--!strict

local types = require(script.Parent.types)
local procedure = require(script.procedure)

local autoProcedureId = 0

local function defineProcedure<Req, Res>(props: types.ProcedureProps<Req, Res>): types.DefinedProcedure<Req, Res>
  autoProcedureId += 1
  local defaultId = autoProcedureId
  local instantiated: types.Procedure<Req, Res>? = nil

  local function getInstance(): types.Procedure<Req, Res>
    if instantiated == nil then
      instantiated = procedure(props, defaultId)
    end
    return instantiated :: types.Procedure<Req, Res>
  end

  local definition: types.DefinedProcedure<Req, Res> = {
    build = function(id: number): types.Procedure<Req, Res>
      return procedure(props, id)
    end,
    call = @native function(_self: types.Procedure<Req, Res>, request: Req): Res?
      return getInstance():call(request)
    end,
    handle = function(_self: types.Procedure<Req, Res>, callback: (request: Req, player: Player) -> Res): () -> ()
      return getInstance():handle(callback)
    end,
  }

  return definition
end

return defineProcedure
