extends Node

const FrameworkRootScript = preload("res://addons/mini_game_framework/runtime/core/framework_root.gd")
const BOOT_LOADING_SCENE_PATH := "res://app/bootstrap/presentation/loading_ui.tscn"
const BOOT_CONFIG_PATH := "res://app/config/bootstrap_config.json"
const LOCAL_MANIFEST_PATH := "res://content/manifests/content_manifest.json"
const MAIN_SCENE_ID := &"scene.main"

var framework_root: Node
var services: RefCounted
var loading_ui: Control
var _boot_running := false

# 启动层不经过通用 UI 服务，保证框架服务尚未就绪时也能展示进度和错误。
func _ready() -> void:
	call_deferred("_start_boot")

func _start_boot() -> void:
	if _boot_running:
		return
	_boot_running = true
	loading_ui = _create_loading_ui()
	if loading_ui == null:
		push_error("启动流程：LoadingUI 创建失败")
		return
	loading_ui.retry_requested.connect(_on_retry_requested)
	await get_tree().process_frame
	_set_progress(0.04, "正在启动", "正在创建运行环境")
	if not await _create_framework():
		_show_failure("基础服务初始化失败")
		return
	var boot_config := _read_boot_config()
	_set_progress(0.20, "正在检查版本", "读取本地内容清单")
	if not await _prepare_content(boot_config):
		return
	_set_progress(0.76, "正在刷新内容", "应用资源清单与配置")
	var resources = services.resolve(&"resources")
	var config = services.resolve(&"config")
	if resources == null or not resources.reload_catalog():
		_show_failure("资源清单加载失败")
		return
	if config != null and not config.reload_all():
		_show_failure("配置表加载失败")
		return
	_set_progress(0.86, "正在预加载", "准备主场景")
	resources.preload_group(&"startup")
	await get_tree().process_frame
	var main_scene: PackedScene = resources.load_packed_scene(MAIN_SCENE_ID)
	if main_scene == null:
		_show_failure("主场景资源不可用")
		return
	_set_progress(1.0, "正在进入游戏", "加载完成")
	await get_tree().create_timer(0.12).timeout
	var scene_flow = services.resolve(&"scene_flow")
	if scene_flow == null or scene_flow.change_scene_resource(main_scene, MAIN_SCENE_ID) != OK:
		_show_failure("主场景切换失败")

func _create_loading_ui() -> Control:
	var packed := ResourceLoader.load(BOOT_LOADING_SCENE_PATH) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate() as Control
	if instance == null:
		return null
	add_child(instance)
	return instance

func _create_framework() -> bool:
	if is_instance_valid(framework_root):
		framework_root.queue_free()
		await get_tree().process_frame
	framework_root = FrameworkRootScript.new()
	framework_root.name = "FrameworkRuntime"
	get_tree().root.add_child(framework_root)
	await get_tree().process_frame
	if not framework_root.startup_ok:
		return false
	var tree_root := get_tree().root
	services = tree_root.get_meta("framework_services") if tree_root.has_meta("framework_services") else null
	return services != null

func _prepare_content(boot_config: Dictionary) -> bool:
	var updates = services.resolve(&"updates")
	var storage = services.resolve(&"storage")
	if updates == null:
		_show_failure("更新服务不可用")
		return false
	var manifest: Dictionary = updates.load_local_manifest(LOCAL_MANIFEST_PATH)
	if manifest.is_empty():
		_show_failure("本地内容清单无效")
		return false
	var remote_url := str(boot_config.get("remote_manifest_url", "")).strip_edges()
	var allow_offline := bool(boot_config.get("allow_offline_start", true))
	if not remote_url.is_empty():
		_set_progress(0.30, "正在检查更新", "连接内容服务器")
		var remote_manifest: Dictionary = await updates.check_remote_manifest(remote_url)
		if remote_manifest.is_empty():
			var cached_manifest = storage.load_json("updates/content_manifest.json", {}) if storage != null else {}
			if cached_manifest is Dictionary and not cached_manifest.is_empty():
				manifest = cached_manifest
			elif not allow_offline:
				_show_failure("无法获取更新清单")
				return false
		else:
			manifest = remote_manifest
			if storage != null:
				storage.save_json("updates/content_manifest.json", manifest)
	_set_progress(0.46, "正在同步内容", "检查资源包版本")
	if not await _mount_content_packs(manifest, remote_url):
		_show_failure("内容资源包更新失败")
		return false
	return true

# 资源包以版本号命名缓存；新版本下载完成后再挂载，避免启动时读取半个文件。
func _mount_content_packs(manifest: Dictionary, remote_manifest_url: String) -> bool:
	var packs = manifest.get("packs", [])
	if not packs is Array:
		return false
	if packs.is_empty():
		_set_progress(0.66, "正在同步内容", "当前内容已是最新")
		return true
	var updates = services.resolve(&"updates")
	for index in range(packs.size()):
		var pack: Dictionary = packs[index]
		var pack_id := str(pack.get("id", "content"))
		var version := str(pack.get("version", "0"))
		var source_url := str(pack.get("url", ""))
		var cache_path := "user://mini_game/content/%s_%s.pck" % [pack_id, version]
		var progress := lerpf(0.48, 0.68, float(index) / maxf(1.0, float(packs.size())))
		_set_progress(progress, "正在下载内容", "同步 %s" % pack_id)
		if not remote_manifest_url.is_empty() and not FileAccess.file_exists(cache_path):
			var pack_url := _resolve_pack_url(remote_manifest_url, source_url)
			if pack_url.is_empty() or not await updates.download_file(pack_url, cache_path, str(pack.get("sha256", ""))):
				return false
		if FileAccess.file_exists(cache_path):
			if not updates.mount_pck(cache_path, true):
				return false
			_log_info("内容包已挂载", {"id": pack_id, "version": version, "source": "cache"})
		elif source_url.begins_with("res://"):
			if not updates.mount_pck(source_url, true):
				return false
			_log_info("内容包已挂载", {"id": pack_id, "version": version, "source": "built_in"})
	return true

func _resolve_pack_url(manifest_url: String, pack_url: String) -> String:
	if pack_url.begins_with("http://") or pack_url.begins_with("https://"):
		return pack_url
	if pack_url.is_empty():
		return ""
	return manifest_url.get_base_dir().path_join(pack_url)

func _read_boot_config() -> Dictionary:
	if not FileAccess.file_exists(BOOT_CONFIG_PATH):
		return {}
	var file := FileAccess.open(BOOT_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _set_progress(progress: float, title: String, detail: String) -> void:
	if is_instance_valid(loading_ui):
		loading_ui.set_progress(progress, title, detail)

func _show_failure(reason: String) -> void:
	_boot_running = false
	if is_instance_valid(loading_ui):
		loading_ui.show_failure(reason)
	else:
		push_error("启动流程：" + reason)

func _log_info(message: String, context: Dictionary) -> void:
	if services != null:
		var logger = services.resolve(&"logger")
		if logger != null:
			logger.log_info(message, context)

func _on_retry_requested() -> void:
	call_deferred("_start_boot")
