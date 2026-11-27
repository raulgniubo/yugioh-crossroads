class_name SummonFx
extends RefCounted
## The set piece of each kind of Extra Deck and Ritual Summon (0.57.0), played on the table
## with the real material cards:
##   Synchro  the Tuner becomes rings of light (one per Level), the other materials become
##            stars (one per Level) that fly up through them, and a pillar of light answers.
##   Xyz      a galaxy opens in the floor, each material turns into a light and spirals down
##            into it, and it bursts. The monster rises out of it.
##   Fusion   the materials circle a whirl of two colors, closer and closer, are drawn in,
##            the whirl folds to a point and bursts.
##   Ritual   a magic circle draws itself, blue flames light around it, the offerings sink
##            into it and burn away, and a pillar of light comes down.
## Each one returns at the moment the new monster should appear. `mats` are the material
## cards' insts that still have a card on the table; `board` is the DuelBoard.

## The colors of the set pieces. They are the same for every card but Lumen's forms, which
## have their own (0.81.0): see LOOKS and `look` in play().
const PLAIN := {"GREEN": Color("6dff9a"), "GOLD": Color("ffd23a"), "VIOLET": Color("b15cff"), "BLUE": Color("5aa8ff"), "ORANGE": Color("ff8a3a"), "AZURE": Color("3aa0ff")}
const LOOKS := {
	"comet": {"GREEN": Color("7fe8ff")},
	"zenith": {"GOLD": Color("9fe0ff"), "VIOLET": Color("8a6bff")},
	"chorus": {"ORANGE": Color("ff8fd6"), "AZURE": Color("6fd0ff"), "VIOLET": Color("ffc8f0")},
	"nova": {"ORANGE": Color("ffd24d"), "AZURE": Color("5a9eff"), "VIOLET": Color("ffffff")},
	"aurora": {"BLUE": Color("4dffb0")},
}
static var GREEN := Color("6dff9a")
static var GOLD := Color("ffd23a")
static var VIOLET := Color("b15cff")
static var BLUE := Color("5aa8ff")
static var ORANGE := Color("ff8a3a")
static var AZURE := Color("3aa0ff")
static var _look := ""


static func _palette(look: String) -> void:
	var p: Dictionary = PLAIN.duplicate()
	p.merge(LOOKS.get(look, {}), true)
	GREEN = p["GREEN"]
	GOLD = p["GOLD"]
	VIOLET = p["VIOLET"]
	BLUE = p["BLUE"]
	ORANGE = p["ORANGE"]
	AZURE = p["AZURE"]
	_look = look


## `look`: "" for any card; "chorus", "comet", "zenith", "aurora", "nova" for Lumen's forms.
static func play(board, method: String, at: Vector3, core: Vector3, mats: Array, look := "") -> void:
	_palette(look)
	match method:
		"synchro":
			await _synchro(board, at, core, mats)
		"xyz":
			await _xyz(board, at, core, mats)
		"fusion":
			await _fusion(board, at, core, mats)
		"ritual":
			await _ritual(board, at, core, mats)
	_palette("")


static func _levels(list: Array, lo: int, hi: int, fallback: int) -> int:
	var n := 0
	for m in list:
		n += int(m.level()) if m.has_method("level") else 0
	return clampi(n if n > 0 else fallback, lo, hi)


## A material card shrinks into a point of light and is gone (the card node is freed later by the board).
static func _to_light(board, m, color: Color, dur := 0.2) -> Vector3:
	var c: Card3D = board.card_for(m)
	if c == null:
		return Vector3.ZERO
	var at := c.position
	var tw: Tween = board.create_tween().set_parallel()
	tw.tween_property(c, "scale", Vector3(0.12, 0.12, 0.12), Settings.t(dur)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_method(c.flash, 0.5, 4.0, Settings.t(dur))
	tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(dur))
	DuelFx.glow(board, at, color, 1.4, 0.35, 0.5)
	return at


