import { afterAll, expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const scanner = join(import.meta.dir, "../scan.ts");
const directory = mkdtempSync(join(tmpdir(), "viqui-stateless-"));
afterAll(() => rmSync(directory, { recursive: true, force: true }));

test.each([
  [
    "class Repository { constructor(private db: Database) {} get(id: string) { return this.db.get(id); } }",
    0,
  ],
  ["class Service extends Base { get() { return repository.get(); } }", 1],
  ["class Service { get(id: string) { return repository.get(id); } }", 1],
])("classifies class correctly: %s", (source, count) => {
  const path = join(directory, "class.ts");
  writeFileSync(path, source);
  const result = Bun.spawnSync({
    cmd: [process.execPath, scanner, path],
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(result.exitCode).toBe(0);
  expect(JSON.parse(result.stdout.toString())).toHaveLength(count);
});
