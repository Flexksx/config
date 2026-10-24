---
name: frontend-dev
description: >
  Always use when doing any web frontend development work.
  Covers reactivity principles and framework-specific patterns for Svelte and Vue.
---

# Web Frontend Development

This skill covers frontend development principles and reactivity patterns.
Always combine with the framework-specific skill when working in Svelte or Vue.

**Framework skills to load alongside this one:**

* Svelte → load `svelte-dev` skill

## General Coding Standards

Mandatorily read coding standards by loading the `software-engineering` skill.

Avoid `index.ts` barrel export files.
Those get out of sync really fast.
Prefer importing each function/class individually.

---

## Reactivity

Reactivity means the UI updates automatically when state changes.
Think of it as a directed graph: state flows one way into derived values, which flow into the UI.

**Core principle: derive, don't sync.**
If a value can be computed from other state, it must be computed — not stored separately and kept in sync via effects.
Effects are for external side effects only (logging, DOM APIs, subscriptions).
Using an effect to update another piece of state is almost always wrong.

### State → Derived State (correct)

```text
state ──► derived ──► UI
```

### State → Effect → State (avoid)

```text
state ──► effect ──► other state ──► UI   ← broken chain, race-prone
```

### Mistake 1: Using effects for derived values

**Vue:**

```typescript
// Bad
const user = ref<User | null>(null);
const userRole = ref<string | undefined>();
watch(user, (u) => { userRole.value = u?.role; });

// Good
const user = ref<User | null>(null);
const userRole = computed(() => user.value?.role);
```

**Svelte:**

```typescript
// Bad
let user = $state<User | null>(null);
let userRole = $state<string | undefined>();
$effect(() => { userRole = user?.role; });

// Good
let user = $state<User | null>(null);
let userRole = $derived(user?.role);
```

### Mistake 2: Circular dependencies

A circular dependency occurs when A depends on B and B depends on A.
It creates an infinite update loop.
The fix is always the same: identify the single source of truth and derive everything else from it.

**Vue:**

```typescript
// Bad — two refs updating each other via watchers
const count = ref(0);
watch(count, (val) => { count.value = val + 1; });

// Good — one source, one derived value
const count = ref(0);
const displayCount = computed(() => count.value + 1);
```

**Svelte:**

```typescript
// Bad — effect reads and writes the same state
let price = $state(10);
let tax = $state(1);
$effect(() => { price = price + tax; });

// Good — one-way dependency chain
let basePrice = $state(10);
let taxRate = $state(0.1);
let totalPrice = $derived(basePrice * (1 + taxRate));
```

## Handling data and Resources

Handling data and resources should follow the general principles of layered architecture.
Each layer should have a clear responsibility and be responsible for its own data and resources.

Keep in mind that frameworks like Vue and Svelte are really close to a MVVM architecture.
The `<script>` tag is responsible for the view model and the `<template>` tag is responsible for the view.
It is important to keep in mind the philosophy of the MVVM pattern, that says that the UI is a function of state, f(S) = UI.
The code should be declarative and clear to understand.

Also, many frontend frameworks benefit from tree shaking, which is also facilitated by the use of clear separation of concerns.

Typical layers for a frontend application are:

* Endpoint/REST - responsible for fetching and caching data from APIs.
* Queries/mutations - orchestration, caching, loading states, query invalidation.
* Stores/Contexts - responsible for managing complex UI state that spans across multiple components.
* UI Components - pure View-Model and View UI code.

### API Network Layer - responsible for fetching and caching data from APIs

This has to be thin and contain only logic necessary for data fetching.

Use `axios` or `fetch` for HTTP requests.

The common structure is something like this:

```typescript
// book.endpoints.ts or BookEndpoints.ts
import axios from 'axios';

interface CreateBookRequest {
  title: string;
  author: string;
}

const get = async (id: string) => { // Simple stateless function
  const response = await axios.get(`/api/books/${id}`);
  return response.data;
}

const post = async (data: CreateBookRequest) => { // Use DTOs for request objects
  const response = await axios.post('/api/books', data);
  return response.data;
}

export BookEndpoints = { // Export the endpoints as an object
  get,
  post,
};
```

Using the endpoints:

