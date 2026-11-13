extends Node
## 3D characters from VRM files (VRoid Studio exports).
## Put <key>.vrm in <card folder>/characters/ (player.vrm for you, yugi.vrm, kaiba.vrm, ...).
## Avatars are posed (arms down), lit and rendered into live portraits.

const VRM0_EXT := preload("res://addons/vrm/vrm_extension.gd")
const VRM1_EXTS := [
	preload("res://addons/vrm/1.0/VRMC_vrm.gd"),
	preload("res://addons/vrm/1.0/VRMC_springBone.gd"),
	preload("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd"),
	preload("res://addons/vrm/1.0/VRMC_materials_mtoon.gd"),
]
const TINTS := [Color.WHITE, Color("2b2b33"), Color("f2d27a"), Color("e0533f"), Color("3f7be0"), Color("8a4fd9"), Color("3fbf8a"), Color("f08fc0")]
const IMPORT_USE_NAMED_SKIN_BINDS := 16
const STAGE_SIZE := Vector2i(512, 640)

var _stages := {}  # key -> SubViewport
var _registered := false


## A character model: characters/<key>.vrm or .glb in the card folder (your own models),
## or a bundled one in res://assets/models/people/<key>.glb (townsfolk).
func path_for(key: String) -> String:
	var own := own_file(key)
	if own != "":
		return own
	for k in [key, Profile.hero_key() if key == "player" else "", STANDINS.get(key, "")]:
		if k == "":
			continue
		var bundled := "res://assets/models/people/%s.glb" % k
		if ResourceLoader.exists(bundled):
			return bundled
	return ""


## A model the player dropped in: characters/<key>.vrm or .glb in the card folder.
func own_file(key: String) -> String:
	for ext in ["vrm", "glb"]:
		var p := Settings.card_folder.path_join(Loc.t("characters/%s.%s") % [key, ext])
		if FileAccess.file_exists(p):
			return p
	return ""


## Original stand-in duelists, used until a character's own model file is dropped in.
## They are deliberately not lookalikes: just good-looking placeholders.
const STANDINS := {
	"yugi": "duelist_m2", "kaiba": "duelist_m6", "joey": "duelist_m5", "mai": "duelist_f1",
	"bakura": "duelist_m1", "marik": "duelist_m7", "pegasus": "duelist_m3", "weevil": "student_boy", "rex": "duelist_m4",
	"jaden": "duelist_m8", "chazz": "duelist_m9", "zane": "duelist_m10", "alexis": "duelist_f2", "syrus": "duelist_m11", "aster": "duelist_m12",
	"yusei": "duelist_m13", "jack": "duelist_m14", "crow": "duelist_m15", "akiza": "duelist_f3", "kalin": "duelist_m16",
	"yuma": "duelist_m17", "shark": "duelist_m18", "kite": "duelist_m19", "vector": "office_worker",
	"kid": "street_duelist", "vendor": "shopkeeper", "grandpa": "shopkeeper", "guard": "office_worker", "lumen": "student_girl", "vesper": "stylish_woman",
	"professor": "duelist_m3", "red_student": "student_boy", "yellow_student": "duelist_m4", "blue_student": "duelist_m7",
}
## Duel Academy jackets. Painted over stand-in models only, never over a model you supplied.
const DORM_COLORS := {"red": Color("d9342b"), "yellow": Color("f2c230"), "blue": Color("2f6fe0")}
const UNIFORMS := {"jaden": "red", "syrus": "red", "red_student": "red", "yellow_student": "yellow",
	"chazz": "blue", "alexis": "blue", "zane": "blue", "blue_student": "blue"}
var _uniform_shader: Shader


## True when this character is shown with a stand-in, not their own model.
func is_standin(key: String) -> bool:
	return key != "player" and own_file(key) == "" and STANDINS.has(key) \
			and not ResourceLoader.exists("res://assets/models/people/%s.glb" % key)


func has_avatar(key: String) -> bool:
	return key != "" and path_for(key) != ""


## Common bone names in rigs from Meshy, Mixamo, Blender's Rigify-lite and VRoid.
const BONE_ALIASES := {
	"Head": ["head"],
	"Hips": ["hips", "pelvis"],
	"LeftUpperArm": ["leftarm", "upperarm_l", "l_upperarm", "leftupperarm", "arm_l", "upper_arm.l"],
	"RightUpperArm": ["rightarm", "upperarm_r", "r_upperarm", "rightupperarm", "arm_r", "upper_arm.r"],
	"LeftLowerArm": ["leftforearm", "lowerarm_l", "l_forearm", "leftlowerarm", "forearm_l", "forearm.l"],
	"RightLowerArm": ["rightforearm", "lowerarm_r", "r_forearm", "rightlowerarm", "forearm_r", "forearm.r"],
	"LeftUpperLeg": ["leftupleg", "thigh_l", "l_thigh", "leftupperleg", "thigh.l"],
	"RightUpperLeg": ["rightupleg", "thigh_r", "r_thigh", "rightupperleg", "thigh.r"],
	"LeftLowerLeg": ["leftleg", "calf_l", "l_calf", "leftlowerleg", "shin.l"],
	"RightLowerLeg": ["rightleg", "calf_r", "r_calf", "rightlowerleg", "shin.r"],
	"LeftFoot": ["leftfoot", "foot_l", "l_foot", "foot.l"],
	"LeftToes": ["lefttoebase", "toe_l", "l_toe", "lefttoes", "toe.l"],
	"RightFoot": ["rightfoot", "foot_r", "r_foot", "foot.r"],
	"LeftHand": ["lefthand", "hand_l", "l_hand", "hand.l"],
	"RightHand": ["righthand", "hand_r", "r_hand", "hand.r"],
}


func _guess_human_map(scene: Node) -> Dictionary:
	var sk := _skeleton(scene)
	var out := {}
	if sk == null:
		return out
	var names := {}
	for i in sk.get_bone_count():
		var n := sk.get_bone_name(i)
		var simple := n.to_lower().replace("mixamorig:", "").replace("mixamorig_", "").replace(" ", "").replace("_", "").replace("-", "")
		names[simple] = n
		names[n.to_lower()] = n
	for human in BONE_ALIASES:
		for alias in BONE_ALIASES[human]:
			var key: String = alias.replace("_", "")
			if names.has(alias):
				out[human] = names[alias]
				break
			if names.has(key):
				out[human] = names[key]
				break
	return out


func _load_glb(path: String) -> Node:
	if path.begins_with("res://"):
		var ps = load(path)
		return ps.instantiate() if ps is PackedScene else null
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	if gltf.append_from_file(path, state) != OK:
		return null
	return gltf.generate_scene(state)


