--!strict

local types = require(script.Parent.Parent.types)

local buff: types.DataTypeInterface<buffer> = {
  write = @native function(b: buffer, cursor: number, value: buffer, _references: { unknown }?): number
    local len = buffer.len(value)
    buffer.writeu32(b, cursor, len)
    buffer.copy(b, cursor + 4, value, 0, len)
    return len + 4
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (buffer, number)
    local len = buffer.readu32(b, cursor)
    local freshBuffer = buffer.create(len)
    buffer.copy(freshBuffer, 0, b, cursor + 4, len)
    return freshBuffer, len + 4
  end,

  skip = @native function(b: buffer, cursor: number): number
    return buffer.readu32(b, cursor) + 4
  end,

  size = @native function(value: buffer): number
    return buffer.len(value) + 4
  end,
}

return function(): types.DataTypeInterface<buffer>
  return buff
end
