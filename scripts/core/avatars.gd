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
## Somebody known by a name of their own who wears one of the people models: a duelist of the worlds
## (the "First-Year Student" is `student_a` and looks like `student_girl`). Set when a duel with them
## starts, so the duel shows them and not a drawn stand-in. (0.64.2)
var look_as := {}

## (0.73.0) The duelists of the people you play online: "net:<their id>" -> their look, as they sent it
## (the same names Profile uses: look_body, look_hair, ...). They are made like your own duelist.
var guests := {}


func guest_look(key: String) -> Dictionary:
	return guests.get(key.get_slice("@", 0), {})


func path_for(key: String) -> String:
	if key.begins_with("net:"):
		var gl := guest_look(key)
		if gl.is_empty():
			return ""
		var body := str(HeroLook.models(int(gl.get("look_body", 0)), int(gl.get("look_hair", 0)), int(gl.get("look_outfit", 0)))["body"])
		var bundled := "res://assets/models/people/%s.glb" % body
		return bundled if ResourceLoader.exists(bundled) else ""
	var own := own_file(key)
	if own != "":
		return own
	for k in [key, Profile.hero_key() if key == "player" else "", STANDINS.get(key, ""), look_as.get(key, "")]:
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
	# (0.80.0) the fifteen new duelists, until their own model is dropped in
	"mako": "hero_m1_island", "jesse": "hero_m2_academy", "hassleberry": "hero_m1_varsity", "atticus": "hero_m1_academy", "yubel": "hunter", "leo5ds": "hero_m1_sporty", "luna": "hero_f1_sporty", "trudge": "hero_m1_trench", "sherry": "hero_f1_rider", "goodwin": "hero_m1_vest", "halldor": "hero_m2_rider", "dragan": "hero_m1_rider", "broder": "hero_m3_street", "bronk": "hero_m1_heartland", "tori": "hero_f1_heartland",
	"kid": "street_duelist", "vendor": "shopkeeper", "grandpa": "shopkeeper", "guard": "office_worker", "lumen": "student_girl", "vesper": "stylish_woman", "curator": "shopkeeper", "aurel": "shopkeeper", "vellum": "duelist_m7", "ren": "duelist_m11", "boy_sol": "student_boy", "boy_aurel": "duelist_m11",
	"dai": "student_boy", "koji": "student_boy", "mechanic": "street_duelist",
	"professor": "duelist_m3", "red_student": "student_boy", "yellow_student": "duelist_m4", "blue_student": "duelist_m7",
	# The Academy story: until their own model is dropped in (or made), people the game already has.
	"nico": "student_boy", "mika": "student_girl", "bruno": "street_duelist", "sato": "stylish_woman", "crowler": "office_worker",
	"sheppard": "elder_m", "dorothy": "duelist_f1", "bastion": "duelist_m4", "dante": "duelist_m7",
	"octavia": "duelist_f2", "crane": "duelist_m3",
	"gus": "student_boy", "felix": "duelist_m7", "ivo": "duelist_m4",
	"moth": "street_duelist", "ink": "student_girl",
	# Act 2: Boreal Academy and the Lantern rank of the Circle.
	"irina": "duelist_f3", "tova": "stylish_woman", "rurik": "duelist_m16",
	"sparrow": "student_girl", "bell": "duelist_m1", "paper": "duelist_m6", "harbor": "duelist_m13",
	# Act 3: the Academy of the Sun, Apex Academy, a memory, and the Midnight rank of the Circle.
	"leo": "duelist_m15", "paco": "street_duelist", "luz": "student_girl", "brisa": "duelist_f3", "tano": "duelist_m17",
	"selene": "duelist_f1", "mirela": "duelist_f3", "otto": "duelist_m5", "cassius": "duelist_m6", "ansel": "duelist_m2",
	"crane_young": "duelist_m3", "tuesday": "stylish_woman",
	# Act 4: the Pro League.
	"vera": "duelist_f3", "milo": "duelist_m19", "cassia": "duelist_f1", "petra": "student_girl", "dov": "duelist_m1", "ines": "duelist_f2", "bram": "duelist_m14",
}
## Duel Academy jackets. Painted over stand-in models only, never over a model you supplied.
const DORM_COLORS := {"red": Color("d9342b"), "yellow": Color("f2c230"), "blue": Color("2f6fe0")}
const UNIFORMS := {"jaden": "red", "syrus": "red", "red_student": "red", "koji": "red", "yellow_student": "yellow",
	"chazz": "blue", "alexis": "blue", "zane": "blue", "blue_student": "blue",
	"nico": "red", "mika": "red", "bruno": "red", "bastion": "yellow", "dante": "blue", "octavia": "blue",
	"gus": "red", "felix": "blue", "ivo": "yellow", "hassleberry": "yellow", "atticus": "blue"}
## People of other schools: the coat of their school, painted the same way (and only on stand-ins).
const COATS := {"irina": Color("8a8f98"), "tova": Color("8a8f98"), "rurik": Color("8a8f98"),
	"leo": Color("e8862a"), "paco": Color("e8862a"), "luz": Color("e8862a"), "brisa": Color("e8862a"), "tano": Color("e8862a"),
	"selene": Color("f1efe6"), "mirela": Color("f1efe6"), "otto": Color("f1efe6"), "cassius": Color("f1efe6"), "ansel": Color("f1efe6"),
	"crane_young": Color("d9342b"),
	"vera": Color("dfe4ec"), "milo": Color("5a6b4a"), "cassia": Color("c9b48a"), "petra": Color("b8322e"), "dov": Color("3a3442"), "ines": Color("5f8f9a"), "bram": Color("2b2b30")}
var _uniform_shader: Shader
## People who are not in their dorm jacket right now (the Academy story's prologue: nobody has a
## dorm before the entrance exam). key -> true.
var plain := {}


## Originals of the Academy story with a model of their own that is drawn in plain clothes, so the
## dorm jacket is painted on it the same way it is on a stand-in (and can change with a promotion).
const PAINTED := ["nico", "mika", "bruno", "dante", "octavia"]

## True when a dorm jacket may be painted on this character: a stand-in, or one of the game's own
## Academy students. Never a model you supplied.
func takes_jacket(key: String) -> bool:
	return is_standin(key) or (key in PAINTED and own_file(key) == "")


## True when this character is shown with a stand-in, not their own model.
func is_standin(key: String) -> bool:
	return key != "player" and own_file(key) == "" and STANDINS.has(key) \
			and not ResourceLoader.exists("res://assets/models/people/%s.glb" % key)


func has_avatar(key: String) -> bool:
	# "student_boy@d9342b" is the same person in a dorm jacket of that color (portraits only).
	return key != "" and path_for(key.get_slice("@", 0)) != ""


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


# ---- reading ahead. A dropped-in .glb is some 14 MB with its pictures inside: reading one on the
# spot stalls everything for a moment. `warm` reads it on a worker thread; `_load_glb` then
# only has to build the scene from what was read.
var _warm := {}            # path -> [GLTFDocument, GLTFState], filled by the worker
var _warm_ids := {}        # path -> worker task id (main thread only)
var _warm_lock := Mutex.new()


## Start reading this duelist's model in the background, if it is not on hand already.
## `sharp`: for a portrait (the color texture keeps up to 2048); a world asks with false.
func warm(key: String, sharp := true) -> void:
	key = key.get_slice("@", 0)
	if (sharp and _stages.has(key)) or not has_avatar(key):
		return
	var path := path_for(key)
	if path.begins_with("res://"):
		if not _tpl.has(path) and not ResourceLoader.has_cached(path) and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_request(path)
			_res_reading.append(path)
		return
	_reap_warm()
	if not path.ends_with(".glb") or _kept(path, sharp):
		return
	var wk := _warm_key(path, 2048 if sharp else 1024)
	if _warm_ids.has(wk):
		return
	_warm_lock.lock()
	var have := _warm.has(wk)
	_warm_lock.unlock()
	if have:
		return
	if _warm_ids.size() >= 3:
		# (0.72.3: three are being read: this one waits its turn instead of being forgotten)
		if not _warm_wanted.has(wk):
			_warm_wanted.append(wk)
		return
	_warm_wanted.erase(wk)
	_warm_start(wk)


var _warm_wanted: Array = []      # reads waiting for a free reader ("<file>|<color size>")
var _tex_fit: GLTFDocumentExtension = null


func _warm_key(path: String, cap: int) -> String:
	return "%s|%d" % [path, cap]


func _warm_start(wk: String) -> void:
	_tex_fit_on()
	var cut := wk.rfind("|")
	_warm_ids[wk] = WorkerThreadPool.add_task(_warm_read.bind(wk.substr(0, cut), int(wk.substr(cut + 1))), false, "read a duelist's model")


## The helper that sizes a model's textures while its file is read (model_tex_fit.gd), put in place
## once. It only acts on a read that asks for it.
func _tex_fit_on() -> void:
	if _tex_fit == null:
		_tex_fit = load("res://scripts/core/model_tex_fit.gd").new()
		GLTFDocument.register_gltf_document_extension(_tex_fit)


## The ones that waited for a reader get theirs as the others finish.
func _warm_next() -> void:
	_reap_warm()
	while _warm_ids.size() < 3 and not _warm_wanted.is_empty():
		var wk := str(_warm_wanted.pop_front())
		_warm_lock.lock()
		var have := _warm.has(wk)
		_warm_lock.unlock()
		if not have and not _warm_ids.has(wk):
			_warm_start(wk)


func _warm_read(path: String, cap: int) -> void:
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	if cap > 0:
		state.set_additional_data(&"yc_cap", cap)      # (its textures are sized as they are decoded, here on this thread)
	var ok := gltf.append_from_file(path, state) == OK
	_warm_lock.lock()
	# A file that cannot be read is marked too, so nobody waits on it forever.
	_warm[_warm_key(path, cap)] = [gltf, state, Time.get_ticks_msec()] if ok else []
	_warm_lock.unlock()


## Is this model already kept aside, whole (see _own_copy)?
func _kept(path: String, sharp: bool) -> bool:
	var t: Dictionary = _tpl.get("%s|%d" % [path, int(sharp)], {})
	return not t.is_empty() and is_instance_valid(t["node"])


## Can this duelist's portrait be shown right now without stopping to read a file?
func ready_now(key: String) -> bool:
	key = key.get_slice("@", 0)
	if _stages.has(key) or not has_avatar(key):
		return true
	var path := path_for(key)
	if path.begins_with("res://"):
		return _tpl.has(path) or ResourceLoader.has_cached(path) or ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED
	if not path.ends_with(".glb") or _kept(path, true):
		return true
	_reap_warm()
	_warm_lock.lock()
	var have := _warm.has(_warm_key(path, 2048))
	_warm_lock.unlock()
	return have


## A model that was read ahead and then never asked for (a face that was scrolled past) is let go
## after a minute: it holds its meshes and textures.
func _warm_expire() -> void:
	var now := Time.get_ticks_msec()
	_warm_lock.lock()
	for wk in _warm.keys():
		var w: Array = _warm[wk]
		if w.size() >= 3 and now - int(w[2]) > 60000:
			_warm.erase(wk)
	_warm_lock.unlock()


## Finished background reads are collected (a worker task has to be waited for once).
func _reap_warm() -> void:
	for wk in _warm_ids.keys():
		if WorkerThreadPool.is_task_completed(int(_warm_ids[wk])):
			WorkerThreadPool.wait_for_task_completion(int(_warm_ids[wk]))
			_warm_ids.erase(wk)


## `cap`: the size its color texture is held to as the file is read (0: everything as it is).
func _load_glb(path: String, cap := 0) -> Node:
	if path.begins_with("res://"):
		# (0.72.4) A bundled model's scene is kept (within the same budget as the dropped-in ones):
		# with nobody made from it left, the engine lets its textures go and the next one read
		# them from the disk again, a tenth of a second each.
		var t: Dictionary = _tpl.get(path, {})
		var t0 := Time.get_ticks_usec()
		var ps = t["scene"] if not t.is_empty() else load(path)
		if not (ps is PackedScene):
			return null
		var made: Node = (ps as PackedScene).instantiate()
		if t.is_empty():
			if _laps:
				print("SCENE %s: %.0f ms  %s" % [path.get_file(), (Time.get_ticks_usec() - t0) / 1000.0, "behind the card" if Router.loading else "IN THE WORLD"])
			t = {"scene": ps, "mb": _weight_mb(made)}
			_tpl[path] = t
			t["used"] = Time.get_ticks_msec()
			_tpl_trim()
		t["used"] = Time.get_ticks_msec()
		return made
	var wk := _warm_key(path, cap)
	_warm_wanted.erase(wk)
	if _warm_ids.has(wk):
		# Being read right now: wait for that instead of reading it a second time.
		WorkerThreadPool.wait_for_task_completion(int(_warm_ids[wk]))
		_warm_ids.erase(wk)
	_warm_lock.lock()
	var w = _warm.get(wk)
	_warm.erase(wk)
	_warm_lock.unlock()
	if w is Array and (w as Array).size() >= 2:
		return (w[0] as GLTFDocument).generate_scene(w[1])
	_tex_fit_on()
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	if cap > 0:
		state.set_additional_data(&"yc_cap", cap)
	if gltf.append_from_file(path, state) != OK:
		return null
	return gltf.generate_scene(state)


## A model made outside the game usually brings three 2048 x 2048 textures (color, bumps, shine):
## about 60 MB on the graphics card for somebody who is a few hundred pixels tall on screen. They are
## brought down to what the screen can show: `color_max` for the color, 1024 for the rest (0.63.1).
func _fit_textures(scene: Node, color_max: int) -> void:
	var done := {}
	for mi in _meshes(scene):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if not (mat is BaseMaterial3D):
				continue
			var bm := mat as BaseMaterial3D
			for prop in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "ao_texture", "emission_texture"]:
				var tex = bm.get(prop)
				if not (tex is Texture2D):
					continue
				var cap := color_max if prop == "albedo_texture" else mini(color_max, 1024)
				if (tex as Texture2D).get_width() <= cap and (tex as Texture2D).get_height() <= cap:
					continue
				var dk := "%d|%d" % [(tex as Texture2D).get_instance_id(), cap]
				if not done.has(dk):
					var img := (tex as Texture2D).get_image()
					if img == null or img.is_empty():
						continue
					if img.is_compressed():
						img.decompress()
					var k := float(cap) / float(maxi(img.get_width(), img.get_height()))
					img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_BILINEAR)
					img.generate_mipmaps(prop == "normal_texture")
					done[dk] = ImageTexture.create_from_image(img)
				bm.set(prop, done[dk])


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
func _borrow_clips(g: Node, file := "") -> void:
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
		# (0.72.3: fitted once per model file and kept, in memory and on disk. It used to be worked out
		# again for every copy of a model, every time: 50 to 170 ms per person put into a world.)
		var ck := "%s|%s|borrow|%s" % [file, skel_path, m]
		var fitted: Animation = _gest_cache.get(ck) if file != "" else null
		if fitted == null and file != "":
			fitted = _fit_load(ck, g, file)
		if fitted == null:
			fitted = _retarget(dap.get_animation(src_name), dskel, skel, skel_path, ratio)
			if file != "":
				_fit_save(ck, g, fitted, file)
		if file != "":
			_gest_cache[ck] = fitted
		lib.add_animation(m, fitted)


