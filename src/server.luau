--!strict

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const types = require(script.Parent.types)

export type Channel = {
  buff: buffer,
  cursor: number,
  size: number,
  references: { unknown },
}

type EventListener = {
  codec: types.DataTypeInterface<unknown>,
  callback: (data: unknown, player: Player) -> (),
}

type ProcedureHandler = {
  requestCodec: types.DataTypeInterface<unknown>,
  responseCodec: types.DataTypeInterface<unknown>,
  callback: (data: unknown, player: Player) -> unknown,
}

type RateLimit = {
  lastTime: number,
  currentBytes: number,
}

const INITIAL_CHANNEL_SIZE = 512
const MAX_PACKET_SIZE = 65_536
const RATE_LIMIT_BYTES_PER_SEC = 65_536

const function createChannel(initialSize: number?): Channel
  const size = if initialSize ~= nil then initialSize else INITIAL_CHANNEL_SIZE
  return {
    buff = buffer.create(size),
    cursor = 0,
    size = size,
    references = {},
  }
end

@native
const function ensureCapacity(channel: Channel, neededBytes: number)
  if channel.cursor + neededBytes > channel.size then
    const newSize = math.max(channel.size * 2, channel.cursor + neededBytes)
    const newBuff = buffer.create(newSize)
    buffer.copy(newBuff, 0, channel.buff, 0, channel.cursor)
    channel.buff = newBuff
    channel.size = newSize
  end
end

@native
const function dumpChannel(channel: Channel): (buffer, { unknown }?)
  const cursor = channel.cursor
  if cursor == 0 then
    return buffer.create(0), nil
  end

  const dumpBuffer = buffer.create(cursor)
  buffer.copy(dumpBuffer, 0, channel.buff, 0, cursor)
  const refs = if #channel.references > 0 then channel.references else nil
  return dumpBuffer, refs
end

@native
const function resetChannel(channel: Channel)
  channel.cursor = 0
  table.clear(channel.references)
end

const globalReliable: Channel = createChannel()
const globalUnreliable: Channel = createChannel()
const perPlayerReliable: { [Player]: Channel } = {}
const perPlayerUnreliable: { [Player]: Channel } = {}
const playerRateLimits: { [Player]: RateLimit } = {}

const activeReliablePlayers: { Player } = table.create(64) :: { Player }
const isReliablePlayerDirty: { [Player]: boolean } = {}

const activeUnreliablePlayers: { Player } = table.create(64) :: { Player }
const isUnreliablePlayerDirty: { [Player]: boolean } = {}

const eventListeners: { [number]: EventListener } = {}
const procedureHandlers: { [number]: ProcedureHandler } = {}

local reliableRemote: RemoteEvent
local unreliableRemote: UnreliableRemoteEvent
local procedureRemoteFunction: RemoteFunction

local server = {}

@native
const function checkRateLimit(player: Player, size: number): boolean
  const limit = playerRateLimits[player]
  if limit == nil then
    return true
  end

  const now = os.clock()
  const elapsed = now - limit.lastTime
  limit.currentBytes = math.min(limit.currentBytes + (elapsed * RATE_LIMIT_BYTES_PER_SEC), RATE_LIMIT_BYTES_PER_SEC)
  limit.lastTime = now

  if limit.currentBytes >= size then
    limit.currentBytes -= size
    return true
  end

  return false
end

@native
const function onServerEvent(player: Player, data: unknown, references: unknown)
  if type(data) ~= "buffer" then
    return
  end

  const dataBuffer = data :: buffer
  const dataSize = buffer.len(dataBuffer)
  if dataSize == 0 or dataSize > MAX_PACKET_SIZE then
    return
  end

  if not checkRateLimit(player, dataSize) then
    return
  end

  const refs = if type(references) == "table" then references :: { unknown } else nil
  local cursor = 0

  while cursor < dataSize do
    const eventId = buffer.readu8(dataBuffer, cursor)
    cursor += 1

    const listener = eventListeners[eventId]
    if listener ~= nil then
      const eventData, readBytes = listener.codec.read(dataBuffer, cursor, refs)
      cursor += readBytes
      task.spawn(listener.callback, eventData, player)
    else
      break
    end
  end
