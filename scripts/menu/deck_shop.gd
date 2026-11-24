class_name DeckShop
extends Control
## The deck counter at the card shop: ready-made decks in their boxes. Duelists' decks on one
## shelf, theme decks on the other. Buying one puts it on your shelf in My Decks and adds every
## card in it to your collection.

signal closed

var _dp: Label
var _grid: GridContainer
var _slots: Array = []           # [{button, box, entry}]
var _entries: Array = []
var _sel := -1
var _tab := 0
var _tab_btns: Array = []
var _name: Label
var _who: Label
var _blurb: Label
var _counts: Label
var _keys: HBoxContainer
var _buy: Button
var _use: Button
var _face: TextureRect
var _see_btn: Button
var _viewing := false


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(AcademyBackdrop.new(0.55, CardsGate.PICTURE, Color(1.0, 0.86, 0.5)))
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 70)
	m.add_theme_constant_override("margin_top", 40)
	m.add_theme_constant_override("margin_bottom", 36)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	m.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	root.add_child(head)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", 0)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tb)
	tb.add_child(UITheme.label("READY-MADE DECKS", 54, Color.WHITE, UITheme.title_font()))
	tb.add_child(UITheme.label("A full deck in a box. Yours to duel with right away, and every card in it joins your collection.", 20, UITheme.TEXT_DIM))
	head.add_child(UITheme.shop_sections(self, "decks"))
	UITheme.cover_3d(self)
	var purse := PanelContainer.new()
	purse.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.08, 0.02, 0.9), 16, Color(UITheme.GOLD, 0.8)))
	purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(purse)
	_dp = UITheme.label("", 34, UITheme.GOLD, UITheme.title_font())
	purse.add_child(_dp)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	root.add_child(tabs)
	for ti in 2:
		var b := Button.new()
		b.toggle_mode = true
		b.text = "  %s  " % Loc.t(["Duelists' decks", "Theme decks"][ti])
		b.add_theme_font_size_override("font_size", 24)
		b.custom_minimum_size = Vector2(0, 50)
		b.pressed.connect(func(): _show_tab(ti))
		tabs.add_child(b)
		_tab_btns.append(b)
	var hint := UITheme.label("Q / E  or  LB / RB", 16, UITheme.TEXT_DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs.add_child(hint)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 30)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(pad)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 22)
	pad.add_child(_grid)
	# The deck you are holding.
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.0824, 0.156, 0.92), 20, Color(UITheme.GOLD, 0.3)))
	body.add_child(panel)
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(pm)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	pm.add_child(right)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	right.add_child(top)
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(110, 130)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	top.add_child(_face)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 2)
	top.add_child(tv)
	_name = UITheme.label("", 40, Color.WHITE, UITheme.title_font())
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_name)
	_who = UITheme.label("", 22, UITheme.GOLD, UITheme.semi_font())
	tv.add_child(_who)
	_blurb = UITheme.label("", 21, UITheme.TEXT)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_blurb)
	_counts = UITheme.label("", 19, UITheme.TEXT_DIM, UITheme.semi_font())
	_counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_counts)
	right.add_child(UITheme.label("KEY CARDS", 18, UITheme.ACCENT, UITheme.semi_font()))
	_keys = HBoxContainer.new()
	_keys.add_theme_constant_override("separation", 10)
	right.add_child(_keys)
	# Every card in the deck (0.55.3).
	_see_btn = Button.new()
	_see_btn.custom_minimum_size = Vector2(0, 50)
	_see_btn.add_theme_font_size_override("font_size", 20)
	_see_btn.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.14), Color(UITheme.ACCENT, 0.75), 14))
	_see_btn.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.ACCENT, 0.35), Color.WHITE, 14))
	_see_btn.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.ACCENT, 0.35), Color.WHITE, 14))
	_see_btn.pressed.connect(_see_cards)
	right.add_child(_see_btn)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(sp)
	_buy = Button.new()
	_buy.custom_minimum_size = Vector2(0, 70)
	_buy.add_theme_font_size_override("font_size", 30)
	_buy.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.22), UITheme.GOLD, 16))
	_buy.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 16))
	_buy.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 16))
	_buy.pressed.connect(_do_buy)
	right.add_child(_buy)
	_use = Button.new()
	_use.custom_minimum_size = Vector2(0, 58)
	_use.add_theme_font_size_override("font_size", 24)
	_use.pressed.connect(_do_use)
	right.add_child(_use)
	var done := Button.new()
	done.text = "Leave the counter"
	done.custom_minimum_size = Vector2(0, 58)
	done.add_theme_font_size_override("font_size", 24)
	done.pressed.connect(_close)
	right.add_child(done)
	_show_tab(int(OS.get_environment("DEV_DECK_TAB")) if OS.get_environment("DEV_DECK_TAB") != "" else 0)
	if OS.get_environment("DEV_BUY_DECK") != "":
		# Dev: buy the selected deck a moment after the shop opens (to look at the reveal).
		get_tree().create_timer(1.0).timeout.connect(func():
			_select(int(OS.get_environment("DEV_BUY_DECK")))
			_do_buy())
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	if OS.has_environment("DECK_CARDS"):	# dev: open the card list of a deck on the shelf
		get_tree().create_timer(1.2).timeout.connect(func():
			_select(int(OS.get_environment("DECK_CARDS")), true)
			_see_cards())


