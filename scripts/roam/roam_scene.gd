extends Node3D
## Free roam: walk a district, talk to people, take on street duels.

const SPEED := 4.2
const RUN := 7.5
const TALK_RANGE := 2.6
const SAVE_PATH := "user://roam.cfg"

var district: Dictionary
var _player: CharacterBody3D
var _figure: RoamFigure
var _pivot: Node3D
var _arm: SpringArm3D
var _cam: Camera3D
var _yaw := 0.0
var _pitch := -0.22
var _npcs: Array = []  # [data, figure, marker]
var _near: Dictionary = {}
var _beaten := {}
var _dragging := false

# UI
var _ui: CanvasLayer
var _prompt: Label
var _dlg: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _dlg_buttons: HBoxContainer
var _dlg_lines: Array = []
var _dlg_index := 0
var _dlg_npc: Dictionary = {}
var _talking := false
var _pause: Control
var _counter: Label
var _theme: Dictionary
var city: CityBuilder
var _spots: Array = []        # [{pos: Vector3, range: float, label: String, action: Callable}]
var _near_spot: Dictionary = {}
var _inside := ""
var _outside_pos := Vector3(-10, 0, -13.6)
var _map: RoamMap
var _map_full: RoamMap
var _loc_name: Label
var _loc_area: Label
var _fader: ColorRect
var _overlay_open := false


func _ready() -> void:
	district = RoamData.district(Router.roam.get("district", "domino"))
	_theme = FieldThemes.resolve(district.get("theme", "battlecity"), "")
	_load_progress()
	_build_world()
	_build_player()
	_build_npcs()
	_build_walkers()
	_build_places()
	city.player = _player
	_build_ui()
	if district.get("builder", "") != "academy" and _player.position.distance_to(ShopInterior.AT) < 30.0:
		_set_inside("kame")
	if _map:
		for mp in [_map, _map_full]:
			mp.title = str(district.get("name", "")).to_upper()
			mp.area = str(district.get("area", ""))
			if district.has("map"):
				mp.layout = district["map"]
	Music.play("menu")
	_after_duel()
	_debug()


# ------------------------------------------------------------------ progress

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_beaten = cfg.get_value("roam", "beaten", {})
		if cfg.has_section_key("roam", "deck") and CardData.has_deck(cfg.get_value("roam", "deck", "")):
			Router.duel_config["player_deck"] = cfg.get_value("roam", "deck")


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("roam", "beaten", _beaten)
	cfg.save(SAVE_PATH)
	_refresh_map_people()


func _after_duel() -> void:
	var who: String = Router.roam.get("last_duel", "")
	if who == "":
		return
	var won := Router.story_result == "won"
	Router.roam["last_duel"] = ""
	Router.story_result = ""
	for n in _npcs:
		if n[0]["id"] == who:
			if won:
				_beaten[who] = true
				_save_progress()
				_refresh_marker(n)
			var name: String = _npc_name(n[0])
			await get_tree().create_timer(0.8).timeout
			Router.toast(("You beat %s!" % name) if won else ("%s wins this time. Try again!" % name))
	_update_counter()


# ------------------------------------------------------------------ world

func _build_world() -> void:
	city = AcademyBuilder.new() if district.get("builder", "") == "academy" else CityBuilder.new()
	add_child(city)
	var key: String = Router.roam.get("district", "domino")
	if not Router.roam.has("tod_" + key) and district.has("tod") and not Router.roam.has("tod"):
		Router.roam["tod"] = district["tod"]
	city.build(_theme, Router.roam.get("tod", "night"))


func _cycle_tod() -> void:
	var i := CityBuilder.TODS.find(city.tod)
	var next: String = CityBuilder.TODS[(i + 1) % CityBuilder.TODS.size()]
	Router.roam["tod"] = next
	city.apply_tod(next)
	Router.toast({"night": "Night", "sunset": "Sunset", "day": "Daytime"}[next])


# ------------------------------------------------------------------ pedestrians

