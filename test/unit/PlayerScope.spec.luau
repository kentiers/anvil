--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = require(ServerScriptService.Anvil)
local PlayerScope = Anvil.Lifecycle.PlayerScope
local FakePlayer = Anvil.Test.FakePlayer
local FakeSignal = Anvil.Test.FakeSignal

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("PlayerScope", function()
        it("replaces character scopes and destroys them on player removal", function()
            local player = FakePlayer.new("Player")
            local playerRemoving = FakeSignal.new()
            local initialCharacter = {}
            player:spawnCharacter(initialCharacter)

            local binding = PlayerScope.new(player, playerRemoving)
            local initialScope = binding.characterScope
            assert(initialScope ~= nil and initialScope.owner == initialCharacter, "initial character needs a scope")

            local cleanupCount = 0
            initialScope:defer(function()
                cleanupCount += 1
            end)

            local replacementCharacter = {}
            player:spawnCharacter(replacementCharacter)
            assert(initialScope.destroyed, "replacement must destroy prior character scope")
            assert(cleanupCount == 1, "prior character cleanup must run once")

            local replacementScope = binding.characterScope
            assert(
                replacementScope ~= nil and replacementScope.owner == replacementCharacter,
                "replacement character needs a new scope"
            )
            replacementScope:defer(function()
                cleanupCount += 1
            end)

            local otherPlayer = FakePlayer.new("Other")
            playerRemoving:fire(otherPlayer)
            assert(not binding.scope.destroyed, "other player removal must not destroy scope")

            playerRemoving:fire(player)
            assert(binding.scope.destroyed, "player removal must destroy scope")
            assert(replacementScope.destroyed, "player removal must destroy current character scope")
            assert(cleanupCount == 2, "current character cleanup must run once")

            player:spawnCharacter({})
            assert(binding.characterScope == replacementScope, "destroyed binding must ignore later character events")
        end)
    end)
end
