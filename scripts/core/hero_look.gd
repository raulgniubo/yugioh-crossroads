class_name HeroLook
extends RefCounted
## Everything about how your own duelist looks: the hairstyle and outfit models, and the paint
## on top of them (skin, hair, eyes, top, bottom, shoes and your signature color). Each built-in
## hero model comes with a mask picture (made by tools/hero_masks.py) that says which pixel is
## what and which triangles are the head, so any hairstyle can sit on any outfit and every part
## can take any color while keeping its folds and shading.

## [name, color]. The first entry of every list keeps what the model was painted with.
const SKIN := [["Natural", ""], ["Porcelain", "f7e4d8"], ["Fair", "f1cfb6"], ["Warm", "e7b795"], ["Tan", "d3a17a"],
	["Honey", "c28c5e"], ["Bronze", "aa7345"], ["Brown", "8b5b3b"], ["Deep", "6c422a"], ["Ebony", "4b2d1d"]]
const HAIR := [["Natural", ""], ["Black", "1b1b21"], ["Dark brown", "3a2517"], ["Brown", "6a4325"], ["Auburn", "8b3a1f"],
	["Red", "c2332b"], ["Orange", "f0872a"], ["Blond", "e9c66b"], ["Platinum", "ebe7dc"], ["Silver", "b8bfcb"],
	["Navy", "1e2b54"], ["Blue", "2f6fe0"], ["Teal", "1fa4a0"], ["Green", "3fa65b"], ["Purple", "7a4fd8"], ["Pink", "f08fc0"]]
const EYES := [["Natural", ""], ["Brown", "7a4a22"], ["Amber", "d9952b"], ["Green", "3fae5d"], ["Teal", "25b8b0"],
	["Blue", "3a7be8"], ["Gray", "8f9bb0"], ["Violet", "8a55e0"], ["Red", "d43a3a"]]
const CLOTH := [["Original", ""], ["White", "f2f2ee"], ["Silver", "b9bec8"], ["Charcoal", "3a3d46"], ["Black", "15161a"],
	["Navy", "1f2c57"], ["Blue", "2f6fe0"], ["Sky", "6fc3ff"], ["Teal", "1fa4a0"], ["Green", "3fa65b"], ["Olive", "6d7a3a"],
	["Yellow", "f2c230"], ["Orange", "f0872a"], ["Red", "d9342b"], ["Crimson", "8f1d2c"], ["Pink", "f08fc0"],
	["Purple", "7a4fd8"], ["Brown", "6a4325"], ["Tan", "c9a877"]]
## Kid, Teen, Grown-up: [name, how tall next to the model as made, how big the head is on it].
const BUILDS := [["Kid", 0.76, 1.22], ["Teen", 1.0, 1.0], ["Grown-up", 1.07, 0.93]]
const HEIGHTS := [["Very short", 0.9], ["Short", 0.95], ["Average", 1.0], ["Tall", 1.05], ["Very tall", 1.1]]
## Outfits: [name, series it belongs to, model name, the dorm colors apply].
const OUTFITS := [
	["Street Duelist", "Duel Monsters", "street", false],
	["Academy Blazer", "GX", "academy", true],
	["Turbo Rider", "5D's", "rider", false],
	["Satellite Jacket", "5D's", "satellite", false],
	["Heartland Casual", "ZEXAL", "heartland", false],
	# Added later: always append, never reorder (saves keep the index).
	["Trench Coat", "Duel Monsters", "trench", false],
	["Varsity Jacket", "Duel Monsters", "varsity", false],
	["Vest and Tie", "Duel Monsters", "vest", false],
	["Track Jacket", "GX", "track", false],
	["Island Casual", "GX", "island", false],
	["Academy Cardigan", "GX", "cardigan", true],
	["Duster Coat", "5D's", "duster", false],
	["Mechanic Overalls", "5D's", "mechanic", false],
	["Windbreaker", "ZEXAL", "sporty", false],
	["Neon Coat", "ZEXAL", "neon", false],
	["City School Uniform", "ZEXAL", "school", false],
]
## The series, in the order the editor shows them.
const SERIES := ["Duel Monsters", "GX", "5D's", "ZEXAL"]
## The first outfits were made on every hairstyle's own body, head and all; the ones after them
## are made once per body and always take the hairstyle's head from its own model.
const OWN_HEAD := ["street", "academy", "rider", "satellite", "heartland"]
## Hairstyles for body A and body B: [name, the model whose head it is]. A head-only model is
## "<stem>_hair"; the first four of each body wear their own outfits. Append only.
const HAIRS := [
	[["Spikes", "hero_m1"], ["Bangs", "hero_m2"], ["Swept Back", "hero_m3"], ["Wild Mane", "hero_m4"],
		["Curly Top", "hero_m5"], ["Buzz Cut", "hero_m6"], ["Side Part", "hero_m7"], ["Messy Shag", "hero_m8"],
		["Top Knot", "hero_m9"], ["Tied Back", "hero_m10"], ["Layered Fringe", "hero_m11"], ["Short Twists", "hero_m12"]],
	[["Ponytail", "hero_f1"], ["Bob", "hero_f2"], ["Twin Tails", "hero_f3"], ["Long Waves", "hero_f4"],
		["Side Braid", "hero_f5"], ["Pixie Cut", "hero_f6"], ["High Bun", "hero_f7"], ["Long Straight", "hero_f8"],
		["Shoulder Curls", "hero_f9"], ["Double Buns", "hero_f10"], ["Short Layers", "hero_f11"], ["Half-Up", "hero_f12"]],
]
const MAX_HAIRS := 12
## Whose body wears a borrowed head, first choice first: a short hairstyle leaves the cleanest neck.
const BASES := [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]]
## Duel Academy dorm jackets: a one-press choice for the blazer's color.
const DORMS := [["Red", "d9342b"], ["Yellow", "f2c230"], ["Blue", "2f6fe0"]]
const PEOPLE := "res://assets/models/people/"

