class_name MoreRooms
## More places to walk into: your own room and a corner store in Domino City, and the library
## on Academy Island. Each has something to do, not just someone to talk to.

const ROOMS := {
	"home": {"name": "Your Room", "area": "Crossroads Apartments, second floor", "at": Vector3(720, 0, 400), "half": Vector2(5.0, 4.2), "height": 3.2,
		"door": Vector3(-25, 0, 18.3), "out": Vector3(0, 0, -1), "label": "Go up to your room", "music": "shop",
		"floor": Color(0.6, 0.46, 0.32), "wall": Color(0.9, 0.88, 0.82), "trim": Color("7cc4ff")},
	"mart": {"name": "Domino Mart", "area": "Open all night", "at": Vector3(800, 0, 400), "half": Vector2(7.0, 5.0), "height": 3.6,
		"door": Vector3(-24, 0, -9.1), "out": Vector3(0, 0, 1), "label": "Enter Domino Mart", "music": "shop",
		"floor": Color(0.82, 0.85, 0.88), "wall": Color(0.95, 0.97, 0.98), "trim": Color("3fbf8a")},
	"ac_library": {"district": "academy", "name": "Academy Library", "area": "Strategy books and the duel quiz", "at": Vector3(720, 0, -400), "half": Vector2(9.0, 7.0), "height": 5.6,
		"door": Vector3(-19.0, 0, 28.5), "out": Vector3(1, 0, 0), "label": "Enter the library", "music": "shop",
		"floor": Color(0.38, 0.25, 0.16), "wall": Color(0.88, 0.82, 0.7), "trim": Color("ffd166")},
}
const PEOPLE := {
	"mart": [
		{"id": "mart_clerk", "char": "", "model": "office_worker", "name": "Night Clerk", "color": Color("3fbf8a"), "pos": Vector3(4.2, 0, -3.3), "face": -0.6,
			"lines": ["Welcome to Domino Mart. The lucky draw by the door is free once a day.", "Duelists come in at 3 a.m. for sleeves and instant noodles. Every night."]},
		{"id": "mart_kid", "char": "kid", "name": "Snack Duelist", "pos": Vector3(-3.6, 0, 1.6), "face": 1.4,
			"lines": ["I spent my lunch money on packs again. Worth it.", "Duel me! If I win you buy me a melon bread."],
			"duel": {"deck": "weevil", "difficulty": 1, "intro": "Melon bread is on the line!"}},
		{"id": "mart_lady", "char": "", "model": "stylish_woman", "name": "Late Shopper", "color": Color("ff8ac0"), "pos": Vector3(-4.8, 0, -2.4), "face": 2.6,
			"lines": ["They restock the card rack on Fridays. Don't tell anyone.", "Somebody keeps winning the lucky draw. I think it's the cat."]},
	],
	"ac_library": [
		{"id": "lib_keeper", "char": "", "model": "stylish_woman", "name": "Librarian", "color": Color("ffd166"), "pos": Vector3(0, 0, -4.4), "face": 0.0,
			"lines": ["Welcome. Voices down, decks out. The quiz desk on your left pays Duel Points for right answers.", "Every strategy book here was written by someone who lost first."]},
		{"id": "lib_reader", "char": "", "model": "student_girl", "name": "Top Student", "color": Color("7cc4ff"), "pos": Vector3(5.6, 0, 1.2), "face": -1.5, "dorm": "blue",
			"lines": ["Set your Traps before you attack, not after. You'd be surprised how many people forget.", "Count their face-down cards before every Battle Phase."]},
		{"id": "lib_worm", "char": "", "model": "student_boy", "name": "Bookworm", "color": Color("ffd166"), "pos": Vector3(-5.8, 0, 2.2), "face": 1.5, "dorm": "yellow",
			"lines": ["I've read every book on this shelf. Theory only goes so far, though.", "Let me test chapter twelve on you."],
			"duel": {"deck": "syrus", "difficulty": 2, "intro": "Chapter twelve: applied dueling!"}},
	],
}
const TIPS := ["A face-down monster in Defense is safer than a weak one in Attack.", "Hold your removal for their best monster, not their first.",
	"If your hand is empty, the duel is deciding itself without you. Keep cards.", "Tribute the monster they are about to destroy anyway.",
	"A Trap you never use still made them play around it.", "Direct attacks win duels. Clear the way first."]


static func dress(city: CityBuilder, key: String, o: Vector3, half: Vector2, hgt: float) -> void:
	match key:
		"home": _home(city, o, half, hgt)
		"mart": _mart(city, o, half, hgt)
		"ac_library": _library(city, o, half, hgt)


static func _sign(city: CityBuilder, text: String, pos: Vector3, rot: float, color: Color, size: int) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	l.font_size = size
	l.outline_size = 0
	l.modulate = color * 1.6
	l.shaded = false
	l.position = pos
	l.rotation.y = rot
	city.add_child(l)


static func _window(city: CityBuilder, at: Vector3, w: float, h: float, along_x: bool, sky := Color(0.6, 0.82, 1.0)) -> void:
	var fr := city.mat(Color(0.95, 0.95, 0.95), 0.5)
	var size := Vector3(w + 0.2, h + 0.2, 0.08) if along_x else Vector3(0.08, h + 0.2, w + 0.2)
	city.box(size, at, fr, false)
	var gl := Vector3(w, h, 0.1) if along_x else Vector3(0.1, h, w)
	city.box(gl, at, city.glow_mat(sky, 1.3), false)
	var bar := Vector3(0.06, h, 0.12) if along_x else Vector3(0.12, h, 0.06)
	city.box(bar, at, fr, false)
	var bar2 := Vector3(w, 0.06, 0.12) if along_x else Vector3(0.12, 0.06, w)
	city.box(bar2, at, fr, false)


