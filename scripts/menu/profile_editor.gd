class_name ProfileEditor
extends Control
## Create or edit your duelist. A full-body 3D preview on the left turns as you choose a body,
## a hairstyle, an outfit and your signature color. Every change shows at once, here and in the
## world behind the editor.

signal closed

var _first_time := false
var _name_edit: LineEdit
var _vp: SubViewport
var _stage: Node3D
var _figure: RoamFigure
var _spin := 0.35
var _auto_spin := true
var _drag := false
var _rows := {}          # key -> [buttons]
var _hair_row: HBoxContainer
var _summary: Label
var _before := {}


func _init(first_time := false) -> void:
	_first_time = first_time


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_before = {"name": Profile.duelist_name, "body": Profile.look_body, "hair": Profile.look_hair,
			"outfit": Profile.look_outfit, "color": Profile.color_index, "gender": Profile.gender,
			"height": Profile.look_height, "title": Profile.title, "intro": Profile.intro, "win": Profile.win_line, "sleeve": Settings.sleeve}
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.062, 0.118, 0.302, 0.97), 26, Color(UITheme.ACCENT, 0.3)))
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 36)
	panel.add_child(h)
	h.add_child(_build_preview())
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.custom_minimum_size = Vector2(720, 0)
	h.add_child(right)
	right.add_child(UITheme.label("NEW DUELIST" if _first_time else "YOUR DUELIST", 54, Color.WHITE, UITheme.title_font()))
	right.add_child(UITheme.label("This is you in the story, the cities and every duel.", 19, UITheme.TEXT_DIM))
	# Everything you can change scrolls; the buttons under it stay put.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(720, 640)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	v.add_child(_section("NAME"))
	_name_edit = LineEdit.new()
	_name_edit.text = "" if _first_time else Profile.duelist_name
	_name_edit.placeholder_text = "Your duelist name"
	_name_edit.max_length = 16
	_name_edit.add_theme_font_size_override("font_size", 28)
	_name_edit.text_changed.connect(func(_t): _refresh())
	v.add_child(_name_edit)
	_choice_row(v, "body", "BODY", ["Type A", "Type B"], func(i):
		Profile.look_body = i
		Profile.gender = i
		_fill_hair())
	v.add_child(_section("HAIR"))
	_hair_row = HBoxContainer.new()
	_hair_row.add_theme_constant_override("separation", 10)
	v.add_child(_hair_row)
	_fill_hair()
	_choice_row(v, "outfit", "OUTFIT", Profile.HERO_OUTFITS, func(i): Profile.look_outfit = i)
	var hnames: Array = []
	for hh in Profile.HEIGHTS:
		hnames.append(str(hh[0]))
	_choice_row(v, "height", "HEIGHT", hnames, func(i): Profile.look_height = i)
	v.add_child(_section("SIGNATURE COLOR   ·   repaints your outfit and hair streak"))
	var cr := HFlowContainer.new()
	cr.add_theme_constant_override("h_separation", 10)
	cr.add_theme_constant_override("v_separation", 10)
	v.add_child(cr)
	var cbtns: Array = []
	for i in Profile.COLORS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(50, 50)
		b.toggle_mode = true
		b.tooltip_text = Profile.COLOR_NAMES[i]
		var c: Color = Profile.COLORS[i]
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			var sb := UITheme.button_box(c, Color.WHITE if st in ["pressed", "hover_pressed", "focus"] else Color(c, 0.0), 25)
			sb.set_border_width_all(4)
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func():
			Profile.color_index = i
			_changed())
		cr.add_child(b)
		cbtns.append(b)
	_rows["color"] = cbtns
	# Who you are on the name plate, and what you say.
	v.add_child(_section("TITLE   ·   shown under your name"))
	var title_pick := OptionButton.new()
	title_pick.custom_minimum_size = Vector2(0, 48)
	for i in Profile.TITLES.size():
		var open := Profile.title_open(i)
		var text := Loc.t("Duelist Lv %d  (your level)") % Profile.level() if i == 0 else Loc.t(str(Profile.TITLES[i][0]))
		title_pick.add_item(text if open else text + Loc.t("   (locked)"), i)
		title_pick.set_item_disabled(i, not open)
	title_pick.select(Profile.title if Profile.title_open(Profile.title) else 0)
	title_pick.item_selected.connect(func(i):
		Profile.title = i
		_soft_change())
	v.add_child(title_pick)
	v.add_child(_section("OPENING LINE   ·   what you say when a duel starts"))
	var intro_pick := OptionButton.new()
	intro_pick.custom_minimum_size = Vector2(0, 48)
	for i in Profile.INTROS.size():
		intro_pick.add_item(Loc.t("Surprise me each time") if i == 0 else Loc.t(str(Profile.INTROS[i])), i)
	intro_pick.select(Profile.intro)
	intro_pick.item_selected.connect(func(i):
		Profile.intro = i
		_soft_change())
	v.add_child(intro_pick)
	v.add_child(_section("VICTORY LINE"))
	var win_pick := OptionButton.new()
	win_pick.custom_minimum_size = Vector2(0, 48)
	for i in Profile.WINS.size():
		win_pick.add_item(Loc.t("Surprise me each time") if i == 0 else Loc.t(str(Profile.WINS[i])), i)
	win_pick.select(Profile.win_line)
	win_pick.item_selected.connect(func(i):
		Profile.win_line = i
		_soft_change())
	v.add_child(win_pick)
	v.add_child(_section("CARD SLEEVE   ·   the back of your cards"))
	var sl_scroll := ScrollContainer.new()
	sl_scroll.custom_minimum_size = Vector2(0, 150)
	sl_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sl_scroll)
	var sl_row := HBoxContainer.new()
	sl_row.add_theme_constant_override("separation", 10)
	sl_scroll.add_child(sl_row)
	var sl_btns: Array = []
	for e in Cards.sleeves():
		var sid := str(e["id"])
		var sbn := Button.new()
		sbn.custom_minimum_size = Vector2(88, 128)
		sbn.toggle_mode = true
		sbn.button_pressed = sid == Settings.sleeve
		sbn.tooltip_text = Loc.t(str(e["name"]))
		sbn.add_theme_stylebox_override("normal", UITheme.button_box(Color(0.054, 0.0996, 0.277, 0.9), Color(1, 1, 1, 0.12), 10))
		var son := UITheme.button_box(Color(0.11, 0.118, 0.353, 0.95), Color("ffd98a"), 10)
		son.set_border_width_all(3)
		sbn.add_theme_stylebox_override("pressed", son)
		var st := TextureRect.new()
		st.texture = Cards.sleeve_texture(sid)
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		st.position = Vector2(7, 7)
		st.size = Vector2(74, 114)
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sbn.add_child(st)
		sbn.pressed.connect(func():
			Settings.sleeve = sid
			for other in sl_btns:
				(other[0] as Button).set_pressed_no_signal(str(other[1]) == sid)
			Sfx.play("card", -8.0))
		sl_btns.append([sbn, sid])
		sl_row.add_child(sbn)
	_summary = UITheme.label("", 18, UITheme.GOLD, UITheme.semi_font())
	right.add_child(_summary)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	right.add_child(row)
	if not _first_time:
		var cancel := Button.new()
		cancel.text = "Cancel"
		cancel.custom_minimum_size = Vector2(0, 60)
		cancel.pressed.connect(_cancel)
		row.add_child(cancel)
	var rnd := Button.new()
	rnd.text = "Surprise me"
	rnd.custom_minimum_size = Vector2(0, 60)
	rnd.pressed.connect(func():
		Profile.look_body = randi() % 2
		Profile.gender = Profile.look_body
		Profile.look_hair = randi() % 2
		Profile.look_outfit = randi() % 3
		Profile.color_index = randi() % Profile.COLORS.size()
		Profile.look_height = randi() % Profile.HEIGHTS.size()
		_fill_hair()
		_changed())
	row.add_child(rnd)
	var save := Button.new()
	save.text = "Start my journey" if _first_time else "Save"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size = Vector2(0, 60)
	save.add_theme_font_size_override("font_size", 28)
	save.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.3), UITheme.ACCENT, 14))
	save.pressed.connect(_save)
	row.add_child(save)
	_rebuild_figure()
	_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	await get_tree().process_frame
	_name_edit.grab_focus()


