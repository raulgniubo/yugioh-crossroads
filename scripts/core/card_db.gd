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


## Card pictures in memory (0.63.1). Every picture ever shown used to stay in memory at full size
## (813 x 1185, about 4 MB each on the graphics card): a few duels and a few packs later that was
## gigabytes, the frame rate fell, and on a smaller graphics card new pictures came up as white boxes.
## Now: a picture is kept at the size it is shown at (512 wide; the full size only for the views that
## show one card large), and only the most recently used ones are kept. One still on screen stays
## alive whatever this list does: the list only decides what is kept ready for next time.
const FACE_WIDE := 512
const FACE_KEEP := 130
const FULL_KEEP := 6
const ART_KEEP := 48
## Small tiles (a grid of cards about 110 wide: the deck editor, a pack's summary, a deck's list).
const THUMB_WIDE := 256
const THUMB_KEEP := 240
var _full_cache := {}
var _thumb_cache := {}
var _made_faces := {}      # id -> a face drawn here for one of the game's own cards (kept for good)
var _made_lru := {}        # id -> a face drawn here for a card with no picture on disk (the recent ones)
const MADE_KEEP := 140
var _baking: Array = []    # [viewport, texture, frames waited] still being drawn


## After a frame is drawn: copy the faces drawn by now into their pictures and free their viewports.
func _bake_step() -> void:
	var left: Array = []
	for b in _baking:
		var vp: SubViewport = b[0]
		b[2] = int(b[2]) + 1
		if not is_instance_valid(vp):
			continue
		var img: Image = vp.get_texture().get_image() if int(b[2]) >= 2 else null
		if img != null and not img.is_empty():
			(b[1] as ImageTexture).set_image(img)
			vp.queue_free()
		elif int(b[2]) < 30:
			left.append(b)
		else:
			vp.queue_free()
	_baking = left
	if _baking.is_empty() and RenderingServer.frame_post_draw.is_connected(_bake_step):
		RenderingServer.frame_post_draw.disconnect(_bake_step)


## A drawn face as a plain picture: the viewport draws it once, its picture is copied into the texture
## handed out (everyone holding it sees the picture appear) and the viewport is freed.
func _bake_face(id: int) -> Texture2D:
	var before := get_child_count()
	var vt := _make_placeholder_face(id)
	if get_child_count() <= before or DisplayServer.get_name() == "headless":
		return vt
	var vp := get_child(get_child_count() - 1) as SubViewport
	if vp == null:
		return vt
	var tex := ImageTexture.create_from_image(Image.create(CARD_SIZE.x, CARD_SIZE.y, false, Image.FORMAT_RGBA8))
	_baking.append([vp, tex, 0])
	if not RenderingServer.frame_post_draw.is_connected(_bake_step):
		RenderingServer.frame_post_draw.connect(_bake_step)
	return tex


func _kept(cache: Dictionary, id: int):
	if not cache.has(id):
		return null
	var t = cache[id]
	cache.erase(id)      # (to the back of the line: the front of the line is what goes first)
	cache[id] = t
	return t


func _keep(cache: Dictionary, id: int, tex, most: int) -> void:
	cache[id] = tex
	while cache.size() > most:
		cache.erase(cache.keys()[0])


## Can this callback still be called? (Callers that may be freed before their picture arrives pass
## a callback made in a static function holding a weakref, see AlbumSlot.)
static func _alive(give: Callable) -> bool:
	return give.is_valid()


## Full card face. Real card image if available, otherwise a generated placeholder.
## `big`: for a view that shows this one card large (the album's detail, a pack's reveal).
func get_face(id: int, big := false) -> Texture2D:
	var cache: Dictionary = _full_cache if big else _face_cache
	var have = _kept(cache, id)
	if have != null:
		return have
	var wide := 0 if big else FACE_WIDE
	var tex := _load_image(Settings.card_folder.path_join("cards/%d.jpg" % id), wide)
	if tex == null and CardData.IMAGE_ALT.has(id):
		tex = _load_image(Settings.card_folder.path_join("cards/%d.jpg" % int(CardData.IMAGE_ALT[id])), wide)
	if tex == null:
		if big:
			return get_face(id)
		# The game's own cards (Lumen's, the Speed Spells): drawn on a small viewport of their own that
		# stays alive (some move for a moment), made once and kept for good. A few dozen at most.
		if CardData.is_original(id):
			if not _made_faces.has(id):
				_made_faces[id] = _make_placeholder_face(id)
			return _made_faces[id]
		# Any other card with no picture on disk: drawn once on a viewport, copied into a plain picture
		# and the viewport let go; only the most recent ones are kept (0.72.1: with every card in the
		# game, browsing the editor or the album kept hundreds of live viewports, over a GB of video
		# memory and every node of them, and the whole game crawled until it was restarted).
		var made = _kept(_made_lru, id)
		if made != null:
			return made
		var baked := _bake_face(id)
		_keep(_made_lru, id, baked, MADE_KEEP)
		return baked
	_keep(cache, id, tex, FULL_KEEP if big else FACE_KEEP)
	return tex


## The card's face for a small tile in a grid: a quarter of the memory of get_face.
func get_thumb(id: int) -> Texture2D:
	var have = _kept(_thumb_cache, id)
	if have != null:
		return have
	var path := Settings.card_folder.path_join("cards/%d.jpg" % id)
	if not FileAccess.file_exists(path) and CardData.IMAGE_ALT.has(id):
		path = Settings.card_folder.path_join("cards/%d.jpg" % int(CardData.IMAGE_ALT[id]))
	var tex := _load_image(path, THUMB_WIDE)
	if tex == null:
		return get_face(id)
	_keep(_thumb_cache, id, tex, THUMB_KEEP)
	return tex


## The same small picture without making the game wait for it: it is read on another thread and
## handed to `give` when it is ready (straight away if it is already in memory). A long list of
## cards fills in over a few frames instead of freezing while every picture is read.
var _thumb_wait := {}      # id -> the ones waiting for it

func thumb_later(id: int, give: Callable) -> void:
	var have = _kept(_thumb_cache, id)
	if have != null:
		give.call(have)
		return
	if _thumb_wait.has(id):
		(_thumb_wait[id] as Array).append(give)
		return
	var path := Settings.card_folder.path_join("cards/%d.jpg" % id)
	if not FileAccess.file_exists(path) and CardData.IMAGE_ALT.has(id):
		path = Settings.card_folder.path_join("cards/%d.jpg" % int(CardData.IMAGE_ALT[id]))
	if not FileAccess.file_exists(path):
		give.call(get_face(id))
		return
	_thumb_wait[id] = [give]
	_thumb_tasks[id] = WorkerThreadPool.add_task(func():
		var img := _read_image(path, THUMB_WIDE)
		_thumb_ready.call_deferred(id, img))


