class_name ElementFx
extends RefCounted
## What a monster's attack is made of (0.60.0). Its Type still decides how it strikes (a slash,
## claws, jaws, a beam: StrikeFx); its Attribute decides the rest, in three beats:
##   gather: the element collects around the attacker when it declares the attack,
##   travel: it crosses the field with the attack (fired from where the monster stands, for the
##           kinds that shoot; ridden across the floor, for the kinds that charge in),
##   impact: it lands on the target, and what it leaves behind fades over the next second.
## FIRE is a stream of flame and an explosion; WATER a wave that crashes and leaves ripples;
## WIND cutting gusts and a whirlwind; EARTH a crack running through the floor and rocks coming
## up under the target; LIGHT lances and a column from the sky; DARK a shadow crawling over the
## floor, a pool opening and fangs closing; DIVINE gold thunder.
## How big it gets goes by the attacker's ATK (tier 0, 1, 2), so a weak monster's attack is as
## quick as it always was and the full show is kept for the strong ones.
## Everything is drawn by shaders on simple pieces and frees itself. `board` is the DuelBoard.

const PAL := {
	"FIRE": [Color("ff8a1e"), Color("e0260a"), Color("fff0b0")],
	"WATER": [Color("6fd8ff"), Color("1a62e0"), Color("ffffff")],
	"WIND": [Color("c4ffd8"), Color("3fe08e"), Color("ffffff")],
	"EARTH": [Color("ffb44a"), Color("8a5a2a"), Color("ffe6b0")],
	"LIGHT": [Color("fff6cc"), Color("ffd76a"), Color("ffffff")],
	"DARK": [Color("b85cff"), Color("4a12a0"), Color("e8c8ff")],
	"DIVINE": [Color("ffe27a"), Color("ff9a1a"), Color("fffbe0")],
}

const NOISE := """
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * vnoise(p); p = p * 2.03 + vec2(17.1, 9.2); a *= 0.5; }
	return v;
}
"""
const ADD := "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;\n"
const MIX := "shader_type spatial;\nrender_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;\n"
const ADD_W := "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, world_vertex_coords;\n"
const MIX_W := "shader_type spatial;\nrender_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, world_vertex_coords;\n"

# A band of the element from one point to another: UV.x runs along it, `head` is how far its
# front has got, `tail` how far its back has let go. It faces the camera, or lies on the floor.
const RIBBON := """
uniform vec3 pa = vec3(0.0);
uniform vec3 pb = vec3(0.0, 0.0, -1.0);
uniform float width = 0.6;
uniform float arc = 0.0;
uniform float flat_on = 0.0;
uniform float head = 0.0;
uniform float tail = -0.2;
uniform int mode = 0;
uniform vec3 col1 : source_color = vec3(1.0);
uniform vec3 col2 : source_color = vec3(1.0);
uniform float energy = 2.2;
uniform float alpha = 1.0;
uniform float seed = 0.0;
varying vec2 uv;
""" + NOISE + """
void vertex() {
	uv = UV;
	float x = UV.x;
	vec3 p = mix(pa, pb, x);
	p.y += sin(x * 3.14159) * arc;
	vec3 dir = normalize(pb - pa + vec3(0.0, cos(x * 3.14159) * arc * 3.14159, 0.0));
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 side = normalize(cross(dir, mix(normalize(cam - p), vec3(0.0, 1.0, 0.0), flat_on)));
	float w = width * mix(0.3, 1.0, smoothstep(0.0, 0.22, x));
	VERTEX = p + side * (UV.y - 0.5) * w;
}
void fragment() {
	float x = uv.x;
	float y = (uv.y - 0.5) * 2.0;
	float t = TIME;
	float along = smoothstep(head, head - 0.1, x) * smoothstep(tail, tail + 0.14, x);
	float front = exp(-pow((x - head + 0.05) * 15.0, 2.0)) * exp(-y * y * 2.5);
	vec3 c = col1;
	float v = 0.0;
	if (mode == 0) {            // fire: a ragged stream, white at the heart, red at the edge
		float n = fbm(vec2(x * 7.0 - t * 6.0, y * 2.2 + seed));
		float n2 = fbm(vec2(x * 16.0 - t * 11.0, y * 4.0 - seed));
		float body = 1.0 - abs(y) - (n - 0.5) * 1.0;
		v = smoothstep(0.0, 0.45, body);
		float core = smoothstep(0.5, 1.0, body + n2 * 0.35);
		c = mix(col2, col1, smoothstep(0.05, 0.6, body));
		c = mix(c, vec3(1.0, 0.9, 0.5), core);
		v = clamp(v * 1.2, 0.0, 1.0) * (0.75 + 0.25 * n2);
		v += front * 0.8;
	} else if (mode == 1) {     // water: a torrent with bright lines running in it and foam at its edge
		float wv = sin(x * 26.0 - t * 15.0 + y * 3.0) * 0.07;
		float n = fbm(vec2(x * 5.0 - t * 4.5, y * 2.0 + seed));
		float body = 1.0 - abs(y + wv) - (n - 0.5) * 0.4;
		float ca = pow(abs(sin(x * 20.0 - t * 13.0 + n * 7.0 + y * 2.0)), 9.0);
		float foam = smoothstep(0.34, 0.06, body) * smoothstep(-0.05, 0.08, body);
		foam += step(0.62, fbm(vec2(x * 22.0 - t * 16.0, y * 7.0 + seed))) * smoothstep(0.5, 0.0, body) * smoothstep(-0.25, 0.1, body) * 0.7;
		v = smoothstep(-0.02, 0.2, body) * 0.62 + ca * smoothstep(0.1, 0.5, body) * 0.4 + foam;
		c = mix(col2, col1, smoothstep(0.0, 0.8, body));
		c = mix(c, vec3(0.85, 0.97, 1.0), clamp(foam * 0.8 + ca * 0.45, 0.0, 1.0));
		v += front * 1.4;
	} else if (mode == 2) {     // wind: a few thin lines of air winding round each other
		for (int i = 0; i < 4; i++) {
			float ph = float(i) * 1.9 + seed;
			float yy = y - sin(x * 8.0 - t * 12.0 + ph) * 0.6;
			v += smoothstep(0.1, 0.0, abs(yy)) * (0.45 + 0.55 * sin(x * 17.0 - t * 30.0 + ph * 3.0));
		}
		v += fbm(vec2(x * 6.0 - t * 9.0, y * 2.0 + seed)) * 0.25 * (1.0 - y * y);
		c = mix(col2, col1, clamp(v, 0.0, 1.0));
		v += front * 0.6;
	} else if (mode == 3 || mode == 6) {    // light / divine: a hard bright line with rings running down it
		v = exp(-y * y * 34.0) * 1.6 + exp(-y * y * 4.5) * 0.4;
		v += pow(abs(sin(x * 38.0 - t * 44.0)), 22.0) * exp(-y * y * 5.0) * 0.8;
		v += step(0.965, h21(floor(vec2(x * 46.0 - t * 34.0, y * 7.0 + seed)))) * 1.2;
		c = mix(col2, col1, exp(-y * y * 8.0));
		if (mode == 6) {        // (divine: lightning writhing round it)
			float jag = (vnoise(vec2(x * 16.0 + seed, floor(t * 20.0))) - 0.5) * 1.2;
			float jag2 = (vnoise(vec2(x * 23.0 - seed, floor(t * 26.0) + 7.0)) - 0.5) * 1.5;
			v += smoothstep(0.07, 0.0, abs(y - jag)) * 2.0 + smoothstep(0.05, 0.0, abs(y - jag2)) * 1.3;
		}
		v += front * 1.6;
	} else if (mode == 4) {     // dark: a band of black smoke with a violet rim (drawn over the picture, not added)
		float n = fbm(vec2(x * 6.0 - t * 4.5, y * 2.4 + seed));
		float body = 1.0 - abs(y) - (n - 0.5) * 1.1;
		v = smoothstep(0.0, 0.3, body);
		float rim = smoothstep(0.32, 0.0, abs(body - 0.16));
		float jag = (vnoise(vec2(x * 15.0 + seed, floor(t * 16.0))) - 0.5) * 0.9;
		float bolt = smoothstep(0.05, 0.0, abs(y - jag)) * step(0.5, vnoise(vec2(floor(t * 16.0), seed)));
		c = mix(vec3(0.015, 0.0, 0.04), col1 * energy, clamp(rim + bolt + front, 0.0, 1.0));
		ALBEDO = c;
		ALPHA = clamp(v * 0.93 + bolt, 0.0, 1.0) * along * alpha;
	} else if (mode == 5) {     // earth: a crack running through the floor, glowing from inside
		float line = (vnoise(vec2(x * 9.0, seed)) - 0.5) * 0.9 + (vnoise(vec2(x * 31.0, seed + 3.0)) - 0.5) * 0.3;
		float d = abs(y - line);
		float br = (vnoise(vec2(x * 13.0, seed + 9.0)) - 0.5) * 1.7;
		float d2 = abs(y - br) + (1.0 - smoothstep(0.35, 0.6, vnoise(vec2(x * 4.0, seed + 5.0)))) * 2.0;
		v = smoothstep(0.09, 0.0, d) * 1.5 + exp(-d * 7.0) * 0.45 + smoothstep(0.06, 0.0, d2) * 0.9;
		c = mix(col1, vec3(1.0, 0.95, 0.75), smoothstep(0.06, 0.0, d));
		v *= 0.75 + 0.25 * sin(t * 14.0 + x * 20.0);
		v += front * 1.5;
	}
	if (mode != 4) {
		ALBEDO = c * energy;
		ALPHA = clamp(v, 0.0, 1.0) * along * alpha * (1.0 - smoothstep(0.82, 1.0, abs(y)));
	}
}
"""

