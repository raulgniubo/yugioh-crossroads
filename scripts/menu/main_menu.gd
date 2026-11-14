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
	vp.msaa_3d = Viewport.MSAA_2X if int(Settings.gfx["aa"]) >= 2 else Viewport.MSAA_DISABLED
	vp.own_world_3d = true
	# The city behind the menu is a backdrop: three quarters of the pixels are plenty, and
	# it keeps the home screen quick.
	vp.scaling_3d_scale = 0.75 * Settings.scale_3d()
	svc.add_child(vp)
	var bg := Node3D.new()
	bg.set_script(MenuBackground)
	vp.add_child(bg)


func _build_overlay() -> void:
	# The real city in its own colors. Dark on the left where the menu sits, clear on the
	# right where the duelists stand; a little shade top and bottom to frame it.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(0.015, 0.025, 0.06, 0.94), Color(0.015, 0.025, 0.06, 0.8), Color(0.015, 0.025, 0.06, 0.2), Color(0.015, 0.025, 0.06, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 4
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.anchor_bottom = 1.0
	tr.anchor_right = 0.8
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.18, 0.62, 1.0])
	vg.colors = PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0.01, 0.02, 0.05, 0.78)])
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
	_title_box.position = Vector2(70, 158)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_box)
	var small := UITheme.label("Y U - G I - O H !", 22, UITheme.ACCENT, Comic.button_font())
	small.position = Vector2(4, 0)
	_title_box.add_child(small)
	var big := UITheme.label("CROSSROADS", 112, Color.WHITE, Comic.shout_font())
	big.position = Vector2(-2, 12)
	big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 6)
	big.add_theme_constant_override("shadow_outline_size", 14)
	_title_box.add_child(big)
	var rule := ColorRect.new()
	rule.color = UITheme.ACCENT
	rule.position = Vector2(4, 140)
	rule.size = Vector2(72, 4)
	_title_box.add_child(rule)
	var tag := UITheme.label("Four eras. One story.", 20, Color(0.82, 0.86, 0.95))
	tag.position = Vector2(90, 128)
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
	_menu_box = Control.new()
	_menu_box.position = Vector2(64, 336)
	add_child(_menu_box)
	Tournament.load_data()
	var won := 0
	for id in Tournament.DEFS:
		if Tournament.titles(str(id)) > 0:
			won += 1
	var st := _story_line()
	# The Story banner on top, then three rows of ribbons. Each row steps back along the slant.
	var story := MenuTile.new(str(st[0]), str(st[1]), str(st[2]), UITheme.ACCENT, "", Vector2(736, 150), "", true)
	story.position = Vector2(24, 0)
	story.pressed.connect(_on_story)
	story.pressed.connect(func(): Sfx.play("click", -6.0))
	_menu_box.add_child(story)
	_items.append(story)
	var rows := [
		[["Free Duel", "FREE DUEL", "Any duelist, deck and field.", "⚔", _on_free_duel, ""],
			["Riding Duels", "TURBO DUEL", "Race the highway at speed.", "➤", _on_turbo, ""]],
		[["Open world", "FREE ROAM", "Five places to walk and duel.", "◎", _on_roam, ""],
			["Four titles", "TOURNAMENTS", "Badges, brackets, trophies.", "♛", _on_tournaments, "%d / %d" % [won, Tournament.DEFS.size()]]],
		[["School life", "DUEL ACADEMY", "Exams, dorms, the weekly cup.", "✎", _on_academy, ""],
			["Your cards", "MY DECKS", "Build, rename, pick a deck.", "❖", _on_deck, ""]],
	]
	var y := 160.0
	for ri in rows.size():
		var x := 16.0 - ri * 8.0
		for e in rows[ri]:
			var tile := MenuTile.new(str(e[0]), str(e[1]), str(e[2]), UITheme.ACCENT, "", Vector2(364, 112), str(e[5]), false)
			tile.position = Vector2(x, y)
			tile.pressed.connect(e[4])
			tile.pressed.connect(func(): Sfx.play("click", -6.0))
			_menu_box.add_child(tile)
			_items.append(tile)
			x += 364.0 + 2.0
		y += 112.0 + 6.0
	# Settings and Quit are round buttons in the corner.
	var rounds := HBoxContainer.new()
	rounds.add_theme_constant_override("separation", 14)
	rounds.anchor_top = 1.0
	rounds.anchor_bottom = 1.0
	rounds.offset_left = 64
	rounds.offset_top = -112
	rounds.offset_bottom = -48
	add_child(rounds)
	var gear := RoundButton.new("gear", Comic.BLUE, 64.0)
	gear.tooltip_text = "Settings"
	gear.focus_mode = Control.FOCUS_ALL
	gear.pressed.connect(_on_settings)
	rounds.add_child(gear)
	_items.append(gear)
	if OS.has_feature("pc"):
		var quit := RoundButton.new("power", Comic.RED, 64.0)
		quit.tooltip_text = "Quit"
		quit.focus_mode = Control.FOCUS_ALL
		quit.pressed.connect(_on_quit)
		rounds.add_child(quit)
		_items.append(quit)


