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
var _cup_card := 0               # the card that came with a cup won for the first time


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	# The same deep blue glass as the other big menus (it was a plain black screen with a box
	# in the middle, which read as an error message).
	var dim := AcademyBackdrop.new(0.45, StoryGate.PICTURE, Color(1.0, 0.9, 0.6))
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
	var bar := ColorRect.new()
	bar.color = UITheme.GOLD
	bar.position = Vector2(228, 98)
	bar.size = Vector2(118, 4)
	root.add_child(bar)
	_sub = UITheme.label("", 22, UITheme.GOLD, UITheme.semi_font())
	_sub.position = Vector2(232, 108)
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
	# It comes in from the right: you have gone somewhere else, this is not a box over Free Duel.
	modulate.a = 0.0
	root.position.x += 120.0
	var tin := create_tween().set_parallel()
	tin.tween_property(self, "modulate:a", 1.0, 0.22)
	tin.tween_property(root, "position:x", root.position.x - 120.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## No bracket yet: what it is, the three cups to play for, and who can be drawn against you.
func _build_setup() -> Control:
	var box := Control.new()
	box.size = Vector2(1920, 1080)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Left: what a Knockout is.
	var big := UITheme.label("EIGHT DUELISTS.\nTHREE ROUNDS.\nONE LOSS AND YOU ARE OUT.", 54, Color.WHITE, UITheme.title_font())
	big.position = Vector2(70, 190)
	big.size = Vector2(760, 220)
	big.add_theme_constant_override("line_spacing", -6)
	box.add_child(big)
	var rules := UITheme.label("Seven duelists are drawn against you, the ones you have met first. Your Life Points start fresh every round. You can leave between rounds: the bracket waits.", 22, UITheme.TEXT)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.position = Vector2(74, 420)
	rules.size = Vector2(700, 110)
	box.add_child(rules)
	# The road to the cup: where each round is played.
	var steps := [["QUARTERFINAL", "On your opponent's own field"], ["SEMIFINAL", "The Academy arena"], ["FINAL", "The Duel Dome, in front of a full house. One step harder."]]
	for i in steps.size():
		var y := 560.0 + i * 78.0
		var num := UITheme.label(str(i + 1), 34, Color(0.03, 0.05, 0.1), UITheme.title_font())
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.position = Vector2(74, y)
		num.size = Vector2(56, 56)
		num.add_theme_stylebox_override("normal", UITheme.button_box(UITheme.GOLD, UITheme.GOLD, 28))
		box.add_child(num)
		var st := UITheme.label(str(steps[i][0]), 26, UITheme.GOLD, UITheme.title_font())
		st.position = Vector2(148, y - 2)
		box.add_child(st)
		var sd := UITheme.label(str(steps[i][1]), 19, UITheme.TEXT_DIM)
		sd.position = Vector2(148, y + 28)
		box.add_child(sd)
	# Right: the three cups.
	var held: Dictionary = Collection.record.get("trophies", {})
	if not Knockout.can_enter():
		var no := UITheme.label("A bracket needs seven duelists with a deck. Set your card folder in Settings first.", 24, UITheme.DANGER)
		no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no.position = Vector2(900, 320)
		no.size = Vector2(900, 120)
		box.add_child(no)
	else:
		for d in [1, 2, 3]:
			var col: Color = Knockout.CUP_COLORS[d]
			var b := Button.new()
			b.position = Vector2(872 + (d - 1) * 338, 190)
			b.size = Vector2(318, 590)
			b.pivot_offset = b.size / 2.0
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			for st2 in ["normal", "hover", "pressed", "focus"]:
				var sb := UITheme.button_box(Color(0.05, 0.08, 0.15, 0.96) if st2 != "hover" else Color(col.darkened(0.72), 0.98), col if st2 in ["hover", "focus"] else Color(col, 0.5), 22)
				sb.set_border_width_all(3 if st2 in ["hover", "focus"] else 2)
				b.add_theme_stylebox_override(st2, sb)
			b.mouse_entered.connect(func(): b.create_tween().tween_property(b, "scale", Vector2(1.03, 1.03), 0.1))
			b.mouse_exited.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
			var cup := Control.new()
			cup.position = Vector2(59, 26)
			cup.size = Vector2(200, 230)
			cup.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cup.draw.connect(func(): _draw_cup(cup, col))
			b.add_child(cup)
			var lines := [[["", "EASY", "NORMAL", "HARD"][d], 46, Color.WHITE, UITheme.title_font(), 270.0],
				[Loc.t(str(Knockout.CUPS[d])).to_upper(), 22, col.lightened(0.25), UITheme.semi_font(), 326.0],
				[Loc.t("%d Duel Points") % int(Knockout.PRIZES[d]), 26, UITheme.GOLD, UITheme.title_font(), 372.0],
				[Loc.t("to the winner"), 17, UITheme.TEXT_DIM, null, 406.0],
				[Loc.t("You hold %d") % int(held.get(str(d), 0)), 18, UITheme.TEXT_DIM if int(held.get(str(d), 0)) == 0 else col.lightened(0.3), null, 446.0]]
			for ln in lines:
				var l := UITheme.label(str(ln[0]), int(ln[1]), ln[2], ln[3])
				l.position = Vector2(0, float(ln[4]))
				l.size = Vector2(318, 50)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				l.mouse_filter = Control.MOUSE_FILTER_IGNORE
				b.add_child(l)
			var enter := UITheme.label(Loc.t("ENTER") + "   ▶", 26, Color(0.03, 0.05, 0.1), UITheme.title_font())
			enter.position = Vector2(34, 506)
			enter.size = Vector2(250, 56)
			enter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			enter.add_theme_stylebox_override("normal", UITheme.button_box(col, col.lightened(0.3), 14))
			enter.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(enter)
			b.pressed.connect(func():
				Knockout.start(d)
				Sfx.play("quest", -4.0)
				_shown = [0, 0, 0]
				_refresh())
			box.add_child(b)
	# Along the bottom: the faces that can be drawn.
	var who: Array = Knockout.pool()
	var rest: Array = Knockout.everyone().filter(func(k): return not who.has(k))
	var faces := Control.new()
	faces.position = Vector2(70, 836)
	faces.size = Vector2(1780, 150)
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faces.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shown: Array = (who + (rest if who.size() < 7 else [])).slice(0, 22)
	faces.draw.connect(func():
		faces.draw_string(UITheme.semi_font(), Vector2(4, 16), Loc.t("WHO CAN BE DRAWN AGAINST YOU").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UITheme.GOLD)
		for i in shown.size():
			var k := str(shown[i])
			var met: bool = who.has(k)
			var at := Vector2(40 + i * 78.0, 78)
			MapArt.token(faces, at, 30.0, k, Color(Color(Characters.get_char(k).get("color", Color(0.5, 0.6, 0.8))), 1.0 if met else 0.35), Color(0.18, 0.75, 0.8), 1.9)
			if not met:
				faces.draw_circle(at, 31.0, Color(0.03, 0.05, 0.09, 0.55))
			faces.draw_string(UITheme.semi_font(), at + Vector2(-38, 54), str(Characters.get_char(k).get("short", k)), HORIZONTAL_ALIGNMENT_CENTER, 76, 14, Color(1, 1, 1, 0.85 if met else 0.4)))
	box.add_child(faces)
	return box


## A cup: bowl, two handles, stem and foot, with a shine and a star.
func _draw_cup(c: Control, col: Color) -> void:
	var lit := col.lightened(0.45)
	var dark := col.darkened(0.35)
	var mid := Vector2(100, 0)
	# Handles.
	for sx: float in [-1.0, 1.0]:
		c.draw_arc(mid + Vector2(sx * 62, 62), 30.0, -PI * 0.5 if sx > 0.0 else PI * 0.5, PI * 0.5 if sx > 0.0 else PI * 1.5, 24, dark, 11.0, true)
		c.draw_arc(mid + Vector2(sx * 62, 62), 30.0, -PI * 0.5 if sx > 0.0 else PI * 0.5, PI * 0.5 if sx > 0.0 else PI * 1.5, 24, col, 6.0, true)
	# Bowl.
	var bowl := PackedVector2Array()
	for i in 21:
		var t := i / 20.0
		var a := PI * t
		bowl.append(mid + Vector2(cos(a) * 70.0, 20.0 + sin(a) * 104.0))
	bowl.append(mid + Vector2(-70, 14))
	bowl.append(mid + Vector2(70, 14))
	c.draw_colored_polygon(bowl, col)
	c.draw_rect(Rect2(mid + Vector2(-76, 8), Vector2(152, 16)), lit)
	# Shine down the left of the bowl.
	var shine := PackedVector2Array([mid + Vector2(-48, 30), mid + Vector2(-30, 30), mid + Vector2(-22, 96), mid + Vector2(-34, 88)])
	c.draw_colored_polygon(shine, Color(1, 1, 1, 0.35))
	# Stem and foot.
	c.draw_rect(Rect2(mid + Vector2(-12, 120), Vector2(24, 48)), dark)
	c.draw_rect(Rect2(mid + Vector2(-8, 120), Vector2(8, 48)), col)
	c.draw_rect(Rect2(mid + Vector2(-48, 166), Vector2(96, 16)), col)
	c.draw_rect(Rect2(mid + Vector2(-62, 182), Vector2(124, 22)), dark)
	c.draw_rect(Rect2(mid + Vector2(-62, 182), Vector2(124, 6)), lit)
	# A star on the bowl.
	var star := PackedVector2Array()
	for i in 10:
		var a2 := -PI * 0.5 + i * PI / 5.0
		star.append(mid + Vector2(0, 66) + Vector2(cos(a2), sin(a2)) * (22.0 if i % 2 == 0 else 9.5))
	c.draw_colored_polygon(star, Color(1, 1, 1, 0.9))


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
		# The first time a cup is yours it comes with one of Lumen's forms.
		if int(held.get(cup, 0)) == 0:
			_cup_card = Collection.lumen_copy(true)
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
			if _cup_card != 0:
				Router.toast(Loc.t("First time you hold this cup: %s is in your collection.") % str(CardData.get_card(_cup_card).get("name", "")), 7.0)
				_cup_card = 0
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