const WALK_LINES := [
	"Did you catch the Battle City finals? Unreal.",
	"My little brother won't stop talking about Blue-Eyes.",
	"Kame Game has the best booster prices in town.",
	"Watch out for the guys in robes. They've been stealing rare cards.",
	"I'm saving up for a new Duel Disk.",
	"The lights on KaibaCorp Tower never go off. Does that guy ever sleep?",
	"Heard there's a duel spirit haunting the park at night...",
	"I'm late for work. Again.",
]
const ROUTES := [
	[Vector3(7.2, 0, 8), Vector3(7.2, 0, 29)],
	[Vector3(8, 0, 7.2), Vector3(29, 0, 7.2)],
	[Vector3(-7.4, 0, 8), Vector3(-7.4, 0, 29)],
	[Vector3(8, 0, -7.4), Vector3(29, 0, -7.4)],
	[Vector3(-8, 0, -7.4), Vector3(-29, 0, -7.4)],
	[Vector3(7.4, 0, -8), Vector3(7.4, 0, -29)],
	[Vector3(-8, 0, 7.4), Vector3(-29, 0, 7.4)],
	[Vector3(-4.0, 0, -10), Vector3(4.0, 0, -10)],
]
var _walkers: Array = []  # {fig, a, b, t, dir, body}


func _build_walkers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var palette := [Color("e0533f"), Color("3f7be0"), Color("3fbf8a"), Color("8a4fd9"), Color("f0a040"), Color("2b2b33"), Color("e8e8ee"), Color("c94f8a")]
	var routes: Array = district.get("routes", ROUTES)
	for i in routes.size():
		var f := RoamFigure.new()
		add_child(f)
		var people := ["student_boy", "student_girl", "office_worker", "stylish_woman", "street_duelist", "shopkeeper"]
		var mkey: String = people[i % people.size()] if Avatars.has_avatar(people[i % people.size()]) else "walker_%d" % i
		f.setup(mkey, palette[rng.randi() % palette.size()], "", false)
		var body := AnimatableBody3D.new()
		body.sync_to_physics = false
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.3
		cap.height = 1.7
		cs.shape = cap
		cs.position.y = 0.85
		body.add_child(cs)
		f.add_child(body)
		var w := {"id": "walker_%d" % i, "fig": f, "a": routes[i][0], "b": routes[i][1], "t": rng.randf(), "dir": 1.0 if rng.randf() > 0.5 else -1.0,
			"speed": rng.randf_range(1.1, 1.6), "pause": 0.0}
		_walkers.append(w)
		var d := {"id": "walker_%d" % i, "name": "Passerby", "color": Color.GRAY, "lines": [WALK_LINES[i % WALK_LINES.size()]]}
		var marker := Label3D.new()
		marker.visible = false
		f.add_child(marker)
		_npcs.append([d, f, marker])


func _move_walkers(delta: float) -> void:
	for w in _walkers:
		var f: RoamFigure = w["fig"]
		var a: Vector3 = w["a"]
		var b: Vector3 = w["b"]
		var len := a.distance_to(b)
		var near_player := f.global_position.distance_to(_player.global_position) < 1.6
		var talking_to: bool = _talking and _dlg_npc.get("id", "") == str(w["id"])
		if w["pause"] > 0.0:
			w["pause"] -= delta
		var moving: bool = not near_player and not talking_to and w["pause"] <= 0.0
		if moving:
			w["t"] += w["dir"] * w["speed"] * delta / len
			if w["t"] > 1.0 or w["t"] < 0.0:
				w["t"] = clampf(w["t"], 0.0, 1.0)
				w["dir"] = -w["dir"]
				w["pause"] = randf_range(0.5, 2.5)
		var pos := a.lerp(b, w["t"]) + Vector3(0, 0.16, 0)
		f.position = pos
		f.set_speed(w["speed"] if moving else 0.0)
		if not talking_to:
			var heading: Vector3 = (b - a).normalized() * float(w["dir"])
			f.rotation.y = lerp_angle(f.rotation.y, atan2(heading.x, heading.z), 1.0 - exp(-delta * 8.0))


# ------------------------------------------------------------------ player & camera

