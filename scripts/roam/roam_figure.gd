class_name RoamFigure
extends Node3D
## A person walking around the world: a VRM model when one exists, otherwise a
## stylized stand-in. Faces +Z. Call set_speed() every frame to drive the walk.

var key := ""
var _model: Node3D        # VRM root (or null)
var _rig := {}            # stand-in parts
var _swing_bones := {}    # bone idx -> [parent global basis, relaxed local rotation, side sign]
var _phase := 0.0
var _speed := 0.0
var _time := randf() * 10.0
var _anim: AnimationPlayer = null
var _cur_clip := ""
var _hold := 0.0          # seconds a one-off clip (cheer) still owns the animation


func setup(char_key: String, color: Color, display_name := "", show_name := true) -> void:
	key = char_key
	_model = Avatars.load_model(char_key) if char_key != "" else null
	if _model:
		add_child(_model)
		await get_tree().process_frame
		_face_plus_z()
		_anim = Avatars.anim_player(_model)
		if _anim == null:
			Avatars._relax_pose(_model)
			_collect_bones()
	else:
		_build_standin(color)
	if show_name and display_name != "":
		var l := Label3D.new()
		l.text = display_name
		l.font_size = 40
		l.pixel_size = 0.0035
		l.outline_size = 10
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = false
		l.position = Vector3(0, 2.05, 0)
		l.modulate = Color(1, 1, 1, 0.95)
		l.outline_modulate = Color(0, 0, 0, 0.8)
		add_child(l)


## Play a one-off motion ("victory"), then fall back to idle. Returns false without one.
func play_once(motion: String, loops := 1) -> bool:
	if _model == null or _anim == null:
		return false
	var c := Avatars.clip(_anim, motion)
	if c == "" or (motion != "idle" and c == Avatars.clip(_anim, "idle")):
		return false
	_anim.speed_scale = 1.0
	_anim.play(c, 0.2)
	_hold = _anim.get_animation(c).length * loops - 0.25
	_cur_clip = ""
	return true


func set_speed(s: float) -> void:
	_speed = s


func _face_plus_z() -> void:
	var sk := Avatars._skeleton(_model)
	if sk == null:
		return
	var toes := Avatars.bone(_model, "LeftToes")
	var foot := Avatars.bone(_model, "LeftFoot")
	if toes == -1 or foot == -1:
		return
	var dz := sk.get_bone_global_rest(toes).origin.z - sk.get_bone_global_rest(foot).origin.z
	if dz < 0.0:
		_model.rotation.y = PI


func _collect_bones() -> void:
	var sk := Avatars._skeleton(_model)
	if sk == null:
		return
	for pair in [["LeftUpperLeg", 1.0], ["RightUpperLeg", -1.0], ["LeftUpperArm", -0.6], ["RightUpperArm", 0.6], ["LeftLowerLeg", 0.0], ["RightLowerLeg", 0.0]]:
		var b := Avatars.bone(_model, pair[0])
		if b == -1:
			continue
		var parent := sk.get_bone_parent(b)
		var pb := sk.get_bone_global_rest(parent).basis if parent != -1 else Basis()
		_swing_bones[b] = [pb, sk.get_bone_pose_rotation(b), pair[1], pair[0]]


func _process(delta: float) -> void:
	_time += delta
	var walk := clampf(_speed / 4.0, 0.0, 1.6)
	_phase += delta * (2.0 + _speed * 2.2)
	var s := sin(_phase)
	if _hold > 0.0:
		_hold -= delta
		return
	if _model and _anim:
		var want := Avatars.clip(_anim, "idle") if _speed < 0.3 else Avatars.clip(_anim, "run" if _speed > 5.5 else "walk")
		if want != "" and want != _cur_clip:
			_cur_clip = want
			_anim.play(want, 0.25)
		if _speed >= 0.3:
			_anim.speed_scale = clampf(_speed / (6.5 if _speed > 5.5 else 1.6), 0.6, 1.8)
		else:
			_anim.speed_scale = 1.0
	elif _model:
		var sk := Avatars._skeleton(_model)
		if sk:
			for b in _swing_bones:
				var info: Array = _swing_bones[b]
				var angle: float
				if str(info[3]).ends_with("LowerLeg"):
					var side := 1.0 if str(info[3]).begins_with("Left") else -1.0
					angle = -maxf(0.0, sin(_phase * side + 0.9)) * 0.7 * walk
				else:
					angle = s * 0.55 * walk * float(info[2])
				var q := Quaternion(Vector3.RIGHT, angle)
				var pb: Basis = info[0]
				var local := pb.inverse() * Basis(q) * pb * Basis(info[1])
				sk.set_bone_pose_rotation(b, local.get_rotation_quaternion())
		_model.position.y = absf(cos(_phase)) * 0.035 * walk + sin(_time * 1.7) * 0.004
	elif _rig.has("model"):
		(_rig["model"] as DuelistModel).set_speed(_speed)


# ------------------------------------------------------------------ stand-in

func _build_standin(color: Color) -> void:
	var m := DuelistModel.new()
	add_child(m)
	var l: Dictionary = DuelistModel.player_look() if key == "player" else DuelistModel.look_for(key, color)
	m.build(l)
	_rig["model"] = m
