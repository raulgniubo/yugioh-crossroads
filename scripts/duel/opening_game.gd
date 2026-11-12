class_name OpeningGame
extends Control
## Who goes first? Played out, not announced: call a coin toss and watch it spin, or throw
## rock-paper-scissors against the other duelist. The winner picks first or second.
## Emits `finished(true)` when the player takes the first turn.

signal finished(player_first: bool)
signal _picked(i: int)

const SAVE := "user://opening.cfg"
const HANDS := ["Rock", "Paper", "Scissors"]

var me_key := "player"
var opp_key := ""
var me_name := "You"
var opp_name := "Rival"
var me_color := Color("2de2e6")
var opp_color := Color("ff5a6e")

var _mode := ""                 # "coin" or "rps"
var _stage: Control
var _title: Label
var _line: Label
var _buttons: HBoxContainer
var _switch: Button
var _say := [null, null]        # speech labels: me, opponent
var _t := 0.0
# Coin
var _coin_y := 0.0              # height above the table, in pixels
var _coin_a := 0.0              # flip angle
var _coin_spin := 0.6           # idle turn speed
var _coin_show := true
var _ring := -1.0               # landing ring age
# Hands
var _hand := [-1, -1]           # what each side is showing (-1 = fist held back)
var _hand_bob := 0.0
var _hand_pop := [1.0, 1.0]
var _hands_show := false
var _sparks: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80
	theme = UITheme.build()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		_mode = str(cfg.get_value("opening", "mode", ""))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--opening="):
			_mode = a.trim_prefix("--opening=")
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.05, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	create_tween().tween_property(shade, "color:a", 0.78, 0.3)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	_title = UITheme.label(Loc.t("WHO GOES FIRST?"), 58, Color.WHITE, UITheme.title_font())
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_line = UITheme.label("", 26, UITheme.TEXT_DIM, UITheme.semi_font())
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_line)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	col.add_child(row)
	row.add_child(_side(0))
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(760, 440)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.draw.connect(_draw_stage)
	row.add_child(_stage)
	row.add_child(_side(1))
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 18)
	_buttons.custom_minimum_size = Vector2(0, 150)
	col.add_child(_buttons)
	_switch = Button.new()
	_switch.flat = true
	_switch.add_theme_font_size_override("font_size", 19)
	_switch.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_switch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_switch.pressed.connect(func(): _picked.emit(-2))
	col.add_child(_switch)
	_run.call_deferred()


## One duelist's corner: portrait, name, and the line they call out.
func _side(who: int) -> Control:
	var c: Color = me_color if who == 0 else opp_color
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(300, 0)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.panel_box(Color(c.darkened(0.75), 0.9), 20, Color(c, 0.9)))
	frame.custom_minimum_size = Vector2(250, 300)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pic := TextureRect.new()
	pic.texture = Portraits.get_portrait(me_key if who == 0 else opp_key)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.custom_minimum_size = Vector2(230, 280)
	pic.flip_h = who == 1
	frame.add_child(pic)
	v.add_child(frame)
	var nm := UITheme.label((me_name if who == 0 else opp_name).to_upper(), 28, Color.WHITE, UITheme.title_font())
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(300, 0)
	v.add_child(nm)
	var say := UITheme.label("", 24, c.lightened(0.45), UITheme.semi_font())
	say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	say.custom_minimum_size = Vector2(300, 34)
	v.add_child(say)
	_say[who] = say
	return v


func _speak(who: int, text: String) -> void:
	var l: Label = _say[who]
	l.text = text
	l.modulate.a = 0.0
	l.pivot_offset = Vector2(150, 17)
	l.scale = Vector2(0.7, 0.7)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "modulate:a", 1.0, 0.12)
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	if _coin_y <= 0.5:
		_coin_a += delta * _coin_spin
	if _ring >= 0.0:
		_ring += delta
		if _ring > 0.7:
			_ring = -1.0
	for i in 2:
		_hand_pop[i] = lerpf(_hand_pop[i], 1.0, clampf(delta * 9.0, 0.0, 1.0))
	for s in _sparks:
		s[0] += s[1] * delta
		s[1].y += 620.0 * delta
	_sparks = _sparks.filter(func(s): return _t - s[3] < 0.9)
	_stage.queue_redraw()


# ------------------------------------------------------------------ buttons

