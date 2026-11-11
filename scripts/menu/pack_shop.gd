class_name PackShop
extends Control
## Buy booster packs with Duel Points and watch them open.

signal closed

var _dp: Label
var _row: HBoxContainer
var _reveal: HBoxContainer
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.025, 0.05, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	c.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 30)
	v.add_child(head)
	head.add_child(UITheme.label("BOOSTER PACKS", 54, Color.WHITE, UITheme.title_font()))
	_dp = UITheme.label("", 30, Color("ffd23a"), UITheme.title_font())
	_dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_dp)
	_hint = UITheme.label("%d cards per pack. Win duels to earn Duel Points." % Collection.PACK_SIZE, 20, UITheme.TEXT_DIM)
	v.add_child(_hint)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 22)
	v.add_child(_row)
	for pack in Collection.PACKS:
		_row.add_child(_pack_card(pack))
	_reveal = HBoxContainer.new()
	_reveal.add_theme_constant_override("separation", 16)
	_reveal.custom_minimum_size = Vector2(0, 300)
	_reveal.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_reveal)
	var done := Button.new()
	done.text = "Leave the counter"
	done.add_theme_font_size_override("font_size", 24)
	done.pressed.connect(_close)
	v.add_child(done)
	_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _pack_card(pack: Dictionary) -> Control:
	var col: Color = pack["color"]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(300, 250)
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(col.darkened(0.75), 0.95), 22, Color(col, 0.8)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(UITheme.label(str(pack["key"]).to_upper(), 16, col.lightened(0.4), UITheme.semi_font()))
	var n := UITheme.label(str(pack["name"]), 32, Color.WHITE, UITheme.title_font())
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(n)
	var pool: Array = Collection.pool(str(pack["key"]))
	var have := 0
	for id in pool:
		if Collection.count(id) > 0:
			have += 1
	var info := UITheme.label("%s\nYou have %d of %d cards." % [pack["blurb"], have, pool.size()], 17, UITheme.TEXT_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.set_meta("pack", pack["key"])
	v.add_child(info)
	var b := Button.new()
	b.text = "Open  ·  %d DP" % Collection.PACK_PRICE
	b.add_theme_font_size_override("font_size", 24)
	b.set_meta("buy", true)
	b.disabled = pool.is_empty()
	if pool.is_empty():
		b.text = "Needs the card database"
	b.pressed.connect(func(): _open(pack))
	v.add_child(b)
	return p


func _refresh() -> void:
	_dp.text = "%d DP" % Collection.dp
	for p in _row.get_children():
		for b in p.get_child(0).get_children():
			if b is Button and b.has_meta("buy") and not b.text.begins_with("Needs"):
				b.disabled = Collection.dp < Collection.PACK_PRICE
			elif b is Label and b.has_meta("pack"):
				var pool: Array = Collection.pool(str(b.get_meta("pack")))
				var have := 0
				for id in pool:
					if Collection.count(id) > 0:
						have += 1
				b.text = b.text.get_slice("\n", 0) + "\nYou have %d of %d cards." % [have, pool.size()]


func _open(pack: Dictionary) -> void:
	var before := Collection.owned.duplicate()
	var pulls := Collection.open_pack(str(pack["key"]))
	if pulls.is_empty():
		Router.toast("Not enough Duel Points")
		return
	_refresh()
	for c in _reveal.get_children():
		c.queue_free()
	Sfx.play("special", -2.0)
	for i in pulls.size():
		var id: int = pulls[i]
		var holder := VBoxContainer.new()
		holder.add_theme_constant_override("separation", 6)
		var tr := TextureRect.new()
		tr.texture = Cards.get_back()
		tr.custom_minimum_size = Vector2(186, 271)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.pivot_offset = Vector2(93, 135)
		holder.add_child(tr)
		var is_new: bool = int(before.get(id, 0)) == 0
		var tag := UITheme.label("NEW!" if is_new else "", 18, Color("ffd23a"), UITheme.title_font())
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.modulate.a = 0.0
		holder.add_child(tag)
		_reveal.add_child(holder)
		before[id] = 1
		var tw := create_tween()
		tw.tween_interval(0.25 + i * 0.28)
		tw.tween_property(tr, "scale:x", 0.0, 0.12)
		tw.tween_callback(func():
			tr.texture = Cards.get_face(id)
			Sfx.play("card", -3.0, 1.0 + i * 0.06))
		tw.tween_property(tr, "scale:x", 1.0, 0.14)
		tw.tween_property(tag, "modulate:a", 1.0, 0.15)
	var names := []
	for id in pulls:
		names.append(str(CardData.get_card(id).get("name", "?")))
	_hint.text = "You pulled: " + ", ".join(names)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
