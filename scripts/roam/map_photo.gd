class_name MapPhoto
extends RefCounted
## The map is a picture of the world itself, taken from straight above once when you arrive.
## Two shots in the same frame (the colors with no lighting, so it reads the same at noon and
## at midnight, and the heights), then one pass that paints soft shadows and wall edges from
## the heights. Both maps draw the result: the big one whole, the small one around you.
##
## It is taken on the first frame, while the screen is still dark from the scene change: for
## that one frame the far-away cut-offs are switched off and people and floating labels hidden,
## so the picture has every roof detail and nobody standing in it.

const CAM_Y := 330.0
const H_MAX := 100.0       # metres the height shot can tell apart (taller reads as this)
const H_BASE := 4.0        # metres below zero it still sees (the sea, a canal)
const ASPECT := 1040.0 / 860.0    # the shape of the big map's frame

const HEIGHT_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, fog_disabled, shadows_disabled;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform float cam_y = 330.0;
uniform float h_max = 100.0;
uniform float h_base = 4.0;
void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}
void fragment() {
	float d = texture(depth_tex, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
#endif
	vec4 v = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	v.xyz /= v.w;
	float h = clamp((cam_y + v.z + h_base) / h_max, 0.0, 1.0);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// This renderer writes the number as it is: keep the low end fine with a square root.
	ALBEDO = vec3(sqrt(h));
#else
	ALBEDO = vec3(h);
#endif
}
"""

const BAKE_SHADER := """
shader_type canvas_item;
uniform sampler2D photo : filter_linear, repeat_disable;
uniform sampler2D height : filter_linear, repeat_disable;
uniform vec2 metres = vec2(200.0, 170.0);
uniform float h_max = 100.0;
uniform float h_base = 4.0;
uniform float lift = 1.0;
uniform bool plain = false;
uniform vec2 keep_mid = vec2(0.5);     // the part with places in it, in picture space
uniform vec2 keep_half = vec2(0.5);
uniform vec3 fade_to = vec3(0.035, 0.05, 0.08);
float lin(float c) {
	if (plain) {
		return c * c;
	}
	return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}
float H(vec2 uv) {
	return lin(texture(height, uv).r) * h_max - h_base;
}
void fragment() {
	vec3 c = texture(photo, UV).rgb;
	float h = H(UV);
	// The sun sits up and to the left: whatever stands between it and this spot shades it.
	vec2 dir = normalize(vec2(-0.78, -0.62));
	float sh = 0.0;
	for (int i = 1; i <= 36; i++) {
		float d = float(i) * 0.7;
		float h2 = H(UV + dir * d / metres);
		sh = max(sh, smoothstep(0.15, 1.3, h2 - d * 1.05 - h) * (1.0 - float(i) / 46.0));
	}
	// Darker at the foot of every wall, so buildings stand off the ground.
	float ao = 0.0;
	for (int k = 0; k < 8; k++) {
		float a = float(k) * 0.7854;
		ao += clamp((H(UV + vec2(cos(a), sin(a)) * 1.3 / metres) - h) / 5.0, 0.0, 1.0);
	}
	ao /= 8.0;
	// A thin light edge on the side of a roof that faces the sun.
	float rim = clamp((h - H(UV + dir * 0.9 / metres)) / 6.0, 0.0, 1.0);
	c *= 1.0 - 0.36 * sh;
	c *= 1.0 - 0.42 * ao;
	c += vec3(0.06, 0.055, 0.04) * rim;
	c *= 1.0 + 0.10 * smoothstep(5.0, 45.0, h);
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, 1.16);
	c = pow(max(c, vec3(0.0)), vec3(1.0 / lift));
	// Past the last place the picture sinks into the frame, so the map floats in its panel.
	vec2 q = (abs(UV - keep_mid) - keep_half) * metres;
	float out_m = length(max(q, vec2(0.0)));
	c = mix(c, fade_to, 0.82 * smoothstep(2.0, 30.0, out_m));
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""

static var key := ""                     # which world the picture is of
static var tex: ImageTexture
static var mid := Vector2.ZERO           # the world spot in the middle of the picture
static var half := Vector2(100, 83)      # metres from the middle to the right and bottom edge
static var content := Rect2(-60, -60, 120, 120)   # the part with places in it (the rest is margin)
static var _busy := false


static func ready_for(district: String) -> bool:
	return tex != null and key == district


## Where a world spot (x, z) falls on the picture, 0..1.
static func uv(world: Vector2) -> Vector2:
	return (world - mid) / (half * 2.0) + Vector2(0.5, 0.5)


## What the picture has to cover: every landmark, the whole island, and a margin.
static func frame_for(d: Dictionary) -> Rect2:
	var m: Dictionary = d.get("map", {})
	var r := Rect2(-40, -40, 80, 80)
	if m.has("island"):
		var rad := float(m["island"]) + 6.0
		r = Rect2(-rad, -rad, rad * 2.0, rad * 2.0)
	for lm in m.get("landmarks", RoamMap.LANDMARKS):
		var p: Vector2 = lm["pos"]
		var s: Vector2 = lm["size"]
		r = r.merge(Rect2(p - s / 2.0, s))
	r = r.grow(9.0)
	return _fit(r)


## What has places in it (the frame without the margin that makes it fit the map's shape).
static func content_for(d: Dictionary) -> Rect2:
	var fr := frame_for(d)
	var m: Dictionary = d.get("map", {})
	var r := Rect2(-40, -40, 80, 80)
	if m.has("island"):
		var rad := float(m["island"]) + 6.0
		r = Rect2(-rad, -rad, rad * 2.0, rad * 2.0)
	for lm in m.get("landmarks", RoamMap.LANDMARKS):
		var p: Vector2 = lm["pos"]
		var s: Vector2 = lm["size"]
		r = r.merge(Rect2(p - s / 2.0, s))
	return r.grow(9.0).intersection(fr)


static func _fit(r: Rect2) -> Rect2:
	var c := r.get_center()
	var hy := maxf(r.size.y / 2.0, r.size.x / 2.0 / ASPECT)
	return Rect2(c - Vector2(hy * ASPECT, hy), Vector2(hy * ASPECT, hy) * 2.0)


## Take the picture for this world unless there is one already. Runs on its own (do not await).
static func take(scene: Node, district: String, d: Dictionary) -> void:
	if ready_for(district) or _busy or DisplayServer.get_name() == "headless":
		return
	_busy = true
	var fr := frame_for(d)
	var px_h := 1536
	var px := Vector2i(int(round(px_h * ASPECT / 4.0)) * 4, px_h)
	var sea: bool = str(d.get("builder", "")) == "academy"
	# A dark sheet over the screen for the frame the world is shown stripped.
	var curtain := CanvasLayer.new()
	curtain.layer = 120
	var black := ColorRect.new()
	black.color = Color(0.01, 0.02, 0.04)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.add_child(black)
	scene.add_child(curtain)
	var ranges: Array = []
	var hidden: Array = []
	_strip(scene, ranges, hidden)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.2, 0.3) if sea else Color(0.06, 0.07, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var shots: Array = []
	for i in 2:
		var vp := SubViewport.new()
		vp.size = px
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		vp.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		vp.msaa_3d = Viewport.MSAA_4X if i == 0 else Viewport.MSAA_DISABLED
		vp.positional_shadow_atlas_size = 0
		vp.audio_listener_enable_3d = false
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = fr.size.y
		cam.near = 1.0
		cam.far = CAM_Y + 40.0
		cam.environment = env
		cam.position = Vector3(fr.get_center().x, CAM_Y, fr.get_center().y)
		cam.rotation_degrees = Vector3(-90, 0, 0)
		cam.cull_mask = 0xFFFFF if i == 1 else (0xFFFFF & ~(1 << 19))
		vp.add_child(cam)
		if i == 1:
			# The height shot: one sheet in front of the lens that writes how far down the ground is.
			var quad := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(2, 2)
			quad.mesh = qm
			var sm := ShaderMaterial.new()
			var sh := Shader.new()
			sh.code = HEIGHT_SHADER
			sm.shader = sh
			sm.set_shader_parameter("cam_y", CAM_Y)
			sm.set_shader_parameter("h_max", H_MAX)
			sm.set_shader_parameter("h_base", H_BASE)
			sm.render_priority = 127
			quad.material_override = sm
			quad.layers = 1 << 19
			quad.extra_cull_margin = 16000.0
			quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			quad.position = Vector3(0, 0, -10)
			cam.add_child(quad)
		scene.add_child(vp)
		shots.append(vp)
	await RenderingServer.frame_post_draw
	if not is_instance_valid(scene):
		_busy = false
		return
	_restore(ranges, hidden)
	# Paint shadows and wall edges into the picture.
	var bake := SubViewport.new()
	bake.size = px
	bake.disable_3d = true
	bake.render_target_update_mode = SubViewport.UPDATE_ONCE
	var rect := ColorRect.new()
	rect.size = Vector2(px)
	var bm := ShaderMaterial.new()
	var bs := Shader.new()
	bs.code = BAKE_SHADER
	bm.shader = bs
	bm.set_shader_parameter("photo", (shots[0] as SubViewport).get_texture())
	bm.set_shader_parameter("height", (shots[1] as SubViewport).get_texture())
	bm.set_shader_parameter("metres", fr.size)
	bm.set_shader_parameter("h_max", H_MAX)
	bm.set_shader_parameter("h_base", H_BASE)
	bm.set_shader_parameter("plain", RenderingServer.get_current_rendering_method() == "gl_compatibility")
	var keep := content_for(d)
	bm.set_shader_parameter("keep_mid", (keep.get_center() - fr.position) / fr.size)
	bm.set_shader_parameter("keep_half", keep.size / 2.0 / fr.size)
	bm.set_shader_parameter("lift", float(d.get("map_lift", 1.25)))
	rect.material = bm
	bake.add_child(rect)
	scene.add_child(bake)
	await RenderingServer.frame_post_draw
	if not is_instance_valid(scene):
		_busy = false
		return
	var img: Image = bake.get_texture().get_image()
	if "--map-shot" in OS.get_cmdline_user_args():
		(shots[1] as SubViewport).get_texture().get_image().save_png("/tmp/map_%s_h.png" % district)
	for vp in shots:
		(vp as Node).queue_free()
	bake.queue_free()
	curtain.queue_free()
	_busy = false
	if img == null or img.is_empty():
		return
	img.convert(Image.FORMAT_RGB8)
	img.generate_mipmaps()
	tex = ImageTexture.create_from_image(img)
	key = district
	mid = fr.get_center()
	half = fr.size / 2.0
	content = content_for(d)
	for a in OS.get_cmdline_user_args():
		if a == "--map-shot":
			img.save_png("/tmp/map_%s.png" % district)
			print("MAP ", district, " ", px, " frame ", fr)


static func _strip(n: Node, ranges: Array, hidden: Array) -> void:
	if n is CanvasItem or n is CanvasLayer:
		return
	if n is RoamFigure or n is Label3D or n is SpriteBase3D or n is GPUParticles3D or n is CPUParticles3D or n is LumenSpirit or n.has_meta("moves"):
		if not (n is Node3D):
			return
		if (n as Node3D).visible:
			(n as Node3D).visible = false
			hidden.append(n)
		return
	if n is GeometryInstance3D and (n as GeometryInstance3D).visibility_range_end > 0.0:
		ranges.append([n, (n as GeometryInstance3D).visibility_range_end])
		(n as GeometryInstance3D).visibility_range_end = 0.0
	for c in n.get_children():
		_strip(c, ranges, hidden)


static func _restore(ranges: Array, hidden: Array) -> void:
	for r in ranges:
		if is_instance_valid(r[0]):
			(r[0] as GeometryInstance3D).visibility_range_end = float(r[1])
	for h in hidden:
		if is_instance_valid(h):
			(h as Node3D).visible = true
