class_name SatScrap
extends RefCounted
## (0.87.0) Satellite's scrap with real shapes, the broken ground, and what stands beyond the
## fence. Every repeated piece (a tyre, a drum, a sheet of tin, a wrecked car) is ONE mesh drawn
## many times, each with its own colour, so hundreds of them cost a handful of draws.
## All of it is made here by code: nothing is copied from anywhere.

const R := 40.0     # the walkable radius (ArenaDistrict.RADIUS)

const RUST := [Color(0.42, 0.22, 0.12), Color(0.36, 0.19, 0.11), Color(0.5, 0.29, 0.15), Color(0.3, 0.17, 0.12), Color(0.46, 0.27, 0.18)]
const PAINT := [Color(0.2, 0.32, 0.4), Color(0.5, 0.42, 0.18), Color(0.42, 0.14, 0.11), Color(0.55, 0.55, 0.52), Color(0.25, 0.33, 0.24), Color(0.62, 0.6, 0.55), Color(0.2, 0.22, 0.26)]


static func tint(rng: RandomNumberGenerator, rusty := 0.55) -> Color:
	if rng.randf() < rusty:
		return (RUST[rng.randi() % RUST.size()] as Color).lerp(Color(0.2, 0.14, 0.1), rng.randf() * 0.3)
	return (PAINT[rng.randi() % PAINT.size()] as Color).lerp(RUST[rng.randi() % RUST.size()], rng.randf_range(0.1, 0.45))


static func rot(yaw: float, pitch := 0.0, roll := 0.0) -> Basis:
	return Basis.from_euler(Vector3(pitch, yaw, roll))


# ====================================================================== building one mesh

## Triangles with a colour on every corner. Faces are given by their corners and the way they
## look; the winding is worked out, so a face can never come out inside out.
class MB:
	var st := SurfaceTool.new()

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	func tri(p0: Vector3, p1: Vector3, p2: Vector3, n0: Vector3, n1: Vector3, n2: Vector3, col: Color) -> void:
		st.set_color(col)
		if (p1 - p0).cross(p2 - p0).dot(n0 + n1 + n2) > 0.0:
			var tp := p1
			p1 = p2
			p2 = tp
			var tn := n1
			n1 = n2
			n2 = tn
		st.set_normal(n0)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.add_vertex(p1)
		st.set_normal(n2)
		st.add_vertex(p2)

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
		tri(a, b, c, n, n, n, col)
		tri(a, c, d, n, n, n, col)

	## A box, or with `top` under 1 a box whose top face is drawn in along x (a car's cabin).
	func box(size: Vector3, at: Vector3, b: Basis, col: Color, top := 1.0, top_shift := 0.0) -> void:
		var h := size / 2.0
		var pts: Array = []
		for sy: float in [-1.0, 1.0]:
			var k := top if sy > 0.0 else 1.0
			var sh := top_shift if sy > 0.0 else 0.0
			pts.append(at + b * Vector3(-h.x * k + sh, sy * h.y, -h.z))
			pts.append(at + b * Vector3(h.x * k + sh, sy * h.y, -h.z))
			pts.append(at + b * Vector3(h.x * k + sh, sy * h.y, h.z))
			pts.append(at + b * Vector3(-h.x * k + sh, sy * h.y, h.z))
		for f in [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [3, 2, 6, 7], [0, 3, 7, 4], [1, 2, 6, 5]]:
			var a: Vector3 = pts[f[0]]
			var bb: Vector3 = pts[f[1]]
			var cc: Vector3 = pts[f[2]]
			var dd: Vector3 = pts[f[3]]
			var mid := (a + bb + cc + dd) / 4.0
			var n := (bb - a).cross(dd - a).normalized()
			if n.dot(mid - at) < 0.0:
				n = -n
			quad(a, bb, cc, dd, n, col)

	## A round piece standing along the basis' y: r0 at the bottom, r1 at the top.
	func cyl(r0: float, r1: float, hgt: float, at: Vector3, b: Basis, col: Color, seg := 10, lid := true, lid_col := Color(-1, 0, 0)) -> void:
		var lc := col if lid_col.r < 0.0 else lid_col
		var up := (b * Vector3.UP).normalized()
		for i in seg:
			var a0 := TAU * i / float(seg)
			var a1 := TAU * (i + 1) / float(seg)
			var d0 := b * Vector3(cos(a0), 0, sin(a0))
			var d1 := b * Vector3(cos(a1), 0, sin(a1))
			var lo0 := at + d0 * r0 - b * Vector3(0, hgt / 2.0, 0)
			var lo1 := at + d1 * r0 - b * Vector3(0, hgt / 2.0, 0)
			var hi0 := at + d0 * r1 + b * Vector3(0, hgt / 2.0, 0)
			var hi1 := at + d1 * r1 + b * Vector3(0, hgt / 2.0, 0)
			var n0 := d0.normalized()
			var n1 := d1.normalized()
			tri(lo0, lo1, hi1, n0, n1, n1, col)
			tri(lo0, hi1, hi0, n0, n1, n0, col)
			if lid:
				if r1 > 0.001:
					tri(at + b * Vector3(0, hgt / 2.0, 0), hi0, hi1, up, up, up, lc)
				if r0 > 0.001:
					tri(at - b * Vector3(0, hgt / 2.0, 0), lo0, lo1, -up, -up, -up, lc)

	## A ring lying flat in the basis (its hole along y).
	func torus(big: float, small: float, at: Vector3, b: Basis, col: Color, seg := 12, tube := 6) -> void:
		for i in seg:
			for j in tube:
				var corner: Array = []
				for q in [[0, 0], [1, 0], [1, 1], [0, 1]]:
					var u: float = TAU * (i + int(q[0])) / float(seg)
					var v: float = TAU * (j + int(q[1])) / float(tube)
					var ring := Vector3(cos(u), 0, sin(u))
					var nn := ring * cos(v) + Vector3(0, sin(v), 0)
					corner.append([at + b * (ring * big + nn * small), (b * nn).normalized()])
				tri(corner[0][0], corner[1][0], corner[2][0], corner[0][1], corner[1][1], corner[2][1], col)
				tri(corner[0][0], corner[2][0], corner[3][0], corner[0][1], corner[2][1], corner[3][1], col)

	func done(m: Material) -> ArrayMesh:
		var mesh := st.commit()
		mesh.surface_set_material(0, m)
		return mesh


static var _meshes := {}
static var _paint: StandardMaterial3D


## The one painted-metal material every piece shares (the same one the town's painted boxes use).
static func paint(c: CityBuilder) -> Material:
	if _paint == null or not is_instance_valid(_paint):
		var sh := CityBuilder.BoxBatch._shared(c.mat(Color(0.5, 0.5, 0.5), 0.9, 0.0))
		if sh.is_empty():
			var m := c.mat(Color.WHITE, 0.9, 0.0)
			m.vertex_color_use_as_albedo = true
			m.vertex_color_is_srgb = true
			_paint = m
		else:
			_paint = sh[0]
	return _paint


