--!strict

local types = require(script.Parent.Parent.types)

local function struct<T>(schema: { [string]: types.DataTypeInterface<unknown> }): types.DataTypeInterface<T>
  local keys: { string } = {}
  for key in schema do
    table.insert(keys, key)
  end
  table.sort(keys)

  local count = #keys
  local orderedCodecs = table.create(count) :: { types.DataTypeInterface<unknown> }

  for i, key in keys do
    orderedCodecs[i] = schema[key]
  end

  local codec: types.DataTypeInterface<T> = {
    write = @native function(b: buffer, cursor: number, value: T, references: { unknown }?): number
      local tbl = (value :: unknown) :: { [string]: unknown }
      local currentCursor = cursor
      for i, key in keys do
        currentCursor += orderedCodecs[i].write(b, currentCursor, tbl[key], references)
      end
      return currentCursor - cursor
    end,

    read = @native function(b: buffer, cursor: number, references: { unknown }?): (T, number)
      local result: { [string]: unknown } = {}
      local currentCursor = cursor
      for i, key in keys do
        local val, readBytes = orderedCodecs[i].read(b, currentCursor, references)
        result[key] = val
        currentCursor += readBytes
      end
      return (result :: unknown) :: T, currentCursor - cursor
    end,

    skip = @native function(b: buffer, cursor: number): number
      local currentCursor = cursor
      for _, c in orderedCodecs do
        currentCursor += c.skip(b, currentCursor)
      end
      return currentCursor - cursor
    end,

    size = @native function(value: T): number
      local tbl = (value :: unknown) :: { [string]: unknown }
      local total = 0
      for i, key in keys do
        total += orderedCodecs[i].size(tbl[key])
      end
      return total
    end,
  }

  return codec
end

return struct
