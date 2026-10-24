---
name: daily-status
description: |
  Generate a daily Slack status post from today's GitHub PRs, Jira updates,
  Confluence edits, and conversation context. Structured as bullet points
  with topics, resource URLs, and concrete achievements. Designed to make
  engineering work visible, build trust, and show progress to leadership.
  Trigger for: "daily status", "daily update", "standup post",
  "what did I do today", "slack status", "EOD update", "end of day post",
  "status post".
  Do not use for: brag lists (use brag-list), sprint planning, retros,
  weekly summaries, or status pages.
---

# Daily Status Post Generator

Generate a concise daily Slack status update from real work artifacts.
The post makes engineering work visible, shows progress, and builds trust
with your manager and team.

## Why This Exists

Hard work alone does not get noticed. Everyone around you works hard too.
Hard work makes you average, not visible (Ethan Evans). A daily status
post is the cheapest way to stay visible without playing games.

Your manager needs four signals from you every day:

1. Am I on track?
2. What actually shipped?
3. What is next?
4. Where am I stuck or waiting on someone?

A "no" or a blocker on Monday is fine. A surprise on Friday is what
breaks trust. The update exists to eliminate surprises.

### What a good daily status does

- Takes things off your manager's plate. A manager who never has to ask
  "where are we on X?" trusts you more and advocates for you in rooms
  you are not in (Ethan Evans: your manager has their own boss to
  report to, and a clean status gives them material they can forward
  without rewriting it).
- Shows you are on track. Consistent updates build a track record that
  speaks for you at review time. One update means nothing. Fifty in a
  row means you are reliable.
- Signals blockers early. When something stalls, the update says so. Your
  manager can help before the delay compounds. The rule: stuck for
  30 minutes, post the question, switch to something else.
- Creates a written record. Promotion cases are built on evidence, not
  memory. A daily log is the raw material for your brag list and your
  manager's calibration notes.

### Patterns to follow

- *Close loops visibly.* Every update that says "Done" or "Merged" on a
  previously open item builds trust faster than opening new things
  (Will Larson, "Staff Engineer").
- *Surface decisions, not activity.* "Decided X" is more useful than
  "worked on X." Decisions show judgment. Activity shows presence.
- *Flag risks without drama.* "Blocked on Y, pinged Z" is the right
  tone. No alarm, no blame, just the state and the action you took.
- *No surprises.* Bad news in a status update is fine. Bad news that
  your manager hears from someone else first is a trust failure.
- *Ask, don't guess.* If you are waiting on input or a decision, name
  the person and the question in the open questions section. That turns
  a silent block into a visible one your manager can help unblock.

### Patterns to avoid

- *Invisible grinder.* Shipping without telling anyone. Your skip-level
  does not read your PRs. If you do not write it down, it did not happen
  for anyone above your direct manager.
- *Self-promotion.* Inflating small work to sound big. People see through
  it fast and it erodes trust. State facts at the right altitude.
- *Noise generator.* Listing every meeting, every Slack reply, every
  trivial commit. Volume is not visibility. A focused update with three
  real items beats a wall of text with twelve.
- *Only reporting good news.* Skipping updates on bad days or blocked
  days. Inconsistency makes people wonder what you are hiding on the
  quiet days.

## Agent Behavior Rules

1. **DO** gather data before writing anything.
2. **DO** include only work from today (or the date the user specifies).
3. **DO** link every artifact (PR, Confluence page, Jira ticket, Slack thread).
4. **DO** state the impact, not the activity. "Updated", "created", "added"
   are presence words. They tell people you were at work, not what changed
   because of your work. Rewrite every bullet to answer "so what?" A PR
   that "added retry logic" is really "failed charges now retry three
   times before going to dead-letter." A doc that was "updated" really
   "resolved the validation split" or "locked in the backoff intervals."
   If you cannot answer "so what?" for a bullet, the bullet is not ready.
