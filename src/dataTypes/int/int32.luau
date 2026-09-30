--!strict

const types = require(script.Parent.Parent.Parent.types)

const int32: types.DataTypeInterface<number> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writei32(b, cursor, value)
    return 4
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readi32(b, cursor), 4
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 4
  end,

  size = @native function(_value: number): number
    return 4
  end,
})

return function(): types.DataTypeInterface<number>
  return int32
end
