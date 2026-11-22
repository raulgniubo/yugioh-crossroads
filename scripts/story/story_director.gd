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

## The Academy story (Campus) plays through this same director, with chapters of its own
## (CampusData, ids "ac_*") and its own place and memory (CampusProgress, in campus.cfg).
static var campus := false


static func _prog():
	return CampusProgress if campus else StoryProgress


static func _book():
	return CampusData if campus else StoryData


var scene                       # RoamScene
## A cinematic is playing: lines move on by themselves when their voice ends, no key needed.
var _cine := false
var free := false               # riding along in the open world: the chapter is at a list of things to do yourself
var _in_task := false           # a task's conversation is playing
var _tasks: Array = []          # the list being worked through (free mode)
var _task_done := {}            # "index" -> true
var _task_nodes := {}           # index -> [nodes placed for it]
var _task_box: PanelContainer
var _task_list: VBoxContainer
var _task_title: Label
var _task_sig := ""
var _task_count: Label
var _task_next: Label
var _task_key: Label
var _task_more: Label                 # the one line under the goal when the list is folded away
## The list of things to do is folded to its goal and a count until you open it (it was a third
## of the screen). Remembered while the game runs.
static var task_small := true
var chapter := ""
var step := 0
var flags := {}
var _called := {}          # who is called what in this scene (actor key -> the name on their lines)
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
var _room: Array = []          # [middle, radius] of the ground this scene keeps to itself (the "room" step)
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
	if free:
		chapter = str(Router.roam.get("quest", ""))
	_steps = _book().SCRIPTS.get(chapter, [])
	var pos: Dictionary = _prog().position()
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
	if free:
		# Back from a duel that one of the things to do asked for.
		if Router.story_result != "" and flags.has("_duel_task"):
			var ti := str(flags["_duel_task"])
			flags.erase("_duel_task")
			if Router.story_result == "won":
				flags["_after_task"] = ti
			else:
				flags["_lost_" + ti] = true
			Router.story_result = ""
		_run.call_deferred()
		return
	# Coming back from a story duel: note how it went and move on.
	if Router.story_result != "":
		flags.erase("won")
		flags.erase("lost")
		flags[Router.story_result] = true
		Router.story_result = ""
		step += 1
	_rebuild_cast()
	if flags.has("_away"):
		scene._figure.visible = false
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
	_choice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE     # (empty, it must not swallow clicks meant for what is behind it)
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
	if step < _steps.size() and (_steps[step] as Dictionary).has("scene"):
		# The very next thing is a new scene: nobody from the old one needs putting back.
		return
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
	if campus and key != "lumen" and key != "player":
		scene.hide_npcs([key])      # the island's everyday copy of them steps aside while the story has them
	var at: Vector3 = st["at"]
	if scene.city and scene.city.has_method("ground_at") and scene._inside == "":
		at.y = maxf(at.y, float(scene.city.ground_at(at.x, at.z)))
	if scene.city and scene.city.has_method("walk_top") and scene._inside == "":
		at.y = maxf(at.y, float(scene.city.walk_top(at.x, at.z)))
	if st.get("spirit", false):
		if key == "lumen" and not _prog().recalls("met_lumen"):
			_prog().remember("met_lumen")      # from here on she goes with you
		# Lumen: a duel spirit, small and made of light, floating at shoulder height.
		var sp := LumenSpirit.new()
		scene.add_child(sp)
		sp.position = Vector3(at.x, at.y + 1.1, at.z)
		sp.watch = scene._player
		sp.set_bonds(_prog().bonds())
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
	# "plain": true puts them in their own clothes, not the dorm jacket they wear later.
	if st.get("plain", false):
		Avatars.plain[key] = true
	else:
		Avatars.plain.erase(key)
	# "as": a face in the crowd. The story calls them by `key`; they look like the character `as`.
	var body := str(st.get("as", key))
	fig.setup(body, Characters.get_char(body).get("color", Color.WHITE), "", false)
	fig.lively = false
	fig.greets = false
	fig.watch = scene._player
	if st.get("mask", false):
		fig.wear_mask()      # the Midnight Circle: nobody shows their face
	if st.get("sit", false):
		fig.stance = "sit"   # at a desk, on a bench
	# "called": the name on their lines here (a nickname under a mask), not their own.
	if st.has("called"):
		_called[key] = str(st["called"])
	else:
		_called.erase(key)
	if st.has("coat") and Avatars.takes_jacket(body):
		# A coat is only painted on a stand-in; a character with a model of their own already
		# wears what they wear.
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
		# An entrance is a few steps, not a hike: nobody starts more than 6 m out ("far" keeps
		# the full walk for the rare scene that wants it). The walk is at most about three seconds.
		var start: Vector3 = st["from"]
		if not st.get("far", false) and start.distance_to(at) > 6.0:
			start = at + (start - at).normalized() * 6.0
			start.y = (st["from"] as Vector3).y
			fig.position = start
		_moving.append([fig, at, 3.6 if st.get("run", false) else 2.0, face])
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
	# Not under the dark screen: the story waits until the place has got going (Router._settle).
	while Router.loading:
		await get_tree().process_frame
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
		if await _do_step(st):
			return
		step += 1
	_leave()


## Play one step. Returns true when the scene is being replaced (a duel, another world, the end)
## and nothing more must run here.
func _do_step(st: Dictionary) -> bool:
	if st.has("echo"):
		await _echo(st)
	elif st.has("shot") and not st.has("t"):
		await _shot_step(st)
	elif st.has("cap") and not st.has("t"):
		await _cap_step(st)
	elif st.has("credits"):
		await _credits(st)
	elif st.has("remember"):
		_prog().remember(str(st["remember"]))
	elif st.has("cine"):
		_cine = bool(st["cine"]) and not _auto
		_letterbox(_cine)
	elif st.has("merits"):
		Campus.add_merits(int(st["merits"]), str(st.get("why", "")))
		Sfx.play("coin", -6.0)
	elif st.has("campus"):
		await _campus_step(st["campus"])
	elif st.has("pick_deck"):
		await _pick_deck()
	elif st.has("music"):
		Music.play(str(st["music"]))
	elif st.has("sfx") and not st.has("t") and not st.has("act"):
		Sfx.play(str(st["sfx"]), float(st.get("vol", -5.0)), float(st.get("pitch", 1.0)))
	elif st.has("turn"):
		_turn(st)
	elif st.has("scene"):
		if await _do_scene(st):
			return true
	elif st.has("actor"):
		_place(st)
		if st.has("from") and st.get("wait", true):
			# Somebody walks in. The last line leaves the screen and the camera turns to them,
			# so it never looks as if the game stopped listening.
			_box.visible = false
			var comer: Node3D = _actors[str(st["actor"])]
			if _dir.is_empty() and not _skip:
				_shot_for(str(st["actor"]), true)
			await _until_arrived(comer)
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
	elif st.has("tasks"):
		if await _do_tasks(st):
			return true
	elif st.has("bracket"):
		await _bracket_step(st["bracket"])
	elif st.has("roster"):
		await _roster_step(st["roster"])
	elif st.has("tally"):
		# {"tally": name}: one more of something (usually with "if": "won").
		flags["_n_" + str(st["tally"])] = int(flags.get("_n_" + str(st["tally"]), 0)) + 1
	elif st.has("tally_flags"):
		# {"tally_flags": name}: sets the flag "<name>_is_<count>", so lines can say how it went.
		flags["%s_is_%d" % [str(st["tally_flags"]), int(flags.get("_n_" + str(st["tally_flags"]), 0))]] = true
	elif st.has("cup_table"):
		await _board_step(StoryCup.new(st["cup_table"]), "cup%d" % step)
	elif st.has("prize"):
		await _bond(st)
	elif st.has("room"):
		# A scene that needs the ground to itself (a duel with an audience of its own):
		# the people who happen to be chatting there step out until the camera lets go.
		_room = [st["room"], float(st.get("r", 5.0))]
		_make_room([_room[0]], _room[1])
	elif st.has("clash"):
		await _clash(st["clash"])
	elif st.has("goal"):
		if not _in_task:
			_prog().save_position(chapter, step, flags)
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
			# (--story-lose: a duel that may be lost is lost, so the other branch gets walked too.)
			flags.erase("won")
			flags.erase("lost")
			if st["duel"].get("lose_ok", false) and "--story-lose" in OS.get_cmdline_user_args():
				flags["lost"] = true
			else:
				flags["won"] = true
			print("STORY: duel skipped (auto) vs ", st["duel"]["opponent"], "  lost" if flags.has("lost") else "")
		else:
			_start_duel(st["duel"])
			return true
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
	elif st.has("flag"):
		# {"flag": name}: sets a flag of this script (with "if"/"unless": a way to say "and").
		flags[str(st["flag"])] = true
	elif st.has("mask_player"):
		# {"mask_player": true}: you put your own mask on (the Midnight Circle). Gone with the scene.
		if scene and scene._figure and scene._figure.has_method("wear_mask"):
			scene._figure.wear_mask()
	elif st.has("class") and st["class"] is String:
		# {"class": kind}: which version of the class this is ("v0", "v1"...), so lines can ask.
		for k in flags.keys():
			if str(k).length() == 2 and str(k).begins_with("v"):
				flags.erase(k)
		flags["v%d" % CampusClasses.variant(str(st["class"]))] = true
	elif st.has("class_check"):
		# {"class_check": "practice"}: was the duel won the way the professor asked? Sets "met".
		flags.erase("met")
		if flags.has("won") and (_auto or CampusClasses.condition_met(Router.last_stats)):
			flags["met"] = true
	elif st.has("build"):
		await _build_step()
	elif st.has("class_end"):
		await _end_class(st)
		return true
	elif st.has("circle_end"):
		await _end_circle(st)
		return true
	elif st.has("end"):
		await _end(st)
		return true
	return false


