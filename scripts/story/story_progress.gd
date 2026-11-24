class_name StoryProgress
extends RefCounted
## Story save: unlocked chapters, current chapter + step, flags. user://story.cfg

static var PATH := Saves.u("story.cfg")
const SCRIPT_VERSION := 5      # bump when chapter scripts are restructured


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	return cfg


static func unlocked() -> Array:
	if Saves.admin:
		var every: Array = []
		for ch in StoryData.CHAPTERS:
			every.append(ch["id"])
		return every
	return _load().get_value("story", "unlocked", ["prologue"])


static func unlock(id: String) -> void:
	var cfg := _load()
	var u: Array = cfg.get_value("story", "unlocked", ["prologue"])
	if not u.has(id):
		u.append(id)
	cfg.set_value("story", "unlocked", u)
	cfg.save(PATH)


static func save_position(chapter: String, step: int, flags: Dictionary) -> void:
	var cfg := _load()
	cfg.set_value("story", "chapter", chapter)
	cfg.set_value("story", "step", step)
	cfg.set_value("story", "flags", flags)
	cfg.set_value("story", "script", SCRIPT_VERSION)
	cfg.save(PATH)
	# The autosave slot follows the story: every goal and every duel writes it.
	if not Saves.admin and Engine.get_main_loop() and Engine.get_main_loop().root.has_node("Collection"):
		Saves.save_to("autosave")


static func position() -> Dictionary:
	var cfg := _load()
	# A place saved in an older build points into a script that has since been rewritten:
	# start that chapter from the top instead of landing mid-sentence somewhere else.
	if int(cfg.get_value("story", "script", 1)) != SCRIPT_VERSION:
		return {"chapter": "", "step": 0, "flags": {}}
	return {"chapter": cfg.get_value("story", "chapter", ""), "step": cfg.get_value("story", "step", 0),
			"flags": cfg.get_value("story", "flags", {})}


## A side scene borrows the "where you stopped" slot: the chapter's own place is put aside
## when one starts and comes back when it ends.
static func stash_position() -> void:
	var cfg := _load()
	if str(cfg.get_value("story", "chapter", "")).begins_with("bond_"):
		return
	cfg.set_value("story", "stash", [cfg.get_value("story", "chapter", ""), cfg.get_value("story", "step", 0), cfg.get_value("story", "flags", {})])
	cfg.save(PATH)


static func restore_position() -> void:
	var cfg := _load()
	var st: Array = cfg.get_value("story", "stash", [])
	if st.size() == 3:
		cfg.set_value("story", "chapter", st[0])
		cfg.set_value("story", "step", st[1])
		cfg.set_value("story", "flags", st[2])
	else:
		cfg.set_value("story", "chapter", "")
		cfg.set_value("story", "step", 0)
		cfg.set_value("story", "flags", {})
	cfg.set_value("story", "stash", [])
	cfg.save(PATH)


static func clear_position() -> void:
	var cfg := _load()
	cfg.set_value("story", "chapter", "")
	cfg.set_value("story", "step", 0)
	cfg.set_value("story", "flags", {})
	cfg.save(PATH)


# ------------------------------------------------------------------ what the story remembers
# Choices and bonds outlive the chapter they were made in: the finale looks back at them.

static func remember(flag: String, value = true) -> void:
	var cfg := _load()
	var m: Dictionary = cfg.get_value("story", "memory", {})
	m[flag] = value
	cfg.set_value("story", "memory", m)
	cfg.save(PATH)


## A running count the story can ask about ("street_wins": duels won against people in the worlds).
static func count(key: String) -> int:
	return int(_load().get_value("story", "counts", {}).get(key, 0))


static func bump(key: String, by := 1) -> void:
	var cfg := _load()
	var c: Dictionary = cfg.get_value("story", "counts", {})
	c[key] = int(c.get(key, 0)) + by
	cfg.set_value("story", "counts", c)
	cfg.save(PATH)


static func recalls(flag: String) -> bool:
	return _load().get_value("story", "memory", {}).has(flag)


static func memory() -> Dictionary:
	return _load().get_value("story", "memory", {})


## How many duelists you have bonded with (Lumen's card grows with this). Chapters finished
## in an older build count too: each one ended with a bond.
static func bonds() -> int:
	var n := 0
	for k in memory():
		if str(k).begins_with("bond_") and str(k) != "bond_lumen":
			n += 1
	var u: Array = unlocked()
	var known := 0
	for pair in [["ch2", 1], ["ch3", 3], ["ch4", 4], ["ch5", 5]]:
		if u.has(pair[0]):
			known = int(pair[1])
	return maxi(n, known)


## How far the story has come: 0 nothing, 1 prologue done, ... 6 the ending.
static func stage() -> int:
	var u: Array = unlocked()
	var n := 0
	for id in ["ch1", "ch2", "ch3", "ch4", "ch5", "epilogue"]:
		if u.has(id):
			n += 1
	return n
