class_name HeadLook
extends SkeletonModifier3D
## Turns a character's head (and a little of the neck) toward something, on top of whatever
## animation is playing. Angles are in the figure's own space: yaw to the side, pitch up/down.

var yaw := 0.0
var pitch := 0.0
var head := -1
var neck := -1
var up := Vector3.UP          # the figure's up and right, as the skeleton sees them
var right := Vector3.RIGHT


func _process_modification() -> void:
	if head < 0 or (absf(yaw) < 0.003 and absf(pitch) < 0.003):
		return
	var sk := get_skeleton()
	if sk == null:
		return
	if neck >= 0:
		var gn := sk.get_bone_global_pose(neck)
		gn.basis = Basis(up, yaw * 0.35) * gn.basis
		sk.set_bone_global_pose(neck, gn)
	var g := sk.get_bone_global_pose(head)
	g.basis = Basis(up, yaw * (0.65 if neck >= 0 else 1.0)) * Basis(right, pitch) * g.basis
	sk.set_bone_global_pose(head, g)
