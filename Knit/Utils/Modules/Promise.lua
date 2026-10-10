--!strict
-- Minimal Promise used by KnitLite. Resolves or rejects exactly once.
local Promise = {}
Promise.__index = Promise

export type Promise<T> = {
    andThen: (self: Promise<T>, ((T) -> any)?, ((any) -> any)?) -> Promise<any>,
    catch: (self: Promise<T>, (any) -> any) -> Promise<any>,
    await: (self: Promise<T>) -> T,
}

type Handler = {Fulfilled: ((any) -> any)?, Rejected: ((any) -> any)?, Resolve: (any) -> (), Reject: (any) -> ()}

local function schedule(self: any, entry: Handler)
    task.defer(function()
        local handler = if self._state == "fulfilled" then entry.Fulfilled else entry.Rejected
        if handler == nil then
            if self._state == "fulfilled" then entry.Resolve(self._value) else entry.Reject(self._value) end
            return
        end
        local ok, value = pcall(handler, self._value)
        if ok then entry.Resolve(value) else entry.Reject(value) end
    end)
end

function Promise.new<T>(executor: (resolve: (T) -> (), reject: (any) -> ()) -> ()): Promise<T>
    assert(type(executor) == "function", "Promise.new requires an executor")
    local self = setmetatable({_state = "pending", _value = nil, _callbacks = {}}, Promise) :: any

    local function settle(status: string, value: any)
        if self._state ~= "pending" then return end
        self._state = status
        self._value = value
        for _, entry in ipairs(self._callbacks) do schedule(self, entry) end
        table.clear(self._callbacks)
    end

    local function reject(reason: any)
        settle("rejected", reason)
    end

    local function resolve(value: any)
        if value == self then
            reject("Promise cannot resolve to itself")
            return
        end
        if type(value) == "table" and getmetatable(value) == Promise then
            value:andThen(resolve, reject)
            return
        end
        settle("fulfilled", value)
    end

    -- Execute registration synchronously so Signal:Wait cannot miss a Fire
    -- issued immediately after the subscription is created.
    local ok, err = pcall(executor, resolve, reject)
    if not ok then reject(err) end
    return self :: Promise<T>
end

function Promise.resolve<T>(value: T): Promise<T>
    return Promise.new(function(resolve)
        resolve(value)
    end)
end

function Promise.reject(reason: any): Promise<any>
    return Promise.new(function(_resolve, reject)
        reject(reason)
    end)
end

function Promise:andThen(onFulfilled: ((any) -> any)?, onRejected: ((any) -> any)?)
    return Promise.new(function(resolve, reject)
        local entry: Handler = {Fulfilled = onFulfilled, Rejected = onRejected, Resolve = resolve, Reject = reject}
        if self._state == "pending" then
            table.insert(self._callbacks, entry)
        else
            schedule(self, entry)
        end
    end)
end

function Promise:catch(onRejected: (any) -> any)
    return self:andThen(nil, onRejected)
end

function Promise:await()
    if self._state == "fulfilled" then return self._value end
    if self._state == "rejected" then error(self._value, 2) end
    local waiting = coroutine.running()
    self:andThen(function(value)
        task.spawn(waiting, true, value)
    end, function(reason)
        task.spawn(waiting, false, reason)
    end)
    local ok, result = coroutine.yield()
    if not ok then error(result, 2) end
    return result
end

return Promise
