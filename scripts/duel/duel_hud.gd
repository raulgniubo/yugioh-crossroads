class_name DuelHUD
extends Control
## Everything 2D on top of the duel: life points, hand, phase controls,
## card inspector, banners, prompts, action menus and the result screen.

signal hand_card_pressed(inst, at: Vector2)
signal hand_card_hovered(inst)
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
var _phase_labels: Array[Label] = []
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
var _menu: VBoxContainer
var _banner: Label
var _float_root: Control
var _overlay: Control
var player_names := ["You", "Opponent"]
var portrait_keys := ["player", "kaiba"]
var _portraits: Array[TextureRect] = [null, null]
var _plates: Array[PanelContainer] = [null, null]
var _bubbles: Array[PanelContainer] = [null, null]
var _bubble_labels: Array[Label] = [null, null]
var _btn_extra: Button
var _extra_panel: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_plates()
	_build_phase()
	_build_inspector()
	_build_hand()
	_build_prompt()
	var menu_btn := Button.new()
	menu_btn.text = "☰  MENU"
	menu_btn.position = Vector2(36, 30)
	menu_btn.custom_minimum_size = Vector2(150, 52)
	menu_btn.pressed.connect(func(): pause_action.emit("open"))
	add_child(menu_btn)
	_float_root = Control.new()
	_float_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_float_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_float_root)
	_menu = VBoxContainer.new()
	_menu.z_index = 50
	_menu.visible = false
	_menu.add_theme_constant_override("separation", 6)
	add_child(_menu)
	_banner = UITheme.label("", 110, Color.WHITE, UITheme.title_font())
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_shadow_color", Color(UITheme.ACCENT, 0.6))
	_banner.add_theme_constant_override("shadow_outline_size", 28)
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)


# ------------------------------------------------------------------ plates

func _plate(p: int) -> PanelContainer:
	var col := UITheme.ACCENT if p == 0 else Color("8a6dff")
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.84), 18, Color(col, 0.4))
	sb.set_content_margin_all(12)
	pc.add_theme_stylebox_override("panel", sb)
	if p == 1:
		# Clicking the opponent's plate while aiming an attack is a direct attack too.
		pc.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				direct_attack_pressed.emit())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	pc.add_child(h)
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(118, 148)
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.02, 0.03, 0.06, 1)
	fsb.set_corner_radius_all(14)
	fsb.border_color = col
	fsb.set_border_width_all(2)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	h.add_child(frame)
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.pivot_offset = Vector2(59, 74)
	frame.add_child(portrait)
	_portraits[p] = portrait
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	var name_l := UITheme.label(player_names[p].to_upper(), 24, UITheme.TEXT_DIM, UITheme.semi_font())
	name_l.name = "Name"
	v.add_child(name_l)
	var lp := UITheme.label("8000", 58, Color.WHITE, UITheme.title_font())
	v.add_child(lp)
	_lp_labels[p] = lp
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.08)
	bar_bg.custom_minimum_size = Vector2(250, 6)
	v.add_child(bar_bg)
	var bar := ColorRect.new()
	bar.color = col
	bar.size = Vector2(250, 6)
	bar_bg.add_child(bar)
	_lp_bars[p] = bar
	var counts := UITheme.label("", 16, UITheme.TEXT_DIM)
	counts.mouse_filter = Control.MOUSE_FILTER_STOP
	counts.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	counts.tooltip_text = "See the Graveyard and banished cards"
	counts.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			show_piles(p))
	v.add_child(counts)
	_count_labels[p] = counts
	add_child(pc)
	_plates[p] = pc
	# Speech bubble
	var bubble := PanelContainer.new()
	var bsb := UITheme.panel_box(Color(0.96, 0.98, 1.0, 0.97), 16, Color(col, 0.0))
	bsb.content_margin_left = 20
	bsb.content_margin_right = 20
	bsb.content_margin_top = 12
	bsb.content_margin_bottom = 12
	bubble.add_theme_stylebox_override("panel", bsb)
	var bl := UITheme.label("", 22, Color("0b1020"), UITheme.semi_font())
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(300, 0)
	bubble.add_child(bl)
	bubble.modulate.a = 0.0
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	_bubbles[p] = bubble
	_bubble_labels[p] = bl
	return pc


