extends FrameworkService

signal app_paused
signal app_resumed

var platform_id := "desktop"
var capabilities: Dictionary = {
	"touch": true,
	"local_storage": true,
	"remote_assets": true,
	"rewarded_ad": false,
	"share": false,
	"safe_area": true
}
var _last_focus := true

func _init() -> void:
	super(&"platform")

func initialize(context: Node) -> bool:
	platform_id = OS.get_name().to_lower()
	if platform_id == "web":
		capabilities["share"] = false
	return super.initialize(context)

func notify_application_focus(focused: bool) -> void:
	if focused == _last_focus:
		return
	_last_focus = focused
	if focused:
		app_resumed.emit()
	else:
		app_paused.emit()

func get_safe_area(viewport_size: Vector2) -> Rect2:
	return Rect2(Vector2.ZERO, viewport_size)

func has_capability(capability: StringName) -> bool:
	return capabilities.get(capability, false)
