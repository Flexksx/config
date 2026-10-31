import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const directory = mkdtempSync(join(tmpdir(), "harness-test-"));
afterAll(() => rmSync(directory, { recursive: true, force: true }));
const adapter = new URL("./check.mjs", import.meta.url).pathname;
const runHook = (file_path) =>
  spawnSync(process.execPath, [adapter], {
    input: JSON.stringify({
      workspace_roots: [directory],
      tool_input: { file_path },
    }),
    encoding: "utf8",
  });

test("reports findings for a changed TypeScript file", () => {
  writeFileSync(
    join(directory, "example.ts"),
    'const activate = () => setState("active"); activate();\n',
  );
  const result = runHook(join(directory, "example.ts"));
  expect(result.stderr).toBe("");
  expect(result.status).toBe(0);
  expect(JSON.parse(result.stdout).additional_context).toMatch(
    /^Review harness findings:\n\.\/example\.ts:1:.*wrapper/,
  );
});

test("ignores non-TypeScript edits", () => {
  writeFileSync(join(directory, "notes.md"), "# notes\n");
  const result = runHook(join(directory, "notes.md"));
  expect(result.status).toBe(0);
  expect(result.stdout).toBe("");
});

test("reports findings for a changed Python file", () => {
  writeFileSync(
    join(directory, "example.py"),
    'def work():\n    def activate():\n        return set_state("active")\n    activate()\n',
  );
  const result = runHook(join(directory, "example.py"));
  expect(result.stderr).toBe("");
  expect(result.status).toBe(0);
  expect(JSON.parse(result.stdout).additional_context).toMatch(
    /example\.py:2:.*wrapper/,
  );
});

test("reports malformed hook input", () => {
  const result = spawnSync(process.execPath, [adapter], {
    input: "{}",
    encoding: "utf8",
  });
  expect(result.status).not.toBe(0);
  expect(result.stderr).toMatch(/Expected a file path/);
});
