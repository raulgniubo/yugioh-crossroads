class_name Saves
extends RefCounted
## Everything about where the game keeps its things.
##
## The game folder: a folder called "Crossroads Data" beside the game holds the cards, your
## own models and the saves. If there is none, the folder picked in Settings is used.
## Save slots hold the WHOLE game (story, cards, Duel Points, decks, world progress), because
## all of those belong together. Loading, starting over and admin mode swap the save files and
## restart the game, so every part of it wakes up on the same save.

const FILES := ["story.cfg", "shop.cfg", "roam.cfg", "turbo.cfg", "tourney.cfg", "roam_extras.cfg", "profile.cfg", "opening.cfg", "collection.cfg", "academy.cfg", "knockout.cfg", "stars.cfg"]
const SLOTS := 3
const PENDING := "user://pending_save.txt"
const PIN := "1010"
const DATA_NAME := "Crossroads Data"


## Where the game itself sits (on a Mac: the folder the app is in).
static func game_dir() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--game-dir="):
			return a.trim_prefix("--game-dir=")      # dev: pretend the game sits in this folder
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


# ------------------------------------------------------------------ the game you are playing, in the folder

## With "Crossroads Data" right beside the game, the game you are playing is kept in that
## folder as well (saves/current), not only in the system's own hidden place. So the folder
## with the game in it is everything: zip it, take it to another computer, and it carries on
## where you were. Without the folder beside the game nothing here does anything.
const LIVE := "current"


## The game's own folder is its home: the save lives right beside the game, so a copy of the
## folder is a copy of the game, and a fresh folder is a fresh game. "Crossroads Data" is made
## next to the game when it is not there yet. Only when that folder cannot be written to (a
## locked drive, a Mac app run from inside a disk image) does the game fall back to the
## system's own hidden place.
static var _portable := -1


static func portable() -> bool:
	if _portable < 0:
		var d := game_dir().path_join(DATA_NAME)
		var built: bool = OS.has_feature("template") or Array(OS.get_cmdline_user_args()).any(func(a): return str(a).begins_with("--game-dir="))
		if DirAccess.dir_exists_absolute(d):
			_portable = 1 if _writable(d) else 0
		elif built and DirAccess.make_dir_recursive_absolute(d.path_join("saves")) == OK:
			_portable = 1
		else:
			_portable = 0
	return _portable == 1


static func _writable(dir: String) -> bool:
	var probe := dir.path_join(".write_test")
	var f := FileAccess.open(probe, FileAccess.WRITE)
	if f == null:
		return false
	f.close()
	DirAccess.remove_absolute(probe)
	return true


## Your own game and the admin game are two different games: each has its own place in the
## folder, so neither ever lands on the other.
static func live_dir() -> String:
	return game_dir().path_join(DATA_NAME).path_join("saves").path_join(LIVE + ("_admin" if admin else ""))


## Two files are about you and not about one game: whether admin mode is on (with the story
## difficulty), and your settings. They travel with the folder as well. Read before anything
## asks whether admin is on or loads a setting.
const SHARED := ["admin.cfg", "settings.cfg"]


static func pull_shared() -> void:
	if not portable():
		return
	for f in SHARED:
		var from: String = game_dir().path_join(DATA_NAME).path_join("saves").path_join(str(f))
		if not FileAccess.file_exists(from):
			continue
		var note := from + ".stamp"
		var there := int(FileAccess.get_file_as_string(note).strip_edges()) if FileAccess.file_exists(note) else int(FileAccess.get_modified_time(from))
		var mine: String = "user://" + str(f)
		var here := int(FileAccess.get_modified_time(mine)) if FileAccess.file_exists(mine) else 0
		if there > here:
			DirAccess.copy_absolute(from, mine)


static func _push_shared() -> void:
	for f in SHARED:
		var mine: String = "user://" + str(f)
		if not FileAccess.file_exists(mine):
			continue
		var to: String = game_dir().path_join(DATA_NAME).path_join("saves").path_join(str(f))
		DirAccess.make_dir_recursive_absolute(to.get_base_dir())
		if not FileAccess.file_exists(to) or FileAccess.get_modified_time(mine) > FileAccess.get_modified_time(to):
			DirAccess.copy_absolute(mine, to)
			var note := FileAccess.open(to + ".stamp", FileAccess.WRITE)
			if note:
				note.store_string(str(int(FileAccess.get_modified_time(mine))))
				note.close()


