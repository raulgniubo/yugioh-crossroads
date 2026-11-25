class_name SummonShow
extends CanvasLayer
## The arrival of a big monster. Each signature card has its own colors and its own figure in
## the air (a magic circle, lightning, flames, a galaxy...) and every other strong monster gets
## one by attribute. The picture in the middle is the card's own art, from your card folder.
## It is drawn here with lines and light: no monster models.

## name -> [color A, color B, figure, line under the name, the name of its attack]
const SIGNATURE := {
	"Lumen, Echo Spirit": ["7fe8ff", "ffd76a", "cards", "Your partner", "Echo Flash"],
	"Lumen, Echo Chorus": ["ff8fd6", "6fd0ff", "circle", "Two voices, one song", "Chorus Wave"],
	"Lumen, Echo Comet": ["3fd8ff", "ffffff", "lightning", "Faster than the echo", "Comet Dive"],
	"Lumen, Echo Zenith": ["8a6bff", "ffd76a", "circle", "The sky, listening", "Zenith Orbit"],
	"Lumen, Echo Radiant": ["ffc23d", "fff6d6", "flames", "Every echo at once", "Radiant Answer"],
	"Dark Magician": ["8a4dff", "ff7ad9", "circle", "The ultimate wizard", "Dark Magic Attack"],
	"Dark Magician Girl": ["ff7ad9", "7cc4ff", "circle", "Apprentice of the dark arts", "Dark Burning Attack"],
	"Blue-Eyes White Dragon": ["bfe6ff", "3a7bff", "lightning", "Engine of destruction", "White Lightning"],
	"Blue-Eyes Ultimate Dragon": ["ffffff", "3a7bff", "lightning", "Three heads, one roar", "Neutron Blast"],
	"Red-Eyes Black Dragon": ["ff3a2a", "2a0a0a", "flames", "The dragon of potential", "Inferno Fire Blast"],
	"Red-Eyes Darkness Dragon": ["ff3a2a", "5a0a2a", "flames", "Darkness given wings", "Inferno Dark Fire"],
	"Summoned Skull": ["b06bff", "ffe36a", "lightning", "Lightning from the underworld", "Lightning Strike"],
	"Black Luster Soldier": ["ffd76a", "3a5fd9", "rays", "The chaos soldier", "Chaos Blade"],
	"Elemental HERO Neos": ["ffffff", "5affd0", "stars", "A hero from deep space", "Wrath of Neos"],
	"Elemental HERO Flame Wingman": ["5aff8a", "ff5a3c", "flames", "Hero of the skyfire", "Skydive Scorcher"],
	"Cyber Dragon": ["d8e6ff", "5a8aff", "gears", "The machine serpent", "Strident Blast"],
	"Cyber End Dragon": ["d8e6ff", "5a8aff", "gears", "Three engines, no brakes", "Super Strident Blaze"],
	"Armed Dragon LV7": ["ff8a3a", "5a2a0a", "flames", "It only gets bigger", "Dragon Talon Terror"],
	"Stardust Dragon": ["e8fbff", "5ad0ff", "stars", "The road of light", "Cosmic Flare"],
	"Junk Warrior": ["ff8a3a", "5a8aff", "gears", "Built from what was thrown away", "Scrap Fist"],
	"Red Dragon Archfiend": ["ff2a2a", "ffb03a", "flames", "The king's soul", "Scorching Crimson Flare"],
	"Black Rose Dragon": ["d9345a", "3a0a1a", "petals", "A garden of thorns", "Black Rose Flare"],
	"Blackwing Armor Master": ["3a3a4a", "9a7aff", "feathers", "Black wings at full speed", "Black Hurricane"],
	"Number 39: Utopia": ["ffd76a", "ffffff", "rays", "The king of wishes", "Rising Sun Slash"],
	"Galaxy-Eyes Photon Dragon": ["7ab0ff", "b06bff", "galaxy", "A galaxy in its eyes", "Photon Stream of Destruction"],
	"Number 17: Leviathan Dragon": ["3a8aff", "0a2a5a", "waves", "From the deepest water", "Vice Stream"],
}
const BY_ATTR := {"DARK": ["8a4dff", "2a0a4a", "circle"], "LIGHT": ["ffe9a8", "ffffff", "rays"], "FIRE": ["ff5a3c", "ffb03a", "flames"],
	"WATER": ["3a8aff", "9fe0ff", "waves"], "WIND": ["5aff8a", "d8ffe0", "streaks"], "EARTH": ["c9a76a", "5a3a1a", "hex"], "DIVINE": ["ffd76a", "ffffff", "rays"]}

