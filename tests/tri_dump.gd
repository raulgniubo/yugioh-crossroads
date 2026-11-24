extends Node
## Dev: where on the body each triangle of a hero model sits, with the middle of its UVs (for mending a mask).
## godot --headless --path . res://tests/tri_dump.tscn -- --model=hero_m12_hair --out=/tmp/masktool/tris.json
func _ready() -> void:
	var model := "hero_m12_hair"
	var out := "/tmp/masktool/tris.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--model="):
			model = a.substr(8)
		elif a.begins_with("--out="):
			out = a.substr(6)
	var ps = load("res://assets/models/people/%s.glb" % model)
	var scene: Node = ps.instantiate()
	add_child(scene)
	var rows: Array = []
	var scale_up := 100.0      # (these models are a hundredth of their size until their skeleton poses them)
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		var xf: Transform3D = (mi as MeshInstance3D).global_transform
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for i in range(0, idx.size(), 3):
				var a := idx[i]
				var b := idx[i + 1]
				var c := idx[i + 2]
				var p: Vector3 = (xf * ((v[a] + v[b] + v[c]) / 3.0)) * scale_up
				rows.append([snappedf(uv[a].x, 0.0001), snappedf(uv[a].y, 0.0001), snappedf(uv[b].x, 0.0001), snappedf(uv[b].y, 0.0001), snappedf(uv[c].x, 0.0001), snappedf(uv[c].y, 0.0001),
					snappedf(p.x, 0.001), snappedf(p.y, 0.001), snappedf(p.z, 0.001)])
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(rows))
	f.close()
	print("TRIS %d -> %s" % [rows.size(), out])
	get_tree().quit()
