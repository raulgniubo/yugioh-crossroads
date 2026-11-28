extends Node3D
## The New Domino Highway ring: one loop from Satellite through a tunnel, over the bay bridge
## and past the Tops, with exits down to both cities. Steer between lanes, hit boost strips
## and jump ramps, grab Star Chips, dodge the haulers, pull alongside a rider for a Turbo
## Duel, or line up at the start flag and race everyone for a lap.

static var SAVE := Saves.u("turbo.cfg")
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
	{"key": "trudge", "deck": "trudge", "difficulty": 1, "pace": 33.0, "race": 40.0, "line": "Sector Security! Pull over! ...After this duel."},
	{"key": "sherry", "deck": "sherry", "difficulty": 2, "pace": 40.0, "race": 44.0, "line": "Keep your eyes on the road. I will be gone before you blink."},
	{"key": "dragan", "deck": "dragan", "difficulty": 2, "pace": 39.0, "race": 43.5, "line": "Full throttle! Thunder rides with me!"},
	{"key": "broder", "deck": "broder", "difficulty": 2, "pace": 41.0, "race": 44.5, "line": "Catch me if you can. You cannot."},
	{"key": "halldor", "deck": "halldor", "difficulty": 3, "pace": 45.0, "race": 46.5, "line": "The road is long and cold. Ride it with honor."},
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
var _blur: SpeedBlur
var _combo := 0               # boost pads chained without a gap
var _combo_t := 0.0
var _lines: SpeedLines
var _pop_l: Label
var _draft := 0.0             # seconds spent tucked in behind another rider
var _flame: MeshInstance3D
var _test_on := false         # --ride-test: an autopilot rides a race lap, then takes an exit
var _test_z := 0.0
var _race := ""               # "", "count", "on", "done"
var _mode := "circuit"        # which event is being raced: circuit, sprint, elim, trial
var _race_len := LAP
var _elim_t := 0.0            # elimination: seconds until the last rider is put out
var _medals := {}             # time trial medals already paid: {"bronze": true, ...}
var _trial_best := 0.0
var _ghost := PackedFloat32Array()        # your best time-trial lap: distance and lane, ten times a second
var _ghost_rec := PackedFloat32Array()
var _ghost_node: Node3D
var _mom := 0.0               # Momentum, 0 to 100: how well you have been riding
var _mom_ui: Control
var _events_best := {}        # best place per event
var _race_d := 0.0
var _race_t := 0.0
var _count := 0.0
var _eye := ""                # dev: --ride-eye, a fixed camera offset for a picture
var _env: Environment
var _tuck_test := "--ride-tuck" in OS.get_cmdline_user_args()      # dev: always tucked in, for a picture


func _ready() -> void:
	_rng.randomize()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		_beaten = cfg.get_value("turbo", "beaten", {})
		_chips = int(cfg.get_value("turbo", "chips", 0))
		_best = float(cfg.get_value("turbo", "best", 0.0))
		_wins = int(cfg.get_value("turbo", "wins", 0))
		_medals = cfg.get_value("turbo", "medals", {})
		_trial_best = float(cfg.get_value("turbo", "trial_best", 0.0))
		_ghost = cfg.get_value("turbo", "ghost", PackedFloat32Array())
		_events_best = cfg.get_value("turbo", "events_best", {})
	_mom = float(Router.roam.get("ride_mom", 0.0))
	TurboGarage.load_data()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--garage-set="):
			# Dev, e.g. --garage-set=paint:3,trail:5,mark:1,frame:1
			for kv in a.trim_prefix("--garage-set=").split(","):
				TurboGarage.data[kv.get_slice(":", 0)] = int(kv.get_slice(":", 1))
	# Where you come onto the ring.
	var from := str(Router.roam.get("ride_from", ""))
	_s = float(Router.roam.get("ride_s", {"satellite": 262.0, "newdomino": 1912.0}.get(from, 40.0)))
	Router.roam["ride_from"] = ""
	if from != "":
		Router.roam["ride_gate"] = false     # (came on from a city's ramp, not from the Turbo screen)
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
	# Back from a Grand Prix duel: settle the round and show the bracket.
	Tournament.load_data()
	if str(Router.roam.get("tourney", "")) == "turbo" and Router.story_result != "":
		var gp_won := Router.story_result == "won"
		Router.story_result = ""
		Router.roam["tourney"] = ""
		came_back = true
		var res := Tournament.resolve("turbo", gp_won)
		print("GP back won=", gp_won, " stage=", Tournament.st("turbo")["stage"], " next=", Tournament.my_match("turbo").get("name", "-"))
		_gp_panel.call_deferred(res)
	Music.play("turbo")
	Sfx.ambience("engine", -14.0)
	Pad.walk_mode = true
	Pad.hint("RT  throttle     LT  brake     X  race events     Back  garage")
	if "--ride-test" in OS.get_cmdline_user_args():
		_self_test.call_deferred()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ride-at="):
			# Dev: start at this point of the lap with the throttle held, for a picture of a zone.
			_s = float(a.trim_prefix("--ride-at="))
			_apply_zone()
			Input.action_press("ui_up")
	for a in OS.get_cmdline_user_args():
		# Dev: straight into the garage, the events board or an event, for a picture.
		if a == "--garage":
			get_tree().create_timer(2.0).timeout.connect(_garage_panel)
		elif a == "--events":
			get_tree().create_timer(2.0).timeout.connect(_events_panel)
		elif a == "--corner-test":
			# Dev (0.74.1): race the first rival to the first corner with the throttle held.
			Input.action_press("ui_up")
			get_tree().create_timer(2.0).timeout.connect(func():
				_near = 0
				_challenge())
		elif a == "--race-test":
			_test_on = true
			Engine.time_scale = 8.0
		elif a.begins_with("--race="):
			get_tree().create_timer(1.0).timeout.connect(_start_race.bind(a.trim_prefix("--race=")))
		elif a.begins_with("--momentum="):
			_mom = float(a.trim_prefix("--momentum="))
		elif a == "--no-ui":
			# Dev: a clean picture of the road (the Turbo screen's backdrop): no HUD, no toasts.
			get_tree().create_timer(0.3).timeout.connect(func():
				for layer in get_tree().root.find_children("*", "CanvasLayer", true, false):
					(layer as CanvasLayer).visible = false)
		elif a.begins_with("--ride-eye="):
			# Dev: hold the camera at an offset from your runner (x ahead, y up, z across), looking at it.
			_eye = a.trim_prefix("--ride-eye=")
	if "--traffic-show" in OS.get_cmdline_user_args():
		# Dev: the four kinds of traffic lined up ahead, keeping pace, for a picture.
		for k in TRAFFIC.size():
			var tn := Node3D.new()
			var tsize := _vehicle(tn, TRAFFIC[k])
			add_child(tn)
			_things.append({"kind": "hauler", "node": tn, "x": 7.0 + k * 10.0, "z": LANE * (1.0 if k % 2 == 0 else -1.0), "hx": tsize.x / 2.0, "hz": 0.1, "v": 46.0, "pin": true})
	if "--gp" in OS.get_cmdline_user_args() and not came_back:
		_test_on = true
		Engine.time_scale = 8.0
		Tournament.register("turbo")
		Tournament.start_finals("turbo")
		_gp = true
		_start_race.call_deferred()
	elif "--gp" in OS.get_cmdline_user_args():
		get_tree().create_timer(1.0).timeout.connect(get_tree().quit)
	# From the Turbo screen: straight to the thing picked there (an event at the line, the Grand
	# Prix, the garage, or a rider just up the road).
	var go := str(Router.roam.get("ride_go", ""))
	Router.roam["ride_go"] = ""
	if go != "" and not came_back:
		_ride_go.call_deferred(go)
	elif not came_back:
		Router.toast.call_deferred("The highway ring. Pull alongside a rider and press E to duel, or take an exit lane down to a city.")


