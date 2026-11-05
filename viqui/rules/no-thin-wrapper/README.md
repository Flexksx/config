# Thin wrappers

This rule reports functions that only return a call with literal presets and unchanged parameters.
Each language implementation reports candidates whose in-file references are direct calls.
Findings are review prompts and have no automatic fix.

Run the shared scanner on files or directories:

```sh
viqui scan --rule no-thin-wrapper .
```

The output is a JSON array with `rule`, `file`, `line`, `column`, and `message` fields.
Line and column numbers start at one.
Errors are written to standard error and cause a nonzero exit.
The scanner supports `.ts`, `.tsx`, `.py`, and `.java` files.
It skips `.git`, `.venv`, `node_modules`, `__pycache__`, and symbolic links while traversing directories.

Install dependencies from the repository root:

```sh
bun install --frozen-lockfile
uv sync --all-packages --locked
```

The TypeScript scanner uses parser scope information and skips exports, callbacks, reassigned bindings, async functions, and wrappers that discard the call's return value.
The Python rule uses the standard library AST and reports only nested functions with no decorators or default arguments.
It skips callbacks and treats ambiguous same-name references conservatively.
Python module-level functions and methods are excluded because their public use cannot be established from one file.
Neither implementation resolves references across files.
The Java scanner is a Checkstyle `MatchXpath` query.
It reports a method whose whole body is a single `return` that calls a differently named method, forwarding each declared parameter exactly once with no added arguments.
It skips methods annotated `@Override`, methods without parameters, and calls that add or drop arguments.
So `int sum(int a) { return calc(a); }` is reported, while `int preset(int a) { return calc(a, 0); }` is not.
Vue and Svelte files are not supported.

Run the tests with:

```sh
bun run test
```

The TypeScript package uses Jest to exercise the scanner.
Jest runs its ESM tests with Node's experimental VM modules flag.
