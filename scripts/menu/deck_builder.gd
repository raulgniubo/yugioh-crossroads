class_name DeckBuilder
extends Control
## Build your own decks from the cards you own: as many decks as you like, a Side Deck for
## matches, search and filters, and an optional Forbidden/Limited list. Tap a card to select it
## (its buttons sit under the big picture), double-click for one quick copy in or out, or drag
## cards between the collection and the deck. Nothing moves on a plain tap. Undo takes steps back.

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
var _race := ""           # monster Type filter ("" = any)
var _addable := false     # only cards that can still go into this deck
var _undo: Array = []     # earlier states of the deck, newest last
var _undo_btn: Button
var _ask_row: HBoxContainer
var _ask_l: Label
var _ask_yes: Button
var _ask_do: Callable
var _read_l: Label
var _pin := {}            # the card you tapped: {"id", "from"} with from = col | main | extra | side
var _act_box: VBoxContainer
var _mark: Panel
var _slot_pick: OptionButton
var _name_edit: LineEdit
var _warn: Label


func _panel(pad := 16) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.82), 18, Color(UITheme.ACCENT, 0.22))
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
	# Which of your decks is on the table.
	_slot_pick = OptionButton.new()
	_slot_pick.custom_minimum_size = Vector2(230, 44)
	_slot_pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slot_pick.clip_text = true
	_slot_pick.fit_to_longest_item = false
	_slot_pick.tooltip_text = Loc.t("Switch to another of your decks")
	_slot_pick.add_theme_font_size_override("font_size", 18)
	_slot_pick.item_selected.connect(func(i: int):
		_undo.clear()
		Collection.load_slot(i)
		Sfx.play("card", -4.0)
		_refresh_all())
	head.add_child(_slot_pick)
	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(260, 44)
	_name_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_edit.max_length = 22
	_name_edit.placeholder_text = "Deck name"
	_name_edit.text_changed.connect(func(t):
		Collection.deck_name = t.strip_edges() if t.strip_edges() != "" else "My Deck"
		Collection.save())
	head.add_child(_name_edit)
	var hand := Button.new()
	hand.text = "Test hand"
	hand.tooltip_text = Loc.t("Deals five cards from this deck so you can see how it opens.")
	hand.add_theme_font_size_override("font_size", 18)
	hand.custom_minimum_size = Vector2(0, 44)
	hand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hand.pressed.connect(_test_hand)
	head.add_child(hand)
	_undo_btn = Button.new()
	_undo_btn.text = "Undo"
	_undo_btn.tooltip_text = Loc.t("Takes back your last change (Ctrl+Z).")
	_undo_btn.add_theme_font_size_override("font_size", 18)
	_undo_btn.custom_minimum_size = Vector2(0, 44)
	_undo_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_undo_btn.disabled = true
	_undo_btn.pressed.connect(_undo_last)
	head.add_child(_undo_btn)
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
	# What you can do with the card you tapped.
	_act_box = VBoxContainer.new()
	_act_box.add_theme_constant_override("separation", 6)
	left.add_child(_act_box)
	var dscroll := ScrollContainer.new()
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(dscroll)
	_detail_text = UITheme.label("Tap a card to select it: its buttons show up here. Double-click adds or removes one copy. You can also drag a card from your collection onto your deck, and drag a deck card back to take it out.", 16, UITheme.TEXT_DIM)
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
		var key := str(keys[i - 1])
		starter.select(0)
		var fill := func():
			_snap()
			var missing := Collection.load_recipe(key)
			Router.toast(Loc.t("Recipe loaded. %d cards skipped because you do not own them yet.") % missing if missing > 0 else "Recipe loaded")
			_refresh_all()
		if Collection.main.is_empty() and Collection.extra.is_empty() and Collection.side.is_empty():
			fill.call()
		else:
			_ask(Loc.t("Replace the %d cards in this deck with the %s list?") % [Collection.main.size() + Collection.extra.size() + Collection.side.size(), CardData.deck_name(key)], Loc.t("Replace"), fill))
	dh.add_child(starter)
	var clear := Button.new()
	clear.text = "Empty deck"
	clear.add_theme_font_size_override("font_size", 16)
	clear.pressed.connect(func():
		if Collection.main.is_empty() and Collection.extra.is_empty() and Collection.side.is_empty():
			return
		_ask(Loc.t("Take all %d cards out of this deck?") % (Collection.main.size() + Collection.extra.size() + Collection.side.size()), Loc.t("Empty it"), func():
			_snap()
			Collection.main.clear()
			Collection.extra.clear()
			Collection.side.clear()
			Collection.save()
			_refresh_all()))
	dh.add_child(clear)
	# "Are you sure?" for the two buttons that change the whole deck at once.
	_ask_row = HBoxContainer.new()
	_ask_row.add_theme_constant_override("separation", 10)
	_ask_row.visible = false
	mid.add_child(_ask_row)
	_ask_l = UITheme.label("", 17, UITheme.GOLD, UITheme.semi_font())
	_ask_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ask_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ask_row.add_child(_ask_l)
	_ask_yes = Button.new()
	_ask_yes.add_theme_font_size_override("font_size", 17)
	_ask_yes.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.DANGER, 0.25), UITheme.DANGER, 10))
	_ask_yes.pressed.connect(func():
		_ask_row.visible = false
		if _ask_do.is_valid():
			_ask_do.call())
	_ask_row.add_child(_ask_yes)
	var ask_no := Button.new()
	ask_no.text = "Cancel"
	ask_no.add_theme_font_size_override("font_size", 17)
	ask_no.pressed.connect(func(): _ask_row.visible = false)
	_ask_row.add_child(ask_no)
	# What the deck is made of, as one bar.
	_mix = Control.new()
	_mix.custom_minimum_size = Vector2(0, 30)
	_mix.draw.connect(_draw_mix)
	mid.add_child(_mix)
	# How heavy the monsters are: the ones you can just play, and the ones that cost tributes.
	_read_l = UITheme.label("", 14, UITheme.TEXT_DIM, UITheme.semi_font())
	mid.add_child(_read_l)
	var rs := ScrollContainer.new()
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(rs)
	_deck_list = VBoxContainer.new()
	_deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_list.add_theme_constant_override("separation", 6)
	rs.add_child(_deck_list)
	for z in [dp, mid, rs, _deck_list, _mix]:
		_drop_zone(z, "main")
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
	# How much you own, and how much of it the filters are letting through.
	_owned_l = UITheme.label("", 16, UITheme.TEXT, UITheme.semi_font())
	col.add_child(_owned_l)
	var bar2 := HBoxContainer.new()
	bar2.add_theme_constant_override("separation", 6)
	col.add_child(bar2)
	var search := LineEdit.new()
	search.placeholder_text = "Search name or card text"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size = Vector2(190, 0)
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", 16)
	search.text_changed.connect(func(t):
		_search = t.to_lower()
		_rebuild_grid())
	bar2.add_child(search)
	var attr := OptionButton.new()
	attr.add_theme_font_size_override("font_size", 16)
	attr.fit_to_longest_item = false
	attr.custom_minimum_size = Vector2(118, 0)
	attr.add_item("Attribute")
	for a in ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND", "DIVINE"]:
		attr.add_item(a)
	attr.item_selected.connect(func(i):
		_attr = "" if i == 0 else ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND", "DIVINE"][i - 1]
		_rebuild_grid())
	bar2.add_child(attr)
	var races := {}
	for k in Collection.owned:
		var cd := CardData.get_card(int(k))
		if str(cd.get("kind", "")) == "monster" and str(cd.get("race", "")) != "":
			races[str(cd["race"])] = true
	var race_names: Array = races.keys()
	race_names.sort()
	var rc := OptionButton.new()
	rc.add_theme_font_size_override("font_size", 16)
	rc.fit_to_longest_item = false
	rc.custom_minimum_size = Vector2(100, 0)
	rc.add_item("Type")
	for r in race_names:
		rc.add_item(str(r))
	rc.item_selected.connect(func(i):
		_race = "" if i == 0 else str(race_names[i - 1])
		_rebuild_grid())
	bar2.add_child(rc)
	var lv := OptionButton.new()
	lv.add_theme_font_size_override("font_size", 16)
	lv.fit_to_longest_item = false
	lv.custom_minimum_size = Vector2(100, 0)
	for t in ["Level", "Level 1 to 4", "Level 5 and 6", "Level 7 and up"]:
		lv.add_item(t)
	lv.item_selected.connect(func(i):
		_level = i
		_rebuild_grid())
	bar2.add_child(lv)
	var so := OptionButton.new()
	so.add_theme_font_size_override("font_size", 16)
	so.fit_to_longest_item = false
	so.custom_minimum_size = Vector2(118, 0)
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
	for z in [cp, col, gscroll, _grid]:
		_drop_zone(z, "col")
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	col.add_child(foot)
	var can_t := CheckButton.new()
	can_t.text = "Only what I can add"
	can_t.add_theme_font_size_override("font_size", 15)
	can_t.tooltip_text = "Hides the cards whose every copy is already in this deck."
	for cn in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		can_t.add_theme_color_override(cn, UITheme.TEXT)
	can_t.toggled.connect(func(on):
		_addable = on
		_rebuild_grid())
	foot.add_child(can_t)
	var fsp := Control.new()
	fsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(fsp)
	var side_t := CheckButton.new()
	side_t.text = "Double-click: Side Deck"
	side_t.add_theme_font_size_override("font_size", 15)
	side_t.tooltip_text = "On: a double-click on a collection card adds it to the Side Deck instead of the Main Deck. The Side Deck holds up to 15 cards you can swap in between the duels of a best-of-3 Match."
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
	_slot_pick.clear()
	for i in Collection.slots.size():
		_slot_pick.add_item(Collection.deck_name if i == Collection.slot else str((Collection.slots[i] as Dictionary).get("name", "Deck %d" % (i + 1))))
	_slot_pick.select(Collection.slot)
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
		if _race != "" and (d["kind"] != "monster" or str(d.get("race", "")) != _race):
			continue
		if _addable and not Collection.can_add(id, _to_side):
			continue
		if _level > 0:
			var l := int(d.get("level", 0))
			if d["kind"] != "monster" or (_level == 1 and l > 4) or (_level == 2 and (l < 5 or l > 6)) or (_level == 3 and l < 7):
				continue
		_grid.add_child(_tile(id))
		shown += 1
	if _owned_l:
		var copies := 0
		for k in Collection.owned:
			copies += int(Collection.owned[k])
		var total: int = Collection.owned.size()
		_owned_l.text = Loc.t("You own %d different cards  ·  %d copies in total") % [total, copies] + "  ·  " + (Loc.t("showing all of them") if shown == total else Loc.t("showing %d of %d") % [shown, total])
		_owned_l.add_theme_color_override("font_color", UITheme.TEXT if shown == total else UITheme.GOLD)