var _thumb_tasks := {}     # id -> the thread task reading it

## (Closing the game while pictures are still being read: let them finish first.)
func _exit_tree() -> void:
	for id in _thumb_tasks.keys():
		WorkerThreadPool.wait_for_task_completion(int(_thumb_tasks[id]))
	_thumb_tasks.clear()
	for k in _pre_tasks.keys():
		WorkerThreadPool.wait_for_task_completion(int(_pre_tasks[k]))
	_pre_tasks.clear()
	for id in _big_tasks.keys():
		WorkerThreadPool.wait_for_task_completion(int(_big_tasks[id]))
	_big_tasks.clear()


func _thumb_ready(id: int, img: Image) -> void:
	if _thumb_tasks.has(id):
		WorkerThreadPool.wait_for_task_completion(int(_thumb_tasks[id]))      # (it is done: this only hands its slot back)
		_thumb_tasks.erase(id)
	var waiting: Array = _thumb_wait.get(id, [])
	_thumb_wait.erase(id)
	var tex: Texture2D = null
	if img != null:
		tex = ImageTexture.create_from_image(img)
		_keep(_thumb_cache, id, tex, THUMB_KEEP)
	else:
		tex = get_face(id)
	for give in waiting:
		if _alive(give):
			(give as Callable).call(tex)


## The full-size face (as get_face(id, true)) read on another thread, handed to `give` when ready.
var _big_wait := {}
var _big_tasks := {}

func face_later(id: int, give: Callable) -> void:
	var have = _kept(_full_cache, id)
	if have != null:
		give.call(have)
		return
	if _big_wait.has(id):
		(_big_wait[id] as Array).append(give)
		return
	var path := Settings.card_folder.path_join("cards/%d.jpg" % id)
	if not FileAccess.file_exists(path) and CardData.IMAGE_ALT.has(id):
		path = Settings.card_folder.path_join("cards/%d.jpg" % int(CardData.IMAGE_ALT[id]))
	if not FileAccess.file_exists(path):
		give.call(get_face(id, true))
		return
	_big_wait[id] = [give]
	_big_tasks[id] = WorkerThreadPool.add_task(func():
		var img := _read_image(path, 0)
		_big_ready.call_deferred(id, img))


func _big_ready(id: int, img: Image) -> void:
	if _big_tasks.has(id):
		WorkerThreadPool.wait_for_task_completion(int(_big_tasks[id]))
		_big_tasks.erase(id)
	var waiting: Array = _big_wait.get(id, [])
	_big_wait.erase(id)
	var tex: Texture2D = null
	if img != null:
		tex = ImageTexture.create_from_image(img)
		_keep(_full_cache, id, tex, FULL_KEEP)
	else:
		tex = get_face(id, true)
	for give in waiting:
		if _alive(give):
			(give as Callable).call(tex)


## How many small pictures are being read right now (a list checks this before asking for more).
func thumbs_busy() -> int:
	return _thumb_wait.size()


func has_thumb(id: int) -> bool:
	return _thumb_cache.has(id)


## (0.80.1) The face and the artwork of a card read ahead on another thread, so whoever shows them next
## (a street duel's hologram) finds them in memory. A street duel used to read two pictures from disk
## on the main thread for every monster it put down: a 35-60 ms hitch each time, out in the worlds.
var _pre_tasks := {}      # "f<id>" / "a<id>" -> thread task

func prefetch(id: int) -> void:
	if Settings.card_folder == "" or id <= 0:
		return
	var fk := "f%d" % id
	if not _face_cache.has(id) and not _pre_tasks.has(fk):
		var fpath := Settings.card_folder.path_join("cards/%d.jpg" % id)
		if not FileAccess.file_exists(fpath) and CardData.IMAGE_ALT.has(id):
			fpath = Settings.card_folder.path_join("cards/%d.jpg" % int(CardData.IMAGE_ALT[id]))
		if FileAccess.file_exists(fpath):
			_pre_tasks[fk] = WorkerThreadPool.add_task(func():
				_pre_ready.call_deferred(fk, id, _read_image(fpath, FACE_WIDE)))
	var ak := "a%d" % id
	if not _art_cache.has(id) and not _pre_tasks.has(ak):
		var apath := Settings.card_folder.path_join("art/%d.jpg" % id)
		if not FileAccess.file_exists(apath) and CardData.IMAGE_ALT.has(id):
			apath = Settings.card_folder.path_join("art/%d.jpg" % int(CardData.IMAGE_ALT[id]))
		if FileAccess.file_exists(apath):
			_pre_tasks[ak] = WorkerThreadPool.add_task(func():
				_pre_ready.call_deferred(ak, id, _read_image(apath)))


func _pre_ready(k: String, id: int, img: Image) -> void:
	if _pre_tasks.has(k):
		WorkerThreadPool.wait_for_task_completion(int(_pre_tasks[k]))
		_pre_tasks.erase(k)
	if img == null:
		return
	if k.begins_with("f"):
		if not _face_cache.has(id):
			_keep(_face_cache, id, ImageTexture.create_from_image(img), FACE_KEEP)
	elif not _art_cache.has(id):
		_keep(_art_cache, id, ImageTexture.create_from_image(img), ART_KEEP)


## Both pictures prefetch() reads are in memory (or there is nothing on disk to read for them).
func pictures_ready(id: int) -> bool:
	if _pre_tasks.has("f%d" % id) or _pre_tasks.has("a%d" % id):
		return false
	var has_face := _face_cache.has(id) or not FileAccess.file_exists(Settings.card_folder.path_join("cards/%d.jpg" % id))
	var has_art := _art_cache.has(id) or not FileAccess.file_exists(Settings.card_folder.path_join("art/%d.jpg" % id))
	return has_face and has_art


## Artwork only (for holograms). Falls back to the full face.
func get_art(id: int) -> Texture2D:
	var have = _kept(_art_cache, id)
	if have != null:
		return have
	var tex := _load_image(Settings.card_folder.path_join("art/%d.jpg" % id))
	if tex == null and CardData.IMAGE_ALT.has(id):
		tex = _load_image(Settings.card_folder.path_join("art/%d.jpg" % int(CardData.IMAGE_ALT[id])))
	if tex == null:
		tex = get_face(id)
	_keep(_art_cache, id, tex, ART_KEEP)
	return tex


