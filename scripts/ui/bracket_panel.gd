class_name BracketPanel
extends Control
## The tournament bracket: eight names on the left narrowing to one champion on the right.
## Rounds already played are filled in; your seat is lit. One button starts your next duel.

signal closed
signal play

var id := ""
var _result := {}
var _plates: Array = []      # [Control, round, index]
var _board: Control


func _init(tourney: String, result := {}) -> void:
	id = tourney
	_result = result


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(MenuBackdrop.new(0.96))
	var d: Dictionary = Tournament.DEFS[id]
	var s := Tournament.st(id)
	var col: Color = d["color"]
	var head := VBoxContainer.new()
	head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	head.offset_top = 34
	head.offset_left = 70
	head.offset_right = -70
	head.add_theme_constant_override("separation", 0)
	add_child(head)
	head.add_child(UITheme.label(Loc.t(str(d["name"])).to_upper(), 58, Color.WHITE, UITheme.title_font()))
	var stage := str(s["stage"])
	var sub := ""
	if stage == "won":
		sub = Loc.t("You are the champion.")
	elif stage == "out":
		sub = Loc.t("Knocked out by %s. Enter again at the desk any time.") % str(s.get("out_to", "?"))
	else:
		sub = Loc.t(Tournament.ROUNDS[clampi(int(s["round"]), 0, 2)]).capitalize() + "  ·  " + Loc.t("win three duels in a row to take the title")
	head.add_child(UITheme.label(sub, 24, col.lightened(0.3), UITheme.semi_font()))
	_board = Control.new()
	_board.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board.offset_top = 170
	_board.offset_bottom = -150
	_board.offset_left = 70
	_board.offset_right = -70
	_board.draw.connect(_draw_lines)
	add_child(_board)
	var foot := HBoxContainer.new()
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -120
	foot.offset_bottom = -44
	foot.offset_left = 70
	foot.offset_right = -70
	foot.add_theme_constant_override("separation", 16)
	foot.alignment = BoxContainer.ALIGNMENT_END
	add_child(foot)
	var note := UITheme.label("", 22, UITheme.TEXT, UITheme.semi_font())
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_child(note)
	if _result.get("champion", false):
		var names: Array = []
		for c in _result.get("cards", []):
			names.append(str(CardData.get_card(int(c)).get("name", "?")))
		note.text = Loc.t("Champion's purse:  +%d Duel Points") % int(_result.get("prize_dp", 0)) + ("   ·   " + ", ".join(names) if not names.is_empty() else "") + "   ·   " + Loc.t("a trophy for your shelf")
		note.add_theme_color_override("font_color", UITheme.GOLD)
	var close := Button.new()
	close.text = Loc.t("  Close  ")
	close.custom_minimum_size = Vector2(200, 64)
	close.add_theme_font_size_override("font_size", 24)
	close.pressed.connect(_close)
	foot.add_child(close)
	var opp := Tournament.my_match(id)
	if not opp.is_empty():
		var go := Button.new()
		go.text = "  " + Loc.t("Duel %s") % str(opp["name"]) + "  "
		go.custom_minimum_size = Vector2(420, 64)
		go.add_theme_font_size_override("font_size", 26)
		go.add_theme_stylebox_override("normal", UITheme.button_box(col, col.lightened(0.3)))
		go.add_theme_stylebox_override("hover", UITheme.button_box(col.lightened(0.15), Color.WHITE))
		go.add_theme_color_override("font_color", Color(0.03, 0.05, 0.09))
		go.add_theme_color_override("font_hover_color", Color(0.03, 0.05, 0.09))
		go.pressed.connect(func():
			Sfx.play("summon", -4.0)
			play.emit())
		foot.add_child(go)
		go.grab_focus.call_deferred()
		note.text = Loc.t("Next: %s, %s Deck.") % [str(opp["name"]), CardData.deck_name(str(opp["deck"]))]
		if Tournament.is_turbo(id):
			note.text += "   " + Loc.t("This round is a Turbo Duel.")
			if Tournament.DEFS[id].get("all_turbo", false):
				go.text = "  " + Loc.t("Race, then duel %s") % str(opp["name"]) + "  "
	else:
		close.grab_focus.call_deferred()
	await get_tree().process_frame
	_build_plates(col)
	# The round is announced as the bracket comes up.
	var word: String = "CHAMPION!" if stage == "won" else ("ELIMINATED" if stage == "out" else Tournament.ROUNDS[clampi(int(s["round"]), 0, 2)])
	_announce(Loc.t(word), UITheme.GOLD if stage == "won" else (UITheme.DANGER if stage == "out" else col))
	Sfx.play("gong", -8.0)
	if stage == "won":
		Sfx.play("cheer", -4.0)
		Sfx.play("rare", -5.0)


