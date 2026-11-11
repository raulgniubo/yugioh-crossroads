class_name CharacterSelect
extends Control
## Free Duel opponent select: a row of duelist cards, a big preview and deck choice.

signal start(opponent: String, deck: String, difficulty: int)
signal closed

var _selected := ""
var _cards := {}
var _preview: TextureRect
var _name: Label
var _title: Label
var _era: Label
var _deck_info: Label
var _ace: TextureRect
var _deck_pick: OptionButton
var _deck_keys: Array = []
var _difficulty := 1
var _diff_btns: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# Big preview on the right
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.anchor_left = 0.56
	_preview.anchor_right = 1.0
	_preview.anchor_bottom = 1.0
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_preview)
	var fade := TextureRect.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.01, 0.02, 0.04, 1), Color(0.01, 0.02, 0.04, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 64
	gt.height = 4
	fade.texture = gt
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.anchor_left = 0.56
	fade.anchor_right = 0.75
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	# Header
	var header := UITheme.label("CHOOSE YOUR OPPONENT", 64, Color.WHITE, UITheme.title_font())
	header.position = Vector2(100, 70)
	add_child(header)
	var sub := UITheme.label("Free Duel  ·  More duelists join as the story goes on", 22, UITheme.TEXT_DIM)
	sub.position = Vector2(104, 150)
	add_child(sub)
	# Character cards
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.position = Vector2(100, 220)
	add_child(grid)
	for key in Characters.ORDER:
		grid.add_child(_char_card(key))
	# Info block
	var info := VBoxContainer.new()
	info.position = Vector2(100, 880)
	info.add_theme_constant_override("separation", 4)
	add_child(info)
	_name = UITheme.label("", 54, Color.WHITE, UITheme.title_font())
	info.add_child(_name)
	_title = UITheme.label("", 22, UITheme.TEXT_DIM)
	info.add_child(_title)
	_era = UITheme.label("", 18, UITheme.ACCENT, UITheme.semi_font())
	_era.position = Vector2(104, 860)
	add_child(_era)
	# Right-bottom controls
	var controls := PanelContainer.new()
	controls.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.9), 20, Color(UITheme.ACCENT, 0.3)))
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_left = -620
	controls.offset_right = -60
	controls.offset_top = -400
	controls.offset_bottom = -60
	add_child(controls)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	controls.add_child(h)
	_ace = TextureRect.new()
	_ace.custom_minimum_size = Vector2(140, 204)
	_ace.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ace.stretch_mode = TextureRect.STRETCH_SCALE
	h.add_child(_ace)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	_deck_info = UITheme.label("", 20, UITheme.TEXT)
	_deck_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_deck_info)
	v.add_child(UITheme.label("YOUR DECK", 16, UITheme.ACCENT, UITheme.semi_font()))
	_deck_pick = OptionButton.new()
	for key in CardData.DECKS:
		_deck_keys.append(key)
		var owner: Dictionary = Characters.get_char(key)
		_deck_pick.add_item("%s  (%s)" % [CardData.DECKS[key]["name"], owner.get("short", key)])
	v.add_child(_deck_pick)
	v.add_child(UITheme.label("DIFFICULTY", 16, UITheme.ACCENT, UITheme.semi_font()))
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	v.add_child(drow)
	_difficulty = int(Router.duel_config.get("difficulty", 1))
	for i in 3:
		var db := Button.new()
		db.text = ["Easy", "Normal", "Hard"][i]
		db.toggle_mode = true
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		db.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		db.pressed.connect(func():
			_difficulty = i
			for j in _diff_btns.size():
				_diff_btns[j].set_pressed_no_signal(j == i))
		db.set_pressed_no_signal(i == _difficulty)
		drow.add_child(db)
		_diff_btns.append(db)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(close)
	row.add_child(back)
	var go := Button.new()
	go.text = "DUEL!"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.add_theme_font_size_override("font_size", 30)
	go.pressed.connect(func(): start.emit(_selected, _deck_keys[_deck_pick.selected], _difficulty))
	row.add_child(go)
	var last_opp: String = Router.duel_config.get("opponent", "kaiba")
	_select(last_opp)
	_deck_pick.select(maxi(0, _deck_keys.find(Router.duel_config.get("player_deck", "yugi"))))
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	await get_tree().process_frame
	go.grab_focus()


func _char_card(key: String) -> Control:
	var d := Characters.get_char(key)
	var b := Button.new()
	b.custom_minimum_size = Vector2(250, 200)
	b.flat = true
	b.clip_contents = true
	var sb := UITheme.button_box(Color(0.05, 0.08, 0.13, 0.9), Color(1, 1, 1, 0.08), 16)
	sb.set_content_margin_all(0)
	for st in ["normal", "hover", "pressed", "focus"]:
		var x: StyleBoxFlat = sb.duplicate()
		if st != "normal":
			x.border_color = d["color"]
			x.set_border_width_all(3)
		b.add_theme_stylebox_override(st, x)
	var pt := TextureRect.new()
	pt.texture = Portraits.get_portrait(key)
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pt)
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.6)
	band.anchor_top = 1.0
	band.anchor_right = 1.0
	band.anchor_bottom = 1.0
	band.offset_top = -46
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(band)
	var n := UITheme.label(str(d["short"]).to_upper(), 30, Color.WHITE, UITheme.title_font())
	n.position = Vector2(14, 6)
	band.add_child(n)
	var e := UITheme.label(str(d["era"]).to_upper(), 15, Color(d["color"]).lightened(0.3), UITheme.semi_font())
	e.anchor_left = 1.0
	e.anchor_right = 1.0
	e.offset_left = -130
	e.offset_right = -12
	e.offset_top = 14
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	band.add_child(e)
	b.pressed.connect(func(): _select(key))
	b.focus_entered.connect(func(): _select(key))
	_cards[key] = b
	return b


func _select(key: String) -> void:
	if key == _selected:
		return
	_selected = key
	var d := Characters.get_char(key)
	_preview.texture = Portraits.get_portrait(key)
	_preview.modulate.a = 0.0
	create_tween().tween_property(_preview, "modulate:a", 1.0, 0.25)
	_name.text = str(d["name"]).to_upper()
	_title.text = d["title"]
	_era.text = str(d["era"]).to_upper()
	var deck: Dictionary = CardData.DECKS[d["deck"]]
	_deck_info.text = "%s plays the %s Deck\n30 cards  ·  %d in the Extra Deck  ·  %s" % [d["short"], deck["name"],
			CardData.extra_list(d["deck"]).size(), FieldThemes.resolve("auto", key)["name"]]
	_ace.texture = Cards.get_face(d["ace"])
	for k in _cards:
		(_cards[k] as Button).modulate = Color.WHITE if k == key else Color(0.7, 0.72, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
