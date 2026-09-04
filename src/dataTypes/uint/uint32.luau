--!strict

local types = require(script.Parent.Parent.Parent.types)

local uint32: types.DataTypeInterface<number> = {
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writeu32(b, cursor, value)
    return 4
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readu32(b, cursor), 4
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 4
  end,

  size = @native function(_value: number): number
    return 4
  end,
}

return function(): types.DataTypeInterface<number>
  return uint32
end
