class_name Interiors
## Rooms you can walk into besides the card shop: the KaibaCorp lobby, Burger World and the
## arcade. Each is a small box-built set parked far outside the city, like the shop interior.

const ROOMS := {
	"kc_lobby": {"name": "KaibaCorp Lobby", "area": "Reception and the Duel Simulator", "at": Vector3(480, 0, 400), "half": Vector2(9.0, 7.0), "height": 6.0,
		"door": Vector3(0, 0, -52.9), "label": "Enter KaibaCorp", "music": "duel", "floor": Color(0.16, 0.19, 0.26), "wall": Color(0.78, 0.83, 0.92), "trim": Color("2a6cff")},
	"burger": {"name": "Burger World", "area": "Best fries in Domino", "at": Vector3(560, 0, 400), "half": Vector2(7.5, 5.5), "height": 4.0,
		"door": Vector3(24, 0, -8.6), "label": "Enter Burger World", "music": "shop", "floor": Color(0.74, 0.3, 0.22), "wall": Color(0.98, 0.92, 0.78), "trim": Color("ffb030")},
	"arcade": {"name": "Game Center", "area": "Duel cabinets and the prize claw", "at": Vector3(640, 0, 400), "half": Vector2(7.5, 6.0), "height": 4.2,
		"door": Vector3(12.5, 0, -11.9), "label": "Enter the Game Center", "music": "heartland", "floor": Color(0.1, 0.09, 0.16), "wall": Color(0.2, 0.16, 0.32), "trim": Color("5affc0")},
}
## Who is inside (positions are relative to the room).
const PEOPLE := {
	"kc_lobby": [
		{"id": "kc_desk", "char": "", "model": "stylish_woman", "name": "Receptionist", "color": Color("7cc4ff"), "pos": Vector3(0, 0, -4.7), "face": 0.0,
			"lines": ["Welcome to KaibaCorp. Mr. Kaiba is not taking visitors. He never is.", "The Duel Simulator on your right is open to the public. It does not go easy on anyone."]},
		{"id": "kc_sim", "char": "", "model": "duelist_m10", "name": "Duel Simulator", "color": Color("2de2e6"), "pos": Vector3(6.6, 0, -0.6), "face": -1.2,
			"lines": ["DUEL SIMULATOR ONLINE. Opponent profile: Expert. Reward on victory: Duel Points.", "Step onto the pad to begin."],
			"duel": {"deck": "kaiba", "difficulty": 3, "intro": "Simulation start."}},
		{"id": "kc_guard2", "char": "guard", "name": "Lobby Guard", "pos": Vector3(-6.0, 0, 3.6), "face": 1.2,
			"lines": ["Elevators are staff only.", "Between us? I duel on my breaks. Want a game?"],
			"duel": {"deck": "joey", "difficulty": 1, "intro": "Quick one before my shift ends!"}},
	],
	"burger": [
		{"id": "bw_clerk", "char": "", "model": "student_girl", "name": "Burger World Clerk", "color": Color("ffb030"), "pos": Vector3(0, 0, -3.6), "face": 0.0,
			"lines": ["Welcome to Burger World! Duelists eat free if they win the tournament. So far nobody has.", "Rumor is someone is dueling alone at the end of the pier every night."]},
		{"id": "bw_tea", "char": "", "model": "stylish_woman", "name": "Regular", "color": Color("ff8ac0"), "pos": Vector3(-4.6, 0, 1.4), "face": 1.6,
			"lines": ["The Duel Dome posts an open challenge every evening. The prize is always cards.", "The arcade next door has a claw machine that gives real cards. I've lost so many points to it."]},
		{"id": "bw_kid", "char": "kid", "name": "Hungry Duelist", "pos": Vector3(4.4, 0, 1.8), "face": -1.7,
			"lines": ["I duel better on a full stomach. I just ate. You're in trouble."],
			"duel": {"deck": "rex", "difficulty": 1, "intro": "Loser buys the fries!"}},
	],
	"arcade": [
		{"id": "ar_ace", "char": "", "model": "duelist_m17", "name": "Arcade Ace", "color": Color("5affc0"), "pos": Vector3(-4.8, 0, -2.2), "face": 1.4,
			"lines": ["High score on every cabinet in here. Dueling is just another game to beat.", "You look like a quarter I'm about to win."],
			"duel": {"deck": "yuma", "difficulty": 2, "intro": "Insert coin!"}},
		{"id": "ar_girl", "char": "", "model": "duelist_f2", "name": "Combo Queen", "color": Color("ff5ab4"), "pos": Vector3(4.6, 0, -2.6), "face": -1.3,
			"lines": ["I practice chains on the cabinets until my hands hurt.", "Three in a row or it doesn't count. Ready?"],
			"duel": {"deck": "alexis", "difficulty": 2, "intro": "Combo start!"}},
		{"id": "ar_claw", "char": "", "model": "vendor", "name": "Prize Claw", "color": Color("ffd166"), "pos": Vector3(5.2, 0, 3.2), "face": -2.2, "claw": true,
			"lines": ["The Prize Claw: 60 Duel Points a try. Every prize is a real card."]},
	],
}


