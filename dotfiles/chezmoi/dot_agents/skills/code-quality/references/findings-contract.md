# Findings contract

A finding is a JSON object with five fields.

```json
{
  "rule": "no-thin-wrapper",
  "file": "./src/example.py",
  "line": 1,
  "column": 1,
  "message": "This wrapper only delegates with preset arguments."
}
```

The schema lives at `viqui/core/finding.schema.json`.
Lines and columns start at one.

## Scanners

A scanner receives absolute file paths as command-line arguments.
It prints a JSON array of findings to stdout.
Errors go to stderr and produce a nonzero exit.

Scanners must only report files they were given, and must report their own
rule id.
The dispatcher rejects any finding that breaks this contract and exits 2.

## Skipped rules

A rule is skipped, not failed, when its runtime is missing.
The dispatcher reports the skip on stderr:

```text
code-quality: skipped no-comments (ts): bun not available on PATH
```

This is deliberate.
A rule that runs partially and passes silently is worse than a rule that
reports itself unavailable.

## Exit status

| Status | Meaning |
| --- | --- |
| 0 | no findings, or findings without `--fail-on-findings` |
| 1 | findings with `--fail-on-findings` |
| 2 | invalid input or a scanner failure |
