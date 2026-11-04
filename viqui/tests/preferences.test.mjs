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

const scan = (rule, name, source) => {
  const directory = tempDir("viqui-preference-");
  const path = join(directory, name);
  writeFileSync(path, source);
  const result = Bun.spawnSync({
    cmd: [process.execPath, cli, "scan", "--rule", rule, path],
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(result.exitCode).toBe(0);
  return JSON.parse(result.stdout.toString()).map(({ line, column }) => [
    line,
    column,
  ]);
};

test("reports boolean parameters but not boolean fields or returns", () => {
  expect(
    scan(
      "no-boolean-parameter",
      "file.ts",
      `
function f(enabled: boolean, flag = false, name: string): boolean { return enabled; }
const value: boolean = true;
`,
    ),
  ).toEqual([
    [2, 12],
    [2, 30],
  ]);
});

test("reports comments but permits recognized directives and strings", () => {
  expect(
    scan(
      "no-comments",
      "file.ts",
      `
// eslint-disable-next-line no-console
const text = "// not a comment"; // explain
/** documentation */
`,
    ),
  ).toEqual([
    [3, 34],
    [4, 1],
  ]);
  expect(
    scan(
      "no-comments",
      "file.py",
      `#!/usr/bin/env python3
# coding: utf-8
"""Module docs."""
value = "# text"  # explain
value = 1  # type: ignore  # reason
`,
    ),
  ).toEqual([[4, 19]]);
});

test("reports empty handlers while allowing handling and propagation", () => {
  expect(
    scan(
      "no-empty-exception-handler",
      "file.ts",
      `
try { run(); } catch (error) {}
try { run(); } catch (error) { throw error; }
`,
    ),
  ).toEqual([[2, 30]]);
  expect(
    scan(
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
  ).toEqual([[4, 1]]);
});

test("reports empty TypeScript blocks and permits comment-only catches", () => {
  expect(
    scan(
      "no-empty-exception-handler",
      "blocks.ts",
      "if (ready) {}\ntry { run(); } catch { /* ignored */ }\n",
    ),
  ).toEqual([[1, 12]]);
});

test("reports the fourth control-flow level, but resets inside functions and keeps else-if at the same level", () => {
  expect(
    scan(
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
  ).toEqual([[5, 7]]);
  expect(
    scan(
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
  ).toEqual([[2, 1]]);
});

test("reports more than two boolean conditions, including nested and negated expressions", () => {
  expect(
    scan(
      "no-complex-if-condition",
      "conditions.ts",
      `
if (a && b) run();
if (a || b || (c && d)) run();
if (!(a && b && c)) run();
`,
    ),
  ).toEqual([
    [3, 1],
    [4, 1],
  ]);
  expect(
    scan(
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
  ).toEqual([[3, 4]]);
});

test("scans JavaScript modules for complex conditions", () => {
  expect(
    scan("no-complex-if-condition", "module.mjs", "if (a && b && c) run();\n"),
  ).toEqual([[1, 1]]);
});

test("reports Python boolean parameters", () => {
  expect(
    scan(
      "no-boolean-parameter",
      "file.py",
      "def f(enabled: bool, count: int = 1, *, active=False):\n    pass\n",
    ),
  ).toEqual([[1, 7]]);
});

test("reports a positional boolean parameter once when both Ruff checks apply", () => {
  expect(
    scan(
      "no-boolean-parameter",
      "file.py",
      "def f(enabled: bool = True, *, active=False):\n    pass\n",
    ),
  ).toEqual([[1, 7]]);
});

test("reports boolean chains longer than three checks in any expression", () => {
  expect(
    scan(
      "no-long-boolean-chain",
      "chain.ts",
      `
const short = a && b && c;
const long = a && (b || c) && d;
function f() { return !(a || b || c || d); }
`,
    ),
  ).toEqual([
    [3, 14],
    [4, 25],
  ]);
  expect(
    scan(
      "no-long-boolean-chain",
      "chain.py",
      `
short = a and b and c
long = a and (b or c) and d
def f():
    return not (a or b or c or d)
`,
    ),
  ).toEqual([
    [3, 8],
    [5, 17],
  ]);
});

test("reports nested ternaries while allowing single conditional expressions", () => {
  expect(
    scan(
      "no-nested-ternary",
      "ternary.ts",
      `
const single = a ? b : c;
const chain = a ? b : c ? d : e;
const nested = a ? (b ? c : d) : e;
`,
    ),
  ).toEqual([
    [3, 23],
    [4, 21],
  ]);
  expect(
    scan(
      "no-nested-ternary",
      "ternary.py",
      `
single = b if a else c
chain = b if a else d if c else e
nested = (c if b else d) if a else e
`,
    ),
  ).toEqual([
    [3, 9],
    [4, 10],
  ]);
});
