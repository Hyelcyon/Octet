--!strict

const types = require(script.Parent.Parent.types)

const function map<K, V>(
  keyType: types.DataTypeInterface<K>,
  valueType: types.DataTypeInterface<V>
): types.DataTypeInterface<{ [K]: V }>
  return table.freeze({
    write = @native function(b: buffer, cursor: number, value: { [K]: V }, references: { unknown }?): number
      local count = 0
      for _ in value do
        count += 1
      end

      buffer.writeu16(b, cursor, count)
      local currentCursor = cursor + 2

      for k, v in value do
        currentCursor += keyType.write(b, currentCursor, k, references)
        currentCursor += valueType.write(b, currentCursor, v, references)
      end

      return currentCursor - cursor
    end,

    read = @native function(b: buffer, cursor: number, references: { unknown }?): ({ [K]: V }, number)
      const count = buffer.readu16(b, cursor)
      local currentCursor = cursor + 2
      const result: { [K]: V } = {}

      for _ = 1, count do
        const k, kBytes = keyType.read(b, currentCursor, references)
        currentCursor += kBytes
        const v, vBytes = valueType.read(b, currentCursor, references)
        currentCursor += vBytes
        result[k] = v
      end

      return result, currentCursor - cursor
    end,

    skip = @native function(b: buffer, cursor: number): number
      const count = buffer.readu16(b, cursor)
      local currentCursor = cursor + 2

      for _ = 1, count do
        currentCursor += keyType.skip(b, currentCursor)
        currentCursor += valueType.skip(b, currentCursor)
      end

      return currentCursor - cursor
    end,

    size = @native function(value: { [K]: V }): number
      local total = 2
      for k, v in value do
        total += keyType.size(k) + valueType.size(v)
      end
      return total
    end,
  })
end

return map
