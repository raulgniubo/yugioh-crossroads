class_name CharacterSelect
extends Control
## Free Duel setup. Two big duelist panels face each other across a VS; the roster sits
## underneath; deck, difficulty and arena sit on the right. Tap a panel (YOU / OPPONENT)
## to say who you are choosing, then tap a duelist.

signal start(config: Dictionary)
signal closed

const W := 1920.0
const H := 1080.0
const PANEL_SIZE := Vector2(506, 438)
const CELL := Vector2(113, 132)

var _me := "player"
var _opp := "kaiba"
var _picking := "opp"
var _era := ""
var _difficulty := 1
var _their_pick: OptionButton
var _their_keys: Array = []
var _their_deck := ""
var _lp := 8000
var _first := -1           # -1 play the opening game, 0 me, 1 them
var _gauntlet := false
var _run := 0               # 0 single, 1 gauntlet of three, 2 survival
var _hand_n := 5
var _match_btn: CheckButton
var _turbo_btn: CheckButton
var _my_deck := "yugi"
var _field := "auto"
var _root: Control
var _backdrop: Control
var _grid: GridContainer
var _slots := {}
var _tabs: Array[Button] = []
var _diff_btns: Array[Button] = []
var _deck_pick: OptionButton
var _deck_keys: Array = []
var _deck_row: HBoxContainer
var _deck_note: Label
var _diff_note: Label
var _field_name: Label
var _field_swatch: ColorRect
var _quote: Label
var _reward: Label
var _vs: Label
var _go: Button
var _starting := false
var _t := 0.0
var _pending: Array = []      # [TextureRect, key]: roster portraits still to load, a couple per frame
var _retouch := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cfg: Dictionary = Router.duel_config
	_me = cfg.get("player_char", "player")
	_opp = cfg.get("opponent", "kaiba")
	if not Characters.available(_opp):
		for k in Characters.ORDER:
			if Characters.available(k):
				_opp = k
				break
	_difficulty = clampi(int(cfg.get("difficulty", 1)), 1, 3)
	_my_deck = cfg.get("player_deck", "yugi")
	if not CardData.has_deck(_my_deck):
		_my_deck = "echo" if CardData.has_deck("echo") else "yugi"
	_field = str(cfg.get("field", Settings.field_theme))
	if _field != "auto" and not FieldThemes.THEMES.has(_field):
		_field = "auto"
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.2, 0.62, 0.985)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_backdrop = Control.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.draw.connect(_draw_backdrop)
	add_child(_backdrop)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	resized.connect(_center)
	_center()
	# A clear way out, top left.
	var top_back := Button.new()
	top_back.text = "◀  Back"
	top_back.add_theme_font_size_override("font_size", 18)
	top_back.position = Vector2(64, 48)
	top_back.size = Vector2(104, 40)
	top_back.tooltip_text = "Back to the main menu (Esc)"
	top_back.pressed.connect(close)
	_root.add_child(top_back)
	var header := UITheme.label("FREE DUEL", 64, Color.WHITE, Comic.shout_font())
	header.add_theme_color_override("font_outline_color", Comic.INK)
	header.add_theme_constant_override("outline_size", 16)
	header.rotation = -0.02
	header.position = Vector2(188, 26)
	_root.add_child(header)
	var bar := ColorRect.new()
	bar.color = UITheme.ACCENT
	bar.position = Vector2(190, 98)
	bar.size = Vector2(118, 4)
	_root.add_child(bar)
	_build_picker()
	_build_slots()
	_build_setup()
	_build_tabs()
	_grid = GridContainer.new()
	# Nine across, three rows: the roster owns the bottom left and never reaches the setup
	# column on the right.
	_grid.columns = 9
	_grid.position = Vector2(64, 632)
	_grid.add_theme_constant_override("h_separation", 7)
	_grid.add_theme_constant_override("v_separation", 7)
	_root.add_child(_grid)
	_refresh_all()
	_enter()


func _center() -> void:
	if _root:
		_root.position = ((size - Vector2(W, H)) / 2.0).max(Vector2.ZERO)
	if _backdrop:
		_backdrop.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _vs:
		var s := 1.0 + sin(_t * 2.4) * 0.04
		_vs.scale = Vector2(s, s)
	# Portraits load a couple per frame, so the screen opens at once and fills in.
	for i in 2:
		if _pending.is_empty():
			break
		var job: Array = _pending.pop_front()
		if is_instance_valid(job[0]):
			(job[0] as TextureRect).texture = Portraits.get_portrait(job[1])
			(job[0] as TextureRect).modulate.a = 0.0
			create_tween().tween_property(job[0], "modulate:a", 1.0, 0.2)
		_retouch = true
	if _pending.is_empty() and _retouch:
		# Asking again keeps the two big portraits among the few that stay animated.
		_retouch = false
		Portraits.get_portrait(_me, true)
		Portraits.get_portrait(_opp, true)
	if _go and not _starting:
		_go.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.25, 1.25), 0.5 + 0.5 * sin(_t * 3.0))


