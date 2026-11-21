class_name CampusLife
extends Node
## Life on the island in the Academy story (0.65.0): the small card that always says what day it
## is, how many merits you have and what comes next; the agenda it opens into (the story mission,
## the week, the silver missions, the people); your bed, the mission board and, in admin mode,
## the panel that lets you jump anywhere. RoamScene adds one whenever Campus.on.

var scene                       # RoamScene
var _ui: CanvasLayer
var _chip: PanelContainer
var _when: Label
var _merit: Label
var _bar: ProgressBar
var _next: Label
var _hint: Label
var _feed_box: VBoxContainer
var _agenda: SidePanel
var _sig := ""
var _tick := 0.0
var _story := false             # a chapter is being told right now (no bed, no board)


func _ready() -> void:
	_story = str(Router.roam.get("story", "")) != ""
	_ui = CanvasLayer.new()
	_ui.layer = 3
	add_child(_ui)
	_build_chip()
	if "--campus-agenda" in OS.get_cmdline_user_args():
		# Dev: the agenda opens by itself a few seconds in, for a picture of it.
		get_tree().create_timer(9.0).timeout.connect(open_agenda)
	if not _story:
		_build_spots.call_deferred()
		# Back from a duel, or just arrived: where you stand is where "continue" brings you back.
		_note.call_deferred()
		var t := Timer.new()
		t.wait_time = 8.0
		t.autostart = true
		t.timeout.connect(_note)
		add_child(t)
	_refresh()


# ------------------------------------------------------------------ the small card

func _build_chip() -> void:
	_chip = PanelContainer.new()
	var box := UITheme.panel_box(Color(0.032, 0.0532, 0.116, 0.82), 14, Color(Campus.DORM_COLORS[Campus.dorm()], 0.75))
	box.content_margin_left = 16
	box.content_margin_right = 18
	box.content_margin_top = 8
	box.content_margin_bottom = 9
	box.border_width_left = 6
	_chip.add_theme_stylebox_override("panel", box)
	_chip.anchor_left = 1.0
	_chip.anchor_right = 1.0
	_chip.offset_left = -404
	_chip.offset_right = -36
	_chip.offset_top = 372
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_chip)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.add_child(v)
	_when = UITheme.label("", 19, UITheme.GOLD, UITheme.semi_font())
	v.add_child(_when)
	_merit = UITheme.label("", 18, Color.WHITE, UITheme.semi_font())
	v.add_child(_merit)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.GOLD
	fill.set_corner_radius_all(3)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.14)
	back.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", back)
	v.add_child(_bar)
	_next = UITheme.label("", 17, Color(0.9, 0.94, 1.0))
	_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next.custom_minimum_size = Vector2(330, 0)
	v.add_child(_next)
	_hint = UITheme.label("", 14, UITheme.TEXT_DIM)
	v.add_child(_hint)
	# What you just earned floats up beside the card.
	_feed_box = VBoxContainer.new()
	_feed_box.anchor_left = 1.0
	_feed_box.anchor_right = 1.0
	_feed_box.offset_left = -404
	_feed_box.offset_right = -36
	_feed_box.offset_top = 520
	_feed_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_feed_box)


## What the card's last line says: the one thing that makes most sense to do now.
func next_line() -> String:
	if _story:
		return ""
	var g := Campus.golden()
	if g.has("chapter"):
		return "▸ " + Loc.t("Ready when you are:") + " " + str(g["text"])
	for m in CampusData.MISSIONS:
		if not Campus.mission_open(m):
			continue
		var st := Campus.mission(str(m["id"]))
		if bool(st["done"]) and not bool(st["paid"]):
			return "▸ " + Loc.t("A mission is finished. Collect it at the board in your room.")
	if Campus.part() == 2:
		return "▸ " + Loc.t("It is night. Sleep in your room to start a new day.")
	if Campus.cup_on() and Campus.cup_place(Campus.dorm()) > 1:
		return "▸ " + Campus.cup_line()
	if Campus.merits_to_go() == 0:
		return "▸ " + Loc.t("You have the merits for the promotion exam.")
	return "▸ " + Loc.t("Free time: duel students, work on the missions.")