## The walking HUD (map, place name, key help) steps aside for cutscenes.
## Does this step play? "if": a choice made this chapter or something the story remembers.
## "unless": the opposite.
func _passes(st: Dictionary) -> bool:
	if st.has("if") and not (flags.has(st["if"]) or _prog().recalls(str(st["if"]))):
		return false
	if st.has("unless") and (flags.has(st["unless"]) or _prog().recalls(str(st["unless"]))):
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
		if not _room.is_empty():
			_make_room([_room[0]], _room[1])
	else:
		for f in _stepped_out:
			if is_instance_valid(f):
				(f as Node3D).visible = true
				_solid(f as Node3D, true)
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
	_room = []
	var district := str(sc.get("district", Router.roam.get("district", "domino")))
	if district != str(Router.roam.get("district", "domino")):
		# Another world: reload there and carry on from the next step.
		if sc.get("away", false):
			flags["_away"] = true
		else:
			flags.erase("_away")
		_prog().save_position(chapter, step, flags)
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
	# "away": a scene you are not in (meanwhile, somewhere else). You come back with the next one.
	if sc.get("away", false):
		flags["_away"] = true
	else:
		flags.erase("_away")
	scene._figure.visible = not flags.has("_away") and not _echo_on
	scene._player.position = pos
	scene._player.velocity = Vector3.ZERO
	scene._yaw = float(sc.get("yaw", scene._yaw))
	scene._figure.rotation.y = scene._yaw + PI
	scene._pivot.position = pos + Vector3(0, 1.45, 0)
	scene._pivot.rotation = Vector3(scene._pitch, scene._yaw, 0)
	scene._entered = ""
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
func _make_room(spots: Array, r := 1.5) -> void:
	var cast: Array = _actors.values()
	cast.append(scene._figure)
	for f in _solver.crowding(spots, r, cast):
		(f as Node3D).visible = false
		_solid(f as Node3D, false)
		_stepped_out.append(f)


## A bystander who stepped out of a scene must not stay there as an invisible wall: their
## body stops colliding while they are hidden, and collides again when they come back.
func _solid(f: Node3D, on: bool) -> void:
	var p := f.get_parent()
	for b in ([p] if p is PhysicsBody3D else []) + f.find_children("*", "PhysicsBody3D", true, false):
		for c in (b as Node).find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).set_deferred("disabled", not on)


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
	if float(best_one[2]) < 45.0 and (not special or float(best_one[2]) < 0.0):
		# Boxed in (a close-up only gives way when there is a wall in it). Step back and show the
		# whole scene instead.
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
	if st.has("lead") and not _skip:
		for li in (st["lead"] if st["lead"] is Array else [st["lead"]]):
			_announce(int(li))
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
	if OS.has_environment("DEV_SAY"):	# dev: check how a long line fits the box
		text = Loc.t(OS.get_environment("DEV_SAY"))
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
		var shown: String = (Profile.duelist_name if who == "player" else Loc.t(str(_called.get(who, info.get("name", who))))).to_upper()
		var changed := _name.text != shown
		_name.text = shown
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
	_fit_text(text, who == "")
	# The line out loud, when there is a voice for it (the Academy story is voiced; a line with
	# no file is simply read).
	var spoken := false
	if who != "" and not _skip:
		Voices.hush(true)
		spoken = Voices.say(who, str(st["t"]), who == "player", true)
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
		if blips % 5 == 0 and who != "" and not spoken:
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
	if _cine or st.get("auto", false):
		# A cinematic: the line holds for as long as it is being said (or read), then moves on.
		var hold := 0.45 if spoken else 1.1 + text.length() * 0.045
		var started := false
		while hold > 0.0 and not _advance_wanted and not _skip:
			await get_tree().process_frame
			if spoken and Voices.talking():
				started = true
			elif not spoken or started or hold < 0.2:
				hold -= get_process_delta_time()
			else:
				hold -= get_process_delta_time() * 0.25    # (the voice has not started yet)
		_advance_wanted = false
		if spoken and Voices.talking():
			Voices.hush(true)
		return
	while not _advance_wanted and not _skip:
		await get_tree().process_frame
	_advance_wanted = false
	if spoken:
		Voices.hush(true)
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
		# Dev: --story-pick=N takes option N of every choice (the last one where there are fewer),
		# so the walk audit can go down the other branches of a chapter too.
		for pick_arg in OS.get_cmdline_user_args():
			if pick_arg.begins_with("--story-pick="):
				picked[0] = clampi(int(pick_arg.trim_prefix("--story-pick=")), 0, options.size() - 1)
	while picked[0] < 0:
		await get_tree().process_frame
	flags[str(options[picked[0]][1])] = true
	# Choices whose name starts with "m_" are remembered for good: later chapters look back.
	if str(options[picked[0]][1]).begins_with("m_"):
		_prog().remember(str(options[picked[0]][1]))
	for c in _choice_box.get_children():
		c.queue_free()
	Sfx.play("click")
	_advance_wanted = false
	# In the Academy your duelist says what you picked out loud.
	if campus and not _auto and not str(options[picked[0]][0]).begins_with("("):
		await get_tree().process_frame
		await _say({"s": "player", "t": str(options[picked[0]][0]), "auto": true})


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
		_walk_check(str(st["goal"]), at, r)
		scene._player.position = Vector3(at.x, scene._player.position.y, at.z + 0.6)
	while true:
		if not is_inside_tree():
			return      # the chapter was left from the pause menu while a goal was up
		await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(scene):
			return
		if st.has("who") and _actors.has(st["who"]):
			at = (_actors[st["who"]] as Node3D).global_position
			scene.extras.waypoint = Vector3(at.x, 0, at.z)
		var d := Vector2(scene._player.global_position.x - at.x, scene._player.global_position.z - at.z).length()
		# (To the door or the stairs the beacon is on, when the goal itself is in another room.)
		var leg: Vector3 = scene.extras.waypoint
		var leg_d := Vector2(scene._player.global_position.x - leg.x, scene._player.global_position.z - leg.z).length()
		var note := str(scene.extras._wp_note)
		_goal_dist.text = Loc.t("%d m away") % int(d if note == "" and leg_d + 0.5 > d else leg_d)
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


# ------------------------------------------------------------------ things to do yourself

## {"tasks": [...], "title": "...", "open": ["academy"]}: the chapter stops telling and hands
## you a list. The world is the open world: every door, every duelist, the map, the clock.
## Each task is something you go and do, in any order unless it "needs" others first:
##   {"talk": key, "at": pos, "label": .., "say": [steps], "duel": {..}, "after": [steps], "retry": [steps]}
##   {"look": pos, "label": .., "say": [steps]}       something to examine
##   {"go": pos, "r": 3.0, "label": .., "say": [steps]}  a place to reach
##   {"travel": district, "label": ..}                go to that world yourself (Worlds, G)
##   {"wins": n, "label": ..}                         win n duels against people in the worlds
##   {"until": "night", "label": ..}                  the clock has to get there (a bench, or the map)
## Any task: "in": district (default: where the list began), "when": "night" (only then),
## "needs": [indices], "optional": true, "thread": name, "flag": name set when done,
## "face", "hollow", "coat", "spirit" for the person standing there.
## Returns true when the scene is being replaced.
func _do_tasks(st: Dictionary) -> bool:
	var home := _district_at(step)
	if not free:
		# Out of the telling and into the open world, where you stand.
		for w in st.get("open", []):
			_prog().remember("open_" + str(w))
		flags["_where"] = home
		flags.erase("_w0")
		_prog().save_position(chapter, step, flags)
		WorldClock.set_look(str(scene.city.tod) if scene.city else "day")
		if st.has("clock"):
			# The list starts at this minute of the day (990 = half past four).
			WorldClock.minutes = float(st["clock"])
		WorldClock.save_data()
		Router.roam["quest"] = chapter
		Router.roam["free"] = false
		Router.roam["story"] = ""
		Router.roam["pos"] = scene._player.position if home == str(Router.roam.get("district", "")) else null
		Router.roam["yaw"] = scene._yaw
		Router.roam.erase("tod")
		_cutscene(true)
		_box.visible = false
		var tw := create_tween()
		tw.tween_property(_flash, "color", Color(0, 0, 0, 1), 0.35)
		await tw.finished
		Router.go(Router.ROAM)
		return true
	_tasks = st["tasks"]
	var here := str(Router.roam.get("district", "domino"))
	_task_done = flags.get("_done", {})
	if not flags.has("_w0"):
		flags["_w0"] = _prog().count("street_wins")
	flags["_where"] = here
	_prog().save_position(chapter, step, flags)
	_build_task_ui(str(st.get("title", "WHAT TO DO")), str(st.get("aim", "")))
	# Whoever the story has in hand is not also standing around as their everyday self.
	var away: Array = (st.get("hide", []) as Array).duplicate()
	for t in _tasks:
		if (t as Dictionary).has("talk"):
			away.append(str(t["talk"]))
	scene.hide_npcs(away)
	if st.get("hide_all", false):
		var all: Array = []
		for n in scene._npcs:
			all.append(str((n[0] as Dictionary).get("id", "")))
		scene.hide_npcs(all)
	# People the chapter has left standing in the world while you are free in it.
	for c in st.get("cast", []):
		if str((c as Dictionary).get("in", home)) == here:
			_place(c, true)
	scene.quest_locked = bool(st.get("lock", false))
	if st.get("frozen", false) or here in (st.get("frozen_in", []) as Array):
		_freeze(true)
	# A duel one of them asked for was just won: what they say after it.
	if flags.has("_after_task"):
		var ai := int(str(flags["_after_task"]))
		flags.erase("_after_task")
		flags["_won_%d" % ai] = true
		await get_tree().create_timer(0.6).timeout
		_place_task(ai, here, home)
		await _task_say(ai, (_tasks[ai] as Dictionary).get("after", []))
		_finish_task(ai)
	if _auto:
		if await _auto_tasks(here, home):
			return true
	var beat := 0.0
	while not _tasks_complete():
		await get_tree().process_frame
		if not is_inside_tree():
			return true
		beat -= get_process_delta_time()
		if beat > 0.0 or _in_task:
			continue
		beat = 0.25
		for i in _tasks.size():
			var t: Dictionary = _tasks[i]
			if _task_done.has(str(i)) or not _task_open(i):
				if _task_done.has(str(i)):
					_clear_task(i)
				continue
			var mine := str(t.get("in", home)) == here
			var now := not t.has("when") or WorldClock.look() == str(t["when"])
			if not _task_listed(i):
				# A lead nobody has given you yet: whoever it is stands there like anybody else,
				# and coming close is how you find it.
				var hp = _task_pos(t)
				if mine and hp != null:
					_place_task(i, here, home, true)
					if Vector2(scene._player.global_position.x - (hp as Vector3).x, scene._player.global_position.z - (hp as Vector3).z).length() < float(t.get("notice", 9.0)):
						_find_task(i, here, home)
				continue
			if t.has("travel"):
				if here == str(t["travel"]):
					_finish_task(i)
			elif t.has("wins"):
				if _prog().count("street_wins") - int(flags.get("_w0", 0)) >= int(t["wins"]):
					_finish_task(i)
			elif t.has("until"):
				if WorldClock.look() == str(t["until"]):
					_finish_task(i)
			elif not mine or not now:
				_clear_task(i)
			else:
				_place_task(i, here, home)
				if t.has("go"):
					var off := Vector2(scene._player.global_position.x - (t["go"] as Vector3).x, scene._player.global_position.z - (t["go"] as Vector3).z).length()
					if off > float(t.get("r", 3.0)) + 1.5:
						_go_armed[i] = true
					elif off < float(t.get("r", 3.0)) and bool(_go_armed.get(i, not flags.has("_lost_%d" % i))):
						# After a loss there you walk away first (to change your deck, say) and come
						# back when you are ready: it does not grab you again where you stand.
						_go_armed[i] = false
						await _run_task(i)
		# Leads arrive one at a time, each with the face of whoever gave it.
		_lead_wait -= 0.25
		if _lead_wait <= 0.0:
			for i in _tasks.size():
				if not _task_done.has(str(i)) and _task_listed(i) and not (flags.get("_seen", {}) as Dictionary).has(str(i)):
					_announce(i)
					_lead_wait = 1.4
					break
		_refresh_task_ui(here, home)
	# Everything that had to be done is done: back to the telling.
	scene.quest_locked = false
	for i in _tasks.size():
		_clear_task(i)
	if _task_box:
		_task_box.visible = false
	scene.extras.clear_waypoint()
	Sfx.play("quest", -4.0)
	Router.toast(Loc.t("The story goes on."))
	await get_tree().create_timer(1.1).timeout
	for k in ["_done", "_w0", "_where", "_after_task", "_duel_task", "_seen", "_found"]:
		flags.erase(k)
	for k in flags.keys():
		if str(k).begins_with("_won_") or str(k).begins_with("_lost_"):
			flags.erase(k)
	step += 1
	_prog().save_position(chapter, step, flags)
	Router.roam.erase("quest")
	Router.roam["pos"] = scene._player.position
	if _audit:
		print("TASKS done step ", step - 1)
	StoryDirector.begin(chapter, true)
	return true