## Two tinted halves split by a slash, in each duelist's color.
func _draw_backdrop() -> void:
	var o := _root.position if _root else Vector2.ZERO
	var a: Color = Portraits.info(_me).get("color", UITheme.ACCENT)
	var b: Color = Portraits.info(_opp).get("color", UITheme.DANGER)
	var mid := o.x + 599.0
	var top := o.y + 104.0
	var bot := o.y + 566.0
	# Two printed halves in the duelists' colors, split by an inked slash.
	var left := PackedVector2Array([Vector2(0, top), Vector2(mid + 70, top), Vector2(mid - 70, bot), Vector2(0, bot)])
	var right := PackedVector2Array([Vector2(mid + 70, top), Vector2(o.x + 1146, top), Vector2(o.x + 1146, bot), Vector2(mid - 70, bot)])
	_backdrop.draw_polygon(left, PackedColorArray([Color(a.darkened(0.2), 0.75), Color(a, 0.8), Color(a.darkened(0.45), 0.85), Color(a.darkened(0.55), 0.8)]))
	_backdrop.draw_polygon(right, PackedColorArray([Color(b, 0.8), Color(b.darkened(0.2), 0.75), Color(b.darkened(0.55), 0.8), Color(b.darkened(0.45), 0.85)]))
	Comic.dots(_backdrop, left, Color(1, 1, 1, 0.12), Vector2(1, 0), 16.0, 7.0, 0.6)
	Comic.dots(_backdrop, right, Color(1, 1, 1, 0.12), Vector2(0, 1), 16.0, 7.0, 0.6)
	_backdrop.draw_line(Vector2(0, top), Vector2(o.x + 1146, top), Comic.INK, 6.0)
	_backdrop.draw_line(Vector2(0, bot), Vector2(o.x + 1146, bot), Comic.INK, 6.0)
	_backdrop.draw_line(Vector2(mid + 70, top), Vector2(mid - 70, bot), Comic.INK, 14.0, true)
	_backdrop.draw_line(Vector2(mid + 70, top), Vector2(mid - 70, bot), Color.WHITE, 6.0, true)


func _enter() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.22)
	for side in _slots:
		var b: Control = _slots[side]["button"]
		var home := b.position
		b.position.x += -160.0 if side == "me" else 160.0
		create_tween().tween_property(b, "position", home, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _vs:
		_vs.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.3)
		tw.tween_property(_vs, "modulate:a", 1.0, 0.18)


# ------------------------------------------------------------------ duelist panels

