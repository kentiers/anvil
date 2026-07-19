--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = ServerScriptService.Anvil
local FakeClock = require(Anvil.Test.FakeClock)

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("FakeClock", function()
        it("advances deterministic monotonic time", function()
            local clock = FakeClock.new(1.25)

            assert(clock:now() == 1.25, "initial time must be preserved")
            assert(clock:advance(0.5) == 1.75, "advance must return current time")
            assert(clock:now() == 1.75, "clock must retain advanced time")
        end)

        it("rejects non-finite or backward time", function()
            assert(not pcall(function()
                FakeClock.new(math.huge)
            end), "non-finite initial time must fail")

            local clock = FakeClock.new()
            assert(not pcall(function()
                clock:advance(-0.01)
            end), "negative advance must fail")
            assert(not pcall(function()
                clock:advance(math.huge)
            end), "non-finite advance must fail")
            local nearLimit = FakeClock.new(1e308)
            assert(not pcall(function()
                nearLimit:advance(1e308)
            end), "overflowing advance must fail")
            assert(nearLimit:now() == 1e308, "failed overflowing advance must not mutate time")
            assert(clock:now() == 0, "failed advances must not mutate time")
        end)
    end)
end
