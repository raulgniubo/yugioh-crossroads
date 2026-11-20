class_name ProfileEditor
extends Control
## Create or edit your duelist. A full-body 3D preview on the left turns as you choose. On the
## right, five tabs: Body (type, age, height, skin, eyes), Hair (style and color), Outfit (the
## clothes of each series, Duel Academy dorm colors, and the color of every piece), and You
## (name, title, lines, card sleeve). Every change shows at once, here and in the world behind.

signal closed

## Everything the editor can change on the profile, so Cancel can put it all back.
const FIELDS := ["duelist_name", "gender", "color_index", "look_body", "look_hair", "look_outfit", "look_height", "look_build",
	"look_skin", "look_haircol", "look_eyes", "look_top", "look_bottom", "look_shoes", "title", "intro", "win_line", "style"]
const TABS := ["Body", "Hair", "Outfit", "You"]

var _first_time := false
var _name_edit: LineEdit
var _vp: SubViewport
var _stage: Node3D
var _figure: RoamFigure
const FRONT := 0.35
var _spin := 0.35
var _auto_spin := false
var _idle_t := 0.0
var _drag := false
var _rows := {}          # profile field -> [buttons], lit when their index is the chosen one
var _pages: Array = []   # one VBoxContainer per tab
var _tab_btns: Array = []
var _tab := 0
var _hair_box: VBoxContainer
var _outfit_box: VBoxContainer
var _summary: Label
var _before := {}
var _sleeve_before := ""


func _init(first_time := false) -> void:
	_first_time = first_time


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for f in FIELDS:
		_before[f] = Profile.get(f)
	_sleeve_before = Settings.sleeve
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.088, 0.165, 0.97), 26, Color(UITheme.ACCENT, 0.3)))
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	panel.add_child(h)
	h.add_child(_build_preview())
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.custom_minimum_size = Vector2(760, 0)
	# A little air to the left of the column: the first slanted button of a row leans a few
	# pixels past its own box, and against the edge its corner was cut off.
	var right_m := MarginContainer.new()
	right_m.add_theme_constant_override("margin_left", 8)
	h.add_child(right_m)
	right_m.add_child(right)
	right.add_child(UITheme.label("NEW DUELIST" if _first_time else "YOUR DUELIST", 54, Color.WHITE, UITheme.title_font()))
	right.add_child(UITheme.label("This is you in the story, the cities and every duel.", 19, UITheme.TEXT_DIM))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	right.add_child(tabs)
	for i in TABS.size():
		var tb := _toggle(str(TABS[i]))
		tb.custom_minimum_size = Vector2(150, 52)
		tb.add_theme_font_size_override("font_size", 24)
		tb.pressed.connect(func(): _show_tab(i))
		tabs.add_child(tb)
		_tab_btns.append(tb)
	# What you pick from scrolls; the tabs above and the buttons under it stay put.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(768, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# The list starts 8 px left of the column and gives those 8 px back inside, so what scrolls
	# lines up with the tabs while its slanted corners stay whole.
	UITheme.pad_scroll(scroll, 8, 0)
	var scroll_m := MarginContainer.new()
	scroll_m.add_theme_constant_override("margin_left", -8)
	right.add_child(scroll_m)
	scroll_m.add_child(scroll)
	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	for i in TABS.size():
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 10)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.visible = false
		holder.add_child(page)
		_pages.append(page)
	_page_body(_pages[0])
	_page_hair(_pages[1])
	_page_outfit(_pages[2])
	_page_you(_pages[3])
	_summary = UITheme.label("", 18, UITheme.GOLD, UITheme.semi_font())
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	rnd.pressed.connect(_surprise)
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
	_show_tab(3 if _first_time else 0)
	_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	await get_tree().process_frame
	if _first_time:
		_name_edit.grab_focus()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--creator-tab="):
			_show_tab(clampi(int(a.trim_prefix("--creator-tab=")), 0, TABS.size() - 1))


func _show_tab(i: int) -> void:
	_tab = i
	for k in _pages.size():
		(_pages[k] as Control).visible = k == i
		(_tab_btns[k] as Button).set_pressed_no_signal(k == i)


# ------------------------------------------------------------------ the tabs