5. **DO** include metrics only when the work directly changed the metric.
   "Reduced rebuild time from 45 min to 12 min" is a real outcome.
   "Opened a 2,200-line PR" or "touched 8 modules" is a vanity metric
   that describes effort, not impact. Line counts, file counts, commit
   counts, and module counts do not belong in a status update. If the
   work did not move a number that matters to the product or the team,
   do not invent one.
6. **DO** keep each bullet to one line when possible.
7. **DO** run `/simple-english` rules on the final output. Use active voice,
   simple tenses, 25-word sentence limit. No hedges, no filler.
8. **DO** run `/humanize` on the final output. Cut AI vocabulary, inflated
   significance, and promotional language.
9. **DO** show the draft to the user before posting.
10. **DO NOT** fabricate or inflate achievements.
11. **DO NOT** include items with no concrete progress.
12. **DO NOT** use jargon without context. A reader outside your team must
    follow the gist.
13. **DO NOT** write more than 10 bullet points. If the day had more items,
    group related work.

## Data Gathering

Collect from these sources in parallel. Skip any source that returns nothing.

### 1. GitHub PRs

```bash
gh pr list --author @me --state all --limit 20 \
  --json number,title,url,state,createdAt,updatedAt,additions,deletions,labels \
  --repo <repo>
```

Filter to PRs created or updated today. For each PR, note:

- Whether it was opened, updated, or merged today
- Key changes (from the PR body or diff stats)
- What remains before merge

Check all repos the user works on. If unknown, ask or check `gh repo list`
and recent git remotes.

### 2. Jira

Search for issues the user updated today:

```text
assignee = currentUser() AND updated >= "YYYY-MM-DD" ORDER BY updated DESC
```

Also search for issues where the user is the reporter or commenter today.
For epics, note what specifically changed (status, scope, child tickets).

### 3. Confluence

Search for pages the user edited today:

```text
contributor = currentUser() AND lastmodified >= "YYYY-MM-DD" AND type = page
```

For each page, note what decisions were made, what iterations happened,
or what sections changed. A "touched the doc" bullet is worthless. State
the decision or the content that moved forward.

### 4. Conversation context

Scan the current conversation and any prior conversations from today for:

- Design decisions made
- Problems debugged
- Code written or reviewed
- Architecture discussions

### 5. Slack threads (if accessible)

Search for threads the user participated in today. Include threads where
the user drove a decision, unblocked someone, or answered a question.

## Output Structure

The output must be plain text that pastes directly into Slack with no
rendering issues. Slack supports a limited subset of markdown: `*bold*`,
`_italic_`, `~strikethrough~`, inline `code`, and bare URLs (which Slack
auto-links and previews). Nothing else.

Do not use:

- `**double asterisks**` (Slack does not render them as bold)
- `[text](url)` markdown links (Slack shows them raw)
- `#` headings
- Nested bullet indentation deeper than one level (Slack flattens it)
- HTML tags

### Template

```text
*Project or Epic Name*

- *Topic* — <bare URL>
  Achievement in past tense, active voice
  Second achievement if needed
  Next: what happens tomorrow (only if concrete)

- *Topic* — <bare URL>
  Achievement

*Open questions / waiting on*

- Question or blocker, addressed to a specific person if possible
- Decision needed from someone, with enough context to act on
```

### Rules

- Group by project or epic, not by tool.
- A PR and its Jira ticket belong under one bullet, not two.
- `*single asterisks*` for bold in Slack. Nothing else for emphasis.
- Bare URLs only. Slack auto-links and shows previews.
- One level of bullet indentation max. Sub-points are plain lines
  under the bullet, no dash prefix.
- "Next:" prefix for forward-looking items. Only when the next step
  is concrete and worth signaling.
- No greeting, no sign-off, no "Happy Monday", no emoji overload.
- One blank line between project groups.
- The "Open questions / waiting on" section goes at the bottom. It
  contains blockers, pending decisions, and questions addressed to
  specific people. If there are none, omit the section entirely.
  Each item should name who you are waiting on and what you need.
  Keep it actionable: "Waiting on X for Y" not "might need to
  discuss Z at some point."

