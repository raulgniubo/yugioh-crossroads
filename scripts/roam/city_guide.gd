class_name CityGuide
extends Control
## The city guide (M): a clean map on the right, and on the left a searchable list of places,
## people, quests and the other worlds. Pick anything and either get directions to it or go
## straight there.

signal closed

var scene                     # RoamScene
var extras                    # RoamExtras
var tab := "places"
var _search: LineEdit
var _list: VBoxContainer
var _tabs := {}
var _map: Control
var _entries: Array = []      # everything listable: {name, sub, pos: Vector3, kind, color, ...}
var _selected: Dictionary = {}
var _hover: Dictionary = {}
var _extent := 60.0


func _init(roam_scene = null, roam_extras = null, start_tab := "places") -> void:
	scene = roam_scene
	extras = roam_extras
	tab = start_tab


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var accent: Color = scene._theme.get("accent", UITheme.ACCENT)
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.035, 0.06, 0.11, 0.98), 24, Color(accent, 0.45)))
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	panel.add_child(h)
	# ---- left: search, tabs, list
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 860)
	left.add_theme_constant_override("separation", 10)
	h.add_child(left)
	var head := HBoxContainer.new()
	left.add_child(head)
	var title := UITheme.label(str(scene.district.get("name", "")).to_upper(), 44, Color.WHITE, UITheme.title_font())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_b := Button.new()
	close_b.text = "Close"
	close_b.pressed.connect(close)
	head.add_child(close_b)
	_search = LineEdit.new()
	_search.placeholder_text = "Search places and people  (try \"card shop\")"
	_search.clear_button_enabled = true
	_search.add_theme_font_size_override("font_size", 22)
	_search.text_changed.connect(func(_t): _fill())
	left.add_child(_search)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	left.add_child(tabs)
	for t in [["places", "PLACES"], ["people", "PEOPLE"], ["quests", "QUESTS"], ["travel", "WORLDS"]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_stylebox_override("pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		b.add_theme_color_override("font_pressed_color", Color(0.02, 0.05, 0.08))
		b.add_theme_color_override("font_hover_pressed_color", Color(0.02, 0.05, 0.08))
		var key: String = t[0]
		b.pressed.connect(func():
			tab = key
			_search.text = ""
			_fill())
		tabs.add_child(b)
		_tabs[key] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	var hint := UITheme.label("M / Esc  close      Click the map or a row to select", 16, UITheme.TEXT_DIM)
	left.add_child(hint)
	# ---- right: the map
	_map = Control.new()
	_map.custom_minimum_size = Vector2(1040, 860)
	_map.clip_contents = true
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_on_map_input)
	h.add_child(_map)
	_collect()
	_fill()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	Sfx.play("click")


func _process(_d: float) -> void:
	_map.queue_redraw()


# ------------------------------------------------------------------ data

func _landmarks() -> Array:
	var m: Dictionary = scene.district.get("map", {})
	return m.get("landmarks", RoamMap.LANDMARKS)


func _collect() -> void:
	_entries.clear()
	var m: Dictionary = scene.district.get("map", {})
	_extent = float(m["island"]) + 10.0 if m.has("island") else 62.0
	for lm in _landmarks():
		var p: Vector2 = lm["pos"]
		var shop: bool = lm.get("shop", false) or lm.get("enter", false)
		_entries.append({"kind": "place", "name": str(lm["name"]), "sub": "Card shop: packs, decks, your look" if shop else "Landmark",
				"pos": Vector3(p.x, 0, p.y), "size": lm["size"], "color": lm["color"], "shop": shop, "park": lm.get("park", false)})
	for n in scene._npcs:
		var d: Dictionary = n[0]
		var f: Node3D = n[1]
		if f.position.distance_to(ShopInterior.AT) < 30.0:
			continue
		var state := "Says hello"
		var col := Color("e8e8ee")
		if d.has("shop"):
			state = "Sells packs and builds decks"
			col = Color("ffd166")
		elif d.has("duel"):
			var beaten: bool = scene._beaten.has(d["id"])
			state = "Beaten. Up for a rematch" if beaten else "Wants to duel"
			col = Color("5affa0") if beaten else Color("ff5a7a")
		var star := str(d.get("char", "")) != "" and Characters.DATA.has(str(d.get("char", "")))
		_entries.append({"kind": "person", "name": scene._npc_name(d), "sub": state, "pos": f.position, "color": col,
				"star": star, "shop": d.has("shop"), "node": f})


func _matches(e: Dictionary, q: String) -> bool:
	if q == "":
		return true
	var hay := (str(e["name"]) + " " + str(e["sub"])).to_lower()
	if e.get("shop", false):
		hay += " card shop store packs buy cards deck"
	for word in q.to_lower().split(" ", false):
		if not hay.contains(word):
			return false
	return true


func _dist(e: Dictionary) -> float:
	var a: Vector3 = e["pos"]
	var b: Vector3 = scene._player.position
	return Vector2(a.x - b.x, a.z - b.z).length()


# ------------------------------------------------------------------ list

func _fill() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var q := _search.text.strip_edges()
	for k in _tabs:
		(_tabs[k] as Button).set_pressed_no_signal(k == tab and q == "")
	if q != "":
		# Searching looks through places and people together.
		var found: Array = _entries.filter(func(e): return _matches(e, q))
		found.sort_custom(func(a, b): return _dist(a) < _dist(b))
		for e in found:
			_list.add_child(_row(e))
		if found.is_empty():
			_list.add_child(UITheme.label("Nothing here by that name.", 20, UITheme.TEXT_DIM))
		return
	match tab:
		"places", "people":
			var want := "place" if tab == "places" else "person"
			var rows: Array = _entries.filter(func(e): return e["kind"] == want)
			rows.sort_custom(func(a, b):
				if a.get("shop", false) != b.get("shop", false):
					return a.get("shop", false)
				if a.get("star", false) != b.get("star", false):
					return a.get("star", false)
				return _dist(a) < _dist(b))
			for e in rows:
				_list.add_child(_row(e))
		"quests":
			for qd in extras.quest_rows():
				_list.add_child(_quest_row(qd))
		"travel":
			_list.add_child(UITheme.label("Jump to any world. You arrive at its entrance.", 18, UITheme.TEXT_DIM))
			_list.add_child(world_cards(func(key): _go_world(key), str(Router.roam.get("district", "domino"))))


func _row(e: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var on: bool = _selected == e
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.07, 0.11, 0.18, 0.95) if on else Color(0.05, 0.08, 0.13, 0.9), 14,
			Color(e["color"], 0.9) if on else Color(1, 1, 1, 0.07)))
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select(e))
	pc.mouse_entered.connect(func(): _hover = e)
	pc.mouse_exited.connect(func():
		if _hover == e:
			_hover = {})
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	pc.add_child(h)
	var dot := ColorRect.new()
	dot.color = e["color"]
	dot.custom_minimum_size = Vector2(8, 46)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(dot)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var nm := UITheme.label(("★  " if e.get("star", false) or e.get("shop", false) else "") + str(e["name"]), 23, Color.WHITE, UITheme.semi_font())
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var sub := UITheme.label("%s   ·   %d m" % [e["sub"], int(_dist(e))], 16, UITheme.TEXT_DIM)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sub)
	var guide := Button.new()
	guide.text = "Guide me"
	guide.tooltip_text = "Show the way: a beacon in the world and an arrow on screen"
	guide.pressed.connect(func():
		extras.set_waypoint(e["pos"], str(e["name"]))
		close())
	h.add_child(guide)
	var go := Button.new()
	go.text = "Go"
	go.tooltip_text = "Travel straight there"
	go.pressed.connect(func():
		extras.fast_travel(e["pos"], str(e["name"]))
		close())
	h.add_child(go)
	return pc