func _build_player() -> void:
	_player = CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	_player.add_child(cs)
	add_child(_player)
	var start = Router.roam.get("pos")
	_player.position = start if start is Vector3 else district.get("start", Vector3(0, 0, 8))
	_figure = RoamFigure.new()
	_player.add_child(_figure)
	_figure.setup("player", Profile.color(), "", false)
	_yaw = float(Router.roam.get("yaw", district.get("yaw", PI)))
	_figure.rotation.y = _yaw + PI
	_pivot = Node3D.new()
	add_child(_pivot)
	_arm = SpringArm3D.new()
	_arm.spring_length = 6.0
	_arm.margin = 0.3
	var sh := SphereShape3D.new()
	sh.radius = 0.25
	_arm.shape = sh
	_arm.add_excluded_object(_player.get_rid())
	_pivot.add_child(_arm)
	_cam = Camera3D.new()
	_cam.fov = 60
	_arm.add_child(_cam)
	_cam.current = true


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if not _talking and _pause == null and not _overlay_open and not (_map_full and _map_full.visible):
		if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
			input.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
			input.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
			input.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
			input.x += 1
		var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			input = stick
		var look := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		if absf(look) > 0.2:
			_yaw -= look * delta * 2.5
		if Input.is_key_pressed(KEY_Q):
			_yaw += delta * 2.0
	input = input.limit_length(1.0)
	var run := Input.is_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
	var basis := Basis(Vector3.UP, _yaw)
	var dir := basis * Vector3(input.x, 0, input.y)
	var target := dir * (RUN if run else SPEED)
	_player.velocity.x = lerpf(_player.velocity.x, target.x, 1.0 - exp(-delta * 12.0))
	_player.velocity.z = lerpf(_player.velocity.z, target.z, 1.0 - exp(-delta * 12.0))
	_player.velocity.y = 0.0 if _player.is_on_floor() else _player.velocity.y - 20.0 * delta
	_player.move_and_slide()
	var flat := Vector2(_player.velocity.x, _player.velocity.z)
	_figure.set_speed(flat.length())
	if flat.length() > 0.3:
		var want := atan2(flat.x, flat.y)
		_figure.rotation.y = lerp_angle(_figure.rotation.y, want, 1.0 - exp(-delta * 12.0))
	_pivot.position = _pivot.position.lerp(_player.position + Vector3(0, 1.45, 0), 1.0 - exp(-delta * 10.0))
	_pivot.rotation = Vector3(_pitch, _yaw, 0)
	_move_walkers(delta)
	_update_near()


func _unhandled_input(event: InputEvent) -> void:
	if _pause:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
			_close_pause()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_arm.spring_length = maxf(2.5, _arm.spring_length - 0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_arm.spring_length = minf(9.0, _arm.spring_length + 0.4)
	elif event is InputEventMouseMotion and _dragging and not _talking:
		_yaw -= event.relative.x * 0.006
		_pitch = clampf(_pitch - event.relative.y * 0.004, -1.1, 0.15)
	if _talking:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E, KEY_SPACE]):
			if _dlg_buttons.get_child_count() == 0:
				_advance()
				get_viewport().set_input_as_handled()
		return
	if _map_full and _map_full.visible:
		if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_M, KEY_ESCAPE]) or event.is_action_pressed("ui_cancel"):
			_toggle_map()
			get_viewport().set_input_as_handled()
		return
	if _overlay_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_toggle_map()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		_cycle_tod()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_talk()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A):
		_talk()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		_open_pause()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ NPCs

func _npc_name(d: Dictionary) -> String:
	if d.get("name", "") != "":
		return d["name"]
	return Characters.get_char(d.get("char", "")).get("name", "Duelist")


func _npc_color(d: Dictionary) -> Color:
	if d.has("color"):
		return d["color"]
	return Characters.get_char(d.get("char", "")).get("color", Color.WHITE)


func _build_npcs() -> void:
	for d in district.get("npcs", []):
		_add_npc(d, Vector3.ZERO)
	for d in district.get("shop_npcs", []):
		_add_npc(d, ShopInterior.AT)


