class_name CardsGate
extends Control
## Decks and cards (0.69.1): the door to your cards, in the look of the Academy's door and the main
## story's. Kame Game at night behind it (a picture taken in the game), the deck you duel with as a
## card down the left with Continue's place taken by My decks, and its best cards fanned out big
## on the right. Below: edit this deck, the card album, the card shops of every world, back.
## The shops page shows each world's shelf of booster packs and its ready-made decks. Buying still
## happens at the counter in the world: the page tells you what is there and takes you to the door.

signal closed

const PICTURE := "res://assets/ui/cards_title.jpg"
## The worlds with a card shop, in the order the story reaches them.
const SHOP_WORLDS := ["domino", "academy", "satellite", "newdomino", "heartland"]
const FAN := 5                     # how many of the deck's cards are fanned out on the right

var _box: VBoxContainer            # a page in the middle of the screen (the shops)
var _left: VBoxContainer           # the title page, down the left side over the picture
var _mid: CenterContainer
var _back: AcademyBackdrop
var _scroll: ScrollContainer
var _fan: Control                  # the deck's best cards, on the right of the title page
var _fan_cards: Array = []         # [TextureRect, base position, base rotation]
var _t := 0.0
var _world := ""                   # the shops page: the world being shown
var _shelf_packs: Array = []       # the packs on that world's shelf
var _shelf_btns: Array = []        # [Button, PackWrapper]
var _pick := -1                    # the pack picked on the shelf
var _pack_name: Label
var _pack_blurb: Label
var _pack_have: Label
var _pack_bar: Control
var _pack_price: Label
var _see_btn: Button
var _busy := false                 # a window (album, builder, card list) is open over this


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_back = AcademyBackdrop.new(0.0, PICTURE if ResourceLoader.exists(PICTURE) else StoryGate.PICTURE, Color(1.0, 0.86, 0.5))
	add_child(_back)
	_fan = Control.new()
	_fan.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fan)
	var lm := MarginContainer.new()
	lm.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	lm.add_theme_constant_override("margin_left", 96)
	lm.add_theme_constant_override("margin_top", 56)
	lm.add_theme_constant_override("margin_bottom", 44)
	add_child(lm)
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 12)
	_left.custom_minimum_size = Vector2(800, 0)
	_left.alignment = BoxContainer.ALIGNMENT_CENTER
	lm.add_child(_left)
	_mid = CenterContainer.new()
	_mid.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mid)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mid.add_child(_scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	_box.custom_minimum_size = Vector2(1240, 0)
	_scroll.add_child(_box)
	UITheme.cover_3d(self)
	_home()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _process(delta: float) -> void:
	_t += delta
	# The middle page never runs past the screen: it scrolls when it is taller than the view.
	var room := get_viewport_rect().size.y - 60.0
	var want := _box.get_combined_minimum_size().y
	# (Room on the right for the scroll bar, so it never sits over the page's right edge.)
	_scroll.custom_minimum_size = Vector2(_box.custom_minimum_size.x + (22.0 if want > room else 0.0), minf(want, room))
	# The fanned cards hold still (slow sub-pixel motion reads as stutter on big screens).
	for i in _fan_cards.size():
		var f: Array = _fan_cards[i]
		var tr: TextureRect = f[0]
		if is_instance_valid(tr):
			tr.position = (f[1] as Vector2).round()
			tr.rotation = float(f[2])
	# The shelf on the shops page: the picked pack a little bigger and lit, the others dimmed.
	for i in _shelf_btns.size():
		var w: PackWrapper = _shelf_btns[i][1]
		if not is_instance_valid(w):
			continue
		var on := i == _pick
		w.glow = lerpf(w.glow, 1.0 if on else 0.0, clampf(delta * 8.0, 0.0, 1.0))
		var s := lerpf(w.scale.x, 1.06 if on else 0.9, clampf(delta * 9.0, 0.0, 1.0))
		w.scale = Vector2(s, s)
		w.modulate = w.modulate.lerp(Color(1, 1, 1, w.modulate.a) if on else Color(0.62, 0.64, 0.7, w.modulate.a), clampf(delta * 8.0, 0.0, 1.0))


func _clear() -> void:
	for n in _box.get_children():
		n.queue_free()
	for n in _left.get_children():
		n.queue_free()
	for n in _fan.get_children():
		n.queue_free()
	_fan_cards.clear()
	_shelf_btns.clear()
	_shelf_packs.clear()
	_pick = -1


# ------------------------------------------------------------------ what you have

## The deck you duel with: its name, its lists, where it came from and the slot it lives in
## (-1 when it is a ready-made deck with no copy in your slots).
static func deck_now() -> Dictionary:
	var k := Collection.active_deck()
	if k == "custom":
		var origin := ""
		if Collection.slot >= 0 and Collection.slot < Collection.slots.size():
			origin = str(Collection.slots[Collection.slot].get("origin", ""))
		return {"name": Collection.deck_name, "main": Collection.main.duplicate(), "extra": Collection.extra.duplicate(), "side": Collection.side.duplicate(),
			"key": "", "slot": Collection.slot, "origin": origin, "ok": Collection.deck_ok()}
	return {"name": CardData.deck_name(k), "main": Array(CardData.deck_list(k)), "extra": Array(CardData.extra_list(k)), "side": [],
		"key": k, "slot": Collection.origin_slot(k), "origin": k, "ok": true}


## Where a deck came from, in a few words: "Starter deck", "Kaiba's deck", "Built by you".
static func origin_words(d: Dictionary) -> String:
	var from := str(d.get("origin", ""))
	if from == "" or not CardData.has_deck(from):
		return Loc.t("Built by you")
	var e := Collection.deck_info(from)
	var whose := Loc.t("Starter deck") if e.get("kind", "") == "starter" else (Loc.t("A gift from Lumen") if e.get("kind", "") == "gift"
			else (Loc.t("%s's deck") % Loc.t(str(e.get("owner", ""))) if str(e.get("owner", "")) != "" else Loc.t("Theme deck")))
	if str(d.get("key", "")) == "" and int(d.get("slot", -1)) >= 0 and Collection.slot_changed(int(d["slot"])):
		whose += "  ·  " + Loc.t("changed")
	return whose


## The deck's best cards, the ace first: the cards worth showing big.
static func best_cards(d: Dictionary, n := FAN) -> Array:
	var ids := {}
	for id in (d.get("main", []) as Array) + (d.get("extra", []) as Array):
		ids[int(id)] = true
	var pool: Array = ids.keys().filter(func(id): return not CardData.get_card(id).is_empty())
	var ace := 0
	var from := str(d.get("origin", ""))
	if from != "" and CardData.has_deck(from):
		ace = Collection.deck_ace(from)
	pool.sort_custom(func(a, b):
		if (a == ace) != (b == ace):
			return a == ace
		var ca := CardData.get_card(a)
		var cb := CardData.get_card(b)
		var ma := str(ca.get("kind", "")) == "monster"
		var mb := str(cb.get("kind", "")) == "monster"
		if ma != mb:
			return ma
		var ra := CardData.rarity(a)
		var rb := CardData.rarity(b)
		if ra != rb:
			return ra > rb
		var aa := int(ca.get("atk", 0))
		var ab := int(cb.get("atk", 0))
		return aa > ab if aa != ab else a < b)
	return pool.slice(0, n)


## How much of the card list you own: [have, total]. (The same count as the album's.)
static func collection_count() -> Array:
	var every: Array = Collection.all_cards().duplicate()
	for id in CardAlbum.LUMEN_IDS + CardAlbum.SPEED_IDS:
		if not every.has(id) and not CardData.get_card(id).is_empty():
			every.append(id)
	var have := 0
	for id in every:
		if int(Collection.owned.get(int(id), 0)) > 0:
			have += 1
	return [have, every.size()]


## A slim bar: how far along something is (`f` 0..1), in a color.
static func bar(width: float, f: float, col: Color, h := 8.0) -> Control:
	var back := Panel.new()
	back.custom_minimum_size = Vector2(width, h)
	back.add_theme_stylebox_override("panel", UITheme.panel_box(Color(1, 1, 1, 0.12), int(h / 2.0), Color(0, 0, 0, 0)))
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", UITheme.panel_box(col, int(h / 2.0), Color(col.lightened(0.3), 0.8)))
	fill.position = Vector2.ZERO
	fill.size = Vector2(maxf(h, width * clampf(f, 0.0, 1.0)), h)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return back


# ------------------------------------------------------------------ the title page

## A glass button for the row under the big one (as on the Academy's door).
func _glass(text: String, col: Color, act: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 23)
	b.clip_text = true
	# The words always fit: a long label (in any language) gets a smaller size, never cut off.
	b.resized.connect(func():
		var f: Font = b.get_theme_font("font")
		var fs := 23
		while fs > 15 and f.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > b.size.x - 28.0:
			fs -= 1
		b.add_theme_font_size_override("font_size", fs))
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 14, col.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.1, 0.14, 0.26, 0.95), 14, col.lightened(0.4)))
	b.add_theme_stylebox_override("disabled", UITheme.panel_box(Color(0.03, 0.04, 0.08, 0.6), 14, Color(1, 1, 1, 0.06)))
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		act.call())
	return b