func _build_plates() -> void:
	var opp := _plate(1)
	opp.anchor_left = 1.0
	opp.anchor_right = 1.0
	opp.offset_left = -456
	opp.offset_right = -36
	opp.offset_top = 30
	var me := _plate(0)
	me.anchor_top = 1.0
	me.anchor_bottom = 1.0
	me.offset_left = 36
	me.offset_top = -206
	me.offset_bottom = -30
	_bubbles[1].anchor_left = 1.0
	_bubbles[1].anchor_right = 1.0
	_bubbles[1].offset_left = -500
	_bubbles[1].offset_right = -120
	_bubbles[1].offset_top = 216
	_bubbles[0].anchor_top = 1.0
	_bubbles[0].anchor_bottom = 1.0
	_bubbles[0].offset_left = 160
	_bubbles[0].offset_right = 540
	_bubbles[0].offset_top = -300


func set_names(a: String, b: String) -> void:
	player_names = [a, b]
	for i in 2:
		var lbl := _lp_labels[i].get_parent().get_node("Name") as Label
		lbl.text = player_names[i].to_upper()


func set_portraits(a: String, b: String) -> void:
	portrait_keys = [a, b]
	for i in 2:
		_portraits[i].texture = Portraits.get_portrait(portrait_keys[i])


## A short line in a speech bubble next to the duelist. Doesn't block.
func say(p: int, text: String) -> void:
	if text == "":
		return
	var b := _bubbles[p]
	_bubble_labels[p].text = text
	b.reset_size()
	await get_tree().process_frame
	var sz := b.get_combined_minimum_size()
	if p == 1:
		b.offset_right = -40
		b.offset_left = -40 - sz.x
		b.offset_top = 222
		b.offset_bottom = 222 + sz.y
	else:
		b.offset_left = 36
		b.offset_right = 36 + sz.x
		b.offset_bottom = -222
		b.offset_top = -222 - sz.y
	b.size = sz
	b.pivot_offset = Vector2(0 if p == 0 else b.size.x, b.size.y if p == 0 else 0)
	b.scale = Vector2(0.85, 0.85)
	if b.has_meta("tw"):
		var old: Tween = b.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	var tw := create_tween()
	b.set_meta("tw", tw)
	tw.set_parallel()
	tw.tween_property(b, "modulate:a", 1.0, 0.15)
	tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(2.4)
	tw.chain().tween_property(b, "modulate:a", 0.0, 0.3)


## Portrait reaction: shake on damage, pulse on big moments.
func react(p: int, kind: String) -> void:
	var pt := _portraits[p]
	var tw := create_tween()
	if kind == "hurt":
		pt.modulate = Color(1.6, 0.6, 0.6)
		for i in 6:
			tw.tween_property(pt, "position:x", (8.0 if i % 2 == 0 else -8.0), 0.04)
		tw.tween_property(pt, "position:x", 0.0, 0.04)
		tw.parallel().tween_property(pt, "modulate", Color.WHITE, 0.4)
	else:
		tw.tween_property(pt, "scale", Vector2(1.12, 1.12), 0.15)
		tw.tween_property(pt, "scale", Vector2.ONE, 0.3)


