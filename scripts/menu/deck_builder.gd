class_name DeckBuilder
extends Control
## Build your own deck from the cards you own. Click a card on the left to add it, on the right to remove it.

signal closed

var _grid: GridContainer
var _deck_list: VBoxContainer
var _count: Label
var _detail_tex: TextureRect
var _detail_name: Label
var _detail_text: Label
var _filter := "all"
var _search := ""
var _filter_btns := {}
var _use_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.025, 0.05, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 44)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	m.add_child(root)
	# Header
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	root.add_child(head)
	head.add_child(UITheme.label("DECK BUILDER", 54, Color.WHITE, UITheme.title_font()))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_count = UITheme.label("", 22, UITheme.TEXT_DIM, UITheme.semi_font())
	head.add_child(_count)
	_use_btn = Button.new()
	_use_btn.add_theme_font_size_override("font_size", 22)
	_use_btn.pressed.connect(func():
		if Collection.deck_ok():
			Router.duel_config["player_deck"] = "custom"
			Router.toast("You'll duel with %s" % Collection.deck_name)
		_refresh_count())
	head.add_child(_use_btn)
	var done := Button.new()
	done.text = "  Done  "
	done.add_theme_font_size_override("font_size", 22)
	done.pressed.connect(_close)
	head.add_child(done)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	# Card detail
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(330, 0)
	left.add_theme_constant_override("separation", 10)
	body.add_child(left)
	_detail_tex = TextureRect.new()
	_detail_tex.custom_minimum_size = Vector2(330, 482)
	_detail_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_tex.texture = Cards.get_back()
	left.add_child(_detail_tex)
	_detail_name = UITheme.label("Hover a card", 26, Color.WHITE, UITheme.title_font())
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_detail_name)
	var dscroll := ScrollContainer.new()
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(dscroll)
	_detail_text = UITheme.label("Click a card in your collection to add it to the deck. Click a card in the deck to take it out.", 17, UITheme.TEXT_DIM)
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_text.custom_minimum_size = Vector2(320, 0)
	dscroll.add_child(_detail_text)
	# Collection
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 10)
	body.add_child(mid)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	mid.add_child(bar)
	bar.add_child(UITheme.label("COLLECTION", 18, UITheme.ACCENT, UITheme.semi_font()))
	for f in [["all", "All"], ["monster", "Monsters"], ["spell", "Spells"], ["trap", "Traps"], ["extra", "Extra Deck"]]:
		var b := Button.new()
		b.text = f[1]
		b.toggle_mode = true
		b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		var key: String = f[0]
		b.pressed.connect(func():
			_filter = key
			_rebuild_grid())
		bar.add_child(b)
		_filter_btns[key] = b
	var search := LineEdit.new()
	search.placeholder_text = "Search by name"
	search.custom_minimum_size = Vector2(240, 0)
	search.text_changed.connect(func(t):
		_search = t.to_lower()
		_rebuild_grid())
	bar.add_child(search)
	var gscroll := ScrollContainer.new()
	gscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(gscroll)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	gscroll.add_child(_grid)
	# Deck
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(400, 0)
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	right.add_child(UITheme.label("YOUR DECK", 18, UITheme.ACCENT, UITheme.semi_font()))
	var rs := ScrollContainer.new()
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	_deck_list = VBoxContainer.new()
	_deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_list.add_theme_constant_override("separation", 4)
	rs.add_child(_deck_list)
	_rebuild_grid()
	_rebuild_deck()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _sorted(ids: Array) -> Array:
	var out := ids.duplicate()
	out.sort_custom(func(a, b):
		var da := CardData.get_card(a)
		var db := CardData.get_card(b)
		var ka := 0 if da["kind"] == "monster" else (1 if da["kind"] == "spell" else 2)
		var kb := 0 if db["kind"] == "monster" else (1 if db["kind"] == "spell" else 2)
		if ka != kb:
			return ka < kb
		if int(da.get("atk", 0)) != int(db.get("atk", 0)):
			return int(da.get("atk", 0)) > int(db.get("atk", 0))
		return str(da.get("name", "")) < str(db.get("name", "")))
	return out


func _rebuild_grid() -> void:
	for k in _filter_btns:
		(_filter_btns[k] as Button).set_pressed_no_signal(k == _filter)
	for c in _grid.get_children():
		c.queue_free()
	for id in _sorted(Collection.owned.keys()):
		var d := CardData.get_card(id)
		var is_extra: bool = str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]
		if _filter == "extra" and not is_extra:
			continue
		if _filter in ["monster", "spell", "trap"] and (d["kind"] != _filter or is_extra):
			continue
		if _search != "" and not str(d.get("name", "")).to_lower().contains(_search):
			continue
		_grid.add_child(_tile(id))


