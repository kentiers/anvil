--!strict

local FakeClock = require(script.FakeClock)
local FakePlayer = require(script.FakePlayer)
local FakeSignal = require(script.FakeSignal)

return {
    FakeClock = FakeClock,
    FakePlayer = FakePlayer,
    FakeSignal = FakeSignal,
}
