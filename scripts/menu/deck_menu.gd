class_name DeckMenu
extends Control
## My Decks: everything you can duel with, in one place. The decks you built (five slots) and
## the ready-made decks on your shelf. Pick the one to duel with, edit, rename, empty a slot, or
## copy a ready-made deck into a slot to make your own version of it. Opens from anywhere.

signal closed

var _list: VBoxContainer
var _rows: Array = []            # [{button, entry}]
var _sel := {}                   # {"type": "slot" | "ready", "i": int, "key": String}
var _dp: Label
var _name: Label
var _rename: LineEdit
var _info: Label
var _status: Label
var _actions: HBoxContainer
var _grid: GridContainer
var _confirm_clear := false
var _picker: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(MenuBackdrop.new())
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 70)
	m.add_theme_constant_override("margin_top", 40)
	m.add_theme_constant_override("margin_bottom", 36)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	m.add_child(root)
	# Header.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	root.add_child(head)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", 0)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tb)
	tb.add_child(UITheme.label("MY DECKS", 54, Color.WHITE, UITheme.title_font()))
	tb.add_child(UITheme.label("The deck marked IN USE is the one you duel with in the city, in the story and at the Academy.", 20, UITheme.TEXT_DIM))
	var purse := PanelContainer.new()
	purse.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.08, 0.02, 0.9), 16, Color(UITheme.GOLD, 0.8)))
	purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(purse)
	_dp = UITheme.label(Loc.t("%d DP") % Collection.dp, 30, UITheme.GOLD, UITheme.title_font())
	purse.add_child(_dp)
	var done := Button.new()
	done.text = "  Done  "
	done.add_theme_font_size_override("font_size", 24)
	done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	done.custom_minimum_size = Vector2(0, 58)
	done.pressed.connect(_close)
	head.add_child(done)
	# Body: the shelf on the left, the chosen deck on the right.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(540, 0)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.follow_focus = true
	body.add_child(left_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(_list)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.065, 0.11, 0.92), 20, Color(UITheme.ACCENT, 0.25)))
	body.add_child(panel)
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(pm)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	pm.add_child(right)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 16)
	right.add_child(name_row)
	_name = UITheme.label("", 44, Color.WHITE, UITheme.title_font())
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.clip_text = true
	name_row.add_child(_name)
	_rename = LineEdit.new()
	_rename.placeholder_text = Loc.t("New name, then Enter")
	_rename.custom_minimum_size = Vector2(330, 50)
	_rename.max_length = 24
	_rename.add_theme_font_size_override("font_size", 22)
	_rename.text_submitted.connect(_do_rename)
	name_row.add_child(_rename)
	_info = UITheme.label("", 22, UITheme.TEXT, UITheme.semi_font())
	right.add_child(_info)
	_status = UITheme.label("", 20, UITheme.TEXT_DIM)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_status)
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 12)
	right.add_child(_actions)
	var line := ColorRect.new()
	line.color = Color(UITheme.ACCENT, 0.3)
	line.custom_minimum_size = Vector2(0, 2)
	right.add_child(line)
	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(grid_scroll)
	_grid = GridContainer.new()
	_grid.columns = 9
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	grid_scroll.add_child(_grid)
	root.add_child(UITheme.label("More ready-made decks are sold at the card shop counter. Booster packs add single cards to your collection.", 18, UITheme.TEXT_DIM))
	# Start on the deck in use.
	if Collection.active == "custom":
		_sel = {"type": "slot", "i": Collection.slot, "key": ""}
	else:
		_sel = {"type": "ready", "i": -1, "key": Collection.active_deck()}
	_rebuild()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _in_use(entry: Dictionary) -> bool:
	if entry["type"] == "slot":
		return Collection.active == "custom" and Collection.active_deck() == "custom" and int(entry["i"]) == Collection.slot
	return Collection.active_deck() == str(entry["key"])


func _slot_data(i: int) -> Dictionary:
	if i == Collection.slot:
		return {"name": Collection.deck_name, "main": Collection.main, "extra": Collection.extra, "side": Collection.side}
	return Collection.slots[i]


