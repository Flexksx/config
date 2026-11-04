# Viqui

Viqui runs checks independently of an agent using a Bun TypeScript CLI.
The [thin-wrapper rule](rules/no-thin-wrapper/README.md) and [stateless-class rule](rules/no-stateless-class/README.md) have TypeScript and Python implementations.
Viqui also reports boolean parameters, comments, empty exception handlers, deeply nested control flow, and complex `if` conditions.
Findings are review prompts, not automatic fixes.
Rule implementations may share code through `viqui/shared`.
Dependency-cruiser and import-linter check JavaScript, TypeScript, and Python rule imports as part of `bun run lint`.
The Python contract lists each Python rule explicitly in `import-linter.toml` and must be updated when adding a rule.
Static import checks cannot detect dynamic loading or runtime changes to Python import paths.

The boolean parameter rule checks explicit `boolean` annotations and boolean literal defaults in TypeScript declarations.
In Python it checks boolean-typed positional arguments and boolean positional defaults, allowing keyword-only arguments.
The comment rule checks Python, TypeScript, and JavaScript, allowing shebangs, Python encoding declarations, and recognized tool directives.
Python docstrings are not comments; TypeScript documentation comments are reported.
The empty exception handler rule reports Python handlers containing only `pass`.
In TypeScript it reports empty blocks, including catches, and allows blocks containing a comment.
The nesting rule reports control flow beyond three levels.
The TypeScript scanner counts `if`, loops, `try`, and `switch`, and resets depth in functions and classes.
The Python scanner uses Ruff's nested-block count.
The boolean-chain rule reports expressions with more than three checks in any context.
The nested-ternary rule reports conditional expressions nested directly inside another conditional expression.
The condition rule reports more than two boolean expressions in a Python `if` or checks joined by `&&` or `||` in TypeScript.
The Python rule does not count chained comparisons or all expressions behind negation as separate checks.
Neither rule reports conditional expressions or comprehensions as control-flow blocks.

The TypeScript scanners also check JavaScript files.
Each rule lives in a directory under `rules` and declares its scanners in `rule.json`.
Each rule has `ts/scan.ts` and `py/scan.py`, with language-specific files kept in their respective directories.
Each language directory contains `test/fixtures/valid` and `invalid` files with the language extension.
Run `bun run test` to check each scanner against its fixtures and verify the rule layout.
The manifest identifies the rule and lists each scanner's runtime, entrypoint relative to the rule directory, and supported file extensions.
Scanners receive absolute file paths as command-line arguments and write a JSON array of findings to standard output.
Findings follow the [shared schema](core/finding.schema.json), identify the declaring rule and refer to one of the files passed to the scanner.
Python scanners return `Finding` objects from `viqui.core.finding` and serialize them with `write_findings`.
TypeScript scanners use the `Finding` interface in `core/finding.ts`.
Lines and columns start at one.
Errors must be written to standard error and produce a nonzero exit.
The registry discovers installed rules and rejects invalid manifests and findings.

The Codex hook runs matching rules on files edited through `apply_patch`.
After shell commands, it scans changed and untracked Git files and reports each new file version once per session.
This can include pre-existing changes, and excludes ignored files and non-Git directories.
Its configuration is managed by chezmoi at `~/.codex/hooks.json`.
The Cursor hook runs matching rules on files edited through `Write` and `StrReplace`.
Its configuration is managed by chezmoi at `~/.cursor/hooks.json`.
The pi extension runs matching rules on files changed through `edit` and `write`, and on changed and untracked Git files after `bash`.
It lives at `~/.pi/agent/extensions/viqui` and reports findings in the tool result.
Install a release with `bun run install:viqui` from the repository root.
Installation requires uv to create Viqui's isolated Ruff environment.
The CLI runs on Bun, and it runs the TypeScript scanners with the same Bun binary.
The Python scanners require Python 3.
Add `~/.local/share/viqui/current` to your `PATH` to invoke `viqui` directly.
The hooks run the installed release at `~/.local/share/viqui/current`.
Run the install command again after changing the harness to create and activate a new release.
Project configuration keeps Bun and uv caches under `.cache` when commands run from the repository root.
Old releases remain in `~/.local/share/viqui/releases`.
Codex requires the hook to be reviewed and trusted through `/hooks` before it runs.
Restart or start a new Codex session if the new configuration is not discovered.
Cursor reloads `hooks.json` on save; restart Cursor if the new configuration is not discovered.

The hooks provide findings as feedback and do not undo an edit.
The Codex shell hook does not observe edits to ignored files or files outside Git repositories.
Run `viqui scan .` to check those files and changes made through other tools.
The test suite scans Viqui itself and excludes intentional violation fixtures.

`viqui list` prints installed rule identifiers as JSON.

Python uses Ruff `S110`, `FBT001`, `FBT002`, `PLR1702`, and `PLR0916` for the corresponding rules.
The `PLR1702` and `PLR0916` checks use Ruff's preview mode.
TypeScript uses Biome `noNestedTernary`, `noEmptyBlockStatements`, `useThisInClassMethods`, and `noStaticOnlyClass`.
Viqui installs pinned copies of both tools and runs them with its own configuration without applying fixes.
Ruff ignores `noqa` suppressions for these rules, while Biome honors its inline suppressions.

`viqui scan --rule no-stateless-class path/to/files` runs one rule.
Use `viqui --help` or `viqui scan --help` to see available commands and options.
Scan results are JSON, with file paths relative to the current working directory and exit status zero even when findings are present.
Use `--fail-on-findings` to return status 1 for findings, such as in CI.
Invalid input or a scanner failure returns status 2.
