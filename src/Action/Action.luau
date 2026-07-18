--!strict

local Result = require(script.Parent.Parent.Core.Result)
local Schema = require(script.Parent.Parent.Schema.Schema)
local Scope = require(script.Parent.Parent.Core.Scope)
local Cooldown = require(script.Parent.Cooldown)
local RateLimit = require(script.Parent.RateLimit)

local Action = {}

export type ExecutionContext = {
    player: unknown,
    input: unknown,
    requestId: string,
    scope: Scope.Scope,
    services: unknown,
}

export type RequestContext = {
    player: unknown,
    rawInput: unknown,
    requestId: string,
    scope: Scope.Scope,
    services: unknown,
}

export type Config = {
    input: Schema.Validator,
    output: Schema.Validator?,
    execute: (context: ExecutionContext) -> Result.Result<unknown>,
    cooldown: Cooldown.Cooldown?,
    rateLimit: RateLimit.RateLimit?,
    authorize: ((context: ExecutionContext) -> Result.Result<nil>)?,
}

export type Action = {
    name: string,
    hasOutput: boolean,
    run: (self: Action, context: RequestContext) -> Result.Result<unknown>,
}

function Action.new(name: string, config: Config): Action
    assert(name ~= "", "action name must not be empty")

    local action = {
        name = name,
        hasOutput = config.output ~= nil,
    } :: Action

    function action.run(_self: Action, context: RequestContext): Result.Result<unknown>
        local inputResult = config.input:parse(context.rawInput)
        if not inputResult.ok then
            return inputResult
        end

        if config.rateLimit ~= nil then
            local rateLimitResult = config.rateLimit:check(context.player)
            if not rateLimitResult.ok then
                return rateLimitResult
            end
        end

        if config.cooldown ~= nil then
            local cooldownResult = config.cooldown:check(context.player)
            if not cooldownResult.ok then
                return cooldownResult
            end
        end

        local executionContext = {
            player = context.player,
            input = inputResult.value,
            requestId = context.requestId,
            scope = context.scope,
            services = context.services,
        }

        if config.authorize ~= nil then
            local authorizationResult = config.authorize(executionContext)
            if not authorizationResult.ok then
                return authorizationResult
            end
        end

        local executionResult = config.execute(executionContext)
        if not executionResult.ok or config.output == nil then
            return executionResult
        end

        return config.output:parse(executionResult.value)
    end

    return action
end

return Action