func _rebuild() -> void:
	_dp.text = Loc.t("%d DP") % Collection.dp
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_rows.clear()
	_list.add_child(UITheme.label("DECKS YOU BUILT", 18, UITheme.ACCENT, UITheme.semi_font()))
	for i in Collection.SLOTS:
		var s := _slot_data(i)
		var n: int = (s.get("main", []) as Array).size()
		var sub := Loc.t("Empty slot") if Collection.slot_empty(i) else Loc.t("%d cards") % n
		if not Collection.slot_empty(i) and not Collection.slot_ok(i):
			sub += "  ·  " + Loc.t("needs %d to %d") % [Collection.MAIN_MIN, Collection.MAIN_MAX]
		_add_row({"type": "slot", "i": i, "key": ""}, str(s.get("name", "Deck %d" % (i + 1))), sub, UITheme.ACCENT, Collection.slot_empty(i))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	_list.add_child(gap)
	_list.add_child(UITheme.label("READY-MADE DECKS", 18, UITheme.GOLD, UITheme.semi_font()))
	for key in Collection.decks_owned:
		if not CardData.has_deck(str(key)):
			continue
		var e := Collection.deck_info(str(key))
		var sub2 := Loc.t("Starter deck") if e["kind"] == "starter" else (Loc.t("%s's deck") % Loc.t(str(e["owner"])) if str(e["owner"]) != "" else Loc.t("Theme deck"))
		_add_row({"type": "ready", "i": -1, "key": str(key)}, Loc.t(str(e["name"])), sub2, e["color"], false)
	_show()
	for r in _rows:
		if r["entry"] == _sel:
			(r["button"] as Button).grab_focus.call_deferred()


