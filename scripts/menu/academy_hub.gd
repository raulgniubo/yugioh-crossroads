class_name AcademyHub
extends Control
## Duel Academy mode. Shows your dorm, this week's class duels and Friday exam, and the
## Academy Tournament bracket. Every duel is started from here and comes back here.

signal closed

const W := 1920.0
const H := 1080.0

var return_to := "res://scenes/main_menu.tscn"
var _root: Control
var _bracket: Control
var _stage: FigureStage
var _news := []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.build()
	Academy.load_data()
	# Coming back from a duel that was started here.
	if not Academy.d.get("pending", {}).is_empty() and Router.story_result != "":
		_news = Academy.resolve(Router.story_result == "won")
		Router.story_result = ""
	var dim := ColorRect.new()
	dim.color = Color(0.012, 0.02, 0.045, 0.985)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var glow := Control.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.draw.connect(func():
		var c: Color = Academy.dorm()["color"]
		for i in 6:
			glow.draw_circle(Vector2(260, 560), 520.0 - i * 70.0, Color(c.r, c.g, c.b, 0.022)))
	add_child(glow)
	_root = Control.new()
	_root.size = Vector2(W, H)
	add_child(_root)
	resized.connect(_center)
	_center()
	_build()
	if not _news.is_empty():
		_show_news.call_deferred()


func _center() -> void:
	if _root:
		_root.position = ((size - Vector2(W, H)) / 2.0).max(Vector2.ZERO)


func _clear() -> void:
	for c in _root.get_children():
		c.queue_free()
	_stage = null
	_bracket = null


func _card(pos: Vector2, sz: Vector2, border := Color(1, 1, 1, 0.08)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel_box(UITheme.PANEL, 18, border))
	p.position = pos
	p.custom_minimum_size = sz
	p.size = sz
	_root.add_child(p)
	return p


func _vbox(parent: Control, sep := 10, margin := 22) -> VBoxContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, margin)
	parent.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	m.add_child(v)
	return v


func _big_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 66)
	b.add_theme_font_override("font", UITheme.title_font())
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_stylebox_override("normal", UITheme.button_box(color.darkened(0.25), color))
	b.add_theme_stylebox_override("hover", UITheme.button_box(color, Color.WHITE))
	b.add_theme_stylebox_override("focus", UITheme.button_box(color, Color.WHITE))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(func(): Sfx.play("click"))
	return b


func _build() -> void:
	_clear()
	var dorm: Dictionary = Academy.dorm()
	var dcol: Color = dorm["color"]
	var head := UITheme.label("DUEL ACADEMY", 58, Color.WHITE, UITheme.title_font())
	head.position = Vector2(64, 28)
	_root.add_child(head)
	var bar := ColorRect.new()
	bar.color = dcol
	bar.position = Vector2(66, 98)
	bar.size = Vector2(118, 4)
	_root.add_child(bar)
	var sub_text := "Pass the entrance exam to enroll." if not Academy.enrolled() else \
		Loc.t("Week %d   ·   %s") % [int(Academy.d["week"]), Loc.t(Academy.DAYS[clampi(int(Academy.d["day"]), 0, 3)])]
	var sub := UITheme.label(sub_text, 22, UITheme.TEXT_DIM)
	sub.position = Vector2(560, 56)
	_root.add_child(sub)
	_build_you(dorm)
	_build_week()
	_build_tourney()
	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(64, 990)
	back.custom_minimum_size = Vector2(200, 58)
	back.pressed.connect(_close)
	_root.add_child(back)
	var deck := Button.new()
	deck.text = "My Deck"
	deck.position = Vector2(284, 990)
	deck.custom_minimum_size = Vector2(200, 58)
	deck.pressed.connect(func():
		var db := DeckBuilder.new()
		db.z_index = 120
		add_child(db))
	_root.add_child(deck)
	back.grab_focus.call_deferred()


# ------------------------------------------------------------------ you and your dorm

