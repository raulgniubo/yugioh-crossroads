class_name CampusProgress
extends RefCounted
## The Academy story's own place and memory (the same shape as StoryProgress, kept in campus.cfg
## beside the campus state: see Campus). StoryDirector uses this one while Campus.on.

static var PATH := Saves.u("campus.cfg")
const SCRIPT_VERSION := 5      # bump when chapter scripts are restructured


static func _load() -> ConfigFile:
	return Campus.read()


static func unlocked() -> Array:
	if Saves.admin:
		var every: Array = []
		for ch in CampusData.CHAPTERS:
			every.append(ch["id"])
		return every
	return _load().get_value("story", "unlocked", ["ac_prologue"])


static func unlock(id: String) -> void:
	var cfg := _load()
	var u: Array = cfg.get_value("story", "unlocked", ["ac_prologue"])
	if not u.has(id):
		u.append(id)
	cfg.set_value("story", "unlocked", u)
	Campus.write(cfg)


static func save_position(chapter: String, step: int, flags: Dictionary) -> void:
	var cfg := _load()
	cfg.set_value("story", "chapter", chapter)
	cfg.set_value("story", "step", step)
	cfg.set_value("story", "flags", flags)
	cfg.set_value("story", "script", SCRIPT_VERSION)
	Campus.write(cfg)
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
	Campus.write(cfg)


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
	Campus.write(cfg)


static func clear_position() -> void:
	var cfg := _load()
	cfg.set_value("story", "chapter", "")
	cfg.set_value("story", "step", 0)
	cfg.set_value("story", "flags", {})
	Campus.write(cfg)


# ------------------------------------------------------------------ what the story remembers
# Choices and bonds outlive the chapter they were made in: the finale looks back at them.

static func remember(flag: String, value = true) -> void:
	var cfg := _load()
	var m: Dictionary = cfg.get_value("story", "memory", {})
	m[flag] = value
	cfg.set_value("story", "memory", m)
	Campus.write(cfg)


## A running count the story can ask about ("street_wins": duels won against people in the worlds).
static func count(key: String) -> int:
	return int(_load().get_value("story", "counts", {}).get(key, 0))


static func bump(key: String, by := 1) -> void:
	var cfg := _load()
	var c: Dictionary = cfg.get_value("story", "counts", {})
	c[key] = int(c.get(key, 0)) + by
	cfg.set_value("story", "counts", c)
	Campus.write(cfg)


static func recalls(flag: String) -> bool:
	return _load().get_value("story", "memory", {}).has(flag)


static func memory() -> Dictionary:
	return _load().get_value("story", "memory", {})


## How many people you have a bond scene with (Lumen's card grows with this).
static func bonds() -> int:
	var n := 0
	for k in memory():
		if str(k).begins_with("bond_") and str(k) != "bond_lumen":
			n += 1
	return n


## How far the Academy story has come: the number of chapters finished.
static func stage() -> int:
	return maxi(0, unlocked().size() - 1) if not Saves.admin else 0
