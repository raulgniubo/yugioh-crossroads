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
var _photo := false           # the map is the picture of the world from above (else the old flat drawing)
var _zoom := 1.0
var _center := Vector2.ZERO   # the world spot in the middle of the view
var _press := Vector2.INF
var _dragged := false


func _init(roam_scene = null, roam_extras = null, start_tab := "places") -> void:
	scene = roam_scene
	extras = roam_extras
	tab = start_tab


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
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
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.047, 0.078, 0.156, 0.98), 24, Color(accent, 0.45)))
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
	var tab_list: Array = [["places", "PLACES"], ["who", "WHO'S WHERE"], ["people", "PEOPLE"], ["quests", "QUESTS"], ["travel", "WORLDS"]]
	if Campus.on:
		# (the Academy story: no other worlds and none of the main game's quests)
		tab_list = tab_list.filter(func(t): return str(t[0]) != "travel" and str(t[0]) != "quests")
	for t in tab_list:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 17)
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
	# The clock, and a way to let time go by without walking to a bench.
	if not bool(scene.get("_own_tod")):
		var clock := HBoxContainer.new()
		clock.add_theme_constant_override("separation", 6)
		left.add_child(clock)
		var now := UITheme.label("%s  ·  %s" % [WorldClock.text(), Loc.t("Wait until")], 17, UITheme.GOLD, UITheme.semi_font())
		now.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		clock.add_child(now)
		for k in ["morning", "midday", "evening", "night"]:
			var wb := Button.new()
			wb.text = Loc.t(str(WorldClock.WAIT_NAMES[k]))
			wb.add_theme_font_size_override("font_size", 16)
			wb.pressed.connect(func():
				close()
				scene.pass_time(k))
			clock.add_child(wb)
	var hint := UITheme.label("M / Esc  close      Click the map or a row to select", 16, UITheme.TEXT_DIM)
	left.add_child(hint)
	# ---- right: the map
	_map = Control.new()
	_map.custom_minimum_size = Vector2(1040, 860)
	_map.clip_contents = true
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_on_map_input)
	h.add_child(_map)
	_photo = MapPhoto.ready_for(str(Router.roam.get("district", "domino")))
	if _photo:
		# Open on you, as close as still shows the whole width of the place.
		_zoom = clampf(MapPhoto.half.x * 2.0 / maxf(MapPhoto.content.size.x, 1.0), 1.0, 1.5)
		var me: Vector3 = scene._player.position if str(scene._inside) == "" else extras.reach_point(scene._player.position)
		_center = Vector2(me.x, me.z)
		_clamp_view.call_deferred()
		# Closer and further, for a trackpad or anybody who does not find the wheel.
		var zy := 86.0
		for z in [["+", 1.5], ["−", 1.0 / 1.5]]:
			var zb := Button.new()
			zb.text = str(z[0])
			zb.tooltip_text = "Closer" if float(z[1]) > 1.0 else "Further"
			zb.add_theme_font_size_override("font_size", 26)
			zb.custom_minimum_size = Vector2(46, 46)
			zb.position = Vector2(1040 - 46 - 20, zy)
			var k: float = z[1]
			zb.pressed.connect(func(): _zoom_at(_map.size / 2.0, k))
			_map.add_child(zb)
			zy += 52.0
	_collect()
	for a in OS.get_cmdline_user_args():
		# --map-zoom=k,x,z  (testing): open zoomed in on a spot.
		if a.begins_with("--map-zoom=") and _photo:
			var zp := a.substr(11).split(",")
			_zoom = float(zp[0])
			if zp.size() >= 3:
				_center = Vector2(float(zp[1]), float(zp[2]))
			_clamp_view.call_deferred()
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
		var shop: bool = lm.get("shop", false)
		_entries.append({"kind": "place", "name": str(lm["name"]), "sub": "Card shop: packs, decks, your look" if shop else ("You can go inside" if lm.get("enter", false) else "Landmark"),
				"pos": Vector3(p.x, 0, p.y), "size": lm["size"], "color": lm["color"], "shop": shop, "park": lm.get("park", false),
				"enter": lm.get("enter", false)})
	# Every door you can walk through: a landmark that has one says so, any other door gets a
	# mark of its own (a library, a lecture hall, your home).
	for rk in scene._rooms:
		var room: Dictionary = scene._rooms[rk]
		if not room.has("door"):
			continue
		var door: Vector3 = room["door"]
		if absf(door.y) > 1.0 or absf(door.x) > 250.0 or absf(door.z) > 250.0:
			continue
		var owner_found := false
		for e in _entries:
			if e["kind"] != "place" or e.get("park", false):
				continue
			var ep: Vector3 = e["pos"]
			if Rect2(Vector2(ep.x, ep.z) - (e["size"] as Vector2) / 2.0, e["size"]).grow(4.5).has_point(Vector2(door.x, door.z)):
				e["enter"] = true
				if str(e["sub"]) == "Landmark":
					e["sub"] = "You can go inside"
				owner_found = true
				break
		if not owner_found:
			_entries.append({"kind": "place", "name": str(room.get("name", rk)), "sub": "You can go inside", "pos": Vector3(door.x, 0, door.z),
					"size": Vector2(5, 5), "color": Color("dfe6f5"), "shop": false, "park": false, "enter": true, "door": true})
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
				"star": star, "shop": d.has("shop"), "node": f, "char": str(d.get("char", "")) if star else "", "id": str(d.get("id", ""))})
	# The main characters with a day of their own: what they are at and where they go next.
	var life = scene.get("stars")
	if life != null and is_instance_valid(life) and scene.story == null and scene.quest == null:
		for w in life.where():
			for e in _entries:
				if e["kind"] == "person" and e.get("node") == w["fig"]:
					e["who"] = w


