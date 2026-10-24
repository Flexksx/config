# Event Sourcing

The event stream is the source of truth.
The state of an aggregate is the result of applying its events in stream order.

## Append-only writes

A command handler writes only by appending events.
It never updates a stored value that it can derive from the events, such as an end time, a status or a JSON copy of the state.
Store a derived value only in a projection or a cache that you can rebuild from the events.
A snapshot is such a cache.
It stores the state together with the stream version it reflects, and it is never the source of truth.

## Decider

Name the two functions `decide` and `evolve`, as in the Decider pattern.

```java
List<EnglishAuctionEvent> decide(EnglishAuctionState state, EnglishAuctionCommand command)
EnglishAuctionState evolve(EnglishAuctionState state, EnglishAuctionEvent event)
```

`decide` is a pure function: no I/O, no clock reads, no randomness.
Pass the time and every other external value in through the command.
`evolve` applies one event to the state and never throws.
Put the rules of the aggregate in `decide`.
The state type does not check invariants in its constructor, because `evolve` must never throw.

## Event and command names

Name events in the past tense with no suffix: `BidPlaced`, `AuctionClosed`.
Name the commands of an aggregate in the imperative with no suffix: `PlaceBid`, `CloseAuction`.
A use case of an event-sourced domain takes the aggregate command, such as `PlaceBid`, as its input.
Do not add a `PlaceBidCommand` type.
The sealed supertypes end in `Command` and `Event`: `EnglishAuctionCommand`, `EnglishAuctionEvent`.
An event carries the change, not a copy of the whole state.

## One Decider per aggregate type

Each aggregate type has its own state, commands, events, `decide` and `evolve`.
Do not move a rule that only one aggregate type uses into a shared base class.
Make the commands of one aggregate type a sealed type, and its events another.
Switch over a sealed type exhaustively, with no default branch, so the compiler reports a missing case.
A generic interface such as `Decider<State, Command, Event>` lets the compiler reject a command meant for another aggregate type.

## Event store

Append events with the expected stream version.
If the version conflicts, another writer appended first: reload the stream, call `decide` again and append again.
An event row has one field per stored column: stream id, version, event type, payload, recorded time.

## Projections and replay

Make each projection idempotent.
Send side effects, such as emails or payments, through a gateway that does nothing during replay.
Record the result of an external query as an event, so that a replay does not call the external system again.

## Pitfalls

### Mutable derived column

Signals:

- An `UPDATE` on the aggregate table in a command handler.
- A column such as `ends_at` or `status` that a command changes in place.

### Shared base aggregate class

Signals:

- A base class with methods such as `commandType()` or `eventType()` that subtypes override.
- Rules in the base class that apply to only one subtype.
- Default methods that throw "not applicable".

### State wrapper

Signals:

- A type whose only field is the state, such as `AuctionView(AuctionState state)`, and that adds no stream version.

### Impure `decide`

Signals:

- `decide` reads the clock, calls a repository or sends a message.
