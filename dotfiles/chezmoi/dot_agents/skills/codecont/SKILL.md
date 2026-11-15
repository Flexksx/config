---
name: codecont
description: >
  Use when asked about a new feature, asked about the current codebase,
  or asked to change something in an existing codebase.
---

# Code Context

## Phase 1 — Quick Overview

Do a fast, lightweight scan of the relevant area.
Use `rg`, `fd`, and targeted file reads — no subagents yet.
From this, form explicit hypotheses: named gaps, risks, or unknowns that need deeper
investigation.

## Phase 2 — Targeted Investigation

Spawn a `code-investigator` subagent (haiku) for each unresolved hypothesis.
Each subagent gets a narrow, specific question — not an open-ended exploration.
Run them in parallel.
Skip this phase entirely if the overview resolved all hypotheses.

## Phase 3 — Synthesis

Answer the user's question directly using what you found.
Every tradeoff and risk must be grounded in specific findings — not generic concerns.

Report:

- **Recommendation**: a concrete, argued position.
  Do not hedge.
  The user makes the final call, but an uncommitted answer adds no value.
- **Pitfalls**: concrete risks tied to specific code you found.
- **Unknowns**: gaps that neither the overview nor the subagents could resolve.
