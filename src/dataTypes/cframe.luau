--!strict

const types = require(script.Parent.Parent.types)

const cframe: types.DataTypeInterface<CFrame> = table.freeze({
  write = @native function(b: buffer, cursor: number, value: CFrame, _references: { unknown }?): number
    const x, y, z = value.X, value.Y, value.Z
    local axis, angle = value:ToAxisAngle()
    axis *= angle

    buffer.writef32(b, cursor, x)
    buffer.writef32(b, cursor + 4, y)
    buffer.writef32(b, cursor + 8, z)
    buffer.writef32(b, cursor + 12, axis.X)
    buffer.writef32(b, cursor + 16, axis.Y)
    buffer.writef32(b, cursor + 20, axis.Z)
    return 24
  end,

  read = @native function(b: buffer, cursor: number, _references: { unknown }?): (CFrame, number)
    const x = buffer.readf32(b, cursor)
    const y = buffer.readf32(b, cursor + 4)
    const z = buffer.readf32(b, cursor + 8)
    const rx = buffer.readf32(b, cursor + 12)
    const ry = buffer.readf32(b, cursor + 16)
    const rz = buffer.readf32(b, cursor + 20)

    const axis = Vector3.new(rx, ry, rz)
    const angle = axis.Magnitude

    if angle ~= 0 then
      return CFrame.new(x, y, z) * CFrame.fromAxisAngle(axis, angle), 24
    else
      return CFrame.new(x, y, z), 24
    end
  end,

  skip = @native function(_b: buffer, _cursor: number): number
    return 24
  end,

  size = @native function(_value: CFrame): number
    return 24
  end,
})

return function(): types.DataTypeInterface<CFrame>
  return cframe
end
