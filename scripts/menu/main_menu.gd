extends Control
## Main menu: animated 3D backdrop, title, menu entries and side panels.

const MenuBackground := preload("res://scripts/menu/menu_city.gd")

var _items: Array[MenuItem] = []
var _menu_box: VBoxContainer
var _title_box: Control
var _panel_open := false


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Music.play("menu")
	Sfx.ambience("")
	Pad.walk_mode = false
	Pad.both_sticks = false
	Pad.hint("D-pad  move     A  select     B  back     Right stick  pointer")
	_build_background()
	_build_overlay()
	_build_title()
	_build_menu()
	_build_featured()
	_build_profile_chip()
	_build_footer()
	_intro()
	if Router.menu_open == "select":
		Router.menu_open = ""
		_on_free_duel.call_deferred()
	elif Router.menu_open == "academy":
		Router.menu_open = ""
		_on_academy.call_deferred()


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
	grad.colors = PackedColorArray([Color(0.01, 0.02, 0.05, 0.93), Color(0.01, 0.02, 0.05, 0.55), Color(0.01, 0.02, 0.05, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 4
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.anchor_bottom = 1.0
	tr.anchor_right = 0.5
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
	_menu_box.position = Vector2(100, 356)
	_menu_box.add_theme_constant_override("separation", 2)
	add_child(_menu_box)
	var entries := [
		["STORY", "Prologue and Chapter 1 are here", _on_story],
		["DUEL ACADEMY", "Entrance exam, three dorms, weekly exams, the tournament", _on_academy],
		["TURBO DUEL", "Ride the New Domino Highway. Speed Counters, Speed Spells", _on_turbo],
		["FREE ROAM", "Four worlds to walk. Duel anyone you meet", _on_roam],
		["FREE DUEL", "Pick both duelists, your deck and the arena", _on_free_duel],
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


## A rotating lineup of duelists on the right: the center card is big and bright,
## its neighbours fan out behind it.
var _carousel: Array[Control] = []
var _carousel_idx := 0


func _build_featured() -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	move_child(holder, 2)
	for key in Characters.ORDER:
		var d := Characters.get_char(key)
		var card := Panel.new()
		card.size = Vector2(380, 520)
		card.pivot_offset = card.size / 2.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.02, 0.03, 0.06, 1)
		sb.set_corner_radius_all(26)
		sb.border_color = d["color"]
		sb.set_border_width_all(3)
		card.add_theme_stylebox_override("panel", sb)
		card.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pt := TextureRect.new()
		pt.texture = Portraits.get_portrait(key)
		pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(pt)
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
		grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.1), Color(0.01, 0.02, 0.05, 0.92)])
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
		card.add_child(shade)
		var n := UITheme.label(str(d["short"]).to_upper(), 44, Color.WHITE, UITheme.title_font())
		n.position = Vector2(24, 430)
		card.add_child(n)
		var e := UITheme.label(str(d["era"]).to_upper(), 16, Color(d["color"]).lightened(0.4), UITheme.semi_font())
		e.position = Vector2(26, 482)
		card.add_child(e)
		card.modulate.a = 0.0
		holder.add_child(card)
		_carousel.append(card)
	_layout_carousel(true)
	var t := Timer.new()
	t.wait_time = 3.5
	t.autostart = true
	t.timeout.connect(func():
		_carousel_idx = (_carousel_idx + 1) % _carousel.size()
		_layout_carousel(false))
	add_child(t)


func _layout_carousel(instant: bool) -> void:
	var n := _carousel.size()
	var center := Vector2(get_viewport_rect().size.x - 400.0, get_viewport_rect().size.y - 300.0)
	for i in n:
		var card := _carousel[i]
		var rel := i - _carousel_idx
		if rel > n / 2:
			rel -= n
		elif rel < -n / 2:
			rel += n
		var a := absf(rel)
		var pos := center + Vector2(rel * 128.0, a * 14.0) - card.size / 2.0
		var sc := (1.0 - a * 0.16) * 0.6
		var alpha := 0.0 if a > 2 else (1.0 if a == 0 else 0.7 - (a - 1) * 0.35)
		card.z_index = 10 - int(a) * 2
		if instant:
			card.position = pos
			card.scale = Vector2(sc, sc)
			card.rotation = deg_to_rad(rel * 6.0)
			create_tween().tween_property(card, "modulate:a", alpha, 0.6).set_delay(0.3 + a * 0.1)
			continue
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(card, "position", pos, 0.7)
		tw.tween_property(card, "scale", Vector2(sc, sc), 0.7)
		tw.tween_property(card, "rotation", deg_to_rad(rel * 6.0), 0.7)
		tw.tween_property(card, "modulate:a", alpha, 0.5)


