class_name DeckBuilder
extends Control
## Build your own decks from the cards you own. Five saved recipes, a Side Deck for matches,
## search and filters, and an optional Forbidden/Limited list. Click a card on the left to add
## it, on the right to take it out; right-click a card in the deck to move it to or from the Side Deck.

signal closed

var picked := false      # "Duel with this deck" was pressed in here

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
var _attr := ""
var _level := 0          # 0 all, 1 = 1 to 4, 2 = 5 to 6, 3 = 7 and up
var _sort := 0           # 0 type, 1 ATK, 2 level, 3 name
var _to_side := false
var _slot_btns: Array = []
var _name_edit: LineEdit
var _warn: Label


func _panel(pad := 16) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.054, 0.0996, 0.285, 0.82), 18, Color(UITheme.ACCENT, 0.22))
	sb.set_content_margin_all(pad)
	pc.add_theme_stylebox_override("panel", sb)
	return pc


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(MenuBackdrop.new())
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 40)
	m.add_theme_constant_override("margin_top", 26)
	m.add_theme_constant_override("margin_bottom", 30)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	m.add_child(root)
	# ---- top bar: back, title, the five saved decks, the name, and the two big buttons
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := Button.new()
	back.text = "◀  Back"
	back.add_theme_font_size_override("font_size", 18)
	back.custom_minimum_size = Vector2(104, 44)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	head.add_child(back)
	head.add_child(UITheme.label("DECK BUILDER", 44, Color.WHITE, UITheme.title_font()))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(18, 0)
	head.add_child(gap)
	for i in Collection.SLOTS:
		var sb := Button.new()
		sb.toggle_mode = true
		sb.custom_minimum_size = Vector2(50, 44)
		sb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sb.text = str(i + 1)
		sb.tooltip_text = "Switch to this saved deck"
		for st in ["pressed", "hover_pressed"]:
			sb.add_theme_stylebox_override(st, UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT, 10))
		sb.add_theme_color_override("font_pressed_color", Color(0.02, 0.05, 0.08))
		sb.add_theme_color_override("font_hover_pressed_color", Color(0.02, 0.05, 0.08))
		sb.pressed.connect(func():
			Collection.load_slot(i)
			Sfx.play("card", -4.0)
			_refresh_all())
		head.add_child(sb)
		_slot_btns.append(sb)
	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(260, 44)
	_name_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_edit.max_length = 22
	_name_edit.placeholder_text = "Deck name"
	_name_edit.text_changed.connect(func(t):
		Collection.deck_name = t.strip_edges() if t.strip_edges() != "" else "My Deck"
		Collection.save())
	head.add_child(_name_edit)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_use_btn = Button.new()
	_use_btn.add_theme_font_size_override("font_size", 20)
	_use_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_use_btn.pressed.connect(func():
		if Collection.deck_ok():
			picked = true
			Collection.use_deck("custom")
			Router.toast(Loc.t("You'll duel with %s") % Collection.deck_name)
		_refresh_count())
	head.add_child(_use_btn)
	var done := Button.new()
	done.text = "  Done  "
	done.add_theme_font_size_override("font_size", 20)
	done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	done.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.9), UITheme.ACCENT))
	done.add_theme_color_override("font_color", Color(0.02, 0.05, 0.08))
	done.pressed.connect(_close)
	head.add_child(done)
	_warn = UITheme.label("", 16, UITheme.DANGER)
	_warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warn.visible = false
	root.add_child(_warn)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	# ---- left: the card you are pointing at
	var lp := _panel(14)
	lp.custom_minimum_size = Vector2(330, 0)
	body.add_child(lp)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	lp.add_child(left)
	_detail_tex = TextureRect.new()
	_detail_tex.custom_minimum_size = Vector2(300, 438)
	_detail_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_tex.texture = Cards.get_back()
	left.add_child(_detail_tex)
	_detail_name = UITheme.label("Point at a card", 24, Color.WHITE, UITheme.title_font())
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_detail_name)
	var dscroll := ScrollContainer.new()
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(dscroll)
	_detail_text = UITheme.label("Click a card in your collection to add it. Click a card in your deck to take it out. Right-click a deck card to move it to the Side Deck.", 16, UITheme.TEXT_DIM)
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_text.custom_minimum_size = Vector2(290, 0)
	dscroll.add_child(_detail_text)
	# ---- middle: your deck, as cards
	var dp := _panel(16)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dp.size_flags_stretch_ratio = 1.0
	body.add_child(dp)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	dp.add_child(mid)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 14)
	mid.add_child(dh)
	dh.add_child(UITheme.label("YOUR DECK", 18, UITheme.ACCENT, UITheme.semi_font()))
	_count = UITheme.label("", 18, UITheme.TEXT, UITheme.semi_font())
	dh.add_child(_count)
	var dsp := Control.new()
	dsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dh.add_child(dsp)
	var starter := OptionButton.new()
	starter.custom_minimum_size = Vector2(210, 38)
	starter.add_theme_font_size_override("font_size", 16)
	starter.add_item("Fill from a starter...")
	var keys := []
	for k in CardData.DECKS.keys() + CardData.NAMED_DECKS.keys():
		if CardData.has_deck(k):
			keys.append(k)
			starter.add_item(CardData.deck_name(k))
	starter.item_selected.connect(func(i):
		if i <= 0:
			return
		var missing := Collection.load_recipe(str(keys[i - 1]))
		Router.toast(Loc.t("Recipe loaded. %d cards skipped because you do not own them yet.") % missing if missing > 0 else "Recipe loaded")
		starter.select(0)
		_refresh_all())
	dh.add_child(starter)
	var clear := Button.new()
	clear.text = "Empty deck"
	clear.add_theme_font_size_override("font_size", 16)
	clear.pressed.connect(func():
		Collection.main.clear()
		Collection.extra.clear()
		Collection.side.clear()
		Collection.save()
		_refresh_all())
	dh.add_child(clear)
	# What the deck is made of, as one bar.
	_mix = Control.new()
	_mix.custom_minimum_size = Vector2(0, 30)
	_mix.draw.connect(_draw_mix)
	mid.add_child(_mix)
	var rs := ScrollContainer.new()
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(rs)
	_deck_list = VBoxContainer.new()
	_deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_list.add_theme_constant_override("separation", 6)
	rs.add_child(_deck_list)
	# ---- right: everything you own
	var cp := _panel(16)
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cp.size_flags_stretch_ratio = 1.0
	body.add_child(cp)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	cp.add_child(col)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	col.add_child(bar)
	bar.add_child(UITheme.label("COLLECTION", 18, UITheme.ACCENT, UITheme.semi_font()))
	var bsp := Control.new()
	bsp.custom_minimum_size = Vector2(6, 0)
	bar.add_child(bsp)
	for f in [["all", "All"], ["monster", "Monsters"], ["spell", "Spells"], ["trap", "Traps"], ["extra", "Extra"]]:
		var b := Button.new()
		b.text = f[1]
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 16)
		var on := UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT, 10)
		on.content_margin_left = 12
		on.content_margin_right = 12
		var off := UITheme.button_box(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.14), 10)
		off.content_margin_left = 12
		off.content_margin_right = 12
		b.add_theme_stylebox_override("normal", off)
		for st in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, on)
		b.add_theme_color_override("font_pressed_color", Color(0.02, 0.05, 0.08))
		b.add_theme_color_override("font_hover_pressed_color", Color(0.02, 0.05, 0.08))
		var key: String = f[0]
		b.pressed.connect(func():
			_filter = key
			_rebuild_grid())
		bar.add_child(b)
		_filter_btns[key] = b
	var bar2 := HBoxContainer.new()
	bar2.add_theme_constant_override("separation", 6)
	col.add_child(bar2)
	var search := LineEdit.new()
	search.placeholder_text = "Search name or card text"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", 16)
	search.text_changed.connect(func(t):
		_search = t.to_lower()
		_rebuild_grid())
	bar2.add_child(search)
	var attr := OptionButton.new()
	attr.add_theme_font_size_override("font_size", 16)
	attr.fit_to_longest_item = false
	attr.custom_minimum_size = Vector2(150, 0)
	attr.add_item("Any Attribute")
	for a in ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND", "DIVINE"]:
		attr.add_item(a)
	attr.item_selected.connect(func(i):
		_attr = "" if i == 0 else ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND", "DIVINE"][i - 1]
		_rebuild_grid())
	bar2.add_child(attr)
	var lv := OptionButton.new()
	lv.add_theme_font_size_override("font_size", 16)
	lv.fit_to_longest_item = false
	lv.custom_minimum_size = Vector2(140, 0)
	for t in ["Any Level", "Level 1 to 4", "Level 5 and 6", "Level 7 and up"]:
		lv.add_item(t)
	lv.item_selected.connect(func(i):
		_level = i
		_rebuild_grid())
	bar2.add_child(lv)
	var so := OptionButton.new()
	so.add_theme_font_size_override("font_size", 16)
	so.fit_to_longest_item = false
	so.custom_minimum_size = Vector2(130, 0)
	for t in ["Sort: type", "Sort: ATK", "Sort: Level", "Sort: name"]:
		so.add_item(t)
	so.item_selected.connect(func(i):
		_sort = i
		_rebuild_grid())
	bar2.add_child(so)
	var gscroll := ScrollContainer.new()
	gscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(gscroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	gscroll.add_child(_grid)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 18)
	col.add_child(foot)
	_owned_l = UITheme.label("", 15, UITheme.TEXT_DIM)
	foot.add_child(_owned_l)
	var fsp := Control.new()
	fsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(fsp)
	var side_t := CheckButton.new()
	side_t.text = "Add to Side Deck"
	side_t.add_theme_font_size_override("font_size", 15)
	side_t.tooltip_text = "The Side Deck holds up to 15 cards you can swap in between the duels of a best-of-3 Match."
	for cn in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		side_t.add_theme_color_override(cn, UITheme.TEXT)
	side_t.toggled.connect(func(on):
		_to_side = on
		_rebuild_grid())
	foot.add_child(side_t)
	var ban := CheckButton.new()
	ban.text = "Forbidden/Limited list"
	ban.add_theme_font_size_override("font_size", 15)
	ban.tooltip_text = "Optional. Forbidden cards cannot be used, Limited cards 1 copy, Semi-Limited 2. Applies to the decks you build."
	ban.button_pressed = Collection.banlist
	for cn in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		ban.add_theme_color_override(cn, UITheme.TEXT)
	ban.toggled.connect(func(on):
		Collection.banlist = on
		Collection.save()
		_refresh_all())
	foot.add_child(ban)
	_refresh_all()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