## The world the story is in at step `at`: the district of the last scene before it.
func _district_at(at: int) -> String:
	var d := "domino"
	for i in mini(at + 1, _steps.size()):
		if (_steps[i] as Dictionary).has("scene"):
			d = str(_steps[i]["scene"].get("district", d))
	return d


## Can this task be worked on yet (everything it needs is done)?
func _task_open(i: int) -> bool:
	for n in (_tasks[i] as Dictionary).get("needs", []):
		if not _task_done.has(str(int(n))):
			return false
	return true


func _tasks_complete() -> bool:
	for i in _tasks.size():
		if not _task_done.has(str(i)) and not (_tasks[i] as Dictionary).get("optional", false):
			return false
	return true


func _task_pos(t: Dictionary):
	for k in ["at", "look", "go"]:
		if t.has(k) and t[k] is Vector3:
			return t[k]
	return null


## Put the person (or the mark) for task `i` into the world, with something to press E on.
func _place_task(i: int, here: String, home: String, bare := false) -> void:
	if _task_nodes.has(i):
		return
	var t: Dictionary = _tasks[i]
	if str(t.get("in", home)) != here:
		return
	var made: Array = []
	var at = _task_pos(t)
	if at == null:
		_task_nodes[i] = made
		return
	if t.has("talk") and not _actors.has(str(t["talk"])):
		var key := str(t["talk"])
		var pst := {"actor": key, "at": at, "face": t.get("face", "player")}
		for k in ["hollow", "coat", "spirit", "pale"]:
			if t.has(k):
				pst[k] = t[k]
		_place(pst, true)
		made.append(_actors[key])
		(_actors[key] as Node3D).set_meta("task_key", key)
	if bare:
		_task_nodes[i] = made
		return
	var mark := Label3D.new()
	mark.text = "!" if t.has("talk") else ("?" if t.has("look") else "▼")
	mark.font = UITheme.title_font()
	mark.font_size = 120
	mark.pixel_size = 0.006
	mark.outline_size = 22
	mark.outline_modulate = Color(0.05, 0.04, 0.0, 0.9)
	mark.modulate = UITheme.GOLD
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.render_priority = 4
	mark.position = (at as Vector3) + Vector3(0, 2.55 if t.has("talk") else 1.5, 0)
	mark.set_meta("base_y", mark.position.y)
	scene.add_child(mark)
	made.append(mark)
	if not t.has("go"):
		var label := str(t.get("prompt", ""))
		if label == "":
			label = (Loc.t("Talk to %s") % _name_of(str(t["talk"]))) if t.has("talk") else "Take a look"
		var spot := {"pos": at, "range": 2.3 if t.has("talk") else 1.9, "label": label, "action": func(): _run_task(i), "quest": i}
		scene._spots.append(spot)
		made.append(spot)
	_task_nodes[i] = made


func _clear_task(i: int) -> void:
	if not _task_nodes.has(i):
		return
	for n in _task_nodes[i]:
		if n is Dictionary:
			scene._spots.erase(n)
		elif is_instance_valid(n):
			if (n as Node).has_meta("task_key"):
				_remove(str((n as Node).get_meta("task_key")))
			else:
				(n as Node).queue_free()
	_task_nodes.erase(i)
	scene._near_spot = {}


func _name_of(key: String) -> String:
	if key == "lumen":
		return "Lumen"
	var c := Characters.get_char(key)
	return Loc.t(str(c.get("short", c.get("name", key.capitalize()))))


## What somebody says, played like any scene: the world steps aside, the camera cuts in.
func _task_say(i: int, steps: Array) -> void:
	if steps.is_empty():
		return
	_in_task = true
	scene.story = self
	# Lumen has things to say too: she comes in close for the conversation.
	var lumen_here := false
	for s in steps:
		if str((s as Dictionary).get("s", "")) == "lumen" and not _actors.has("lumen"):
			var pp: Vector3 = scene._player.global_position
			# Beside you, on whichever side is not a lamp post or a wall.
			var at_l := pp + Basis(Vector3.UP, scene._yaw) * Vector3(0.9, 0, 0.4)
			for off: Vector3 in [Vector3(0.9, 0, 0.4), Vector3(-0.9, 0, 0.4), Vector3(0.9, 0, -0.7), Vector3(-0.9, 0, -0.7), Vector3(0, 0, 1.1)]:
				var cand := pp + Basis(Vector3.UP, scene._yaw) * off
				if _solver.blocked_at(Vector3(cand.x, pp.y, cand.z)) != "":
					continue
				# Not under an awning either: she floats at head height and has to be seen.
				var up := PhysicsRayQueryParameters3D.create(Vector3(cand.x, pp.y + 0.9, cand.z), Vector3(cand.x, pp.y + 3.4, cand.z))
				up.exclude = [scene._player.get_rid()]
				var side := PhysicsRayQueryParameters3D.create(pp + Vector3(0, 1.4, 0), Vector3(cand.x, pp.y + 1.4, cand.z))
				side.exclude = [scene._player.get_rid()]
				var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
				if space.intersect_ray(up).is_empty() and space.intersect_ray(side).is_empty():
					at_l = cand
					break
			_place({"actor": "lumen", "at": at_l, "face": "player", "spirit": true}, true)
			lumen_here = true
			break
	for s in steps:
		if _passes(s):
			await _do_step(s)
	_cutscene(false)
	if lumen_here:
		_remove("lumen")
		_spirit = null
		if scene.partner and is_instance_valid(scene.partner):
			scene.partner.visible = true
	scene.story = null
	_in_task = false


## Do task `i`: its conversation, then its duel if it has one.
func _run_task(i: int) -> void:
	if _in_task or _task_done.has(str(i)):
		return
	var t: Dictionary = _tasks[i]
	var again: bool = flags.has("_lost_%d" % i) and t.has("retry")
	await _task_say(i, t["retry"] if again else t.get("say", []))
	if t.has("duel") and not flags.has("_won_%d" % i):
		if _auto and not "--story-duel" in OS.get_cmdline_user_args():
			print("STORY: task duel skipped (auto) vs ", t["duel"]["opponent"])
			flags["_won_%d" % i] = true
			await _task_say(i, t.get("after", []))
		else:
			flags["_duel_task"] = str(i)
			_in_task = true
			scene.story = self
			_start_duel((t["duel"] as Dictionary).merged({"task": true}))
			return
	_finish_task(i)


func _finish_task(i: int) -> void:
	if _task_done.has(str(i)):
		return
	var t: Dictionary = _tasks[i]
	_task_done[str(i)] = true
	flags["_done"] = _task_done
	if t.has("flag"):
		flags[str(t["flag"])] = true
	if t.has("remember"):
		_prog().remember(str(t["remember"]))
	if t.has("reveals"):
		var fnd: Dictionary = flags.get("_found", {})
		for j in t["reveals"]:
			fnd[str(int(j))] = true
		flags["_found"] = fnd
	if t.has("dp"):
		Collection.dp += int(t["dp"])
		Collection.save()
		Router.toast(Loc.t("+%d Duel Points") % int(t["dp"]))
	if t.has("merits") and campus:
		Campus.add_merits(int(t["merits"]), str(t.get("label", "")))
	if t.has("bond") and campus:
		Campus.add_bond(str(t["bond"]), 1)
	_prog().save_position(chapter, step, flags)
	_clear_task(i)
	Sfx.play("sparkle", -6.0)
	if _audit or _auto:
		print("TASK done ", step, ":", i, " ", str(t.get("label", "")))


## --story-auto: do every task by itself, in order, going to other worlds as needed.
func _auto_tasks(here: String, home: String) -> bool:
	await get_tree().create_timer(0.6).timeout
	var guard := 0
	while not _tasks_complete() and guard < 60:
		guard += 1
		for i in _tasks.size():
			var t: Dictionary = _tasks[i]
			if _task_done.has(str(i)) or not _task_open(i):
				continue
			var where := str(t.get("travel", t.get("in", home)))
			if where != here:
				print("TASK auto travel ", here, " -> ", where)
				_prog().save_position(chapter, step, flags)
				Router.roam["district"] = where
				Router.roam["pos"] = null
				Router.go(Router.ROAM)
				return true
			if t.has("wins") or t.has("until") or t.has("travel"):
				_finish_task(i)
				continue
			_place_task(i, here, home)
			var at = _task_pos(t)
			if at != null:
				_walk_check(str(t.get("label", "task %d" % i)), at, float(t.get("r", 2.4)))
				scene._player.position = Vector3((at as Vector3).x, (at as Vector3).y, (at as Vector3).z + 1.4)
				scene._player.velocity = Vector3.ZERO
			await get_tree().create_timer(0.3).timeout
			await _run_task(i)
	return false