static func mesh(kind: String, c: CityBuilder) -> ArrayMesh:
	var key := kind + ":" + str(paint(c).get_instance_id())
	if _meshes.has(key):
		return _meshes[key]
	var W := Color.WHITE
	var dark := Color(0.16, 0.16, 0.17)
	var black := Color(0.09, 0.09, 0.1)
	var steel := Color(0.55, 0.55, 0.56)
	var I := Basis.IDENTITY
	var m := MB.new()
	match kind:
		"tyre":
			m.torus(0.3, 0.13, Vector3.ZERO, I, W, 8, 4)
		"wheel":
			m.torus(0.3, 0.13, Vector3.ZERO, I, black, 12, 6)
			m.cyl(0.19, 0.19, 0.12, Vector3.ZERO, I, steel, 10)
		"drum":
			# a band round the middle a shade off, so the ribs read without more sides
			m.cyl(0.29, 0.29, 0.88, Vector3.ZERO, I, W, 10, true, Color(0.66, 0.66, 0.66))
			m.cyl(0.302, 0.302, 0.26, Vector3.ZERO, I, Color(0.84, 0.84, 0.84), 10, false)
		"pipe":
			# one long along z, one across; the ends are dark so it reads as hollow
			m.cyl(0.5, 0.5, 1.0, Vector3.ZERO, rot(0.0, PI / 2.0), W, 10, true, black)
			m.cyl(0.56, 0.56, 0.05, Vector3(0, 0, 0.44), rot(0.0, PI / 2.0), Color(0.85, 0.85, 0.85), 10, false)
		"sheet":
			# corrugated tin, one long along z, one wide: ridges you can see from both sides
			var ridges := 7
			for i in ridges:
				var x0 := -0.5 + i / float(ridges)
				var x1 := -0.5 + (i + 1) / float(ridges)
				var y0 := 0.035 if i % 2 == 0 else -0.035
				var y1 := -y0
				var a := Vector3(x0, y0, -0.5)
				var b := Vector3(x1, y1, -0.5)
				var cc := Vector3(x1, y1, 0.5)
				var d := Vector3(x0, y0, 0.5)
				var n := (b - a).cross(d - a).normalized()
				if n.y < 0.0:
					n = -n
				m.quad(a, b, cc, d, n, W)
				m.quad(a - n * 0.012, b - n * 0.012, cc - n * 0.012, d - n * 0.012, -n, Color(0.8, 0.8, 0.8))
		"beam":
			m.box(Vector3(0.22, 0.03, 1.0), Vector3(0, 0.11, 0), I, W)
			m.box(Vector3(0.22, 0.03, 1.0), Vector3(0, -0.11, 0), I, W)
			m.box(Vector3(0.03, 0.2, 1.0), Vector3.ZERO, I, Color(0.86, 0.86, 0.86))
		"fridge":
			m.box(Vector3(0.7, 1.6, 0.65), Vector3(0, 0.8, 0), I, W)
			m.box(Vector3(0.66, 0.02, 0.02), Vector3(0, 1.08, 0.33), I, dark)
			m.box(Vector3(0.04, 0.3, 0.05), Vector3(0.27, 1.32, 0.35), I, steel)
			m.box(Vector3(0.04, 0.5, 0.05), Vector3(0.27, 0.7, 0.35), I, steel)
			m.box(Vector3(0.6, 0.5, 0.02), Vector3(0, 0.3, -0.33), I, dark)
		"washer":
			m.box(Vector3(0.62, 0.86, 0.6), Vector3(0, 0.43, 0), I, W)
			m.cyl(0.2, 0.2, 0.03, Vector3(0, 0.4, 0.31), rot(0.0, PI / 2.0), black, 8)
			m.cyl(0.24, 0.24, 0.02, Vector3(0, 0.4, 0.305), rot(0.0, PI / 2.0), steel, 8)
			m.box(Vector3(0.58, 0.1, 0.02), Vector3(0, 0.77, 0.305), I, dark)
		"wreck", "van":
			# a car with nothing left to take off it: body, cabin, dark where the glass was
			var van := kind == "van"
			var ln := 4.5 if van else 4.0
			var body_h := 0.95 if van else 0.55
			m.box(Vector3(ln, body_h, 1.7), Vector3(0, 0.3 + body_h / 2.0, 0), I, W)
			var cab_l := 2.9 if van else 2.1
			var cab_h := 0.75 if van else 0.55
			var cab_x := -0.55 if van else -0.2
			var cab_y := 0.3 + body_h + cab_h / 2.0
			m.box(Vector3(cab_l, cab_h, 1.6), Vector3(cab_x, cab_y, 0), I, W, 0.86 if van else 0.7, 0.0 if van else -0.1)
			for sz: float in [-1.0, 1.0]:
				m.box(Vector3(cab_l * 0.62, cab_h * 0.6, 0.02), Vector3(cab_x - (0.0 if van else 0.08), cab_y + 0.03, sz * 0.805), I, black)
				for wx: float in [-ln * 0.3, ln * 0.3]:
					m.box(Vector3(0.78, 0.4, 0.04), Vector3(wx, 0.42, sz * 0.84), I, black)
			m.box(Vector3(0.02, cab_h * 0.6, 1.3), Vector3(cab_x + cab_l * (0.42 if van else 0.37), cab_y + 0.02, 0), rot(0.0, 0.0, 0.0 if van else -0.5), black)
			m.box(Vector3(0.02, cab_h * 0.55, 1.3), Vector3(cab_x - cab_l * (0.44 if van else 0.4), cab_y + 0.02, 0), rot(0.0, 0.0, 0.0 if van else 0.45), black)
			m.box(Vector3(0.12, 0.16, 1.74), Vector3(ln / 2.0, 0.42, 0), I, steel)
			m.box(Vector3(0.12, 0.16, 1.74), Vector3(-ln / 2.0, 0.42, 0), I, dark)
			for sz2: float in [-1.0, 1.0]:
				m.box(Vector3(0.04, 0.14, 0.3), Vector3(ln / 2.0 + 0.01, 0.62, sz2 * 0.6), I, black)
			# two wheels left, on the same side: it sits crooked
			for wx2: float in [-ln * 0.3, ln * 0.3]:
				m.torus(0.24, 0.11, Vector3(wx2, 0.3, 0.8), rot(0.0, PI / 2.0), black, 8, 4)
				m.cyl(0.15, 0.15, 0.1, Vector3(wx2, 0.3, 0.8), rot(0.0, PI / 2.0), steel, 8)
			if not van:
				m.box(Vector3(1.0, 0.03, 1.5), Vector3(ln * 0.33, 0.3 + body_h + 0.24, 0), rot(0.0, 0.0, 0.6), W)      # the hood left standing open
		"chunk":
			# a lump of broken concrete: no two faces square to each other
			var pts := [Vector3(-0.5, 0, -0.42), Vector3(0.46, 0, -0.5), Vector3(0.5, 0, 0.38), Vector3(-0.38, 0, 0.5),
					Vector3(-0.3, 0.62, -0.22), Vector3(0.34, 0.8, -0.3), Vector3(0.22, 0.5, 0.3), Vector3(-0.26, 0.7, 0.18)]
			for f in [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [3, 2, 6, 7], [0, 3, 7, 4], [1, 2, 6, 5]]:
				var a2: Vector3 = pts[f[0]]
				var b2: Vector3 = pts[f[1]]
				var c2: Vector3 = pts[f[2]]
				var d2: Vector3 = pts[f[3]]
				var n2 := (b2 - a2).cross(d2 - a2).normalized()
				if n2.dot((a2 + b2 + c2 + d2) / 4.0 - Vector3(0, 0.35, 0)) < 0.0:
					n2 = -n2
				m.tri(a2, b2, c2, n2, n2, n2, W)
				m.tri(a2, c2, d2, n2, n2, n2, W)
		"slab":
			# a piece of the old floor: a chipped outline, the broken edge darker than the top,
			# and the iron that was in it sticking out of one side
			var outline := [Vector2(-0.5, -0.42), Vector2(0.08, -0.5), Vector2(0.5, -0.3), Vector2(0.44, 0.34), Vector2(-0.1, 0.5), Vector2(-0.5, 0.28)]
			var edge_col := Color(0.62, 0.61, 0.6)
			for k in outline.size():
				var p0: Vector2 = outline[k]
				var p1: Vector2 = outline[(k + 1) % outline.size()]
				m.tri(Vector3(0, 0.5, 0), Vector3(p0.x, 0.5, p0.y), Vector3(p1.x, 0.5, p1.y), Vector3.UP, Vector3.UP, Vector3.UP, W)
				var nrm := Vector3(p1.y - p0.y, 0, p0.x - p1.x).normalized()
				if nrm.dot(Vector3((p0.x + p1.x) / 2.0, 0, (p0.y + p1.y) / 2.0)) < 0.0:
					nrm = -nrm
				m.quad(Vector3(p0.x, -0.5, p0.y), Vector3(p1.x, -0.5, p1.y), Vector3(p1.x, 0.5, p1.y), Vector3(p0.x, 0.5, p0.y), nrm, edge_col)
			for k in 4:
				m.box(Vector3(0.2, 0.1, 0.012), Vector3(0.56, 0.1 - k * 0.12, -0.2 + k * 0.14), rot(0.0, 0.0, 0.3 - k * 0.22), Color(0.45, 0.25, 0.16))
		"disc":
			m.cyl(1.0, 1.0, 1.0, Vector3.ZERO, I, W, 12)
		"cube":
			m.box(Vector3.ONE, Vector3.ZERO, I, W)
		"mound":
			# a heap of earth: a wide cone with its top knocked off, a little lopsided
			m.cyl(1.0, 0.24, 1.0, Vector3(0, 0.5, 0), I, W, 11)
		_:
			m.box(Vector3.ONE, Vector3.ZERO, I, W)
	var out := m.done(paint(c))
	_meshes[key] = out
	return out


