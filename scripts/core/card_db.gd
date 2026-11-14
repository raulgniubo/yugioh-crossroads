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


## The picture of a card for a cover (a pack wrapper, a deck box): its artwork, and which part of
## that texture to show. If only the full card face is on disk, the art window is cut out of it.
## Returns [texture, region].
func cover_art(id: int) -> Array:
	var tex := get_art(id)
	if tex == null:
		return [null, Rect2()]
	var ts := tex.get_size()
	var region := Rect2(Vector2.ZERO, ts)
	if ts.x / maxf(ts.y, 1.0) < 0.82:
		# A full card face: the artwork sits in a square window under the name bar.
		region = Rect2(ts.x * 0.125, ts.y * 0.185, ts.x * 0.75, ts.x * 0.75)
	return [tex, region]


## Fit `region` of a picture into `into` so it fills it (cut, never stretched). `focus` is
## which part to keep when it has to cut: 0 = top / left, 0.5 = middle.
func cover_fit(region: Rect2, into: Vector2, focus := Vector2(0.5, 0.35)) -> Rect2:
	var want := into.x / maxf(into.y, 1.0)
	if region.size.x / maxf(region.size.y, 1.0) > want:
		var nw := region.size.y * want
		return Rect2(region.position.x + (region.size.x - nw) * focus.x, region.position.y, nw, region.size.y)
	var nh := region.size.x / want
	return Rect2(region.position.x, region.position.y + (region.size.y - nh) * focus.y, region.size.x, nh)


## The backs in the duel being played: [yours, the opponent's]. Empty = everybody's default.
var duel_backs: Array = []


func duel_back(owner: int) -> Texture2D:
	if owner >= 0 and owner < duel_backs.size() and duel_backs[owner] != null:
		return duel_backs[owner]
	return get_back()


## The default back of every card. A picture you put in the card folder as back.jpg (or
## back.png) is used when there is one; otherwise the game draws its own.
func get_back() -> Texture2D:
	if _back_texture == null:
		for ext in ["jpg", "png", "jpeg", "webp"]:
			_back_texture = _load_image(Settings.card_folder.path_join("back." + ext))
			if _back_texture != null:
				break
		if _back_texture == null:
			_back_texture = _make_back()
	return _back_texture


# ---------------------------------------------------------------- sleeves

## Monsters that have a sleeve of their own. Only the ones this game knows are offered.
const SLEEVE_ART := [89631139, 46986414, 74677422, 44508094, 84013237, 70781052, 23995346, 11901678, 60800381, 35809262,
	70095154, 73580471, 70902743, 93717133, 5405694, 10000020, 10000000, 10000010, 38033121, 6983839]
var _sleeve_cache := {}


## Every back you can put on your own cards: [{id, name}]. "default" is the plain back.
func sleeves() -> Array:
	var out: Array = [{"id": "default", "name": "Classic"}, {"id": "crossroads", "name": "Crossroads"}]
	for id in SLEEVE_ART:
		var d := CardData.get_card(int(id))
		if not d.is_empty() and str(d.get("name", "")) != "":
			out.append({"id": "art:%d" % int(id), "name": str(d["name"])})
	return out


func sleeve_texture(sid: String) -> Texture2D:
	if sid == "" or sid == "default":
		return get_back()
	if _sleeve_cache.has(sid):
		return _sleeve_cache[sid]
	var tex: Texture2D = null
	if sid == "crossroads":
		tex = _make_back()
	elif sid.begins_with("art:"):
		tex = _make_sleeve(int(sid.trim_prefix("art:")))
	if tex == null:
		tex = get_back()
	_sleeve_cache[sid] = tex
	return tex


## The back of your own cards.
func player_back() -> Texture2D:
	return sleeve_texture(Settings.sleeve)


## A character's own sleeve: their ace monster, when the game knows it.
func back_for_char(key: String) -> Texture2D:
	var ace := int(Characters.get_char(key).get("ace", 0))
	if ace > 0 and not CardData.get_card(ace).is_empty():
		return sleeve_texture("art:%d" % ace)
	return get_back()


