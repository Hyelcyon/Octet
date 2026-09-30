--!strict

const types = require(script.Parent.Parent.Parent.types)

const vec3: types.DataTypeInterface<Vector3> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: Vector3, _references: { unknown }?): number
    buffer.writef32(b, cursor, value.X)
    buffer.writef32(b, cursor + 4, value.Y)
    buffer.writef32(b, cursor + 8, value.Z)
    return 12
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (Vector3, number)
    return Vector3.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4), buffer.readf32(b, cursor + 8)), 12
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 12
  end,

  size = @native function(_value: Vector3): number
    return 12
  end,
})

return function(): types.DataTypeInterface<Vector3>
  return vec3
end