# ------------------------------------------------------------------ 3D preview

func _build_preview() -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(520, 760)
	# A bright stage behind the figure, so the duelist is the lightest thing on the card.
	var fsb := UITheme.panel_box(Color(0.14, 0.4, 0.9, 1), 22, Color(1, 1, 1, 0.1))
	fsb.set_content_margin_all(0)
	frame.add_theme_stylebox_override("panel", fsb)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_STOP
	svc.gui_input.connect(_on_preview_input)
	svc.mouse_default_cursor_shape = Control.CURSOR_DRAG
	frame.add_child(svc)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	svc.add_child(_vp)
	_stage = Node3D.new()
	_vp.add_child(_stage)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.82, 0.88, 1.0)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	_stage.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.rotation_degrees = Vector3(-28, 28, 0)
	_stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.9
	rim.light_color = Color(0.6, 0.85, 1.0)
	rim.rotation_degrees = Vector3(-12, 155, 0)
	_stage.add_child(rim)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.52
	cm.bottom_radius = 0.58
	cm.height = 0.06
	disc.mesh = cm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.08, 0.13, 0.22)
	dm.metallic = 0.5
	dm.roughness = 0.35
	disc.material_override = dm
	disc.position.y = -0.03
	_stage.add_child(disc)
	var cam := Camera3D.new()
	cam.fov = 30
	cam.position = Vector3(0, 0.98, 4.35)
	_stage.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0))
	cam.current = true
	var hint := UITheme.label("Drag to turn", 16, UITheme.TEXT_DIM)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -34
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(hint)
	frame.add_child(holder)
	return frame