```typescript
import { BookEndpoints } from './BookEndpoints.ts';

const book = await BookEndpoints.get('123');
console.log(book.title);

const newBook = await BookEndpoints.post({ title: 'New Book', author: 'John Doe' });
console.log(newBook.id);
```

### API Resources Management

Previously people did different mental gymnastics to facilitate data fetching and abstracting away the API network layer.
A current modern alternative is Tanstack Query that has ports for different frameworks like React, Vue, Svelte, Angular, etc.

Tanstack gives a comfortable abstraction layer over the API Network Layer that adds caching, invalidation and state management.

Structure of a resource that is managed via Tanstack:

`queryKeys.ts` contains the keys for the queries available.

```typescript
// queryKeys.ts
export const queryKeys = {
  books: () => ['books'] as const,
  book: (id: string) => ['books', id] as const,
  bookComments: (id: string) => ['books', id, 'comments'] as const,
};
```

The query keys are used to identify the queries and are used to invalidate the cache when the data changes.

`queries.ts` - use to read data from a source

```typescript
// queries.ts
import { useQuery } from '@tanstack/vue-query';
import { type MaybeRefOrGetter, toValue, computed } from 'vue';
import { BookEndpoints } from './BookEndpoints';
import { queryKeys } from './queryKeys';

export const useBook = (bookId: MaybeRefOrGetter<string>) => {
  return useQuery({
    queryKey: computed(() => queryKeys.book(toValue(bookId))),
    queryFn: () => BookEndpoints.get(toValue(bookId)),
    enabled: computed(() => !!toValue(bookId))
  });
};

export const useBooks = () => {
  return useQuery({
    queryKey: queryKeys.books(),
    queryFn: () => BookEndpoints.getAll(),
  });
};

export const useBookComments = (bookId: MaybeRefOrGetter<string>) => {
  return useQuery({
    queryKey: computed(() => queryKeys.bookComments(toValue(bookId))),
    queryFn: () => BookEndpoints.getComments(toValue(bookId)),
    enabled: computed(() => !!toValue(bookId))
  });
};
```

Using that in a real scenario

```vue
<script setup lang="ts">
import { ref } from 'vue';
import { useBook } from './queries/useBook';

const bookId = ref('123');

const { 
  data: book, 
  isLoading, 
  isError, 
  error 
} = useBook(bookId);

const selectNextBook = () => {
  bookId.value = (parseInt(bookId.value) + 1).toString();
};

</script>

<template>
  <main>
    <div v-if="isLoading">Loading book data...</div>

    <div v-else-if="isError">
      Error: {{ error instanceof Error ? error.message : 'Unknown error' }}
    </div>

    <article v-else-if="book">
      <h1>{{ book.title }}</h1>
      <p>Author: {{ book.author }}</p>
      <button @click="selectNextBook">Load Next Book</button>
    </article>
  </main>
</template>
```

`mutations.ts` - use for CUD operations or performing server-side effects.

```typescript
import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { BookEndpoints } from './BookEndpoints';
import { queryKeys } from './queryKeys';

export const useCreateBook = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (newBook: CreateBookRequest) => BookEndpoints.post(newBook),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.books() });
    },
  });
};
```

Using in a component:

```vue
<script setup lang="ts">
import { reactive } from 'vue';
import { useCreateBook } from './mutations';

const form = reactive({
  title: '',
  author: ''
});

const { mutate, isPending, isError, error } = useCreateBook();

const handleSubmit = () => {
  mutate(form, {
    onSuccess: () => {
      form.title = '';
      form.author = '';
      alert('Book created successfully');
    }
  });
};
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <input v-model="form.title" placeholder="Title" :disabled="isPending" />
    <input v-model="form.author" placeholder="Author" :disabled="isPending" />

    <button type="submit" :disabled="isPending">
      {{ isPending ? 'Saving...' : 'Create Book' }}
    </button>

    <p v-if="isError" class="error">{{ error.message }}</p>
  </form>
</template>
```

**Differences between `queries.ts` and `mutations.ts`**

`queries.ts`:

* reads data from a source
* declarative, runs on mount or key change
* cached by key
* retires by default

`mutations.ts`:

