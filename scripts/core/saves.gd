class_name Saves
extends RefCounted
## Everything about where the game keeps its things.
##
## The game folder: a folder called "Crossroads Data" beside the game holds the cards, your
## own models and the saves. If there is none, the folder picked in Settings is used.
## Save slots hold the WHOLE game (story, cards, Duel Points, decks, world progress), because
## all of those belong together. Loading, starting over and admin mode swap the save files and
## restart the game, so every part of it wakes up on the same save.

const FILES := ["story.cfg", "shop.cfg", "roam.cfg", "turbo.cfg", "tourney.cfg", "roam_extras.cfg", "profile.cfg", "opening.cfg", "collection.cfg", "academy.cfg"]
const SLOTS := 3
const PENDING := "user://pending_save.txt"
const PIN := "1010"
const DATA_NAME := "Crossroads Data"


## Where the game itself sits (on a Mac: the folder the app is in).
static func game_dir() -> String:
	var exe := OS.get_executable_path().get_base_dir()
	if OS.get_name() == "macOS" and exe.contains(".app/Contents/MacOS"):
		exe = exe.get_base_dir().get_base_dir().get_base_dir()
	return exe


## The game folder, or "" when there is none (then things live in the system's own place).
static func data_dir() -> String:
	var here := game_dir().path_join(DATA_NAME)
	if DirAccess.dir_exists_absolute(here):
		return here
	var picked := str(Engine.get_main_loop().root.get_node("Settings").card_folder) if Engine.get_main_loop() and Engine.get_main_loop().root.has_node("Settings") else ""
	if picked != "" and DirAccess.dir_exists_absolute(picked):
		return picked
	return ""


static func saves_dir() -> String:
	var d := data_dir()
	var out := d.path_join("saves") if d != "" else "user://saves"
	if not DirAccess.dir_exists_absolute(out):
		if DirAccess.make_dir_recursive_absolute(out) != OK:
			out = "user://saves"
			DirAccess.make_dir_recursive_absolute(out)
	return out


static func slot_dir(slot: String) -> String:
	return saves_dir().path_join(slot)


static func _copy_all(from: String, to: String) -> int:
	DirAccess.make_dir_recursive_absolute(to)
	var n := 0
	for f in FILES:
		var src := from.path_join(f)
		var dst := to.path_join(f)
		if FileAccess.file_exists(src):
			if DirAccess.copy_absolute(src, dst) == OK:
				n += 1
		elif FileAccess.file_exists(dst):
			DirAccess.remove_absolute(dst)
	return n


## Write the game as it is now into a slot ("slot1".."slot3", "autosave").
static func save_to(slot: String) -> bool:
	_flush()
	var n := _copy_all("user://", slot_dir(slot))
	var meta := ConfigFile.new()
	meta.set_value("save", "when", Time.get_datetime_string_from_system(false, true))
	meta.set_value("save", "summary", summary())
	meta.save(slot_dir(slot).path_join("slot.cfg"))
	return n > 0


static func exists(slot: String) -> bool:
	return FileAccess.file_exists(slot_dir(slot).path_join("slot.cfg"))


static func info(slot: String) -> Dictionary:
	var meta := ConfigFile.new()
	if meta.load(slot_dir(slot).path_join("slot.cfg")) != OK:
		return {}
	return {"when": str(meta.get_value("save", "when", "")), "summary": str(meta.get_value("save", "summary", ""))}


## One line about the game in memory: where the story is and what you own.
static func summary() -> String:
	var u: Array = StoryProgress.unlocked()
	var where := "Prologue"
	for ch in StoryData.CHAPTERS:
		if u.has(ch["id"]):
			where = str(ch["title"])
	if StoryProgress.recalls("finished"):
		where = "Story finished"
	var col = Engine.get_main_loop().root.get_node_or_null("Collection")
	var cards := 0
	if col:
		for id in col.owned:
			cards += int(col.owned[id])
	return "%s  ·  %d cards  ·  %d DP" % [where, cards, int(col.dp) if col else 0]


static func _flush() -> void:
	var root: Node = Engine.get_main_loop().root
	if root.has_node("Collection"):
		root.get_node("Collection").save()
	if root.has_node("Settings"):
		root.get_node("Settings").save_settings()


## Load a slot, start a new game, or leave admin mode: note it down and restart. The swap
## itself happens at the very start of the next run, before anything has read a save file.
static func restart_with(order: String) -> void:
	_flush()
	var f := FileAccess.open(PENDING, FileAccess.WRITE)
	if f:
		f.store_string(order)
		f.close()
	var tree: SceneTree = Engine.get_main_loop()
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	tree.quit()


## Called once, first thing, by the first part of the game that starts.
static func apply_pending() -> void:
	if not FileAccess.file_exists(PENDING):
		return
	var order := FileAccess.get_file_as_string(PENDING).strip_edges()
	DirAccess.remove_absolute(PENDING)
	if order == "new":
		for f in FILES:
			if FileAccess.file_exists("user://" + f):
				DirAccess.remove_absolute("user://" + f)
	elif order.begins_with("load:"):
		var slot := order.trim_prefix("load:")
		if FileAccess.file_exists(slot_dir(slot).path_join("slot.cfg")):
			_copy_all(slot_dir(slot), "user://")
	print("SAVES applied: ", order)


# ------------------------------------------------------------------ admin

static var admin := false


## Admin mode: everything open, for testing. Your real game is put aside first and comes
## back untouched when you switch admin off.
static func admin_on(pin: String) -> bool:
	if pin != PIN:
		return false
	save_to("_real")
	var cfg := ConfigFile.new()
	cfg.load("user://admin.cfg")
	cfg.set_value("admin", "on", true)
	cfg.set_value("admin", "known", true)
	cfg.save("user://admin.cfg")
	admin = true
	return true


## Has the right PIN been typed on this computer before? Then the switch needs no PIN again.
static func pin_known() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load("user://admin.cfg") == OK and bool(cfg.get_value("admin", "known", false))


static func admin_off() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://admin.cfg")
	cfg.set_value("admin", "on", false)
	cfg.save("user://admin.cfg")
	admin = false
	restart_with("load:_real")


static func read_admin() -> void:
	var cfg := ConfigFile.new()
	admin = cfg.load("user://admin.cfg") == OK and bool(cfg.get_value("admin", "on", false))
	if "--admin" in OS.get_cmdline_user_args():
		admin = true


# ------------------------------------------------------------------ story difficulty

## 0 Easy, 1 Normal, 2 Hard. Kept with the settings, so it follows you across saves.
static func story_difficulty() -> int:
	var cfg := ConfigFile.new()
	cfg.load("user://admin.cfg")
	return clampi(int(cfg.get_value("story", "difficulty", 1)), 0, 2)


static func set_story_difficulty(d: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://admin.cfg")
	cfg.set_value("story", "difficulty", clampi(d, 0, 2))
	cfg.save("user://admin.cfg")
