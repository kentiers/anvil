--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = ServerScriptService.Anvil
local RateLimit = require(Anvil.Action.RateLimit)
local FakeClock = require(Anvil.Test.FakeClock)

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("RateLimit", function()
        it("refills deterministic per-player token buckets", function()
            local clock = FakeClock.new()
            local rateLimit = RateLimit.new(2, 1, function()
                return clock:now()
            end)
            local player = {}

            assert(rateLimit:check(player).ok, "first token must pass")
            assert(rateLimit:check(player).ok, "second token must pass")

            local blocked = rateLimit:check(player)
            assert(not blocked.ok, "empty bucket must fail")
            if not blocked.ok then
                assert(blocked.error.code == "ACTION_RATE_LIMITED", "rate-limit error code must be stable")
                assert(
                    blocked.error.details ~= nil and blocked.error.details.retryAfter == 1,
                    "retry delay must be exact"
                )
            end

            clock:advance(0.5)
            assert(not rateLimit:check(player).ok, "partial refill must not permit a request")

            clock:advance(0.5)
            assert(rateLimit:check(player).ok, "full token refill must permit a request")

            local otherPlayer = {}
            assert(rateLimit:check(otherPlayer).ok, "players must have independent buckets")
        end)
    end)
end