func _build_slots() -> void:
	for side in ["me", "opp"]:
		var b := Button.new()
		b.flat = true
		b.clip_contents = true
		b.size = PANEL_SIZE
		b.position = Vector2(64 if side == "me" else 628, 116)
		b.pivot_offset = PANEL_SIZE / 2.0
		b.pressed.connect(func():
			_picking = side
			Sfx.play("card", -8.0)
			_refresh_all())
		_root.add_child(b)
		var glow := ColorRect.new()
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(glow)
		# The portrait is taller than the panel: pin it to the top so the face always shows.
		var pt := TextureRect.new()
		pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pt.stretch_mode = TextureRect.STRETCH_SCALE
		pt.size = Vector2(PANEL_SIZE.x, PANEL_SIZE.x * 640.0 / 512.0)
		pt.position = Vector2(0, 6)
		pt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pt.flip_h = side == "opp"
		b.add_child(pt)
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
		grad.colors = PackedColorArray([Color(Comic.INK, 0.0), Color(Comic.INK, 0.0), Color(Comic.INK, 0.9)])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill_from = Vector2(0.5, 0.0)
		gt.fill_to = Vector2(0.5, 1.0)
		var shade := TextureRect.new()
		shade.texture = gt
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(shade)
		var tag_bg := PanelContainer.new()
		tag_bg.position = Vector2(16, 16)
		tag_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tag_bg)
		var tag := UITheme.label("", 18, Color(0.02, 0.04, 0.08), UITheme.title_font())
		tag_bg.add_child(tag)
		var ace := TextureRect.new()
		ace.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ace.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ace.size = Vector2(104, 152)
		ace.position = Vector2(PANEL_SIZE.x - 124, PANEL_SIZE.y - 176)
		ace.pivot_offset = ace.size / 2.0
		ace.rotation = deg_to_rad(6.0)
		ace.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ace)
		var name_l := Comic.label("", 46, Color.WHITE, 10)
		name_l.position = Vector2(20, PANEL_SIZE.y - 132)
		name_l.size = Vector2(PANEL_SIZE.x - 150, 52)
		name_l.clip_text = true
		b.add_child(name_l)
		var title_l := UITheme.label("", 19, UITheme.GOLD, UITheme.semi_font())
		title_l.position = Vector2(22, PANEL_SIZE.y - 80)
		b.add_child(title_l)
		var sub := UITheme.label("", 18, UITheme.TEXT_DIM)
		sub.position = Vector2(22, PANEL_SIZE.y - 52)
		sub.size = Vector2(PANEL_SIZE.x - 150, 24)
		sub.clip_text = true
		b.add_child(sub)
		_slots[side] = {"button": b, "portrait": pt, "name": name_l, "title": title_l, "sub": sub, "tag": tag,
				"tag_bg": tag_bg, "ace": ace, "glow": glow, "key": ""}
	_vs = UITheme.label("VS", 104, Comic.YELLOW, Comic.shout_font())
	_vs.position = Vector2(549, 286)
	_vs.size = Vector2(100, 100)
	_vs.pivot_offset = Vector2(50, 50)
	_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs.add_theme_color_override("font_outline_color", Comic.INK)
	_vs.add_theme_constant_override("outline_size", 22)
	_vs.add_theme_color_override("font_shadow_color", Comic.ORANGE_DEEP)
	_vs.add_theme_constant_override("shadow_offset_x", 5)
	_vs.add_theme_constant_override("shadow_offset_y", 6)
	_vs.add_theme_constant_override("shadow_outline_size", 22)
	_vs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vs)


func _deck_of(side: String) -> String:
	if side == "opp" and _their_deck != "":
		return _their_deck
	return _my_deck if side == "me" else str(Characters.get_char(_opp).get("deck", ""))


## The strongest monster in a deck: what goes on the panel as the duelist's ace.
func _deck_ace(deck_key: String) -> int:
	var best := 0
	var best_atk := -1
	for id in _unique(CardData.extra_list(deck_key) + CardData.deck_list(deck_key)):
		var d := CardData.get_card(id)
		if d.get("kind", "") in ["spell", "trap"]:
			continue
		if int(d.get("atk", 0)) > best_atk:
			best_atk = int(d.get("atk", 0))
			best = id
	return best


func _unique(ids: Array) -> Array:
	var seen := {}
	var out := []
	for id in ids:
		if not seen.has(id):
			seen[id] = true
			out.append(id)
	return out


