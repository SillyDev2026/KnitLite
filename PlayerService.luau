local Replicated = game:GetService('ReplicatedStorage')
local KnitLite = Replicated:WaitForChild('KnitLite')
local Shared = KnitLite:WaitForChild('Shared')
local Server = KnitLite:WaitForChild('Server')
local KnitLite = require(Shared:WaitForChild('KnitLite'))
local ServiceFolder = Server:WaitForChild('Services')
local PlayerService = require(ServiceFolder:WaitForChild('PlayerService'))

local Players = KnitLite.GetService('PlayerService') :: PlayerService.PlayerService

Players.Client.PlayerJoined:Connect(function(player)
	print(player.Name, 'Has Joined')
end)

Players.Client.PlayerLeft:Connect(function(player)
	print(player.Name, 'Has Left')
end)
