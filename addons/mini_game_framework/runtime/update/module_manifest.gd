extends RefCounted

var schema := 1
var app_version := "0.1.0"
var framework_version := "0.1.0"
var engine_version := "4.7.2"
var platform := "desktop"
var packs: Array[Dictionary] = []

static func from_dictionary(data: Dictionary) -> FrameworkModuleManifest:
	var result := FrameworkModuleManifest.new()
	result.schema = int(data.get("schema", 1))
	result.app_version = str(data.get("app_version", "0.0.0"))
	result.framework_version = str(data.get("framework_version", "0.0.0"))
	result.engine_version = str(data.get("engine_version", ""))
	result.platform = str(data.get("platform", "desktop"))
	var raw_packs = data.get("packs", [])
	if raw_packs is Array:
		for pack in raw_packs:
			if pack is Dictionary:
				result.packs.append(pack)
	return result

func is_compatible(target_platform: String, target_engine: String) -> bool:
	return (platform == target_platform or platform == "all") and (engine_version.is_empty() or engine_version == target_engine)
