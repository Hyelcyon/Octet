--!strict

local types = require(script.Parent.Parent.types)

local null: types.DataTypeInterface<nil> = {
  write = @native function(_b: buffer, _cursor: number, _value: nil, _references: { unknown }?): number
    return 0
  end,

  read = @native function(_b: buffer, _cursor: number, _references: { unknown }?): (nil, number)
    return nil, 0
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 0
  end,

  size = @native function(_value: nil): number
    return 0
  end,
}

return function(): types.DataTypeInterface<nil>
  return null
end