## Animation files that sit beside a dropped-in model. Most tools export one file per motion,
## so characters/yugi.glb can come with yugi_walk.glb, yugi_run.glb, yugi_idle.glb and
## yugi_victory.glb: the clip in each is added to the model under the name after the underscore.
func _merge_clip_files(key: String, path: String, g: Node) -> Node:
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return g
	var extras: Array = []
	for f in dir.get_files():
		var lf := f.to_lower()
		if lf.begins_with(key.to_lower() + "_") and lf.ends_with(".glb"):
			extras.append(f)
	if extras.is_empty():
		return g
	# Walk first: if the main file has no skeleton animation of its own, the walk file
	# becomes the body and the rest are added to it.
	extras.sort_custom(func(a, b): return int(a.to_lower().contains("walk")) > int(b.to_lower().contains("walk")))
	var main_ap := anim_player(g)
	for f in extras:
		var motion: String = f.get_basename().substr(key.length() + 1).to_lower()
		var scene := _load_glb(path.get_base_dir().path_join(f))
		if scene == null:
			continue
		var ap2 := anim_player(scene)
		if ap2 == null or ap2.get_animation_list().is_empty():
			scene.free()
			continue
		if main_ap == null:
			g.free()
			g = scene
			main_ap = ap2
			var lib0 := ap2.get_animation_library(ap2.get_animation_library_list()[0])
			var i0 := 0
			for n in lib0.get_animation_list():
				lib0.rename_animation(n, motion if i0 == 0 else "%s_%d" % [motion, i0 + 1])
				i0 += 1
			continue
		var lib := main_ap.get_animation_library(main_ap.get_animation_library_list()[0])
		var i := 0
		for n in ap2.get_animation_list():
			var nm := motion if i == 0 else "%s_%d" % [motion, i + 1]
			if not lib.has_animation(nm):
				lib.add_animation(nm, ap2.get_animation(n).duplicate())
			i += 1
		scene.free()
	return g


const DONOR := "res://assets/models/people/duelist_m2.glb"
const MOTIONS := ["idle", "walk", "run", "victory"]
var _donor: Node = null          # a bundled model kept around for its animations


func _first_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var sk := _first_skeleton(c)
		if sk:
			return sk
	return null


## A dropped-in model that is rigged but has no idle / walk / run / victory of its own gets
## the game's. Auto-riggers give every character the same skeleton, so the bundled clips fit
## any model whose bones carry the same names; anything else is left alone.
func _borrow_clips(g: Node) -> void:
	var skel := _first_skeleton(g)
	if skel == null:
		return
	var ap := anim_player(g)
	var missing: Array = []
	for m: String in MOTIONS:
		var have := false
		if ap:
			for n in ap.get_animation_list():
				if String(n).to_lower().contains(m):
					have = true
		if not have:
			missing.append(m)
	if missing.is_empty():
		return
	if _donor == null or not is_instance_valid(_donor):
		var ps = load(DONOR)
		if not (ps is PackedScene):
			return
		_donor = ps.instantiate()
	var dap := anim_player(_donor)
	var dskel := _first_skeleton(_donor)
	if dap == null or dskel == null:
		return
	# Only when the skeletons really are the same family.
	var shared := 0
	for b in dskel.get_bone_count():
		if skel.find_bone(dskel.get_bone_name(b)) >= 0:
			shared += 1
	if shared < int(dskel.get_bone_count() * 0.8):
		return
	if ap == null:
		ap = AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		g.add_child(ap)
		ap.add_animation_library("", AnimationLibrary.new())
	elif ap.get_animation_library_list().is_empty():
		ap.add_animation_library("", AnimationLibrary.new())
	var lib := ap.get_animation_library(ap.get_animation_library_list()[0])
	var root := ap.get_node_or_null(ap.root_node)
	if root == null:
		return
	var skel_path := str(root.get_path_to(skel))
	# Taller or shorter than the donor: scale how far the hips travel to match.
	var ratio := 1.0
	var hip_a := skel.find_bone("Hips")
	var hip_b := dskel.find_bone("Hips")
	if hip_a >= 0 and hip_b >= 0 and absf(dskel.get_bone_global_rest(hip_b).origin.y) > 0.0001:
		ratio = skel.get_bone_global_rest(hip_a).origin.y / dskel.get_bone_global_rest(hip_b).origin.y
	for m: String in missing:
		var src_name := ""
		for n in dap.get_animation_list():
			if String(n).to_lower().contains(m):
				src_name = n
				break
		if src_name == "" or lib.has_animation(m):
			continue
		lib.add_animation(m, _retarget(dap.get_animation(src_name), dskel, skel, skel_path, ratio))


