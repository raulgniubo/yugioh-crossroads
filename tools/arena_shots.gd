extends Node3D
## Dev tool: builds every duel arena in turn and saves a picture of each. The small ones in
## assets/arenas are what the Free Duel arena picker shows.
##   godot res://tools/arena_shots.tscn -- [--only=key,key]

func _ready() -> void:
	var keys: Array = FieldThemes.ORDER.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			keys = Array(a.trim_prefix("--only=").split(","))
	for key in keys:
		var board := DuelBoard.new()
		board.theme = FieldThemes.resolve(str(key), "")
		add_child(board)
		for i in 40:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/ar_%s_top.png" % key)
		var cam := Camera3D.new()
		cam.fov = 54.0
		cam.far = 1200.0
		add_child(cam)
		cam.look_at_from_position(Vector3(9.5, 4.6, 12.5), Vector3(-2.0, 1.6, -5.0))
		cam.current = true
		for i in 8:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("/tmp/ar_%s_cine.png" % key)
		img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		img.save_jpg(ProjectSettings.globalize_path("res://assets/arenas/%s.jpg" % key), 0.9)
		print("ARENA ", key)
		cam.queue_free()
		board.queue_free()
		for i in 4:
			await get_tree().process_frame
	get_tree().quit()
