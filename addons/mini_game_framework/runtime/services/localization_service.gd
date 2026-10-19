extends FrameworkService

signal locale_changed(locale: StringName)

var locale: StringName = &"zh-CN"
var fallback_locale: StringName = &"en-US"
var tables: Dictionary = {}

func _init() -> void:
	super(&"localization")

func initialize(context: Node) -> bool:
	load_table(&"zh-CN", "res://content/manifests/localization_zh-CN.json")
	load_table(&"en-US", "res://content/manifests/localization_en-US.json")
	return super.initialize(context)

func load_table(table_locale: StringName, path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return false
	tables[table_locale] = data
	return true

func set_locale(next_locale: StringName) -> void:
	if locale == next_locale:
		return
	locale = next_locale
	locale_changed.emit(locale)

func text(key: StringName, fallback := "") -> String:
	var current: Dictionary = tables.get(locale, {})
	if current.has(key):
		return str(current[key])
	var fallback_table: Dictionary = tables.get(fallback_locale, {})
	return str(fallback_table.get(key, fallback))
