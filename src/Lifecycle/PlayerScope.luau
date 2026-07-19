--!strict

local Scope = require(script.Parent.Parent.Core.Scope)

local PlayerScope = {}

type Connection = {
    Disconnect: (self: Connection) -> (),
}

type Signal = {
    Connect: (self: Signal, callback: (value: unknown) -> ()) -> Connection,
}

export type Player = {
    Character: unknown?,
    CharacterAdded: Signal,
}

export type PlayerScope = {
    scope: Scope.Scope,
    player: Player,
    characterScope: Scope.Scope?,
    destroy: (self: PlayerScope) -> (),
}

function PlayerScope.new(playerValue: unknown, playerRemovingValue: unknown): PlayerScope
    local player = playerValue :: any
    local playerRemoving = playerRemovingValue :: any
    assert(player ~= nil and player.CharacterAdded ~= nil, "player must expose CharacterAdded")
    assert(playerRemoving ~= nil and playerRemoving.Connect ~= nil, "playerRemoving must expose Connect")
    local scope = Scope.new("Player", player)
    local binding = {
        scope = scope,
        player = player,
        characterScope = nil,
    } :: PlayerScope
    local currentCharacterScope: Scope.Scope? = nil

    local function replaceCharacterScope(character: unknown)
        if scope.destroyed then
            return
        end
        if currentCharacterScope ~= nil then
            currentCharacterScope:destroy()
        end

        currentCharacterScope = Scope.new("Character", character)
        binding.characterScope = currentCharacterScope
    end

    scope:defer(function()
        if currentCharacterScope ~= nil then
            currentCharacterScope:destroy()
        end
    end)
    scope:connect(player.CharacterAdded:Connect(replaceCharacterScope), function(connection: unknown)
        (connection :: Connection):Disconnect()
    end)
    scope:connect(
        playerRemoving:Connect(function(removedPlayer: unknown)
            if removedPlayer == player then
                scope:destroy()
            end
        end),
        function(connection: unknown)
            (connection :: Connection):Disconnect()
        end
    )

    if player.Character ~= nil then
        replaceCharacterScope(player.Character)
    end

    function binding.destroy(_self: PlayerScope)
        scope:destroy()
    end

    return binding
end

return PlayerScope
