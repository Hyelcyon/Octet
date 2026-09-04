--!strict

local types = require(script.Parent.Parent.Parent.types)

local INV_31 = 1 / 31
local INV_63 = 1 / 63

local color2: types.DataTypeInterface<Color3> = {
  write = @native function(b: buffer, cursor: number, value: Color3, _references: { unknown }?): number
    local r = math.round(value.R * 31)
    local g = math.round(value.G * 63)
    local bVal = math.round(value.B * 31)
    local packed = bit32.bor(bit32.lshift(r, 11), bit32.lshift(g, 5), bVal)

    buffer.writeu16(b, cursor, packed)
    return 2
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (Color3, number)
    local packed = buffer.readu16(b, cursor)
    local r = bit32.rshift(packed, 11) * INV_31
    local g = bit32.band(bit32.rshift(packed, 5), 0x3F) * INV_63
    local bVal = bit32.band(packed, 0x1F) * INV_31

    return Color3.new(r, g, bVal), 2
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 2
  end,

  size = @native function(_value: Color3): number
    return 2
  end,
}

return function(): types.DataTypeInterface<Color3>
  return color2
end
