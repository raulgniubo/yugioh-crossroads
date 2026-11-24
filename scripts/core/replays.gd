class_name Replays
## Replays (0.64.0). While a duel is played, everything that happens in it is written down step by
## step: every card that moves, every change of Life Points, every chain. A replay is that record in
## one small file, and watching it plays the record back through the same table, with every animation.
## - It shows what happened; it does not work the duel out again. So a replay made today plays the
##   same in any later version of the game, whatever changes in the rules or the cards.
## - Every duel is kept by itself, the last KEEP of them; a favorite is kept until you say so.
## - One file per duel in "Replays" inside Crossroads Data (or the game's own folder when there is
##   no data folder): send it to a friend, they put it in their Replays folder, and it is in their list.

const FORMAT := 3
const KEEP := 30
const EXT := ".cxr"

static var last_saved := ""      # the file of the duel that just ended


static func dir() -> String:
	var d := Saves.data_dir()
	var out := d.path_join("Replays") if d != "" else Saves.u("Replays")
	DirAccess.make_dir_recursive_absolute(out)
	return out


static func game_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "?"))


## The parts of a duel's settings that a replay needs to look the same: who, where, what kind.
## (Not what the duel was for: a replay gives no rewards and moves no story forward.)
const CFG_KEEP := ["opponent", "opponent_name", "opponent_model", "opponent_deck", "opponent_deck_full", "opponent_coat", "player_char", "player_coat",
	"player_deck", "difficulty", "cpu_level", "turbo", "lp", "my_lp", "opp_lp", "hand", "rare", "field", "arena", "music", "tod", "destiny", "destiny_opp"]

static func clean_cfg(cfg: Dictionary) -> Dictionary:
	var out := {}
	for k in CFG_KEEP:
		if cfg.has(k):
			out[k] = cfg[k]
	return out


## Writes the duel that just ended. `rec`: what the table recorded ({"setup", "lp", "answers", "cfg"}).
## Returns the file's path ("" when nothing was written).
static func save(rec: Dictionary, result: Dictionary) -> String:
	if rec.is_empty() or not rec.has("setup") or (rec.get("answers", []) as Array).is_empty():
		return ""
	var when := Time.get_datetime_dict_from_system()
	var data := {
		"format": FORMAT, "game": game_version(), "when": int(Time.get_unix_time_from_system()),
		"date": "%04d-%02d-%02d %02d:%02d" % [when["year"], when["month"], when["day"], when["hour"], when["minute"]],
		"keep": false, "names": rec["setup"]["names"], "result": result,
		"cfg": rec.get("cfg", {}), "lp": rec.get("lp", [8000, 8000]), "steps": (rec.get("tape", []) as Array).size(),
		"setup": rec["setup"], "answers": rec["answers"], "tape": rec.get("tape", []), "cards": rec.get("cards", {}),
	}
	var opp := str((rec["setup"]["names"] as Array)[1]).validate_filename()
	var how := "draw" if int(result.get("winner", 2)) > 1 else ("won" if int(result.get("winner", 2)) == 0 else "lost")
	var base := "%04d-%02d-%02d %02d-%02d-%02d vs %s (%s)" % [when["year"], when["month"], when["day"], when["hour"], when["minute"], when["second"], opp, how]
	var path := dir().path_join(base + EXT)
	if not _write(path, data):
		return ""
	last_saved = path
	_trim()
	return path


## Only the newest KEEP replays that are neither a favorite nor named stay.
static func _trim() -> void:
	var loose: Array = []
	for h in list():
		if not bool(h.get("keep", false)) and str(h.get("title", "")) == "":      # (a replay someone named stays too)
			loose.append(h)
	for h in loose.slice(KEEP):
		DirAccess.remove_absolute(str(h["path"]))


## A replay file: the whole record, packed small. (Kept as the game's own data, not as text: it holds
## thousands of small numbers and has to give them back exactly.) It is written in two parts: first
## the few lines a list shows (who, when, how it ended), then the duel itself, so that the Replays
## screen only reads the top of each file.
const HEAD := ["format", "game", "when", "date", "keep", "names", "result", "cfg", "lp", "steps"]

static func _write(path: String, data: Dictionary) -> bool:
	var f := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return false
	var head := {}
	var body := {}
	for k in data:
		if k == "path":
			continue
		if k in HEAD:
			head[k] = data[k]
		else:
			body[k] = data[k]
	f.store_var(head)
	f.store_var(body)
	f.close()
	return true