func _build_you(dorm: Dictionary) -> void:
	var dcol: Color = dorm["color"]
	var card := _card(Vector2(64, 130), Vector2(472, 840), Color(dcol.r, dcol.g, dcol.b, 0.5))
	card.clip_contents = true
	var v := _vbox(card, 8)
	var who := UITheme.label(Profile.duelist_name.to_upper(), 34, Color.WHITE, UITheme.title_font())
	v.add_child(who)
	var rank := UITheme.label(Loc.t(Academy.rank_title()).to_upper(), 24, dcol.lightened(0.25), UITheme.semi_font())
	v.add_child(rank)
	_stage = FigureStage.new(Vector2(420, 450))
	v.add_child(_stage)
	_stage.show_person("player", dcol if Academy.enrolled() else null)
	var motto := UITheme.label(str(dorm["motto"]) if Academy.enrolled() else "Not enrolled yet. The proctor is waiting in the exam hall.", 18, UITheme.TEXT_DIM)
	motto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	motto.custom_minimum_size = Vector2(420, 0)
	v.add_child(motto)
	# The ladder: three dorms, the one you are in lit up.
	var ladder := HBoxContainer.new()
	ladder.add_theme_constant_override("separation", 8)
	v.add_child(ladder)
	for i in 3:
		var dd: Dictionary = Academy.DORMS[i]
		var c: Color = dd["color"]
		var here := Academy.enrolled() and int(Academy.d["dorm"]) == i
		var reached := Academy.enrolled() and int(Academy.d["dorm"]) >= i
		var pill := PanelContainer.new()
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pill.add_theme_stylebox_override("panel", UITheme.button_box(c.darkened(0.2) if reached else Color(0.11, 0.163, 0.353), Color.WHITE if here else c.darkened(0.3), 10))
		var l := UITheme.label(str(dd["name"]), 17, Color.WHITE if reached else Color(1, 1, 1, 0.4), UITheme.semi_font())
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(0, 40)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pill.add_child(l)
		ladder.add_child(pill)
	var stats := UITheme.label(Loc.t("Class wins %d   ·   Exams passed %d   ·   Trophies %d") % [int(Academy.d.get("class_wins", 0)),
		int(Academy.d.get("exams_passed", 0)), int(Academy.d.get("trophies", 0))], 16, UITheme.TEXT_DIM)
	v.add_child(stats)
	if Academy.enrolled():
		var wear := CheckButton.new()
		wear.text = "Wear my dorm jacket"
		wear.add_theme_color_override("font_color", UITheme.TEXT)
		wear.add_theme_color_override("font_pressed_color", UITheme.TEXT)
		wear.add_theme_color_override("font_hover_color", Color.WHITE)
		wear.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		wear.button_pressed = bool(Academy.d.get("uniform", true))
		wear.toggled.connect(func(on):
			Academy.d["uniform"] = on
			Academy.save())
		v.add_child(wear)


# ------------------------------------------------------------------ this week

func _build_week() -> void:
	var t: Dictionary = Academy.today()
	var dcol: Color = Academy.dorm()["color"]
	var card := _card(Vector2(586, 130), Vector2(614, 840))
	var v := _vbox(card, 12)
	v.add_child(UITheme.label("THIS WEEK" if Academy.enrolled() else "ADMISSIONS", 18, UITheme.ACCENT, UITheme.semi_font()))
	if Academy.enrolled():
		var days := HBoxContainer.new()
		days.add_theme_constant_override("separation", 8)
		v.add_child(days)
		var day := int(Academy.d["day"])
		var log: Array = Academy.d.get("log", [])
		for i in 4:
			var tile := PanelContainer.new()
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var done := i < day
			var now := i == day
			var won := i < log.size() and bool(log[i])
			var bg := Color(0.1, 0.13, 0.2)
			if done:
				bg = Color(0.1, 0.32, 0.22) if won else Color(0.34, 0.12, 0.16)
			tile.add_theme_stylebox_override("panel", UITheme.button_box(bg, UITheme.ACCENT if now else Color(1, 1, 1, 0.1), 10))
			var tv := VBoxContainer.new()
			tile.add_child(tv)
			var dl := UITheme.label(Loc.t(Academy.DAYS[i]).to_upper(), 13, Color.WHITE if now else UITheme.TEXT_DIM, UITheme.semi_font())
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tv.add_child(dl)
			var what := "EXAM" if i == 3 else "CLASS"
			var st := UITheme.label((("WON" if won else "LOST") if done else what), 20, Color.WHITE if (done or now) else Color(1, 1, 1, 0.45), UITheme.title_font())
			st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tv.add_child(st)
			days.add_child(tile)
		var need := UITheme.label(Loc.t("Class wins this week: %d of %d needed to move up on Friday.") % [int(Academy.d["wins"]), Academy.NEED_WINS], 18,
			UITheme.GOLD if int(Academy.d["wins"]) >= Academy.NEED_WINS else UITheme.TEXT_DIM)
		need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(need)
	if Academy.d["graduated"]:
		var g := UITheme.label("You graduated at the top of Obelisk Blue. The weeks keep going if you want more duels, and the tournament is always open.", 18, UITheme.GOLD)
		g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(g)
	v.add_child(UITheme.label(Loc.t(str(t["title"])).to_upper(), 30, Color.WHITE, UITheme.title_font()))
	v.add_child(_versus(t))
	var blurb := {"entrance": "Beat the proctor's test deck to earn your place. Lose and you can retake it right away.",
		"class": "A regular class duel. A win counts toward this week's grade and pays Duel Points.",
		"exam": "The Friday exam. Win it with enough class wins this week and you move up a dorm."}
	var bl := UITheme.label(str(blurb.get(t["kind"], "")), 18, UITheme.TEXT_DIM)
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(bl)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var go := _big_button({"entrance": "TAKE THE ENTRANCE EXAM", "class": "START CLASS DUEL", "exam": "TAKE THE EXAM"}.get(t["kind"], "DUEL"), dcol if Academy.enrolled() else UITheme.ACCENT_2)
	go.pressed.connect(func(): _launch(t))
	v.add_child(go)


