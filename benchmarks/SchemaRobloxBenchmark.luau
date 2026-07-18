--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Anvil = ServerScriptService.Anvil
local Schema = require(Anvil.Schema.Schema)

local SchemaRobloxBenchmark = {}

local ITERATIONS = 10_000

type Measurement = {
    seconds: number,
    operationsPerSecond: number,
}

export type Report = {
    iterations: number,
    manual: Measurement,
    schema: Measurement,
}
local TYPE_VECTOR3 = "Vector3"
local TYPE_CFRAME = "CFrame"
local TYPE_COLOR3 = "Color3"
local TYPE_ENUM_ITEM = "EnumItem"

local function measure(callback: () -> ()): Measurement
    local startedAt = os.clock()
    for _ = 1, ITERATIONS do
        callback()
    end
    local seconds = os.clock() - startedAt
    return {
        seconds = seconds,
        operationsPerSecond = ITERATIONS / seconds,
    }
end

function SchemaRobloxBenchmark.run(): Report
    local workspace = game:GetService("Workspace")
    local lighting = game:GetService("Lighting")
    local terrain = workspace.Terrain
    local payload = {
        Vector = lighting:GetSunDirection(),
        Frame = workspace:GetPivot(),
        Color = lighting.Ambient,
        Material = terrain.Material,
        Terrain = terrain,
    }
    local schema = Schema.object({
        Vector = Schema.vector3(),
        Frame = Schema.cframe(),
        Color = Schema.color3(),
        Material = Schema.enumItem(payload.Material.EnumType),
        Terrain = Schema.instance({
            classNames = { "Terrain" },
            ancestor = workspace,
        }),
    })

    local manual = measure(function()
        assert(typeof(payload.Vector) == TYPE_VECTOR3, "manual Vector3 check must pass")
        assert(typeof(payload.Frame) == TYPE_CFRAME, "manual CFrame check must pass")
        assert(typeof(payload.Color) == TYPE_COLOR3, "manual Color3 check must pass")
        assert(typeof(payload.Material) == TYPE_ENUM_ITEM, "manual EnumItem check must pass")
        assert(payload.Terrain:IsA("Terrain"), "manual Instance class check must pass")
        assert(payload.Terrain:IsDescendantOf(workspace), "manual Instance ancestry check must pass")
    end)
    local schemaMeasurement = measure(function()
        local result = schema:parse(payload)
        assert(result.ok, "Roblox schema benchmark payload must parse")
    end)

    return {
        iterations = ITERATIONS,
        manual = manual,
        schema = schemaMeasurement,
    }
end

return SchemaRobloxBenchmark
