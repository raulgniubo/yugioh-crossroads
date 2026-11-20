extends Node
## Dev: plays several duels in a row (both sides by the computer) and prints what is left in memory
## after each one is closed. Numbers that keep climbing are a leak.
##   godot --headless --path . res://tests/duel_leak.tscn -- --autoplay [--duels=6] [--assets=<folder>]
func _ready() -> void:
	var n := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--duels="):
			n = int(a.substr(8))
		elif a.begins_with("--assets="):
			Settings.card_folder = a.substr(9)
	await get_tree().process_frame
	_report("start")
	var decks := ["deck_dragon", "deck_warrior", "yugi", "kaiba", "joey", "jaden"]
	var foes := ["kaiba", "yugi", "joey", "jaden", "mai", "zane"]
	for i in n:
		Router.duel_config = {"player_deck": decks[i % decks.size()], "opponent_deck": decks[(i + 1) % decks.size()], "opponent": foes[i % foes.size()], "difficulty": 1}
		var d: Node = (load("res://scenes/duel.tscn") as PackedScene).instantiate()
		add_child(d)
		var waited := 0.0
		while is_instance_valid(d) and not bool(d.get("_finished")) and waited < 240.0:
			await get_tree().create_timer(0.25).timeout
			waited += 0.25
		await get_tree().create_timer(1.0).timeout
		d.queue_free()
		for k in 20:
			await get_tree().process_frame
		if "--rest" in OS.get_cmdline_user_args():
			await get_tree().create_timer(14.0).timeout      # (long enough for idle portraits to let go)
		_report("after duel %d (%.0fs, finished %s)" % [i + 1, waited, str(waited < 240.0)])
	get_tree().quit()


func _count(n: Node) -> int:
	var c := 1
	for k in n.get_children(true):
		c += _count(k)
	return c


## Who holds the nodes: every child of the root with more than 12 nodes under it, and under the
## biggest ones, what kinds of nodes they are.
func _who() -> void:
	for ch in get_tree().root.get_children(true):
		var c := _count(ch)
		if c > 12:
			var kinds := {}
			for k in ch.get_children(true):
				var key := "%s%s" % [k.get_class(), (" (" + str(k.get_script().resource_path).get_file() + ")") if k.get_script() != null else ""]
				kinds[key] = int(kinds.get(key, 0)) + _count(k)
			var top := kinds.keys()
			top.sort_custom(func(x, y): return int(kinds[x]) > int(kinds[y]))
			var parts: Array = []
			for k in top.slice(0, 6):
				parts.append("%s x%d" % [k, int(kinds[k])])
			print("  WHO %-18s %5d  %s" % [ch.name, c, ", ".join(parts)])


func _report(tag: String) -> void:
	_who()
	print("LEAK %-28s objects %6d  nodes %5d  orphans %4d  resources %5d  static %6.1f MB  faces %d  arts %d  clips %d" % [tag,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Cards._face_cache.size(), Cards._art_cache.size(), Avatars._gest_cache.size()])
	var held := 0
	for k in Avatars._stages:
		if Avatars._stage_of(k) != null and bool(Avatars._stage_of(k).call("loaded")):
			held += 1
	var refs: Array = []
	for k in Avatars._stages:
		refs.append("%s:%d%s" % [k, (Avatars._stages[k] as SubViewport).get_texture().get_reference_count(), "*" if Avatars._shown(k) else ""])
	print("  portraits %d, with a model loaded %d   picture holders %s" % [Avatars._stages.size(), held, " ".join(refs)])