func _home() -> void:
	_clear()
	_back.shade_to(0.0)
	var d := deck_now()
	var col: Color = UITheme.GOLD
	if str(d["origin"]) != "" and CardData.has_deck(str(d["origin"])):
		col = (Collection.deck_info(str(d["origin"])).get("color", UITheme.GOLD) as Color)
	if col.get_luminance() < 0.35:
		col = col.lightened(0.35)
	_left.add_child(UITheme.label("YOUR CARDS", 19, UITheme.GOLD, UITheme.semi_font()))
	var t := UITheme.label(Loc.t("DECKS & CARDS"), 96, Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 5)
	t.add_theme_constant_override("shadow_outline_size", 10)
	_left.add_child(t)
	# The collection, as one gold bar: how much of the card list is yours.
	var cc := collection_count()
	var pct := float(cc[0]) / maxf(1.0, float(cc[1]))
	_left.add_child(bar(800, pct, UITheme.GOLD, 8.0))
	# (Under 10%, one decimal: 37 cards of 8,433 is 0.4%, not 0%.)
	var pct_txt := ("%.1f" % (pct * 100.0)) if pct < 0.1 else str(int(round(pct * 100.0)))
	var sub := UITheme.label(Loc.t("%d of %d cards in your collection  ·  %s%%") % [int(cc[0]), int(cc[1]), pct_txt]
			+ "   ·   " + Loc.t("%d DP") % Collection.dp, 23, Color(0.9, 0.93, 1.0, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(780, 0)
	_left.add_child(sub)
	var gap0 := Control.new()
	gap0.custom_minimum_size = Vector2(0, 10)
	_left.add_child(gap0)
	# The deck you duel with: its ace as the card on the left, its name, its lists and its state.
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.84), 20, Color(col, 0.75)))
	card.custom_minimum_size = Vector2(800, 0)
	_left.add_child(card)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 22)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	card.add_child(m)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	m.add_child(row)
	var best := best_cards(d, FAN)
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(86, 126)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not best.is_empty():
		face.texture = Cards.get_thumb(int(best[0]))
		Foil.apply(face, CardData.rarity(int(best[0])))
	row.add_child(face)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UITheme.label("THE DECK YOU DUEL WITH", 16, col, UITheme.semi_font()))
	var nm := UITheme.label(str(d["name"]), 40, Color.WHITE, UITheme.title_font())
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(600, 0)
	v.add_child(nm)
	var lists := Loc.t("Main %d  ·  Extra %d  ·  Side %d") % [(d["main"] as Array).size(), (d["extra"] as Array).size(), (d["side"] as Array).size()]
	v.add_child(UITheme.label(lists, 21, Color.WHITE, UITheme.semi_font()))
	var state := UITheme.label(Loc.t("Ready to duel") if bool(d["ok"]) else Loc.t("Not ready: a deck needs %d to %d cards") % [Collection.MAIN_MIN, Collection.MAIN_MAX],
			18, Color("7dffa6") if bool(d["ok"]) else Color("ff8a7a"), UITheme.semi_font())
	v.add_child(state)
	var shelf_n := 0
	for i in Collection.slots.size():
		if not Collection.slot_empty(i):
			shelf_n += 1
	var shelf_txt := Loc.t("1 deck on your shelf") if shelf_n == 1 else Loc.t("%d decks on your shelf") % shelf_n
	v.add_child(UITheme.label("%s   ·   %s" % [origin_words(d), shelf_txt], 17, UITheme.TEXT_DIM))
	# The way in: every deck you have, to pick, build, copy and rename.
	var first := Button.new()
	first.text = "▶   " + Loc.t("My decks")
	first.custom_minimum_size = Vector2(800, 92)
	first.add_theme_font_size_override("font_size", 38)
	first.clip_text = true
	UITheme.paint_button(first, col.darkened(0.3))
	first.pressed.connect(func():
		Sfx.play("click", -6.0)
		_open_decks())
	_left.add_child(first)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	row2.custom_minimum_size = Vector2(800, 0)
	_left.add_child(row2)
	var edit := _glass(Loc.t("Edit this deck"), col, _edit_now)
	row2.add_child(edit)
	row2.add_child(_glass(Loc.t("Card Album"), col, _open_album))
	row2.add_child(_glass(Loc.t("Shop shelves"), col, func(): _shops("")))
	row2.add_child(_glass(Loc.t("Back"), col, _close))
	var hint := UITheme.label(Loc.t("Booster packs and ready-made decks are bought at the card shop counter in each world. Here you can only look at their shelves."), 17, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(780, 0)
	_left.add_child(hint)
	if Saves.admin:
		var warn := UITheme.label(Loc.t("ADMIN MODE IS ON: saving is switched off."), 17, UITheme.GOLD)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.custom_minimum_size = Vector2(780, 0)
		_left.add_child(warn)
	_build_fan(best)
	first.grab_focus.call_deferred()
	# The words come in from the left, one after the other.
	var k := 0
	for n in _left.get_children():
		var c := n as Control
		c.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.05 * k)
		tw.tween_property(c, "modulate:a", 1.0, 0.25)
		k += 1


