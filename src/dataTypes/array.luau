--!strict

local types = require(script.Parent.Parent.types)

local function array<T>(valueType: types.DataTypeInterface<T>): types.DataTypeInterface<{ T }>
  return {
    write = @native function(b: buffer, cursor: number, value: { T }, references: { unknown }?): number
      local count = #value
      buffer.writeu16(b, cursor, count)
      local currentCursor = cursor + 2

      for _, item in value do
        currentCursor += valueType.write(b, currentCursor, item, references)
      end

      return currentCursor - cursor
    end,

    read = @native function(b: buffer, cursor: number, references: { unknown }?): ({ T }, number)
      local count = buffer.readu16(b, cursor)
      local currentCursor = cursor + 2
      local arr = table.create(count) :: { T }

      for i = 1, count do
        local item, readBytes = valueType.read(b, currentCursor, references)
        arr[i] = item
        currentCursor += readBytes
      end

      return arr, currentCursor - cursor
    end,

    skip = @native function(b: buffer, cursor: number): number
      local count = buffer.readu16(b, cursor)
      local currentCursor = cursor + 2

      for _ = 1, count do
        currentCursor += valueType.skip(b, currentCursor)
      end

      return currentCursor - cursor
    end,

    size = @native function(value: { T }): number
      local total = 2
      for _, item in value do
        total += valueType.size(item)
      end
      return total
    end,
  }
end

return array
