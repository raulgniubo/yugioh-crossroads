class_name CharacterSelect
extends Control
## Free Duel setup: pick who you play as (yourself or any duelist) and who you face.
## Tap a slot (YOU / OPPONENT) at the top, then pick from the roster below.

signal start(config: Dictionary)
signal closed

var _me := "player"
var _opp := "kaiba"
var _picking := "opp"
var _era := ""
var _difficulty := 1
var _my_deck := "yugi"
var _grid: GridContainer
var _slots := {}
var _tabs: Array[Button] = []
var _diff_btns: Array[Button] = []
var _deck_pick: OptionButton
var _deck_keys: Array = []
var _info: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cfg: Dictionary = Router.duel_config
	_me = cfg.get("player_char", "player")
	_opp = cfg.get("opponent", "kaiba")
	_difficulty = int(cfg.get("difficulty", 1))
	_my_deck = cfg.get("player_deck", "yugi")
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.05, 0.98)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var header := UITheme.label("FREE DUEL", 60, Color.WHITE, UITheme.title_font())
	header.position = Vector2(80, 44)
	add_child(header)
	var hint := UITheme.label("Tap YOU or OPPONENT, then pick a duelist", 20, UITheme.TEXT_DIM)
	hint.position = Vector2(84, 116)
	add_child(hint)
	_build_slots()
	_build_tabs()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 470)
	scroll.size = Vector2(1180, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	_build_controls()
	_refresh_all()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


# ------------------------------------------------------------------ slots

func _build_slots() -> void:
	for side in ["me", "opp"]:
		var b := Button.new()
		b.flat = true
		b.clip_contents = true
		b.size = Vector2(520, 230)
		b.position = Vector2(80 if side == "me" else 700, 170)
		b.pressed.connect(func():
			_picking = side
			_refresh_all())
		add_child(b)
		var pt := TextureRect.new()
		pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pt)
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color(0, 0, 0, 0.85), Color(0, 0, 0, 0.0)])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		var shade := TextureRect.new()
		shade.texture = gt
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(shade)
		var tag := UITheme.label("", 18, UITheme.ACCENT, UITheme.semi_font())
		tag.position = Vector2(22, 18)
		b.add_child(tag)
		var name_l := UITheme.label("", 46, Color.WHITE, UITheme.title_font())
		name_l.position = Vector2(20, 120)
		b.add_child(name_l)
		var sub := UITheme.label("", 18, UITheme.TEXT_DIM)
		sub.position = Vector2(22, 180)
		b.add_child(sub)
		_slots[side] = {"button": b, "portrait": pt, "name": name_l, "sub": sub, "tag": tag}
	var vs := UITheme.label("VS", 64, Color.WHITE, UITheme.title_font())
	vs.position = Vector2(608, 236)
	vs.add_theme_color_override("font_shadow_color", Color(UITheme.ACCENT, 0.7))
	vs.add_theme_constant_override("shadow_outline_size", 18)
	add_child(vs)


func _refresh_slots() -> void:
	for side in _slots:
		var key: String = _me if side == "me" else _opp
		var sl: Dictionary = _slots[side]
		var info := Portraits.info(key)
		sl["portrait"].texture = Portraits.get_portrait(key)
		sl["name"].text = str(info.get("name", "")).to_upper()
		var deck_key: String = _my_deck if side == "me" else str(Characters.get_char(key).get("deck", ""))
		sl["sub"].text = "%s  ·  %s Deck" % [info.get("era", ""), CardData.deck_name(deck_key)]
		var active: bool = side == _picking
		var col: Color = info.get("color", UITheme.ACCENT)
		var sb := UITheme.button_box(Color(0.03, 0.05, 0.09, 1), col if active else Color(1, 1, 1, 0.12), 22)
		sb.set_border_width_all(4 if active else 1)
		sb.set_content_margin_all(0)
		for st in ["normal", "hover", "pressed", "focus"]:
			sl["button"].add_theme_stylebox_override(st, sb)
		sl["tag"].text = ("YOU" if side == "me" else "OPPONENT") + ("   ◀ choosing" if active else "")


# ------------------------------------------------------------------ roster

func _build_tabs() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(80, 418)
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var tabs := [["", "ALL"]]
	for e in Characters.ERAS:
		tabs.append([e, e.to_upper()])
	for t in tabs:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		var era: String = t[0]
		b.pressed.connect(func():
			_era = era
			_refresh_all())
		row.add_child(b)
		_tabs.append(b)


func _refresh_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var keys: Array = []
	if _picking == "me":
		keys.append("player")
	for k in Characters.ORDER:
		if _era == "" or Characters.DATA[k]["era"] == _era:
			keys.append(k)
	var i := 0
	for key in keys:
		var card := _roster_card(key)
		_grid.add_child(card)
		card.modulate.a = 0.0
		create_tween().tween_property(card, "modulate:a", 1.0, 0.15).set_delay(i * 0.012)
		i += 1


