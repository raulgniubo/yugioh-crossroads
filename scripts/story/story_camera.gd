class_name StoryCamera
extends RefCounted
## Decides where the story camera stands.
##
## Every shot is picked from a set of candidate positions. Each one is scored on what would
## actually be on screen: are the people it is about inside the frame and above the dialogue
## box, is anything (a wall, a lamp post, a stall, a bystander) between the lens and their
## faces, is the lens itself stuck inside something, do we see the speaker's face or the back
## of their head. The best one wins, so a shot never has to be "close enough": if a prop is
## in the way on one side, the camera simply stands somewhere else.

const FOV := 46.0
const ASPECT := 16.0 / 9.0
## The part of the picture that is free: under the top bar, above the dialogue box.
const SAFE_TOP := 0.80
const SAFE_LOW := -0.30
const SAFE_SIDE := 0.84

var scene                       # RoamScene
var skip_rids: Array = []       # the player's body
var _all: Array = []            # every piece of scenery in this world: [inverse xform, AABB, centre, radius, small]
var _near: Array = []
var _people: Array = []         # bystanders near the shot: feet positions
var _built := false
var last := {}                  # how the last pick scored (for the audit)


func _init(s) -> void:
	scene = s


# ------------------------------------------------------------------ what is around

func _collect(n: Node) -> void:
	if n is RoamFigure or n is StoryDirector or n is LumenSpirit or n is CanvasItem or n is CanvasLayer:
		return
	if n == scene._player:
		return
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh and _solid_looking(mi):
			_add_box(mi.global_transform, mi.mesh.get_aabb(), str(mi.get_path()).right(60))
	elif n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm and mm.mesh and mm.instance_count <= 1500:
			var bb := mm.mesh.get_aabb()
			var gx := (n as MultiMeshInstance3D).global_transform
			var count := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			for i in count:
				_add_box(gx * mm.get_instance_transform(i), bb)
	for c in n.get_children():
		_collect(c)


## Glows, light cones, glass and the like do not hide anybody.
func _solid_looking(mi: MeshInstance3D) -> bool:
	if mi.has_meta("see_through") or mi.has_meta("billboard"):
		return false
	var m: Material = mi.material_override
	if m == null and mi.mesh.get_surface_count() > 0:
		m = mi.get_surface_override_material(0)
		if m == null:
			m = mi.mesh.surface_get_material(0)
	if m is ShaderMaterial and (m as ShaderMaterial).shader:
		# Beams, holograms, glows: anything drawn as added light or with its own alpha.
		var code: String = (m as ShaderMaterial).shader.code
		if "blend_add" in code or ("unshaded" in code and "ALPHA" in code):
			return false
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		if b.blend_mode == BaseMaterial3D.BLEND_MODE_ADD:
			return false
		if b.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and b.albedo_color.a < 0.6 and b.albedo_texture == null:
			return false
	return true


func _add_box(gx: Transform3D, bb: AABB, tag := "") -> void:
	var sc := gx.basis.get_scale().abs()
	var size := bb.size * sc
	# Flat things (roads, rugs, paint) and whole landscapes are not obstacles.
	if maxf(size.x, maxf(size.y, size.z)) > 70.0:
		return
	var centre := gx * bb.get_center()
	var top := centre.y + (absf(gx.basis.y.y) * bb.size.y + absf(gx.basis.x.y) * bb.size.x + absf(gx.basis.z.y) * bb.size.z) * 0.5
	if size.y < 0.25 and absf(gx.basis.y.normalized().y) > 0.9:
		return
	if gx.basis.determinant() == 0.0:
		return
	var radius := size.length() * 0.5
	_all.append([gx.affine_inverse(), bb, centre, radius, maxf(size.x, size.z) < 5.0, top, tag])


## Scenery and bystanders within reach of a shot around `focus`.
func survey(focus: Vector3, reach: float, cast: Array) -> void:
	if not _built:
		_built = true
		_collect(scene)
	_near.clear()
	for b in _all:
		var c: Vector3 = b[2]
		if absf(c.y - focus.y) > 40.0:
			continue
		if Vector2(c.x - focus.x, c.z - focus.z).length() < reach + float(b[3]):
			_near.append(b)
	_people.clear()
	for f in scene.find_children("*", "RoamFigure", true, false):
		if f in cast or not (f as Node3D).is_visible_in_tree():
			continue
		var p: Vector3 = (f as Node3D).global_position
		if Vector2(p.x - focus.x, p.z - focus.z).length() < reach and absf(p.y - focus.y) < 6.0:
			_people.append(p)


