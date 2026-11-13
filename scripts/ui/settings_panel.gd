class_name SettingsPanel
extends RefCounted
## Builds the settings side panel. Used from the main menu and the pause menu.


## One block of settings: a titled card with rows inside.
static func _card(p: SidePanel, title: String, glyph: String, tint: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.106, 0.222, 0.495, 0.9)
	sb.set_corner_radius_all(18)
	sb.border_color = Color(tint, 0.28)
	sb.set_border_width_all(1)
	sb.border_width_left = 4
	sb.set_content_margin_all(20)
	sb.content_margin_top = 14
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pc.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var g := UITheme.label(glyph, 24, tint.lightened(0.3))
	head.add_child(g)
	var t := UITheme.label(Loc.t(title).to_upper(), 20, tint.lightened(0.35), UITheme.semi_font())
	head.add_child(t)
	v.add_child(head)
	var rule := ColorRect.new()
	rule.color = Color(tint, 0.22)
	rule.custom_minimum_size = Vector2(0, 1)
	v.add_child(rule)
	p.body.add_child(pc)
	return v


## A setting: its name and a short word on what it does on the left, the control on the right.
static func _row(v: VBoxContainer, title: String, hint: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(UITheme.label(title, 22, UITheme.TEXT))
	if hint != "":
		var h := UITheme.label(hint, 15, UITheme.TEXT_DIM)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(h)
	row.add_child(words)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if control is OptionButton or control is LineEdit:
		control.custom_minimum_size = Vector2(300, 46)
	row.add_child(control)
	v.add_child(row)


static func open(parent: Node) -> SidePanel:
	var p := SidePanel.new("Settings", 820)
	p.body.add_theme_constant_override("separation", 16)
	var desktop := OS.has_feature("pc")

	var disp := _card(p, "Display", "▣", Color("7cc4ff"))
	if desktop:
		var fs := CheckButton.new()
		fs.button_pressed = Settings.fullscreen
		fs.toggled.connect(func(on):
			Settings.fullscreen = on
			Settings.apply()
			Settings.save_settings())
		_row(disp, "Fullscreen", "Fill the whole screen.", fs)
		var res := OptionButton.new()
		for i in Settings.RESOLUTIONS.size():
			var r: Vector2i = Settings.RESOLUTIONS[i]
			res.add_item("%d x %d" % [r.x, r.y], i)
			if r == Settings.resolution:
				res.select(i)
		res.item_selected.connect(func(i):
			Settings.resolution = Settings.RESOLUTIONS[i]
			Settings.apply()
			Settings.save_settings())
		_row(disp, "Resolution", "Window size when not fullscreen.", res)
	var gfx := OptionButton.new()
	for i in Settings.GRAPHICS.size():
		gfx.add_item(Settings.GRAPHICS[i], i)
	gfx.select(Settings.graphics)
	gfx.item_selected.connect(func(i):
		Settings.graphics = i
		Settings.save_settings()
		Router.toast("Applies next time a scene loads"))
	_row(disp, "Graphics", "Shadows, reflections and fog. Lower it if the game stutters.", gfx)
	if desktop:
		var cap := OptionButton.new()
		for i in Settings.FPS_CAPS.size():
			cap.add_item(Loc.t(Settings.fps_name(Settings.FPS_CAPS[i])), i)
			if Settings.FPS_CAPS[i] == Settings.fps_cap:
				cap.select(i)
		cap.item_selected.connect(func(i):
			Settings.fps_cap = Settings.FPS_CAPS[i]
			Settings.apply_fps()
			Settings.save_settings())
		_row(disp, "Frame rate", "Unlimited runs as fast as your computer can. A cap keeps it cooler and quieter.", cap)
	var fps := CheckButton.new()
	fps.button_pressed = Settings.show_fps
	fps.toggled.connect(func(on):
		Settings.show_fps = on
		Settings.save_settings())
	_row(disp, "Show FPS", "A frame counter in the corner.", fps)

	var aud := _card(p, "Audio", "♪", Color("ff8ac0"))
	_row(aud, "Master", "", _slider(Settings.master_volume, func(v): Settings.master_volume = v))
	_row(aud, "Music", "", _slider(Settings.music_volume, func(v): Settings.music_volume = v))
	_row(aud, "Effects", "Cards, attacks, the crowd.", _slider(Settings.sfx_volume, func(v): Settings.sfx_volume = v))

	var game := _card(p, "Gameplay", "⚔", Color("ffd166"))
	var lang := OptionButton.new()
	lang.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for i in Loc.LANGS.size():
		lang.add_item(Loc.LANGS[i][1], i)
		if Loc.LANGS[i][0] == Settings.language:
			lang.select(i)
	lang.item_selected.connect(func(i):
		Settings.language = Loc.LANGS[i][0]
		Settings.apply()
		Settings.save_settings()
		# Everything on screen was built in the old language: reload the scene.
		Router.go(parent.get_tree().current_scene.scene_file_path))
	_row(game, "Language / Idioma", "", lang)
	var speed := OptionButton.new()
	var keys: Array = Settings.ANIM_SPEEDS.keys()
	for i in keys.size():
		speed.add_item(keys[i], i)
		if is_equal_approx(Settings.ANIM_SPEEDS[keys[i]], Settings.anim_speed):
			speed.select(i)
	speed.item_selected.connect(func(i):
		Settings.anim_speed = Settings.ANIM_SPEEDS[keys[i]]
		Settings.save_settings())
	_row(game, "Animation speed", "How fast cards and attacks play out.", speed)
	var field := OptionButton.new()
	var fkeys := ["auto"] + FieldThemes.ORDER
	for i in fkeys.size():
		var k: String = fkeys[i]
		field.add_item("Opponent's home field" if k == "auto" else FieldThemes.THEMES[k]["name"], i)
		if k == Settings.field_theme:
			field.select(i)
	field.item_selected.connect(func(i):
		Settings.field_theme = fkeys[i]
		Settings.save_settings())
	_row(game, "Duel field", "Where duels are played when the duel itself does not say.", field)

	# Sleeves: the back of your own cards in every duel.
	var sl := _card(p, "Card sleeves", "❖", Color("b98cff"))
	var sl_hint := UITheme.label("The back of your cards in a duel. Opponents use their own ace monster.", 15, UITheme.TEXT_DIM)
	sl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.add_child(sl_hint)
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	sl.add_child(grid)
	var picks: Array = []
	for e in Cards.sleeves():
		var sid := str(e["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(104, 172)
		b.toggle_mode = true
		b.button_pressed = sid == Settings.sleeve
		b.tooltip_text = Loc.t(str(e["name"]))
		var nb := UITheme.button_box(Color(0.073, 0.172, 0.441, 0.9), Color(1, 1, 1, 0.12), 12)
		var on := UITheme.button_box(Color(0.15, 0.198, 0.522, 0.95), Color("ffd98a"), 12)
		on.set_border_width_all(3)
		b.add_theme_stylebox_override("normal", nb)
		b.add_theme_stylebox_override("hover", UITheme.button_box(Color(0.106, 0.21, 0.486, 0.95), Color("b98cff"), 12))
		b.add_theme_stylebox_override("pressed", on)
		b.add_theme_stylebox_override("focus", UITheme.button_box(Color(0, 0, 0, 0), Color("b98cff"), 12))
		var tr := TextureRect.new()
		tr.texture = Cards.sleeve_texture(sid)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.position = Vector2(8, 8)
		tr.size = Vector2(88, 128)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tr)
		var nm := UITheme.label(Loc.t(str(e["name"])), 12, UITheme.TEXT_DIM)
		nm.position = Vector2(4, 140)
		nm.size = Vector2(96, 28)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
		b.pressed.connect(func():
			Settings.sleeve = sid
			Settings.save_settings()
			for other in picks:
				(other[0] as Button).button_pressed = str(other[1]) == sid
			Sfx.play("card", -6.0))
		picks.append([b, sid])
		grid.add_child(b)

	var art := _card(p, "Card art", "▤", Color("3ddc97"))
	var folder := LineEdit.new()
	folder.text = Settings.card_folder
	folder.text_submitted.connect(func(t):
		Settings.card_folder = t.strip_edges()
		Settings.save_settings()
		Cards.clear_cache()
		Portraits.clear_cache()
		Router.toast("Card folder saved"))
	_row(art, "Folder", "Where your card pictures live. Press Enter to save.", folder)
	var status := UITheme.label("", 16, UITheme.TEXT_DIM)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = ("Real card images found." if Cards.has_real_images()
			else "No card images found, using placeholders. Run tools/fetch_cards.py with --out pointing at this folder.")
	art.add_child(status)
	var back_hint := UITheme.label("Put a picture named back.jpg in this folder and it becomes the back of every card.", 16, UITheme.TEXT_DIM)
	back_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art.add_child(back_hint)

	parent.add_child(p)
	return p


static func _slider(value: float, setter: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = value
	s.custom_minimum_size = Vector2(300, 32)
	s.value_changed.connect(func(v):
		setter.call(v)
		Settings.apply()
		Settings.save_settings())
	return s
