--!strict

local ReplayRecord = {}

export type ReplayRecord = {
    action: string,
    requestId: string,
    input: unknown,
    result: unknown,
    clock: number,
    random: { number },
}

function ReplayRecord.new(
    action: string,
    requestId: string,
    input: unknown,
    result: unknown,
    clock: number,
    random: { number }
): ReplayRecord
    assert(clock == clock and clock ~= math.huge and clock ~= -math.huge, "replay clock must be finite")
    return table.freeze({
        action = action,
        requestId = requestId,
        input = input,
        result = result,
        clock = clock,
        random = table.clone(random),
    })
end

return ReplayRecord
