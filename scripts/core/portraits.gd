extends Node
## Character portraits. Loads <card folder>/characters/<key>.png|jpg|webp when present
## (see tools/fetch_characters.py), otherwise draws a stylized placeholder.
## "player" uses <card folder>/characters/player.png, or an emblem built from the profile.

const SIZE := Vector2i(512, 640)

var _cache := {}


var _look := ""


func _ready() -> void:
	_look = _look_sig()
	Profile.changed.connect(_on_profile)


## The player's picture is only thrown away when something you can see changed. A win or a
## loss also saves the profile, and that must not blank the portrait on screen.
func _on_profile() -> void:
	var now := _look_sig()
	if now != _look:
		_look = now
		_forget("player")


func _look_sig() -> String:
	return str([Profile.gender, Profile.color_index, Profile.emblem, Profile.tints, Profile.look_body, Profile.look_hair,
			Profile.look_outfit, Profile.look_height, Profile.duelist_name])


func folder() -> String:
	return Settings.card_folder.path_join("characters")


func has_real(key: String) -> bool:
	return _find_file(key) != "" or Avatars.has_avatar(key)


## `hi` = this one is about to be shown big: render it at double size (3D portraits only).
func get_portrait(key: String, hi := false) -> Texture2D:
	if hi and Avatars.has_avatar(key):
		Avatars.portrait(key, true)
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = Avatars.portrait(key, hi) if Avatars.has_avatar(key) else null
	if tex != null:
		_cache[key] = tex
		return tex
	var path := _find_file(key)
	if path != "":
		var img := Image.load_from_file(path)
		if img and not img.is_empty():
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	if tex == null:
		tex = _make_placeholder(key)
	_cache[key] = tex
	return tex


## Sent after every cached portrait was thrown away: anything showing one must ask again.
signal flushed


func clear_cache() -> void:
	for k in _cache.keys():
		_forget(k)
	flushed.emit()


func _forget(key: String) -> void:
	_cache.erase(key)
	Avatars.forget(key)
	var vp := get_node_or_null("vp_" + key)
	if vp:
		vp.name = "old_" + str(randi())
		vp.queue_free()


func _find_file(key: String) -> String:
	for ext in ["png", "webp", "jpg", "jpeg"]:
		var p := folder().path_join("%s.%s" % [key, ext])
		if FileAccess.file_exists(p):
			return p
	return ""


func info(key: String) -> Dictionary:
	if key == "player":
		return {"name": Profile.duelist_name, "short": Profile.duelist_name, "era": "Crossroads",
				"color": Profile.color(), "title": Profile.title_text()}
	return Characters.get_char(key)


func _make_placeholder(key: String) -> Texture2D:
	var d := info(key)
	var col: Color = d.get("color", UITheme.ACCENT)
	var vp := SubViewport.new()
	vp.name = "vp_" + key
	vp.size = SIZE
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var root := Control.new()
	root.size = Vector2(SIZE)
	vp.add_child(root)
	# Background glow
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([col.lightened(0.15), col.darkened(0.55), Color(0.02, 0.03, 0.06, 1)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.38)
	gt.fill_to = Vector2(1.15, 1.05)
	var bg := TextureRect.new()
	bg.texture = gt
	bg.size = Vector2(SIZE)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(bg)
	# Speed lines
	for i in 9:
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.05 + 0.03 * (i % 3))
		line.size = Vector2(26 + (i % 4) * 14, 900)
		line.position = Vector2(-120 + i * 80, -120)
		line.rotation = deg_to_rad(18)
		root.add_child(line)
	if key == "player":
		root.modulate.a = 1.0
		_emblem(root, Profile.emblem, col)
		root.get_child(root.get_child_count() - 1).modulate.a = 0.35
	_bust(vp, key, col)
	return vp.get_texture()


## A cel-shaded 3D bust of the character's stand-in model in front of the drawn background.
func _bust(vp: SubViewport, key: String, col: Color) -> void:
	var stage := Node3D.new()
	vp.add_child(stage)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.background_canvas_max_layer = 0
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.88, 1.0)
	e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	stage.add_child(we)
	var key_l := DirectionalLight3D.new()
	key_l.light_energy = 1.0
	key_l.rotation_degrees = Vector3(-20, 28, 0)
	stage.add_child(key_l)
	var rim := DirectionalLight3D.new()
	rim.light_color = col.lightened(0.4)
	rim.light_energy = 0.8
	rim.rotation_degrees = Vector3(-10, 160, 0)
	stage.add_child(rim)
	var m := DuelistModel.new()
	stage.add_child(m)
	m.build(DuelistModel.player_look() if key == "player" else DuelistModel.look_for(key, col))
	m.set_process(false)
	m.rotation.y = -0.25
	var cam := Camera3D.new()
	cam.fov = 26
	cam.position = Vector3(0.0, 1.72, 2.0)
	stage.add_child(cam)
	cam.look_at(Vector3(0, 1.6, 0))
	cam.current = true


func _emblem(root: Control, style: int, col: Color) -> void:
	var c := Vector2(SIZE.x / 2.0, 300)
	var pts := PackedVector2Array()
	match style:
		0:  # Star
			for i in 10:
				var r := 170.0 if i % 2 == 0 else 72.0
				var a := -PI / 2.0 + i * PI / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
		1:  # Wing
			pts = PackedVector2Array([c + Vector2(0, 120), c + Vector2(-190, -110), c + Vector2(-60, -40),
					c + Vector2(0, -170), c + Vector2(60, -40), c + Vector2(190, -110)])
		2:  # Blade
			pts = PackedVector2Array([c + Vector2(0, -200), c + Vector2(60, 0), c + Vector2(0, 200), c + Vector2(-60, 0)])
		_:  # Crown
			pts = PackedVector2Array([c + Vector2(-170, 110), c + Vector2(-170, -90), c + Vector2(-85, 0),
					c + Vector2(0, -150), c + Vector2(85, 0), c + Vector2(170, -90), c + Vector2(170, 110)])
	var glow := Polygon2D.new()
	glow.polygon = pts
	glow.color = Color(col, 0.35)
	glow.scale = Vector2(1.12, 1.12)
	glow.position = c * (1.0 - 1.12)
	root.add_child(glow)
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = Color(1, 1, 1, 0.95)
	root.add_child(poly)
	var inner := Polygon2D.new()
	inner.polygon = pts
	inner.color = col.lightened(0.2)
	inner.scale = Vector2(0.78, 0.78)
	inner.position = c * (1.0 - 0.78)
	root.add_child(inner)
