# Builder Pattern

## Java

Static inner `Builder` class.
Outer class has a private constructor; all fields are `final`.
Required fields are constructor arguments on `Builder`;
optional fields have defaults.

```java
public final class DatabaseConfig {
    private final String host;
    private final int port;
    private final String database;

    private DatabaseConfig(Builder builder) {
        this.host = builder.host;
        this.port = builder.port;
        this.database = builder.database;
    }

    public static final class Builder {
        private final String host;
        private final String database;
        private int port = 5432;

        public Builder(String host, String database) {
            this.host = Objects.requireNonNull(host);
            this.database = Objects.requireNonNull(database);
        }

        public Builder port(int port) { this.port = port; return this; }

        public DatabaseConfig build() {
            return new DatabaseConfig(this);
        }
    }
}
```

Use Lombok `@Builder` for plain data objects.
Write manually when `build()` needs validation logic.

## Python

For step-by-step construction, use a `@dataclass` with private state
and fluent methods:

```python
@dataclass
class QueryBuilder:
    table: str
    _conditions: list[str] = field(default_factory=list, init=False)
    _limit: int | None = field(default=None, init=False)

    def where(self, condition: str) -> "QueryBuilder":
        self._conditions.append(condition)
        return self

    def limit(self, n: int) -> "QueryBuilder":
        self._limit = n
        return self

    def build(self) -> Query:
        if not self._conditions:
            raise ValueError("at least one condition required")
        return Query(self.table, list(self._conditions), self._limit)
```

For configuration objects, `@dataclass(frozen=True)` is sufficient.
Do not add a `Builder` wrapper on top of a dataclass.

## Pitfalls

### Required Fields as Optional Setters

`build()` silently produces an invalid object when required fields are unset.
Put required fields in the `Builder` constructor, not as setters.

**Signals:**

- `NullPointerException` at runtime that could have been a build-time error.
- Calling `build()` on a freshly constructed Builder produces a broken object.
- Required fields with no `Objects.requireNonNull` or equivalent guard.

### Setters Returning `void`/`None`

Breaks method chaining; every setter must return `this`/`self`.

**Signals:**

- Builder calls written on separate lines because chaining fails to compile.
- IDE autocomplete shows `void` return type on a setter.

### No Defensive Copy of Mutable Collections

The caller retains a reference to the collection and can mutate the built
object's state after construction.

**Signals:**

- Modifying the list passed to the Builder changes the built object's data.
- Built objects sharing mutable collection state with their construction site.
- No `new ArrayList<>(input)` or equivalent copy before field assignment.

### No Validation in `build()`

Cross-field invariants scattered across setters are never fully enforced.
All validation belongs in `build()`, where the complete state is visible.

**Signals:**

- Fields that must be set together can be set independently with no error.
- Invalid objects only fail at use time, not at construction time.
- `build()` body contains nothing but `return new Obj(this)`.

### Builder for a Small Object

Two or three required fields need a constructor, not a builder.

**Signals:**

- A `Builder` class with fewer than 4 fields, all required.
- `build()` contains no validation logic and no optional fields.

### Python: Builder Wrapper over a Dataclass

`@dataclass` with keyword arguments is already a builder.
A `Builder` class on top is pure boilerplate.

**Signals:**

- A `Builder` class that only wraps a `@dataclass`.
- `Builder.build()` that only calls `Dataclass(field1=..., field2=...)`.
