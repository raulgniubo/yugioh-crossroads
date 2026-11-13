class_name SpeedLines
extends ColorRect
## Streaks racing outward at the edges of the screen: the faster you go, the more of them.
## Set `amount` from 0 (none) to 1 (flat out); `kick()` adds a burst that fades.

const CODE := """
shader_type canvas_item;
uniform float amount = 0.0;
uniform vec3 tint : source_color = vec3(0.75, 0.9, 1.0);
float hash(float p) { return fract(sin(p * 127.1) * 43758.5453); }
void fragment() {
	vec2 p = UV - vec2(0.5, 0.52);
	p.x *= 16.0 / 9.0;
	float ang = atan(p.y, p.x);
	float r = length(p);
	float seg = floor(ang * 60.0);
	float w = hash(seg);
	// Each streak runs outward on its own clock.
	float run = fract(r * (1.2 + w * 1.5) - TIME * (1.6 + w * 2.4) - w * 7.0);
	float streak = smoothstep(0.0, 0.12, run) * smoothstep(0.55, 0.12, run);
	float thin = smoothstep(0.5, 0.0, abs(fract(ang * 60.0) - 0.5) * (2.0 + w * 3.0));
	float edge = smoothstep(0.52 - amount * 0.22, 1.0, r);
	float on = step(1.0 - amount * 0.75, w);
	COLOR = vec4(tint, streak * thin * edge * on * (0.25 + amount * 0.5));
}
"""

static var _sh: Shader
var amount := 0.0
var _kick := 0.0
var _mat: ShaderMaterial


func _init(tint := Color(0.75, 0.9, 1.0)) -> void:
	if _sh == null:
		_sh = Shader.new()
		_sh.code = CODE
	_mat = ShaderMaterial.new()
	_mat.shader = _sh
	_mat.set_shader_parameter("tint", tint)
	material = _mat
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func kick(strength := 0.6) -> void:
	_kick = maxf(_kick, strength)


func _process(delta: float) -> void:
	_kick = maxf(0.0, _kick - delta * 0.9)
	_mat.set_shader_parameter("amount", clampf(amount + _kick, 0.0, 1.0))