## Pieces waiting to be drawn: kind -> [where, colour]. commit() makes one MultiMesh per kind.
class Kit:
	var items := {}

	func add(kind: String, xf: Transform3D, col := Color.WHITE) -> void:
		if not items.has(kind):
			items[kind] = []
		(items[kind] as Array).append([xf, col])

	func put(kind: String, at: Vector3, b: Basis, size: Vector3, col := Color.WHITE) -> void:
		add(kind, Transform3D(b * Basis.from_scale(size), at), col)

	func count() -> int:
		var n := 0
		for k in items:
			n += (items[k] as Array).size()
		return n

	func commit(c: CityBuilder, shadows := true) -> void:
		for kind in items:
			var list: Array = items[kind]
			if OS.has_environment("SAT_DEBUG"):
				print("KIT ", kind, " x", list.size(), " tris each ", SatScrap.mesh(kind, c).get_faces().size() / 3, " shadows ", shadows)
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = SatScrap.mesh(kind, c)
			mm.instance_count = list.size()
			for i in list.size():
				mm.set_instance_transform(i, list[i][0])
				mm.set_instance_color(i, list[i][1])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.name = "Scrap_" + kind
			mmi.set_meta("scrap", kind)
			# only what is big enough to throw a shadow you would miss throws one
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (shadows and kind in ["mound", "wreck", "van", "fridge", "slab"]) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			c.add_child(mmi)


static func _amount() -> float:
	return [0.45, 0.7, 1.0, 1.0][clampi(int(Settings.gfx.get("detail", 2)), 0, 3)]


# ====================================================================== the heaps

## One heap: earth with scrap bedded into it. Returns where its top is (smoke rises from some).
static func _heap(kit: Kit, rng: RandomNumberGenerator, center: Vector3, rad: float, hgt: float, rich: float) -> Vector3:
	var earth := Color(0.3, 0.255, 0.205)
	kit.put("mound", center + Vector3(0, -0.1, 0), rot(rng.randf() * TAU), Vector3(rad, hgt, rad * rng.randf_range(0.82, 1.0)), earth)
	for k in 2:
		var a := rng.randf() * TAU
		var d := rad * rng.randf_range(0.45, 0.7)
		kit.put("mound", center + Vector3(cos(a) * d, -0.1, sin(a) * d), rot(rng.randf() * TAU), Vector3(rad * rng.randf_range(0.4, 0.6), hgt * rng.randf_range(0.4, 0.7), rad * rng.randf_range(0.4, 0.6)), earth.lerp(Color(0.25, 0.21, 0.175), rng.randf()))
	# Where a point on the side of the heap is, and which way the ground tips there.
	var on_side := func(rr: float, aa: float) -> Array:
		var t := clampf(rr / rad, 0.0, 1.0)
		var y := hgt * (1.0 - t) * 0.76 if t > 0.24 else hgt * 0.58 + hgt * 0.4 * (0.24 - t)
		var out_dir := Vector3(cos(aa), 0, sin(aa))
		var slope := atan2(hgt * 0.76, rad)
		var side := out_dir.cross(Vector3.UP).normalized()
		return [center + out_dir * rr + Vector3(0, y, 0), Basis(side, -slope * 0.8)]
	var n := int(round(rich * _amount()))
	for k in int(n * 0.22):
		var s: Array = on_side.call(sqrt(rng.randf()) * rad * 1.02, rng.randf() * TAU)
		var lying := rng.randf() < 0.7
		kit.put("tyre", s[0] + Vector3(0, 0.12, 0), (s[1] as Basis) * rot(rng.randf() * TAU, rng.randf_range(-0.3, 0.3) if lying else rng.randf_range(1.1, 1.6), rng.randf_range(-0.3, 0.3)), Vector3.ONE * rng.randf_range(0.95, 1.5), Color(0.075, 0.075, 0.08).lerp(Color(0.14, 0.12, 0.1), rng.randf()))
	for k in int(n * 0.12):
		var s2: Array = on_side.call(sqrt(rng.randf()) * rad, rng.randf() * TAU)
		var up := rng.randf() < 0.35
		kit.put("drum", s2[0] + Vector3(0, 0.4 if up else 0.24, 0), (s2[1] as Basis) * rot(rng.randf() * TAU, 0.0 if up else rng.randf_range(1.2, 1.7), rng.randf_range(-0.25, 0.25)), Vector3.ONE * rng.randf_range(0.9, 1.15), tint(rng, 0.45))
	for k in int(n * 0.1):
		var s3: Array = on_side.call(sqrt(rng.randf()) * rad * 0.9, rng.randf() * TAU)
		var dia := rng.randf_range(0.18, 0.5)
		kit.put("pipe", s3[0] + Vector3(0, dia * 0.4, 0), (s3[1] as Basis) * rot(rng.randf() * TAU, rng.randf_range(-0.5, 0.5)), Vector3(dia, dia, rng.randf_range(2.4, 5.5)), tint(rng, 0.7))
	for k in int(n * 0.3):
		var s4: Array = on_side.call(sqrt(rng.randf()) * rad, rng.randf() * TAU)
		kit.put("sheet", s4[0] + Vector3(0, 0.14, 0), (s4[1] as Basis) * rot(rng.randf() * TAU, rng.randf_range(-0.55, 0.55), rng.randf_range(-0.4, 0.4)), Vector3(rng.randf_range(1.0, 1.9), 1.0, rng.randf_range(2.0, 3.8)), tint(rng, 0.5))
	for k in int(n * 0.08):
		var s5: Array = on_side.call(sqrt(rng.randf()) * rad * 0.85, rng.randf() * TAU)
		kit.put("beam", s5[0] + Vector3(0, 0.3, 0), (s5[1] as Basis) * rot(rng.randf() * TAU, rng.randf_range(-0.7, 0.7)), Vector3(1.2, 1.2, rng.randf_range(3.0, 6.5)), tint(rng, 0.85))
	for k in int(n * 0.07):
		var s6: Array = on_side.call(sqrt(rng.randf()) * rad * 0.95, rng.randf() * TAU)
		var white := Color(0.68, 0.67, 0.63).lerp(RUST[rng.randi() % RUST.size()], rng.randf_range(0.05, 0.4))
		kit.put("fridge" if rng.randf() < 0.5 else "washer", s6[0] + Vector3(0, 0.1, 0), (s6[1] as Basis) * rot(rng.randf() * TAU, rng.randf_range(-1.5, 0.4), rng.randf_range(-0.5, 0.5)), Vector3.ONE * rng.randf_range(0.95, 1.1), white)
	for k in int(n * 0.14):
		var s7: Array = on_side.call(sqrt(rng.randf()) * rad * 1.05, rng.randf() * TAU)
		var sc := rng.randf_range(0.4, 1.3)
		kit.put("chunk", s7[0] - Vector3(0, 0.1, 0), rot(rng.randf() * TAU, rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)), Vector3(sc, sc * rng.randf_range(0.5, 1.0), sc * rng.randf_range(0.7, 1.3)), Color(0.4, 0.39, 0.37).lerp(Color(0.26, 0.24, 0.22), rng.randf()))
	# One or two wrecks low on the heap, nose up or on their side, half sunk in it.
	for k in (3 if rich > 50.0 else 2):
		var aa := rng.randf() * TAU
		var s8: Array = on_side.call(rad * rng.randf_range(0.55, 0.92), aa)
		var b8 := rot(rng.randf() * TAU, rng.randf_range(-0.35, 0.35), rng.randf_range(-0.3, 0.3) if rng.randf() < 0.7 else rng.randf_range(1.2, 1.5))
		kit.put("van" if rng.randf() < 0.3 else "wreck", s8[0] + Vector3(0, -0.2, 0), (s8[1] as Basis) * b8, Vector3.ONE * rng.randf_range(0.95, 1.08), tint(rng, 0.5))
	return center + Vector3(0, hgt * 0.92, 0)