## The figure of a monster as it stands on the table (its hologram, its arrival). For the cards
## of this game that is the painted figure itself, cut out, and Lumen alive for her own card;
## for every other card it is the card's art.
func get_figure(id: int) -> Texture2D:
	if CardData.is_original(id):
		if id == CardData.LUMEN or id == 99200023:
			return LumenSpirit.portrait(self)
		var path := "res://assets/originals/%d.png" % id
		if ResourceLoader.exists(path):
			return load(path)
	return get_art(id)


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
		if CardData.is_original(id):
			# (a card of this game: its picture, without the band with its set number under it)
			region = Rect2(ts.x * 0.11, ts.y * 0.193, ts.x * 0.78, ts.y * 0.447)
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
	# Sleeves you earn by climbing the Duelist Rank.
	for t in [2, 3, 5, 6, 7]:
		out.append({"id": "rank:%d" % t, "name": Loc.t("%s Rank") % Loc.t(str(Goals.RANKS[t][0])), "need": t})
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
	elif sid.begins_with("rank:"):
		var t := clampi(int(sid.trim_prefix("rank:")), 0, Goals.RANKS.size() - 1)
		var c: Color = Goals.RANKS[t][2]
		tex = _make_back(c, Color(c, 0.75), str(Goals.RANKS[t][0]).to_upper(), c.darkened(0.55))
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
	var art := _load_image(Settings.card_folder.path_join("art/%d.jpg" % int(CardData.IMAGE_ALT.get(id, id))))
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
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture = art
		clip.add_child(tr)
		# The art is wider than the sleeve: cut it around the monster, not just the middle of
		# the picture (Ra, for one, stands to the side of its art).
		var asz := Vector2(art.get_size())
		var k := maxf(clip.size.x / asz.x, clip.size.y / asz.y)
		var drawn := asz * k
		var fx := art_focus(art.get_image())
		tr.size = drawn
		tr.position = Vector2(clampf(clip.size.x / 2.0 - fx * drawn.x, clip.size.x - drawn.x, 0.0), (clip.size.y - drawn.y) / 2.0)
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
	_full_cache.clear()
	_thumb_cache.clear()
	_made_faces.clear()
	_made_lru.clear()
	for c in get_children():
		if c is SubViewport:
			c.queue_free()
	_sleeve_cache.clear()
	_art_cache.clear()
	for c in get_children():
		c.queue_free()
	_back_texture = null
	_load_external_data()


## Where across a picture its subject stands (0 left .. 1 right): the middle of the busy part,
## weighed by how much each column differs from the picture's edges (the background).
static func art_focus(img: Image) -> float:
	if img == null or img.is_empty():
		return 0.5
	var s := img.duplicate() as Image
	if s.is_compressed():
		s.decompress()
	s.resize(48, 48, Image.INTERPOLATE_BILINEAR)
	var bg := Color(0, 0, 0)
	var n := 0
	for i in 48:
		for e in [s.get_pixel(0, i), s.get_pixel(47, i), s.get_pixel(i, 0), s.get_pixel(i, 47)]:
			bg += e
			n += 1
	bg = bg / float(n)
	var total := 0.0
	var sum := 0.0
	for x in 48:
		var col := 0.0
		for y in 48:
			var c := s.get_pixel(x, y)
			var dd := absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b)
			if x > 0:
				var l := s.get_pixel(x - 1, y)
				dd += (absf(c.r - l.r) + absf(c.g - l.g) + absf(c.b - l.b)) * 2.0
			col += dd
		col = col * col
		total += col
		sum += col * (x + 0.5) / 48.0
	if total <= 0.0:
		return 0.5
	# Only part of the way: a picture that really is centred stays centred.
	return lerpf(0.5, sum / total, 0.8)


## `wide`: bring a bigger picture down to this width (0 = as it is on disk).
func _load_image(path: String, wide := 0) -> Texture2D:
	var img := _read_image(path, wide)
	if img == null:
		return null
	return ImageTexture.create_from_image(img)


## Reads a picture from disk at the size it will be shown at. (Safe to call from another thread.)
func _read_image(path: String, wide := 0) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	if wide > 0 and img.get_width() > wide:
		while img.get_width() >= wide * 2 + 2:
			img.shrink_x2()      # (halving first keeps small text clean; one big bilinear step would make it grainy)
		img.resize(wide, int(round(img.get_height() * float(wide) / img.get_width())), Image.INTERPOLATE_BILINEAR)      # (3 ms; the sharper filters take 30)
	img.generate_mipmaps()
	return img


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
	# (Cut to its box before it is given its size: a label that may not cut its text cannot be
	# made narrower than the text, so a long line came out as wide as the line and ran off the
	# card instead of wrapping.)
	l.clip_text = true
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _make_placeholder_face(id: int) -> Texture2D:
	if CardData.is_original(id):
		return _make_original_face(id)
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
	var form: int = LUMEN_FORMS.get(id, -1)
	if form >= 0:
		# Lumen's own cards: she is on them, alive, instead of a monogram. Each form has its own
		# sky and its own signs round her (see _lumen_art).
		art_box.clip_contents = true
		_lumen_art(art_box, form, id)
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
	if form >= 0:
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
			var fx_text := _label(root, str(d["text"]), Vector2(38, 470), Vector2(344, 70), _font_body, 12 if str(d["text"]).length() <= 170 else 10, Color("2b2b2b"))
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


func _fill(parent: Control, pos: Vector2, size: Vector2, top: Color, bottom: Color) -> TextureRect:
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bottom)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 128
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture = gt
	tr.position = pos
	tr.size = size
	parent.add_child(tr)
	return tr


func _edge(parent: Control, pos: Vector2, size: Vector2, color: Color, width: int, radius: int, bg := Color(0, 0, 0, 0)) -> Panel:
	var p := _rect(parent, pos, size, bg, radius)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
	sb.border_color = color
	sb.set_border_width_all(width)
	sb.anti_aliasing = true
	return p