## Re-make a donor clip for another skeleton of the same family. The two can be bound in
## different poses (one arms-out, one arms-down) with bones rolled differently, so copying the
## numbers across bends everything the wrong way. Instead: work out how far each donor bone has
## turned from its own rest pose, in world terms, and turn the matching bone the same amount
## from where the donor's rest would put it.
##
## The arms get a second pass (0.63.1), because turning bones the same amount is only right when
## the two bodies have the same proportions. A model with longer arms and a bigger head ends up
## with a hand that should stop at the chin flat on the face, and two fists that should meet in
## front of the chest crossed past each other. So each hand is put where the donor's hand is
## RELATIVE TO THE BODY (between the shoulders, up to the top of the head, down to the hips, each
## measured on its own body), the elbow is bent to reach it, and no hand may sit in front of the
## face. A straight arm (pointing, hanging, a cheer) keeps its direction instead.
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
	# The arms by position: what each body measures, and the bones whose keys wait for that pass.
	var da := _arm_frame(dskel)
	var ta := _arm_frame(skel)
	var arms: bool = arms_by_position and not da.is_empty() and not ta.is_empty()
	var later := {}
	var body := {}
	if arms:
		body = _body_stats(skel, ta)
		for side in 2:
			for k in ["arm", "fore", "hand"]:
				later[int(ta[k][side])] = true
	var rec: Array = []
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
		var tp: Array = []      # where each of this skeleton's joints is (skeleton space)
		tp.resize(tn)
		for tb in tn:
			var par := skel.get_bone_parent(tb)
			var pg: Basis = tg[par] if par >= 0 else Basis.IDENTITY
			if tb == hip and dhip >= 0:
				tp[tb] = (dg[dhip] as Transform3D).origin * ratio
			elif par >= 0:
				tp[tb] = (tp[par] as Vector3) + pg * skel.get_bone_rest(tb).origin
			else:
				tp[tb] = skel.get_bone_rest(tb).origin
			var b: int = from_donor[tb]
			if b < 0:
				tg[tb] = pg * skel.get_bone_rest(tb).basis.orthonormalized()
				continue
			var turned := (dg[b] as Transform3D).basis.orthonormalized() * dskel.get_bone_global_rest(b).basis.orthonormalized().inverse()
			var gb: Basis = turned * (fix[tb] as Basis) * skel.get_bone_global_rest(tb).basis.orthonormalized()
			tg[tb] = gb
			if not later.has(tb):
				out.rotation_track_insert_key(track_of[tb], t, (pg.inverse() * gb).orthonormalized().get_rotation_quaternion())
		if hip_track >= 0:
			out.position_track_insert_key(hip_track, t, hip_parent_inv * ((dg[dhip] as Transform3D).origin * ratio))
		if arms:
			rec.append(_arm_wants(dskel, skel, da, ta, body, dg, tg, tp, t))
	if arms:
		_arm_solve(out, track_of, ta, rec)
	return out


## Bring the head and the neck most of the way back to how the model holds them at rest (keep = how
## much of the clip's own nod or bow stays). `also`: more bones to straighten the same way (the spine).
func _calm_head(anim: Animation, skel: Skeleton3D, skel_path: String, keep: float, also: Array = []) -> void:
	for bn in ["Head", "neck", "Neck"] + also:
		var bi := skel.find_bone(bn)
		var ti := anim.find_track(NodePath("%s:%s" % [skel_path, bn]), Animation.TYPE_ROTATION_3D)
		if bi < 0 or ti < 0:
			continue
		var rest := skel.get_bone_rest(bi).basis.orthonormalized().get_rotation_quaternion()
		for k in anim.track_get_key_count(ti):
			anim.track_set_key_value(ti, k, rest.slerp(anim.track_get_key_value(ti, k) as Quaternion, keep))


## ---- Motions made here, by hand, for the moments of a duel that happen every turn (0.63.1).
## Recorded motions are fitted to each body as well as they can be; these are BUILT on each body, so
## they are exact on any proportions: the hand goes to the Duel Disk on that body's own forearm, the
## card comes up beside that body's own face. Each key says where the two hands are, in the body's
## own measures: x in shoulders (1 = at its own shoulder, -1 = at the other one, past that in arm
## lengths), y from the line of the shoulders (1 = the top of the head, -1 = the hips), z forward in
## arm lengths. "lo"/"ro" turn a hand: [where the fingers point, where the palm faces], as (out to its
## own side, up, forward). "twist" turns the chest toward the right hand, "lean" bows it, "look" turns
## the head toward the right hand and down. null = the arm hangs as it does standing.
const DISK := Vector3(-0.35, -0.50, 0.55)         # the left forearm across the body, Duel Disk up
const ON_DISK := Vector3(-0.35, -0.40, 0.56)      # the right hand on the deck of that disk
const PALM_DOWN := [Vector3(-1, 0, 0.25), Vector3(0, -1, 0)]
const MADE_MOTIONS := {
	"g_draw": {"len": 2.4, "keys": [
		{"t": 0.0},
		{"t": 0.30, "l": DISK, "r": Vector3(0.2, -0.55, 0.45), "look": Vector2(-8, 12)},
		{"t": 0.55, "l": DISK, "r": ON_DISK, "ro": PALM_DOWN, "lean": 4, "look": Vector2(-10, 16)},
		{"t": 0.95, "l": DISK, "r": Vector3(1.55, 0.50, 0.30), "ro": [Vector3(0, 1, 0), Vector3(-0.85, 0, -0.4)], "twist": 8, "look": Vector2(20, 0)},
		{"t": 1.55, "l": DISK, "r": Vector3(1.55, 0.52, 0.30), "ro": [Vector3(0, 1, 0), Vector3(-0.85, 0, -0.4)], "twist": 8, "look": Vector2(20, 0)},
		{"t": 1.95, "l": Vector3(0.3, -0.75, 0.35), "r": Vector3(0.55, -0.50, 0.48), "look": Vector2(0, 0)},
		{"t": 2.4}]},
	"g_play": {"len": 2.05, "keys": [
		{"t": 0.0},
		{"t": 0.30, "l": DISK, "r": Vector3(1.45, 0.78, 0.15), "ro": [Vector3(0, 1, 0), Vector3(0, 0, 1)], "twist": 10},
		{"t": 0.50, "l": DISK, "r": Vector3(1.45, 0.80, 0.13), "ro": [Vector3(0, 1, 0), Vector3(0, 0, 1)], "twist": 11},
		{"t": 0.72, "l": DISK, "r": ON_DISK, "ro": PALM_DOWN, "twist": -12, "lean": 7, "look": Vector2(-8, 10)},
		{"t": 1.05, "l": DISK, "r": ON_DISK, "ro": PALM_DOWN, "twist": -12, "lean": 7, "look": Vector2(-8, 10)},
		{"t": 1.35, "l": DISK, "r": Vector3(0.7, -0.15, 0.85), "ro": [Vector3(0.2, 0, 1), Vector3(0, -1, 0)], "twist": -4},
		{"t": 1.65, "l": DISK, "r": Vector3(0.7, -0.15, 0.86), "ro": [Vector3(0.2, 0, 1), Vector3(0, -1, 0)], "twist": -4},
		{"t": 2.05}]},
	"g_cset": {"len": 1.9, "keys": [
		{"t": 0.0},
		{"t": 0.35, "l": DISK, "r": Vector3(0.5, -0.35, 0.50), "ro": PALM_DOWN, "look": Vector2(-6, 12)},
		{"t": 0.75, "l": DISK, "r": Vector3(-0.3, -0.45, 0.58), "ro": PALM_DOWN, "lean": 5, "look": Vector2(-10, 16)},
		{"t": 1.15, "l": DISK, "r": Vector3(-0.3, -0.45, 0.58), "ro": PALM_DOWN, "lean": 5, "look": Vector2(-10, 16)},
		{"t": 1.50, "l": Vector3(0.3, -0.75, 0.35), "r": Vector3(0.6, -0.6, 0.4)},
		{"t": 1.9}]},
	"g_cspell": {"len": 2.1, "keys": [
		{"t": 0.0},
		{"t": 0.35, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(1.35, 1.05, 0.2), "ro": [Vector3(0, 1, 0), Vector3(0, 0, 1)], "twist": 8},
		{"t": 0.60, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(1.35, 1.07, 0.2), "ro": [Vector3(0, 1, 0), Vector3(0, 0, 1)], "twist": 9},
		{"t": 0.85, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(1.05, -0.30, 0.85), "ro": [Vector3(0, 0.45, 1), Vector3(-1, 0, 0)], "twist": -10, "lean": 4},
		{"t": 1.35, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(1.05, -0.29, 0.86), "ro": [Vector3(0, 0.45, 1), Vector3(-1, 0, 0)], "twist": -10, "lean": 4},
		{"t": 2.1}]},
	"g_ctrap": {"len": 1.7, "keys": [
		{"t": 0.0},
		{"t": 0.28, "r": Vector3(-0.7, -0.55, 0.45), "ro": PALM_DOWN, "twist": -14, "lean": 4},
		{"t": 0.58, "r": Vector3(1.95, 0.05, 0.30), "ro": [Vector3(1, 0, 0.2), Vector3(0, 0, 1)], "twist": 16},
		{"t": 1.10, "r": Vector3(1.95, 0.06, 0.30), "ro": [Vector3(1, 0, 0.2), Vector3(0, 0, 1)], "twist": 16},
		{"t": 1.7}]},
	# The ace arrives, the hard way: the arm goes up, then comes down and points it onto the field.
	# (The recorded one dropped to the floor to slam it, and left the picture.)
	"g_ace_slam": {"len": 2.6, "keys": [
		{"t": 0.0},
		{"t": 0.40, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(1.3, 1.25, 0.1), "ro": [Vector3(0, 1, 0), Vector3(0, 0, 1)], "twist": 12, "look": Vector2(10, -8)},
		{"t": 0.65, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(1.3, 1.28, 0.08), "ro": [Vector3(0, 1, 0), Vector3(0, 0, 1)], "twist": 13, "look": Vector2(10, -8)},
		{"t": 0.90, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(0.75, -0.38, 0.9), "ro": [Vector3(0.1, -0.2, 1), Vector3(0, -1, 0)], "twist": -14, "lean": 11, "look": Vector2(-4, 8)},
		{"t": 1.70, "l": Vector3(1.05, -0.9, 0.1), "r": Vector3(0.75, -0.37, 0.91), "ro": [Vector3(0.1, -0.2, 1), Vector3(0, -1, 0)], "twist": -14, "lean": 11, "look": Vector2(-4, 8)},
		{"t": 2.6}]},
	# Thinking: the Duel Disk up, the other hand moving over the cards, eyes on them and then on the
	# field. (The recorded one bowed the head into a hand and hid the face.)
	"g_think": {"len": 4.0, "keys": [
		{"t": 0.0},
		{"t": 0.50, "l": DISK, "r": Vector3(0.15, -0.36, 0.50), "ro": PALM_DOWN, "look": Vector2(-8, 13)},
		{"t": 1.40, "l": DISK, "r": Vector3(-0.50, -0.37, 0.56), "ro": PALM_DOWN, "twist": -4, "look": Vector2(-14, 15)},
		{"t": 2.30, "l": DISK, "r": Vector3(0.25, -0.34, 0.50), "ro": PALM_DOWN, "twist": 3, "look": Vector2(4, -2)},
		{"t": 3.20, "l": DISK, "r": Vector3(-0.20, -0.37, 0.55), "ro": PALM_DOWN, "look": Vector2(-10, 14)},
		{"t": 4.0}]},
	# The stances a duelist HOLDS between moves (0.64.2). A pose that is held for most of a duel must
	# look right on every body and in every outfit, so these keep the arms hanging as they do in the
	# calm stand (no key for a hand = it hangs) and say who the duelist is with the chest and the
	# head only. What they replace put the hands in front of the body: the fired-up one read as
	# "carrying something", and arms crossed over a Duel Disk sank into the chest on some bodies.
	# Fired up: never still, turning from side to side, leaning in a little.
	"g_st_wild": {"len": 2.2, "loop": true, "keys": [
		{"t": 0.0, "twist": 6, "lean": 3, "look": Vector2(-4, 0)},
		{"t": 0.55, "twist": 0, "lean": 4.5},
		{"t": 1.1, "twist": -6, "lean": 3, "look": Vector2(4, 0)},
		{"t": 1.65, "twist": 0, "lean": 4.5},
		{"t": 2.2, "twist": 6, "lean": 3, "look": Vector2(-4, 0)}]},
	# Dark: leaning in, chin down, watching from under the brow, slow.
	"g_st_dark": {"len": 7.0, "loop": true, "keys": [
		{"t": 0.0, "twist": -3, "lean": 5, "look": Vector2(-4, 7)},
		{"t": 3.5, "twist": 2, "lean": 6, "look": Vector2(4, 8)},
		{"t": 7.0, "twist": -3, "lean": 5, "look": Vector2(-4, 7)}]},
	# Cool: upright and almost still, a slow look from one side of the field to the other.
	"g_st_cool": {"len": 8.0, "loop": true, "keys": [
		{"t": 0.0, "twist": -2, "lean": 0, "look": Vector2(-6, 0)},
		{"t": 4.0, "twist": 2, "lean": 0.5, "look": Vector2(6, 1)},
		{"t": 8.0, "twist": -2, "lean": 0, "look": Vector2(-6, 0)}]},
	# Sure of themselves: chest out, leaning back a touch, chin up, in no hurry.
	"g_st_cocky": {"len": 6.0, "loop": true, "keys": [
		{"t": 0.0, "twist": 4, "lean": -3.5, "look": Vector2(6, -6)},
		{"t": 3.0, "twist": 1, "lean": -4.5, "look": Vector2(-5, -5)},
		{"t": 6.0, "twist": 4, "lean": -3.5, "look": Vector2(6, -6)}]},
}


func _body_point(fr: Dictionary, ax: Basis, mid: Vector3, sgn: float, v: Vector3) -> Vector3:
	var w := float(fr["w"])
	var arm := float(fr["len"])
	var x := w * v.x if absf(v.x) <= 1.0 else signf(v.x) * (w + (absf(v.x) - 1.0) * arm)
	var y := 0.0
	if v.y >= 0.0:
		y = float(fr["up"]) * v.y if v.y <= 1.0 else float(fr["up"]) + (v.y - 1.0) * arm
	else:
		y = float(fr["down"]) * v.y if v.y >= -1.0 else -float(fr["down"]) + (v.y + 1.0) * arm
	return mid + ax * Vector3(x * sgn, y, v.z * arm)


