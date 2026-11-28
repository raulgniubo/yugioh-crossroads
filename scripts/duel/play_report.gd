class_name PlayReport
extends RefCounted
## (0.85.0) "Report this play" in the duel menu: writes the table as it stands to a small text file
## next to the saves, so a move of the opponent that looked wrong can be turned into a test board
## (tests/ocg_boards.gd) instead of being described from memory. It holds the two fields, your
## hand, the counts of what is hidden, the last lines of the duel log and the opponent's own notes
## on its last decisions (its candidate answers and what each was worth). Nothing personal.

const ME := 0
const AI := 1


static func _mon(c) -> String:
	if c == null:
		return "-"
	var nm := str(c.data.get("name", "?"))
	if not c.face_up:
		return "[face-down] " + nm
	return "%s (%s %d/%d)" % [nm, "ATK" if c.attack_pos else "DEF", int(c.atk()), int(c.def())]


static func text(scene) -> String:
	var st = scene.state
	var out: Array = []
	out.append("Yu-Gi-Oh! Crossroads %s  play report" % str(ProjectSettings.get_setting("application/config/version", "?")))
	out.append(Time.get_datetime_string_from_system())
	var cfg: Dictionary = Router.duel_config
	out.append("opponent: %s   deck: %s   level: %s   turn %d, %s to play" % [str(st.players[AI].name), str(cfg.get("opponent_deck", "?")),
		str(scene.ocg.level) if scene.ocg != null else "old rules", int(st.turn), "you" if int(st.current) == ME else "them"])
	for p in [AI, ME]:
		var pl = st.players[p]
		out.append("")
		out.append("== %s   LP %d   hand %d   deck %d   graveyard %d   banished %d   extra %d" % ["THEM" if p == AI else "YOU", int(pl.lp), pl.hand.size(), pl.deck.size(), pl.gy.size(), pl.banished.size(), pl.extra.size()])
		var mons: Array = []
		for m in pl.field:
			mons.append(_mon(m))
		out.append("monsters: " + " | ".join(mons))
		var sts: Array = []
		for c in pl.spells:
			if c == null:
				sts.append("-")
			elif c.face_up or p == ME:
				sts.append(("" if c.face_up else "[set] ") + str(c.data.get("name", "?")))
			else:
				sts.append("[set]")
		out.append("spells and traps: " + " | ".join(sts))
		if pl.field_spell != null:
			out.append("field: " + str(pl.field_spell.data.get("name", "?")))
		if p == ME:
			var hand: Array = []
			for c in pl.hand:
				hand.append(str(c.data.get("name", "?")))
			out.append("your hand: " + ", ".join(hand))
		var gy: Array = []
		for i in range(maxi(0, pl.gy.size() - 8), pl.gy.size()):
			gy.append(str(pl.gy[i].data.get("name", "?")))
		out.append("last in graveyard: " + ", ".join(gy))
	out.append("")
	out.append("== the duel log (last lines)")
	for l in scene.hud.log_tail(30):
		out.append(str(l))
	out.append("")
	out.append("== the opponent's own notes on its last decisions (* = what it chose)")
	if scene.ocg != null:
		for n in scene.ocg.d.cpu_notes:
			out.append(str(n))
	return "\n".join(out) + "\n"


## Writes the report and returns where (empty if it could not).
static func write(scene) -> String:
	var dir := Saves.saves_dir().path_join("play_reports")
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := dir.path_join("play_%s.txt" % stamp)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(text(scene))
	f.close()
	return path