func _tile(id: int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(112, 163)
	holder.pivot_offset = Vector2(56, 81)
	var tr := TextureRect.new()
	tr.texture = Cards.get_face(id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	badge.add_theme_stylebox_override("normal", sb)
	badge.position = Vector2(4, 4)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(badge)
	# How many are in the deck on the table, on its own strip, so the corner only says what you own.
	var strip := Label.new()
	strip.add_theme_font_override("font", UITheme.semi_font())
	strip.add_theme_font_size_override("font_size", 13)
	strip.add_theme_color_override("font_color", Color(0.03, 0.05, 0.1))
	var ssb := UITheme.panel_box(Color(UITheme.GOLD, 0.95), 7, UITheme.GOLD)
	ssb.content_margin_left = 5
	ssb.content_margin_right = 5
	ssb.content_margin_top = 1
	ssb.content_margin_bottom = 1
	strip.add_theme_stylebox_override("normal", ssb)
	strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_left = 4
	strip.offset_right = -4
	strip.offset_top = -30
	strip.offset_bottom = -6
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(strip)
	var refresh := func():
		var used := Collection.in_deck(id)
		var lim := Collection.limit(id)
		var can_use: int = mini(mini(3, lim), Collection.count(id))
		badge.text = "x%d" % Collection.count(id)
		if lim < 3:
			badge.text += ["   FORBIDDEN", "   LIMITED", "   SEMI"][lim]
		strip.visible = used > 0
		strip.text = Loc.t("All in this deck") if used >= can_use else Loc.t("In this deck: %d") % used
		tr.modulate = Color.WHITE if Collection.can_add(id, _to_side) else Color(0.5, 0.5, 0.56)
	refresh.call()
	tr.mouse_entered.connect(func():
		_show(id)
		holder.z_index = 2
		holder.create_tween().tween_property(holder, "scale", Vector2(1.07, 1.07), 0.08))
	tr.mouse_exited.connect(func():
		holder.z_index = 0
		holder.create_tween().tween_property(holder, "scale", Vector2.ONE, 0.1)
		_show_pin())
	tr.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if e.double_click:
				# The fast way: one more copy into the deck.
				_quick_add(id)
			else:
				_select(id, "col", holder))
	tr.set_drag_forwarding(func(_at): return _drag_from(id, "col", tr),
		func(_at, data): return _can_drop("col", data),
		func(_at, data): _drop("col", data))
	if _pin.get("from", "") == "col" and int(_pin.get("id", -1)) == id:
		_place_mark(holder)
	holder.set_meta("refresh", refresh)
	holder.set_meta("id", id)
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
		var part: String = "side" if is_side else ("main" if is_main else "extra")
		var zone: String = "side" if is_side else "main"
		flow.custom_minimum_size = Vector2(0, 90 if is_side or is_main else 0)
		_drop_zone(flow, zone)
		_drop_zone(head, zone)
		var marked := false
		if ids.is_empty():
			var tip := UITheme.label({"MAIN DECK": "Empty. Drag cards here from your collection, or tap one and press Add to deck.",
				"EXTRA DECK": "Fusion, Synchro and Xyz monsters you add go here.",
				"SIDE DECK": "Optional. Drag cards here, or tap a deck card and press Move to Side Deck."}[section[0]], 14, UITheme.TEXT_DIM)
			tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tip.custom_minimum_size = Vector2(520, 0)
			_deck_list.add_child(tip)
		for id in _sorted(ids):
			var card := TextureRect.new()
			card.texture = Cards.get_face(id)
			card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card.custom_minimum_size = Vector2(62, 90)
			card.pivot_offset = Vector2(31, 45)
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			card.set_meta("id", id)
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
				card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.1)
				_show_pin())
			card.gui_input.connect(func(e):
				if not (e is InputEventMouseButton and e.pressed):
					return
				# No hidden clicks: a card only moves when you drag it or press its button.
				if e.button_index == MOUSE_BUTTON_LEFT:
					if e.double_click:
						# The fast way: one copy out.
						_take_out(id, part)
					else:
						_select(id, part, card))
			card.set_drag_forwarding(func(_at): return _drag_from(id, part, card),
				func(_at, data): return _can_drop(zone, data),
				func(_at, data): _drop(zone, data))
			if not marked and _pin.get("from", "") == part and int(_pin.get("id", -1)) == id:
				marked = true
				_place_mark(card)
	_last_added = -1
	_mix.queue_redraw()
	_refresh_count()
	_refresh_actions()


