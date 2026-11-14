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
	print("FX coverage: ", covered, " of ", total, " effect-monster slots; ", missing.size(), " different cards missing")
	var names: Array = missing.keys()
	names.sort_custom(func(a, b): return (missing[a]["decks"] as Array).size() > (missing[b]["decks"] as Array).size())
	for nm in names:
		print("MISSING|", nm, "|", missing[nm]["frame"], "|", ",".join(PackedStringArray(missing[nm]["decks"])), "|", str(missing[nm]["desc"]).replace("\n", " ").substr(0, 230))
	quit()
