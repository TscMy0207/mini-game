extends FrameworkService

signal check_started
signal check_finished(result: Dictionary)
signal download_progress(pack_id: StringName, progress: float)
signal update_failed(reason: String)

var manifest: Dictionary = {}
var _context: Node
var _request: HTTPRequest

# 更新服务只处理下载、校验和挂载；是否更新由启动流程或平台策略决定。
func _init() -> void:
	super(&"updates")

func initialize(context: Node) -> bool:
	_context = context
	_request = HTTPRequest.new()
	_request.name = "ContentUpdateRequest"
	_context.add_child(_request)
	return super.initialize(context)

func load_local_manifest(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	manifest = parsed if parsed is Dictionary else {}
	return manifest

# Manifest 是更新入口，先确认版本和资源清单，再决定是否下载 PCK。
func check_remote_manifest(url: String) -> Dictionary:
	if _request == null or url.is_empty():
		return {}
	check_started.emit()
	var request_error := _request.request(url)
	if request_error != OK:
		update_failed.emit("请求启动失败：%s" % request_error)
		return {}
	var result = await _request.request_completed
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	if response_code < 200 or response_code >= 300:
		update_failed.emit("版本清单 HTTP 状态异常：%d" % response_code)
		return {}
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		update_failed.emit("版本清单 JSON 格式无效")
		return {}
	manifest = parsed
	check_finished.emit(manifest)
	return manifest

# 下载先写入 .tmp，校验通过后再原子替换，避免中断留下半个资源包。
func download_file(url: String, local_path: String, expected_sha256 := "") -> bool:
	if _request == null or url.is_empty() or local_path.is_empty():
		return false
	var absolute_path := ProjectSettings.globalize_path(local_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	_request.download_file = absolute_path + ".tmp"
	var request_error := _request.request(url)
	if request_error != OK:
		update_failed.emit("下载请求启动失败：%s" % request_error)
		return false
	var result = await _request.request_completed
	var response_code: int = result[1]
	if response_code < 200 or response_code >= 300:
		update_failed.emit("下载 HTTP 状态异常：%d" % response_code)
		return false
	var temp_path := local_path + ".tmp"
	if not FileAccess.file_exists(temp_path):
		update_failed.emit("下载临时文件不存在：" + temp_path)
		return false
	if not expected_sha256.is_empty() and _sha256_file(temp_path) != expected_sha256.to_lower():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		update_failed.emit("SHA-256 校验不一致：" + url)
		return false
	if FileAccess.file_exists(local_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(local_path))
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), absolute_path) != OK:
		update_failed.emit("下载文件提交失败：" + local_path)
		return false
	return true

# PCK 挂载后，ResourceLoader 可以像读取内置资源一样读取其中的内容。
func mount_pck(path: String, replace_files := true) -> bool:
	if not FileAccess.file_exists(path):
		update_failed.emit("PCK 文件不存在：" + path)
		return false
	var mounted := ProjectSettings.load_resource_pack(path, replace_files)
	if not mounted:
		update_failed.emit("PCK 挂载失败：" + path)
	return mounted

# 分块计算 Hash，避免大型资源包一次性读入内存。
func _sha256_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	while not file.eof_reached():
		hashing.update(file.get_buffer(1024 * 1024))
	return hashing.finish().hex_encode()

func shutdown() -> void:
	if is_instance_valid(_request):
		_request.queue_free()
	_request = null
	_context = null
	super.shutdown()
