--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

local results = TestEZ.TestBootstrap:run({ ServerScriptService.Tests }, TestEZ.Reporters.TextReporter)
if results.failureCount > 0 then
    error(`TestEZ failed: {results.failureCount} failing test(s)`, 0)
end
