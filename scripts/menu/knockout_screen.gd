class_name KnockoutScreen
extends Control
## The Free Duel Knockout: the bracket of eight, where you are in it, and the button for your next
## duel. Opened from Free Duel, and it comes back by itself after each of your duels to show
## how the round went.

signal start(config: Dictionary)
signal closed

const TILE := Vector2(330, 78)
const COL_X := [70.0, 520.0, 970.0, 1420.0]

var result := ""                 # "won" / "lost": you are back from a duel of the bracket
var _draw_box: Control
var _head: Label
var _sub: Label
var _go: Button
var _prize: Label
var _setup: Control
var _shown := [4, 2, 1]          # how many winners of each round are on show (they come in one by one)
var _pulse := 0.0
var _confetti: Array = []
var _just := {}                  # what the last report said (prize, champion)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	var dim := ColorRect.new()
	dim.color = Color(0.022, 0.035, 0.07, 1.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# Laid out for 1920 x 1080 and scaled to the window like the rest of the menus.
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	add_child(root)
	var fit := func():
		var s: float = minf(size.x / 1920.0, size.y / 1080.0)
		root.scale = Vector2(s, s)
		root.position = (size - Vector2(1920, 1080) * s) / 2.0
	resized.connect(fit)
	fit.call_deferred()
	var back := Button.new()
	back.text = "◀  Back"
	back.position = Vector2(64, 40)
	back.size = Vector2(120, 44)
	back.pressed.connect(close)
	root.add_child(back)
	_head = UITheme.label("KNOCKOUT", 64, Color.WHITE, Comic.shout_font())
	_head.position = Vector2(226, 22)
	root.add_child(_head)
	_sub = UITheme.label("", 22, UITheme.GOLD, UITheme.semi_font())
	_sub.position = Vector2(232, 100)
	_sub.size = Vector2(1500, 30)
	root.add_child(_sub)
	_draw_box = Control.new()
	_draw_box.position = Vector2(0, 172)
	_draw_box.size = Vector2(1920, 760)
	_draw_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_draw_box.draw.connect(_draw_bracket)
	root.add_child(_draw_box)
	_prize = UITheme.label("", 20, UITheme.TEXT_DIM)
	_prize.position = Vector2(74, 972)
	_prize.size = Vector2(1100, 30)
	root.add_child(_prize)
	_go = Button.new()
	_go.add_theme_font_size_override("font_size", 34)
	_go.position = Vector2(1240, 950)
	_go.size = Vector2(610, 86)
	_go.pressed.connect(_on_go)
	root.add_child(_go)
	_setup = _build_setup()
	root.add_child(_setup)
	Knockout.load_data()
	if result != "" and Knockout.running():
		_after_duel(result == "won")
	else:
		_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


## No bracket yet: how hard, what it pays, and the way in.
func _build_setup() -> Control:
	var pc := PanelContainer.new()
	pc.position = Vector2(460, 250)
	pc.custom_minimum_size = Vector2(1000, 420)
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.05, 0.08, 0.15, 0.98), 24, Color(UITheme.GOLD, 0.5)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pc.add_child(v)
	v.add_child(UITheme.label("EIGHT DUELISTS. THREE ROUNDS. ONE LOSS AND YOU ARE OUT.", 34, Color.WHITE, UITheme.title_font()))
	var rules := UITheme.label("Seven duelists are drawn against you, the ones you have met first. Lose once and you are out. Your Life Points start fresh every round. The semifinal is in the Academy arena and the final in the Duel Dome, in front of a full house. You can leave between rounds: the bracket waits.", 20, UITheme.TEXT)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.custom_minimum_size = Vector2(940, 0)
	v.add_child(rules)
	var cups := UITheme.label("", 18, UITheme.TEXT_DIM)
	var held: Dictionary = Collection.record.get("trophies", {})
	cups.text = Loc.t("Your cups:   Bronze %d     Silver %d     Gold %d") % [int(held.get("1", 0)), int(held.get("2", 0)), int(held.get("3", 0))]
	v.add_child(cups)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	if not Knockout.can_enter():
		var no := UITheme.label("A bracket needs seven duelists with a deck. Set your card folder in Settings first.", 20, UITheme.DANGER)
		no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no.custom_minimum_size = Vector2(940, 0)
		v.add_child(no)
		return pc
	for d in [1, 2, 3]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(300, 150)
		var col: Color = Knockout.CUP_COLORS[d]
		for st in ["normal", "hover", "pressed", "focus"]:
			var sb := UITheme.button_box(Color(col.darkened(0.72), 0.95) if st != "hover" else Color(col.darkened(0.55), 0.98), col if st in ["hover", "focus"] else Color(col, 0.45), 18)
			sb.set_border_width_all(2)
			b.add_theme_stylebox_override(st, sb)
		var inner := VBoxContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 18
		inner.offset_top = 14
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		var t1 := UITheme.label(["", "EASY", "NORMAL", "HARD"][d], 34, Color.WHITE, UITheme.title_font())
		t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(t1)
		var t2 := UITheme.label(Loc.t(str(Knockout.CUPS[d])), 20, col.lightened(0.2), UITheme.semi_font())
		t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(t2)
		var t3 := UITheme.label(Loc.t("Winner: %d Duel Points") % int(Knockout.PRIZES[d]), 17, UITheme.TEXT_DIM)
		t3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(t3)
		b.pressed.connect(func():
			Knockout.start(d)
			Sfx.play("quest", -4.0)
			_shown = [0, 0, 0]
			_refresh())
		row.add_child(b)
	var note := UITheme.label("The final is one step harder than the rest.", 16, UITheme.TEXT_DIM)
	v.add_child(note)
	return pc