## The face of a card made for this game. It is its own set, so it has its own frame: the
## deep blue and gold of the rest of the game, with the color of the kind of card (Effect,
## Fusion, Synchro, Xyz, Spell, Trap) as the frame round it and behind its name.
func _make_original_face(id: int) -> Texture2D:
	var d := get_card(id)
	var vp := _new_viewport()
	var root := Control.new()
	root.size = Vector2(CARD_SIZE)
	vp.add_child(root)
	var kind: String = d.get("kind", "monster")
	var is_trap := kind == "trap"
	var is_spell: bool = kind == "spell" or is_trap
	var ftype: String = d.get("frame", "normal")
	# (0.82.2, Raul) The WHOLE card is the color of its kind, not only a line round a dark card: in a
	# hand of several, which is a Spell, a Trap, a Synchro has to be seen at a glance.
	# (0.82.3, Raul: "they look kinda plain") The color is a worked surface now (see FRAME_GLSL):
	# a woven pattern, light running across it, a deeper edge; with gold corner pieces, a cut name
	# plate, a jewel for the Attribute, a ribbon for the stars and a plate for ATK and DEF.
	var tone: Color = {"spell": Color("149a6c"), "trap": Color("b52a7c"), "effect": Color("cf7a30"), "fusion": Color("8249bd"),
			"synchro": Color("e3e7ee"), "xyz": Color("2a2c42"), "ritual": Color("3873d6")}.get(ftype, Color("c79a55"))
	var pale := tone.get_luminance() > 0.6          # (the Synchro's white: dark lettering on the card itself)
	var gold := Color("ffd766")
	var gold_deep := Color("9a6a12")
	var ink := Color("0b1322")
	var deep := tone.darkened(0.64) if not pale else Color("39404e")
	if ftype == "xyz":
		deep = Color("11121f")
	_rect(root, Vector2.ZERO, Vector2(CARD_SIZE), Color("05080f"))
	# The card itself.
	var body_rect := ColorRect.new()
	body_rect.position = Vector2(7, 7)
	body_rect.size = Vector2(406, 598)
	var bm := ShaderMaterial.new()
	bm.shader = _frame_shader()
	bm.set_shader_parameter("tone", tone)
	bm.set_shader_parameter("pale", 1.0 if pale else 0.0)
	bm.set_shader_parameter("weave", float(["effect", "spell", "trap", "fusion", "synchro", "xyz", "ritual"].find(ftype)))
	body_rect.material = bm
	root.add_child(body_rect)
	# Gold round it: a bright line with a deep one inside (a worked edge, not a flat stroke).
	_edge(root, Vector2(4, 4), Vector2(412, 604), gold_deep, 2, 13)
	_edge(root, Vector2(6, 6), Vector2(408, 600), gold, 3, 11)
	_edge(root, Vector2(9, 9), Vector2(402, 594), Color(gold_deep, 0.9), 1, 9)
	_edge(root, Vector2(15, 15), Vector2(390, 582), Color(1, 1, 1, 0.3) if not pale else Color(0.2, 0.25, 0.4, 0.35), 1, 6)
	# Name: a plate with cut corners, a few shades deeper than the card.
	var plate_n := Control.new()
	plate_n.position = Vector2(22, 22)
	plate_n.size = Vector2(376, 54)
	plate_n.draw.connect(_draw_name_plate.bind(plate_n, deep, gold, gold_deep))
	root.add_child(plate_n)
	var nm := str(d.get("name", ""))
	var name_l := _label(root, nm, Vector2(38, 24), Vector2(300, 50), _font_title, 30 if nm.length() <= 20 else (24 if nm.length() <= 25 else 20), Color.WHITE)
	name_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	name_l.add_theme_constant_override("shadow_offset_y", 2)
	# The Attribute, as a jewel in a gold ring.
	var attr: String = ("TRAP" if is_trap else "SPELL") if is_spell else str(d.get("attribute", "LIGHT"))
	var colors: Array = ATTRIBUTE_COLORS.get(attr, [Color("3d0f2c"), Color("e24da0")] if is_trap else [Color("0f3d3a"), Color("2de2c6")])
	var gem := Control.new()
	gem.position = Vector2(344, 25)
	gem.size = Vector2(48, 48)
	gem.draw.connect(_draw_gem.bind(gem, colors[1], gold, gold_deep))
	root.add_child(gem)
	var gl := _label(root, attr.substr(0, 1), Vector2(344, 25), Vector2(48, 48), _font_title, 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	gl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	gl.add_theme_constant_override("shadow_offset_y", 2)
	# Level (Rank, for an Xyz Monster: on the left) or the kind of Spell, on a dark ribbon.
	var ribbon := Control.new()
	ribbon.position = Vector2(22, 81)
	ribbon.size = Vector2(376, 28)
	root.add_child(ribbon)
	if is_spell:
		# (The kind of Spell or Trap, when it has one: Field, Continuous, Quick-Play, Ritual, Counter.)
		var st_kind := str(d.get("st", "")).to_upper()
		var kind_line := "TRAP CARD" if is_trap else ("SPEED SPELL" if d.get("speed_spell", false) else "SPELL CARD")
		if st_kind != "":
			kind_line = "%s %s" % [st_kind, "TRAP" if is_trap else "SPELL"]
		var shown_kind := tr(kind_line)
		ribbon.draw.connect(_draw_ribbon.bind(ribbon, _font_title.get_string_size(shown_kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 34.0, false, deep, gold))
		_label(root, kind_line, Vector2(30, 80), Vector2(356, 30), _font_title, 20, Color("fff3c4"), HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		var n := int(d.get("level", 1))
		var left := ftype == "xyz"
		ribbon.draw.connect(_draw_ribbon.bind(ribbon, n * 21.5 + 30.0, left, deep, gold))
		_label(root, "★".repeat(n), Vector2(34, 80), Vector2(352, 30), _font_title, 23, Color("ffe27a") if not left else Color("cdbdff"),
				HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT)
	# The picture: sunk into the card, in a gold frame with a bright inner line and corner pieces.
	_rect(root, Vector2(36, 108), Vector2(348, 320), Color(0, 0, 0, 0.34), 7)
	_edge(root, Vector2(39, 111), Vector2(342, 314), gold_deep, 2, 5)
	_edge(root, Vector2(41, 113), Vector2(338, 310), gold, 3, 4, Color.BLACK)
	var art_box := Control.new()
	art_box.position = Vector2(46, 118)
	art_box.size = Vector2(328, 300)
	art_box.clip_contents = true
	root.add_child(art_box)
	_fill(art_box, Vector2.ZERO, Vector2(328, 300), (colors[1] as Color).lerp(Color.WHITE, 0.25), (colors[0] as Color).darkened(0.2))
	var form: int = LUMEN_FORMS.get(id, -1)
	if form >= 0:
		_lumen_art(art_box, form, id)
		# Draw for a moment (her picture needs a few frames to exist), then hold still.
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		LumenSpirit.wake(2.5)
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(vp):
				vp.render_target_update_mode = SubViewport.UPDATE_DISABLED)
	elif EchoArt.has(id):
		# (0.81.0) The Echo cards: drawn in EchoArt. Lumen is on some of them, and needs a moment.
		if EchoArt.build(art_box, id, self):
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			LumenSpirit.wake(2.5)
			get_tree().create_timer(2.0).timeout.connect(func():
				if is_instance_valid(vp):
					vp.render_target_update_mode = SubViewport.UPDATE_DISABLED)
	else:
		_speed_art(art_box, id)
	_edge(root, Vector2(45, 117), Vector2(330, 302), Color(1, 1, 1, 0.22), 1, 2)
	_crossroads_mark(root, id)
	var caps := Control.new()
	caps.position = Vector2(36, 108)
	caps.size = Vector2(348, 320)
	caps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caps.draw.connect(_draw_corner_caps.bind(caps, gold, gold_deep))
	root.add_child(caps)
	# What it does: on a light plate tinted with the card's color, in dark lettering.
	var plate := tone.lerp(Color("f8f2e2"), 0.86) if not pale else Color("f1f3f8")
	if ftype == "xyz":
		plate = Color("dcdcea")
	var dark := deep.darkened(0.2)
	_rect(root, Vector2(22, 428), Vector2(376, 166), Color(0, 0, 0, 0.36), 9)
	_edge(root, Vector2(24, 430), Vector2(372, 162), gold_deep, 2, 8)
	_edge(root, Vector2(26, 432), Vector2(368, 158), gold, 2, 6, plate)
	_fill(root, Vector2(29, 435), Vector2(362, 70), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0))
	_fill(root, Vector2(29, 530), Vector2(362, 57), Color(tone.darkened(0.3), 0.0), Color(tone.darkened(0.3), 0.16))
	_edge(root, Vector2(30, 436), Vector2(360, 150), Color(dark, 0.3), 1, 4)
	# (In Spanish the card says what it does in Spanish: the same text the card list shows.)
	var body: String = CardText.shown(str(d.get("name", "")), str(d.get("text", "")))
	if is_spell:
		var bl := body.length()
		var desc := _label(root, body, Vector2(40, 442), Vector2(340, 138), _font_body, 19 if bl <= 110 else (16 if bl <= 180 else (14 if bl <= 250 else 12)), ink)
		desc.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		desc.clip_text = false
	else:
		var kinds := [tr(str(d.get("race", "")))]
		if ftype in ["fusion", "synchro", "xyz", "ritual"]:
			kinds.append(tr(ftype.capitalize()))
		if d.get("tuner", false):
			kinds.append(tr("Tuner"))
		kinds.append(tr("Effect"))
		var kl := _label(root, "[ %s ]" % " / ".join(kinds), Vector2(40, 437), Vector2(340, 28), _font_title, 20, dark)
		kl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		var rule := Control.new()
		rule.position = Vector2(40, 464)
		rule.size = Vector2(340, 6)
		rule.draw.connect(_draw_rule.bind(rule, Color(dark, 0.55)))
		root.add_child(rule)
		var bl2 := body.length()
		var fx_text := _label(root, body, Vector2(40, 470), Vector2(340, 78), _font_body, 12 if bl2 <= 170 else (10 if bl2 <= 260 else 9), ink)
		fx_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		fx_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fx_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		fx_text.clip_text = false
		# ATK and DEF on their own plate, in gold.
		var stat := Control.new()
		stat.position = Vector2(126, 551)
		stat.size = Vector2(260, 34)
		stat.draw.connect(_draw_stat_plate.bind(stat, deep, gold, gold_deep))
		root.add_child(stat)
		var sl := _label(root, "ATK/%d   DEF/%d" % [d.get("atk", 0), d.get("def", 0)], Vector2(140, 550), Vector2(246, 36),
				_font_title, 25, Color("ffe9a8"), HORIZONTAL_ALIGNMENT_CENTER)
		sl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return vp.get_texture()


## The color of one of this game's cards, as a surface: a gradient lit from the top left, a fine
## pattern woven into it (each kind has its own), two bands of light on a slant, a grain like
## brushed metal, and edges that sink into shadow.
const FRAME_GLSL := """
shader_type canvas_item;
uniform vec4 tone : source_color = vec4(0.8, 0.5, 0.2, 1.0);
uniform float pale = 0.0;
uniform float weave = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float pattern(vec2 px) {
	if (weave < 0.5) {            // Effect: diamonds
		vec2 g = px / 17.0; vec2 d = abs(fract(vec2(g.x + g.y, g.x - g.y)) - 0.5);
		return smoothstep(0.455, 0.5, max(d.x, d.y));
	} else if (weave < 1.5) {     // Spell: rings
		vec2 c = fract(px / 30.0) - 0.5; float r = length(c);
		return (1.0 - smoothstep(0.0, 0.035, abs(r - 0.36))) + 0.7 * (1.0 - smoothstep(0.0, 0.03, abs(r - 0.18)));
	} else if (weave < 2.5) {     // Trap: a net
		vec2 g = px / 13.0; vec2 d = abs(fract(vec2(g.x + g.y, g.x - g.y)) - 0.5);
		return smoothstep(0.44, 0.5, d.x) + smoothstep(0.44, 0.5, d.y);
	} else if (weave < 3.5) {     // Fusion: two waves crossing
		float a = sin(px.x / 9.0 + sin(px.y / 23.0) * 2.6); float b = sin(px.x / 9.0 - sin(px.y / 23.0) * 2.6 + 1.7);
		return (1.0 - smoothstep(0.0, 0.16, abs(a))) + (1.0 - smoothstep(0.0, 0.16, abs(b)));
	} else if (weave < 4.5) {     // Synchro: fine straight beams
		return (1.0 - smoothstep(0.0, 0.12, abs(fract(px.y / 9.0) - 0.5))) * 0.8 + (1.0 - smoothstep(0.0, 0.03, abs(fract(px.x / 58.0) - 0.5))) * 0.6;
	} else if (weave < 5.5) {     // Xyz: stars
		vec2 cell = floor(px / 15.0); float h = hash(cell);
		vec2 c = fract(px / 15.0) - vec2(0.2 + 0.6 * hash(cell + 3.1), 0.2 + 0.6 * hash(cell + 7.7));
		return step(0.78, h) * (1.0 - smoothstep(0.0, 0.16, length(c))) * 3.0;
	}
	// Ritual: scales
	vec2 g = px / vec2(22.0, 15.0); g.x += 0.5 * mod(floor(g.y), 2.0);
	vec2 c = fract(g) - vec2(0.5, 0.0);
	return 1.0 - smoothstep(0.0, 0.05, abs(length(c * vec2(1.0, 0.9)) - 0.5));
}
void fragment() {
	vec2 px = UV * vec2(406.0, 598.0);
	vec3 hi = mix(tone.rgb, vec3(1.0), mix(0.30, 0.75, pale));
	vec3 lo = tone.rgb * mix(0.50, 0.70, pale);
	float t = clamp(UV.y * 0.86 + UV.x * 0.14, 0.0, 1.0);
	vec3 col = mix(hi, lo, smoothstep(0.0, 1.0, t));
	col += mix(0.14, 0.06, pale) * (1.0 - smoothstep(0.0, 0.85, distance(UV, vec2(0.18, 0.04))));
	float w = clamp(pattern(px), 0.0, 1.5);
	col += w * mix(vec3(0.085), vec3(-0.09, -0.08, -0.05), pale);
	float s = UV.x * 0.9 + UV.y * 0.55;
	float band = exp(-pow((s - 0.40) / 0.075, 2.0)) + 0.55 * exp(-pow((s - 0.98) / 0.05, 2.0));
	col += band * mix(vec3(0.17), vec3(0.10, 0.12, 0.2) * -0.55, pale);
	col += (noise(vec2(px.x * 0.06, px.y * 1.7)) - 0.5) * 0.04;
	col += (noise(px * 1.1) - 0.5) * 0.03;
	vec2 q = (UV - 0.5) * vec2(1.0, 1.12);
	col *= 1.0 - mix(0.42, 0.2, pale) * smoothstep(0.34, 0.80, length(q));
	COLOR = vec4(col, 1.0);
}
"""
var _frame_sh: Shader


func _frame_shader() -> Shader:
	if _frame_sh == null:
		_frame_sh = Shader.new()
		_frame_sh.code = FRAME_GLSL
	return _frame_sh


## The name's plate: cut corners, darker toward the foot, a gloss across its top half, gold round it.
func _draw_name_plate(c: Control, deep: Color, gold: Color, gold_deep: Color) -> void:
	var w := c.size.x
	var h := c.size.y
	var k := 9.0
	var pts := PackedVector2Array([Vector2(k, 0), Vector2(w - k, 0), Vector2(w, k), Vector2(w, h - k), Vector2(w - k, h), Vector2(k, h), Vector2(0, h - k), Vector2(0, k)])
	var top := deep.lightened(0.2)
	var foot := deep.darkened(0.35)
	c.draw_polygon(pts, PackedColorArray([top, top, top, foot, foot, foot, foot, top]))
	c.draw_colored_polygon(PackedVector2Array([Vector2(k, 2), Vector2(w - k, 2), Vector2(w - 2, k), Vector2(w - 2, h * 0.46), Vector2(2, h * 0.46), Vector2(2, k)]), Color(1, 1, 1, 0.09))
	var ring := pts.duplicate()
	ring.append(pts[0])
	c.draw_polyline(ring, gold_deep, 4.0, true)
	c.draw_polyline(ring, gold, 2.0, true)


## The Attribute's jewel: a gold ring, the color lit from above, a gloss on its upper left.
func _draw_gem(c: Control, col: Color, gold: Color, gold_deep: Color) -> void:
	var m := c.size / 2.0
	c.draw_circle(m + Vector2(0, 2), 23.0, Color(0, 0, 0, 0.45))
	c.draw_circle(m, 23.0, gold_deep)
	c.draw_circle(m, 21.5, gold)
	c.draw_circle(m, 18.5, col.darkened(0.45))
	for i in 7:
		var t := float(i) / 6.0
		c.draw_circle(m + Vector2(-2.0, -3.0) * t, 18.5 - 6.5 * t, col.darkened(0.45).lerp(col.lightened(0.18), t))
	c.draw_circle(m + Vector2(-6, -8), 5.0, Color(1, 1, 1, 0.38))
	c.draw_circle(m + Vector2(-7.5, -9.5), 2.2, Color(1, 1, 1, 0.7))
	c.draw_arc(m, 18.5, 0, TAU, 40, Color(0, 0, 0, 0.35), 1.2, true)


## The ribbon the stars (or the kind of Spell) sit on: against the right edge, cut on a slant at
## its other end (an Xyz's: against the left).
func _draw_ribbon(c: Control, width: float, left: bool, deep: Color, gold: Color) -> void:
	var w := c.size.x
	var h := c.size.y
	var x0 := 0.0 if left else w - width
	var x1 := width if left else w
	var pts: PackedVector2Array
	if left:
		pts = PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1 - 14, h), Vector2(x0, h)])
	else:
		pts = PackedVector2Array([Vector2(x0 + 14, 0), Vector2(x1, 0), Vector2(x1, h), Vector2(x0, h)])
	c.draw_colored_polygon(pts, Color(deep.darkened(0.3), 0.82))
	c.draw_line(Vector2(x0 + (0 if left else 14), 0), Vector2(x1, 0), Color(gold, 0.55), 1.0, true)
	c.draw_line(Vector2(x0, h), Vector2(x1 - (14 if left else 0), h), Color(gold, 0.55), 1.0, true)


