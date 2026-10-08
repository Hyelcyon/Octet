--!strict

const types = require(script.Parent.Parent.types)

const scratch = buffer.create(8)

const TAG_NIL = 0
const TAG_UINT8 = 1
const TAG_UINT16 = 2
const TAG_UINT24 = 3
const TAG_UINT32 = 4
const TAG_INT8 = 5
const TAG_INT16 = 6
const TAG_INT24 = 7
const TAG_INT32 = 8
const TAG_FLOAT32 = 9
const TAG_FLOAT64 = 10
const TAG_BOOL_FALSE = 11
const TAG_BOOL_TRUE = 12
const TAG_STR8 = 13
const TAG_STR16 = 14
const TAG_VEC2 = 15
const TAG_VEC3 = 16
const TAG_COLOR3 = 17
const TAG_CFRAME = 18
const TAG_REF = 255

type Reader = (b: buffer, cursor: number, references: { unknown }?) -> (unknown, number)
type Skipper = (b: buffer, cursor: number) -> number

const READERS: { [number]: Reader } = table.freeze({
  [TAG_NIL] = @native function(_b: buffer, _cursor: number): (unknown, number)
    return nil, 1
  end,

  [TAG_UINT8] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readu8(b, cursor + 1), 2
  end,

  [TAG_UINT16] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readu16(b, cursor + 1), 3
  end,

  [TAG_UINT24] = @native function(b: buffer, cursor: number): (unknown, number)
    const low = buffer.readu16(b, cursor + 1)
    const high = buffer.readu8(b, cursor + 3)
    return low + high * 65_536, 4
  end,

  [TAG_UINT32] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readu32(b, cursor + 1), 5
  end,

  [TAG_INT8] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readi8(b, cursor + 1), 2
  end,

  [TAG_INT16] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readi16(b, cursor + 1), 3
  end,

  [TAG_INT24] = @native function(b: buffer, cursor: number): (unknown, number)
    const low = buffer.readu16(b, cursor + 1)
    const high = buffer.readi8(b, cursor + 3)
    return low + high * 65_536, 4
  end,

  [TAG_INT32] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readi32(b, cursor + 1), 5
  end,

  [TAG_FLOAT32] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readf32(b, cursor + 1), 5
  end,

  [TAG_FLOAT64] = @native function(b: buffer, cursor: number): (unknown, number)
    return buffer.readf64(b, cursor + 1), 9
  end,

  [TAG_BOOL_FALSE] = @native function(_b: buffer, _cursor: number): (unknown, number)
    return false, 1
  end,

  [TAG_BOOL_TRUE] = @native function(_b: buffer, _cursor: number): (unknown, number)
    return true, 1
  end,

  [TAG_STR8] = @native function(b: buffer, cursor: number): (unknown, number)
    const len = buffer.readu8(b, cursor + 1)
    return buffer.readstring(b, cursor + 2, len), len + 2
  end,

  [TAG_STR16] = @native function(b: buffer, cursor: number): (unknown, number)
    const len = buffer.readu16(b, cursor + 1)
    return buffer.readstring(b, cursor + 3, len), len + 3
  end,

  [TAG_VEC2] = @native function(b: buffer, cursor: number): (unknown, number)
    return Vector2.new(buffer.readf32(b, cursor + 1), buffer.readf32(b, cursor + 5)), 9
  end,

  [TAG_VEC3] = @native function(b: buffer, cursor: number): (unknown, number)
    return Vector3.new(buffer.readf32(b, cursor + 1), buffer.readf32(b, cursor + 5), buffer.readf32(b, cursor + 9)), 13
  end,

  [TAG_COLOR3] = @native function(b: buffer, cursor: number): (unknown, number)
    return Color3.fromRGB(buffer.readu8(b, cursor + 1), buffer.readu8(b, cursor + 2), buffer.readu8(b, cursor + 3)), 4
  end,

  [TAG_CFRAME] = @native function(b: buffer, cursor: number): (unknown, number)
    const x = buffer.readf32(b, cursor + 1)
    const y = buffer.readf32(b, cursor + 5)
    const z = buffer.readf32(b, cursor + 9)
    const rx = buffer.readf32(b, cursor + 13)
    const ry = buffer.readf32(b, cursor + 17)
    const rz = buffer.readf32(b, cursor + 21)
    const axis = Vector3.new(rx, ry, rz)
    const angle = axis.Magnitude
    const cf = if angle ~= 0 then CFrame.new(x, y, z) * CFrame.fromAxisAngle(axis, angle) else CFrame.new(x, y, z)
    return cf, 25
  end,

  [TAG_REF] = @native function(b: buffer, cursor: number, references: { unknown }?): (unknown, number)
    const refId = buffer.readu16(b, cursor + 1)
    if references ~= nil and refId > 0 then
      return references[refId], 3
    end
    return nil, 3
  end,
})

