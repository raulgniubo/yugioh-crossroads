class_name DuelHUD
extends Control
## Everything 2D on top of the duel: life points, hand, phase controls,
## card inspector, banners, prompts, action menus and the result screen.

signal hand_card_pressed(inst, at: Vector2)
signal hand_card_hovered(inst)
signal hand_drag(inst, on: bool)
signal phase_button(action: String)
signal action_chosen(action: String)
signal cancel_pressed
signal direct_attack_pressed
signal pause_action(action: String)
signal extra_pressed
signal speed_pressed
signal extra_chosen(inst)
signal _response_picked(choice)

const HAND_CARD := Vector2(150, 218)

var _lp_labels: Array[Label] = [null, null]
var _lp_bars: Array[ColorRect] = [null, null]
var _lp_values := [8000.0, 8000.0]
var _count_labels: Array[Label] = [null, null]
var _hand_root: Control
var _phase_box: Control
var _hand: Array = []  # [{inst, node}]
var _hand_hover := -1
var _playable := {}
var _btn_battle: Button
var _btn_end: Button
var _inspect_panel: PanelContainer
var _inspect_tex: TextureRect
var _inspect_name: Label
var _inspect_stats: Label
var _inspect_text: Label
var _prompt: PanelContainer
var _prompt_label: Label
var _btn_direct: Button
var _btn_cancel: Button
var _menu: VBoxContainer
var _banner: Label
var _float_root: Control
var _overlay: Control
var player_names := ["You", "Opponent"]
var portrait_keys := ["player", "kaiba"]
var _portraits: Array[TextureRect] = [null, null]
var _plates: Array[Control] = [null, null]
var _bubbles: Array[Control] = [null, null]
var _name_labels: Array[Label] = [null, null]
var _btn_extra: Button
var _extra_panel: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Everything in a duel answers on the press, not on the release: taps feel instant.
	get_tree().node_added.connect(_snap_button)
	_build_plates()
	_build_phase()
	_build_inspector()
	_build_hand()
	_build_prompt()
	# Round icon buttons in the corner: duel menu, the card log, the Graveyards.
	var rounds := HBoxContainer.new()
	_menu_btn = rounds
	rounds.add_theme_constant_override("separation", 14)
	rounds.anchor_left = 1.0
	rounds.anchor_right = 1.0
	rounds.anchor_top = 1.0
	rounds.anchor_bottom = 1.0
	rounds.offset_left = -270
	rounds.offset_right = -30
	rounds.offset_top = -100
	rounds.offset_bottom = -28
	rounds.alignment = BoxContainer.ALIGNMENT_END
	add_child(rounds)
	for def in [["piles", "Graveyards and banished cards", Comic.BLUE], ["log", "Card log: everything played this duel", Comic.BLUE], ["gear", "Duel menu", Comic.BLUE]]:
		var rb := RoundButton.new(str(def[0]), def[2])
		rb.tooltip_text = str(def[1])
		rounds.add_child(rb)
		match str(def[0]):
			"gear": rb.pressed.connect(func(): pause_action.emit("open"))
			"log": rb.pressed.connect(show_log)
			"piles": rb.pressed.connect(func(): show_piles(0))
	_float_root = Control.new()
	_float_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_float_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_float_root)
	_menu = VBoxContainer.new()
	_menu.z_index = 50
	_menu.visible = false
	_menu.add_theme_constant_override("separation", 6)
	add_child(_menu)
	_banner = UITheme.label("", 110, Color.WHITE, Comic.shout_font())
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_outline_color", Color(Comic.INK, 0.85))
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_banner.add_theme_constant_override("shadow_offset_x", 0)
	_banner.add_theme_constant_override("shadow_offset_y", 6)
	_banner.add_theme_constant_override("shadow_outline_size", 16)
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)


var _menu_btn: Control


## The frame of the duel screen (Life Point plates, phases, menu, card panel). Off during the
## opening so the picture is clean, back on when the cards are dealt.
func set_chrome(on: bool) -> void:
	for n in [_plates[0], _plates[1], _phase_box, _menu_btn, _inspect_panel, _feed, _coach]:
		if n != null and is_instance_valid(n):
			if on:
				(n as CanvasItem).visible = true if n != _coach or _coach_text != "" else false
				(n as CanvasItem).modulate.a = 0.0 if n != _inspect_panel else (n as CanvasItem).modulate.a
				if n != _inspect_panel:
					create_tween().tween_property(n, "modulate:a", 1.0, 0.4)
			else:
				(n as CanvasItem).visible = false


func _snap_button(n: Node) -> void:
	if n is BaseButton and not (n is OptionButton) and is_ancestor_of(n):
		(n as BaseButton).action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS


# ------------------------------------------------------------------ duelist panels

func _plate(p: int) -> Control:
	var dp := DuelistPanel.new(p)
	if p == 1:
		# Clicking the opponent's panel while aiming an attack is a direct attack too.
		dp.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				direct_attack_pressed.emit())
	_portraits[p] = dp.portrait
	_panels[p] = dp
	dp.name_label.text = player_names[p].to_upper()
	_name_labels[p] = dp.name_label
	_lp_labels[p] = dp.lp_label
	_lp_bars[p] = dp.lp_bar
	dp.counts.tooltip_text = "See the Graveyard and banished cards"
	dp.counts.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			show_piles(p))
	_count_labels[p] = dp.counts
	_fate_labels[p] = dp.fate
	add_child(dp)
	_plates[p] = dp
	var bubble := SpeechBox.new(p)
	bubble.modulate.a = 0.0
	add_child(bubble)
	_bubbles[p] = bubble
	return dp


func _build_plates() -> void:
	var opp := _plate(1)
	opp.anchor_left = 1.0
	opp.anchor_right = 1.0
	opp.offset_left = -DuelistPanel.SIZE.x
	opp.offset_right = 0
	opp.offset_top = 0
	opp.offset_bottom = DuelistPanel.SIZE.y
	var me := _plate(0)
	me.anchor_top = 1.0
	me.anchor_bottom = 1.0
	me.offset_left = 0
	me.offset_right = DuelistPanel.SIZE.x
	me.offset_top = -DuelistPanel.SIZE.y
	me.offset_bottom = 0


func set_names(a: String, b: String) -> void:
	player_names = [a, b]
	for i in 2:
		_name_labels[i].text = player_names[i].to_upper()


func set_portraits(a: String, b: String) -> void:
	portrait_keys = [a, b]
	for i in 2:
		if _panels[i] != null and (_panels[i] as DuelistPanel).live:
			continue
		_portraits[i].texture = Portraits.get_portrait(portrait_keys[i], true)


## The live duelists in the corners (0.63.0): the size the board should draw each one at, and the
## switch from the still picture to the live one.
var _panels := [null, null]

func live_size(p: int) -> Vector2i:
	return (_panels[p] as DuelistPanel).live_size() if _panels[p] != null else Vector2i(380, 380)


func go_live(p: int, tex: Texture2D) -> void:
	if _panels[p] != null and tex != null:
		(_panels[p] as DuelistPanel).go_live(tex)


## Whose turn it is: their panel gets the bright rim and the TURN tab.
func set_turn_side(p: int) -> void:
	for i in 2:
		(_plates[i] as DuelistPanel).set_active(i == p)


## A short line in a speech bubble next to the duelist. Doesn't block.
var ask_why := ""             # shown under the next response prompt, then cleared
var gauntlet_next := false
var gauntlet_label := ""
var speed_fx: SpeedLines   # only in a Turbo Duel
var _cut_at: Array = [0, 0]
var _feed: VBoxContainer
var _coach: PanelContainer
var _coach_label: Label
var _coach_text := ""


signal said(p: int, text: String)      # a duelist's line went up (their figure moves its mouth for it)

func say(p: int, text: String) -> void:
	if text.strip_edges() != "":
		said.emit(p, text)
		# A voice blip so a line is heard as well as read: yours a little higher than theirs.
		Sfx.play("hey", -11.0, 1.15 if p == 0 else 0.82)
	if text == "":
		return
	var b := _bubbles[p] as SpeechBox
	b.set_line(player_names[p], text)
	var vs := get_viewport_rect().size
	if p == 1:
		b.position = Vector2(vs.x - DuelistPanel.SIZE.x - b.size.x + 30, 96)
	else:
		b.position = Vector2(DuelistPanel.SIZE.x - 40, vs.y - DuelistPanel.SIZE.y - 30 - b.size.y)
	b.pivot_offset = Vector2(b.size.x if p == 1 else 0.0, 0.0 if p == 1 else b.size.y)
	b.scale = Vector2(0.8, 0.8)
	b.rotation = 0.0
	if b.has_meta("tw"):
		var old: Tween = b.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	var tw := create_tween()
	b.set_meta("tw", tw)
	tw.set_parallel()
	tw.tween_property(b, "modulate:a", 1.0, 0.08)
	tw.tween_property(b, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(2.6)
	tw.chain().tween_property(b, "modulate:a", 0.0, 0.25)
	# The speaker's portrait gives a little nod as the line pops.
	var pt := _portraits[p]
	var nod := create_tween()
	nod.tween_property(pt, "scale", Vector2(1.06, 1.06), 0.1)
	nod.tween_property(pt, "scale", Vector2.ONE, 0.22)


## Portrait reaction: shake on damage, pulse on big moments.
func react(p: int, kind: String) -> void:
	var pt := _portraits[p]
	var tw := create_tween()
	if kind == "hurt":
		pt.modulate = Color(1.6, 0.6, 0.6)
		var hx := float(pt.get_meta("home_x", 0.0))
		for i in 6:
			tw.tween_property(pt, "position:x", hx + (8.0 if i % 2 == 0 else -8.0), 0.04)
		tw.tween_property(pt, "position:x", hx, 0.04)
		tw.parallel().tween_property(pt, "modulate", Color.WHITE, 0.4)
	else:
		tw.tween_property(pt, "scale", Vector2(1.12, 1.12), 0.15)
		tw.tween_property(pt, "scale", Vector2.ONE, 0.3)


## [graveyard, banished] card lists per player, kept fresh by the scene for the pile viewer.
var piles: Array = [[[], []], [[], []]]
## Cards a player has to keep revealed because of a card effect (their hand, their Set cards).
var revealed: Array = [[], []]
var _pile_panel: Control


var _fate_labels := [null, null]

## The small Destiny Draw mark on a duelist's panel: 0 not in this duel, 1 still unused, 2 spent.
func set_destiny(p: int, code: int) -> void:
	var l: Label = _fate_labels[p]
	if l == null:
		return
	l.visible = code > 0
	l.modulate = Color(1, 1, 1, 1.0) if code == 1 else Color(0.6, 0.62, 0.7, 0.45)
	l.tooltip_text = Loc.t("Destiny Draw: still unused") if code == 1 else Loc.t("Destiny Draw: used")


func set_counts(p: int, deck: int, hand: int, gy: int, banished := 0) -> void:
	var t := Loc.t("Deck %d   ·   Hand %d   ·   GY %d") % [deck, hand, gy]
	if banished > 0:
		t += Loc.t("   ·   Banished %d") % banished
	_count_labels[p].text = t + Loc.t("     ▸ view")


## Every card in a player's Graveyard and banished pile.
func show_piles(p: int) -> void:
	hide_piles()
	_pile_panel = Control.new()
	_pile_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pile_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pile_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			hide_piles())
	_pile_panel.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.078, 0.156, 0.97), 22, Color(UITheme.ACCENT, 0.4)))
	_pile_panel.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var who: String = str(player_names[p]) if player_names.size() > p else ("You" if p == 0 else "Opponent")
	v.add_child(UITheme.label(who.to_upper(), 20, UITheme.TEXT_DIM, UITheme.semi_font()))
	var titles := ["GRAVEYARD", "BANISHED", "REVEALED BY A CARD EFFECT"]
	var cols := [UITheme.ACCENT, Color("b06cff"), UITheme.GOLD]
	var tall: bool = not (revealed[p] as Array).is_empty()
	for k in ([2, 0, 1] if tall else [0, 1]):
		var list: Array = revealed[p] if k == 2 else piles[p][k]
		v.add_child(UITheme.label("%s  ·  %d" % [Loc.t(titles[k]), list.size()], 26 if tall else 34, cols[k], UITheme.title_font()))
		if list.is_empty():
			v.add_child(UITheme.label("Empty" if k == 0 else "No cards have been banished.", 18, UITheme.TEXT_DIM))
			continue
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(1080, 150 if tall else 196)
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		v.add_child(sc)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		sc.add_child(row)
		for i in range(list.size() - 1, -1, -1):
			var inst = list[i]
			var tr := TextureRect.new()
			# (their face-down banished cards stay secret; your own you may look at)
			var secret: bool = k == 1 and p != 0 and inst.tags.has("facedown")
			tr.texture = Cards.duel_back(int(inst.owner)) if secret else Cards.get_face(inst.id)
			if k == 1 and inst.tags.has("facedown"):
				tr.modulate = Color(0.72, 0.72, 0.85)
			tr.custom_minimum_size = Vector2(92, 134) if tall else Vector2(124, 181)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_STOP
			tr.mouse_entered.connect(func(): inspect(inst, secret))
			row.add_child(tr)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide_piles)
	v.add_child(close)
	await get_tree().process_frame
	if _pile_panel:
		panel.reset_size()
		panel.position = (get_viewport_rect().size - panel.size) / 2.0
		close.grab_focus()


func hide_piles() -> void:
	if _pile_panel:
		_pile_panel.queue_free()
		_pile_panel = null


