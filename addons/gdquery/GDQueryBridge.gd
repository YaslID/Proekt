extends Node

var _bridge_cs

func _ready():
	_bridge_cs = load("res://addons/gdquery/csharp/GDQueryBridgeCS.cs")
	if _bridge_cs == null:
		push_error("❌ Не удалось загрузить GDQueryBridgeCS.cs")
		return
	print("✅ GDQueryBridge загружен")

func execute(provider: String, conn_string: String, sql: String, params: Dictionary, tx_handle: String = "") -> int:
	if _bridge_cs == null:
		return -1
	return _bridge_cs.Execute(provider, conn_string, sql, params, tx_handle)

func scalar(provider: String, conn_string: String, sql: String, params: Dictionary, tx_handle: String = "") -> Variant:
	if _bridge_cs == null:
		return null
	return _bridge_cs.Scalar(provider, conn_string, sql, params, tx_handle)

func query(provider: String, conn_string: String, sql: String, params: Dictionary, tx_handle: String = "") -> Array:
	if _bridge_cs == null:
		return []
	return _bridge_cs.Query(provider, conn_string, sql, params, tx_handle)

func begin_transaction(provider: String, conn_string: String) -> String:
	if _bridge_cs == null:
		return ""
	return _bridge_cs.BeginTransaction(provider, conn_string)

func commit_transaction(tx_handle: String) -> bool:
	if _bridge_cs == null:
		return false
	return _bridge_cs.CommitTransaction(tx_handle)

func rollback_transaction(tx_handle: String) -> bool:
	if _bridge_cs == null:
		return false
	return _bridge_cs.RollbackTransaction(tx_handle)