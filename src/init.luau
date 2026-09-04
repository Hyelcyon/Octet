--!strict

local types = require(script.types)

local server = require(script.server)
local client = require(script.client)

local event = require(script.events)
local procedure = require(script.procedures)
local contract = require(script.contracts.contract)

local int8 = require(script.dataTypes.int.int8)
local int16 = require(script.dataTypes.int.int16)
local int24 = require(script.dataTypes.int.int24)
local int32 = require(script.dataTypes.int.int32)

local uint8 = require(script.dataTypes.uint.uint8)
local uint16 = require(script.dataTypes.uint.uint16)
local uint24 = require(script.dataTypes.uint.uint24)
local uint32 = require(script.dataTypes.uint.uint32)

local float32 = require(script.dataTypes.float.float32)
local float48 = require(script.dataTypes.float.float48)
local float64 = require(script.dataTypes.float.float64)

local bool = require(script.dataTypes.bool)
local str = require(script.dataTypes.str)
local buff = require(script.dataTypes.buff)
local null = require(script.dataTypes.null)
local any = require(script.dataTypes.any)

local vec2 = require(script.dataTypes.vec.vec2)
local vec3 = require(script.dataTypes.vec.vec3)
local color2 = require(script.dataTypes.color.color2)
local color3 = require(script.dataTypes.color.color3)
local cframe = require(script.dataTypes.cframe)

local optional = require(script.dataTypes.optional)
local array = require(script.dataTypes.array)
local map = require(script.dataTypes.map)
local struct = require(script.dataTypes.struct)

local RunService = game:GetService("RunService")

if RunService:IsServer() then
  server:start()
else
  client:start()
end

local dts = {
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
}

return (table.freeze(dts)) :: types.Octet
