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
var _dlg_tag: StyleBoxFlat
var _dlg_text: Label
var _dlg_face: TextureRect
var _plate: Control
var _purse: Control
var _dlg_fig: RoamFigure
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
var _outside_yaw := PI
var _map: RoamMap
var _map_full: RoamMap
var _loc_name: Label
var _loc_area: Label
var _fader: ColorRect
var _overlay_open := false
var extras: RoamExtras
var _help: Label
var story: StoryDirector          # set while a story chapter is being played in this world
var _lights: Array = []        # every lamp in the world, for _cull_lights
var _chat_turn := {}           # npc id -> how many times you have talked this visit
var _light_t := 0.0
var walkers_frozen := false       # the story's Hollows: nobody on the street moves
var life: WorldLife                # street dressing, animals, benches, favors (Domino and the Academy)
var weather: Weather
var _jump := false
var _hop_test := "--hop" in OS.get_cmdline_user_args()   # dev: jump now and then on a walk test
var _squash := 0.0
var _air := false                 # off the ground (for the landing sound)
var _rooms := {}                  # rooms you can walk into in this district (door filled in)


func _ready() -> void:
	district = RoamData.district(Router.roam.get("district", "domino"))
	_theme = FieldThemes.resolve(district.get("theme", "battlecity"), "")
	_load_progress()
	_build_world()
	_build_player()
	var in_story := str(Router.roam.get("story", "")) != ""
	if not in_story:
		_build_npcs()
	_build_walkers()
	_build_places()
	city.player = _player
	_build_ui()
	if district.get("builder", "") == "" and _player.position.distance_to(ShopInterior.AT) < 30.0:
		_set_inside("kame")
	else:
		for rk in _rooms:
			if _player.position.distance_to(_rooms[rk]["at"]) < 30.0:
				_set_inside(rk)
	if _map:
		for mp in [_map, _map_full]:
			mp.title = str(district.get("name", "")).to_upper()
			mp.area = str(district.get("area", ""))
			if district.has("map"):
				mp.layout = district["map"]
	Music.play({"": "city", "academy": "academy"}.get(str(district.get("builder", "")), str(district.get("theme", "city"))))
	Sfx.ambience({"": "city", "academy": "sea"}.get(str(district.get("builder", "")), "wind" if district.get("theme", "") == "satellite" else "hum"))
	Pad.walk_mode = true
	Pad.both_sticks = false
	Pad.hint("Left stick  walk     Right stick  look     A  talk / enter     LB  run     Y  map     X  card shop     Back  worlds     Start  menu")
	extras = RoamExtras.new()
	extras.scene = self
	extras.story_mode = in_story
	add_child(extras)
	if true:
		life = WorldLife.new()
		add_child(life)
		life.setup(self)
		weather = Weather.new()
		add_child(weather)
		weather.setup(self)
	_update_fill()
	if in_story:
		if _counter:
			_counter.visible = false
		# No through traffic during a chapter: scenes play out in the middle of the street.
		for c in city.cars:
			(c["node"] as Node3D).queue_free()
		city.cars.clear()
		story = StoryDirector.new()
		story.scene = self
		add_child(story)
	else:
		_after_duel()
	_debug()


# ------------------------------------------------------------------ progress

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_beaten = cfg.get_value("roam", "beaten", {})
	Router.duel_config["player_deck"] = Collection.active_deck()


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
				if life and life.tourney:
					life.tourney.street_win(who, str((n[0] as Dictionary).get("duel", {}).get("deck", "")))
			var name: String = _npc_name(n[0])
			await get_tree().create_timer(0.8).timeout
			Router.toast((Loc.t("You beat %s!") % name) if won else (Loc.t("%s wins this time. Try again!") % name))
	_update_counter()


# ------------------------------------------------------------------ world

## The duel field for a duel started where you are standing: a park gives a meadow, the
## waterfront the shallows, the old woods the Shadow Realm; otherwise the district's own.
func _field_here() -> String:
	var here: String = district.get("theme", "battlecity")
	if _inside != "":
		return here
	var p := _player.global_position
	var key := str(Router.roam.get("district", "domino"))
	for lm in (district.get("map", {}) as Dictionary).get("landmarks", []):
		if lm.get("park", false):
			var c: Vector2 = lm["pos"]
			var sz: Vector2 = lm["size"]
			if absf(p.x - c.x) < sz.x / 2.0 + 1.0 and absf(p.z - c.y) < sz.y / 2.0 + 1.0:
				return "meadow"
	match key:
		"domino":
			if p.z > 50.0:
				return "tide"
			if p.z < -38.0:
				return "kaibacorp"
		"academy":
			if p.x < -32.0 and p.z > 28.0:
				return "shadow"
			if p.z > 54.0 or absf(p.x) > 52.0:
				return "tide"
			if p.x > 40.0 and p.z < -24.0:
				return "volcano"
			if absf(p.x) > 24.0 or absf(p.z) > 30.0:
				return "meadow"
		"satellite":
			if p.length() > 30.0:
				return "ruins"
	return here


