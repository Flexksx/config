import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scanner = fileURLToPath(new URL("../scan.ts", import.meta.url));
const scan = (filename) => {
  const path = fileURLToPath(
    new URL(`./fixtures/${filename}`, import.meta.url),
  );
  const result = spawnSync(process.execPath, [scanner, path], {
    encoding: "utf8",
  });
  expect(result.status).toBe(0);
  return JSON.parse(result.stdout);
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