## What the Turbo screen asked for: "race:<event>", "gp", "garage" or "rider:<key>".
func _ride_go(go: String) -> void:
	await get_tree().create_timer(0.8).timeout
	print("RIDE GO ", go)
	if go.begins_with("race:"):
		var id := go.trim_prefix("race:")
		if EVENTS.has(id):
			Router.toast(Loc.t("%s: get ready at the line.") % Loc.t(str(EVENTS[id]["name"])))
			_start_race(id)
	elif go == "gp":
		_s = 0.0
		_gp_key()
	elif go == "garage":
		_garage_panel()
	elif go.begins_with("rider:"):
		var key := go.trim_prefix("rider:")
		for r in _riders:
			if str(r["info"]["key"]) == key:
				# Put them a little way up the road in your lane, riding easy, so you can catch them.
				r["x"] = 26.0
				r["z"] = _z
				var nm := str(Characters.get_char(key).get("name", key))
				Router.toast(Loc.t("%s is just up the road. Pull alongside and press E for a Turbo Duel.") % nm)
				print("RIDE GO rider placed ", key, " lane ", snappedf(_z, 0.1))
				break


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE)             # the garage keeps its things in the same file
	cfg.set_value("turbo", "medals", _medals)
	cfg.set_value("turbo", "trial_best", _trial_best)
	cfg.set_value("turbo", "ghost", _ghost)
	cfg.set_value("turbo", "events_best", _events_best)
	cfg.set_value("turbo", "beaten", _beaten)
	cfg.set_value("turbo", "chips", _chips)
	cfg.set_value("turbo", "best", _best)
	cfg.set_value("turbo", "wins", _wins)
	cfg.save(SAVE)


func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	_env = env
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
	track.trail_scale = 0.4        # the camera sits close behind: a long trail would fill the picture
	track.add_rider(0, "player", Vector3.ZERO, TurboGarage.paint(Profile.color()), _my_look())
	track.place_rider(0, Vector3.ZERO)
	var i := 1
	for r in RIVALS:
		var info: Dictionary = r
		var col: Color = Characters.get_char(str(info["key"])).get("color", Color.WHITE)
		track.add_rider(i, str(info["key"]), Vector3(40.0 * i, 0, 0), col)
		track.engine_on(i, 0.78 + 0.07 * float(i), -5.0)      # (0.74.1) you hear them come up and go past
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
	PerfPass.settle(self)      # no two surfaces left lying on top of each other (flicker)
	_cam = Camera3D.new()
	_cam.fov = 68.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.current = true
	_apply_zone()
	_place_camera(1.0)
	# (0.74.0) The hour and the weather: picked once when you come onto the highway and kept
	# while you go in and out of duels on it.
	var w: Dictionary = Router.roam.get("ride_weather", {})
	if w.is_empty():
		w = {"mood": ["dusk", "dusk", "night", "dawn"][_rng.randi() % 4], "rain": _rng.randf() < 0.3}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--weather="):
			w = {"mood": a.trim_prefix("--weather=").get_slice(",", 0), "rain": "rain" in a}
	Router.roam["ride_weather"] = w
	track.set_weather(str(w["mood"]), bool(w["rain"]), _cam)
	if bool(w["rain"]):
		_env.fog_density = 0.011
		_env.fog_light_color = Color("1a1c26")
	elif str(w["mood"]) == "dawn":
		_env.fog_light_color = Color("3a3650")
		_env.ambient_light_energy = 0.75


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
	# Where a Sprint ends: a light gate that only stands while one is being ridden.
	var gate := Node3D.new()
	for sz: float in [-1.0, 1.0]:
		track._box(gate, Vector3(0.6, 8.0, 0.6), Vector3(0, 4.0, sz * 14.0), track._solid(Color(0.1, 0.11, 0.15)))
		track._box(gate, Vector3(0.14, 7.6, 0.14), Vector3(-0.4, 4.0, sz * 13.6), track._glow(Color("5aff90"), 4.0))
	track._box(gate, Vector3(0.6, 1.6, 28.6), Vector3(0, 8.2, 0), track._solid(Color(0.06, 0.07, 0.1)))
	track._box(gate, Vector3(0.12, 0.14, 27.6), Vector3(-0.4, 7.3, 0), track._glow(Color("5aff90"), 4.5))
	for k in 24:
		track._box(gate, Vector3(1.2, 0.02, 1.2), Vector3((0.6 if k % 2 == 0 else -0.6), 0.02, -13.8 + k * 1.2), track._glow(Color.WHITE, 0.9))
	var gl := Label3D.new()
	gl.text = "SPRINT  ·  FINISH"
	gl.font_size = 130
	gl.pixel_size = 0.011
	gl.modulate = Color("5aff90")
	gl.position = Vector3(-0.4, 8.2, 0)
	gl.rotation.y = -PI / 2
	gate.add_child(gl)
	add_child(gate)
	_fixed.append({"s": SPRINT_LEN, "node": gate, "kind": "sprint"})
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


## What else is on the highway. `len` is how long it stands on the road, `v` how fast it goes.
const TRAFFIC := [
	{"file": "truck", "len": 11.0, "v": 14.0},
	{"file": "bus", "len": 10.5, "v": 16.0},
	{"file": "van", "len": 4.7, "v": 19.0},
	{"file": "car", "len": 4.4, "v": 22.0},
]
static var _traffic_ps := {}


## One vehicle, standing on the road with its nose down the way you ride. Returns its size.
func _vehicle(node: Node3D, pick: Dictionary) -> Vector3:
	var file := str(pick["file"])
	if not _traffic_ps.has(file):
		_traffic_ps[file] = load("res://assets/models/vehicles/traffic_%s.glb" % file)
	var want := float(pick["len"])
	var size := Vector3(want, 2.6, 2.2)
	var ps = _traffic_ps[file]
	if ps is PackedScene:
		var model: Node3D = ps.instantiate()
		node.add_child(model)
		var box := track._aabb(model, Transform3D())
		var k := want / maxf(0.01, box.size.x)
		model.scale = Vector3.ONE * k
		model.rotation.y = TRAFFIC_TURN
		model.position = Vector3(-box.get_center().x * k * cos(TRAFFIC_TURN), -box.position.y * k, box.get_center().z * k)
		size = box.size * k
		# (0.74.0) Not every car on the road is the same white one: a coat of paint each, and a
		# slightly different size. (An overlay, so the model and its texture stay shared.)
		var paint: Color = CAR_PAINTS[_rng.randi() % CAR_PAINTS.size()]
		if paint.a > 0.0:
			var coat := StandardMaterial3D.new()
			coat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			coat.albedo_color = paint
			coat.metallic = 0.7
			coat.roughness = 0.3
			for mi in model.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_overlay = coat
		model.scale *= _rng.randf_range(0.94, 1.06)
	else:
		track._box(node, size, Vector3(0, size.y / 2.0, 0), track._solid(Color(0.3, 0.32, 0.36)))
	# Tail lights you can read from far back, their glow on the road, and headlights ahead.
	for sz: float in [-1.0, 1.0]:
		track._box(node, Vector3(0.06, 0.16, size.z * 0.2), Vector3(-size.x / 2.0 - 0.02, size.y * 0.3, sz * size.z * 0.33), track._glow(Color("ff2a2a"), 4.5))
		track._box(node, Vector3(0.06, 0.14, size.z * 0.16), Vector3(size.x / 2.0 + 0.02, size.y * 0.26, sz * size.z * 0.33), track._glow(Color(1.0, 0.96, 0.85), 4.0))
	var pool := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(5.0, size.z + 1.2)
	pool.mesh = qm
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.albedo_color = Color(1.0, 0.12, 0.1, 0.28)
	pm.albedo_texture = track._puff()
	pool.material_override = pm
	pool.rotation.x = -PI / 2.0
	pool.position = Vector3(-size.x / 2.0 - 1.8, 0.04, 0)
	node.add_child(pool)
	var tail := OmniLight3D.new()
	tail.light_color = Color(1.0, 0.25, 0.2)
	tail.light_energy = 1.6
	tail.omni_range = 5.0
	tail.position = Vector3(-size.x / 2.0 - 0.8, 0.9, 0)
	node.add_child(tail)
	return size


