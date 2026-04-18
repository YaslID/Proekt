extends RefCounted

var _bridge
var _handle: String
var _provider: String
var _connection_string: String

func _init(provider: String, connection_string: String, bridge):
	_bridge = bridge
	_provider = provider
	_connection_string = connection_string

func begin() -> bool:
	if _bridge == null:
		return false
	_handle = await _bridge.begin_transaction(_provider, _connection_string)
	return _handle != ""

func commit() -> bool:
	if _bridge == null or _handle == "":
		return false
	return await _bridge.commit_transaction(_handle)

func rollback() -> bool:
	if _bridge == null or _handle == "":
		return false
	return await _bridge.rollback_transaction(_handle)

func query(sql: String, parameters: Dictionary = {}) -> Array:
	if _bridge == null or _handle == "":
		return []
	return await _bridge.query(_provider, _connection_string, sql, parameters, _handle)

func execute(sql: String, parameters: Dictionary = {}) -> int:
	if _bridge == null or _handle == "":
		return -1
	return await _bridge.execute(_provider, _connection_string, sql, parameters, _handle)

func scalar(sql: String, parameters: Dictionary = {}) -> Variant:
	if _bridge == null or _handle == "":
		return null
	return await _bridge.scalar(_provider, _connection_string, sql, parameters, _handle)