func _refresh_slots() -> void:
	for side in _slots:
		var key: String = _me if side == "me" else _opp
		var sl: Dictionary = _slots[side]
		var info := Portraits.info(key)
		var col: Color = info.get("color", UITheme.ACCENT)
		var changed: bool = sl["key"] != key
		sl["key"] = key
		sl["portrait"].texture = Portraits.get_portrait(key, true)
		sl["name"].text = str(info.get("name", "")).to_upper()
		sl["title"].text = str(info.get("title", ""))
		var deck_key := _deck_of(side)
		sl["sub"].text = Loc.t("%s  ·  %s Deck") % [info.get("era", ""), CardData.deck_name(deck_key)]
		if side == "opp":
			var rec := Collection.versus(key)
			# Your record against them, and how close you are to earning their deck.
			var bits: Array = [Loc.t("%s Deck") % CardData.deck_name(deck_key)]
			if rec[0] + rec[1] > 0:
				bits.append(Loc.t("%d W  %d L") % [rec[0], rec[1]])
			if rec[0] < 3 and not Collection.decks_owned.has(str(info.get("deck", ""))):
				bits.append(Loc.t("unlocks in %d wins") % (3 - rec[0]))
			sl["sub"].text = "  ·  ".join(bits)
		var ace := 0
		if side == "opp":
			ace = int(Characters.get_char(key).get("ace", 0))
		if ace == 0 or CardData.get_card(ace).is_empty():
			ace = _deck_ace(deck_key)
		sl["ace"].texture = Cards.get_face(ace) if ace != 0 else null
		var active: bool = side == _picking
		var sb := UITheme.button_box(Color(0.054, 0.0996, 0.277, 0.0), col if active else Color(1, 1, 1, 0.16), 20)
		sb.set_border_width_all(4 if active else 1)
		sb.set_content_margin_all(0)
		if active:
			sb.shadow_color = Color(col, 0.45)
			sb.shadow_size = 22
		for st in ["normal", "hover", "pressed", "focus"]:
			sl["button"].add_theme_stylebox_override(st, sb)
		sl["glow"].color = Color(col.darkened(0.55), 0.55)
		var tsb := UITheme.button_box(col if active else Color(1, 1, 1, 0.85), Color(0, 0, 0, 0), 8)
		tsb.content_margin_left = 12
		tsb.content_margin_right = 12
		tsb.content_margin_top = 2
		tsb.content_margin_bottom = 2
		sl["tag_bg"].add_theme_stylebox_override("panel", tsb)
		sl["tag"].text = Loc.t("YOU") if side == "me" else Loc.t("OPPONENT")
		if changed:
			var b: Control = sl["button"]
			b.scale = Vector2(0.96, 0.96)
			create_tween().tween_property(b, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			sl["portrait"].modulate = Color(2.2, 2.2, 2.2)
			create_tween().tween_property(sl["portrait"], "modulate", Color.WHITE, 0.3)
	_backdrop.queue_redraw()


# ------------------------------------------------------------------ roster

var _pick_btns := {}
var _pick_title: Label


## Who the roster is choosing for, said loudly: two big switches over the roster.
func _build_picker() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(604, 580)
	box.add_theme_constant_override("separation", 10)
	_root.add_child(box)
	_pick_title = UITheme.label("", 20, UITheme.TEXT_DIM, UITheme.semi_font())
	_pick_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(_pick_title)
	for side in ["me", "opp"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 42)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func():
			_picking = side
			Sfx.play("card", -8.0)
			_refresh_all())
		box.add_child(b)
		_pick_btns[side] = b


func _refresh_picker() -> void:
	if _pick_title == null:
		return
	_pick_title.text = Loc.t("The roster below changes:")
	for side in _pick_btns:
		var b: Button = _pick_btns[side]
		var on: bool = side == _picking
		var col: Color = Portraits.info(_me if side == "me" else _opp).get("color", UITheme.ACCENT)
		b.text = ("●  " if on else "") + (Loc.t("My duelist") if side == "me" else Loc.t("My opponent"))
		var sb := UITheme._chip_box(col if on else Comic.CREAM)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(fc, Comic.INK)
		b.tooltip_text = "Choose who you play as" if side == "me" else "Choose who you duel against"
	for side in _slots:
		var pb: Control = _slots[side]["button"]
		pb.modulate = Color.WHITE if side == _picking else Color(0.62, 0.64, 0.7)


func _build_tabs() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(64, 580)
	row.add_theme_constant_override("separation", 8)
	_root.add_child(row)
	var tabs := [["", "ALL"]]
	for e in Characters.ERAS:
		tabs.append([e, e.to_upper()])
	for t in tabs:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		var era: String = t[0]
		b.pressed.connect(func():
			_era = era
			_refresh_all())
		row.add_child(b)
		_tabs.append(b)


func _refresh_grid() -> void:
	_pending.clear()
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	# Your own duelist is always the first tile, whoever you are choosing for.
	var keys: Array = ["player"]
	for k in Characters.ORDER:
		if _era == "" or Characters.DATA[k]["era"] == _era:
			keys.append(k)
	var i := 0
	for key in keys:
		var card := _roster_card(key)
		_grid.add_child(card)
		card.modulate.a = 0.0
		create_tween().tween_property(card, "modulate:a", 1.0, 0.14).set_delay(i * 0.01)
		i += 1


