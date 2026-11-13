class_name RoamExtras
extends Node
## Everything that gives free roam a purpose: the guide (map, search, worlds), directions to a
## place you picked, a quick bar, the marked edge of each area, Star Chips to collect and quests.

const SAVE := "user://roam_extras.cfg"
const CHIP_DP := 15
const CHIPS_ALL_DP := 300

var scene                       # RoamScene
var waypoint := Vector3.ZERO
var _wp_name := ""
var _wp_on := false
var _beacon: Node3D
var _trail: Array = []
var _hud: Control
var _wp_label: Label
var _chip_label: Button
var _chip_card: Control
var _errands := {}             # favors: id -> stage (see WorldLife)
var _edge_label: Label
var _chips: Array = []          # [{node, pos, idx}]
var _got := {}                  # district -> [chip indices]
var _talked := {}               # district -> [npc ids]
var _visited := {}              # district -> true
var _done := {}                 # quest id -> true
var _fence_mat: ShaderMaterial
var _key := "domino"
var _tick := 0.0
var _edge_shown := 0.0
var _step := 0.0
var _blip := 0.0


var _last_barker = null
var story_mode := false     # a story chapter is running: no quick bar, chips or quests
var _bar: Control


func _ready() -> void:
	_key = str(Router.roam.get("district", "domino"))
	_load()
	_build_hud()
	_build_fence()
	if story_mode:
		if _bar:
			_bar.visible = false
		return
	_visited[_key] = true
	_build_chips()
	_save()
	_check_quests(false)


# ------------------------------------------------------------------ save

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		_got = cfg.get_value("x", "chips", {})
		_talked = cfg.get_value("x", "talked", {})
		_visited = cfg.get_value("x", "visited", {})
		_done = cfg.get_value("x", "done", {})
		_errands = cfg.get_value("x", "errands", {})


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("x", "chips", _got)
	cfg.set_value("x", "talked", _talked)
	cfg.set_value("x", "visited", _visited)
	cfg.set_value("x", "done", _done)
	cfg.set_value("x", "errands", _errands)
	cfg.save(SAVE)


# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene._ui.add_child(_hud)
	var bar := HBoxContainer.new()
	_bar = bar
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.offset_top = 26
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.add_theme_constant_override("separation", 8)
	_hud.add_child(bar)
	for b in [["M   Map", func(): open_guide("places")], ["G   Worlds", func(): open_guide("travel")],
			["C   Card shop", guide_to_shop], ["J   Quests", func(): open_guide("quests")], ["B   Decks", func(): scene.open_decks()]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 19)
		btn.add_theme_stylebox_override("normal", UITheme.button_box(Color(0.073, 0.172, 0.441, 0.78), Color(1, 1, 1, 0.14), 12))
		btn.pressed.connect(b[1])
		bar.add_child(btn)
	# Star Chips: a named counter you can click to be told what they are.
	_chip_label = Button.new()
	_chip_label.focus_mode = Control.FOCUS_NONE
	_chip_label.add_theme_font_size_override("font_size", 19)
	_chip_label.add_theme_color_override("font_color", UITheme.GOLD)
	_chip_label.add_theme_color_override("font_hover_color", Color.WHITE)
	_chip_label.add_theme_stylebox_override("normal", UITheme.button_box(Color(0.09, 0.07, 0.02, 0.82), Color(UITheme.GOLD, 0.55), 12))
	_chip_label.tooltip_text = "Star Chips found in this world. Click to see what they are."
	_chip_label.pressed.connect(explain_chips)
	bar.add_child(_chip_label)
	_wp_label = UITheme.label("", 26, Color("ffe9a8"), UITheme.title_font())
	_wp_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wp_label.offset_top = 84
	_wp_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_wp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_wp_label.add_theme_constant_override("outline_size", 8)
	_wp_label.visible = false
	_hud.add_child(_wp_label)
	_edge_label = UITheme.label("", 24, Color.WHITE, UITheme.semi_font())
	_edge_label.set_anchors_preset(Control.PRESET_CENTER)
	_edge_label.offset_top = 150
	_edge_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_edge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_edge_label.add_theme_constant_override("outline_size", 8)
	_edge_label.modulate.a = 0.0
	_hud.add_child(_edge_label)


