--!strict

local RunService = game:GetService("RunService")

local types = require(script.Parent.Parent.types)
local server = require(script.Parent.Parent.server)
local client = require(script.Parent.Parent.client)

local isServer = RunService:IsServer()

local function createProcedure<Req, Res>(props: types.ProcedureProps<Req, Res>, id: number): types.Procedure<Req, Res>
  local requestCodec = props.request
  local responseCodec = props.response

  local procedure: types.Procedure<Req, Res>
  procedure = {
    call = @native function(_self: types.Procedure<Req, Res>, request: Req): Res?
      if isServer then
        error("Cannot call procedure on the server.")
      end
      return client:callProcedure(id, requestCodec, responseCodec, request)
    end,

    handle = function(_self: types.Procedure<Req, Res>, callback: (request: Req, player: Player) -> Res): () -> ()
      if not isServer then
        error("Cannot handle procedure on the client.")
      end
      server:registerProcedure(id, requestCodec, responseCodec, callback)
      return function()
        server:unregisterProcedure(id)
      end
    end,
  }

  return procedure
end

return createProcedure