## The audit (--story-audit) walks to each goal before it jumps there: is there a way on foot from
## where the player stands? (See WalkCheck.) A goal in another room is walked the way a player goes:
## to the "Leave" mat of each room on the way out, to the door of each room on the way in (rooms
## are built far apart and a door carries you across), and the last stretch to the goal itself.
func _walk_check(what: String, at: Vector3, r: float) -> void:
	if not _audit or scene == null or scene._player == null:
		return
	var from: Vector3 = scene._player.global_position
	var near_kame := func(p: Vector3) -> bool: return p.distance_to(ShopInterior.AT) < 30.0
	if near_kame.call(from) != near_kame.call(at):
		print("WALK door step ", step, "  ", what, "  (through the Kame Game door, not walked)")
		return
	# The same doors the guide sends the player through (RoamExtras.place_chain).
	var a: Array = scene.extras.place_chain(_place_of(from))
	var b: Array = scene.extras.place_chain(_place_of(at))
	var ia := 0
	while ia < a.size() and not (a[ia] in b):
		ia += 1
	if ia >= a.size():
		print("WALK BLOCKED step ", step, "  ", what, "  no chain of doors from '", a[0], "' to '", b[0], "'")
		return
	var ib := b.find(a[ia])
	var legs: Array = []
	var pos := from
	for i in ia:
		var rd: Dictionary = scene._rooms[a[i]]
		legs.append([pos, (rd["at"] as Vector3) + Vector3(0, 0, (rd["half"] as Vector2).y - 0.7), 1.7, "the way out of " + str(a[i])])
		pos = scene.leave_to(str(a[i]))["pos"]
	for i in range(ib - 1, -1, -1):
		var rd: Dictionary = scene._rooms[b[i]]
		var inner: Dictionary = AcademyRooms.inner_door(str(b[i]))
		if str(b[i + 1]) != "" and not inner.is_empty():
			# Up the stairs of the hall and along the gallery to the bedroom's door.
			legs.append([pos, inner["foot"], 1.6, "the stairs to " + str(b[i])])
			legs.append([inner["foot"], inner["pos"], 1.25, "the door of " + str(b[i]) + " upstairs"])
		else:
			var out: Vector3 = rd.get("out", Vector3(0, 0, 1))
			legs.append([pos, (rd["door"] as Vector3) + out * (0.9 if not rd.has("step") else 0.6), 2.3 if not rd.has("step") else 1.3, "the door of " + str(b[i])])
		pos = (rd["at"] as Vector3) + Vector3(0, 0, (rd["half"] as Vector2).y - 1.8)
	legs.append([pos, at, maxf(r, 1.2), what])
	var t0 := Time.get_ticks_msec()
	var cells := 0
	for leg in legs:
		var got: Dictionary = WalkCheck.reach(scene._player, leg[0], leg[1], float(leg[2]))
		cells += int(got["cells"])
		if not bool(got["ok"]):
			print("WALK BLOCKED step ", step, "  ", what, "  at: ", leg[3], "  from ", (leg[0] as Vector3).snapped(Vector3(0.1, 0.1, 0.1)), " to ", (leg[1] as Vector3).snapped(Vector3(0.1, 0.1, 0.1)),
					"  got as close as ", (got["closest"] as Vector3).snapped(Vector3(0.1, 0.1, 0.1)), " (", snappedf(float(got["left"]), 0.1), " m short)  cells ", got["cells"])
			return
	var via: Array = []
	for i in legs.size() - 1:
		via.append(str(legs[i][3]))
	print("WALK ok step ", step, "  ", what, "  legs ", legs.size(), "  cells ", cells, "  ", Time.get_ticks_msec() - t0, " ms", ("  via " + ", ".join(via)) if not via.is_empty() else "")


## The room a point is in ("" out of doors).
func _place_of(p: Vector3) -> String:
	for rk in scene._rooms:
		var rd: Dictionary = scene._rooms[rk]
		var c: Vector3 = rd["at"]
		var h: Vector2 = rd["half"]
		if absf(p.x - c.x) <= h.x + 1.0 and absf(p.z - c.z) <= h.y + 1.0:
			return str(rk)
	return ""


## A room, the room its door is in, and so on out to the open air: ["red_room_2", "dorm_red", ""].
func _place_chain(place: String) -> Array:
	var out: Array = [place]
	var guard := 0
	while place != "" and guard < 6:
		place = _place_of(scene._rooms[place]["door"])
		out.append(place)
		guard += 1
	return out


func _build_task_ui(title: String, goal := "") -> void:
	if _task_box != null:
		return
	_task_box = PanelContainer.new()
	_task_box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.88), 16, Color(UITheme.GOLD, 0.6)))
	_task_box.position = Vector2(30, 232)
	_task_box.custom_minimum_size = Vector2(380, 0)
	_task_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_task_box)
	var gm := MarginContainer.new()
	for side in ["left", "right"]:
		gm.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		gm.add_theme_constant_override("margin_" + side, 9)
	gm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_task_box.add_child(gm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gm.add_child(v)
	var ch := ""
	for c in _book().CHAPTERS:
		if c["id"] == chapter:
			ch = Loc.t(str(c["title"])).to_upper() + "   ·   "
	# With a goal, the small line names the stretch of the chapter and the big line says what
	# all of it is for.
	v.add_child(UITheme.label(ch + (Loc.t(title).to_upper() if goal != "" else Loc.t("YOUR MOVE")), 13, UITheme.GOLD, UITheme.semi_font()))
	_task_title = UITheme.label(Loc.t(goal if goal != "" else title), 19, Color.WHITE, UITheme.semi_font())
	_task_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_task_title.custom_minimum_size = Vector2(348, 0)
	v.add_child(_task_title)
	# What to do next and where, always in sight (also with the list folded away).
	_task_next = UITheme.label("", 16, UITheme.GOLD, UITheme.semi_font())
	_task_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_task_next.custom_minimum_size = Vector2(348, 0)
	_task_next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_task_next)
	_task_list = VBoxContainer.new()
	_task_list.add_theme_constant_override("separation", 1)
	_task_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_task_list)
	# The foot of the box: how far along you are, and a small button that says what opens the
	# list. The whole box is the button: a click anywhere on it does what Tab does.
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(foot)
	_task_count = UITheme.label("", 15, Color(0.78, 0.84, 0.95, 0.9), UITheme.semi_font())
	_task_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(_task_count)
	var pill := PanelContainer.new()
	var pill_sb := UITheme.panel_box(Color(UITheme.GOLD, 0.13), 9, Color(UITheme.GOLD, 0.55))
	pill_sb.set_content_margin_all(0)
	pill_sb.shadow_size = 0
	pill.add_theme_stylebox_override("panel", pill_sb)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A small chip on the line, never stretched to the height or width of the box.
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	foot.add_child(pill)
	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left", 8)
	pm.add_theme_constant_override("margin_right", 10)
	pm.add_theme_constant_override("margin_top", 3)
	pm.add_theme_constant_override("margin_bottom", 3)
	pm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(pm)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 8)
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pm.add_child(ph)
	var cap := PanelContainer.new()
	var cap_sb := UITheme.panel_box(Color(0.9, 0.92, 1.0, 0.95), 5, Color(0.55, 0.6, 0.75))
	cap_sb.set_content_margin_all(0)
	cap_sb.shadow_size = 0
	cap.add_theme_stylebox_override("panel", cap_sb)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ph.add_child(cap)
	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 6)
	cm.add_theme_constant_override("margin_right", 6)
	cm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(cm)
	_task_key = UITheme.label("Tab", 13, Color(0.08, 0.1, 0.18), UITheme.semi_font())
	_task_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cm.add_child(_task_key)
	_task_more = UITheme.label("", 15, UITheme.GOLD, UITheme.semi_font())
	_task_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ph.add_child(_task_more)
	_task_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_task_box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_task_box.tooltip_text = Loc.t("Click to open or fold away the list of what there is to do.")
	_task_box.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_task_box.accept_event()
			_toggle_tasks())
	Sfx.play("quest", -6.0)


## One line per task, as [text, state] with state "done" | "open" | "away" | "wait".
func task_rows(here: String, home: String) -> Array:
	var rows: Array = []
	for i in _tasks.size():
		var t: Dictionary = _tasks[i]
		if not _task_listed(i):
			continue
		var text := Loc.t(str(t.get("label", "")))
		var state := "open"
		var place := ""      # where this one is, in plain words
		if _task_done.has(str(i)):
			state = "done"
		else:
			var where := str(t.get("in", home))
			if not t.has("travel") and not t.has("wins") and not t.has("until") and where != here:
				# Somewhere else: say where, and how to get there, in so many words.
				place = Loc.t("In %s. Open Worlds (G) to travel there.") % Loc.t(str(RoamData.district(where).get("name", where)))
				state = "away"
			elif t.has("when") and WorldClock.look() != str(t["when"]):
				text += "   (" + Loc.t({"night": "at night", "day": "by day", "sunset": "in the evening", "dawn": "at dawn"}.get(str(t["when"]), "")) + ")"
				state = "wait"
			elif t.has("wins"):
				text += "   %d / %d" % [mini(int(t["wins"]), _prog().count("street_wins") - int(flags.get("_w0", 0))), int(t["wins"])]
				var nd = _nearest_duelist()
				place = Loc.t("Any duelist you can challenge counts, in any world.")
				if nd != null:
					place += "  " + Loc.t("Nearest one here: %d m, the beacon is on them.") % _meters(nd.global_position)
				else:
					place += "  " + Loc.t("Nobody to challenge is out here right now.")
			else:
				var at = _task_pos(t)
				if at != null and scene != null and scene._player != null:
					place = _where_words(at)
			if t.get("optional", false):
				text += "   " + Loc.t("(optional)")
		var sub := lead_sub(i)
		if place != "":
			sub = place + ("\n      " + sub if sub != "" else "")
		rows.append([text, state, sub, i])
	return rows


## Where a spot is from where you stand, in plain words: in this room, upstairs, out of this
## building, inside another one. (Rooms are built far apart, so metres to a spot in another room
## mean nothing: "80 m" for your own room, one floor up.)
func _where_words(at: Vector3) -> String:
	var ex = scene.extras
	var room := str(ex._room_of(at))
	var here := str(scene._inside)
	if room == here:
		return Loc.t("Here, %d m away. Follow the beacon.") % _meters(at)
	var down: Array = ex.place_chain(room)
	if not here in down:
		return Loc.t("In another place. Leave this room first: the beacon is on the way out.")
	var next := str(down[down.find(here) - 1])
	var rd: Dictionary = scene._rooms.get(next, {})
	if here == "":
		var door: Vector3 = (rd["door"] as Vector3) if rd.has("door") else at
		return Loc.t("Inside %s, %d m away. Follow the beacon to its door.") % [Loc.t(str(rd.get("name", next))), _meters(door)]
	var inner: Dictionary = AcademyRooms.inner_door(next)
	if not inner.is_empty() and scene._player.global_position.y < float((inner["pos"] as Vector3).y) - 1.4:
		return Loc.t("Upstairs in this building. The beacon is at the foot of the stairs.")
	return Loc.t("Upstairs, door %s. The beacon is on the door.") % next.get_slice("_", next.get_slice_count("_") - 1)


