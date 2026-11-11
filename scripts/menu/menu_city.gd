extends Node3D
## Home screen backdrop: Domino City at sunset, your duelist looking up at the skyline.

var _cam: Camera3D
var _time := 0.0
var _hero: RoamFigure
var _look := ""


func _ready() -> void:
	var city := CityBuilder.new()
	city.make_solid = false
	add_child(city)
	city.build(FieldThemes.resolve("battlecity", ""), "sunset")
	_cam = Camera3D.new()
	_cam.fov = 52
	add_child(_cam)
	_cam.current = true
	var key := OmniLight3D.new()
	key.light_color = Color(1.0, 0.82, 0.66)
	key.light_energy = 2.6
	key.omni_range = 6.0
	key.position = Vector3(10.2, 2.6, 11.0)
	add_child(key)
	_spawn_hero()
	Profile.changed.connect(func():
		if Profile.hero_key() != _look:
			_spawn_hero())
	_process(0.0)


func _spawn_hero() -> void:
	if _hero:
		_hero.queue_free()
	_look = Profile.hero_key()
	_hero = RoamFigure.new()
	add_child(_hero)
	_hero.position = Vector3(8.3, 0.16, 8.9)
	_hero.rotation.y = PI + 0.75
	_hero.setup("player", Profile.color(), "", false)


func _process(delta: float) -> void:
	_time += delta
	var sway := sin(_time * 0.13)
	_cam.position = Vector3(9.3 + sway * 0.5, 1.3 + cos(_time * 0.1) * 0.06, 12.6)
	_cam.look_at(Vector3(-1.5 + sway * 0.4, 4.4, -30.0))
