extends Node
## Dev (0.55.1): create, start, run and destroy engine duels the way a played duel does, and print
## the memory in use before and after. A duel that leaves its engine behind shows as growth.
##   godot --headless res://tests/leak_check.tscn -- 200
func _ready() -> void:
	await get_tree().process_frame
	var n := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 100
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED")
		get_tree().quit(1)
		return
	var deck: Array = CardData.deck_list("deck_swarm")
	var rss := func() -> int:
		var out: Array = []
		OS.execute("ps", ["-o", "rss=", "-p", str(OS.get_process_id())], out)
		return int(str(out[0]).strip_edges()) if not out.is_empty() else 0
	var start: int = 0
	for i in n:
		var h := OcgCore.create(i + 1, [8000, 8000], [5, 5])
		var cards: Array = []
		for side in 2:
			for id in deck:
				cards.append([side, int(id), 0x01, 0x8])
		OcgCore.add_cards(h, cards)
		OcgCore.op(12, OcgCore._h(h))
		OcgCore.op(13, OcgCore._h(h))
		OcgCore.destroy(h)
		if i == 9:
			start = rss.call()
	var end_: int = rss.call()
	print("LEAK CHECK: %d duels, memory after 10: %d KB, after %d: %d KB, growth per duel after the first 10: %.1f KB" % [n, start, n, end_, float(end_ - start) / maxf(1.0, n - 10)])
	get_tree().quit()