func _roster_card(key: String) -> Control:
	var info := Portraits.info(key)
	var ok := key == "player" or Characters.available(key)
	var b := Button.new()
	b.custom_minimum_size = Vector2(184, 170)
	b.clip_contents = true
	b.flat = true
	var chosen := (key == _me and _picking == "me") or (key == _opp and _picking == "opp")
	var col: Color = info.get("color", UITheme.ACCENT)
	for st in ["normal", "hover", "pressed", "focus"]:
		var lit: bool = chosen or st == "hover"
		var sb := UITheme.button_box(Color(0.05, 0.08, 0.13, 1), col if lit else Color(1, 1, 1, 0.06), 14)
		sb.set_border_width_all(3 if lit else 1)
		sb.set_content_margin_all(0)
		b.add_theme_stylebox_override(st, sb)
	var pt := TextureRect.new()
	pt.texture = Portraits.get_portrait(key)
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pt)
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.72)
	band.anchor_top = 1.0
	band.anchor_right = 1.0
	band.anchor_bottom = 1.0
	band.offset_top = -40
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(band)
	var n := UITheme.label(("YOU" if key == "player" else str(info.get("short", ""))).to_upper(), 24, Color.WHITE, UITheme.title_font())
	n.position = Vector2(12, 4)
	band.add_child(n)
	var stripe := ColorRect.new()
	stripe.color = col
	stripe.size = Vector2(184, 3)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(stripe)
	if not ok:
		pt.modulate = Color(0.35, 0.35, 0.4)
		var lock := UITheme.label("Needs card database", 14, UITheme.TEXT_DIM)
		lock.position = Vector2(10, 10)
		b.add_child(lock)
	b.pressed.connect(func():
		if not ok:
			Router.toast("Download the full card database to unlock %s" % info.get("short", ""))
			return
		_choose(key))
	b.mouse_entered.connect(func():
		b.pivot_offset = b.size / 2.0
		create_tween().tween_property(b, "scale", Vector2(1.05, 1.05), 0.1))
	b.mouse_exited.connect(func():
		create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
	return b


func _choose(key: String) -> void:
	if _picking == "me":
		_me = key
		if key != "player":
			_my_deck = Characters.get_char(key)["deck"]
		_picking = "opp"
	else:
		_opp = key
	Sfx.play("card", -6.0)
	_refresh_all()


# ------------------------------------------------------------------ controls

func _build_controls() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.96), 22, Color(UITheme.ACCENT, 0.3)))
	panel.position = Vector2(1320, 170)
	panel.custom_minimum_size = Vector2(540, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	_info = UITheme.label("", 20, UITheme.TEXT)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(500, 0)
	v.add_child(_info)
	v.add_child(UITheme.label("YOUR DECK", 16, UITheme.ACCENT, UITheme.semi_font()))
	_deck_pick = OptionButton.new()
	_deck_pick.item_selected.connect(func(i):
		_my_deck = _deck_keys[i]
		_refresh_slots())
	v.add_child(_deck_pick)
	v.add_child(UITheme.label("DIFFICULTY", 16, UITheme.ACCENT, UITheme.semi_font()))
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	v.add_child(drow)
	for i in 3:
		var db := Button.new()
		db.text = ["Easy", "Normal", "Hard"][i]
		db.toggle_mode = true
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		db.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		db.pressed.connect(func():
			_difficulty = i
			_refresh_all())
		drow.add_child(db)
		_diff_btns.append(db)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(close)
	row.add_child(back)
	var go := Button.new()
	go.text = "DUEL!"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size = Vector2(0, 64)
	go.add_theme_font_size_override("font_size", 32)
	go.pressed.connect(func():
		start.emit({"player_char": _me, "opponent": _opp, "player_deck": _my_deck, "difficulty": _difficulty}))
	row.add_child(go)


func _refresh_all() -> void:
	_refresh_slots()
	_refresh_grid()
	for i in _tabs.size():
		var era: String = "" if i == 0 else Characters.ERAS[i - 1]
		_tabs[i].set_pressed_no_signal(era == _era)
	for i in _diff_btns.size():
		_diff_btns[i].set_pressed_no_signal(i == _difficulty)
	_deck_pick.clear()
	_deck_keys.clear()
	for k in Characters.ORDER:
		var deck: String = Characters.DATA[k]["deck"]
		if CardData.has_deck(deck) and not _deck_keys.has(deck):
			_deck_keys.append(deck)
			_deck_pick.add_item("%s  (%s)" % [CardData.deck_name(deck), Characters.DATA[k]["short"]])
	_deck_pick.select(maxi(0, _deck_keys.find(_my_deck)))
	var o := Characters.get_char(_opp)
	var notes := ["Easy: relaxed and makes mistakes.", "Normal: plays sensibly and attacks when it can.",
			"Hard: thinks ahead, brings a tuned deck and starts with one extra card."]
	_info.text = "%s plays the %s Deck on the %s.\n\n%s" % [o.get("short", ""), CardData.deck_name(o.get("deck", "")),
			FieldThemes.resolve("auto", _opp)["name"], notes[_difficulty]]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
