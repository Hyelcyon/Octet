--!strict

const types = require(script.Parent.Parent.Parent.types)

const uint8: types.DataTypeInterface<number> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writeu8(b, cursor, value)
    return 1
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readu8(b, cursor), 1
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 1
  end,

  size = @native function(_value: number): number
    return 1
  end,
})

return function(): types.DataTypeInterface<number>
  return uint8
end
