class_name SigFx
extends RefCounted
## (0.85.0) The named attacks of the main monsters, as they cross the table and land. Until now an
## ace had its entrance and the name of its attack on screen, but the blow itself was the one every
## monster of its Type and Attribute throws. Each of these is a shape made of light (no models),
## in the monster's own colors; it replaces the element's travel and the Type's strike for that
## monster, is over in well under a second, and leaves nothing behind.
##   stream   a breath of light from the monster to its target (1, 2 or 3 of them)
##   orb      a ball of magic thrown from over its head
##   thunder  a crackling line, then bolts from the sky on the target
##   fist     a block of light comes down on the target like a fist
##   slash    two great cuts across the target, with a sun behind for Utopia
##   dive     it comes down from high above like a meteor
##   sonic    hoops of sound that widen as they fly
##   petals   a whirl of petals and thorns
##   multi    one stream for each color it has (Rainbow Dragon, Five-Headed Dragon)
##   jaws     fangs of water close on the target
## ATTACKS: card name in lower case -> [shape, color a, color b, size, count].

const ATTACKS := {
	"blue-eyes white dragon": ["stream", "dff2ff", "5ab8ff", 1.0, 1],
	"blue-eyes alternative white dragon": ["stream", "dff2ff", "5ab8ff", 1.1, 1],
	"blue-eyes ultimate dragon": ["stream", "dff2ff", "5ab8ff", 1.0, 3],
	"neo blue-eyes ultimate dragon": ["stream", "ffffff", "7fd0ff", 1.15, 3],
	"blue-eyes shining dragon": ["stream", "ffffff", "9fe8ff", 1.2, 1],
	"blue-eyes chaos max dragon": ["stream", "e0d0ff", "7a5cff", 1.3, 1],
	"dark magician": ["orb", "b06bff", "5a1ad0", 1.0, 1],
	"dark magician girl": ["orb", "ff8ad8", "ffd0f0", 0.85, 1],
	"dark magician of chaos": ["orb", "9a5cff", "2a0a5a", 1.2, 1],
	"dark paladin": ["slash", "7dffb0", "b06bff", 1.1, 2],
	"red-eyes black dragon": ["orb", "ff5a2a", "8a1a0a", 1.05, 1],
	"red-eyes darkness metal dragon": ["orb", "ff4a2a", "5a0a0a", 1.25, 1],
	"red-eyes dark dragoon": ["orb", "ff4a6a", "5a1ad0", 1.25, 1],
	"slifer the sky dragon": ["thunder", "ffe24d", "ff5a3a", 1.3, 3],
	"obelisk the tormentor": ["fist", "5a8cff", "c0d8ff", 1.35, 1],
	"the winged dragon of ra": ["stream", "fff0a0", "ffb02a", 1.45, 1],
	"summoned skull": ["thunder", "c79bff", "7a3cff", 1.0, 2],
	"black luster soldier": ["slash", "ffe9a0", "5a8cff", 1.0, 2],
	"black luster soldier - envoy of the beginning": ["slash", "ffe9a0", "5a8cff", 1.15, 2],
	"buster blader": ["slash", "d0e0ff", "7a8cff", 1.1, 1],
	"flame swordsman": ["slash", "ffb04a", "ff4a1a", 0.95, 1],
	"jinzo": ["orb", "7dffa6", "0a3a1a", 0.9, 1],
	"elemental hero neos": ["fist", "e0f4ff", "5ad0ff", 1.0, 1],
	"elemental hero flame wingman": ["dive", "ff8a2a", "ffd76a", 1.0, 1],
	"elemental hero shining flare wingman": ["dive", "ffffff", "9fe8ff", 1.15, 1],
	"cyber dragon": ["stream", "e8f4ff", "7fb8ff", 0.8, 1],
	"cyber twin dragon": ["stream", "e8f4ff", "7fb8ff", 0.85, 2],
	"cyber end dragon": ["stream", "ffffff", "7fb8ff", 1.0, 3],
	"rainbow dragon": ["multi", "ffffff", "ff5a5a", 1.0, 7],
	"five-headed dragon": ["multi", "ffffff", "ff5a5a", 1.0, 5],
	"stardust dragon": ["sonic", "e8fbff", "7fd8ff", 1.0, 5],
	"shooting star dragon": ["sonic", "ffffff", "9fe8ff", 1.2, 7],
	"shooting quasar dragon": ["sonic", "fff6c0", "ffd23a", 1.35, 7],
	"red dragon archfiend": ["fist", "ff3a2a", "ffb04a", 1.1, 1],
	"scarlight red dragon archfiend": ["fist", "ff3a2a", "ffb04a", 1.15, 1],
	"red nova dragon": ["fist", "ff2a1a", "ffd04a", 1.3, 1],
	"black rose dragon": ["petals", "e0244a", "5a0a2a", 1.0, 1],
	"ancient fairy dragon": ["sonic", "fff0a0", "a0ffd0", 1.0, 4],
	"black-winged dragon": ["orb", "ff3a4a", "1a0a1a", 1.0, 1],
	"number 39: utopia": ["slash", "ffd76a", "ffffff", 1.1, 2],
	"number c39: utopia ray": ["slash", "ffd76a", "ff5a8a", 1.2, 2],
	"number 39: utopia beyond": ["slash", "fff0a0", "9fe8ff", 1.3, 2],
	"number s39: utopia the lightning": ["slash", "fff6a0", "7fd8ff", 1.3, 2],
	"galaxy-eyes photon dragon": ["stream", "ffffff", "5ad8ff", 1.1, 1],
	"neo galaxy-eyes photon dragon": ["stream", "ffffff", "ff5ad8", 1.1, 3],
	"number 62: galaxy-eyes prime photon dragon": ["stream", "ffffff", "5ad8ff", 1.3, 1],
	"galaxy-eyes cipher dragon": ["stream", "e0ffff", "3ad0c0", 1.1, 1],
	"number 17: leviathan dragon": ["stream", "d0f0ff", "2a8cff", 1.0, 1],
	"number 32: shark drake": ["jaws", "9fd8ff", "1a5aff", 1.1, 1],
}
const RAINBOW := ["ff4a4a", "ff9a3a", "ffe24d", "6dff8a", "4ad0ff", "5a6aff", "c06bff"]


