--!strict

const types = require(script.Parent.Parent.Parent.types)

const scratch = buffer.create(8)

const float48: types.DataTypeInterface<number> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writef64(scratch, 0, value)
    buffer.copy(b, cursor, scratch, 2, 6)
    return 6
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    buffer.writeu16(scratch, 0, 0)
    buffer.copy(scratch, 2, b, cursor, 6)
    return buffer.readf64(scratch, 0), 6
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 6
  end,

  size = @native function(_value: number): number
    return 6
  end,
})

return function(): types.DataTypeInterface<number>
  return float48
end
