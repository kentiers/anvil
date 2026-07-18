--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = ServerScriptService.Anvil
local Action = require(Anvil.Action.Action)
local Result = require(Anvil.Core.Result)
local Schema = require(Anvil.Schema.Schema)
local Scope = require(Anvil.Core.Scope)
local Cooldown = require(Anvil.Action.Cooldown)
local RateLimit = require(Anvil.Action.RateLimit)
local RobloxRemote = require(Anvil.Transport.RobloxRemote)

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("Action", function()
        it("validates input before execution", function()
            local executions = 0
            local action = Action.new("Test.Execute", {
                input = Schema.object({
                    Count = Schema.integer():between(1, 10),
                }),
                execute = function(context)
                    executions += 1
                    local input = context.input :: { [string]: unknown }
                    assert(input.Count == 2, "executor must receive normalized input")
                    assert(context.requestId == "request-1", "executor must receive request ID")
                    return Result.ok("executed")
                end,
            })

            local scope = Scope.new("ActionTest")
            local validResult = action:run({
                player = {},
                rawInput = { Count = 2 },
                requestId = "request-1",
                scope = scope,
                services = {},
            })
            assert(validResult.ok and validResult.value == "executed", "valid input must execute")
            assert(executions == 1, "valid input must execute once")

            local invalidResult = action:run({
                player = {},
                rawInput = { Count = "2" },
                requestId = "request-2",
                scope = scope,
                services = {},
            })
            assert(not invalidResult.ok, "invalid input must fail")
            assert(executions == 1, "invalid input must not execute")
            if not invalidResult.ok then
                assert(invalidResult.error.code == "SCHEMA_INTEGER_REQUIRED", "schema error must be preserved")
            end

            scope:destroy()
        end)

        it("runs rate limit before cooldown", function()
            local now = 0
            local executions = 0
            local action = Action.new("Test.Guards", {
                input = Schema.object({}),
                cooldown = Cooldown.new(5, function()
                    return now
                end),
                rateLimit = RateLimit.new(1, 1, function()
                    return now
                end),
                execute = function()
                    executions += 1
                    return Result.ok(nil)
                end,
            })
            local scope = Scope.new("ActionGuards")
            local request = {
                player = {},
                rawInput = {},
                requestId = "request-1",
                scope = scope,
                services = {},
            }

            assert(action:run(request).ok, "first request must execute")

            local rateLimited = action:run(request)
            assert(not rateLimited.ok, "second request must be rate limited")
            if not rateLimited.ok then
                assert(rateLimited.error.code == "ACTION_RATE_LIMITED", "rate limit must run before cooldown")
            end

            now = 1
            local coolingDown = action:run(request)
            assert(not coolingDown.ok, "request inside cooldown must fail")
            if not coolingDown.ok then
                assert(coolingDown.error.code == "ACTION_COOLDOWN", "cooldown must run after rate limit")
            end
            assert(executions == 1, "blocked requests must not execute")
            scope:destroy()
        end)

        it("rejects unauthorized input before execution", function()
            local executions = 0
            local action = Action.new("Test.Authorization", {
                input = Schema.object({}),
                authorize = function()
                    return Result.err("ACTION_UNAUTHORIZED")
                end,
                execute = function()
                    executions += 1
                    return Result.ok(nil)
                end,
            })
            local scope = Scope.new("ActionAuthorization")

            local result = action:run({
                player = {},
                rawInput = {},
                requestId = "request-1",
                scope = scope,
                services = {},
            })
            assert(not result.ok, "unauthorized request must fail")
            if not result.ok then
                assert(result.error.code == "ACTION_UNAUTHORIZED", "authorization error must be preserved")
            end
            assert(executions == 0, "unauthorized request must not execute")
            scope:destroy()
        end)

        it("dispatches through a request scope", function()
            local capturedScope: Scope.Scope? = nil
            local action = Action.new("Test.Transport", {
                input = Schema.object({
                    Count = Schema.integer(),
                }),
                output = Schema.string(),
                execute = function(context)
                    capturedScope = context.scope
                    return Result.ok("accepted")
                end,
            })
            local player = {}
            local transport = RobloxRemote.new()

            local result = transport:dispatch(action, player, { Count = 1 }, "request-1", {})
            assert(result.ok and result.value == "accepted", "transport must return Action result")
            assert(capturedScope ~= nil and capturedScope.destroyed, "transport must destroy request scope")
        end)

        it("validates execution output when declared", function()
            local action = Action.new("Test.Output", {
                input = Schema.object({}),
                output = Schema.integer(),
                execute = function()
                    return Result.ok("not-an-integer")
                end,
            })
            local scope = Scope.new("ActionOutput")

            local result = action:run({
                player = {},
                rawInput = {},
                requestId = "request-1",
                scope = scope,
                services = {},
            })
            assert(not result.ok, "invalid declared output must fail")
            if not result.ok then
                assert(result.error.code == "SCHEMA_INTEGER_REQUIRED", "output schema error must be preserved")
            end
            scope:destroy()
        end)
    end)
end
