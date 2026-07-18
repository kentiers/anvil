# Anvil

Anvil is server-side Luau foundation for Roblox actions with explicit `Result`, `Schema`, `Scope`, rate-limit, cooldown, authorization, and RemoteEvent/RemoteFunction boundaries.

## Status

Pre-1.0 development. APIs may change in minor releases before `1.0.0`.

## Install

```toml
[server-dependencies]
Anvil = "kentiers/anvil@0.1.1"
```

Install with Wally, then place package in a server-only Rojo location such as `ServerScriptService`. Do not expose `Action` or `Transport` modules through `ReplicatedStorage`.

### Migration

Initial public release. No prior public API exists to migrate.

## Quick start

```lua
--!strict

local Anvil = ServerScriptService.Packages.Anvil
local Action = require(Anvil.Action.Action)
local Cooldown = require(Anvil.Action.Cooldown)
local RateLimit = require(Anvil.Action.RateLimit)
local Result = require(Anvil.Core.Result)
local Schema = require(Anvil.Schema.Schema)

local purchase = Action.new("Purchase", {
    input = Schema.object({
        ItemId = Schema.string():minLength(1):maxLength(64),
    }),
    output = Schema.object({ Accepted = Schema.boolean() }),
    cooldown = Cooldown.new(0.25, os.clock),
    rateLimit = RateLimit.new(10, 1, os.clock),
    authorize = function()
        return Result.ok(nil)
    end,
    execute = function(context)
        -- Server validates ownership, price, and mutation here.
        return Result.ok({ Accepted = true })
    end,
})
```

Bind a caller-owned remote on server:

```lua
local RobloxRemote = require(Anvil.Transport.RobloxRemote)
local transport = RobloxRemote.new()
transport:bindEvent(remoteEvent, purchase, services)
```

## Roblox schema policy

```lua
local target = Schema.instance({
    classNames = { "BasePart" },
    ancestor = workspace:WaitForChild("BuildArea"),
})
```

Roblox datatypes use explicit validators: `Schema.vector3()`, `Schema.cframe()`, `Schema.color3()`, and `Schema.enumItem(expectedEnum?)`. `Schema.instance` always requires both class allow-list and ancestry root. Passing schema validation does not prove a player owns, may modify, or may target that Instance.

## Guarantees and limits

- Raw remote payload is schema-validated before execution.
- Order: validation, rate limit, cooldown, authorization, execution, output validation.
- Request scopes are destroyed after transport dispatch.
- Client failures expose stable error codes only.
- Anvil does not validate game economy, ownership, damage, or rewards automatically.
- Core creates no polling loop and has no mandatory third-party runtime dependency.

## Verification

```powershell
wally install
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
```

## Consumer smoke test

After `kentiers/anvil@0.1.0` is available in Wally, verify a clean consumer project with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/test-consumer.ps1
```

`examples/consumer` installs the exact public package, maps it server-only through Rojo, then verifies valid and invalid `Action` requests with an Instance policy.

TestEZ runs through local Roblox Studio. GitHub-hosted CI runs formatting, lint, and strict analysis only.
