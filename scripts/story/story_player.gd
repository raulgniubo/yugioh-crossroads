extends Control
## Plays a story chapter: location cards, dialogue with portraits, choices and story duels.

const MenuBackground := preload("res://scripts/menu/menu_background.gd")

var chapter := "prologue"
var step := 0
var flags := {}
var _steps: Array = []
var _left: TextureRect
var _right: TextureRect
var _left_key := "player"
var _right_key := ""
var _name_tag: Label
var _text: RichTextLabel
var _box: PanelContainer
var _more: Label
var _tint: ColorRect
var _flash: ColorRect
var _typing: Tween
var _busy := false
var _waiting_choice := false
var _root: Control


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Music.play("menu")
	Pad.walk_mode = false
	Pad.both_sticks = false
	Pad.hint("A  next     B  menu     Right stick  pointer")
	_build()
	var s: Dictionary = Router.story
	chapter = s.get("chapter", "prologue")
	step = int(s.get("step", 0))
	flags = s.get("flags", {}).duplicate()
	_steps = StoryData.SCRIPTS.get(chapter, [])
	var result: String = Router.story_result
	Router.story_result = ""
	if result != "":
		flags.erase("won")
		flags.erase("lost")
		flags[result] = true
		step += 1
	else:
		_chapter_card()
		await get_tree().create_timer(2.2).timeout
	_next()
	if "--auto-story" in OS.get_cmdline_user_args():
		_auto()


func _auto() -> void:
	while is_inside_tree():
		await get_tree().create_timer(0.25).timeout
		if _waiting_choice:
			for c in get_children():
				if c is VBoxContainer and c.get_child_count() > 0 and c.get_child(0) is Button:
					(c.get_child(0) as Button).pressed.emit()
					break
		else:
			_advance()


func _build() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	svc.add_child(vp)
	var bg := Node3D.new()
	bg.set_script(MenuBackground)
	vp.add_child(bg)
	_tint = ColorRect.new()
	_tint.color = Color(0.02, 0.03, 0.06, 0.55)
	_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tint)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_left = _portrait(true)
	_right = _portrait(false)
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.1, 0.94), 24, Color(UITheme.ACCENT, 0.4)))
	_box.anchor_left = 0.5
	_box.anchor_right = 0.5
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = -680
	_box.offset_right = 680
	_box.offset_top = -290
	_box.offset_bottom = -40
	_root.add_child(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_box.add_child(v)
	_name_tag = UITheme.label("", 32, UITheme.ACCENT, UITheme.title_font())
	v.add_child(_name_tag)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(1300, 140)
	_text.add_theme_font_size_override("normal_font_size", 30)
	_text.add_theme_color_override("default_color", UITheme.TEXT)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_text)
	_more = UITheme.label("▼", 22, UITheme.ACCENT)
	_more.anchor_left = 1.0
	_more.anchor_top = 1.0
	_more.position = Vector2(1300, 200)
	_box.add_child(_more)
	var bob := create_tween().set_loops()
	bob.tween_property(_more, "modulate:a", 0.2, 0.5)
	bob.tween_property(_more, "modulate:a", 1.0, 0.5)
	# Top bar
	var bar := HBoxContainer.new()
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.offset_left = -420
	bar.offset_right = -40
	bar.offset_top = 30
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.add_theme_constant_override("separation", 10)
	_root.add_child(bar)
	var skip := Button.new()
	skip.text = "Skip  ▸▸"
	skip.pressed.connect(_skip)
	bar.add_child(skip)
	var menu := Button.new()
	menu.text = "Menu"
	menu.pressed.connect(func():
		StoryProgress.save_position(chapter, step, flags)
		Router.go(Router.MAIN_MENU))
	bar.add_child(menu)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func _portrait(left: bool) -> TextureRect:
	var frame := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(28)
	frame.add_theme_stylebox_override("panel", sb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	frame.size = Vector2(560, 700)
	frame.position = Vector2(60 if left else 1300, 140)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(frame)
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.modulate.a = 0.0
	frame.add_child(t)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.02, 0.03, 0.06, 1)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(shade)
	return t


func _sub(text: String) -> String:
	return Loc.t(text).replace("{player}", Profile.duelist_name)


func _chapter_card() -> void:
	var info := {}
	for c in StoryData.CHAPTERS:
		if c["id"] == chapter:
			info = c
	_box.modulate.a = 0.0
	var l := UITheme.label(Loc.t(str(info.get("title", ""))).to_upper(), 28, UITheme.ACCENT, UITheme.semi_font())
	var n := UITheme.label(str(info.get("name", "")), 96, Color.WHITE, UITheme.title_font())
	var vb := VBoxContainer.new()
	vb.add_child(l)
	vb.add_child(n)
	vb.position = Vector2(140, 400)
	vb.modulate.a = 0.0
	add_child(vb)
	var tw := create_tween()
	tw.tween_property(vb, "modulate:a", 1.0, 0.6)
	tw.tween_interval(1.2)
	tw.tween_property(vb, "modulate:a", 0.0, 0.4)
	tw.tween_callback(vb.queue_free)


# ------------------------------------------------------------------ flow

func _next() -> void:
	while step < _steps.size():
		var st: Dictionary = _steps[step]
		if st.has("if") and not flags.has(st["if"]):
			step += 1
			continue
		if st.has("loc"):
			await _location(st)
			step += 1
			continue
		if st.has("choice"):
			_show_choice(st["choice"])
			return
		if st.has("duel"):
			_start_duel(st["duel"])
			return
		if st.has("end"):
			_end(st)
			return
		_say(st)
		return
	_end({"end": "To be continued"})


