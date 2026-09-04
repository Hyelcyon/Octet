--!strict

local types = require(script.Parent.Parent.types)

local cframe: types.DataTypeInterface<CFrame> = {
  write = @native function(b: buffer, cursor: number, value: CFrame, _references: { unknown }?): number
    local x, y, z = value.X, value.Y, value.Z
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
    local x = buffer.readf32(b, cursor)
    local y = buffer.readf32(b, cursor + 4)
    local z = buffer.readf32(b, cursor + 8)
    local rx = buffer.readf32(b, cursor + 12)
    local ry = buffer.readf32(b, cursor + 16)
    local rz = buffer.readf32(b, cursor + 20)

    local axis = Vector3.new(rx, ry, rz)
    local angle = axis.Magnitude

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
}

return function(): types.DataTypeInterface<CFrame>
  return cframe
end
