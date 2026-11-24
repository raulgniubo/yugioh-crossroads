class_name CardWhere
extends Control
## "Where to find it" (0.55.3): one card, and every place in the worlds you can get it, laid out
## world by world. Each world shows the packs its card shop sells with this card in them, the
## ready-made decks there that include it, and the duelists there who play it (and when they are
## around). Packs every shop sells sit together at the top. It only tells you where to go: buying
## still means walking into that shop.

signal closed

var _id := 0
var _closing := false
var _listing := false
var _panel: PanelContainer


func _init(card_id: int) -> void:
	_id = card_id


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 150
	theme = UITheme.build()
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.03, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_close())
	add_child(dim)
	var pl := CardFinder.places(_id)
	var d := CardData.get_card(_id)
	var owned := int(Collection.owned.get(_id, 0)) > 0
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 120
	_panel.offset_right = -120
	_panel.offset_top = 60
	_panel.offset_bottom = -60
	var box := UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.98), 22, Color(UITheme.ACCENT, 0.55))
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 24
	box.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	_panel.add_child(row)
	# ---- left: the card itself
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size = Vector2(250, 0)
	row.add_child(left)
	var face := TextureRect.new()
	face.texture = Cards.get_face(_id, true)
	face.custom_minimum_size = Vector2(250, 364)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if owned:
		Foil.apply(face, CardData.rarity(_id))
	else:
		face.material = AlbumSlot.gray_material()
	left.add_child(face)
	var nm := UITheme.label(str(d.get("name", "")), 26, Color.WHITE, UITheme.title_font())
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(nm)
	var have := UITheme.label(Loc.t("You own %d copies") % int(Collection.owned.get(_id, 0)) if owned else Loc.t("You don't have it yet."), 17,
			UITheme.GOLD if owned else Color(1.0, 0.55, 0.55), UITheme.semi_font())
	have.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(have)
	var sm := UITheme.label(CardFinder.summary(_id), 16, UITheme.TEXT_DIM, UITheme.semi_font())
	sm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(sm)
	var lsp := Control.new()
	lsp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(lsp)
	var note := UITheme.label(Loc.t("To buy, walk into that world's card shop."), 15, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(note)
	var close := Button.new()
	close.text = "  %s  " % Loc.t("Close")
	close.add_theme_font_size_override("font_size", 22)
	close.custom_minimum_size = Vector2(0, 54)
	close.pressed.connect(_close)
	left.add_child(close)
	close.grab_focus.call_deferred()
	# ---- right: the places, world by world
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(UITheme.label(Loc.t("WHERE TO FIND IT"), 40, Color.WHITE, UITheme.title_font()))
	var sub := UITheme.label(Loc.t("Every place in the worlds where you can get this card."), 18, UITheme.TEXT_DIM)
	right.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 8)
	pad.add_theme_constant_override("margin_right", 14)
	sc.add_child(pad)
	pad.add_child(list)
	var k := 0
	if not (pl["everywhere"] as Array).is_empty():
		list.add_child(_section(Loc.t("Every card shop"), Loc.t("Sold in the card shop of every world"), UITheme.ACCENT, pl["everywhere"], [], [], k))
		k += 1
	for w in pl["worlds"]:
		list.add_child(_section(str(w["name"]), str(w["shop"]), w["color"], w["packs"], w["decks"], w["people"], k))
		k += 1
	if k == 0:
		var none := UITheme.label(Loc.t("Not sold in any shop: it comes from the story or from duels."), 22, UITheme.TEXT)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(none)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	_panel.pivot_offset = get_viewport_rect().size / 2.0 - Vector2(120, 60)
	_panel.scale = Vector2(0.97, 0.97)
	create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("whoosh", -12.0, 1.3)
	if OS.has_environment("WHERE_LIST"):	# dev: click the first pack or deck in the window
		get_tree().create_timer(0.8).timeout.connect(func():
			for n in find_children("*", "VBoxContainer", true, false):
				if (n as Control).mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND:
					var ev := InputEventMouseButton.new()
					ev.pressed = true
					ev.button_index = MOUSE_BUTTON_LEFT
					(n as Control).gui_input.emit(ev)
					break)
	if OS.has_environment("WHERE_SCROLL"):	# dev: check the bottom of a long list
		get_tree().create_timer(0.6).timeout.connect(func(): sc.scroll_vertical = int(OS.get_environment("WHERE_SCROLL")))


## One world: its name in its color, then a row each for packs, decks and duelists.
func _section(title: String, shop: String, col: Color, packs: Array, decks: Array, people: Array, k: int) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.darkened(0.6), 0.22)
	sb.set_corner_radius_all(16)
	sb.border_color = Color(col, 0.55)
	sb.border_width_left = 5
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 20
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 16
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)
	var t := UITheme.label(title.to_upper(), 30, col.lightened(0.35), UITheme.title_font())
	head.add_child(t)
	var shop_l := UITheme.label(shop, 17, UITheme.TEXT_DIM, UITheme.semi_font())
	shop_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(shop_l)
	# Packs and decks side by side when they fit on one line, stacked otherwise.
	var one_line := not packs.is_empty() and not decks.is_empty() and packs.size() + decks.size() <= 6
	var goods: Array[Control] = []
	if not packs.is_empty():
		goods.append(_row(Loc.t("PACKS"), col, packs.map(func(p): return _pack_item(p)), not one_line))
	if not decks.is_empty():
		goods.append(_row(Loc.t("READY-MADE DECKS"), col, decks.map(func(e): return _deck_item(e)), not one_line))
	if one_line:
		var side := HBoxContainer.new()
		side.add_theme_constant_override("separation", 34)
		v.add_child(side)
		for g in goods:
			side.add_child(g)
	else:
		for g in goods:
			v.add_child(g)
	if not people.is_empty():
		v.add_child(_row(Loc.t("DUELISTS WHO PLAY IT"), col, people.map(func(r): return _person_item(r))))
	pc.modulate.a = 0.0
	pc.create_tween().tween_property(pc, "modulate:a", 1.0, 0.22).set_delay(0.06 + 0.05 * k)
	return pc


