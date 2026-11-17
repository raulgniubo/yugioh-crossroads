extends Node
## Controller support that sits beside the mouse and keyboard instead of replacing them.
## Any controller the system recognizes works (Xbox, PlayStation, Switch Pro, 8BitDo in any mode).
##
## - Menus: D-pad or left stick moves the highlight, A selects, B goes back.
## - Anywhere a pointer is needed (the duel field, the city guide, deck building): the right stick
##   moves the pointer and A clicks. In a duel the left stick moves it too.
## - Free roam: left stick walks, right stick turns the camera, A talks. The pointer comes back
##   whenever a menu is open.
## You can mix freely: walk with the controller, play the duel with the mouse.

const SPEED := 1250.0

var walk_mode := false        # roam: the sticks belong to the character and the camera
var overlay := false          # roam: a menu is open, the pointer is live again
var both_sticks := false      # duel: the left stick moves the pointer too
## Whether the game shows controller buttons. Settings "Show buttons for": Automatic (only once
## a real controller is actually used, back to the keyboard the moment a key or the mouse is
## pressed), Keyboard & mouse, or Controller. A device the system lists as a controller that is
## never touched (some headsets, wheels, drawing tablets) changes nothing.
var connected: bool:
	get:
		match Settings.pad_show:
			"keys":
				return false
			"pad":
				return true
		return plugged and _used
var plugged := false          # a controller is connected (the pointer follows its stick)
var _used := false            # ...and it was the last thing used
var _pushing := false         # (the click A sends is not the mouse being used)
var _armed := 0.0             # the pad moved the pointer recently: A clicks where it points
var _down := false
var _hint: Label
var _layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy)
	plugged = not Input.get_connected_joypads().is_empty()
	for pair in [["ui_pause", JOY_BUTTON_START]]:
		if InputMap.has_action(pair[0]):
			var ev := InputEventJoypadButton.new()
			ev.button_index = pair[1]
			InputMap.action_add_event(pair[0], ev)
	_layer = CanvasLayer.new()
	_layer.layer = 90
	add_child(_layer)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 17)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_right = -24
	_hint.offset_bottom = -10
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_hint)
	apply_map.call_deferred()


# ------------------------------------------------------------------ buttons, pictures, remapping

## The buttons by their place on the pad, with their name on each kind of controller.
## (Godot's A is the bottom face button on every pad; on a Nintendo pad that one is labelled B.)
const BUTTONS := [
	[JOY_BUTTON_A, "A", "Ⓐ", "✕", "Ⓑ"], [JOY_BUTTON_B, "B", "Ⓑ", "○", "Ⓐ"], [JOY_BUTTON_X, "X", "Ⓧ", "□", "Ⓨ"],
	[JOY_BUTTON_Y, "Y", "Ⓨ", "△", "Ⓧ"], [JOY_BUTTON_LEFT_SHOULDER, "LB", "LB", "L1", "L"], [JOY_BUTTON_RIGHT_SHOULDER, "RB", "RB", "R1", "R"],
	[JOY_BUTTON_BACK, "Back", "View", "Create", "−"], [JOY_BUTTON_START, "Start", "☰", "Options", "+"],
	[JOY_BUTTON_LEFT_STICK, "L3", "L3", "L3", "L-stick"], [JOY_BUTTON_RIGHT_STICK, "R3", "R3", "R3", "R-stick"],
	[JOY_BUTTON_DPAD_UP, "Up", "D-pad ↑", "D-pad ↑", "D-pad ↑"],
]
const TRIGGERS := {"LT": ["LT", "L2", "ZL"], "RT": ["RT", "R2", "ZR"]}
## Which pad button a keyboard key shares a job with, so prompts can show the right one.
const KEY_TO_PAD := {"E": "A", "G": "Back", "C": "X", "M": "Y", "J": "R3", "Tab": "R3"}

signal changed          # a controller came or went, or its settings changed: redraw button names


## "xbox", "ps" or "nintendo": what the button pictures should look like.
func family() -> String:
	if Settings.pad_layout != "auto":
		return Settings.pad_layout
	for dev in Input.get_connected_joypads():
		var n := Input.get_joy_name(dev).to_lower()
		if n.contains("ps") or n.contains("dualsense") or n.contains("dualshock") or n.contains("playstation") or n.contains("wireless controller"):
			return "ps"
		if n.contains("nintendo") or n.contains("switch") or n.contains("pro controller") or n.contains("joy-con"):
			return "nintendo"
	return "xbox"


## The picture for a button by its Xbox-style name ("A", "LB", "Start", "LT"...), as the
## player's controller labels it, after their remapping.
func g(name: String) -> String:
	var col: int = {"xbox": 2, "ps": 3, "nintendo": 4}.get(family(), 2)
	if TRIGGERS.has(name):
		return TRIGGERS[name][col - 2]
	var want := -1
	for b in BUTTONS:
		if b[1] == name:
			want = b[0]
	if want < 0:
		return name
	# The physical button the player set to do this job, if they moved it.
	var phys := want
	for k in Settings.pad_map:
		if int(Settings.pad_map[k]) == want:
			phys = int(k)
	for b in BUTTONS:
		if b[0] == phys:
			return str(b[col])
	return name


## The button a pressed physical button acts as (the player's remapping applied).
func b(event: InputEvent) -> int:
	if not (event is InputEventJoypadButton):
		return -1
	return int(Settings.pad_map.get(event.button_index, event.button_index))


