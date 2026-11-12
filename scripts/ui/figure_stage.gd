class_name FigureStage
extends SubViewportContainer
## A small lit 3D stage that shows one person turning slowly. Used wherever a screen wants to
## show a duelist in full: the Academy hub, result cards.

var figure: RoamFigure
var spin := 0.5
var auto := true
var _vp: SubViewport
var _stage: Node3D


func _init(px := Vector2(420, 600)) -> void:
	stretch = true
	custom_minimum_size = px
	size = px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	_stage = Node3D.new()
	_vp.add_child(_stage)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.82, 0.88, 1.0)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	_stage.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.rotation_degrees = Vector3(-28, 28, 0)
	_stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.9
	rim.light_color = Color(0.6, 0.85, 1.0)
	rim.rotation_degrees = Vector3(-12, 155, 0)
	_stage.add_child(rim)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.52
	cm.bottom_radius = 0.58
	cm.height = 0.06
	disc.mesh = cm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.08, 0.13, 0.22)
	dm.metallic = 0.5
	dm.roughness = 0.35
	disc.material_override = dm
	disc.position.y = -0.03
	_stage.add_child(disc)
	var cam := Camera3D.new()
	cam.fov = 30
	cam.position = Vector3(0, 0.98, 4.35)
	_stage.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0, 0.9, 0))
	cam.current = true


## Show this character. `uniform` is a dorm color (or null for their own clothes).
func show_person(key: String, uniform = null) -> void:
	if figure and is_instance_valid(figure):
		figure.queue_free()
	figure = RoamFigure.new()
	_stage.add_child(figure)
	figure.setup(key, Color.WHITE, "", false)
	if uniform is Color:
		figure.wear_uniform(uniform)
	figure.rotation.y = spin


func _process(delta: float) -> void:
	if auto:
		spin += delta * 0.45
	if figure and is_instance_valid(figure):
		figure.rotation.y = spin