func set_lp(p: int, lp: int, delta: int) -> void:
	var from: float = _lp_values[p]
	_lp_values[p] = lp
	var lbl := _lp_labels[p]
	# The count runs down as the damage number lands on the plate, not before.
	var lag := Settings.t(0.62 if absi(delta) >= 1000 else 0.5) if delta != 0 else 0.0
	var tw := create_tween()
	tw.tween_interval(lag)
	tw.tween_method(func(v: float): lbl.text = str(int(round(v))), from, float(lp), Settings.t(0.55))
	var bar := _lp_bars[p]
	var btw := create_tween()
	btw.tween_interval(lag)
	btw.tween_property(bar, "size:x", DuelistPanel.BAR_W * clampf(lp / 8000.0, 0.0, 1.0), Settings.t(0.55)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var col := UITheme.DANGER if delta < 0 else Color("4fd18b")
	lbl.add_theme_color_override("font_color", col)
	create_tween().tween_method(func(c: Color): lbl.add_theme_color_override("font_color", c), col, Color.WHITE, Settings.t(1.0))
	_float_number(p, delta)


func _float_number(p: int, delta: int) -> void:
	var big := absi(delta) >= 1000
	var l := UITheme.label(("%+d" % delta), 128 if big else 92, UITheme.DANGER if delta < 0 else Color("4fd18b"), Comic.shout_font())
	l.add_theme_color_override("font_outline_color", Color(Comic.INK, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	var vs := get_viewport_rect().size
	_float_root.add_child(l)
	l.reset_size()
	l.pivot_offset = l.size / 2.0
	l.position = Vector2(vs.x * 0.5 - l.size.x / 2.0, vs.y * (0.6 if p == 0 else 0.24) - l.size.y / 2.0)
	l.scale = Vector2(0.3, 0.3)
	l.rotation = -0.06 if p == 0 else 0.06
	# Where it ends up: on top of that player's Life Points.
	var plate := _plates[p]
	var goal := l.position - Vector2(0, 90)
	if plate:
		goal = plate.global_position + plate.size * Vector2(0.55, 0.45) - l.size / 2.0
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE * (1.25 if big else 1.1), Settings.t(0.12)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, Settings.t(0.1))
	tw.tween_interval(Settings.t(0.38 if big else 0.25))
	tw.tween_property(l, "position", goal, Settings.t(0.32)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(l, "scale", Vector2.ONE * 0.32, Settings.t(0.32)).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(l, "modulate:a", 0.25, Settings.t(0.32)).set_ease(Tween.EASE_IN)
	tw.tween_callback(l.queue_free)
	# The plate takes the hit when the number arrives.
	if plate:
		var pt := create_tween()
		pt.tween_interval(Settings.t(0.85 if big else 0.72))
		pt.tween_property(plate, "modulate", Color(1.9, 0.7, 0.7) if delta < 0 else Color(0.8, 1.7, 1.0), Settings.t(0.05))
		pt.tween_property(plate, "modulate", Color.WHITE, Settings.t(0.35))


# ------------------------------------------------------------------ phases

func _build_phase() -> void:
	var box := VBoxContainer.new()
	_phase_box = box
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -366
	box.offset_right = -30
	box.offset_top = -150
	box.offset_bottom = 250
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	# One pill says it all: the turn number, whose turn, and the phase.
	_pill = Control.new()
	_pill.custom_minimum_size = Vector2(336, 104)
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.draw.connect(_draw_pill)
	box.add_child(_pill)
	_btn_battle = Button.new()
	_btn_battle.text = "Battle Phase"
	_btn_battle.custom_minimum_size = Vector2(336, 58)
	UITheme.paint_button(_btn_battle, UITheme.ACCENT)
	_btn_battle.pressed.connect(func(): phase_button.emit("battle"))
	box.add_child(_btn_battle)
	_btn_end = Button.new()
	_btn_end.text = "End Turn"
	_btn_end.custom_minimum_size = Vector2(336, 58)
	_btn_end.pressed.connect(func(): phase_button.emit("end"))
	box.add_child(_btn_end)
	_btn_extra = Button.new()
	_btn_extra.text = "Extra Deck"
	_btn_extra.custom_minimum_size = Vector2(336, 50)
	_btn_extra.add_theme_color_override("font_color", Color("ffd23a"))
	_btn_extra.pressed.connect(func(): extra_pressed.emit())
	_btn_extra.visible = false
	box.add_child(_btn_extra)
	# Each phase of either turn is a chance to use Set cards and Quick-Play Spells. This switches
	# those reminders off for players who only want to be asked about attacks, summons and chains.
	var ask_row := HBoxContainer.new()
	ask_row.add_theme_constant_override("separation", 6)
	var ask_bg := PanelContainer.new()
	var asb := Comic.box(Color(0.035, 0.055, 0.12, 0.8), 10, 0.0, 0, 0)
	asb.content_margin_left = 14
	asb.content_margin_right = 8
	asb.content_margin_top = 4
	asb.content_margin_bottom = 4
	ask_bg.add_theme_stylebox_override("panel", asb)
	ask_bg.add_child(ask_row)
	box.add_child(ask_bg)
	var ask := CheckButton.new()
	ask.text = "Ask me at every chance"
	ask.button_pressed = phase_prompts
	ask.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ask.add_theme_font_size_override("font_size", 17)
	for col in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		ask.add_theme_color_override(col, UITheme.TEXT)
	ask.toggled.connect(func(on):
		phase_prompts = on
		Settings.ask_always = on
		Settings.save_settings())
	ask_row.add_child(ask)
	# A small "i": press it to read what the switch does.
	var info := Button.new()
	info.text = "?"
	info.custom_minimum_size = Vector2(34, 34)
	info.add_theme_font_size_override("font_size", 18)
	for st in [["normal", 0.12], ["hover", 0.3], ["pressed", 0.3], ["focus", 0.12]]:
		var isb := UITheme.button_box(Color(UITheme.ACCENT, float(st[1])), Color(UITheme.ACCENT, 0.7), 17)
		isb.set_content_margin_all(2)
		info.add_theme_stylebox_override(str(st[0]), isb)
	info.add_theme_color_override("font_color", UITheme.ACCENT)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ask_row.add_child(info)
	var tip := PanelContainer.new()
	var tsb := UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.97), 14, Color(UITheme.ACCENT, 0.6))
	tsb.set_content_margin_all(14)
	tip.add_theme_stylebox_override("panel", tsb)
	tip.visible = false
	tip.z_index = 20
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tl := UITheme.label("OFF: you are asked when your opponent does something one of your cards can answer: an attack, a summon, a card or effect of theirs. On your own attacks, only when you hold a card that makes your monster stronger.\n\nON: the duel also stops in every phase and after your own plays, whenever a card of yours could legally be used. Nothing is ever missed, and it asks a lot.", 16, UITheme.TEXT)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(300, 0)
	tip.add_child(tl)
	add_child(tip)
	if "--tip" in OS.get_cmdline_user_args():
		get_tree().create_timer(3.0).timeout.connect(func(): info.pressed.emit())
	var show_tip := func(on: bool):
		tip.visible = on
		if on:
			tip.reset_size()
			tip.global_position = info.global_position + Vector2(-tip.size.x + 34, 44)
	info.mouse_entered.connect(func(): show_tip.call(true))
	info.mouse_exited.connect(func(): show_tip.call(false))
	info.pressed.connect(func(): show_tip.call(not tip.visible))


var _pill: Control
var _pill_phase := 0
var _pill_mine := true
var _pill_turn := 1
var _pill_t := 0.0
var _pill_pop := 0.0
const PHASE_NAMES := ["Draw Phase", "Standby Phase", "Main Phase 1", "Battle Phase", "Main Phase 2", "End Phase"]


func set_phase(phase: int, my_turn: bool, turn := -1) -> void:
	var slot: int = {DuelState.Phase.DRAW: 0, DuelState.Phase.STANDBY: 1, DuelState.Phase.MAIN1: 2, DuelState.Phase.BATTLE: 3,
			DuelState.Phase.MAIN2: 4, DuelState.Phase.END: 5}.get(phase, 0)
	if slot != _pill_phase or my_turn != _pill_mine:
		_pill_pop = 1.0
	_pill_phase = slot
	_pill_mine = my_turn
	if turn > 0:
		_pill_turn = turn
	set_turn_side(0 if my_turn else 1)
	_pill.queue_redraw()


func _draw_pill() -> void:
	var c := _pill
	var col := Comic.BLUE if _pill_mine else Comic.RED
	var r := Rect2(2, 8, 332, 88)
	var pts := Comic.slab(c, r, 20.0, Color(0.05, 0.075, 0.16, 0.95).lerp(col, 0.25 + _pill_pop * 0.5), Color(0.025, 0.04, 0.09, 0.97), 1.0, Vector2(0, 4))
	# The side's color on the leading edge.
	c.draw_polyline(PackedVector2Array([pts[0], pts[3]]), col.lightened(0.25), 5.0, true)
	var who: String = Loc.t("YOUR TURN") if _pill_mine else Loc.t("RIVAL'S TURN")
	var head := Loc.t("TURN %d") % _pill_turn
	var f := Comic.chunky_font()
	var sf := Comic.button_font()
	var hw := sf.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	c.draw_string(sf, Vector2(40, 36), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UITheme.ACCENT)
	c.draw_string(sf, Vector2(40 + hw + 12, 36), "·  " + who, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.8))
	var nm: String = Loc.t(PHASE_NAMES[_pill_phase]).to_upper()
	var size := 40
	while size > 22 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 226.0:
		size -= 2
	Comic.text(c, f, Vector2(32, 80), nm, size, Color.WHITE, 2)
	# The arrow: three chevrons that run when it is your turn.
	for i in 3:
		var ph := fposmod(_pill_t * 1.6 - i * 0.22, 1.0) if _pill_mine else 0.3
		var x := 268.0 + i * 16.0
		var a := (0.35 + 0.65 * (1.0 - ph)) if _pill_mine else 0.3
		c.draw_polyline(PackedVector2Array([Vector2(x, 50), Vector2(x + 10, 62), Vector2(x, 74)]), Color(UITheme.ACCENT, a), 3.0, true)


# ------------------------------------------------------------------ Turbo Duel: Speed Counters

func _process(delta: float) -> void:
	_pill_t += delta
	_pill_pop = maxf(0.0, _pill_pop - delta * 4.0)
	if _pill and _pill.is_visible_in_tree():
		_pill.queue_redraw()
	if not _gauges.is_empty():
		_tick_gauges(delta)


var speed_need := Callable()     # Turbo Duels: how many Speed Counters a Spell needs
var _gauges: Array = []          # one speedometer per player
var _gauge_val := [0.0, 0.0]
var _gauge_to := [0, 0]
var _gauge_kick := [0.0, 0.0]
var _btn_speed: Button


## Show the two speedometers and the Speed World 2 button.
func enable_turbo() -> void:
	speed_fx = SpeedLines.new(Color(0.7, 0.92, 1.0))
	speed_fx.amount = 0.12
	add_child(speed_fx)
	move_child(speed_fx, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_phase_box.add_child(row)
	_phase_box.move_child(row, 0)
	_phase_box.offset_top -= 110
	for p in [1, 0]:
		var g := Control.new()
		g.custom_minimum_size = Vector2(144, 150)
		g.draw.connect(func(): _draw_gauge(g, p))
		g.tooltip_text = "Speed Counters. Both riders gain 1 each Standby Phase and lose 1 for every 1000 damage taken at once."
		row.add_child(g)
		_gauges.append([g, p])
	_btn_speed = Button.new()
	_btn_speed.text = "Speed World 2"
	_btn_speed.custom_minimum_size = Vector2(336, 50)
	_btn_speed.add_theme_color_override("font_color", Color("ff8a3a"))
	_btn_speed.tooltip_text = "Spend Speed Counters, once per turn: 4 to burn, 7 to draw, 10 to destroy a card."
	_btn_speed.pressed.connect(func(): speed_pressed.emit())
	_phase_box.add_child(_btn_speed)
	_phase_box.move_child(_btn_speed, 4)


func set_speed(p: int, value: int, delta := 0) -> void:
	_gauge_to[p] = value
	if delta != 0:
		_gauge_kick[p] = 1.0


func set_speed_button(enabled: bool) -> void:
	if _btn_speed:
		_btn_speed.disabled = not enabled


func _tick_gauges(delta: float) -> void:
	for p in 2:
		_gauge_val[p] = lerpf(_gauge_val[p], float(_gauge_to[p]), clampf(delta * 6.0, 0.0, 1.0))
		_gauge_kick[p] = maxf(0.0, _gauge_kick[p] - delta * 1.6)
	for g in _gauges:
		(g[0] as Control).queue_redraw()


func _draw_gauge(g: Control, p: int) -> void:
	var col := Color("ff8a3a") if p == 0 else Color("2de2e6")
	var c := Vector2(g.size.x / 2.0, 82.0)
	var r := 62.0
	var a0 := deg_to_rad(150.0)
	var a1 := deg_to_rad(390.0)
	var v: float = _gauge_val[p]
	var kick: float = _gauge_kick[p]
	g.draw_circle(c, r + 8.0, Color(0.02, 0.03, 0.06, 0.88))
	g.draw_arc(c, r + 8.0, 0.0, TAU, 48, Color(col, 0.35 + kick * 0.5), 2.0, true)
	g.draw_arc(c, r, a0, a1, 40, Color(1, 1, 1, 0.12), 7.0, true)
	if v > 0.02:
		g.draw_arc(c, r, a0, lerpf(a0, a1, v / 12.0), 40, col.lightened(kick * 0.5), 7.0, true)
	for i in 13:
		var a := lerpf(a0, a1, i / 12.0)
		var dir := Vector2(cos(a), sin(a))
		var big := i % 4 == 0 or i == 7 or i == 10
		g.draw_line(c + dir * (r - (13.0 if big else 8.0)), c + dir * (r - 3.0), Color(1, 1, 1, 0.75 if big else 0.3), 2.0 if big else 1.0)
	# The marks where Speed World 2 pays out.
	for mark in [4, 7, 10]:
		var am := lerpf(a0, a1, mark / 12.0)
		g.draw_circle(c + Vector2(cos(am), sin(am)) * (r + 1.0), 3.5, UITheme.GOLD if v >= mark - 0.05 else Color(1, 1, 1, 0.25))
	var an := lerpf(a0, a1, v / 12.0)
	g.draw_line(c, c + Vector2(cos(an), sin(an)) * (r - 16.0), Color.WHITE, 3.0, true)
	g.draw_circle(c, 5.0, col)
	var font := UITheme.title_font()
	var num := str(_gauge_to[p])
	var ns := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
	g.draw_string(font, c + Vector2(-ns.x / 2.0, 44.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
	var who: String = (Loc.t("You") if p == 0 else Loc.t("Rival")).to_upper()
	var f2 := UITheme.semi_font()
	var ws := f2.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	g.draw_string(f2, Vector2(c.x - ws.x / 2.0, 14.0), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)


func end_button_off() -> bool:
	return _btn_end.disabled


func set_phase_buttons(battle_text: String, battle_enabled: bool, end_enabled: bool) -> void:
	_btn_battle.text = battle_text
	_btn_battle.visible = battle_text != ""
	_btn_battle.disabled = not battle_enabled
	_btn_end.disabled = not end_enabled


func set_extra_button(count: int, ready: int, enabled: bool) -> void:
	# The Extra Deck lives on the field now (left of your Spell & Trap row); this button stays
	# hidden and only keeps the old keyboard path working.
	_btn_extra.visible = false
	_btn_extra.tooltip_text = "Your Fusion, Synchro and Xyz monsters wait in the Extra Deck."
	_btn_extra.text = (Loc.t("✸ SUMMON READY  (%d)") % ready) if ready > 0 else Loc.t("Extra Deck  %d") % count
	_btn_extra.disabled = not enabled or count == 0
	_btn_extra.add_theme_color_override("font_color", Color("ffd23a") if ready > 0 else UITheme.TEXT_DIM)


## options: [[inst, status_text, enabled], ...]
func show_extra(options: Array) -> void:
	hide_extra()
	_extra_panel = Control.new()
	_extra_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_extra_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_extra_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			hide_extra())
	_extra_panel.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.078, 0.156, 0.97), 22, Color("ffd23a", 0.4)))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	_extra_panel.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(UITheme.label("EXTRA DECK", 42, Color("ffd23a"), UITheme.title_font()))
	var ex := UITheme.label("Fusion, Synchro and Xyz monsters wait here. Synchro needs a Tuner plus monsters whose Levels add up.\nXyz needs 2 monsters with the same Level. Fusion uses Polymerization from your hand.", 17, UITheme.TEXT_DIM)
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ex.custom_minimum_size = Vector2(700, 0)
	v.add_child(ex)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	for o in options:
		var inst = o[0]
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(inst.id)
		tr.custom_minimum_size = Vector2(170, 248)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.modulate = Color.WHITE if o[2] else Color(0.55, 0.55, 0.6)
		tr.mouse_entered.connect(func(): inspect(inst))
		col.add_child(tr)
		var b := Button.new()
		b.text = o[1]
		b.disabled = not o[2]
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func():
			hide_extra()
			extra_chosen.emit(inst))
		col.add_child(b)
		row.add_child(col)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide_extra)
	v.add_child(close)
	await get_tree().process_frame
	panel.reset_size()
	panel.position = (get_viewport_rect().size - panel.size) / 2.0


