--!strict

local Result = require(script.Parent.Core.Result)
local Error = require(script.Parent.Core.Error)
local Schema = require(script.Parent.Schema.Schema)
local Scope = require(script.Parent.Core.Scope)

return {
    Error = Error,
    Result = Result,
    Schema = Schema,
    Scope = Scope,
}
