extends SceneTree
## Dev: a close picture of a people model's face. godot -s tools/face_shot.gd -- name out.png [texture.png]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var name: String = args[0]
	var out: String = args[1]
	var scene: Node3D = (load("res://assets/models/people/%s.glb" % name) as PackedScene).instantiate()
	root.add_child(scene)
	if args.size() > 2 and args[2] != "":
		var img := Image.load_from_file(args[2])
		img.generate_mipmaps()
		var tex := ImageTexture.create_from_image(img)
		for mi in scene.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m := (mi as MeshInstance3D).mesh.surface_get_material(i)
				if m is BaseMaterial3D:
					var d := (m as BaseMaterial3D).duplicate()
					d.albedo_texture = tex
					(mi as MeshInstance3D).set_surface_override_material(i, d)
	await process_frame
	var top := 0.0
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		top = maxf(top, bb.end.y)
	var cam := Camera3D.new()
	cam.fov = 28.0
	root.add_child(cam)
	var face := Vector3(0, top * 0.9, 0)
	if args.size() > 3:
		face.y = float(args[3])
	cam.look_at_from_position(face + Vector3(0.22, 0.02, 0.95), face, Vector3.UP)
	cam.current = true
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.09, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.7
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.5, 0.5, 0)
	root.add_child(sun)
	for i in 6:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out, " top ", top)
	quit()
