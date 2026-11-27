extends Node
## The game's two packs (0.82.0). The FIRST autoload: it has to run before anything asks for a voice
## or a model.
##
## A build comes in two files. The game pack (Crossroads.pck, opened by the program itself) holds
## the code, the cards, the menus, and every voice or model that is new or changed since the base
## was made. The base (base.pck) holds the big things that rarely change, the voices and the 3D
## models, and is downloaded once. An update is a new game pack: small, and good from any older
## version. See addons/crossroads_packs/export_split.gd for how the two are made.
##
## Here the base is found and opened. What the game pack holds wins, so a voice that was redone
## after the base plays in its new form. When the base is not there, or is older than the one this
## version was made for, the game says so in plain words (PacksNotice) instead of opening half empty.
##
## A build made as one pack (CR_PACK not set), the editor and the tests have no pack_info.json:
## nothing happens here then.

const INFO := "res://pack_info.json"
const BASE_INFO := "res://base_info.json"
const BASE_FILE := "base.pck"

var split := false          ## this build is the small game pack and needs a base beside it
var base_needed := 0        ## the base this version was made for
var base_found := 0         ## the base that was opened (0 = none)
var base_path := ""         ## where it was found
var problem := ""           ## "" all good | "missing" | "old" | "broken"
var gone := {}              ## files the base still holds that the game no longer has


func _init() -> void:
	_open_base()


func _ready() -> void:
	if problem != "":
		# After every autoload is in and the first scene is up: it is taken down and the notice stands alone.
		_show_notice.call_deferred()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--packs-check"):
			_dev_check.call_deferred(a.trim_prefix("--packs-check").trim_prefix("="))


## True for a file the game should use. A voice or model that was taken out of the game after the
## base was made is still inside the base file; this is how the game knows to leave it alone.
func has(path: String) -> bool:
	return not gone.has(path) and ResourceLoader.exists(path)


## The folders the base is looked for in, in order: beside the game (on a Mac, beside the app),
## in Crossroads Data, and beside the program itself.
func places() -> PackedStringArray:
	var out := PackedStringArray()
	var game := Saves.game_dir()
	out.append(game)
	out.append(game.path_join(Saves.DATA_NAME))
	var exe := OS.get_executable_path().get_base_dir()
	if not out.has(exe):
		out.append(exe)
	if OS.get_name() == "macOS":
		out.append(exe.get_base_dir().path_join("Resources"))
	return out


## Where the player is told to put the base: the first place it is looked for that already exists.
func home() -> String:
	if OS.get_name() == "macOS":
		var data := Saves.game_dir().path_join(Saves.DATA_NAME)
		if DirAccess.dir_exists_absolute(data):
			return data
	return Saves.game_dir()


func _open_base() -> void:
	if not FileAccess.file_exists(INFO):
		return
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(INFO))
	if not (info is Dictionary) or not bool(info.get("split", false)):
		return
	split = true
	base_needed = int(info.get("base", 0))
	var whole := int(info.get("base_bytes", 0))
	for p in info.get("gone", []):
		gone[str(p)] = true
	var found := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--base="):
			found = a.trim_prefix("--base=")      # dev: use this base file
	if found == "":
		for d in places():
			var f := d.path_join(BASE_FILE)
			if FileAccess.file_exists(f):
				found = f
				break
	if found == "":
		problem = "missing"
		print("PACKS no base.pck in ", ", ".join(places()))
		return
	base_path = found
	# false: what the game pack already holds stays (it is newer than the base).
	if not ProjectSettings.load_resource_pack(found, false):
		problem = "broken"
		print("PACKS the base at ", found, " cannot be opened")
		return
	var b: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASE_INFO)) if FileAccess.file_exists(BASE_INFO) else null
	base_found = int(b.get("base", 0)) if b is Dictionary else 0
	if base_found <= 0:
		problem = "broken"
	elif base_found < base_needed:
		problem = "old"
	elif base_found == base_needed and whole > 0:
		# The very base this version was made for: its size is known, so a file that did not
		# download whole is caught here and not later, as voices that never play.
		var f := FileAccess.open(found, FileAccess.READ)
		if f == null or f.get_length() != whole:
			problem = "broken"
	print("PACKS base ", base_found, " from ", found, " (this version was made for base ", base_needed, ")", "" if problem == "" else " PROBLEM: " + problem)


func _show_notice() -> void:
	var tree := get_tree()
	if tree.current_scene:
		tree.current_scene.queue_free()
	for bus in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	var notice: Node = load("res://scripts/ui/packs_notice.gd").new()
	tree.root.add_child(notice)


## Dev (`-- --packs-check=res://a;res://b`): what this build sees of its packs and of the files
## named, then the game closes. For testing a base with a newer game pack on top.
func _dev_check(paths: String) -> void:
	print("CHECK version=", ProjectSettings.get_setting("application/config/version"), " split=", split, " needed=", base_needed, " found=", base_found, " problem='", problem, "' from=", base_path, " gone=", gone.size())
	for p in paths.split(";", false):
		var line := "CHECK %s exists=%s has=%s" % [p, ResourceLoader.exists(p), has(p)]
		if ResourceLoader.exists(p):
			var r: Resource = load(p)
			if r is AudioStream:
				line += " audio %.2fs" % (r as AudioStream).get_length()
			elif r is PackedScene:
				var n: Node = (r as PackedScene).instantiate()
				line += " scene %d nodes" % n.find_children("*", "", true, false).size()
				n.free()
			elif r != null:
				line += " " + r.get_class()
			else:
				line += " DID NOT LOAD"
		print(line)
	var v := 0
	for lang in DirAccess.get_directories_at("res://voices"):
		for sub in DirAccess.get_directories_at("res://voices/" + lang):
			v += DirAccess.get_files_at("res://voices/%s/%s" % [lang, sub]).size()
	print("CHECK voice files listed: ", v, "  people models listed: ", DirAccess.get_files_at("res://assets/models/people").size())
	get_tree().quit()
