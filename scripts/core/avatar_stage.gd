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


## Everybody is framed the same way. The picture shows the same stretch of the world for every
## duelist (VIEW_H meters top to bottom) and hangs off the head bone, so heads line up and a
## small person looks small next to a tall one. Only somebody whose hair would still leave the
## picture is stepped back from, and only as far as it takes to fit.
const VIEW_H := 1.22
const HEAD_AT := 0.5        # where the head bone sits in the picture (0 top, 1 bottom)
const VIEW_MAX := 1.62


func _frame() -> void:
	var box := AABB()
	var first := true
	for mi in Avatars._meshes(_model):
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var head := Vector3(box.get_center().x, box.end.y - box.size.y * 0.14, box.get_center().z) if not first else Vector3(0, 1.45, 0)
	var sk := Avatars._skeleton(_model)
	if sk and Avatars.bone(_model, "Head") != -1:
		head = (sk.global_transform * sk.get_bone_global_pose(Avatars.bone(_model, "Head"))).origin
	var view := VIEW_H
	var aspect := 0.8
	var vp := get_viewport()
	if vp and vp.size.y > 0:
		aspect = float(vp.size.x) / float(vp.size.y)
	# How far the hair (or a hat, or horns) reaches above and to the side of the head.
	var reach := _head_reach(head)
	view = maxf(view, (reach.y + 0.06) / HEAD_AT)
	view = maxf(view, 2.0 * (reach.x + 0.05) / aspect)
	view = minf(view, VIEW_MAX)
	var look := head + Vector3(0, view * (0.5 - HEAD_AT), 0)
	_head = look
	# Which way does the face point? VRM 0.x faces -Z after import, 1.0 faces +Z.
	var face := 1.0 if _head_forward() >= 0.0 else -1.0
	var dist := (view / 2.0) / tan(deg_to_rad(_cam.fov * 0.5))
	_cam.position = look + Vector3(0, 0, face * dist)
	_cam.look_at(look)


## x: the widest the model gets from the head sideways, y: the highest it gets above the head
## bone, both taken from the real vertices at head height and up (hair, hats, horns, wings of
## hair), not from the mesh's bounding box, which is often wrong on a rigged model.
func _head_reach(head: Vector3) -> Vector2:
	var up := 0.0
	var half := 0.0
	var sk := Avatars._skeleton(_model)
	for mi in Avatars._meshes(_model):
		if mi.mesh == null:
			continue
		var xf := mi.global_transform
		if sk != null and mi.skin != null and mi.skin.get_bind_count() > 0:
			var bi := mi.skin.get_bind_bone(0)
			if bi < 0:
				bi = sk.find_bone(mi.skin.get_bind_name(0))
			if bi >= 0:
				xf = sk.global_transform * sk.get_bone_global_rest(bi) * mi.skin.get_bind_pose(0)
		for si in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
			var step := maxi(1, verts.size() / 9000)
			for v in range(0, verts.size(), step):
				var p := xf * verts[v]
				if p.y < head.y - 0.02:
					continue
				up = maxf(up, p.y - head.y)
				half = maxf(half, absf(p.x - head.x))
	return Vector2(half, up)


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
