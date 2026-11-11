extends Control
## Main menu: animated 3D backdrop, title, menu entries and side panels.

const MenuBackground := preload("res://scripts/menu/menu_background.gd")

var _items: Array[MenuItem] = []
var _menu_box: VBoxContainer
var _title_box: Control
var _panel_open := false


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_overlay()
	_build_title()
	_build_menu()
	_build_featured()
	_build_profile_chip()
	_build_footer()
	_intro()


func _build_background() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_2X
	vp.own_world_3d = true
	svc.add_child(vp)
	var bg := Node3D.new()
	bg.set_script(MenuBackground)
	vp.add_child(bg)


func _build_overlay() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([Color(0.01, 0.02, 0.04, 0.96), Color(0.01, 0.02, 0.04, 0.7), Color(0.01, 0.02, 0.04, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 4
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.anchor_bottom = 1.0
	tr.anchor_right = 0.62
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)


func _build_title() -> void:
	_title_box = Control.new()
	_title_box.position = Vector2(120, 120)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_box)
	var small := UITheme.label("Y U - G I - O H !", 30, UITheme.ACCENT, UITheme.semi_font())
	_title_box.add_child(small)
	var big := UITheme.label("CROSSROADS", 150, Color.WHITE, UITheme.title_font())
	big.position = Vector2(-6, 18)
	big.add_theme_color_override("font_shadow_color", Color(UITheme.ACCENT, 0.35))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 0)
	big.add_theme_constant_override("shadow_outline_size", 22)
	_title_box.add_child(big)
	var tag := UITheme.label("Four eras. One story.", 26, UITheme.TEXT_DIM)
	tag.position = Vector2(4, 186)
	_title_box.add_child(tag)


func _build_menu() -> void:
	_menu_box = VBoxContainer.new()
	_menu_box.position = Vector2(100, 420)
	_menu_box.add_theme_constant_override("separation", 6)
	add_child(_menu_box)
	var entries := [
		["STORY", "Chapter 1: The Blank Deck. Coming soon", _on_story],
		["FREE DUEL", "Duel a rival with a story deck", _on_free_duel],
		["DECK", "Your cards and decks", _on_deck],
		["SETTINGS", "Display, audio and card art", _on_settings],
	]
	if OS.has_feature("pc"):
		entries.append(["QUIT", "See you next duel", _on_quit])
	for e in entries:
		var item := MenuItem.new(e[0], e[1])
		item.pressed.connect(e[2])
		_menu_box.add_child(item)
		_items.append(item)


var _featured: TextureRect
var _featured_name: Label
var _featured_idx := 0
var _chip_avatar: TextureRect
var _chip_name: Label
var _chip_sub: Label


func _build_featured() -> void:
	var holder := Control.new()
	holder.anchor_left = 1.0
	holder.anchor_right = 1.0
	holder.anchor_top = 1.0
	holder.anchor_bottom = 1.0
	holder.offset_left = -700
	holder.offset_right = -110
	holder.offset_top = -860
	holder.offset_bottom = -110
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	_featured = TextureRect.new()
	_featured.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_featured.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_featured.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_featured.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_featured)
	_featured_name = UITheme.label("", 22, UITheme.TEXT_DIM, UITheme.semi_font())
	_featured_name.anchor_top = 1.0
	_featured_name.anchor_bottom = 1.0
	_featured_name.anchor_right = 1.0
	_featured_name.offset_top = 6
	_featured_name.offset_bottom = 40
	_featured_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(_featured_name)
	_show_featured()
	var t := Timer.new()
	t.wait_time = 6.0
	t.autostart = true
	t.timeout.connect(func():
		_featured_idx = (_featured_idx + 1) % Characters.ORDER.size()
		_show_featured())
	add_child(t)


func _show_featured() -> void:
	var key: String = Characters.ORDER[_featured_idx]
	var d := Characters.get_char(key)
	var tw := create_tween()
	tw.tween_property(_featured, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		_featured.texture = Portraits.get_portrait(key)
		_featured_name.text = "%s  ·  %s" % [str(d["name"]).to_upper(), d["era"]])
	tw.tween_property(_featured, "modulate:a", 1.0, 0.6)


