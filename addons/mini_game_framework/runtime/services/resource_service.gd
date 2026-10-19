extends FrameworkService

signal resource_loaded(resource_id: StringName)
signal resource_failed(resource_id: StringName, reason: String)

var catalog: Dictionary = {}
var cache: Dictionary = {}
var catalog_path := "res://content/manifests/resources.json"

# Catalog 保存逻辑资源 ID 到实际路径的映射，业务代码不直接依赖 res:// 路径。
func _init() -> void:
	super(&"resources")

func initialize(context: Node) -> bool:
	var result := super.initialize(context)
	return load_catalog(catalog_path) and result

func load_catalog(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	catalog = parsed
	catalog_path = path
	clear_cache()
	return true

# PCK 挂载后必须清空旧缓存，再重新读取可能被覆盖的资源清单。
func reload_catalog() -> bool:
	return load_catalog(catalog_path)

func has_resource(resource_id: StringName) -> bool:
	return catalog.has(String(resource_id))

func get_path(resource_id: StringName) -> String:
	var definition: Dictionary = catalog.get(String(resource_id), {})
	return str(definition.get("path", ""))

# 先查内存缓存，再从 Catalog 解析并加载资源。
func load_resource(resource_id: StringName) -> Resource:
	if cache.has(resource_id):
		return cache[resource_id]
	var path := get_path(resource_id)
	if path.is_empty():
		resource_failed.emit(resource_id, "资源未注册")
		return null
	var resource := ResourceLoader.load(path)
	if resource == null:
		resource_failed.emit(resource_id, "资源加载失败：" + path)
		return null
	cache[resource_id] = resource
	resource_loaded.emit(resource_id)
	return resource

func load_packed_scene(resource_id: StringName) -> PackedScene:
	return load_resource(resource_id) as PackedScene

# JSON 配置也使用逻辑资源 ID，业务层不再持有 res:// 文件路径。
func load_json(resource_id: StringName, fallback: Variant = {}) -> Variant:
	var path := get_path(resource_id)
	if path.is_empty() or not FileAccess.file_exists(path):
		resource_failed.emit(resource_id, "JSON 文件不存在：" + path)
		return fallback
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		resource_failed.emit(resource_id, "JSON 文件打开失败：" + path)
		return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		resource_failed.emit(resource_id, "JSON 格式无效：" + path)
		return fallback
	resource_loaded.emit(resource_id)
	return parsed

func preload_group(group_id: StringName) -> Array[Resource]:
	var loaded: Array[Resource] = []
	for resource_id in catalog:
		var definition: Dictionary = catalog[resource_id]
		if definition.get("group", "") == String(group_id):
			var resource := load_resource(StringName(resource_id))
			if resource != null:
				loaded.append(resource)
	return loaded

func release(resource_id: StringName) -> void:
	cache.erase(resource_id)

func clear_cache() -> void:
	cache.clear()