## The landmark a spot is at or nearest to: [name, how far outside it in metres].
func _place_at(p: Vector3) -> Array:
	var best := ""
	var best_d := 1e9
	for lm in _landmarks():
		var c: Vector2 = lm["pos"]
		var hs: Vector2 = (lm["size"] as Vector2) / 2.0
		var q := Vector2(absf(p.x - c.x) - hs.x, absf(p.z - c.y) - hs.y)
		var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length()
		# A park holds other places: the building inside it wins.
		if lm.get("park", false):
			d += 3.0
		if d < best_d:
			best_d = d
			best = str(lm["name"])
	return [best, best_d]


func _at_text(p: Vector3) -> String:
	var pl := _place_at(p)
	if str(pl[0]) == "":
		return Loc.t("Out in the open")
	return (Loc.t("At %s") if float(pl[1]) < 7.0 else Loc.t("Near %s")) % Loc.t(str(pl[0]))


## Two lines for a main character: where and what, then where next and when.
func _who_lines(e: Dictionary) -> Array:
	var node: Node3D = e.get("node")
	var p: Vector3 = node.position if is_instance_valid(node) else e["pos"]
	if extras != null and extras._room_of(p) != "":
		return [Loc.t("Indoors"), Loc.t(str(e["sub"]))]
	if not e.has("who"):
		return [_at_text(p), Loc.t(str(e["sub"]))]
	var w: Dictionary = e["who"]
	var first: Array = []
	if w["walking"]:
		first = [Loc.t("Walking to %s") % Loc.t(str(_place_at(w["stop"])[0]))]
	else:
		first = [_at_text(p), str(w["doing"])]
	if w["one_stop"]:
		return first + [Loc.t(str(e["sub"]))]
	var m := int(w["next_min"])
	var hour := "%02d:%02d" % [m / 60, m % 60]
	var here := str(_place_at(w["stop"])[0])
	var there := str(_place_at(w["next"])[0])
	if there == here:
		return first + [Loc.t("Around here until %s") % hour]
	return first + [Loc.t("Next, %s: %s") % [hour, Loc.t(there)]]


func _matches(e: Dictionary, q: String) -> bool:
	if q == "":
		return true
	var hay := (str(e["name"]) + " " + str(e["sub"])).to_lower()
	if e.get("shop", false):
		hay += Loc.t(" card shop store packs buy cards deck")
	for word in q.to_lower().split(" ", false):
		if not hay.contains(word):
			return false
	return true


