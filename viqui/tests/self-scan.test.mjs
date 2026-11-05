import { expect, test } from "bun:test";
import { join } from "node:path";
import {
  checkstyleCachePath,
  ensureCheckstyleJar,
} from "../shared/checkstyle.ts";

const directory = join(import.meta.dir, "..");
const cli = join(import.meta.dir, "../viqui.ts");
await ensureCheckstyleJar(checkstyleCachePath());

test("Viqui follows its rules outside intentional violation fixtures", () => {
  const result = Bun.spawnSync({
    cmd: [process.execPath, cli, "scan", directory],
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(result.exitCode).toBe(0);
  const findings = JSON.parse(result.stdout.toString()).filter(
    ({ file }) => !file.includes("/test/fixtures/"),
  );
  expect(findings).toEqual([]);
}, 60000);
