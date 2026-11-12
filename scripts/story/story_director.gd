class_name StoryDirector
extends Node
## Runs a story chapter inside the walking world. It places the cast, takes the camera for
## cutscenes, shows the dialogue, hands control back for "walk there" goals with a marker and
## a NEXT GOAL panel, starts story duels and picks the chapter up again afterwards.
##
## Step kinds (see StoryData):
##   {"scene": {...}}      move to a place (district, inside, pos, yaw, tod), with a title card
##   {"actor": key, "at": Vector3, "face": yaw|"player", "from": Vector3, "spirit": bool, "hollow": bool}
##   {"move": key, "to": Vector3, "run": bool, "wait": bool}
##   {"gone": key}
##   {"s": key, "t": text, "fx": "flash"|"shake", "anim": "cheer", "cam": "wide"}
##   {"choice": [[text, flag], ...]}
##   {"goal": text, "at": Vector3, "r": 2.5, "who": key}
##   {"duel": {...}}
##   {"fx": "flash"|"shake"|"rift"|"freeze"|"unfreeze", "at": Vector3}
##   {"tod": "night"}      change the time of day
##   {"bond": name, "card": id, "text": ...}
##   {"wait": seconds}
##   {"end": title, "unlock": id}

var scene                       # RoamScene
var chapter := ""
var step := 0
var flags := {}
var _steps: Array = []
var _actors := {}               # key -> RoamFigure
var _spirit: Node3D             # Lumen's holder (hovers)
var _cam: Camera3D
var _fill: OmniLight3D
var _cut := false               # a cutscene has the camera
var _busy := false
var _advance_wanted := false
var _skip := false
var _auto := false              # --story-auto: play the chapter by itself (for testing)
var _goal := {}
var _shake := 0.0
var _cam_pos := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _shot_side := 1.0
var _last_other := ""          # who the player was last talking with
var _spirit_park = null         # where Lumen hovers during a shot (Vector3 or null)
var _t := 0.0
var _rift: Node3D
var _moving: Array = []         # [fig, to, speed]
# UI
var _ui: Control
var _bars: Array = []
var _box: PanelContainer
var _name: Label
var _text: RichTextLabel
var _more: Label
var _portrait: TextureRect
var _goal_box: PanelContainer
var _goal_text: Label
var _goal_dist: Label
var _flash: ColorRect
var _card: Control
var _typing: Tween
var _choice_box: VBoxContainer


func _ready() -> void:
	_auto = "--story-auto" in OS.get_cmdline_user_args()
	chapter = str(Router.roam.get("story", ""))
	_steps = StoryData.SCRIPTS.get(chapter, [])
	var pos := StoryProgress.position()
	if str(pos["chapter"]) == chapter:
		step = int(pos["step"])
		flags = pos["flags"]
	_cam = Camera3D.new()
	_cam.fov = 46.0
	add_child(_cam)
	# A soft light that rides on the cutscene camera, so faces read at night and indoors.
	_fill = OmniLight3D.new()
	_fill.omni_attenuation = 0.6
	_fill.shadow_enabled = false
	_fill.visible = false
	_cam.add_child(_fill)
	_build_ui()
	# Portraits are drawn live from the models: start them now so nobody's first line shows
	# an empty frame.
	Portraits.get_portrait("player")
	var seen := {}
	for st in _steps:
		var who := str((st as Dictionary).get("s", ""))
		if who != "" and who != "player" and not seen.has(who) and seen.size() < 4:
			seen[who] = true
			Portraits.get_portrait(who)
	# Coming back from a story duel: note how it went and move on.
	if Router.story_result != "":
		flags.erase("won")
		flags.erase("lost")
		flags[Router.story_result] = true
		Router.story_result = ""
		step += 1
	_rebuild_cast()
	_run.call_deferred()


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.theme = UITheme.build()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 1)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.custom_minimum_size = Vector2(0, 0)
		bar.offset_bottom = 0.0 if top else 0.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(bar)
		_bars.append(bar)
	# Dialogue box.
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.1, 0.92), 20, Color(1, 1, 1, 0.14)))
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 220
	_box.offset_right = -220
	_box.offset_top = -268
	_box.offset_bottom = -92
	_box.visible = false
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_advance_wanted = true)
	_ui.add_child(_box)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 22)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(120, 132)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_portrait)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	_name = UITheme.label("", 26, UITheme.ACCENT, UITheme.title_font())
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 25)
	_text.add_theme_font_size_override("italics_font_size", 25)
	_text.add_theme_color_override("default_color", UITheme.TEXT)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_text)
	_more = UITheme.label("▼", 22, UITheme.ACCENT)
	_more.size_flags_vertical = Control.SIZE_SHRINK_END
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_more)
	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_choice_box.offset_left = -360
	_choice_box.offset_right = 360
	_choice_box.offset_top = -150
	_choice_box.add_theme_constant_override("separation", 14)
	_ui.add_child(_choice_box)
	# NEXT GOAL panel.
	_goal_box = PanelContainer.new()
	_goal_box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.1, 0.86), 16, Color(UITheme.GOLD, 0.6)))
	_goal_box.position = Vector2(44, 168)
	_goal_box.custom_minimum_size = Vector2(430, 0)
	_goal_box.visible = false
	_goal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_goal_box)
	var gm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		gm.add_theme_constant_override("margin_" + side, 16)
	_goal_box.add_child(gm)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 2)
	gm.add_child(gv)
	gv.add_child(UITheme.label("NEXT GOAL", 15, UITheme.GOLD, UITheme.semi_font()))
	_goal_text = UITheme.label("", 23, Color.WHITE, UITheme.semi_font())
	_goal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_text.custom_minimum_size = Vector2(390, 0)
	gv.add_child(_goal_text)
	_goal_dist = UITheme.label("", 17, UITheme.TEXT_DIM)
	gv.add_child(_goal_dist)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_flash)
	var skip := UITheme.label("Space / A  next        Tab  skip scene", 15, Color(1, 1, 1, 0.45))
	skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -420
	skip.offset_top = -80
	skip.offset_right = -40
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.name = "SkipHint"
	skip.visible = false
	_ui.add_child(skip)