func _row(caption: String, col: Color, items: Array, wrap := true) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UITheme.label(caption, 14, col.lightened(0.5), UITheme.semi_font()))
	var flow: Container = HFlowContainer.new() if wrap else HBoxContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("separation", 14)
	flow.add_theme_constant_override("v_separation", 12)
	v.add_child(flow)
	for it in items:
		flow.add_child(it)
	return v


## A pack: the little foil wrapper, its name and its price.
func _pack_item(p: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size = Vector2(150, 0)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(150, 190)
	v.add_child(holder)
	_clickable(v, holder, "pack", p)
	var wrap := PackWrapper.new().setup(p)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Drawn at its shelf size, then scaled down, so the name on it fits like it does in the shop.
	wrap.custom_minimum_size = Vector2(230, 353)
	wrap.size = Vector2(230, 353)
	wrap.scale = Vector2(0.52, 0.52)
	wrap.position = Vector2(15, 4)
	holder.add_child(wrap)
	var n := UITheme.label(Collection.pack_title(p), 15, Color.WHITE, UITheme.semi_font())
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.custom_minimum_size = Vector2(150, 46)
	n.max_lines_visible = 2
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(n)
	var pr := UITheme.label(Loc.t("%d DP") % Collection.pack_price(p), 14, UITheme.GOLD, UITheme.semi_font())
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pr)
	return v


## Click a pack or deck to see every card in it (the same window the shops open).
func _clickable(v: Control, holder: Control, kind: String, info: Dictionary) -> void:
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	v.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	v.tooltip_text = Loc.t("See every card in it")
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.pivot_offset = Vector2(75, 95)
	v.mouse_entered.connect(func(): v.create_tween().tween_property(v, "scale", Vector2(1.05, 1.05), 0.1))
	v.mouse_exited.connect(func(): v.create_tween().tween_property(v, "scale", Vector2.ONE, 0.1))
	v.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not _listing:
			_listing = true
			Sfx.play("click")
			var lv := CardListView.new(kind, info)
			add_child(lv)
			await lv.closed
			_listing = false)


## A ready-made deck: its box and its name.
func _deck_item(e: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size = Vector2(150, 0)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(150, 190)
	v.add_child(holder)
	_clickable(v, holder, "deck", e)
	var b := DeckBox.new().setup(e)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.size = Vector2(206, 290)	# drawn at its shop size, then scaled down so its lettering stays inside
	b.scale = Vector2(0.6, 0.6)
	b.position = Vector2(13, 10)
	b.owned = Collection.owns_deck(str(e["key"]))
	holder.add_child(b)
	var n := UITheme.label(Loc.t(str(e["name"])), 15, Color.WHITE, UITheme.semi_font())
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.custom_minimum_size = Vector2(150, 46)
	n.max_lines_visible = 2
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(n)
	var pr := UITheme.label(Loc.t("%d DP") % int(e.get("price", 0)), 14, UITheme.GOLD, UITheme.semi_font())
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pr)
	return v


## A duelist: a badge with their initial in their color, their name, where they stand and when.
func _person_item(r: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.07, 0.7)
	sb.set_corner_radius_all(30)
	sb.border_color = Color(r["color"], 0.6)
	sb.set_border_width_all(1)
	sb.content_margin_left = 8
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pc.add_child(h)
	var badge := _Badge.new()
	badge.col = r["color"]
	badge.letter = str(r["name"]).left(1).to_upper()
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(UITheme.label(Loc.t(str(r["name"])), 18, Color.WHITE, UITheme.semi_font()))
	var bits: Array = []
	if str(r["place"]) != "":
		bits.append(Loc.t(str(r["place"])))
	else:
		bits.append(Loc.t("out in the streets"))
	var wt := CardFinder.when_text(r["hours"])
	if wt != "":
		bits.append(wt)
	v.add_child(UITheme.label("  ·  ".join(bits), 14, UITheme.TEXT_DIM))
	return pc


class _Badge extends Control:
	var col := Color.WHITE
	var letter := "?"

	func _init() -> void:
		custom_minimum_size = Vector2(44, 44)

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 21.0, col.darkened(0.45))
		draw_arc(c, 21.0, 0, TAU, 40, col.lightened(0.2), 2.0, true)
		var f := UITheme.title_font()
		var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		draw_string(f, Vector2(c.x - ts.x / 2.0, c.y + 9), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)


func _close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if _listing:
		return
	# (It sits above the album, which reads keys and pads in _input too: the window takes them first.)
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_close()
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
