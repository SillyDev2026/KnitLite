--!strict
local Promise = {}
Promise.__index = Promise

export type Promise<T> = {
	_status: 'Pending'|'Resolved'|'Rejected',
	_value: any,
	_callbacks: { (T) -> () },
	_errbacks: { (any) -> () },
	andThen:(self: Promise<T>, fn: (T) -> any) -> Promise<T>,
	catch: (self: Promise<T>, fn: (any) -> any) -> Promise<T>,
	finally: (self: Promise<T>, fn: () -> ()) -> Promise<T>,
}

function handle<T, R>(fn: (T) -> R, value: T, resolve: (R) -> (), reject: (any) -> ())
	local ok: boolean, result: any = pcall(fn, value)
	if ok then
		resolve(result)
	else
		reject(result)
	end
end

function Promise.new<T>(executor: (resolve: (T) -> (), reject: (any) -> ()) -> ())
	local self = setmetatable({}, Promise) :: Promise<T>
	self._status = 'Pending'
	self._callbacks = {}
	self._errbacks = {}	
	
	local function pending(): boolean
		return self._status ~= 'Pending'
	end
	
	local function resolve(value: T)
		if pending() then return end
		self._status = 'Resolved'
		self._value = value
		for _, calls in self._callbacks do
			task.spawn(calls, value)
		end
	end
	local function reject(reason: any)
		if pending() then return end
		self._status = 'Rejected'
		self._value = reason
		for _, errs in self._errbacks do
			task.spawn(errs, reason)
		end
	end
	task.spawn(function()
		local ok: boolean, result: any = pcall(executor, resolve, reject)
		if not ok then
			reject(result)
		end
	end)
	return self
end

function Promise:andThen<T, R>(fn: (T) -> R): Promise<T>
	return Promise.new(function(resolve, reject)
		local function callback(val: T)
			return handle(fn, val, resolve, reject)
		end
		if self._status == 'Resolved' then
			callback(self._value)
		elseif self._status == 'Rejected' then
			reject(self._value)
		else
			table.insert(self._callbacks, handle)
			table.insert(self.errbacks, reject)
		end
	end)
end

function Promise:catch<T>(fn: (any) -> T): Promise<T>
	return Promise.new(function(resolve, _reject)
		local function callback(reason: any)
			handle(fn, reason, resolve, _reject)
		end
		if self._status == 'Rejected' then
			callback(self._value)
		elseif self._status == 'Resolved' then
			resolve(self._value)
		else
			table.insert(self._callbacks, resolve)
			table.insert(self._errbacks, callback)
		end
	end)
end

function Promise:finally<T>(fn): Promise<T>
	return Promise.new(function(resolve, reject)
		local function finalize()
			local ok: boolean, err: any = pcall(fn)
			if not ok then
				reject(err)
			end
		end
		if self._status == 'Resolved' then
			finalize()
			resolve(self._value)
		elseif self._status == 'Rejected' then
			finalize()
			reject(self._value)
		else
			table.insert(self._callbacks, function(val)
				finalize()
				resolve(val)
			end)
			table.insert(self._errbacks, function(reason)
				finalize()
				reject(reason)
			end)
		end
	end)
end

return Promise