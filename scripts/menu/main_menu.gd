extends Control
## Main menu: animated 3D backdrop, title, menu entries and side panels.

const MenuBackground := preload("res://scripts/menu/menu_city.gd")

var _items: Array[Button] = []
var _menu_box: Control
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
	Router.roam["story"] = ""
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
	# Dark on the left where the menu sits, clear on the right where the city and the
	# duelists show through; a little shade top and bottom to frame it.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 0.78, 1.0])
	grad.colors = PackedColorArray([Color(0.01, 0.02, 0.05, 0.95), Color(0.01, 0.02, 0.05, 0.8), Color(0.01, 0.02, 0.05, 0.18), Color(0.01, 0.02, 0.05, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 4
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.anchor_bottom = 1.0
	tr.anchor_right = 0.86
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	vg.colors = PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6)])
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill_from = Vector2(0, 0)
	vt.fill_to = Vector2(0, 1)
	vt.width = 4
	vt.height = 256
	var vr := TextureRect.new()
	vr.texture = vt
	vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vr.stretch_mode = TextureRect.STRETCH_SCALE
	vr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vr)


func _build_title() -> void:
	_title_box = Control.new()
	_title_box.position = Vector2(100, 58)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_box)
	var small := UITheme.label("Y U - G I - O H !", 24, UITheme.ACCENT, UITheme.semi_font())
	_title_box.add_child(small)
	var big := UITheme.label("CROSSROADS", 112, Color.WHITE, UITheme.title_font())
	big.position = Vector2(-5, 14)
	big.add_theme_color_override("font_shadow_color", Color(UITheme.ACCENT, 0.35))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 0)
	big.add_theme_constant_override("shadow_outline_size", 20)
	_title_box.add_child(big)
	var rule := ColorRect.new()
	rule.color = Color(UITheme.ACCENT, 0.8)
	rule.position = Vector2(2, 142)
	rule.size = Vector2(64, 3)
	_title_box.add_child(rule)
	var tag := UITheme.label("Four eras. One story.", 22, UITheme.TEXT_DIM)
	tag.position = Vector2(82, 128)
	_title_box.add_child(tag)


## What the Story tile says: where you left off, or the newest chapter you can start.
func _story_line() -> Array:
	var pos := StoryProgress.position()
	var unlocked := StoryProgress.unlocked()
	var newest := {}
	var played := 0
	for c in StoryData.CHAPTERS:
		if unlocked.has(c["id"]) and StoryData.SCRIPTS.has(c["id"]):
			newest = c
			played += 1
		if str(pos["chapter"]) == str(c["id"]):
			return [Loc.t("Continue"), "%s: %s" % [Loc.t(str(c["title"])), Loc.t(str(c["name"]))], Loc.t("Pick up right where you stopped. %d of %d chapters open.") % [maxi(played, 1), StoryData.CHAPTERS.size()]]
	if newest.is_empty():
		newest = StoryData.CHAPTERS[0]
	return [Loc.t("Story"), "%s: %s" % [Loc.t(str(newest["title"])), Loc.t(str(newest["name"]))], Loc.t("%d of %d chapters open. Each one ends with a bond and a new card.") % [maxi(played, 1), StoryData.CHAPTERS.size()]]


func _build_menu() -> void:
	var purse := DpPurse.new()
	purse.anchor_left = 1.0
	purse.anchor_right = 1.0
	purse.offset_left = -706
	purse.offset_right = -446
	purse.offset_top = 40
	purse.offset_bottom = 124
	add_child(purse)
	_menu_box = Control.new()
	_menu_box.position = Vector2(100, 262)
	add_child(_menu_box)
	Tournament.load_data()
	var won := 0
	for id in Tournament.DEFS:
		if Tournament.titles(str(id)) > 0:
			won += 1
	var st := _story_line()
	var gap := 18.0
	var rows := [
		[232.0, [
			[st[0], st[1], st[2], Color("ffd166"), "✦", 610.0, _on_story, "", true],
			["Free Duel", "FREE DUEL", "Any duelist, any deck, any field. Gauntlets and Survival.", Color("2de2e6"), "⚔", 372.0, _on_free_duel, "", true]]],
		[156.0, [
			["Riding Duels", "TURBO DUEL", "Race the highway, duel at speed.", Color("ff8a3a"), "➤", 321.0, _on_turbo, "", false],
			["Open world", "FREE ROAM", "Five places to walk and duel.", Color("3ddc97"), "◎", 321.0, _on_roam, "", false],
			["Four titles", "TOURNAMENTS", "Badges, brackets, trophies.", Color("ff5a7a"), "♛", 322.0, _on_tournaments, "%d / %d" % [won, Tournament.DEFS.size()], false]]],
		[156.0, [
			["School life", "DUEL ACADEMY", "Exams, dorms, the weekly cup.", Color("7cc4ff"), "✎", 321.0, _on_academy, "", false],
			["Your cards", "MY DECKS", "Build, rename, pick a deck.", Color("b98cff"), "❖", 321.0, _on_deck, "", false],
			["", "SETTINGS", "", Color("9fb4c8"), "⚙", 152.0, _on_settings, "", false],
			["", "QUIT", "", Color("8a93a6"), "⏻", 152.0, _on_quit, "", false]]],
	]
	var y := 0.0
	for row in rows:
		var x := 0.0
		for e in row[1]:
			if str(e[1]) == "QUIT" and not OS.has_feature("pc"):
				continue
			var tile := MenuTile.new(str(e[0]), str(e[1]), str(e[2]), e[3], str(e[4]), Vector2(float(e[5]), float(row[0])), str(e[7]), bool(e[8]))
			tile.position = Vector2(x, y)
			tile.pressed.connect(e[6])
			tile.pressed.connect(func(): Sfx.play("click", -6.0))
			_menu_box.add_child(tile)
			_items.append(tile)
			x += float(e[5]) + gap
		y += float(row[0]) + gap


