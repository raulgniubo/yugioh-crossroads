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


const DUOTONE := """
shader_type canvas_item;
// The city behind the menu, printed in blues: dark navy shadows, royal blue mids, sky highlights,
// with a little of its real color left in and halftone dots in the bright parts.
void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float l = smoothstep(0.02, 0.8, dot(c, vec3(0.3, 0.59, 0.11)));
	vec3 lo = vec3(0.03, 0.08, 0.36);
	vec3 mid = vec3(0.09, 0.34, 0.93);
	vec3 hi = vec3(0.62, 0.88, 1.0);
	vec3 col = l < 0.5 ? mix(lo, mid, l * 2.0) : mix(mid, hi, l * 2.0 - 1.0);
	col = mix(col, c, 0.22);
	vec2 g = FRAGCOORD.xy / 8.0;
	g.x += mod(floor(g.y), 2.0) * 0.5;
	float dr = clamp(l * 0.62, 0.0, 0.48);
	float dots = 1.0 - smoothstep(dr - 0.08, dr, length(fract(g) - 0.5));
	col += vec3(0.25, 0.3, 0.3) * dots * smoothstep(0.35, 0.9, l);
	COLOR = vec4(col, 1.0);
}
"""


func _build_background() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = DUOTONE
	var sm := ShaderMaterial.new()
	sm.shader = sh
	svc.material = sm
	add_child(svc)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_2X
	vp.own_world_3d = true
	svc.add_child(vp)
	var bg := Node3D.new()
	bg.set_script(MenuBackground)
	vp.add_child(bg)


func _build_overlay() -> void:
	# Big slanted bands of color over the city, like panels on a printed page: deep blue on the
	# left where the menu sits, a band in the featured duelist's color on the right.
	_bands = Control.new()
	_bands.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bands.draw.connect(_draw_bands)
	add_child(_bands)


var _bands: Control
var _band_color := Comic.BLUE
var _band_t := 0.0


func _draw_bands() -> void:
	var vs := get_viewport_rect().size
	var c := _bands
	# Left: the menu's own deep blue page.
	var left := PackedVector2Array([Vector2(0, 0), Vector2(vs.x * 0.47, 0), Vector2(vs.x * 0.36, vs.y), Vector2(0, vs.y)])
	c.draw_polygon(left, PackedColorArray([Color(0.04, 0.12, 0.42, 0.93), Color(0.05, 0.2, 0.6, 0.82), Color(0.03, 0.1, 0.4, 0.9), Color(0.02, 0.06, 0.3, 0.96)]))
	Comic.dots(c, left, Color(1, 1, 1, 0.07), Vector2(1, 0), 18.0, 8.0, 0.55)
	c.draw_polyline(PackedVector2Array([left[1], left[2]]), Comic.INK, 10.0, true)
	c.draw_polyline(PackedVector2Array([left[1] + Vector2(14, 0), left[2] + Vector2(14, 0)]), Color(1, 1, 1, 0.85), 5.0, true)
	c.draw_polyline(PackedVector2Array([left[1] + Vector2(30, 0), left[2] + Vector2(30, 0)]), Color(Comic.YELLOW, 0.9), 8.0, true)
	# Right: a band in the color of whoever is on show.
	var x0 := vs.x * 0.69
	var band := PackedVector2Array([Vector2(x0 + 150, 0), Vector2(vs.x, 0), Vector2(vs.x, vs.y), Vector2(x0 - 110, vs.y)])
	var col := _band_color
	c.draw_polygon(band, PackedColorArray([Color(col.lightened(0.15), 0.72), Color(col, 0.78), Color(col.darkened(0.45), 0.9), Color(col.darkened(0.35), 0.78)]))
	Comic.dots(c, band, Color(1, 1, 1, 0.16), Vector2(0, 1), 20.0, 9.0, 0.7)
	c.draw_polyline(PackedVector2Array([band[0], band[3]]), Comic.INK, 10.0, true)
	c.draw_polyline(PackedVector2Array([band[0] - Vector2(14, 0), band[3] - Vector2(14, 0)]), Color(1, 1, 1, 0.8), 5.0, true)
	# Speed streaks drifting across the band.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 9:
		var y := rng.randf() * vs.y
		var w := rng.randf_range(120.0, 380.0)
		var x := x0 + fposmod(rng.randf() * 900.0 + _band_t * rng.randf_range(60.0, 160.0), vs.x - x0 + w) - w
		c.draw_rect(Rect2(x, y, w, rng.randf_range(2.0, 5.0)), Color(1, 1, 1, 0.16))


