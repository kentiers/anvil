--!strict

local Result = require(script.Parent.Parent.Core.Result)
local ErrorCode = require(script.Parent.Parent.Core.ErrorCode)

local RateLimit = {}

export type Clock = () -> number

export type RateLimit = {
    check: (self: RateLimit, player: unknown) -> Result.Result<nil>,
    clear: (self: RateLimit, player: unknown) -> (),
}

type Bucket = {
    tokens: number,
    updatedAt: number,
}

function RateLimit.new(capacity: number, refillPerSecond: number, clock: Clock): RateLimit
    assert(capacity > 0, "rate limit capacity must be positive")
    assert(refillPerSecond > 0, "rate limit refill rate must be positive")

    local buckets: { [unknown]: Bucket } = {}
    local rateLimit = {} :: RateLimit

    function rateLimit.check(_self: RateLimit, player: unknown): Result.Result<nil>
        local now = clock()
        local bucket = buckets[player]
        if bucket == nil then
            bucket = {
                tokens = capacity,
                updatedAt = now,
            }
            buckets[player] = bucket
        else
            local elapsed = now - bucket.updatedAt
            if elapsed > 0 then
                bucket.tokens = math.min(capacity, bucket.tokens + elapsed * refillPerSecond)
                bucket.updatedAt = now
            end
        end

        if bucket.tokens < 1 then
            local details: { [string]: unknown } = {
                retryAfter = (1 - bucket.tokens) / refillPerSecond,
            }
            return Result.err(ErrorCode.ACTION_RATE_LIMITED, details)
        end

        bucket.tokens -= 1
        return Result.ok(nil)
    end

    function rateLimit.clear(_self: RateLimit, player: unknown)
        buckets[player] = nil
    end

    return rateLimit
end

return RateLimit