func _versus(t: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.054, 0.0996, 0.277), 14, Color(1, 1, 1, 0.14)))
	frame.custom_minimum_size = Vector2(190, 230)
	frame.clip_contents = true
	var tex := TextureRect.new()
	tex.texture = Portraits.get_portrait(str(t["char"]))
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(tex)
	row.add_child(frame)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	row.add_child(v)
	v.add_child(UITheme.label("OPPONENT", 15, UITheme.DANGER, UITheme.semi_font()))
	var nm := UITheme.label(Loc.t(str(t["name"])), 34, Color.WHITE, UITheme.title_font())
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)
	v.add_child(UITheme.label(Loc.t("%s Deck") % CardData.deck_name(str(t["deck"])), 20, UITheme.TEXT_DIM))
	var diff: String = ["Easy", "Normal", "Hard", "Expert"][clampi(int(t["difficulty"]), 0, 3)]
	var dc: Color = [Color("5affa0"), Color("7cc4ff"), Color("ffb030"), Color("ff4d6d")][clampi(int(t["difficulty"]), 0, 3)]
	v.add_child(UITheme.label(Loc.t(diff).to_upper(), 22, dc, UITheme.title_font()))
	v.add_child(UITheme.label(Loc.t("Your deck: %s") % CardData.deck_name(Collection.active_deck()), 17, UITheme.TEXT_DIM))
	return row


func _launch(t: Dictionary) -> void:
	Academy.start(t)
	var cfg := Academy.duel_config(t)
	cfg["return_to"] = return_to
	cfg["continue_label"] = Loc.t("Back to the Academy")
	Router.duel_config = cfg
	Router.menu_open = "academy" if return_to == Router.MAIN_MENU else ""
	Sfx.play("summon", -4.0)
	Router.go(Router.DUEL)


# ------------------------------------------------------------------ tournament

func _build_tourney() -> void:
	var card := _card(Vector2(1224, 130), Vector2(632, 840), Color(1, 0.82, 0.4, 0.28))
	var v := _vbox(card, 10)
	v.add_child(UITheme.label("ACADEMY TOURNAMENT", 18, UITheme.GOLD, UITheme.semi_font()))
	if not Academy.tourney_open():
		var l := UITheme.label("Eight duelists, three rounds, one trophy. Open to Ra Yellow and above: earn your promotion first.", 20, UITheme.TEXT_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		var lock := UITheme.label("LOCKED", 44, Color(1, 1, 1, 0.25), UITheme.title_font())
		v.add_child(lock)
		return
	var t: Dictionary = Academy.d.get("tourney", {})
	if t.is_empty():
		var l2 := UITheme.label("Eight duelists, three rounds, one trophy. Lose once and you are out. The champion takes 1500 Duel Points.", 20, UITheme.TEXT_DIM)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l2)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
		var enter := _big_button("ENTER THE TOURNAMENT", Color("c98a1e"))
		enter.pressed.connect(func():
			Academy.tourney_new()
			Sfx.play("gong")
			_build())
		v.add_child(enter)
		return
	_bracket = Control.new()
	_bracket.custom_minimum_size = Vector2(586, 560)
	_bracket.draw.connect(_draw_bracket)
	v.add_child(_bracket)
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp2)
	if Academy.tourney_active():
		var nx := Academy.tourney_today()
		var go := _big_button(Loc.t("%s  VS  %s") % [Loc.t(Academy.tourney_round_name(int(t["round"]))).to_upper(), str(nx["name"]).to_upper()], Color("c98a1e"))
		go.pressed.connect(func(): _launch(nx))
		v.add_child(go)
	else:
		var res := UITheme.label("You are the champion!" if t.get("won", false) else "Knocked out this time.", 22, UITheme.GOLD if t.get("won", false) else UITheme.TEXT_DIM)
		v.add_child(res)
		var again := _big_button("NEW TOURNAMENT", Color("c98a1e"))
		again.pressed.connect(func():
			Academy.tourney_new()
			Sfx.play("gong")
			_build())
		v.add_child(again)


