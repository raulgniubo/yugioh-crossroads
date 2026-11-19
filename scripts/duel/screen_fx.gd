class_name ScreenFx
extends RefCounted
## Things that happen to the whole picture in a duel (0.57.0): a flash, cinema bars, lines of
## speed rushing at a point, and the picture breaking like glass for the last hit. Each one is a
## full-screen piece on top of the duel that lets clicks through and frees itself.
## `host` is the duel's HUD (any Control that fills the screen).

const SHATTER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform vec2 center = vec2(0.5);
uniform float t = 0.0;
uniform float aspect = 1.777;
vec2 hash2(vec2 p) { p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))); return fract(sin(p) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 q = (uv - center) * vec2(aspect, 1.0);
	float scale = 6.5;
	vec2 g = floor(q * scale);
	vec2 f = fract(q * scale);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id = vec2(0.0);
	vec2 cc = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 h = hash2(g + o);
			vec2 r = o + h - f;
			float d = dot(r, r);
			if (d < d1) { d2 = d1; d1 = d; id = g + o; cc = (g + o + h) / scale; }
			else if (d < d2) { d2 = d; }
		}
	}
	float edge = sqrt(d2) - sqrt(d1);
	float dist = length(cc);
	// The break runs outward from the hit: the pieces near it go first.
	float local = clamp((t * 1.9 - dist * 0.85) / 0.6, 0.0, 1.0);
	vec2 rnd = hash2(id + 3.7) - 0.5;
	vec2 away = normalize(cc + vec2(0.0001));
	vec2 off = (away * 0.07 + rnd * 0.04) * local;
	off.y += 0.3 * local * local * (0.6 + rnd.x);
	vec3 col = texture(screen, uv - off / vec2(aspect, 1.0)).rgb;
	float started = step(0.001, local);
	float crack = smoothstep(0.07, 0.0, edge) * started;
	col = mix(col, vec3(1.0), crack * (1.0 - local) * 0.85);
	col += vec3(0.16, 0.2, 0.28) * started * (1.0 - local) * (0.5 + rnd.y);
	float piece = smoothstep(local * 0.3, local * 0.3 + 0.03, edge);
	float a = started * piece * (1.0 - local * local);
	COLOR = vec4(col, a);
}
"""

const LINES := """
shader_type canvas_item;
uniform vec2 center = vec2(0.5);
uniform vec4 color : source_color = vec4(1.0);
uniform float alpha = 1.0;
uniform float aspect = 1.777;
float hash(float n) { return fract(sin(n * 91.3458) * 47453.5453); }
void fragment() {
	vec2 q = (UV - center) * vec2(aspect, 1.0);
	float r = length(q);
	float a = atan(q.y, q.x) / 6.2831853 + 0.5;
	float n = 90.0;
	float id = floor(a * n);
	float f = abs(fract(a * n) - 0.5);
	float t = fract(TIME * (1.6 + hash(id) * 1.4) + hash(id + 5.0));
	float inner = 0.28 + 0.3 * hash(id + 2.0) + t * 0.25;
	float v = smoothstep(0.5 * (0.15 + 0.5 * hash(id + 9.0)), 0.0, f) * smoothstep(inner, inner + 0.25, r) * step(0.45, hash(id + 1.0));
	COLOR = vec4(color.rgb, v * alpha * color.a);
}
"""


static func _full(host: Control, z := 80) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = z
	host.add_child(r)
	return r


## The picture goes white (or any color) for a blink.
static func flash(host: Control, color := Color.WHITE, dur := 0.35, peak := 0.85) -> void:
	var r := _full(host, 90)
	r.color = Color(color, peak)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(r.queue_free)


## Cinema bars slide in at the top and bottom for `hold` seconds.
static func letterbox(host: Control, hold := 2.2, size := 0.085) -> void:
	var vs := host.get_viewport_rect().size
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 1)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.z_index = 70
		bar.size = Vector2(vs.x, vs.y * size)
		bar.position = Vector2(0, -bar.size.y if top else vs.y)
		host.add_child(bar)
		var shown := 0.0 if top else vs.y - bar.size.y
		var hidden := bar.position.y
		var tw := bar.create_tween()
		tw.tween_property(bar, "position:y", shown, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_interval(hold)
		tw.tween_property(bar, "position:y", hidden, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(bar.queue_free)


## Lines of speed rushing toward a point of the screen (in pixels) for `dur` seconds.
static func speed_lines(host: Control, at: Vector2, color := Color.WHITE, dur := 0.8) -> void:
	var vs := host.get_viewport_rect().size
	var r := _full(host, 60)
	var m := ShaderMaterial.new()
	m.shader = DuelFx._shader("screen_lines", LINES)
	m.set_shader_parameter("center", at / vs)
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("alpha", 0.0)
	m.set_shader_parameter("aspect", vs.x / vs.y)
	r.material = m
	var tw := r.create_tween()
	tw.tween_property(m, "shader_parameter/alpha", 0.75, 0.1)
	tw.tween_interval(maxf(0.0, dur - 0.35))
	tw.tween_property(m, "shader_parameter/alpha", 0.0, 0.25)
	tw.tween_callback(r.queue_free)


## The picture breaks like glass from a point (in pixels): the pieces slide apart, fall and fade.
static func shatter(host: Control, at: Vector2, dur := 1.15) -> void:
	var vs := host.get_viewport_rect().size
	var r := _full(host, 85)
	var m := ShaderMaterial.new()
	m.shader = DuelFx._shader("screen_shatter", SHATTER)
	m.set_shader_parameter("center", at / vs)
	m.set_shader_parameter("t", 0.0)
	m.set_shader_parameter("aspect", vs.x / vs.y)
	r.material = m
	var tw := r.create_tween()
	tw.tween_property(m, "shader_parameter/t", 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(r.queue_free)