func _add_npc(d: Dictionary, offset: Vector3) -> void:
	if true:
		var f := RoamFigure.new()
		add_child(f)
		f.position = d["pos"] + offset
		f.rotation.y = d.get("face", 0.0)
		var model_key: String = d.get("char", "")
		if model_key == "":
			model_key = d["id"]
		if not Avatars.has_avatar(model_key) and d.has("model") and Avatars.has_avatar(d["model"]):
			model_key = d["model"]
		f.setup(model_key, _npc_color(d), _npc_name(d))
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.35
		cap.height = 1.7
		cs.shape = cap
		cs.position.y = 0.85
		body.add_child(cs)
		f.add_child(body)
		var marker := Label3D.new()
		marker.font_size = 90
		marker.outline_size = 14
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.position = Vector3(0, 2.45, 0)
		marker.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
		f.add_child(marker)
		var entry := [d, f, marker]
		_npcs.append(entry)
		_refresh_marker(entry)


func _refresh_map_people() -> void:
	if _map == null:
		return
	var list: Array = []
	for n in _npcs:
		var d: Dictionary = n[0]
		var f: Node3D = n[1]
		if f.position.distance_to(ShopInterior.AT) < 30.0:
			continue
		var state := "talk"
		if d.has("duel"):
			state = "beaten" if _beaten.has(d["id"]) else "duel"
		list.append({"pos": Vector2(f.position.x, f.position.z), "state": state, "name": _npc_name(d)})
	_map.npcs = list
	_map_full.npcs = list


func _toggle_map() -> void:
	_map_full.visible = not _map_full.visible
	_map.visible = not _map_full.visible
	Sfx.play("click")


# ------------------------------------------------------------------ places you can enter

func _build_places() -> void:
	# The way to the other district (a ferry bus in town, the pier on the island).
	if district.has("travel"):
		var tr: Dictionary = district["travel"]
		_spots.append({"pos": tr["pos"], "range": 2.6, "label": tr["label"], "action": func(): _travel_district(str(tr["to"]))})
		var sign_l := Label3D.new()
		sign_l.text = "▼  FERRY"
		sign_l.font = UITheme.semi_font()
		sign_l.font_size = 64
		sign_l.pixel_size = 0.005
		sign_l.outline_size = 10
		sign_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign_l.modulate = Color("9fe0ff")
		sign_l.position = (tr["pos"] as Vector3) + Vector3(0, 3.2, 0)
		city.add_child(sign_l)
		var pad := city.box(Vector3(2.4, 0.03, 1.4), (tr["pos"] as Vector3) + Vector3(0, 0.24, 0), city.glow_mat(Color("7fd8ff"), 1.2), false)
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if district.get("builder", "") == "academy":
		return
	ShopInterior.build(city)
	var at := ShopInterior.AT
	_spots.append({"pos": Vector3(-10, 0, -15.4), "range": 2.3, "label": "Enter Kame Game", "action": func(): _travel("kame")})
	_spots.append({"pos": at + Vector3(0, 0, 4.3), "range": 1.7, "label": "Leave the shop", "action": func(): _travel("")})
	_spots.append({"pos": at + Vector3(-6.0, 0, 3.4), "range": 1.7, "label": "Change your look", "action": _open_look})
	# A glowing mat in front of the shop door so the way in is easy to spot.
	var mat_mesh := city.box(Vector3(2.2, 0.03, 1.2), Vector3(-10, 0.18, -15.4), city.glow_mat(Color("ffd166"), 1.3), false)
	mat_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var arrow := Label3D.new()
	arrow.text = "▼  ENTER"
	arrow.font = UITheme.semi_font()
	arrow.font_size = 64
	arrow.pixel_size = 0.005
	arrow.outline_size = 10
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.modulate = Color("ffe9a8")
	arrow.position = Vector3(-10, 3.0, -15.4)
	city.add_child(arrow)


func _travel(where: String) -> void:
	if _overlay_open:
		return
	_overlay_open = true
	var tw := create_tween()
	tw.tween_property(_fader, "color:a", 1.0, 0.22)
	await tw.finished
	if where == "kame":
		_outside_pos = Vector3(-10, 0, -13.6)
		_player.position = ShopInterior.AT + Vector3(0, 0, 3.2)
		_yaw = 0.0
	else:
		_player.position = _outside_pos
		_yaw = PI
	_player.velocity = Vector3.ZERO
	_figure.rotation.y = _yaw + PI
	_pivot.position = _player.position + Vector3(0, 1.45, 0)
	_set_inside(where)
	await get_tree().create_timer(0.12).timeout
	var tw2 := create_tween()
	tw2.tween_property(_fader, "color:a", 0.0, 0.3)
	_overlay_open = false


