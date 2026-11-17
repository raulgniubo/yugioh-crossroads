class_name NavGrid
extends Node
## A walking map of the world you are in, one cell per metre, built a little at a time after
## you arrive: which squares you can stand on (not water, not inside a wall). The way-finding
## arrows on the ground follow it, so they go around buildings and along the pier instead of
## straight through them.

var scene: Node
var ready_ := false
var _grid: AStarGrid2D
var _half := 60


func setup(s: Node, half: int) -> void:
	scene = s
	_half = half
	_build.call_deferred()


func _build() -> void:
	# Let the place finish appearing first (and the loading screen go) before the work starts.
	await get_tree().create_timer(1.5).timeout
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(-_half, -_half, _half * 2 + 1, _half * 2 + 1)
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	var skip: Array = []
	if scene._player:
		skip.append(scene._player.get_rid())
	for n in scene._npcs:
		for c in (n[1] as Node).get_children():
			if c is PhysicsBody3D:
				skip.append((c as PhysicsBody3D).get_rid())
	var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	var sph := SphereShape3D.new()
	sph.radius = 0.3
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sph
	q.exclude = skip
	var done := 0
	for z in range(-_half, _half + 1):
		for x in range(-_half, _half + 1):
			if not is_inside_tree():
				return
			var down := PhysicsRayQueryParameters3D.create(Vector3(x, 2.4, z), Vector3(x, -1.0, z))
			down.exclude = skip
			var hit := space.intersect_ray(down)
			var solid := hit.is_empty() or (hit["position"] as Vector3).y > 0.55 or (hit["normal"] as Vector3).y < 0.6
			if not solid:
				q.transform = Transform3D(Basis(), Vector3(x, (hit["position"] as Vector3).y + 1.0, z))
				solid = not space.intersect_shape(q, 1).is_empty()
			if solid:
				_grid.set_point_solid(Vector2i(x, z), true)
			done += 1
			if done % 400 == 0:
				await get_tree().physics_frame
	ready_ = true
	if "--nav-debug" in OS.get_cmdline_user_args():
		var solid := 0
		for z in range(-_half, _half + 1):
			for x in range(-_half, _half + 1):
				if _grid.is_point_solid(Vector2i(x, z)):
					solid += 1
		print("NAVGRID ready half=", _half, " solid=", solid, " of ", (_half * 2 + 1) * (_half * 2 + 1))


func _free(p: Vector3) -> Vector2i:
	var c := Vector2i(int(round(p.x)), int(round(p.z)))
	for r in range(0, 5):
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c2 := c + Vector2i(dx, dz)
				if _grid.is_in_boundsv(c2) and not _grid.is_point_solid(c2):
					return c2
	return Vector2i(99999, 99999)


## The walk from a to b as points on the ground (straightened where the line is clear), or
## nothing when there is no way on foot or the map is not ready yet.
func route(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not ready_:
		return out
	var ca := _free(a)
	var cb := _free(b)
	if ca.x == 99999 or cb.x == 99999:
		return out
	var raw := _grid.get_point_path(ca, cb)
	if raw.is_empty():
		return out
	var i := 0
	out.append(Vector3(a.x, 0, a.z))
	while i < raw.size() - 1:
		var j := raw.size() - 1
		while j > i + 1 and not _clear(raw[i], raw[j]):
			j -= 1
		out.append(Vector3(raw[j].x, 0, raw[j].y))
		i = j
	out.append(Vector3(b.x, 0, b.z))
	return out


func _clear(a: Vector2, b: Vector2) -> bool:
	var n := int(ceil(a.distance_to(b) / 0.5))
	for k in range(1, n):
		var p := a.lerp(b, k / float(n))
		var c := Vector2i(int(round(p.x)), int(round(p.y)))
		if not _grid.is_in_boundsv(c) or _grid.is_point_solid(c):
			return false
	return true