## The window with every card in this deck.
func _see_cards() -> void:
	if _viewing or _sel < 0:
		return
	_viewing = true
	Sfx.play("click")
	var v := CardListView.new("deck", _entries[_sel])
	add_child(v)
	await v.closed
	_viewing = false
	_see_btn.grab_focus.call_deferred()


func _show_tab(t: int) -> void:
	_tab = t
	for i in _tab_btns.size():
		(_tab_btns[i] as Button).button_pressed = i == t
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_slots.clear()
	var want := "duelist" if t == 0 else "theme"
	_entries = Collection.deck_catalog().filter(func(e): return e["kind"] == want)
	# A shop inside a world sells that world's own decks: its era's duelists, and the theme decks
	# stocked there. The main menu's shop has them all.
	var here := str(Router.roam.get("district", "")) if get_tree().current_scene and "district" in get_tree().current_scene and "_npcs" in get_tree().current_scene else ""
	if here != "":
		var era_here := str(Collection.WORLD_ERA.get(here, ""))
		_entries = _entries.filter(func(e): return (e["kind"] == "duelist" and str(e["era"]) == era_here) or (e["kind"] == "theme" and Collection.theme_sold_in(str(e["key"]), here)))
	_sel = -1
	for i in _entries.size():
		_grid.add_child(_slot(i))
	if _entries.is_empty():
		_name.text = Loc.t("Needs the card database")
		_buy.disabled = true
		_use.visible = false
		return
	_select(0, true)
	(_slots[0]["button"] as Button).grab_focus.call_deferred()


func _slot(i: int) -> Control:
	var e: Dictionary = _entries[i]
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(206, 290)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var box := DeckBox.new().setup(e)
	box.size = Vector2(206, 290)
	box.owned = Collection.owns_deck(str(e["key"]))
	box.pivot_offset = Vector2(103, 145)
	b.add_child(box)
	b.pressed.connect(func(): _select(i))
	b.focus_entered.connect(func(): _select(i))
	# (Hovering no longer picks a deck: click it, and it stays picked while you move to the buttons.)
	_slots.append({"button": b, "box": box, "entry": e})
	box.modulate.a = 0.0
	box.create_tween().tween_property(box, "modulate:a", 1.0, 0.2).set_delay(0.03 * i)
	return b


func _process(delta: float) -> void:
	for i in _slots.size():
		var box: DeckBox = _slots[i]["box"]
		var on := i == _sel
		box.glow = lerpf(box.glow, 1.0 if on else 0.0, clampf(delta * 8.0, 0.0, 1.0))
		var s := lerpf(box.scale.x, 1.06 if on else 1.0, clampf(delta * 10.0, 0.0, 1.0))
		box.scale = Vector2(s, s)


