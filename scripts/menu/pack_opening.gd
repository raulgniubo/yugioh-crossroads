class_name PackOpening
extends Control
## The pack-opening scene: the pack drops in and shakes, tears open in a flash, and the cards
## fan out face-down. They flip one at a time; rare pulls get a glow, a light beam and a sting.

signal closed

var _pulls: Array = []
var _before := {}
var _color := Color("7cc4ff")
var _title := ""
var _pack := {}
var _cards: Array = []
var _done := false
var _skip := false
var _fx: Control
var _beams: Array = []      # [x, color, born]
var _sparks: Array = []     # [pos, vel, color, born]
var _t := 0.0
var _btn: Button


func _init(pulls: Array, owned_before: Dictionary, color: Color, title: String, pack := {}) -> void:
	_pulls = pulls
	_before = owned_before
	_color = color
	_title = title
	_pack = pack if not pack.is_empty() else {"name": title, "color": color, "key": ""}


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
	create_tween().tween_property(bg, "color:a", 0.94, 0.25)
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
	_sparks = _sparks.filter(func(s): return _t - s[3] < 1.1)
	_beams = _beams.filter(func(b): return _t - b[2] < 1.6)
	_fx.queue_redraw()


func _draw_fx() -> void:
	for b in _beams:
		var age: float = _t - b[2]
		var a := clampf(1.0 - age / 1.6, 0.0, 1.0)
		var w := 150.0 * (0.4 + 0.6 * a)
		var c: Color = b[1]
		for i in 5:
			var ww := w * (1.0 - i * 0.17)
			_fx.draw_rect(Rect2(b[0] - ww / 2.0, 0, ww, size.y), Color(c.r, c.g, c.b, 0.07 * a))
	for s in _sparks:
		var a2 := clampf(1.0 - (_t - s[3]) / 1.1, 0.0, 1.0)
		var c2: Color = s[2]
		_fx.draw_circle(s[0], 3.5 * a2 + 1.0, Color(c2.r, c2.g, c2.b, a2))


func _burst(at: Vector2, color: Color, n: int) -> void:
	for i in n:
		var ang := randf() * TAU
		_sparks.append([at, Vector2(cos(ang), sin(ang)) * randf_range(120.0, 520.0) + Vector2(0, -160), color.lightened(randf() * 0.5), _t])


func _wait(sec: float) -> void:
	if _skip:
		return
	await get_tree().create_timer(sec).timeout


