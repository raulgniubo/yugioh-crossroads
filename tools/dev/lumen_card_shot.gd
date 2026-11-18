extends SceneTree
## Dev: Lumen as her card picture shows her (portrait settings), photographed every 0.07 s for
## 3 s, to catch a blink or a tear. xvfb-run godot --rendering-driver opengl3 -s tools/dev/lumen_card_shot.gd
var l: LumenSpirit
var n := 0
func _initialize() -> void:
	var root3 := Node3D.new()
	get_root().add_child(root3)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.45, 0.75)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.86, 1.0)
	env.environment = e
	root3.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.7, 0.6, 0)
	sun.light_energy = 0.8
	root3.add_child(sun)
	l = LumenSpirit.new()
	l.size = 1.0
	l.rotation.y = 0.28
	root3.add_child(l)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var at := Vector3(0.0, 0.3, 1.5)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.27, 0) - at, Vector3.UP), at)
	root3.add_child(cam)
	get_root().size = Vector2i(400, 500)

func _process(_d: float) -> bool:
	n += 1
	if n % 4 == 0 and n > 20:
		var img := get_root().get_texture().get_image()
		img.save_png("/tmp/ls/f%03d_%s.png" % [n, "rest" if l.at_rest() else "MOVING"])
	return n > 260
