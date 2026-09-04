--!strict

local types = require(script.Parent.Parent.Parent.types)

local uint24: types.DataTypeInterface<number> = {
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writeu16(b, cursor, bit32.band(value, 0xFFFF))
    buffer.writeu8(b, cursor + 2, bit32.rshift(value, 16))
    return 3
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    local low = buffer.readu16(b, cursor)
    local high = buffer.readu8(b, cursor + 2)
    return bit32.bor(low, bit32.lshift(high, 16)), 3
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 3
  end,

  size = @native function(_value: number): number
    return 3
  end,
}

return function(): types.DataTypeInterface<number>
  return uint24
end