func _build_world() -> void:
	match str(district.get("builder", "")):
		"academy":
			city = AcademyBuilder.new()
		"arena":
			city = ArenaDistrict.new()
		"newdomino":
			city = NewDominoBuilder.new()
		_:
			city = CityBuilder.new()
	add_child(city)
	var key: String = Router.roam.get("district", "domino")
	if city is CityBuilder and str(district.get("builder", "")) == "":
		(city as CityBuilder).wide = true
	if not Router.roam.has("tod_" + key) and district.has("tod") and not Router.roam.has("tod"):
		Router.roam["tod"] = district["tod"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tod="):
			Router.roam["tod"] = a.trim_prefix("--tod=")
	city.build(_theme, Router.roam.get("tod", "night"))


func _cycle_tod() -> void:
	var i := CityBuilder.TODS.find(city.tod)
	var next: String = CityBuilder.TODS[(i + 1) % CityBuilder.TODS.size()]
	Router.roam["tod"] = next
	city.apply_tod(next)
	_update_fill()
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
	[Vector3(-7.4, 0, -8), Vector3(-7.4, 0, -29)],
	[Vector3(-14, 0, 57.8), Vector3(14, 0, 57.8)],
	[Vector3(-29, 0, -7.4), Vector3(-8, 0, -7.4)],
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
		var campus: bool = Router.roam.get("district", "") == "academy"
		if campus:
			people = ["student_boy", "student_girl", "street_duelist", "stylish_woman"]
		var mkey: String = people[i % people.size()] if Avatars.has_avatar(people[i % people.size()]) else "walker_%d" % i
		f.setup(mkey, palette[rng.randi() % palette.size()], "", false)
		f.watch = _player
		f.greets = false
		if campus:
			f.wear_uniform(Avatars.DORM_COLORS[["red", "yellow", "blue"][i % 3]])
		var body := AnimatableBody3D.new()
		body.sync_to_physics = false
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.3
		cap.height = 1.7
		cs.shape = cap
		cs.position.y = 0.85
		body.add_child(cs)
		body.collision_layer = 2
		f.add_child(body)
		var w := {"id": "walker_%d" % i, "fig": f, "a": routes[i][0], "b": routes[i][1], "t": rng.randf(), "dir": 1.0 if rng.randf() > 0.5 else -1.0,
			"speed": rng.randf_range(1.1, 1.6), "pause": 0.0}
		_walkers.append(w)
		# Anybody on the street will duel you if you ask.
		var decks: Array = []
		for k in Characters.ORDER:
			if CardData.has_deck(Characters.DATA[k]["deck"]):
				decks.append(Characters.DATA[k]["deck"])
		var d := {"id": "walker_%d" % i, "char": mkey if Characters.STORY_CAST.has(mkey) else "", "name": "Passerby", "color": Color.GRAY,
				"lines": [WALK_LINES[i % WALK_LINES.size()], "A duel? Right here? ...Sure, why not."],
				"duel": {"deck": decks[rng.randi() % decks.size()] if not decks.is_empty() else "joey", "difficulty": i % 2, "intro": "Let's make it quick!"}}
		var marker := Sprite3D.new()
		marker.visible = false
		f.add_child(marker)
		_npcs.append([d, f, marker])


func _move_walkers(delta: float) -> void:
	if walkers_frozen:
		return
	for w in _walkers:
		var f: RoamFigure = w["fig"]
		var a: Vector3 = w["a"]
		var b: Vector3 = w["b"]
		var len := a.distance_to(b)
		var near_player := f.global_position.distance_to(_player.global_position) < 1.6
		var talking_to: bool = _talking and _dlg_npc.get("id", "") == str(w["id"])
		if w["pause"] > 0.0:
			w["pause"] -= delta
		var moving: bool = not talking_to and w["pause"] <= 0.0 and not (near_player and _prompt and _prompt.visible and _near.get("id", "") == str(w["id"]) and _player.velocity.length() < 0.5)
		if moving:
			w["t"] += w["dir"] * w["speed"] * delta / len
			if w["t"] > 1.0 or w["t"] < 0.0:
				w["t"] = clampf(w["t"], 0.0, 1.0)
				w["dir"] = -w["dir"]
				w["pause"] = randf_range(0.5, 2.5)
		# Step around you instead of standing in your way.
		var along: Vector3 = (b - a).normalized()
		var side_dir := along.cross(Vector3.UP)
		var rel: Vector3 = _player.global_position - (a.lerp(b, w["t"]))
		var want_side := 0.0
		if rel.length() < 2.4:
			want_side = -signf(rel.dot(side_dir) if absf(rel.dot(side_dir)) > 0.05 else 1.0) * 1.0
		w["side"] = lerpf(float(w.get("side", 0.0)), want_side, 1.0 - exp(-delta * 4.0))
		var pos := a.lerp(b, w["t"]) + Vector3(0, 0.16, 0) + side_dir * float(w["side"])
		f.position = pos
		f.set_speed(w["speed"] if moving else 0.0)
		if not talking_to:
			var heading: Vector3 = (b - a).normalized() * float(w["dir"])
			f.rotation.y = lerp_angle(f.rotation.y, atan2(heading.x, heading.z), 1.0 - exp(-delta * 8.0))


## People who drift around a room: shop customers going from shelf to shelf. They stop to look,
## pick something up, scratch their head, then move on. They wait if you stand in the way.
var _wanderers: Array = []


func _move_wanderers(delta: float) -> void:
	if walkers_frozen or story != null:
		return
	for w in _wanderers:
		var f: RoamFigure = w["fig"]
		if _talking and _dlg_npc.get("id", "") == str(w["id"]):
			f.set_speed(0.0)
			continue
		var k := 1.0 - exp(-delta * 6.0)
		if w["pause"] > 0.0:
			w["pause"] -= delta
			f.set_speed(0.0)
			f.rotation.y = lerp_angle(f.rotation.y, float(w["face"]), k)
			continue
		var pt: Array = w["pts"][w["i"]]
		var to: Vector3 = (pt[0] as Vector3) - f.position
		to.y = 0.0
		if to.length() < 0.1:
			w["pause"] = randf_range(5.0, 11.0)
			w["face"] = pt[1]
			w["k"] = (int(w["k"]) + 1) % (w["order"] as Array).size()
			w["i"] = int(w["order"][w["k"]])
			f.set_speed(0.0)
			f._fidget_t = randf_range(1.2, 3.0)
			continue
		if f.global_position.distance_to(_player.global_position) < 1.25:
			f.set_speed(0.0)
			continue
		var step := minf(1.05 * delta, to.length())
		f.position += to.normalized() * step
		f.rotation.y = lerp_angle(f.rotation.y, atan2(to.x, to.z), k)
		f.set_speed(1.05)


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
	_player.collision_mask = 3
	add_child(_player)
	var start = Router.roam.get("pos")
	_player.position = start if start is Vector3 else district.get("start", Vector3(0, 0, 8))
	_figure = RoamFigure.new()
	_player.add_child(_figure)
	_figure.setup("player", Profile.color(), "", false)
	_dress_player()
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
	_arm.collision_mask = 1
	_pivot.add_child(_arm)
	_cam = Camera3D.new()
	_cam.fov = 60
	_cam.near = 0.12
	_cam.far = 1200.0
	_arm.add_child(_cam)
	_cam.current = true


## The renderer only draws so many lights at once, and it picks them by what the camera
## could see, not by how near they are. So lamps a long way off (the whole city, when you are
## standing in a shop) are switched off, or they crowd out the ones in the room with you.
func _cull_lights() -> void:
	if city == null:
		return
	if _lights.is_empty():
		for n in city.find_children("*", "Light3D", true, false):
			if not (n is DirectionalLight3D):
				_lights.append(n)
	var cam := get_viewport().get_camera_3d()
	var here: Vector3 = cam.global_position if cam else _player.global_position
	for l: Light3D in _lights:
		if not is_instance_valid(l):
			continue
		var reach := 55.0
		if l is OmniLight3D:
			reach += (l as OmniLight3D).omni_range
		elif l is SpotLight3D:
			reach += (l as SpotLight3D).spot_range
		var far := l.global_position.distance_to(here) > reach
		if far != bool(l.get_meta("far", false)) or not l.has_meta("far"):
			if not l.has_meta("want"):
				l.set_meta("want", l.visible)
			l.set_meta("far", far)
			l.visible = bool(l.get_meta("want")) and not far


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
		var look_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		if absf(look_y) > 0.25:
			_pitch = clampf(_pitch - look_y * delta * 1.4, -1.1, 0.15)
		if Input.is_key_pressed(KEY_Q):
			_yaw += delta * 2.0
	input = input.limit_length(1.0)
	if life and life.seated:
		if input.length() > 0.3:
			life.stand_up()
		input = Vector2.ZERO
	var run := Input.is_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.4
	Pad.overlay = _talking or _overlay_open or _pause != null
	var basis := Basis(Vector3.UP, _yaw)
	var dir := basis * Vector3(input.x, 0, input.y)
	var target := dir * (RUN if run else SPEED)
	# Ease into a walk, stop a touch quicker than you start.
	var rate := 7.5 if target.length() > 0.1 else 11.0
	_player.velocity.x = lerpf(_player.velocity.x, target.x, 1.0 - exp(-delta * rate))
	_player.velocity.z = lerpf(_player.velocity.z, target.z, 1.0 - exp(-delta * rate))
	var grounded := _player.is_on_floor()
	if grounded and _air and _player.velocity.y <= 0.0:
		Sfx.play("land", -8.0)
		_squash = 0.14
	_air = not grounded
	_player.velocity.y = 0.0 if grounded else _player.velocity.y - 20.0 * delta
	if _hop_test and Engine.get_physics_frames() % 150 == 100:
		_jump = true
	if _jump and grounded and not (life and life.seated):
		_player.velocity.y = 6.2
		Sfx.play("jump", -9.0)
		_air = true
	_jump = false
	_player.move_and_slide()
	var flat := Vector2(_player.velocity.x, _player.velocity.z)
	_figure.set_speed(flat.length() if not _air else 0.0)
	var turn := 0.0
	if flat.length() > 0.3 and not (life and life.seated):
		var want := atan2(flat.x, flat.y)
		turn = wrapf(want - _figure.rotation.y, -PI, PI)
		_figure.rotation.y = lerp_angle(_figure.rotation.y, want, 1.0 - exp(-delta * 10.0))
	# Lean into turns and forward into a run; a little squash on landing.
	var k := 1.0 - exp(-delta * 8.0)
	_figure.rotation.z = lerpf(_figure.rotation.z, clampf(-turn * 0.22, -0.16, 0.16) * clampf(flat.length() / RUN, 0.0, 1.0), k)
	_figure.rotation.x = lerpf(_figure.rotation.x, 0.07 * clampf((flat.length() - SPEED) / (RUN - SPEED), 0.0, 1.0) + (-0.12 if _air else 0.0), k)
	_squash = move_toward(_squash, 0.0, delta * 0.6)
	_figure.scale = Vector3(1.0 + _squash * 0.5, 1.0 - _squash, 1.0 + _squash * 0.5)
	_pivot.position = _pivot.position.lerp(_player.position + Vector3(0, 1.45, 0), 1.0 - exp(-delta * 10.0))
	_pivot.rotation = Vector3(_pitch, _yaw, 0)
	# Backed against a wall the camera ends up at your shoulder: step out of its way.
	if story == null or not story._cut:
		_figure.visible = _cam.global_position.distance_to(_player.global_position + Vector3(0, 1.3, 0)) > 0.75
	_light_t -= delta
	if _light_t <= 0.0:
		_light_t = 0.35
		_cull_lights()
	_move_walkers(delta)
	_move_wanderers(delta)
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
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and _near.is_empty() and _near_spot.is_empty():
		_jump = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A):
		if _near.is_empty() and _near_spot.is_empty():
			_jump = true
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