const TRAFFIC_TURN := PI      # the models are built nose toward -X
const CAR_PAINTS := [Color(0, 0, 0, 0), Color(0.08, 0.09, 0.11, 0.62), Color(0.55, 0.06, 0.07, 0.5), Color(0.06, 0.2, 0.5, 0.5),
	Color(0.6, 0.6, 0.62, 0.4), Color(0.75, 0.5, 0.08, 0.45), Color(0.05, 0.3, 0.22, 0.5), Color(0.3, 0.06, 0.32, 0.45)]


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
			var pick: Dictionary = TRAFFIC[_rng.randi() % TRAFFIC.size()]
			if "--traffic=" in " ".join(OS.get_cmdline_user_args()):
				for a in OS.get_cmdline_user_args():
					if a.begins_with("--traffic="):
						pick = TRAFFIC[int(a.trim_prefix("--traffic=")) % TRAFFIC.size()]
			var size := _vehicle(node, pick)
			add_child(node)
			_things.append({"kind": kind, "node": node, "x": x, "z": z, "hx": size.x / 2.0 + 0.9, "hz": size.z / 2.0 + 0.55, "v": float(pick["v"])})
			return
	add_child(node)
	_things.append({"kind": kind, "node": node, "x": x, "z": z})


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	_blur = SpeedBlur.new()
	_ui.add_child(_blur)
	_lines = SpeedLines.new()
	_ui.add_child(_lines)
	_pop_l = UITheme.label("", 44, Color("5affd0"), UITheme.title_font())
	_pop_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_pop_l.add_theme_constant_override("outline_size", 10)
	_pop_l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pop_l.offset_top = 210
	_pop_l.offset_left = -500
	_pop_l.offset_right = 500
	_pop_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pop_l.modulate.a = 0.0
	_pop_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_pop_l)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.build()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	# The place plate: on a dark glass card, so it reads over a bright sky or the moon.
	var plate := PanelContainer.new()
	plate.position = Vector2(30, 24)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb := UITheme.panel_box(Color(0.03, 0.045, 0.1, 0.78), 14, Color(1, 1, 1, 0.1))
	psb.content_margin_left = 20
	psb.content_margin_right = 22
	psb.content_margin_top = 10
	psb.content_margin_bottom = 12
	plate.add_theme_stylebox_override("panel", psb)
	root.add_child(plate)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 0)
	plate.add_child(pv)
	var title := UITheme.label("NEW DOMINO HIGHWAY", 38, Color.WHITE, UITheme.title_font())
	pv.add_child(title)
	_zone_l = UITheme.label("", 22, Color("ff8a3a"), UITheme.semi_font())
	pv.add_child(_zone_l)
	_info = UITheme.label("", 18, UITheme.TEXT_DIM)
	pv.add_child(_info)
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
	_mom_ui = Control.new()
	_mom_ui.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_mom_ui.offset_left = -470
	_mom_ui.offset_top = -378
	_mom_ui.offset_right = -40
	_mom_ui.offset_bottom = -292
	_mom_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mom_ui.draw.connect(_draw_momentum)
	root.add_child(_mom_ui)
	_radar = Control.new()
	_radar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_radar.offset_left = -140      # (right of the place plate, in any language)
	_radar.offset_right = 810
	_radar.offset_top = 30
	_radar.offset_bottom = 120
	_radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radar.draw.connect(_draw_radar)
	root.add_child(_radar)
	var help := UITheme.label("W / S  throttle and brake     A / D  steer     E  duel a rider / take an exit     R  race events at the start line     T  garage     Esc  menu", 17, Color(0.93, 0.95, 1.0, 0.95))
	# On a dark strip of its own, so the light trails on the road never run through it.
	var hb := PanelContainer.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.03, 0.05, 0.11, 0.72)
	hsb.set_corner_radius_all(8)
	hsb.content_margin_left = 16
	hsb.content_margin_right = 16
	hsb.content_margin_top = 6
	hsb.content_margin_bottom = 6
	hb.add_theme_stylebox_override("panel", hsb)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(help)
	hb.anchor_top = 1.0
	hb.anchor_bottom = 1.0
	hb.offset_left = 40
	hb.offset_top = -62
	hb.offset_bottom = -22
	hb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(hb)


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


## Momentum: how well you have been riding. It is what you carry into a Turbo Duel.
func _gain(amount: float) -> void:
	_mom = clampf(_mom + amount, 0.0, 100.0)


## What your Momentum is worth right now: [Speed Counters, do you take the first turn].
func _mom_worth() -> Array:
	return [mini(4, int(_mom / 25.0)), _mom >= 50.0]