func _tile(id: int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(124, 181)
	var tr := TextureRect.new()
	tr.texture = Cards.get_face(id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	holder.add_child(tr)
	var badge := Label.new()
	badge.add_theme_font_override("font", UITheme.semi_font())
	badge.add_theme_font_size_override("font_size", 16)
	var sb := UITheme.panel_box(Color(0, 0, 0, 0.82), 9, Color(1, 1, 1, 0.25))
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	badge.add_theme_stylebox_override("normal", sb)
	badge.position = Vector2(4, 4)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(badge)
	var refresh := func():
		var used := Collection.in_deck(id)
		badge.text = "%d / %d" % [used, mini(3, Collection.count(id))]
		tr.modulate = Color.WHITE if Collection.can_add(id) else Color(0.5, 0.5, 0.56)
	refresh.call()
	tr.mouse_entered.connect(func(): _show(id))
	tr.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if Collection.can_add(id):
				Collection.add(id)
				Sfx.play("card", -4.0)
				refresh.call()
				_rebuild_deck()
			else:
				Sfx.play("click", -6.0))
	holder.set_meta("refresh", refresh)
	return holder


func _rebuild_deck() -> void:
	for c in _deck_list.get_children():
		c.queue_free()
	for section in [["MAIN DECK", Collection.main], ["EXTRA DECK", Collection.extra]]:
		var ids: Array = section[1]
		_deck_list.add_child(UITheme.label("%s  ·  %d" % [section[0], ids.size()], 16, UITheme.TEXT_DIM, UITheme.semi_font()))
		var seen := {}
		for id in _sorted(ids):
			if seen.has(id):
				continue
			seen[id] = true
			var d := CardData.get_card(id)
			var b := Button.new()
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size = Vector2(0, 36)
			b.add_theme_font_size_override("font_size", 17)
			var stat := ("  %d" % int(d.get("atk", 0))) if d["kind"] == "monster" else ("  " + str(d["kind"]).capitalize())
			b.text = "%d×  %s%s" % [ids.count(id), d.get("name", "?"), stat]
			b.clip_text = true
			b.mouse_entered.connect(func(): _show(id))
			b.pressed.connect(func():
				Collection.remove(id)
				Sfx.play("card", -6.0, 0.8)
				_rebuild_deck()
				for t in _grid.get_children():
					if t.has_meta("refresh"):
						(t.get_meta("refresh") as Callable).call())
			_deck_list.add_child(b)
	_refresh_count()


func _refresh_count() -> void:
	var n := Collection.main.size()
	var ok := Collection.deck_ok()
	_count.text = "Main %d  (needs %d to %d)     Extra %d / %d     DP %d" % [n, Collection.MAIN_MIN, Collection.MAIN_MAX, Collection.extra.size(), Collection.EXTRA_MAX, Collection.dp]
	_count.add_theme_color_override("font_color", UITheme.TEXT_DIM if ok else UITheme.DANGER)
	var using: bool = Router.duel_config.get("player_deck", "") == "custom"
	_use_btn.text = "  ✓ Using this deck  " if using and ok else "  Duel with this deck  "
	_use_btn.disabled = not ok


func _show(id: int) -> void:
	var d := CardData.get_card(id)
	_detail_tex.texture = Cards.get_face(id)
	_detail_name.text = str(d.get("name", ""))
	var lines := []
	if d["kind"] == "monster":
		lines.append("Level %d  ·  %s  ·  %s" % [int(d.get("level", 0)), d.get("attribute", ""), d.get("race", "")])
		lines.append("ATK %d   DEF %d" % [int(d.get("atk", 0)), int(d.get("def", 0))])
		var note := str(CardEffects.of(str(d.get("name", ""))).get("note", ""))
		if note != "":
			lines.append("IN THIS GAME: " + note)
	lines.append(str(d.get("desc", d.get("text", ""))))
	lines.append("You own %d." % Collection.count(id))
	_detail_text.text = "\n\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if not Collection.deck_ok() and Router.duel_config.get("player_deck", "") == "custom":
		Router.duel_config["player_deck"] = "echo"
		Router.toast("Your deck needs %d to %d cards, so the Echo Deck is back in use" % [Collection.MAIN_MIN, Collection.MAIN_MAX])
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