## Is the button that does the job of `virtual` held down?
func held(virtual: int) -> bool:
	for dev in Input.get_connected_joypads():
		for b2 in BUTTONS:
			if int(Settings.pad_map.get(b2[0], b2[0])) == virtual and Input.is_joy_button_pressed(dev, b2[0]):
				return true
	return false


## Keyboard prompts ("E   Talk to Yugi", "Press G to travel") with the controller's buttons
## instead, when a controller is connected.
func keys(text: String, over := {}) -> String:
	if not connected:
		return text
	var table: Dictionary = KEY_TO_PAD.merged(over, true)
	var out := text
	var rx := RegEx.create_from_string("(^|   |    |     |        )(Tab|[A-Z])(   )")
	var m := rx.search(out)
	var guard := 0
	while m != null and guard < 6:
		guard += 1
		var k := m.get_string(2)
		if table.has(k):
			out = out.substr(0, m.get_start(2)) + g(str(table[k])) + out.substr(m.get_end(2))
		m = rx.search(out, m.get_start(2) + 1)
	var rp := RegEx.create_from_string("Press (Tab|[A-Z])\\b")
	var m2 := rp.search(out)
	if m2 != null and table.has(m2.get_string(1)):
		out = out.substr(0, m2.get_start(1)) + g(str(table[m2.get_string(1)])) + out.substr(m2.get_end(1))
	return out


## A short buzz, when the player has rumble on.
func rumble(weak: float, strong: float, secs: float) -> void:
	if not Settings.pad_rumble or not connected:
		return
	for dev in Input.get_connected_joypads():
		Input.start_joy_vibration(dev, weak, strong, secs)


## The built-in confirm and cancel follow the remapping too.
func apply_map() -> void:
	for act in ["ui_accept", "ui_cancel"]:
		if not InputMap.has_action(act):
			continue
		for e in InputMap.action_get_events(act):
			if e is InputEventJoypadButton:
				InputMap.action_erase_event(act, e)
		var want := JOY_BUTTON_A if act == "ui_accept" else JOY_BUTTON_B
		for b2 in BUTTONS:
			if int(Settings.pad_map.get(b2[0], b2[0])) == want:
				var ev := InputEventJoypadButton.new()
				ev.button_index = b2[0]
				InputMap.action_add_event(act, ev)


var _hint_raw := ""


func _on_joy(device: int, on: bool) -> void:
	plugged = not Input.get_connected_joypads().is_empty()
	if not plugged:
		_used = false
	hint(_hint_raw)
	changed.emit()
	if on:
		Router.toast(Loc.t("Controller connected: %s") % Input.get_joy_name(device))
		Sfx.play("equip", -6.0)
	elif not plugged:
		Router.toast("Controller disconnected")


func _pointer_live() -> bool:
	return not walk_mode or overlay


## Text for the corner hint. Scenes call this when what the buttons do changes. Button
## names in it are Xbox style and come out as the player's own controller shows them.
func hint(text: String) -> void:
	_hint_raw = text
	var words := text.split("     ")
	var out := []
	for w in words:
		var parts := w.split("  ", false, 1)
		if parts.size() == 2:
			var keys_ := []
			for k in parts[0].split(" "):
				keys_.append(g(k) if k != "" else k)
			out.append(" ".join(keys_) + "  " + Loc.t(parts[1]))
		else:
			out.append(Loc.t(w))
	_hint.text = "     ".join(out)


func _process(delta: float) -> void:
	_hint.visible = connected and _hint.text != ""
	_armed = maxf(0.0, _armed - delta)
	if not plugged or not _pointer_live():
		return
	var v := Vector2.ZERO
	for dev in Input.get_connected_joypads():
		var r := Vector2(Input.get_joy_axis(dev, JOY_AXIS_RIGHT_X), Input.get_joy_axis(dev, JOY_AXIS_RIGHT_Y))
		if r.length() > 0.22:
			v += r
		if both_sticks:
			var l := Vector2(Input.get_joy_axis(dev, JOY_AXIS_LEFT_X), Input.get_joy_axis(dev, JOY_AXIS_LEFT_Y))
			if l.length() > 0.22:
				v += l
	if v.length() > 0.22:
		var vp := get_viewport()
		# Slow near the centre of the stick for fine aim, fast at the edge.
		var pos := vp.get_mouse_position() + v.normalized() * pow(minf(v.length(), 1.0), 2.0) * SPEED * Settings.pad_pointer * delta
		var rect := vp.get_visible_rect()
		pos = pos.clamp(rect.position + Vector2(2, 2), rect.end - Vector2(2, 2))
		vp.warp_mouse(pos)
		_armed = 4.0


func _set_used(on: bool) -> void:
	if _used == on:
		return
	_used = on
	hint(_hint_raw)
	changed.emit()


func _input(event: InputEvent) -> void:
	# Which one you are using right now decides the button names on screen (Automatic).
	if (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.6):
		plugged = true
		_set_used(true)
	elif not _pushing and ((event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed)):
		_set_used(false)
	if not (event is InputEventJoypadButton):
		return
	if b(event) == JOY_BUTTON_A and _pointer_live() and (_armed > 0.0 or _down):
		# A is a click wherever the pointer is.
		_down = event.pressed
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = event.pressed
		e.position = get_viewport().get_mouse_position()
		e.global_position = e.position
		_pushing = true
		get_viewport().push_input(e, true)
		_pushing = false
		get_viewport().set_input_as_handled()
