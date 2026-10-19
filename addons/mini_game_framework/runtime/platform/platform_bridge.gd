extends FrameworkService

signal callback_received(name: StringName, payload: Dictionary)

var handlers: Dictionary = {}

func _init() -> void:
	super(&"platform_bridge")

func register_handler(name: StringName, handler: Callable) -> void:
	handlers[name] = handler

func call_platform(name: StringName, payload: Dictionary = {}) -> Variant:
	if handlers.has(name):
		return handlers[name].call(payload)
	return null

func emit_platform_callback(name: StringName, payload: Dictionary = {}) -> void:
	callback_received.emit(name, payload)
