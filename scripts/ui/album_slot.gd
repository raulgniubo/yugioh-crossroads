class_name AlbumSlot
extends Control
## One pocket of the Card Album binder. A clear plastic sleeve with a card in it: the card you
## own (with how many copies and its foil), a card you have only met in a duel (dimmed, marked
## SEEN), or an empty pocket with the card's number and a question mark.

signal picked(slot: AlbumSlot)

const CARD := Vector2(128, 186)

var id := 0
var number := 0                # its place in the set: #001, #002...
var state := "unknown"         # owned | seen | lookup (found by searching its name) | unknown
var copies := 0
var tint := Color("7fe8ff")    # the set's color
var selected := false:
	set(v):
		selected = v
		queue_redraw()
		if _over:
			_over.queue_redraw()
var is_new := false            # owned, but the album has not shown it to you yet

var _card: TextureRect
var _over: Control
var _hover := 0.0
var _sel_t := 0.0
var _loaded := false


func _init() -> void:
	custom_minimum_size = CARD + Vector2(14, 14)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	_card = TextureRect.new()
	_card.position = Vector2(7, 7)
	_card.size = CARD
	_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	_over = Control.new()
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_over)
	add_child(_over)
	mouse_entered.connect(func():
		Sfx.play("blip", -20.0, 1.5))


func setup(card_id: int, num: int, st: String, n: int, col: Color, fresh := false) -> void:
	id = card_id
	number = num
	state = st
	copies = n
	tint = col
	is_new = fresh
	_loaded = false
	_card.texture = null
	_card.material = null
	_card.modulate = Color.WHITE
	visible = id != 0
	queue_redraw()
	_over.queue_redraw()


## Does it still need its picture loaded? (The album loads a few each frame.)
func wants_face() -> bool:
	return id != 0 and state != "unknown" and not _loaded


func load_face() -> void:
	_loaded = true
	_card.texture = Cards.get_face(id)
	if state == "owned":
		Foil.apply(_card, CardData.rarity(id))
		_card.modulate = Color.WHITE
	else:
		_card.material = null
		_card.modulate = Color(0.42, 0.47, 0.58, 1.0)
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.18)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		picked.emit(self)
		accept_event()


func _process(delta: float) -> void:
	var h := 1.0 if is_hovered_now() else 0.0
	if not is_equal_approx(_hover, h):
		_hover = move_toward(_hover, h, delta * 8.0)
		queue_redraw()
		_over.queue_redraw()
	if selected:
		_sel_t += delta
		_over.queue_redraw()


func is_hovered_now() -> bool:
	return get_global_rect().has_point(get_global_mouse_position()) and is_visible_in_tree()


func _draw() -> void:
	if id == 0:
		return
	var r := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	# The sleeve: a soft dark pocket with a thin clear edge.
	var pocket := StyleBoxFlat.new()
	pocket.bg_color = Color(0.02, 0.035, 0.07, 0.75)
	pocket.set_corner_radius_all(9)
	pocket.border_color = Color(1, 1, 1, 0.07 + 0.12 * _hover)
	pocket.set_border_width_all(1)
	draw_style_box(pocket, r)
	if state == "unknown":
		# An empty pocket: the shape of a card, its number, a question mark.
		var cr := Rect2(Vector2(7, 7), CARD)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(tint.darkened(0.82), 0.85)
		sb.set_corner_radius_all(7)
		sb.border_color = Color(tint, 0.22 + 0.25 * _hover)
		sb.set_border_width_all(2)
		draw_style_box(sb, cr)
		var inner := cr.grow(-12)
		draw_rect(inner, Color(tint, 0.06), false, 1.0)
		var f := UITheme.title_font()
		var q := "?"
		var qs := f.get_string_size(q, HORIZONTAL_ALIGNMENT_LEFT, -1, 64)
		draw_string(f, cr.get_center() + Vector2(-qs.x / 2.0, 22), q, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(tint, 0.28 + 0.2 * _hover))
		var num := "#%03d" % number
		var fs := UITheme.semi_font()
		var ns := fs.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
		draw_string(fs, Vector2(cr.get_center().x - ns.x / 2.0, cr.end.y - 14), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.32))


func _draw_over() -> void:
	if id == 0:
		return
	var cr := Rect2(Vector2(7, 7), CARD)
	# Light catching the sleeve.
	var sheen := PackedVector2Array([cr.position + Vector2(CARD.x * 0.55, 0), cr.position + Vector2(CARD.x * 0.8, 0), cr.position + Vector2(CARD.x * 0.25, CARD.y), cr.position + Vector2(0, CARD.y)])
	_over.draw_colored_polygon(sheen, Color(1, 1, 1, 0.035 + 0.03 * _hover))
	if state == "seen" or state == "lookup":
		var tag := Rect2(cr.position + Vector2(0, CARD.y * 0.42), Vector2(CARD.x, 30))
		_over.draw_rect(tag, Color(0.02, 0.04, 0.09, 0.82))
		var f := UITheme.title_font()
		var t := Loc.t("SEEN") if state == "seen" else Loc.t("MISSING")
		var ts := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		_over.draw_string(f, Vector2(cr.get_center().x - ts.x / 2.0, tag.position.y + 23), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.75, 0.85, 1.0, 0.9))
	if state == "owned" and copies > 1:
		var t2 := "x%d" % copies
		var f2 := UITheme.title_font()
		var w := f2.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 14.0
		var b := Rect2(Vector2(cr.end.x - w + 3, cr.end.y - 26), Vector2(w, 26))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.032, 0.058, 0.125, 0.95)
		sb.set_corner_radius_all(8)
		sb.border_color = Color(UITheme.GOLD, 0.9)
		sb.set_border_width_all(1)
		_over.draw_style_box(sb, b)
		_over.draw_string(f2, b.position + Vector2(7, 20), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UITheme.GOLD)
	if is_new and state == "owned":
		# (The tag fits its word: "NUEVA" was cut off in a box sized for "NEW".)
		var nt := Loc.t("NEW")
		var nw := UITheme.title_font().get_string_size(nt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var nb := Rect2(cr.position + Vector2(-3, -3), Vector2(nw + 14, 20))
		var sb2 := StyleBoxFlat.new()
		sb2.bg_color = UITheme.ACCENT
		sb2.set_corner_radius_all(6)
		_over.draw_style_box(sb2, nb)
		_over.draw_string(UITheme.title_font(), nb.position + Vector2(7, 16), nt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Comic.INK)
	if selected or _hover > 0.01:
		var k := 1.0 if selected else _hover * 0.6
		var pulse := 0.75 + 0.25 * sin(_sel_t * 5.0) if selected else 1.0
		var ring := StyleBoxFlat.new()
		ring.draw_center = false
		ring.set_corner_radius_all(10)
		ring.border_color = Color(UITheme.ACCENT if selected else Color.WHITE, 0.95 * k * pulse)
		ring.set_border_width_all(3 if selected else 2)
		ring.shadow_color = Color(UITheme.ACCENT, 0.35 * k * pulse) if selected else Color(0, 0, 0, 0)
		ring.shadow_size = 10 if selected else 0
		_over.draw_style_box(ring, Rect2(Vector2(1, 1), size - Vector2(2, 2)))
