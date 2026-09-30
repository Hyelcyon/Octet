--!strict

const types = require(script.Parent.Parent.Parent.types)

const float64: types.DataTypeInterface<number> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writef64(b, cursor, value)
    return 8
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readf64(b, cursor), 8
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 8
  end,

  size = @native function(_value: number): number
    return 8
  end,
})

return function(): types.DataTypeInterface<number>
  return float64
end
