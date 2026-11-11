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


func setup(char_key: String, color: Color, display_name := "", show_name := true) -> void:
	key = char_key
	_model = Avatars.load_model(char_key) if char_key != "" else null
	if _model:
		add_child(_model)
		await get_tree().process_frame
		Avatars._relax_pose(_model)
		_face_plus_z()
		_collect_bones()
	else:
		_build_standin(color)
	if show_name and display_name != "":
		var l := Label3D.new()
		l.text = display_name
		l.font_size = 40
		l.outline_size = 10
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = false
		l.position = Vector3(0, 2.05, 0)
		l.modulate = Color(1, 1, 1, 0.95)
		l.outline_modulate = Color(0, 0, 0, 0.8)
		add_child(l)


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
	if _model:
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
	elif not _rig.is_empty():
		(_rig["leg_l"] as Node3D).rotation.x = s * 0.6 * walk
		(_rig["leg_r"] as Node3D).rotation.x = -s * 0.6 * walk
		(_rig["arm_l"] as Node3D).rotation.x = -s * 0.5 * walk
		(_rig["arm_r"] as Node3D).rotation.x = s * 0.5 * walk
		(_rig["body"] as Node3D).position.y = absf(cos(_phase)) * 0.04 * walk + sin(_time * 1.7) * 0.006


# ------------------------------------------------------------------ stand-in

func _mat(c: Color, rough := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _part(mesh: Mesh, mat: Material, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _limb(parent: Node3D, pivot: Vector3, length: float, radius: float, mat: Material) -> Node3D:
	var j := Node3D.new()
	j.position = pivot
	parent.add_child(j)
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = length
	_part(c, mat, Vector3(0, -length / 2.0, 0), j)
	return j


## A clean, toy-like duelist: jacket in the character's color, dark pants, a hair cap.
func _build_standin(color: Color) -> void:
	var body := Node3D.new()
	add_child(body)
	var jacket := _mat(color.darkened(0.15), 0.5)
	var shirt := _mat(Color(0.92, 0.94, 0.97))
	var pants := _mat(Color(0.12, 0.13, 0.17))
	var skin := _mat(Color(1.0, 0.86, 0.76), 0.8)
	var hair := _mat(color.lightened(0.1).lerp(Color(0.15, 0.12, 0.1), 0.35), 0.4)
	var torso := CapsuleMesh.new()
	torso.radius = 0.24
	torso.height = 0.72
	_part(torso, jacket, Vector3(0, 1.18, 0), body)
	var chest := BoxMesh.new()
	chest.size = Vector3(0.18, 0.4, 0.05)
	_part(chest, shirt, Vector3(0, 1.25, 0.215), body)
	var head := SphereMesh.new()
	head.radius = 0.19
	head.height = 0.4
	_part(head, skin, Vector3(0, 1.72, 0), body)
	var cap := SphereMesh.new()
	cap.radius = 0.215
	cap.height = 0.3
	_part(cap, hair, Vector3(0, 1.8, -0.03), body)
	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.025
		eye.height = 0.05
		_part(eye, _mat(Color(0.08, 0.08, 0.12)), Vector3(0.07 * side, 1.73, 0.175), body)
	_rig["leg_l"] = _limb(body, Vector3(0.11, 0.86, 0), 0.82, 0.09, pants)
	_rig["leg_r"] = _limb(body, Vector3(-0.11, 0.86, 0), 0.82, 0.09, pants)
	_rig["arm_l"] = _limb(body, Vector3(0.31, 1.46, 0), 0.62, 0.07, jacket)
	_rig["arm_r"] = _limb(body, Vector3(-0.31, 1.46, 0), 0.62, 0.07, jacket)
	(_rig["arm_l"] as Node3D).rotation.z = 0.12
	(_rig["arm_r"] as Node3D).rotation.z = -0.12
	# Duel disk on the left arm.
	var disk := CylinderMesh.new()
	disk.top_radius = 0.2
	disk.bottom_radius = 0.2
	disk.height = 0.03
	var dm := _mat(Color(0.75, 0.78, 0.85), 0.3)
	dm.metallic = 0.6
	var d := _part(disk, dm, Vector3(0.03, -0.45, 0.05), _rig["arm_l"])
	d.rotation.z = PI / 2
	_rig["body"] = body
