# Migration to 0.3.0

## New APIs

- Use `Anvil.Adapters.ByteNet.eventHandler` inside caller-owned ByteNet listener registration.
- Use `Anvil.Adapters.Remo.bindEvent` for Scope-owned Remo event cleanup, or `requestHandler` for caller-owned Remo request registration.
- Use `Replica.own`, `ProfileStore.ownSession`, and `Trove.own` only when Anvil Scope is sole lifecycle owner.
- Use `Scribe.waitForData` to map unavailable data to `ADAPTER_SCRIBE_DATA_UNAVAILABLE`.

## Compatibility

Existing core APIs remain compatible. Adapter packages remain optional Wally development targets and never become Anvil runtime dependencies.
