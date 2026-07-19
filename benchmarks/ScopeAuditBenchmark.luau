--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Scope = require(ServerScriptService.Anvil.Core.Scope)

local ScopeAuditBenchmark = {}

local ITERATIONS = 10_000

type Measurement = {
    seconds: number,
    operationsPerSecond: number,
}

export type Report = {
    iterations: number,
    audit: Measurement,
    disabled: Measurement,
}

local function measure(callback: () -> ()): Measurement
    local startedAt = os.clock()
    for _ = 1, ITERATIONS do
        callback()
    end
    local seconds = os.clock() - startedAt
    return {
        seconds = seconds,
        operationsPerSecond = ITERATIONS / seconds,
    }
end

function ScopeAuditBenchmark.run(): Report
    local disabled = measure(function()
        local scope = Scope.new("Benchmark")
        scope:destroy()
    end)

    local auditEvents = 0
    local audit = function()
        auditEvents += 1
    end
    local auditOptions = {
        audit = audit,
    }
    local enabled = measure(function()
        local scope = Scope.new("Benchmark", nil, auditOptions)
        scope:destroy()
    end)
    assert(auditEvents == ITERATIONS, "enabled audit must emit one destruction event per Scope")

    return {
        iterations = ITERATIONS,
        audit = enabled,
        disabled = disabled,
    }
end

return ScopeAuditBenchmark