## Bystanders standing right in a conversation (closer than `r` to any of `spots`).
func crowding(spots: Array, r: float, cast: Array) -> Array:
	var out: Array = []
	for f in scene.find_children("*", "RoamFigure", true, false):
		if f in cast or not (f as Node3D).is_visible_in_tree():
			continue
		var p: Vector3 = (f as Node3D).global_position
		for s in spots:
			if Vector2(p.x - s.x, p.z - s.z).length() < r and absf(p.y - s.y) < 3.0:
				out.append(f)
				break
	return out


## Is a spot where somebody is meant to stand inside something? "" when it is free.
func blocked_at(feet: Vector3) -> String:
	if not _built:
		_built = true
		_collect(scene)
	# Find the floor under them first (a pier deck, a plinth).
	var floor_y := feet.y
	var down := PhysicsRayQueryParameters3D.create(feet + Vector3(0, 1.9, 0), feet + Vector3(0, -0.6, 0))
	down.exclude = skip_rids
	var fh: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(down)
	if not fh.is_empty():
		floor_y = (fh["position"] as Vector3).y
		if floor_y > feet.y + 1.2:
			return "(under something solid at %.1f)" % floor_y
		if floor_y > feet.y + 0.3:
			return "(floor is %.2f higher than where they stand)" % (floor_y - feet.y)
	var chest := Vector3(feet.x, floor_y + 1.05, feet.z)
	var q := PhysicsShapeQueryParameters3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.28
	q.shape = sph
	q.transform = Transform3D(Basis(), chest)
	q.exclude = skip_rids
	var hits: Array = scene.get_world_3d().direct_space_state.intersect_shape(q, 2)
	if not hits.is_empty():
		return "(solid: %s)" % str(hits[0]["collider"])
	for b in _all:
		if not bool(b[4]):
			continue
		if (b[1] as AABB).grow(-0.05).has_point((b[0] as Transform3D) * chest):
			return "(inside a prop near %s)" % str((b[2] as Vector3).snapped(Vector3(0.1, 0.1, 0.1)))
	return ""


# ------------------------------------------------------------------ scoring

static func sub(feet: Vector3, head := 1.56, weight := 1.0, facing := Vector3.ZERO) -> Dictionary:
	return {"p": feet, "h": head, "w": weight, "f": facing}


