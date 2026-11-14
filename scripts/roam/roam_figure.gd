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
var _riding := false

## Everyday life. `watch` is who this person notices (the player): they turn their head, and
## wave or nod when you walk up. `stance` is what they do when standing still: "stand", "sit"
## or "browse" (looking over shelves). `lively` people shift, scratch, check their phone.
var watch: Node3D = null
var stance := "stand"
var lively := true
var greets := true
var _speaking := false
var _look: HeadLook = null
var _fidget_t := randf_range(2.5, 9.0)
var _greet_cd := 0.0
var _was_near := false
var _warm: Array = []
var _warm_t := randf_range(0.2, 1.2)
var _stand_clip := ""
var _started := false


func setup(char_key: String, color: Color, display_name := "", show_name := true) -> void:
	key = char_key
	_model = Avatars.load_model(char_key) if char_key != "" else null
	if _model:
		add_child(_model)
		if char_key == "player":
			_model.scale *= Profile.height()
		await get_tree().process_frame
		_face_plus_z()
		_anim = Avatars.anim_player(_model)
		if Avatars.rest_idle(_model) != "":
			_anim = Avatars.anim_player(_model)
			_stand_clip = "g_rest"
			_warm = ["wave", "chat", "scratch", "listen", "phone", "cheer"]
		if _anim == null:
			Avatars._relax_pose(_model)
			_collect_bones()
		_add_head_look()
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


func _add_head_look() -> void:
	var sk := Avatars._skeleton(_model)
	if sk == null:
		return
	var h := Avatars.bone(_model, "Head")
	if h < 0:
		return
	_look = HeadLook.new()
	_look.head = h
	_look.neck = sk.find_bone("neck")
	if _look.neck < 0:
		_look.neck = sk.find_bone("Neck")
	# The lowest bone of the back: the one that hangs off the hips, whatever the rig calls it.
	var hip_i := Avatars.bone(_model, "Hips")
	for b in sk.get_bone_count():
		if hip_i >= 0 and sk.get_bone_parent(b) == hip_i and sk.get_bone_name(b).to_lower().contains("spine"):
			_look.spine = b
			break
	for side in [["LeftUpperArm", "LeftLowerArm"], ["RightUpperArm", "RightLowerArm"]]:
		var ua := Avatars.bone(_model, side[0])
		var la := Avatars.bone(_model, side[1])
		if ua >= 0 and la >= 0:
			var sx := signf(sk.get_bone_global_rest(ua).origin.x - sk.get_bone_global_rest(Avatars.bone(_model, "Hips")).origin.x) if Avatars.bone(_model, "Hips") >= 0 else 1.0
			_look.arms.append([ua, la, sx if sx != 0.0 else 1.0])
	sk.add_child(_look)
	var to_sk := sk.global_transform.basis.orthonormalized().inverse() * global_transform.basis.orthonormalized()
	_look.up = (to_sk * Vector3.UP).normalized()
	_look.right = (to_sk * Vector3.RIGHT).normalized()
	# Which way is "out" for each arm, measured along the figure's own right.
	var hips := Avatars.bone(_model, "Hips")
	for a in _look.arms:
		var off: Vector3 = sk.get_bone_global_rest(a[0]).origin - (sk.get_bone_global_rest(hips).origin if hips >= 0 else Vector3.ZERO)
		a[2] = 1.0 if off.dot(_look.right) >= 0.0 else -1.0


## A small nod hello, done with the head alone.
func do_nod() -> void:
	if _look == null:
		return
	var tw := create_tween()
	tw.tween_property(_look, "nod", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_look, "nod", 0.0, 0.35).set_trans(Tween.TRANS_SINE)


## Talking: hands move while the lines are on screen.
func speak(on: bool) -> void:
	if on == _speaking:
		return
	_speaking = on
	_cur_clip = ""
	if on:
		_hold = 0.0


## A one-off everyday motion from the shared library ("wave", "agree", "bow", "cheer", ...).
func gesture(motion: String, blend := 0.3) -> bool:
	if _model == null or _riding:
		return false
	var c := Avatars.gesture(_model, motion)
	if c == "":
		return false
	_anim = Avatars.anim_player(_model)
	_anim.speed_scale = 1.0
	_anim.play(c, blend)
	_hold = _anim.get_animation(c).length - 0.3
	_cur_clip = ""
	return true


func _idle_clip() -> String:
	if stance == "sit" or stance == "rest":
		# "sit": upright at a table, hands busy. "rest": leaning on the knees, on a bench.
		var c := Avatars.gesture(_model, "sittalk" if (stance == "sit" or _speaking) else "sit")
		if c != "":
			return c
	if _speaking:
		var c2 := Avatars.gesture(_model, "chat")
		if c2 != "":
			return c2
	if _stand_clip != "":
		return _stand_clip
	return Avatars.clip(_anim, "idle")


