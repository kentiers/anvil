--!strict

local Result = require(script.Parent.Parent.Core.Result)
local ErrorCode = require(script.Parent.Parent.Core.ErrorCode)

local Cooldown = {}

export type Clock = () -> number

export type Cooldown = {
    check: (self: Cooldown, player: unknown) -> Result.Result<nil>,
    clear: (self: Cooldown, player: unknown) -> (),
}

function Cooldown.new(duration: number, clock: Clock): Cooldown
    assert(duration >= 0, "cooldown duration must not be negative")

    local expiresAt: { [unknown]: number } = {}
    local cooldown = {} :: Cooldown

    function cooldown.check(_self: Cooldown, player: unknown): Result.Result<nil>
        if duration == 0 then
            return Result.ok(nil)
        end

        local now = clock()
        local expires = expiresAt[player]
        if expires ~= nil and now < expires then
            local details: { [string]: unknown } = {
                remaining = expires - now,
            }
            return Result.err(ErrorCode.ACTION_COOLDOWN, details)
        end

        expiresAt[player] = now + duration
        return Result.ok(nil)
    end

    function cooldown.clear(_self: Cooldown, player: unknown)
        expiresAt[player] = nil
    end

    return cooldown
end

return Cooldown
