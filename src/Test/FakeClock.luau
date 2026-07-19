--!strict

local FakeClock = {}

export type FakeClock = {
    now: (self: FakeClock) -> number,
    advance: (self: FakeClock, seconds: number) -> number,
}

local function isFinite(value: number): boolean
    return value == value and value ~= math.huge and value ~= -math.huge
end

function FakeClock.new(initialTime: number?): FakeClock
    local currentTime = initialTime or 0
    assert(isFinite(currentTime), "fake clock initial time must be finite")

    local clock = {} :: FakeClock

    function clock.now(_self: FakeClock): number
        return currentTime
    end

    function clock.advance(_self: FakeClock, seconds: number): number
        assert(isFinite(seconds) and seconds >= 0, "fake clock advance must be a finite non-negative number")
        local nextTime = currentTime + seconds
        assert(isFinite(nextTime), "fake clock time must remain finite")
        currentTime = nextTime
        return currentTime
    end

    return clock
end

return FakeClock