func _clear_buttons() -> void:
	for c in _buttons.get_children():
		c.queue_free()


func _big_button(text: String, draw_icon: Callable, accent: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(230, 140)
	b.add_theme_stylebox_override("normal", UITheme.button_box(Color(accent, 0.12), Color(accent, 0.6), 18))
	b.add_theme_stylebox_override("hover", UITheme.button_box(Color(accent, 0.3), accent, 18))
	b.add_theme_stylebox_override("focus", UITheme.button_box(Color(accent, 0.3), Color.WHITE, 18))
	b.add_theme_stylebox_override("pressed", UITheme.button_box(Color(accent, 0.45), Color.WHITE, 18))
	var icon := Control.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func(): draw_icon.call(icon))
	b.add_child(icon)
	var l := UITheme.label(Loc.t(text), 24, Color.WHITE, UITheme.title_font())
	l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -40
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	b.mouse_entered.connect(func(): Sfx.play("hover", -14.0))
	return b


func _ask(options: Array) -> int:
	_clear_buttons()
	await get_tree().process_frame
	var first: Button = null
	for i in options.size():
		var o: Dictionary = options[i]
		var b: Button
		if o.has("icon"):
			b = _big_button(str(o["text"]), o["icon"], o.get("color", UITheme.ACCENT))
		else:
			b = Button.new()
			b.text = Loc.t(str(o["text"]))
			b.custom_minimum_size = Vector2(300, 72)
			b.add_theme_font_size_override("font_size", 28)
			if i == 0:
				b.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.25), UITheme.ACCENT, 14))
		b.pressed.connect(func():
			Sfx.play("click", -6.0)
			_picked.emit(i))
		_buttons.add_child(b)
		b.modulate.a = 0.0
		var tw := b.create_tween()
		tw.tween_interval(i * 0.06)
		tw.tween_property(b, "modulate:a", 1.0, 0.18)
		if first == null:
			first = b
	if first:
		first.grab_focus.call_deferred()
	if "--opening-auto" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1.0).timeout
		return 0
	var got: int = await _picked
	return got


func _remember() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("opening", "mode", _mode)
	cfg.save(SAVE)


# ------------------------------------------------------------------ the games

func _run() -> void:
	if _mode == "":
		_switch.visible = false
		_line.text = Loc.t("Pick how to settle it.")
		var m := await _ask([
			{"text": "Coin toss", "icon": func(c: Control): _draw_coin(c, c.size / 2.0 - Vector2(0, 18), 40.0, 0.3, true), "color": UITheme.GOLD},
			{"text": "Rock-paper-scissors", "icon": func(c: Control): _draw_hand(c, c.size / 2.0 - Vector2(0, 18), 0.62, 2, me_color, -PI / 2), "color": UITheme.ACCENT}])
		_mode = "coin" if m == 0 else "rps"
		_remember()
	_switch.visible = true
	while true:
		var result := 0
		if _mode == "coin":
			result = await _coin()
		else:
			result = await _rps()
		if result == -2:
			_mode = "rps" if _mode == "coin" else "coin"
			_remember()
			_say[0].text = ""
			_say[1].text = ""
			continue
		await _decide(result == 0)
		return