func _dist(e: Dictionary) -> float:
	var a: Vector3 = extras.reach_point(e["pos"]) if extras else e["pos"]
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
		"who":
			var rows: Array = _entries.filter(func(e): return e["kind"] == "person" and e.get("star", false))
			rows.sort_custom(func(a, b): return _dist(a) < _dist(b))
			# The duels they have with each other today come first.
			var meets := _meets()
			if not meets.is_empty():
				_list.add_child(UITheme.label(Loc.t("TODAY'S DUELS"), 15, UITheme.GOLD, UITheme.semi_font()))
				for m in meets:
					_list.add_child(_meet_row(m))
			if rows.is_empty():
				var none := UITheme.label("Nobody you know by name is out here right now. Try another hour, or another world.", 19, UITheme.TEXT_DIM)
				none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				none.custom_minimum_size = Vector2(520, 0)
				_list.add_child(none)
			else:
				var lead := UITheme.label("They have a day of their own: different places by the hour." if rows.any(func(e): return e.has("who")) else "Where everybody you know by name is right now.", 16, UITheme.TEXT_DIM)
				_list.add_child(lead)
			for e in rows:
				_list.add_child(_who_row(e))
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
			# The chapter's own list first.
			if scene.quest != null and is_instance_valid(scene.quest):
				var here := str(Router.roam.get("district", "domino"))
				var rows: Array = scene.quest.task_rows(here, scene.quest._district_at(scene.quest.step))
				var pc := PanelContainer.new()
				pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.09, 0.08, 0.03, 0.9), 14, Color(UITheme.GOLD, 0.7)))
				var sv := VBoxContainer.new()
				sv.add_theme_constant_override("separation", 3)
				pc.add_child(sv)
				sv.add_child(UITheme.label(Loc.t("THE STORY"), 15, UITheme.GOLD, UITheme.semi_font()))
				if scene.quest._task_title:
					sv.add_child(UITheme.label(scene.quest._task_title.text, 22, Color.WHITE, UITheme.semi_font()))
				for r in rows:
					var done: bool = r[1] == "done"
					var rl := UITheme.label(("✔  " if done else "•  ") + str(r[0]), 17, Color(0.55, 0.9, 0.62) if done else UITheme.TEXT)
					rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					rl.custom_minimum_size = Vector2(500, 0)
					sv.add_child(rl)
					if r.size() > 3:
						if str(r[2]) != "":
							var sl := UITheme.label("      " + str(r[2]), 15, UITheme.TEXT_DIM)
							sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
							sl.custom_minimum_size = Vector2(500, 0)
							sv.add_child(sl)
						var said: String = scene.quest.lead_quote(int(r[3]))
						if said != "":
							var ql := UITheme.label("      \u201c" + said + "\u201d", 14, Color(0.8, 0.78, 0.62, 0.9))
							ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
							ql.custom_minimum_size = Vector2(500, 0)
							sv.add_child(ql)
				_list.add_child(pc)
			for qd in extras.quest_rows():
				_list.add_child(_quest_row(qd))
		"travel":
			_list.add_child(UITheme.label("Jump to any world. You arrive at its entrance.", 18, UITheme.TEXT_DIM))
			_list.add_child(world_cards(func(key): _go_world(key), str(Router.roam.get("district", "domino"))))


func _row(e: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var on: bool = _selected == e
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.082, 0.128, 0.225, 0.95) if on else Color(0.062, 0.098, 0.174, 0.9), 14,
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
		extras.fast_travel(extras.reach_point(e["pos"]), str(e["name"]))
		close())
	h.add_child(go)
	return pc


## A main character: face, name, where they are and what they are doing, where they go next.
func _who_row(e: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var on: bool = _selected == e
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.115, 0.17, 0.96) if on else Color(0.062, 0.098, 0.174, 0.9), 16,
			Color(UITheme.GOLD, 0.95) if on else Color(UITheme.GOLD, 0.22)))
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
	var face := Control.new()
	face.custom_minimum_size = Vector2(66, 66)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key := str(e.get("char", ""))
	face.draw.connect(func(): MapArt.token(face, Vector2(33, 33), 28.0, key, UITheme.GOLD))
	h.add_child(face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var nm := UITheme.label(str(e["name"]), 23, Color.WHITE, UITheme.semi_font())
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	var far := UITheme.label("%d m" % int(_dist(e)), 15, UITheme.TEXT_DIM)
	far.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(far)
	# How well they know you: the step you are on and how far the next one is.
	if e.has("who") and (e["who"] as Dictionary).has("rank"):
		var w: Dictionary = e["who"]
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(250, 16)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rank_text := str(w["rank_name"])
		var rank := int(w["rank"])
		var top_rank := int(w["ranks"])
		var frac := clampf(float(w["frac"]), 0.0, 1.0)
		bar.draw.connect(func():
			var font := UITheme.semi_font()
			var gold := UITheme.GOLD
			# One pip a step, filled up to where you stand, and a thin bar toward the next.
			for k in top_rank:
				var c := Vector2(6.0 + k * 13.0, 8.0)
				bar.draw_circle(c, 5.0, Color(gold, 0.25))
				if k < rank:
					bar.draw_circle(c, 5.0, gold)
			var x0 := 6.0 + top_rank * 13.0 + 2.0
			bar.draw_string(font, Vector2(x0, 13.0), rank_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, gold)
			var x1 := x0 + font.get_string_size(rank_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 10.0
			if rank < top_rank and x1 < bar.size.x - 30.0:
				var wd := minf(90.0, bar.size.x - x1 - 4.0)
				bar.draw_rect(Rect2(x1, 6.0, wd, 4.0), Color(1, 1, 1, 0.14))
				bar.draw_rect(Rect2(x1, 6.0, wd * frac, 4.0), gold))
		v.add_child(bar)
	# Where, what they are doing, and (dimmer) where next.
	var lines := _who_lines(e)
	for i in lines.size():
		var last: bool = i == lines.size() - 1 and lines.size() > 1
		var ll := UITheme.label(str(lines[i]), 15, UITheme.TEXT_DIM if last else UITheme.TEXT)
		ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ll.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ll.custom_minimum_size = Vector2(250, 0)
		ll.clip_text = true
		v.add_child(ll)
	var guide := Button.new()
	guide.text = "Guide me"
	guide.tooltip_text = "Show the way: a beacon in the world and an arrow on screen"
	guide.pressed.connect(func():
		var node: Node3D = e.get("node")
		extras.set_waypoint(node.position if is_instance_valid(node) else e["pos"], str(e["name"]))
		close())
	h.add_child(guide)
	var go := Button.new()
	go.text = "Go"
	go.tooltip_text = "Travel straight there"
	go.pressed.connect(func():
		var node: Node3D = e.get("node")
		extras.fast_travel(extras.reach_point(node.position if is_instance_valid(node) else e["pos"]), str(e["name"]))
		close())
	h.add_child(go)
	return pc


func _meets() -> Array:
	var life = scene.get("stars")
	if life == null or not is_instance_valid(life) or scene.story != null or scene.quest != null:
		return []
	return life.meets_today()


func _meet_state(m: Dictionary) -> String:
	match str(m["state"]):
		"now":
			return Loc.t("On now")
		"soon":
			return Loc.t("About to start")
		"over":
			return Loc.t("Over: %s won") % str(m["winner"])
	return Loc.t("Later today")


## One of today's duels between two main characters: when, who, where, and how it stands.
func _meet_row(m: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var live: bool = str(m["state"]) in ["now", "soon"]
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.16, 0.07, 0.09, 0.95) if live else Color(0.062, 0.098, 0.174, 0.9), 14,
			Color("ff5a7a") if live else Color(1, 1, 1, 0.07)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	pc.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	var at := int(m["at"])
	v.add_child(UITheme.label("%02d:%02d   %s  vs  %s" % [at / 60, at % 60, str(m["a"]), str(m["b"])], 21, Color.WHITE, UITheme.semi_font()))
	v.add_child(UITheme.label("%s  ·  %s" % [Loc.t(str(_place_at(m["mid"])[0])), _meet_state(m)], 15, UITheme.TEXT if live else UITheme.TEXT_DIM))
	if str(m["state"]) != "over":
		var guide := Button.new()
		guide.text = "Guide me"
		guide.pressed.connect(func():
			extras.set_waypoint(m["mid"], "%s vs %s" % [str(m["a"]), str(m["b"])])
			close())
		h.add_child(guide)
	return pc


func _quest_row(qd: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var done: bool = qd["done"]
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.062, 0.098, 0.174, 0.9), 14, Color(UITheme.GOLD, 0.5) if done else Color(1, 1, 1, 0.07)))
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
	v.add_child(UITheme.label(Loc.t("%d / %d      Reward: %d Duel Points%s") % [qd["have"], qd["goal"], qd["reward"], Loc.t("  (collected)") if done else ""], 16,
			UITheme.GOLD if done else UITheme.TEXT))
	return pc