static var _shader: Shader


static func has_model(name: String) -> bool:
	return ResourceLoader.exists(PEOPLE + name + ".glb") and ResourceLoader.exists(PEOPLE + "masks/" + name + ".png")


## The outfits and hairstyles whose models are in this build (new ones can be added later).
static func outfits() -> Array:
	var out: Array = []
	for i in OUTFITS.size():
		if has_model("hero_m1_" + str(OUTFITS[i][2])) or has_model("hero_f1_" + str(OUTFITS[i][2])):
			out.append(i)
	return out


static func hairs(body: int) -> Array:
	var out: Array = []
	var list: Array = HAIRS[clampi(body, 0, 1)]
	for i in list.size():
		if _head_model(body, i) != "":
			out.append(i)
	return out


## Any model of that hairstyle will do for the head: they all carry the same head. A head-only
## model ("<stem>_hair") comes first.
static func _head_model(body: int, hair: int) -> String:
	var list: Array = HAIRS[clampi(body, 0, 1)]
	var stem := str(list[clampi(hair, 0, list.size() - 1)][1])
	if has_model(stem + "_hair"):
		return stem + "_hair"
	for o in OWN_HEAD:
		if has_model("%s_%s" % [stem, o]):
			return "%s_%s" % [stem, o]
	return ""


## Which models make up a look: {"body": model, "head": model or "" when the body's own head is the one}.
static func models(body: int, hair: int, outfit: int) -> Dictionary:
	var b := clampi(body, 0, 1)
	var list: Array = HAIRS[b]
	var o := str(OUTFITS[clampi(outfit, 0, OUTFITS.size() - 1)][2])
	var stem := str(list[clampi(hair, 0, list.size() - 1)][1])
	if OWN_HEAD.has(o) and has_model("%s_%s" % [stem, o]):
		return {"body": "%s_%s" % [stem, o], "head": ""}
	var base := ""
	for k in BASES[b]:
		var s: Array = list[k]
		if has_model("%s_%s" % [s[1], o]):
			base = "%s_%s" % [s[1], o]
			break
	if base == "":
		# That outfit is not made for this body: fall back to the street clothes.
		return models(body, hair, 0) if outfit != 0 else {"body": "hero_m1_street", "head": ""}
	var head := _head_model(b, hair)
	return {"body": base, "head": head if head != "" and head != base else ""}


## The outfits made for this body, in OUTFITS order.
static func outfits_for(body: int) -> Array:
	var out: Array = []
	for i in OUTFITS.size():
		for s in HAIRS[clampi(body, 0, 1)]:
			if has_model("%s_%s" % [s[1], OUTFITS[i][2]]):
				out.append(i)
				break
	return out


static func _col(list: Array, i: int) -> Color:
	var hex := str(list[clampi(i, 0, list.size() - 1)][1])
	return Color(0, 0, 0, 0) if hex == "" else Color(hex)


