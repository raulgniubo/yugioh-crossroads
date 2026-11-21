class_name StoryRoster
extends Control
## A list that gets posted in a story: a team, a ranking. Names in their dorm colors, with what
## each one is on the list, and, under a line, whoever was left off it.
##
## list: {"title": "The League Team", "sub": "...",
##        "rows": [[role, who], ...]     who = a character key, "player", or a plain name
##        "out":  [[place, who], ...]}   under the line

const DORM_COLS := {"red": Color("d9342b"), "yellow": Color("f2c230"), "blue": Color("2f6fe0")}

var list := {}


func _init(l: Dictionary) -> void:
	list = l


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
	v.offset_left = -460
	v.offset_right = 460
	v.offset_top = -440
	v.offset_bottom = 440
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head := UITheme.label(Loc.t(str(list.get("title", ""))).to_upper(), 58, Color.WHITE, UITheme.title_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	if str(list.get("sub", "")) != "":
		var sub := UITheme.label(Loc.t(str(list["sub"])), 24, UITheme.GOLD, UITheme.semi_font())
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sub)
	v.add_child(_gap(14))
	var k := 0
	for row in list.get("rows", []):
		v.add_child(_plate(str(row[0]), str(row[1]), false, k))
		k += 1
	var left: Array = list.get("out", [])
	if not left.is_empty():
		v.add_child(_gap(6))
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.3)
		line.custom_minimum_size = Vector2(0, 2)
		v.add_child(line)
		v.add_child(_gap(6))
		for row in left:
			v.add_child(_plate(str(row[0]), str(row[1]), true, k))
			k += 1
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	Sfx.play("gong", -10.0)


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Name and dorm of somebody on the list.
func _who(key: String) -> Array:
	if key == "player":
		return [Profile.duelist_name, Campus.DORMS[Campus.dorm()] if Campus.on else "red"]
	var c: Dictionary = Characters.get_char(key)
	if c.is_empty():
		return [key, ""]
	return [str(c.get("name", key)), str(Avatars.UNIFORMS.get(key, ""))]


func _plate(role: String, key: String, out: bool, k: int) -> Control:
	var who := _who(key)
	var you := key == "player"
	var pc := PanelContainer.new()
	var bg := Color(0.05, 0.08, 0.14, 0.95)
	var border := Color(1, 1, 1, 0.16)
	if you:
		bg = Color(0.1, 0.22, 0.3, 0.98)
		border = UITheme.ACCENT
	var sb := UITheme.panel_box(bg, 12, border)
	sb.set_border_width_all(3 if you else 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(0, 74 if not out else 60)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	pc.add_child(h)
	var bar := ColorRect.new()
	bar.color = Color(DORM_COLS.get(who[1], Color(0.6, 0.6, 0.66)), 0.45 if out else 1.0)
	bar.custom_minimum_size = Vector2(9, 0)
	h.add_child(bar)
	var name_l := UITheme.label(str(who[0]), 34 if not out else 28, Color(1, 1, 1, 0.5) if out else Color.WHITE, UITheme.title_font() if you else UITheme.semi_font())
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_l.clip_text = true
	h.add_child(name_l)
	if role != "":
		var role_l := UITheme.label(Loc.t(role).to_upper(), 20, Color(1, 1, 1, 0.5) if out else UITheme.GOLD, UITheme.semi_font())
		role_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(role_l)
	if out:
		pc.modulate = Color(0.8, 0.8, 0.86, 0.85)
	# The names come up one after another, the way a list is read out.
	pc.modulate.a = 0.0
	var tw := pc.create_tween()
	tw.tween_property(pc, "modulate:a", 0.85 if out else 1.0, 0.25).set_delay(0.35 + k * 0.45)
	return pc


## How long the list needs before everything on it has come up.
func shown_after() -> float:
	return 0.35 + ((list.get("rows", []) as Array).size() + (list.get("out", []) as Array).size()) * 0.45 + 0.3


func leave() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
