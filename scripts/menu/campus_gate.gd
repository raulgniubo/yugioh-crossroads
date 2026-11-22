class_name CampusGate
extends Control
## The door to the Academy story (0.65.0): continue, new game, load a save. A new game asks how
## you want to play (the Academy's own cards, or your whole collection). The Academy mode from
## before this build is still here, at the bottom, as "Classic Academy".

signal closed
signal classic

var _box: VBoxContainer          # a page in the middle of the screen (a question, the two ways to play)
var _left: VBoxContainer         # the title page, down the left side over the picture
var _mid: CenterContainer
var _back: AcademyBackdrop
var _foot: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_back = AcademyBackdrop.new()
	add_child(_back)
	var lm := MarginContainer.new()
	lm.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	lm.add_theme_constant_override("margin_left", 96)
	lm.add_theme_constant_override("margin_top", 70)
	lm.add_theme_constant_override("margin_bottom", 54)
	add_child(lm)
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 12)
	_left.custom_minimum_size = Vector2(780, 0)
	_left.alignment = BoxContainer.ALIGNMENT_CENTER
	lm.add_child(_left)
	_mid = CenterContainer.new()
	_mid.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mid)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	_box.custom_minimum_size = Vector2(980, 0)
	_mid.add_child(_box)
	Campus.reload()
	_home()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _clear() -> void:
	for n in _box.get_children():
		n.queue_free()
	for n in _left.get_children():
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


## A glass button for the row under Continue: dark, a thin line in the dorm's color, brighter
## when the pointer or the pad is on it.
func _glass(text: String, col: Color, act: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 14, col.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.1, 0.14, 0.26, 0.95), 14, col.lightened(0.4)))
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		act.call())
	return b


## The three dorms as one bar: the one you are in is lit and a little taller.
func _dorm_bar(mine: int) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for i in 3:
		var seg := ColorRect.new()
		var on := i == mine
		seg.color = Campus.DORM_COLORS[i] if on else Color(Campus.DORM_COLORS[i], 0.38)
		seg.custom_minimum_size = Vector2(150 if on else 96, 8 if on else 5)
		seg.size_flags_vertical = Control.SIZE_SHRINK_END
		h.add_child(seg)
	return h


## The chapters of the act you are in, as a row of pips: done, the one you are on, still ahead.
func _act_row(pos_chapter: String, col: Color) -> Control:
	var act := 0
	var at := -1
	for i in CampusData.CHAPTERS.size():
		if str(CampusData.CHAPTERS[i]["id"]) == pos_chapter:
			act = int(CampusData.CHAPTERS[i]["act"])
			at = i
	var open: Array = CampusProgress.unlocked()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	var tag := UITheme.label(Loc.t("PROLOGUE") if act == 0 else Loc.t("ACT %d") % act, 15, UITheme.TEXT_DIM, UITheme.semi_font())
	h.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(6, 0)
	h.add_child(gap)
	var n := 0
	var mine := 0
	for i in CampusData.CHAPTERS.size():
		var ch: Dictionary = CampusData.CHAPTERS[i]
		if int(ch["act"]) != act:
			continue
		n += 1
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(34, 10)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(5)
		if i == at:
			sb.bg_color = Color.WHITE
			mine = n
		elif i < at or (at < 0 and open.has(str(ch["id"]))):
			sb.bg_color = col.lightened(0.15)
		else:
			sb.bg_color = Color(1, 1, 1, 0.16)
		pip.add_theme_stylebox_override("panel", sb)
		h.add_child(pip)
	if mine > 0 and act > 0:
		h.add_child(UITheme.label("  " + Loc.t("%d of %d") % [mine, n], 15, UITheme.TEXT_DIM, UITheme.semi_font()))
	return h


