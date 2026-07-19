--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = require(ServerScriptService.Anvil)
local FakePlayer = Anvil.Test.FakePlayer

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("FakePlayer", function()
        it("emits character and removal lifecycle events", function()
            local player = FakePlayer.new("Player")
            local characterEvents = 0
            local removalEvents = 0
            local character = {}
            local characterConnection = player.CharacterAdded:Connect(function(value)
                characterEvents += 1
                assert(value == character, "character signal must emit spawned character")
            end)
            player.Removing:Connect(function(value)
                removalEvents += 1
                assert(value == player, "removal signal must emit player")
            end)

            player:spawnCharacter(character)
            player:remove()
            assert(player.Character == character, "spawned character must remain current")
            assert(characterEvents == 1, "character event must fire once")
            assert(removalEvents == 1, "removal event must fire once")

            characterConnection:Disconnect()
            player:spawnCharacter({})
            assert(characterEvents == 1, "disconnected signal listener must not fire")
        end)
    end)
end