## (0.86.0) Every ace with an entrance of its own has an attack of its own too: the ones not in
## ATTACKS get one from their entrance (SummonShow.SIGNATURE): its two colors, and the shape that
## goes with its figure.
const FROM_FIGURE := {"cards": "orb", "circle": "orb", "lightning": "thunder", "flames": "orb", "aurora": "sonic", "nova": "dive", "hex": "orb",
	"rays": "stream", "stars": "sonic", "gears": "fist", "petals": "petals", "feathers": "sonic", "galaxy": "stream", "waves": "jaws",
	"streaks": "slash", "wings": "stream", "slash": "slash", "runes": "thunder", "storm": "thunder", "bloom": "petals", "photon": "stream"}
const COUNT := {"stream": 1, "orb": 1, "thunder": 2, "fist": 1, "slash": 2, "dive": 1, "sonic": 5, "petals": 1, "multi": 5, "jaws": 1}
static var _made := {}


static func _look(inst) -> Array:
	if inst == null:
		return []
	var nm := str(inst.data.get("name", ""))
	var lk: Array = ATTACKS.get(nm.to_lower(), [])
	if not lk.is_empty():
		return lk
	if _made.has(nm):
		return _made[nm]
	var out: Array = []
	if SummonShow.SIGNATURE.has(nm):
		var sg: Array = SummonShow.SIGNATURE[nm]
		var shape := str(FROM_FIGURE.get(str(sg[2]), "orb"))
		var cols := SummonShow.colors_of(inst.data)
		out = [shape, (cols[0] as Color).to_html(false), (cols[1] as Color).to_html(false), 1.2 if SummonShow.is_boss(inst.data) else 1.0, int(COUNT.get(shape, 1))]
	_made[nm] = out
	return out


static func has(inst) -> bool:
	return not _look(inst).is_empty()


static func _col(hex: String) -> Color:
	return Color(hex)


