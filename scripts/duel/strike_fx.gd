class_name StrikeFx
## How a monster's attack lands, by what kind of monster it is (a blade slash, claws, jaws, a
## beam, a spell blast, a crushing blow), and the signature look of well-known Spells and Traps.
## Everything is built from simple shapes and frees itself. `board` is the DuelBoard.

const KINDS := {
	"Warrior": "slash", "Beast-Warrior": "slash", "Zombie": "slash",
	"Beast": "claw", "Winged Beast": "claw", "Insect": "claw", "Reptile": "claw", "Fiend": "claw",
	"Dinosaur": "bite", "Sea Serpent": "bite", "Fish": "bite",
	"Dragon": "beam", "Machine": "beam", "Thunder": "beam", "Pyro": "beam",
	"Spellcaster": "blast", "Fairy": "blast", "Psychic": "blast", "Aqua": "blast", "Plant": "blast",
	"Rock": "smash",
}
const SLASH := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform float prog = 0.0;
uniform float tilt = 0.6;
uniform float size = 2.2;
uniform float offset = 0.0;
uniform vec3 tint : source_color = vec3(1.0, 0.9, 0.7);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	VERTEX *= size;
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float c = cos(tilt); float s = sin(tilt);
	p = vec2(p.x * c - p.y * s, p.x * s + p.y * c);
	p.y += offset;
	// A crescent: part of a big circle whose center sits below the picture.
	vec2 q = p - vec2(0.0, -1.1);
	float r = length(q);
	float ang = atan(q.y, q.x);
	float t = 1.0 - (ang - 0.75) / (2.39 - 0.75);
	float inside = step(0.0, t) * step(t, 1.0);
	float width = 0.15 * sin(clamp(t, 0.0, 1.0) * 3.14159);
	float band = smoothstep(width, 0.0, abs(r - 1.45));
	// The cut sweeps across, bright at the tip with a tail behind it.
	float head = prog * 1.5;
	float sweep = smoothstep(head, head - 0.12, t) * smoothstep(head - 0.95, head - 0.3, t);
	float a = band * inside * sweep;
	ALBEDO = mix(tint, vec3(1.0), smoothstep(0.5, 1.0, band)) * 2.2;
	ALPHA = clamp(a, 0.0, 1.0);
}
"""

static var _slash_sh: Shader


static func kind_of(inst) -> String:
	if inst == null:
		return "slash"
	return str(KINDS.get(str(inst.data.get("race", "")), "slash"))


static func _add_mat(col: Color, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, alpha)
	return m


static func _slash(board: Node3D, at: Vector3, col: Color, tilt: float, offset := 0.0, delay := 0.0, size := 3.4) -> void:
	if _slash_sh == null:
		_slash_sh = Shader.new()
		_slash_sh.code = SLASH
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	var m := ShaderMaterial.new()
	m.shader = _slash_sh
	m.set_shader_parameter("tint", col)
	m.set_shader_parameter("tilt", tilt)
	m.set_shader_parameter("offset", offset)
	m.set_shader_parameter("size", size)
	mi.material_override = m
	mi.position = at
	mi.extra_cull_margin = 6.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	board.add_child(mi)
	var tw := mi.create_tween()
	tw.tween_interval(Settings.t(delay))
	tw.tween_method(func(v: float): m.set_shader_parameter("prog", v), 0.0, 1.35, Settings.t(0.36))
	tw.tween_callback(mi.queue_free)


static func _beam(board: Node3D, a: Vector3, b: Vector3, col: Color, radius := 0.24) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius * 0.6
	cm.height = a.distance_to(b)
	cm.radial_segments = 10
	mi.mesh = cm
	var m := _add_mat(col, 0.85)
	mi.material_override = m
	mi.position = (a + b) / 2.0
	board.add_child(mi)
	if a.distance_to(b) > 0.05:
		mi.look_at_from_position(mi.position, b, Vector3.UP if absf((b - a).normalized().y) < 0.95 else Vector3.RIGHT)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	var core := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = radius * 0.4
	cc.bottom_radius = radius * 0.25
	cc.height = cm.height
	core.mesh = cc
	core.material_override = _add_mat(Color.WHITE, 0.9)
	mi.add_child(core)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(0.05, 1.0, 0.05), Settings.t(0.32)).set_ease(Tween.EASE_IN)
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.32))
	tw.chain().tween_callback(mi.queue_free)


## The strike that goes with this monster's kind. `from` is the attacker, `at` where it lands.
static func play(board: Node3D, inst, from: Vector3, at: Vector3) -> void:
	var col: Color = board.ATTR_COLORS.get(str(inst.data.get("attribute", "")) if inst != null else "", Color("ffd9a0"))
	var hit := at + Vector3(0, 0.75, 0)
	match kind_of(inst):
		"slash":
			_slash(board, hit, col.lightened(0.4), 0.7)
			if inst != null and int(inst.data.get("level", 4)) >= 7:
				_slash(board, hit, col.lightened(0.2), -0.7, 0.0, 0.1)
			Sfx.play("whoosh", -6.0, 1.7)
		"claw":
			for k in 3:
				_slash(board, hit, col.lightened(0.3), 0.95, -0.22 + k * 0.22, k * 0.03, 3.0)
			Sfx.play("whoosh", -6.0, 2.0)
		"bite":
			# Two rows of teeth snap shut on the target.
			var m := _add_mat(Color(1.0, 0.98, 0.9), 0.95)
			for row in 2:
				var jaw := Node3D.new()
				jaw.position = hit + Vector3(0, 0.75 if row == 0 else -0.55, 0)
				board.add_child(jaw)
				for k in 5:
					var tooth := MeshInstance3D.new()
					var pr := PrismMesh.new()
					pr.size = Vector3(0.24, 0.42 - absf(k - 2.0) * 0.06, 0.08)
					tooth.mesh = pr
					tooth.material_override = m
					tooth.position = Vector3(-0.56 + k * 0.28, 0, 0)
					tooth.rotation.z = PI if row == 0 else 0.0
					jaw.add_child(tooth)
				var tw := jaw.create_tween()
				tw.tween_property(jaw, "position:y", hit.y + (0.16 if row == 0 else -0.06), Settings.t(0.1)).set_ease(Tween.EASE_IN)
				tw.tween_interval(Settings.t(0.12))
				tw.tween_property(jaw, "scale", Vector3(1.3, 0.01, 1.0), Settings.t(0.12))
				tw.tween_callback(jaw.queue_free)
			Sfx.play("impact", -7.0, 1.6)
		"beam":
			_beam(board, from + Vector3(0, 0.9, 0), hit, col)
			board._ring_fx(at + Vector3(0, 0.1, 0), col, 0.8, 0.05, 1.2)
			Sfx.play("charge", -8.0, 1.6)
		"blast":
			# A circle of light under the target, then it goes up.
			for k in 3:
				board._ring_fx(at + Vector3(0, 0.06, 0), col.lerp(Color.WHITE, k * 0.3), 0.5 + k * 0.35, k * 0.05, 0.2 + k * 0.9)
			board._flash(hit, col)
			_beam(board, at + Vector3(0, 3.2, 0), at + Vector3(0, 0.1, 0), col.lightened(0.3), 0.16)
			Sfx.play("sparkle", -6.0, 0.8)
		"smash":
			var wedge := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(1.2, 1.6, 1.0)
			wedge.mesh = pm
			wedge.rotation.z = PI
			wedge.material_override = _add_mat(col.darkened(0.1), 0.8)
			wedge.position = at + Vector3(0, 3.6, 0)
			board.add_child(wedge)
			var tw2 := wedge.create_tween()
			tw2.tween_property(wedge, "position:y", at.y + 0.8, Settings.t(0.09)).set_ease(Tween.EASE_IN)
			tw2.tween_callback(func():
				board.shake(0.8)
				board._ring_fx(at + Vector3(0, 0.05, 0), col, 1.3, 0.0, 0.3))
			tw2.tween_property(wedge, "scale", Vector3(1.6, 0.05, 1.6), Settings.t(0.16))
			tw2.tween_callback(wedge.queue_free)
			Sfx.play("impact", -5.0, 0.55)


## The look of a famous Spell or Trap. `p` is who played it. Returns false if the card has none.
static func card(board: Node3D, card_name: String, p: int) -> bool:
	var n := card_name.to_lower()
	var o := 1 - p
	var mine: Vector3 = board.monster_zone_pos(p, 2)
	var theirs: Vector3 = board.monster_zone_pos(o, 2)
	if n == "raigeki" or n.contains("lightning vortex") or n.contains("thunder"):
		for z in 5:
			var at: Vector3 = board.monster_zone_pos(o, z)
			var delay := z * 0.05
			board.get_tree().create_timer(Settings.t(delay)).timeout.connect(func():
				_bolt(board, at)
				board._flash(at + Vector3(0, 0.5, 0), Color("fff6a0")))
		board.shake(1.0)
		Sfx.play("impact", -3.0, 1.5)
	elif n == "dark hole" or n.contains("black hole"):
		board._vortex(Vector3(0, 0.7, 0), Color("7a3cff"))
		board._rift(Vector3(0, 0, 0))
		for z in 5:
			for side in 2:
				_beam(board, board.monster_zone_pos(side, z) + Vector3(0, 0.3, 0), Vector3(0, 0.7, 0), Color("5a2ad0"), 0.07)
		board.shake(0.8)
	elif n.contains("mirror force") or n.contains("negate attack") or n == "waboku" or n.contains("draining shield") or n.contains("sakuretsu"):
		_barrier(board, mine + Vector3(0, 0, (0.9 if p == 1 else -0.9)), Color("9fe8ff") if not n.contains("mirror") else Color("ffe9a0"))
		if n.contains("mirror") or n.contains("sakuretsu"):
			for z in 5:
				_beam(board, mine + Vector3(0, 0.9, 0), board.monster_zone_pos(o, z) + Vector3(0, 0.4, 0), Color("ffe9a0"), 0.08)
			board.shake(0.7)
	elif n.contains("monster reborn") or n.contains("call of the haunted") or n.contains("premature burial"):
		_beam(board, mine + Vector3(0, 5.0, 0), mine + Vector3(0, 0.05, 0), Color("ffd866"), 0.5)
		for k in 4:
			board._ring_fx(mine + Vector3(0, 0.05, 0), Color("ffd866"), 0.6 + k * 0.2, k * 0.08, 2.4)
		Sfx.play("sparkle", -3.0, 0.7)
	elif n.contains("pot of greed") or n.contains("graceful charity") or n.contains("card destruction"):
		var dp: Vector3 = board.deck_pos(p)
		for k in 3:
			board._ring_fx(dp + Vector3(0, 0.3, 0), Color("6dff9a"), 0.5 + k * 0.2, k * 0.07, 1.6)
		board._flash(dp + Vector3(0, 0.8, 0), Color("6dff9a"))
		Sfx.play("coin", -6.0, 0.8)
	elif n.contains("typhoon") or n.contains("heavy storm") or n.contains("feather duster") or n.contains("twister"):
		var wide: bool = not n.contains("typhoon") and not n.contains("twister")
		for z in (5 if wide else 1):
			board._swirl(board.st_pos(o, z if wide else 2) + Vector3(0, 0.6, 0), Color("9fffd0"))
		Sfx.play("whoosh", -2.0, 0.9)
	elif n.contains("swords of revealing light"):
		for k in 9:
			var sx := -3.6 + k * 0.9
			var sword := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.16, 1.5, 0.05)
			sword.mesh = pm
			sword.rotation.z = PI
			sword.material_override = _add_mat(Color("fff4b0"), 0.9)
			sword.position = Vector3(sx, 6.0, theirs.z + (0.5 if k % 2 == 0 else -0.3))
			board.add_child(sword)
			var tw := sword.create_tween()
			tw.tween_interval(Settings.t(k * 0.04))
			tw.tween_property(sword, "position:y", 0.8, Settings.t(0.16)).set_ease(Tween.EASE_IN)
			tw.tween_interval(Settings.t(0.7))
			tw.tween_property(sword.material_override, "albedo_color:a", 0.0, Settings.t(0.3))
			tw.tween_callback(sword.queue_free)
		Sfx.play("sparkle", -3.0)
	elif n == "fissure" or n.contains("hammer shot") or n.contains("smashing ground") or n.contains("trap hole"):
		board._rift(theirs)
		board._ring_fx(theirs + Vector3(0, 0.04, 0), Color("ffb060"), 1.4, 0.0, 0.2)
		board.shake(0.9)
		Sfx.play("impact", -3.0, 0.6)
	elif n.contains("polymerization") or n.contains("fusion"):
		board._swirl(mine + Vector3(0, 0.8, 0), Color("b06cff"))
		board._swirl(mine + Vector3(0, 0.8, 0), Color("ff9a3c"))
		board._vortex(mine + Vector3(0, 0.8, 0), Color("b06cff"))
	elif n.contains("magic cylinder"):
		for sx: float in [-0.9, 0.9]:
			var cyl := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.5
			cm.bottom_radius = 0.5
			cm.height = 1.2
			cyl.mesh = cm
			cyl.rotation.x = PI / 2.0
			cyl.material_override = _add_mat(Color("ff7ad8"), 0.6)
			cyl.position = mine + Vector3(sx, 0.9, 0)
			cyl.scale = Vector3(0.1, 0.1, 0.1)
			board.add_child(cyl)
			var tw3 := cyl.create_tween()
			tw3.tween_property(cyl, "scale", Vector3.ONE, Settings.t(0.18)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw3.tween_interval(Settings.t(0.6))
			tw3.tween_property(cyl, "scale", Vector3(0.01, 0.01, 0.01), Settings.t(0.2))
			tw3.tween_callback(cyl.queue_free)
		board.get_tree().create_timer(Settings.t(0.35)).timeout.connect(func():
			_beam(board, mine + Vector3(0.9, 0.9, 0), Vector3(0, 1.0, 5.2 if o == 0 else -5.2), Color("ff7ad8"), 0.3))
	else:
		return false
	return true


static func _bolt(board: Node3D, at: Vector3) -> void:
	# A jagged line from the sky to the card, drawn as short glowing segments.
	var m := _add_mat(Color("fff6a0"), 1.0)
	var holder := Node3D.new()
	board.add_child(holder)
	var p := at + Vector3(randf_range(-0.6, 0.6), 6.0, randf_range(-0.4, 0.4))
	var steps := 7
	for k in steps:
		var t := float(k + 1) / steps
		var q := at.lerp(Vector3(p.x, 6.0, p.z), 1.0 - t) + Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.2, 0.2)) * (1.0 - t)
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.14, p.distance_to(q), 0.14)
		seg.mesh = bm
		seg.material_override = m
		seg.position = (p + q) / 2.0
		holder.add_child(seg)
		if p.distance_to(q) > 0.01:
			seg.look_at_from_position(seg.position, q, Vector3.RIGHT)
			seg.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		p = q
	var tw := holder.create_tween()
	tw.tween_interval(Settings.t(0.1))
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.22))
	tw.tween_callback(holder.queue_free)


static func _barrier(board: Node3D, at: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(9.0, 2.6)
	mi.mesh = qm
	var m := _add_mat(col, 0.0)
	mi.material_override = m
	mi.position = at + Vector3(0, 1.3, 0)
	board.add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.55, Settings.t(0.08))
	tw.tween_property(m, "albedo_color:a", 0.18, Settings.t(0.15))
	tw.tween_property(m, "albedo_color:a", 0.45, Settings.t(0.08))
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.5))
	tw.tween_callback(mi.queue_free)
	for k in 6:
		board._ring_fx(at + Vector3(-3.6 + k * 1.44, 0.05, 0), col, 0.4, k * 0.02, 1.8)
	Sfx.play("trap", -6.0, 1.2)