# A burst that faces the camera. `age` runs 0 to 1 over its life.
# 0 fireball, 1 flame tongue, 2 mist, 3 smoke (drawn over), 4 dark flame (drawn over).
const PUFF := """
void vertex() {
	uv = UV;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
uniform float age = 0.0;
uniform int mode = 0;
uniform vec3 col1 : source_color = vec3(1.0);
uniform vec3 col2 : source_color = vec3(1.0);
uniform float energy = 2.4;
uniform float alpha = 1.0;
uniform float seed = 0.0;
""" + NOISE + """
void fragment() {
	vec2 p = (uv - 0.5) * 2.0;
	p.y = -p.y;
	float r = length(p);
	float t = TIME;
	vec3 c = col1;
	float v = 0.0;
	if (mode == 0) {
		float a = atan(p.y, p.x);
		float n = fbm(vec2(a * 1.5 + seed, r * 2.4 - age * 2.6 - t * 0.5));
		float n2 = fbm(p * 3.4 + vec2(seed, -t * 1.3 - age * 2.0));
		float big = mix(0.28, 0.95, 1.0 - pow(1.0 - age, 2.6));
		float edge = big * (0.7 + 0.5 * n);
		float ball = smoothstep(edge, edge * 0.5, r);
		float hot = smoothstep(edge * 0.8, 0.0, r) * (1.0 - age);
		c = mix(col2, col1, smoothstep(0.25, 0.7, n2 + hot * 0.7));
		c = mix(c, vec3(1.0, 0.9, 0.5), hot * 0.9);
		// (it cools to dark smoke as it breaks up)
		c = mix(c, vec3(0.1, 0.045, 0.03), smoothstep(0.4, 0.95, age) * (1.0 - hot));
		float holes = smoothstep(age * 1.2 - 0.3, age * 1.2, n2 + 0.28);
		v = ball * holes * (1.0 - smoothstep(0.72, 1.0, age)) * 0.9;
	} else if (mode == 1 || mode == 4) {
		float qy = p.y * 0.5 + 0.5;
		float wob = (fbm(vec2(qy * 3.0 - t * 2.8 + seed, seed)) - 0.5) * 0.55 * qy;
		float wdt = (1.0 - qy) * 0.72 + 0.04;
		float n = fbm(vec2(p.x * 3.0 + seed, qy * 3.6 - t * 3.4));
		float f = smoothstep(wdt, wdt * 0.25, abs(p.x + wob) + (n - 0.5) * 0.36) * smoothstep(1.0, 0.5, qy + (n - 0.5) * 0.45) * smoothstep(0.0, 0.07, qy);
		float life = smoothstep(0.0, 0.18, age) * (1.0 - smoothstep(0.65, 1.0, age));
		if (mode == 1) {
			c = mix(col2, col1, smoothstep(0.1, 0.7, f));
			c = mix(c, vec3(1.0, 0.9, 0.5), smoothstep(0.62, 1.0, f) * (1.0 - qy));
			v = clamp(f * 1.25, 0.0, 1.0) * life;
		} else {
			float rim = smoothstep(0.0, 0.3, f) * (1.0 - smoothstep(0.3, 0.75, f));
			ALBEDO = mix(vec3(0.02, 0.0, 0.05), col1 * energy, rim);
			ALPHA = clamp(smoothstep(0.02, 0.3, f) * 0.94, 0.0, 1.0) * life * alpha;
		}
	} else if (mode == 2) {
		float n = fbm(p * 2.6 + vec2(seed, -t * 0.6 - age));
		v = smoothstep(1.0, 0.15, r) * smoothstep(0.32, 0.72, n + (1.0 - r) * 0.42) * (1.0 - age) * smoothstep(0.0, 0.1, age) * 0.8;
		c = mix(col1, vec3(1.0), n);
	} else {
		float n = fbm(p * 2.2 + vec2(seed, -t * 0.4 - age * 1.2));
		float body = smoothstep(1.0, 0.2, r + (n - 0.5) * 0.6) * smoothstep(0.3, 0.62, n + (1.0 - r) * 0.5);
		ALBEDO = mix(col2, col1, n);
		ALPHA = body * (1.0 - smoothstep(0.3, 1.0, age)) * smoothstep(0.0, 0.08, age) * 0.78 * alpha;
	}
	if (mode <= 2) {
		ALBEDO = c * energy;
		ALPHA = clamp(v, 0.0, 1.0) * alpha * smoothstep(1.0, 0.86, r);
	}
}
"""

