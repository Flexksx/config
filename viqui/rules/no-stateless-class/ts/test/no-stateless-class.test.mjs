import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const scanner = fileURLToPath(new URL("../scan.ts", import.meta.url));
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
  const result = spawnSync(process.execPath, [scanner, path], {
    encoding: "utf8",
  });
  expect(result.status).toBe(0);
  expect(JSON.parse(result.stdout)).toHaveLength(count);
});
