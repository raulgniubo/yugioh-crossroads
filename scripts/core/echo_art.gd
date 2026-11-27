extends RefCounted
## The pictures on the Echo cards (0.81.0): Lumen's two new forms, the monsters that follow her
## and the Spells and Traps around her. All of them are drawn here, in the game, like the
## pictures on her first cards: a sky made by a small shader, shapes of light over it, and
## Lumen herself (her living portrait) wherever the card is about her.
##   EchoArt.build(art_box, id, host) -> true when her portrait is on it (it needs a moment to draw)

const W := 328.0
const H := 300.0
const CYAN := Color("7fe8ff")
const GOLD := Color("ffd766")
const ROSE := Color("ff8ad0")
const NAVY := Color("081428")
const IDS := [99200006, 99200007, 99200014, 99200015, 99200016, 99200017, 99200018, 99200019, 99200020,
	99200021, 99200022, 99200023, 99200024, 99200025]

const SKY := """
shader_type canvas_item;
uniform int mode = 0;
uniform vec3 c0 : source_color = vec3(0.03, 0.08, 0.16);
uniform vec3 c1 : source_color = vec3(0.3, 1.0, 0.7);
uniform vec3 c2 : source_color = vec3(0.6, 0.4, 1.0);
uniform vec2 focus = vec2(0.5, 0.5);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return s;
}
float stars(vec2 uv, float cut) {
	vec2 g = uv * vec2(82.0, 75.0);
	vec2 c = floor(g);
	float h = hash(c);
	float d = length(fract(g) - 0.5 - (vec2(hash(c + 3.1), hash(c + 7.7)) - 0.5) * 0.6);
	return step(cut, h) * smoothstep(0.32, 0.0, d) * (0.5 + 0.5 * hash(c + 1.3));
}
void fragment() {
	vec2 uv = UV;
	vec3 col = c0;
	if (mode == 0) {
		// A night sky with an aurora: curtains bright at their lower edge, fading upward.
		col = mix(c0 * 0.55, c0 * 1.9, uv.y);
		col += vec3(stars(uv, 0.90)) * (1.0 - uv.y * 0.8);
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			float x = uv.x * 2.6 + fi * 1.9;
			float edge = 0.36 + fi * 0.13 + sin(x * 1.7 + noise(vec2(x, fi * 3.0)) * 3.0) * 0.07;
			float up = edge - uv.y;
			float a = up > 0.0 ? exp(-up * 5.5) : exp(up * 70.0);
			float ray = 0.45 + 0.55 * noise(vec2(uv.x * 46.0 + fi * 13.0, fi));
			col += mix(c1, c2, clamp(up * 2.6, 0.0, 1.0)) * a * ray * 0.62;
		}
	} else if (mode == 1) {
		// Nova: a burst in the four colors of the worlds.
		vec2 p = uv - focus;
		p.x *= 1.093;
		float r = length(p);
		float ang = atan(p.y, p.x);
		float rays = pow(abs(sin(ang * 9.0 + noise(vec2(ang * 2.0, 3.0)) * 2.5)), 2.5);
		vec3 hs[4] = vec3[4](vec3(0.35, 0.62, 1.0), vec3(1.0, 0.82, 0.3), vec3(0.72, 0.42, 1.0), vec3(0.92, 0.97, 1.0));
		vec3 hue = vec3(0.0);
		float wsum = 0.0;
		for (int i = 0; i < 4; i++) {
			float w = max(0.0, cos(ang - (float(i) * 1.5708 + 0.785)));
			w = w * w;
			hue += hs[i] * w;
			wsum += w;
		}
		hue /= max(0.001, wsum);
		col = c0 * (1.0 - r);
		col += hue * (rays * exp(-r * 2.4) * 1.5 + exp(-r * 4.2) * 0.9);
		col += vec3(1.0, 0.98, 0.92) * exp(-r * 9.0) * 1.2;
		col += vec3(stars(uv, 0.90)) * 0.8 * smoothstep(0.25, 0.6, r);
	} else if (mode == 2) {
		// A cloud of light among stars.
		float n = fbm(uv * 3.2 + vec2(1.7, 0.3));
		float m = fbm(uv * 6.0 - vec2(0.4, 2.1));
		col = mix(c0, c1, smoothstep(0.35, 0.8, n)) + c2 * smoothstep(0.55, 0.9, m) * 0.5;
		col *= 1.0 - 0.55 * length(uv - focus);
		col += vec3(stars(uv, 0.88)) * 0.9;
	} else if (mode == 3) {
		// Two colors drawn into one point.
		vec2 p = uv - focus;
		p.x *= 1.093;
		float r = length(p);
		float ang = atan(p.y, p.x);
		float s = sin(ang * 2.0 + log(r + 0.02) * 5.5);
		float arm = smoothstep(0.0, 0.9, abs(s));
		vec3 two = mix(c1, c2, smoothstep(-0.25, 0.25, s));
		col = c0 * (1.0 - r * 0.8) + two * arm * exp(-r * 2.6) * 1.25;
		col += vec3(1.0) * exp(-r * 13.0) * 1.3;
		col += vec3(stars(uv, 0.93)) * 0.6 * smoothstep(0.3, 0.6, r);
	} else {
		// Soft light from one spot.
		float r = length((uv - focus) * vec2(1.093, 1.0));
		col = mix(c1, c0, smoothstep(0.0, 0.85, r));
		col += c2 * exp(-r * 6.0) * 0.5;
	}
	COLOR = vec4(col, 1.0);
}
"""

