class_name FirstStart
extends Control
## The very first time the game starts: a dark screen, one small light, a voice. The four
## worlds go by, the roads cross, the title lands, and the light asks who you are. Then the
## character creator opens on this stage instead of over the menu. Any key skips to the question.

signal ask          # the question has been asked and answered with "this is me": open the creator

const WORLDS := [
	{"name": "DOMINO CITY", "line": "Where it all began.", "color": Color("ffd166"), "faces": ["yugi", "kaiba", "joey"]},
	{"name": "DUEL ACADEMY", "line": "Where duelists are made.", "color": Color("7cc4ff"), "faces": ["jaden", "chazz", "alexis"]},
	{"name": "NEW DOMINO CITY", "line": "Where they duel at full speed.", "color": Color("ff8a3a"), "faces": ["yusei", "jack", "akiza"]},
	{"name": "HEARTLAND", "line": "Where they reach higher.", "color": Color("ff6ad8"), "faces": ["yuma", "shark", "kite"]},
]
const LINES := [
	"...Hello?",
	"Oh! There you are. I was hoping someone would come.",
	"There are four worlds out there. Four eras of duelists.",
	"They were never meant to meet. But the roads have crossed.",
	"I have a deck with no cards in it yet. I think it is yours.",
	"So, tell me. Who are you?",
]

var _back: ColorRect
var _light: TextureRect
var _halo: TextureRect
var _text: Label
var _title: Control
var _beams: Control
var _btn: Button
var _skip_l: Label
var _t := 0.0
var _beam := 0.0         # 0: no roads yet, 1: they have met in the middle
var _flash := 0.0
var _asked := false
var _skipped := false
var _run := 0            # which run of the sequence this is (a skip starts none)
var _home := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_back = ColorRect.new()
	_back.color = Color(0.008, 0.01, 0.022)
	_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back)
	_beams = Control.new()
	_beams.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_beams.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beams.draw.connect(_draw_beams)
	add_child(_beams)
	var glow := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.25, Color(0.75, 0.95, 1.0, 0.55))
	glow.gradient = g
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(0.5, 0.0)
	glow.width = 256
	glow.height = 256
	_halo = _glow_rect(glow, 520.0, Color(0.45, 0.85, 1.0, 0.35))
	_light = _glow_rect(glow, 120.0, Color(0.9, 1.0, 1.0, 1.0))
	_text = UITheme.label("", 40, Color(0.92, 0.97, 1.0), UITheme.semi_font())
	_text.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_text.offset_left = -800
	_text.offset_right = 800
	_text.offset_top = 150
	_text.offset_bottom = 300
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_title = Control.new()
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.modulate.a = 0.0
	add_child(_title)
	var small := UITheme.label("YU-GI-OH!", 34, UITheme.GOLD, UITheme.title_font())
	small.position = Vector2(-640, -250)
	small.size = Vector2(1280, 44)
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_child(small)
	var big := UITheme.label("CROSSROADS", 170, Color.WHITE, UITheme.title_font())
	big.position = Vector2(-800, -220)
	big.size = Vector2(1600, 190)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.1))
	big.add_theme_constant_override("outline_size", 14)
	_title.add_child(big)
	var tag := UITheme.label(Loc.t("Four eras. One story."), 30, Color(0.8, 0.9, 1.0), UITheme.semi_font())
	tag.position = Vector2(-640, -18)
	tag.size = Vector2(1280, 40)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_child(tag)
	_btn = Button.new()
	_btn.text = Loc.t("This is me")
	_btn.custom_minimum_size = Vector2(360, 70)
	_btn.add_theme_font_override("font", UITheme.title_font())
	_btn.add_theme_font_size_override("font_size", 32)
	_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_btn.offset_left = -180
	_btn.offset_right = 180
	_btn.offset_top = 300
	_btn.offset_bottom = 370
	_btn.visible = false
	_btn.pressed.connect(_answer)
	add_child(_btn)
	_skip_l = UITheme.label(Loc.t("Press any key to skip"), 18, Color(1, 1, 1, 0.35))
	_skip_l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_l.offset_left = -360
	_skip_l.offset_top = -60
	_skip_l.offset_right = -40
	_skip_l.offset_bottom = -30
	_skip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_skip_l)
	_light.modulate.a = 0.0
	_halo.modulate.a = 0.0
	Music.set_boost(-9.0)
	_play.call_deferred()
	if "--intro-answer" in OS.get_cmdline_user_args():
		# Dev: skip to the question and answer it, to see the creator open on this stage.
		get_tree().create_timer(1.0).timeout.connect(_skip)
		get_tree().create_timer(2.5).timeout.connect(_answer)