## How far something is from you, in whole steps of 5 m (so the list is not redrawn every step).
func _meters(at: Vector3) -> int:
	if scene == null or scene._player == null:
		return 0
	return int(round(scene._player.global_position.distance_to(at) / 5.0)) * 5


## The nearest person in this world you can challenge to a street duel (somebody you have not
## beaten yet comes first), or null when nobody is out.
func _nearest_duelist():
	if scene == null or scene._player == null:
		return null
	var best = null
	var best_d := 1e9
	for n in scene._npcs:
		var d: Dictionary = n[0]
		var f = n[1]
		if not d.has("duel") or f == null or not is_instance_valid(f) or not (f as Node3D).visible:
			continue
		if (d.get("night", false) or d.has("hours")) and not scene._npc_out(d):
			continue
		var dist: float = (f as Node3D).global_position.distance_to(scene._player.global_position) + (400.0 if scene._beaten.has(d["id"]) else 0.0)
		if dist < best_d:
			best_d = dist
			best = f
	return best


## "Yugi  ·  Kaiba will not look at anyone who is not on his board."
func lead_sub(i: int) -> String:
	var t: Dictionary = _tasks[i]
	var who := str(t.get("from", ""))
	var why := Loc.t(str(t.get("why", ""))) if t.has("why") else ""
	if who == "":
		return why
	return _name_of(who) + ("   ·   " + why if why != "" else "")


## The words that gave you this lead: "Yugi: ..." ("" when nobody said it in so many words).
func lead_quote(i: int) -> String:
	var lines: Array = []
	for k in range(maxi(0, step - 60), mini(step, _steps.size())):
		lines.append(_steps[k])
	for t in _tasks:
		for part in ["say", "retry", "after"]:
			lines.append_array((t as Dictionary).get(part, []))
	var out := ""
	for ln in lines:
		var d: Dictionary = ln
		for key in ["lead", "told"]:
			if not d.has(key) or not d.has("t"):
				continue
			var marks: Array = d[key] if d[key] is Array else [d[key]]
			if marks.has(i) or marks.has(float(i)):
				var who := str(d.get("s", ""))
				var said := Loc.t(str(d["t"])).replace("{player}", Profile.duelist_name)
				out = (_name_of(who) + ": " if who != "" and who != "player" else "") + said
	return out


## Is this lead on your list (given to you, or found)?
func _task_listed(i: int) -> bool:
	if _task_done.has(str(i)):
		return true
	if not _task_open(i):
		return false
	return not (_tasks[i] as Dictionary).get("hidden", false) or (flags.get("_found", {}) as Dictionary).has(str(i))


func _find_task(i: int, here: String, home: String) -> void:
	var fnd: Dictionary = flags.get("_found", {})
	fnd[str(i)] = true
	flags["_found"] = fnd
	_clear_task(i)
	_place_task(i, here, home)


## The list a "lead" mark on a line points at: the one in play, or the next one coming.
func _lead_tasks() -> Array:
	if free and not _tasks.is_empty():
		return _tasks
	for k in range(step, _steps.size()):
		if (_steps[k] as Dictionary).has("tasks"):
			return _steps[k]["tasks"]
	return []


var _lead_wait := 0.8
var _lead_live := 0
var _lead_cards: Array = []     # the lead cards on screen right now


## A lead is handed to you: a card slides in with who it came from, what it is and why.
func _announce(i: int) -> void:
	var tasks := _lead_tasks()
	if i < 0 or i >= tasks.size():
		return
	var seen: Dictionary = flags.get("_seen", {})
	if seen.has(str(i)) or (free and tasks == _tasks and _task_done.has(str(i))):
		return          # already given, or already done before anybody mentioned it
	seen[str(i)] = true
	flags["_seen"] = seen
	var fnd: Dictionary = flags.get("_found", {})
	fnd[str(i)] = true
	flags["_found"] = fnd
	var t: Dictionary = tasks[i]
	if _audit or _auto:
		print("LEAD ", i, " from ", str(t.get("from", "")), ": ", str(t.get("label", "")))
	if _skip:
		return
	var who := str(t.get("from", ""))
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.045, 0.065, 0.14, 0.95), 14, Color(UITheme.GOLD, 0.85)))
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pc.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pc.offset_right = -30
	_lead_live += 1
	_ui.add_child(pc)
	var mg := MarginContainer.new()
	for side in ["left", "right"]:
		mg.add_theme_constant_override("margin_" + side, 14)
	for side in ["top", "bottom"]:
		mg.add_theme_constant_override("margin_" + side, 10)
	mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(mg)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mg.add_child(h)
	if who != "" and who != "player":
		var face := TextureRect.new()
		face.texture = _face(who)
		face.custom_minimum_size = Vector2(60, 76)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(face)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UITheme.label(Loc.t("NEW LEAD") + ("   ·   " + _name_of(who).to_upper() if who != "" and who != "player" else ""), 14, UITheme.GOLD, UITheme.semi_font()))
	var tl := UITheme.label(Loc.t(str(t.get("label", ""))), 19, Color.WHITE, UITheme.semi_font())
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(400, 0)
	v.add_child(tl)
	if t.has("why"):
		var wl := UITheme.label(Loc.t(str(t["why"])), 15, Color(0.78, 0.83, 0.93, 0.9))
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wl.custom_minimum_size = Vector2(400, 0)
		v.add_child(wl)
	# Under the Duel Points box, and under any lead that is still showing: each card is as tall
	# as its text, so the next one starts where the last one really ends (they used to be placed
	# a fixed step apart and landed on each other).
	var top := 374.0
	for c in _lead_cards:
		if is_instance_valid(c):
			top = maxf(top, float(c.get_meta("foot", 0.0)) + 10.0)
	pc.offset_top = top
	pc.set_meta("foot", top + pc.get_combined_minimum_size().y)
	_lead_cards = _lead_cards.filter(func(c): return is_instance_valid(c))
	_lead_cards.append(pc)
	# Wrapped text only knows its real height once it has been laid out: settle them again then.
	if not get_tree().process_frame.is_connected(_flow_leads):
		get_tree().process_frame.connect(_flow_leads, CONNECT_ONE_SHOT)
	Sfx.play("quest", -9.0, 1.15)
	pc.modulate.a = 0.0
	pc.offset_left += 40
	pc.offset_right += 40
	var tw := pc.create_tween()
	tw.set_parallel()
	tw.tween_property(pc, "modulate:a", 1.0, 0.2)
	tw.tween_property(pc, "offset_right", -30.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(4.6)
	tw.tween_property(pc, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		_lead_live = maxi(0, _lead_live - 1)
		_lead_cards.erase(pc)
		pc.queue_free())


func _flow_leads() -> void:
	await get_tree().process_frame
	var y := 374.0
	for c in _lead_cards:
		if is_instance_valid(c):
			(c as Control).position.y = y
			y += (c as Control).size.y + 10.0
			c.set_meta("foot", y - 10.0)


func _refresh_task_ui(here: String, home: String) -> void:
	if _task_box == null:
		return
	# Never over the map, the menu or anything else that is open on top of the world.
	var covered: bool = scene != null and (scene._overlay_open or scene._pause != null or (scene._map_full != null and scene._map_full.visible))
	_task_box.visible = not _cut and not covered
	_task_box.size = Vector2.ZERO          # (never taller than what is in it)
	var rows := task_rows(here, home)
	var sig := str(rows) + str(task_small)
	if sig != _task_sig:
		_task_sig = sig
		# The next step: something you can do right here first, then something that has to
		# wait for the hour, then something in another world. What is optional comes last.
		var nxt := []
		var rank := 99
		for r in rows:
			if r[1] == "done":
				continue
			var k: int = {"open": 0, "wait": 1, "away": 2}.get(str(r[1]), 3) + (10 if bool((_tasks[int(r[3])] as Dictionary).get("optional", false)) else 0)
			if k < rank:
				rank = k
				nxt = r
		if nxt.is_empty():
			_task_next.visible = false
		else:
			_task_next.visible = true
			_task_next.text = "▸  " + Loc.t("Next:") + "  " + str(nxt[0]) + "\n" + str(nxt[2]).get_slice("\n", 0)
			_task_next.add_theme_color_override("font_color", Color("ffb38a") if str(nxt[1]) == "away" else UITheme.GOLD)
		_task_next.custom_minimum_size.x = 348.0 if task_small else 460.0
		for c in _task_list.get_children():
			_task_list.remove_child(c)
			c.queue_free()
		var done_n := 0
		for r in rows:
			if r[1] == "done":
				done_n += 1
		var key_name := "R3" if Pad.connected else "Tab"
		_task_list.visible = not task_small
		_task_box.custom_minimum_size.x = 380.0 if task_small else 500.0
		_task_title.custom_minimum_size.x = 348.0 if task_small else 460.0
		_task_count.text = Loc.t("%d of %d done") % [done_n, rows.size()]
		_task_key.text = key_name
		_task_more.text = (Loc.t("Show all %d tasks  ▾") % rows.size()) if task_small else Loc.t("Hide the list  ▴")
		_task_box.size = Vector2.ZERO
		for r in (rows if not task_small else []):
			var done: bool = r[1] == "done"
			var l := UITheme.label(("✔  " if done else "•  ") + str(r[0]), 18,
					Color(0.55, 0.9, 0.62, 0.85) if done else (Color(0.75, 0.8, 0.9, 0.8) if r[1] in ["away", "wait"] else Color.WHITE), UITheme.semi_font())
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(460, 0)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_task_list.add_child(l)
			if not done and str(r[2]) != "":
				# Who gave it to you, and what for.
				var sl := UITheme.label("      " + str(r[2]), 14, Color(0.72, 0.78, 0.9, 0.78))
				sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				sl.custom_minimum_size = Vector2(460, 0)
				sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_task_list.add_child(sl)
	# The beacon stands on the nearest thing still to do here.
	var best = null
	var best_d := 1e9
	var best_label := ""
	for i in _tasks.size():
		var t: Dictionary = _tasks[i]
		if _task_done.has(str(i)) or not _task_open(i) or str(t.get("in", home)) != here:
			continue
		if t.has("when") and WorldClock.look() != str(t["when"]):
			continue
		var at = _task_pos(t)
		if at == null and t.has("wins"):
			# "Win 2 street duels" has no place of its own: it points at the nearest person
			# you can challenge.
			var nd = _nearest_duelist()
			if nd != null:
				at = (nd as Node3D).global_position
				at = Vector3(snappedf(at.x, 2.0), at.y, snappedf(at.z, 2.0))      # (they walk: do not move the beacon every step)
		if at == null or not scene.extras.reachable(at):
			continue      # (never a beacon on a place that is not in this world)
		var d: float = scene.extras.reach_point(at).distance_to(scene._player.global_position)
		if t.get("optional", false):
			d += 500.0
		if d < best_d:
			best_d = d
			best = at
			best_label = Loc.t(str(t.get("label", "")))
	if best == null:
		if scene.extras.has_waypoint() and _task_wp:
			scene.extras.clear_waypoint()
		_task_wp = false
	elif not _task_wp or (_task_wp_at as Vector3).distance_to(best) > 0.1:
		_task_wp = true
		_task_wp_at = best
		scene.extras.set_waypoint(best, best_label)
	# The marks bob.
	for i in _task_nodes:
		for n in _task_nodes[i]:
			if n is Label3D and is_instance_valid(n):
				(n as Label3D).position.y = float((n as Label3D).get_meta("base_y", 2.5)) + sin(_t * 3.2) * 0.08


var _go_armed := {}
var _task_wp := false
var _task_wp_at := Vector3.ZERO


## In a word, what to do next (for Lumen, when asked).
func task_hint() -> String:
	var here := str(Router.roam.get("district", "domino"))
	for r in task_rows(here, _district_at(step)):
		if r[1] != "done":
			return str(r[0])
	return ""


# ------------------------------------------------------------------ a duel you watch

## {"clash": {"a": key, "b": key, "lp": [4000, 4000], "beats": [[who, "CARD OR MOVE", "line", damage], ...], "win": "a"}}
## Two duelists who are not you have it out on screen: a cut-in for every big play, Life Points
## coming down, a winner. `who` is "a" or "b"; `damage` is what the other side loses.
func _clash(c: Dictionary) -> void:
	_cutscene(true)
	_box.visible = false
	_caption("")
	var ka := str(c["a"])
	var kb := str(c["b"])
	var fa := _fig(ka)
	var fb := _fig(kb)
	if fa and fb:
		var to: Vector3 = fb.global_position - fa.global_position
		fa.rotation.y = atan2(to.x, to.z)
		fb.rotation.y = atan2(-to.x, -to.z)
	var lp: Array = (c.get("lp", [4000, 4000]) as Array).duplicate()
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.9), 14, Color(UITheme.GOLD, 0.55)))
	plate.set_anchors_preset(Control.PRESET_CENTER_TOP)
	plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plate.offset_top = 96
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	plate.add_child(row)
	var la := UITheme.label("", 30, Color.WHITE, UITheme.title_font())
	var mid := UITheme.label("VS", 22, UITheme.GOLD, UITheme.title_font())
	var lb := UITheme.label("", 30, Color.WHITE, UITheme.title_font())
	row.add_child(la)
	row.add_child(mid)
	row.add_child(lb)
	var show_lp := func():
		la.text = "%s   %d" % [_name_of(ka).to_upper(), int(lp[0])]
		lb.text = "%d   %s" % [int(lp[1]), _name_of(kb).to_upper()]
	show_lp.call()
	if not _skip and fa and fb:
		# The duel takes the camera over from whatever shot came before it.
		_dir = {}
		_cam.fov = StoryCamera.FOV
		_clash_shot(ka, kb)
	if not _skip:
		Sfx.play("gong", -6.0)
		await get_tree().create_timer(0.9).timeout
	for beat in c.get("beats", []):
		var who := str(beat[0])
		var key := ka if who == "a" else kb
		var col: Color = Characters.get_char(key).get("color", UITheme.ACCENT)
		if not _skip:
			_shot_for(key, false)
			var f := _fig(key)
			if f is RoamFigure:
				(f as RoamFigure).gesture("cheer", 0.2)
			# The duelist says the line out loud, and the band stays for as long as it takes.
			var line := str(beat[2]) if beat.size() > 2 else ""
			var hold := 0.85
			if line != "" and Voices.say(key, line, false, true):
				hold = maxf(hold, Voices.length(key, line, false) + 0.25)
			await CutIn.play(_ui, 0 if who == "a" else 1, key, Loc.t(str(beat[1])), Loc.t(line), col, hold, false)
			var waited := 0.0
			while Voices.talking() and waited < 6.0 and not _skip:
				await get_tree().process_frame
				waited += get_process_delta_time()
		var dmg := int(beat[3]) if beat.size() > 3 else 0
		if dmg > 0:
			var other := 1 if who == "a" else 0
			var from := int(lp[other])
			lp[other] = maxi(0, from - dmg)
			if not _skip:
				Sfx.play("hit", -4.0)
				_shake = 0.35
				var tw := create_tween()
				tw.tween_method(func(v: float):
					var keep: int = int(lp[other])
					lp[other] = int(v)
					show_lp.call()
					lp[other] = keep, float(from), float(lp[other]), 0.5)
				await tw.finished
			show_lp.call()
	var winner := ka if str(c.get("win", "a")) == "a" else kb
	if not _skip:
		Sfx.play("win", -6.0)
		_shot_for(winner, false)
		mid.text = Loc.t("%s WINS") % _name_of(winner).to_upper()
		la.visible = false
		lb.visible = false
		await get_tree().create_timer(1.4).timeout
	plate.queue_free()
	if _audit or _auto:
		print("CLASH ", ka, " vs ", kb, " -> ", winner)


