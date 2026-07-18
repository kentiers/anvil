--!strict

local Error = require(script.Parent.Parent.Core.Error)
local Result = require(script.Parent.Parent.Core.Result)

local Schema = {}

type ResultValue = Result.Result<unknown>
type BaseValidator = (value: unknown, path: string) -> ResultValue
type Check = (value: unknown, path: string) -> ResultValue

export type Validator = {
    parse: (self: Validator, value: unknown, path: string?) -> ResultValue,
    minLength: (self: Validator, minimum: number) -> Validator,
    maxLength: (self: Validator, maximum: number) -> Validator,
    between: (self: Validator, minimum: number, maximum: number) -> Validator,
}

local function invalid(code: string, path: string, expected: string, actual: string): ResultValue
    local details: { [string]: unknown } = {
        expected = expected,
        actual = actual,
    }
    return {
        ok = false,
        error = Error.new(code, nil, path, details),
    }
end

local function constraintFailure(
    code: string,
    path: string,
    value: unknown,
    minimum: number?,
    maximum: number?
): ResultValue
    local details: { [string]: unknown } = {
        value = value,
        minimum = minimum,
        maximum = maximum,
    }
    return {
        ok = false,
        error = Error.new(code, nil, path, details),
    }
end

local function new(base: BaseValidator): Validator
    local checks: { Check } = {}

    local validator = {} :: Validator

    function validator.parse(_self: Validator, value: unknown, path: string?): ResultValue
        local currentPath = path or "$"
        local baseResult = base(value, currentPath)
        if not baseResult.ok then
            return baseResult
        end

        local normalized = baseResult.value
        for _, check in checks do
            local checkResult = check(normalized, currentPath)
            if not checkResult.ok then
                return checkResult
            end
            normalized = checkResult.value
        end

        return Result.ok(normalized)
    end

    function validator.minLength(self: Validator, minimum: number): Validator
        table.insert(checks, function(value: unknown, path: string): ResultValue
            if type(value) ~= "string" then
                return invalid("SCHEMA_INTERNAL_TYPE", path, "string", type(value))
            end
            if #value < minimum then
                return constraintFailure("SCHEMA_STRING_TOO_SHORT", path, value, minimum, nil)
            end
            return Result.ok(value)
        end)
        return self
    end

    function validator.maxLength(self: Validator, maximum: number): Validator
        table.insert(checks, function(value: unknown, path: string): ResultValue
            if type(value) ~= "string" then
                return invalid("SCHEMA_INTERNAL_TYPE", path, "string", type(value))
            end
            if #value > maximum then
                return constraintFailure("SCHEMA_STRING_TOO_LONG", path, value, nil, maximum)
            end
            return Result.ok(value)
        end)
        return self
    end

    function validator.between(self: Validator, minimum: number, maximum: number): Validator
        table.insert(checks, function(value: unknown, path: string): ResultValue
            if type(value) ~= "number" then
                return invalid("SCHEMA_INTERNAL_TYPE", path, "number", type(value))
            end
            if value < minimum or value > maximum then
                return constraintFailure("SCHEMA_NUMBER_OUT_OF_RANGE", path, value, minimum, maximum)
            end
            return Result.ok(value)
        end)
        return self
    end

    return validator
end

function Schema.string(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if type(value) ~= "string" then
            return invalid("SCHEMA_TYPE_MISMATCH", path, "string", type(value))
        end
        return Result.ok(value)
    end)
end

function Schema.number(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if type(value) ~= "number" or value ~= value then
            return invalid("SCHEMA_TYPE_MISMATCH", path, "number", type(value))
        end
        return Result.ok(value)
    end)
end

function Schema.integer(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
            return invalid("SCHEMA_INTEGER_REQUIRED", path, "integer", type(value))
        end
        return Result.ok(value)
    end)
end

function Schema.boolean(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if type(value) ~= "boolean" then
            return invalid("SCHEMA_TYPE_MISMATCH", path, "boolean", type(value))
        end
        return Result.ok(value)
    end)
end

function Schema.optional(inner: Validator): Validator
    return new(function(value: unknown, path: string): ResultValue
        if value == nil then
            return Result.ok(nil)
        end
        return inner:parse(value, path)
    end)
end

function Schema.array(inner: Validator): Validator
    return new(function(value: unknown, path: string): ResultValue
        if type(value) ~= "table" then
            return invalid("SCHEMA_TYPE_MISMATCH", path, "array", type(value))
        end

        local arrayValue = value :: { [number]: unknown }
        local length = #arrayValue
        local normalized = {}
        for key in arrayValue do
            if key % 1 ~= 0 or key < 1 or key > length then
                return invalid("SCHEMA_ARRAY_REQUIRED", path, "array", "sparse table")
            end
        end

        for index = 1, length do
            local itemResult = inner:parse(arrayValue[index], `{path}[{index}]`)
            if not itemResult.ok then
                return itemResult
            end
            table.insert(normalized, itemResult.value)
        end

        return Result.ok(normalized)
    end)
end

function Schema.object(fields: { [string]: Validator }): Validator
    return new(function(value: unknown, path: string): ResultValue
        if type(value) ~= "table" then
            return invalid("SCHEMA_TYPE_MISMATCH", path, "object", type(value))
        end

        local objectValue = value :: { [string]: unknown }
        for key in value :: { [unknown]: unknown } do
            if type(key) ~= "string" or fields[key] == nil then
                return invalid("SCHEMA_UNKNOWN_FIELD", path, "declared field", tostring(key))
            end
        end

        local normalized = {}
        for key, field in fields do
            local fieldResult = field:parse(objectValue[key], `{path}.{key}`)
            if not fieldResult.ok then
                return fieldResult
            end
            normalized[key] = fieldResult.value
        end
        return Result.ok(normalized)
    end)
end

function Schema.union(options: { Validator }): Validator
    return new(function(value: unknown, path: string): ResultValue
        for _, option in options do
            local optionResult = option:parse(value, path)
            if optionResult.ok then
                return optionResult
            end
        end

        return invalid("SCHEMA_UNION_MISMATCH", path, "one of union options", type(value))
    end)
end

return Schema
