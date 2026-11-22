class_name AcademyBackdrop
extends Control
## The picture behind the Academy's own screens: the island at sunset (a picture taken in the
## game itself), drifting very slowly, darker on the side the words are on, with a few motes of
## light going up. `shade`: how dark the whole of it is (0 for the title, more behind a list).

const PICTURE := "res://assets/ui/academy_title.jpg"

var shade := 0.0: set = set_shade

var _pic: TextureRect
var _pic2: TextureRect           # the next picture, fading in over the first when there are several
var _cycle: Array = []           # textures shown in turn (empty: one picture, still)
var _ci := 0
var _ct := 0.0
var _fading := false
const HOLD := 7.0
const FADE := 1.8
var _side: TextureRect
var _all: ColorRect
var _t := 0.0
var _motes: Array = []


var _mote_col := Color(1.0, 0.9, 0.62)


## `pic`: another picture taken in the game (the main story uses Domino City at night), and
## `mote`: the color of the motes of light that drift up over it.
func _init(dark := 0.0, pic := PICTURE, mote := Color(1.0, 0.9, 0.62)) -> void:
	shade = dark
	_mote_col = mote
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var under := ColorRect.new()
	under.color = Color(0.03, 0.04, 0.1)
	under.set_anchors_preset(Control.PRESET_FULL_RECT)
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(under)
	_pic = TextureRect.new()
	if ResourceLoader.exists(pic):
		_pic.texture = load(pic)
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pic)
	_pic2 = TextureRect.new()
	_pic2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		_motes.append({"x": rng.randf(), "y": rng.randf(), "v": rng.randf_range(0.012, 0.035), "r": rng.randf_range(1.6, 4.2), "p": rng.randf() * TAU, "a": rng.randf_range(0.25, 0.7)})


func set_shade(v: float) -> void:
	shade = v
	if _all:
		_all.color.a = v


## Show these pictures in turn, each held a few seconds and crossfading into the next (the main
## story's door with no game yet, and its Load screen). One path: just that picture, still.
func cycle(paths: Array) -> void:
	_cycle = []
	for p in paths:
		if ResourceLoader.exists(str(p)):
			_cycle.append(load(str(p)))
	if _cycle.is_empty():
		return
	_ci = 0
	_ct = 0.0
	_pic.texture = _cycle[0]
	_pic2.modulate.a = 0.0
	if _cycle.size() == 1:
		_cycle = []


## Show one picture now (no fading).
func show_picture(path: String) -> void:
	_cycle = []
	if ResourceLoader.exists(path):
		_pic.texture = load(path)
	_pic2.modulate.a = 0.0


## Crossfade from the picture on now to this one (the Free Roam door, as you move between worlds).
func fade_to(path: String, secs := 0.45) -> void:
	_cycle = []
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if _pic.texture == tex:
		return
	_pic2.texture = tex
	_pic2.modulate.a = 0.0
	_fading = true
	var tw := create_tween()
	tw.tween_property(_pic2, "modulate:a", 1.0, secs)
	tw.tween_callback(func():
		_pic.texture = tex
		_pic2.modulate.a = 0.0
		_fading = false)


## Fade the whole-picture shade to `v` (going from the title to a list and back).
func shade_to(v: float, secs := 0.25) -> void:
	shade = v
	if _all and is_inside_tree():
		create_tween().tween_property(_all, "color:a", v, secs)


func _process(delta: float) -> void:
	_t += delta
	# The picture is a little larger than the screen and wanders inside its margin.
	var grow := 1.07
	_pic.size = size * grow
	var slack := size * (grow - 1.0)
	_pic.position = Vector2(-slack.x * (0.5 + 0.5 * sin(_t * 0.045)), -slack.y * (0.5 + 0.5 * cos(_t * 0.031)))
	_pic2.size = _pic.size
	_pic2.position = _pic.position
	if _cycle.size() > 1 and not _fading:
		_ct += delta
		if _ct >= HOLD:
			_ct = 0.0
			_fading = true
			_ci = (_ci + 1) % _cycle.size()
			_pic2.texture = _cycle[_ci]
			var tw := create_tween()
			tw.tween_property(_pic2, "modulate:a", 1.0, FADE)
			tw.tween_callback(func():
				_pic.texture = _pic2.texture
				_pic2.modulate.a = 0.0
				_fading = false)
	for m in _motes:
		m["y"] = float(m["y"]) - float(m["v"]) * delta
		if float(m["y"]) < -0.03:
			m["y"] = 1.03
	queue_redraw()


func _draw() -> void:
	# (Children draw over this, so the motes are drawn by a child that sits on top: see _ready.)
	pass


func _ready() -> void:
	var top := Control.new()
	top.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	top.draw.connect(func():
		for m in _motes:
			var x := (float(m["x"]) + 0.012 * sin(_t * 0.6 + float(m["p"]))) * size.x
			var y := float(m["y"]) * size.y
			var a := float(m["a"]) * (0.6 + 0.4 * sin(_t * 1.3 + float(m["p"])))
			top.draw_circle(Vector2(x, y), float(m["r"]) * 2.4, Color(_mote_col.darkened(0.05), a * 0.12))
			top.draw_circle(Vector2(x, y), float(m["r"]), Color(_mote_col, a)))
	set_process(true)
	var redraw := func(): top.queue_redraw()
	var tm := Timer.new()
	tm.wait_time = 0.033
	tm.autostart = true
	tm.timeout.connect(redraw)
	add_child(tm)
