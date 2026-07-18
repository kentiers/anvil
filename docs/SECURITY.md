# Anvil Security Model

**Applies to:** public `0.1.x` line
**Status:** supported baseline

Anvil provides server-side trust-boundary controls. It does not make game-domain rules correct by inference.

## Threat model

Treat every client, client payload, and client-visible Instance as untrusted. Treat server configuration and server-owned state as trusted only inside game code's own security boundary.

Anvil assumes Roblox delivers a network payload to a caller-owned `RemoteEvent` or `RemoteFunction`. The application decides which remote exists and which Action it binds. Anvil never discovers or creates remotes automatically.

## Enforced action boundary

For an `Action`, raw input follows one fixed order:

```text
receive
  -> schema validation
  -> rate limit
  -> cooldown
  -> authorization
  -> domain execution
  -> output validation
  -> safe response
```

Consequences:

- invalid input does not reach `execute`;
- unknown object fields are rejected by default;
- rate limits and cooldowns run on server state;
- an authorization hook runs before domain execution;
- declared output is validated before transport serializes a success response;
- expected failure returns a stable code, not an internal error object.

## What schemas validate

Schemas validate shape, bounds, and selected Roblox datatypes. Default payload policy:

- reject unknown object fields;
- reject `NaN`, positive infinity, and negative infinity;
- bound strings and numbers when schema declares bounds;
- recursively validate arrays and objects against their supplied schemas;
- reject unsupported values;
- reject arbitrary Instances unless an explicit policy allows them.

`Schema.instance` requires non-empty `classNames` and an `ancestor` Instance. Accepted values must satisfy an allowed `IsA` class and be the ancestor itself or a descendant.

This is **reference validation**, not authorization. Domain code must still validate ownership, entitlement, placement rules, distance, currency, inventory, and moderation policy.

## Client response policy

Remote failures expose only a stable error code:

```lua
return Anvil.Result.err("PURCHASE_NOT_ALLOWED")
```

Do not return stack traces, DataStore keys, private profiles, moderation notes, secrets, or detailed server state to clients. Keep operational diagnostics server-only and bounded.

## Resource lifecycle

Use `Scope` for every resource an Action or service owns:

- `RBXScriptConnection`;
- cancellable scheduled thread;
- Instance;
- callback registration;
- child Scope.

Scope destruction is idempotent. Transport dispatch creates a request Scope and destroys it after dispatch completes. Long-lived resources still need an explicit application-owned Scope.

## Limits

Anvil does not:

- detect all exploits or replace anti-cheat;
- make client UI state authoritative;
- validate economy, rewards, damage, or ownership automatically;
- guarantee rollback of Roblox physics, DataStore writes, or other external effects;
- secure other packages, remotes, or handlers not routed through an Anvil Action.

## Production integration checklist

- [ ] Place Anvil under `ServerScriptService.ServerPackages`; never expose Action or Transport under `ReplicatedStorage`.
- [ ] Bind caller-owned remotes only on server.
- [ ] Give every client-originated Action a runtime input schema.
- [ ] Reject or normalize client fields before domain execution.
- [ ] Read prices, balances, rewards, permissions, and ownership from server-owned state.
- [ ] Add authorization, cooldown, and rate limit where abuse is plausible.
- [ ] Constrain Instance references by class and ancestry; then apply game-specific authorization.
- [ ] Return stable `Result.err` codes for expected failures.
- [ ] Register owned resources with a Scope and destroy it at lifecycle end.
- [ ] Test malformed, boundary, unauthorized, rate-limited, and cleanup paths.

## Reporting vulnerabilities

Do not publish exploit details in a public issue. Use [GitHub private security reporting](https://github.com/kentiers/anvil/security/advisories/new) with affected version, minimum reproduction, impact, and proposed mitigation. If private reporting is unavailable, contact repository maintainers before opening an issue.
