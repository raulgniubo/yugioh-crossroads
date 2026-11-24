extends Node
## Dev: what loading a person's model costs: the first time and again (tools/dev/HANDOFF.md, 0.72.4).
## godot --headless --path . res://tests/model_cost.tscn -- --assets=<card folder> [--keys=a,b,c] [--loop=yugi]
func _ready() -> void:
	await get_tree().process_frame
	var keys := ["bruno", "crane", "curator", "nico", "duelist_m2", "yugi", "kaiba", "jaden", "mai"]
	var loop_key := "yugi"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--keys="):
			keys = Array(a.substr(7).split(","))
		elif a.begins_with("--loop="):
			loop_key = a.substr(7)
	if "--warm" in OS.get_cmdline_user_args():
		# The way a world does it: every file is read on other threads first.
		var w0 := Time.get_ticks_msec()
		for k in keys:
			Avatars.warm(k, false)
		var all := false
		while not all:
			await get_tree().process_frame
			Avatars._warm_next()
			all = true
			Avatars._warm_lock.lock()
			for k in keys:
				var p := Avatars.path_for(k)
				if not p.begins_with("res://") and not Avatars._warm.has(Avatars._warm_key(p, 1024)):
					Avatars.warm(k, false)
					all = false
			Avatars._warm_lock.unlock()
		print("WARM: all read after %d ms" % (Time.get_ticks_msec() - w0))
	for round in 3:
		var line := "ROUND %d: " % round
		var held: Array = []
		for k in keys:
			var t0 := Time.get_ticks_usec()
			var m: Node3D = Avatars.load_model(k)
			var t1 := Time.get_ticks_usec()
			if m != null:
				add_child(m)
				held.append(m)
			line += "%s %.0f  " % [k, (t1 - t0) / 1000.0]
		print(line)
		await get_tree().process_frame
		for m in held:
			m.queue_free()
		await get_tree().process_frame
	# What its textures came out as, for the street and for a portrait.
	for sharp in [false, true]:
		var pm: Node3D = Avatars._load_plain(loop_key, sharp)
		var line2 := "TEXTURES %s%s:" % [loop_key, " (portrait)" if sharp else ""]
		if pm != null:
			for mi in Avatars._meshes(pm):
				var mat := mi.mesh.surface_get_material(0) as BaseMaterial3D if mi.mesh != null and mi.mesh.get_surface_count() > 0 else null
				if mat == null:
					continue
				for prop in ["albedo_texture", "normal_texture", "roughness_texture"]:
					var tex := mat.get(prop) as Texture2D
					if tex != null:
						var im := tex.get_image()
						line2 += "  %s %dx%d mips=%s fmt=%d" % [prop.get_slice("_", 0), tex.get_width(), tex.get_height(), str(im.has_mipmaps()) if im else "?", im.get_format() if im else -1]
				break
			pm.free()
		print(line2)
	# The same model made and thrown away over and over: nothing may pile up.
	for i in 3:
		await get_tree().process_frame
	var m0 := OS.get_static_memory_usage()
	var r0 := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var t0 := Time.get_ticks_msec()
	for i in 30:
		var m: Node3D = Avatars.load_model(loop_key)
		if m != null:
			add_child(m)
			await get_tree().process_frame
			m.queue_free()
		await get_tree().process_frame
	print("LOOP %s x30: %d ms, memory %+.1f MB, resources %+d, kept %d models (%.0f MB)" % [loop_key, Time.get_ticks_msec() - t0,
			(OS.get_static_memory_usage() - m0) / 1048576.0, int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)) - r0, Avatars._tpl.size(), Avatars.kept_mb()])
	get_tree().quit()
