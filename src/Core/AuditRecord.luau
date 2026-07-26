--!strict

local AuditRecord = {}

export type AuditRecord = {
    action: string,
    requestId: string,
    player: unknown,
    result: "ok" | "error",
    transaction: "committed" | "rolled_back" | "none",
}

function AuditRecord.new(
    action: string,
    requestId: string,
    player: unknown,
    result: "ok" | "error",
    transaction: "committed" | "rolled_back" | "none"
): AuditRecord
    return table.freeze({
        action = action,
        requestId = requestId,
        player = player,
        result = result,
        transaction = transaction,
    })
end

return AuditRecord
