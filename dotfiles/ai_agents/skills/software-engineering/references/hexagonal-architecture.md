# Hexagonal Architecture

The domain model and the use cases form the core of each domain.
The core and the adapters interact only through ports.
An inbound port is a use case, and inbound adapters call it.
An outbound port is an interface that a use case calls, and an outbound adapter implements it.

## Folder layout

```text
# Java
auction/
  domain/                   Auction, Bid, rules
  application/
    port/in/                PlaceBidUseCase
    port/out/               LoadAuctionPort, AppendAuctionEventsPort
    PlaceBidService.java    implements PlaceBidUseCase
  adapter/
    in/rest/                AuctionController, PlaceBidRequest, AuctionRestMapper
    out/persistence/        JdbcAuctionAdapter, AuctionRow, AuctionRowMapper

# TypeScript
src/
  skill/
    model.ts
    in.ports.ts             use case interfaces
    out.ports.ts            outbound ports
    use-cases.ts            implements the use case interfaces
    adapters/
      fs-skill-store.ts     outbound adapter
    index.ts                public entry: model types and use case interfaces
  app/
    cli/  mcp/              inbound adapters that call several domains

# Python
ingestion/
  __init__.py               __all__ lists the use cases and the public types
  model.py                  plain dataclasses
  service.py                use cases as public functions that take their outbound ports
  ports.py                  outbound ports as Protocol types
  orm.py                    imperative mapping of the dataclasses to tables
  postgres.py               outbound adapter
```

## Inbound ports

In Java and TypeScript, each use case is one interface: `PlaceBidUseCase`, `GetListingUseCase`.
One service class can implement several use case interfaces.
Put logic that several use cases share in an injected component, not in a base class.
In Python, each use case is a public function of the domain package.
Inbound adapters, such as REST, CLI and MCP handlers, depend on the use case, never on the service class.

## Outbound ports

The domain whose use cases call an outbound port declares it.
No other domain imports it.

If a use case must load, save or send data during its work, add an outbound port for that need.
If the inbound adapter can resolve a value from its own input or environment, such as a file path or the platform, pass the value in.
Do not add a port for it.

Name an outbound port with a verb, an object and `Port`, after what the use case needs: `LoadToolsPort`, not a `FileStore` with `fileExists` and `writeText`.
Give two different needs two ports, even when both concern one aggregate: loading an auction and appending its events are two ports.

## Adapters and mappers

Adapters depend on ports.
The core never imports an adapter.
The `app` folder imports an adapter directly from its module to wire it, never through the domain's entry point.

In Java, a persistence type is named `*Row` and has one field per stored column.
A mapper lives in the adapter package that uses it.
Name it after the aggregate root and the types it maps to: `AuctionRowMapper` for `AuctionRow`, `AuctionRestMapper` for the REST request and response types.
Name each mapper method after its return type.

In Python, domain types are plain dataclasses.
`orm.py` maps them to tables with SQLAlchemy imperative mapping, so there are no `*Row` types and no mapper modules.
An outbound port is a `Protocol` type or a callable passed as a parameter.
Write adapters as modules or functions, not as class hierarchies.

## Transaction boundaries

The use case is the transaction boundary.
If a write spans two domains, call the other domain's inbound port in the same transaction, or publish a domain event that the other domain handles.
State the option you chose and the reason in the plan or the pull request description.

## Pitfalls

### Fat port

One port collects every operation a domain has.

Signals:

- A port interface with more than four methods.
- Use cases that call only one method of the port they depend on.

### Infrastructure-shaped port

The port methods mirror disk or network calls instead of what the use case needs.

Signals:

- Port methods such as `fileExists`, `writeText` or `executeQuery`.
- A use case that runs several port calls in sequence to do one thing.

### Shared outbound port

One domain imports another domain's outbound port.

Signals:

- An import from another domain's `port/out`, `out.ports.ts` or `ports.py`.
- Ports placed in a shared module that every domain depends on.

### Port for a passed-in value

A port fetches a value that the inbound adapter could resolve from its own input or environment.

Signals:

- A port that returns a path, the platform or an environment value.

### Adapter-to-adapter call

An adapter calls another adapter and bypasses the use case.

Signals:

- An inbound adapter imports an outbound adapter.
- A REST controller calls a repository class.

### Inbound adapter bound to a service class

The inbound adapter depends on the service class instead of the use case.

Signals:

- A controller or MCP handler has a constructor parameter typed as a service class.
- No use case interface between the adapter and the logic, in Java or TypeScript.
