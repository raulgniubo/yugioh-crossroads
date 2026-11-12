extends Node3D
## The New Domino Highway ring: one loop from Satellite through a tunnel, over the bay bridge
## and past the Tops, with exits down to both cities. Steer between lanes, hit boost strips
## and jump ramps, grab Star Chips, dodge the haulers, pull alongside a rider for a Turbo
## Duel, or line up at the start flag and race everyone for a lap.

const SAVE := "user://turbo.cfg"
const LANE := 4.4
const LAP := 2600.0
## Stretches of the ring: [from, to, scenery, name].
const ZONES := [[0.0, 500.0, "satellite", "Satellite Flats"], [500.0, 800.0, "tunnel", "Old Harbor Tunnel"],
	[800.0, 1500.0, "bridge", "Daedalus Bay Bridge"], [1500.0, 2300.0, "tops", "The Tops Skyway"], [2300.0, 2600.0, "tunnel", "Ring Tunnel"]]
const EXITS := [{"s": 250.0, "to": "satellite", "name": "Satellite"}, {"s": 1900.0, "to": "newdomino", "name": "New Domino City"}]
const RAMPS := [1150.0, 1380.0, 2120.0]
const RIVALS := [
	{"key": "crow", "deck": "crow", "difficulty": 1, "pace": 30.0, "race": 39.0, "line": "Delivery run can wait. Let's ride!"},
	{"key": "akiza", "deck": "akiza", "difficulty": 1, "pace": 34.0, "race": 41.0, "line": "Keep up, if you can."},
	{"key": "kalin", "deck": "kalin", "difficulty": 2, "pace": 38.0, "race": 43.0, "line": "A duel at full speed. Now that is satisfying."},
	{"key": "yusei", "deck": "yusei", "difficulty": 2, "pace": 42.0, "race": 45.5, "line": "Speed World 2, set on! Let's rev it up!"},
	{"key": "jack", "deck": "jack", "difficulty": 3, "pace": 47.0, "race": 47.0, "line": "The King rides alone. Prove you belong on my road!"},
]

var track: TurboTrack
var _cam: Camera3D
var _s := 0.0                 # where on the ring the player is
var _z := 0.0                 # the player's place across the road
var _vz := 0.0
var _y := 0.0                 # height off the road (ramps)
var _vy := 0.0
var _speed := 28.0
var _boost := 0.0
var _stun := 0.0
var _dist := 0.0
var _riders: Array = []       # {info, x, z, lane_t, index, tag, race_d}
var _things: Array = []       # {kind, node, x, z}
var _fixed: Array = []        # ring furniture at a set place: {s, node, kind}
var _beaten := {}
var _chips := 0
var _best := 0.0
var _wins := 0
var _near := -1
var _exit := -1
var _ui: CanvasLayer
var _prompt: Label
var _info: Label
var _zone_l: Label
var _big: Label
var _gauge: Control
var _radar: Control
var _paused := false
var _t := 0.0
var _rng := RandomNumberGenerator.new()
# race
var _test_on := false         # --ride-test: an autopilot rides a race lap, then takes an exit
var _test_z := 0.0
var _race := ""               # "", "count", "on", "done"
var _race_d := 0.0
var _race_t := 0.0
var _count := 0.0


func _ready() -> void:
	_rng.randomize()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		_beaten = cfg.get_value("turbo", "beaten", {})
		_chips = int(cfg.get_value("turbo", "chips", 0))
		_best = float(cfg.get_value("turbo", "best", 0.0))
		_wins = int(cfg.get_value("turbo", "wins", 0))
	# Where you come onto the ring.
	var from := str(Router.roam.get("ride_from", ""))
	_s = float(Router.roam.get("ride_s", {"satellite": 262.0, "newdomino": 1912.0}.get(from, 40.0)))
	Router.roam["ride_from"] = ""
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
	Pad.hint("Left stick  steer     RT  throttle     LT  brake     A  duel / exit     X  race     B  back")
	if "--ride-test" in OS.get_cmdline_user_args():
		_self_test.call_deferred()
	if not came_back:
		Router.toast.call_deferred("The highway ring. Pull alongside a rider and press E to duel, or take an exit lane down to a city.")


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("turbo", "beaten", _beaten)
	cfg.set_value("turbo", "chips", _chips)
	cfg.set_value("turbo", "best", _best)
	cfg.set_value("turbo", "wins", _wins)
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
		_riders.append({"info": info, "x": 60.0 + 190.0 * i, "z": LANE * float((i % 5) - 2), "lane_t": _rng.randf() * 6.0, "index": i, "tag": tag, "race_d": 0.0})
		i += 1
	_refresh_tags()
	for k in 7:
		_spawn_thing(60.0 + k * 45.0)
	_build_fixed()
	_cam = Camera3D.new()
	_cam.fov = 68.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.current = true
	_apply_zone()
	_place_camera(1.0)


