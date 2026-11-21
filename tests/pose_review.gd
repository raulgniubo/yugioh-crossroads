extends Node3D
## Dev: reviews every duel motion on a set of models, the way the duel's corner camera sees them.
##   check: how much of the face a hand or forearm covers, per motion (numbers, every model)
##   sheet: pictures of each motion (corner camera and a wide one), one strip of frames per motion
## The body measurements (the box of each joint's own vertices) come from a JSON made beside the
## models (tools/dev/motions/skel.py): numbers only, so real models never have to leave their folder.
##   godot --headless --path . res://tests/pose_review.tscn -- --assets=<folder> --boxes=<real.json> --mode=check
##   xvfb-run ... godot --rendering-driver opengl3 --path . res://tests/pose_review.tscn -- --assets=<folder>
##       --boxes=<real.json> --mode=sheet --keys=jaden,kaiba --motions=draw,play --out=/tmp/pose
const LIB := ["rest", "challenge", "defeat", "cheer", "cheer2", "bow", "wave", "chat", "scratch", "stomp", "alert", "agree"]
const CAM := Vector3(0.42, 0.09, 1.75)       # the corner camera, from the duelist's own point of view
const BLOCKERS := ["LeftHand", "RightHand", "LeftForeArm", "RightForeArm"]

var boxes := {}
var out_dir := "/tmp/pose"


func _arg(name: String, def := "") -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return def


func _motions() -> Array:
	var m: Array = []
	for f in DirAccess.get_files_at("res://assets/models/anim/clips"):
		var n := str(f).trim_suffix(".import").trim_suffix(".remap")
		if n.begins_with("g_") and n.ends_with(".res") and not m.has(n.substr(2, n.length() - 6)):
			m.append(n.substr(2, n.length() - 6))
	m.sort()
	return LIB + m


func _ready() -> void:
	var assets := _arg("assets")
	if assets != "":
		Settings.card_folder = assets
	var bj := _arg("boxes")
	if bj != "" and FileAccess.file_exists(bj):
		for r in JSON.parse_string(FileAccess.get_file_as_string(bj)):
			if r.has("bones"):
				var d := {}
				for b in r["bones"]:
					d[str(b["n"])] = b
				boxes[str(r["file"]).get_basename()] = d
	out_dir = _arg("out", "/tmp/pose")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var keys: Array = []
	if _arg("keys") != "":
		keys = Array(_arg("keys").split(","))
	else:
		for f in DirAccess.get_files_at(Settings.card_folder + "/characters"):
			if str(f).ends_with(".glb"):
				keys.append(str(f).get_basename())
		keys.sort()
	var motions: Array = Array(_arg("motions").split(",")) if _arg("motions") != "" else _motions()
	if _arg("mode", "check") == "check":
		await _check(keys, motions)
	else:
		await _sheet(keys, motions)
	get_tree().quit()


func _xf(b: Dictionary) -> Transform3D:
	var g: Array = b["g"]
	return Transform3D(Basis(Vector3(g[0], g[4], g[8]), Vector3(g[1], g[5], g[9]), Vector3(g[2], g[6], g[10])), Vector3(g[3], g[7], g[11]))


## The points of the face (a grid on the front of the head, chin to brow), in the Head bone's own space.
func _face_points(key: String) -> Array:
	var d: Dictionary = boxes.get(key, {})
	if not d.has("Head") or not d["Head"].has("wlo"):
		return []
	var hb: Dictionary = d["Head"]
	var inv := _xf(hb).affine_inverse()
	var hx := float(hb["g"][3])
	var chin := float(hb["wlo"][1])
	var zf := float(hb["whi"][2])
	var tall := float(hb["whi"][1]) - chin
	var pts: Array = []
	# (chin to brow: the lower two thirds of the head, as wide as the face without the hair)
	for iy in 7:
		for ix in 5:
			pts.append(inv * Vector3(hx + tall * 0.24 * (ix - 2) / 2.0, chin + tall * (0.34 + 0.26 * (iy - 3) / 3.0), zf))
	return pts


func _ray_hits_box(o: Vector3, d: Vector3, lo: Vector3, hi: Vector3) -> bool:
	var t0 := 0.0
	var t1 := 0.97
	for a in 3:
		if absf(d[a]) < 1e-9:
			if o[a] < lo[a] or o[a] > hi[a]:
				return false
			continue
		var ta := (lo[a] - o[a]) / d[a]
		var tb := (hi[a] - o[a]) / d[a]
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
		if t0 > t1:
			return false
	return true


