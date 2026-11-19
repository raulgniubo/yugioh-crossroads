class_name FxOrb
extends Node3D
## A ball of light with a trail (0.57.0). Move it (tween its position) and it leaves fading
## lights behind it; pop() ends it in a small burst. Made by DuelFx.orb().

var color := Color.WHITE
var size := 0.28
var trail := true

var _core: MeshInstance3D
var _last := Vector3.ZERO
var _acc := 0.0


func _ready() -> void:
	_core = _blob(size, 1.0, 0.6)
	add_child(_core)
	_last = global_position


func _blob(s: float, a: float, flare: float) -> MeshInstance3D:
	var m := DuelFx._mat("glow", DuelFx.HEAD + DuelFx.GLOW, {"color": color, "energy": 3.2, "alpha": a, "flare": flare})
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	mi.mesh = q
	mi.material_override = m
	mi.scale = Vector3.ONE * s
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _process(delta: float) -> void:
	if not trail:
		return
	var here := global_position
	var moved := here.distance_to(_last)
	_acc += moved
	# One light every few centimeters travelled, so a fast orb leaves an unbroken line.
	var step := size * 0.28
	var n := 0
	while _acc >= step and n < 12:
		_acc -= step
		n += 1
		var at := here.lerp(_last, _acc / maxf(0.0001, moved)) if moved > 0.0001 else here
		var b := _blob(size * 0.7, 0.7, 0.0)
		get_parent().add_child(b)
		b.global_position = at
		var m := b.material_override as ShaderMaterial
		var tw := b.create_tween().set_parallel()
		tw.tween_property(m, "shader_parameter/alpha", 0.0, Settings.t(0.32))
		tw.tween_property(b, "scale", Vector3.ONE * size * 0.15, Settings.t(0.32))
		tw.chain().tween_callback(b.queue_free)
	_last = here


## It bursts and is gone.
func pop(big := 1.0) -> void:
	trail = false
	DuelFx.glow(get_parent(), position, color, size * 4.0 * big, 0.35, 0.8)
	queue_free()
