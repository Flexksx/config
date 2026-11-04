import { afterEach, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const hook = join(import.meta.dir, "../codex/check.mjs");
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

const run = async (cwd, tool_name, command) => {
  const proc = Bun.spawn({
    cmd: [process.execPath, hook],
    stdin: "pipe",
    stdout: "pipe",
    stderr: "pipe",
  });
  proc.stdin.write(
    JSON.stringify({
      cwd,
      tool_name,
      tool_input: { command },
      session_id: cwd,
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

test("ignores shell commands outside a git repository", async () => {
  const cwd = tempDir("viqui-hook-nonrepo-");
  const result = await run(cwd, "Bash", "echo hello");
  expect(result.status).toBe(0);
  expect(result.stderr).toBe("");
  expect(result.stdout).toBe("");
});

test("finds untracked files below the session directory", async () => {
  const cwd = tempDir("viqui-hook-subdir-");
  expect(Bun.spawnSync({ cmd: ["git", "init", "-q", cwd] }).exitCode).toBe(0);
  const nested = join(cwd, "src");
  mkdirSync(nested, { recursive: true });
  writeFileSync(join(nested, "example.py"), "# violation\n");
  const result = await run(nested, "Bash", "write src/example.py");
  expect(result.status).toBe(0);
  expect(result.stdout).toMatch(/Comment found/);
});

test("checks shell edits once per file version and keeps patch feedback", async () => {
  const cwd = tempDir("viqui-hook-test-");
  expect(Bun.spawnSync({ cmd: ["git", "init", "-q", cwd] }).exitCode).toBe(0);
  const file = join(cwd, "example.py");
  writeFileSync(file, "# violation\n");
  const first = await run(cwd, "Bash", "write example.py");
  expect(first.status).toBe(0);
  expect(first.stdout).toMatch(/Comment found/);
  expect((await run(cwd, "Bash", "pwd")).stdout).toBe("");
  writeFileSync(file, "# another violation\n");
  expect((await run(cwd, "Bash", "change example.py")).stdout).toMatch(
    /Comment found/,
  );
  expect(
    (await run(cwd, "apply_patch", "*** Update File: example.py\n")).stdout,
  ).toMatch(/Comment found/);
});
