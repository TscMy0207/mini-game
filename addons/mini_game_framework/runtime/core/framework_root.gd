extends Node2D

const ServiceRegistryScript = preload("res://addons/mini_game_framework/runtime/core/service_registry.gd")
const FrameworkLoggerScript = preload("res://addons/mini_game_framework/runtime/core/framework_logger.gd")
const FrameworkModuleLoaderScript = preload("res://addons/mini_game_framework/runtime/core/module_loader.gd")
const FrameworkSceneFlowScript = preload("res://addons/mini_game_framework/runtime/core/scene_flow.gd")
const FrameworkPlatformServiceScript = preload("res://addons/mini_game_framework/runtime/platform/platform_service.gd")
const FrameworkPlatformBridgeScript = preload("res://addons/mini_game_framework/runtime/platform/platform_bridge.gd")
const FrameworkStorageServiceScript = preload("res://addons/mini_game_framework/runtime/services/storage_service.gd")
const FrameworkConfigServiceScript = preload("res://addons/mini_game_framework/runtime/services/config_service.gd")
const FrameworkResourceServiceScript = preload("res://addons/mini_game_framework/runtime/services/resource_service.gd")
const FrameworkUpdateServiceScript = preload("res://addons/mini_game_framework/runtime/update/update_service.gd")
const FrameworkAudioServiceScript = preload("res://addons/mini_game_framework/runtime/services/audio_service.gd")
const FrameworkLocalizationServiceScript = preload("res://addons/mini_game_framework/runtime/services/localization_service.gd")
const FrameworkEventBusScript = preload("res://addons/mini_game_framework/runtime/core/event_bus.gd")
const FrameworkObjectPoolScript = preload("res://addons/mini_game_framework/runtime/core/object_pool.gd")
const FrameworkInputRouterScript = preload("res://addons/mini_game_framework/runtime/platform/input_router.gd")
const FrameworkUIServiceScript = preload("res://addons/mini_game_framework/runtime/services/ui_service.gd")

var services: RefCounted
var logger: RefCounted
var startup_ok := false
var _shutdown_started := false

# FrameworkRoot 由启动场景动态创建，并挂到 SceneTree 根节点以跨场景存活。
func _ready() -> void:
	initialize_framework()

func initialize_framework() -> bool:
	if services != null:
		return startup_ok
	logger = FrameworkLoggerScript.new()
	services = ServiceRegistryScript.new()
	services.register(&"logger", logger)
	services.register(&"platform", FrameworkPlatformServiceScript.new())
	services.register(&"platform_bridge", FrameworkPlatformBridgeScript.new())
	services.register(&"storage", FrameworkStorageServiceScript.new())
	services.register(&"config", FrameworkConfigServiceScript.new())
	services.register(&"resources", FrameworkResourceServiceScript.new())
	services.register(&"updates", FrameworkUpdateServiceScript.new())
	services.register(&"audio", FrameworkAudioServiceScript.new())
	services.register(&"localization", FrameworkLocalizationServiceScript.new())
	services.register(&"events", FrameworkEventBusScript.new())
	services.register(&"object_pool", FrameworkObjectPoolScript.new())
	services.register(&"ui", FrameworkUIServiceScript.new())
	var input_router := FrameworkInputRouterScript.new()
	input_router.name = "InputRouter"
	add_child(input_router)
	services.register(&"input", input_router)
	services.register(&"module_loader", FrameworkModuleLoaderScript.new())
	services.register(&"scene_flow", FrameworkSceneFlowScript.new())
	services.service_failed.connect(_on_service_failed)
	startup_ok = services.initialize_all(self)
	set_meta("framework_services", services)
	set_meta("framework_ready", startup_ok)
	var tree_root := get_tree().root
	tree_root.set_meta("framework_services", services)
	tree_root.set_meta("framework_root", self)
	if startup_ok:
		logger.log_info("框架启动完成", {"services": services.snapshot_ids()})
	else:
		logger.log_error("框架启动失败")
	return startup_ok

func _notification(what: int) -> void:
	if services == null or not services.has(&"platform"):
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		services.resolve(&"platform").notify_application_focus(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		services.resolve(&"platform").notify_application_focus(false)

func _on_service_failed(service_id: StringName, reason: String) -> void:
	if logger != null:
		logger.log_error("服务初始化失败", {"service": service_id, "reason": reason})

func _exit_tree() -> void:
	if _shutdown_started:
		return
	_shutdown_started = true
	if get_tree() != null and get_tree().root != null:
		var tree_root := get_tree().root
		if tree_root.has_meta("framework_root") and tree_root.get_meta("framework_root") == self:
			tree_root.remove_meta("framework_root")
			if tree_root.has_meta("framework_services"):
				tree_root.remove_meta("framework_services")
	if services != null:
		services.shutdown_all()