## Build one of MADE_MOTIONS on this model's own skeleton. null when the body lacks the bones.
func _made_motion(model: Node, nm: String, skel: Skeleton3D, skel_path: String) -> Animation:
	var fr := _arm_frame(skel)
	if fr.is_empty() or rest_idle(model) == "":
		return null
	var ap := anim_player(model)
	var rest_anim := ap.get_animation("g_rest")
	var spec: Dictionary = MADE_MOTIONS[nm]
	var keys: Array = spec["keys"]
	var body := _body_stats(skel, fr)
	var n := skel.get_bone_count()
	# How the body stands: the first frame of its own calm stand.
	var base: Array = []
	for i in n:
		var loc := skel.get_bone_rest(i)
		var rt := rest_anim.find_track(NodePath("%s:%s" % [skel_path, skel.get_bone_name(i)]), Animation.TYPE_ROTATION_3D)
		if rt >= 0 and rest_anim.track_get_key_count(rt) > 0:
			loc.basis = Basis(rest_anim.track_get_key_value(rt, 0) as Quaternion)
		var pt := rest_anim.find_track(NodePath("%s:%s" % [skel_path, skel.get_bone_name(i)]), Animation.TYPE_POSITION_3D)
		if pt >= 0 and rest_anim.track_get_key_count(pt) > 0:
			loc.origin = rest_anim.track_get_key_value(pt, 0)
		var par := skel.get_bone_parent(i)
		base.append((base[par] as Transform3D) * loc if par >= 0 else loc)
	var chest := int(fr["chest"])
	var upper := {chest: true}      # the chest and everything that hangs from it
	for i in n:
		if skel.get_bone_parent(i) >= 0 and upper.has(skel.get_bone_parent(i)):
			upper[i] = true
	var head := int(fr["head"])
	var ax0: Basis = fr["axes"]
	var out := Animation.new()
	out.length = float(spec["len"])
	out.loop_mode = Animation.LOOP_LINEAR if bool(spec.get("loop", false)) else Animation.LOOP_NONE
	var tracks: Array = []
	for i in n:
		var ti := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(ti, NodePath("%s:%s" % [skel_path, skel.get_bone_name(i)]))
		tracks.append(ti)
	var hips := int(fr["hips"])
	var hip_t := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(hip_t, NodePath("%s:%s" % [skel_path, skel.get_bone_name(hips)]))
	var hip_local := skel.get_bone_rest(hips).origin
	var hpt := rest_anim.find_track(NodePath("%s:%s" % [skel_path, skel.get_bone_name(hips)]), Animation.TYPE_POSITION_3D)
	if hpt >= 0 and rest_anim.track_get_key_count(hpt) > 0:
		hip_local = rest_anim.track_get_key_value(hpt, 0)
	var frames := int(ceil(out.length * 30.0)) + 1
	for f in frames:
		var t := minf(float(f) / 30.0, out.length)
		var k1 := 0
		while k1 < keys.size() - 1 and float(keys[k1]["t"]) < t:
			k1 += 1
		var k0 := maxi(k1 - 1, 0)
		var span := float(keys[k1]["t"]) - float(keys[k0]["t"])
		var u := smoothstep(0.0, 1.0, (t - float(keys[k0]["t"])) / span) if span > 0.0001 else 1.0
		var a: Dictionary = keys[k0]
		var b: Dictionary = keys[k1]
		var twist := deg_to_rad(lerpf(float(a.get("twist", 0.0)), float(b.get("twist", 0.0)), u))
		var lean := deg_to_rad(lerpf(float(a.get("lean", 0.0)), float(b.get("lean", 0.0)), u))
		var look: Vector2 = (a.get("look", Vector2.ZERO) as Vector2).lerp(b.get("look", Vector2.ZERO) as Vector2, u)
		var g: Array = base.duplicate()
		# The chest turns (toward the right hand is "twist") and bows; the head keeps facing the field.
		var turn := Basis(ax0.y, -twist) * Basis(ax0.x, lean)
		var pivot: Vector3 = (base[chest] as Transform3D).origin
		for i in n:
			if upper.has(i):
				var bt: Transform3D = base[i]
				g[i] = Transform3D(turn * bt.basis, pivot + turn * (bt.origin - pivot))
		var ht: Transform3D = g[head]
		g[head] = Transform3D(Basis(ax0.y, -deg_to_rad(look.x)) * Basis(ax0.x, deg_to_rad(look.y)) * (base[head] as Transform3D).basis, ht.origin)
		for c in skel.get_bone_children(head):
			var rel: Transform3D = (base[head] as Transform3D).affine_inverse() * (base[c] as Transform3D)
			g[c] = (g[head] as Transform3D) * rel
		var ax := turn * ax0
		var mid: Vector3 = ((g[int(fr["arm"][0])] as Transform3D).origin + (g[int(fr["arm"][1])] as Transform3D).origin) * 0.5
		for side in 2:
			var sgn := 1.0 if side == 0 else -1.0
			var kk := "l" if side == 0 else "r"
			var ia := int(fr["arm"][side])
			var ie := int(fr["fore"][side])
			var ih := int(fr["hand"][side])
			var s0: Vector3 = (g[ia] as Transform3D).origin
			var e0: Vector3 = (g[ie] as Transform3D).origin
			var h0: Vector3 = (g[ih] as Transform3D).origin
			var pa: Vector3 = _body_point(fr, ax, mid, sgn, a[kk]) if a.get(kk) != null else h0
			var pb: Vector3 = _body_point(fr, ax, mid, sgn, b[kk]) if b.get(kk) != null else h0
			var target := pa.lerp(pb, u)
			# (a hand that travels far swings a little out and forward on the way: an arc, not a rail)
			target += (ax.z * 0.5 + ax.x * sgn * 0.5 + ax.y * 0.3) * (pa.distance_to(pb) * 0.12 * sin(u * PI))
			# ...and never in front of the face, whatever this body's proportions are.
			if a.get(kk) != null or b.get(kk) != null:
				var h_turn: Basis = (g[head] as Transform3D).basis * skel.get_bone_global_rest(head).basis.orthonormalized().inverse()
				var face: Vector3 = (g[head] as Transform3D).origin + h_turn * ((body["face"] as Vector3) - skel.get_bone_global_rest(head).origin)
				var head_c: Vector3 = (g[head] as Transform3D).origin + h_turn * ((body["head_c"] as Vector3) - skel.get_bone_global_rest(head).origin)
				var reach := (target - s0).normalized()
				var fingers := reach
				var kn: Dictionary = a if u < 0.5 else b
				if kn.get("lo" if side == 0 else "ro") != null:
					var fd: Vector3 = kn["lo" if side == 0 else "ro"][0]
					fingers = (ax * Vector3(fd.x * sgn, fd.y, fd.z)).normalized()
				target = _off_face(target, sgn, fingers, reach, float(body["hand"][side]), float(fr["b"][side]), face, (h_turn * ax0.z).normalized(), (h_turn * ax0.y).normalized(),
					head_c, body, float(fr["len"]), (ax0.x * 0.42 - ax0.y * 0.2 + ax0.z * 1.75).normalized(), ax)
				var was := target
				target = _off_body(target, s0, -ax.y * 0.7 + ax.x * sgn * 0.55 - ax.z * 0.45, float(fr["a"][side]), float(fr["b"][side]), side, fingers, float(body["hand"][side]), body, ax, mid, float(fr["w"]), float(fr["len"]))
				if target != was:
					target = _off_face(target, sgn, fingers, reach, float(body["hand"][side]), float(fr["b"][side]), face, (h_turn * ax0.z).normalized(), (h_turn * ax0.y).normalized(),
						head_c, body, float(fr["len"]), (ax0.x * 0.42 - ax0.y * 0.2 + ax0.z * 1.75).normalized(), ax)
			var la := float(fr["a"][side])
			var lb := float(fr["b"][side])
			var to := target - s0
			var dist := clampf(to.length(), absf(la - lb) + (la + lb) * 0.04, (la + lb) * 0.995)
			var dirn := to.normalized() if to.length() > 0.00001 else (h0 - s0).normalized()
			var pole: Vector3 = -ax.y * 0.7 + ax.x * sgn * 0.55 - ax.z * 0.45
			pole = (pole - dirn * pole.dot(dirn)).normalized()
			var x := (la * la - lb * lb + dist * dist) / (2.0 * dist)
			var elbow := s0 + dirn * x + pole * sqrt(maxf(la * la - x * x, 0.0))
			var hand := s0 + dirn * dist
			var u0 := (e0 - s0).normalized()
			var f0 := (h0 - e0).normalized()
			var u1 := (elbow - s0).normalized()
			var f1 := (hand - elbow).normalized()
			var gu: Basis = (g[ia] as Transform3D).basis
			var gf: Basis = (g[ie] as Transform3D).basis
			var gh: Basis = (g[ih] as Transform3D).basis
			if u0.dot(u1) < 0.999999 and u0.dot(u1) > -0.9999:
				gu = Basis(Quaternion(u0, u1)) * gu
			var line := Basis.IDENTITY
			if f0.dot(f1) < 0.999999 and f0.dot(f1) > -0.9999:
				line = Basis(Quaternion(f0, f1))
			gf = line * gf
			# The hand: in line with the forearm, or turned the way the key says.
			var ok := "lo" if side == 0 else "ro"
			var qa := (line * gh).orthonormalized().get_rotation_quaternion()
			var qb := qa
			for which in 2:
				var kd: Dictionary = a if which == 0 else b
				if kd.get(ok) != null:
					var d0: Vector3 = body["hand_dir"][side]
					var n0 := (-ax0.y - d0 * (-ax0.y).dot(d0)).normalized()
					var want_d: Vector3 = (kd[ok][0] as Vector3)
					var want_n: Vector3 = (kd[ok][1] as Vector3)
					var d1 := (ax * Vector3(want_d.x * sgn, want_d.y, want_d.z)).normalized()
					var n1 := ax * Vector3(want_n.x * sgn, want_n.y, want_n.z)
					n1 = (n1 - d1 * n1.dot(d1)).normalized()
					var q := (Basis(d1, n1, d1.cross(n1)) * Basis(d0, n0, d0.cross(n0)).inverse() * skel.get_bone_global_rest(ih).basis.orthonormalized()).orthonormalized().get_rotation_quaternion()
					if which == 0:
						qa = q
					else:
						qb = q
			gh = Basis(qa.slerp(qb, u))
			g[ia] = Transform3D(gu, s0)
			g[ie] = Transform3D(gf, elbow)
			g[ih] = Transform3D(gh, hand)
		for i in n:
			var par := skel.get_bone_parent(i)
			var lbs: Basis = ((g[par] as Transform3D).basis.inverse() * (g[i] as Transform3D).basis) if par >= 0 else (g[i] as Transform3D).basis
			out.rotation_track_insert_key(tracks[i], t, lbs.orthonormalized().get_rotation_quaternion())
		out.position_track_insert_key(hip_t, t, hip_local)
	return out


var made_motions := true      # (off: the recorded clips of the same names play instead)

func _made_for(model: Node, nm: String, skel: Skeleton3D) -> String:
	if rest_idle(model) == "":
		return ""
	var ap := anim_player(model)
	var root := ap.get_node_or_null(ap.root_node) if ap != null else null
	if root == null:
		return ""
	var skel_path := str(root.get_path_to(skel))
	var ck := "%s|%s|%s" % [str(model.get_meta("file", "")), skel_path, nm]
	var anim: Animation = _gest_cache.get(ck) if model.has_meta("file") else null
	if anim == null:
		anim = _fit_load(ck, model)
		if anim != null:
			_gest_cache[ck] = anim
	if anim == null:
		anim = _made_motion(model, nm, skel, skel_path)
		if anim == null:
			return ""
		if model.has_meta("file"):
			_gest_cache[ck] = anim
			_fit_save(ck, model, anim)
	ap.get_animation_library(ap.get_animation_library_list()[0]).add_animation(nm, anim)
	return nm


## Off for a look at the old way (bones turned the same amount and nothing else).
var arms_by_position := true


## A domino mask across the eyes (the Midnight Circle): a dark band curved around the face with two
## pale lenses, hung on the head bone so it turns and nods with the head. Its size and place come
## from the body's own measurements. Nothing on a body without the usual bones.
func add_mask(model: Node, color := Color(0.045, 0.045, 0.06)) -> void:
	var sk := _first_skeleton(model)
	if sk == null or sk.has_node("Mask"):
		return
	var fr := _arm_frame(sk)
	if fr.is_empty():
		return
	var st := _body_stats(sk, fr)
	var ax: Basis = fr["axes"]
	var head := sk.get_bone_global_rest(int(fr["head"]))
	var tall: float = float(st["face_r"]) / 0.28          # chin to the top of the head
	var eye: Vector3 = (st["face"] as Vector3) + ax.y * tall * MASK_UP
	var rad := tall * MASK_R
	var half := tall * MASK_H
	# The band is an arc around an upright line behind the face; its front sits just off the skin.
	var centre := eye + ax.z * (float(st["front"]) - tall * MASK_IN - rad)
	var stl := SurfaceTool.new()
	stl.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 14
	for i in steps:
		var a0 := deg_to_rad(-66.0 + 132.0 * float(i) / steps)
		var a1 := deg_to_rad(-66.0 + 132.0 * float(i + 1) / steps)
		# (narrower towards the temples, like a mask cut from one piece)
		var h0 := half * (1.0 - 0.45 * absf(a0) / deg_to_rad(66.0))
		var h1 := half * (1.0 - 0.45 * absf(a1) / deg_to_rad(66.0))
		var p0 := Vector3(sin(a0) * rad, 0, cos(a0) * rad)
		var p1 := Vector3(sin(a1) * rad, 0, cos(a1) * rad)
		for tri in [[p0 + Vector3(0, h0, 0), p1 + Vector3(0, h1, 0), p1 - Vector3(0, h1, 0)], [p0 + Vector3(0, h0, 0), p1 - Vector3(0, h1, 0), p0 - Vector3(0, h0, 0)]]:
			for p in tri:
				stl.set_normal(Vector3((p as Vector3).x, 0, (p as Vector3).z).normalized())
				stl.add_vertex(p)
	var band := MeshInstance3D.new()
	band.mesh = stl.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	band.material_override = m
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Two pale lenses where the eyes are.
	var lens_m := StandardMaterial3D.new()
	lens_m.albedo_color = Color(0.92, 0.94, 1.0)
	lens_m.emission_enabled = true
	lens_m.emission = Color(0.8, 0.86, 1.0)
	lens_m.emission_energy_multiplier = 0.55
	lens_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1.0, 1.0]:
		var ang: float = deg_to_rad(21.0) * float(side)
		var lens := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(rad * 0.3, half * 0.62)
		lens.mesh = q
		lens.material_override = lens_m
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lens.position = Vector3(sin(ang) * (rad + 0.0015), 0, cos(ang) * (rad + 0.0015))
		lens.rotation.y = ang
		band.add_child(lens)
	var att := BoneAttachment3D.new()
	att.name = "Mask"
	sk.add_child(att)
	att.bone_name = sk.get_bone_name(int(fr["head"]))
	att.add_child(band)
	band.transform = head.affine_inverse() * Transform3D(ax, centre)


## The mask's measurements, in head heights (chin to crown): how far above the middle of the face
## the eyes are, the radius of the band, half its height, and how far it sits inside the face's
## foremost point (the nose, or a fringe of hair).
const MASK_UP := 0.13
const MASK_R := 0.36
const MASK_H := 0.085
const MASK_IN := 0.05


## What a body measures for the arm pass: the bones, the line of the shoulders, how long the arms
## are, how far the top of the head and the hips are from the shoulders. {} when it is not a body
## with the usual arm bones.
func _arm_frame(sk: Skeleton3D) -> Dictionary:
	var d := {"arm": [sk.find_bone("LeftArm"), sk.find_bone("RightArm")], "fore": [sk.find_bone("LeftForeArm"), sk.find_bone("RightForeArm")],
		"hand": [sk.find_bone("LeftHand"), sk.find_bone("RightHand")], "head": sk.find_bone("Head"), "hips": sk.find_bone("Hips")}
	for k in ["arm", "fore", "hand"]:
		if int(d[k][0]) < 0 or int(d[k][1]) < 0:
			return {}
	if int(d["head"]) < 0 or int(d["hips"]) < 0:
		return {}
	var la := sk.get_bone_global_rest(int(d["arm"][0])).origin
	var ra := sk.get_bone_global_rest(int(d["arm"][1])).origin
	var chest := sk.get_bone_parent(int(d["arm"][0]))
	if chest >= 0 and sk.get_bone_name(chest).to_lower().contains("shoulder"):
		chest = sk.get_bone_parent(chest)
	if chest < 0:
		return {}
	d["chest"] = chest
	var mid := (la + ra) * 0.5
	var hips := sk.get_bone_global_rest(int(d["hips"])).origin
	var lat := (la - ra).normalized()
	var up := (mid - hips)
	up = (up - lat * up.dot(lat)).normalized()
	var fwd := lat.cross(up).normalized()
	d["axes"] = Basis(lat, up, fwd)
	d["mid"] = mid
	d["w"] = maxf((la - ra).length() * 0.5, 0.0001)
	d["a"] = [(sk.get_bone_global_rest(int(d["fore"][0])).origin - la).length(), (sk.get_bone_global_rest(int(d["fore"][1])).origin - ra).length()]
	d["b"] = [(sk.get_bone_global_rest(int(d["hand"][0])).origin - sk.get_bone_global_rest(int(d["fore"][0])).origin).length(),
		(sk.get_bone_global_rest(int(d["hand"][1])).origin - sk.get_bone_global_rest(int(d["fore"][1])).origin).length()]
	d["len"] = maxf(float(d["a"][0]) + float(d["b"][0]), 0.0001)
	var head := sk.get_bone_global_rest(int(d["head"])).origin
	var he := sk.find_bone("head_end")
	var top := sk.get_bone_global_rest(he).origin if he >= 0 else head + up * float(d["len"]) * 0.6
	d["up"] = maxf((top - mid).dot(up), float(d["len"]) * 0.3)
	d["down"] = maxf((mid - hips).dot(up), float(d["len"]) * 0.3)
	return d