static var dev_hold := 0.0        # dev: keep it on screen (screenshots)
var _t := 0.0
var _dur := 1.9
var _a := Color.WHITE
var _b := Color.WHITE
var _figure := "circle"
var _pad: Control
var _art: TextureRect
var _rng := RandomNumberGenerator.new()
var _seeds: Array = []
var _strike := false
var _dir := 1.0


## The name its attack is called by, or "" for a monster without one.
static func attack_name(card: Dictionary) -> String:
	var spec: Array = SIGNATURE.get(str(card.get("name", "")), [])
	return str(spec[4]) if spec.size() > 4 else ""


## A signature monster attacks: its picture cuts across the screen with the attack's name.
static func strike(host: Node, card: Dictionary, mine: bool) -> SummonShow:
	var nm := str(card.get("name", ""))
	var spec: Array = SIGNATURE.get(nm, [])
	if spec.size() < 5:
		return null
	var s := SummonShow.new()
	s._a = Color(str(spec[0]))
	s._b = Color(str(spec[1]))
	s._figure = str(spec[2])
	s._strike = true
	s._dur = 1.0
	s.layer = 4
	host.add_child(s)
	s._build_strike(card, str(spec[4]), mine)
	return s


func _build_strike(card: Dictionary, attack: String, mine: bool) -> void:
	_rng.seed = hash(attack)
	for i in 40:
		_seeds.append([_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf()])
	_dir = 1.0 if mine else -1.0
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_paint)
	add_child(_pad)
	var vp := get_viewport().get_visible_rect().size
	_art = TextureRect.new()
	_art.texture = Cards.get_art(int(card.get("id", 0)))
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.size = Vector2(300, 430)
	_art.pivot_offset = _art.size / 2.0
	_art.rotation = -0.1 * _dir
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var y := vp.y * 0.5 - 250.0
	var from_x := -340.0 if mine else vp.x + 40.0
	var hold_x := vp.x * (0.22 if mine else 0.78) - 150.0
	var out_x := vp.x + 80.0 if mine else -380.0
	_art.position = Vector2(from_x, y)
	add_child(_art)
	var name_l := UITheme.label(Loc.t(attack).to_upper() + "!", 66, Color.WHITE, UITheme.title_font())
	name_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	name_l.offset_left = -900
	name_l.offset_right = 900
	name_l.offset_top = 40
	name_l.offset_bottom = 130
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_color_override("font_outline_color", _b.darkened(0.6))
	name_l.add_theme_constant_override("outline_size", 16)
	name_l.modulate.a = 0.0
	add_child(name_l)
	Sfx.play("charge", -6.0, 1.3)
	var tw := create_tween()
	tw.tween_property(_art, "position:x", hold_x, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(name_l, "modulate:a", 1.0, 0.12).set_delay(0.1)
	tw.tween_property(_art, "position:x", hold_x + 40.0 * _dir, 0.45 + dev_hold)
	tw.tween_property(_art, "position:x", out_x, 0.16).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "_fade", 0.0, 0.2)
	tw.tween_callback(queue_free)


## Does this monster get an arrival? (Signature cards always; others from Level 7 up.)
static func wants(card: Dictionary) -> bool:
	return SIGNATURE.has(str(card.get("name", ""))) or int(card.get("level", 0)) >= 7


static func play(host: Node, card: Dictionary, mine: bool) -> SummonShow:
	var s := SummonShow.new()
	var nm := str(card.get("name", ""))
	var spec: Array = SIGNATURE.get(nm, [])
	var line := ""
	if spec.is_empty():
		var by: Array = BY_ATTR.get(str(card.get("attribute", "DARK")), BY_ATTR["DARK"])
		spec = [by[0], by[1], by[2], ""]
	else:
		line = str(spec[3])
	s._a = Color(str(spec[0]))
	s._b = Color(str(spec[1]))
	s._figure = str(spec[2])
	s.layer = 4
	host.add_child(s)
	s._build(card, nm, line, mine)
	return s