func _build_profile_chip() -> void:
	var chip := Button.new()
	chip.flat = true
	chip.anchor_left = 1.0
	chip.anchor_right = 1.0
	chip.offset_left = -420
	chip.offset_right = -50
	chip.offset_top = 40
	chip.offset_bottom = 124
	var sb := UITheme.panel_box(Color(0.03, 0.05, 0.09, 0.96), 20, Color(UITheme.ACCENT, 0.45))
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
	_chip_sub = UITheme.label("", 16, Color(0.8, 0.88, 1.0, 0.9))
	_chip_sub.position = Vector2(93, 46)
	_chip_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_sub)
	chip.pressed.connect(func(): _open_profile(false))
	Profile.changed.connect(_refresh_chip)
	_refresh_chip()


func _refresh_chip() -> void:
	_chip_avatar.texture = Portraits.get_portrait("player")
	_chip_name.text = Profile.duelist_name
	_chip_sub.text = Loc.t("Duelist Lv %d   ·   %d W  %d L") % [Profile.level(), Profile.wins, Profile.losses]


func _open_profile(first: bool) -> void:
	var ed := ProfileEditor.new(first)
	ed.z_index = 100
	add_child(ed)
	_panel_open = true
	ed.closed.connect(func():
		_panel_open = false
		_refresh_chip()
		if _items.size() > 1:
			_items[1].grab_focus())


func _build_footer() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1")
	var left := UITheme.label(Loc.t("Private fan project  ·  Prototype %s") % version, 16, Color(1, 1, 1, 0.35))
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
	p.z_index = 100
	p.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[1].grab_focus())


## Free Roam starts with a choice of world.
func _on_roam() -> void:
	var p := SidePanel.new("Free Roam", 640)
	p.z_index = 100
	var hint := UITheme.label("Pick a world. Inside, press G any time to jump to another one.", 18, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(hint)
	p.body.add_child(CityGuide.world_cards(func(key):
		if key == "highway":
			Router.go(Router.RIDE)
			return
		Router.roam["district"] = key
		Router.roam["pos"] = null
		Router.roam.erase("yaw")
		Router.roam.erase("tod")
		Router.go(Router.ROAM)))
	add_child(p)
	_open_panel(p)


func _on_story() -> void:
	var p := SidePanel.new("Story", 760)
	p.z_index = 100
	var pos := StoryProgress.position()
	if pos["chapter"] != "":
		var cont := Button.new()
		cont.text = "▶  Continue where you left off"
		cont.custom_minimum_size = Vector2(0, 72)
		cont.add_theme_font_size_override("font_size", 28)
		cont.pressed.connect(func():
			Router.story = pos
			Router.story_result = ""
			Router.go(Router.STORY))
		p.body.add_child(cont)
	p.add_section("Chapters")
	var unlocked := StoryProgress.unlocked()
	for c in StoryData.CHAPTERS:
		var ok: bool = unlocked.has(c["id"]) and StoryData.SCRIPTS.has(c["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 96)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s   ·   %s\n%s" % [Loc.t(c["title"]).to_upper(), c["era"], Loc.t(c["name"]) if ok else Loc.t("Locked" if StoryData.SCRIPTS.has(c["id"]) else "Coming soon")]
		b.add_theme_font_size_override("font_size", 24)
		b.disabled = not ok
		var id: String = c["id"]
		b.pressed.connect(func():
			Router.story = {"chapter": id, "step": 0, "flags": {}}
			Router.story_result = ""
			Router.go(Router.STORY))
		p.body.add_child(b)
	add_child(p)
	_open_panel(p)


func _on_deck() -> void:
	var db := DeckBuilder.new()
	db.z_index = 100
	add_child(db)
	_panel_open = true
	db.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[1].grab_focus())


func _on_settings() -> void:
	_open_panel(SettingsPanel.open(self))


func _on_quit() -> void:
	get_tree().quit()


func _on_turbo() -> void:
	Sfx.play("gong", -6.0)
	Router.go(Router.RIDE)


func _on_academy() -> void:
	var hub := AcademyHub.new()
	hub.z_index = 100
	add_child(hub)
	_panel_open = true
	hub.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[1].grab_focus())


func _on_free_duel() -> void:
	var cs := CharacterSelect.new()
	cs.z_index = 100
	add_child(cs)
	_panel_open = true
	cs.start.connect(func(cfg):
		Router.duel_config = cfg
		Router.go(Router.DUEL))
	cs.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[1].grab_focus())
