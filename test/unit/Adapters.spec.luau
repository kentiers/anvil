--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = require(ServerScriptService.Anvil)

local Action = Anvil.Action
local ErrorCode = Anvil.ErrorCode
local Result = Anvil.Result
local Schema = Anvil.Schema
local Scope = Anvil.Scope

return function()
    local environment = getfenv()
    local describe: (string, () -> ()) -> () = environment.describe
    local it: (string, () -> ()) -> () = environment.it

    describe("Adapters", function()
        it("keeps Action validation and safe response serialization across transport adapters", function()
            local executed = 0
            local action = Action.new("Adapter.Test", {
                input = Schema.object({ Count = Schema.integer() }),
                output = Schema.integer(),
                execute = function(context)
                    executed += 1
                    return Result.ok((context.input :: { Count: number }).Count)
                end,
            })
            local response = { payload = nil :: any, player = nil :: any }
            function response.sendTo(payload, player)
                response.payload = payload
                response.player = player
            end
            local handler = Anvil.Adapters.ByteNet.eventHandler(action, {}, response)
            local player = {}
            handler({ Count = "bad" }, player)
            assert(
                not response.payload.ok and response.payload.error.code == ErrorCode.SCHEMA_INTEGER_REQUIRED,
                "ByteNet handler must preserve schema boundary"
            )
            assert(executed == 0, "invalid ByteNet input must not execute")

            local request = Anvil.Adapters.Remo.requestHandler(action, {})
            local payload = request(player, { Count = 3 })
            assert(payload.ok and payload.value == 3, "Remo request handler must serialize validated output")
            assert(executed == 1, "valid Remo input must execute once")
        end)

        it("owns external resource lifecycles explicitly", function()
            local scope = Scope.new("Adapters")
            local replicaDestroyed = 0
            local sessionEnded = 0
            local troveDestroyed = 0
            Anvil.Adapters.Replica.own(scope, {
                Destroy = function()
                    replicaDestroyed += 1
                end,
            })
            Anvil.Adapters.ProfileStore.ownSession(scope, {
                EndSession = function()
                    sessionEnded += 1
                end,
            })
            Anvil.Adapters.Trove.own(scope, {
                Destroy = function()
                    troveDestroyed += 1
                end,
            })
            scope:destroy()
            assert(
                replicaDestroyed == 1 and sessionEnded == 1 and troveDestroyed == 1,
                "scope must release each owned adapter resource once"
            )
        end)

        it("disconnects scoped Remo event bindings", function()
            local callback: ((unknown, unknown) -> ())? = nil
            local disconnected = 0
            local remote = { Name = "AdapterEvent" }
            function remote:connect(listener)
                callback = listener
                return function()
                    disconnected += 1
                end
            end
            local action = Action.new("Adapter.Event", {
                input = Schema.object({}),
                execute = function()
                    return Result.ok(nil)
                end,
            })
            local binding = Anvil.Adapters.Remo.bindEvent(remote, action, {})
            assert(callback ~= nil, "Remo adapter must register listener")
            binding:destroy()
            assert(disconnected == 1, "scope must disconnect Remo listener")
        end)

        it("returns ready Scribe data", function()
            local ready = { Coins = 10 }
            local result = Anvil.Adapters.Scribe.waitForData({
                WaitForData = function()
                    return ready, nil
                end,
            }, {})
            assert(result.ok and result.value == ready, "ready Scribe data must remain available")
        end)

        it("maps unavailable Scribe data to a stable adapter error", function()
            local failed = Anvil.Adapters.Scribe.waitForData({
                WaitForData = function()
                    return nil, "load-failed"
                end,
            }, {})
            assert(not failed.ok, "unavailable Scribe data must fail")
            if not failed.ok then
                assert(
                    failed.error.code == ErrorCode.ADAPTER_SCRIBE_DATA_UNAVAILABLE,
                    "Scribe failure code must be stable"
                )
            end
        end)
    end)
end