## Re-make a donor clip for another skeleton of the same family. The two can be bound in
## different poses (one arms-out, one arms-down) with bones rolled differently, so copying the
## numbers across bends everything the wrong way. Instead: work out how far each donor bone has
## turned from its own rest pose, in world terms, and turn the matching bone the same amount
## from where the donor's rest would put it.
func _retarget(src: Animation, dskel: Skeleton3D, skel: Skeleton3D, skel_path: String, ratio: float, fps := 30.0) -> Animation:
	var dn := dskel.get_bone_count()
	var rot_t := {}
	var pos_t := {}
	for t in src.get_track_count():
		var bi := dskel.find_bone(String(src.track_get_path(t)).get_slice(":", 1))
		if bi < 0:
			continue
		if src.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			rot_t[bi] = t
		elif src.track_get_type(t) == Animation.TYPE_POSITION_3D:
			pos_t[bi] = t
	# Which donor bone drives each of this skeleton's bones, and the turn that lines its
	# rest direction up with the donor's.
	var tn := skel.get_bone_count()
	var from_donor: Array = []
	var fix: Array = []
	for tb in tn:
		var b := dskel.find_bone(skel.get_bone_name(tb))
		from_donor.append(b)
		var c := Basis.IDENTITY
		if b >= 0:
			var kids := dskel.get_bone_children(b)
			var tk := skel.find_bone(dskel.get_bone_name(kids[0])) if kids.size() > 0 else -1
			if tk >= 0:
				var dd := (dskel.get_bone_global_rest(kids[0]).origin - dskel.get_bone_global_rest(b).origin).normalized()
				var td := (skel.get_bone_global_rest(tk).origin - skel.get_bone_global_rest(tb).origin).normalized()
				if dd.length() > 0.5 and td.length() > 0.5 and td.dot(dd) < 0.99999 and td.dot(dd) > -0.999:
					c = Basis(Quaternion(td, dd))
			else:
				var par := skel.get_bone_parent(tb)
				if par >= 0:
					c = fix[par]
		fix.append(c)
	var out := Animation.new()
	out.length = src.length
	out.loop_mode = src.loop_mode
	var track_of := {}
	for tb in tn:
		if from_donor[tb] >= 0:
			var ti := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(ti, NodePath("%s:%s" % [skel_path, skel.get_bone_name(tb)]))
			track_of[tb] = ti
	var hip := skel.find_bone("Hips")
	var dhip := dskel.find_bone("Hips")
	var hip_track := -1
	if hip >= 0 and dhip >= 0:
		hip_track = out.add_track(Animation.TYPE_POSITION_3D)
		out.track_set_path(hip_track, NodePath("%s:Hips" % skel_path))
	var hip_parent_inv := Transform3D.IDENTITY
	if hip >= 0 and skel.get_bone_parent(hip) >= 0:
		hip_parent_inv = skel.get_bone_global_rest(skel.get_bone_parent(hip)).affine_inverse()
	var frames := int(ceil(src.length * fps)) + 1
	for f in frames:
		var t := minf(float(f) / fps, src.length)
		# The donor's pose at this moment, bone by bone, in skeleton space.
		var dg: Array = []
		dg.resize(dn)
		for b in dn:
			var loc := dskel.get_bone_rest(b)
			if rot_t.has(b):
				loc.basis = Basis(src.rotation_track_interpolate(rot_t[b], t))
			if pos_t.has(b):
				loc.origin = src.position_track_interpolate(pos_t[b], t)
			var dp := dskel.get_bone_parent(b)
			dg[b] = (dg[dp] * loc) if dp >= 0 else loc
		var tg: Array = []
		tg.resize(tn)
		for tb in tn:
			var par := skel.get_bone_parent(tb)
			var pg: Basis = tg[par] if par >= 0 else Basis.IDENTITY
			var b: int = from_donor[tb]
			if b < 0:
				tg[tb] = pg * skel.get_bone_rest(tb).basis.orthonormalized()
				continue
			var turned := (dg[b] as Transform3D).basis.orthonormalized() * dskel.get_bone_global_rest(b).basis.orthonormalized().inverse()
			var gb: Basis = turned * (fix[tb] as Basis) * skel.get_bone_global_rest(tb).basis.orthonormalized()
			tg[tb] = gb
			out.rotation_track_insert_key(track_of[tb], t, (pg.inverse() * gb).orthonormalized().get_rotation_quaternion())
		if hip_track >= 0:
			out.position_track_insert_key(hip_track, t, hip_parent_inv * ((dg[dhip] as Transform3D).origin * ratio))
	return out


const GESTURES := "res://assets/models/anim/gestures.glb"
var _gest: Node = null           # the shared library of everyday motions (wave, chat, sit, ...)
var _gest_cache := {}            # "<model file>|<clip>" -> Animation, made once per model file


## An everyday motion from the shared library, fitted to this model: "stand", "stand2", "alert",
## "agree", "wave", "sit", "sittalk", "scratch", "listen", "chat", "checkout", "cheer", "cheer2",
## "phone", "stomp", "bow". Returns the clip name to play, or "" when this model cannot use it
## (no skeleton of the usual family). The clip is made the first time it is asked for.
func gesture(model: Node, motion: String) -> String:
	var ap := anim_player(model)
	var skel := _first_skeleton(model)
	if skel == null:
		return ""
	var nm := "g_" + motion
	if ap and ap.has_animation(nm):
		return nm
	if model.has_meta("no_gestures"):
		return ""
	if _gest == null or not is_instance_valid(_gest):
		var ps = load(GESTURES)
		if not (ps is PackedScene):
			return ""
		_gest = ps.instantiate()
	var dap := anim_player(_gest)
	var dskel := _first_skeleton(_gest)
	if dap != null and dskel != null and MADE_POSES.has(nm) and not dap.has_animation(nm):
		_make_pose_clip(dap, dskel, nm)
	if dap == null or dskel == null or not dap.has_animation(nm):
		return ""
	var shared := 0
	for b in dskel.get_bone_count():
		if skel.find_bone(dskel.get_bone_name(b)) >= 0:
			shared += 1
	if shared < int(dskel.get_bone_count() * 0.8):
		model.set_meta("no_gestures", true)
		return ""
	if ap == null:
		ap = AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		skel.get_parent().add_child(ap)
		ap.root_node = ap.get_path_to(skel.get_parent())
		ap.add_animation_library("", AnimationLibrary.new())
	elif ap.get_animation_library_list().is_empty():
		ap.add_animation_library("", AnimationLibrary.new())
	var lib := ap.get_animation_library(ap.get_animation_library_list()[0])
	var root := ap.get_node_or_null(ap.root_node)
	if root == null:
		return ""
	var skel_path := str(root.get_path_to(skel))
	var ck := "%s|%s|%s" % [str(model.get_meta("file", "")), skel_path, nm]
	var anim: Animation = _gest_cache.get(ck) if model.has_meta("file") else null
	if anim == null:
		var ratio := 1.0
		var hip_a := skel.find_bone("Hips")
		var hip_b := dskel.find_bone("Hips")
		if hip_a >= 0 and hip_b >= 0 and absf(dskel.get_bone_global_rest(hip_b).origin.y) > 0.0001:
			ratio = skel.get_bone_global_rest(hip_a).origin.y / dskel.get_bone_global_rest(hip_b).origin.y
		anim = _retarget(dap.get_animation(nm), dskel, skel, skel_path, ratio, 20.0)
		# Standing motions only move the top half: the legs keep the calm stance of the idle,
		# so going in and out of a gesture never shuffles the feet.
		if nm in ["g_wave", "g_chat", "g_scratch", "g_listen", "g_phone", "g_agree", "g_checkout", "g_alert", "g_challenge", "g_defeat"] and rest_idle(model) != "":
			_plant_legs(anim, ap.get_animation("g_rest"))
		if nm in ["g_stand", "g_stand2", "g_sit", "g_sittalk", "g_chat", "g_listen"]:
			anim.loop_mode = Animation.LOOP_LINEAR
		if model.has_meta("file"):
			_gest_cache[ck] = anim
	lib.add_animation(nm, anim)
	return nm


