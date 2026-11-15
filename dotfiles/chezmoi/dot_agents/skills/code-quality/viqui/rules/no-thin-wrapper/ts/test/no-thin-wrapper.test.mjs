import { expect, test } from "bun:test";
import { join } from "node:path";

const scanner = join(import.meta.dir, "../scan.ts");
const scan = (filename) => {
  const path = join(import.meta.dir, `./fixtures/${filename}`);
  const result = Bun.spawnSync({
    cmd: [process.execPath, scanner, path],
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(result.exitCode).toBe(0);
  return JSON.parse(result.stdout.toString());
};

test.each([
  "callback.ts",
  "named-export.ts",
  "default-export.ts",
  "direct-export.ts",
  "additional-work.ts",
  "transformed-argument.ts",
  "discarded-return.ts",
  "unused.ts",
  "duplicate-parameter.ts",
  "recursive.ts",
  "reassigned.ts",
  "async.ts",
])("does not report %s", (filename) => {
  expect(scan(filename)).toHaveLength(0);
});

test.each([
  "multiple-presets.ts",
  "function-declaration.ts",
  "direct-call.ts",
  "component.tsx",
  "shadowed-name.ts",
])("reports %s", (filename) => {
  expect(scan(filename)).toHaveLength(1);
});
