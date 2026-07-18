--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Anvil = ReplicatedStorage.Anvil
local Error = require(Anvil.Core.Error)
local Result = require(Anvil.Core.Result)

return function()
    local value: Result.Result<number> = Result.ok(42)
    assert(Result.isOk(value), "Ok result must report isOk")
    assert(not Result.isErr(value), "Ok result must not report isErr")
    assert(Result.unwrap(value) == 42, "unwrap must return Ok value")
    assert(Result.unwrapOr(value, 0) == 42, "unwrapOr must prefer Ok value")

    local details: { [string]: unknown } = { path = "quantity" }
    local failure: Result.Result<number> = Result.err("INVALID_INPUT", details)
    assert(Result.isErr(failure), "Err result must report isErr")
    assert(not Result.isOk(failure), "Err result must not report isOk")
    assert(Result.unwrapOr(failure, 7) == 7, "unwrapOr must return fallback")
    if failure.ok then
        error("expected Err result")
    end
    assert(failure.error.code == "INVALID_INPUT", "Err must preserve error code")
    assert(failure.error.details ~= nil and failure.error.details.path == "quantity", "Err must preserve error details")

    local mapped = Result.map(value, function(number: number)
        return number * 2
    end)
    assert(Result.unwrap(mapped) == 84, "map must transform Ok value")

    local mappedError = Result.mapErr(failure, function()
        return Error.new("NORMALIZED")
    end)
    if mappedError.ok then
        error("expected mapped Err result")
    end
    assert(mappedError.error.code == "NORMALIZED", "mapErr must transform error")

    local chained = Result.andThen(value, function(number: number)
        return Result.ok(number + 1)
    end)
    assert(Result.unwrap(chained) == 43, "andThen must run on Ok value")

    local skipped = Result.andThen(failure, function()
        error("andThen must not run on Err")
    end)
    assert(Result.isErr(skipped), "andThen must preserve Err")

    local didThrow = pcall(function()
        Result.unwrap(failure)
    end)
    assert(not didThrow, "unwrap must throw for Err")
end
