class_name PackShop
extends Control
## The booster counter: five foil packs on a lit shelf. Pick one up to see what is in it, what
## you already own from it and a few of its best cards, then open it.

signal closed

var _dp: Label
var _shelf: HBoxContainer
var _slots: Array = []          # [{button, wrap, pack}]
var _sel := -1
var _backdrop: TextureRect
var _name: Label
var _blurb: Label
var _have: Label
var _bar: ProgressBar
var _featured: HBoxContainer
var _open_btn: Button
var _last: HBoxContainer
var _last_title: Label
var _busy := false
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.018, 0.04, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# The chosen pack's art, huge and dim, behind everything.
	_backdrop = TextureRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.modulate = Color(1, 1, 1, 0.0)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	var veil := ColorRect.new()
	veil.color = Color(0.012, 0.018, 0.04, 0.78)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 90)
	m.add_theme_constant_override("margin_top", 44)
	m.add_theme_constant_override("margin_bottom", 36)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 0)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_box)
	title_box.add_child(UITheme.label("BOOSTER PACKS", 56, Color.WHITE, UITheme.title_font()))
	title_box.add_child(UITheme.label(Loc.t("%d cards per pack. Win duels to earn Duel Points.") % Collection.PACK_SIZE, 20, UITheme.TEXT_DIM))
	var purse := PanelContainer.new()
	purse.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.08, 0.02, 0.9), 16, Color(UITheme.GOLD, 0.8)))
	purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(purse)
	_dp = UITheme.label("", 34, UITheme.GOLD, UITheme.title_font())
	purse.add_child(_dp)
	# The shelf.
	_shelf = HBoxContainer.new()
	_shelf.alignment = BoxContainer.ALIGNMENT_CENTER
	_shelf.add_theme_constant_override("separation", 34)
	_shelf.custom_minimum_size = Vector2(0, 456)
	v.add_child(_shelf)
	for i in Collection.PACKS.size():
		_shelf.add_child(_slot(i))
	var plank := ColorRect.new()
	plank.color = Color(UITheme.ACCENT, 0.5)
	plank.custom_minimum_size = Vector2(0, 3)
	v.add_child(plank)
	# What is in the pack you are holding.
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 40)
	info.custom_minimum_size = Vector2(0, 250)
	v.add_child(info)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(left)
	_name = UITheme.label("", 46, Color.WHITE, UITheme.title_font())
	left.add_child(_name)
	_blurb = UITheme.label("", 22, UITheme.TEXT)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_blurb)
	_have = UITheme.label("", 20, UITheme.TEXT_DIM, UITheme.semi_font())
	left.add_child(_have)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(520, 14)
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(1, 1, 1, 0.1)
	bar_bg.set_corner_radius_all(7)
	var bar_fg := StyleBoxFlat.new()
	bar_fg.bg_color = UITheme.GOLD
	bar_fg.set_corner_radius_all(7)
	_bar.add_theme_stylebox_override("background", bar_bg)
	_bar.add_theme_stylebox_override("fill", bar_fg)
	left.add_child(_bar)
	var odds := UITheme.label("The last card in every pack leans toward the strong ones. Foils: Rare, Super Rare, Ultra Rare.", 17, UITheme.TEXT_DIM)
	odds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(odds)
	var buy := HBoxContainer.new()
	buy.add_theme_constant_override("separation", 16)
	left.add_child(buy)
	_open_btn = Button.new()
	_open_btn.custom_minimum_size = Vector2(360, 70)
	_open_btn.add_theme_font_size_override("font_size", 30)
	_open_btn.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.22), UITheme.GOLD, 16))
	_open_btn.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 16))
	_open_btn.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 16))
	_open_btn.pressed.connect(func(): _open(Collection.PACKS[_sel]))
	buy.add_child(_open_btn)
	var done := Button.new()
	done.text = "Leave the counter"
	done.custom_minimum_size = Vector2(260, 70)
	done.add_theme_font_size_override("font_size", 24)
	done.pressed.connect(_close)
	buy.add_child(done)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	info.add_child(right)
	_last_title = UITheme.label("IN THIS PACK", 18, UITheme.ACCENT, UITheme.semi_font())
	right.add_child(_last_title)
	_featured = HBoxContainer.new()
	_featured.add_theme_constant_override("separation", 12)
	right.add_child(_featured)
	_last = _featured
	_refresh()
	_select(0, true)
	(_slots[0]["button"] as Button).grab_focus.call_deferred()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _slot(i: int) -> Control:
	var pack: Dictionary = Collection.PACKS[i]
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(250, 452)
	b.focus_mode = Control.FOCUS_ALL
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var wrap := PackWrapper.new().setup(pack)
	wrap.custom_minimum_size = Vector2(250, 384)
	wrap.size = Vector2(250, 384)
	wrap.position = Vector2(0, 60)
	wrap.pivot_offset = Vector2(125, 384)
	b.add_child(wrap)
	b.pressed.connect(func():
		if _sel == i:
			_open(pack)
		else:
			_select(i))
	b.focus_entered.connect(func(): _select(i))
	b.mouse_entered.connect(func(): _select(i))
	_slots.append({"button": b, "wrap": wrap, "pack": pack})
	# Drop onto the shelf one after another.
	wrap.modulate.a = 0.0
	wrap.position.y = -60
	var tw := wrap.create_tween().set_parallel()
	tw.tween_property(wrap, "modulate:a", 1.0, 0.25).set_delay(0.1 + i * 0.07)
	tw.tween_property(wrap, "position:y", 60.0, 0.4).set_delay(0.1 + i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return b


func _process(delta: float) -> void:
	_t += delta
	for i in _slots.size():
		var w: PackWrapper = _slots[i]["wrap"]
		var on := i == _sel
		w.glow = lerpf(w.glow, 1.0 if on else 0.0, clampf(delta * 8.0, 0.0, 1.0))
		var s := lerpf(w.scale.x, 1.1 if on else 0.92, clampf(delta * 9.0, 0.0, 1.0))
		w.scale = Vector2(s, s)
		w.rotation = lerpf(w.rotation, sin(_t * 1.6 + i) * 0.02 if on else 0.0, clampf(delta * 6.0, 0.0, 1.0))
		w.modulate = w.modulate.lerp(Color(1, 1, 1, w.modulate.a) if on else Color(0.62, 0.64, 0.7, w.modulate.a), clampf(delta * 8.0, 0.0, 1.0))


func _select(i: int, quiet := false) -> void:
	if i == _sel or _busy:
		return
	_sel = i
	if not quiet:
		Sfx.play("hover", -10.0)
	var pack: Dictionary = Collection.PACKS[i]
	var col: Color = pack["color"]
	var w: PackWrapper = _slots[i]["wrap"]
	if w._art:
		_backdrop.texture = w._art
		_backdrop.modulate.a = 0.0
		create_tween().tween_property(_backdrop, "modulate:a", 0.55, 0.35)
	_name.text = Loc.t(str(pack["name"])).to_upper()
	_name.add_theme_color_override("font_color", col.lightened(0.45))
	_blurb.text = Loc.t(str(pack["blurb"]))
	_show_featured(pack)
	_refresh()


func _show_featured(pack: Dictionary) -> void:
	_last_title.text = Loc.t("IN THIS PACK")
	for c in _featured.get_children():
		c.queue_free()
	var pool: Array = Collection.pool(str(pack["key"])).duplicate()
	pool.sort_custom(func(a, b):
		var ra := CardData.rarity(a)
		var rb := CardData.rarity(b)
		if ra != rb:
			return ra > rb
		return int(CardData.get_card(a).get("atk", 0)) > int(CardData.get_card(b).get("atk", 0)))
	for k in mini(5, pool.size()):
		_featured.add_child(_thumb(pool[k], k, Collection.count(pool[k]) > 0, false))


func _thumb(id: int, k: int, owned: bool, is_new: bool) -> Control:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 4)
	var tr := TextureRect.new()
	tr.texture = Cards.get_face(id)
	tr.custom_minimum_size = Vector2(138, 201)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.pivot_offset = Vector2(69, 100)
	tr.tooltip_text = str(CardData.get_card(id).get("name", ""))
	holder.add_child(tr)
	Foil.apply(tr, CardData.rarity(id))
	var r := CardData.rarity(id)
	var tag := UITheme.label("NEW!" if is_new else (Loc.t(Foil.NAMES[r]) if r > 0 else ("" if owned else "")), 15,
			Color("ffd23a") if is_new else Foil.COLORS[r], UITheme.semi_font())
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(tag)
	if not owned and not is_new:
		tr.modulate = Color(0.55, 0.58, 0.66)
	tr.scale = Vector2(0.7, 0.7)
	tr.modulate.a = 0.0
	var tw := tr.create_tween().set_parallel()
	tw.tween_property(tr, "scale", Vector2.ONE, 0.22).set_delay(k * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(tr, "modulate:a", 1.0, 0.18).set_delay(k * 0.05)
	return holder


func _refresh() -> void:
	_dp.text = Loc.t("%d DP") % Collection.dp
	if _sel < 0:
		return
	var pack: Dictionary = Collection.PACKS[_sel]
	var pool: Array = Collection.pool(str(pack["key"]))
	var have := 0
	for id in pool:
		if Collection.count(id) > 0:
			have += 1
	_have.text = Loc.t("You have %d of %d cards.") % [have, pool.size()]
	_bar.max_value = maxi(1, pool.size())
	_bar.value = have
	if pool.is_empty():
		_open_btn.text = "Needs the card database"
		_open_btn.disabled = true
	else:
		_open_btn.text = Loc.t("Open  ·  %d DP") % Collection.PACK_PRICE
		_open_btn.disabled = Collection.dp < Collection.PACK_PRICE


func _open(pack: Dictionary) -> void:
	if _busy:
		return
	var before := Collection.owned.duplicate()
	var pulls := Collection.open_pack(str(pack["key"]))
	if pulls.is_empty():
		Router.toast("Not enough Duel Points")
		Sfx.play("blip", -6.0, 0.6)
		return
	_busy = true
	_refresh()
	# The pack lifts off the shelf, then the opening scene takes over.
	var w: PackWrapper = _slots[_sel]["wrap"]
	var lift := w.create_tween()
	lift.tween_property(w, "position:y", 0.0, 0.18).set_ease(Tween.EASE_OUT)
	Sfx.play("whoosh", -6.0, 1.3)
	await lift.finished
	w.modulate.a = 0.0
	var scene := PackOpening.new(pulls, before.duplicate(), pack.get("color", UITheme.ACCENT), str(pack.get("name", "")), pack)
	add_child(scene)
	await scene.closed
	# A fresh pack slides into the empty place, and what you pulled stays on show.
	w.position.y = -60
	var back := w.create_tween().set_parallel()
	back.tween_property(w, "modulate:a", 1.0, 0.2)
	back.tween_property(w, "position:y", 60.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_last_title.text = Loc.t("YOU PULLED")
	for c in _featured.get_children():
		c.queue_free()
	for i in pulls.size():
		var id: int = pulls[i]
		_featured.add_child(_thumb(id, i, true, int(before.get(id, 0)) == 0))
		before[id] = 1
	_busy = false
	_refresh()
	_open_btn.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if _busy:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
