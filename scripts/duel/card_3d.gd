class_name Card3D
extends Node3D
## A physical card: front, back, a thin core, a glow outline and a pick area.
## Lies in the XY plane facing +Z. Rotate it to lay it on the table.

signal clicked(card: Card3D)
signal hovered(card: Card3D, inside: bool)

const SIZE := Vector2(0.59, 0.86)

var card_id := 0
var inst = null  # DuelState.CardInst when used in a duel

var _front: MeshInstance3D
var _back: MeshInstance3D
var _core: MeshInstance3D
var _glow: MeshInstance3D
var _front_mat: StandardMaterial3D
var _back_mat: StandardMaterial3D
var _glow_mat: StandardMaterial3D
var _area: Area3D


func _init() -> void:
	_front_mat = _card_material()
	_back_mat = _card_material()
	_front = _quad(_front_mat, 0.004)
	_back = _quad(_back_mat, -0.004)
	_back.rotation.y = PI
	_core = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(SIZE.x * 0.99, SIZE.y * 0.99, 0.006)
	_core.mesh = box
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color("0b0e14")
	_core.material_override = core_mat
	add_child(_core)
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.albedo_color = Color(UITheme.ACCENT, 0.9)
	_glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glow = MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = SIZE + Vector2(0.07, 0.07)
	_glow.mesh = gq
	_glow.material_override = _glow_mat
	_glow.position.z = -0.006
	_glow.visible = false
	add_child(_glow)
	_area = Area3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(SIZE.x, SIZE.y, 0.04)
	shape.shape = bs
	_area.add_child(shape)
	_area.input_ray_pickable = true
	add_child(_area)
	_area.input_event.connect(_on_input)
	_area.mouse_entered.connect(func(): hovered.emit(self, true))
	_area.mouse_exited.connect(func(): hovered.emit(self, false))


func _card_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 0.45
	m.metallic_specular = 0.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.emission_enabled = true
	m.emission_energy_multiplier = 0.18
	return m


func _quad(mat: StandardMaterial3D, z: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = SIZE
	mi.mesh = q
	mi.material_override = mat
	mi.position.z = z
	add_child(mi)
	return mi


func setup(id: int) -> void:
	card_id = id
	var face := Cards.get_face(id)
	_front_mat.albedo_texture = face
	_front_mat.emission_texture = face
	var back := Cards.get_back()
	_back_mat.albedo_texture = back
	_back_mat.emission_texture = back


func set_pickable(on: bool) -> void:
	_area.input_ray_pickable = on


func set_glow(on: bool, color := UITheme.ACCENT) -> void:
	_glow.visible = on
	_glow_mat.albedo_color = Color(color, 0.9)


func set_alpha(a: float) -> void:
	for m in [_front_mat, _back_mat]:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if a < 0.999 else BaseMaterial3D.TRANSPARENCY_DISABLED
		m.albedo_color.a = a
	_core.visible = a > 0.5


func flash(amount: float) -> void:
	_front_mat.emission_energy_multiplier = 0.18 + amount


func _on_input(_cam: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		clicked.emit(self)
