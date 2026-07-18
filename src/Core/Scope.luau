--!strict

local Scope = {}

type Cleanup = () -> ()
type ResourceCleanup = (resource: unknown) -> ()

export type Scope = {
    name: string,
    owner: unknown,
    destroyed: boolean,
    child: (self: Scope, name: string, owner: unknown?) -> Scope,
    defer: (self: Scope, cleanup: Cleanup) -> Cleanup,
    own: (self: Scope, resource: unknown, cleanup: ResourceCleanup) -> unknown,
    connect: (self: Scope, connection: unknown, disconnect: ResourceCleanup) -> unknown,
    destroy: (self: Scope) -> (),
}

type InternalScope = Scope & {
    cleanups: { Cleanup },
    children: { Scope },
}

local function assertActive(scope: Scope)
    if scope.destroyed then
        error(`cannot use destroyed scope: {scope.name}`)
    end
end

function Scope.new(name: string, owner: unknown?): Scope
    local scope = {
        name = name,
        owner = owner,
        destroyed = false,
        cleanups = {} :: { Cleanup },
        children = {} :: { Scope },
    } :: InternalScope

    local publicScope = scope :: Scope

    function publicScope.child(self: Scope, childName: string, childOwner: unknown?): Scope
        assertActive(self)
        local childScope = Scope.new(`{self.name}/{childName}`, childOwner)
        table.insert((self :: InternalScope).children, childScope)
        return childScope
    end

    function publicScope.defer(self: Scope, cleanup: Cleanup): Cleanup
        assertActive(self)
        table.insert((self :: InternalScope).cleanups, cleanup)
        return cleanup
    end

    function publicScope.own(self: Scope, resource: unknown, cleanup: ResourceCleanup): unknown
        assertActive(self)
        self:defer(function()
            cleanup(resource)
        end)
        return resource
    end

    function publicScope.connect(self: Scope, connection: unknown, disconnect: ResourceCleanup): unknown
        return self:own(connection, disconnect)
    end

    function publicScope.destroy(self: Scope)
        if self.destroyed then
            return
        end
        self.destroyed = true
        local internal = self :: InternalScope

        local firstFailure: any = nil
        local function runCleanup(cleanup: Cleanup)
            local ok, failure = pcall(function()
                cleanup()
                return true
            end)
            if not ok and firstFailure == nil then
                firstFailure = failure
            end
        end

        for index = #internal.children, 1, -1 do
            runCleanup(function()
                internal.children[index]:destroy()
            end)
        end

        for index = #internal.cleanups, 1, -1 do
            runCleanup(internal.cleanups[index])
        end

        table.clear(internal.children)
        table.clear(internal.cleanups)

        if firstFailure ~= nil then
            error(firstFailure, 0)
        end
    end

    return publicScope
end

return Scope