func _roster_card(key: String) -> Control:
	var info := Portraits.info(key)
	var ok := key == "player" or Characters.available(key)
	var b := Button.new()
	b.custom_minimum_size = CELL
	b.clip_contents = true
	b.flat = true
	b.tooltip_text = "%s\n%s" % [info.get("name", ""), Loc.t(str(info.get("title", "")))]
	var is_me := key == _me
	var is_opp := key == _opp
	var chosen := (is_me and _picking == "me") or (is_opp and _picking == "opp")
	var col: Color = info.get("color", UITheme.ACCENT)
	for st in ["normal", "hover", "pressed", "focus"]:
		var lit: bool = chosen or st == "hover" or st == "focus"
		var sb := UITheme.button_box(Color(0.07, 0.127, 0.31, 1), col if lit else Color(1, 1, 1, 0.08), 12)
		sb.set_border_width_all(3 if lit else 1)
		sb.set_content_margin_all(0)
		b.add_theme_stylebox_override(st, sb)
	var tint := ColorRect.new()
	tint.color = Color(col.darkened(0.6), 0.7)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tint)
	var pt := TextureRect.new()
	if Portraits._cache.has(key):
		pt.texture = Portraits.get_portrait(key)
	else:
		_pending.append([pt, key])
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.size = Vector2(CELL.x, CELL.x * 640.0 / 512.0)
	pt.position = Vector2(0, 2)
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pt)
	var band := ColorRect.new()
	band.color = Color(Comic.INK, 0.86)
	band.anchor_top = 1.0
	band.anchor_right = 1.0
	band.anchor_bottom = 1.0
	band.offset_top = -28
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(band)
	var n := UITheme.label(("YOU" if key == "player" else str(info.get("short", ""))).to_upper(), 18, Color.WHITE, UITheme.title_font())
	n.position = Vector2(8, 2)
	n.size = Vector2(CELL.x - 12, 26)
	n.clip_text = true
	band.add_child(n)
	var stripe := ColorRect.new()
	stripe.color = col
	stripe.size = Vector2(CELL.x, 3)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(stripe)
	var badges := []
	if is_me:
		badges.append(["YOU", UITheme.ACCENT])
	if is_opp:
		badges.append(["CPU", UITheme.DANGER])
	var bx := 6.0
	for bd in badges:
		var chip := PanelContainer.new()
		var csb := UITheme.button_box(bd[1], Color(0, 0, 0, 0), 6)
		csb.content_margin_left = 7
		csb.content_margin_right = 7
		csb.content_margin_top = 0
		csb.content_margin_bottom = 0
		chip.add_theme_stylebox_override("panel", csb)
		chip.position = Vector2(bx, 6)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(UITheme.label(bd[0], 14, Color(0.02, 0.04, 0.08), UITheme.title_font()))
		b.add_child(chip)
		bx += 48.0
	if not ok:
		pt.modulate = Color(0.3, 0.3, 0.36)
		var lock := UITheme.label("Needs the\ncard database", 13, UITheme.TEXT_DIM)
		lock.position = Vector2(8, 8)
		b.add_child(lock)
	b.pressed.connect(func():
		if not ok:
			Router.toast(Loc.t("Download the full card database to unlock %s") % info.get("short", ""))
			return
		_choose(key))
	b.mouse_entered.connect(func():
		b.pivot_offset = b.size / 2.0
		b.z_index = 2
		create_tween().tween_property(b, "scale", Vector2(1.08, 1.08), 0.1))
	b.mouse_exited.connect(func():
		b.z_index = 0
		create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
	return b


func _choose(key: String) -> void:
	if key == "player":
		# Tapping your own duelist always puts you back in the YOU seat.
		_me = "player"
		if not CardData.has_deck(_my_deck):
			_my_deck = "echo"
		_picking = "opp"
	elif _picking == "me":
		_me = key
		if key != "player":
			_my_deck = Characters.get_char(key)["deck"]
		_picking = "opp"
	else:
		_opp = key
	Sfx.play("card", -6.0)
	_refresh_all()


func _random_opponent() -> void:
	var pool := []
	for k in Characters.ORDER:
		if Characters.available(k) and k != _opp:
			pool.append(k)
	if pool.is_empty():
		return
	_picking = "opp"
	_opp = pool[randi() % pool.size()]
	Sfx.play("card", -6.0)
	_refresh_all()


# ------------------------------------------------------------------ match setup

func _section(v: VBoxContainer, text: String) -> void:
	v.add_child(UITheme.label(text, 16, UITheme.ACCENT, UITheme.semi_font()))


func _build_setup() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.062, 0.118, 0.302, 0.96), 22, Color(UITheme.ACCENT, 0.3)))
	panel.position = Vector2(1166, 104)
	panel.custom_minimum_size = Vector2(690, 936)
	panel.size = Vector2(690, 936)
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	panel.add_child(v)
	_quote = UITheme.label("", 20, UITheme.TEXT)
	_quote.position = Vector2(1170, 60)
	_quote.size = Vector2(686, 26)
	_quote.add_theme_font_size_override("font_size", 17)
	_quote.clip_text = true
	_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_quote)
	_section(v, "YOUR DECK")
	_deck_pick = OptionButton.new()
	_deck_pick.item_selected.connect(func(i):
		_my_deck = _deck_keys[i]
		_refresh_slots()
		_refresh_deck_row())
	v.add_child(_deck_pick)
	_deck_row = HBoxContainer.new()
	_deck_row.add_theme_constant_override("separation", 8)
	_deck_row.custom_minimum_size = Vector2(0, 70)
	v.add_child(_deck_row)
	_deck_note = UITheme.label("", 15, UITheme.TEXT_DIM)
	v.add_child(_deck_note)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 10)
	v.add_child(trow)
	trow.add_child(UITheme.label("THEIR DECK", 16, UITheme.ACCENT, UITheme.semi_font()))
	_their_pick = OptionButton.new()
	_their_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_their_pick.add_theme_font_size_override("font_size", 16)
	_their_pick.add_item("Their own deck")
	_their_keys = [""]
	for k in CardData.DECKS.keys() + CardData.NAMED_DECKS.keys():
		if CardData.has_deck(k) and str(k) != "custom":
			_their_keys.append(str(k))
			_their_pick.add_item(CardData.deck_name(k))
	_their_pick.item_selected.connect(func(i):
		_their_deck = _their_keys[i]
		_refresh_slots())
	trow.add_child(_their_pick)
	var dhead := HBoxContainer.new()
	v.add_child(dhead)
	dhead.add_child(UITheme.label("DIFFICULTY", 16, UITheme.ACCENT, UITheme.semi_font()))
	_reward = UITheme.label("", 15, UITheme.GOLD)
	_reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dhead.add_child(_reward)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	v.add_child(drow)
	for i in 3:
		var db := Button.new()
		db.text = ["Easy", "Normal", "Hard"][i]
		db.toggle_mode = true
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_pick_style(db)
		db.pressed.connect(func():
			_difficulty = i + 1
			_refresh_all())
		drow.add_child(db)
		_diff_btns.append(db)
	_diff_note = UITheme.label("", 15, UITheme.TEXT_DIM)
	v.add_child(_diff_note)
	# How the duel is played: on foot or on runners, one duel or a match.
	_match_btn = CheckButton.new()
	_turbo_btn = CheckButton.new()
	var rules := HBoxContainer.new()
	rules.add_theme_constant_override("separation", 8)
	v.add_child(rules)
	for grp in [[_turbo_btn, "TYPE", ["Standard", "Turbo Duel"], ["A normal duel at the table.", "Both duelists ride runners. Spells need Speed Counters."]],
			[_match_btn, "LENGTH", ["1 duel", "Best of 3"], ["One duel decides it.", "First to win two duels. You can swap Side Deck cards between duels."]]]:
		var cb: CheckButton = grp[0]
		var gv := VBoxContainer.new()
		gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gv.add_theme_constant_override("separation", 2)
		rules.add_child(gv)
		gv.add_child(UITheme.label(str(grp[1]), 16, UITheme.ACCENT, UITheme.semi_font()))
		var gh := HBoxContainer.new()
		gh.add_theme_constant_override("separation", 6)
		gv.add_child(gh)
		var pair: Array = []
		for k in 2:
			var ob := Button.new()
			ob.text = str(grp[2][k])
			ob.tooltip_text = str(grp[3][k])
			ob.toggle_mode = true
			ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ob.add_theme_font_size_override("font_size", 18)
			_pick_style(ob)
			ob.button_pressed = k == 0
			gh.add_child(ob)
			pair.append(ob)
		for k in 2:
			(pair[k] as Button).pressed.connect(func():
				cb.button_pressed = k == 1
				(pair[0] as Button).set_pressed_no_signal(k == 0)
				(pair[1] as Button).set_pressed_no_signal(k == 1))
	# House rules: each button steps through its choices.
	v.add_child(UITheme.label("RULES", 16, UITheme.ACCENT, UITheme.semi_font()))
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 6)
	v.add_child(rrow)
	var lp_b := Button.new()
	var first_b := Button.new()
	var g_b := Button.new()
	var hand_b := Button.new()
	var paint := func():
		lp_b.text = Loc.t("%d Life Points") % _lp
		first_b.text = Loc.t(["Rock-paper-scissors", "I go first", "They go first"][_first + 1])
		g_b.text = Loc.t(["Single opponent", "Gauntlet: 3 in a row", "Survival: endless"][_run])
		g_b.add_theme_color_override("font_color", Comic.ORANGE_DEEP if _run > 0 else Comic.INK)
		hand_b.text = Loc.t("Hand of %d") % _hand_n
	for rb in [lp_b, hand_b, first_b, g_b]:
		UITheme.chip(rb)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.add_theme_font_size_override("font_size", 14)
		rb.clip_text = true
		rrow.add_child(rb)
	lp_b.tooltip_text = "Starting Life Points for both duelists."
	first_b.tooltip_text = "Who takes the first turn."
	g_b.tooltip_text = "Face three duelists in a row. Your Life Points carry over. Clear it for a bonus."
	lp_b.pressed.connect(func():
		_lp = {4000: 8000, 8000: 16000, 16000: 4000}[_lp]
		paint.call())
	first_b.pressed.connect(func():
		_first = (_first + 2) % 3 - 1
		paint.call())
	g_b.tooltip_text = "Single opponent, a Gauntlet of three in a row, or Survival: opponents keep coming until you lose. Your Life Points carry over."
	hand_b.tooltip_text = "How many cards each duelist starts with."
	hand_b.pressed.connect(func():
		_hand_n = {5: 6, 6: 7, 7: 4, 4: 5}[_hand_n]
		paint.call())
	g_b.pressed.connect(func():
		_run = (_run + 1) % 3
		_gauntlet = _run > 0
		paint.call())
	paint.call()
	v.add_child(UITheme.label("ARENA", 16, UITheme.ACCENT, UITheme.semi_font()))
	var arow := HBoxContainer.new()
	arow.add_theme_constant_override("separation", 10)
	v.add_child(arow)
	var prev := Button.new()
	prev.text = "◀"
	prev.pressed.connect(func(): _step_field(-1))
	arow.add_child(prev)
	_field_swatch = ColorRect.new()
	_field_swatch.custom_minimum_size = Vector2(10, 40)
	arow.add_child(_field_swatch)
	_field_name = UITheme.label("", 22, Color.WHITE, UITheme.semi_font())
	_field_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arow.add_child(_field_name)
	var next := Button.new()
	next.text = "▶"
	next.pressed.connect(func(): _step_field(1))
	arow.add_child(next)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	# Everything above takes what it needs; the button row sits on the floor of the column.
	var push := Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(push)
	v.move_child(push, row.get_index())
	var rnd := Button.new()
	rnd.text = "Random rival"
	rnd.custom_minimum_size = Vector2(0, 86)
	rnd.pressed.connect(_random_opponent)
	row.add_child(rnd)
	_go = Button.new()
	_go.text = "DUEL!"
	_go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_go.custom_minimum_size = Vector2(0, 86)
	_go.add_theme_font_size_override("font_size", 64)
	_go.add_theme_font_override("font", Comic.shout_font())
	_go.add_theme_constant_override("outline_size", 14)
	for st in [["normal", Comic.ORANGE], ["hover", Comic.YELLOW], ["pressed", Comic.ORANGE_DEEP], ["focus", Comic.ORANGE.lightened(0.15)]]:
		var gsb := Comic.box(st[1], 16, 0.14, 5, 8)
		_go.add_theme_stylebox_override(str(st[0]), gsb)
	_go.add_theme_color_override("font_pressed_color", Color.WHITE)
	_go.pressed.connect(_start_duel)
	row.add_child(_go)