func _draw_momentum() -> void:
	if _race != "":
		return
	var w := _mom_ui.size.x
	var font := UITheme.semi_font()
	var worth := _mom_worth()
	var col := Color("5affd0") if _mom >= 50.0 else Color("ffd166")
	_mom_ui.draw_string(UITheme.title_font(), Vector2(0, 20), Loc.t("MOMENTUM"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	var num := str(int(_mom))
	var ns := UITheme.title_font().get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	_mom_ui.draw_string(UITheme.title_font(), Vector2(w - ns.x, 20), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
	_mom_ui.draw_rect(Rect2(0, 30, w, 18), Color(0.02, 0.03, 0.06, 0.85))
	_mom_ui.draw_rect(Rect2(2, 32, (w - 4.0) * _mom / 100.0, 14), col)
	# A mark at every Speed Counter; the tall one in the middle is where the first turn becomes yours.
	for k in [1, 2, 3]:
		var x: float = w * float(k) / 4.0
		_mom_ui.draw_rect(Rect2(x - 1.0, 28 if k != 2 else 24, 2, 22 if k != 2 else 30), Color(1, 1, 1, 0.8))
	var txt := Loc.t("Duel now: %d Speed Counters, %s") % [int(worth[0]), Loc.t("you go first") if worth[1] else Loc.t("they go first")]
	_mom_ui.draw_string(font, Vector2(0, 74), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, col)


## How the garage left your runner.
func _my_look() -> Dictionary:
	var paint := TurboGarage.paint(Profile.color())
	return {"frame": TurboGarage.frame(), "trail": TurboGarage.trail(paint), "mark": TurboGarage.mark()}


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
		# Inside the tunnel the engine booms back off the walls.
		Sfx.ambience("tunnel" if "tunnel" in str(zn[2]) else "engine", -13.0 if "tunnel" in str(zn[2]) else -14.0)
	if _zone_l:
		_zone_l.text = Loc.t(str(zn[3]))


## How hard the ring bends here: positive pushes you toward the left edge.
func _curve_at(s: float) -> float:
	var m := fposmod(s, LAP) / LAP
	return sin(m * TAU * 3.0) * 0.55 + sin(m * TAU * 7.0 + 1.3) * 0.2


func _place_camera(w: float) -> void:
	var c := _curve_at(_s)
	if _eye != "":
		var e := _eye.split(",")
		_cam.position = Vector3(float(e[0]), float(e[1]), _z + float(e[2]))
		_cam.look_at(Vector3(float(e[3]) if e.size() > 3 else 0.0, 0.9, _z + (float(e[4]) if e.size() > 4 else 0.0)), Vector3.UP)
		_cam.fov = float(e[5]) if e.size() > 5 else 58.0
		return
	# Low and close behind the runner, the way a racing game sits: the runner fills a fifth of
	# the picture and the road rushes under the lens. The view drops back and widens with speed.
	var want := Vector3(-5.3 - _speed * 0.022, 2.05 + _y * 0.6, _z * 0.9 + c * 1.1)
	_cam.position = _cam.position.lerp(want, w)
	_cam.look_at(Vector3(11.0, 1.3 + _y * 0.5, _z * 0.95 - c * 5.0), Vector3.UP)
	_cam.rotation.z = lerpf(_cam.rotation.z, -c * 0.11 - _vz * 0.006, clampf(w, 0.0, 1.0))
	_cam.fov = lerpf(_cam.fov, minf(80.0, 62.0 + (_speed - 28.0) * 0.5 + (6.0 if _boost > 0.0 else 0.0)), clampf(w * 0.5, 0.0, 1.0))
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
	var top := (56.0 if _boost > 0.0 else 46.0) + TurboGarage.top_bonus()
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
	var grip := TurboGarage.grip()
	_vz = lerpf(_vz, steer * (11.0 * grip if not airborne else 4.0) - c * _speed * 0.05 / grip, clampf(delta * 6.0 * grip, 0.0, 1.0))
	_z = clampf(_z + _vz * delta, -LANE * 2.5, LANE * 2.5)
	var scraping := absf(_z) >= LANE * 2.48 and _speed > 30.0
	track.scrape(0, scraping)
	if scraping:
		_speed -= delta * 14.0      # scraping the barrier
		_gain(-delta * 9.0)
	# Momentum drains slowly by itself, faster if you crawl: it has to be kept up.
	if _race == "":
		_gain(-delta * (0.7 if _speed >= 30.0 else 3.0))
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
	if not _corner.is_empty():
		_corner_tick(delta)
	track.set_tuck(0, 1.0 if _boost > 0.0 or _tuck_test else clampf((_speed - 45.0) / 40.0, 0.0, 0.5))
	# Tail lights ahead, for the wet road to mirror.
	var lights: Array = []
	for th in _things:
		if str(th["kind"]) == "hauler" and float(th["x"]) > -12.0 and float(th["x"]) < 95.0 and lights.size() < 5:
			lights.append([Vector3(float(th["x"]) - float(th.get("hx", 3.0)) + 0.8, 0, float(th["z"])), Color(1.0, 0.18, 0.12), 1.5])
	track.set_lights(lights)
	_apply_zone()
	_tick_race(delta)
	# Other riders hold their own pace and wander between lanes.
	_near = -1
	var best := 99.0
	for r in _riders:
		var info: Dictionary = r["info"]
		var pace := float(info["pace"])
		var racing_me: bool = not _corner.is_empty() and _corner["r"] == r
		if racing_me:
			pace = _speed      # (racing you to the first corner: _corner_tick moves them)
		elif _race == "count":
			pace = _speed
		elif _race == "on":
			# Racing: their own top speed, easing off a little when far ahead, pushing when behind.
			pace = float(info["race"]) + clampf(-float(r["x"]) * 0.02, -3.0, 3.5)
			if r.get("out", false):
				pace = 18.0        # put out: they sit up and roll
			else:
				r["race_d"] = float(r["race_d"]) + pace * delta
		if _mode == "trial" and _race in ["count", "on", "done"]:
			r["x"] = -3000.0       # a time trial is ridden alone
		r["x"] = float(r["x"]) + (pace - _speed) * delta
		track.set_rev(int(r["index"]), pace / 50.0)
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
		node.visible = absf(rel) < 220.0 and (fx["kind"] != "sprint" or (_mode == "sprint" and _race != ""))
		node.position.x = rel
		if fx["kind"] == "ramp" and absf(rel) < 3.6 and absf(_z) < 3.6 and _y < 0.3 and _speed > 24.0:
			_vy = 6.5 + _speed * 0.09
			_y = 0.31
			Sfx.play("whoosh", -2.0, 1.5)
			_gain(5.0)
			Collection.dp += 5
		elif fx["kind"] == "exit" and rel > -70.0 and rel < 60.0 and _z > LANE * 1.55 and _race == "":
			_exit = EXITS.find(EXITS.filter(func(e): return is_equal_approx(float(e["s"]), float(fx["s"])))[0])
	# Things on the road.
	for th in _things:
		if not th.get("pin", false):
			th["x"] = float(th["x"]) - (_speed - float(th.get("v", 0.0))) * delta
		var tnode: Node3D = th["node"]
		tnode.position = Vector3(float(th["x"]), 0, float(th["z"]))
		if th["kind"] == "chip":
			tnode.rotation.y += delta * 3.0
		if float(th["x"]) < -40.0:
			_recycle(th)
			continue
		var hit_x: float = float(th.get("hx", 3.6 if th["kind"] != "chip" else 1.6))
		if _y < 1.2 and absf(float(th["x"])) < hit_x and absf(float(th["z"]) - _z) < float(th.get("hz", 1.7)):
			match str(th["kind"]):
				"boost":
					if _boost <= 0.0:
						Sfx.play("whoosh", -2.0, 1.3)
						Sfx.play("charge", -4.0, 1.4)
					# Chain pads without letting the boost run out and the chain pays more each time.
					if not th.get("hit", false):
						th["hit"] = true
						_combo = _combo + 1 if _combo_t > 0.0 else 1
						_combo_t = 4.5
						if _combo >= 2:
							Collection.dp += 5 * _combo
							Sfx.play("coin", -8.0, 1.0 + 0.1 * _combo)
							_pop(Loc.t("BOOST CHAIN x%d  +%d") % [_combo, 5 * _combo], Color("5affd0"))
					_boost = 2.6 + minf(1.2, 0.3 * _combo) + TurboGarage.boost_bonus()
					_gain(6.0 + 3.0 * minf(_combo, 4.0))
				"chip":
					_chips += 1
					Collection.dp += 15
					Collection.save()
					_save()
					Sfx.play_or("star_chip", "coin", -3.0)
					_gain(4.0)
					Router.toast(Loc.t("Star Chip!  +15 Duel Points  (%d on this road)") % _chips)
					_recycle(th)
				"hauler":
					if _stun <= 0.0:
						Sfx.play("impact", -2.0, 0.7)
						_stun = 1.2 * TurboGarage.crash()
						_gain(-28.0 * TurboGarage.crash())
						_boost = 0.0
						_speed = minf(_speed, 18.0)
						_z += signf(_z - float(th["z"]) + 0.01) * 2.4
	_tricks(delta)
	_place_camera(clampf(delta * 5.0, 0.0, 1.0))
	# Prompts.
	var at_start := fposmod(_s, LAP) > LAP - 90.0 or fposmod(_s, LAP) < 12.0
	if _race == "on":
		_prompt.text = ""
	elif _exit >= 0:
		_prompt.text = Pad.keys(Loc.t("E   Take the exit to %s") % Loc.t(str(EXITS[_exit]["name"])))
	elif _near >= 0:
		var key := str(_riders[_near]["info"]["key"])
		_prompt.text = Pad.keys(Loc.t("E   Turbo Duel with %s") % str(Characters.get_char(key).get("name", key)))
	elif at_start and _race == "":
		_prompt.text = Pad.keys(Loc.t("R   Race events        G   Highway Grand Prix        T   Garage"), {"R": "X", "G": "Y", "T": "Back"})
	else:
		_prompt.text = ""
	if _race == "on" and _mode == "trial":
		var gap := ""
		if _ghost.size() >= 4:
			var gi := clampi(int(_race_t * 10.0), 0, _ghost.size() / 2 - 1)
			var behind := (_ghost[gi * 2] - _race_d) / maxf(20.0, _speed)
			gap = "     " + (Loc.t("%.1f s behind your best") % behind if behind > 0.0 else Loc.t("%.1f s ahead of your best") % -behind)
		_info.text = Loc.t("TIME TRIAL     %s     %d m to go") % [_clock(_race_t), int(maxf(0.0, LAP - _race_d))] + gap
	elif _race == "on" and _mode == "elim":
		_info.text = Loc.t("ELIMINATION     Position %d / %d     Last place is out in %d s") % [_position(), _riding(), int(ceilf(_elim_t))]
	elif _race == "on":
		_info.text = Loc.t("%s     Position %d / %d     %d m to go     %s") % [Loc.t(str(EVENTS[_mode]["name"])).to_upper(), _position(), _riders.size() + 1, int(maxf(0.0, _race_len - _race_d)), _clock(_race_t)]
	else:
		_info.text = Loc.t("Riders beaten %d / %d     Star Chips %d     Races won %d     Best lap %s") % [_beaten.size(), RIVALS.size(), _chips, _wins, _clock(_best) if _best > 0.0 else "--"]
	_gauge.queue_redraw()
	_radar.queue_redraw()
	_mom_ui.queue_redraw()


## A short shout in the middle of the screen: SLIPSTREAM, NEAR MISS.
func _pop(text: String, col: Color) -> void:
	_pop_l.text = Loc.t(text)
	_pop_l.add_theme_color_override("font_color", col)
	_pop_l.modulate.a = 1.0
	_pop_l.scale = Vector2(1.3, 1.3)
	_pop_l.pivot_offset = Vector2(500, 30)
	var tw := _pop_l.create_tween()
	tw.tween_property(_pop_l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7)
	tw.tween_property(_pop_l, "modulate:a", 0.0, 0.3)


## Tucked in behind someone for a moment gives a free burst; so does shaving past a hauler.
func _tricks(delta: float) -> void:
	var drafting := false
	if _race != "count" and _y < 0.1:
		for r in _riders:
			var dx := float(r["x"])
			if dx > 2.0 and dx < 15.0 and absf(float(r["z"]) - _z) < 1.5:
				drafting = true
	_draft = _draft + delta if drafting else maxf(0.0, _draft - delta * 2.0)
	if _draft > 1.3:
		_draft = 0.0
		_boost = maxf(_boost, 1.8 + TurboGarage.boost_bonus())
		_gain(12.0)
		_lines.kick(0.7)
		Sfx.play("whoosh", -3.0, 1.4)
		_pop("SLIPSTREAM!", Color("5affd0"))
	for th in _things:
		if th["kind"] != "hauler" or th.get("missed", false):
			continue
		var gap := absf(float(th["z"]) - _z)
		if absf(float(th["x"])) < 3.0 and gap >= 1.9 and gap < 3.3 and _speed > 38.0 and _stun <= 0.0:
			th["missed"] = true
			_boost = maxf(_boost, 1.0)
			_gain(10.0)
			Collection.dp += 5
			_lines.kick(0.5)
			Sfx.play("coin", -8.0, 1.4)
			_pop("NEAR MISS  +5", Color("ffd23a"))
	# Exhaust flame while a boost is burning.
	if _flame == null and track.rider_node(0):
		_flame = MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.5, 2.2, 0.3)
		_flame.mesh = pm
		_flame.rotation.z = PI / 2.0
		_flame.position = Vector3(-2.2, 0.55, 0)
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		fm.albedo_color = Color(0.4, 1.0, 0.85, 0.9)
		_flame.material_override = fm
		track.rider_node(0).add_child(_flame)
	if _flame:
		_flame.visible = _boost > 0.0
		_flame.scale = Vector3(1.0 + sin(_t * 50.0) * 0.2, 0.8 + sin(_t * 37.0) * 0.25 + minf(_boost, 1.0) * 0.4, 1.0)
	# The picture only smears at the edges once you are properly fast; cruising stays sharp.
	_blur.amount = clampf((_speed - 40.0) / 30.0, 0.0, 0.4) + (0.3 if _boost > 0.0 else 0.0)
	_combo_t = maxf(0.0, _combo_t - delta)
	if _combo_t <= 0.0:
		_combo = 0
	# Passing a rider is worth a shout and a few points.
	if _race != "count":
		for r in _riders:
			var was: float = r.get("was_x", float(r["x"]))
			if was > 0.5 and float(r["x"]) <= 0.5 and absf(float(r["x"])) < 6.0 and _speed > 30.0:
				Collection.dp += 10
				_gain(8.0)
				_lines.kick(0.4)
				Sfx.play("whoosh", -5.0, 1.6)
				_pop("OVERTAKE  +10", Color("ff8a3a"))
			r["was_x"] = float(r["x"])
	# The engine note climbs with the speedometer and screams on a boost.
	Sfx.ambience_pitch(0.72 + _speed / 52.0 + (0.18 if _boost > 0.0 else 0.0) + sin(_t * 31.0) * 0.01)
	_lines.amount = clampf((_speed - 42.0) / 30.0, 0.0, 0.45) + (0.3 if _boost > 0.0 else 0.0) + (0.15 if drafting else 0.0)


func _clock(t: float) -> String:
	return "%d:%04.1f" % [int(t) / 60, fmod(t, 60.0)]


func _position() -> int:
	var ahead := 1
	for r in _riders:
		if not r.get("out", false) and float(r["race_d"]) > _race_d:
			ahead += 1
	return ahead


func _riding() -> int:
	var n := 1
	for r in _riders:
		if not r.get("out", false):
			n += 1
	return n


# ------------------------------------------------------------------ racing

const EVENTS := {
	"circuit": {"name": "Circuit", "what": "One full lap of the ring against every rider.", "prize": [600, 300, 150, 60, 40, 20]},
	"sprint": {"name": "Sprint", "what": "800 metres flat out from the line. Over in twenty seconds: the start decides it.", "prize": [250, 120, 60, 30, 20, 10]},
	"elim": {"name": "Elimination", "what": "Every 16 seconds the rider in last place is out. Be the last one riding.", "prize": [800, 350, 150, 60, 40, 20]},
	"trial": {"name": "Time Trial", "what": "The road to yourself and the clock. Your best lap rides with you as a ghost.", "prize": []},
}
const EVENT_ORDER := ["circuit", "sprint", "elim", "trial"]
const MEDALS := [["gold", 50.0, 600], ["silver", 55.0, 300], ["bronze", 62.0, 150]]
const SPRINT_LEN := 800.0


## The board at the start line: pick what to race.
func _events_panel() -> void:
	if _paused or _race != "":
		return
	_paused = true
	Input.action_release("ui_up")
	var p := SidePanel.new(Loc.t("RACE EVENTS"), 720.0)
	_ui.add_child(p)
	p.closed.connect(func(): _paused = false)
	var first_btn: Button = null
	for id in EVENT_ORDER:
		var ev: Dictionary = EVENTS[id]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		var b := Button.new()
		b.text = Loc.t(str(ev["name"]))
		b.custom_minimum_size = Vector2(0, 58)
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(func():
			p.queue_free()
			_paused = false
			_start_race(id))
		box.add_child(b)
		if first_btn == null:
			first_btn = b
		var what := UITheme.label(Loc.t(str(ev["what"])), 18, UITheme.TEXT_DIM)
		what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(what)
		var best := ""
		if id == "trial":
			var have: Array = []
			for m in MEDALS:
				have.append("%s %s%s" % [Loc.t(str(m[0]).capitalize()), _clock(float(m[1])), "  ✓" if _medals.has(m[0]) else ""])
			best = "   ·   ".join(have) + ("\n" + Loc.t("Your best: %s") % _clock(_trial_best) if _trial_best > 0.0 else "")
		else:
			var prize: Array = ev["prize"]
			best = Loc.t("First place pays %d Duel Points.") % int(prize[0])
			if _events_best.has(id):
				best += "   " + Loc.t("Your best finish: place %d.") % int(_events_best[id])
			if id == "circuit" and _best > 0.0:
				best += "   " + Loc.t("Best lap %s.") % _clock(_best)
		box.add_child(UITheme.label(best, 17, UITheme.GOLD))
		p.body.add_child(box)
	if first_btn:
		first_btn.grab_focus.call_deferred()


func _start_race(mode := "circuit") -> void:
	if _race != "" or not _corner.is_empty():
		return
	_mode = mode
	_race_len = SPRINT_LEN if mode == "sprint" else LAP
	_elim_t = 16.0
	_ghost_rec = PackedFloat32Array()
	for r in _riders:
		r["out"] = false
	if _ghost_node:
		_ghost_node.queue_free()
		_ghost_node = null
	if mode == "trial" and _ghost.size() >= 4:
		_ghost_node = track.ghost_runner(TurboGarage.frame(), Color("7cc4ff"))
	print("RIDE race start ", mode)
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
		var before_t := _race_t
		_race_t += delta
		_race_d += _speed * delta
		if _mode == "trial":
			# Write this lap down ten times a second, and move the ghost of the best one.
			if int(_race_t * 10.0) != int(before_t * 10.0):
				_ghost_rec.append(_race_d)
				_ghost_rec.append(_z)
			if _ghost_node:
				var gi := clampi(int(_race_t * 10.0), 0, _ghost.size() / 2 - 1)
				var gd: float = _ghost[gi * 2]
				if gi + 1 < _ghost.size() / 2:
					gd = lerpf(gd, _ghost[gi * 2 + 2], fposmod(_race_t * 10.0, 1.0))
				_ghost_node.position = Vector3(clampf(gd - _race_d, -200.0, 200.0), 0, _ghost[gi * 2 + 1])
				_ghost_node.visible = absf(gd - _race_d) < 190.0
		elif _mode == "elim":
			_elim_t -= delta
			if _elim_t <= 0.0:
				_eliminate()
		if _mode != "elim" and _race_d >= _race_len:
			_finish_race()


## Elimination: whoever is last when the clock runs out is done.
func _eliminate() -> void:
	_elim_t = 16.0
	var last: Dictionary = {}
	var last_d := _race_d
	var left := 0
	for r in _riders:
		if r.get("out", false):
			continue
		left += 1
		if float(r["race_d"]) < last_d:
			last_d = float(r["race_d"])
			last = r
	if last.is_empty():
		# It is you at the back.
		_finish_race(left + 1)
		return
	last["out"] = true
	Sfx.play("impact", -4.0, 0.8)
	_pop(Loc.t("%s IS OUT") % str(Characters.get_char(str(last["info"]["key"])).get("short", "")).to_upper(), Color("ff5a5a"))
	if left <= 1:
		_finish_race(1)


func _finish_race(place := 0) -> void:
	var pos := place if place > 0 else _position()
	_race = "done"
	if _mode == "trial":
		_finish_trial()
		return
	var prize: int = (EVENTS[_mode]["prize"] as Array)[clampi(pos - 1, 0, 5)]
	Collection.dp += prize
	Collection.save()
	if pos == 1:
		_wins += 1
	if _mode == "circuit" and (_best <= 0.0 or _race_t < _best):
		_best = _race_t
	if pos < int(_events_best.get(_mode, 99)):
		_events_best[_mode] = pos
	_gain(40.0 if pos == 1 else (20.0 if pos <= 3 else 0.0))     # a good result is Momentum for the next duel
	_save()
	_big.text = [Loc.t("1ST!"), Loc.t("2ND"), Loc.t("3RD")][pos - 1] if pos <= 3 else Loc.t("%dTH") % pos
	_big.add_theme_color_override("font_color", Color("ffd166") if pos == 1 else Color.WHITE)
	Sfx.play("win" if pos <= 3 else "lose")
	if pos == 1:
		Sfx.play("cheer", -4.0)
	Music.play("victory" if pos == 1 else "turbo")
	if _mode == "circuit":
		Router.toast(Loc.t("Lap %s.   +%d Duel Points") % [_clock(_race_t), prize])
	else:
		Router.toast(Loc.t("%s: place %d.   +%d Duel Points") % [Loc.t(str(EVENTS[_mode]["name"])), pos, prize])
	if _gp:
		_gp = false
		_gp_duel(pos)
		return
	await _after_race()


## Back to free riding after an event.
func _after_race() -> void:
	if "--race-test" in OS.get_cmdline_user_args():
		print("RACE TEST %s: place=%d time=%s riding=%d medals=%s trial_best=%s ghost=%d momentum=%d" % [_mode, _position(), _clock(_race_t), _riding(), str(_medals.keys()), _clock(_trial_best), _ghost.size() / 2, int(_mom)])
		get_tree().quit()
	await get_tree().create_timer(3.5).timeout
	_big.text = ""
	_race = ""
	_mode = "circuit"
	if _ghost_node:
		_ghost_node.queue_free()
		_ghost_node = null
	Music.play("turbo")
	var i := 0
	for r in _riders:
		r["out"] = false
		if absf(float(r["x"])) > 900.0:
			r["x"] = 120.0 + 190.0 * i      # back from wherever a time trial or an elimination left them
		r["x"] = fposmod(float(r["x"]) + LAP / 2.0, LAP) - LAP / 2.0
		i += 1


## A time trial lap is done: medals pay once each, a new best becomes the ghost.
func _finish_trial() -> void:
	var t := _race_t
	var better := _trial_best <= 0.0 or t < _trial_best
	var paid := 0
	var got := ""
	for m in MEDALS:
		if t <= float(m[1]):
			if got == "":
				got = str(m[0])
			if not _medals.has(m[0]):
				_medals[m[0]] = true
				paid += int(m[2])
	if better:
		_trial_best = t
		_ghost = _ghost_rec.duplicate()
		paid += 40
	Collection.dp += paid
	Collection.save()
	_gain(25.0 if got != "" else 10.0)
	_save()
	_big.text = _clock(t)
	_big.add_theme_color_override("font_color", {"gold": Color("ffd166"), "silver": Color("d8dde6"), "bronze": Color("d99a5a")}.get(got, Color.WHITE))
	Sfx.play("win" if got != "" or better else "lose")
	var line := Loc.t("Lap %s.") % _clock(t)
	if got != "":
		line += "  " + Loc.t("%s medal.") % Loc.t(got.capitalize())
	if better:
		line += "  " + Loc.t("New best: it rides with you next time.")
	if paid > 0:
		line += "  " + Loc.t("+%d Duel Points") % paid
	Router.toast(line)
	await _after_race()


func _recycle(th: Dictionary) -> void:
	th["missed"] = false
	th["hit"] = false
	(th["node"] as Node3D).queue_free()
	_things.erase(th)
	_spawn_thing(_rng.randf_range(150.0, 260.0))


# ------------------------------------------------------------------ Highway Grand Prix

var _gp := false       # the lap being raced is a Grand Prix heat


## The bracket, over the road. "Race" starts the heat for your next round.
func _gp_panel(result := {}) -> void:
	if _paused and result.is_empty():
		return
	_paused = true
	var p := BracketPanel.new("turbo", result)
	_ui.add_child(p)
	p.closed.connect(func(): _paused = false)
	p.play.connect(func():
		p.queue_free()
		_paused = false
		_gp = true
		_race = ""
		_start_race())


## G at the start line: enter the Grand Prix, or look at where you stand in it.
func _gp_key() -> void:
	var s := Tournament.st("turbo")
	if str(s["stage"]) != "finals":
		if _beaten.size() < 2 and not "--gp" in OS.get_cmdline_user_args():
			Router.toast(Loc.t("The Grand Prix is for riders who have won 2 Turbo Duels on this road. You have %d.") % _beaten.size())
			Sfx.play("error", -8.0)
			return
		Tournament.register("turbo")
		Tournament.start_finals("turbo")
		Sfx.play("quest", -3.0)
		Router.toast(Loc.t(str(Tournament.DEFS["turbo"]["blurb"])))
	_gp_panel()


## The heat is over: your place becomes your starting Speed Counters, then the duel begins.
func _gp_duel(place: int) -> void:
	var start: int = [4, 3, 2][place - 1] if place <= 3 else 1
	Router.toast(Loc.t("Heat finished: place %d. You start the duel with %d Speed Counters.") % [place, start])
	await get_tree().create_timer(3.2).timeout
	var cfg := Tournament.duel_config("turbo")
	cfg["return_to"] = Router.RIDE
	cfg["speed_start"] = [start, 2]
	cfg["continue_label"] = Loc.t("Back to the bracket")
	Router.roam["tourney"] = "turbo"
	Router.roam["turbo_rival"] = ""
	Router.roam["ride_s"] = 0.0
	Router.match_state = {}
	Router.duel_config = cfg
	print("GP duel vs ", cfg["opponent_name"], " speed ", cfg["speed_start"])
	Router.go(Router.DUEL)


## (0.74.1) The first corner: before a Turbo Duel on the road, the two of you race to the
## first bend, CORNER_LEN meters away. Whoever takes it first takes the first turn.
const CORNER_LEN := 340.0
var _corner := {}      # {r, mine, theirs, count, pace} while the race to the corner is on


func _corner_start(r: Dictionary) -> void:
	_corner = {"r": r, "mine": 0.0, "theirs": 0.0, "count": 2.99, "pace": float(r["info"]["race"]) * 0.97}
	r["x"] = 1.5
	r["z"] = clampf(_z + (LANE if _z < LANE else -LANE), -LANE * 2.0, LANE * 2.0)
	Sfx.play("gong", -3.0)
	Router.toast(str(r["info"]["line"]))
	_pop(Loc.t("RACE TO THE FIRST CORNER: first there takes the first turn"), Color("ffd166"))
	print("RIDE corner start vs ", r["info"]["key"])


func _corner_tick(delta: float) -> void:
	var r: Dictionary = _corner["r"]
	if float(_corner["count"]) > 0.0:
		var before := int(_corner["count"]) + 1
		_corner["count"] = float(_corner["count"]) - delta
		var now := int(_corner["count"]) + 1
		_big.text = str(now) if float(_corner["count"]) > 0.0 else Loc.t("GO!")
		_big.add_theme_color_override("font_color", Color("ffd166") if float(_corner["count"]) > 0.0 else Color("5aff90"))
		if now != before or float(_corner["count"]) <= 0.0:
			Sfx.play("phase" if float(_corner["count"]) > 0.0 else "special", -2.0)
		r["x"] = 1.5
		return
	_corner["mine"] = float(_corner["mine"]) + _speed * delta
	_corner["theirs"] = float(_corner["theirs"]) + float(_corner["pace"]) * delta
	r["x"] = float(_corner["theirs"]) - float(_corner["mine"]) + 1.5
	var left := CORNER_LEN - maxf(float(_corner["mine"]), float(_corner["theirs"]))
	_big.text = Loc.t("CORNER  %d m") % maxi(0, int(left))
	_big.add_theme_color_override("font_color", Color.WHITE)
	if left <= 0.0:
		var me_first := float(_corner["mine"]) >= float(_corner["theirs"])
		_corner = {}
		_big.text = Loc.t("YOU TAKE THE CORNER!") if me_first else Loc.t("THEY TAKE THE CORNER")
		_big.add_theme_color_override("font_color", Color("5aff90") if me_first else Color("ff8a5a"))
		Sfx.play("win" if me_first else "error", -4.0)
		print("RIDE corner done me_first=", me_first)
		_near = _riders.find(r)
		_challenge(1 if me_first else 0)


func _challenge(first := -1) -> void:
	if _exit >= 0 and first < 0:
		_take_exit()
		return
	if not _corner.is_empty():
		return
	if _near < 0:
		return
	if first < 0 and not "--no-corner" in OS.get_cmdline_user_args():
		_corner_start(_riders[_near])
		return
	var info: Dictionary = _riders[_near]["info"]
	var key := str(info["key"])
	_paused = true
	Sfx.play("gong", -3.0)
	Router.toast(str(info["line"]))
	Router.roam["turbo_rival"] = key
	Router.roam["ride_s"] = _s
	Router.roam["ride_mom"] = 0.0      # spent on this duel
	# How you rode up to them is how the duel opens: Speed Counters on your dial and who moves
	# first. A tougher rider starts with counters of their own, so ride well before you ask.
	var worth := _mom_worth()
	var mine := mini(DuelState.SPEED_MAX, int(worth[0]) + int(Collection.record.get("runner_tune", 0)))
	var theirs := maxi(0, int(info["difficulty"]) - 1)
	if first >= 0:
		worth[1] = first == 1       # (the first corner decided who goes first, not Momentum)
	Router.toast.call_deferred(Loc.t("Momentum %d: you start with %d Speed Counters (%s has %d) and %s.") % [int(_mom), mine,
		str(Characters.get_char(key).get("short", key)), theirs, Loc.t("you take the first turn") if worth[1] else Loc.t("they take the first turn")])
	print("RIDE duel setup: momentum=%d speed=[%d,%d] first=%s" % [int(_mom), mine, theirs, "me" if worth[1] else "them"])
	var deck := str(info["deck"])
	if not CardData.has_deck(deck):
		deck = ["yusei", "jaden", "kaiba", "yugi", "joey"][absi(key.hash()) % 5]
	Router.match_state = {}
	Router.duel_config = {
		"opponent": key, "opponent_deck": DeckTiers.for_duel(deck, key, int(info["difficulty"]) + 1), "player_deck": Collection.active_deck(), "player_char": "player",
		"difficulty": int(info["difficulty"]), "turbo": true, "story": true, "lose_ok": true, "return_to": Router.RIDE,
		"continue_label": Loc.t("Back to the highway"),
		"speed_start": [mine, theirs], "first_turn": 0 if worth[1] else 1,
	}
	await get_tree().create_timer(2.4).timeout
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
	Sfx.ambience_pitch(1.0)
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
		Sfx.ambience_pitch(1.0)
		Sfx.ambience("")
		Pad.walk_mode = false
		Router.roam.erase("ride_s")
		if bool(Router.roam.get("ride_gate", false)):
			Router.menu_open = "turbo"       # came from the Turbo screen: back to it, one more Back to the menu
		Router.go(Router.MAIN_MENU)
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G) or (pad and Pad.b(event) == JOY_BUTTON_Y):
		var gm := fposmod(_s, LAP)
		if _race == "" and (gm > LAP - 90.0 or gm < 12.0):
			_gp_key()
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R) or (pad and Pad.b(event) == JOY_BUTTON_X):
		var m := fposmod(_s, LAP)
		if _race == "" and (m > LAP - 90.0 or m < 12.0):
			_events_panel()
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T) or (pad and Pad.b(event) == JOY_BUTTON_BACK):
		if _race == "":
			_garage_panel()
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E) or event.is_action_pressed("ui_accept"):
		if _race == "":
			_challenge()


