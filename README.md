# Anvil

[![Verify](https://github.com/kentiers/anvil/actions/workflows/verify.yml/badge.svg)](https://github.com/kentiers/anvil/actions/workflows/verify.yml)
[![Release](https://img.shields.io/github/v/release/kentiers/anvil?display_name=tag&label=release)](https://github.com/kentiers/anvil/releases)
[![License](https://img.shields.io/github/license/kentiers/anvil)](LICENSE)
[![Wally](https://img.shields.io/badge/Wally-kentiers%2Fanvil-ff6a8b)](https://wally.run/package/kentiers/anvil)

Server-authoritative Luau foundation for Roblox actions, runtime schemas, resource scopes, and safe remote boundaries.

Anvil gives server code one explicit path for untrusted input:

```text
remote payload
  -> schema validation
  -> rate limit
  -> cooldown
  -> authorization
  -> domain execution
  -> output validation
  -> safe client response
```

## Why Anvil

- **Trust boundaries are explicit.** Raw client values do not reach an action executor before its input schema passes.
- **Failure is typed.** `Result` and stable error codes model expected gameplay failures without Promise allocation.
- **Resource ownership is visible.** `Scope` owns connections, Instances, callbacks, and cancellable work; destruction is idempotent.
- **Runtime cost is predictable.** Core has no required third-party runtime dependency, polling loop, or hidden remote creation.

## Non-goals

Anvil is not an anti-cheat system, DataStore wrapper, UI framework, networking replacement, or game-rule engine. Game code still owns prices, inventory, ownership, damage, permissions, and external-effect compensation.

## Install

Anvil is a server-realm Wally package. Pin an exact version:

```toml
[server-dependencies]
Anvil = "kentiers/anvil@0.3.0"
```
```bash
wally install
```

Map Wally's server dependencies into `ServerScriptService` with Rojo:

```json
{
  "name": "MyGame",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "ServerPackages": { "$path": "ServerPackages" }
    }
  }
}
```

Never map Anvil's `Action` or `Transport` modules into `ReplicatedStorage`.

## Use case: server-authoritative purchase request

This example accepts only a bounded item identifier. Price, ownership, inventory mutation, and reward remain server decisions inside `execute`.

```lua
--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local AnvilModule = ServerScriptService.ServerPackages.Anvil
local Anvil = require(AnvilModule)
local RobloxRemote = require(AnvilModule.Transport.RobloxRemote)

local purchase = Anvil.Action.new("Purchase", {
    input = Anvil.Schema.object({
        ItemId = Anvil.Schema.string():minLength(1):maxLength(64),
    }),
    output = Anvil.Schema.object({ Accepted = Anvil.Schema.boolean() }),
    cooldown = require(AnvilModule.Action.Cooldown).new(0.25, os.clock),
    rateLimit = require(AnvilModule.Action.RateLimit).new(10, 1, os.clock),
    authorize = function()
        return Anvil.Result.ok(nil)
    end,
    execute = function(context)
        local input = context.input :: { ItemId: string }

        -- Read catalog, price, balance, and ownership from server-owned state.
        if input.ItemId == "" then
            return Anvil.Result.err("PURCHASE_NOT_ALLOWED")
        end
        return Anvil.Result.ok({ Accepted = true })
    end,
})

local remotes = ServerScriptService:WaitForChild("Remotes")
local purchaseRemote = remotes:WaitForChild("Purchase") :: RemoteEvent
RobloxRemote.new():bindEvent(purchaseRemote, purchase, {})
```

The caller creates and owns `purchaseRemote`; Anvil does not create remotes implicitly.

## Runtime schemas

Use schemas at every untrusted boundary. Roblox datatypes are explicit, and Instance references require both class and ancestry constraints:

```lua
local target = Anvil.Schema.instance({
    classNames = { "BasePart" },
    ancestor = workspace:WaitForChild("BuildArea"),
})
```

Available Roblox validators: `Schema.vector3()`, `Schema.cframe()`, `Schema.color3()`, and `Schema.enumItem(expectedEnum?)`.

Passing `Schema.instance` only proves reference shape and location. It does **not** prove player ownership, entitlement, placement validity, or permission.

## Security and lifecycle

- Input order is validation, rate limit, cooldown, authorization, execution, then output validation.
- Unknown object fields, non-finite numbers, unsupported datatypes, and unconfigured Instances are rejected.
- Client failures expose stable codes, not stack traces or server state.
- Each request transport dispatch owns a `Scope` and destroys it after completion.
- `Scope` lifecycle audit is opt-in, server-only, and has no default telemetry or polling.

Read [Security model](docs/SECURITY.md) before binding production remotes. Read [Architecture](docs/ARCHITECTURE.md) for contracts, constraints, and cost model.

## Roadmap

| Phase | Focus | Status |
| --- | --- | --- |
| 0.1 | Core: Result, Schema, Scope, Action, transport | Released |
| 0.2 | Reliability: lifecycle helpers, fakes, diagnostics | Released (`0.2.0`) |
| 0.3 | Optional integration adapters | Released (`0.3.0`) |
| 0.4+ | Transactions, generated contracts, CLI, Studio tooling | Planned |

Full scope and exit gates: [ROADMAP.md](docs/ROADMAP.md).

## Verification

```powershell
wally install
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
powershell -ExecutionPolicy Bypass -File scripts/test-consumer.ps1
```

The consumer smoke test downloads exact public Wally package version, maps it server-only through Rojo, and exercises valid and invalid Action requests. TestEZ runs through local Roblox Studio; GitHub CI runs format, lint, and strict analysis.

## Documentation

- [Security model](docs/SECURITY.md)
- [Architecture and API contracts](docs/ARCHITECTURE.md)
- [Tooling and verification](docs/TOOLING.md)
- [Optional adapter contracts](docs/ADAPTERS.md)
- [Changelog](CHANGELOG.md)
- [0.2.0 migration notes](docs/MIGRATION-0.2.0.md)
- [0.3.0 migration notes](docs/MIGRATION-0.3.0.md)
- [Release notes](https://github.com/kentiers/anvil/releases)

## Contributing and support

Open a focused [issue](https://github.com/kentiers/anvil/issues) for bugs, design proposals, or documentation gaps. Report vulnerabilities privately; see [SECURITY.md](SECURITY.md).

## Credits

Built for Roblox with [Luau](https://luau.org/), [Wally](https://github.com/UpliftGames/wally), [Rojo](https://rojo.space/), and [TestEZ](https://github.com/Roblox/testez). Anvil is independent software; these projects are not bundled runtime dependencies.

## License

[MIT](LICENSE) © 2026 kentiers.