func _process(delta: float) -> void:
	_band_t += delta
	if _bands:
		_bands.queue_redraw()


func _build_title() -> void:
	_title_box = Control.new()
	_title_box.position = Vector2(64, 150)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.rotation = -0.03
	add_child(_title_box)
	var big := UITheme.label("CROSSROADS", 104, Color.WHITE, Comic.shout_font())
	big.position = Vector2(0, 16)
	big.add_theme_color_override("font_outline_color", Comic.INK)
	big.add_theme_constant_override("outline_size", 24)
	big.add_theme_color_override("font_shadow_color", Comic.ORANGE_DEEP)
	big.add_theme_constant_override("shadow_offset_x", 6)
	big.add_theme_constant_override("shadow_offset_y", 8)
	big.add_theme_constant_override("shadow_outline_size", 24)
	_title_box.add_child(big)
	var small := Comic.label("YU-GI-OH!", 26, Comic.INK, 0)
	var ssb := Comic.box(Comic.YELLOW, 6, 0.2, 3, 3)
	ssb.content_margin_left = 16
	ssb.content_margin_right = 16
	ssb.content_margin_top = 0
	ssb.content_margin_bottom = 0
	small.add_theme_stylebox_override("normal", ssb)
	small.position = Vector2(6, 0)
	_title_box.add_child(small)
	var tag := Comic.label("Four eras. One story.", 22, Comic.YELLOW, 6)
	tag.position = Vector2(196, 2)
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
	_menu_box.position = Vector2(64, 318)
	add_child(_menu_box)
	Tournament.load_data()
	var won := 0
	for id in Tournament.DEFS:
		if Tournament.titles(str(id)) > 0:
			won += 1
	var st := _story_line()
	# The Story banner on top, then three rows of ribbons. Each row steps back along the slant.
	var story := MenuTile.new(str(st[0]), str(st[1]), str(st[2]), Comic.YELLOW, "✦", Vector2(720, 176), "", true)
	story.position = Vector2(30, 0)
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
	var y := 190.0
	for ri in rows.size():
		var x := 20.0 - ri * 10.0
		for e in rows[ri]:
			var tile := MenuTile.new(str(e[0]), str(e[1]), str(e[2]), Comic.ORANGE, str(e[3]), Vector2(356, 126), str(e[5]), false)
			tile.position = Vector2(x, y)
			tile.pressed.connect(e[4])
			tile.pressed.connect(func(): Sfx.play("click", -6.0))
			_menu_box.add_child(tile)
			_items.append(tile)
			x += 356.0 + 10.0
		y += 126.0 + 4.0
	# Settings and Quit are round buttons in the corner.
	var rounds := HBoxContainer.new()
	rounds.add_theme_constant_override("separation", 14)
	rounds.anchor_top = 1.0
	rounds.anchor_bottom = 1.0
	rounds.offset_left = 64
	rounds.offset_top = -128
	rounds.offset_bottom = -52
	add_child(rounds)
	var gear := RoundButton.new("gear", Comic.BLUE, 76.0)
	gear.tooltip_text = "Settings"
	gear.focus_mode = Control.FOCUS_ALL
	gear.pressed.connect(_on_settings)
	rounds.add_child(gear)
	_items.append(gear)
	if OS.has_feature("pc"):
		var quit := RoundButton.new("power", Comic.RED, 76.0)
		quit.tooltip_text = "Quit"
		quit.focus_mode = Control.FOCUS_ALL
		quit.pressed.connect(_on_quit)
		rounds.add_child(quit)
		_items.append(quit)


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
var _chip_avatar: TextureRect
var _chip_name: Label
var _chip_sub: Label