## Returns 0 when the player wins the toss, 1 when the other duelist does, -2 to switch games.
func _coin() -> int:
	_hands_show = false
	_coin_show = true
	_coin_y = 0.0
	_coin_spin = 0.6
	_title.text = Loc.t("COIN TOSS")
	_line.text = Loc.t("Call it in the air.")
	_switch.text = Loc.t("Play rock-paper-scissors instead")
	_switch.disabled = false
	var pick := await _ask([
		{"text": "Heads", "icon": func(c: Control): _draw_coin(c, c.size / 2.0 - Vector2(0, 18), 40.0, 0.0, true), "color": UITheme.GOLD},
		{"text": "Tails", "icon": func(c: Control): _draw_coin(c, c.size / 2.0 - Vector2(0, 18), 40.0, PI, true), "color": Color("b9c4d8")}])
	if pick == -2:
		return -2
	_switch.disabled = true
	_clear_buttons()
	_speak(0, Loc.t("Heads!") if pick == 0 else Loc.t("Tails!"))
	_speak(1, Loc.t("Tails.") if pick == 0 else Loc.t("Heads."))
	_line.text = ""
	var side := randi() % 2          # 0 heads, 1 tails
	# Up it goes: a high arc, a dozen turns, landing on the side that was drawn.
	Sfx.play("whoosh", -3.0, 1.4)
	var turns := 7.0 + float(randi() % 3)
	var from := fposmod(_coin_a, TAU)
	var to := turns * TAU + (PI if side == 1 else 0.0)
	_coin_spin = 0.0
	var dur := 1.75
	var el := 0.0
	var last_tick := 0
	while el < dur:
		await get_tree().process_frame
		el += get_process_delta_time()
		var u := clampf(el / dur, 0.0, 1.0)
		_coin_y = sin(u * PI) * 300.0
		_coin_a = lerpf(from, to, 1.0 - pow(1.0 - u, 1.6))
		var tick := int(_coin_a / PI)
		if tick != last_tick and u < 0.9:
			last_tick = tick
			Sfx.play("blip", -16.0, 1.5 + u)
	_coin_a = to
	_coin_y = 0.0
	Sfx.play("coin", -2.0)
	_ring = 0.0
	# A little settle on the table.
	for k in 2:
		var b := create_tween()
		b.tween_property(self, "_coin_y", 26.0 / float(k + 1), 0.09).set_ease(Tween.EASE_OUT)
		b.tween_property(self, "_coin_y", 0.0, 0.09).set_ease(Tween.EASE_IN)
		await b.finished
		Sfx.play("blip", -12.0, 0.8)
	var won := side == pick
	_burst(_stage.size / 2.0 + Vector2(0, 90), UITheme.GOLD if won else opp_color, 34)
	_title.text = Loc.t("HEADS!") if side == 0 else Loc.t("TAILS!")
	_line.text = Loc.t("You called it.") if won else Loc.t("%s called it.") % opp_name
	Sfx.play("sparkle" if won else "phase", -4.0)
	await get_tree().create_timer(0.9).timeout
	return 0 if won else 1


## Returns 0 / 1 like _coin, or -2 to switch games. Ties are thrown again.
func _rps() -> int:
	_coin_show = false
	_hands_show = true
	_hand = [-1, -1]
	_title.text = Loc.t("ROCK-PAPER-SCISSORS")
	_switch.text = Loc.t("Toss a coin instead")
	var round_n := 0
	while true:
		_hand = [-1, -1]
		_line.text = Loc.t("Choose your hand.") if round_n == 0 else Loc.t("A tie. Again!")
		_switch.disabled = round_n > 0
		var opts: Array = []
		for i in 3:
			opts.append({"text": HANDS[i], "icon": func(c: Control): _draw_hand(c, c.size / 2.0 - Vector2(0, 18), 0.62, i, me_color, -PI / 2), "color": me_color})
		var mine := await _ask(opts)
		if mine == -2:
			return -2
		_switch.disabled = true
		_clear_buttons()
		_say[0].text = ""
		_say[1].text = ""
		var theirs := randi() % 3
		# Three beats with both fists pumping, then the throw.
		var words := ["Rock...", "Paper...", "Scissors!"]
		for k in 3:
			_line.text = Loc.t(words[k])
			Sfx.play("phase", -6.0, 0.9 + k * 0.15)
			var tw := create_tween()
			tw.tween_property(self, "_hand_bob", -46.0, 0.16).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "_hand_bob", 0.0, 0.14).set_ease(Tween.EASE_IN)
			await tw.finished
			await get_tree().create_timer(0.08).timeout
		_hand = [mine, theirs]
		_hand_pop = [1.45, 1.45]
		Sfx.play("impact", -6.0, 1.3)
		_speak(0, Loc.t(HANDS[mine]) + "!")
		_speak(1, Loc.t(HANDS[theirs]) + "!")
		await get_tree().create_timer(0.55).timeout
		if mine == theirs:
			round_n += 1
			Sfx.play("blip", -6.0, 0.7)
			await get_tree().create_timer(0.5).timeout
			continue
		var won := (mine - theirs + 3) % 3 == 1
		var beats := {0: "Rock breaks scissors.", 1: "Paper wraps rock.", 2: "Scissors cut paper."}
		_title.text = Loc.t("YOU WIN!") if won else Loc.t("%s WINS") % opp_name.to_upper()
		_line.text = Loc.t(beats[mine if won else theirs])
		_hand_pop[0 if won else 1] = 1.5
		_burst(_stage.size / 2.0 + Vector2(-190 if won else 190, 0), me_color if won else opp_color, 34)
		Sfx.play("sparkle" if won else "phase", -4.0)
		await get_tree().create_timer(1.0).timeout
		return 0 if won else 1
	return 0


