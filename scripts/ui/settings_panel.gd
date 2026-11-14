class_name SettingsPanel
extends RefCounted
## Builds the settings side panel. Used from the main menu and the pause menu.


## One block of settings: a titled card with rows inside.
static func _card(p: SidePanel, title: String, glyph: String, tint: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.072, 0.108, 0.196, 0.9)
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
	pc.set_meta("tab", title)
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

	_graphics_card(p)

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

	_tabs(p)
	parent.add_child(p)
	return p


## One section on screen at a time, picked from a row of tabs across the top. The panel
## remembers which one you were on.
static var _tab_at := {}


static func _tabs(p: SidePanel, store := "settings") -> void:
	var cards: Array = p.body.get_children()
	if cards.size() < 2:
		return
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	p.body.add_child(bar)
	p.body.move_child(bar, 0)
	var btns: Array = []
	var show := func(i: int):
		_tab_at[store] = i
		for k in cards.size():
			(cards[k] as Control).visible = k == i
			(btns[k] as Button).set_pressed_no_signal(k == i)
	for i in cards.size():
		var b := Button.new()
		b.toggle_mode = true
		b.text = str((cards[i] as Control).get_meta("tab", "Section"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 46)
		b.pressed.connect(show.bind(i))
		bar.add_child(b)
		btns.append(b)
	show.call(clampi(int(_tab_at.get(store, 0)), 0, cards.size() - 1))


## Your own things, opened from the profile bar on the home screen: the duelist you play as,
## and what your cards look like.
static func open_profile(parent: Node, edit_character: Callable) -> SidePanel:
	var p := SidePanel.new("My duelist", 820)
	p.body.add_theme_constant_override("separation", 16)
	var who := _card(p, "Character", "◉", Color("7cc4ff"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	who.add_child(row)
	var face := TextureRect.new()
	face.texture = Portraits.get_portrait("player")
	face.custom_minimum_size = Vector2(190, 238)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.clip_contents = true
	row.add_child(face)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 6)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	words.add_child(UITheme.label(Profile.duelist_name, 40, UITheme.TEXT, UITheme.title_font()))
	words.add_child(UITheme.label(Profile.title_text(), 20, UITheme.ACCENT, UITheme.semi_font()))
	words.add_child(UITheme.label(Loc.t("Level %d   ·   %d wins   ·   %d losses") % [Profile.level(), Profile.wins, Profile.losses], 18, UITheme.TEXT_DIM))
	words.add_child(UITheme.label(Loc.t("%d Duel Points") % Collection.dp, 18, UITheme.GOLD))
	var edit := Button.new()
	edit.text = "Edit my character"
	edit.custom_minimum_size = Vector2(0, 54)
	UITheme.paint_button(edit, UITheme.ACCENT)
	edit.pressed.connect(func():
		p.close()
		edit_character.call())
	words.add_child(edit)
	var hint := UITheme.label("Name, body, hair, outfit, height, color and title.", 15, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(hint)
	who.get_parent().set_meta("tab", "Character")
	_sleeves_card(p)
	_tabs(p, "profile")
	parent.add_child(p)
	return p


## Sleeves: the back of your own cards in every duel.
static func _sleeves_card(p: SidePanel) -> void:
	var sl := _card(p, "Card sleeves", "❖", Color("b98cff"))
	var sl_hint := UITheme.label("The back of your cards in a duel. Opponents use their own ace monster.", 15, UITheme.TEXT_DIM)
	sl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.add_child(sl_hint)
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	sl.add_child(grid)
	var picks: Array = []
	var thumbs: Array = []       # filled in a few at a time once the panel is on screen
	for e in Cards.sleeves():
		var sid := str(e["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(120, 178)
		b.toggle_mode = true
		b.clip_contents = true
		b.button_pressed = sid == Settings.sleeve
		b.tooltip_text = Loc.t(str(e["name"]))
		var nb := UITheme.button_box(Color(0.042, 0.0676, 0.136, 0.9), Color(1, 1, 1, 0.12), 12)
		var on := UITheme.button_box(Color(0.112, 0.088, 0.225, 0.95), Color("ffd98a"), 12)
		on.set_border_width_all(3)
		b.add_theme_stylebox_override("normal", nb)
		b.add_theme_stylebox_override("hover", UITheme.button_box(Color(0.072, 0.098, 0.185, 0.95), Color("b98cff"), 12))
		b.add_theme_stylebox_override("pressed", on)
		b.add_theme_stylebox_override("focus", UITheme.button_box(Color(0, 0, 0, 0), Color("b98cff"), 12))
		var tr := TextureRect.new()
		thumbs.append([tr, sid])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tr)
		tr.position = Vector2(16, 8)
		tr.size = Vector2(88, 128)
		# The name stays inside its own tile: two short lines, cut with "..." if it is longer.
		var nm := UITheme.label(Loc.t(str(e["name"])), 13, UITheme.TEXT_DIM, UITheme.semi_font())
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.max_lines_visible = 2
		nm.add_theme_constant_override("line_spacing", -3)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nm.clip_contents = true
		b.add_child(nm)
		nm.position = Vector2(6, 138)
		nm.size = Vector2(108, 34)
		b.pressed.connect(func():
			Settings.sleeve = sid
			Settings.save_settings()
			for other in picks:
				(other[0] as Button).button_pressed = str(other[1]) == sid
			Sfx.play("card", -6.0))
		picks.append([b, sid])
		grid.add_child(b)

	sl.get_parent().set_meta("tab", "Card sleeves")
	_fill_thumbs(p, thumbs)


## The sleeve pictures load after the panel is already open, so opening it is instant.
static func _fill_thumbs(p: SidePanel, thumbs: Array) -> void:
	if not p.is_inside_tree():
		await p.tree_entered
	await p.get_tree().process_frame
	for t in thumbs:
		if not is_instance_valid(p) or not is_instance_valid(t[0]):
			return
		(t[0] as TextureRect).texture = Cards.sleeve_texture(str(t[1]))
		await p.get_tree().process_frame


## Graphics: a preset on top, then every effect on its own switch. Touch one and the preset
## reads "Custom"; pick a preset and every switch moves to match.
static func _graphics_card(p: SidePanel) -> void:
	var g := _card(p, "Graphics", "◆", Color("ffb62e"))
	var sync: Array = []         # callables that re-read the settings into the controls
	var preset := OptionButton.new()
	for i in Settings.GFX_PRESET_NAMES.size():
		preset.add_item(Settings.GFX_PRESET_NAMES[i], i)
	preset.add_item("Custom", 9)
	var refresh := func():
		for c in sync:
			(c as Callable).call()
	sync.append(func():
		preset.select(Settings.gfx_preset if Settings.gfx_preset >= 0 else Settings.GFX_PRESET_NAMES.size()))
	preset.item_selected.connect(func(i):
		if i < Settings.GFX_PRESET_NAMES.size():
			Settings.set_gfx_preset(i)
			Settings.save_settings()
		refresh.call())
	_row(g, "Preset", "Low is the fastest, Ultra the prettiest. If the game feels slow, go down one step.", preset)
	var pick := func(key: String, names: Array, title: String, hint: String):
		var ob := OptionButton.new()
		for i in names.size():
			ob.add_item(str(names[i]), i)
		sync.append(func(): ob.select(clampi(int(Settings.gfx[key]), 0, names.size() - 1)))
		ob.item_selected.connect(func(i):
			Settings.set_gfx(key, i)
			Settings.save_settings()
			refresh.call())
		_row(g, title, hint, ob)
	var flip := func(key: String, title: String, hint: String):
		var cb := CheckButton.new()
		sync.append(func(): cb.set_pressed_no_signal(bool(Settings.gfx[key])))
		cb.toggled.connect(func(on):
			Settings.set_gfx(key, on)
			Settings.save_settings()
			refresh.call())
		_row(g, title, hint, cb)
	pick.call("res", Settings.RES_NAMES, "3D resolution", "How sharp the 3D picture is. The biggest speed gain on Retina and 4K screens. Menus and text always stay sharp.")
	pick.call("aa", Settings.AA_NAMES, "Edge smoothing", "Takes the stair-steps off edges.")
	pick.call("shadows", Settings.SHADOW_NAMES, "Shadows", "How sharp the sun's shadows are and how far they reach.")
	flip.call("ao", "Soft corner shading", "Darkens corners and the ground under things.")
	flip.call("reflect", "Reflections", "Wet streets and water mirror the world.")
	flip.call("glow", "Glow", "Lights and neon bloom a little.")
	flip.call("fog", "Light haze", "Soft haze in the air and light shafts. Costs a lot.")
	flip.call("gi", "Bounce light", "Light bounces off walls and floors. The most expensive one.")
	pick.call("detail", Settings.DETAIL_NAMES, "Ground detail", "Grass tufts, flowers and pebbles. Shows the next time a place loads.")
	pick.call("people", Settings.PEOPLE_NAMES, "People in the world", "How busy the streets are. Shows the next time a place loads.")
	refresh.call()


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
