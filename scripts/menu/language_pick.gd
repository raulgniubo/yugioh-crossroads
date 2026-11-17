class_name LanguagePick
extends Control
## The very first thing a new player sees: pick a language. Two big cards over the dark stage of
## the opening (the four roads of light, Lumen's light breathing in the middle), every word in
## both languages until one is picked. Then the menu loads again in that language and the
## opening plays.

const ERA := [Color("ffd166"), Color("7cc4ff"), Color("ff8a3a"), Color("ff6ad8")]
const CARDS := {
	"en": {"name": "English", "line": "Play in English", "color": Color("7cc4ff")},
	"es": {"name": "Español", "line": "Jugar en español", "color": Color("ffd166")},
}

var _t := 0.0
var _in := 0.0              # 0 to 1 as the screen arrives
var _cards: Array[Button] = []
var _picked := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	var small := UITheme.label("YU-GI-OH!  CROSSROADS", 26, UITheme.GOLD, UITheme.title_font())
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(small)
	var t := UITheme.label("Choose your language", 64, Color.WHITE, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var t2 := UITheme.label("Elige tu idioma", 40, Color(0.8, 0.9, 1.0), UITheme.title_font())
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t2)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 46)
	col.add_child(gap)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 44)
	col.add_child(row)
	for lang in Loc.LANGS:
		var code := str(lang[0])
		var info: Dictionary = CARDS.get(code, {"name": str(lang[1]), "line": "", "color": Color("7cc4ff")})
		var b := Button.new()
		b.custom_minimum_size = Vector2(420, 250)
		b.focus_mode = Control.FOCUS_ALL
		b.set_meta("info", info)
		b.set_meta("code", code)
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		b.draw.connect(_draw_card.bind(b))
		b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(func(): Sfx.play("select", -12.0))
		b.pressed.connect(_pick.bind(code, b))
		row.add_child(b)
		_cards.append(b)
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 40)
	col.add_child(gap2)
	var foot := UITheme.label("You can change it later in Settings   ·   Puedes cambiarlo después en Ajustes", 20, Color(1, 1, 1, 0.55), UITheme.semi_font())
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(foot)
	modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	tw.tween_property(self, "_in", 1.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# The card of the language the computer is set to is the one in your hands first.
	var want := 1 if OS.get_locale_language() == "es" and _cards.size() > 1 else 0
	_cards[want].grab_focus.call_deferred()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	for b in _cards:
		b.queue_redraw()


## The stage: near black, the four roads of light meeting in the middle, a soft glow there.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.01, 0.022))
	var c := size / 2.0 + Vector2(0, 30)
	var corners := [Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)]
	for i in 4:
		var from: Vector2 = corners[i]
		var to := from.lerp(c, _in)
		for w in [[30.0, 0.03], [12.0, 0.07], [3.0, 0.3]]:
			draw_line(from, to, Color(ERA[i], float(w[1])), float(w[0]), true)
	var breathe := 1.0 + sin(_t * 1.6) * 0.06
	for k in 18:
		draw_circle(c, (70.0 + k * 30.0) * breathe * _in, Color(0.3, 0.7, 1.0, 0.009))


func _draw_card(b: Button) -> void:
	var info: Dictionary = b.get_meta("info")
	var col: Color = info["color"]
	var on := b.has_focus()
	var r := Rect2(Vector2.ZERO, b.size)
	var lift := 1.0 if on else 0.0
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.085, 0.17, 0.96).lerp(col.darkened(0.72), 0.55 * lift)
	box.set_corner_radius_all(22)
	box.border_color = col if on else Color(col, 0.35)
	box.set_border_width_all(4 if on else 2)
	if on:
		box.shadow_color = Color(col, 0.35 + 0.1 * sin(_t * 3.0))
		box.shadow_size = 26
	b.draw_style_box(box, r)
	# A bar of the card's colour on top, the name big, the line under it.
	b.draw_rect(Rect2(r.position + Vector2(34, 30), Vector2(70, 5)), col)
	var f := UITheme.title_font()
	var name := str(info["name"])
	var ns := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 72)
	b.draw_string(f, Vector2((r.size.x - ns.x) / 2.0, r.size.y / 2.0 + 18), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color.WHITE if on else Color(0.86, 0.9, 1.0))
	var fs := UITheme.semi_font()
	var line := str(info["line"])
	var ls := fs.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	b.draw_string(fs, Vector2((r.size.x - ls.x) / 2.0, r.size.y / 2.0 + 66), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col.lightened(0.4) if on else Color(1, 1, 1, 0.5))


func _pick(code: String, b: Button) -> void:
	if _picked:
		return
	_picked = true
	Sfx.play("summon", -6.0)
	Settings.language = code
	Settings.first_language = false
	Settings.apply()
	Settings.save_settings()
	b.pivot_offset = b.size / 2.0
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.06, 1.06), 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): Router.go(Router.MAIN_MENU))
