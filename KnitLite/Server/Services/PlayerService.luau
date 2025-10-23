--!strict
local Replicated = game:GetService('ReplicatedStorage')
local KnitLite = Replicated:WaitForChild('KnitLite')
local Shared = KnitLite:WaitForChild('Shared')
local Knit = require(Shared:WaitForChild('KnitLite'))
local SIgnal = require(Shared:WaitForChild('Signal'))
local Players = game:GetService('Players')

export type PlayerServiceClient = {
	PlayerJoined: SIgnal.Signal<Player>,
	PlayerLeft: SIgnal.Signal<Player>
}

export type PlayerService = {
	Name: string,
	Client: PlayerServiceClient,
	Players: {[Player]: true},
	KnitInit: (self: PlayerService) -> (),
	KnitStart: (self: PlayerService) -> (),
	GetPlayers: (self: PlayerService) -> {Player},
	IsPlayerInGame: (self: PlayerService, player: Player) -> boolean,
}

local PlayerService = Knit.CreateService({
	Name = 'PlayerService',
	Client = {
		PlayerJoined = SIgnal.new(),
		PlayerLeft = SIgnal.new()
	},
}) :: PlayerService

PlayerService.Players = {} :: {[Player]: true}

function PlayerService:KnitInit()
	print("[PlayerService] Initialized")
end

function PlayerService:KnitStart()
	print("[PlayerService] Started")
	Players.PlayerAdded:Connect(function(player)
		if not self.Players[player] then
			self.Players[player] = true
			self.Client.PlayerJoined:Fire(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.Players[player] = nil
		self.Client.PlayerLeft:Fire(player)
	end)
	local current = Players:GetPlayers()
	for _, player in pairs(current) do
		self.Players[player] = true
		self.Client.PlayerJoined:Fire(player)
	end
end

function PlayerService:GetPlayers(): {Player}
	local list: {Player} = {}
	for player in pairs(self.Players) do
		table.insert(list, player)
	end
	return list
end

function PlayerService:IsPlayerInGame(player: Player): boolean
	return self.Players[player] ~= nil
end

return PlayerService