func hide_extra() -> void:
	if _extra_panel:
		_extra_panel.queue_free()
		_extra_panel = null


## A sweeping band across the screen for phase changes.
func phase_sweep(text: String, color: Color) -> void:
	var vs := get_viewport_rect().size
	var band := ColorRect.new()
	band.color = Color(color, 0.0)
	band.size = Vector2(vs.x, 120)
	band.position = Vector2(0, vs.y * 0.42 - 60)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	var line_top := ColorRect.new()
	line_top.color = color
	line_top.size = Vector2(0, 3)
	band.add_child(line_top)
	var line_bot := ColorRect.new()
	line_bot.color = color
	line_bot.size = Vector2(0, 3)
	line_bot.position = Vector2(vs.x, 117)
	band.add_child(line_bot)
	line_top.color = Comic.YELLOW
	line_top.size.y = 5
	line_bot.color = Comic.YELLOW
	line_bot.size.y = 5
	var l := UITheme.label(text, 88, Color.WHITE, Comic.shout_font())
	l.add_theme_color_override("font_outline_color", Color(Comic.INK, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	l.size = Vector2(vs.x, 120)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position.x = vs.x * 0.25
	l.modulate.a = 0.0
	band.add_child(l)
	Sfx.play("turn", -2.0, 1.25)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(band, "color:a", 0.45, Settings.t(0.15))
	tw.tween_property(line_top, "size:x", vs.x, Settings.t(0.35))
	tw.tween_property(line_bot, "size:x", vs.x, Settings.t(0.35))
	tw.tween_property(line_bot, "position:x", 0.0, Settings.t(0.35))
	tw.tween_property(l, "position:x", 0.0, Settings.t(0.35))
	tw.tween_property(l, "modulate:a", 1.0, Settings.t(0.2))
	tw.chain().tween_interval(Settings.t(0.35))
	tw.chain().tween_property(band, "modulate:a", 0.0, Settings.t(0.25))
	await tw.finished
	band.queue_free()


## A name plate along the bottom of the picture while the camera is on a duelist: a slanted
## band in their color, the name, and a line under it. Slides in, holds, slides away.
func name_plate(p: int, title: String, sub: String, color: Color, hold := 1.5, quote := "") -> void:
	var vs := get_viewport_rect().size
	var right := p == 1
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 70
	add_child(root)
	var w := 760.0
	var y := vs.y - 230.0
	var band := Polygon2D.new()
	var slant := 46.0
	band.polygon = PackedVector2Array([Vector2(slant, 0), Vector2(w, 0), Vector2(w - slant, 124), Vector2(0, 124)])
	band.color = Comic.INK
	band.position = Vector2(0, 8)
	root.add_child(band)
	var band2 := Polygon2D.new()
	band2.polygon = band.polygon
	band2.color = (Comic.RED if right else Comic.BLUE).darkened(0.1)
	root.add_child(band2)
	var rim := Line2D.new()
	rim.points = PackedVector2Array([Vector2(slant, 0), Vector2(w, 0), Vector2(w - slant, 124), Vector2(0, 124), Vector2(slant, 0)])
	rim.width = 6
	rim.default_color = Comic.INK
	rim.joint_mode = Line2D.LINE_JOINT_ROUND
	root.add_child(rim)
	var edge := Polygon2D.new()
	edge.polygon = PackedVector2Array([Vector2(slant, 0), Vector2(slant + 16, 0), Vector2(16, 124), Vector2(0, 124)]) if not right else PackedVector2Array([Vector2(w - 16, 0), Vector2(w, 0), Vector2(w - slant, 124), Vector2(w - slant - 16, 124)])
	edge.color = Comic.YELLOW
	root.add_child(edge)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.55)
	line.position = Vector2(slant + 30, 78)
	line.size = Vector2(w - slant * 2 - 60, 2)
	root.add_child(line)
	var nm := Comic.label(title.to_upper(), 60, Color.WHITE, 12)
	nm.position = Vector2(slant + 34, 0)
	nm.size = Vector2(w - slant * 2 - 60, 78)
	nm.clip_text = true
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(nm)
	var sb := UITheme.label(sub, 24, Comic.YELLOW, UITheme.semi_font())
	sb.position = Vector2(slant + 34, 82)
	sb.size = Vector2(w - slant * 2 - 60, 36)
	sb.clip_text = true
	sb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(sb)
	if quote != "":
		# What they say pops up in a speech box over the plate.
		var q := SpeechBox.new(p)
		q.tail = "dr" if right else "dl"
		q.set_line(title, quote)
		q.position = Vector2(w - slant - q.size.x - 30, -q.size.y - 46) if right else Vector2(slant + 30, -q.size.y - 46)
		q.pivot_offset = Vector2(q.size.x if right else 0.0, q.size.y)
		q.scale = Vector2(0.5, 0.5)
		q.modulate.a = 0.0
		root.add_child(q)
		var qt := create_tween().set_parallel()
		qt.tween_property(q, "modulate:a", 1.0, 0.1).set_delay(0.4)
		qt.tween_property(q, "scale", Vector2.ONE, 0.22).set_delay(0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("hey", -11.0, 1.15 if p == 0 else 0.82)
	var rest_x := vs.x - w - 70.0 if right else 70.0
	var off_x := vs.x + 40.0 if right else -w - 40.0
	root.position = Vector2(off_x, y)
	Sfx.play("whoosh", -10.0, 1.2)
	var tw := create_tween()
	tw.tween_property(root, "position:x", rest_x, 0.28).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "position:x", rest_x + (-26.0 if right else 26.0), hold)
	tw.tween_property(root, "position:x", off_x, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_callback(root.queue_free)


## "VS" hits the middle of the picture over the live field, then gets out of the way.
func vs_slam(left: Color, right: Color) -> void:
	var vs := get_viewport_rect().size
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 70
	root.position = vs / 2.0
	add_child(root)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.0)
	flash.position = -vs / 2.0
	flash.size = vs
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	for i in 2:
		var streak := Polygon2D.new()
		var sx := -1.0 if i == 0 else 1.0
		streak.polygon = PackedVector2Array([Vector2(sx * 90, -8), Vector2(sx * (vs.x / 2.0 + 60), -3), Vector2(sx * (vs.x / 2.0 + 60), 3), Vector2(sx * 90, 8)])
		streak.color = Color(left if i == 0 else right, 0.9)
		streak.scale.x = 0.0
		root.add_child(streak)
		create_tween().tween_property(streak, "scale:x", 1.0, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	var l := UITheme.label("VS", 290, Comic.YELLOW, Comic.shout_font())
	l.add_theme_color_override("font_outline_color", Color(Comic.INK, 0.9))
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 10)
	l.add_theme_constant_override("shadow_outline_size", 24)
	l.size = Vector2(600, 300)
	l.position = Vector2(-300, -150)
	l.pivot_offset = Vector2(300, 150)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.scale = Vector2(3.2, 3.2)
	l.modulate.a = 0.0
	root.add_child(l)
	Sfx.play("vs", -2.0)
	Sfx.play("impact", -6.0, 0.8)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_property(l, "modulate:a", 1.0, 0.12)
	tw.tween_property(flash, "color:a", 0.55, 0.05).set_delay(0.18)
	tw.tween_property(flash, "color:a", 0.0, 0.35).set_delay(0.24)
	await get_tree().create_timer(0.95).timeout
	var out := create_tween().set_parallel()
	out.tween_property(root, "modulate:a", 0.0, 0.25)
	out.tween_property(l, "scale", Vector2(0.6, 0.6), 0.25)
	await out.finished
	root.queue_free()


## Full-screen VS intro.
func vs_intro(left: Dictionary, right: Dictionary) -> void:
	var card := VsCard.new(left, right)
	add_child(card)
	await card.play()
	card.queue_free()


# ------------------------------------------------------------------ inspector

var _inspect_chips: HFlowContainer
var _inspect_note: Label
var _inspect_atk: Label
var _inspect_def: Label
var _inspect_stat_row: HBoxContainer


func _build_inspector() -> void:
	_inspect_panel = PanelContainer.new()
	_inspect_panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.92), 20, Color(UITheme.ACCENT, 0.25)))
	_inspect_panel.anchor_top = 0.5
	_inspect_panel.anchor_bottom = 0.5
	_inspect_panel.offset_left = 30
	_inspect_panel.offset_right = 390
	_inspect_panel.offset_top = -420
	# (0.63.1: it ends above your duelist's head now that the corner shows them live and taller)
	_inspect_panel.offset_bottom = 208
	_inspect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inspect_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_inspect_panel.add_child(v)
	# The card's name rides a slanted bar in the color of its frame.
	_inspect_head = PanelContainer.new()
	_inspect_head.add_theme_stylebox_override("panel", _head_box(Comic.BLUE))
	v.add_child(_inspect_head)
	_inspect_name = Comic.label("", 25, Color.WHITE, 7)
	_inspect_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect_name.custom_minimum_size = Vector2(290, 0)
	_inspect_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inspect_head.add_child(_inspect_name)
	_inspect_tex = TextureRect.new()
	_inspect_tex.custom_minimum_size = Vector2(320, 250)
	_inspect_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_inspect_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(_inspect_tex)
	_inspect_chips = HFlowContainer.new()
	_inspect_chips.add_theme_constant_override("h_separation", 6)
	_inspect_chips.add_theme_constant_override("v_separation", 6)
	_inspect_chips.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(_inspect_chips)
	_inspect_stat_row = HBoxContainer.new()
	_inspect_stat_row.add_theme_constant_override("separation", 10)
	_inspect_stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_inspect_stat_row)
	_inspect_atk = _stat_box("ATK", Color("ff6b6b"))
	_inspect_def = _stat_box("DEF", Color("6bc8ff"))
	_inspect_stats = UITheme.label("", 1, Color.TRANSPARENT)
	_inspect_stats.visible = false
	v.add_child(_inspect_stats)      # (it was never put anywhere: one stray label left behind by every duel)
	# The panel keeps its size whatever the card says (it used to grow over your duelist, and
	# still cut long texts off). The text has the room that is left and scrolls: the mouse
	# wheel, wherever the pointer is.
	_inspect_scroll = ScrollContainer.new()
	_inspect_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inspect_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspect_scroll.custom_minimum_size = Vector2(320, 132)
	_inspect_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(_inspect_scroll)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inspect_scroll.add_child(tv)
	_inspect_text = UITheme.label("", 15, UITheme.TEXT_DIM)
	_inspect_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect_text.custom_minimum_size = Vector2(304, 0)
	_inspect_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inspect_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(_inspect_text)
	# (what is under an Xyz Monster, Lumen's bonds)
	_inspect_note = UITheme.label("", 15, Color("ffcf6b"), UITheme.semi_font())
	_inspect_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect_note.custom_minimum_size = Vector2(304, 0)
	_inspect_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inspect_note.visible = false
	_inspect_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(_inspect_note)
	_inspect_more = UITheme.label("", 13, Color(UITheme.ACCENT, 0.9), UITheme.semi_font())
	_inspect_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inspect_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_inspect_more)
	_inspect_panel.modulate.a = 0.0


var _inspect_head: PanelContainer
var _inspect_scroll: ScrollContainer
var _inspect_more: Label


## After a card is shown: back to the top of its text, and a word under it when there is more to read.
func _inspect_fit() -> void:
	_inspect_scroll.scroll_vertical = 0
	_inspect_more.text = " "
	await get_tree().process_frame
	if not is_instance_valid(_inspect_scroll):
		return
	var bar := _inspect_scroll.get_v_scroll_bar()
	_inspect_more.text = Loc.t("▾  scroll to read the rest") if (bar != null and bar.max_value > bar.page + 2.0) else " "


func _unhandled_input(event: InputEvent) -> void:
	# The mouse wheel, wherever the pointer is, moves the text of the card being shown.
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] \
			and _inspect_panel != null and _inspect_panel.modulate.a > 0.5 and not overlay_visible():
		_inspect_scroll.scroll_vertical += (-48 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 48)
		var bar := _inspect_scroll.get_v_scroll_bar()
		if bar != null and bar.value >= bar.max_value - bar.page - 2.0:
			_inspect_more.text = " "
const HEAD_COLORS := {"normal": Color("d9a441"), "effect": Color("f07a26"), "fusion": Color("9a55d6"), "ritual": Color("3f7fe0"),
		"synchro": Color("9aa7bd"), "xyz": Color("39405c"), "spell": Color("17a88c"), "trap": Color("d0408f"), "hidden": Color("2b6bff")}


