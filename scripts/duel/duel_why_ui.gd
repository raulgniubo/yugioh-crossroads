class_name DuelWhyUI
extends Control
## The duel's "why" on screen (DuelWhy works it out):
##   - a reason card at the top when something expected does not happen ("NO DAMAGE: One Day of
##     Peace is in force"), with the picture of the card behind it;
##   - by each player's Life Points, a small chip for everything still in force for them (what,
##     until when, from which card); point at a chip for the card's whole text.

const KIND_COLORS := {"no_dmg": Color("5fd0ff"), "no_bdmg": Color("5fd0ff"), "no_attack": Color("ffb35a"),
	"no_kill": Color("7be08a"), "no_special": Color("c79bff")}

var plates: Array = [null, null]       # the two DuelistPanels (to sit next to)
var _rows: Array = [null, null]        # the chip row of each player
var _known := {}                       # chips already shown open once (key: player + text + card)
var _cards: Array = []                 # reason cards on screen (newest last)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30


# ------------------------------------------------------------------ the reason card

## A reason, shown for a few seconds: big `title`, the sentence, the card's picture.
func show_why(p: int, title: String, text: String, id: int) -> void:
	var col: Color = Color("5fd0ff") if title.contains(Loc.t("DAMAGE")) else Color("ffb35a")
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.95), 18, Color(col, 0.55))
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.content_margin_left = 16
	sb.content_margin_right = 24
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(h)
	if id > 0:
		var art := TextureRect.new()
		art.texture = Cards.get_thumb(id)
		art.custom_minimum_size = Vector2(66, 96)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(UiPictures.rounded(art, 8))
	else:
		var ic := _Icon.new()
		ic.kind = "no_dmg" if title.contains(Loc.t("DAMAGE")) else "no_attack"
		ic.col = col
		ic.custom_minimum_size = Vector2(54, 64)
		h.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	if id > 0:
		var ic2 := _Icon.new()
		ic2.kind = "no_dmg" if title.contains(Loc.t("DAMAGE")) else "no_attack"
		ic2.col = col
		ic2.custom_minimum_size = Vector2(26, 30)
		top.add_child(ic2)
	var tl := UITheme.label(title, 30, col, UITheme.title_font())
	top.add_child(tl)
	var body := UITheme.label(text, 21, UITheme.TEXT, UITheme.semi_font())
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(520, 0)
	v.add_child(body)
	add_child(pc)
	pc.reset_size()
	# (stacked under each other when two come at once; the oldest leaves first)
	_cards = _cards.filter(func(c): return is_instance_valid(c))
	var vs := get_viewport_rect().size
	var y := vs.y * 0.27
	for c in _cards:
		y = maxf(y, (c as Control).position.y + (c as Control).size.y + 12.0)
	_cards.append(pc)
	pc.position = Vector2((vs.x - pc.size.x) / 2.0, y - 18.0)
	pc.modulate.a = 0.0
	pc.pivot_offset = pc.size / 2.0
	pc.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(pc, "modulate:a", 1.0, 0.18)
	tw.tween_property(pc, "position:y", y, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(pc, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(Settings.t(3.4))
	tw.tween_property(pc, "modulate:a", 0.0, 0.35)
	tw.tween_callback(pc.queue_free)


# ------------------------------------------------------------------ chips by the Life Points

## What is in force for player `p` now (DuelWhy.statuses): one chip each.
func set_status(p: int, list: Array) -> void:
	if _rows[p] != null and is_instance_valid(_rows[p]):
		var old: Control = _rows[p]
		var tw := create_tween()
		tw.tween_property(old, "modulate:a", 0.0, 0.18)
		tw.tween_callback(old.queue_free)
	_rows[p] = null
	if list.is_empty():
		return
	# (0.72.1: a row of small chips, card and sign only, so they don't cover Lumen; a new one opens
	# for a few seconds to say what it is, and any of them opens while the pointer is on it)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_BEGIN if p == 0 else BoxContainer.ALIGNMENT_END
	for s in list:
		box.add_child(_chip(s, p))
	add_child(box)
	_rows[p] = box
	box.reset_size()
	_place(p)
	box.modulate.a = 0.0
	create_tween().tween_property(box, "modulate:a", 1.0, 0.25)


func _process(_d: float) -> void:
	for p in 2:
		if _rows[p] != null and is_instance_valid(_rows[p]):
			_place(p)


## Next to the plate: yours above it (bottom left), theirs under it (top right).
func _place(p: int) -> void:
	var box: Control = _rows[p]
	var plate: Control = plates[p]
	if plate == null or not is_instance_valid(plate):
		return
	var r := plate.get_global_rect()
	box.reset_size()
	if p == 0:
		box.position = Vector2(r.position.x + 196.0, r.position.y - box.size.y - 10.0)
	else:
		box.position = Vector2(r.end.x - box.size.x - 24.0, r.end.y + 10.0)


func _chip(s: Dictionary, p: int) -> Control:
	var kind := str(s["kind"])
	var col: Color = KIND_COLORS.get(kind, UITheme.GOLD)
	if s.get("partial", false):
		col = col.lerp(Color(0.7, 0.75, 0.85), 0.45)
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.9), 14, Color(col, 0.6))
	sb.border_width_left = 3
	sb.content_margin_left = 6
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if p == 0 else Control.SIZE_SHRINK_END
	var d := CardData.get_card(int(s["id"]))
	var en := str(CardData.EXT.get(int(s["id"]), {}).get("desc", "")) if CardData.EXT.has(int(s["id"])) else ""
	if en == "":
		en = str(d.get("text", d.get("desc", "")))
	pc.tooltip_text = "%s\n\n%s\n%s" % [str(s["text"]), str(s["name"]), CardText.shown(str(s["name"]), en)]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(h)
	var art := TextureRect.new()
	art.texture = Cards.get_thumb(int(s["id"]))
	art.custom_minimum_size = Vector2(28, 40)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(UiPictures.rounded(art, 5))
	var ic := _Icon.new()
	ic.kind = kind
	ic.col = col
	ic.custom_minimum_size = Vector2(18, 22)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UITheme.label(str(s["short"]), 19, col.lightened(0.25), UITheme.semi_font()))
	var when := UITheme.label("%s · %s" % [str(s["when"]), str(s["name"])], 14, UITheme.TEXT_DIM, UITheme.semi_font())
	when.clip_text = true
	when.custom_minimum_size = Vector2(minf(300.0, 8.0 * (str(s["when"]).length() + str(s["name"]).length())), 0)
	v.add_child(when)
	# closed: only the card and the sign; open while pointed at, and for a moment when it is new
	var key := "%d|%s|%s" % [p, str(s["short"]), str(s["id"])]
	v.visible = false
	pc.mouse_entered.connect(func(): v.visible = true)
	pc.mouse_exited.connect(func(): v.visible = false)
	if not _known.has(key):
		_known[key] = true
		v.visible = true
		get_tree().create_timer(4.0).timeout.connect(func():
			if is_instance_valid(v) and is_instance_valid(pc) and not pc.get_global_rect().has_point(pc.get_global_mouse_position()):
				v.visible = false)
	return pc


