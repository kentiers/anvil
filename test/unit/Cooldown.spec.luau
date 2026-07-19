--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = ServerScriptService.Anvil
local Cooldown = require(Anvil.Action.Cooldown)
local FakeClock = require(Anvil.Test.FakeClock)

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("Cooldown", function()
        it("enforces a deterministic per-player boundary", function()
            local clock = FakeClock.new()
            local cooldown = Cooldown.new(2, function()
                return clock:now()
            end)
            local player = {}

            assert(cooldown:check(player).ok, "first request must pass")

            clock:advance(1.5)
            local blocked = cooldown:check(player)
            assert(not blocked.ok, "request before expiry must fail")
            if not blocked.ok then
                assert(blocked.error.code == "ACTION_COOLDOWN", "cooldown error code must be stable")
                assert(
                    blocked.error.details ~= nil and blocked.error.details.remaining == 0.5,
                    "remaining time must be exact"
                )
            end

            clock:advance(0.5)
            assert(cooldown:check(player).ok, "request at expiry must pass")
            cooldown:clear(player)
            assert(cooldown:check(player).ok, "cleared player cooldown must pass")
        end)
    end)
end
