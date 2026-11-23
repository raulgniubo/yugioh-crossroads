class_name AcademyBackdrop
extends Control
## The picture behind the Academy's own screens: the island at sunset (a picture taken in the
## game itself), still (nothing moves on its own: on a big screen any drift reads as stutter),
## darker on the side the words are on. `shade`: how dark the whole of it is (0 for the title,
## more behind a list). It only changes when the player changes what it shows (fade_to).

const PICTURE := "res://assets/ui/academy_title.jpg"

var shade := 0.0: set = set_shade

var _pic: TextureRect
var _pic2: TextureRect           # the next picture, fading in over the first when there are several
var _fading := false
var _side: TextureRect
var _all: ColorRect
var _want := ""                  # the picture meant to be on: its small copy shows until the sharp one is read


## `pic`: another picture taken in the game (the main story uses Domino City at night).
## (`mote` is kept so older callers still work: the motes of light are gone.)
func _init(dark := 0.0, pic := PICTURE, mote := Color(1.0, 0.9, 0.62)) -> void:
	shade = dark
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var under := ColorRect.new()
	under.color = Color(0.03, 0.04, 0.1)
	under.set_anchors_preset(Control.PRESET_FULL_RECT)
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(under)
	_pic = TextureRect.new()
	_set_main(pic)
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pic)
	_pic2 = TextureRect.new()
	_pic2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic2.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pic2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_pic2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pic2.modulate.a = 0.0
	add_child(_pic2)
	# Dark where the words go (the left), clear over the school and the lighthouse.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.34, 0.62, 1.0])
	g.colors = PackedColorArray([Color(0.02, 0.03, 0.09, 0.93), Color(0.02, 0.03, 0.09, 0.78), Color(0.02, 0.03, 0.09, 0.18), Color(0.02, 0.03, 0.09, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 4
	_side = TextureRect.new()
	_side.texture = gt
	_side.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_side.stretch_mode = TextureRect.STRETCH_SCALE
	_side.set_anchors_preset(Control.PRESET_FULL_RECT)
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_side)
	# A soft dark foot, so the line at the bottom reads over the sand.
	var fg := Gradient.new()
	fg.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	fg.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0.01, 0.02, 0.06, 0.6)])
	var ft := GradientTexture2D.new()
	ft.gradient = fg
	ft.fill_from = Vector2(0, 0)
	ft.fill_to = Vector2(0, 1)
	ft.width = 4
	ft.height = 256
	var foot := TextureRect.new()
	foot.texture = ft
	foot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foot.stretch_mode = TextureRect.STRETCH_SCALE
	foot.set_anchors_preset(Control.PRESET_FULL_RECT)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(foot)
	_all = ColorRect.new()
	_all.color = Color(0.02, 0.03, 0.09, shade)
	_all.set_anchors_preset(Control.PRESET_FULL_RECT)
	_all.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_all)


func set_shade(v: float) -> void:
	shade = v
	if _all:
		_all.color.a = v


## One picture from a set, held still (the main story's door with no game yet, and its Load
## screen). The pictures no longer rotate on their own: the first one that exists is shown.
func cycle(paths: Array) -> void:
	for p in paths:
		if ResourceLoader.exists(str(p)):
			_set_main(str(p))
			_pic2.modulate.a = 0.0
			return


## Show one picture now (no fading).
func show_picture(path: String) -> void:
	if ResourceLoader.exists(path):
		_set_main(path)
	_pic2.modulate.a = 0.0


## Crossfade from the picture on now to this one (the Free Roam door, as you move between worlds).
func fade_to(path: String, secs := 0.45) -> void:
	if not ResourceLoader.exists(path) or path == _want:
		return
	_want = path
	var tex: Texture2D = UiPictures.full(path)
	if tex == null:
		tex = UiPictures.thumb(path)
		set_process(true)          # (the sharp one replaces it when it has been read)
	_pic2.texture = tex
	_pic2.modulate.a = 0.0
	_fading = true
	var tw := create_tween()
	tw.tween_property(_pic2, "modulate:a", 1.0, secs)
	tw.tween_callback(func():
		_pic.texture = _pic2.texture
		_pic2.modulate.a = 0.0
		_fading = false)


## The picture at once: the sharp one if it has been read, else its small copy while it is read.
func _set_main(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	_want = path
	var tex: Texture2D = UiPictures.full(path)
	if tex == null:
		tex = UiPictures.thumb(path)
		set_process(true)
	_pic.texture = tex


func _process(_delta: float) -> void:
	# The sharp picture has been read on a worker thread: it takes the small copy's place.
	var tex: Texture2D = UiPictures.full(_want)
	if tex == null:
		return
	set_process(false)
	if _fading:
		_pic2.texture = tex
	else:
		_pic.texture = tex


## Fade the whole-picture shade to `v` (going from the title to a list and back).
func shade_to(v: float, secs := 0.25) -> void:
	shade = v
	if _all and is_inside_tree():
		create_tween().tween_property(_all, "color:a", v, secs)


func _ready() -> void:
	# Still: the picture fills the screen exactly, at its own sharpness. Nothing moves on its own.
	# (_process only runs to swap in a sharp picture that was still being read.)
	set_process(UiPictures.full(_want) == null and _want != "")
