class_name Toon
## Anime-style materials: two-tone cel shading, a soft rim light and an ink outline.

static var _shader: Shader
static var _outline_shader: Shader
static var _eye_shader: Shader
static var _cache := {}


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type spatial;
render_mode diffuse_toon, specular_toon;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade : source_color = vec4(0.62, 0.6, 0.75, 1.0);
uniform float rim = 0.35;
uniform vec4 rim_color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float gloss = 0.0;
uniform float fill = 0.12;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	// Anime look: a flat fill so the shadow side never goes muddy.
	EMISSION = emission.rgb + albedo.rgb * fill;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION += rim_color.rgb * smoothstep(0.5, 0.62, fres) * rim * 0.25;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.0, 0.06, ndl);
	vec3 base = mix(shade.rgb * 0.75, vec3(1.0), lit);
	DIFFUSE_LIGHT += base * LIGHT_COLOR * ATTENUATION / PI * 1.25;
	if (gloss > 0.0) {
		vec3 h = normalize(VIEW + LIGHT);
		float s = smoothstep(0.965, 0.975, dot(NORMAL, h)) * lit;
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * s * gloss * 0.35;
	}
}
"""
	return _shader


static func outline_shader() -> Shader:
	if _outline_shader == null:
		_outline_shader = Shader.new()
		_outline_shader.code = """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
uniform vec4 color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float width = 0.012;
void vertex() {
	VERTEX += NORMAL * width;
}
void fragment() {
	ALBEDO = color.rgb;
}
"""
	return _outline_shader


## A cel-shaded material, shared per color. outline = ink width in meters (0 = none).
static func mat(c: Color, outline := 0.012, gloss := 0.0, emit := Color.BLACK) -> ShaderMaterial:
	var key := "%s|%f|%f|%s" % [c.to_html(), outline, gloss, emit.to_html()]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = shader()
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("shade", Color(0.55, 0.55, 0.72).lerp(c, 0.25))
	m.set_shader_parameter("gloss", gloss)
	m.set_shader_parameter("emission", emit)
	if outline > 0.0:
		var o := ShaderMaterial.new()
		o.shader = outline_shader()
		o.set_shader_parameter("width", outline)
		o.set_shader_parameter("color", c.darkened(0.82))
		m.next_pass = o
	_cache[key] = m
	return m


## Big anime eyes drawn procedurally: white, colored iris with gradient, pupil, two highlights, lash line.
static func eye_mat(iris: Color) -> ShaderMaterial:
	var key := "eye|" + iris.to_html()
	if _cache.has(key):
		return _cache[key]
	if _eye_shader == null:
		_eye_shader = Shader.new()
		_eye_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform vec4 iris : source_color = vec4(0.2, 0.5, 0.9, 1.0);
instance uniform float blink = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;
	float open = 1.0 - blink;
	// Almond-ish eye shape
	float shape = step(length(vec2(p.x * 0.95, p.y / max(0.05, 0.9 * open))), 1.0);
	if (shape < 0.5) { discard; }
	vec2 ip = p - vec2(0.0, -0.08);
	float r = length(vec2(ip.x * 1.25, ip.y * 0.95));
	vec3 col = vec3(0.98, 0.97, 1.0);
	float in_iris = step(r, 0.72);
	vec3 ic = mix(iris.rgb * 0.45, iris.rgb * 1.25, smoothstep(0.7, -0.4, ip.y));
	ic = mix(ic, iris.rgb * 0.25, smoothstep(0.55, 0.72, r));
	col = mix(col, ic, in_iris);
	col = mix(col, vec3(0.03, 0.03, 0.06), step(r, 0.28));
	float hl = step(length(p - vec2(-0.25, 0.32)), 0.17) + step(length(p - vec2(0.22, -0.3)), 0.08);
	col = mix(col, vec3(1.0), clamp(hl, 0.0, 1.0));
	// Upper lash line
	float lash = smoothstep(0.62, 0.8, p.y / max(0.05, 0.9 * open)) ;
	col = mix(col, vec3(0.05, 0.04, 0.07), clamp(lash, 0.0, 1.0));
	ALBEDO = col;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _eye_shader
	m.set_shader_parameter("iris", iris)
	_cache[key] = m
	return m