static var _shader: Shader


static func has(id: int) -> bool:
	return IDS.has(id)


static func _sky(box: Control, mode: int, c0: Color, c1: Color, c2: Color, focus := Vector2(0.5, 0.5)) -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SKY
	var r := ColorRect.new()
	r.size = Vector2(W, H)
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("c0", Vector3(c0.r, c0.g, c0.b))
	m.set_shader_parameter("c1", Vector3(c1.r, c1.g, c1.b))
	m.set_shader_parameter("c2", Vector3(c2.r, c2.g, c2.b))
	m.set_shader_parameter("focus", focus)
	r.material = m
	box.add_child(r)


static func _canvas(box: Control, paint: Callable) -> Control:
	var c := Control.new()
	c.size = Vector2(W, H)
	box.add_child(c)
	c.draw.connect(func(): paint.call(c))
	return c


## Her living portrait, placed on the card.
static func _lumen(box: Control, host: Node, pos: Vector2, size: Vector2, tint := Color.WHITE, flip := false) -> TextureRect:
	var live := TextureRect.new()
	live.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	live.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	live.texture = LumenSpirit.portrait_form(host, 0)
	live.position = pos
	live.size = size
	live.modulate = tint
	live.flip_h = flip
	box.add_child(live)
	return live


## A painted figure (assets/originals/<card id>.png: cut out, on a clear background), `width` wide.
static func _painted(box: Control, id: int, pos: Vector2, width: float, tint := Color.WHITE) -> TextureRect:
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	var tex: Texture2D = load("res://assets/originals/%d.png" % id)
	pic.texture = tex
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pic.position = pos
	pic.size = Vector2(width, width * tex.get_height() / float(tex.get_width()))
	pic.modulate = tint
	box.add_child(pic)
	return pic


static func _glow(c: Control, at: Vector2, r: float, col: Color, steps := 12) -> void:
	for i in steps:
		var t := 1.0 - float(i) / float(steps)
		c.draw_circle(at, r * t, Color(col.r, col.g, col.b, col.a * 0.13))


static func _poly(c: Control, pts: Array, cols: Array) -> void:
	c.draw_polygon(PackedVector2Array(pts), PackedColorArray(cols))


static func _flat(c: Control, pts: Array, col: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(pts), col)


static func _line(c: Control, pts: Array, col: Color, width: float, closed := false) -> void:
	var p := PackedVector2Array(pts)
	if closed:
		p.append(pts[0])
	c.draw_polyline(p, col, width, true)


## A four-pointed star of light.
static func _spark(c: Control, at: Vector2, r: float, col: Color) -> void:
	_glow(c, at, r * 1.6, Color(col, 0.7), 8)
	_flat(c, [at + Vector2(0, -r), at + Vector2(r * 0.22, 0), at + Vector2(0, r), at + Vector2(-r * 0.22, 0)], col)
	_flat(c, [at + Vector2(-r, 0), at + Vector2(0, -r * 0.22), at + Vector2(r, 0), at + Vector2(0, r * 0.22)], col)


static func _diamond(c: Control, at: Vector2, w: float, h: float, top: Color, bottom: Color) -> void:
	_poly(c, [at + Vector2(0, -h), at + Vector2(w, 0), at + Vector2(0, h), at + Vector2(-w, 0)], [top, top.lerp(bottom, 0.5), bottom, top.lerp(bottom, 0.35)])


## A curve through three points (a soft thread), as a list of points.
static func _curve(a: Vector2, ctrl: Vector2, b: Vector2, n := 20) -> Array:
	var out: Array = []
	for i in n + 1:
		var t := float(i) / float(n)
		out.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return out


