import { afterEach, expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const cli = join(import.meta.dir, "../viqui.ts");
const schema = await Bun.file(
  join(import.meta.dir, "../core/finding.schema.json"),
).json();
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

test("Python and TypeScript findings conform to the shared schema", () => {
  const directory = tempDir("viqui-finding-");
  const python = join(directory, "example.py");
  const typescript = join(directory, "example.ts");
  writeFileSync(python, "# note\n");
  writeFileSync(typescript, "// note\n");
  const result = Bun.spawnSync({
    cmd: [
      process.execPath,
      cli,
      "scan",
      "--rule",
      "no-comments",
      python,
      typescript,
    ],
    cwd: directory,
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(result.exitCode).toBe(0);
  const findings = JSON.parse(result.stdout.toString());
  expect(findings.length).toBe(2);
  for (const finding of findings) {
    expect(Object.keys(finding).sort()).toEqual([...schema.required].sort());
    for (const [name, property] of Object.entries(schema.properties)) {
      const value = finding[name];
      if (property.type === "integer") {
        expect(Number.isInteger(value)).toBe(true);
        expect(value).toBeGreaterThanOrEqual(property.minimum);
      } else {
        expect(typeof value).toBe(property.type);
        expect(value.length).toBeGreaterThanOrEqual(property.minLength);
      }
    }
  }
});
