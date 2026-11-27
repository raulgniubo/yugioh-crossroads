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
var _search_f := ""     # the same, folded for names (CardSearch)
var _filter_btns := {}
var _use_btn: Button
var _attr := ""
var _level := 0          # 0 all, 1 = 1 to 4, 2 = 5 to 6, 3 = 7 and up
var _sort := 0           # 0 type, 1 ATK, 2 level, 3 name
var _to_side := false
var _race := ""           # monster Type filter ("" = any)
var _grid_empty: Label
var _mine := false        # (0.80.4) only the cards you have; off = every card of the game, yours first, the rest greyed
const CLASSES := [["", "Any kind"], ["-", "Monsters"], ["normal", "Normal monster"], ["effect", "Effect monster"],
	["ritual", "Ritual monster"], ["fusion", "Fusion"], ["synchro", "Synchro"], ["xyz", "Xyz"], ["tuner", "Tuner"],
	["-", "Spells"], ["s:normal", "Normal Spell"], ["s:quick-play", "Quick-Play Spell"], ["s:continuous", "Continuous Spell"],
	["s:equip", "Equip Spell"], ["s:field", "Field Spell"], ["s:ritual", "Ritual Spell"],
	["-", "Traps"], ["t:normal", "Normal Trap"], ["t:continuous", "Continuous Trap"], ["t:counter", "Counter Trap"]]
var _class := ""          # card class filter: "normal", "effect", "fusion"... or a Spell/Trap kind ("" = any)
var _undo: Array = []     # earlier states of the deck, newest last
var _undo_btn: Button
var _ask_row: HBoxContainer
var _ask_l: Label
var _ask_yes: Button
var _ask_do: Callable
var _read_l: Label
var _pin := {}            # the card you tapped: {"id", "from"} with from = col | main | extra | side
var _act_box: VBoxContainer
var _peek := -1            # the card under the pointer when it is not the tapped one (the big picture shows it)
var _mark: Panel
var _slot_pick: OptionButton
var _name_edit: LineEdit
var _warn: Label
var _admin_fill: Button


func _panel(pad := 16) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.82), 18, Color(UITheme.ACCENT, 0.22))
	sb.set_content_margin_all(pad)
	pc.add_theme_stylebox_override("panel", sb)
	return pc


