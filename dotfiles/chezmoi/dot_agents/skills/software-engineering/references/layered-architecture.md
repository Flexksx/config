# Layered Architecture

Presentation calls service, and service calls repository.
Do not add ports between them.
A service also calls the domain models, and the domain layer calls no other layer.
Handle cross-cutting concerns, such as logging, tracing and auth, in a filter, an interceptor or an aspect.

## Layers

### Presentation

Controllers, CLI handlers and event listeners form this layer.
They translate input into service calls and service results into responses.

Signals:

- A controller contains business logic.

### Service

A service carries out the operations of the application by coordinating domain models.

If logic uses the state of one domain model only, put it on that model.
Put logic in a service only if it uses the state of several models, uses no model state, or needs external input.

Signals:

- A service builds an HTTP response or formats a view.
- A service is a catch-all for logic that had no other home.
- A service contains SQL, ORM annotations or other persistence code.

### Repository

This layer accesses databases, queues and external APIs.
Each aggregate root has one repository, which accepts and returns persistence types named `*Row`.

### Domain

The domain layer holds business logic and domain models.
It has no framework dependencies and does no I/O.

Signals:

- A domain model imports a repository or a framework class.
- A domain method signature contains an infrastructure type.

## Mappers

A mapper converts domain models to and from the types of one other layer.
Name it after the aggregate root and the types it maps to: `UserRowMapper` for `UserRow`, `UserRestMapper` for the REST request and response types.
The service calls the row mapper, and the controller calls the REST mapper.

Signals:

- A `*Row` type in a service signature, or a domain model in a repository signature.

## Pitfalls

### Framework annotations on domain models

A domain model carries `@Entity`, `@Column` or `@JsonProperty` annotations.
A schema or serialization change then changes the domain model.

Signals:

- Domain classes importing ORM or Jackson packages.
- `@Entity` or `@Table` annotations inside the `domain` package.
- Domain objects with `@JsonProperty` or `@JsonSerialize`.
- Domain methods accepting or returning `EntityManager` or `Session`.

### Anemic domain model

Business logic lives in services instead of on domain models.
The domain models hold only data, and the services grow long.

Signals:

- Domain models with only getters, setters and no behavior methods.
- Service methods longer than 50 lines that change domain model fields directly.
- Service methods named `calculateX` or `validateY` that take a domain model.

### Persistence types in service signatures

A service that accepts or returns a `*Row` type couples the service layer to the database schema.
A schema migration then changes service signatures.

Signals:

- Tests that require a running database just to call a service method.

### Business logic in controllers

A controller branches on domain state, validates beyond the input format, or accesses a repository.

Signals:

- Controllers importing repository classes.
- `if` statements checking domain status inside a controller method.
- Controllers longer than about 30 lines.

### Cross-cutting concerns copied into services

Logging, tracing or auth checks are copied into service methods instead of handled in a filter, an interceptor or an aspect.

Signals:

- Identical logging blocks at the start of multiple service methods.
- `SecurityContext` checks copied into unrelated methods.
- An auth fix requires changes in more than 10 places.
