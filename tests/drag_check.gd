extends Node
## Dev: drags cards with real mouse events and says if they landed: a collection card (one you have,
## then one you don't) onto the deck, and a deck card back to the collection.
##   xvfb-run godot --path . res://tests/drag_check.tscn -- --assets=...
var b: DeckBuilder

func _ready() -> void:
	await get_tree().process_frame
	if "--real" in OS.get_cmdline_user_args():
		# the real game: the main menu opens the editor (--menu-open=builder); this node outlives the scene change
		var me := self
		get_parent().remove_child.call_deferred(me)
		get_tree().root.add_child.call_deferred(me)
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
		for i in 600:
			await get_tree().process_frame
			var found := get_tree().root.find_children("*", "DeckBuilder", true, false)
			if not found.is_empty():
				b = found[0]
				break
		if b == null:
			print("DRAG no editor")
			get_tree().quit()
			return
	else:
		# as in the game from DECKS & CARDS: a panel at z 100 holding the editor at z 110
		var gate := Control.new()
		gate.set_anchors_preset(Control.PRESET_FULL_RECT)
		gate.z_index = 100
		get_tree().root.add_child(gate)
		b = DeckBuilder.new()
		b.z_index = 110
		gate.add_child(b)
	await _wait(60)
	await _case("owned to deck", _first_tile(), _deck_point())
	# type into the search box like a person (it keeps the focus), then drag
	var se: LineEdit = null
	for le in b.find_children("*", "LineEdit", true, false):
		if (le as LineEdit).clear_button_enabled:
			se = le
	se.grab_focus()
	se.edit()
	await _wait(2)
	for ch in "umi":
		var k := InputEventKey.new()
		k.pressed = true
		k.unicode = ch.unicode_at(0)
		k.keycode = OS.find_keycode_from_string(ch.to_upper())
		Input.parse_input_event(k)
		await _wait(1)
		var k2 := k.duplicate()
		k2.pressed = false
		Input.parse_input_event(k2)
		await _wait(1)
	await _wait(40)
	print("DRAG search box text '", se.text, "' editing ", se.is_editing(), " focus ", se.has_focus())
	await _case("search hit to deck", _first_tile(), _deck_point())
	await _case("deck to collection", _deck_tile(), (b.get("_cp") as Control).get_global_rect().get_center())
	# admin: the missing copies in one press
	Saves.admin = true
	var n := 0
	for cid in Collection.all_cards():
		if Collection.count(int(cid)) == 0 and not CardData.is_extra(int(cid)) and n < 3:
			Collection.main.append(int(cid))
			n += 1
	b.call("_changed")
	b.call("_refresh_count")
	var btn: Button = b.get("_admin_fill")
	print("DRAG admin button visible ", btn.visible, " '", btn.text.strip_edges(), "' missing ", Collection.missing_count())
	btn.pressed.emit()
	await _wait(5)
	print("DRAG admin after press: missing ", Collection.missing_count(), " deck ok? ", Collection.missing_cards().is_empty(), " button ", btn.visible)
	get_tree().quit()

func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _first_tile() -> Control:
	for h in (b.get("_grid") as GridContainer).get_children():
		if (h as Control).get_child_count() > 0 and (h as Control).get_global_rect().size.x > 0:
			return h
	return null

func _deck_tile() -> Control:
	var dp: Control = b.get("_dp")
	var best: Control = null
	for n in dp.find_children("*", "TextureRect", true, false):
		if (n as Control).is_visible_in_tree() and (n as Control).size.x > 40 and (n as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			best = n
			break
	return best

func _deck_point() -> Vector2:
	var dp: Control = b.get("_dp")
	return dp.get_global_rect().position + Vector2(dp.size.x * 0.5, 160)

func _case(name: String, tile: Control, p1: Vector2) -> void:
	if tile == null:
		print("DRAG ", name, ": no tile")
		return
	var before := [Collection.main.size(), Collection.extra.size(), Collection.side.size()]
	var p0: Vector2 = tile.get_global_rect().get_center()
	_mouse(p0, true)
	await _wait(2)
	for k in 14:
		_move(p0.lerp(p1, (k + 1) / 14.0))
		await _wait(1)
	var t0 := Time.get_ticks_msec()
	await _wait(10)
	print("  10 frames while dragging: ", Time.get_ticks_msec() - t0, " ms")
	var air: bool = b.get("_drag") != null
	if OS.get_environment("DRAG_SHOT") != "":
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [OS.get_environment("DRAG_SHOT"), name.replace(" ", "_")])
	var zone: String = b.get("_drag_to")
	var t1 := Time.get_ticks_msec()
	_mouse(p1, false)
	await _wait(1)
	print("  drop frame: ", Time.get_ticks_msec() - t1, " ms")
	await _wait(12)
	print("DRAG ", name, ": in the air ", air, " zone '", zone, "' deck ", before, " -> ", [Collection.main.size(), Collection.extra.size(), Collection.side.size()])

func _mouse(p: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = p
	e.global_position = p
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	get_viewport().warp_mouse(p)
	Input.parse_input_event(e)

func _move(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().warp_mouse(p)
	Input.parse_input_event(e)
