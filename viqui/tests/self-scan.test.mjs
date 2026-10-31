import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const directory = fileURLToPath(new URL("..", import.meta.url));
const cli = fileURLToPath(new URL("../viqui.ts", import.meta.url));

test("Viqui follows its rules outside intentional violation fixtures", () => {
  const result = spawnSync("bun", [cli, "scan", directory], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  const findings = JSON.parse(result.stdout).filter(
    ({ file }) => !file.includes("/test/fixtures/"),
  );
  assert.deepEqual(findings, []);
});