func _advance() -> void:
	if _busy or _waiting_choice:
		return
	if _typing and _typing.is_running():
		_typing.kill()
		_text.visible_ratio = 1.0
		return
	step += 1
	_next()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()


func _location(st: Dictionary) -> void:
	_busy = true
	var theme_key: String = st.get("theme", "crossroads")
	var th := FieldThemes.resolve(theme_key, "")
	create_tween().tween_property(_tint, "color", Color(Color(th["sky_horizon"]).darkened(0.6), 0.6), 0.8)
	_box.modulate.a = 0.0
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.6)
	band.size = Vector2(get_viewport_rect().size.x, 170)
	band.position = Vector2(0, 430)
	add_child(band)
	var t := UITheme.label(str(st["loc"]).to_upper(), 76, Color.WHITE, UITheme.title_font())
	t.position = Vector2(140, 14)
	band.add_child(t)
	var sub := UITheme.label(str(st.get("sub", "")), 24, th["accent"], UITheme.semi_font())
	sub.position = Vector2(144, 110)
	band.add_child(sub)
	band.modulate.a = 0.0
	Sfx.play("turn", -6.0, 0.8)
	var tw := create_tween()
	tw.tween_property(band, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.4)
	tw.tween_property(band, "modulate:a", 0.0, 0.4)
	await tw.finished
	band.queue_free()
	_busy = false


func _say(st: Dictionary) -> void:
	var who: String = st.get("s", "")
	var text := _sub(str(st.get("t", "")))
	if _box.modulate.a < 1.0:
		create_tween().tween_property(_box, "modulate:a", 1.0, 0.2)
	if who == "":
		_name_tag.text = ""
		_text.add_theme_color_override("default_color", Color(0.8, 0.86, 0.95))
		_dim_both()
	else:
		var info := Portraits.info(who)
		_name_tag.text = str(info.get("short", info.get("name", who))).to_upper()
		_name_tag.add_theme_color_override("font_color", info.get("color", UITheme.ACCENT))
		_text.add_theme_color_override("default_color", UITheme.TEXT)
		_show_speaker(who)
	_text.text = text
	_text.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, maxf(0.25, text.length() * 0.018))
	match st.get("fx", ""):
		"shake":
			var tw := create_tween()
			for i in 8:
				tw.tween_property(_root, "position", Vector2(randf_range(-14, 14), randf_range(-10, 10)), 0.04)
			tw.tween_property(_root, "position", Vector2.ZERO, 0.05)
			Sfx.play("impact", -4.0)
		"flash":
			_flash.color.a = 0.85
			create_tween().tween_property(_flash, "color:a", 0.0, 0.6)
			Sfx.play("special", -6.0)


func _show_speaker(who: String) -> void:
	var left := who == "player"
	var tex := Portraits.get_portrait(who)
	var target := _left if left else _right
	if left:
		_left_key = who
	elif _right_key != who:
		_right_key = who
		target.modulate.a = 0.0
		target.position.x = 40
		var slide := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide.tween_property(target, "position:x", 0.0, 0.3)
	target.texture = tex
	var other := _right if left else _left
	var tw := create_tween().set_parallel()
	tw.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.2)
	if other.texture != null:
		tw.tween_property(other, "modulate", Color(0.45, 0.48, 0.55, 0.85), 0.2)


func _dim_both() -> void:
	for t in [_left, _right]:
		if t.texture != null:
			create_tween().tween_property(t, "modulate", Color(0.4, 0.42, 0.5, 0.7), 0.2)


func _show_choice(options: Array) -> void:
	_waiting_choice = true
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.offset_left = -360
	v.offset_right = 360
	v.offset_top = 300
	add_child(v)
	for o in options:
		var b := Button.new()
		b.text = _sub(str(o[0]))
		b.custom_minimum_size = Vector2(720, 70)
		b.add_theme_font_size_override("font_size", 28)
		var flag: String = o[1]
		b.pressed.connect(func():
			flags[flag] = true
			v.queue_free()
			_waiting_choice = false
			step += 1
			_next())
		v.add_child(b)
	await get_tree().process_frame
	(v.get_child(0) as Button).grab_focus()


func _start_duel(d: Dictionary) -> void:
	print("STORY DUEL: ", d["opponent"], " at step ", step)
	StoryProgress.save_position(chapter, step, flags)
	Router.story = {"chapter": chapter, "step": step, "flags": flags}
	Router.duel_config = {
		"opponent": d["opponent"], "player_deck": d.get("deck", "echo"), "player_char": "player",
		"difficulty": d.get("difficulty", 1), "field": d.get("field", "auto"),
		"story": true, "lose_ok": d.get("lose_ok", false),
	}
	Router.go(Router.DUEL)


func _skip() -> void:
	if _waiting_choice or _busy:
		return
	if _typing and _typing.is_running():
		_typing.kill()
	# Jump to the next choice, duel or chapter end.
	while step + 1 < _steps.size():
		var st: Dictionary = _steps[step + 1]
		if st.has("choice") or st.has("duel") or st.has("end"):
			break
		step += 1
	step += 1
	_next()


func _end(st: Dictionary) -> void:
	print("STORY END: ", chapter, " ", st.get("end", ""))
	if st.has("unlock"):
		StoryProgress.unlock(st["unlock"])
	StoryProgress.clear_position()
	_busy = true
	var l := UITheme.label(str(st["end"]).to_upper(), 96, Color.WHITE, UITheme.title_font())
	l.add_theme_color_override("font_shadow_color", Color(UITheme.ACCENT, 0.8))
	l.add_theme_constant_override("shadow_outline_size", 30)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.modulate.a = 0.0
	add_child(l)
	Sfx.play("win")
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.6)
	tw.tween_interval(2.0)
	await tw.finished
	Router.go(Router.MAIN_MENU)
