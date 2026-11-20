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
	var tl := UITheme.label(title, 22, UITheme.TEXT)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # (a long title wraps instead of pushing the control off the panel)
	tl.custom_minimum_size = Vector2(120, 0)
	words.add_child(tl)
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
	p.z_index = 100   # over whatever screen opened it (a duel's hand cards sit high)
	p.body.add_theme_constant_override("separation", 16)
	var desktop := OS.has_feature("pc")

	# General: the language, starting over, admin mode.
	var gen := _card(p, "General", "◈", Color("9cf0c8"))
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
	_row(gen, "Language / Idioma", "", lang)
	SavesUI.settings_block(func(title, help, control): _row(gen, title, help, control), parent)

	var disp := _card(p, "Display", "▣", Color("7cc4ff"))
	if desktop:
		var fs := CheckButton.new()
		fs.button_pressed = Settings.fullscreen
		_row(disp, "Fullscreen", "Fill the whole screen.", fs)
		# One Resolution box for both modes. In a window it is the window's size. In fullscreen it is
		# the size the 3D picture is drawn at (the screen keeps its own resolution, so menus and
		# text stay sharp), and the line under it shows the size in use.
		var res := OptionButton.new()
		_row(disp, "Resolution", "Window size.", res)
		var res_hint: Label = res.get_parent().get_child(0).get_child(1)
		var res_note := func():
			if not is_instance_valid(res_hint):
				return
			if Settings.fullscreen:
				var rs := Settings.render_size()
				res_hint.text = Loc.t("The 3D picture is drawn at %d x %d now. Lower runs faster; menus and text stay sharp.") % [rs.x, rs.y]
			else:
				res_hint.text = Loc.t("Window size.")
		var res_fill := func():
			res.clear()
			if Settings.fullscreen:
				res.add_item(Loc.t("Native (your screen)"), 0)
				res.select(0)
			for i in Settings.RESOLUTIONS.size():
				var r: Vector2i = Settings.RESOLUTIONS[i]
				res.add_item("%d x %d" % [r.x, r.y], i + 1)
				if r == (Settings.fs_resolution if Settings.fullscreen else Settings.resolution):
					res.select(res.item_count - 1)
			res_note.call()
		var res_later := func():
			# The window and the 3D scale settle a moment after a change.
			if p.is_inside_tree():
				p.get_tree().create_timer(0.35).timeout.connect(res_note)
		res_fill.call()
		res_later.call()
		res.item_selected.connect(func(at):
			var id := res.get_item_id(at)
			if Settings.fullscreen:
				Settings.fs_resolution = Vector2i.ZERO if id == 0 else Settings.RESOLUTIONS[id - 1]
			else:
				Settings.resolution = Settings.RESOLUTIONS[id - 1]
			Settings.apply()
			Settings.save_settings()
			res_note.call()
			res_later.call())
		fs.toggled.connect(func(on):
			Settings.fullscreen = on
			Settings.apply()
			Settings.save_settings()
			res_fill.call()
			res_later.call())
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
		_row(disp, "Frame rate cap", "Unlimited runs as fast as your computer can. A cap keeps it cooler and quieter.", cap)
		var vs := CheckButton.new()
		vs.button_pressed = Settings.vsync
		vs.toggled.connect(func(on):
			Settings.vsync = on
			Settings.apply_fps()
			Settings.save_settings())
		_row(disp, "V-Sync", "Waits for the screen before showing each picture, so the picture never tears. The game then runs at your screen's rate at most. Works together with the cap: 60 FPS with V-Sync on is a steady 60.", vs)
	var fps := CheckButton.new()
	fps.button_pressed = Settings.show_fps
	fps.toggled.connect(func(on):
		Settings.show_fps = on
		Settings.save_settings())
	_row(disp, "Show FPS", "A frame counter in the corner. Press F3 any time for the full readout: where the time goes.", fps)
	var hold := CheckButton.new()
	hold.button_pressed = Settings.hold_fps
	hold.toggled.connect(func(on):
		Settings.hold_fps = on
		Settings.hold_gave_up = false
		Settings.auto_k = 1.0
		Settings.apply_graphics()
		Settings.save_settings())
	_row(disp, "Hold 60 FPS (can blur the picture)", "Off by default. Warning: when it is on and the game cannot reach 60, the 3D picture is drawn smaller and looks soft or blurry. It never goes under 1080 lines, and it puts the picture back when being smaller does not make the game faster. If the game looks blurry, turn this off first.", hold)

	_graphics_card(p)

	var aud := _card(p, "Audio", "♪", Color("ff8ac0"))
	_row(aud, "Master", "", _slider(Settings.master_volume, func(v): Settings.master_volume = v))
	_row(aud, "Music", "", _slider(Settings.music_volume, func(v): Settings.music_volume = v))
	_row(aud, "Effects", "Cards, attacks, the crowd.", _slider(Settings.sfx_volume, func(v): Settings.sfx_volume = v))
	# Voices in duels: one switch for all of them, then who talks.
	var mk_switch := func(on: bool, setter: Callable) -> CheckButton:
		var cb := CheckButton.new()
		cb.button_pressed = on
		cb.toggled.connect(func(v):
			setter.call(v)
			if not v:
				Voices.hush(true)
			Settings.save_settings())
		return cb
	_row(aud, "Voices", "Duelists, Lumen and the narrator of the opening say their lines out loud. Turn it off and the lines are only text, like before.", mk_switch.call(Settings.voices_on, func(v): Settings.voices_on = v))
	_row(aud, "Voice volume", "", _slider(Settings.voice_volume, func(v): Settings.voice_volume = v))
	_row(aud, "Opponents' voices", "", mk_switch.call(Settings.voice_opp, func(v): Settings.voice_opp = v))
	var lum := OptionButton.new()
	for i in 4:
		lum.add_item(Loc.t(["Warm", "Bright", "Calm", "No voice"][i]), i)
	lum.select(int(Settings.voice_lumen))
	lum.item_selected.connect(func(i):
		Settings.voice_lumen = i
		Settings.save_settings()
		Voices.hush(true)
		if i != 3:
			Voices.say("lumen", "Lumen, reporting for duty! Small but mighty!", true))
	_row(aud, "Lumen's voice", "Three voices to pick from, or none: she still shows what she says. Pick one and you hear it.", lum)
	var mine := OptionButton.new()
	for i in 6:
		mine.add_item(Loc.t(["Fits my duelist's look", "Male A", "Male B", "Female A", "Female B", "No voice"][i]), i)
	mine.select(int(Settings.voice_me))
	mine.item_selected.connect(func(i):
		Settings.voice_me = i
		Settings.save_settings()
		Voices.hush(true)
		if i != 5:
			Voices.say("player", "Let's do this.", true))
	_row(aud, "My duelist's voice", "Your duelist calls out the turn, the cards and the attacks. Pick one and you hear it.", mine)
	var talk := OptionButton.new()
	for i in 3:
		talk.add_item(Loc.t(["Some", "Normal", "A lot"][i]), i)
	talk.select(Settings.talk)
	talk.item_selected.connect(func(i):
		Settings.talk = i
		Settings.save_settings())
	_row(aud, "How much they talk", "Some: only the big moments. Normal: the draw, the battle and the end of the turn too. A lot: every card and every attack is called out, like in the shows.", talk)

	var game := _card(p, "Gameplay", "⚔", Color("ffd166"))
	_row(game, "Mouse camera speed", "In the worlds, hold the right mouse button and drag to turn the camera.", _pad_slider(Settings.mouse_sens, func(v): Settings.mouse_sens = v))
	var mi := CheckButton.new()
	mi.button_pressed = Settings.mouse_invert
	mi.toggled.connect(func(on):
		Settings.mouse_invert = on
		Settings.save_settings())
	_row(game, "Invert mouse up and down", "", mi)
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
	var bs := CheckButton.new()
	bs.button_pressed = Settings.big_shows
	bs.toggled.connect(func(on):
		Settings.big_shows = on
		Settings.save_settings())
	var cs := CheckButton.new()
	cs.button_pressed = Settings.card_showcase
	cs.toggled.connect(func(on):
		Settings.card_showcase = on
		Settings.save_settings())
	var op := CheckButton.new()
	op.button_pressed = Settings.opening
	op.toggled.connect(func(on):
		Settings.opening = on
		Settings.save_settings())
	_row(game, "Opening when the game starts", "The short flight over the four worlds before the menu. Any key skips it.", op)
	_row(game, "Show activated cards big", "Off: a Spell or Trap goes straight into what it does, with a line at the top saying what it is. On: the duel stops to show the card in the middle first.", cs)
	_row(game, "Big summon and attack scenes", "The full-screen scene when a strong monster arrives or attacks. Turn it off if a duel freezes or closes there.", bs)
	var lp := CheckButton.new()
	lp.button_pressed = Settings.live_portraits
	lp.toggled.connect(func(on):
		Settings.live_portraits = on
		Settings.save_settings())
	_row(game, "Live duelists in the corners", "On: the two duelists next to the Life Points are the real 3D duelists, moving and reacting all through the duel. Off: still pictures, like before. Takes effect in the next duel.", lp)
	# The looks at the duelists (0.63.0): how often the camera leaves the table for one of them.
	var cuts := OptionButton.new()
	for i in 3:
		cuts.add_item(Loc.t(["Full", "Fewer", "Off"][i]), i)
	cuts.select(Settings.cam_cuts)
	cuts.item_selected.connect(func(i):
		Settings.cam_cuts = i
		Settings.save_settings())
	_row(game, "Camera cuts", "A short look at a duelist at the big moments: an ace summon, a Trap, a direct attack. Full: all of them, never more than one every few seconds. Fewer: only an ace and a direct attack. Off: the camera stays on the table.", cuts)
	var beat := OptionButton.new()
	for i in 3:
		beat.add_item(Loc.t(["Full", "Brief", "Off"][i]), i)
	beat.select(Settings.turn_beat)
	beat.item_selected.connect(func(i):
		Settings.turn_beat = i
		Settings.save_settings())
	_row(game, "Turn beat", "Each turn opens with a moment on the duelist whose turn it is: they call it and draw. Full: about a second, shorter from the fourth turn on. Brief: always the short one. Off: straight to the table.", beat)
	var crowd := CheckButton.new()
	crowd.button_pressed = Settings.crowd_cam
	crowd.toggled.connect(func(on):
		Settings.crowd_cam = on
		Settings.save_settings())
	_row(game, "Crowd camera", "After a hit of 2000 or more, the camera looks at the people watching for a second before it goes back to the field. At most once every 30 seconds. Off: the camera stays on the duel.", crowd)
	var asks := CheckButton.new()
	asks.button_pressed = Settings.ask_always
	asks.toggled.connect(func(on):
		Settings.ask_always = on
		Settings.save_settings())
	_row(game, "Ask me at every chance", "Off: a duel only stops to ask you when your opponent does something one of your cards can answer. On: it also stops in every phase and after your own plays. The same switch is on the duel screen.", asks)
	var fate := CheckButton.new()
	fate.button_pressed = Settings.destiny_draw
	fate.toggled.connect(func(on):
		Settings.destiny_draw = on
		Settings.save_settings())
	_row(game, "Destiny Draw", "Once per duel, when you are at 2000 Life Points or less (or under half of your opponent's), you may choose the card you draw. The strongest opponents can do it too.", fate)
	var brain := OptionButton.new()
	for i in 3:
		brain.add_item(["Normal", "Hard", "Extreme"][i], i)
	brain.select(clampi(Settings.cpu_level, 1, 3) - 1)
	brain.item_selected.connect(func(i):
		Settings.cpu_level = i + 1
		Settings.save_settings())
	_row(game, "Opponent difficulty", "How every opponent in Story and in the worlds thinks. Normal looks a little ahead and sometimes slips. Hard plans its turn and checks what you could answer. Extreme tries more plays for longer. None of them looks at your hand or face-down cards. Free Duel has its own buttons.", brain)
	_row(game, "Credits", "Made by Atlas Peak Games. The duel rules run on ocgcore by Edoardo Lolletti (edo9300), and every card plays by its script from Project Ignis. Both are free software under the AGPL-3.0 license. The game is built with the Godot engine.", Control.new())
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
		Sfx.reload_own()
		Music.reload_own()
		Router.toast("Card folder saved"))
	_row(art, "Folder", "Where your card pictures live. Press Enter to save.", folder)
	var status := UITheme.label("", 16, UITheme.TEXT_DIM)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = ("Real card images found." if Cards.has_real_images()
			else "No card images found, using placeholders. Run tools/fetch_cards.py with --out pointing at this folder.")
	art.add_child(status)
	var back_hint := UITheme.label("Put a picture named back.jpg in this folder and it becomes the back of every card. A picture named icon.png becomes the game's icon while it runs. Sound files in a \"sounds\" folder and music in a \"music\" folder (named like the sound or track, .ogg, .wav or .mp3) play instead of the built-in ones.", 16, UITheme.TEXT_DIM)
	back_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art.add_child(back_hint)

	_controller_card(p)

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
	# The tabs wrap onto a second row when they do not fit (seven of them, longer in Spanish).
	var bar := HFlowContainer.new()
	bar.add_theme_constant_override("h_separation", 8)
	bar.add_theme_constant_override("v_separation", 8)
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
		b.add_theme_font_size_override("font_size", 20)
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
		var need := int(e.get("need", -1))
		if need > 0 and Goals.tier() < need and not Saves.admin:
			b.disabled = true
			b.tooltip_text = Loc.t("Reach %s rank to use this sleeve.") % Goals.rank_name(need)
			b.modulate = Color(1, 1, 1, 0.45)
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
	pick.call("upscale", Settings.upscale_names(), "Upscaling", "When the 3D resolution is below your screen's, this rebuilds the missing sharpness. The second choice is cheap, the third looks closest to full resolution." if Settings.upscale_ok() else "Needs the full renderer. On this machine the picture is simply stretched.")
	pick.call("aa", Settings.AA_NAMES, "Edge smoothing", "Takes the stair-steps off edges.")
	pick.call("shadows", Settings.SHADOW_NAMES, "Shadows", "How sharp the sun's shadows are and how far they reach.")
	flip.call("ao", "Soft corner shading", "Darkens corners and the ground under things.")
	flip.call("reflect", "Reflections", "Wet streets and water mirror the world.")
	flip.call("glow", "Glow", "Lights and neon bloom a little.")
	flip.call("fog", "Light haze", "Soft haze in the air and light shafts. Costs a lot.")
	flip.call("gi", "Bounce light", "Light bounces off walls and floors. The most expensive one.")
	pick.call("detail", Settings.DETAIL_NAMES, "Ground detail", "Grass tufts, flowers and pebbles. Shows the next time a place loads.")
	pick.call("people", Settings.PEOPLE_NAMES, "People in the world", "How busy the streets are. Shows the next time a place loads.")
	var test := Button.new()
	test.text = Loc.t("Run the test")
	test.custom_minimum_size = Vector2(220, 44)
	test.pressed.connect(func(): PerfReport.start(p.get_tree()))
	_row(g, "Performance test", "Measures this screen for half a minute and saves a report in your Crossroads folder (reports). F4 runs it anywhere: do it where the game feels slow.", test)
	refresh.call()


