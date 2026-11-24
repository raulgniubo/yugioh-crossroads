class_name CardPicker
extends PanelContainer
## One box to choose cards in. Tap a card to choose it, tap it again to take it back, then
## Confirm. It is used for every pick that is not made on the table itself: cards in your hand,
## your Deck, a Graveyard, the Extra Deck, or a mix of places (Tributes for a Ritual, materials).
##
## With one card to choose, a second tap on the chosen card confirms it.
## "live" picks (materials the rules check one at a time) answer on every tap and the box stays
## open in between, so it reads as one pick and not as a row of pop-ups.

signal done(result)      # an Array of cards; in a live pick the card tapped or "finish"; null = cancelled

const TINT := Color("7fd8ff")
const CHOSEN := Color("5df07a")

var hud
var cards: Array = []
var chosen: Array = []       # in the order they were tapped
var o := {}
var lo := 1
var hi := 1
var live := false
var _tiles := {}             # uid -> {"pic", "rim", "badge", "num", "home"}
var _grid: GridContainer
var _scroll: ScrollContainer
var _cell_w := 0.0
var _count: Label
var _count_box: PanelContainer
var _info: Label
var _ok: Button
var _bar: Button
var _closed := false
var _frozen := false
var _body: VBoxContainer


func open(h, text: String, list: Array, opts: Dictionary, animate := true) -> void:
	hud = h
	cards = list
	o = opts
	lo = int(o.get("min", 1))
	hi = int(o.get("max", 1))
	live = bool(o.get("live", false))
	chosen = (o.get("chosen", []) as Array).duplicate() if live else []
	_closed = false
	_frozen = false
	_tiles.clear()
	if _bar != null and is_instance_valid(_bar):
		_bar.queue_free()
	if _body != null and is_instance_valid(_body):
		remove_child(_body)
		_body.queue_free()
	var tint: Color = o.get("tint", TINT)
	add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.042, 0.078, 0.156, 0.97), 22, Color(tint, 0.7)))
	z_index = 60
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	add_child(_body)
	# The question, how many are chosen, and a way to look at the table first.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	_body.add_child(head)
	var t := UITheme.label(text, 30, Color.WHITE, UITheme.title_font())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_count_box = PanelContainer.new()
	var cb := UITheme.panel_box(Color(tint, 0.16), 14, Color(tint, 0.8))
	cb.content_margin_left = 14
	cb.content_margin_right = 14
	cb.content_margin_top = 2
	cb.content_margin_bottom = 2
	_count_box.add_theme_stylebox_override("panel", cb)
	_count_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_count = UITheme.label("", 24, Color.WHITE, UITheme.title_font())
	_count_box.add_child(_count)
	_count_box.visible = hi > 1 or live
	head.add_child(_count_box)
	var fold: Array = hud._foldable(self, text, tint)
	head.add_child(fold[0])
	_bar = fold[1]
	var why := str(o.get("why", ""))
	if why != "":
		var wl := UITheme.label(why, 19, UITheme.TEXT_DIM)
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wl.custom_minimum_size = Vector2(620, 0)
		_body.add_child(wl)
	_info = UITheme.label("", 20, Comic.YELLOW, UITheme.semi_font())
	_info.visible = false
	_body.add_child(_info)
	# (room for a chosen card to lift without touching the line above)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	_body.add_child(gap)
	# Up to nine across; long lists (a Deck search) wrap and scroll.
	var all: Array = cards.duplicate()
	if live:
		for c in chosen:
			if not all.has(c):
				all.append(c)
	var small := all.size() > 6
	var csize := Vector2(110, 161) if small else Vector2(150, 219)
	var hidden: Array = o.get("hidden", [])
	var labels: Dictionary = o.get("labels", {})
	var grid := GridContainer.new()
	_grid = grid
	_scroll = null
	_cell_w = csize.x
	grid.columns = clampi(all.size(), 1, 9)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	if all.size() > 18:
		var sc := ScrollContainer.new()
		_scroll = sc
		sc.custom_minimum_size = Vector2(9 * (csize.x + 18) + 24, 520)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_body.add_child(sc)
		# (room above the first row for a chosen card to lift, and beside the scroll bar)
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_top", 14)
		pad.add_theme_constant_override("margin_right", 14)
		sc.add_child(pad)
		pad.add_child(grid)
	else:
		_body.add_child(grid)
	var nth := 0
	for c in all:
		var secret: bool = hidden.has(c)
		var cap := str(labels.get(c.uid, ""))
		var cell := Control.new()
		cell.custom_minimum_size = csize + Vector2(8, 22 + (22 if cap != "" else 0))
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pic := TextureRect.new()
		pic.texture = Cards.duel_back(int(c.owner)) if secret else Cards.get_face(c.id)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.size = csize
		pic.position = Vector2(4, 18)
		pic.pivot_offset = csize / 2.0
		pic.mouse_filter = Control.MOUSE_FILTER_STOP
		pic.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cell.add_child(pic)
		var rim := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.border_color = CHOSEN.lightened(0.2)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(8)
		sb.set_expand_margin_all(3)
		sb.shadow_color = Color(CHOSEN, 0.6)
		sb.shadow_size = 16
		rim.add_theme_stylebox_override("panel", sb)
		rim.set_anchors_preset(Control.PRESET_FULL_RECT)
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rim.visible = false
		pic.add_child(rim)
		var badge := PanelContainer.new()
		var bb := StyleBoxFlat.new()
		bb.bg_color = CHOSEN
		bb.set_corner_radius_all(17)
		bb.border_color = Color(Comic.INK, 0.9)
		bb.set_border_width_all(3)
		badge.add_theme_stylebox_override("panel", bb)
		badge.custom_minimum_size = Vector2(34, 34)
		badge.position = Vector2(csize.x - 24, -12)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = false
		var num := UITheme.label("", 20, Comic.INK, UITheme.title_font())
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(num)
		pic.add_child(badge)
		if cap != "":
			var cl := UITheme.label(cap, 15, UITheme.TEXT_DIM)
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cl.clip_text = true
			cl.position = Vector2(0, csize.y + 20)
			cl.size = Vector2(csize.x + 8, 20)
			cell.add_child(cl)
		pic.mouse_entered.connect(func():
			hud.inspect(c, secret)
			if not _frozen:
				_lift(c, true))
		pic.mouse_exited.connect(func(): _lift(c, false))
		pic.gui_input.connect(func(e):
			if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
				_tap(c))
		grid.add_child(cell)
		_tiles[c.uid] = {"pic": pic, "rim": rim, "badge": badge, "num": num, "hover": false}
		if animate:
			# The cards are dealt into the box one after the other.
			pic.modulate.a = 0.0
			pic.scale = Vector2(0.8, 0.8)
			var d := minf(0.012 * nth, 0.3)
			var tw := create_tween().set_parallel()
			tw.tween_property(pic, "modulate:a", 1.0, 0.1).set_delay(0.05 + d)
			tw.tween_property(pic, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.05 + d)
		nth += 1
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 16)
	_body.add_child(foot)
	var cancel := str(o.get("cancel", ""))
	if cancel != "":
		var no := Button.new()
		no.text = cancel
		no.custom_minimum_size = Vector2(200, 54)
		no.pressed.connect(func(): _finish(null))
		foot.add_child(no)
	_ok = Button.new()
	_ok.text = str(o.get("confirm", Loc.t("Confirm")))
	_ok.custom_minimum_size = Vector2(300, 54)
	_ok.add_theme_font_size_override("font_size", 24)
	_ok.add_theme_stylebox_override("normal", UITheme.button_box(Color(CHOSEN, 0.3), CHOSEN, 14))
	_ok.add_theme_stylebox_override("hover", UITheme.button_box(Color(CHOSEN, 0.55), Color.WHITE, 14))
	_ok.add_theme_stylebox_override("focus", UITheme.button_box(Color(CHOSEN, 0.45), Color.WHITE, 14))
	_ok.add_theme_stylebox_override("disabled", UITheme.button_box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.14), 14))
	_ok.pressed.connect(func(): _finish("finish" if live else chosen.duplicate()))
	_ok.visible = not live or bool(o.get("finish", false))
	foot.add_child(_ok)
	_refresh()
	reset_size()
	if animate:
		modulate.a = 0.0
	await get_tree().process_frame
	if not is_inside_tree():
		return
	reset_size()
	var vs := get_viewport_rect().size
	# (0.74.2) Right of the card panel, never over it: a card in the list is read there while you
	# choose. Too wide for the room left: fewer cards to a row (more rows).
	var left := 20.0
	if hud != null and "_inspect_panel" in hud and hud._inspect_panel != null and is_instance_valid(hud._inspect_panel):
		left = hud._inspect_panel.offset_right + 18.0
	var room := vs.x - left - 16.0
	while size.x > room and _grid != null and _grid.columns > 3:
		_grid.columns -= 1
		if _scroll != null:
			_scroll.custom_minimum_size.x = _grid.columns * (_cell_w + 18) + 24
		reset_size()
		await get_tree().process_frame
		if not is_inside_tree():
			return
		reset_size()
	var x := left + maxf(0.0, (room - size.x) / 2.0)
	if size.x > room:
		x = maxf(16.0, vs.x - 16.0 - size.x)
	position = Vector2(x, clampf((vs.y - size.y) * 0.42, 16.0, vs.y * 0.3))
	if animate:
		pivot_offset = size / 2.0
		scale = Vector2(0.94, 0.94)
		var tw2 := create_tween().set_parallel()
		tw2.tween_property(self, "modulate:a", 1.0, 0.14)
		tw2.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("spell", -4.0, 0.8)


