extends Node
## Character portraits. Loads <card folder>/characters/<key>.png|jpg|webp when present
## (see tools/fetch_characters.py), otherwise draws a stylized placeholder.
## "player" uses <card folder>/characters/player.png, or an emblem built from the profile.

const SIZE := Vector2i(512, 640)

var _cache := {}


func _ready() -> void:
	Profile.changed.connect(func(): _forget("player"))


func folder() -> String:
	return Settings.card_folder.path_join("characters")


func has_real(key: String) -> bool:
	return _find_file(key) != "" or Avatars.has_avatar(key)


func get_portrait(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = Avatars.portrait(key) if Avatars.has_avatar(key) else null
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


func clear_cache() -> void:
	for k in _cache.keys():
		_forget(k)


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
				"color": Profile.color(), "title": "Duelist Lv %d" % Profile.level()}
	return Characters.get_char(key)


func _make_placeholder(key: String) -> Texture2D:
	var d := info(key)
	var col: Color = d.get("color", UITheme.ACCENT)
	var vp := SubViewport.new()
	vp.name = "vp_" + key
	vp.size = SIZE
	vp.transparent_bg = true
	vp.disable_3d = true
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
		_emblem(root, Profile.emblem, col)
	else:
		var initial := UITheme.label(str(d.get("short", "?")).substr(0, 1), 340, Color(1, 1, 1, 0.92), UITheme.title_font())
		initial.size = Vector2(SIZE.x, 460)
		initial.position = Vector2(0, 70)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.add_theme_color_override("font_shadow_color", Color(col, 0.9))
		initial.add_theme_constant_override("shadow_outline_size", 40)
		root.add_child(initial)
	return vp.get_texture()


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
