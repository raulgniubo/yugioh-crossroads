extends Node
## Dev: the shops shelves, frame by frame. Opens Decks and cards > shops, switches through every
## world's tab, then opens the biggest pack of each world's shelf ("See all cards") and closes it.
## For each step: build time, then over the next frames the worst frame, the average and how many
## frames took more than 20 ms.
##   xvfb-run godot --rendering-driver opengl3 --path . res://tests/shelf_times.tscn -- --assets=<folder>

func _frames(n: int) -> Array:
	var worst := 0
	var sum := 0
	var slow := 0
	for i in n:
		var f0 := Time.get_ticks_usec()
		await get_tree().process_frame
		var d := Time.get_ticks_usec() - f0
		worst = maxi(worst, d)
		sum += d
		if d > 20000:
			slow += 1
	return [worst / 1000.0, sum / 1000.0 / n, slow]


func _line(tag: String, build_us: int, f: Array) -> void:
	print("SHELF %-34s build %6.1f ms   worst %6.1f ms   avg %5.1f ms   >20ms %3d" % [tag, build_us / 1000.0, f[0], f[1], f[2]])


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--assets="):
			Settings.card_folder = a.substr(9)
	await get_tree().process_frame
	var g := CardsGate.new()
	add_child(g)
	_line("hub", 0, await _frames(30))
	for pass_name in ["first", "again"]:
		for w in CardsGate.SHOP_WORLDS:
			var t0 := Time.get_ticks_usec()
			g._shops(w)
			var t1 := Time.get_ticks_usec()
			_line("tab %s (%s)" % [w, pass_name], t1 - t0, await _frames(60))
	_line("idle on shelf", 0, await _frames(120))
	for w in CardsGate.SHOP_WORLDS:
		g._shops(w)
		await _frames(10)
		var best := -1
		var most := -1
		for i in g._shelf_packs.size():
			var n: int = Collection.pool(str(g._shelf_packs[i]["key"])).size()
			if n > most:
				most = n
				best = i
		if best < 0:
			continue
		g._pick_pack(best)
		var t0 := Time.get_ticks_usec()
		var v := CardListView.new("pack", g._shelf_packs[best])
		g.add_child(v)
		var t1 := Time.get_ticks_usec()
		_line("pack %s (%d cards)" % [w, most], t1 - t0, await _frames(240))
		v.queue_free()
		await _frames(5)
	print("SHELF DONE")
	get_tree().quit()