func _live(delta: float) -> void:
	# Fit the everyday motions to this model a little at a time, so nothing stutters later.
	if not _warm.is_empty():
		_warm_t -= delta
		if _warm_t <= 0.0:
			_warm_t = 0.35
			Avatars.gesture(_model, _warm.pop_front())
	_greet_cd -= delta
	var near := false
	var want_yaw := 0.0
	var want_pitch := 0.0
	if watch and is_instance_valid(watch) and watch != self:
		var local := to_local(watch.global_position + Vector3(0, 1.5, 0)) - Vector3(0, 1.5, 0)
		var dist := Vector2(local.x, local.z).length()
		if dist < 5.5 and dist > 0.25:
			var ang := atan2(local.x, local.z)
			if absf(ang) < 1.75:
				want_yaw = clampf(ang, -1.15, 1.15)
				want_pitch = clampf(-atan2(local.y, dist), -0.3, 0.3)
		near = dist < 3.4
	if _look:
		var k := 1.0 - exp(-delta * 5.0)
		_look.yaw = lerpf(_look.yaw, want_yaw if stance == "stand" or absf(want_yaw) < 0.9 else 0.0, k)
		# The talking clip hunches forward; lift the chin so a speaker looks at who they talk to.
		_look.pitch = lerpf(_look.pitch, want_pitch - (0.3 if _speaking and stance == "stand" else 0.0), k)
	if _speed >= 0.3 or _hold > 0.0 or _speaking:
		_was_near = near
		return
	# Someone walks up: a wave or a nod, once in a while.
	if near and not _was_near and greets and _greet_cd <= 0.0 and stance == "stand":
		_greet_cd = randf_range(35.0, 60.0)
		if randf() < 0.5 and gesture("wave"):
			_hold = minf(_hold, 3.4)
		else:
			do_nod()
		_fidget_t = randf_range(6.0, 12.0)
	_was_near = near
	if not lively or _hold > 0.0:
		return
	_fidget_t -= delta
	if _fidget_t <= 0.0:
		_fidget_t = randf_range(9.0, 22.0)
		var pool: Array = []
		if stance == "stand":
			pool = ["scratch", "listen", "phone"]
		elif stance == "browse":
			pool = ["listen", "scratch"]
		if not pool.is_empty() and gesture(str(pool[randi() % pool.size()]), 0.45) and _hold > 6.5:
			_hold = 6.5


## Sit this person on a duel runner: knees up, leaning forward, hands on the bars. The pose
## is set once on the skeleton and the walk and idle animations are switched off.
func ride_pose() -> void:
	_riding = true
	if _model == null:
		return
	var ap := Avatars.anim_player(_model)
	if ap:
		ap.stop()
		ap.active = false
	var sk := Avatars._skeleton(_model)
	if sk == null:
		return
	sk.reset_bone_poses()
	var map: Dictionary = _model.get_meta("human_bones", {})
	var turn := func(human: String, axis: Vector3, deg: float):
		var idx := sk.find_bone(str(map.get(human, human)))
		if idx < 0:
			idx = sk.find_bone(human.to_lower())
		if idx < 0:
			return
		var g := sk.get_bone_global_pose(idx)
		g.basis = Basis(axis, deg_to_rad(deg)) * g.basis
		sk.set_bone_global_pose(idx, g)
	# Point a limb (from this bone to its first child) along a direction, in the model's own
	# space where +Z is forward and +Y is up. Works whatever pose the model rests in.
	var aim := func(human: String, dir: Vector3):
		var idx := sk.find_bone(str(map.get(human, human)))
		if idx < 0:
			return
		var kids := sk.get_bone_children(idx)
		if kids.is_empty():
			return
		var g := sk.get_bone_global_pose(idx)
		var cur: Vector3 = (sk.get_bone_global_pose(kids[0]).origin - g.origin).normalized()
		if cur.length() < 0.5:
			return
		g.basis = Basis(Quaternion(cur, dir.normalized())) * g.basis
		sk.set_bone_global_pose(idx, g)
	# Parents before children: each move carries everything below it along.
	turn.call("Spine", Vector3.RIGHT, 38.0)
	turn.call("Head", Vector3.RIGHT, -30.0)
	for side in ["Left", "Right"]:
		var idx := sk.find_bone(str(map.get(side + "UpperArm", "")))
		var sx := 1.0
		if idx >= 0:
			sx = 1.0 if sk.get_bone_global_rest(idx).origin.x >= 0.0 else -1.0
		aim.call(side + "UpperArm", Vector3(0.16 * sx, -0.42, 0.9))
		aim.call(side + "LowerArm", Vector3(-0.06 * sx, -0.12, 1.0))
		aim.call(side + "UpperLeg", Vector3(0.3 * sx, -0.36, 0.9))
		aim.call(side + "LowerLeg", Vector3(0.0, -0.6, -0.8))
	# Sit down onto the saddle.
	_model.position.y = -0.2


