--!strict

const types = require(script.Parent.Parent.types)

const str: types.DataTypeInterface<string> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: string, _references: { unknown }?): number
    const len = #value
    buffer.writeu16(b, cursor, len)
    buffer.writestring(b, cursor + 2, value, len)
    return len + 2
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (string, number)
    const len = buffer.readu16(b, cursor)
    return buffer.readstring(b, cursor + 2, len), len + 2
  end,

  skip = @native function(b: buffer, cursor: number): number
    return buffer.readu16(b, cursor) + 2
  end,

  size = @native function(value: string): number
    return #value + 2
  end,
})

return function(): types.DataTypeInterface<string>
  return str
end
