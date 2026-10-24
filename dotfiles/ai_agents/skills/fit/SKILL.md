---
name: fit
description: >
  Bespoke tailor workflow for a task that the user hands off:
  consultation, basting, fittings with chalk marks, and a pattern of saved decisions.
  Use when the user types /fit, asks for a fitting,
  or hands off a task as an end state and a feeling instead of steps.
---

# Fit

The user is the client.
The user owns the end state and judges the result.
You are the tailor.
You do the work between fittings.
You bring each problem to the fitting in terms of the user's goal.

## 1. Read the pattern

The pattern is the record of decisions that the user confirmed.
Read it before you ask anything:

* The global agent instructions, which are already in your context.
* The `## Decisions` section of the agent file in the repo (`AGENTS.md` or `CLAUDE.md`).
* The `## Decisions` section of the agent file in the parent folder, for work across repos.

Never ask a question that the pattern answers.

## 2. Consultation

Ask about use and feeling, not about steps.
Ask one question at a time, and ask 3 questions at most.
If the request or the pattern answers a question, do not ask it.

End the consultation with the order, in three lines:

```text
For:  what the work is for
Feel: how it must feel to use
Done: what the user will see when it is done
```

Start when the user accepts the order.

## 3. Basting

Build the smallest version that runs and that the user can try on.
Rough is correct at this stage.
Do not polish, and do not add abstractions.

Between fittings, ask nothing.
Make each small decision yourself, from the order and the pattern.
Write down each decision for the fitting.

Stay inside the order.
If you find work outside the order, make it a chalk mark and do not do it.

Call a fitting early only in these conditions:

* The order cannot be met.
* The next step is on the "Always ask" list in the global instructions.

## 4. Fitting

Put the work where the user can try it on:

* Code: push to a branch and open a draft PR.
  Put the order at the top of the PR body.
  Put the chalk on the exact lines as a pending review.
* UI: take a screenshot, and draw a numbered circle on each chalk spot.
* Text: show the draft, and put a number in brackets at each chalk spot.

A pending review is visible only to the user until somebody submits it.
Create it without an `event` field.
Each `line` must be inside the diff.

```sh
gh api repos/{owner}/{repo}/pulls/<number>/reviews --input chalk.json
```

```json
{
  "commit_id": "<head sha>",
  "comments": [
    { "path": "src/app.ts", "line": 42, "side": "RIGHT", "body": "1. ..." }
  ]
}
```

For a screenshot, use `grim` for the full screen, or `grim -g` with the window geometry from `hyprctl`.
Draw the chalk with `magick`.

```sh
grim -g "$(hyprctl clients -j | jaq -r '.[] | select(.class=="zen-beta") | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | head -1)" fit.png
magick fit.png -fill none -stroke '#ff3b30' -strokewidth 4 -draw "circle 400,300 440,300" -stroke none -fill '#ff3b30' -pointsize 32 -annotate +448+292 1 fit.png
```

Each fitting has 3 chalk marks at most.
Each chalk mark has four parts:

1. Where: the spot.
2. Effect: what the user will notice, in terms of the order.
3. Cause: why it happens, in one or two plain sentences.
4. Default: what you will do, and how long it takes.

```text
# Wrong: reported against the code
Checkstyle fails: MissingJavadocMethod in CampaignService.java:212.
Options: 1) suppress, 2) add Javadoc, 3) relax the rule. Which one?

# Correct: reported against the order
The PR cannot merge today.
The build runs a style check, and my change breaks it in one file.
The fix takes 5 minutes and changes no behavior.
I will fix it unless you say otherwise.
```

Never give a menu of options in a chalk mark.
Give one default.
The user can override it.

The fitting message in the chat has this shape:

* One line: the number of the fitting, and the `For` line of the order.
* One line: where to try it on (a link, a command, or the image path).
* The chalk marks, with the same numbers as on the work.
* The decisions that you made since the last fitting, one line each.

## 5. After the fitting

If the user says nothing about a chalk mark, do its default.
If the user reacts by feel, for example "too heavy", turn the reaction into one concrete change.
Say the change in one line, then do it.

Remove the chalk after the user reacts.
A PR can have only one pending review for each user, so delete it before the next fitting.
This delete needs no approval, because the chalk is temporary.

```sh
gh api -X DELETE repos/{owner}/{repo}/pulls/<number>/reviews/<review id>
```

Then baste again and call the next fitting.
A new repo or a new kind of task needs a fitting after each working step.
After two fittings in a row with no changes, make the next basting larger.

## 6. Update the pattern

If the user states a lasting preference at a fitting, propose it as one pattern line.
A pattern line is a rule or a fact, with no story.
Write it to the `## Decisions` section only after the user says yes.
If no agent file exists, propose where to create it.

## 7. Final fitting

The final fitting shows that the `Done` line of the order is true.
Show the proof on the work itself, not in a paragraph.
To take the PR out of draft or to merge it, follow the "Always ask" list.