static func _synchro(board, at: Vector3, core: Vector3, mats: Array) -> void:
	var tuners: Array = mats.filter(func(m): return bool(m.data.get("tuner", false)))
	var others: Array = mats.filter(func(m): return not bool(m.data.get("tuner", false)))
	if tuners.is_empty() and mats.size() > 1:
		tuners = [mats[0]]
		others = mats.slice(1)
	var n_rings := _levels(tuners, 1, 5, 3)
	var n_stars := _levels(others, 1, 8, 4)
	# The Tuner becomes rings, stacked over the zone.
	for m in tuners:
		_to_light(board, m, GREEN)
	var rings: Array = []
	var span := 2.5
	for i in n_rings:
		var y := 0.55 + (i + 0.5) * span / n_rings
		var r := DuelFx.glyph(board, Vector3(at.x, at.y + y, at.z), GREEN, 0.85 - 0.04 * i, 9.0,
				{"rings": 0, "ticks": 0, "star": 0, "keep": true, "energy": 3.0, "turn": 5.0, "dash": 0})
		(r.material_override as ShaderMaterial).set_shader_parameter("width", 0.04)
		rings.append(r)
		Sfx.play("blip", -8.0, 1.0 + 0.14 * i)
		await board._wait(0.07)
	# The others become stars, in a line under the rings.
	var from: Array = []
	for m in others:
		var p := _to_light(board, m, Color.WHITE)
		if p != Vector3.ZERO:
			from.append(p)
	if from.is_empty():
		from.append(at + Vector3(0, 1.4, 0.6))
	var stars: Array = []
	for k in n_stars:
		var o := DuelFx.orb(board, from[k % from.size()], Color(1.0, 1.0, 0.85), 0.2)
		stars.append(o)
		var line := Vector3(at.x, at.y + 0.18 + 0.1 * k, at.z)
		board.create_tween().tween_property(o, "position", line, Settings.t(0.24)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await board._wait(0.3)
	# They fly up through the rings, one after another.
	Sfx.play("whoosh", -4.0, 1.5)
	for k in n_stars:
		var o2: FxOrb = stars[k]
		var tw: Tween = board.create_tween()
		tw.tween_interval(Settings.t(0.035 * k))
		tw.tween_property(o2, "position", Vector3(at.x, at.y + 3.6 + 0.05 * k, at.z), Settings.t(0.34)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for i in rings.size():
		# (each ring flares as the stars go through it)
		var rm := (rings[i] as MeshInstance3D).material_override as ShaderMaterial
		var tw2: Tween = board.create_tween()
		tw2.tween_interval(Settings.t(0.1 + 0.05 * i))
		tw2.tween_property(rm, "shader_parameter/energy", 6.0, Settings.t(0.06))
		tw2.tween_property(rm, "shader_parameter/energy", 3.0, Settings.t(0.2))
	await board._wait(0.36 + 0.035 * n_stars)
	# The pillar of light.
	DuelFx.pillar(board, at, GREEN.lerp(Color.WHITE, 0.2), 0.62, 7.5, 0.95, 0.0, 1.9)
	DuelFx.ring(board, at, GREEN, 0.4, 2.6, 0.6, 0.06)
	for o3 in stars:
		if is_instance_valid(o3):
			(o3 as FxOrb).queue_free()
	for r2 in rings:
		var mi := r2 as MeshInstance3D
		var tw3: Tween = board.create_tween().set_parallel()
		tw3.tween_property(mi, "scale", Vector3(1.9, 1, 1.9), Settings.t(0.3)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw3.tween_property(mi.material_override, "shader_parameter/alpha", 0.0, Settings.t(0.3))
		tw3.chain().tween_callback(mi.queue_free)
	DuelFx.glow(board, core, GREEN.lerp(Color.WHITE, 0.7), 2.8, 0.5, 1.0, 2.4)
	DuelFx.rays(board, core, GREEN, 2.8, 0.45, 30, false)
	if _look == "comet":
		# Lumen's Comet: a tail of light falls across the field into the pillar.
		for i in 5:
			var cs: Vector3 = at + Vector3(3.4 - i * 0.2, 4.4 + i * 0.3, -1.6)
			var co := DuelFx.orb(board, cs, Color.WHITE if i == 0 else GREEN, 0.34 - 0.04 * i)
			co.trail = true
			var ct: Tween = board.create_tween()
			ct.tween_interval(Settings.t(0.03 * i))
			ct.tween_property(co, "position", at + Vector3(0, 0.3, 0), Settings.t(0.22)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			ct.tween_callback(co.pop.bind(0.8))
	board.shake(0.5)
	Sfx.play("special", -2.0, 1.1)
	await board._wait(0.2)


static func _xyz(board, at: Vector3, core: Vector3, mats: Array) -> void:
	DuelFx.pit(board, at, 1.5, 1.75)
	var sp := DuelFx.spiral(board, at + Vector3(0, 0.05, 0), GOLD, VIOLET, 1.95, 2.0, {"hole": 0.2, "keep": true, "speed": 4.5, "twist": 5.5})
	Sfx.play("whoosh", -3.0, 0.7)
	await board._wait(0.32)
	# Every material turns into a light and spirals down into the galaxy.
	var starts: Array = []
	for m in mats:
		var p := _to_light(board, m, GOLD)
		if p != Vector3.ZERO:
			starts.append(p)
	if starts.is_empty():
		starts = [at + Vector3(-1.2, 1.6, 0.2), at + Vector3(1.2, 1.6, -0.2)]
	var orbs: Array = []
	for i in starts.size():
		var s: Vector3 = starts[i]
		var o := DuelFx.orb(board, s, GOLD if i % 2 == 0 else VIOLET.lightened(0.2), 0.34)
		orbs.append(o)
		var a0 := atan2(s.z - at.z, s.x - at.x)
		var r0 := maxf(0.9, Vector2(s.x - at.x, s.z - at.z).length())
		var y0 := s.y
		var tw: Tween = board.create_tween()
		tw.tween_interval(Settings.t(0.06 * i))
		tw.tween_method(func(t: float):
			if not is_instance_valid(o):
				return
			var ang := a0 + t * DuelFx.TAU_F * 1.75
			var rad := r0 * pow(1.0 - t, 0.8)
			o.position = Vector3(at.x + cos(ang) * rad, lerpf(y0, at.y + 0.12, t * t), at.z + sin(ang) * rad), 0.0, 1.0, Settings.t(0.68)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	Sfx.play("charge", -6.0, 1.2)
	await board._wait(0.72 + 0.06 * starts.size())
	for o2 in orbs:
		if is_instance_valid(o2):
			(o2 as FxOrb).pop(1.2)
	# The galaxy bursts.
	DuelFx.glow(board, at + Vector3(0, 0.5, 0), Color(1.0, 0.95, 0.75), 2.8, 0.5, 1.0, 2.4)
	DuelFx.ring(board, at, GOLD, 0.3, 2.8, 0.6, 0.06)
	DuelFx.rays(board, at, GOLD, 3.0, 0.5, 32)
	DuelFx.pillar(board, at, GOLD, 0.7, 6.5, 0.8, 0.0, 1.8)
	DuelFx.sparks(board, at + Vector3(0, 0.2, 0), GOLD, 50, 6.0, 0.7)
	if _look == "zenith":
		# Lumen's Zenith: two lights go round the place she rises from.
		for i in 2:
			var zo := DuelFx.orb(board, at + Vector3(1.4 if i == 0 else -1.4, 0.9, 0), VIOLET.lightened(0.3) if i == 0 else GOLD, 0.26)
			zo.trail = true
			var zt: Tween = board.create_tween()
			zt.tween_method(func(t: float):
				if is_instance_valid(zo):
					var za := t * DuelFx.TAU_F * 1.5 + PI * i
					zo.position = at + Vector3(cos(za) * 1.4, 0.9 + 0.5 * t, sin(za) * 1.4), 0.0, 1.0, Settings.t(0.7))
			zt.tween_callback(zo.pop.bind(0.8))
	DuelFx.fade(sp, 0.4)
	board.shake(0.6)
	Sfx.play("special", -2.0, 0.9)
	await board._wait(0.14)


static func _fusion(board, at: Vector3, core: Vector3, mats: Array) -> void:
	var whirl := DuelFx.spiral(board, core, ORANGE, AZURE, 1.55, 2.0, {"flat": false, "arms": 2, "twist": 7.0, "speed": 6.5, "keep": true, "energy": 2.6})
	Sfx.play("whoosh", -3.0, 0.9)
	await board._wait(0.18)
	# The materials circle the whirl, closer and closer, and are drawn into it.
	var n := maxi(1, mats.size())
	var i := 0
	for m in mats:
		var c: Card3D = board.card_for(m)
		if c == null:
			continue
		var col := ORANGE if i % 2 == 0 else AZURE
		var s := c.position
		var a0 := PI if i % 2 == 0 else 0.0
		var r0 := 1.45
		var o := DuelFx.orb(board, s, col, 0.3)
		var rot0 := c.rotation.z
		var tw: Tween = board.create_tween()
		tw.tween_method(func(t: float):
			if not is_instance_valid(c):
				return
			var ang := a0 + t * DuelFx.TAU_F * 1.6
			var rad := r0 * (1.0 - t * t)
			var pos := core + Vector3(cos(ang) * rad, sin(ang) * rad * 0.62, 0.05 * (1.0 if i % 2 == 0 else -1.0))
			c.position = pos
			c.rotation.z = rot0 + t * 7.0
			c.scale = Vector3.ONE * lerpf(1.0, 0.18, t * t)
			c.set_alpha(clampf((1.0 - t) * 3.0, 0.0, 1.0))
			if is_instance_valid(o):
				o.position = pos, 0.0, 1.0, Settings.t(0.78)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if is_instance_valid(o):
				o.queue_free())
		c.set_glow(true, col)
		i += 1
	Sfx.play("charge", -6.0, 0.9)
	await board._wait(0.8)
	# The whirl folds into a point...
	var wt: Tween = board.create_tween()
	wt.tween_property(whirl, "scale", Vector3.ONE * 0.04, Settings.t(0.16)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	wt.tween_callback(whirl.queue_free)
	await board._wait(0.2)
	# ...and bursts.
	DuelFx.glow(board, core, Color(0.95, 0.85, 1.0), 3.0, 0.55, 1.0, 2.4)
	DuelFx.rays(board, core, VIOLET.lightened(0.2), 3.0, 0.5, 30, false)
	DuelFx.ring(board, at, VIOLET, 0.3, 2.6, 0.6, 0.06)
	DuelFx.sparks(board, core, ORANGE, 30, 5.0, 0.4)
	DuelFx.sparks(board, core, AZURE, 30, 5.0, 0.4)
	if _look == "nova":
		# Lumen's Nova: one ring for each world she has crossed, then all of it in white.
		var four := [Color("5a9eff"), Color("ffd24d"), Color("b86bff"), Color("eef8ff")]
		for w in 4:
			DuelFx.ring(board, at, four[w], 0.3, 2.2 + 0.8 * w, 0.7, 0.07, 0.07 * w)
			DuelFx.rays(board, core, four[w], 2.6 + 0.5 * w, 0.55, 14, false)
		DuelFx.glow(board, core, Color.WHITE, 5.0, 0.7, 1.0, 3.0)
		DuelFx.pillar(board, at, Color(1.0, 0.97, 0.85), 0.9, 8.0, 1.0, 0.1, 2.2)
	elif _look == "chorus":
		# Lumen's Chorus: the two voices go out as rings, one after the other.
		DuelFx.ring(board, at, ORANGE, 0.3, 2.4, 0.6, 0.06, 0.08)
		DuelFx.ring(board, at, AZURE, 0.3, 3.0, 0.7, 0.06, 0.18)
	board.shake(0.6)
	Sfx.play("special", -2.0, 1.0)
	await board._wait(0.12)


static func _ritual(board, at: Vector3, core: Vector3, mats: Array) -> void:
	DuelFx.glyph(board, at, BLUE, 1.6, 2.9, {"star": 3, "rings": 2, "ticks": 48, "turn": 2.6, "energy": 2.6})
	Sfx.play("spell", -4.0, 0.7)
	await board._wait(0.2)
	# Blue fire around the circle, one flame after another.
	for i in 6:
		var a := DuelFx.TAU_F * i / 6.0 - PI / 2.0
		var fp := at + Vector3(cos(a) * 1.33, 0, sin(a) * 1.33)
		DuelFx.embers(board, fp, BLUE.lightened(0.15), 0.09, 26, 2.2 - 0.05 * i, 1.9, 0.11)
		DuelFx.glow(board, fp + Vector3(0, 0.18, 0), BLUE, 0.7, 0.4)
		Sfx.play("blip", -12.0, 0.8 + 0.06 * i)
		await board._wait(0.05)
	# The offerings sink into the circle and burn away.
	var k := 0
	for m in mats:
		var c: Card3D = board.card_for(m)
		if c == null:
			continue
		var down := at + Vector3((k - (mats.size() - 1) * 0.5) * 0.5, 0.35, 0)
		var tw: Tween = board.create_tween().set_parallel()
		tw.tween_property(c, "position", down, Settings.t(0.36)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(c, "scale", Vector3.ONE * 0.45, Settings.t(0.36))
		tw.tween_method(c.flash, 0.0, 3.0, Settings.t(0.36))
		tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.14)).set_delay(Settings.t(0.26))
		k += 1
	await board._wait(0.4)
	DuelFx.sparks(board, at + Vector3(0, 0.3, 0), BLUE.lightened(0.3), 40, 3.5, 0.9, 0.9, 1.5)
	Sfx.play("tribute", -3.0)
	await board._wait(0.16)
	# The light comes down.
	DuelFx.pillar(board, at, BLUE.lightened(0.15), 0.8, 7.5, 1.35, 0.0, 1.9)
	DuelFx.ring(board, at, Color.WHITE, 0.3, 2.3, 0.55, 0.05)
	DuelFx.glow(board, core + Vector3(0, 0.6, 0), BLUE.lightened(0.5), 3.4, 0.5, 1.0)
	if _look == "aurora":
		# Lumen's Aurora: curtains of light stand up across the whole field behind her.
		for i in 13:
			var ax := -4.8 + i * 0.8
			DuelFx.pillar(board, Vector3(ax, 0.0, at.z - 2.4 - 0.3 * sin(i * 1.3)), Color("4dffb0") if i % 2 == 0 else Color("9a6bff"), 0.36, 5.0 + 1.4 * sin(i * 2.1), 1.9, 0.04 * i, 1.0)
	board.shake(0.45)
	Sfx.play("special", -2.0, 0.85)
	await board._wait(0.22)
