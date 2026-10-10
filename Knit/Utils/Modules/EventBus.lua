--!strict
-- Simple, per-instance event bus used by KnitLite services.
local EventBus = {}
EventBus.__index = EventBus

export type Connection = {
    Connected: boolean,
    Disconnect: (self: Connection) -> (),
}

type Listener = {Callback: (...any) -> (), Connected: boolean, Once: boolean, Connection: Connection}

function EventBus.new()
    local self = setmetatable({_events = {}, _destroyed = false}, EventBus)
    return self
end

function EventBus:_connect(name: string, callback: (...any) -> (), once: boolean): Connection
    assert(not self._destroyed, "Cannot subscribe to a destroyed EventBus")
    assert(type(name) == "string" and name ~= "", "Event name must be a nonempty string")
    assert(type(callback) == "function", "Event callback must be a function")

    local listeners = self._events[name]
    if listeners == nil then
        listeners = {}
        self._events[name] = listeners
    end
    local connection: Connection = {Connected = true, Disconnect = function() end}
    local entry: Listener = {Callback = callback, Connected = true, Once = once, Connection = connection}

    function connection:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        entry.Connected = false
        local idx = table.find(listeners, entry)
        if idx then table.remove(listeners, idx) end
    end

    table.insert(listeners, entry)
    return connection
end

function EventBus:On(name: string, callback: (...any) -> ()): Connection
    return self:_connect(name, callback, false)
end

function EventBus:Once(name: string, callback: (...any) -> ()): Connection
    return self:_connect(name, callback, true)
end

function EventBus:Emit(name: string, ...)
    if self._destroyed then return end
    local listeners = self._events[name]
    if listeners == nil then return end
    local copy = table.clone(listeners)
    local args = table.pack(...)
    for _, entry in ipairs(copy) do
        if entry.Connected then
            if entry.Once then entry.Connection:Disconnect() end
            local ok, err = pcall(entry.Callback, table.unpack(args, 1, args.n))
            if not ok then warn("[KnitLite EventBus] Event callback failed:", err) end
        end
    end
end

function EventBus:Clear(name: string?)
    if name ~= nil then
        local listeners = self._events[name]
        if listeners == nil then return end
        for _, entry in ipairs(listeners) do
            entry.Connected = false
            entry.Connection.Connected = false
        end
        self._events[name] = nil
        return
    end
    for eventName in pairs(self._events) do self:Clear(eventName) end
end

function EventBus:Destroy()
    if self._destroyed then return end
    self:Clear()
    self._destroyed = true
end

return EventBus
