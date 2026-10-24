# MVVM Architecture

View binds declaratively to ViewModel state.
ViewModel drives the Model.
View is passive; ViewModel is testable without a rendering framework.

## Pitfalls

### Logic Leaking into the View

Conditional rendering on raw model data or inline string formatting couples
the View to domain knowledge it should not hold.

**Signals:**

- `if`/`switch` on domain state inside a template or layout file.
- Date formatting or currency conversion in template expressions.
- Business rules duplicated across multiple View components.

### Fat ViewModel

Business rules, data fetching, and transformation accumulate in the
ViewModel because the Model layer is thin or absent.

**Signals:**

- ViewModel exceeding 500 lines.
- Direct API or database calls inside the ViewModel.
- ViewModel methods named after domain operations: `calculateTotal`.

### ViewModel Holding View References

A ViewModel holding a direct reference to a View or Activity creates
a memory leak and breaks testability.

**Signals:**

- ViewModel constructor or method accepts a View, Activity, or Fragment.
- `context.findViewById` called inside a ViewModel.
- Memory leak warnings in Android Studio pointing to a ViewModel.

### Silent Binding Failures

A typo in a binding expression or a type mismatch produces a blank field
rather than a crash, making defects easy to ship undetected.

**Signals:**

- A UI field renders nothing without any logged error.
- Renaming a ViewModel property causes silent UI breakage.
- No compile-time check on binding expressions in the framework in use.

### Mutable State Modified from Multiple Sites

Observable state updated from multiple places produces race conditions
that are hard to reproduce.

**Signals:**

- A `MutableStateFlow` or `MutableLiveData` with more than one writer.
- UI inconsistency that only reproduces under concurrent load.
- Multiple coroutines or threads writing to the same state variable.
