class_name ShopInterior
extends RefCounted
## The inside of Kame Game. Built far away from the streets; you step in through the shop door.

const AT := Vector3(400, 0, 400)
const HALF := Vector2(7.0, 5.0)
const HEIGHT := 4.2


static func build(city: CityBuilder) -> void:
	var o := AT
	var wood := city.mat(Color(0.5, 0.36, 0.24), 0.75)
	var wall := city.mat(Color(0.92, 0.86, 0.74), 0.9)
	var trim := city.mat(Color(0.32, 0.2, 0.13), 0.7)
	city.box(Vector3(HALF.x * 2 + 0.6, 0.3, HALF.y * 2 + 0.6), o + Vector3(0, -0.15, 0), wood)
	# Plank lines on the floor
	for i in range(-6, 7):
		city.box(Vector3(0.03, 0.01, HALF.y * 2), o + Vector3(i * 1.0 + 0.5, 0.006, 0), trim, false)
	city.box(Vector3(HALF.x * 2 + 0.6, 0.3, HALF.y * 2 + 0.6), o + Vector3(0, HEIGHT + 0.15, 0), city.mat(Color(0.86, 0.82, 0.74), 0.95), false)
	for sx in [-1, 1]:
		city.box(Vector3(0.3, HEIGHT, HALF.y * 2 + 0.6), o + Vector3(sx * (HALF.x + 0.15), HEIGHT / 2.0, 0), wall)
		city.box(Vector3(0.08, 0.9, HALF.y * 2), o + Vector3(sx * (HALF.x - 0.03), 0.45, 0), trim, false)
	for sz in [-1, 1]:
		city.box(Vector3(HALF.x * 2 + 0.6, HEIGHT, 0.3), o + Vector3(0, HEIGHT / 2.0, sz * (HALF.y + 0.15)), wall)
		city.box(Vector3(HALF.x * 2, 0.9, 0.08), o + Vector3(0, 0.45, sz * (HALF.y - 0.03)), trim, false)
	# Ceiling beams and warm lights
	for i in range(-2, 3):
		city.box(Vector3(0.25, 0.25, HALF.y * 2), o + Vector3(i * 3.0, HEIGHT - 0.13, 0), trim, false)
	for p in [Vector3(-4, 3.4, -1.5), Vector3(4, 3.4, -1.5), Vector3(0, 3.4, 2.4), Vector3(0, 3.2, -3.4)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.86, 0.66)
		l.light_energy = 2.2
		l.omni_range = 9.0
		l.shadow_enabled = false
		l.position = o + p
		city.add_child(l)
		var bulb := city.cyl(0.22, 0.34, 0.2, o + p + Vector3(0, 0.35, 0), city.glow_mat(Color(1.0, 0.86, 0.6), 2.4))
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Furniture
	city.collide(city.prop("shop_counter", o + Vector3(0, 0, -2.9), 0.0, 4.8), 0.95)
	for x in [-5.6, -3.0, 3.0, 5.6]:
		city.collide(city.prop("shop_shelf", o + Vector3(x, 0, -4.45), 0.0, 2.7, true))
	for z in [-2.2, 0.6]:
		city.collide(city.prop("shop_shelf", o + Vector3(-6.45, 0, z), PI / 2, 2.7, true))
		city.collide(city.prop("shop_shelf", o + Vector3(6.45, 0, z), -PI / 2, 2.7, true))
	city.collide(city.prop("card_rack", o + Vector3(-2.6, 0, -0.4), 0.4, 1.9, true), 0.7)
	city.collide(city.prop("card_rack", o + Vector3(2.7, 0, 0.2), -0.6, 1.9, true), 0.7)
	city.collide(city.prop("duel_table", o + Vector3(-3.9, 0, 2.9), 0.0, 2.5), 0.75)
	city.collide(city.prop("duel_table", o + Vector3(4.0, 0, 2.9), 0.0, 2.5), 0.75)
	city.collide(city.prop("arcade_cabinet", o + Vector3(6.35, 0, 3.6), -PI / 2, 1.9, true))
	city.collide(city.prop("vending", o + Vector3(-6.45, 0, -4.2), PI / 2, 1.95, true))
	# Mirror (change your look) and the door out
	var frame := city.box(Vector3(0.12, 2.3, 1.3), o + Vector3(-6.92, 1.35, 3.4), trim, false)
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glass := city.mat(Color(0.75, 0.88, 0.95), 0.04, 0.9)
	glass.emission_enabled = true
	glass.emission = Color(0.55, 0.75, 0.9)
	glass.emission_energy_multiplier = 0.25
	city.box(Vector3(0.05, 2.1, 1.1), o + Vector3(-6.85, 1.35, 3.4), glass, false)
	city.box(Vector3(1.7, 2.6, 0.12), o + Vector3(0, 1.3, HALF.y - 0.04), city.mat(Color(0.28, 0.18, 0.12), 0.6), false)
	city.box(Vector3(1.2, 1.2, 0.05), o + Vector3(0, 1.75, HALF.y - 0.11), city.glow_mat(Color(0.7, 0.85, 1.0), 0.9), false)
	_sign(city, "EXIT", o + Vector3(0, 2.95, HALF.y - 0.12), PI, Color("7dffb0"), 70)
	_sign(city, "KAME GAME", o + Vector3(0, 3.35, -HALF.y + 0.12), 0.0, Color("ffd166"), 130)
	_sign(city, "NEW BOOSTERS IN STOCK", o + Vector3(4.3, 3.3, -HALF.y + 0.12), 0.0, Color("ff8ac0"), 54)
	_sign(city, "DUEL TABLES  ·  FREE PLAY", o + Vector3(HALF.x - 0.12, 3.2, 2.6), -PI / 2, Color("7cc4ff"), 54)
	_sign(city, "FITTING MIRROR", o + Vector3(-HALF.x + 0.12, 2.9, 3.4), PI / 2, Color("b8f0ff"), 46)


static func _sign(city: CityBuilder, text: String, pos: Vector3, rot: float, color: Color, size: int) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 8
	l.modulate = color * 1.5
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.position = pos
	l.rotation.y = rot
	city.add_child(l)
