# Vue Reactivity Examples

## Primitives Decision Matrix

| Need | Use | Why |
|------|-----|-----|
| Reactive primitive or object | `ref()` | Works for any value, access via `.value` |
| Reactive object (no `.value`) | `reactive()` | Convenient for objects, but can't be reassigned |
| Computed value | `computed()` | Lazy, cached, auto-tracks dependencies |
| Watch with old/new value | `watch()` | Explicit source, runs on change |
| Watch any accessed reactive data | `watchEffect()` | Auto-tracks, runs immediately |

## ref

Use for any reactive value.
Access and mutate via `.value` in script; templates unwrap automatically.

```typescript
const count = ref(0);
count.value++;

const user = ref<User | null>(null);
```

## computed

Use when a value is derived from other reactive state.
Lazy and cached — only recomputes when dependencies change.

```typescript
const user = ref<User | null>(null);
const userRole = computed(() => user.value?.role);
const isAdmin = computed(() => userRole.value === 'admin');
```

Never use `watch` to sync one ref from another when `computed` can express the relationship.

## watch

Use when you need to react to a specific source and access the previous value, or trigger async work.

```typescript
const userId = ref<string | null>(null);

watch(userId, async (newId, oldId) => {
  if (newId === null) return;
  userData.value = await fetchUser(newId);
});
```

Watch a getter for nested values:

```typescript
watch(
  () => user.value?.profile.age,
  (age) => { console.log('Age changed to', age); }
);
```

## watchEffect

Use when you want to run a side effect immediately and re-run whenever any reactive value it reads changes.
Does not give you the previous value.

```typescript
watchEffect(() => {
  document.title = `Hello, ${user.value?.name ?? 'Guest'}`;
});
```

Cleanup:

```typescript
watchEffect((onCleanup) => {
  const timer = setInterval(() => tick(), 1000);
  onCleanup(() => clearInterval(timer));
});
```

## Anti-Patterns

### Using watch to sync derived state

```typescript
// Bad
const user = ref<User | null>(null);
const userRole = ref<string | undefined>();
watch(user, (u) => { userRole.value = u?.role; });

// Good
const user = ref<User | null>(null);
const userRole = computed(() => user.value?.role);
```

### Circular watcher

```typescript
// Bad — watcher modifies the ref it watches
const count = ref(0);
watch(count, (val) => { count.value = val + 1; }); // infinite loop

// Good — derive instead
const count = ref(0);
const displayCount = computed(() => count.value + 1);
```

### Mutating a computed ref

```typescript
// Bad — computed values are read-only
const doubled = computed(() => count.value * 2);
doubled.value = 10; // runtime warning

// Good — mutate the source
count.value = 5; // doubled updates automatically
```

### Losing reactivity by destructuring reactive()

```typescript
// Bad — destructuring breaks reactivity
const state = reactive({ count: 0, name: 'Alex' });
const { count } = state; // count is now a plain number, not reactive

// Good — use toRefs or keep ref()
const count = ref(0);
// or
const { count } = toRefs(state);
```
