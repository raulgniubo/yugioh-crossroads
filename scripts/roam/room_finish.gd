class_name RoomFinish
## What makes a room look built instead of a painted box, for every room you can walk into in
## every world: a real floor (boards, or tiles), plastered walls, panelling under the rail (the
## old rooms) or flat piers along the walls (the modern ones), beams or coffers on the ceiling,
## rounded corners, a skirting board and a cornice. All the small pieces go into one mesh for
## the room (CityBuilder.BoxBatch), so a finished room draws in two or three more calls.

## Rooms with a boarded floor and panelled walls. The rest are tiled, with piers.
const WOOD := ["home", "dorm_red", "dorm_yellow", "dorm_blue", "ac_library", "ac_class", "sat_shack", "ac_hall"]
## Rooms that already have their own skirting and cornice (MoreRooms.spruce).
const SPRUCED := ["burger", "arcade", "kc_lobby", "dorm_red", "dorm_yellow", "dorm_blue", "ac_hall"]


static func wooden(key: String) -> bool:
	return key in WOOD or key.contains("_room_")


## The floor of a room: boards or tiles in the room's own color.
static func floor_material(city: CityBuilder, key: String, col: Color) -> Material:
	if wooden(key):
		return city.surf("wood", col, 0.8)
	return city._tile_material(col, 0.9 if key != "kc_lobby" else 1.5)


## The walls: plaster with a little relief the lights pick out.
static func wall_material(city: CityBuilder, col: Color) -> Material:
	return city.surf("plaster", col, 1.0)


