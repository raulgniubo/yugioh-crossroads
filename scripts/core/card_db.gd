extends Node
## Card database and card textures.
##
## Built-in card data means the game always runs. If the player has run
## tools/fetch_cards.py, real card images are loaded from their card folder
## (Settings.card_folder): cards/<id>.jpg for full cards, art/<id>.jpg for artwork.

const CARD_SIZE := Vector2i(420, 612)

const ATTRIBUTE_COLORS := {
	"DARK": [Color("2a1240"), Color("7b2fbf")],
	"LIGHT": [Color("6b5a1e"), Color("f2d36b")],
	"EARTH": [Color("3b2a17"), Color("a8763e")],
	"WIND": [Color("123a2b"), Color("4fd18b")],
	"WATER": [Color("0f2a4a"), Color("3a8cff")],
	"FIRE": [Color("4a1410"), Color("ff6a3a")],
}

var _face_cache := {}
var _art_cache := {}
var _back_texture: Texture2D
var _font_title: Font
var _font_body: Font


func _ready() -> void:
	_font_title = load("res://assets/fonts/Rajdhani-Bold.ttf")
	_font_body = load("res://assets/fonts/Inter.ttf")
	_load_external_data()


func get_card(id: int) -> Dictionary:
	var d := CardData.get_card(id)
	if CardData.EXT.has(id) and CardData.CARDS.has(id):
		d["desc"] = CardData.EXT[id].get("desc", "")
	return d


func has_real_images() -> bool:
	return DirAccess.dir_exists_absolute(Settings.card_folder.path_join("cards"))


## Full card face. Real card image if available, otherwise a generated placeholder.
func get_face(id: int) -> Texture2D:
	if _face_cache.has(id):
		return _face_cache[id]
	var tex := _load_image(Settings.card_folder.path_join("cards/%d.jpg" % id))
	if tex == null:
		tex = _make_placeholder_face(id)
	_face_cache[id] = tex
	return tex


## Artwork only (for holograms). Falls back to the full face.
func get_art(id: int) -> Texture2D:
	if _art_cache.has(id):
		return _art_cache[id]
	var tex := _load_image(Settings.card_folder.path_join("art/%d.jpg" % id))
	if tex == null:
		tex = get_face(id)
	_art_cache[id] = tex
	return tex


## The backs in the duel being played: [yours, the opponent's]. Empty = everybody's default.
var duel_backs: Array = []


func duel_back(owner: int) -> Texture2D:
	if owner >= 0 and owner < duel_backs.size() and duel_backs[owner] != null:
		return duel_backs[owner]
	return get_back()


func get_back() -> Texture2D:
	if _back_texture == null:
		_back_texture = _make_back()
	return _back_texture


func clear_cache() -> void:
	_face_cache.clear()
	_art_cache.clear()
	for c in get_children():
		c.queue_free()
	_back_texture = null
	_load_external_data()