## The deck's best cards fanned out on the right half, big, the ace in front in the middle.
func _build_fan(ids: Array) -> void:
	if ids.is_empty():
		return
	var vs := get_viewport_rect().size
	if vs.x < 1500.0:
		# (On a small window the fan would sit under the words: fewer, smaller cards, further right.)
		ids = ids.slice(0, 3)
	var cw := clampf(vs.y * 0.3, 190.0, 330.0)
	var ch := cw * 1.459
	var cx := vs.x * 0.75
	var cy := vs.y * 0.5 - ch * 0.5
	var n := ids.size()
	# Behind the fan, the deck's name on a soft plate of light.
	var order: Array = []          # the ace in the middle: [i, slot] with slot -2..2
	var slots := [0, -1, 1, -2, 2]
	for i in n:
		order.append([i, slots[i]])
	order.sort_custom(func(a, b): return absi(int(a[1])) > absi(int(b[1])))   # the outer ones first, so the ace sits on top
	for o in order:
		var i: int = o[0]
		var s: int = o[1]
		var id := int(ids[i])
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(id, true)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var scale_k := 1.0 - absi(s) * 0.09
		tr.size = Vector2(cw, ch) * scale_k
		tr.pivot_offset = tr.size * Vector2(0.5, 1.0)
		var base := Vector2(cx + s * cw * 0.5 - tr.size.x * 0.5, cy + absi(s) * ch * 0.05 + (ch - tr.size.y))
		var rot := s * 0.085
		tr.position = base
		tr.rotation = rot
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color(1, 1, 1, 0.0) if s == 0 else Color(0.82, 0.84, 0.9, 0.0)
		Foil.apply(tr, CardData.rarity(id))
		_fan.add_child(tr)
		_fan_cards.append([tr, base, rot])
		var tw := tr.create_tween().set_parallel()
		tw.tween_property(tr, "modulate:a", 1.0, 0.35).set_delay(0.12 + 0.07 * absi(s))
	# The ace's name under the fan.
	var ace_name := UITheme.label(str(CardData.get_card(int(ids[0])).get("name", "")), 26, Color.WHITE, UITheme.title_font())
	ace_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ace_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	ace_name.add_theme_constant_override("shadow_outline_size", 8)
	ace_name.size = Vector2(cw * 2.6, 40)
	ace_name.position = Vector2(cx - cw * 1.3, cy + ch + 26)
	ace_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fan.add_child(ace_name)
	var tag := UITheme.label(Loc.t("The best of this deck"), 17, UITheme.TEXT_DIM, UITheme.semi_font())
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.size = Vector2(cw * 2.6, 26)
	tag.position = Vector2(cx - cw * 1.3, cy + ch + 64)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fan.add_child(tag)


