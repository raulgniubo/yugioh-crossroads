class_name StarterPick
extends Control
## Your first deck: three to choose from, the same strength, three ways to play. Shown once,
## the first time you reach the main menu (and once to anybody who was already playing before
## the choice existed: they keep the deck they have and get one of these on top).

signal closed

var _picked := ""
var _cards := {}          # key -> its panel
var _take: Button
var _note: Label
var _fresh := true


func _ready() -> void:
	_fresh = Collection.is_new()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)
	var title := UITheme.label("CHOOSE YOUR FIRST DECK" if _fresh else "A STARTER DECK FOR YOU", 58, Color.WHITE, UITheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UITheme.label("All three are the same strength. Lumen, your partner, is in every one. You can build and buy other decks later." if _fresh
			else "New: three starter decks. Pick one and it is added to My Decks, free. The deck you play now stays as it is.", 20, UITheme.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for st in Collection.STARTERS:
		row.add_child(_deck_card(st))
	_note = UITheme.label("", 19, UITheme.GOLD, UITheme.semi_font())
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_note)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(foot)
	_take = Button.new()
	_take.text = "  Pick a deck  "
	_take.disabled = true
	_take.add_theme_font_size_override("font_size", 30)
	_take.custom_minimum_size = Vector2(420, 68)
	_take.pressed.connect(_confirm)
	foot.add_child(_take)
	for a in OS.get_cmdline_user_args():
		# --starter-take=<key> (testing): choose it and say what the collection looks like after.
		if a.begins_with("--starter-take="):
			var tk := a.substr(15)
			get_tree().create_timer(0.6).timeout.connect(func():
				print("STARTER before: new ", Collection.is_new(), " active ", Collection.active_deck(), " decks ", Collection.decks_owned)
				_pick(tk)
				_confirm()
				print("STARTER after: pick ", Collection.starter_pick, " active ", Collection.active_deck(), " decks ", Collection.decks_owned,
						" cards ", CardData.deck_list(Collection.active_deck()).size(), " cfg ", Router.duel_config.get("player_deck", "?")))
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	((_cards[Collection.STARTERS[0]["key"]] as Control).get_meta("button") as Button).grab_focus.call_deferred()


func _deck_card(st: Dictionary) -> Control:
	var key := str(st["key"])
	var col: Color = st["color"]
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(500, 640)
	pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.05, 0.08, 0.15, 0.98), 22, Color(col, 0.35)))
	_cards[key] = pc
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var style := UITheme.label(Loc.t(str(st["style"])), 18, col.lightened(0.25), UITheme.semi_font())
	v.add_child(style)
	v.add_child(UITheme.label(Loc.t(CardData.deck_name(key)).to_upper(), 44, Color.WHITE, UITheme.title_font()))
	# Three cards that say what the deck is about, fanned, from your own card folder.
	var fan := Control.new()
	fan.custom_minimum_size = Vector2(460, 250)
	fan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fan)
	var shown: Array = st["show"]
	for i in shown.size():
		var id: int = CardData.NAME_TO_ID.get(str(shown[i]).to_lower(), 0)
		if id == 0:
			continue
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(id)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = Vector2(160, 234)
		tr.pivot_offset = Vector2(80, 234)
		tr.position = Vector2(150 + (i - 1) * 118, 12 + absi(i - 1) * 10)
		tr.rotation = (i - 1) * 0.12
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.z_index = 1 if i == 1 else 0
		fan.add_child(tr)
	var blurb := UITheme.label(str(st["blurb"]), 19, UITheme.TEXT)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(460, 0)
	v.add_child(blurb)
	for pt in st["points"]:
		var line := UITheme.label("•  " + Loc.t(str(pt)), 17, UITheme.TEXT_DIM)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(460, 0)
		v.add_child(line)
	# What is in it, counted from the deck itself.
	var mons := 0
	var spells := 0
	var traps := 0
	for id in CardData.deck_list(key):
		match str(CardData.get_card(id).get("kind", "monster")):
			"spell":
				spells += 1
			"trap":
				traps += 1
			_:
				mons += 1
	var count := UITheme.label(Loc.t("%d monsters   %d Spells   %d Traps") % [mons, spells, traps], 16, col.lightened(0.35), UITheme.semi_font())
	v.add_child(count)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var b := Button.new()
	b.text = "This one"
	b.toggle_mode = true
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_stylebox_override("pressed", UITheme.button_box(col, col))
	b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(col, col))
	b.add_theme_color_override("font_pressed_color", Color(0.03, 0.04, 0.07))
	b.add_theme_color_override("font_hover_pressed_color", Color(0.03, 0.04, 0.07))
	b.pressed.connect(func(): _pick(key))
	v.add_child(b)
	pc.set_meta("button", b)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_pick(key))
	return pc


func _pick(key: String) -> void:
	_picked = key
	Sfx.play("card", -8.0)
	for k in _cards:
		var pc: PanelContainer = _cards[k]
		var st := Collection.starter_info(str(k))
		var on: bool = k == key
		pc.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.07, 0.11, 0.2, 0.99) if on else Color(0.05, 0.08, 0.15, 0.98), 22,
				Color(st["color"], 1.0 if on else 0.3)))
		(pc.get_meta("button") as Button).set_pressed_no_signal(on)
		pc.pivot_offset = pc.size / 2.0
		create_tween().tween_property(pc, "scale", Vector2.ONE * (1.03 if on else 0.97), 0.16)
		pc.modulate = Color.WHITE if on else Color(0.72, 0.72, 0.78)
	_take.disabled = false
	_take.text = Loc.t("  Take %s  ") % Loc.t(CardData.deck_name(key))
	_note.text = Loc.t("%s: 40 cards. It goes into My Decks. This choice is made once.") % Loc.t(CardData.deck_name(key))


func _confirm() -> void:
	if _picked == "":
		return
	var now_active := Collection.take_starter(_picked)
	Sfx.play("quest", -4.0)
	var name := Loc.t(CardData.deck_name(_picked))
	Router.toast((Loc.t("%s is your deck. Good luck out there.") if now_active else Loc.t("%s was added to My Decks.")) % name, 5.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		closed.emit()
		queue_free())
