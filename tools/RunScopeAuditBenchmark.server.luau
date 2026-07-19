--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local benchmark = require(ServerScriptService.Benchmarks.ScopeAuditBenchmark)

local report = benchmark.run()
local disabledOperations = math.floor(report.disabled.operationsPerSecond)
local auditOperations = math.floor(report.audit.operationsPerSecond)
print(
    `Scope audit benchmark: {report.iterations} iterations; disabled {disabledOperations} ops/s; audit {auditOperations} ops/s`
)
