import { afterEach, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const config = join(import.meta.dir, "../dependency-cruiser.cjs");
const cruiser = join(
  import.meta.dir,
  "../../node_modules/dependency-cruiser/bin/dependency-cruiser.mjs",
);
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

test("rejects imports between rules while permitting own and shared modules", () => {
  const root = tempDir("viqui-dependencies-");
  for (const name of ["alpha", "beta"]) {
    mkdirSync(join(root, "viqui", "rules", name), { recursive: true });
  }
  mkdirSync(join(root, "viqui", "shared"));
  writeFileSync(
    join(root, "viqui", "shared", "common.mjs"),
    "export const common = 1;\n",
  );
  writeFileSync(
    join(root, "viqui", "rules", "alpha", "own.mjs"),
    "export const own = 1;\n",
  );
  writeFileSync(
    join(root, "viqui", "rules", "beta", "other.mjs"),
    "export const other = 1;\n",
  );
  const source = join(root, "viqui", "rules", "alpha", "scan.ts");
  writeFileSync(
    source,
    'import "./own.mjs";\nimport "../../shared/common.mjs";\n',
  );
  const run = () =>
    Bun.spawnSync({
      cmd: [process.execPath, cruiser, "--config", config, "viqui/rules"],
      cwd: root,
      stdout: "pipe",
      stderr: "pipe",
    });
  expect(run().exitCode).toBe(0);
  writeFileSync(source, 'import "../beta/other.mjs";\n');
  const violation = run();
  expect(violation.exitCode).toBe(1);
  expect(violation.stdout.toString()).toMatch(/no-cross-rule-imports/);
});
