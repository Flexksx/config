import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const cli = fileURLToPath(new URL("../viqui.ts", import.meta.url));

const scan = (t, rule, name, source) => {
  const directory = mkdtempSync(join(tmpdir(), "viqui-preference-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const path = join(directory, name);
  writeFileSync(path, source);
  const result = spawnSync("bun", [cli, "scan", "--rule", rule, path], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout).map(({ line, column }) => [line, column]);
};

test("reports boolean parameters but not boolean fields or returns", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-boolean-parameter",
      "file.ts",
      `
function f(enabled: boolean, flag = false, name: string): boolean { return enabled; }
const value: boolean = true;
`,
    ),
    [
      [2, 12],
      [2, 30],
    ],
  );
});

test("reports comments but permits recognized directives and strings", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-comments",
      "file.ts",
      `
// eslint-disable-next-line no-console
const text = "// not a comment"; // explain
/** documentation */
`,
    ),
    [
      [3, 34],
      [4, 1],
    ],
  );
  assert.deepEqual(
    scan(
      t,
      "no-comments",
      "file.py",
      `#!/usr/bin/env python3
# coding: utf-8
"""Module docs."""
value = "# text"  # explain
value = 1  # type: ignore  # reason
`,
    ),
    [[4, 19]],
  );
});

test("reports empty handlers while allowing handling and propagation", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-empty-exception-handler",
      "file.ts",
      `
try { run(); } catch (error) {}
try { run(); } catch (error) { throw error; }
`,
    ),
    [[2, 30]],
  );
  assert.deepEqual(
    scan(
      t,
      "no-empty-exception-handler",
      "file.py",
      `
try:
    run()
except ValueError:
    pass
try:
    run()
except ValueError:
    raise
`,
    ),
    [[4, 1]],
  );
});

test("reports empty TypeScript blocks and permits comment-only catches", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-empty-exception-handler",
      "blocks.ts",
      "if (ready) {}\ntry { run(); } catch { /* ignored */ }\n",
    ),
    [[1, 12]],
  );
});

test("reports the fourth control-flow level, but resets inside functions and keeps else-if at the same level", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-deep-nesting",
      "nesting.ts",
      `
if (a) {
  for (const x of xs) {
    if (b) {
      if (c) { run(); }
      function f() { if (d) { run(); } }
    } else if (e) { run(); }
  }
}
`,
    ),
    [[5, 7]],
  );
  assert.deepEqual(
    scan(
      t,
      "no-deep-nesting",
      "nesting.py",
      `
if a:
    for x in xs:
        if b:
            if c:
                run()
            def f():
                if d:
                    run()
        elif e:
            run()
`,
    ),
    [[2, 1]],
  );
});

test("reports more than two boolean conditions, including nested and negated expressions", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-complex-if-condition",
      "conditions.ts",
      `
if (a && b) run();
if (a || b || (c && d)) run();
if (!(a && b && c)) run();
`,
    ),
    [
      [3, 1],
      [4, 1],
    ],
  );
  assert.deepEqual(
    scan(
      t,
      "no-complex-if-condition",
      "conditions.py",
      `
if a and b: run()
if a or b or (c and d): run()
if not (a and b and c): run()
if a < b < c: run()
if a < b < c < d: run()
`,
    ),
    [[3, 4]],
  );
});

test("scans JavaScript modules for complex conditions", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-complex-if-condition",
      "module.mjs",
      "if (a && b && c) run();\n",
    ),
    [[1, 1]],
  );
});

test("reports Python boolean parameters", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-boolean-parameter",
      "file.py",
      "def f(enabled: bool, count: int = 1, *, active=False):\n    pass\n",
    ),
    [[1, 7]],
  );
});

test("reports a positional boolean parameter once when both Ruff checks apply", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-boolean-parameter",
      "file.py",
      "def f(enabled: bool = True, *, active=False):\n    pass\n",
    ),
    [[1, 7]],
  );
});

test("reports boolean chains longer than three checks in any expression", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-long-boolean-chain",
      "chain.ts",
      `
const short = a && b && c;
const long = a && (b || c) && d;
function f() { return !(a || b || c || d); }
`,
    ),
    [
      [3, 14],
      [4, 25],
    ],
  );
  assert.deepEqual(
    scan(
      t,
      "no-long-boolean-chain",
      "chain.py",
      `
short = a and b and c
long = a and (b or c) and d
def f():
    return not (a or b or c or d)
`,
    ),
    [
      [3, 8],
      [5, 17],
    ],
  );
});

test("reports nested ternaries while allowing single conditional expressions", (t) => {
  assert.deepEqual(
    scan(
      t,
      "no-nested-ternary",
      "ternary.ts",
      `
const single = a ? b : c;
const chain = a ? b : c ? d : e;
const nested = a ? (b ? c : d) : e;
`,
    ),
    [
      [3, 23],
      [4, 21],
    ],
  );
  assert.deepEqual(
    scan(
      t,
      "no-nested-ternary",
      "ternary.py",
      `
single = b if a else c
chain = b if a else d if c else e
nested = (c if b else d) if a else e
`,
    ),
    [
      [3, 9],
      [4, 10],
    ],
  );
});
