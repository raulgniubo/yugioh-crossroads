class_name SideSwap
extends Control
## Between the duels of a Match: swap cards between your Main Deck and Side Deck. The Main
## Deck must end with the same number of cards it started with.

signal done

var _main_grid: GridContainer
var _side_grid: GridContainer
var _info: Label
var _go: Button
var _need := 40


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_need = Collection.main.size()
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.02, 0.045, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 44)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	m.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	root.add_child(head)
	head.add_child(UITheme.label("SIDE DECK", 54, Color.WHITE, UITheme.title_font()))
	_info = UITheme.label("", 22, UITheme.TEXT_DIM)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_info)
	_go = Button.new()
	_go.text = "  Next duel  "
	_go.add_theme_font_size_override("font_size", 26)
	_go.pressed.connect(func():
		Collection.save()
		done.emit()
		queue_free())
	head.add_child(_go)
	var hint := UITheme.label("Click a card to move it between your Main Deck and your Side Deck. Changes last until the Match ends.", 18, UITheme.TEXT_DIM)
	root.add_child(hint)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	_main_grid = _column(body, "MAIN DECK", 11, 2.4)
	_side_grid = _column(body, "SIDE DECK", 4, 1.0)
	_rebuild()


func _column(parent: Control, title: String, cols: int, ratio: float) -> GridContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = ratio
	parent.add_child(v)
	v.add_child(UITheme.label(title, 18, UITheme.ACCENT, UITheme.semi_font()))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	sc.add_child(g)
	return g


func _rebuild() -> void:
	for pair in [[_main_grid, Collection.main, true], [_side_grid, Collection.side, false]]:
		var g: GridContainer = pair[0]
		for c in g.get_children():
			c.queue_free()
		var ids: Array = (pair[1] as Array).duplicate()
		ids.sort_custom(func(a, b):
			var da := CardData.get_card(a)
			var db := CardData.get_card(b)
			if da["kind"] != db["kind"]:
				return str(da["kind"]) < str(db["kind"])
			return str(da.get("name", "")) < str(db.get("name", "")))
		for id in ids:
			var tr := TextureRect.new()
			tr.texture = Cards.get_face(id)
			tr.custom_minimum_size = Vector2(104, 152)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			tr.tooltip_text = str(CardData.get_card(id).get("name", ""))
			var from_main: bool = pair[2]
			tr.gui_input.connect(func(e):
				if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
					if from_main:
						Collection.main.erase(id)
						Collection.side.append(id)
					else:
						Collection.side.erase(id)
						Collection.main.append(id)
					Sfx.play("card", -5.0)
					_rebuild())
			g.add_child(tr)
	var n := Collection.main.size()
	_info.text = Loc.t("Main Deck %d of %d     Side Deck %d") % [n, _need, Collection.side.size()]
	_info.add_theme_color_override("font_color", UITheme.TEXT_DIM if n == _need else UITheme.DANGER)
	_go.disabled = n != _need
