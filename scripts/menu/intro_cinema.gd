class_name IntroCinema
extends Control
## The opening's flight over the four worlds: each era's world built with the game's own
## builders, at its own time of day, a camera sweeping over it and Lumen racing ahead.
## Every world lives in its own off-screen picture. Only the one on screen is drawn, a picture
## is never shown before it has been drawn (an undrawn one is noise on some graphics cards),
## and one world fades into the next.

## The camera glides from `from` to `to`, looking at `look` (all around where you arrive).
const SHOTS := [
	{"district": "domino", "tod": "night", "from": Vector3(-23, 19, 33), "to": Vector3(-3, 12, 20), "look": Vector3(4, 4, -12)},
	{"district": "academy", "tod": "day", "from": Vector3(18, 26, 96), "to": Vector3(4, 12, 66), "look": Vector3(0, 8, 10)},
	{"district": "newdomino", "tod": "night", "from": Vector3(-20, 18, 66), "to": Vector3(-4, 9, 44), "look": Vector3(4, 8, 0)},
	{"district": "heartland", "tod": "sunset", "from": Vector3(22, 24, 66), "to": Vector3(6, 11, 42), "look": Vector3(-2, 12, 0)},
]
## Behind the title: Domino City at night again, from high up, drifting slowly.
const FINALE := {"view": 0, "from": Vector3(-16, 30, 56), "to": Vector3(10, 36, 50), "look": Vector3(0, 9, -14)}

var built := false
var _views: Array[SubViewport] = []
var _rects: Array[TextureRect] = []
var _cams: Array[Camera3D] = []
var _lumens: Array[Node3D] = []
var _scrim: ColorRect            # darkens the picture when words go over it
var _live := {}                  # which world is being drawn: index -> {t, len, path}
var _top := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim = ColorRect.new()
	_scrim.color = Color(0.008, 0.012, 0.035, 0.0)
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)


## As sharp as the screen, up to 1440 lines (it moves fast, and four of them are kept).
func _view_size() -> Vector2i:
	var win := Vector2(DisplayServer.window_get_size())
	if win.x < 16.0 or win.y < 16.0:
		win = Vector2(1920, 1080)
	var k := minf(1.0, 1440.0 / win.y)
	if int(Settings.gfx.get("detail", 2)) < 1:
		k *= 0.6
	return Vector2i(maxi(320, int(win.x * k)), maxi(180, int(win.y * k)))


## Build the four worlds and draw each one a few times (the screen is dark while it happens),
## so nothing has to be prepared in the middle of the show.
func build_all() -> void:
	var px := _view_size()
	for i in SHOTS.size():
		var s: Dictionary = SHOTS[i]
		var vp := SubViewport.new()
		vp.own_world_3d = true
		vp.size = px
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
			print("INTRO built %s in %d ms at %s" % [s["district"], Time.get_ticks_msec() - t0, px])
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
		var r := TextureRect.new()
		r.texture = vp.get_texture()
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.visible = false
		add_child(r)
		_views.append(vp)
		_cams.append(cam)
		_lumens.append(lu)
		_rects.append(r)
		# Drawn now, unseen: the picture is real before anybody looks at it.
		_live[i] = {"t": 0.0, "len": 3.0, "path": s}
		_pose(i)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		for f in 3:
			await get_tree().process_frame
			if not is_inside_tree():
				return
		_live.erase(i)
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.process_mode = Node.PROCESS_MODE_DISABLED
	move_child(_scrim, -1)
	built = true


## Fade to world `i` and fly over it for `seconds`.
func show_shot(i: int, seconds: float, fade := 0.4) -> void:
	if i >= 0 and i < SHOTS.size():
		_cut(i, SHOTS[i], seconds, fade, true)


## The picture behind the title: the city from high up, dimmed, drifting slowly.
func finale(fade := 1.2) -> void:
	_cut(int(FINALE["view"]), FINALE, 40.0, fade, false)
	dim(0.74, fade)


func dim(alpha: float, seconds := 0.5) -> void:
	create_tween().tween_property(_scrim, "color:a", alpha, seconds)


func _cut(v: int, path: Dictionary, seconds: float, fade: float, lumen: bool) -> void:
	if not built:
		return
	var same := _top == v and _live.has(v)
	_live[v] = {"t": 0.0, "len": seconds, "path": path}
	_top = v
	_views[v].render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_views[v].process_mode = Node.PROCESS_MODE_INHERIT
	_lumens[v].visible = lumen
	_pose(v)
	var r := _rects[v]
	move_child(r, -1)
	move_child(_scrim, -1)
	r.visible = true
	if not same:
		r.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 1.0, fade)
	tw.tween_callback(_drop_others)


## Whatever is under the picture on top is not seen anymore: stop drawing it.
func _drop_others() -> void:
	for k in _live.keys():
		if int(k) != _top:
			_off(int(k))


func _off(k: int) -> void:
	_views[k].render_target_update_mode = SubViewport.UPDATE_DISABLED
	_views[k].process_mode = Node.PROCESS_MODE_DISABLED
	_rects[k].visible = false
	_live.erase(k)


## Hold the picture as it is (it stays on screen, nothing is drawn anymore).
func freeze() -> void:
	for k in _live.keys():
		_views[int(k)].render_target_update_mode = SubViewport.UPDATE_DISABLED
		_views[int(k)].process_mode = Node.PROCESS_MODE_DISABLED
	_live.clear()


func _process(delta: float) -> void:
	for k in _live.keys():
		_live[k]["t"] = float(_live[k]["t"]) + delta
		_pose(int(k))


## The camera glides from `from` to `to` (easing out, banking a little, the lens closing in),
## and Lumen races ahead of it, weaving.
func _pose(v: int) -> void:
	var d: Dictionary = _live[v]
	var s: Dictionary = d["path"]
	var k := float(d["t"]) / maxf(0.1, float(d["len"]))
	var kc := clampf(k, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - kc, 2.2)
	var a: Vector3 = s["from"]
	var b: Vector3 = s["to"]
	var look: Vector3 = s["look"]
	var cam := _cams[v]
	cam.position = a.lerp(b, e) + Vector3(0, sin(kc * PI) * 1.5, 0)
	cam.look_at(look.lerp(look + Vector3(0, -1.5, 0), e))
	cam.rotate_object_local(Vector3.FORWARD, sin(kc * PI) * 0.045 * (1.0 if v % 2 == 0 else -1.0))
	cam.fov = lerpf(60.0, 52.0, e)
	var lu := _lumens[v]
	if lu.visible:
		var fwd := -cam.global_transform.basis.z
		var right := cam.global_transform.basis.x
		var ahead := 2.4 + 6.0 * k
		lu.position = cam.position + fwd * ahead + right * sin(k * 6.0) * 0.9 + Vector3(0, -0.6 + cos(k * 5.0) * 0.4, 0)
		lu.look_at(lu.position + fwd, Vector3.UP)