* changes or writes data
* imperative, calls mutate()
* not cached, modified state
* not retired by default

**State management boundary:**
Do not mirror TanStack Query data into local `ref` or `$state` variables.
Access the data object directly from the hook to maintain a single source of truth.

**Use standardized error/loading states**
Every component using `useQuery` or `useMutation` must explicitly handle `isLoading/isPending` and `isError` states in the template.

**TypeScript Strictness**
All mutation payloads and query return types must be interfaced.
Use `zod` or similar for runtime validation if the API Network Layer is thin.

### Frontend Domain Layer

When developing backends, it is a good practice to use a layered architecture.
Typically it looks like this: repository -> service -> controller -> router -> handler
Where the repository is responsible for DB logic, the service for business logic and so on.

The REST layer would be responsible for handling HTTP requests and responses, mapping them to the domain layer.
Besides that, usually each layer has its own DTOs and interfaces that help separation and use mappers.

Frontend does not usually follow the same structure.

**Using classes in frontend code should be for handling state or complex logic**
Usually websites just present data fetched from the backend.
There is no point of writing a separate domain layer that is mapping the API network layer to the frontend domain layer,
unless the logic is complex and requires a lot of state management.

Classes in UI code should be used mainly for state management.
For methods that are utilitarian (e.g. `getDisplayName` or `getPrettifiedName`), they should be placed in a separate file or module.
Example:

```typescript
// Just write a simple function in a separate file or module

// lib/api/bookings/utils.ts
const getDisplayName = (booking: Booking) => {
  return `${booking.firstName} ${booking.lastName}`;
};

// Having a class for simple methods is expensive maintenance
class Booking{
  constructor(private firstName: string, private lastName: string){}

  public getFirstName() {
    return this.firstName;
  }

  public getLastName() {
    return this.lastName;
  }

  public getDisplayName() {
    return `${this.firstName} ${this.lastName}`;
  }
}
```

**Use classes for context management and state**
While simple utility functions are preferred for data transformation,
Classes are the optimal tool for managing complex,
shared state or encapsulating logic that requires internal private state.

In Svelte 5 and Vue 3, classes allow you to group related $state or ref properties with the methods that mutate them.
This is particularly powerful when passed through Context to avoid prop-drilling.

```typescript
//BookSelectionStore.ts
export class BookSelectionStore {
  // Encapsulated state
  #selectedIds = $state(new Set<string>());

  // Derived state
  get count() {
    return this.#selectedIds.size;
  }

  // Methods (Actions)
  toggle(id: string) {
    if (this.#selectedIds.has(id)) {
      this.#selectedIds.delete(id);
    } else {
      this.#selectedIds.add(id);
    }
  }

  isSelected(id: string) {
    return this.#selectedIds.has(id);
  }
}
```

Also it is highly recommended to wrap these in custom hooks to provide type safety and avoid magic strings

```typescript
const KEY = Symbol('BookStore');
export const useBookStore = () => getContext<BookSelectionStore>(KEY);
export const setBookStore = () => setContext(KEY, new BookSelectionStore());
```

* Use private `#field`s for state and expose only necessary getters and setters
* CRITICALLY forbidden to use `onMount` or `onDestroy` inside class logic
* These classes should be instantiated once and shared via `setContext/getContext` (Svelte) or `provide/inject` (Vue)

---

## References

* [Svelte reactivity examples](references/svelte-reactivity-examples.md) — runes decision matrix, `$state`, `$derived`, `$derived` reassignment behavior, `$effect`, `$effect.pre`, `$state.raw` vs `$state` performance guidance, anti-patterns
* [Svelte common mistakes](references/svelte-common-mistakes.md) — top 10 Svelte 5 anti-patterns with wrong/right examples: `$effect` for derived state, effects instead of event handlers, syncing linked values via effects, optional chaining breaking dependency tracking, infinite loops, DOM sync with `@attach`, runes inside functions, deep reactivity behavior, TypeScript prop typing mistakes
* [Vue reactivity examples](references/vue-reactivity-examples.md) — `ref`, `computed`, `watch`, `watchEffect`, anti-patterns
* [Tanstack Docs Index Page](references/tanstack-docs.md) - The index of tanstack query documentation with URL to see the latest docs
