--!strict
export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> ()
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	FireAll: (self:Signal<T...>, T...)->(),
	Wait: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
	_connections: {_ConnectionEntry<T...>}
}

type _ConnectionEntry<T...> = {
	fn: (T...) -> (),
	conn: Connection
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({
		_connections = {} :: {_ConnectionEntry<T...>}
	}, Signal) :: Signal<T...>
	return self
end

function Signal:Connect<T...>(fn: (T...) -> ()): Connection
	local connection = {} :: Connection
	connection.Connected = true
	connection.Disconnect = function(self: Connection)
		self.Connected = false
	end
	local entry: _ConnectionEntry<T...> = {
		fn = fn,
		conn = connection
	}
	table.insert(self._connections, entry)
	return connection
end

function Signal:Fire<T...>(...: T...)
	for i = 1, #self._connections do
		local data: _ConnectionEntry<T...> = self._connections[i]
		if data.conn.Connected then
			task.spawn(data.fn, ...)
		end
	end
end

function Signal:Wait<T...>(): T...
	local thread = coroutine.running()
	if not thread then
		error('Signal:Wait() can only be called during coroutine')
	end
	local result: {any}
	local conn:Connection
	conn = self:Connect(function(...: T...)
		result = {...}
		conn:Disconnect()
		coroutine.resume(thread)
	end)
	coroutine.yield()
	return table.unpack(result)
end

function Signal:Destroy<T...>()
	for i = 1, #self._connections do
		local data: _ConnectionEntry<T...> = self._connections[i]
		data.conn:Disconnect()
	end
	table.clear(self._connections)
end

function Signal:FireAll<T...>(...: T...)
	for i = 1, #self._connections do
		local data: _ConnectionEntry<T...> = self._connections[i]
		if data.conn.Connected then
			task.spawn(data.fn, ...)
		end
	end
end

return Signal