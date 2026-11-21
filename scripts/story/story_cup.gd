class_name StoryCup
extends Control
## The Dorm Cup table, put up in a story: the three dorms in the order they stand right now, with
## the points they really have (Campus.cup_points()), and what a dorm has just been given.
##
## table: {"title": "The Dorm Cup", "sub": "...", "gain": {"red": 15}, "mark": "red"}
##   gain: points that were just added (shown next to the total, in gold)
##   mark: the dorm the story is about right now (its plate is lit)

var table := {}


func _init(t: Dictionary) -> void:
	table = t


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -480
	v.offset_right = 480
	v.offset_top = -360
	v.offset_bottom = 360
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var head := UITheme.label(Loc.t(str(table.get("title", "The Dorm Cup"))).to_upper(), 58, Color.WHITE, UITheme.title_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	if str(table.get("sub", "")) != "":
		var sub := UITheme.label(Loc.t(str(table["sub"])), 24, UITheme.GOLD, UITheme.semi_font())
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	v.add_child(gap)
	var k := 0
	for d in order():
		v.add_child(_plate(int(d), k))
		k += 1
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	Sfx.play("gong", -10.0)


## The three dorms from first to last, the way the board in the agenda orders them.
static func order() -> Array:
	var out := [0, 1, 2]
	out.sort_custom(func(a, b): return Campus.cup_place(int(a)) < Campus.cup_place(int(b)))
	return out


func _plate(d: int, k: int) -> Control:
	var pts := Campus.cup_points()
	var key := str(Campus.DORMS[d])
	var lit := str(table.get("mark", "")) == key
	var pc := PanelContainer.new()
	var bg := Color(0.05, 0.08, 0.14, 0.95)
	var border := Color(1, 1, 1, 0.16)
	if lit:
		bg = Color(0.1, 0.22, 0.3, 0.98)
		border = UITheme.ACCENT
	var sb := UITheme.panel_box(bg, 12, border)
	sb.set_border_width_all(3 if lit else 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 26
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(0, 104)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	pc.add_child(h)
	var bar := ColorRect.new()
	bar.color = Campus.DORM_COLORS[d]
	bar.custom_minimum_size = Vector2(12, 0)
	h.add_child(bar)
	var place := UITheme.label(str(k + 1), 54, UITheme.GOLD if k == 0 else Color(1, 1, 1, 0.6), UITheme.title_font())
	place.custom_minimum_size = Vector2(54, 0)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(place)
	var name_l := UITheme.label(Loc.t(str(Campus.DORM_NAMES[d])), 40, Color.WHITE, UITheme.title_font() if lit else UITheme.semi_font())
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(name_l)
	var gain := int((table.get("gain", {}) as Dictionary).get(key, 0))
	if gain != 0:
		var gain_l := UITheme.label("+%d" % gain, 30, UITheme.GOLD, UITheme.semi_font())
		gain_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(gain_l)
	var pts_l := UITheme.label(str(int(pts[d])), 54, Color.WHITE, UITheme.title_font())
	pts_l.custom_minimum_size = Vector2(120, 0)
	pts_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pts_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pts_l)
	# The plates come up one after another, from first place down.
	pc.modulate.a = 0.0
	var tw := pc.create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.3).set_delay(0.4 + k * 0.6)
	return pc


## How long the table needs before all three dorms are on it.
func shown_after() -> float:
	return 0.4 + 3 * 0.6 + 0.3


func leave() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