func _ready() -> void:
	if OS.has_environment("BUILDER_DEV"):
		_dev_env.call_deferred()
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	_note_seen(true)
	_seen_at_open = (Collection.record.get("seen", {}) as Dictionary).duplicate()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(AcademyBackdrop.new(0.66, CardsGate.PICTURE, Color(1.0, 0.86, 0.5)))
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
	# The tools on a row of their own under it (test hand, tips, share, undo), so the top row
	# fits in every language and the Done button never runs off the screen.
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 10)
	root.add_child(tools)
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
	tools.add_child(hand)
	var tips := Button.new()
	tips.text = Loc.t("Deck tips")
	tips.tooltip_text = Loc.t("Looks over this deck and points out anything that could trip it up.")
	tips.add_theme_font_size_override("font_size", 18)
	tips.custom_minimum_size = Vector2(0, 44)
	tips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tips.pressed.connect(_show_tips)
	tools.add_child(tips)
	var share := Button.new()
	share.text = Loc.t("Share")
	share.tooltip_text = Loc.t("Copy this deck as a code to send a friend, or build a deck from a friend's code.")
	share.add_theme_font_size_override("font_size", 18)
	share.custom_minimum_size = Vector2(0, 44)
	share.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	share.pressed.connect(_show_share)
	tools.add_child(share)
	_undo_btn = Button.new()
	_undo_btn.text = "Undo"
	_undo_btn.tooltip_text = Loc.t("Takes back your last change (Ctrl+Z).")
	_undo_btn.add_theme_font_size_override("font_size", 18)
	_undo_btn.custom_minimum_size = Vector2(0, 44)
	_undo_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_undo_btn.disabled = true
	_undo_btn.pressed.connect(_undo_last)
	tools.add_child(_undo_btn)
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
	_warn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var warn_row := HBoxContainer.new()
	warn_row.add_theme_constant_override("separation", 14)
	root.add_child(warn_row)
	warn_row.add_child(_warn)
	# Admin mode only: one press puts every missing copy of this deck in your collection.
	_admin_fill = Button.new()
	_admin_fill.visible = false
	_admin_fill.focus_mode = Control.FOCUS_NONE
	_admin_fill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_admin_fill.add_theme_font_size_override("font_size", 16)
	_admin_fill.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.18), UITheme.GOLD))
	_admin_fill.add_theme_color_override("font_color", UITheme.GOLD)
	_admin_fill.pressed.connect(func():
		var got := Collection.admin_fill_missing()
		if got > 0:
			Sfx.play("coin")
			_changed()
			_rebuild_grid())
	warn_row.add_child(_admin_fill)
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
	_dp = dp
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
	starter.add_item(Loc.t("★ Best of my cards"))
	var keys := ["*mine"]
	for k in CardData.DECKS.keys() + CardData.NAMED_DECKS.keys():
		if CardData.has_deck(k):
			keys.append(k)
			starter.add_item(CardData.deck_name(k))
	starter.item_selected.connect(func(i):
		if i <= 0:
			return
		var key := str(keys[i - 1])
		starter.select(0)
		if key == "*mine":
			var mine := func():
				_snap()
				var r := auto_build()
				Collection.main = r["main"]
				Collection.extra = r["extra"]
				Collection.side.clear()
				Collection.save()
				Router.toast(Loc.t("Built a %d-card deck from your strongest cards. Deck tips can fine-tune it.") % Collection.main.size(), 3.0)
				_refresh_all()
			if Collection.main.is_empty() and Collection.extra.is_empty():
				mine.call()
			else:
				_ask(Loc.t("Replace this deck with one built from your strongest cards?"), Loc.t("Replace"), mine)
			return
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
	var dpad := MarginContainer.new()
	dpad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side_ in ["left", "top", "right", "bottom"]:
		dpad.add_theme_constant_override("margin_" + side_, 6)
	rs.add_child(dpad)
	dpad.add_child(_deck_list)
	# ---- right: everything you own
	var cp := _panel(16)
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cp.size_flags_stretch_ratio = 1.0
	body.add_child(cp)
	_cp = cp
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	cp.add_child(col)
	# (These rows wrap instead of pushing the panel off the right edge: the Spanish labels are long.)
	var bar := HFlowContainer.new()
	bar.add_theme_constant_override("h_separation", 6)
	bar.add_theme_constant_override("v_separation", 6)
	col.add_child(bar)
	bar.add_child(UITheme.label("COLLECTION", 18, UITheme.ACCENT, UITheme.semi_font()))
	var bsp := Control.new()
	bsp.custom_minimum_size = Vector2(6, 0)
	bar.add_child(bsp)
	for f in [["all", "All"], ["monster", "Monsters"], ["spell", "Spells"], ["trap", "Traps"], ["extra", "Extra"], ["ours", "Crossroads"]]:
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
		# (hover and focus with the same margins as normal: the theme's own cut the word short)
		var hov := UITheme.button_box(Color(1, 1, 1, 0.12), Color(UITheme.ACCENT, 0.6), 10)
		hov.content_margin_left = 12
		hov.content_margin_right = 12
		b.add_theme_stylebox_override("hover", hov)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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
	var bar2 := HFlowContainer.new()
	bar2.add_theme_constant_override("h_separation", 6)
	bar2.add_theme_constant_override("v_separation", 6)
	col.add_child(bar2)
	var search := LineEdit.new()
	search.placeholder_text = Loc.t("Search…")
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size = Vector2(170, 40)
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", 16)
	# (0.59.1: the grid is rebuilt a moment after the last key, not on every key)
	var wait := Timer.new()
	wait.one_shot = true
	wait.wait_time = 0.15
	add_child(wait)
	wait.timeout.connect(func():
		_search = search.text.strip_edges().to_lower()
		_search_f = CardSearch.fold(search.text)
		_rebuild_grid())
	search.text_changed.connect(func(_t): wait.start())
	bar2.add_child(search)
	var attr := OptionButton.new()
	attr.add_theme_font_size_override("font_size", 16)
	attr.fit_to_longest_item = false
	attr.clip_text = true
	attr.custom_minimum_size = Vector2(130, 0)
	attr.add_item("Attribute")
	for a in ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND", "DIVINE"]:
		attr.add_item(a)
	attr.item_selected.connect(func(i):
		_attr = "" if i == 0 else ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND", "DIVINE"][i - 1]
		_rebuild_grid())
	bar2.add_child(attr)
	var races := {}
	for k in Collection.all_cards():
		var cd := CardData.get_card(int(k))
		if str(cd.get("kind", "")) == "monster" and str(cd.get("race", "")) != "":
			races[str(cd["race"])] = true
	var race_names: Array = races.keys()
	race_names.sort()
	var rc := OptionButton.new()
	rc.add_theme_font_size_override("font_size", 16)
	rc.fit_to_longest_item = false
	rc.clip_text = true
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
	lv.clip_text = true
	lv.custom_minimum_size = Vector2(100, 0)
	for t in ["Level / Rank", "Level 1 to 4", "Level 5 and 6", "Level 7 and up"]:
		lv.add_item(Loc.t(t))
	for n in range(1, 13):
		lv.add_item(Loc.t("Level / Rank %d") % n)
	lv.item_selected.connect(func(i):
		_level = i
		_rebuild_grid())
	bar2.add_child(lv)
	# What kind of card: the monster frames, and the kinds of Spell and Trap.
	var cl := OptionButton.new()
	cl.add_theme_font_size_override("font_size", 16)
	cl.fit_to_longest_item = false
	cl.clip_text = true
	cl.custom_minimum_size = Vector2(200, 0)     # (wide enough for "Mágica de Juego Rápido"; it goes to the second row)
	var classes: Array = CLASSES
	for c in classes:
		if str(c[0]) == "-":
			cl.add_separator(Loc.t(str(c[1])))
		else:
			cl.add_item(Loc.t(str(c[1])))
			cl.set_item_metadata(cl.item_count - 1, str(c[0]))
	cl.item_selected.connect(func(i):
		_class = str(cl.get_item_metadata(i)) if cl.get_item_metadata(i) != null else ""
		_rebuild_grid())
	bar2.add_child(cl)
	var so := OptionButton.new()
	so.add_theme_font_size_override("font_size", 16)
	so.fit_to_longest_item = false
	so.clip_text = true
	so.custom_minimum_size = Vector2(150, 0)
	for t in ["Sort: type", "Sort: ATK", "Sort: Level", "Sort: name"]:
		so.add_item(t)
	so.item_selected.connect(func(i):
		_sort = i
		_rebuild_grid())
	bar2.add_child(so)
	_grid_empty = UITheme.label("", 18, UITheme.TEXT_DIM, UITheme.semi_font())
	_grid_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_grid_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_grid_empty.custom_minimum_size = Vector2(0, 60)
	_grid_empty.visible = false
	col.add_child(_grid_empty)
	var gscroll := ScrollContainer.new()
	_gscroll = gscroll
	gscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(gscroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	var gpad := MarginContainer.new()
	for side_ in ["left", "top", "right", "bottom"]:
		gpad.add_theme_constant_override("margin_" + side_, 8)
	gscroll.add_child(gpad)
	gpad.add_child(_grid)
	# As many columns as fit (it was always 6, and six cards were wider than the panel on some screens).
	gscroll.resized.connect(func():
		var cols := clampi(int((gscroll.size.x - 24.0) / 120.0), 3, 8)
		if cols != _grid.columns:
			_grid.columns = cols)
	var foot := HFlowContainer.new()
	foot.add_theme_constant_override("h_separation", 18)
	foot.add_theme_constant_override("v_separation", 4)
	col.add_child(foot)
	# (0.80.4, Raul) Every card of the game is listed by default, like Master Duel: yours first, the
	# ones you don't have greyed (you can still plan a deck with them). This switch narrows it to yours.
	var mine_t := CheckButton.new()
	mine_t.text = Loc.t("Only cards I have")
	mine_t.add_theme_font_size_override("font_size", 15)
	mine_t.tooltip_text = Loc.t("Shows only the cards in your collection. Off: every card of the game, yours first and the ones you don't have yet greyed.")
	for cn in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		mine_t.add_theme_color_override(cn, UITheme.GOLD)
	mine_t.toggled.connect(func(on):
		_mine = on
		_rebuild_grid())
	foot.add_child(mine_t)
	# (0.81.0, Raul: "Only what I can add" read as the same thing as "Only cards I have". It is gone:
	# one switch for which cards are listed. A card whose every copy is in the deck says so on its tile.)
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
	if "--builder-empty" in OS.get_cmdline_user_args():
		Collection.main.clear()      # (dev: pictures of an empty deck)
		Collection.extra.clear()
		Collection.side.clear()
	if "--builder-plan" in OS.get_cmdline_user_args():
		# (dev: a deck with cards you don't have yet)
		var n := 0
		for cid in Collection.all_cards():
			if Collection.count(int(cid)) == 0 and str(CardData.get_card(int(cid)).get("kind", "")) == "monster" and n < 4:
				Collection.main.append(int(cid))
				n += 1
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


## The cards in the order picked. Each card's key is worked out once (a sort that looked every
## card up again for every comparison took seconds over the whole game). `owned_first`: yours come
## before the ones you don't have yet.
## (0.81.0) The list is every card of the game by default now, so this runs over 12,700 cards each
## time: one sort key per card and the engine's own sort (it was a comparison written here, called
## 170,000 times). `info`: card data already read by the caller, by id.
func _sorted(ids: Array, owned_first := false, info := {}) -> Array:
	var rows: Array = []
	rows.resize(ids.size())
	var n := 0
	for id in ids:
		var d: Dictionary = info[id] if info.has(id) else CardData.get_card(id)
		var k := 0 if d["kind"] == "monster" else (1 if d["kind"] == "spell" else 2)
		var own := 0 if (not owned_first or Collection.count(id) > 0) else 1
		var nm := str(d.get("name", ""))
		match _sort:
			3:
				rows[n] = [own, 0, 0, nm, id]
			2:
				rows[n] = [own, -int(d.get("level", 0)), k, nm, id]
			1:
				rows[n] = [own, -int(d.get("atk", 0)), k, nm, id]
			_:
				rows[n] = [own, k, -int(d.get("atk", 0)), nm, id]
		n += 1
	rows.sort()
	var out: Array = []
	out.resize(rows.size())
	for i in rows.size():
		out[i] = rows[i][4]
	return out


func _rebuild_grid() -> void:
	for k in _filter_btns:
		(_filter_btns[k] as Button).set_pressed_no_signal(k == _filter)
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_grid_far_n = -1
	# Yours, or every card of the game (with "Every card in the game", and always when searching:
	# a card you are looking for is found whether you have it or not; yours come first).
	var everything := not _mine
	var source: Array = _every_card() if everything else Collection.owned.keys()
	var keep: Array = []
	# (What a card is does not change while the game runs: read once, kept for every later look.
	# Lumen herself is the exception, she grows with your bonds.)
	if _info_stamp != CardData.EXT.size():
		_info_stamp = CardData.EXT.size()
		_info = {}
	var info := _info
	info.erase(CardData.LUMEN)
	for id in source:
		var d: Dictionary
		if info.has(id):
			d = info[id]
		else:
			d = CardData.get_card(id)
			info[id] = d
		var fr := str(d.get("frame", ""))
		var is_extra: bool = fr in ["fusion", "synchro", "xyz"]
		if _filter == "extra" and not is_extra:
			continue
		if _filter == "ours" and not CardData.is_original(id):   # the cards that only exist in this game
			continue
		if _filter in ["monster", "spell", "trap"] and (d["kind"] != _filter or is_extra):
			continue
		if _attr != "" and str(d.get("attribute", "")) != _attr:
			continue
		if _race != "" and (d["kind"] != "monster" or str(d.get("race", "")) != _race):
			continue
		if _class != "" and not _is_class(id, d, fr):
			continue
		if _level > 0:
			var l := int(d.get("level", 0))
			if d["kind"] != "monster":
				continue
			if (_level == 1 and l > 4) or (_level == 2 and (l < 5 or l > 6)) or (_level == 3 and l < 7) or (_level >= 4 and l != _level - 3):
				continue
		if _search != "" and not _found(id, d):
			continue
		keep.append(id)
	# The first screens of tiles are there at once; the rest of a long list follows over the next
	# frames (a tile is an empty box until it comes near the screen, but 12,700 boxes in one frame
	# was a hitch you could feel).
	var order := _sorted(keep, everything, info)
	var shown := order.size()
	_grid_gen += 1
	for i in mini(GRID_FIRST, order.size()):
		_grid.add_child(_tile(order[i]))
	if order.size() > GRID_FIRST:
		_grid_rest(order, _grid_gen)
	if _owned_l:
		var copies := 0
		for k in Collection.owned:
			copies += int(Collection.owned[k])
		var total: int = Collection.owned.size()
		var all_n: int = _every_card().size()      # (with Lumen's cards, which no booster set lists)
		if everything:
			_owned_l.text = Loc.t("You own %d of %d cards") % [total, all_n] + "  ·  " + (Loc.t("showing every card") if shown == all_n else Loc.t("showing %d") % shown) + "  ·  " + Loc.t("the grey ones you don't have yet")
		else:
			_owned_l.text = Loc.t("You own %d different cards  ·  %d copies in total") % [total, copies] + "  ·  " + (Loc.t("showing all of them") if shown == total else Loc.t("showing %d of %d") % [shown, total])
		_owned_l.add_theme_color_override("font_color", UITheme.TEXT if shown == total and not everything else UITheme.GOLD)
	_grid_empty.visible = shown == 0
	if shown == 0:
		_grid_empty.text = Loc.t("No card matches. Try fewer filters.") if everything else Loc.t("None of your cards match. Turn off \"Only cards I have\" to look through all of them.")


const GRID_FIRST := 240
const GRID_STEP := 1100
var _grid_gen := 0
static var _info := {}
static var _info_stamp := -1

func _grid_rest(order: Array, gen: int) -> void:
	var at := GRID_FIRST
	while at < order.size():
		await get_tree().process_frame
		if gen != _grid_gen or not is_inside_tree():
			return      # (the list was built again meanwhile)
		for i in range(at, mini(at + GRID_STEP, order.size())):
			_grid.add_child(_tile(order[i]))
		at += GRID_STEP


## Every card a deck can be built from: the game's whole list, Lumen's cards (the game's own, which
## no booster set lists) and anything else you hold. (Lumen's cards were missing from the search.)
var _every: Array = []

func _every_card() -> Array:
	if _every.is_empty():
		var seen := {}
		for id in Collection.all_cards():
			seen[int(id)] = true
		for id in CardData.LUMEN_CARDS:
			if not CardData.get_card(int(id)).is_empty():
				seen[int(id)] = true
		for id in Collection.owned.keys():
			seen[int(id)] = true
		_every = seen.keys()
	return _every


## Is this card of the kind picked in the class filter?
func _is_class(id: int, d: Dictionary, fr: String) -> bool:
	if _class.begins_with("s:") or _class.begins_with("t:"):
		if d["kind"] != ("spell" if _class.begins_with("s:") else "trap"):
			return false
		var k := DuelWhy.spell_kind(id)
		if k == "":
			k = "normal"
		return k == _class.substr(2)
	if d["kind"] != "monster":
		return false
	match _class:
		"tuner":
			return bool(d.get("tuner", false))
		"effect":
			return fr == "effect"
		_:
			return fr == _class


## A tile starts as an empty box of the right size. Its picture, badges and handlers are only made
## while it is near the part of the list on screen (_grid_tick), and dropped again when it is far.
## Before, every owned card loaded its picture when the editor opened: with a few thousand cards
## that was minutes of waiting and gigabytes of pictures.
func _tile(id: int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(112, 163)
	holder.pivot_offset = Vector2(56, 81)
	holder.set_meta("id", id)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return holder


var _tile_boxes := {}

func _tile_box(kind: String) -> StyleBox:
	if not _tile_boxes.has(kind):
		var sb: StyleBoxFlat
		match kind:
			"badge":
				sb = UITheme.panel_box(Color(0, 0, 0, 0.82), 9, Color(1, 1, 1, 0.25))
				sb.content_margin_left = 7
				sb.content_margin_right = 7
			"strip":
				sb = UITheme.panel_box(Color(UITheme.GOLD, 0.95), 7, UITheme.GOLD)
				sb.content_margin_left = 5
				sb.content_margin_right = 5
			"strip_missing":
				sb = UITheme.panel_box(Color(Comic.RED, 0.95), 7, Color(Comic.RED, 0.95))
				sb.content_margin_left = 5
				sb.content_margin_right = 5
			_:
				sb = UITheme.panel_box(Color(Comic.RED, 0.95), 7, Color.WHITE)
				sb.content_margin_left = 6
				sb.content_margin_right = 6
		sb.content_margin_top = 1
		sb.content_margin_bottom = 1
		_tile_boxes[kind] = sb
	return _tile_boxes[kind]


func _empty_tile(holder: Control) -> void:
	for c in holder.get_children():
		c.queue_free()
	holder.remove_meta("refresh")
	holder.scale = Vector2.ONE
	holder.z_index = 0


func _fill_tile(holder: Control) -> void:
	var id := int(holder.get_meta("id"))
	var tr := TextureRect.new()
	# (The picture is read off the main thread: the tile is there at once, its face a moment later.)
	var tr_id := tr.get_instance_id()      # (by number: the tile may be gone by the time its picture is read)
	Cards.thumb_later(id, func(tex: Texture2D):
		var still := instance_from_id(tr_id) as TextureRect
		if still != null:
			still.texture = tex)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	holder.add_child(tr)
	var have := Collection.count(id) > 0
	if have:
		Foil.apply(tr, CardData.rarity(id), id)
	else:
		tr.material = AlbumSlot.gray_material()
	var badge := Label.new()
	badge.add_theme_font_override("font", UITheme.semi_font())
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_stylebox_override("normal", _tile_box("badge"))
	badge.position = Vector2(4, 4)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(badge)
	# How many are in the deck on the table, on its own strip, so the corner only says what you own.
	var strip := Label.new()
	strip.add_theme_font_override("font", UITheme.semi_font())
	strip.add_theme_font_size_override("font_size", 12)
	strip.add_theme_color_override("font_color", Color(0.03, 0.05, 0.1))
	# (never wider than the card: "Todas en este deck" ran past its right edge)
	strip.clip_text = true
	strip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	strip.add_theme_stylebox_override("normal", _tile_box("strip"))
	strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_left = 4
	strip.offset_right = -4
	strip.offset_top = -30
	strip.offset_bottom = -6
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(strip)
	if is_new_card(id):
		var nw := Label.new()
		nw.text = Loc.t("NEW")
		nw.add_theme_font_override("font", UITheme.semi_font())
		nw.add_theme_font_size_override("font_size", 13)
		nw.add_theme_color_override("font_color", Color.WHITE)
		nw.add_theme_stylebox_override("normal", _tile_box("new"))
		nw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(nw)
		# (Pinned to the top-right corner, whatever the word's length: "NUEVA" ran past the card.)
		nw.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		nw.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		nw.position += Vector2(-4, 4)
	# A card you don't have yet: grey with x0 (it can still go in a deck to plan it).
	# (0.72.1: no padlock: it read as "can't be added", and it can)
	var refresh := func():
		var used := Collection.in_deck(id)
		var lim := Collection.limit(id)
		var own := Collection.count(id)
		var can_use: int = mini(mini(3, lim), own)
		badge.text = "x%d" % own     # (x0 in pink for a card you don't have: "Not yours yet" ran past the card)
		badge.add_theme_color_override("font_color", Color.WHITE if own > 0 else Color("ffb3bd"))
		if lim < 3:
			badge.text += ["   FORBIDDEN", "   LIMITED", "   SEMI"][lim]
		strip.visible = used > 0
		# (short, so it fits the card; a red strip says some of those copies are not yours yet)
		strip.add_theme_stylebox_override("normal", _tile_box("strip_missing" if used > own else "strip"))
		strip.add_theme_color_override("font_color", Color.WHITE if used > own else Color(0.03, 0.05, 0.1))
		if used > own:
			strip.text = Loc.t("In this deck: %d") % used
		else:
			strip.text = Loc.t("All in this deck") if used >= can_use else Loc.t("In this deck: %d") % used
		# (0.72.2: a card is never darkened for "no more copies can go in": next to the grey cards you
		# don't have, a dark card you do have read as missing. The strip says "All in this deck".)
		tr.modulate = Color.WHITE
	refresh.call()
	tr.mouse_entered.connect(func():
		if _drag != null:
			return
		_show(id)
		holder.z_index = 2
		holder.create_tween().tween_property(holder, "scale", Vector2(1.07, 1.07), 0.08))
	tr.mouse_exited.connect(func():
		holder.z_index = 0
		holder.create_tween().tween_property(holder, "scale", Vector2.ONE, 0.1)
		_show_pin())
	tr.gui_input.connect(func(e):
		_follow_grab(e)
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if e.double_click:
				# The fast way: one more copy into the deck.
				_quick_add(id)
			else:
				_select(id, "col", holder)
				_grab = {"card": id, "from": "col", "src": tr, "at": get_global_mouse_position()})
	if _pin.get("from", "") == "col" and int(_pin.get("id", -1)) == id:
		_place_mark(holder)
	holder.set_meta("refresh", refresh)


## Fills the tiles near the visible part of the list (a few milliseconds' worth per frame, the ones
## on screen first) and empties the ones that are far away.
const TILE_FILL_MS := 7.0
const TILE_NEAR := 260.0      # filled this far above and below what is on screen
const TILE_FAR := 1500.0      # emptied beyond this

func _grid_tick() -> void:
	if _grid == null or _gscroll == null or not is_visible_in_tree():
		return
	var n := _grid.get_child_count()
	if n == 0:
		return
	var cols: int = maxi(1, _grid.columns)
	var row_h := 163.0 + 8.0
	var top := float(_gscroll.scroll_vertical) - 8.0
	var bottom := top + _gscroll.size.y
	var first := clampi(int(floor((top - TILE_NEAR) / row_h)), 0, (n - 1) / cols)
	var last := clampi(int(floor((bottom + TILE_NEAR) / row_h)), 0, (n - 1) / cols)
	var mid := clampi(int(floor((top + bottom) * 0.5 / row_h)), first, last)
	var t0 := Time.get_ticks_usec()
	# From the middle of the screen outwards, so what you are looking at comes first.
	var rows := [mid]
	for k in range(1, last - first + 2):
		if mid + k <= last:
			rows.append(mid + k)
		if mid - k >= first:
			rows.append(mid - k)
	var out_of_time := false
	for r in rows:
		for c in cols:
			var i: int = r * cols + c
			if i >= n:
				break
			var h := _grid.get_child(i) as Control
			if h == null or h.is_queued_for_deletion() or h.has_meta("refresh"):
				continue
			# (No more than a screenful being read at a time: flinging the scroll bar across thousands of
			# cards must not queue every picture it passes.)
			if Cards.thumbs_busy() >= 48 and not Cards.has_thumb(int(h.get_meta("id"))):
				out_of_time = true
				break
			_fill_tile(h)
			if (Time.get_ticks_usec() - t0) / 1000.0 > TILE_FILL_MS:
				out_of_time = true
				break
		if out_of_time:
			break
	# The far ones let go of their pictures (never while a card is being dragged out of the list).
	if _grab.is_empty() and _drag == null and (_grid_far_at != _gscroll.scroll_vertical or _grid_far_n != n):
		_grid_far_at = _gscroll.scroll_vertical
		_grid_far_n = n
		var keep_a := int(floor((top - TILE_FAR) / row_h)) * cols
		var keep_b := (int(floor((bottom + TILE_FAR) / row_h)) + 1) * cols
		for i in n:
			if i >= keep_a and i < keep_b:
				continue
			var h := _grid.get_child(i) as Control
			if h != null and h.has_meta("refresh"):
				_empty_tile(h)

var _gscroll: ScrollContainer
var _grid_far_at := -1
var _grid_far_n := -1


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
		if is_side:
			_side_head = head
		var marked := false
		if ids.is_empty():
			# Empty: a few dashed card places and one short line, in the place itself.
			var ghosts: int = 5 if is_main else 3
			for g in ghosts:
				var gs := _GhostSlot.new()
				gs.custom_minimum_size = Vector2(62, 90)
				gs.mouse_filter = Control.MOUSE_FILTER_IGNORE
				gs.fade = 1.0 - float(g) / float(ghosts + 1)
				gs.col = UITheme.GOLD if is_side else (Color("b48cff") if not is_main else Comic.SKY)
				flow.add_child(gs)
			var tip := UITheme.label({"MAIN DECK": "Drag cards here, or double-click one in the collection.",
				"EXTRA DECK": "Fusion, Synchro and Xyz monsters land here.",
				"SIDE DECK": "Optional: up to 15 cards to swap in between Match duels."}[section[0]], 15, UITheme.TEXT_DIM, UITheme.semi_font())
			tip.text = Loc.t(tip.text)
			tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tip.custom_minimum_size = Vector2(200, 0)
			tip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var tipbox := CenterContainer.new()
			tipbox.custom_minimum_size = Vector2(240, 90)
			tipbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tipbox.add_child(tip)
			flow.add_child(tipbox)
		var seen := {}
		for id in _sorted(ids):
			var card := TextureRect.new()
			card.texture = Cards.get_thumb(id)
			card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card.custom_minimum_size = Vector2(62, 90)
			card.pivot_offset = Vector2(31, 45)
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			card.set_meta("id", id)
			flow.add_child(card)
			# A copy you don't have yet: grey, with a red corner (the deck waits for it).
			seen[id] = int(seen.get(id, 0)) + 1
			if int(seen[id]) > Collection.count(id) and id != CardData.LUMEN:
				card.material = AlbumSlot.gray_material()
				card.tooltip_text = Loc.t("You don't have this copy yet")
				var dot := Panel.new()
				var dsb := StyleBoxFlat.new()
				dsb.bg_color = Comic.RED
				dsb.set_corner_radius_all(7)
				dsb.border_color = Color.WHITE
				dsb.set_border_width_all(2)
				dot.add_theme_stylebox_override("panel", dsb)
				dot.size = Vector2(14, 14)
				dot.position = Vector2(62 - 16, 2)
				dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.add_child(dot)
			# The card you just added pops, so your eye lands on it.
			if id == _last_added and not popped:
				popped = true
				card.scale = Vector2(1.35, 1.35)
				card.modulate = Color(1.6, 1.6, 1.6)
				var tw := card.create_tween().set_parallel()
				tw.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(card, "modulate", Color.WHITE, 0.3)
			card.mouse_entered.connect(func():
				if _drag != null:
					return
				_show(id)
				card.z_index = 2
				card.create_tween().tween_property(card, "scale", Vector2(1.12, 1.12), 0.08))
			card.mouse_exited.connect(func():
				card.z_index = 0
				card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.1)
				_show_pin())
			card.gui_input.connect(func(e):
				_follow_grab(e)
				if not (e is InputEventMouseButton and e.pressed):
					return
				# No hidden clicks: a card only moves when you drag it or press its button.
				if e.button_index == MOUSE_BUTTON_LEFT:
					if e.double_click:
						# The fast way: one copy out.
						_take_out(id, part)
					else:
						_select(id, part, card)
						_grab = {"card": id, "from": part, "src": card, "at": get_global_mouse_position()})
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
	_mark.offset_left = -2
	_mark.offset_top = -2
	_mark.offset_right = 2
	_mark.offset_bottom = 2
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
	if not Collection.can_add(id, to_side, true):
		Sfx.play("click", -6.0)
		return
	_snap()
	if to_side:
		Collection.add_side(id, true)
	else:
		Collection.add(id, true)
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
	if Collection.can_add(id, false, true):
		Collection.add(id, true)
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
## Plain advice about a deck: what might stop it from working. Each entry is one sentence,
## already in the player's language. Empty means nothing stood out.
static func deck_tips(main: Array, extra: Array) -> Array:
	var out := []
	var mons := 0
	var low := 0
	var high := 0
	var tuners := 0
	var spells := 0
	var traps := 0
	var by_level := {}
	var names := {}
	var has_fusion_spell := false
	var has_ritual_spell := false
	var rituals := 0
	for x in main:
		var d := CardData.get_card(int(x))
		var nm := str(d.get("name", ""))
		names[nm.to_lower()] = true
		match str(d.get("kind", "")):
			"monster":
				mons += 1
				var l := int(d.get("level", 0))
				by_level[l] = int(by_level.get(l, 0)) + 1
				if l <= 4:
					low += 1
				else:
					high += 1
				if bool(d.get("tuner", false)):
					tuners += 1
				if str(d.get("frame", "")) == "ritual":
					rituals += 1
			"spell":
				spells += 1
				if "Polymerization" in nm or "Fusion" in nm or nm == "Power Bond" or nm == "Miracle Fusion":
					has_fusion_spell = true
				if "Ritual" in nm or str(d.get("st", "")) == "ritual":
					has_ritual_spell = true
			_:
				traps += 1
	var n := main.size()
	if n > 45:
		out.append(Loc.t("%d cards is a lot. With 40 you draw your best cards more often.") % n)
	if mons < 12:
		out.append(Loc.t("Only %d monsters. Most decks want about 14 to 20 so there is always something to summon.") % mons)
	elif n > 0 and mons > 28:
		out.append(Loc.t("%d monsters leaves little room for Spells and Traps to protect them.") % mons)
	if mons > 0 and high > 0 and high * 2 > low:
		out.append(Loc.t("%d monsters need tributes and only %d do not. Add more Level 4 or lower so you can open.") % [high, low])
	if traps == 0 and n >= 30:
		out.append(Loc.t("No Trap cards. One or two can stop an attack you did not see coming."))
	if rituals > 0 and not has_ritual_spell:
		out.append(Loc.t("You have Ritual monsters but no Ritual Spell to summon them."))
	var synchros := 0
	var fusions := 0
	var fus_missing := []
	var xyz_short := {}
	for x in extra:
		var d := CardData.get_card(int(x))
		match str(d.get("frame", "")):
			"synchro":
				synchros += 1
			"fusion":
				fusions += 1
				var mats := CardData.fusion_materials(d)
				for m in mats:
					var md := CardData.get_card(int(m))
					if int(m) != 0 and not names.has(str(md.get("name", "")).to_lower()):
						if not fus_missing.has(str(d.get("name", ""))):
							fus_missing.append(str(d.get("name", "")))
						break
			"xyz":
				var r := int(d.get("level", 0))
				if int(by_level.get(r, 0)) < 4:
					xyz_short[r] = true
	if synchros > 0 and tuners == 0:
		out.append(Loc.t("Your Extra Deck has Synchro monsters but your deck has no Tuners, so you cannot summon them."))
	elif synchros >= 3 and tuners < 3:
		out.append(Loc.t("Only %d Tuner(s) for %d Synchro monsters. A few more Tuners help.") % [tuners, synchros])
	if fusions > 0 and not has_fusion_spell:
		out.append(Loc.t("Your Extra Deck has Fusion monsters but no Polymerization or other Fusion Spell."))
	if not fus_missing.is_empty():
		var shown := fus_missing.slice(0, 3)
		out.append(Loc.t("Missing materials for: %s.") % ", ".join(shown))
	for r in xyz_short.keys():
		out.append(Loc.t("Few Level %d monsters for your Rank %d Xyz. Aim for at least 4.") % [r, r])
	return out


func _show_share() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := _panel(28)
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(UITheme.label(Loc.t("SHARE A DECK"), 30, Color.WHITE, UITheme.title_font()))
	var code := DeckCode.encode(Collection.main, Collection.extra, Collection.side)
	var hint := UITheme.label(Loc.t("This deck as a code. Copy it and send it to a friend: they paste it here to build the same deck (the cards they don't have yet come in greyed)."), 17, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)
	var out := TextEdit.new()
	out.text = code
	out.editable = false
	out.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	out.custom_minimum_size = Vector2(700, 90)
	v.add_child(out)
	var copy := Button.new()
	copy.text = "  %s  " % Loc.t("Copy code")
	copy.custom_minimum_size = Vector2(0, 46)
	copy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(code)
		Router.toast(Loc.t("Deck code copied.")))
	v.add_child(copy)
	v.add_child(UITheme.label(Loc.t("Build from a code"), 20, Color.WHITE, UITheme.semi_font()))
	var inp := TextEdit.new()
	inp.placeholder_text = Loc.t("Paste a deck code here")
	inp.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	inp.custom_minimum_size = Vector2(700, 90)
	v.add_child(inp)
	var res := UITheme.label("", 17, UITheme.TEXT)
	res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(res)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(btns)
	var paste := Button.new()
	paste.text = "  %s  " % Loc.t("Paste")
	paste.custom_minimum_size = Vector2(0, 48)
	paste.pressed.connect(func(): inp.text = DisplayServer.clipboard_get())
	btns.add_child(paste)
	var build := Button.new()
	build.text = "  %s  " % Loc.t("Build this deck")
	build.custom_minimum_size = Vector2(0, 48)
	build.pressed.connect(func():
		var d := DeckCode.decode(inp.text)
		if d.is_empty():
			res.text = Loc.t("That is not a deck code. It starts with CR1-.")
			res.add_theme_color_override("font_color", UITheme.DANGER)
			return
		var r := apply_code(d)
		_changed()
		res.add_theme_color_override("font_color", UITheme.TEXT)
		var lines: Array = []
		if (r["missing"] as Array).is_empty():
			lines.append(Loc.t("Done: every card is in, and you have them all. (Undo takes it back.)"))
		else:
			lines.append(Loc.t("Done: every card is in. You don't have these yet (greyed in the deck): %s. The deck can be dueled with once you have them.") % ", ".join(PackedStringArray(r["missing"])))
		if int(r.get("unknown", 0)) > 0:
			lines.append(Loc.t("%d cards of the code aren't in this game and were left out.") % int(r["unknown"]))
		res.text = "\n".join(lines))
	btns.add_child(build)
	var close := Button.new()
	close.text = "  %s  " % Loc.t("Close")
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(shade.queue_free)
	btns.add_child(close)


## Puts a decoded deck in the builder, every card of it: the ones you don't have yet go in all the
## same, greyed, and the deck can be dueled with once you have them. Returns {"missing": [names you
## don't have enough of], "unknown": n cards this game doesn't have at all}.
func apply_code(d: Dictionary) -> Dictionary:
	_snap()
	Collection.main = []
	Collection.extra = []
	Collection.side = []
	var unknown := 0
	for part in ["main", "extra", "side"]:
		for id in d[part]:
			var cd := CardData.get_card(int(id))
			if cd.is_empty() or str(cd.get("name", "Unknown")) == "Unknown" or not Collection.playable(int(id)):
				unknown += 1
				continue
			if Collection.in_deck(int(id)) >= mini(3, Collection.limit(int(id))):
				continue
			if part == "side":
				Collection.side.append(int(id))
			elif part == "extra" or str(cd.get("frame", "")) in ["fusion", "synchro", "xyz"]:
				Collection.extra.append(int(id))
			else:
				Collection.main.append(int(id))
	Collection.save()
	var missing := []
	for m in Collection.missing_cards():
		var nm := str(CardData.get_card(int(m[0])).get("name", ""))
		var short := int(m[1]) - int(m[2])
		missing.append(nm + ("" if short == 1 else " x%d" % short))
	return {"missing": missing, "unknown": unknown}


const STAPLES := ["Pot of Greed", "Monster Reborn", "Raigeki", "Dark Hole", "Mirror Force", "Heavy Storm", "Harpie's Feather Duster",
	"Swords of Revealing Light", "Change of Heart", "Mystical Space Typhoon", "Torrential Tribute", "Call of the Haunted", "Polymerization",
	"Premature Burial", "Graceful Charity", "Sakuretsu Armor", "Bottomless Trap Hole", "Magic Cylinder", "Dimensional Prison", "Book of Moon",
	"Solemn Judgment", "Trap Hole", "Mirror Wall", "Magic Jammer", "Brain Control"]
const GOOD_TRAPS := ["Mirror Force", "Torrential Tribute", "Sakuretsu Armor", "Bottomless Trap Hole", "Dimensional Prison", "Magic Cylinder",
	"Call of the Haunted", "Trap Hole", "Solemn Judgment", "Negate Attack", "Draining Shield", "Waboku", "Mirror Wall"]


## How much a card is worth keeping, roughly: big, easy-to-summon monsters and the classic Spells and Traps score high.
static func _worth(id: int) -> int:
	var d := CardData.get_card(id)
	var nm := str(d.get("name", ""))
	if str(d.get("kind", "")) != "monster":
		return 1800 + (500 if nm in STAPLES else 0)
	var s := int(d.get("atk", 0))
	if str(d.get("frame", "")) == "effect" or CardEffects.of(nm).size() > 0:
		s += 350
	var l := int(d.get("level", 0))
	if l >= 7:
		s -= 700
	elif l >= 5:
		s -= 350
	if bool(d.get("tuner", false)):
		s += 300
	return s


## Copies of a card you could still put in: what you own, minus what the deck holds, within the limit.
static func _spare(id: int, main: Array, extra: Array) -> int:
	var used := main.count(id) + extra.count(id) + Collection.side.count(id)
	return maxi(0, mini(Collection.count(id), mini(3, Collection.limit(id))) - used)


## Fixes what Deck tips points out, using only cards you own. Returns {"main", "extra", "changes": [text]}.
static func improve_deck(main_in: Array, extra_in: Array) -> Dictionary:
	var main: Array = main_in.duplicate()
	var extra: Array = extra_in.duplicate()
	var changes := []
	var owned_ids: Array = []
	for id in Collection.owned:
		if int(Collection.owned[id]) > 0 and Collection.playable(int(id)) and not CardData.is_extra(int(id)):
			owned_ids.append(int(id))
	var kind_of := func(id: int) -> String: return str(CardData.get_card(id).get("kind", ""))
	var lvl_of := func(id: int) -> int: return int(CardData.get_card(id).get("level", 0))
	var name_of := func(id: int) -> String: return str(CardData.get_card(id).get("name", ""))
	# Swap the weakest card that fits `out_f` for the best one you own that fits `in_f`.
	var swap := func(out_f: Callable, in_f: Callable, why: String) -> bool:
		var best_in := 0
		var best_s := -99999
		for id in owned_ids:
			if in_f.call(id) and _spare(id, main, extra) > 0 and _worth(id) > best_s:
				best_s = _worth(id)
				best_in = id
		if best_in == 0:
			return false
		var worst := -1
		var worst_s := 99999
		for i in main.size():
			if out_f.call(int(main[i])) and _worth(int(main[i])) < worst_s:
				worst_s = _worth(int(main[i]))
				worst = i
		if worst < 0:
			if main.size() >= 40:
				return false
			main.append(best_in)
			changes.append(Loc.t("Added %s (%s)") % [name_of.call(best_in), Loc.t(why)])
			return true
		var gone: int = main[worst]
		main[worst] = best_in
		changes.append(Loc.t("%s out, %s in (%s)") % [name_of.call(gone), name_of.call(best_in), Loc.t(why)])
		return true
	# 1. Down to 40: the weakest cards go.
	while main.size() > 40:
		var wi := 0
		for i in main.size():
			if _worth(int(main[i])) < _worth(int(main[wi])):
				wi = i
		changes.append(Loc.t("Took out %s (down to 40 cards)") % name_of.call(int(main[wi])))
		main.remove_at(wi)
	var count_mons := func() -> int: return main.filter(func(x): return kind_of.call(int(x)) == "monster").size()
	# 2. Enough monsters to always have something to summon.
	var guard := 0
	while count_mons.call() < 14 and guard < 8:
		guard += 1
		if not swap.call(func(x): return kind_of.call(x) != "monster" and not (name_of.call(x) in STAPLES),
				func(x): return kind_of.call(x) == "monster" and lvl_of.call(x) <= 4, "more monsters"):
			break
	# 3. Too many that need Tributes.
	guard = 0
	while guard < 12:
		guard += 1
		var low := main.filter(func(x): return kind_of.call(int(x)) == "monster" and lvl_of.call(int(x)) <= 4).size()
		var high := main.filter(func(x): return kind_of.call(int(x)) == "monster" and lvl_of.call(int(x)) >= 5).size()
		if high * 2 <= low:
			break
		if not swap.call(func(x): return kind_of.call(x) == "monster" and lvl_of.call(x) >= 5,
				func(x): return kind_of.call(x) == "monster" and lvl_of.call(x) <= 4, "fewer Tributes"):
			break
	# 4. Synchros need Tuners.
	var synchros := extra.filter(func(x): return str(CardData.get_card(int(x)).get("frame", "")) == "synchro").size()
	var tuners := main.filter(func(x): return bool(CardData.get_card(int(x)).get("tuner", false))).size()
	while synchros > 0 and tuners < mini(3, synchros + 1):
		if not swap.call(func(x): return kind_of.call(x) == "monster" and not bool(CardData.get_card(x).get("tuner", false)) and lvl_of.call(x) <= 4,
				func(x): return bool(CardData.get_card(x).get("tuner", false)), "Tuners for your Synchros"):
			break
		tuners += 1
	# 5. Fusions need Polymerization.
	var fusions := extra.filter(func(x): return str(CardData.get_card(int(x)).get("frame", "")) == "fusion").size()
	var has_poly := not main.filter(func(x): return name_of.call(int(x)) in ["Polymerization", "Power Bond", "Fusion Gate", "Miracle Fusion"]).is_empty()
	if fusions > 0 and not has_poly:
		swap.call(func(x): return kind_of.call(x) == "monster", func(x): return name_of.call(x) == "Polymerization", "for your Fusions")
	# 6. A Trap or two.
	var traps := main.filter(func(x): return kind_of.call(int(x)) == "trap").size()
	guard = 0
	while traps < 2 and count_mons.call() > 15 and guard < 2:
		guard += 1
		if not swap.call(func(x): return kind_of.call(x) == "monster", func(x): return name_of.call(x) in GOOD_TRAPS, "a Trap to stop attacks"):
			break
		traps += 1
	# 7. The classic Spells and Traps you own and left out, for the weakest monsters.
	guard = 0
	while guard < 4:
		guard += 1
		var cand := 0
		for id in owned_ids:
			if name_of.call(id) in ["Pot of Greed", "Monster Reborn", "Raigeki", "Dark Hole", "Mirror Force", "Heavy Storm", "Harpie's Feather Duster", "Swords of Revealing Light", "Change of Heart", "Graceful Charity"] \
					and _spare(id, main, extra) > 0 and not main.has(id):
				cand = id
				break
		if cand == 0 or count_mons.call() <= 15:
			break
		var wi2 := -1
		for i in main.size():
			if kind_of.call(int(main[i])) == "monster" and (wi2 < 0 or _worth(int(main[i])) < _worth(int(main[wi2]))):
				wi2 = i
		if wi2 < 0 or _worth(int(main[wi2])) > 1700:
			break
		changes.append(Loc.t("%s out, %s in (%s)") % [name_of.call(int(main[wi2])), name_of.call(cand), Loc.t("a classic you own")])
		main[wi2] = cand
	return {"main": main, "extra": extra, "changes": changes}


## A 40-card deck from the best of what you own: mostly monsters you can summon right away, a
## few big ones, the classic Spells and Traps, then the rest. The Extra Deck gets your strongest.
static func auto_build() -> Dictionary:
	var main := []
	var extra := []
	var ids: Array = []
	for id in Collection.owned:
		if int(Collection.owned[id]) > 0 and Collection.playable(int(id)):
			ids.append(int(id))
	ids.sort_custom(func(a, b): return _worth(a) > _worth(b))
	var take := func(filter: Callable, n: int, into: Array) -> void:
		for id in ids:
			if into.size() >= 60 or n <= 0:
				return
			if not filter.call(id):
				continue
			var k := _spare(id, main, extra)
			for c in mini(k, n):
				into.append(id)
				n -= 1
	var d := func(id: int) -> Dictionary: return CardData.get_card(id)
	var plain := func(id: int) -> bool: return not CardData.is_extra(id) and str(d.call(id).get("frame", "")) != "ritual"
	take.call(func(id): return plain.call(id) and d.call(id).get("kind", "") == "monster" and int(d.call(id).get("level", 0)) <= 4, 16, main)
	take.call(func(id): return plain.call(id) and d.call(id).get("kind", "") == "monster" and int(d.call(id).get("level", 0)) in [5, 6], 3, main)
	take.call(func(id): return plain.call(id) and d.call(id).get("kind", "") == "monster" and int(d.call(id).get("level", 0)) >= 7, 2, main)
	take.call(func(id): return str(d.call(id).get("name", "")) in STAPLES or str(d.call(id).get("name", "")) in GOOD_TRAPS, 40 - main.size(), main)
	take.call(func(id): return d.call(id).get("kind", "") != "monster" and (CardPool.has(int(id)) or SpellRules.FX.has(str(d.call(id).get("name", "")))), 40 - main.size(), main)
	take.call(func(id): return plain.call(id) and d.call(id).get("kind", "") == "monster" and int(d.call(id).get("level", 0)) <= 4, 40 - main.size(), main)
	var by_atk: Array = ids.filter(func(id): return CardData.is_extra(id))
	by_atk.sort_custom(func(a, b): return int(CardData.get_card(a).get("atk", 0)) > int(CardData.get_card(b).get("atk", 0)))
	for id in by_atk:
		var k := _spare(id, main, extra)
		for c in k:
			if extra.size() < 15:
				extra.append(id)
	# Then let the tips fix what is left (Tuners for the Synchros, Polymerization...).
	var r := improve_deck(main, extra)
	return {"main": r["main"], "extra": r["extra"]}


func _show_tips() -> void:
	var tips := deck_tips(Collection.main, Collection.extra)
	var text := ""
	if tips.is_empty():
		text = Loc.t("Looks solid. Nothing stands out that would stop this deck from working.")
	else:
		var lines := []
		for t in tips:
			lines.append("•  " + str(t))
		text = "\n\n".join(lines)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := _panel(28)
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	v.add_child(UITheme.label(Loc.t("DECK TIPS"), 30, Color.WHITE, UITheme.title_font()))
	var body := UITheme.label(text, 19, UITheme.TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(700, 0)
	v.add_child(body)
	var close := Button.new()
	close.text = "  %s  " % Loc.t("Close")
	close.custom_minimum_size = Vector2(0, 48)
	close.add_theme_font_size_override("font_size", 19)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(shade.queue_free)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.remove_child(close)
	if not tips.is_empty():
		var fix := Button.new()
		fix.text = "  %s  " % Loc.t("Improve it for me")
		fix.tooltip_text = Loc.t("Makes these fixes with cards you own. Undo takes it all back.")
		fix.custom_minimum_size = Vector2(0, 48)
		fix.add_theme_font_size_override("font_size", 19)
		fix.pressed.connect(func():
			var r := improve_deck(Collection.main, Collection.extra)
			if (r["changes"] as Array).is_empty():
				body.text = Loc.t("Nothing to change with the cards you own. More packs or duels would give it more to work with.")
				fix.disabled = true
				return
			_snap()
			Collection.main = r["main"]
			Collection.extra = r["extra"]
			Collection.save()
			_changed()
			var lines := []
			for t in r["changes"]:
				lines.append("•  " + str(t))
			body.text = Loc.t("Done. What changed (Undo takes it back):") + "\n\n" + "\n".join(lines)
			fix.disabled = true
			Sfx.play("card", -4.0))
		row.add_child(fix)
	row.add_child(close)
	v.add_child(row)
	Sfx.play("card", -6.0)


## Dev (BUILDER_DEV="pin=<id>;peek=<id>;where=<id>"): tap a card, put the pointer on another, open
## "Where to find it", for a picture of each.
func _dev_env() -> void:
	await get_tree().create_timer(1.5).timeout
	for bit in OS.get_environment("BUILDER_DEV").split(";", false):
		var kv := bit.split("=")
		var id := int(kv[1]) if kv.size() > 1 else 0
		match kv[0]:
			"pin":
				_pin = {"id": id, "from": "col"}
				_show(id)
				_refresh_actions()
			"peek":
				_show(id)
			"where":
				add_child(CardWhere.new(id))


func _refresh_actions() -> void:
	if _act_box == null:
		return
	for c in _act_box.get_children():
		_act_box.remove_child(c)
		c.queue_free()
	if _peek >= 0:
		# The big picture is showing the card under the pointer, not the tapped one: the line under
		# it is about that card too, and the tapped card's buttons wait until the pointer leaves.
		# (They used to stay: "You own 2" and "Add to deck" under a card you had none of.)
		var pk := UITheme.label(Loc.t("In this deck: %d") % (Collection.main.count(_peek) + Collection.extra.count(_peek)) + "   ·   " + Loc.t("You own %d") % Collection.count(_peek), 15, UITheme.GOLD, UITheme.semi_font())
		pk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pk.custom_minimum_size = Vector2(290, 0)
		_act_box.add_child(pk)
		if Collection.count(_peek) == 0 and _peek != CardData.LUMEN:
			var pn := UITheme.label(Loc.t("You don't have this card yet. It can go in the deck to plan it; the deck can be dueled with once you have it."), 14, Color("ffb3bd"))
			pn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			pn.custom_minimum_size = Vector2(290, 0)
			_act_box.add_child(pn)
		var ph := UITheme.label(Loc.t("Click the card to pick it: its buttons show up here."), 14, UITheme.TEXT_DIM)
		ph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ph.custom_minimum_size = Vector2(290, 0)
		_act_box.add_child(ph)
		return
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
	if Collection.count(id) == 0 and id != CardData.LUMEN:
		var nh := UITheme.label(Loc.t("You don't have this card yet. It can go in the deck to plan it; the deck can be dueled with once you have it."), 14, Color("ffb3bd"))
		nh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nh.custom_minimum_size = Vector2(290, 0)
		_act_box.add_child(nh)
	if from == "col":
		_act_btn(Loc.t("Add to deck"), Collection.can_add(id, false, true), func(): _quick_add(id, false), true)
		_act_btn(Loc.t("Add to Side Deck"), Collection.can_add(id, true, true), func(): _quick_add(id, true))
		if in_main > 0:
			_act_btn(Loc.t("Remove one from the deck"), true, func(): _take_out(id, "main"))
	elif from == "side":
		_act_btn(Loc.t("Remove from the Side Deck"), true, func(): _take_out(id, "side"), true)
		_act_btn(Loc.t("Move to the Main Deck"), true, func(): _to_main_deck(id))
	else:
		_act_btn(Loc.t("Remove from the deck"), true, func(): _take_out(id, from), true)
		if from == "main":
			_act_btn(Loc.t("Move to the Side Deck"), Collection.side.size() < Collection.SIDE_MAX, func(): _to_side_deck(id))
		_act_btn(Loc.t("Add another copy"), Collection.can_add(id, false, true), func(): _quick_add(id, false))
	# (0.82.2: Lumen's cards too. They are in the Echo Pack and in her decks now.)
	if not CardData.is_original(id) or CardData.LUMEN_CARDS.has(id) or Collection.count(id) == 0:
		_act_btn(Loc.t("Where to find it"), true, func():
			if find_children("*", "CardWhere", false, false).is_empty():
				add_child(CardWhere.new(id)))


# ---- dragging. You grab a card and it comes with the pointer, full size; the side it can go to
# lights up and says what letting go will do. Made by hand: the engine's own drag starts late,
# shows a small ghost and only lands on some of the panel.
var _grab := {}            # the card under the pressed button: {"card", "from", "src", "at"}
var _drag: Control         # the card in the air
var _drag_to := ""         # the zone under it: "main" | "side" | "col" | ""
var _drag_vx := 0.0
var _drag_idle := 0.0
var _dp: Control
var _cp: Control
var _side_head: Control
var _zone_glow: Panel
var _zone_tag: Label


func _input(event: InputEvent) -> void:
	_follow_grab(event)


## The grabbed card follows the pointer: from the panel's own input and, the same, from the tile that
## was pressed (it keeps getting the pointer while the button is down), so the drag starts and lands
## even when something else takes the panel's input first (0.72.1).
func _follow_grab(event: InputEvent) -> void:
	if _grab.is_empty():
		return
	if event is InputEventMouseMotion and _drag == null and ((event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		if get_global_mouse_position().distance_to(_grab["at"]) > 7.0:
			_start_drag()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _drag != null:
			get_viewport().set_input_as_handled()
			_end_drag()
		_grab = {}


func _start_drag() -> void:
	var id := int(_grab["card"])
	_drag = Control.new()
	_drag.top_level = true
	# (0.72.2: a top-level piece is drawn at its own z, not on top of this panel's. Opened from
	# DECKS & CARDS the editor sits at 100 + 110, so at 200 the card in the air and the glow were
	# drawn BEHIND the editor: the card went dim and nothing came out. Now they are above everything.)
	_drag.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 2
	_drag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_drag)
	var sz := Vector2(150, 218)
	var shade := Panel.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.0)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 22
	sb.shadow_offset = Vector2(0, 12)
	sb.set_corner_radius_all(8)
	shade.add_theme_stylebox_override("panel", sb)
	shade.size = sz
	shade.position = -sz / 2.0
	_drag.add_child(shade)
	var face := TextureRect.new()
	face.texture = Cards.get_face(id)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.size = sz
	face.position = -sz / 2.0
	_drag.add_child(face)
	_drag.global_position = get_global_mouse_position()
	_drag.scale = Vector2(0.55, 0.55)
	_drag.create_tween().tween_property(_drag, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var src: Control = _grab["src"]
	if is_instance_valid(src):
		_grab["was"] = src.modulate
		src.modulate = Color(src.modulate, 0.3)
	_zone_glow = Panel.new()
	_zone_glow.top_level = true
	_zone_glow.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 6
	_zone_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zone_glow.visible = false
	add_child(_zone_glow)
	_zone_tag = UITheme.label("", 20, Color.WHITE, UITheme.semi_font())
	_zone_tag.top_level = true
	_zone_tag.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 5
	_zone_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.02, 0.03, 0.07, 0.92)
	pill.set_corner_radius_all(18)
	pill.content_margin_left = 20
	pill.content_margin_right = 20
	pill.content_margin_top = 8
	pill.content_margin_bottom = 8
	_zone_tag.add_theme_stylebox_override("normal", pill)
	add_child(_zone_tag)
	Sfx.play("click", -6.0, 1.2)
	set_process(true)


func _process(delta: float) -> void:
	_grid_tick()
	if _drag == null:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drag_idle += delta
		if _drag_idle > 0.25:
			# the button is up and no release came (let go outside the window): put it down
			_drag_idle = 0.0
			_end_drag()
			_grab = {}
			return
	else:
		_drag_idle = 0.0
	var m := get_global_mouse_position()
	var before := _drag.global_position
	_drag.global_position = before.lerp(m, 1.0 - exp(-30.0 * delta))
	# It leans the way it is being pulled.
	_drag_vx = lerpf(_drag_vx, (_drag.global_position.x - before.x) / maxf(delta, 0.001), 1.0 - exp(-12.0 * delta))
	_drag.rotation = clampf(_drag_vx * 0.00022, -0.16, 0.16)
	var zone := _zone_at(m)
	var rect := _zone_rect(zone)
	var data := {"card": _grab["card"], "from": _grab["from"]}
	var ok := zone != "" and _can_drop(zone, data)
	_drag_to = zone if ok else ""
	var from := str(_grab["from"])
	var same := zone != "" and (zone == from or (zone == "main" and from == "extra"))
	_zone_glow.visible = zone != "" and not same
	_zone_tag.visible = _zone_glow.visible
	if _zone_glow.visible:
		var colr := Color(0.35, 0.95, 0.55) if ok else Color(1.0, 0.4, 0.4)
		var zs := UITheme.panel_box(Color(colr, 0.07), 14, Color(colr, 0.95))
		zs.set_border_width_all(3)
		_zone_glow.add_theme_stylebox_override("panel", zs)
		_zone_glow.global_position = rect.position
		_zone_glow.size = rect.size
		_zone_tag.text = Loc.t(_drop_words(zone, from, ok))
		_zone_tag.add_theme_color_override("font_color", colr.lightened(0.5))
		_zone_tag.reset_size()
		_zone_tag.global_position = Vector2(rect.position.x + (rect.size.x - _zone_tag.size.x) / 2.0, rect.end.y - _zone_tag.size.y - 16.0)


func _drop_words(zone: String, from: String, ok: bool) -> String:
	if not ok:
		if zone == "side":
			return "The Side Deck cannot take it"
		return "No more copies of this card can go in"
	match zone:
		"col":
			return "Let go to take it out of the deck"
		"side":
			return "Let go to put it in the Side Deck"
	return "Let go to move it to the Main Deck" if from == "side" else "Let go to add it to your deck"


## Which side of the screen is the pointer over?
func _zone_at(m: Vector2) -> String:
	if _cp != null and _cp.get_global_rect().has_point(m):
		return "col"
	if _dp != null and _dp.get_global_rect().has_point(m):
		if _side_head != null and is_instance_valid(_side_head) and m.y >= _side_head.global_position.y - 8.0:
			return "side"
		return "main"
	return ""


func _zone_rect(zone: String) -> Rect2:
	if zone == "col":
		return _cp.get_global_rect()
	if zone == "":
		return Rect2()
	var r := _dp.get_global_rect()
	if _side_head != null and is_instance_valid(_side_head):
		var cut := clampf(_side_head.global_position.y - 8.0, r.position.y + 60.0, r.end.y - 60.0)
		if zone == "side":
			return Rect2(r.position.x, cut, r.size.x, r.end.y - cut)
		return Rect2(r.position.x, r.position.y, r.size.x, cut - r.position.y)
	return r


func _end_drag() -> void:
	var card := _drag
	var zone := _drag_to
	var data := {"card": _grab["card"], "from": _grab["from"]}
	var src = _grab.get("src")
	var was = _grab.get("was")
	_drag = null
	_drag_to = ""
	if _zone_glow != null and is_instance_valid(_zone_glow):
		_zone_glow.queue_free()
	if _zone_tag != null and is_instance_valid(_zone_tag):
		_zone_tag.queue_free()
	if src is Control and is_instance_valid(src) and was is Color:
		(src as Control).modulate = was
	var tw := card.create_tween().set_parallel()
	if zone != "":
		# It lands: a quick drop into the panel, and the deck redraws with the card in place.
		tw.tween_property(card, "scale", Vector2(0.42, 0.42), 0.11)
		tw.tween_property(card, "modulate:a", 0.0, 0.11)
		_drop(zone, data)
	else:
		# Nowhere to go: back where it came from.
		var home := (src as Control).get_global_rect().get_center() if (src is Control and is_instance_valid(src)) else card.global_position
		tw.tween_property(card, "global_position", home, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "scale", Vector2(0.45, 0.45), 0.16)
		tw.tween_property(card, "rotation", 0.0, 0.1)
		tw.tween_property(card, "modulate:a", 0.0, 0.16).set_delay(0.06)
	tw.chain().tween_callback(card.queue_free)


func _can_drop(zone: String, data: Variant) -> bool:
	if not (data is Dictionary and (data as Dictionary).has("card")):
		return false
	var id := int(data["card"])
	var from := str(data["from"])
	match zone:
		"col":
			return from != "col"
		"side":
			return (from == "col" and Collection.can_add(id, true, true)) or (from == "main" and Collection.side.size() < Collection.SIDE_MAX)
	return (from == "col" and Collection.can_add(id, false, true)) or from == "side"


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
	var lack := Collection.missing_count()
	var warns: Array = []
	if not bad.is_empty():
		var parts := []
		for x in bad:
			parts.append("%s (%d, max %d)" % [x[0], x[1], x[2]])
		warns.append(Loc.t("Not allowed by the Forbidden/Limited list: ") + ", ".join(parts))
	if lack > 0:
		var names := []
		for m in Collection.missing_cards():
			var short := int(m[1]) - int(m[2])
			names.append(str(CardData.get_card(int(m[0])).get("name", "")) + ("" if short == 1 else " x%d" % short))
		warns.append((Loc.t("You don't have 1 card of this deck yet: %s.") if lack == 1 else Loc.t("You don't have %d cards of this deck yet: %s.") % [lack, "%s"]) % ", ".join(names) + " " + Loc.t("It can be dueled with once you have them."))
	_warn.visible = not warns.is_empty()
	_warn.text = "\n".join(warns)
	_admin_fill.visible = Saves.admin and lack > 0
	if _admin_fill.visible:
		_admin_fill.text = "  " + (Loc.t("Admin: add the missing card") if lack == 1 else Loc.t("Admin: add the %d missing cards") % lack) + "  "
	_count.add_theme_color_override("font_color", Color.WHITE if ok else UITheme.DANGER)
	var using: bool = Collection.active == "custom"
	if lack > 0:
		_use_btn.text = "  " + (Loc.t("1 card missing") if lack == 1 else Loc.t("%d cards missing") % lack) + "  "
	else:
		_use_btn.text = "  ✓ Using this deck  " if using and ok else "  Duel with this deck  "
	_use_btn.disabled = not ok


func _show(id: int) -> void:
	var d := CardData.get_card(id)
	_detail_tex.texture = Cards.get_face(id, true)
	Foil.apply(_detail_tex, CardData.rarity(id), id)
	_detail_name.text = str(d.get("name", ""))
	var lines := []
	if CardData.is_original(id):
		lines.append(Loc.t("CROSSROADS ORIGINAL  ·  %s  ·  This card only exists in this game.") % CardData.set_code(id))
	if d["kind"] == "monster":
		lines.append(Loc.t("Level %d  ·  %s  ·  %s") % [int(d.get("level", 0)), d.get("attribute", ""), d.get("race", "")])
		lines.append(Loc.t("ATK %s   DEF %s") % [CardData.stat_text(d.get("atk", 0)), CardData.stat_text(d.get("def", 0))])
		var note := str(CardEffects.of(str(d.get("name", ""))).get("note", ""))
		# (The note is in English: in Spanish the card's own text below says the same, in Spanish.)
		if note != "" and not (Loc.lang() == "es" and CardText.spanish(str(d.get("name", ""))) != ""):
			lines.append(Loc.t("IN THIS GAME: ") + note)
	lines.append(CardText.shown(str(d.get("name", "")), str(d.get("desc", d.get("text", "")))))
	lines.append(Loc.t("You own %d.") % Collection.count(id) + "   " + Loc.t(Foil.NAMES[CardData.rarity(id)]))
	if Collection.banlist and Collection.limit(id) < 3:
		lines.append(Loc.t(["Forbidden: cannot be used.", "Limited: 1 copy per deck.", "Semi-Limited: 2 copies per deck."][Collection.limit(id)]))
	_detail_text.text = "\n\n".join(lines)
	var peek := -1 if int(_pin.get("id", -1)) == id else id
	if peek != _peek:
		_peek = peek
		_refresh_actions()


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


## Cards you got since you last opened the deck builder wear a NEW tag for one visit.
## (The first time, everything you already own counts as seen.)
static var _seen_at_open := {}


static func is_new_card(id: int) -> bool:
	return not _seen_at_open.is_empty() and not _seen_at_open.has(id) and Collection.count(id) > 0


static func _note_seen(init_only := false) -> void:
	var seen: Dictionary = Collection.record.get("seen", {})
	if seen.is_empty() or not init_only:
		for id in Collection.owned:
			if int(Collection.owned[id]) > 0:
				seen[int(id)] = true
		Collection.record["seen"] = seen
		Collection.save()


func _close() -> void:
	_note_seen()
	Collection._apply_active()
	if not Collection.deck_ok() and Collection.active == "custom":
		Router.toast(Loc.t("Your deck needs %d to %d cards, so %s is back in use") % [Collection.MAIN_MIN, Collection.MAIN_MAX, CardData.deck_name(Collection.fallback_deck())])
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()


## Does what was typed find this card? Its English or Spanish name, or its text in either
## language, whatever language the game is in (0.59.0).
func _found(id: int, d: Dictionary) -> bool:
	var nm := str(d.get("name", ""))
	if _search_f != "" and CardSearch.matches(id, nm, _search_f):
		return true
	var en := str(d.get("desc", d.get("text", "")))
	if en.to_lower().contains(_search):
		return true
	var es := CardText.spanish(nm)
	return es != "" and es.to_lower().contains(_search)


## The lock on a card you don't have yet: a padlock drawn in a dark round badge.
class _LockTag:
	extends Control

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 24.0, Color(0.02, 0.03, 0.08, 0.78))
		draw_arc(c, 24.0, 0, TAU, 40, Color(1, 1, 1, 0.25), 2.0, true)
		var body := Rect2(c + Vector2(-10, -3), Vector2(20, 15))
		draw_arc(c + Vector2(0, -4), 7.0, PI, TAU, 16, Color(1, 1, 1, 0.9), 3.0, true)
		draw_line(c + Vector2(-7, -4), c + Vector2(-7, -2), Color(1, 1, 1, 0.9), 3.0)
		draw_line(c + Vector2(7, -4), c + Vector2(7, -2), Color(1, 1, 1, 0.9), 3.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.92)
		sb.set_corner_radius_all(3)
		draw_style_box(sb, body)
		draw_circle(body.get_center() + Vector2(0, -1), 2.2, Color(0.02, 0.03, 0.08))


## An empty card place in an empty deck: a dashed outline with a plus.
class _GhostSlot:
	extends Control
	var fade := 1.0
	var col := Color.WHITE

	func _draw() -> void:
		var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
		var c := Color(col, 0.42 * fade)
		var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		for i in 4:
			draw_dashed_line(pts[i], pts[i + 1], c, 2.0, 6.0, true)
		draw_rect(r.grow(-3), Color(col, 0.05 * fade))
		var m := size / 2.0
		draw_line(m + Vector2(-8, 0), m + Vector2(8, 0), c, 2.5)
		draw_line(m + Vector2(0, -8), m + Vector2(0, 8), c, 2.5)