## Gold pieces on the four corners of the picture's frame.
func _draw_corner_caps(c: Control, gold: Color, gold_deep: Color) -> void:
	var w := c.size.x
	var h := c.size.y
	for corner in [[Vector2(0, 0), Vector2(1, 1)], [Vector2(w, 0), Vector2(-1, 1)], [Vector2(0, h), Vector2(1, -1)], [Vector2(w, h), Vector2(-1, -1)]]:
		var o: Vector2 = corner[0]
		var s: Vector2 = corner[1]
		var tri := PackedVector2Array([o, o + Vector2(26, 0) * s, o + Vector2(15, 5) * s, o + Vector2(5, 5) * s, o + Vector2(5, 15) * s, o + Vector2(0, 26) * s])
		c.draw_colored_polygon(tri, gold)
		var line := tri.duplicate()
		line.append(tri[0])
		c.draw_polyline(line, gold_deep, 1.2, true)
		c.draw_circle(o + Vector2(8.5, 8.5) * s, 2.6, gold_deep)
		c.draw_circle(o + Vector2(8.5, 8.5) * s, 1.4, Color("fff6d0"))


## A fine line with a diamond in its middle (under a monster's kinds).
func _draw_rule(c: Control, col: Color) -> void:
	var w := c.size.x
	var y := c.size.y / 2.0
	c.draw_line(Vector2(0, y), Vector2(w / 2.0 - 9, y), col, 1.2, true)
	c.draw_line(Vector2(w / 2.0 + 9, y), Vector2(w, y), col, 1.2, true)
	c.draw_colored_polygon(PackedVector2Array([Vector2(w / 2.0, y - 4), Vector2(w / 2.0 + 5, y), Vector2(w / 2.0, y + 4), Vector2(w / 2.0 - 5, y)]), col)


