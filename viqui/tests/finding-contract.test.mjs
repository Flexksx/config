import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const cli = fileURLToPath(new URL("../viqui.ts", import.meta.url));
const schema = JSON.parse(
  readFileSync(new URL("../core/finding.schema.json", import.meta.url), "utf8"),
);

test("Python and TypeScript findings conform to the shared schema", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "viqui-finding-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const python = join(directory, "example.py");
  const typescript = join(directory, "example.ts");
  writeFileSync(python, "# note\n");
  writeFileSync(typescript, "// note\n");
  const result = spawnSync(
    "bun",
    [cli, "scan", "--rule", "no-comments", python, typescript],
    { cwd: directory, encoding: "utf8" },
  );
  assert.equal(result.status, 0, result.stderr);
  const findings = JSON.parse(result.stdout);
  assert.equal(findings.length, 2);
  for (const finding of findings) {
    assert.deepEqual(Object.keys(finding).sort(), [...schema.required].sort());
    for (const [name, property] of Object.entries(schema.properties)) {
      const value = finding[name];
      if (property.type === "integer") {
        assert.ok(Number.isInteger(value));
        assert.ok(value >= property.minimum);
      } else {
        assert.equal(typeof value, property.type);
        assert.ok(value.length >= property.minLength);
      }
    }
  }
});
