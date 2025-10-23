--!strict
export type KnitService = {
	Name: string,
	Client: {[string]: any}?,
	KnitInit: ((self: any) -> ())?,
	KnitStart: ((self: any) -> ())?,
}

export type KnitController = {
	Name: string,
	KnitInit: ((self: any) -> ())?,
	KnitStart: ((self: any) -> ())?,
}

export type KnitType = {
	_services: {[string]: KnitService},
	_controllers: {[string]: KnitController},
	CreateService: (service: KnitService) -> KnitService,
	CreateController: (controller: KnitController) -> KnitController,
	AddService: (folder: Instance) -> (),
	AddControllers: (folder: Instance) -> (),
	GetService: (name: string) -> KnitService,
	GetController: (name: string) -> KnitController,
	Start:(self: KnitType) -> any
}

local Knit: KnitType = {
	_services = {},
	_controllers = {}
} :: any

function Knit.CreateService(service: KnitService): KnitService
	assert(service.Name, "Service must have a Name")
	assert(not Knit._services[service.Name], `Service '{service.Name}' already exists`)
	service.Client = service.Client or {}
	Knit._services[service.Name] = service
	return service
end

function Knit.CreateController(controller: KnitController): KnitController
	assert(controller.Name, "Controller must have a Name")
	assert(not Knit._controllers[controller.Name], `Controller '{controller.Name}' already exists`)
	Knit._controllers[controller.Name] = controller
	return controller
end

function Knit.AddService(folder: Instance)
	for _, module in folder:GetDescendants() do
		if module:IsA('ModuleScript') then
			local ok: boolean, service: any = pcall(require, module)
			if ok and service then
				Knit.CreateService(service)
			else
				warn(`Failed to require Service {module.Name}: {service}`)
			end
		end
	end
end

function Knit.AddControllers(folder: Instance)
	for _, module in folder:GetChildren() do
		if module:IsA('ModuleScript') then
			local ok: boolean, controller: any = pcall(require, module)
			if ok and controller then
				Knit.CreateController(controller)
			else
				warn(`Failed to require Controller {module.Name}: {controller}`)
			end
		end
	end
end

function Knit.GetService(name: string): KnitService
	local service = Knit._services[name]
	assert(service, `Service {name} does not exist`)
	return service
end

function Knit.GetController(name: string): KnitController
	local service = Knit._controllers[name]
	assert(service, `Service {name} does not exist`)
	return service
end

function Knit:Start()
	local start = {}
	for _, service in pairs(self._services) do
		if service.KnitInit then service:KnitInit() end
	end

	for _, service in pairs(self._services) do
		if service.KnitStart then task.spawn(function() service:KnitStart() end) end
	end

	for _, controller in pairs(self._controllers) do
		if controller.KnitInit then controller:KnitInit() end
	end

	for _, controller in pairs(self._controllers) do
		if controller.KnitStart then task.spawn(function() controller:KnitStart() end) end
	end

	return true
end

return Knit