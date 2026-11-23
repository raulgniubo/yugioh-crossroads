extends Node3D
## Dev: close-ups of the player's face for every body/hair/outfit, saved as PNGs.
##   xvfb-run godot --rendering-driver opengl3 --path . res://tests/face_shot.tscn -- --out=/tmp/ui/face --size=640 [--looks=0:0:0,1:2:1] [--dist=0.42] [--sun]
var out := "/tmp/ui/face"
var size := 640
var dist := 0.42
var sun := false
var looks: Array = []
var ids := false
var tint := false
var lod := -1.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--size="):
			size = int(a.substr(7))
		elif a.begins_with("--dist="):
			dist = float(a.substr(7))
		elif a == "--ids":
			ids = true
		elif a.begins_with("--lod="):
			lod = float(a.substr(6))
		elif a == "--tint":
			tint = true
		elif a == "--sun":
			sun = true
		elif a.begins_with("--looks="):
			for s in a.substr(8).split(","):
				var p := s.split(":")
				looks.append([int(p[0]), int(p[1]), int(p[2])])
	if looks.is_empty():
		for b in 2:
			for h in 4:
				looks.append([b, h, 0])
	get_window().size = Vector2i(size, size)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.32, 0.3, 0.4)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.8)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 30, 0)
	light.light_energy = 1.1
	light.shadow_enabled = sun
	add_child(light)
	var cam := Camera3D.new()
	cam.fov = 30.0
	add_child(cam)
	cam.current = true
	for lk in looks:
		Profile.look_body = int(lk[0])
		Profile.look_hair = int(lk[1])
		Profile.look_outfit = int(lk[2])
		var m := Avatars._load_plain("player", true)
		if m == null:
			print("FACESHOT no model for ", lk)
			continue
		add_child(m)
		for mm in m.find_children("*", "MeshInstance3D", true, false):
			for si in (mm as MeshInstance3D).get_surface_override_material_count():
				var sm = (mm as MeshInstance3D).get_surface_override_material(si)
				if sm is ShaderMaterial and ids:
					(sm as ShaderMaterial).set_shader_parameter("debug_ids", 1)
				if sm is ShaderMaterial and lod >= 0.0:
					(sm as ShaderMaterial).set_shader_parameter("lod_max", lod)
				if sm is ShaderMaterial and tint:
					# a vivid look: teal hair, a deep skin tone (any skin pixel left out of the skin shows)
					(sm as ShaderMaterial).set_shader_parameter("hair_to", Color("1fa4a0"))
					(sm as ShaderMaterial).set_shader_parameter("skin_to", Color("aa7345"))
		for i in 20:
			await get_tree().process_frame
		var hp := Avatars.head_position(m) + Vector3(0, 0.07, 0)
		cam.global_position = hp + Vector3(0, 0.0, dist)
		cam.look_at(hp, Vector3.UP)
		for i in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var fn := "%s_b%d_h%d_o%d%s.png" % [out, lk[0], lk[1], lk[2], ("_ids" if ids else "") + ("_tint" if tint else "") + ("_lod%d" % int(lod) if lod >= 0.0 else "")]
		img.save_png(fn)
		print("FACESHOT ", fn)
		m.queue_free()
		await get_tree().process_frame
	get_tree().quit()
