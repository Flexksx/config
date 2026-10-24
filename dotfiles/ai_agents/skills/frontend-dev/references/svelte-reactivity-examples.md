# Svelte Reactivity Examples

## Runes Decision Matrix

| Need | Use | Why |
|------|-----|-----|
| Mutable state | `$state()` | Base reactive variable |
| Computed value | `$derived()` | Auto-updates when dependencies change |
| Complex computation | `$derived.by()` | Multi-line logic in function body |
| Large immutable data | `$state.raw()` | Skip deep reactivity for performance |
| Read-only snapshot | `$state.snapshot()` | Get plain JS value, no proxy |
| Side effect | `$effect()` | Run code when dependencies change |
| Pre-DOM effect | `$effect.pre()` | Run before DOM updates |
| Accept props | `$props()` | Declare component props |
| Bindable prop | `$bindable()` | Allow parent to bind to prop |

## $effect Decision Hierarchy

**$effect is an escape hatch.** Before using it, ask:

```text
Need to react to state change?
├─ Can use event handler? → USE EVENT HANDLER (preferred)
├─ Is it a computed value? → USE $derived
├─ Is it DOM-specific? → USE @attach
└─ External side effect? → USE $effect (with cleanup)
```

## $state

Use when you need a variable that changes and triggers UI updates.

```svelte
<script>
  let count = $state(0);
  let user = $state({ name: 'Alex', profile: { age: 30 } }); // deeply reactive
  let items = $state([1, 2, 3]);
</script>
```

Objects and arrays are deeply reactive by default.
Mutate nested properties directly: `user.profile.age = 31` works.
Reassignment also works: `user = { ...user, name: 'Bo' }`.

## $derived

Use when a value is calculated from other state.

```svelte
<script>
  let count = $state(0);
  let doubled = $derived(count * 2);
  let message = $derived.by(() => {
    if (count === 0) return 'Zero';
    return count > 10 ? 'High' : 'Low';
  });
</script>
```

Use `const` to make it truly read-only and prevent accidental reassignment.
Lazy — only computes when accessed.
Auto-tracks dependencies.

As of Svelte 5.25+, `$derived` values can be reassigned (they'll recalculate when dependencies change), but prefer `const` to prevent this.

```svelte
<script>
  let count = $state(0);
  const doubled = $derived(count * 2); // const = truly read-only

  function reset() {
    count = 0; // update source; derived follows
  }
</script>
```

## $effect

Use only for external side effects that can't be handled by event handlers, `$derived`, or `@attach`.

```svelte
<script>
  let count = $state(0);

  $effect(() => {
    document.title = `Count: ${count}`;
    return () => { document.title = ''; }; // cleanup
  });
</script>
```

Legitimate uses: logging, localStorage, document.title, WebSocket/interval setup, third-party library integration.

Does not run during SSR.
Runs after DOM updates.
Never update state that the effect reads — infinite loop.

## $effect.pre

Use when you need to run code before DOM updates (e.g., measuring DOM before changes).

```svelte
<script>
  $effect.pre(() => {
    // Runs BEFORE DOM updates
  });
</script>
```

## $props and $bindable

```svelte
<!-- Child.svelte -->
<script>
  let { name, age = 18, value = $bindable() } = $props();
</script>

<!-- Parent.svelte -->
<script>
  let text = $state('');
</script>
<Child bind:value={text} />
```

## $state.raw

Use for large immutable data or data you'll replace entirely rather than mutate.

```svelte
<script>
  let config = $state.raw(hugeConfigObject); // no proxy overhead
  let apiData = $state.raw(data);
  // later: apiData = newData; (full replacement, not mutation)
</script>
```

## $state.snapshot

Extract a plain JavaScript value from a reactive proxy.

```svelte
<script>
  let user = $state({ name: 'Alex', age: 30 });

  function save() {
    const plain = $state.snapshot(user);
    fetch('/api/users', { body: JSON.stringify(plain) });
  }
</script>
```

## $state.raw vs $state: Performance

Use `$state.raw()` when you don't need deep reactivity:

| Scenario | Use |
|----------|-----|
| Large immutable config | `$state.raw()` — no proxy overhead |
| Data replaced entirely (not mutated) | `$state.raw()` |
| Data with nested mutations needed | `$state()` |
| Small/medium mutable data | `$state()` |

```svelte
<script>
  let config = $state.raw(hugeConfigObject); // no proxy
  let apiData = $state.raw(data);
  // Replace entirely: apiData = newData;

  let user = $state({ profile: { name: 'Alex' } });
  user.profile.name = 'Bo'; // deep mutation works
</script>
```

Don't use `$state()` on constants — plain `const` is sufficient:

```svelte
<script>
  const API_URL = 'https://api.example.com'; // not $state
</script>
```
