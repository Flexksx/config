---
name: code-quality
description: >
  Deterministic self-checks for code that need not exist: thin wrappers, stateless
  classes, boolean parameters, comments, empty exception handlers, deep nesting,
  nested ternaries, long boolean chains and complex conditions.
  Use on any coding task to run the check entrypoint on the files you changed, and
  when the user asks for a self-check, code review or a quality gate.
  Use it even for a one-line change, because these checks fail quietly when skipped.
  Do not use for design decisions or module boundaries; use `software-engineering`
  instead, or `ponytail` for the smallest complete change.
  Supports Python, TypeScript and Java.
---

# Code quality

These checks catch code that does not need to exist.
Code that does not need to exist is the expensive kind to maintain.
Every future reader must first decide whether it is safe to delete.

The central failure mode is the thin abstraction: a wrapper, class or
parameter that forwards work it adds nothing to.
Thin abstractions start cheap and evolve hard, because each one becomes a
decision point later code must route through.
See `references/thin-abstractions.md`.

The checks cover nine rules: boolean parameters, comments, complex if
conditions, deep nesting, empty exception handlers, long boolean chains,
nested ternaries, stateless classes and thin wrappers.

Findings are review prompts, not automatic fixes.
Each finding names a rule, file, line, column and one message.

## When to run

Run the check entrypoint on the files you changed before you finish any
coding task.
The global instructions require it.

## Entrypoint

The entrypoint is callable on its own, without the harness.

```sh
# Preferred: uv fetches ruff into its cache on first run.
uv run --project <skill-dir> python <skill-dir>/viqui/cli.py check <paths...>

# Python 3 only: runs the standard-library rules, reports the rest skipped.
python3 <skill-dir>/viqui/cli.py check <paths...>
```

`list` prints the installed rule ids as JSON.
`--rule <id>` runs one rule.
`--fail-on-findings` returns exit status 1 when findings exist, for CI.

## Routing table

The manifests under `viqui/rules/*/rule.json` are the single routing table.
Each rule declares its id, file extensions, runtime and entrypoint.
Do not copy rule ids anywhere else; that second list drifts.

The dispatcher reads the manifests and routes each file to the matching
scanner.
A scanner whose runtime is missing is reported as skipped on stderr, never
passed silently.

Exit status: 0 means no findings or findings without `--fail-on-findings`.
1 means findings with `--fail-on-findings`.
2 means invalid input or a scanner failure.

## Runtimes

| Runtime | Covers | First run |
| --- | --- | --- |
| python3 | five rules on `.py`, no dependencies | none |
| ruff | the four remaining `.py` rules | `uv run` fetches it |
| bun | `.ts`, `.js`, `.tsx`, `.jsx` and runs the `.java` scanners | `bun install` fetches packages |
| java + checkstyle jar | `.java` checks | the jar is fetched on first scan |

A machine with only python3 still covers every rule id.
See `references/findings-contract.md` for the schema and exit codes.

## Adding a rule

Create a directory `viqui/rules/<id>` with a `rule.json` manifest.
Each scanner reads absolute paths from argv and prints a JSON array of
findings.
Reuse the helpers in `viqui/shared`.
