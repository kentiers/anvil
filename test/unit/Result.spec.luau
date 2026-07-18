--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Anvil = ReplicatedStorage.Anvil
local Error = require(Anvil.Core.Error)
local Result = require(Anvil.Core.Result)

return function()
    local value = Result.ok(42)
    assert(Result.isOk(value), "Ok result must report isOk")
    assert(not Result.isErr(value), "Ok result must not report isErr")
    assert(Result.unwrap(value) == 42, "unwrap must return Ok value")
    assert(Result.unwrapOr(value, 0) == 42, "unwrapOr must prefer Ok value")

    local failure = Result.err(Error.new("INVALID_INPUT", "input is invalid", "quantity"))
    assert(Result.isErr(failure), "Err result must report isErr")
    assert(not Result.isOk(failure), "Err result must not report isOk")
    assert(Result.unwrapOr(failure, 7) == 7, "unwrapOr must return fallback")
    if failure.ok then
        error("expected Err result")
    end
    assert(failure.error.code == "INVALID_INPUT", "Err must preserve error code")
    assert(failure.error.path == "quantity", "Err must preserve error path")

    local didThrow = pcall(function()
        Result.unwrap(failure)
    end)
    assert(not didThrow, "unwrap must throw for Err")
end