## Controller: which button pictures, stick speeds, rumble, and moving any button to another.
static func _controller_card(p: SidePanel) -> void:
	var c := _card(p, "Controller", "◎", Color("7cc4ff"))
	var pads := Input.get_connected_joypads()
	var who := UITheme.label(Loc.t("Connected: %s") % Input.get_joy_name(pads[0]) if not pads.is_empty() else Loc.t("No controller connected. Plug one in or pair it, and it works right away."), 16, UITheme.ACCENT if not pads.is_empty() else UITheme.TEXT_DIM)
	who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.add_child(who)
	var lay := OptionButton.new()
	var lays := [["auto", "Match my controller"], ["xbox", "Xbox"], ["ps", "PlayStation"], ["nintendo", "Nintendo"]]
	for i in lays.size():
		lay.add_item(Loc.t(lays[i][1]), i)
		if lays[i][0] == Settings.pad_layout:
			lay.select(i)
	var remap_rows: Array = []
	var redraw := func():
		for r in remap_rows:
			(r[0] as Button).text = "  %s  " % Pad.g(str(r[1]))
		Pad.hint(Pad._hint_raw)
		Pad.changed.emit()
	lay.item_selected.connect(func(i):
		Settings.pad_layout = lays[i][0]
		Settings.save_settings()
		redraw.call())
	var shw := OptionButton.new()
	var shows := [["auto", "Automatic"], ["keys", "Keyboard & mouse"], ["pad", "Controller"]]
	for i in shows.size():
		shw.add_item(Loc.t(shows[i][1]), i)
		if shows[i][0] == Settings.pad_show:
			shw.select(i)
	shw.item_selected.connect(func(i):
		Settings.pad_show = shows[i][0]
		Settings.save_settings()
		redraw.call())
	_row(c, "Show buttons for", "Automatic: the keyboard's keys, and the controller's buttons as soon as you pick up a controller and press something.", shw)
	_row(c, "Button pictures", "Which names the game shows for the buttons: ✕ ○ □ △ for PlayStation, A B X Y for Xbox.", lay)
	_row(c, "Camera speed", "How fast the right stick turns the camera in the worlds.", _pad_slider(Settings.pad_cam, func(v): Settings.pad_cam = v))
	_row(c, "Pointer speed", "How fast the stick moves the pointer on the duel field and in menus.", _pad_slider(Settings.pad_pointer, func(v): Settings.pad_pointer = v))
	var inv := CheckButton.new()
	inv.button_pressed = Settings.pad_invert
	inv.toggled.connect(func(on):
		Settings.pad_invert = on
		Settings.save_settings())
	_row(c, "Invert camera", "Push the stick up to look down, like a flight game.", inv)
	var rum := CheckButton.new()
	rum.button_pressed = Settings.pad_rumble
	rum.toggled.connect(func(on):
		Settings.pad_rumble = on
		Settings.save_settings()
		if on:
			Pad.rumble(0.3, 0.6, 0.3))
	_row(c, "Vibration", "The controller buzzes when you take a hit, a little when you land one.", rum)
	c.add_child(UITheme.label(Loc.t("Buttons"), 22, UITheme.TEXT))
	var bh := UITheme.label(Loc.t("Press a box, then press the button you want for that job. Two jobs swap buttons, so nothing is ever left without one."), 15, UITheme.TEXT_DIM)
	bh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.add_child(bh)
	var jobs := [["A", "Confirm, talk, enter, select"], ["B", "Back, cancel"], ["X", "Card shop (worlds), next phase (duels), race events"],
		["Y", "Map (worlds), end turn (duels), Grand Prix"], ["LB", "Run (worlds), page left"], ["RB", "Page right"],
		["Back", "Travel to another world, garage"], ["R3", "Show or hide the list of things to do"]]
	for j in jobs:
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(150, 44)
		var job := str(j[0])
		remap_rows.append([bt, job])
		bt.text = "  %s  " % Pad.g(job)
		bt.pressed.connect(func():
			bt.text = Loc.t("Press a button...")
			var catcher := _PadCatch.new()
			bt.add_child(catcher)
			var got: int = await catcher.caught
			catcher.queue_free()
			if got >= 0:
				_assign(job, got)
				Settings.save_settings()
				Pad.apply_map()
				Sfx.play("equip", -6.0)
			redraw.call())
		_row(c, Loc.t(str(j[1])), "", bt)
	var reset := Button.new()
	reset.text = "  %s  " % Loc.t("Reset buttons")
	reset.custom_minimum_size = Vector2(0, 44)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_END
	reset.pressed.connect(func():
		Settings.pad_map = {}
		Settings.save_settings()
		Pad.apply_map()
		redraw.call())
	c.add_child(reset)


