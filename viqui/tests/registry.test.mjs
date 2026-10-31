import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { scanRules } from "../core/registry.mjs";

test("discovers a new rule and dispatches only matching files", (t) => {
  const root = mkdtempSync(join(tmpdir(), "harness-registry-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const rule = join(root, "example");
  mkdirSync(rule);
  writeFileSync(
    join(rule, "rule.json"),
    JSON.stringify({
      id: "example",
      scanners: [
        { extensions: [".ts"], runtime: "node", entrypoint: "scan.ts" },
      ],
    }),
  );
  writeFileSync(
    join(rule, "scan.ts"),
    `process.stdout.write(JSON.stringify(process.argv.slice(2).map(file => ({rule: "example", file, line: 1, column: 1, message: "found"}))));`,
  );
  const findings = scanRules(root, ["/tmp/example.ts", "/tmp/example.py"]);
  assert.deepEqual(findings, [
    {
      rule: "example",
      file: "/tmp/example.ts",
      line: 1,
      column: 1,
      message: "found",
    },
  ]);
});

test("rejects malformed findings", (t) => {
  const root = mkdtempSync(join(tmpdir(), "harness-registry-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const rule = join(root, "example");
  mkdirSync(rule);
  writeFileSync(
    join(rule, "rule.json"),
    JSON.stringify({
      id: "example",
      scanners: [
        { extensions: [".ts"], runtime: "node", entrypoint: "scan.ts" },
      ],
    }),
  );
  writeFileSync(join(rule, "scan.ts"), 'process.stdout.write("[{}]")');
  assert.throws(() => scanRules(root, ["/tmp/example.ts"]), /Invalid finding/);
});