func _quest_row(qd: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var done: bool = qd["done"]
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.05, 0.08, 0.13, 0.9), 14, Color(UITheme.GOLD, 0.5) if done else Color(1, 1, 1, 0.07)))
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(UITheme.label(("✔  " if done else "") + str(qd["name"]), 23, UITheme.GOLD if done else Color.WHITE, UITheme.semi_font()))
	var sub := UITheme.label(str(qd["text"]), 16, UITheme.TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(500, 0)
	v.add_child(sub)
	var bar := ProgressBar.new()
	bar.max_value = float(qd["goal"])
	bar.value = float(qd["have"])
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	v.add_child(bar)
	v.add_child(UITheme.label("%d / %d      Reward: %d Duel Points%s" % [qd["have"], qd["goal"], qd["reward"], "  (collected)" if done else ""], 16,
			UITheme.GOLD if done else UITheme.TEXT))
	return pc


## Four big buttons, one per world. Used here and by the main menu.
static func world_cards(on_pick: Callable, current := "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	for w in RoamData.WORLDS:
		var key: String = w[0]
		var d := RoamData.district(key)
		var col: Color = w[3]
		var b := Button.new()
		b.custom_minimum_size = Vector2(520, 104)
		b.disabled = key == current
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			var sb := UITheme.button_box(Color(col.darkened(0.72), 0.95) if st != "hover" else Color(col.darkened(0.55), 0.98), col if st in ["hover", "focus"] else Color(col, 0.35), 16)
			sb.set_border_width_all(2)
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func(): on_pick.call(key))
		var inner := VBoxContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 20
		inner.offset_top = 10
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_constant_override("separation", 0)
		b.add_child(inner)
		var top := UITheme.label("%s%s" % [str(d.get("name", key)).to_upper(), "     YOU ARE HERE" if key == current else ""], 30, Color.WHITE, UITheme.title_font())
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(top)
		var era := UITheme.label(str(w[1]), 17, col.lightened(0.3), UITheme.semi_font())
		era.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(era)
		var blurb := UITheme.label(str(w[2]), 16, UITheme.TEXT_DIM)
		blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(blurb)
		v.add_child(b)
	return v


func _go_world(key: String) -> void:
	close()
	extras.travel_world(key)


func _select(e: Dictionary) -> void:
	_selected = e
	Sfx.play("card", -10.0)
	_fill()


# ------------------------------------------------------------------ map

func _to_map(p: Vector3) -> Vector2:
	var s: float = minf(_map.size.x, _map.size.y) / (_extent * 2.0)
	return _map.size / 2.0 + Vector2(p.x, p.z) * s


func _draw_map() -> void:
	var s: float = minf(_map.size.x, _map.size.y) / (_extent * 2.0)
	var mid := _map.size / 2.0
	var font := UITheme.semi_font()
	var m: Dictionary = scene.district.get("map", {})
	_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color(0.02, 0.035, 0.065))
	if m.has("island"):
		var water: bool = scene.district.get("builder", "") == "academy"
		if water:
			_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color(0.05, 0.13, 0.22))
		_map.draw_circle(mid, (float(m["island"]) + 4.0) * s, Color(0.75, 0.68, 0.5) if water else Color(0.1, 0.11, 0.15))
		_map.draw_circle(mid, float(m["island"]) * s, Color(0.16, 0.3, 0.2) if water else Color(0.13, 0.15, 0.2))
		_map.draw_arc(mid, float(m["island"]) * s, 0, TAU, 96, Color(1, 1, 1, 0.25), 2.0, true)
		for path in m.get("paths", []):
			_map.draw_line(mid + (path[0] as Vector2) * s, mid + (path[1] as Vector2) * s, Color(0.7, 0.68, 0.6, 0.55), 4.5 * s, true)
	else:
		# Domino's downtown: four blocks around the crossroads.
		_map.draw_rect(Rect2(mid - Vector2(36, 36) * s, Vector2(72, 72) * s), Color(0.07, 0.085, 0.12))
		for qx in [-1, 1]:
			for qz in [-1, 1]:
				_map.draw_rect(Rect2(mid + Vector2(qx * 19.5 - 14.5, qz * 19.5 - 14.5) * s, Vector2(29, 29) * s), Color(0.12, 0.14, 0.19))
		_map.draw_line(mid + Vector2(-56, 0) * s, mid + Vector2(56, 0) * s, Color(0.23, 0.25, 0.31), 9 * s)
		_map.draw_line(mid + Vector2(0, -56) * s, mid + Vector2(0, 56) * s, Color(0.23, 0.25, 0.31), 9 * s)
		_map.draw_rect(Rect2(mid - Vector2(34.5, 34.5) * s, Vector2(69, 69) * s), Color(1, 1, 1, 0.22), false, 2.0)
	# Places: a shape and a name each. Names that would collide step down a line.
	var taken: Array = []
	for e in _entries:
		if e["kind"] != "place":
			continue
		var c := _to_map(e["pos"])
		var sz: Vector2 = (e["size"] as Vector2) * s
		var col: Color = e["color"]
		var lit: bool = e == _selected or e == _hover
		var r := Rect2(c - sz / 2.0, sz)
		_map.draw_rect(r, Color(col, 0.3 if e.get("park", false) else (0.95 if lit else 0.7)))
		_map.draw_rect(r, Color.WHITE if lit else Color(col.lightened(0.3), 0.9), false, 3.0 if lit else 1.5)
		var text := ("★ " if e.get("shop", false) else "") + str(e["name"])
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19)
		var lp := Vector2(c.x - ts.x / 2.0, r.end.y + 19)
		var lr := Rect2(lp - Vector2(3, 17), ts + Vector2(6, 4))
		var tries := 0
		while tries < 5 and taken.any(func(o): return (o as Rect2).intersects(lr)):
			lp.y += 21
			lr.position.y += 21
			tries += 1
		taken.append(lr)
		_map.draw_rect(lr, Color(0.02, 0.035, 0.065, 0.8))
		_map.draw_string(font, lp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE if lit else col.lightened(0.45))
	# People: dots only. The name shows for the one you point at or picked.
	for e in _entries:
		if e["kind"] != "person":
			continue
		var node: Node3D = e["node"]
		if is_instance_valid(node):
			e["pos"] = node.position
		var c := _to_map(e["pos"])
		var lit: bool = e == _selected or e == _hover
		_map.draw_circle(c, 8.0 if lit else 5.5, Color(0, 0, 0, 0.6))
		_map.draw_circle(c, 6.5 if lit else 4.0, e["color"])
		if e.get("star", false):
			_map.draw_arc(c, 9.5 if lit else 7.5, 0, TAU, 20, Color("ffd166"), 1.6, true)
		if lit:
			var text := str(e["name"])
			var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19)
			_map.draw_rect(Rect2(c + Vector2(12, -15), ts + Vector2(10, 6)), Color(0.02, 0.035, 0.065, 0.92))
			_map.draw_string(font, c + Vector2(17, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	# Waypoint and a line to it.
	var pp := _to_map(scene._player.position)
	if extras.has_waypoint():
		var wp := _to_map(extras.waypoint)
		_map.draw_dashed_line(pp, wp, Color("ffd166"), 3.0, 10.0)
		_map.draw_circle(wp, 9.0 + sin(Time.get_ticks_msec() / 200.0) * 2.0, Color("ffd166"))
		_map.draw_circle(wp, 4.0, Color(0.02, 0.035, 0.065))
	# You.
	var yaw: float = scene._figure.rotation.y
	var fwd := Vector2(sin(yaw), cos(yaw))
	var side := Vector2(fwd.y, -fwd.x)
	_map.draw_colored_polygon(PackedVector2Array([pp + fwd * 16, pp - fwd * 9 + side * 10, pp - fwd * 4, pp - fwd * 9 - side * 10]), Color.WHITE)
	_map.draw_arc(pp, 20.0, 0, TAU, 28, Color(1, 1, 1, 0.35), 1.5, true)
	_map.draw_string(UITheme.title_font(), Vector2(18, 34), "N ▲", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.6))
	var legend := [["Wants to duel", Color("ff5a7a")], ["Beaten", Color("5affa0")], ["Talk / shop", Color("e8e8ee")], ["Anime duelist", Color("ffd166")]]
	var lx := 18.0
	for l in legend:
		_map.draw_circle(Vector2(lx + 6, _map.size.y - 20), 5.0, l[1])
		_map.draw_string(font, Vector2(lx + 18, _map.size.y - 14), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
		lx += 40.0 + font.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x


func _nearest(at: Vector2):
	var best = null
	var best_d := 26.0
	for e in _entries:
		var d := _to_map(e["pos"]).distance_to(at)
		if e["kind"] == "place":
			d = maxf(0.0, d - minf((e["size"] as Vector2).x, (e["size"] as Vector2).y) * 2.0)
		if d < best_d:
			best_d = d
			best = e
	return best


func _on_map_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var e = _nearest(ev.position)
		_hover = e if e != null else {}
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var e = _nearest(ev.position)
		if e != null:
			if ev.double_click:
				extras.set_waypoint(e["pos"], str(e["name"]))
				close()
				return
			tab = "places" if e["kind"] == "place" else "people"
			_search.text = ""
			_select(e)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()