## On Academy Island an enrolled student wears the jacket of their dorm.
func _dress_player() -> void:
	if Router.roam.get("district", "") == "academy":
		var c = Academy.uniform_color()
		if c is Color:
			_figure.wear_uniform(c)


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
		f.watch = _player
		f.stance = str(d.get("pose", "browse" if d.has("wander") else "stand"))
		f.greets = not d.get("aloof", false)
		if f.stance == "sit" and d.get("seat", true):
			f.seat_if_needed()
		if d.has("dorm"):
			f.wear_uniform(Avatars.DORM_COLORS[d["dorm"]])
		var body: PhysicsBody3D = AnimatableBody3D.new() if d.has("wander") else StaticBody3D.new()
		if body is AnimatableBody3D:
			(body as AnimatableBody3D).sync_to_physics = false
			var pts: Array = []
			for w in d["wander"]:
				pts.append([(w[0] as Vector3) + offset, float(w[1])])
			_wanderers.append({"id": d["id"], "fig": f, "pts": pts, "i": 0, "pause": randf_range(2.0, 7.0), "face": float(d.get("face", 0.0)),
				"order": d.get("order", range(pts.size())), "k": 0})
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.35
		cap.height = 1.7
		cs.shape = cap
		cs.position.y = 0.85
		body.add_child(cs)
		body.collision_layer = 2
		f.add_child(body)
		var marker := Sprite3D.new()
		marker.pixel_size = 0.0019
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.shaded = false
		marker.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		marker.position = Vector3(0, 2.45, 0)
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
	extras.open_guide("places")


# ------------------------------------------------------------------ places you can enter

func _build_places() -> void:
	# The way to the other district (a ferry bus in town, the pier on the island).
	if district.has("travel"):
		var tr: Dictionary = district["travel"]
		_spots.append({"pos": tr["pos"], "range": 2.6, "label": tr["label"], "action": func(): _travel_district(str(tr["to"]))})
		var sign_l := Label3D.new()
		sign_l.text = Loc.t("▼  FERRY")
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
	if Router.roam.get("district", "") == "newdomino":
		# The runner gate: back up onto the highway.
		var g := NewDominoBuilder.GATE + Vector3(0, 0, 0.5)
		_spots.append({"pos": g, "range": 3.0, "label": "Ride onto the highway (Turbo Duels)", "action": func():
			Sfx.play("gong", -6.0)
			Router.roam["ride_from"] = "newdomino"
			Router.go(Router.RIDE)})
		var gl := Label3D.new()
		gl.text = Loc.t("▼  HIGHWAY")
		gl.font_size = 64
		gl.pixel_size = 0.006
		gl.outline_size = 14
		gl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		gl.modulate = Color("ff8a3a")
		gl.position = g + Vector3(0, 3.2, 0)
		city.add_child(gl)
	if Router.roam.get("district", "") == "satellite":
		# The garage door leads out onto the highway.
		var ramp := Vector3(-10, 0, 16.2)
		_spots.append({"pos": ramp, "range": 2.6, "label": "Ride onto the highway (Turbo Duels)", "action": func():
			Sfx.play("gong", -6.0)
			Router.roam["ride_from"] = "satellite"
			Router.go(Router.RIDE)})
		var rl := Label3D.new()
		rl.text = Loc.t("▼  HIGHWAY")
		rl.font_size = 64
		rl.pixel_size = 0.006
		rl.outline_size = 14
		rl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rl.modulate = Color("ff8a3a")
		rl.position = ramp + Vector3(0, 3.2, 0)
		city.add_child(rl)
		var rmat := city.box(Vector3(3.0, 0.03, 1.6), ramp + Vector3(0, 0.2, 0), city.glow_mat(Color("ff8a3a"), 1.3), false)
		rmat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if Router.roam.get("district", "") == "academy":
		# The exam office: a desk inside the main hall opens Duel Academy mode.
		var desk: Vector3 = AcademyRooms.ROOMS["ac_hall"]["at"] + Vector3(6.6, 0, 5.4)
		_spots.append({"pos": desk, "range": 2.0, "label": "Exam office: class duels, exams, tournament", "action": _open_academy})
		Academy.load_data()
		if not Academy.d.get("pending", {}).is_empty() and Router.story_result != "":
			_open_academy.call_deferred()
	# Rooms you can walk into: the KaibaCorp lobby, Burger World and the arcade in Domino; the
	# main hall and the three dorms on Academy Island.
	var dk: String = str(Router.roam.get("district", "domino"))
	if not RoamData.DISTRICTS.has(dk):
		dk = "domino"
	var doors: Dictionary = city.get_meta("doors", {})
	for rk in Interiors.rooms_in(dk):
		var rd: Dictionary = Interiors.all_rooms()[rk].duplicate()
		if not rd.has("door"):
			if not doors.has(str(rd.get("door_of", ""))):
				continue
			rd["door"] = doors[str(rd["door_of"])][0]
			rd["out"] = doors[str(rd["door_of"])][1]
		_rooms[rk] = rd
	if district.get("builder", "") != "":
		_build_rooms()
		return
	ShopInterior.build(city)
	_build_rooms()
	_build_kame_spots()