## Reads a replay. `whole` false: only what a list shows. An empty answer means "not a replay this
## game can play" (a broken file, something else with the same ending).
static func read(path: String, whole := true) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return {}
	var got = f.get_var()
	if not (got is Dictionary) or int((got as Dictionary).get("format", 0)) < FORMAT:
		f.close()
		return {}
	var d: Dictionary = got
	if int(d.get("format", 0)) > FORMAT:
		# Written by a later version in a way this one cannot play. The list still shows it (every
		# format keeps these first lines), with a word about updating the game.
		f.close()
		if whole:
			return {}
		d["newer"] = true
		d["path"] = path
		return d
	if whole:
		var body = f.get_var()
		if not (body is Dictionary) or not (body as Dictionary).has("tape") or not (body as Dictionary).has("setup"):
			f.close()
			return {}
		d.merge(body as Dictionary)
	f.close()
	d["path"] = path
	return d


## Every replay in the folder, newest first: what a list needs to show, without the duel itself.
static func list() -> Array:
	var out: Array = []
	var folder := dir()
	for fn in DirAccess.get_files_at(folder):
		if not fn.ends_with(EXT):
			continue
		var d := read(folder.path_join(fn), false)
		if d.is_empty():
			continue
		out.append({"path": d["path"], "file": fn, "when": int(d.get("when", 0)), "date": str(d.get("date", "")), "game": str(d.get("game", "?")),
			"keep": bool(d.get("keep", false)), "names": d.get("names", ["?", "?"]), "result": d.get("result", {}),
			"opponent": str((d.get("cfg", {}) as Dictionary).get("opponent", "")), "looks": str((d.get("cfg", {}) as Dictionary).get("opponent_model", "")),
			"me": str((d.get("cfg", {}) as Dictionary).get("player_char", "player")),
			"turbo": bool((d.get("cfg", {}) as Dictionary).get("turbo", false)), "steps": int(d.get("steps", 0)), "newer": bool(d.get("newer", false)), "title": title_of(fn)})
	out.sort_custom(func(a, b): return int(a["when"]) > int(b["when"]))
	return out


## The name someone gave a replay: its file's name, when that is no longer the one the game wrote
## ("2026-11-20 19-25-21 vs Seto Kaiba (lost)"). "" when it was never named. It works both ways:
## named here, or the file renamed in Finder / Explorer.
static var _auto_name: RegEx

static func title_of(file_name: String) -> String:
	if _auto_name == null:
		_auto_name = RegEx.new()
		_auto_name.compile("^\\d{4}-\\d{2}-\\d{2} \\d{2}-\\d{2}-\\d{2} vs .*\\((won|lost|draw)\\)$")
	var base := file_name.get_file().trim_suffix(EXT)
	return "" if _auto_name.search(base) != null else base


## Gives a replay a name: the file itself is renamed, so the name is what you see in the Replays
## folder and what you send to a friend. Returns the new path ("" when the name cannot be used).
static func rename(path: String, name: String) -> String:
	var clean := name.strip_edges().trim_suffix(EXT)
	for bad in [":", "/", "\\", "?", "*", "\"", "|", "%", "<", ">", "\n", "\t"]:
		clean = clean.replace(bad, " ")      # (what a file's name cannot hold, on Mac or on Windows)
	clean = clean.validate_filename().strip_edges()
	while clean.ends_with("."):
		clean = clean.substr(0, clean.length() - 1).strip_edges()
	clean = clean.substr(0, 70).strip_edges()
	if clean == "" or not FileAccess.file_exists(path) or not path.ends_with(EXT):
		return ""
	var folder := path.get_base_dir()
	var want := folder.path_join(clean + EXT)
	if want == path:
		return path
	var n := 2
	# (the same file with other capitals is not "taken": Mac and Windows do not tell them apart)
	while FileAccess.file_exists(want) and want.to_lower() != path.to_lower():
		want = folder.path_join("%s (%d)%s" % [clean, n, EXT])
		n += 1
	if DirAccess.rename_absolute(path, want) != OK:
		return ""
	if last_saved == path:
		last_saved = want
	return want


## Make a replay a favorite or not (a favorite is never cleared out by newer duels).
static func set_keep(path: String, on: bool) -> void:
	var d := read(path)
	if d.is_empty():
		return
	d["keep"] = on
	d.erase("path")
	_write(path, d)


static func remove(path: String) -> void:
	if path.ends_with(EXT) and path.begins_with(dir()):
		DirAccess.remove_absolute(path)


## What a replay says about one of its cards: enough to show it in a game that does not have it.
const SLIM_SKIP := ["effect", "id", "kind", "original", "guest"]

static func slim(card: Dictionary) -> Dictionary:
	var out := {}
	for k in card:
		var v = card[k]
		if not (str(k) in SLIM_SKIP) and (v is String or v is int or v is float or v is bool):
			out[k] = v
	var es := CardText.spanish(str(card.get("name", "")))
	if es != "":
		out["es"] = es
	return out