## Poses built here, not recorded. Each one starts from the calm stand and moves a few bones.
##   challenge: the right arm winds back, then is thrown out to point straight down the field,
##              left fist on the hip, shoulders squared to the opponent.
##   defeat:    the head drops, the back rounds and the arms hang. It stays that way.
const MADE_POSES := {
	"g_challenge": {"length": 2.8, "back": 2.1, "order": ["Spine01", "Spine", "neck", "RightArm", "RightForeArm", "LeftArm", "LeftForeArm"],
		"poses": [
			[0.28, {"Spine01": 0.3, "RightArm": Vector3(-0.75, 0.4, -0.5), "RightForeArm": Vector3(-0.2, 0.9, 0.35), "LeftArm": Vector3(0.5, -0.85, 0.1), "LeftForeArm": Vector3(-0.5, -0.2, 0.84)}],
			[0.5, {"Spine01": -0.36, "neck": 0.3, "RightArm": Vector3(-0.3, 0.16, 1.0), "RightForeArm": Vector3(-0.3, 0.16, 1.0), "LeftArm": Vector3(0.62, -0.75, -0.2), "LeftForeArm": Vector3(-0.55, -0.1, 0.83)}],
		]},
	"g_defeat": {"length": 30.0, "back": -1.0, "order": ["Spine02", "Spine01", "Spine", "neck", "Head", "RightArm", "RightForeArm", "LeftArm", "LeftForeArm"],
		"poses": [
			[0.35, {"Spine01": Vector2(0.1, 0.0), "neck": Vector2(0.2, 0.0)}],
			[0.9, {"Spine02": Vector2(0.12, 0.0), "Spine01": Vector2(0.2, 0.0), "Spine": Vector2(0.16, 0.0), "neck": Vector2(0.4, 0.0), "Head": Vector2(0.32, 0.12),
				"RightArm": Vector3(-0.12, -1.0, 0.2), "RightForeArm": Vector3(-0.04, -1.0, 0.28), "LeftArm": Vector3(0.12, -1.0, 0.2), "LeftForeArm": Vector3(0.04, -1.0, 0.28)}],
		]},
}


func _bone_basis(sk: Skeleton3D, bi: int) -> Basis:
	if bi < 0:
		return Basis.IDENTITY
	return _bone_basis(sk, sk.get_bone_parent(bi)) * Basis(sk.get_bone_pose_rotation(bi))


func _make_pose_clip(dap: AnimationPlayer, dskel: Skeleton3D, nm: String) -> void:
	var base: Animation = dap.get_animation("g_stand")
	if base == null or not MADE_POSES.has(nm):
		return
	var def: Dictionary = MADE_POSES[nm]
	var anim := Animation.new()
	anim.length = float(def["length"])
	var tracks := {}                # bone name -> rotation track index in the new clip
	for t in base.get_track_count():
		var nt := anim.add_track(base.track_get_type(t))
		anim.track_set_path(nt, base.track_get_path(t))
		if base.track_get_key_count(t) == 0:
			continue
		var v = base.track_get_key_value(t, 0)
		anim.track_insert_key(nt, 0.0, v)
		anim.track_insert_key(nt, anim.length, v)
		var bn := String(base.track_get_path(t)).get_slice(":", 1)
		if base.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			tracks[bn] = nt
			var bi := dskel.find_bone(bn)
			if bi >= 0:
				dskel.set_bone_pose_rotation(bi, v)
	# A pose says, bone by bone: Vector3 = point this way (the model's own space: +Z forward,
	# +X its left), float = turn about straight up, Vector2 = (bow forward, turn).
	# Worked out parents first, so arms follow the torso.
	var order: Array = def["order"]
	var idle := {}
	for bn in order:
		var bi := dskel.find_bone(bn)
		if bi >= 0:
			idle[bn] = dskel.get_bone_pose_rotation(bi)
	var keyed := []
	for pose in def["poses"]:
		for bn in idle:
			dskel.set_bone_pose_rotation(dskel.find_bone(bn), idle[bn])
		var want: Dictionary = pose[1]
		var got := {}
		for bn in order:
			var bi := dskel.find_bone(bn)
			if bi < 0 or not tracks.has(bn):
				continue
			var q: Quaternion = idle[bn]
			if want.has(bn):
				var pg := _bone_basis(dskel, dskel.get_bone_parent(bi)).orthonormalized()
				var w = want[bn]
				if w is Vector3:
					var cur := (pg * dskel.get_bone_rest(bi).basis.orthonormalized())
					var arc := Quaternion(cur.y.normalized(), (w as Vector3).normalized())
					q = (pg.inverse() * (Basis(arc) * cur)).get_rotation_quaternion()
				else:
					var turn := Basis(Vector3.UP, float(w)) if w is float else Basis(Vector3.UP, (w as Vector2).y) * Basis(Vector3.RIGHT, (w as Vector2).x)
					q = (pg.inverse() * (turn * (pg * Basis(q)))).get_rotation_quaternion()
			dskel.set_bone_pose_rotation(bi, q)
			got[bn] = q
		keyed.append([float(pose[0]), got])
	var back := float(def["back"])
	for bn in order:
		if not tracks.has(bn) or not idle.has(bn):
			continue
		var nt: int = tracks[bn]
		anim.track_remove_key_at_time(nt, anim.length)
		anim.track_insert_key(nt, 0.08, idle[bn])
		for kp in keyed:
			anim.track_insert_key(nt, kp[0], kp[1][bn])
		var last: Quaternion = keyed[keyed.size() - 1][1][bn]
		if back > 0.0:
			anim.track_insert_key(nt, back, last)
			anim.track_insert_key(nt, minf(back + 0.5, anim.length), idle[bn])
		else:
			anim.track_insert_key(nt, anim.length, last)
		dskel.set_bone_pose_rotation(dskel.find_bone(bn), idle[bn])
	var lib := dap.get_animation_library(dap.get_animation_library_list()[0])
	lib.add_animation(nm, anim)


func _plant_legs(anim: Animation, rest: Animation) -> void:
	var keep := {}
	for t in rest.get_track_count():
		var bn := String(rest.track_get_path(t)).get_slice(":", 1)
		var lb := bn.to_lower()
		if lb.contains("leg") or lb.contains("foot") or lb.contains("toe") or lb.contains("thigh") or lb.contains("calf") or lb == "hips" or lb == "pelvis":
			keep[str(rest.track_get_path(t)) + "#" + str(rest.track_get_type(t))] = t
	for t in anim.get_track_count():
		var key := str(anim.track_get_path(t)) + "#" + str(anim.track_get_type(t))
		if not keep.has(key):
			continue
		var src: int = keep[key]
		for k in range(anim.track_get_key_count(t) - 1, -1, -1):
			anim.track_remove_key(t, k)
		var steps := int(ceil(anim.length / 0.2))
		for k in steps + 1:
			var tt := minf(k * 0.2, anim.length)
			var rt := fmod(tt, rest.length)
			if anim.track_get_type(t) == Animation.TYPE_ROTATION_3D:
				anim.rotation_track_insert_key(t, tt, rest.rotation_track_interpolate(src, rt))
			else:
				anim.position_track_insert_key(t, tt, rest.position_track_interpolate(src, rt))


