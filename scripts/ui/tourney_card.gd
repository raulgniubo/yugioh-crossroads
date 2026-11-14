class_name TourneyCard
extends Button
## One tournament on the Tournaments screen: a banner in the event's color with a trophy on it,
## what it is, where you stand (badges earned, round reached, titles held) and what it pays.

var def: Dictionary
var id := ""
var _hover := 0.0
var _target := 0.0


func _init(tid: String) -> void:
	id = tid
	def = Tournament.DEFS[tid]
	custom_minimum_size = Vector2(0, 148)
	focus_mode = Control.FOCUS_ALL
	flat = true
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(s, empty)
	mouse_entered.connect(func(): _target = 1.0)
	mouse_exited.connect(func(): _target = 1.0 if has_focus() else 0.0)
	focus_entered.connect(func(): _target = 1.0)
	focus_exited.connect(func(): _target = 0.0)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _process(delta: float) -> void:
	var was := _hover
	_hover = move_toward(_hover, _target if not disabled else 0.0, delta * 7.0)
	if was != _hover:
		queue_redraw()


func _draw() -> void:
	var col := Color(def.get("color", UITheme.ACCENT))
	var locked := disabled
	var e := ease(_hover, -2.0)
	var w := size.x
	var h := size.y - 10.0
	var body := StyleBoxFlat.new()
	body.bg_color = Color(0.05, 0.075, 0.15, 0.96).lerp(Color(0.08, 0.12, 0.23, 0.98), e)
	body.set_corner_radius_all(14)
	body.set_border_width_all(1)
	body.border_color = Color(1, 1, 1, 0.08).lerp(Color(col, 0.75), e)
	body.shadow_color = Color(0, 0, 0, 0.35)
	body.shadow_size = 6
	draw_style_box(body, Rect2(0, 0, w, h))
	# The banner: the event's color, cut on a slant, the trophy standing on it.
	var bw := 128.0
	var ban := col.darkened(0.55) if locked else col.darkened(0.12)
	var banner := StyleBoxFlat.new()
	banner.bg_color = ban
	banner.corner_radius_top_left = 14
	banner.corner_radius_bottom_left = 14
	draw_style_box(banner, Rect2(0, 0, bw - 26.0, h))
	draw_colored_polygon(PackedVector2Array([Vector2(bw - 27.0, 0), Vector2(bw, 0), Vector2(bw - 27.0, h)]), ban)
	for k in 3:
		# Three pale stripes across the banner, the way a pennant has them.
		var x0 := 14.0 + k * 22.0
		draw_colored_polygon(PackedVector2Array([Vector2(x0 + 30.0, 0), Vector2(x0 + 40.0, 0), Vector2(x0 + 10.0 - 30.0 + 30.0, h), Vector2(x0 - 30.0 + 30.0, h)]), Color(1, 1, 1, 0.07))
	_trophy(Vector2(50.0, h / 2.0 - 4.0), Color(1.0, 0.95, 0.8) if not locked else Color(0.6, 0.62, 0.68), ban)
	# Words.
	var x := bw + 14.0
	var tf := UITheme.title_font()
	var bf := UITheme.body_font()
	var sf := UITheme.semi_font()
	var name_col := Color(0.6, 0.63, 0.7) if locked else Color.WHITE.lerp(col.lightened(0.5), 0.35)
	draw_string(tf, Vector2(x, 36.0), Loc.t(str(def["name"])).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w - x - 150.0, 28, name_col)
	var where := {"domino": "Domino City", "academy": "Duel Academy", "ride": "The Highway"}.get(str(def.get("district", "")), "") as String
	draw_string(sf, Vector2(x, 58.0), Loc.t(where).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col.lightened(0.3), 0.9 if not locked else 0.45))
	# The blurb, wrapped to two lines.
	var blurb := Loc.t(str(def.get("blurb", "")))
	var para := TextParagraph.new()
	para.add_string(blurb, bf, 14)
	para.width = w - x - 26.0
	para.max_lines_visible = 2
	para.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	para.draw(get_canvas_item(), Vector2(x, 66.0), Color(0.8, 0.85, 0.94, 0.8 if not locked else 0.4))
	# Where you stand.
	var s := Tournament.st(id)
	var titles := Tournament.titles(id)
	var missing: Array = Tournament.missing(id)
	var y := h - 18.0
	var need := int(def.get("need", 0))
	var stage := str(s.get("stage", ""))
	var state := ""
	var state_col := col.lightened(0.35)
	if locked:
		state = Loc.t("Locked: needs %s") % ", ".join(missing)
		state_col = Color(0.72, 0.5, 0.52)
	elif stage == "qualify" and need > 0:
		var have := mini(int(s.get("badges", 0)), need)
		for k in need:
			var c := Vector2(x + 8.0 + k * 20.0, y - 5.0)
			draw_circle(c, 7.0, Color(0, 0, 0, 0.4))
			draw_circle(c, 5.5, col if k < have else Color(1, 1, 1, 0.14))
			if k < have:
				draw_circle(c - Vector2(1.5, 1.5), 1.6, Color(1, 1, 1, 0.7))
		x += need * 20.0 + 10.0
		state = Loc.t("Finals Badges %d / %d") % [have, need]
	elif stage != "" and stage != "qualify":
		state = Loc.t("Finals under way. Go to the desk.")
	else:
		state = Loc.t("Open. Go to the desk to enter.")
	draw_string(sf, Vector2(x, y), state, HORIZONTAL_ALIGNMENT_LEFT, w - x - 190.0, 15, state_col)
	# Top right: titles held. Bottom right: the purse.
	if titles > 0:
		var tag := Loc.t("Champion  x%d") % titles
		var tw := sf.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 22.0
		var chip := StyleBoxFlat.new()
		chip.bg_color = Color(UITheme.GOLD, 0.95)
		chip.set_corner_radius_all(11)
		draw_style_box(chip, Rect2(w - tw - 14.0, 14.0, tw, 24.0))
		draw_string(sf, Vector2(w - tw - 3.0, 31.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.2, 0.13, 0.02))
	var purse := "%d DP" % int(def.get("prize_dp", 0))
	var pw := tf.get_string_size(purse, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(tf, Vector2(w - pw - 44.0, y + 2.0), purse, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(UITheme.GOLD, 0.95 if not locked else 0.4))
	# An arrow that leans in when you point at it, or a padlock.
	var ax := w - 26.0 + e * 4.0
	if locked:
		draw_rect(Rect2(ax - 8.0, y - 12.0, 16.0, 13.0), Color(0.6, 0.62, 0.68), true)
		draw_arc(Vector2(ax, y - 12.0), 5.5, PI, TAU, 10, Color(0.6, 0.62, 0.68), 2.5)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(ax - 6.0, y - 13.0), Vector2(ax + 5.0, y - 5.0), Vector2(ax - 6.0, y + 3.0)]), Color(col.lightened(0.3), 0.6 + 0.4 * e))
	if has_focus():
		draw_style_box(UITheme.focus_box(0.0, 14), Rect2(-2, -2, w + 4, h + 4))


