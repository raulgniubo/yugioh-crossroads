extends SceneTree
## Dev tool: which effect monsters in the ready-made decks still play as plain ATK/DEF?
## godot --headless -s tools/fx_audit.gd -- /path/to/card/folder

func _initialize() -> void:
	var folder := "/tmp/testassets2"
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			folder = a
	CardData.load_external(folder)
	var keys: Array = CardData.DECKS.keys() + CardData.NAMED_DECKS.keys()
	var missing := {}
	var total := 0
	var covered := 0
	for k in keys:
		for id in CardData.deck_list(str(k)) + CardData.extra_list(str(k)):
			var d := CardData.get_card(id)
			if d.get("kind", "") != "monster" or str(d.get("frame", "")) == "normal":
				continue
			var nm := str(d.get("name", ""))
			total += 1
			if CardEffects.has(nm) or CardData.MONSTER_EFFECTS.has(nm):
				covered += 1
				continue
			if not missing.has(nm):
				missing[nm] = {"decks": [], "desc": str(d.get("desc", d.get("text", ""))), "frame": d.get("frame", "")}
			if not (k in missing[nm]["decks"]):
				missing[nm]["decks"].append(k)
	var col = get_root().get_node_or_null("Collection")
	if col:
		var kinds := {"monster": 0, "spell": 0, "trap": 0}
		for id in col.every_playable():
			var k := str(CardData.get_card(id).get("kind", "monster"))
			kinds[k] = int(kinds.get(k, 0)) + 1
		print("IN THE GAME: ", col.every_playable().size(), " cards ", kinds, "   in the database: ", CardData.EXT.size(), "   read from text: ", CardEffectsAuto.FX.size())
	if col:
		# The strict check: every card in the game must have rules behind its text.
		var bad := 0
		var loose := 0
		var gain := RegEx.new()
		gain.compile("gains? (\\d+) ATK")
		var fld := RegEx.new()
		fld.compile("All ([A-Za-z\\-, ]+?)(?:-Type)? monsters (?:on the field )?gain (\\d+) ATK")
		for id in col.every_playable():
			var d := CardData.get_card(id)
			var nm := str(d.get("name", ""))
			var text := str(d.get("desc", d.get("text", "")))
			var why := ""
			if str(d.get("kind", "monster")) == "monster":
				# An entry that is only a note is a placeholder, not rules.
				var e: Dictionary = CardEffects.of(nm)
				var real := e.size() > (1 if e.has("note") else 0)
				if str(d.get("frame", "")) == "normal" or real or CardData.MONSTER_EFFECTS.has(nm) or nm == "Shield Warrior":
					continue
				# Fusion / Ritual / Synchro monsters whose text is only how to summon them.
				var rest := text
				for line in text.split("\n"):
					var l := line.strip_edges()
					if l == "" or l.begins_with("\"") or l.contains("Ritual Summon this card") or l.contains("Tuner") and l.contains("+") or l.contains(" + ") or l.contains("Level ") and l.contains("monsters") and l.length() < 40:
						rest = rest.replace(line, "")
				if rest.strip_edges() == "":
					continue
				why = "monster effect"
			else:
				if SpellRules.FX.has(nm) or d.has("effect"):
					continue
				var st := str(d.get("st", "")).to_lower()
				if st == "ritual":
					continue
				if st == "equip" and gain.search(text) != null:
					loose += 1
					print("DERIVED|", nm, "|", st, "|", text.replace("\n", " ").substr(0, 200))
					continue
				if st == "field" and fld.search(text) != null:
					loose += 1
					print("DERIVED|", nm, "|", st, "|", text.replace("\n", " ").substr(0, 200))
					continue
				why = "spell/trap"
			bad += 1
			print("NO RULES|", why, "|", nm, "|", id, "|", text.replace("\n", " ").substr(0, 160))
		var inexact := 0
		for id in col.every_playable():
			if not CardExact.ok(CardData.get_card(id)):
				inexact += 1
				print("NOT EXACT IN GAME|", CardData.get_card(id).get("name", ""))
		print("EXACT: ", CardExact.MONSTERS.size(), " effect monsters checked against their text; Spells/Traps not exact yet: ", CardExact.NOT_YET.size(), "; inexact cards still in the game: ", inexact)
		print("STRICT: ", bad, " cards in the game without rules; ", loose, " equip/field cards run from their text pattern")
	print("FX coverage: ", covered, " of ", total, " effect-monster slots; ", missing.size(), " different cards missing")
	var names: Array = missing.keys()
	names.sort_custom(func(a, b): return (missing[a]["decks"] as Array).size() > (missing[b]["decks"] as Array).size())
	for nm in names:
		print("MISSING|", nm, "|", missing[nm]["frame"], "|", ",".join(PackedStringArray(missing[nm]["decks"])), "|", str(missing[nm]["desc"]).replace("\n", " ").substr(0, 230))
	quit()
