class_name LegendsGate
extends Control
## Legendary Duels (0.75.0): the famous matchups of the shows, era by era. Each one is played with
## the decks of that moment, from either side, with a short scene before and after (written for
## this game). Three stars a side; winning a side for the first time puts its deck on your shelf,
## so it can be taken to Free Duel and online.

signal closed

const ERA_COLORS := {"dm": Color("ffd166"), "gx": Color("e0533f"), "5ds": Color("3fc6ff"), "zexal": Color("ff6ad8")}

var _back: AcademyBackdrop
var _body: VBoxContainer
var _era := "dm"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_back = AcademyBackdrop.new(0.45, "res://assets/ui/academy_title.jpg")
	add_child(_back)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_theme_constant_override("margin_left", 96)
	m.add_theme_constant_override("margin_right", 96)
	m.add_theme_constant_override("margin_top", 52)
	m.add_theme_constant_override("margin_bottom", 40)
	sc.add_child(m)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 16)
	m.add_child(_body)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	if "--legend-test=after" in OS.get_cmdline_user_args():
		Router.legend_pending = {"id": str(LegendData.LEGENDS[_test_n()]["id"]), "side": 0}
		Router.story_result = "won"
		Router.last_stats = {"won": true, "turns": 6, "field": ["Elemental HERO Flame Wingman"]}
	var pend: Dictionary = Router.legend_pending
	if not pend.is_empty() and Router.story_result != "":
		# Back from a Legendary Duel: its closing scene, then what it earned.
		Router.legend_pending = {}
		var won := Router.story_result == "won"
		Router.story_result = ""
		_after(str(pend["id"]), int(pend["side"]), won)
		return
	Router.legend_pending = {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--legend-era="):
			_era = a.get_slice("=", 1)
	_page()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--legend-test"):
			# Dev: the decks as they resolve here, and (=play) straight into side 0 of the first one.
			for l in LegendData.LEGENDS:
				for sd in l["sides"]:
					print("LEGEND deck %s: %d main, %d extra" % [sd["deck"], CardData.deck_list(str(sd["deck"])).size(), CardData.extra_list(str(sd["deck"])).size()])
			if a == "--legend-test=play":
				_start(LegendData.LEGENDS[_test_n()], 0)
			elif a == "--legend-test=scene":
				var l0: Dictionary = LegendData.LEGENDS[_test_n()]
				add_child(LegendScene.new(l0["before"], str(l0["sides"][0]["key"]), str(l0["sides"][1]["key"]), str(l0["picture"]), true))


## Dev: which matchup the --legend-test runs use (--legend-n=index into LEGENDS, default 0).
static func _test_n() -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--legend-n="):
			return clampi(int(a.get_slice("=", 1)), 0, LegendData.LEGENDS.size() - 1)
	return 0


func _clear() -> void:
	for c in _body.get_children():
		c.queue_free()


func _page() -> void:
	_clear()
	_body.add_child(UITheme.label(Loc.t("THE SHOWS' FAMOUS DUELS"), 19, UITheme.GOLD, UITheme.semi_font()))
	var t := UITheme.label(Loc.t("LEGENDARY DUELS"), 92, Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 5)
	_body.add_child(t)
	var sub := UITheme.label(Loc.t("Famous matchups, played with the decks the duelists had at that moment. Pick a side. A short scene before and after each one, written for this game."), 21, Color(0.9, 0.94, 1.0, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(900, 0)
	_body.add_child(sub)
	# The eras.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	_body.add_child(tabs)
	for e in LegendData.ERAS:
		var key := str(e[0])
		var b := Button.new()
		var n := LegendData.in_era(key).size()
		b.text = "  %s  " % Loc.t(str(e[1])) + ("" if n > 0 else "  ·  " + Loc.t("soon"))
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 21)
		var col: Color = ERA_COLORS.get(key, UITheme.GOLD)
		b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.85 if key == _era else 0.6), 12, Color(col, 0.9 if key == _era else 0.25)))
		b.add_theme_stylebox_override("hover", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 12, col))
		b.add_theme_color_override("font_color", col.lightened(0.3) if key == _era else Color(0.8, 0.84, 0.92, 0.8 if n > 0 else 0.45))
		b.pressed.connect(func():
			Sfx.play("click", -6.0)
			_era = key
			_page())
		tabs.add_child(b)
	var list := LegendData.in_era(_era)
	if list.is_empty():
		var soon := UITheme.label(Loc.t("The duels of this era are on their way. GX is first: tell us how it plays."), 22, UITheme.TEXT_DIM)
		soon.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(soon)
	for l in list:
		_body.add_child(_matchup(l))
	var back := Button.new()
	back.text = Loc.t("Back")
	back.custom_minimum_size = Vector2(220, 54)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.add_theme_font_size_override("font_size", 21)
	back.pressed.connect(_close)
	_body.add_child(back)


