# Migration to 0.4.0

## New APIs

- Use `Anvil.Transaction.new()` for local, caller-owned mutations that may need reverse-order rollback.
- Register external-effect reversal with `transaction:compensate(callback)`; never assume purchases, network sends, physics, or persistent writes roll back automatically.
- Use `Anvil.RequestId`, `Anvil.AuditRecord`, and `Anvil.ReplayRecord` when a deterministic request fixture needs stable identity and bounded diagnostic data.
- Use `Anvil.Test.FakeRng` with `Anvil.Test.FakeClock` for deterministic replay fixtures.

## Compatibility

Existing APIs remain compatible. `0.4.0` adds opt-in contracts only; it changes no existing Action, Schema, Scope, transport, or adapter behavior.
