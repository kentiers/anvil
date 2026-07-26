--!strict

local FakeRng = {}

export type FakeRng = {
    next: (self: FakeRng) -> number,
}

function FakeRng.new(seed: number): FakeRng
    assert(seed % 1 == 0 and seed >= 0, "fake RNG seed must be a non-negative integer")
    local state = seed
    local rng = {} :: FakeRng
    function rng.next(_self: FakeRng): number
        state = (state * 1664525 + 1013904223) % 4294967296
        return state / 4294967296
    end
    return rng
end

return FakeRng
