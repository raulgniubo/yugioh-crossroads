extends Control
## The chain, where you can read it (0.63.2). The numbered links over the cards on the table say
## where each card is; this says what the chain is.
## - A card that is chained gets its moment: it shows large in the middle with a gold glow, its name
##   and what it does written beside it, then tucks into a strip beside the card panel so the table
##   is free again while you decide whether to respond.
## - The strip is a ladder: your cards on the left, the rival's a step to the right, each with its
##   number on a gold coin and its owner's color (blue yours, red theirs), joined by a chain.
## - When the chain resolves it goes backwards, one card at a time: the card comes forward large,
##   you read it, it steps aside and its effect plays on the table, and only then is it the next
##   one's turn. A negated card gets a red cross.
## - Point at a card in the strip (or tap it) to read it in the card panel.
## Made for this game: the idea of a readable chain, not another game's screen.

const TILE := Vector2(92, 134)
const MINE := Color("5fc8ff")
const THEIRS := Color("ff6a7c")
const GOLD := Color("ffd23a")
const LEFT := 418.0          # just right of the card panel
const TOP := 150.0
const ROOM := 600.0          # the height the stack may take
const ZIG := 54.0            # the rival's cards sit this far to the right of yours
const BIG := 2.15            # how large a card is shown in its moment in the middle
const STEP_OUT := 1.32       # ...and while its effect plays, back in the strip

var hud
var _tiles := {}             # n -> {"root", "pic", "rim", "halo", "badge", "p", "card", "home", "state"}
var _first := {}             # link 1 waits here until a second card is chained
var _focus := 0
var _head: Label
var _caption: PanelContainer
var _cap_n: Label
var _cap_name: Label
var _cap_text: Label
var _t := 0.0