func _valid() -> bool:
	if live:
		return bool(o.get("finish", false))
	var v = o.get("valid")
	if v is Callable and (v as Callable).is_valid():
		return bool((v as Callable).call(chosen))
	return chosen.size() >= lo and chosen.size() <= hi


func _tap(c) -> void:
	if _closed or _frozen:
		return
	if live:
		Sfx.play("card", -8.0, 1.2 if not chosen.has(c) else 0.9)
		_finish(c)
		return
	if chosen.has(c):
		if hi == 1 and _valid():
			# One card to choose: a second tap on it is the answer.
			Sfx.play("click", -6.0, 1.1)
			_finish(chosen.duplicate())
			return
		chosen.erase(c)
		Sfx.play("card", -10.0, 0.9)
	elif hi <= 1:
		chosen = [c]
		Sfx.play("card", -8.0, 1.2)
	elif chosen.size() >= hi:
		Sfx.play("error", -10.0)
		_nudge(_count_box)
		return
	else:
		chosen.append(c)
		Sfx.play("card", -8.0, 1.15 + 0.06 * chosen.size())
	_refresh()


func _nudge(n: Control) -> void:
	if n == null or not is_instance_valid(n):
		return
	n.pivot_offset = n.size / 2.0
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(1.18, 1.18), 0.07)
	tw.tween_property(n, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _lift(c, on: bool) -> void:
	var t = _tiles.get(c.uid)
	if t == null:
		return
	t["hover"] = on
	_place(c)


func _place(c) -> void:
	var t = _tiles.get(c.uid)
	if t == null or not is_instance_valid(t["pic"]):
		return
	var pic: TextureRect = t["pic"]
	var picked := chosen.has(c)
	var y := 18.0 - (14.0 if picked else 0.0) - (5.0 if t["hover"] else 0.0)
	var old: Tween = pic.get_meta("tw") if pic.has_meta("tw") else null
	if old and old.is_valid():
		old.kill()
	var tw := create_tween().set_parallel()
	tw.tween_property(pic, "position:y", y, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pic, "scale", Vector2(1.04, 1.04) if (picked or t["hover"]) else Vector2.ONE, 0.12)
	tw.tween_property(pic, "modulate:a", 1.0, 0.08)
	pic.set_meta("tw", tw)


func _refresh() -> void:
	var full: bool = not live and hi > 1 and chosen.size() >= hi
	for c in cards + (chosen if live else []):
		var t = _tiles.get(c.uid)
		if t == null:
			continue
		var picked := chosen.has(c)
		(t["rim"] as Panel).visible = picked
		(t["badge"] as Control).visible = picked
		(t["num"] as Label).text = str(chosen.find(c) + 1) if (hi > 1 or live) else "✓"
		(t["pic"] as TextureRect).self_modulate = Color(0.55, 0.6, 0.7) if (full and not picked) else Color.WHITE
		_place(c)
	if live:
		_count.text = Loc.t("%d chosen") % chosen.size()
	elif lo == hi:
		_count.text = "%d / %d" % [chosen.size(), hi]
	else:
		_count.text = Loc.t("%d chosen   ·   %d to %d") % [chosen.size(), lo, hi]
	var info = o.get("info")
	if info is Callable and (info as Callable).is_valid():
		_info.text = str((info as Callable).call(chosen))
		_info.visible = _info.text != ""
	var ok := _valid()
	if _ok.disabled == ok and ok:
		# It just became possible: the button says so.
		_nudge(_ok)
		_ok.grab_focus()
	_ok.disabled = not ok


func _finish(result) -> void:
	if _closed or _frozen:
		return
	if live:
		_frozen = true
	else:
		_closed = true
	done.emit(result)


## Gone, with its fold-away bar.
func close() -> void:
	_closed = true
	if _bar != null and is_instance_valid(_bar):
		_bar.queue_free()
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_property(self, "scale", Vector2(0.96, 0.96), 0.1)
	tw.chain().tween_callback(queue_free)
