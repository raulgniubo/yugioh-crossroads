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
			# (0.74.2) the bone that moves each triangle most, by name (hands: for mending a mask)
			var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES] if arr[Mesh.ARRAY_BONES] != null else PackedInt32Array()
			var wts: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS] if arr[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
			var per := bones.size() / maxi(v.size(), 1)
			var skin: Skin = (mi as MeshInstance3D).skin
			var sk := (mi as MeshInstance3D).get_node_or_null((mi as MeshInstance3D).skeleton) as Skeleton3D
			var bone_of := func(vi: int) -> String:
				if per <= 0:
					return ""
				var best := 0
				for k in per:
					if wts[vi * per + k] > wts[vi * per + best]:
						best = k
				var bi := bones[vi * per + best]
				if skin != null and bi < skin.get_bind_count():
					var nm := String(skin.get_bind_name(bi))
					if nm == "" and sk != null and skin.get_bind_bone(bi) >= 0:
						nm = sk.get_bone_name(skin.get_bind_bone(bi))
					return nm
				return sk.get_bone_name(bi) if sk != null and bi < sk.get_bone_count() else ""
			for i in range(0, idx.size(), 3):
				var a := idx[i]
				var b := idx[i + 1]
				var c := idx[i + 2]
				var p: Vector3 = (xf * ((v[a] + v[b] + v[c]) / 3.0)) * scale_up
				rows.append([snappedf(uv[a].x, 0.0001), snappedf(uv[a].y, 0.0001), snappedf(uv[b].x, 0.0001), snappedf(uv[b].y, 0.0001), snappedf(uv[c].x, 0.0001), snappedf(uv[c].y, 0.0001),
					snappedf(p.x, 0.001), snappedf(p.y, 0.001), snappedf(p.z, 0.001), bone_of.call(a)])
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(rows))
	f.close()
	print("TRIS %d -> %s" % [rows.size(), out])
	get_tree().quit()
