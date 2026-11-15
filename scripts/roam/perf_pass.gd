class_name PerfPass
extends RefCounted
## One pass over a finished world that makes it cheaper to draw without changing how it looks
## up close: small things are not drawn from far away, tiny things cast no shadow, lamps stop
## lighting (and stop casting shadows) at a distance, and people far down the street are skipped.
## Every draw call saved here is saved again in each shadow pass.

static var _level := 2


static func apply(root: Node) -> Dictionary:
	# "Ground detail" decides how much is traded away. Full (Ultra): small things are only left
	# out from so far away that they are less than a pixel or two. More (High): a little sooner.
	# Some and Off: speed first. On the Max preset nothing is ever left out.
	_level = clampi(int(Settings.gfx.get("detail", 2)), 0, 3)
	var k: float = [0.75, 0.9, 1.7, 3.0][_level]
	var stats := {"small": 0, "noshadow": 0, "lights": 0, "people": 0}
	# (Before anything is joined or shared: the pieces are still themselves here.)
	stats["unfight"] = settle(root)
	stats["merged"] = merge_static(root)
	_one_mat.clear()
	if not ("--no-share" in OS.get_cmdline_user_args()):      # dev: to measure what sharing saves
		stats.merge(share(root))
	_walk(root, stats, k, false)
	return stats