## A choice button: the picked one is filled bright so it is obvious which is on.
func _pick_style(b: Button) -> void:
	var on := UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT, 8)
	on.content_margin_left = 8
	on.content_margin_right = 8
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, on)
	for c in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Color(0.02, 0.05, 0.08))


func _step_field(dir: int) -> void:
	var opts: Array = ["auto"] + FieldThemes.ORDER
	_field = opts[posmod(opts.find(_field) + dir, opts.size())]
	Sfx.play("card", -10.0)
	_refresh_setup()


## The five cards that best show what a deck is about: its biggest monsters.
func _refresh_deck_row() -> void:
	for c in _deck_row.get_children():
		_deck_row.remove_child(c)
		c.queue_free()
	var mons := []
	var others := 0
	var all := CardData.deck_list(_my_deck)
	for id in _unique(CardData.extra_list(_my_deck) + all):
		var d := CardData.get_card(id)
		if d.get("kind", "") in ["spell", "trap"]:
			continue
		mons.append([int(d.get("atk", 0)), id])
	for id in all:
		if CardData.get_card(id).get("kind", "") in ["spell", "trap"]:
			others += 1
	mons.sort_custom(func(a, b): return a[0] > b[0])
	for i in mini(8, mons.size()):
		var id: int = mons[i][1]
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(id)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(48, 70)
		tr.tooltip_text = Loc.t("%s\nATK %d") % [CardData.get_card(id).get("name", ""), mons[i][0]]
		tr.modulate.a = 0.0
		_deck_row.add_child(tr)
		create_tween().tween_property(tr, "modulate:a", 1.0, 0.2).set_delay(i * 0.04)
	_deck_note.text = Loc.t("%d cards  ·  %d monsters  ·  %d Spells and Traps  ·  %d in the Extra Deck") % [
			all.size(), all.size() - others, others, CardData.extra_list(_my_deck).size()]