## The ring of heaps outside the fence: the near ones full of things you can name, the far ones
## bigger and plainer. Returns the tops of the near ones.
static func heaps(c: ArenaDistrict) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8701
	var near := Kit.new()
	var far := Kit.new()
	var tops: Array = []
	var mounds := 13
	for hi in mounds:
		var ang := hi * TAU / mounds + 0.2 + rng.randf_range(-0.08, 0.08)
		var is_far: bool = hi % 2 == 1
		var d := R + (rng.randf_range(17.0, 24.0) if is_far else rng.randf_range(8.0, 12.5))
		var center := Vector3(sin(ang) * d, 0, cos(ang) * d)
		# Keep the way under the overpass and the view of the far city open.
		if center.z < -30.0 and absf(center.x) < 26.0 and not is_far:
			continue
		var rad := minf(rng.randf_range(7.0, 10.5), d - R - 0.6) if not is_far else rng.randf_range(9.0, 14.0)
		var hgt := rng.randf_range(3.4, 5.8) if not is_far else rng.randf_range(6.0, 10.0)
		var top := _heap(far if is_far else near, rng, center, rad, hgt, 58.0 if is_far else 96.0)
		if not is_far:
			tops.append(top)
	near.commit(c, true)
	far.commit(c, false)
	return tops


# ====================================================================== the broken ground

const KEEP_CLEAR := [Vector3(15.0, 0, 13.5), Vector3(20.0, 0, -15.0), Vector3(4.6, 0, 33.0), Vector3(-8, 0, 11), Vector3(17, 0, 11.5), Vector3(-13, 0, -22), Vector3(21.5, 0, -14),
		Vector3(4, 0, 22), Vector3(-16, 0, 14.5), Vector3(0, 0, 19.6), Vector3(20.2, 0, -13), Vector3(0, 0, 33), Vector3(7.5, 0, 27.5), Vector3(11.0, 0, 23.2)]
## [centre, half size] of what is built on the floor: nothing broken goes under these.
const BUILT := [[Vector2(-10, 12.5), Vector2(7.5, 4.0)], [Vector2(24, -18), Vector2(6.5, 6.5)], [Vector2(-25, -16), Vector2(6.5, 6.0)], [Vector2(18, 14), Vector2(3.6, 3.6)],
		[Vector2(31.5, 5.0), Vector2(5.0, 8.0)], [Vector2(-20, 12), Vector2(2.0, 2.0)], [Vector2(13, -11), Vector2(2.2, 2.2)], [Vector2(-12, -14), Vector2(2.0, 2.0)], [Vector2(8, 16), Vector2(2.0, 2.0)],
		[Vector2(27, -7), Vector2(4.0, 4.0)]]


## Everything solid already standing on the floor (a statue, a bench, a stall...): [where, how
## wide]. Read off the bodies the town was given, so nothing new is ever laid under one of them.
static var _solid: Array = []
static var slab_spots: Array = []      # where the heaved slabs were laid (the tests look at these)


static func note_solids(c: Node3D) -> void:
	_solid = []
	_walk_solids(c, Transform3D.IDENTITY)


static func _walk_solids(n: Node, xf: Transform3D) -> void:
	for ch in n.get_children():
		if not (ch is Node3D):
			continue
		var t := xf * (ch as Node3D).transform
		if ch is CollisionShape3D and (ch as CollisionShape3D).shape != null:
			var sh := (ch as CollisionShape3D).shape
			var r := 0.0
			if sh is BoxShape3D:
				r = maxf((sh as BoxShape3D).size.x, (sh as BoxShape3D).size.z) * 0.5 * maxf(t.basis.get_scale().x, t.basis.get_scale().z)
			elif sh is CylinderShape3D:
				r = (sh as CylinderShape3D).radius * t.basis.get_scale().x
			elif sh is SphereShape3D:
				r = (sh as SphereShape3D).radius * t.basis.get_scale().x
			elif sh is CapsuleShape3D:
				r = (sh as CapsuleShape3D).radius * t.basis.get_scale().x
			var flat := Vector2(t.origin.x, t.origin.z)
			if r > 0.05 and r < 12.0 and flat.length() < R - 1.0 and t.origin.y < 6.0:
				_solid.append([flat, r])
		_walk_solids(ch, t)


## Is this spot open floor: off the roads, the ring, the buildings and where people stand?
static func open_floor(p: Vector3, room := 1.6) -> bool:
	for sld in _solid:
		if Vector2(p.x, p.z).distance_to(sld[0]) < float(sld[1]) + room:
			return false
	return _open_floor(p, room)


static func _open_floor(p: Vector3, room := 1.6) -> bool:
	if Vector2(p.x, p.z).length() < 9.5 + room or Vector2(p.x, p.z).length() > R - 1.2 - room:
		return false
	if (absf(p.x) < 3.0 + room and p.z > -34.0 and p.z < 38.0) or (absf(p.z - 20.0) < 2.6 + room and absf(p.x) < 31.0):
		return false
	# the ways people walk: the two side streets and the back one
	if (absf(absf(p.x) - 22.0) < 1.4 + room and absf(p.z) < 12.0) or (absf(p.z + 24.0) < 1.4 + room and absf(p.x) < 14.0):
		return false
	for q in KEEP_CLEAR:
		if Vector2(p.x - (q as Vector3).x, p.z - (q as Vector3).z).length() < 2.6 + room:
			return false
	for b in BUILT:
		var cc: Vector2 = b[0]
		var hh: Vector2 = b[1]
		if absf(p.x - cc.x) < hh.x + room and absf(p.z - cc.y) < hh.y + room:
			return false
	return true


