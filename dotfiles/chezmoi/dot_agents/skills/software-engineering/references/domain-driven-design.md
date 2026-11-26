# Domain-Driven Design

Prefer pairing DDD with a functional core and imperative interface to keep domain rules separate from side effects.
Follow `functional-core-imperative-interface.md`.

## Procedure

1. Find the terms and business rules in the existing code and domain documentation.
   Ask a domain expert when a term or rule is unclear.
2. Identify values, entities, and the business constraints that must hold when they change.
3. Group entities into aggregates where a business constraint requires them to change together.
4. Implement each aggregate operation in one transaction and test its constraints.

## Ubiquitous language

Use the same domain terms in conversations, code, and tests.
Use the existing term for a concept instead of inventing a synonym.
Clarify a term that has different meanings before using it in the model.

## Value objects

Use a value object for a domain concept identified by its value rather than an ID, such as money or a date range.
Keep it immutable and validate its rules when it is created.
Keep domain value objects independent of storage and transport formats.

## Entities

Use an entity for a domain object that needs a stable ID across changes and can be stored and retrieved by that ID.
Keep its identity distinct from its attributes.

## Aggregates

Use an aggregate to group entities whose business constraints must be enforced together.
The aggregate root controls changes to the entities it encompasses and enforces those constraints.
Perform each operation on an aggregate in a single transaction, so its changes either all succeed or all fail.
Keep the aggregate limited to the entities needed to enforce its constraints.
