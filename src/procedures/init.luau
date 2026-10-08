--!strict

const types = require(script.Parent.types)
const procedure = require(script.procedure)

local autoProcedureId = 0

const function defineProcedure<Req, Res>(props: types.ProcedureProps<Req, Res>): types.DefinedProcedure<Req, Res>
  autoProcedureId += 1
  const defaultId = autoProcedureId
  local instantiated: types.Procedure<Req, Res>? = nil

  const function getInstance(): types.Procedure<Req, Res>
    local instance = instantiated
    if instance ~= nil then
      return instance
    end
    instance = procedure(props, defaultId)
    instantiated = instance
    return instance
  end

  const definition: types.DefinedProcedure<Req, Res> = table.freeze({
    build = function(id: number): types.Procedure<Req, Res>
      return procedure(props, id)
    end,
    call = @native function(_self: types.Procedure<Req, Res>, request: Req): Res?
      return getInstance():call(request)
    end,
    handle = function(_self: types.Procedure<Req, Res>, callback: (request: Req, player: Player) -> Res): () -> ()
      return getInstance():handle(callback)
    end,
  })

  return definition
end

return defineProcedure
