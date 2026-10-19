extends FrameworkService

var root_path := "user://mini_game"
var _context: Node

# 所有存档集中放在 user://mini_game，便于平台层替换底层文件系统实现。
func _init() -> void:
	super(&"storage")

func initialize(context: Node) -> bool:
	_context = context
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path))
	return super.initialize(context)

# 先写临时文件再替换正式文件，避免进程中断导致存档损坏。
func save_json(relative_path: String, value: Variant) -> bool:
	var path := _normalize(relative_path)
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK

func load_json(relative_path: String, fallback: Variant = {}) -> Variant:
	var path := _normalize(relative_path)
	if not FileAccess.file_exists(path):
		return fallback
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	return fallback if parsed == null else parsed

func exists(relative_path: String) -> bool:
	return FileAccess.file_exists(_normalize(relative_path))

func remove(relative_path: String) -> void:
	var path := _normalize(relative_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _normalize(relative_path: String) -> String:
	return root_path.path_join(relative_path.trim_prefix("/").trim_prefix("user://"))
