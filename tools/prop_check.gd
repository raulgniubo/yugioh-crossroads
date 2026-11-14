extends SceneTree
# Dev: what the pre-made models are made of. godot --headless -s tools/prop_check.gd
func _init() -> void:
	var dir := DirAccess.open("res://assets/models/city")
	for f in dir.get_files():
		if not f.ends_with(".glb"):
			continue
		var ps: PackedScene = load("res://assets/models/city/" + f)
		var inst := ps.instantiate()
		var out := f + ":"
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = (mi as MeshInstance3D).mesh
			for i in mesh.get_surface_count():
				var m := mesh.surface_get_material(i) as BaseMaterial3D
				var arr := mesh.surface_get_arrays(i)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var idx = arr[Mesh.ARRAY_INDEX]
				var tris: int = (idx.size() if idx != null else verts.size()) / 3
				# How many triangles share their centre with another one (to a tenth of a millimetre
				# of the model's size): the sign of a doubled surface.
				var seen := {}
				var dup := 0
				var box := mesh.get_aabb()
				var q := maxf(box.size.length(), 0.001) / 4000.0
				for t in tris:
					var a: Vector3 = verts[idx[t * 3]] if idx != null else verts[t * 3]
					var b: Vector3 = verts[idx[t * 3 + 1]] if idx != null else verts[t * 3 + 1]
					var c: Vector3 = verts[idx[t * 3 + 2]] if idx != null else verts[t * 3 + 2]
					var ctr := ((a + b + c) / 3.0 / q).round()
					if seen.has(ctr):
						dup += 1
					seen[ctr] = true
				out += " tris=%d dup=%d cull=%d transp=%d" % [tris, dup, m.cull_mode if m else -1, m.transparency if m else -1]
		print(out)
		inst.free()
	quit()
