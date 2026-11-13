class_name DuelistPanel
extends Control
## The big corner panel of one duelist: a slanted slab in their color, the live 3D character
## leaning out of it, and the Life Points on a ribbon. Yours sits bottom left, theirs top right.

const SIZE := Vector2(470, 204)
const BAR_W := 250.0

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
	# The character. Yours leans out over the top edge; theirs is cut by the panel.
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if p == 0:
		clip.position = Vector2(-6, -96)
		clip.size = Vector2(250, 300)
	else:
		clip.position = Vector2(SIZE.x - 232, 4)
		clip.size = Vector2(228, SIZE.y - 10)
	add_child(clip)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size = Vector2(250, 312)
	portrait.position = Vector2(0, 0) if p == 0 else Vector2(-10, -8)
	portrait.pivot_offset = portrait.size / 2.0
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(portrait)
	_front = Control.new()
	_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
	var x0 := 206.0 if p == 0 else 22.0
	name_label = Comic.label("", 25, Color.WHITE, 7)
	name_label.position = Vector2(x0 + 4, 10)
	name_label.size = Vector2(250, 32)
	name_label.clip_text = true
	_front.add_child(name_label)
	var tag := Comic.label("LP", 22, Comic.YELLOW, 6)
	tag.position = Vector2(x0 + 10, 84)
	_front.add_child(tag)
	lp_label = Comic.label("8000", 64, Color.WHITE, 12)
	lp_label.position = Vector2(x0 + 46, 44)
	lp_label.size = Vector2(210, 78)
	lp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_front.add_child(lp_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(Comic.INK, 0.85)
	bar_bg.position = Vector2(x0 + 2, 130)
	bar_bg.size = Vector2(BAR_W + 4, 14)
	_front.add_child(bar_bg)
	lp_bar = ColorRect.new()
	lp_bar.color = Comic.GREEN
	lp_bar.position = Vector2(2, 2)
	lp_bar.size = Vector2(BAR_W, 10)
	bar_bg.add_child(lp_bar)
	counts = UITheme.label("", 16, Color(1, 1, 1, 0.92), UITheme.semi_font())
	counts.add_theme_color_override("font_outline_color", Comic.INK)
	counts.add_theme_constant_override("outline_size", 5)
	counts.position = Vector2(x0 + 2, 152)
	counts.size = Vector2(262, 26)
	counts.mouse_filter = Control.MOUSE_FILTER_STOP
	counts.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_front.add_child(counts)
	set_process(true)


## The duelist whose turn it is gets a bright rim and a small TURN tab.
func set_active(on: bool) -> void:
	_active = on
	queue_redraw()
	_front.queue_redraw()


func _process(delta: float) -> void:
	if _active:
		_pulse += delta
		_front.queue_redraw()
	# The bar goes from green to yellow to red as the Life Points drop.
	var f := clampf(lp_bar.size.x / BAR_W, 0.0, 1.0)
	lp_bar.color = Comic.RED.lerp(Comic.YELLOW, clampf(f * 2.0, 0, 1)) if f < 0.5 else Comic.YELLOW.lerp(Comic.GREEN, clampf(f * 2.0 - 1.0, 0, 1))


func _shape() -> PackedVector2Array:
	var w := SIZE.x
	var h := SIZE.y
	if side == 0:
		# Bottom left corner of the screen: the right edge leans.
		return PackedVector2Array([Vector2(-8, 0), Vector2(w - 78, 0), Vector2(w, h + 8), Vector2(-8, h + 8)])
	return PackedVector2Array([Vector2(0, -8), Vector2(w + 8, -8), Vector2(w + 8, h), Vector2(78, h)])


func _draw() -> void:
	var top := Comic.BLUE if side == 0 else Comic.RED
	var bottom := Comic.BLUE_DEEP if side == 0 else Comic.RED_DEEP
	var pts := _shape()
	Comic.shape(self, pts, top.lightened(0.12), bottom, 0.0, Vector2(6 if side == 0 else -6, -7 if side == 0 else 7))
	Comic.dots(self, pts, Color(1, 1, 1, 0.16), Vector2(1, 0) if side == 0 else Vector2(0, 1), 15.0, 6.0, 0.7)
	# A lighter diagonal stripe, like a printed panel.
	var stripe := PackedVector2Array([Vector2(60, 0), Vector2(150, 0), Vector2(40, SIZE.y), Vector2(-50, SIZE.y)]) if side == 0 \
			else PackedVector2Array([Vector2(SIZE.x - 60, 0), Vector2(SIZE.x + 30, 0), Vector2(SIZE.x - 80, SIZE.y), Vector2(SIZE.x - 170, SIZE.y)])
	draw_colored_polygon(stripe, Color(1, 1, 1, 0.09))
	Comic.outline(self, pts, Comic.INK, 6.0)


func _draw_front() -> void:
	var c := _front
	var x0 := 206.0 if side == 0 else 22.0
	# The Life Point ribbon: a dark slanted band across the panel.
	var rib := Comic.quad(Rect2(x0 - 12, 46, 286, 78), 16.0)
	Comic.shape(c, rib, Color(Comic.INK, 0.9), Color(0.03, 0.05, 0.16, 0.92), 0.0, Vector2(0, 5))
	var edge := Comic.YELLOW if _active else (Comic.SKY if side == 0 else Color("ff9aa6"))
	c.draw_polyline(PackedVector2Array([rib[0], rib[1]]), edge, 4.0, true)
	c.draw_polyline(PackedVector2Array([rib[3], rib[2]]), Color(edge, 0.55), 3.0, true)
	if _active:
		var a := 0.65 + 0.35 * sin(_pulse * 5.0)
		Comic.outline(c, _shape(), Color(Comic.YELLOW, a), 4.0)
		# The TURN tab.
		# The TURN tab sticks out of the panel's free edge.
		var tab := Comic.quad(Rect2(250, -31, 100, 34) if side == 0 else Rect2(110, SIZE.y - 3, 100, 34), 8.0)
		Comic.shape(c, tab, Comic.YELLOW, Comic.ORANGE, 3.0, Vector2(0, 3))
		var f := Comic.chunky_font()
		Comic.text(c, f, tab[3] + Vector2(6, -9), Loc.t("TURN"), 20, Comic.INK, 0, Comic.INK, 76, HORIZONTAL_ALIGNMENT_CENTER)