func _letterbox(on: bool) -> void:
	for i in 2:
		var bar: ColorRect = _bars[i]
		var tw := create_tween()
		if i == 0:
			tw.tween_property(bar, "offset_bottom", 78.0 if on else 0.0, 0.35)
		else:
			tw.tween_property(bar, "offset_top", -78.0 if on else 0.0, 0.35)
	(_ui.get_node("SkipHint") as Control).visible = on


# ------------------------------------------------------------------ cast

func _player_fig() -> RoamFigure:
	return scene._figure


## Whoever is talking moves their hands; everybody else stands and listens.
func _speaker(who: String) -> void:
	for k in _actors.keys() + ["player"]:
		var f := _fig(str(k))
		if f is RoamFigure and is_instance_valid(f):
			(f as RoamFigure).speak(str(k) == who and who != "")


func _fig(key: String) -> Node3D:
	if key == "player":
		return scene._figure
	return _actors.get(key)


func _pos_of(key: String) -> Vector3:
	if key == "player":
		return scene._player.global_position
	var f = _actors.get(key)
	return f.global_position if f else scene._player.global_position


## Put back everyone who should be standing around at this point of the chapter (after a
## duel or a reload the world starts empty).
func _rebuild_cast() -> void:
	var last_scene := -1
	for i in mini(step, _steps.size()):
		if (_steps[i] as Dictionary).has("scene"):
			last_scene = i
	for i in range(maxi(0, last_scene), mini(step, _steps.size())):
		var st: Dictionary = _steps[i]
		if st.has("if") and not flags.has(st["if"]):
			continue
		if st.has("actor"):
			_place(st, true)
		elif st.has("move") and _actors.has(st["move"]):
			(_actors[st["move"]] as Node3D).global_position = st["to"]
		elif st.has("gone"):
			_remove(str(st["gone"]))
		elif st.has("fx") and st["fx"] == "freeze":
			_freeze(true)
		elif st.has("fx") and st["fx"] == "unfreeze":
			_freeze(false)
		elif st.has("tod"):
			scene.city.apply_tod(str(st["tod"]))


