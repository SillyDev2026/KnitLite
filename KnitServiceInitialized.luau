local Replicated = game:GetService('ReplicatedStorage')
local KnitLite = Replicated:WaitForChild('KnitLite')
local Shared = KnitLite:WaitForChild('Shared')
local Server = KnitLite:WaitForChild('Server')
local KnitLite = require(Shared:WaitForChild('KnitLite'))
local ServiceFolder = Server:WaitForChild('Services')

KnitLite:Start()