## The floor of the town is not one clean slab any more: worn patches, places where the concrete
## is gone down to the dirt with the rubble still round them, slabs the ground has pushed up at
## an angle with their iron showing, and wide cracks. Nothing here is in the way of walking.
static func broken_ground(c: ArenaDistrict) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8702
	note_solids(c)
	slab_spots = []
	var kit := Kit.new()
	var flat := Kit.new()
	var conc := [Color(0.31, 0.295, 0.275), Color(0.27, 0.26, 0.245), Color(0.36, 0.345, 0.325), Color(0.24, 0.225, 0.21)]
	var amount := _amount()
	# Worn and stained stretches: the slab is many ages of concrete, not one. Each is a few
	# angular pieces lying over each other, a shade off the floor, never a neat shape.
	var worn := [Color(0.25, 0.238, 0.222), Color(0.235, 0.222, 0.208), Color(0.262, 0.25, 0.235), Color(0.222, 0.21, 0.198)]
	for k in 30:
		var a := rng.randf() * TAU
		var d := rng.randf_range(8.0, 38.0)
		var p := Vector3(cos(a) * d, 0.0, sin(a) * d)
		var col: Color = worn[rng.randi() % worn.size()]
		var big := rng.randf_range(2.0, 5.0)
		for j in rng.randi_range(3, 5):
			var off := Vector3(rng.randf_range(-0.6, 0.6) * big, 0.004, rng.randf_range(-0.6, 0.6) * big)
			if Vector2(p.x + off.x, p.z + off.z).length() > R - 2.0:
				continue
			flat.put("cube", p + off, rot(rng.randf() * TAU), Vector3(big * rng.randf_range(0.5, 1.2), 0.008, big * rng.randf_range(0.3, 0.8)), col)
	# Holes down to the dirt, each with its rim of rubble.
	var holes := 0
	var tries := 0
	while holes < int(11 * amount) and tries < 400:
		tries += 1
		var a2 := rng.randf() * TAU
		var d2 := rng.randf_range(11.0, 38.0)
		var p2 := Vector3(cos(a2) * d2, 0.0, sin(a2) * d2)
		if not open_floor(p2, 1.0):
			continue
		holes += 1
		var rr2 := rng.randf_range(0.9, 2.4)
		var squash := rng.randf_range(0.55, 0.95)
		var yaw := rng.randf() * TAU
		_solid.append([Vector2(p2.x, p2.z), rr2])          # (nothing else is laid in a hole)
		flat.put("disc", p2 + Vector3(0, 0.014, 0), rot(yaw), Vector3(rr2, 0.01, rr2 * squash), Color(0.16, 0.13, 0.105))
		flat.put("disc", p2 + Vector3(rng.randf_range(-0.3, 0.3), 0.018, rng.randf_range(-0.3, 0.3)), rot(yaw + 0.6), Vector3(rr2 * 0.6, 0.01, rr2 * squash * 0.55), Color(0.12, 0.1, 0.085))
		for j in int(rr2 * 9.0):
			var ra := rng.randf() * TAU
			var rd := rr2 * rng.randf_range(0.75, 1.2)
			var off := rot(yaw) * Vector3(cos(ra) * rd, 0, sin(ra) * rd * squash)
			var sc := rng.randf_range(0.1, 0.34)
			kit.put("chunk", p2 + off, rot(rng.randf() * TAU, rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)), Vector3(sc, sc * rng.randf_range(0.4, 0.9), sc), (conc[rng.randi() % conc.size()] as Color).lightened(0.06))
		if rng.randf() < 0.6:
			for j in rng.randi_range(2, 4):
				kit.put("pipe", p2 + rot(yaw) * Vector3(rng.randf_range(-0.5, 0.5) * rr2, 0.16, rng.randf_range(-0.4, 0.4) * rr2), rot(rng.randf() * TAU, rng.randf_range(0.5, 1.2)), Vector3(0.028, 0.028, rng.randf_range(0.4, 0.9)), Color(0.4, 0.22, 0.13))
	# Slabs the ground has heaved up: one edge sits a hand high, the other is still in the floor.
	var slabs := 0
	tries = 0
	while slabs < int(26 * amount) and tries < 700:
		tries += 1
		var a3 := rng.randf() * TAU
		var d3 := rng.randf_range(13.0, 38.4)
		var p3 := Vector3(cos(a3) * d3, 0.0, sin(a3) * d3)
		if not open_floor(p3, 1.5):
			continue
		slabs += 1
		_solid.append([Vector2(p3.x, p3.z), 1.2])
		slab_spots.append(p3)
		var sx := rng.randf_range(1.5, 2.6)
		var sz := rng.randf_range(1.4, 2.8)
		var tip := rng.randf_range(0.045, 0.1)
		var yaw3 := rng.randf() * TAU
		var b3 := rot(yaw3, 0.0, tip)
		kit.put("slab", p3 + Vector3(0, sx * 0.5 * sin(tip) - 0.085, 0), b3, Vector3(sx, 0.24, sz), Color(0.3, 0.285, 0.268).lerp(Color(0.25, 0.238, 0.225), rng.randf()))
		# the dark gap under the edge that stands up, and the bits that broke off it
		var edge := p3 + rot(yaw3) * Vector3(sx * 0.5, 0, 0)
		flat.put("disc", Vector3(edge.x, 0.012, edge.z), rot(yaw3), Vector3(0.32, 0.01, sz * 0.46), Color(0.1, 0.085, 0.075))
		for j in rng.randi_range(2, 5):
			var sc2 := rng.randf_range(0.09, 0.26)
			var at := p3 + rot(yaw3) * Vector3(sx * rng.randf_range(0.5, 0.8), 0, sz * rng.randf_range(-0.55, 0.55))
			kit.put("chunk", Vector3(at.x, 0.0, at.z), rot(rng.randf() * TAU), Vector3(sc2, sc2 * 0.7, sc2), Color(0.38, 0.365, 0.345))
	# Wide cracks: the kind a wheel drops into.
	var crack_col := Color(0.05, 0.045, 0.045)
	for k in int(16 * amount):
		var a4 := rng.randf() * TAU
		var d4 := rng.randf_range(10.0, 37.0)
		var p4 := Vector3(cos(a4) * d4, 0.026, sin(a4) * d4)
		var yaw4 := rng.randf() * TAU
		for seg in rng.randi_range(4, 8):
			var ln := rng.randf_range(0.9, 2.6)
			var dir := Vector3(cos(-yaw4), 0, sin(-yaw4))
			p4 += dir * ln * 0.5
			if absf(p4.x) < 3.2 or absf(p4.z - 20.0) < 2.7 or Vector2(p4.x, p4.z).length() < 8.0 or Vector2(p4.x, p4.z).length() > R - 1.5:
				break
			flat.put("cube", p4, rot(yaw4), Vector3(ln, 0.008, rng.randf_range(0.07, 0.16)), crack_col)
			p4 += dir * ln * 0.5
			yaw4 += rng.randf_range(-0.8, 0.8)
	kit.commit(c, true)
	flat.commit(c, false)


# ====================================================================== beyond the fence

