--!strict

local FakeSignal = require(script.Parent.FakeSignal)

local FakePlayer = {}

export type FakePlayer = {
    Name: string,
    Character: unknown?,
    CharacterAdded: FakeSignal.Signal,
    Removing: FakeSignal.Signal,
    spawnCharacter: (self: FakePlayer, character: unknown) -> (),
    remove: (self: FakePlayer) -> (),
}

function FakePlayer.new(name: string): FakePlayer
    assert(name ~= "", "fake player name must not be empty")

    local player = {
        Name = name,
        Character = nil,
        CharacterAdded = FakeSignal.new(),
        Removing = FakeSignal.new(),
    } :: FakePlayer

    function player.spawnCharacter(self: FakePlayer, character: unknown)
        assert(character ~= nil, "fake player character must not be nil")
        self.Character = character
        self.CharacterAdded:fire(character)
    end

    function player.remove(self: FakePlayer)
        self.Removing:fire(self)
    end

    return player
end

return FakePlayer