func _on_preview_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_drag = ev.pressed
		if ev.pressed:
			_auto_spin = false
	elif ev is InputEventMouseMotion and _drag:
		_spin += ev.relative.x * 0.012


func _process(delta: float) -> void:
	if _auto_spin:
		_spin += delta * 0.45
	# The right stick turns the preview too.
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if absf(rx) > 0.25:
		_auto_spin = false
		_spin += rx * delta * 2.5
	if _figure and is_instance_valid(_figure):
		_figure.rotation.y = _spin


func _rebuild_figure() -> void:
	if _figure and is_instance_valid(_figure):
		_figure.queue_free()
	Avatars.forget("player")
	_figure = RoamFigure.new()
	_stage.add_child(_figure)
	_figure.setup("player", Profile.color(), "", false)
	_figure.rotation.y = _spin


# ------------------------------------------------------------------ choices

func _section(t: String) -> Label:
	return UITheme.label(t, 16, UITheme.ACCENT, UITheme.semi_font())


func _toggle(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(196, 54)
	b.add_theme_stylebox_override("pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
	b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
	b.add_theme_color_override("font_pressed_color", Color(0.02, 0.05, 0.08))
	b.add_theme_color_override("font_hover_pressed_color", Color(0.02, 0.05, 0.08))
	return b


func _choice_row(parent: Control, key: String, title: String, options: Array, setter: Callable) -> void:
	parent.add_child(_section(title))
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 10)
	parent.add_child(r)
	var btns: Array = []
	for i in options.size():
		var b := _toggle(str(options[i]))
		b.pressed.connect(func():
			setter.call(i)
			_changed())
		r.add_child(b)
		btns.append(b)
	_rows[key] = btns


func _fill_hair() -> void:
	for c in _hair_row.get_children():
		_hair_row.remove_child(c)
		c.queue_free()
	var btns: Array = []
	var names: Array = Profile.HERO_HAIR[Profile.look_body]
	Profile.look_hair = clampi(Profile.look_hair, 0, names.size() - 1)
	for i in names.size():
		var b := _toggle(str(names[i]))
		b.pressed.connect(func():
			Profile.look_hair = i
			_changed())
		_hair_row.add_child(b)
		btns.append(b)
	_rows["hair"] = btns


## A look option changed: rebuild the preview and tell the rest of the game right away.
func _changed() -> void:
	Sfx.play("card", -8.0)
	Portraits._forget("player")
	_rebuild_figure()
	_refresh()
	Profile.changed.emit()


## A change that does not touch the model (title, lines): no rebuild, just the summary.
func _soft_change() -> void:
	Sfx.play("card", -10.0)
	_refresh()


func _refresh() -> void:
	var current := {"body": Profile.look_body, "hair": Profile.look_hair, "outfit": Profile.look_outfit, "color": Profile.color_index, "height": Profile.look_height}
	for key in _rows:
		for i in (_rows[key] as Array).size():
			if is_instance_valid(_rows[key][i]):
				(_rows[key][i] as Button).set_pressed_no_signal(i == int(current[key]))
	var n := _name_edit.text.strip_edges()
	Profile.duelist_name = n if n != "" else "Duelist"
	if _summary:
		_summary.text = "%s  ·  %s  ·  %s  ·  %s" % [Loc.t(str(Profile.HERO_HAIR[Profile.look_body][Profile.look_hair])),
				Loc.t(str(Profile.HERO_OUTFITS[Profile.look_outfit])), Loc.t(str(Profile.COLOR_NAMES[Profile.color_index])), Profile.title_text()]


func _save() -> void:
	if _name_edit.text.strip_edges() == "":
		Router.toast("Pick a name first")
		_name_edit.grab_focus()
		return
	Profile.duelist_name = _name_edit.text.strip_edges()
	Profile.created = true
	Profile.save()
	Settings.save_settings()
	Portraits._forget("player")
	_close()


func _cancel() -> void:
	Profile.duelist_name = _before["name"]
	Profile.look_body = _before["body"]
	Profile.look_hair = _before["hair"]
	Profile.look_outfit = _before["outfit"]
	Profile.color_index = _before["color"]
	Profile.gender = _before["gender"]
	Profile.look_height = _before["height"]
	Profile.title = _before["title"]
	Profile.intro = _before["intro"]
	Profile.win_line = _before["win"]
	Settings.sleeve = _before["sleeve"]
	Portraits._forget("player")
	Profile.changed.emit()
	_close()


func _unhandled_input(event: InputEvent) -> void:
	if not _first_time and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause")):
		get_viewport().set_input_as_handled()
		_cancel()


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