static func _shed(batch: CityBuilder.BoxBatch, c: ArenaDistrict, rng: RandomNumberGenerator, at: Vector3, yaw: float, w: float, d: float, h: float, wall_col: Color, lit: Array) -> void:
	var b := rot(yaw)
	var wall := c.mat(wall_col, 0.9, 0.0)
	var wall2 := c.mat(wall_col.darkened(0.14), 0.9, 0.0)
	var low := c.mat(wall_col.lerp(Color(0.3, 0.17, 0.11), 0.6), 0.95, 0.0)
	var roof := c.mat(Color(0.3, 0.27, 0.25).lerp(RUST[rng.randi() % RUST.size()], 0.35), 0.9, 0.0)
	var dark := c.mat(Color(0.07, 0.07, 0.08), 0.8, 0.0)
	var glass := c.mat(Color(0.16, 0.2, 0.24), 0.9, 0.0)
	batch.add(Vector3(w, h, d), at + Vector3(0, h / 2.0, 0), wall, b)
	batch.add(Vector3(w + 0.16, 1.6, d + 0.16), at + Vector3(0, 0.8, 0), low, b)
	# the wall in sheets: every other one a shade off, some newer, some rusted through
	var nx := int(w / 3.2)
	for i in nx:
		if i % 2 == 0 and rng.randf() < 0.8:
			continue
		var x := -w / 2.0 + (i + 0.5) * w / nx
		var pm: Material = wall2 if rng.randf() < 0.7 else low
		for sz: float in [-1.0, 1.0]:
			batch.add(Vector3(w / nx - 0.1, h - 1.7, 0.08), at + b * Vector3(x, 1.6 + (h - 1.7) / 2.0, sz * (d / 2.0 + 0.02)), pm, b)
	# a saw-tooth roof: each tooth a long slope and a strip of glass facing away from the sun
	var teeth := maxi(2, int(w / 7.0))
	var tw := w / teeth
	for i in teeth:
		var x2 := -w / 2.0 + (i + 0.5) * tw
		batch.add(Vector3(tw * 1.06, 0.18, d + 0.5), at + b * Vector3(x2, h + tw * 0.17, 0), roof, b * rot(0.0, 0.0, 0.33))
		batch.add(Vector3(0.14, tw * 0.36, d + 0.3), at + b * Vector3(x2 + tw * 0.49, h + tw * 0.17, 0), glass, b)
		if rng.randf() < 0.5:
			lit.append([at + b * Vector3(x2 + tw * 0.5, h + tw * 0.17, rng.randf_range(-0.3, 0.3) * d), b, Vector3(0.08, tw * 0.22, d * rng.randf_range(0.12, 0.3))])
	# the doors: one big enough for a truck, standing half open on the dark
	batch.add(Vector3(minf(6.5, w * 0.3), minf(h - 1.0, 5.2), 0.2), at + b * Vector3(-w * 0.2, minf(h - 1.0, 5.2) / 2.0, d / 2.0 + 0.06), dark, b)
	batch.add(Vector3(minf(3.4, w * 0.16), minf(h - 1.0, 5.2), 0.14), at + b * Vector3(-w * 0.2 + minf(6.5, w * 0.3) * 0.62, minf(h - 1.0, 5.2) / 2.0, d / 2.0 + 0.2), wall2, b)
	# what hangs on a building like this: a pipe run, a vent or two, a lean-to
	batch.add(Vector3(w * 0.9, 0.3, 0.3), at + b * Vector3(0, h * 0.62, -d / 2.0 - 0.3), c.mat(RUST[1], 0.9, 0.0), b)
	for i in 2:
		batch.add_round(0.6, 1.6, at + b * Vector3(rng.randf_range(-0.4, 0.4) * w, h + tw * 0.34 + 0.6, rng.randf_range(-0.35, 0.35) * d), c.mat(Color(0.34, 0.33, 0.32), 0.9, 0.0), 8)
	batch.add(Vector3(w * 0.28, h * 0.45, 4.0), at + b * Vector3(w * 0.3, h * 0.225, d / 2.0 + 2.0), wall2, b)
	batch.add(Vector3(w * 0.3, 0.16, 4.4), at + b * Vector3(w * 0.3, h * 0.45 + 0.2, d / 2.0 + 2.0), roof, b * rot(0.0, -0.12))


