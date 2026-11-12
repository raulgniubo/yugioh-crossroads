extends Node3D
## New Domino Highway: ride your duel runner down the night highway. Steer between the lanes,
## hit boost strips, grab Star Chips, dodge the cargo haulers, and pull alongside another
## rider to challenge them to a Turbo Duel.

const SAVE := "user://turbo.cfg"
const LANE := 4.4
const RIVALS := [
	{"key": "crow", "deck": "crow", "difficulty": 1, "pace": 30.0, "line": "Delivery run can wait. Let's ride!"},
	{"key": "akiza", "deck": "akiza", "difficulty": 1, "pace": 34.0, "line": "Keep up, if you can."},
	{"key": "kalin", "deck": "kalin", "difficulty": 2, "pace": 38.0, "line": "A duel at full speed. Now that is satisfying."},
	{"key": "yusei", "deck": "yusei", "difficulty": 2, "pace": 42.0, "line": "Speed World 2, set on! Let's rev it up!"},
	{"key": "jack", "deck": "jack", "difficulty": 3, "pace": 47.0, "line": "The King rides alone. Prove you belong on my road!"},
]

var track: TurboTrack
var _cam: Camera3D
var _z := 0.0                 # the player's place across the road
var _vz := 0.0
var _speed := 28.0
var _boost := 0.0
var _stun := 0.0
var _dist := 0.0
var _riders: Array = []       # {info, x, z, lane_t, index, tag}
var _things: Array = []       # {kind, node, x, z}
var _beaten := {}
var _chips := 0
var _near := -1
var _ui: CanvasLayer
var _prompt: Label
var _speed_l: Label
var _info: Label
var _gauge: Control
var _radar: Control
var _paused := false
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		_beaten = cfg.get_value("turbo", "beaten", {})
		_chips = int(cfg.get_value("turbo", "chips", 0))
	# Back from a Turbo Duel started here?
	var came_back := false
	if Router.story_result != "" and str(Router.roam.get("turbo_rival", "")) != "":
		var who := str(Router.roam["turbo_rival"])
		if Router.story_result == "won":
			_beaten[who] = true
			_save()
		came_back = true
		var nm := str(Characters.get_char(who).get("short", who))
		Router.toast.call_deferred((Loc.t("You beat %s!") % nm) if Router.story_result == "won" else (Loc.t("%s wins this time. Try again!") % nm))
		Router.story_result = ""
		Router.roam["turbo_rival"] = ""
	_build_world()
	_build_ui()
	Music.play("turbo")
	Sfx.ambience("engine", -14.0)
	Pad.walk_mode = true
	Pad.hint("Left stick  steer     RT  throttle     LT  brake     A  challenge     B  back")
	if not came_back:
		Router.toast.call_deferred("New Domino Highway. Pull alongside a rider and press E to duel.")


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("turbo", "beaten", _beaten)
	cfg.set_value("turbo", "chips", _chips)
	cfg.save(SAVE)


func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("03040a")
	sm.sky_horizon_color = Color("2a1840")
	sm.ground_bottom_color = Color("020308")
	sm.ground_horizon_color = Color("2a1840")
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.8)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.fog_enabled = true
	env.fog_light_color = Color("140c22")
	env.fog_density = 0.006
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.7, 0.78, 1.0)
	moon.light_energy = 0.7
	moon.rotation_degrees = Vector3(-50, 40, 0)
	add_child(moon)
	track = TurboTrack.new()
	add_child(track)
	track.build(Color("ff8a3a"), Color("2de2e6"))
	track.add_rider(0, "player", Vector3.ZERO, Profile.color())
	track.place_rider(0, Vector3.ZERO)
	var i := 1
	for r in RIVALS:
		var info: Dictionary = r
		var col: Color = Characters.get_char(str(info["key"])).get("color", Color.WHITE)
		track.add_rider(i, str(info["key"]), Vector3(40.0 * i, 0, 0), col)
		var tag := Label3D.new()
		tag.font_size = 44
		tag.pixel_size = 0.006
		tag.outline_size = 12
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = Vector3(0, 2.5, 0)
		track.rider_node(i).add_child(tag)
		_riders.append({"info": info, "x": 30.0 + 45.0 * i, "z": LANE * float((i % 5) - 2), "lane_t": _rng.randf() * 6.0, "index": i, "tag": tag})
		i += 1
	_refresh_tags()
	for k in 7:
		_spawn_thing(60.0 + k * 45.0)
	_cam = Camera3D.new()
	_cam.fov = 68.0
	_cam.far = 400.0
	add_child(_cam)
	_cam.current = true
	_place_camera(1.0)