var _mix: Control
var _owned_l: Label
var _last_added := -1


## One bar for the whole Main Deck: monsters, Spells and Traps by share, with their counts.
func _draw_mix() -> void:
	var w := _mix.size.x
	var n := [0, 0, 0]
	for id in Collection.main:
		var k := str(CardData.get_card(id).get("kind", "monster"))
		n[0 if k == "monster" else (1 if k == "spell" else 2)] += 1
	var total: int = n[0] + n[1] + n[2]
	var cols := [Color("d9903a"), Color("2bb59a"), Color("c8457f")]
	var names := ["Monsters", "Spells", "Traps"]
	var font := UITheme.semi_font()
	_mix.draw_style_box(UITheme.panel_box(Color(1, 1, 1, 0.05), 8, Color(1, 1, 1, 0.08)), Rect2(0, 0, w, 10))
	var x := 0.0
	for i in 3:
		if total > 0 and n[i] > 0:
			var seg: float = w * float(n[i]) / float(total)
			_mix.draw_style_box(UITheme.panel_box(cols[i], 5, cols[i]), Rect2(x + 1, 0, maxf(2.0, seg - 2.0), 10))
			x += seg
		_mix.draw_string(font, Vector2(i * 150.0, 27), "%s %d" % [Loc.t(names[i]), n[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cols[i].lightened(0.25))


func _refresh_all() -> void:
	for i in _slot_btns.size():
		(_slot_btns[i] as Button).set_pressed_no_signal(i == Collection.slot)
		(_slot_btns[i] as Button).tooltip_text = str((Collection.slots[i] as Dictionary).get("name", "")) if i < Collection.slots.size() else ""
	if _name_edit.text != Collection.deck_name and not _name_edit.has_focus():
		_name_edit.text = Collection.deck_name
	_rebuild_grid()
	_rebuild_deck()


func _sorted(ids: Array) -> Array:
	var out := ids.duplicate()
	out.sort_custom(func(a, b):
		var da := CardData.get_card(a)
		var db := CardData.get_card(b)
		if _sort == 3:
			return str(da.get("name", "")) < str(db.get("name", ""))
		if _sort == 2 and int(da.get("level", 0)) != int(db.get("level", 0)):
			return int(da.get("level", 0)) > int(db.get("level", 0))
		if _sort == 1 and int(da.get("atk", 0)) != int(db.get("atk", 0)):
			return int(da.get("atk", 0)) > int(db.get("atk", 0))
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
	var shown := 0
	for id in _sorted(Collection.owned.keys()):
		var d := CardData.get_card(id)
		var is_extra: bool = str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]
		if _filter == "extra" and not is_extra:
			continue
		if _filter in ["monster", "spell", "trap"] and (d["kind"] != _filter or is_extra):
			continue
		if _search != "" and not str(d.get("name", "")).to_lower().contains(_search) and not str(d.get("desc", d.get("text", ""))).to_lower().contains(_search):
			continue
		if _attr != "" and str(d.get("attribute", "")) != _attr:
			continue
		if _level > 0:
			var l := int(d.get("level", 0))
			if d["kind"] != "monster" or (_level == 1 and l > 4) or (_level == 2 and (l < 5 or l > 6)) or (_level == 3 and l < 7):
				continue
		_grid.add_child(_tile(id))
		shown += 1
	if _owned_l:
		_owned_l.text = Loc.t("%d of %d cards shown") % [shown, Collection.owned.size()]


func _tile(id: int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(112, 163)
	holder.pivot_offset = Vector2(56, 81)
	var tr := TextureRect.new()
	tr.texture = Cards.get_face(id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	holder.add_child(tr)
	Foil.apply(tr, CardData.rarity(id))
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
		var lim := Collection.limit(id)
		badge.text = "%d / %d" % [used, mini(mini(3, lim), Collection.count(id))]
		if lim < 3:
			badge.text += ["   FORBIDDEN", "   LIMITED", "   SEMI"][lim]
		tr.modulate = Color.WHITE if Collection.can_add(id, _to_side) else Color(0.5, 0.5, 0.56)
	refresh.call()
	tr.mouse_entered.connect(func():
		_show(id)
		holder.z_index = 2
		holder.create_tween().tween_property(holder, "scale", Vector2(1.07, 1.07), 0.08))
	tr.mouse_exited.connect(func():
		holder.z_index = 0
		holder.create_tween().tween_property(holder, "scale", Vector2.ONE, 0.1))
	tr.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if Collection.can_add(id, _to_side):
				if _to_side:
					Collection.add_side(id)
				else:
					Collection.add(id)
				Sfx.play("card", -4.0)
				refresh.call()
				_last_added = id
				_rebuild_deck()
			else:
				Sfx.play("click", -6.0))
	holder.set_meta("refresh", refresh)
	return holder


func _rebuild_deck() -> void:
	for c in _deck_list.get_children():
		c.queue_free()
	var popped := false
	for section in [["MAIN DECK", Collection.main, Collection.MAIN_MAX, 10], ["EXTRA DECK", Collection.extra, Collection.EXTRA_MAX, 10], ["SIDE DECK", Collection.side, Collection.SIDE_MAX, 10]]:
		var ids: Array = section[1]
		var is_side: bool = section[0] == "SIDE DECK"
		var is_main: bool = section[0] == "MAIN DECK"
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		_deck_list.add_child(head)
		head.add_child(UITheme.label(Loc.t(section[0]), 15, UITheme.GOLD if is_side else UITheme.TEXT_DIM, UITheme.semi_font()))
		var short: bool = is_main and (ids.size() < Collection.MAIN_MIN or ids.size() > Collection.MAIN_MAX)
		var ct := "%d" % ids.size() + ((Loc.t("  (needs %d to %d)") % [Collection.MAIN_MIN, Collection.MAIN_MAX]) if is_main else " / %d" % int(section[2]))
		head.add_child(UITheme.label(ct, 15, UITheme.DANGER if short else Color.WHITE, UITheme.semi_font()))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 5)
		flow.add_theme_constant_override("v_separation", 5)
		_deck_list.add_child(flow)
		if ids.is_empty():
			var tip := UITheme.label({"MAIN DECK": "Empty. Click cards in your collection to add them here.",
				"EXTRA DECK": "Fusion, Synchro and Xyz monsters you add go here.",
				"SIDE DECK": "Optional. Right-click a deck card to move it here."}[section[0]], 14, UITheme.TEXT_DIM)
			tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tip.custom_minimum_size = Vector2(520, 0)
			_deck_list.add_child(tip)
		for id in _sorted(ids):
			var card := TextureRect.new()
			card.texture = Cards.get_face(id)
			card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			card.stretch_mode = TextureRect.STRETCH_SCALE
			card.custom_minimum_size = Vector2(62, 90)
			card.pivot_offset = Vector2(31, 45)
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			flow.add_child(card)
			# The card you just added pops, so your eye lands on it.
			if id == _last_added and not popped:
				popped = true
				card.scale = Vector2(1.35, 1.35)
				card.modulate = Color(1.6, 1.6, 1.6)
				var tw := card.create_tween().set_parallel()
				tw.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(card, "modulate", Color.WHITE, 0.3)
			card.mouse_entered.connect(func():
				_show(id)
				card.z_index = 2
				card.create_tween().tween_property(card, "scale", Vector2(1.12, 1.12), 0.08))
			card.mouse_exited.connect(func():
				card.z_index = 0
				card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.1))
			card.gui_input.connect(func(e):
				if not (e is InputEventMouseButton and e.pressed):
					return
				if e.button_index == MOUSE_BUTTON_RIGHT:
					if is_side:
						Collection.side.erase(id)
						if Collection.can_add(id):
							Collection.add(id)
						else:
							Collection.side.append(id)
					elif Collection.side.size() < Collection.SIDE_MAX and Collection.main.has(id):
						Collection.main.erase(id)
						Collection.side.append(id)
					Collection.save()
					Sfx.play("card", -6.0, 1.2)
					_last_added = -1
					_refresh_all()
				elif e.button_index == MOUSE_BUTTON_LEFT:
					if is_side:
						Collection.remove_side(id)
					else:
						Collection.remove(id)
					Sfx.play("card", -6.0, 0.8)
					_last_added = -1
					_rebuild_deck()
					for t in _grid.get_children():
						if t.has_meta("refresh"):
							(t.get_meta("refresh") as Callable).call())
	_last_added = -1
	_mix.queue_redraw()
	_refresh_count()


func _refresh_count() -> void:
	var n := Collection.main.size()
	var ok := Collection.deck_ok()
	_count.text = Loc.t("%d cards") % n
	var bad := Collection.illegal()
	_warn.visible = not bad.is_empty()
	if not bad.is_empty():
		var parts := []
		for x in bad:
			parts.append("%s (%d, max %d)" % [x[0], x[1], x[2]])
		_warn.text = Loc.t("Not allowed by the Forbidden/Limited list: ") + ", ".join(parts)
	_count.add_theme_color_override("font_color", Color.WHITE if ok else UITheme.DANGER)
	var using: bool = Collection.active == "custom"
	_use_btn.text = "  ✓ Using this deck  " if using and ok else "  Duel with this deck  "
	_use_btn.disabled = not ok


func _show(id: int) -> void:
	var d := CardData.get_card(id)
	_detail_tex.texture = Cards.get_face(id)
	Foil.apply(_detail_tex, CardData.rarity(id))
	_detail_name.text = str(d.get("name", ""))
	var lines := []
	if d["kind"] == "monster":
		lines.append(Loc.t("Level %d  ·  %s  ·  %s") % [int(d.get("level", 0)), d.get("attribute", ""), d.get("race", "")])
		lines.append(Loc.t("ATK %d   DEF %d") % [int(d.get("atk", 0)), int(d.get("def", 0))])
		var note := str(CardEffects.of(str(d.get("name", ""))).get("note", ""))
		if note != "":
			lines.append(Loc.t("IN THIS GAME: ") + note)
	lines.append(str(d.get("desc", d.get("text", ""))))
	lines.append(Loc.t("You own %d.") % Collection.count(id) + "   " + Loc.t(Foil.NAMES[CardData.rarity(id)]))
	if Collection.banlist and Collection.limit(id) < 3:
		lines.append(Loc.t(["Forbidden: cannot be used.", "Limited: 1 copy per deck.", "Semi-Limited: 2 copies per deck."][Collection.limit(id)]))
	_detail_text.text = "\n\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	Collection._apply_active()
	if not Collection.deck_ok() and Collection.active == "custom":
		Router.toast(Loc.t("Your deck needs %d to %d cards, so the Echo Deck is back in use") % [Collection.MAIN_MIN, Collection.MAIN_MAX])
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
