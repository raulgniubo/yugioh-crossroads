class_name SettingsPanel
extends RefCounted
## Builds the settings side panel. Used from the main menu and the pause menu.


static func open(parent: Node) -> SidePanel:
	var p := SidePanel.new("Settings")
	var desktop := OS.has_feature("pc")

	if desktop:
		p.add_section("Display")
		var fs := CheckButton.new()
		fs.text = "Fullscreen"
		fs.button_pressed = Settings.fullscreen
		fs.toggled.connect(func(on):
			Settings.fullscreen = on
			Settings.apply()
			Settings.save_settings())
		p.add_row("Window", fs)
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
		p.add_row("Resolution", res)

	p.add_section("Language")
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
	p.add_row("Language / Idioma", lang)

	var gfx := OptionButton.new()
	for i in Settings.GRAPHICS.size():
		gfx.add_item(Settings.GRAPHICS[i], i)
	gfx.select(Settings.graphics)
	gfx.item_selected.connect(func(i):
		Settings.graphics = i
		Settings.save_settings()
		Router.toast("Applies next time a scene loads"))
	p.add_row("Graphics", gfx)

	var fps := CheckButton.new()
	fps.text = "Show FPS"
	fps.button_pressed = Settings.show_fps
	fps.toggled.connect(func(on):
		Settings.show_fps = on
		Settings.save_settings())
	p.add_row("Performance", fps)

	p.add_section("Audio")
	p.add_row("Master", _slider(Settings.master_volume, func(v): Settings.master_volume = v))
	p.add_row("Music", _slider(Settings.music_volume, func(v): Settings.music_volume = v))
	p.add_row("Effects", _slider(Settings.sfx_volume, func(v): Settings.sfx_volume = v))

	p.add_section("Gameplay")
	var speed := OptionButton.new()
	var keys: Array = Settings.ANIM_SPEEDS.keys()
	for i in keys.size():
		speed.add_item(keys[i], i)
		if is_equal_approx(Settings.ANIM_SPEEDS[keys[i]], Settings.anim_speed):
			speed.select(i)
	speed.item_selected.connect(func(i):
		Settings.anim_speed = Settings.ANIM_SPEEDS[keys[i]]
		Settings.save_settings())
	p.add_row("Animation speed", speed)
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
	p.add_row("Duel field", field)

	p.add_section("Card art")
	var folder := LineEdit.new()
	folder.text = Settings.card_folder
	folder.text_submitted.connect(func(t):
		Settings.card_folder = t.strip_edges()
		Settings.save_settings()
		Cards.clear_cache()
		Portraits.clear_cache()
		Router.toast("Card folder saved"))
	p.add_row("Folder", folder)
	var status := UITheme.label("", 17, UITheme.TEXT_DIM)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = ("Real card images found." if Cards.has_real_images()
			else "No card images found, using placeholders. Run tools/fetch_cards.py with --out pointing at this folder.")
	p.body.add_child(status)

	parent.add_child(p)
	return p


static func _slider(value: float, setter: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = value
	s.custom_minimum_size = Vector2(240, 32)
	s.value_changed.connect(func(v):
		setter.call(v)
		Settings.apply()
		Settings.save_settings())
	return s
