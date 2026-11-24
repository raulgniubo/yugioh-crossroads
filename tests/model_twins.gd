extends Node3D
## Dev: three copies of one dropped-in model side by side, each doing something else (one kept model,
## three copies: nothing may be shared that should not be). TWINS_SHOT=<file.png>  --key=yugi
func _ready() -> void:
	var key := "yugi"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--key="):
			key = a.substr(6)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.5)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 4.2)
	cam.fov = 40
	add_child(cam)
	var acts := ["idle", "walk", "wave", "cheer"]
	var models: Array = []
	for i in 4:
		var m: Node3D = Avatars.load_model(key if i < 3 else "kaiba")
		if m == null:
			print("TWINS no model")
			continue
		m.position = Vector3(-1.8 + i * 1.2, 0, 0)
		add_child(m)
		models.append(m)
	await get_tree().process_frame
	# One of the copies gets a dorm jacket and one a suit of another color: only they may change.
	if models.size() >= 3:
		Avatars.apply_uniform(models[1], Avatars.DORM_COLORS["red"])
		Avatars.wear(models[2], key, Color("3f7be0"))
	for i in models.size():
		var ap: AnimationPlayer = Avatars.anim_player(models[i])
		var nm := ""
		if acts[i] in ["wave", "cheer"]:
			nm = Avatars.gesture(models[i], acts[i])
		elif ap != null:
			nm = Avatars.clip(ap, acts[i])
		print("TWINS %d %s -> '%s'  clips %d  same library as the first: %s" % [i, acts[i], nm, ap.get_animation_list().size() if ap else -1,
				str(ap != null and Avatars.anim_player(models[0]).get_animation_library("") == ap.get_animation_library(""))])
		if ap != null and nm != "":
			ap.play(nm)
			ap.seek(0.4 + i * 0.1, true)
	# And their portrait, which is a copy of the kept model with the sharper color texture.
	var layer := CanvasLayer.new()
	add_child(layer)
	var face := TextureRect.new()
	face.texture = Portraits.get_portrait(key, true)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.position = Vector2(8, 8)
	face.size = Vector2(150, 188)
	layer.add_child(face)
	for i in 40:
		await get_tree().process_frame
	var shot := OS.get_environment("TWINS_SHOT")
	if shot != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)
	# One goes: the others must stay whole.
	models[0].queue_free()
	for i in 6:
		await get_tree().process_frame
	if shot != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot.replace(".png", "_b.png"))
	get_tree().quit()
