extends Node
## Dev: how long each of the menu's screens takes to come up (the click that opens it freezes the game
## for that long), and what is left behind after it is closed twice.
##   godot --headless res://tests/open_cost.tscn -- --assets=...
func _ready() -> void:
	await get_tree().process_frame
	var tp := Time.get_ticks_msec()
	Router.prepare()
	print("OPEN prepare (done behind the boot card) %d ms" % (Time.get_ticks_msec() - tp))
	var names := ["RoamGate", "StoryGate", "CardsGate", "DeckMenu", "ReplayList", "TurboGate", "CampusGate", "AcademyHub", "KnockoutScreen", "CharacterSelect", "DeckBuilder", "CardAlbum", "PackShop"]
	for round in 3:
		for nm in names:
			var sc = null
			for c in ProjectSettings.get_global_class_list():
				if str(c["class"]) == nm:
					sc = load(str(c["path"]))
			if sc == null:
				continue
			var n0 := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
			var o0 := int(Performance.get_monitor(Performance.OBJECT_COUNT))
			var t0 := Time.get_ticks_usec()
			var p = sc.new()
			add_child(p)
			var t1 := Time.get_ticks_usec()
			var worst := 0
			var last := t1
			for i in 40:
				await get_tree().process_frame
				var now := Time.get_ticks_usec()
				worst = maxi(worst, now - last)
				last = now
			var n1 := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
			if is_instance_valid(p):
				p.queue_free()
			for i in 20:
				await get_tree().process_frame
			print("OPEN %-16s round %d  opens in %4d ms  worst frame after %4d ms  nodes while open %5d  left behind: nodes %+d objects %+d" % [nm, round, (t1 - t0) / 1000, worst / 1000, n1 - n0,
				int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - n0, int(Performance.get_monitor(Performance.OBJECT_COUNT)) - o0])
	get_tree().quit()