## How much of the face is hidden from the corner camera right now (0..1).
func _covered(key: String, skel: Skeleton3D, face: Array) -> float:
	var d: Dictionary = boxes.get(key, {})
	var head := skel.find_bone("Head")
	if face.is_empty() or head < 0:
		return 0.0
	var st := skel.global_transform
	var hp := st * skel.get_bone_global_pose(head)
	var cam := hp.origin + Vector3(0, 0.06 - 0.25 + CAM.y, 0) + Vector3(CAM.x, 0, CAM.z)
	# (a duelist who has turned away, in a spin or bent right over, shows no face to hide)
	var mid: Vector3 = hp * (face[17] as Vector3)
	var normal := (hp.basis * (_xf(d["Head"]).basis.inverse() * Vector3(0, 0, 1))).normalized()
	if normal.dot((cam - mid).normalized()) < 0.3:
		return 0.0
	var blk: Array = []
	for bn in BLOCKERS:
		var bi := skel.find_bone(bn)
		if bi >= 0 and d.has(bn) and d[bn].has("lo"):
			blk.append([(st * skel.get_bone_global_pose(bi)).affine_inverse(), Vector3(d[bn]["lo"][0], d[bn]["lo"][1], d[bn]["lo"][2]), Vector3(d[bn]["hi"][0], d[bn]["hi"][1], d[bn]["hi"][2])])
	var hit := 0
	for fp in face:
		var w: Vector3 = hp * (fp as Vector3)
		for b in blk:
			var inv: Transform3D = b[0]
			if _ray_hits_box(inv * cam, inv.basis * (w - cam), b[1], b[2]):
				hit += 1
				break
	return float(hit) / float(face.size())


## How deep a hand or a forearm is inside the body right now, in meters (0 = not at all). Measured
## against the real model's own numbers (the box of each trunk joint's vertices, rounded off at the
## corners), NOT against what the game measures at run time: an outside check.
const TRUNK := ["Hips", "Spine", "Spine01", "Spine02", "Spine1", "Spine2", "LeftShoulder", "RightShoulder"]

func _inside(key: String, skel: Skeleton3D) -> float:
	var d: Dictionary = boxes.get(key, {})
	var worst := 0.0
	var pts: Array = []
	var st := skel.global_transform      # (the boxes are in meters, as the model stands; the bones may not be)
	for side in ["Left", "Right"]:
		var ih := skel.find_bone(side + "Hand")
		var ie := skel.find_bone(side + "ForeArm")
		if ih < 0 or ie < 0:
			continue
		var hp := skel.get_bone_global_pose(ih)
		var ep := skel.get_bone_global_pose(ie)
		pts.append(hp.origin)
		pts.append(ep.origin.lerp(hp.origin, 0.5))
		pts.append(ep.origin.lerp(hp.origin, 0.75))
		# (the middle of the palm: along the hand's own length, half of what the real hand measures)
		if d.has(side + "Hand") and d[side + "Hand"].has("wlo"):
			var hb: Dictionary = d[side + "Hand"]
			var c_rest := (Vector3(hb["wlo"][0], hb["wlo"][1], hb["wlo"][2]) + Vector3(hb["whi"][0], hb["whi"][1], hb["whi"][2])) * 0.5
			pts.append(hp * (skel.get_bone_global_rest(ih).affine_inverse() * (st.affine_inverse() * c_rest)))
	for bn in TRUNK:
		var bi := skel.find_bone(bn)
		if bi < 0 or not d.has(bn) or not d[bn].has("wlo") or d[bn]["wlo"] == null:
			continue
		var lo := Vector3(d[bn]["wlo"][0], d[bn]["wlo"][1], d[bn]["wlo"][2])
		var hi := Vector3(d[bn]["whi"][0], d[bn]["whi"][1], d[bn]["whi"][2])
		var to_rest := st * skel.get_bone_global_rest(bi) * skel.get_bone_global_pose(bi).affine_inverse()
		var c := (lo + hi) * 0.5
		var r := (hi - lo) * 0.5
		for p in pts:
			var q: Vector3 = to_rest * (p as Vector3) - c
			if absf(q.y) > r.y or r.x < 0.001 or r.z < 0.001:
				continue
			# (an oval across, as a trunk is)
			var k := sqrt((q.x / r.x) * (q.x / r.x) + (q.z / r.z) * (q.z / r.z))
			if k < 1.0:
				worst = maxf(worst, (1.0 - k) * minf(r.x, r.z))
	return worst


func _load(key: String) -> Array:
	var m := Avatars.load_model(key)
	if m == null:
		return []
	add_child(m)
	var skel := Avatars._first_skeleton(m)
	return [m, skel]


