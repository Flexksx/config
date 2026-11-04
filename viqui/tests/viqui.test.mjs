import { afterEach, expect, test } from "bun:test";
import { mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, relative } from "node:path";

const cli = join(import.meta.dir, "../viqui.ts");
const tempDirs = [];
const tempDir = (prefix) => {
  const directory = mkdtempSync(join(tmpdir(), prefix));
  tempDirs.push(directory);
  return directory;
};
afterEach(() => {
  for (const directory of tempDirs.splice(0)) {
    rmSync(directory, { recursive: true, force: true });
  }
});
const run = (...arguments_) => {
  const result = Bun.spawnSync({
    cmd: [process.execPath, cli, ...arguments_],
    stdout: "pipe",
    stderr: "pipe",
  });
  return {
    status: result.exitCode,
    stdout: result.stdout.toString(),
    stderr: result.stderr.toString(),
  };
};

test("lists installed rules", () => {
  const result = run("list");
  expect(result.status).toBe(0);
  expect(JSON.parse(result.stdout).sort()).toEqual([
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

test("selects a rule and can fail on findings", () => {
  const directory = tempDir("viqui-test-");
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
  expect(selected.status).toBe(1);
  expect(JSON.parse(selected.stdout).map(({ rule }) => rule)).toEqual([
    "no-stateless-class",
  ]);
  const other = run("scan", "--rule", "no-thin-wrapper", path);
  expect(other.status).toBe(0);
  expect(JSON.parse(other.stdout)).toEqual([]);
});

test("rejects unknown rules and missing paths", () => {
  const unknown = run("scan", "--rule", "missing", ".");
  expect(unknown.status).toBe(2);
  expect(unknown.stderr).toMatch(/Unknown rule/);
  const missing = run("scan");
  expect(missing.status).toBe(2);
  expect(missing.stderr).toMatch(/missing required argument/);
});

test("shows help without affecting JSON output", () => {
  const result = run("scan", "--help");
  expect(result.status).toBe(0);
  expect(result.stdout).toMatch(/--fail-on-findings/);
  expect(result.stderr).toBe("");
});

test("reports paths relative to the scan working directory", () => {
  const directory = tempDir("viqui-paths-");
  const file = join(directory, "example.py");
  writeFileSync(file, "# comment\n");
  const result = Bun.spawnSync({
    cmd: [process.execPath, cli, "scan", "--rule", "no-comments", file],
    cwd: directory,
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(result.exitCode).toBe(0);
  expect(JSON.parse(result.stdout.toString())[0].file).toBe("./example.py");
  const outside = run("scan", "--rule", "no-comments", file);
  expect(outside.status).toBe(0);
  expect(JSON.parse(outside.stdout)[0].file).toBe(
    relative(realpathSync(process.cwd()), realpathSync(file)),
  );
});
