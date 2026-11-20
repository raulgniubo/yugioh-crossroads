class_name PackSummary
extends Control
## After opening 5 or 10 packs at once: everything you pulled on one screen, the best cards
## first, new ones marked, doubles counted ("x3"). It scrolls when there is more than fits.

signal closed

var _pulls: Array = []
var _before := {}
var _color := Color("7cc4ff")
var _title := ""
var _closing := false


func _init(pulls: Array, owned_before: Dictionary, color: Color, title: String) -> void:
	_pulls = pulls
	_before = owned_before
	_color = color
	_title = title


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	theme = UITheme.build()
	var bg := ColorRect.new()
	bg.color = Color(0.008, 0.012, 0.03, 0.99)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 90)
	m.add_theme_constant_override("margin_top", 40)
	m.add_theme_constant_override("margin_bottom", 34)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	# What came out, counted once each.
	var count := {}
	var order: Array = []
	for id in _pulls:
		if not count.has(id):
			order.append(id)
		count[id] = int(count.get(id, 0)) + 1
	var fresh := 0
	for id in order:
		if int(_before.get(id, 0)) == 0:
			fresh += 1
	order.sort_custom(func(a, b):
		var ra := CardData.rarity(a)
		var rb := CardData.rarity(b)
		if ra != rb:
			return ra > rb
		var na := int(_before.get(a, 0)) == 0
		var nb := int(_before.get(b, 0)) == 0
		if na != nb:
			return na
		return a < b)
	var t := UITheme.label(Loc.t("ALL YOUR PULLS"), 44, Color.WHITE, UITheme.title_font())
	v.add_child(t)
	var packs := int(ceil(_pulls.size() / float(Collection.PACK_SIZE)))
	var sub := UITheme.label(Loc.t("%s  ·  %d packs, %d cards, %d new to your collection.") % [_title, packs, _pulls.size(), fresh], 22, _color.lightened(0.45), UITheme.semi_font())
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	sc.add_child(grid)
	for k in order.size():
		grid.add_child(_tile(order[k], int(count[order[k]]), k))
	var btn := Button.new()
	btn.text = "  %s  " % Loc.t("Continue")
	btn.add_theme_font_size_override("font_size", 26)
	btn.custom_minimum_size = Vector2(280, 62)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_close)
	v.add_child(btn)
	btn.grab_focus.call_deferred()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	Sfx.play("sparkle", -4.0)


func _tile(id: int, n: int, k: int) -> Control:
	var r := CardData.rarity(id)
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 2)
	var tr := TextureRect.new()
	tr.texture = Cards.get_thumb(id)
	tr.custom_minimum_size = Vector2(118, 172)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.tooltip_text = str(CardData.get_card(id).get("name", ""))
	holder.add_child(tr)
	Foil.apply(tr, r)
	var is_new := int(_before.get(id, 0)) == 0
	var line := Loc.t(Foil.NAMES[r]) if r > 0 else ""
	if n > 1:
		line = (line + "  x%d" % n).strip_edges()
	var tag := UITheme.label(line, 14, Foil.COLORS[r], UITheme.semi_font())
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.custom_minimum_size = Vector2(118, 0)
	tag.clip_text = true
	holder.add_child(tag)
	var nl := UITheme.label(Loc.t("NEW!") if is_new else "", 14, Color("ffd23a"), UITheme.semi_font())
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.custom_minimum_size = Vector2(118, 0)
	holder.add_child(nl)
	holder.modulate.a = 0.0
	holder.create_tween().tween_property(holder, "modulate:a", 1.0, 0.15).set_delay(mini(k, 40) * 0.015)
	return holder


func _close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