# ------------------------------------------------------------------ the doors out of here

## A window over this screen; this screen comes back (rebuilt: the deck may have changed) when it closes.
func _over(w: Control, back: Callable) -> void:
	_busy = true
	_fan.visible = false
	w.closed.connect(func():
		_busy = false
		_fan.visible = true
		back.call())


func _open_decks() -> void:
	var db := DeckMenu.new()
	db.z_index = 110
	add_child(db)
	_over(db, _home)


## Edit the deck you duel with, as My decks does it: your own deck in its slot, or the copy of the
## ready-made deck in your slots. A ready-made deck with no copy yet: My decks, where you can make one.
func _edit_now() -> void:
	var d := deck_now()
	var i := int(d["slot"])
	if i < 0 or i >= Collection.slots.size():
		Router.toast(Loc.t("This ready-made deck has no copy of yours yet: make one in My decks."))
		_open_decks()
		return
	var was_slot := Collection.slot
	var was_custom := Collection.active == "custom"
	Collection.load_slot(i)
	var builder := DeckBuilder.new()
	builder.z_index = 110
	add_child(builder)
	_busy = true
	_fan.visible = false
	await builder.closed
	if was_custom and was_slot != i and not builder.picked:
		Collection.load_slot(was_slot)
	_busy = false
	_fan.visible = true
	_home()


