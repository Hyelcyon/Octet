--!strict

type Buildable = {
  build: (id: number) -> unknown,
}

type NodeEntry = {
  path: string,
  parent: { [string]: unknown },
  key: string,
  buildable: Buildable,
}

const function contract<T>(schema: T): T
  if type(schema) ~= "table" then
    return schema :: T
  end

  const entries: { NodeEntry } = {}

  const function traverse(node: { [string]: unknown }, currentPath: string)
    for key, value in node do
      const subPath = if currentPath == "" then key else `{currentPath}/{key}`
      if type(value) == "table" then
        const candidate = value :: { [string]: unknown }
        if type(candidate.build) == "function" then
          table.insert(entries, {
            path = subPath,
            parent = node,
            key = key,
            buildable = candidate :: Buildable,
          })
        else
          traverse(candidate, subPath)
        end
      end
    end
  end

  traverse(schema :: { [string]: unknown }, "")

  table.sort(entries, function(a: NodeEntry, b: NodeEntry): boolean
    return a.path < b.path
  end)

  for id, entry in entries do
    entry.parent[entry.key] = entry.buildable.build(id)
  end

  return schema :: T
end

return contract