func _home() -> void:
	_clear()
	_back.shade_to(0.0)
	var d := Campus.dorm() if Campus.started() else 0
	var col: Color = Campus.DORM_COLORS[d]
	var over := UITheme.label(Loc.t("A STORY OF ITS OWN"), 19, UITheme.GOLD, UITheme.semi_font())
	_left.add_child(over)
	var t := UITheme.label(Loc.t("Duel Academy").to_upper(), 104, Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 5)
	t.add_theme_constant_override("shadow_outline_size", 10)
	_left.add_child(t)
	_left.add_child(_dorm_bar(d if Campus.started() else -1))
	var sub := UITheme.label(Loc.t("A school year on the island: Red, Yellow, Blue, and then the Pro League."), 23, Color(0.9, 0.93, 1.0, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(760, 0)
	_left.add_child(sub)
	var gap0 := Control.new()
	gap0.custom_minimum_size = Vector2(0, 14)
	_left.add_child(gap0)
	var first: Button
	if Campus.started():
		# Where the game in this save is: the dorm's crest, the day, the chapter and how far along
		# the act it is.
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.82), 20, Color(col, 0.75)))
		card.custom_minimum_size = Vector2(780, 0)
		_left.add_child(card)
		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 24)
		for side in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 18)
		card.add_child(m)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		m.add_child(row)
		var crest := DormCrest.new(d, 104.0)
		crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(crest)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		v.add_child(UITheme.label(Loc.t(Campus.DORM_NAMES[d]).to_upper(), 38, col.lightened(0.45), UITheme.title_font()))
		v.add_child(UITheme.label("%s %d   ·   %d %s" % [Loc.t("Day"), Campus.day(), Campus.merits(), Loc.t("merits")], 22, Color.WHITE, UITheme.semi_font()))
		var g := Campus.golden()
		var pos: Dictionary = CampusProgress.position()
		var line := str(g.get("text", "")) if g.has("chapter") else Loc.t(str(g.get("text", "")))
		var cid := str(g.get("chapter", g.get("told", "")))      # (story told: the row of the last act, all lit)
		for ch in CampusData.CHAPTERS:
			if str(ch["id"]) == str(pos.get("chapter", "")):
				line = "%s: %s" % [Loc.t(str(ch["title"])), Loc.t(str(ch["name"]))]
				cid = str(ch["id"])
		var where := UITheme.label(line, 23, UITheme.GOLD, UITheme.semi_font())
		where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		where.custom_minimum_size = Vector2(560, 0)
		v.add_child(where)
		var gap1 := Control.new()
		gap1.custom_minimum_size = Vector2(0, 4)
		v.add_child(gap1)
		v.add_child(_act_row(cid, col))
		v.add_child(UITheme.label(Loc.t("Playing with the Academy's own cards") if Campus.own_cards() else Loc.t("Playing with your own decks"), 17, UITheme.TEXT_DIM))
		first = Button.new()
		first.text = "▶   " + Loc.t("Continue")
		first.custom_minimum_size = Vector2(780, 92)
		first.add_theme_font_size_override("font_size", 38)
		UITheme.paint_button(first, col.darkened(0.08) if d != 1 else col)
		first.pressed.connect(func():
			Sfx.play("click", -6.0)
			Campus.go())
		_left.add_child(first)
	else:
		var hello := UITheme.label(Loc.t("You come in on the morning ferry with a novice deck. Everything else you earn on the island."), 22, Color(0.95, 0.96, 1.0))
		hello.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hello.custom_minimum_size = Vector2(760, 0)
		_left.add_child(hello)
		first = Button.new()
		first.text = "▶   " + Loc.t("New game")
		first.custom_minimum_size = Vector2(780, 92)
		first.add_theme_font_size_override("font_size", 38)
		UITheme.paint_button(first, Color("c8322a"))
		first.pressed.connect(func():
			Sfx.play("click", -6.0)
			_pick_mode())
		_left.add_child(first)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	row2.custom_minimum_size = Vector2(780, 0)
	_left.add_child(row2)
	if Campus.started():
		row2.add_child(_glass(Loc.t("New game"), col, _ask_new))
	row2.add_child(_glass(Loc.t("Load a save"), col, func():
		var sm := SaveMenu.open(self, false, true)
		sm.closed.connect(func():
			Campus.reload()
			_home())))
	row2.add_child(_glass(Loc.t("Back"), col, _close))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	_left.add_child(gap)
	# The mode from before: still playable, with your progress as it was.
	var old := Button.new()
	old.text = Loc.t("Classic Academy (the mode from before)  ·  going away soon")
	old.flat = true
	old.add_theme_font_size_override("font_size", 18)
	old.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 0.7))
	old.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	old.pressed.connect(func():
		classic.emit()
		queue_free())
	_left.add_child(old)
	first.grab_focus.call_deferred()
	# The words come in from the left, one after the other.
	var k := 0
	for n in _left.get_children():
		var c := n as Control
		c.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.05 * k)
		tw.tween_property(c, "modulate:a", 1.0, 0.25)
		k += 1


func _ask_new() -> void:
	_clear()
	_back.shade_to(0.72)
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
	_back.shade_to(0.72)
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