## [graveyard, banished] card lists per player, kept fresh by the scene for the pile viewer.
var piles: Array = [[[], []], [[], []]]
var _pile_panel: Control


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
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.06, 0.11, 0.97), 22, Color(UITheme.ACCENT, 0.4)))
	_pile_panel.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var who: String = str(player_names[p]) if player_names.size() > p else ("You" if p == 0 else "Opponent")
	v.add_child(UITheme.label(who.to_upper(), 20, UITheme.TEXT_DIM, UITheme.semi_font()))
	var titles := ["GRAVEYARD", "BANISHED"]
	var cols := [UITheme.ACCENT, Color("b06cff")]
	for k in 2:
		var list: Array = piles[p][k]
		v.add_child(UITheme.label("%s  ·  %d" % [titles[k], list.size()], 34, cols[k], UITheme.title_font()))
		if list.is_empty():
			v.add_child(UITheme.label("Empty" if k == 0 else "No cards have been banished.", 18, UITheme.TEXT_DIM))
			continue
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(1080, 196)
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		v.add_child(sc)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		sc.add_child(row)
		for i in range(list.size() - 1, -1, -1):
			var inst = list[i]
			var tr := TextureRect.new()
			tr.texture = Cards.get_face(inst.id)
			tr.custom_minimum_size = Vector2(124, 181)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.mouse_filter = Control.MOUSE_FILTER_STOP
			tr.mouse_entered.connect(func(): inspect(inst))
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
	var tw := create_tween()
	tw.tween_method(func(v: float): lbl.text = str(int(round(v))), from, float(lp), Settings.t(0.7))
	var bar := _lp_bars[p]
	create_tween().tween_property(bar, "size:x", 250.0 * clampf(lp / 8000.0, 0.0, 1.0), Settings.t(0.7))
	var col := UITheme.DANGER if delta < 0 else Color("4fd18b")
	lbl.add_theme_color_override("font_color", col)
	create_tween().tween_method(func(c: Color): lbl.add_theme_color_override("font_color", c), col, Color.WHITE, Settings.t(1.0))
	_float_number(p, delta)


func _float_number(p: int, delta: int) -> void:
	var l := UITheme.label(("%+d" % delta), 84, UITheme.DANGER if delta < 0 else Color("4fd18b"), UITheme.title_font())
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 14)
	var vs := get_viewport_rect().size
	l.position = Vector2(vs.x * 0.5 - 120, vs.y * (0.62 if p == 0 else 0.22))
	_float_root.add_child(l)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 90, Settings.t(1.1)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, Settings.t(0.5)).set_delay(Settings.t(0.7))
	tw.chain().tween_callback(l.queue_free)


# ------------------------------------------------------------------ phases

func _build_phase() -> void:
	var box := VBoxContainer.new()
	_phase_box = box
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -330
	box.offset_right = -36
	box.offset_top = -170
	box.offset_bottom = 230
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", 6)
	pills.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(pills)
	for txt in ["DP", "SP", "M1", "BP", "M2", "EP"]:
		var l := UITheme.label(txt, 20, UITheme.TEXT_DIM, UITheme.semi_font())
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(43, 36)
		l.add_theme_stylebox_override("normal", _pill_box(Color(0.05, 0.08, 0.13, 0.8)))
		pills.add_child(l)
		_phase_labels.append(l)
	_btn_battle = Button.new()
	_btn_battle.text = "Battle Phase"
	_btn_battle.custom_minimum_size = Vector2(294, 58)
	_btn_battle.pressed.connect(func(): phase_button.emit("battle"))
	box.add_child(_btn_battle)
	_btn_end = Button.new()
	_btn_end.text = "End Turn"
	_btn_end.custom_minimum_size = Vector2(294, 58)
	_btn_end.pressed.connect(func(): phase_button.emit("end"))
	box.add_child(_btn_end)
	_btn_extra = Button.new()
	_btn_extra.text = "Extra Deck"
	_btn_extra.custom_minimum_size = Vector2(294, 50)
	_btn_extra.add_theme_color_override("font_color", Color("ffd23a"))
	_btn_extra.pressed.connect(func(): extra_pressed.emit())
	_btn_extra.visible = false
	box.add_child(_btn_extra)
	# Each phase of either turn is a chance to use Set cards and Quick-Play Spells. This switches
	# those reminders off for players who only want to be asked about attacks, summons and chains.
	var ask := CheckButton.new()
	ask.text = "Pause in every phase"
	ask.button_pressed = phase_prompts
	ask.add_theme_font_size_override("font_size", 17)
	for col in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		ask.add_theme_color_override(col, UITheme.TEXT)
	ask.tooltip_text = "On: the duel stops in the Draw, Standby, Battle and End Phase whenever one of your Set cards or Quick-Play Spells could be used there.\nOff: you are only asked during summons, attacks and chains."
	ask.toggled.connect(func(on): phase_prompts = on)
	box.add_child(ask)
	var ask_help := UITheme.label("Stops the duel when a Set card could be used. Off = only during attacks and chains.", 14, UITheme.TEXT_DIM)
	ask_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask_help.custom_minimum_size = Vector2(294, 0)
	box.add_child(ask_help)


