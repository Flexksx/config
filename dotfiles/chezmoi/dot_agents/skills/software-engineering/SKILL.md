---
name: software-engineering
description: >
  Design judgment for code structure: detect the architecture (hexagonal, layered, event-sourced,
  MVVM, modular monorepo, microservices), set module boundaries, choose types, data shapes and
  names.
  Use before scaffolding or restructuring code in any language, when the repo records conventions
  in `AGENTS.md`, or when a module needs a public API from `index.ts` or `__init__.py`.
  Use it even for one new file, because names and boundaries are where models drift.
  Do not use for language syntax or tooling; use `python-dev`, `java-dev` or `svelte-dev`.
---

# Software Engineering

Rules for decisions that models get wrong when they scaffold code that must hold over time.
Generic best practice is always mandatory: YAGNI, SOLID and KISS.

## Abstractions

An abstraction can take many forms, including a function, type or module.
Review it with these checks:

- **Adding a sibling:** Count existing files that must change; callers should not need changes.
- **Implementation leaks:** Search callers for checks against implementation names or types.
- **Contract compliance:** Run the same contract tests against every implementation; check for skipped or unsupported operations.
- **Invalid combinations:** Check whether public inputs allow combinations that no implementation accepts.
- **Forwarding:** Check whether removing a pass-through operation changes behavior or a boundary.
- **Unused variation:** Count implementations and callers of extension points; question variation with no current need.

Treat findings as prompts for judgment, not automatic verdicts.

### Module boundaries

Treat modules, packages and classes as boundaries that expose abstractions.
Review their accessible names with these checks:

- **Implementation independence:** Can an internal implementation change without changing callers or the public contract?
- **Invariant protection:** Can callers bypass a rule by changing internal state or calling an internal operation?
- **Dependency direction:** Can callers use the boundary without importing internal types or files?
- **Contract exposure:** Does the public interface expose details that must change when an internal implementation changes?

When a module or package needs a public boundary, expose a deliberate API through its entry point.
In TypeScript, use explicit exports from `index.ts`.
In Python packages, expose the intended names through `__init__.py` and `__all__`.
Consumers should use that public API instead of reaching into implementation files.
Inside the boundary, import from defining files to avoid circular dependencies.

## Naming

- Things are named by their role in the design.
- Names should follow the structure idiomatic for the architecture, see the architecture section for guidance
- Avoid generics such as `Element`, `Type`, `Data`, `Manager`, `Helper`, `utils`
- Domain types are named after the word the domain uses, e.g. `Bid`, not `AcceptedBid`
- Avoid things like `OrderProcessor` in favor of `OrderProcessingService`.
- No abbrevations, `userIdentifier`, not `usrId`. `connectionPool`, not `cp`.
- No *magic values* - every meaningful literal must be a named constant.

**Avoid boolean parameters that switch behavior.**

In TypeScript, prefer separate operations over boolean parameters.
In Python, keyword-only boolean arguments can make a call clear when a separate operation or command object would add unnecessary structure.

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

## Decouple code from data

In the case of scripts that perform some business logic or apply configuration, it is critical to separate the code from the data.

Symptoms:

- A case name, tier or country appears inside the code, not only in the data.
- The same literal, date or threshold appears in more than one function.
- An `if`/`elif` chain whose branches differ only in their values.
- Adding a case edits a function instead of adding a row.
- A parameter exists only to pick a group of preset values.
- The rule cannot be tested without setting up the real case.