## No flicker. Two surfaces lying in the same plane, one over the other, cannot both win: the
## graphics card picks one per pixel and the pick changes as the camera moves, which is the
## shimmer on a sign set flush into a wall or a mark painted level with the ground. Here every
## such pair among the built pieces is found (boxes and flat panels that stand upright, at any
## turn), and the smaller piece is brought a few millimetres in front: a box grows on that one
## side (its other sides stay where they are), a flat panel moves out. Bigger overlaps get a
## bigger step, because far away a few millimetres are not enough for the card to tell apart.
## Returns how many faces were fixed.
static func unfight(root: Node, report := false, dry := false) -> int:
	var frames := {}       # turn key -> {"f": Basis, "faces": [6 lists of [coord, lo_a, hi_a, lo_b, hi_b, node, volume, flat]]}
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.is_queued_for_deletion() or not mi.is_visible_in_tree() or mi.get_script() != null or mi.has_meta("keep") or _moves(mi, root):
			continue
		var flat_n := Vector3.ZERO      # which way a flat panel faces (its own axes)
		if mi.mesh is PlaneMesh:
			flat_n = [Vector3.RIGHT, Vector3.UP, Vector3.BACK][(mi.mesh as PlaneMesh).orientation]
		elif mi.mesh is QuadMesh:
			flat_n = [Vector3.RIGHT, Vector3.UP, Vector3.BACK][(mi.mesh as QuadMesh).orientation]
		elif not (mi.mesh is BoxMesh or mi.mesh is CylinderMesh):
			continue
		var round_one := mi.mesh is CylinderMesh       # (a lid, a disc, a plinth: only its top can lie level with something)
		var gt := mi.global_transform
		# Upright: one of its axes points straight up or down, the other two lie level.
		var up_n := 0
		var level_col := Vector3.ZERO
		var okay := true
		for k in 3:
			var col: Vector3 = gt.basis[k]
			var len := col.length()
			if len < 0.00001:
				okay = false
			elif absf(col.y) > len * 0.99999:
				up_n += 1
			elif absf(col.y) < len * 0.002:
				level_col = col
			else:
				okay = false
		if not okay or up_n != 1:
			continue
		if round_one and absf(gt.basis.y.y) < gt.basis.y.length() * 0.99999:
			continue
		var turn := fposmod(atan2(level_col.z, level_col.x), PI * 0.5)
		var tkey := int(round(rad_to_deg(turn) * 100.0)) % 9000
		if round_one:
			turn = 0.0
			tkey = 0
		if not frames.has(tkey):
			frames[tkey] = {"f": Basis.IDENTITY if tkey == 0 else Basis(Vector3.UP, -turn), "faces": [[], [], [], [], [], []]}
		var fr: Dictionary = frames[tkey]
		var f: Basis = fr["f"]
		var bb: AABB = Transform3D(f.inverse(), Vector3.ZERO) * gt * mi.get_aabb()
		var lo := bb.position
		var hi := bb.end
		var vol := maxf(bb.size.x, 0.001) * maxf(bb.size.y, 0.001) * maxf(bb.size.z, 0.001)
		var facing := Vector3.ZERO
		if flat_n != Vector3.ZERO:
			facing = (f.inverse() * (gt.basis * flat_n)).normalized()
		for ax in 3:
			var a := (ax + 1) % 3
			var b := (ax + 2) % 3
			if hi[a] - lo[a] < 0.02 or hi[b] - lo[b] < 0.02:
				continue
			if flat_n != Vector3.ZERO:
				# A panel has one face: the side it looks out of.
				if absf(facing[ax]) > 0.9:
					fr["faces"][ax * 2 + (1 if facing[ax] > 0.0 else 0)].append([hi[ax] if facing[ax] > 0.0 else lo[ax], lo[a], hi[a], lo[b], hi[b], mi, vol, true])
				continue
			if round_one and ax != 1:
				continue
			if ax != 1:      # (the underside of a box is not something anyone sees)
				fr["faces"][ax * 2].append([lo[ax], lo[a], hi[a], lo[b], hi[b], mi, vol, false])
			fr["faces"][ax * 2 + 1].append([hi[ax], lo[a], hi[a], lo[b], hi[b], mi, vol, false])
	var done := {}
	var count := 0
	for tkey in frames:
		var f2: Basis = frames[tkey]["f"]
		for fi in 6:
			var list: Array = frames[tkey]["faces"][fi]
			list.sort_custom(func(x, y): return x[0] < y[0])
			var ax2 := fi / 2
			var sgn := 1.0 if fi % 2 == 1 else -1.0
			var out_dir := Vector3.ZERO
			out_dir[ax2] = sgn
			var out_w := (f2 * out_dir).normalized()
			for i in list.size():
				var f1: Array = list[i]
				var j := i + 1
				while j < list.size() and list[j][0] - f1[0] < 0.0035:
					var fb: Array = list[j]
					j += 1
					if f1[5] == fb[5]:
						continue
					var ov_a := minf(f1[2], fb[2]) - maxf(f1[1], fb[1])
					var ov_b := minf(f1[4], fb[4]) - maxf(f1[3], fb[3])
					if ov_a < 0.03 or ov_b < 0.03 or ov_a * ov_b < 0.004:
						continue
					if _same_look(f1[5], fb[5]):
						continue
					# The panel goes in front of the box; of two alike, the smaller one does.
					var first_small: bool = f1[6] <= fb[6]
					if f1[7] != fb[7]:
						first_small = f1[7]
					var sm: Array = f1 if first_small else fb
					var bg: Array = fb if first_small else f1
					var small: MeshInstance3D = sm[5]
					var key := "%d/%d/%d" % [small.get_instance_id(), tkey, fi]
					if done.has(key):
						continue
					done[key] = true
					var want := clampf(sqrt(ov_a * ov_b) * 0.004, 0.005, 0.02)
					var step: float = want - (sm[0] - bg[0]) * sgn
					if step <= 0.0:
						continue
					var gt2 := small.global_transform
					if dry:
						pass
					elif sm[7] or small.get_child_count() > 0:
						gt2.origin += out_w * step
					else:
						var best := 0
						for k in 3:
							if absf(gt2.basis[k].normalized().dot(out_w)) > absf(gt2.basis[best].normalized().dot(out_w)):
								best = k
						var size_now := maxf(absf(sm[0] - _other_side(small, f2, ax2, sm[0])), 0.001)
						gt2.basis[best] = gt2.basis[best] * ((size_now + step) / size_now)
						gt2.origin += out_w * step * 0.5
					if not dry:
						small.global_transform = gt2
					count += 1
					if report:
						var big: MeshInstance3D = bg[5]
						print("UNFIGHT ", small.get_path(), " ", (small.global_transform * small.get_aabb()).size.snapped(Vector3.ONE * 0.01), " @", small.global_position.snapped(Vector3.ONE * 0.001), " turn ", tkey, " axis ", ax2, " side ", fi % 2, " at ", snappedf(f1[0], 0.0001), "/", snappedf(fb[0], 0.0001), " ov ", snappedf(ov_a * ov_b, 0.01), " WITH ", big.get_path(), " ", (big.global_transform * big.get_aabb()).size.snapped(Vector3.ONE * 0.01), " @", big.global_position.snapped(Vector3.ONE * 0.001))
	return count


## The same, until nothing is left to fix. (A piece brought in front of one neighbour can land
## level with another, so a few rounds settle it.)
static func settle(root: Node) -> int:
	var fought := 0
	if "--no-unfight" in OS.get_cmdline_user_args():      # dev: to see what it was like before
		return 0
	for round_i in 8:
		var got := unfight(root, "--unfight-list" in OS.get_cmdline_user_args())
		fought += got
		if got == 0:
			break
	return fought


## Is this piece, or anything it hangs from, marked as something that moves?
static func _moves(n: Node, root: Node) -> bool:
	while n != null and n != root:
		if n.has_meta("moves"):
			return true
		n = n.get_parent()
	return false


## Where the opposite side of a box is, along one axis of the frame it stands in.
static func _other_side(mi: MeshInstance3D, f: Basis, ax: int, this_side: float) -> float:
	var bb: AABB = Transform3D(f.inverse(), Vector3.ZERO) * mi.global_transform * mi.get_aabb()
	return bb.position[ax] if absf(bb.end[ax] - this_side) < absf(bb.position[ax] - this_side) else bb.end[ax]


