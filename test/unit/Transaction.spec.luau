--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = require(ServerScriptService.Anvil)

return function()
    local environment = getfenv()
    local describe: (string, () -> ()) -> () = environment.describe
    local it: (string, () -> ()) -> () = environment.it

    describe("Transaction", function()
        it("rolls back managed mutations after partial failure", function()
            local state = { Coins = 10, Item = nil }
            local transaction = Anvil.Transaction.new()
            assert(transaction:set(state, "Coins", 0).ok, "set must succeed")
            assert(transaction:set(state, "Item", "Sword").ok, "second set must succeed")
            assert(transaction:rollback().ok, "rollback must succeed")
            assert(state.Coins == 10 and state.Item == nil, "rollback must restore all managed mutations")
        end)

        it("does not claim external effects rolled back", function()
            local compensated = 0
            local transaction = Anvil.Transaction.new()
            assert(
                transaction:compensate(function()
                    compensated += 1
                end).ok,
                "compensation registration must succeed"
            )
            assert(transaction:rollback().ok, "rollback with compensation must succeed")
            assert(compensated == 1, "external effects require explicit compensation")
            local commit = transaction:commit()
            assert(not commit.ok, "closed transaction must reject commit")
            if not commit.ok then
                assert(commit.error.code == Anvil.ErrorCode.TRANSACTION_CLOSED, "closed code must be stable")
            end
        end)

        it("replays deterministic request inputs", function()
            local ids = Anvil.RequestId.new(function()
                return "request-1"
            end)
            local rng = Anvil.Test.FakeRng.new(7)
            local first = { rng:next(), rng:next() }
            local record = Anvil.ReplayRecord.new("Test.Replay", ids:next(), { Value = 4 }, 8, 2, first)
            local same = Anvil.ReplayRecord.new("Test.Replay", "request-1", { Value = 4 }, 8, 2, first)
            assert(
                record.requestId == same.requestId and record.result == same.result,
                "deterministic replay record must preserve Result"
            )
            assert(
                record.random[1] == same.random[1] and record.random[2] == same.random[2],
                "replay must preserve RNG sequence"
            )
        end)

        it("creates bounded action audit records", function()
            local record = Anvil.AuditRecord.new("Test.Action", "request-1", {}, "ok", "committed")
            assert(
                record.action == "Test.Action" and record.requestId == "request-1",
                "audit must preserve stable identity"
            )
            assert(record.transaction == "committed", "audit must preserve transaction outcome")
        end)
    end)
end
