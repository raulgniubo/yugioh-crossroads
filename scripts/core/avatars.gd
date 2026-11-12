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
	"kid": "street_duelist", "vendor": "shopkeeper", "guard": "office_worker", "lumen": "student_girl",
}


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
	if src_name == "" or ap.has_animation("Calm_Idle"):
		return
	var src := ap.get_animation(src_name)
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
		var ti := a.add_track(src.track_get_type(t))
		a.track_set_path(ti, src.track_get_path(t))
		var v = src.track_get_key_value(t, 0)
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
		var r := Node3D.new()
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
func portrait(key: String) -> Texture2D:
	if _stages.has(key):
		_touch(key)
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
	_stages[key] = vp
	_touch(key)
	return vp.get_texture()


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
