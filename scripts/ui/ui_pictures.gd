class_name UiPictures
## The big menu pictures (assets/ui/*.jpg, 3840x2160) cost about 0.1 s each to read, which is a
## visible stall when a screen opens with several. Every screen asks here instead:
##   thumb(path)  a 960x540 copy (assets/ui/thumbs/), read at once: for tiles, and for the first
##                frame of a backdrop;
##   full(path)   the sharp picture if it is already read, else null (and it starts reading it on a
##                worker thread); poll() hands back what has arrived.
## Read pictures stay here for the whole run (a handful of textures), so reopening a screen is free.

static var _full := {}           # path -> Texture2D
static var _thumbs := {}         # path -> Texture2D
static var _asked := {}          # path -> true while a worker reads it


static func thumb_path(path: String) -> String:
	var t := "res://assets/ui/thumbs/" + path.get_file()
	return t if ResourceLoader.exists(t) else path


## The small copy, at once (or the picture itself when it has no small copy).
static func thumb(path: String) -> Texture2D:
	if path == "":
		return null
	if _full.has(path) and thumb_path(path) == path:
		return _full[path]
	if not _thumbs.has(path):
		var t := thumb_path(path)
		if t == path:
			_thumbs[path] = full_now(path)
		elif ResourceLoader.exists(t):
			_thumbs[path] = load(t)
		else:
			return null
	return _thumbs[path]


## The sharp picture if it is on hand; otherwise null, and it is being read on a worker thread.
static func full(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if _full.has(path):
		return _full[path]
	if not _asked.has(path):
		_asked[path] = true
		if ResourceLoader.load_threaded_request(path) != OK:
			_asked.erase(path)
			_full[path] = load(path)
			return _full[path]
	return _poll_one(path)


## The sharp picture now, reading it here if need be (for the rare place that cannot wait).
static func full_now(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if _full.has(path):
		return _full[path]
	if _asked.has(path):
		_full[path] = ResourceLoader.load_threaded_get(path)
		_asked.erase(path)
	else:
		_full[path] = load(path)
	return _full[path]


static func _poll_one(path: String) -> Texture2D:
	if not _asked.has(path):
		return _full.get(path)
	var st := ResourceLoader.load_threaded_get_status(path)
	if st == ResourceLoader.THREAD_LOAD_LOADED:
		_full[path] = ResourceLoader.load_threaded_get(path)
		_asked.erase(path)
		return _full[path]
	if st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_asked.erase(path)
		_full[path] = load(path)
		return _full[path]
	return null


## Start reading these in the background (the main menu warms the pictures its tiles open on).
static func warm(paths: Array) -> void:
	for p in paths:
		full(str(p))


## A picture with rounded corners: `rect` goes inside a panel of that shape that only lets it show
## inside the curve (a square picture in a rounded card used to poke its corners out of it).
## The panel takes the picture's place: give it the position and size the picture had.
static func rounded(rect: Control, radius: float) -> Panel:
	var clip := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	clip.add_theme_stylebox_override("panel", sb)
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = rect.position
	clip.size = rect.size
	clip.custom_minimum_size = rect.custom_minimum_size
	clip.size_flags_horizontal = rect.size_flags_horizontal
	clip.size_flags_vertical = rect.size_flags_vertical
	rect.position = Vector2.ZERO
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_child(rect)
	return clip
