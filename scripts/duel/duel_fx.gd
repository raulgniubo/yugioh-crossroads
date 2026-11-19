class_name DuelFx
extends RefCounted
## The light show of a duel (0.57.0): magic circles, shock rings, pillars of light, spiral
## portals, glowing orbs with trails, card-shaped pulses and the links of a chain. Everything is
## drawn by small shaders on flat pieces, adds its light to the picture (so it blooms on the
## better graphics settings), frees itself, and runs on the duel's animation speed.
## `board` is the DuelBoard (any Node3D works); positions are in its space.

const TAU_F := 6.2831853

static var _shaders := {}


static func _shader(key: String, code: String) -> Shader:
	if not _shaders.has(key):
		var s := Shader.new()
		s.code = code
		_shaders[key] = s
	return _shaders[key]


static func _mat(key: String, code: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(key, code)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


static func _t(sec: float) -> float:
	return Settings.t(sec)


const HEAD := "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;\n"
const HEAD_TOP := "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;\n"
const BILLBOARD := """
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
"""

# A circle of light on the floor: one ring, or a whole magic circle (inner rings, tick marks,
# a star of two polygons), turning slowly.
const GLYPH := """
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform float radius = 0.8;
uniform float width = 0.05;
uniform float soft = 0.07;
uniform float rings = 0.0;
uniform float ticks = 0.0;
uniform float star = 0.0;
uniform float dash = 0.0;
uniform float spin = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x) + spin;
	float d = abs(r - radius);
	float v = smoothstep(width, 0.0, d) + exp(-d * d / (soft * soft)) * 0.55;
	if (dash > 0.5) { v *= 0.5 + 0.5 * smoothstep(-0.2, 0.2, sin(a * dash)); }
	if (rings > 0.5) { v += smoothstep(width * 0.55, 0.0, abs(r - radius * 0.84)) * 0.85; }
	if (rings > 1.5) { v += smoothstep(width * 0.55, 0.0, abs(r - radius * 0.42)) * 0.75; }
	if (ticks > 0.5) {
		float t = abs(fract(a / 6.2831853 * ticks) - 0.5);
		v += smoothstep(0.42, 0.5, t) * step(radius * 0.86, r) * step(r, radius * 0.97) * 0.9;
	}
	if (star > 2.5) {
		float seg = 6.2831853 / star;
		float big = radius * 0.82;
		float a1 = mod(a - spin * 2.0, seg) - seg * 0.5;
		float a2 = mod(a - spin * 2.0 + seg * 0.5, seg) - seg * 0.5;
		float inside = step(r, big + 0.01);
		v += smoothstep(width * 0.5, 0.0, abs(r * cos(a1) - big * cos(seg * 0.5))) * inside * 0.8;
		v += smoothstep(width * 0.5, 0.0, abs(r * cos(a2) - big * cos(seg * 0.5))) * inside * 0.8;
	}
	ALBEDO = color.rgb * energy;
	ALPHA = clamp(v, 0.0, 1.0) * alpha * color.a * smoothstep(1.0, 0.92, r);
}
"""

# A spiral of light turning around a bright (or dark) heart: the Xyz galaxy, the Fusion whirl.
const SPIRAL := """
uniform vec4 color_a : source_color = vec4(1.0);
uniform vec4 color_b : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform float arms = 3.0;
uniform float twist = 5.0;
uniform float speed = 3.0;
uniform float hole = 0.0;
uniform float phase = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float s = a * arms + log(r + 0.03) * twist - TIME * speed - phase;
	float arm = pow(0.5 + 0.5 * cos(s), 2.2);
	float fall = smoothstep(1.0, 0.15, r);
	float v = arm * fall * (0.3 + 0.7 * smoothstep(0.0, 0.3, r));
	// stars caught in the arms
	vec2 cell = floor(vec2(a * 9.0 - TIME * speed * 0.7 - log(r + 0.03) * twist * 1.4, r * 16.0));
	float st = step(0.93, hash(cell)) * fall * arm;
	v += st * 1.4;
	float heart = exp(-r * r * 16.0) * 1.6;
	if (hole > 0.01) { v *= smoothstep(hole * 0.55, hole, r); v += smoothstep(0.06, 0.0, abs(r - hole)) * 0.9; }
	else { v += heart; }
	vec3 col = mix(color_a.rgb, color_b.rgb, clamp(r * 1.25, 0.0, 1.0));
	ALBEDO = col * energy;
	ALPHA = clamp(v, 0.0, 1.0) * alpha;
}
"""

# A column of light with streaks running up it (on a cylinder without caps).
const PILLAR := """
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform float speed = 1.6;
void fragment() {
	float u = UV.x * 6.2831853;
	float s1 = 0.5 + 0.5 * sin(u * 9.0 + sin(UV.y * 6.0 - TIME * speed * 2.0) * 1.5);
	float s2 = 0.5 + 0.5 * sin(u * 23.0 - UV.y * 14.0 + TIME * speed * 5.0);
	float streak = pow(s1, 3.0) * 0.7 + pow(s2, 6.0) * 0.6;
	float up = smoothstep(0.0, 0.65, UV.y);
	float foot = 1.0 + smoothstep(0.8, 1.0, UV.y) * 1.2;
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.6);
	ALBEDO = color.rgb * energy;
	ALPHA = clamp((0.22 + streak) * up * foot * (0.35 + 0.65 * rim), 0.0, 1.0) * alpha;
}
"""

# A soft ball of light that always faces the camera, with an optional four-point flare.
const GLOW := BILLBOARD + """
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform float flare = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float v = exp(-r * r * 5.5) + exp(-r * r * 40.0) * 0.8;
	if (flare > 0.01) {
		v += (exp(-abs(p.y) * 46.0) * exp(-abs(p.x) * 2.6) + exp(-abs(p.x) * 46.0) * exp(-abs(p.y) * 2.6)) * flare;
	}
	ALBEDO = mix(color.rgb, vec3(1.0), exp(-r * r * 30.0) * 0.7) * energy;
	ALPHA = clamp(v, 0.0, 1.0) * alpha * smoothstep(1.0, 0.8, r);
}
"""

# The outline of a card, pulsing outward from its zone.
const RECT := """
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform vec2 half_size = vec2(0.25, 0.36);
uniform float width = 0.02;
uniform float fill = 0.0;
float box(vec2 p, vec2 b) { vec2 d = abs(p) - b; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = box(p, half_size - 0.03) - 0.03;
	float v = smoothstep(width, 0.0, abs(d)) + exp(-d * d / 0.004) * 0.5;
	v += fill * smoothstep(0.02, -0.25, d) * 0.6;
	ALBEDO = color.rgb * energy;
	ALPHA = clamp(v, 0.0, 1.0) * alpha * smoothstep(1.0, 0.9, max(abs(p.x), abs(p.y)));
}
"""

# Lines of light flying outward from a point (on a floor quad or facing the camera).
const RAYS := """
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform float count = 24.0;
uniform float reach = 0.5;
uniform float seed = 0.0;
float hash(float n) { return fract(sin(n * 91.3458 + seed) * 47453.5453); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x) / 6.2831853 + 0.5;
	float id = floor(a * count);
	float f = abs(fract(a * count) - 0.5);
	float len = 0.45 + 0.55 * hash(id);
	float head = reach * len;
	float body = smoothstep(head, head - 0.25 * len, r) * smoothstep(head - 0.55 * len, head - 0.2 * len, r);
	float thin = smoothstep(0.5 * (0.25 + 0.5 * hash(id + 7.0)), 0.0, f);
	ALBEDO = color.rgb * energy;
	ALPHA = clamp(body * thin * step(0.25, hash(id + 3.0)), 0.0, 1.0) * alpha * smoothstep(1.0, 0.85, r);
}
"""

# The links of a chain along a ribbon. UV.x counts links, UV.y runs across; UV2.x is 0..1 along it.
const CHAIN := """
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 2.2;
uniform float alpha = 1.0;
uniform float progress = 1.0;
uniform float snap = 0.0;
float box(vec2 p, vec2 b, float r) { vec2 d = abs(p) - b + r; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r; }
void fragment() {
	float u = UV.x - TIME * 0.35;
	float cell = floor(u);
	vec2 p = vec2(fract(u) - 0.5, UV.y - 0.5);
	float odd = mod(cell, 2.0);
	float v;
	if (odd < 0.5) {
		float d = box(p, vec2(0.56, 0.36), 0.3);
		v = smoothstep(0.075, 0.03, abs(d + 0.09));
	} else {
		float d = box(p, vec2(0.52, 0.11), 0.1);
		v = smoothstep(0.03, -0.02, d);
	}
	float glow = exp(-pow((UV.y - 0.5) * 3.2, 2.0)) * 0.22;
	float lit = 0.75 + 0.6 * exp(-pow((UV2.x - fract(TIME * 0.9)) * 7.0, 2.0));
	float shown = smoothstep(progress + 0.02, progress - 0.02, UV2.x);
	float gone = smoothstep(snap - 0.02, snap + 0.02, abs(UV2.x - 0.5) * 2.0 + 0.001);
	ALBEDO = mix(color.rgb, vec3(1.0), v * 0.35) * energy * lit;
	ALPHA = clamp(v + glow, 0.0, 1.0) * alpha * shown * (snap > 0.0 ? gone : 1.0);
}
"""


static func _quad(size: float, flat: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	if flat:
		q.orientation = PlaneMesh.FACE_Y
	return q


static func _piece(board: Node, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at
	board.add_child(mi)
	return mi


static var _dot: GradientTexture2D


## A soft round dot for every small particle (sparks, embers, snow): a bright heart, a soft
## edge. Without it a particle is a plain square.
static func dot_tex() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.0)])
		_dot = GradientTexture2D.new()
		_dot.gradient = g
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(0.5, 0.0)
		_dot.width = 48
		_dot.height = 48
	return _dot


