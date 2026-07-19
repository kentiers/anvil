--!strict

local ErrorCode = require(script.Parent.Parent.Core.ErrorCode)
local Result = require(script.Parent.Parent.Core.Result)

local Scribe = {}

type Data = { WaitForData: (player: unknown) -> (unknown?, string?) }

function Scribe.waitForData(data: Data, player: unknown): Result.Result<unknown>
    local accessor, reason = data.WaitForData(player)
    if accessor == nil then
        local details: { [string]: unknown } = { reason = tostring(reason) }
        return Result.err(ErrorCode.ADAPTER_SCRIBE_DATA_UNAVAILABLE, details)
    end
    return Result.ok(accessor)
end

return Scribe
