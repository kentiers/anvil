--!strict

local HttpService = game:GetService("HttpService")
local Action = require(script.Parent.Parent.Action.Action)
local Scope = require(script.Parent.Parent.Core.Scope)
local ActionDispatch = require(script.Parent.ActionDispatch)

local Remo = {}

type Event = { Name: string, connect: (self: Event, callback: (player: unknown, rawInput: unknown) -> ()) -> () -> () }

function Remo.bindEvent(remote: Event, action: Action.Action, services: unknown?): Scope.Scope
    local scope = Scope.new(`Remo/{remote.Name}`, remote)
    local disconnect = remote:connect(function(player, rawInput)
        ActionDispatch.run(action, player, rawInput, HttpService:GenerateGUID(false), services)
    end)
    scope.defer(scope, disconnect)
    return scope
end

function Remo.requestHandler(
    action: Action.Action,
    services: unknown?
): (player: unknown, rawInput: unknown) -> ActionDispatch.ClientResult
    return function(player, rawInput)
        return ActionDispatch.serialize(
            action,
            ActionDispatch.run(action, player, rawInput, HttpService:GenerateGUID(false), services)
        )
    end
end

return Remo