func _refresh() -> void:
	var has := Knockout.has_bracket()
	_setup.visible = not has
	_draw_box.visible = has
	_go.visible = has
	_prize.visible = has
	if has:
		var dd := int(Knockout.state.get("difficulty", 1))
		_prize.text = Loc.t("%s  ·  winner takes %d Duel Points  ·  the final is one step harder") % [Loc.t(str(Knockout.CUPS[dd])), int(Knockout.PRIZES[dd])]
	if not has:
		_sub.text = Loc.t("Free Duel  ·  a knockout of eight")
		return
	var over := str(Knockout.state.get("over", ""))
	var d := int(Knockout.state.get("difficulty", 1))
	var level: String = Loc.t(["", "Easy", "Normal", "Hard"][d])
	if over == "":
		var opp := Knockout.opponent()
		_sub.text = "%s  ·  %s" % [level, Loc.t(Knockout.round_name())]
		_go.text = Loc.t("%s:  duel %s") % [Loc.t(Knockout.round_name()), _name(opp)]
		_go.disabled = false
		_shown = [(Knockout.state["wins"][0] as Array).size(), (Knockout.state["wins"][1] as Array).size(), (Knockout.state["wins"][2] as Array).size()]
	else:
		_sub.text = ("%s  ·  %s" % [level, Loc.t("You won the cup!")]) if over == "won" else ("%s  ·  %s" % [level, Loc.t("%s took the cup.") % _name(Knockout.champion())])
		_go.text = Loc.t("New knockout")
		_go.disabled = false
	_draw_box.queue_redraw()


func _name(key: String) -> String:
	if key == "player":
		return Profile.duelist_name
	return str(Characters.get_char(key).get("short", key))


func _on_go() -> void:
	if not Knockout.running():
		Knockout.clear()
		_just = {}
		_confetti.clear()
		_refresh()
		return
	_go.disabled = true
	Sfx.play("click")
	start.emit(Knockout.duel_config())


