class_name MonsterHolo
extends MeshInstance3D
## The monster itself, standing over its card as a hologram for as long as it is face-up on the
## field. It floats and breathes, leans into an attack when its card lifts, flashes when hit and
## breaks apart into pixels when it leaves. It follows its card, so every card animation moves it.
##
## (0.58.0) It has depth now: three planes, one behind the other. At the back, a halo in the
## colour of its Attribute with a faint echo of the picture and the light coming up from the
## card; in the middle the monster; in front, a few motes that drift past it. Each Attribute
## moves its own way (embers, bubbles, gusts, dust, sparkles, sinking wisps), bigger monsters
## stand taller, and a signature monster has an idle of its own: its own two colours, a circle
## turning under its feet and a gleam that crosses it every few seconds.

const CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, world_vertex_coords;
uniform sampler2D art : source_color, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.3, 0.9, 1.0);
uniform vec2 size = vec2(1.0, 1.0);
uniform float appear = 0.0;     // 0 not there, 1 fully projected
uniform float flash = 0.0;      // white hit flash
uniform float dim = 0.0;        // 1 in Defense Position
uniform float power = 0.0;      // 1 while attacking
uniform float shatter = 0.0;    // 0 whole, 1 gone
uniform float seed = 0.0;
uniform float shade = 1.0;      // below 1 while the player is choosing among other cards
uniform float ace = 0.0;        // 1 for a signature monster
uniform vec3 tint2 : source_color = vec3(1.0);
varying vec2 uv;
float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1)) + seed) * 43758.5453); }
void vertex() {
	uv = UV;
	vec3 base = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 look = normalize(vec3(cam.x - base.x, 0.0, cam.z - base.z) + vec3(0.0, 0.0, 0.0001));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), look));
	float breathe = 1.0 + sin(TIME * 2.1 + seed) * 0.018 + power * 0.16;
	float grow = mix(0.35, 1.0, smoothstep(0.0, 1.0, appear)) * (1.0 - dim * 0.18) * (1.0 + shatter * 0.25);
	float bob = sin(TIME * 1.5 + seed * 1.7) * 0.035 + power * 0.12;
	vec2 l = vec2((UV.x - 0.5) * size.x, (1.0 - UV.y) * size.y) * breathe * grow;
	// Lean back a little so it faces the high duel camera instead of standing bolt upright.
	vec3 up = normalize(vec3(0.0, 1.0, 0.0) - look * 0.38);
	VERTEX = base + right * l.x + up * (l.y + 0.1 + bob);
}
void fragment() {
	vec4 t = texture(art, uv);
	vec2 c = uv - 0.5;
	// The whole picture is projected (nothing of the monster is trimmed away), and its border
	// thins out into scan lines, the way a projection ends, instead of stopping in a straight cut.
	float rad = 0.15;
	vec2 dd = abs(c) - vec2(0.5 - rad);
	float sd = length(max(dd, vec2(0.0))) + min(max(dd.x, dd.y), 0.0) - rad;
	float edge = smoothstep(0.0, -0.11, sd);
	float lines = sin(uv.y * 210.0 + TIME * 2.4 + seed) * 0.5 + 0.5;
	float mask = clamp(edge + edge * (1.0 - edge) * (lines - 0.55) * 1.6, 0.0, 1.0);
	float foot = smoothstep(1.0, 0.82, uv.y);
	float scan = 0.9 + 0.1 * sin(uv.y * 160.0 - TIME * 5.0);
	float flick = 0.96 + 0.04 * sin(TIME * 23.0 + seed);
	vec3 col = t.rgb * scan * flick * (1.12 - dim * 0.38) + tint * (0.08 + power * 0.25);
	col = mix(col, mix(col, vec3(0.45, 0.6, 0.9), 0.45), dim);
	// A signature monster: a gleam crosses it every few seconds.
	float sweep = fract(TIME * 0.22 + seed * 0.13) * 3.2 - 1.1;
	float gleam = smoothstep(0.16, 0.0, abs(uv.x + (1.0 - uv.y) * 0.55 - sweep));
	col += mix(tint2, vec3(1.0), 0.5) * gleam * 0.55 * ace * (1.0 - dim);
	col = mix(col, vec3(1.0), clamp(flash, 0.0, 1.0));
	// Rim of the projector's color where the picture thins out.
	col += tint * (1.0 - mask) * mask * 2.2;
	// Projected from the card upward when it appears.
	float rise = smoothstep(0.0, 0.12, appear * 1.15 - (1.0 - uv.y));
	// Breaking apart: squares drop out at random, the last ones burn white.
	vec2 cell = floor(uv * 14.0);
	float n = hash(cell);
	float alive = step(shatter * 1.1, n);
	col = mix(col, vec3(1.0), smoothstep(0.0, 0.18, shatter) * step(n, shatter * 1.1 + 0.16));
	ALBEDO = col * shade;
	ALPHA = mask * foot * rise * alive * (0.94 - dim * 0.22) * mix(0.55, 1.0, shade);
}
"""

## The planes behind and in front of the picture: halo, echo, projector light, motes.
const AURA := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, world_vertex_coords, blend_add;
uniform sampler2D art : source_color, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.3, 0.9, 1.0);
uniform vec3 tint2 : source_color = vec3(1.0);
uniform vec2 size = vec2(1.0, 1.0);
uniform vec3 pad = vec3(0.5, 0.55, 0.12);   // room around the picture: sides, above, below
uniform float appear = 0.0;
uniform float dim = 0.0;
uniform float power = 0.0;
uniform float shatter = 0.0;
uniform float seed = 0.0;
uniform float shade = 1.0;
uniform float front = 0.0;      // 1: the plane of motes in front of the picture
uniform float depth = -0.11;    // how far behind (or in front of) the picture this plane hangs
uniform float ace = 0.0;
uniform int mode = 0;           // how its Attribute moves (see MODES)
varying vec2 lp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1)) + seed) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	vec3 base = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 look = normalize(vec3(cam.x - base.x, 0.0, cam.z - base.z) + vec3(0.0, 0.0, 0.0001));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), look));
	float breathe = 1.0 + sin(TIME * 2.1 + seed) * 0.018 + power * 0.16;
	float grow = mix(0.35, 1.0, smoothstep(0.0, 1.0, appear)) * (1.0 - dim * 0.18) * (1.0 + shatter * 0.25);
	float bob = sin(TIME * 1.5 + seed * 1.7) * 0.035 + power * 0.12;
	vec2 q = vec2((UV.x - 0.5) * (size.x + pad.x * 2.0), (1.0 - UV.y) * (size.y + pad.y + pad.z) - pad.z);
	lp = q;
	vec2 l = q * breathe * grow;
	vec3 up = normalize(vec3(0.0, 1.0, 0.0) - look * 0.38);
	VERTEX = base + look * depth + right * l.x + up * (l.y + 0.1 + bob);
}
// One sheet of motes: a grid that slides with `vel`, one mote in some of its cells.
// shape 0 soft dot, 1 hollow bubble, 2 square chip, 3 four-point sparkle.
float motes(vec2 p, vec2 vel, vec2 dens, float r, vec2 stretch, float twinkle, float fill, int shape, float sd) {
	vec2 g = (p - vel * TIME) * dens;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id + sd);
	vec2 j = vec2(hash(id + sd + 3.1), hash(id + sd + 7.7)) - 0.5;
	vec2 d = (f - j * 0.55) * stretch;
	float len = length(d);
	float m = smoothstep(r, 0.0, len);
	if (shape == 1) { m = smoothstep(r * 0.3, 0.0, abs(len - r * 0.7)) + smoothstep(r * 0.3, 0.0, length(d + vec2(r * 0.25, -r * 0.25))) * 0.7; }
	if (shape == 2) { m = step(max(abs(d.x), abs(d.y)), r * 0.55); }
	if (shape == 3) { m = smoothstep(r, 0.0, len) * clamp(1.0 - abs(d.x) * abs(d.y) * (90.0 / (r * r * 16.0 + 0.001)) * 0.02, 0.0, 1.0) + smoothstep(r * 0.25, 0.0, len); }
	float tw = mix(1.0, 0.5 + 0.5 * sin(TIME * (2.5 + h * 5.0) + h * 40.0), twinkle);
	return m * step(1.0 - fill, h) * tw;
}
void fragment() {
	vec2 p = lp;
	vec2 c = vec2(p.x, p.y - size.y * 0.5);
	float rad = 0.12;
	vec2 dd = abs(c) - (size * 0.5 - vec2(rad));
	float sd = length(max(dd, vec2(0.0))) + min(max(dd.x, dd.y), 0.0) - rad;
	float out_d = max(sd, 0.0);
	float t = TIME;
	float f = mix(1.0, 1.7, front);      // (the front plane: fewer, bigger, nearer)
	float fill = mix(0.42, 0.2, front) * (1.0 + ace * 0.35);
	// Motes live around the picture and thin out away from it.
	float near = exp(-out_d * mix(3.2, 2.2, front));
	vec2 sway = vec2(sin(p.y * 3.0 + t * 1.3 + seed) * 0.06, 0.0);
	float m = 0.0;
	vec3 mcol = mix(tint, vec3(1.0), 0.35);
	float lick = noise(vec2(p.x * 4.0, p.y * 3.0 - t * 0.5));
	float halo_k = 5.5;
	float extra = 0.0;
	if (mode == 1) {            // FIRE: embers climbing, a halo that licks upward
		m = motes(p + sway * 0.5, vec2(0.0, 0.6), vec2(9.0, 5.0) / f, 0.2, vec2(1.0, 0.55), 0.6, fill, 0, 1.0)
			+ motes(p, vec2(0.05, 0.95), vec2(13.0, 7.0) / f, 0.16, vec2(1.0, 0.5), 0.8, fill * 0.7, 0, 9.0);
		lick = noise(vec2(p.x * 5.0, p.y * 3.5 - t * 2.2));
		halo_k = mix(7.0, 3.0, lick) - smoothstep(0.0, size.y, p.y) * 1.2;
		mcol = mix(tint, vec3(1.0, 0.9, 0.5), 0.5);
	} else if (mode == 2) {     // WATER: bubbles going up, slowly, swaying
		m = motes(p + sway, vec2(0.0, 0.24), vec2(6.0) / f, 0.3, vec2(1.0), 0.0, fill, 1, 2.0)
			+ motes(p - sway, vec2(0.0, 0.36), vec2(9.0) / f, 0.26, vec2(1.0), 0.0, fill * 0.6, 1, 5.0);
		lick = 0.5 + 0.5 * sin(out_d * 26.0 - t * 2.4);
		halo_k = 6.0;
	} else if (mode == 3) {     // WIND: gusts going by
		m = motes(p, vec2(1.3, 0.3), vec2(2.4, 9.0) / f, 0.3, vec2(0.3, 1.0), 0.0, fill, 0, 3.0)
			+ motes(p, vec2(1.9, 0.5), vec2(3.0, 13.0) / f, 0.24, vec2(0.25, 1.0), 0.0, fill * 0.7, 0, 6.0);
		lick = noise(vec2(p.x * 3.0 - t * 2.4, p.y * 6.0));
		halo_k = 6.5;
	} else if (mode == 4) {     // EARTH: chips and dust settling
		m = motes(p, vec2(0.0, -0.14), vec2(7.0) / f, 0.3, vec2(1.0), 0.0, fill, 2, 4.0) * 0.8
			+ motes(p + sway, vec2(0.02, -0.07), vec2(12.0) / f, 0.2, vec2(1.0), 0.3, fill * 0.8, 0, 8.0);
		halo_k = 7.0;
	} else if (mode == 5) {     // LIGHT: sparkles, and rays fanning out behind
		m = motes(p, vec2(0.0, 0.07), vec2(6.5) / f, 0.36, vec2(1.0), 1.0, fill * 1.2, 3, 5.0)
			+ motes(p, vec2(0.02, 0.1), vec2(11.0) / f, 0.3, vec2(1.0), 1.0, fill * 0.8, 3, 2.0);
		float ang = atan(c.y, c.x);
		extra = pow(abs(sin(ang * 7.0 + t * 0.25 + seed)), 10.0) * exp(-out_d * 2.6) * 0.5 * (1.0 - front);
		mcol = mix(tint, vec3(1.0), 0.6);
	} else if (mode == 6) {     // DARK: wisps sinking, a wide slow smoke
		m = motes(p + sway, vec2(0.0, -0.32), vec2(8.0, 3.6) / f, 0.26, vec2(1.0, 0.4), 0.3, fill, 0, 6.0)
			+ motes(p - sway, vec2(0.0, -0.2), vec2(12.0, 5.0) / f, 0.2, vec2(1.0, 0.4), 0.5, fill * 0.7, 0, 3.0);
		lick = noise(vec2(p.x * 3.0 + sin(t * 0.4) * 0.6, p.y * 2.4 + t * 0.7));
		halo_k = mix(5.0, 2.6, lick);
	} else if (mode == 7) {     // lightning: arcs that jump around its edge
		float tick = floor(t * 13.0);
		float ang2 = atan(c.y, c.x);
		float seg = floor((ang2 + 3.14159) / 6.28318 * 7.0);
		float on = step(0.62, hash(vec2(seg, tick)));
		float jag = (noise(vec2(ang2 * 9.0, tick * 3.7)) - 0.5) * 0.22;
		extra = smoothstep(0.035, 0.0, abs(sd - 0.11 - jag)) * on * 1.2 * (1.0 - front);
		m = motes(p, vec2(0.0, 0.12), vec2(8.0) / f, 0.26, vec2(1.0), 1.0, fill * 0.8, 3, 7.0);
		mcol = mix(tint, vec3(1.0), 0.6);
	} else if (mode == 8) {     // petals or feathers coming down across it
		m = motes(p + sway * 2.0, vec2(-0.16, -0.3), vec2(5.5, 6.5) / f, 0.3, vec2(0.6, 1.3), 0.0, fill, 0, 8.0)
			+ motes(p - sway * 2.0, vec2(-0.26, -0.42), vec2(8.0, 9.0) / f, 0.26, vec2(1.3, 0.6), 0.0, fill * 0.7, 0, 1.0);
	} else {
		m = motes(p + sway, vec2(0.0, 0.18), vec2(8.0) / f, 0.24, vec2(1.0), 0.6, fill, 0, 0.0);
	}
	float v = m * near * mix(0.85, 1.25, front);
	vec3 col = mcol * v;
	if (front < 0.5) {
		// The halo, the echo of the picture and the light coming up from the card.
		float halo = exp(-out_d * max(halo_k, 1.6)) * (0.15 + 0.24 * lick) * (1.0 + ace * 0.5 + power * 0.8);
		col += mix(tint, tint2, clamp(out_d * 2.2, 0.0, 1.0) * ace) * halo;
		col += mix(tint, vec3(1.0), 0.4) * extra;
		vec2 guv = vec2(c.x / (size.x * 1.14) + 0.5, 0.5 - c.y / (size.y * 1.14));
		float inb = step(0.0, guv.x) * step(guv.x, 1.0) * step(0.0, guv.y) * step(guv.y, 1.0);
		vec3 echo = texture(art, guv).rgb;
		col += tint * dot(echo, vec3(0.34)) * 0.3 * inb;
		float cw = mix(0.24, size.x * 0.44, smoothstep(-0.1, 0.34, p.y));
		float cone = smoothstep(cw, cw * 0.45, abs(p.x)) * smoothstep(0.42, -0.1, p.y) * step(-0.11, p.y);
		col += tint * cone * (0.3 + 0.12 * sin(p.x * 70.0 + t * 3.0));
	}
	float life = smoothstep(0.25, 1.0, appear) * (1.0 - smoothstep(0.0, 0.6, shatter)) * (1.0 - dim * 0.45) * shade;
	// (nothing may show at the edge of the plane)
	vec2 e = vec2(abs(p.x) / (size.x * 0.5 + pad.x), max((p.y - size.y) / pad.y, 0.0));
	float border = (1.0 - smoothstep(0.82, 1.0, e.x)) * (1.0 - smoothstep(0.75, 1.0, e.y));
	ALBEDO = col * life * border;
	ALPHA = clamp(max(col.r, max(col.g, col.b)) * life * border, 0.0, 1.0);
}
"""

