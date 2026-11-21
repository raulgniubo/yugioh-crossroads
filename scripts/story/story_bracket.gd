class_name StoryBracket
extends Control
## The board of a tournament inside a story: sixteen names on the left narrowing to one on the
## right. It is a picture of where everybody stands, nothing is clicked on it: the story shows it
## between rounds and moves on.
##
## board: {"title": "The Rookie Tournament", "round": "Round 1",
##         "names": [16 x (character key | [name, dorm])]   ("player" is you),
##         "wins": [[8 indices], [4], [2], [1]]             who went through, round by round (as far as it got)}

const HEADS := ["Round 1", "Quarterfinals", "Semifinals", "Final", "Champion"]
const DORM_COLS := {"red": Color("d9342b"), "yellow": Color("f2c230"), "blue": Color("2f6fe0")}

var board := {}
var _area: Control
var _font: Font


func _init(b: Dictionary) -> void:
	board = b


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UITheme.semi_font()
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var head := VBoxContainer.new()
	head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	head.offset_top = 26
	head.offset_left = 60
	head.offset_right = -60
	head.add_theme_constant_override("separation", 0)
	add_child(head)
	head.add_child(UITheme.label(Loc.t(str(board.get("title", ""))).to_upper(), 50, Color.WHITE, UITheme.title_font()))
	head.add_child(UITheme.label(Loc.t(str(board.get("round", ""))), 24, UITheme.GOLD, UITheme.semi_font()))
	_area = Control.new()
	_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_area.offset_top = 176
	_area.offset_bottom = -40
	_area.offset_left = 60
	_area.offset_right = -60
	_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.draw.connect(_draw_board)
	add_child(_area)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	Sfx.play("gong", -10.0)


## Name and dorm of entry `i`.
func _entry(i: int) -> Array:
	var e = (board.get("names", []) as Array)[i]
	if e is Array:
		return [str(e[0]), str(e[1])]
	var key := str(e)
	if key == "player":
		return [Profile.duelist_name, Campus.DORMS[Campus.dorm()] if Campus.on else "red"]
	return [str(Characters.get_char(key).get("name", key)), str(Avatars.UNIFORMS.get(key, ""))]


## Who stands in column `r` (0 = everybody, 1 = winners of round 1, ...), top to bottom.
func _column(r: int) -> Array:
	if r == 0:
		return range((board.get("names", []) as Array).size())
	var wins: Array = board.get("wins", [])
	if r - 1 >= wins.size():
		return []
	# Kept in bracket order, whatever order the script wrote them in.
	var out: Array = (wins[r - 1] as Array).duplicate()
	out.sort()
	return out


func _slot_of(r: int, entry: int) -> int:
	return entry >> r


func _rect(r: int, slot: int) -> Rect2:
	var w := _area.size.x
	var h := _area.size.y
	var col_w := w / 5.0
	var n := 16 >> r
	var each := h / float(n)
	var ph := minf(each - 6.0, 46.0) if r < 4 else 76.0
	return Rect2(Vector2(r * col_w, each * (slot + 0.5) - ph / 2.0), Vector2(col_w - 34.0, ph))


func _draw_board() -> void:
	if _area.size.x < 10.0:
		return
	var you := (board.get("names", []) as Array).find("player")
	for r in 5:
		_area.draw_string(_font, Vector2(r * _area.size.x / 5.0 + 2.0, -12.0), Loc.t(HEADS[r]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
			UITheme.GOLD if r == 4 else Color(1, 1, 1, 0.6))
		var here := _column(r)
		var after := _column(r + 1) if r < 4 else []
		var n := 16 >> r
		for slot in n:
			var rect := _rect(r, slot)
			var who := -1
			for e in here:
				if _slot_of(r, int(e)) == slot:
					who = int(e)
			# The line on to the next column.
			if r < 4:
				var to := _rect(r + 1, slot / 2)
				var a := rect.position + Vector2(rect.size.x, rect.size.y / 2.0)
				var b := to.position + Vector2(0, to.size.y / 2.0)
				var mid := (a.x + b.x) / 2.0
				var through := who >= 0 and after.has(who)
				var lc := Color(1, 0.82, 0.4, 0.95) if through else Color(1, 1, 1, 0.14)
				var lw := 3.0 if through else 2.0
				_area.draw_line(a, Vector2(mid, a.y), lc, lw)
				_area.draw_line(Vector2(mid, a.y), Vector2(mid, b.y), lc, lw)
				_area.draw_line(Vector2(mid, b.y), b, lc, lw)
			var bg := Color(0.05, 0.08, 0.14, 0.95)
			var border := Color(1, 1, 1, 0.14)
			if who < 0:
				_area.draw_style_box(UITheme.panel_box(bg, 8, border), rect)
				_area.draw_string(_font, rect.position + Vector2(0, rect.size.y / 2.0 + 7.0), "?", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 20, Color(1, 1, 1, 0.22))
				continue
			var e2 := _entry(who)
			var dorm_col: Color = DORM_COLS.get(e2[1], Color(0.6, 0.6, 0.66))
			var out := r < 4 and not after.is_empty() and not after.has(who) and _decided(r, slot, after)
			if who == you:
				bg = Color(0.1, 0.22, 0.3, 0.98)
				border = UITheme.ACCENT
			if r == 4:
				bg = Color(0.22, 0.16, 0.03, 0.98)
				border = UITheme.GOLD
			var sb := UITheme.panel_box(bg, 8, border)
			sb.set_border_width_all(3 if who == you or r == 4 else 1)
			_area.draw_style_box(sb, rect)
			# The dorm's color down the left edge.
			_area.draw_rect(Rect2(rect.position + Vector2(4, 5), Vector2(7, rect.size.y - 10.0)), Color(dorm_col, 0.4 if out else 1.0))
			var fs := 26 if r == 4 else (20 if rect.size.y > 34.0 else 16)
			var tc := Color(1, 1, 1, 0.34) if out else Color.WHITE
			_area.draw_string(_font, rect.position + Vector2(20, rect.size.y / 2.0 + fs * 0.36), e2[0], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 26.0, fs, tc)


## Has the match that slot `slot` of column `r` plays been decided (somebody from it went on)?
func _decided(r: int, slot: int, after: Array) -> bool:
	for e in after:
		if _slot_of(r + 1, int(e)) == slot / 2:
			return true
	return false


func leave() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
