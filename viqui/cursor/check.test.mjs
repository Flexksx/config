import { afterAll, expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const directory = mkdtempSync(join(tmpdir(), "harness-test-"));
afterAll(() => rmSync(directory, { recursive: true, force: true }));
const adapter = join(import.meta.dir, "check.mjs");
const runHook = async (file_path) => {
  const proc = Bun.spawn({
    cmd: [process.execPath, adapter],
    stdin: "pipe",
    stdout: "pipe",
    stderr: "pipe",
  });
  proc.stdin.write(
    JSON.stringify({
      workspace_roots: [directory],
      tool_input: { file_path },
    }),
  );
  proc.stdin.end();
  const [stdout, stderr, status] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  return { stdout, stderr, status };
};

test("reports findings for a changed TypeScript file", async () => {
  writeFileSync(
    join(directory, "example.ts"),
    'const activate = () => setState("active"); activate();\n',
  );
  const result = await runHook(join(directory, "example.ts"));
  expect(result.stderr).toBe("");
  expect(result.status).toBe(0);
  expect(JSON.parse(result.stdout).additional_context).toMatch(
    /^Review harness findings:\n\.\/example\.ts:1:.*wrapper/,
  );
});

test("ignores non-TypeScript edits", async () => {
  writeFileSync(join(directory, "notes.md"), "# notes\n");
  const result = await runHook(join(directory, "notes.md"));
  expect(result.status).toBe(0);
  expect(result.stdout).toBe("");
});

test("reports findings for a changed Python file", async () => {
  writeFileSync(
    join(directory, "example.py"),
    'def work():\n    def activate():\n        return set_state("active")\n    activate()\n',
  );
  const result = await runHook(join(directory, "example.py"));
  expect(result.stderr).toBe("");
  expect(result.status).toBe(0);
  expect(JSON.parse(result.stdout).additional_context).toMatch(
    /example\.py:2:.*wrapper/,
  );
});

test("reports malformed hook input", async () => {
  const proc = Bun.spawn({
    cmd: [process.execPath, adapter],
    stdin: "pipe",
    stdout: "pipe",
    stderr: "pipe",
  });
  proc.stdin.write("{}");
  proc.stdin.end();
  const [stderr, status] = await Promise.all([
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  expect(status).not.toBe(0);
  expect(stderr).toMatch(/Expected a file path/);
});