func _refresh_tags() -> void:
	for r in _riders:
		var key := str(r["info"]["key"])
		var short := str(Characters.get_char(key).get("short", key))
		(r["tag"] as Label3D).text = ("✓ " if _beaten.has(key) else "⚔ ") + short
		(r["tag"] as Label3D).modulate = Color("5affa0") if _beaten.has(key) else Color("ffd166")


## Things on the road: boost strips, Star Chips and slow cargo haulers.
func _spawn_thing(x: float) -> void:
	var roll := _rng.randf()
	var kind := "boost" if roll < 0.35 else ("chip" if roll < 0.75 else "hauler")
	var z := LANE * float(_rng.randi_range(-2, 2))
	var node := Node3D.new()
	match kind:
		"boost":
			for k in 3:
				var mi := MeshInstance3D.new()
				var pm := PrismMesh.new()
				pm.size = Vector3(2.4, 2.0, 0.04)
				mi.mesh = pm
				mi.rotation = Vector3(-PI / 2.0, 0, -PI / 2.0)
				mi.position = Vector3(k * 2.2, 0.03, 0)
				mi.material_override = track._glow(Color("5affd0"), 3.0)
				node.add_child(mi)
		"chip":
			var mi2 := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.34
			tm.outer_radius = 0.5
			mi2.mesh = tm
			mi2.rotation.z = PI / 2.0
			mi2.position.y = 1.1
			mi2.material_override = track._glow(Color("ffd23a"), 3.5)
			node.add_child(mi2)
			var l := OmniLight3D.new()
			l.light_color = Color("ffd23a")
			l.omni_range = 4.0
			l.light_energy = 2.0
			l.position.y = 1.1
			node.add_child(l)
		"hauler":
			track._box(node, Vector3(6.5, 2.6, 2.6), Vector3(0, 1.7, 0), track._solid(Color(0.16, 0.18, 0.24)))
			track._box(node, Vector3(1.8, 1.8, 2.4), Vector3(4.2, 1.3, 0), track._solid(Color(0.3, 0.12, 0.1)))
			track._box(node, Vector3(0.1, 0.5, 2.2), Vector3(-3.3, 1.2, 0), track._glow(Color("ff3030"), 3.0))
			track._box(node, Vector3(6.4, 0.08, 0.08), Vector3(0, 0.5, 1.32), track._glow(Color("ff8a3a"), 2.0))
			track._box(node, Vector3(6.4, 0.08, 0.08), Vector3(0, 0.5, -1.32), track._glow(Color("ff8a3a"), 2.0))
	add_child(node)
	_things.append({"kind": kind, "node": node, "x": x, "z": z})


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.build()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	var title := UITheme.label("NEW DOMINO HIGHWAY", 40, Color.WHITE, UITheme.title_font())
	title.position = Vector2(48, 36)
	root.add_child(title)
	_info = UITheme.label("", 20, UITheme.TEXT_DIM)
	_info.position = Vector2(50, 88)
	root.add_child(_info)
	_prompt = UITheme.label("", 30, UITheme.GOLD, UITheme.title_font())
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -600
	_prompt.offset_right = 600
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_prompt)
	_gauge = Control.new()
	_gauge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_gauge.offset_left = -300
	_gauge.offset_top = -280
	_gauge.offset_right = -40
	_gauge.offset_bottom = -30
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.draw.connect(_draw_gauge)
	root.add_child(_gauge)
	_radar = Control.new()
	_radar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_radar.offset_left = -260
	_radar.offset_right = 520
	_radar.offset_top = 34
	_radar.offset_bottom = 110
	_radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radar.draw.connect(_draw_radar)
	root.add_child(_radar)
	var help := UITheme.label("W / S  throttle and brake     A / D  steer     E  challenge a rider     Esc  back to the menu", 17, UITheme.TEXT_DIM)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.offset_left = 48
	help.offset_top = -52
	help.offset_bottom = -22
	help.offset_right = 1200
	root.add_child(help)