## A crane that straddles a yard on two legs: a beam across the top, the crab that runs along
## it, a hook hanging over a pile.
static func _gantry(batch: CityBuilder.BoxBatch, c: ArenaDistrict, at: Vector3, yaw: float, span: float, h: float, col: Color) -> void:
	var b := rot(yaw)
	var m := c.mat(col, 0.9, 0.0)
	var dark := c.mat(Color(0.1, 0.1, 0.11), 0.8, 0.0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			batch.add(Vector3(0.5, h + 0.4, 0.5), at + b * Vector3(sx * span / 2.0, h / 2.0, sz * 1.5), m, b * rot(0.0, sz * -0.09))
		batch.add(Vector3(0.7, 0.6, 4.6), at + b * Vector3(sx * span / 2.0, 0.3, 0), dark, b)
		batch.add(Vector3(0.36, 0.36, 3.2), at + b * Vector3(sx * span / 2.0, h * 0.5, 0), m, b)
	for sz2: float in [-0.8, 0.8]:
		batch.add(Vector3(span + 5.0, 1.3, 0.4), at + b * Vector3(0, h + 0.5, sz2), m, b)
	batch.add(Vector3(2.4, 1.4, 2.6), at + b * Vector3(span * 0.18, h + 1.6, 0), dark, b)
	batch.add(Vector3(1.6, 1.2, 1.6), at + b * Vector3(span * 0.18 + 1.5, h - 0.9, 1.2), c.mat(col.darkened(0.2), 0.9, 0.0), b)
	batch.add(Vector3(0.08, h * 0.46, 0.08), at + b * Vector3(span * 0.18, h - h * 0.23, 0), dark, b)
	batch.add(Vector3(0.9, 0.7, 0.5), at + b * Vector3(span * 0.18, h - h * 0.46 - 0.3, 0), m, b)


## A pylon of the line that used to feed the place: four legs drawn in to a point, three arms.
static func _pylon(batch: CityBuilder.BoxBatch, c: ArenaDistrict, at: Vector3, yaw: float, h: float) -> Array:
	var b := rot(yaw)
	var m := c.mat(Color(0.33, 0.31, 0.3), 0.9, 0.0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			batch.add(Vector3(0.24, h, 0.24), at + b * Vector3(sx * 1.1, h / 2.0, sz * 1.1), m, b * rot(0.0, sz * 0.055, sx * -0.055))
	for k in 5:
		var y := 2.0 + k * (h - 4.0) / 5.0
		var wd := 3.6 - k * 0.5
		for sz2: float in [-1.0, 1.0]:
			batch.add(Vector3(wd, 0.1, 0.1), at + b * Vector3(0, y, sz2 * wd * 0.33), m, b * rot(0.0, 0.0, 0.5 if k % 2 == 0 else -0.5))
			batch.add(Vector3(0.1, 0.1, wd), at + b * Vector3(sz2 * wd * 0.33, y, 0), m, b * rot(0.0, 0.5 if k % 2 == 0 else -0.5))
	var tips: Array = []
	for k in 3:
		var y2 := h - 1.0 - k * 3.2
		var arm := 9.0 - k * 1.2 if k != 1 else 11.0
		batch.add(Vector3(arm, 0.22, 0.3), at + b * Vector3(0, y2, 0), m, b)
		for sx2: float in [-1.0, 1.0]:
			batch.add(Vector3(0.1, 0.9, 0.1), at + b * Vector3(sx2 * arm * 0.47, y2 - 0.45, 0), c.mat(Color(0.5, 0.52, 0.5), 0.6, 0.0), b)
			tips.append(at + b * Vector3(sx2 * arm * 0.47, y2 - 0.9, 0))
	return tips


static func _near_shed(sheds: Array, p: Vector3, d: float) -> bool:
	for s in sheds:
		if Vector2(p.x - (s[0] as Vector3).x, p.z - (s[0] as Vector3).z).length() < d:
			return true
	return false


## The works past the fence: sheds with saw-tooth roofs, a yard crane over a pile, tanks, a line
## of pylons walking off, more heaps far out so the land does not end in a flat line, dirt and
## wheel tracks on the ground between, and out over the water the bridge nobody finished.
static func outskirts(c: ArenaDistrict) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8703
	var batch := CityBuilder.BoxBatch.new()
	var flat := Kit.new()
	var kit := Kit.new()
	var lit: Array = []
	# ---- sheds
	var shed_at := [[Vector3(-84, 0, 14), 1.45, 34.0, 20.0, 11.0, Color(0.36, 0.4, 0.38)], [Vector3(-80, 0, -15), 1.7, 22.0, 15.0, 9.0, Color(0.44, 0.36, 0.28)],
			[Vector3(86, 0, 26), -1.5, 38.0, 22.0, 12.0, Color(0.38, 0.36, 0.34)], [Vector3(72, 0, 58), -2.2, 28.0, 17.0, 9.5, Color(0.33, 0.37, 0.42)],
			[Vector3(-30, 0, 86), 3.0, 36.0, 20.0, 10.5, Color(0.42, 0.38, 0.3)], [Vector3(26, 0, 92), 3.3, 30.0, 18.0, 9.0, Color(0.34, 0.38, 0.36)],
			[Vector3(104, 0, -18), -1.3, 30.0, 18.0, 10.0, Color(0.4, 0.33, 0.27)]]
	for s in shed_at:
		_shed(batch, c, rng, s[0], s[1], s[2], s[3], s[4], s[5], lit)
	# ---- a yard crane over the scrap on each side, and a line of tanks
	_gantry(batch, c, Vector3(64, 0, -8), 0.3, 22.0, 13.0, Color(0.62, 0.5, 0.16))
	_gantry(batch, c, Vector3(-58, 0, 44), -0.7, 20.0, 12.0, Color(0.3, 0.42, 0.5))
	var tank := c.mat(Color(0.5, 0.49, 0.46), 0.9, 0.0)
	var band := c.mat(RUST[0], 0.9, 0.0)
	for k in 4:
		var tp := Vector3(-66.0 - k * 11.5, 0, -58.0 + k * 1.0)
		var tr := 4.6 if k % 2 == 0 else 3.6
		var th := 8.5 if k % 2 == 0 else 11.0
		batch.add_round(tr, th, tp + Vector3(0, th / 2.0, 0), tank if k != 2 else c.mat(Color(0.44, 0.3, 0.2), 0.9, 0.0), 14)
		for j in 3:
			batch.add_round(tr + 0.06, 0.3, tp + Vector3(0, 1.2 + j * th * 0.34, 0), band, 14)
		batch.add(Vector3(0.5, th + 1.0, 0.12), tp + Vector3(tr + 0.1, (th + 1.0) / 2.0, 0), c.mat(Color(0.2, 0.2, 0.2), 0.8, 0.0))
		batch.add(Vector3(11.5, 0.4, 0.4), tp + Vector3(-5.7, th * 0.6, 0), band, rot(0.26))
	# ---- the power line: pylons walking off to the south-west, the wires sagging between them
	var wire := c.mat(Color(0.06, 0.06, 0.07), 0.7, 0.0)
	var last: Array = []
	for k in 5:
		var pp := Vector3(-52.0 - k * 26.0, 0, 62.0 + k * 13.0)
		var tips := _pylon(batch, c, pp, 0.46, 24.0 - k * 0.6)
		if not last.is_empty():
			for w in tips.size():
				var a: Vector3 = last[w]
				var b: Vector3 = tips[w]
				var prev := a
				for seg in 6:
					var t := (seg + 1) / 6.0
					var cur := a.lerp(b, t) + Vector3(0, -2.6 * sin(t * PI), 0)
					var mid := (prev + cur) / 2.0
					var dirv := cur - prev
					batch.add(Vector3(dirv.length(), 0.05, 0.05), mid, wire, Basis(Quaternion(Vector3.RIGHT, dirv.normalized())))
					prev = cur
		last = tips
	# ---- the bridge that was never finished: out from the shore toward the city, then nothing
	var conc := c.surf("concrete", Color(0.47, 0.46, 0.44))
	var conc2 := c.surf("concrete", Color(0.38, 0.37, 0.36))
	var bx := 62.0
	var deck_y := 15.0
	# the ramp up from the land
	var slope := atan2(deck_y / 6.0, 6.0)
	for k in 6:
		var z := -24.0 - k * 6.0
		var y := deck_y * (k + 0.5) / 6.0
		batch.add(Vector3(8.6, 0.9, 6.5), Vector3(bx, y - 0.45, z), conc, rot(0.0, slope))
		if k > 0:
			batch.add(Vector3(2.0, y, 2.0), Vector3(bx, y / 2.0 - 0.5, z), conc2)
	for pz: float in [-62.0, -78.0, -94.0, -110.0]:
		var done: bool = pz > -100.0
		var ph := deck_y - 1.0 if done else deck_y * 0.55
		for px: float in [-2.6, 2.6]:
			batch.add(Vector3(1.8, ph + 6.0, 2.6), Vector3(bx + px, (ph - 6.0) / 2.0, pz), conc2)
		if done:
			batch.add(Vector3(8.4, 1.4, 3.2), Vector3(bx, deck_y - 1.7, pz), conc2)
		else:
			# the last pier stands bare: iron out of the top of it
			for r in 6:
				for px2: float in [-2.6, 2.6]:
					kit.put("pipe", Vector3(bx + px2 + (r % 3) * 0.5 - 0.5, ph + 0.9, pz + (r / 3) * 0.8 - 0.4), rot(rng.randf_range(-0.1, 0.1), PI / 2.0 + rng.randf_range(-0.12, 0.12)), Vector3(0.07, 0.07, 2.2), RUST[1])
	# the deck in three strips, each breaking off at its own length
	for k in 3:
		var end_z := [-99.0, -95.5, -102.0][k] as float
		batch.add(Vector3(2.86, 1.0, absf(end_z + 57.0)), Vector3(bx - 2.86 + k * 2.86, deck_y - 0.5, (end_z - 57.0) / 2.0), conc)
		for r in 5:
			kit.put("pipe", Vector3(bx - 2.86 + k * 2.86 + (r - 2) * 0.5, deck_y - 0.5 + rng.randf_range(-0.3, 0.3), end_z - 0.9), rot(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.5, 0.2)), Vector3(0.07, 0.07, 2.0), RUST[0])
	for sx: float in [-1.0, 1.0]:
		batch.add(Vector3(0.3, 0.9, 38.0), Vector3(bx + sx * 4.2, deck_y + 0.45, -77.0), c.mat(Color(0.42, 0.41, 0.4), 0.9, 0.0))
	# two towers for cables that were only half strung, and the crane left on the end of the deck
	var steel := c.mat(Color(0.45, 0.4, 0.36), 0.9, 0.0)
	for sx2: float in [-1.0, 1.0]:
		batch.add(Vector3(1.3, 30.0, 1.8), Vector3(bx + sx2 * 5.0, deck_y + 9.0, -78.0), steel)
	batch.add(Vector3(11.4, 1.2, 1.4), Vector3(bx, deck_y + 23.0, -78.0), steel)
	batch.add(Vector3(11.4, 1.0, 1.2), Vector3(bx, deck_y + 12.0, -78.0), steel)
	for k in 4:
		var reach := 6.0 + k * 4.4
		var top := Vector3(bx - 5.0, deck_y + 22.0 - k * 1.6, -78.0)
		for sgn: float in ([1.0, -1.0] if k < 3 else [1.0]):
			var foot := Vector3(bx - 4.3, deck_y + 0.6, -78.0 + sgn * reach)
			var dv := foot - top
			batch.add(Vector3(dv.length(), 0.09, 0.09), (top + foot) / 2.0, wire, Basis(Quaternion(Vector3.RIGHT, dv.normalized())))
	var yellow := c.mat(Color(0.66, 0.52, 0.14), 0.9, 0.0)
	var cb := Vector3(bx + 1.0, deck_y, -93.0)
	batch.add(Vector3(1.1, 13.0, 1.1), cb + Vector3(0, 6.5, 0), yellow)
	batch.add(Vector3(1.0, 0.8, 19.0), cb + Vector3(0, 13.2, -5.5), yellow)
	batch.add(Vector3(1.8, 1.6, 2.2), cb + Vector3(0, 12.6, 5.0), c.mat(Color(0.3, 0.3, 0.3), 0.9, 0.0))
	batch.add(Vector3(0.06, 6.0, 0.06), cb + Vector3(0, 10.0, -13.0), wire)
	c.box(Vector3(0.45, 0.45, 0.45), cb + Vector3(0, 14.0, -14.6), c.glow_mat(Color(1.0, 0.2, 0.15), 5.0), false)
	c.box(Vector3(0.45, 0.45, 0.45), Vector3(bx - 5.0, deck_y + 24.4, -78.0), c.glow_mat(Color(1.0, 0.2, 0.15), 5.0), false)
	c.box(Vector3(0.45, 0.45, 0.45), Vector3(bx + 5.0, deck_y + 24.4, -78.0), c.glow_mat(Color(1.0, 0.2, 0.15), 5.0), false)
	batch.commit(c)
	# the few panes still lit in the sheds (only seen once the day goes)
	if not lit.is_empty():
		var lb := CityBuilder.BoxBatch.new()
		var lm := c.glow_mat(Color(1.0, 0.72, 0.4), 1.6)
		for l in lit:
			lb.add(l[2], l[0], lm, l[1])
		var lmi := lb.commit(c)
		if lmi:
			c.set_meta("shed_lights", lmi)
	# ---- heaps far out, so the land ends in a broken line of them
	for k in 11:
		var a := k * TAU / 11.0 + 0.5 + rng.randf_range(-0.12, 0.12)
		var d := rng.randf_range(96.0, 122.0)
		var center := Vector3(sin(a) * d, 0, cos(a) * d)
		if center.z < -58.0 or _near_shed(shed_at, center, 26.0):
			continue          # that way is the water; and not on top of a shed
		_heap(kit, rng, center, rng.randf_range(13.0, 22.0), rng.randf_range(6.0, 11.0), 26.0)
	# ---- the ground between: dark and pale dirt, wheel tracks, low banks, scrap lying about
	var dirt := [Color(0.165, 0.132, 0.105), Color(0.19, 0.155, 0.125), Color(0.13, 0.108, 0.09), Color(0.2, 0.168, 0.135), Color(0.15, 0.125, 0.105)]
	for k in 90:
		var a2 := rng.randf() * TAU
		var d2 := rng.randf_range(R + 3.0, 128.0)
		var p := Vector3(sin(a2) * d2, 0.0, cos(a2) * d2)
		if p.z < -64.0:
			continue
		var rr := rng.randf_range(3.0, 11.0)
		var dcol: Color = dirt[rng.randi() % dirt.size()]
		for j in 3:
			flat.put("disc" if j == 0 else "cube", p + Vector3(rng.randf_range(-0.5, 0.5) * rr, -0.055 + (k % 5) * 0.004, rng.randf_range(-0.5, 0.5) * rr), rot(rng.randf() * TAU), Vector3(rr * rng.randf_range(0.6, 1.1), 0.02, rr * rng.randf_range(0.35, 0.8)), dcol)
	for k in 22:
		var a3 := rng.randf() * TAU
		var d3 := rng.randf_range(R + 12.0, 110.0)
		var p3 := Vector3(sin(a3) * d3, 0.0, cos(a3) * d3)
		if p3.z < -60.0:
			continue
		var rr3 := rng.randf_range(3.0, 7.0)
		kit.put("mound", p3 + Vector3(0, -0.1, 0), rot(rng.randf() * TAU), Vector3(rr3, rng.randf_range(0.5, 1.4), rr3 * rng.randf_range(0.5, 0.9)), (dirt[rng.randi() % dirt.size()] as Color).lightened(0.12))
	# wheel tracks: pairs of dark lines from the gate ways out to the sheds
	for run in [[Vector3(-44, 0, 6), Vector3(-70, 0, 12)], [Vector3(44, 0, 10), Vector3(70, 0, 22)], [Vector3(-10, 0, 46), Vector3(-24, 0, 74)], [Vector3(46, 0, -6), Vector3(60, 0, -28)], [Vector3(30, 0, 44), Vector3(62, 0, 52)]]:
		var a4: Vector3 = run[0]
		var b4: Vector3 = run[1]
		var dir4 := (b4 - a4).normalized()
		var side4 := dir4.cross(Vector3.UP)
		for sgn2: float in [-1.0, 1.0]:
			flat.put("cube", (a4 + b4) / 2.0 + side4 * sgn2 * 1.0 + Vector3(0, -0.03, 0), Basis(Quaternion(Vector3.RIGHT, dir4)), Vector3((b4 - a4).length(), 0.02, 0.55), Color(0.1, 0.085, 0.075))
	# scrap lying loose on the flat: drums in rows, tyres in stacks, sheets, a few more wrecks
	for k in int(120 * _amount()):
		var a5 := rng.randf() * TAU
		var d5 := rng.randf_range(R + 3.0, 96.0)
		var p5 := Vector3(sin(a5) * d5, 0.0, cos(a5) * d5)
		if p5.z < -62.0 or _near_shed(shed_at, p5, 15.0) or (absf(p5.x - 62.0) < 6.0 and p5.z < -18.0):
			continue
		match rng.randi() % 9:
			0, 1:
				for j in rng.randi_range(2, 5):
					kit.put("tyre", p5 + Vector3(rng.randf_range(-0.08, 0.08), 0.13 + j * 0.26, rng.randf_range(-0.08, 0.08)), rot(rng.randf() * TAU), Vector3.ONE * 1.3, Color(0.08, 0.08, 0.085))
			2, 3:
				var yaw5 := rng.randf() * TAU
				for j in rng.randi_range(2, 6):
					kit.put("drum", p5 + rot(yaw5) * Vector3(j * 0.64, 0.44, 0), rot(rng.randf() * TAU), Vector3.ONE, tint(rng, 0.4))
			4:
				kit.put("wreck" if rng.randf() < 0.65 else "van", p5 + Vector3(0, -0.12, 0), rot(rng.randf() * TAU, rng.randf_range(-0.06, 0.06), rng.randf_range(-0.1, 0.1)), Vector3.ONE, tint(rng, 0.55))
			5, 6:
				kit.put("sheet", p5 + Vector3(0, 0.06, 0), rot(rng.randf() * TAU, rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1)), Vector3(rng.randf_range(0.9, 1.4), 1.0, rng.randf_range(2.0, 3.4)), tint(rng, 0.6))
			7:
				var dia := rng.randf_range(0.5, 1.1)
				kit.put("pipe", p5 + Vector3(0, dia * 0.5, 0), rot(rng.randf() * TAU), Vector3(dia, dia, rng.randf_range(3.0, 6.5)), Color(0.45, 0.44, 0.42).lerp(RUST[0], rng.randf() * 0.5))
			8:
				var sc := rng.randf_range(0.7, 1.8)
				kit.put("chunk", p5 + Vector3(0, -0.1, 0), rot(rng.randf() * TAU), Vector3(sc, sc * 0.7, sc), Color(0.36, 0.35, 0.33))
	kit.commit(c, false)
	flat.commit(c, false)
