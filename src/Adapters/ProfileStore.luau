--!strict

local Scope = require(script.Parent.Parent.Core.Scope)

local ProfileStore = {}

type Session = { EndSession: (self: Session) -> () }

function ProfileStore.ownSession(scope: Scope.Scope, session: Session): Session
    scope:own(session, function(resource)
        (resource :: Session):EndSession()
    end)
    return session
end

return ProfileStore
