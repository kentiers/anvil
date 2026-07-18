--!strict

local Error = require(script.Parent.Parent.Core.Error)
local Result = require(script.Parent.Parent.Core.Result)

local Schema = {}
local TYPE_VECTOR3 = "Vector3"
local TYPE_CFRAME = "CFrame"
local TYPE_COLOR3 = "Color3"
local TYPE_ENUM = "Enum"
local TYPE_ENUM_ITEM = "EnumItem"
local TYPE_INSTANCE = "Instance"

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

export type InstancePolicy = {
    classNames: { string },
    ancestor: unknown,
}

local function isFinite(value: number): boolean
    return value == value and value ~= math.huge and value ~= -math.huge
end

local function isAllowedClass(instance: any, classNames: { string }): boolean
    for _, className in classNames do
        if instance:IsA(className) then
            return true
        end
    end
    return false
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
        if type(value) ~= "number" or not isFinite(value) then
            return invalid("SCHEMA_TYPE_MISMATCH", path, "number", type(value))
        end
        return Result.ok(value)
    end)
end

function Schema.integer(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if type(value) ~= "number" or not isFinite(value) or value % 1 ~= 0 then
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

function Schema.vector3(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if typeof(value) ~= TYPE_VECTOR3 then
            return invalid("SCHEMA_VECTOR3_REQUIRED", path, "Vector3", typeof(value))
        end

        local vector = value :: any
        if not isFinite(vector.X) or not isFinite(vector.Y) or not isFinite(vector.Z) then
            return invalid("SCHEMA_VECTOR3_REQUIRED", path, "finite Vector3", "non-finite Vector3")
        end
        return Result.ok(value)
    end)
end

function Schema.cframe(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if typeof(value) ~= TYPE_CFRAME then
            return invalid("SCHEMA_CFRAME_REQUIRED", path, "CFrame", typeof(value))
        end

        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = (value :: any):GetComponents()
        if
            not (
                isFinite(x)
                and isFinite(y)
                and isFinite(z)
                and isFinite(r00)
                and isFinite(r01)
                and isFinite(r02)
                and isFinite(r10)
                and isFinite(r11)
                and isFinite(r12)
                and isFinite(r20)
                and isFinite(r21)
                and isFinite(r22)
            )
        then
            return invalid("SCHEMA_CFRAME_REQUIRED", path, "finite CFrame", "non-finite CFrame")
        end
        return Result.ok(value)
    end)
end

function Schema.color3(): Validator
    return new(function(value: unknown, path: string): ResultValue
        if typeof(value) ~= TYPE_COLOR3 then
            return invalid("SCHEMA_COLOR3_REQUIRED", path, "Color3", typeof(value))
        end

        local color = value :: any
        if not isFinite(color.R) or not isFinite(color.G) or not isFinite(color.B) then
            return invalid("SCHEMA_COLOR3_REQUIRED", path, "finite Color3", "non-finite Color3")
        end
        return Result.ok(value)
    end)
end

function Schema.enumItem(enumType: unknown?): Validator
    if enumType ~= nil then
        assert(typeof(enumType) == TYPE_ENUM, "enum type must be an Enum")
    end

    return new(function(value: unknown, path: string): ResultValue
        if typeof(value) ~= TYPE_ENUM_ITEM then
            return invalid("SCHEMA_ENUM_ITEM_REQUIRED", path, "EnumItem", typeof(value))
        end

        local item = value :: any
        if enumType ~= nil and item.EnumType ~= enumType then
            return invalid("SCHEMA_ENUM_ITEM_REQUIRED", path, "configured Enum", tostring(item.EnumType))
        end
        return Result.ok(value)
    end)
end

function Schema.instance(policy: InstancePolicy): Validator
    assert(#policy.classNames > 0, "instance policy must allow at least one class")
    for _, className in policy.classNames do
        assert(type(className) == "string" and #className > 0, "instance policy class names must be non-empty strings")
    end
    assert(typeof(policy.ancestor) == TYPE_INSTANCE, "instance policy ancestor must be an Instance")

    return new(function(value: unknown, path: string): ResultValue
        if typeof(value) ~= TYPE_INSTANCE then
            return invalid("SCHEMA_INSTANCE_REQUIRED", path, "Instance", typeof(value))
        end

        local instance = value :: any
        local ancestor = policy.ancestor :: any
        if not isAllowedClass(instance, policy.classNames) then
            return invalid("SCHEMA_INSTANCE_CLASS", path, "allowed Instance class", instance.ClassName)
        end
        if instance ~= ancestor and not instance:IsDescendantOf(ancestor) then
            return invalid("SCHEMA_INSTANCE_ANCESTRY", path, "allowed Instance ancestry", "outside configured ancestry")
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
