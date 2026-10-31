import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, relative } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const cli = fileURLToPath(new URL("../viqui.ts", import.meta.url));
const run = (...arguments_) =>
  spawnSync("bun", [cli, ...arguments_], { encoding: "utf8" });

test("lists installed rules", () => {
  const result = run("list");
  assert.equal(result.status, 0);
  assert.deepEqual(JSON.parse(result.stdout).sort(), [
    "no-boolean-parameter",
    "no-comments",
    "no-complex-if-condition",
    "no-deep-nesting",
    "no-empty-exception-handler",
    "no-long-boolean-chain",
    "no-nested-ternary",
    "no-stateless-class",
    "no-thin-wrapper",
  ]);
});

test("selects a rule and can fail on findings", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "viqui-test-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const path = join(directory, "service.py");
  writeFileSync(
    path,
    "class Service:\n    def get(self, key):\n        return repository.get(key)\n",
  );
  const selected = run(
    "scan",
    "--rule",
    "no-stateless-class",
    "--fail-on-findings",
    path,
  );
  assert.equal(selected.status, 1);
  assert.deepEqual(
    JSON.parse(selected.stdout).map(({ rule }) => rule),
    ["no-stateless-class"],
  );
  const other = run("scan", "--rule", "no-thin-wrapper", path);
  assert.equal(other.status, 0);
  assert.deepEqual(JSON.parse(other.stdout), []);
});

test("rejects unknown rules and missing paths", () => {
  const unknown = run("scan", "--rule", "missing", ".");
  assert.equal(unknown.status, 2);
  assert.match(unknown.stderr, /Unknown rule/);
  const missing = run("scan");
  assert.equal(missing.status, 2);
  assert.match(missing.stderr, /missing required argument/);
});

test("shows help without affecting JSON output", () => {
  const result = run("scan", "--help");
  assert.equal(result.status, 0);
  assert.match(result.stdout, /--fail-on-findings/);
  assert.equal(result.stderr, "");
});

test("reports paths relative to the scan working directory", (t) => {
  const directory = mkdtempSync(join(tmpdir(), "viqui-paths-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const file = join(directory, "example.py");
  writeFileSync(file, "# comment\n");
  const result = spawnSync(
    "bun",
    [cli, "scan", "--rule", "no-comments", file],
    {
      cwd: directory,
      encoding: "utf8",
    },
  );
  assert.equal(result.status, 0, result.stderr);
  assert.equal(JSON.parse(result.stdout)[0].file, "./example.py");
  const outside = run("scan", "--rule", "no-comments", file);
  assert.equal(outside.status, 0, outside.stderr);
  assert.equal(
    JSON.parse(outside.stdout)[0].file,
    relative(realpathSync(process.cwd()), realpathSync(file)),
  );
});
