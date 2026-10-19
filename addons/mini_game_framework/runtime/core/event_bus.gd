extends FrameworkService

signal event_emitted(event_name: StringName, payload: Dictionary)

func _init() -> void:
	super(&"events")

func publish(event_name: StringName, payload: Dictionary = {}) -> void:
	event_emitted.emit(event_name, payload)

func subscribe(event_name: StringName, listener: Callable) -> void:
	if not event_emitted.is_connected(listener):
		event_emitted.connect(func(name: StringName, payload: Dictionary) -> void:
			if name == event_name:
				listener.call(payload)
		)
