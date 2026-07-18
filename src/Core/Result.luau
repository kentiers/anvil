--!strict

local ErrorModule = require(script.Parent.Error)

local Result = {}

export type Error = ErrorModule.Error
export type Result<T> = { ok: true, value: T } | { ok: false, error: Error }

function Result.ok<T>(value: T): Result<T>
    return {
        ok = true,
        value = value,
    }
end

function Result.err<T>(error: Error): Result<T>
    return {
        ok = false,
        error = error,
    }
end

function Result.isOk<T>(result: Result<T>): boolean
    return result.ok
end

function Result.isErr<T>(result: Result<T>): boolean
    return not result.ok
end

function Result.unwrap<T>(result: Result<T>): T
    if not result.ok then
        error(`cannot unwrap error result: ${result.error.code}`)
    end

    return result.value
end

function Result.unwrapOr<T>(result: Result<T>, fallback: T): T
    if result.ok then
        return result.value
    end

    return fallback
end

return Result
