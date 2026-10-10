--!strict
local Players = game:GetService("Players")
local EventBus = require(script.Parent.Parent.Utils.Modules:WaitForChild("EventBus"))

local PlayerService = {
    Name = "PlayerService",
    ClientCall = {},
    Events = nil,
    _connections = {},
}

function PlayerService:Init()
    self.Events = EventBus.new()
end

function PlayerService:Start()
    assert(self.Events ~= nil, "PlayerService.Init must run first")
    self._connections = {
        Players.PlayerAdded:Connect(function(player)
            self.Events:Emit("PlayerJoined", player)
        end),
        Players.PlayerRemoving:Connect(function(player)
            self.Events:Emit("PlayerLeaving", player)
        end),
    }
    -- Also announce players who joined before Framework.Start completed.
    for _, player in ipairs(Players:GetPlayers()) do
        task.defer(function()
            if player.Parent == Players and self.Events ~= nil then
                self.Events:Emit("PlayerJoined", player)
            end
        end)
    end
end

function PlayerService:Stop()
    for _, connection in ipairs(self._connections) do connection:Disconnect() end
    table.clear(self._connections)
    if self.Events then
        self.Events:Destroy()
        self.Events = nil
    end
end

return PlayerService