## Back from your duel: the round is settled, and the winners come onto the bracket one at a time.
func _after_duel(won: bool) -> void:
	var r := int(Knockout.state.get("round", 0))
	var before := [(Knockout.state["wins"][0] as Array).size(), (Knockout.state["wins"][1] as Array).size(), (Knockout.state["wins"][2] as Array).size()]
	_just = Knockout.report(won)
	_shown = before
	_setup.visible = false
	_draw_box.visible = true
	_go.visible = true
	_go.disabled = true
	_go.text = "..."
	_sub.text = Loc.t("%s: the results") % Loc.t(str(Knockout.ROUNDS[r]))
	var prize := int(_just.get("prize", 0))
	if prize > 0:
		Collection.dp += prize
	if str(_just.get("champion", "")) == "player":
		var held: Dictionary = Collection.record.get("trophies", {})
		var cup := str(int(_just.get("cup", 1)))
		held[cup] = int(held.get(cup, 0)) + 1
		Collection.record["trophies"] = held
	Collection.save()
	var tw := create_tween()
	tw.tween_interval(0.5)
	for rr in 3:
		var total: int = (Knockout.state["wins"][rr] as Array).size()
		for i in range(int(before[rr]), total):
			tw.tween_callback(func():
				_shown[rr] = i + 1
				Sfx.play("card", -8.0)
				_draw_box.queue_redraw())
			tw.tween_interval(0.45)
	tw.tween_callback(func():
		if str(_just.get("champion", "")) == "player":
			Sfx.play("win", -4.0)
			Sfx.play("cheer", -4.0)
			_burst()
			Router.toast(Loc.t("%s!  +%d Duel Points") % [Loc.t(str(Knockout.CUPS[int(_just.get("cup", 1))])), prize], 6.0)
		elif not won:
			if prize > 0:
				Router.toast(Loc.t("Out in the %s.  +%d Duel Points for the rounds you won.") % [Loc.t(str(Knockout.ROUNDS[r])).to_lower(), prize], 5.0)
			else:
				Router.toast(Loc.t("Out in the %s.") % Loc.t(str(Knockout.ROUNDS[r])).to_lower(), 4.0)
		else:
			Sfx.play("quest", -6.0)
		_refresh())


func _burst() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var cols := [Color("ffd166"), Color("ff5a7a"), Color("5affc0"), Color("7cc4ff"), Color("f2f2f2")]
	for i in 160:
		_confetti.append({"p": Vector2(rng.randf_range(200, 1720), rng.randf_range(-500, -20)), "v": Vector2(rng.randf_range(-40, 40), rng.randf_range(160, 340)),
				"c": cols[rng.randi() % cols.size()], "s": rng.randf_range(6, 13), "a": rng.randf() * TAU})


func _process(delta: float) -> void:
	_pulse += delta
	if _draw_box.visible:
		for c in _confetti:
			c["p"] = (c["p"] as Vector2) + (c["v"] as Vector2) * delta
			c["a"] = float(c["a"]) + delta * 5.0
		_draw_box.queue_redraw()


func _tile_at(r: int, i: int) -> Vector2:
	# Round 0: eight tiles down the left. Each later round sits between the two it came from.
	var n := 8 >> r
	var gap := 760.0 / n
	return Vector2(float(COL_X[r]), gap * (i + 0.5) - TILE.y / 2.0)


