--!strict

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const types = require(script.Parent.Parent.types)
const server = require(script.Parent.Parent.server)
const client = require(script.Parent.Parent.client)

const isServer = RunService:IsServer()

type Callback<T> = (data: T, player: Player?) -> ()

type ListenerNode<T> = {
  callback: Callback<T>?,
  next: ListenerNode<T>?,
  prev: ListenerNode<T>?,
}

const function createEvent<T>(props: types.EventProps<T>, id: number): types.Event<T>
  const reliability = if props.reliability ~= nil then props.reliability else "reliable"
  const codec = props.value

  local head: ListenerNode<T>? = nil
  local tail: ListenerNode<T>? = nil

  @native
  const function dispatch(typedData: T, player: Player?)
    local current = head
    while current ~= nil do
      const nextNode = current.next
      const cb = current.callback
      if cb ~= nil then
        cb(typedData, player)
      end
      current = nextNode
    end
  end

  if isServer then
    server:registerEvent(id, codec, function(data: unknown, player: Player)
      dispatch(data :: T, player)
    end)
  else
    client:registerEvent(id, codec, function(data: unknown)
      dispatch(data :: T, nil)
    end)
  end

  const function addListener(callback: Callback<T>): types.Connection
    const node: ListenerNode<T> = {
      callback = callback,
      next = nil :: ListenerNode<T>?,
      prev = tail,
    }

    local connection: types.Connection
    const function disconnectAction(_selfConn: types.Connection)
      if not connection.connected then
        return
      end
      connection.connected = false

      if node.prev ~= nil then
        node.prev.next = node.next
      else
        head = node.next
      end

      if node.next ~= nil then
        node.next.prev = node.prev
      else
        tail = node.prev
      end

      node.prev = nil
      node.next = nil
      node.callback = nil
    end

    if tail ~= nil then
      tail.next = node
      tail = node
    else
      head = node
      tail = node
    end

    connection = {
      connected = true,
      disconnect = disconnectAction,
      Disconnect = disconnectAction,
    }
    return connection
  end

  const event: types.Event<T> = table.freeze({
    fire = @native function(_self: types.Event<T>, data: T)
      if isServer then
        error("Cannot call event:fire on the server. Use event:fireTo or event:broadcast.")
      end
      if reliability == "reliable" then
        client:sendReliable(id, codec, data)
      else
        client:sendUnreliable(id, codec, data)
      end
    end,

    fireTo = @native function(_self: types.Event<T>, target: Player | { Player }, data: T)
      if not isServer then
        error("Cannot call event:fireTo on the client.")
      end

      if typeof(target) == "Instance" and target:IsA("Player") then
        const player = target :: Player
        if reliability == "reliable" then
          server:sendPlayerReliable(player, id, codec, data)
        else
          server:sendPlayerUnreliable(player, id, codec, data)
        end
      elseif type(target) == "table" then
        const players = target :: { Player }
        if reliability == "reliable" then
          server:sendPlayersReliable(players, id, codec, data)
        else
          for _, player in players do
            server:sendPlayerUnreliable(player, id, codec, data)
          end
        end
      else
        error("Invalid target passed to event:fireTo. Expected Player or array of Players.")
      end
    end,

    broadcast = @native function(_self: types.Event<T>, data: T)
      if not isServer then
        error("Cannot call event:broadcast on the client.")
      end
      if reliability == "reliable" then
        server:sendAllReliable(id, codec, data)
      else
        server:sendAllUnreliable(id, codec, data)
      end
    end,

    broadcastExcept = @native function(_self: types.Event<T>, except: Player, data: T)
      if not isServer then
        error("Cannot call event:broadcastExcept on the client.")
      end

      for _, player in Players:GetPlayers() do
        if player ~= except then
          if reliability == "reliable" then
            server:sendPlayerReliable(player, id, codec, data)
          else
            server:sendPlayerUnreliable(player, id, codec, data)
          end
        end
      end
    end,

    connect = function(_self: types.Event<T>, callback: (data: T, player: Player?) -> ()): types.Connection
      return addListener(callback)
    end,

    once = function(self: types.Event<T>, callback: (data: T, player: Player?) -> ()): types.Connection
      local conn: types.Connection
      conn = self:connect(function(data: T, player: Player?)
        conn:disconnect()
        callback(data, player)
      end)
      return conn
    end,

    wait = function(self: types.Event<T>): (T, Player?)
      const running = coroutine.running()
      local conn: types.Connection
      conn = self:connect(function(data: T, player: Player?)
        conn:disconnect()
        task.spawn(running, data, player)
      end)
      return coroutine.yield()
    end,
  })

  return event
end

return createEvent
