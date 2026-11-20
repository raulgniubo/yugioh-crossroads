extends SceneTree
## Dev: turns motion files into clips for the game's shared skeleton (assets/models/anim/gestures.glb).
## Run it in a scratch project that holds the files (Godot has to import them first):
##   godot --headless --path <scratch> --import
##   godot --headless --path <scratch> -s <this file> -- <jobs.json> <out dir>
## jobs.json: [{"src": "res://in/motion_draw.fbx", "anim": "" (first one), "name": "g_draw", "map": "smplh" | "same",
##              "from": 0.0, "to": 0.0 (whole clip), "hips": false}]
## The scratch project needs res://in/gestures.glb (a copy of the game's). Each clip is saved as <out dir>/<name>.res:
## rotation tracks "Skeleton3D:<bone>" at 30 fps. Avatars.gesture() picks them up by name.
##
## How a motion moves from one skeleton to another: for every bone, how far it has turned from its rest pose, measured
## in the world, is applied to the same bone of the other skeleton's rest pose. Both rests must be the same pose (T).

const SMPLH := {"Pelvis": "Hips", "L_Hip": "LeftUpLeg", "L_Knee": "LeftLeg", "L_Ankle": "LeftFoot", "L_Foot": "LeftToeBase",
	"R_Hip": "RightUpLeg", "R_Knee": "RightLeg", "R_Ankle": "RightFoot", "R_Foot": "RightToeBase",
	"Spine1": "Spine", "Spine2": "Spine01", "Spine3": "Spine02", "Neck": "neck", "Head": "Head",
	"L_Collar": "LeftShoulder", "L_Shoulder": "LeftArm", "L_Elbow": "LeftForeArm", "L_Wrist": "LeftHand",
	"R_Collar": "RightShoulder", "R_Shoulder": "RightArm", "R_Elbow": "RightForeArm", "R_Wrist": "RightHand"}


func _find(n: Node, type: String) -> Node:
	var stack := [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x.is_class(type):
			return x
		for c in x.get_children():
			stack.append(c)
	return null


## The node's turn in the world, without being in the tree: every parent's transform, multiplied down.
func _world_q(n: Node) -> Quaternion:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t.basis.orthonormalized().get_rotation_quaternion()


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var jobs: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var out_dir: String = args[1]
	var tgt: Node = (load("res://in/gestures.glb") as PackedScene).instantiate()
	var tsk: Skeleton3D = _find(tgt, "Skeleton3D")
	var tw := _world_q(tsk)
	var tn := tsk.get_bone_count()
	var t_rest_g := []
	for b in tn:
		t_rest_g.append(tsk.get_bone_global_rest(b).basis.orthonormalized().get_rotation_quaternion())
	for job in jobs:
		var src: Node = (load(str(job["src"])) as PackedScene).instantiate()
		var ssk: Skeleton3D = _find(src, "Skeleton3D")
		var ap: AnimationPlayer = _find(src, "AnimationPlayer")
		var an_name := str(job.get("anim", ""))
		if an_name == "":
			for a in ap.get_animation_list():
				if a != "RESET":
					an_name = a
					break
		var an := ap.get_animation(an_name)
		if an == null:
			print("NO ANIMATION ", job["src"], " ", an_name, " has ", ap.get_animation_list())
			continue
		var sw := _world_q(ssk)
		var sn := ssk.get_bone_count()
		var track := {}
		for t in an.get_track_count():
			if an.track_get_type(t) == Animation.TYPE_ROTATION_3D:
				track[ssk.find_bone(String(an.track_get_path(t)).get_slice(":", 1))] = t
		var s_rest_g := []
		for b in sn:
			s_rest_g.append(ssk.get_bone_global_rest(b).basis.orthonormalized().get_rotation_quaternion())
		# which source bone drives each target bone
		var drive := {}
		for b in sn:
			var nm := ssk.get_bone_name(b)
			var to := str(SMPLH.get(nm, "")) if str(job.get("map", "same")) == "smplh" else nm
			var tb := tsk.find_bone(to)
			if tb >= 0:
				drive[tb] = b
		var t0 := float(job.get("from", 0.0))
		var t1 := float(job.get("to", 0.0))
		if t1 <= t0:
			t1 = an.length
		var out := Animation.new()
		out.length = t1 - t0
		var out_t := {}
		for tb in tn:
			var ti := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(ti, NodePath("Skeleton3D:" + tsk.get_bone_name(tb)))
			out_t[tb] = ti
		var frames := int(ceil(out.length * 30.0))
		for f in frames + 1:
			var tt := minf(t0 + f / 30.0, t1)
			# the source pose at this moment, bone by bone, in its skeleton's space
			var sg := []
			for b in sn:
				var loc: Quaternion = an.rotation_track_interpolate(track[b], tt) if track.has(b) else ssk.get_bone_rest(b).basis.orthonormalized().get_rotation_quaternion()
				var par := ssk.get_bone_parent(b)
				sg.append(loc if par < 0 else (sg[par] as Quaternion) * loc)
			var tg := []
			for tb in tn:
				var par := tsk.get_bone_parent(tb)
				var g: Quaternion
				if drive.has(tb):
					var sb: int = drive[tb]
					var turn: Quaternion = (sg[sb] as Quaternion) * (s_rest_g[sb] as Quaternion).inverse()      # in the source skeleton
					turn = tw.inverse() * (sw * turn * sw.inverse()) * tw                                      # in the target skeleton
					g = turn * (t_rest_g[tb] as Quaternion)
				else:
					var rest_loc := tsk.get_bone_rest(tb).basis.orthonormalized().get_rotation_quaternion()
					g = rest_loc if par < 0 else (tg[par] as Quaternion) * rest_loc
				tg.append(g)
				var local: Quaternion = g if par < 0 else (tg[par] as Quaternion).inverse() * g
				out.rotation_track_insert_key(out_t[tb], f / 30.0, local.normalized())
		var path := out_dir.path_join(str(job["name"]) + ".res")
		var err := ResourceSaver.save(out, path)
		print("CLIP ", job["name"], " ", snappedf(out.length, 0.01), " s, ", drive.size(), " of ", tn, " bones driven, saved ", err == OK, " ", path)
		src.free()
	tgt.free()
	quit()
