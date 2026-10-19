extends RefCounted

signal service_initialized(service_id: StringName)
signal service_failed(service_id: StringName, reason: String)

var _services: Dictionary = {}
var _initialized := false

# 服务只通过逻辑 ID 注册，业务层不需要知道具体实现类。
func register(service_id: StringName, service: Object) -> void:
	if service == null:
		push_error("不能注册空服务：%s" % service_id)
		return
	_services[service_id] = service

func has(service_id: StringName) -> bool:
	return _services.has(service_id)

func resolve(service_id: StringName) -> Object:
	return _services.get(service_id)

# 按注册顺序初始化服务；任一服务失败时仍继续初始化其余服务，最后统一返回结果。
func initialize_all(context: Node) -> bool:
	if _initialized:
		return true
	var success := true
	for service_id in _services:
		var service: Object = _services[service_id]
		if not service.has_method("initialize"):
			continue
		var result = service.initialize(context)
		if result == false:
			success = false
			service_failed.emit(service_id, "初始化返回 false")
		else:
			service_initialized.emit(service_id)
	_initialized = success
	return success

# 关闭时逆序释放，尽量满足服务之间的依赖关系。
func shutdown_all() -> void:
	var ids := _services.keys()
	ids.reverse()
	for service_id in ids:
		var service: Object = _services[service_id]
		if service.has_method("shutdown"):
			service.shutdown()
	_initialized = false

func snapshot_ids() -> Array[StringName]:
	return Array(_services.keys(), TYPE_STRING_NAME, &"", null)
