extends SceneTree
## Dev tool: pictures of Lumen from a few sides. godot -s tools/lumen_shot.gd (needs a display).

func _initialize() -> void:
	var root3 := Node3D.new()
	get_root().add_child(root3)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.2, 0.3)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.75, 0.9)
	e.ambient_light_energy = 0.8
	env.environment = e
	root3.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.5, 0)
	root3.add_child(sun)
	var moods := ["calm", "happy", "scared", "sad"]
	for i in 4:
		var l := LumenSpirit.new()
		l.position = Vector3(float(i) * 0.9 - 1.35, 0, 0)
		l.rotation.y = [0.0, 0.5, -0.9, 2.4][i]
		l.mood = moods[i]
		l.bonds = i
		root3.add_child(l)
	var cam := Camera3D.new()
	cam.fov = 30
	cam.position = Vector3(0, 0.45, 3.4)
	root3.add_child(cam)
	cam.look_at(Vector3(0, 0.26, 0))
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/lumen.png")
	quit()