static func _home(city: CityBuilder, o: Vector3, half: Vector2, hgt: float) -> void:
	var wood := city.mat(Color(0.45, 0.3, 0.18), 0.6)
	var white := city.mat(Color(0.93, 0.93, 0.95), 0.7)
	var dark := city.mat(Color(0.12, 0.13, 0.17), 0.5, 0.3)
	# A rug in the middle.
	city.box(Vector3(4.2, 0.03, 2.8), o + Vector3(0, 0.02, 0.4), city.mat(Color(0.16, 0.42, 0.5), 0.95), false)
	city.box(Vector3(3.6, 0.035, 2.2), o + Vector3(0, 0.02, 0.4), city.mat(Color(0.86, 0.9, 0.9), 0.95), false)
	# Bed along the left wall, with a blanket in your colors.
	var bx := -half.x + 1.15
	city.box(Vector3(2.0, 0.42, 3.2), o + Vector3(bx, 0.21, -half.y + 1.8), wood)
	city.box(Vector3(1.9, 0.22, 3.1), o + Vector3(bx, 0.52, -half.y + 1.8), white, false)
	city.box(Vector3(1.92, 0.24, 2.0), o + Vector3(bx, 0.54, -half.y + 2.35), city.mat(Color(0.12, 0.62, 0.66), 0.9), false)
	city.box(Vector3(1.2, 0.16, 0.6), o + Vector3(bx, 0.7, -half.y + 0.6), white, false)
	city.box(Vector3(2.1, 1.0, 0.14), o + Vector3(bx, 0.5, -half.y + 0.14), wood, false)
	# Desk under the window: a deck box, a lamp, a playmat with cards laid out.
	var dx := 1.2
	city.box(Vector3(2.6, 0.08, 1.0), o + Vector3(dx, 0.82, -half.y + 0.62), wood)
	for lx: float in [-1.2, 1.2]:
		city.box(Vector3(0.08, 0.8, 0.9), o + Vector3(dx + lx, 0.4, -half.y + 0.62), wood, false)
	city.box(Vector3(1.5, 0.012, 0.7), o + Vector3(dx, 0.867, -half.y + 0.6), city.mat(Color(0.08, 0.2, 0.34), 0.9), false)
	for k in 5:
		var card := Sprite3D.new()
		card.texture = Cards.get_back()
		card.pixel_size = 0.22 / maxf(1.0, card.texture.get_height())
		card.rotation.x = -PI / 2.0
		card.shaded = false
		card.position = o + Vector3(dx - 0.52 + k * 0.26, 0.876, -half.y + 0.6)
		city.add_child(card)
	city.box(Vector3(0.24, 0.16, 0.34), o + Vector3(dx + 1.0, 0.94, -half.y + 0.5), city.mat(Color(0.14, 0.5, 0.86), 0.4, 0.3), false)
	city.cyl(0.03, 0.07, 0.5, o + Vector3(dx - 1.05, 1.1, -half.y + 0.4), dark, null, 8)
	city.cyl(0.16, 0.08, 0.16, o + Vector3(dx - 1.05, 1.4, -half.y + 0.4), city.glow_mat(Color(1.0, 0.9, 0.7), 2.2), null, 10)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.86, 0.66)
	lamp.light_energy = 1.6
	lamp.omni_range = 4.5
	lamp.position = o + Vector3(dx - 1.05, 1.5, -half.y + 0.7)
	city.add_child(lamp)
	# Chair.
	city.box(Vector3(0.5, 0.06, 0.5), o + Vector3(dx, 0.48, -half.y + 1.5), dark, false)
	city.box(Vector3(0.5, 0.6, 0.06), o + Vector3(dx, 0.8, -half.y + 1.74), dark, false)
	city.cyl(0.04, 0.04, 0.46, o + Vector3(dx, 0.23, -half.y + 1.5), dark, null, 8)
	_window(city, o + Vector3(dx, 1.95, -half.y + 0.03), 2.2, 1.2, true)
	# Trophy shelf on the right wall: cups, a framed card, a little city model.
	var sx := half.x - 0.32
	for k in 3:
		city.box(Vector3(0.5, 0.06, 2.6), o + Vector3(sx, 0.7 + k * 0.62, 0.2), wood, false)
	city.box(Vector3(0.5, 2.1, 0.08), o + Vector3(sx, 1.05, -1.1), wood, false)
	city.box(Vector3(0.5, 2.1, 0.08), o + Vector3(sx, 1.05, 1.5), wood, false)
	var gold := city.mat(Color(0.95, 0.78, 0.3), 0.25, 0.9)
	for k in 3:
		var cz := -0.6 + k * 0.7
		city.cyl(0.11, 0.05, 0.2, o + Vector3(sx, 1.46, cz), gold, null, 10)
		city.cyl(0.03, 0.03, 0.1, o + Vector3(sx, 1.4, cz), gold, null, 8)
		city.box(Vector3(0.14, 0.04, 0.14), o + Vector3(sx, 1.36, cz), dark, false)
	for k in 6:
		city.box(Vector3(0.3, 0.3 + (k % 3) * 0.05, 0.09), o + Vector3(sx, 0.9, -0.9 + k * 0.12), city.mat([Color("d9342b"), Color("2a6cff"), Color("f0c040"), Color("3fbf8a")][k % 4], 0.8), false)
	city.box(Vector3(0.05, 0.6, 0.44), o + Vector3(sx + 0.2, 2.25, 0.2), gold, false)
	var framed := Sprite3D.new()
	framed.texture = Cards.get_back()
	framed.pixel_size = 0.52 / maxf(1.0, framed.texture.get_height())
	framed.rotation.y = -PI / 2.0
	framed.shaded = false
	framed.position = o + Vector3(sx + 0.16, 2.25, 0.2)
	city.add_child(framed)
	# A small TV and a beanbag by the door wall, posters, a plant.
	city.box(Vector3(1.5, 0.5, 0.45), o + Vector3(-1.6, 0.25, half.y - 0.4), dark)
	city.box(Vector3(1.3, 0.75, 0.06), o + Vector3(-1.6, 0.95, half.y - 0.36), dark, false)
	city.box(Vector3(1.2, 0.65, 0.02), o + Vector3(-1.6, 0.95, half.y - 0.4), city.glow_mat(Color(0.3, 0.6, 1.0), 1.0), false)
	var bag := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 0.7
	bag.mesh = sm
	bag.material_override = city.mat(Color(0.86, 0.36, 0.3), 0.95)
	bag.position = o + Vector3(-2.0, 0.3, 1.2)
	city.add_child(bag)
	for k in 2:
		city.box(Vector3(0.03, 1.0, 0.72), o + Vector3(-half.x + 0.03, 2.0, 1.6 + k * 1.0), city.glow_mat([Color("2de2e6"), Color("ff8a3a")][k], 0.5), false)
	city.cyl(0.2, 0.15, 0.36, o + Vector3(half.x - 0.5, 0.18, half.y - 0.6), city.mat(Color(0.8, 0.5, 0.36), 0.8), null, 10)
	var leaf := MeshInstance3D.new()
	var ls := SphereMesh.new()
	ls.radius = 0.36
	ls.height = 0.8
	leaf.mesh = ls
	leaf.material_override = city.mat(Color(0.18, 0.5, 0.24), 0.9)
	leaf.position = o + Vector3(half.x - 0.5, 0.8, half.y - 0.6)
	city.add_child(leaf)
	_sign(city, "HOME", o + Vector3(-2.6, 2.6, -half.y + 0.12), 0.0, Color("7cc4ff"), 90)


