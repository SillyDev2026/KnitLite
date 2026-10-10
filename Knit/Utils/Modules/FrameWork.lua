--!strict
local Promise = require(script.Parent:WaitForChild("Promise"))
local FrameWork = {}
FrameWork.__index = FrameWork

export type Service = {
    Name: string?,
    Init: ((any) -> ())?,
    Start: ((any) -> ())?,
    Stop: ((any) -> ())?,
}
export type App = {
    Services: {[string]: Service},
    LoadServices: (self: App, container: Instance) -> (),
    GetService: (self: App, name: string) -> Service,
    Start: (self: App) -> any,
    Stop: (self: App) -> (),
}

function FrameWork.new(): App
    return setmetatable({Services = {}, _loaded = false, _started = false}, FrameWork) :: any
end

function FrameWork:LoadServices(container: Instance)
    assert(not self._started, "Services cannot be loaded after Start")
    assert(typeof(container) == "Instance", "LoadServices expects an Instance")
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("ModuleScript") then continue end
        local ok, service = pcall(require, child)
        assert(ok, "Failed to load service " .. child.Name .. ": " .. tostring(service))
        assert(type(service) == "table", "Service modules must return a table")
        local name = service.Name or child.Name
        assert(type(name) == "string" and name ~= "", "Service name must not be empty")
        assert(self.Services[name] == nil, "Duplicate service: " .. name)
        service.Name = name
        self.Services[name] = service
    end
    self._loaded = true
end

function FrameWork:GetService(name: string)
    local service = self.Services[name]
    assert(service ~= nil, "Unknown service: " .. name)
    return service
end

function FrameWork:Start()
    return Promise.new(function(resolve, reject)
        if self._started then resolve(self) return end
        if not self._loaded then reject("Call LoadServices before Start") return end

        local names = {}
        for name in pairs(self.Services) do table.insert(names, name) end
        table.sort(names)
        for _, name in ipairs(names) do
            local service = self.Services[name]
            if type(service.Init) == "function" then
                local ok, err = pcall(service.Init, service)
                if not ok then reject(name .. ":Init: " .. tostring(err)) return end
            end
        end
        for _, name in ipairs(names) do
            local service = self.Services[name]
            if type(service.Start) == "function" then
                local ok, err = pcall(service.Start, service)
                if not ok then reject(name .. ":Start: " .. tostring(err)) return end
            end
        end
        self._started = true
        resolve(self)
    end)
end

function FrameWork:Stop()
    if not self._started then return end
    self._started = false
    for name, service in pairs(self.Services) do
        if type(service.Stop) == "function" then
            local ok, err = pcall(service.Stop, service)
            if not ok then warn("[KnitLite] Stop failed for", name, err) end
        end
    end
end

return FrameWork
