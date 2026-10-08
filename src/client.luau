--!strict

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
  callback: (data: unknown) -> (),
}

const INITIAL_CHANNEL_SIZE = 512

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

const reliableChannel: Channel = createChannel()
const unreliableChannel: Channel = createChannel()

const eventListeners: { [number]: EventListener } = {}

local procedureRemote: RemoteFunction? = nil

const function getProcedureRemote(): RemoteFunction
  local remote = procedureRemote
  if remote ~= nil then
    return remote
  end
  const folder = script.Parent:WaitForChild("system")
  remote = folder:WaitForChild("OctetProcedure") :: RemoteFunction
  procedureRemote = remote
  return remote
end

const client = {}

@native
const function onClientEvent(data: unknown, references: unknown)
  if type(data) ~= "buffer" then
    return
  end

  const dataBuffer = data :: buffer
  const dataSize = buffer.len(dataBuffer)
  if dataSize == 0 then
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
      task.spawn(listener.callback, eventData)
    else
      break
    end
  end
end

@native
function client:sendReliable<T>(eventId: number, codec: types.DataTypeInterface<T>, data: T)
  const needed = codec.size(data) + 1
  ensureCapacity(reliableChannel, needed)
  buffer.writeu8(reliableChannel.buff, reliableChannel.cursor, eventId)
  reliableChannel.cursor += 1
  const written = codec.write(reliableChannel.buff, reliableChannel.cursor, data, reliableChannel.references)
  reliableChannel.cursor += written
end

@native
function client:sendUnreliable<T>(eventId: number, codec: types.DataTypeInterface<T>, data: T)
  const needed = codec.size(data) + 1
  ensureCapacity(unreliableChannel, needed)
  buffer.writeu8(unreliableChannel.buff, unreliableChannel.cursor, eventId)
  unreliableChannel.cursor += 1
  const written = codec.write(unreliableChannel.buff, unreliableChannel.cursor, data, unreliableChannel.references)
  unreliableChannel.cursor += written
end

function client:registerEvent(eventId: number, codec: types.DataTypeInterface<unknown>, callback: (data: unknown) -> ())
  eventListeners[eventId] = {
    codec = codec,
    callback = callback,
  }
end

@native
function client:callProcedure<Req, Res>(
  procedureId: number,
  requestCodec: types.DataTypeInterface<Req>,
  responseCodec: types.DataTypeInterface<Res>,
  requestData: Req
): Res?
  const needed = requestCodec.size(requestData)
  const tempChannel = createChannel(math.max(128, needed))
  ensureCapacity(tempChannel, needed)
  const written = requestCodec.write(tempChannel.buff, 0, requestData, tempChannel.references)
  tempChannel.cursor = written

  const reqBuf, reqRefs = dumpChannel(tempChannel)
  const procedure = getProcedureRemote()
  const resBuf, resRefs = procedure:InvokeServer(reqBuf, reqRefs, procedureId)

  if type(resBuf) == "buffer" then
    const refs = if type(resRefs) == "table" then resRefs :: { unknown } else nil
    const decodedResponse = responseCodec.read(resBuf :: buffer, 0, refs)
    return decodedResponse
  end

  return nil
end

function client:start()
  const folder = script.Parent:WaitForChild("system")

  const reliableRemote = folder:WaitForChild("OctetReliable") :: RemoteEvent
  reliableRemote.OnClientEvent:Connect(onClientEvent)

  const unreliableRemote = folder:WaitForChild("OctetUnreliable") :: UnreliableRemoteEvent
  unreliableRemote.OnClientEvent:Connect(onClientEvent)

  getProcedureRemote()

  RunService.Heartbeat:Connect(function()
    if reliableChannel.cursor > 0 then
      const dumpBuf, dumpRefs = dumpChannel(reliableChannel)
      reliableRemote:FireServer(dumpBuf, dumpRefs)
      resetChannel(reliableChannel)
    end

    if unreliableChannel.cursor > 0 then
      const dumpBuf, dumpRefs = dumpChannel(unreliableChannel)
      unreliableRemote:FireServer(dumpBuf, dumpRefs)
      resetChannel(unreliableChannel)
    end
  end)
end

return table.freeze(client)
