extends Node
## Dev: how long each big screen takes to open. For each screen: the time to build it (new + add
## to the tree, i.e. its _ready) and the longest of the next 30 frames (work it spreads out).
## Opened twice: "cold" (first time) and "warm" (caches full).
##   xvfb-run godot --rendering-driver opengl3 --path . res://tests/open_times.tscn -- --assets=<folder> [--only=name]

func _ready() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--assets="):
			Settings.card_folder = a.substr(9)
		elif a.begins_with("--only="):
			only = a.substr(7)
	await get_tree().process_frame
	var screens := {
		"free duel": func(): return CharacterSelect.new(),
		"story": func(): return StoryGate.new(),
		"free roam": func(): return RoamGate.new(),
		"turbo": func(): return TurboGate.new(),
		"decks hub": func(): return CardsGate.new(),
		"academy door": func(): return CampusGate.new(),
		"editor": func(): return ProfileEditor.new(),
		"settings": null,      # (SettingsPanel.open builds it into a parent)
	}
	for name in screens:
		if only != "" and not str(name).contains(only):
			continue
		for pass_name in ["cold", "warm"]:
			var t0 := Time.get_ticks_usec()
			var s: Node = null
			var t1 := t0
			if screens[name] == null:
				s = SettingsPanel.open(self)
				t1 = Time.get_ticks_usec()
			else:
				s = (screens[name] as Callable).call()
				t1 = Time.get_ticks_usec()
				add_child(s)
			var t2 := Time.get_ticks_usec()
			if name == "settings":
				t1 = t0        # (built and added in one call)
			var worst := 0
			for i in 30:
				var f0 := Time.get_ticks_usec()
				await get_tree().process_frame
				worst = maxi(worst, Time.get_ticks_usec() - f0)
			print("OPEN %-13s %s  new %5d ms  ready %5d ms  worst frame after %5d ms" % [name, pass_name, (t1 - t0) / 1000, (t2 - t1) / 1000, worst / 1000])
			if name == "decks hub":
				# The shops page, and switching between the worlds' shops.
				for w in [""] + CardsGate.SHOP_WORLDS:
					var w0 := Time.get_ticks_usec()
					s._shops(w)
					var w1 := Time.get_ticks_usec()
					var ww := 0
					for i in 20:
						var f0 := Time.get_ticks_usec()
						await get_tree().process_frame
						ww = maxi(ww, Time.get_ticks_usec() - f0)
					print("OPEN   shops %-10s %s  build %5d ms  worst frame after %5d ms" % [w if w != "" else "(first)", pass_name, (w1 - w0) / 1000, ww / 1000])
			s.queue_free()
			for i in 5:
				await get_tree().process_frame
	print("OPEN DONE")
	get_tree().quit()