func _head_box(col: Color) -> StyleBoxFlat:
	var sb := Comic.box(col, 10, 0.12, 3, 4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _stat_box(title: String, col: Color) -> Label:
	var box := PanelContainer.new()
	var sb := UITheme.button_box(Color(Comic.INK, 0.7), col, 12)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	box.add_theme_stylebox_override("panel", sb)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	box.add_child(h)
	var t := UITheme.label(title, 18, col, UITheme.semi_font())
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(t)
	var n := UITheme.label("0", 40, Color.WHITE, UITheme.title_font())
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	_inspect_stat_row.add_child(box)
	return n


func _chip(text: String, col: Color) -> void:
	var l := UITheme.label(text, 15, col.lightened(0.45), UITheme.semi_font())
	var sb := UITheme.button_box(Color(Comic.INK, 0.6), Color(col, 0.9), 10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", sb)
	_inspect_chips.add_child(l)


var _inspect_shown = null
var _inspect_hidden := false

func inspect(inst, hidden := false) -> void:
	if inst == null:
		return
	if _inspect_shown != inst or _inspect_hidden != hidden:
		_inspect_shown = inst
		_inspect_hidden = hidden
		_inspect_fit()
	if _inspect_panel.modulate.a < 0.99:
		create_tween().tween_property(_inspect_panel, "modulate:a", 1.0, 0.15)
	for c in _inspect_chips.get_children():
		c.queue_free()
	_inspect_note.visible = false
	if hidden:
		# The same back the card wears on the table: its owner's sleeve.
		_inspect_tex.texture = Cards.duel_back(int(inst.owner))
		_inspect_head.add_theme_stylebox_override("panel", _head_box(HEAD_COLORS["hidden"]))
		_inspect_name.text = "Face-down card"
		_inspect_stat_row.visible = false
		_inspect_text.text = "You don't know what this is yet."
		return
	var d: Dictionary = inst.data
	_inspect_tex.texture = Cards.get_face(inst.id)
	_inspect_name.text = d.get("name", "")
	var head_key := str(d.get("frame", "normal")) if d.get("kind", "monster") == "monster" else str(d.get("kind", "spell"))
	_inspect_head.add_theme_stylebox_override("panel", _head_box(HEAD_COLORS.get(head_key, Comic.BLUE)))
	if d.get("kind", "monster") == "monster":
		var frame: String = d.get("frame", "normal")
		var lv_word := "Rank" if frame == "xyz" else "Level"
		_chip("%s %d" % [Loc.t(lv_word), int(d.get("level", 0))], Color("ffd23a"))
		_chip(str(d.get("attribute", "")), Cards.ATTRIBUTE_COLORS.get(d.get("attribute", ""), [Color.GRAY, Color.GRAY])[1])
		_chip(str(d.get("race", "")), UITheme.ACCENT)
		_chip(frame.capitalize() + (" Tuner" if d.get("tuner", false) else ""), Color("b0b8c8"))
		_inspect_stat_row.visible = true
		_inspect_atk.text = str(int(d.get("atk", 0)))      # (whole numbers: it showed "3300.0")
		_inspect_def.text = str(int(d.get("def", 0)))
		var txt := str(d.get("desc", ""))
		var nm := str(d.get("name", ""))
		var note := str(CardEffects.of(nm).get("note", CardData.MONSTER_EFFECTS.get(nm, "")))
		# Cards built into the game carry no printed text of their own: take it from the card
		# database, or failing that say what the card does in this game.
		if txt == "":
			txt = str(CardData.EXT.get(int(inst.id), {}).get("desc", ""))
		if txt == "":
			txt = Loc.t(note)
		_inspect_text.text = CardText.shown(nm, txt) if txt != "" else (Loc.t("Normal Monster") if frame == "normal" else "")
		# Lumen grows with your bonds: the card prints her 500, so say where the rest comes from.
		if int(inst.id) == CardData.LUMEN and StoryProgress.bonds() > 0:
			var b := mini(5, StoryProgress.bonds())
			_inspect_note.text = Loc.t("500 printed  +%d from your %d bond(s) with her (300 each).") % [300 * b, b]
			_inspect_note.visible = true
		# Xyz Materials are public: say what is under the card.
		if frame == "xyz" and "overlays" in inst:
			var names: Array = []
			for o in inst.overlays:
				names.append(str(o.data.get("name", "?")))
			_inspect_note.text = (Loc.t("Xyz Materials (%d): ") % names.size() + ", ".join(names)) if not names.is_empty() else Loc.t("No Xyz Materials left.")
			_inspect_note.visible = true
	else:
		var is_trap: bool = str(d.get("kind", "")) == "trap"
		var st_names := {"quick": "Quick-Play Spell", "cont": "Continuous Spell", "field": "Field Spell", "equip": "Equip Spell",
				"ritual": "Ritual Spell", "ctrap": "Continuous Trap", "counter": "Counter Trap"}
		_chip(str(st_names.get(SpellRules.kind(inst), "Trap" if is_trap else "Spell")), Color("ff4dd2") if is_trap else Color("2de2a0"))
		if speed_need.is_valid() and not is_trap:
			var need: int = speed_need.call(inst)
			if need > 0:
				_chip(Loc.t("Speed Spell  ·  needs %d") % need, Color("ff8a3a"))
		_inspect_stat_row.visible = false
		var body := str(d.get("text", d.get("desc", "")))
		if body == "":
			body = str(CardData.EXT.get(int(inst.id), {}).get("desc", ""))
		_inspect_text.text = CardText.shown(str(d.get("name", "")), body)


# ------------------------------------------------------------------ hand

func _build_hand() -> void:
	_hand_root = Control.new()
	_hand_root.anchor_left = 0.5
	_hand_root.anchor_right = 0.5
	_hand_root.anchor_top = 1.0
	_hand_root.anchor_bottom = 1.0
	_hand_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand_root)


func add_hand_card(inst) -> void:
	var tr := TextureRect.new()
	tr.texture = Cards.get_face(inst.id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = HAND_CARD
	tr.pivot_offset = HAND_CARD / 2.0
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	# Two rims: a soft one for "you can play this", a bright gold one for the card in hand.
	for rim in [["Glow", Comic.SKY, 3, 14], ["Sel", Comic.YELLOW, 4, 24]]:
		var glow := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(rim[1]).lightened(0.25)
		sb.set_border_width_all(int(rim[2]))
		sb.set_corner_radius_all(9)
		sb.set_expand_margin_all(3)
		sb.shadow_color = Color(rim[1], 0.55)
		sb.shadow_size = int(rim[3])
		sb.draw_center = false
		glow.add_theme_stylebox_override("panel", sb)
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.visible = false
		glow.name = str(rim[0])
		tr.add_child(glow)
	tr.position = Vector2(520, -330)
	tr.rotation = 0.5
	tr.scale = Vector2(0.6, 0.6)
	tr.modulate.a = 0.0
	_hand_root.add_child(tr)
	var entry := {"inst": inst, "node": tr}
	_hand.append(entry)
	tr.mouse_entered.connect(func():
		if _hand_hover != _hand.find(entry):
			Sfx.play("blip", -20.0, 1.5)
		_hand_hover = _hand.find(entry)
		hand_card_hovered.emit(inst)
		_layout_hand())
	tr.mouse_exited.connect(func():
		if _hand_hover == _hand.find(entry):
			_hand_hover = -1
		_layout_hand())
	tr.gui_input.connect(func(e):
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
			Sfx.play("card", -12.0, 1.25)
			_drag = {"entry": entry, "from": get_viewport().get_mouse_position(), "on": false}
			hand_card_pressed.emit(inst, tr.global_position + Vector2(tr.size.x / 2.0, 0)))
	_layout_hand()


# ------------------------------------------------------------------ dragging a card out of the hand

var _drag := {}                  # {entry, from, on}
var can_drag := Callable()       # (inst) -> bool, set by the duel
var drop_handler := Callable()   # (inst, screen position) -> bool: true when the card was played


## Where the hand's own row starts on the screen: a card dropped below this line was only moved
## inside the hand, not played.
func _hand_band() -> float:
	return get_viewport_rect().size.y - HAND_CARD.y * 1.1


## Dragging a card: up onto the table plays it (when it can be played), and sideways inside the hand
## moves it to a new place among the others, so you can keep your cards in the order you like.
func _input(event: InputEvent) -> void:
	if _drag.is_empty():
		return
	var entry: Dictionary = _drag["entry"]
	var node: Control = entry["node"]
	if not is_instance_valid(node) or not _hand.has(entry):
		_drag = {}
		return
	if event is InputEventMouseMotion:
		var mp: Vector2 = event.position
		if not _drag["on"]:
			if mp.distance_to(_drag["from"]) < 16.0:
				return
			_drag["on"] = true
			_drag["can"] = can_drag.is_valid() and can_drag.call(entry["inst"])
			_drag["out"] = false
			hide_actions()
			var old: Tween = node.get_meta("tw") if node.has_meta("tw") else null
			if old and old.is_valid():
				old.kill()
			node.set_meta("held", true)
			node.z_index = 60
			node.modulate.a = 0.94
			Sfx.play("whoosh", -14.0, 1.4)
		# A card that cannot be played right now stays in the hand's row: it can only change places.
		if not _drag["can"]:
			mp.y = maxf(mp.y, _hand_band() + HAND_CARD.y * 0.3)
		var outside: bool = mp.y < _hand_band()
		if outside != bool(_drag["out"]) and _drag["can"]:
			_drag["out"] = outside
			hand_drag.emit(entry["inst"], outside)      # the table lights up where it can go
		node.global_position = mp - HAND_CARD / 2.0
		node.scale = node.scale.lerp(Vector2(0.86, 0.86), 0.35)
		node.rotation = lerpf(node.rotation, clampf(event.relative.x * 0.012, -0.3, 0.3), 0.3)
		if not outside:
			_hand_move(entry, mp.x)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var was_on: bool = _drag["on"]
		var was_out: bool = bool(_drag.get("out", false))
		_drag = {}
		if not was_on:
			return
		if was_out:
			hand_drag.emit(entry["inst"], false)
		var played: bool = was_out and drop_handler.is_valid() and drop_handler.call(entry["inst"], event.position)
		if played:
			# It stays where it was dropped until the summon takes it off the hand.
			get_tree().create_timer(2.5).timeout.connect(func():
				if is_instance_valid(node) and node.has_meta("held"):
					node.remove_meta("held")
					_layout_hand())
		else:
			node.remove_meta("held")
			node.z_index = 0
			_layout_hand()


## The held card takes the place its middle is over: the others make room as it passes them.
func _hand_move(entry: Dictionary, x: float) -> void:
	var at := _hand.find(entry)
	if at < 0:
		return
	var want := 0
	for e in _hand:
		if e == entry:
			continue
		var n: Control = e["node"]
		if is_instance_valid(n) and n.global_position.x + HAND_CARD.x * 0.5 < x:
			want += 1
	if want == at:
		return
	_hand.remove_at(at)
	_hand.insert(want, entry)
	_hand_hover = -1
	Sfx.play("blip", -18.0, 1.7)
	_layout_hand()


## Dev (--handtest): drags the first card of the hand sideways past the next two, then tries to pull a
## card it cannot play up onto the table, and prints what happened (the order must change, nothing is played).
func dev_hand_test() -> void:
	if _hand.size() < 3:
		print("HANDTEST too few cards: ", _hand.size())
		return
	var vp := get_viewport()
	var send := func(ev: InputEvent) -> void:
		vp.push_input(ev, true)
	var drag := func(from: Vector2, to: Vector2) -> void:
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = from
		down.global_position = from
		send.call(down)
		await get_tree().process_frame
		for k in 12:
			var mv := InputEventMouseMotion.new()
			mv.position = from.lerp(to, float(k + 1) / 12.0)
			mv.global_position = mv.position
			mv.relative = (to - from) / 12.0
			mv.button_mask = MOUSE_BUTTON_MASK_LEFT
			send.call(mv)
			await get_tree().process_frame
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		up.position = to
		up.global_position = to
		send.call(up)
		await get_tree().create_timer(0.5).timeout
	var first: Dictionary = _hand[0]
	var size0 := _hand.size()
	var a: Control = _hand[0]["node"]
	var c: Control = _hand[2]["node"]
	var from: Vector2 = a.global_position + HAND_CARD * Vector2(0.5, 0.35)
	var to := Vector2(c.global_position.x + HAND_CARD.x * 0.75, from.y)
	await drag.call(from, to)
	print("HANDTEST sideways: first card now at index %d of %d (was 0 of %d)" % [_hand.find(first), _hand.size(), size0])
	# Up onto the table with a card that cannot be played: it must stay in the hand.
	var stuck: Dictionary = {}
	for e in _hand:
		if not (can_drag.is_valid() and can_drag.call(e["inst"])):
			stuck = e
			break
	if stuck.is_empty():
		print("HANDTEST up: every card can be played, nothing to check")
	else:
		var n: Control = stuck["node"]
		var f2: Vector2 = n.global_position + HAND_CARD * Vector2(0.5, 0.35)
		await drag.call(f2, Vector2(f2.x, 300.0))
		print("HANDTEST up: still in hand %s, hand size %d" % [str(_hand.has(stuck)), _hand.size()])
	print("HANDTEST done")


func remove_hand_card(inst) -> void:
	for i in _hand.size():
		if _hand[i]["inst"] == inst:
			var n: Control = _hand[i]["node"]
			_hand.remove_at(i)
			_hand_hover = -1
			var tw := create_tween().set_parallel()
			tw.tween_property(n, "position:y", n.position.y - 160, Settings.t(0.2))
			tw.tween_property(n, "modulate:a", 0.0, Settings.t(0.2))
			tw.chain().tween_callback(n.queue_free)
			break
	_layout_hand()


func set_playable(insts: Array) -> void:
	_playable.clear()
	for i in insts:
		_playable[i] = true
	_layout_hand()


func _layout_hand() -> void:
	var n := _hand.size()
	var spacing := minf(HAND_CARD.x * 0.82, 1050.0 / maxf(n, 1))
	var hover_i := _hand_hover
	for i in n:
		if _hand[i]["inst"] == _focused:
			hover_i = i
	for i in n:
		var node: Control = _hand[i]["node"]
		var chosen: bool = _hand[i]["inst"] == _focused
		(node.get_node("Sel") as Panel).visible = chosen
		(node.get_node("Glow") as Panel).visible = _playable.has(_hand[i]["inst"]) and not chosen
		if node.has_meta("held"):
			continue
		var offset := i - (n - 1) / 2.0
		var hovered: bool = i == hover_i
		var target := Vector2(offset * spacing - HAND_CARD.x / 2.0, -HAND_CARD.y * 0.72 + absf(offset) * 6.0)
		var rot := deg_to_rad(offset * 2.5)
		var sc := 1.0
		# Cards you can play right now sit a little higher than the rest.
		if _playable.has(_hand[i]["inst"]):
			target.y -= 16.0
		if hovered:
			target.y = -HAND_CARD.y - 46
			rot = 0.0
			sc = 1.22
		elif hover_i >= 0:
			# The neighbors make room for the card you are pointing at.
			var away := float(i - hover_i)
			target.x += signf(away) * maxf(0.0, 62.0 - absf(away) * 18.0) * (1.0 if spacing < HAND_CARD.x * 0.8 else 0.6)
		node.z_index = 10 if hovered else i
		# One tween per card: a new layout replaces the old move instead of fighting it.
		var old: Tween = node.get_meta("tw") if node.has_meta("tw") else null
		if old and old.is_valid():
			old.kill()
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK if hovered else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var d := 0.09 if hovered else 0.15
		tw.tween_property(node, "position", target, d)
		tw.tween_property(node, "rotation", rot, d)
		tw.tween_property(node, "scale", Vector2(sc, sc), d)
		tw.tween_property(node, "modulate:a", 1.0, 0.14)
		node.set_meta("tw", tw)


# ------------------------------------------------------------------ prompts & menus

func _build_prompt() -> void:
	_prompt = PanelContainer.new()
	_prompt.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.088, 0.165, 0.92), 16, Color(UITheme.ACCENT, 0.5)))
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.offset_top = 36
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_prompt)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	_prompt.add_child(h)
	_prompt_label = UITheme.label("", 24, Color.WHITE, UITheme.semi_font())
	h.add_child(_prompt_label)
	_btn_direct = Button.new()
	_btn_direct.text = "Direct Attack"
	_btn_direct.custom_minimum_size = Vector2(150, 44)
	_btn_direct.add_theme_stylebox_override("normal", UITheme.button_box(Color(Comic.GREEN, 0.3), Comic.GREEN, 14))
	_btn_direct.add_theme_stylebox_override("hover", UITheme.button_box(Color(Comic.GREEN, 0.55), Color.WHITE, 14))
	_btn_direct.add_theme_stylebox_override("disabled", UITheme.button_box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.16), 14))
	_btn_direct.pressed.connect(func(): direct_attack_pressed.emit())
	h.add_child(_btn_direct)
	_btn_cancel = Button.new()
	_btn_cancel.text = "Cancel"
	_btn_cancel.custom_minimum_size = Vector2(110, 44)
	_btn_cancel.pressed.connect(func(): cancel_pressed.emit())
	h.add_child(_btn_cancel)
	_prompt.visible = false
	# The coach line: what you can do right now, in a few words.
	_coach = PanelContainer.new()
	var csb := UITheme.panel_box(Color(0.042, 0.0676, 0.136, 0.78), 14, Color(UITheme.ACCENT, 0.28))
	csb.content_margin_left = 18
	csb.content_margin_right = 18
	csb.content_margin_top = 7
	csb.content_margin_bottom = 7
	_coach.add_theme_stylebox_override("panel", csb)
	_coach.anchor_left = 0.5
	_coach.anchor_right = 0.5
	_coach.offset_top = 36
	_coach.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_coach.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coach.visible = false
	add_child(_coach)
	_coach_label = UITheme.label("", 19, UITheme.TEXT, UITheme.semi_font())
	_coach.add_child(_coach_label)