## Both duelists in one frame, with `ka` on the left like their name on the plate.
func _clash_shot(ka: String, kb: String) -> void:
	var sa := _subject(ka)
	var sb := _subject(kb)
	var pa: Vector3 = sa["p"]
	var pb: Vector3 = sb["p"]
	var mid := (pa + pb) * 0.5
	var ab := Vector3(pb.x - pa.x, 0, pb.z - pa.z)
	var gap := ab.length()
	if gap < 0.2:
		_shot_for(ka, true)
		return
	# The camera looks along `fwd`; its right-hand side is the way from a to b.
	var fwd := Vector3.UP.cross(ab / gap)
	var heads: Array = [pa + Vector3(0, float(sa["h"]), 0), pb + Vector3(0, float(sb["h"]), 0)]
	var cands: Array = []
	for ai in 5:
		var ang: float = [0.0, 0.28, -0.28, 0.55, -0.55][ai]
		for di in 3:
			var d: float = gap * 0.85 + 3.0 + 1.3 * float(di)
			for li in 3:
				var cam := mid - (Basis(Vector3.UP, ang) * fwd) * d + Vector3(0, [1.7, 2.3, 1.25][li], 0)
				cands.append([cam, StoryCamera.aim_for(cam, heads, 0.3), -2.0 * float(ai) - 2.5 * float(di) - 1.5 * float(li)])
	_solver.survey(mid, 22.0, [_fig(ka), _fig(kb)])
	_take(_solver.pick(cands, [sa, sb]), "wide", [])
	_shot_subs = [sa, sb]
	_spirit_park = null