func _travel_district(key: String) -> void:
	if _overlay_open:
		return
	_overlay_open = true
	Sfx.play("special", -4.0)
	Router.toast("The ferry to %s..." % RoamData.district(key).get("name", key))
	Router.roam["district"] = key
	Router.roam["pos"] = null
	Router.roam.erase("yaw")
	Router.roam.erase("tod")
	Router.go(Router.ROAM)


func _set_inside(where: String) -> void:
	_inside = where
	# A soft fill light that travels with the camera, so you are never a silhouette indoors.
	var fill: OmniLight3D = _cam.get_node_or_null("Fill")
	if fill == null:
		fill = OmniLight3D.new()
		fill.name = "Fill"
		fill.light_color = Color(1.0, 0.93, 0.82)
		fill.light_energy = 1.5
		fill.omni_range = 9.0
		fill.omni_attenuation = 0.6
		fill.shadow_enabled = false
		_cam.add_child(fill)
	fill.visible = where != ""
	_arm.spring_length = 3.6 if where != "" else 6.0
	if _loc_name:
		_loc_name.text = "KAME GAME" if where != "" else str(district.get("name", "")).to_upper()
		_loc_area.text = "Card shop" if where != "" else str(district.get("area", ""))


## A full-screen menu opened from the world (pack shop, deck builder).
func _open_overlay(panel: Control) -> void:
	_overlay_open = true
	_ui.add_child(panel)
	panel.connect("closed", func(): _overlay_open = false)


func _open_look() -> void:
	_overlay_open = true
	var ed := ProfileEditor.new(false)
	_ui.add_child(ed)
	ed.closed.connect(func():
		_overlay_open = false
		var rot := _figure.rotation.y
		_figure.queue_free()
		_figure = RoamFigure.new()
		_player.add_child(_figure)
		_figure.setup("player", Profile.color(), "", false)
		_figure.rotation.y = rot)


func _open_deck_picker() -> void:
	_overlay_open = true
	var p := SidePanel.new("Choose your deck", 620)
	var current: String = Router.duel_config.get("player_deck", "echo")
	var keys: Array = ["custom", "echo"]
	for k in Characters.ORDER:
		if Characters.available(k):
			keys.append(Characters.DATA[k]["deck"])
	for k in keys:
		if not CardData.has_deck(k):
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 64)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 24)
		b.text = ("●  " if k == current else "     ") + CardData.deck_name(k)
		var key: String = k
		b.pressed.connect(func():
			Router.duel_config["player_deck"] = key
			var cfg := ConfigFile.new()
			cfg.load(SAVE_PATH)
			cfg.set_value("roam", "deck", key)
			cfg.save(SAVE_PATH)
			Router.toast("Deck set: %s" % CardData.deck_name(key))
			p.close())
		p.body.add_child(b)
	p.closed.connect(func(): _overlay_open = false)
	_ui.add_child(p)


func _refresh_marker(n: Array) -> void:
	var d: Dictionary = n[0]
	var m: Label3D = n[2]
	if not d.has("duel"):
		m.text = "…"
		m.modulate = Color(1, 1, 1, 0.8)
	elif _beaten.has(d["id"]):
		m.text = "✓"
		m.modulate = Color("5cf2a0")
	else:
		m.text = "!"
		m.modulate = Color("ffd166")


