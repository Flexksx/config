---
name: project-bootstrap
description: >
  How to use the project-bootstrap-template monorepo: clone it, run ./init,
  scaffold units with `just new`, run every task through `just`, and add a
  toolchain through nix. Also covers monorepo scope, contract libraries, and
  OpenAPI as the source of truth. Load when you create a repo, add an app or a
  lib, add a language, wire a build/format/lint/test task, or debug the
  just/moon/nix wiring. Combine with software-engineering and the
  language-specific skill.
---

# Project bootstrap

Template: `git@github.com:Flexksx/project-bootstrap-template.git`

`./init` deletes every `README.md` and empties `AGENTS.md`, so a fresh project
carries no wiring docs. This skill is the reference.

## Start a project

```bash
git clone git@github.com:Flexksx/project-bootstrap-template.git <name>
cd <name> && ./init && direnv allow
```

`./init` clears the docs, deletes `.git`, runs `git init`, then deletes itself.
`CLAUDE.md` stays a symlink to `AGENTS.md`. Fill `AGENTS.md` with the project
map and the unit roles.

## Who owns what

nix owns the dev shell and every system tool. moon owns the tasks, the graph,
and the cache. just owns the commands you type. uv owns Python. pnpm owns the
JavaScript workspace. lefthook owns the pre-commit hooks.

There is no proto and no `.prototools`. Every moon task sets
`toolchains: 'system'`, so moon installs nothing.

## Run a task

`just` is the only entry point. Never write `moon run` in a document, a script,
or a hook.

```bash
just format        # repo-wide, fixes
just lint          # repo-wide, gates
just build all
just test billing  # one unit
just start shop
just sync          # rebuild the unit indexes
```

`format` and `lint` have no per-unit form. moon runs them on the changed units
only. To bypass the cache, add `-f`. Every flag goes to `moon`.

## Add a unit

```bash
just new python      # asks for the name, and for lib or app
just new sveltekit
just new nuxt
```

The recipe generates the unit, stages it with `git add`, runs the frontend
wizard inside `nix develop`, then runs `just sync`. The `git add` matters,
because nix flakes ignore untracked files.

After the recipe, reload the shell. direnv does it on the next prompt. Without
direnv, enter `nix develop` again.

Do not name a unit `all`. The name collides with the repo-wide recipe.

## Add a language

One file: `.moon/tasks/<language>.yml`. It holds the commands and applies by
tag:

```yaml
inheritedBy:
  tags: ['python']
```

A unit `moon.yml` then declares metadata only: `language`, `layer`, `tags`.

Python tasks run `uv run <tool>` and depend on `install`. Keep the rules in the
unit `ruff.toml` and `ty.toml`, never in `pyproject.toml`. Frontend tasks call
the `package.json` scripts `format`, `lint`, `test`, `build` and `dev`.

To override an inherited task, redefine it in the unit `moon.yml`. Args append
by default, so set `mergeArgs: 'replace'` to drop them. A `script:` task needs a
`script:` override. moon ignores a `command:` override on it and reports no
error.

## Nix

The flake imports `./nix`, `./apps` and `./libs` with `flake-parts` and
`import-tree`. A repo-wide tool goes in `nix/`. A unit toolchain goes in
`<unit>/nix/devshell.nix`:

```nix
{
  perSystem = {pkgs, ...}: {
    shellPackages = [pkgs.uv];
  };
}
```

Every `shellPackages` list concatenates into one shell. Duplicates drop, but
conflicts do not resolve. If two units ask for a different Python, the first one
wins with no message.

`import-tree` skips a path that holds `/_`. Name a `callPackage` expression
`_package.nix`. Name the exact runtime version, for example `jdk21`.

Test a package with `nix build`. Never rebuild the system to test a project
flake.

## Traps

CAUTION: moon puts `~/.proto/shims` first on the `PATH`. A global proto install
beats the nix version. If proto is absent, every frontend task fails with
`proto-shim: Failed to execute proto`. Delete the stale shims.

- Do not add a `packageManager` field to a `package.json`. pnpm self-installs
  that version and defeats the nix pin.
- pnpm blocks a dependency build script until you list it in `allowBuilds`.
- `sv create` defaults to `@sveltejs/adapter-auto`. It can write no output and
  still report success. Pick a real adapter.
- `sv create` writes a `check` script that `lint` never calls. Append
  `&& pnpm run check` to `lint`.
- The Nuxt minimal template writes no `lint`, `format` or `test` script.

## Judgment calls

Default to a monorepo. Split the repos only for separate owners, separate
release dates, or a hard access boundary. Delete a directory that has no
occupant.

Split a backend service into three projects when another unit consumes its API:

- `*-client` holds the DTOs, the records, the HTTP interfaces, and the enums.
  No logic, no persistence, no framework boot.
- The service app holds the logic and implements the `*-client` interfaces.
- `*-client-starter` wires the client proxies for a consumer.

A consumer depends on the `-client`, never on the producer app.

When the API has a spec, the spec is the source of truth. Keep it in `openapi/`,
generate every client from it, and never edit a generated file by hand.