## A cup with two handles on a stepped foot, drawn from plain shapes.
func _trophy(c: Vector2, col: Color, back: Color) -> void:
	var dark := col.darkened(0.25)
	draw_arc(c + Vector2(-19.0, -12.0), 9.0, PI * 0.5, PI * 1.5, 12, col, 3.5)
	draw_arc(c + Vector2(19.0, -12.0), 9.0, -PI * 0.5, PI * 0.5, 12, col, 3.5)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-20, -26), c + Vector2(20, -26), c + Vector2(15, -4), c + Vector2(6, 6), c + Vector2(-6, 6), c + Vector2(-15, -4)]), col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-20, -26), c + Vector2(-9, -26), c + Vector2(-7, -4), c + Vector2(-2, 6), c + Vector2(-6, 6), c + Vector2(-15, -4)]), Color(1, 1, 1, 0.35))
	draw_rect(Rect2(c + Vector2(-3.5, 6), Vector2(7, 9)), dark)
	draw_rect(Rect2(c + Vector2(-12, 15), Vector2(24, 5)), col)
	draw_rect(Rect2(c + Vector2(-16, 20), Vector2(32, 6)), dark)
	# A star cut into the cup.
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		pts.append(c + Vector2(0, -12) + Vector2(cos(a), sin(a)) * (7.0 if k % 2 == 0 else 3.0))
	draw_colored_polygon(pts, back)
