--!strict

local Action = require(script.Parent.Parent.Action.Action)
local Result = require(script.Parent.Parent.Core.Result)
local Scope = require(script.Parent.Parent.Core.Scope)

local ActionDispatch = {}

export type ClientResult = { ok: true, value: unknown? } | { ok: false, error: { code: string } }

function ActionDispatch.run(
    action: Action.Action,
    player: unknown,
    rawInput: unknown,
    requestId: string,
    services: unknown?
): Result.Result<unknown>
    local requestScope = Scope.new(`Action/{action.name}`, player)
    local ran, resultOrFailure = pcall(function()
        return action:run({
            player = player,
            rawInput = rawInput,
            requestId = requestId,
            scope = requestScope,
            services = services,
        })
    end)
    local cleaned, cleanupFailure = pcall(function()
        requestScope:destroy()
    end)
    if not cleaned then
        error(cleanupFailure, 0)
    end
    if not ran then
        error(resultOrFailure, 0)
    end
    return resultOrFailure :: Result.Result<unknown>
end

function ActionDispatch.serialize(action: Action.Action, result: Result.Result<unknown>): ClientResult
    if not result.ok then
        return { ok = false, error = { code = result.error.code } }
    end
    if action.hasOutput then
        return { ok = true, value = result.value }
    end
    return { ok = true }
end

return ActionDispatch