func _draw_gauge() -> void:
	var c := Vector2(130, 135)
	var r := 104.0
	var a0 := deg_to_rad(150.0)
	var a1 := deg_to_rad(390.0)
	var f := clampf((_speed - 10.0) / 60.0, 0.0, 1.0)
	var col := Color("5affd0") if _boost > 0.0 else Color("ff8a3a")
	_gauge.draw_circle(c, r + 12.0, Color(0.02, 0.03, 0.06, 0.85))
	_gauge.draw_arc(c, r + 12.0, 0, TAU, 64, Color(col, 0.5), 2.0, true)
	_gauge.draw_arc(c, r, a0, a1, 48, Color(1, 1, 1, 0.12), 10.0, true)
	_gauge.draw_arc(c, r, a0, lerpf(a0, a1, f), 48, col, 10.0, true)
	for i in 13:
		var a := lerpf(a0, a1, i / 12.0)
		var d := Vector2(cos(a), sin(a))
		_gauge.draw_line(c + d * (r - 18.0), c + d * (r - 6.0), Color(1, 1, 1, 0.6), 2.0)
	var an := lerpf(a0, a1, f)
	_gauge.draw_line(c, c + Vector2(cos(an), sin(an)) * (r - 24.0), Color.WHITE, 4.0, true)
	_gauge.draw_circle(c, 7.0, col)
	var font := UITheme.title_font()
	var txt := str(int(_speed * 5.2))
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 46)
	_gauge.draw_string(font, c + Vector2(-ts.x / 2.0, 62), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color.WHITE)
	_gauge.draw_string(UITheme.semi_font(), c + Vector2(-20, 86), "KM/H", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.6))


