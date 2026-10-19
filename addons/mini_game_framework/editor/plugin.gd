@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("MiniGameFramework", "res://addons/mini_game_framework/runtime/core/framework_root.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("MiniGameFramework")
