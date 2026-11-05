import { expect, test } from "bun:test";
import { join } from "node:path";
import { protectedOperand } from "../core/protect.mjs";

const cases = [
  [{ path: ".env" }, ".env"],
  [{ path: ".env.local" }, ".env.local"],
  [{ file_path: "/home/user/.envrc" }, "/home/user/.envrc"],
  [{ filePath: "config/.env" }, "config/.env"],
  [{ paths: ["src/index.ts", ".env"] }, ".env"],
  [{ command: "cat .env" }, "cat .env"],
  [{ patch: "*** Update File: .env" }, "*** Update File: .env"],
  [{ glob: "**/.env*" }, "**/.env*"],
  [{ command: "echo $HOME" }, undefined],
  [{ path: "src/environment.ts" }, undefined],
  [{ content: ".env" }, undefined],
  [{ edits: [{ newText: ".env" }] }, undefined],
  [{}, undefined],
  [null, undefined],
  ["raw string", undefined],
];

const runHook = async (script, input) => {
  const proc = Bun.spawn({
    cmd: [process.execPath, script],
    stdin: "pipe",
    stdout: "pipe",
    stderr: "pipe",
  });
  proc.stdin.write(JSON.stringify(input));
  proc.stdin.end();
  const [stdout, stderr, status] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  return { stdout, stderr, status };
};

const codexHook = join(import.meta.dir, "../codex/protect.mjs");
const cursorHook = join(import.meta.dir, "../cursor/protect.mjs");

test("matches operated-on arguments that contain .env", () => {
  for (const [input, expected] of cases) {
    expect(protectedOperand(input)).toBe(expected);
  }
});

test("the Codex hook denies calls that touch a .env path", async () => {
  const denied = await runHook(codexHook, { tool_input: { path: ".env" } });
  expect(denied.status).toBe(0);
  expect(denied.stderr).toBe("");
  const output = JSON.parse(denied.stdout);
  expect(output.hookSpecificOutput.hookEventName).toBe("PreToolUse");
  expect(output.hookSpecificOutput.permissionDecision).toBe("deny");
  expect(output.hookSpecificOutput.permissionDecisionReason).toMatch(/\.env/);
});

test("the Codex hook stays silent for other calls", async () => {
  const allowed = await runHook(codexHook, { tool_input: { path: "a.ts" } });
  expect(allowed.status).toBe(0);
  expect(allowed.stdout).toBe("");
});

test("the Cursor hook denies calls that touch a .env path", async () => {
  const denied = await runHook(cursorHook, {
    tool_input: { command: "cat .env" },
  });
  expect(denied.status).toBe(0);
  expect(denied.stderr).toBe("");
  const output = JSON.parse(denied.stdout);
  expect(output.permission).toBe("deny");
  expect(output.user_message).toMatch(/\.env/);
});

test("the Cursor hook stays silent for other calls", async () => {
  const allowed = await runHook(cursorHook, { tool_input: { command: "ls" } });
  expect(allowed.status).toBe(0);
  expect(allowed.stdout).toBe("");
});

test("the Cursor hook denies a .env read event", async () => {
  const denied = await runHook(cursorHook, {
    file_path: "/home/user/.env",
    content: "SECRET=1",
  });
  expect(denied.status).toBe(0);
  const output = JSON.parse(denied.stdout);
  expect(output.permission).toBe("deny");
  expect(output.user_message).toMatch(/\.env/);
});

test("the hooks fail on malformed input", async () => {
  const proc = Bun.spawn({
    cmd: [process.execPath, codexHook],
    stdin: "pipe",
    stdout: "pipe",
    stderr: "pipe",
  });
  proc.stdin.write("{");
  proc.stdin.end();
  const status = await proc.exited;
  expect(status).not.toBe(0);
});
