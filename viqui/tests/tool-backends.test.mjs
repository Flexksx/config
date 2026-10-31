import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const cli = fileURLToPath(new URL("../viqui.ts", import.meta.url));

test("tool-backed rules ignore project lint settings and do not modify files", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "viqui-backends-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  writeFileSync(
    join(directory, "ruff.toml"),
    "fix = true\n[lint]\nignore = ['ALL']\n",
  );
  writeFileSync(
    join(directory, "biome.json"),
    JSON.stringify({ linter: { enabled: false } }),
  );
  for (const [name, rule, source] of [
    [
      "example.py",
      "no-empty-exception-handler",
      "try:\n    work()\nexcept ValueError:\n    pass  # noqa: S110\n",
    ],
    ["example.ts", "no-nested-ternary", "const value = a ? b : c ? d : e;\n"],
  ]) {
    const file = join(directory, name);
    writeFileSync(file, source);
    const result = spawnSync("bun", [cli, "scan", "--rule", rule, file], {
      cwd: directory,
      encoding: "utf8",
    });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).length, 1);
    assert.equal(readFileSync(file, "utf8"), source);
  }
});