func _add_row(entry: Dictionary, title: String, sub: String, col: Color, dim: bool) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 78)
	b.toggle_mode = true
	b.button_pressed = entry == _sel
	b.clip_contents = true
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	h.offset_right = -16
	h.add_theme_constant_override("separation", 14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var chip := ColorRect.new()
	chip.color = Color(col, 0.35 if dim else 0.95)
	chip.custom_minimum_size = Vector2(6, 46)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(chip)
	# The deck's best monster, peeking out like the top card of the box.
	var ace := _ace_of(entry)
	var thumb := TextureRect.new()
	thumb.texture = Cards.get_face(ace) if ace > 0 else Cards.get_back()
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_SCALE
	thumb.custom_minimum_size = Vector2(44, 64)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.pivot_offset = Vector2(22, 32)
	thumb.rotation = -0.07
	thumb.modulate = Color(1, 1, 1, 0.35 if dim else 1.0)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(thumb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var picked: bool = entry == _sel
	var t := UITheme.label(title, 26, Color(0.02, 0.07, 0.1) if picked else Color(1, 1, 1, 0.5 if dim else 1.0), UITheme.semi_font())
	t.clip_text = true
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var s := UITheme.label(sub, 17, Color(0.03, 0.14, 0.18, 0.9) if picked else UITheme.TEXT_DIM)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(s)
	if _in_use(entry):
		var tag := UITheme.label(Loc.t("IN USE"), 18, Color("06121c"), UITheme.title_font())
		var tp := PanelContainer.new()
		tp.add_theme_stylebox_override("panel", UITheme.panel_box(UITheme.GOLD, 10, UITheme.GOLD))
		tp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tp.add_child(tag)
		h.add_child(tp)
	b.pressed.connect(func():
		_sel = entry
		_confirm_clear = false
		Sfx.play("click")
		_rebuild())
	_list.add_child(b)
	_rows.append({"button": b, "entry": entry})


func _ace_of(entry: Dictionary) -> int:
	if entry["type"] != "slot":
		return Collection.deck_ace(str(entry["key"]))
	var best := 0
	var score := -1
	var lists := _cards_of(entry)
	for id in (lists[1] as Array) + (lists[0] as Array):
		var d := CardData.get_card(int(id))
		if d.get("kind", "") != "monster":
			continue
		var sc := CardData.rarity(int(id)) * 10000 + int(d.get("atk", 0))
		if sc > score:
			score = sc
			best = int(id)
	return best


func _cards_of(entry: Dictionary) -> Array:
	if entry["type"] == "slot":
		var s := _slot_data(int(entry["i"]))
		return [(s.get("main", []) as Array), (s.get("extra", []) as Array), (s.get("side", []) as Array)]
	return [Array(CardData.deck_list(str(entry["key"]))), Array(CardData.extra_list(str(entry["key"]))), []]


func _show() -> void:
	for c in _actions.get_children():
		_actions.remove_child(c)
		c.queue_free()
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var is_slot: bool = _sel["type"] == "slot"
	var lists := _cards_of(_sel)
	var main: Array = lists[0]
	var extra: Array = lists[1]
	var mons := 0
	var spells := 0
	var traps := 0
	for id in main:
		match str(CardData.get_card(int(id)).get("kind", "")):
			"monster": mons += 1
			"spell": spells += 1
			"trap": traps += 1
	_rename.visible = is_slot
	_rename.text = ""
	var using := _in_use(_sel)
	if is_slot:
		var i := int(_sel["i"])
		_name.text = str(_slot_data(i).get("name", "Deck %d" % (i + 1)))
		_name.add_theme_color_override("font_color", Color.WHITE)
	else:
		var e := Collection.deck_info(str(_sel["key"]))
		_name.text = Loc.t(str(e["name"])).to_upper()
		_name.add_theme_color_override("font_color", Color(e["color"]).lightened(0.45))
	_info.text = Loc.t("%d cards   ·   %d Monsters   ·   %d Spells   ·   %d Traps   ·   Extra Deck %d   ·   Side Deck %d") % [main.size(), mons, spells, traps, extra.size(), (lists[2] as Array).size()]
	var ok := true
	if is_slot:
		var i2 := int(_sel["i"])
		ok = Collection.slot_ok(i2)
		if Collection.slot_empty(i2):
			_status.text = Loc.t("This slot is empty. Press Edit to build a deck here, or copy a ready-made deck into it.")
		elif not ok:
			_status.text = Loc.t("Not ready to duel: a Main Deck needs %d to %d cards.") % [Collection.MAIN_MIN, Collection.MAIN_MAX]
		else:
			_status.text = Loc.t("Ready to duel.") if not using else Loc.t("You are dueling with this deck.")
		_status.add_theme_color_override("font_color", UITheme.DANGER if (not ok and not Collection.slot_empty(i2)) else UITheme.TEXT_DIM)
	else:
		var e2 := Collection.deck_info(str(_sel["key"]))
		var blurb := Loc.t(str(e2["blurb"])) if str(e2["blurb"]) != "" else ""
		_status.text = (Loc.t("You are dueling with this deck.") if using else Loc.t("Ready to duel.")) + ("   " + blurb if blurb != "" else "")
		_status.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	# Buttons.
	var use := _btn(Loc.t("✓ In use") if using else Loc.t("Duel with this deck"), true)
	use.disabled = using or not ok
	use.pressed.connect(_use)
	_actions.add_child(use)
	if is_slot:
		var edit := _btn(Loc.t("Edit"))
		edit.pressed.connect(func(): _edit(int(_sel["i"])))
		_actions.add_child(edit)
		if not Collection.slot_empty(int(_sel["i"])):
			var clear := _btn(Loc.t("Press again to empty") if _confirm_clear else Loc.t("Empty this slot"))
			clear.pressed.connect(_clear)
			_actions.add_child(clear)
	else:
		var copy := _btn(Loc.t("Make my own version"))
		copy.tooltip_text = Loc.t("Copies this deck into one of your slots so you can change its cards.")
		copy.pressed.connect(func(): _copy(str(_sel["key"])))
		_actions.add_child(copy)
	# The cards, one tile each, with how many copies.
	var counts := {}
	var order: Array = []
	for id in main + extra:
		if not counts.has(id):
			order.append(id)
		counts[id] = int(counts.get(id, 0)) + 1
	order.sort_custom(func(a, b):
		var da := CardData.get_card(int(a))
		var db := CardData.get_card(int(b))
		var ka: int = {"monster": 0, "spell": 1, "trap": 2}.get(str(da.get("kind", "")), 3) + (10 if CardData.is_extra(int(a)) else 0)
		var kb: int = {"monster": 0, "spell": 1, "trap": 2}.get(str(db.get("kind", "")), 3) + (10 if CardData.is_extra(int(b)) else 0)
		if ka != kb:
			return ka < kb
		if int(da.get("level", 0)) != int(db.get("level", 0)):
			return int(da.get("level", 0)) > int(db.get("level", 0))
		if int(da.get("atk", 0)) != int(db.get("atk", 0)):
			return int(da.get("atk", 0)) > int(db.get("atk", 0))
		return str(da.get("name", "")) < str(db.get("name", "")))
	for id in order:
		_grid.add_child(_tile(int(id), int(counts[id])))


func _tile(id: int, n: int) -> Control:
	var tr := TextureRect.new()
	tr.texture = Cards.get_face(id)
	tr.custom_minimum_size = Vector2(118, 172)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.tooltip_text = str(CardData.get_card(id).get("name", ""))
	Foil.apply(tr, CardData.rarity(id))
	if n > 1:
		var badge := PanelContainer.new()
		var bsb := UITheme.panel_box(Color(0.02, 0.04, 0.08, 0.94), 9, Color(UITheme.GOLD, 0.9))
		bsb.content_margin_left = 7
		bsb.content_margin_right = 7
		bsb.content_margin_top = 0
		bsb.content_margin_bottom = 0
		badge.add_theme_stylebox_override("panel", bsb)
		badge.position = Vector2(76, 140)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(UITheme.label("x%d" % n, 18, UITheme.GOLD, UITheme.title_font()))
		tr.add_child(badge)
	return tr


func _btn(text: String, primary := false) -> Button:
	var b := Button.new()
	b.text = "  %s  " % text
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 23)
	if primary:
		b.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.22), UITheme.GOLD, 14))
		b.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 14))
		b.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 14))
	return b


