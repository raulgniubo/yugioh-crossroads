class_name MenuItem
extends Button
## Big main-menu entry: accent bar, title and subtitle. Slides and glows on hover/focus.

var _bar: ColorRect
var _title: Label
var _sub: Label
var _content: Control
var _hover := 0.0
var _target := 0.0
var _bg: StyleBoxFlat


func _init(title_text: String, subtitle: String) -> void:
	custom_minimum_size = Vector2(560, 76)
	focus_mode = Control.FOCUS_ALL
	flat = true
	_bg = UITheme.button_box(Color(0.094, 0.181, 0.404, 0.0), Color(1, 1, 1, 0.0), 14)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(s, _bg)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content)
	_bar = ColorRect.new()
	_bar.color = UITheme.ACCENT
	_bar.position = Vector2(18, 22)
	_bar.size = Vector2(4, 30)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_bar)
	_title = UITheme.label(title_text, 36, UITheme.TEXT, UITheme.title_font())
	_title.position = Vector2(40, 4)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_title)
	_sub = UITheme.label(subtitle, 16, UITheme.TEXT_DIM)
	_sub.position = Vector2(42, 45)
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_sub)
	mouse_entered.connect(func(): _target = 1.0)
	mouse_exited.connect(func(): _target = 1.0 if has_focus() else 0.0)
	focus_entered.connect(func(): _target = 1.0)
	focus_exited.connect(func(): _target = 0.0)


func _process(delta: float) -> void:
	_hover = move_toward(_hover, _target, delta * 6.0)
	var e := ease(_hover, -2.0)
	_content.position.x = 16.0 * e
	_bar.size.y = lerpf(32.0, 52.0, e)
	_bar.position.y = (84.0 - _bar.size.y) / 2.0
	_bar.color = UITheme.ACCENT.lerp(Color.WHITE, 0.35 * e)
	_bg.bg_color = Color(0.094, 0.199, 0.421, 0.55 * e)
	_bg.border_color = Color(UITheme.ACCENT, 0.35 * e)
	_title.add_theme_color_override("font_color", UITheme.TEXT.lerp(Color.WHITE, e))
	_sub.modulate.a = lerpf(0.75, 1.0, e)