static func _hdr(c: Color, k := 1.0) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, 1.0)


## A ring of light that spreads over the floor and fades: the shock of something landing.
static func ring(board: Node, at: Vector3, color: Color, r0: float, r1: float, dur := 0.5, width := 0.05, delay := 0.0, energy := 2.4) -> void:
	var size := r1 * 2.2
	var m := _mat("glyph", HEAD + GLYPH, {"color": color, "energy": energy, "alpha": 0.0, "radius": r0 / (size * 0.5), "width": width, "soft": width * 1.6})
	var mi := _piece(board, _quad(size, true), m, at + Vector3(0, 0.03, 0))
	var tw := board.create_tween()
	if delay > 0.0:
		tw.tween_interval(_t(delay))
	tw.tween_property(m, "shader_parameter/alpha", 1.0, _t(0.05))
	tw.parallel().tween_property(m, "shader_parameter/radius", r1 / (size * 0.5), _t(dur)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(m, "shader_parameter/alpha", 0.0, _t(dur * 0.55)).set_delay(_t(dur * 0.45))
	tw.tween_callback(mi.queue_free)


## A magic circle on the floor. It draws itself in, turns while it holds, and fades.
## opts: rings (0-2), ticks, star (3 = hexagram, 4, 5...), dash, turn (radians it turns over its life),
## energy, hold (false: returns the piece and its material; call fade() on it yourself).
static func glyph(board: Node, at: Vector3, color: Color, radius: float, life := 1.4, opts := {}) -> MeshInstance3D:
	var size := radius * 2.2
	var m := _mat("glyph", HEAD + GLYPH, {"color": color, "energy": float(opts.get("energy", 2.2)), "alpha": 0.0, "radius": 0.86, "width": 0.022, "spin": 0.0,
		"soft": 0.05, "rings": float(opts.get("rings", 2)), "ticks": float(opts.get("ticks", 36)), "star": float(opts.get("star", 3)), "dash": float(opts.get("dash", 0))})
	var mi := _piece(board, _quad(size, true), m, at + Vector3(0, 0.035, 0))
	mi.scale = Vector3(0.3, 1, 0.3)
	var turn := float(opts.get("turn", 1.6))
	var tw := board.create_tween().set_parallel()
	tw.tween_property(m, "shader_parameter/alpha", 1.0, _t(0.18))
	tw.tween_property(mi, "scale", Vector3.ONE, _t(0.32)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "shader_parameter/spin", turn, _t(life))
	if not opts.get("keep", false):
		tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(0.3)).set_delay(_t(life - 0.3))
		tw.chain().tween_callback(mi.queue_free)
	return mi


