class_name SidePanel
extends Control
## A dimmed overlay with a glass panel that slides in from the right.

signal closed

var body: VBoxContainer
var _dim: ColorRect
var _panel: PanelContainer
var _width := 640.0
## Full screen (Settings since 0.69.1): a picture or a deep dim behind, the sections listed down
## the left (`nav`), the section's name and what it is about over the list (`sec_title`, `sec_sub`).
var full := false
var nav: VBoxContainer
var sec_title: Label
var sec_sub: Label
var backdrop: AcademyBackdrop


func _init(title_text: String, width := 640.0, full_screen := false, pictures: Array = []) -> void:
	_width = width
	full = full_screen
	if full:
		_build_full(title_text, pictures)
		return
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
	# Whatever is put in it, it never leaves the screen: it grows to the left, and _ready
	# keeps it narrower than the window.
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)
	# The list scrolls inside its own margins (below): slanted buttons need a little room on the
	# left or their corners are clipped, and room on the right or they run under the scrollbar.
	var margin := MarginContainer.new()
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 10)
	_panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 22)
	margin.add_child(outer)
	var head_m := MarginContainer.new()
	head_m.add_theme_constant_override("margin_left", 10)
	head_m.add_theme_constant_override("margin_right", 16)
	outer.add_child(head_m)
	var head_v := VBoxContainer.new()
	head_v.add_theme_constant_override("separation", 22)
	head_m.add_child(head_v)
	var header := HBoxContainer.new()
	head_v.add_child(header)
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
	head_v.add_child(line)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var body_m := MarginContainer.new()
	body_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_m.add_theme_constant_override("margin_left", 10)
	body_m.add_theme_constant_override("margin_right", 22)
	body_m.add_theme_constant_override("margin_top", 4)
	body_m.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(body_m)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	body_m.add_child(body)


## The full-screen layout: picture (or dim) behind; on the left the title and the sections; on
## the right a large glass page with the section's name over its settings.
func _build_full(title_text: String, pictures: Array) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	if not pictures.is_empty():
		backdrop = AcademyBackdrop.new(0.5, str(pictures[0]), Color(0.72, 0.9, 1.0))
		add_child(backdrop)
	_dim = ColorRect.new()
	_dim.color = Color(0.015, 0.025, 0.07, 0.42 if not pictures.is_empty() else 0.9)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.set_meta("full_margin", true)
	add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 34)
	m.add_child(h)
	# Left: what this is, the sections, and the way out.
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size = Vector2(340, 0)
	h.add_child(left)
	var over := UITheme.label(Loc.t("CROSSROADS"), 18, UITheme.GOLD, UITheme.semi_font())
	left.add_child(over)
	var t := UITheme.label(title_text, 78, Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 4)
	t.set_meta("big_title", true)
	left.add_child(t)
	var bar := ColorRect.new()
	bar.color = UITheme.ACCENT
	bar.custom_minimum_size = Vector2(150, 6)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(bar)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	left.add_child(gap)
	var nav_scroll := ScrollContainer.new()
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.pad_scroll(nav_scroll, 8, 6)
	left.add_child(nav_scroll)
	nav = VBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_scroll.add_child(nav)
	var close_btn := Button.new()
	close_btn.text = "  " + Loc.t("Close") + "  "
	close_btn.custom_minimum_size = Vector2(0, 60)
	close_btn.add_theme_font_size_override("font_size", 23)
	close_btn.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		close_btn.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 14, UITheme.ACCENT))
	close_btn.pressed.connect(close)
	left.add_child(close_btn)
	# Right: the page of the section that is open.
	_panel = PanelContainer.new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pb := UITheme.panel_box(Color(0.035, 0.055, 0.12, 0.86), 22, Color(1, 1, 1, 0.13))
	pb.set_content_margin_all(0)
	_panel.add_theme_stylebox_override("panel", pb)
	h.add_child(_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 0)
	_panel.add_child(pv)
	var head := MarginContainer.new()
	for side in ["left", "right"]:
		head.add_theme_constant_override("margin_" + side, 40)
	head.add_theme_constant_override("margin_top", 30)
	head.add_theme_constant_override("margin_bottom", 18)
	pv.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	head.add_child(hv)
	sec_title = UITheme.label("", 52, Color.WHITE, UITheme.title_font())
	hv.add_child(sec_title)
	sec_sub = UITheme.label("", 19, UITheme.TEXT_DIM)
	sec_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(sec_sub)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.1)
	line.custom_minimum_size = Vector2(0, 1)
	pv.add_child(line)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pv.add_child(scroll)
	var body_m := MarginContainer.new()
	body_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_m.add_theme_constant_override("margin_left", 40)
	body_m.add_theme_constant_override("margin_right", 34)
	body_m.add_theme_constant_override("margin_top", 22)
	body_m.add_theme_constant_override("margin_bottom", 26)
	scroll.add_child(body_m)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	body_m.add_child(body)


## Margins that fit the window: roomy on a big screen, tighter on a small one.
func _fit_full() -> void:
	var vs := get_viewport_rect().size
	var k := clampf(vs.y / 1080.0, 0.6, 1.0)
	for n in get_children():
		if n is MarginContainer and n.has_meta("full_margin"):
			for side in ["left", "right"]:
				n.add_theme_constant_override("margin_" + side, int(72 * k))
			n.add_theme_constant_override("margin_top", int(56 * k))
			n.add_theme_constant_override("margin_bottom", int(44 * k))
	for t in find_children("*", "Label", true, false):
		if t.has_meta("big_title"):
			t.add_theme_font_size_override("font_size", int(78 * maxf(k, 0.72)))


func _ready() -> void:
	if full:
		_fit_full()
		get_viewport().size_changed.connect(_fit_full)
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
		return
	var room: float = get_viewport_rect().size.x - 80.0
	if _width > room:
		_width = maxf(320.0, room)
		_panel.offset_left = -_width - 40
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
	if full:
		var fw := create_tween()
		fw.tween_property(self, "modulate:a", 0.0, 0.18)
		await fw.finished
		closed.emit()
		queue_free()
		return
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
	var l := UITheme.label(Loc.t(text).to_upper(), 18, UITheme.ACCENT, UITheme.semi_font())
	body.add_child(l)