## What the arm pass needs to know about the body's surface (skeleton space, rest pose): how long
## each hand is and where the face is. Read off the skin once per skeleton; a body with no skin to
## read gets sensible guesses from its bones.
func _body_stats(skel: Skeleton3D, fr: Dictionary) -> Dictionary:
	if skel.has_meta("body_stats"):
		return skel.get_meta("body_stats")
	var ax: Basis = fr["axes"]
	var head := skel.get_bone_global_rest(int(fr["head"])).origin
	var hand_dir: Array = []
	var st := {"hand": [float(fr["b"][0]) * 0.9, float(fr["b"][1]) * 0.9]}
	for side in 2:
		hand_dir.append((skel.get_bone_global_rest(int(fr["hand"][side])).origin - skel.get_bone_global_rest(int(fr["fore"][side])).origin).normalized())
	var chin := (head - (fr["mid"] as Vector3)).dot(ax.y) - float(fr["up"]) * 0.15
	var top := float(fr["up"])
	var front := float(fr["len"]) * 0.3
	var seen := [0.0, 0.0]
	var lo := INF
	var hi := -INF
	var fz := -INF
	var bz := INF
	var hands := [int(fr["hand"][0]), int(fr["hand"][1])]
	var head_set := {int(fr["head"]): true}
	for c in skel.get_bone_children(int(fr["head"])):
		head_set[c] = true
	# The trunk (0.64.2): everything that is not an arm or the head, measured in rows from the
	# shoulders down past the hips: how far its front and its back are from the line of the
	# shoulders, and how wide it is. Clothes count (a jacket, a coat): they are what a hand would
	# sink into. See _off_body.
	var arm_set := {}
	for side in 2:
		var todo: Array = [int(fr["arm"][side])]
		while not todo.is_empty():
			var bi: int = todo.pop_back()
			arm_set[bi] = true
			for c in skel.get_bone_children(bi):
				todo.append(c)
	var neck := skel.get_bone_parent(int(fr["head"]))
	if neck >= 0 and skel.get_bone_name(neck).to_lower().contains("neck"):
		head_set[neck] = true
	var t_top := float(fr["up"]) * 0.12
	var t_step := (t_top + float(fr["down"]) * 1.55) / float(TORSO_ROWS)
	var t_core := float(fr["w"]) * 0.65
	var t_front := PackedFloat32Array()
	var t_side := PackedFloat32Array()      # (the front of the part out by the flanks)
	var t_back := PackedFloat32Array()
	var t_wide := PackedFloat32Array()
	for i in TORSO_ROWS:
		t_front.append(-INF)
		t_side.append(-INF)
		t_back.append(INF)
		t_wide.append(0.0)
	var pool: Array = skel.find_children("*", "MeshInstance3D", true, false)
	if skel.get_parent() != null:
		pool += skel.get_parent().find_children("*", "MeshInstance3D", true, false)
	var done := {}
	for n in pool:
		var mi := n as MeshInstance3D
		if done.has(mi) or mi.mesh == null or mi.skin == null:
			continue
		done[mi] = true
		var bind_bone: Array = []
		var bind_xf: Array = []
		for i in mi.skin.get_bind_count():
			var bb := mi.skin.get_bind_bone(i)
			if bb < 0 and str(mi.skin.get_bind_name(i)) != "":
				bb = skel.find_bone(mi.skin.get_bind_name(i))
			bind_bone.append(bb)
			bind_xf.append(skel.get_bone_global_rest(bb) * mi.skin.get_bind_pose(i) if bb >= 0 else Transform3D.IDENTITY)
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			if arr.size() <= Mesh.ARRAY_WEIGHTS or arr[Mesh.ARRAY_BONES] == null or arr[Mesh.ARRAY_WEIGHTS] == null:
				continue
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bs = arr[Mesh.ARRAY_BONES]
			var ws = arr[Mesh.ARRAY_WEIGHTS]
			var per := int(bs.size() / maxi(vs.size(), 1))
			if per < 1:
				continue
			for vi in vs.size():
				var best := 0
				for k in range(1, per):
					if ws[vi * per + k] > ws[vi * per + best]:
						best = k
				var bind := int(bs[vi * per + best])
				if bind < 0 or bind >= bind_bone.size():
					continue
				var bone: int = bind_bone[bind]
				if bone == hands[0] or bone == hands[1]:
					var side := 0 if bone == hands[0] else 1
					var p: Vector3 = (bind_xf[bind] as Transform3D) * vs[vi]
					seen[side] = maxf(seen[side], (p - skel.get_bone_global_rest(bone).origin).dot(hand_dir[side]))
				elif head_set.has(bone):
					var p2: Vector3 = (bind_xf[bind] as Transform3D) * vs[vi] - (fr["mid"] as Vector3)
					lo = minf(lo, p2.dot(ax.y))
					hi = maxf(hi, p2.dot(ax.y))
					fz = maxf(fz, p2.dot(ax.z))
					bz = minf(bz, p2.dot(ax.z))
				elif not arm_set.has(bone):
					var p3: Vector3 = (bind_xf[bind] as Transform3D) * vs[vi] - (fr["mid"] as Vector3)
					var row := int(floor((t_top - p3.dot(ax.y)) / t_step))
					if row >= 0 and row < TORSO_ROWS:
						var px := absf(p3.dot(ax.x))
						var pz := p3.dot(ax.z)
						if px < t_core:
							t_front[row] = maxf(t_front[row], pz)
						else:
							t_side[row] = maxf(t_side[row], pz)
						t_back[row] = minf(t_back[row], pz)
						t_wide[row] = maxf(t_wide[row], px)
	for side in 2:
		if seen[side] > float(fr["b"][side]) * 0.3:
			st["hand"][side] = seen[side]
	if hi > lo:
		chin = lo
		top = hi
		front = fz
	# The face: the lower two thirds of the head, seen from the front (heights above the shoulder line).
	var tall := maxf(top - chin, 0.0001)
	st["face"] = (fr["mid"] as Vector3) + ax.y * (chin + tall * 0.34)
	st["face"] = (st["face"] as Vector3) + ax.x * (head - (fr["mid"] as Vector3)).dot(ax.x) + ax.z * (head - (fr["mid"] as Vector3)).dot(ax.z)
	st["face_r"] = tall * 0.28
	st["front"] = front - (head - (fr["mid"] as Vector3)).dot(ax.z)      # how far the face is in front of the head joint
	st["hand_dir"] = hand_dir
	# The head as a ball (hair and all, but not the tips of the spikes) that no arm passes through.
	var deep := (fz + bz) * 0.5 if hi > lo else (head - (fr["mid"] as Vector3)).dot(ax.z)
	st["head_c"] = (fr["mid"] as Vector3) + ax.y * (chin + tall * 0.5) + ax.x * (head - (fr["mid"] as Vector3)).dot(ax.x) + ax.z * deep
	st["head_r"] = tall * 0.4
	# (a row no vertex fell in takes after its neighbours; a body with no skin to read has no trunk here)
	var any := false
	for i in TORSO_ROWS:
		if t_wide[i] > 0.0:
			any = true
	if any:
		for i in TORSO_ROWS:
			if t_front[i] == -INF:
				t_front[i] = t_side[i]
			if t_side[i] == -INF:
				t_side[i] = t_front[i]
		st["torso"] = {"top": t_top, "step": t_step, "core": t_core, "front": t_front, "side": t_side, "back": t_back, "wide": t_wide}
	skel.set_meta("body_stats", st)
	return st


const TORSO_ROWS := 12

## The trunk at one height (y from the line of the shoulders, x across): [front, back, half width],
## or [] where there is no trunk. The rows next to it count too, so nothing slips between two rows.
func _torso_row(tor: Dictionary, x: float, y: float) -> Array:
	var r := int(floor((float(tor["top"]) - y) / float(tor["step"])))
	if r < 0 or r >= TORSO_ROWS:
		return []
	var front := -INF
	var back := INF
	var wide := 0.0
	for k in range(maxi(r - 1, 0), mini(r + 2, TORSO_ROWS)):
		if float((tor["wide"] as PackedFloat32Array)[k]) <= 0.0:
			continue
		front = maxf(front, float((tor["front" if absf(x) < float(tor["core"]) else "side"] as PackedFloat32Array)[k]))
		back = minf(back, float((tor["back"] as PackedFloat32Array)[k]))
		# (how wide: this row only, so a hem that flares out does not widen the waist above it)
		if k == r:
			wide = float((tor["wide"] as PackedFloat32Array)[k])
	if front == -INF or wide <= 0.0:
		return []
	return [front, back, wide]


## No hand and no forearm inside the body (0.64.2). The wrist, the palm, the fingertips and two
## points of the forearm are tried against the trunk as it was measured on this very model (clothes
## and all); whatever is inside moves the wrist out: forward for a hand in front of the body,
## backward for one behind the back, a little out to the side for one hanging beside the hips.
## Returns where the wrist may be. `pole`: which way the elbow points.
func _off_body(want: Vector3, s: Vector3, pole: Vector3, la: float, lb: float, side: int, hdir: Vector3, hl: float, body: Dictionary, ax: Basis, mid: Vector3, w: float, arm_len: float) -> Vector3:
	var tor: Dictionary = body.get("torso", {})
	if tor.is_empty() or not body_clear:
		return want
	var inv := ax.orthonormalized().inverse()
	var axz := ax.z.normalized()
	var axx := ax.x.normalized()
	for pass_i in 4:
		var to := want - s
		var dist := clampf(to.length(), absf(la - lb) + (la + lb) * 0.04, (la + lb) * 0.995)
		var n := to.normalized() if to.length() > 0.00001 else -ax.y.normalized()
		var pl := pole - n * pole.dot(n)
		pl = pl.normalized() if pl.length() > 0.0001 else Vector3.ZERO
		var along := (la * la - lb * lb + dist * dist) / (2.0 * dist)
		var elbow := s + n * along + pl * sqrt(maxf(la * la - along * along, 0.0))
		var wrist := s + n * dist
		var push := Vector3.ZERO
		for sm in 5:
			var pt := wrist + hdir * hl * (0.5 * sm) if sm < 3 else wrist.lerp(elbow, 0.3 if sm == 3 else 0.55)
			# (the forearm is thicker than the hand, and the left one wears the Duel Disk)
			var thick := hl * 0.2 if sm < 3 else hl * (0.42 if side == 0 else 0.3)
			var gain := 1.0 if sm < 3 else (1.0 / 0.7 if sm == 3 else 1.0 / 0.45)
			var q: Vector3 = inv * (pt - mid)
			var row := _torso_row(tor, q.x, q.y)
			if row.is_empty():
				continue
			var front := float(row[0])
			var back := float(row[1])
			var wide := float(row[2])
			if absf(q.x) >= wide or q.z >= front + thick or q.z <= back - thick:
				continue
			var pv := Vector3.ZERO
			if absf(q.x) > 0.85 * w and q.z < arm_len * 0.25 and q.z > back:
				# Hanging beside the body: out to the side, and only when a little is enough (an arm
				# is not held away from a wide coat: it hangs in it, as it always has).
				var dx := wide + thick * 0.4 - absf(q.x)
				if sm >= 3 or dx > 0.22 * w:
					continue
				pv = axx * signf(q.x) * dx
			elif q.z < (front + back) * 0.5:
				if sm >= 3:
					continue
				pv = -axz * (q.z - (back - thick))      # (behind the back: out the back)
			else:
				pv = axz * minf((front + thick - q.z) * gain, arm_len * 0.45)
			if pv.length() > push.length():
				push = pv
		if push.length() < 0.0005:
			break
		want += push
	return want


var body_clear := true      # (off: for a look at how it was before)


func _stretch(v: float, zone_d: float, zone_t: float, k_out: float) -> float:
	# (inside the zone the body's own measure counts; past it, the length of the arm)
	var a := absf(v)
	var r := a * (zone_t / zone_d) if a <= zone_d else zone_t + (a - zone_d) * k_out
	return r * signf(v)


## Where both hands should be at this moment, and everything the solve needs: one entry per side.
func _arm_wants(dskel: Skeleton3D, skel: Skeleton3D, da: Dictionary, ta: Dictionary, body: Dictionary, dg: Array, tg: Array, tp: Array, t: float) -> Array:
	var d_turn := (dg[int(da["chest"])] as Transform3D).basis.orthonormalized() * dskel.get_bone_global_rest(int(da["chest"])).basis.orthonormalized().inverse()
	var t_turn := (tg[int(ta["chest"])] as Basis) * skel.get_bone_global_rest(int(ta["chest"])).basis.orthonormalized().inverse()
	var d_ax := d_turn * (da["axes"] as Basis)
	var t_ax := t_turn * (ta["axes"] as Basis)
	var d_mid := ((dg[int(da["arm"][0])] as Transform3D).origin + (dg[int(da["arm"][1])] as Transform3D).origin) * 0.5
	var t_mid := ((tp[int(ta["arm"][0])] as Vector3) + (tp[int(ta["arm"][1])] as Vector3)) * 0.5
	var k_len := float(ta["len"]) / float(da["len"])
	var k_w := float(ta["w"]) / float(da["w"])
	# The face, now: a little in front of the head joint, turned with the head.
	var h_turn := (tg[int(ta["head"])] as Basis) * skel.get_bone_global_rest(int(ta["head"])).basis.orthonormalized().inverse()
	var face: Vector3 = (tp[int(ta["head"])] as Vector3) + h_turn * ((body["face"] as Vector3) - skel.get_bone_global_rest(int(ta["head"])).origin)
	var f_fwd := (h_turn * (ta["axes"] as Basis).z).normalized()
	var f_up := (h_turn * (ta["axes"] as Basis).y).normalized()
	var res: Array = []
	for side in 2:
		var sgn := 1.0 if side == 0 else -1.0
		var ds := (dg[int(da["arm"][side])] as Transform3D).origin
		var dh := (dg[int(da["hand"][side])] as Transform3D).origin
		var q := d_ax.inverse() * (dh - d_mid)
		var x := _stretch(q.x * sgn, float(da["w"]), float(ta["w"]), k_len) * sgn
		var y := _stretch(q.y, float(da["up"]) if q.y >= 0.0 else float(da["down"]), float(ta["up"]) if q.y >= 0.0 else float(ta["down"]), k_len)
		var z := _stretch(q.z, float(da["len"]) * 0.5, float(da["len"]) * 0.5 * k_w, k_len)
		var want := t_mid + t_ax * Vector3(x, y, z)
		var s: Vector3 = tp[int(ta["arm"][side])]
		var e: Vector3 = tp[int(ta["fore"][side])]
		var h: Vector3 = tp[int(ta["hand"][side])]
		# A straight arm keeps its direction (a pointing finger must point where it pointed).
		var ext := (dh - ds).length() / (float(da["a"][side]) + float(da["b"][side]))
		var keep := smoothstep(0.82, 0.97, ext)
		want = want.lerp(h, keep)
		# No hand in front of the face. The whole hand (wrist, palm, fingertips) and the forearm stay
		# out of: a cone that opens forward from the face; the same cone opened toward the corner
		# camera (which stands in front of the duelist, a little to their left); and the head itself.
		var hand_turn := (tg[int(ta["hand"][side])] as Basis) * skel.get_bone_global_rest(int(ta["hand"][side])).basis.orthonormalized().inverse()
		var hdir := (hand_turn * (body["hand_dir"][side] as Vector3)).normalized()
		var hl := float(body["hand"][side])
		var fdir := (h - e).normalized()
		var r_ax: Basis = ta["axes"]
		var cam_dir := (r_ax.x * 0.42 - r_ax.y * 0.2 + r_ax.z * 1.75).normalized()
		var head_c: Vector3 = (tp[int(ta["head"])] as Vector3) + h_turn * ((body["head_c"] as Vector3) - skel.get_bone_global_rest(int(ta["head"])).origin)
		want = _off_face(want, sgn, hdir, fdir, hl, float(ta["b"][side]), face, f_fwd, f_up, head_c, body, float(ta["len"]), cam_dir, t_ax)
		# ...and no hand or forearm inside the body. (Not while the chest is bent right over, a bow or a
		# kneel: the trunk was measured standing.)
		if t_ax.y.normalized().dot(r_ax.y.normalized()) > 0.9:
			var e_out := e - s
			if e_out.length() < 0.0001:
				e_out = -t_ax.y + t_ax.x * sgn * 0.5
			var was := want
			want = _off_body(want, s, e_out, float(ta["a"][side]), float(ta["b"][side]), side, hdir, hl, body, t_ax, t_mid, float(ta["w"]), float(ta["len"]))
			if want != was:      # (out of the body must not mean into the face: the face has the last word)
				want = _off_face(want, sgn, hdir, fdir, hl, float(ta["b"][side]), face, f_fwd, f_up, head_c, body, float(ta["len"]), cam_dir, t_ax)
		res.append({"t": t, "s": s, "e": e, "h": h, "want": want, "pg": tg[skel.get_bone_parent(int(ta["arm"][side]))] if skel.get_bone_parent(int(ta["arm"][side])) >= 0 else Basis.IDENTITY,
			"gu": tg[int(ta["arm"][side])], "gf": tg[int(ta["fore"][side])], "gh": tg[int(ta["hand"][side])], "out": t_ax.x * sgn, "down": -t_ax.y})
	return res