func set_phase(phase: int, my_turn: bool) -> void:
	# Pills run Draw, Standby, Main 1, Battle, Main 2, End.
	var slot: int = {DuelState.Phase.DRAW: 0, DuelState.Phase.STANDBY: 1, DuelState.Phase.MAIN1: 2, DuelState.Phase.BATTLE: 3,
			DuelState.Phase.MAIN2: 4, DuelState.Phase.END: 5}.get(phase, 0)
	for i in _phase_labels.size():
		var on := i == slot
		var l := _phase_labels[i]
		l.add_theme_color_override("font_color", UITheme.BG if on else UITheme.TEXT_DIM)
		var col: Color = (UITheme.ACCENT if my_turn else Color("8a6dff")) if on else Color(0.05, 0.08, 0.13, 0.8)
		l.add_theme_stylebox_override("normal", _pill_box(col))


func _pill_box(col: Color) -> StyleBoxFlat:
	var sb := UITheme.button_box(col, Color(1, 1, 1, 0.08), 8)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb


# ------------------------------------------------------------------ Turbo Duel: Speed Counters

func _process(delta: float) -> void:
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_phase_box.add_child(row)
	_phase_box.move_child(row, 0)
	_phase_box.offset_top -= 170
	for p in [1, 0]:
		var g := Control.new()
		g.custom_minimum_size = Vector2(144, 150)
		g.draw.connect(func(): _draw_gauge(g, p))
		g.tooltip_text = "Speed Counters. Both riders gain 1 each Standby Phase and lose 1 for every 1000 damage taken at once."
		row.add_child(g)
		_gauges.append([g, p])
	_btn_speed = Button.new()
	_btn_speed.text = "Speed World 2"
	_btn_speed.custom_minimum_size = Vector2(294, 50)
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
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.06, 0.11, 0.97), 22, Color("ffd23a", 0.4)))
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
		tr.stretch_mode = TextureRect.STRETCH_SCALE
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
	var l := UITheme.label(text, 72, Color.WHITE, UITheme.title_font())
	l.add_theme_color_override("font_shadow_color", Color(color, 0.9))
	l.add_theme_constant_override("shadow_outline_size", 22)
	l.size = Vector2(vs.x, 120)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position.x = vs.x * 0.25
	l.modulate.a = 0.0
	band.add_child(l)
	Sfx.play("turn", -2.0, 1.25)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(band, "color:a", 0.22, Settings.t(0.15))
	tw.tween_property(line_top, "size:x", vs.x, Settings.t(0.35))
	tw.tween_property(line_bot, "size:x", vs.x, Settings.t(0.35))
	tw.tween_property(line_bot, "position:x", 0.0, Settings.t(0.35))
	tw.tween_property(l, "position:x", 0.0, Settings.t(0.35))
	tw.tween_property(l, "modulate:a", 1.0, Settings.t(0.2))
	tw.chain().tween_interval(Settings.t(0.35))
	tw.chain().tween_property(band, "modulate:a", 0.0, Settings.t(0.25))
	await tw.finished
	band.queue_free()


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
	_inspect_panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.1, 0.92), 20, Color(UITheme.ACCENT, 0.25)))
	_inspect_panel.anchor_top = 0.5
	_inspect_panel.anchor_bottom = 0.5
	_inspect_panel.offset_left = 30
	_inspect_panel.offset_right = 390
	_inspect_panel.offset_top = -390
	_inspect_panel.offset_bottom = 300
	_inspect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inspect_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_inspect_panel.add_child(v)
	_inspect_tex = TextureRect.new()
	_inspect_tex.custom_minimum_size = Vector2(320, 330)
	_inspect_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_inspect_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(_inspect_tex)
	_inspect_name = UITheme.label("", 28, Color.WHITE, UITheme.title_font())
	_inspect_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect_name.custom_minimum_size = Vector2(320, 0)
	_inspect_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_inspect_name)
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
	_inspect_text = UITheme.label("", 15, UITheme.TEXT_DIM)
	_inspect_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect_text.custom_minimum_size = Vector2(320, 0)
	_inspect_text.max_lines_visible = 9
	_inspect_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_inspect_text)
	# Only shown when this game plays the card differently from what the card says.
	_inspect_note = UITheme.label("", 15, Color("ffcf6b"), UITheme.semi_font())
	_inspect_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect_note.custom_minimum_size = Vector2(320, 0)
	_inspect_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inspect_note.visible = false
	v.add_child(_inspect_note)
	_inspect_panel.modulate.a = 0.0


