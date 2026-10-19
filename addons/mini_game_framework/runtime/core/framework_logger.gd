extends RefCounted

signal entry_added(entry: Dictionary)

const MAX_ENTRIES := 500
var entries: Array[Dictionary] = []
var minimum_level := 0

func log_info(message: String, context: Dictionary = {}) -> void:
	_log(0, "INFO", message, context)

func log_warning(message: String, context: Dictionary = {}) -> void:
	_log(1, "WARN", message, context)

func log_error(message: String, context: Dictionary = {}) -> void:
	_log(2, "ERROR", message, context)

func _log(level: int, label: String, message: String, context: Dictionary) -> void:
	if level < minimum_level:
		return
	var entry := {
		"time": Time.get_datetime_string_from_system(true),
		"level": label,
		"message": message,
		"context": context.duplicate(true)
	}
	entries.append(entry)
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()
	match level:
		0:
			print("[", label, "] ", message)
		1:
			push_warning(message)
		2:
			push_error(message)
	entry_added.emit(entry)

func clear() -> void:
	entries.clear()

func export_json() -> String:
	return JSON.stringify(entries)