static func apply(city: CityBuilder, key: String, r: Dictionary, o: Vector3, half: Vector2, hgt: float) -> void:
	var batch := CityBuilder.BoxBatch.new()
	var wall_c: Color = r["wall"]
	var wood := wooden(key)
	var dark := city.mat(Color(0.14, 0.15, 0.19) if not wood else Color(0.3, 0.2, 0.13), 0.6, 0.0)
	var panel := city.mat(wall_c.darkened(0.16) if not wood else wall_c.darkened(0.3).lerp(Color(0.42, 0.28, 0.18), 0.45), 0.8)
	var rail := city.mat(wall_c.darkened(0.34) if not wood else Color(0.32, 0.21, 0.14), 0.7)
	var pale := city.mat(wall_c.lightened(0.12), 0.8)
	# The four walls: [the way into the room, along the wall, how far out it stands, half its length]
	var walls := [[Vector3(0, 0, 1), Vector3(1, 0, 0), half.y, half.x], [Vector3(0, 0, -1), Vector3(1, 0, 0), half.y, half.x],
			[Vector3(1, 0, 0), Vector3(0, 0, 1), half.x, half.y], [Vector3(-1, 0, 0), Vector3(0, 0, 1), half.x, half.y]]
	for wi in walls.size():
		var inw: Vector3 = walls[wi][0]
		var t: Vector3 = walls[wi][1]
		var out: float = walls[wi][2]
		var hl: float = walls[wi][3]
		var basis := Basis(t, Vector3.UP, inw) if t.cross(Vector3.UP).dot(inw) > 0.0 else Basis(-t, Vector3.UP, inw)
		var face := o - inw * out           # a point on the wall's face, in the middle of it
		var door_wall := wi == 1            # (the way out is in the middle of the +Z wall)
		if not key in SPRUCED:
			batch.add(Vector3(hl * 2.0, 0.16, 0.05), face + Vector3(0, 0.08, 0) + inw * 0.025, dark, basis)
			batch.add(Vector3(hl * 2.0, 0.13, 0.13), face + Vector3(0, hgt - 0.065, 0) + inw * 0.065, dark, basis)
		if wood:
			# Panelling under the rail: a board every 1.1 m with a narrow gap between, and a cap on top.
			var n := maxi(2, int(round(hl * 2.0 / 1.1)))
			var w := hl * 2.0 / n
			for i in n:
				var u := -hl + (i + 0.5) * w
				if door_wall and absf(u) < 1.7:
					continue
				batch.add(Vector3(w - 0.08, 0.68, 0.036), face + t * u + Vector3(0, 0.54, 0) + inw * 0.018, panel, basis)
				batch.add(Vector3(w - 0.34, 0.42, 0.05), face + t * u + Vector3(0, 0.54, 0) + inw * 0.025, rail, basis)
			for sd: float in ([-1.0, 1.0] if door_wall else [0.0]):
				var seg := hl * 2.0 if not door_wall else hl - 1.7
				var mid := 0.0 if not door_wall else sd * (1.7 + seg * 0.5)
				batch.add(Vector3(seg, 0.07, 0.09), face + t * mid + Vector3(0, 0.9, 0) + inw * 0.045, rail, basis)
		else:
			# Flat piers along the wall from floor to ceiling, with a foot and a head.
			var n2 := maxi(2, int(round(hl * 2.0 / 3.4)))
			for i in n2 + 1:
				var u2 := -hl + 0.22 + (hl * 2.0 - 0.44) * i / float(n2)
				if door_wall and absf(u2) < 1.9:
					continue
				batch.add(Vector3(0.36, hgt - 0.3, 0.07), face + t * u2 + Vector3(0, hgt * 0.5, 0) + inw * 0.035, pale, basis)
				batch.add(Vector3(0.46, 0.2, 0.1), face + t * u2 + Vector3(0, 0.26, 0) + inw * 0.05, rail, basis)
				batch.add(Vector3(0.46, 0.14, 0.1), face + t * u2 + Vector3(0, hgt - 0.22, 0) + inw * 0.05, rail, basis)
	# The ceiling: beams across the room (wood), or a grid of shallow coffers (the rest). They
	# stay clear of where the lamps hang.
	var lamp_z := [-half.y * 0.4, half.y * 0.45]
	var count := maxi(2, int(round(half.y * 2.0 / 2.3)))
	for i in count + 1:
		var z := -half.y + 0.2 + (half.y * 2.0 - 0.4) * i / float(count)
		var clear := true
		for lz in lamp_z:
			if absf(z - float(lz)) < 0.5:
				clear = false
		if not clear:
			continue
		batch.add(Vector3(half.x * 2.0, 0.2 if wood else 0.1, 0.22 if wood else 0.3), o + Vector3(0, hgt - (0.1 if wood else 0.05), z), rail if wood else pale)
	if not wood:
		var cols := maxi(2, int(round(half.x * 2.0 / 3.0)))
		for i in range(1, cols):
			var x := -half.x + half.x * 2.0 * i / float(cols)
			if absf(absf(x) - half.x * 0.5) < 1.0 or absf(x) < 1.0:
				continue
			batch.add(Vector3(0.3, 0.09, half.y * 2.0), o + Vector3(x, hgt - 0.045, 0), pale)
	batch.commit(city, 70.0)
	# The corners of the room are round, not a knife edge: a quarter column in each.
	var col_m := city.mat(wall_c.lightened(0.06), 0.85)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := city.cyl(0.2, 0.2, hgt, o + Vector3(sx * (half.x - 0.02), hgt * 0.5, sz * (half.y - 0.02)), col_m, null, 12)
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## One thing on a shop shelf, standing at `at` (the shelf board under it) and facing `side` along
## X: a box with a paler label band, a bottle with a neck and a cap, a pair of tins, or a flat
## pack lying down. The colors are the shop's own. Everything goes into `batch`.
static func goods(batch: CityBuilder.BoxBatch, city: CityBuilder, at: Vector3, side: float, rng: RandomNumberGenerator, cols: Array, tint: Array = []) -> void:
	var c: Color = cols[rng.randi() % cols.size()]
	var c2: Color = cols[rng.randi() % cols.size()]
	if tint.size() == 2:
		c = c.lerp(tint[0], float(tint[1]))
		c2 = c2.lerp(tint[0], float(tint[1]))
	var body := _paint(city, c)
	var label := _paint(city, c.lerp(Color.WHITE, 0.62))
	var cap := _paint(city, c2.darkened(0.15))
	var face := Vector3(side * 0.101, 0, 0)
	match rng.randi() % 5:
		0, 1:
			# A box: its label on the front, a darker lid.
			var hh := rng.randf_range(0.17, 0.3)
			var dd := rng.randf_range(0.22, 0.32)
			batch.add(Vector3(0.2, hh, dd), at + Vector3(0, hh * 0.5, 0), body)
			batch.add(Vector3(0.006, hh * 0.42, dd * 0.7), at + Vector3(0, hh * 0.5, 0) + face, label)
			batch.add(Vector3(0.204, 0.025, dd + 0.004), at + Vector3(0, hh - 0.012, 0), cap)
		2:
			# Two bottles side by side: shoulders, a neck and a cap, a label round the middle.
			for bz: float in [-0.08, 0.08]:
				var bh := rng.randf_range(0.2, 0.26)
				batch.add(Vector3(0.1, bh, 0.1), at + Vector3(0, bh * 0.5, bz), body)
				batch.add(Vector3(0.075, 0.03, 0.075), at + Vector3(0, bh + 0.015, bz), body)
				batch.add(Vector3(0.042, 0.06, 0.042), at + Vector3(0, bh + 0.06, bz), body)
				batch.add(Vector3(0.05, 0.022, 0.05), at + Vector3(0, bh + 0.1, bz), cap)
				batch.add(Vector3(0.104, bh * 0.36, 0.104), at + Vector3(0, bh * 0.5, bz), label)
		3:
			# Tins, stacked two high, with a band.
			for ty in 2:
				for bz: float in [-0.085, 0.085]:
					batch.add(Vector3(0.13, 0.11, 0.13), at + Vector3(0, 0.055 + ty * 0.112, bz), cap, Basis(Vector3.UP, 0.785))
					batch.add(Vector3(0.134, 0.05, 0.134), at + Vector3(0, 0.055 + ty * 0.112, bz), label, Basis(Vector3.UP, 0.785))
		_:
			# Flat packs lying in a small pile, each a little askew.
			for k in rng.randi_range(2, 4):
				batch.add(Vector3(0.19, 0.045, 0.27), at + Vector3(0, 0.023 + k * 0.047, 0), body if k % 2 == 0 else cap, Basis(Vector3.UP, rng.randf_range(-0.18, 0.18)))
				batch.add(Vector3(0.006, 0.02, 0.16), at + Vector3(0, 0.023 + k * 0.047, 0) + face * 0.96, label)


static var _paints := {}


## One paint per color for a whole shop's goods (they all share one material in the end anyway).
static func _paint(city: CityBuilder, c: Color) -> Material:
	var key := c.to_html()
	if not _paints.has(key) or not is_instance_valid(_paints[key]):
		_paints[key] = city.mat(c, 0.7)
	return _paints[key]
