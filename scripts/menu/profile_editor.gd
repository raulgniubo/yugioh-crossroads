class_name ProfileEditor
extends Control
## Create or edit your duelist: name, pronouns, color and emblem, with a live preview.

signal closed

var _preview: TextureRect
var _name_edit: LineEdit
var _gender_btns: Array[Button] = []
var _color_btns: Array[Button] = []
var _emblem_btns: Array[Button] = []
var _first_time := false
var _tint_btns: Array = []


func _init(first_time := false) -> void:
	_first_time = first_time


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.95)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.96), 26, Color(UITheme.ACCENT, 0.3)))
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 40)
	panel.add_child(h)
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(400, 500)
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0, 0, 0, 1)
	fsb.set_corner_radius_all(22)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	h.add_child(frame)
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(_preview)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.custom_minimum_size = Vector2(560, 0)
	h.add_child(v)
	v.add_child(UITheme.label("NEW DUELIST" if _first_time else "YOUR DUELIST", 56, Color.WHITE, UITheme.title_font()))
	var intro := UITheme.label("This is you in the story. You can change it any time." if _first_time else "Change how you look across the game.", 20, UITheme.TEXT_DIM)
	v.add_child(intro)
	v.add_child(_section("NAME"))
	_name_edit = LineEdit.new()
	_name_edit.text = "" if _first_time else Profile.duelist_name
	_name_edit.placeholder_text = "Your duelist name"
	_name_edit.max_length = 16
	_name_edit.add_theme_font_size_override("font_size", 28)
	_name_edit.text_changed.connect(func(t): _refresh())
	v.add_child(_name_edit)
	v.add_child(_section("PRONOUNS"))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 10)
	v.add_child(gr)
	for i in Profile.GENDERS.size():
		var b := _toggle(Profile.GENDERS[i] + (["/him", "/her", "/them"][i]))
		b.pressed.connect(func():
			Profile.gender = i
			_refresh())
		gr.add_child(b)
		_gender_btns.append(b)
	v.add_child(_section("COLOR"))
	var cr := HBoxContainer.new()
	cr.add_theme_constant_override("separation", 12)
	v.add_child(cr)
	for i in Profile.COLORS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(60, 60)
		b.toggle_mode = true
		var c: Color = Profile.COLORS[i]
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			var sb := UITheme.button_box(c, Color.WHITE if st in ["pressed", "hover_pressed"] else Color(c, 0.0), 30)
			sb.set_border_width_all(4)
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func():
			Profile.color_index = i
			_refresh())
		cr.add_child(b)
		_color_btns.append(b)
	v.add_child(_section("EMBLEM"))
	var er := HBoxContainer.new()
	er.add_theme_constant_override("separation", 10)
	v.add_child(er)
	for i in Profile.EMBLEMS.size():
		var b := _toggle(Profile.EMBLEMS[i])
		b.pressed.connect(func():
			Profile.emblem = i
			_refresh())
		er.add_child(b)
		_emblem_btns.append(b)
	if Avatars.own_file("player") == "":
		_look_row(v, "BODY", ["Type A", "Type B"], func(): return Profile.look_body, func(i): Profile.look_body = i)
		_hair_holder = VBoxContainer.new()
		v.add_child(_hair_holder)
		_rebuild_hair()
		_look_row(v, "OUTFIT", Profile.HERO_OUTFITS, func(): return Profile.look_outfit, func(i): Profile.look_outfit = i)
	else:
		v.add_child(_section("LOOK  ·  YOUR OWN 3D MODEL"))
		for g in ["hair", "outfit", "eyes"]:
			var tr := HBoxContainer.new()
			tr.add_theme_constant_override("separation", 8)
			var gl := UITheme.label(g.capitalize(), 18, UITheme.TEXT_DIM)
			gl.custom_minimum_size = Vector2(80, 0)
			tr.add_child(gl)
			for c in Avatars.TINTS:
				var b := Button.new()
				b.custom_minimum_size = Vector2(40, 40)
				b.toggle_mode = true
				for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
					var sb := UITheme.button_box(c, Color.WHITE if st in ["pressed", "hover_pressed"] else Color(1, 1, 1, 0.15), 20)
					sb.set_border_width_all(3)
					b.add_theme_stylebox_override(st, sb)
				if c == Color.WHITE:
					b.text = "↺"
					b.add_theme_color_override("font_color", Color.BLACK)
				var group: String = g
				var col: Color = c
				b.pressed.connect(func():
					Profile.tints[group] = col
					Avatars.retint("player")
					_refresh())
				tr.add_child(b)
				_tint_btns.append([b, group, col])
			v.add_child(tr)
		var hint := UITheme.label("Using your own model: characters/player in your card folder. Remove it to use the built-in looks.", 16, UITheme.TEXT_DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	if not _first_time:
		var cancel := Button.new()
		cancel.text = "Cancel"
		cancel.pressed.connect(func():
			Profile._ready()
			Portraits._forget("player")
			_close())
		row.add_child(cancel)
	var save := Button.new()
	save.text = "Start my journey" if _first_time else "Save"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.add_theme_font_size_override("font_size", 28)
	save.pressed.connect(_save)
	row.add_child(save)
	_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	await get_tree().process_frame
	_name_edit.grab_focus()


var _hair_holder: VBoxContainer
var _look_rows: Array = []  # [buttons, getter]


## A row of choices for one part of the built-in hero look.
func _look_row(parent: Control, title: String, options: Array, getter: Callable, setter: Callable) -> void:
	parent.add_child(_section(title))
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 10)
	parent.add_child(r)
	var btns: Array = []
	for i in options.size():
		var b := _toggle(str(options[i]))
		b.custom_minimum_size = Vector2(170, 50)
		b.pressed.connect(func():
			setter.call(i)
			if title == "BODY":
				_rebuild_hair()
			_look_changed())
		r.add_child(b)
		btns.append(b)
	_look_rows.append([btns, getter])


