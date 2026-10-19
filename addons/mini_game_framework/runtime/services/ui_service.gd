extends FrameworkService

# 通用 UI 层级：数值越大越靠上，所有动态 UI 统一由 UIService 管理。
const UI_LAYER_INTERFACE := 100
const UI_LAYER_POPUP := 200
const UI_LAYER_SYSTEM := 300

signal ui_opened(ui_id: StringName, instance: Node)
signal ui_closed(ui_id: StringName)

var _root: Node
var _layer_roots: Dictionary = {}
var _resources: Object
var _instances: Dictionary = {}

func _init() -> void:
	super(&"ui")

func initialize(context: Node) -> bool:
	_root = context
	var registry = context.get("services")
	_resources = registry.resolve(&"resources") if registry != null else null
	return _resources != null and super.initialize(context)

# 主场景创建自己的 UI 容器后在此登记，框架服务本身不绑定具体游戏场景。
func set_root(root: Node) -> void:
	_root = root
	_refresh_layer_roots()

func _refresh_layer_roots() -> void:
	_layer_roots.clear()
	if _root == null:
		return
	for layer_name in ["InterfaceLayer", "PopupLayer", "SystemLayer"]:
		var layer := _root.get_node_or_null(NodePath(layer_name))
		if layer != null:
			_layer_roots[layer_name] = layer

func _layer_parent_for(layer: int) -> Node:
	if layer >= UI_LAYER_SYSTEM and _layer_roots.has("SystemLayer"):
		return _layer_roots["SystemLayer"]
	if layer >= UI_LAYER_POPUP and _layer_roots.has("PopupLayer"):
		return _layer_roots["PopupLayer"]
	if _layer_roots.has("InterfaceLayer"):
		return _layer_roots["InterfaceLayer"]
	return _root

# 通用 UI 动态加载入口；同一 ID 重复打开时返回已存在实例。
func open(ui_id: StringName, resource_id: StringName, parent: Node = null, layer: int = UI_LAYER_INTERFACE) -> Node:
	if ui_id.is_empty() or resource_id.is_empty() or _resources == null:
		return null
	var existing: Node = _instances.get(ui_id)
	if is_instance_valid(existing):
		var existing_parent: Node = parent if parent != null else _layer_parent_for(layer)
		if existing_parent != null and existing.get_parent() != existing_parent:
			existing.reparent(existing_parent)
		_apply_layer(existing, layer)
		existing.show()
		return existing
	var packed: PackedScene = _resources.load_packed_scene(resource_id)
	if packed == null:
		push_error("UI 服务：资源加载失败：%s" % resource_id)
		return null
	var instance: Node = packed.instantiate()
	var target_parent: Node = parent if parent != null else _layer_parent_for(layer)
	if target_parent == null:
		instance.free()
		return null
	target_parent.add_child(instance)
	_apply_layer(instance, layer)
	instance.set_meta("ui_service_id", ui_id)
	_instances[ui_id] = instance
	ui_opened.emit(ui_id, instance)
	return instance

func _apply_layer(instance: Node, layer: int) -> void:
	if instance is CanvasItem:
		var canvas_item := instance as CanvasItem
		# 使用全局层级，避免 UI 根节点或玩法节点的相对 z_index 影响弹窗顺序。
		canvas_item.z_as_relative = false
		canvas_item.z_index = layer

func close(ui_id: StringName) -> void:
	var instance: Node = _instances.get(ui_id)
	_instances.erase(ui_id)
	if is_instance_valid(instance):
		instance.queue_free()
	ui_closed.emit(ui_id)

func close_all() -> void:
	for ui_id in _instances.keys().duplicate():
		close(ui_id)

func get_instance(ui_id: StringName) -> Node:
	var instance: Node = _instances.get(ui_id)
	return instance if is_instance_valid(instance) else null

func shutdown() -> void:
	close_all()
	_root = null
	_layer_roots.clear()
	_resources = null
	super.shutdown()
