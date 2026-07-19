--!strict

local FakeSignal = require(script.Parent.FakeSignal)

local FakeTransport = {}

export type ClientMessage = {
    player: unknown,
    payload: unknown,
}

export type Event = {
    Name: string,
    OnServerEvent: FakeSignal.Signal,
    clientMessages: { ClientMessage },
    FireClient: (self: Event, player: unknown, payload: unknown) -> (),
    fireServer: (self: Event, player: unknown, rawInput: unknown) -> (),
}

export type Function = {
    Name: string,
    OnServerInvoke: ((player: unknown, rawInput: unknown) -> unknown)?,
    invokeServer: (self: Function, player: unknown, rawInput: unknown) -> unknown,
}

export type FakeTransport = {
    event: (self: FakeTransport, name: string) -> Event,
    functionRemote: (self: FakeTransport, name: string) -> Function,
}

function FakeTransport.new(): FakeTransport
    local transport = {} :: FakeTransport

    function transport.event(_self: FakeTransport, name: string): Event
        assert(name ~= "", "fake event name must not be empty")

        local serverEvent = FakeSignal.new()
        local remote = {
            Name = name,
            OnServerEvent = serverEvent,
            clientMessages = {} :: { ClientMessage },
        } :: Event

        function remote.FireClient(self: Event, player: unknown, payload: unknown)
            table.insert(self.clientMessages, {
                player = player,
                payload = payload,
            })
        end

        function remote.fireServer(_self: Event, player: unknown, rawInput: unknown)
            serverEvent:fire(player, rawInput)
        end

        return remote
    end

    function transport.functionRemote(_self: FakeTransport, name: string): Function
        assert(name ~= "", "fake function name must not be empty")

        local remote = {
            Name = name,
            OnServerInvoke = nil,
        } :: Function

        function remote.invokeServer(self: Function, player: unknown, rawInput: unknown): unknown
            assert(self.OnServerInvoke ~= nil, "fake function must be bound before invocation")
            return self.OnServerInvoke(player, rawInput)
        end

        return remote
    end

    return transport
end

return FakeTransport
