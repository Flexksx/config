import { afterEach, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { scanRules } from "../core/registry.mjs";

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

test("discovers a new rule and dispatches only matching files", async () => {
  const root = tempDir("harness-registry-");
  const rule = join(root, "example");
  mkdirSync(rule);
  writeFileSync(
    join(rule, "rule.json"),
    JSON.stringify({
      id: "example",
      scanners: [
        { extensions: [".ts"], runtime: "bun", entrypoint: "scan.ts" },
      ],
    }),
  );
  writeFileSync(
    join(rule, "scan.ts"),
    `await Bun.stdout.write(JSON.stringify(Bun.argv.slice(2).map(file => ({rule: "example", file, line: 1, column: 1, message: "found"}))));`,
  );
  const findings = await scanRules(root, [
    "/tmp/example.ts",
    "/tmp/example.py",
  ]);
  expect(findings).toEqual([
    {
      rule: "example",
      file: "/tmp/example.ts",
      line: 1,
      column: 1,
      message: "found",
    },
  ]);
});

test("rejects malformed findings", async () => {
  const root = tempDir("harness-registry-");
  const rule = join(root, "example");
  mkdirSync(rule);
  writeFileSync(
    join(rule, "rule.json"),
    JSON.stringify({
      id: "example",
      scanners: [
        { extensions: [".ts"], runtime: "bun", entrypoint: "scan.ts" },
      ],
    }),
  );
  writeFileSync(join(rule, "scan.ts"), 'await Bun.stdout.write("[{}]")');
  await expect(scanRules(root, ["/tmp/example.ts"])).rejects.toThrow(
    /Invalid finding/,
  );
});
