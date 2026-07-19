--!strict

local Scope = require(script.Parent.Parent.Core.Scope)

local Replica = {}

type Replica = { Destroy: (self: Replica) -> () }

function Replica.own(scope: Scope.Scope, replica: Replica): Replica
    scope:own(replica, function(resource)
        (resource :: Replica):Destroy()
    end)
    return replica
end

return Replica
