class_name MonsterHolo
extends MeshInstance3D
## The monster itself, standing over its card as a hologram for as long as it is face-up on the
## field. It floats and breathes, leans into an attack when its card lifts, flashes when hit and
## breaks apart into pixels when it leaves. It follows its card, so every card animation moves it.

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
	// Soft edges: the picture melts into the air instead of ending in a hard rectangle.
	float box = smoothstep(0.5, 0.36, max(abs(c.x), abs(c.y)));
	float oval = 1.0 - smoothstep(0.34, 0.56, length(c * vec2(1.0, 0.92)));
	float mask = box * mix(1.0, oval, 0.75);
	float foot = smoothstep(1.0, 0.82, uv.y);
	float scan = 0.9 + 0.1 * sin(uv.y * 160.0 - TIME * 5.0);
	float flick = 0.96 + 0.04 * sin(TIME * 23.0 + seed);
	vec3 col = t.rgb * scan * flick * (1.12 - dim * 0.38) + tint * (0.08 + power * 0.25);
	col = mix(col, mix(col, vec3(0.45, 0.6, 0.9), 0.45), dim);
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
	ALBEDO = col;
	ALPHA = mask * foot * rise * alive * (0.94 - dim * 0.22);
}
"""

static var _sh: Shader

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


func setup(for_inst, on_card: Node3D, color: Color, delay := 0.0) -> void:
	inst = for_inst
	card = on_card
	_delay = delay
	if _sh == null:
		_sh = Shader.new()
		_sh.code = CODE
	var art := Cards.get_art(inst.id)
	var lvl := float(inst.data.get("level", 4))
	var h := 1.02 + clampf(lvl - 4.0, 0.0, 5.0) * 0.075
	var w := h * float(art.get_width()) / maxf(1.0, float(art.get_height()))
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	mesh = q
	_mat = ShaderMaterial.new()
	_mat.shader = _sh
	_mat.set_shader_parameter("art", art)
	_mat.set_shader_parameter("tint", color)
	_mat.set_shader_parameter("size", Vector2(w, h))
	_mat.set_shader_parameter("seed", randf() * 20.0)
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 4.0
	# The pool of light it stands in.
	_ring = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.95, 0.95)
	_ring.mesh = pm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 0.75))
	gr.set_color(1, Color(1, 1, 1, 0.0))
	g.gradient = gr
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(0.5, 0.0)
	g.width = 64
	g.height = 64
	rm.albedo_texture = g
	rm.albedo_color = Color(color, 0.0)
	_ring.material_override = rm
	_ring.position.y = 0.03
	add_child(_ring)
	if is_instance_valid(card):
		_rest_y = card.global_position.y
		global_position = card.global_position


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
	tw.tween_method(func(v: float): _mat.set_shader_parameter("shatter", v), 0.0, 1.0, Settings.t(0.45))
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
	(_ring.material_override as StandardMaterial3D).albedo_color.a = 0.55 * _appear * (1.0 - _dim * 0.5)