func _stat_box(title: String, col: Color) -> Label:
	var box := PanelContainer.new()
	var sb := UITheme.button_box(Color(col, 0.12), Color(col, 0.55), 12)
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
	var l := UITheme.label(text, 15, col.lightened(0.3), UITheme.semi_font())
	var sb := UITheme.button_box(Color(col, 0.15), Color(col, 0.5), 10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", sb)
	_inspect_chips.add_child(l)


func inspect(inst, hidden := false) -> void:
	if inst == null:
		return
	if _inspect_panel.modulate.a < 0.99:
		create_tween().tween_property(_inspect_panel, "modulate:a", 1.0, 0.15)
	for c in _inspect_chips.get_children():
		c.queue_free()
	_inspect_note.visible = false
	if hidden:
		_inspect_tex.texture = Cards.get_back()
		_inspect_name.text = "Face-down card"
		_inspect_stat_row.visible = false
		_inspect_text.text = "You don't know what this is yet."
		return
	var d: Dictionary = inst.data
	_inspect_tex.texture = Cards.get_face(inst.id)
	_inspect_name.text = d.get("name", "")
	if d.get("kind", "monster") == "monster":
		var frame: String = d.get("frame", "normal")
		var lv_word := "Rank" if frame == "xyz" else "Level"
		_chip("%s %d" % [lv_word, int(d.get("level", 0))], Color("ffd23a"))
		_chip(str(d.get("attribute", "")), Cards.ATTRIBUTE_COLORS.get(d.get("attribute", ""), [Color.GRAY, Color.GRAY])[1])
		_chip(str(d.get("race", "")), UITheme.ACCENT)
		_chip(frame.capitalize() + (" Tuner" if d.get("tuner", false) else ""), Color("b0b8c8"))
		_inspect_stat_row.visible = true
		_inspect_atk.text = str(d.get("atk", 0))
		_inspect_def.text = str(d.get("def", 0))
		var txt := str(d.get("desc", ""))
		var nm := str(d.get("name", ""))
		var note := str(CardEffects.of(nm).get("note", CardData.MONSTER_EFFECTS.get(nm, "")))
		if note == "" and (frame == "effect" or (frame in ["synchro", "xyz", "fusion"] and txt.length() > 80)):
			_inspect_note.text = Loc.t("Not in this game yet: this card plays with its ATK and DEF only.")
			_inspect_note.visible = true
		_inspect_text.text = txt if txt != "" else "Normal Monster"
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
		_inspect_text.text = body
		if SpellRules.spec(inst).is_empty():
			_inspect_note.text = Loc.t("Not in this game yet: you can still Set it as a bluff.")
			_inspect_note.visible = true


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
	var glow := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = UITheme.ACCENT
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.expand_margin_left = 4
	sb.expand_margin_right = 4
	sb.expand_margin_top = 4
	sb.expand_margin_bottom = 4
	glow.add_theme_stylebox_override("panel", sb)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.visible = false
	glow.name = "Glow"
	tr.add_child(glow)
	tr.position = Vector2(300, -80)
	tr.modulate.a = 0.0
	_hand_root.add_child(tr)
	var entry := {"inst": inst, "node": tr}
	_hand.append(entry)
	tr.mouse_entered.connect(func():
		_hand_hover = _hand.find(entry)
		hand_card_hovered.emit(inst)
		_layout_hand())
	tr.mouse_exited.connect(func():
		if _hand_hover == _hand.find(entry):
			_hand_hover = -1
		_layout_hand())
	tr.gui_input.connect(func(e):
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
			hand_card_pressed.emit(inst, tr.global_position + Vector2(tr.size.x / 2.0, 0)))
	_layout_hand()


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
	for e in _hand:
		(e["node"].get_node("Glow") as Panel).visible = _playable.has(e["inst"])


func _layout_hand() -> void:
	var n := _hand.size()
	var spacing := minf(HAND_CARD.x * 0.82, 1050.0 / maxf(n, 1))
	for i in n:
		var node: Control = _hand[i]["node"]
		var offset := i - (n - 1) / 2.0
		var hovered: bool = i == _hand_hover or _hand[i]["inst"] == _focused
		var target := Vector2(offset * spacing - HAND_CARD.x / 2.0, -HAND_CARD.y * 0.72 + absf(offset) * 6.0)
		var rot := deg_to_rad(offset * 2.5)
		var sc := 1.0
		if hovered:
			target.y = -HAND_CARD.y - 40
			rot = 0.0
			sc = 1.18
		node.z_index = 10 if hovered else i
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "position", target, 0.18)
		tw.tween_property(node, "rotation", rot, 0.18)
		tw.tween_property(node, "scale", Vector2(sc, sc), 0.18)
		tw.tween_property(node, "modulate:a", 1.0, 0.18)


