--!strict

local types = require(script.Parent.Parent.Parent.types)

local int8: types.DataTypeInterface<number> = {
  write = @native function(b: buffer, cursor: number, value: number, _references: { unknown }?): number
    buffer.writei8(b, cursor, value)
    return 1
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (number, number)
    return buffer.readi8(b, cursor), 1
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 1
  end,

  size = @native function(_value: number): number
    return 1
  end,
}

return function(): types.DataTypeInterface<number>
  return int8
end