func _refresh() -> void:
	var need := int(Campus.NEED[Campus.dorm()])
	var sig := "%d|%d|%d|%d|%s|%s|%s" % [Campus.day(), Campus.part(), Campus.merits(), Campus.dorm(), next_line(), Loc.lang(), str(Campus.cup_points())]
	if sig == _sig:
		return
	_sig = sig
	_when.text = "%s  ·  %s %d" % [Campus.when_text(), Loc.t("Day"), Campus.day()]
	_merit.text = "%s  %d / %d" % [Loc.t("Merits"), Campus.merits(), need]
	_bar.max_value = need
	_bar.value = mini(need, Campus.merits())
	var nl := next_line()
	_next.text = nl
	_next.visible = nl != ""
	_hint.text = Pad.keys(Loc.t("N  agenda"))
	(_chip.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(Campus.DORM_COLORS[Campus.dorm()], 0.75)


func _process(delta: float) -> void:
	_tick += delta
	if _tick > 0.5:
		_tick = 0.0
		_refresh()
	# The card steps aside while a scene has the camera, or you are in a conversation.
	var hide: bool = _story and scene.story != null and bool(scene.story._cut)
	if scene._talking:
		hide = true
	# ... and while the agenda is open: the panel opens right where the card sits.
	if _agenda != null and is_instance_valid(_agenda):
		hide = true
	_chip.visible = not hide
	while not Campus.feed.is_empty():
		var f: Array = Campus.feed.pop_front()
		_pop(int(f[0]), str(f[1]), str(f[2]) if f.size() > 2 else "")


## Something earned, in the corner: merits by default; "cup" = points for a dorm in the Dorm Cup;
## "note" = a plain line.
func _pop(n: int, why: String, kind := "") -> void:
	var text := "%s%d %s%s" % ["+" if n > 0 else "", n, Loc.t("merits"), ("  ·  " + Loc.t(why)) if why != "" else ""]
	var col := UITheme.GOLD
	if kind == "cup":
		text = "%s  ·  +%d %s" % [Loc.t("Dorm Cup"), n, Loc.t(why)]
		col = Campus.DORM_COLORS[Campus.dorm()].lightened(0.35)
	elif kind == "note":
		text = Loc.t(why)
	var l := UITheme.label(text, 19, col, UITheme.semi_font())
	l.modulate.a = 0.0
	_feed_box.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
	Sfx.play("coin", -10.0)
	_sig = ""


func _note() -> void:
	if scene == null or scene._player == null or _story:
		return
	var pp: Vector3 = scene._outside_pos if scene._inside != "" else scene._player.position
	Campus.note(pp, scene._yaw)


# ------------------------------------------------------------------ your room

func _build_spots() -> void:
	if scene == null:
		return
	var room := str(Campus.ROOM[Campus.dorm()])
	if not AcademyRooms.ROOMS.has(room):
		return
	var o: Vector3 = AcademyRooms.ROOMS[room]["at"]
	scene._spots.append({"pos": o + Vector3(-1.5, 0, -0.5), "range": 1.7, "label": "Rest or sleep (your bed)", "action": _bed})
	scene._spots.append({"pos": o + Vector3(2.3, 0, -1.2), "range": 1.6, "label": "Look at the mission board", "action": func(): open_agenda()})
	# The board itself: cork, a frame, a gold card and a few silver ones.
	var c: CityBuilder = scene.city
	var wall := o + Vector3(2.92, 1.55, -1.2)
	var frame := c.box(Vector3(0.06, 1.0, 1.5), wall, c.mat(Color(0.36, 0.24, 0.15), 0.8), false)
	frame.name = "MissionBoard"
	c.box(Vector3(0.05, 0.88, 1.38), wall + Vector3(-0.02, 0, 0), c.mat(Color(0.72, 0.56, 0.36), 0.95), false)
	c.box(Vector3(0.02, 0.3, 0.22), wall + Vector3(-0.05, 0.2, -0.42), c.glow_mat(UITheme.GOLD, 0.9), false)
	for k in 3:
		c.box(Vector3(0.02, 0.26, 0.2), wall + Vector3(-0.05, 0.2 - (k % 2) * 0.42, -0.05 + k * 0.3), c.mat(Color(0.86, 0.88, 0.92), 0.5), false)


func _bed() -> void:
	if _agenda != null and is_instance_valid(_agenda):
		return
	var p := SidePanel.new("Your bed", 620)
	scene._ui.add_child(p)
	_agenda = p
	var l := UITheme.label(Loc.t("It is %s. Nothing on the island runs out while you are busy: the day only moves when you say so.") % Loc.t(Campus.PARTS[Campus.part()]).to_lower(), 21, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(l)
	if Campus.part() < 2:
		var rest := Button.new()
		rest.text = Loc.t("Rest until the %s") % Loc.t(Campus.PARTS[Campus.part() + 1]).to_lower()
		rest.custom_minimum_size = Vector2(0, 64)
		rest.add_theme_font_size_override("font_size", 23)
		rest.pressed.connect(func():
			p.close()
			_turn_time(false))
		p.body.add_child(rest)
		rest.grab_focus.call_deferred()
	var sl := Button.new()
	sl.text = Loc.t("Sleep until tomorrow morning")
	sl.custom_minimum_size = Vector2(0, 64)
	sl.add_theme_font_size_override("font_size", 23)
	sl.pressed.connect(func():
		p.close()
		_turn_time(true))
	p.body.add_child(sl)
	if Campus.part() >= 2:
		sl.grab_focus.call_deferred()
	var no := Button.new()
	no.text = Loc.t("Not yet")
	no.custom_minimum_size = Vector2(0, 54)
	no.pressed.connect(p.close)
	p.body.add_child(no)


## The day moves: a fade, the new hour on screen, the sky changed, and the game saved.
func _turn_time(night_over: bool) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(shade)
	var tw := create_tween()
	tw.tween_property(shade, "color:a", 1.0, 0.7)
	await tw.finished
	if night_over:
		Campus.sleep()
		Campus.mission_count("sleep")
	else:
		Campus.pass_time()
	scene.city.apply_tod(Campus.tod())
	Router.roam["tod"] = Campus.tod()
	var l := UITheme.label("%s  ·  %s %d" % [Campus.when_text(), Loc.t("Day"), Campus.day()], 44, Color.WHITE, UITheme.title_font())
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shade.add_child(l)
	Sfx.play("sparkle", -8.0)
	await get_tree().create_timer(1.6).timeout
	var tw2 := create_tween()
	tw2.tween_property(shade, "color:a", 0.0, 0.7)
	tw2.parallel().tween_property(l, "modulate:a", 0.0, 0.4)
	await tw2.finished
	shade.queue_free()
	_sig = ""
	_note()
	Saves.note_place("campus", {"district": "academy"})
	Saves.autosave(true)


# ------------------------------------------------------------------ the agenda

func _unhandled_input(event: InputEvent) -> void:
	var want := false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		want = true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_DOWN:
		want = true
	if not want:
		return
	if _agenda != null and is_instance_valid(_agenda):
		_agenda.close()
		get_viewport().set_input_as_handled()
		return
	if scene._talking or (scene.story != null and scene.story._cut) or scene._pause != null:
		return
	open_agenda()
	get_viewport().set_input_as_handled()


func _head(p: SidePanel, text: String) -> void:
	var h := UITheme.label(Loc.t(text).to_upper(), 17, UITheme.GOLD, UITheme.semi_font())
	p.body.add_child(h)


func _line(p: SidePanel, text: String, size := 20, col := Color.WHITE) -> Label:
	var l := UITheme.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(l)
	return l


func open_agenda() -> void:
	if _agenda != null and is_instance_valid(_agenda):
		_agenda.close()
	var p := SidePanel.new("Agenda", 760)
	scene._ui.add_child(p)
	_agenda = p
	p.closed.connect(func(): _agenda = null)
	Sfx.play("panel", -8.0)
	# ---- today
	_head(p, "Today")
	_line(p, "%s  ·  %s %d  ·  %s" % [Campus.when_text(), Loc.t("Day"), Campus.day(), Loc.t(Campus.DORM_NAMES[Campus.dorm()])], 24)
	# Until classes, exams and the Cup open (chapter 2), the day is free time: say that, not the plan.
	var plan_now := str(CampusData.WEEK_PLAN[Campus.weekday()][Campus.part()])
	if not CampusData.CLASSES_OPEN and Campus.part() < 2:
		plan_now = "Free time"
	_line(p, Loc.t(plan_now), 19, UITheme.TEXT_DIM)
	# ---- the story
	_head(p, "Story")
	var g := Campus.golden()
	_line(p, str(g.get("text", "")) if g.has("chapter") else Loc.t(str(g.get("text", ""))), 23, UITheme.GOLD)
	if str(g.get("sub", "")) != "":
		_line(p, Loc.t(str(g["sub"])), 18, UITheme.TEXT_DIM)
	if g.has("chapter") and not _story:
		var go := Button.new()
		go.text = "▶  " + Loc.t("Start this chapter")
		go.custom_minimum_size = Vector2(0, 62)
		go.add_theme_font_size_override("font_size", 23)
		go.pressed.connect(func():
			_note()
			StoryDirector.begin(str(g["chapter"])))
		p.body.add_child(go)
		go.grab_focus.call_deferred()
	# ---- the Dorm Cup
	if Campus.cup_on():
		_head(p, "Dorm Cup")
		var pts := Campus.cup_points()
		for place in [1, 2, 3]:
			for d in 3:
				if Campus.cup_place(d) != place:
					continue
				var mine := d == Campus.dorm()
				var row := _line(p, "%d.   %s   %d%s" % [place, Loc.t(Campus.DORM_NAMES[d]), int(pts[d]), ("   ◀ " + Loc.t("your dorm")) if mine else ""], 21 if mine else 19, (Campus.DORM_COLORS[d] as Color).lightened(0.3))
				if mine:
					row.add_theme_font_override("font", UITheme.semi_font())
		_line(p, Loc.t("Every duel you win against a student of another dorm scores for yours. Stronger duelists are worth more. Each dorm also scores a little every day."), 16, UITheme.TEXT_DIM)
		_line(p, Loc.t("If Red finishes last this term, the Red dorm closes."), 16, UITheme.TEXT_DIM)
	# ---- merits and moving up
	_head(p, "Moving up")
	var need := int(Campus.NEED[Campus.dorm()])
	if Campus.dorm() < 2:
		_line(p, Loc.t("To sit the promotion exam to %s you need three things:") % Loc.t(Campus.DORM_NAMES[Campus.dorm() + 1]), 19)
		_line(p, "%s  %s  (%d / %d)" % ["✔" if Campus.merits() >= need else "○", Loc.t("Merits"), Campus.merits(), need], 19)
		_line(p, "○  " + Loc.t("The chapter that closes this act"), 19)
		_line(p, "○  " + Loc.t("The exam itself, on a Friday of your choice"), 19)
	else:
		_line(p, Loc.t("You are in the top dorm."), 19)
	# ---- the week
	_head(p, "Your week")
	for d in 7:
		var plan: Array = CampusData.WEEK_PLAN[d]
		var today := d == Campus.weekday()
		var parts: Array = []
		for k in 3:
			if k == 0 or str(plan[k]) != str(plan[k - 1]):
				parts.append(Loc.t(str(plan[k])))
		var row := _line(p, "%s  %s:  %s" % ["▸" if today else "   ", Loc.t(Campus.WEEK[d]), "  ·  ".join(parts.slice(0, 2))], 18, Color.WHITE if today else UITheme.TEXT_DIM)
		if today:
			row.add_theme_font_override("font", UITheme.semi_font())
	if not CampusData.CLASSES_OPEN:
		_line(p, Loc.t("Classes and the promotion exams open with the next chapters. Until then every day is free time."), 16, UITheme.TEXT_DIM)
	# ---- silver missions
	_head(p, "Missions")
	var any := false
	for m in CampusData.MISSIONS:
		if not Campus.mission_open(m):
			continue
		any = true
		var st := Campus.mission(str(m["id"]))
		var done := bool(st["done"])
		var paid := bool(st["paid"])
		var mark := "✔" if paid else ("★" if done else "○")
		_line(p, "%s  %s   (+%d %s)" % [mark, Loc.t(str(m["name"])), int(m["merits"]), Loc.t("merits")], 20, UITheme.TEXT_DIM if paid else Color.WHITE)
		_line(p, "     %s   %d / %d" % [Loc.t(str(m["text"])), mini(int(st["n"]), int(m["need"])), int(m["need"])], 17, UITheme.TEXT_DIM)
		if done and not paid:
			var claim := Button.new()
			claim.text = Loc.t("Collect: +%d merits") % int(m["merits"])
			claim.custom_minimum_size = Vector2(0, 52)
			var mid := str(m["id"])
			claim.pressed.connect(func():
				Campus.mission_claim(mid)
				open_agenda())
			p.body.add_child(claim)
	if not any:
		_line(p, Loc.t("The board fills up after your first day."), 18, UITheme.TEXT_DIM)
	# ---- people
	var bonds: Dictionary = Campus.v("bonds", {})
	if not bonds.is_empty():
		_head(p, "People")
		for who in bonds:
			var info := Characters.get_char(str(who))
			_line(p, "%s   %s" % [Loc.t(str(info.get("name", who))), "♥".repeat(clampi(int(bonds[who]), 0, 10))], 19)
	# ---- how you play
	_head(p, "How you play")
	_line(p, Loc.t("Academy: your novice deck, and everything you earn on the island.") if Campus.own_cards() else Loc.t("Free: your own decks and your whole collection. Rivals come one step stronger."), 18)
	if not _story:
		var sw := Button.new()
		sw.text = Loc.t("Switch to Free (my own decks)") if Campus.own_cards() else Loc.t("Switch to Academy (island cards only)")
		sw.custom_minimum_size = Vector2(0, 52)
		sw.pressed.connect(func():
			Campus.set_mode("libre" if Campus.own_cards() else "academia")
			Router.duel_config["player_deck"] = Collection.active_deck()
			open_agenda())
		p.body.add_child(sw)
	if Saves.admin:
		_admin(p)
	var close := Button.new()
	close.text = Loc.t("Close")
	close.custom_minimum_size = Vector2(0, 54)
	close.pressed.connect(p.close)
	p.body.add_child(close)


# ------------------------------------------------------------------ admin

func _admin(p: SidePanel) -> void:
	_head(p, "Admin")
	_line(p, Loc.t("Admin mode: jump anywhere and set anything. Your real game is untouched."), 17, UITheme.TEXT_DIM)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	p.body.add_child(grid)
	var add := func(text: String, act: Callable) -> void:
		var b := Button.new()
		b.text = text
		b.custom_minimum_size = Vector2(340, 48)
		b.pressed.connect(act)
		grid.add_child(b)
	for ch in CampusData.CHAPTERS:
		var id := str(ch["id"])
		if not CampusData.SCRIPTS.has(id):
			continue
		add.call(Loc.t("Play: %s") % Loc.t(str(ch["title"])), func():
			Campus.put("jacket", id != "ac_prologue")
			StoryDirector.begin(id))
	add.call(Loc.t("+100 merits"), func():
		Campus.add_merits(100, "Admin")
		open_agenda())
	add.call(Loc.t("Merits to 0"), func():
		Campus.put("merits", 0)
		open_agenda())
	add.call(Loc.t("Dorm Cup: +5 for your dorm"), func():
		Campus.cup_open()
		Campus.cup_score("blue" if Campus.dorm() != 2 else "red", 5)
		open_agenda())
	for d in 3:
		add.call(Loc.t("Dorm: %s") % Loc.t(Campus.DORM_NAMES[d]), func():
			Campus.put_many({"dorm": d, "jacket": true})
			Campus.island())
	for k in 3:
		add.call(Loc.t("Time: %s") % Loc.t(Campus.PARTS[k]), func():
			Campus.put("part", k)
			scene.city.apply_tod(Campus.tod())
			open_agenda())
	add.call(Loc.t("Next day"), func():
		Campus.sleep()
		scene.city.apply_tod(Campus.tod())
		open_agenda())
	add.call(Loc.t("Finish every mission"), func():
		var all := {}
		for m in CampusData.MISSIONS:
			all[str(m["id"])] = {"n": int(m["need"]), "done": true, "paid": false}
		Campus.put("missions", all)
		open_agenda())
	add.call(Loc.t("Bonds +1 with everybody"), func():
		for who in CampusData.CLASSMATES:
			Campus.add_bond(str(who), 1)
		open_agenda())
	add.call(Loc.t("Forget the choices made"), func():
		var cfg := Campus.read()
		cfg.set_value("story", "memory", {})
		Campus.write(cfg)
		open_agenda())