func _plate_rect(r: int, i: int) -> Rect2:
	var w := _board.size.x
	var h := _board.size.y
	var col_w := w / 4.0
	var n := 8 >> r
	var slot := h / float(n)
	var pw := minf(col_w - 60.0, 380.0)
	var ph := minf(64.0, slot - 10.0) if r < 3 else 96.0
	return Rect2(Vector2(r * col_w + (0.0 if r < 3 else 10.0), slot * (i + 0.5) - ph / 2.0), Vector2(pw, ph))


func _build_plates(col: Color) -> void:
	var s := Tournament.st(id)
	var rounds: Array = s["rounds"]
	for r in 4:
		var n := 8 >> r
		var head := UITheme.label(Loc.t(Tournament.ROUNDS[r]), 16, col if r < 3 else UITheme.GOLD, UITheme.semi_font())
		head.position = Vector2(_plate_rect(r, 0).position.x, -30)
		_board.add_child(head)
		for i in n:
			var e: Dictionary = (rounds[r] as Array)[i] if r < rounds.size() and i < (rounds[r] as Array).size() else {}
			var rect := _plate_rect(r, i)
			var pc := PanelContainer.new()
			var you: bool = e.get("you", false)
			# Lost in this round: their name is not on the next list.
			var lost := false
			if not e.is_empty() and r + 1 < rounds.size():
				lost = not (rounds[r + 1] as Array).has(e)
			var bg := Color(0.04, 0.07, 0.12, 0.92)
			var border := Color(1, 1, 1, 0.14)
			if you:
				bg = Color(col.darkened(0.6), 0.95)
				border = col
			if r == 3 and not e.is_empty():
				border = UITheme.GOLD
				bg = Color(0.2, 0.15, 0.03, 0.95)
			var sb := UITheme.panel_box(bg, 12, border)
			sb.set_border_width_all(3 if you or r == 3 else 1)
			sb.content_margin_left = 8
			sb.content_margin_right = 12
			sb.content_margin_top = 4
			sb.content_margin_bottom = 4
			pc.add_theme_stylebox_override("panel", sb)
			pc.position = rect.position
			pc.size = rect.size
			pc.custom_minimum_size = rect.size
			_board.add_child(pc)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			pc.add_child(h)
			if e.is_empty():
				var q := UITheme.label("?", 26, Color(1, 1, 1, 0.25), UITheme.title_font())
				q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				h.add_child(q)
			else:
				var face := TextureRect.new()
				face.texture = Portraits.get_portrait(str(e["char"]))
				face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				face.custom_minimum_size = Vector2(rect.size.y - 10.0, rect.size.y - 10.0)
				face.clip_contents = true
				h.add_child(face)
				var nm := UITheme.label(str(e["name"]).to_upper() if you else str(e["name"]), 26 if r == 3 else 22, Color.WHITE if not lost else Color(1, 1, 1, 0.35), UITheme.title_font() if you or r == 3 else UITheme.semi_font())
				nm.clip_text = true
				nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h.add_child(nm)
				if lost:
					pc.modulate = Color(0.75, 0.75, 0.8, 0.7)
			# Plates fly in column by column.
			pc.modulate.a = 0.0
			var to_x := pc.position.x
			pc.position.x = to_x - 50.0
			var tw := pc.create_tween().set_parallel()
			var delay := r * 0.16 + i * 0.03
			tw.tween_property(pc, "modulate:a", 0.7 if lost else 1.0, 0.2).set_delay(delay)
			tw.tween_property(pc, "position:x", to_x, 0.3).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_plates.append([pc, r, i])
	_board.queue_redraw()


func _draw_lines() -> void:
	if _board.size.x < 10.0:
		return
	var s := Tournament.st(id)
	var rounds: Array = s["rounds"]
	var col: Color = Tournament.DEFS[id]["color"]
	for r in 3:
		var n := 8 >> r
		for i in n:
			var a := _plate_rect(r, i)
			var b := _plate_rect(r + 1, i / 2)
			var from := a.position + Vector2(a.size.x, a.size.y / 2.0)
			var to := b.position + Vector2(0, b.size.y / 2.0)
			var mid := (from.x + to.x) / 2.0
			# The winner's path is drawn bright.
			var e: Dictionary = (rounds[r] as Array)[i] if r < rounds.size() and i < (rounds[r] as Array).size() else {}
			var through: bool = not e.is_empty() and r + 1 < rounds.size() and (rounds[r + 1] as Array).has(e)
			var c := Color(col, 0.9) if through else Color(1, 1, 1, 0.16)
			var w := 3.0 if through else 2.0
			_board.draw_line(from, Vector2(mid, from.y), c, w)
			_board.draw_line(Vector2(mid, from.y), Vector2(mid, to.y), c, w)
			_board.draw_line(Vector2(mid, to.y), to, c, w)


func _announce(text: String, col: Color) -> void:
	var l := UITheme.label(text, 150, col.lightened(0.2), UITheme.title_font())
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 22)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.rotation = -0.05
	add_child(l)
	await get_tree().process_frame
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(2.2, 2.2)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.parallel().tween_property(l, "scale", Vector2(1.15, 1.15), 0.35)
	tw.tween_callback(l.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
