extends FrameworkService

signal scene_changing(from_path: String, to_path: String)
signal scene_changed(path: String)

var _tree: SceneTree
var _current_path := ""

func _init() -> void:
	super(&"scene_flow")

func initialize(context: Node) -> bool:
	_tree = context.get_tree()
	_current_path = _tree.current_scene.scene_file_path if _tree.current_scene else ""
	return super.initialize(context)

func change_scene(scene_path: String) -> Error:
	if _tree == null or scene_path.is_empty():
		return ERR_UNCONFIGURED
	scene_changing.emit(_current_path, scene_path)
	var error := _tree.change_scene_to_file(scene_path)
	if error == OK:
		_current_path = scene_path
		scene_changed.emit(scene_path)
	return error

# 启动流程已经通过资源服务拿到场景，切换阶段不再重复按路径加载。
func change_scene_resource(scene: PackedScene, logical_id: StringName = &"") -> Error:
	if _tree == null or scene == null:
		return ERR_UNCONFIGURED
	scene_changing.emit(_current_path, String(logical_id))
	var error := _tree.change_scene_to_packed(scene)
	if error == OK:
		_current_path = String(logical_id)
		scene_changed.emit(_current_path)
	return error

func current_path() -> String:
	return _current_path
