class_name SpeedBlur
extends ColorRect
## Motion blur for the highway: the picture is smeared outward from the vanishing point, more
## toward the edges and more the faster you go. Add it under the HUD so only the 3D view blurs.

const CODE := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float amount = 0.0;
uniform vec2 center = vec2(0.5, 0.42);
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - center;
	float r = length(dir * vec2(1.0, 0.8));
	// Nothing near the middle (your runner and the road ahead stay sharp).
	float k = amount * smoothstep(0.16, 0.7, r) * 0.085;
	vec3 col = vec3(0.0);
	float w = 0.0;
	for (int i = 0; i < 9; i++) {
		float t = float(i) / 8.0;
		float wi = 1.0 - t * 0.6;
		col += texture(screen, uv - dir * k * t).rgb * wi;
		w += wi;
	}
	col /= w;
	// A touch of vignette that deepens with speed pulls the eye down the road.
	col *= 1.0 - amount * 0.22 * smoothstep(0.35, 0.95, r);
	COLOR = vec4(col, 1.0);
}
"""

static var _sh: Shader
var amount := 0.0
var _mat: ShaderMaterial


func _init() -> void:
	if _sh == null:
		_sh = Shader.new()
		_sh.code = CODE
	_mat = ShaderMaterial.new()
	_mat.shader = _sh
	material = _mat
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	_mat.set_shader_parameter("amount", clampf(amount, 0.0, 1.0))
	visible = amount > 0.02
