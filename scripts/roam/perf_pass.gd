class_name PerfPass
extends RefCounted
## One pass over a finished world that makes it cheaper to draw without changing how it looks
## up close: small things are not drawn from far away, tiny things cast no shadow, lamps stop
## lighting (and stop casting shadows) at a distance, and people far down the street are skipped.
## Every draw call saved here is saved again in each shadow pass.

static var _level := 2


static func apply(root: Node) -> Dictionary:
	# "Ground detail" decides how much is traded away. Full (Ultra): nothing is hidden with
	# distance and nothing loses its shadow or its roundness. More (High): things last much
	# further than before. Some and Off: speed first.
	_level = clampi(int(Settings.gfx.get("detail", 2)), 0, 3)
	var k: float = [0.75, 0.9, 1.7, 3.0][_level]
	var stats := {"small": 0, "noshadow": 0, "lights": 0, "people": 0}
	stats["merged"] = merge_static(root)
	_walk(root, stats, k, false)
	return stats


## A house built board by board is thousands of little boxes, each one its own draw call.
## Inside a container marked "static_boxes" (nothing in it ever moves), every plain box that
## shares a material is welded into one mesh. It looks the same and draws in a handful of calls.
static func merge_static(root: Node) -> int:
	var total := 0
	for h in root.find_children("*", "Node3D", true, false):
		if h.has_meta("static_boxes"):
			total += _merge_under(h as Node3D)
	return total


static func _merge_under(h: Node3D) -> int:
	var groups := {}
	for n in h.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not (mi.mesh is BoxMesh) or mi.get_child_count() > 0 or mi.get_script() != null or not mi.is_visible_in_tree() or not mi.get_groups().is_empty() or mi.has_meta("keep"):
			continue
		var mat: Material = mi.material_override if mi.material_override != null else (mi.mesh as BoxMesh).material
		if mat == null or _glows(mi) or mi.transparency > 0.0:
			continue
		var key := "%d/%d" % [mat.get_instance_id(), mi.cast_shadow]
		if not groups.has(key):
			groups[key] = {"mat": mat, "shadow": mi.cast_shadow, "nodes": []}
		(groups[key]["nodes"] as Array).append(mi)
	var merged := 0
	var inv := h.global_transform.affine_inverse()
	for key in groups:
		var nodes: Array = groups[key]["nodes"]
		if nodes.size() < 6:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi in nodes:
			st.append_from((mi as MeshInstance3D).mesh, 0, inv * (mi as MeshInstance3D).global_transform)
		var one := MeshInstance3D.new()
		one.mesh = st.commit()
		one.material_override = groups[key]["mat"]
		one.cast_shadow = groups[key]["shadow"]
		one.set_meta("far", true)   # a whole house: never culled by the small-things rule
		h.add_child(one)
		for mi in nodes:
			(mi as Node).queue_free()
		merged += nodes.size()
	return merged


## A bush the size of a football does not need four thousand triangles to look round.
## Balls, tubes and rings are built with as many sides as their size on screen can show.
static func _round_less(mesh: Mesh, big: float, stats: Dictionary) -> void:
	if mesh is SphereMesh:
		var sm := mesh as SphereMesh
		var seg := 10 if big < 1.2 else (16 if big < 4.0 else (24 if big < 12.0 else 40))
		if sm.radial_segments > seg:
			sm.radial_segments = seg
			sm.rings = maxi(4, seg / 2)
			stats["rounded"] = int(stats.get("rounded", 0)) + 1
	elif mesh is CylinderMesh:
		var cm := mesh as CylinderMesh
		var segc := 8 if big < 0.8 else (12 if big < 3.5 else 20)
		if cm.radial_segments > segc:
			cm.radial_segments = segc
			stats["rounded"] = int(stats.get("rounded", 0)) + 1
		if cm.rings > 1:
			cm.rings = 1
	elif mesh is TorusMesh:
		var tm := mesh as TorusMesh
		var rr := 24 if big < 3.0 else 40
		if tm.rings > rr:
			tm.rings = rr
		if tm.ring_segments > 8:
			tm.ring_segments = 8
			stats["rounded"] = int(stats.get("rounded", 0)) + 1
	elif mesh is CapsuleMesh:
		var cap := mesh as CapsuleMesh
		if cap.radial_segments > 12:
			cap.radial_segments = 12
			cap.rings = 4


