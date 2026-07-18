--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Anvil = ReplicatedStorage.Anvil
local Scope = require(Anvil.Core.Scope)

return function()
    local testEnvironment = getfenv()
    local describe: (name: string, callback: () -> ()) -> () = testEnvironment.describe
    local it: (name: string, callback: () -> ()) -> () = testEnvironment.it
    describe("Scope", function()
        it("destroys owned resources deterministically", function()
            local events = {}
            local root = Scope.new("Root")

            root:defer(function()
                table.insert(events, "root-defer")
            end)

            local connection = {}
            root:connect(connection, function(resource)
                assert(resource == connection, "connect must pass owned resource")
                table.insert(events, "disconnect")
            end)

            local resource = {}
            root:own(resource, function(value)
                assert(value == resource, "own must pass owned resource")
                table.insert(events, "resource")
            end)

            local child = root:child("Child")
            child:defer(function()
                table.insert(events, "child-defer")
            end)

            root:destroy()
            assert(root.destroyed, "destroy must mark root destroyed")
            assert(child.destroyed, "destroy must destroy children")
            assert(events[1] == "child-defer", "children must destroy before parent resources")
            assert(events[2] == "resource", "resources must clean in reverse registration order")
            assert(events[3] == "disconnect", "connections must clean in reverse registration order")
            assert(events[4] == "root-defer", "deferred cleanup must run")

            root:destroy()
            assert(#events == 4, "destroy must be idempotent")

            local didRejectRegistration = pcall(function()
                root:defer(function() end)
            end)
            assert(not didRejectRegistration, "destroyed scope must reject new resources")
        end)

        it("drains cleanup after a failure", function()
            local failureEvents = {}
            local failingScope = Scope.new("Failing")
            failingScope:defer(function()
                table.insert(failureEvents, "after-failure")
            end)
            failingScope:defer(function()
                table.insert(failureEvents, "failure")
                error("cleanup failed")
            end)

            local didThrow = pcall(function()
                failingScope:destroy()
            end)
            assert(not didThrow, "destroy must rethrow cleanup failure")
            assert(failingScope.destroyed, "failing scope must still be destroyed")
            assert(failureEvents[1] == "failure", "cleanup order must remain reverse registration")
            assert(failureEvents[2] == "after-failure", "cleanup after failure must still run")
        end)
    end)
end