func _build_rooms() -> void:
	for rk in _rooms:
		var room: Dictionary = _rooms[rk]
		Interiors.build(city, rk)
		var door: Vector3 = room["door"]
		var out: Vector3 = room.get("out", Vector3(0, 0, 1))
		var inside_at: Vector3 = room["at"]
		var half: Vector2 = room["half"]
		_spots.append({"pos": door + out * 0.9, "range": 2.3, "label": str(room["label"]), "action": func(): _travel(rk)})
		_spots.append({"pos": inside_at + Vector3(0, 0, half.y - 0.7), "range": 1.7, "label": "Leave", "action": func(): _travel("")})
		var dl := Label3D.new()
		dl.text = Loc.t("▼  ENTER")
		dl.font_size = 64
		dl.pixel_size = 0.006
		dl.outline_size = 14
		dl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		dl.modulate = Color(room["trim"]).lightened(0.3)
		dl.position = door + out * 0.9 + Vector3(0, 3.0, 0)
		city.add_child(dl)
		var dmat := city.box(Vector3(2.2, 0.03, 1.2), door + out * 0.9 + Vector3(0, 0.18, 0), city.glow_mat(room["trim"], 1.3), false)
		dmat.rotation.y = atan2(out.x, out.z)
		dmat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if str(Router.roam.get("story", "")) == "":
			for d in Interiors.people(rk):
				_add_npc(d, inside_at)
	MoreRooms.build_outside(city, str(Router.roam.get("district", "domino")))
	MoreRooms.add_spots(self)