func _refresh_tags() -> void:
	for r in _riders:
		var key := str(r["info"]["key"])
		var short := str(Characters.get_char(key).get("short", key))
		(r["tag"] as Label3D).text = ("✓ " if _beaten.has(key) else "⚔ ") + short
		(r["tag"] as Label3D).modulate = Color("5affa0") if _beaten.has(key) else Color("ffd166")


## Ring furniture that sits at one place on the loop: the start gantry, exit signs and lanes, ramps.
func _build_fixed() -> void:
	# Start and finish line.
	var start := Node3D.new()
	track._box(start, Vector3(1.0, 9.5, 1.0), Vector3(0, 4.75, -14.0), track._solid(Color(0.85, 0.87, 0.9)))
	track._box(start, Vector3(1.0, 9.5, 1.0), Vector3(0, 4.75, 14.0), track._solid(Color(0.85, 0.87, 0.9)))
	track._box(start, Vector3(1.2, 2.2, 29.0), Vector3(0, 8.6, 0), track._solid(Color(0.08, 0.09, 0.12)))
	for k in 12:
		track._box(start, Vector3(0.1, 1.0, 1.15), Vector3(-0.66, 8.6 + (0.5 if k % 2 == 0 else -0.5), -13.2 + k * 2.4), track._glow(Color.WHITE, 2.0))
	for k in 24:
		track._box(start, Vector3(1.2, 0.02, 1.2), Vector3((0.6 if k % 2 == 0 else -0.6), 0.02, -13.8 + k * 1.2), track._glow(Color.WHITE, 0.9))
	var sl := Label3D.new()
	sl.text = "START  ·  FINISH"
	sl.font_size = 150
	sl.pixel_size = 0.012
	sl.modulate = Color("ffd166")
	sl.position = Vector3(-0.8, 10.6, 0)
	sl.rotation.y = -PI / 2
	start.add_child(sl)
	add_child(start)
	_fixed.append({"s": 0.0, "node": start, "kind": "start"})
	for e in EXITS:
		var ex := Node3D.new()
		track._box(ex, Vector3(0.8, 8.4, 0.8), Vector3(0, 4.2, 14.0), track._solid(Color(0.1, 0.11, 0.15)))
		track._box(ex, Vector3(0.6, 0.6, 12.0), Vector3(0, 8.2, 8.5), track._solid(Color(0.1, 0.11, 0.15)))
		track._box(ex, Vector3(0.2, 2.6, 9.0), Vector3(-0.3, 6.6, 8.0), track._glow(Color(0.1, 0.5, 0.25), 1.2))
		var el := Label3D.new()
		el.text = "EXIT  ▶\n" + str(e["name"]).to_upper()
		el.font_size = 110
		el.pixel_size = 0.011
		el.modulate = Color.WHITE
		el.position = Vector3(-0.5, 6.6, 8.0)
		el.rotation.y = -PI / 2
		ex.add_child(el)
		# The exit lane: green arrows painted along the right edge for the whole window.
		for k in 10:
			var arrow := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(2.0, 2.4, 0.04)
			arrow.mesh = pm
			arrow.rotation = Vector3(-PI / 2.0, 0, -PI / 2.0)
			arrow.position = Vector3(-54.0 + k * 12.0, 0.03, LANE * 2.2)
			arrow.material_override = track._glow(Color("5aff90"), 2.4)
			ex.add_child(arrow)
		add_child(ex)
		_fixed.append({"s": float(e["s"]), "node": ex, "kind": "exit"})
	for rs in RAMPS:
		var ramp := Node3D.new()
		var wedge := MeshInstance3D.new()
		var pm2 := PrismMesh.new()
		pm2.size = Vector3(7.0, 1.5, 8.0)
		pm2.left_to_right = 1.0
		wedge.mesh = pm2
		wedge.position = Vector3(0, 0.75, 0)
		wedge.material_override = track._solid(Color(0.16, 0.17, 0.22))
		ramp.add_child(wedge)
		for k in 3:
			track._box(ramp, Vector3(0.3, 0.03, 7.6), Vector3(-2.4 + k * 2.0, 0.3 + k * 0.42, 0), track._glow(Color("ffd23a"), 3.0)).rotation.z = 0.21
		add_child(ramp)
		_fixed.append({"s": float(rs), "node": ramp, "kind": "ramp"})


