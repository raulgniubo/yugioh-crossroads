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


static func _beam(board: Node3D, a: Vector3, b: Vector3, col: Color, radius := 0.4) -> void:
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
## `ctx` is what the duel knows at that moment: {"attacker": where the attacking monster stands,
## "summoned": where the monster that just arrived stands}; Vector3.INF when there is none.
static func card(board: Node3D, card_name: String, p: int, ctx := {}) -> bool:
	var n := card_name.to_lower()
	var o := 1 - p
	var mine: Vector3 = board.monster_zone_pos(p, 2)
	var theirs: Vector3 = board.monster_zone_pos(o, 2)
	var attacker: Vector3 = ctx.get("attacker", Vector3.INF)
	if n.contains("magic cylinder"):
		_magic_cylinder(board, p, attacker if attacker != Vector3.INF else theirs)
		return true
	if n.contains("mirror force"):
		_mirror_force(board, p, attacker if attacker != Vector3.INF else theirs)
		return true
	if n.contains("torrential tribute"):
		_torrent(board)
		return true
	if n.contains("solemn judgment") or n.contains("solemn warning") or n.contains("solemn strike"):
		_solemn(board, o)
		return true
	if n.contains("bottomless trap hole"):
		var fell: Vector3 = ctx.get("summoned", Vector3.INF)
		_bottomless(board, fell if fell != Vector3.INF else theirs)
		return true
	if n.contains("burst stream of destruction"):
		_burst_stream(board, p)
		return true
	if n.contains("dark magic attack"):
		_dark_magic_attack(board, p)
		return true
	for w in ["hinotama", "ookazi", "tremendous fire", "just desserts", "meteor of destruction", "final flame", "sparks", "raimei", "poison of the old man"]:
		if n == w or (w.length() > 6 and n.contains(w)):
			_burn(board, p)
			return true
	for w in ["dian keto", "red medicine", "blue medicine", "goblin's secret remedy", "soul of the pure", "rain of mercy", "nutrient z", "enchanted javelin"]:
		if n.contains(w):
			_heal(board, p)
			return true
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
	elif n.contains("negate attack") or n == "waboku" or n.contains("draining shield") or n.contains("sakuretsu"):
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


# ------------------------------------------------------------------ the famous ones, as set pieces (0.84.0)

## Does this card have a look that plays ON the card it targets (see card_on)?
static func aims(card_name: String) -> bool:
	var n := card_name.to_lower()
	for w in ["ring of destruction", "spellbinding circle", "shadow spell", "fiendish chain", "change of heart", "brain control", "mind control", "snatch steal",
			"enemy controller", "book of moon", "compulsory evacuation", "dimensional prison", "mystical space typhoon", "twister", "dust tornado", "thousand knives"]:
		if n.contains(w):
			return true
	return false