func _open_album() -> void:
	var a := CardAlbum.open(self)
	_over(a, _home)


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _left.get_child_count() == 0:
			_home()
		else:
			_close()
	elif _world != "" and _left.get_child_count() == 0:
		# On the shops page: Q / E (LB / RB) move between the worlds.
		var i := SHOP_WORLDS.find(_world)
		if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_Q or event.keycode == KEY_E):
			get_viewport().set_input_as_handled()
			_shops(SHOP_WORLDS[posmod(i + (1 if event.keycode == KEY_E else -1), SHOP_WORLDS.size())])
		elif event is InputEventJoypadButton and event.pressed and (event.button_index == JOY_BUTTON_LEFT_SHOULDER or event.button_index == JOY_BUTTON_RIGHT_SHOULDER):
			get_viewport().set_input_as_handled()
			_shops(SHOP_WORLDS[posmod(i + (1 if event.button_index == JOY_BUTTON_RIGHT_SHOULDER else -1), SHOP_WORLDS.size())])


# ------------------------------------------------------------------ the card shops

## The packs on a world's shelf: that world's own series and families (and the Vault), as the
## shop in that world stocks them.
static func world_packs(world: String) -> Array:
	var all: Array = Collection.shop_packs().filter(func(p): return int(p.get("tab", 0)) <= 1)
	var mine: Array = PackShop.WORLD_PACKS.get(world, [])
	var out: Array = all.filter(func(p): return Collection.base_key(str(p["key"])) in mine or (p.get("families", []) as Array).any(func(f): return f in mine))
	return out if not out.is_empty() else all