func _init(h) -> void:
	hud = h
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 12
	_head = UITheme.label("", 20, GOLD, UITheme.title_font())
	_head.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_head.add_theme_constant_override("shadow_offset_y", 2)
	_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_head.position = Vector2(LEFT - 14.0, TOP - 44.0)
	_head.modulate.a = 0.0
	add_child(_head)
	# What is resolving, written beside it.
	_caption = PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.94), 14, Color(GOLD, 0.85))
	sb.set_border_width_all(2)
	sb.content_margin_left = 16
	sb.content_margin_right = 18
	sb.content_margin_top = 9
	sb.content_margin_bottom = 11
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	_caption.add_theme_stylebox_override("panel", sb)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.modulate.a = 0.0
	_caption.z_index = 40
	add_child(_caption)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_child(v)
	_cap_n = UITheme.label("", 15, GOLD, UITheme.semi_font())
	v.add_child(_cap_n)
	_cap_name = UITheme.label("", 25, Color.WHITE, UITheme.title_font())
	v.add_child(_cap_name)
	_cap_text = UITheme.label("", 15, Color(0.82, 0.88, 0.98), UITheme.body_font())
	_cap_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cap_text.custom_minimum_size = Vector2(330, 0)
	_cap_text.max_lines_visible = 3
	v.add_child(_cap_text)
	for l in [_cap_n, _cap_name, _cap_text]:
		(l as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _tiles.is_empty():
		return
	_t += delta
	# The one resolving breathes; the chain between the cards is redrawn as they move.
	if _tiles.has(_focus):
		var rim: Panel = _tiles[_focus]["rim"]
		rim.modulate.a = 0.75 + 0.25 * sin(_t * 7.0)
	for k in _tiles:
		var h: Panel = _tiles[k]["halo"]
		if h.modulate.a > 0.05:
			h.self_modulate.a = 0.78 + 0.22 * sin(_t * 9.0)
	queue_redraw()


## Where link n sits: a ladder going down, yours on the left and the rival's a step to the right.
func _home(n: int) -> Vector2:
	var count := maxi(_tiles.size(), 2)
	var step := minf(82.0, (ROOM - TILE.y) / float(count - 1))
	var theirs: bool = _tiles.has(n) and int(_tiles[n]["p"]) != 0
	return Vector2(LEFT + (ZIG if theirs else 0.0), TOP + (n - 1) * step)


## The middle of the screen, where a card has its moment (the top-left corner of a tile there).
func _stage() -> Vector2:
	var vs := get_viewport_rect().size
	return Vector2(vs.x * 0.5 - TILE.x * 0.5 - 150.0, vs.y * 0.43 - TILE.y * 0.5)


func _show_caption(n: int, at: Vector2, word := "") -> void:
	var card = _tiles[n]["card"]
	var mine: bool = int(_tiles[n]["p"]) == 0
	_cap_n.text = (Loc.t("CHAIN %d") % n) + "  ·  " + (word if word != "" else (Loc.t("your card") if mine else Loc.t("their card")))
	_cap_n.add_theme_color_override("font_color", MINE if mine else THEIRS)
	_cap_name.text = str(card.cname())
	_cap_name.add_theme_color_override("font_color", Color.WHITE)
	_cap_text.text = first_line(card)
	_cap_text.visible = _cap_text.text != ""
	(_caption.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(GOLD, 0.85)
	_caption.reset_size()
	_caption.position = at
	_caption.pivot_offset = Vector2(0, 40)
	_caption.scale = Vector2(0.9, 0.9)
	if _cap_tw != null and _cap_tw.is_valid():
		_cap_tw.kill()
	_cap_tw = _caption.create_tween().set_parallel()
	_cap_tw.tween_property(_caption, "modulate:a", 1.0, 0.14)
	_cap_tw.tween_property(_caption, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

var _cap_tw: Tween


func _hide_caption(after := 0.0) -> void:
	if _cap_tw != null and _cap_tw.is_valid():
		_cap_tw.kill()
	_cap_tw = _caption.create_tween()
	if after > 0.0:
		_cap_tw.tween_interval(after)
	_cap_tw.tween_property(_caption, "modulate:a", 0.0, 0.14)


## A card goes on the chain. Nothing shows for a chain of one: the first card only appears once a
## second one is chained to it. `hold`: how long the new card has the middle of the screen.
## Returns how long the whole entrance takes.
func link(n: int, p: int, card, hold := 0.75) -> float:
	if n < 1 or card == null:
		return 0.0
	if n == 1:
		clear(true)
		_first = {"p": p, "card": card}
		return 0.0
	if not _tiles.has(1) and not _first.is_empty():
		_add(1, int(_first["p"]), _first["card"], -1.0)
		_first = {}
	# (the one before is no longer the newest: its glow goes)
	for k in _tiles:
		var h: Panel = _tiles[k]["halo"]
		h.create_tween().tween_property(h, "modulate:a", 0.0, 0.2)
	_add(n, p, card, hold)
	_head.text = Loc.t("CHAIN") + "  ×%d" % _tiles.size()
	create_tween().tween_property(_head, "modulate:a", 1.0, 0.15)
	if hud != null and is_instance_valid(hud) and hud.has_method("inspect"):
		hud.inspect(card)
	return 0.2 + hold + 0.26


## `hold` < 0: straight into the strip (the first card, shown when the second arrives).
func _add(n: int, p: int, card, hold: float) -> void:
	if _tiles.has(n):
		return
	var col: Color = MINE if p == 0 else THEIRS
	var root := Control.new()
	root.size = TILE
	root.pivot_offset = TILE / 2.0
	root.z_index = n
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# The newest card on the chain burns gold.
	var halo := Panel.new()
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(GOLD, 0.55)
	hs.set_corner_radius_all(12)
	hs.set_expand_margin_all(9)
	hs.shadow_color = Color(1.0, 0.82, 0.25, 0.85)
	hs.shadow_size = 26
	halo.add_theme_stylebox_override("panel", hs)
	halo.modulate.a = 0.0
	root.add_child(halo)
	# A glow in the owner's color behind the card.
	var rim := Panel.new()
	rim.set_anchors_preset(Control.PRESET_FULL_RECT)
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(col, 0.9)
	rs.set_corner_radius_all(8)
	rs.set_expand_margin_all(4)
	rs.shadow_color = Color(col, 0.55)
	rs.shadow_size = 10
	rim.add_theme_stylebox_override("panel", rs)
	root.add_child(rim)
	var pic := TextureRect.new()
	pic.texture = Cards.get_face(int(card.id))      # (sharp when it is shown large)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.mouse_filter = Control.MOUSE_FILTER_STOP
	pic.mouse_default_cursor_shape = Control.CURSOR_HELP
	root.add_child(pic)
	pic.mouse_entered.connect(func():
		if hud != null and is_instance_valid(hud) and hud.has_method("inspect"):
			hud.inspect(card))
	pic.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and hud != null and hud.has_method("inspect"):
			hud.inspect(card))
	# Its number, on a gold coin at the corner.
	var badge := Panel.new()
	badge.size = Vector2(36, 36)
	badge.position = Vector2(-14, -14)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs := StyleBoxFlat.new()
	bs.bg_color = GOLD
	bs.set_corner_radius_all(18)
	bs.set_border_width_all(3)
	bs.border_color = Color(0.1, 0.07, 0.0)
	bs.shadow_color = Color(0, 0, 0, 0.5)
	bs.shadow_size = 4
	badge.add_theme_stylebox_override("panel", bs)
	root.add_child(badge)
	var num := UITheme.label(str(n), 21, Color(0.1, 0.07, 0.0), UITheme.title_font())
	num.set_anchors_preset(Control.PRESET_FULL_RECT)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(num)
	_tiles[n] = {"root": root, "pic": pic, "rim": rim, "halo": halo, "badge": badge, "p": p, "card": card, "state": "", "home": Vector2.ZERO}
	# Everybody makes room, and the new one drops into its place.
	for k in _tiles:
		var home := _home(int(k))
		_tiles[k]["home"] = home
		if int(k) != n:
			var tr: Control = _tiles[k]["root"]
			tr.create_tween().tween_property(tr, "position", home, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var to: Vector2 = _tiles[n]["home"]
	Sfx.play("chain", -7.0, 0.9 + 0.07 * n)
	if hold < 0.0:
		root.position = to + Vector2(-60, 0)
		root.modulate.a = 0.0
		var tq := root.create_tween().set_parallel()
		tq.tween_property(root, "position", to, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tq.tween_property(root, "modulate:a", 1.0, 0.12)
		return
	# Its moment: large in the middle, glowing, with what it is written beside it. Then into the strip.
	var stage := _stage()
	root.z_index = 30
	root.position = stage
	root.scale = Vector2(BIG * 0.55, BIG * 0.55)
	root.modulate.a = 0.0
	halo.modulate.a = 1.0
	_show_caption(n, stage + Vector2(TILE.x * 0.5 + TILE.x * BIG * 0.5 + 30.0, 20.0))
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector2(BIG, BIG), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "modulate:a", 1.0, 0.1)
	tw.tween_interval(hold)
	tw.tween_callback(func(): _hide_caption())
	tw.tween_property(root, "position", to, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(root, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(halo, "modulate:a", 0.7, 0.26)
	tw.tween_callback(func(): root.z_index = n)


## Link n is resolving now: it comes forward large with its caption, holds for `hold` seconds, then
## steps aside (still lit, beside the strip) while its effect plays on the table.
## Returns how long until it has stepped aside.
func solving(n: int, hold := 0.8) -> float:
	if not _tiles.has(n):
		return 0.0
	_focus = n
	for k in _tiles:
		var t: Dictionary = _tiles[k]
		var r: Control = t["root"]
		(t["halo"] as Panel).modulate.a = 0.0
		if int(k) != n and str(t["state"]) == "":
			r.create_tween().tween_property(r, "modulate", Color(0.62, 0.62, 0.7), 0.2)
	var t2: Dictionary = _tiles[n]
	var root: Control = t2["root"]
	var halo: Panel = t2["halo"]
	t2["state"] = "now"
	root.z_index = 30
	var stage := _stage()
	var aside: Vector2 = (t2["home"] as Vector2) + Vector2(36, 0)
	_show_caption(n, stage + Vector2(TILE.x * 0.5 + TILE.x * BIG * 0.5 + 30.0, 20.0), Loc.t("resolves"))
	var tw := root.create_tween()
	tw.tween_property(root, "position", stage, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "scale", Vector2(BIG, BIG), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "modulate", Color.WHITE, 0.12)
	tw.parallel().tween_property(halo, "modulate:a", 1.0, 0.15)
	tw.tween_interval(hold)
	tw.tween_property(root, "position", aside, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(root, "scale", Vector2(STEP_OUT, STEP_OUT), 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(halo, "modulate:a", 0.0, 0.24)
	# (the caption goes with it and stays while the effect plays)
	tw.parallel().tween_property(_caption, "position", aside + Vector2(TILE.x * 0.5 + TILE.x * STEP_OUT * 0.5 + 16.0, 6.0), 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	Sfx.play("chain", -9.0, 1.25)
	if hud != null and is_instance_valid(hud) and hud.has_method("inspect"):
		hud.inspect(t2["card"])
	return 0.2 + hold + 0.26


## Its effect was stopped: a red cross over the card, and the caption says so.
func negated(n: int) -> void:
	if not _tiles.has(n):
		return
	var t: Dictionary = _tiles[n]
	var r: Control = t["root"]
	t["state"] = "negated"
	for a in [[Vector2(8, 8), TILE - Vector2(8, 8)], [Vector2(TILE.x - 8, 8), Vector2(8, TILE.y - 8)]]:
		var ln := Line2D.new()
		ln.points = PackedVector2Array([a[0], a[0]])
		ln.width = 9.0
		ln.default_color = Color("ff3344")
		ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ln.end_cap_mode = Line2D.LINE_CAP_ROUND
		r.add_child(ln)
		var to: Vector2 = a[1]
		ln.create_tween().tween_method(func(v: Vector2): ln.set_point_position(1, v), a[0], to, 0.14)
	(t["pic"] as TextureRect).create_tween().tween_property(t["pic"], "modulate", Color(0.55, 0.4, 0.42), 0.2)
	# (a short shake)
	var home: Vector2 = r.position
	var tw := r.create_tween()
	for k in 4:
		tw.tween_property(r, "position", home + Vector2(7 if k % 2 == 0 else -7, 0), 0.04)
	tw.tween_property(r, "position", home, 0.04)
	if _focus == n:
		_cap_n.text = (Loc.t("CHAIN %d") % n) + "  ·  " + Loc.t("NEGATED")
		_cap_n.add_theme_color_override("font_color", Color("ff5a6a"))
		_cap_name.add_theme_color_override("font_color", Color(1.0, 0.72, 0.74))
		(_caption.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color("ff5a6a")


## Link n is done: it steps back and goes dark, with a mark that says it has resolved.
func solved(n: int) -> void:
	if not _tiles.has(n):
		return
	var t: Dictionary = _tiles[n]
	var r: Control = t["root"]
	var was_negated: bool = str(t["state"]) == "negated"
	t["state"] = "done"
	r.z_index = n
	(t["rim"] as Panel).modulate.a = 0.35
	var tw := r.create_tween().set_parallel()
	tw.tween_property(r, "scale", Vector2(0.94, 0.94), 0.16)
	tw.tween_property(r, "position", t["home"], 0.16)
	tw.tween_property(r, "modulate", Color(0.42, 0.42, 0.5, 0.9), 0.16)
	if not was_negated:
		var ok := UITheme.label("✓", 40, Color("8dffb0"), UITheme.title_font())
		ok.set_anchors_preset(Control.PRESET_FULL_RECT)
		ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ok.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ok.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		ok.add_theme_constant_override("shadow_offset_y", 2)
		ok.modulate = Color(2.2, 2.2, 2.2)      # (against the darkened tile it sits on)
		r.add_child(ok)
	if _focus == n:
		_focus = 0
		_hide_caption()


## The chain is over (or a new one starts): everything leaves.
func clear(at_once := false) -> void:
	_first = {}
	_focus = 0
	for k in _tiles:
		var r: Control = _tiles[k]["root"]
		if at_once:
			r.queue_free()
		else:
			var tw := r.create_tween()
			tw.tween_interval(0.04 * (_tiles.size() - int(k)))
			tw.tween_property(r, "modulate:a", 0.0, 0.22)
			tw.parallel().tween_property(r, "position:x", r.position.x - 40.0, 0.22)
			tw.tween_callback(r.queue_free)
	_tiles.clear()
	if at_once:
		_head.modulate.a = 0.0
		_caption.modulate.a = 0.0
	else:
		create_tween().tween_property(_head, "modulate:a", 0.0, 0.2)
		_hide_caption()
	queue_redraw()


func showing() -> bool:
	return not _tiles.is_empty()


## The chain between the cards: gold links from each coin to the next.
func _draw() -> void:
	var ns := _tiles.keys()
	ns.sort()
	for i in range(1, ns.size()):
		var a: Dictionary = _tiles[ns[i - 1]]
		var b: Dictionary = _tiles[ns[i]]
		if not is_instance_valid(a["root"]) or not is_instance_valid(b["root"]):
			continue
		var pa: Vector2 = (a["root"] as Control).position + Vector2(4, 4)
		var pb: Vector2 = (b["root"] as Control).position + Vector2(4, 4)
		var alpha := minf((a["root"] as Control).modulate.a, (b["root"] as Control).modulate.a)
		var done: bool = str(b["state"]) == "done"
		var col := Color(GOLD, (0.3 if done else 0.95) * alpha)
		var d := pb - pa
		var steps := maxi(2, int(d.length() / 13.0))
		for s in steps:
			var c := pa + d * ((s + 0.5) / float(steps))
			# (links seen flat and on edge, one after the other, like a real chain)
			var along := d.normalized()
			var half := along * (5.5 if s % 2 == 0 else 3.0)
			draw_line(c - half, c + half, Color(0, 0, 0, 0.55 * alpha), 6.5 if s % 2 == 0 else 3.5, true)
			draw_line(c - half, c + half, col, 4.0 if s % 2 == 0 else 2.0, true)


## What the card does, in one line: the first sentence of its text in the game's language.
static func first_line(card) -> String:
	if card == null:
		return ""
	var d: Dictionary = card.data
	var text := ""
	if Loc.lang() == "es":
		text = CardText.spanish(str(d.get("name", "")))
	if text == "":
		text = str(d.get("desc", d.get("text", "")))
	text = text.replace("\r", " ").replace("\n", " ").strip_edges()
	if text == "":
		return ""
	# Whole sentences while they fit: a leading condition ("Activate only as Chain Link 4 or higher.")
	# is followed by what the card does.
	var out := ""
	var from := 0
	while from < text.length():
		var at := text.find(". ", from)
		var piece := text.substr(from) if at < 0 else text.substr(from, at + 1 - from)
		if out != "" and out.length() + piece.length() + 1 > 125:
			break
		out = piece if out == "" else out + " " + piece.strip_edges()
		if at < 0:
			break
		from = at + 2
	if out.length() > 150:
		out = out.substr(0, 147).rstrip(" ,;:") + "..."
	return out