static func _same_look(a: MeshInstance3D, b: MeshInstance3D) -> bool:
	var ma: Material = a.get_active_material(0)
	var mb: Material = b.get_active_material(0)
	if ma == mb:
		return true
	if ma is StandardMaterial3D and mb is StandardMaterial3D:
		var sa := ma as StandardMaterial3D
		var sb := mb as StandardMaterial3D
		return sa.albedo_color.is_equal_approx(sb.albedo_color) and sa.emission_enabled == sb.emission_enabled and (not sa.emission_enabled or sa.emission.is_equal_approx(sb.emission)) and sa.albedo_texture == sb.albedo_texture and sa.transparency == sb.transparency
	return false


## One box, many places. A city built from code is thousands of boxes, poles and balls, and
## each one was made as its own mesh with its own material, so the renderer had to treat every
## piece as a separate thing. Here every plain box becomes the SAME box (sized by its node
## instead), and so on for poles, balls and flat panels, and materials that are identical in
## every value become one material. Pieces that share a mesh and a material are drawn together
## in one call (and all of them together in each shadow pass). Nothing looks different.
static var _shared := {}       # key -> Mesh
static var _one_mat := {}      # material key -> Material


static func share(root: Node) -> Dictionary:
	var out := {"shared": 0, "one_mat": 0}
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.get_script() != null or mi.has_meta("keep"):
			continue
		if not (mi.mesh is PrimitiveMesh) or mi.mesh.resource_path != "":
			_one_material(mi, out)
			continue
		var pm := mi.mesh as PrimitiveMesh
		var mat: Material = mi.material_override
		if mat == null:
			mat = mi.get_surface_override_material(0)
		if mat == null:
			mat = pm.material
		var see_through := mat is ShaderMaterial or (mat is BaseMaterial3D and ((mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or (mat as BaseMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED))
		var local := mat is BaseMaterial3D and (mat as BaseMaterial3D).uv1_triplanar and not (mat as BaseMaterial3D).uv1_world_triplanar
		var key := ""
		var grow := Vector3.ONE
		if pm.flip_faces or pm.custom_aabb != AABB() or pm.add_uv2 or see_through or local:
			pass            # markers, glass, beams: these may be sized by code later, so they keep their own size
		elif pm is BoxMesh and (pm as BoxMesh).subdivide_width == 0 and (pm as BoxMesh).subdivide_height == 0 and (pm as BoxMesh).subdivide_depth == 0:
			key = "box"
			grow = (pm as BoxMesh).size
		elif pm is CylinderMesh:
			var c := pm as CylinderMesh
			if c.bottom_radius > 0.0005 and c.height > 0.0005:
				var taper := snappedf(c.top_radius / c.bottom_radius, 0.01)
				key = "cyl/%d/%d/%s/%s/%.2f" % [c.radial_segments, c.rings, str(c.cap_top), str(c.cap_bottom), taper]
				grow = Vector3(c.bottom_radius * 2.0, c.height, c.bottom_radius * 2.0)
		elif pm is SphereMesh and not (pm as SphereMesh).is_hemisphere:
			var sp := pm as SphereMesh
			key = "ball/%d/%d" % [sp.radial_segments, sp.rings]
			grow = Vector3(sp.radius * 2.0, sp.height, sp.radius * 2.0)
		elif pm is QuadMesh and (pm as QuadMesh).orientation == PlaneMesh.FACE_Z and (pm as QuadMesh).center_offset == Vector3.ZERO and (pm as QuadMesh).subdivide_width == 0 and (pm as QuadMesh).subdivide_depth == 0:
			key = "quad"
			grow = Vector3((pm as QuadMesh).size.x, (pm as QuadMesh).size.y, 1.0)
		elif pm is PlaneMesh and not (pm is QuadMesh) and (pm as PlaneMesh).orientation == PlaneMesh.FACE_Y and (pm as PlaneMesh).center_offset == Vector3.ZERO and (pm as PlaneMesh).subdivide_width == 0 and (pm as PlaneMesh).subdivide_depth == 0:
			key = "plane"
			grow = Vector3((pm as PlaneMesh).size.x, 1.0, (pm as PlaneMesh).size.y)
		if key != "" and (grow.x < 0.0005 or grow.y < 0.0005 or grow.z < 0.0005):
			key = ""
		if key == "":
			# Any other shape: the same shape with the same numbers is still shared, as it is.
			key = _prim_key(pm)
			grow = Vector3.ONE
		if not _shared.has(key):
			_shared[key] = _unit_mesh(pm, grow)
		if mat != null and mi.material_override == null:
			mi.material_override = mat
		mi.mesh = _shared[key]
		if grow != Vector3.ONE:
			mi.transform = mi.transform * Transform3D(Basis.from_scale(grow), Vector3.ZERO)
		out["shared"] += 1
		_one_material(mi, out)
	return out


## The shared version of a shape: the same shape at size one (or itself, when it is not sized).
static func _unit_mesh(pm: PrimitiveMesh, grow: Vector3) -> Mesh:
	if grow == Vector3.ONE:
		var same := pm.duplicate() as PrimitiveMesh
		same.material = null
		return same
	if pm is BoxMesh:
		return BoxMesh.new()
	if pm is CylinderMesh:
		var c := pm as CylinderMesh
		var u := CylinderMesh.new()
		u.bottom_radius = 0.5
		u.top_radius = 0.5 * snappedf(c.top_radius / c.bottom_radius, 0.01)
		u.height = 1.0
		u.radial_segments = c.radial_segments
		u.rings = c.rings
		u.cap_top = c.cap_top
		u.cap_bottom = c.cap_bottom
		return u
	if pm is SphereMesh:
		var b := SphereMesh.new()
		b.radius = 0.5
		b.height = 1.0
		b.radial_segments = (pm as SphereMesh).radial_segments
		b.rings = (pm as SphereMesh).rings
		return b
	if pm is QuadMesh:
		return QuadMesh.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2.ONE
	return pl


static func _prim_key(pm: PrimitiveMesh) -> String:
	var parts: PackedStringArray = [pm.get_class()]
	for p in pm.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_STORAGE == 0:
			continue
		var name := str(p["name"])
		if name in ["resource_name", "resource_path", "resource_local_to_scene", "script", "material"]:
			continue
		parts.append(str(pm.get(name)))
	return "/".join(parts)


## Plain solid materials with the same values everywhere become one. Anything that glows, is
## see-through or runs its own shader is left alone: those are the ones code changes later
## (lamps at night, traffic lights, screens).
static func _one_material(mi: MeshInstance3D, out: Dictionary) -> void:
	var m: Material = mi.material_override
	if not (m is StandardMaterial3D) or m.resource_path != "":
		return
	var b := m as StandardMaterial3D
	if b.emission_enabled or b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or b.has_meta("keep"):
		return
	var key := mat_key(b)
	if not _one_mat.has(key) or not is_instance_valid(_one_mat[key]):
		_one_mat[key] = b
	elif _one_mat[key] != b:
		mi.material_override = _one_mat[key]
		out["one_mat"] += 1


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
		if Settings.gfx_preset == Settings.GFX_PRESETS.size() - 1:
			pass                # Max: everything is drawn, however far or small
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


## Dev: what are the pieces made of? Mesh kinds, how many could share a mesh or a material.
static func kinds(root: Node) -> void:
	var by_class := {}
	var mats := {}
	var mat_keys := {}
	var free_boxes := 0
	var with_kids := 0
	var scripted := 0
	var total := 0
	var mat_class := {}
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var p := mi.get_parent()
		if p is Skeleton3D or (p and p.get_parent() is Skeleton3D):
			continue
		total += 1
		var c := mi.mesh.get_class()
		if mi.mesh is ArrayMesh:
			c += " (file)" if mi.mesh.resource_path != "" else " (built)"
		by_class[c] = int(by_class.get(c, 0)) + 1
		if mi.get_child_count() > 0:
			with_kids += 1
		if mi.get_script() != null:
			scripted += 1
		if mi.mesh is PrimitiveMesh and mi.get_child_count() == 0 and mi.get_script() == null:
			free_boxes += 1
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.get_active_material(s)
			if m == null:
				continue
			if mats.has(m.get_instance_id()):
				continue
			mats[m.get_instance_id()] = true
			mat_class[m.get_class()] = int(mat_class.get(m.get_class(), 0)) + 1
			mat_keys[mat_key(m)] = int(mat_keys.get(mat_key(m), 0)) + 1
	print("KINDS pieces ", total, "  with children ", with_kids, "  scripted ", scripted, "  plain primitives ", free_boxes)
	print("KINDS meshes ", by_class)
	print("KINDS materials ", mats.size(), " objects, ", mat_keys.size(), " really different  ", mat_class)


## Two materials with the same key draw the same.
static func mat_key(m: Material) -> String:
	if not (m is BaseMaterial3D) or m.resource_path != "":
		return str(m.get_instance_id())
	var parts: PackedStringArray = []
	for p in m.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_STORAGE == 0:
			continue
		var name := str(p["name"])
		if name in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
			continue
		var v = m.get(name)
		if v is Object:
			parts.append("%s=#%d" % [name, (v as Object).get_instance_id()])
		else:
			parts.append("%s=%s" % [name, str(v)])
	return m.get_class() + "|" + "|".join(parts)
