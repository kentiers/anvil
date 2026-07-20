--!strict

local HttpService = game:GetService("HttpService")
local Action = require(script.Parent.Parent.Action.Action)
local ActionDispatch = require(script.Parent.ActionDispatch)

local ByteNet = {}

type ResponsePacket = { sendTo: (payload: ActionDispatch.ClientResult, player: unknown) -> () }

function ByteNet.eventHandler(
    action: Action.Action,
    services: unknown?,
    response: ResponsePacket?
): (rawInput: unknown, player: unknown) -> ()
    return function(rawInput: unknown, player: unknown)
        local result = ActionDispatch.run(action, player, rawInput, HttpService:GenerateGUID(false), services)
        if response ~= nil then
            response.sendTo(ActionDispatch.serialize(action, result), player)
        end
    end
end

return ByteNet