func _build_kame_spots() -> void:
	var at := ShopInterior.AT
	_spots.append({"pos": Vector3(-10, 0, -15.4), "range": 2.3, "label": "Enter Kame Game", "action": func(): _travel("kame")})
	_spots.append({"pos": at + Vector3(0, 0, 4.3), "range": 1.7, "label": "Leave the shop", "action": func(): _travel("")})
	_spots.append({"pos": at + Vector3(-6.0, 0, 3.4), "range": 1.7, "label": "Change your look", "action": _open_look})
	_spots.append({"pos": at + Vector3(-1.75, 0, -1.9), "range": 1.2, "label": "Pet the shop cat", "action": _pet_cat})
	# A glowing mat in front of the shop door so the way in is easy to spot.
	var mat_mesh := city.box(Vector3(2.2, 0.03, 1.2), Vector3(-10, 0.18, -15.4), city.glow_mat(Color("ffd166"), 1.3), false)
	mat_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var arrow := Label3D.new()
	arrow.text = Loc.t("▼  ENTER")
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
	# Some places keep hours.
	if where in ["burger", "ac_library"] and city.tod == "night" and story == null:
		Router.toast(Loc.t("Closed for the night. It opens again in the morning."))
		Sfx.play("error", -8.0)
		return
	_overlay_open = true
	if life:
		life.stand_up()
	Sfx.play("door", -3.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(_fader, "color:a", 1.0, 0.38).set_delay(0.12)
	tw.tween_property(_arm, "spring_length", maxf(2.2, _arm.spring_length - 2.4), 0.5).set_trans(Tween.TRANS_SINE)
	if not _near_spot.is_empty():
		# Walk the last step to the door while the picture fades.
		var to: Vector3 = (_near_spot["pos"] as Vector3) - _player.position
		to.y = 0.0
		if to.length() > 0.05:
			_figure.rotation.y = atan2(to.x, to.z)
			_figure.set_speed(SPEED * 0.7)
			tw.tween_property(_player, "position", _player.position + to.limit_length(0.9), 0.45)
	await tw.finished
	_figure.set_speed(0.0)
	if where == "kame":
		_outside_pos = Vector3(-10, 0, -13.6)
		_outside_yaw = PI
		_player.position = ShopInterior.AT + Vector3(0, 0, 3.2)
		_yaw = 0.0
	elif _rooms.has(where):
		var room: Dictionary = _rooms[where]
		var out2: Vector3 = room.get("out", Vector3(0, 0, 1))
		_outside_pos = (room["door"] as Vector3) + out2 * 2.2
		_outside_yaw = atan2(out2.x, out2.z) + PI
		_player.position = (room["at"] as Vector3) + Vector3(0, 0, (room["half"] as Vector2).y - 1.8)
		_yaw = 0.0
	else:
		_player.position = _outside_pos
		_yaw = _outside_yaw
	_player.velocity = Vector3.ZERO
	_figure.rotation.y = _yaw + PI
	_pivot.position = _player.position + Vector3(0, 1.45, 0)
	_set_inside(where)
	await get_tree().create_timer(0.12).timeout
	var settle := _arm.spring_length
	_arm.spring_length = settle + 1.6
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(_fader, "color:a", 0.0, 0.45)
	tw2.tween_property(_arm, "spring_length", settle, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_overlay_open = false


func _travel_district(key: String) -> void:
	if _overlay_open:
		return
	_overlay_open = true
	await travel_card(key)
	Router.roam["district"] = key
	Router.roam["pos"] = null
	Router.roam.erase("yaw")
	Router.roam.erase("tod")
	Router.go(Router.ROAM)


## The ride to another world, shown before the scene changes.
func travel_card(key: String) -> void:
	var here: String = str(Router.roam.get("district", "domino"))
	var sea: bool = "academy" in [here, key]
	var card := TravelCard.new(str(district.get("name", "")), str(RoamData.district(key).get("name", key)), sea)
	_ui.add_child(card)
	await card.play()


func _outdoor_sound() -> void:
	Music.play({"": "city", "academy": "academy"}.get(str(district.get("builder", "")), str(district.get("theme", "city"))))
	Sfx.ambience({"": "city", "academy": "sea"}.get(str(district.get("builder", "")), "wind" if district.get("theme", "") == "satellite" else "hum"))


## A soft light that travels with the camera, so the hero is never a silhouette
## indoors, at night or against the sunset.
func _update_fill() -> void:
	if _cam == null:
		return
	var fill: OmniLight3D = _cam.get_node_or_null("Fill")
	if fill == null:
		fill = OmniLight3D.new()
		fill.name = "Fill"
		fill.omni_attenuation = 0.6
		fill.shadow_enabled = false
		_cam.add_child(fill)
	var t: String = city.tod if city else "day"
	if _inside != "":
		fill.light_color = Color(1.0, 0.93, 0.82)
		fill.light_energy = 1.5
		fill.omni_range = 9.0
		fill.visible = true
	else:
		fill.light_color = Color(0.75, 0.82, 1.0) if t == "night" else Color(1.0, 0.86, 0.72)
		fill.light_energy = 1.1 if t == "night" else 0.7
		fill.omni_range = 13.0
		fill.visible = t != "day"


func _set_inside(where: String) -> void:
	if where != _inside:
		Sfx.play("door", -4.0)
		if where != "":
			Music.play("shop")
			Sfx.ambience("shop")
		else:
			_outdoor_sound()
	_inside = where
	if _rooms.has(where):
		Music.play(str(_rooms[where]["music"]))
	# A soft fill light that travels with the camera, so you are never a silhouette indoors.
	_update_fill()
	_arm.spring_length = 3.6 if where != "" else 6.0
	if _loc_name:
		_loc_name.text = "KAME GAME" if where != "" else str(district.get("name", "")).to_upper()
		_loc_area.text = "Card shop" if where != "" else str(district.get("area", ""))
		if _rooms.has(where):
			_loc_name.text = Loc.t(str(_rooms[where]["name"])).to_upper()
			_loc_area.text = Loc.t(str(_rooms[where]["area"]))
	for mp in [_map, _map_full]:
		if mp == null:
			continue
		if _rooms.has(where):
			var door: Vector3 = _rooms[where]["door"]
			var od: Vector3 = _rooms[where].get("out", Vector3(0, 0, 1))
			mp.inside_at = Vector2(door.x - od.x * 2.5, door.z - od.z * 2.5)
			mp.inside_name = str(_rooms[where]["name"])
		else:
			mp.inside_at = Vector2(-10, -19.5)
			mp.inside_name = "Kame Game"


## A full-screen menu opened from the world (pack shop, deck builder).
func _open_overlay(panel: Control) -> void:
	_overlay_open = true
	_ui.add_child(panel)
	panel.connect("closed", func(): _overlay_open = false)


func _open_academy() -> void:
	_overlay_open = true
	Router.roam["pos"] = _player.position
	Router.roam["yaw"] = _yaw
	var hub := AcademyHub.new()
	hub.return_to = Router.ROAM
	_ui.add_child(hub)
	hub.closed.connect(func():
		_overlay_open = false
		var rot := _figure.rotation.y
		_figure.queue_free()
		_figure = RoamFigure.new()
		_player.add_child(_figure)
		_figure.setup("player", Profile.color(), "", false)
		_dress_player()
		_figure.rotation.y = rot)


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
		_dress_player()
		_figure.rotation.y = rot)


## Which footstep fits what is under your feet.
func ground_sound() -> String:
	if _inside != "":
		return "step_hall" if _inside in ["kc_lobby", "ac_hall", "dorm_blue", "arcade"] else "step_wood"
	if str(Router.roam.get("district", "")) == "academy":
		var p := _player.position
		if Vector2(p.x - 48.0, p.z - 50.0).length() < 17.0 or Vector2(p.x, p.z).length() > 64.0:
			return "step_sand"
		if absf(p.x) > 2.6 and Vector2(p.x, p.z).length() > 9.5 and absf(p.z - 6.0) > 2.2 and absf(p.z + 4.0) > 2.2:
			return "step_grass"
	return "step"


## My Decks, from anywhere: the B key, the bar at the top, the pause menu, the shop counter.
func open_decks() -> void:
	if _overlay_open or _talking or story != null and story._cut:
		return
	_open_overlay(DeckMenu.new())


func _refresh_marker(n: Array) -> void:
	var d: Dictionary = n[0]
	var m: Sprite3D = n[2]
	if not d.has("duel"):
		m.texture = load("res://assets/ui/markers/talk.png")
		m.modulate = Color(1, 1, 1, 0.92)
	elif _beaten.has(d["id"]):
		m.texture = load("res://assets/ui/markers/done.png")
		m.modulate = Color.WHITE
	else:
		m.texture = load("res://assets/ui/markers/duel.png")
		m.modulate = Color.WHITE


## Which part of town the player is standing in (shown under the city name).
func _area_name() -> String:
	var p := _player.global_position
	match str(district.get("builder", "")):
		"":
			if p.z < -35.5:
				return "KaibaCorp Plaza"
			if p.z > 62.5:
				return "Domino Pier"
			if p.z > 35.5:
				return "Harbor"
			if p.x < -35.0:
				return "Duel Dome"
			if p.x > 35.0:
				return "Domino High"
			return "Downtown"
		"newdomino":
			if p.z > 34.0:
				return "Highway Gate"
			if p.z < -20.0:
				return "Stadium Gate"
			if p.x < -24.0:
				return "Sector Security"
			if p.x > 24.0:
				return "The Tops"
			return "Central Plaza"
	return ""


func _update_near() -> void:
	var best: Dictionary = {}
	var best_d := TALK_RANGE
	for n in _npcs:
		var f: Node3D = n[1]
		var dist := f.global_position.distance_to(_player.global_position)
		var m: Sprite3D = n[2]
		m.position.y = 2.45 + sin(Time.get_ticks_msec() / 300.0) * 0.06
		if dist < best_d:
			best_d = dist
			best = n[0]
	_near = best
	_near_spot = {}
	if _inside == "" and _loc_area:
		var area := _area_name()
		if area != "" and _loc_area.text != Loc.t(area):
			_loc_area.text = Loc.t(area)
	# A door and a person can both be in reach: whichever is closer gets the prompt.
	# During a story chapter the doors are shut: the scene decides when you go through one.
	for sp in (_spots if story == null and not (life != null and life.seated) else []):
		var sd := (sp["pos"] as Vector3).distance_to(_player.global_position)
		if sd < float(sp["range"]) and (_near.is_empty() or sd < best_d):
			_near_spot = sp
			_near = {}
			break
	# In a chapter, say so when you walk up to a door, so a shut door is never a mystery.
	var locked := ""
	if story != null and _near.is_empty() and not _overlay_open:
		for sp in _spots:
			if (sp["pos"] as Vector3).distance_to(_player.global_position) < float(sp["range"]):
				# Unless this door is where the goal is sending you.
				if story._goal.has("at") and (story._goal["at"] as Vector3).distance_to(sp["pos"]) < 3.0:
					break
				var goal_text := str(story._goal.get("goal", ""))
				locked = Loc.t("Not now.  Goal: %s") % Loc.t(goal_text) if goal_text != "" else Loc.t("Not now.")
				break
	if _prompt and locked != "":
		_prompt.visible = true
		_prompt.text = locked
	elif _prompt:
		_prompt.visible = (not _near.is_empty() or not _near_spot.is_empty()) and not _talking and _pause == null and not _overlay_open
		if _prompt.visible:
			_prompt.text = (Loc.t("E   Talk to %s") % Loc.t(_npc_name(_near))) if not _near.is_empty() else ("E   %s" % Loc.t(str(_near_spot["label"])))
	if _map:
		_map.player_pos = Vector2(_player.position.x, _player.position.z)
		_map.player_yaw = _figure.rotation.y + PI
		_map.inside = _inside
		var has_goal: bool = extras != null and extras._wp_on and _inside == ""
		_map.goal = Vector2(extras.waypoint.x, extras.waypoint.z) if has_goal else Vector2.INF
		if _map_full:
			_map_full.goal = _map.goal
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
	var say: Array = d.get("lines", [])
	if d.has("chats"):
		# People with more to say go through their topics one visit at a time.
		var topics: Array = d["chats"]
		var turn: int = int(_chat_turn.get(d["id"], 0))
		say = topics[turn % topics.size()]
		_chat_turn[d["id"]] = turn + 1
	# People with a story to them talk differently once you have beaten them.
	if d.has("after") and _beaten.has(d["id"]):
		var acts: Array = d["after"]
		var seen: int = int(_chat_turn.get(str(d["id"]) + "_after", 0))
		say = acts[mini(seen, acts.size() - 1)]
		_chat_turn[str(d["id"]) + "_after"] = seen + 1
	var favor: Array = life.errand_talk(d) if life and story == null else []
	if not favor.is_empty():
		say = favor
	Collection.daily_bump("talk")
	for l in say:
		_dlg_lines.append(Loc.t(str(l)).replace("{player}", Profile.duelist_name))
	if d.has("duel") and favor.is_empty():
		var duel: Dictionary = d["duel"]
		if _beaten.has(d["id"]) and d.has("after"):
			pass
		elif _beaten.has(d["id"]):
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
	_dlg_fig = null
	for n in _npcs:
		if n[0] == d:
			_dlg_fig = n[1]
	_dlg_face.visible = _dlg_fig != null and _dlg_fig.key != "" and Avatars.has_avatar(_dlg_fig.key)
	if _dlg_face.visible:
		var tex := Portraits.get_portrait(_dlg_fig.key)
		if tex is ViewportTexture and not Avatars._stages.has(_dlg_fig.key):
			Portraits._forget(_dlg_fig.key)
			tex = Portraits.get_portrait(_dlg_fig.key)
		_dlg_face.texture = tex
	if _dlg_fig:
		_dlg_fig.speak(true)
	_dlg_name.text = _npc_name(d).to_upper()
	# Nameless passers-by get the district's color, not grey.
	var tag_col: Color = _npc_color(d)
	if tag_col.s < 0.2:
		tag_col = Color(_theme["accent"])
	_dlg_tag.bg_color = tag_col.darkened(0.05) if tag_col.get_luminance() < 0.7 else tag_col.darkened(0.35)
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
		var first: Button = null
		for item in [["  Booster packs  ", func(): _open_overlay(PackShop.new())], ["  Ready-made decks  ", func(): _open_overlay(DeckShop.new())],
				["  My decks  ", open_decks], ["  Just looking  ", func(): pass]]:
			var sb := Button.new()
			sb.text = Loc.t(str(item[0]))
			sb.add_theme_font_size_override("font_size", 26)
			var act: Callable = item[1]
			sb.pressed.connect(func():
				_end_talk()
				act.call())
			_dlg_buttons.add_child(sb)
			if first == null:
				first = sb
		first.grab_focus.call_deferred()
	elif last and _dlg_npc.get("trade", false):
		_trade_buttons()
	elif last and _dlg_npc.has("gift") and not _shop_flag("gift_" + str(_dlg_npc["id"])):
		var take := Button.new()
		take.text = Loc.t("  Thanks!  (+%d DP)  ") % int(_dlg_npc["gift"])
		take.add_theme_font_size_override("font_size", 26)
		take.pressed.connect(func():
			_shop_set("gift_" + str(_dlg_npc["id"]), true)
			Collection.dp += int(_dlg_npc["gift"])
			Collection.save()
			Sfx.play("coin", -3.0)
			Router.toast(Loc.t("+%d Duel Points") % int(_dlg_npc["gift"]))
			_end_talk())
		_dlg_buttons.add_child(take)
		take.grab_focus.call_deferred()
	elif last and _dlg_npc.get("claw", false):
		var try := Button.new()
		try.text = Loc.t("  Try the claw  ·  %d DP  ") % 60
		try.add_theme_font_size_override("font_size", 26)
		try.disabled = Collection.dp < 60
		try.pressed.connect(_play_claw)
		_dlg_buttons.add_child(try)
		var nope := Button.new()
		nope.text = "  Not now  "
		nope.add_theme_font_size_override("font_size", 26)
		nope.pressed.connect(_end_talk)
		_dlg_buttons.add_child(nope)
		try.grab_focus.call_deferred()
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


# ------------------------------------------------------------------ the card shop's regulars

func _shop_cfg() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load("user://shop.cfg")
	return cfg


func _shop_flag(key: String) -> bool:
	return bool(_shop_cfg().get_value("shop", key, false))


func _shop_set(key: String, value) -> void:
	var cfg := _shop_cfg()
	cfg.set_value("shop", key, value)
	cfg.save("user://shop.cfg")


func _today() -> String:
	return Time.get_date_string_from_system()


## The trader's single of the day: the same card all day, a different one tomorrow.
func _trade_card() -> int:
	var good: Array = []
	for era in ["Duel Monsters", "GX", "5D's", "ZEXAL", "Vault"]:
		for id in Collection.pool(era):
			if CardData.rarity(id) >= 2:
				good.append(id)
	if good.is_empty():
		return 0
	good.sort()
	return good[hash(_today()) % good.size()]


func _trade_buttons() -> void:
	var id := _trade_card()
	if id == 0:
		_dlg_text.text = Loc.t("My binder is empty until the card database is in. Come back then.")
		_dlg_text.visible_ratio = 1.0
	elif str(_shop_cfg().get_value("shop", "bought_day", "")) == _today():
		_dlg_text.text = Loc.t("You already cleaned me out today. Come back tomorrow for a new one.")
		_dlg_text.visible_ratio = 1.0
	else:
		var r := CardData.rarity(id)
		var price := 520 if r >= 3 else 360
		var nm := str(CardData.get_card(id).get("name", "?"))
		_dlg_text.text = Loc.t("Today I have %s (%s). %d Duel Points and it's yours.") % [nm, Loc.t(Foil.NAMES[r]), price]
		_dlg_text.visible_ratio = 1.0
		var buy := Button.new()
		buy.text = Loc.t("  Buy it  ·  %d DP  ") % price
		buy.add_theme_font_size_override("font_size", 26)
		buy.disabled = Collection.dp < price
		buy.pressed.connect(func():
			Collection.dp -= price
			Collection.owned[id] = mini(3, int(Collection.owned.get(id, 0)) + 1)
			Collection.save()
			_shop_set("bought_day", _today())
			Sfx.play("rare", -3.0)
			Router.toast(Loc.t("%s is in your collection.") % nm)
			_end_talk())
		_dlg_buttons.add_child(buy)
		buy.grab_focus.call_deferred()
	var no := Button.new()
	no.text = "  Not today  "
	no.add_theme_font_size_override("font_size", 26)
	no.pressed.connect(_end_talk)
	_dlg_buttons.add_child(no)
	if _dlg_buttons.get_child_count() == 1:
		no.grab_focus.call_deferred()


func _pet_cat() -> void:
	Sfx.play("blip", -8.0, 0.5)
	if str(_shop_cfg().get_value("shop", "cat_day", "")) != _today():
		_shop_set("cat_day", _today())
		Collection.dp += 10
		Collection.save()
		Router.toast(Loc.t("Kuri purrs. You feel lucky.  +10 Duel Points"))
	else:
		Router.toast(Loc.t(["Kuri purrs.", "Kuri opens one eye, then goes back to sleep.", "Kuri stretches across the register."][randi() % 3]))


## The arcade's prize claw: pay, watch it wobble, win one random card (sometimes a good one).
func _play_claw() -> void:
	if Collection.dp < 60:
		return
	Collection.dp -= 60
	for c in _dlg_buttons.get_children():
		c.queue_free()
	_dlg_text.text = Loc.t("The claw drops...")
	Sfx.play("charge", -4.0)
	await get_tree().create_timer(1.1).timeout
	var pools: Array = []
	for era in ["Duel Monsters", "GX", "5D's", "ZEXAL", "Vault"]:
		pools.append_array(Collection.pool(era))
	if pools.is_empty():
		_dlg_text.text = Loc.t("It comes up empty. The machine gives your points back.")
		Collection.dp += 60
		Collection.save()
		return
	var id: int = pools[randi() % pools.size()]
	# One try in four digs for something shiny.
	if randf() < 0.25:
		for tries in 12:
			var alt: int = pools[randi() % pools.size()]
			if CardData.rarity(alt) >= 2:
				id = alt
				break
	Collection.owned[id] = mini(3, int(Collection.owned.get(id, 0)) + 1)
	Collection.save()
	var r := CardData.rarity(id)
	Sfx.play("rare" if r >= 2 else "sparkle", -3.0)
	_dlg_text.text = Loc.t("It grabs a card: %s  (%s). It is in your collection.") % [str(CardData.get_card(id).get("name", "?")), Loc.t(Foil.NAMES[r])]
	var again := Button.new()
	again.text = Loc.t("  Again  ·  %d DP  ") % 60
	again.add_theme_font_size_override("font_size", 26)
	again.disabled = Collection.dp < 60
	again.pressed.connect(_play_claw)
	_dlg_buttons.add_child(again)
	var done := Button.new()
	done.text = "  Done  "
	done.add_theme_font_size_override("font_size", 26)
	done.pressed.connect(_end_talk)
	_dlg_buttons.add_child(done)
	done.grab_focus.call_deferred()


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
	if _dlg_fig and is_instance_valid(_dlg_fig):
		_dlg_fig.speak(false)
		if not _dlg_npc.has("duel") and randf() < 0.5:
			_dlg_fig.do_nod()
	for c in _dlg_buttons.get_children():
		c.queue_free()


## Start a duel against someone who is not a talkable character (a street duel's winner).
func duel_with(d: Dictionary) -> void:
	_dlg_npc = d
	_start_duel()


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
		"player_deck": Collection.active_deck(), "player_char": "player",
		"difficulty": duel.get("difficulty", 1), "field": _field_here(),
		"story": true, "lose_ok": true, "return_to": Router.ROAM, "continue_label": Loc.t("Back to %s") % Loc.t(str(district.get("name", "town"))),
	}
	_end_talk()
	Router.go(Router.DUEL)


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	# Location card, top left.
	var plate := PanelContainer.new()
	var plate_box := UITheme.panel_box(Color(0.032, 0.0532, 0.116, 0.78), 16, Color(_theme["accent"], 0.4))
	plate_box.content_margin_left = 22
	plate_box.content_margin_right = 26
	plate_box.content_margin_top = 8
	plate_box.content_margin_bottom = 10
	plate.add_theme_stylebox_override("panel", plate_box)
	plate.position = Vector2(30, 24)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(plate)
	_plate = plate
	var loc := VBoxContainer.new()
	loc.add_theme_constant_override("separation", -2)
	loc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(loc)
	_loc_name = UITheme.label(district.get("name", "").to_upper(), 46, Color.WHITE, UITheme.title_font())
	loc.add_child(_loc_name)
	_loc_area = UITheme.label(district.get("area", ""), 22, _theme["accent"], UITheme.semi_font())
	loc.add_child(_loc_area)
	_counter = UITheme.label("", 20, Color(0.86, 0.9, 0.97, 0.92))
	loc.add_child(_counter)
	# Duel Points, under the map: always in sight.
	var purse := DpPurse.new()
	purse.anchor_left = 1.0
	purse.anchor_right = 1.0
	purse.offset_left = -292
	purse.offset_right = -36
	purse.offset_top = 300
	purse.offset_bottom = 362
	_ui.add_child(purse)
	_purse = purse
	_update_counter()
	# Controls, bottom left.
	var help := UITheme.label("WASD / stick  move     Shift  run     Drag  look     Scroll  zoom     E  talk / enter     M  map     B  decks     T  time of day     Esc  menu", 17, Color(0.93, 0.95, 1.0, 0.95))
	# On a dark strip of its own, so it reads over grass, sand and bright paving alike.
	var help_bar := PanelContainer.new()
	var hb := StyleBoxFlat.new()
	hb.bg_color = Color(0.03, 0.05, 0.11, 0.72)
	hb.set_corner_radius_all(8)
	hb.content_margin_left = 16
	hb.content_margin_right = 16
	hb.content_margin_top = 6
	hb.content_margin_bottom = 6
	help_bar.add_theme_stylebox_override("panel", hb)
	help_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_bar.add_child(help)
	help_bar.anchor_top = 1.0
	help_bar.anchor_bottom = 1.0
	help_bar.offset_left = 40
	help_bar.offset_top = -62
	help_bar.offset_bottom = -22
	help_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ui.add_child(help_bar)
	_help = help
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
	var sb := UITheme.panel_box(Color(0.042, 0.078, 0.145, 0.9), 14, Color(UITheme.ACCENT, 0.6))
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
	var dsb := UITheme.panel_box(Color(0.03, 0.045, 0.1, 0.95), 14, Color(1, 1, 1, 0.14))
	dsb.set_content_margin_all(20)
	_dlg.add_theme_stylebox_override("panel", dsb)
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	_dlg.add_child(row)
	_dlg_face = TextureRect.new()
	_dlg_face.custom_minimum_size = Vector2(150, 176)
	_dlg_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dlg_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_dlg_face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var face_bg := Panel.new()
	face_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	face_bg.show_behind_parent = true
	face_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_bg.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.102, 0.158, 0.265, 0.95), 16, Color(UITheme.ACCENT, 0.5)))
	_dlg_face.add_child(face_bg)
	row.add_child(_dlg_face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	row.add_child(v)
	# The name sits on a slanted tag in the speaker's color.
	_dlg_name = Comic.label("", 26, Color.WHITE, 0)
	_dlg_tag = Comic.box(Comic.BLUE, 10, 0.18, 4, 4)
	_dlg_tag.content_margin_left = 20
	_dlg_tag.content_margin_right = 20
	_dlg_tag.content_margin_top = 2
	_dlg_tag.content_margin_bottom = 2
	_dlg_name.add_theme_stylebox_override("normal", _dlg_tag)
	_dlg_name.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(_dlg_name)
	_dlg_text = UITheme.label("", 30, Color(0.95, 0.97, 1.0))
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(1000, 90)
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
	_counter.text = Loc.t("Street duels won  %d / %d") % [won, total]


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
	var decks := Button.new()
	decks.text = "My Decks"
	decks.custom_minimum_size = Vector2(320, 60)
	decks.disabled = story != null and story._cut
	decks.pressed.connect(func():
		_close_pause()
		open_decks())
	v.add_child(decks)
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
		elif a.begins_with("--roam-open="):
			# decks | deckshop | packs, then (decks only) buy-and-copy exercise with --roam-open=flow
			await get_tree().create_timer(1.5).timeout
			var what := a.substr(12)
			if what == "flow":
				Collection.dp += 5000
				print("FLOW buy ", Collection.buy_deck("deck_dragon"), " owned=", Collection.decks_owned)
				var dm := DeckMenu.new()
				_open_overlay(dm)
				await get_tree().create_timer(0.5).timeout
				dm._sel = {"type": "ready", "i": -1, "key": "deck_dragon"}
				dm._rebuild()
				dm._use()
				print("FLOW active ", Collection.active_deck(), " cfg=", Router.duel_config["player_deck"])
				dm._copy("deck_dragon")
				await get_tree().create_timer(0.3).timeout
				print("FLOW copied sel=", dm._sel, " slot=", Collection.slot, " active=", Collection.active_deck())
				dm._use()
				print("FLOW custom ", Collection.active_deck(), " name=", Collection.deck_name, " n=", Collection.main.size())
				dm._do_rename("Test Deck")
				dm._clear()
				dm._clear()
				print("FLOW cleared active=", Collection.active_deck(), " empty=", Collection.slot_empty(int(dm._sel["i"])))
				dm._close()
			else:
				_open_overlay(DeckShop.new() if what == "deckshop" else (PackShop.new() if what == "packs" else DeckMenu.new()))
		elif a == "--doors":
			for rk in _rooms:
				print("DOOR ", rk, " ", _rooms[rk]["door"], " out ", _rooms[rk].get("out", Vector3(0, 0, 1)))
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
		elif a.begins_with("--eye="):
			# Free camera for checking a build: --eye=x,y,z,lookx,looky,lookz
			var e := a.trim_prefix("--eye=").split(",")
			await get_tree().create_timer(0.4).timeout
			var eye := Camera3D.new()
			eye.far = 600.0
			eye.fov = 60.0
			add_child(eye)
			eye.global_position = Vector3(float(e[0]), float(e[1]), float(e[2]))
			var target := Vector3(float(e[3]), float(e[4]), float(e[5]))
			eye.look_at(target, Vector3.FORWARD if absf(eye.global_position.x - target.x) + absf(eye.global_position.z - target.z) < 0.01 else Vector3.UP)
			eye.current = true
		elif a.begins_with("--walk-to="):
			# Collision check: walk in straight lines through the listed points and report
			# where the player ends up. --walk-to=x,z;x,z;...
			await get_tree().create_timer(0.5).timeout
			for leg in a.trim_prefix("--walk-to=").split(";"):
				var w := leg.trim_prefix("@").split(",")
				var goal := Vector3(float(w[0]), 0, float(w[1]))
				if leg.begins_with("@"):
					_player.global_position = goal + Vector3(0, 0.1, 0)
					await get_tree().physics_frame
					continue
				for i in 600:
					if i % 30 == 0 and "--arm" in OS.get_cmdline_user_args():
						print("ARM hit=", _arm.get_hit_length(), " at ", _player.global_position)
					var to := goal - _player.global_position
					to.y = 0
					if to.length() < 0.25:
						break
					_player.velocity = to.normalized() * 6.0
					_player.move_and_slide()
					await get_tree().physics_frame
				await get_tree().physics_frame
				var flat := Vector2(goal.x - _player.global_position.x, goal.z - _player.global_position.z).length()
				print("WALK to ", goal, " ", "ok" if flat < 0.5 else "BLOCKED", " at ", _player.global_position.snapped(Vector3(0.1, 0.1, 0.1)), " spot=", _near_spot.get("label", ""), " npc=", _near.get("id", ""))
			if "--walk-quit" in OS.get_cmdline_user_args():
				get_tree().quit()
		elif a.begins_with("--what="):
			# What is standing here? Lists every mesh within 4 m of x,z.
			await get_tree().create_timer(1.0).timeout
			var wp := a.trim_prefix("--what=").split(",")
			var spot := Vector3(float(wp[0]), 0, float(wp[1]))
			for n in find_children("*", "MeshInstance3D", true, false):
				var mi := n as MeshInstance3D
				var gp := mi.global_position
				if Vector2(gp.x - spot.x, gp.z - spot.z).length() < 4.0 and mi.mesh:
					print("WHAT ", mi.get_path(), " at ", gp.snapped(Vector3(0.1, 0.1, 0.1)), " size ", (mi.mesh.get_aabb().size * mi.global_transform.basis.get_scale()).snapped(Vector3(0.1, 0.1, 0.1)), " vis=", mi.is_visible_in_tree(), " mat=", mi.material_override)
		elif a.begins_with("--enter="):
			await get_tree().create_timer(0.6).timeout
			await _travel(a.trim_prefix("--enter="))
		elif a.begins_with("--spot="):
			# Dev: stand on the first spot whose label contains this text and use it.
			await get_tree().create_timer(2.5).timeout
			var want := a.trim_prefix("--spot=").to_lower()
			var found := false
			for sp in _spots:
				if str(sp["label"]).to_lower().contains(want):
					found = true
					_player.global_position = sp["pos"] + Vector3(0, 0.3, 0)
					print("SPOT use: ", sp["label"], " at ", sp["pos"])
					await (sp["action"] as Callable).call()
					break
			if not found:
				print("SPOT not found: ", want)
			await get_tree().create_timer(3.0).timeout
			print("SPOT done dp=", Collection.dp, " scene=", get_tree().current_scene.name if get_tree().current_scene else "?")
			if "--spot-quit" in OS.get_cmdline_user_args():
				get_tree().quit()
		elif a.begins_with("--tour="):
			# Several free-camera shots in one run: --tour=name:x,y,z,lx,ly,lz;name2:...
			await get_tree().create_timer(1.2).timeout
			var tcam := Camera3D.new()
			tcam.far = 700.0
			tcam.fov = 62.0
			add_child(tcam)
			tcam.current = true
			for arg2 in OS.get_cmdline_user_args():
				if arg2.begins_with("--npc-anim="):
					for n in _npcs:
						(n[1] as RoamFigure).play_once(arg2.trim_prefix("--npc-anim="), 99)
			for part in a.trim_prefix("--tour=").split(";"):
				var bits := part.split(":")
				var e2 := bits[1].split(",")
				tcam.global_position = Vector3(float(e2[0]), float(e2[1]), float(e2[2]))
				var tg := Vector3(float(e2[3]), float(e2[4]), float(e2[5]))
				if tcam.global_position.distance_to(_player.global_position) > 160.0:
					_player.global_position = Vector3(tg.x, 0.3, tg.z)
				tcam.look_at(tg, Vector3.UP)
				for i in 4:
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % bits[0])
				print("tour shot ", bits[0])
			get_tree().quit()
		elif a == "--roam-walk":
			await get_tree().create_timer(0.5).timeout
			_yaw = PI * 0.8
			Input.action_press("ui_up")