## Fade any piece made here and free it.
static func fade(mi: Node3D, dur := 0.3) -> void:
	if mi == null or not is_instance_valid(mi):
		return
	var m = (mi as MeshInstance3D).material_override if mi is MeshInstance3D else null
	var tw := mi.create_tween()
	if m is ShaderMaterial:
		tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(dur))
	else:
		tw.tween_interval(_t(dur))
	tw.tween_callback(mi.queue_free)


## A column of light rising from the floor.
static func pillar(board: Node, at: Vector3, color: Color, radius := 0.6, height := 6.0, life := 1.0, delay := 0.0, energy := 2.2) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 1.25
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 28
	cyl.rings = 1
	cyl.cap_top = false
	cyl.cap_bottom = false
	var m := _mat("pillar", HEAD + PILLAR, {"color": color, "energy": energy, "alpha": 0.0})
	var mi := _piece(board, cyl, m, at + Vector3(0, height * 0.5, 0))
	mi.scale = Vector3(0.15, 1, 0.15)
	var tw := board.create_tween()
	if delay > 0.0:
		tw.tween_interval(_t(delay))
	tw.tween_property(m, "shader_parameter/alpha", 1.0, _t(0.1))
	tw.parallel().tween_property(mi, "scale", Vector3.ONE, _t(0.16)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(_t(maxf(0.0, life - 0.55)))
	tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(0.45))
	tw.parallel().tween_property(mi, "scale", Vector3(0.05, 1, 0.05), _t(0.45)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	return mi


## A turning spiral: flat on the floor (a portal) or facing the camera (a whirl in the air).
## Returns the piece; it fades by itself after `life` unless keep is set.
static func spiral(board: Node, at: Vector3, col_a: Color, col_b: Color, radius: float, life := 1.2, opts := {}) -> MeshInstance3D:
	var flat: bool = opts.get("flat", true)
	var code := (HEAD + SPIRAL) if flat else (HEAD + BILLBOARD + SPIRAL)
	var m := _mat("spiral_flat" if flat else "spiral_bill", code, {"color_a": col_a, "color_b": col_b, "energy": float(opts.get("energy", 2.4)), "alpha": 0.0,
		"arms": float(opts.get("arms", 3)), "twist": float(opts.get("twist", 5.0)), "speed": float(opts.get("speed", 3.5)), "hole": float(opts.get("hole", 0.0))})
	var mi := _piece(board, _quad(radius * 2.0, flat), m, at)
	mi.scale = Vector3(0.1, 0.1, 0.1) if not flat else Vector3(0.1, 1, 0.1)
	var tw := board.create_tween().set_parallel()
	tw.tween_property(m, "shader_parameter/alpha", 1.0, _t(0.2))
	tw.tween_property(mi, "scale", Vector3.ONE, _t(float(opts.get("open", 0.4)))).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not opts.get("keep", false):
		tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(0.3)).set_delay(_t(life - 0.3))
		tw.tween_property(mi, "scale", Vector3(0.02, 0.02, 0.02) if not flat else Vector3(0.02, 1, 0.02), _t(0.3)).set_delay(_t(life - 0.3)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(mi.queue_free)
	return mi


## A dark disc on the floor (the mouth of a portal). Not added light: it really darkens.
static func pit(board: Node, at: Vector3, radius: float, life: float) -> MeshInstance3D:
	var m := _mat("pit", "shader_type spatial;\nrender_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;\nuniform float alpha = 1.0;\nvoid fragment() { vec2 p = (UV - 0.5) * 2.0; float r = length(p); ALBEDO = vec3(0.01, 0.0, 0.04); ALPHA = smoothstep(1.0, 0.55, r) * 0.94 * alpha; }\n", {"alpha": 0.0})
	var mi := _piece(board, _quad(radius * 2.0, true), m, at + Vector3(0, 0.028, 0))
	mi.scale = Vector3(0.1, 1, 0.1)
	var tw := board.create_tween()
	tw.tween_property(m, "shader_parameter/alpha", 1.0, _t(0.2))
	tw.parallel().tween_property(mi, "scale", Vector3.ONE, _t(0.35)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(_t(maxf(0.0, life - 0.6)))
	tw.tween_property(mi, "scale", Vector3(0.02, 1, 0.02), _t(0.25)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	return mi


## A flash of light in the air: swells and fades. `flare` adds a four-point star.
static func glow(board: Node, at: Vector3, color: Color, size := 1.6, life := 0.45, flare := 0.0, energy := 3.0, on_top := false) -> MeshInstance3D:
	var m := _mat("glow_top" if on_top else "glow", (HEAD_TOP if on_top else HEAD) + GLOW, {"color": color, "energy": energy, "alpha": 1.0, "flare": flare})
	var mi := _piece(board, _quad(1.0, false), m, at)
	mi.scale = Vector3.ONE * size * 0.35
	var tw := board.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3.ONE * size, _t(life * 0.35)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(life * 0.7)).set_delay(_t(life * 0.3))
	tw.chain().tween_callback(mi.queue_free)
	return mi


## The outline of a card flashing outward from where a card just landed.
## `yaw` turns it with the card (0 = upright as you see it).
static func rect(board: Node, at: Vector3, color: Color, from := 1.0, to := 1.9, dur := 0.45, sideways := false, energy := 2.6, fill := 0.0) -> void:
	var size := 2.6
	var half := Vector2(Card3D.SIZE.x, Card3D.SIZE.y) / size
	if sideways:
		half = Vector2(half.y, half.x)
	var m := _mat("rect", HEAD + RECT, {"color": color, "energy": energy, "alpha": 1.0, "half_size": half * from, "width": 0.014, "fill": fill})
	var mi := _piece(board, _quad(size, true), m, at + Vector3(0, 0.04, 0))
	var tw := board.create_tween().set_parallel()
	tw.tween_property(m, "shader_parameter/half_size", half * to, _t(dur)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(dur * 0.6)).set_delay(_t(dur * 0.4))
	tw.tween_property(m, "shader_parameter/fill", 0.0, _t(dur * 0.5))
	tw.chain().tween_callback(mi.queue_free)


## Lines of light thrown outward along the floor (or toward the camera with flat = false).
static func rays(board: Node, at: Vector3, color: Color, radius := 2.0, dur := 0.4, count := 26, flat := true, energy := 2.6) -> void:
	var code := (HEAD + RAYS) if flat else (HEAD + BILLBOARD + RAYS)
	var m := _mat("rays_flat" if flat else "rays_bill", code, {"color": color, "energy": energy, "alpha": 1.0, "count": float(count), "reach": 0.25, "seed": randf() * 50.0})
	var mi := _piece(board, _quad(radius * 2.0, flat), m, at + (Vector3(0, 0.045, 0) if flat else Vector3.ZERO))
	var tw := board.create_tween().set_parallel()
	tw.tween_property(m, "shader_parameter/reach", 1.25, _t(dur)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(dur * 0.5)).set_delay(_t(dur * 0.5))
	tw.chain().tween_callback(mi.queue_free)


## Sparks thrown from a point. `up` = how much they favor going up (0 flat ring, 1 a fountain).
static func sparks(board: Node, at: Vector3, color: Color, amount := 30, speed := 5.0, up := 0.6, life := 0.8, gravity := -9.0, size := 0.05) -> void:
	var ps := GPUParticles3D.new()
	ps.one_shot = true
	ps.explosiveness = 0.95
	ps.amount = maxi(4, amount)
	ps.lifetime = life
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = lerpf(89.0, 35.0, up)
	pm.flatness = 1.0 - up if up < 0.3 else 0.0
	pm.initial_velocity_min = speed * 0.45
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0)
	pm.damping_min = 1.0
	pm.damping_max = 2.5
	pm.scale_min = 0.5
	pm.scale_max = 1.5
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(color, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	ps.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.albedo_texture = dot_tex()
	qm.vertex_color_use_as_albedo = true
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.albedo_color = _hdr(color, 2.2)
	q.material = qm
	ps.draw_pass_1 = q
	ps.position = at
	board.add_child(ps)
	ps.emitting = true
	board.get_tree().create_timer(life + 0.8).timeout.connect(ps.queue_free)


## Motes of light drifting up out of a ring on the floor for a while (flames, an aura).
static func embers(board: Node, at: Vector3, color: Color, radius := 0.6, amount := 24, life := 1.2, rise := 1.6, size := 0.06) -> GPUParticles3D:
	var ps := GPUParticles3D.new()
	ps.amount = maxi(4, amount)
	ps.lifetime = 0.9
	ps.one_shot = false
	ps.explosiveness = 0.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.emission_ring_radius = radius
	pm.emission_ring_inner_radius = radius * 0.8
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = rise * 0.6
	pm.initial_velocity_max = rise
	pm.gravity = Vector3(0, 0.6, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.6
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.95))
	grad.set_color(1, Color(color, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	ps.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size * 1.8)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.albedo_texture = dot_tex()
	qm.vertex_color_use_as_albedo = true
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.albedo_color = _hdr(color, 2.0)
	q.material = qm
	ps.draw_pass_1 = q
	ps.position = at + Vector3(0, 0.05, 0)
	board.add_child(ps)
	ps.emitting = true
	if life > 0.0:
		var tr := board.get_tree()
		tr.create_timer(_t(life)).timeout.connect(func():
			if is_instance_valid(ps):
				ps.emitting = false)
		tr.create_timer(_t(life) + 1.2).timeout.connect(func():
			if is_instance_valid(ps):
				ps.queue_free())
	return ps


## A ball of light that leaves a trail as it is moved. Move it with a tween on its position,
## then call pop() (a small burst) or just free it.
static func orb(board: Node, at: Vector3, color: Color, size := 0.28) -> FxOrb:
	var o := FxOrb.new()
	o.color = color
	o.size = size
	o.position = at
	board.add_child(o)
	return o


## A chain of light between two points, drawn out from `a` to `b`. Returns the piece: fade() it,
## or snap_chain() to break it from the middle.
static func chain(board: Node, a: Vector3, b: Vector3, color: Color, cam: Camera3D, dur := 0.3, width := 0.2) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var mid := (a + b) * 0.5 + Vector3(0, 0.55 + a.distance_to(b) * 0.08, 0)
	var steps := 18
	var total := 0.0
	var pts: Array = []
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
		if i > 0:
			total += (pts[i] as Vector3).distance_to(pts[i - 1])
	var link := width * 1.9
	var run := 0.0
	var eye := cam.global_position if cam != null else Vector3(0, 10, 5)
	for i in steps + 1:
		var p: Vector3 = pts[i]
		var tan: Vector3 = ((pts[mini(i + 1, steps)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		var side := tan.cross((eye - p).normalized()).normalized() * width * 0.5
		if i > 0:
			run += p.distance_to(pts[i - 1])
		for k in 2:
			st.set_uv(Vector2(run / link, float(k)))
			st.set_uv2(Vector2(run / maxf(0.001, total), 0.0))
			st.add_vertex(p + side * (1.0 if k == 0 else -1.0))
	var m := _mat("chain", HEAD_TOP + CHAIN, {"color": color, "alpha": 1.0, "progress": 0.0, "snap": 0.0})
	var mi := _piece(board, st.commit(), m, Vector3.ZERO)
	board.create_tween().tween_property(m, "shader_parameter/progress", 1.05, _t(dur)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return mi


## The chain breaks: it opens from the middle and is gone.
static func snap_chain(mi: MeshInstance3D, dur := 0.22) -> void:
	if mi == null or not is_instance_valid(mi):
		return
	var m := mi.material_override as ShaderMaterial
	var tw := mi.create_tween()
	tw.tween_property(m, "shader_parameter/snap", 1.05, _t(dur)).from(0.001)
	tw.tween_callback(mi.queue_free)


## Draw every kind of piece once, tiny and out of sight, so the first real one does not make the
## game stop to build its shader. Call when a duel starts.
static func warm(board: Node) -> void:
	var under := Vector3(0, -30, 0)
	var keys := [["glyph", HEAD + GLYPH, true], ["spiral_flat", HEAD + SPIRAL, true], ["spiral_bill", HEAD + BILLBOARD + SPIRAL, false], ["pillar", HEAD + PILLAR, false],
		["glow", HEAD + GLOW, false], ["glow_top", HEAD_TOP + GLOW, false], ["rect", HEAD + RECT, true], ["rays_flat", HEAD + RAYS, true],
		["rays_bill", HEAD + BILLBOARD + RAYS, false], ["chain", HEAD_TOP + CHAIN, false], ["glyph_badge", HEAD_TOP + BILLBOARD + GLYPH, false]]
	var made: Array = []
	for k in keys:
		made.append(_piece(board, _quad(0.01, bool(k[2])), _mat(str(k[0]), str(k[1])), under))
	board.get_tree().create_timer(0.5).timeout.connect(func():
		for mi in made:
			if is_instance_valid(mi):
				mi.queue_free())