static func _make_shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type spatial;
render_mode shadows_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform sampler2D mask : filter_nearest;
uniform vec4 skin_to : source_color = vec4(0.0);
uniform vec4 hair_to : source_color = vec4(0.0);
uniform vec4 top_to : source_color = vec4(0.0);
uniform vec4 bottom_to : source_color = vec4(0.0);
uniform vec4 shoes_to : source_color = vec4(0.0);
uniform vec4 eyes_to : source_color = vec4(0.0);
uniform vec4 accent_to : source_color = vec4(0.0);
uniform vec3 skin_gain = vec3(1.0);   // a borrowed head: the tint that matches the body's skin
uniform vec3 skin_ref = vec3(0.6);
uniform vec3 hair_ref = vec3(0.5);
uniform vec3 top_ref = vec3(0.5);
uniform vec3 bottom_ref = vec3(0.5);
uniform vec3 shoes_ref = vec3(0.5);
uniform int part = 0;            // 0 everything, 1 the body without its head, 2 only the head
uniform int debug_ids = 0;       // dev: 1 shows each mask region in a flat color
// The pictures are many small islands packed edge to edge: the small mipmaps of a far-away hero
// blend neighbouring islands together, which drew grey and dark specks and lines across the face.
// Never going past this mipmap keeps every island its own color (1.5: up to about 3x smaller).
uniform float lod_max = 1.5;
uniform float face_flat = 0.7;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
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
// The new color, with the folds and shading the painted one had.
vec3 paint(vec3 c, vec3 ref, vec4 to) {
	if (to.a < 0.5) {
		return c;
	}
	float k = clamp(pow(dot(c, LUMA) / max(dot(ref, LUMA), 0.004), 0.8), 0.3, 1.5);
	// Very dark paint keeps a little of the light the folds caught, so black is not a flat hole.
	return clamp(to.rgb * k + vec3(0.012) * max(k - 1.0, 0.0), 0.0, 1.0);
}
vec3 rehue(vec3 c, vec4 to) {
	if (to.a < 0.5) {
		return c;
	}
	vec3 h = rgb2hsv(c);
	vec3 t = rgb2hsv(to.rgb);
	return hsv2rgb(vec3(t.x, clamp(h.y * mix(1.0, t.y / 0.8, 0.8), 0.0, 1.0), clamp(h.z * mix(1.0, t.z / 0.8, 0.6), 0.0, 1.0)));
}
void fragment() {
	vec2 tsz = vec2(textureSize(tex, 0));
	float lod = log2(max(max(length(dFdx(UV * tsz)), length(dFdy(UV * tsz))), 1e-6));
	vec4 t = textureLod(tex, UV, clamp(lod, 0.0, lod_max));
	vec2 m = texture(mask, UV).rg;
	if (part == 1 && m.g > 0.75) {
		discard;
	}
	if (part == 2 && m.g < 0.25) {
		discard;
	}
	float id = m.r * 255.0;
	vec3 c = t.rgb;
	if (abs(id - 40.0) < 12.0) {
		c = paint(min(c * skin_gain, vec3(1.0)), skin_ref * skin_gain, skin_to);
		// Faces are drawn flat, the way the art is: light that follows every small bump of a
		// generated face shows lumps around the nose and mouth.
		if (m.g > 0.75) {
			NORMAL = normalize(mix(NORMAL, VIEW, face_flat));
		}
	} else if (abs(id - 80.0) < 12.0) {
		c = paint(c, hair_ref, hair_to);
	} else if (abs(id - 120.0) < 12.0) {
		c = paint(c, top_ref, top_to);
	} else if (abs(id - 160.0) < 12.0) {
		c = paint(c, bottom_ref, bottom_to);
	} else if (abs(id - 200.0) < 9.0) {
		c = paint(c, shoes_ref, shoes_to);
	} else if (abs(id - 220.0) < 9.0) {
		c = rehue(c, eyes_to);
	} else if (id > 231.0) {
		c = rehue(c, accent_to);
	}
	if (debug_ids == 1) {
		c = id < 20.0 ? vec3(0.0) : (abs(id - 40.0) < 12.0 ? vec3(1.0, 0.8, 0.6) : (abs(id - 80.0) < 12.0 ? vec3(0.1, 0.9, 0.1) : (abs(id - 120.0) < 12.0 ? vec3(0.1, 0.2, 1.0) : (abs(id - 160.0) < 12.0 ? vec3(0.6, 0.0, 0.6) : (abs(id - 200.0) < 9.0 ? vec3(0.5, 0.3, 0.0) : (abs(id - 220.0) < 9.0 ? vec3(1.0, 1.0, 0.0) : (id > 231.0 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 1.0))))))));
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
"""
	return _shader


## The colors of a look, as the shader wants them. `p` is Profile, or a Dictionary with the same names.
static func colors(p) -> Dictionary:
	return {
		"skin_to": _col(SKIN, int(p.get("look_skin"))),
		"hair_to": _col(HAIR, int(p.get("look_haircol"))),
		"eyes_to": _col(EYES, int(p.get("look_eyes"))),
		"top_to": _col(CLOTH, int(p.get("look_top"))),
		"bottom_to": _col(CLOTH, int(p.get("look_bottom"))),
		"shoes_to": _col(CLOTH, int(p.get("look_shoes"))),
	}


## Dress a freshly loaded hero body model. `scene` is the model, `model` its name. Adds the head
## of another model when the hairstyle is not the body's own.
static func apply(scene: Node, model: String, head_model: String, p, accent: Color) -> void:
	var mats: Array = []
	var head: MeshInstance3D = null
	var body_mesh: Dictionary = {}
	if head_model != "":
		head = _attach_head(scene, head_model, _neck_cut(model))
	if head != null:
		# The body without its own head and the borrowed head without its body are cut along whole
		# triangles (not pixel by pixel in the shader, which left sawtooth edges at the neck).
		var sk := Avatars._skeleton(scene)
		for mi in Avatars._meshes(scene):
			if mi != head and mi.mesh != null:
				body_mesh[mi] = mi.mesh
				mi.mesh = _cut(mi.mesh, mi.skin, sk, model, 1, _neck_cut(model))
	_paint(scene, model, 0, mats)
	if head != null:
		var hm: Array = []
		_paint(head, head_model, 0, hm)
		# The borrowed face takes the tint of the body's skin (the neck below it is the body's own),
		# with the light and shade it was painted with. Its brightness moves only halfway, so a fair
		# face on a tanned body (or the other way round) keeps its drawing.
		var r: Color = _necks.get("%s/1/%.3f" % [model, _neck_cut(model)], Color(0, 0, 0, 0))
		var d: Color = _necks.get("%s/2/%.3f" % [head_model, _neck_cut(model)], Color(0, 0, 0, 0))
		if r.a > 0.0 and d.a > 0.0:
			var g := Vector3(r.r / maxf(d.r, 0.02), r.g / maxf(d.g, 0.02), r.b / maxf(d.b, 0.02))
			var gl := g.x * 0.2126 + g.y * 0.7152 + g.z * 0.0722
			# only a nudge of the tint, half of the way: the brightness stays the face's own
			g = (Vector3.ONE + g / maxf(gl, 0.01)) * 0.5
			g = g.clamp(Vector3.ONE * 0.9, Vector3.ONE * 1.12)
			if OS.has_environment("HERO_CUT_DEBUG"):
				print("HEROSKIN body %s head %s gain %s" % [model, head_model, g])
			for m in hm:
				(m as ShaderMaterial).set_shader_parameter("skin_gain", g)
		mats.append_array(hm)
	if head != null and OS.get_environment("HERO_ONLY") != "":
		# dev: see one of the two parts alone
		head.visible = OS.get_environment("HERO_ONLY") == "head"
		for mi in body_mesh:
			(mi as MeshInstance3D).visible = OS.get_environment("HERO_ONLY") == "body"
	scene.set_meta("hero_mats", mats)
	scene.set_meta("hero_body", model)
	recolor(scene, p, accent)
	_build(scene, int(p.get("look_build")))


static func _paint(node: Node, model: String, part: int, mats: Array) -> void:
	var mask_path := PEOPLE + "masks/" + model + ".png"
	if not ResourceLoader.exists(mask_path):
		return
	var mask: Texture2D = load(mask_path)
	var refs: Dictionary = HeroMasks.REFS.get(model, {})
	var list: Array = [node] if node is MeshInstance3D else Array(Avatars._meshes(node))
	for mi in list:
		if (mi as MeshInstance3D).mesh == null:
			continue
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			var mat := (mi as MeshInstance3D).mesh.surface_get_material(i)
			if not (mat is BaseMaterial3D) or (mat as BaseMaterial3D).albedo_texture == null:
				continue
			var sm := ShaderMaterial.new()
			sm.shader = _make_shader()
			sm.set_shader_parameter("tex", (mat as BaseMaterial3D).albedo_texture)
			sm.set_shader_parameter("mask", mask)
			sm.set_shader_parameter("part", part)
			for k in ["skin", "hair", "top", "bottom", "shoes"]:
				var r: Color = refs.get(k, Color(0.5, 0.5, 0.5))
				sm.set_shader_parameter(k + "_ref", Vector3(r.r, r.g, r.b))
			# The signature color starts from teal (orange on the rider suit); the eyes keep
			# their own color unless one is picked.
			(mi as MeshInstance3D).set_surface_override_material(i, sm)
			mats.append(sm)


## Put new colors on a hero that is already standing there. No model is loaded again.
static func recolor(scene: Node, p, accent: Color) -> void:
	var cols := colors(p)
	for m in scene.get_meta("hero_mats", []):
		for k in cols:
			(m as ShaderMaterial).set_shader_parameter(k, cols[k])
		(m as ShaderMaterial).set_shader_parameter("accent_to", Color(accent.r, accent.g, accent.b, 1.0))


## Another model's head and hair, riding on this body's skeleton. Both come from the same rig,
## so the head sits on the head bone exactly as it did on its own body.
static func _attach_head(scene: Node, head_model: String, neck := 0.03) -> MeshInstance3D:
	var ps = load(PEOPLE + head_model + ".glb")
	if not (ps is PackedScene):
		return null
	var donor: Node = (ps as PackedScene).instantiate()
	var dmis := Avatars._meshes(donor)
	var bmis := Avatars._meshes(scene)
	var dsk := Avatars._skeleton(donor)
	var sk := Avatars._skeleton(scene)
	if dmis.is_empty() or bmis.is_empty() or dsk == null or sk == null or dsk.get_bone_count() != sk.get_bone_count():
		donor.free()
		return null
	for b in sk.get_bone_count():
		if sk.get_bone_name(b) != dsk.get_bone_name(b):
			donor.free()
			return null
	var src: MeshInstance3D = dmis[0]
	var body: MeshInstance3D = bmis[0]
	var head := MeshInstance3D.new()
	head.name = "HeroHead"
	head.mesh = _cut(src.mesh, src.skin, dsk, head_model, 2, neck)
	head.skin = _rigid_skin(src.skin, dsk, sk)
	body.get_parent().add_child(head)
	head.transform = src.transform
	head.skeleton = body.skeleton
	head.lod_bias = 1000.0
	# The two bodies are not built exactly alike; this is how far the donor's head bone sits
	# from where this body's is, kept for anyone who needs it (the portrait camera).
	donor.free()
	return head


## The donor's skin, re-bound so its whole head moves to this body's head bone as one piece.
## (Bound straight to this skeleton, the parts weighted to the neck would follow this body's neck
## and the parts on the head its head; when the two bodies differ that stretched the face.)
static func _rigid_skin(dskin: Skin, dsk: Skeleton3D, sk: Skeleton3D) -> Skin:
	if dskin == null:
		return null
	var hb := sk.find_bone("Head")
	var dhb := dsk.find_bone("Head")
	if hb < 0 or dhb < 0:
		return dskin
	var t := Transform3D(Basis(), sk.get_bone_global_rest(hb).origin - dsk.get_bone_global_rest(dhb).origin)
	var out := Skin.new()
	for i in dskin.get_bind_count():
		var bone := dskin.get_bind_bone(i)
		var bname := String(dskin.get_bind_name(i))
		var db := bone if bone >= 0 else dsk.find_bone(bname)
		var b := bone if bone >= 0 else sk.find_bone(bname)
		if db < 0 or b < 0:
			return dskin
		# donor mesh space -> donor skeleton space, moved head to head, then into this bone's rest
		var to_skel := dsk.get_bone_global_rest(db) * dskin.get_bind_pose(i)
		# The face bones (head_end, headfront) ride on the head: some borrowed idle clips move them,
		# which pulled the nose and mouth of a borrowed face out of shape.
		if String(dsk.get_bone_name(db)) in ["head_end", "headfront"]:
			b = hb
		out.add_bind(b, sk.get_bone_global_rest(b).affine_inverse() * t * to_skel)
	return out


## Kid, Teen or Grown-up: the whole figure is scaled, and the head keeps more of its size the
## younger the build, the way people are actually proportioned.
static func _build(scene: Node, build: int) -> void:
	var b: Array = BUILDS[clampi(build, 0, BUILDS.size() - 1)]
	var sk := Avatars._skeleton(scene)
	if scene is Node3D:
		(scene as Node3D).scale *= float(b[1])
	if sk == null or is_equal_approx(float(b[2]), 1.0):
		return
	var bi := sk.find_bone("Head")
	if bi < 0:
		return
	var mod := HeroBuild.new()
	mod.name = "HeroBuild"
	mod.scales = {bi: Vector3.ONE * float(b[2])}
	sk.add_child(mod)


static var _cuts := {}
## Where the borrowed neck takes over from the body's (meters under the head bone). A body whose
## own neck is ragged under the jaw hands more of it to the head.
## How far under the head bone a short hairstyle's hair can reach (meters); below that, what the
## mask took for hair is the donor's dark shirt.
const HAIR_DEPTH := {"hero_m5_hair": 0.05, "hero_m6_hair": 0.05, "hero_m7_hair": 0.05, "hero_m8_hair": 0.05, "hero_m9_hair": 0.05, "hero_m12_hair": 0.05, "hero_f6_hair": 0.05}
const NECK_CUT := {"hero_f1_street": 0.07, "hero_f1_heartland": 0.08, "hero_f1_satellite": 0.06}


static func _neck_cut(body: String) -> float:
	return float(NECK_CUT.get(body, 0.03))
static var _necks := {}


## A copy of a hero mesh with only some of its triangles: role 1 the body without its head (and
## without any stray bit of its own hair), role 2 only the head and hair (no collar, no neck below
## the jaw, no loose shards floating around it). Worked out once per model from its mask.
static func _cut(mesh: Mesh, skin: Skin, sk: Skeleton3D, model: String, role: int, neck: float) -> Mesh:
	var key := "%s/%d/%.3f" % [model, role, neck]
	if _cuts.has(key):
		return _cuts[key]
	var t0 := Time.get_ticks_msec()
	var mask_path := PEOPLE + "masks/" + model + ".png"
	if mesh == null or skin == null or sk == null or not ResourceLoader.exists(mask_path):
		return mesh
	var img: Image = (load(mask_path) as Texture2D).get_image()
	if img == null:
		return mesh
	if img.is_compressed():
		img.decompress()
	var hb := sk.find_bone("Head")
	if hb < 0:
		return mesh
	var head_group := PackedInt32Array()
	var bind_bone := PackedInt32Array()
	var to_sk := Transform3D()
	for i in skin.get_bind_count():
		var b := skin.get_bind_bone(i)
		if b < 0:
			b = sk.find_bone(skin.get_bind_name(i))
		bind_bone.append(b)
		if b == hb:
			to_sk = sk.get_bone_global_rest(b) * skin.get_bind_pose(i)
		head_group.append(1 if b >= 0 and String(sk.get_bone_name(b)) in ["Head", "head_end", "headfront"] else 0)
	var hpos := sk.get_bone_global_rest(hb).origin
	# these rigs are in centimeters; every distance below is in meters
	var u := 100.0 if hpos.y > 20.0 else 1.0

	var mw := img.get_width()
	var mh := img.get_height()
	var out := ArrayMesh.new()
	for si in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(si)
		var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var wts: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var nv := pos.size()
		if idx.is_empty() or uv.size() != nv or bones.is_empty():
			return mesh
		var per := bones.size() / nv
		# per vertex: on a head bone, the mask's G and R where it sits, its place by the skeleton
		var vhead := PackedByteArray()
		vhead.resize(nv)
		var vg := PackedByteArray()
		vg.resize(nv)
		var vr := PackedByteArray()
		vr.resize(nv)
		var vp := PackedVector3Array()
		vp.resize(nv)
		for v in nv:
			var best := 0
			for k in per:
				if wts[v * per + k] > wts[v * per + best]:
					best = k
			var bi := bones[v * per + best]
			vhead[v] = head_group[bi] if bi < head_group.size() else 0
			var c := img.get_pixel(clampi(int(uv[v].x * mw), 0, mw - 1), clampi(int(uv[v].y * mh), 0, mh - 1))
			vg[v] = int(c.g * 255.0)
			vr[v] = int(c.r * 255.0)
			vp[v] = to_sk * pos[v]
		var nt := idx.size() / 3
		var keep := PackedByteArray()
		keep.resize(nt)
		for t in nt:
			var a := idx[t * 3]
			var b := idx[t * 3 + 1]
			var c := idx[t * 3 + 2]
			var cu := (uv[a] + uv[b] + uv[c]) / 3.0
			var cc := img.get_pixel(clampi(int(cu.x * mw), 0, mw - 1), clampi(int(cu.y * mh), 0, mh - 1))
			var cen := (vp[a] + vp[b] + vp[c]) / 3.0
			var on_head := int(vhead[a]) + int(vhead[b]) + int(vhead[c]) >= 2
			if role == 1:
				var g := int(vg[a] > 191) + int(vg[b] > 191) + int(vg[c] > 191) + int(cc.g > 0.75)
				var kind := _kind(int(cc.r * 255.0))
				# its face and hair go; a collar stays even where it sits on the head bone
				var eyes: bool = absi(int(cc.r * 255.0) - 220) < 9
				# its hair and face go (the neck's skin from a little under the jaw, where the
				# borrowed neck overlaps it); a collar stays even where it rides the head bone
				var drop: bool = g >= 2 and (kind == 1 or eyes or (kind == 2 and cen.y > hpos.y - neck * u) or (kind == 0 and cen.y > hpos.y - 0.01 * u and cen.z - hpos.z > 0.03 * u) or cen.y > hpos.y + 0.02 * u)
				# anything of its own left on the head bone off to the side or above the jaw: the
				# tips of a tail, a strand by the ear
				if on_head and (Vector2(cen.x - hpos.x, cen.z - hpos.z).length() > 0.13 * u or cen.y > hpos.y + 0.05 * u):
					drop = true
				# the skin of its neck above the handover, all of it (bits the mask left on the body
				# would show between the borrowed neck and the collar)
				if kind == 2 and cen.y > hpos.y - neck * u and Vector2(cen.x - hpos.x, cen.z - hpos.z).length() < 0.07 * u:
					drop = true
				# unmarked slivers above the collar (the underside of its own hair)
				if kind == 0 and cen.y > hpos.y and Vector2(cen.x - hpos.x, cen.z - hpos.z).length() < 0.2 * u:
					drop = true
				# and any strand of its own hair around the head, however the mask marked it
				if kind == 1 and cen.y > hpos.y - 0.04 * u and Vector2(cen.x - hpos.x, cen.z - hpos.z).length() < 0.16 * u:
					drop = true
				keep[t] = 0 if drop else 1
			else:
				var g2 := int(vg[a] >= 64) + int(vg[b] >= 64) + int(vg[c] >= 64) + int(cc.g >= 0.25)
				var kind := _kind(int(cc.r * 255.0))
				# a head-only model's neck counts as its body in the mask: its skin under the jaw
				# comes along all the same, to overlap the body's own neck
				# the mask's own say at the middle of the triangle counts: strands it left out in
				# front of the face (G 0) stay out
				var ok := (g2 >= 2 and cc.g >= 0.25) or (kind == 2 and cen.y > hpos.y - (neck + 0.012) * u and cen.y < hpos.y + 0.03 * u and Vector2(cen.x - hpos.x, cen.z - hpos.z).length() < 0.07 * u)
				# under the jaw: the hair, and the neck's skin down to where the body's own neck
				# takes over; never the donor's collar or shirt
				# a short hairstyle has no hair under the neck: anything dark down there is its shirt
				if ok and kind == 1 and HAIR_DEPTH.has(model) and (cen.y < hpos.y - float(HAIR_DEPTH[model]) * u or not on_head):
					ok = false
				# unmarked bits around the neck (folds where the hair met it) stay out
				if ok and kind == 0 and cen.y < hpos.y + 0.02 * u:
					ok = false
				if ok and cen.y < hpos.y and kind != 1 and kind != 3:
					ok = kind == 2 and cen.y > hpos.y - (neck + 0.012) * u
				keep[t] = 1 if ok else 0
		if role == 2:
			_drop_folds(idx, keep, vp, vr, hpos, u)
			_drop_shards(idx, keep, vp, vr, hpos, u)
		# the usual color of the skin where body and head meet (the body's neck under the jaw, the
		# head's chin and neck), so the head can take the body's tint
		var tex: Texture2D = null
		var mat := mesh.surface_get_material(si)
		if mat is BaseMaterial3D:
			tex = (mat as BaseMaterial3D).albedo_texture
		if tex != null and not _necks.has(key):
			var ti := tex.get_image()
			if ti != null and ti.is_compressed():
				ti.decompress()
			if ti != null and not ti.is_compressed():
				var sum := Vector3.ZERO
				var cnt := 0
				var tw := ti.get_width()
				var th := ti.get_height()
				var lo := hpos.y - (0.1 if role == 1 else 0.075) * u
				var hi := hpos.y - (0.04 if role == 1 else 0.02) * u
				for t in nt:
					if keep[t] == 0:
						continue
					var a := idx[t * 3]
					var cen := (vp[a] + vp[idx[t * 3 + 1]] + vp[idx[t * 3 + 2]]) / 3.0
					if cen.y < lo or cen.y > hi or abs(int(vr[a]) - 40) >= 12:
						continue
					var cu := (uv[a] + uv[idx[t * 3 + 1]] + uv[idx[t * 3 + 2]]) / 3.0
					var col := ti.get_pixel(clampi(int(cu.x * tw), 0, tw - 1), clampi(int(cu.y * th), 0, th - 1)).srgb_to_linear()
					sum += Vector3(col.r, col.g, col.b)
					cnt += 1
				if cnt >= 8:
					sum /= cnt
					_necks[key] = Color(sum.x, sum.y, sum.z, 1.0)
		var ni := PackedInt32Array()
		for t in nt:
			if keep[t] == 1:
				ni.append(idx[t * 3])
				ni.append(idx[t * 3 + 1])
				ni.append(idx[t * 3 + 2])
		if OS.has_environment("HERO_CUT_DEBUG"):
			print("HEROCUT %s role %d surface %d: %d of %d triangles, %d ms" % [model, role, si, ni.size() / 3, nt, Time.get_ticks_msec() - t0])
		arr[Mesh.ARRAY_INDEX] = ni
		var fmt: int = mesh.surface_get_format(si)
		var flags: int = fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		out.surface_set_material(si, mesh.surface_get_material(si))
	_cuts[key] = out
	return out


## Small loose pieces of a borrowed head (Meshy shards by the eyes, specks of a collar): any group of
## joined triangles much smaller than the head itself, unless it is an eye or skin.
static func _drop_shards(idx: PackedInt32Array, keep: PackedByteArray, vp: PackedVector3Array, vr: PackedByteArray, hpos: Vector3, u: float) -> void:
	var nt := keep.size()
	# the same point can be several vertices (seams in the picture): join them by place
	var weld := {}
	var root := PackedInt32Array()
	root.resize(vp.size())
	for v in vp.size():
		var q := Vector3i(roundi(vp[v].x * 1000.0), roundi(vp[v].y * 1000.0), roundi(vp[v].z * 1000.0))
		if weld.has(q):
			root[v] = weld[q]
		else:
			weld[q] = v
			root[v] = v
	var par := PackedInt32Array()
	par.resize(vp.size())
	for v in vp.size():
		par[v] = v
	var kept := 0
	for t in nt:
		if keep[t] == 0:
			continue
		kept += 1
		var a := _find(par, root[idx[t * 3]])
		for k in [1, 2]:
			var b := _find(par, root[idx[t * 3 + k]])
			if a != b:
				par[b] = a
	var size := {}
	var eye := {}
	var mid := {}
	for t in nt:
		if keep[t] == 1:
			var r := _find(par, root[idx[t * 3]])
			size[r] = int(size.get(r, 0)) + 1
			mid[r] = (mid.get(r, Vector3.ZERO) as Vector3) + vp[idx[t * 3]]
			var id := int(vr[idx[t * 3]])
			if abs(id - 40) < 12 or abs(id - 220) < 9:
				eye[r] = int(eye.get(r, 0)) + 1
	var small := maxi(12, int(kept * 0.01))
	for t in nt:
		if keep[t] == 1:
			var r := _find(par, root[idx[t * 3]])
			var n := int(size[r])
			# (pieces of the face itself, eyes and brows, are close to the middle of the head)
			var near: bool = ((mid[r] as Vector3) / n - hpos).length() < 0.2 * u
			if n < small and int(eye.get(r, 0)) * 2 < n and not near:
				keep[t] = 0


static func _find(par: PackedInt32Array, v: int) -> int:
	while par[v] != v:
		par[v] = par[par[v]]
		v = par[v]
	return v


## What a mask id is, for cutting: 1 hair, 2 skin, 3 eyes or accent (a hair streak), 4 clothes, 0 nothing.
static func _kind(id: int) -> int:
	if abs(id - 80) < 12:
		return 1
	if abs(id - 40) < 12:
		return 2
	if abs(id - 220) < 9 or id > 231:
		return 3
	if id > 20:
		return 4
	return 0


## The neck of a generated head is often folded in on itself where the hair met it: skin under the
## jaw that faces in toward the middle of the neck is the inside of a fold, never its outside.
static func _drop_folds(idx: PackedInt32Array, keep: PackedByteArray, vp: PackedVector3Array, vr: PackedByteArray, hpos: Vector3, u: float) -> void:
	var nt := keep.size()
	# which way the triangles of this mesh wind: the face looks forward
	var vote := 0.0
	for t in nt:
		if keep[t] == 0:
			continue
		var a := vp[idx[t * 3]]
		var cen := (a + vp[idx[t * 3 + 1]] + vp[idx[t * 3 + 2]]) / 3.0
		if cen.y > hpos.y + 0.02 * u and cen.z > hpos.z + 0.06 * u and abs(cen.x - hpos.x) < 0.03 * u:
			vote += signf((vp[idx[t * 3 + 1]] - a).cross(vp[idx[t * 3 + 2]] - a).z)
	if vote == 0.0:
		return
	var sgn := signf(vote)
	for t in nt:
		if keep[t] == 0 or absi(int(vr[idx[t * 3]]) - 40) >= 12:
			continue
		var a := vp[idx[t * 3]]
		var cen := (a + vp[idx[t * 3 + 1]] + vp[idx[t * 3 + 2]]) / 3.0
		if cen.y > hpos.y - 0.005 * u:
			continue
		var n := (vp[idx[t * 3 + 1]] - a).cross(vp[idx[t * 3 + 2]] - a) * sgn
		var radial := Vector2(cen.x - hpos.x, cen.z - hpos.z)
		var n2 := Vector2(n.x, n.z)
		if radial.length() < 0.004 * u or n2.length() < 1e-9:
			continue
		if n2.normalized().dot(radial.normalized()) < -0.3:
			keep[t] = 0
