--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = require(ServerScriptService.Packages.Anvil)

local executed = false
local action = Anvil.Action.new("ConsumerSmoke", {
    input = Anvil.Schema.object({
        Count = Anvil.Schema.integer():between(1, 10),
        Target = Anvil.Schema.instance({
            classNames = { "Terrain" },
            ancestor = workspace,
        }),
    }),
    output = Anvil.Schema.object({ Accepted = Anvil.Schema.boolean() }),
    execute = function(context)
        executed = true
        assert((context.input :: { Count: number }).Count == 1, "normalized input must reach execute")
        return Anvil.Result.ok({ Accepted = true })
    end,
})

local scope = Anvil.Scope.new("ConsumerSmoke")
local valid = action:run({
    player = "consumer",
    rawInput = {
        Count = 1,
        Target = workspace.Terrain,
    },
    requestId = "consumer-smoke-valid",
    scope = scope,
    services = {},
})
assert(valid.ok and executed, "valid consumer Action request must execute")

executed = false
local invalid = action:run({
    player = "consumer",
    rawInput = {
        Count = 0,
        Target = workspace.Terrain,
    },
    requestId = "consumer-smoke-invalid",
    scope = scope,
    services = {},
})
assert(not invalid.ok and not executed, "invalid consumer Action request must not execute")
scope:destroy()

print("Anvil consumer smoke: passed")
