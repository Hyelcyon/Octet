--!strict

local types = require(script.Parent.Parent.Parent.types)

local uint16: types.DataTypeInterface<number> = {
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writeu16(b, cursor, value)
    return 2
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readu16(b, cursor), 2
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 2
  end,

  size = @native function(_value: number): number
    return 2
  end,
}

return function(): types.DataTypeInterface<number>
  return uint16
end
