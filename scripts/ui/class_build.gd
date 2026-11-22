class_name ClassBuild
extends Control
## Deck Building class: sixty cards on your desk, forty of them go into a deck. Click a card to put
## it in or take it out; the big card on the right is the one you are pointing at. The deck is only
## for the duel that follows. Nothing here touches your collection.

signal closed(deck: Array)

const CARD := Vector2(100, 146)
const COLS := 12

var pool: Array = []          # the sixty card ids
var _in := {}                 # card id -> true
var _tiles := {}              # card id -> its button
var _count: Label
var _split: Label
var _go: Button
var _big: TextureRect
var _name: Label
var _stat: Label
var _text: Label
var _shown := 0


func _init(cards: Array = []) -> void:
	pool = cards


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	center.add_child(v)
	var title := UITheme.label(Loc.t("DECK BUILDING"), 46, Color.WHITE, UITheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UITheme.label(Loc.t("Sixty cards on the desk. Choose the forty you will duel with. Click a card to put it in or take it out."), 20, UITheme.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	v.add_child(row)
	# ---- the desk
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	row.add_child(grid)
	var sorted := pool.duplicate()
	sorted.sort_custom(func(a, b): return _rank(int(a)) < _rank(int(b)))
	for id in sorted:
		var t := _tile(int(id))
		grid.add_child(t)
		_tiles[int(id)] = t
	# ---- the card you are looking at
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(380, 0)
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	_big = TextureRect.new()
	_big.custom_minimum_size = Vector2(300, 438)
	_big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_big.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	side.add_child(_big)
	_name = UITheme.label("", 22, Color.WHITE, UITheme.semi_font())
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_name)
	_stat = UITheme.label("", 18, UITheme.GOLD)
	side.add_child(_stat)
	_text = UITheme.label("", 16, UITheme.TEXT_DIM)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(380, 150)
	side.add_child(_text)
	# ---- the count and the buttons
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 22)
	v.add_child(foot)
	_count = UITheme.label("", 30, UITheme.GOLD, UITheme.title_font())
	foot.add_child(_count)
	_split = UITheme.label("", 19, UITheme.TEXT_DIM)
	foot.add_child(_split)
	var fill := Button.new()
	fill.text = "  " + Loc.t("Fill the rest for me") + "  "
	fill.custom_minimum_size = Vector2(0, 58)
	fill.add_theme_font_size_override("font_size", 21)
	fill.pressed.connect(_fill)
	foot.add_child(fill)
	var clear := Button.new()
	clear.text = "  " + Loc.t("Take everything out") + "  "
	clear.custom_minimum_size = Vector2(0, 58)
	clear.add_theme_font_size_override("font_size", 21)
	clear.pressed.connect(func():
		_in.clear()
		_refresh())
	foot.add_child(clear)
	_go = Button.new()
	_go.custom_minimum_size = Vector2(360, 64)
	_go.add_theme_font_size_override("font_size", 25)
	_go.pressed.connect(_done)
	foot.add_child(_go)
	_refresh()
	if not sorted.is_empty():
		_look(int(sorted[0]))
		(_tiles[int(sorted[0])] as Control).grab_focus.call_deferred()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


## Where a card sits on the desk: monsters (strongest first), then Spells, then Traps.
func _rank(id: int) -> float:
	var c := CardData.get_card(id)
	match str(c.get("kind", "monster")):
		"spell":
			return 20000.0 + float(id % 9973) * 0.0001
		"trap":
			return 30000.0 + float(id % 9973) * 0.0001
	return 10000.0 - float(int(c.get("atk", 0))) - float(int(c.get("level", 0))) * 0.01


func _tile(id: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.clip_contents = true
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, flat)
	var face := TextureRect.new()
	face.name = "Face"
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.texture = Cards.get_face(id)
	b.add_child(face)
	# A card with no picture on this computer still says what it is.
	if face.texture == null:
		var nm := UITheme.label(str(CardData.get_card(id).get("name", "?")), 13, Color.WHITE)
		nm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
	var mark := Panel.new()
	mark.name = "Mark"
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = UITheme.GOLD
	box.set_border_width_all(4)
	box.set_corner_radius_all(6)
	mark.add_theme_stylebox_override("panel", box)
	b.add_child(mark)
	b.pressed.connect(func(): _toggle(id))
	b.mouse_entered.connect(func(): _look(id))
	b.focus_entered.connect(func(): _look(id))
	return b


func _toggle(id: int) -> void:
	if _in.has(id):
		_in.erase(id)
		Sfx.play("card", -10.0, 0.9)
	elif _in.size() < CampusClasses.DECK_SIZE:
		_in[id] = true
		Sfx.play("card", -8.0)
	else:
		Sfx.play("error", -10.0)
	_refresh()


func _fill() -> void:
	var have: Array = []
	for id in pool:
		if _in.has(int(id)):
			have.append(int(id))
	_in.clear()
	for id in CampusClasses.pick(pool, have):
		_in[int(id)] = true
	Sfx.play("sparkle", -10.0)
	_refresh()


func _look(id: int) -> void:
	if id == _shown:
		return
	_shown = id
	var c := CardData.get_card(id)
	_big.texture = Cards.get_face(id, true)
	if _big.texture == null:
		_big.texture = Cards.get_face(id)
	_name.text = str(c.get("name", ""))
	if str(c.get("kind", "monster")) == "monster":
		_stat.text = "%s %d   ·   ATK %d   ·   DEF %d" % [Loc.t("Level"), int(c.get("level", 0)), int(c.get("atk", 0)), int(c.get("def", 0))]
	else:
		_stat.text = Loc.t("Spell Card") if str(c.get("kind", "")) == "spell" else Loc.t("Trap Card")
	var txt := str(c.get("desc", c.get("text", "")))
	if txt == "":
		txt = str(CardData.EXT.get(id, {}).get("desc", ""))
	_text.text = CardText.shown(str(c.get("name", "")), txt)


func _refresh() -> void:
	var m := 0
	var s := 0
	var t := 0
	for id in pool:
		var on := _in.has(int(id))
		var tile: Button = _tiles[int(id)]
		(tile.get_node("Face") as Control).modulate = Color.WHITE if on else Color(0.42, 0.42, 0.48)
		(tile.get_node("Mark") as Control).visible = on
		if on:
			match str(CardData.get_card(int(id)).get("kind", "monster")):
				"spell":
					s += 1
				"trap":
					t += 1
				_:
					m += 1
	var n := _in.size()
	_count.text = "%d / %d" % [n, CampusClasses.DECK_SIZE]
	_split.text = "%s %d   ·   %s %d   ·   %s %d" % [Loc.t("Monsters"), m, Loc.t("Spells"), s, Loc.t("Traps"), t]
	_go.disabled = n != CampusClasses.DECK_SIZE
	_go.text = Loc.t("Duel with these forty") if n == CampusClasses.DECK_SIZE else Loc.t("%d more to choose") % (CampusClasses.DECK_SIZE - n)


func _done() -> void:
	var deck: Array = []
	for id in pool:
		if _in.has(int(id)):
			deck.append(int(id))
	Sfx.play("sparkle", -8.0)
	closed.emit(deck)