## The whole hand (wrist, palm, fingertips) and the forearm, pushed out of the face and the head: see
## _arm_wants. Returns where the wrist may be.
func _off_face(want: Vector3, sgn: float, hdir: Vector3, fdir: Vector3, hl: float, fore_len: float, face: Vector3, f_fwd: Vector3, f_up: Vector3, head_c: Vector3, body: Dictionary, arm_len: float, cam_dir: Vector3, t_ax: Basis) -> Vector3:
	for pass_i in 4:
		var push := Vector3.ZERO
		for sm in 5:
			var pt := want + hdir * hl * (0.5 * sm) if sm < 3 else want - fdir * fore_len * (0.4 if sm == 3 else 0.8)
			var thick := hl * 0.38 if sm < 3 else hl * 0.22
			for axis in [f_fwd, cam_dir]:
				var dd := pt - face
				var al := dd.dot(axis)
				if al < -float(body["face_r"]) * 0.4 or al > arm_len * 1.8:
					continue
				var rad: Vector3 = dd - axis * al
				var need := float(body["face_r"]) + thick + 0.3 * maxf(al, 0.0)
				if rad.length() < need:
					# Which way out: a hand held up (a card shown, a salute, a hand to the chin) goes out
					# to its own side and stays up, beside the face; a hand lower down goes down past
					# the chin. Never up over the eyes.
					var side_dir: Vector3 = t_ax.x * sgn
					side_dir = (side_dir - axis * side_dir.dot(axis)).normalized()
					var down_dir: Vector3 = (-f_up - axis * (-f_up).dot(axis)).normalized()
					var dirn := side_dir
					if rad.dot(f_up) < -float(body["face_r"]) * 0.5:
						dirn = (down_dir + side_dir * 0.45).normalized()
					elif rad.dot(side_dir) < -need * 0.6:
						dirn = (down_dir * 0.8 - side_dir * 0.6).normalized()      # (reached right across: under the chin)
					var along := rad.dot(dirn)
					var pv := dirn * (-along + sqrt(maxf(along * along + need * need - rad.length_squared(), 0.0)))
					if pv.length() > push.length():
						push = pv
			var hd := pt - head_c
			var hneed := float(body["head_r"]) + thick
			if hd.length() < hneed:
				var out_dir := hd.normalized() if hd.length() > hneed * 0.1 else (t_ax.x * sgn).normalized()
				var pv2 := out_dir * (hneed - hd.length())
				if pv2.length() > push.length():
					push = pv2
		if push == Vector3.ZERO:
			break
		want += push
	return want


## Bend each elbow so the hand is where it should be, and write the keys of the six arm bones.
func _arm_solve(out: Animation, track_of: Dictionary, ta: Dictionary, rec: Array) -> void:
	for side in 2:
		var a := float(ta["a"][side])
		var b := float(ta["b"][side])
		# The move asked of the hand, smoothed over a few frames so a push off the face never pops.
		var off: Array = []
		for r in rec:
			off.append((r[side]["want"] as Vector3) - (r[side]["h"] as Vector3))
		var soft: Array = []
		for i in off.size():
			var acc := Vector3.ZERO
			var wsum := 0.0
			for k in range(-2, 3):
				var j := clampi(i + k, 0, off.size() - 1)
				var w := 3.0 - absf(k)
				acc += (off[j] as Vector3) * w
				wsum += w
			# (never softer than the push itself asked for: smoothing may add, not take away)
			var sm := acc / wsum
			soft.append(sm if sm.length() >= (off[i] as Vector3).length() * 0.85 else (off[i] as Vector3))
		var last_pole := Vector3.ZERO
		for i in rec.size():
			var r: Dictionary = rec[i][side]
			var s: Vector3 = r["s"]
			var target: Vector3 = (r["h"] as Vector3) + (soft[i] as Vector3)
			var to := target - s
			var dist := clampf(to.length(), absf(a - b) + (a + b) * 0.04, (a + b) * 0.998)
			var n := to.normalized() if to.length() > 0.00001 else ((r["h"] as Vector3) - s).normalized()
			var e0 := (r["e"] as Vector3) - s
			var pole := e0 - n * e0.dot(n)
			if pole.length() < (a + b) * 0.02:
				pole = last_pole if last_pole != Vector3.ZERO else ((r["down"] as Vector3) + (r["out"] as Vector3) * 0.5)
				pole = pole - n * pole.dot(n)
			pole = pole.normalized()
			last_pole = pole
			var x := (a * a - b * b + dist * dist) / (2.0 * dist)
			var hgt := sqrt(maxf(a * a - x * x, 0.0))
			var elbow := s + n * x + pole * hgt
			var hand := s + n * dist
			var u0 := ((r["e"] as Vector3) - s).normalized()
			var f0 := ((r["h"] as Vector3) - (r["e"] as Vector3)).normalized()
			var u1 := (elbow - s).normalized()
			var f1 := (hand - elbow).normalized()
			var gu: Basis = r["gu"]
			var gf: Basis = r["gf"]
			if u0.dot(u1) < 0.999999 and u0.dot(u1) > -0.9999:
				gu = Basis(Quaternion(u0, u1)) * gu
			if f0.dot(f1) < 0.999999 and f0.dot(f1) > -0.9999:
				gf = Basis(Quaternion(f0, f1)) * gf
			var t := float(r["t"])
			out.rotation_track_insert_key(track_of[int(ta["arm"][side])], t, ((r["pg"] as Basis).inverse() * gu).orthonormalized().get_rotation_quaternion())
			out.rotation_track_insert_key(track_of[int(ta["fore"][side])], t, (gu.inverse() * gf).orthonormalized().get_rotation_quaternion())
			out.rotation_track_insert_key(track_of[int(ta["hand"][side])], t, (gf.inverse() * (r["gh"] as Basis)).orthonormalized().get_rotation_quaternion())


const GESTURES := "res://assets/models/anim/gestures.glb"
const CLIPS := "res://assets/models/anim/clips/"
## Motions of the arms and the torso: the legs keep the calm stance under them.
const PLANTED := ["g_wave", "g_chat", "g_scratch", "g_listen", "g_phone", "g_agree", "g_checkout", "g_alert", "g_challenge", "g_defeat",
	"g_draw", "g_play", "g_cset", "g_cspell", "g_ctrap", "g_point", "g_think", "g_summon_big", "g_endturn", "g_hip",
	"g_shrug", "g_scheme", "g_cheer_one", "g_talk_open", "g_fo_glove", "g_fo_knuckles", "g_fo_chest", "g_fo_hair", "g_fo_salute",
	"g_fo_beckon", "g_fo_open", "g_ace_sky", "g_ace_both", "g_ace_sweep", "g_ace_snap", "g_ace_fist"]
var _gest: Node = null           # the shared library of everyday motions (wave, chat, sit, ...)
var _gest_cache := {}            # "<model file>|<clip>" -> Animation, made once per model file

# ---- (0.72.3) motions fitted to a model are kept on disk too. Fitting one is 20 to 70 ms of work, a
# world has dozens of models with a dozen motions each, and it was all done again every session, a
# little at a time while you played: a stutter every third of a second for the first half minute.
static var FIT_DIR := Saves.u("fit_cache/")
var _fit_checked := false
var _fit_tasks: Array = []


func _fit_path(ck: String, model: Node, file_of := "") -> String:
	var file := file_of if file_of != "" else str(model.get_meta("file", ""))
	var stamp := FileAccess.get_modified_time(file) if file != "" and not file.begins_with("res://") else 0
	return FIT_DIR + ("%s|%s|%d|%s|%s" % [ck, _fit_mark(), stamp, str(arms_by_position), str(made_motions)]).md5_text() + ".res"


## (0.72.4) What the kept motions are good for: the way they are fitted (data/fit_rev.json, set by
## tests/fit_rev.gd and checked by the unit tests), not the version of the game. They used to be
## thrown away with every update, and every place worked them all out again on the next visit.
var _fit_rev := ""

func _fit_mark() -> String:
	if _fit_rev == "":
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/fit_rev.json"))
		_fit_rev = str((j as Dictionary).get("rev", "")) if j is Dictionary else ""
		if _fit_rev == "":
			_fit_rev = "v" + str(ProjectSettings.get_setting("application/config/version", ""))
	return _fit_rev


func _fit_dir() -> void:
	if _fit_checked:
		return
	_fit_checked = true
	DirAccess.make_dir_recursive_absolute(FIT_DIR)
	# Fitted another way now: the old fits go (their names would never be asked for again).
	var ver := _fit_mark()
	var mark := FIT_DIR + "version.txt"
	if FileAccess.get_file_as_string(mark) != ver:
		var d := DirAccess.open(FIT_DIR)
		if d != null:
			for f in d.get_files():
				if f.ends_with(".res"):
					d.remove(f)
		var w := FileAccess.open(mark, FileAccess.WRITE)
		if w != null:
			w.store_string(ver)
			w.close()


func _fit_load(ck: String, model: Node, file_of := "") -> Animation:
	if (file_of == "" and not model.has_meta("file")) or OS.has_environment("NO_FIT_CACHE"):
		return null
	_fit_dir()
	var path := _fit_path(ck, model, file_of)
	if not FileAccess.file_exists(path):
		return null
	var a = ResourceLoader.load(path, "Animation", ResourceLoader.CACHE_MODE_IGNORE)
	return a as Animation


func _fit_save(ck: String, model: Node, anim: Animation, file_of := "") -> void:
	if _laps:
		print("FIT %s  %s" % [ck.get_slice("|", 0).get_file() + " " + ck.get_slice("|", 2), "behind the card" if Router.loading else "IN THE WORLD"])
	if (file_of == "" and not model.has_meta("file")) or anim == null or OS.has_environment("NO_FIT_CACHE"):
		return
	_fit_dir()
	var path := _fit_path(ck, model, file_of)
	var copy := anim.duplicate() as Animation      # (its own copy: written on another thread)
	_fit_tasks.append(WorkerThreadPool.add_task(func(): ResourceSaver.save(copy, path, ResourceSaver.FLAG_COMPRESS), false, "keep a fitted motion"))


func _fit_wait(all := false) -> void:
	var left: Array = []
	for t in _fit_tasks:
		if all or WorkerThreadPool.is_task_completed(int(t)):
			WorkerThreadPool.wait_for_task_completion(int(t))
		else:
			left.append(t)
	_fit_tasks = left


## The everyday motions of the people in a world, fitted ahead of time so nothing waits when somebody
## waves. One line of all of them, worked through by the clock: plenty per frame while the loading
## card is up, and once you are playing only what costs nothing, with a pause after any that had to
## be worked out.
var _warm_q: Array = []         # [weakref to the model, motion]
var _warm_pause := 0


func warm_gestures(model: Node, motions: Array) -> void:
	for m in motions:
		_warm_q.append([weakref(model), str(m)])


