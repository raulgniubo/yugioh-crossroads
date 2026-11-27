class_name Foil
## Card rarity looks. Rare cards get a soft silver sheen, Super Rares a gold one and Ultra
## Rares a moving rainbow, on flat cards (menus, packs) and on the 3D cards in a duel.

const NAMES := ["Common", "Rare", "Super Rare", "Ultra Rare"]
const COLORS := [Color(0.75, 0.8, 0.9), Color("7cc4ff"), Color("ffd166"), Color("ff7ad9")]

static var _flat: Shader
static var _solid: Shader


## Put the foil on a TextureRect (or clear it for commons).
## `id`: the card, when it is known. Lumen's cards (0.81.0) also get an edge of light that breathes.
static func apply(tr: CanvasItem, rarity: int, id := 0) -> void:
	var echo := id != 0 and CardData.LUMEN_CARDS.has(id)
	if rarity <= 0 and not echo:
		tr.material = null
		return
	if _flat == null:
		_flat = Shader.new()
		_flat.code = """
shader_type canvas_item;
uniform float rarity = 1.0;
uniform float phase = 0.0;
uniform float echo = 0.0;
vec3 rainbow(float t) {
	return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float band = UV.x * 1.4 + UV.y * 0.9 - TIME * 0.35 + phase;
	float sheen = pow(0.5 + 0.5 * sin(band * 6.28318), 6.0);
	vec3 tint = vec3(0.85, 0.92, 1.0);
	if (rarity > 2.5) {
		tint = rainbow(band * 0.5 + UV.y * 0.6);
	} else if (rarity > 1.5) {
		tint = vec3(1.0, 0.85, 0.45);
	}
	float sparkle = step(0.985, fract(sin(dot(floor(UV * vec2(46.0, 66.0)), vec2(12.9898, 78.233)) + floor(TIME * 3.0)) * 43758.5453));
	float amount = (rarity > 2.5 ? 0.42 : (rarity > 1.5 ? 0.34 : (rarity > 0.5 ? 0.22 : 0.0)));
	vec3 col = c.rgb + tint * sheen * amount + tint * sparkle * (rarity > 1.5 ? 0.5 : 0.0);
	if (rarity > 2.5) {
		col = mix(col, col * (0.75 + 0.5 * rainbow(UV.y * 1.2 - TIME * 0.2 + phase)), 0.22);
	}
	if (echo > 0.5) {
		// One of Lumen's: light along the card's edge, coming and going slowly.
		vec2 e = min(UV, 1.0 - UV) * vec2(1.0, 1.457);
		float rim = 1.0 - smoothstep(0.0, 0.055, min(e.x, e.y));
		col += vec3(0.45, 0.9, 1.0) * rim * rim * (0.45 + 0.4 * sin(TIME * 2.1 + phase * 6.28318));
	}
	COLOR = vec4(col, c.a) * COLOR;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _flat
	m.set_shader_parameter("rarity", float(rarity))
	m.set_shader_parameter("echo", 1.0 if echo else 0.0)
	m.set_shader_parameter("phase", randf())
	tr.material = m


## A see-through foil layer for a 3D card face (use as next_pass). Null for commons and rares.
static func layer_3d(rarity: int) -> ShaderMaterial:
	if rarity < 2:
		return null
	if _solid == null:
		_solid = Shader.new()
		_solid.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform float rarity = 2.0;
vec3 rainbow(float t) {
	return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}
void fragment() {
	vec3 v = normalize(VIEW);
	float tilt = dot(v, NORMAL);
	float band = UV.x * 1.3 + UV.y * 0.8 + tilt * 2.2 - TIME * 0.25;
	float sheen = pow(0.5 + 0.5 * sin(band * 6.28318), 5.0);
	vec3 tint = rarity > 2.5 ? rainbow(band * 0.5) : vec3(1.0, 0.82, 0.4);
	ALBEDO = tint * sheen * (rarity > 2.5 ? 0.30 : 0.22);
	ALPHA = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _solid
	m.set_shader_parameter("rarity", float(rarity))
	return m