## Show (or with "" hide) the coach line. It steps aside while a prompt is up.
func set_coach(text: String) -> void:
	if _coach == null:
		return
	_coach_text = text
	var show := text != "" and not _prompt.visible
	if show and (_coach_label.text != text or not _coach.visible):
		_coach_label.text = text
		_coach.reset_size()
		_coach.offset_left = -_coach.size.x / 2.0
		_coach.offset_right = _coach.size.x / 2.0
	_coach.visible = show


## The line at the top of the table while you point at something on it. `direct` adds a second
## button (its word is `direct_label`; greyed out while `direct_on` is false); an empty
## `cancel_label` leaves the cancel button out (the pick cannot be skipped).
func show_prompt(text: String, direct := false, direct_label := "Direct Attack", cancel_label := "Cancel", direct_on := true) -> void:
	var fresh: bool = not _prompt.visible
	_prompt_label.text = text
	_btn_direct.text = Loc.t(direct_label)
	_btn_direct.visible = direct
	_btn_direct.disabled = not direct_on
	_btn_cancel.visible = cancel_label != ""
	_btn_cancel.text = Loc.t(cancel_label)
	_prompt.visible = true
	if _coach:
		_coach.visible = false
	_prompt.reset_size()
	_prompt.offset_left = -_prompt.size.x / 2.0
	_prompt.offset_right = _prompt.size.x / 2.0
	if fresh:
		# It drops in from just above, so the eye catches that the table is asking something.
		_prompt.pivot_offset = _prompt.size / 2.0
		_prompt.scale = Vector2(0.9, 0.9)
		_prompt.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(_prompt, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_prompt, "modulate:a", 1.0, 0.1)


func hide_prompt() -> void:
	_prompt.visible = false
	set_coach(_coach_text)


## Ask the player whether to respond with one of `options` (cards). Returns the card or null.
## Pick one card from a list (targets, materials...). `hidden` cards are shown face-down.
## `labels` (uid -> text) adds a caption under each card, e.g. where it is. An empty `cancel` means the pick is required.
func ask_pick(text: String, options: Array, button := "Select", cancel := "Cancel", hidden: Array = [], labels := {}):
	# (the box where you tap a card and confirm: a button under every card made long lists,
	# like the Destiny Draw's whole Deck, run off both sides of the screen)
	var res = await ask_cards(text, options, {"min": 1, "max": 1, "confirm": Loc.t(button), "cancel": Loc.t(cancel) if cancel != "" else "", "hidden": hidden, "labels": labels})
	return res[0] if (res is Array and not (res as Array).is_empty()) else null


## Choose cards in one box: tap to choose, tap again to take back, Confirm. See CardPicker.
## o: "min", "max"; "valid" (chosen cards -> bool) when a plain count is not the rule; "info"
## (chosen cards -> a line of text, e.g. the Levels so far); "cancel" (the word on the button, ""
## when it cannot be skipped); "hidden", "labels" as in ask_pick; "why".
## "live": every tap is an answer and the box stays open for the next one ("chosen": the cards
## already in, "finish": it may be confirmed now). Returns the chosen cards (live: the card
## tapped, or "finish"), or null when it was cancelled.
var _picker: CardPicker

func ask_cards(text: String, cards: Array, o := {}):
	var live := bool(o.get("live", false))
	if auto_answer:
		await get_tree().process_frame
		if live:
			if (bool(o.get("finish", false)) and randf() < 0.5) or cards.is_empty():
				return "finish" if bool(o.get("finish", false)) else null
			return cards[randi() % cards.size()]
		var lo := int(o.get("min", 1))
		var hi := mini(int(o.get("max", 1)), cards.size())
		var v = o.get("valid")
		for _try in 40:
			var pool := cards.duplicate()
			pool.shuffle()
			var got: Array = pool.slice(0, randi_range(mini(lo, hi), hi))
			if (v is Callable and (v as Callable).call(got)) or (not (v is Callable) and got.size() >= lo):
				return got
		return null
	await stage_clear()
	var keep: bool = live and _picker != null and is_instance_valid(_picker)
	if not keep:
		close_cards()
		_picker = CardPicker.new()
		add_child(_picker)
	_picker.open(self, text, cards, o, not keep)
	var res = await _picker.done
	if not live:
		close_cards()
	return res


## Put the card box away (a live pick leaves it open between answers).
func close_cards() -> void:
	if _picker != null and is_instance_valid(_picker):
		_picker.close()
	_picker = null


func cards_open() -> bool:
	return _picker != null and is_instance_valid(_picker)


## Attack or Defense, face-up or face-down: the card itself is shown each way it can go, and
## you tap the one you want. `bits`: 1 Attack, 4 Defense, 8 face-down Defense, 2 face-down Attack.
func ask_position(card, bits: Array) -> int:
	if auto_answer:
		await get_tree().process_frame
		return randi() % bits.size()
	await stage_clear()
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.042, 0.078, 0.156, 0.97), 22, Color(UITheme.ACCENT, 0.7)))
	root.z_index = 60
	add_child(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	root.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	v.add_child(head)
	var text := Loc.t("%s: which position?") % card.cname()
	var t := UITheme.label(text, 30, Color.WHITE, UITheme.title_font())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var fold := _foldable(root, text, UITheme.ACCENT)
	head.add_child(fold[0])
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	v.add_child(row)
	var names := {1: "Attack Position", 4: "Defense Position", 8: "Face-down Defense", 2: "Face-down Attack"}
	var subs := {1: "Fights with its ATK", 4: "Guards with its DEF", 8: "Set: they cannot see it", 2: "Hidden, upright"}
	inspect(card)
	var first: Button = null
	for i in bits.size():
		var bit := int(bits[i])
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 330)
		b.add_theme_stylebox_override("normal", UITheme.button_box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.22), 16))
		b.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.ACCENT, 0.22), UITheme.ACCENT, 16))
		b.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.ACCENT, 0.22), UITheme.ACCENT, 16))
		var pic := TextureRect.new()
		pic.texture = Cards.get_face(card.id) if bit in [1, 4] else Cards.duel_back(int(card.owner))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.size = Vector2(150, 219)
		pic.pivot_offset = pic.size / 2.0
		pic.position = Vector2(50, 12)
		pic.rotation = 0.0 if bit in [1, 2] else -PI / 2.0
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pic)
		var nm := UITheme.label(Loc.t(str(names[bit])), 23, Color.WHITE, UITheme.title_font())
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position = Vector2(0, 246)
		nm.size = Vector2(250, 30)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
		var sub := UITheme.label(Loc.t(str(subs[bit])), 16, UITheme.TEXT_DIM)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.position = Vector2(0, 280)
		sub.size = Vector2(250, 24)
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sub)
		b.mouse_entered.connect(func():
			Sfx.play("blip", -18.0, 1.3)
			create_tween().tween_property(pic, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
		b.mouse_exited.connect(func(): create_tween().tween_property(pic, "scale", Vector2.ONE, 0.1))
		b.pressed.connect(func():
			Sfx.play("click", -6.0, 1.1)
			_choice_picked.emit(i))
		row.add_child(b)
		if first == null:
			first = b
		# Each way of placing it turns into place.
		pic.modulate.a = 0.0
		var from_rot := pic.rotation + 0.5
		var to_rot := pic.rotation
		pic.rotation = from_rot
		var tw := create_tween().set_parallel()
		tw.tween_property(pic, "modulate:a", 1.0, 0.12).set_delay(0.06 * i)
		tw.tween_property(pic, "rotation", to_rot, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.06 * i)
	root.reset_size()
	await get_tree().process_frame
	var vs := get_viewport_rect().size
	root.position = Vector2((vs.x - root.size.x) / 2.0, vs.y * 0.26)
	_pop_in(root)
	if first:
		first.grab_focus()
	var idx: int = await _choice_picked
	root.queue_free()
	(fold[1] as Button).queue_free()
	return idx


## A box that asks something arrives with a small spring instead of just being there.
func _pop_in(root: Control) -> void:
	root.pivot_offset = root.size / 2.0
	root.scale = Vector2(0.92, 0.92)
	root.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(root, "modulate:a", 1.0, 0.12)
	tw.tween_property(root, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Where a card of your hand is on the screen right now (its middle), or (-1, -1).
func hand_card_center(inst) -> Vector2:
	for e in _hand:
		if e["inst"] == inst and is_instance_valid(e["node"]):
			var n: Control = e["node"]
			return n.global_position + HAND_CARD * n.scale / 2.0
	return Vector2(-1, -1)


## Your duel spirit, floating by your panel (bottom left) for the whole duel.
var _spirit_pic: TextureRect
var _spirit_t := 0.0

func show_spirit(tex: Texture2D) -> void:
	if _spirit_pic != null:
		return
	_spirit_pic = TextureRect.new()
	_spirit_pic.texture = tex
	_spirit_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_spirit_pic.stretch_mode = TextureRect.STRETCH_SCALE
	# Pinned to the bottom left corner, above the right end of your panel.
	_spirit_pic.anchor_left = 0.0
	_spirit_pic.anchor_right = 0.0
	_spirit_pic.anchor_top = 1.0
	_spirit_pic.anchor_bottom = 1.0
	_spirit_pic.offset_left = 360.0
	_spirit_pic.offset_right = 580.0
	_spirit_pic.offset_top = -(DuelistPanel.SIZE.y + 196.0)
	_spirit_pic.offset_bottom = -(DuelistPanel.SIZE.y + 196.0) + 220.0
	_spirit_pic.pivot_offset = Vector2(110, 110)
	_spirit_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spirit_pic.modulate.a = 0.0
	_spirit_pic.z_index = 4
	add_child(_spirit_pic)
	create_tween().tween_property(_spirit_pic, "modulate:a", 1.0, 0.6).set_delay(1.2)


## She perks up for a moment (when she says something, or something big happens).
func spirit_pop() -> void:
	if _spirit_pic == null:
		return
	var tw := create_tween()
	tw.tween_property(_spirit_pic, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_spirit_pic, "scale", Vector2.ONE, 0.3)


signal _destiny_picked(yes: bool)

## The offer of a Destiny Draw, before your Draw Phase: the screen's edge lights up gold, one big
## button to reach for the card you need, one small one to draw as usual. Returns true for yes.
func ask_destiny() -> bool:
	if auto_answer:
		await get_tree().process_frame
		return true
	await stage_clear()
	var vs := get_viewport_rect().size
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 58
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.015, 0.04, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	create_tween().tween_property(shade, "color:a", 0.62, 0.25)
	# A gold frame breathing at the edge of the screen.
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fb := StyleBoxFlat.new()
	fb.draw_center = false
	fb.border_color = Color("ffd76a")
	fb.set_border_width_all(8)
	frame.add_theme_stylebox_override("panel", fb)
	root.add_child(frame)
	# Two wider, fainter bands inside it stand in for a glow.
	for band in [[26, 0.22], [60, 0.09]]:
		var soft := Panel.new()
		soft.set_anchors_preset(Control.PRESET_FULL_RECT)
		soft.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sbx := StyleBoxFlat.new()
		sbx.draw_center = false
		sbx.border_color = Color(1.0, 0.84, 0.42, float(band[1]))
		sbx.set_border_width_all(int(band[0]))
		soft.add_theme_stylebox_override("panel", sbx)
		frame.add_child(soft)
	var breathe := frame.create_tween().set_loops()
	breathe.tween_property(frame, "modulate:a", 0.45, 0.6).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(frame, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.custom_minimum_size = Vector2(760, 0)
	root.add_child(v)
	var kick := UITheme.label(Loc.t("YOUR BACK IS AGAINST THE WALL"), 24, Color("fff3c4"), UITheme.semi_font())
	kick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(kick)
	var head := Comic.label(Loc.t("DESTINY DRAW"), 96, Color("ffd76a"), 14)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var what := UITheme.label(Loc.t("Choose the card you draw this turn. You can do this once per duel."), 24, Color.WHITE, UITheme.semi_font())
	what.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	what.custom_minimum_size = Vector2(760, 0)   # a wrapping label needs its width to know its height
	v.add_child(what)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	v.add_child(gap)
	var yes := Button.new()
	yes.text = Loc.t("Reach for it")
	yes.custom_minimum_size = Vector2(520, 92)
	yes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	yes.add_theme_font_override("font", UITheme.title_font())
	yes.add_theme_font_size_override("font_size", 40)
	yes.add_theme_color_override("font_color", Color("1a1204"))
	yes.add_theme_color_override("font_hover_color", Color("1a1204"))
	yes.add_theme_color_override("font_focus_color", Color("1a1204"))
	yes.add_theme_color_override("font_pressed_color", Color("1a1204"))
	var yb := Comic.box(Color("ffd76a"), 12, 0.1, 1, 8)
	var yh := Comic.box(Color("fff0b8"), 12, 0.1, 1, 8)
	for st in [["normal", yb], ["hover", yh], ["focus", yh], ["pressed", yb]]:
		yes.add_theme_stylebox_override(str(st[0]), st[1])
	yes.pressed.connect(func(): _destiny_picked.emit(true))
	v.add_child(yes)
	var no := Button.new()
	no.text = Loc.t("Draw as usual and save it")
	no.custom_minimum_size = Vector2(380, 54)
	no.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	no.add_theme_font_size_override("font_size", 22)
	no.pressed.connect(func(): _destiny_picked.emit(false))
	v.add_child(no)
	v.reset_size()
	await get_tree().process_frame
	v.reset_size()
	v.position = Vector2((vs.x - v.size.x) / 2.0, maxf(vs.y * 0.2, (vs.y - v.size.y) / 2.0 - vs.y * 0.06))
	v.pivot_offset = v.size / 2.0
	v.scale = Vector2(0.92, 0.92)
	v.modulate.a = 0.0
	var pop := create_tween().set_parallel()
	pop.tween_property(v, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(v, "modulate:a", 1.0, 0.1)
	Sfx.play("special", -6.0, 1.15)
	yes.grab_focus()
	var answer: bool = await _destiny_picked
	root.queue_free()
	return answer


signal _choice_picked(index: int)
## Dev: answer every prompt at random (the --human-test run that exercises the manual path).
var auto_answer := false
## "Ask me at every chance". Off (the way it starts): you are asked when the other side does
## something one of your cards can answer. On: also in every phase and after your own plays.
var phase_prompts := Settings.ask_always


## A question with a few labelled answers (a position, yes / no, go first or second). Returns the index.
## A box that asks you something can be folded away so you can look over the table first.
## Returns [the "Look at the field" button for the box, the bar that stands in for it meanwhile].
## The caller puts the button in its layout and frees the bar when the answer is in.
func _foldable(root: Control, text: String, tint: Color) -> Array:
	var look := Button.new()
	look.text = Loc.t("Look at the field")
	look.tooltip_text = Loc.t("Fold this away and look over the table, both Graveyards and your hand. Nothing happens until you answer.")
	look.add_theme_font_size_override("font_size", 18)
	look.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bar := Button.new()
	bar.text = "%s     ·     %s" % [text, Loc.t("Back to the choice")]
	bar.add_theme_font_size_override("font_size", 22)
	bar.add_theme_stylebox_override("normal", UITheme.button_box(Color(0.06, 0.05, 0.13, 0.96), tint, 16))
	bar.add_theme_stylebox_override("hover", UITheme.button_box(Color(tint.darkened(0.6), 0.98), tint.lightened(0.2), 16))
	bar.z_index = 60
	bar.visible = false
	add_child(bar)
	var fold := func(on: bool):
		root.visible = not on
		bar.visible = on
		if on:
			bar.reset_size()
			bar.position = Vector2((get_viewport_rect().size.x - bar.size.x) / 2.0, 96.0 * get_viewport_rect().size.y / 1080.0)
			Sfx.play("click", -8.0)
	look.pressed.connect(func(): fold.call(true))
	bar.pressed.connect(func(): fold.call(false))
	if "--ask-look" in OS.get_cmdline_user_args():      # dev: fold it away by itself, for a picture
		get_tree().create_timer(2.0).timeout.connect(func(): fold.call(true))
	return [look, bar]


func ask_choice(text: String, answers: Array, card = null) -> int:
	if auto_answer:
		await get_tree().process_frame
		return randi() % answers.size()
	await stage_clear()
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.042, 0.078, 0.156, 0.97), 22, Color(UITheme.ACCENT, 0.7)))
	root.z_index = 60
	add_child(root)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	root.add_child(h)
	if card != null:
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(card.id)
		tr.custom_minimum_size = Vector2(170, 248)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(tr)
		inspect(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var t := UITheme.label(text, 30, Color.WHITE, UITheme.title_font())
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(440, 0)
	v.add_child(t)
	var first: Button = null
	for i in answers.size():
		var b := Button.new()
		b.text = str(answers[i])
		b.custom_minimum_size = Vector2(440, 56)
		if i == 0:
			b.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.25), UITheme.ACCENT, 14))
			first = b
		b.add_theme_font_size_override("font_size", 23)
		b.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.ACCENT, 0.45), Color.WHITE, 14))
		b.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.ACCENT, 0.35), Color.WHITE, 14))
		b.mouse_entered.connect(func(): Sfx.play("blip", -18.0, 1.3))
		b.pressed.connect(func():
			Sfx.play("click", -6.0, 1.1)
			_choice_picked.emit(i))
		v.add_child(b)
	var fold := _foldable(root, text, UITheme.ACCENT)
	(fold[0] as Button).flat = true
	v.add_child(fold[0])
	root.reset_size()
	await get_tree().process_frame
	var vs := get_viewport_rect().size
	root.position = Vector2((vs.x - root.size.x) / 2.0, vs.y * 0.3)
	_pop_in(root)
	Sfx.play("hover", -8.0, 1.1)
	if first:
		first.grab_focus()
	var idx: int = await _choice_picked
	root.queue_free()
	(fold[1] as Button).queue_free()
	return idx


