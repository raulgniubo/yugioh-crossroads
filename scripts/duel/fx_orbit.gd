class_name FxOrbit
extends Node3D
## The Xyz Materials of a monster (0.57.0): one light for each, circling its card. When a
## material is used the light flies off and bursts; when the card leaves, they all go.
## The board keeps one per Xyz Monster and tells it how many it holds (set_count).

const GOLD := Color("ffd23a")

var card: Card3D
var _orbs: Array = []       # MeshInstance3D
var _t := 0.0


func set_count(n: int) -> void:
	n = clampi(n, 0, 6)
	while _orbs.size() < n:
		var m := DuelFx._mat("glow", DuelFx.HEAD + DuelFx.GLOW, {"color": GOLD if _orbs.size() % 2 == 0 else Color("fff0b0"), "energy": 3.0, "alpha": 1.0, "flare": 0.5})
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.26, 0.26)
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3.ONE * 0.1
		add_child(mi)
		mi.create_tween().tween_property(mi, "scale", Vector3.ONE, Settings.t(0.25)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_orbs.append(mi)
	while _orbs.size() > n:
		var gone: MeshInstance3D = _orbs.pop_back()
		_use(gone)


## One material is used: its light flies up and bursts.
func _use(mi: MeshInstance3D) -> void:
	var at := mi.global_position
	remove_child(mi)
	get_parent().add_child(mi)
	mi.global_position = at
	var tw := mi.create_tween()
	tw.tween_property(mi, "position", at + Vector3(0, 0.9, 0), Settings.t(0.22)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		DuelFx.glow(mi.get_parent(), mi.position, GOLD, 1.5, 0.35, 1.0)
		DuelFx.sparks(mi.get_parent(), mi.position, GOLD, 12, 2.5, 0.5, 0.5, -3.0, 0.04)
		mi.queue_free())
	Sfx.play("sparkle", -8.0, 1.3)


func _process(delta: float) -> void:
	if card == null or not is_instance_valid(card):
		for mi in _orbs:
			if is_instance_valid(mi):
				DuelFx.glow(get_parent(), (mi as MeshInstance3D).global_position, GOLD, 0.8, 0.3)
		queue_free()
		return
	_t += delta
	global_position = card.global_position
	visible = card.visible
	var n := _orbs.size()
	for i in n:
		var a := _t * 2.2 + TAU * i / n
		var mi: MeshInstance3D = _orbs[i]
		# A tilted circle around the card, so the lights pass in front of it and behind it.
		mi.position = Vector3(cos(a) * 0.56, 0.32 + sin(a * 1.0 + 0.6) * 0.14, sin(a) * 0.5)
