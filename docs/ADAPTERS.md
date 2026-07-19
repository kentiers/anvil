# Optional Adapters

Anvil core never requires adapter packages. Install and own ByteNet, Remo, Replica, ProfileStore, Scribe, or Trove in consumer code; pass their live objects into `Anvil.Adapters` helpers.

## Transport

- `ByteNet.eventHandler(action, services, responsePacket?)` returns a listener for `packet.listen`. ByteNet owns listener registration because its documented packet API has no unsubscribe contract. The caller owns that persistent registration.
- `Remo.bindEvent(remote, action, services?)` owns Remo's returned disconnect callback in an Anvil `Scope`.
- `Remo.requestHandler(action, services?)` returns a server handler for `remote:onRequest`; caller owns request-handler registration because Remo documents no handler removal API.

Every handler enters `ActionDispatch`: request Scope, schema validation, rate limit, cooldown, authorization, execution, output validation, and safe error serialization remain unchanged.

## State and persistence

- `Replica.own(scope, replica)` destroys a caller-created replica when scope ends.
- `ProfileStore.ownSession(scope, session)` calls `EndSession()` when scope ends. Do not give same session another lifecycle owner.
- `Scribe.waitForData(data, player)` wraps `WaitForData`; unavailable data returns stable `ADAPTER_SCRIBE_DATA_UNAVAILABLE`.
- `Trove.own(scope, trove)` destroys a caller-created Trove when scope ends.

Adapters never create stores, remotes, replicas, or player sessions. Domain code retains authority over persistence, replication visibility, and external effects.

## Tests

`test/unit/Adapters.spec.luau` is an isolated contract kit. It proves payload validation and safe serialization survive transport callbacks, each owned resource releases exactly once, and Scribe load failure has a stable code. Consumer projects must also run their own real-package integration test after pinning a target package version.
