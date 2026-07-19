# Migration to 0.2.0

## Compatibility

No required migration from `0.1.3`. Existing `Result`, `Schema`, `Scope`, `Action`, and `RobloxRemote` behavior remains unchanged.

## New APIs

- Use `Anvil.ErrorCode` instead of copied Anvil-emitted error-code literals.
- Use `Anvil.Lifecycle.PlayerScope` for explicit Player and Character Scope ownership.
- Use `Anvil.Test.FakeClock`, `FakePlayer`, `FakeSignal`, and `FakeTransport` for deterministic Roblox-facing tests.
- Pass an optional `audit` callback to `Scope.new(name, owner, options)` only for server-side development diagnostics. It receives `scope_destroyed` and `scope_use_after_destroy` events; production callers leave it unset.

## No behavior changes

- Audit remains opt-in. It starts no telemetry, polling, or global loop when unset.
- Client transport responses still expose only stable error codes for failures.
- Player lifecycle helpers still contain no game-domain policy.
