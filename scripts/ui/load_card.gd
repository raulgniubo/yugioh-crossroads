class_name LoadCard
extends Control
## The screen you see while a world gets ready: the place's name in its era's color, a skyline,
## the roads of light from the intro, a tip, and Lumen's light breathing in the corner. It sits
## on the router's dark fade, so it fades in and out with it.

const PLACES := {
	"domino": {"era": "DUEL MONSTERS", "color": Color("ffd166"), "line": "Where it all began."},
	"academy": {"era": "GX", "color": Color("7cc4ff"), "line": "Where duelists are made."},
	"satellite": {"era": "5D'S", "color": Color("ff8a3a"), "line": "Where they duel at full speed."},
	"newdomino": {"era": "5D'S", "color": Color("ff8a3a"), "line": "Where they duel at full speed."},
	"heartland": {"era": "ZEXAL", "color": Color("ff6ad8"), "line": "Where they reach higher."},
	"museum": {"era": "CROSSROADS", "color": Color("bfe9ff"), "line": "Between the ages."},
	"ride": {"era": "5D'S", "color": Color("ff8a3a"), "line": "Where they duel at full speed."},
}
const TIPS := [
	"Press M for the map. Places you can go in are marked on it.",
	"Lumen knows what to do next: press L to ask her.",
	"A Side Deck lets you swap cards between the duels of a Match.",
	"The first win of each Knockout cup brings more of Lumen's cards.",
	"The Card Album shows every card you own, have seen, or are still missing.",
	"Story saves are in the pause menu while you play the story.",
	"Booster packs only hold cards from the eras the story has opened.",
	"Your deck needs 40 to 60 cards. Lumen is in every starter.",
	"Hold Shift to run (or the right trigger on a controller).",
	"Tournaments give badges, keys and trophies. Four titles in all.",
]

var _key := "domino"
var _t := 0.0
var _tip := ""
var _sky: Array = []        # [x, width, height, windows seed]


func setup(key: String, title: String, sub: String) -> void:
	_key = key if PLACES.has(key) else "domino"
	_tip = Loc.t(TIPS[randi() % TIPS.size()])
	var col: Color = PLACES[_key]["color"]
	# The old lines are taken out right now, not at the end of the frame: while they were still
	# there the new ones could not have their names ("title", "tip"...), the layout below found
	# the old ones, and from the second loading card on everything piled up in the top left
	# corner with the tip running down the edge one letter per line.
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var era := UITheme.label(Loc.t(str(PLACES[_key]["era"])), 26, col, UITheme.title_font())
	era.position = Vector2(110, 0)
	era.name = "era"
	add_child(era)
	var t := UITheme.label(title.to_upper(), 120, Color.WHITE, UITheme.title_font())
	t.name = "title"
	t.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	t.add_theme_constant_override("outline_size", 12)
	add_child(t)
	var s := UITheme.label(sub if sub != "" else Loc.t(str(PLACES[_key]["line"])), 32, col.lightened(0.45), UITheme.semi_font())
	s.name = "sub"
	add_child(s)
	var tip := UITheme.label(Loc.t("TIP") + "   " + _tip, 22, Color(1, 1, 1, 0.7), UITheme.semi_font())
	tip.name = "tip"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(tip)
	var ld := UITheme.label(Loc.t("Loading"), 26, Color(1, 1, 1, 0.8), UITheme.semi_font())
	ld.name = "loading"
	add_child(ld)
	_sky.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_key)
	var x := -20.0
	while x < 2600.0:
		var w := rng.randf_range(60, 170)
		_sky.append([x, w, rng.randf_range(50, 240), rng.randi()])
		x += w + rng.randf_range(4, 26)
	_layout()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)


func _layout() -> void:
	var t := get_node_or_null("title") as Label
	if t == null:
		return
	var w := size.x
	var h := size.y
	# A long name (or a long name in Spanish) gets smaller instead of running off the screen.
	var fs := 120
	var f := UITheme.title_font()
	while fs > 56 and f.get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 220:
		fs -= 4
	t.add_theme_font_size_override("font_size", fs)
	t.position = Vector2(104, h * 0.5 - fs * 0.62)
	(get_node("era") as Control).position = Vector2(112, t.position.y - 6)
	(get_node("sub") as Control).position = Vector2(112, t.position.y + fs * 1.08)
	var tip := get_node("tip") as Label
	tip.position = Vector2(110, h - 112)
	tip.size = Vector2(w * 0.6, 60)
	var ld := get_node("loading") as Label
	ld.position = Vector2(w - 260, h - 104)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	var ld := get_node_or_null("loading") as Label
	if ld:
		ld.text = Loc.t("Loading") + ".".repeat(int(_t * 2.5) % 4)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var col: Color = PLACES.get(_key, PLACES["domino"])["color"]
	# Night sky in the era's color, darker at the top.
	var steps := 24
	for i in steps:
		var k := float(i) / steps
		draw_rect(Rect2(0, h * k, w, h / steps + 1), Color(0.012, 0.016, 0.035).lerp(col.darkened(0.78), k * 0.9))
	# The four roads of light from the intro, crossing behind the name.
	var c := Vector2(w * 0.62, h * 0.46)
	var eras := [Color("ffd166"), Color("7cc4ff"), Color("ff8a3a"), Color("ff6ad8")]
	var corners := [Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]
	for i in 4:
		var a: Color = eras[i]
		var wob := sin(_t * 0.8 + i) * 0.04
		for lw in [[22.0, 0.05], [9.0, 0.12], [3.0, 0.45]]:
			draw_line(corners[i], c + Vector2(wob * 300.0, 0), Color(a, float(lw[1])), float(lw[0]), true)
	# Glow where they meet.
	for r in [260.0, 160.0, 80.0]:
		draw_circle(c, r, Color(col, 0.04 + 0.02 * sin(_t * 1.5)))
	# The skyline along the bottom, its windows lit here and there.
	var base := h - 150.0
	for b in _sky:
		var bx: float = b[0]
		var bw: float = b[1]
		var bh: float = b[2]
		draw_rect(Rect2(bx, base - bh, bw, bh + 160.0), Color(0.02, 0.025, 0.05, 0.96))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(b[3])
		var wy := base - bh + 14.0
		while wy < base - 10.0:
			var wx := bx + 10.0
			while wx < bx + bw - 14.0:
				if rng.randf() < 0.28:
					var flick := 0.5 + 0.5 * sin(_t * 0.7 + rng.randf() * 6.0)
					draw_rect(Rect2(wx, wy, 7, 10), Color(col.lightened(0.3), 0.25 + 0.35 * flick))
				wx += 16.0
			wy += 22.0
	draw_rect(Rect2(0, base + 4, w, 3), Color(col, 0.55))
	# A bar under the tip and Lumen's light by the word "Loading".
	draw_rect(Rect2(110, h - 128, 90, 3), col)
	var lp := Vector2(w - 296, h - 88)
	var pulse := 1.0 + sin(_t * 3.0) * 0.15
	for r in [30.0, 18.0, 9.0]:
		draw_circle(lp, r * pulse, Color(0.75, 0.95, 1.0, 0.18 if r > 20 else (0.35 if r > 10 else 0.95)))
