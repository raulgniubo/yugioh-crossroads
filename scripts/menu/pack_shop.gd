class_name PackShop
extends Control
## The booster counter: foil packs on a lit shelf, three shelves to flip between. Pick one up to
## see what is in it, what you already own from it and a few of its best cards, then open it.

signal closed

var _dp: Label
var _shelf: HBoxContainer
var _scroll: ScrollContainer
var _multi: Array = []          # the Open 5 and Open 10 buttons
var _slots: Array = []          # [{button, wrap, pack}]
var _sel := -1
var _see_btn: Button
var _viewing := false
var _tab := 0
var _packs: Array = []          # the packs on the shelf being shown
var _tab_btns: Array = []
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


## How many cards the info panel shows (best in the pack, or the best you just pulled).
const FEATURED := 5

## What each world's card shop keeps on its shelf.
const WORLD_PACKS := {"domino": ["Duel Monsters", "toy", "mask", "goblin", "dd", "union", "spirit", "darklord", "jurrac", "legends_king", "red_eyes", "blue_eyes", "dark_magician", "kuriboh", "exodia", "guardian", "amazoness", "toon", "archfiend", "gravekeeper", "chaos", "Vault", "legends"], "academy": ["GX", "frog", "barrier", "cyber", "sacred_beast", "hero", "armed_dragon", "cloudian", "arcana_force", "koaki_meiru", "volcanic", "alien", "vampire", "crystal_beast", "gladiator", "dark_world", "ancient_gear", "monarchs", "Vault", "legends"], "satellite": ["5D's", "reptilianne", "flamvell", "ally_justice", "laval", "watt", "gishki", "vylon", "swarm", "worm", "fabled", "synchron", "nordic", "tg", "naturia", "ice_barrier", "x_saber", "scrap", "morphtronic", "dragunity", "genex", "six_samurai", "lightsworn", "beyond"], "newdomino": ["5D's", "reptilianne", "flamvell", "ally_justice", "laval", "watt", "gishki", "vylon", "swarm", "worm", "gusto", "fortune_lady", "fabled", "karakuri", "synchron", "meklord", "nordic", "tg", "naturia", "ice_barrier", "x_saber", "scrap", "morphtronic", "dragunity", "genex", "six_samurai", "lightsworn", "beyond", "Vault"],
	"heartland": ["ZEXAL", "sylvan", "heraldic", "artifact", "hieratic", "hazy", "inzektor", "gears", "noble_knight", "phantom_beast", "evol", "dragon_ruler", "ghostrick", "wind_up", "spellbook", "mermail", "bujin", "fire_fist", "ninja", "battlin_boxer", "gimmick_puppet", "chronomaly", "heroic", "madolche", "constellar", "gem_knight", "beyond", "legends", "frontier"]}


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
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
	head.add_child(UITheme.shop_sections(self, "packs"))
	var head_gap := Control.new()
	head_gap.custom_minimum_size = Vector2(18, 0)
	head.add_child(head_gap)
	UITheme.cover_3d(self)
	var purse := PanelContainer.new()
	purse.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.08, 0.02, 0.9), 16, Color(UITheme.GOLD, 0.8)))
	purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(purse)
	_dp = UITheme.label("", 34, UITheme.GOLD, UITheme.title_font())
	purse.add_child(_dp)
	# Which shelf.
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 12)
	v.add_child(tabs)
	for ti in Collection.PACK_TABS.size():
		var tb := Button.new()
		tb.toggle_mode = true
		tb.text = "  %s  " % Loc.t(str(Collection.PACK_TABS[ti]))
		tb.add_theme_font_size_override("font_size", 24)
		tb.custom_minimum_size = Vector2(0, 50)
		tb.pressed.connect(func(): _show_tab(ti))
		tabs.add_child(tb)
		_tab_btns.append(tb)
	var hint := UITheme.label("Q / E  or  LB / RB", 16, UITheme.TEXT_DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs.add_child(hint)
	# The shelf.
	# (It scrolls sideways: a shelf of twenty packs is wider than any screen, and it used to push
	# the whole counter off the right edge.)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, 420)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	v.add_child(_scroll)
	_shelf = HBoxContainer.new()
	_shelf.alignment = BoxContainer.ALIGNMENT_CENTER
	_shelf.add_theme_constant_override("separation", 30)
	_shelf.custom_minimum_size = Vector2(0, 404)
	_shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# (Room at both ends so the pack you hold, a little bigger, is not cut off at the edge.)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 18)
	_scroll.add_child(pad)
	pad.add_child(_shelf)
	var plank := ColorRect.new()
	plank.color = Color(UITheme.ACCENT, 0.5)
	plank.custom_minimum_size = Vector2(0, 3)
	v.add_child(plank)
	# What is in the pack you are holding.
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 40)
	info.custom_minimum_size = Vector2(0, 240)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(info)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(left)
	_name = UITheme.label("", 40, Color.WHITE, UITheme.title_font())
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_name)
	_blurb = UITheme.label("", 22, UITheme.TEXT)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_blurb)
	_have = UITheme.label("", 20, UITheme.TEXT_DIM, UITheme.semi_font())
	left.add_child(_have)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(480, 14)
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
	buy.add_theme_constant_override("separation", 12)
	left.add_child(buy)
	_open_btn = Button.new()
	_open_btn.custom_minimum_size = Vector2(280, 66)
	_open_btn.add_theme_font_size_override("font_size", 26)
	_open_btn.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.22), UITheme.GOLD, 16))
	_open_btn.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 16))
	_open_btn.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 16))
	_open_btn.pressed.connect(func(): _open(_packs[_sel]))
	buy.add_child(_open_btn)
	# Open 5 or 10 at once, for less.
	for n in [5, 10]:
		var mb := Button.new()
		mb.custom_minimum_size = Vector2(0, 66)
		mb.add_theme_font_size_override("font_size", 20)
		mb.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.12), Color(UITheme.GOLD, 0.7), 16))
		mb.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.GOLD, 0.35), Color.WHITE, 16))
		mb.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.GOLD, 0.35), Color.WHITE, 16))
		mb.pressed.connect(func(): _open(_packs[_sel], n))
		buy.add_child(mb)
		_multi.append(mb)
	var done := Button.new()
	done.text = "Leave the counter"
	done.custom_minimum_size = Vector2(0, 66)
	done.add_theme_font_size_override("font_size", 20)
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
	# Every card the pack can give you (0.55.3).
	_see_btn = Button.new()
	_see_btn.custom_minimum_size = Vector2(0, 52)
	_see_btn.add_theme_font_size_override("font_size", 20)
	_see_btn.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.14), Color(UITheme.ACCENT, 0.75), 14))
	_see_btn.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.ACCENT, 0.35), Color.WHITE, 14))
	_see_btn.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.ACCENT, 0.35), Color.WHITE, 14))
	_see_btn.pressed.connect(_see_cards)
	right.add_child(_see_btn)
	_last = _featured
	_show_tab(int(OS.get_environment("PACK_TAB")) if OS.get_environment("PACK_TAB") != "" else 0)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	if OS.has_environment("PACK_CARDS"):	# dev: open the card list of a pack on the shelf
		get_tree().create_timer(1.2).timeout.connect(func():
			var want := OS.get_environment("PACK_CARDS")
			var at := int(want) if want.is_valid_int() else maxi(0, _packs.map(func(p): return str(p["key"])).find(want))
			_select(at, true)
			_see_cards())


