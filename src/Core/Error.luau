--!strict

local Error = {}

export type Error = {
    code: string,
    message: string?,
    path: string?,
    details: { [string]: unknown }?,
}

function Error.new(code: string, message: string?, path: string?, details: { [string]: unknown }?): Error
    assert(code ~= "", "error code must not be empty")

    return {
        code = code,
        message = message,
        path = path,
        details = details,
    }
end

return Error