signal _name_picked(id: int)

## "Declare 1 card name": a search box over every card name the question allows. The cards you
## have seen in this duel are offered first, so most of the time it is one click. `quick` and
## `all` are lists of [id, name]. Returns the id of the card named.
func ask_name(text: String, quick: Array, all: Array) -> int:
	if auto_answer:
		await get_tree().process_frame
		var src: Array = quick if not quick.is_empty() else all
		return int(src[randi() % src.size()][0]) if not src.is_empty() else 0
	await stage_clear()
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.042, 0.078, 0.156, 0.97), 22, Color(UITheme.ACCENT, 0.7)))
	root.z_index = 60
	add_child(root)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	root.add_child(h)
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(190, 277)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(face)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	h.add_child(v)
	var t := UITheme.label(text, 28, Color.WHITE, UITheme.title_font())
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(460, 0)
	v.add_child(t)
	var search := LineEdit.new()
	search.placeholder_text = Loc.t("Type a card name (English or Spanish)")
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", 20)
	search.custom_minimum_size = Vector2(460, 44)
	v.add_child(search)
	var note := UITheme.label("", 16, UITheme.TEXT, UITheme.semi_font())
	v.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	var peek := func(id: int): face.texture = Cards.get_face(id)
	var fill := func(word: String):
		for c in list.get_children():
			c.queue_free()
		var rows: Array = []
		var w := CardSearch.fold(word)
		if w == "":
			rows = quick
			note.text = Loc.t("Cards seen in this duel. Type to search every card.") if not quick.is_empty() else Loc.t("Type to search every card.")
		else:
			var starts: Array = []
			var holds: Array = []
			# (its English or its Spanish name)
			for r in all:
				var sc := CardSearch.score(int(r[0]), str(r[1]), w)
				if sc >= 3:
					starts.append(r)
				elif sc > 0:
					holds.append(r)
			rows = starts + holds
			note.text = Loc.t("%d names match") % rows.size()
		for r in rows.slice(0, 40):
			var b := Button.new()
			var alt := CardSearch.other_name(int(r[0]), str(r[1]), w)
			b.text = str(r[1]) + ("   ·   " + alt if alt != "" else "")
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.custom_minimum_size = Vector2(440, 40)
			b.add_theme_font_size_override("font_size", 18)
			var id := int(r[0])
			b.pressed.connect(func(): _name_picked.emit(id))
			b.mouse_entered.connect(func(): peek.call(id))
			b.focus_entered.connect(func(): peek.call(id))
			list.add_child(b)
		if not rows.is_empty():
			peek.call(int(rows[0][0]))
	search.text_changed.connect(func(nt): fill.call(nt))
	# (Enter names the first match)
	search.text_submitted.connect(func(_nt):
		for c in list.get_children():
			if c is Button and not c.is_queued_for_deletion():
				(c as Button).pressed.emit()
				return)
	fill.call("")
	root.reset_size()
	await get_tree().process_frame
	var vs := get_viewport_rect().size
	root.position = Vector2((vs.x - root.size.x) / 2.0, maxf(20.0, (vs.y - root.size.y) * 0.4))
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.15)
	search.grab_focus()
	var got: int = await _name_picked
	root.queue_free()
	return got


func ask_response(text: String, options: Array, button := "Activate", cancel := "Don't activate", hidden: Array = [], tint := Color("ff4dd2"), labels := {}):
	if auto_answer:
		await get_tree().process_frame
		return null if (cancel != "" and randf() < 0.3) or options.is_empty() else options[randi() % options.size()]
	await stage_clear()
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.072, 0.038, 0.125, 0.97) if tint == Color("ff4dd2") else Color(0.042, 0.078, 0.156, 0.97), 22, Color(tint, 0.7)))
	root.z_index = 60
	add_child(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	root.add_child(v)
	# The question, and a way to get the box out of the way: it sits in the middle of the table,
	# and what you answer depends on what is on that table.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	v.add_child(head)
	var t := UITheme.label(text, 30, Color.WHITE, UITheme.title_font())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var fold := _foldable(root, text, tint)
	head.add_child(fold[0])
	var bar: Button = fold[1]
	if ask_why != "":
		# One plain line on why the duel stopped and what your choice does.
		var why := UITheme.label(ask_why, 19, UITheme.TEXT_DIM)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(620, 0)
		v.add_child(why)
		ask_why = ""
	# Up to nine across; long lists (a Deck search) wrap and scroll.
	var row := GridContainer.new()
	row.columns = clampi(options.size(), 1, 9)
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 12)
	if options.size() > 18:
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(9 * 124 + 20, 500)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		v.add_child(sc)
		sc.add_child(row)
	else:
		v.add_child(row)
	for c in options:
		var col := VBoxContainer.new()
		var tr := TextureRect.new()
		var secret := hidden.has(c)
		tr.texture = Cards.duel_back(int(c.owner)) if secret else Cards.get_face(c.id)
		var small := options.size() > 6
		tr.custom_minimum_size = Vector2(110, 161) if small else Vector2(150, 219)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_STOP
		tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tr.mouse_entered.connect(func(): inspect(c, secret))
		tr.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_response_picked.emit(c))
		col.add_child(tr)
		if labels.has(c.uid) and str(labels[c.uid]) != "":
			var cap := UITheme.label(str(labels[c.uid]), 15, UITheme.TEXT_DIM)
			cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(cap)
		var b := Button.new()
		b.text = button
		b.add_theme_stylebox_override("normal", UITheme.button_box(Color(tint, 0.25), tint, 14))
		b.pressed.connect(func(): _response_picked.emit(c))
		col.add_child(b)
		row.add_child(col)
	if cancel != "":
		var no := Button.new()
		no.text = cancel
		no.pressed.connect(func(): _response_picked.emit(null))
		v.add_child(no)
	root.reset_size()
	var vs := get_viewport_rect().size
	await get_tree().process_frame
	root.position = Vector2((vs.x - root.size.x) / 2.0, vs.y * 0.3)
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.15)
	Sfx.play("spell", -2.0, 0.7)
	var choice = await _response_picked
	root.queue_free()
	bar.queue_free()
	return choice


## Small floating callout for card effects.
## Who activated what, and what it does, at the top of the screen for a moment. The duel does
## not wait for it: the card goes straight into its animation underneath.
var _caption: Control