## The mark of this game, small: a ring with two roads crossing.
static func _crossroads(c: Control, at: Vector2, r: float, alpha := 1.0) -> void:
	c.draw_arc(at, r, 0, TAU, 40, Color(GOLD, alpha), maxf(1.5, r * 0.14), true)
	var k := r * 0.6
	c.draw_line(at + Vector2(-k, -k), at + Vector2(k, k), Color(CYAN, alpha), maxf(1.5, r * 0.16), true)
	c.draw_line(at + Vector2(k, -k), at + Vector2(-k, k), Color(CYAN, alpha), maxf(1.5, r * 0.16), true)
	c.draw_circle(at, r * 0.2, Color(GOLD, alpha))


static func build(box: Control, id: int, host: Node) -> bool:
	box.clip_contents = true
	match id:
		99200021: _wisp(box)
		99200022: _keeper(box)
		99200023: _twin(box, host)
		99200024: _messenger(box)
		99200025: _sentinel(box)
		99200006: _aurora(box)
		99200007: _nova(box)
		99200014: _rite(box, host)
		99200015: _bond(box, host)
		99200016: _hall(box)
		99200017: _merge(box)
		99200018: _memory(box)
		99200019: _return(box, host)
		99200020: _silence(box, host)
	return id in [99200023, 99200014, 99200015, 99200019, 99200020]


# ---------------------------------------------------------------- the monsters
# (The figures are painted pictures; the sky behind each and the light around it are drawn here.)

static func _wisp(box: Control) -> void:
	_sky(box, 4, Color("061427"), Color("1d6a96"), CYAN, Vector2(0.52, 0.5))
	_canvas(box, func(c: Control):
		var at := Vector2(176, 138)
		for k in 4:
			c.draw_arc(at, 70.0 + k * 30.0, 0, TAU, 72, Color(1, 1, 1, 0.22 - k * 0.05), 2.5, true)
		_glow(c, at, 120.0, Color(CYAN, 0.55), 12)
		var rng := RandomNumberGenerator.new()
		rng.seed = 2121
		for i in 26:
			var p := Vector2(rng.randf_range(8, 320), rng.randf_range(8, 292))
			c.draw_circle(p, rng.randf_range(0.8, 2.2), Color(0.85, 1, 1, rng.randf_range(0.3, 0.8))))
	# Its echoes behind it, each fainter and smaller, then the wisp itself.
	_painted(box, 99200021, Vector2(-66, 44), 180.0, Color(0.7, 0.95, 1.0, 0.22))
	_painted(box, 99200021, Vector2(-34, -6), 230.0, Color(0.8, 0.97, 1.0, 0.4))
	_painted(box, 99200021, Vector2(29, -56), 290.0)
	_canvas(box, func(c: Control):
		_spark(c, Vector2(276, 52), 9.0, Color.WHITE)
		_spark(c, Vector2(44, 44), 6.0, Color(CYAN, 0.9)))


