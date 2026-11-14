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
var _shot_mode := ""       # "", "close" or "low" for the line being spoken
var _shot_kind := ""       # what the camera is doing now: "two" (two people), "single", "wide"
var _shot_pair: Array = [] # who the two-shot is holding
var _prev_spk := ""
var _cut_now := false      # the next camera move is a cut, not a glide
var _push := 0.0            # how far the camera has crept in during this line
var _box_style: StyleBoxFlat
var _name_tab: PanelContainer
var _name_style: StyleBoxFlat
var _solver: StoryCamera
var _stepped_out: Array = []   # bystanders hidden while a scene plays where they stood
var _shot_subs: Array = []     # who the current wide shot holds
var _audit := false
var _dir := {}                 # a directed camera move in progress
var _cap: Label
var _cap_tw: Tween
var _echo_on := false
var _echo_fx: ColorRect
var _echo_frame: Panel
var _echo_tag: Label
var _echo_tint := Color(1.0, 0.9, 0.74)
var _echo_music := ""
var _hint_t := 0.0
var _goal_how: Label
var _lead_to = null            # where Lumen is leading you (Vector3) while a goal is open


func _ready() -> void:
	_auto = "--story-auto" in OS.get_cmdline_user_args()
	chapter = str(Router.roam.get("story", ""))
	_steps = StoryData.SCRIPTS.get(chapter, [])
	var pos := StoryProgress.position()
	if str(pos["chapter"]) == chapter:
		step = int(pos["step"])
		flags = pos["flags"]
	_solver = StoryCamera.new(scene)
	_solver.skip_rids = [scene._player.get_rid()]
	_audit = "--story-audit" in OS.get_cmdline_user_args()
	_cam = Camera3D.new()
	_cam.fov = StoryCamera.FOV
	add_child(_cam)
	# A soft light that rides on the cutscene camera, so faces read at night and indoors.
	_fill = OmniLight3D.new()
	_fill.omni_attenuation = 0.6
	_fill.shadow_enabled = false
	_fill.visible = false
	_cam.add_child(_fill)
	_build_ui()
	_build_cine_ui()
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
	if flags.has("_echo"):
		# The memory carried on into another world: put the frame back.
		_echo_on = true
		scene._figure.visible = false
		_echo_fx.visible = true
		_echo_frame.visible = true
		_echo_tag.visible = true
		_echo_tag.text = "  " + Loc.t("ECHO") + "  ·  " + Loc.t(str(flags["_echo"])).to_upper() + "  "
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
	# Dialogue box: dark glass with the speaker's color down the left edge, their name on a
	# tab above it and their portrait standing up out of the corner.
	_box = PanelContainer.new()
	# Dark glass with the speaker's color down the left edge.
	_box_style = UITheme.panel_box(Color(0.03, 0.045, 0.1, 0.94), 14, Color(1, 1, 1, 0.14))
	_box_style.border_width_left = 6
	_box.add_theme_stylebox_override("panel", _box_style)
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 250
	_box.offset_right = -250
	_box.offset_top = -262
	_box.offset_bottom = -88
	_box.visible = false
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_advance_wanted = true)
	_ui.add_child(_box)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 196)
	m.add_theme_constant_override("margin_right", 26)
	m.add_theme_constant_override("margin_top", 26)
	m.add_theme_constant_override("margin_bottom", 18)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 28)
	_text.add_theme_font_size_override("italics_font_size", 28)
	_text.add_theme_constant_override("line_separation", 5)
	_text.add_theme_color_override("default_color", Color(0.95, 0.97, 1.0))
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_text)
	_more = UITheme.label("▼", 24, UITheme.ACCENT)
	_more.size_flags_vertical = Control.SIZE_SHRINK_END
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_more)
	# The portrait is not laid out by the box: it stands 70 px taller than it.
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_portrait.offset_left = 262
	_portrait.offset_right = 262 + 176
	_portrait.offset_top = -88 - 236
	_portrait.offset_bottom = -90
	_portrait.visible = false
	_ui.add_child(_portrait)
	_name_tab = PanelContainer.new()
	_name_style = Comic.box(UITheme.ACCENT, 10, 0.18, 4, 4)
	_name_style.content_margin_left = 20
	_name_style.content_margin_right = 20
	_name_style.content_margin_top = 4
	_name_style.content_margin_bottom = 4
	_name_style.skew = Vector2(0.18, 0.0)
	_name_tab.add_theme_stylebox_override("panel", _name_style)
	_name_tab.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_name_tab.offset_left = 452
	_name_tab.offset_top = -262 - 24
	_name_tab.offset_bottom = -262 + 20
	_name_tab.grow_horizontal = Control.GROW_DIRECTION_END
	_name_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_tab.visible = false
	_ui.add_child(_name_tab)
	_name = Comic.label("", 27, Color.WHITE, 0)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_tab.add_child(_name)
	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_choice_box.offset_left = -360
	_choice_box.offset_right = 360
	_choice_box.offset_top = -150
	_choice_box.add_theme_constant_override("separation", 14)
	_ui.add_child(_choice_box)
	# NEXT GOAL panel.
	_goal_box = PanelContainer.new()
	_goal_box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.86), 16, Color(UITheme.GOLD, 0.6)))
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
	_goal_how = UITheme.label("", 16, Color(0.78, 0.9, 1.0), UITheme.semi_font())
	_goal_how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_how.custom_minimum_size = Vector2(390, 0)
	gv.add_child(_goal_how)
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
		elif f is LumenSpirit and str(k) == who:
			(f as LumenSpirit).speak(2.2)


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
	flags.erase("_echo")
	for i in mini(step, _steps.size()):
		var es: Dictionary = _steps[i]
		if es.has("echo") and _passes(es):
			if es["echo"] is bool:
				flags.erase("_echo")
			else:
				flags["_echo"] = str(es["echo"])
	for i in range(maxi(0, last_scene), mini(step, _steps.size())):
		var st: Dictionary = _steps[i]
		if not _passes(st):
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
	var at: Vector3 = st["at"]
	if scene.city and scene.city.has_method("ground_at") and scene._inside == "":
		at.y = maxf(at.y, float(scene.city.ground_at(at.x, at.z)))
	if st.get("spirit", false):
		# Lumen: a duel spirit, small and made of light, floating at shoulder height.
		var sp := LumenSpirit.new()
		scene.add_child(sp)
		sp.position = Vector3(at.x, at.y + 1.1, at.z)
		sp.watch = scene._player
		sp.set_bonds(StoryProgress.bonds())
		_actors[key] = sp
		if st.get("caged", false):
			# Held in the Curator's frame: she does not follow anybody.
			sp.mood = "sad"
			if _spirit == null or not is_instance_valid(_spirit):
				_spirit = null
			return
		_spirit = sp
		if scene.partner and is_instance_valid(scene.partner):
			scene.partner.visible = false
		if not instant:
			sp.scale = Vector3.ONE * 0.01
			create_tween().tween_property(sp, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			sp.glitch(0.5)
		return
	# Stand on whatever floor is really there (a raised slab, a pier deck), not through it.
	var fq := PhysicsRayQueryParameters3D.create(at + Vector3(0, 1.5, 0), at + Vector3(0, -0.5, 0))
	fq.exclude = [scene._player.get_rid()]
	var fhit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(fq)
	if not fhit.is_empty():
		var fy: float = (fhit["position"] as Vector3).y
		if fy > at.y + 0.03 and fy < at.y + 1.0:
			at.y = fy
	var fig := RoamFigure.new()
	scene.add_child(fig)
	fig.position = st.get("from", at) if not instant else at
	fig.setup(key, Characters.get_char(key).get("color", Color.WHITE), "", false)
	fig.lively = false
	fig.greets = false
	fig.watch = scene._player
	if st.has("coat"):
		fig.wear_uniform(st["coat"])
	if st.has("pale"):
		# Washed out, like something kept behind glass for too long.
		var wash := StandardMaterial3D.new()
		wash.albedo_color = Color(0.96, 0.95, 0.9, float(st["pale"]))
		wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wash.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		wash.roughness = 0.9
		for mi in fig.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = wash
	_actors[key] = fig
	if _audit:
		var why := _solver.blocked_at(at)
		if why != "":
			print("ACTOR BLOCKED step ", step, " ", key, " at ", at, " ", why)
	var face = st.get("face", "player")
	if face is String:
		var to: Vector3 = _pos_of(str(face)) - at
		fig.rotation.y = atan2(to.x, to.z)
	else:
		fig.rotation.y = float(face)
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
		if not _passes(st):
			step += 1
			continue
		if _auto:
			print("STORY step ", step, " ", st.keys())
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--story-until=") and step > int(a.trim_prefix("--story-until=")):
					get_tree().quit()
					return
		if st.has("echo"):
			await _echo(st)
		elif st.has("shot") and not st.has("t"):
			await _shot_step(st)
		elif st.has("cap") and not st.has("t"):
			await _cap_step(st)
		elif st.has("credits"):
			await _credits(st)
		elif st.has("remember"):
			StoryProgress.remember(str(st["remember"]))
		elif st.has("music"):
			Music.play(str(st["music"]))
		elif st.has("sfx") and not st.has("t") and not st.has("act"):
			Sfx.play(str(st["sfx"]), float(st.get("vol", -5.0)), float(st.get("pitch", 1.0)))
		elif st.has("turn"):
			_turn(st)
		elif st.has("scene"):
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
		elif st.has("act"):
			await _act_step(st)
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
## Does this step play? "if": a choice made this chapter or something the story remembers.
## "unless": the opposite.
func _passes(st: Dictionary) -> bool:
	if st.has("if") and not (flags.has(st["if"]) or StoryProgress.recalls(str(st["if"]))):
		return false
	if st.has("unless") and (flags.has(st["unless"]) or StoryProgress.recalls(str(st["unless"]))):
		return false
	return true


## {"turn": who, "to": who or where}: someone turns to face something.
func _turn(st: Dictionary) -> void:
	var f := _fig(str(st["turn"]))
	if f == null:
		return
	var to := _spot(st["to"]) - f.global_position
	if Vector2(to.x, to.z).length() > 0.1:
		create_tween().tween_property(f, "rotation:y", f.rotation.y + angle_difference(f.rotation.y, atan2(to.x, to.z)), 0.35)


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
		for f in _stepped_out:
			if is_instance_valid(f):
				(f as Node3D).visible = true
		_stepped_out.clear()
		_shot_kind = ""
		_shot_pair = []
		_dir = {}
		_cam.fov = StoryCamera.FOV
		_caption("")
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
	_dir = {}
	_cam.fov = StoryCamera.FOV
	_caption("")
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
	var big := chapter_line != ""
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	# A slash of light across the dark, the same shape the duel cut-ins use.
	var band := ColorRect.new()
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bm := ShaderMaterial.new()
	bm.shader = CutIn._shader(CutIn.BAND, "band")
	for kv in [["center", 0.5], ["half_h", 0.2 if big else 0.14], ["slant", -0.07], ["dir", 1.0], ["tint", UITheme.GOLD if big else UITheme.ACCENT], ["progress", 0.0], ["fade", 1.0]]:
		bm.set_shader_parameter(kv[0], kv[1])
	band.material = bm
	root.add_child(band)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -800
	v.offset_right = 800
	v.offset_top = -150 if big else -100
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.rotation = -0.04
	v.pivot_offset = Vector2(800, 100)
	root.add_child(v)
	var parts: Array = []
	if big:
		var c := UITheme.label(Loc.t(chapter_line).to_upper(), 30, UITheme.GOLD.lightened(0.3), UITheme.semi_font())
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(c)
		parts.append(c)
	var t := UITheme.label(Loc.t(title).to_upper(), 104 if big else 70, Color.WHITE, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	t.add_theme_constant_override("outline_size", 12)
	v.add_child(t)
	parts.append(t)
	var line := ColorRect.new()
	line.color = UITheme.ACCENT
	line.custom_minimum_size = Vector2(0, 4)
	line.scale.x = 0.0
	v.add_child(line)
	var s := UITheme.label(Loc.t(sub), 30, Color(0.9, 0.94, 1.0, 0.9), UITheme.semi_font())
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	parts.append(s)
	for pt in parts:
		(pt as Control).modulate.a = 0.0
	Sfx.play("gong", -8.0)
	Sfx.play("whoosh", -9.0)
	await get_tree().process_frame
	line.pivot_offset = Vector2(line.size.x / 2.0, 0)
	var tw := create_tween().set_parallel()
	tw.tween_method(func(x: float): bm.set_shader_parameter("progress", x), 0.0, 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(line, "scale:x", 1.0, 0.5).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in parts.size():
		tw.tween_property(parts[i], "modulate:a", 1.0, 0.3).set_delay(0.15 + i * 0.14)
	tw.tween_property(v, "position:x", v.position.x + 30.0, 2.8 if big else 2.2)
	await get_tree().create_timer(2.3 if big else 1.7).timeout
	var out := create_tween().set_parallel()
	out.tween_method(func(x: float): bm.set_shader_parameter("fade", x), 1.0, 0.0, 0.4)
	out.tween_property(v, "modulate:a", 0.0, 0.35)
	await out.finished
	root.queue_free()


## Who a shot is about: where they stand, how tall, how much they matter, which way they face.
func _subject(key: String, w := 1.0, toward = null) -> Dictionary:
	var f := _fig(key)
	var p := _pos_of(key)
	if key == "player" and scene._figure:
		p = scene._figure.global_position
	var head := _head_h(f)
	# Someone still walking to their mark is filmed where they will stop.
	for m in _moving:
		if m[0] == f and (m[1] as Vector3).distance_to(p) < 5.0:
			p = Vector3(m[1].x, p.y, m[1].z)
	var face := Vector3.ZERO
	if toward != null:
		var t: Vector3 = toward
		face = Vector3(t.x - p.x, 0, t.z - p.z)
		face = face.normalized() if face.length() > 0.2 else Vector3.ZERO
	elif f and not (f == _spirit):
		face = Vector3(sin(f.rotation.y), 0, cos(f.rotation.y))
	return StoryCamera.sub(p, head, w, face)


## How high this person's face is (Grandpa is a head shorter than Kaiba).
func _head_h(f: Node3D) -> float:
	if f is RoamFigure and (f as RoamFigure)._model:
		var sk := Avatars._skeleton((f as RoamFigure)._model)
		var hb := Avatars.bone((f as RoamFigure)._model, "Head")
		if sk and hb >= 0:
			# (Someone who has just popped in is still growing to full size: measure them
			# as they will be.)
			var grown := maxf(0.001, f.scale.y)
			var y := ((sk.global_transform * sk.get_bone_global_pose(hb).origin).y - f.global_position.y) / grown
			if y > 0.3 and y < 2.6:
				return y + 0.1
	if f is LumenSpirit:
		return (f as LumenSpirit).head_height
	return 1.56


func _cast() -> Array:
	var out: Array = [scene._figure]
	if _spirit and is_instance_valid(_spirit):
		out.append(_spirit)
	return out


## Bystanders standing in the middle of a scene step out of it until the camera lets go.
func _make_room(spots: Array) -> void:
	var cast: Array = _actors.values()
	cast.append(scene._figure)
	for f in _solver.crowding(spots, 1.5, cast):
		(f as Node3D).visible = false
		_stepped_out.append(f)


## Where Lumen waits while other people talk: past them as the camera sees it and a little
## to one side, small in the background, never between the lens and a face.
func _behind(focus: Vector3) -> Vector3:
	var away_cam := Vector3(focus.x - _cam_pos.x, 0, focus.z - _cam_pos.z)
	if away_cam.length() < 0.1:
		return focus
	away_cam = away_cam.normalized()
	return focus + away_cam * 1.5 + away_cam.cross(Vector3.UP) * 1.1 * _shot_side


## Take the shot the solver likes best. Returns its score.
func _take(best: Array, kind: String, pair: Array) -> void:
	_cam_pos = best[0]
	_cam_look = best[1]
	_push = 0.0
	_cut_now = true
	_shot_kind = kind
	_shot_pair = pair
	_shot_subs = []


func _wide_cands(subs: Array) -> Array:
	var mid := Vector3.ZERO
	var heads: Array = []
	for su in subs:
		mid += su["p"] as Vector3
		heads.append((su["p"] as Vector3) + Vector3(0, float(su["h"]), 0))
	mid /= float(subs.size())
	var spread := 1.6
	for su in subs:
		spread = maxf(spread, Vector2((su["p"] as Vector3).x - mid.x, (su["p"] as Vector3).z - mid.z).length())
	var cands: Array = []
	var start := _t * 0.05 + 0.6
	for i in 12:
		var ang := start + float(i) * TAU / 12.0
		for dk: float in [1.0, 1.35, 0.8]:
			for lift: float in [2.5 + spread * 0.12, 1.75, 3.6 + spread * 0.15]:
				var cam := mid + Basis(Vector3.UP, ang) * Vector3(0, lift, (3.6 + spread * 1.15) * dk)
				cands.append([cam, StoryCamera.aim_for(cam, heads, 0.22), -0.4 * float(i) - (0.0 if dk == 1.0 else 3.0) - (0.0 if lift < 3.0 and lift > 2.0 else 2.5)])
	return cands


## A shot that holds a set of things in one frame (people, a rift, a doorway).
func _shot_group(subs: Array) -> void:
	if subs.is_empty():
		return
	var mid := Vector3.ZERO
	var spots: Array = []
	for su in subs:
		mid += su["p"] as Vector3
		spots.append(su["p"])
	mid /= float(subs.size())
	_make_room(spots)
	_solver.survey(mid, 22.0, _actors.values() + [scene._figure])
	var best := _solver.pick(_wide_cands(subs), subs)
	_take(best, "wide", [])
	_shot_subs = subs
	_spirit_park = null


func _shot_for(speaker: String, wide: bool) -> void:
	var who := speaker if speaker != "" else "player"
	var f := _fig(who)
	if f == null:
		who = "player"
		f = scene._figure
	var at := _pos_of(who)
	if wide or speaker == "":
		# Everyone nearby in one frame, from a little above.
		var here: Vector3 = scene._player.global_position
		var subs: Array = [_subject("player", 1.0 if who == "player" else 0.7)]
		var others: Array = []
		for k in _actors:
			var ap: Vector3 = (_actors[k] as Node3D).global_position
			var dk := Vector2(ap.x - here.x, ap.z - here.z).length()
			if dk > 12.0:
				continue
			if _actors[k] == _spirit and _actors.size() > 1 and str(k) != who:
				continue
			others.append([0.0 if str(k) == who else dk, str(k)])
		# The scene is about whoever is close: people across the room are set dressing.
		others.sort_custom(func(a, b): return a[0] < b[0])
		for i in mini(others.size(), 4):
			var ok := str(others[i][1])
			subs.append(_subject(ok, 1.0 if ok == who else (0.6 if float(others[i][0]) < 5.0 else 0.25)))
		if _shot_kind == "wide" and not _shot_subs.is_empty() and _shot_subs.size() == subs.size() and _solver.rate(_cam_pos, _cam_look, subs) > 62.0:
			_prev_spk = speaker
			return
		_shot_group(subs)
		_prev_spk = speaker
		return
	var is_spirit: bool = _spirit != null and f == _spirit
	var special := _shot_mode in ["close", "low"]
	# Who is being spoken to.
	var partner := "player"
	if who == "player":
		partner = _last_other if (_last_other != "" and _actors.has(_last_other)) else ""
		if partner == "":
			var near := 99.0
			for k in _actors:
				if _actors[k] == _spirit and _actors.size() > 1:
					continue
				var dk := _pos_of(str(k)).distance_to(at)
				if dk < near and dk > 0.3:
					near = dk
					partner = str(k)
	elif _prev_spk != "" and _prev_spk != who and _prev_spk != "player" and _actors.has(_prev_spk) and _pos_of(_prev_spk).distance_to(at) < 7.0:
		partner = _prev_spk
	if who != "player":
		_last_other = who
	_prev_spk = speaker
	var b := _pos_of(partner) if partner != "" else at + Vector3(sin(f.rotation.y), 0, cos(f.rotation.y)) * 2.4
	# An NPC turns to whoever they talk to as the line starts; you stand the way you stand.
	var sa := _subject(who, 1.0, b) if who != "player" else _subject(who, 1.0)
	var gap := Vector2(b.x - at.x, b.z - at.z).length()
	var best_two: Array = []
	var pair := [who, partner]
	pair.sort()
	# Two people talking are filmed together, from the side, and the camera stays put while
	# they go back and forth. It only cuts when somebody else speaks, for a marked moment,
	# or when the view stops being clear.
	if not special and partner != "" and partner != who and gap > 0.5 and gap < 9.0:
		var sb := _subject(partner, 0.8, at) if partner == "player" else _subject(partner, 0.8)
		var subs2: Array = [sa, sb]
		var ha: Vector3 = (sa["p"] as Vector3) + Vector3(0, float(sa["h"]), 0)
		var hb: Vector3 = (sb["p"] as Vector3) + Vector3(0, float(sb["h"]), 0)
		var mid: Vector3 = ((sa["p"] as Vector3) + (sb["p"] as Vector3)) / 2.0
		_make_room([sa["p"], sb["p"], mid])
		_solver.survey(mid, 16.0, [f, _fig(partner)] + ([_spirit] if _spirit and is_instance_valid(_spirit) else []))
		if pair == _shot_pair and _shot_kind == "two" and _solver.rate(_cam_pos, _cam_look, subs2) > 60.0:
			# Same two: hold the shot, lean the framing a touch toward whoever speaks.
			_cam_look = StoryCamera.aim_for(_cam_pos, [ha, hb], 0.34) + (Vector3(at.x, 0, at.z) - Vector3(mid.x, 0, mid.z)).limit_length(0.3)
			return
		var axis := Vector3(b.x - at.x, 0, b.z - at.z).normalized()
		var perp := axis.cross(Vector3.UP).normalized()
		var eye_mid := (ha.y + hb.y) / 2.0
		var cands: Array = []
		for side: float in [_shot_side, -_shot_side]:
			for along: float in [0.28, 0.1, 0.45, -0.12, 0.62]:
				for dk: float in [1.0, 1.3, 0.8, 1.65]:
					for lift: float in [0.3, 0.8, 1.4, 2.1]:
						var cam := Vector3(mid.x, 0, mid.z) + perp * side * (2.0 + gap * 0.72) * dk + axis * gap * along + Vector3(0, eye_mid + lift, 0)
						var bonus := (0.0 if side == _shot_side else -3.0) - absf(along - 0.28) * 14.0 - absf(dk - 1.0) * 9.0 - (lift - 0.3) * (lift - 0.3) * 7.0
						cands.append([cam, StoryCamera.aim_for(cam, [ha, hb], 0.34), bonus])
		best_two = _solver.pick(cands, subs2)
		if float(best_two[2]) > 66.0:
			_take(best_two, "two", pair)
			var off_side: float = ((best_two[0] as Vector3) - mid).dot(perp)
			if absf(off_side) > 0.01:
				_shot_side = signf(off_side)
			_spirit_park = null
			if _spirit and is_instance_valid(_spirit) and f != _spirit and _fig(partner) != _spirit:
				_spirit_park = _behind(Vector3(mid.x, 0, mid.z))
			return
	# One person: from in front, a little to one side, the listener just out of frame.
	_shot_side = -_shot_side
	var away := Vector3(b.x - at.x, 0, b.z - at.z)
	if away.length() < 0.4:
		away = Vector3(sin(f.rotation.y), 0, cos(f.rotation.y))
	var d0 := clampf(away.length(), 1.4, 2.3) + 1.1
	away = away.normalized()
	var head: Vector3 = (sa["p"] as Vector3) + Vector3(0, float(sa["h"]), 0)
	_make_room([sa["p"]])
	_solver.survey(sa["p"], 12.0, [f] + ([_spirit] if _spirit and is_instance_valid(_spirit) else []))
	var dists: Array = [d0, d0 + 0.9, d0 - 0.6, d0 + 2.0]
	var lifts: Array = [0.42, 0.9, 0.1, 1.5]
	var frac := 0.32
	if is_spirit:
		dists = [1.7, 2.3, 1.3, 3.0]
		lifts = [0.15, 0.45, -0.1, 0.8]
		frac = 0.2
	elif _shot_mode == "close":
		# Right in on the face for the lines that matter.
		dists = [1.45, 1.8, 1.2, 2.3]
		lifts = [0.2, 0.05, 0.45, 0.8]
		frac = 0.16
	elif _shot_mode == "low":
		# From below, looking up: someone who thinks they own the street.
		dists = [2.0, 2.5, 1.6, 3.0]
		lifts = [-0.75, -0.5, -0.95, -0.2]
		frac = 0.12
	var cands1: Array = []
	for ai in 8:
		var ang: float = [0.32, -0.32, 0.62, -0.62, 1.0, -1.0, 1.4, -1.4][ai] * _shot_side
		var dir := Basis(Vector3.UP, ang) * away
		for di in dists.size():
			for li in lifts.size():
				var cam1 := Vector3(at.x, 0, at.z) + dir * float(dists[di]) + Vector3(0, head.y - 0.06 + float(lifts[li]), 0)
				cands1.append([cam1, StoryCamera.aim_for(cam1, [head], frac), -1.6 * float(ai) - 3.0 * float(di) - 2.5 * float(li)])
	var best_one := _solver.pick(cands1, [sa])
	if not best_two.is_empty() and float(best_two[2]) > float(best_one[2]) + 4.0:
		# Nothing clean from the front either: the two-shot was the clearer view after all.
		_take(best_two, "two", pair)
		_spirit_park = null
		return
	if float(best_one[2]) < 45.0 and not special:
		# Boxed in. Step back and show the whole scene instead.
		var keep_cam := best_one
		var subs_w: Array = [sa]
		if partner != "":
			subs_w.append(_subject(partner, 0.7, at))
		_solver.survey(sa["p"], 22.0, [f, _fig(partner)] + ([_spirit] if _spirit and is_instance_valid(_spirit) else []))
		var best_w := _solver.pick(_wide_cands(subs_w), subs_w)
		if float(best_w[2]) > float(keep_cam[2]) + 6.0:
			_take(best_w, "wide", [])
			_shot_subs = subs_w
			_spirit_park = null
			return
	_take(best_one, "single", [])
	# Lumen keeps out of the lens: she hovers beside the conversation, on the far side.
	_spirit_park = null
	if _spirit and is_instance_valid(_spirit) and not is_spirit:
		var to_cam: Vector3 = (best_one[0] as Vector3) - at
		var rt := Vector3(to_cam.x, 0, to_cam.z).normalized().cross(Vector3.UP)
		_spirit_park = _behind(Vector3(at.x, 0, at.z))


## A character's portrait. They are drawn live from the model, and that little stage can be
## thrown away behind our back (a new look, a settings change), so make sure it still exists.
func _face(key: String) -> Texture2D:
	var tex := Portraits.get_portrait(key)
	if key == "lumen":
		LumenSpirit.wake(12.0)
		return tex
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
	# Answering somebody else who just spoke and stands close by: look at them, not at you.
	if _prev_spk != "" and _prev_spk != speaker and _prev_spk != "player" and _actors.has(_prev_spk):
		var other: Vector3 = (_actors[_prev_spk] as Node3D).global_position - f.global_position
		if Vector2(other.x, other.z).length() < 7.0 and Vector2(other.x, other.z).length() > 0.3:
			to = other
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
	_shot_mode = str(st.get("cam", ""))
	_caption("")
	if st.has("shot"):
		_start_directed(st["shot"])
	elif st.get("keep", false) and not _dir.is_empty():
		pass
	else:
		if not _dir.is_empty():
			_dir = {}
			_cam.fov = StoryCamera.FOV
			_shot_kind = ""
		_shot_for(who, _shot_mode == "wide")
	if _audit and _dir.is_empty():
		var asub: Array = [_subject(who if who != "" else "player")]
		asub[0]["f"] = Vector3.ZERO
		var rating := _solver.rate(_cam_pos, _cam_look, asub)
		print("CAM %s step %d %s %s %s %s" % ["ok " if rating > 60.0 else "BAD", step, _shot_kind, who, _solver.explain(_cam_pos, _cam_look, asub), str(_solver.last)])
	if st.has("fx"):
		_do_flash_or_shake(str(st["fx"]))
	if st.has("sfx") and not _skip:
		Sfx.play(str(st["sfx"]), -5.0)
	# "do": the speaker acts the line out. "react": others answer with a mark over their head
	# a beat later, e.g. {"lumen": "!"}.
	if st.has("do") and not _skip:
		var df := _fig(who if who != "" else "player")
		if df is RoamFigure:
			(df as RoamFigure).gesture(str(st["do"]), 0.2)
			(df as RoamFigure)._hold = 2.2
		elif df is LumenSpirit:
			(df as LumenSpirit).gesture(str(st["do"]))
	if st.has("react") and not _skip:
		var marks: Dictionary = st["react"]
		for rk in marks:
			var rwho := str(rk)
			var rmark := str(marks[rk])
			get_tree().create_timer(0.45).timeout.connect(func(): _emote(rwho, rmark))
	var info := Characters.get_char(who) if who != "" and who != "player" else {}
	var text := Loc.t(str(st["t"])).replace("{player}", Profile.duelist_name)
	_box.visible = true
	_more.visible = false
	var m := _text.get_parent().get_parent() as MarginContainer
	if who == "":
		_name.text = ""
		_name_tab.visible = false
		_portrait.visible = false
		m.add_theme_constant_override("margin_left", 34)
		_box_style.border_color = Color(1, 1, 1, 0.16)
		_text.text = "[i]%s[/i]" % text
	else:
		var col: Color = Profile.color() if who == "player" else Color(info.get("color", UITheme.ACCENT))
		col = col.lightened(0.15)
		var changed := _name.text != (Profile.duelist_name if who == "player" else Loc.t(str(info.get("name", who)))).to_upper()
		_name.text = (Profile.duelist_name if who == "player" else Loc.t(str(info.get("name", who)))).to_upper()
		_name_style.bg_color = col
		_name_style.border_color = col.lightened(0.3)
		_name.add_theme_color_override("font_color", Comic.INK if col.get_luminance() > 0.4 else Color.WHITE)
		_name_tab.visible = true
		_name_tab.reset_size()
		_box_style.border_color = col
		m.add_theme_constant_override("margin_left", 196)
		_portrait.visible = true
		_portrait.texture = _face(who)
		_portrait.self_modulate = Color(1.45, 1.45, 1.55) if who == "curator" else Color.WHITE
		_text.text = text
		# A new speaker steps in: the portrait and the name tab slide up into place.
		if changed and not _skip:
			_portrait.modulate.a = 0.0
			_portrait.offset_top = -88 - 236 + 26
			_portrait.offset_bottom = -90 + 26
			var pt := create_tween().set_parallel()
			pt.tween_property(_portrait, "modulate:a", 1.0, 0.14)
			pt.tween_property(_portrait, "offset_top", -88.0 - 236.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pt.tween_property(_portrait, "offset_bottom", -90.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
			if a.begins_with("--story-shots=") and (a == "--story-shots=all" or str(step) in a.trim_prefix("--story-shots=").split(",")):
				await get_tree().create_timer(1.0).timeout
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
	# Choices whose name starts with "m_" are remembered for good: later chapters look back.
	if str(options[picked[0]][1]).begins_with("m_"):
		StoryProgress.remember(str(options[picked[0]][1]))
	for c in _choice_box.get_children():
		c.queue_free()
	Sfx.play("click")
	_advance_wanted = false


func _do_goal(st: Dictionary) -> void:
	_cutscene(false)
	var at: Vector3 = st["at"] if st.has("at") else _pos_of(str(st.get("who", "player")))
	_goal = st
	_goal_text.text = Loc.t(str(st["goal"]))
	# How to do it, in one line. Every goal has one: the default is the beacon.
	var how := str(st.get("how", "Follow the gold beacon. Lumen flies ahead to show the way." if (_spirit and is_instance_valid(_spirit)) else "Follow the gold beacon. The arrow at the top shows which way."))
	_goal_how.text = Loc.t(how)
	_goal_how.visible = how != ""
	_lead_to = at
	_hint_t = 0.0
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
		_lead_to = at
		if d < r:
			break
		# Standing around? Lumen says it again, in her own words.
		_hint_t += get_process_delta_time()
		if _hint_t > 28.0 and _spirit is LumenSpirit:
			_hint_t = 0.0
			var hint := str(st.get("hint", "This way! %s. Follow me!"))
			if "%s" in hint:
				hint = Loc.t(hint) % Loc.t(str(st["goal"]))
			Router.toast("Lumen:  " + Loc.t(hint))
			(_spirit as LumenSpirit).speak(2.0)
			(_spirit as LumenSpirit).hop()
			Sfx.play("blip", -8.0, 1.25)
	_lead_to = null
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
	# Boss rules: {"opp_lp": 12000, "lp": 8000, "rule": "The Curator starts with 12000 Life Points."}
	for k in ["opp_lp", "my_lp", "hand", "rule", "music"]:
		if d.has(k):
			Router.duel_config[k] = d[k]
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


## A beat with no words: someone gestures, maybe with a mark over their head, and the camera
## holds on them. {"act": "kaiba", "do": "wave", "emote": "!", "wait": 1.0, "cam": "close"}
func _act_step(st: Dictionary) -> void:
	if _skip:
		return
	var who := str(st["act"])
	_cutscene(true)
	_box.visible = false
	_shot_mode = str(st.get("cam", ""))
	_face_each_other(who)
	if st.has("shot"):
		_start_directed(st["shot"])
	elif not (st.get("keep", false) and not _dir.is_empty()):
		_dir = {}
		_cam.fov = StoryCamera.FOV
		_shot_for(who, _shot_mode == "wide")
	var f := _fig(who)
	if f is RoamFigure and st.has("do"):
		var motion := str(st["do"])
		if motion in ["victory", "lose", "cheer"]:
			(f as RoamFigure).play_once("victory" if motion == "cheer" else motion)
		else:
			(f as RoamFigure).gesture(motion, 0.2)
			(f as RoamFigure)._hold = float(st.get("wait", 1.1)) + 0.6
	if st.has("emote"):
		_emote(who, str(st["emote"]))
	if st.has("sfx"):
		Sfx.play(str(st["sfx"]), -5.0)
	var left := float(st.get("wait", 1.1)) if not _auto else 0.3
	while left > 0.0 and not _skip and not _advance_wanted:
		await get_tree().process_frame
		left -= get_process_delta_time()
	_advance_wanted = false


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


# ------------------------------------------------------------------ cinematics
# Directed camera moves, captions, and Echoes (memory scenes). Steps:
#   {"shot": {...}, "cap": "caption", "bg": true}      a camera move; "bg" lets the next lines play over it
#   {"s": ..., "t": ..., "shot": {...}} or "keep": true  a line spoken over a directed move
#   {"cap": "text"}                                      a caption over whatever the camera shows
#   {"echo": "Title", "sub": "..."} ... {"echo": false}  everything between plays as a memory
# Shot spec: "on" who or where it looks (key or Vector3), "on_to" where the look ends up,
#   "ang" yaw of the camera around that point (number or [from, to]), or "face" the same but
#   measured from the way the person faces (0 = straight in front of them),
#   "d" distance, "h" camera height, "look_h" height of the point it looks at,
#   "from"/"to" exact camera positions instead, "t" seconds, "fov" (number or [from, to]).

func _pair(v, fallback: float) -> Array:
	if v == null:
		return [fallback, fallback]
	if v is Array:
		return [float(v[0]), float(v[1])]
	return [float(v), float(v)]


func _spot(v) -> Vector3:
	if v is Vector3:
		return v
	return _pos_of(str(v))


func _start_directed(spec: Dictionary) -> void:
	var on = spec.get("on", "player")
	var d := {"on": on, "on_to": spec.get("on_to", null), "t": 0.0, "dur": float(spec.get("t", 4.0)),
		"d": _pair(spec.get("d", null), 4.0), "h": _pair(spec.get("h", null), 1.7),
		"fov": _pair(spec.get("fov", null), StoryCamera.FOV), "look_h": float(spec.get("look_h", 1.25 if on is String else 0.0)),
		"look_h_to": float(spec.get("look_h_to", spec.get("look_h", 1.25 if spec.get("on_to", on) is String else 0.0)))}
	var base := 0.0
	if spec.has("face"):
		var f := _fig(str(on)) if on is String else null
		base = f.rotation.y if f else 0.0
		d["ang"] = _pair(spec["face"], 0.0)
		d["ang"] = [base + float(d["ang"][0]), base + float(d["ang"][1])]
	else:
		d["ang"] = _pair(spec.get("ang", null), 0.0)
	if spec.has("from"):
		d["from"] = spec["from"]
		d["to"] = spec.get("to", spec["from"])
	elif maxf(float(d["d"][0]), float(d["d"][1])) <= 9.5:
		# (Big establishing shots stand far off and high up: nothing to clear.)
		_clear_view(d, spec.has("face"))
	_dir = d
	_shot_kind = "directed"
	_shot_pair = []
	_spirit_park = null
	_eval_directed(0.0)
	if _echo_on and not _skip:
		# A new panel of the memory: a soft white blink between pictures.
		_flash.color = Color(1, 1, 1, 0.55)
		create_tween().tween_property(_flash, "color", Color(1, 1, 1, 0), 0.45)


## A directed move says roughly where the camera goes. If a rack, a post or a wall would sit
## between the lens and what it is looking at, swing the whole move round a little until the
## view is clear. The move keeps its shape; only where it stands changes.
func _clear_view(d: Dictionary, face_shot := false) -> void:
	var feet := _spot(d["on"])
	var look_h := maxf(0.6, float(d["look_h"]))
	var cast: Array = [scene._figure]
	if d["on"] is String and _fig(str(d["on"])) != null:
		cast.append(_fig(str(d["on"])))
	_solver.survey(feet, maxf(float(d["d"][0]), float(d["d"][1])) + 6.0, cast)
	var sub: Array = [StoryCamera.sub(feet, look_h, 1.0)]
	if not (d["on"] is String):
		# Looking at a place: what matters is the people standing around it.
		sub = []
		for k in _actors:
			var ap: Vector3 = (_actors[k] as Node3D).global_position
			if Vector2(ap.x - feet.x, ap.z - feet.z).length() < 4.5 and absf(ap.y - feet.y) < 2.0:
				sub.append(_subject(str(k), 1.0))
				cast.append(_actors[k])
		if sub.is_empty() or sub.size() > 2:
			return
		_solver.survey(feet, maxf(float(d["d"][0]), float(d["d"][1])) + 6.0, cast)
	var swings: Array = [0.0, 0.3, -0.3, 0.6, -0.6, 0.95, -0.95, 1.4, -1.4]
	if face_shot:
		# A shot of somebody's face stays in front of them.
		swings = [0.0, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75]
		var ff := _fig(str(d["on"])) if d["on"] is String else null
		if ff:
			sub[0]["f"] = Vector3(sin(ff.rotation.y), 0, cos(ff.rotation.y))
	var best := 0.0
	var best_s := -1e9
	var base_s := -1e9
	for off: float in swings:
		var total := 0.0
		for k: float in [0.0, 0.5, 1.0]:
			var ang := lerpf(float(d["ang"][0]), float(d["ang"][1]), k) + off
			var cam := feet + Vector3(sin(ang), 0, cos(ang)) * lerpf(float(d["d"][0]), float(d["d"][1]), k) + Vector3(0, lerpf(float(d["h"][0]), float(d["h"][1]), k), 0)
			total += _solver.rate(cam, feet + Vector3(0, float(d["look_h"]), 0), sub)
		total -= absf(off) * 9.0
		if off == 0.0:
			base_s = total
			best_s = total
			if total > 285.0:
				break
		elif total > best_s + 1.0 and total > base_s + 60.0:
			# Only leave the planned line for a view that is clearly better.
			best_s = total
			best = off
	d["ang"] = [float(d["ang"][0]) + best, float(d["ang"][1]) + best]
	if _audit:
		print("DIRECTED step ", step, " swing ", best, " score ", snappedf(best_s / 3.0, 0.1))


func _eval_directed(delta: float) -> void:
	var d := _dir
	d["t"] = float(d["t"]) + delta
	var k := clampf(float(d["t"]) / maxf(0.01, float(d["dur"])), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var a := _spot(d["on"]) + Vector3(0, float(d["look_h"]), 0)
	var look := a
	if d["on_to"] != null:
		look = a.lerp(_spot(d["on_to"]) + Vector3(0, float(d["look_h_to"]), 0), k)
	var cam: Vector3
	if d.has("from"):
		cam = (d["from"] as Vector3).lerp(d["to"], k)
	else:
		var ang := lerpf(float(d["ang"][0]), float(d["ang"][1]), k)
		var dist := lerpf(float(d["d"][0]), float(d["d"][1]), k)
		var feet := look - Vector3(0, lerpf(float(d["look_h"]), float(d["look_h_to"]), k), 0)
		cam = feet + Vector3(sin(ang), 0, cos(ang)) * dist + Vector3(0, lerpf(float(d["h"][0]), float(d["h"][1]), k), 0)
		# Never through a wall: come in along the line of sight until the view is clear.
		var hit := _solver._ray(look, cam)
		if hit >= 0.0:
			cam = look + (cam - look).normalized() * maxf(0.8, hit * 0.9)
	_cam_pos = cam
	_cam_look = look
	_cam.fov = lerpf(float(d["fov"][0]), float(d["fov"][1]), k)
	_cam.global_position = cam + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.08
	if cam.distance_to(look) > 0.05:
		_cam.look_at(look, Vector3.UP)


func _shot_step(st: Dictionary) -> void:
	_cutscene(true)
	_light_shot()
	_box.visible = false
	_start_directed(st["shot"])
	if st.has("sfx") and not _skip:
		Sfx.play(str(st["sfx"]), -5.0)
	if st.has("music"):
		Music.play(str(st["music"]))
	if st.has("cap"):
		_caption(str(st["cap"]))
	if st.get("bg", false) or _skip:
		return
	var left := float(st["shot"].get("t", 4.0))
	if st.has("cap"):
		left = maxf(left, 1.6 + str(st["cap"]).length() * 0.045)
	if _auto:
		left = 0.4
		await _auto_shot()
	_advance_wanted = false
	while left > 0.0 and not _skip and not _advance_wanted:
		await get_tree().process_frame
		left -= get_process_delta_time()
	_advance_wanted = false
	if st.has("cap"):
		_caption("")


func _auto_shot() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--story-shots=") and (a == "--story-shots=all" or str(step) in a.trim_prefix("--story-shots=").split(",")):
			_dir["t"] = float(_dir.get("dur", 1.0)) * 0.5
			await get_tree().create_timer(1.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/story_%s_%d.png" % [chapter, step])
			print("STORY shot ", step)


## A line of narration on the picture itself (no box): for cinematics and memories.
func _caption(text: String) -> void:
	if _cap_tw and _cap_tw.is_valid():
		_cap_tw.kill()
	if text == "":
		if _cap.visible:
			_cap_tw = create_tween()
			_cap_tw.tween_property(_cap, "modulate:a", 0.0, 0.25)
			_cap_tw.tween_callback(func(): _cap.visible = false)
		return
	_cap.text = Loc.t(text).replace("{player}", Profile.duelist_name)
	_cap.visible = true
	_cap.modulate.a = 0.0
	_cap_tw = create_tween()
	_cap_tw.tween_property(_cap, "modulate:a", 1.0, 0.35)


func _cap_step(st: Dictionary) -> void:
	_cutscene(true)
	_box.visible = false
	_caption(str(st["cap"]))
	if _skip:
		return
	var left := 1.8 + str(st["cap"]).length() * 0.05
	if _auto:
		left = 0.3
	_advance_wanted = false
	while left > 0.0 and not _skip and not _advance_wanted:
		await get_tree().process_frame
		left -= get_process_delta_time()
	_advance_wanted = false
	_caption("")


## A memory begins (or ends): the picture loses its color, the edges soften, a frame closes in.
func _echo(st: Dictionary) -> void:
	var on: bool = not (st["echo"] is bool)
	if on == _echo_on:
		return
	_cutscene(true)
	_box.visible = false
	_caption("")
	Sfx.play("special", -6.0, 0.7 if on else 1.2)
	if not _skip:
		var tw := create_tween()
		tw.tween_property(_flash, "color", Color(1, 1, 1, 1), 0.3)
		await tw.finished
	_echo_on = on
	# A memory is somebody else's: you are not in the picture.
	scene._figure.visible = not on
	if on:
		flags["_echo"] = str(st["echo"])
	else:
		flags.erase("_echo")
	_echo_fx.visible = on
	_echo_frame.visible = on
	_echo_tag.visible = on
	if on:
		_echo_tint = st.get("tint", Color(1.0, 0.9, 0.74))
		(_echo_fx.material as ShaderMaterial).set_shader_parameter("tint", _echo_tint)
		_echo_tag.text = "  " + Loc.t("ECHO") + "  ·  " + Loc.t(str(st["echo"])).to_upper() + "  "
		_echo_music = Music._wanted
		Music.play(str(st.get("music", "memory")))
		if st.has("sub") and not _skip:
			await _title_card(str(st["echo"]), str(st["sub"]), "Echo")
	else:
		_dir = {}
		_cam.fov = StoryCamera.FOV
		if _echo_music != "":
			Music.play(_echo_music)
	create_tween().tween_property(_flash, "color", Color(1, 1, 1, 0), 0.7)


const ECHO_SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform vec3 tint = vec3(1.0, 0.9, 0.74);
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	float d = distance(uv, vec2(0.5));
	float soft = smoothstep(0.22, 0.62, d) * 3.5;
	vec3 c = texture(screen, uv).rgb * 0.4;
	c += texture(screen, uv + vec2(px.x, px.y) * soft).rgb * 0.15;
	c += texture(screen, uv + vec2(-px.x, px.y) * soft).rgb * 0.15;
	c += texture(screen, uv + vec2(px.x, -px.y) * soft).rgb * 0.15;
	c += texture(screen, uv + vec2(-px.x, -px.y) * soft).rgb * 0.15;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 mem = mix(vec3(g), c, 0.3) * tint * 1.12 + vec3(0.035);
	mem = mix(mem, vec3(1.0), smoothstep(0.75, 1.0, g) * 0.35);
	mem += (hash(uv * 900.0 + fract(TIME) * 37.0) - 0.5) * 0.06;
	mem *= mix(0.4, 1.0, smoothstep(0.82, 0.28, d));
	COLOR = vec4(mem, 1.0);
}
"""


func _build_cine_ui() -> void:
	_echo_fx = ColorRect.new()
	_echo_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_echo_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = ECHO_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sh
	_echo_fx.material = sm
	_echo_fx.visible = false
	_ui.add_child(_echo_fx)
	_ui.move_child(_echo_fx, 0)
	# The frame of the picture: a memory is something you look at, not somewhere you are.
	_echo_frame = Panel.new()
	_echo_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_echo_frame.offset_left = 46
	_echo_frame.offset_right = -46
	_echo_frame.offset_top = 96
	_echo_frame.offset_bottom = -96
	_echo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0, 0, 0, 0)
	fs.border_color = Color(1, 0.98, 0.92, 0.9)
	fs.set_border_width_all(5)
	fs.set_corner_radius_all(14)
	fs.shadow_color = Color(1, 0.95, 0.8, 0.25)
	fs.shadow_size = 18
	_echo_frame.add_theme_stylebox_override("panel", fs)
	_echo_frame.visible = false
	_ui.add_child(_echo_frame)
	_ui.move_child(_echo_frame, 1)
	_echo_tag = UITheme.label("", 22, Comic.INK, UITheme.semi_font())
	_echo_tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_echo_tag.offset_left = 78
	_echo_tag.offset_top = 82
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(1, 0.98, 0.92, 0.95)
	ts.set_corner_radius_all(6)
	ts.content_margin_top = 3
	ts.content_margin_bottom = 3
	_echo_tag.add_theme_stylebox_override("normal", ts)
	_echo_tag.visible = false
	_ui.add_child(_echo_tag)
	_ui.move_child(_echo_tag, 2)
	_cap = UITheme.label("", 34, Color(1, 1, 1), UITheme.semi_font())
	_cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_cap.offset_left = 220
	_cap.offset_right = -220
	_cap.offset_top = -250
	_cap.offset_bottom = -112
	_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cap.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_cap.add_theme_constant_override("outline_size", 10)
	_cap.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_cap.add_theme_constant_override("shadow_offset_y", 3)
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cap.visible = false
	_ui.add_child(_cap)


## The names at the very end.
func _credits(st: Dictionary) -> void:
	_cutscene(true)
	_box.visible = false
	_caption("")
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(shade)
	var tw := create_tween()
	tw.tween_property(shade, "color:a", 1.0, 1.2)
	await tw.finished
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	shade.add_child(v)
	for line in st["credits"]:
		var txt := str(line)
		var big := txt.begins_with("#")
		var l := UITheme.label(Loc.t(txt.trim_prefix("#")).replace("{player}", Profile.duelist_name), 58 if big else 28, UITheme.GOLD if big else Color(0.92, 0.95, 1.0), UITheme.title_font() if big else UITheme.semi_font())
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(0, 110 if big else 0)
		l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		v.add_child(l)
	await get_tree().process_frame
	await get_tree().process_frame
	var h := get_viewport().get_visible_rect().size.y
	v.position.y = h
	var total := v.size.y + h
	var dur := total / 95.0
	if _auto:
		dur = 1.0
	var roll := create_tween()
	roll.tween_property(v, "position:y", -v.size.y, dur)
	_advance_wanted = false
	_skip = false
	while roll.is_running() and not _skip:
		if _advance_wanted:
			roll.set_speed_scale(6.0)
		await get_tree().process_frame
	roll.kill()
	_advance_wanted = false
	shade.queue_free()


## A blank card in the Echo Deck fills in.
func _bond(st: Dictionary) -> void:
	_cutscene(true)
	_box.visible = false
	var id := int(st.get("card", 0))
	if id != 0 and not CardData.get_card(id).is_empty():
		Collection.owned[id] = mini(3, int(Collection.owned.get(id, 0)) + 1)
		Collection.save()
	StoryProgress.remember("bond_" + str(st["bond"]).to_lower().replace(" ", "_"))
	if _spirit is LumenSpirit:
		(_spirit as LumenSpirit).set_bonds(StoryProgress.bonds())
		(_spirit as LumenSpirit).spin()
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
	# Nothing is drawn without a window, so there is no frame to wait for (or to save).
	if DisplayServer.get_name() == "headless":
		print("STORY shot ", tag, " (headless, not saved)")
		return
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
	# Dev: --story-step=N starts the chapter at that step (for checking one scene).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--story-step="):
			at = clampi(int(a.trim_prefix("--story-step=")), 0, maxi(0, steps.size() - 1))
			StoryProgress.save_position(id, at, {})
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
	# The portrait and the name tab live outside the box, so they follow it when it hides.
	if _box and not _box.visible:
		_portrait.visible = false
		_name_tab.visible = false
	if _more and _more.visible:
		_more.position.y += sin(_t * 6.0) * 0.25
	# Actors walking to their marks.
	for m in _moving.duplicate():
		var f: Node3D = m[0]
		if not is_instance_valid(f):
			_moving.erase(m)
			continue
		var to: Vector3 = m[1]
		var flat := Vector3(to.x - f.global_position.x, 0, to.z - f.global_position.z)
		if flat.length() < 0.15:
			f.set_speed(0.0)
			if absf(to.y - f.global_position.y) < 1.0:
				f.global_position.y = to.y
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
		_spirit.position.y = scene._player.global_position.y + 1.2 + sin(_t * 2.2) * 0.12
		if _cut and _spirit is LumenSpirit:
			(_spirit as LumenSpirit).look_at_point = null
		if _cut and _spirit_park != null:
			var park: Vector3 = _spirit_park
			var sp := _spirit.global_position
			var k := clampf(delta * 5.0, 0.0, 1.0)
			_spirit.global_position = Vector3(lerpf(sp.x, park.x, k), sp.y, lerpf(sp.z, park.z, k))
			var mid: Vector3 = _cam_look - _spirit.global_position
			_spirit.rotation.y = lerp_angle(_spirit.rotation.y, atan2(mid.x, mid.z), k)
		elif not _cut and _lead_to != null and Vector2((_lead_to as Vector3).x - scene._player.global_position.x, (_lead_to as Vector3).z - scene._player.global_position.z).length() > 4.0:
			# A goal is open: she flies a few steps ahead, toward it, and looks back for you.
			var lead: Vector3 = _lead_to
			var pp: Vector3 = scene._player.global_position
			var dirg := Vector3(lead.x - pp.x, 0, lead.z - pp.z).normalized()
			var ahead: Vector3 = pp + dirg * 2.6 + dirg.cross(Vector3.UP) * 0.5
			var sp2 := _spirit.global_position
			var kk := clampf(delta * 3.5, 0.0, 1.0)
			_spirit.global_position = Vector3(lerpf(sp2.x, ahead.x, kk), pp.y + 1.25 + sin(_t * 2.2) * 0.12, lerpf(sp2.z, ahead.z, kk))
			if _spirit is LumenSpirit:
				(_spirit as LumenSpirit).look_at_point = (pp + Vector3(0, 1.4, 0)) if fmod(_t, 5.0) < 1.6 else (lead + Vector3(0, 1.2, 0))
		elif not _cut:
			if _spirit is LumenSpirit:
				(_spirit as LumenSpirit).look_at_point = null
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
	if _cut and not _dir.is_empty():
		_shake = maxf(0.0, _shake - delta)
		_eval_directed(delta)
	elif _cut:
		_shake = maxf(0.0, _shake - delta)
		var w := clampf(delta * 4.5, 0.0, 1.0)
		# No shot is ever quite still: the camera creeps in while a line is on screen.
		if _box and _box.visible and _push < 0.4:
			var step_in := delta * (0.075 if _shot_mode == "close" else 0.05)
			_push += step_in
			_cam_pos += (_cam_look - _cam_pos).normalized() * step_in
		# A change of shot is a clean cut. Inside a shot the camera only ever eases.
		if _cut_now:
			_cut_now = false
			_cam.global_position = _cam_pos
			if _cam_pos.distance_to(_cam_look) > 0.1:
				_cam.look_at(_cam_look, Vector3.UP)
		w = clampf(delta * 1.8, 0.0, 1.0)
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
