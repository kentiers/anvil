--!strict

local FakeClock = require(script.FakeClock)
local FakePlayer = require(script.FakePlayer)
local FakeSignal = require(script.FakeSignal)
local FakeTransport = require(script.FakeTransport)
local FakeRng = require(script.FakeRng)

return {
    FakeClock = FakeClock,
    FakePlayer = FakePlayer,
    FakeSignal = FakeSignal,
    FakeTransport = FakeTransport,
    FakeRng = FakeRng,
}
