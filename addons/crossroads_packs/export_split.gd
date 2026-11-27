@tool
extends EditorExportPlugin
## The base and the small game pack.
##
## The game ships as two packs. The BASE (base.pck) holds the big things that rarely change, the
## voices and the 3D models, and is downloaded once. The GAME pack (Crossroads.pck, the one the
## program opens by itself) holds everything else AND every voice or model that is new or changed
## since the base was made, so it is the whole update, from any older version.
##
## What an export writes is chosen with the environment variable CR_PACK:
##   (not set)  everything in one pack, as before
##   base       only the base files; writes tools/dev/base_manifest.json (what the base holds;
##              make_release.sh then adds the size of the finished file to it)
##   main       everything except the base files that are still the same as in the manifest
## tools/dev/make_release.sh runs the three steps. scripts/core/packs.gd loads the base in the game.

const MANIFEST := "res://tools/dev/base_manifest.json"
## What belongs in a base: the big folders.
const BASE_DIRS := ["res://voices/", "res://assets/models/"]

var _mode := ""
var _base_id := 0
var _known := {}        # main: path -> hash, from the manifest
var _made := {}         # base: path -> hash, as they are written
var _kept := 0
var _left := 0
var _bytes_left := 0


func _get_name() -> String:
	return "CrossroadsPacks"


static func is_base_path(path: String) -> bool:
	for d in BASE_DIRS:
		if path.begins_with(d):
			return true
	return false


## A file is the same file when its bytes and the way it is imported are the same.
static func stamp(path: String) -> String:
	var s := FileAccess.get_md5(path)
	if FileAccess.file_exists(path + ".import"):
		s += ":" + FileAccess.get_md5(path + ".import")
	return s


func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	_mode = OS.get_environment("CR_PACK")
	_known = {}
	_made = {}
	_kept = 0
	_left = 0
	_bytes_left = 0
	_base_id = 0
	if _mode == "":
		return
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	if _mode == "base":
		_base_id = int(OS.get_environment("CR_BASE_ID"))
		if _base_id <= 0:
			push_error("CrossroadsPacks: CR_BASE_ID is not set for a base export")
		add_file("res://base_info.json", JSON.stringify({"base": _base_id, "made_with": version}).to_utf8_buffer(), false)
	elif _mode == "main":
		var f := FileAccess.open(MANIFEST, FileAccess.READ)
		if f == null:
			push_error("CrossroadsPacks: no base manifest at %s, make a base first" % MANIFEST)
			return
		var data: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if not (data is Dictionary):
			push_error("CrossroadsPacks: the base manifest cannot be read")
			return
		_base_id = int(data.get("base", 0))
		_known = data.get("files", {})
		var gone := []
		for p in _known:
			if not FileAccess.file_exists(str(p)):
				gone.append(str(p))
		gone.sort()
		add_file("res://pack_info.json", JSON.stringify({"split": true, "base": _base_id, "base_bytes": int(data.get("bytes", 0)), "version": version, "gone": gone}).to_utf8_buffer(), false)
	print("CrossroadsPacks: ", _mode, " export, base ", _base_id, " (", " ".join(features), ")")


func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if _mode == "base":
		if is_base_path(path):
			_made[path] = stamp(path)
			_kept += 1
		else:
			skip()
	elif _mode == "main":
		if _known.has(path) and str(_known[path]) == stamp(path):
			_left += 1
			skip()
		elif is_base_path(path):
			_kept += 1
			print("CrossroadsPacks: in the update: ", path)


func _export_end() -> void:
	if _mode == "base":
		var f := FileAccess.open(MANIFEST, FileAccess.WRITE)
		f.store_string(JSON.stringify({"base": _base_id, "made_with": str(ProjectSettings.get_setting("application/config/version", "")), "files": _made}, "", true))
		f.close()
		print("CrossroadsPacks: base ", _base_id, " holds ", _kept, " files; manifest written")
	elif _mode == "main":
		print("CrossroadsPacks: ", _left, " files stay in the base, ", _kept, " voices or models travel in the update")
	_mode = ""