## A calm, natural standing loop made from the model's own skeleton: legs straight under the
## hips, arms hanging close to the body with a soft bend at the elbow, slow breathing and a little
## weight shift. Every rigged humanoid gets the same relaxed posture this way, whatever shape its
## body is. Returns the clip name ("g_rest"), or "" without the bones it needs.
func rest_idle(model: Node) -> String:
	var skel := _first_skeleton(model)
	if skel == null:
		return ""
	var ap := anim_player(model)
	if ap and ap.has_animation("g_rest"):
		return "g_rest"
	var need := {}
	for h in ["Hips", "Head", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg"]:
		var i := bone(model, h)
		if i < 0:
			return ""
		need[h] = i
	if ap == null:
		ap = AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		skel.get_parent().add_child(ap)
		ap.root_node = ap.get_path_to(skel.get_parent())
		ap.add_animation_library("", AnimationLibrary.new())
	elif ap.get_animation_library_list().is_empty():
		ap.add_animation_library("", AnimationLibrary.new())
	var lib := ap.get_animation_library(ap.get_animation_library_list()[0])
	var root := ap.get_node_or_null(ap.root_node)
	if root == null:
		return ""
	var skel_path := str(root.get_path_to(skel))
	var ck := "%s|%s|g_rest" % [str(model.get_meta("file", "")), skel_path]
	var cached: Animation = _gest_cache.get(ck) if model.has_meta("file") else null
	if cached:
		lib.add_animation("g_rest", cached)
		return "g_rest"
	var n := skel.get_bone_count()
	var order: Array = []
	var placed := {}
	while order.size() < n:
		var moved := false
		for i in n:
			if not placed.has(i) and (skel.get_bone_parent(i) < 0 or placed.has(skel.get_bone_parent(i))):
				order.append(i)
				placed[i] = true
				moved = true
		if not moved:
			return ""
	var gr := func(i: int) -> Vector3: return skel.get_bone_global_rest(i).origin
	var u: Vector3 = (gr.call(need["Head"]) - gr.call(need["Hips"])).normalized()
	var r: Vector3 = (gr.call(need["RightUpperLeg"]) - gr.call(need["LeftUpperLeg"]))
	r = (r - u * r.dot(u)).normalized()
	var f := u.cross(r).normalized()
	var first_child := func(i: int, toward: int) -> int:
		# The child that leads toward `toward` (forearm for an upper arm, and so on).
		for c in skel.get_bone_children(i):
			if c == toward:
				return c
		var kids := skel.get_bone_children(i)
		return kids[0] if kids.size() > 0 else -1
	# Where each limb should point, in the skeleton's space.
	var aims := {}
	for side in [["Left", -1.0], ["Right", 1.0]]:
		var out: Vector3 = r * float(side[1])
		aims[need[side[0] + "UpperArm"]] = [need[side[0] + "LowerArm"], (out * 0.11 - u + f * 0.03).normalized()]
		var hand := bone(model, side[0] + "Hand")
		aims[need[side[0] + "LowerArm"]] = [hand, (out * 0.05 - u + f * 0.3).normalized()]
		aims[need[side[0] + "UpperLeg"]] = [need[side[0] + "LowerLeg"], (out * 0.05 - u + f * 0.02).normalized()]
		var foot := bone(model, side[0] + "Foot")
		aims[need[side[0] + "LowerLeg"]] = [foot, (-u + f * 0.0).normalized()]
	var spine: Array = []
	for nm in ["Spine", "Spine01", "Spine02", "spine", "Chest", "UpperChest"]:
		var si := skel.find_bone(nm)
		if si >= 0:
			spine.append(si)
	var neck := skel.find_bone("neck")
	if neck < 0:
		neck = skel.find_bone("Neck")
	var hips: int = need["Hips"]
	var hip_h: float = gr.call(hips).dot(u)
	var a := Animation.new()
	a.length = 4.8
	a.loop_mode = Animation.LOOP_LINEAR
	var tracks := {}
	for i in n:
		var ti := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(ti, NodePath("%s:%s" % [skel_path, skel.get_bone_name(i)]))
		tracks[i] = ti
	var hip_t := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(hip_t, NodePath("%s:%s" % [skel_path, skel.get_bone_name(hips)]))
	var steps := 24
	for k in steps + 1:
		var t := a.length * k / float(steps)
		var ph := TAU * t / a.length
		var breath := sin(ph * 2.0)            # two breaths a loop
		var sway := sin(ph)                    # weight drifts from one foot to the other
		var g := {}
		for i in order:
			var par := skel.get_bone_parent(i)
			var loc := skel.get_bone_rest(i)
			var gi: Transform3D = (g[par] * loc) if par >= 0 else loc
			if i == hips:
				gi.origin += r * sway * 0.012 * hip_h - u * 0.004 * hip_h * (1.0 - absf(sway))
				gi.basis = Basis(f, -sway * 0.018) * gi.basis
			if spine.has(i):
				gi.basis = Basis(r, breath * 0.012) * Basis(f, sway * 0.012) * gi.basis
			if i == neck or i == need["Head"]:
				gi.basis = Basis(r, -breath * 0.01) * Basis(u, sin(ph + 1.3) * 0.03) * gi.basis
			if aims.has(i) and int(aims[i][0]) >= 0:
				var c: int = aims[i][0]
				var cur := ((gi * skel.get_bone_rest(c)).origin - gi.origin).normalized()
				var want: Vector3 = aims[i][1]
				if i == need["LeftUpperArm"] or i == need["RightUpperArm"]:
					want = Basis(f, (0.012 * sin(ph + (0.0 if i == need["LeftUpperArm"] else 1.0)))) * want
				if cur.length() > 0.5 and absf(cur.dot(want)) < 0.99999:
					gi.basis = Basis(Quaternion(cur, want)) * gi.basis
			g[i] = gi
		for i in n:
			var par := skel.get_bone_parent(i)
			var lb: Basis = ((g[par] as Transform3D).basis.inverse() * (g[i] as Transform3D).basis) if par >= 0 else (g[i] as Transform3D).basis
			a.rotation_track_insert_key(tracks[i], t, lb.orthonormalized().get_rotation_quaternion())
		var hp := skel.get_bone_parent(hips)
		var ho: Vector3 = ((g[hp] as Transform3D).affine_inverse() * (g[hips] as Transform3D).origin) if hp >= 0 else (g[hips] as Transform3D).origin
		a.position_track_insert_key(hip_t, t, ho)
	if model.has_meta("file"):
		_gest_cache[ck] = a
	lib.add_animation("g_rest", a)
	return "g_rest"


## The model's AnimationPlayer, if it came with animations (walk/idle...).
func anim_player(model: Node) -> AnimationPlayer:
	if model is AnimationPlayer:
		return model
	for c in model.get_children():
		var a := anim_player(c)
		if a:
			return a
	return null


## A relaxed standing loop built from the first frame of the model's idle clip, with a little
## breathing. (Stock idle clips can include big stretches that look odd on a loop.)
func _calm_idle(ap: AnimationPlayer) -> void:
	var src_name := ""
	for n in ap.get_animation_list():
		if String(n).to_lower().contains("idle"):
			src_name = n
			break
	if ap.has_animation("Calm_Idle") or ap.get_animation_list().is_empty():
		return
	# No idle clip at all (a model that only came with a walk): stand in the skeleton's own
	# rest pose instead, so nobody is left frozen mid-stride or in a T-pose.
	var from_rest := src_name == ""
	if from_rest:
		src_name = clip(ap, "walk")
		if src_name == "":
			return
	var src := ap.get_animation(src_name)
	var root := ap.get_node_or_null(ap.root_node)
	# Arms hang the way they do mid-stride: the average of the walk's arm keys.
	var rest := {}
	var walk_name := ""
	for n in ap.get_animation_list():
		if String(n).to_lower().contains("walk"):
			walk_name = n
			break
	if walk_name != "":
		var w := ap.get_animation(walk_name)
		for t in w.get_track_count():
			if w.track_get_type(t) != Animation.TYPE_ROTATION_3D or w.track_get_key_count(t) == 0:
				continue
			var wb := String(w.track_get_path(t)).get_slice(":", 1).to_lower()
			if not (wb.contains("arm") or wb.contains("shoulder") or wb.contains("hand")):
				continue
			var first: Quaternion = w.track_get_key_value(t, 0)
			var acc := Vector4.ZERO
			for k in w.track_get_key_count(t):
				var q: Quaternion = w.track_get_key_value(t, k)
				if q.dot(first) < 0.0:
					q = -q
				acc += Vector4(q.x, q.y, q.z, q.w)
			if acc.length() > 0.001:
				acc = acc.normalized()
				rest[String(w.track_get_path(t))] = Quaternion(acc.x, acc.y, acc.z, acc.w)
	var a := Animation.new()
	a.length = 3.6
	a.loop_mode = Animation.LOOP_LINEAR
	for t in src.get_track_count():
		if src.track_get_key_count(t) == 0:
			continue
		var v = src.track_get_key_value(t, 0)
		if from_rest:
			var tp := String(src.track_get_path(t))
			var skel := root.get_node_or_null(NodePath(tp.get_slice(":", 0))) as Skeleton3D if root else null
			var bi := skel.find_bone(tp.get_slice(":", 1)) if skel else -1
			if bi < 0:
				continue
			var rp := skel.get_bone_rest(bi)
			match src.track_get_type(t):
				Animation.TYPE_ROTATION_3D:
					v = rp.basis.get_rotation_quaternion()
				Animation.TYPE_POSITION_3D:
					v = rp.origin
				Animation.TYPE_SCALE_3D:
					v = rp.basis.get_scale()
				_:
					continue
		var ti := a.add_track(src.track_get_type(t))
		a.track_set_path(ti, src.track_get_path(t))
		if src.track_get_type(t) == Animation.TYPE_ROTATION_3D and rest.has(String(src.track_get_path(t))):
			v = rest[String(src.track_get_path(t))]
		var bone := String(src.track_get_path(t)).get_slice(":", 1).to_lower()
		if src.track_get_type(t) == Animation.TYPE_ROTATION_3D and v is Quaternion and (bone.begins_with("spine") or bone == "head" or bone.contains("arm")):
			var amt := 0.022 if bone.begins_with("spine") else (-0.03 if bone == "head" else 0.012)
			var axis := Vector3.RIGHT if not bone.contains("arm") else Vector3.FORWARD
			a.rotation_track_insert_key(ti, 0.0, v)
			a.rotation_track_insert_key(ti, 1.8, (v as Quaternion) * Quaternion(axis, amt))
			a.rotation_track_insert_key(ti, 3.6, v)
		else:
			a.track_insert_key(ti, 0.0, v)
			a.track_insert_key(ti, 3.6, v)
	var lib := ap.get_animation_library(ap.get_animation_library_list()[0])
	if lib and not lib.has_animation("Calm_Idle"):
		lib.add_animation("Calm_Idle", a)


## Best clip for a motion: "idle", "walk", "run" or "victory".
func clip(ap: AnimationPlayer, motion: String) -> String:
	var names := ap.get_animation_list()
	if motion == "idle" and ap.has_animation("Calm_Idle"):
		return "Calm_Idle"
	for n in names:
		if String(n).to_lower().contains(motion):
			return n
	if motion == "run":
		return clip(ap, "walk")
	return names[0] if names.size() > 0 and motion == "walk" else ""


func _register() -> void:
	if _registered:
		return
	_registered = true
	Engine.set_meta("vrm_runtime_no_retarget", true)
	for ext in VRM1_EXTS:
		GLTFDocument.register_gltf_document_extension(ext.new())


## Load a VRM as a fresh Node3D, posed and tinted (tints only for the player).
func load_model(key: String) -> Node3D:
	if not has_avatar(key):
		return null
	var path := path_for(key)
	if path.ends_with(".glb"):
		var g := _load_glb(path)
		if g == null:
			return null
		if not path.begins_with("res://"):
			g = _merge_clip_files(key, path, g)
			_borrow_clips(g)
		var r := Node3D.new()
		r.set_meta("file", path)
		r.set_meta("human_bones", _guess_human_map(g))
		r.set_meta("animated", anim_player(g) != null)
		r.add_child(g)
		var ap := anim_player(g)
		if ap:
			_calm_idle(ap)
			for n in ap.get_animation_list():
				var a := ap.get_animation(n)
				var ln := String(n).to_lower()
				if ln.contains("walk") or ln.contains("run") or ln.contains("idle"):
					a.loop_mode = Animation.LOOP_LINEAR
			var idle := clip(ap, "idle")
			if idle != "":
				ap.play(idle)
		elif key == "player":
			apply_tints(g)
		if key == "player" and path.begins_with("res://"):
			apply_hero_color(g, Profile.color(), Profile.look_outfit)
		if UNIFORMS.has(key) and is_standin(key):
			apply_uniform(g, DORM_COLORS[UNIFORMS[key]])
		return r
	_register()
	var gltf := GLTFDocument.new()
	var vrm0: GLTFDocumentExtension = VRM0_EXT.new()
	gltf.register_gltf_document_extension(vrm0, true)
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err := gltf.append_from_file(path, state, IMPORT_USE_NAMED_SKIN_BINDS)
	var scene: Node = null
	if err == OK:
		scene = gltf.generate_scene(state)
	GLTFDocument.unregister_gltf_document_extension(vrm0)
	if scene == null:
		push_warning("Could not load VRM for %s" % key)
		return null
	var root := Node3D.new()
	root.set_meta("human_bones", _human_map(state))
	root.add_child(scene)
	_relax_pose(root)
	if key == "player":
		apply_tints(scene)
	return root


func _skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _skeleton(c)
		if s:
			return s
	return null


## Humanoid bone name -> this model's skeleton bone name (from the VRM data).
func _human_map(state: GLTFState) -> Dictionary:
	var out := {}
	var ext: Dictionary = state.json.get("extensions", {})
	var nodes := state.get_nodes()
	var pairs := []
	if ext.has("VRMC_vrm"):
		var hb: Dictionary = ext["VRMC_vrm"].get("humanoid", {}).get("humanBones", {})
		for k in hb:
			pairs.append([k, int(hb[k].get("node", -1))])
	elif ext.has("VRM"):
		for e in ext["VRM"].get("humanoid", {}).get("humanBones", []):
			pairs.append([e.get("bone", ""), int(e.get("node", -1))])
	for pr in pairs:
		var idx: int = pr[1]
		if idx < 0 or idx >= nodes.size():
			continue
		var k: String = pr[0]
		out[k.substr(0, 1).to_upper() + k.substr(1)] = String(nodes[idx].resource_name)
	return out


func bone(model: Node, human: String) -> int:
	var sk := _skeleton(model)
	if sk == null:
		return -1
	var hm: Dictionary = model.get_meta("human_bones", {}) if model.has_meta("human_bones") else {}
	var i := sk.find_bone(hm.get(human, human))
	return i if i != -1 else sk.find_bone(human)


## VRM models stand in a T-pose. Bring the arms down to the sides.
func _relax_pose(model: Node) -> void:
	var sk := _skeleton(model)
	if sk == null:
		return
	for pair in [["LeftUpperArm", "LeftLowerArm"], ["RightUpperArm", "RightLowerArm"]]:
		var ua := bone(model, pair[0])
		var la := bone(model, pair[1])
		if ua == -1 or la == -1:
			continue
		var g_ua := sk.get_bone_global_rest(ua)
		var dir := (sk.get_bone_global_rest(la).origin - g_ua.origin).normalized()
		var target := Vector3(signf(dir.x) * 0.3, -0.95, 0.0).normalized()
		var q := Quaternion(dir, target)
		var new_global := Basis(q) * g_ua.basis
		var parent := sk.get_bone_parent(ua)
		var pb := sk.get_bone_global_rest(parent).basis if parent != -1 else Basis()
		sk.set_bone_pose_rotation(ua, (pb.inverse() * new_global).get_rotation_quaternion())


func head_position(model: Node3D) -> Vector3:
	var sk := _skeleton(model)
	if sk:
		var idx := bone(model, "Head")
		if idx != -1:
			return (sk.global_transform * sk.get_bone_global_pose(idx)).origin
	return Vector3(0, 1.45, 0)


# ------------------------------------------------------------------ customization

## Material groups VRoid uses in its material names.
const GROUPS := {
	"hair": ["hair"],
	"outfit": ["cloth", "tops", "bottoms", "shoes", "onepiece", "huku", "outfit"],
	"eyes": ["eyeiris", "eye_iris", "iris"],
}


var _hero_shader: Shader


## Your signature color on the built-in hero: the accent parts of the outfit (and the hair streak)
## are repainted in it. The models are painted with a teal accent (orange on the rider suit), so
## only pixels close to that hue and strongly colored are touched; skin and neutrals stay as they are.
func apply_hero_color(scene: Node, color: Color, outfit := 0) -> void:
	if _hero_shader == null:
		_hero_shader = Shader.new()
		_hero_shader.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform float hue = 0.5;
uniform float sat_mul = 1.0;
uniform float from_hue = 0.49;
uniform float band = 0.075;
uniform float min_sat = 0.28;
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}
void fragment() {
	vec4 t = texture(tex, UV);
	vec3 h = rgb2hsv(t.rgb);
	float d = abs(h.x - from_hue);
	d = min(d, 1.0 - d);
	float m = (1.0 - smoothstep(band * 0.7, band, d)) * smoothstep(min_sat, min_sat + 0.12, h.y);
	vec3 sw = hsv2rgb(vec3(hue, clamp(h.y * sat_mul, 0.0, 1.0), h.z));
	ALBEDO = mix(t.rgb, sw, m);
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
"""
	for mi in _meshes(scene):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i)
			if not (mat is BaseMaterial3D) or (mat as BaseMaterial3D).albedo_texture == null:
				continue
			var sm := ShaderMaterial.new()
			sm.shader = _hero_shader
			sm.set_shader_parameter("tex", (mat as BaseMaterial3D).albedo_texture)
			sm.set_shader_parameter("hue", color.h)
			sm.set_shader_parameter("sat_mul", clampf(color.s / 0.8, 0.6, 1.3))
			if outfit == 2:
				sm.set_shader_parameter("from_hue", 0.065)
				sm.set_shader_parameter("band", 0.05)
				sm.set_shader_parameter("min_sat", 0.62)
			mi.set_surface_override_material(i, sm)


## Paint a dorm jacket on a model: the torso and sleeves take the dorm color with white trim at
## the collar, cuffs and hem. Works on the rest pose, so it follows the body when it moves.
func apply_uniform(scene: Node, color: Color) -> void:
	if _uniform_shader == null:
		_uniform_shader = Shader.new()
		_uniform_shader.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 coat : source_color = vec3(0.85, 0.2, 0.17);
uniform float h = 1.7;
uniform float top = 0.80;
uniform float hem_y = 0.50;
uniform mat4 to_root;
varying vec3 lp;
void vertex() { lp = (to_root * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec4 t = texture(tex, UV);
	float y = lp.y / h;
	float x = abs(lp.x) / h;
	float arm = smoothstep(0.115, 0.135, x);
	float lo = mix(hem_y, hem_y + 0.065, arm);
	float body = smoothstep(lo, lo + 0.012, y) * (1.0 - smoothstep(top, top + 0.012, y)) * (1.0 - smoothstep(0.375, 0.39, x));
	float lum = dot(t.rgb, vec3(0.3, 0.59, 0.11));
	vec3 cloth = coat * (0.5 + 0.7 * lum);
	// Trim is thin piping, not panels: a line just above the hem, one at each cuff, a narrow
	// zip, and two short collar tabs. Soft edges, and off-white so it sits in the cloth.
	float hem = smoothstep(hem_y + 0.012, hem_y + 0.017, y) * (1.0 - smoothstep(hem_y + 0.024, hem_y + 0.029, y)) * (1.0 - arm);
	float cuff = arm * smoothstep(hem_y + 0.072, hem_y + 0.076, y) * (1.0 - smoothstep(hem_y + 0.083, hem_y + 0.087, y));
	float tab = smoothstep(top - 0.03, top - 0.024, y) * smoothstep(0.012, 0.018, x) * (1.0 - smoothstep(0.04, 0.048, x)) * step(0.0, lp.z);
	float zip = (1.0 - smoothstep(0.003, 0.006, x)) * step(0.0, lp.z) * (1.0 - smoothstep(top - 0.03, top - 0.02, y));
	float trim = clamp(hem + cuff + tab + zip, 0.0, 1.0) * 0.85;
	// A slightly darker yoke over the shoulders gives the jacket some shape.
	cloth *= mix(1.0, 0.82, smoothstep(top - 0.07, top - 0.03, y));
	cloth = mix(cloth, mix(vec3(0.93, 0.92, 0.88), coat, 0.12) * (0.62 + 0.45 * lum), trim);
	ALBEDO = mix(t.rgb, cloth, body);
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
"""
	# Skinned vertices reach the shader in the skeleton's space (often centimeters), so hand it
	# the transform back to the model's own space, where the feet are at 0 and Y is up.
	var skel := _skeleton(scene)
	for mi in _meshes(scene):
		if mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		if box.size.y < 0.01:
			continue
		var top := 0.80
		var hem := 0.50
		var rel := Transform3D.IDENTITY
		var n: Node = skel if (skel != null and mi.skin != null) else mi
		while n != null and n != scene:
			if n is Node3D:
				rel = (n as Node3D).transform * rel
			n = n.get_parent()
		# The jacket runs from the hips to the base of the neck, wherever this body has them.
		if skel != null and mi.skin != null:
			for b in skel.get_bone_count():
				var bn := skel.get_bone_name(b).to_lower()
				var by: float = (rel * skel.get_bone_global_rest(b).origin).y / box.size.y
				if bn.ends_with("neck") or bn == "neck":
					top = clampf(by - 0.012, 0.62, 0.88)
				elif bn.ends_with("hips") or bn == "hips" or bn.ends_with("pelvis"):
					hem = clampf(by - 0.035, 0.40, 0.58)
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i)
			var tex: Texture2D = null
			if mat is BaseMaterial3D:
				tex = (mat as BaseMaterial3D).albedo_texture
			elif mat is ShaderMaterial:
				tex = (mat as ShaderMaterial).get_shader_parameter("tex")
			if tex == null:
				continue
			var sm := ShaderMaterial.new()
			sm.shader = _uniform_shader
			sm.set_shader_parameter("tex", tex)
			sm.set_shader_parameter("coat", color)
			sm.set_shader_parameter("h", box.size.y)
			sm.set_shader_parameter("top", top)
			sm.set_shader_parameter("hem_y", hem)
			sm.set_shader_parameter("to_root", rel)
			mi.set_surface_override_material(i, sm)