func _refresh_setup() -> void:
	for i in _diff_btns.size():
		_diff_btns[i].set_pressed_no_signal(i + 1 == maxi(1, _difficulty))
	_diff_note.text = ["Plays sensibly and attacks when it can.", "Plays sensibly and attacks when it can.",
			"Thinks ahead, brings a tuned deck and starts with one extra card.",
			"Plans two plays ahead and sees your counterattack coming. Tuned deck, one extra card."][_difficulty]
	var th := FieldThemes.resolve(_field, _opp)
	_field_name.text = (Loc.t("Auto  ·  %s") % th["name"]) if _field == "auto" else str(th["name"])
	_field_swatch.color = th["accent"]
	var o := Characters.get_char(_opp)
	var said := Characters.line(_opp, "intro")
	_quote.text = "%s:  \"%s\"" % [str(o.get("short", "")).to_upper(), said] if said != "" else ""
	_reward.text = Loc.t("Win +%d Duel Points  ·  Lose +40") % (120 + 60 * _difficulty)


func _refresh_all() -> void:
	_refresh_slots()
	_refresh_picker()
	_refresh_grid()
	for i in _tabs.size():
		var era: String = "" if i == 0 else Characters.ERAS[i - 1]
		_tabs[i].set_pressed_no_signal(era == _era)
	_deck_pick.clear()
	_deck_keys.clear()
	for special in ["custom", "echo"]:
		if CardData.has_deck(special):
			_deck_keys.append(special)
			_deck_pick.add_item("%s  (%s)" % [CardData.deck_name(special), "built by you" if special == "custom" else "starter"])
	for k in Characters.ORDER:
		var deck: String = Characters.DATA[k]["deck"]
		if CardData.has_deck(deck) and not _deck_keys.has(deck):
			_deck_keys.append(deck)
			_deck_pick.add_item("%s  (%s)" % [CardData.deck_name(deck), Characters.DATA[k]["short"]])
	_deck_pick.select(maxi(0, _deck_keys.find(_my_deck)))
	_refresh_deck_row()
	_refresh_setup()