```python
# Bad - the thresholds are the rule, and they are written twice
# A new tier edits both functions, and the message can drift from the routing
def required_approver(amount_cents: int) -> Role:
    if amount_cents < 100_000:
        return Role.TEAM_LEAD
    if amount_cents < 1_000_000:
        return Role.FINANCE_MANAGER
    if amount_cents < 10_000_000:
        return Role.CONTROLLER
    return Role.CFO

def approval_message(amount_cents: int) -> str:
    if amount_cents < 100_000:
        return "Team lead approval"
    if amount_cents < 1_000_000:
        return "Finance review"
    if amount_cents < 10_000_000:
        return "Controller signature"
    return "CFO signature"


# Better - the tiers are data, and the code only selects one
# A new tier adds a row, so routing and message cannot disagree
@dataclass(frozen=True)
class ApprovalTier:
    max_amount_cents: int | None
    approver: Role
    message: str

APPROVAL_TIERS = (
    ApprovalTier(max_amount_cents=100_000, approver=Role.TEAM_LEAD, message="Team lead approval"),
    ApprovalTier(max_amount_cents=1_000_000, approver=Role.FINANCE_MANAGER, message="Finance review"),
    ApprovalTier(max_amount_cents=10_000_000, approver=Role.CONTROLLER, message="Controller signature"),
    ApprovalTier(max_amount_cents=None, approver=Role.CFO, message="CFO signature"),
)

def tier_for(amount_cents: int) -> ApprovalTier:
    return next(
        tier
        for tier in APPROVAL_TIERS
        if tier.max_amount_cents is None or amount_cents < tier.max_amount_cents
    )

def approval_message(amount_cents: int) -> str:
    return tier_for(amount_cents).message
```

The example above is a common use case, whereas some use cases may not be that obvious.

```python
# Bad - the rate history lives in the code, and every reader repeats the dates
def vat_cents(order: Order) -> int:
    if order.placed_on < date(2024, 1, 1):
        return order.net_cents * 19 // 100
    return order.net_cents * 21 // 100

def invoice_note(order: Order) -> str:
    if order.placed_on < date(2024, 1, 1):
        return "VAT 19%"
    return "VAT 21%"


# Better - the rate history is data, newest first, and the code reads it once
@dataclass(frozen=True)
class VatPeriod:
    valid_from: date
    rate_percent: int

VAT_PERIODS = (
    VatPeriod(valid_from=date(2024, 1, 1), rate_percent=21),
    VatPeriod(valid_from=date(2023, 1, 1), rate_percent=19),
)

def vat_period(placed_on: date) -> VatPeriod:
    for period in VAT_PERIODS:
        if period.valid_from <= placed_on:
            return period
    raise UnknownPeriod(placed_on)

def vat_cents(order: Order) -> int:
    return order.net_cents * vat_period(order.placed_on).rate_percent // 100

def invoice_note(order: Order) -> str:
    return f"VAT {vat_period(order.placed_on).rate_percent}%"
```

## Software design

Software design organizes the code that implements system behavior to improve maintainability and speed to market.
Follow these guidelines within the system architecture.

### Design patterns

The personal default is a functional core with an imperative interface, including when using domain-driven design.
Keep domain logic as pure and immutable as practical, and read `references/functional-core-imperative-interface.md` when designing domain logic or its boundary.
Apply this preference within the existing architecture.

Identify the patterns used in the code and follow them idiomatically.
Read the reference for each pattern whose signals match.

- **Domain-driven design:** domain models, bounded contexts or aggregates.
  Reference: `references/domain-driven-design.md`.
- **Hexagonal:** `*UseCase` or `*Port` types, `port` or `adapter` folders, `ports.py` or `*.ports.ts` files.
  Reference: `references/hexagonal-architecture.md`.
- **MVVM:** views bound to view models or UI state classes.
  Reference: `references/mvvm-architecture.md`.
- **Layered (n-tier):** controllers call services, and services call repositories.
  Reference: `references/layered-architecture.md`.
- **Modular monorepo:** several apps and libraries in one repo.
  Reference: `references/monolith-architecture.md`.

## Architecture

Architecture defines the system’s major parts and their interactions to meet system-wide requirements such as availability, scalability and security.
These decisions also constrain how the system implements its behavior.
Some patterns affect both architecture and software design.

### Architecture style

Identify the architecture from the code and follow it idiomatically.
Before you design anything, read the reference of every architecture whose signals match.

- **Event-sourced:** an event store, `decide` and `evolve` functions.
  Reference: `references/event-sourcing.md`.
- **Microservices:** separately deployed services that call each other over a network.
  Reference: `references/microservices-architecture.md`.

If no architecture or design pattern matches, present two options with their trade-offs, recommend one, and wait for the user to choose, even after "just build it".
Propose one line for the repo's `AGENTS.md` that records the choice, and let the user write it.