func _build_profile_chip() -> void:
	var chip := Button.new()
	chip.flat = true
	chip.anchor_left = 1.0
	chip.anchor_right = 1.0
	chip.offset_left = -420
	chip.offset_right = -50
	chip.offset_top = 40
	chip.offset_bottom = 124
	var sb := UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.8), 20, Color(1, 1, 1, 0.1))
	sb.set_content_margin_all(10)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.border_color = UITheme.ACCENT
	for st in ["normal", "focus"]:
		chip.add_theme_stylebox_override(st, sb)
	for st in ["hover", "pressed"]:
		chip.add_theme_stylebox_override(st, sbh)
	add_child(chip)
	var frame := Panel.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color.BLACK
	fsb.set_corner_radius_all(32)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.position = Vector2(12, 10)
	frame.size = Vector2(64, 64)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(frame)
	_chip_avatar = TextureRect.new()
	_chip_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chip_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_chip_avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(_chip_avatar)
	_chip_name = UITheme.label("", 30, Color.WHITE, UITheme.title_font())
	_chip_name.position = Vector2(92, 8)
	_chip_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_name)
	_chip_sub = UITheme.label("", 16, UITheme.TEXT_DIM)
	_chip_sub.position = Vector2(93, 46)
	_chip_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_sub)
	chip.pressed.connect(func(): _open_profile(false))
	Profile.changed.connect(_refresh_chip)
	_refresh_chip()


func _refresh_chip() -> void:
	_chip_avatar.texture = Portraits.get_portrait("player")
	_chip_name.text = Profile.duelist_name
	_chip_sub.text = "Duelist Lv %d   ·   %d W  %d L" % [Profile.level(), Profile.wins, Profile.losses]


func _open_profile(first: bool) -> void:
	var ed := ProfileEditor.new(first)
	add_child(ed)
	_panel_open = true
	ed.closed.connect(func():
		_panel_open = false
		_refresh_chip()
		if _items.size() > 1:
			_items[1].grab_focus())


func _build_footer() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1")
	var left := UITheme.label("Private fan project  ·  Prototype %s" % version, 16, Color(1, 1, 1, 0.35))
	_anchor_bottom(left, 120, 900)
	add_child(left)
	var art_text := "Card art: real images" if Cards.has_real_images() else "Card art: placeholders"
	var art := UITheme.label(art_text, 16, Color(1, 1, 1, 0.35))
	art.anchor_left = 1.0
	art.anchor_right = 1.0
	_anchor_bottom(art, -480, -60)
	art.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(art)


func _anchor_bottom(c: Control, left: float, right: float) -> void:
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_top = -64
	c.offset_bottom = -34
	c.offset_left = left
	c.offset_right = right


func _intro() -> void:
	_title_box.modulate.a = 0.0
	_title_box.position.x -= 40
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_title_box, "modulate:a", 1.0, 0.9).set_delay(0.2)
	tw.tween_property(_title_box, "position:x", _title_box.position.x + 40, 1.0).set_delay(0.2)
	for i in _items.size():
		var item := _items[i]
		item.modulate.a = 0.0
		tw.tween_property(item, "modulate:a", 1.0, 0.5).set_delay(0.5 + i * 0.08)
	await get_tree().create_timer(0.6).timeout
	if not Profile.created and not "--shot" in str(OS.get_cmdline_user_args()):
		_open_profile(true)
	elif _items.size() > 0 and not _panel_open:
		_items[1].grab_focus()


func _open_panel(p: SidePanel) -> void:
	_panel_open = true
	p.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[1].grab_focus())


func _on_story() -> void:
	Router.toast("Story mode is coming in a later build")


func _on_deck() -> void:
	Router.toast("Deck builder is coming soon")


func _on_settings() -> void:
	_open_panel(SettingsPanel.open(self))


func _on_quit() -> void:
	get_tree().quit()


func _on_free_duel() -> void:
	var cs := CharacterSelect.new()
	add_child(cs)
	_panel_open = true
	cs.start.connect(func(opp, deck):
		Router.duel_config = {"opponent": opp, "player_deck": deck}
		Router.go(Router.DUEL))
	cs.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[1].grab_focus())