func apply_tints(scene: Node) -> void:
	for mi in _meshes(scene):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat == null:
				continue
			var group := _group_of(str(mat.resource_name))
			if group == "":
				continue
			var tint: Color = Profile.tints.get(group, Color.WHITE)
			if tint == Color.WHITE:
				mi.set_surface_override_material(i, null)
				continue
			var m: Material = mat.duplicate()
			if m is ShaderMaterial:
				for pname in ["_Color", "albedo_color", "_MainColor"]:
					var cur = m.get_shader_parameter(pname)
					if cur != null:
						m.set_shader_parameter(pname, Color(cur) * tint)
						break
			elif m is BaseMaterial3D:
				m.albedo_color = m.albedo_color * tint
			mi.set_surface_override_material(i, m)


func _group_of(name: String) -> String:
	name = name.to_lower()
	if name == "eye":
		return "eyes"
	for g in GROUPS:
		for k in GROUPS[g]:
			if name.contains(k):
				return g
	return ""


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out


# ------------------------------------------------------------------ live portraits

## A live 3D portrait (upper body, idle motion). Null if there's no VRM.
const HI_SIZE := Vector2i(1024, 1280)
const HI_MAX := 4
var _hi: Array[String] = []      # the few portraits being shown big right now


## `hi` asks for the portrait at double size, for when it fills a large part of the screen.
## Only the last few asked for stay that sharp; the rest go back to the normal size.
func portrait(key: String, hi := false) -> Texture2D:
	if _stages.has(key):
		_touch(key)
		if hi:
			_sharpen(key)
		return (_stages[key] as SubViewport).get_texture()
	var model := load_model(key)
	if model == null:
		return null
	var vp := SubViewport.new()
	vp.size = STAGE_SIZE
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var stage := Node3D.new()
	stage.set_script(preload("res://scripts/core/avatar_stage.gd"))
	vp.add_child(stage)
	stage.call("setup", model)
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_stages[key] = vp
	_touch(key)
	if hi:
		_sharpen(key)
	return vp.get_texture()