func _use() -> void:
	if _sel["type"] == "slot":
		Collection.load_slot(int(_sel["i"]))
		Collection.use_deck("custom")
		Router.toast(Loc.t("You'll duel with %s") % Collection.deck_name)
	else:
		Collection.use_deck(str(_sel["key"]))
		Router.toast(Loc.t("You'll duel with %s") % Loc.t(CardData.deck_name(str(_sel["key"]))))
	Sfx.play("coin", -6.0)
	_rebuild()


func _do_rename(text: String) -> void:
	var t := text.strip_edges()
	if t == "" or _sel["type"] != "slot":
		return
	var i := int(_sel["i"])
	if i == Collection.slot:
		Collection.deck_name = t
	else:
		Collection.slots[i]["name"] = t
	Collection.save()
	_rebuild()


func _clear() -> void:
	if not _confirm_clear:
		_confirm_clear = true
		_show()
		return
	_confirm_clear = false
	var i := int(_sel["i"])
	if i == Collection.slot:
		Collection.main = []
		Collection.extra = []
		Collection.side = []
		Collection.deck_name = "Deck %d" % (i + 1)
	else:
		Collection.slots[i] = {"name": "Deck %d" % (i + 1), "main": [], "extra": [], "side": []}
	Collection.save()
	if Collection.active == "custom" and i == Collection.slot:
		Collection.use_deck("echo")
		Router.toast(Loc.t("The Echo Deck is back in use"))
	_rebuild()


## Open the deck builder on a slot. The deck you duel with only changes if you say so in there.
func _edit(i: int) -> void:
	var was_slot := Collection.slot
	var was_custom := Collection.active == "custom"
	Collection.load_slot(i)
	var builder := DeckBuilder.new()
	add_child(builder)
	await builder.closed
	if was_custom and was_slot != i and not builder.picked:
		Collection.load_slot(was_slot)
	elif builder.picked:
		_sel = {"type": "slot", "i": Collection.slot, "key": ""}
	_rebuild()


## Copy a ready-made deck into a slot: the first empty one, or one you choose to overwrite.
func _copy(key: String) -> void:
	for i in Collection.SLOTS:
		if Collection.slot_empty(i):
			_copy_into(key, i)
			return
	if _picker and is_instance_valid(_picker):
		_picker.queue_free()
	var p := SidePanel.new(Loc.t("Which slot should it replace?"), 560)
	_picker = p
	for i in Collection.SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 64)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 24)
		b.text = "   %s   (%s)" % [str(_slot_data(i).get("name", "")), Loc.t("%d cards") % (_slot_data(i).get("main", []) as Array).size()]
		b.pressed.connect(func():
			p.close()
			_copy_into(key, i))
		p.body.add_child(b)
	add_child(p)


func _copy_into(key: String, i: int) -> void:
	var was_slot := Collection.slot
	var was_custom := Collection.active == "custom"
	Collection.copy_ready_to_slot(key, i)
	Router.toast(Loc.t("Copied into slot %d. Change it any way you like.") % (i + 1))
	_sel = {"type": "slot", "i": i, "key": ""}
	if was_custom and was_slot != i:
		Collection.load_slot(was_slot)
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	await tw.finished
	closed.emit()
	queue_free()