# ------------------------------------------------------------------ picking, buttons, dragging

## Tap a card: it becomes the one the big picture and its buttons are about.
func _select(id: int, from: String, on: Control) -> void:
	_pin = {"id": id, "from": from}
	_show(id)
	_place_mark(on)
	_refresh_actions()
	Sfx.play("click", -8.0)


func _show_pin() -> void:
	if not _pin.is_empty():
		_show(int(_pin["id"]))


func _place_mark(on: Control) -> void:
	if _mark != null and is_instance_valid(_mark):
		_mark.queue_free()
	_mark = Panel.new()
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mark.offset_left = -3
	_mark.offset_top = -3
	_mark.offset_right = 3
	_mark.offset_bottom = 3
	var sb := UITheme.panel_box(Color(UITheme.GOLD, 0.0), 6, UITheme.GOLD)
	sb.set_border_width_all(3)
	_mark.add_theme_stylebox_override("panel", sb)
	on.add_child(_mark)


## After any change to the deck: the deck redraws, the collection tiles recount.
func _changed(added := -1) -> void:
	_last_added = added
	_rebuild_deck()
	for t in _grid.get_children():
		if t.has_meta("refresh"):
			(t.get_meta("refresh") as Callable).call()


func _quick_add(id: int, to_side := _to_side) -> void:
	if not Collection.can_add(id, to_side):
		Sfx.play("click", -6.0)
		return
	_snap()
	if to_side:
		Collection.add_side(id)
	else:
		Collection.add(id)
	Sfx.play("card", -4.0)
	_changed(id)


