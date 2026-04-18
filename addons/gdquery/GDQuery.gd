extends Node

var GDBridge

func _ready():
	# Ждём, пока загрузится GDBridge
	await get_tree().process_frame
	GDBridge = get_node("/root/GDBridge")
	if GDBridge == null:
		push_error("❌ GDBridge не найден!")
		return
	print("✅ GDQuery инициализирован")

func query_async(provider: String, connection_string: String, query: String, parameters: Dictionary = {}) -> Array:
	if GDBridge == null:
		return []
	return await GDBridge.query(provider, connection_string, query, parameters, "")

func execute_async(provider: String, connection_string: String, query: String, parameters: Dictionary = {}) -> int:
	if GDBridge == null:
		return -1
	return await GDBridge.execute(provider, connection_string, query, parameters, "")

func scalar_async(provider: String, connection_string: String, query: String, parameters: Dictionary = {}) -> Variant:
	if GDBridge == null:
		return null
	return await GDBridge.scalar(provider, connection_string, query, parameters, "")

func begin_transaction_async(provider: String, connection_string: String) -> String:
	if GDBridge == null:
		return ""
	return await GDBridge.begin_transaction(provider, connection_string)

func commit_transaction_async(handle: String) -> bool:
	if GDBridge == null:
		return false
	return await GDBridge.commit_transaction(handle)

func rollback_transaction_async(handle: String) -> bool:
	if GDBridge == null:
		return false
	return await GDBridge.rollback_transaction(handle)