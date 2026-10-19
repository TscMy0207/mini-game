class_name FrameworkService
extends RefCounted

var service_id: StringName
var initialized := false

func _init(id: StringName = &"") -> void:
	service_id = id

func initialize(_context: Node) -> bool:
	initialized = true
	return true

func shutdown() -> void:
	initialized = false
