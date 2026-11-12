class_name CharacterSelect
extends Control
## Free Duel setup. Two big duelist panels face each other across a VS; the roster sits
## underneath; deck, difficulty and arena sit on the right. Tap a panel (YOU / OPPONENT)
## to say who you are choosing, then tap a duelist.

signal start(config: Dictionary)
signal closed

const W := 1920.0
const H := 1080.0
const PANEL_SIZE := Vector2(470, 500)
const CELL := Vector2(130, 158)

var _me := "player"
var _opp := "kaiba"
var _picking := "opp"
var _era := ""
var _difficulty := 1
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
	_difficulty = int(cfg.get("difficulty", 1))
	_my_deck = cfg.get("player_deck", "yugi")
	if not CardData.has_deck(_my_deck):
		_my_deck = "echo" if CardData.has_deck("echo") else "yugi"
	_field = str(cfg.get("field", Settings.field_theme))
	if _field != "auto" and not FieldThemes.THEMES.has(_field):
		_field = "auto"
	var dim := ColorRect.new()
	dim.color = Color(0.012, 0.02, 0.045, 0.985)
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
	var header := UITheme.label("FREE DUEL", 58, Color.WHITE, UITheme.title_font())
	header.position = Vector2(64, 28)
	_root.add_child(header)
	var bar := ColorRect.new()
	bar.color = UITheme.ACCENT
	bar.position = Vector2(66, 98)
	bar.size = Vector2(118, 4)
	_root.add_child(bar)
	var hint := UITheme.label("Tap YOU or OPPONENT, then pick a duelist below", 20, UITheme.TEXT_DIM)
	hint.position = Vector2(330, 58)
	_root.add_child(hint)
	_build_slots()
	_build_setup()
	_build_tabs()
	_grid = GridContainer.new()
	_grid.columns = 13
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.position = Vector2(64, 722)
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
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
		Portraits.get_portrait(_me)
		Portraits.get_portrait(_opp)
	if _go and not _starting:
		_go.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.25, 1.25), 0.5 + 0.5 * sin(_t * 3.0))


## Two tinted halves split by a slash, in each duelist's color.
func _draw_backdrop() -> void:
	var o := _root.position if _root else Vector2.ZERO
	var a: Color = Portraits.info(_me).get("color", UITheme.ACCENT)
	var b: Color = Portraits.info(_opp).get("color", UITheme.DANGER)
	var mid := o.x + 590.0
	var top := o.y + 118.0
	var bot := o.y + 652.0
	_backdrop.draw_colored_polygon(PackedVector2Array([Vector2(0, top), Vector2(mid + 70, top), Vector2(mid - 70, bot), Vector2(0, bot)]), Color(a, 0.13))
	_backdrop.draw_colored_polygon(PackedVector2Array([Vector2(mid + 70, top), Vector2(o.x + 1146, top), Vector2(o.x + 1146, bot), Vector2(mid - 70, bot)]), Color(b, 0.13))
	_backdrop.draw_line(Vector2(mid + 70, top), Vector2(mid - 70, bot), Color(1, 1, 1, 0.5), 3.0, true)
	_backdrop.draw_line(Vector2(0, top), Vector2(o.x + 1146, top), Color(1, 1, 1, 0.08), 1.0)
	_backdrop.draw_line(Vector2(0, bot), Vector2(size.x, bot), Color(1, 1, 1, 0.08), 1.0)
	for i in 7:
		var x := fmod(_t * 0.0 + i * 190.0, 1146.0)
		_backdrop.draw_line(Vector2(o.x + x + 60, top), Vector2(o.x + x - 40, bot), Color(1, 1, 1, 0.025), 28.0)


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
		b.position = Vector2(64 if side == "me" else 646, 136)
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
		pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pt.flip_h = side == "opp"
		b.add_child(pt)
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
		grad.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.92)])
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
		var name_l := UITheme.label("", 46, Color.WHITE, UITheme.title_font())
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
	_vs = UITheme.label("VS", 92, Color.WHITE, UITheme.title_font())
	_vs.position = Vector2(540, 318)
	_vs.size = Vector2(100, 100)
	_vs.pivot_offset = Vector2(50, 50)
	_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08))
	_vs.add_theme_constant_override("outline_size", 14)
	_vs.add_theme_color_override("font_shadow_color", Color(UITheme.ACCENT, 0.8))
	_vs.add_theme_constant_override("shadow_outline_size", 26)
	_vs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vs)