func _take_out(id: int, part: String) -> void:
	_snap()
	if part == "side":
		Collection.remove_side(id)
	else:
		Collection.remove(id)
	Sfx.play("card", -6.0, 0.8)
	_changed()


func _to_side_deck(id: int) -> void:
	if Collection.side.size() >= Collection.SIDE_MAX or not Collection.main.has(id):
		Sfx.play("click", -6.0)
		return
	_snap()
	Collection.main.erase(id)
	Collection.side.append(id)
	Collection.save()
	Sfx.play("card", -6.0, 1.2)
	if _pin.get("from", "") == "main" and int(_pin.get("id", -1)) == id and not Collection.main.has(id):
		_pin["from"] = "side"
	_changed()


func _to_main_deck(id: int) -> void:
	if not Collection.side.has(id):
		return
	_snap()
	Collection.side.erase(id)
	if Collection.can_add(id):
		Collection.add(id)
	else:
		Collection.side.append(id)
		Sfx.play("click", -6.0)
	Collection.save()
	Sfx.play("card", -6.0, 1.2)
	if _pin.get("from", "") == "side" and int(_pin.get("id", -1)) == id and not Collection.side.has(id):
		_pin["from"] = "extra" if Collection.extra.has(id) else "main"
	_changed(id)


func _act_btn(text: String, on: bool, do: Callable, primary := false) -> void:
	var b := Button.new()
	b.text = text
	b.disabled = not on
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 19)
	if primary:
		b.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.22), UITheme.GOLD, 12))
		b.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 12))
		b.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 12))
	b.pressed.connect(do)
	_act_box.add_child(b)


