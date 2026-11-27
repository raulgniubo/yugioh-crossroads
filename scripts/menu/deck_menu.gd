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
var _grid: VBoxContainer       # the deck shown: Main, Extra and Side Deck, each under its own heading
var _confirm_clear := false
var _picker: Control
var _filter := "all"          # all | ready | not
var _confirm_restore := false


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(AcademyBackdrop.new(0.5, CardsGate.PICTURE, Color(1.0, 0.86, 0.5)))
	if "--decks-plan" in OS.get_cmdline_user_args():
		# (dev: the deck in use gets cards you don't have yet, Main and Extra)
		var nm := 0
		var nx := 0
		for cid in Collection.all_cards():
			var cd := CardData.get_card(int(cid))
			if Collection.count(int(cid)) > 0 or str(cd.get("kind", "")) != "monster":
				continue
			if CardData.is_extra(int(cid)) and nx < 3:
				Collection.extra.append(int(cid))
				nx += 1
			elif not CardData.is_extra(int(cid)) and nm < 4:
				Collection.main.append(int(cid))
				nm += 1
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
	var album := Button.new()
	album.text = "  " + Loc.t("Card Album") + "  "
	album.add_theme_font_size_override("font_size", 24)
	album.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	album.custom_minimum_size = Vector2(0, 58)
	album.pressed.connect(func():
		Sfx.play("click", -6.0)
		CardAlbum.open(self))
	head.add_child(album)
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
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.0824, 0.156, 0.92), 20, Color(UITheme.ACCENT, 0.25)))
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
	_grid = VBoxContainer.new()
	_grid.add_theme_constant_override("separation", 8)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.add_child(_grid)
	root.add_child(UITheme.label("More ready-made decks are sold at the card shop counter. A deck you buy is yours to change, and its original list can always be restored. Booster packs add single cards to your collection.", 18, UITheme.TEXT_DIM))
	# Start on the deck in use.
	_sel = {"type": "slot", "i": Collection.slot, "key": ""}
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
	_list.add_child(UITheme.label("YOUR DECKS", 18, UITheme.ACCENT, UITheme.semi_font()))
	# Show all of them, or only the ones that are ready to duel, or only the ones that are not.
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 8)
	_list.add_child(frow)
	var counts := {"all": Collection.slots.size(), "ready": 0, "not": 0}
	for i in Collection.slots.size():
		counts["ready" if Collection.slot_ok(i) else "not"] += 1
	for f in [["all", "All"], ["ready", "Ready"], ["not", "Not ready"]]:
		var fb := Button.new()
		fb.toggle_mode = true
		fb.button_pressed = _filter == f[0]
		fb.text = "  %s  %d  " % [Loc.t(f[1]), int(counts[f[0]])]
		fb.custom_minimum_size = Vector2(0, 40)
		fb.add_theme_font_size_override("font_size", 17)
		for st in ["pressed", "hover_pressed"]:
			fb.add_theme_stylebox_override(st, UITheme.button_box(Color(UITheme.ACCENT, 0.9), UITheme.ACCENT, 10))
		fb.add_theme_color_override("font_pressed_color", Color(0.02, 0.05, 0.08))
		fb.add_theme_color_override("font_hover_pressed_color", Color(0.02, 0.05, 0.08))
		fb.pressed.connect(func():
			_filter = f[0]
			Sfx.play("click")
			_rebuild())
		frow.add_child(fb)
	var shown := 0
	for i in Collection.slots.size():
		var s := _slot_data(i)
		var n: int = (s.get("main", []) as Array).size()
		var ok := Collection.slot_ok(i)
		if (_filter == "ready" and not ok) or (_filter == "not" and ok):
			continue
		shown += 1
		var sub := Loc.t("No cards yet") if Collection.slot_empty(i) else Loc.t("%d cards") % n
		if not ok and not Collection.slot_empty(i):
			sub += "  ·  " + Loc.t("needs %d to %d") % [Collection.MAIN_MIN, Collection.MAIN_MAX]
		var col: Color = UITheme.ACCENT
		var from := str(Collection.slots[i].get("origin", ""))
		if from != "" and CardData.has_deck(from):
			# Where it came from, and whether you have changed it since.
			var e := Collection.deck_info(from)
			col = e["color"]
			var whose := Loc.t("Starter deck") if e["kind"] == "starter" else Loc.t("A gift from Lumen") if e["kind"] == "gift" else (Loc.t("%s's deck") % Loc.t(str(e["owner"])) if str(e["owner"]) != "" else Loc.t("Theme deck"))
			sub += "  ·  " + whose + ("  ·  " + Loc.t("changed") if Collection.slot_changed(i) else "")
		_add_row({"type": "slot", "i": i, "key": ""}, str(s.get("name", "Deck %d" % (i + 1))), sub, col, Collection.slot_empty(i), 1 if ok else 2)
	if shown == 0:
		_list.add_child(UITheme.label(Loc.t("No deck here yet.") if _filter == "ready" else Loc.t("Every deck is ready."), 18, UITheme.TEXT_DIM))
	var add := Button.new()
	add.text = "+  " + Loc.t("New deck")
	add.custom_minimum_size = Vector2(0, 58)
	add.add_theme_font_size_override("font_size", 22)
	add.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.1), Color(UITheme.ACCENT, 0.6), 14))
	add.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.ACCENT, 0.24), UITheme.ACCENT, 14))
	add.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.ACCENT, 0.24), UITheme.ACCENT, 14))
	add.pressed.connect(_new_deck)
	_list.add_child(add)
	_show()
	for r in _rows:
		if r["entry"] == _sel:
			(r["button"] as Button).grab_focus.call_deferred()