# A wave standing across the field: an arched body with lines of light running up it, a
# foaming crest and spray above. `rise` brings it up out of the floor; the top leans forward.
const WAVE := """
uniform float rise = 0.0;
uniform float curl = 0.5;
uniform vec3 col1 : source_color = vec3(0.4, 0.85, 1.0);
uniform vec3 col2 : source_color = vec3(0.1, 0.4, 0.9);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform float seed = 0.0;
varying vec2 uv;
""" + NOISE + """
void vertex() {
	uv = UV;
	float yy = 1.0 - UV.y;
	VERTEX.z += curl * yy * yy * rise;
}
void fragment() {
	float xx = (uv.x - 0.5) * 2.0;
	float yy = 1.0 - uv.y;
	float t = TIME;
	float crest = 0.66 + 0.07 * sin(xx * 4.0 + t * 3.4 + seed) + (fbm(vec2(xx * 3.0 + t * 1.2, t * 0.8 + seed)) - 0.5) * 0.24;
	crest *= (1.0 - xx * xx * 0.8) * rise;
	float body = smoothstep(crest, crest - 0.06, yy);
	float foam = smoothstep(0.11, 0.0, abs(yy - crest + 0.02)) * step(0.02, crest);
	float n = fbm(vec2(xx * 5.0 + seed, yy * 6.0 - t * 4.0));
	float lines = pow(abs(sin(yy * 16.0 - t * 7.0 + n * 6.0 + xx * 2.0)), 7.0);
	float spray = step(0.6, fbm(vec2(xx * 14.0 + seed, yy * 14.0 - t * 5.0))) * smoothstep(crest + 0.3, crest, yy) * step(crest, yy) * step(0.05, crest);
	vec3 c = mix(col2, col1, clamp(yy / max(crest, 0.05), 0.0, 1.0));
	c = mix(c, vec3(0.85, 0.97, 1.0), clamp(foam * 0.85 + lines * 0.3 + spray * 0.8, 0.0, 1.0));
	float v = body * (0.5 + lines * 0.25 + n * 0.15) + foam + spray * 0.8;
	ALBEDO = c * energy;
	ALPHA = clamp(v, 0.0, 1.0) * alpha * (1.0 - smoothstep(0.86, 1.0, abs(xx)));
}
"""

# A ring of jets thrown up from a hit (on a cylinder without caps, which spreads as it rises).
const CROWN := """
uniform float grow = 0.0;
uniform float count = 14.0;
uniform float flare = 0.6;
uniform vec3 col1 : source_color = vec3(0.4, 0.85, 1.0);
uniform vec3 col2 : source_color = vec3(0.1, 0.4, 0.9);
uniform float energy = 2.2;
uniform float alpha = 1.0;
uniform float seed = 0.0;
varying vec2 uv;
float hs(float n) { return fract(sin(n * 91.3458 + seed) * 47453.5453); }
void vertex() {
	uv = UV;
	float yy = 1.0 - UV.y;
	VERTEX.xz *= 1.0 + yy * flare;
}
void fragment() {
	float u = uv.x * count;
	float id = floor(u);
	float f = fract(u) - 0.5;
	float yy = 1.0 - uv.y;
	float hgt = (0.45 + 0.55 * hs(id)) * grow;
	float w = 0.34 * (1.0 - clamp(yy / max(hgt, 0.01), 0.0, 1.0) * 0.7);
	float jet = smoothstep(w, w - 0.12, abs(f)) * smoothstep(hgt, hgt - 0.12, yy);
	float drop = smoothstep(0.16, 0.05, length(vec2(f * 1.2, (yy - hgt - 0.07) * count * 0.16)));
	float drop2 = smoothstep(0.1, 0.03, length(vec2((f - 0.2) * 1.2, (yy - hgt * 1.25 - 0.1) * count * 0.16)));
	float v = jet * (0.6 + 0.4 * yy / max(hgt, 0.01)) + drop + drop2 * 0.8;
	vec3 c = mix(col2, col1, clamp(yy / max(hgt, 0.01), 0.0, 1.0));
	c = mix(c, vec3(0.9, 0.98, 1.0), clamp(drop + drop2 + jet * smoothstep(hgt - 0.2, hgt, yy) * 0.7, 0.0, 1.0));
	ALBEDO = c * energy;
	ALPHA = clamp(v, 0.0, 1.0) * alpha;
}
"""

# A whirl (on a cone without caps): bands winding up it, swaying. A whirlwind, a waterspout,
# a pillar of fire, by its colours.
const TWISTER := """
uniform vec3 col1 : source_color = vec3(0.8, 1.0, 0.85);
uniform vec3 col2 : source_color = vec3(0.25, 0.9, 0.55);
uniform float energy = 2.0;
uniform float alpha = 1.0;
uniform float speed = 1.0;
uniform float sway = 0.14;
uniform float seed = 0.0;
varying vec2 uv;
""" + NOISE + """
void vertex() {
	uv = UV;
	float yy = 1.0 - UV.y;
	VERTEX.x += sin(TIME * 6.0 * speed + yy * 5.0 + seed) * sway * yy;
	VERTEX.z += cos(TIME * 5.0 * speed + yy * 4.0 + seed) * sway * yy;
}
void fragment() {
	float yy = 1.0 - uv.y;
	float s = uv.x * 6.2831853;
	float t = TIME * speed;
	float bands = pow(0.5 + 0.5 * sin(s * 3.0 + yy * 13.0 - t * 19.0), 3.0);
	float fine = pow(0.5 + 0.5 * sin(s * 11.0 + yy * 31.0 - t * 33.0 + seed), 9.0);
	float n = fbm(vec2(uv.x * 9.0 - t * 3.2, yy * 4.0 - t * 1.6 + seed));
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 0.5);
	float v = (bands * 0.62 + fine * 0.6 + n * 0.28) * (0.35 + 0.65 * rim);
	v *= smoothstep(0.0, 0.1, yy) * smoothstep(1.0, 0.72, yy);
	ALBEDO = mix(col2, col1, clamp(bands * 0.7 + fine, 0.0, 1.0)) * energy;
	ALPHA = clamp(v, 0.0, 1.0) * alpha;
}
"""

# What a hit leaves on the floor. `age` runs 0 to 1.
# 0 embers in a scorch, 1 ripples, 2 a pool of shadow (drawn over), 3 cracks from a point.
const DECAL := """
uniform float age = 0.0;
uniform int mode = 0;
uniform vec3 col1 : source_color = vec3(1.0);
uniform vec3 col2 : source_color = vec3(1.0);
uniform float energy = 2.2;
uniform float alpha = 1.0;
uniform float seed = 0.0;
""" + NOISE + """
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float t = TIME;
	vec3 c = col1;
	float v = 0.0;
	if (mode == 0) {
		float n = fbm(p * 4.6 + seed);
		float veins = smoothstep(0.075, 0.0, abs(n - 0.5));
		float fall = smoothstep(1.0, 0.1, r + (fbm(vec2(a * 2.0 + seed, 1.0)) - 0.5) * 0.5);
		float flick = 0.6 + 0.4 * sin(t * 9.0 + n * 22.0);
		float cool = 1.0 - smoothstep(0.15, 1.0, age);
		v = (veins * flick * 1.1 + 0.22 * (1.0 - r)) * fall * cool;
		c = mix(col2, col1, veins);
		c = mix(c, vec3(1.0, 0.95, 0.7), veins * (1.0 - age) * 0.6);
	} else if (mode == 1) {
		float grow = 0.25 + age * 0.85;
		float w = sin(r * 30.0 - t * 9.0 - seed);
		float lines = pow(max(w, 0.0), 6.0);
		float sheen = fbm(p * 3.0 + vec2(t * 0.4, seed)) * 0.25;
		float fall = smoothstep(grow, grow - 0.45, r);
		v = (lines * 0.85 + sheen) * fall * (1.0 - smoothstep(0.35, 1.0, age));
		c = mix(col2, col1, lines);
		c = mix(c, vec3(1.0), lines * 0.5);
	} else if (mode == 2) {
		float open = sin(clamp(age, 0.0, 1.0) * 3.14159);
		open = clamp(open * 1.8, 0.0, 1.0);
		float edge = (0.62 + 0.3 * fbm(vec2(a * 2.4 + seed, t * 0.7))) * open;
		float arms = edge + pow(max(sin(a * 5.0 + seed + t * 0.6), 0.0), 3.0) * 0.26 * open;
		float inside = smoothstep(arms, arms - 0.1, r);
		float rim = smoothstep(0.13, 0.0, abs(r - arms + 0.05)) * step(0.02, open);
		float swirl = pow(0.5 + 0.5 * sin(a * 3.0 + log(r + 0.05) * 5.0 - t * 4.0), 3.0) * inside * 0.5;
		ALBEDO = mix(vec3(0.0, 0.0, 0.015), col1 * energy, clamp(rim + swirl * 0.45, 0.0, 1.0));
		ALPHA = clamp(max(inside * 0.93, rim), 0.0, 1.0) * alpha;
	} else {
		float k = 9.0;
		float u = (a + 3.14159) / 6.2831853 * k;
		float id = floor(u);
		float f = fract(u) - 0.5;
		float jag = (vnoise(vec2(r * 9.0, id + seed)) - 0.5) * 0.75;
		float d = abs(f - jag * 0.5) * r * (6.2831853 / k);
		float grow = clamp(age * 5.0, 0.0, 1.0);
		float reach = (0.45 + 0.55 * h21(vec2(id, seed))) * grow;
		float core = smoothstep(0.022, 0.0, d) * step(r, reach);
		float glow = exp(-d * 26.0) * 0.5 * smoothstep(reach + 0.1, reach - 0.2, r);
		float cool = 1.0 - smoothstep(0.3, 1.0, age);
		v = (core * 1.4 + glow) * cool + exp(-r * r * 9.0) * 0.5 * cool;
		c = mix(col1, vec3(1.0, 0.95, 0.75), core * (1.0 - age));
	}
	if (mode != 2) {
		ALBEDO = c * energy;
		ALPHA = clamp(v, 0.0, 1.0) * alpha * smoothstep(1.0, 0.9, r);
	}
}
"""