func action_caption(title: String, detail: String, color: Color, mine: bool) -> void:
	if _caption and is_instance_valid(_caption):
		_caption.queue_free()
	var pc := PanelContainer.new()
	var sb := UITheme.button_box(Color(0.03, 0.045, 0.1, 0.93), Color(color, 0.85), 16)
	sb.content_margin_left = 22
	sb.content_margin_right = 26
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	sb.border_width_left = 6
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.z_index = 41
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	var t := UITheme.label(title, 23, color.lightened(0.35), UITheme.title_font())
	v.add_child(t)
	if detail != "":
		var d := UITheme.label(detail, 17, Color(0.9, 0.93, 1.0))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.max_lines_visible = 2
		d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		d.custom_minimum_size = Vector2(minf(640.0, 18.0 + detail.length() * 8.5), 0)
		v.add_child(d)
	add_child(pc)
	_caption = pc
	pc.reset_size()
	var vs := get_viewport_rect().size
	pc.position = Vector2((vs.x - pc.size.x) / 2.0, vs.y * 0.075)
	pc.modulate.a = 0.0
	pc.position.y -= 14.0
	var tw := pc.create_tween()
	tw.set_parallel()
	tw.tween_property(pc, "modulate:a", 1.0, 0.16)
	tw.tween_property(pc, "position:y", pc.position.y + 14.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Long enough to read, short enough to be out of the way of what happens next (it stayed
	# up to six seconds, on top of the lines that followed).
	tw.chain().tween_interval(Settings.t(clampf(1.3 + detail.length() * 0.011, 1.5, 2.6)))
	tw.chain().tween_property(pc, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(pc.queue_free)


var _fx_line: Label

func effect_text(text: String, color := Color("ffd23a")) -> void:
	var l := UITheme.label(text, 26, Color.WHITE, UITheme.semi_font())
	var sb := UITheme.button_box(Color(0.042, 0.058, 0.125, 0.92), color, 16)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	l.add_theme_stylebox_override("normal", sb)
	l.z_index = 40
	add_child(l)
	l.reset_size()
	var vs := get_viewport_rect().size
	var y := vs.y * 0.17
	if _caption != null and is_instance_valid(_caption) and _caption.modulate.a > 0.05:
		y = maxf(y, _caption.position.y + _caption.size.y + 10.0)      # (under the "X activates Y" box, never across it)
	if _fx_line != null and is_instance_valid(_fx_line):
		_fx_line.queue_free()                                         # (one line at a time: a new one replaces the last)
	_fx_line = l
	l.position = Vector2((vs.x - l.size.x) / 2.0, y)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.tween_interval(Settings.t(1.3))
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


const ACTION_ICONS := {
	"summon": "▲", "set": "▼", "activate": "✦", "flip": "⟳", "position": "⟲",
	"attack": "⚔", "direct": "⚔", "fuse": "✸", "set_st": "▼", "special_hand": "★", "ignite": "✦", "fire": "✹",
	"surrender": "⚑", "piles": "☰", "pause": "⚙",
	"special": "★", "mset": "▼", "sset": "▼", "act": "✦", "repos": "⟲", "flipsummon": "⟳", "tribute": "▲", "gyfx": "✦",
}
var _focused = null


const ACTION_HINTS := {
	"summon": "Face-up, in Attack Position", "set": "Face-down, in Defense Position", "set_st": "Face-down. Use it on a later turn",
	"activate": "Use its effect right now", "flip": "Turn it face-up", "position": "Switch its battle position",
	"attack": "Pick a target, or go direct", "fuse": "Fusion Summon this monster", "special_hand": "Does not use your Normal Summon",
	"ignite": "Use this monster's effect", "fire": "Spend its counters", "surrender": "Give up this duel", "piles": "Look through both Graveyards",
	"pause": "Settings, rules and more",
	"special": "Does not use your Normal Summon", "mset": "Face-down, in Defense Position", "sset": "Face-down. Use it on a later turn",
	"act": "Use it right now", "repos": "Switch its battle position", "flipsummon": "Turn it face-up, in Attack Position",
	"tribute": "Give up monsters you control for it", "gyfx": "A card there can use its effect",
}


## options: [[action_id, label, enabled], ...]  Cards of choice that pop out beside `at`.
## `at` is the right edge / vertical middle of the card that was tapped.
## `above`: `at` is the middle of the menu's bottom edge (it opens upward from there, the way
## it does over a hand card, so it never covers the other cards in your hand).
func show_actions(at: Vector2, options: Array, above := false) -> void:
	for c in _menu.get_children():
		_menu.remove_child(c)
		c.queue_free()
	_menu.add_theme_constant_override("separation", 7)
	var nth := 0
	for o in options:
		var id: String = o[0]
		# (an entry may say what kind of move it is, and bring its own second line)
		var key: String = str(o[3]) if o.size() > 3 else id.split(":")[0]
		var hint: String = str(o[4]) if o.size() > 4 else str(ACTION_HINTS.get(key, ""))
		var col: Color = Comic.RED if key in ["attack", "direct", "surrender"] else (Color("d99a00") if key in ["fuse", "special_hand", "ignite", "special", "act", "gyfx"] else (Color("8a5cf0") if key in ["set", "set_st", "mset", "sset"] else (Comic.BLUE if key in ["piles", "pause", "view", "repos", "position"] else Comic.ORANGE_DEEP)))
		var b := Button.new()
		b.disabled = not o[2]
		b.custom_minimum_size = Vector2(330, 66)
		b.focus_mode = Control.FOCUS_ALL
		# A slanted comic ribbon in the action's own color.
		var normal := Comic.box(Color(0.05, 0.075, 0.16, 0.96).lerp(col, 0.55), 8, 0.1, 1, 6)
		normal.border_color = Color(col.lightened(0.35), 0.9)
		normal.border_width_left = 5
		var hover := Comic.box(col.lightened(0.08), 8, 0.1, 1, 6)
		hover.border_color = Color.WHITE
		hover.set_border_width_all(2)
		hover.border_width_left = 5
		var down := Comic.box(col.darkened(0.2), 8, 0.1, 1, 2)
		var off := Comic.box(Color(0.06, 0.08, 0.14, 0.9), 8, 0.1, 1, 0)
		for st in [["normal", normal], ["hover", hover], ["focus", hover], ["pressed", down], ["disabled", off]]:
			b.add_theme_stylebox_override(str(st[0]), st[1])
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 16
		row.offset_right = -14
		row.add_theme_constant_override("separation", 14)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(42, 42)
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tb := StyleBoxFlat.new()
		tb.bg_color = Color(Comic.INK, 0.85 if o[2] else 0.3)
		tb.set_corner_radius_all(21)
		tb.border_color = Color(1, 1, 1, 0.9 if o[2] else 0.2)
		tb.set_border_width_all(2)
		tile.add_theme_stylebox_override("panel", tb)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glyph := UITheme.label(str(ACTION_ICONS.get(key, "•")), 24, Comic.YELLOW if o[2] else Color(1, 1, 1, 0.3))
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tile.add_child(glyph)
		row.add_child(tile)
		var words := VBoxContainer.new()
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", -2)
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Comic.label(Loc.t(str(o[1])), 27, Color.WHITE if o[2] else Color(1, 1, 1, 0.4), 2 if o[2] else 0)
		words.add_child(title)
		# The button is as wide as its words need (Spanish runs longer: "Invocación por Sacrificio"
		# was cut off). Only a very long effect line is trimmed, at twice the usual width.
		var wide: float = title.get_minimum_size().x
		if hint != "":
			var sub := UITheme.label(Loc.t(hint) if o[2] else Loc.t("Not possible right now"), 15, Color(1, 1, 1, 0.92) if o[2] else Color(1, 1, 1, 0.35), UITheme.semi_font())
			wide = maxf(wide, sub.get_minimum_size().x)
			sub.clip_text = true
			sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			words.add_child(sub)
		title.clip_text = true
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size.x = clampf(wide + 16.0 + 42.0 + 14.0 + 14.0 + 16.0, 330.0, 660.0)
		row.add_child(words)
		b.pressed.connect(func():
			Sfx.play("click", -6.0, 1.1)
			hide_actions()
			action_chosen.emit(id))
		b.pivot_offset = Vector2(165, 33)
		b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
		b.mouse_entered.connect(func():
			if not b.disabled:
				Sfx.play("blip", -18.0, 1.3)
				_menu_pop(b, 1.05))
		b.mouse_exited.connect(func(): _menu_pop(b, 1.0))
		b.focus_entered.connect(func(): _menu_pop(b, 1.05))
		b.focus_exited.connect(func(): _menu_pop(b, 1.0))
		_menu.add_child(b)
		# Each choice springs out a beat after the one before it. It answers from the first frame.
		b.scale = Vector2(0.82, 0.82)
		b.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(b, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.03 * nth)
		tw.tween_property(b, "modulate:a", 1.0, 0.08).set_delay(0.03 * nth)
		b.set_meta("tw", tw)
		nth += 1
	_menu.visible = true
	_menu.reset_size()
	var sz := _menu.get_combined_minimum_size()
	var vs := get_viewport_rect().size
	var x := at.x + 24
	if x + sz.x > vs.x - 10:
		x = at.x - sz.x - 200
	_menu.position = Vector2(clampf(x, 10, vs.x - sz.x - 10), clampf(at.y - sz.y / 2.0, 10, vs.y - sz.y - 10))
	if above:
		_menu.position = Vector2(clampf(at.x - sz.x / 2.0, 10, vs.x - sz.x - 10), maxf(10.0, at.y - sz.y))
	_menu.scale = Vector2.ONE
	_menu.modulate.a = 1.0
	Sfx.play("hover", -8.0, 1.3)
	for c in _menu.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			break


func _menu_pop(b: Button, to: float) -> void:
	if not is_instance_valid(b):
		return
	var old: Tween = b.get_meta("tw") if b.has_meta("tw") else null
	if old and old.is_valid():
		old.kill()
	b.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(to, to), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b.set_meta("tw", tw)


## Where a hand card's menu opens: just over the top edge of the card once it is lifted,
## centered on it.
func hand_menu_anchor(inst) -> Vector2:
	var vs := get_viewport_rect().size
	var n := _hand.size()
	var spacing := minf(HAND_CARD.x * 0.82, 1050.0 / maxf(n, 1))
	for i in n:
		if _hand[i]["inst"] == inst:
			var offset := i - (n - 1) / 2.0
			return Vector2(vs.x / 2.0 + offset * spacing, vs.y - HAND_CARD.y - 46.0 - HAND_CARD.y * 0.11 - 18.0)
	return Vector2(vs.x / 2.0, vs.y - HAND_CARD.y - 90.0)


func hand_card_anchor(inst) -> Vector2:
	for e in _hand:
		if e["inst"] == inst:
			var n: Control = e["node"]
			var vs := get_viewport_rect().size
			return Vector2(vs.x / 2.0 + n.position.x + HAND_CARD.x * 1.12, vs.y - HAND_CARD.y * 1.18 - 40 + 70)
	return get_viewport_rect().size / 2.0


## Lift a hand card while its actions are open.
func focus_hand_card(inst) -> void:
	_focused = inst
	_layout_hand()


func hide_actions() -> void:
	_menu.visible = false
	if _focused != null:
		_focused = null
		_layout_hand()


func actions_visible() -> bool:
	return _menu.visible


## Ace monster moment: letterbox bars, the monster's name sweeping in, its stats.
func summon_cinematic(card_name: String, atk: int, def: int, color: Color, mine: bool) -> void:
	await cut_in(0 if mine else 1, card_name.to_upper(), Loc.t("ATK %d   ·   DEF %d") % [atk, def], color, 0.95, true)


## The play-by-play: one short line per thing the other side just did, stacked under the menu
## button and fading out on their own. `icon` is a single symbol shown in the side's color.
var _log: Array = []             # [player, icon, text, turn] for the card log
var _log_panel: Control


## The card log: every line the feed has shown this duel, newest first.
func show_log() -> void:
	if _log_panel:
		_log_panel.queue_free()
		_log_panel = null
		return
	_log_panel = Control.new()
	_log_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_log_panel.z_index = 40
	add_child(_log_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			show_log())
	_log_panel.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(UITheme.PANEL, 22))
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -620
	panel.offset_right = -30
	panel.offset_top = 230
	panel.offset_bottom = -120
	_log_panel.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(Comic.label(Loc.t("CARD LOG"), 34, Comic.YELLOW))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	sc.add_child(list)
	if _log.is_empty():
		list.add_child(UITheme.label("Nothing has been played yet.", 18, UITheme.TEXT_DIM))
	var last_turn := -1
	for i in range(_log.size() - 1, -1, -1):
		var e: Array = _log[i]
		if int(e[3]) != last_turn:
			last_turn = int(e[3])
			list.add_child(UITheme.label(Loc.t("TURN %d") % last_turn, 17, Comic.YELLOW, UITheme.semi_font()))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var col: Color = Comic.SKY if int(e[0]) == 0 else Color("ff9aa6")
		var who := UITheme.label(str(e[1]), 19, col, UITheme.title_font())
		who.custom_minimum_size = Vector2(30, 0)
		row.add_child(who)
		var l := UITheme.label(str(e[2]), 18, UITheme.TEXT, UITheme.semi_font())
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		list.add_child(row)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(show_log)
	v.add_child(close)


func feed(p: int, icon: String, text: String) -> void:
	_log.append([p, icon, text, _pill_turn])
	if _log.size() > 300:
		_log.pop_front()
	if _feed == null:
		_feed = VBoxContainer.new()
		_feed.position = Vector2(30, 22)
		_feed.custom_minimum_size = Vector2(400, 0)
		_feed.add_theme_constant_override("separation", 6)
		_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_feed)
	var col: Color = Comic.SKY if p == 0 else Color("ff9aa6")
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.8), 10, Color(col, 0.4))
	sb.border_width_left = 4
	sb.content_margin_left = 12
	sb.content_margin_right = 14
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 9)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(h)
	h.add_child(UITheme.label(icon, 18, col, UITheme.title_font()))
	var l := UITheme.label(text, 17, UITheme.TEXT, UITheme.semi_font())
	l.clip_text = true
	l.custom_minimum_size = Vector2(mini(350, 40 + text.length() * 9), 0)
	h.add_child(l)
	_feed.add_child(pc)
	while _feed.get_child_count() > 3:
		var first := _feed.get_child(0)
		_feed.remove_child(first)
		first.queue_free()
	pc.modulate.a = 0.0
	var tw := pc.create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.15)
	tw.tween_interval(6.5)
	tw.tween_property(pc, "modulate:a", 0.0, 0.5)
	tw.tween_callback(pc.queue_free)


## An anime cut-in for one side: their portrait, big words and a small line.
var _stage_busy := 0              # a cut-in or banner owns the screen until this tick


## Wait until the last cut-in or banner has left the screen. Prompts call this first, so a
## question never lands on top of an animation.
func stage_clear() -> void:
	while Time.get_ticks_msec() < _stage_busy:
		await get_tree().process_frame


func cut_in(p: int, title: String, sub: String, color: Color, hold := 0.6, big := false) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_cut_at[p]) < 900 and not big:
		return
	_cut_at[p] = now
	if hold < 5.0:
		_stage_busy = maxi(_stage_busy, now + int((hold + 0.6) * 1000.0))
	await CutIn.play(self, p, str(portrait_keys[p]), title, sub, color, hold, big)