# ------------------------------------------------------------------ prompts & menus

func _build_prompt() -> void:
	_prompt = PanelContainer.new()
	_prompt.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.92), 16, Color(UITheme.ACCENT, 0.5)))
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
	_btn_direct.pressed.connect(func(): direct_attack_pressed.emit())
	h.add_child(_btn_direct)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(func(): cancel_pressed.emit())
	h.add_child(cancel)
	_prompt.visible = false


func show_prompt(text: String, direct := false, direct_label := "Direct Attack") -> void:
	_prompt_label.text = text
	_btn_direct.text = direct_label
	_btn_direct.visible = direct
	_prompt.visible = true
	_prompt.reset_size()
	_prompt.offset_left = -_prompt.size.x / 2.0
	_prompt.offset_right = _prompt.size.x / 2.0


func hide_prompt() -> void:
	_prompt.visible = false


## Ask the player whether to respond with one of `options` (cards). Returns the card or null.
## Pick one card from a list (targets, materials...). `hidden` cards are shown face-down.
## `labels` (uid -> text) adds a caption under each card, e.g. where it is. An empty `cancel` means the pick is required.
func ask_pick(text: String, options: Array, button := "Select", cancel := "Cancel", hidden: Array = [], labels := {}):
	return await ask_response(text, options, button, cancel, hidden, Color("7fd8ff"), labels)


signal _choice_picked(index: int)
## Dev: answer every prompt at random (the --human-test run that exercises the manual path).
var auto_answer := false
var phase_prompts := true


## A question with a few labelled answers (a position, yes / no, go first or second). Returns the index.
func ask_choice(text: String, answers: Array, card = null) -> int:
	if auto_answer:
		await get_tree().process_frame
		return randi() % answers.size()
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.06, 0.11, 0.97), 22, Color(UITheme.ACCENT, 0.7)))
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
		b.pressed.connect(func(): _choice_picked.emit(i))
		v.add_child(b)
	root.reset_size()
	await get_tree().process_frame
	var vs := get_viewport_rect().size
	root.position = Vector2((vs.x - root.size.x) / 2.0, vs.y * 0.3)
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.15)
	if first:
		first.grab_focus()
	var idx: int = await _choice_picked
	root.queue_free()
	return idx


