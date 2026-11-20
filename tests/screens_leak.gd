extends Node
## Dev: opens and closes each big screen several times and prints what is left in memory after
## each round. A number that keeps climbing round after round is a leak; one that climbs once and
## then holds is a cache filling up.
##   godot --headless --path . res://tests/screens_leak.tscn -- --assets=<folder> [--own=3000] [--rounds=4] [--only=world]
## (Back up the profile first: some screens save.)
var rounds := 4

func _ready() -> void:
	var own := 3000
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--assets="):
			Settings.card_folder = a.substr(9)
		elif a.begins_with("--own="):
			own = int(a.substr(6))
		elif a.begins_with("--rounds="):
			rounds = int(a.substr(9))
		elif a.begins_with("--only="):
			only = a.substr(7)
	await get_tree().process_frame
	var ids: Array = Collection.all_cards()
	ids.sort()
	Collection.owned.clear()
	for id in ids.slice(0, own):
		Collection.owned[int(id)] = 1 + (int(id) % 3)
	var pulls: Array = []
	for k in 216:      # (a box of 24 packs)
		pulls.append(int(ids[(k * 37) % ids.size()]))
	var screens := {
		"deck editor": func(): return DeckBuilder.new(),
		"deck list": func(): return DeckMenu.new(),
		"pack shop": func(): return PackShop.new(),
		"deck shop": func(): return DeckShop.new(),
		"pack summary (24 packs)": func(): return PackSummary.new(pulls, {}, UITheme.ACCENT, "Test"),
		"album": func(): return CardAlbum.open(self),
	}
	_line("start")
	for name in screens:
		if only != "" and not str(name).contains(only):
			continue
		for r in rounds:
			var s: Node = (screens[name] as Callable).call()
			if s.get_parent() == null:
				add_child(s)
			await _frames(40)
			# Scroll every list in it to the bottom and back, the way somebody browsing would.
			for sc in s.find_children("*", "ScrollContainer", true, false):
				for step in 12:
					(sc as ScrollContainer).scroll_vertical = int((sc as ScrollContainer).get_v_scroll_bar().max_value * (step + 1) / 12.0)
					await _frames(3)
			s.queue_free()
			await _frames(30)
			_line("%s, round %d" % [name, r + 1])
	if only == "" or only == "world":
		for r in rounds:
			var w: Node = (load(Router.ROAM) as PackedScene).instantiate()
			add_child(w)
			await get_tree().create_timer(6.0).timeout
			w.queue_free()
			await _frames(40)
			_line("world, round %d" % (r + 1))
	get_tree().quit()


func _frames(n: int) -> void:
	for k in n:
		await get_tree().process_frame


func _line(tag: String) -> void:
	print("SOAK %-34s objects %6d  nodes %5d  orphans %4d  resources %5d  memory %7.1f MB  pictures: faces %d small %d big %d art %d" % [tag,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Cards._face_cache.size(), Cards._thumb_cache.size(), Cards._full_cache.size(), Cards._art_cache.size()])
