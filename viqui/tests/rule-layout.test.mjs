import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../rules", import.meta.url));
const repository = fileURLToPath(new URL("../..", import.meta.url));
const extensions = {
  ts: new Set([".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".json"]),
  py: new Set([".py", ".toml", ".txt", ".json"]),
};

for (const rule of readdirSync(root, { withFileTypes: true }).filter((entry) =>
  entry.isDirectory(),
)) {
  const directory = join(root, rule.name);
  const manifest = JSON.parse(
    readFileSync(join(directory, "rule.json"), "utf8"),
  );
  test(`${rule.name} keeps scanners in language directories`, () => {
    assert.equal(manifest.scanners.length, 2);
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      if (entry.isFile()) {
        assert.ok(
          ["rule.json", "README.md", "package.json", "pyproject.toml"].includes(
            entry.name,
          ),
          entry.name,
        );
      }
    }
  });
  for (const language of ["ts", "py"]) {
    test(`${rule.name}/${language} has an isolated, tested scanner`, () => {
      const base = join(directory, language);
      for (const path of [
        `scan.${language}`,
        `test/fixtures/valid.${language}`,
        `test/fixtures/invalid.${language}`,
      ]) {
        assert.ok(statSync(join(base, path)).isFile(), path);
      }
      const scanner = manifest.scanners.find(
        (entry) => entry.entrypoint === `${language}/scan.${language}`,
      );
      assert.ok(scanner, `missing ${language} scanner`);
      assert.equal(scanner.runtime, language === "ts" ? "node" : "python3");
      const allowed =
        language === "ts"
          ? [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"]
          : [".py"];
      assert.ok(scanner.extensions.length > 0);
      assert.ok(
        scanner.extensions.every((extension) => allowed.includes(extension)),
      );
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
            assert.ok(
              extensions[language].has(child.slice(child.lastIndexOf("."))),
              child,
            );
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
        const result = spawnSync(
          runner,
          [join(base, `scan.${language}`), fixture],
          {
            cwd: repository,
            encoding: "utf8",
            env: { ...process.env, PYTHONPATH: repository },
          },
        );
        assert.equal(result.status, 0, result.stderr);
        const findings = JSON.parse(result.stdout);
        assert.equal(findings.length, expected, fixture);
        if (expected) {
          assert.equal(findings[0].rule, manifest.id);
          assert.equal(findings[0].file, fixture);
          assert.ok(findings[0].line > 0 && findings[0].column > 0);
        }
      }
    });
  }
}
