class_name CampusGate
extends Control
## The door to the Academy story (0.65.0): continue, new game, load a save. A new game asks how
## you want to play (the Academy's own cards, or your whole collection). The Academy mode from
## before this build is still here, at the bottom, as "Classic Academy".

signal closed
signal classic

var _box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(MenuBackdrop.new(0.985, Color("d9342b").lerp(Color.WHITE, 0.15)))
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	_box.custom_minimum_size = Vector2(980, 0)
	c.add_child(_box)
	Campus.reload()
	_home()


func _clear() -> void:
	for n in _box.get_children():
		n.queue_free()


func _title(text: String, sub: String) -> void:
	var t := UITheme.label(Loc.t(text).to_upper(), 82, Color.WHITE, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var s := UITheme.label(Loc.t(sub), 24, UITheme.TEXT_DIM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(s)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	_box.add_child(gap)


func _button(text: String, big: bool, act: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(620, 84 if big else 62)
	b.add_theme_font_size_override("font_size", 32 if big else 25)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if big:
		UITheme.paint_button(b, Color("c8322a"))
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		act.call())
	_box.add_child(b)
	return b


func _home() -> void:
	_clear()
	_title("Duel Academy", "A school year on the island: Red, Yellow, Blue, and then the Pro League.")
	var first: Button
	if Campus.started():
		# Where the game in this save is.
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.06, 0.13, 0.9), 18, Color(Campus.DORM_COLORS[Campus.dorm()], 0.7)))
		card.custom_minimum_size = Vector2(820, 0)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_box.add_child(card)
		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 26)
		for side in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 16)
		card.add_child(m)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		m.add_child(v)
		v.add_child(UITheme.label(Campus.summary(), 30, Color.WHITE, UITheme.semi_font()))
		var g := Campus.golden()
		var pos: Dictionary = CampusProgress.position()
		var line := str(g.get("text", "")) if g.has("chapter") else Loc.t(str(g.get("text", "")))
		for ch in CampusData.CHAPTERS:
			if str(ch["id"]) == str(pos.get("chapter", "")):
				line = "%s: %s" % [Loc.t(str(ch["title"])), Loc.t(str(ch["name"]))]
		v.add_child(UITheme.label(line, 23, UITheme.GOLD))
		v.add_child(UITheme.label(Loc.t("Playing with the Academy's own cards") if Campus.own_cards() else Loc.t("Playing with your own decks"), 19, UITheme.TEXT_DIM))
		first = _button("▶  " + Loc.t("Continue"), true, func():
			Campus.go())
		_button(Loc.t("New game"), false, _ask_new)
	else:
		first = _button("▶  " + Loc.t("New game"), true, _pick_mode)
	_button(Loc.t("Load a save"), false, func():
		var sm := SaveMenu.open(self, false)
		sm.closed.connect(func():
			Campus.reload()
			_home()))
	_button(Loc.t("Back"), false, _close)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	_box.add_child(gap)
	# The mode from before: still playable, with your progress as it was.
	var old := Button.new()
	old.text = Loc.t("Classic Academy (the mode from before)  ·  going away soon")
	old.flat = true
	old.add_theme_font_size_override("font_size", 19)
	old.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	old.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	old.pressed.connect(func():
		classic.emit()
		queue_free())
	_box.add_child(old)
	first.grab_focus.call_deferred()


func _ask_new() -> void:
	_clear()
	_title("New game?", "This save already has an Academy game. A new one starts it over from the ferry. Save first (Esc on the island, or Load a save here) if you want to keep the old one in a slot.")
	var yes := _button(Loc.t("Start over"), true, _pick_mode)
	_button(Loc.t("Keep my game"), false, _home)
	yes.grab_focus.call_deferred()


func _mode_card(row: HBoxContainer, title: String, tag: String, lines: Array, col: Color, how: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(470, 430)
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.04, 0.06, 0.13, 0.92), 20, Color(col, 0.6)))
	b.add_theme_stylebox_override("hover", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.96), 20, col))
	b.add_theme_stylebox_override("focus", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.96), 20, col))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.09, 0.13, 0.25, 0.96), 20, col))
	row.add_child(b)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	b.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	v.add_child(UITheme.label(Loc.t(tag).to_upper(), 17, col, UITheme.semi_font()))
	v.add_child(UITheme.label(Loc.t(title).to_upper(), 44, Color.WHITE, UITheme.title_font()))
	for t in lines:
		var l := UITheme.label("•  " + Loc.t(str(t)), 20, Color(0.9, 0.93, 1.0))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(410, 0)
		v.add_child(l)
	b.pressed.connect(func():
		Sfx.play("gong", -8.0)
		Campus.new_game(how)
		Campus.go())
	return b


func _pick_mode() -> void:
	_clear()
	_title("How do you want to play?", "You can change this later from the agenda on the island.")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(row)
	var a := _mode_card(row, "Academy", "Recommended", [
		"You arrive as a new student with a novice deck you pick on the ferry.",
		"Every card you add is earned or bought on the island.",
		"Rivals grow with the story, so the first chapters are a fair fight.",
		"What you earn joins your own collection when you graduate."], UITheme.GOLD, "academia")
	_mode_card(row, "Free", "Your own cards", [
		"You bring your own decks and your whole collection.",
		"Build a deck in any other world and use it here.",
		"Every rival comes one step stronger to keep it a challenge."], Color("7cc4ff"), "libre")
	_button(Loc.t("Back"), false, _home)
	a.grab_focus.call_deferred()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
