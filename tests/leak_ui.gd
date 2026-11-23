extends Node
## Dev: opens the deck editor on every card, scrolls the whole list, hovers cards, closes it; then the
## album the same way; prints what is left alive and how long an idle frame takes, before and after.
##   xvfb-run godot --path . res://tests/leak_ui.tscn -- --assets=...
func _snap(tag: String) -> void:
	var t0 := Time.get_ticks_usec()
	for i in 30:
		await get_tree().process_frame
	var ms := (Time.get_ticks_usec() - t0) / 30000.0
	print("LEAK %s nodes %d objects %d orphans %d vram %d MB tex %d MB frame %.1f ms cards-kids %d made-faces %d" % [tag,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0),
		int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0), ms,
		Cards.get_child_count(), (Cards.get("_made_faces") as Dictionary).size()])

func _ready() -> void:
	await get_tree().process_frame
	await _snap("start")
	for round in 2:
		var b := DeckBuilder.new()
		b.set("_all", true)
		get_tree().root.add_child(b)
		for i in 20:
			await get_tree().process_frame
		var sc: ScrollContainer = b.get("_gscroll")
		var grid: GridContainer = b.get("_grid")
		print("LEAK grid tiles ", grid.get_child_count())
		var maxv := int(sc.get_v_scroll_bar().max_value)
		var step := maxi(200, maxv / 120)
		var v := 0
		while v < maxv:
			sc.scroll_vertical = v
			v += step
			for i in 2:
				await get_tree().process_frame
			# hover a few: the big picture on the left
			for h in grid.get_children().slice(0, 0):
				pass
			b.call("_show", int(grid.get_child(mini(grid.get_child_count() - 1, v / 171 * grid.columns)).get_meta("id")))
		await _snap("builder open, scrolled round %d" % round)
		b.call("_close")
		for i in 30:
			await get_tree().process_frame
		await _snap("builder closed round %d" % round)
	get_tree().quit()