# ------------------------------------------------------------------ undo, are-you-sure, test hand

func _snap() -> void:
	_undo.append([Collection.main.duplicate(), Collection.extra.duplicate(), Collection.side.duplicate()])
	if _undo.size() > 60:
		_undo.pop_front()
	if _undo_btn:
		_undo_btn.disabled = false


func _undo_last() -> void:
	if _undo.is_empty():
		return
	var st: Array = _undo.pop_back()
	Collection.main = st[0]
	Collection.extra = st[1]
	Collection.side = st[2]
	Collection.save()
	Sfx.play("card", -6.0, 0.9)
	_changed()


func _ask(text: String, yes: String, do: Callable) -> void:
	_ask_l.text = text
	_ask_yes.text = "  %s  " % yes
	_ask_do = do
	_ask_row.visible = true
	_ask_yes.grab_focus.call_deferred()


var _hand_box: Control


## Five cards off the top of a shuffled copy of the deck, and one more whenever you ask.
func _test_hand() -> void:
	if _hand_box != null and is_instance_valid(_hand_box):
		_hand_box.queue_free()
	if Collection.main.size() < 5:
		Router.toast(Loc.t("Put at least 5 cards in the Main Deck first"))
		return
	var pile: Array = Collection.main.duplicate()
	pile.shuffle()
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.05, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.z_index = 30
	add_child(shade)
	_hand_box = shade
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.045, 0.07, 0.14, 0.98), 18, Color(UITheme.GOLD, 0.6)))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	shade.add_child(panel)
	var pad := MarginContainer.new()
	for sd in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + sd, 22)
	panel.add_child(pad)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pad.add_child(v)
	v.add_child(UITheme.label("TEST HAND", 30, Color.WHITE, UITheme.title_font()))
	var note := UITheme.label("", 17, UITheme.TEXT_DIM)
	v.add_child(note)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	row.custom_minimum_size = Vector2(5 * 160.0 + 40.0, 222)
	v.add_child(row)
	var drawn := [0]
	var deal := func(n: int):
		for k in n:
			if pile.is_empty():
				break
			var id: int = pile.pop_back()
			drawn[0] += 1
			var c := TextureRect.new()
			c.texture = Cards.get_face(id)
			c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			c.custom_minimum_size = Vector2(152, 222)
			c.tooltip_text = str(CardData.get_card(id).get("name", ""))
			c.modulate.a = 0.0
			row.add_child(c)
			var tw := c.create_tween()
			tw.tween_interval(0.07 * k)
			tw.tween_property(c, "modulate:a", 1.0, 0.15)
		Sfx.play("card", -5.0)
		note.text = Loc.t("%d cards drawn, %d left in the deck.") % [drawn[0], pile.size()]
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(btns)
	for spec in [["Draw one more", 0], ["New hand", 1], ["Close", 2]]:
		var b := Button.new()
		b.text = "  %s  " % Loc.t(str(spec[0]))
		b.custom_minimum_size = Vector2(0, 48)
		b.add_theme_font_size_override("font_size", 19)
		var what: int = spec[1]
		b.pressed.connect(func():
			if what == 0:
				deal.call(1)
			elif what == 1:
				_test_hand()
			else:
				shade.queue_free())
		btns.add_child(b)
	deal.call(5)