## A replay may come from a later version of the game, or from someone whose game has other cards.
## So before it plays, everything it names is checked against this game: a card this game does not
## have is shown from what the replay says about it (its name, its numbers, its text; no picture
## when there is none here), and a duelist, a field or a song that is not here is swapped for one
## that is. Returns what was missing: {"cards": n, "duelist": bool}.
static func settle(data: Dictionary, cfg: Dictionary) -> Dictionary:
	CardData.GUEST.clear()
	var lost := 0
	var book: Dictionary = data.get("cards", {})
	for k in book:
		var id := int(k)
		var c = book[k]
		if not (c is Dictionary) or CardData.knows(id):
			continue
		var d: Dictionary = (c as Dictionary).duplicate()
		if str(d.get("name", "")) == "":
			d["name"] = "?"
		if str(d.get("frame", "")) == "":
			d["frame"] = "effect"
		CardText.guest(str(d["name"]), str(d.get("es", "")))
		d.erase("es")
		d["guest"] = true
		CardData.GUEST[id] = d
		if str(d["frame"]) != "token":
			lost += 1
	# Who and where.
	var names: Array = data.get("names", ["?", "?"])
	var no_duelist := false
	var opp := str(cfg.get("opponent", ""))
	var looks := str(cfg.get("opponent_model", ""))
	if looks != "" and Avatars.path_for(looks) != "":
		Avatars.look_as[opp] = looks      # (a duelist of the worlds: their own name, the looks of one of the people models)
	elif Characters.get_char(opp).is_empty() and Avatars.path_for(opp) == "":
		no_duelist = true
		cfg["opponent"] = STAND_IN
		cfg.erase("opponent_coat")
		cfg.erase("opponent_model")
	if names.size() > 1:
		cfg["opponent_name"] = str(names[1])
	var me := str(cfg.get("player_char", "player"))
	if me != "player" and Characters.get_char(me).is_empty():
		cfg["player_char"] = "player"
		cfg.erase("player_coat")
	for k in ["opponent_coat", "player_coat"]:
		if cfg.has(k) and not Color.html_is_valid(str(cfg[k])):
			cfg.erase(k)
	for k in ["player_deck", "opponent_deck"]:
		if cfg.has(k) and str(cfg[k]) != "custom" and not CardData.has_deck(str(DeckTiers.split(str(cfg[k]))[0])):
			cfg.erase(k)      # (the cards themselves are in the replay; this is only the deck's name)
	for k in ["difficulty", "cpu_level", "lp", "my_lp", "opp_lp"]:
		if cfg.has(k) and not (cfg[k] is int or cfg[k] is float):
			cfg.erase(k)
	return {"cards": lost, "duelist": no_duelist}

const STAND_IN := "street_duelist"      # (who stands at the table when a replay's duelist is not in this game; the name stays the replay's)


## The duel settings that play a replay back.
## (0.73.0) An online duel as the other side saw it: the host records the duel, the guest gets that
## recording turned around (the guest is player 0 in it, as in every replay of your own).
static func flipped(rec: Dictionary) -> Dictionary:
	var r: Dictionary = rec.duplicate(true)
	var su: Dictionary = r.get("setup", {})
	for k in ["decks", "extras", "names", "hand"]:
		if su.get(k) is Array and (su[k] as Array).size() == 2:
			su[k] = [su[k][1], su[k][0]]
	su["first"] = 1 - int(su.get("first", 0))
	var lay = su.get("lay", {})
	if lay is Dictionary:
		for k in lay:
			if lay[k] is Array and (lay[k] as Array).size() == 2:
				lay[k] = [lay[k][1], lay[k][0]]
	var ru = su.get("rules", {})
	if ru is Dictionary:
		for k in ["destiny", "speed"]:
			if ru.get(k) is Array and (ru[k] as Array).size() == 2:
				ru[k] = [ru[k][1], ru[k][0]]
	if r.get("lp") is Array and (r["lp"] as Array).size() == 2:
		r["lp"] = [r["lp"][1], r["lp"][0]]
	for step in r.get("tape", []):
		if step is Dictionary and step.has("m"):
			_turn_around(step["m"])
	return r


## Every player number in the engine's messages (p, con, tc) the other way round.
static func _turn_around(v) -> void:
	if v is Dictionary:
		for k in v:
			var x = v[k]
			if x is Dictionary or x is Array:
				_turn_around(x)
			elif (k == "p" or k == "con" or k == "tc") and int(x) < 2:
				v[k] = 1 - int(x)
	elif v is Array:
		for x in v:
			_turn_around(x)


static func config_for(data: Dictionary) -> Dictionary:
	var cfg: Dictionary = (data.get("cfg", {}) as Dictionary).duplicate(true)
	cfg["first"] = int(data["setup"]["first"])
	cfg["replay"] = data
	cfg["replay_lost"] = settle(data, cfg)
	return cfg
