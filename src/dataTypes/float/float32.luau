--!strict

const types = require(script.Parent.Parent.Parent.types)

const float32: types.DataTypeInterface<number> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writef32(b, cursor, value)
    return 4
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readf32(b, cursor), 4
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 4
  end,

  size = @native function(_value: number): number
    return 4
  end,
})

return function(): types.DataTypeInterface<number>
  return float32
end
