import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const config = fileURLToPath(
  new URL("../dependency-cruiser.cjs", import.meta.url),
);
const cruiser = fileURLToPath(
  new URL(
    "../../node_modules/dependency-cruiser/bin/dependency-cruiser.mjs",
    import.meta.url,
  ),
);

test("rejects imports between rules while permitting own and shared modules", (t) => {
  const root = mkdtempSync(join(tmpdir(), "viqui-dependencies-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
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
    spawnSync(process.execPath, [cruiser, "--config", config, "viqui/rules"], {
      cwd: root,
      encoding: "utf8",
    });
  assert.equal(run().status, 0);
  writeFileSync(source, 'import "../beta/other.mjs";\n');
  const violation = run();
  assert.equal(violation.status, 1);
  assert.match(violation.stdout, /no-cross-rule-imports/);
});
