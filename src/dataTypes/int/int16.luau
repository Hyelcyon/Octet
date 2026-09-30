--!strict

const types = require(script.Parent.Parent.Parent.types)

const int16: types.DataTypeInterface<number> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writei16(b, cursor, value)
    return 2
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readi16(b, cursor), 2
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 2
  end,

  size = @native function(_value: number): number
    return 2
  end,
})

return function(): types.DataTypeInterface<number>
  return int16
end