func _busy() -> bool:
	return scene._talking or scene._overlay_open or scene._pause != null


func open_guide(tab := "places") -> void:
	if _busy():
		return
	scene._open_overlay(CityGuide.new(scene, self, tab))


func _unhandled_input(event: InputEvent) -> void:
	if _busy() or story_mode:
		return
	var pad: bool = event is InputEventJoypadButton and event.pressed
	if (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G) or (pad and event.button_index == JOY_BUTTON_BACK):
		open_guide("travel")
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C) or (pad and event.button_index == JOY_BUTTON_X):
		guide_to_shop()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		scene.open_decks()
		scene.get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J:
		open_guide("quests")
	elif pad and event.button_index == JOY_BUTTON_Y:
		open_guide("places")
	else:
		return
	get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ directions

func has_waypoint() -> bool:
	return _wp_on


func set_waypoint(pos: Vector3, title: String) -> void:
	waypoint = Vector3(pos.x, 0, pos.z)
	_wp_name = title
	_wp_on = true
	if _beacon == null:
		_beacon = Node3D.new()
		scene.city.add_child(_beacon)
		var beam := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.5
		cm.bottom_radius = 0.16
		cm.height = 40.0
		cm.radial_segments = 10
		beam.mesh = cm
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.albedo_color = Color(1.0, 0.82, 0.4, 0.3)
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		bm.no_depth_test = true
		beam.material_override = bm
		beam.position.y = 20.0
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_beacon.add_child(beam)
		var tag := Label3D.new()
		tag.name = "Tag"
		tag.font = UITheme.title_font()
		tag.font_size = 72
		tag.pixel_size = 0.006
		tag.outline_size = 14
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.modulate = Color("ffe9a8")
		tag.position.y = 4.2
		_beacon.add_child(tag)
		for i in 9:
			var ch := Label3D.new()
			ch.text = "▲"
			ch.font_size = 96
			ch.pixel_size = 0.006
			ch.modulate = Color(1.0, 0.82, 0.4, 0.9)
			ch.shaded = false
			ch.double_sided = true
			ch.rotation.x = -PI / 2
			scene.city.add_child(ch)
			_trail.append(ch)
	_beacon.position = waypoint
	(_beacon.get_node("Tag") as Label3D).text = "▼ " + Loc.t(title)
	_beacon.visible = true
	Sfx.play("special", -8.0)
	if not story_mode:
		Router.toast(Loc.t("Follow the beacon to %s") % Loc.t(title))


func clear_waypoint() -> void:
	_wp_on = false
	if _beacon:
		_beacon.visible = false
	for ch in _trail:
		(ch as Node3D).visible = false
	_wp_label.visible = false


## The closest card shop: the Kame Game door in Domino, the card dealer everywhere else.
func guide_to_shop() -> void:
	if _busy():
		return
	if scene._inside != "":
		Router.toast("You are in the card shop. Talk to the owner at the counter.")
		return
	if scene.district.get("builder", "") == "":
		set_waypoint(Vector3(-10, 0, -15.4), "Kame Game (card shop)")
		return
	for n in scene._npcs:
		if (n[0] as Dictionary).has("shop"):
			set_waypoint((n[1] as Node3D).position, scene._npc_name(n[0]))
			return
	Router.toast("No card shop in this world")