# A spike of rock (or of shadow): flat faces lit from above, glowing where it broke the floor.
const ROCK := """
shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform vec3 base : source_color = vec3(0.48, 0.38, 0.28);
uniform vec3 glow : source_color = vec3(1.0, 0.7, 0.3);
uniform float heat = 1.0;
uniform float edge = 0.0;
varying float hgt;
varying vec3 vpos;
void vertex() {
	hgt = UV.y;
	vpos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 n = normalize(cross(dFdx(vpos), dFdy(vpos)));
	vec3 up = normalize((VIEW_MATRIX * vec4(0.25, 0.9, 0.35, 0.0)).xyz);
	float l = 0.18 + 0.82 * pow(clamp(dot(n, up) * 0.5 + 0.5, 0.0, 1.0), 1.6);
	float rim = pow(1.0 - abs(n.z), 2.5);
	// (strata: darker bands across it)
	float band = 0.82 + 0.18 * sin(hgt * 34.0 + n.x * 5.0);
	vec3 c = base * l * 1.3 * band;
	c += glow * smoothstep(0.55, 1.0, hgt) * heat * 1.6;
	c += glow * rim * edge * 2.2;
	ALBEDO = c;
}
"""

static var _sh := {}


static func _shader(key: String, code: String) -> Shader:
	if not _sh.has(key):
		var s := Shader.new()
		s.code = code
		_sh[key] = s
	return _sh[key]


