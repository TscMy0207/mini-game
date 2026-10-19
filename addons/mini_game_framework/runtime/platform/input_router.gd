extends Node

signal pointer_pressed(position: Vector2, pointer_id: int)
signal pointer_released(position: Vector2, pointer_id: int)
signal pointer_moved(position: Vector2, pointer_id: int)
signal key_pressed(keycode: Key)

var last_pointer_position := Vector2.ZERO

# 全屏 UI 使用 PASS 时，部分宿主会在 GUI 分发阶段消费事件；在 _input 广播可保证玩法拖拽始终收到触摸和鼠标。
# 路由不调用 set_input_as_handled，因此 UI 按钮仍可继续接收同一事件。
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		last_pointer_position = event.position
		if event.pressed:
			pointer_pressed.emit(event.position, 0)
		else:
			pointer_released.emit(event.position, 0)
	elif event is InputEventMouseMotion:
		last_pointer_position = event.position
		pointer_moved.emit(event.position, 0)
	elif event is InputEventScreenTouch:
		last_pointer_position = event.position
		if event.pressed:
			pointer_pressed.emit(event.position, event.index)
		else:
			pointer_released.emit(event.position, event.index)
	elif event is InputEventScreenDrag:
		last_pointer_position = event.position
		pointer_moved.emit(event.position, event.index)
	elif event is InputEventKey and event.pressed and not event.echo:
		key_pressed.emit(event.keycode)