## The winner takes first or second.
func _decide(player_won: bool) -> void:
	_switch.visible = false
	if player_won:
		_line.text = Loc.t("Your call: first or second?")
		var c := await _ask([{"text": "Go first"}, {"text": "Go second"}])
		_speak(0, Loc.t("I'll go first!") if c == 0 else Loc.t("You start."))
		await _leave(c == 0)
	else:
		_clear_buttons()
		await get_tree().create_timer(0.35).timeout
		_speak(1, Loc.t("I'll go first."))
		_line.text = Loc.t("%s takes the first turn.") % opp_name
		Sfx.play("phase", -6.0)
		await get_tree().create_timer(1.25).timeout
		await _leave(false)


func _leave(player_first: bool) -> void:
	_clear_buttons()
	await get_tree().create_timer(0.45).timeout
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	await tw.finished
	finished.emit(player_first)
	queue_free()


func _burst(at: Vector2, color: Color, n: int) -> void:
	for i in n:
		var ang := randf() * TAU
		_sparks.append([at, Vector2(cos(ang), sin(ang)) * randf_range(140.0, 560.0) + Vector2(0, -180), color.lightened(randf() * 0.5), _t])


# ------------------------------------------------------------------ drawing

func _draw_stage() -> void:
	var c := _stage.size / 2.0
	# The table: a soft ellipse of light with a rim.
	var table := c + Vector2(0, 150)
	for i in 6:
		var k := 1.0 - i / 6.0
		_stage.draw_set_transform(table, 0.0, Vector2(1.0, 0.24))
		_stage.draw_circle(Vector2.ZERO, 330.0 * k, Color(0.25, 0.55, 0.8, 0.045))
	_stage.draw_set_transform(table, 0.0, Vector2(1.0, 0.24))
	_stage.draw_arc(Vector2.ZERO, 330.0, 0, TAU, 72, Color(UITheme.ACCENT, 0.5), 3.0)
	_stage.draw_arc(Vector2.ZERO, 250.0, 0, TAU, 72, Color(UITheme.ACCENT, 0.2), 2.0)
	if _ring >= 0.0:
		_stage.draw_arc(Vector2.ZERO, 60.0 + _ring * 420.0, 0, TAU, 64, Color(1.0, 0.85, 0.4, 0.9 * (1.0 - _ring / 0.7)), 5.0)
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _coin_show:
		# Shadow on the table shrinks as the coin climbs.
		var sh := clampf(1.0 - _coin_y / 420.0, 0.35, 1.0)
		_stage.draw_set_transform(table - Vector2(0, 8), 0.0, Vector2(1.0, 0.26))
		_stage.draw_circle(Vector2.ZERO, 92.0 * sh, Color(0, 0, 0, 0.45 * sh))
		_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_coin(_stage, table - Vector2(0, 96.0 + _coin_y), 92.0, _coin_a, false)
	if _hands_show:
		for i in 2:
			var x := -190.0 if i == 0 else 190.0
			var shown: int = _hand[i]
			_draw_hand(_stage, c + Vector2(x, 10.0 + _hand_bob), 1.7 * float(_hand_pop[i]), shown if shown >= 0 else 0,
					me_color if i == 0 else opp_color, 0.0 if i == 0 else PI, i == 1)
	for s in _sparks:
		var a := clampf(1.0 - (_t - s[3]) / 0.9, 0.0, 1.0)
		var sc: Color = s[2]
		_stage.draw_circle(s[0], 3.0 + 3.0 * a, Color(sc.r, sc.g, sc.b, a))