func _build(card: Dictionary, nm: String, line: String, mine: bool) -> void:
	_rng.seed = hash(nm)
	for i in 40:
		_seeds.append([_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf()])
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_paint)
	add_child(_pad)
	_art = TextureRect.new()
	_art.texture = Cards.get_art(int(card.get("id", 0)))
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_art.offset_left = -190
	_art.offset_right = 190
	_art.offset_top = -300
	_art.offset_bottom = 250
	_art.pivot_offset = Vector2(190, 275)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.modulate.a = 0.0
	add_child(_art)
	var name_l := UITheme.label(Loc.t(nm).to_upper(), 58, Color.WHITE, UITheme.title_font())
	name_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	name_l.offset_left = -800
	name_l.offset_right = 800
	name_l.offset_top = -250
	name_l.offset_bottom = -180
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_color_override("font_outline_color", _b.darkened(0.6))
	name_l.add_theme_constant_override("outline_size", 14)
	name_l.modulate.a = 0.0
	add_child(name_l)
	var sub := UITheme.label(Loc.t(line) if line != "" else ("ATK %s" % CardData.stat_text(card.get("atk", 0))), 26, _a.lightened(0.4), UITheme.semi_font())
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	sub.offset_left = -800
	sub.offset_right = 800
	sub.offset_top = -180
	sub.offset_bottom = -140
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate.a = 0.0
	add_child(sub)
	Sfx.play("special", -3.0, 0.8 if mine else 0.65)
	Sfx.play("charge", -8.0)
	var tw := create_tween().set_parallel()
	_art.scale = Vector2(1.5, 1.5)
	tw.tween_property(_art, "modulate:a", 1.0, 0.22).set_delay(0.3)
	tw.tween_property(_art, "scale", Vector2.ONE, 0.45).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(name_l, "modulate:a", 1.0, 0.2).set_delay(0.6)
	tw.tween_property(sub, "modulate:a", 1.0, 0.2).set_delay(0.75)
	var hit := create_tween()
	hit.tween_interval(0.62)
	hit.tween_callback(Sfx.play.bind("impact", -5.0))       # (goes with this node, no loose timer)
	print("SHOW ", nm)
	var out := create_tween()
	out.tween_interval(_dur - 0.3 + dev_hold)
	out.tween_property(self, "_fade", 0.0, 0.3)
	out.tween_callback(queue_free)


var _fade := 1.0:
	set(v):
		_fade = v
		for c in get_children():
			if c is CanvasItem and c != _pad:
				(c as CanvasItem).modulate.a = minf((c as CanvasItem).modulate.a, v)


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_pad):
		_pad.queue_redraw()


