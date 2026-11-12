extends Node3D
## Dev tool: contact sheet of models. godot -- res://tools/sheet.tscn --sheet=dir --out=/tmp/x.png [--filter=hero] [--cols=6]

func _ready() -> void:
	var dir := "res://assets/models/people"
	var out := "/tmp/sheet.png"
	var filt := ""
	var cols := 6
	var size := 1.9
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sheet="): dir = a.trim_prefix("--sheet=")
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--filter="): filt = a.trim_prefix("--filter=")
		if a.begins_with("--cols="): cols = int(a.trim_prefix("--cols="))
	var names: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".glb") and (filt == "" or f.contains(filt)):
			names.append(f)
	names.sort()
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.32, 0.36, 0.42)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.7
	we.environment = e
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	add_child(sun)
	var rows := int(ceil(names.size() / float(cols)))
	for i in names.size():
		var ps: PackedScene = load(dir.path_join(names[i]))
		var n: Node3D = ps.instantiate()
		var holder := Node3D.new()
		add_child(holder)
		holder.add_child(n)
		var box := _aabb(n, Transform3D())
		var s := size / maxf(box.size.y, maxf(box.size.x, box.size.z))
		if dir.contains("city"):
			n.scale = Vector3.ONE * s
			n.position = Vector3(-box.get_center().x * s, -box.position.y * s, -box.get_center().z * s)
		holder.position = Vector3((i % cols - (cols - 1) / 2.0) * 2.3, -(i / cols) * 2.7, 0)
		holder.rotation.y = 0.5 if dir.contains("city") else 0.0
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--tint="):
				var ti := (i + int(arg.trim_prefix("--tint="))) % Profile.COLORS.size()
				Avatars.apply_hero_color(n, Profile.COLORS[ti], 2 if names[i].contains("rider") else 0)
		var ap := _ap(n)
		if ap:
			var want := "idle"
			var at := -1.0
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--clip="): want = a.trim_prefix("--clip=")
				if a.begins_with("--t="): at = float(a.trim_prefix("--t="))
			if want == "calm":
				Avatars._calm_idle(ap)
			for c in ap.get_animation_list():
				if String(c).to_lower().contains(want):
					ap.play(c)
					if at >= 0.0:
						ap.seek(at, true)
						ap.pause()
		var l := Label3D.new()
		l.text = names[i].trim_suffix(".glb")
		l.font_size = 48
		l.pixel_size = 0.004
		l.position = holder.position + Vector3(0, -0.25, 0.5)
		add_child(l)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var h := rows * 2.7 + 0.3
	cam.size = maxf(h, cols * 2.3 * 9.0 / 16.0 + 0.4)
	cam.position = Vector3(0, -(rows - 1) * 2.7 / 2.0 + 0.85, 20)
	add_child(cam)
	cam.current = true
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


func _ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var a := _ap(c)
		if a: return a
	return null


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var t: Transform3D = xf * ((n as Node3D).transform if n is Node3D else Transform3D())
	var out := AABB()
	var first := true
	if n is MeshInstance3D:
		out = t * (n as MeshInstance3D).get_aabb()
		first = false
	for c in n.get_children():
		var b := _aabb(c, t)
		if b.size != Vector3.ZERO:
			out = b if first else out.merge(b)
			first = false
	return out