# ------------------------------------------------------------------ start / close

func _start_duel() -> void:
	if _starting:
		return
	_starting = true
	Sfx.play("summon", -4.0)
	var me_b: Control = _slots["me"]["button"]
	var opp_b: Control = _slots["opp"]["button"]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(me_b, "position:x", me_b.position.x + 46.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(opp_b, "position:x", opp_b.position.x - 46.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_vs, "scale", Vector2(2.2, 2.2), 0.22)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw2 := create_tween()
	tw2.tween_interval(0.16)
	tw2.tween_property(flash, "color:a", 1.0, 0.14)
	tw2.tween_property(flash, "color", Color(0, 0, 0, 1), 0.2)
	await tw2.finished
	var is_match: bool = _match_btn != null and _match_btn.button_pressed
	Router.match_state = {"wins": [0, 0], "game": 1, "last_loser": -1,
		"orig": {"main": Collection.main.duplicate(), "side": Collection.side.duplicate()}} if is_match else {}
	var cfg := {"player_char": _me, "opponent": _opp, "player_deck": _my_deck, "difficulty": _difficulty, "field": _field, "match": is_match and not _gauntlet,
		"turbo": _turbo_btn != null and _turbo_btn.button_pressed, "lp": _lp, "hand": _hand_n}
	if _their_deck != "":
		cfg["opponent_deck"] = _their_deck
	if _first >= 0:
		cfg["first"] = _first
	if _gauntlet:
		# The duelist you picked first, then two more drawn from everyone else.
		var others: Array = []
		for k in Characters.ORDER:
			if str(k) != _opp and str(k) != _me and CardData.has_deck(str(Characters.DATA[k].get("deck", ""))):
				others.append(str(k))
		others.shuffle()
		var run: Array = [_opp] + others.slice(0, 2)
		cfg["gauntlet"] = {"all": run.duplicate(), "left": run.slice(1), "stage": 1, "total": run.size(), "endless": _run == 2}
		Router.match_state = {}
	start.emit(cfg)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if _starting:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
