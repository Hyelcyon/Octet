--!strict

local types = require(script.Parent.Parent.Parent.types)

local color3: types.DataTypeInterface<Color3> = {
  write = @native function(b: buffer, cursor: number, value: Color3, _references: { unknown }?): number
    buffer.writeu8(b, cursor, math.round(value.R * 255))
    buffer.writeu8(b, cursor + 1, math.round(value.G * 255))
    buffer.writeu8(b, cursor + 2, math.round(value.B * 255))
    return 3
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (Color3, number)
    return Color3.fromRGB(buffer.readu8(b, cursor), buffer.readu8(b, cursor + 1), buffer.readu8(b, cursor + 2)), 3
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 3
  end,

  size = @native function(_value: Color3): number
    return 3
  end,
}

return function(): types.DataTypeInterface<Color3>
  return color3
end
