--!strict

local types = require(script.Parent.Parent.types)

local function optional<T>(valueType: types.DataTypeInterface<T>): types.DataTypeInterface<T?>
  return {
    write = @native function(b: buffer, cursor: number, value: T?, references: { unknown }?): number
      if value ~= nil then
        buffer.writeu8(b, cursor, 1)
        return 1 + valueType.write(b, cursor + 1, value, references)
      else
        buffer.writeu8(b, cursor, 0)
        return 1
      end
    end,

    read = @native function(b: buffer, cursor: number, references: { unknown }?): (T?, number)
      if buffer.readu8(b, cursor) == 0 then
        return nil, 1
      end

      local val, readBytes = valueType.read(b, cursor + 1, references)
      return val, 1 + readBytes
    end,

    skip = @native function(b: buffer, cursor: number): number
      if buffer.readu8(b, cursor) == 0 then
        return 1
      end
      return 1 + valueType.skip(b, cursor + 1)
    end,

    size = @native function(value: T?): number
      return if value ~= nil then 1 + valueType.size(value) else 1
    end,
  }
end

return optional