## The duelist on show: one big live character on the right, their name on a ribbon, and the
## band behind them in their color. A new one steps in every few seconds.
var _feat_idx := 0
var _feat_ribbon: Control
var _feat_keys: Array = []


func _build_featured() -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	move_child(holder, 2)
	for key in Characters.ORDER:
		if Avatars.has_avatar(str(key)):
			_feat_keys.append(str(key))
	if _feat_keys.is_empty():
		_feat_keys = Characters.ORDER.duplicate()
	_feat_idx = randi() % _feat_keys.size()
	_featured = TextureRect.new()
	_featured.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_featured.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_featured.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_featured)
	_feat_ribbon = Control.new()
	_feat_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feat_ribbon.draw.connect(_draw_feat_ribbon)
	holder.add_child(_feat_ribbon)
	_show_featured(true)
	var t := Timer.new()
	t.wait_time = 5.0
	t.autostart = true
	t.timeout.connect(func():
		_feat_idx = (_feat_idx + 1) % _feat_keys.size()
		_show_featured(false))
	add_child(t)


func _feat_rest() -> Rect2:
	var vs := get_viewport_rect().size
	var h := vs.y * 0.94
	return Rect2(vs.x - h * 0.8 - 40.0, vs.y - h, h * 0.8, h)


func _show_featured(instant: bool) -> void:
	var key := str(_feat_keys[_feat_idx])
	var d := Characters.get_char(key)
	var rest := _feat_rest()
	var swap := func():
		_featured.texture = Portraits.get_portrait(key, true)
		_featured.size = rest.size
		_band_color = Color(d.get("color", Comic.BLUE))
		_feat_ribbon.set_meta("name", str(d.get("short", key)).to_upper())
		_feat_ribbon.set_meta("era", str(d.get("era", "")).to_upper())
		_feat_ribbon.set_meta("color", _band_color)
		_feat_ribbon.queue_redraw()
	if instant:
		swap.call()
		_featured.position = rest.position + Vector2(120, 0)
		_featured.modulate.a = 0.0
		_feat_ribbon.modulate.a = 0.0
		var tw0 := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw0.tween_property(_featured, "position", rest.position, 0.6).set_delay(0.3)
		tw0.tween_property(_featured, "modulate:a", 1.0, 0.4).set_delay(0.3)
		tw0.tween_property(_feat_ribbon, "modulate:a", 1.0, 0.3).set_delay(0.6)
		return
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(_featured, "position:x", rest.position.x + 160.0, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_property(_featured, "modulate:a", 0.0, 0.2)
	tw.tween_property(_feat_ribbon, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(func():
		swap.call()
		_featured.position.x = rest.position.x - 140.0)
	tw.chain().tween_property(_featured, "position:x", rest.position.x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_featured, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_feat_ribbon, "modulate:a", 1.0, 0.25).set_delay(0.15)


func _draw_feat_ribbon() -> void:
	var c := _feat_ribbon
	if not c.has_meta("name"):
		return
	var vs := get_viewport_rect().size
	var nm := str(c.get_meta("name"))
	var era := str(c.get_meta("era"))
	var col: Color = c.get_meta("color")
	var f := Comic.chunky_font()
	var size := 78
	while size > 40 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 440.0:
		size -= 4
	var w := maxf(f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 120.0, 360.0)
	var r := Rect2(vs.x - w - 70.0, vs.y - 196.0, w, 104.0)
	Comic.slab(c, r, 26.0, Comic.INK, Color(0.04, 0.07, 0.25), 0.0, Vector2(0, 8))
	var pts := Comic.quad(r, 26.0)
	c.draw_polyline(PackedVector2Array([pts[0], pts[1]]), Comic.YELLOW, 6.0, true)
	c.draw_polyline(PackedVector2Array([pts[3], pts[2]]), col.lightened(0.3), 6.0, true)
	Comic.text(c, f, Vector2(r.position.x + 56, r.position.y + 50 + size * 0.34), nm, size, Color.WHITE, 12)
	if era != "":
		var ew := f.get_string_size(era, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var tab := Rect2(r.position.x + 70, r.position.y - 26, ew + 40, 32)
		Comic.slab(c, tab, 8.0, col.lightened(0.2), col.darkened(0.1), 4.0, Vector2(0, 3))
		Comic.text(c, f, tab.position + Vector2(22, 24), era, 20, Color.WHITE, 5)


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
	fsb.bg_color = Color(0.05, 0.12, 0.4)
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
	_chip_name = Comic.label("", 34, Color.WHITE, 8)
	_chip_name.position = Vector2(126, 14)
	_chip_name.size = Vector2(290, 40)
	_chip_name.clip_text = true
	_chip_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_name)
	_chip_sub = UITheme.label("", 18, Comic.YELLOW, UITheme.semi_font())
	_chip_sub.position = Vector2(128, 58)
	_chip_sub.size = Vector2(290, 26)
	_chip_sub.clip_text = true
	_chip_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_sub)
	_chip_dp = Comic.label("", 32, Comic.YELLOW, 8)
	_chip_dp.position = Vector2(476, 14)
	_chip_dp.size = Vector2(190, 40)
	_chip_dp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_dp)
	chip.pressed.connect(func(): _open_profile(false))
	Profile.changed.connect(_refresh_chip)
	Collection.changed.connect(_refresh_chip)
	Portraits.flushed.connect(_on_flushed)
	_refresh_chip()


