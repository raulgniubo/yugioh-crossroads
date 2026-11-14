class_name HeroBuild
extends SkeletonModifier3D
## Keeps a few bones at a chosen size (a kid's bigger head) whatever animation is playing.
## The clips carry their own scale for every bone, so setting it once would not last a frame.

var scales := {}        # bone index -> Vector3


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for b in scales:
		sk.set_bone_pose_scale(int(b), scales[b])
