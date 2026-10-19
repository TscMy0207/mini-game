extends FrameworkService

signal table_loaded(table_id: StringName)
signal table_failed(table_id: StringName, reason: String)

var tables: Dictionary = {}
var table_paths: Dictionary = {}

# 配置表运行时只读；热更新时替换表数据，不让业务代码持有文件句柄。
func _init() -> void:
	super(&"config")

func initialize(context: Node) -> bool:
	var result := super.initialize(context)
	load_builtin_table("framework", "res://content/manifests/framework.json")
	return result

func register_table(table_id: StringName, path: String) -> void:
	table_paths[table_id] = path

func load_builtin_table(table_id: StringName, path: String) -> bool:
	if not FileAccess.file_exists(path):
		table_failed.emit(table_id, "文件不存在：" + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		table_failed.emit(table_id, "文件无法打开：" + path)
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		table_failed.emit(table_id, "JSON 格式无效")
		return false
	tables[table_id] = parsed
	table_paths[table_id] = path
	table_loaded.emit(table_id)
	return true

func get_table(table_id: StringName, fallback: Variant = {}) -> Variant:
	return tables.get(table_id, fallback)

func get_row(table_id: StringName, key: String, fallback: Variant = {}) -> Variant:
	var table = tables.get(table_id)
	if not table is Dictionary:
		return fallback
	return table.get(key, fallback)

func reload_all() -> bool:
	var success := true
	for table_id in table_paths.keys():
		success = load_builtin_table(table_id, str(table_paths[table_id])) and success
	return success
