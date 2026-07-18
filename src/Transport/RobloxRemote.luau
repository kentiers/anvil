--!strict

local HttpService = game:GetService("HttpService")

local Action = require(script.Parent.Parent.Action.Action)
local Result = require(script.Parent.Parent.Core.Result)
local Scope = require(script.Parent.Parent.Core.Scope)

local RobloxRemote = {}

export type ClientResult = { ok: true, value: unknown? } | { ok: false, error: { code: string } }

type Connection = {
    Disconnect: (self: Connection) -> (),
}

type ServerEvent = {
    Connect: (self: ServerEvent, callback: (player: unknown, rawInput: unknown) -> ()) -> Connection,
}

type RemoteEvent = {
    Name: string,
    OnServerEvent: ServerEvent,
    FireClient: (self: RemoteEvent, player: unknown, payload: unknown) -> (),
}

type ServerInvoke = (player: unknown, rawInput: unknown) -> ClientResult

type RemoteFunction = {
    Name: string,
    OnServerInvoke: ServerInvoke?,
}

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

local function serialize(action: Action.Action, result: Result.Result<unknown>): ClientResult
    if not result.ok then
        return {
            ok = false,
            error = {
                code = result.error.code,
            },
        }
    end

    if action.hasOutput then
        return {
            ok = true,
            value = result.value,
        }
    end

    return { ok = true }
end

function RobloxRemote.new(): RobloxRemote
    local transport = {} :: RobloxRemote

    function transport.dispatch(
        _self: RobloxRemote,
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

    function transport.bindEvent(
        self: RobloxRemote,
        remote: RemoteEvent,
        action: Action.Action,
        services: unknown?
    ): Scope.Scope
        local scope = Scope.new(`RemoteEvent/{remote.Name}`, remote)
        local connection = remote.OnServerEvent:Connect(function(player: unknown, rawInput: unknown)
            local result = self:dispatch(action, player, rawInput, HttpService:GenerateGUID(false), services)
            remote:FireClient(player, serialize(action, result))
        end)
        scope:connect(connection, function(resource: unknown)
            (resource :: Connection):Disconnect()
        end)
        return scope
    end

    function transport.bindFunction(
        self: RobloxRemote,
        remote: RemoteFunction,
        action: Action.Action,
        services: unknown?
    ): Scope.Scope
        local scope = Scope.new(`RemoteFunction/{remote.Name}`, remote)
        local handler = function(player: unknown, rawInput: unknown): ClientResult
            local result = self:dispatch(action, player, rawInput, HttpService:GenerateGUID(false), services)
            return serialize(action, result)
        end
        remote.OnServerInvoke = handler
        scope:defer(function()
            if remote.OnServerInvoke == handler then
                remote.OnServerInvoke = nil
            end
        end)
        return scope
    end

    function transport.send(_self: RobloxRemote, remote: RemoteEvent, player: unknown, payload: unknown)
        remote:FireClient(player, payload)
    end

    return transport
end

return RobloxRemote
