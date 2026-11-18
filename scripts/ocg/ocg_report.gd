class_name OcgReport
extends RefCounted
## A small plain-text record next to the saves: did the rules engine load on this computer, and
## how did the last duels go (which rules ran them, what the engine or the table complained
## about). It is there so a problem on a machine nobody can look at can still be read later.
## Nothing personal goes in it.

const FILE := "engine_status.txt"
const KEEP := 60        # duel lines kept


static func _path() -> String:
	return Saves.saves_dir().path_join(FILE)


static func _head() -> String:
	var ok := OcgCore.ensure_loaded()
	var ver := ""
	if ok:
		var v := OcgCore.op(0)
		ver = "ocgcore %d.%d" % [v.decode_u32(0), v.decode_u32(4)] if v.size() >= 8 else ""
	var lines := [
		"Yu-Gi-Oh! Crossroads %s" % str(ProjectSettings.get_setting("application/config/version", "?")),
		"system: %s %s, %s, %s" % [OS.get_name(), OS.get_version(), Engine.get_architecture_name(), OS.get_processor_name()],
		"rules engine: %s" % ("loaded" + ((" (" + ver + ")") if ver != "" else "") if ok else "NOT LOADED: " + OcgCore.why_not()),
		"duels run on: %s" % ("the rules engine" if ok else "nothing: the engine did not load, so no duel can start"),
		"opponent difficulty: %s" % ["", "Normal", "Hard", "Extreme"][clampi(Settings.cpu_level, 1, 3)],
		"written: %s" % Time.get_datetime_string_from_system(false, true),
	]
	return "\n".join(PackedStringArray(lines))


static func _duel_lines() -> Array:
	var out: Array = []
	var txt := FileAccess.get_file_as_string(_path())
	var at := txt.find("\n--- duels")
	if at >= 0:
		for l in txt.substr(at).split("\n").slice(2):
			if str(l).strip_edges() != "":
				out.append(str(l))
	return out


static func _write(duels: Array) -> void:
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(_head() + "\n\n--- duels (newest last) ---\n" + "\n".join(PackedStringArray(duels.slice(maxi(0, duels.size() - KEEP)))) + "\n")
	f.close()


## When the game starts.
static func boot() -> void:
	_write(_duel_lines())


## After a duel. errors: what the engine's scripts or the table check complained about.
static func duel(kind: String, opponent: String, level: int, winner: int, turns: int, reason: String, errors: Array) -> void:
	var line := "%s  %s vs %s  level %d  winner %s  turn %d  (%s)" % [Time.get_datetime_string_from_system(false, true), kind, opponent, level,
		["you", "opponent", "draw"][clampi(winner, 0, 2)] if winner >= 0 else "none", turns, reason]
	var all := _duel_lines()
	all.append(line)
	for e in errors.slice(0, 12):
		all.append("    ! " + str(e).left(300).replace("\n", " "))
	_write(all)
