--!strict

local FakeSignal = {}

type Callback = (...unknown) -> ()
type Listener = {
    callback: Callback,
}

export type Connection = {
    Disconnect: (self: Connection) -> (),
}

export type Signal = {
    Connect: (self: Signal, callback: Callback) -> Connection,
    fire: (self: Signal, ...unknown) -> (),
}

function FakeSignal.new(): Signal
    local listeners: { [number]: Listener } = {}
    local nextListenerId = 0
    local signal = {} :: Signal

    function signal.Connect(_self: Signal, callback: Callback): Connection
        nextListenerId += 1
        local listenerId = nextListenerId
        listeners[listenerId] = {
            callback = callback,
        }

        local connection = {} :: Connection
        function connection.Disconnect(_connection: Connection)
            listeners[listenerId] = nil
        end
        return connection
    end

    function signal.fire(_self: Signal, ...: unknown)
        for _, listener in listeners do
            listener.callback(...)
        end
    end

    return signal
end

return FakeSignal
