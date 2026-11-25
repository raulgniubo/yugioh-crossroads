class_name ChallengeCard
extends CanvasLayer
## Somebody in your Duel Group challenges you (0.73.0): their duelist, what they ask for (one duel or
## a Match of 3, the Forbidden/Limited list on or off, Life Points, Destiny Draw), your deck, and
## Accept or Decline. It shows over any menu; it goes away by itself after a minute, and when they
## call it off.

const TEAL := Color("2de2e6")
const WAIT := 60.0

var ch := {}
var _panel: PanelContainer
var _left: Label
var _deck: OptionButton
var _t := WAIT
var _gone := false


static func show_for(msg: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for n in tree.root.get_children():
		if n is ChallengeCard:
			# (one at a time: a second challenge waits for the first to be answered)
			if not (n as ChallengeCard)._gone:
				Net.decline(str(msg.get("cid", "")), "busy")
				return
	var c := ChallengeCard.new()
	c.ch = msg
	tree.root.add_child(c)


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	Net.answered.connect(func(a):
		if a.get("cancelled", false) and str(a.get("cid", "")) == str(ch.get("cid", "")):
			_close())
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UITheme.build()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.06, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.98), 24, Color(TEAL, 0.85)))
	_panel.custom_minimum_size = Vector2(900, 0)
	cc.add_child(_panel)
	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 28)
	_panel.add_child(mm)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 26)
	mm.add_child(h)
	var key := "net:" + str(ch.get("from", ""))
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(250, 300)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture = Portraits.get_portrait(key, true)
	h.add_child(face)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var p := Net.person(str(ch.get("from", "")))
	var name := str(p.get("name", Loc.t("Someone")))
	v.add_child(UITheme.label(Loc.t("%s CHALLENGES YOU!") % name.to_upper(), 36, TEAL, UITheme.title_font()))
	if str(p.get("title", "")) != "":
		v.add_child(UITheme.label(str(p["title"]), 17, UITheme.GOLD))
	var mode := Loc.t("A Match of 3 (Side Deck between duels)") if str(ch.get("mode", "single")) == "match" else Loc.t("One duel")
	var lines := [mode, Loc.t("%d Life Points") % int(ch.get("lp", 8000)),
		Loc.t("Destiny Draw: on") if bool(ch.get("destiny", false)) else Loc.t("Destiny Draw: off"),
		Loc.t("Their deck: %s") % str(ch.get("deck_name", ""))]
	var anime := bool(ch.get("anime", false))
	if anime:
		lines.append(Loc.t("Anime decks only: you play as a duelist from the shows, with one of their anime decks"))
	for l in lines:
		v.add_child(UITheme.label("•  " + str(l), 19, UITheme.TEXT))
	var fl := UITheme.label("•  " + (Loc.t("Forbidden/Limited list: on") if bool(ch.get("fl", true)) else Loc.t("Forbidden/Limited list: OFF (any card, 3 copies)")), 19,
			UITheme.TEXT if bool(ch.get("fl", true)) else UITheme.GOLD, null if bool(ch.get("fl", true)) else UITheme.semi_font())
	v.add_child(fl)
	v.add_child(UITheme.label(Loc.t("Your duelist and their anime deck") if anime else Loc.t("Your deck"), 16, UITheme.TEXT_DIM))
	_deck = OptionButton.new()
	_deck.custom_minimum_size = Vector2(0, 46)
	# (anime decks only: [character, deck, name] picks; else your own complete decks)
	var decks := Net.anime_decks() if anime else Net.decks()
	for d in decks:
		_deck.add_item(str(d[2]) if anime else str(d[1]))
	v.add_child(_deck)
	var msg := UITheme.label("", 16, UITheme.DANGER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var ok := Button.new()
	ok.text = "Accept"
	ok.custom_minimum_size = Vector2(0, 58)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.add_theme_font_size_override("font_size", 22)
	ok.add_theme_stylebox_override("normal", UITheme.button_box(Color(TEAL, 0.25), TEAL))
	ok.pressed.connect(func():
		if decks.is_empty():
			return
		var dk := str(decks[_deck.selected][1]) if anime else str(decks[_deck.selected][0])
		var bad := Net.deck_problem(Net.deck_lists(dk), bool(ch.get("fl", true)) and not anime)
		if bad != "":
			msg.text = bad
			return
		_gone = true
		Sfx.play("summon", -6.0)
		Net.accept(str(ch["cid"]), dk, str(decks[_deck.selected][0]) if anime else "")
		_close())
	row.add_child(ok)
	var no := Button.new()
	no.text = "Decline"
	no.custom_minimum_size = Vector2(170, 58)
	no.pressed.connect(func():
		Net.decline(str(ch["cid"]))
		_close())
	row.add_child(no)
	_left = UITheme.label("", 14, UITheme.TEXT_DIM)
	v.add_child(_left)
	if decks.is_empty():
		ok.disabled = true
		msg.text = Loc.t("You have no complete deck to take online yet (40 to 60 cards, every card owned).")
	Sfx.play("draw", -2.0)
	_panel.pivot_offset = Vector2(450, 180)
	_panel.scale = Vector2(0.9, 0.9)
	root.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(root, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not decks.is_empty():
		ok.grab_focus()


func _process(delta: float) -> void:
	if _gone:
		return
	_t -= delta
	_left.text = Loc.t("Goes away in %d s") % maxi(0, int(ceil(_t)))
	if _t <= 0.0:
		Net.decline(str(ch["cid"]), "time")
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	_gone = true
	var tw := create_tween()
	tw.tween_property(get_child(0), "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