## ATK and DEF sit on a plate of their own, cut on a slant at its left end.
func _draw_stat_plate(c: Control, deep: Color, gold: Color, gold_deep: Color) -> void:
	var w := c.size.x
	var h := c.size.y
	var pts := PackedVector2Array([Vector2(16, 0), Vector2(w - 5, 0), Vector2(w, 5), Vector2(w, h - 5), Vector2(w - 5, h), Vector2(0, h)])
	var top := deep.lightened(0.14)
	var foot := deep.darkened(0.35)
	c.draw_polygon(pts, PackedColorArray([top, top, top, foot, foot, foot]))
	var ring := pts.duplicate()
	ring.append(pts[0])
	c.draw_polyline(ring, gold_deep, 3.0, true)
	c.draw_polyline(ring, gold, 1.3, true)


## The picture on a Speed Spell: the road rushing at you, and how many Speed Counters it asks for.
func _speed_art(art_box: Control, id: int) -> void:
	var need := 0
	var sp: Dictionary = SpellRules.FX.get(str(CardData.get_card(id).get("name", "")), {})
	need = int(sp.get("speed", 0))
	var c := Control.new()
	c.size = Vector2(328, 300)
	art_box.add_child(c)
	c.draw.connect(func():
		var vanish := Vector2(164, 96)
		c.draw_rect(Rect2(0, 0, 328, 300), Color(0.03, 0.05, 0.1, 0.55))
		# The road, and the lines of speed running out from where it ends.
		c.draw_colored_polygon(PackedVector2Array([vanish + Vector2(-10, 0), vanish + Vector2(10, 0), Vector2(300, 300), Vector2(28, 300)]), Color(0.1, 0.12, 0.18))
		for k in 6:
			var t0 := 0.12 + k * 0.15
			var t1 := t0 + 0.07
			var a := vanish.lerp(Vector2(164, 300), t0 * t0 * 1.2)
			var b := vanish.lerp(Vector2(164, 300), minf(1.0, t1 * t1 * 1.2))
			c.draw_line(a, b, Color("ffd766"), 2.0 + k * 1.6, true)
		for k in 18:
			var ang := -PI + k * (TAU / 18.0) + 0.17
			var dir := Vector2(cos(ang), sin(ang) * 0.8)
			c.draw_line(vanish + dir * 46.0, vanish + dir * 260.0, Color(0.5, 0.92, 1.0, 0.22), 3.0, true)
		c.draw_circle(vanish, 16.0, Color(1, 1, 1, 0.9))
		c.draw_circle(vanish, 30.0, Color(0.5, 0.92, 1.0, 0.3))
		pass)
	var n := _label(art_box, str(need) if need > 0 else "", Vector2(214, 150), Vector2(100, 110), _font_title, 96, Color(1, 1, 1, 0.92), HORIZONTAL_ALIGNMENT_RIGHT)
	n.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	n.add_theme_constant_override("shadow_offset_y", 4)


