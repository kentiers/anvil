--!strict

local Result = require(script.Parent.Parent.Core.Result)

local Transaction = {}

type Cleanup = () -> ()

export type Transaction = {
    status: "active" | "committed" | "rolled_back",
    set: (self: Transaction, target: { [any]: any }, key: any, value: any) -> Result.Result<nil>,
    delete: (self: Transaction, target: { [any]: any }, key: any) -> Result.Result<nil>,
    compensate: (self: Transaction, callback: Cleanup) -> Result.Result<nil>,
    commit: (self: Transaction) -> Result.Result<nil>,
    rollback: (self: Transaction) -> Result.Result<nil>,
    destroy: (self: Transaction) -> (),
}

local function closed(transaction: Transaction): Result.Result<nil>?
    if transaction.status == "active" then
        return nil
    end
    local details: { [string]: unknown } = { status = transaction.status }
    return Result.err("TRANSACTION_CLOSED", details)
end

function Transaction.new(): Transaction
    local undo: { Cleanup } = {}
    local compensations: { Cleanup } = {}
    local transaction = { status = "active" } :: Transaction

    function transaction.set(self, target, key, value)
        local failure = closed(self)
        if failure ~= nil then
            return failure
        end
        local existed = target[key] ~= nil
        local previous = target[key]
        table.insert(undo, function()
            if existed then
                target[key] = previous
            else
                target[key] = nil
            end
        end)
        target[key] = value
        return Result.ok(nil)
    end

    function transaction.delete(self, target, key)
        return self:set(target, key, nil)
    end

    function transaction.compensate(self, callback)
        local failure = closed(self)
        if failure ~= nil then
            return failure
        end
        table.insert(compensations, callback)
        return Result.ok(nil)
    end

    function transaction.commit(self)
        local failure = closed(self)
        if failure ~= nil then
            return failure
        end
        self.status = "committed"
        table.clear(undo)
        table.clear(compensations)
        return Result.ok(nil)
    end

    function transaction.rollback(self)
        local failure = closed(self)
        if failure ~= nil then
            return failure
        end
        self.status = "rolled_back"
        local failed = false
        for index = #compensations, 1, -1 do
            if not pcall(compensations[index]) then
                failed = true
            end
        end
        for index = #undo, 1, -1 do
            if not pcall(undo[index]) then
                failed = true
            end
        end
        table.clear(undo)
        table.clear(compensations)
        if failed then
            local details: { [string]: unknown } = { reason = "cleanup callback failed" }
            return Result.err("TRANSACTION_ROLLBACK_FAILED", details)
        end
        return Result.ok(nil)
    end

    function transaction.destroy(self)
        if self.status == "active" then
            self:rollback()
        end
    end

    return transaction
end

return Transaction
