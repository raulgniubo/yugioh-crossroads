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
]
## Hairstyles for body A and body B: [name, the model whose head it is].
const HAIRS := [
	[["Spikes", "hero_m1"], ["Bangs", "hero_m2"], ["Swept Back", "hero_m3"], ["Wild Mane", "hero_m4"]],
	[["Ponytail", "hero_f1"], ["Bob", "hero_f2"], ["Twin Tails", "hero_f3"], ["Long Waves", "hero_f4"]],
]
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


## Any model of that hairstyle will do for the head: they all carry the same head.
static func _head_model(body: int, hair: int) -> String:
	var stem := str(HAIRS[clampi(body, 0, 1)][clampi(hair, 0, 3)][1])
	for o in OUTFITS:
		if has_model("%s_%s" % [stem, o[2]]):
			return "%s_%s" % [stem, o[2]]
	return ""


## Which models make up a look: {"body": model, "head": model or "" when the body's own head is the one}.
static func models(body: int, hair: int, outfit: int) -> Dictionary:
	var b := clampi(body, 0, 1)
	var o := str(OUTFITS[clampi(outfit, 0, OUTFITS.size() - 1)][2])
	var stem := str(HAIRS[b][clampi(hair, 0, 3)][1])
	if has_model("%s_%s" % [stem, o]):
		return {"body": "%s_%s" % [stem, o], "head": ""}
	var base := ""
	for s in HAIRS[b]:
		if has_model("%s_%s" % [s[1], o]):
			base = "%s_%s" % [s[1], o]
			break
	if base == "":
		# That outfit is not made for this body: fall back to the street clothes.
		return models(body, hair, 0) if outfit != 0 else {"body": "hero_m1_street", "head": ""}
	var head := _head_model(b, hair)
	return {"body": base, "head": head if head != "" and head != base else ""}


static func _col(list: Array, i: int) -> Color:
	var hex := str(list[clampi(i, 0, list.size() - 1)][1])
	return Color(0, 0, 0, 0) if hex == "" else Color(hex)


static func _make_shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform sampler2D mask : filter_nearest;
uniform vec4 skin_to : source_color = vec4(0.0);
uniform vec4 hair_to : source_color = vec4(0.0);
uniform vec4 top_to : source_color = vec4(0.0);
uniform vec4 bottom_to : source_color = vec4(0.0);
uniform vec4 shoes_to : source_color = vec4(0.0);
uniform vec4 eyes_to : source_color = vec4(0.0);
uniform vec4 accent_to : source_color = vec4(0.0);
uniform vec3 skin_ref = vec3(0.6);
uniform vec3 hair_ref = vec3(0.5);
uniform vec3 top_ref = vec3(0.5);
uniform vec3 bottom_ref = vec3(0.5);
uniform vec3 shoes_ref = vec3(0.5);
uniform int part = 0;            // 0 everything, 1 the body without its head, 2 only the head
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
	vec4 t = texture(tex, UV);
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
		c = paint(c, skin_ref, skin_to);
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
	_paint(scene, model, 1 if head_model != "" else 0, mats)
	if head_model != "":
		var head := _attach_head(scene, head_model)
		if head != null:
			_paint(head, head_model, 2, mats)
		else:
			for m in mats:
				(m as ShaderMaterial).set_shader_parameter("part", 0)
	scene.set_meta("hero_mats", mats)
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
static func _attach_head(scene: Node, head_model: String) -> MeshInstance3D:
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
	head.mesh = src.mesh
	head.skin = src.skin
	body.get_parent().add_child(head)
	head.transform = src.transform
	head.skeleton = body.skeleton
	head.lod_bias = 1000.0
	# The two bodies are not built exactly alike; this is how far the donor's head bone sits
	# from where this body's is, kept for anyone who needs it (the portrait camera).
	donor.free()
	return head


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