func _run() -> void:
	var center := size / 2.0
	# The pack.
	var pack := PackWrapper.new().setup(_pack)
	pack.custom_minimum_size = Vector2(250, 384)
	pack.size = Vector2(250, 384)
	pack.pivot_offset = Vector2(125, 192)
	pack.glow = 0.6
	add_child(pack)
	pack.position = Vector2(center.x - 125, -420)
	Sfx.play("whoosh", -4.0)
	var drop := create_tween()
	drop.tween_property(pack, "position:y", center.y - 190, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await drop.finished
	# Shake, harder each time.
	for i in 3:
		Sfx.play("charge", -8.0, 0.9 + i * 0.15)
		var sh := create_tween()
		for k in 6:
			sh.tween_property(pack, "rotation", deg_to_rad((3.0 + i * 2.5) * (1 if k % 2 == 0 else -1)), 0.04)
		sh.tween_property(pack, "rotation", 0.0, 0.04)
		await sh.finished
		await _wait(0.12)
	# Rip: the top seal peels off and flutters away before the light comes out.
	Sfx.play("pack_rip", -2.0)
	if not _skip:
		pack.torn = true
		pack.sheen = false
		var strip := ColorRect.new()
		strip.color = _color.darkened(0.35)
		strip.size = PackWrapper.seal_rect(pack.size).size
		strip.position = pack.position
		strip.pivot_offset = Vector2(0, strip.size.y / 2.0)
		add_child(strip)
		var peel := create_tween().set_parallel()
		peel.tween_property(strip, "rotation", -1.1, 0.42).set_ease(Tween.EASE_OUT)
		peel.tween_property(strip, "position", strip.position + Vector2(170, -210), 0.42).set_ease(Tween.EASE_OUT)
		peel.tween_property(strip, "modulate:a", 0.0, 0.42).set_ease(Tween.EASE_IN)
		peel.chain().tween_callback(strip.queue_free)
		# Light leaks out of the open top and the pack swells.
		_beams.append([center.x, _color.lightened(0.4), _t])
		_burst(Vector2(center.x, pack.position.y + 20), _color.lightened(0.3), 26)
		var swell := create_tween()
		swell.tween_property(pack, "scale", Vector2(1.08, 1.08), 0.3).set_trans(Tween.TRANS_SINE)
		await swell.finished
		await _wait(0.12)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.45)
	_burst(center, _color, 60)
	var gone := create_tween().set_parallel()
	gone.tween_property(pack, "scale", Vector2(1.5, 1.5), 0.25)
	gone.tween_property(pack, "modulate:a", 0.0, 0.25)
	# Cards fan out face-down.
	var n := _pulls.size()
	var card_size := Vector2(232, 338)
	var gap := 26.0
	var total := n * card_size.x + (n - 1) * gap
	# Best card last.
	var order := range(n)
	for i in n:
		var id: int = _pulls[i]
		var holder := Control.new()
		holder.size = card_size
		holder.pivot_offset = card_size / 2.0
		holder.position = center - card_size / 2.0
		holder.scale = Vector2(0.3, 0.3)
		add_child(holder)
		var glow := Panel.new()
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.offset_left = -10
		glow.offset_top = -10
		glow.offset_right = 10
		glow.offset_bottom = 10
		glow.modulate.a = 0.0
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(glow)
		var tr := TextureRect.new()
		tr.texture = Cards.get_back()
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
		var tag := UITheme.label("", 20, Color.WHITE, UITheme.title_font())
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.position = Vector2(-30, card_size.y + 12)
		tag.size = Vector2(card_size.x + 60, 30)
		tag.modulate.a = 0.0
		holder.add_child(tag)
		var newl := UITheme.label("", 20, Color("ffd23a"), UITheme.title_font())
		newl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		newl.position = Vector2(0, -38)
		newl.size = Vector2(card_size.x, 30)
		newl.modulate.a = 0.0
		holder.add_child(newl)
		_cards.append({"id": id, "holder": holder, "tr": tr, "glow": glow, "tag": tag, "new": newl})
		var to := Vector2(center.x - total / 2.0 + i * (card_size.x + gap), center.y - card_size.y / 2.0 - 10)
		var fly := create_tween().set_parallel()
		fly.tween_property(holder, "position", to, 0.4).set_delay(i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		fly.tween_property(holder, "scale", Vector2.ONE, 0.4).set_delay(i * 0.07)
		fly.tween_callback(func(): Sfx.play("card", -5.0, 0.9 + i * 0.07)).set_delay(i * 0.07)
	await _wait(0.4 + n * 0.07 + 0.25)
	pack.queue_free()
	flash.queue_free()
	# Flip them one by one, the commons quickly, the good ones with a build-up.
	order.sort_custom(func(a, b): return CardData.rarity(_pulls[a]) < CardData.rarity(_pulls[b]) if CardData.rarity(_pulls[a]) != CardData.rarity(_pulls[b]) else a < b)
	for i in order:
		await _flip(_cards[i])
	_done = true
	_btn = Button.new()
	_btn.text = "  Continue  "
	_btn.add_theme_font_size_override("font_size", 26)
	add_child(_btn)
	await get_tree().process_frame
	_btn.position = Vector2(center.x - _btn.size.x / 2.0, size.y - 120)
	_btn.pressed.connect(_close)
	_btn.grab_focus()


func _flip(c: Dictionary) -> void:
	var id: int = c["id"]
	var r := CardData.rarity(id)
	var col: Color = Foil.COLORS[r]
	var holder: Control = c["holder"]
	var tr: TextureRect = c["tr"]
	var at := holder.position + holder.size / 2.0
	if r >= 2 and not _skip:
		# Build-up: the card lifts and trembles before it turns.
		Sfx.play("charge", -5.0, 1.0 + 0.2 * (r - 2))
		var lift := create_tween()
		lift.tween_property(holder, "position:y", holder.position.y - 26, 0.25)
		for k in 8:
			lift.tween_property(holder, "rotation", deg_to_rad(2.5 * (1 if k % 2 == 0 else -1)), 0.04)
		lift.tween_property(holder, "rotation", 0.0, 0.04)
		await lift.finished
	var t1 := create_tween()
	t1.tween_property(holder, "scale:x", 0.0, 0.1)
	await t1.finished
	tr.texture = Cards.get_face(id)
	Foil.apply(tr, r)
	var sb := UITheme.panel_box(Color(col.r, col.g, col.b, 0.35), 16, col)
	(c["glow"] as Panel).add_theme_stylebox_override("panel", sb)
	var t2 := create_tween().set_parallel()
	t2.tween_property(holder, "scale:x", 1.0, 0.12)
	if r >= 1:
		t2.tween_property(c["glow"], "modulate:a", 1.0, 0.2)
	(c["tag"] as Label).text = Loc.t(Foil.NAMES[r]).to_upper() if r >= 1 else ""
	(c["tag"] as Label).add_theme_color_override("font_color", col)
	t2.tween_property(c["tag"], "modulate:a", 1.0, 0.2)
	if int(_before.get(id, 0)) == 0:
		(c["new"] as Label).text = Loc.t("NEW!")
		t2.tween_property(c["new"], "modulate:a", 1.0, 0.2)
		_before[id] = 1
	match r:
		0:
			Sfx.play("card", -3.0)
		1:
			Sfx.play("sparkle", -4.0)
			_burst(at, col, 14)
		2:
			Sfx.play("rare", -2.0)
			_beams.append([at.x, col, _t])
			_burst(at, col, 40)
		_:
			Sfx.play("rare", 0.0, 1.15)
			Sfx.play("cheer", -8.0)
			_beams.append([at.x, col, _t])
			_beams.append([at.x, Color("7cf0ff"), _t])
			_burst(at, col, 60)
			_burst(at, Color("ffe07a"), 40)
			var pop := create_tween()
			pop.tween_property(holder, "scale", Vector2(1.14, 1.14), 0.12)
			pop.tween_property(holder, "scale", Vector2.ONE, 0.2)
	await _wait(0.22 if r == 0 else (0.5 if r == 1 else 0.95))


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
