--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Anvil = ReplicatedStorage.Anvil
local Schema = require(Anvil.Schema.Schema)

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it
    describe("Schema", function()
        it("validates and normalizes structured input", function()
            local actionInput = Schema.object({
                Name = Schema.string():minLength(1):maxLength(64),
                Count = Schema.integer():between(1, 99),
                Note = Schema.optional(Schema.string()),
            })

            local valid = actionInput:parse({
                Name = "item-001",
                Count = 2,
            })
            assert(valid.ok, "valid object must parse")
            if valid.ok then
                local parsed = valid.value :: { [string]: unknown }
                assert(parsed["Name"] == "item-001", "object parser must preserve fields")
                assert(parsed["Count"] == 2, "object parser must preserve numbers")
            end

            local invalidType = actionInput:parse({
                Name = "item-001",
                Count = "2",
            })
            assert(not invalidType.ok, "wrong field type must fail")
            if not invalidType.ok then
                assert(invalidType.error.code == "SCHEMA_INTEGER_REQUIRED", "type error code must be stable")
                assert(invalidType.error.path == "$.Count", "type error must include field path")
            end

            local unknownField = actionInput:parse({
                Name = "item-001",
                Count = 2,
                Extra = true,
            })
            assert(not unknownField.ok, "unknown fields must fail closed")
            if not unknownField.ok then
                assert(unknownField.error.code == "SCHEMA_UNKNOWN_FIELD", "unknown field code must be stable")
            end

            local tooShort = Schema.string():minLength(3):parse("no")
            assert(not tooShort.ok, "minimum length must be enforced")
            if not tooShort.ok then
                assert(tooShort.error.code == "SCHEMA_STRING_TOO_SHORT", "minimum length error must be stable")
                assert(tooShort.error.path == "$", "root error must have root path")
            end

            local array = Schema.array(Schema.integer():between(1, 5))
            local invalidArray = array:parse({ 1, 6 })
            assert(not invalidArray.ok, "invalid array item must fail")
            if not invalidArray.ok then
                assert(invalidArray.error.path == "$[2]", "array error must include index path")
            end

            local optional = Schema.optional(Schema.string())
            local omitted = optional:parse(nil)
            assert(omitted.ok, "optional schema must accept nil")

            local union = Schema.union({ Schema.string(), Schema.integer() })
            assert(union:parse("text").ok, "union must accept first option")
            assert(union:parse(3).ok, "union must accept later option")
            assert(not union:parse(true).ok, "union must reject unmatched values")
        end)
    end)
end