func _load_image(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _load_external_data() -> void:
	CardData.load_external(Settings.card_folder)


# ---------------------------------------------------------------- placeholders

func _new_viewport() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = CARD_SIZE
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.disable_3d = true
	add_child(vp)
	return vp


func _rect(parent: Control, pos: Vector2, size: Vector2, color: Color, radius := 0) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


func _label(parent: Control, text: String, pos: Vector2, size: Vector2, font: Font, font_size: int,
		color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _make_placeholder_face(id: int) -> Texture2D:
	var d := get_card(id)
	var vp := _new_viewport()
	var root := Control.new()
	root.size = Vector2(CARD_SIZE)
	vp.add_child(root)
	var kind: String = d.get("kind", "monster")
	var is_trap := kind == "trap"
	var is_spell: bool = kind == "spell" or is_trap
	var ftype: String = d.get("frame", "normal")
	var frame: Color = {"spell": Color("1a8f80"), "trap": Color("a8327a"), "effect": Color("c9783e"), "fusion": Color("8a55b8"),
			"synchro": Color("d8d8dc"), "xyz": Color("3a3a44"), "ritual": Color("4d7fd0")}.get(ftype, Color("c79a55"))
	var frame_dark := frame.darkened(0.45)
	_rect(root, Vector2.ZERO, Vector2(CARD_SIZE), Color("101318"))
	_rect(root, Vector2(8, 8), Vector2(404, 596), frame, 10)
	# Name bar
	_rect(root, Vector2(22, 22), Vector2(376, 54), frame.lightened(0.25), 6)
	_label(root, d.get("name", "Unknown"), Vector2(32, 22), Vector2(300, 54), _font_title, 30, Color("161616"))
	# Attribute badge
	var attr: String = ("TRAP" if is_trap else "SPELL") if is_spell else str(d.get("attribute", "DARK"))
	var colors: Array = ATTRIBUTE_COLORS.get(attr, [Color("3d0f2c"), Color("e24da0")] if is_trap else [Color("0f3d3a"), Color("2de2c6")])
	_rect(root, Vector2(340, 26), Vector2(48, 46), colors[1], 23)
	_label(root, attr.substr(0, 1), Vector2(340, 26), Vector2(48, 46), _font_title, 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	# Level / type line
	var sub: String = str(d.get("st", "")).capitalize()
	if sub == "Normal":
		sub = ""
	var line := ("%s %s CARD" % [sub.to_upper(), "TRAP" if is_trap else "SPELL"]).strip_edges() if is_spell else "★".repeat(int(d.get("level", 4)))
	if ftype == "xyz":
		frame_dark = Color("f0d060")
	_label(root, line, Vector2(30, 80), Vector2(360, 34), _font_title, 26, frame_dark.darkened(0.3), HORIZONTAL_ALIGNMENT_RIGHT)
	# Artwork: attribute gradient with a big monogram
	var art_box := _rect(root, Vector2(46, 118), Vector2(328, 300), Color.BLACK, 2)
	var grad := Gradient.new()
	grad.set_color(0, colors[0])
	grad.set_color(1, colors[1])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(1.1, 1.1)
	gt.width = 128
	gt.height = 128
	var tr := TextureRect.new()
	tr.texture = gt
	tr.position = Vector2(4, 4)
	tr.size = Vector2(320, 292)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_box.add_child(tr)
	var initials := ""
	for word in str(d.get("name", "?")).split(" ", false):
		if initials.length() < 2 and word.length() > 0 and word[0] == word[0].to_upper():
			initials += word[0]
	var mono := _label(art_box, initials, Vector2(4, 4), Vector2(320, 292), _font_title, 150,
			Color(1, 1, 1, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
	mono.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	mono.add_theme_constant_override("shadow_offset_y", 6)
	# Text box
	_rect(root, Vector2(26, 430), Vector2(368, 160), Color("efe3c6") if not is_spell else (Color("efd9e6") if is_trap else Color("d9efe9")), 4)
	if is_spell:
		var body: String = str(d.get("text", d.get("desc", "")))
		var desc := _label(root, body, Vector2(38, 438), Vector2(344, 146), _font_body, 15 if body.length() > 150 else 19, Color("1b1b1b"))
		desc.clip_contents = true
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		desc.clip_text = false
	else:
		_label(root, "[ %s ]" % d.get("race", ""), Vector2(38, 438), Vector2(344, 36), _font_title, 26, Color("1b1b1b"))
		_label(root, {"effect": "Effect Monster", "fusion": "Fusion Monster", "synchro": "Synchro Monster", "xyz": "Xyz Monster",
				"ritual": "Ritual Monster"}.get(ftype, "Normal Monster"), Vector2(38, 474), Vector2(344, 30), _font_body, 18, Color("555555"))
		_rect(root, Vector2(38, 540), Vector2(344, 2), Color("1b1b1b"))
		_label(root, "ATK/%d   DEF/%d" % [d.get("atk", 0), d.get("def", 0)], Vector2(38, 544), Vector2(344, 40),
				_font_title, 30, Color("1b1b1b"), HORIZONTAL_ALIGNMENT_RIGHT)
	return vp.get_texture()


func _make_back() -> Texture2D:
	var vp := _new_viewport()
	var root := Control.new()
	root.size = Vector2(CARD_SIZE)
	vp.add_child(root)
	_rect(root, Vector2.ZERO, Vector2(CARD_SIZE), Color("0a0f1a"))
	_rect(root, Vector2(10, 10), Vector2(400, 592), Color("101a2e"), 12)
	var grad := Gradient.new()
	grad.set_color(0, Color("1fd1c1"))
	grad.set_color(1, Color(0.04, 0.08, 0.16, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.position = Vector2(30, 126)
	tr.size = Vector2(360, 360)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(tr)
	for r in [150, 110, 70]:
		var ring := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(0.55, 0.95, 1.0, 0.55)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(r)
		ring.add_theme_stylebox_override("panel", sb)
		ring.position = Vector2(210 - r, 306 - r)
		ring.size = Vector2(r * 2, r * 2)
		root.add_child(ring)
	_label(root, "CROSSROADS", Vector2(10, 520), Vector2(400, 50), _font_title, 40,
			Color(0.75, 0.97, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	return vp.get_texture()
