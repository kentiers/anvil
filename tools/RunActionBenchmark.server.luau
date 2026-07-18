--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local benchmark = require(ServerScriptService.Benchmarks.ActionBenchmark)

local report = benchmark.run()
local manualOperations = math.floor(report.manual.operationsPerSecond)
local actionOperations = math.floor(report.action.operationsPerSecond)
print(
    `Action benchmark: {report.iterations} iterations; manual {manualOperations} ops/s; action {actionOperations} ops/s`
)