func _update_near() -> void:
	var best: Dictionary = {}
	var best_d := TALK_RANGE
	for n in _npcs:
		var f: Node3D = n[1]
		var dist := f.global_position.distance_to(_player.global_position)
		var m: Label3D = n[2]
		m.position.y = 2.45 + sin(Time.get_ticks_msec() / 300.0) * 0.06
		if dist < best_d:
			best_d = dist
			best = n[0]
	_near = best
	_near_spot = {}
	if _near.is_empty():
		for sp in _spots:
			if (sp["pos"] as Vector3).distance_to(_player.global_position) < float(sp["range"]):
				_near_spot = sp
				break
	if _prompt:
		_prompt.visible = (not _near.is_empty() or not _near_spot.is_empty()) and not _talking and _pause == null and not _overlay_open
		if _prompt.visible:
			_prompt.text = ("E   Talk to %s" % _npc_name(_near)) if not _near.is_empty() else ("E   %s" % _near_spot["label"])
	if _map:
		_map.player_pos = Vector2(_player.position.x, _player.position.z)
		_map.player_yaw = _figure.rotation.y + PI
		_map.inside = _inside
		if _map_full and _map_full.visible:
			_map_full.player_pos = _map.player_pos
			_map_full.player_yaw = _map.player_yaw
			_map_full.inside = _inside


func _talk() -> void:
	if _talking or _overlay_open:
		return
	if _near.is_empty():
		if not _near_spot.is_empty():
			Sfx.play("click")
			(_near_spot["action"] as Callable).call()
		return
	var d := _near
	_dlg_npc = d
	_talking = true
	_dlg_lines = []
	for l in d.get("lines", []):
		_dlg_lines.append(str(l).replace("{player}", Profile.duelist_name))
	if d.has("duel"):
		var duel: Dictionary = d["duel"]
		if _beaten.has(d["id"]):
			_dlg_lines.append("Rematch? I won't go easy on you this time.")
		else:
			_dlg_lines.append("So? Are we dueling or what?")
	_dlg_index = 0
	# Turn to face each other.
	for n in _npcs:
		if n[0] == d:
			var f: Node3D = n[1]
			var to := _player.global_position - f.global_position
			create_tween().tween_property(f, "rotation:y", atan2(to.x, to.z), 0.3)
			var back := f.global_position - _player.global_position
			create_tween().tween_property(_figure, "rotation:y", atan2(back.x, back.z), 0.3)
			# Over-the-shoulder framing for the conversation.
			var want_yaw := atan2(to.x, to.z) + 0.6
			create_tween().tween_property(self, "_yaw", _yaw + wrapf(want_yaw - _yaw, -PI, PI), 0.45).set_trans(Tween.TRANS_SINE)
	_dlg.visible = true
	_dlg_name.text = _npc_name(d).to_upper()
	_dlg_name.add_theme_color_override("font_color", _npc_color(d).lightened(0.3))
	_show_line()
	Sfx.play("click")


func _show_line() -> void:
	for c in _dlg_buttons.get_children():
		c.queue_free()
	_dlg_text.text = _dlg_lines[_dlg_index]
	_dlg_text.visible_ratio = 0.0
	create_tween().tween_property(_dlg_text, "visible_ratio", 1.0, 0.02 * _dlg_text.text.length())
	var last := _dlg_index == _dlg_lines.size() - 1
	if last and _dlg_npc.has("shop"):
		var deck_btn := Button.new()
		deck_btn.text = "  Choose my deck  "
		deck_btn.add_theme_font_size_override("font_size", 26)
		deck_btn.pressed.connect(func():
			_end_talk()
			_open_deck_picker())
		_dlg_buttons.add_child(deck_btn)
		var bye := Button.new()
		var packs := Button.new()
		packs.text = "  Buy packs  "
		packs.add_theme_font_size_override("font_size", 26)
		packs.pressed.connect(func():
			_end_talk()
			_open_overlay(PackShop.new()))
		_dlg_buttons.add_child(packs)
		_dlg_buttons.move_child(packs, 0)
		var build := Button.new()
		build.text = "  Build my deck  "
		build.add_theme_font_size_override("font_size", 26)
		build.pressed.connect(func():
			_end_talk()
			_open_overlay(DeckBuilder.new()))
		_dlg_buttons.add_child(build)
		bye.text = "  Just looking  "
		bye.add_theme_font_size_override("font_size", 26)
		bye.pressed.connect(_end_talk)
		_dlg_buttons.add_child(bye)
		deck_btn.grab_focus.call_deferred()
	elif last and _dlg_npc.has("duel"):
		var duel_btn := Button.new()
		duel_btn.text = "  Duel!  "
		duel_btn.add_theme_font_size_override("font_size", 26)
		duel_btn.pressed.connect(_start_duel)
		_dlg_buttons.add_child(duel_btn)
		var later := Button.new()
		later.text = "  Not now  "
		later.add_theme_font_size_override("font_size", 26)
		later.pressed.connect(_end_talk)
		_dlg_buttons.add_child(later)
		duel_btn.grab_focus.call_deferred()