func fast_travel(pos: Vector3, title: String) -> void:
	var center := Vector3.ZERO
	var out := (pos - center)
	out.y = 0
	var spot := pos
	if out.length() > 1.0:
		spot = pos - out.normalized() * 3.0   # just short of it, on the side facing the middle of the map
	else:
		spot = pos + Vector3(0, 0, 4.0)
	if title.begins_with("Kame Game"):
		spot = Vector3(-10, 0, -12.8)
	if scene._inside != "":
		scene._set_inside("")
	# Landmarks at the end of a road sit past the walkable edge: stop just inside it.
	var b := _bounds()
	if b.has("r"):
		var flat := Vector2(spot.x, spot.z).limit_length(float(b["r"]) - 3.5)
		spot = Vector3(flat.x, 0, flat.y)
	elif b.get("open", false):
		# Domino's plus shape: the old square, plus the plaza, the harbor, the pier and the forecourts.
		var x := clampf(spot.x, -41.0, 41.0)
		var z := clampf(spot.z, -53.0, 89.0)
		if absf(x) > 32.0:
			z = clampf(z, -10.0, 10.0)
		if z < -33.0:
			x = clampf(x, -25.0, 25.0)
		elif z > 61.0:
			x = clampf(x, -2.6, 2.6)
		elif z > 33.0:
			x = clampf(x, -28.0, 28.0)
		spot = Vector3(x, 0, z)
	else:
		var lim: float = float(b["half"]) - 2.5
		spot = Vector3(clampf(spot.x, -lim, lim), 0, clampf(spot.z, -lim, lim))
	scene._player.position = Vector3(spot.x, 0.3, spot.z)
	scene._player.velocity = Vector3.ZERO
	scene._pivot.position = scene._player.position + Vector3(0, 1.45, 0)
	var to := pos - spot
	scene._yaw = atan2(-to.x, -to.z)
	scene._fader.color.a = 1.0
	scene.create_tween().tween_property(scene._fader, "color:a", 0.0, 0.35)
	Sfx.play("special", -6.0)
	clear_waypoint()
	Router.toast(title)


func travel_world(key: String) -> void:
	if key == _key:
		return
	if key == "highway":
		Sfx.play("gong", -6.0)
		Router.go(Router.RIDE)
		return
	await scene.travel_card(key)
	Router.roam["district"] = key
	Router.roam["pos"] = null
	Router.roam.erase("yaw")
	Router.roam.erase("tod")
	Router.go(Router.ROAM)


# ------------------------------------------------------------------ the edge of the area

func _bounds() -> Dictionary:
	match str(scene.district.get("builder", "")):
		"academy":
			return {"r": AcademyBuilder.SHORE - 3.0}
		"arena":
			return {"r": ArenaDistrict.RADIUS}
		"newdomino":
			return {"half": 50.5}
	# Domino City: the avenues run on past the old square, so there is no single fence line.
	return {"half": 34.5, "open": true}


func _edge_distance(p: Vector3) -> float:
	var b := _bounds()
	if b.has("r"):
		return float(b["r"]) - Vector2(p.x, p.z).length()
	if b.get("open", false):
		return 99.0
	return float(b["half"]) - maxf(absf(p.x), absf(p.z))