## The four tournaments at a glance, and a way to go straight to each one's desk.
func _on_tournaments() -> void:
	var p := SidePanel.new("Tournaments", 720)
	p.z_index = 100
	var hint := UITheme.label("Beat duelists out in the world to earn Finals Badges, then win the bracket. Three titles open the Crossroads Cup.", 18, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(hint)
	Tournament.load_data()
	for id in Tournament.DEFS:
		var d: Dictionary = Tournament.DEFS[id]
		var titles := Tournament.titles(str(id))
		var missing: Array = Tournament.missing(str(id))
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 104)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var state := Loc.t("Champion  x%d") % titles if titles > 0 else (Loc.t("Locked: needs %s") % ", ".join(missing) if not missing.is_empty() else Loc.t("Open. Go to the desk to enter."))
		b.text = "%s\n%s" % [Loc.t(str(d["name"])).to_upper(), state]
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_color_override("font_color", Color(d.get("color", UITheme.ACCENT)).lightened(0.4))
		b.disabled = not missing.is_empty()
		var district := str(d.get("district", "domino"))
		b.pressed.connect(func():
			if district == "ride":
				Router.go(Router.RIDE)
				return
			Router.roam["district"] = district
			Router.roam["pos"] = null
			Router.roam.erase("yaw")
			Router.roam.erase("tod")
			Router.go(Router.ROAM))
		p.body.add_child(b)
	add_child(p)
	_open_panel(p)


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
	var center := Vector2(get_viewport_rect().size.x - 430.0, get_viewport_rect().size.y - 372.0)
	# The one in front is shown large: ask for it sharp.
	if n > 0:
		Portraits.get_portrait(str(Characters.ORDER[_carousel_idx % Characters.ORDER.size()]), true)
	for i in n:
		var card := _carousel[i]
		var rel := i - _carousel_idx
		if rel > n / 2:
			rel -= n
		elif rel < -n / 2:
			rel += n
		var a := absf(rel)
		var pos := center + Vector2(rel * 176.0, a * 22.0) - card.size / 2.0
		var sc := (1.0 - a * 0.2) * 0.98
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
	chip.anchor_left = 1.0
	chip.anchor_right = 1.0
	chip.offset_left = -430
	chip.offset_right = -60
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
			_items[0].grab_focus())


func _build_footer() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1")
	var left := UITheme.label(Loc.t("Private fan project  ·  Prototype %s") % version, 16, Color(1, 1, 1, 0.35))
	_anchor_bottom(left, 104, 900)
	add_child(left)


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
		var home := item.position
		item.position = home + Vector2(-30, 14)
		tw.tween_property(item, "modulate:a", 1.0, 0.4).set_delay(0.35 + i * 0.05)
		tw.tween_property(item, "position", home, 0.5).set_delay(0.35 + i * 0.05)
	await get_tree().create_timer(0.6).timeout
	if not Profile.created and not "--shot" in str(OS.get_cmdline_user_args()) and not "--story" in str(OS.get_cmdline_user_args()):
		_open_profile(true)
	elif _items.size() > 0 and not _panel_open:
		_items[0].grab_focus()


func _open_panel(p: SidePanel) -> void:
	_panel_open = true
	p.z_index = 100
	p.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


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
		cont.pressed.connect(func(): StoryDirector.begin(str(pos["chapter"]), true))
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
		b.pressed.connect(func(): StoryDirector.begin(id))
		p.body.add_child(b)
	add_child(p)
	_open_panel(p)


func _on_deck() -> void:
	var db := DeckMenu.new()
	db.z_index = 100
	add_child(db)
	_panel_open = true
	db.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


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
			_items[0].grab_focus())


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
			_items[0].grab_focus())
