---
name: java-dev
description: >
  Mandatory standards and patterns to adhere to when developing Java,
  Spring MVC and Spring Boot applications.
---

# Java Development

Load `software-engineering` alongside this skill
to get universal software engineering standards.

## Using Records

Use `record` for immutable data: DTOs, API responses, projections.

The canonical constructor holds the record's invariants and creation conditions.
Validate them in a compact constructor and call the constructor directly.

Add a builder only when the record has optional fields.
A builder added for API uniformity, or to avoid positional arguments, is not idiomatic.

```java
// example: the compact constructor enforces the invariants
public record Money(BigDecimal amount, Currency currency) {
    public Money {
        if (amount.signum() < 0) {
            throw new NegativeAmountException(amount);
        }
    }
}

Money price = new Money(amount, EUR);

// counter-example: a builder with no optional field to justify it
Money price = Money.builder().amount(amount).currency(EUR).build();
```

Records are particularly useful for DOP - Data Oriented Programming.

## Using the type system

**var** — Avoid.
It hides types at declaration sites and degrades readability in reviews and refactors.

**final** — Mark class fields `final` when not reassigned after construction.

**Optional** — Use for nullable return values.
Never return `null`.
Never use `Optional` as a field type or method parameter — it is a return-value API only.
Never call `.get()` unguarded.
Use `.orElseThrow()` or `.map().orElse()`.

**Constants** — Use `private static final` for every meaningful string or number literal.
Name them base-first: `COLUMN_NAME_ID`, not `ID_COLUMN_NAME`.

## Stream API

Use streams for collection processing.

Avoid imperative loops unless the logic involves
complex mutation or multiple accumulators.

Break into named intermediate variables if there are
multiple chained operations for readability.

As a general practice, tend towards functional-style,
stateless operations since those are easier to reason about
and less prone to bugs.

## Abstractions

**Naming** — Class naming goes specialization-first, base-last:
`S3FileStorage extends FileStorage`.

Do not create an interface for a single implementation.
The exception is a port at a layer boundary: an interface the application layer defines
and infrastructure implements, such as `UserRepository`.
`*Impl` suffix signals a redundant interface.
Name implementations by how they do the job:
`EmailNotificationService implements NotificationService`.

**Substitutability (LSP)** — A subclass that throws `UnsupportedOperationException`
or overrides a method with an empty body breaks substitutability.
If a subtype cannot honor the supertype contract, the hierarchy is wrong.

**Exceptions** — Catch specific exceptions —
never `Exception`, `Throwable`, or `RuntimeException`.

Always pass the cause when wrapping:
`throw new MyException("msg", e)`.
Omitting `e` silently discards the original stack trace.

## Dependency Injection

ALways use constructor injection.

**Injection on fields**
Never inject via `@Autowired` on fields, because:

- prevents using `final`,
- hides the dependency graph,
- requires a Spring context to test.
- makes it harder for mocking

## Anti-patterns (DIP)

- Static utility or singleton calls from domain logic — `Clock.now()`,
  `Logger.getInstance()`. Inject a `Clock` or logger instead.
- Constructor parameter typed as a concrete class instead of an interface.

## REST API DTOs

Use `record` with `@JsonProperty` for request and response objects.
Name requests: `Action + Resource + Request` —
`CreateUserRequest`, `UpdateUserSubscriptionRequest`.

REST DTOs live in the `rest` subpackage of their aggregate.
Request is a REST term only.
The application layer names its use-case input a command: `CreateUserCommand`.

```java
package com.example.user.rest;

public record CreateUserRequest(
    @JsonProperty("name") String name,
    @JsonProperty("email") String email) {}
```

## Mappers

One mapper per layer and aggregate root.

It owns conversion for all composed types in that layer —
no sub-mappers per nested type.

Use it to map both Response and Request REST DTOs.

It shall be used to map objects between layers, e.g. the REST layer
or the persistence layer.

**Example:**
Domain has `User`, `UserPreferences` and `UserSettings`.

REST Layer has `UserResponse`, `UserPreferencesResponse` and `UserSettingsResponse`.

Do not create a separate `UserRestMapper`,
`UserPreferencesRestMapper` and `UserSettingsRestMapper` class.

Use a single `UserRestMapper` class with methods for each response type.

## Method naming

Methods are named by the return type for clarity.

Do not name methods by layer, e.g. `toRestResponse()`, `toDomain()`.

Use clear names -> `toUserResponse()`,
`toUserPreferencesResponse()`, `toUserSettingsResponse()`.

```java
package com.example.user.rest;

class UserRestMapper {
    public UserResponse toUserResponse(User user) { ... }
    // Composed type — still this mapper's responsibility, not a separate mapper
    public UserPreferencesResponse toUserPreferencesResponse(UserPreferences prefs) { ... }

    public UserSettingsResponse toUserSettingsResponse(UserSettings settings) { ... }

    public CreateUserCommand toCreateUserCommand(CreateUserRequest request) { ... }
}
```

```java
class UserEntityMapper {
    public UserEntity toUserEntity(User user) { ... }
    public User toUser(UserEntity entity) { ... }
}
```

## Builder Pattern in Java

Use a builder when an object has optional fields.
An object with only required fields uses its constructor.

### Pitfalls and best practices when using Builder

#### 1. Optional arguments

Builder methods take plain values, never `Optional`.
A caller leaves an optional field absent by not calling its method.

#### 2. No need for separate builder class

Place the builder class in the same package as the domain class.

Create it as a static inner class of the domain class.

#### 3. Builder inheritance hierarchy

For builder inheritance use CRTP: base builder declares
`protected abstract T self()`, each subclass overrides it to return `this`.

Without CRTP, base builder methods return the base `Builder` type
the fluent chain breaks at the first inherited setter call,
forcing callers to cast.

```java
public abstract class BaseEvent {
    private final String eventId;

    protected BaseEvent(Builder<?> builder) {
        this.eventId = builder.eventId;
    }

    public abstract static class Builder<T extends Builder<T>> {
        private String eventId;

        public T eventId(String eventId) {
            this.eventId = eventId;
            return self();
        }

        protected abstract T self();

        public abstract BaseEvent build();
    }
}

public final class UserEvent extends BaseEvent {
    private final String userId;

    private UserEvent(Builder builder) {
        super(builder);
        this.userId = builder.userId;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static final class Builder extends BaseEvent.Builder<Builder> {
        private String userId;

        public Builder userId(String userId) {
            this.userId = userId;
            return self();
        }

        @Override
        protected Builder self() {
            return this;
        }

        @Override
        public UserEvent build() {
            return new UserEvent(this);
        }
    }
}

// usage: eventId() returns UserEvent.Builder, so userId() chains without a cast
UserEvent event = UserEvent.builder().eventId("e-1").userId("u-1").build();
```

#### 4. Introducing business logic in Builders

In some codebases, business logic is introduced in the builder methods,
usually with `execute` or `run` methods.

This is a major anti-pattern, since it breaks SRP and the OCP.

In such cases, it makes sense to extract the business logic into a separate
service or component and the builder should be
responsible for constructing command DTOs only.

## References

[Spring Boot Organization Patterns][sbms] — module, module-client,
module-client-starter pattern for decoupled Spring Boot microservices.

[sbms]: references/spring-boot-microservices-patterns.md