func _start_duel(d: Dictionary) -> void:
	_prog().save_position(chapter, step, flags)
	# A class, or a night at the Circle, fills in its own duel: which problem, which decks, which rule.
	if d.has("class"):
		d = d.merged(CampusClasses.duel(str(d["class"])), true)
		if str(d["class"]) == "build" and flags.has("_deck"):
			d["my_list"] = flags["_deck"]
	elif d.has("circle"):
		d = d.merged(CampusCircle.duel(int(d["circle"]), str(d.get("opp_deck", ""))), true)
	Router.roam["pos"] = scene._player.position
	Router.roam["yaw"] = scene._yaw
	var deck: String = Collection.active_deck()
	if not CardData.has_deck(deck):
		deck = Collection.fallback_deck()
	var opp_deck := str(d.get("opp_deck", d["opponent"]))
	if not CardData.has_deck(opp_deck):
		opp_deck = str(d.get("fallback", "kairo"))
	# Which version of their deck they bring (DeckTiers): simpler early in the story, whole for the
	# bosses. Hard brings each one a step stronger, Extreme two.
	# (In the Academy, with your own collection brought along, everybody comes a step stronger.)
	var harder := Campus.deck_steps() if campus else Saves.story_difficulty()
	opp_deck = DeckTiers.with_version(opp_deck, DeckTiers.shift(str(d.get("deck_tier", "full")), harder))
	# "opp_deck_exact": that very deck, card for card (the Circle's swap night: they play yours).
	if d.has("opp_deck_exact") and CardData.has_deck(str(d["opp_deck_exact"])):
		opp_deck = str(d["opp_deck_exact"])
	# "my_deck": you are lent one for this duel (a class, the Circle).
	if d.has("my_deck") and CardData.has_deck(str(d["my_deck"])):
		deck = str(d["my_deck"])
	Router.match_state = {}
	Router.duel_config = {
		"opponent": d["opponent"], "opponent_deck": opp_deck, "player_deck": deck, "player_char": "player",
		"difficulty": clampi(int(d.get("difficulty", 1)) + Saves.story_difficulty() - 1, 0, 3), "field": d.get("field", "battlecity"), "turbo": d.get("turbo", false),
		"story": true, "lose_ok": d.get("lose_ok", false), "return_to": Router.ROAM, "continue_label": Loc.t("Continue Story"),
	}
	# Whoever is in a dorm jacket in the scene wears it in the duel too (you included).
	var of = _actors.get(str(d["opponent"]))
	if of and is_instance_valid(of) and of is RoamFigure and str(of.coat) != "":
		Router.duel_config["opponent_coat"] = str(of.coat)
	if scene._figure and str(scene._figure.coat) != "":
		Router.duel_config["player_coat"] = str(scene._figure.coat)
	# Boss rules: {"opp_lp": 12000, "lp": 8000, "rule": "The Curator starts with 12000 Life Points."}
	for k in ["opp_lp", "my_lp", "hand", "rule", "music", "task"]:
		if d.has(k):
			Router.duel_config[k] = d[k]
	# Decks handed over as plain lists of cards (the Deck Building class).
	if d.has("my_list"):
		Router.duel_config["player_list"] = d["my_list"]
	if d.has("opp_list"):
		Router.duel_config["opponent_list"] = d["opp_list"]
	# {"puzzle": id}: not a duel but a problem (Puzzles): the field is set, and there is one turn to win.
	var problem := str(d.get("puzzle", ""))
	if problem != "":
		Router.duel_config["puzzle"] = problem
		Router.duel_config["opponent_name"] = Loc.t("Class problem") if d.has("class") else Loc.t("Exam problem")
		Router.duel_config["difficulty"] = 0
	# The duel a chapter ends on, and any duel with boss rules: they can make a Destiny Draw too.
	var last_duel := true
	for i in range(step + 1, _steps.size()):
		if (_steps[i] as Dictionary).has("duel"):
			last_duel = false
	# ("fair": true keeps it from them: the entrance exam, where the other side gets no comeback draw.)
	Router.duel_config["destiny_opp"] = (last_duel or d.has("opp_lp") or d.has("rule") or bool(d.get("boss", false))) and not bool(d.get("fair", false))
	_cutscene(true)
	_box.visible = false
	if problem == "":
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
	# "vo": somebody speaks over the picture: {"vo": ["nico", "line"]}. It reads as a caption
	# with their name, and the shot holds for as long as they talk.
	var vo_left := 0.0
	if st.has("vo") and not _skip:
		var vw := str(st["vo"][0])
		var vt := str(st["vo"][1])
		var vname := Profile.duelist_name if vw == "player" else Loc.t(str(Characters.get_char(vw).get("short", vw)))
		_caption("%s:  %s" % [vname.to_upper(), Loc.t(vt)])
		Voices.hush(true)
		if Voices.say(vw, vt, vw == "player", true):
			vo_left = Voices.length(vw, vt, vw == "player") + 0.5
		else:
			vo_left = 1.4 + vt.length() * 0.05
	if st.get("bg", false) or _skip:
		return
	var left := maxf(float(st["shot"].get("t", 4.0)), vo_left)
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
	if st.has("cap") or st.has("vo"):
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
## Long lines (Spanish runs longer) step the type down until the whole line fits in the box,
## instead of the last line being cut off at the bottom (0.55.3).
func _fit_text(text: String, italic: bool) -> void:
	var size := 28
	if _text.size.x > 100.0 and _text.size.y > 40.0:
		# Measure the real thing: the label lays the line out at each size and says how tall it is.
		for fs in [28, 26, 24, 22, 20, 18]:
			size = fs
			_text.add_theme_font_size_override("normal_font_size", fs)
			_text.add_theme_font_size_override("italics_font_size", fs)
			if _text.get_content_height() <= _text.size.y:
				break
		return
	# (Before the box has ever been laid out: estimate from the font.)
	var m := _text.get_parent().get_parent() as MarginContainer
	var width := get_viewport().get_visible_rect().size.x - 500.0 - m.get_theme_constant("margin_left") - m.get_theme_constant("margin_right") - 60.0
	var height := (_box.offset_bottom - _box.offset_top) - m.get_theme_constant("margin_top") - m.get_theme_constant("margin_bottom") - 20.0
	var font: Font = _text.get_theme_font("italics_font" if italic else "normal_font")
	for fs in [28, 26, 24, 22, 20, 18]:
		size = fs
		var lh := font.get_height(fs) + 7.0
		var lines := ceili(font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, fs).y / font.get_height(fs) - 0.01)
		if lines * lh <= height:
			break
	_text.add_theme_font_size_override("normal_font_size", size)
	_text.add_theme_font_size_override("italics_font_size", size)


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


## The board of a tournament, between rounds: it comes up, stays long enough to be read (or
## until you press on), and goes.
func _bracket_step(b: Dictionary) -> void:
	_cutscene(true)
	_box.visible = false
	if _skip:
		return
	var panel := StoryBracket.new(b)
	_ui.add_child(panel)
	var left := 9.0
	if _auto:
		left = 0.3
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--story-shots="):
				await _snap("bracket%d" % step, 0.8)
	_advance_wanted = false
	while left > 0.0 and not _skip and not _advance_wanted:
		await get_tree().process_frame
		left -= get_process_delta_time()
	_advance_wanted = false
	panel.leave()


## A list that gets posted (a team, a ranking): the names come up one by one, it stays long
## enough to be read (or until you press on once it is all there), and goes.
func _roster_step(l: Dictionary) -> void:
	_cutscene(true)
	_box.visible = false
	if _skip:
		return
	await _board_step(StoryRoster.new(l), "roster%d" % step)