const EchoArt := preload("res://scripts/core/echo_art.gd")


## Which of Lumen's cards shows which form of her: 0 the spirit, 1 Chorus, 2 Comet, 3 Zenith, 4 Radiant.
## 5 Echo Resonance, 6 Echo Call, 7 Echo Veil: she is on those too.
const LUMEN_FORMS := {99200001: 0, 99200002: 1, 99200003: 2, 99200004: 3, 99200005: 4, 99200011: 5, 99200012: 6, 99200013: 7}


## The mark of a card made for this game: a band across the foot of its picture with the
## crossroads sign, the words, and its number in the set.
func _crossroads_mark(root: Control, id: int) -> void:
	var band := _rect(root, Vector2(46, 392), Vector2(328, 26), Color(0.04, 0.07, 0.13, 0.88))
	var sign := Control.new()
	sign.position = Vector2(6, 3)
	sign.size = Vector2(20, 20)
	sign.draw.connect(func():
		# Two roads crossing, in a ring.
		var c := Vector2(10, 10)
		sign.draw_arc(c, 9.0, 0, TAU, 28, Color("ffd766"), 2.0, true)
		sign.draw_line(c + Vector2(-5.5, -5.5), c + Vector2(5.5, 5.5), Color("7fe8ff"), 2.6, true)
		sign.draw_line(c + Vector2(5.5, -5.5), c + Vector2(-5.5, 5.5), Color("7fe8ff"), 2.6, true)
		sign.draw_circle(c, 2.2, Color("ffd766")))
	band.add_child(sign)
	_label(band, "CROSSROADS ORIGINAL", Vector2(32, 0), Vector2(200, 26), _font_title, 17, Color("ffd766"))
	_label(band, CardData.set_code(id), Vector2(228, 0), Vector2(92, 26), _font_title, 17, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_RIGHT)


