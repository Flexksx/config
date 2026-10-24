---
name: software-engineering
description: >
  Design judgment for code structure: architecture, boundaries, sharing,
  types, data and naming.
  Always load before writing, designing, restructuring or reviewing code
  in any language, together with the language skill for the stack.
---

# Software Engineering

Rules for decisions that models get wrong when they scaffold code that must hold over time.
Generic best practice is always mandatory: YAGNI, SOLID and KISS.

When rules conflict, the higher one wins:

1. Decisions recorded in the repo's `AGENTS.md`.
2. The repo's existing conventions.
3. This skill.
4. General best practice.

## Architecture style

Identify the architecture from the code and follow it idiomatically.
Before you design anything, read the reference of every architecture whose signals match.

- **Hexagonal:** `*UseCase` or `*Port` types, `port` or `adapter` folders, `ports.py` or `*.ports.ts` files.
  Reference: `references/hexagonal-architecture.md`.
- **Event-sourced:** an event store, `decide` and `evolve` functions.
  Reference: `references/event-sourcing.md`.
- **Layered (n-tier):** controllers call services, and services call repositories.
  Reference: `references/layered-architecture.md`.
- **Modular monorepo:** several apps and libraries in one repo.
  Reference: `references/monolith-architecture.md`.
- **Microservices:** separately deployed services that call each other over a network.
  Reference: `references/microservices-architecture.md`.
- **MVVM:** views bound to view models or UI state classes.
  Reference: `references/mvvm-architecture.md`.

If no architecture matches, present two options with their trade-offs, recommend one, and wait for the user to choose, even after "just build it".
Propose one line for the repo's `AGENTS.md` that records the choice, and let the user write it.

## Naming

- Things are named by their role in the design.
- Names should follow the structure idiomatic for the architecture, see the architecture section for guidance
- Avoid generics such as `Element`, `Type`, `Data`, `Manager`, `Helper`, `utils`
- Domain types are named after the word the domain uses, e.g. `Bid`, not `AcceptedBid`
- Avoid things like `OrderProcessor` in favor of `OrderProcessingService`.
- No abbrevations, `userIdentifier`, not `usrId`. `connectionPool`, not `cp`.
- No *magic values* - every meaningful literal must be a named constant.

**No boolean parameters.**

They hide branching.

```java
// Bad - the call site does not say what true does
orders.process(order, true);

// Better - each call states what it does
orders.process(order);
notifications.sendOrderConfirmation(order);
```

**Functions do only one thing.**

If you need "and" to describe it, split it.

```python
# Bad - two jobs, so the name needs "and"
def process_order_and_send_email(order: Order) -> None:
    ...

# Better - one job each, and the caller composes them
def process_order(command: ProcessOrderCommand) -> None:
    ...

def send_order_confirmation(order: Order) -> None:
    ...

# The command carries the input as data, with no flag that switches behavior
@dataclass(frozen=True)
class ProcessOrderCommand:
    order_id: OrderId
    items: list[OrderItem]

# In Python, keyword-only arguments can replace the command
def process_order(*, order_id: OrderId, items: list[OrderItem]) -> None:
    ...
```

**No comments in code.**

If code needs explanation, rename or restructure until it doesn't.

Exceptions: module-level docstrings and pragma annotations.

**Fail explicitly.**

Throw domain exceptions.

Never return `null` to signal failure.

Never swallow errors silently.

## Inheritance

Overall best practice to avoid inheritance unless there is clearly a is-a relationship.
Favor composition over inheritance all time.