static func _newest(dir: String) -> int:
	var t := 0
	for f in FILES:
		var p: String = dir.path_join(str(f))
		if FileAccess.file_exists(p):
			t = maxi(t, int(FileAccess.get_modified_time(p)))
	return t


## At the very start: when the folder's copy of the game you are playing is newer than this
## computer's (or this computer has none yet), that is the game you play.
static func pull_live() -> void:
	if not portable():
		return
	var live := live_dir()
	var in_folder := false
	var on_computer := false
	for f in FILES:
		in_folder = in_folder or FileAccess.file_exists(live.path_join(str(f)))
		on_computer = on_computer or FileAccess.file_exists("user://" + str(f))
	if in_folder:
		# The folder is the game: what is in it is what you play, whatever this computer had.
		for f in FILES:
			var src := live.path_join(str(f))
			if FileAccess.file_exists(src):
				DirAccess.copy_absolute(src, "user://" + str(f))
			elif FileAccess.file_exists("user://" + str(f)):
				DirAccess.remove_absolute("user://" + str(f))
		print("SAVES the game in the folder beside the game (", live, ")")
	elif on_computer and not admin:
		# A fresh folder is a fresh game. A game this computer kept from before is not thrown
		# away: it goes into an empty save slot in the folder, ready to Load from Story.
		var slot := ""
		for i in range(1, SLOTS + 1):
			if not exists("slot%d" % i):
				slot = "slot%d" % i
				break
		if slot == "":
			slot = "from_this_computer"
		_copy_all("user://", slot_dir(slot))
		var meta := ConfigFile.new()
		meta.set_value("save", "when", Time.get_datetime_string_from_system(false, true))
		meta.set_value("save", "summary", "Found on this computer from an earlier version")
		meta.save(slot_dir(slot).path_join("slot.cfg"))
		for f in FILES:
			if FileAccess.file_exists("user://" + str(f)):
				DirAccess.remove_absolute("user://" + str(f))
			if FileAccess.file_exists("user://" + str(f) + ".bak"):
				DirAccess.remove_absolute("user://" + str(f) + ".bak")
		print("SAVES fresh folder: the old game from this computer is kept in ", slot_dir(slot))


## Keep the folder's copy up to date: every save file that changed since it was last copied.
static func push_live() -> void:
	if not portable():
		return
	_push_shared()
	var to := live_dir()
	if not DirAccess.dir_exists_absolute(to) and DirAccess.make_dir_recursive_absolute(to) != OK:
		return
	for f in FILES:
		var src: String = "user://" + str(f)
		var dst: String = to.path_join(str(f))
		if FileAccess.file_exists(src):
			if not FileAccess.file_exists(dst) or FileAccess.get_modified_time(src) > FileAccess.get_modified_time(dst):
				DirAccess.copy_absolute(src, dst)
		elif FileAccess.file_exists(dst):
			DirAccess.remove_absolute(dst)
	var note := FileAccess.open(to.path_join("stamp.txt"), FileAccess.WRITE)
	if note:
		note.store_string(str(_newest("user://")))
		note.close()


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
## Save safety: every save file is checked when the game starts. A file that no longer reads
## (the computer lost power while it was being written) is put back from the copy kept at the last
## good start; a good one becomes the new copy. So a crash can cost one session, never the save.
static func guard_files() -> Array:
	var fixed: Array = []
	for f in FILES:
		var path: String = "user://" + f
		var bak: String = path + ".bak"
		if not FileAccess.file_exists(path):
			continue
		var cfg := ConfigFile.new()
		if cfg.load(path) == OK:
			DirAccess.copy_absolute(path, bak)
		elif FileAccess.file_exists(bak) and ConfigFile.new().load(bak) == OK:
			DirAccess.copy_absolute(bak, path)
			fixed.append(f)
	if not fixed.is_empty():
		push_warning("Save files restored from the last good copy: %s" % ", ".join(fixed))
	return fixed


static func apply_pending() -> void:
	if not FileAccess.file_exists(PENDING):
		return
	var order := FileAccess.get_file_as_string(PENDING).strip_edges()
	DirAccess.remove_absolute(PENDING)
	if order == "new":
		for f in FILES:
			if FileAccess.file_exists("user://" + f):
				DirAccess.remove_absolute("user://" + f)
			# ...and the folder's copy of it, or the old game would come straight back.
			if portable() and FileAccess.file_exists(live_dir().path_join(str(f))):
				DirAccess.remove_absolute(live_dir().path_join(str(f)))
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
	push_live()      # your own game, as it is right now, into the folder before the admin one starts
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
