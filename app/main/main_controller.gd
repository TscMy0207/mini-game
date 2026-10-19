extends Node

const MAIN_MENU_UI_ID := &"main_menu"
const MAIN_MENU_SCENE_ID := &"ui.main_menu"

var services: RefCounted
var ui_root: Control
var interface_layer: Control
var popup_layer: Control
var system_layer: Control
var main_menu: Control

# 主场景只创建运行时挂载点，先显示主界面，用户确认后再加载玩法模块。
func _ready() -> void:
	call_deferred("_assemble_runtime")

func _assemble_runtime() -> void:
	var tree_root := get_tree().root
	services = tree_root.get_meta("framework_services") if tree_root.has_meta("framework_services") else null
	if services == null:
		push_error("主场景控制器：框架服务不可用")
		return
	var ui_service = services.resolve(&"ui")
	if ui_service == null:
		push_error("主场景控制器：必要服务不可用")
		return
	_create_runtime_hosts()
	ui_service.set_root(ui_root)
	_open_main_menu()

func _open_main_menu() -> void:
	var ui_service = services.resolve(&"ui")
	if ui_service == null:
		return
	main_menu = ui_service.open(MAIN_MENU_UI_ID, MAIN_MENU_SCENE_ID) as Control
	if main_menu == null:
		push_error("主场景控制器：主界面加载失败")
		return
	var start_signal: Signal = main_menu.get("start_requested")
	if not start_signal.is_connected(_on_start_requested):
		start_signal.connect(_on_start_requested)

func _on_start_requested() -> void:
	if is_instance_valid(main_menu) and main_menu.has_method("show_framework_ready"):
		main_menu.show_framework_ready()

func _create_runtime_hosts() -> void:
	ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(ui_root)
	# UIRoot 按界面类型拆成独立层，普通界面、弹窗和系统提示互不抢层级。
	interface_layer = _create_ui_layer("InterfaceLayer", 100)
	popup_layer = _create_ui_layer("PopupLayer", 200)
	system_layer = _create_ui_layer("SystemLayer", 300)
	get_viewport().size_changed.connect(_resize_ui_root)
	_resize_ui_root()

func _create_ui_layer(layer_name: String, layer_z: int) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.z_as_relative = false
	layer.z_index = layer_z
	ui_root.add_child(layer)
	return layer

func _resize_ui_root() -> void:
	if is_instance_valid(ui_root):
		ui_root.position = Vector2.ZERO
		ui_root.size = get_viewport().get_visible_rect().size
		for layer in [interface_layer, popup_layer, system_layer]:
			if is_instance_valid(layer):
				layer.position = Vector2.ZERO
				layer.size = ui_root.size

func _exit_tree() -> void:
	if services == null:
		return
	var ui_service = services.resolve(&"ui")
	if ui_service != null:
		ui_service.close_all()
		ui_service.set_root(null)