const SKIPPERS: { [number]: Skipper } = table.freeze({
  [TAG_NIL] = @native function(_b: buffer, _cursor: number): number
    return 1
  end,

  [TAG_UINT8] = @native function(_b: buffer, _cursor: number): number
    return 2
  end,

  [TAG_UINT16] = @native function(_b: buffer, _cursor: number): number
    return 3
  end,

  [TAG_UINT24] = @native function(_b: buffer, _cursor: number): number
    return 4
  end,

  [TAG_UINT32] = @native function(_b: buffer, _cursor: number): number
    return 5
  end,

  [TAG_INT8] = @native function(_b: buffer, _cursor: number): number
    return 2
  end,

  [TAG_INT16] = @native function(_b: buffer, _cursor: number): number
    return 3
  end,

  [TAG_INT24] = @native function(_b: buffer, _cursor: number): number
    return 4
  end,

  [TAG_INT32] = @native function(_b: buffer, _cursor: number): number
    return 5
  end,

  [TAG_FLOAT32] = @native function(_b: buffer, _cursor: number): number
    return 5
  end,

  [TAG_FLOAT64] = @native function(_b: buffer, _cursor: number): number
    return 9
  end,

  [TAG_BOOL_FALSE] = @native function(_b: buffer, _cursor: number): number
    return 1
  end,

  [TAG_BOOL_TRUE] = @native function(_b: buffer, _cursor: number): number
    return 1
  end,

  [TAG_STR8] = @native function(b: buffer, cursor: number): number
    return buffer.readu8(b, cursor + 1) + 2
  end,

  [TAG_STR16] = @native function(b: buffer, cursor: number): number
    return buffer.readu16(b, cursor + 1) + 3
  end,

  [TAG_VEC2] = @native function(_b: buffer, _cursor: number): number
    return 9
  end,

  [TAG_VEC3] = @native function(_b: buffer, _cursor: number): number
    return 13
  end,

  [TAG_COLOR3] = @native function(_b: buffer, _cursor: number): number
    return 4
  end,

  [TAG_CFRAME] = @native function(_b: buffer, _cursor: number): number
    return 25
  end,

  [TAG_REF] = @native function(_b: buffer, _cursor: number): number
    return 3
  end,
})

