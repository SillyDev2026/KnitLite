--!strict
-- Studio Script alongside the Knit folder in ServerScriptService.
local modules = script.Parent:WaitForChild("Knit").Utils.Modules
local EventBus = require(modules:WaitForChild("EventBus"))
local Promise = require(modules:WaitForChild("Promise"))
local Signal = require(modules:WaitForChild("Signal"))
local FrameWork = require(modules:WaitForChild("FrameWork"))

local bus = EventBus.new()
local eventCount = 0
local connection = bus:Once("Once", function(value)
    assert(value == 9)
    eventCount += 1
end)
bus:Emit("Once", 9)
bus:Emit("Once", 9)
assert(eventCount == 1 and not connection.Connected)
bus:Destroy()

local signal = Signal.new()
local count = 0
local first = signal:Connect(function(_value)
    count += 1
end)
signal:Fire(1)
first:Disconnect()
signal:Fire(2)
assert(count == 1, "Signal listener not removed")

local fired = signal:Wait()
-- Registration must happen before the next Fire, without relying on
-- Promise.new having started an asynchronous executor.
signal:Fire(13)
assert(fired:await() == 13, "Signal Wait lost an immediate event")
signal:DisconnectAll()

local outcome = Promise.resolve(41):andThen(function(value)
    return value + 1
end):await()
assert(outcome == 42, "Promise continuation failed")

local app = FrameWork.new()
app:LoadServices(script.Parent.Knit.Services)
local started = app:Start():await()
assert(started == app, "Framework did not resolve to the app")
local playerService = app:GetService("PlayerService")
assert(playerService.Events ~= nil, "PlayerService did not initialize")
app:Stop()
print("KnitLite core regression PASS")
