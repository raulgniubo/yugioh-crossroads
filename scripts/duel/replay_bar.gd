extends PanelContainer
## The controls of a replay (0.64.0): pause, speed, on to the next turn, both hands, and the way out.
## It sits under the phase box, where the buttons of a live duel are (nobody is playing: there is
## no turn to end).

signal pause_toggled(on: bool)
signal speed_picked(x: float)
signal skip_turn
signal hands_toggled(on: bool)
signal leave

const SPEEDS := [1.0, 2.0, 4.0]
var _speed_i := 0
var _paused := false
var _hands := false
var _pause_btn: RoundButton
var _speed_btn: Button
var _eye_btn: RoundButton
var _note: Label


func _init(title: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sb := UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.92), 16, Color(UITheme.GOLD, 0.7))
	sb.set_border_width_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	head.add_child(UITheme.label(Loc.t("REPLAY"), 17, UITheme.GOLD, UITheme.title_font()))
	var t := UITheme.label(title, 14, UITheme.TEXT_DIM, UITheme.semi_font())
	t.clip_text = true
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	_pause_btn = RoundButton.new("pause", Comic.BLUE, 52.0)
	_pause_btn.tooltip_text = Loc.t("Pause")
	_pause_btn.pressed.connect(func():
		_paused = not _paused
		_pause_btn.kind = "play" if _paused else "pause"
		_pause_btn.tooltip_text = Loc.t("Play") if _paused else Loc.t("Pause")
		_pause_btn.queue_redraw()
		pause_toggled.emit(_paused)
		_say())
	row.add_child(_pause_btn)
	_speed_btn = Button.new()
	_speed_btn.text = "1x"
	_speed_btn.custom_minimum_size = Vector2(66, 48)
	_speed_btn.tooltip_text = Loc.t("Speed")
	_speed_btn.focus_mode = Control.FOCUS_NONE
	_speed_btn.pressed.connect(func():
		_speed_i = (_speed_i + 1) % SPEEDS.size()
		_speed_btn.text = "%dx" % int(SPEEDS[_speed_i])
		speed_picked.emit(float(SPEEDS[_speed_i]))
		_say())
	row.add_child(_speed_btn)
	var skip := RoundButton.new("skip", Comic.BLUE, 52.0)
	skip.tooltip_text = Loc.t("To the next turn")
	skip.pressed.connect(func(): skip_turn.emit())
	row.add_child(skip)
	_eye_btn = RoundButton.new("eye", Comic.BLUE, 52.0)
	_eye_btn.tooltip_text = Loc.t("Show both hands")
	_eye_btn.pressed.connect(func():
		_hands = not _hands
		_eye_btn.modulate = Color(1.0, 0.85, 0.3) if _hands else Color.WHITE
		hands_toggled.emit(_hands)
		_say())
	row.add_child(_eye_btn)
	var out := RoundButton.new("close", Comic.RED, 52.0)
	out.tooltip_text = Loc.t("Leave the replay")
	out.pressed.connect(func(): leave.emit())
	row.add_child(out)
	_note = UITheme.label("", 13, UITheme.TEXT_DIM)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_note)
	_say()


func speed() -> float:
	return float(SPEEDS[_speed_i])


## One line under the buttons: what is on right now.
func _say(extra := "") -> void:
	var parts: Array = []
	if extra != "":
		parts.append(extra)
	elif _paused:
		parts.append(Loc.t("Paused"))
	else:
		parts.append(Loc.t("Playing at %dx") % int(SPEEDS[_speed_i]))
	if _hands:
		parts.append(Loc.t("both hands shown"))
	_note.text = "  ·  ".join(parts)


func skipping(on: bool) -> void:
	_say(Loc.t("On to the next turn...") if on else "")
