--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = require(ServerScriptService.Anvil)

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it
    describe("Anvil", function()
        it("exports public modules from package root", function()
            assert(type(Anvil.Action.new) == "function", "package root must export Action")
            assert(type(Anvil.Schema.object) == "function", "package root must export Schema")
            assert(type(Anvil.Scope.new) == "function", "package root must export Scope")
            assert(type(Anvil.Result.ok) == "function", "package root must export Result")
            assert(type(Anvil.Error.new) == "function", "package root must export Error")
            assert(Anvil.ErrorCode.ACTION_COOLDOWN == "ACTION_COOLDOWN", "package root must export ErrorCode")
            assert(type(Anvil.Test.FakeClock.new) == "function", "package root must export test helpers")
            assert(type(Anvil.Lifecycle.PlayerScope.new) == "function", "package root must export lifecycle helpers")
            assert(type(Anvil.Test.FakePlayer.new) == "function", "package root must export player fixture")
        end)
    end)
end
