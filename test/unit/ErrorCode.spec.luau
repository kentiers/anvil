--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = require(ServerScriptService.Anvil)
local ErrorCode = Anvil.ErrorCode

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it

    describe("ErrorCode", function()
        it("publishes stable emitted error codes", function()
            local expected = {
                ACTION_COOLDOWN = "ACTION_COOLDOWN",
                ACTION_RATE_LIMITED = "ACTION_RATE_LIMITED",
                SCHEMA_ARRAY_REQUIRED = "SCHEMA_ARRAY_REQUIRED",
                SCHEMA_CFRAME_REQUIRED = "SCHEMA_CFRAME_REQUIRED",
                SCHEMA_COLOR3_REQUIRED = "SCHEMA_COLOR3_REQUIRED",
                SCHEMA_ENUM_ITEM_REQUIRED = "SCHEMA_ENUM_ITEM_REQUIRED",
                SCHEMA_INSTANCE_ANCESTRY = "SCHEMA_INSTANCE_ANCESTRY",
                SCHEMA_INSTANCE_CLASS = "SCHEMA_INSTANCE_CLASS",
                SCHEMA_INSTANCE_REQUIRED = "SCHEMA_INSTANCE_REQUIRED",
                SCHEMA_INTEGER_REQUIRED = "SCHEMA_INTEGER_REQUIRED",
                SCHEMA_INTERNAL_TYPE = "SCHEMA_INTERNAL_TYPE",
                SCHEMA_NUMBER_OUT_OF_RANGE = "SCHEMA_NUMBER_OUT_OF_RANGE",
                SCHEMA_STRING_TOO_LONG = "SCHEMA_STRING_TOO_LONG",
                SCHEMA_STRING_TOO_SHORT = "SCHEMA_STRING_TOO_SHORT",
                SCHEMA_TYPE_MISMATCH = "SCHEMA_TYPE_MISMATCH",
                SCHEMA_UNION_MISMATCH = "SCHEMA_UNION_MISMATCH",
                SCHEMA_UNKNOWN_FIELD = "SCHEMA_UNKNOWN_FIELD",
                SCHEMA_VECTOR3_REQUIRED = "SCHEMA_VECTOR3_REQUIRED",
            }
            local values = ErrorCode :: any

            for name, value in expected do
                assert(values[name] == value, `{name} must preserve its wire value`)
            end
        end)
    end)
end