func _rebuild_hair() -> void:
	for row in _look_rows.duplicate():
		if (row[0] as Array).size() > 0 and (row[0][0] as Button).get_parent().get_parent() == _hair_holder:
			_look_rows.erase(row)
	for c in _hair_holder.get_children():
		c.queue_free()
	_look_row(_hair_holder, "HAIR", Profile.HERO_HAIR[Profile.look_body], func(): return Profile.look_hair, func(i): Profile.look_hair = i)


func _look_changed() -> void:
	Portraits._forget("player")
	_refresh()


func _section(t: String) -> Label:
	return UITheme.label(t, 16, UITheme.ACCENT, UITheme.semi_font())


func _toggle(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(130, 50)
	b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
	return b


func _refresh() -> void:
	for i in _gender_btns.size():
		_gender_btns[i].set_pressed_no_signal(i == Profile.gender)
	for i in _color_btns.size():
		_color_btns[i].set_pressed_no_signal(i == Profile.color_index)
	for i in _emblem_btns.size():
		_emblem_btns[i].set_pressed_no_signal(i == Profile.emblem)
	for row in _look_rows:
		for i in (row[0] as Array).size():
			if is_instance_valid(row[0][i]):
				(row[0][i] as Button).set_pressed_no_signal(i == int((row[1] as Callable).call()))
	for t in _tint_btns:
		(t[0] as Button).set_pressed_no_signal(Profile.tints.get(t[1], Color.WHITE) == t[2])
	var n := _name_edit.text.strip_edges()
	Profile.duelist_name = n if n != "" else "Duelist"
	if not Avatars.has_avatar("player"):
		Portraits._forget("player")  # the drawn placeholder shows name, color and emblem
	_preview.texture = Portraits.get_portrait("player")


func _save() -> void:
	if _name_edit.text.strip_edges() == "":
		Router.toast("Pick a name first")
		_name_edit.grab_focus()
		return
	Profile.duelist_name = _name_edit.text.strip_edges()
	Profile.created = true
	Profile.save()
	_close()


func _unhandled_input(event: InputEvent) -> void:
	if not _first_time and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause")):
		get_viewport().set_input_as_handled()
		Profile._ready()
		Portraits._forget("player")
		_close()


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
