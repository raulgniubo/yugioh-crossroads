class_name LumenBubble
extends CanvasLayer
## What Lumen says, in a small box with her face on it. Used while you walk the worlds and
## during duels. It never takes the keyboard: it shows up, stays a moment, and goes.

var _box: PanelContainer
var _text: Label
var _hide_at := 0.0
var _t := 0.0


func _init(left := 26.0, bottom := -110.0) -> void:
	layer = 3
	_box = PanelContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_box.offset_left = left
	_box.offset_right = left + 560
	_box.offset_top = bottom - 104
	_box.offset_bottom = bottom
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.theme = UITheme.build()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.14, 0.92)
	sb.border_color = Color("7fe8ff")
	sb.set_border_width_all(2)
	sb.border_width_left = 6
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_box.add_theme_stylebox_override("panel", sb)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.visible = false
	add_child(_box)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(h)
	var face := TextureRect.new()
	face.texture = Portraits.get_portrait("lumen")
	face.custom_minimum_size = Vector2(70, 88)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UITheme.label("LUMEN", 15, Color("7fe8ff"), UITheme.semi_font()))
	_text = UITheme.label("", 20, Color.WHITE, UITheme.semi_font())
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(440, 0)
	v.add_child(_text)


func say(line: String, hold := 0.0) -> void:
	_text.text = Loc.t(line).replace("{player}", Profile.duelist_name)
	_box.visible = true
	_box.modulate.a = 0.0
	create_tween().tween_property(_box, "modulate:a", 1.0, 0.2)
	_hide_at = _t + (hold if hold > 0.0 else 2.6 + line.length() * 0.055)
	LumenSpirit.wake(_hide_at - _t + 1.0)
	Sfx.play("blip", -9.0, 1.3)


func showing() -> bool:
	return _box.visible


func _process(delta: float) -> void:
	_t += delta
	if _box.visible and _t > _hide_at:
		_box.visible = false


## Is she with you at all right now? (Between chapter 4 and the ending the Curator has her.)
static func with_you() -> bool:
	return not (StoryProgress.unlocked().has("ch5") and not StoryProgress.recalls("finished"))