static func _glows(g: GeometryInstance3D) -> bool:
	var m: Material = g.material_override
	if m == null and g is MeshInstance3D and (g as MeshInstance3D).mesh and (g as MeshInstance3D).mesh.get_surface_count() > 0:
		m = (g as MeshInstance3D).get_active_material(0)
	if m is BaseMaterial3D:
		return (m as BaseMaterial3D).emission_enabled or (m as BaseMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
	return m is ShaderMaterial


static func _walk(n: Node, stats: Dictionary, k: float, in_person: bool) -> void:
	if n is CanvasItem or n is CanvasLayer or n is LumenSpirit:
		return
	var person := in_person or n is RoamFigure
	if n is Light3D and not (n is DirectionalLight3D):
		var l := n as Light3D
		if not l.distance_fade_enabled:
			var reach := 12.0
			if l is OmniLight3D:
				reach = (l as OmniLight3D).omni_range
			elif l is SpotLight3D:
				reach = (l as SpotLight3D).spot_range
			l.distance_fade_enabled = true
			l.distance_fade_begin = maxf(42.0, reach * 3.5) * k
			l.distance_fade_length = 14.0
			l.distance_fade_shadow = 26.0 * k
			stats["lights"] += 1
	elif n is GeometryInstance3D and not (n is Label3D) and not (n is SpriteBase3D) and not n.has_meta("far"):
		var g := n as GeometryInstance3D
		if _level >= 3:
			pass                # Full: everything is drawn, however far or small
		elif person:
			# Somebody a block and a half away is a few pixels tall.
			if g.visibility_range_end == 0.0:
				g.visibility_range_end = 95.0 * k
				g.visibility_range_end_margin = 6.0
				stats["people"] += 1
		elif g.visibility_range_end == 0.0 and (g is MeshInstance3D):
			var size: Vector3 = g.get_aabb().size * g.global_transform.basis.get_scale().abs()
			var big := maxf(size.x, maxf(size.y, size.z))
			if _level <= 1:
				_round_less((g as MeshInstance3D).mesh, big, stats)
			if big > 0.0 and big < 3.2:
				# Things that glow are seen from further off (a lamp at night), so they stay longer.
				var far := clampf(big * 42.0, 40.0, 150.0) * k
				if _glows(g):
					far = maxf(far * 2.2, 120.0 * k)
				g.visibility_range_end = far
				g.visibility_range_end_margin = 6.0
				g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				stats["small"] += 1
			if big > 0.0 and big < (0.75 if _level <= 1 else 0.3) and g.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
				g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				stats["noshadow"] += 1
	for c in n.get_children():
		_walk(c, stats, k, person)


## Dev: where do the triangles live? Prints the heaviest kinds of thing in a world.
static func census(root: Node) -> void:
	var by := {}
	var cache := {}
	_count(root, by, cache, "")
	var keys: Array = by.keys()
	keys.sort_custom(func(a, b): return int(by[a][0]) > int(by[b][0]))
	var total := 0
	for k in keys:
		total += int(by[k][0])
	print("CENSUS total ", total / 1000, "k triangles in ", keys.size(), " kinds")
	for i in mini(14, keys.size()):
		print("CENSUS  %6dk  x%-5d %s" % [int(by[keys[i]][0]) / 1000, int(by[keys[i]][1]), str(keys[i])])


static func _tris(mesh: Mesh, cache: Dictionary) -> int:
	if cache.has(mesh):
		return cache[mesh]
	var n := 0
	if mesh is ArrayMesh:
		for i in mesh.get_surface_count():
			var il := (mesh as ArrayMesh).surface_get_array_index_len(i)
			n += (il if il > 0 else (mesh as ArrayMesh).surface_get_array_len(i)) / 3
	else:
		n = mesh.get_faces().size() / 3
	cache[mesh] = n
	return n


static func _count(n: Node, by: Dictionary, cache: Dictionary, group: String) -> void:
	if n is CanvasItem or n is CanvasLayer:
		return
	var g := group
	if n is RoamFigure:
		g = "people"
	if n is MeshInstance3D and (n as MeshInstance3D).mesh and (n as Node3D).is_visible_in_tree():
		var mesh := (n as MeshInstance3D).mesh
		var key := g
		if key == "":
			key = mesh.resource_path.get_file() if mesh.resource_path != "" else (mesh.get_class() + " " + str(n.get_parent().name).rstrip("0123456789@"))
		var e: Array = by.get(key, [0, 0])
		by[key] = [int(e[0]) + _tris(mesh, cache), int(e[1]) + 1]
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh and (n as MultiMeshInstance3D).multimesh.mesh:
		var mm := (n as MultiMeshInstance3D).multimesh
		var key2 := "multimesh " + str(n.name).rstrip("0123456789@")
		var e2: Array = by.get(key2, [0, 0])
		by[key2] = [int(e2[0]) + _tris(mm.mesh, cache) * mm.instance_count, int(e2[1]) + 1]
	for c in n.get_children():
		_count(c, by, cache, g)
