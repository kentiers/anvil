--!strict

local HttpService = game:GetService("HttpService")

local RequestId = {}

export type RequestId = {
    next: (self: RequestId) -> string,
}

function RequestId.new(generator: (() -> string)?): RequestId
    local nextId: () -> string = if generator ~= nil
        then generator
        else function()
            return HttpService:GenerateGUID(false)
        end
    return {
        next = function()
            return nextId()
        end,
    }
end

return RequestId