func _slot_name(s: Dictionary) -> String:
	if s["char"] == "player":
		return Profile.duelist_name
	var short := str(Characters.get_char(str(s["char"])).get("short", ""))
	return short if short != "" and short != "Student" else Loc.t(str(s["name"]))


func _draw_bracket() -> void:
	var t: Dictionary = Academy.d.get("tourney", {})
	if t.is_empty():
		return
	var font := UITheme.semi_font()
	var rounds: Array = t["rounds"]
	var col_w := 148.0
	var box := Vector2(132, 44)
	var total_h := _bracket.size.y
	var prev_centers := []
	for r in 4:
		var n := 8 >> r
		var centers := []
		for i in n:
			var y := total_h * (float(i) + 0.5) / float(n)
			var x := r * col_w
			centers.append(Vector2(x, y))
			var known: bool = rounds.size() > r and i < rounds[r].size()
			var s: Dictionary = rounds[r][i] if known else {}
			var me: bool = known and s["char"] == "player"
			var lost := false
			if known and rounds.size() > r + 1 and r < 3:
				var adv: Dictionary = rounds[r + 1][i >> 1] if (i >> 1) < rounds[r + 1].size() else {}
				lost = not adv.is_empty() and adv["char"] != s["char"]
			var rect := Rect2(Vector2(x, y - box.y / 2.0), box)
			var bg := Color(0.08, 0.11, 0.18)
			if me:
				bg = Color(0.06, 0.3, 0.34)
			if r == 3 and known:
				bg = Color(0.45, 0.32, 0.06)
			_bracket.draw_style_box(UITheme.button_box(bg, UITheme.ACCENT if me else (UITheme.GOLD if r == 3 else Color(1, 1, 1, 0.14)), 8), rect)
			var text := _slot_name(s) if known else "?"
			if r == 3 and not known:
				text = Loc.t("CHAMPION")
			var c := Color(1, 1, 1, 0.35) if lost or not known else Color.WHITE
			_bracket.draw_string(font, rect.position + Vector2(9, 29), text, HORIZONTAL_ALIGNMENT_LEFT, box.x - 14, 15, c)
			if r > 0:
				for k in 2:
					var from: Vector2 = prev_centers[i * 2 + k] + Vector2(box.x, 0)
					var mid := Vector2(x - 8, from.y)
					_bracket.draw_polyline(PackedVector2Array([from, mid, Vector2(x - 8, y), Vector2(x, y)]), Color(1, 1, 1, 0.22), 2.0)
		prev_centers = centers


# ------------------------------------------------------------------ results

func _show_news() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var box := PanelContainer.new()
	var dcol: Color = Academy.dorm()["color"]
	box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.062, 0.109, 0.294, 0.98), 22, dcol))
	box.custom_minimum_size = Vector2(820, 0)
	shade.add_child(box)
	var v := _vbox(box, 14, 40)
	var good: bool = Academy.last_good
	var head := UITheme.label(Loc.t(str(_news[0])), 54, UITheme.GOLD if good else UITheme.DANGER, UITheme.title_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(head)
	for i in range(1, _news.size()):
		var l := UITheme.label(Loc.t(str(_news[i])), 24 if i == 1 else 28, UITheme.TEXT if i == 1 else UITheme.ACCENT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	var ok := _big_button("CONTINUE", dcol)
	v.add_child(ok)
	ok.pressed.connect(func(): shade.queue_free())
	Sfx.play("rare" if good else "error")
	if good:
		Sfx.play("cheer", -6.0)
	await get_tree().process_frame
	box.position = (size - box.size) / 2.0
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ok.grab_focus()
	_news = []


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_close()