## The window with every card this pack can give you.
func _see_cards() -> void:
	if _busy or _viewing or _sel < 0 or Collection.pool(str(_packs[_sel]["key"])).is_empty():
		return
	_viewing = true
	Sfx.play("click")
	var v := CardListView.new("pack", _packs[_sel])
	add_child(v)
	await v.closed
	_viewing = false
	_see_btn.grab_focus.call_deferred()


func _show_tab(t: int) -> void:
	if _busy:
		return
	_tab = t
	for i in _tab_btns.size():
		(_tab_btns[i] as Button).button_pressed = i == t
	for c in _shelf.get_children():
		_shelf.remove_child(c)
		c.queue_free()
	_slots.clear()
	_packs = Collection.shop_packs().filter(func(p): return int(p.get("tab", 0)) == t)
	# A shop inside a world sells that world's own cards (and the Vault). The full shelf is
	# in the main menu.
	var here := str(Router.roam.get("district", "")) if get_tree().current_scene and "district" in get_tree().current_scene and "_npcs" in get_tree().current_scene else ""
	if here != "" and WORLD_PACKS.has(here) and t <= 1:
		var mine: Array = WORLD_PACKS[here]
		var kept: Array = _packs.filter(func(p): return Collection.base_key(str(p["key"])) in mine or (p.get("families", []) as Array).any(func(f): return f in mine))
		if not kept.is_empty():
			_packs = kept
	_sel = -1
	# (0.72.3) The first packs of the shelf now, the rest a few per frame: with ninety packs, making
	# every wrapper before the shop showed was over a second of standing still.
	_shelf_gen += 1
	var gen := _shelf_gen
	var first: int = mini(_packs.size(), 8)
	for i in first:
		_shelf.add_child(_slot(i))
	_select(0, true)
	_scroll.scroll_horizontal = 0
	(_slots[0]["button"] as Button).grab_focus.call_deferred()
	var t0 := Time.get_ticks_msec()
	for i in range(first, _packs.size()):
		if Time.get_ticks_msec() - t0 > 5:
			await get_tree().process_frame
			if not is_inside_tree() or gen != _shelf_gen:
				return
			t0 = Time.get_ticks_msec()
		_shelf.add_child(_slot(i))