static func build(city: CityBuilder, key: String) -> void:
	var r: Dictionary = ROOMS[key]
	var o: Vector3 = r["at"]
	var half: Vector2 = r["half"]
	var hgt: float = r["height"]
	var floor_m := city.mat(r["floor"], 0.55, 0.1)
	var wall_m := city.mat(r["wall"], 0.9)
	var trim: Color = r["trim"]
	city.box(Vector3(half.x * 2 + 0.6, 0.3, half.y * 2 + 0.6), o + Vector3(0, -0.15, 0), floor_m)
	city.box(Vector3(half.x * 2 + 0.6, 0.3, half.y * 2 + 0.6), o + Vector3(0, hgt + 0.15, 0), city.mat(Color(r["wall"]).darkened(0.25), 0.95), false)
	for sx: float in [-1.0, 1.0]:
		city.box(Vector3(0.3, hgt, half.y * 2 + 0.6), o + Vector3(sx * (half.x + 0.15), hgt / 2.0, 0), wall_m)
		city.box(Vector3(0.06, 0.12, half.y * 2), o + Vector3(sx * (half.x - 0.02), 1.0, 0), city.glow_mat(trim, 1.6), false)
	for sz: float in [-1.0, 1.0]:
		city.box(Vector3(half.x * 2 + 0.6, hgt, 0.3), o + Vector3(0, hgt / 2.0, sz * (half.y + 0.15)), wall_m)
		city.box(Vector3(half.x * 2, 0.12, 0.06), o + Vector3(0, 1.0, sz * (half.y - 0.02)), city.glow_mat(trim, 1.6), false)
	for p in [Vector3(-half.x * 0.5, hgt - 0.5, -half.y * 0.4), Vector3(half.x * 0.5, hgt - 0.5, -half.y * 0.4), Vector3(0, hgt - 0.5, half.y * 0.45)]:
		var l := OmniLight3D.new()
		l.light_color = Color.WHITE.lerp(trim, 0.2)
		l.light_energy = 2.4
		l.omni_range = 11.0
		l.shadow_enabled = false
		l.position = o + p
		city.add_child(l)
		city.box(Vector3(1.6, 0.06, 0.5), o + p + Vector3(0, 0.42, 0), city.glow_mat(Color.WHITE.lerp(trim, 0.25), 2.6), false)
	# The way out.
	city.box(Vector3(2.0, 2.6, 0.08), o + Vector3(0, 1.3, half.y - 0.02), city.glow_mat(Color("7dffb0"), 0.5), false)
	_sign(city, "EXIT", o + Vector3(0, 2.95, half.y - 0.1), PI, Color("7dffb0"), 64)
	match key:
		"kc_lobby":
			_sign(city, "KAIBACORP", o + Vector3(0, 4.9, -half.y + 0.12), 0.0, Color("7cc4ff"), 170)
			# Reception: a white desk with a blue edge, the KC ring set into the floor in front.
			var white := city.mat(Color(0.9, 0.92, 0.96), 0.3, 0.3)
			city.box(Vector3(6.4, 1.1, 1.1), o + Vector3(0, 0.55, -3.6), white)
			city.box(Vector3(6.6, 0.08, 1.3), o + Vector3(0, 1.14, -3.6), city.mat(Color(0.12, 0.14, 0.2), 0.2, 0.6), false)
			city.box(Vector3(6.42, 0.1, 0.04), o + Vector3(0, 0.3, -3.04), city.glow_mat(Color("2a6cff"), 2.0), false)
			for k in 2:
				city.box(Vector3(0.9, 0.55, 0.06), o + Vector3(-1.6 + k * 3.2, 1.5, -3.7), city.glow_mat(Color("7cc4ff"), 1.0), false)
			for rr: Array in [[2.6, 2.72], [1.9, 1.96]]:
				var ring := MeshInstance3D.new()
				var tm := TorusMesh.new()
				tm.inner_radius = rr[0]
				tm.outer_radius = rr[1]
				tm.rings = 48
				ring.mesh = tm
				ring.material_override = city.glow_mat(Color("7cc4ff"), 1.4)
				ring.scale = Vector3(1, 0.04, 1)
				ring.position = o + Vector3(0, 0.03, 1.6)
				city.add_child(ring)
			# The tournament bracket on the big screen, and the lifts nobody is allowed to use.
			city.box(Vector3(7.0, 2.3, 0.12), o + Vector3(0, 3.0, -half.y + 0.1), city.mat(Color(0.04, 0.06, 0.1), 0.3, 0.4), false)
			_sign(city, "BATTLE CITY  ·  LIVE BRACKET", o + Vector3(0, 3.85, -half.y + 0.2), 0.0, Color("ffd166"), 50)
			for row in 4:
				for side: float in [-1.0, 1.0]:
					city.box(Vector3(1.5, 0.22, 0.03), o + Vector3(side * 2.4, 3.3 - row * 0.36, -half.y + 0.18), city.glow_mat(Color("7cc4ff") if (row + int(side)) % 2 == 0 else Color("2a6cff"), 1.2), false)
					city.box(Vector3(0.5, 0.03, 0.03), o + Vector3(side * 1.4, 3.3 - row * 0.36, -half.y + 0.18), city.glow_mat(Color("f2f6ff"), 0.9), false)
			city.box(Vector3(1.1, 0.5, 0.03), o + Vector3(0, 2.75, -half.y + 0.18), city.glow_mat(Color("ffd166"), 1.6), false)
			for sx: float in [-1.0, 1.0]:
				var st := city.prop("dragon_statue", o + Vector3(sx * 6.4, 0, -5.0), -sx * 0.6, 3.6, true)
				if st:
					city.collide(st, 0.6)
				# Lift doors.
				city.box(Vector3(1.9, 2.8, 0.1), o + Vector3(sx * 5.0, 1.4, -half.y + 0.1), city.mat(Color(0.62, 0.66, 0.74), 0.25, 0.8), false)
				city.box(Vector3(0.04, 2.8, 0.12), o + Vector3(sx * 5.0, 1.4, -half.y + 0.1), city.mat(Color(0.1, 0.12, 0.16), 0.4), false)
				city.box(Vector3(0.3, 0.14, 0.05), o + Vector3(sx * 5.0, 3.05, -half.y + 0.12), city.glow_mat(Color("ff5a5a"), 2.0), false)
				# Columns with light strips.
				for sz: float in [-1.0, 1.0]:
					var cp := o + Vector3(sx * 3.4, 0, 1.6 + sz * 3.4)
					city.cyl(0.32, 0.32, hgt, cp + Vector3(0, hgt / 2.0, 0), white)
					city.solid_cyl(0.4, 3.0, cp)
					city.cyl(0.34, 0.34, 0.12, cp + Vector3(0, 1.0, 0), city.glow_mat(Color("2a6cff"), 2.0))
					city.cyl(0.34, 0.34, 0.12, cp + Vector3(0, hgt - 0.6, 0), city.glow_mat(Color("2a6cff"), 2.0))
			# The simulator pad.
			city.cyl(1.5, 1.5, 0.06, o + Vector3(6.6, 0.03, 1.4), city.glow_mat(Color("2de2e6"), 1.8))
			var py := city.prop("holo_pylon", o + Vector3(8.1, 0, -1.2), 0.0, 3.6, true)
			if py:
				city.collide(py, 0.5)
			_sign(city, "DUEL SIMULATOR", o + Vector3(half.x - 0.12, 3.4, 0.6), -PI / 2, Color("2de2e6"), 70)
			for k in 2:
				var bench := city.prop("bench", o + Vector3(-7.6, 0, 0.2 + k * 2.6), PI / 2, 2.0)
				if bench:
					city.collide(bench, 0.8)
			var plant := city.mat(Color(0.26, 0.52, 0.3), 0.95)
			for sx: float in [-1.0, 1.0]:
				city.box(Vector3(0.8, 0.7, 0.8), o + Vector3(sx * 8.1, 0.35, half.y - 0.9), white)
				var bush := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.55
				sm.height = 1.2
				bush.mesh = sm
				bush.material_override = plant
				bush.position = o + Vector3(sx * 8.1, 1.2, half.y - 0.9)
				city.add_child(bush)
		"burger":
			# A red band along the back wall with the name on it, menu boards underneath.
			city.box(Vector3(half.x * 2, 0.9, 0.08), o + Vector3(0, 3.4, -half.y + 0.06), city.mat(Color("c8322a"), 0.6), false)
			_sign(city, "BURGER WORLD", o + Vector3(0, 3.4, -half.y + 0.14), 0.0, Color("fff3c8"), 120)
			for k in 4:
				var mb := o + Vector3(-5.1 + k * 3.4, 2.35, -half.y + 0.1)
				city.box(Vector3(2.6, 0.95, 0.06), mb, city.mat(Color(0.1, 0.09, 0.09), 0.5), false)
				city.box(Vector3(0.8, 0.6, 0.03), mb + Vector3(-0.75, 0, 0.04), city.glow_mat([Color("ffb030"), Color("ff5a3a"), Color("ffe07a"), Color("8ad66a")][k], 0.9), false)
				for row in 3:
					city.box(Vector3(1.2, 0.07, 0.03), mb + Vector3(0.55, 0.25 - row * 0.25, 0.04), city.glow_mat(Color("fff3c8"), 0.7), false)
			# The counter: red front, steel top, a till, trays and a drinks machine behind.
			city.box(Vector3(8.4, 1.05, 0.9), o + Vector3(0, 0.525, -2.7), city.mat(Color("d9342b"), 0.5))
			city.box(Vector3(8.4, 0.22, 0.92), o + Vector3(0, 0.34, -2.69), city.mat(Color("fff3c8"), 0.5), false)
			city.box(Vector3(8.6, 0.07, 1.1), o + Vector3(0, 1.09, -2.7), city.mat(Color(0.8, 0.82, 0.85), 0.2, 0.8), false)
			city.box(Vector3(0.5, 0.36, 0.42), o + Vector3(1.9, 1.3, -2.75), city.mat(Color(0.16, 0.17, 0.2), 0.4), false)
			city.box(Vector3(0.42, 0.26, 0.03), o + Vector3(1.9, 1.56, -2.6), city.glow_mat(Color("7dffb0"), 0.9), false)
			for k in 2:
				var tray := o + Vector3(-2.6 + k * 1.5, 1.14, -2.6)
				city.box(Vector3(0.7, 0.03, 0.46), tray, city.mat(Color(0.5, 0.3, 0.2), 0.6), false)
				city.cyl(0.14, 0.14, 0.13, tray + Vector3(-0.14, 0.09, 0), city.mat(Color("d9a13a"), 0.7))
				city.cyl(0.06, 0.08, 0.2, tray + Vector3(0.2, 0.12, 0.02), city.mat(Color("f2f2f2"), 0.5))
			city.box(Vector3(2.2, 2.0, 0.7), o + Vector3(-4.4, 1.0, -half.y + 0.55), city.mat(Color(0.75, 0.77, 0.8), 0.25, 0.8))
			for k in 3:
				city.box(Vector3(0.36, 0.5, 0.05), o + Vector3(-5.0 + k * 0.6, 1.5, -half.y + 0.92), city.glow_mat([Color("ff5a3a"), Color("ffb030"), Color("7cc4ff")][k], 1.1), false)
			# Stools along the counter.
			for k in 5:
				var sp := o + Vector3(-3.2 + k * 1.6, 0, -1.75)
				city.cyl(0.26, 0.26, 0.1, sp + Vector3(0, 0.72, 0), city.mat(Color("d9342b"), 0.6))
				city.cyl(0.05, 0.16, 0.7, sp + Vector3(0, 0.35, 0), city.mat(Color(0.8, 0.82, 0.85), 0.2, 0.8))
			# Booths down the sides, round tables in the middle.
			for sx: float in [-1.0, 1.0]:
				for k in 2:
					var bp := o + Vector3(sx * (half.x - 1.5), 0, 0.4 + k * 3.0)
					city.box(Vector3(1.5, 0.08, 0.9), bp + Vector3(0, 0.78, 0), city.mat(Color(0.95, 0.95, 0.92), 0.4))
					city.cyl(0.08, 0.2, 0.76, bp + Vector3(0, 0.38, 0), city.mat(Color(0.7, 0.72, 0.75), 0.3, 0.8))
					for sz: float in [-1.0, 1.0]:
						city.box(Vector3(1.6, 0.5, 0.5), bp + Vector3(0, 0.25, sz * 0.85), city.mat(Color("d9342b"), 0.6), false)
						city.box(Vector3(1.6, 0.7, 0.14), bp + Vector3(0, 0.85, sz * 1.05), city.mat(Color("c8322a"), 0.6), false)
					city.box(Vector3(1.7, 1.2, 2.3), bp + Vector3(0, 0.6, 0), city.mat(Color(0, 0, 0, 0), 1.0)).visible = false
			for t in [Vector3(-1.9, 0, 2.2), Vector3(1.9, 0, 3.0)]:
				city.cyl(0.6, 0.6, 0.06, o + t + Vector3(0, 0.78, 0), city.mat(Color(0.95, 0.95, 0.92), 0.4))
				city.cyl(0.06, 0.2, 0.78, o + t + Vector3(0, 0.39, 0), city.mat(Color(0.7, 0.72, 0.75), 0.3, 0.8))
				city.solid_cyl(0.55, 1.0, o + t)
				for a in 2:
					city.cyl(0.24, 0.24, 0.45, o + t + Vector3(-0.95 + a * 1.9, 0.22, 0), city.mat(Color("d9342b"), 0.6))
			# Checkerboard strip on the floor in front of the counter.
			for k in 16:
				city.box(Vector3(0.5, 0.012, 0.5), o + Vector3(-3.75 + k * 0.5, 0.008, -1.1 - (k % 2) * 0.5), city.mat(Color(0.96, 0.95, 0.9), 0.5), false)
			var vend := city.prop("vending", o + Vector3(half.x - 0.7, 0, -4.2), -PI / 2, 2.0, true)
			if vend:
				city.collide(vend, 0.9)
		"arcade":
			_sign(city, "GAME CENTER", o + Vector3(0, 3.4, -half.y + 0.12), 0.0, Color("5affc0"), 130)
			for k in 5:
				var cab := city.prop("arcade_cabinet", o + Vector3(-5.6 + k * 2.8, 0, -half.y + 1.0), 0.0, 2.1, true)
				if cab:
					city.collide(cab, 0.9)
				else:
					city.box(Vector3(0.9, 1.9, 0.8), o + Vector3(-5.6 + k * 2.8, 0.95, -half.y + 0.9), city.mat(Color(0.12, 0.1, 0.2), 0.5))
				var gl := OmniLight3D.new()
				gl.light_color = [Color("5affc0"), Color("ff5ab4"), Color("ffd23a"), Color("7cc4ff"), Color("b06cff")][k]
				gl.light_energy = 1.4
				gl.omni_range = 4.0
				gl.shadow_enabled = false
				gl.position = o + Vector3(-5.6 + k * 2.8, 1.5, -half.y + 2.0)
				city.add_child(gl)
			for k in 2:
				var tb := city.prop("duel_table", o + Vector3(-3.0 + k * 6.0, 0, 1.2), 0.0, 2.6)
				if tb:
					city.collide(tb, 0.85)
			# The prize claw.
			city.box(Vector3(1.5, 1.0, 1.5), o + Vector3(6.4, 0.5, 4.2), city.mat(Color(0.75, 0.2, 0.3), 0.5))
			var glass := StandardMaterial3D.new()
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.albedo_color = Color(0.6, 0.9, 1.0, 0.22)
			glass.roughness = 0.05
			city.box(Vector3(1.5, 1.3, 1.5), o + Vector3(6.4, 1.65, 4.2), glass, false)
			city.box(Vector3(1.6, 0.25, 1.6), o + Vector3(6.4, 2.42, 4.2), city.glow_mat(Color("ffd166"), 1.6), false)
			_sign(city, "PRIZE CLAW", o + Vector3(half.x - 0.12, 3.2, 4.2), -PI / 2, Color("ffd166"), 60)


static func _sign(city: CityBuilder, text: String, pos: Vector3, rot: float, color: Color, size: int) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 0
	l.modulate = color * 1.6
	l.position = pos
	l.rotation.y = rot
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	city.add_child(l)
