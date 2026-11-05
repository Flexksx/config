import { expect, test } from "bun:test";
import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import {
  checkstyleCachePath,
  ensureCheckstyleJar,
} from "../shared/checkstyle.ts";

const root = join(import.meta.dir, "../rules");
const repository = join(import.meta.dir, "../..");
await ensureCheckstyleJar(checkstyleCachePath());

const languages = {
  ts: {
    runtime: "bun",
    runner: process.execPath,
    entrypoint: "ts/scan.ts",
    source: "scan.ts",
    fixture: "ts",
    extensions: [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"],
    files: new Set([".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".json"]),
  },
  py: {
    runtime: "python3",
    runner: "python3",
    entrypoint: "py/scan.py",
    source: "scan.py",
    fixture: "py",
    extensions: [".py"],
    files: new Set([".py", ".toml", ".txt", ".json"]),
  },
  java: {
    runtime: "bun",
    runner: process.execPath,
    entrypoint: "java/scan.ts",
    source: "scan.ts",
    fixture: "java",
    extensions: [".java"],
    files: new Set([".ts", ".xml", ".java", ".json"]),
  },
};

for (const rule of readdirSync(root, { withFileTypes: true }).filter((entry) =>
  entry.isDirectory(),
)) {
  const directory = join(root, rule.name);
  const manifest = await Bun.file(join(directory, "rule.json")).json();
  const present = Object.keys(languages).filter((language) =>
    existsSync(join(directory, language)),
  );

  test(`${rule.name} keeps scanners in language directories`, () => {
    expect(manifest.scanners.length).toBe(present.length);
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

  for (const language of present) {
    const spec = languages[language];
    test(`${rule.name}/${language} has an isolated, tested scanner`, async () => {
      const base = join(directory, language);
      for (const path of [
        spec.source,
        `test/fixtures/valid.${spec.fixture}`,
        `test/fixtures/invalid.${spec.fixture}`,
      ]) {
        expect(await Bun.file(join(base, path)).exists()).toBe(true);
      }
      const scanner = manifest.scanners.find(
        (entry) => entry.entrypoint === spec.entrypoint,
      );
      expect(scanner).toBeDefined();
      expect(scanner.runtime).toBe(spec.runtime);
      expect(scanner.extensions.length).toBeGreaterThan(0);
      expect(
        scanner.extensions.every((extension) =>
          spec.extensions.includes(extension),
        ),
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
            expect(spec.files.has(child.slice(child.lastIndexOf(".")))).toBe(
              true,
            );
          }
        }
      };
      walk(base);
      for (const [name, expected] of [
        ["valid", 0],
        ["invalid", 1],
      ]) {
        const fixture = join(base, `test/fixtures/${name}.${spec.fixture}`);
        const result = Bun.spawnSync({
          cmd: [spec.runner, join(base, spec.source), fixture],
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
