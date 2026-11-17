class_name IntroCinema
extends SubViewportContainer
## The opening's flight over the four worlds: each era's city built from the game's own city
## builder, at its own time of day, a camera sweeping over it and Lumen's light racing ahead.
## Every city is built in its own small world before the show starts (the screen is still dark
## then), and only the one on screen is drawn.

## Each world as the game builds it (the same builder as when you walk there), at an hour that
## suits it. The camera glides from `from` to `to`, looking at `look` (all around where you arrive).
const SHOTS := [
	{"district": "domino", "tod": "night", "from": Vector3(-34, 22, 40), "to": Vector3(-6, 13, 22), "look": Vector3(4, 4, -12)},
	{"district": "academy", "tod": "day", "from": Vector3(18, 26, 96), "to": Vector3(4, 12, 66), "look": Vector3(0, 8, 10)},
	{"district": "newdomino", "tod": "night", "from": Vector3(-20, 18, 66), "to": Vector3(-4, 9, 44), "look": Vector3(4, 8, 0)},
	{"district": "heartland", "tod": "sunset", "from": Vector3(22, 24, 66), "to": Vector3(6, 11, 42), "look": Vector3(-2, 12, 0)},
]

var _views: Array[SubViewport] = []
var _cams: Array[Camera3D] = []
var _lumens: Array[Node3D] = []
var _cities: Array = []
var _shot := -1
var _t := 0.0
var _len := 2.6
var built := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	# Drawn a little under screen size: it moves fast and sits under a dark grade anyway.
	stretch_shrink = 2 if int(Settings.gfx.get("detail", 2)) < 2 else 1
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0


## Build the four worlds, one per frame (the screen is dark while it happens).
func build_all() -> void:
	for i in SHOTS.size():
		var s: Dictionary = SHOTS[i]
		var vp := SubViewport.new()
		vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.msaa_3d = Settings.small_view_msaa()
		vp.audio_listener_enable_3d = false
		add_child(vp)
		var d: Dictionary = RoamData.district(str(s["district"]))
		var city: CityBuilder
		match str(d.get("builder", "")):
			"academy":
				city = AcademyBuilder.new()
			"arena":
				city = ArenaDistrict.new()
			"newdomino":
				city = NewDominoBuilder.new()
			_:
				city = CityBuilder.new()
		city.make_solid = false
		vp.add_child(city)
		var t0 := Time.get_ticks_msec()
		city.build(FieldThemes.resolve(str(d.get("theme", "battlecity")), ""), str(s["tod"]))
		city.grade(str(s["district"]))
		PerfPass.settle(city)
		if "--intro-log" in OS.get_cmdline_user_args():
			print("INTRO built %s in %d ms" % [s["district"], Time.get_ticks_msec() - t0])
		var cam := Camera3D.new()
		cam.fov = 58
		cam.far = 400.0
		vp.add_child(cam)
		cam.current = true
		var lu := LumenSpirit.new()
		lu.size = 1.25
		vp.add_child(lu)
		var glow := OmniLight3D.new()
		glow.light_color = Color(0.6, 0.92, 1.0)
		glow.light_energy = 3.0
		glow.omni_range = 9.0
		lu.add_child(glow)
		_views.append(vp)
		_cams.append(cam)
		_lumens.append(lu)
		_cities.append(city)
		vp.process_mode = Node.PROCESS_MODE_DISABLED
		await get_tree().process_frame
		if not is_inside_tree():
			return
	built = true


## Cut to world `i` for `seconds`.
func show_shot(i: int, seconds: float) -> void:
	if not built or i < 0 or i >= _views.size():
		return
	for k in _views.size():
		var on := k == i
		_views[k].render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
		_views[k].process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	_shot = i
	_t = 0.0
	_len = seconds
	modulate.a = 1.0
	_place(0.0)


func stop() -> void:
	_shot = -1
	for v in _views:
		v.render_target_update_mode = SubViewport.UPDATE_DISABLED
		v.process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if _shot < 0:
		return
	_t += delta
	_place(clampf(_t / _len, 0.0, 1.2))


## The camera glides from `from` to `to` (easing out), and Lumen races ahead of it toward the
## spot it looks at, weaving a little.
func _place(k: float) -> void:
	var s: Dictionary = SHOTS[_shot]
	var e := 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 2.2)
	var a: Vector3 = s["from"]
	var b: Vector3 = s["to"]
	var look: Vector3 = s["look"]
	var cam := _cams[_shot]
	cam.position = a.lerp(b, e) + Vector3(0, sin(k * PI) * 1.5, 0)
	cam.look_at(look.lerp(look + Vector3(0, -1.5, 0), e))
	var fwd := -cam.global_transform.basis.z
	var right := cam.global_transform.basis.x
	var lu := _lumens[_shot]
	var ahead := 2.4 + 6.0 * k
	lu.position = cam.position + fwd * ahead + right * sin(k * 6.0) * 0.9 + Vector3(0, -0.6 + cos(k * 5.0) * 0.4, 0)
	lu.look_at(lu.position + fwd, Vector3.UP)
