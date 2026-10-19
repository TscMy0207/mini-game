extends FrameworkService

var _context: Node
var _resources: Object

func _init() -> void:
	super(&"module_loader")

func initialize(context: Node) -> bool:
	_context = context
	var registry = context.get("services")
	_resources = registry.resolve(&"resources") if registry != null else null
	return _resources != null and super.initialize(context)

# 模块仅通过资源 ID 请求场景，资源服务决定实际路径和热更新版本。
func load_scene(resource_id: StringName) -> PackedScene:
	if resource_id.is_empty() or _resources == null:
		return null
	return _resources.load_packed_scene(resource_id)

func instantiate_scene(resource_id: StringName, parent: Node = null) -> Node:
	var packed := load_scene(resource_id)
	if packed == null:
		return null
	var instance := packed.instantiate()
	if parent != null:
		parent.add_child(instance)
	return instance

func shutdown() -> void:
	_resources = null
	_context = null
	super.shutdown()