static func _mat(key: String, code: String, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(key, code)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


static func _t(sec: float) -> float:
	return Settings.t(sec)


static func _later(board: Node, sec: float, what: Callable) -> void:
	if sec <= 0.0:
		what.call()
		return
	board.get_tree().create_timer(_t(sec)).timeout.connect(func():
		if is_instance_valid(board):
			what.call())


static func _piece(board: Node, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 8.0
	mi.position = at
	board.add_child(mi)
	return mi


## The Attribute a monster attacks with ("" has none: it gets LIGHT's shapes in a plain white).
static func attr_of(inst) -> String:
	var a := str(inst.data.get("attribute", "")) if inst != null else ""
	return a if PAL.has(a) else ""


static func pal(attr: String) -> Array:
	return PAL.get(attr, [Color("ffe9c8"), Color("ffb070"), Color.WHITE])


## How big the attack plays: 0 a quick one, 1 a real one, 2 the full show.
static func tier_of(inst, atk := -1) -> int:
	if inst == null:
		return 0
	var a := atk if atk >= 0 else int(inst.atk())
	if a >= 2400 or int(inst.data.get("level", 0)) >= 7:
		return 2
	return 1 if a >= 1500 else 0


## Does this kind of monster shoot from where it stands (true) or charge in (false)?
static func ranged(inst) -> bool:
	return StrikeFx.kind_of(inst) in ["beam", "blast"]


# ---------------------------------------------------------------- the pieces

## A band of the element from `a` to `b`. Its front crosses in `dur`, it holds, then lets go from the back.
## opts: arc, flat, mix, hold, fade, energy, alpha.
static func ribbon(board: Node3D, a: Vector3, b: Vector3, mode: int, c1: Color, c2: Color, width: float, dur: float, opts := {}) -> void:
	var mixed: bool = opts.get("mix", mode in [0, 1, 4])
	var m := _mat("ribbon_mix" if mixed else "ribbon_add", (MIX_W if mixed else ADD_W) + RIBBON, {
		"pa": board.to_global(a), "pb": board.to_global(b), "width": width, "arc": float(opts.get("arc", 0.0)), "flat_on": 1.0 if opts.get("flat", false) else 0.0,
		"head": 0.0, "tail": -0.2, "mode": mode, "col1": c1, "col2": c2, "energy": float(opts.get("energy", 1.45 if mixed else 1.35)), "alpha": float(opts.get("alpha", 1.0)), "seed": randf() * 30.0})
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	pm.subdivide_width = 28
	pm.orientation = PlaneMesh.FACE_Z
	var mi := _piece(board, pm, m, Vector3.ZERO)
	mi.extra_cull_margin = 60.0
	var tw := mi.create_tween()
	tw.tween_property(m, "shader_parameter/head", 1.15, _t(dur)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(_t(float(opts.get("hold", 0.08))))
	tw.tween_property(m, "shader_parameter/tail", 1.1, _t(float(opts.get("fade", 0.28)))).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)


## A burst facing the camera, `size` across, living `life` seconds. It can rise as it goes.
static func puff(board: Node3D, at: Vector3, mode: int, c1: Color, c2: Color, size: float, life: float, rise := 0.0, delay := 0.0, grow := 1.0) -> void:
	var mixed := mode != 2
	var m := _mat("puff_mix" if mixed else "puff_add", (MIX if mixed else ADD) + "varying vec2 uv;\n" + PUFF, {"age": 0.0, "mode": mode, "col1": c1, "col2": c2,
		"energy": 1.7, "alpha": 0.0 if delay > 0.0 else 1.0, "seed": randf() * 40.0})
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var mi := _piece(board, q, m, at)
	mi.scale = Vector3.ONE * size
	var tw := mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(_t(delay))
		tw.tween_callback(func(): m.set_shader_parameter("alpha", 1.0))
	tw.tween_property(m, "shader_parameter/age", 1.0, _t(life))
	if rise != 0.0:
		tw.parallel().tween_property(mi, "position:y", at.y + rise, _t(life)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if grow != 1.0:
		tw.parallel().tween_property(mi, "scale", Vector3.ONE * size * grow, _t(life)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mi.queue_free)


## A mark on the floor, `size` across, cooling over `life` seconds.
static func decal(board: Node3D, at: Vector3, mode: int, c1: Color, c2: Color, size: float, life: float, delay := 0.0, energy := 1.5) -> void:
	var mixed := mode == 2
	var m := _mat("decal_mix" if mixed else "decal_add", (MIX if mixed else ADD) + DECAL, {"age": 0.0, "mode": mode, "col1": c1, "col2": c2, "energy": energy,
		"alpha": 0.0 if delay > 0.0 else 1.0, "seed": randf() * 40.0})
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.orientation = PlaneMesh.FACE_Y
	var mi := _piece(board, q, m, Vector3(at.x, 0.045 if mixed else 0.05, at.z))
	var tw := mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(_t(delay))
		tw.tween_callback(func(): m.set_shader_parameter("alpha", 1.0))
	tw.tween_property(m, "shader_parameter/age", 1.0, _t(life))
	tw.tween_callback(mi.queue_free)


## A whirl standing on the floor: `r0` wide at its foot, `r1` at its top.
static func twister(board: Node3D, at: Vector3, c1: Color, c2: Color, r0: float, r1: float, height: float, life: float, delay := 0.0, speed := 1.0, energy := 1.25) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = height
	cyl.radial_segments = 28
	cyl.rings = 10
	cyl.cap_top = false
	cyl.cap_bottom = false
	var m := _mat("twister", ADD + TWISTER, {"col1": c1, "col2": c2, "energy": energy, "alpha": 0.0, "speed": speed, "sway": 0.06 + r1 * 0.12, "seed": randf() * 20.0})
	var mi := _piece(board, cyl, m, Vector3(at.x, height * 0.5, at.z))
	mi.scale = Vector3(0.25, 0.3, 0.25)
	var tw := mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(_t(delay))
	tw.tween_property(m, "shader_parameter/alpha", 1.0, _t(0.1))
	tw.parallel().tween_property(mi, "scale", Vector3.ONE, _t(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mi, "position:y", height * 0.5, _t(0.2)).from(height * 0.15)
	tw.tween_interval(_t(maxf(0.0, life - 0.5)))
	tw.tween_property(m, "shader_parameter/alpha", 0.0, _t(0.32))
	tw.parallel().tween_property(mi, "scale", Vector3(1.5, 1.08, 1.5), _t(0.32))
	tw.tween_callback(mi.queue_free)
	return mi


## A ring of jets thrown up: water from a splash, earth from a blow.
static func crown(board: Node3D, at: Vector3, c1: Color, c2: Color, radius: float, height: float, life: float, count := 14.0, delay := 0.0) -> void:
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = radius
	cyl.top_radius = radius
	cyl.height = height
	cyl.radial_segments = 32
	cyl.rings = 6
	cyl.cap_top = false
	cyl.cap_bottom = false
	var m := _mat("crown", MIX + CROWN, {"grow": 0.0, "count": count, "flare": 0.7, "col1": c1, "col2": c2, "energy": 1.4, "alpha": 1.0, "seed": randf() * 20.0})
	var mi := _piece(board, cyl, m, Vector3(at.x, height * 0.5, at.z))
	mi.scale = Vector3(0.55, 1, 0.55)
	var tw := mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(_t(delay))
	tw.tween_property(m, "shader_parameter/grow", 1.0, _t(life * 0.4)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mi, "scale", Vector3(1.0, 1, 1.0), _t(life * 0.4)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "shader_parameter/grow", 0.0, _t(life * 0.6)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(mi, "scale", Vector3(1.35, 1, 1.35), _t(life * 0.6))
	tw.parallel().tween_property(m, "shader_parameter/alpha", 0.0, _t(life * 0.6)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)


## A wave across the field, running from `from` to `to` and breaking there.
static func wave(board: Node3D, from: Vector3, to: Vector3, c1: Color, c2: Color, width: float, height: float, dur: float) -> void:
	var m := _mat("wave", MIX + WAVE, {"rise": 0.0, "curl": height * 0.42, "col1": c1, "col2": c2, "energy": 1.15, "alpha": 1.0, "seed": randf() * 20.0})
	var pm := PlaneMesh.new()
	pm.size = Vector2(width, height)
	pm.subdivide_depth = 10
	pm.orientation = PlaneMesh.FACE_Z
	var mi := _piece(board, pm, m, Vector3(from.x, height * 0.5, from.z))
	var dir := to - from
	dir.y = 0.0
	if dir.length() > 0.01:
		mi.rotation.y = atan2(dir.x, dir.z)
	var tw := mi.create_tween()
	tw.tween_property(m, "shader_parameter/rise", 1.0, _t(dur * 0.45)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mi, "position", Vector3(to.x, height * 0.5, to.z), _t(dur)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# It breaks: the crest falls forward and the body drops.
	tw.tween_property(m, "shader_parameter/curl", height * 1.5, _t(0.16))
	tw.parallel().tween_property(m, "shader_parameter/rise", 0.0, _t(0.22)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(m, "shader_parameter/alpha", 0.0, _t(0.22))
	tw.tween_callback(mi.queue_free)


## A spike that comes up out of the floor (rock, or shadow), stands a moment and goes back.
## `lean` tips it toward `toward`; `snap` tips it further once it is up (fangs closing).
static func spike(board: Node3D, at: Vector3, radius: float, height: float, base: Color, glow: Color, delay: float, hold: float, toward := Vector3.ZERO, lean := 0.0, snap := 0.0, edge := 0.0) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 5
	cyl.rings = 1
	var m := _mat("rock", ROCK, {"base": base, "glow": glow, "heat": 1.0 if edge == 0.0 else 0.25, "edge": edge})
	var pivot := Node3D.new()
	pivot.position = Vector3(at.x, 0.0, at.z)
	board.add_child(pivot)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = -height * 0.55
	mi.rotation.y = randf() * TAU
	pivot.add_child(mi)
	var axis := Vector3.RIGHT
	if lean != 0.0 or snap != 0.0:
		var d := toward - at
		d.y = 0.0
		if d.length() > 0.01:
			axis = Vector3.UP.cross(d.normalized()).normalized()
			pivot.transform.basis = Basis(axis, lean)
	var tw := pivot.create_tween()
	tw.tween_interval(_t(delay))
	tw.tween_property(mi, "position:y", height * 0.48, _t(0.11)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if snap != 0.0:
		tw.tween_interval(_t(0.05))
		tw.tween_method(func(v: float): pivot.transform.basis = Basis(axis, v), lean, snap, _t(0.08)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(m, "shader_parameter/heat", 0.15 if edge == 0.0 else 0.0, _t(hold))
	tw.tween_property(mi, "position:y", -height * 0.6, _t(0.3)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(pivot, "scale", Vector3(0.7, 1.0, 0.7), _t(0.3))
	tw.tween_callback(pivot.queue_free)


## A blade of light dropping out of the sky into the floor.
static func lance(board: Node3D, at: Vector3, color: Color, length: float, delay: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.085
	cyl.bottom_radius = 0.0
	cyl.height = length
	cyl.radial_segments = 4
	cyl.rings = 1
	var m := StrikeFx._add_mat(color, 0.0)
	var mi := _piece(board, cyl, m, Vector3(at.x + 0.9, 7.0, at.z - 0.6))
	mi.rotation = Vector3(0.1, 0.0, 0.13)
	var land := Vector3(at.x, length * 0.5 - 0.1, at.z)
	var tw := mi.create_tween()
	tw.tween_interval(_t(delay))
	tw.tween_property(m, "albedo_color:a", 0.95, _t(0.03))
	tw.tween_property(mi, "position", land, _t(0.09)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		DuelFx.ring(board, Vector3(at.x, 0.03, at.z), color, 0.1, 0.7, 0.3, 0.05)
		DuelFx.glow(board, Vector3(at.x, 0.15, at.z), color, 0.8, 0.25, 0.6, 1.8))
	tw.tween_interval(_t(0.22))
	tw.tween_property(m, "albedo_color:a", 0.0, _t(0.22))
	tw.parallel().tween_property(mi, "scale", Vector3(0.2, 1.0, 0.2), _t(0.22))
	tw.tween_callback(mi.queue_free)


## A flash of coloured light on the table and the monsters around the hit.
static func light(board: Node3D, at: Vector3, color: Color, power: float, life: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 0.0
	l.omni_range = 6.5
	l.shadow_enabled = false
	l.position = at + Vector3(0, 1.0, 0)
	board.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", power, _t(0.06))
	tw.tween_property(l, "light_energy", 0.0, _t(life)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)


## Compile every shader before the first attack, so none of them stutters.
static func warm(board: Node3D) -> void:
	var under := Vector3(0, -40, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.01, 0.01)
	var made: Array = []
	for spec in [["ribbon_add", ADD_W + RIBBON], ["ribbon_mix", MIX_W + RIBBON], ["puff_add", ADD + "varying vec2 uv;\n" + PUFF], ["puff_mix", MIX + "varying vec2 uv;\n" + PUFF],
			["decal_add", ADD + DECAL], ["decal_mix", MIX + DECAL], ["twister", ADD + TWISTER], ["crown", MIX + CROWN], ["wave", MIX + WAVE], ["rock", ROCK]]:
		var m := _mat(str(spec[0]), str(spec[1]), {})
		if str(spec[0]).begins_with("ribbon"):
			m.set_shader_parameter("pa", under)
			m.set_shader_parameter("pb", under + Vector3(0.01, 0, 0))
			m.set_shader_parameter("width", 0.01)
		made.append(_piece(board, q, m, under))
	board.get_tree().create_timer(0.6).timeout.connect(func():
		for mi in made:
			if is_instance_valid(mi):
				mi.queue_free())


# ---------------------------------------------------------------- beat 1: gather

## The element collects around the attacker as it declares its attack.
static func gather(board: Node3D, inst, at: Vector3, tier: int) -> void:
	var attr := attr_of(inst)
	var p := pal(attr)
	var c1: Color = p[0]
	var c2: Color = p[1]
	var k: float = [0.75, 1.0, 1.3][tier]
	var floor_at := Vector3(at.x, 0.03, at.z)
	match attr:
		"FIRE":
			# Tongues of flame come up in a ring around it.
			for i in (3 + tier * 2):
				var a := TAU * float(i) / float(3 + tier * 2) + randf() * 0.5
				puff(board, floor_at + Vector3(cos(a) * 0.5 * k, 0.5 * k, sin(a) * 0.38 * k), 1, c1, c2, 1.1 * k, 0.62, 0.25, i * 0.035)
			DuelFx.ring(board, floor_at, c1, 0.9 * k, 0.35, 0.4, 0.05)
			DuelFx.embers(board, floor_at, c1, 0.45 * k, 14 + tier * 8, 0.7, 2.6, 0.06)
			light(board, at, c1, 1.2 * k, 0.6)
			Sfx.play("el_fire_up", -9.0, 1.2)
		"WATER":
			crown(board, floor_at, c1, c2, 0.5 * k, 1.3 * k, 0.75, 11.0)
			decal(board, floor_at, 1, c1, c2, 2.2 * k, 0.9)
			if tier >= 1:
				twister(board, floor_at, c1, c2, 0.3 * k, 0.5 * k, 1.9 * k, 0.6, 0.05, 0.8, 1.0)
			light(board, at, c1, 1.0 * k, 0.6)
			Sfx.play("el_water_up", -10.0, 1.1)
		"WIND":
			twister(board, floor_at, c1, c2, 0.3 * k, 0.75 * k, 2.2 * k, 0.65, 0.0, 1.2)
			DuelFx.ring(board, floor_at, c2, 0.3, 1.5 * k, 0.4, 0.04)
			DuelFx.ring(board, floor_at, c1, 0.3, 1.1 * k, 0.4, 0.035, 0.1)
			Sfx.play("el_wind", -11.0, 1.4)
		"EARTH":
			decal(board, floor_at, 3, c1, c2, 2.4 * k, 1.0)
			DuelFx.sparks(board, floor_at + Vector3(0, 0.1, 0), Color("c9a878"), 14 + tier * 8, 2.2, 0.85, 0.8, -2.0, 0.07)
			puff(board, floor_at + Vector3(0, 0.3, 0), 3, Color("b89a78"), Color("6a5440"), 1.6 * k, 0.7, 0.3, 0.0, 1.5)
			board.shake(0.22 + 0.1 * tier)
			Sfx.play("el_earth_up", -8.0, 1.1)
		"DARK":
			decal(board, floor_at, 2, c1, c2, 2.5 * k, 0.9)
			for i in (2 + tier):
				var a2 := TAU * float(i) / float(2 + tier) + 0.6
				puff(board, floor_at + Vector3(cos(a2) * 0.42 * k, 0.5 * k, sin(a2) * 0.3 * k), 4, c1, c2, 1.15 * k, 0.65, 0.2, 0.05 + i * 0.04)
			DuelFx.embers(board, floor_at, c1, 0.5 * k, 12 + tier * 6, 0.7, 1.7, 0.05)
			Sfx.play("el_dark_up", -9.0, 1.0)
		"DIVINE":
			DuelFx.glyph(board, floor_at, c1, 1.15 * k, 0.8, {"rings": 2, "ticks": 24, "star": 4, "turn": 2.0, "energy": 2.6})
			DuelFx.pillar(board, Vector3(at.x, 0, at.z), c1, 0.4 * k, 7.0, 0.7, 0.0, 2.0)
			DuelFx.embers(board, floor_at, c1, 0.55 * k, 26, 0.8, 3.0, 0.06)
			light(board, at, c1, 1.8, 0.7)
			Sfx.play("el_light_up", -8.0, 0.8)
		_:
			# LIGHT (and monsters with no Attribute): a halo opens over it and light climbs to it.
			DuelFx.glyph(board, floor_at + Vector3(0, 1.7 * k, 0), c1, 0.55 * k, 0.7, {"rings": 1, "ticks": 0, "star": 0, "turn": 1.2, "energy": 2.8})
			DuelFx.glyph(board, floor_at, c2, 0.85 * k, 0.7, {"rings": 1, "ticks": 18, "star": 0, "turn": -1.6, "energy": 2.2})
			DuelFx.embers(board, floor_at, c1, 0.45 * k, 16 + tier * 8, 0.7, 2.8, 0.05)
			DuelFx.glow(board, at + Vector3(0, 0.9 * k, 0), c1, 1.2 * k, 0.5, 0.8, 1.4)
			light(board, at, c1, 1.2 * k, 0.6)
			Sfx.play("el_light_up", -10.0, 1.2)


# ---------------------------------------------------------------- beat 2: travel

## The element crosses the field with the attack, arriving after `dur` seconds.
## `from` is where the attacker stands, `to` where the attack lands.
static func travel(board: Node3D, inst, from: Vector3, to: Vector3, tier: int, dur: float) -> void:
	var attr := attr_of(inst)
	var p := pal(attr)
	var c1: Color = p[0]
	var c2: Color = p[1]
	var k: float = [0.8, 1.0, 1.3][tier]
	var shoot := ranged(inst)
	var a := Vector3(from.x, 0.95 if shoot else 0.4, from.z)
	var b := Vector3(to.x, 0.6 if shoot else 0.4, to.z)
	var fa := Vector3(from.x, 0.05, from.z)
	var fb := Vector3(to.x, 0.05, to.z)
	match attr:
		"FIRE":
			ribbon(board, a, b, 0, c1, c2, (1.15 if shoot else 0.95) * k, dur, {"arc": 0.25 if shoot else 0.0, "hold": 0.1, "fade": 0.32})
			if tier >= 1:
				# (the floor under it catches)
				ribbon(board, fa, fb, 0, c2, c2.darkened(0.3), 0.6 * k, dur, {"flat": true, "hold": 0.25, "fade": 0.5, "alpha": 0.55})
			Sfx.play("el_fire", -7.0, 1.0)
		"WATER":
			ribbon(board, a, b, 1, c1, c2, (1.1 if shoot else 0.9) * k, dur, {"arc": 0.2 if shoot else 0.0, "hold": 0.1, "fade": 0.3})
			if tier >= 1:
				wave(board, from.lerp(to, 0.12), to, c1, c2, 2.5 * k, 1.7 * k, dur)
			ribbon(board, fa, fb, 1, c1, c2, 0.8 * k, dur, {"flat": true, "hold": 0.2, "fade": 0.5, "alpha": 0.5})
			Sfx.play("el_water", -7.0, 1.0)
		"WIND":
			ribbon(board, a, b, 2, c1, c2, 1.3 * k, dur, {"hold": 0.12, "fade": 0.3})
			ribbon(board, a + Vector3(0, 0.3, 0), b + Vector3(0, 0.3, 0), 2, c1, c2, 0.9 * k, dur * 0.85, {"hold": 0.1, "fade": 0.25, "alpha": 0.7})
			if shoot or tier >= 1:
				# Blades of air fly ahead of it.
				for i in (2 + tier):
					var at := a.lerp(b, 0.45 + i * 0.18)
					_later(board, dur * (0.3 + i * 0.2), func(): StrikeFx._slash(board, at, c1, 0.5 - i * 0.6, 0.0, 0.0, 2.2 * k))
			Sfx.play("el_wind", -7.0, 1.6)
		"EARTH":
			ribbon(board, fa, fb, 5, c1, c2, 1.5 * k, dur, {"flat": true, "hold": 0.5, "fade": 0.6})
			# Stones jump out of the crack as it runs.
			for i in (3 + tier * 2):
				var f := (float(i) + 0.5) / float(3 + tier * 2)
				var sp := fa.lerp(fb, f) + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.15, 0.15))
				spike(board, sp, 0.14 * k, (0.38 + randf() * 0.3) * k, Color("6a5038"), c1, dur * f * 0.9, 0.2)
			if shoot:
				ribbon(board, a, b, 3, Color("d8c0a0"), c2, 0.5 * k, dur, {"arc": 0.5, "hold": 0.05, "fade": 0.2, "alpha": 0.6})
			board.shake(0.2 + 0.08 * tier)
			Sfx.play("el_earth", -7.0, 1.2)
		"DARK":
			ribbon(board, fa, fb, 4, c1, c2, 1.25 * k, dur, {"flat": true, "hold": 0.25, "fade": 0.45})
			ribbon(board, a, b, 4, c1, c2, (1.0 if shoot else 0.8) * k, dur, {"arc": 0.2 if shoot else 0.0, "hold": 0.1, "fade": 0.3})
			Sfx.play("el_dark", -8.0, 1.1)
		"DIVINE":
			ribbon(board, a, b, 6, c1, c2, 1.5 * k, dur, {"hold": 0.12, "fade": 0.3, "energy": 1.7})
			ribbon(board, fa, fb, 3, c1, c2, 0.6 * k, dur, {"flat": true, "hold": 0.3, "fade": 0.5, "alpha": 0.6})
			Sfx.play("el_thunder", -7.0, 1.2)
		_:
			ribbon(board, a, b, 3, c1, c2, (0.95 if shoot else 0.75) * k, dur * 0.8, {"hold": 0.14, "fade": 0.3, "energy": 1.6})
			if tier >= 1:
				ribbon(board, fa, fb, 3, c2, c2, 0.45 * k, dur, {"flat": true, "hold": 0.25, "fade": 0.45, "alpha": 0.5})
			Sfx.play("el_light", -8.0, 1.1)


# ---------------------------------------------------------------- beat 3: impact

## The attack lands at `at` (the target's place on the table, or in front of the duelist it
## goes through to), having come from `from`.
static func impact(board: Node3D, inst, from: Vector3, at: Vector3, tier: int) -> void:
	var attr := attr_of(inst)
	var p := pal(attr)
	var c1: Color = p[0]
	var c2: Color = p[1]
	var hot: Color = p[2]
	var k: float = [0.72, 1.0, 1.35][tier]
	var f := Vector3(at.x, 0.03, at.z)
	var mid := Vector3(at.x, 0.75 * k, at.z)
	light(board, f, c1, 1.5 + 0.8 * tier, 0.55)
	match attr:
		"FIRE":
			puff(board, mid, 0, c1, c2, 2.0 * k, 0.8, 0.35, 0.0, 1.15)
			puff(board, mid + Vector3(0.4 * k, 0.35, 0.1), 0, c1, c2, 1.3 * k, 0.65, 0.5, 0.07, 1.2)
			puff(board, mid + Vector3(-0.35 * k, 0.15, -0.1), 0, c1, c2, 1.15 * k, 0.6, 0.4, 0.12, 1.2)
			decal(board, f, 0, c1, c2, 2.9 * k, 1.9)
			DuelFx.ring(board, f, c1, 0.3, 1.9 * k, 0.45, 0.06)
			DuelFx.rays(board, f, hot, 2.2 * k, 0.4, 22)
			DuelFx.sparks(board, f + Vector3(0, 0.2, 0), c1, int(26 * k), 5.5, 0.6, 0.9, -7.0, 0.06)
			DuelFx.embers(board, f, c1, 0.7 * k, int(20 * k), 1.0, 2.2, 0.06)
			if tier >= 1:
				for i in (3 + tier * 2):
					var a := TAU * float(i) / float(3 + tier * 2)
					puff(board, f + Vector3(cos(a) * 0.75 * k, 0.55 * k, sin(a) * 0.6 * k), 1, c1, c2, 1.25 * k, 0.75, 0.3, 0.08 + i * 0.03)
			if tier >= 2:
				# A pillar of fire stands where it hit.
				twister(board, f, hot, c1, 0.45, 0.85, 3.6, 0.95, 0.05, 1.1, 1.5)
				puff(board, mid + Vector3(-0.2, 1.3, 0), 0, c1, c2, 1.9, 0.7, 0.9, 0.18, 1.2)
			Sfx.play("el_fire_hit", -4.0, 1.0 - 0.08 * tier)
		"WATER":
			crown(board, f, c1, c2, 0.75 * k, 2.1 * k, 0.8, 16.0)
			crown(board, f, c1.lightened(0.15), c2, 0.4 * k, 1.3 * k, 0.6, 9.0, 0.06)
			decal(board, f, 1, c1, c2, 3.6 * k, 1.9)
			for i in 3:
				DuelFx.ring(board, f, c1.lerp(c2, i * 0.3), 0.25, (1.3 + i * 0.6) * k, 0.55, 0.045, i * 0.1, 1.6)
			DuelFx.sparks(board, f + Vector3(0, 0.3, 0), c1.lightened(0.3), int(30 * k), 5.0, 0.8, 0.95, -10.0, 0.055)
			puff(board, mid, 2, c1, c2, 1.6 * k, 0.8, 0.5, 0.0, 1.3)
			if tier >= 2:
				# A waterspout goes up from it.
				twister(board, f, c1, c2, 0.4, 0.75, 3.6, 0.9, 0.04, 0.9, 0.8)
			Sfx.play("el_water_hit", -4.0, 1.0 - 0.08 * tier)
		"WIND":
			twister(board, f, c1, c2, 0.4 * k, 1.15 * k, 3.4 * k, 0.6 + 0.25 * tier, 0.0, 1.4, 0.8)
			if tier >= 1:
				twister(board, f, c1, c2, 0.2 * k, 0.6 * k, 2.6 * k, 0.5 + 0.2 * tier, 0.05, 1.9, 0.7)
			for i in (1 + tier):
				StrikeFx._slash(board, mid + Vector3(0, 0.15 * i, 0), c2.lightened(0.3), -0.9 + i * 0.85, 0.0, 0.04 + i * 0.07, 2.3 * k)
			DuelFx.ring(board, f, c2, 0.3, 2.3 * k, 0.4, 0.04, 0.0, 1.7)
			DuelFx.ring(board, f, c2, 0.3, 1.6 * k, 0.4, 0.035, 0.08, 1.7)
			DuelFx.sparks(board, f + Vector3(0, 0.4, 0), c1, int(22 * k), 4.5, 0.25, 0.7, 1.5, 0.04)
			Sfx.play("el_wind_hit", -4.0, 1.0 - 0.08 * tier)
		"EARTH":
			decal(board, f, 3, c1, c2, 3.6 * k, 2.0)
			# Rocks come up under it: one big one in the middle, a ring around.
			spike(board, f, 0.34 * k, 1.75 * k, Color("6a5038"), c1, 0.0, 0.55)
			var n := 3 + tier * 2
			for i in n:
				var a2 := TAU * float(i) / float(n) + 0.4
				var d := (0.48 + randf() * 0.2) * k
				spike(board, f + Vector3(cos(a2) * d, 0, sin(a2) * d), (0.2 + randf() * 0.08) * k, (0.85 + randf() * 0.5) * k, Color("5a4532").lerp(Color("7d6248"), randf()), c1,
					0.03 + i * 0.022, 0.45, f + Vector3(cos(a2), 0, sin(a2)) * 3.0, 0.3)
			for i in 3:
				var a3 := TAU * float(i) / 3.0 + 1.0
				puff(board, f + Vector3(cos(a3) * 0.6 * k, 0.4, sin(a3) * 0.5 * k), 3, Color("c2a684"), Color("6a5440"), 1.9 * k, 0.95, 0.5, 0.05 * i, 1.6)
			DuelFx.sparks(board, f + Vector3(0, 0.2, 0), Color("c9a878"), int(28 * k), 5.0, 0.7, 0.95, -13.0, 0.085)
			DuelFx.ring(board, f, c1, 0.3, 2.0 * k, 0.45, 0.06)
			board.shake(0.5 + 0.25 * tier)
			Sfx.play("el_earth_hit", -3.0, 1.0 - 0.1 * tier)
		"DARK":
			decal(board, f, 2, c1, c2, 3.4 * k, 1.35)
			DuelFx.spiral(board, f + Vector3(0, 0.03, 0), c1, c2, 1.0 * k, 0.9, {"arms": 3, "twist": 6.0, "speed": 6.0, "energy": 1.8})
			# Fangs of shadow come up around it and close.
			var n2 := 4 + tier * 2
			for i in n2:
				var a4 := TAU * float(i) / float(n2) + 0.3
				var sp := f + Vector3(cos(a4) * 0.72 * k, 0, sin(a4) * 0.6 * k)
				spike(board, sp, 0.15 * k, 1.5 * k, Color(0.035, 0.0, 0.07), c1, 0.02 + i * 0.012, 0.3, f, 0.22, 0.62, 1.0)
			for i in (2 + tier):
				puff(board, mid + Vector3(randf_range(-0.4, 0.4) * k, 0.1, randf_range(-0.2, 0.2)), 4, c1, c2, 2.0 * k, 0.8, 0.5, 0.12 + i * 0.06)
			DuelFx.glow(board, mid, c1, 2.2 * k, 0.4, 0.0, 2.0)
			DuelFx.ring(board, f, c1, 0.3, 1.8 * k, 0.5, 0.05)
			DuelFx.embers(board, f, c1, 0.8 * k, int(18 * k), 1.0, 1.4, 0.05)
			if tier >= 2:
				twister(board, f, c1, c2, 0.5, 0.25, 2.8, 0.7, 0.1, 1.3, 1.1)
			Sfx.play("el_dark_hit", -4.0, 1.0 - 0.08 * tier)
		"DIVINE":
			DuelFx.pillar(board, Vector3(at.x, 0, at.z), c2, 0.75 * k, 9.0, 0.95, 0.0, 1.1)
			DuelFx.pillar(board, Vector3(at.x, 0, at.z), c1, 0.3 * k, 9.0, 0.8, 0.0, 1.4)
			# Thunder comes down on it three times.
			for i in 3:
				var off := Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.3, 0.3))
				_later(board, i * 0.09, func():
					ribbon(board, Vector3(at.x + off.x * 3.0, 8.0, at.z + off.z), f + off, 6, hot, c1, 1.3, 0.05, {"hold": 0.05, "fade": 0.14, "energy": 2.0})
					DuelFx.glow(board, f + off + Vector3(0, 0.3, 0), c1, 1.4, 0.2, 0.9, 2.0))
			DuelFx.glyph(board, f, c1, 1.6 * k, 1.1, {"rings": 2, "ticks": 28, "star": 4, "turn": 2.4, "energy": 2.8})
			for i in 3:
				DuelFx.ring(board, f, c1.lerp(c2, 0.3 + i * 0.3), 0.3, (1.8 + i * 0.8) * k, 0.55, 0.06, i * 0.08, 1.7)
			DuelFx.rays(board, f, c2, 3.0 * k, 0.5, 30, true, 1.7)
			DuelFx.embers(board, f, c1, 0.9 * k, 40, 1.2, 3.4, 0.07)
			DuelFx.glow(board, mid, c1, 2.0 * k, 0.35, 1.0, 1.5)
			board.shake(0.9)
			board.house(0.8, c1, at, 0.8)
			Sfx.play("el_thunder_hit", -3.0, 0.9)
		_:
			# LIGHT: blades of light fall around it, then the column comes down.
			var n3: int = [0, 3, 5][tier]
			for i in n3:
				var a5 := TAU * float(i) / float(maxi(1, n3)) + 0.5
				lance(board, f + Vector3(cos(a5) * 0.85 * k, 0, sin(a5) * 0.65 * k), c1, 2.6, i * 0.035)
			var wait := 0.0 if n3 == 0 else 0.08
			DuelFx.pillar(board, Vector3(at.x, 0, at.z), c2, 0.55 * k, 8.0, 0.8, wait, 1.25)
			DuelFx.pillar(board, Vector3(at.x, 0, at.z), c1, 0.2 * k, 8.0, 0.65, wait, 1.7)
			DuelFx.glyph(board, f, c2, 1.3 * k, 1.0, {"rings": 2, "ticks": 24, "star": 4 if tier >= 1 else 0, "turn": 2.0, "energy": 2.5})
			DuelFx.glow(board, mid, c1, 2.2 * k, 0.35, 1.0, 1.7)
			DuelFx.ring(board, f, c2, 0.3, 2.0 * k, 0.45, 0.05, wait)
			DuelFx.rays(board, f, c1, 2.4 * k, 0.45, 26, true, 1.8)
			DuelFx.embers(board, f, c1, 0.75 * k, int(22 * k), 1.1, 2.6, 0.055)
			Sfx.play("el_light_hit", -4.0, 1.0 - 0.06 * tier)