func _check(keys: Array, motions: Array) -> void:
	var worst := {}      # motion -> [fraction, key, time]
	var mean := {}
	var in_body := {}    # motion -> [meters, key, time]
	var in_frames := {}
	var all_frames := {}
	Avatars.body_clear = _arg("clear", "on") != "off"
	for key in keys:
		var l := _load(str(key))
		if l.is_empty() or l[1] == null:
			print("NO MODEL ", key)
			continue
		var model: Node3D = l[0]
		var skel: Skeleton3D = l[1]
		var face := _face_points(str(key))
		for mo in motions:
			var c := Avatars.rest_idle(model) if str(mo) == "rest" else Avatars.gesture(model, str(mo))
			if c == "":
				continue
			var ap := Avatars.anim_player(model)
			var an := ap.get_animation(c)
			ap.play(c)
			var t := 0.0
			var top := 0.0
			var at := 0.0
			var sum := 0.0
			var n := 0
			while t <= an.length:
				ap.seek(t, true)
				skel.force_update_all_bone_transforms()
				var f := _covered(str(key), skel, face)
				if f > top:
					top = f
					at = t
				sum += f
				n += 1
				var deep := _inside(str(key), skel)
				if deep > float(in_body.get(mo, [0.0])[0]):
					in_body[mo] = [deep, key, t]
				if deep > 0.03:
					in_frames[mo] = int(in_frames.get(mo, 0)) + 1
				all_frames[mo] = int(all_frames.get(mo, 0)) + 1
				t += 0.1
			if top > float(worst.get(mo, [-1.0])[0]):
				worst[mo] = [top, key, at]
			mean[mo] = float(mean.get(mo, 0.0)) + sum / maxf(n, 1)
		model.queue_free()
		await get_tree().process_frame
	var names := worst.keys()
	names.sort_custom(func(a, b): return float(worst[a][0]) > float(worst[b][0]))
	var bad := 0
	for mo in names:
		var w: Array = worst[mo]
		if float(w[0]) > 0.12:
			bad += 1
		print("%-14s worst %3d%% of the face hidden (%s at %.1fs)   average %2d%%" % [mo, int(round(float(w[0]) * 100)), w[1], w[2], int(round(float(mean[mo]) / maxf(keys.size(), 1) * 100))])
	print("POSE CHECK: %d motions, %d models, %d motions hide more than 12%% of a face" % [names.size(), keys.size(), bad])
	var deepest := in_body.keys()
	deepest.sort_custom(func(a, b): return float(in_body[a][0]) > float(in_body[b][0]))
	var sunk := 0
	for mo in deepest:
		var w2: Array = in_body[mo]
		if float(w2[0]) > 0.03:
			sunk += 1
			print("%-14s a hand or forearm up to %4.1f cm inside the body (%s at %.1fs)   %2d%% of its frames" % [mo, float(w2[0]) * 100.0, w2[1], w2[2],
				int(round(100.0 * float(in_frames.get(mo, 0)) / maxf(float(all_frames.get(mo, 1)), 1.0)))])
	print("BODY CHECK: %d motions, %d models, %d motions put a hand or forearm more than 3 cm inside the body (clearance %s)" % [deepest.size() if not deepest.is_empty() else names.size(), keys.size(), sunk, "on" if Avatars.body_clear else "off"])


func _view(size: Vector2i) -> Array:
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = false
	vp.world_3d = get_viewport().find_world_3d()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	add_child(vp)
	var cam := Camera3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.11, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.75
	cam.environment = env
	vp.add_child(cam)
	cam.current = true
	return [vp, cam]


func _sheet(keys: Array, motions: Array) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.6, 0.5, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var a := _view(Vector2i(240, 320))      # the corner camera
	var b := _view(Vector2i(240, 320))      # the whole body from the front
	var frames := int(_arg("frames", "8"))
	for key in keys:
		var l := _load(str(key))
		if l.is_empty() or l[1] == null:
			print("NO MODEL ", key)
			continue
		var model: Node3D = l[0]
		var skel: Skeleton3D = l[1]
		var face := _face_points(str(key))
		var head := skel.find_bone("Head")
		var sheet := Image.create(240 * frames, 640 * motions.size(), false, Image.FORMAT_RGBA8)
		var row := 0
		for mo in motions:
			var c := Avatars.rest_idle(model) if str(mo) == "rest" else Avatars.gesture(model, str(mo))
			if c == "":
				print("NO CLIP ", mo)
				row += 1
				continue
			var ap := Avatars.anim_player(model)
			var an := ap.get_animation(c)
			ap.play(c)
			var line := "%s %s len %.1f covered" % [key, mo, an.length]
			for k in frames:
				var t := an.length * float(k) / float(maxi(frames - 1, 1))
				ap.seek(t, true)
				skel.force_update_all_bone_transforms()
				var hp := (skel.global_transform * skel.get_bone_global_pose(head)).origin + Vector3(0, 0.06, 0)
				var at := hp - Vector3(0, 0.25, 0)
				(a[1] as Camera3D).fov = 40.0
				(a[1] as Camera3D).look_at_from_position(at + CAM, at)
				(b[1] as Camera3D).fov = 30.0
				(b[1] as Camera3D).look_at_from_position(Vector3(0.9, 1.05, 4.3), Vector3(0, 0.9, 0))
				for i in 3:
					await RenderingServer.frame_post_draw
				sheet.blit_rect((a[0] as SubViewport).get_texture().get_image(), Rect2i(0, 0, 240, 320), Vector2i(240 * k, 640 * row))
				sheet.blit_rect((b[0] as SubViewport).get_texture().get_image(), Rect2i(0, 0, 240, 320), Vector2i(240 * k, 640 * row + 320))
				line += " %d" % int(round(_covered(str(key), skel, face) * 100))
			print(line)
			row += 1
		sheet.save_png("%s/%s.png" % [out_dir, key])
		print("SHEET %s/%s.png" % [out_dir, key])
		model.queue_free()
		await get_tree().process_frame
