extends SceneTree
## Dev: writes every line a voice can speak in a duel to a JSON file (English, with the Spanish
## from the string table). `godot --headless -s tools/voices/dump_lines.gd -- <out.json>`
func _init() -> void:
	var pers := {}
	# (merged here: a script run with -s cannot call into Characters, only read its constants)
	for pk in Characters.PERSONALITY_LINES:
		var m := {}
		for src in [Characters.PERSONALITY_LINES[pk], Characters.MORE_LINES.get(pk, {})]:
			for k in src:
				m[k] = (m.get(k, []) as Array) + (src[k] as Array)
		pers[pk] = m
	var out := {"personality": pers, "player": Characters.PLAYER_LINES, "chars": {}, "lumen": {}, "intros": [], "wins": [], "es": {}}
	for src in [Characters.DATA, Characters.STORY_CAST]:
		for k in src:
			var d: Dictionary = src[k]
			out["chars"][k] = {"name": d.get("name", ""), "personality": d.get("personality", ""), "lines": d.get("lines", {}),
				"ace": d.get("ace", 0), "ace_name": d.get("ace_name", ""), "deck": d.get("deck", "")}
	var ds = load("res://scripts/duel/duel_scene.gd")
	out["lumen"] = ds.LUMEN_SAYS
	var pr = load("res://scripts/core/profile.gd")
	out["intros"] = pr.INTROS
	out["wins"] = pr.WINS
	var es: Dictionary = (load("res://scripts/core/es_strings.gd").ES as Dictionary).duplicate()
	es.merge(load("res://scripts/core/es_campus.gd").ES)      # the Academy story's people have their duel lines there
	var want := {}
	var walk := func(v, f):
		pass
	var stack: Array = [out["personality"], out["player"], out["chars"], out["lumen"], out["intros"], out["wins"]]
	while not stack.is_empty():
		var v = stack.pop_back()
		if v is Dictionary:
			for k in v:
				stack.append(v[k])
		elif v is Array:
			for x in v:
				stack.append(x)
		elif v is String and es.has(v):
			want[v] = es[v]
	out["es"] = want
	var args := OS.get_cmdline_user_args()
	var f := FileAccess.open(args[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("DUMPED")
	quit()