## `ready`: 0 no tag, 1 READY, 2 NOT READY.
func _add_row(entry: Dictionary, title: String, sub: String, col: Color, dim: bool, ready := 0) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 78)
	b.toggle_mode = true
	b.button_pressed = entry == _sel
	UITheme.clip_safe(b)
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
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var s := UITheme.label(sub, 17, Color(0.03, 0.14, 0.18, 0.9) if picked else UITheme.TEXT_DIM)
	# (0.61.0) A long line under the name ("40 cards · Zane Truesdale's deck · changed") used to
	# push the READY tag off the end of the row. Now the line gives way (it ends in "…") and
	# the tag always has its place.
	s.clip_text = true
	s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(s)
	if ready > 0 and not _in_use(entry):
		var rc := Color("5df07a") if ready == 1 else Color("ff8a6a")
		var rtag := UITheme.label(Loc.t("READY") if ready == 1 else Loc.t("NOT READY"), 15, Color("06121c") if picked else rc, UITheme.title_font())
		var rp := PanelContainer.new()
		var rsb := UITheme.panel_box(Color(rc, 0.0), 9, Color(Color("06121c") if picked else rc, 0.75))
		rsb.set_content_margin_all(5)
		rsb.content_margin_left = 9
		rsb.content_margin_right = 9
		rp.add_theme_stylebox_override("panel", rsb)
		rp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rp.add_child(rtag)
		h.add_child(rp)
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
		_confirm_restore = false
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
			_status.text = Loc.t("This deck has no cards yet. Press Edit to build it.")
		elif not ok:
			var lack := 0
			for m in Collection._missing_in(main + extra + (lists[2] as Array)):
				lack += int(m[1]) - int(m[2])
			if main.size() < Collection.MAIN_MIN or main.size() > Collection.MAIN_MAX:
				_status.text = Loc.t("Not ready to duel: a Main Deck needs %d to %d cards.") % [Collection.MAIN_MIN, Collection.MAIN_MAX]
			else:
				_status.text = ""
			if lack > 0:
				_status.text = (_status.text + "  " if _status.text != "" else Loc.t("Not ready to duel:") + " ") + (Loc.t("1 card you don't have yet (greyed).") if lack == 1 else Loc.t("%d cards you don't have yet (greyed).") % lack)
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
			var dup := _btn(Loc.t("Duplicate"))
			dup.pressed.connect(_duplicate)
			_actions.add_child(dup)
		for mv in [[-1, "▲", "Move this deck up the list"], [1, "▼", "Move this deck down the list"]]:
			var mb := _btn(str(mv[1]))
			mb.tooltip_text = Loc.t(str(mv[2]))
			var to: int = int(_sel["i"]) + int(mv[0])
			mb.disabled = to < 0 or to >= Collection.slots.size()
			mb.pressed.connect(func(): _move(int(mv[0])))
			_actions.add_child(mb)
		if Collection.slot_changed(int(_sel["i"])):
			var back := _btn(Loc.t("Press again to restore") if _confirm_restore else Loc.t("Restore the original list"))
			back.tooltip_text = Loc.t("Puts this deck back to the list it came with. The cards you added stay in your collection.")
			back.pressed.connect(_restore)
			_actions.add_child(back)
		var clear := _btn(Loc.t("Press again to delete") if _confirm_clear else Loc.t("Delete"))
		clear.pressed.connect(_clear)
		_actions.add_child(clear)
	# The cards, one tile each, with how many copies: the Main Deck, then the Extra Deck and the
	# Side Deck under their own headings.
	var owned_left := {}
	for part in [["MAIN DECK", main, Comic.SKY], ["EXTRA DECK", extra, Color("b48cff")], ["SIDE DECK", lists[2], UITheme.GOLD]]:
		var ids: Array = part[1]
		if ids.is_empty():
			continue
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		var hl := UITheme.label(Loc.t(str(part[0])), 18, part[2], UITheme.title_font())
		head.add_child(hl)
		head.add_child(UITheme.label(str(ids.size()), 18, Color.WHITE, UITheme.semi_font()))
		var rule := ColorRect.new()
		rule.color = Color(part[2], 0.3)
		rule.custom_minimum_size = Vector2(0, 2)
		rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(rule)
		if _grid.get_child_count() > 0:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 6)
			_grid.add_child(gap)
		_grid.add_child(head)
		var g := GridContainer.new()
		g.columns = 9
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 10)
		_grid.add_child(g)
		var counts := {}
		var order: Array = []
		for id in ids:
			if not counts.has(id):
				order.append(id)
			counts[id] = int(counts.get(id, 0)) + 1
		order.sort_custom(func(a, b):
			var da := CardData.get_card(int(a))
			var db := CardData.get_card(int(b))
			var ka: int = {"monster": 0, "spell": 1, "trap": 2}.get(str(da.get("kind", "")), 3)
			var kb: int = {"monster": 0, "spell": 1, "trap": 2}.get(str(db.get("kind", "")), 3)
			if ka != kb:
				return ka < kb
			if int(da.get("level", 0)) != int(db.get("level", 0)):
				return int(da.get("level", 0)) > int(db.get("level", 0))
			if int(da.get("atk", 0)) != int(db.get("atk", 0)):
				return int(da.get("atk", 0)) > int(db.get("atk", 0))
			return str(da.get("name", "")) < str(db.get("name", "")))
		for id in order:
			# (copies you don't have yet: counted over the whole deck, Main first)
			var have: int = int(owned_left.get(id, Collection.count(int(id))))
			var n := int(counts[id])
			owned_left[id] = maxi(0, have - n)
			g.add_child(_tile(int(id), n, maxi(0, n - have) if int(id) != CardData.LUMEN else 0))