const any: types.DataTypeInterface<unknown> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: unknown, references: { unknown }?): number
    if typeof(value) == "number" then
      if value % 1 == 0 and value >= -2147483648 and value <= 4294967295 then
        if value >= 0 then
          if value <= 255 then
            buffer.writeu8(b, cursor, TAG_UINT8)
            buffer.writeu8(b, cursor + 1, value)
            return 2
          elseif value <= 65535 then
            buffer.writeu8(b, cursor, TAG_UINT16)
            buffer.writeu16(b, cursor + 1, value)
            return 3
          elseif value <= 16777215 then
            buffer.writeu8(b, cursor, TAG_UINT24)
            buffer.writeu16(b, cursor + 1, bit32.band(value, 0xFFFF))
            buffer.writeu8(b, cursor + 3, bit32.rshift(value, 16))
            return 4
          else
            buffer.writeu8(b, cursor, TAG_UINT32)
            buffer.writeu32(b, cursor + 1, value)
            return 5
          end
        else
          if value >= -128 then
            buffer.writeu8(b, cursor, TAG_INT8)
            buffer.writei8(b, cursor + 1, value)
            return 2
          elseif value >= -32768 then
            buffer.writeu8(b, cursor, TAG_INT16)
            buffer.writei16(b, cursor + 1, value)
            return 3
          elseif value >= -8388608 then
            buffer.writeu8(b, cursor, TAG_INT24)
            buffer.writeu16(b, cursor + 1, bit32.band(value, 0xFFFF))
            buffer.writei8(b, cursor + 3, bit32.arshift(value, 16))
            return 4
          else
            buffer.writeu8(b, cursor, TAG_INT32)
            buffer.writei32(b, cursor + 1, value)
            return 5
          end
        end
      else
        buffer.writef32(scratch, 0, value)
        if buffer.readf32(scratch, 0) == value then
          buffer.writeu8(b, cursor, TAG_FLOAT32)
          buffer.writef32(b, cursor + 1, value)
          return 5
        else
          buffer.writeu8(b, cursor, TAG_FLOAT64)
          buffer.writef64(b, cursor + 1, value)
          return 9
        end
      end
    elseif typeof(value) == "boolean" then
      buffer.writeu8(b, cursor, if value then TAG_BOOL_TRUE else TAG_BOOL_FALSE)
      return 1
    elseif typeof(value) == "string" then
      const len = #value
      if len <= 255 then
        buffer.writeu8(b, cursor, TAG_STR8)
        buffer.writeu8(b, cursor + 1, len)
        buffer.writestring(b, cursor + 2, value, len)
        return len + 2
      else
        buffer.writeu8(b, cursor, TAG_STR16)
        buffer.writeu16(b, cursor + 1, len)
        buffer.writestring(b, cursor + 3, value, len)
        return len + 3
      end
    elseif typeof(value) == "Vector3" then
      buffer.writeu8(b, cursor, TAG_VEC3)
      buffer.writef32(b, cursor + 1, value.X)
      buffer.writef32(b, cursor + 5, value.Y)
      buffer.writef32(b, cursor + 9, value.Z)
      return 13
    elseif typeof(value) == "Vector2" then
      buffer.writeu8(b, cursor, TAG_VEC2)
      buffer.writef32(b, cursor + 1, value.X)
      buffer.writef32(b, cursor + 5, value.Y)
      return 9
    elseif typeof(value) == "Color3" then
      buffer.writeu8(b, cursor, TAG_COLOR3)
      buffer.writeu8(b, cursor + 1, math.round(value.R * 255))
      buffer.writeu8(b, cursor + 2, math.round(value.G * 255))
      buffer.writeu8(b, cursor + 3, math.round(value.B * 255))
      return 4
    elseif typeof(value) == "CFrame" then
      const x, y, z = value.X, value.Y, value.Z
      local axis, angle = value:ToAxisAngle()
      axis *= angle
      buffer.writeu8(b, cursor, TAG_CFRAME)
      buffer.writef32(b, cursor + 1, x)
      buffer.writef32(b, cursor + 5, y)
      buffer.writef32(b, cursor + 9, z)
      buffer.writef32(b, cursor + 13, axis.X)
      buffer.writef32(b, cursor + 17, axis.Y)
      buffer.writef32(b, cursor + 21, axis.Z)
      return 25
    elseif value == nil then
      buffer.writeu8(b, cursor, TAG_NIL)
      return 1
    else
      buffer.writeu8(b, cursor, TAG_REF)
      if references ~= nil then
        table.insert(references, value)
        buffer.writeu16(b, cursor + 1, #references)
      else
        buffer.writeu16(b, cursor + 1, 0)
      end
      return 3
    end
  end,

  read = @native function(b: buffer, cursor: number, references: { unknown }?): (unknown, number)
    const tag = buffer.readu8(b, cursor)
    const reader = READERS[tag]
    if reader ~= nil then
      return reader(b, cursor, references)
    end
    return nil, 1
  end,

  skip = @native function(b: buffer, cursor: number): number
    const tag = buffer.readu8(b, cursor)
    const skipper = SKIPPERS[tag]
    if skipper ~= nil then
      return skipper(b, cursor)
    end
    return 1
  end,

  size = @native function(value: unknown): number
    if typeof(value) == "number" then
      return 9
    elseif typeof(value) == "boolean" then
      return 1
    elseif typeof(value) == "string" then
      const len = #value
      return if len <= 255 then len + 2 else len + 3
    elseif typeof(value) == "Vector2" then
      return 9
    elseif typeof(value) == "Vector3" then
      return 13
    elseif typeof(value) == "Color3" then
      return 4
    elseif typeof(value) == "CFrame" then
      return 25
    elseif value == nil then
      return 1
    else
      return 3
    end
  end,
})

return function(): types.DataTypeInterface<unknown>
  return any
end
