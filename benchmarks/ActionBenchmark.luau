--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = ServerScriptService.Anvil
local Action = require(Anvil.Action.Action)
local Result = require(Anvil.Core.Result)
local Schema = require(Anvil.Schema.Schema)
local Scope = require(Anvil.Core.Scope)

local ActionBenchmark = {}

local ITERATIONS = 10_000

type Measurement = {
    seconds: number,
    operationsPerSecond: number,
}

export type Report = {
    iterations: number,
    manual: Measurement,
    action: Measurement,
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

function ActionBenchmark.run(): Report
    local input = Schema.object({
        Count = Schema.integer():between(1, 10),
    })
    local action = Action.new("Benchmark.Execute", {
        input = input,
        execute = function()
            return Result.ok(nil)
        end,
    })

    local manual = measure(function()
        local result = input:parse({ Count = 1 })
        assert(result.ok, "manual baseline input must parse")
    end)
    local actionMeasurement = measure(function()
        local scope = Scope.new("Benchmark")
        local result = action:run({
            player = {},
            rawInput = { Count = 1 },
            requestId = "benchmark",
            scope = scope,
            services = {},
        })
        scope:destroy()
        assert(result.ok, "Action benchmark input must execute")
    end)

    return {
        iterations = ITERATIONS,
        manual = manual,
        action = actionMeasurement,
    }
end

return ActionBenchmark
