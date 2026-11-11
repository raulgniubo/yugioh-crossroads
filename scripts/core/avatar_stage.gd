extends Node3D
## Lit little stage for a VRM portrait: frames the upper body and adds idle motion.

var _model: Node3D
var _time := 0.0
var _cam: Camera3D
var _head := Vector3(0, 1.45, 0)
var _blink: Array = []  # [MeshInstance3D, blend shape index]
var _next_blink := 2.0


func setup(model: Node3D) -> void:
	_model = model
	add_child(model)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.2
	key.rotation_degrees = Vector3(-25, 30, 0)
	add_child(key)
	var rim := OmniLight3D.new()
	rim.light_color = Color("8fe8ff")
	rim.light_energy = 2.0
	rim.omni_range = 4.0
	rim.position = Vector3(-0.8, 1.8, -0.8)
	add_child(rim)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.9, 1.0)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	_cam = Camera3D.new()
	_cam.fov = 30
	add_child(_cam)
	_cam.current = true
	await get_tree().process_frame
	if Avatars.anim_player(model) == null:
		Avatars._relax_pose(model)
	for mi in Avatars._meshes(model):
		if mi.mesh is ArrayMesh:
			for i in (mi.mesh as ArrayMesh).get_blend_shape_count():
				var n := String((mi.mesh as ArrayMesh).get_blend_shape_name(i)).to_lower()
				if n.contains("eye_close") or n == "blink" or n.ends_with("_blink") or n.contains("eye_close_"):
					if not n.contains("_l") and not n.contains("_r") or n.ends_with("eye_close"):
						_blink.append([mi, i])
						break
	_head = Avatars.head_position(model)
	_frame()


func _frame() -> void:
	# Frame from the mesh bounds: works for any VRM, whatever its bones are called.
	var box := AABB()
	var first := true
	for mi in Avatars._meshes(_model):
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var top := box.end.y if not first else 1.6
	var height := box.size.y if not first else 1.6
	var cx := box.get_center().x if not first else 0.0
	var cz := box.get_center().z if not first else 0.0
	var look := Vector3(cx, top - height * 0.17, cz)
	var sk := Avatars._skeleton(_model)
	if sk and Avatars.bone(_model, "Head") != -1:
		var hp := (sk.global_transform * sk.get_bone_global_pose(Avatars.bone(_model, "Head"))).origin
		look = hp + Vector3(0, -0.1, 0)
		height = maxf(hp.y * 1.12, 0.5)
	_head = look
	# Which way does the face point? VRM 0.x faces -Z after import, 1.0 faces +Z.
	var face := 1.0 if _head_forward() >= 0.0 else -1.0
	_cam.position = look + Vector3(0, height * 0.02, face * height * 0.85)
	_cam.look_at(look)


func _head_forward() -> float:
	var sk := Avatars._skeleton(_model)
	if sk:
		var ft := Avatars.bone(_model, "LeftToes")
		var kn := Avatars.bone(_model, "LeftFoot")
		if ft == -1:
			ft = Avatars.bone(_model, "LeftFoot")
			kn = Avatars.bone(_model, "LeftLowerLeg")
		if ft != -1 and kn != -1:
			var a := (sk.global_transform * sk.get_bone_global_pose(ft)).origin
			var b := (sk.global_transform * sk.get_bone_global_pose(kn)).origin
			return a.z - b.z
	return 1.0


func _process(delta: float) -> void:
	if _model == null:
		return
	_time += delta
	_model.position.y = sin(_time * 1.6) * 0.006
	_model.rotation.y = sin(_time * 0.5) * 0.06
	if _blink.size() > 0:
		var t := _time - _next_blink
		var w := 0.0
		if t >= 0.0:
			w = 1.0 - absf(t - 0.07) / 0.07
			if t > 0.14:
				_next_blink = _time + randf_range(2.0, 5.0)
				w = 0.0
		for b in _blink:
			(b[0] as MeshInstance3D).set_blend_shape_value(b[1], clampf(w, 0.0, 1.0))
