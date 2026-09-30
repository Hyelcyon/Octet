--!strict

const types = require(script.Parent.Parent.types)

const bool: types.DataTypeInterface<boolean> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: boolean, _references: { unknown }?): number
    buffer.writeu8(b, cursor, if value then 1 else 0)
    return 1
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (boolean, number)
    return buffer.readu8(b, cursor) ~= 0, 1
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 1
  end,

  size = @native function(_value: boolean): number
    return 1
  end,
})

return function(): types.DataTypeInterface<boolean>
  return bool
end