func _advance() -> void:
	if _dlg_text.visible_ratio < 1.0:
		_dlg_text.visible_ratio = 1.0
		return
	if _dlg_index + 1 < _dlg_lines.size():
		_dlg_index += 1
		_show_line()
	else:
		_end_talk()


func _end_talk() -> void:
	_talking = false
	_dlg.visible = false
	for c in _dlg_buttons.get_children():
		c.queue_free()


func _start_duel() -> void:
	var d := _dlg_npc
	var duel: Dictionary = d["duel"]
	Router.roam["pos"] = _player.position
	Router.roam["yaw"] = _yaw
	Router.roam["last_duel"] = d["id"]
	var opp_key: String = d.get("char", "")
	if opp_key == "":
		opp_key = d["id"]
	Router.duel_config = {
		"opponent": opp_key, "opponent_deck": duel.get("deck", "joey"),
		"player_deck": Router.duel_config.get("player_deck", "echo"), "player_char": "player",
		"difficulty": duel.get("difficulty", 1), "field": district.get("theme", "battlecity"),
		"story": true, "lose_ok": true, "return_to": Router.ROAM, "continue_label": "Back to %s" % district.get("name", "town"),
	}
	_end_talk()
	Router.go(Router.DUEL)


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	# Location card, top left.
	var loc := VBoxContainer.new()
	loc.position = Vector2(48, 36)
	_ui.add_child(loc)
	_loc_name = UITheme.label(district.get("name", "").to_upper(), 46, Color.WHITE, UITheme.title_font())
	loc.add_child(_loc_name)
	_loc_area = UITheme.label(district.get("area", ""), 22, _theme["accent"], UITheme.semi_font())
	loc.add_child(_loc_area)
	_counter = UITheme.label("", 20, UITheme.TEXT_DIM)
	loc.add_child(_counter)
	_update_counter()
	# Controls, bottom left.
	var help := UITheme.label("WASD / stick  move     Shift  run     Drag  look     Scroll  zoom     E  talk / enter     M  map     T  time of day     Esc  menu", 18, Color(1, 1, 1, 0.5))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.position = Vector2(48, -50)
	help.offset_top = -50
	help.offset_left = 48
	_ui.add_child(help)
	# Maps: a small one in the corner, the full one on M.
	_map = RoamMap.new()
	_map.accent = _theme["accent"]
	_map.anchor_left = 1.0
	_map.anchor_right = 1.0
	_map.offset_left = -292
	_map.offset_right = -36
	_map.offset_top = 36
	_map.offset_bottom = 292
	_ui.add_child(_map)
	_map_full = RoamMap.new()
	_map_full.full = true
	_map_full.accent = _theme["accent"]
	_map_full.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_full.offset_left = 260
	_map_full.offset_right = -260
	_map_full.offset_top = 70
	_map_full.offset_bottom = -70
	_map_full.visible = false
	_ui.add_child(_map_full)
	_refresh_map_people()
	_fader = ColorRect.new()
	_fader.color = Color(0, 0, 0, 0)
	_fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fader)
	# Talk prompt.
	_prompt = Label.new()
	_prompt.add_theme_font_override("font", UITheme.semi_font())
	_prompt.add_theme_font_size_override("font_size", 30)
	var sb := UITheme.panel_box(Color(0.03, 0.06, 0.1, 0.9), 14, Color(UITheme.ACCENT, 0.6))
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_prompt.add_theme_stylebox_override("normal", sb)
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -200
	_prompt.offset_bottom = -148
	_prompt.offset_left = -200
	_prompt.offset_right = 200
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_ui.add_child(_prompt)
	# Dialogue box.
	_dlg = PanelContainer.new()
	_dlg.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.09, 0.94), 22, Color(UITheme.ACCENT, 0.4)))
	_dlg.anchor_left = 0.5
	_dlg.anchor_right = 0.5
	_dlg.anchor_top = 1.0
	_dlg.anchor_bottom = 1.0
	_dlg.offset_left = -620
	_dlg.offset_right = 620
	_dlg.offset_top = -290
	_dlg.offset_bottom = -60
	_dlg.visible = false
	_ui.add_child(_dlg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_dlg.add_child(v)
	_dlg_name = UITheme.label("", 28, UITheme.ACCENT, UITheme.title_font())
	v.add_child(_dlg_name)
	_dlg_text = UITheme.label("", 30, Color.WHITE)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(1180, 90)
	v.add_child(_dlg_text)
	_dlg_buttons = HBoxContainer.new()
	_dlg_buttons.add_theme_constant_override("separation", 14)
	_dlg_buttons.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(_dlg_buttons)


func _update_counter() -> void:
	if _counter == null:
		return
	var total := 0
	var won := 0
	for d in district.get("npcs", []):
		if d.has("duel"):
			total += 1
			if _beaten.has(d["id"]):
				won += 1
	_counter.text = "Street duels won  %d / %d" % [won, total]


func _open_pause() -> void:
	_pause = Control.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	c.add_child(v)
	v.add_child(UITheme.label("PAUSED", 64, Color.WHITE, UITheme.title_font()))
	var resume := Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(320, 60)
	resume.pressed.connect(_close_pause)
	v.add_child(resume)
	var menu := Button.new()
	menu.text = "Main Menu"
	menu.custom_minimum_size = Vector2(320, 60)
	menu.pressed.connect(func():
		Router.roam["pos"] = _player.position
		Router.roam["yaw"] = _yaw
		Router.go(Router.MAIN_MENU))
	v.add_child(menu)
	_ui.add_child(_pause)
	resume.grab_focus()


func _close_pause() -> void:
	if _pause:
		_pause.queue_free()
		_pause = null


# ------------------------------------------------------------------ debug

func _debug() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--roam-talk="):
			var who := a.substr(12)
			await get_tree().create_timer(1.0).timeout
			for n in _npcs:
				if n[0]["id"] == who:
					var f: Node3D = n[1]
					var fwd := Vector3(0, 0, 1).rotated(Vector3.UP, f.rotation.y)
					_player.position = f.position + fwd * 2.0
					_yaw = atan2(fwd.x, fwd.z)
					_pivot.position = _player.position + Vector3(0, 1.45, 0)
			await get_tree().create_timer(0.5).timeout
			_update_near()
			_talk()
			for i in 2:
				await get_tree().create_timer(0.4).timeout
				_advance()
		elif a == "--shop":
			await get_tree().create_timer(0.6).timeout
			await _travel("kame")
			_pitch = -0.12
		elif a == "--map":
			await get_tree().create_timer(0.6).timeout
			_toggle_map()
		elif a.begins_with("--at="):
			var parts := a.trim_prefix("--at=").split(",")
			await get_tree().create_timer(0.3).timeout
			_player.position = Vector3(float(parts[0]), 0, float(parts[1]))
			_yaw = float(parts[2]) if parts.size() > 2 else _yaw
			_figure.rotation.y = _yaw + PI
			_pivot.position = _player.position + Vector3(0, 1.45, 0)
		elif a == "--lineup":
			# Model check: everyone in a row in front of the camera.
			var keys: Array = Characters.ORDER
			for i in keys.size():
				var f := RoamFigure.new()
				add_child(f)
				var row := i / 8
				f.position = Vector3(-4.9 + (i % 8) * 1.4, 0, 4.0 - row * 2.2)
				f.setup(keys[i], Characters.get_char(keys[i]).get("color", Color.WHITE), Characters.get_char(keys[i]).get("short", ""))
			_player.position = Vector3(0, 0, 6.2 if "--close" in OS.get_cmdline_user_args() else 9.0)
			_yaw = 0.0
			_pitch = -0.1
			_arm.spring_length = 0.1
			_figure.visible = false
			for n in _npcs:
				n[1].visible = false
		elif a == "--roam-walk":
			await get_tree().create_timer(0.5).timeout
			_yaw = PI * 0.8
			Input.action_press("ui_up")