func _paint() -> void:
	var sz := _pad.size
	if sz.x < 8.0 or sz.y < 8.0:
		return      # (not laid out yet)
	var c := sz / 2.0 + Vector2(0, -25)
	var k := clampf(_t / 0.5, 0.0, 1.0)
	var f := _fade
	if _strike:
		# A slanted band in the card's colors, with speed lines running the way it attacks.
		var kb := clampf(_t / 0.15, 0.0, 1.0)
		var half := 205.0 * kb
		if half < 2.0:
			return      # (a band with no height yet is not a shape that can be drawn)
		var band := PackedVector2Array([Vector2(0, c.y - half + 60.0), Vector2(sz.x, c.y - half - 60.0), Vector2(sz.x, c.y + half - 60.0), Vector2(0, c.y + half + 60.0)])
		_pad.draw_colored_polygon(band, Color(_b.darkened(0.7), 0.88 * f))
		_pad.draw_line(band[0], band[1], Color(_a, f), 5.0)
		_pad.draw_line(band[3], band[2], Color(_a, f), 5.0)
		for i in 26:
			var sd0: Array = _seeds[i]
			var ly := c.y + (float(sd0[0]) - 0.5) * 2.0 * (half - 30.0)
			var lx := fmod(float(sd0[1]) * sz.x + _t * (2600.0 + 1800.0 * float(sd0[2])) * _dir, sz.x + 500.0)
			if lx < 0.0:
				lx += sz.x + 500.0
			lx -= 250.0
			var slope := -120.0 / sz.x
			_pad.draw_line(Vector2(lx, ly + (lx - sz.x * 0.5) * slope), Vector2(lx + (160.0 + 300.0 * float(sd0[3])) * _dir, ly + (lx + 300.0 * _dir - sz.x * 0.5) * slope), Color(_a if i % 3 else _b.lightened(0.5), 0.55 * f), 3.0 + 3.0 * float(sd0[2]))
		return
	# The world goes dark, in the card's own color.
	_pad.draw_rect(Rect2(Vector2.ZERO, sz), Color(_a.lerp(_b, 0.3).darkened(0.88), 0.86 * k * f))
	# A burst behind the card at the moment it lands.
	var hit := clampf((_t - 0.55) / 0.5, 0.0, 1.0)
	if hit > 0.0 and hit < 1.0:
		_pad.draw_arc(c, 120.0 + hit * 900.0, 0, TAU, 96, Color(_a, (1.0 - hit) * 0.9 * f), 14.0 * (1.0 - hit) + 2.0)
	var R := minf(sz.x, sz.y) * 0.36
	match _figure:
		"circle", "cards":
			for ring in 2:
				var rr := R * (1.0 if ring == 0 else 0.78)
				_pad.draw_arc(c, rr * k, 0, TAU, 96, Color(_a if ring == 0 else _b.lightened(0.3), 0.9 * f), 4.0)
			# A six-pointed star (two triangles) for magic, a five-pointed one for Lumen.
			var step := TAU / 3.0 if _figure == "circle" else TAU * 2.0 / 5.0
			var corners := 3 if _figure == "circle" else 5
			for tri in (2 if _figure == "circle" else 1):
				var pts := PackedVector2Array()
				for i in corners + 1:
					var ang := _t * 0.9 + float(i) * step + float(tri) * PI / 3.0
					pts.append(c + Vector2(cos(ang), sin(ang)) * R * 0.78 * k)
				_pad.draw_polyline(pts, Color(_a.lightened(0.3), 0.8 * f), 3.0)
			for i in 24:
				var a2 := -_t * 0.6 + float(i) * TAU / 24.0
				var p := c + Vector2(cos(a2), sin(a2)) * R * 0.89 * k
				if _figure == "cards" and i % 4 == 0:
					_pad.draw_rect(Rect2(p - Vector2(13, 19), Vector2(26, 38)), Color(_b if i % 8 == 0 else _a, 0.9 * f))
				else:
					_pad.draw_circle(p, 4.0, Color(_b.lightened(0.4), 0.9 * f))
		"rays":
			for i in 28:
				var a3 := float(i) * TAU / 28.0 + _t * 0.25
				var len0 := R * (0.5 + 1.6 * k) * (0.6 + 0.4 * float(_seeds[i][0]))
				_pad.draw_line(c + Vector2(cos(a3), sin(a3)) * 150.0, c + Vector2(cos(a3), sin(a3)) * (150.0 + len0), Color(_a if i % 2 == 0 else _b, 0.55 * f), 6.0 + 10.0 * float(_seeds[i][1]))
		"lightning":
			for i in 7:
				var x := sz.x * (0.12 + 0.76 * float(_seeds[i][0]))
				var on := fmod(_t * 6.0 + float(_seeds[i][1]) * 5.0, 1.0) < 0.55
				if not on:
					continue
				var pts2 := PackedVector2Array([Vector2(x, 0)])
				var y := 0.0
				var j := 0
				while y < sz.y * 0.85 and j < 24:
					y += 60.0 + 80.0 * float(_seeds[(i * 5 + j) % 40][2])
					x += (float(_seeds[(i * 3 + j) % 40][3]) - 0.5) * 190.0
					pts2.append(Vector2(x, y))
					j += 1
				_pad.draw_polyline(pts2, Color(_a, 0.95 * f), 5.0)
				_pad.draw_polyline(pts2, Color(_b, 0.5 * f), 12.0)
		"flames", "petals", "feathers":
			for i in 40:
				var sd: Array = _seeds[i]
				var life := fmod(_t * (0.5 + float(sd[2])) + float(sd[0]), 1.0)
				var px := sz.x * float(sd[1])
				var py := sz.y * (1.05 - life * 1.1) if _figure == "flames" else sz.y * (-0.05 + life * 1.1)
				var w := 26.0 + 40.0 * float(sd[3])
				px += sin(_t * 3.0 + float(i)) * 30.0
				var col := (_a if i % 2 == 0 else _b.lightened(0.2))
				var tri := PackedVector2Array([Vector2(px, py - w * 1.6), Vector2(px - w * 0.5, py), Vector2(px + w * 0.5, py)]) if _figure == "flames" else PackedVector2Array([Vector2(px, py - w * 0.7), Vector2(px - w * 0.3, py), Vector2(px, py + w * 0.7), Vector2(px + w * 0.3, py)])
				_pad.draw_colored_polygon(tri, Color(col, (1.0 - life) * 0.8 * k * f))
		"stars":
			for i in 40:
				var sd2: Array = _seeds[i]
				var a4 := float(sd2[0]) * TAU
				var dist := (0.15 + float(sd2[1])) * R * 2.2 * (0.3 + 0.7 * clampf(_t / 1.2, 0.0, 1.0))
				var p2 := c + Vector2(cos(a4), sin(a4)) * dist
				var tw2 := 0.5 + 0.5 * sin(_t * 9.0 + float(i))
				var s2 := (5.0 + 16.0 * float(sd2[2])) * tw2
				_pad.draw_line(p2 - Vector2(s2, 0), p2 + Vector2(s2, 0), Color(_a, f), 2.0)
				_pad.draw_line(p2 - Vector2(0, s2), p2 + Vector2(0, s2), Color(_b.lightened(0.5), f), 2.0)
		"galaxy":
			for i in 160:
				var u := float(i) / 160.0
				var a5 := u * TAU * 3.0 + _t * 1.2 + (PI if i % 2 == 0 else 0.0)
				var p3 := c + Vector2(cos(a5), sin(a5) * 0.55) * R * 2.5 * u * k
				_pad.draw_circle(p3, 3.0 + 8.0 * (1.0 - u), Color(_a.lerp(_b, u).lightened(0.25), 0.95 * f))
			for ring in 3:
				_pad.draw_circle(c, R * (0.75 - 0.2 * float(ring)) * k, Color(_a.lerp(_b, 0.5), 0.10 * f))
		"waves":
			for i in 6:
				var ph := fmod(_t * 0.7 + float(i) / 6.0, 1.0)
				_pad.draw_arc(c, R * 2.0 * ph, 0, TAU, 96, Color(_a.lerp(_b, ph), (1.0 - ph) * 0.9 * f), 8.0 * (1.0 - ph) + 1.0)
		"gears":
			for g in 3:
				var gc: Vector2 = c + Vector2(float([-R * 1.25, R * 1.25, 0.0][g]), float([R * 0.2, -R * 0.3, R * 0.05][g]))
				var gr: float = R * float([0.55, 0.45, 0.95][g]) * k
				var teeth: int = int([10, 8, 16][g])
				var spin := _t * (1.2 if g != 1 else -1.5) * (1.0 if g < 2 else 0.5)
				_pad.draw_arc(gc, gr, 0, TAU, 64, Color(_a if g % 2 == 0 else _b, 0.85 * f), 5.0)
				for tI in teeth:
					var a6 := spin + float(tI) * TAU / float(teeth)
					_pad.draw_line(gc + Vector2(cos(a6), sin(a6)) * gr, gc + Vector2(cos(a6), sin(a6)) * (gr + 20.0), Color(_a, 0.85 * f), 9.0)
		"streaks":
			for i in 30:
				var sd3: Array = _seeds[i]
				var y2 := sz.y * float(sd3[0])
				var x2 := fmod(float(sd3[1]) * sz.x + _t * (1400.0 + 900.0 * float(sd3[2])), sz.x + 600.0) - 300.0
				_pad.draw_line(Vector2(x2, y2), Vector2(x2 + 220.0 + 260.0 * float(sd3[3]), y2), Color(_a if i % 2 == 0 else _b, 0.6 * f), 4.0)
		"hex":
			for i in 40:
				var sd4: Array = _seeds[i]
				var hc := Vector2(sz.x * float(sd4[0]), sz.y * float(sd4[1]))
				var hr := 30.0 + 50.0 * float(sd4[2])
				var hp := PackedVector2Array()
				for j2 in 7:
					hp.append(hc + Vector2(cos(float(j2) * TAU / 6.0), sin(float(j2) * TAU / 6.0)) * hr * k)
				_pad.draw_polyline(hp, Color(_a if i % 2 == 0 else _b.lightened(0.3), (0.3 + 0.5 * absf(sin(_t * 2.0 + float(i)))) * f), 3.0)
