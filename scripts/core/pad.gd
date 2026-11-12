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
var connected := false
var _armed := 0.0             # the pad moved the pointer recently: A clicks where it points
var _down := false
var _hint: Label
var _layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy)
	connected = not Input.get_connected_joypads().is_empty()
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


func _on_joy(device: int, on: bool) -> void:
	connected = not Input.get_connected_joypads().is_empty()
	if on:
		Router.toast("Controller connected: %s" % Input.get_joy_name(device))
		Sfx.play("equip", -6.0)
	elif not connected:
		Router.toast("Controller disconnected")


func _pointer_live() -> bool:
	return not walk_mode or overlay


## Text for the corner hint. Scenes call this when what the buttons do changes.
func hint(text: String) -> void:
	_hint.text = text


func _process(delta: float) -> void:
	_hint.visible = connected and _hint.text != ""
	_armed = maxf(0.0, _armed - delta)
	if not connected or not _pointer_live():
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
		var pos := vp.get_mouse_position() + v.normalized() * pow(minf(v.length(), 1.0), 2.0) * SPEED * delta
		var rect := vp.get_visible_rect()
		pos = pos.clamp(rect.position + Vector2(2, 2), rect.end - Vector2(2, 2))
		vp.warp_mouse(pos)
		_armed = 4.0


func _input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton):
		return
	if event.button_index == JOY_BUTTON_A and _pointer_live() and (_armed > 0.0 or _down):
		# A is a click wherever the pointer is.
		_down = event.pressed
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = event.pressed
		e.position = get_viewport().get_mouse_position()
		e.global_position = e.position
		get_viewport().push_input(e, true)
		get_viewport().set_input_as_handled()
