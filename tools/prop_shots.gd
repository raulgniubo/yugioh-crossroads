extends Node3D
## Dev: a picture of each pre-made model from two sides, drawn two-sided (as shipped) and
## one-sided (as the game now draws them), to check that nothing goes missing.
##   godot res://tools/prop_shots.tscn -- --props=school,card_shop

func _ready() -> void:
	var names: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--props="):
			names = Array(a.trim_prefix("--props=").split(","))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.85, 1.0)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)
	var cam := Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.current = true
	for n in names:
		for mode in 2:
			var ps: PackedScene = load("res://assets/models/city/%s.glb" % n)
			var inst: Node3D = ps.instantiate()
			add_child(inst)
			var box := AABB()
			var first := true
			for mi in inst.find_children("*", "MeshInstance3D", true, false):
				var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
				box = b if first else box.merge(b)
				first = false
				for i in (mi as MeshInstance3D).mesh.get_surface_count():
					var m := (mi as MeshInstance3D).mesh.surface_get_material(i) as BaseMaterial3D
					if m:
						m.cull_mode = BaseMaterial3D.CULL_BACK if mode == 1 else BaseMaterial3D.CULL_DISABLED
			var c := box.get_center()
			var r := box.size.length() * 0.5
			for view in 2:
				var ang := 0.6 + view * PI
				cam.position = c + Vector3(sin(ang) * r * 1.9, r * 0.5, cos(ang) * r * 1.9)
				cam.look_at(c)
				for k in 5:
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("/tmp/prop_%s_%d%d.png" % [n, mode, view])
			inst.queue_free()
			await get_tree().process_frame
	get_tree().quit()