func ask_response(text: String, options: Array, button := "Activate", cancel := "Don't activate", hidden: Array = [], tint := Color("ff4dd2"), labels := {}):
	if auto_answer:
		await get_tree().process_frame
		return null if (cancel != "" and randf() < 0.3) or options.is_empty() else options[randi() % options.size()]
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.06, 0.02, 0.08, 0.97) if tint == Color("ff4dd2") else Color(0.03, 0.06, 0.11, 0.97), 22, Color(tint, 0.7)))
	root.z_index = 60
	add_child(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	root.add_child(v)
	var t := UITheme.label(text, 30, Color.WHITE, UITheme.title_font())
	v.add_child(t)
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
		tr.texture = Cards.get_back() if secret else Cards.get_face(c.id)
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
	return choice


## Small floating callout for card effects.
func effect_text(text: String, color := Color("ffd23a")) -> void:
	var l := UITheme.label(text, 30, Color.WHITE, UITheme.semi_font())
	var sb := UITheme.button_box(Color(0.03, 0.04, 0.08, 0.92), color, 16)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	l.add_theme_stylebox_override("normal", sb)
	l.z_index = 40
	add_child(l)
	l.reset_size()
	var vs := get_viewport_rect().size
	l.position = Vector2((vs.x - l.size.x) / 2.0, vs.y * 0.24)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.tween_interval(Settings.t(1.3))
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


const ACTION_ICONS := {
	"summon": "▲", "set": "▼", "activate": "✦", "flip": "⟳", "position": "⟲",
	"attack": "⚔", "direct": "⚔", "fuse": "✸",
}
var _focused = null


## options: [[action_id, label, enabled], ...]  Pill buttons that pop out beside `at`.
## `at` is the right edge / vertical middle of the card that was tapped.
func show_actions(at: Vector2, options: Array) -> void:
	for c in _menu.get_children():
		_menu.remove_child(c)
		c.queue_free()
	_menu.add_theme_constant_override("separation", 8)
	var i := 0
	for o in options:
		var id: String = o[0]
		var key := id.split(":")[0]
		var b := Button.new()
		b.text = "%s   %s" % [ACTION_ICONS.get(key, "•"), o[1]]
		b.disabled = not o[2]
		b.custom_minimum_size = Vector2(250, 56)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 25)
		var col: Color = UITheme.DANGER if key in ["attack", "direct"] else (Color("ffd23a") if key == "fuse" else UITheme.ACCENT)
		var normal := UITheme.button_box(Color(0.03, 0.06, 0.11, 0.97), Color(col, 0.7), 28)
		normal.shadow_color = Color(0, 0, 0, 0.55)
		normal.shadow_size = 12
		var hover := UITheme.button_box(Color(col, 0.3), col, 28)
		hover.set_border_width_all(3)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("focus", hover)
		b.add_theme_stylebox_override("pressed", UITheme.button_box(col, col, 28))
		b.pressed.connect(func():
			hide_actions()
			action_chosen.emit(id))
		_menu.add_child(b)
		b.modulate.a = 0.0
		b.position.x = -30
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "modulate:a", 1.0, 0.1).set_delay(i * 0.03)
		i += 1
	_menu.visible = true
	_menu.reset_size()
	var sz := _menu.get_combined_minimum_size()
	var vs := get_viewport_rect().size
	var x := at.x + 24
	if x + sz.x > vs.x - 10:
		x = at.x - sz.x - 200
	_menu.position = Vector2(clampf(x, 10, vs.x - sz.x - 10), clampf(at.y - sz.y / 2.0, 10, vs.y - sz.y - 10))
	_menu.modulate.a = 1.0
	var slide := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := _menu.position
	_menu.position.x -= 24
	slide.tween_property(_menu, "position", target, 0.14)
	Sfx.play("hover", -8.0, 1.3)
	for c in _menu.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			break


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
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 40
	add_child(root)
	var vs := get_viewport_rect().size
	var bar_h := 120.0
	var bars: Array[ColorRect] = []
	for top in [true, false]:
		var b := ColorRect.new()
		b.color = Color(0, 0, 0, 0.92)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.size = Vector2(vs.x, bar_h)
		b.position = Vector2(0, -bar_h if top else vs.y)
		root.add_child(b)
		bars.append(b)
	var stripe := ColorRect.new()
	stripe.color = Color(color, 0.85)
	stripe.size = Vector2(vs.x, 4)
	stripe.position = Vector2(0, vs.y - bar_h - 2)
	stripe.modulate.a = 0.0
	root.add_child(stripe)
	var name_l := UITheme.label(card_name.to_upper(), 76, Color.WHITE, UITheme.title_font())
	name_l.add_theme_color_override("font_outline_color", Color(color, 0.9))
	name_l.add_theme_constant_override("outline_size", 10)
	name_l.position = Vector2(-900 if mine else vs.x + 100, vs.y - bar_h - 150)
	root.add_child(name_l)
	var stats := UITheme.label(Loc.t("ATK %d   ·   DEF %d") % [atk, def], 30, Color(color.lightened(0.4)), UITheme.semi_font())
	stats.position = Vector2(vs.x * 0.08, vs.y - bar_h + 38)
	stats.modulate.a = 0.0
	root.add_child(stats)
	await get_tree().process_frame
	var target_x := vs.x * 0.08 if mine else vs.x * 0.92 - name_l.size.x
	if not mine:
		stats.position.x = vs.x * 0.92 - 360
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bars[0], "position:y", 0.0, Settings.t(0.3))
	tw.tween_property(bars[1], "position:y", vs.y - bar_h, Settings.t(0.3))
	tw.tween_property(stripe, "modulate:a", 1.0, Settings.t(0.3))
	tw.tween_property(name_l, "position:x", target_x, Settings.t(0.45)).set_delay(Settings.t(0.1))
	tw.tween_property(stats, "modulate:a", 1.0, Settings.t(0.3)).set_delay(Settings.t(0.35))
	await tw.finished
	await get_tree().create_timer(Settings.t(1.0)).timeout
	var out := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	out.tween_property(bars[0], "position:y", -bar_h, Settings.t(0.3))
	out.tween_property(bars[1], "position:y", vs.y, Settings.t(0.3))
	out.tween_property(root, "modulate:a", 0.0, Settings.t(0.3))
	await out.finished
	root.queue_free()