## Things on the road: boost strips, Star Chips and slow cargo haulers.
func _spawn_thing(x: float) -> void:
	var roll := _rng.randf()
	var kind := "boost" if roll < 0.35 else ("chip" if roll < 0.75 else "hauler")
	if _race in ["count", "on"] and kind == "chip":
		kind = "boost"
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
	_zone_l = UITheme.label("", 22, Color("ff8a3a"), UITheme.semi_font())
	_zone_l.position = Vector2(50, 84)
	root.add_child(_zone_l)
	_info = UITheme.label("", 19, UITheme.TEXT_DIM)
	_info.position = Vector2(50, 114)
	root.add_child(_info)
	_prompt = UITheme.label("", 30, UITheme.GOLD, UITheme.title_font())
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -700
	_prompt.offset_right = 700
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_prompt)
	_big = UITheme.label("", 150, Color.WHITE, UITheme.title_font())
	_big.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_big.offset_left = -700
	_big.offset_right = 700
	_big.offset_top = -220
	_big.offset_bottom = 0
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_big)
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
	_radar.offset_left = -330
	_radar.offset_right = 620
	_radar.offset_top = 30
	_radar.offset_bottom = 120
	_radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radar.draw.connect(_draw_radar)
	root.add_child(_radar)
	var help := UITheme.label("W / S  throttle and brake     A / D  steer     E  duel a rider / take an exit     R  race at the start line     Esc  menu", 17, UITheme.TEXT_DIM)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.offset_left = 48
	help.offset_top = -52
	help.offset_bottom = -22
	help.offset_right = 1400
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


