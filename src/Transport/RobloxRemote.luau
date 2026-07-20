--!strict

local HttpService = game:GetService("HttpService")

local Action = require(script.Parent.Parent.Action.Action)
local Result = require(script.Parent.Parent.Core.Result)
local Scope = require(script.Parent.Parent.Core.Scope)
local ActionDispatch = require(script.Parent.Parent.Adapters.ActionDispatch)

local RobloxRemote = {}

export type ClientResult = ActionDispatch.ClientResult

type Connection = { Disconnect: (self: Connection) -> () }
type ServerEvent = { Connect: (self: ServerEvent, callback: (player: unknown, rawInput: unknown) -> ()) -> Connection }
type RemoteEvent = {
    Name: string,
    OnServerEvent: ServerEvent,
    FireClient: (self: RemoteEvent, player: unknown, payload: unknown) -> (),
}
type ServerInvoke = (player: unknown, rawInput: unknown) -> ClientResult
type RemoteFunction = { Name: string, OnServerInvoke: ServerInvoke? }

export type RobloxRemote = {
    bindEvent: (self: RobloxRemote, remote: RemoteEvent, action: Action.Action, services: unknown?) -> Scope.Scope,
    bindFunction: (
        self: RobloxRemote,
        remote: RemoteFunction,
        action: Action.Action,
        services: unknown?
    ) -> Scope.Scope,
    dispatch: (
        self: RobloxRemote,
        action: Action.Action,
        player: unknown,
        rawInput: unknown,
        requestId: string,
        services: unknown?
    ) -> Result.Result<unknown>,
    send: (self: RobloxRemote, remote: RemoteEvent, player: unknown, payload: unknown) -> (),
}

function RobloxRemote.new(): RobloxRemote
    local transport = {} :: RobloxRemote

    function transport.dispatch(_self, action, player, rawInput, requestId, services)
        return ActionDispatch.run(action, player, rawInput, requestId, services)
    end

    function transport.bindEvent(self, remote, action, services)
        local scope = Scope.new(`RemoteEvent/{remote.Name}`, remote)
        local connection = remote.OnServerEvent:Connect(function(player, rawInput)
            local result = self:dispatch(action, player, rawInput, HttpService:GenerateGUID(false), services)
            remote:FireClient(player, ActionDispatch.serialize(action, result))
        end)
        scope:connect(connection, function(resource)
            (resource :: Connection):Disconnect()
        end)
        return scope
    end

    function transport.bindFunction(self, remote, action, services)
        local scope = Scope.new(`RemoteFunction/{remote.Name}`, remote)
        local handler = function(player, rawInput): ClientResult
            return ActionDispatch.serialize(
                action,
                self:dispatch(action, player, rawInput, HttpService:GenerateGUID(false), services)
            )
        end
        remote.OnServerInvoke = handler
        scope:defer(function()
            if remote.OnServerInvoke == handler then
                remote.OnServerInvoke = nil
            end
        end)
        return scope
    end

    function transport.send(_self, remote, player, payload)
        remote:FireClient(player, payload)
    end

    return transport
end

return RobloxRemote