## The little picture of a kind: a shield (no damage), a raised hand (no attacks), a shield with a
## heart line (safe in battle), a crossed circle (no Special Summons).
class _Icon:
	extends Control
	var kind := "no_dmg"
	var col := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		match kind:
			"no_attack":
				# an octagon, like a stop sign, with a bar
				var pts := PackedVector2Array()
				var c := Vector2(w, h) / 2.0
				var r := minf(w, h) * 0.48
				for i in 8:
					var a := TAU * (i + 0.5) / 8.0
					pts.append(c + Vector2(cos(a), sin(a)) * r)
				draw_colored_polygon(pts, Color(col, 0.9))
				draw_rect(Rect2(c.x - r * 0.55, c.y - r * 0.14, r * 1.1, r * 0.28), Color(0.03, 0.05, 0.11))
			"no_special":
				var c2 := Vector2(w, h) / 2.0
				var r2 := minf(w, h) * 0.42
				draw_arc(c2, r2, 0, TAU, 28, col, maxf(2.0, r2 * 0.25), true)
				draw_line(c2 + Vector2(-r2, r2) * 0.7, c2 + Vector2(r2, -r2) * 0.7, col, maxf(2.0, r2 * 0.25), true)
			_:
				# a shield
				var s := PackedVector2Array([Vector2(w * 0.5, 0), Vector2(w, h * 0.16), Vector2(w * 0.94, h * 0.55),
					Vector2(w * 0.5, h), Vector2(w * 0.06, h * 0.55), Vector2(0, h * 0.16)])
				draw_colored_polygon(s, Color(col, 0.9))
				var inner := PackedVector2Array()
				for q in s:
					inner.append(Vector2(w, h) / 2.0 + (q - Vector2(w, h) / 2.0) * 0.55)
				draw_colored_polygon(inner, Color(0.03, 0.05, 0.11, 0.85) if kind != "no_kill" else Color(1, 1, 1, 0.85))
