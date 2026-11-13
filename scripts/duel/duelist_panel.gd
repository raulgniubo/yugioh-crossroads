class_name DuelistPanel
extends Control
## The corner panel of one duelist: a slanted glass slab edged in their color, the live 3D
## character, and the Life Points. Yours sits bottom left, theirs top right. Everything on it
## stays inside the slab; the turn marker is drawn behind the character, never across it.

const SIZE := Vector2(510, 190)
const BAR_W := 240.0

var side := 0
var portrait: TextureRect
var name_label: Label
var lp_label: Label
var lp_bar: ColorRect
var counts: Label
var _front: Control
var _active := false
var _pulse := 0.0


func _init(p: int) -> void:
	side = p
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP if p == 1 else Control.MOUSE_FILTER_IGNORE
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if p == 0:
		# Yours leans out a little over the top edge.
		clip.position = Vector2(0, -70)
		clip.size = Vector2(190, SIZE.y + 70)
	else:
		clip.position = Vector2(SIZE.x - 190, 0)
		clip.size = Vector2(190, SIZE.y - 2)
	add_child(clip)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size = Vector2(208, 260)
	portrait.position = Vector2(-9, 0) if p == 0 else Vector2(-9, -6)
	portrait.pivot_offset = portrait.size / 2.0
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(portrait)
	_front = Control.new()
	_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_front)
	var x0 := 198.0 if p == 0 else 78.0
	name_label = Comic.label("", 26, Color.WHITE)
	name_label.position = Vector2(x0, 12)
	name_label.size = Vector2(BAR_W, 32)
	name_label.clip_text = true
	_front.add_child(name_label)
	var tag := UITheme.label("LP", 20, Color(side_color().lightened(0.45), 0.95), UITheme.semi_font())
	tag.position = Vector2(x0, 74)
	_front.add_child(tag)
	lp_label = UITheme.label("8000", 66, Color.WHITE, Comic.chunky_font())
	lp_label.position = Vector2(x0 + 30, 34)
	lp_label.size = Vector2(BAR_W - 30, 76)
	lp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	lp_label.add_theme_constant_override("shadow_offset_y", 3)
	_front.add_child(lp_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.12)
	bar_bg.position = Vector2(x0, 116)
	bar_bg.size = Vector2(BAR_W, 6)
	_front.add_child(bar_bg)
	lp_bar = ColorRect.new()
	lp_bar.color = Comic.GREEN
	lp_bar.size = Vector2(BAR_W, 6)
	bar_bg.add_child(lp_bar)
	counts = UITheme.label("", 16, UITheme.TEXT_DIM, UITheme.semi_font())
	counts.position = Vector2(x0, 132)
	counts.size = Vector2(BAR_W + 10, 24)
	counts.clip_text = true
	counts.mouse_filter = Control.MOUSE_FILTER_STOP
	counts.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_front.add_child(counts)
	set_process(true)


func side_color() -> Color:
	return Comic.BLUE if side == 0 else Comic.RED


## The duelist whose turn it is gets a bright edge and a small TURN tab.
func set_active(on: bool) -> void:
	_active = on
	queue_redraw()


func _process(delta: float) -> void:
	if _active:
		_pulse += delta
		queue_redraw()
	# The bar goes from green to yellow to red as the Life Points drop.
	var f := clampf(lp_bar.size.x / BAR_W, 0.0, 1.0)
	lp_bar.color = Comic.RED.lerp(Comic.YELLOW, clampf(f * 2.0, 0, 1)) if f < 0.5 else Comic.YELLOW.lerp(Comic.GREEN, clampf(f * 2.0 - 1.0, 0, 1))


func _shape() -> PackedVector2Array:
	var w := SIZE.x
	var h := SIZE.y
	if side == 0:
		# Bottom left: the free (right) edge leans out toward the bottom, so every row fits.
		return PackedVector2Array([Vector2(-4, 0), Vector2(w - 60, 0), Vector2(w, h + 4), Vector2(-4, h + 4)])
	return PackedVector2Array([Vector2(60, -4), Vector2(w + 4, -4), Vector2(w + 4, h), Vector2(0, h)])


## Everything here is drawn under the character and the text.
func _draw() -> void:
	var col := side_color()
	var pts := _shape()
	Comic.shape(self, pts, Color(0.05, 0.075, 0.16, 0.94), Color(0.025, 0.04, 0.09, 0.96), 0.0, Vector2(0, -4 if side == 0 else 4))
	# Their color washes in from the character's side.
	var wash := PackedVector2Array([pts[0], Vector2(pts[0].x + 300, pts[0].y), Vector2(pts[3].x + 230, pts[3].y), pts[3]]) if side == 0 \
			else PackedVector2Array([Vector2(pts[1].x - 300, pts[1].y), pts[1], pts[2], Vector2(pts[2].x - 230, pts[2].y)])
	var c_in := Color(col, 0.55)
	var c_out := Color(col, 0.0)
	draw_polygon(wash, PackedColorArray([c_in, c_out, c_out, c_in]) if side == 0 else PackedColorArray([c_out, c_in, c_in, c_out]))
	# The free slanted edge carries the side's color; it brightens on that duelist's turn.
	var e0 := pts[1] if side == 0 else pts[0]
	var e1 := pts[2] if side == 0 else pts[3]
	var glow := 0.5 + 0.5 * sin(_pulse * 4.0)
	draw_polyline(PackedVector2Array([e0, e1]), Color(Comic.YELLOW, 0.75 + 0.25 * glow) if _active else Color(col.lightened(0.3), 0.9), 4.0 if _active else 3.0, true)
	var top0 := pts[0] if side == 0 else pts[3]
	var top1 := pts[1] if side == 0 else pts[2]
	draw_polyline(PackedVector2Array([top0, top1]), Color(1, 1, 1, 0.18), 1.5, true)
	if _active:
		# The TURN tab sits on the free edge, clear of the character and the numbers.
		var f := Comic.button_font()
		var word := Loc.t("TURN")
		var tw := f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		var tab := Comic.quad(Rect2(SIZE.x - 168 - tw, -30, tw + 44, 28) if side == 0 else Rect2(84, SIZE.y + 2, tw + 44, 28), 8.0)
		Comic.shape(self, tab, Comic.YELLOW, Comic.ORANGE, 0.0, Vector2(0, 2))
		draw_string(f, tab[3] + Vector2(20, -7), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Comic.INK)