func _deck_of(side: String) -> String:
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
		sl["portrait"].texture = Portraits.get_portrait(key)
		sl["name"].text = str(info.get("name", "")).to_upper()
		sl["title"].text = str(info.get("title", ""))
		var deck_key := _deck_of(side)
		sl["sub"].text = "%s  ·  %s Deck" % [info.get("era", ""), CardData.deck_name(deck_key)]
		var ace := 0
		if side == "opp":
			ace = int(Characters.get_char(key).get("ace", 0))
		if ace == 0 or CardData.get_card(ace).is_empty():
			ace = _deck_ace(deck_key)
		sl["ace"].texture = Cards.get_face(ace) if ace != 0 else null
		var active: bool = side == _picking
		var sb := UITheme.button_box(Color(0.03, 0.05, 0.09, 0.0), col if active else Color(1, 1, 1, 0.16), 20)
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
		sl["tag"].text = ("YOU" if side == "me" else "OPPONENT") + ("  ·  CHOOSING" if active else "")
		if changed:
			var b: Control = sl["button"]
			b.scale = Vector2(0.96, 0.96)
			create_tween().tween_property(b, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			sl["portrait"].modulate = Color(2.2, 2.2, 2.2)
			create_tween().tween_property(sl["portrait"], "modulate", Color.WHITE, 0.3)
	_backdrop.queue_redraw()


# ------------------------------------------------------------------ roster

func _build_tabs() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(64, 668)
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
	b.tooltip_text = "%s\n%s" % [info.get("name", ""), info.get("title", "")]
	var is_me := key == _me
	var is_opp := key == _opp
	var chosen := (is_me and _picking == "me") or (is_opp and _picking == "opp")
	var col: Color = info.get("color", UITheme.ACCENT)
	for st in ["normal", "hover", "pressed", "focus"]:
		var lit: bool = chosen or st == "hover" or st == "focus"
		var sb := UITheme.button_box(Color(0.05, 0.08, 0.13, 1), col if lit else Color(1, 1, 1, 0.08), 12)
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
	band.color = Color(0, 0, 0, 0.78)
	band.anchor_top = 1.0
	band.anchor_right = 1.0
	band.anchor_bottom = 1.0
	band.offset_top = -32
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(band)
	var n := UITheme.label(("YOU" if key == "player" else str(info.get("short", ""))).to_upper(), 20, Color.WHITE, UITheme.title_font())
	n.position = Vector2(8, 3)
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
			Router.toast("Download the full card database to unlock %s" % info.get("short", ""))
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
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.04, 0.07, 0.12, 0.96), 22, Color(UITheme.ACCENT, 0.3)))
	panel.position = Vector2(1176, 130)
	panel.custom_minimum_size = Vector2(680, 512)
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	_quote = UITheme.label("", 20, UITheme.TEXT)
	_quote.position = Vector2(1180, 92)
	_quote.size = Vector2(676, 28)
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
	_deck_row.custom_minimum_size = Vector2(0, 96)
	v.add_child(_deck_row)
	_deck_note = UITheme.label("", 15, UITheme.TEXT_DIM)
	v.add_child(_deck_note)
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
		db.add_theme_stylebox_override("hover_pressed", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT))
		db.pressed.connect(func():
			_difficulty = i
			_refresh_all())
		drow.add_child(db)
		_diff_btns.append(db)
	_diff_note = UITheme.label("", 15, UITheme.TEXT_DIM)
	v.add_child(_diff_note)
	_section(v, "ARENA")
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
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 60)
	back.pressed.connect(close)
	row.add_child(back)
	var rnd := Button.new()
	rnd.text = "Random rival"
	rnd.custom_minimum_size = Vector2(0, 60)
	rnd.pressed.connect(_random_opponent)
	row.add_child(rnd)
	_go = Button.new()
	_go.text = "DUEL!"
	_go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_go.custom_minimum_size = Vector2(0, 60)
	_go.add_theme_font_size_override("font_size", 36)
	_go.add_theme_font_override("font", UITheme.title_font())
	_go.add_theme_color_override("font_color", Color(0.02, 0.05, 0.08))
	_go.add_theme_color_override("font_hover_color", Color(0.02, 0.05, 0.08))
	_go.add_theme_color_override("font_pressed_color", Color(0.02, 0.05, 0.08))
	_go.add_theme_stylebox_override("normal", UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT, 14))
	_go.add_theme_stylebox_override("hover", UITheme.button_box(UITheme.ACCENT.lightened(0.25), Color.WHITE, 14))
	_go.add_theme_stylebox_override("pressed", UITheme.button_box(UITheme.ACCENT.darkened(0.15), Color.WHITE, 14))
	_go.add_theme_stylebox_override("focus", UITheme.button_box(UITheme.ACCENT.lightened(0.15), Color.WHITE, 14))
	_go.pressed.connect(_start_duel)
	row.add_child(_go)


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
		tr.custom_minimum_size = Vector2(66, 96)
		tr.tooltip_text = "%s\nATK %d" % [CardData.get_card(id).get("name", ""), mons[i][0]]
		tr.modulate.a = 0.0
		_deck_row.add_child(tr)
		create_tween().tween_property(tr, "modulate:a", 1.0, 0.2).set_delay(i * 0.04)
	_deck_note.text = "%d cards  ·  %d monsters  ·  %d Spells and Traps  ·  %d in the Extra Deck" % [
			all.size(), all.size() - others, others, CardData.extra_list(_my_deck).size()]


func _refresh_setup() -> void:
	for i in _diff_btns.size():
		_diff_btns[i].set_pressed_no_signal(i == _difficulty)
	_diff_note.text = ["Relaxed. Makes mistakes and leaves openings.", "Plays sensibly and attacks when it can.",
			"Thinks ahead, brings a tuned deck and starts with one extra card."][_difficulty]
	var th := FieldThemes.resolve(_field, _opp)
	_field_name.text = ("Auto  ·  %s" % th["name"]) if _field == "auto" else str(th["name"])
	_field_swatch.color = th["accent"]
	var o := Characters.get_char(_opp)
	var said := Characters.line(_opp, "intro")
	_quote.text = "%s:  \"%s\"" % [str(o.get("short", "")).to_upper(), said] if said != "" else ""
	_reward.text = "Win +%d Duel Points  ·  Lose +40" % (120 + 60 * _difficulty)


func _refresh_all() -> void:
	_refresh_slots()
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
	start.emit({"player_char": _me, "opponent": _opp, "player_deck": _my_deck, "difficulty": _difficulty, "field": _field})


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
