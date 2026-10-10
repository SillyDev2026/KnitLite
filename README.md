# KnitLite — minimal Roblox service framework

KnitLite provides a small, dependency-free service loader with event signaling and Promise-based startup for Roblox Luau. This maintenance release replaces four **empty ModuleScript files** with working implementations.

## Package structure

```text
ReplicatedStorage
└── Knit
    ├── Services
    │   └── PlayerService     -- ModuleScript
    └── Utils
        └── Modules
            ├── EventBus      -- ModuleScript
            ├── FrameWork     -- ModuleScript
            ├── Promise       -- ModuleScript
            └── Signal        -- ModuleScript
```

Put `PlayerServiceTest.lua` into a **server Script** for the existing demonstration, not a client Script. It expects the hierarchy above.

## Quick start

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = ReplicatedStorage:WaitForChild("Knit")
local FrameWork = require(Knit.Utils.Modules.FrameWork)
local app = FrameWork.new()

app:LoadServices(Knit.Services)
app:Start():await()

local players = app:GetService("PlayerService")
local connection = players.Events:On("PlayerJoined", function(player)
    print(player.Name, "joined")
end)

-- Example cleanup at the end of a session:
connection:Disconnect()
app:Stop()
```

## Public API

| Module | Public operations |
| --- | --- |
| FrameWork | `new()`, `:LoadServices(folder)`, `:GetService(name)`, `:Start()`, `:Stop()` |
| EventBus | `new()`, `:On(name, fn)`, `:Once(name, fn)`, `:Emit(name, ...)`, `:Clear(name?)`, `:Destroy()` |
| Promise | `new(executor)`, `resolve(value)`, `reject(error)`, `:andThen(onFulfilled?, onRejected?)`, `:catch(fn)`, `:await()` |
| Signal | `new()`, `:Connect(fn)`, `:Once(fn)`, `:Fire(value)`, `:Wait()`, `:DisconnectAll()` |
| PlayerService | `Events` emits `PlayerJoined` and `PlayerLeaving`, and exposes a legacy `ClientCall` table |

`FrameWork:Start()` returns a Promise that resolves after all service `Init` methods, then all service `Start` methods run in service-name order. If a service throws, the Promise rejects. The Promise executor runs immediately, and continuations are deferred.

## Important limitations

This is a **local services and events framework**. It does not yet implement Knit-style automatic client RemoteEvents, RemoteFunctions, dependency graphs, cancellation propagation, or a distributed RPC security system. The legacy `ClientCall` table is ordinary in-process state and **does not create networking**. Do not expose private game actions to clients on the assumption that this module validates RemoteEvents.

KnitLite's exported Luau types and `--!strict` directives are a first pass, not a verified zero-warning Roblox Studio typecheck. Engine-dependent modules must be analyzed with Script Analysis in a real place.

## Regression tests and performance

Run `tests/KnitLiteRegression.server.lua` in Roblox Studio with the `Knit` folder as its sibling. Then run the original `PlayerServiceTest.lua`.

Measure listener connect/disconnect throughput and promise chaining with the Studio Script Profiler. There are no claimed performance gains without same-workload baseline measurements.

Luau language reference: https://luau.org/typecheck/ and https://luau.org/performance/.