end

@native
const function onServerInvoke(
  player: Player,
  data: unknown,
  references: unknown,
  procedureId: unknown
): (buffer?, { unknown }?)
  if type(data) ~= "buffer" or type(procedureId) ~= "number" then
    return nil, nil
  end

  const dataBuffer = data :: buffer
  const dataSize = buffer.len(dataBuffer)
  if dataSize > MAX_PACKET_SIZE or not checkRateLimit(player, dataSize) then
    return nil, nil
  end

  const handler = procedureHandlers[procedureId :: number]
  if handler == nil then
    return nil, nil
  end

  const refs = if type(references) == "table" then references :: { unknown } else nil
  const requestData = handler.requestCodec.read(dataBuffer, 0, refs)
  const success, responseData = pcall(handler.callback, requestData, player)
  if not success then
    warn(`[Octet] Procedure handler error (id {procedureId}): {responseData}`)
    return nil, nil
  end

  const needed = handler.responseCodec.size(responseData)
  const tempChannel = createChannel(math.max(128, needed))
  ensureCapacity(tempChannel, needed)
  const written = handler.responseCodec.write(tempChannel.buff, 0, responseData, tempChannel.references)
  tempChannel.cursor = written

  return dumpChannel(tempChannel)
end

const function onPlayerAdded(player: Player)
  perPlayerReliable[player] = createChannel()
  perPlayerUnreliable[player] = createChannel()
  playerRateLimits[player] = {
    lastTime = os.clock(),
    currentBytes = RATE_LIMIT_BYTES_PER_SEC,
  }
end

const function onPlayerRemoving(player: Player)
  perPlayerReliable[player] = nil
  perPlayerUnreliable[player] = nil
  isReliablePlayerDirty[player] = nil
  isUnreliablePlayerDirty[player] = nil
  playerRateLimits[player] = nil
end

@native
function server:sendAllReliable<T>(eventId: number, codec: types.DataTypeInterface<T>, data: T)
  const needed = codec.size(data) + 1
  ensureCapacity(globalReliable, needed)
  buffer.writeu8(globalReliable.buff, globalReliable.cursor, eventId)
  globalReliable.cursor += 1
  const written = codec.write(globalReliable.buff, globalReliable.cursor, data, globalReliable.references)
  globalReliable.cursor += written
end

@native
function server:sendAllUnreliable<T>(eventId: number, codec: types.DataTypeInterface<T>, data: T)
  const needed = codec.size(data) + 1
  ensureCapacity(globalUnreliable, needed)
  buffer.writeu8(globalUnreliable.buff, globalUnreliable.cursor, eventId)
  globalUnreliable.cursor += 1
  const written = codec.write(globalUnreliable.buff, globalUnreliable.cursor, data, globalUnreliable.references)
  globalUnreliable.cursor += written
end

@native
function server:sendPlayerReliable<T>(player: Player, eventId: number, codec: types.DataTypeInterface<T>, data: T)
  const channel = perPlayerReliable[player]
  if channel == nil then
    return
  end
  const needed = codec.size(data) + 1
  ensureCapacity(channel, needed)
  buffer.writeu8(channel.buff, channel.cursor, eventId)
  channel.cursor += 1
  const written = codec.write(channel.buff, channel.cursor, data, channel.references)
  channel.cursor += written

  if not isReliablePlayerDirty[player] then
    isReliablePlayerDirty[player] = true
    table.insert(activeReliablePlayers, player)
  end
end

