--!strict

const types = require(script.Parent.Parent.Parent.types)

const int24: types.DataTypeInterface<number> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writeu16(b, cursor, bit32.band(value, 0xFFFF))
    buffer.writei8(b, cursor + 2, bit32.arshift(value, 16))
    return 3
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    const low = buffer.readu16(b, cursor)
    const high = buffer.readi8(b, cursor + 2)
    return low + high * 65_536, 3
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 3
  end,

  size = @native function(_value: number): number
    return 3
  end,
})

return function(): types.DataTypeInterface<number>
  return int24
end
