--!strict

export type DataTypeInterface<T> = {
  read write: (b: buffer, cursor: number, value: T, references: { unknown }?) -> number,
  read read: (b: buffer, cursor: number, references: { unknown }?) -> (T, number),
  read skip: (b: buffer, cursor: number) -> number,
  read size: (value: T) -> number,
}

export type Connection = {
  connected: boolean,
  read disconnect: (self: Connection) -> (),
  read Disconnect: (self: Connection) -> (),
}

export type EventProps<T> = {
  read value: DataTypeInterface<T>,
  read reliability: ("reliable" | "unreliable")?,
}

export type Event<T> = {
  read fire: (self: Event<T>, data: T) -> (),
  read fireTo: (self: Event<T>, target: Player | { Player }, data: T) -> (),
  read broadcast: (self: Event<T>, data: T) -> (),
  read broadcastExcept: (self: Event<T>, except: Player, data: T) -> (),
  read connect: (self: Event<T>, callback: (data: T, player: Player?) -> ()) -> Connection,
  read once: (self: Event<T>, callback: (data: T, player: Player?) -> ()) -> Connection,
  read wait: (self: Event<T>) -> (T, Player?),
}

export type ProcedureProps<Req, Res> = {
  read request: DataTypeInterface<Req>,
  read response: DataTypeInterface<Res>,
}

export type Procedure<Req, Res> = {
  read call: (self: Procedure<Req, Res>, request: Req) -> Res?,
  read handle: (self: Procedure<Req, Res>, callback: (request: Req, player: Player) -> Res) -> () -> (),
}

export type DefinedEvent<T> = Event<T> & {
  read build: (id: number) -> Event<T>,
}
export type DefinedProcedure<Req, Res> = Procedure<Req, Res> & {
  read build: (id: number) -> Procedure<Req, Res>,
}

export type Octet = {
  read event: <T>(props: EventProps<T>) -> DefinedEvent<T>,
  read procedure: <Req, Res>(props: ProcedureProps<Req, Res>) -> DefinedProcedure<Req, Res>,
  read contract: <T>(schema: T) -> T,

  read int8: DataTypeInterface<number>,
  read int16: DataTypeInterface<number>,
  read int24: DataTypeInterface<number>,
  read int32: DataTypeInterface<number>,

  read uint8: DataTypeInterface<number>,
  read uint16: DataTypeInterface<number>,
  read uint24: DataTypeInterface<number>,
  read uint32: DataTypeInterface<number>,

  read float32: DataTypeInterface<number>,
  read float48: DataTypeInterface<number>,
  read float64: DataTypeInterface<number>,

  read bool: DataTypeInterface<boolean>,
  read str: DataTypeInterface<string>,
  read buff: DataTypeInterface<buffer>,
  read null: DataTypeInterface<nil>,
  read any: DataTypeInterface<unknown>,

  read vec2: DataTypeInterface<Vector2>,
  read vec3: DataTypeInterface<Vector3>,
  read color2: DataTypeInterface<Color3>,
  read color3: DataTypeInterface<Color3>,
  read cframe: DataTypeInterface<CFrame>,

  read optional: <T>(valueType: DataTypeInterface<T>) -> DataTypeInterface<T?>,
  read array: <T>(valueType: DataTypeInterface<T>) -> DataTypeInterface<{ T }>,
  read map: <K, V>(keyType: DataTypeInterface<K>, valueType: DataTypeInterface<V>) -> DataTypeInterface<{ [K]: V }>,
  read struct: <T>(schema: { [string]: DataTypeInterface<unknown> }) -> DataTypeInterface<T>,
}

return table.freeze({})
