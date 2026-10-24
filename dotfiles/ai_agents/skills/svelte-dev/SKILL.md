---
name: svelte-dev
description: Always load this skill when working with Svelte or SvelteKit
---

# Svelte Development Skill

## What is Svelte

Svelte is a **compiler-based UI framework** for building web applications.
Unlike React or Vue, which do their work in the browser at runtime, Svelte compiles components to vanilla JavaScript at build time.
This eliminates the need for a virtual DOM and ships minimal runtime code.

**Svelte 5** (current major version) introduced **runes** — a reactivity system based on compiler-recognized function calls (`$state`, `$derived`, `$effect`, etc.) that replace the old `$:` reactive statements and `export let` prop syntax from Svelte 4.
Runes make reactivity explicit, composable, and TypeScript-friendly.

Key characteristics:

- Components are `.svelte` files containing `<script>`, markup, and optional `<style>` in a single file
- Reactivity is declared with runes at the top level of the component script
- No virtual DOM — updates are surgically precise DOM mutations
- `$state()` creates deeply reactive proxies by default
- Side effects run with `$effect()`, computed values with `$derived()`
- Content composition uses **snippets** (`{#snippet}` / `{@render}`) instead of slots
- Props are declared via `$props()` destructuring; two-way binding requires `$bindable()`

**SvelteKit** is the official application framework built on Svelte, providing routing, SSR, file-based layouts, load functions, and adapters for deployment targets.

---

## References

### Reactivity patterns and common mistakes

Covered in the `frontend-dev` skill references:

- `references/svelte-reactivity-examples.md` — runes decision matrix, `$state`, `$derived`, `$effect`, `$effect.pre`, `$state.raw` vs `$state`, `$state.snapshot`
- `references/svelte-common-mistakes.md` — wrong/right examples for all common Svelte 5 anti-patterns

### `references/component-api.md`

Full reference for `$props()` and `$bindable()`. Covers basic prop destructuring, default values, rest props, TypeScript interfaces, generic components, and the `Props vs Bindable` decision tree. Explains controlled components (callback-only pattern), hybrid bindable+callback pattern, when `$bindable` is unnecessary, prop drilling vs. Context API, and TypeScript best practices for strict prop interfaces.

### `references/snippets-vs-slots.md`

Comparison table and migration guide from Svelte 4 slots to Svelte 5 snippets. Explains `{@render children()}` as the default slot replacement, named snippets as named slot replacements, snippet parameters as slot props replacements, optional snippet fallback patterns using `?.()`, reusable inline snippets, passing snippets as props, and TypeScript typing with `Snippet<[ParamType]>`. Includes a full migration guide for all slot variants and common mistakes.

### `references/migration-from-4-to-5-gotchas.md`

Side-by-side translation table covering every Svelte 4 → Svelte 5 syntax change: reactive statements → runes, `export let` → `$props()`, `on:event` → `onclick`, `<slot>` → `{@render}`, `onDestroy` → `$effect` cleanup, and bindable props. Highlights that stores still work in Svelte 5, covers reactive class fields, and provides a migration strategy (bottom-up, one component at a time, use TypeScript to catch errors early).

### `references/common-mistakes.md`

Top 10 Svelte 5 anti-patterns with wrong/right examples and explanations. Key pitfalls: using `$effect` for derived state (use `$derived`), using `$effect` instead of event handlers, optional chaining breaking effect dependency tracking, infinite loops from updating state inside `$effect`, mixing Svelte 4 and 5 syntax, forgetting `$state()` on reactive variables, missing `$bindable()` for two-way binding, using `{children}` instead of `{@render children()}`, and using `on:click` instead of `onclick`. Also covers deep reactivity behavior, `$state.raw()` performance usage, and TypeScript prop-typing mistakes.