func _warm_step() -> void:
	if _warm_pause > 0 and not Router.loading:
		_warm_pause -= 1
		return
	var t0 := Time.get_ticks_usec()
	while not _warm_q.is_empty():
		var e: Array = _warm_q.pop_front()
		var m = (e[0] as WeakRef).get_ref()
		if m == null or not is_instance_valid(m) or not (m as Node).is_inside_tree():
			continue
		var t1 := Time.get_ticks_usec()
		gesture(m, str(e[1]))
		if Time.get_ticks_usec() - t1 > 4000:
			_warm_pause = 10      # that one had to be worked out: let ten frames go by before the next
		if Time.get_ticks_usec() - t0 > (20000 if Router.loading else 1500):
			break


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
	if MADE_MOTIONS.has(nm) and made_motions:
		var made := _made_for(model, nm, skel)
		if made != "":
			return made
		if nm.begins_with("g_st_"):
			return ""      # (a stance that cannot be built on this body: the calm stand, never the old recorded one)
	if _gest == null or not is_instance_valid(_gest):
		var ps = load(GESTURES)
		if not (ps is PackedScene):
			return ""
		_gest = ps.instantiate()
	var dap := anim_player(_gest)
	var dskel := _first_skeleton(_gest)
	if dap != null and dskel != null and MADE_POSES.has(nm) and not dap.has_animation(nm):
		_make_pose_clip(dap, dskel, nm)
	# Motions added after the library file was made live one clip per file (tools/dev/motions).
	if dap != null and dskel != null and not dap.has_animation(nm) and ResourceLoader.exists(CLIPS + nm + ".res"):
		var extra := load(CLIPS + nm + ".res") as Animation
		if extra != null:
			var dlib := dap.get_animation_library(dap.get_animation_library_list()[0])
			var droot := dap.get_node_or_null(dap.root_node)
			var dpath := str(droot.get_path_to(dskel)) if droot != null else "Skeleton3D"
			var fit := extra.duplicate() as Animation
			for t in fit.get_track_count():
				fit.track_set_path(t, NodePath(dpath + ":" + String(fit.track_get_path(t)).get_slice(":", 1)))
			dlib.add_animation(nm, fit)
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
		anim = _fit_load(ck, model)
		if anim != null:
			_gest_cache[ck] = anim
	if anim == null:
		var ratio := 1.0
		var hip_a := skel.find_bone("Hips")
		var hip_b := dskel.find_bone("Hips")
		if hip_a >= 0 and hip_b >= 0 and absf(dskel.get_bone_global_rest(hip_b).origin.y) > 0.0001:
			ratio = skel.get_bone_global_rest(hip_a).origin.y / dskel.get_bone_global_rest(hip_b).origin.y
		anim = _retarget(dap.get_animation(nm), dskel, skel, skel_path, ratio, 20.0)
		# Standing motions only move the top half: the legs keep the calm stance of the idle,
		# so going in and out of a gesture never shuffles the feet.
		if nm in PLANTED and rest_idle(model) != "":
			_plant_legs(anim, ap.get_animation("g_rest"))
		if nm in ["g_stand", "g_stand2", "g_sit", "g_sittalk", "g_chat", "g_listen"]:
			anim.loop_mode = Animation.LOOP_LINEAR
		if nm in ["g_scheme", "g_fist_pump", "g_head_hold"]:
			# (bowed until the face was gone: the head comes up, and the back with it)
			_calm_head(anim, skel, skel_path, 0.45, ["Spine", "Spine01", "Spine02"] if nm == "g_scheme" else [])
		if nm.begins_with("g_st_"):
			# A stance is held for minutes, so the head stays up: whoever stands there shows their face.
			_calm_head(anim, skel, skel_path, 0.3)
		if model.has_meta("file"):
			_gest_cache[ck] = anim
			_fit_save(ck, model, anim)
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
	# Everyday business for the people who live a day of their own (see StarLife).
	# Something in the right hand, held up in front of the chest, and now and then to the mouth.
	"g_eat": {"length": 9.0, "back": 8.2, "order": ["neck", "Head", "RightArm", "RightForeArm"],
		"poses": [
			[0.6, {"neck": Vector2(0.14, 0.0), "RightArm": Vector3(-0.3, -0.9, 0.3), "RightForeArm": Vector3(0.3, 0.45, 0.84)}],
			[2.8, {"neck": Vector2(0.14, 0.0), "RightArm": Vector3(-0.3, -0.9, 0.3), "RightForeArm": Vector3(0.3, 0.45, 0.84)}],
			[3.4, {"neck": Vector2(0.22, 0.0), "RightArm": Vector3(-0.3, -0.72, 0.62), "RightForeArm": Vector3(0.42, 0.88, 0.2)}],
			[4.3, {"neck": Vector2(0.22, 0.0), "RightArm": Vector3(-0.3, -0.72, 0.62), "RightForeArm": Vector3(0.42, 0.88, 0.2)}],
			[5.0, {"neck": Vector2(0.1, 0.0), "RightArm": Vector3(-0.3, -0.9, 0.3), "RightForeArm": Vector3(0.3, 0.45, 0.84)}],
		]},
	# A fan of cards in the left hand, eyes on it; the right hand comes over to move one.
	"g_read": {"length": 10.0, "back": 9.2, "order": ["neck", "Head", "LeftArm", "LeftForeArm", "RightArm", "RightForeArm"],
		"poses": [
			[0.6, {"neck": Vector2(0.26, 0.0), "Head": Vector2(0.18, -0.12), "LeftArm": Vector3(0.3, -0.92, 0.22), "LeftForeArm": Vector3(-0.2, 0.22, 0.95)}],
			[3.6, {"neck": Vector2(0.26, 0.0), "Head": Vector2(0.18, -0.12), "LeftArm": Vector3(0.3, -0.92, 0.22), "LeftForeArm": Vector3(-0.2, 0.22, 0.95)}],
			[4.3, {"neck": Vector2(0.3, 0.0), "Head": Vector2(0.2, -0.08), "LeftArm": Vector3(0.3, -0.92, 0.22), "LeftForeArm": Vector3(-0.2, 0.22, 0.95), "RightArm": Vector3(-0.25, -0.86, 0.42), "RightForeArm": Vector3(0.5, 0.2, 0.84)}],
			[5.4, {"neck": Vector2(0.3, 0.0), "Head": Vector2(0.2, -0.08), "LeftArm": Vector3(0.3, -0.92, 0.22), "LeftForeArm": Vector3(-0.2, 0.22, 0.95), "RightArm": Vector3(-0.25, -0.86, 0.42), "RightForeArm": Vector3(0.5, 0.2, 0.84)}],
			[6.2, {"neck": Vector2(0.26, 0.0), "Head": Vector2(0.18, -0.12), "LeftArm": Vector3(0.3, -0.92, 0.22), "LeftForeArm": Vector3(-0.2, 0.22, 0.95)}],
		]},
	# Bent over something at waist height, both hands on it.
	"g_tinker": {"length": 9.0, "back": 8.2, "order": ["Spine01", "neck", "RightArm", "RightForeArm", "LeftArm", "LeftForeArm"],
		"poses": [
			[0.7, {"Spine01": Vector2(0.3, 0.0), "neck": Vector2(0.2, 0.0), "RightArm": Vector3(-0.22, -0.7, 0.68), "RightForeArm": Vector3(0.18, -0.1, 0.98), "LeftArm": Vector3(0.22, -0.7, 0.68), "LeftForeArm": Vector3(-0.18, -0.1, 0.98)}],
			[3.0, {"Spine01": Vector2(0.34, 0.08), "neck": Vector2(0.24, 0.0), "RightArm": Vector3(-0.22, -0.62, 0.75), "RightForeArm": Vector3(0.3, 0.1, 0.95), "LeftArm": Vector3(0.22, -0.7, 0.68), "LeftForeArm": Vector3(-0.18, -0.1, 0.98)}],
			[5.5, {"Spine01": Vector2(0.3, -0.06), "neck": Vector2(0.2, 0.0), "RightArm": Vector3(-0.22, -0.7, 0.68), "RightForeArm": Vector3(0.1, -0.2, 0.97), "LeftArm": Vector3(0.22, -0.7, 0.68), "LeftForeArm": Vector3(-0.18, -0.1, 0.98)}],
		]},
	# The Duel Disk arm across the chest, the other hand working at it.
	"g_disk": {"length": 10.0, "back": 9.2, "order": ["neck", "Head", "LeftArm", "LeftForeArm", "RightArm", "RightForeArm"],
		"poses": [
			[0.7, {"neck": Vector2(0.24, 0.0), "Head": Vector2(0.16, -0.2), "LeftArm": Vector3(0.34, -0.9, 0.26), "LeftForeArm": Vector3(-0.6, 0.2, 0.77), "RightArm": Vector3(-0.25, -0.86, 0.42), "RightForeArm": Vector3(0.45, 0.25, 0.86)}],
			[3.5, {"neck": Vector2(0.24, 0.0), "Head": Vector2(0.16, -0.2), "LeftArm": Vector3(0.34, -0.9, 0.26), "LeftForeArm": Vector3(-0.6, 0.2, 0.77), "RightArm": Vector3(-0.25, -0.86, 0.42), "RightForeArm": Vector3(0.3, 0.32, 0.9)}],
			[6.0, {"neck": Vector2(0.28, 0.0), "Head": Vector2(0.18, -0.24), "LeftArm": Vector3(0.34, -0.9, 0.26), "LeftForeArm": Vector3(-0.6, 0.2, 0.77), "RightArm": Vector3(-0.25, -0.86, 0.42), "RightForeArm": Vector3(0.5, 0.2, 0.84)}],
			[8.6, {"neck": Vector2(0.24, 0.0), "Head": Vector2(0.16, -0.2), "LeftArm": Vector3(0.34, -0.9, 0.26), "LeftForeArm": Vector3(-0.6, 0.2, 0.77), "RightArm": Vector3(-0.25, -0.86, 0.42), "RightForeArm": Vector3(0.38, 0.28, 0.88)}],
		]},
	# Arms folded, weight back: somebody who is not waiting for anyone.
	"g_armsx": {"length": 14.0, "back": 13.2, "order": ["Spine01", "RightArm", "RightForeArm", "LeftArm", "LeftForeArm"],
		"poses": [
			[0.7, {"Spine01": Vector2(-0.05, 0.0), "RightArm": Vector3(-0.42, -0.86, 0.3), "RightForeArm": Vector3(0.93, 0.18, 0.32), "LeftArm": Vector3(0.42, -0.86, 0.3), "LeftForeArm": Vector3(-0.93, 0.26, 0.26)}],
			[12.5, {"Spine01": Vector2(-0.05, 0.0), "RightArm": Vector3(-0.42, -0.86, 0.3), "RightForeArm": Vector3(0.93, 0.18, 0.32), "LeftArm": Vector3(0.42, -0.86, 0.3), "LeftForeArm": Vector3(-0.93, 0.26, 0.26)}],
		]},
	# Head back, looking at the sky (or out to sea), hands behind the back.
	"g_skygaze": {"length": 12.0, "back": 11.2, "order": ["neck", "Head", "RightArm", "LeftArm"],
		"poses": [
			[0.9, {"neck": Vector2(-0.2, 0.0), "Head": Vector2(-0.22, 0.0), "RightArm": Vector3(-0.2, -0.92, -0.32), "LeftArm": Vector3(0.2, -0.92, -0.32)}],
			[5.5, {"neck": Vector2(-0.22, 0.0), "Head": Vector2(-0.2, 0.18), "RightArm": Vector3(-0.2, -0.92, -0.32), "LeftArm": Vector3(0.2, -0.92, -0.32)}],
			[10.5, {"neck": Vector2(-0.2, 0.0), "Head": Vector2(-0.22, -0.1), "RightArm": Vector3(-0.2, -0.92, -0.32), "LeftArm": Vector3(0.2, -0.92, -0.32)}],
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
	if cached == null:
		cached = _fit_load(ck, model)
		if cached != null:
			_gest_cache[ck] = cached
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
		_fit_save(ck, model, a)
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


## What somebody has on for now, on top of their own model: key -> jacket color as html. A duel
## started in the world sets this, so the person across the field (and you) wear in the duel what
## you both wore when the challenge was made. Empty everywhere else.
var dress := {}


## Put a dorm jacket on a loaded model. Your own duelist keeps every color you picked: only the
## top is repainted.
func wear(model: Node, key: String, color: Color) -> void:
	if key == "player":
		var tone := player_coat(color)
		for n in [model] + model.find_children("*", "Node3D", true, false):
			if n.has_meta("hero_mats"):
				for m in n.get_meta("hero_mats"):
					(m as ShaderMaterial).set_shader_parameter("top_to", Color(tone.r, tone.g, tone.b, 1.0))
					# The hero's jacket is mostly its accent color: a dorm jacket has to take that too,
					# or nothing changes on the default look.
					var acc := player_coat(color, true)
					(m as ShaderMaterial).set_shader_parameter("accent_to", Color(acc.r, acc.g, acc.b, 1.0))
				return
	apply_uniform(model, color)


## The jacket color as the hero's paint should get it, so it reads like the other students' jackets.
## A student's jacket is drawn as coat * (0.5 + 0.7 * the cloth's own light), which in the light of
## the island comes to about 0.85 of the dorm color, a little greyer in the folds; the hero's paint
## puts the color on as it is, so the same red came out purer and louder than everybody else's.
## `accent`: for the parts the hero's paint re-hues instead of repainting (most of the Academy
## blazer). Re-hue keeps the cloth's own brightness and only moves it part of the way to the new
## color (60% of the brightness, 80% of the greyness), so that color has to be toned further to
## land on the same jacket: about 0.82 of the light and 0.85 of the strength of the dorm color.
static func player_coat(c: Color, accent := false) -> Color:
	var grey := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	var g := Color(grey, grey, grey)
	if accent:
		return c.lerp(g, PLAYER_ACCENT_GREY) * PLAYER_ACCENT_LIGHT
	return c.lerp(g, PLAYER_COAT_GREY) * PLAYER_COAT_LIGHT


const PLAYER_COAT_LIGHT := 0.86
const PLAYER_COAT_GREY := 0.1
const PLAYER_ACCENT_LIGHT := 0.72
const PLAYER_ACCENT_GREY := 0.2


## The name a picture of `key` is kept under: with the jacket on, when they are wearing one.
func dressed(key: String) -> String:
	if not ("@" in key) and dress.has(key):
		return "%s@%s" % [key, str(dress[key])]
	# In their own clothes for now (before the entrance exam): its own picture, so the one in the
	# dorm jacket is not shown in its place, nor the other way round later.
	if not ("@" in key) and plain.has(key) and UNIFORMS.has(key):
		return key + "@plain"
	return key


# ---- (0.72.4) a dropped-in model is read once
# A model from the card folder used to be read from its file, built, its textures sized and its
# motions fitted every single time somebody needed it: once for the person in the street, again for
# their portrait, again when the portrait came back after a rest, again on the next visit. About
# 0.1 s each with a small file, far more with three 2048 textures. Now the finished model is kept
# aside (never shown itself) and every use is a copy of it: the copies share its meshes, textures
# and motions, so a second one costs a few milliseconds and no memory to speak of.
var _tpl := {}        # "<file>|<sharp>" -> {"node": Node, "stamp": int, "used": int, "mb": float}; a bundled one: "<res path>" -> {"scene": PackedScene, ...}
var _laps := OS.get_environment("MODEL_LAPS") != ""      # dev: what the first reading of each model cost
const TPL_BUDGET_MB := 700.0      # what the kept models may weigh together (meshes + textures, roughly)


func _own_copy(key: String, path: String, sharp: bool) -> Node:
	var t := _own_kept(key, path, sharp)
	return (t["node"] as Node).duplicate() if not t.is_empty() else null


## The kept model of a dropped-in file, read and finished now if it is not there yet.
func _own_kept(key: String, path: String, sharp: bool) -> Dictionary:
	var tk := "%s|%d" % [path, int(sharp)]
	var stamp := int(FileAccess.get_modified_time(path))
	var t: Dictionary = _tpl.get(tk, {})
	if t.is_empty() or not is_instance_valid(t["node"]) or int(t["stamp"]) != stamp:
		# (a file that was replaced while the game runs is read again)
		_tpl_drop(tk)
		var t0 := Time.get_ticks_usec()
		var g := _load_glb(path, 2048 if sharp else 1024)
		if g == null:
			return {}
		var t1 := Time.get_ticks_usec()
		_fit_textures(g, 2048 if sharp else 1024)      # (a net: they were sized as the file was read)
		var t2 := Time.get_ticks_usec()
		g = _merge_clip_files(key, path, g)
		_borrow_clips(g, path)
		var ap := anim_player(g)
		if ap:
			_calm_idle(ap)
		t = {"node": g, "stamp": stamp, "mb": _weight_mb(g)}
		if _laps:
			print("MODEL %s%s: read+build %.0f ms, textures %.0f ms, motions %.0f ms, %.0f MB kept" % [path.get_file(), " (sharp)" if sharp else "",
					(t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (Time.get_ticks_usec() - t2) / 1000.0, float(t["mb"])])
		_tpl[tk] = t
		t["used"] = Time.get_ticks_msec()
		_tpl_trim()
	t["used"] = Time.get_ticks_msec()
	return t


# A face that will be wanted soon (somebody you are standing next to): its file is read on another
# thread and the model finished the moment that is done, so the portrait is there at once when asked.
var _face_wanted := {}        # key -> true


func prepare_face(key: String) -> void:
	key = key.get_slice("@", 0)
	if key == "" or not has_avatar(key) or _stages.has(key):
		return
	warm(key)
	var path := path_for(key)
	if not path.begins_with("res://") and path.ends_with(".glb") and not _kept(path, true):
		_face_wanted[key] = true


func _faces_step() -> void:
	for key in _face_wanted.keys():
		var path := path_for(key)
		if path.begins_with("res://") or not path.ends_with(".glb") or _kept(path, true) or _stages.has(key):
			_face_wanted.erase(key)
			continue
		var wk := _warm_key(path, 2048)
		_warm_lock.lock()
		var have := _warm.has(wk)
		_warm_lock.unlock()
		if have:
			_own_kept(key, path, true)
			_face_wanted.erase(key)
			return      # (one a frame)
		if not _warm_ids.has(wk) and not _warm_wanted.has(wk):
			_face_wanted.erase(key)      # (its read was lost or let go: nothing to wait for)


## Several faces are about to be shown together (a lineup, a bracket, the two of a duel): their
## files are read on other threads, side by side, and waited for here with the loading card or the
## busy ring turning. (They used to be read one after another on the main thread, the picture
## standing still: a third of a second each for a model with big textures.) Nothing to wait for
## when they are on hand already.
func read_ahead(keys: Array, max_ms := 5000) -> void:
	var want: Array = []
	for k in keys:
		var key := str(k).get_slice("@", 0)
		if key == "" or key == "lumen" or want.has(key) or not has_avatar(key) or ready_now(key):
			continue
		want.append(key)
		warm(key)
	if want.is_empty():
		return
	Router.busy()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < max_ms:
		var all := true
		for key in want:
			if not ready_now(key):
				warm(key)
				all = false
		if all:
			break
		_warm_next()
		Router.pulse()
		OS.delay_msec(2)


## Are people's files still being read on other threads? (A world waits for them behind its card.)
var _res_reading: Array = []

func reading() -> bool:
	_warm_next()
	for p in _res_reading.duplicate():
		if ResourceLoader.load_threaded_get_status(p) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_res_reading.erase(p)
	return not _warm_ids.is_empty() or not _warm_wanted.is_empty() or not _res_reading.is_empty()


## What every model leans on, loaded once at the start: the body the walk and idle are borrowed
## from, and the library of everyday motions. (The first person of the session used to pay for both.)
func prime() -> void:
	if _donor == null or not is_instance_valid(_donor):
		var ps = load(DONOR)
		if ps is PackedScene:
			_donor = ps.instantiate()
	if _gest == null or not is_instance_valid(_gest):
		var gs = load(GESTURES)
		if gs is PackedScene:
			_gest = gs.instantiate()


## Roughly what a model holds on the graphics card: its textures (with their smaller versions) and
## its meshes.
func _weight_mb(scene: Node) -> float:
	var bytes := 0.0
	var seen := {}
	for mi in _meshes(scene):
		if mi.mesh == null or seen.has(mi.mesh):
			continue
		seen[mi.mesh] = true
		for i in mi.mesh.get_surface_count():
			bytes += mi.mesh.surface_get_array_len(i) * 48.0 + mi.mesh.surface_get_array_index_len(i) * 4.0
			var mat := mi.mesh.surface_get_material(i)
			if not (mat is BaseMaterial3D):
				continue
			for prop in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "ao_texture", "emission_texture"]:
				var tex = (mat as BaseMaterial3D).get(prop)
				if tex is Texture2D and not seen.has(tex):
					seen[tex] = true
					bytes += (tex as Texture2D).get_width() * (tex as Texture2D).get_height() * 4.0 * 1.34
	return bytes / 1048576.0


## The kept models stay under their budget: the ones not asked for the longest go first. (Whoever is
## made from one keeps what it shares with it; only the spare copy goes.)
func _tpl_trim() -> void:
	while _tpl.size() > 1:
		var total := 0.0
		var oldest := ""
		for k in _tpl:
			total += float(_tpl[k]["mb"])
			if oldest == "" or int(_tpl[k]["used"]) < int(_tpl[oldest]["used"]):
				oldest = k
		if total <= TPL_BUDGET_MB:
			return
		_tpl_drop(oldest)


func kept_mb() -> float:
	var total := 0.0
	for k in _tpl:
		total += float(_tpl[k]["mb"])
	return total


func _tpl_drop(tk: String) -> void:
	if not _tpl.has(tk):
		return
	var n = _tpl[tk].get("node")
	if n is Node and is_instance_valid(n):
		(n as Node).free()
	_tpl.erase(tk)


## Every kept model is let go (leaving the game).
func drop_kept_models() -> void:
	for k in _tpl.keys():
		_tpl_drop(k)


## Load a model as a fresh Node3D, posed, tinted (tints only for the player) and dressed.
func load_model(key: String) -> Node3D:
	Router.pulse()      # (keeps the loading card moving while a world's people are made)
	var m := _load_plain(key)
	if m and dress.has(key):
		wear(m, key, Color.html(str(dress[key])))
	return m


## `sharp`: for a portrait (a close look at the face): the color texture keeps up to 2048.
func _load_plain(key: String, sharp := false) -> Node3D:
	if not has_avatar(key):
		return null
	var path := path_for(key)
	if path.ends_with(".glb"):
		# (0.72.4) A model dropped into the card folder is read from its file once and copied from
		# then on (see _own_copy); a bundled one already was (the engine keeps its scene).
		var g: Node = _own_copy(key, path, sharp) if not path.begins_with("res://") else _load_glb(path)
		if g == null:
			return null
		# A rigged model without an idle, walk, run or victory of its own gets the game's
		# (yours, and the bundled ones that came from the rigger with no clips).
		if path.begins_with("res://"):
			_borrow_clips(g, path)
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
		if key.begins_with("net:") and path.begins_with("res://"):
			var gl := guest_look(key)
			var gparts := HeroLook.models(int(gl.get("look_body", 0)), int(gl.get("look_hair", 0)), int(gl.get("look_outfit", 0)))
			var gcol: Color = Profile.COLORS[clampi(int(gl.get("color_index", 0)), 0, Profile.COLORS.size() - 1)]
			if HeroLook.has_model(str(gparts["body"])):
				HeroLook.apply(g, str(gparts["body"]), str(gparts["head"]), gl, gcol)
			else:
				apply_hero_color(g, gcol, int(gl.get("look_outfit", 0)))
		if key == "player" and path.begins_with("res://"):
			var parts := HeroLook.models(Profile.look_body, Profile.look_hair, Profile.look_outfit)
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--force-head="):
					parts["head"] = a.trim_prefix("--force-head=")      # dev: try a head swap
			if HeroLook.has_model(str(parts["body"])):
				HeroLook.apply(g, str(parts["body"]), str(parts["head"]), Profile, Profile.color())
			else:
				apply_hero_color(g, Profile.color(), Profile.look_outfit)
		if UNIFORMS.has(key) and takes_jacket(key) and not plain.has(key):
			apply_uniform(g, DORM_COLORS[UNIFORMS[key]])
		elif COATS.has(key) and takes_jacket(key) and not plain.has(key):
			apply_uniform(g, COATS[key])
		keep_whole(r)
		even_light(r)
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
	keep_whole(root)
	even_light(root)
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
render_mode shadows_disabled;
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


## Paint a dorm jacket on a model: the torso and sleeves take the dorm color, with thin piping at
## the collar, down the zip and along the hem. The mask is worked out from where each vertex is
## in the rest pose (baked into the mesh once), so it stays glued to the body however the model
## moves, sits or bends. Skinned vertices reach the shader already moved, so they can't be used.
var _rest_cache := {}            # "file|mesh name" -> ArrayMesh with the rest pose in CUSTOM0


## `fore` lists the skin's bind indices that belong to a forearm or hand: the fourth number
## stored with each vertex is how much of it they carry, so a shader can tell forearm from waist
## even when the arms hang right beside the body.
func _with_rest_pose(mesh: Mesh, cache_key: String, fore := {}) -> ArrayMesh:
	if mesh.has_meta("rest_baked"):
		return mesh
	if cache_key != "" and _rest_cache.has(cache_key):
		return _rest_cache[cache_key]
	var src := mesh as ArrayMesh
	if src == null:
		return null
	var out := ArrayMesh.new()
	for bs in src.get_blend_shape_count():
		out.add_blend_shape(src.get_blend_shape_name(bs))
	out.blend_shape_mode = src.blend_shape_mode
	var custom_bits: int = Mesh.ARRAY_FORMAT_CUSTOM_MASK << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	for i in src.get_surface_count():
		var arrays := src.surface_get_arrays(i)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var rest := PackedFloat32Array()
		rest.resize(verts.size() * 4)
		var bones = arrays[Mesh.ARRAY_BONES]
		var weights = arrays[Mesh.ARRAY_WEIGHTS]
		var per := 0
		if not fore.is_empty() and bones != null and weights != null and verts.size() > 0:
			per = bones.size() / verts.size()
		for v in verts.size():
			var p := verts[v]
			rest[v * 4] = p.x
			rest[v * 4 + 1] = p.y
			rest[v * 4 + 2] = p.z
			var fw := 0.0
			for k in per:
				if fore.has(int(bones[v * per + k])):
					fw += float(weights[v * per + k])
			rest[v * 4 + 3] = fw
		arrays[Mesh.ARRAY_CUSTOM0] = rest
		var fmt: int = src.surface_get_format(i)
		fmt = (fmt & ~custom_bits) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		# Only the flag bits and the custom formats matter here; the rest is read off the arrays.
		var all_custom: int = 0
		for ci in 4:
			all_custom |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << (Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT + ci * Mesh.ARRAY_FORMAT_CUSTOM_BITS)
		var flags: int = fmt & (all_custom | Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
		out.add_surface_from_arrays(src.surface_get_primitive_type(i), arrays, src.surface_get_blend_shape_arrays(i), {}, flags)
		out.surface_set_material(i, src.surface_get_material(i))
		out.surface_set_name(i, src.surface_get_name(i))
	out.custom_aabb = src.custom_aabb
	out.set_meta("rest_baked", true)
	if cache_key != "":
		_rest_cache[cache_key] = out
	return out


func apply_uniform(scene: Node, color: Color) -> void:
	if _uniform_shader == null:
		_uniform_shader = Shader.new()
		_uniform_shader.code = """
shader_type spatial;
render_mode shadows_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 coat : source_color = vec3(0.85, 0.2, 0.17);
uniform float h = 1.7;
uniform float top = 0.80;
uniform float hem_y = 0.50;
uniform mat4 to_root;
uniform vec3 el_l;
uniform vec3 wr_l;
uniform float lim_l = 100.0;
uniform vec3 el_r;
uniform vec3 wr_r;
uniform float lim_r = 100.0;
varying vec3 lp;
varying float fore;
void vertex() {
	lp = (to_root * vec4(CUSTOM0.xyz, 1.0)).xyz;
	fore = CUSTOM0.a;
}
float off_sleeve(vec3 p, vec3 a, vec3 b, float lim) {
	vec3 ab = b - a;
	float along = dot(p - a, ab) / max(dot(ab, ab), 0.0001);
	float d = length(p - (a + ab * clamp(along, 0.0, 1.0)));
	return smoothstep(lim, lim * 1.1, d) * smoothstep(-0.3, -0.18, along) * (1.0 - smoothstep(1.6, 1.8, along));
}
// (0.74.2) Past the wrist, along the forearm and close to its line: a hand. Never jacket (a
// student's hands came out painted in the dorm color, fingers and all).
float past_wrist(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	float l2 = dot(ab, ab);
	if (l2 < 0.0001) {
		return 0.0;
	}
	float along = dot(p - a, ab) / l2;
	float d = length(p - (a + ab * along));
	return smoothstep(0.96, 1.02, along) * (1.0 - smoothstep(0.55, 0.7, d / sqrt(l2)));
}
void fragment() {
	vec4 t = texture(tex, UV);
	float y = lp.y / h;
	float x = abs(lp.x) / h;
	float arm = smoothstep(0.115, 0.135, x);
	float lo = mix(hem_y, hem_y + 0.065, arm);
	float body = smoothstep(lo, lo + 0.012, y) * (1.0 - smoothstep(top, top + 0.012, y)) * (1.0 - smoothstep(0.375, 0.39, x));
	// Something strapped to a forearm (a duel disk, a gauntlet) is not sleeve: past the sleeve's
	// own thickness from the bone it keeps its real colors.
	float on_fore = smoothstep(0.35, 0.65, fore);
	body *= 1.0 - off_sleeve(lp, el_l, wr_l, lim_l) * on_fore;
	body *= 1.0 - off_sleeve(lp, el_r, wr_r, lim_r) * on_fore;
	body *= 1.0 - clamp(past_wrist(lp, el_l, wr_l) + past_wrist(lp, el_r, wr_r), 0.0, 1.0);
	float lum = dot(t.rgb, vec3(0.3, 0.59, 0.11));
	vec3 cloth = coat * (0.5 + 0.7 * lum);
	// Thin piping only: a line just above the hem, a narrow zip and a line round the collar.
	float hem = smoothstep(hem_y + 0.012, hem_y + 0.017, y) * (1.0 - smoothstep(hem_y + 0.024, hem_y + 0.029, y)) * (1.0 - arm);
	float zip = (1.0 - smoothstep(0.003, 0.006, x)) * step(0.0, lp.z) * (1.0 - smoothstep(top - 0.03, top - 0.02, y));
	float collar = smoothstep(top - 0.014, top - 0.009, y) * (1.0 - smoothstep(0.075, 0.09, x));
	float trim = clamp(hem + zip + collar, 0.0, 1.0) * 0.8;
	// A slightly darker yoke over the shoulders gives the jacket some shape.
	cloth *= mix(1.0, 0.82, smoothstep(top - 0.07, top - 0.03, y));
	cloth = mix(cloth, mix(vec3(0.93, 0.92, 0.88), coat, 0.12) * (0.62 + 0.45 * lum), trim);
	ALBEDO = mix(t.rgb, cloth, body);
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
"""
	var skel := _skeleton(scene)
	var file := ""
	var up: Node = scene
	while up != null and file == "":
		file = str(up.get_meta("file", ""))
		up = up.get_parent()
	for mi in _meshes(scene):
		if mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		if box.size.y < 0.01:
			continue
		var fore_binds := {}
		if skel != null and mi.skin != null:
			var hmap := _guess_human_map(scene)
			var arm_bones := {}
			for hn in ["LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand"]:
				if hmap.has(hn):
					arm_bones[str(hmap[hn])] = true
			for bnd in mi.skin.get_bind_count():
				var bone_i := mi.skin.get_bind_bone(bnd)
				var bone_name := str(mi.skin.get_bind_name(bnd)) if bone_i < 0 else skel.get_bone_name(bone_i)
				if arm_bones.has(bone_name):
					fore_binds[bnd] = true
		var baked := _with_rest_pose(mi.mesh, (file + "|" + str(scene.get_path_to(mi))) if file != "" else "", fore_binds)
		if baked == null:
			continue
		if baked != mi.mesh:
			# Keep whatever the model had set on the mesh node itself.
			var keep: Array = []
			for i in mi.mesh.get_surface_count():
				keep.append(mi.get_surface_override_material(i))
			mi.mesh = baked
			for i in keep.size():
				mi.set_surface_override_material(i, keep[i])
		var top := 0.80
		var hem := 0.50
		var skinned: bool = skel != null and mi.skin != null
		var rel := Transform3D.IDENTITY
		var n: Node = skel if skinned else mi
		while n != null and n != scene:
			if n is Node3D:
				rel = (n as Node3D).transform * rel
			n = n.get_parent()
		# Mesh space -> skeleton space at rest: what the skin does to a vertex when nothing moves.
		var bind := Transform3D.IDENTITY
		if skinned and mi.skin.get_bind_count() > 0:
			var bi := mi.skin.get_bind_bone(0)
			if bi < 0:
				bi = skel.find_bone(mi.skin.get_bind_name(0))
			if bi >= 0:
				bind = skel.get_bone_global_rest(bi) * mi.skin.get_bind_pose(0)
		# The jacket runs from the hips to the base of the neck, wherever this body has them.
		if skinned:
			for b in skel.get_bone_count():
				var bn := skel.get_bone_name(b).to_lower()
				var by: float = (rel * skel.get_bone_global_rest(b).origin).y / box.size.y
				if bn.ends_with("neck") or bn == "neck":
					top = clampf(by - 0.012, 0.62, 0.88)
				elif bn.ends_with("hips") or bn == "hips" or bn.ends_with("pelvis"):
					hem = clampf(by - 0.035, 0.40, 0.58)
		var sleeves := _sleeve_limits(scene, skel, mi, rel, rel * bind, (file + "|" + str(scene.get_path_to(mi))) if file != "" else "") if skinned else []
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
			sm.set_shader_parameter("to_root", rel * bind)
			for k in sleeves.size():
				var sl: Array = sleeves[k]
				sm.set_shader_parameter("el_l" if k == 0 else "el_r", sl[0])
				sm.set_shader_parameter("wr_l" if k == 0 else "wr_r", sl[1])
				sm.set_shader_parameter("lim_l" if k == 0 else "lim_r", sl[2])
			mi.set_surface_override_material(i, sm)


## For each arm: [elbow, wrist, how far from the bone the sleeve reaches]. A forearm that is
## much thicker than the other one is carrying something (a duel disk, a gauntlet); there the
## reach is the plain forearm's thickness, so the jacket color stops at the sleeve and whatever
## is strapped on keeps its own colors. A plain arm gets a reach of 100: no limit.
var _sleeve_cache := {}


func _sleeve_limits(scene: Node, skel: Skeleton3D, mi: MeshInstance3D, rel: Transform3D, to_root: Transform3D, cache_key: String) -> Array:
	if cache_key != "" and _sleeve_cache.has(cache_key):
		return _sleeve_cache[cache_key]
	var map := _guess_human_map(scene)
	var out: Array = []
	var arms: Array = []
	var kind_of := {}        # bone name -> [arm index, 0 upper / 1 forearm]
	for side in ["Left", "Right"]:
		var up := skel.find_bone(str(map.get(side + "UpperArm", "")))
		var lo := skel.find_bone(str(map.get(side + "LowerArm", "")))
		var hand := skel.find_bone(str(map.get(side + "Hand", "")))
		if up < 0 or lo < 0 or hand < 0:
			return []
		kind_of[skel.get_bone_name(up)] = [arms.size(), 0]
		kind_of[skel.get_bone_name(lo)] = [arms.size(), 1]
		arms.append([rel * skel.get_bone_global_rest(up).origin, rel * skel.get_bone_global_rest(lo).origin, rel * skel.get_bone_global_rest(hand).origin, [], []])
	# Which of the skin's binds are arm bones.
	var bind_kind := {}
	for bnd in mi.skin.get_bind_count():
		var bone_i := mi.skin.get_bind_bone(bnd)
		var bone_name := str(mi.skin.get_bind_name(bnd)) if bone_i < 0 else skel.get_bone_name(bone_i)
		if kind_of.has(bone_name):
			bind_kind[bnd] = kind_of[bone_name]
	for si in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(si)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones = arrays[Mesh.ARRAY_BONES]
		var weights = arrays[Mesh.ARRAY_WEIGHTS]
		if bones == null or weights == null or verts.is_empty():
			continue
		var per: int = bones.size() / verts.size()
		for v in verts.size():
			# The bone that carries most of this vertex says which part of the body it is.
			var best := -1
			var best_w := 0.0
			for k in per:
				var wgt := float(weights[v * per + k])
				if wgt > best_w:
					best_w = wgt
					best = int(bones[v * per + k])
			if best_w < 0.6 or not bind_kind.has(best):
				continue
			var bk: Array = bind_kind[best]
			var arm: Array = arms[bk[0]]
			var p := to_root * verts[v]
			var a0: Vector3 = arm[0] if bk[1] == 0 else arm[1]
			var a1: Vector3 = arm[1] if bk[1] == 0 else arm[2]
			var ax := a1 - a0
			var t := clampf((p - a0).dot(ax) / maxf(ax.length_squared(), 0.0001), 0.0, 1.0)
			if bk[1] == 0 and t < 0.35:
				continue          # the shoulder end of the upper arm is half chest
			(arm[3 + int(bk[1])] as Array).append((p - (a0 + ax * t)).length())
	# How thick each forearm is, ignoring the odd stray vertex. A forearm much thicker than the
	# other one is carrying something: there the sleeve is only as thick as the plain arm.
	var thick: Array = []
	for arm: Array in arms:
		var fore: Array = arm[4]
		fore.sort()
		thick.append(float(fore[int(fore.size() * 0.97)]) if fore.size() > 8 else 0.0)
	for i in arms.size():
		var other: float = thick[1 - i]
		var lim := 100.0
		if other > 0.0 and float(thick[i]) > other * 1.3:
			lim = other * 1.08
		out.append([arms[i][1], arms[i][2], lim])
	if cache_key != "":
		_sleeve_cache[cache_key] = out
	return out


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
const HI_MAX := 6
var _hi: Array[String] = []      # the few portraits being shown big right now


## `hi` asks for the portrait at double size, for when it fills a large part of the screen.
## Only the last few asked for stay that sharp; the rest go back to the normal size.
var _asked := 0          # (dev) how many times a portrait was asked for since the last count
var _count_asks := "--portrait-count" in OS.get_cmdline_user_args()

func portrait(key: String, hi := false) -> Texture2D:
	_asked += 1
	key = dressed(key)
	_asked_at[key] = Time.get_ticks_msec()
	if _stages.has(key):
		_restage(key)
		_touch(key)
		if hi:
			_sharpen(key)
		return (_stages[key] as SubViewport).get_texture()
	var model := _load_plain(key.get_slice("@", 0), true)
	if model == null:
		return null
	if "@" in key and key.get_slice("@", 1) != "plain":
		wear(model, key.get_slice("@", 0), Color.html(key.get_slice("@", 1)))
	var vp := SubViewport.new()
	vp.size = stage_size()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Settings.small_view_msaa()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var stage := Node3D.new()
	stage.set_script(preload("res://scripts/core/avatar_stage.gd"))
	vp.add_child(stage)
	stage.call("setup", model)
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_stages[key] = vp
	_stage_path[key] = path_for(key.get_slice("@", 0))
	_touch(key)
	if hi:
		_sharpen(key)
	return vp.get_texture()


## ---- What a portrait keeps in memory (0.63.1). Every duelist whose portrait was ever shown kept a
## whole model loaded behind their picture for the rest of the session: 50 to 60 MB each with the
## textures of a model made outside the game, so the 25 of them were over a gigabyte that never came
## back. Now a portrait nobody has asked for in a while lets its model go and keeps its picture; the
## model comes back the next time the portrait is asked for. The few most recent always stay ready
## (the two duelists of a duel are never reloaded in the middle of it).
var STAGE_MODELS := 4          # the most recently asked-for portraits keep their model, come what may
const STAGE_IDLE_MS := 12000     # the others let it go after this long without being asked for
var _asked_at := {}              # key -> when its portrait was last asked for (msec)


func _stage_of(key: String) -> Node:
	var vp: SubViewport = _stages.get(key)
	return vp.get_child(0) if vp != null and vp.get_child_count() > 0 else null


## Put the model back behind a portrait that had let it go.
func _restage(key: String) -> void:
	var stage := _stage_of(key)
	if stage == null or bool(stage.call("loaded")):
		return
	var model := _load_plain(key.get_slice("@", 0), true)
	if model == null:
		return
	if "@" in key and key.get_slice("@", 1) != "plain":
		wear(model, key.get_slice("@", 0), Color.html(key.get_slice("@", 1)))
	stage.call("enter", model)


## Is anything on screen (or anything at all, beyond the two that always do) holding this portrait's
## picture? The viewport holds it, and so does the Portraits list once it has handed it out.
func _shown(key: String) -> bool:
	var vp: SubViewport = _stages.get(key)
	if vp == null:
		return false
	var tex := vp.get_texture()
	return tex.get_reference_count() > 2 + (1 if Portraits.holds(key) else 0)


## Somebody is about to show this portrait again (it was handed out before): if it had let its model
## go, the model comes back and the picture is drawn fresh.
func wake(key: String) -> void:
	if not _stages.has(key):
		return
	_asked_at[key] = Time.get_ticks_msec()
	var stage := _stage_of(key)
	if stage != null and not bool(stage.call("loaded")):
		_restage(key)
		_touch(key)


## Called now and then: a portrait nothing is showing, not asked for in a while, gives up its model
## (the few most recent keep theirs). Its picture stays as it is.
func _trim_stages() -> void:
	var now := Time.get_ticks_msec()
	var loaded: Array = []
	for k in _stages:
		var stage := _stage_of(k)
		if stage != null and bool(stage.call("loaded")):
			loaded.append(k)
	if loaded.size() <= STAGE_MODELS:
		return
	loaded.sort_custom(func(a, b): return int(_asked_at.get(a, 0)) > int(_asked_at.get(b, 0)))
	for k in loaded.slice(STAGE_MODELS):
		var vp: SubViewport = _stages[k]
		if now - int(_asked_at.get(k, 0)) < STAGE_IDLE_MS or _shown(k):
			continue
		# (Never freeze a picture that is not drawn yet. With no screen nothing is ever drawn, so the
		# tests skip this check.)
		if DisplayServer.get_name() != "headless" and (not _framed(k) or _blank(vp)):
			continue
		_live.erase(k)
		_hi.erase(k)
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_awake(k, false)
		_stage_of(k).call("unload")


## (0.75.1) Makes the portrait of `key` move: a motion from the shared library, played once, then
## its calm idle again (Legendary Duels scenes: the one speaking talks with their hands, the other
## listens). False when that portrait has no model loaded or the model cannot do it.
func portrait_act(key: String, motion: String, blend := 0.35) -> bool:
	var stage := _stage_of(dressed(key))
	if stage == null or not bool(stage.call("loaded")) or not stage.has_method("act"):
		return false
	return bool(stage.call("act", motion, blend))


## The motions a portrait is about to need, fitted ahead in small steps so the first one does not stall.
func portrait_warm(key: String, motions: Array) -> void:
	var stage := _stage_of(dressed(key))
	if stage != null and bool(stage.call("loaded")) and stage.get("_model") != null:
		warm_gestures(stage.get("_model"), motions)


## The size every portrait is drawn at when it is not one of the few big ones. Bigger on High
## and Ultra, so a tile that zooms in on a face stays crisp.
func stage_size() -> Vector2i:
	return Vector2i(768, 960) if int(Settings.gfx.get("detail", 2)) >= 2 else STAGE_SIZE


## How many meters, top to bottom, the portrait of `key` shows (1.22 for most, more for tall hair).
func portrait_view(key: String) -> float:
	key = dressed(key)
	if _stages.has(key):
		var stage: Node = (_stages[key] as SubViewport).get_child(0)
		if stage and stage.get("view_h") != null:
			return float(stage.get("view_h"))
	return 1.22


func _sharpen(key: String) -> void:
	_hi.erase(key)
	_hi.push_front(key)
	(_stages[key] as SubViewport).size = HI_SIZE
	while _hi.size() > HI_MAX:
		var old: String = _hi.pop_back()
		if _stages.has(old):
			_restage(old)
			(_stages[old] as SubViewport).size = stage_size()
			# A portrait that is holding its last frame has to draw once more at the new size.
			# (Drawn live again until a picture is really there, then frozen: a single UPDATE_ONCE could
			# lose the race with a freeze already waiting and leave the tile empty.)
			if not _live.has(old):
				(_stages[old] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS
				_freeze_later(old)


const LIVE_MAX := 5
var _live: Array[String] = []


## Only the few most recently asked-for portraits keep animating; the rest hold their last frame.
func _touch(key: String) -> void:
	_live.erase(key)
	_live.push_front(key)
	(_stages[key] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_awake(key, true)
	while _live.size() > LIVE_MAX:
		var old: String = _live.pop_back()
		if _stages.has(old):
			# (0.80.0) A live portrait is drawn every other frame (_process switches it off in between):
			# one that left the live list on an "off" frame was never drawn again, and if its first
			# picture was not there yet the tile froze empty (Jack, Crow in Free Duel's 5D's tab).
			(_stages[old] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS
			_freeze_later(old)


## Live portraits are small moving busts: drawing each on every other frame halves what they
## cost and nobody can tell. They take turns, so the load is even from frame to frame.
var _tick := 0
## Set while nothing on screen shows a portrait that should move (walking around the world with
## no conversation open): the live portraits stop being redrawn until it is cleared.
var quiet := false


func _process(_delta: float) -> void:
	_tick += 1
	if not _warm_wanted.is_empty() and _tick % 3 == 0:
		_warm_next()
	if not _warm_q.is_empty():
		_warm_step()
	if not _face_wanted.is_empty() and _tick % 4 == 0:
		_faces_step()
	if not _fit_tasks.is_empty() and _tick % 30 == 0:
		_fit_wait()
	if _tick % 90 == 0:
		_trim_stages()
		_warm_expire()
	if _count_asks and _tick % 120 == 0:
		var drawing := 0
		for k in _stages:
			if (_stages[k] as SubViewport).render_target_update_mode != SubViewport.UPDATE_DISABLED:
				drawing += 1
		print("PORTRAITS asked %d times in 120 frames, %d views, %d not asleep, %d live" % [_asked, _stages.size(), drawing, _live.size()])
		_asked = 0
	for i in _live.size():
		var vp: SubViewport = _stages.get(_live[i])
		if vp == null:
			continue
		if quiet:
			# Nobody is looking at a moving portrait right now: each holds the frame it has.
			# (One that was only just asked for is drawn once first.)
			if not _framed(_live[i]):
				continue          # still getting its first picture: leave it drawing
			if vp.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
				vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			else:
				_awake(_live[i], false)
			continue
		_awake(_live[i], true)
		if (_tick + i) % 2 == 0:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		elif vp.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _freeze_later(key: String) -> void:
	await get_tree().create_timer(0.6).timeout
	# Never freeze a picture that has not been drawn yet (a slow frame, a model that took its
	# time, or one just resized): wait for its stage to say the first picture is there.
	var tries := 0
	while _stages.has(key) and not _framed(key) and tries < 600:
		tries += 1
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	# Still nothing in the picture (a model whose textures or meshes arrived late): keep drawing
	# and look again, so a tile never freezes empty (Pegasus's tile on the Mac, Bakura's on Windows).
	# (0.80.0: 20 tries were not enough on a slow machine with 43 tiles to draw: a tile froze empty.
	# Up to 40 s now; a real picture is there in well under a second on any graphics card.)
	var checks := 0
	while _stages.has(key) and not _live.has(key) and checks < 80 and _blank(_stages[key]):
		checks += 1
		(_stages[key] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await get_tree().create_timer(0.5).timeout
	if _stages.has(key) and not _live.has(key):
		(_stages[key] as SubViewport).render_target_update_mode = SubViewport.UPDATE_DISABLED
		_awake(key, false)


## True when a portrait's picture is still empty: a few points down the middle are all see-through.
func _blank(vp: SubViewport) -> bool:
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return true
	var w := img.get_width()
	var h := img.get_height()
	for fy in [0.3, 0.45, 0.6, 0.75, 0.9]:
		for fx in [0.35, 0.5, 0.65]:
			if img.get_pixel(int(w * fx), int(h * fy)).a > 0.05:
				return false
	return true


## A portrait that holds its last frame has nobody to move for: its little stage (the model's
## animation, its blinking) is put to sleep with it. Before, every portrait ever shown kept
## animating its skeleton behind the scenes on every frame, drawn or not: two dozen bodies
## skinned for nothing while you walked around.
func _framed(key: String) -> bool:
	var vp: SubViewport = _stages.get(key)
	if vp == null or vp.get_child_count() == 0:
		return true
	return bool(vp.get_child(0).get("framed"))


func _awake(key: String, on: bool) -> void:
	var vp: SubViewport = _stages.get(key)
	if vp == null:
		return
	var want := Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if vp.process_mode != want:
		vp.process_mode = want


## Re-apply the profile's colors to the live player model.
func retint(key := "player") -> void:
	if _stages.has(key):
		var stage: Node = _stages[key].get_child(0)
		if stage.get("_model"):
			apply_tints(stage.get("_model"))


## (0.80.2) The file each portrait was made from, so a model dropped into the characters folder
## while the game is open replaces the stand-in's portrait (it kept the stand-in until a restart).
var _stage_path := {}
var _path_checked := {}       # key -> when its file was last looked for (msec)


## Has the file behind this portrait changed since it was made (a model dropped in or taken out)?
## Looked at once every few seconds per duelist: it asks the disk.
func file_changed(key: String) -> bool:
	if not _stages.has(key) or not _stage_path.has(key):
		return false
	var now := Time.get_ticks_msec()
	if now - int(_path_checked.get(key, -100000)) < 4000:
		return false
	_path_checked[key] = now
	return path_for(key.get_slice("@", 0)) != str(_stage_path[key])


func forget(key: String) -> void:
	_stage_path.erase(key)
	_live.erase(key)
	if _stages.has(key):
		_stages[key].queue_free()
		_stages.erase(key)


## A character is always drawn with every triangle it has, at any distance: the renderer is
## told never to pick a lighter version of its meshes (the bundled models carry some from
## the import). A missing head is far worse than a few more triangles.
func keep_whole(model: Node) -> void:
	if model == null:
		return
	for mi in _meshes(model):
		mi.lod_bias = 1000.0
		mi.extra_cull_margin = maxf(mi.extra_cull_margin, 1.0)


## A character takes no shadows, its own or the world's; it still casts one on the ground. On a model
## with few triangles the sun's shadow of the face fell back onto the face in hard, angular patches
## (a nose and two cheeks made of a few dozen triangles each): up close it looked disfigured.


func even_light(model: Node) -> void:
	if model == null:
		return
	for mi in _meshes(model):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if not (m is BaseMaterial3D) or (m as BaseMaterial3D).disable_receive_shadows:
				continue
			# (0.72.4) The twin is kept on the material itself, not in a list here: the list held
			# on to every material of every dropped-in model ever loaded, textures and all.
			# (That list also kept the bundled models' textures loaded once their people were gone,
			# which is why a second visit was quick: that job is now done on purpose, see _tpl.)
			var d: BaseMaterial3D = m.get_meta("even_twin") if m.has_meta("even_twin") else null
			if d == null:
				d = m.duplicate() as BaseMaterial3D
				d.disable_receive_shadows = true
				m.set_meta("even_twin", d)
			mi.set_surface_override_material(i, d)


# ------------------------------------------------------------------ lighter versions for distance
# Character models are loaded as they are: every figure is drawn with all of its triangles
# even when it is a few pixels tall at the far end of the street. Here each heavy mesh gets
# a set of lighter versions (LODs), worked out in the background, and the renderer switches
# between them by size on screen. Nothing changes up close.

var _lod_done := {}        # original mesh -> mesh with lighter versions
var _lod_busy := {}        # original mesh -> true while being worked out
var _lod_users := {}       # original mesh -> [WeakRef to a MeshInstance3D, ...]
const LOD_MIN_TRIS := 5000


func request_lods(model: Node) -> void:
	# Off. The lighter versions came out broken on real machines: at a few steps away figures
	# lost their heads and half their bodies. Characters are now always drawn whole (see
	# keep_whole). The code stays for "--char-lods", to look into it one day.
	if not "--char-lods" in OS.get_cmdline_user_args():
		return
	if model == null or _closing or DisplayServer.get_name() == "headless" or "--no-lods" in OS.get_cmdline_user_args():
		return
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var src := mi.mesh as ArrayMesh
		if src == null or src.has_meta("has_lods"):
			continue
		if _lod_done.has(src):
			mi.mesh = _lod_done[src]
			continue
		var users: Array = _lod_users.get(src, [])
		users.append(weakref(mi))
		_lod_users[src] = users
		if _lod_busy.has(src):
			continue
		var tris := 0
		for i in src.get_surface_count():
			var il := src.surface_get_array_index_len(i)
			tris += (il if il > 0 else src.surface_get_array_len(i)) / 3
		if tris < LOD_MIN_TRIS:
			src.set_meta("has_lods", true)
			_lod_users.erase(src)
			continue
		_lod_busy[src] = true
		# Read the mesh here (the main thread); the heavy part runs on a worker.
		var surfaces: Array = []
		for i in src.get_surface_count():
			if src.surface_get_primitive_type(i) != Mesh.PRIMITIVE_TRIANGLES:
				surfaces.clear()
				break
			surfaces.append([src.surface_get_arrays(i), src.surface_get_blend_shape_arrays(i), src.surface_get_material(i), src.surface_get_name(i),
				src.surface_get_format(i) & ~((1 << Mesh.ARRAY_MAX) - 1)])
		if surfaces.is_empty():
			src.set_meta("has_lods", true)
			continue
		var shapes: Array = []
		for b in src.get_blend_shape_count():
			shapes.append(src.get_blend_shape_name(b))
		var mode := src.blend_shape_mode
		_lod_tasks.append(WorkerThreadPool.add_task(_lod_work.bind(src, surfaces, shapes, mode)))


var _lod_tasks: Array = []
var _closing := false


## Leaving the game: let the workers finish before anything they touch is taken away.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		_closing = true
		for t in _lod_tasks:
			if not WorkerThreadPool.is_task_completed(t):
				WorkerThreadPool.wait_for_task_completion(t)
		_lod_tasks.clear()
		_fit_wait(true)
		if what != NOTIFICATION_WM_CLOSE_REQUEST:
			drop_kept_models()


func _lod_work(src: ArrayMesh, surfaces: Array, shapes: Array, mode: int) -> void:
	var im := ImporterMesh.new()
	for b in shapes:
		im.add_blend_shape(str(b))
	im.set_blend_shape_mode(mode)
	for su in surfaces:
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, su[0], su[1], {}, su[2], str(su[3]), int(su[4]))
	im.generate_lods(25.0, 60.0, [])
	if not _closing:
		_lod_ready.call_deferred(src, im)


func _lod_ready(src: ArrayMesh, im: ImporterMesh) -> void:
	if _closing:
		return
	var out := im.get_mesh()
	_lod_busy.erase(src)
	if out == null or out.get_surface_count() != src.get_surface_count():
		src.set_meta("has_lods", true)
		return
	out.set_meta("has_lods", true)
	for mk in src.get_meta_list():
		if mk != "has_lods":
			out.set_meta(mk, src.get_meta(mk))
	_lod_done[src] = out
	for w in _lod_users.get(src, []):
		var mi = (w as WeakRef).get_ref()
		if mi != null and is_instance_valid(mi) and (mi as MeshInstance3D).mesh == src:
			(mi as MeshInstance3D).mesh = out
	_lod_users.erase(src)
