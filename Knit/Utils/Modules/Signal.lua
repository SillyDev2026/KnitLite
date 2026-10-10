--!strict
--!native
--!optimize 2

local Promise = require(script.Parent.Promise)

type Node<Arg> = {
	fn: (Arg) -> (),
	next: Node<Arg>?,
	connected: boolean
}

export type Connection<Arg> = {
	Disconnect: (self: Connection<Arg>) -> (),
	_node: Node<Arg>?,
	_signal: Signal<Arg>?
}

export type Signal<Arg> = {
	Connect: (self: Signal<Arg>, fn:(Arg)->()) -> Connection<Arg>,
	Once: (self: Signal<Arg>, fn:(Arg)->()) -> Connection<Arg>,
	Fire: (self: Signal<Arg>, Arg) -> (),
	Wait: (self: Signal<Arg>) -> Promise.Promise<Arg>,
	DisconnectAll: (self: Signal<Arg>) -> ()
}

type SignalInternal<Arg> = {
	_head: Node<Arg>?
}

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	local node = self._node
	if not node or not node.connected then
		return
	end

    node.connected = false
    local owner = self._signal
    if owner then
        local previous = nil
        local current = owner._head
        while current do
            if current == node then
                if previous then previous.next = current.next else owner._head = current.next end
                break
            end
            previous = current
            current = current.next
        end
    end
    node.next = nil
    self._node = nil
    self._signal = nil
end

function Signal.new<Arg>(): Signal<Arg>
	local self: SignalInternal<Arg> = setmetatable({
		_head = nil
	}, Signal)

	return self :: any
end

function Signal:Connect<Arg>(fn:(Arg)->()): Connection<Arg>
	local node: Node<Arg> = {
		fn = fn,
		next = self._head,
		connected = true
	}

	self._head = node

	local conn: Connection<Arg> = setmetatable({
		_node = node,
		_signal = self
	}, Connection)

	return conn
end

function Signal:Once<Arg>(fn:(Arg)->()): Connection<Arg>
	local conn: Connection<Arg>

	conn = self:Connect(function(v:Arg)
		conn:Disconnect()
		fn(v)
	end)

	return conn
end

function Signal:Fire<Arg>(value:Arg)
    local node = self._head
    while node do
        local nextNode = node.next
        if node.connected then node.fn(value) end
        node = nextNode
    end
end

function Signal:DisconnectAll()
    local node = self._head
    self._head = nil
    while node do
        local nextNode = node.next
        node.connected = false
        node.next = nil
        node = nextNode
    end
end

function Signal:Wait<Arg>(): Promise.Promise<Arg>
	return Promise.new(function(resolve)
		local conn
		conn = self:Connect(function(v:Arg)
			conn:Disconnect()
			resolve(v)
		end)
	end)
end

return Signal