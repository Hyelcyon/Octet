--!strict

const types = require(script.types)

export type DataTypeInterface<T> = types.DataTypeInterface<T>
export type Connection = types.Connection
export type EventProps<T> = types.EventProps<T>
export type Event<T> = types.Event<T>
export type ProcedureProps<Req, Res> = types.ProcedureProps<Req, Res>
export type Procedure<Req, Res> = types.Procedure<Req, Res>
export type DefinedEvent<T> = types.DefinedEvent<T>
export type DefinedProcedure<Req, Res> = types.DefinedProcedure<Req, Res>
export type Octet = types.Octet

const server = require(script.server)
const client = require(script.client)

const event = require(script.events)
const procedure = require(script.procedures)
const contract = require(script.contracts.contract)

const int8 = require(script.dataTypes.int.int8)
const int16 = require(script.dataTypes.int.int16)
const int24 = require(script.dataTypes.int.int24)
const int32 = require(script.dataTypes.int.int32)

const uint8 = require(script.dataTypes.uint.uint8)
const uint16 = require(script.dataTypes.uint.uint16)
const uint24 = require(script.dataTypes.uint.uint24)
const uint32 = require(script.dataTypes.uint.uint32)

const float32 = require(script.dataTypes.float.float32)
const float48 = require(script.dataTypes.float.float48)
const float64 = require(script.dataTypes.float.float64)

const bool = require(script.dataTypes.bool)
const str = require(script.dataTypes.str)
const buff = require(script.dataTypes.buff)
const null = require(script.dataTypes.null)
const any = require(script.dataTypes.any)

const vec2 = require(script.dataTypes.vec.vec2)
const vec3 = require(script.dataTypes.vec.vec3)
const color2 = require(script.dataTypes.color.color2)
const color3 = require(script.dataTypes.color.color3)
const cframe = require(script.dataTypes.cframe)

const optional = require(script.dataTypes.optional)
const array = require(script.dataTypes.array)
const map = require(script.dataTypes.map)
const struct = require(script.dataTypes.struct)

const RunService = game:GetService("RunService")

if RunService:IsServer() then
  server:start()
else
  client:start()
end

const dts: types.Octet = table.freeze({
  event = event,
  procedure = procedure,
  contract = contract,

  int8 = int8(),
  int16 = int16(),
  int24 = int24(),
  int32 = int32(),

  uint8 = uint8(),
  uint16 = uint16(),
  uint24 = uint24(),
  uint32 = uint32(),

  float32 = float32(),
  float48 = float48(),
  float64 = float64(),

  bool = bool(),
  str = str(),
  buff = buff(),
  null = null(),
  any = any(),

  vec2 = vec2(),
  vec3 = vec3(),
  color2 = color2(),
  color3 = color3(),
  cframe = cframe(),

  optional = optional,
  array = array,
  map = map,
  struct = struct,
})

return dts
