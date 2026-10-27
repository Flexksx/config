# Microservices Architecture

Small, independently deployable services.
Each owns one business capability and communicates over a network.

## Pitfalls

### Distributed Monolith

Services split at deployment level but tightly coupled at data or call level.
All the operational cost of microservices, none of the independence.

**Signals:**

- Releasing service A always requires coordinating with service B.
- Service A imports service B's internal classes instead of service B's `*-client` library.
- A single feature requires changes in 3+ services simultaneously.

### Integration Database

Two services reading and writing the same database tables.
Schema changes in one service break the other; data ownership is fiction.

**Signals:**

- A migration in one service requires testing another service.
- Two services sharing the same database connection string.
- Foreign keys referencing tables owned by a different service.

### Synchronous Call Chains Deeper Than Two Hops

Each hop adds latency and a failure point.
A timeout anywhere stalls the entire upstream request.

**Signals:**

- A controller response depends on 3+ sequential service calls.
- P99 latency tracks the sum of all downstream service latencies.
- A failure in service D causes a 504 in service A.

### Chatty Interface

Dozens of fine-grained calls per request across a service boundary.
Signals a wrong boundary or bad API design.

**Signals:**

- A single user-facing action triggers 10+ inter-service calls.
- Network traces show the same service called in a tight loop.
- Latency improves dramatically when two services are co-located.

### Shared Mutable Library

A frequently updated internal library that multiple services depend on.
Any consumer is blocked from releasing independently until it upgrades.

**Signals:**

- A library version bump requires coordinated deploys across services.
- Services pinned to different versions of the same internal library.
- A breaking change in the library blocks unrelated service releases.

### No Idempotency on Message Consumers

At-least-once delivery guarantees duplicates; consumers must handle them.
A non-idempotent consumer corrupts state on retry.

**Signals:**

- Consuming the same event twice creates duplicate records.
- No deduplication key or idempotency check in event handlers.
- Unique constraint violations appearing in event consumer logs.

### Missing Observability

Distributed tracing, structured logs, and per-service metrics are
prerequisite, not optional.

**Signals:**

- No correlation ID propagated across service calls.
- Logs from different services cannot be joined by request.
- A user-reported bug cannot be traced to a specific service failure.

### Cross-Service Foreign Keys

Referential integrity across service databases cannot be enforced at the
DB level; attempting it couples schemas directly.

**Signals:**

- Service B's schema has a column referencing service A's primary key.
- Cascade deletes attempted across service boundaries.
- An integration test truncates tables across multiple service schemas.
