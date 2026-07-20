--!strict

local Scope = require(script.Parent.Parent.Core.Scope)

local Trove = {}

type Trove = { Destroy: (self: Trove) -> () }

function Trove.own(scope: Scope.Scope, trove: Trove): Trove
    scope:own(trove, function(resource)
        (resource :: Trove):Destroy()
    end)
    return trove
end

return Trove