## The look of a famous Spell or Trap on the very card it was aimed at. `p` is who played it.
static func card_on(board: Node3D, card_name: String, p: int, at: Vector3) -> void:
	var n := card_name.to_lower()
	var floor_at := Vector3(at.x, 0.03, at.z)
	if n.contains("ring of destruction"):
		# The ring closes round it, its charges light one by one, and it goes off.
		var red := Color("ff4a2a")
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.62
		tm.outer_radius = 0.72
		ring.mesh = tm
		ring.material_override = _add_mat(red, 0.95)
		ring.position = at + Vector3(0, 0.55, 0)
		ring.scale = Vector3(2.4, 1, 2.4)
		board.add_child(ring)
		var tw := ring.create_tween()
		tw.tween_property(ring, "scale", Vector3.ONE, Settings.t(0.28)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(ring, "rotation:y", TAU, Settings.t(0.6))
		tw.tween_interval(Settings.t(0.34))
		tw.tween_property(ring, "scale", Vector3(3.2, 0.2, 3.2), Settings.t(0.12))
		tw.parallel().tween_property(ring.material_override, "albedo_color:a", 0.0, Settings.t(0.12))
		tw.tween_callback(ring.queue_free)
		for k in 8:
			var ang := float(k) * TAU / 8.0
			var spot := at + Vector3(cos(ang) * 0.67, 0.55, sin(ang) * 0.67)
			board.get_tree().create_timer(Settings.t(0.26 + 0.04 * k)).timeout.connect(func(): DuelFx.glow(board, spot, Color("ffd060"), 0.5, 0.3, 0.6, 3.0))
		board.get_tree().create_timer(Settings.t(0.64)).timeout.connect(func():
			DuelFx.rays(board, floor_at, red, 2.8, 0.45, 30)
			DuelFx.ring(board, floor_at, red, 0.4, 3.0, 0.55, 0.08)
			DuelFx.embers(board, floor_at, Color("ff7a2a"), 0.7, 60, 1.0, 3.6, 0.08)
			DuelFx.glow(board, at + Vector3(0, 0.5, 0), Color("ffe0a0"), 3.0, 0.4, 0.8, 3.0)
			board.shake(0.9)
			Sfx.play("impact", -2.0, 0.7))
	elif n.contains("spellbinding circle") or n.contains("shadow spell") or n.contains("fiendish chain"):
		# A circle is written under it and chains come out of the four corners and hold it.
		var col := Color("b06bff") if not n.contains("spellbinding") else Color("ffd76a")
		DuelFx.glyph(board, floor_at, col, 1.05, 1.5, {"star": 3, "rings": 2, "turn": 2.2})
		for k in 4:
			var corner := at + Vector3(1.9 if k % 2 == 0 else -1.9, 2.3, 1.5 if k < 2 else -1.5)
			var chain := DuelFx.chain(board, corner, at + Vector3(0, 0.45, 0), col.lightened(0.3), board.camera if "camera" in board else null, 0.22, 0.16)
			board.get_tree().create_timer(Settings.t(1.25)).timeout.connect(func():
				if is_instance_valid(chain):
					DuelFx.fade(chain, 0.25))
		DuelFx.ring(board, floor_at, col, 1.6, 0.5, 0.4, 0.06, 0.2)
		Sfx.play("trap", -4.0, 0.8)
	elif n.contains("change of heart") or n.contains("brain control") or n.contains("mind control") or n.contains("snatch steal") or n.contains("enemy controller"):
		# Light on one side of it and dark on the other, turning round it; then a thread to its new master.
		board._swirl(at + Vector3(0, 0.7, 0), Color("fff0f6"))
		board._swirl(at + Vector3(0, 0.7, 0), Color("6a2ad0"))
		DuelFx.pillar(board, floor_at, Color("ff7ad9"), 0.55, 3.2, 0.9, 0.0, 2.2)
		DuelFx.ring(board, floor_at, Color("fff0f6"), 0.3, 1.6, 0.5, 0.06)
		DuelFx.ring(board, floor_at, Color("8a3cf0"), 1.8, 0.4, 0.5, 0.06, 0.18)
		DuelFx.embers(board, floor_at, Color("ffb0e6"), 0.5, 22, 0.9, 2.0, 0.05)
		var to: Vector3 = board.monster_zone_pos(p, 2) + Vector3(0, 0.4, 0)
		board.get_tree().create_timer(Settings.t(0.3)).timeout.connect(func(): _beam(board, at + Vector3(0, 0.6, 0), to, Color("ff7ad9"), 0.07))
		Sfx.play("sparkle", -4.0, 0.9)
	elif n.contains("book of moon"):
		# A crescent crosses over it and night falls on that one zone.
		var moon := MeshInstance3D.new()
		var tmm := TorusMesh.new()
		tmm.inner_radius = 0.5
		tmm.outer_radius = 0.62
		moon.mesh = tmm
		moon.material_override = _add_mat(Color("bcd4ff"), 0.95)
		moon.rotation = Vector3(PI / 2.0, 0, 0)
		moon.scale = Vector3(1.0, 1.0, 0.55)
		moon.position = at + Vector3(-1.6, 1.3, 0)
		board.add_child(moon)
		var mt := moon.create_tween()
		mt.tween_property(moon, "position", at + Vector3(1.6, 1.3, 0), Settings.t(0.6)).set_trans(Tween.TRANS_SINE)
		mt.parallel().tween_property(moon, "rotation:z", -1.2, Settings.t(0.6))
		mt.tween_property(moon.material_override, "albedo_color:a", 0.0, Settings.t(0.2))
		mt.tween_callback(moon.queue_free)
		DuelFx.pit(board, floor_at, 0.85, 0.9)
		DuelFx.embers(board, floor_at, Color("bcd4ff"), 0.6, 24, 0.9, 1.4, 0.04)
		Sfx.play("sparkle", -5.0, 0.6)
	elif n.contains("compulsory evacuation"):
		# The floor under it fires: it leaves straight up.
		DuelFx.pillar(board, floor_at, Color("7fd8ff"), 0.5, 8.0, 0.6, 0.0, 2.6)
		DuelFx.ring(board, floor_at, Color("7fd8ff"), 0.3, 1.8, 0.45, 0.07)
		DuelFx.rect(board, floor_at, Color("ffd060"), 1.0, 1.5, 0.4, false, 2.6, 0.7)
		DuelFx.sparks(board, floor_at, Color("fff0c0"), 40, 6.0, 1.0, 0.7, -9.0, 0.05)
		board.shake(0.45)
		Sfx.play("whoosh", -2.0, 1.4)
	elif n.contains("dimensional prison"):
		# A door in the air opens behind it, takes it, and shuts.
		board._vortex(at + Vector3(0, 0.7, 0), Color("8a5cff"))
		DuelFx.rect(board, floor_at, Color("8a5cff"), 2.2, 0.9, 0.5, false, 2.6, 0.5)
		DuelFx.rect(board, floor_at, Color("d0b8ff"), 1.6, 0.6, 0.45, false, 2.6, 0.0)
		DuelFx.pit(board, floor_at, 0.8, 0.8)
		Sfx.play("whoosh", -3.0, 0.7)
	elif n.contains("thousand knives"):
		# The knives come one after another, from above, all on the same card.
		for k in 9:
			var from := at + Vector3(-1.6 + k * 0.4, 3.2 + 0.2 * (k % 3), 2.0 if p == 0 else -2.0)
			var to := at + Vector3(-0.3 + 0.075 * k, 0.3, 0)
			board.get_tree().create_timer(Settings.t(0.05 * k)).timeout.connect(func():
				_beam(board, from, to, Color("e8f0ff"), 0.035)
				DuelFx.sparks(board, to, Color("ffffff"), 5, 2.4, 0.5, 0.35, -6.0, 0.04))
		board.get_tree().create_timer(Settings.t(0.5)).timeout.connect(func():
			DuelFx.ring(board, floor_at, Color("e8f0ff"), 0.3, 1.5, 0.4, 0.05)
			board.shake(0.5)
			Sfx.play("impact", -5.0, 1.6))
	else:
		# Mystical Space Typhoon, Twister, Dust Tornado: the wind on the very card it takes.
		board._swirl(at + Vector3(0, 0.6, 0), Color("9fffd0"))
		board._swirl(at + Vector3(0, 0.9, 0), Color("d8fff0"))
		DuelFx.ring(board, floor_at, Color("9fffd0"), 0.3, 1.3, 0.4, 0.05)
		Sfx.play("whoosh", -2.0, 1.0)


## A tube of light with a bright rim at each end, lying on its side, facing along `dir`.
static func _tube(board: Node3D, at: Vector3, dir: Vector3, col: Color) -> Node3D:
	var root := Node3D.new()
	root.position = at
	board.add_child(root)
	root.look_at_from_position(at, at + dir, Vector3.UP)
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 1.3
	cm.cap_top = false
	cm.cap_bottom = false
	cm.radial_segments = 28
	body.mesh = cm
	body.rotation.x = PI / 2.0
	body.material_override = _add_mat(col, 0.3)
	root.add_child(body)
	for end in [-0.65, 0.0, 0.65]:
		var rim := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.48 if end != 0.0 else 0.5
		tm.outer_radius = 0.57 if end != 0.0 else 0.53
		rim.mesh = tm
		rim.rotation.x = PI / 2.0
		rim.position.z = end
		rim.material_override = _add_mat(Color("ffc840") if end != 0.0 else col.lightened(0.2), 0.9)
		root.add_child(rim)
	root.scale = Vector3(0.05, 0.05, 0.05)
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, Settings.t(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return root


## Magic Cylinder: two cylinders stand in the attack's way. It goes into the first, and comes out
## of the second straight at the duelist who sent it.
static func _magic_cylinder(board: Node3D, p: int, attacker: Vector3) -> void:
	var o := 1 - p
	var pink := Color("ff4fc0")
	var front := 0.55 if p == 1 else -0.55        # (toward the other side of the table)
	var lane := clampf(attacker.x, -3.0, 3.0)
	var a_at := Vector3(lane - 0.95, 0.7, board.monster_zone_pos(p, 2).z + front)
	var b_at := Vector3(lane + 0.95, 0.7, board.monster_zone_pos(p, 2).z + front)
	var their_seat := Vector3(0, 1.1, 5.4 if o == 0 else -5.4)
	var tube_a := _tube(board, a_at, (attacker + Vector3(0, 0.6, 0) - a_at).normalized(), pink)
	var tube_b := _tube(board, b_at, (their_seat - b_at).normalized(), pink)
	DuelFx.ring(board, Vector3(a_at.x, 0.03, a_at.z), pink, 0.3, 1.1, 0.4, 0.05)
	DuelFx.ring(board, Vector3(b_at.x, 0.03, b_at.z), pink, 0.3, 1.1, 0.4, 0.05, 0.06)
	Sfx.play("trap", -4.0, 1.3)
	var tree := board.get_tree()
	# In: the attack is pulled into the first one.
	tree.create_timer(Settings.t(0.36)).timeout.connect(func():
		_beam(board, attacker + Vector3(0, 0.6, 0), a_at, Color("ffb060"), 0.26)
		DuelFx.glow(board, a_at, Color("ffe9d0"), 1.6, 0.35, 0.6, 2.8)
		DuelFx.sparks(board, a_at, pink.lightened(0.3), 26, 4.0, 0.2, 0.5, -2.0, 0.05))
	# A beat while it crosses from one to the other.
	tree.create_timer(Settings.t(0.62)).timeout.connect(func():
		_beam(board, a_at, b_at, pink.lightened(0.3), 0.1)
		DuelFx.glow(board, b_at, pink.lightened(0.4), 1.2, 0.3, 0.5, 2.6))
	# Out: it leaves the second one at whoever attacked.
	tree.create_timer(Settings.t(0.9)).timeout.connect(func():
		_beam(board, b_at, their_seat, pink, 0.36)
		_beam(board, b_at, their_seat, Color.WHITE, 0.14)
		DuelFx.glow(board, b_at, Color.WHITE, 2.0, 0.35, 0.8, 3.0)
		DuelFx.rays(board, Vector3(their_seat.x, 0.03, their_seat.z * 0.72), pink, 2.4, 0.45, 24)
		DuelFx.ring(board, Vector3(their_seat.x, 0.03, their_seat.z * 0.72), pink, 0.3, 2.6, 0.5, 0.07)
		board.shake(0.8)
		Sfx.play("impact", -3.0, 1.1))
	for tube in [tube_a, tube_b]:
		var tw := (tube as Node3D).create_tween()
		tw.tween_interval(Settings.t(1.4))
		tw.tween_property(tube, "scale", Vector3(0.01, 0.01, 0.01), Settings.t(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback((tube as Node3D).queue_free)


const MIRROR := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0, 0.92, 0.6, 1.0);
uniform float alpha = 0.0;
uniform float sweep = -0.3;
uniform float crack = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 g = UV * vec2(18.0, 5.0);
	vec2 d = abs(fract(vec2(g.x + g.y, g.x - g.y)) - 0.5);
	float pane = smoothstep(0.43, 0.5, max(d.x, d.y));
	float cell = hash(floor(vec2(g.x + g.y, g.x - g.y)));
	float sheen = exp(-pow((UV.x + UV.y * 0.3 - sweep * 1.6) / 0.09, 2.0));
	float edge = smoothstep(0.0, 0.12, UV.y) * smoothstep(0.0, 0.05, UV.x) * smoothstep(0.0, 0.05, 1.0 - UV.x) * smoothstep(0.0, 0.2, 1.0 - UV.y);
	float broken = step(cell, crack);
	ALBEDO = tint.rgb * (0.5 + 0.9 * pane + 1.6 * sheen + 0.35 * cell) + vec3(1.0) * sheen * 0.6;
	ALPHA = clamp((0.2 + 0.55 * pane + 0.7 * sheen + 0.12 * cell) * edge * alpha * (1.0 - broken), 0.0, 1.0);
}
"""
static var _mirror_sh: Shader


## Mirror Force: a wall of mirror stands up in front of your monsters. The attack breaks on it, a
## light runs across it, and it sends a blade of that light at every monster of theirs in Attack
## Position. Then it comes apart.
static func _mirror_force(board: Node3D, p: int, attacker: Vector3) -> void:
	var o := 1 - p
	var gold := Color("ffe9a0")
	var front := 0.72 if p == 1 else -0.72
	var wall_at: Vector3 = board.monster_zone_pos(p, 2) + Vector3(0, 0, front)
	if _mirror_sh == null:
		_mirror_sh = Shader.new()
		_mirror_sh.code = MIRROR
	var m := ShaderMaterial.new()
	m.shader = _mirror_sh
	m.set_shader_parameter("tint", gold)
	m.set_shader_parameter("alpha", 0.0)
	m.set_shader_parameter("sweep", -0.3)
	m.set_shader_parameter("crack", 0.0)
	var wall := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(9.4, 1.8)
	wall.mesh = qm
	wall.material_override = m
	wall.position = wall_at + Vector3(0, 0.1, 0)
	wall.scale = Vector3(1, 0.05, 1)
	board.add_child(wall)
	var tw := wall.create_tween()
	tw.tween_property(wall, "scale", Vector3.ONE, Settings.t(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(wall, "position:y", 0.95, Settings.t(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(m, "shader_parameter/alpha", 1.0, Settings.t(0.14))
	tw.tween_property(m, "shader_parameter/sweep", 1.3, Settings.t(0.45))
	tw.tween_interval(Settings.t(0.3))
	tw.tween_property(m, "shader_parameter/crack", 1.0, Settings.t(0.3))
	tw.tween_callback(wall.queue_free)
	for k in 6:
		board._ring_fx(wall_at + Vector3(-3.6 + k * 1.44, 0.05, 0), gold, 0.4, k * 0.02, 1.8)
	Sfx.play("trap", -5.0, 1.2)
	var tree := board.get_tree()
	var hit_at := Vector3(clampf(attacker.x, -4.0, 4.0), 0.85, wall_at.z)
	# The attack lands on the mirror...
	tree.create_timer(Settings.t(0.24)).timeout.connect(func():
		_beam(board, attacker + Vector3(0, 0.6, 0), hit_at, Color("ffd0a0"), 0.28)
		DuelFx.glow(board, hit_at, Color.WHITE, 2.4, 0.4, 0.9, 3.0)
		DuelFx.rays(board, hit_at, gold, 1.8, 0.35, 22, false, 2.8)
		board.shake(0.5))
	# ...and comes back as a blade for each of theirs that stands in Attack Position.
	var marks: Array = []
	if board.state_ref != null:
		var row: Array = board.state_ref.players[o].field
		for z in mini(5, row.size()):
			var mon = row[z]
			if mon != null and mon.is_monster() and mon.face_up and mon.attack_pos:
				marks.append(board.monster_zone_pos(o, z))
	if marks.is_empty():
		for z in 5:
			marks.append(board.monster_zone_pos(o, z))
	for i in marks.size():
		var to: Vector3 = marks[i]
		tree.create_timer(Settings.t(0.6 + 0.05 * i)).timeout.connect(func():
			_beam(board, Vector3(to.x * 0.8, 1.1, wall_at.z), to + Vector3(0, 0.35, 0), gold, 0.16)
			DuelFx.glow(board, to + Vector3(0, 0.4, 0), Color.WHITE, 1.6, 0.3, 0.7, 2.8)
			DuelFx.rays(board, Vector3(to.x, 0.03, to.z), gold, 1.5, 0.35, 18)
			DuelFx.ring(board, Vector3(to.x, 0.03, to.z), gold, 0.3, 1.4, 0.4, 0.05))
	tree.create_timer(Settings.t(0.62)).timeout.connect(func():
		board.shake(0.75)
		Sfx.play("impact", -3.0, 1.4))
	# The mirror breaks.
	tree.create_timer(Settings.t(1.1)).timeout.connect(func():
		board._shatter(wall_at + Vector3(-2.2, 0.7, 0), gold, Vector3.ZERO, "few")
		board._shatter(wall_at + Vector3(2.2, 0.7, 0), gold, Vector3.ZERO, "few")
		Sfx.play("destroy", -8.0, 1.5))


## Torrential Tribute: a wall of water crosses the whole table and takes every monster with it.
static func _torrent(board: Node3D) -> void:
	var blue := Color("1f86ff")
	var wave := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(11.0, 2.6)
	wave.mesh = qm
	var m := _add_mat(blue, 0.0)
	wave.material_override = m
	wave.position = Vector3(0, 1.1, -5.2)
	board.add_child(wave)
	var crest := MeshInstance3D.new()
	var cq := QuadMesh.new()
	cq.size = Vector2(11.0, 0.5)
	crest.mesh = cq
	crest.material_override = _add_mat(Color("bfe6ff"), 0.7)
	crest.position = Vector3(0, 1.3, 0.02)
	wave.add_child(crest)
	var tw := wave.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.6, Settings.t(0.12))
	tw.parallel().tween_property(wave, "position:z", 5.2, Settings.t(0.75)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.2))
	tw.parallel().tween_property(crest.material_override, "albedo_color:a", 0.0, Settings.t(0.2))
	tw.tween_callback(wave.queue_free)
	var tree := board.get_tree()
	for side in 2:
		for z in 5:
			var at: Vector3 = board.monster_zone_pos(side, z)
			# (the wave reaches each zone as it passes: the far row first)
			var when := 0.12 + 0.75 * (at.z + 5.2) / 10.4
			tree.create_timer(Settings.t(when)).timeout.connect(func():
				DuelFx.pillar(board, Vector3(at.x, 0.03, at.z), blue, 0.45, 2.6, 0.5, 0.0, 1.5)
				DuelFx.ring(board, Vector3(at.x, 0.03, at.z), blue, 0.2, 1.2, 0.45, 0.04, 0.0, 1.5)
				DuelFx.sparks(board, at + Vector3(0, 0.2, 0), Color("cfeaff"), 16, 4.2, 0.9, 0.7, -12.0, 0.05))
	board.shake(0.8)
	Sfx.play("whoosh", -1.0, 0.6)
	tree.create_timer(Settings.t(0.5)).timeout.connect(func(): Sfx.play("impact", -5.0, 0.6))


## Solemn Judgment (and Warning, and Strike): a light comes straight down on their side of the
## table and says no. Two bars of it cross, and it is over.
static func _solemn(board: Node3D, o: int) -> void:
	var gold := Color("ffe6a0")
	var at: Vector3 = board.monster_zone_pos(o, 2)
	at = Vector3(0, 0.03, at.z * 1.15)
	DuelFx.pillar(board, at, gold, 1.3, 9.0, 0.9, 0.0, 2.6)
	DuelFx.pillar(board, at, Color.WHITE, 0.5, 9.0, 0.7, 0.05, 3.0)
	DuelFx.glyph(board, at, gold, 2.2, 1.1, {"star": 0, "rings": 3, "ticks": 48, "turn": -1.2})
	DuelFx.ring(board, at, gold, 0.4, 3.6, 0.6, 0.09)
	DuelFx.embers(board, at, gold, 1.2, 50, 1.1, 3.4, 0.06)
	board.shake(0.7)
	Sfx.play("trap", -3.0, 0.7)
	var tree := board.get_tree()
	tree.create_timer(Settings.t(0.32)).timeout.connect(func():
		_beam(board, at + Vector3(-2.4, 2.6, 0), at + Vector3(2.4, 0.4, 0), gold, 0.16)
		_beam(board, at + Vector3(2.4, 2.6, 0), at + Vector3(-2.4, 0.4, 0), gold, 0.16)
		DuelFx.glow(board, at + Vector3(0, 1.5, 0), Color.WHITE, 3.0, 0.4, 0.9, 3.0)
		DuelFx.rays(board, at, Color.WHITE, 3.0, 0.4, 28)
		Sfx.play("impact", -3.0, 0.9))


## Bottomless Trap Hole: the floor opens much wider than a card, and what stood there keeps falling.
static func _bottomless(board: Node3D, at: Vector3) -> void:
	var floor_at := Vector3(at.x, 0.03, at.z)
	DuelFx.pit(board, floor_at, 1.5, 1.1)
	DuelFx.ring(board, floor_at, Color("7a3cff"), 2.4, 0.4, 0.5, 0.07)
	DuelFx.ring(board, floor_at, Color("b99aff"), 1.8, 0.3, 0.5, 0.05, 0.12)
	DuelFx.embers(board, floor_at, Color("7a3cff"), 1.1, 34, 0.9, -1.4, 0.05)
	DuelFx.spiral(board, floor_at, Color("7a3cff"), Color("1a0a3a"), 1.4, 1.0)
	board.shake(0.5)
	Sfx.play("impact", -5.0, 0.5)


## Burst Stream of Destruction: one white breath that crosses their whole row from end to end.
static func _burst_stream(board: Node3D, p: int) -> void:
	var o := 1 - p
	var white := Color("dff2ff")
	var blue := Color("5ab8ff")
	var from: Vector3 = board.monster_zone_pos(p, 2) + Vector3(0, 1.4, 0)
	DuelFx.glow(board, from, white, 2.2, 0.5, 0.9, 3.0)
	DuelFx.rays(board, from, blue, 1.6, 0.4, 20, false)
	Sfx.play("charge", -4.0, 1.3)
	var tree := board.get_tree()
	for z in 5:
		var to: Vector3 = board.monster_zone_pos(o, z if p == 0 else 4 - z)
		tree.create_timer(Settings.t(0.28 + 0.07 * z)).timeout.connect(func():
			_beam(board, from, to + Vector3(0, 0.3, 0), blue, 0.3)
			_beam(board, from, to + Vector3(0, 0.3, 0), Color.WHITE, 0.12)
			DuelFx.glow(board, to + Vector3(0, 0.4, 0), white, 1.8, 0.35, 0.8, 3.0)
			DuelFx.ring(board, Vector3(to.x, 0.03, to.z), blue, 0.3, 1.5, 0.4, 0.06)
			DuelFx.sparks(board, to + Vector3(0, 0.3, 0), white, 12, 4.5, 0.8, 0.5, -8.0, 0.05))
	tree.create_timer(Settings.t(0.3)).timeout.connect(func():
		board.shake(1.0)
		Sfx.play("impact", -2.0, 1.2))


## Dark Magic Attack: a wave of dark magic rolls over every Spell and Trap they have.
static func _dark_magic_attack(board: Node3D, p: int) -> void:
	var o := 1 - p
	var violet := Color("b06bff")
	var from: Vector3 = board.monster_zone_pos(p, 2) + Vector3(0, 1.2, 0)
	DuelFx.glyph(board, Vector3(from.x, 0.03, from.z), violet, 1.2, 1.0, {"star": 6, "rings": 2, "turn": 2.0})
	DuelFx.glow(board, from, violet, 1.8, 0.5, 0.8, 2.8)
	Sfx.play("charge", -4.0, 0.9)
	var tree := board.get_tree()
	for z in 5:
		var to: Vector3 = board.st_pos(o, z)
		tree.create_timer(Settings.t(0.3 + 0.05 * absf(z - 2.0))).timeout.connect(func():
			_beam(board, from, to + Vector3(0, 0.2, 0), violet, 0.14)
			DuelFx.rect(board, Vector3(to.x, 0.03, to.z), violet, 0.9, 1.6, 0.4, false, 2.6, 0.6)
			DuelFx.embers(board, Vector3(to.x, 0.03, to.z), Color("e0c0ff"), 0.4, 14, 0.8, 2.0, 0.05))
	tree.create_timer(Settings.t(0.34)).timeout.connect(func():
		board.shake(0.7)
		Sfx.play("impact", -4.0, 0.8))


## Burn Spells (Hinotama, Ookazi, Tremendous Fire...): fire falls on the other duelist's side.
static func _burn(board: Node3D, p: int) -> void:
	var o := 1 - p
	var fire := Color("ff7a2a")
	var seat := Vector3(0, 0.03, 4.3 if o == 0 else -4.3)
	var tree := board.get_tree()
	for k in 3:
		var land := seat + Vector3(-1.6 + 1.6 * k, 0, 0)
		var from := land + Vector3(-1.2, 6.0, -2.4 if o == 0 else 2.4)
		tree.create_timer(Settings.t(0.1 * k)).timeout.connect(func():
			_beam(board, from, land + Vector3(0, 0.2, 0), fire, 0.2)
			DuelFx.glow(board, land + Vector3(0, 0.4, 0), Color("ffe0a0"), 2.0, 0.4, 0.8, 3.0)
			DuelFx.ring(board, land, fire, 0.3, 1.8, 0.45, 0.07)
			DuelFx.embers(board, land, fire, 0.6, 26, 1.0, 2.8, 0.07)
			Sfx.play("impact", -5.0, 0.9 + 0.15 * k))
	board.shake(0.7)


## Healing Spells (Dian Keto the Cure Master...): a soft green light rises round whoever played it.
static func _heal(board: Node3D, p: int) -> void:
	var green := Color("8affb0")
	var seat := Vector3(0, 0.03, 4.3 if p == 0 else -4.3)
	DuelFx.pillar(board, seat, green, 1.4, 5.0, 1.1, 0.0, 1.8)
	DuelFx.ring(board, seat, green, 2.4, 0.5, 0.6, 0.06)
	DuelFx.ring(board, seat, Color("e0ffe8"), 1.8, 0.3, 0.6, 0.04, 0.15)
	DuelFx.embers(board, seat, Color("d0ffe0"), 1.4, 40, 1.3, 2.4, 0.06)
	Sfx.play("sparkle", -4.0, 0.8)