func _draw_bracket() -> void:
	if not Knockout.has_bracket():
		return
	var font := UITheme.semi_font()
	var seeds: Array = Knockout.state["seeds"]
	var wins: Array = Knockout.state["wins"]
	var cur := int(Knockout.state.get("round", 0)) if Knockout.running() else -1
	var me_gold := Color("ffd166")
	# Column headings.
	var heads := ["Quarterfinals", "Semifinals", "Final", "Champion"]
	for c in 4:
		_draw_box.draw_string(UITheme.title_font(), Vector2(float(COL_X[c]) + 4.0, -10.0), Loc.t(str(heads[c])).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
				Color(1, 1, 1, 0.55))
	# Lines first, tiles over them.
	for r in 3:
		var n := 8 >> r
		for i in n:
			var from := _tile_at(r, i) + Vector2(TILE.x, TILE.y / 2.0)
			var to := _tile_at(r + 1, i / 2) + Vector2(0, TILE.y / 2.0)
			var midx := (from.x + to.x) / 2.0
			var who := str(seeds[i]) if r == 0 else (str(wins[r - 1][i]) if i < int(_shown[r - 1]) else "")
			var went: bool = (i / 2) < int(_shown[r]) and who != "" and str(wins[r][i / 2]) == who
			var lc := (me_gold if who == "player" else Color(0.75, 0.82, 0.95)) if went else Color(1, 1, 1, 0.14)
			var lw := 3.5 if went else 2.0
			_draw_box.draw_polyline(PackedVector2Array([from, Vector2(midx, from.y), Vector2(midx, to.y), to]), lc, lw, true)
	for r in 4:
		var n := 8 >> r
		for i in n:
			var who := ""
			if r == 0:
				who = str(seeds[i])
			elif i < int(_shown[r - 1]):
				who = str(wins[r - 1][i])
			var at := _tile_at(r, i)
			# Out: lost the round this tile is in.
			var out := false
			if who != "" and r < 3 and (i / 2) < int(_shown[r]):
				out = str(wins[r][i / 2]) != who
			var mine := who == "player"
			var live: bool = r == cur and who != "" and (mine or who == Knockout.opponent())
			_tile(at, who, mine, out, live, r == 3, font)


func _tile(at: Vector2, who: String, mine: bool, out: bool, live: bool, crown: bool, font: Font) -> void:
	var box := StyleBoxFlat.new()
	var col := Color("ffd166") if mine else (Color(Characters.get_char(who).get("color", Color(0.5, 0.6, 0.8))) if who != "" else Color(1, 1, 1, 0.2))
	box.bg_color = Color(0.06, 0.095, 0.17, 0.98) if who != "" else Color(0.04, 0.06, 0.1, 0.7)
	box.set_corner_radius_all(16)
	box.border_color = Color(col, 0.25 if out else (1.0 if mine or crown else 0.6))
	box.set_border_width_all(3 if (mine and not out) or crown else 2)
	if live:
		box.shadow_color = Color(col, 0.35 + 0.25 * sin(_pulse * 4.0))
		box.shadow_size = 14
	_draw_box.draw_style_box(box, Rect2(at, TILE))
	if who == "":
		_draw_box.draw_string(font, at + Vector2(24, 48), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, 0.25))
		return
	var a := 0.4 if out else 1.0
	_draw_box.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	MapArt.token(_draw_box, at + Vector2(44, TILE.y / 2.0), 28.0, "player" if mine else who, Color(col, a), Color(0.18, 0.75, 0.8), 1.9)
	if out:
		_draw_box.draw_circle(at + Vector2(44, TILE.y / 2.0), 29.0, Color(0.03, 0.05, 0.09, 0.6))
	var name := _name(who)
	_draw_box.draw_string(UITheme.title_font(), at + Vector2(88, 38), name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, TILE.x - 100.0, 26, Color(1, 1, 1, a))
	var line := Loc.t("You") if mine else Loc.t(str(Characters.get_char(who).get("title", "")))
	if crown:
		line = Loc.t("Winner of the cup")
	_draw_box.draw_string(font, at + Vector2(88, 60), line, HORIZONTAL_ALIGNMENT_LEFT, TILE.x - 100.0, 15, Color(col.lightened(0.3), a * 0.9))
	# Confetti for a cup of your own, over everything.
	if crown and not _confetti.is_empty():
		for c in _confetti:
			var p: Vector2 = c["p"]
			if p.y > 900.0:
				continue
			_draw_box.draw_set_transform(p, float(c["a"]), Vector2.ONE)
			_draw_box.draw_rect(Rect2(-float(c["s"]) / 2.0, -float(c["s"]) / 4.0, float(c["s"]), float(c["s"]) / 2.0), c["c"])
		_draw_box.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func close() -> void:
	Sfx.play("click")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		closed.emit()
		queue_free())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
