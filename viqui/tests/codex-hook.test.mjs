import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const hook = fileURLToPath(new URL("../codex/check.mjs", import.meta.url));

test("checks shell edits once per file version and keeps patch feedback", (t) => {
  const cwd = mkdtempSync(join(tmpdir(), "viqui-hook-test-"));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  assert.equal(spawnSync("git", ["init", "-q", cwd]).status, 0);
  const file = join(cwd, "example.py");
  writeFileSync(file, "# violation\n");
  const run = (tool_name, command) =>
    spawnSync("node", [hook], {
      input: JSON.stringify({
        cwd,
        tool_name,
        tool_input: { command },
        session_id: cwd,
      }),
      encoding: "utf8",
    });
  const first = run("Bash", "write example.py");
  assert.equal(first.status, 0, first.stderr);
  assert.match(first.stdout, /Comment found/);
  assert.equal(run("Bash", "pwd").stdout, "");
  writeFileSync(file, "# another violation\n");
  assert.match(run("Bash", "change example.py").stdout, /Comment found/);
  assert.match(
    run("apply_patch", "*** Update File: example.py\n").stdout,
    /Comment found/,
  );
});