# ------------------------------------------------------------------ the garage

## Your runner, up close, and everything you can do to it. Changes show at once.
func _garage_panel() -> void:
	if _paused:
		return
	_paused = true
	Input.action_release("ui_up")
	Sfx.play("select", -4.0)
	# Come round to the side of the runner so you can see what you are choosing.
	_cam.position = Vector3(0.7, 1.2, _z + 4.5)
	_cam.look_at(Vector3(1.75, 0.8, _z), Vector3.UP)
	_cam.rotation.z = 0.0
	_cam.fov = 50.0
	_blur.amount = 0.0
	_lines.amount = 0.0
	var p := SidePanel.new(Loc.t("GARAGE"), 700.0)
	p._dim.color = Color(0.02, 0.03, 0.08, 0.12)       # keep the runner in the light
	_ui.add_child(p)
	p.closed.connect(func():
		_paused = false
		_place_camera(1.0))
	_garage_fill(p)


func _garage_fill(p: SidePanel) -> void:
	for c in p.body.get_children():
		c.queue_free()
	var dp := UITheme.label(Loc.t("Duel Points: %d") % Collection.dp, 20, UITheme.GOLD, UITheme.semi_font())
	p.body.add_child(dp)
	var first: Button = null
	# Frame.
	p.body.add_child(UITheme.label(Loc.t("FRAME"), 22, Color.WHITE, UITheme.title_font()))
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 10)
	for i in TurboGarage.FRAMES.size():
		var b := Button.new()
		b.text = Loc.t(str(TurboGarage.FRAMES[i]))
		b.toggle_mode = true
		b.button_pressed = TurboGarage.frame() == i
		UITheme.chip(b)
		b.pressed.connect(func(): _garage_set(p, "frame", i))
		fr.add_child(b)
		if first == null:
			first = b
	p.body.add_child(fr)
	# Paint and trail: swatches.
	for row in [["PAINT", "paint", TurboGarage.PAINTS], ["TRAIL", "trail", TurboGarage.TRAILS]]:
		var list: Array = row[2]
		var cur := clampi(int(TurboGarage.val(str(row[1]), 0)), 0, list.size() - 1)
		p.body.add_child(UITheme.label("%s   ·   %s" % [Loc.t(str(row[0])), Loc.t(str(list[cur][0]))], 22, Color.WHITE, UITheme.title_font()))
		var grid := HFlowContainer.new()
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for i in list.size():
			var hex := str(list[i][1])
			var sw := Button.new()
			sw.custom_minimum_size = Vector2(54, 44)
			sw.tooltip_text = Loc.t(str(list[i][0]))
			var col := Color(hex) if hex != "" else (Profile.color() if str(row[1]) == "paint" else TurboGarage.paint(Profile.color()))
			var sb := UITheme.button_box(col, Color.WHITE if i == cur else Color(1, 1, 1, 0.15), 10)
			sb.set_border_width_all(3 if i == cur else 1)
			for st in ["normal", "hover", "pressed", "focus"]:
				sw.add_theme_stylebox_override(st, sb)
			if hex == "":
				sw.text = "●"
				sw.add_theme_color_override("font_color", Color(0, 0, 0, 0.55))
			sw.pressed.connect(func(): _garage_set(p, str(row[1]), i))
			grid.add_child(sw)
		p.body.add_child(grid)
	# What is painted on the side.
	p.body.add_child(UITheme.label(Loc.t("ON THE SIDE"), 22, Color.WHITE, UITheme.title_font()))
	var mk := HFlowContainer.new()
	mk.add_theme_constant_override("h_separation", 8)
	mk.add_theme_constant_override("v_separation", 8)
	for i in TurboGarage.MARKS.size():
		var b2 := Button.new()
		var sign := str(TurboGarage.MARKS[i][1])
		b2.text = Loc.t(str(TurboGarage.MARKS[i][0])) if sign in ["", "#"] else sign + "  " + Loc.t(str(TurboGarage.MARKS[i][0]))
		b2.toggle_mode = true
		b2.button_pressed = int(TurboGarage.val("mark", 0)) == i
		UITheme.chip(b2)
		b2.pressed.connect(func(): _garage_set(p, "mark", i))
		mk.add_child(b2)
	p.body.add_child(mk)
	if str(TurboGarage.MARKS[clampi(int(TurboGarage.val("mark", 0)), 0, TurboGarage.MARKS.size() - 1)][1]) == "#":
		var nr := HBoxContainer.new()
		nr.add_theme_constant_override("separation", 10)
		nr.add_child(UITheme.label(Loc.t("Your number"), 19, UITheme.TEXT_DIM))
		for step in [-10, -1, 1, 10]:
			var nb := Button.new()
			nb.text = ("+%d" % step) if step > 0 else str(step)
			nb.pressed.connect(func(): _garage_set(p, "number", posmod(int(TurboGarage.val("number", 7)) + step, 100)))
			nr.add_child(nb)
		nr.add_child(UITheme.label(str(int(TurboGarage.val("number", 7))), 30, UITheme.GOLD, UITheme.title_font()))
		p.body.add_child(nr)
	# Parts.
	p.body.add_child(UITheme.label(Loc.t("PARTS"), 22, Color.WHITE, UITheme.title_font()))
	for part in TurboGarage.PART_ORDER:
		var info: Dictionary = TurboGarage.PARTS[part]
		var lvl := TurboGarage.level(part)
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", 12)
		var txt := VBoxContainer.new()
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		txt.add_theme_constant_override("separation", 0)
		txt.add_child(UITheme.label("%s   %s" % [Loc.t(str(info["name"])), "■".repeat(lvl) + "□".repeat(TurboGarage.COST.size() - lvl)], 21, Color.WHITE, UITheme.semi_font()))
		var what := UITheme.label("%s.  %s: %s" % [Loc.t(str(info["what"])), Loc.t("Now"), Loc.t(TurboGarage.gives(part, lvl))], 16, UITheme.TEXT_DIM)
		what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.add_child(what)
		row2.add_child(txt)
		var buy := Button.new()
		if lvl >= TurboGarage.COST.size():
			buy.text = Loc.t("Maxed")
			buy.disabled = true
		else:
			buy.text = Loc.t("%s  ·  %d DP") % [Loc.t(TurboGarage.gives(part, lvl + 1)), int(TurboGarage.COST[lvl])]
			buy.disabled = Collection.dp < int(TurboGarage.COST[lvl])
			buy.pressed.connect(func():
				var why := TurboGarage.buy(part)
				if why != "":
					Router.toast(Loc.t(why))
					Sfx.play("error", -8.0)
				else:
					Sfx.play("rare", -4.0)
				_garage_fill(p))
		buy.custom_minimum_size = Vector2(220, 46)
		row2.add_child(buy)
		p.body.add_child(row2)
	var note := UITheme.label(Loc.t("Your runner looks like this in every Turbo Duel too. Speed Counters at the start of a duel come from your Momentum on the road, and from the tuning bench in the Satellite garage."), 16, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(note)
	if first:
		first.grab_focus.call_deferred()


## One thing changed in the garage: keep it, and put the new look on the runner right away.
func _garage_set(p: SidePanel, key: String, value: int) -> void:
	TurboGarage.put(key, value)
	Sfx.play("select", -6.0)
	track.replace_rider(0, "player", TurboGarage.paint(Profile.color()), _my_look())
	track.place_rider(0, Vector3(0, _y, _z), 0.0)
	_flame = null
	_garage_fill(p)