## A strip across the top showing where the other riders are, ahead or behind.
func _draw_radar() -> void:
	var w := _radar.size.x
	var mid := w / 2.0
	_radar.draw_rect(Rect2(0, 30, w, 6), Color(1, 1, 1, 0.12))
	_radar.draw_circle(Vector2(mid, 33), 9.0, Profile.color())
	var font := UITheme.semi_font()
	for r in _riders:
		var dx: float = clampf(float(r["x"]) / 260.0, -1.0, 1.0)
		var key := str(r["info"]["key"])
		var col := Color("5affa0") if _beaten.has(key) else Color("ffd166")
		var px := mid + dx * (mid - 20.0)
		_radar.draw_circle(Vector2(px, 33), 7.0, col)
		var short := str(Characters.get_char(key).get("short", key))
		var label := "%s  %dm" % [short, int(absf(float(r["x"])))]
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		_radar.draw_string(font, Vector2(px - ts.x / 2.0, 62 if int(r["index"]) % 2 == 0 else 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)


func _place_camera(w: float) -> void:
	var want := Vector3(-7.4 - _speed * 0.03, 3.1, _z * 0.82)
	_cam.position = _cam.position.lerp(want, w)
	_cam.look_at(Vector3(9.0, 1.1, _z * 0.9), Vector3.UP)
	_cam.fov = lerpf(_cam.fov, 66.0 + (_speed - 28.0) * 0.5 + (8.0 if _boost > 0.0 else 0.0), clampf(w * 0.5, 0.0, 1.0))
	if _boost > 0.0 or _stun > 0.0:
		_cam.h_offset = randf_range(-0.03, 0.03)
		_cam.v_offset = randf_range(-0.03, 0.03)
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0


func _process(delta: float) -> void:
	if _paused:
		return
	_t += delta
	# Controls: throttle, brake, steer.
	var throttle := Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	if Input.is_key_pressed(KEY_W):
		throttle = 1.0
	elif Input.is_key_pressed(KEY_S):
		throttle = -1.0
	throttle += Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	var steer := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if Input.is_key_pressed(KEY_D):
		steer = 1.0
	elif Input.is_key_pressed(KEY_A):
		steer = -1.0
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if absf(jx) > 0.2:
		steer = jx
	throttle = clampf(throttle, -1.0, 1.0)
	_boost = maxf(0.0, _boost - delta)
	_stun = maxf(0.0, _stun - delta)
	var top := 56.0 if _boost > 0.0 else 46.0
	var cruise := 30.0
	var goal := cruise + throttle * (top - cruise if throttle > 0.0 else 16.0)
	if _boost > 0.0:
		goal = top + 8.0
	if _stun > 0.0:
		goal = 16.0
	_speed = move_toward(_speed, goal, delta * (30.0 if _boost > 0.0 else (14.0 if goal > _speed else 22.0)))
	_vz = lerpf(_vz, steer * 11.0, clampf(delta * 6.0, 0.0, 1.0))
	_z = clampf(_z + _vz * delta, -LANE * 2.4, LANE * 2.4)
	_dist += _speed * delta
	track.target_speed = _speed
	track.speed = lerpf(track.speed, _speed, clampf(delta * 6.0, 0.0, 1.0))
	track.place_rider(0, Vector3(0, 0, _z), -_vz * 0.035)
	# Other riders hold their own pace and wander between lanes.
	_near = -1
	var best := 99.0
	for r in _riders:
		var info: Dictionary = r["info"]
		r["x"] = float(r["x"]) + (float(info["pace"]) - _speed) * delta
		if float(r["x"]) > 280.0:
			r["x"] = -220.0
		elif float(r["x"]) < -260.0:
			r["x"] = 240.0
		r["lane_t"] = float(r["lane_t"]) + delta
		var want_z: float = LANE * float(int(float(r["lane_t"]) / 7.0 + int(r["index"])) % 5 - 2)
		var before: float = r["z"]
		r["z"] = move_toward(before, want_z, delta * 2.2)
		track.place_rider(int(r["index"]), Vector3(float(r["x"]), 0, float(r["z"])), -(float(r["z"]) - before) / maxf(delta, 0.001) * 0.035)
		var d := Vector2(float(r["x"]), float(r["z"]) - _z).length()
		if absf(float(r["x"])) < 7.0 and absf(float(r["z"]) - _z) < LANE * 1.4 and d < best:
			best = d
			_near = _riders.find(r)
	# Things on the road.
	for th in _things:
		th["x"] = float(th["x"]) - (_speed - (14.0 if th["kind"] == "hauler" else 0.0)) * delta
		var node: Node3D = th["node"]
		node.position = Vector3(float(th["x"]), 0, float(th["z"]))
		if th["kind"] == "chip":
			node.rotation.y += delta * 3.0
		if float(th["x"]) < -40.0:
			_recycle(th)
			continue
		var hit_x := 3.6 if th["kind"] != "chip" else 1.6
		if absf(float(th["x"])) < hit_x and absf(float(th["z"]) - _z) < (1.9 if th["kind"] == "hauler" else 1.7):
			match str(th["kind"]):
				"boost":
					if _boost <= 0.0:
						Sfx.play("whoosh", -2.0, 1.3)
						Sfx.play("charge", -4.0, 1.4)
					_boost = 2.6
				"chip":
					_chips += 1
					Collection.dp += 15
					Collection.save()
					_save()
					Sfx.play("coin", -3.0)
					Router.toast(Loc.t("Star Chip!  +15 Duel Points  (%d on this road)") % _chips)
					_recycle(th)
				"hauler":
					if _stun <= 0.0:
						Sfx.play("impact", -2.0, 0.7)
						_stun = 1.2
						_boost = 0.0
						_speed = minf(_speed, 18.0)
						_z += signf(_z - float(th["z"]) + 0.01) * 2.4
	_place_camera(clampf(delta * 5.0, 0.0, 1.0))
	if _near >= 0:
		var key := str(_riders[_near]["info"]["key"])
		_prompt.text = Loc.t("E   Turbo Duel with %s") % str(Characters.get_char(key).get("name", key))
	else:
		_prompt.text = ""
	_info.text = Loc.t("Riders beaten %d / %d     Star Chips %d     Distance %.1f km") % [_beaten.size(), RIVALS.size(), _chips, _dist / 1000.0]
	_gauge.queue_redraw()
	_radar.queue_redraw()


func _recycle(th: Dictionary) -> void:
	(th["node"] as Node3D).queue_free()
	_things.erase(th)
	_spawn_thing(_rng.randf_range(150.0, 260.0))


func _challenge() -> void:
	if _near < 0:
		return
	var info: Dictionary = _riders[_near]["info"]
	var key := str(info["key"])
	_paused = true
	Sfx.play("gong", -3.0)
	Router.toast(str(info["line"]))
	Router.roam["turbo_rival"] = key
	var deck := str(info["deck"])
	if not CardData.has_deck(deck):
		deck = ["yusei", "jaden", "kaiba", "yugi", "joey"][absi(key.hash()) % 5]
	Router.match_state = {}
	Router.duel_config = {
		"opponent": key, "opponent_deck": deck, "player_deck": Router.duel_config.get("player_deck", "echo"), "player_char": "player",
		"difficulty": int(info["difficulty"]), "turbo": true, "story": true, "lose_ok": true, "return_to": Router.RIDE,
		"continue_label": Loc.t("Back to the highway"),
	}
	await get_tree().create_timer(1.1).timeout
	Router.go(Router.DUEL)


func _unhandled_input(event: InputEvent) -> void:
	if _paused:
		return
	if event.is_action_pressed("ui_cancel"):
		_paused = true
		Sfx.ambience("")
		Pad.walk_mode = false
		Router.go(Router.MAIN_MENU)
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E) or event.is_action_pressed("ui_accept"):
		_challenge()
