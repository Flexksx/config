import { expect, test } from "bun:test";
import { readdirSync } from "node:fs";
import { join } from "node:path";

const root = join(import.meta.dir, "../rules");
const repository = join(import.meta.dir, "../..");
const extensions = {
  ts: new Set([".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".json"]),
  py: new Set([".py", ".toml", ".txt", ".json"]),
};

for (const rule of readdirSync(root, { withFileTypes: true }).filter((entry) =>
  entry.isDirectory(),
)) {
  const directory = join(root, rule.name);
  const manifest = await Bun.file(join(directory, "rule.json")).json();
  test(`${rule.name} keeps scanners in language directories`, () => {
    expect(manifest.scanners.length).toBe(2);
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      if (entry.isFile()) {
        expect([
          "rule.json",
          "README.md",
          "package.json",
          "pyproject.toml",
        ]).toContain(entry.name);
      }
    }
  });
  for (const language of ["ts", "py"]) {
    test(`${rule.name}/${language} has an isolated, tested scanner`, async () => {
      const base = join(directory, language);
      for (const path of [
        `scan.${language}`,
        `test/fixtures/valid.${language}`,
        `test/fixtures/invalid.${language}`,
      ]) {
        expect(await Bun.file(join(base, path)).exists()).toBe(true);
      }
      const scanner = manifest.scanners.find(
        (entry) => entry.entrypoint === `${language}/scan.${language}`,
      );
      expect(scanner).toBeDefined();
      expect(scanner.runtime).toBe(language === "ts" ? "bun" : "python3");
      const allowed =
        language === "ts"
          ? [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"]
          : [".py"];
      expect(scanner.extensions.length).toBeGreaterThan(0);
      expect(
        scanner.extensions.every((extension) => allowed.includes(extension)),
      ).toBe(true);
      const walk = (path) => {
        for (const entry of readdirSync(path, { withFileTypes: true })) {
          if (
            [
              "__pycache__",
              "node_modules",
              ".pytest_cache",
              ".ruff_cache",
              ".cache",
              ".venv",
            ].includes(entry.name)
          ) {
            continue;
          }
          const child = join(path, entry.name);
          if (entry.isDirectory()) {
            walk(child);
          } else {
            expect(
              extensions[language].has(child.slice(child.lastIndexOf("."))),
            ).toBe(true);
          }
        }
      };
      walk(base);
      for (const [name, expected] of [
        ["valid", 0],
        ["invalid", 1],
      ]) {
        const fixture = join(base, `test/fixtures/${name}.${language}`);
        const runner = language === "ts" ? process.execPath : "python3";
        const result = Bun.spawnSync({
          cmd: [runner, join(base, `scan.${language}`), fixture],
          cwd: repository,
          env: { ...Bun.env, PYTHONPATH: repository },
          stdout: "pipe",
          stderr: "pipe",
        });
        expect(result.exitCode).toBe(0);
        const findings = JSON.parse(result.stdout.toString());
        expect(findings.length).toBe(expected);
        if (expected) {
          expect(findings[0].rule).toBe(manifest.id);
          expect(findings[0].file).toBe(fixture);
          expect(findings[0].line).toBeGreaterThan(0);
          expect(findings[0].column).toBeGreaterThan(0);
        }
      }
    });
  }
}
