# Svelte 5 Common Mistakes

## $effect for derived state

```svelte
<script>
  // bad: $effect is for side effects, not computed values
  let count = $state(0);
  let doubled = $state(0);
  $effect(() => { doubled = count * 2; });

  // good
  let count = $state(0);
  const doubled = $derived(count * 2);
</script>
```

## $effect instead of event handler

```svelte
<script>
  // bad: $effect re-runs on every count change just to log
  let count = $state(0);
  $effect(() => { console.log(`Count is now ${count}`); });

  // good: side effect belongs in the handler
  let count = $state(0);
  function increment() {
    count++;
    console.log(`Count is now ${count}`);
  }
</script>

<button onclick={increment}>Increment</button>
```

## $effect to sync linked values

```svelte
<script>
  // bad: two effects trying to sync each other — fragile, order-dependent
  let celsius = $state(0);
  let fahrenheit = $state(32);
  $effect(() => { fahrenheit = (celsius * 9) / 5 + 32; });
  $effect(() => { celsius = ((fahrenheit - 32) * 5) / 9; });

  // good: update both values in the event handler
  let celsius = $state(0);
  let fahrenheit = $state(32);
  function updateFromCelsius(e) {
    celsius = +e.target.value;
    fahrenheit = (celsius * 9) / 5 + 32;
  }
  function updateFromFahrenheit(e) {
    fahrenheit = +e.target.value;
    celsius = ((fahrenheit - 32) * 5) / 9;
  }
</script>

<input type="number" value={celsius} oninput={updateFromCelsius} />
<input type="number" value={fahrenheit} oninput={updateFromFahrenheit} />
```

## Optional chaining breaks effect dependency tracking

```svelte
<script>
  // bad: if particles is undefined, scheme is never read → no dependency created
  // effect won't re-run when scheme changes
  let particles = $state(undefined);
  let scheme = $state('dark');
  $effect(() => { particles?.updateScheme(scheme); });

  // good: read all dependencies before any short-circuit
  $effect(() => {
    const currentScheme = scheme; // dependency registered unconditionally
    if (particles) particles.updateScheme(currentScheme);
  });
</script>
```

## Infinite loop in $effect

```svelte
<script>
  // bad: effect reads count and writes count → infinite loop
  let count = $state(0);
  $effect(() => { count++; });

  // good option 1: write to different state
  let count = $state(0);
  let log = $state([]);
  $effect(() => { log.push(count); });

  // good option 2: read without subscribing via untrack()
  import { untrack } from 'svelte';
  let count = $state(0);
  $effect(() => {
    const current = untrack(() => count); // no dependency created
    sendAnalytics(current);
  });
</script>
```

## $effect to sync DOM elements

```svelte
<script>
  // bad: dialog.close() fires the native 'close' event → triggers handler → loop
  let is_open = $state(false);
  let dialog_element = $state<HTMLDialogElement>();
  $effect(() => {
    if (is_open) dialog_element?.showModal();
    else dialog_element?.close();
  });
</script>
<dialog bind:this={dialog_element} onclose={() => is_open = false}>

<!-- good: use @attach to register the element; call DOM methods directly -->
```

```ts
// state.svelte.ts
class DialogState {
  dialog: HTMLDialogElement | null = null;
  is_open = $state(false);

  register = (el: HTMLDialogElement) => {
    this.dialog = el;
    return () => { this.dialog = null; };
  };

  open() { if (!this.dialog?.open) { this.is_open = true; this.dialog?.showModal(); } }
  close() { this.is_open = false; this.dialog?.close(); }
}
```

```svelte
<dialog {@attach dialog_state.register} onclose={dialog_state.close}>
```

## Runes inside functions

```svelte
<script>
  // bad: runes must be statically analyzable — not inside function bodies
  function createCounter() {
    let count = $state(0); // compile error
  }

  // good option 1: top-level
  let count = $state(0);

  // good option 2: reactive class fields
  class Counter {
    count = $state(0);
    doubled = $derived(this.count * 2);
  }
  const counter = new Counter();
</script>
```

## Forgetting $state on reactive variables

```svelte
<script>
  // bad: plain let is not reactive in Svelte 5
  let count = 0;

  // good
  let count = $state(0);
</script>

<button onclick={() => count++}>{count}</button>
```

## Missing $bindable for two-way binding

```svelte
<!-- bad: parent can't bind to a non-bindable prop -->
<!-- Child.svelte -->
<script>
  let { value } = $props();
</script>
<input bind:value />
<!-- Parent: <Child bind:value={text} /> → ERROR -->

<!-- good -->
<!-- Child.svelte -->
<script>
  let { value = $bindable() } = $props();
</script>
<input bind:value />
<!-- Parent: <Child bind:value={text} /> → works -->
```

## {children} instead of {@render children()}

```svelte
<script>
  let { children } = $props();
</script>

<!-- bad: children is a Snippet, not a value — renders [object Object] -->
<div>{children}</div>

<!-- good -->
<div>{@render children()}</div>
```

## on:event instead of onclick

```svelte
<!-- bad: Svelte 4 directive syntax -->
<button on:click={handler}>Click</button>
<button on:click|preventDefault={handler}>Click</button>

<!-- good: standard DOM property syntax -->
<button onclick={handler}>Click</button>
<button onclick={(e) => { e.preventDefault(); handler(e); }}>Click</button>
```

## Mixing Svelte 4 and 5 syntax

```svelte
<script>
  // bad: $state with $: reactive statement
  let count = $state(0);
  $: doubled = count * 2;
</script>
<button on:click={() => count++}>{count}</button>

<script>
  // good: runes only
  let count = $state(0);
  const doubled = $derived(count * 2);
</script>
<button onclick={() => count++}>{count}</button>
```

## Untyped props

```svelte
<script lang="ts">
  // bad
  let { name, age } = $props();

  // good
  interface Props { name: string; age: number; }
  let { name, age }: Props = $props();
</script>
```

## Wrong bindable type (must be optional)

```svelte
<script lang="ts">
  // bad: value is required but $bindable implies optional
  let { value = $bindable() }: { value: string } = $props();

  // good
  let { value = $bindable('') }: { value?: string } = $props();
</script>
```

## Unnecessary $bindable

```svelte
<script>
  // bad: label is read-only, no reason for two-way binding
  let { label = $bindable('Submit') } = $props();

  // good
  let { label = 'Submit' } = $props();
</script>
```

## Unnecessary $derived for single-use inline values

```svelte
<script>
  // bad: wrapping a value used once
  let { count } = $props();
  let doubled = $derived(count * 2);
</script>
<p>{doubled}</p>

<!-- good: inline is fine -->
<script>
  let { count } = $props();
</script>
<p>{count * 2}</p>
```
