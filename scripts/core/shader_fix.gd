class_name ShaderFix
extends RefCounted
## One picture on both renderers.
##
## The game's own shaders (the sky, the streets, grass, windows, duel fields, the toon look)
## name their colors as plain numbers, picked by eye. The light renderer shows those numbers as
## they are. The full renderer (Forward+) treats them as light amounts and brightens them on the
## way to the screen: a dark steel floor of 0.08 comes out at 0.30, deep green comes out lime,
## and the whole game looks pale and milky. That was the "washed out" look.
##
## On Forward+ every one of those shaders gets the same small change as it first appears: color
## inputs are read as the numbers they are, the shader does its sums the way it was written,
## and the result is converted once, at the very end. The picture then matches what the colors
## were chosen for. On the light renderer nothing is touched.

const MARK := "_s2l("
const HELPER := """
vec3 _s2l(vec3 c) {
	vec3 lo = c / 12.92;
	vec3 hi = pow((max(c, vec3(0.0)) + 0.055) / 1.055, vec3(2.4));
	vec3 v = mix(lo, hi, step(vec3(0.04045), c));
	return mix(v, c, step(vec3(1.0), c));
}
"""

static var _on := -1
static var _hint: RegEx = null
static var _hint_only: RegEx = null


static func active() -> bool:
	if _on < 0:
		_on = 1 if (RenderingServer.get_current_rendering_method() != "gl_compatibility" and not ("--no-shaderfix" in OS.get_cmdline_user_args())) else 0
	return _on == 1


## Called for every node that enters the tree (a frame later, so its materials are on it).
static func node(n: Node) -> void:
	if not active() or not is_instance_valid(n):
		return
	if n is WorldEnvironment:
		var e := (n as WorldEnvironment).environment
		if e and e.sky and e.sky.sky_material is ShaderMaterial:
			shader((e.sky.sky_material as ShaderMaterial).shader)
		return
	if not (n is GeometryInstance3D):
		return
	var g := n as GeometryInstance3D
	_mat(g.material_override)
	_mat(g.material_overlay)
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				_mat(mi.get_surface_override_material(i))
				_mat(mi.mesh.surface_get_material(i))
	elif g is MultiMeshInstance3D:
		var mm := (g as MultiMeshInstance3D).multimesh
		if mm and mm.mesh:
			for i in mm.mesh.get_surface_count():
				_mat(mm.mesh.surface_get_material(i))
	elif g is GPUParticles3D:
		for i in (g as GPUParticles3D).draw_passes:
			var pm := (g as GPUParticles3D).get_draw_pass_mesh(i)
			if pm:
				for s in pm.get_surface_count():
					_mat(pm.surface_get_material(s))
	elif g is CPUParticles3D:
		var cm := (g as CPUParticles3D).mesh
		if cm:
			for s in cm.get_surface_count():
				_mat(cm.surface_get_material(s))


## The same a frame later, by id: the node may be gone by then.
static func node_later(id: int) -> void:
	var o := instance_from_id(id)
	if o != null and is_instance_valid(o) and o is Node:
		node(o as Node)


static func _mat(m: Material) -> void:
	while m != null:
		if m is ShaderMaterial:
			shader((m as ShaderMaterial).shader)
		m = m.next_pass


## Change one shader, once.
static func shader(sh: Shader) -> void:
	if sh == null or sh.has_meta("s2l") or not active():
		return
	sh.set_meta("s2l", true)
	if sh.resource_path != "" and not sh.resource_path.contains("::"):
		return                      # a shader file from disk: leave it as it was written
	var code := sh.code
	var fixed := fixed_code(code)
	if fixed != code:
		sh.code = fixed


static func fixed_code(code: String) -> String:
	if code.contains(MARK) or code.contains("hint_screen_texture") or code.contains("hint_depth_texture"):
		return code
	var kind := ""
	if code.contains("shader_type spatial"):
		kind = "spatial"
	elif code.contains("shader_type sky"):
		kind = "sky"
	else:
		return code
	var fn_rx := RegEx.new()
	fn_rx.compile("void\\s+" + ("sky" if kind == "sky" else "fragment") + "\\s*\\(")
	if fn_rx.search(code) == null:
		return code                 # nothing here sets a color
	if _hint == null:
		_hint = RegEx.new()
		_hint.compile(":\\s*source_color\\s*,\\s*")
		_hint_only = RegEx.new()
		_hint_only.compile(":\\s*source_color\\b")
	var out := _hint.sub(code, ": ", true)
	out = _hint_only.sub(out, "", true)
	# The helper goes right after the header lines (shader_type, render_mode).
	var at := out.find("shader_type")
	at = out.find(";", at) + 1
	var rm := out.find("render_mode", at)
	if rm >= 0 and out.substr(at, rm - at).strip_edges() == "":
		at = out.find(";", rm) + 1
	out = out.substr(0, at) + HELPER + out.substr(at)
	if kind == "sky":
		return _append(out, "sky", "\tCOLOR = _s2l(COLOR);\n")
	return _append(out, "fragment", "\tALBEDO = _s2l(ALBEDO);\n\tEMISSION = _s2l(EMISSION);\n")


## Add lines at the very end of `void <fn>() { ... }`.
static func _append(code: String, fn: String, lines: String) -> String:
	var rx := RegEx.new()
	rx.compile("void\\s+" + fn + "\\s*\\(\\s*\\)\\s*\\{")
	var hit := rx.search(code)
	if hit == null:
		return code
	var i := hit.get_end()
	var depth := 1
	while i < code.length() and depth > 0:
		var ch := code[i]
		if ch == "{":
			depth += 1
		elif ch == "}":
			depth -= 1
		i += 1
	if depth != 0:
		return code
	var close := i - 1
	return code.substr(0, close) + lines + code.substr(close)