## Gives the job `job` (a button by its Xbox name) to the physical button `phys`; the button
## that had the job takes over whatever `phys` did before, so the two swap.
static func _assign(job: String, phys: int) -> void:
	var want := -1
	for b in Pad.BUTTONS:
		if b[1] == job:
			want = int(b[0])
	if want < 0:
		return
	var m: Dictionary = Settings.pad_map.duplicate()
	var old_phys := want
	for k in m:
		if int(m[k]) == want:
			old_phys = int(k)
	var phys_did := int(m.get(phys, phys))
	m[phys] = want
	m[old_phys] = phys_did
	for k in m.keys():
		if int(k) == int(m[k]):
			m.erase(k)
	Settings.pad_map = m


## Catches the next controller button (or Escape / B-less cancel after 6 seconds).
class _PadCatch extends Node:
	signal caught(button: int)
	var _t := 6.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(event: InputEvent) -> void:
		if event is InputEventJoypadButton and event.pressed:
			get_viewport().set_input_as_handled()
			caught.emit(event.button_index)
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			caught.emit(-1)

	func _process(delta: float) -> void:
		_t -= delta
		if _t <= 0.0:
			_t = 999.0
			caught.emit(-1)


static func _pad_slider(value: float, setter: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.4
	s.max_value = 2.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(300, 32)
	s.value_changed.connect(func(v):
		setter.call(v)
		Settings.save_settings())
	return s


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
