# Functional Core, Imperative Interface

Keep domain decisions in a functional core and interactions with the outside world in an imperative interface, also called the shell.
This boundary works alongside other architectures, including domain-driven design and hexagonal architecture.

## Functional core

- Model domain concepts as immutable values and entities.
  A new version of an entity keeps its identity while carrying its new state.
- Make domain operations return new values instead of mutating existing objects or collections.
  Use immutable nested values too, because a frozen object can still contain mutable objects.
- Keep domain rules and invariants inside the domain model or pure domain functions.
  Reject invalid transitions explicitly.
- Make results depend only on explicit inputs.
  Pass in values such as the current time or generated identifiers instead of reading them inside domain logic.
- Keep repositories, network calls, logging, and other side effects out of the core.
  Domain operations may return data describing effects for the shell to carry out.

## Imperative interface

- Load external state and resolve environmental inputs before calling the core.
- Pass the resulting values to the core, then persist or publish its results.
- Keep orchestration thin and leave domain decisions in the core.
- Handle missing data, failed writes, and concurrency at the boundary.
  Do not report success when persistence fails.

## Examples

The shell loads an order, asks the domain model for an updated version, and saves that version.
The repository raises an error when an order is missing or a save fails.

```python
from dataclasses import dataclass, replace


# Bad: the operation changes the existing order in place.
@dataclass
class MutableOrder:
    item_ids: list[str]

    def add_item(self, item_id: str) -> None:
        self.item_ids.append(item_id)


# Better: the operation returns a new order with the same identity.
@dataclass(frozen=True, slots=True)
class Order:
    id: str
    item_ids: tuple[str, ...]

    def add_item(self, item_id: str) -> "Order":
        return replace(self, item_ids=self.item_ids + (item_id,))


def add_item_to_order(order_id: str, item_id: str) -> Order:
    order = repository.get(order_id)
    updated_order = order.add_item(item_id)
    return repository.save(updated_order)
```

In Java, a record prevents field reassignment but does not make a supplied list immutable.
Copy the list at construction and return a new record for each change.

```java
import java.util.List;
import java.util.stream.Stream;

// Bad: callers can mutate the record through its list.
record MutableOrder(String id, List<String> itemIds) {}

// Better: the order owns an immutable copy and returns a new version.
public record Order(String id, List<String> itemIds) {
    public Order {
        itemIds = List.copyOf(itemIds);
    }

    public Order addItem(String itemId) {
        List<String> updatedItems = Stream.concat(itemIds.stream(), Stream.of(itemId)).toList();
        return new Order(id, updatedItems);
    }
}

class OrderService {
    private final OrderRepository repository;

    OrderService(OrderRepository repository) {
        this.repository = repository;
    }

    Order addItemToOrder(String orderId, String itemId) {
        Order order = repository.get(orderId);
        Order updatedOrder = order.addItem(itemId);
        return repository.save(updatedOrder);
    }
}
```

Test domain rules directly with values and expected results, without a database or mocks.
Test the shell separately for orchestration and failures at its external boundaries.

## Failure modes

- **Shallow immutability:** A frozen object or record holds a mutable collection or mutable child.
  Use immutable children and defensive copies at boundaries.
- **Hidden inputs or effects:** A domain operation reads a clock, generates an identifier, accesses a repository, or writes a log.
  Pass values in and let the shell perform effects.
- **Rules in the shell:** The shell decides whether a domain transition is valid, leaving other callers able to bypass the rule.
  Put the rule in the domain operation.
- **Ignored result:** A caller discards the new object or saves the old version.
  Carry the returned version through the rest of the operation.
- **Lost updates:** Two callers load the same version and the later save overwrites the earlier change.
  Use an appropriate transaction or version check at the persistence boundary.
- **Incomplete effects:** A save succeeds but a required message fails, or a retry repeats an effect.
  Choose transaction, delivery, and retry behavior explicitly for the operation.