## A sleeve built around one monster: its artwork filling the card, darkened at the edges,
## inside a double gold frame with the name along the bottom.
func _make_sleeve(id: int) -> Texture2D:
	var d := get_card(id)
	var art := _load_image(Settings.card_folder.path_join("art/%d.jpg" % id))
	var vp := _new_viewport()
	var root := Control.new()
	root.size = Vector2(CARD_SIZE)
	vp.add_child(root)
	var tint: Color = ATTRIBUTE_COLORS.get(d.get("attribute", ""), [Color("2a3350"), Color("5a6ea8")])[1]
	_rect(root, Vector2.ZERO, Vector2(CARD_SIZE), Color("07090f"))
	var w := float(CARD_SIZE.x)
	var h := float(CARD_SIZE.y)
	if art != null:
		# The picture fills the sleeve, centered, cut to the frame. (Size goes last: a
		# TextureRect that still follows its texture's size would grow to the picture.)
		var clip := Control.new()
		clip.position = Vector2(14, 14)
		clip.size = Vector2(w - 28, h - 28)
		clip.clip_contents = true
		root.add_child(clip)
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture = art
		clip.add_child(tr)
		tr.position = Vector2.ZERO
		tr.size = clip.size
	else:
		# No artwork on disk: a crest in the monster's color with its initials.
		var grad := Gradient.new()
		grad.set_color(0, tint.lightened(0.15))
		grad.set_color(1, Color(0.03, 0.04, 0.08, 1))
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.45)
		gt.fill_to = Vector2(0.5, -0.1)
		var bg := TextureRect.new()
		bg.texture = gt
		bg.position = Vector2(14, 14)
		bg.size = Vector2(w - 28, h - 28)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		root.add_child(bg)
		var initials := ""
		for word in str(d.get("name", "?")).replace("-", " ").split(" ", false):
			if initials.length() < 3 and word.length() > 0:
				initials += word[0].to_upper()
		_label(root, initials, Vector2(0, h * 0.26), Vector2(w, h * 0.36), _font_title, 150, Color(1, 1, 1, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	# Vignette, so the frame and the name read on any picture.
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	vg.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.12), Color(0, 0, 0, 0.82)])
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.46)
	vt.fill_to = Vector2(0.5, -0.22)
	var vr := TextureRect.new()
	vr.texture = vt
	vr.position = Vector2(14, 14)
	vr.size = Vector2(w - 28, h - 28)
	vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(vr)
	for fr in [[8.0, 5, Color("d9b25a")], [20.0, 2, Color(1.0, 0.9, 0.62, 0.85)]]:
		var frame := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.draw_center = false
		sb.border_color = fr[2]
		sb.set_border_width_all(int(fr[1]))
		sb.set_corner_radius_all(14)
		frame.add_theme_stylebox_override("panel", sb)
		frame.position = Vector2(float(fr[0]), float(fr[0]))
		frame.size = Vector2(w - float(fr[0]) * 2.0, h - float(fr[0]) * 2.0)
		root.add_child(frame)
	# Corner studs and the name plate.
	for cx: float in [34.0, w - 34.0]:
		for cy: float in [34.0, h - 34.0]:
			var stud := _rect(root, Vector2(cx - 9, cy - 9), Vector2(18, 18), Color("d9b25a"), 9)
			stud.rotation = PI / 4.0
			stud.pivot_offset = Vector2(9, 9)
	_rect(root, Vector2(48, h - 84), Vector2(w - 96, 44), Color(0.03, 0.04, 0.07, 0.86), 10)
	_rect(root, Vector2(48, h - 86), Vector2(w - 96, 2), Color("d9b25a"))
	_label(root, str(d.get("name", "")).to_upper(), Vector2(56, h - 84), Vector2(w - 112, 44), _font_title, 24, Color("ffe9b0"), HORIZONTAL_ALIGNMENT_CENTER)
	return vp.get_texture()


func clear_cache() -> void:
	_face_cache.clear()
	_sleeve_cache.clear()
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
	if d.get("partner", false):
		# Lumen's own card: she is on it, alive, instead of a monogram.
		var live := TextureRect.new()
		live.texture = LumenSpirit.portrait(self)
		live.position = Vector2(4, 4)
		live.size = Vector2(320, 292)
		live.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		live.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art_box.add_child(live)
		# Draw for a moment (her picture needs a few frames to exist), then hold still.
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		LumenSpirit.wake(2.5)
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(vp):
				vp.render_target_update_mode = SubViewport.UPDATE_DISABLED)
	var initials := ""
	for word in str(d.get("name", "?")).split(" ", false):
		if initials.length() < 2 and word.length() > 0 and word[0] == word[0].to_upper():
			initials += word[0]
	if d.get("partner", false):
		initials = ""
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
		if str(d.get("text", "")) != "":
			var fx_text := _label(root, str(d["text"]), Vector2(38, 470), Vector2(344, 70), _font_body, 12, Color("2b2b2b"))
			fx_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fx_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			fx_text.clip_text = false
		else:
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