## The four tournaments at a glance, and a way to go straight to each one's desk.
func _on_tournaments() -> void:
	var p := SidePanel.new("Tournaments", 760)
	p.z_index = 100
	var hint := UITheme.label("Beat duelists out in the world to earn Finals Badges, then win the bracket. Three titles open the Crossroads Cup.", 18, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(hint)
	Tournament.load_data()
	for id in Tournament.DEFS:
		var d: Dictionary = Tournament.DEFS[id]
		var b := TourneyCard.new(str(id))
		b.disabled = not Tournament.missing(str(id)).is_empty()
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


var _chip_avatar: TextureRect
var _chip_name: Label
var _chip_sub: Label


## A lineup of duelists on the right: four at a time, one from each series (Duel Monsters, GX,
## 5D's, ZEXAL), each with a name tag. Every few seconds one of them steps out for another
## duelist from the same series, so all four eras are always on screen.
const LINEUP := 4
const LINEUP_ERAS := ["Duel Monsters", "GX", "5D's", "ZEXAL"]
var _line: Array = []            # [{tex, tag, key, home, pool, at}]
var _feat_turn := 0


func _build_featured() -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	move_child(holder, 2)
	var pools: Array = [[], [], [], []]
	var spare: Array = []
	for key in Characters.ORDER:
		if not Avatars.has_avatar(str(key)):
			continue
		var era := LINEUP_ERAS.find(str(Characters.get_char(str(key)).get("era", "")))
		if era >= 0:
			(pools[era] as Array).append(str(key))
		else:
			spare.append(str(key))
	for pool in pools:
		(pool as Array).shuffle()
		if (pool as Array).is_empty():
			# Nobody from that series has a model yet: anyone will do.
			(pool as Array).append_array(spare if not spare.is_empty() else Characters.ORDER.slice(0, 1))
	var vs := get_viewport_rect().size
	# Back to front, so the two in the middle stand a step ahead of the outer two.
	var plan := [[0, 0.82, -30.0], [3, 0.82, -30.0], [1, 1.0, 0.0], [2, 1.0, 0.0]]
	_line.resize(LINEUP)
	for e in plan:
		var i: int = e[0]
		var sc: float = e[1]
		# The picture shows a wider piece of the world than the bust it used to (room for any
		# hair), so the slot is bigger and the slots overlap: what overlaps is empty air.
		var sz := Vector2(592, 740) * sc
		var cx := vs.x - 905.0 + i * 244.0
		var home := Vector2(cx - sz.x / 2.0, vs.y - 62.0 - sz.y + float(e[2]))
		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.material = _fade_mat().duplicate()
		holder.add_child(tex)
		tex.size = sz
		tex.position = home
		var tag := Control.new()
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.position = Vector2(cx, home.y + sz.y - 114.0)
		tag.draw.connect(_draw_name_tag.bind(tag))
		holder.add_child(tag)
		_line[i] = {"tex": tex, "tag": tag, "key": "", "home": home, "pool": pools[i], "at": 0, "dim": 0.82 if sc < 1.0 else 1.0}
	for i in LINEUP:
		_set_lineup(i, str((_line[i]["pool"] as Array)[0]), true)
	var t := Timer.new()
	t.wait_time = 3.4
	t.autostart = true
	t.timeout.connect(func():
		# Take turns; a series with only one duelist keeps the one it has.
		for tries in LINEUP:
			var slot: Dictionary = _line[[1, 3, 2, 0][_feat_turn % LINEUP]]
			_feat_turn += 1
			var pool: Array = slot["pool"]
			if pool.size() < 2:
				continue
			slot["at"] = (int(slot["at"]) + 1) % pool.size()
			_set_lineup(_line.find(slot), str(pool[int(slot["at"])]), false)
			break)
	add_child(t)


## The busts melt into the street at the waist instead of ending in a hard cut.
var _fade: ShaderMaterial


func _fade_mat() -> ShaderMaterial:
	if _fade == null:
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
uniform float shade = 0.0;          // 1 = a dark silhouette (while one duelist swaps for another)
uniform float dim = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb = mix(c.rgb * dim, vec3(0.035, 0.05, 0.11), shade);
	c.a *= 1.0 - smoothstep(0.74, 0.9, UV.y);
	// Nothing ends in a hard line at the edge of its picture.
	c.a *= smoothstep(0.0, 0.05, UV.x) * smoothstep(1.0, 0.95, UV.x) * smoothstep(0.0, 0.03, UV.y);
	COLOR = c;
}
"""
		_fade = ShaderMaterial.new()
		_fade.shader = sh
	return _fade


func _set_lineup(i: int, key: String, instant: bool) -> void:
	var slot: Dictionary = _line[i]
	var tex: TextureRect = slot["tex"]
	var tag: Control = slot["tag"]
	var mat: ShaderMaterial = tex.material
	mat.set_shader_parameter("dim", slot["dim"])
	var d := Characters.get_char(key)
	var swap := func():
		slot["key"] = key
		tex.texture = Portraits.get_portrait(key, true)
		tag.set_meta("name", str(d.get("short", key)).to_upper())
		tag.set_meta("color", Color(d.get("color", Comic.BLUE)))
		tag.queue_redraw()
	var home: Vector2 = slot["home"]
	if instant:
		swap.call()
		tex.modulate.a = 0.0
		tag.modulate.a = 0.0
		tex.position = home + Vector2(40, 0)
		var tw0 := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw0.tween_property(tex, "position", home, 0.4).set_delay(0.1 + i * 0.05)
		tw0.tween_property(tex, "modulate:a", 1.0, 0.3).set_delay(0.1 + i * 0.05)
		tw0.tween_property(tag, "modulate:a", 1.0, 0.25).set_delay(0.25 + i * 0.05)
		return
	# A clean swap: the duelist goes to a dark silhouette, the next one steps into it, and
	# the light comes back up. Nobody is ever see-through.
	Portraits.get_portrait(key)            # start drawing the next face now
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("shade", v), 0.0, 1.0, 0.2)
	tw.parallel().tween_property(tag, "modulate:a", 0.0, 0.15)
	tw.tween_callback(swap)
	tw.tween_interval(0.16)
	tw.tween_method(func(v: float): mat.set_shader_parameter("shade", v), 1.0, 0.0, 0.3)
	tw.parallel().tween_property(tag, "modulate:a", 1.0, 0.25)


func _draw_name_tag(c: Control) -> void:
	if not c.has_meta("name"):
		return
	var nm := str(c.get_meta("name"))
	var col: Color = c.get_meta("color")
	var f := Comic.chunky_font()
	var size := 30
	var w := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 44.0
	var r := Rect2(-w / 2.0, 0, w, 38)
	var pts := Comic.slab(c, r, 10.0, Color(0.05, 0.075, 0.16, 0.94), Color(0.03, 0.045, 0.1, 0.96), 1.0, Vector2(0, 3))
	c.draw_polyline(PackedVector2Array([pts[0], pts[3]]), col.lightened(0.2), 4.0, true)
	c.draw_string(f, Vector2(r.position.x + 24, 28), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)


## The profile bar in the top left: your face, name and title, your Duel Points and how far
## along the current level you are. Press it to open the duelist creator.
var _chip: Button
var _chip_dp: Label


func _build_profile_chip() -> void:
	var chip := Button.new()
	_chip = chip
	chip.position = Vector2(40, 22)
	chip.size = Vector2(700, 112)
	chip.flat = true
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.tooltip_text = "Change your duelist"
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		chip.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	chip.draw.connect(_draw_chip)
	chip.mouse_entered.connect(chip.queue_redraw)
	chip.mouse_exited.connect(chip.queue_redraw)
	add_child(chip)
	var frame := Panel.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.0211, 0.026, 0.0897)
	fsb.set_corner_radius_all(46)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.position = Vector2(10, 10)
	frame.size = Vector2(92, 92)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(frame)
	_chip_avatar = TextureRect.new()
	_chip_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chip_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_chip_avatar.position = Vector2(-10, -4)
	_chip_avatar.size = Vector2(112, 140)
	frame.add_child(_chip_avatar)
	_chip_name = Comic.label("", 34, Color.WHITE)
	_chip_name.position = Vector2(126, 14)
	_chip_name.size = Vector2(290, 40)
	_chip_name.clip_text = true
	_chip_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_name)
	_chip_sub = UITheme.label("", 18, UITheme.TEXT_DIM, UITheme.semi_font())
	_chip_sub.position = Vector2(128, 58)
	_chip_sub.size = Vector2(290, 26)
	_chip_sub.clip_text = true
	_chip_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_sub)
	_chip_dp = Comic.label("", 32, Comic.YELLOW)
	_chip_dp.position = Vector2(476, 14)
	_chip_dp.size = Vector2(190, 40)
	_chip_dp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_dp)
	chip.pressed.connect(func(): _open_panel(SettingsPanel.open_profile(self, func(): _open_profile(false))))
	Profile.changed.connect(_refresh_chip)
	Collection.changed.connect(_refresh_chip)
	Portraits.flushed.connect(_on_flushed)
	_refresh_chip()


func _draw_chip() -> void:
	var c := _chip
	var hot := c.is_hovered()
	var pts := Comic.slab(c, Rect2(50, 10, 640, 88), 18.0, Color(0.07, 0.1, 0.2, 0.92) if hot else Color(0.05, 0.075, 0.16, 0.9), Color(0.03, 0.045, 0.1, 0.94), 1.0, Vector2(0, 4))
	if hot:
		Comic.outline(c, pts, UITheme.ACCENT, 2.0)
	# The coin.
	var cc := Vector2(456, 39)
	c.draw_circle(cc, 12.0, Color("c98a00"))
	c.draw_circle(cc, 9.5, Comic.YELLOW)
	c.draw_colored_polygon(PackedVector2Array([cc + Vector2(0, -6), cc + Vector2(4.5, 0), cc + Vector2(0, 6), cc + Vector2(-4.5, 0)]), Color("a86a00"))
	c.draw_line(Vector2(428, 22), Vector2(412, 88), Color(1, 1, 1, 0.12), 1.5, true)
	# The level and how far along it is (three wins a level).
	var f := Comic.button_font()
	c.draw_string(f, Vector2(440, 82), Loc.t("Lv %d") % Profile.level(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	var bar := Rect2(500, 70, 156, 8)
	c.draw_rect(bar, Color(1, 1, 1, 0.14))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(Profile.wins % 3) / 3.0, bar.size.y)), UITheme.ACCENT)
	# The ring around the face.
	c.draw_arc(Vector2(56, 56), 48.0, 0.0, TAU, 48, UITheme.ACCENT if hot else Color(1, 1, 1, 0.85), 3.0, true)


func _on_flushed() -> void:
	_refresh_chip()
	for i in _line.size():
		if _line[i] != null and str(_line[i]["key"]) != "":
			(_line[i]["tex"] as TextureRect).texture = Portraits.get_portrait(str(_line[i]["key"]), true)


func _refresh_chip() -> void:
	_chip_avatar.texture = Portraits.get_portrait("player")
	_chip_name.text = Profile.duelist_name
	_chip_sub.text = "%s   ·   %s" % [Profile.title_text(), Loc.t("%d W  %d L") % [Profile.wins, Profile.losses]]
	_chip_dp.text = DpPurse._fmt(Collection.dp)
	_chip.queue_redraw()


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
	_anchor_bottom(left, 250, 900)
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
	tw.tween_property(_title_box, "modulate:a", 1.0, 0.35)
	tw.tween_property(_title_box, "position:x", _title_box.position.x + 40, 0.45)
	for i in _items.size():
		var item := _items[i]
		item.modulate.a = 0.0
		tw.tween_property(item, "modulate:a", 1.0, 0.18).set_delay(0.04 + i * 0.022)
		if item.get_parent() is Container:
			continue
		var home := item.position
		item.position = home + Vector2(-18, 8)
		tw.tween_property(item, "position", home, 0.24).set_delay(0.04 + i * 0.022)
	await get_tree().create_timer(0.22).timeout
	if not is_inside_tree() or Router._busy:
		return
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
