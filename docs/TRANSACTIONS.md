# Transactions and Replay

Phase 4 adds explicit managed mutation transactions. A transaction owns only table mutations registered through `set` or `delete`; it does not observe or reverse arbitrary Roblox or external effects.

```lua
local transaction = Anvil.Transaction.new()
transaction:set(state, "Coins", state.Coins - price)
transaction:compensate(function()
    -- reverse an external effect explicitly, when possible
end)
local result = transaction:commit()
```

Call `rollback()` on domain failure. Rollback restores managed values in reverse order and invokes compensation callbacks in reverse order. Compensation failure returns `TRANSACTION_ROLLBACK_FAILED`; it never claims an external effect was automatically reversed. Closed transactions reject later operations with `TRANSACTION_CLOSED`.

`RequestId`, `AuditRecord`, and `ReplayRecord` are bounded data contracts. `FakeRng` and `FakeClock` make deterministic fixtures reproducible. Replay records describe deterministic execution; Anvil never replays external effects automatically.
