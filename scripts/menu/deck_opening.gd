class_name DeckOpening
extends Control
## Buying a ready-made deck: the box drops in, shakes, the lid flies off in a burst of light,
## the whole deck spills out as a wall of cards, and its best cards turn over up front, the
## way a booster pack opens. Tap or press to skip ahead.

signal closed

var _entry := {}
var _before := {}
var _color := Color("7cc4ff")
var _done := false
var _skip := false
var _fx: Control
var _beams: Array = []      # [x, color, born]
var _sparks: Array = []     # [pos, vel, color, born]
var _t := 0.0
var _btn: Button


func _init(entry: Dictionary, owned_before: Dictionary) -> void:
	_entry = entry
	_before = owned_before
	_color = entry.get("color", Color("7cc4ff"))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	theme = UITheme.build()
	var bg := ColorRect.new()
	bg.color = Color(0.008, 0.012, 0.03, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	create_tween().tween_property(bg, "color:a", 0.95, 0.25)
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_run.call_deferred()


func _process(delta: float) -> void:
	_t += delta
	for s in _sparks:
		s[0] += s[1] * delta
		s[1].y += 520.0 * delta
	_sparks = _sparks.filter(func(s): return _t - s[3] < 1.2)
	_beams = _beams.filter(func(b): return _t - b[2] < 1.8)
	_fx.queue_redraw()


func _draw_fx() -> void:
	for b in _beams:
		var a := clampf(1.0 - (_t - b[2]) / 1.8, 0.0, 1.0)
		var w := 220.0 * (0.4 + 0.6 * a)
		var c: Color = b[1]
		for i in 5:
			var ww := w * (1.0 - i * 0.17)
			_fx.draw_rect(Rect2(b[0] - ww / 2.0, 0, ww, size.y), Color(c.r, c.g, c.b, 0.07 * a))
	for s in _sparks:
		var a2 := clampf(1.0 - (_t - s[3]) / 1.2, 0.0, 1.0)
		var c2: Color = s[2]
		_fx.draw_circle(s[0], 3.5 * a2 + 1.0, Color(c2.r, c2.g, c2.b, a2))


func _burst(at: Vector2, color: Color, n: int) -> void:
	for i in n:
		var ang := randf() * TAU
		_sparks.append([at, Vector2(cos(ang), sin(ang)) * randf_range(140.0, 600.0) + Vector2(0, -180), color.lightened(randf() * 0.5), _t])


func _wait(sec: float) -> void:
	if _skip:
		return
	await get_tree().create_timer(sec).timeout


func _run() -> void:
	var center := size / 2.0
	var key := str(_entry.get("key", ""))
	# The box.
	var box := DeckBox.new().setup(_entry)
	box.size = Vector2(206, 290)
	box.pivot_offset = Vector2(103, 145)
	box.glow = 0.8
	add_child(box)
	box.position = Vector2(center.x - 103, -340)
	Sfx.play("whoosh", -4.0)
	var drop := create_tween()
	drop.tween_property(box, "position:y", center.y - 145, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await drop.finished
	for i in 3:
		Sfx.play("charge", -8.0, 0.9 + i * 0.15)
		var sh := create_tween()
		for k in 6:
			sh.tween_property(box, "rotation", deg_to_rad((2.5 + i * 2.0) * (1 if k % 2 == 0 else -1)), 0.04)
		sh.tween_property(box, "rotation", 0.0, 0.04)
		await sh.finished
		await _wait(0.1)
	# The lid flies off.
	Sfx.play("pack_rip", -2.0)
	var lid := ColorRect.new()
	lid.color = _color.darkened(0.25)
	lid.size = Vector2(206, 34)
	lid.position = box.position
	lid.pivot_offset = Vector2(103, 17)
	add_child(lid)
	var off := create_tween().set_parallel()
	off.tween_property(lid, "position", lid.position + Vector2(260, -300), 0.45).set_ease(Tween.EASE_OUT)
	off.tween_property(lid, "rotation", 1.4, 0.45)
	off.tween_property(lid, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
	off.chain().tween_callback(lid.queue_free)
	_beams.append([center.x, _color.lightened(0.4), _t])
	_burst(Vector2(center.x, box.position.y + 20), _color.lightened(0.3), 34)
	var swell := create_tween()
	swell.tween_property(box, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE)
	await swell.finished
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.5)
	_burst(center, _color, 80)
	Sfx.play("rare", -3.0)
	var gone := create_tween().set_parallel()
	gone.tween_property(box, "scale", Vector2(1.6, 1.6), 0.25)
	gone.tween_property(box, "modulate:a", 0.0, 0.25)
	# The whole deck spills out: every different card in it, as a wall behind.
	var all_ids: Array = []
	for id in CardData.deck_list(key) + CardData.extra_list(key):
		if not all_ids.has(id):
			all_ids.append(id)
	all_ids.sort_custom(func(a, b): return CardData.rarity(a) > CardData.rarity(b) if CardData.rarity(a) != CardData.rarity(b) else int(CardData.get_card(a).get("atk", 0)) > int(CardData.get_card(b).get("atk", 0)))
	var small := Vector2(92, 134)
	var per_row := mini(14, maxi(1, all_ids.size()))
	var rows := int(ceil(all_ids.size() / float(per_row)))
	var wall_w := per_row * (small.x + 8) - 8
	var top := 70.0
	var news := 0
	for i in all_ids.size():
		var id: int = all_ids[i]
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(id)
		tr.size = small
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.pivot_offset = small / 2.0
		tr.position = center - small / 2.0
		tr.scale = Vector2(0.2, 0.2)
		tr.modulate.a = 0.0
		Foil.apply(tr, CardData.rarity(id), id)
		add_child(tr)
		tr.custom_minimum_size = small
		tr.size = small
		var r := i / per_row
		var col := i % per_row
		var to := Vector2(center.x - wall_w / 2.0 + col * (small.x + 8), top + r * (small.y + 8))
		var fly := create_tween().set_parallel()
		var dl := 0.0 if _skip else i * 0.018
		fly.tween_property(tr, "position", to, 0.35).set_delay(dl).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		fly.tween_property(tr, "scale", Vector2.ONE, 0.35).set_delay(dl)
		fly.tween_property(tr, "modulate:a", 0.55, 0.35).set_delay(dl)
		if int(_before.get(id, 0)) == 0:
			news += 1
	await _wait(0.4 + all_ids.size() * 0.018)
	box.queue_free()
	flash.queue_free()
	# Its best cards up front, turning over one by one.
	var best: Array = all_ids.slice(0, mini(4, all_ids.size()))
	var big := Vector2(214, 312)
	var gap := 30.0
	var total := best.size() * big.x + (best.size() - 1) * gap
	var y := top + rows * (small.y + 8) + 10.0
	y = minf(y, size.y - big.y - 150.0)
	for i in best.size():
		var id2: int = best[i]
		var holder := Control.new()
		holder.size = big
		holder.pivot_offset = big / 2.0
		holder.position = Vector2(center.x - total / 2.0 + i * (big.x + gap), size.y + 40)
		add_child(holder)
		var tr2 := TextureRect.new()
		tr2.texture = Cards.get_back()
		tr2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr2)
		tr2.size = big
		var up := create_tween()
		up.tween_property(holder, "position:y", y, 0.35).set_delay(0.0 if _skip else i * 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await _wait(0.12)
		var rr := CardData.rarity(id2)
		var colr: Color = Foil.COLORS[rr]
		var t1 := create_tween()
		t1.tween_property(holder, "scale:x", 0.0, 0.1)
		await t1.finished
		tr2.texture = Cards.get_face(id2)
		Foil.apply(tr2, rr, id2)
		var t2 := create_tween()
		t2.tween_property(holder, "scale:x", 1.0, 0.12)
		var at := holder.position + big / 2.0
		if rr >= 2:
			Sfx.play("rare", -3.0, 1.0 + 0.1 * rr)
			_beams.append([at.x, colr, _t])
			_burst(at, colr, 40)
		else:
			Sfx.play("sparkle", -4.0)
			_burst(at, colr, 14)
		await _wait(0.35)
	# What it means for your collection.
	var title := UITheme.label(Loc.t(str(_entry.get("name", ""))).to_upper(), 46, _color.lightened(0.4), UITheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(size.x, 60)
	title.position = Vector2(0, 8)
	add_child(title)
	var n_cards := CardData.deck_list(key).size() + CardData.extra_list(key).size()
	var line := UITheme.label(Loc.t("%d cards are yours, %d of them new to your collection.") % [n_cards, news], 24, Color.WHITE)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.size = Vector2(size.x, 34)
	line.position = Vector2(0, size.y - 112)
	add_child(line)
	_done = true
	_btn = Button.new()
	_btn.text = "  " + Loc.t("Continue") + "  "
	_btn.add_theme_font_size_override("font_size", 26)
	add_child(_btn)
	await get_tree().process_frame
	_btn.position = Vector2(center.x - _btn.size.x / 2.0, size.y - 70)
	_btn.pressed.connect(_close)
	_btn.grab_focus()


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _done:
		_skip = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _done:
			_close()
		else:
			_skip = true