func _select(i: int, quiet := false) -> void:
	if i == _sel:
		return
	_sel = i
	if not quiet:
		Sfx.play("hover", -10.0)
	var e: Dictionary = _entries[i]
	var key := str(e["key"])
	var col: Color = e["color"]
	_name.text = Loc.t(str(e["name"])).to_upper()
	_name.add_theme_color_override("font_color", col.lightened(0.45))
	var who := str(e["who"])
	_face.visible = who != "" and Avatars.has_avatar(who)
	if _face.visible:
		_face.texture = Portraits.get_portrait(who)
	if str(e["owner"]) != "":
		_who.text = Loc.t("%s's deck") % Loc.t(str(e["owner"])) + ("   ·   " + Loc.t(str(e["era"])) if str(e["era"]) != "" else "")
		_blurb.text = Loc.t("The deck %s duels with, card for card.") % Loc.t(str(e["owner"]))
	else:
		_who.text = Loc.t("Theme deck")
		_blurb.text = Loc.t(str(e["blurb"]))
	var main := CardData.deck_list(key)
	var extra := CardData.extra_list(key)
	var mons := 0
	var spells := 0
	var traps := 0
	var have := 0
	var seen := {}
	for id in main:
		match str(CardData.get_card(id).get("kind", "")):
			"monster": mons += 1
			"spell": spells += 1
			"trap": traps += 1
	for id in main + extra:
		if not seen.has(id):
			seen[id] = true
			if Collection.count(id) > 0:
				have += 1
	_counts.text = Loc.t("%d Monsters   ·   %d Spells   ·   %d Traps   ·   Extra Deck %d") % [mons, spells, traps, extra.size()] \
			+ "\n" + Loc.t("You already have %d of its %d different cards.") % [have, seen.size()]
	for c in _keys.get_children():
		_keys.remove_child(c)
		c.queue_free()
	var pool: Array = seen.keys()
	pool.sort_custom(func(a, b):
		var ra := CardData.rarity(a)
		var rb := CardData.rarity(b)
		if ra != rb:
			return ra > rb
		return int(CardData.get_card(a).get("atk", 0)) > int(CardData.get_card(b).get("atk", 0)))
	_see_btn.text = Loc.t("SEE ALL %d CARDS") % pool.size()
	for k in mini(4, pool.size()):
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(pool[k])
		tr.custom_minimum_size = Vector2(118, 172)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.tooltip_text = str(CardData.get_card(pool[k]).get("name", ""))
		Foil.apply(tr, CardData.rarity(pool[k]))
		_keys.add_child(tr)
	_refresh()


func _refresh() -> void:
	_dp.text = Loc.t("%d DP") % Collection.dp
	if _sel < 0:
		return
	var e: Dictionary = _entries[_sel]
	var key := str(e["key"])
	var mine := Collection.owns_deck(key)
	_buy.visible = not mine
	_buy.text = Loc.t("Buy  ·  %d DP") % int(e["price"])
	_buy.disabled = Collection.dp < int(e["price"])
	if _buy.disabled and not mine:
		_buy.text = Loc.t("%d DP  ·  you need %d more") % [int(e["price"]), int(e["price"]) - Collection.dp]
	if not mine and int(e.get("stage", 0)) > 0 and Unlocks.stage() < int(e.get("stage", 0)):
		# (The New Frontier decks, 0.56.0: they open with the end of the story, like their pack.)
		_buy.text = Loc.t("Locked: opens when you finish the story.")
		_buy.disabled = true
	_use.visible = mine
	var using := Collection.using_origin(key) and Collection.active_deck() == "custom"
	_use.text = Loc.t("✓ Yours. You are dueling with it.") if using else Loc.t("Yours. Duel with this deck")
	_use.disabled = using
	for s in _slots:
		(s["box"] as DeckBox).owned = Collection.owns_deck(str(s["entry"]["key"]))


func _do_buy() -> void:
	var e: Dictionary = _entries[_sel]
	var before := Collection.owned.duplicate()
	if not Collection.buy_deck(str(e["key"])):
		Router.toast("Not enough Duel Points")
		Sfx.play("blip", -6.0, 0.6)
		return
	Sfx.play("coin", -2.0)
	# The deck opens like a booster pack.
	var scene := DeckOpening.new(e, before)
	add_child(scene)
	await scene.closed
	Sfx.play("win", -8.0)
	Router.toast(Loc.t("%s is yours! Find it in My Decks.") % Loc.t(str(e["name"])))
	var box: DeckBox = _slots[_sel]["box"]
	box.scale = Vector2(1.25, 1.25)
	_refresh()
	_use.grab_focus.call_deferred()


func _do_use() -> void:
	var e: Dictionary = _entries[_sel]
	Collection.use_owned(str(e["key"]))
	Sfx.play("coin", -6.0)
	Router.toast(Loc.t("You'll duel with %s") % Loc.t(str(e["name"])))
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _viewing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_X):
		# C or X: every card in the deck you are on.
		get_viewport().set_input_as_handled()
		_see_cards()
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Q, KEY_E]) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		get_viewport().set_input_as_handled()
		Sfx.play("click")
		_show_tab(1 - _tab)


func _switch(what: String) -> void:
	UITheme.shop_swap(self, what)


func _close() -> void:
	UITheme.uncover_3d(self)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
