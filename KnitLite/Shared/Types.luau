--!strict
export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> ()
}

export type _ConnectionEntry<T...> = {
	fn: (T...) -> (),
	conn: Connection
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> (T...),
	Destroy: (self: Signal<T...>) -> (),
	_connections: {_ConnectionEntry<T...>}
}

export type Promise<T> = {
	_status: 'Pending'|'Resolved'|'Rejected',
	_value: any,
	_callbacks: { (T) -> () },
	_errbacks: { (any) -> () },
	andThen:(self: Promise<T>, fn: (T) -> any) -> Promise<T>,
	catch: (self: Promise<T>, fn: (any) -> any) -> Promise<T>,
	finally: (self: Promise<T>, fn: () -> ()) -> Promise<T>,
}

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

return {}