func _tile(id: int, n: int, lacking := 0) -> Control:
	var tr := TextureRect.new()
	tr.texture = Cards.get_thumb(id)
	tr.custom_minimum_size = Vector2(118, 172)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.tooltip_text = str(CardData.get_card(id).get("name", ""))
	if lacking > 0:
		# (copies you don't have yet: grey, and how many are missing)
		tr.material = AlbumSlot.gray_material()
		tr.tooltip_text += "\n" + (Loc.t("You don't have this card yet") if lacking >= n else Loc.t("Missing %d of these") % lacking)
		var miss := PanelContainer.new()
		var msb := UITheme.panel_box(Color(Comic.RED, 0.95), 9, Color.WHITE)
		msb.content_margin_left = 6
		msb.content_margin_right = 6
		msb.content_margin_top = 0
		msb.content_margin_bottom = 0
		miss.add_theme_stylebox_override("panel", msb)
		miss.position = Vector2(6, 6)
		miss.mouse_filter = Control.MOUSE_FILTER_IGNORE
		miss.add_child(UITheme.label(Loc.t("missing %d") % lacking, 14, Color.WHITE, UITheme.semi_font()))
		tr.add_child(miss)
	else:
		Foil.apply(tr, CardData.rarity(id), id)
	if n > 1:
		var badge := PanelContainer.new()
		var bsb := UITheme.panel_box(Color(0.032, 0.058, 0.125, 0.94), 9, Color(UITheme.GOLD, 0.9))
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
	var was_use := Collection.active == "custom" and i == Collection.slot
	Collection.delete_slot(i)
	if was_use:
		var now := Collection.fall_back()
		Router.toast(Loc.t("You'll duel with %s") % now if now != "" else Loc.t("None of your decks is ready: the starter list is used until one is."))
	_sel = {"type": "slot", "i": clampi(i, 0, Collection.slots.size() - 1), "key": ""}
	_filter = "all"
	Sfx.play("card", -6.0)
	_rebuild()


func _restore() -> void:
	if not _confirm_restore:
		_confirm_restore = true
		_show()
		return
	_confirm_restore = false
	Collection.restore_slot(int(_sel["i"]))
	Sfx.play("card", -4.0)
	Router.toast(Loc.t("Back to the original list"))
	_rebuild()


## A new deck at the end of your list, opened in the builder right away.
func _new_deck() -> void:
	var was_slot := Collection.slot
	var was_custom := Collection.active == "custom"
	var i := Collection.new_slot()
	_sel = {"type": "slot", "i": i, "key": ""}
	_filter = "all"
	_confirm_clear = false
	Sfx.play("card", -4.0)
	if was_custom and was_slot != i:
		Collection.load_slot(was_slot)
	_rebuild()
	_edit(i)


func _duplicate() -> void:
	var i := Collection.duplicate_slot(int(_sel["i"]))
	_sel = {"type": "slot", "i": i, "key": ""}
	_filter = "all"
	_confirm_clear = false
	Router.toast(Loc.t("Copied. Change it any way you like."))
	_rebuild()


func _move(dir: int) -> void:
	var j := Collection.move_slot(int(_sel["i"]), dir)
	_sel = {"type": "slot", "i": j, "key": ""}
	_confirm_clear = false
	Sfx.play("click")
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
