local Replicated = game:GetService('ReplicatedStorage')
local Knit = Replicated:WaitForChild('Knit')
local Utils = Knit:WaitForChild('Utils')
local Modules = Utils:WaitForChild('Modules')
local FrameWork = require(Modules:WaitForChild('FrameWork'))
local Services = Knit:WaitForChild('Services')

local App = FrameWork.new()

App:LoadServices(Services)
App:Start():await()
print('Loading servies fininished')

local PlayerService = App:GetService('PlayerService')

PlayerService.Events:On('PlayerJoined', function(player)
	print(player.Name, 'Has Joined the game')
	PlayerService.ClientCall.Do = function(self, player, ...)
		self.Events:Emit('DoCalled', player, ...)
	end
end)

PlayerService.Events:On('PlayerLeaving', function(player)
	print(player.Name, 'Has Left the game')
end)