## Somebody who sits needs something to sit on. Looks under them once the room is built and,
## if there is no seat there already, puts a small stool in.
func seat_if_needed() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 0.95, 0)
	var q := PhysicsRayQueryParameters3D.create(from, global_position + Vector3(0, 0.2, 0), 1)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		return
	var back := -global_transform.basis.z.normalized()
	var q2 := PhysicsRayQueryParameters3D.create(from + back * 0.18, global_position + back * 0.18 + Vector3(0, 0.2, 0), 1)
	if not space.intersect_ray(q2).is_empty():
		return
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.25, 0.16)
	wood.roughness = 0.7
	var pad := StandardMaterial3D.new()
	pad.albedo_color = Color(0.2, 0.22, 0.3)
	pad.roughness = 0.9
	var stool := Node3D.new()
	add_child(stool)
	stool.position = Vector3.ZERO
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.24
	tm.bottom_radius = 0.24
	tm.height = 0.07
	tm.radial_segments = 18
	top.mesh = tm
	top.material_override = pad
	top.position.y = SEAT_H - 0.035
	stool.add_child(top)
	var rim := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.25
	rm.bottom_radius = 0.23
	rm.height = 0.05
	rm.radial_segments = 18
	rim.mesh = rm
	rim.material_override = wood
	rim.position.y = SEAT_H - 0.09
	stool.add_child(rim)
	for k in 4:
		var a := PI / 4.0 + k * PI / 2.0
		var leg := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.022
		lm.bottom_radius = 0.028
		lm.height = SEAT_H - 0.1
		lm.radial_segments = 8
		leg.mesh = lm
		leg.material_override = wood
		leg.position = Vector3(cos(a) * 0.17, (SEAT_H - 0.1) / 2.0, sin(a) * 0.17)
		stool.add_child(leg)


const SEAT_H := 0.5


## Put a Duel Academy dorm jacket on this person.
func wear_uniform(color: Color) -> void:
	if _model:
		Avatars.apply_uniform(_model, color)


## Play a one-off motion ("victory"), then fall back to idle. Returns false without one.
func play_once(motion: String, loops := 1) -> bool:
	if _model == null:
		return false
	if _anim == null:
		_anim = Avatars.anim_player(_model)
	if _anim == null and Avatars.gesture(_model, "stand") == "":
		return false
	var lib_motion: String = {"victory": "cheer", "lose": "defeat", "bow": "bow", "cheer": "cheer2"}.get(motion, "")
	var c := Avatars.gesture(_model, lib_motion) if lib_motion != "" else ""
	if c == "":
		c = Avatars.clip(_anim, motion)
	if c == "" or (motion != "idle" and c == Avatars.clip(_anim, "idle")):
		return false
	_anim = Avatars.anim_player(_model)
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
	if _riding:
		return
	_time += delta
	var walk := clampf(_speed / 4.0, 0.0, 1.6)
	_phase += delta * (2.0 + _speed * 2.2)
	var s := sin(_phase)
	if _model:
		_live(delta)
		# Sitting: the motions were made with the body well behind the feet, so slide the model
		# forward until the hips are over this node. A seat is then simply "where the node is".
		var seat_shift := Vector3.ZERO
		if _speed < 0.3 and _hold <= 0.0:
			if stance == "sit":
				seat_shift = Vector3(0.14, 0, 0.29)
			elif stance == "rest":
				seat_shift = Vector3(-0.11, 0, 0.31)
		var k := 1.0 - exp(-delta * 8.0)
		if _look:
			_look.sit_up = lerpf(_look.sit_up, 0.36 if (stance == "rest" and _speed < 0.3 and _hold <= 0.0 and not _speaking) else 0.0, k)
		_model.position.x = lerpf(_model.position.x, seat_shift.x, k)
		_model.position.z = lerpf(_model.position.z, seat_shift.z, k)
	if _hold > 0.0:
		_hold -= delta
		if _speed < 0.3:
			return
		_hold = 0.0       # started walking: drop the gesture
	if _model and _anim:
		var want := _idle_clip() if _speed < 0.3 else Avatars.clip(_anim, "run" if _speed > 5.5 else "walk")
		if want != "" and want != _cur_clip:
			var first := not _started
			_started = true
			_cur_clip = want
			_anim.play(want, 0.35)
			if first and _speed < 0.3:
				# Nobody breathes in step with the person next to them.
				_anim.seek(randf() * _anim.get_animation(want).length, true)
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