## Anything that gets posted over the scene (the team list, the Cup table): it comes up piece by
## piece, stays long enough to be read (or until you press on once it is all there), and goes.
## `panel` has shown_after() and leave().
func _board_step(panel: Control, tag: String) -> void:
	_cutscene(true)
	_box.visible = false
	if _skip:
		panel.free()
		return
	_ui.add_child(panel)
	var full: float = panel.call("shown_after")
	var left := full + 6.0
	if _auto:
		left = 0.3
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--story-shots="):
				await _snap(tag, full + 0.3)
	_advance_wanted = false
	var shown := 0.0
	while left > 0.0 and not _skip:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		left -= dt
		shown += dt
		# (A press before the last name is up does not close it: the list is the scene.)
		if _advance_wanted:
			_advance_wanted = false
			if shown >= full:
				break
	_advance_wanted = false
	panel.call("leave")


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
	# {"prize": "The Rookie Tournament", "card": id, "text": ...} is the same banner for a card
	# that was won, not for a bond.
	var is_bond := st.has("bond")
	if is_bond:
		_prog().remember("bond_" + str(st["bond"]).to_lower().replace(" ", "_"))
		if _spirit is LumenSpirit:
			(_spirit as LumenSpirit).set_bonds(_prog().bonds())
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
	var head := UITheme.label(Loc.t("BOND FORMED" if is_bond else str(st.get("head", "PRIZE"))), 30, UITheme.GOLD, UITheme.semi_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var who := UITheme.label(Loc.t(str(st["bond"] if is_bond else st["prize"])).to_upper(), 64, Color.WHITE, UITheme.title_font())
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
	elif _auto and not is_bond:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--story-shots="):
				await _snap("prize%d" % step, 0.3)
	while not _advance_wanted and not _auto:
		await get_tree().process_frame
	_advance_wanted = false
	shade.queue_free()


## Things only the Academy story does: {"campus": {...}} with any of
##   "sleep": true        the night passes: the next morning
##   "part": 0..2         morning / afternoon / night (the sky follows)
##   "dorm": 0..2         you move up (the jacket changes)
##   "bond": [who, n]     somebody thinks more of you
##   "trophy": id         something for your room
##   "weekday": 0..6      (with "morning") the chapter plays on this day of the week: Monday is 0
##   "cup_floor": dorm    the oldest rule of the Cup: this dorm won the final round, so it is not last
##   "cup_flags": true    sets the flag "cup_first" when your dorm leads the table right now
##   "card": id           a card for your (Academy) collection, no fanfare
func _campus_step(c: Dictionary) -> void:
	if c.get("sleep", false):
		_cutscene(true)
		_box.visible = false
		var tw := create_tween()
		tw.tween_property(_flash, "color", Color(0, 0, 0, 1), 0.8)
		await tw.finished
		Campus.sleep()
		scene.city.apply_tod(Campus.tod())
		Router.roam["tod"] = Campus.tod()
		if not _skip and not _auto:
			_caption("%s  ·  %s %d" % [Loc.t(Campus.WEEK[Campus.weekday()]), Loc.t("Day"), Campus.day()])
			await get_tree().create_timer(1.8).timeout
			_caption("")
		var tw2 := create_tween()
		tw2.tween_property(_flash, "color", Color(0, 0, 0, 0), 0.8)
		await tw2.finished
		Saves.autosave(true)
	if c.get("morning", false) and Campus.part() > 0:
		# A chapter that opens in the morning, started later in the day: it is the next morning.
		Campus.set_time(Campus.day() + 1, 0)
		scene.city.apply_tod(Campus.tod())
		Router.roam["tod"] = Campus.tod()
	if c.has("weekday") and Campus.weekday() != int(c["weekday"]):
		# The story says which day it is; the calendar follows (the days in between simply pass).
		Campus.set_time(Campus.day() + posmod(int(c["weekday"]) - Campus.weekday(), 7), 0)
		scene.city.apply_tod(Campus.tod())
		Router.roam["tod"] = Campus.tod()
	if c.get("cup", false):
		Campus.cup_open()
	if c.has("cup_add"):
		Campus.cup_add(str(c["cup_add"][0]), int(c["cup_add"][1]))
	if c.has("cup_floor"):
		Campus.cup_not_last(str(c["cup_floor"]))
	if c.get("cup_flags", false):
		flags.erase("cup_first")
		if Campus.cup_on() and Campus.cup_place(Campus.dorm()) == 1:
			flags["cup_first"] = true
	if c.has("part"):
		Campus.put("part", clampi(int(c["part"]), 0, 2))
		scene.city.apply_tod(Campus.tod())
		Router.roam["tod"] = Campus.tod()
	if c.has("dorm"):
		Campus.put_many({"dorm": clampi(int(c["dorm"]), 0, 2), "jacket": true})
		scene._dress_player()
	if c.has("bond"):
		Campus.add_bond(str(c["bond"][0]), int(c["bond"][1]))
	if c.has("trophy"):
		Campus.trophy(str(c["trophy"]))
	if c.has("card"):
		var id := int(c["card"])
		if not CardData.get_card(id).is_empty():
			Collection.owned[id] = mini(3, int(Collection.owned.get(id, 0)) + 1)
			Collection.save()


## The deck you bring to the island: one of the three starters (only when the Academy's own
## collection is in use and has no deck yet).
func _pick_deck() -> void:
	if not Collection.needs_starter():
		return
	if _auto:
		Collection.take_starter("starter_warrior")
		return
	_cutscene(true)
	_box.visible = false
	var pick := StarterPick.new()
	_ui.add_child(pick)
	await pick.closed
	if is_instance_valid(pick):
		pick.queue_free()
	if Collection.needs_starter():
		Collection.take_starter("starter_warrior")
	_advance_wanted = false


## An Academy chapter ends: merits, the card, and back to the island (or straight on).
func _end_campus(st: Dictionary) -> void:
	print("STORY END: ", chapter)
	_cutscene(true)
	_cine = false
	_box.visible = false
	_prog().clear_position()
	var next := str(st.get("unlock", ""))
	if next != "":
		_prog().unlock(next)
	var first := not Campus.chapter_done(chapter)
	Campus.finish_chapter(chapter)
	var pay := int(st.get("pay", 40)) if first else 0
	if pay > 0:
		Campus.add_merits(pay, str(st["end"]))
	Saves.autosave(true)
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
	var r := UITheme.label(Loc.t("+%d merits") % pay if pay > 0 else (Loc.t("You have seen this one before") if not first else ""), 28, UITheme.ACCENT)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	if st.has("teaser"):
		var te := UITheme.label(Loc.t(str(st["teaser"])), 22, UITheme.TEXT_DIM)
		te.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		te.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		te.custom_minimum_size = Vector2(1000, 0)
		v.add_child(te)
	# "then": "next" goes straight into the next chapter (the prologue into chapter 1). Without
	# it the day is yours: the island, with the next chapter on the mission board.
	var straight: bool = str(st.get("then", "")) == "next" and next != "" and _book().SCRIPTS.has(next)
	var go := Button.new()
	go.text = Loc.t("Continue") if straight else Loc.t("Back to the island")
	go.custom_minimum_size = Vector2(420, 70)
	go.add_theme_font_size_override("font_size", 28)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(go)
	go.grab_focus.call_deferred()
	go.pressed.connect(func():
		if straight:
			StoryDirector.begin(next)
		else:
			Campus.put("free_days", true)
			Campus.island(st.get("wake", null)))
	var menu := Button.new()
	menu.text = Loc.t("Back to the menu")
	menu.custom_minimum_size = Vector2(420, 56)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(func():
		if not straight:
			Campus.put("free_days", true)
		_leave())
	v.add_child(menu)
	if _auto and "--story-quit" in OS.get_cmdline_user_args():
		await _snap("end", 2.5)
		get_tree().quit()


## The Deck Building class: the sixty cards on your desk, and the forty you choose (kept in the
## script's flags, so the deck is still yours if the game closes before the duel).
func _build_step() -> void:
	var pool := CampusClasses.pool()
	if _auto:
		flags["_deck"] = CampusClasses.pick(pool)
		print("STORY: deck built (auto), ", (flags["_deck"] as Array).size(), " of ", pool.size(), " cards")
		return
	_cutscene(true)
	_box.visible = false
	var desk := ClassBuild.new(pool)
	_ui.add_child(desk)
	var deck: Array = await desk.closed
	if is_instance_valid(desk):
		desk.queue_free()
	flags["_deck"] = deck
	_prog().save_position(chapter, step, flags)
	_advance_wanted = false


## A class is over: the stars, the merits, the morning spent, and back out to the island.
func _end_class(st: Dictionary) -> void:
	var kind := str(st["class_end"])
	print("STORY END: ", chapter)
	var n := CampusClasses.stars(kind, flags)
	var pay := CampusClasses.finish(kind, n)
	print("CLASS ", kind, " stars ", n, " merits ", pay)
	await _side_end(Loc.t("Class over"), "★".repeat(n) + "☆".repeat(3 - n),
			[Loc.t(str(CampusClasses.NAMES.get(kind, ""))), Loc.t("+%d merits") % pay], CampusData.LECT_DOOR, true)


## A night at the Midnight Circle is over.
func _end_circle(st: Dictionary) -> void:
	var n := int(st["circle_end"])
	print("STORY END: ", chapter)
	var res := CampusCircle.finish(n, flags.has("won"))
	print("CIRCLE night ", n, " won ", flags.has("won"), " -> ", res)
	var notes: Array = []
	var big := ""
	var rk := maxi(0, n - 1) / CampusCircle.PER_RANK      # the rank this night belongs to: 0 Candle, 1 Lantern
	if n == 0:
		notes.append(Loc.t("Your name is on the wall."))
	elif bool(res["rank"]) and rk == 0:
		big = Loc.t("RANK COMPLETE: THE CANDLE")
		notes.append(Loc.t("A mask of your own, hung in your room"))
		if int(res["prize"]) != 0:
			notes.append(Loc.t("A card for the first row of the wall: %s") % str(CardData.get_card(int(res["prize"])).get("name", "")))
	elif bool(res["rank"]) and rk >= 2:
		big = Loc.t("RANK COMPLETE: MIDNIGHT")
		notes.append(Loc.t("Your name is on the top line of the wall"))
		notes.append(Loc.t("The keys of the cellar are yours"))
	elif bool(res["rank"]):
		big = Loc.t("RANK COMPLETE: THE LANTERN")
		notes.append(Loc.t("Your name goes up to the Lantern line of the wall"))
	elif flags.has("won"):
		var lit := clampi(int(res["wins"]) - rk * CampusCircle.PER_RANK, 0, 4)
		big = "✦".repeat(lit) + "✧".repeat(4 - lit)
		notes.append(Loc.t(["A candle on the wall: %d of 4", "A lantern on the wall: %d of 4", "A midnight mark on the wall: %d of 4"][mini(rk, 2)]) % lit)
	else:
		notes.append(Loc.t("The wall is patient. Come back another night."))
	await _side_end(Loc.t("The night is over") if n > 0 else Loc.t("The Midnight Circle"), big, notes, CampusData.CELLAR_DOOR, n == 0 or flags.has("won"))


## The closing card of a side scene (a class, a night at the Circle): no chapter is finished, the
## place in the story is given back, and the island is where you go next.
func _side_end(title: String, big: String, notes: Array, wake: Vector3, glad: bool) -> void:
	_cutscene(true)
	_cine = false
	_box.visible = false
	_prog().clear_position()
	Saves.autosave(true)
	if not Saves.admin and Engine.get_main_loop() and Engine.get_main_loop().root.has_node("Collection"):
		Saves.save_to("autosave")
	if glad:
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
	var t := UITheme.label(title.to_upper(), 64, UITheme.GOLD, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if big != "":
		var b := UITheme.label(big, 54, Color.WHITE, UITheme.title_font())
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(b)
	for line in notes:
		var r := UITheme.label(str(line), 27, UITheme.ACCENT)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.custom_minimum_size = Vector2(1000, 0)
		v.add_child(r)
	var go := Button.new()
	go.text = Loc.t("Back to the island")
	go.custom_minimum_size = Vector2(420, 70)
	go.add_theme_font_size_override("font_size", 28)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(go)
	go.grab_focus.call_deferred()
	go.pressed.connect(func():
		Campus.put("free_days", true)
		Campus.island(wake))
	if _auto and "--story-quit" in OS.get_cmdline_user_args():
		await _snap("end", 2.5)
		get_tree().quit()


func _end(st: Dictionary) -> void:
	if campus:
		await _end_campus(st)
		return
	print("STORY END: ", chapter)
	_cutscene(true)
	_box.visible = false
	var side := chapter.begins_with("bond_")
	var pay := 500
	if side:
		# A side scene pays once, and hands the "continue" slot back to the chapter you were in.
		_prog().restore_position()
		pay = 0 if _prog().recalls("side_" + chapter.substr(5)) else 300
		_prog().remember("side_" + chapter.substr(5))
	else:
		_prog().clear_position()
	var next := str(st.get("unlock", ""))
	if next != "":
		_prog().unlock(next)
	Collection.dp += pay
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
	var r := UITheme.label(Loc.t("+%d Duel Points") % pay if pay > 0 else Loc.t("You have seen this one before"), 28, UITheme.ACCENT)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	if st.has("teaser"):
		var te := UITheme.label(Loc.t(str(st["teaser"])), 22, UITheme.TEXT_DIM)
		te.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		te.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		te.custom_minimum_size = Vector2(1000, 0)
		v.add_child(te)
	var playable: bool = next != "" and _book().SCRIPTS.has(next)
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
	if campus:
		Campus.leave()
	Router.go(Router.MAIN_MENU)


## Start (or continue) a chapter: load the world its current scene plays in.
static func begin(id: String, resume := false) -> void:
	var router = Engine.get_main_loop().root.get_node("Router")
	var steps: Array = _book().SCRIPTS.get(id, [])
	var at := 0
	if resume:
		at = int(_prog().position()["step"])
	else:
		if id.begins_with("bond_"):
			_prog().stash_position()   # a side scene: the chapter you were in keeps its place
		_prog().save_position(id, 0, {})
	# Dev: --story-step=N starts the chapter at that step (for checking one scene).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--story-step="):
			at = clampi(int(a.trim_prefix("--story-step=")), 0, maxi(0, steps.size() - 1))
			_prog().save_position(id, at, {})
	# The scene that step belongs to decides where to load.
	var sc := {}
	for i in mini(at + 1, steps.size()):
		if (steps[i] as Dictionary).has("scene"):
			sc = steps[i]["scene"]
	router.roam.erase("quest")
	router.roam["free"] = false          # you came in through the story: its list of things to do rides along
	if at < steps.size() and (steps[at] as Dictionary).has("tasks"):
		# The chapter is at a list of things to do yourself: that is the open world, with the
		# list riding along. You come back where you were.
		var fl: Dictionary = _prog().position()["flags"] if resume else {}
		var where := str(fl.get("_where", sc.get("district", "domino")))
		router.roam["story"] = ""
		router.roam["quest"] = id
		router.roam["district"] = where
		router.roam["pos"] = sc.get("pos", null) if where == str(sc.get("district", "domino")) else null
		router.roam.erase("tod")
		router.roam.erase("yaw")
		router.story_result = ""
		router.go(router.ROAM)
		return
	router.roam["story"] = id
	router.roam["district"] = str(sc.get("district", "domino"))
	router.roam["pos"] = sc.get("pos", null)
	router.roam["tod"] = str(sc.get("tod", "day"))
	if sc.has("yaw"):
		router.roam["yaw"] = sc["yaw"]
	router.story_result = ""
	router.go(router.ROAM)


## Is a chapter waiting at a list of things to do in the open world? Returns its id, or "".
static func quest_pending() -> String:
	var pos: Dictionary = _prog().position()
	var id := str(pos["chapter"])
	var steps: Array = _book().SCRIPTS.get(id, [])
	var at := int(pos["step"])
	if id == "" or at >= steps.size() or not (steps[at] as Dictionary).has("tasks"):
		return ""
	return id


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


func _toggle_tasks() -> void:
	task_small = not task_small
	_task_sig = ""
	Sfx.play("click", -10.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _cut:
		# The list of things to do: Tab (or a click of the right stick) opens it out and folds it away.
		if _task_box != null and _task_box.visible and ((event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB) \
				or (event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_RIGHT_STICK)):
			_toggle_tasks()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_E, KEY_ENTER]) \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_advance_wanted = true
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_skip = true
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_Y:
		_skip = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		_prog().save_position(chapter, step, flags)
		scene._open_pause()