func _page_body(v: VBoxContainer) -> void:
	_choice_row(v, "look_body", "BODY", ["Type A", "Type B"], func(i):
		Profile.look_body = i
		Profile.gender = i
		_fill_hair()
		_fill_outfits(), true)
	var builds: Array = []
	for b in HeroLook.BUILDS:
		builds.append(str(b[0]))
	_choice_row(v, "look_build", "AGE", builds, func(i): Profile.look_build = i, true)
	var hnames: Array = []
	for hh in HeroLook.HEIGHTS:
		hnames.append(str(hh[0]))
	_choice_row(v, "look_height", "HEIGHT", hnames, func(i): Profile.look_height = i, true, 138)
	_swatches(v, "look_skin", "SKIN", HeroLook.SKIN)
	_swatches(v, "look_eyes", "EYES", HeroLook.EYES)


func _page_hair(v: VBoxContainer) -> void:
	_hair_box = VBoxContainer.new()
	_hair_box.add_theme_constant_override("separation", 10)
	v.add_child(_hair_box)
	_fill_hair()
	_swatches(v, "look_haircol", "HAIR COLOR", HeroLook.HAIR)
	var note := UITheme.label("The streak in your hair follows your signature color (Outfit tab).", 16, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)


func _page_outfit(v: VBoxContainer) -> void:
	_outfit_box = VBoxContainer.new()
	_outfit_box.add_theme_constant_override("separation", 10)
	v.add_child(_outfit_box)
	_fill_outfits()
	v.add_child(_section("SIGNATURE COLOR   ·   your trim, your hair streak, your name plate"))
	var cr := HFlowContainer.new()
	cr.add_theme_constant_override("h_separation", 10)
	cr.add_theme_constant_override("v_separation", 10)
	v.add_child(cr)
	var cbtns: Array = []
	for i in Profile.COLORS.size():
		var b := _swatch(Profile.COLORS[i], Loc.t(str(Profile.COLOR_NAMES[i])))
		b.pressed.connect(func():
			Profile.color_index = i
			_recolor())
		cr.add_child(b)
		cbtns.append(b)
	_rows["color_index"] = cbtns
	_swatches(v, "look_top", "TOP", HeroLook.CLOTH)
	_swatches(v, "look_bottom", "BOTTOM", HeroLook.CLOTH)
	_swatches(v, "look_shoes", "SHOES", HeroLook.CLOTH)


func _page_you(v: VBoxContainer) -> void:
	v.add_child(_section("NAME"))
	_name_edit = LineEdit.new()
	_name_edit.text = "" if _first_time else Profile.duelist_name
	_name_edit.placeholder_text = "Your duelist name"
	_name_edit.max_length = 16
	_name_edit.add_theme_font_size_override("font_size", 28)
	_name_edit.text_changed.connect(func(_t): _refresh())
	v.add_child(_name_edit)
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
	v.add_child(_section("STYLE   ·   how you stand and move in a duel"))
	var style_pick := OptionButton.new()
	style_pick.custom_minimum_size = Vector2(0, 48)
	for i in Profile.STYLE_NAMES.size():
		style_pick.add_item(Loc.t(str(Profile.STYLE_NAMES[i])), i)
	style_pick.select(Profile.style)
	style_pick.item_selected.connect(func(i):
		Profile.style = i
		_soft_change())
	v.add_child(style_pick)
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
		sbn.add_theme_stylebox_override("normal", UITheme.button_box(Color(0.042, 0.0676, 0.136, 0.9), Color(1, 1, 1, 0.12), 10))
		var son := UITheme.button_box(Color(0.112, 0.088, 0.225, 0.95), Color("ffd98a"), 10)
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


func _surprise() -> void:
	Profile.look_body = randi() % 2
	Profile.gender = Profile.look_body
	var hs := HeroLook.hairs(Profile.look_body)
	Profile.look_hair = int(hs[randi() % hs.size()])
	var os := _outfits_for_body()
	Profile.look_outfit = int(os[randi() % os.size()])
	Profile.color_index = randi() % Profile.COLORS.size()
	Profile.look_height = 1 + randi() % 3
	Profile.look_build = 1 + randi() % 2
	Profile.look_skin = randi() % HeroLook.SKIN.size()
	Profile.look_haircol = randi() % HeroLook.HAIR.size()
	Profile.look_eyes = randi() % HeroLook.EYES.size()
	# Clothes: mostly as the outfit was made, now and then a color of its own.
	Profile.look_top = randi() % HeroLook.CLOTH.size() if randf() < 0.5 else 0
	Profile.look_bottom = randi() % HeroLook.CLOTH.size() if randf() < 0.35 else 0
	Profile.look_shoes = randi() % HeroLook.CLOTH.size() if randf() < 0.3 else 0
	_fill_hair()
	_fill_outfits()
	_changed()


# ------------------------------------------------------------------ 3D preview