func _sharpen(key: String) -> void:
	_hi.erase(key)
	_hi.push_front(key)
	(_stages[key] as SubViewport).size = HI_SIZE
	while _hi.size() > HI_MAX:
		var old: String = _hi.pop_back()
		if _stages.has(old):
			(_stages[old] as SubViewport).size = STAGE_SIZE


const LIVE_MAX := 5
var _live: Array[String] = []


## Only the few most recently asked-for portraits keep animating; the rest hold their last frame.
func _touch(key: String) -> void:
	_live.erase(key)
	_live.push_front(key)
	(_stages[key] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS
	while _live.size() > LIVE_MAX:
		var old: String = _live.pop_back()
		if _stages.has(old):
			_freeze_later(old)


func _freeze_later(key: String) -> void:
	await get_tree().create_timer(0.6).timeout
	if _stages.has(key) and not _live.has(key):
		(_stages[key] as SubViewport).render_target_update_mode = SubViewport.UPDATE_DISABLED


## Re-apply the profile's colors to the live player model.
func retint(key := "player") -> void:
	if _stages.has(key):
		var stage: Node = _stages[key].get_child(0)
		if stage.get("_model"):
			apply_tints(stage.get("_model"))


func forget(key: String) -> void:
	_live.erase(key)
	if _stages.has(key):
		_stages[key].queue_free()
		_stages.erase(key)