func _glow_rect(tex: Texture2D, px: float, col: Color) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = Vector2(px, px)
	r.pivot_offset = Vector2(px, px) / 2.0
	r.modulate = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	r.material = m
	add_child(r)
	return r


func _process(delta: float) -> void:
	_t += delta
	# The light breathes and drifts a little, and sits a bit above the middle.
	var c := size / 2.0 + _home + Vector2(sin(_t * 0.7) * 14.0, cos(_t * 0.9) * 9.0 - 60.0)
	var pulse := 1.0 + sin(_t * 2.4) * 0.06 + _flash * 0.8
	_light.position = c - _light.size / 2.0
	_light.scale = Vector2.ONE * pulse
	_halo.position = c - _halo.size / 2.0
	_halo.scale = Vector2.ONE * (1.0 + sin(_t * 1.3) * 0.08 + _flash * 1.6)
	_flash = maxf(0.0, _flash - delta * 1.6)
	_beams.queue_redraw()


## Four roads of light come in from the corners of the screen and meet in the middle.
func _draw_beams() -> void:
	if _beam <= 0.0 and _flash <= 0.0:
		return
	var c := size / 2.0 + Vector2(0, -60.0)
	var corners := [Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)]
	for i in 4:
		var col: Color = WORLDS[i]["color"]
		var from: Vector2 = corners[i]
		var to := from.lerp(c, clampf(_beam, 0.0, 1.0))
		for w in [[26.0, 0.07], [12.0, 0.16], [4.0, 0.7]]:
			_beams.draw_line(from, to, Color(col, float(w[1])), float(w[0]), true)
		_beams.draw_circle(to, 9.0, Color(col, 0.9))
	if _flash > 0.0:
		_beams.draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, clampf(_flash, 0.0, 1.0) * 0.55))


func _say(i: int) -> void:
	var tw := create_tween()
	tw.tween_property(_text, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		_text.text = Loc.t(LINES[i])
		_text.visible_ratio = 0.0
		Sfx.play("select", -14.0, 1.5))
	tw.tween_property(_text, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_text, "visible_ratio", 1.0, clampf(LINES[i].length() * 0.022, 0.3, 1.3))
	_flash = maxf(_flash, 0.12)


func _wait(sec: float, run: int) -> bool:
	await get_tree().create_timer(sec).timeout
	return is_inside_tree() and run == _run and not _skipped