## The floor under it: a pool of light, and for a signature monster a circle that keeps turning.
const POOL := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_add;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 tint2 : source_color = vec3(1.0);
uniform float alpha = 0.0;
uniform float ace = 0.0;
uniform float star = 0.0;
uniform float pool = 1.0;       // radius of the pool of light, in UV units from the middle
uniform float seed = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float v = pow(clamp(1.0 - r / pool, 0.0, 1.0), 2.0) * 0.75;
	vec3 col = tint * v;
	if (ace > 0.5) {
		float a = atan(p.y, p.x);
		float spin = TIME * 0.45 + seed;
		float ring = smoothstep(0.022, 0.0, abs(r - 0.84)) + smoothstep(0.014, 0.0, abs(r - 0.74)) * 0.7;
		float tk = abs(fract((a + spin) / 6.2831853 * 32.0) - 0.5);
		ring += smoothstep(0.4, 0.5, tk) * step(0.75, r) * step(r, 0.83) * 0.7;
		float dash = smoothstep(0.016, 0.0, abs(r - 0.56)) * (0.5 + 0.5 * smoothstep(-0.2, 0.2, sin((a - spin * 1.6) * 9.0)));
		float fig = 0.0;
		if (star > 2.5) {
			float seg = 6.2831853 / star;
			float a1 = mod(a - spin * 0.7, seg) - seg * 0.5;
			float a2 = mod(a - spin * 0.7 + seg * 0.5, seg) - seg * 0.5;
			float inside = step(r, 0.75);
			fig = (smoothstep(0.014, 0.0, abs(r * cos(a1) - 0.74 * cos(seg * 0.5))) + smoothstep(0.014, 0.0, abs(r * cos(a2) - 0.74 * cos(seg * 0.5)))) * inside * 0.6;
		}
		float beat = fract(TIME * 0.4 + seed);
		float wave = smoothstep(0.03, 0.0, abs(r - beat * 0.95)) * (1.0 - beat) * 0.8;
		col += mix(tint, tint2, 0.5 + 0.5 * sin(a * 2.0 + spin)) * (ring + dash + fig + wave) * 2.1;
	}
	col *= smoothstep(1.0, 0.94, r);
	ALBEDO = col * alpha;
	ALPHA = clamp(max(col.r, max(col.g, col.b)) * alpha, 0.0, 1.0);
}
"""

## How each Attribute moves, and how each signature figure does (SummonShow.SIGNATURE).
const MODES := {"FIRE": 1, "WATER": 2, "WIND": 3, "EARTH": 4, "LIGHT": 5, "DARK": 6, "DIVINE": 5}
const FIGURE_MODES := {"flames": 1, "waves": 2, "streaks": 3, "feathers": 8, "hex": 4, "gears": 4, "rays": 5, "stars": 5,
	"galaxy": 5, "cards": 5, "circle": 6, "lightning": 7, "petals": 8}
const FIGURE_STARS := {"circle": 3.0, "gears": 4.0, "stars": 5.0, "galaxy": 5.0, "rays": 4.0, "hex": 3.0}

static var _sh: Shader
static var _aura_sh: Shader
static var _pool_sh: Shader

var card: Node3D           # the Card3D it stands over
var inst                   # the card instance in the duel state
var _mat: ShaderMaterial
var _appear := 0.0
var _delay := 0.0
var _flash := 0.0
var _power := 0.0
var _dim := 0.0
var _want_dim := 0.0
var _gone := false
var _rest_y := 0.0
var _ring: MeshInstance3D
var _layers: Array = []       # the planes behind and in front (ShaderMaterials)
var is_ace := false
var height := 1.0


## How tall a monster stands: by its Level (or Rank) and its ATK. A Level 1 with nothing to it
## is under a metre; a Level 12 with 4000 is close to twice that.
static func height_for(data: Dictionary) -> float:
	var lvl := float(int(data.get("level", 4)))
	var atk := 0.0
	var raw = data.get("atk", 0)
	if typeof(raw) in [TYPE_INT, TYPE_FLOAT]:
		atk = float(raw)
	return 0.94 + clampf(lvl - 1.0, 0.0, 11.0) / 11.0 * 0.42 + clampf((atk - 1000.0) / 3000.0, 0.0, 1.0) * 0.26


func setup(for_inst, on_card: Node3D, color: Color, delay := 0.0, ace := false) -> void:
	inst = for_inst
	card = on_card
	_delay = delay
	if _sh == null:
		_sh = Shader.new()
		_sh.code = CODE
		_aura_sh = Shader.new()
		_aura_sh.code = AURA
		_pool_sh = Shader.new()
		_pool_sh.code = POOL
	var art := Cards.get_art(inst.id)
	# A signature monster wears its own two colours and moves its own way.
	var sig: Array = SummonShow.SIGNATURE.get(str(inst.data.get("name", "")), [])
	is_ace = ace or sig.size() >= 3
	var color2 := color.lightened(0.45)
	var mode: int = MODES.get(str(inst.data.get("attribute", "")), 0)
	var star := 0.0
	if sig.size() >= 3:
		color = Color(str(sig[0]))
		color2 = Color(str(sig[1]))
		if color.get_luminance() < 0.2:
			color = color.lightened(0.35)
		if color2.get_luminance() < 0.2:
			color2 = color2.lightened(0.45)
		mode = FIGURE_MODES.get(str(sig[2]), mode)
		star = float(FIGURE_STARS.get(str(sig[2]), 0.0))
	var h := height_for(inst.data) * (1.07 if is_ace else 1.0)
	height = h
	var w := h * float(art.get_width()) / maxf(1.0, float(art.get_height()))
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	mesh = q
	var sd := randf() * 20.0
	_mat = ShaderMaterial.new()
	_mat.shader = _sh
	_mat.render_priority = 1
	_mat.set_shader_parameter("art", art)
	_mat.set_shader_parameter("tint", color)
	_mat.set_shader_parameter("tint2", color2)
	_mat.set_shader_parameter("ace", 1.0 if is_ace else 0.0)
	_mat.set_shader_parameter("size", Vector2(w, h))
	_mat.set_shader_parameter("seed", sd)
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 4.0
	# The planes behind and in front of it. (The lowest graphics setting keeps only the back one.)
	var pad := Vector3(0.5, 0.55, 0.12)
	var planes: Array = [[0.0, -0.11, 0]]
	if int(Settings.gfx.get("detail", 2)) >= 1:
		planes.append([1.0, 0.2, 2])
	for spec in planes:
		var mi := MeshInstance3D.new()
		var aq := QuadMesh.new()
		aq.size = Vector2(w + pad.x * 2.0, h + pad.y + pad.z)
		mi.mesh = aq
		var am := ShaderMaterial.new()
		am.shader = _aura_sh
		am.render_priority = int(spec[2])
		am.set_shader_parameter("art", art)
		am.set_shader_parameter("tint", color)
		am.set_shader_parameter("tint2", color2)
		am.set_shader_parameter("size", Vector2(w, h))
		am.set_shader_parameter("pad", pad)
		am.set_shader_parameter("seed", sd)
		am.set_shader_parameter("front", float(spec[0]))
		am.set_shader_parameter("depth", float(spec[1]))
		am.set_shader_parameter("ace", 1.0 if is_ace else 0.0)
		am.set_shader_parameter("mode", mode)
		mi.material_override = am
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 5.0
		add_child(mi)
		_layers.append(am)
	# The pool of light it stands in (and, for a signature monster, its circle).
	_ring = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var span := 2.1 if is_ace else 0.95
	pm.size = Vector2(span, span)
	_ring.mesh = pm
	var rm := ShaderMaterial.new()
	rm.shader = _pool_sh
	rm.set_shader_parameter("tint", color)
	rm.set_shader_parameter("tint2", color2)
	rm.set_shader_parameter("alpha", 0.0)
	rm.set_shader_parameter("ace", 1.0 if is_ace else 0.0)
	rm.set_shader_parameter("star", star)
	rm.set_shader_parameter("pool", 0.95 / span)
	rm.set_shader_parameter("seed", sd)
	_ring.material_override = rm
	_ring.position.y = 0.03
	add_child(_ring)
	if is_instance_valid(card):
		_rest_y = card.global_position.y
		global_position = card.global_position


func set_shade(v: float) -> void:
	if _mat:
		_mat.set_shader_parameter("shade", v)
	for am in _layers:
		am.set_shader_parameter("shade", v)


func set_defense(on: bool) -> void:
	_want_dim = 1.0 if on else 0.0


func hit() -> void:
	_flash = 1.0


## Break apart and remove itself.
func shatter() -> void:
	if _gone:
		return
	_gone = true
	_flash = 0.6
	var tw := create_tween()
	tw.tween_method(func(v: float):
		_mat.set_shader_parameter("shatter", v)
		for am in _layers:
			am.set_shader_parameter("shatter", v)
		(_ring.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.55 * (1.0 - v)), 0.0, 1.0, Settings.t(0.45))
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _gone:
		return
	if _delay > 0.0:
		_delay -= delta
		return
	_appear = minf(1.0, _appear + delta / maxf(0.05, Settings.t(0.4)))
	_flash = maxf(0.0, _flash - delta * 3.5)
	_dim = lerpf(_dim, _want_dim, clampf(delta * 8.0, 0.0, 1.0))
	if is_instance_valid(card):
		var cp := card.global_position
		# A lifted card is a monster winding up or striking.
		var lifted := clampf((cp.y - _rest_y - 0.12) / 0.4, 0.0, 1.0)
		_power = lerpf(_power, lifted, clampf(delta * 14.0, 0.0, 1.0))
		global_position = Vector3(cp.x, _rest_y, cp.z)
	_mat.set_shader_parameter("appear", _appear)
	_mat.set_shader_parameter("flash", _flash)
	_mat.set_shader_parameter("dim", _dim)
	_mat.set_shader_parameter("power", _power)
	for am in _layers:
		am.set_shader_parameter("appear", _appear)
		am.set_shader_parameter("dim", _dim)
		am.set_shader_parameter("power", _power)
	(_ring.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.55 * _appear * (1.0 - _dim * 0.5))