## The whole ring as a strip: its stretches, the start line, exits, ramps, you and the riders.
func _draw_radar() -> void:
	var w := _radar.size.x
	var font := UITheme.semi_font()
	var cols := {"satellite": Color("ff8a3a"), "tunnel": Color("8a8f9c"), "bridge": Color("5affd0"), "tops": Color("7cc4ff")}
	for zn in ZONES:
		var x0: float = float(zn[0]) / LAP * w
		var x1: float = float(zn[1]) / LAP * w
		_radar.draw_rect(Rect2(x0, 40, x1 - x0 - 2.0, 7), Color(cols[zn[2]], 0.55))
	_radar.draw_rect(Rect2(0, 34, 3, 19), Color.WHITE)
	for e in EXITS:
		var ex: float = float(e["s"]) / LAP * w
		_radar.draw_rect(Rect2(ex - 1.5, 36, 3, 15), Color("5aff90"))
		_radar.draw_string(font, Vector2(ex - 16, 30), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("5aff90"))
	for rs in RAMPS:
		_radar.draw_circle(Vector2(float(rs) / LAP * w, 43.5), 3.0, Color("ffd23a"))
	for r in _riders:
		var rs2: float = fposmod(_s + float(r["x"]), LAP)
		var key := str(r["info"]["key"])
		var col := Color("5affa0") if _beaten.has(key) else Color("ffd166")
		var px := rs2 / LAP * w
		_radar.draw_circle(Vector2(px, 43.5), 6.0, col)
		var short := str(Characters.get_char(key).get("short", key))
		var ts := font.get_string_size(short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		_radar.draw_string(font, Vector2(px - ts.x / 2.0, 70 if int(r["index"]) % 2 == 0 else 84), short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	var me := fposmod(_s, LAP) / LAP * w
	_radar.draw_circle(Vector2(me, 43.5), 9.0, Color.WHITE)
	_radar.draw_circle(Vector2(me, 43.5), 6.5, Profile.color())


func _zone_at(s: float) -> Array:
	var m := fposmod(s, LAP)
	for zn in ZONES:
		if m >= float(zn[0]) and m < float(zn[1]):
			return zn
	return ZONES[0]


func _apply_zone() -> void:
	var zn := _zone_at(_s)
	if track.zone != str(zn[2]):
		track.set_zone(str(zn[2]))
		Sfx.play("whoosh", -6.0, 0.8)
	if _zone_l:
		_zone_l.text = Loc.t(str(zn[3]))


## How hard the ring bends here: positive pushes you toward the left edge.
func _curve_at(s: float) -> float:
	var m := fposmod(s, LAP) / LAP
	return sin(m * TAU * 3.0) * 0.55 + sin(m * TAU * 7.0 + 1.3) * 0.2


func _place_camera(w: float) -> void:
	var c := _curve_at(_s)
	var want := Vector3(-7.4 - _speed * 0.03, 3.1 + _y * 0.6, _z * 0.82 + c * 1.6)
	_cam.position = _cam.position.lerp(want, w)
	_cam.look_at(Vector3(9.0, 1.1 + _y * 0.5, _z * 0.9 - c * 5.0), Vector3.UP)
	_cam.rotation.z = lerpf(_cam.rotation.z, -c * 0.11, clampf(w, 0.0, 1.0))
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
	if _test_on:
		throttle = 1.0
		steer = clampf((_test_z - _z) * 0.6, -1.0, 1.0)
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
	if _race == "count":
		goal = 0.0
		_speed = move_toward(_speed, 0.0, delta * 60.0)
	_speed = move_toward(_speed, goal, delta * (30.0 if _boost > 0.0 else (14.0 if goal > _speed else 22.0)))
	# The ring bends: the faster you go, the harder it carries you to the outside.
	var c := _curve_at(_s)
	var airborne := _y > 0.02
	_vz = lerpf(_vz, steer * (11.0 if not airborne else 4.0) - c * _speed * 0.05, clampf(delta * 6.0, 0.0, 1.0))
	_z = clampf(_z + _vz * delta, -LANE * 2.5, LANE * 2.5)
	if absf(_z) >= LANE * 2.48 and _speed > 30.0:
		_speed -= delta * 14.0      # scraping the barrier
	# Ramps and gravity.
	if airborne or _vy > 0.0:
		_vy -= 22.0 * delta
		_y += _vy * delta
		if _y <= 0.0:
			_y = 0.0
			_vy = 0.0
			Sfx.play("impact", -8.0, 1.3)
	_s += _speed * delta
	_dist += _speed * delta
	track.curve = c
	track.target_speed = _speed
	track.speed = lerpf(track.speed, _speed, clampf(delta * 6.0, 0.0, 1.0))
	track.place_rider(0, Vector3(0, _y, _z), -_vz * 0.035)
	_apply_zone()
	_tick_race(delta)
	# Other riders hold their own pace and wander between lanes.
	_near = -1
	var best := 99.0
	for r in _riders:
		var info: Dictionary = r["info"]
		var pace := float(info["pace"])
		if _race == "count":
			pace = _speed
		elif _race == "on":
			# Racing: their own top speed, easing off a little when far ahead, pushing when behind.
			pace = float(info["race"]) + clampf(-float(r["x"]) * 0.02, -3.0, 3.5)
			r["race_d"] = float(r["race_d"]) + pace * delta
		r["x"] = float(r["x"]) + (pace - _speed) * delta
		if _race == "":
			if float(r["x"]) > LAP / 2.0:
				r["x"] = float(r["x"]) - LAP
			elif float(r["x"]) < -LAP / 2.0:
				r["x"] = float(r["x"]) + LAP
		r["lane_t"] = float(r["lane_t"]) + delta
		var want_z: float = LANE * float(int(float(r["lane_t"]) / 7.0 + int(r["index"])) % 5 - 2)
		var before: float = r["z"]
		r["z"] = move_toward(before, want_z, delta * 2.2)
		track.place_rider(int(r["index"]), Vector3(clampf(float(r["x"]), -400.0, 400.0), 0, float(r["z"])), -(float(r["z"]) - before) / maxf(delta, 0.001) * 0.035)
		var d := Vector2(float(r["x"]), float(r["z"]) - _z).length()
		if _race == "" and absf(float(r["x"])) < 7.0 and absf(float(r["z"]) - _z) < LANE * 1.4 and d < best:
			best = d
			_near = _riders.find(r)
	# Ring furniture slides past at its own place on the loop.
	_exit = -1
	for fx in _fixed:
		var rel := fposmod(float(fx["s"]) - _s + LAP / 2.0, LAP) - LAP / 2.0
		var node: Node3D = fx["node"]
		node.visible = absf(rel) < 220.0
		node.position.x = rel
		if fx["kind"] == "ramp" and absf(rel) < 3.6 and absf(_z) < 3.6 and _y < 0.3 and _speed > 24.0:
			_vy = 6.5 + _speed * 0.09
			_y = 0.31
			Sfx.play("whoosh", -2.0, 1.5)
			Collection.dp += 5
		elif fx["kind"] == "exit" and rel > -70.0 and rel < 60.0 and _z > LANE * 1.55 and _race == "":
			_exit = EXITS.find(EXITS.filter(func(e): return is_equal_approx(float(e["s"]), float(fx["s"])))[0])
	# Things on the road.
	for th in _things:
		th["x"] = float(th["x"]) - (_speed - (14.0 if th["kind"] == "hauler" else 0.0)) * delta
		var tnode: Node3D = th["node"]
		tnode.position = Vector3(float(th["x"]), 0, float(th["z"]))
		if th["kind"] == "chip":
			tnode.rotation.y += delta * 3.0
		if float(th["x"]) < -40.0:
			_recycle(th)
			continue
		var hit_x := 3.6 if th["kind"] != "chip" else 1.6
		if _y < 1.2 and absf(float(th["x"])) < hit_x and absf(float(th["z"]) - _z) < (1.9 if th["kind"] == "hauler" else 1.7):
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
	# Prompts.
	var at_start := fposmod(_s, LAP) > LAP - 90.0 or fposmod(_s, LAP) < 12.0
	if _race == "on":
		_prompt.text = ""
	elif _exit >= 0:
		_prompt.text = Loc.t("E   Take the exit to %s") % Loc.t(str(EXITS[_exit]["name"]))
	elif _near >= 0:
		var key := str(_riders[_near]["info"]["key"])
		_prompt.text = Loc.t("E   Turbo Duel with %s") % str(Characters.get_char(key).get("name", key))
	elif at_start and _race == "":
		_prompt.text = Loc.t("R   Start a race: one lap against every rider")
	else:
		_prompt.text = ""
	if _race == "on":
		_info.text = Loc.t("RACE     Position %d / %d     %d m to go     %s") % [_position(), _riders.size() + 1, int(maxf(0.0, LAP - _race_d)), _clock(_race_t)]
	else:
		_info.text = Loc.t("Riders beaten %d / %d     Star Chips %d     Races won %d     Best lap %s") % [_beaten.size(), RIVALS.size(), _chips, _wins, _clock(_best) if _best > 0.0 else "--"]
	_gauge.queue_redraw()
	_radar.queue_redraw()


func _clock(t: float) -> String:
	return "%d:%04.1f" % [int(t) / 60, fmod(t, 60.0)]


func _position() -> int:
	var ahead := 1
	for r in _riders:
		if float(r["race_d"]) > _race_d:
			ahead += 1
	return ahead


# ------------------------------------------------------------------ racing

func _start_race() -> void:
	if _race != "":
		return
	_race = "count"
	_count = 3.99
	_race_d = 0.0
	_race_t = 0.0
	# Line everyone up on the grid just behind the line.
	_s = 0.0
	_z = 0.0
	var i := 0
	for r in _riders:
		r["x"] = 6.0 + i * 5.0 if i % 2 == 0 else -6.0 - i * 5.0
		r["x"] = -4.0 - float(i) * 5.5
		r["z"] = LANE * float((i % 5) - 2)
		r["race_d"] = float(r["x"])
		i += 1
	Music.play("duel_tense")
	Sfx.play("gong", -3.0)


func _tick_race(delta: float) -> void:
	if _race == "count":
		var before := int(_count)
		_count -= delta
		if int(_count) != before or _big.text == "":
			_big.text = str(maxi(1, int(_count))) if _count >= 1.0 else Loc.t("GO!")
			_big.add_theme_color_override("font_color", Color("ffd166") if _count >= 1.0 else Color("5aff90"))
			Sfx.play("phase" if _count >= 1.0 else "special", -2.0)
		if _count < 1.0:
			_race = "on"
			_boost = 1.2
			get_tree().create_timer(0.9).timeout.connect(func(): _big.text = "")
	elif _race == "on":
		_race_t += delta
		_race_d += _speed * delta
		if _race_d >= LAP:
			_finish_race()


func _finish_race() -> void:
	var pos := _position()
	_race = "done"
	var prize: int = [600, 300, 150, 60, 40, 20][clampi(pos - 1, 0, 5)]
	Collection.dp += prize
	Collection.save()
	if pos == 1:
		_wins += 1
	if _best <= 0.0 or _race_t < _best:
		_best = _race_t
	_save()
	_big.text = [Loc.t("1ST!"), Loc.t("2ND"), Loc.t("3RD")][pos - 1] if pos <= 3 else Loc.t("%dTH") % pos
	_big.add_theme_color_override("font_color", Color("ffd166") if pos == 1 else Color.WHITE)
	Sfx.play("win" if pos <= 3 else "lose")
	if pos == 1:
		Sfx.play("cheer", -4.0)
	Music.play("victory" if pos == 1 else "turbo")
	Router.toast(Loc.t("Lap %s.   +%d Duel Points") % [_clock(_race_t), prize])
	await get_tree().create_timer(3.5).timeout
	_big.text = ""
	_race = ""
	Music.play("turbo")
	for r in _riders:
		r["x"] = fposmod(float(r["x"]) + LAP / 2.0, LAP) - LAP / 2.0


func _recycle(th: Dictionary) -> void:
	(th["node"] as Node3D).queue_free()
	_things.erase(th)
	_spawn_thing(_rng.randf_range(150.0, 260.0))


func _challenge() -> void:
	if _exit >= 0:
		_take_exit()
		return
	if _near < 0:
		return
	var info: Dictionary = _riders[_near]["info"]
	var key := str(info["key"])
	_paused = true
	Sfx.play("gong", -3.0)
	Router.toast(str(info["line"]))
	Router.roam["turbo_rival"] = key
	Router.roam["ride_s"] = _s
	var deck := str(info["deck"])
	if not CardData.has_deck(deck):
		deck = ["yusei", "jaden", "kaiba", "yugi", "joey"][absi(key.hash()) % 5]
	Router.match_state = {}
	Router.duel_config = {
		"opponent": key, "opponent_deck": deck, "player_deck": Collection.active_deck(), "player_char": "player",
		"difficulty": int(info["difficulty"]), "turbo": true, "story": true, "lose_ok": true, "return_to": Router.RIDE,
		"continue_label": Loc.t("Back to the highway"),
	}
	await get_tree().create_timer(1.1).timeout
	Router.go(Router.DUEL)


## Down the ramp into a city.
## Rides a full race lap on autopilot and then leaves by the first exit, printing what happened.
func _self_test() -> void:
	_test_on = true
	Engine.time_scale = 8.0
	await get_tree().create_timer(1.0).timeout
	var zones := {}
	_start_race()
	var jumps := 0
	var guard := 0.0
	while _race != "done" and guard < 400.0:
		await get_tree().process_frame
		guard += get_process_delta_time()
		zones[track.zone] = true
		if _y > 0.5:
			jumps += 1
		_test_z = sin(_t * 0.7) * 3.0
	print("RIDE race: state=%s position=%d time=%s zones=%s airborne_frames=%d" % [_race, _position(), _clock(_race_t), str(zones.keys()), jumps])
	while _race != "":
		await get_tree().process_frame
	_test_z = LANE * 2.2
	guard = 0.0
	while _exit < 0 and guard < 400.0:
		await get_tree().process_frame
		guard += get_process_delta_time()
	print("RIDE exit: index=%d at s=%d prompt=%s" % [_exit, int(fposmod(_s, LAP)), _prompt.text])
	Engine.time_scale = 1.0
	if _exit >= 0:
		_take_exit()
		await get_tree().create_timer(2.0).timeout
		print("RIDE arrived: district=", Router.roam.get("district", ""))


func _take_exit() -> void:
	var e: Dictionary = EXITS[_exit]
	_paused = true
	Sfx.play("whoosh", -2.0, 0.7)
	Sfx.ambience("")
	Pad.walk_mode = false
	Router.toast(Loc.t("Exit: %s") % Loc.t(str(e["name"])))
	Router.roam.erase("ride_s")
	Router.roam["district"] = str(e["to"])
	Router.roam["pos"] = null
	Router.roam.erase("yaw")
	Router.roam.erase("tod")
	Router.go(Router.ROAM)


func _unhandled_input(event: InputEvent) -> void:
	if _paused:
		return
	var pad: bool = event is InputEventJoypadButton and event.pressed
	if event.is_action_pressed("ui_cancel"):
		_paused = true
		Sfx.ambience("")
		Pad.walk_mode = false
		Router.roam.erase("ride_s")
		Router.go(Router.MAIN_MENU)
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R) or (pad and event.button_index == JOY_BUTTON_X):
		var m := fposmod(_s, LAP)
		if _race == "" and (m > LAP - 90.0 or m < 12.0):
			_start_race()
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E) or event.is_action_pressed("ui_accept"):
		if _race == "":
			_challenge()
