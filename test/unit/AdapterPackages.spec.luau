--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    local environment = getfenv()
    local describe: (string, () -> ()) -> () = environment.describe
    local it: (string, () -> ()) -> () = environment.it

    describe("Adapter packages", function()
        it("loads every pinned optional package without making it a core dependency", function()
            local packages = ReplicatedStorage.DevPackages
            local byteNet = require(packages.ByteNet)
            local remo = require(packages.Remo)
            local profileStore = require(packages.ProfileStore)
            local scribe = require(packages.Scribe)
            local trove = require(packages.Trove)

            assert(type(byteNet.defineNamespace) == "function", "pinned ByteNet package must expose defineNamespace")
            assert(type(remo.remote) == "function", "pinned Remo package must expose remote")
            assert(type(profileStore) == "table", "pinned ProfileStore package must load")
            assert(type(scribe) == "table", "pinned Scribe package must load")
            assert(type(trove.new) == "function", "pinned Trove package must expose new")
        end)
    end)
end