## Quality Checklist

- [ ] Output pastes into Slack with correct formatting (no raw markdown)
- [ ] Every bullet states impact, not activity ("so what?" test passes)
- [ ] No presence verbs as the main verb (updated, created, added, worked on)
- [ ] No vanity metrics (line counts, file counts, module counts, commit counts)
- [ ] Metrics included only when the work directly changed the metric
- [ ] Every artifact has a bare URL
- [ ] No bullet exceeds two lines
- [ ] Active voice throughout
- [ ] No AI vocabulary (leverage, utilize, ensure, robust, streamline,
      comprehensive, foster, enhance, facilitate, moreover, furthermore)
- [ ] No hedging (should, might, could, may, potentially)
- [ ] No inflated significance ("critical improvement", "major milestone")
- [ ] Grouped by project, not by tool
- [ ] Under 10 top-level bullets
- [ ] A reader outside your team can follow the gist

## Draft Review

After writing the draft, spawn a subagent with clean context to review
it. Pass the subagent the draft and the quality checklist above. The
subagent returns pass/fail per checklist item, with rewrites for any
failing bullets. If anything fails, fix the draft before showing it to
the user.

## Example Output

```text
*Payment Processing (PROJ-1234)*

- *Retry logic for failed charges* — https://github.com/acme/billing/pull/892
  Failed charges now retry with exponential backoff (3 attempts) before dead-lettering
  Timeout and 5xx errors retry, 4xx errors skip (no point retrying bad input)
  Next: wire the dead-letter queue consumer (PR 2 of 3)

- *Charge failure design doc* — https://acme.atlassian.net/wiki/spaces/ENG/pages/12345
  Locked in backoff intervals: 1s, 10s, 60s (based on Stripe's rate-limit guidance)
  Dropped the circuit-breaker option after reviewing last month's failure data

*Search Infrastructure (PROJ-5678)*

- *Index rebuild pipeline, merged* — https://github.com/acme/search/pull/445
  Full rebuild now takes 12 min on staging, down from 45 min
  All three stacked PRs merged

*Open questions / waiting on*

- @alice: need a decision on whether dead-letter retries go to the same queue or a separate one before I start PR 2
- @bob: staging dataset is missing the last two weeks of prod data, can you refresh it?
```

## Anti-Patterns

This is a status update, not a brag list. State what happened at a high
level. Do not pad with numbers, metrics, or implementation details that
only make sense to you.

| Bad | Why | Better |
|-----|-----|--------|
| "Updated the design doc" | Presence, not impact. So what? | "Resolved the validation split: build-time for literals, runtime for expressions" |
| "Created a PR for the entity skeleton" | Activity verb, says nothing about what changed | "Email V2 type now compiles and persists across all layers (dark launch, PR 1 of 5)" |
| "Added retry logic to the charge worker" | What does retry logic do for anyone? | "Failed charges now retry three times before going to dead-letter" |
| "Worked on the feature" | Too vague, could mean anything | "Entity skeleton is ready for review, blocks the REST CRUD PR" |
| "Made progress on the epic" | What progress? | "First task moved to In Progress, PR is up for review" |
| "Added type across 8 modules with 6 validation exceptions" | Too granular, reads like a commit log | "New action type wired across all layers" |
| "Had discussions about architecture" | No outcome | "Agreed to split preview into a separate ticket" |
| "Reviewed 3 PRs" | Count is noise | "Reviewed the migration PR, flagged a missing rollback step" |

## Edge Cases

### Nothing concrete today

If the day was meetings, reviews, or blocked work, say so honestly:

- "Reviewed X, unblocked Y" is valid.
- "Blocked on Z, followed up with W" is valid.
- An empty status is better than a padded one.

### Multiple projects

Use separate headings per project. Keep the most important project first.

### User provides extra context

If the user mentions work that the tools did not find (a call, a decision,
a whiteboard session), include it with whatever evidence they provide.

### Weekend or off-hours

If the date has no work artifacts, ask if the user wants to skip or
report on the nearest workday instead.
