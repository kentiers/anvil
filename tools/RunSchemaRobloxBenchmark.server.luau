--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local benchmark = require(ServerScriptService.Benchmarks.SchemaRobloxBenchmark)

local report = benchmark.run()
local manualOperations = math.floor(report.manual.operationsPerSecond)
local schemaOperations = math.floor(report.schema.operationsPerSecond)
print(
    `Schema Roblox benchmark: {report.iterations} iterations; manual {manualOperations} ops/s; schema {schemaOperations} ops/s`
)