## One matchup: the two sides, each with its duelist, its deck of the time, its three stars and
## a button to play it.
func _matchup(l: Dictionary) -> Control:
	var id := str(l["id"])
	var col: Color = ERA_COLORS.get(str(l["era"]), UITheme.GOLD)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.045, 0.11, 0.88), 22, Color(col, 0.7)))
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 22)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	v.add_child(head)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(UITheme.label(Loc.t(str(l["title"])).to_upper(), 46, Color.WHITE, UITheme.title_font()))
	hv.add_child(UITheme.label(Loc.t(str(l["when"])), 21, col.lightened(0.35), UITheme.semi_font()))
	head.add_child(UITheme.label("★ %d / 6" % LegendData.star_count(id), 26, UITheme.GOLD, UITheme.title_font()))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	v.add_child(row)
	for side in 2:
		row.add_child(_side(l, side, col))
	if LegendData.seen(id):
		var again := Button.new()
		again.text = Loc.t("Watch the opening scene again")
		again.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		again.custom_minimum_size = Vector2(0, 44)
		again.pressed.connect(func():
			var sc := LegendScene.new(l["before"], str(l["sides"][0]["key"]), str(l["sides"][1]["key"]), str(l["picture"]), true)
			add_child(sc))
		v.add_child(again)
	return card


func _side(l: Dictionary, side: int, col: Color) -> Control:
	var s: Dictionary = l["sides"][side]
	var key := str(s["key"])
	var who := str(Characters.get_char(key).get("name", key))
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(1, 1, 1, 0.04), 16, Color(1, 1, 1, 0.1)))
	var m := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 14)
	p.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	m.add_child(h)
	var face := TextureRect.new()
	face.texture = Portraits.get_portrait(key)
	face.custom_minimum_size = Vector2(130, 160)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(face)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UITheme.label(who, 28, Color.WHITE, UITheme.title_font()))
	v.add_child(UITheme.label(Loc.t("Deck: %s") % Loc.t(CardData.deck_name(str(s["deck"]))), 17, UITheme.TEXT_DIM))
	var got := LegendData.stars(str(l["id"]), side)
	var st: Array = s["stars"]
	for i in st.size():
		var line := UITheme.label(("★  " if got[i] else "☆  ") + LegendData.star_text(st[i]), 17, UITheme.GOLD if got[i] else Color(0.82, 0.86, 0.94, 0.85))
		v.add_child(line)
	var play := Button.new()
	play.text = Loc.t("Play as %s") % who
	play.custom_minimum_size = Vector2(0, 50)
	play.add_theme_font_size_override("font_size", 20)
	play.add_theme_stylebox_override("normal", UITheme.panel_box(Color(col.darkened(0.55), 0.95), 12, col))
	play.add_theme_stylebox_override("hover", UITheme.panel_box(Color(col.darkened(0.35), 0.98), 12, col.lightened(0.3)))
	play.pressed.connect(func():
		Sfx.play("click", -6.0)
		_start(l, side))
	v.add_child(play)
	return p


## The opening scene, then the duel.
func _start(l: Dictionary, side: int) -> void:
	var sc := LegendScene.new(l["before"], str(l["sides"][0]["key"]), str(l["sides"][1]["key"]), str(l["picture"]), true)
	add_child(sc)
	await sc.finished
	LegendData.mark_seen(str(l["id"]))
	var me: Dictionary = l["sides"][side]
	var them: Dictionary = l["sides"][1 - side]
	Router.legend_pending = {"id": str(l["id"]), "side": side}
	Router.menu_open = "legends"
	Router.match_state = {}
	Router.duel_config = {
		"opponent": str(them["key"]), "opponent_deck": str(them["deck"]),
		"player_char": str(me["key"]), "player_deck": str(me["deck"]),
		"difficulty": Settings.cpu_level, "field": str(l.get("field", "auto")),
		"story": true, "lose_ok": true, "return_to": Router.MAIN_MENU, "continue_label": Loc.t("Continue"),
	}
	Router.go(Router.DUEL)


## Back from the duel: the closing scene for who won, then the stars and what they unlock.
func _after(id: String, side: int, won: bool) -> void:
	var l := LegendData.by_id(id)
	if l.is_empty():
		_page()
		return
	var winner := side if won else 1 - side
	var sc := LegendScene.new(l["after"][winner], str(l["sides"][0]["key"]), str(l["sides"][1]["key"]), str(l["picture"]))
	add_child(sc)
	await sc.finished
	var new_stars := LegendData.award(id, side, Router.last_stats)
	var words: Array = []
	for i in new_stars:
		words.append("★ " + LegendData.star_text(l["sides"][side]["stars"][i]))
	if won:
		var deck := str(l["sides"][side]["deck"])
		if not Collection.decks_owned.has(deck):
			Collection.decks_owned.append(deck)
			Collection.save()
			words.append(Loc.t("New deck on your shelf: %s (Free Duel and online)") % Loc.t(CardData.deck_name(deck)))
	if not words.is_empty():
		Sfx.play("quest", -3.0)
		Router.toast("\n".join(words), 6.0)
	_page()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