func _build_preview() -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(520, 760)
	var fsb := UITheme.panel_box(Color(0.06, 0.09, 0.19, 1), 14, Color(1, 1, 1, 0.1))
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
	_vp.msaa_3d = Settings.small_view_msaa()
	svc.add_child(_vp)
	_stage = Node3D.new()
	_vp.add_child(_stage)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.82, 0.88, 1.0)
	e.ambient_light_energy = 0.5
	# Plain light, close to one to one: the color you press is the color you see on the figure.
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = e
	_stage.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_energy = 0.72
	key.rotation_degrees = Vector3(-28, 28, 0)
	_stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.35
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
	# The figure faces you and just breathes. Drag (or the right stick) turns it; let go and
	# it eases back to face the front again.
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if absf(rx) > 0.25:
		_spin += rx * delta * 2.5
		_idle_t = 0.0
	elif _drag:
		_idle_t = 0.0
	else:
		_idle_t += delta
		if _idle_t > 1.2:
			_spin = lerp_angle(_spin, FRONT, clampf(delta * 3.0, 0.0, 1.0))
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


## A round color button. `c.a == 0` is the "as it was made" choice: a ring with a slash.
func _swatch(c: Color, tip: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(48, 48)
	b.toggle_mode = true
	b.tooltip_text = tip
	var own := c.a < 0.5
	var fill := Color(0.09, 0.13, 0.22) if own else c
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var lit: bool = st in ["pressed", "hover_pressed", "focus"]
		var sb := UITheme.button_box(fill, Color.WHITE if lit else (Color(1, 1, 1, 0.28) if own or c.get_luminance() < 0.12 else Color(c, 0.0)), 24)
		sb.set_border_width_all(4 if lit else 2)
		b.add_theme_stylebox_override(st, sb)
	if own:
		b.text = "/"
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	return b


## A row of color buttons for one profile field. Colors only repaint the figure that is
## standing there; nothing is loaded again, so trying them is instant.
func _swatches(parent: Control, field: String, title: String, list: Array) -> void:
	parent.add_child(_section(title))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	parent.add_child(flow)
	var btns: Array = []
	for i in list.size():
		var hex := str(list[i][1])
		var b := _swatch(Color(0, 0, 0, 0) if hex == "" else Color(hex), Loc.t(str(list[i][0])))
		b.pressed.connect(func():
			Profile.set(field, i)
			_recolor())
		flow.add_child(b)
		btns.append(b)
	_rows[field] = btns


func _choice_row(parent: Control, field: String, title: String, options: Array, setter: Callable, _rebuild := true, width := 196) -> void:
	parent.add_child(_section(title))
	var r := HFlowContainer.new()
	r.add_theme_constant_override("h_separation", 10)
	r.add_theme_constant_override("v_separation", 10)
	parent.add_child(r)
	var btns: Array = []
	for i in options.size():
		var b := _toggle(Loc.t(str(options[i])))
		b.custom_minimum_size.x = width
		b.pressed.connect(func():
			setter.call(i)
			_changed())
		r.add_child(b)
		btns.append(b)
	_rows[field] = btns


func _fill_hair() -> void:
	if _hair_box == null:
		return
	for c in _hair_box.get_children():
		_hair_box.remove_child(c)
		c.queue_free()
	_hair_box.add_child(_section("HAIRSTYLE"))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	_hair_box.add_child(flow)
	var have := HeroLook.hairs(Profile.look_body)
	if not have.has(Profile.look_hair):
		Profile.look_hair = int(have[0])
	var btns: Array = []
	btns.resize(4)
	for i in have:
		var b := _toggle(Loc.t(str(HeroLook.HAIRS[Profile.look_body][i][0])))
		b.pressed.connect(func():
			Profile.look_hair = i
			_changed())
		flow.add_child(b)
		btns[i] = b
	_rows["look_hair"] = btns


## The outfits made for this body.
func _outfits_for_body() -> Array:
	var out: Array = []
	var stem := "hero_m" if Profile.look_body == 0 else "hero_f"
	for i in HeroLook.OUTFITS.size():
		for n in [1, 2, 3, 4]:
			if HeroLook.has_model("%s%d_%s" % [stem, n, HeroLook.OUTFITS[i][2]]):
				out.append(i)
				break
	return out


func _fill_outfits() -> void:
	if _outfit_box == null:
		return
	for c in _outfit_box.get_children():
		_outfit_box.remove_child(c)
		c.queue_free()
	_outfit_box.add_child(_section("OUTFIT   ·   one for every series"))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	_outfit_box.add_child(flow)
	var have := _outfits_for_body()
	if not have.has(Profile.look_outfit):
		Profile.look_outfit = int(have[0])
	var btns: Array = []
	btns.resize(HeroLook.OUTFITS.size())
	for i in have:
		var o: Array = HeroLook.OUTFITS[i]
		var b := _toggle("%s\n%s" % [Loc.t(str(o[0])), str(o[1])])
		b.custom_minimum_size = Vector2(236, 76)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(func():
			Profile.look_outfit = i
			_fill_outfits()
			_changed())
		flow.add_child(b)
		btns[i] = b
	_rows["look_outfit"] = btns
	if bool(HeroLook.OUTFITS[Profile.look_outfit][3]):
		# Duel Academy: the three dorms, one press each. The blazer takes the dorm's color.
		_outfit_box.add_child(_section("DORM   ·   Duel Academy jackets"))
		var dr := HBoxContainer.new()
		dr.add_theme_constant_override("separation", 10)
		_outfit_box.add_child(dr)
		for d in HeroLook.DORMS:
			var db := Button.new()
			db.text = Loc.t(str(d[0]))
			db.custom_minimum_size = Vector2(150, 54)
			var dc := Color(str(d[1]))
			db.add_theme_stylebox_override("normal", UITheme.button_box(Color(dc, 0.85), dc.lightened(0.3), 12))
			db.add_theme_stylebox_override("hover", UITheme.button_box(dc, Color.WHITE, 12))
			db.add_theme_color_override("font_color", Color.WHITE if dc.get_luminance() < 0.6 else Color(0.08, 0.08, 0.1))
			db.add_theme_color_override("font_hover_color", Color.WHITE if dc.get_luminance() < 0.6 else Color(0.08, 0.08, 0.1))
			var want := -1
			for k in HeroLook.CLOTH.size():
				if str(HeroLook.CLOTH[k][1]) == str(d[1]):
					want = k
			db.pressed.connect(func():
				Profile.look_top = want
				_recolor())
			dr.add_child(db)
		var plain := Button.new()
		plain.text = Loc.t("Navy (as made)")
		plain.custom_minimum_size = Vector2(190, 54)
		plain.pressed.connect(func():
			Profile.look_top = 0
			_recolor())
		dr.add_child(plain)


## A model option changed (body, hairstyle, outfit, age, height): rebuild the preview and tell
## the rest of the game right away.
func _changed() -> void:
	Sfx.play("card", -8.0)
	Portraits._forget("player")
	_rebuild_figure()
	_refresh()
	Profile.changed.emit()


## A color changed: repaint the figure that is already there.
func _recolor() -> void:
	Sfx.play("card", -10.0)
	var painted := false
	if _figure and is_instance_valid(_figure) and _figure._model:
		for n in [_figure._model] + _figure._model.find_children("*", "Node3D", true, false):
			if n.has_meta("hero_mats"):
				HeroLook.recolor(n, Profile, Profile.color())
				painted = true
	if not painted:
		_rebuild_figure()
	Portraits._forget("player")
	_refresh()
	Profile.changed.emit()


## A change that does not touch the model (title, lines): no rebuild, just the summary.
func _soft_change() -> void:
	Sfx.play("card", -10.0)
	_refresh()


func _refresh() -> void:
	for field in _rows:
		var chosen := int(Profile.get(field))
		for i in (_rows[field] as Array).size():
			var b = _rows[field][i]
			if b != null and is_instance_valid(b):
				(b as Button).set_pressed_no_signal(i == chosen)
	if _name_edit:
		var n := _name_edit.text.strip_edges()
		Profile.duelist_name = n if n != "" else "Duelist"
	if _summary:
		_summary.text = "%s  ·  %s  ·  %s  ·  %s  ·  %s" % [Loc.t(str(HeroLook.BUILDS[Profile.look_build][0])),
				Loc.t(str(HeroLook.HAIRS[Profile.look_body][Profile.look_hair][0])),
				Loc.t(str(HeroLook.OUTFITS[Profile.look_outfit][0])), Loc.t(str(Profile.COLOR_NAMES[Profile.color_index])), Profile.title_text()]


func _save() -> void:
	if _name_edit.text.strip_edges() == "":
		Router.toast("Pick a name first")
		_show_tab(3)
		_name_edit.grab_focus()
		return
	Profile.duelist_name = _name_edit.text.strip_edges()
	Profile.created = true
	Profile.save()
	Settings.save_settings()
	Portraits._forget("player")
	_close()


func _cancel() -> void:
	for f in FIELDS:
		Profile.set(f, _before[f])
	Settings.sleeve = _sleeve_before
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
