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

### Stable error codes

`Anvil.ErrorCode` is a frozen catalog for every stable error code emitted by Anvil. Consumers branch on these constants instead of copied string literals. Constant values are transport-safe wire contracts and cannot change in a compatible release.

Only Anvil-emitted codes belong in this catalog. Errors returned by consumer `authorize` or `execute` callbacks remain application-defined.

```lua
Anvil.ErrorCode.ACTION_COOLDOWN
Anvil.ErrorCode.ACTION_RATE_LIMITED
Anvil.ErrorCode.SCHEMA_TYPE_MISMATCH
Anvil.ErrorCode.SCHEMA_INTERNAL_TYPE
Anvil.ErrorCode.SCHEMA_INTEGER_REQUIRED
Anvil.ErrorCode.SCHEMA_STRING_TOO_SHORT
Anvil.ErrorCode.SCHEMA_STRING_TOO_LONG
Anvil.ErrorCode.SCHEMA_NUMBER_OUT_OF_RANGE
Anvil.ErrorCode.SCHEMA_VECTOR3_REQUIRED
Anvil.ErrorCode.SCHEMA_CFRAME_REQUIRED
Anvil.ErrorCode.SCHEMA_COLOR3_REQUIRED
Anvil.ErrorCode.SCHEMA_ENUM_ITEM_REQUIRED
Anvil.ErrorCode.SCHEMA_INSTANCE_REQUIRED
Anvil.ErrorCode.SCHEMA_INSTANCE_CLASS
Anvil.ErrorCode.SCHEMA_INSTANCE_ANCESTRY
Anvil.ErrorCode.SCHEMA_ARRAY_REQUIRED
Anvil.ErrorCode.SCHEMA_UNKNOWN_FIELD
Anvil.ErrorCode.SCHEMA_UNION_MISMATCH
```

## 6. Scope Contract

```lua
local scope = Scope.new("Player", player)

scope:connect(connection, disconnect)
scope:own(thread, cancel)
scope:own(instance, destroy)
scope:defer(cleanup)
local child = scope:child("Character", character)
scope:destroy()
```

Invariants:

- destruction is idempotent;
- children are destroyed before parent completion;
- resources are cleaned through explicit callbacks;
- owned cancellable threads are cancelled through their registered callback;
- owned Instances are destroyed only when explicitly registered;
- new resources cannot be registered after destruction;
- development mode may report use-after-destroy.

`Scope` does not infer ownership or cleanup behavior from arbitrary values. Resource cleanup callbacks must be supplied explicitly.

Development callers may opt into bounded-by-caller lifecycle audit events:

```lua
local scope = Scope.new("Player", player, {
    audit = function(event)
        -- `scope_destroyed` or `scope_use_after_destroy`
    end,
})
```

Each enabled event contains only `kind`, `scopeName`, and attempted `operation` when relevant. Child scopes inherit the hook. No hook, telemetry, event table, background loop, or polling exists by default. Callers enable this only in development; audit callbacks remain server-side and must not receive client payloads or secrets.

`Lifecycle.PlayerScope.new(player, Players.PlayerRemoving)` binds an explicit player root Scope. It creates one current Character Scope, destroys the prior Character Scope on `CharacterAdded`, and destroys both scopes when that player is removed. It carries no team, inventory, avatar, or game-mode policy.

## 7. Schema Contract

```lua
local ActionInput = Schema.object({
    Name = Schema.string():minLength(1):maxLength(64),
    Count = Schema.integer():between(1, 99),
})

local result = ActionInput:parse(raw)
```

Schema responsibilities:

- runtime validation;
- normalization;
- path-aware errors;
- static exported types where Luau supports them;
- explicit Roblox datatype policies.

Current Roblox datatype validators cover `Vector3`, `CFrame`, `Color3`, and `EnumItem`. `Schema.instance` requires an explicit class allow-list and ancestry root; arbitrary Instances have no default schema.

Datatype checks are constant work except `CFrame`, which checks its fixed twelve components, and `Schema.instance`, which is $O(c)$ for $c$ allowed classes plus one ancestry query. CFrame validation uses multiple returns rather than allocating a temporary component table.

Schema does not infer security policy from a field name.

## 8. Action Contract

```lua
local action = Action.new("Example.Execute", {
    input = ActionInput,
    output = Schema.object({ Accepted = Schema.boolean() }),
    cooldown = Cooldown.new(0.25, os.clock),
    rateLimit = RateLimit.new(10, 1, os.clock),
    authorize = authorize,
    execute = function(context)
        return Result.ok({ Accepted = true })
    end,
})
```

`Action:run(context)` validates input, then applies rate limit, cooldown, authorization, execution, and declared output validation. Only validated input reaches `execute`. Expected failures return `Result`; programmer failures throw.

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

## 9. Roblox Remote Transport

```lua
local transport = RobloxRemote.new()
local binding = transport:bindEvent(remoteEvent, action, services)
```

`RobloxRemote` accepts caller-owned `RemoteEvent` or `RemoteFunction` instances; it never creates remotes implicitly. Each request gets a destroyed request scope after execution. Client failures expose only stable error codes. Successful values are sent only when `Action` declares and validates an output schema. Transport and Action modules are server-only.

## 10. State and Transaction Boundary

State and transaction APIs are not required for 0.1 action execution. They must not be implemented as a hidden global store.

Later state contract:

```lua
local state = State.new(defaultValue, scope)
local tx = state:transaction()
tx:set({"Value"}, 100)
tx:commit()
```

Rollback only covers mutations registered with Anvil. External effects require explicit compensation.

## 11. Testing Architecture

Core tests use injected fakes rather than live platform services:

```text
FakeClock
FakeTransport
FakePlayer
FakeRng
FakeScope
```

`Anvil.Test.FakeClock` starts at a finite supplied time or zero, advances only by finite non-negative intervals, and can supply injected clock callbacks to deterministic tests. Tests must not call live DataStoreService, MarketplaceService, or real client networking.

`Anvil.Test.FakeTransport` creates deterministic event and function remotes for `RobloxRemote:bindEvent` and `:bindFunction` tests. It records event client responses, can trigger server events, and clears bindings through returned Scope destruction.

## 12. Performance Rules

- no mandatory global Heartbeat connection;
- no polling for player or Instance lifecycle;
- no deep copy unless explicitly requested;
- no Promise for synchronous Result;
- no diagnostic string formatting on disabled paths;
- bounded diagnostic buffers;
- no automatic Workspace scan;
- optional adapters lazy-loaded.

Action request cost is schema parsing plus constant-time rate-limit and cooldown table lookups, one request `Scope`, and domain execution. Scope lifecycle audit allocates an event only when a caller opts in; disabled scopes have no hook, telemetry, background loop, or polling cost. `benchmarks/ActionBenchmark.luau` compares validated manual input handling with Action execution for a fixed small object payload; it is a local comparison, not a universal performance claim.

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