func _ray(a: Vector3, b: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(a, b)
	q.exclude = skip_rids
	var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return -1.0
	return a.distance_to(hit["position"])


## Distance between segment a-b and the upright segment from `feet` to feet + up * h.
static func _seg_gap(a: Vector3, b: Vector3, feet: Vector3, h: float) -> Array:
	var best := 1e9
	var best_t := 0.0
	for i in 9:
		var t := float(i) / 8.0 * 0.94
		var p := a.lerp(b, t)
		var y := clampf(p.y, feet.y, feet.y + h)
		var d := Vector2(p.x - feet.x, p.z - feet.z).length() + absf(p.y - y)
		if d < best:
			best = d
			best_t = t
	return [best, best_t]


## The quick part of the score: framing, walls, people.
func _score_fast(cam: Vector3, aim: Vector3, subs: Array) -> float:
	var fwd := aim - cam
	if fwd.length() < 0.5:
		return -999.0
	fwd = fwd.normalized()
	if absf(fwd.y) > 0.9:
		return -999.0
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var tv := tan(deg_to_rad(FOV * 0.5))
	var th := tv * ASPECT
	var s := 100.0
	for i in subs.size():
		var su: Dictionary = subs[i]
		var w: float = su["w"]
		var feet: Vector3 = su["p"]
		var head := feet + Vector3(0, float(su["h"]), 0)
		var chest := head - Vector3(0, 0.42 * float(su["h"]) / 1.56, 0)
		var v := head - cam
		var z := v.dot(fwd)
		if z < 0.9:
			s -= 220.0 * w
			continue
		var nx := v.dot(right) / (z * th)
		var ny := v.dot(up) / (z * tv)
		# Inside the free part of the frame, and the head not too small to read.
		if absf(nx) > SAFE_SIDE:
			s -= (absf(nx) - SAFE_SIDE) * 420.0 * w + 25.0 * w
		elif absf(nx) > 0.66:
			s -= (absf(nx) - 0.66) * 40.0 * w
		if ny > SAFE_TOP:
			s -= (ny - SAFE_TOP) * 420.0 * w + 25.0 * w
		if ny < 0.02:
			s -= (0.02 - ny) * 260.0 * w
		if ny < SAFE_LOW:
			s -= 40.0 * w
		if z > 9.0:
			s -= (z - 9.0) * 5.0 * w
		# Walls and furniture with a body.
		var dh := cam.distance_to(head)
		var hit := _ray(cam, head)
		if hit >= 0.0 and hit < dh - 0.35:
			s -= 75.0 * w
		hit = _ray(cam, chest)
		if hit >= 0.0 and hit < cam.distance_to(chest) - 0.35:
			s -= 35.0 * w
		# Other people standing in front of this one.
		for p in _people:
			var g := _seg_gap(cam, head, p, 1.75)
			if float(g[0]) < 0.42:
				s -= 55.0 * w
			elif float(g[0]) < 0.7:
				s -= 14.0 * w
		for j in subs.size():
			if j == i:
				continue
			var o: Dictionary = subs[j]
			var g2 := _seg_gap(cam, head, o["p"], float(o["h"]) + 0.15)
			if float(g2[0]) < 0.36:
				s -= 70.0 * w
			elif float(g2[0]) < 0.55:
				s -= 22.0 * w
		# Faces, not the backs of heads.
		var f: Vector3 = su["f"]
		if f != Vector3.ZERO:
			var to_cam := Vector3(cam.x - feet.x, 0, cam.z - feet.z).normalized()
			var d := f.dot(to_cam)
			if d < 0.3:
				s -= (0.3 - d) * 70.0 * w
	# The lens itself: not through a wall from what it looks at, not jammed against anything.
	var back := _ray(aim, cam)
	if back >= 0.0:
		s -= 90.0
	for off: Vector3 in [right * 0.4, -right * 0.4, Vector3(0, -0.35, 0), -fwd * 0.4]:
		if _ray(cam, cam + off) >= 0.0:
			s -= 22.0
	if _ray(cam + Vector3(0, 0.3, 0), cam + Vector3(0, -30, 0)) < 0.0 and cam.y < 60.0:
		# Nothing below: hanging over the sea or outside the world. Allowed, never preferred.
		s -= 6.0
	return s


## The slower part: scenery that has no body in the physics world (most props).
func _score_clutter(cam: Vector3, aim: Vector3, subs: Array) -> float:
	var pen := 0.0
	var segs: Array = []
	var mid := Vector3.ZERO
	var near_z := 1e9
	var fwd := (aim - cam).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var tv := tan(deg_to_rad(FOV * 0.5))
	for su in subs:
		var feet: Vector3 = su["p"]
		var h: float = su["h"]
		var head: Vector3 = feet + Vector3(0, h, 0)
		segs.append([head, float(su["w"]) * 1.0])
		segs.append([head - Vector3(0, 0.3 * h, 0), float(su["w"]) * 0.5])
		segs.append([head - Vector3(0, 0.55 * h, 0), float(su["w"]) * 0.22])
		mid += head - Vector3(0, 0.3 * h, 0)
		near_z = minf(near_z, (head - cam).dot(fwd))
	if subs.size() > 1:
		# The space between the people is part of the picture too.
		segs.append([mid / float(subs.size()), 0.45])
	var front := 0.0
	for b in _near:
		var inv: Transform3D = b[0]
		var bb: AABB = b[1]
		var c: Vector3 = b[2]
		var r: float = b[3]
		var small: bool = b[4]
		var lc := inv * cam
		var inside := bb.grow(0.05).has_point(lc)
		if inside and small:
			# Inside a prop. Unless the people are inside it too: then it is a booth, a gate,
			# a ring of light, and the lens is simply standing where they are.
			if not bb.has_point(inv * (segs[0][0] as Vector3)):
				# (A lamp post's box is mostly air: the post itself has a body, and the
				# rays above already look for that.)
				var sz := bb.size * inv.affine_inverse().basis.get_scale().abs()
				pen += 70.0 if minf(sz.x, sz.z) > 1.3 else 18.0
			continue
		var to_c := c - cam
		var ahead := to_c.dot(fwd)
		if small and ahead > 0.0:
			# Something small sitting right in front of the lens.
			if ahead < 1.6 and (to_c - fwd * ahead).length() < r + 0.25:
				pen += 26.0
			elif ahead < near_z * 0.7 and r > 0.3 and float(b[5]) > cam.y - 1.3:
				# Foreground things that fill the middle of the picture, even when nobody is
				# strictly behind them: a rack, a lamp post, a parked bike.
				var nx := to_c.dot(right) / (ahead * tv * ASPECT)
				var ny := to_c.dot(up) / (ahead * tv)
				var size_on_screen := r / (ahead * tv)
				if absf(nx) < 0.62 + size_on_screen * 0.5 and ny > -0.75 - size_on_screen and ny < 0.8:
					front += clampf(size_on_screen * 26.0, 2.0, 16.0)
		for sg in segs:
			var target: Vector3 = sg[0]
			# A shell the person stands inside (a room, an arch, a canopy) hides nothing.
			var lt := inv * target
			if bb.has_point(lt):
				continue
			if inside:
				# The lens is inside a big shape the person is outside of: a tree crown,
				# a porch roof. Often fine, sometimes a wall. A small cost.
				pen += 5.0 * float(sg[1])
				continue
			var end := cam.lerp(target, 0.96)
			if bb.intersects_segment(lc, inv * end):
				pen += (46.0 if small else 20.0) * float(sg[1])
	return pen + minf(front, 34.0)


## Pick the best of `cands` (each [cam, aim, bonus]). Returns [cam, aim, score].
func pick(cands: Array, subs: Array) -> Array:
	var rated: Array = []
	for c in cands:
		rated.append([_score_fast(c[0], c[1], subs) + float(c[2]), c])
	rated.sort_custom(func(a, b): return a[0] > b[0])
	var best: Array = []
	var best_s := -1e9
	var tried := 0
	for r in rated:
		if float(r[0]) <= best_s:
			break
		tried += 1
		var c: Array = r[1]
		var full := float(r[0]) - _score_clutter(c[0], c[1], subs)
		if full > best_s:
			best_s = full
			best = [c[0], c[1], full]
	last = {"score": best_s, "tried": tried, "of": cands.size()}
	return best


## How good is the shot we already have (to decide whether to hold it)?
func rate(cam: Vector3, aim: Vector3, subs: Array) -> float:
	return _score_fast(cam, aim, subs) - _score_clutter(cam, aim, subs)


## Where to aim so that `heads` sit in the upper part of the free frame.
static func aim_for(cam: Vector3, heads: Array, frac := 0.36) -> Vector3:
	var mid := Vector3.ZERO
	for h in heads:
		mid += h
	mid /= float(heads.size())
	var d := cam.distance_to(mid)
	return mid - Vector3(0, d * tan(deg_to_rad(FOV * 0.5)) * frac, 0)


## What is wrong with a shot, in words (for --story-audit).
func explain(cam: Vector3, aim: Vector3, subs: Array) -> String:
	var fwd := (aim - cam).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var tv := tan(deg_to_rad(FOV * 0.5))
	var out: Array = []
	for su in subs:
		var head: Vector3 = (su["p"] as Vector3) + Vector3(0, float(su["h"]), 0)
		var v := head - cam
		var z := v.dot(fwd)
		var nx := v.dot(right) / (maxf(z, 0.01) * tv * ASPECT)
		var ny := v.dot(up) / (maxf(z, 0.01) * tv)
		var hit := _ray(cam, head)
		out.append("(%.2f,%.2f z%.1f%s)" % [nx, ny, z, " WALL" if (hit >= 0.0 and hit < cam.distance_to(head) - 0.35) else ""])
	var inside: Array = []
	for b in _near:
		if bool(b[4]) and (b[1] as AABB).grow(0.05).has_point((b[0] as Transform3D) * cam):
			inside.append("%s size %s %s" % [str((b[2] as Vector3).snapped(Vector3(0.1, 0.1, 0.1))), str(((b[1] as AABB).size * (b[0] as Transform3D).affine_inverse().basis.get_scale()).snapped(Vector3(0.1, 0.1, 0.1))), str(b[6]) if b.size() > 6 else ""])
	return " ".join(out) + " fast=%.0f clutter=%.0f" % [_score_fast(cam, aim, subs), _score_clutter(cam, aim, subs)] + (" LENS INSIDE " + "; ".join(PackedStringArray(inside)) if not inside.is_empty() else "")
