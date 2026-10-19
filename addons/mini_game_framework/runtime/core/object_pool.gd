extends FrameworkService

var _context: Node
var _pools: Dictionary = {}

# 池中的节点在 available/active 两个集合之间切换，避免频繁实例化和释放。
func _init() -> void:
	super(&"object_pool")

func initialize(context: Node) -> bool:
	_context = context
	return super.initialize(context)

func shutdown() -> void:
	for pool_id in _pools.keys().duplicate():
		clear(pool_id)
	_pools.clear()
	_context = null

func configure(pool_id: StringName, scene: PackedScene, initial_size := 0) -> void:
	_pools[pool_id] = {"scene": scene, "available": [], "active": []}
	for index in range(initial_size):
		var instance := _create(pool_id)
		if instance != null:
			_release_instance(pool_id, instance)

func acquire(pool_id: StringName, parent: Node = null) -> Node:
	if not _pools.has(pool_id):
		return null
	var pool: Dictionary = _pools[pool_id]
	var instance: Node = pool["available"].pop_back() if not pool["available"].is_empty() else _create(pool_id)
	if instance == null:
		return null
	var target_parent := parent if parent != null else _context
	if instance.get_parent() != target_parent:
		if instance.get_parent() != null:
			instance.get_parent().remove_child(instance)
		if target_parent != null:
			target_parent.add_child(instance)
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	pool["active"].append(instance)
	if instance.has_method("on_pool_acquired"):
		instance.call("on_pool_acquired")
	return instance

func release(pool_id: StringName, instance: Node) -> void:
	if not _pools.has(pool_id) or instance == null:
		return
	_release_instance(pool_id, instance)

func clear(pool_id: StringName) -> void:
	if not _pools.has(pool_id):
		return
	var pool: Dictionary = _pools[pool_id]
	for instance in pool["available"] + pool["active"]:
		if is_instance_valid(instance):
			instance.queue_free()
	_pools.erase(pool_id)

func _create(pool_id: StringName) -> Node:
	var pool: Dictionary = _pools.get(pool_id, {})
	var scene: PackedScene = pool.get("scene")
	return scene.instantiate() if scene != null else null

func _release_instance(pool_id: StringName, instance: Node) -> void:
	var pool: Dictionary = _pools[pool_id]
	pool["active"].erase(instance)
	pool["available"].append(instance)
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance.has_method("reset_for_pool"):
		instance.call("reset_for_pool")
	if instance.get_parent() != null:
		instance.get_parent().remove_child(instance)