func _place(st: Dictionary, instant := false) -> void:
	var key := str(st["actor"])
	_remove(key)
	var fig := RoamFigure.new()
	scene.add_child(fig)
	var at: Vector3 = st["at"]
	fig.position = st.get("from", at) if not instant else at
	fig.setup(key, Characters.get_char(key).get("color", Color.WHITE), "", false)
	fig.lively = false
	fig.greets = false
	fig.watch = scene._player
	_actors[key] = fig
	var face = st.get("face", "player")
	if face is String:
		var to: Vector3 = _pos_of(str(face)) - at
		fig.rotation.y = atan2(to.x, to.z)
	else:
		fig.rotation.y = float(face)
	if st.get("spirit", false):
		# A duel spirit: small, glowing, floating at shoulder height.
		fig.scale = Vector3.ONE * 0.55
		fig.position.y = 1.1
		var l := OmniLight3D.new()
		l.light_color = Color("9ff0ff")
		l.light_energy = 1.1
		l.omni_range = 4.0
		l.position.y = 1.0
		fig.add_child(l)
		var halo := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.8
		sm.height = 1.6
		halo.mesh = sm
		var hm := StandardMaterial3D.new()
		hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hm.albedo_color = Color(0.5, 0.95, 1.0, 0.1)
		hm.cull_mode = BaseMaterial3D.CULL_FRONT
		halo.material_override = hm
		halo.position.y = 0.95
		fig.add_child(halo)
		_spirit = fig
	if st.get("hollow", false):
		_make_hollow(fig)
	if not instant and st.has("from"):
		_moving.append([fig, at, 3.6 if st.get("run", false) else 1.7, face])
	elif not instant and not st.get("hollow", false):
		# Pop in with a little scale-up so nobody just appears.
		var s := fig.scale
		fig.scale = s * 0.01
		create_tween().tween_property(fig, "scale", s, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A person frozen inside one memory: stock-still, washed out, with a slow violet pulse.
func _make_hollow(fig: RoamFigure) -> void:
	fig.set_process(false)
	var ap := Avatars.anim_player(fig._model) if fig._model else null
	if ap:
		ap.speed_scale = 0.0
	var l := OmniLight3D.new()
	l.light_color = Color("b06cff")
	l.light_energy = 1.6
	l.omni_range = 3.5
	l.position.y = 1.2
	fig.add_child(l)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.62
	tm.outer_radius = 0.7
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color("b06cff")
	rm.emission_enabled = true
	rm.emission = Color("b06cff")
	rm.emission_energy_multiplier = 2.5
	ring.material_override = rm
	ring.position.y = 0.06
	ring.scale = Vector3(1, 0.2, 1)
	fig.add_child(ring)
	var tw := ring.create_tween().set_loops()
	tw.tween_property(ring, "scale", Vector3(1.25, 0.2, 1.25), 1.2)
	tw.tween_property(ring, "scale", Vector3(1, 0.2, 1), 1.2)


func _remove(key: String) -> void:
	if _actors.has(key):
		var f: Node3D = _actors[key]
		if is_instance_valid(f):
			f.queue_free()
		_actors.erase(key)
		_moving = _moving.filter(func(m): return m[0] != f)


## The Hollows: everybody on the street stops dead.
func _freeze(on: bool) -> void:
	scene.walkers_frozen = on
	for w in scene._walkers:
		var f: RoamFigure = w["fig"]
		var ap := Avatars.anim_player(f._model) if f._model else null
		if ap:
			ap.speed_scale = 0.0 if on else 1.0
		f.set_process(not on)


# ------------------------------------------------------------------ running the script

func _run() -> void:
	if _steps.is_empty():
		_leave()
		return
	while step < _steps.size():
		var st: Dictionary = _steps[step]
		if st.has("if") and not flags.has(st["if"]):
			step += 1
			continue
		if _auto:
			print("STORY step ", step, " ", st.keys())
		if st.has("scene"):
			if await _do_scene(st):
				return
		elif st.has("actor"):
			_place(st)
			if st.has("from") and st.get("wait", true):
				await _until_arrived(_actors[str(st["actor"])])
		elif st.has("move"):
			var f = _actors.get(str(st["move"]))
			if f:
				_moving.append([f, st["to"], 3.8 if st.get("run", false) else 1.8, st.get("face", null)])
				if st.get("wait", false):
					await _until_arrived(f)
		elif st.has("gone"):
			_remove(str(st["gone"]))
		elif st.has("t"):
			await _say(st)
		elif st.has("choice"):
			await _choose(st["choice"])
		elif st.has("goal"):
			StoryProgress.save_position(chapter, step, flags)
			await _do_goal(st)
		elif st.has("duel"):
			if _auto and not "--story-duel" in OS.get_cmdline_user_args():
				if "--story-versus" in OS.get_cmdline_user_args():
					_cutscene(true)
					_box.visible = false
					await _versus(str(st["duel"]["opponent"]))
					await _snap("vs")
					_ui.get_child(_ui.get_child_count() - 1).queue_free()
					_cut = true
				flags["won"] = true
				print("STORY: duel skipped (auto) vs ", st["duel"]["opponent"])
			else:
				_start_duel(st["duel"])
				return
		elif st.has("fx"):
			await _fx(st)
		elif st.has("tod"):
			scene.city.apply_tod(str(st["tod"]))
		elif st.has("bond"):
			await _bond(st)
		elif st.has("wait"):
			if not _skip:
				await get_tree().create_timer(float(st["wait"])).timeout
		elif st.has("end"):
			await _end(st)
			return
		step += 1
	_leave()


## The walking HUD (map, place name, key help) steps aside for cutscenes.
func _hud(on: bool) -> void:
	for n in [scene._map, scene._loc_name, scene._loc_area, scene._prompt, scene._plate, scene._purse]:
		if n and is_instance_valid(n):
			n.visible = on
	if scene.extras and scene.extras._hud:
		scene.extras._hud.visible = on
	if scene._help:
		scene._help.visible = on


func _until_arrived(f: Node3D) -> void:
	var guard := 0.0
	while guard < 14.0 and _moving.any(func(m): return m[0] == f):
		if _skip:
			for m in _moving:
				if m[0] == f:
					(m[0] as Node3D).global_position = m[1]
			_moving = _moving.filter(func(m): return m[0] != f)
			break
		await get_tree().process_frame
		guard += get_process_delta_time()


func _cutscene(on: bool) -> void:
	if on == _cut:
		return
	_cut = on
	scene._overlay_open = on
	_letterbox(on)
	if on:
		_cam.global_transform = scene._cam.global_transform
		_cam_pos = _cam.global_position
		_cam_look = scene._player.global_position + Vector3(0, 1.4, 0)
		_cam.current = true
		_goal_box.visible = false
		_hud(false)
	else:
		_speaker("")
		_hud(true)
		_fill.visible = false
		scene._cam.current = true
		_box.visible = false
		_skip = false


# ------------------------------------------------------------------ steps

func _do_scene(st: Dictionary) -> bool:
	var sc: Dictionary = st["scene"]
	var district := str(sc.get("district", Router.roam.get("district", "domino")))
	if district != str(Router.roam.get("district", "domino")):
		# Another world: reload there and carry on from the next step.
		StoryProgress.save_position(chapter, step, flags)
		Router.roam["district"] = district
		Router.roam["pos"] = sc.get("pos", null)
		if sc.has("yaw"):
			Router.roam["yaw"] = sc["yaw"]
		if sc.has("tod"):
			Router.roam["tod"] = sc["tod"]
		Router.go(Router.ROAM)
		return true
	_cutscene(true)
	var tw := create_tween()
	tw.tween_property(_flash, "color", Color(0, 0, 0, 1), 0.35)
	await tw.finished
	for k in _actors.keys():
		_remove(k)
	_freeze(false)
	if sc.has("tod"):
		scene.city.apply_tod(str(sc["tod"]))
		Router.roam["tod"] = sc["tod"]
	var inside := str(sc.get("inside", ""))
	var pos: Vector3 = sc.get("pos", scene._player.position)
	scene._player.position = pos
	scene._player.velocity = Vector3.ZERO
	scene._yaw = float(sc.get("yaw", scene._yaw))
	scene._figure.rotation.y = scene._yaw + PI
	scene._pivot.position = pos + Vector3(0, 1.45, 0)
	scene._pivot.rotation = Vector3(scene._pitch, scene._yaw, 0)
	scene._set_inside(inside)
	if sc.has("music"):
		Music.play(str(sc["music"]))
	_cam_pos = pos + Basis(Vector3.UP, scene._yaw) * Vector3(2.4, 2.2, 5.0)
	_cam_look = pos + Vector3(0, 1.3, 0)
	_cam.global_position = _cam_pos
	await get_tree().create_timer(0.25).timeout
	# Title card over black, then fade in on the new place.
	if st.has("title") and not _skip:
		await _title_card(str(st["title"]), str(st.get("sub", "")), str(st.get("chapter", "")))
	var tw2 := create_tween()
	tw2.tween_property(_flash, "color", Color(0, 0, 0, 0), 0.6)
	await tw2.finished
	return false


func _title_card(title: String, sub: String, chapter_line: String) -> void:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -700
	v.offset_right = 700
	v.offset_top = -110
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.modulate.a = 0.0
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(v)
	if chapter_line != "":
		var c := UITheme.label(Loc.t(chapter_line).to_upper(), 24, UITheme.GOLD, UITheme.semi_font())
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(c)
	var t := UITheme.label(Loc.t(title).to_upper(), 72 if chapter_line != "" else 60, Color.WHITE, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var line := ColorRect.new()
	line.color = UITheme.ACCENT
	line.custom_minimum_size = Vector2(0, 3)
	v.add_child(line)
	var s := UITheme.label(Loc.t(sub), 26, UITheme.TEXT_DIM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	Sfx.play("gong", -8.0)
	var tw := create_tween()
	tw.tween_property(v, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.9 if chapter_line != "" else 1.4)
	tw.tween_property(v, "modulate:a", 0.0, 0.5)
	await tw.finished
	v.queue_free()


func _shot_for(speaker: String, wide: bool) -> void:
	# Frame whoever is talking: a little to one side, at eye level, the listener's shoulder
	# just out of frame. Sides alternate so a conversation cuts back and forth.
	var at := _pos_of(speaker if speaker != "" else "player")
	var f := _fig(speaker if speaker != "" else "player")
	var facing := Vector3(sin(f.rotation.y), 0, cos(f.rotation.y)) if f else Vector3.FORWARD
	if speaker == "player" and scene._figure:
		facing = Vector3(sin(scene._figure.rotation.y), 0, cos(scene._figure.rotation.y))
	var right := facing.cross(Vector3.UP).normalized()
	var eye := 1.5
	if f == _spirit and _spirit:
		eye = 0.82
	var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	if wide or speaker == "":
		# Everyone nearby in one frame, from a little above, drifting slowly round them.
		var here: Vector3 = scene._player.global_position
		var mid: Vector3 = here
		var n := 1
		var spread := 2.5
		for k in _actors:
			var ap: Vector3 = (_actors[k] as Node3D).global_position
			var d := Vector2(ap.x - here.x, ap.z - here.z).length()
			if d > 12.0:
				continue
			mid += ap
			n += 1
			spread = maxf(spread, d)
		mid /= float(n)
		mid.y = 0.0
		var look_w := mid + Vector3(0, 1.25, 0)
		var best_w := look_w + Vector3(0, 2.0, 4.0)
		var best_len := -1.0
		# Try a few directions and keep the one with the clearest view (indoors most are walls).
		for i in 8:
			var ang := _t * 0.05 + 0.6 + float(i) * TAU / 8.0
			var want_w := mid + Basis(Vector3.UP, ang) * Vector3(0, 2.6 + spread * 0.12, 4.2 + spread * 0.75)
			var qw := PhysicsRayQueryParameters3D.create(look_w, want_w)
			qw.exclude = [scene._player.get_rid()]
			var hw := space.intersect_ray(qw)
			var reach := look_w.distance_to(want_w)
			if not hw.is_empty():
				reach = look_w.distance_to(hw["position"]) * 0.88
				want_w = look_w + (want_w - look_w).normalized() * reach
			if reach > best_len + 0.4:
				best_len = reach
				best_w = want_w
			if hw.is_empty():
				break
		_cam_pos = best_w
		_cam_look = look_w
		_spirit_park = null
		return
	_shot_side = -_shot_side
	# Over the shoulder: the camera stands just behind whoever is listening.
	var listener: Vector3 = scene._player.global_position
	if speaker == "player":
		# The player answers whoever spoke last; failing that, the nearest person.
		var best := 99.0
		listener = at + facing * 2.6
		if _last_other != "" and _actors.has(_last_other):
			listener = (_actors[_last_other] as Node3D).global_position
		else:
			for k in _actors:
				if _actors[k] == _spirit and _actors.size() > 1:
					continue
				var p: Vector3 = (_actors[k] as Node3D).global_position
				var d := Vector2(p.x - at.x, p.z - at.z).length()
				if d < best and d > 0.3:
					best = d
					listener = p
	elif speaker != "":
		_last_other = speaker
	var away := Vector3(listener.x - at.x, 0, listener.z - at.z)
	if away.length() < 0.4:
		away = facing
	var is_spirit: bool = _spirit != null and f == _spirit
	var dist := clampf(away.length(), 1.4, 2.3)
	away = away.normalized()
	right = away.cross(Vector3.UP).normalized()
	var look := Vector3(at.x, (f.global_position.y if is_spirit else 0.0) + eye, at.z)
	# A little above eye level, looking slightly down: clears tills and other counter clutter.
	var lift := 0.15 if is_spirit else 0.42
	var want := Vector3(at.x, 0, at.z) + away * (dist + (0.4 if is_spirit else 1.1)) + right * 0.7 * _shot_side + Vector3(0, look.y + lift, 0)
	# Never put the camera inside a wall or a shelf: pull it in until the view is clear.
	var from := look + Vector3(0, lift, 0)
	var q := PhysicsRayQueryParameters3D.create(from, want)
	q.exclude = [scene._player.get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty() and from.distance_to(hit["position"]) < 1.5:
		# Something right beside the speaker (a counter, a railing): shoot from the other
		# shoulder and higher up instead of pushing the lens into it.
		_shot_side = -_shot_side
		want = Vector3(at.x, 0, at.z) + away * (dist + 1.1) + right * 0.7 * _shot_side + Vector3(0, look.y + lift + 0.5, 0)
		from = look + Vector3(0, lift + 0.5, 0)
		q = PhysicsRayQueryParameters3D.create(from, want)
		q.exclude = [scene._player.get_rid()]
		hit = space.intersect_ray(q)
	if _auto and "--story-rays" in OS.get_cmdline_user_args():
		print("RAY step ", step, " speaker=", speaker, " from=", from.snapped(Vector3(0.1, 0.1, 0.1)), " want=", want.snapped(Vector3(0.1, 0.1, 0.1)), " hit=", (hit["position"] as Vector3).snapped(Vector3(0.1, 0.1, 0.1)) if not hit.is_empty() else "none", " ", (hit["collider"] as Node).get_parent().name if not hit.is_empty() else "")
	if not hit.is_empty():
		var hp: Vector3 = hit["position"]
		want = from + (hp - from) * 0.86
		if want.distance_to(from) < 1.1:
			want = from + (want - from).normalized() * 1.1
	_cam_pos = want
	_cam_look = look
	# Lumen keeps out of the lens: she hovers beside the conversation, on the far side.
	_spirit_park = null
	if _spirit and is_instance_valid(_spirit) and not is_spirit:
		var d2 := Vector3(listener.x - at.x, 0, listener.z - at.z)
		_spirit_park = Vector3(at.x, 0, at.z) + d2 * 0.2 - right * _shot_side * 1.5


## A character's portrait. They are drawn live from the model, and that little stage can be
## thrown away behind our back (a new look, a settings change), so make sure it still exists.
func _face(key: String) -> Texture2D:
	var tex := Portraits.get_portrait(key)
	if tex is ViewportTexture and not Avatars._stages.has(key):
		Portraits._forget(key)
		tex = Portraits.get_portrait(key)
	return tex


func _face_each_other(speaker: String) -> void:
	if speaker == "" or speaker == "player":
		return
	var f := _fig(speaker)
	if f == null or f.is_processing() == false:
		return
	var to: Vector3 = scene._player.global_position - f.global_position
	var tw := create_tween()
	tw.tween_property(f, "rotation:y", lerp_angle(f.rotation.y, atan2(to.x, to.z), 1.0), 0.3)
	var back: Vector3 = f.global_position - scene._player.global_position
	create_tween().tween_property(scene._figure, "rotation:y", lerp_angle(scene._figure.rotation.y, atan2(back.x, back.z), 1.0), 0.3)


func _light_shot() -> void:
	var tod: String = scene.city.tod if scene.city else "day"
	var inside: bool = scene._inside != ""
	_fill.visible = _cut and (inside or tod != "day")
	_fill.light_color = Color(1.0, 0.93, 0.82) if inside else (Color(0.78, 0.85, 1.0) if tod == "night" else Color(1.0, 0.86, 0.72))
	_fill.light_energy = 1.3 if inside else (1.5 if tod == "night" else 0.7)
	_fill.omni_range = 9.0 if inside else 14.0


func _say(st: Dictionary) -> void:
	_cutscene(true)
	_light_shot()
	var who := str(st.get("s", ""))
	_face_each_other(who)
	_speaker(who if not st.has("anim") else "")
	_shot_for(who, st.get("cam", "") == "wide")
	if st.has("fx"):
		_do_flash_or_shake(str(st["fx"]))
	var info := Characters.get_char(who) if who != "" and who != "player" else {}
	var text := Loc.t(str(st["t"])).replace("{player}", Profile.duelist_name)
	_box.visible = true
	_more.visible = false
	if who == "":
		_name.text = ""
		_portrait.visible = false
		_text.text = "[i]%s[/i]" % text
	else:
		_name.text = (Profile.duelist_name if who == "player" else Loc.t(str(info.get("name", who)))).to_upper()
		_name.add_theme_color_override("font_color", Profile.color() if who == "player" else Color(info.get("color", UITheme.ACCENT)).lightened(0.25))
		_portrait.visible = true
		_portrait.texture = _face(who)
		_text.text = text
	if st.has("emote"):
		_emote(who, str(st["emote"]))
	if st.has("anim"):
		var f := _fig(who)
		if f is RoamFigure:
			(f as RoamFigure).play_once("victory" if st["anim"] == "cheer" else str(st["anim"]))
	if _skip:
		return
	_text.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, maxf(0.25, text.length() * 0.018))
	var blips := 0
	_advance_wanted = false
	while _text.visible_ratio < 1.0:
		await get_tree().process_frame
		blips += 1
		if blips % 5 == 0 and who != "":
			Sfx.play("blip", -14.0, 1.25 if who == "lumen" else (0.85 if who in ["kaiba", "kairo", "hunter"] else 1.0))
		if _advance_wanted or _skip:
			_typing.kill()
			_text.visible_ratio = 1.0
	_more.visible = true
	_advance_wanted = false
	if _auto:
		await get_tree().create_timer(0.5).timeout
		# --story-shots=3,17,40 saves a picture of those steps (for checking the staging).
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--story-shots=") and str(step) in a.trim_prefix("--story-shots=").split(","):
				await get_tree().create_timer(1.6).timeout
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("/tmp/story_%s_%d.png" % [chapter, step])
				print("STORY shot ", step)
		return
	while not _advance_wanted and not _skip:
		await get_tree().process_frame
	_advance_wanted = false
	Sfx.play("click", -10.0)


## A little reaction that pops over someone's head: "!", "?", "...", a heart, a spark.
func _emote(who: String, mark: String) -> void:
	var f := _fig(who if who != "" else "player")
	if f == null or _skip:
		return
	var l := Label3D.new()
	l.text = mark
	l.font = UITheme.title_font()
	l.font_size = 150
	l.outline_size = 34
	l.modulate = {"!": Color("ffd166"), "?": Color("7cc4ff"), "...": Color(0.9, 0.9, 0.95), "♪": Color("7dffb0"), "#": Color("ff5a5a")}.get(mark, Color.WHITE)
	l.outline_modulate = Color(0.05, 0.06, 0.1)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.shaded = false
	l.pixel_size = 0.0034
	scene.add_child(l)
	var base: Vector3 = f.global_position + Vector3(0, 2.05 * f.scale.y + (0.0 if f != _spirit else 0.15), 0)
	l.global_position = base
	l.scale = Vector3.ONE * 0.05
	Sfx.play("blip", -6.0, 1.6 if mark == "!" else 1.1)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.25, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "global_position", base + Vector3(0, 0.22, 0), 0.12)
	tw.tween_property(l, "scale", Vector3.ONE, 0.1)
	tw.tween_interval(1.1)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)


## The versus card before a story duel: both duelists slide in, VS slams down between them.
func _versus(opp: String) -> void:
	var info := Characters.get_char(opp)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)
	create_tween().tween_property(shade, "color:a", 0.9, 0.25)
	var size := get_viewport().get_visible_rect().size
	var sides := [["player", Profile.duelist_name, Profile.color(), -1.0], [opp, Loc.t(str(info.get("name", opp))), Color(info.get("color", UITheme.ACCENT)), 1.0]]
	for sd in sides:
		var dir: float = sd[3]
		var col: Color = sd[2]
		var band := ColorRect.new()
		band.color = Color(col, 0.22)
		band.size = Vector2(size.x * 0.5, 300)
		band.position = Vector2(size.x * 0.5 if dir > 0.0 else 0.0, size.y * 0.5 - 150) + Vector2(dir * size.x * 0.6, 0)
		shade.add_child(band)
		var edge := ColorRect.new()
		edge.color = col
		edge.size = Vector2(size.x * 0.5, 5)
		edge.position = Vector2(0, 0 if dir > 0.0 else 295)
		band.add_child(edge)
		var pic := TextureRect.new()
		pic.texture = _face(str(sd[0]))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.size = Vector2(280, 280)
		pic.position = Vector2(size.x * 0.25 - 140 + dir * 190, 10)
		pic.flip_h = dir > 0.0
		band.add_child(pic)
		var nm := UITheme.label(str(sd[1]).to_upper(), 46, Color.WHITE, UITheme.title_font())
		nm.position = Vector2(size.x * 0.25 - 20, 108) if dir < 0.0 else Vector2(130, 108)
		nm.size = Vector2(size.x * 0.25 - 110, 60)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if dir < 0.0 else HORIZONTAL_ALIGNMENT_RIGHT
		nm.clip_text = true
		band.add_child(nm)
		var tag := UITheme.label(Loc.t("YOU") if dir < 0.0 else Loc.t(str(info.get("title", "Duelist"))).to_upper(), 20, col.lightened(0.4), UITheme.semi_font())
		tag.position = nm.position + Vector2(0, 58)
		tag.size = nm.size
		tag.horizontal_alignment = nm.horizontal_alignment
		tag.clip_text = true
		band.add_child(tag)
		var tw := create_tween()
		tw.tween_property(band, "position:x", band.position.x - dir * size.x * 0.6, 0.32).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	Sfx.play("whoosh", -4.0)
	await get_tree().create_timer(0.36).timeout
	var vs := UITheme.label("VS", 190, UITheme.GOLD, UITheme.title_font())
	vs.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	vs.add_theme_constant_override("outline_size", 22)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.size = Vector2(400, 240)
	vs.position = size * 0.5 - Vector2(200, 120)
	vs.pivot_offset = Vector2(200, 120)
	vs.scale = Vector2(3.2, 3.2)
	vs.modulate.a = 0.0
	shade.add_child(vs)
	var tv := create_tween()
	tv.tween_property(vs, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tv.parallel().tween_property(vs, "modulate:a", 1.0, 0.1)
	await tv.finished
	_shake = 0.5
	Sfx.play("impact", -2.0, 0.8)
	await get_tree().create_timer(1.15 if not _auto else 0.3).timeout


func _choose(options: Array) -> void:
	_cutscene(true)
	_skip = false
	_box.visible = false
	_shot_for("player", false)
	var picked := [-1]
	for i in options.size():
		var b := Button.new()
		b.text = Loc.t(str(options[i][0]))
		b.custom_minimum_size = Vector2(720, 70)
		b.add_theme_font_size_override("font_size", 25)
		b.pressed.connect(func(): picked[0] = i)
		_choice_box.add_child(b)
		if i == 0:
			b.grab_focus.call_deferred()
	Sfx.play("panel", -6.0)
	if _auto:
		await get_tree().create_timer(0.6).timeout
		picked[0] = 0
	while picked[0] < 0:
		await get_tree().process_frame
	flags[str(options[picked[0]][1])] = true
	for c in _choice_box.get_children():
		c.queue_free()
	Sfx.play("click")
	_advance_wanted = false


func _do_goal(st: Dictionary) -> void:
	_cutscene(false)
	var at: Vector3 = st["at"] if st.has("at") else _pos_of(str(st.get("who", "player")))
	_goal = st
	_goal_text.text = Loc.t(str(st["goal"]))
	_goal_box.visible = true
	_goal_box.modulate.a = 0.0
	create_tween().tween_property(_goal_box, "modulate:a", 1.0, 0.4)
	Sfx.play("quest", -6.0)
	scene.extras.set_waypoint(at, Loc.t(str(st["goal"])))
	# Turn the camera toward where you are meant to go, so the beacon is on screen.
	var to_goal := Vector3(at.x - scene._player.global_position.x, 0, at.z - scene._player.global_position.z)
	if to_goal.length() > 1.5:
		var want_yaw := atan2(-to_goal.x, -to_goal.z)
		var yt := create_tween()
		yt.tween_method(func(v: float): scene._yaw = v, scene._yaw, scene._yaw + angle_difference(scene._yaw, want_yaw), 0.7).set_trans(Tween.TRANS_SINE)
	var r := float(st.get("r", 2.6))
	if _auto:
		await get_tree().create_timer(1.2).timeout
		scene._player.position = Vector3(at.x, scene._player.position.y, at.z + 0.6)
	while true:
		await get_tree().process_frame
		if st.has("who") and _actors.has(st["who"]):
			at = (_actors[st["who"]] as Node3D).global_position
			scene.extras.waypoint = Vector3(at.x, 0, at.z)
		var d := Vector2(scene._player.global_position.x - at.x, scene._player.global_position.z - at.z).length()
		_goal_dist.text = Loc.t("%d m away") % int(d)
		if d < r:
			break
	scene.extras.clear_waypoint()
	_goal_box.visible = false
	_goal = {}
	Sfx.play("sparkle", -8.0)


func _start_duel(d: Dictionary) -> void:
	StoryProgress.save_position(chapter, step, flags)
	Router.roam["pos"] = scene._player.position
	Router.roam["yaw"] = scene._yaw
	var deck: String = Collection.active_deck()
	if not CardData.has_deck(deck):
		deck = "echo"
	var opp_deck := str(d.get("opp_deck", d["opponent"]))
	if not CardData.has_deck(opp_deck):
		opp_deck = str(d.get("fallback", "kairo"))
	Router.match_state = {}
	Router.duel_config = {
		"opponent": d["opponent"], "opponent_deck": opp_deck, "player_deck": deck, "player_char": "player",
		"difficulty": d.get("difficulty", 1), "field": d.get("field", "battlecity"), "turbo": d.get("turbo", false),
		"story": true, "lose_ok": d.get("lose_ok", false), "return_to": Router.ROAM, "continue_label": Loc.t("Continue Story"),
	}
	_cutscene(true)
	_box.visible = false
	await _versus(str(d["opponent"]))
	Sfx.play("gong", -4.0)
	var tw := create_tween()
	tw.tween_property(_flash, "color", Color(1, 1, 1, 1), 0.3)
	await tw.finished
	Router.go(Router.DUEL)


func _do_flash_or_shake(kind: String) -> void:
	if kind == "flash":
		_flash.color = Color(1, 1, 1, 0.9)
		create_tween().tween_property(_flash, "color", Color(1, 1, 1, 0), 0.7)
		Sfx.play("special", -4.0)
	elif kind == "shake":
		_shake = 0.6
		Sfx.play("impact", -6.0, 0.6)


func _fx(st: Dictionary) -> void:
	var kind := str(st["fx"])
	match kind:
		"flash", "shake":
			_do_flash_or_shake(kind)
		"freeze":
			_freeze(true)
			Sfx.play("banish", -4.0, 0.6)
		"unfreeze":
			_freeze(false)
		"rift":
			_open_rift(st.get("at", scene._player.position + Vector3(0, 0, -4)))
			if not _skip:
				await get_tree().create_timer(1.0).timeout
		"rift_close":
			if _rift and is_instance_valid(_rift):
				_rift.queue_free()


## A tear in the air: a tall blade of light with rings turning around it.
func _open_rift(at: Vector3) -> void:
	if _rift and is_instance_valid(_rift):
		_rift.queue_free()
	_rift = Node3D.new()
	_rift.position = at
	scene.add_child(_rift)
	var blade := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 4.6)
	blade.mesh = q
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = abs(p.x) / (1.0 - p.y * p.y + 0.05) ;
	float core = smoothstep(0.9, 0.0, edge * (1.2 + 0.25 * sin(TIME * 7.0 + p.y * 9.0)));
	vec3 col = mix(vec3(0.3, 0.9, 1.0), vec3(1.0), core * core);
	ALBEDO = col * core * 2.2;
	ALPHA = core;
}
"""
	var bm := ShaderMaterial.new()
	bm.shader = sh
	blade.material_override = bm
	blade.position.y = 2.3
	blade.set_meta("billboard", true)
	_rift.add_child(blade)
	for i in 3:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.0 + i * 0.35
		tm.outer_radius = 1.05 + i * 0.35
		ring.mesh = tm
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.albedo_color = Color("7cf0ff")
		rm.emission_enabled = true
		rm.emission = Color("7cf0ff")
		rm.emission_energy_multiplier = 3.0
		ring.material_override = rm
		ring.position.y = 0.08
		ring.scale = Vector3(1, 0.15, 1)
		_rift.add_child(ring)
		var tw := ring.create_tween().set_loops()
		tw.tween_property(ring, "rotation:y", TAU * (1 if i % 2 == 0 else -1), 3.0 + i).from(0.0)
	var l := OmniLight3D.new()
	l.light_color = Color("7cf0ff")
	l.light_energy = 6.0
	l.omni_range = 12.0
	l.position.y = 2.0
	_rift.add_child(l)
	_rift.scale = Vector3(0.01, 0.01, 0.01)
	create_tween().tween_property(_rift, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_do_flash_or_shake("flash")
	_shake = 0.8


## A blank card in the Echo Deck fills in.
func _bond(st: Dictionary) -> void:
	_cutscene(true)
	_box.visible = false
	var id := int(st.get("card", 0))
	if id != 0 and not CardData.get_card(id).is_empty():
		Collection.owned[id] = mini(3, int(Collection.owned.get(id, 0)) + 1)
		Collection.save()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(shade)
	create_tween().tween_property(shade, "color:a", 0.78, 0.4)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -500
	v.offset_right = 500
	v.offset_top = -400
	v.offset_bottom = 400
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	shade.add_child(v)
	var head := UITheme.label(Loc.t("BOND FORMED"), 30, UITheme.GOLD, UITheme.semi_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var who := UITheme.label(Loc.t(str(st["bond"])).to_upper(), 64, Color.WHITE, UITheme.title_font())
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(who)
	var holder := CenterContainer.new()
	v.add_child(holder)
	var tr := TextureRect.new()
	tr.texture = Cards.get_back()
	tr.custom_minimum_size = Vector2(300, 437)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.pivot_offset = Vector2(150, 218)
	holder.add_child(tr)
	var note := UITheme.label(Loc.t(str(st.get("text", "A blank card in the Echo Deck fills in. It is yours to keep."))), 24, UITheme.TEXT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(900, 0)
	v.add_child(note)
	Sfx.play("charge", -4.0)
	await get_tree().create_timer(0.9).timeout
	var t1 := create_tween()
	t1.tween_property(tr, "scale:x", 0.0, 0.14)
	await t1.finished
	if id != 0:
		tr.texture = Cards.get_face(id)
		Foil.apply(tr, 3)
	create_tween().tween_property(tr, "scale:x", 1.0, 0.16)
	_do_flash_or_shake("flash")
	Sfx.play("rare")
	_advance_wanted = false
	_skip = false
	await get_tree().create_timer(0.8).timeout
	if _auto and "--story-versus" in OS.get_cmdline_user_args():
		await _snap("bond")
	while not _advance_wanted and not _auto:
		await get_tree().process_frame
	_advance_wanted = false
	shade.queue_free()


func _end(st: Dictionary) -> void:
	print("STORY END: ", chapter)
	_cutscene(true)
	_box.visible = false
	StoryProgress.clear_position()
	var next := str(st.get("unlock", ""))
	if next != "":
		StoryProgress.unlock(next)
	Collection.dp += 500
	Collection.save()
	Music.play("victory")
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(shade)
	create_tween().tween_property(shade, "color:a", 0.86, 0.8)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -520
	v.offset_right = 520
	v.offset_top = -240
	v.offset_bottom = 240
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	shade.add_child(v)
	var t := UITheme.label(Loc.t(str(st["end"])).to_upper(), 70, UITheme.GOLD, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var r := UITheme.label(Loc.t("+500 Duel Points"), 28, UITheme.ACCENT)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	if st.has("teaser"):
		var te := UITheme.label(Loc.t(str(st["teaser"])), 22, UITheme.TEXT_DIM)
		te.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		te.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		te.custom_minimum_size = Vector2(1000, 0)
		v.add_child(te)
	var playable := next != "" and StoryData.SCRIPTS.has(next)
	var go := Button.new()
	go.text = Loc.t("Next chapter") if playable else Loc.t("Back to the menu")
	go.custom_minimum_size = Vector2(420, 70)
	go.add_theme_font_size_override("font_size", 28)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(go)
	go.grab_focus.call_deferred()
	go.pressed.connect(func():
		if playable:
			StoryDirector.begin(next)
		else:
			_leave())
	if playable:
		var menu := Button.new()
		menu.text = Loc.t("Back to the menu")
		menu.custom_minimum_size = Vector2(420, 56)
		menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		menu.pressed.connect(_leave)
		v.add_child(menu)
	if _auto and "--story-quit" in OS.get_cmdline_user_args():
		await _snap("end", 2.5)
		get_tree().quit()


## Test helper: save what is on screen to /tmp/story_<chapter>_<tag>.png.
func _snap(tag: String, wait := 1.0) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/story_%s_%s.png" % [chapter, tag])
	print("STORY shot ", tag)


func _leave() -> void:
	Router.roam["story"] = ""
	Router.roam["pos"] = null
	Router.go(Router.MAIN_MENU)


## Start (or continue) a chapter: load the world its current scene plays in.
static func begin(id: String, resume := false) -> void:
	var router = Engine.get_main_loop().root.get_node("Router")
	var steps: Array = StoryData.SCRIPTS.get(id, [])
	var at := 0
	if resume:
		at = int(StoryProgress.position()["step"])
	else:
		StoryProgress.save_position(id, 0, {})
	# The scene that step belongs to decides where to load.
	var sc := {}
	for i in mini(at + 1, steps.size()):
		if (steps[i] as Dictionary).has("scene"):
			sc = steps[i]["scene"]
	router.roam["story"] = id
	router.roam["district"] = str(sc.get("district", "domino"))
	router.roam["pos"] = sc.get("pos", null)
	router.roam["tod"] = str(sc.get("tod", "day"))
	if sc.has("yaw"):
		router.roam["yaw"] = sc["yaw"]
	router.story_result = ""
	router.go(router.ROAM)


# ------------------------------------------------------------------ every frame

func _process(delta: float) -> void:
	_t += delta
	# Actors walking to their marks.
	for m in _moving.duplicate():
		var f: RoamFigure = m[0]
		if not is_instance_valid(f):
			_moving.erase(m)
			continue
		var to: Vector3 = m[1]
		var flat := Vector3(to.x - f.global_position.x, 0, to.z - f.global_position.z)
		if flat.length() < 0.15:
			f.set_speed(0.0)
			var face = m[3] if m.size() > 3 else null
			if face is String:
				var look := _pos_of(str(face)) - f.global_position
				f.rotation.y = atan2(look.x, look.z)
			elif face != null:
				f.rotation.y = float(face)
			_moving.erase(m)
			continue
		var stepv := flat.normalized() * float(m[2]) * delta
		f.global_position += Vector3(stepv.x, 0, stepv.z)
		f.rotation.y = lerp_angle(f.rotation.y, atan2(flat.x, flat.z), clampf(delta * 10.0, 0.0, 1.0))
		f.set_speed(float(m[2]))
	# Lumen bobs in the air and trails the player between scenes.
	if _spirit and is_instance_valid(_spirit):
		_spirit.position.y = 1.1 + sin(_t * 2.2) * 0.12
		if _cut and _spirit_park != null:
			var park: Vector3 = _spirit_park
			var sp := _spirit.global_position
			var k := clampf(delta * 5.0, 0.0, 1.0)
			_spirit.global_position = Vector3(lerpf(sp.x, park.x, k), sp.y, lerpf(sp.z, park.z, k))
			var mid: Vector3 = _cam_look - _spirit.global_position
			_spirit.rotation.y = lerp_angle(_spirit.rotation.y, atan2(mid.x, mid.z), k)
		elif not _cut:
			var want: Vector3 = scene._player.global_position + Basis(Vector3.UP, scene._yaw) * Vector3(0.8, 0, 0.6)
			var p := _spirit.global_position
			_spirit.global_position = Vector3(lerpf(p.x, want.x, clampf(delta * 3.0, 0.0, 1.0)), p.y, lerpf(p.z, want.z, clampf(delta * 3.0, 0.0, 1.0)))
			_spirit.rotation.y = scene._figure.rotation.y
	if _rift and is_instance_valid(_rift) and _rift.get_child_count() > 0:
		var blade := _rift.get_child(0) as Node3D
		var cam := get_viewport().get_camera_3d()
		if cam:
			var d := cam.global_position - blade.global_position
			blade.rotation.y = atan2(d.x, d.z)
	if _cut:
		_shake = maxf(0.0, _shake - delta)
		var w := clampf(delta * 4.5, 0.0, 1.0)
		_cam.global_position = _cam.global_position.lerp(_cam_pos, w)
		var jitter := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.08
		var cur := -_cam.global_transform.basis.z
		var want_dir := (_cam_look - _cam.global_position).normalized()
		var dir := cur.lerp(want_dir, w).normalized()
		if dir.length() > 0.1 and absf(dir.dot(Vector3.UP)) < 0.98:
			_cam.look_at(_cam.global_position + dir + jitter, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if not _cut:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_E, KEY_ENTER]) \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_advance_wanted = true
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_skip = true
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		_skip = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		StoryProgress.save_position(chapter, step, flags)
		scene._open_pause()
