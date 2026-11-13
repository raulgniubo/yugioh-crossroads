class_name SidePanel
extends Control
## A dimmed overlay with a glass panel that slides in from the right.

signal closed

var body: VBoxContainer
var _dim: ColorRect
var _panel: PanelContainer
var _width := 640.0


func _init(title_text: String, width := 640.0) -> void:
	_width = width
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.05, 0.24, 0.62)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(_dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.057, 0.088, 0.165, 0.96), 24, Color(UITheme.ACCENT, 0.25)))
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = 40
	_panel.offset_bottom = -40
	_panel.offset_left = -_width - 40
	_panel.offset_right = -40
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	_panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 22)
	margin.add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := UITheme.label(title_text, 46, UITheme.TEXT, UITheme.title_font())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)
	var line := ColorRect.new()
	line.color = Color(UITheme.ACCENT, 0.35)
	line.custom_minimum_size = Vector2(0, 1)
	outer.add_child(line)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	scroll.add_child(body)


func _ready() -> void:
	_dim.modulate.a = 0.0
	_panel.position.x += 36
	_panel.modulate.a = 0.35
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_dim, "modulate:a", 1.0, 0.14)
	tw.tween_property(_panel, "position:x", _panel.position.x - 36, 0.16)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_dim, "modulate:a", 0.0, 0.2)
	tw.tween_property(_panel, "position:x", _panel.position.x + 80, 0.22)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()


func add_row(label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UITheme.label(label_text, 22, UITheme.TEXT)
	l.custom_minimum_size = Vector2(220, 0)
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	body.add_child(row)


func add_section(text: String) -> void:
	var l := UITheme.label(text.to_upper(), 18, UITheme.ACCENT, UITheme.semi_font())
	body.add_child(l)
