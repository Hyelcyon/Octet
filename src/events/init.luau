--!strict

const types = require(script.Parent.types)
const event = require(script.event)

local autoId = 0

const function defineEvent<T>(props: types.EventProps<T>): types.DefinedEvent<T>
  autoId += 1
  const defaultId = autoId
  local instantiated: types.Event<T>? = nil

  const function getInstance(): types.Event<T>
    if instantiated == nil then
      instantiated = event(props, defaultId)
    end
    return instantiated :: types.Event<T>
  end

  const definition: types.DefinedEvent<T> = table.freeze({
    build = function(id: number): types.Event<T>
      return event(props, id)
    end,
    fire = function(_self: types.Event<T>, data: T)
      getInstance():fire(data)
    end,
    fireTo = function(_self: types.Event<T>, target: Player | { Player }, data: T)
      getInstance():fireTo(target, data)
    end,
    broadcast = function(_self: types.Event<T>, data: T)
      getInstance():broadcast(data)
    end,
    broadcastExcept = function(_self: types.Event<T>, except: Player, data: T)
      getInstance():broadcastExcept(except, data)
    end,
    connect = function(_self: types.Event<T>, callback: (data: T, player: Player?) -> ()): types.Connection
      return getInstance():connect(callback)
    end,
    once = function(_self: types.Event<T>, callback: (data: T, player: Player?) -> ()): types.Connection
      return getInstance():once(callback)
    end,
    wait = function(_self: types.Event<T>): (T, Player?)
      return getInstance():wait()
    end,
  })

  return definition
end

return defineEvent
