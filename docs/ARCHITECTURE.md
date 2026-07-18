# Anvil Architecture

**Status:** Draft
**Version:** 0.1

## 1. Architecture Goal

Anvil provides a small Roblox-native runtime core that enforces explicit contracts at trust and lifecycle boundaries. Domain logic stays in the user's services. Anvil owns plumbing, not game design.

## 2. Layers

```text
User domain services
        |
Anvil Action / State / Transaction APIs
        |
Anvil Core: Result / Schema / Scope / Lifecycle
        |
Transport and persistence adapters
        |
Roblox engine
```

## 3. Package Layout

```text
src/
  Anvil.luau
  Core/
    Result.luau
    Error.luau
    Scope.luau
    Lifecycle.luau
  Schema/
    Schema.luau
    Validators.luau
    RobloxTypes.luau
  Action/
    Action.luau
    Router.luau
    Cooldown.luau
    RateLimit.luau
  Transport/
    Transport.luau
    RobloxRemote.luau
  Test/
    TestClock.luau
    TestTransport.luau
    TestPlayer.luau
    TestRng.luau
```

Optional adapters must not load from `Anvil.luau` unless explicitly requested.

## 4. Trust Boundaries

### Client to server

```text
client payload
  -> transport decode
  -> schema validation
  -> normalization
  -> rate limit
  -> cooldown
  -> authorization
  -> domain handler
```

No domain handler receives raw network payload.

### Server to client

Only serializable, explicitly declared Result values may cross the transport. Server-only objects, functions, connections, and arbitrary Instances are rejected unless the schema explicitly allows a safe representation.

## 5. Result Contract

```lua
--!strict

export type Error = {
    code: string,
    message: string?,
    path: string?,
    details: {[string]: unknown}?,
}

export type Result<T> =
    { ok: true, value: T }
    | { ok: false, error: Error }
```

Expected domain failure returns `Err`. Programmer faults throw and remain visible.

Required methods:

```lua
Result.ok(value)
Result.err(code, details?)
Result.map(result, transform)
Result.mapErr(result, transform)
Result.andThen(result, transform)
Result.unwrapOr(result, fallback)
```

Methods must avoid Promise allocation.

## 6. Scope Contract

```lua
local scope = Scope.new("Player", player)

scope:connect(connection)
scope:own(thread)
scope:own(instance)
scope:defer(cleanup)
local child = scope:child("Character", character)
scope:destroy()
```

Invariants:

- destruction is idempotent;
- children are destroyed before parent completion;
- owned connections are disconnected;
- owned cancellable threads are cancelled;
- owned Instances are destroyed only when explicitly registered;
- new resources cannot be registered after destruction;
- development mode may report use-after-destroy.

`Scope` does not claim automatic ownership of arbitrary values.

## 7. Schema Contract

```lua
local BuyInput = Schema.object({
    ItemId = Schema.string():minLength(1):maxLength(64),
    Quantity = Schema.integer():between(1, 99),
})

local value, err = BuyInput:parse(raw)
```

Schema responsibilities:

- runtime validation;
- normalization;
- path-aware errors;
- static exported types where Luau supports them;
- explicit Roblox datatype policies.

Schema does not infer security policy from a field name.

## 8. Action Contract

```lua
local action = Action.new("Shop.Buy", {
    input = BuyInput,
    cooldown = 0.25,
    rateLimit = {
        capacity = 10,
        refillPerSecond = 1,
    },
    authorize = authorize,
    execute = execute,
})
```

`execute(context)` receives:

```lua
{
    player = Player,
    input = ValidatedInput,
    requestId = string,
    scope = Scope,
    services = Services,
}
```

The action runner owns ordering. Domain handlers own domain decisions and mutations.

## 9. Transport Interface

```lua
export type Transport = {
    bind: (self: Transport, name: string, handler: (...any) -> ()) -> Scope,
    send: (self: Transport, player: Player, name: string, payload: unknown) -> (),
}
```

The core transport must use Roblox RemoteEvent/RemoteFunction primitives. ByteNet, Remo, and other transports are optional adapters.

## 10. State and Transaction Boundary

State and transaction APIs are not required for 0.1 action execution. They must not be implemented as a hidden global store.

Later state contract:

```lua
local state = State.new(defaultValue, scope)
local tx = state:transaction()
tx:set({"Coins"}, 100)
tx:commit()
```

Rollback only covers mutations registered with Anvil. External effects require explicit compensation.

## 11. Testing Architecture

Core tests use injected fakes:

```text
TestClock
TestTransport
TestPlayer
TestRng
TestScope
```

Tests must not call live DataStoreService, MarketplaceService, or real client networking.

## 12. Performance Rules

- no mandatory global Heartbeat connection;
- no polling for player or Instance lifecycle;
- no deep copy unless explicitly requested;
- no Promise for synchronous Result;
- no diagnostic string formatting on disabled paths;
- bounded diagnostic buffers;
- no automatic Workspace scan;
- optional adapters lazy-loaded.

## 13. Compatibility

Required:

- Roblox Luau;
- `--!strict` public modules;
- Rojo;
- Wally;
- TestEZ-compatible test execution.

Optional:

- ByteNet;
- Remo;
- Replica;
- ProfileStore;
- Scribe;
- Fusion;
- Trove.

## 14. Rust Analogy Boundaries

| Rust concept | Anvil implementation | Limitation |
| --- | --- | --- |
| `Result<T, E>` | typed discriminated table | not language primitive |
| ownership | explicit Scope | not borrow-checked |
| traits | adapter tables/types | no trait compiler |
| Cargo | Wally plus future CLI | Wally remains package manager |
| compiler diagnostics | runtime and future CLI diagnostics | Luau checker remains separate |
| `cargo test` | deterministic Anvil tests | engine behavior still needs integration tests |
| zero-cost abstraction | disabled feature fast paths | must be verified by benchmark |

## 15. Dependency Policy

Anvil core adds no mandatory third-party dependency. An adapter may depend on its target package. The main package must not vendor or fork existing packages without a documented reason.