## Four big buttons, one per world. Used here and by the main menu.
static func world_cards(on_pick: Callable, current := "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	for w in RoamData.WORLDS + [["highway", "5D's  ·  Turbo Duels", "Ride your runner down the night highway and duel at full speed.", Color("ff8a3a")]]:
		var key: String = w[0]
		var d: Dictionary = RoamData.district(key) if key != "highway" else {"name": "New Domino Highway"}
		var col: Color = w[3]
		var b := Button.new()
		b.custom_minimum_size = Vector2(520, 96)
		var open_now := Unlocks.world(key)
		b.disabled = key == current or not open_now
		if not open_now:
			b.tooltip_text = Unlocks.world_why(key)
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
		var top := UITheme.label("%s%s" % [Loc.t(str(d.get("name", key))).to_upper(), Loc.t("     YOU ARE HERE") if key == current else ""], 30, Color.WHITE, UITheme.title_font())
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(top)
		var era := UITheme.label(str(w[1]), 17, col.lightened(0.3), UITheme.semi_font())
		era.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(era)
		var blurb := UITheme.label(str(w[2]), 16, UITheme.TEXT_DIM)
		blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(blurb)
		if not open_now:
			# Locked: greyed out, with a lock tag and how to open it in place of the description.
			b.self_modulate = Color(0.55, 0.55, 0.6, 1.0)
			top.modulate = Color(1, 1, 1, 0.5)
			era.modulate = Color(1, 1, 1, 0.5)
			blurb.text = Unlocks.world_why(key)
			blurb.add_theme_color_override("font_color", UITheme.GOLD)
			var lock := UITheme.label(Loc.t("LOCKED"), 16, Color.WHITE, UITheme.semi_font())
			var lsb := UITheme.panel_box(Color(0.1, 0.1, 0.14, 0.95), 8, Color(1, 1, 1, 0.35))
			lsb.content_margin_left = 10
			lsb.content_margin_right = 10
			lock.add_theme_stylebox_override("normal", lsb)
			lock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			lock.offset_left = -120
			lock.offset_right = -16
			lock.offset_top = 12
			lock.offset_bottom = 40
			lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(lock)
		v.add_child(b)
	return v


func _go_world(key: String) -> void:
	close()
	extras.travel_world(key)


func _select(e: Dictionary) -> void:
	_selected = e
	Sfx.play("card", -10.0)
	# Zoomed in and it is off the edge: slide the map over to it.
	if _photo and _zoom > 1.01:
		var at := _to_map(_spot(e))
		if not Rect2(Vector2(80, 80), _map.size - Vector2(160, 160)).has_point(at):
			var p := _spot(e)
			_center = Vector2(p.x, p.z)
			_clamp_view()
	_fill()


## Where an entry is on the ground right now (people move; rooms are reached through their door).
func _spot(e: Dictionary) -> Vector3:
	var node = e.get("node")
	if node != null and is_instance_valid(node):
		e["pos"] = (node as Node3D).position
	return extras.reach_point(e["pos"]) if extras else e["pos"]


# ------------------------------------------------------------------ map

func _scale() -> float:
	if _photo:
		return _map.size.y / (MapPhoto.half.y * 2.0) * _zoom
	return minf(_map.size.x, _map.size.y) / (_extent * 2.0)


func _to_map(p: Vector3) -> Vector2:
	return _map.size / 2.0 + (Vector2(p.x, p.z) - _center) * _scale()


func _clamp_view() -> void:
	var hv := _map.size / 2.0 / _scale()
	var lo := MapPhoto.mid - MapPhoto.half + hv
	var hi := MapPhoto.mid + MapPhoto.half - hv
	_center.x = clampf(_center.x, lo.x, hi.x) if lo.x <= hi.x else MapPhoto.mid.x
	_center.y = clampf(_center.y, lo.y, hi.y) if lo.y <= hi.y else MapPhoto.mid.y


## Closer or further, keeping what is under `at` (map pixels) where it is.
func _zoom_at(at: Vector2, k: float) -> void:
	if not _photo:
		return
	var before := _center + (at - _map.size / 2.0) / _scale()
	_zoom = clampf(_zoom * k, 1.0, 6.0)
	_center = before - (at - _map.size / 2.0) / _scale()
	_clamp_view()


## The map: the picture of the world, every place named, everybody on it, and you.
func _draw_map() -> void:
	if not _photo:
		_draw_map_flat()
		return
	var s := _scale()
	var font := UITheme.semi_font()
	var view := _map.size / s
	MapArt.photo(_map, Rect2(Vector2.ZERO, _map.size), Rect2(_center - view / 2.0, view))
	_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color(MapArt.INK, 0.1))
	MapArt.vignette(_map, _map.size, 110.0, 0.5)
	var frame := Rect2(Vector2.ZERO, _map.size)
	# Name tags keep clear of the legend, the scale bar, the compass and the buttons.
	var taken: Array = [Rect2(0, _map.size.y - 58.0, _map.size.x, 58.0), Rect2(_map.size.x - 84.0, 0, 84.0, 196.0), Rect2(0, 0, 520.0, 46.0),
			Rect2(_map.size.x - 230.0, _map.size.y - 104.0, 230.0, 104.0)]
	var face_tags: Array = []
	# The main characters get a portrait and a name: note where those go first, so place names
	# stay out from under them.
	var faces: Array = []
	for e in _entries:
		if e["kind"] != "person" or str(e.get("char", "")) == "":
			continue
		var c := _to_map(_spot(e))
		if not frame.grow(30.0).has_point(c):
			continue
		var lit: bool = e == _selected or e == _hover
		var r := 21.0 if lit else 17.0
		# Two of them at the same door: fan the second one out.
		for o in faces:
			if (o[1] as Vector2).distance_to(c) < 34.0:
				c += Vector2(40, 0)
		# Two names on top of each other: the second one waits until you point at it.
		var tr := MapArt.tag_rect(font, c + Vector2(0, r + 5.0), Loc.t(str(e["name"])), 16)
		var named: bool = lit or not face_tags.any(func(o): return (o as Rect2).intersects(tr))
		faces.append([e, c, r, lit, named])
		taken.append(Rect2(c - Vector2(r + 3, r + 3), Vector2(r + 3, r + 3) * 2.0))
		if named:
			face_tags.append(tr)
			taken.append(tr)
	# Places: the outline of the one you point at, and a name tag on each. A tag that would land
	# on another moves above its building, and waits for you to zoom in if that is taken too.
	var places: Array = _entries.filter(func(e): return e["kind"] == "place")
	places.sort_custom(func(a, b):
		var ka := (0 if a == _selected or a == _hover else (1 if a.get("shop", false) else (3 if a.get("park", false) else 2)))
		var kb := (0 if b == _selected or b == _hover else (1 if b.get("shop", false) else (3 if b.get("park", false) else 2)))
		return ka < kb)
	for e in places:
		var c := _to_map(_spot(e))
		var sz: Vector2 = (e["size"] as Vector2) * s
		var col: Color = e["color"]
		var lit: bool = e == _selected or e == _hover
		if lit:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(col, 0.2)
			box.border_color = Color.WHITE
			box.set_border_width_all(3)
			box.set_corner_radius_all(int(clampf(1.2 * s, 4.0, 16.0)))
			box.shadow_color = Color(col, 0.55)
			box.shadow_size = 10
			_map.draw_style_box(box, Rect2(c - sz / 2.0, sz).grow(3.0))
		if not frame.has_point(c):
			continue
		var text := Loc.t(str(e["name"]))
		var fs := 18
		var park: bool = e.get("park", false)
		var spots := [c + Vector2(0, minf(sz.y / 2.0, 60.0) + 6.0), c - Vector2(0, minf(sz.y / 2.0, 60.0) + 6.0 + fs + 9.0)]
		if park:
			spots = [c - Vector2(0, (fs + 9.0) / 2.0)] + spots
		var at = null
		for sp in spots:
			var r := MapArt.tag_rect(font, sp, text, fs, true).grow(2.0)
			if not taken.any(func(o): return (o as Rect2).intersects(r)):
				at = sp
				break
		if at == null:
			if not lit:
				continue
			at = spots[0]
		taken.append(MapArt.tag_rect(font, at, text, fs, true).grow(2.0))
		if e.get("shop", false):
			var tr := MapArt.tag(_map, font, at, "    " + text, fs, Color.WHITE, Color(0, 0, 0, 0), lit)
			MapArt.star(_map, Vector2(tr.position.x + 17.0, tr.position.y + tr.size.y / 2.0), 8.0, Color("ffd166"))
		else:
			MapArt.tag(_map, font, at, text, fs, Color.WHITE if lit else Color(0.93, 0.95, 1.0), col.lightened(0.15), lit, e.get("enter", false))
	# Everybody else: a dot. The name shows for the one you point at or picked.
	for e in _entries:
		if e["kind"] != "person" or str(e.get("char", "")) != "":
			continue
		var c := _to_map(_spot(e))
		if not frame.has_point(c):
			continue
		var lit: bool = e == _selected or e == _hover
		_map.draw_circle(c + Vector2(0, 1), 8.5 if lit else 6.5, Color(0, 0, 0, 0.6))
		_map.draw_circle(c, 7.0 if lit else 5.0, Color.WHITE if lit else Color(MapArt.INK, 0.9))
		_map.draw_circle(c, 5.5 if lit else 3.8, e["color"])
		if lit:
			MapArt.tag(_map, font, c + Vector2(0, 12), "%s  ·  %s" % [Loc.t(str(e["name"])), Loc.t(str(e["sub"]))], 16, Color.WHITE, Color(0, 0, 0, 0), true)
	# The story's tasks in this world: a gold "!" each (the one you are guided to is the waypoint below).
	for tm in extras.task_marks:
		var tc := _to_map(tm[0])
		if not frame.has_point(tc):
			continue
		_map.draw_circle(tc + Vector2(0, 1), 10.0, Color(0, 0, 0, 0.6))
		_map.draw_circle(tc, 9.0, Color("ffd166"))
		_map.draw_string(UITheme.title_font(), tc + Vector2(-3.5, 6.5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MapArt.INK)
		if tc.distance_to(_map.get_local_mouse_position()) < 14.0:
			MapArt.tag(_map, font, tc + Vector2(0, 14), str(tm[1]), 16, Color.WHITE, Color(0, 0, 0, 0), true)
	# The way to your waypoint.
	var pp := _to_map(scene._player.position if str(scene._inside) == "" else extras.reach_point(scene._player.position))
	if extras.has_waypoint():
		var wp := _to_map(extras.waypoint)
		_map.draw_dashed_line(pp, wp, Color(0, 0, 0, 0.6), 6.0, 12.0)
		_map.draw_dashed_line(pp, wp, Color("ffd166"), 3.0, 12.0)
		var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() / 200.0)
		var gr := 11.0 * pulse
		_map.draw_colored_polygon(PackedVector2Array([wp + Vector2(0, -gr - 3), wp + Vector2(gr + 3, 0), wp + Vector2(0, gr + 3), wp + Vector2(-gr - 3, 0)]), Color(0, 0, 0, 0.8))
		_map.draw_colored_polygon(PackedVector2Array([wp + Vector2(0, -gr), wp + Vector2(gr, 0), wp + Vector2(0, gr), wp + Vector2(-gr, 0)]), Color("ffd166"))
	# Today's duels between them: crossed swords where it happens, with the hour.
	var marked: Array = []
	for m in _meets():
		if str(m["state"]) == "over":
			continue
		var mc := _to_map(m["mid"])
		# Two duels at the same spot today: the mark is for the next one.
		if not frame.has_point(mc) or marked.has(m["mid"]):
			continue
		marked.append(m["mid"])
		var live: bool = str(m["state"]) == "now"
		var pr := 15.0 + (2.0 * sin(Time.get_ticks_msec() / 160.0) if live else 0.0)
		_map.draw_circle(mc, pr + 2.5, Color("ff5a7a"))
		_map.draw_circle(mc, pr, MapArt.INK)
		for sx: float in [-1.0, 1.0]:
			_map.draw_line(mc + Vector2(-7 * sx, 7), mc + Vector2(7 * sx, -7), Color.WHITE, 2.5, true)
			_map.draw_line(mc + Vector2(-7 * sx, 7) + Vector2(4 * sx, 1), mc + Vector2(-7 * sx, 7) + Vector2(-1 * sx, -4), Color("ffd166"), 2.5, true)
		var mat := int(m["at"])
		var mt := (Loc.t("On now") if live else "%02d:%02d" % [mat / 60, mat % 60]) + "   %s vs %s" % [str(m["a"]), str(m["b"])]
		MapArt.tag(_map, font, mc + Vector2(0, pr + 6.0), mt, 15, Color("ffd0d8"), Color(0, 0, 0, 0), live)
	# The main characters, on top.
	for f in faces:
		var e: Dictionary = f[0]
		var c: Vector2 = f[1]
		var r: float = f[2]
		var lit: bool = f[3]
		MapArt.token(_map, c, r, str(e["char"]), Color.WHITE if lit else Color("ffd166"))
		if f[4]:
			MapArt.tag(_map, font, c + Vector2(0, r + 5.0), Loc.t(str(e["name"])), 16, Color("ffe9a8"), Color(0, 0, 0, 0), lit)
		if lit:
			var lines := _who_lines(e)
			MapArt.tag(_map, font, c + Vector2(0, r + 34.0), str(lines[1] if lines.size() > 2 else lines[0]), 15, Color.WHITE, Color(0, 0, 0, 0), false)
	# You.
	var yaw: float = scene._figure.rotation.y
	var ring := 22.0 + 3.0 * sin(Time.get_ticks_msec() / 260.0)
	_map.draw_arc(pp, ring, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0, true)
	MapArt.you(_map, pp, Vector2(sin(yaw), cos(yaw)), 12.0, scene._theme.get("accent", UITheme.ACCENT))
	# Compass.
	var cp := Vector2(_map.size.x - 43.0, 43.0)
	_map.draw_circle(cp, 27.0, Color(MapArt.INK, 0.85))
	_map.draw_arc(cp, 27.0, 0, TAU, 40, Color(1, 1, 1, 0.3), 1.5, true)
	_map.draw_colored_polygon(PackedVector2Array([cp + Vector2(0, -21), cp + Vector2(6, 0), cp + Vector2(-6, 0)]), Color("ff5a6e"))
	_map.draw_colored_polygon(PackedVector2Array([cp + Vector2(0, 21), cp + Vector2(6, 0), cp + Vector2(-6, 0)]), Color(1, 1, 1, 0.75))
	_map.draw_string(UITheme.title_font(), cp + Vector2(-5.5, -29), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	# How far is far: a bar with a round number of metres.
	var metres := 100.0
	for m in [5.0, 10.0, 20.0, 50.0, 100.0]:
		if m * s >= 70.0:
			metres = m
			break
	var bx := _map.size.x - 24.0
	var by := _map.size.y - 72.0
	_map.draw_rect(Rect2(bx - metres * s - 12.0, by - 26.0, metres * s + 24.0, 40.0), Color(MapArt.INK, 0.75))
	_map.draw_line(Vector2(bx - metres * s, by), Vector2(bx, by), Color.WHITE, 2.0)
	_map.draw_line(Vector2(bx - metres * s, by - 6), Vector2(bx - metres * s, by + 1), Color.WHITE, 2.0)
	_map.draw_line(Vector2(bx, by - 6), Vector2(bx, by + 1), Color.WHITE, 2.0)
	_map.draw_string(font, Vector2(bx - metres * s, by - 9), "%d m" % int(metres), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.9))
	# What the marks mean.
	var legend := [["dot", "Wants to duel", Color("ff5a7a")], ["dot", "Beaten", Color("5affa0")], ["dot", "Talk / shop", Color("e8e8ee")],
			["face", "Main character", Color("ffd166")], ["star", "Card shop", Color("ffd166")], ["door", "Go inside", Color("9fb4c8")], ["goal", "Your route", Color("ffd166")]]
	var lw := 26.0
	for l in legend:
		lw += 30.0 + font.get_string_size(Loc.t(l[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16.0
	var lbox := StyleBoxFlat.new()
	lbox.bg_color = Color(MapArt.INK, 0.86)
	lbox.set_corner_radius_all(17)
	lbox.border_color = Color(1, 1, 1, 0.14)
	lbox.set_border_width_all(1)
	_map.draw_style_box(lbox, Rect2(16.0, _map.size.y - 50.0, lw - 12.0, 34.0))
	var lx := 34.0
	var ly := _map.size.y - 33.0
	for l in legend:
		match str(l[0]):
			"dot":
				_map.draw_circle(Vector2(lx, ly), 5.5, l[2])
			"face":
				_map.draw_circle(Vector2(lx, ly), 8.0, l[2])
				_map.draw_circle(Vector2(lx, ly), 5.5, Color(0.35, 0.4, 0.5))
			"star":
				MapArt.star(_map, Vector2(lx, ly), 8.0, l[2])
			"door":
				_map.draw_circle(Vector2(lx, ly), 6.0, l[2])
				_map.draw_circle(Vector2(lx, ly), 2.6, Color.WHITE)
			"goal":
				_map.draw_colored_polygon(PackedVector2Array([Vector2(lx, ly - 7), Vector2(lx + 7, ly), Vector2(lx, ly + 7), Vector2(lx - 7, ly)]), l[2])
		_map.draw_string(font, Vector2(lx + 13.0, ly + 5.5), Loc.t(l[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.85))
		lx += 30.0 + font.get_string_size(Loc.t(l[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16.0
	MapArt.tag(_map, font, Vector2(16.0 + 0.5 * MapArt.tag_rect(font, Vector2.ZERO, Loc.t("Scroll: closer / further    Drag: move    Double-click: show the way"), 14).size.x, 16.0),
			Loc.t("Scroll: closer / further    Drag: move    Double-click: show the way"), 14, Color(1, 1, 1, 0.8))


## The old flat drawing: used when there is no picture of the world (it could not be taken).
func _draw_map_flat() -> void:
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
		var c := _to_map(extras.reach_point(e["pos"]) if extras else e["pos"])
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
		_map.draw_string(font, lp, Loc.t(text), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE if lit else col.lightened(0.45))
	# People: dots only. The name shows for the one you point at or picked.
	for e in _entries:
		if e["kind"] != "person":
			continue
		var node: Node3D = e["node"]
		if is_instance_valid(node):
			e["pos"] = node.position
		var c := _to_map(extras.reach_point(e["pos"]) if extras else e["pos"])
		var lit: bool = e == _selected or e == _hover
		_map.draw_circle(c, 8.0 if lit else 5.5, Color(0, 0, 0, 0.6))
		_map.draw_circle(c, 6.5 if lit else 4.0, e["color"])
		if e.get("star", false):
			_map.draw_arc(c, 9.5 if lit else 7.5, 0, TAU, 20, Color("ffd166"), 1.6, true)
		if lit:
			var text := str(e["name"])
			var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19)
			_map.draw_rect(Rect2(c + Vector2(12, -15), ts + Vector2(10, 6)), Color(0.02, 0.035, 0.065, 0.92))
			_map.draw_string(font, c + Vector2(17, 4), Loc.t(text), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	# The story's tasks in this world.
	for tm in extras.task_marks:
		var tc := _to_map(tm[0])
		_map.draw_circle(tc, 6.5, Color("ffd166"))
		_map.draw_circle(tc, 3.0, Color(0.02, 0.035, 0.065))
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
		_map.draw_string(font, Vector2(lx + 18, _map.size.y - 14), Loc.t(l[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
		lx += 40.0 + font.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x


func _nearest(at: Vector2):
	var best = null
	var best_d := 26.0
	for e in _entries:
		var d := _to_map(_spot(e)).distance_to(at)
		if e["kind"] == "place":
			var sz: Vector2 = (e["size"] as Vector2) * _scale() if _photo else (e["size"] as Vector2) * 4.0
			d = maxf(0.0, d - minf(sz.x, sz.y) * 0.5) + (6.0 if _photo else 0.0)
		elif str(e.get("char", "")) != "":
			d = maxf(0.0, d - 12.0)
		if d < best_d:
			best_d = d
			best = e
	return best


func _pick(e) -> void:
	if e == null:
		return
	if e["kind"] == "place":
		tab = "places"
	else:
		tab = "who" if e.get("star", false) else "people"
	_search.text = ""
	_select(e)


func _on_map_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.pressed and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom_at(ev.position, 1.18 if ev.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.18)
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_press = ev.position
				_dragged = false
				if ev.double_click:
					var e = _nearest(ev.position)
					if e != null:
						extras.set_waypoint(_true_spot(e), str(e["name"]))
						close()
			else:
				if not _dragged and _press != Vector2.INF:
					_pick(_nearest(ev.position))
				_press = Vector2.INF
	elif ev is InputEventMouseMotion:
		if _photo and _press != Vector2.INF and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if not _dragged and ev.position.distance_to(_press) > 6.0:
				_dragged = true
			if _dragged:
				_center -= ev.relative / _scale()
				_clamp_view()
		else:
			var e = _nearest(ev.position)
			_hover = e if e != null else {}
	elif ev is InputEventMagnifyGesture:
		_zoom_at(ev.position, ev.factor)
	elif ev is InputEventPanGesture and _photo:
		# Two fingers on a trackpad slide the map.
		_center += ev.delta * 14.0 / _scale()
		_clamp_view()


## Where a waypoint for an entry goes: the person or place itself (the beacon works out doors).
func _true_spot(e: Dictionary) -> Vector3:
	var node = e.get("node")
	if node != null and is_instance_valid(node):
		return (node as Node3D).position
	return e["pos"]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()