func _slot(i: int) -> Control:
	var pack: Dictionary = _packs[i]
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(230, 396)
	b.focus_mode = Control.FOCUS_ALL
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var wrap := PackWrapper.new().setup(pack)
	wrap.custom_minimum_size = Vector2(230, 353)
	wrap.size = Vector2(230, 353)
	wrap.position = Vector2(0, 38)
	wrap.pivot_offset = Vector2(115, 353)
	b.add_child(wrap)
	# Click a pack to pick it; only the Open button spends Duel Points.
	b.pressed.connect(func(): _select(i))
	b.focus_entered.connect(func(): _select(i))
	_slots.append({"button": b, "wrap": wrap, "pack": pack})
	# Drop onto the shelf one after another.
	wrap.modulate.a = 0.0
	wrap.position.y = -60
	var tw := wrap.create_tween().set_parallel()
	tw.tween_property(wrap, "modulate:a", 1.0, 0.25).set_delay(0.1 + i * 0.07)
	tw.tween_property(wrap, "position:y", 38.0, 0.4).set_delay(0.1 + i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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


var _shelf_gen := 0


func _select(i: int, quiet := false) -> void:
	if i == _sel or _busy or i < 0 or i >= _slots.size():
		return
	_sel = i
	if not quiet:
		Sfx.play("hover", -10.0)
	var pack: Dictionary = _packs[i]
	var col: Color = pack["color"]
	var w: PackWrapper = _slots[i]["wrap"]
	if w._art:
		_backdrop.texture = w._art
		_backdrop.modulate.a = 0.0
		create_tween().tween_property(_backdrop, "modulate:a", 0.55, 0.35)
	_name.text = Collection.pack_title(pack).to_upper()
	_scroll.ensure_control_visible(_slots[i]["button"])
	_name.add_theme_color_override("font_color", col.lightened(0.45))
	_blurb.text = Loc.t(str(pack["blurb"]))
	if int(pack.get("vol", 0)) > 0:
		_blurb.text += " " + Loc.t("Volume %d of %d, in the order the cards first came out.") % [int(pack["vol"]), int(pack["vols"])]
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
	for k in mini(FEATURED, pool.size()):
		_featured.add_child(_thumb(pool[k], k, Collection.count(pool[k]) > 0, false))


func _thumb(id: int, k: int, owned: bool, is_new: bool) -> Control:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 4)
	var tr := TextureRect.new()
	tr.texture = Cards.get_thumb(id)
	tr.custom_minimum_size = Vector2(120, 175)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.pivot_offset = Vector2(60, 87)
	tr.tooltip_text = str(CardData.get_card(id).get("name", ""))
	holder.add_child(tr)
	Foil.apply(tr, CardData.rarity(id), id)
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
	var pack: Dictionary = _packs[_sel]
	var pool: Array = Collection.pool(str(pack["key"]))
	var have := 0
	for id in pool:
		if Collection.count(id) > 0:
			have += 1
	_have.text = Loc.t("You have %d of %d cards.") % [have, pool.size()]
	_see_btn.text = Loc.t("SEE ALL %d CARDS") % pool.size()
	_see_btn.visible = not pool.is_empty()
	_bar.max_value = maxi(1, pool.size())
	_bar.value = have
	var single_only := str(pack["key"]) == "echo"
	for k in _multi.size():
		var mb: Button = _multi[k]
		var n: int = [5, 10][k]
		mb.visible = not single_only
		mb.text = Loc.t("%d packs  ·  %d DP") % [n, Collection.multi_price(pack, n)]
		mb.tooltip_text = Loc.t("%d%% off") % (10 if n == 5 else 15)
		mb.disabled = pool.is_empty() or not Unlocks.pack(str(pack["key"])) or Collection.dp < Collection.multi_price(pack, n)
	if pool.is_empty():
		_open_btn.text = "Needs the card database"
		_open_btn.disabled = true
	else:
		_open_btn.text = Loc.t("Open  ·  %d DP") % Collection.pack_price(pack)
		_open_btn.disabled = Collection.dp < Collection.pack_price(pack)
		# Packs open with the story and with wins: say why this one is still shut.
		if not Unlocks.pack(str(pack["key"])):
			_open_btn.text = Unlocks.pack_why(str(pack["key"]))
			_open_btn.disabled = true
			for mb in _multi:
				mb.visible = false


