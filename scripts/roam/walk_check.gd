class_name WalkCheck
## Can somebody on foot get from here to there?
##
## The story's own test run jumps the player to each goal, so a wall across the only way in is
## never noticed (one stood across the pier for weeks: nobody who got off the ferry could reach
## the school). This walks it instead: the ground is tried in half-metre steps with the player's
## own body and the real collision of the world, spreading out from where the player stands
## until the goal is reached or there is nowhere left to go. A step may climb half a metre (a
## kerb, a stair, a ramp) and has to end on something to stand on.

const CELL := 0.5
const DIRS := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1),
		Vector3(1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(-1, 0, -1)]


static func _blocked(body: CharacterBody3D, from: Vector3, motion: Vector3, res: PhysicsTestMotionResult3D = null) -> bool:
	var p := PhysicsTestMotionParameters3D.new()
	p.from = Transform3D(body.global_transform.basis, from)
	p.motion = motion
	return PhysicsServer3D.body_test_motion(body.get_rid(), p, res)


## Where a body standing at `from` ends up after one step along `d`, or null if it cannot go.
static func step(body: CharacterBody3D, from: Vector3, d: Vector3):
	var to: Vector3
	if not _blocked(body, from, d):
		to = from + d
	elif not _blocked(body, from, Vector3.UP * 0.5) and not _blocked(body, from + Vector3.UP * 0.5, d):
		to = from + Vector3.UP * 0.5 + d
	else:
		return null
	var res := PhysicsTestMotionResult3D.new()
	if not _blocked(body, to, Vector3.DOWN * 2.5, res):
		return null                     # nothing to stand on
	return to + res.get_travel() + Vector3.UP * 0.03


## Spread out from `from`. Stops as soon as a cell within `r` of `goal` is reached (pass a goal far
## away to map everything). Returns {"ok", "cells", "closest": Vector3, "left": metres still to go,
## "seen": {Vector3i: Vector3}}.
static func reach(body: CharacterBody3D, from: Vector3, goal: Vector3, r: float, max_cells := 60000, pad := 45.0) -> Dictionary:
	# Stand the start on whatever floor is under it (it may be a spot worked out from a door, a little
	# inside a porch step): dropped from the first height that is free.
	var start := from
	var res := PhysicsTestMotionResult3D.new()
	for lift in [0.3, 0.8, 1.4]:
		if not _blocked(body, start + Vector3.UP * lift, Vector3.DOWN * 4.0, res):
			continue
		# (A hair above where it touched: resting exactly on a floor, every move counts as a hit.)
		var stood: Vector3 = start + Vector3.UP * lift + res.get_travel() + Vector3.UP * 0.03
		if not _blocked(body, stood, Vector3.UP * 0.3):
			start = stood
			break
	var span := Vector2(goal.x - start.x, goal.z - start.z).length() + pad
	var seen := {}
	var queue: Array = [start]
	seen[_key(start)] = start
	var best := start
	var best_d := Vector2(goal.x - start.x, goal.z - start.z).length()
	var head := 0
	while head < queue.size() and seen.size() < max_cells:
		var at: Vector3 = queue[head]
		head += 1
		var d := Vector2(goal.x - at.x, goal.z - at.z).length()
		if d < best_d:
			best_d = d
			best = at
		if d <= r and absf(at.y - goal.y) < 1.7:
			return {"ok": true, "cells": seen.size(), "closest": at, "left": 0.0, "seen": seen}
		for dir in DIRS:
			var k := _key(at + dir * CELL)
			if seen.has(k):
				continue
			var to = step(body, at, dir * CELL)
			if to == null:
				continue
			if Vector2((to as Vector3).x - start.x, (to as Vector3).z - start.z).length() > span:
				continue
			seen[k] = to
			queue.append(to)
	return {"ok": false, "cells": seen.size(), "closest": best, "left": maxf(0.0, best_d - r), "seen": seen}


## (The height is part of it: a balcony and the ground under it are two places.)
static func _key(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x / CELL), roundi(p.y / 1.6), roundi(p.z / CELL))
