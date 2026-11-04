import { afterEach, expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const cli = join(import.meta.dir, "../viqui.ts");
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

test("tool-backed rules ignore project lint settings and do not modify files", async () => {
  const directory = tempDir("viqui-backends-");
  writeFileSync(
    join(directory, "ruff.toml"),
    "fix = true\n[lint]\nignore = ['ALL']\n",
  );
  writeFileSync(
    join(directory, "biome.json"),
    JSON.stringify({ linter: { enabled: false } }),
  );
  for (const [name, rule, source] of [
    [
      "example.py",
      "no-empty-exception-handler",
      "try:\n    work()\nexcept ValueError:\n    pass  # noqa: S110\n",
    ],
    ["example.ts", "no-nested-ternary", "const value = a ? b : c ? d : e;\n"],
  ]) {
    const file = join(directory, name);
    writeFileSync(file, source);
    const result = Bun.spawnSync({
      cmd: [process.execPath, cli, "scan", "--rule", rule, file],
      cwd: directory,
      stdout: "pipe",
      stderr: "pipe",
    });
    expect(result.exitCode).toBe(0);
    expect(JSON.parse(result.stdout.toString()).length).toBe(1);
    expect(await Bun.file(file).text()).toBe(source);
  }
});
