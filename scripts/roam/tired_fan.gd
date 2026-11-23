class_name TiredFan
extends Node3D
## The ceiling fan in Red Dorm room 2 ("one very tired fan"): it turns slowly and not quite evenly,
## slowing now and then as if it might give up, then carrying on. No collision: it is out of reach.

var _t := randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	var speed := 1.1 + 0.35 * sin(_t * 0.55) + 0.18 * sin(_t * 2.1 + 1.3)
	# Every so often it nearly stops, then picks up again.
	var lull := fmod(_t, 11.0)
	if lull < 2.2:
		speed *= 0.35 + 0.65 * absf(lull - 1.1) / 1.1
	rotation.y += speed * delta
	# A little wobble: it has seen better days.
	rotation.x = 0.018 * sin(_t * speed * 2.0)
	rotation.z = 0.014 * cos(_t * speed * 2.0 + 0.7)
