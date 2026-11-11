class_name StoryProgress
extends RefCounted
## Story save: unlocked chapters, current chapter + step, flags. user://story.cfg

const PATH := "user://story.cfg"


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	return cfg


static func unlocked() -> Array:
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
	cfg.save(PATH)


static func position() -> Dictionary:
	var cfg := _load()
	return {"chapter": cfg.get_value("story", "chapter", ""), "step": cfg.get_value("story", "step", 0),
			"flags": cfg.get_value("story", "flags", {})}


static func clear_position() -> void:
	var cfg := _load()
	cfg.set_value("story", "chapter", "")
	cfg.set_value("story", "step", 0)
	cfg.set_value("story", "flags", {})
	cfg.save(PATH)
