--!strict

const types = require(script.Parent.Parent.Parent.types)

const vec2: types.DataTypeInterface<Vector2> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: Vector2, _references: { unknown }?): number
    buffer.writef32(b, cursor, value.X)
    buffer.writef32(b, cursor + 4, value.Y)
    return 8
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (Vector2, number)
    return Vector2.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4)), 8
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 8
  end,

  size = @native function(_value: Vector2): number
    return 8
  end,
})

return function(): types.DataTypeInterface<Vector2>
  return vec2
end