## Lumen on her card. The same living picture of her every time; what changes with the form
## is the sky behind her and the signs of what she has become:
## 1 Chorus: two echoes of her, one at each shoulder.   2 Comet: a tail of light and stars.
## 3 Zenith: a ring with two lights going round it.      4 Radiant: rays, and she fills the card.
func _lumen_art(art_box: Control, form: int, id := 0) -> void:
	# Her four great forms have painted pictures of their own (assets/originals/<card id>.png,
	# cut out, on a clear background). The sky and its signs are drawn here behind them.
	var painted: Texture2D = null
	var art_path := "res://assets/originals/%d.png" % id
	if form >= 1 and form <= 4 and ResourceLoader.exists(art_path):
		painted = load(art_path)
	var skies := [[Color("12305a"), Color("7fe8ff")], [Color("3a1f6e"), Color("ff9ad5")], [Color("06223f"), Color("5fe0ff")], [Color("0b0b22"), Color("8a6bff")], [Color("c9601a"), Color("ffe9a8")],
			[Color("3a2a05"), Color("ffe08a")], [Color("0d3b3a"), Color("8dffe0")], [Color("2a0f33"), Color("ff8ad0")]]
	if painted != null:
		# Figures made of light want a dark sky behind them.
		skies[1] = [Color("12041c"), Color("6a2478")]
		skies[2] = [Color("02101c"), Color("0f6a96")]
		skies[3] = [Color("05041a"), Color("3d2c94")]
		skies[4] = [Color("160802"), Color("8a4410")]
	if true:
		var grad := Gradient.new()
		grad.set_color(0, skies[form][1])
		grad.set_color(1, skies[form][0])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.55)
		gt.fill_to = Vector2(1.15, 1.15)
		gt.width = 128
		gt.height = 128
		var sky := TextureRect.new()
		sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sky.texture = gt
		sky.position = Vector2(0, 0)
		sky.size = Vector2(328, 300)
		art_box.add_child(sky)
	var back := Control.new()
	back.position = Vector2(4, 4)
	back.size = Vector2(320, 292)
	art_box.add_child(back)
	var mid := Vector2(160, 150)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + form
	var stars: Array = []
	for i in 46:
		stars.append([Vector2(rng.randf_range(0, 320), rng.randf_range(0, 292)), rng.randf_range(0.8, 2.4)])
	back.draw.connect(func():
		match form:
			0:
				# The spirit: a soft light behind her and a few motes.
				back.draw_circle(mid + Vector2(0, 10), 104.0, Color(1, 1, 1, 0.22))
				back.draw_circle(mid + Vector2(0, 10), 72.0, Color(1, 1, 1, 0.22))
				for st in stars.slice(0, 16):
					back.draw_circle(st[0], st[1] * 1.3, Color(1, 1, 1, 0.75))
			5:
				# Resonance: rings going out from her, and rays.
				for k in 16:
					var a5 := TAU * k / 16.0
					back.draw_line(mid + Vector2(cos(a5), sin(a5)) * 70.0, mid + Vector2(cos(a5), sin(a5)) * 240.0, Color(1, 0.95, 0.7, 0.3), 6.0, true)
				for k in 4:
					back.draw_arc(mid, 56.0 + k * 30.0, 0, TAU, 64, Color(1, 1, 1, 0.5 - k * 0.1), 4.0, true)
			6:
				# The call: waves of sound from her, off to the left.
				for k in 6:
					back.draw_arc(Vector2(214, 150), 50.0 + k * 34.0, PI * 0.72, PI * 1.28, 32, Color(1, 1, 1, 0.6 - k * 0.08), 5.0, true)
			7:
				for st in stars.slice(0, 20):
					back.draw_circle(st[0], st[1], Color(1, 0.85, 0.95, 0.6))
			1:
				for k in 5:
					back.draw_arc(mid, 60.0 + k * 26.0, 0, TAU, 64, Color(1, 1, 1, 0.26 - k * 0.04), 3.0, true)
			2:
				for st in stars:
					back.draw_circle(st[0], st[1], Color(1, 1, 1, 0.7))
				# Lines of speed across the sky.
				for k in 7:
					back.draw_line(Vector2(340, 20 + k * 38.0), Vector2(40 + k * 22.0, 60 + k * 38.0), Color(0.8, 0.97, 1.0, 0.16), 3.0, true)
			3:
				for st in stars:
					back.draw_circle(st[0], st[1] * 0.8, Color(0.85, 0.8, 1.0, 0.75))
			4:
				for k in 24:
					var a := TAU * k / 24.0
					var long := 230.0 if k % 2 == 0 else 170.0
					var d1 := Vector2(cos(a - 0.05), sin(a - 0.05))
					var d2 := Vector2(cos(a + 0.05), sin(a + 0.05))
					back.draw_colored_polygon(PackedVector2Array([mid, mid + d1 * long, mid + d2 * long]), Color(1, 0.95, 0.75, 0.32))
				back.draw_circle(mid, 100.0, Color(1, 0.96, 0.8, 0.3))
		pass)
	# Her: the body of the form she is in (the three cards around her show the spirit).
	var shots := [[Vector2(4, 4), Vector2(320, 292), Color.WHITE]]
	match form:
		1, 2, 3:
			shots = [[Vector2(-2, -6), Vector2(332, 312), Color.WHITE]]
		4:
			shots = [[Vector2(-6, -10), Vector2(340, 320), Color.WHITE]]
		5:
			shots = [[Vector2(44, 30), Vector2(240, 220), Color(1.0, 0.97, 0.85)]]
		6:
			shots = [[Vector2(110, 40), Vector2(230, 212), Color.WHITE]]
		7:
			shots = [[Vector2(54, 62), Vector2(220, 202), Color.WHITE]]
	if painted != null:
		# The top two thirds of the painting fill the picture: the head, the wings, what she holds.
		var crop: Array = [[], [Vector2(-6, -6), 340.0], [Vector2(-20, -4), 372.0], [Vector2(-4, -2), 336.0], [Vector2(-14, -2), 356.0]][form]
		var pic := TextureRect.new()
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.texture = painted
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		pic.position = crop[0]
		pic.size = Vector2(float(crop[1]), float(crop[1]) * painted.get_height() / painted.get_width())
		art_box.add_child(pic)
		return
	for sh in shots:
		# (Its size is set after the "any size" switch: before it, a picture cannot be made
		# smaller than its texture, and she came out twice the size and off the card.)
		var live := TextureRect.new()
		live.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		live.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		live.texture = LumenSpirit.portrait_form(self, form if form <= 4 else 0)
		live.position = sh[0]
		live.size = sh[1]
		live.modulate = sh[2]
		art_box.add_child(live)
	var front := Control.new()
	front.position = Vector2(4, 4)
	front.size = Vector2(320, 292)
	art_box.add_child(front)
	front.draw.connect(func():
		match form:
			7:
				# The veil: a dome of light over her.
				front.draw_arc(Vector2(164, 236), 150.0, PI, TAU, 64, Color(1, 0.75, 0.92, 0.95), 5.0, true)
				front.draw_arc(Vector2(164, 236), 140.0, PI, TAU, 64, Color(1, 1, 1, 0.35), 14.0, true)
				for k in 5:
					var a7 := PI + (k + 0.5) * PI / 5.0
					front.draw_line(Vector2(164, 236) + Vector2(cos(a7), sin(a7)) * 150.0, Vector2(164, 236) + Vector2(cos(a7), sin(a7)) * 96.0, Color(1, 1, 1, 0.3), 2.0, true)
		pass)


func _make_back(accent := Color("1fd1c1"), ring_col := Color(0.55, 0.95, 1.0, 0.55), text := "CROSSROADS", edge := Color("0a0f1a")) -> Texture2D:
	var vp := _new_viewport()
	var root := Control.new()
	root.size = Vector2(CARD_SIZE)
	vp.add_child(root)
	_rect(root, Vector2.ZERO, Vector2(CARD_SIZE), edge)
	_rect(root, Vector2(10, 10), Vector2(400, 592), Color("101a2e"), 12)
	var grad := Gradient.new()
	grad.set_color(0, accent)
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
		sb.border_color = ring_col
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(r)
		ring.add_theme_stylebox_override("panel", sb)
		ring.position = Vector2(210 - r, 306 - r)
		ring.size = Vector2(r * 2, r * 2)
		root.add_child(ring)
	_label(root, text, Vector2(10, 520), Vector2(400, 50), _font_title, 40 if text.length() <= 12 else 32,
			ring_col.lightened(0.4) if text != "CROSSROADS" else Color(0.75, 0.97, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	return vp.get_texture()