func banner(text: String, color := Color.WHITE) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.reset_size()
	var vs := get_viewport_rect().size
	_banner.position = Vector2((vs.x - _banner.size.x) / 2.0 - 60, vs.y * 0.4 - _banner.size.y / 2.0)
	var x := _banner.position.x
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(_banner, "modulate:a", 1.0, Settings.t(0.2))
	tw.tween_property(_banner, "position:x", x + 60, Settings.t(0.35)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(Settings.t(0.55))
	tw.chain().tween_property(_banner, "modulate:a", 0.0, Settings.t(0.25))
	await tw.finished


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
	add_child(_overlay)
	if side:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.42, 0.7, 1.0])
		grad.colors = PackedColorArray([Color(0.01, 0.02, 0.04, 0.0), Color(0.01, 0.02, 0.04, 0.25), Color(0.01, 0.02, 0.04, 0.86), Color(0.01, 0.02, 0.04, 0.94)])
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
		dim.color = Color(0.01, 0.02, 0.04, 0.78)
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
	var t := UITheme.label(title, 120, title_color, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_shadow_color", Color(title_color, 0.5))
	t.add_theme_constant_override("shadow_outline_size", 30)
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


func _overlay_button(v: VBoxContainer, text: String, action: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 60)
	b.pressed.connect(func(): pause_action.emit(action))
	var c := CenterContainer.new()
	c.add_child(b)
	v.add_child(c)
	return b


func show_result(won: bool, reason: String, story := false, lose_ok := false, cont := "Continue Story", stats := {}) -> void:
	for n in [_phase_box, _inspect_panel, _hand_root]:
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
			Color.WHITE if tied else (UITheme.ACCENT if won else UITheme.DANGER), true)
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
		for item in [["TURNS", str(stats.get("turns", 0)), Color.WHITE], ["YOUR LP", str(lp[0]), UITheme.ACCENT], ["THEIR LP", str(lp[1]), UITheme.DANGER]]:
			var box := PanelContainer.new()
			box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.9), 14, Color(item[2], 0.35)))
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
				var ll := UITheme.label(label, 22, UITheme.TEXT)
				ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(ll)
				row2.add_child(UITheme.label("+%d" % int(line[1]), 22, UITheme.GOLD, UITheme.semi_font()))
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
	var first: Button
	if story:
		if won or lose_ok:
			first = _overlay_button(v, cont, "story_continue")
		else:
			first = _overlay_button(v, "Try Again", "rematch")
			_overlay_button(v, "Quit to Menu", "menu")
	elif not mt.is_empty() and not mt["over"]:
		first = _overlay_button(v, "Next duel", "next_game")
		if mt.get("side", false):
			_overlay_button(v, "Side Deck", "side_deck")
		_overlay_button(v, "Main Menu", "menu")
	else:
		first = _overlay_button(v, "New match" if not mt.is_empty() else "Rematch", "rematch")
		if stats.get("free", false):
			_overlay_button(v, "Change duelists", "select")
		_overlay_button(v, "Main Menu", "menu")
	first.grab_focus()


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
