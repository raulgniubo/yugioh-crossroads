@tool
extends EditorPlugin

var _split: EditorExportPlugin


func _enter_tree() -> void:
	_split = preload("res://addons/crossroads_packs/export_split.gd").new()
	add_export_plugin(_split)


func _exit_tree() -> void:
	if _split:
		remove_export_plugin(_split)
		_split = null