## The ready-made decks the same counter sells: its era's duelists and the theme decks stocked there.
static func world_decks(world: String) -> Array:
	var era := str(Collection.WORLD_ERA.get(world, ""))
	var out: Array = []
	for e in Collection.deck_catalog():
		if (e["kind"] == "duelist" and str(e["era"]) == era) or (e["kind"] == "theme" and Collection.theme_sold_in(str(e["key"]), world)):
			out.append(e)
	return out


## The shop's name in its world, as the map calls it.
static func shop_name(world: String) -> String:
	if world == "domino":
		return "Kame Game"
	if world == "academy":
		return Loc.t("Dorothy's shop")
	return Loc.t("Card Shop")


func _shops(world: String) -> void:
	if world == "":
		# Open on the world you are furthest into that has a shop.
		world = "domino"
		for w in SHOP_WORLDS:
			if Unlocks.world(w):
				world = w
	_clear()
	_world = world
	_back.shade_to(0.78)
	var col := StoryGate.world_color(world)
	var title := UITheme.label(Loc.t("CARD SHOPS"), 54, Color.WHITE, UITheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)
	var sub := UITheme.label("What each world's card shop keeps on its shelf. To buy, walk in and talk at the counter.", 21, UITheme.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(sub)
	# One tab a world, in its color. A world the story has not reached yet is shown, but shut.
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	_box.add_child(tabs)
	var here_tab: Button = null
	for w in SHOP_WORLDS:
		var wc := StoryGate.world_color(w)
		var tb := Button.new()
		tb.toggle_mode = true
		tb.button_pressed = w == world
		tb.text = "  %s  " % StoryGate.world_name(w)
		tb.custom_minimum_size = Vector2(0, 50)
		tb.add_theme_font_size_override("font_size", 21)
		tb.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.7), 12, Color(wc, 0.35)))
		tb.add_theme_stylebox_override("hover", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 12, wc))
		tb.add_theme_stylebox_override("focus", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 12, wc))
		tb.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(wc.darkened(0.55), 0.95), 12, wc.lightened(0.3)))
		tb.add_theme_stylebox_override("hover_pressed", UITheme.panel_box(Color(wc.darkened(0.5), 0.95), 12, wc.lightened(0.4)))
		for fc in ["font_pressed_color", "font_hover_pressed_color"]:
			tb.add_theme_color_override(fc, Color.WHITE)
		if not Unlocks.world(w):
			tb.modulate = Color(1, 1, 1, 0.55)
			tb.tooltip_text = Unlocks.world_why(w)
		var wk: String = w
		tb.pressed.connect(func():
			Sfx.play("click", -8.0)
			_shops(wk))
		tabs.add_child(tb)
		if w == world:
			here_tab = tb
	var hint := UITheme.label("Q / E  or  LB / RB", 15, UITheme.TEXT_DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs.add_child(hint)
	# The shop itself: its name, and how to get there.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	_box.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(UITheme.label(shop_name(world).to_upper(), 34, col.lightened(0.35), UITheme.title_font()))
	var packs := world_packs(world)
	var decks := world_decks(world)
	hv.add_child(UITheme.label(Loc.t("%s  ·  %d booster packs  ·  %d ready-made decks") % [StoryGate.world_name(world), packs.size(), decks.size()], 18, UITheme.TEXT_DIM, UITheme.semi_font()))
	var purse := PanelContainer.new()
	purse.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.08, 0.02, 0.9), 14, Color(UITheme.GOLD, 0.8)))
	purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	purse.add_child(UITheme.label(Loc.t("%d DP") % Collection.dp, 28, UITheme.GOLD, UITheme.title_font()))
	head.add_child(purse)
	var go := Button.new()
	go.custom_minimum_size = Vector2(340, 62)
	go.add_theme_font_size_override("font_size", 24)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if Unlocks.world(world):
		go.text = "➜   " + Loc.t("Go to this shop")
		UITheme.paint_button(go, col.darkened(0.35))
		go.pressed.connect(func():
			Sfx.play("gong", -8.0)
			go_to_shop(world))
	else:
		go.text = Loc.t("Not open yet")
		go.disabled = true
		go.tooltip_text = Unlocks.world_why(world)
	head.add_child(go)
	var back := _glass(Loc.t("Back"), col, _home)
	back.custom_minimum_size = Vector2(150, 62)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(back)
	# The shelf of packs: the packs are the stars here, as on the counter itself.
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(1240, 286)
	sc.follow_focus = true
	_box.add_child(sc)
	var pad := MarginContainer.new()
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 14)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(pad)
	var shelf := HBoxContainer.new()
	shelf.add_theme_constant_override("separation", 18)
	shelf.alignment = BoxContainer.ALIGNMENT_CENTER
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(shelf)
	_shelf_packs = packs
	for i in packs.size():
		var p: Dictionary = packs[i]
		var b := Button.new()
		b.flat = true
		b.custom_minimum_size = Vector2(160, 270)
		b.focus_mode = Control.FOCUS_ALL
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var wrap := PackWrapper.new().setup(p)
		wrap.custom_minimum_size = Vector2(160, 246)
		wrap.size = Vector2(160, 246)
		wrap.position = Vector2(0, 20)
		wrap.pivot_offset = Vector2(80, 246)
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(wrap)
		var k := i
		b.focus_entered.connect(func(): _pick_pack(k))
		b.pressed.connect(func():
			if _pick == k:
				_see_pack()
			else:
				_pick_pack(k))
		shelf.add_child(b)
		_shelf_btns.append([b, wrap])
		wrap.modulate.a = 0.0
		var tw := wrap.create_tween()
		tw.tween_property(wrap, "modulate:a", 1.0, 0.22).set_delay(0.04 * i)
	var plank := ColorRect.new()
	plank.color = Color(col, 0.5)
	plank.custom_minimum_size = Vector2(0, 3)
	_box.add_child(plank)
	# The pack you are looking at: what it is, how much of it you have, what it costs there.
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 26)
	_box.add_child(info)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 4)
	iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(iv)
	_pack_name = UITheme.label("", 34, Color.WHITE, UITheme.title_font())
	iv.add_child(_pack_name)
	_pack_blurb = UITheme.label("", 19, UITheme.TEXT)
	_pack_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pack_blurb.custom_minimum_size = Vector2(760, 0)
	iv.add_child(_pack_blurb)
	_pack_have = UITheme.label("", 18, UITheme.TEXT_DIM, UITheme.semi_font())
	iv.add_child(_pack_have)
	_pack_bar = Control.new()
	_pack_bar.custom_minimum_size = Vector2(480, 10)
	iv.add_child(_pack_bar)
	var iv2 := VBoxContainer.new()
	iv2.add_theme_constant_override("separation", 8)
	iv2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(iv2)
	_pack_price = UITheme.label("", 22, UITheme.GOLD, UITheme.semi_font())
	_pack_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	iv2.add_child(_pack_price)
	_see_btn = _glass("", col, _see_pack)
	_see_btn.custom_minimum_size = Vector2(360, 56)
	_see_btn.add_theme_font_size_override("font_size", 20)
	iv2.add_child(_see_btn)
	# The ready-made decks on the same counter, small, as their boxes.
	if not decks.is_empty():
		var dl := UITheme.label(Loc.t("READY-MADE DECKS AT THIS COUNTER"), 17, col.lightened(0.3), UITheme.semi_font())
		_box.add_child(dl)
		var dsc := ScrollContainer.new()
		dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		dsc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		dsc.custom_minimum_size = Vector2(1240, 214)
		dsc.follow_focus = true
		_box.add_child(dsc)
		var drow := HBoxContainer.new()
		drow.add_theme_constant_override("separation", 12)
		dsc.add_child(drow)
		for e in decks:
			var db := Button.new()
			db.flat = true
			db.custom_minimum_size = Vector2(132, 202)
			db.focus_mode = Control.FOCUS_ALL
			for st in ["normal", "pressed"]:
				db.add_theme_stylebox_override(st, StyleBoxEmpty.new())
			for st in ["hover", "focus"]:
				db.add_theme_stylebox_override(st, UITheme.panel_box(Color(1, 1, 1, 0.06), 10, Color(e.get("color", col), 0.9)))
			var box := DeckBox.new().setup(e)
			box.owned = Collection.owns_deck(str(e["key"]))
			box.custom_minimum_size = Vector2(124, 174)
			box.size = Vector2(124, 174)
			box.position = Vector2(4, 4)
			db.add_child(box)
			var owner := str(e.get("owner", ""))
			db.tooltip_text = "%s%s  ·  %d DP%s" % [str(e["name"]), ("  ·  " + Loc.t(owner)) if owner != "" else "", int(e.get("price", 0)),
					("  ·  " + Loc.t("Yours")) if box.owned else ""]
			var entry: Dictionary = e
			db.pressed.connect(func():
				Sfx.play("click", -6.0)
				_see(CardListView.new("deck", entry)))
			drow.add_child(db)
	if not packs.is_empty():
		_pick_pack(0)
		(_shelf_btns[0][0] as Button).grab_focus.call_deferred()
	elif here_tab:
		here_tab.grab_focus.call_deferred()