## The crossing: called when the monster lunges. `dur` is how long the lunge takes. Returns false
## when this monster has no attack of its own (the caller plays its element's instead).
static func travel(board: Node3D, inst, from: Vector3, to: Vector3, dur: float) -> bool:
	var lk := _look(inst)
	if lk.is_empty():
		return false
	var a := _col(lk[1])
	var b := _col(lk[2])
	var size: float = lk[3]
	var n: int = lk[4]
	var mouth := from + Vector3(0, 1.0, 0)
	var hit := to + Vector3(0, 0.55, 0)
	var dir := to - from
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, -1)
	var side := dir.cross(Vector3.UP).normalized()
	var tree := board.get_tree()
	board.shade(0.6 + dur, 0.5)
	match str(lk[0]):
		"stream", "multi":
			DuelFx.glow(board, mouth, a, 1.6 * size, 0.4, 0.8, 3.0)
			DuelFx.rays(board, mouth, b, 1.1 * size, 0.3, 14, false)
			for i in n:
				var off := (float(i) - float(n - 1) * 0.5) * 0.75
				var start := mouth + side * off + Vector3(0, 0.25 * absf(off), 0)
				var colb: Color = _col(RAINBOW[i % RAINBOW.size()]) if str(lk[0]) == "multi" else b
				# (two beats of the same breath, so it holds for the length of the lunge)
				for beat in 2:
					tree.create_timer(Settings.t(0.02 * i + beat * maxf(0.08, dur * 0.6))).timeout.connect(func():
						StrikeFx._beam(board, start, hit, colb, 0.3 * size / sqrt(float(n)) + 0.06)
						if str(lk[0]) != "multi":      # (each of the many keeps its own color: no white core over it)
							StrikeFx._beam(board, start, hit, a, 0.12 * size / sqrt(float(n)) + 0.03))
			DuelFx.sparks(board, mouth, a, 18, 5.0, 0.4, 0.5, -3.0, 0.05)
			Sfx.play("charge", -5.0, 1.5)
		"orb":
			var o := DuelFx.orb(board, mouth + Vector3(0, 0.5, 0), a, 0.8 * size)
			DuelFx.glyph(board, Vector3(from.x, 0.03, from.z), b.lightened(0.3), 1.0 * size, 0.7, {"star": 5, "rings": 1, "turn": 3.0})
			var tw := board.create_tween()
			tw.tween_property(o, "position", hit, Settings.t(maxf(0.1, dur))).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(o.pop.bind(1.8 * size))
			Sfx.play("whoosh", -4.0, 0.8)
		"thunder":
			for i in 3:
				var bend := hit.lerp(mouth, 0.5) + side * (0.5 if i % 2 == 0 else -0.5) + Vector3(0, 0.3 * i, 0)
				StrikeFx._beam(board, mouth, bend, a, 0.07 * size)
				StrikeFx._beam(board, bend, hit, a, 0.07 * size)
			DuelFx.glow(board, mouth, a, 1.4 * size, 0.3, 0.8, 3.0)
			Sfx.play("impact", -6.0, 1.9)
		"fist":
			var block := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.25, 1.5, 1.25) * size
			block.mesh = bm
			block.material_override = StrikeFx._add_mat(a, 0.55)
			block.position = to + Vector3(0, 5.2, 0) - dir * 1.4
			block.rotation = Vector3(0.25, atan2(dir.x, dir.z), 0)
			board.add_child(block)
			var core := MeshInstance3D.new()
			var cb := BoxMesh.new()
			cb.size = bm.size * 0.6
			core.mesh = cb
			core.material_override = StrikeFx._add_mat(b.lerp(Color.WHITE, 0.4), 0.8)
			block.add_child(core)
			var fw := block.create_tween()
			fw.tween_property(block, "position", to + Vector3(0, 0.75 * size, 0), Settings.t(maxf(0.12, dur))).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fw.tween_property(block, "scale", Vector3(1.7, 0.15, 1.7), Settings.t(0.12))
			fw.parallel().tween_property(block.material_override, "albedo_color:a", 0.0, Settings.t(0.16))
			fw.parallel().tween_property(core.material_override, "albedo_color:a", 0.0, Settings.t(0.16))
			fw.tween_callback(block.queue_free)
			DuelFx.pillar(board, Vector3(to.x, 0.03, to.z), a, 0.5 * size, 6.0, 0.4, 0.0, 1.4)
			Sfx.play("whoosh", -3.0, 0.6)
		"dive":
			var top := from.lerp(to, 0.45) + Vector3(0, 5.0, 0)
			var d := DuelFx.orb(board, top, a, 0.9 * size)
			var dw := board.create_tween()
			dw.tween_property(d, "position", hit, Settings.t(maxf(0.12, dur))).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			dw.tween_callback(d.pop.bind(2.0 * size))
			DuelFx.glow(board, top, b, 1.5 * size, 0.3, 0.8, 3.0)
			Sfx.play("whoosh", -3.0, 1.2)
		"sonic":
			for i in n:
				var t := float(i) / float(maxi(1, n - 1))
				_hoop(board, mouth.lerp(hit, 0.12 + 0.8 * t), dir, a if i % 2 == 0 else b, 0.25 * size, (0.5 + 0.75 * t) * size, 0.32, maxf(0.02, dur) * t * 0.9)
			StrikeFx._beam(board, mouth, hit, a, 0.08 * size)
			DuelFx.sparks(board, mouth, a, 26, 6.0, 0.3, 0.6, -2.0, 0.04)
			Sfx.play("whoosh", -3.0, 1.7)
		"petals":
			ElementFx.twister(board, Vector3(to.x, 0.03, to.z), a, b, 0.25 * size, 1.0 * size, 2.6, 0.6, 0.0, 1.6)
			for i in 3:
				var o2 := DuelFx.orb(board, mouth + side * (i - 1) * 0.5, a.lightened(0.2), 0.3)
				var pw := board.create_tween()
				pw.tween_interval(Settings.t(0.03 * i))
				pw.tween_property(o2, "position", hit + side * (1 - i) * 0.3, Settings.t(maxf(0.1, dur))).set_trans(Tween.TRANS_SINE)
				pw.tween_callback(o2.pop.bind(0.9))
			Sfx.play("whoosh", -4.0, 1.3)
		"slash":
			if n >= 2:
				# (the sun at its back, or the light of its blade)
				DuelFx.glow(board, from + Vector3(0, 1.6, 0) - dir * 0.6, a, 2.6 * size, 0.5, 0.6, 2.6)
				DuelFx.rays(board, from + Vector3(0, 1.6, 0) - dir * 0.6, a, 2.0 * size, 0.4, 20, false, 2.2)
			Sfx.play("whoosh", -4.0, 1.5)
		"jaws":
			StrikeFx._beam(board, mouth, hit, b, 0.12 * size)
			DuelFx.ring(board, Vector3(to.x, 0.03, to.z), a, 1.6 * size, 0.4, 0.3, 0.06)
			Sfx.play("whoosh", -4.0, 0.7)
	return true