@native
function server:sendPlayerUnreliable<T>(player: Player, eventId: number, codec: types.DataTypeInterface<T>, data: T)
  const channel = perPlayerUnreliable[player]
  if channel == nil then
    return
  end
  const needed = codec.size(data) + 1
  ensureCapacity(channel, needed)
  buffer.writeu8(channel.buff, channel.cursor, eventId)
  channel.cursor += 1
  const written = codec.write(channel.buff, channel.cursor, data, channel.references)
  channel.cursor += written

  if not isUnreliablePlayerDirty[player] then
    isUnreliablePlayerDirty[player] = true
    table.insert(activeUnreliablePlayers, player)
  end
end

@native
function server:sendPlayersReliable<T>(players: { Player }, eventId: number, codec: types.DataTypeInterface<T>, data: T)
  for _, player in players do
    self:sendPlayerReliable(player, eventId, codec, data)
  end
end

function server:registerEvent(
  eventId: number,
  codec: types.DataTypeInterface<unknown>,
  callback: (data: unknown, player: Player) -> ()
)
  eventListeners[eventId] = {
    codec = codec,
    callback = callback,
  }
end

function server:registerProcedure(
  procedureId: number,
  requestCodec: types.DataTypeInterface<unknown>,
  responseCodec: types.DataTypeInterface<unknown>,
  callback: (request: unknown, player: Player) -> unknown
)
  procedureHandlers[procedureId] = {
    requestCodec = requestCodec,
    responseCodec = responseCodec,
    callback = callback,
  }
end

function server:unregisterProcedure(procedureId: number)
  procedureHandlers[procedureId] = nil
end

function server:start()
  const folder = script.Parent:FindFirstChild("system") or Instance.new("Folder")
  folder.Name = "system"
  folder.Parent = script.Parent

  reliableRemote = folder:FindFirstChild("OctetReliable") or Instance.new("RemoteEvent")
  reliableRemote.Name = "OctetReliable"
  reliableRemote.OnServerEvent:Connect(onServerEvent)
  reliableRemote.Parent = folder

  unreliableRemote = folder:FindFirstChild("OctetUnreliable") or Instance.new("UnreliableRemoteEvent")
  unreliableRemote.Name = "OctetUnreliable"
  unreliableRemote.OnServerEvent:Connect(onServerEvent)
  unreliableRemote.Parent = folder

  procedureRemoteFunction = folder:FindFirstChild("OctetProcedure") or Instance.new("RemoteFunction")
  procedureRemoteFunction.Name = "OctetProcedure"
  procedureRemoteFunction.OnServerInvoke = onServerInvoke
  procedureRemoteFunction.Parent = folder

  for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
  end

  Players.PlayerAdded:Connect(onPlayerAdded)
  Players.PlayerRemoving:Connect(onPlayerRemoving)

  RunService.Heartbeat:Connect(function()
    if globalReliable.cursor > 0 then
      const dumpBuf, dumpRefs = dumpChannel(globalReliable)
      reliableRemote:FireAllClients(dumpBuf, dumpRefs)
      resetChannel(globalReliable)
    end

    if globalUnreliable.cursor > 0 then
      const dumpBuf, dumpRefs = dumpChannel(globalUnreliable)
      unreliableRemote:FireAllClients(dumpBuf, dumpRefs)
      resetChannel(globalUnreliable)
    end

    for _, player in activeReliablePlayers do
      const channel = perPlayerReliable[player]
      if channel ~= nil and channel.cursor > 0 then
        const dumpBuf, dumpRefs = dumpChannel(channel)
        reliableRemote:FireClient(player, dumpBuf, dumpRefs)
        resetChannel(channel)
      end
      isReliablePlayerDirty[player] = nil
    end
    table.clear(activeReliablePlayers)

    for _, player in activeUnreliablePlayers do
      const channel = perPlayerUnreliable[player]
      if channel ~= nil and channel.cursor > 0 then
        const dumpBuf, dumpRefs = dumpChannel(channel)
        unreliableRemote:FireClient(player, dumpBuf, dumpRefs)
        resetChannel(channel)
      end
      isUnreliablePlayerDirty[player] = nil
    end
    table.clear(activeUnreliablePlayers)
  end)
end

return table.freeze(server)