## A holographic fence along the edge. It only lights up near you, so it marks the end of the
## area without boxing in the view.
func _build_fence() -> void:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform vec3 player;
uniform vec4 tint : source_color = vec4(0.3, 0.9, 1.0, 1.0);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float near = 1.0 - smoothstep(3.0, 13.0, distance(wp.xz, player.xz));
	vec2 g = abs(fract(vec2(wp.x + wp.z, wp.y) * 0.8 + vec2(0.0, TIME * 0.15)) - 0.5);
	float grid = smoothstep(0.46, 0.5, max(g.x, g.y));
	float fade = 1.0 - smoothstep(0.0, 4.2, wp.y);
	ALBEDO = tint.rgb;
	ALPHA = (grid * 0.8 + 0.07) * near * fade;
}
"""
	_fence_mat = ShaderMaterial.new()
	_fence_mat.shader = sh
	_fence_mat.set_shader_parameter("tint", Color(scene._theme.get("accent", UITheme.ACCENT)))
	var b := _bounds()
	if b.get("open", false):
		return
	if b.has("r"):
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = float(b["r"]) - 0.6
		cm.bottom_radius = float(b["r"]) - 0.6
		cm.height = 4.4
		cm.radial_segments = 72
		cm.cap_top = false
		cm.cap_bottom = false
		mi.mesh = cm
		mi.material_override = _fence_mat
		mi.position.y = 2.2
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scene.city.add_child(mi)
	else:
		var hlf: float = float(b["half"]) - 0.6
		for i in 4:
			var mi := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(hlf * 2.0, 4.4)
			mi.mesh = qm
			mi.material_override = _fence_mat
			var a := i * PI / 2
			mi.position = Vector3(sin(a) * hlf, 2.2, cos(a) * hlf)
			mi.rotation.y = a
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			scene.city.add_child(mi)


# ------------------------------------------------------------------ Star Chips

func _chip_spots() -> Array:
	match str(scene.district.get("builder", "")):
		"":
			return [Vector3(5.2, 0, -28), Vector3(-5.2, 0, -20), Vector3(5.2, 0, 12), Vector3(-5.2, 0, 27), Vector3(-28, 0, 5.2), Vector3(-18, 0, -5.2),
					Vector3(16, 0, 5.2), Vector3(29, 0, -5.2), Vector3(19, 0, 19), Vector3(12, 0, 25), Vector3(26, 0, 13), Vector3(-10, 0, -11.5),
					# KaibaCorp Plaza, the harbor, the pier and the two forecourts.
					Vector3(-23, 0, -52), Vector3(23, 0, -39), Vector3(-27, 0, 59), Vector3(26, 0, 40), Vector3(0, 0, 90.5), Vector3(0, 0, 72),
					Vector3(-36.4, 0, -10.8), Vector3(39.5, 0, 10.8)]
		"academy":
			return [Vector3(0, 0, 36), Vector3(-3, 0, 18), Vector3(-20, 0, 6), Vector3(-36, 0, 3), Vector3(-30, 0, -8), Vector3(22, 0, -4), Vector3(37, 0, -8),
					Vector3(19, 0, 14), Vector3(30, 0, 30), Vector3(47, 0, 30), Vector3(3, 0, -16), Vector3(-10, 0, -28)]
	var out: Array = []
	for i in 8:
		var a := i * TAU / 8.0 + 0.4
		out.append(Vector3(cos(a) * (15.0 + (i % 2) * 5.0), 0, sin(a) * (15.0 + (i % 2) * 5.0)))
	out.append_array([Vector3(-30, 0, 4), Vector3(30, 0, -4), Vector3(4, 0, -31), Vector3(-10, 0, 31)])
	return out


func _build_chips() -> void:
	var got: Array = _got.get(_key, [])
	var spots := _chip_spots()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("ffd166")
	m.emission_enabled = true
	m.emission = Color("ffb000")
	m.emission_energy_multiplier = 2.2
	m.metallic = 0.8
	m.roughness = 0.25
	for i in spots.size():
		if got.has(i):
			continue
		var n := Node3D.new()
		n.position = (spots[i] as Vector3) + Vector3(0, 1.0, 0)
		var star := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.5, 0.5, 0.12)
		star.mesh = pm
		star.material_override = m
		n.add_child(star)
		var star2 := MeshInstance3D.new()
		star2.mesh = pm
		star2.material_override = m
		star2.rotation.z = PI
		star2.position.y = -0.14
		n.add_child(star2)
		var l := OmniLight3D.new()
		l.light_color = Color("ffd166")
		l.light_energy = 1.2
		l.omni_range = 3.0
		n.add_child(l)
		scene.city.add_child(n)
		_chips.append({"node": n, "pos": spots[i], "idx": i})
	_refresh_chip_label()


func _refresh_chip_label() -> void:
	_chip_label.text = Loc.t("Star Chips  %d / %d") % [(_got.get(_key, []) as Array).size(), _chip_spots().size()]


## What the spinning gold stars are, said plainly. Shown the first time you pick one up, and
## whenever you click the counter.
func explain_chips() -> void:
	if _chip_card and is_instance_valid(_chip_card):
		_chip_card.queue_free()
	var total := _chip_spots().size()
	var card := PanelContainer.new()
	_chip_card = card
	var sb := UITheme.panel_box(Color(0.07, 0.055, 0.02, 0.96), 18, Color(UITheme.GOLD, 0.85))
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sb)
	card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	card.offset_top = 130
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var t := UITheme.label("STAR CHIPS", 30, UITheme.GOLD, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for line in [Loc.t("The spinning gold stars around town are Star Chips. Walk into one to pick it up."),
			Loc.t("Each one pays %d Duel Points. Find all %d in a world for a bonus of %d.") % [CHIP_DP, total, CHIPS_ALL_DP],
			Loc.t("The counter at the top shows how many you have found here. Quests (J) track them too.")]:
		var l := UITheme.label(line, 21, UITheme.TEXT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	_hud.add_child(card)
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	tw.tween_interval(9.0)
	tw.tween_property(card, "modulate:a", 0.0, 0.5)
	tw.tween_callback(card.queue_free)


func _collect(c: Dictionary) -> void:
	var first_ever := true
	for k in _got:
		if not (_got[k] as Array).is_empty():
			first_ever = false
	if first_ever:
		explain_chips()
	var got: Array = _got.get(_key, [])
	got.append(c["idx"])
	_got[_key] = got
	_chips.erase(c)
	var n: Node3D = c["node"]
	var tw: Tween = scene.create_tween().set_parallel()
	tw.tween_property(n, "position:y", n.position.y + 1.6, 0.35)
	tw.tween_property(n, "scale", Vector3.ZERO, 0.35)
	tw.chain().tween_callback(n.queue_free)
	Collection.dp += CHIP_DP
	Collection.daily_bump("chip")
	Sfx.play("coin", -2.0)
	var total := _chip_spots().size()
	if got.size() == total:
		Collection.dp += CHIPS_ALL_DP
		Router.toast(Loc.t("Every Star Chip in %s! +%d Duel Points") % [Loc.t(str(scene.district.get("name", ""))), CHIPS_ALL_DP])
		Sfx.play("win", -6.0)
	else:
		Router.toast(Loc.t("Star Chip %d of %d   +%d Duel Points") % [got.size(), total, CHIP_DP])
	Collection.save()
	_refresh_chip_label()
	_save()
	_check_quests(true)


# ------------------------------------------------------------------ quests

const BOSS := {"domino": "yugi", "academy": "jaden", "satellite": "yusei", "heartland": "yuma", "newdomino": "jack"}


func _duelists_here() -> Array:
	var out: Array = []
	for d in scene.district.get("npcs", []):
		if (d as Dictionary).has("duel"):
			out.append(d["id"])
	return out


## Every quest with its progress: [{id, name, text, have, goal, reward, done}]
func quest_rows() -> Array:
	var place := str(scene.district.get("name", ""))
	var beaten := 0
	for id in _duelists_here():
		if scene._beaten.has(id):
			beaten += 1
	var boss := str(BOSS.get(_key, ""))
	var boss_name: String = Characters.get_char(boss).get("short", boss)
	var worlds := 0
	for w in RoamData.WORLDS:
		if _visited.has(w[0]):
			worlds += 1
	var all_chips := 0
	for k in _got:
		all_chips += (_got[k] as Array).size()
	var rows := [
		{"id": _key + "_hello", "name": "Meet the locals", "text": Loc.t("Talk to 4 different people in %s.") % place,
			"have": mini(4, (_talked.get(_key, []) as Array).size()), "goal": 4, "reward": 150},
		{"id": _key + "_shop", "name": "Shopping trip", "text": Loc.t("Find the card shop in %s and talk to whoever runs it. (Press C for directions.)") % place,
			"have": 1 if _talked.get(_key + "_shop", false) else 0, "goal": 1, "reward": 100},
		{"id": _key + "_streets", "name": "Street champion", "text": Loc.t("Win duels against 3 different duelists in %s.") % place,
			"have": mini(3, beaten), "goal": 3, "reward": 300},
		{"id": _key + "_boss", "name": Loc.t("Beat %s") % boss_name, "text": Loc.t("%s is the one to beat in %s. Win that duel.") % [boss_name, place],
			"have": 1 if scene._beaten.has(boss) else 0, "goal": 1, "reward": 400},
		{"id": _key + "_chips", "name": "Star hunter", "text": Loc.t("Collect 8 Star Chips in %s.") % place,
			"have": mini(8, (_got.get(_key, []) as Array).size()), "goal": 8, "reward": 250},
		{"id": "world_tour", "name": "World tour", "text": "Set foot in all five worlds. (Press G to travel.)", "have": worlds, "goal": RoamData.WORLDS.size(), "reward": 400},
		{"id": "chip_master", "name": "Chip master", "text": "Collect 30 Star Chips across every world.", "have": mini(30, all_chips), "goal": 30, "reward": 600},
	]
	rows = Collection.daily_rows() + rows
	for r in rows:
		r["done"] = _done.has(r["id"])
	return rows


func _check_quests(announce: bool) -> void:
	if story_mode:
		return
	for r in quest_rows():
		if not r["done"] and int(r["have"]) >= int(r["goal"]):
			_done[r["id"]] = true
			Collection.dp += int(r["reward"])
			Collection.save()
			_save()
			if announce or true:
				Router.toast(Loc.t("Quest complete: %s   +%d Duel Points") % [Loc.t(str(r["name"])), r["reward"]])
				Sfx.play("quest", -3.0)


# ------------------------------------------------------------------ every frame

const ARROWS := ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]


## Street chatter: every few seconds someone nearby says something, in a little bubble over
## their head. And the people standing around turn to look at you when you come close.
const BARKS := ["Nice Duel Disk!", "Did you see that last duel?", "I need one more rare card...", "Who's the top duelist around here?",
	"My deck is finally ready.", "Heard the card shop restocked.", "I pulled an Ultra Rare today!", "Wanna duel later?",
	"That combo was unreal.", "I should really trade my doubles.", "One day I'll go pro.", "Heart of the cards, right?"]
var _bark_in := 4.0
var _bark: Label3D


func _street_life(delta: float, p: Vector3) -> void:
	if scene._inside != "":
		_indoor_chatter(delta, p)
		return
	for n in scene._npcs:
		var fig: Node3D = n[1]
		if not is_instance_valid(fig) or not n[0].has("face"):
			continue
		var to := p - fig.global_position
		var want: float = atan2(to.x, to.z) if to.length() < 5.5 else float(n[0]["face"])
		fig.rotation.y = lerp_angle(fig.rotation.y, want, clampf(delta * 3.0, 0.0, 1.0))
	_bark_in -= delta
	if _bark_in > 0.0 or scene._overlay_open:
		return
	_bark_in = randf_range(5.0, 9.0)
	var near := []
	for w in scene._walkers:
		var f: Node3D = w["fig"]
		if is_instance_valid(f) and f.global_position.distance_to(p) < 13.0:
			near.append(f)
	if near.is_empty():
		return
	var who: Node3D = near[randi() % near.size()]
	if _bark and is_instance_valid(_bark):
		_bark.queue_free()
	_bark = Label3D.new()
	_bark.text = Loc.t(BARKS[randi() % BARKS.size()])
	_bark.font_size = 36
	_bark.pixel_size = 0.0042
	_bark.outline_size = 12
	_bark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bark.modulate = Color(1, 1, 1, 0.0)
	_bark.outline_modulate = Color(0.02, 0.03, 0.06, 0.9)
	_bark.position = Vector3(0, 2.25, 0)
	who.add_child(_bark)
	var tw := _bark.create_tween()
	tw.tween_property(_bark, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.8)
	tw.tween_property(_bark, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_bark.queue_free)
	Sfx.play("blip", -16.0, randf_range(0.9, 1.3))


## Indoors, the people in the room talk among themselves: each has a few lines of their own.
func _indoor_chatter(delta: float, p: Vector3) -> void:
	_bark_in -= delta
	if _bark_in > 0.0 or scene._overlay_open or scene._talking:
		return
	_bark_in = randf_range(2.6, 5.0)
	var near := []
	for n in scene._npcs:
		var fig: Node3D = n[1]
		if is_instance_valid(fig) and (n[0] as Dictionary).has("barks") and fig.global_position.distance_to(p) < 14.0 and n[0] != _last_barker:
			near.append(n)
	if near.is_empty():
		return
	var pick: Array = near[randi() % near.size()]
	_last_barker = pick[0]
	var lines: Array = pick[0]["barks"]
	_say_over(pick[1], Loc.t(str(lines[randi() % lines.size()])), 2.3)


func _say_over(who: Node3D, text: String, hold: float) -> void:
	if _bark and is_instance_valid(_bark):
		_bark.queue_free()
	_bark = Label3D.new()
	_bark.text = text
	_bark.font_size = 34
	_bark.pixel_size = 0.004
	_bark.outline_size = 12
	_bark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bark.no_depth_test = true
	_bark.modulate = Color(1, 1, 1, 0.0)
	_bark.outline_modulate = Color(0.02, 0.03, 0.06, 0.9)
	_bark.position = Vector3(0, 2.85, 0)
	who.add_child(_bark)
	var tw := _bark.create_tween()
	tw.tween_property(_bark, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_bark, "position:y", 3.0, 0.2)
	tw.tween_interval(hold)
	tw.tween_property(_bark, "modulate:a", 0.0, 0.35)
	tw.tween_callback(_bark.queue_free)
	Sfx.play("blip", -18.0, randf_range(0.9, 1.4))


func _process(delta: float) -> void:
	var p: Vector3 = scene._player.position
	_street_life(delta, p)
	if _fence_mat:
		_fence_mat.set_shader_parameter("player", p)
	var t := Time.get_ticks_msec() / 1000.0
	# Star Chips spin, bob and are picked up by walking into them.
	for c in _chips.duplicate():
		var n: Node3D = c["node"]
		n.rotation.y = t * 2.2
		n.position.y = 1.0 + sin(t * 2.0 + float(c["idx"])) * 0.12
		if Vector2(p.x - n.position.x, p.z - n.position.z).length() < 1.25 and scene._inside == "":
			_collect(c)
	# The way to the waypoint.
	if _wp_on:
		var to := waypoint - p
		to.y = 0
		var dist := to.length()
		if dist < 3.2:
			Router.toast(Loc.t("You have arrived: %s") % Loc.t(_wp_name))
			Sfx.play("click")
			clear_waypoint()
		else:
			var rel := wrapf(atan2(to.x, to.z) - (scene._yaw + PI), -PI, PI)
			var idx := posmod(int(round(-rel / (PI / 4.0))), 8)
			_wp_label.text = "%s   %s   %d m" % [ARROWS[idx], _wp_name, int(dist)]
			_wp_label.visible = not _busy()
			var dir := to / dist
			for i in _trail.size():
				var ch: Label3D = _trail[i]
				var d := 2.0 + i * 1.8 + fmod(t * 2.0, 1.8)
				ch.visible = d < dist - 1.0 and scene._inside == ""
				ch.position = p + dir * d + Vector3(0, 0.2 - p.y * 0.0, 0)
				ch.position.y = 0.22
				ch.rotation.y = atan2(dir.x, dir.z) + PI
				ch.modulate.a = clampf(1.0 - i / float(_trail.size()), 0.15, 0.9)
	# The edge of the area.
	_edge_shown = maxf(0.0, _edge_shown - delta)
	if scene._inside == "" and _edge_distance(p) < 2.6:
		if _edge_shown <= 0.0:
			_edge_label.text = Loc.t("This is the edge of %s.   Press G to travel to another world.") % Loc.t(str(scene.district.get("name", "the area")))
			scene.create_tween().tween_property(_edge_label, "modulate:a", 1.0, 0.2)
		_edge_shown = 1.2
	elif _edge_shown <= 0.0 and _edge_label.modulate.a > 0.9:
		scene.create_tween().tween_property(_edge_label, "modulate:a", 0.0, 0.4)
	# Footsteps while you move, and a little voice blip for every few letters of dialogue.
	var sp := Vector2(scene._player.velocity.x, scene._player.velocity.z).length()
	if sp > 0.6 and scene._player.is_on_floor():
		_step += delta * sp
		if _step > (1.5 if sp < 5.5 else 2.1):
			_step = 0.0
			Sfx.play(scene.ground_sound(), -9.0 if sp > 5.5 else -11.0, 0.9 + randf() * 0.25)
	if scene._talking and scene._dlg_text.visible_ratio < 1.0:
		_blip += delta
		if _blip > 0.055:
			_blip = 0.0
			Sfx.play("blip", -13.0, 0.75 + (hash(str(scene._dlg_npc.get("id", ""))) % 9) * 0.07)
	# Who you have talked to, for the quests.
	_tick += delta
	if scene._talking and not scene._dlg_npc.is_empty():
		var id: String = str(scene._dlg_npc.get("id", ""))
		var list: Array = _talked.get(_key, [])
		if id != "" and not list.has(id):
			list.append(id)
			_talked[_key] = list
			if scene._dlg_npc.has("shop"):
				_talked[_key + "_shop"] = true
			_save()
			_check_quests(true)
	if _tick > 1.5:
		_tick = 0.0
		_check_quests(true)
