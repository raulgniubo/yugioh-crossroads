class_name MenuBackdrop
extends ColorRect
## The backdrop behind the big menus: deep blue glass with slow light bands, a faint hex grid
## and a vignette. `alpha` below 1 lets the world show through when a menu opens in town.

const CODE := """
shader_type canvas_item;
uniform float alpha = 1.0;
uniform vec3 tint : source_color = vec3(0.18, 0.89, 0.9);
float hex(vec2 p) {
	p.x *= 0.57735 * 2.0;
	p.y += mod(floor(p.x), 2.0) * 0.5;
	p = abs(fract(p) - 0.5);
	return abs(max(p.x * 1.5 + p.y, p.y * 2.0) - 1.0);
}
void fragment() {
	vec2 uv = UV;
	vec3 top = vec3(0.035, 0.06, 0.12);
	vec3 bot = vec3(0.012, 0.018, 0.04);
	vec3 col = mix(top, bot, uv.y);
	// Two slow bands of light drifting across.
	float d = uv.x * 0.8 + uv.y * 0.5;
	col += tint * 0.05 * smoothstep(0.25, 0.0, abs(fract(d - TIME * 0.02) - 0.5) - 0.1);
	col += vec3(0.4, 0.3, 0.9) * 0.035 * smoothstep(0.3, 0.0, abs(fract(d * 0.7 + TIME * 0.013 + 0.4) - 0.5) - 0.05);
	// Hex grid, strongest in the corners.
	float h = smoothstep(0.06, 0.0, hex(uv * vec2(32.0, 18.0)));
	float corner = smoothstep(0.2, 0.9, length(uv - 0.5) * 1.3);
	col += tint * h * 0.05 * corner;
	// Glow rising from the bottom edge.
	col += tint * 0.06 * smoothstep(0.75, 1.0, uv.y);
	col *= 1.0 - 0.45 * smoothstep(0.45, 1.0, length(uv - 0.5) * 1.25);
	COLOR = vec4(col, alpha);
}
"""

static var _sh: Shader


func _init(a := 0.98) -> void:
	if _sh == null:
		_sh = Shader.new()
		_sh.code = CODE
	var m := ShaderMaterial.new()
	m.shader = _sh
	m.set_shader_parameter("alpha", a)
	m.set_shader_parameter("tint", UITheme.ACCENT)
	material = m
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