func _pick_pack(i: int) -> void:
	if i < 0 or i >= _shelf_packs.size():
		return
	if _pick != i:
		Sfx.play("hover", -14.0)
	_pick = i
	var p: Dictionary = _shelf_packs[i]
	var pool: Array = Collection.pool(str(p["key"]))
	var have := 0
	for id in pool:
		if Collection.count(id) > 0:
			have += 1
	_pack_name.text = Loc.t(str(p.get("name", "")))
	_pack_blurb.text = Loc.t(str(p.get("blurb", "")))
	_pack_have.text = Loc.t("You have %d of %d cards.") % [have, pool.size()]
	for c in _pack_bar.get_children():
		c.queue_free()
	_pack_bar.add_child(bar(480, float(have) / maxf(1.0, float(pool.size())), UITheme.GOLD, 10.0))
	if not Unlocks.pack(str(p["key"])):
		_pack_price.text = Unlocks.pack_why(str(p["key"]))
		_pack_price.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	else:
		_pack_price.text = Loc.t("%d DP a pack at the counter") % Collection.pack_price(p)
		_pack_price.add_theme_color_override("font_color", UITheme.GOLD)
	_see_btn.text = Loc.t("SEE ALL %d CARDS") % pool.size()
	_see_btn.disabled = pool.is_empty()


func _see_pack() -> void:
	if _pick < 0 or _pick >= _shelf_packs.size() or Collection.pool(str(_shelf_packs[_pick]["key"])).is_empty():
		return
	Sfx.play("click")
	_see(CardListView.new("pack", _shelf_packs[_pick]))


## A card list over the shops page; focus comes back to where it was.
func _see(v: Control) -> void:
	var had := get_viewport().gui_get_focus_owner()
	_busy = true
	add_child(v)
	await v.closed
	_busy = false
	if is_instance_valid(had):
		had.grab_focus.call_deferred()


## Into the world, at its card shop: Free Roam there, with the guide showing the way to the counter.
static func go_to_shop(world: String) -> void:
	Router.roam["district"] = world
	Router.roam["free"] = true
	Router.roam["pos"] = null
	Router.roam.erase("yaw")
	Router.roam.erase("tod")
	Router.roam["guide"] = "shop"
	if world == "domino":
		# (Out on the street, a few steps from Kame Game's door.)
		Router.roam["pos"] = Vector3(-10, 0, -11.0)
		Router.roam["yaw"] = PI
	Router.go(Router.ROAM)