static func _mart(city: CityBuilder, o: Vector3, half: Vector2, hgt: float) -> void:
	var white := city.mat(Color(0.94, 0.95, 0.97), 0.5)
	var steel := city.mat(Color(0.7, 0.72, 0.76), 0.35, 0.6)
	var cols := [Color("d9342b"), Color("f0c040"), Color("3f7be0"), Color("3fbf8a"), Color("f28c38"), Color("c85ad0"), Color("f2f2ee")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	_sign(city, "DOMINO MART", o + Vector3(0, hgt - 0.5, -half.y + 0.12), 0.0, Color("3fbf8a"), 130)
	# Green and orange stripes round the walls.
	for sz: float in [-1.0, 1.0]:
		city.box(Vector3(half.x * 2, 0.16, 0.05), o + Vector3(0, hgt - 1.0, sz * (half.y - 0.03)), city.glow_mat(Color("3fbf8a"), 0.8), false)
		city.box(Vector3(half.x * 2, 0.08, 0.05), o + Vector3(0, hgt - 1.16, sz * (half.y - 0.03)), city.glow_mat(Color("f28c38"), 0.8), false)
	# Two aisles of shelves stocked with boxes.
	for ax: float in [-2.6, 0.2]:
		city.box(Vector3(0.5, 1.7, 5.0), o + Vector3(ax, 0.85, 0.2), white)
		for lvl in 4:
			city.box(Vector3(1.0, 0.04, 5.0), o + Vector3(ax, 0.3 + lvl * 0.42, 0.2), steel, false)
			for k in 12:
				for side: float in [-1.0, 1.0]:
					var hh := rng.randf_range(0.16, 0.32)
					city.box(Vector3(0.2, hh, 0.3), o + Vector3(ax + side * 0.36, 0.32 + lvl * 0.42 + hh / 2.0, -2.1 + k * 0.4), city.mat(cols[rng.randi() % cols.size()], 0.7), false)
	# Drink fridges glowing along the left wall.
	for k in 4:
		var fz := -3.4 + k * 1.5
		city.box(Vector3(0.7, 2.2, 1.4), o + Vector3(-half.x + 0.4, 1.1, fz), steel)
		city.box(Vector3(0.04, 1.9, 1.2), o + Vector3(-half.x + 0.77, 1.15, fz), city.glow_mat(Color(0.75, 0.92, 1.0), 1.4), false)
		for r in 4:
			for c in 5:
				city.cyl(0.05, 0.05, 0.22, o + Vector3(-half.x + 0.82, 0.42 + r * 0.46, fz - 0.44 + c * 0.22), city.mat(cols[(r * 3 + c + k) % cols.size()], 0.4, 0.3), null, 6)
	# Counter with a register, a hot-food case and the card rack behind it.
	city.box(Vector3(3.6, 1.0, 0.9), o + Vector3(4.6, 0.5, -2.4), white)
	city.box(Vector3(3.7, 0.06, 1.0), o + Vector3(4.6, 1.03, -2.4), city.mat(Color(0.2, 0.5, 0.36), 0.4), false)
	city.box(Vector3(0.5, 0.36, 0.44), o + Vector3(5.6, 1.24, -2.4), city.mat(Color(0.14, 0.15, 0.19), 0.4, 0.4), false)
	city.box(Vector3(0.44, 0.26, 0.04), o + Vector3(5.6, 1.52, -2.52), city.glow_mat(Color(0.5, 1.0, 0.7), 1.0), false)
	city.box(Vector3(0.9, 0.5, 0.6), o + Vector3(3.6, 1.3, -2.4), city.glow_mat(Color(1.0, 0.75, 0.4), 0.7), false)
	city.box(Vector3(3.0, 1.6, 0.2), o + Vector3(4.6, 1.5, -half.y + 0.12), white, false)
	for k in 12:
		var pk := Sprite3D.new()
		pk.texture = Cards.get_back()
		pk.pixel_size = 0.3 / maxf(1.0, pk.texture.get_height())
		pk.shaded = false
		pk.position = o + Vector3(3.35 + (k % 6) * 0.5, 1.2 + (k / 6) * 0.5, -half.y + 0.24)
		city.add_child(pk)
	# The lucky draw machine by the door.
	var lx := half.x - 1.0
	city.box(Vector3(0.9, 1.3, 0.8), o + Vector3(lx, 0.65, half.y - 1.6), city.mat(Color(0.86, 0.2, 0.24), 0.4, 0.2))
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.42
	dm.height = 0.84
	dome.mesh = dm
	var glass := city.mat(Color(0.8, 0.95, 1.0, 0.35), 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dome.material_override = glass
	dome.position = o + Vector3(lx, 1.62, half.y - 1.6)
	city.add_child(dome)
	for k in 9:
		var cap := MeshInstance3D.new()
		var cs := SphereMesh.new()
		cs.radius = 0.09
		cs.height = 0.18
		cap.mesh = cs
		cap.material_override = city.mat(cols[k % cols.size()], 0.4)
		cap.position = o + Vector3(lx + rng.randf_range(-0.22, 0.22), 1.42 + rng.randf_range(0.0, 0.28), half.y - 1.6 + rng.randf_range(-0.22, 0.22))
		city.add_child(cap)
	_sign(city, "LUCKY DRAW", o + Vector3(lx, 2.3, half.y - 1.6), -0.5, Color("ffd166"), 60)
	# Magazine rack under the front window.
	_window(city, o + Vector3(-2.0, 1.8, half.y - 0.03), 4.5, 1.5, true, Color(0.16, 0.2, 0.4))
	city.box(Vector3(4.4, 0.9, 0.4), o + Vector3(-2.0, 0.45, half.y - 0.4), white)
	for k in 10:
		city.box(Vector3(0.36, 0.5, 0.04), o + Vector3(-4.0 + k * 0.44, 1.1, half.y - 0.42), city.mat(cols[k % cols.size()], 0.7), false).rotation.x = 0.25


static func _library(city: CityBuilder, o: Vector3, half: Vector2, hgt: float) -> void:
	var wood := city.mat(Color(0.34, 0.2, 0.11), 0.6)
	var wood2 := city.mat(Color(0.5, 0.32, 0.18), 0.55)
	var brass := city.mat(Color(0.86, 0.68, 0.3), 0.3, 0.8)
	var cols := [Color("7a1f1f"), Color("1f3f7a"), Color("2f6b3a"), Color("8a6a1f"), Color("4a2a6a"), Color("d8cfc0"), Color("202a38")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	_sign(city, "ACADEMY LIBRARY", o + Vector3(0, hgt - 0.7, -half.y + 0.12), 0.0, Color("ffd166"), 120)
	# A long red runner from the door to the desk.
	city.box(Vector3(2.2, 0.03, half.y * 2 - 1.5), o + Vector3(0, 0.02, 0.4), city.mat(Color(0.5, 0.1, 0.12), 0.95), false)
	# Tall shelves on both side walls and four free-standing rows, all full of books.
	var rows: Array = []
	for sx: float in [-1.0, 1.0]:
		rows.append([Vector3(sx * (half.x - 0.35), 0, 0), Vector3(0.6, 4.2, half.y * 2 - 2.0), true])
		for k in 2:
			rows.append([Vector3(sx * 4.4, 0, -3.4 + k * 3.6), Vector3(3.4, 2.6, 0.7), false])
	for r in rows:
		var c: Vector3 = r[0]
		var sz: Vector3 = r[1]
		city.box(sz, o + c + Vector3(0, sz.y / 2.0, 0), wood)
		var along_z: bool = r[2]
		var length := sz.z if along_z else sz.x
		var n := int(length / 0.16)
		var levels := int(sz.y / 0.52)
		for lvl in levels:
			for k in n:
				if rng.randf() < 0.08:
					continue
				var bh := rng.randf_range(0.3, 0.44)
				var t := -length / 2.0 + 0.1 + k * 0.16
				var y := 0.14 + lvl * 0.52 + bh / 2.0
				var bm := city.mat(cols[rng.randi() % cols.size()], 0.8)
				if along_z:
					var face := -signf(c.x)
					city.box(Vector3(0.06, bh, 0.13), o + c + Vector3(face * 0.3, y, t), bm, false)
				else:
					for face: float in [-1.0, 1.0]:
						city.box(Vector3(0.13, bh, 0.06), o + c + Vector3(t, y, face * 0.35), bm, false)
	# The librarian's desk at the far end, with a green lamp.
	city.box(Vector3(4.4, 1.05, 1.0), o + Vector3(0, 0.52, -half.y + 1.9), wood2)
	city.box(Vector3(4.6, 0.07, 1.2), o + Vector3(0, 1.08, -half.y + 1.9), wood, false)
	city.cyl(0.03, 0.08, 0.36, o + Vector3(-1.6, 1.3, -half.y + 1.9), brass, null, 8)
	city.box(Vector3(0.44, 0.1, 0.2), o + Vector3(-1.6, 1.5, -half.y + 1.9), city.glow_mat(Color(0.3, 0.9, 0.5), 1.4), false)
	# The quiz desk on the left: a lectern with a glowing question mark over it.
	var qx := -2.6
	city.box(Vector3(1.2, 1.1, 0.7), o + Vector3(qx, 0.55, 3.6), wood2)
	var top := city.box(Vector3(1.3, 0.06, 0.8), o + Vector3(qx, 1.16, 3.6), wood, false)
	top.rotation.x = 0.18
	_sign(city, "?", o + Vector3(qx, 2.2, 3.6), 0.0, Color("ffd166"), 200)
	_sign(city, "DUEL QUIZ", o + Vector3(qx, 1.62, 3.6), 0.0, Color("ffe9a8"), 44)
	# Two reading tables with lamps, chairs and open books.
	for tx: float in [-1.0, 1.0]:
		var tc := o + Vector3(tx * 4.6, 0, 1.6)
		city.box(Vector3(2.8, 0.08, 1.2), tc + Vector3(0, 0.76, 0), wood2)
		for lx: float in [-1.25, 1.25]:
			for lz: float in [-0.5, 0.5]:
				city.box(Vector3(0.08, 0.76, 0.08), tc + Vector3(lx, 0.38, lz), wood, false)
		city.cyl(0.03, 0.07, 0.34, tc + Vector3(0, 0.98, 0), brass, null, 8)
		city.box(Vector3(0.4, 0.09, 0.18), tc + Vector3(0, 1.17, 0), city.glow_mat(Color(0.3, 0.9, 0.5), 1.2), false)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.9, 0.7)
		l.light_energy = 1.2
		l.omni_range = 4.0
		l.position = tc + Vector3(0, 1.4, 0)
		city.add_child(l)
		for k in 2:
			city.box(Vector3(0.44, 0.03, 0.3), tc + Vector3(-0.8 + k * 1.6, 0.82, 0.2), city.mat(Color(0.93, 0.9, 0.82), 0.9), false)
			city.box(Vector3(0.44, 0.05, 0.44), tc + Vector3(-0.8 + k * 1.6, 0.46, 0.95), wood, false)
			city.box(Vector3(0.44, 0.5, 0.05), tc + Vector3(-0.8 + k * 1.6, 0.72, 1.16), wood, false)
	# Tall windows above the side shelves throw daylight across the room.
	for sx: float in [-1.0, 1.0]:
		for k in 3:
			_window(city, o + Vector3(sx * (half.x - 0.03), 4.7, -4.0 + k * 4.0), 1.6, 1.0, false)
	# A globe by the desk.
	city.cyl(0.05, 0.2, 0.9, o + Vector3(3.0, 0.45, -half.y + 2.4), brass, null, 10)
	var globe := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.38
	gm.height = 0.76
	globe.mesh = gm
	globe.material_override = city.mat(Color(0.2, 0.45, 0.7), 0.4)
	globe.position = o + Vector3(3.0, 1.2, -half.y + 2.4)
	city.add_child(globe)


## A second coat for the older rooms: daylight windows, wall art, ceiling fixtures, plants and
## floor detail. Everything goes on walls, corners and the ceiling, clear of the furniture.
static func spruce(city: CityBuilder, key: String, o: Vector3, half: Vector2, hgt: float, trim: Color) -> void:
	if not key in ["burger", "arcade", "kc_lobby", "dorm_red", "dorm_yellow", "dorm_blue", "ac_hall"]:
		return
	var dark := city.mat(Color(0.14, 0.15, 0.19), 0.6, 0.2)
	# Skirting board and a ceiling cornice all the way round.
	for sx: float in [-1.0, 1.0]:
		city.box(Vector3(0.06, 0.16, half.y * 2), o + Vector3(sx * (half.x - 0.03), 0.08, 0), dark, false)
		city.box(Vector3(0.14, 0.14, half.y * 2), o + Vector3(sx * (half.x - 0.07), hgt - 0.07, 0), dark, false)
	for sz: float in [-1.0, 1.0]:
		city.box(Vector3(half.x * 2, 0.16, 0.06), o + Vector3(0, 0.08, sz * (half.y - 0.03)), dark, false)
		city.box(Vector3(half.x * 2, 0.14, 0.14), o + Vector3(0, hgt - 0.07, sz * (half.y - 0.07)), dark, false)
	# Windows high on both side walls. Night-blue for the arcade, daylight everywhere else.
	var sky := Color(0.14, 0.12, 0.3) if key == "arcade" else Color(0.62, 0.84, 1.0)
	var wy := minf(hgt - 1.0, 2.6 if hgt < 5.0 else hgt * 0.62)
	var wh := 1.1 if hgt < 5.0 else 2.4
	var n := maxi(2, int(half.y / 2.2))
	for sx: float in [-1.0, 1.0]:
		for k in n:
			var z := -half.y + (k + 0.5) * (half.y * 2.0 / n)
			_window(city, o + Vector3(sx * (half.x - 0.03), wy, z), 1.5, wh, false, sky)
			if key != "arcade":
				# A patch of light on the floor under each window.
				var pool := city.box(Vector3(1.8, 0.012, 1.5), o + Vector3(sx * (half.x - 1.6), 0.012, z), city.glow_mat(Color(1.0, 0.96, 0.82), 0.22), false)
				pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Framed pictures between the windows on the door wall.
	var frames := [Color("d9342b"), Color("2a6cff"), Color("f0c040"), Color("3fbf8a"), Color("c85ad0")]
	for k in 4:
		var fx := -half.x + 1.4 + k * ((half.x * 2.0 - 2.8) / 3.0)
		if absf(fx) < 1.8:
			continue
		city.box(Vector3(0.9, 0.7, 0.05), o + Vector3(fx, 1.9, half.y - 0.04), dark, false)
		city.box(Vector3(0.78, 0.58, 0.06), o + Vector3(fx, 1.9, half.y - 0.045), city.glow_mat(frames[(k + key.length()) % frames.size()].lerp(trim, 0.3), 0.35), false)
	# Potted plants in the two front corners.
	for sx: float in [-1.0, 1.0]:
		var pp := o + Vector3(sx * (half.x - 0.55), 0, half.y - 0.55)
		city.cyl(0.24, 0.18, 0.44, pp + Vector3(0, 0.22, 0), city.mat(Color(0.82, 0.8, 0.76), 0.7), null, 10)
		for b in 3:
			var leaf := MeshInstance3D.new()
			var ls := SphereMesh.new()
			ls.radius = 0.3 - b * 0.06
			ls.height = 0.7 - b * 0.1
			leaf.mesh = ls
			leaf.material_override = city.mat(Color(0.16, 0.46 + b * 0.06, 0.22), 0.9)
			leaf.position = pp + Vector3((b - 1) * 0.12, 0.75 + b * 0.22, (b % 2) * 0.1)
			city.add_child(leaf)
	match key:
		"burger":
			# Checkerboard strip down the middle, pendant lamps, a jukebox and an OPEN sign.
			for k in 14:
				for r in 2:
					if (k + r) % 2 == 0:
						city.box(Vector3(0.5, 0.012, 0.5), o + Vector3(-3.25 + k * 0.5, 0.013, 3.6 + r * 0.5), city.mat(Color(0.96, 0.94, 0.9), 0.5), false)
			for k in 4:
				var lx := -4.5 + k * 3.0
				city.cyl(0.015, 0.015, 0.9, o + Vector3(lx, hgt - 0.45, 1.2), dark, null, 6)
				city.cyl(0.08, 0.3, 0.26, o + Vector3(lx, hgt - 1.0, 1.2), city.mat(Color(0.86, 0.2, 0.16), 0.4, 0.3), null, 12)
				city.cyl(0.1, 0.1, 0.04, o + Vector3(lx, hgt - 1.13, 1.2), city.glow_mat(Color(1.0, 0.9, 0.7), 2.4), null, 10)
			var jb := o + Vector3(-half.x + 0.6, 0, -1.0)
			city.box(Vector3(0.7, 1.5, 0.9), jb + Vector3(0, 0.75, 0), city.mat(Color(0.5, 0.12, 0.14), 0.4, 0.3))
			city.box(Vector3(0.06, 0.6, 0.7), jb + Vector3(0.36, 1.05, 0), city.glow_mat(Color(1.0, 0.75, 0.3), 1.4), false)
			for k in 3:
				city.box(Vector3(0.07, 1.3, 0.06), jb + Vector3(0.37, 0.75, -0.36 + k * 0.36), city.glow_mat([Color("2de2e6"), Color("ff4fd8"), Color("ffd166")][k], 1.6), false)
			_sign(city, "OPEN", o + Vector3(half.x - 0.12, 2.9, 3.4), -PI / 2.0, Color("ff5a5a"), 70)
		"arcade":
			# Neon tubes across the ceiling, a starry carpet and a prize wall.
			for k in 5:
				city.box(Vector3(half.x * 1.7, 0.05, 0.05), o + Vector3(0, hgt - 0.2, -half.y + 1.5 + k * 2.3), city.glow_mat([Color("ff4fd8"), Color("2de2e6"), Color("ffd166"), Color("7dff6a"), Color("7c8cff")][k], 2.4), false)
			var rng := RandomNumberGenerator.new()
			rng.seed = 21
			for k in 46:
				var st := city.box(Vector3(0.16, 0.011, 0.16), o + Vector3(rng.randf_range(-half.x + 0.5, half.x - 0.5), 0.012, rng.randf_range(-half.y + 0.5, half.y - 0.5)),
					city.glow_mat([Color("ff4fd8"), Color("2de2e6"), Color("ffd166")][k % 3], 0.9), false)
				st.rotation.y = rng.randf() * PI
				st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var pw := o + Vector3(-half.x + 0.25, 0, 2.6)
			city.box(Vector3(0.4, 2.4, 3.0), pw + Vector3(0, 1.2, 0), dark)
			for r in 3:
				for c in 5:
					var toy := MeshInstance3D.new()
					var ts := SphereMesh.new()
					ts.radius = 0.16
					ts.height = 0.32
					toy.mesh = ts
					toy.material_override = city.mat([Color("ff8ac0"), Color("7cc4ff"), Color("ffd166"), Color("7dffb0"), Color("c85ad0")][(r + c) % 5], 0.6)
					toy.position = pw + Vector3(0.26, 0.5 + r * 0.7, -1.1 + c * 0.55)
					city.add_child(toy)
			_sign(city, "PRIZES", pw + Vector3(0.24, 2.7, 0), PI / 2.0, Color("ffd166"), 60)
		"kc_lobby":
			# Light lines in the floor leading to the desk, tall banners and a slow holo globe.
			for sx: float in [-1.0, 1.0]:
				city.box(Vector3(0.06, 0.012, half.y * 2 - 3.0), o + Vector3(sx * 1.6, 0.013, 0.6), city.glow_mat(Color("2a6cff"), 1.6), false)
				city.box(Vector3(1.1, 3.4, 0.04), o + Vector3(sx * 4.6, hgt - 2.0, -half.y + 0.1), city.glow_mat(Color("17306e"), 0.6), false)
				city.box(Vector3(0.7, 0.7, 0.05), o + Vector3(sx * 4.6, hgt - 1.2, -half.y + 0.13), city.glow_mat(Color("7cc4ff"), 1.4), false)
				# Waiting benches along the side walls.
				city.box(Vector3(0.6, 0.12, 2.6), o + Vector3(sx * (half.x - 0.7), 0.46, 2.4), city.mat(Color(0.9, 0.92, 0.96), 0.4))
				for lz: float in [-1.1, 1.1]:
					city.box(Vector3(0.5, 0.42, 0.1), o + Vector3(sx * (half.x - 0.7), 0.21, 2.4 + lz), dark, false)
			var globe := MeshInstance3D.new()
			var gm := SphereMesh.new()
			gm.radius = 0.6
			gm.height = 1.2
			globe.mesh = gm
			var gmat := city.glow_mat(Color("5aa8ff"), 1.2)
			gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gmat.albedo_color = Color(0.4, 0.7, 1.0, 0.45)
			globe.material_override = gmat
			globe.position = o + Vector3(-5.2, 1.7, -2.6)
			city.add_child(globe)
			city.cyl(0.5, 0.6, 0.5, o + Vector3(-5.2, 0.25, -2.6), dark, null, 16)
			city.cyl(0.62, 0.62, 0.03, o + Vector3(-5.2, 0.52, -2.6), city.glow_mat(Color("7cc4ff"), 2.0), null, 20)
		"dorm_red":
			# A rag rug, a noticeboard and laundry on a line: lived in, a little shabby.
			city.box(Vector3(3.0, 0.02, 2.0), o + Vector3(0.5, 0.012, 1.6), city.mat(Color(0.7, 0.3, 0.22), 0.95), false)
			city.box(Vector3(2.4, 0.021, 1.4), o + Vector3(0.5, 0.013, 1.6), city.mat(Color(0.86, 0.68, 0.4), 0.95), false)
			city.box(Vector3(1.6, 1.0, 0.05), o + Vector3(2.6, 1.7, -half.y + 0.05), city.mat(Color(0.62, 0.46, 0.28), 0.9), false)
			for k in 6:
				city.box(Vector3(0.3, 0.38, 0.02), o + Vector3(2.0 + (k % 3) * 0.6, 1.5 + (k / 3) * 0.44, -half.y + 0.09), city.mat([Color("f2f2ee"), Color("ffd166"), Color("7cc4ff")][k % 3], 0.9), false)
			city.box(Vector3(half.x * 1.2, 0.015, 0.015), o + Vector3(-1.0, hgt - 0.55, 2.8), dark, false)
			for k in 5:
				city.box(Vector3(0.4, 0.5, 0.02), o + Vector3(-3.4 + k * 1.1, hgt - 0.82, 2.8), city.mat([Color("d9342b"), Color("f2f2ee"), Color("26364f"), Color("d9342b"), Color("f0c040")][k], 0.9), false)
		"dorm_yellow", "dorm_blue":
			# A long carpet runner in the dorm color and standing lamps.
			var cc := Color("d8a520") if key == "dorm_yellow" else Color("1f4fa8")
			city.box(Vector3(2.2, 0.02, half.y * 2 - 2.0), o + Vector3(0, 0.012, 0.3), city.mat(cc, 0.95), false)
			city.box(Vector3(1.8, 0.021, half.y * 2 - 2.4), o + Vector3(0, 0.013, 0.3), city.mat(cc.lightened(0.25), 0.95), false)
			for sx: float in [-1.0, 1.0]:
				var lp := o + Vector3(sx * (half.x - 0.6), 0, -half.y + 0.7)
				city.cyl(0.03, 0.14, 1.7, lp + Vector3(0, 0.85, 0), city.mat(Color(0.86, 0.68, 0.3), 0.3, 0.8), null, 8)
				city.cyl(0.14, 0.22, 0.3, lp + Vector3(0, 1.8, 0), city.glow_mat(Color(1.0, 0.9, 0.7), 1.8), null, 12)
				var l := OmniLight3D.new()
				l.light_color = Color(1.0, 0.88, 0.68)
				l.light_energy = 1.3
				l.omni_range = 5.0
				l.position = lp + Vector3(0, 1.8, 0)
				city.add_child(l)


## What the buildings look like from the street: a sign and awning for the two Domino doors,
## and a small columned library building on the island.
static func build_outside(city: CityBuilder, district: String) -> void:
	if district == "academy":
		var c := Vector3(-24.0, 0.1, 28.5)
		var stone := city.mat(Color(0.9, 0.88, 0.82), 0.8)
		var roof := city.mat(Color(0.3, 0.42, 0.62), 0.6)
		var dark := city.mat(Color(0.22, 0.14, 0.09), 0.6)
		city.box(Vector3(10.6, 0.4, 12.6), c + Vector3(0, 0.2, 0), city.mat(Color(0.8, 0.78, 0.74), 0.9))
		city.box(Vector3(9.0, 5.2, 11.0), c + Vector3(-0.5, 2.9, 0), stone)
		# Columns across the front and a stepped roof.
		for k in 5:
			city.cyl(0.32, 0.36, 4.6, c + Vector3(4.55, 2.7, -4.4 + k * 2.2), stone, null, 12)
			city.box(Vector3(0.9, 0.2, 0.9), c + Vector3(4.55, 0.5, -4.4 + k * 2.2), stone, false)
		city.box(Vector3(11.2, 0.5, 12.8), c + Vector3(0, 5.7, 0), stone, false)
		for k in 3:
			city.box(Vector3(10.6 - k * 2.6, 0.55, 12.2 - k * 0.6), c + Vector3(-0.2, 6.2 + k * 0.55, 0), roof, false)
		# Door, steps and windows.
		city.box(Vector3(0.2, 3.0, 2.0), c + Vector3(4.0, 1.9, 0), dark, false)
		city.box(Vector3(0.25, 3.3, 0.2), c + Vector3(4.05, 2.05, -1.1), city.mat(Color(0.86, 0.68, 0.3), 0.3, 0.8), false)
		city.box(Vector3(0.25, 3.3, 0.2), c + Vector3(4.05, 2.05, 1.1), city.mat(Color(0.86, 0.68, 0.3), 0.3, 0.8), false)
		for k in 2:
			city.box(Vector3(0.5, 0.15, 3.4 + k * 0.6), c + Vector3(5.5 + k * 0.45, 0.3 - k * 0.14, 0), stone, false)
		for z: float in [-3.4, 3.4]:
			city.box(Vector3(0.12, 2.0, 1.2), c + Vector3(4.02, 2.6, z), city.glow_mat(Color(1.0, 0.86, 0.6), 0.6), false)
		var sign := city.neon_sign("LIBRARY", c + Vector3(5.1, 5.1, 0), Color("ffd166"), 80, PI / 2.0, false)
		sign.double_sided = true
		# A path over to the main walk.
		city.box(Vector3(17.5, 0.12, 2.6), Vector3(-9.6, 0.1, 28.5), city.mat(Color(0.82, 0.8, 0.74), 0.9), false)
		return
	if district != "domino":
		return
	# Your building: an awning, a name plate and a warm light over the door.
	var d := Vector3(-25, 0, 18.3)
	city.box(Vector3(2.6, 0.12, 1.3), d + Vector3(0, 3.0, -0.7), city.mat(Color(0.16, 0.5, 0.56), 0.7), false)
	city.box(Vector3(2.6, 0.3, 0.06), d + Vector3(0, 2.86, -1.33), city.mat(Color(0.9, 0.92, 0.94), 0.7), false)
	city.box(Vector3(1.7, 2.6, 0.1), d + Vector3(0, 1.46, 0.02), city.mat(Color(0.2, 0.26, 0.34), 0.5), false)
	city.box(Vector3(0.7, 2.3, 0.04), d + Vector3(-0.4, 1.36, -0.05), city.glow_mat(Color(1.0, 0.86, 0.62), 0.5), false)
	city.box(Vector3(0.7, 2.3, 0.04), d + Vector3(0.4, 1.36, -0.05), city.glow_mat(Color(1.0, 0.86, 0.62), 0.5), false)
	city.neon_sign("CROSSROADS APARTMENTS", d + Vector3(0, 3.5, -1.36), Color("7cc4ff"), 46, PI, false)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.86, 0.66)
	lamp.light_energy = 1.4
	lamp.omni_range = 5.0
	lamp.position = d + Vector3(0, 2.6, -1.0)
	city.add_child(lamp)
	city.neon_sign("DOMINO MART  24H", Vector3(-24, 4.5, -8.8), Color("7dffb0"), 60, 0.0, false)


## The things you can do inside each room.
static func add_spots(scene: Node) -> void:
	for key in ROOMS:
		if not scene._rooms.has(key):
			continue
		var r: Dictionary = ROOMS[key]
		var o: Vector3 = r["at"]
		var half: Vector2 = r["half"]
		match key:
			"home":
				scene._spots.append({"pos": o + Vector3(-half.x + 2.6, 0, -half.y + 2.0), "range": 1.5, "label": "Rest on your bed", "action": func(): _rest(scene)})
				scene._spots.append({"pos": o + Vector3(1.2, 0, -half.y + 1.9), "range": 1.3, "label": "Build decks at your desk", "action": func(): scene.open_decks()})
				scene._spots.append({"pos": o + Vector3(half.x - 1.3, 0, 0.2), "range": 1.4, "label": "Look at your shelf", "action": func(): _shelf()})
			"mart":
				scene._spots.append({"pos": o + Vector3(half.x - 2.0, 0, half.y - 1.6), "range": 1.4, "label": "Lucky draw  ·  free once a day", "action": func(): _lucky(scene)})
				scene._spots.append({"pos": o + Vector3(-half.x + 1.7, 0, 0.4), "range": 1.4, "label": "Buy a drink  ·  10 DP", "action": func(): scene.life._drink() if scene.life else null})
			"ac_library":
				scene._spots.append({"pos": o + Vector3(-2.6, 0, 4.6), "range": 1.4, "label": "Take the duel quiz", "action": func(): _quiz(scene)})
				scene._spots.append({"pos": o + Vector3(4.6, 0, 3.0), "range": 1.3, "label": "Read a strategy book", "action": func(): Router.toast(Loc.t(TIPS[randi() % TIPS.size()]))})


static func _rest(scene: Node) -> void:
	if scene._overlay_open:
		return
	scene._overlay_open = true
	Sfx.play("sit", -6.0)
	var tw: Tween = scene.create_tween()
	tw.tween_property(scene._fader, "color:a", 1.0, 0.5)
	await tw.finished
	scene._cycle_tod()
	await scene.get_tree().create_timer(0.5).timeout
	var tw2: Tween = scene.create_tween()
	tw2.tween_property(scene._fader, "color:a", 0.0, 0.6)
	scene._overlay_open = false
	Router.toast(Loc.t("You rest for a while. Time has moved on outside."))


static func _shelf() -> void:
	var wins := 0
	var beaten: Dictionary = Collection.record.get("beaten", {})
	wins = beaten.size()
	Router.toast(Loc.t("Your shelf: %d different duelists beaten, %d cards collected, %d Duel Points saved.") % [wins, Collection.owned.size(), Collection.dp])


static func _lucky(scene: Node) -> void:
	if str(scene._shop_cfg().get_value("shop", "draw_day", "")) == scene._today():
		Router.toast(Loc.t("The lucky draw is empty until tomorrow."))
		Sfx.play("error", -8.0)
		return
	scene._shop_set("draw_day", scene._today())
	Sfx.play("charge", -6.0)
	await scene.get_tree().create_timer(0.9).timeout
	var roll := randf()
	if roll < 0.12:
		var pools: Array = []
		for era in ["Duel Monsters", "GX", "5D's", "ZEXAL"]:
			pools.append_array(Collection.pool(era))
		if not pools.is_empty():
			var id: int = pools[randi() % pools.size()]
			Collection.owned[id] = mini(3, int(Collection.owned.get(id, 0)) + 1)
			Collection.save()
			Sfx.play("rare", -4.0)
			Router.toast(Loc.t("A gold capsule! Inside: %s. It is in your collection.") % str(CardData.get_card(id).get("name", "?")))
			return
	var prize: int = 150 if roll < 0.4 else [30, 40, 50, 60, 80][randi() % 5]
	Collection.dp += prize
	Collection.save()
	Sfx.play("coin", -4.0)
	Router.toast(Loc.t("The capsule pops open:  +%d Duel Points") % prize)


static func _quiz(scene: Node) -> void:
	if scene._overlay_open:
		return
	# The first three right answers of the day pay; after that it is just for practice.
	var cfg: ConfigFile = scene._shop_cfg()
	var paid := int(cfg.get_value("shop", "quiz_n", 0)) if str(cfg.get_value("shop", "quiz_day", "")) == scene._today() else 0
	var reward := 40 if paid < 3 else 0
	var q := QuizPanel.new(reward)
	q.answered.connect(func(ok: bool):
		if not ok:
			return
		Collection.daily_bump("quiz")
		if reward > 0:
			Collection.dp += reward
			scene._shop_set("quiz_day", scene._today())
			scene._shop_set("quiz_n", paid + 1)
		Collection.save())
	scene._open_overlay(q)