## The buttons under the big picture, for the card you tapped.
func _refresh_actions() -> void:
	if _act_box == null:
		return
	for c in _act_box.get_children():
		_act_box.remove_child(c)
		c.queue_free()
	if _pin.is_empty():
		return
	var id := int(_pin["id"])
	var from := str(_pin["from"])
	# A card that has left the part of the deck it was tapped in goes back to being a collection card.
	if (from == "main" and not Collection.main.has(id)) or (from == "extra" and not Collection.extra.has(id)) or (from == "side" and not Collection.side.has(id)):
		from = "col"
		_pin["from"] = "col"
	var in_main: int = Collection.main.count(id) + Collection.extra.count(id)
	var in_side: int = Collection.side.count(id)
	var info := UITheme.label(Loc.t("In this deck: %d") % in_main + ("   ·   " + Loc.t("Side Deck: %d") % in_side if in_side > 0 else "") + "   ·   " + Loc.t("You own %d") % Collection.count(id), 15, UITheme.GOLD, UITheme.semi_font())
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(290, 0)
	_act_box.add_child(info)
	if from == "col":
		_act_btn(Loc.t("Add to deck"), Collection.can_add(id, false), func(): _quick_add(id, false), true)
		_act_btn(Loc.t("Add to Side Deck"), Collection.can_add(id, true), func(): _quick_add(id, true))
		if in_main > 0:
			_act_btn(Loc.t("Remove one from the deck"), true, func(): _take_out(id, "main"))
	elif from == "side":
		_act_btn(Loc.t("Remove from the Side Deck"), true, func(): _take_out(id, "side"), true)
		_act_btn(Loc.t("Move to the Main Deck"), true, func(): _to_main_deck(id))
	else:
		_act_btn(Loc.t("Remove from the deck"), true, func(): _take_out(id, from), true)
		if from == "main":
			_act_btn(Loc.t("Move to the Side Deck"), Collection.side.size() < Collection.SIDE_MAX, func(): _to_side_deck(id))
		_act_btn(Loc.t("Add another copy"), Collection.can_add(id, false), func(): _quick_add(id, false))


## A panel or strip that takes dropped cards. zone: "main" (the deck), "side", "col" (take it out).
func _drop_zone(c: Control, zone: String) -> void:
	c.set_drag_forwarding(Callable(), func(_at, data): return _can_drop(zone, data), func(_at, data): _drop(zone, data))


func _drag_from(id: int, from: String, src: Control) -> Variant:
	var p := TextureRect.new()
	p.texture = Cards.get_face(id)
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.size = Vector2(92, 134)
	p.position = -p.size / 2.0
	p.modulate.a = 0.92
	var wrap := Control.new()
	wrap.add_child(p)
	src.set_drag_preview(wrap)
	return {"card": id, "from": from}


func _can_drop(zone: String, data: Variant) -> bool:
	if not (data is Dictionary and (data as Dictionary).has("card")):
		return false
	var id := int(data["card"])
	var from := str(data["from"])
	match zone:
		"col":
			return from != "col"
		"side":
			return (from == "col" and Collection.can_add(id, true)) or (from == "main" and Collection.side.size() < Collection.SIDE_MAX)
	return (from == "col" and Collection.can_add(id, false)) or from == "side"


func _drop(zone: String, data: Variant) -> void:
	if not _can_drop(zone, data):
		return
	var id := int(data["card"])
	var from := str(data["from"])
	if zone == "col":
		_take_out(id, from)
	elif zone == "side":
		if from == "col":
			_quick_add(id, true)
		else:
			_to_side_deck(id)
	elif from == "col":
		_quick_add(id, false)
	else:
		_to_main_deck(id)


func _refresh_count() -> void:
	if _undo_btn:
		_undo_btn.disabled = _undo.is_empty()
	if _read_l:
		var lv := [0, 0, 0]
		for mid_ in Collection.main:
			var cd := CardData.get_card(int(mid_))
			if str(cd.get("kind", "")) == "monster":
				var l := int(cd.get("level", 0))
				lv[0 if l <= 4 else (1 if l <= 6 else 2)] += 1
		var heavy: bool = lv[1] + lv[2] > 0 and (lv[1] + lv[2]) * 2 > lv[0]
		_read_l.text = Loc.t("No tribute: %d   ·   One tribute: %d   ·   Two tributes: %d") % lv + ("   ·   " + Loc.t("heavy on tributes") if heavy else "")
		_read_l.add_theme_color_override("font_color", UITheme.GOLD if heavy else UITheme.TEXT_DIM)
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Z and (event.ctrl_pressed or event.meta_pressed):
		get_viewport().set_input_as_handled()
		_undo_last()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _hand_box != null and is_instance_valid(_hand_box):
			_hand_box.queue_free()
			_hand_box = null
			return
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