## The opponent plays a Spell or springs a Trap: the card is held up big, with its name and
## what it does, long enough to read, before anything happens. Await it.
func showcase(inst, kicker: String, color: Color, who := "") -> void:
	if inst == null or auto_answer:
		return
	inspect(inst)
	var hold := maxf(1.5, Settings.t(2.0))
	_stage_busy = maxi(_stage_busy, Time.get_ticks_msec() + int((hold + 0.6) * 1000.0))
	var vs := get_viewport_rect().size
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 55
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.05, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var card := TextureRect.new()
	card.texture = Cards.get_face(inst.id, true)
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.size = Vector2(330, 481)
	card.pivot_offset = card.size / 2.0
	var cx := vs.x * 0.5 - 420.0
	card.position = Vector2(cx, vs.y * 0.5 - 250.0)
	card.rotation = -0.12
	card.scale = Vector2(0.5, 0.5)
	card.modulate.a = 0.0
	root.add_child(card)
	var panel := PanelContainer.new()
	var psb := UITheme.panel_box(Color(0.035, 0.055, 0.12, 0.95), 12, Color(color, 0.8))
	psb.border_width_left = 6
	psb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", psb)
	panel.position = Vector2(cx + 372.0, vs.y * 0.5 - 150.0)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.modulate.a = 0.0
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UITheme.label((kicker + ("   ·   " + who.to_upper() if who != "" else "")), 20, color.lightened(0.35), Comic.button_font()))
	var nm := Comic.label(str(inst.data.get("name", "")), 44)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(476, 0)
	v.add_child(nm)
	var body := str(_inspect_text.text)
	if body.length() > 260:
		body = body.substr(0, 257) + "..."
	var tl := UITheme.label(body, 20, UITheme.TEXT)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(476, 0)
	v.add_child(tl)
	Sfx.play("whoosh", -8.0, 0.9)
	var tin := create_tween().set_parallel()
	tin.tween_property(shade, "color:a", 0.45, 0.2)
	tin.tween_property(card, "modulate:a", 1.0, 0.12)
	tin.tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tin.tween_property(card, "rotation", -0.03, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tin.tween_property(panel, "modulate:a", 1.0, 0.2).set_delay(0.12)
	tin.tween_property(panel, "position:x", panel.position.x + 18.0, hold + 0.3)
	await get_tree().create_timer(hold).timeout
	if not is_instance_valid(root):
		return
	var out := create_tween().set_parallel()
	out.tween_property(root, "modulate:a", 0.0, 0.22)
	out.tween_property(card, "scale", Vector2(0.86, 0.86), 0.22)
	await out.finished
	root.queue_free()


## Speed lines bursting out from a point on the table (where a hit lands).
func impact(world: Vector3, color: Color, strength := 1.0) -> void:
	var cam := get_viewport().get_camera_3d()
	var at := get_viewport_rect().size * 0.5
	if cam and not cam.is_position_behind(world):
		at = cam.unproject_position(world)
	CutIn.impact(self, at, color, strength)


## `high` puts the words along the top of the picture, clear of the monsters on the field.
func banner(text: String, color := Color.WHITE, high := false, at_y := -1.0) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.add_theme_font_size_override("font_size", 92 if high else 130)
	_banner.reset_size()
	var vs := get_viewport_rect().size
	_stage_busy = maxi(_stage_busy, Time.get_ticks_msec() + int(Settings.t(0.9) * 1000.0))
	_banner.position = Vector2((vs.x - _banner.size.x) / 2.0 - 60, vs.y * (at_y if at_y > 0.0 else (0.115 if high else 0.4)) - _banner.size.y / 2.0)
	var x := _banner.position.x
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(_banner, "modulate:a", 1.0, Settings.t(0.2))
	tw.tween_property(_banner, "position:x", x + 60, Settings.t(0.35)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(Settings.t(0.55))
	tw.chain().tween_property(_banner, "modulate:a", 0.0, Settings.t(0.25))
	await tw.finished


# ------------------------------------------------------------------ the Field Spell in force

var _field_strip: PanelContainer
var _field_card = null


## The name of the place sweeps across the field once, when a Field Spell takes it.
func field_banner(title: String, whose: String, color: Color) -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.z_index = 38
	var small := UITheme.label(Loc.t("FIELD SPELL") + "   ·   " + whose, 24, Color(1, 1, 1, 0.92), UITheme.semi_font())
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	small.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	small.add_theme_constant_override("outline_size", 8)
	box.add_child(small)
	var big := UITheme.label(title.to_upper(), 104, color.lerp(Color.WHITE, 0.25), UITheme.title_font())
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.92))
	big.add_theme_constant_override("outline_size", 22)
	box.add_child(big)
	add_child(box)
	box.reset_size()
	var vs := get_viewport_rect().size
	# Long names are brought down to the width of the field.
	var k := minf(1.0, vs.x * 0.72 / maxf(box.size.x, 1.0))
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2(k, k) * 0.86
	box.position = Vector2((vs.x - box.size.x) / 2.0, vs.y * 0.36 - box.size.y / 2.0)
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(box, "modulate:a", 1.0, Settings.t(0.22))
	tw.tween_property(box, "scale", Vector2(k, k), Settings.t(0.45)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(Settings.t(1.15))
	tw.chain().tween_property(box, "modulate:a", 0.0, Settings.t(0.4))
	tw.chain().tween_callback(box.queue_free)


## The Field Spell in force, kept in sight on the right: its name, whose it is and what it does
## to whom. `lines` are [who, what] pairs. A null card takes the strip away.
func set_field_strip(card, lines: Array, color: Color, whose: String) -> void:
	if _field_strip != null and is_instance_valid(_field_strip):
		_field_strip.queue_free()
	_field_strip = null
	_field_card = card
	if card == null:
		return
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.035, 0.05, 0.11, 0.9), 12, Color(color, 0.85))
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	pc.add_theme_stylebox_override("panel", sb)
	pc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pc.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pc.offset_right = -32
	pc.offset_top = 708          # (under the turn buttons, in the free strip on the right)
	pc.custom_minimum_size = Vector2(332, 0)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pc.tooltip_text = Loc.t("The Field Spell in force. Click to read the card.")
	pc.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and _field_card != null:
			pc.accept_event()
			inspect(_field_card))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(v)
	var head := UITheme.label(Loc.t("FIELD") + "   ·   " + whose, 17, Color(color.lerp(Color.WHITE, 0.3), 0.95), UITheme.semi_font())
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var nm := UITheme.label(str(card.data.get("name", "")), 30, Color.WHITE, UITheme.title_font())
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(298, 0)
	v.add_child(nm)
	for ln in lines:
		var who := UITheme.label(str(ln[0]), 20, Color(0.86, 0.9, 1.0, 0.95), UITheme.semi_font())
		who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		who.custom_minimum_size = Vector2(298, 0)
		who.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(who)
		var what := str(ln[1])
		var wl := UITheme.label("    " + what, 21, Color("ff8a8a") if what.begins_with("-") else Color("8dffb0"), UITheme.semi_font())
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wl.custom_minimum_size = Vector2(298, 0)
		wl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(wl)
	if lines.is_empty():
		var rd := UITheme.label(Loc.t("Click to read what it does."), 18, Color(0.8, 0.85, 0.95, 0.85))
		rd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(rd)
	add_child(pc)
	_field_strip = pc
	pc.modulate.a = 0.0
	create_tween().tween_property(pc, "modulate:a", 1.0, 0.3)


# ------------------------------------------------------------------ overlays

func _clear_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null


## `side` keeps the left of the screen clear (for the winner's close-up) and puts the panel on the right.
func _overlay_panel(title: String, subtitle: String, title_color: Color, side := false) -> VBoxContainer:
	_clear_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.z_index = 75   # over the hand cards and every menu: a pause covers the whole table
	add_child(_overlay)
	if side:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.42, 0.7, 1.0])
		grad.colors = PackedColorArray([Color(0.01, 0.02, 0.05, 0.0), Color(0.01, 0.02, 0.05, 0.25), Color(0.015, 0.025, 0.06, 0.86), Color(0.015, 0.025, 0.06, 0.94)])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		var shade := TextureRect.new()
		shade.texture = gt
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay.add_child(shade)
	else:
		var dim := ColorRect.new()
		dim.color = Color(0.01, 0.02, 0.05, 0.78)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	if side:
		center.anchor_left = 0.52
	_overlay.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var t := UITheme.label(title, 150, title_color, Comic.shout_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(Comic.INK, 0.9))
	t.add_theme_constant_override("outline_size", 10)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_x", 0)
	t.add_theme_constant_override("shadow_offset_y", 8)
	t.add_theme_constant_override("shadow_outline_size", 20)
	v.add_child(t)
	if subtitle != "":
		var s := UITheme.label(subtitle, 24, UITheme.TEXT_DIM)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	v.add_child(spacer)
	_overlay.modulate.a = 0.0
	create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.3)
	return v


func _overlay_button(v: BoxContainer, text: String, action: String) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func(): pause_action.emit(action))
	if v is HBoxContainer:
		# Side by side (the result screen): the first one is the wide one.
		b.custom_minimum_size = Vector2(300 if v.get_child_count() == 0 else 210, 60)
		v.add_child(b)
		return b
	b.custom_minimum_size = Vector2(360, 60)
	var c := CenterContainer.new()
	c.add_child(b)
	v.add_child(c)
	return b


func show_result(won: bool, reason: String, story := false, lose_ok := false, cont := "Continue Story", stats := {}) -> void:
	for n in [_phase_box, _inspect_panel, _hand_root, _plates[0], _plates[1], _menu_btn]:
		if n:
			create_tween().tween_property(n, "modulate:a", 0.0, 0.3)
	var tied: bool = stats.get("draw", false)
	var mt: Dictionary = stats.get("match", {})
	var title := "DRAW" if tied else ("VICTORY" if won else "DEFEAT")
	if not mt.is_empty():
		if mt["over"]:
			title = "MATCH WON" if mt["won"] else "MATCH LOST"
		else:
			title = "DRAW" if tied else ("DUEL WON" if won else "DUEL LOST")
	var v := _overlay_panel(title, reason,
			Color.WHITE if tied else (Comic.YELLOW if won else Comic.RED), true)
	if not mt.is_empty():
		var score := UITheme.label(Loc.t("MATCH   %d  -  %d") % [int(mt["wins"][0]), int(mt["wins"][1])], 40, UITheme.GOLD, UITheme.title_font())
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(score)
	if not stats.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		v.add_child(row)
		var lp: Array = stats.get("lp", [0, 0])
		for item in [["TURNS", str(stats.get("turns", 0)), Color.WHITE], ["YOUR LP", str(lp[0]), Comic.SKY], ["THEIR LP", str(lp[1]), Color("ff8a98")]]:
			var box := PanelContainer.new()
			box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.088, 0.165, 0.9), 14, Color(item[2], 0.35)))
			box.custom_minimum_size = Vector2(150, 0)
			var bv := VBoxContainer.new()
			box.add_child(bv)
			var cap := UITheme.label(item[0], 15, UITheme.TEXT_DIM, UITheme.semi_font())
			cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bv.add_child(cap)
			var val := UITheme.label(item[1], 40, item[2], UITheme.title_font())
			val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bv.add_child(val)
			row.add_child(box)
		# The card they handed over, held up.
		if int(stats.get("prize", 0)) != 0:
			var pz := HBoxContainer.new()
			pz.alignment = BoxContainer.ALIGNMENT_CENTER
			pz.add_theme_constant_override("separation", 18)
			var pc := TextureRect.new()
			pc.texture = Cards.get_face(int(stats["prize"]))
			pc.custom_minimum_size = Vector2(124, 180)
			pc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pz.add_child(pc)
			var pw := VBoxContainer.new()
			pw.alignment = BoxContainer.ALIGNMENT_CENTER
			pw.add_child(UITheme.label(Loc.t("%s HANDS YOU A CARD") % str((stats.get("names", ["", ""]) as Array)[1]).to_upper(), 18, UITheme.GOLD, UITheme.semi_font()))
			pw.add_child(Comic.label(str(CardData.get_card(int(stats["prize"])).get("name", "")), 34, Color.WHITE, 4))
			pw.add_child(UITheme.label(Loc.t("It is in your collection now."), 18, UITheme.TEXT_DIM))
			pz.add_child(pw)
			v.add_child(pz)
		# What the duel paid, line by line, then the total and your purse.
		var pay: Array = stats.get("reward", [])
		if not pay.is_empty():
			var box := PanelContainer.new()
			var psb := UITheme.panel_box(Color(0.09, 0.07, 0.02, 0.9), 14, Color(UITheme.GOLD, 0.6))
			psb.content_margin_left = 22
			psb.content_margin_right = 22
			psb.content_margin_top = 10
			psb.content_margin_bottom = 10
			box.add_theme_stylebox_override("panel", psb)
			box.custom_minimum_size = Vector2(480, 0)
			box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var pv := VBoxContainer.new()
			pv.add_theme_constant_override("separation", 2)
			box.add_child(pv)
			for line in pay:
				var label := str(line[0])
				if label.begins_with("Win streak x"):
					label = Loc.t("Win streak x%d") % int(label.trim_prefix("Win streak x"))
				else:
					label = Loc.t(label)
				var row2 := HBoxContainer.new()
				var fs := 22 if pay.size() <= 5 else (20 if pay.size() <= 7 else 18)
				var ll := UITheme.label(label, fs, UITheme.TEXT)
				ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(ll)
				# A card prize has no points on it: it shows as a card.
				if label.begins_with("New card: "):
					label = Loc.t("New card: %s") % Loc.t(label.trim_prefix("New card: "))
					ll.text = label
					ll.add_theme_color_override("font_color", Color("9ff0ff"))
				row2.add_child(UITheme.label(("+%d" % int(line[1])) if int(line[1]) > 0 else "★", fs, UITheme.GOLD, UITheme.semi_font()))
				pv.add_child(row2)
			var rule := ColorRect.new()
			rule.color = Color(UITheme.GOLD, 0.5)
			rule.custom_minimum_size = Vector2(0, 2)
			pv.add_child(rule)
			var tot := HBoxContainer.new()
			var tl := UITheme.label(Loc.t("DUEL POINTS EARNED"), 20, UITheme.GOLD, UITheme.semi_font())
			tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tot.add_child(tl)
			tot.add_child(UITheme.label("+%d" % int(stats.get("earned", 0)), 34, UITheme.GOLD, UITheme.title_font()))
			pv.add_child(tot)
			var have := UITheme.label(Loc.t("You now have %d DP") % Collection.dp, 18, UITheme.TEXT_DIM)
			have.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			pv.add_child(have)
			v.add_child(box)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 14)
		v.add_child(gap)
	# The buttons stand side by side under everything else, so a long list of what the duel paid
	# (medals, streaks, a card) can never push one of them off the bottom of the screen.
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 14)
	v.add_child(bar)
	var first: Button
	if story:
		if won or lose_ok:
			first = _overlay_button(bar, cont, "story_continue")
		else:
			# A duel the story needs you to win: go again, or step away and come back stronger.
			first = _overlay_button(bar, "Try Again", "rematch")
			if stats.get("task", false):
				_overlay_button(bar, "Back to the world", "story_continue")
			else:
				_overlay_button(bar, "Change deck", "decks")
			_overlay_button(bar, "Quit to Menu", "menu")
	elif not mt.is_empty() and not mt["over"]:
		first = _overlay_button(bar, "Next duel", "next_game")
		if mt.get("side", false):
			_overlay_button(bar, "Side Deck", "side_deck")
		_overlay_button(bar, "Main Menu", "menu")
	elif gauntlet_next:
		first = _overlay_button(bar, "Next opponent", "gauntlet_next")
		_overlay_button(bar, "Main Menu", "menu")
	else:
		first = _overlay_button(bar, "New match" if not mt.is_empty() else ("Run it again" if gauntlet_label != "" else "Rematch"), "rematch")
		if stats.get("free", false):
			_overlay_button(bar, "Change duelists", "select")
		_overlay_button(bar, "Main Menu", "menu")
	first.grab_focus()
	# And if it is still taller than the window (a small window, a very long list), the whole
	# column is made a little smaller instead of running off it.
	await get_tree().process_frame
	if is_instance_valid(v):
		var room := get_viewport_rect().size.y - 36.0
		if v.size.y > room:
			v.pivot_offset = v.size / 2.0
			v.scale = Vector2.ONE * (room / v.size.y)


func show_pause() -> void:
	var v := _overlay_panel("PAUSED", "", Color.WHITE)
	var first := _overlay_button(v, "Resume", "resume")
	_overlay_button(v, "Settings", "settings")
	_overlay_button(v, "Surrender", "surrender")
	_overlay_button(v, "Main Menu", "menu")
	first.grab_focus()


func hide_overlay() -> void:
	_clear_overlay()


func overlay_visible() -> bool:
	return _overlay != null
