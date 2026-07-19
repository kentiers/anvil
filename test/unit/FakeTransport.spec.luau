--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local AnvilModule = ServerScriptService.Anvil
local Anvil = require(AnvilModule)
local Action = Anvil.Action
local ErrorCode = Anvil.ErrorCode
local Result = Anvil.Result
local RobloxRemote = require(AnvilModule.Transport.RobloxRemote)
local Schema = Anvil.Schema
local FakeTransport = Anvil.Test.FakeTransport

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("FakeTransport", function()
        it("binds deterministic event and function remotes", function()
            local fakeTransport = FakeTransport.new()
            local transport = RobloxRemote.new()
            local action = Action.new("Test.FakeTransport", {
                input = Schema.object({
                    Count = Schema.integer(),
                }),
                output = Schema.string(),
                execute = function()
                    return Result.ok("accepted")
                end,
            })
            local player = {}

            local event = fakeTransport:event("Execute")
            local eventBinding = transport:bindEvent(event :: any, action, {})
            event:fireServer(player, { Count = "not-an-integer" })

            assert(#event.clientMessages == 1, "event request must produce one client response")
            local eventPayload = event.clientMessages[1].payload :: any
            assert(not eventPayload.ok, "invalid event input must fail")
            assert(
                eventPayload.error.code == ErrorCode.SCHEMA_INTEGER_REQUIRED,
                "event must serialize stable error code"
            )
            assert(eventPayload.error.details == nil, "event must not expose server error details")

            eventBinding:destroy()
            event:fireServer(player, { Count = 1 })
            assert(#event.clientMessages == 1, "destroyed event binding must disconnect")

            local functionRemote = fakeTransport:functionRemote("Execute")
            local functionBinding = transport:bindFunction(functionRemote :: any, action, {})
            local functionPayload = functionRemote:invokeServer(player, { Count = 1 }) :: any
            assert(functionPayload.ok and functionPayload.value == "accepted", "function must return validated output")

            functionBinding:destroy()
            local didInvoke = pcall(function()
                functionRemote:invokeServer(player, { Count = 1 })
            end)
            assert(not didInvoke, "destroyed function binding must clear server handler")
        end)
    end)
end
