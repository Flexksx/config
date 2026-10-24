# Modular Monolith and Monorepo

Several apps and libraries live in one repository and build together.
A modular monolith deploys as one process.
A monorepo can deploy several apps.

## Apps and libraries

An app holds its wiring, its startup and the domains that only it uses.
If several apps share framework wiring, such as Spring configuration, put it in a starter library.
Before you create a library for two classes, look for an existing library that owns their concept.
If one exists, depend on it.

## Pitfalls

### Module Entanglement

Without enforced boundaries, modules reach into each other's internals.
A change anywhere can break anything.

**Signals:**

- Module A imports classes from module B's internal packages.
- A single change causes test failures in multiple unrelated modules.
- No package-private visibility; everything is public.
- Circular dependencies between packages.

### Premature Extraction

Splitting into services before domain boundaries are stable produces
wrong service boundaries that are expensive to renegotiate.

**Signals:**

- An extracted service changes every time the monolith changes.
- The extracted service has no independent release history.
- Removing the service would require rewriting the monolith caller.

### Anemic Domain Model

Business logic accumulates in service classes instead of domain entities.
Entities become data bags; services become procedural scripts.

**Signals:**

- Entity classes with only getters and setters, no domain methods.
- Service methods named after domain concepts: `calculateDiscount`.
- Domain invariants enforced by callers, not by the entity itself.

### God Service

One service class accumulates responsibilities because it is the most
convenient place to add new logic.

**Signals:**

- A service with more than ~5 public methods, growing every sprint.
- The service is a dependency of nearly every other class in the module.
- PRs almost always touch the same service file.

### No Enforced Module Boundaries

A monolith with no internal structure cannot be safely extracted later.

**Signals:**

- No `ApplicationModules.verify()` or equivalent boundary check.
- No package-private visibility; every class is public.
- Circular dependencies between packages detected by static analysis.
