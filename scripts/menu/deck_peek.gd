class_name DeckPeek
extends Control
## "See their deck": every card a duelist plays, Main Deck and Extra Deck, laid out before you
## pick them. Point at a card (or move to it) to read it on the right.

signal closed

var _deck := ""
var _who := ""
var _face: TextureRect
var _name: Label
var _text: RichTextLabel
var _first: Button


func _init(who_key: String, deck_key: String) -> void:
	_who = who_key
	_deck = deck_key


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.06, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(dim)
	var info := Characters.get_char(_who)
	var col: Color = Portraits.info(_who).get("color", UITheme.ACCENT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.05, 0.075, 0.15, 0.98), 22, Color(col, 0.6)))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_right = -70
	panel.offset_top = 50
	panel.offset_bottom = -50
	add_child(panel)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(m)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 26)
	m.add_child(cols)
	# Left: the deck.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)
	var head := HBoxContainer.new()
	left.add_child(head)
	var title := UITheme.label(Loc.t("%s'S DECK") % str(info.get("short", info.get("name", _who))).to_upper(), 42, Color.WHITE, UITheme.title_font())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_b := Button.new()
	close_b.text = "Close"
	close_b.pressed.connect(close)
	head.add_child(close_b)
	var main: Array[int] = CardData.deck_list(_deck)
	var extra: Array = CardData.extra_list(_deck)
	var mons := 0
	var spells := 0
	var traps := 0
	for id in main:
		match str(CardData.get_card(id).get("kind", "")):
			"spell":
				spells += 1
			"trap":
				traps += 1
			_:
				mons += 1
	left.add_child(UITheme.label(Loc.t("%s Deck   ·   %d cards: %d monsters, %d Spells, %d Traps   ·   %d in the Extra Deck") % [
		CardData.deck_name(_deck), main.size(), mons, spells, traps, extra.size()], 18, col.lightened(0.4), UITheme.semi_font()))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	_group(body, Loc.t("MAIN DECK"), _sorted(main))
	if not extra.is_empty():
		_group(body, Loc.t("EXTRA DECK"), _sorted(extra))
	# Right: the card you are looking at.
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(430, 0)
	right.add_theme_constant_override("separation", 10)
	cols.add_child(right)
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.custom_minimum_size = Vector2(430, 500)
	right.add_child(_face)
	_name = UITheme.label("", 28, Color.WHITE, UITheme.title_font())
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_name)
	_text = RichTextLabel.new()
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_color_override("default_color", UITheme.TEXT)
	right.add_child(_text)
	if _first:
		_first.grab_focus.call_deferred()
		_first.focus_entered.emit()


## Monsters first (highest Level, then ATK), then Spells, then Traps; one entry per card with
## how many copies. Returns [[id, copies], ...].
func _sorted(list: Array) -> Array:
	var counts := {}
	var order: Array = []
	for id in list:
		if not counts.has(int(id)):
			order.append(int(id))
		counts[int(id)] = int(counts.get(int(id), 0)) + 1
	var rank := func(id: int) -> int:
		var d := CardData.get_card(id)
		var kind := str(d.get("kind", "monster"))
		if kind == "spell":
			return -100000
		if kind == "trap":
			return -200000
		return int(d.get("level", 0)) * 6000 + int(d.get("atk", 0))
	order.sort_custom(func(a, b): return rank.call(a) > rank.call(b))
	var out: Array = []
	for id in order:
		out.append([id, counts[id]])
	return out


func _group(body: VBoxContainer, title: String, cards: Array) -> void:
	body.add_child(UITheme.label(title, 18, UITheme.GOLD, UITheme.semi_font()))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	body.add_child(flow)
	for e in cards:
		var id: int = e[0]
		var b := Button.new()
		b.custom_minimum_size = Vector2(104, 152)
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(id)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tr)
		if int(e[1]) > 1:
			var n := UITheme.label("x%d" % int(e[1]), 20, Color.WHITE, UITheme.title_font())
			n.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			n.add_theme_constant_override("outline_size", 8)
			n.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			n.offset_left = -40
			n.offset_top = -30
			n.offset_right = -6
			n.offset_bottom = -4
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(n)
		b.mouse_entered.connect(func(): _show(id))
		b.focus_entered.connect(func(): _show(id))
		b.pressed.connect(func(): _show(id))
		flow.add_child(b)
		if _first == null:
			_first = b


func _show(id: int) -> void:
	var d := CardData.get_card(id)
	_face.texture = Cards.get_face(id)
	_name.text = str(d.get("name", ""))
	var lines := []
	if str(d.get("kind", "")) == "monster":
		lines.append(Loc.t("Level %d  ·  %s  ·  %s") % [int(d.get("level", 0)), d.get("attribute", ""), d.get("race", "")])
		lines.append(Loc.t("ATK %d   DEF %d") % [int(d.get("atk", 0)), int(d.get("def", 0))])
	else:
		lines.append(Loc.t("Spell Card") if str(d.get("kind", "")) == "spell" else Loc.t("Trap Card"))
	lines.append(str(d.get("desc", d.get("text", ""))))
	_text.text = "\n\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
