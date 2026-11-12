class_name HeadLook
extends SkeletonModifier3D
## Small touches on top of whatever animation is playing:
## - turns the head (and a little of the neck) toward something: yaw to the side, pitch up/down;
## - `nod` dips the head forward (0..1), for a hello;
## - brings hanging arms in closer to the body. Shared motions are made on a broad-shouldered
##   body, and on slimmer characters the arms float away from the hips like a wrestler's.
## Angles are in the figure's own space.

var yaw := 0.0
var pitch := 0.0
var nod := 0.0
var head := -1
var neck := -1
var arms: Array = []          # [[upper arm, forearm, side sign], ...]
var tuck := 0.55              # how much of an arm's outward lean to keep (1 = untouched)
var up := Vector3.UP          # the figure's up and right, as the skeleton sees them
var right := Vector3.RIGHT


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if tuck < 0.999:
		var down := -up
		for a in arms:
			var g := sk.get_bone_global_pose(a[0])
			var dir := (sk.get_bone_global_pose(a[1]).origin - g.origin).normalized()
			if dir.dot(down) < 0.72:
				continue           # raised or reaching: leave it alone
			var side := dir.dot(right) * float(a[2])     # > 0: leaning out, away from the body
			if side <= 0.12:
				continue
			var want := (dir - right * float(a[2]) * (side - maxf(0.12, side * tuck))).normalized()
			g.basis = Basis(Quaternion(dir, want)) * g.basis
			sk.set_bone_global_pose(a[0], g)
	if head < 0 or (absf(yaw) < 0.003 and absf(pitch) < 0.003 and nod < 0.003):
		return
	var p := pitch + nod * 0.32
	if neck >= 0:
		var gn := sk.get_bone_global_pose(neck)
		gn.basis = Basis(up, yaw * 0.35) * Basis(right, nod * 0.18) * gn.basis
		sk.set_bone_global_pose(neck, gn)
	var gh := sk.get_bone_global_pose(head)
	gh.basis = Basis(up, yaw * (0.65 if neck >= 0 else 1.0)) * Basis(right, p) * gh.basis
	sk.set_bone_global_pose(head, gh)