## The landing: called at the moment of the hit. Returns false for a monster with no attack of its own.
static func impact(board: Node3D, inst, from: Vector3, to: Vector3) -> bool:
	var lk := _look(inst)
	if lk.is_empty():
		return false
	var a := _col(lk[1])
	var b := _col(lk[2])
	var size: float = lk[3]
	var n: int = lk[4]
	var floor_at := Vector3(to.x, 0.03, to.z)
	var hit := to + Vector3(0, 0.6, 0)
	var dir := to - from
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, -1)
	# What every one of them does when it lands: a flash, a ring, rays on the floor.
	# (kept in the monster's own color: on a pale table a wide white ring washes everything out)
	DuelFx.glow(board, hit, a.lerp(Color.WHITE, 0.25), 1.7 * size, 0.4, 0.8, 2.3)
	DuelFx.ring(board, floor_at, b, 0.3, 1.9 * size, 0.5, 0.045, 0.0, 1.9)
	DuelFx.rays(board, floor_at, a, 1.8 * size, 0.4, 22, true, 2.0)
	match str(lk[0]):
		"stream", "multi":
			DuelFx.pillar(board, floor_at, a, 0.5 * size, 4.5, 0.5, 0.0, 2.4)
			DuelFx.sparks(board, hit, a, 40, 7.0, 0.7, 0.7, -8.0, 0.05)
			if n >= 3:
				DuelFx.ring(board, floor_at, a, 0.4, 2.8 * size, 0.6, 0.05, 0.06, 1.8)
		"orb":
			DuelFx.glyph(board, floor_at, a, 1.3 * size, 0.8, {"star": 6, "rings": 2, "turn": -3.0})
			DuelFx.embers(board, floor_at, b.lightened(0.3), 0.8, 40, 1.0, 3.0, 0.07)
			DuelFx.spiral(board, floor_at, a, b, 1.2 * size, 0.7)
		"thunder":
			for i in n:
				var at := to + Vector3((i - (n - 1) * 0.5) * 0.55, 0, 0.2 * (i % 2))
				board.get_tree().create_timer(Settings.t(0.05 * i)).timeout.connect(func():
					StrikeFx._bolt(board, at)
					board._flash(at + Vector3(0, 0.5, 0), a))
			DuelFx.sparks(board, hit, a, 36, 6.0, 0.8, 0.6, -6.0, 0.05)
		"fist":
			DuelFx.ring(board, floor_at, a, 0.4, 2.6 * size, 0.6, 0.05, 0.05, 1.8)
			DuelFx.rect(board, floor_at, b, 1.2, 2.2 * size, 0.45, false, 2.0, 0.2)
			DuelFx.embers(board, floor_at, b, 1.0, 46, 0.9, 3.4, 0.08)
			for i in 6:
				var ang := float(i) * TAU / 6.0
				ElementFx.spike(board, floor_at + Vector3(cos(ang), 0, sin(ang)) * 0.95 * size, 0.16, 0.9 * size, a.darkened(0.5), b, 0.02 * i, 0.22, floor_at, -0.4)
		"slash":
			StrikeFx._slash(board, hit, a.lerp(Color.WHITE, 0.3), 0.75, 0.0, 0.0, 5.2 * size)
			if n >= 2:
				StrikeFx._slash(board, hit, b.lerp(Color.WHITE, 0.2), -0.75, 0.0, 0.08, 5.2 * size)
			DuelFx.sparks(board, hit, a, 30, 7.5, 0.5, 0.5, -7.0, 0.05)
		"dive":
			DuelFx.pillar(board, floor_at, a, 0.7 * size, 6.0, 0.6, 0.0, 2.4)
			DuelFx.embers(board, floor_at, a, 0.9, 50, 1.0, 3.6, 0.08)
			DuelFx.ring(board, floor_at, b, 0.4, 2.5 * size, 0.55, 0.05, 0.05, 1.8)
		"sonic":
			for i in 3:
				DuelFx.ring(board, floor_at, a if i % 2 == 0 else b, 0.3, (1.2 + 0.6 * i) * size, 0.5, 0.035, 0.06 * i, 1.8)
			DuelFx.sparks(board, hit, Color.WHITE, 60, 8.0, 0.6, 0.9, -3.0, 0.04)
			DuelFx.embers(board, floor_at, a, 1.2, 40, 1.2, 2.2, 0.05)
		"petals":
			DuelFx.embers(board, floor_at, a, 1.1, 60, 1.2, 2.6, 0.09)
			DuelFx.spiral(board, floor_at, a, b, 1.5 * size, 0.8)
			for i in 5:
				var ang2 := float(i) * TAU / 5.0 + 0.3
				ElementFx.spike(board, floor_at + Vector3(cos(ang2), 0, sin(ang2)) * 0.8, 0.1, 1.2, b, a, 0.03 * i, 0.3, floor_at, 0.5, 0.3)
		"jaws":
			for i in 8:
				var ang3 := float(i) * TAU / 8.0
				ElementFx.spike(board, floor_at + Vector3(cos(ang3) * 1.0, 0, sin(ang3) * 0.7) * size, 0.14, 1.3 * size, b, a, 0.015 * i, 0.26, floor_at, 0.45, 0.5)
			DuelFx.sparks(board, hit, a, 44, 6.0, 1.0, 0.8, -12.0, 0.05)
			DuelFx.ring(board, floor_at, a, 0.3, 2.3 * size, 0.55, 0.05, 0.08, 1.8)
	board.shake(0.5 + 0.35 * size)
	Sfx.play("impact", -2.0, 1.1 - 0.15 * size)
	return true


## A hoop of light facing down the line of the attack, widening as it goes.
static func _hoop(board: Node3D, at: Vector3, dir: Vector3, col: Color, r0: float, r1: float, life: float, delay: float) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 28
	mi.mesh = tm
	var m := StrikeFx._add_mat(col, 0.0)
	mi.material_override = m
	mi.position = at
	board.add_child(mi)
	mi.look_at_from_position(at, at + dir, Vector3.UP)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	mi.scale = Vector3.ONE * r0
	var tw := mi.create_tween()
	tw.tween_interval(Settings.t(delay))
	tw.tween_property(m, "albedo_color:a", 0.9, Settings.t(0.05))
	tw.tween_property(mi, "scale", Vector3.ONE * r1, Settings.t(life)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, Settings.t(life))
	tw.tween_callback(mi.queue_free)