func _play() -> void:
	_run += 1
	var run := _run
	var tw := create_tween().set_parallel()
	tw.tween_property(_light, "modulate:a", 1.0, 1.2)
	tw.tween_property(_halo, "modulate:a", 0.35, 1.6)
	if not await _wait(1.4, run): return
	_say(0)
	if not await _wait(1.9, run): return
	_say(1)
	if not await _wait(3.0, run): return
	_say(2)
	if not await _wait(2.5, run): return
	create_tween().tween_property(_text, "modulate:a", 0.0, 0.2)
	for i in WORLDS.size():
		_world(i)
		if not await _wait(1.05, run): return
	_say(3)
	create_tween().tween_property(self, "_beam", 1.0, 1.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	Sfx.play("charge", -8.0, 0.8)
	if not await _wait(2.1, run): return
	_land_title()
	if not await _wait(2.2, run): return
	_say(4)
	if not await _wait(3.0, run): return
	_question()


## One world goes by: a band in its colour with its name, and three of its duelists if you have them.
func _world(i: int) -> void:
	var w: Dictionary = WORLDS[i]
	var col: Color = w["color"]
	var from_left := i % 2 == 0
	var band := Control.new()
	band.size = Vector2(size.x, 320.0)
	band.position = Vector2(-size.x if from_left else size.x, size.y / 2.0 - 220.0 + (i % 2) * 40.0)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	move_child(band, _text.get_index())
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(col.darkened(0.55), 0.0))
	g.set_color(1, Color(col.darkened(0.55), 0.0))
	g.add_point(0.18, Color(col.darkened(0.35), 0.95))
	g.add_point(0.82, Color(col.darkened(0.6), 0.95))
	grad.gradient = g
	grad.width = 64
	grad.height = 8
	var bg := TextureRect.new()
	bg.texture = grad
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = band.size
	band.add_child(bg)
	for edge in [0.0, band.size.y - 4.0]:
		var line := ColorRect.new()
		line.color = col
		line.position = Vector2(size.x * 0.14, edge)
		line.size = Vector2(size.x * 0.72, 4.0)
		band.add_child(line)
	# The faces sit on the right; the name gets the room left of them (a long name in another
	# language gets smaller instead of running under the duelists).
	var faces: Array = []
	for key in w["faces"]:
		if Avatars.has_avatar(str(key)):
			faces.append(key)
	var fx := size.x * 0.82
	var faces_left := fx - 200.0 - 190.0 * maxf(0.0, faces.size() - 1.0) if not faces.is_empty() else size.x * 0.86
	var room := faces_left - size.x * 0.18 - 40.0
	var title := Loc.t(str(w["name"]))
	var fs := 110
	var tf := UITheme.title_font()
	while fs > 48 and tf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 2
	var name_l := UITheme.label(title, fs, Color.WHITE, tf)
	name_l.position = Vector2(size.x * 0.18, 60.0 + (110 - fs) * 0.6)
	band.add_child(name_l)
	var cap := UITheme.label(Loc.t(str(w["line"])), 34, col.lightened(0.45), UITheme.semi_font())
	cap.position = Vector2(size.x * 0.185, 200.0)
	cap.size.x = room
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	band.add_child(cap)
	for key in faces:
		var face := TextureRect.new()
		face.texture = Portraits.get_portrait(str(key))
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.size = Vector2(200, 270)
		face.position = Vector2(fx - 200.0, 25.0)
		face.clip_contents = true
		band.add_child(face)
		fx -= 190.0
	Sfx.play("whoosh", -6.0, 0.9 + i * 0.08)
	var tw := create_tween()
	tw.tween_property(band, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(band, "position:x", 30.0 if from_left else -30.0, 0.6)
	tw.tween_property(band, "position:x", size.x if from_left else -size.x, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(band.queue_free)


func _land_title() -> void:
	_flash = 1.0
	_beam = 1.0
	Sfx.play("gong", -2.0)
	Sfx.play("special", -6.0)
	create_tween().tween_property(_text, "modulate:a", 0.0, 0.15)
	_title.modulate.a = 1.0
	_title.scale = Vector2(1.7, 1.7)
	var tw := create_tween().set_parallel()
	tw.tween_property(_title, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_home", Vector2(0, 150.0), 0.8).set_trans(Tween.TRANS_SINE)


func _question() -> void:
	if _asked:
		return
	_asked = true
	_skip_l.visible = false
	_say(5)
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	_btn.visible = true
	_btn.modulate.a = 0.0
	create_tween().tween_property(_btn, "modulate:a", 1.0, 0.3)
	_btn.grab_focus()


func _answer() -> void:
	Sfx.play("summon", -4.0)
	_btn.visible = false
	create_tween().tween_property(_text, "modulate:a", 0.0, 0.2)
	create_tween().tween_property(_title, "modulate:a", 0.0, 0.3)
	ask.emit()


## Straight to the title and the question.
func _skip() -> void:
	if _skipped or _asked:
		return
	_skipped = true
	for c in get_children():
		if c is Control and c != _back and c != _beams and c != _light and c != _halo and c != _text and c != _title and c != _btn and c != _skip_l:
			c.queue_free()
	_land_title()
	_question()


func _input(event: InputEvent) -> void:
	if _asked or _t < 0.8:
		return
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed):
		get_viewport().set_input_as_handled()
		_skip()


## The creator is done: fade away and leave the menu behind it.
func leave() -> void:
	Music.set_boost(0.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
