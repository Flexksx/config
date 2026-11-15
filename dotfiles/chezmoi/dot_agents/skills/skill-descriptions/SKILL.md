---
name: skill-descriptions
description: >
  Framework for the `description` field of a SKILL.md.
  Use before writing a skill, before editing an existing description, or when a
  skill never loads, loads on the wrong prompts, or loads too often.
  Do not use for the body of a skill; that is ordinary technical writing.
---

# Skill descriptions

Agents preload `name` and `description` for every skill, and nothing else.
The description carries the whole routing decision.

## The shape

| Part | Answers | Example |
| --- | --- | --- |
| Capability | what knowledge the file holds | my NixOS config: module layout, which module owns which setting, flake inputs |
| Signals | the artifacts that appear when it applies | `.nix`, `flake.nix`, `nix build` |
| Trigger | imperative sentence in the user's words | Use before editing any `.nix` file under `~/config` |
| Reach | why it applies when the user names nothing | even for a one-line change, because the option path and the owning module are project conventions |
| Boundary | what it is not for, and what to load instead | Do not use for nixpkgs itself |

pi has no `paths` frontmatter field, so file types can only route through this text.

## Template

```yaml
description: >
  <Capability: the knowledge the file holds that the model would otherwise get wrong>.
  Use when <signals: files, extensions, commands, symbols in backticks>, or when the task mentions <the user's words>.
  Use it even <reach: the case where the user names nothing>.
  Do not use for <out of scope>; use `<other-skill>` instead.
```

## Budgets

* 1024 characters is the hard cap in the specification.
* Claude Code truncates the whole skill listing at 1536 characters, so the budget per skill is that number divided by how many skills you install.
* One signal per 100 characters, and never a signal an adjacent skill already claims.

## If a skill misbehaves

Only when one never loads, or loads on the wrong prompts. Writing a description does not need this.
Write 10 prompts that should load the skill and 10 near-misses that share keywords but need something else.
Run each three times in a fresh session and count the runs that read the skill file.
A should-load prompt passes at 2 of 3 or better; a near-miss at 1 of 3 or worse.
The split that stops you overfitting to your own test prompts is at `agentskills.io/skill-creation/optimizing-descriptions`.

```sh
pi --mode json -p "<prompt>" | grep -q "skills/<name>/SKILL.md" && echo hit || echo miss
```

## Gotchas

* "Always load this skill when working with X" names no artifact, so it routes nothing.
* Agents consult a skill only for work they cannot do alone, so claim the knowledge they lack: conventions, gotchas, where a setting belongs.
* Mechanics do not route. Levels, modes and section names belong in the body.
* Two skills claiming the same signal leave no choice, so the agent picks neither.

## Lint

```sh
bun scripts/lint.ts ~/.agents/skills
```

Checks the trigger sentence, at least one signal, and a boundary clause, and reports a signal that more than one skill claims.
Exit code 1 means a failure.