static func _keeper(box: Control) -> void:
	_sky(box, 4, Color("05070f"), Color("4a3312"), GOLD, Vector2(0.26, 0.34))
	_canvas(box, func(c: Control):
		var lamp := Vector2(84, 100)
		# The hall behind: pillars the lantern picks out of the dark.
		for k in 4:
			var x := 30.0 + k * 92.0
			_poly(c, [Vector2(x, 0), Vector2(x + 20, 0), Vector2(x + 20, 300), Vector2(x, 300)],
					[Color(0.5, 0.36, 0.14, 0.34), Color(0.3, 0.22, 0.1, 0.0), Color(0.1, 0.06, 0.03, 0.0), Color(0.2, 0.12, 0.05, 0.3)])
		_glow(c, lamp, 150.0, Color(1.0, 0.8, 0.35, 0.55), 16)
		for k in 14:
			var a := TAU * k / 14.0 + 0.12
			c.draw_line(lamp + Vector2(cos(a), sin(a)) * 38.0, lamp + Vector2(cos(a), sin(a)) * (104.0 if k % 2 == 0 else 72.0), Color(1, 0.9, 0.6, 0.3), 2.0, true)
		# The floor, lit under the lantern.
		c.draw_set_transform(Vector2(150, 288), 0.0, Vector2(1.0, 0.16))
		_glow(c, Vector2.ZERO, 170.0, Color(1.0, 0.78, 0.35, 0.5), 10)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	_painted(box, 99200022, Vector2(29, -27), 316.0)
	_canvas(box, func(c: Control):
		_glow(c, Vector2(84, 100), 30.0, Color(1, 1, 0.9, 0.5), 8)
		_spark(c, Vector2(292, 40), 6.0, Color(1, 0.95, 0.7))
		_spark(c, Vector2(286, 168), 4.5, Color(1, 0.95, 0.7, 0.8)))


static func _twin(box: Control, host: Node) -> void:
	_sky(box, 2, Color("0a0f2e"), Color("2a78b8"), ROSE, Vector2(0.5, 0.5))
	_canvas(box, func(c: Control):
		for k in 5:
			c.draw_arc(Vector2(164, 150), 46.0 + k * 30.0, 0, TAU, 72, Color(1, 1, 1, 0.2 - k * 0.035), 2.5, true))
	_lumen(box, host, Vector2(-34, 14), Vector2(236, 290))
	_lumen(box, host, Vector2(126, 14), Vector2(236, 290), Color(1.0, 0.7, 0.92), true)
	_canvas(box, func(c: Control):
		# The line between the two: a mirror made of light.
		_poly(c, [Vector2(152, 0), Vector2(164, 0), Vector2(164, 300), Vector2(152, 300)], [Color(1, 1, 1, 0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		_poly(c, [Vector2(164, 0), Vector2(176, 0), Vector2(176, 300), Vector2(164, 300)], [Color(1, 1, 1, 0.5), Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.5)])
		c.draw_line(Vector2(164, 0), Vector2(164, 300), Color(1, 1, 1, 0.9), 1.5, true)
		_spark(c, Vector2(164, 150), 15.0, Color.WHITE)
		_spark(c, Vector2(164, 44), 7.0, Color(CYAN, 0.95))
		_spark(c, Vector2(164, 256), 7.0, Color(ROSE, 0.95)))


static func _messenger(box: Control) -> void:
	_sky(box, 4, Color("16245a"), Color("ff9f6a"), Color("fff0c0"), Vector2(0.3, 1.02))
	_canvas(box, func(c: Control):
		# Morning clouds.
		for cl in [[60.0, 236.0, 120.0, 0.34], [240.0, 258.0, 150.0, 0.3], [150.0, 284.0, 190.0, 0.4], [280.0, 60.0, 80.0, 0.1]]:
			c.draw_set_transform(Vector2(float(cl[0]), float(cl[1])), 0.0, Vector2(1.0, 0.24))
			_glow(c, Vector2.ZERO, float(cl[2]), Color(1.0, 0.9, 0.86, float(cl[3])), 8)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var rng := RandomNumberGenerator.new()
		rng.seed = 2424
		for i in 14:
			c.draw_circle(Vector2(rng.randf_range(8, 320), rng.randf_range(6, 130)), rng.randf_range(0.7, 1.7), Color(1, 1, 1, rng.randf_range(0.3, 0.7)))
		# Where it has been: lines of light behind it.
		for tr in [[96.0, 232.0, -10.0, 286.0, 0.55], [78.0, 206.0, -6.0, 232.0, 0.35], [116.0, 250.0, 34.0, 306.0, 0.32]]:
			c.draw_line(Vector2(float(tr[0]), float(tr[1])), Vector2(float(tr[2]), float(tr[3])), Color(1, 1, 1, float(tr[4])), 2.5, true)
		_glow(c, Vector2(170, 138), 130.0, Color(1, 1, 1, 0.4), 10))
	_painted(box, 99200024, Vector2(24, -52), 300.0)
	_canvas(box, func(c: Control):
		_spark(c, Vector2(286, 40), 8.0, Color.WHITE)
		_spark(c, Vector2(40, 110), 5.0, Color(1, 1, 1, 0.85)))


static func _sentinel(box: Control) -> void:
	_sky(box, 4, Color("040914"), Color("1a4a7a"), CYAN, Vector2(0.5, 0.36))
	_canvas(box, func(c: Control):
		# Light standing behind it.
		for k in 5:
			var x := 44.0 + k * 60.0
			_poly(c, [Vector2(x - 9, 0), Vector2(x + 9, 0), Vector2(x + 18, 300), Vector2(x - 18, 300)],
					[Color(CYAN, 0.0), Color(CYAN, 0.2), Color(CYAN, 0.0), Color(CYAN, 0.05)])
		_glow(c, Vector2(164, 120), 160.0, Color(CYAN, 0.5), 14))
	# Its echoes, standing guard a step behind on each side.
	_painted(box, 99200025, Vector2(-62, 14), 290.0, Color(0.6, 0.9, 1.0, 0.22))
	_painted(box, 99200025, Vector2(100, 14), 290.0, Color(0.6, 0.9, 1.0, 0.22))
	_painted(box, 99200025, Vector2(7, -12), 330.0)
	_canvas(box, func(c: Control):
		_spark(c, Vector2(288, 30), 9.0, Color.WHITE))


# ---------------------------------------------------------------- her two new forms

static func _aurora(box: Control) -> void:
	_sky(box, 0, Color("050d24"), Color("4dffb0"), Color("9a6bff"))
	_canvas(box, func(c: Control):
		_glow(c, Vector2(164, 120), 150.0, Color(0.7, 1.0, 0.9, 0.45), 12))
	_painted(box, 99200006, Vector2(-21, -45), 340.0)
	_canvas(box, func(c: Control):
		# The crown of three lights over her halo.
		_diamond(c, Vector2(164, 14), 7.0, 12.0, Color.WHITE, GOLD)
		_diamond(c, Vector2(128, 24), 5.0, 9.0, Color.WHITE, Color(0.4, 1.0, 0.75))
		_diamond(c, Vector2(200, 24), 5.0, 9.0, Color.WHITE, Color(0.65, 0.5, 1.0))
		_glow(c, Vector2(164, 14), 18.0, Color(1, 1, 0.9, 0.8), 8)
		_spark(c, Vector2(40, 60), 6.0, Color(0.6, 1.0, 0.85))
		_spark(c, Vector2(292, 96), 7.0, Color(0.8, 0.7, 1.0)))


static func _nova(box: Control) -> void:
	_sky(box, 1, Color("0a0618"), Color.WHITE, Color.WHITE, Vector2(0.5, 0.42))
	var four := [Color("5a9eff"), Color("ffd24d"), Color("b86bff"), Color("eef8ff")]
	_canvas(box, func(c: Control):
		var o := Vector2(164, 126)
		c.draw_arc(o, 118.0, 0, TAU, 72, Color(1, 1, 1, 0.55), 2.5, true)
		c.draw_arc(o, 130.0, 0, TAU, 72, Color(1, 0.95, 0.75, 0.3), 6.0, true)
		_glow(c, o, 130.0, Color(1, 0.97, 0.85, 0.6), 12))
	_painted(box, 99200007, Vector2(-9, -15), 350.0)
	_canvas(box, func(c: Control):
		# Four lights round her, one for each world she has crossed.
		var o := Vector2(164, 126)
		for k in 4:
			var a := k * PI * 0.5 + PI * 0.25
			var p := o + Vector2(cos(a) * 142.0, sin(a) * 112.0)
			_glow(c, p, 16.0, Color(four[k] as Color, 0.9), 8)
			_diamond(c, p, 6.0, 10.0, Color.WHITE, four[k]))


# ---------------------------------------------------------------- Spells and Traps

static func _rite(box: Control, host: Node) -> void:
	_sky(box, 4, Color("0b1238"), Color("ff9a5a"), Color("fff2c0"), Vector2(0.5, 0.76))
	_canvas(box, func(c: Control):
		var sun := Vector2(164, 222)
		for k in 16:
			var a := PI + PI * (k + 0.5) / 16.0
			var long := 230.0 if k % 2 == 0 else 150.0
			_poly(c, [sun + Vector2(cos(a - 0.035), sin(a - 0.035)) * 40.0, sun + Vector2(cos(a), sin(a)) * long, sun + Vector2(cos(a + 0.035), sin(a + 0.035)) * 40.0],
					[Color(1, 0.95, 0.75, 0.5), Color(1, 0.9, 0.6, 0.0), Color(1, 0.95, 0.75, 0.5)])
		_glow(c, sun, 110.0, Color(1, 0.9, 0.6, 0.8), 12)
		c.draw_circle(sun, 46.0, Color("fff6d8"))
		# The ground, and the circle drawn on it.
		_poly(c, [Vector2(0, 222), Vector2(328, 222), Vector2(328, 300), Vector2(0, 300)], [Color("2a1840"), Color("2a1840"), Color("07060f"), Color("07060f")])
		c.draw_line(Vector2(0, 222), Vector2(328, 222), Color(1, 0.92, 0.7, 0.9), 2.0, true)
		c.draw_set_transform(Vector2(164, 262), 0.0, Vector2(1.0, 0.25))
		_glow(c, Vector2.ZERO, 136.0, Color(1, 0.85, 0.5, 0.45), 8)
		c.draw_arc(Vector2.ZERO, 132.0, 0, TAU, 72, GOLD, 4.0, true)
		c.draw_arc(Vector2.ZERO, 106.0, 0, TAU, 72, Color(1, 1, 1, 0.7), 2.5, true)
		for k in 8:
			var a := TAU * k / 8.0
			c.draw_line(Vector2(cos(a), sin(a)) * 106.0, Vector2(cos(a + 0.9), sin(a + 0.9)) * 106.0, Color(GOLD, 0.6), 2.0, true)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	_lumen(box, host, Vector2(106, 86), Vector2(116, 150), Color(1.0, 0.98, 0.9))
	_canvas(box, func(c: Control):
		# Eight flames round the circle.
		for k in 8:
			var a := TAU * k / 8.0 + 0.39
			var p := Vector2(164, 262) + Vector2(cos(a) * 132.0, sin(a) * 33.0)
			var s := 0.8 + 0.35 * (sin(a) * 0.5 + 0.5)
			_glow(c, p + Vector2(0, -8) * s, 20.0 * s, Color(0.5, 0.9, 1.0, 0.9), 8)
			_poly(c, [p + Vector2(-6, 0) * s, p + Vector2(0, -24) * s, p + Vector2(6, 0) * s, p + Vector2(0, 5) * s], [CYAN, Color.WHITE, CYAN, Color("2a8fd8")])
		_spark(c, Vector2(164, 66), 9.0, Color.WHITE))


static func _bond(box: Control, host: Node) -> void:
	_sky(box, 2, Color("08102c"), Color("1f7f9a"), GOLD, Vector2(0.5, 0.52))
	var ends := [Vector2(164, 26), Vector2(38, 78), Vector2(290, 78), Vector2(46, 232), Vector2(282, 232)]
	var cols := [GOLD, ROSE, Color("8dffb0"), Color("b08aff"), CYAN]
	var heart := Vector2(164, 176)
	_canvas(box, func(c: Control):
		_glow(c, heart, 130.0, Color(1, 1, 1, 0.3), 10)
		for k in 5:
			var e: Vector2 = ends[k]
			var bend := (heart + e) * 0.5 + (e - heart).orthogonal().normalized() * (26.0 if k % 2 == 0 else -26.0)
			var pts := _curve(heart, bend, e, 24)
			_line(c, pts, Color(cols[k] as Color, 0.22), 9.0)
			_line(c, pts, Color(cols[k] as Color, 0.95), 3.0)
			_line(c, pts, Color(1, 1, 1, 0.8), 1.0))
	_lumen(box, host, Vector2(74, 44), Vector2(180, 226))
	_canvas(box, func(c: Control):
		for k in 5:
			_spark(c, ends[k], 13.0, (cols[k] as Color).lerp(Color.WHITE, 0.45))
			c.draw_arc(ends[k], 19.0, 0, TAU, 32, Color(cols[k] as Color, 0.8), 2.0, true)
		_glow(c, heart, 22.0, Color(1, 1, 1, 0.95), 8))


static func _hall(box: Control) -> void:
	_sky(box, 4, Color("02050c"), Color("0d2f4e"), CYAN, Vector2(0.5, 0.48))
	_canvas(box, func(c: Control):
		var v := Vector2(164, 146)
		var n := 9
		var ws: Array = []
		for k in n:
			ws.append(pow(0.74, k))
		# The floor: lines running to where the hall ends.
		for k in 13:
			var x := -160.0 + k * 54.0
			c.draw_line(v + Vector2(0, 6), Vector2(x, 300), Color(CYAN, 0.16), 1.5, true)
		# Walls between one arch and the next, darker each time.
		for k in n - 1:
			var w0 := 176.0 * float(ws[k])
			var w1 := 176.0 * float(ws[k + 1])
			var f0 := v.y + 158.0 * float(ws[k])
			var f1 := v.y + 158.0 * float(ws[k + 1])
			var t0 := v.y - 54.0 * float(ws[k])
			var t1 := v.y - 54.0 * float(ws[k + 1])
			for sx in [-1.0, 1.0]:
				_poly(c, [Vector2(v.x + sx * w0, f0), Vector2(v.x + sx * w0, t0), Vector2(v.x + sx * w1, t1), Vector2(v.x + sx * w1, f1)],
						[Color(0.03, 0.14, 0.24, 0.85), Color(0.05, 0.22, 0.34, 0.85), Color(0.02, 0.1, 0.18, 0.85), Color(0.01, 0.06, 0.12, 0.85)])
			_poly(c, [Vector2(v.x - w0, f0), Vector2(v.x + w0, f0), Vector2(v.x + w1, f1), Vector2(v.x - w1, f1)],
					[Color(0.04, 0.2, 0.3, 0.5), Color(0.04, 0.2, 0.3, 0.5), Color(0.1, 0.4, 0.5, 0.5), Color(0.1, 0.4, 0.5, 0.5)])
		_glow(c, v + Vector2(0, 10), 70.0, Color(0.85, 1, 1, 0.95), 14)
		# The arches: each one the echo of the one before it.
		for k in range(n - 1, -1, -1):
			var s := float(ws[k])
			var w := 176.0 * s
			var fl := v.y + 158.0 * s
			var tp := v.y - 54.0 * s
			var a := 0.95 - k * 0.085
			var col := CYAN.lerp(Color.WHITE, 0.25 + k * 0.08)
			var wd := 6.0 * s + 1.2
			for pass_n in 2:
				var cc := Color(col, a * (0.25 if pass_n == 0 else 1.0))
				var ww := wd * (3.0 if pass_n == 0 else 1.0)
				c.draw_line(Vector2(v.x - w, fl), Vector2(v.x - w, tp), cc, ww, true)
				c.draw_line(Vector2(v.x + w, fl), Vector2(v.x + w, tp), cc, ww, true)
				c.draw_arc(Vector2(v.x, tp), w, PI, TAU, 48, cc, ww, true)
			c.draw_line(Vector2(v.x - w, fl), Vector2(v.x + w, fl), Color(col, a * 0.5), wd * 0.6, true)
		var rng := RandomNumberGenerator.new()
		rng.seed = 1616
		for i in 18:
			c.draw_circle(Vector2(rng.randf_range(70, 258), rng.randf_range(60, 260)), rng.randf_range(0.8, 2.0), Color(0.9, 1, 1, rng.randf_range(0.3, 0.8)))
		_crossroads(c, v + Vector2(0, 8), 13.0))


static func _merge(box: Control) -> void:
	_sky(box, 3, Color("06081a"), CYAN, ROSE, Vector2(0.5, 0.5))
	_canvas(box, func(c: Control):
		var o := Vector2(164, 150)
		# Two lights on their way in, each with the road it has taken behind it.
		for k in 2:
			var col: Color = [CYAN, ROSE][k]
			var a0 := -2.4 + k * PI
			var trail: Array = []
			for i in 30:
				var t := float(i) / 29.0
				var ang := a0 - t * 2.6
				trail.append(o + Vector2(cos(ang), sin(ang) * 0.92) * (64.0 + 62.0 * t))
			for i in 29:
				c.draw_line(trail[i], trail[i + 1], Color(col, 0.9 * (1.0 - float(i) / 29.0)), 5.0 * (1.0 - float(i) / 34.0), true)
			var head: Vector2 = trail[0]
			_glow(c, head, 30.0, Color(col, 0.95), 10)
			c.draw_circle(head, 9.0, Color.WHITE)
		c.draw_arc(o, 34.0, 0, TAU, 48, Color(1, 1, 1, 0.75), 2.0, true)
		_spark(c, o, 30.0, Color.WHITE)
		_spark(c, Vector2(52, 44), 7.0, Color(CYAN, 0.9))
		_spark(c, Vector2(276, 256), 7.0, Color(ROSE, 0.9)))


static func _memory(box: Control) -> void:
	_sky(box, 2, Color("09092a"), Color("3a3aa0"), CYAN, Vector2(0.5, 0.5))
	_canvas(box, func(c: Control):
		var o := Vector2(164, 156)
		_glow(c, o, 120.0, Color(0.6, 0.8, 1.0, 0.35), 10)
		# Three cards, coming back.
		for card in [[-78.0, 14.0, -0.34, 0.5], [78.0, 14.0, 0.34, 0.5], [0.0, -6.0, 0.0, 1.0]]:
			var at := o + Vector2(float(card[0]), float(card[1]))
			var al := float(card[3])
			for echo in [2, 1, 0]:
				c.draw_set_transform(at + Vector2(0, -9.0 * echo), float(card[2]), Vector2.ONE * (1.0 + 0.07 * echo))
				var r := Rect2(-38, -54, 76, 108)
				if echo == 0:
					c.draw_rect(r, Color(0.08, 0.16, 0.32, 0.92 * al + 0.08))
					c.draw_rect(Rect2(-30, -44, 60, 50), Color(CYAN, 0.28 * al))
					c.draw_rect(Rect2(-30, 14, 60, 4), Color(1, 1, 1, 0.5 * al))
					c.draw_rect(Rect2(-30, 24, 44, 4), Color(1, 1, 1, 0.35 * al))
					c.draw_rect(Rect2(-30, 34, 52, 4), Color(1, 1, 1, 0.35 * al))
					c.draw_rect(r, Color(GOLD, 0.95 * al + 0.05), false, 2.5)
				else:
					c.draw_rect(r, Color(CYAN, 0.3 * al / echo), false, 2.0)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_crossroads(c, o + Vector2(0, -25), 15.0)
		# Time turned back: an arrow going round the wrong way.
		c.draw_arc(o + Vector2(0, -4), 128.0, PI * 1.12, PI * 1.9, 48, Color(GOLD, 0.9), 3.5, true)
		var tip := o + Vector2(0, -4) + Vector2(cos(PI * 1.12), sin(PI * 1.12)) * 128.0
		_flat(c, [tip + Vector2(-13, -2), tip + Vector2(5, -15), tip + Vector2(9, 9)], GOLD)
		var rng := RandomNumberGenerator.new()
		rng.seed = 1818
		for i in 16:
			var p := Vector2(rng.randf_range(20, 308), rng.randf_range(200, 296))
			c.draw_line(p, p + Vector2(0, -rng.randf_range(8, 26)), Color(CYAN, rng.randf_range(0.2, 0.6)), 1.5, true))


static func _return(box: Control, host: Node) -> void:
	_sky(box, 4, Color("10041a"), Color("6a2478"), Color("ff9ad5"), Vector2(0.5, 0.62))
	_canvas(box, func(c: Control):
		# A pillar of light, and the pieces of what was broken, rising with her.
		_poly(c, [Vector2(96, 0), Vector2(164, 0), Vector2(164, 300), Vector2(96, 300)], [Color(1, 1, 1, 0), Color(1, 0.9, 0.97, 0.5), Color(1, 0.9, 0.97, 0.62), Color(1, 1, 1, 0)])
		_poly(c, [Vector2(164, 0), Vector2(232, 0), Vector2(232, 300), Vector2(164, 300)], [Color(1, 0.9, 0.97, 0.5), Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 0.9, 0.97, 0.62)])
		var rng := RandomNumberGenerator.new()
		rng.seed = 1919
		for i in 15:
			var side := -1.0 if i % 2 == 0 else 1.0
			var p := Vector2(164 + side * rng.randf_range(84, 150), rng.randf_range(36, 280))
			var r := rng.randf_range(8, 19)
			var a := rng.randf_range(0, TAU)
			var tri := [p + Vector2(cos(a), sin(a)) * r, p + Vector2(cos(a + 2.2), sin(a + 2.2)) * r * 0.8, p + Vector2(cos(a + 4.1), sin(a + 4.1)) * r * 0.9]
			_poly(c, tri, [Color(1.0, 0.75, 0.92, 0.9), Color(0.55, 0.2, 0.6, 0.85), Color(0.3, 0.08, 0.36, 0.85)])
			_line(c, tri, Color(1, 0.9, 0.97, 0.8), 1.2, true)
			c.draw_line(p + Vector2(0, r), p + Vector2(0, r + rng.randf_range(14, 34)), Color(1, 0.8, 0.95, 0.35), 1.5, true)
		c.draw_set_transform(Vector2(164, 276), 0.0, Vector2(1.0, 0.22))
		c.draw_arc(Vector2.ZERO, 96.0, 0, TAU, 56, Color(1, 0.85, 0.96, 0.9), 3.0, true)
		c.draw_arc(Vector2.ZERO, 70.0, 0, TAU, 56, Color(1, 1, 1, 0.5), 2.0, true)
		_glow(c, Vector2.ZERO, 100.0, Color(1, 0.7, 0.9, 0.5), 8)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	_lumen(box, host, Vector2(62, 22), Vector2(204, 256))
	_canvas(box, func(c: Control):
		# Upward, three times.
		for k in 3:
			var y := 288.0 - k * 17.0
			var w := 46.0 - k * 9.0
			_line(c, [Vector2(164 - w, y), Vector2(164, y - 13), Vector2(164 + w, y)], Color(1, 0.92, 0.98, 0.95 - k * 0.22), 4.0 - k * 0.8)
		_spark(c, Vector2(164, 18), 11.0, Color.WHITE))


static func _silence(box: Control, host: Node) -> void:
	_sky(box, 4, Color("12051a"), Color("401448"), ROSE, Vector2(0.22, 0.5))
	_canvas(box, func(c: Control):
		var src := Vector2(346, 150)
		# What the other side says: waves, loud where they start.
		for k in 9:
			var r := 40.0 + k * 21.0
			c.draw_arc(src, r, PI * 0.7, PI * 1.3, 40, Color(1.0, 0.42, 0.55, 0.95 - k * 0.06), 5.0 - k * 0.2, true)
		_glow(c, Vector2(318, 150), 60.0, Color(1.0, 0.35, 0.5, 0.6), 8))
	_lumen(box, host, Vector2(-14, 44), Vector2(176, 222))
	_canvas(box, func(c: Control):
		# The wall they stop at: one clean line of light.
		var a := Vector2(176, -6)
		var b := Vector2(136, 306)
		var nrm := (b - a).normalized().orthogonal()
		_poly(c, [a - nrm * 26.0, a, b, b - nrm * 26.0], [Color(1, 1, 1, 0), Color(0.85, 1, 1, 0.55), Color(0.85, 1, 1, 0.55), Color(1, 1, 1, 0)])
		_poly(c, [a, a + nrm * 26.0, b + nrm * 26.0, b], [Color(0.85, 1, 1, 0.55), Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(0.85, 1, 1, 0.55)])
		c.draw_line(a, b, Color.WHITE, 3.0, true)
		# Where each wave breaks on it.
		for k in 5:
			var p := a.lerp(b, 0.2 + k * 0.15)
			_spark(c, p, 8.0 if k % 2 == 0 else 5.5, Color(1, 0.9, 0.95))
			for j in 3:
				var q := p + Vector2(14.0 + j * 9.0, (j - 1) * 7.0)
				c.draw_circle(q, 2.2 - j * 0.5, Color(1.0, 0.6, 0.7, 0.8 - j * 0.2)))