## A coin seen edge-on as it turns: `angle` 0 shows heads (a star), PI shows tails (a moon).
func _draw_coin(ci: Control, at: Vector2, r: float, angle: float, flat: bool) -> void:
	var cs := cos(angle)
	var squash := maxf(absf(cs), 0.06) if not flat else 1.0
	var heads := cs >= 0.0
	var gold := Color("ffcf4a") if heads else Color("c9d2e3")
	var deep := gold.darkened(0.45)
	# The edge gives it thickness when it is nearly side-on.
	ci.draw_set_transform(at + Vector2(0, r * 0.07 * (1.0 - squash)), 0.0, Vector2(1.0, squash))
	ci.draw_circle(Vector2(0, r * 0.08), r, deep.darkened(0.3))
	ci.draw_set_transform(at, 0.0, Vector2(1.0, squash))
	ci.draw_circle(Vector2.ZERO, r, deep)
	ci.draw_circle(Vector2.ZERO, r * 0.93, gold)
	ci.draw_arc(Vector2.ZERO, r * 0.8, 0, TAU, 48, deep, r * 0.035)
	# A highlight sliding across the face.
	ci.draw_arc(Vector2.ZERO, r * 0.88, -2.4, -1.2, 16, Color(1, 1, 1, 0.55), r * 0.07)
	if heads:
		var pts := PackedVector2Array()
		for i in 10:
			var rr := r * (0.55 if i % 2 == 0 else 0.23)
			var a := -PI / 2 + i * TAU / 10.0
			pts.append(Vector2(cos(a), sin(a)) * rr)
		ci.draw_colored_polygon(pts, deep)
	else:
		ci.draw_circle(Vector2.ZERO, r * 0.5, deep)
		ci.draw_circle(Vector2(r * 0.2, -r * 0.12), r * 0.42, gold)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _finger(ci: Control, from: Vector2, to: Vector2, w: float, fill: Color, line: Color) -> void:
	ci.draw_line(from, to, line, w + 7.0)
	ci.draw_circle(to, (w + 7.0) / 2.0, line)
	ci.draw_line(from, to, fill, w)
	ci.draw_circle(to, w / 2.0, fill)


## A gloved hand throwing rock (0), paper (1) or scissors (2). It points along +X before `rot`.
func _draw_hand(ci: Control, at: Vector2, scale: float, kind: int, color: Color, rot: float, mirror := false) -> void:
	var fill := color.lerp(Color.WHITE, 0.72)
	var line := color.darkened(0.6)
	ci.draw_set_transform(at, rot, Vector2(scale, scale * (-1.0 if mirror else 1.0)))
	# Cuff and wrist.
	ci.draw_rect(Rect2(-78, -20, 34, 40), line)
	ci.draw_rect(Rect2(-74, -16, 28, 32), color)
	match kind:
		0:
			ci.draw_circle(Vector2(-8, 0), 39, line)
			ci.draw_circle(Vector2(-8, 0), 34, fill)
			for i in 4:
				ci.draw_circle(Vector2(22, -24 + i * 16), 13, line)
				ci.draw_circle(Vector2(22, -24 + i * 16), 9.5, fill)
			_finger(ci, Vector2(-14, 26), Vector2(12, 34), 13, fill, line)
		1:
			ci.draw_circle(Vector2(-12, 0), 36, line)
			for i in 4:
				_finger(ci, Vector2(6, -24 + i * 16), Vector2(64 - absf(i - 1.5) * 7.0, -30 + i * 20), 13, fill, line)
			ci.draw_circle(Vector2(-12, 0), 31, fill)
			_finger(ci, Vector2(-20, 24), Vector2(10, 46), 13, fill, line)
		2:
			ci.draw_circle(Vector2(-10, 4), 36, line)
			_finger(ci, Vector2(8, -12), Vector2(70, -30), 13, fill, line)
			_finger(ci, Vector2(8, 2), Vector2(72, 12), 13, fill, line)
			ci.draw_circle(Vector2(-10, 4), 31, fill)
			for i in 2:
				ci.draw_circle(Vector2(18, 22 + i * 13), 11, line)
				ci.draw_circle(Vector2(18, 22 + i * 13), 8, fill)
			_finger(ci, Vector2(-16, 20), Vector2(14, 6), 12, fill, line)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _unhandled_input(event: InputEvent) -> void:
	# Nothing behind this screen should react while it is up.
	if event is InputEventKey or event is InputEventJoypadButton:
		if not event.is_action("ui_accept") and not event.is_action("ui_left") and not event.is_action("ui_right") \
				and not event.is_action("ui_up") and not event.is_action("ui_down"):
			get_viewport().set_input_as_handled()
