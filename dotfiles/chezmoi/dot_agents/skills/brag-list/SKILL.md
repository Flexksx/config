---
name: brag-list
description: >
  Update an existing brag list with evidence-backed impact statements.
  Mines merged GitHub PRs via `gh` as the primary source, then asks what else
  is worth bragging about since the last update.
  Enforces a 3-part impact contract (action → result → evidence).
  Trigger for: "update my brag list", "add to my brag list", "what have I shipped since last time",
  "log recent work", "what did I do since [date]", "backfill my brag list",
  or any request to add recent accomplishments to an existing work log.
license: MIT
compatibility: 'Cross-platform (Windows, macOS, Linux). Requires git and gh CLI.'
metadata:
  version: "2.0"
argument-hint: 'Brag list file path + date range to scan (e.g. "brag.md, since last Monday")'
---

# Brag Sheet — Work Impact Writer

Update an existing brag list with new impact-first entries. Mines merged GitHub PRs as the primary source, then asks what else is worth bragging about that a PR list won't show.

USE FOR: "update my brag list", "add to my brag list", "what have I shipped since last time", "log recent work", "backfill my brag list"
DO NOT USE FOR: creating a brag list from scratch, project management, sprint planning, time tracking, ticket creation

## Agent Behavior Rules

1. **DO** ask for the brag list file path and the date range to scan before touching any source. Never assume either.
2. **DO** run `gh pr list` for that range as the primary source.
3. **DO** ask if there's other work to brag about that PRs won't show — incidents, design docs, mentoring, cross-team work.
4. **DO** always include all three parts: action → result → evidence. If evidence is missing, write `(evidence needed)` — never silently omit.
5. **DO** show drafted entries before appending to the file. Never auto-save.
6. **DO** group related PRs/commits into a single entry.
7. **DO** preserve the user's voice. Reframe for impact, but don't invent accomplishments or inflate scope.
8. **DO NOT** fabricate metrics, team sizes, or impact numbers.
9. **DO NOT** write an entry for verbally-described work without asking for a PR, doc, or other reference.
10. **DO NOT** draft entries before the PR scan and the "anything else?" question are both done.

## Entry Format

Every entry uses impact-first framing with three required parts:

```text
Did [action] → [result/impact] → [evidence]
```

**Do not output an entry unless it includes all three parts.** If evidence is missing, ask for it or mark as "(evidence needed)".

### Anti-Patterns

| ❌ Don't | ✅ Do instead |
|---------|--------------|
| "Fixed a bug in auth" | "Fixed token refresh race condition → eliminated 401s affecting 12% of API calls → PR #247" |
| "Worked on dashboards" | "Built latency dashboard in Grafana → on-call detects P95 spikes in <2min → deployed to prod" |
| Invent a metric: "saved 40% of eng time" | Ask: "Do you have a rough estimate, or should I keep this qualitative?" |
| One entry per commit | Group related commits into one entry with highest-impact framing |
| Passive voice: "The pipeline was improved" | Active voice: "Built CI matrix → caught Windows-only bug before release" |
| List technologies used | State the outcome: "Migrated 4 services to IaC → deploy time 45min → 8min" |

## Evidence Ladder

Not every entry needs a metric. Use the strongest evidence available:

| Strength | Evidence type | Example |
|----------|--------------|---------|
| 🥇 Best | Quantified metric | "Reduced P95 latency from 800ms to 120ms" |
| 🥈 Strong | PR, commit, or doc link | "PR #312, design doc in wiki" |
| 🥉 Good | Observable outcome | "Unblocked Team X", "Resolved Sev2 incident Y" |
| ✅ Acceptable | Qualitative + context | "Reduced toil for on-call rotation — see updated runbook" |
| ⚠️ Weak | Activity only | "Worked on auth" — reframe or mark `(evidence needed)` |

Never invent a metric to fill the gap. Qualitative evidence with context beats fabricated numbers.

## Categories

| ID | Emoji | Use for |
|----|-------|---------|
| `pr` | 🚀 | Merged PRs, shipped features |
| `bugfix` | 🐛 | Bug fixes, incident patches |
| `infrastructure` | 🏗️ | Infra, deployments, migrations |
| `investigation` | 🔍 | Root cause analysis, debugging |
| `collaboration` | 🤝 | Reviews, mentoring, design discussions |
| `tooling` | 🔧 | Dev tools, scripts, automation |
| `oncall` | 🚨 | Incident response, on-call wins |
| `design` | 📐 | Design docs, architecture decisions |
| `documentation` | 📝 | Docs, runbooks, guides |

## Update Workflow

### Step 1: Get scope

Ask for:

- Brag list file path
- Date range to scan (since when)

### Step 2: Scan merged PRs

```bash
gh pr list --author @me --state merged --limit 50 \
  --json number,title,repository,mergedAt \
  --search "merged:>=2025-04-01"
```

If `gh` isn't available, or a repo has no PR history, fall back to:

```bash
git log --author="$(git config user.email)" --since="2025-04-01" \
  --pretty=format:'%h|%ad|%s' --date=short --no-merges
```

### Step 3: Ask about other sources

Prompt: "Anything else to brag about since [date] that a PR list won't catch? Incidents, design docs, mentoring, cross-team work, talks?"

### Step 4: Group related work

- Same PR + its commits → 1 entry
- Multiple commits on the same feature within a few days → 1 entry
- Non-PR items from Step 3 → their own entries

### Step 5: Draft entries

Write impact-first entries for each group. Assign a category.

### Step 6: Present and refine

Show all drafted entries to the user. Adjust based on feedback.

### Step 7: Append to the file

Read the existing file first to match its structure (headings, grouping).
Append new entries — never rewrite or reformat existing ones.

```markdown
## Week of 2025-04-14

### 🚀 PRs & Features

- **Migrated auth service to managed identity** → eliminated 3 secret rotation incidents/quarter → PR #312
```

## Output Contract

Before finishing, ensure:

1. Every entry has action → result → evidence (mark `(evidence needed)` if missing)
2. No fabricated metrics — only user-provided or source-verified data
3. Entries shown to user before appending
4. Date range explicitly stated
5. New entries match the existing file's format

## Gotchas

### No PRs in range

Ask if there's a different repo or org to check.
Fall back to the guided interview — not all impactful work leaves a PR trail (design docs, incident response, mentoring).

### Long gap since last update

Commit logs get noisy over months.
Prefer `gh pr list --state merged` with an explicit date range over `git log` for long spans.

### User can't quantify impact

Not every entry needs a number. See the Evidence Ladder above. Never invent a metric to fill the gap.

### "Brag" might mean something else

The user might say "brag about this feature to my team" (a launch announcement, not a work entry). Confirm intent if ambiguous.

### Co-authored commits or PRs

If multiple authors appear on the same work, ask: "Should I credit this as your work, shared work, or skip it?"