func _draw_chip() -> void:
	var c := _chip
	var hot := c.is_hovered()
	var pts := Comic.slab(c, Rect2(50, 8, 640, 92), 20.0, Comic.BLUE.lightened(0.2 if hot else 0.08), Comic.BLUE_DEEP, 5.0, Vector2(0, 7))
	Comic.dots(c, pts, Color(1, 1, 1, 0.14), Vector2(1, 0), 13.0, 5.5, 0.5)
	# A darker pocket on the right for the Duel Points and the level.
	Comic.slab(c, Rect2(424, 14, 256, 80), 16.0, Color(Comic.INK, 0.78), Color(Comic.INK, 0.9), 0.0, Vector2.ZERO)
	# The coin.
	var cc := Vector2(456, 37)
	c.draw_circle(cc, 15.0, Comic.INK)
	c.draw_circle(cc, 12.5, Color("c98a00"))
	c.draw_circle(cc, 10.0, Comic.YELLOW)
	c.draw_colored_polygon(PackedVector2Array([cc + Vector2(0, -7), cc + Vector2(5, 0), cc + Vector2(0, 7), cc + Vector2(-5, 0)]), Color("a86a00"))
	# The level and how far along it is (three wins a level).
	var f := Comic.chunky_font()
	Comic.text(c, f, Vector2(440, 84), Loc.t("Lv %d") % Profile.level(), 20, Color.WHITE, 5)
	var bar := Rect2(506, 70, 150, 14)
	c.draw_rect(bar.grow(3.0), Comic.INK)
	c.draw_rect(bar, Color(0.1, 0.2, 0.5))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(Profile.wins % 3) / 3.0, bar.size.y)), Comic.GREEN)
	# The ring around the face.
	c.draw_arc(Vector2(56, 56), 49.0, 0.0, TAU, 48, Comic.INK, 9.0, true)
	c.draw_arc(Vector2(56, 56), 48.0, 0.0, TAU, 48, Comic.YELLOW if hot else Color.WHITE, 4.0, true)


func _on_flushed() -> void:
	_refresh_chip()
	if _featured:
		_show_featured(true)


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
	tw.tween_property(_title_box, "modulate:a", 1.0, 0.9).set_delay(0.2)
	tw.tween_property(_title_box, "position:x", _title_box.position.x + 40, 1.0).set_delay(0.2)
	for i in _items.size():
		var item := _items[i]
		item.modulate.a = 0.0
		tw.tween_property(item, "modulate:a", 1.0, 0.4).set_delay(0.35 + i * 0.05)
		if item.get_parent() is Container:
			continue
		var home := item.position
		item.position = home + Vector2(-30, 14)
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
