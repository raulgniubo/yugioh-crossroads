extends Node
## Dev: how long does the deck editor take to open with a big collection?
##   godot --headless --path . res://tests/editor_open.tscn -- --cards=<folder with cards/N.jpg> --own=5000
## (Back up the profile first: opening the editor saves what you have seen.)
func _ready() -> void:
	var own := 3000
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cards="):
			Settings.card_folder = a.substr(8)
		elif a.begins_with("--own="):
			own = int(a.substr(6))
	await get_tree().process_frame
	var ids: Array = []
	var d := DirAccess.open(Settings.card_folder.path_join("cards"))
	for f in d.get_files():
		if f.ends_with(".jpg"):
			ids.append(int(f.get_basename()))
	ids.sort()
	Collection.owned.clear()
	for id in ids.slice(0, own):
		Collection.owned[id] = 1 + (id % 3)
	var mem0 := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var vid0 := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
	var t0 := Time.get_ticks_msec()
	var b := DeckBuilder.new()
	add_child(b)
	var t1 := Time.get_ticks_msec()
	# ...and until everything on screen has its picture.
	var frames := 0
	while frames < 400:
		await get_tree().process_frame
		frames += 1
		if frames > 3 and _settled(b):
			break
	var t2 := Time.get_ticks_msec()
	var filled := 0
	var grid: GridContainer = b.get("_grid")
	for t in grid.get_children():
		if t.has_meta("refresh"):
			filled += 1
	print("EDITOR OPEN: owned %d  tiles %d  with a picture %d  |  opened in %d ms, pictures ready %d ms later (%d frames)  |  memory +%.0f MB, pictures on the graphics card +%.0f MB" % [
		Collection.owned.size(), grid.get_child_count(), filled, t1 - t0, t2 - t1, frames,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0 - mem0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0 - vid0])
	if "--idle" in OS.get_cmdline_user_args():
		for k in 240:
			var ti := Time.get_ticks_msec()
			await get_tree().process_frame
			if Time.get_ticks_msec() - ti > 150:
				print("  idle frame %d took %d ms" % [k, Time.get_ticks_msec() - ti])
	# Scroll to the bottom and back: the far tiles must let go.
	var sc: ScrollContainer = b.get("_gscroll") if "_gscroll" in b else null
	if sc != null:
		var worst := 0
		for step in 40:
			var t := Time.get_ticks_msec()
			sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value * (step + 1) / 40.0)
			await get_tree().process_frame
			await get_tree().process_frame
			worst = maxi(worst, Time.get_ticks_msec() - t)
			if "--steps" in OS.get_cmdline_user_args():
				print("  step %d: %d ms" % [step, Time.get_ticks_msec() - t])
		for k in 30:
			await get_tree().process_frame
		filled = 0
		for t in grid.get_children():
			if t.has_meta("refresh"):
				filled += 1
		print("EDITOR SCROLL: to the bottom in 40 steps, slowest step %d ms  |  tiles with a picture now %d  |  memory +%.0f MB, graphics +%.0f MB" % [
			worst, filled, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0 - mem0,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0 - vid0])
	get_tree().quit()


func _settled(b: Node) -> bool:
	var grid: GridContainer = b.get("_grid")
	var sc = b.get("_gscroll") if "_gscroll" in b else null
	if sc == null:
		return true      # (the old editor: everything was loaded before the first frame)
	var view: Rect2 = (sc as Control).get_global_rect()
	for t in grid.get_children():
		if (t as Control).get_global_rect().intersects(view) and (not t.has_meta("refresh") or (t.get_child(0) as TextureRect).texture == null):
			return false
	return true