func _open(pack: Dictionary, n := 1) -> void:
	if _busy:
		return
	var before := Collection.owned.duplicate()
	var batches := Collection.open_packs(str(pack["key"]), n)
	if batches.is_empty():
		if Unlocks.pack(str(pack["key"])):
			Router.toast("Not enough Duel Points")
		Sfx.play("blip", -6.0, 0.6)
		return
	_busy = true
	# Collection goals reached by these packs (and daily or weekly pack goals), told once the cards are out.
	var pays: Array = Goals.pay_album() + Goals.pay_due()
	_refresh()
	# The pack lifts off the shelf, then the opening scene takes over: one pack after another,
	# the same show each time, and with several a look at everything at the end.
	var w: PackWrapper = _slots[_sel]["wrap"]
	var lift := w.create_tween()
	lift.tween_property(w, "position:y", 0.0, 0.18).set_ease(Tween.EASE_OUT)
	Sfx.play("whoosh", -6.0, 1.3)
	await lift.finished
	w.modulate.a = 0.0
	var seen := before.duplicate()
	var all: Array = []
	for b in batches:
		all += b
	for k in batches.size():
		var scene := PackOpening.new(batches[k], seen.duplicate(), pack.get("color", UITheme.ACCENT), Collection.pack_title(pack), pack)
		if batches.size() > 1:
			scene.counter = Loc.t("Pack %d of %d") % [k + 1, batches.size()]
			scene.last = k == batches.size() - 1
		add_child(scene)
		await scene.closed
		for id in batches[k]:
			seen[id] = 1
		if scene.skip_rest:
			break
	if batches.size() > 1:
		var sum := PackSummary.new(all, before, pack.get("color", UITheme.ACCENT), Collection.pack_title(pack))
		add_child(sum)
		await sum.closed
	for k in pays.size():
		var line: Array = pays[k]
		get_tree().create_timer(0.6 + 2.2 * k).timeout.connect(func():
			Router.toast(Loc.t("%s   +%d Duel Points") % [str(line[0]), int(line[1])])
			Sfx.play("quest", -4.0))
	# A fresh pack slides into the empty place, and what you pulled stays on show.
	w.position.y = -60
	var back := w.create_tween().set_parallel()
	back.tween_property(w, "modulate:a", 1.0, 0.2)
	back.tween_property(w, "position:y", 38.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_last_title.text = Loc.t("YOU PULLED")
	for c in _featured.get_children():
		c.queue_free()
	var show: Array = []
	for id in all:
		if not show.has(id):
			show.append(id)
	if all.size() > FEATURED:
		# (From several packs: the best of them, new ones first.)
		show.sort_custom(func(a, b):
			var na := int(before.get(a, 0)) == 0
			var nb := int(before.get(b, 0)) == 0
			if CardData.rarity(a) != CardData.rarity(b):
				return CardData.rarity(a) > CardData.rarity(b)
			return na and not nb)
	for i in mini(FEATURED, show.size()):
		var id: int = show[i]
		_featured.add_child(_thumb(id, i, true, int(before.get(id, 0)) == 0))
	_busy = false
	_refresh()
	_open_btn.grab_focus.call_deferred()


## Left and right (D-pad, stick or arrow keys) walk along the shelf, whatever has focus, before
## the buttons get a chance to move focus somewhere else.
func _input(event: InputEvent) -> void:
	if _busy or _viewing or _slots.is_empty() or not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var step := -1 if event.is_action_pressed("ui_left") else 1
		var to := clampi(_sel + step, 0, _slots.size() - 1)
		get_viewport().set_input_as_handled()
		if to != _sel:
			_select(to)
			(_slots[to]["button"] as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif _busy or _viewing:
		return
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_X):
		# C or X: every card in the pack you are on.
		get_viewport().set_input_as_handled()
		_see_cards()
	elif event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_Y and _sel >= 0:
		# Y opens the pack you are on straight away.
		get_viewport().set_input_as_handled()
		_open(_packs[_sel])
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Q, KEY_E]) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		var back: bool = (event is InputEventKey and event.keycode == KEY_Q) or (event is InputEventJoypadButton and Pad.b(event) == JOY_BUTTON_LEFT_SHOULDER)
		get_viewport().set_input_as_handled()
		Sfx.play("click")
		_show_tab(posmod(_tab + (-1 if back else 1), Collection.PACK_TABS.size()))


func _switch(what: String) -> void:
	if not _busy:
		UITheme.shop_swap(self, what)


func _close() -> void:
	if _busy:
		return
	UITheme.uncover_3d(self)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()
