class_name CardAlbum
extends Control
## The Card Album: a binder with a pocket for every card you can collect, set by set. Cards you
## own sit in their pockets with their foil; cards you have only met in a duel show dimmed; the
## rest are empty pockets with a number. Pick a card for the big view on the right. Every booster
## set shows how much of it you own and the Duel Points waiting at 25, 50, 75 and 100%.
## Opens over the main menu, My Decks or the open world.

signal closed

const PER_PAGE := 9
const SPREAD := 18
const ROWS := 3
const COLS := 3
const LUMEN_IDS := CardData.LUMEN_CARDS
const SPEED_IDS := CardData.SPEED_SPELLS

var _sets: Array = []            # [{key, name, color, ids, group}]
var _set := 0
var _filter := "all"             # all | owned | missing
var _search := ""
var _list: Array = []            # the ids shown in this set, after filter and search
var _spread := 0
var _sel := 0                    # 0..17 inside the spread
var _new_ids := {}
var _played_by := {}             # id -> [names]
var _comes_from := {}            # id -> [pack names]

var _set_buttons: Array = []
var _slots: Array = []           # 18 AlbumSlot
var _spread_box: Control
var _binder: Control
var _set_title: Label
var _set_count: Label
var _set_bar: Control
var _rewards: HBoxContainer
var _page_label: Label
var _filter_btns := {}
var _search_box: LineEdit
var _search_wait: Timer
var _total_label: Label
var _total_pct: Label
var _hint: Label
# The big view on the right.
var _d_face: TextureRect
var _d_unknown: Control
var _d_name: Label
var _d_type: Label
var _d_stats: Label
var _d_text: Label
var _d_owned: Label
var _d_from: Label
var _d_who: Label
var _where_btn: Button      # "Where to find it": opens CardWhere (0.55.3)
var _where_sum: Label       # "3 packs · 2 decks · 4 duelists"
var _d_card_id := -1


static func open(host: Node) -> CardAlbum:
	var a := CardAlbum.new()
	a.z_index = 110
	host.add_child(a)
	return a


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	if "--album-demo" in OS.get_cmdline_user_args():
		# Dev (screenshots): some cards met in duels, some just collected.
		var k := 0
		for id in Collection.all_cards():
			if int(Collection.owned.get(int(id), 0)) == 0 and k % 3 == 0:
				Collection.meet(int(id))
			k += 1
		var shown := {"0": true, "1": true}
		var j := 0
		for id in Collection.owned:
			if j % 4 != 0:
				shown[str(id)] = true
			j += 1
		Collection.record["album_seen"] = shown
	_build_data()
	_build_ui()
	# Anything collected since the last look pays now.
	var pays: Array = Goals.pay_album()
	var dp := 0
	for line in pays:
		dp += int(line[1])
	if dp > 0:
		Router.toast(Loc.t("Collection rewards: +%d Duel Points") % dp, 3.5)
		Sfx.play("quest", -3.0)
	var first := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--album-set="):
			first = int(a.trim_prefix("--album-set="))
	_pick_set(first, false)
	Sfx.play("card", -6.0, 0.8)
	modulate.a = 0.0
	scale = Vector2(0.985, 0.985)
	pivot_offset = get_viewport_rect().size / 2.0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ data

func _build_data() -> void:
	var met: Dictionary = Collection.record.get("met", {})
	var shown: Dictionary = Collection.record.get("album_seen", {})
	for id in Collection.owned:
		if int(Collection.owned[id]) > 0 and not shown.has(str(id)):
			_new_ids[int(id)] = true
	# The first time the album opens, nothing is "new": you have had all of it a while.
	if shown.is_empty():
		_new_ids.clear()
	var every: Array = Collection.all_cards().duplicate()
	for id in LUMEN_IDS + SPEED_IDS:
		if not every.has(id) and not CardData.get_card(id).is_empty():
			every.append(id)
	_sets.append({"key": "all", "name": "Every card", "color": Color("8fb8ff"), "ids": _sorted(every), "group": ""})
	for p in Collection.PACKS:
		var key := str(p["key"])
		var ids: Array = []
		if key == "echo":
			continue
		ids = Collection.pool(key)
		if ids.is_empty():
			continue
		for id in ids:
			if not _comes_from.has(int(id)):
				_comes_from[int(id)] = []
			(_comes_from[int(id)] as Array).append(str(p["name"]))
		_sets.append({"key": key, "name": str(p["name"]), "color": p["color"], "ids": _sorted(ids),
				"group": "BOOSTER SETS" if int(p["tab"]) <= 1 else "BY KIND"})
		if key == "Vault":
			# The special ones sit after the era sets.
			pass
	var lumen: Array = []
	for id in LUMEN_IDS:
		if not CardData.get_card(id).is_empty():
			lumen.append(id)
			# (0.81.0) The Echo cards around her are in the pack from the first day; all of them are in her decks.
			_comes_from[id] = ["The Echo Pack and Lumen's decks in the deck shops"]
	var speed: Array = []
	for id in SPEED_IDS:
		if not CardData.get_card(id).is_empty():
			speed.append(id)
			_comes_from[id] = ["Turbo Duels"]
	_sets.append({"key": "lumen", "name": "Lumen's cards", "color": Color("7fe8ff"), "ids": _sorted(lumen), "group": "SPECIAL"})
	_sets.append({"key": "speed", "name": "Speed Spells", "color": Color("ff8a3a"), "ids": _sorted(speed), "group": "SPECIAL"})
	# Order: Every card, the booster sets, the special ones, then by kind.
	var order := {"": 0, "BOOSTER SETS": 1, "SPECIAL": 2, "BY KIND": 3}
	var tagged: Array = []
	for i in _sets.size():
		tagged.append([int(order.get(str(_sets[i]["group"]), 9)), i, _sets[i]])
	tagged.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	_sets = tagged.map(func(t): return t[2])
	# Who plays each card (for the big view).
	for k in Characters.ORDER:
		var info := Characters.get_char(str(k))
		var dk := str(info.get("deck", ""))
		if str(k) == "player" or dk == "" or not CardData.has_deck(dk):
			continue
		var nm := str(info.get("name", k))
		for id in CardData.deck_list(dk, true) + CardData.extra_list(dk, true):
			if not _played_by.has(int(id)):
				_played_by[int(id)] = []
			if not (_played_by[int(id)] as Array).has(nm):
				(_played_by[int(id)] as Array).append(nm)
	var _unused = met


## Monsters first, then Spells, Traps, and the Extra Deck at the end; by name within each.
## (0.72.3: each card's place is worked out once and the list is sorted by plain text. It used to ask
## the card data twice for every comparison: with every card in the game, opening the album took
## seconds, most of it here.)
static var _sort_keys := {}

func _sorted(ids: Array) -> Array:
	var keyed := PackedStringArray()
	keyed.resize(ids.size())
	for i in ids.size():
		var id := int(ids[i])
		var k = _sort_keys.get(id)
		if k == null:
			var d := CardData.get_card(id)
			var rank: int = {"monster": 0, "spell": 1, "trap": 2}.get(str(d.get("kind", "")), 3) + (10 if CardData.is_extra(id) else 0)
			k = "%02d%s" % [rank, str(d.get("name", ""))]
			_sort_keys[id] = k
		keyed[i] = "%s\t%d" % [k, id]
	keyed.sort()
	var out: Array = []
	out.resize(keyed.size())
	for i in keyed.size():
		out[i] = int(keyed[i].get_slice("\t", 1))
	return out


func _state(id: int) -> String:
	if int(Collection.owned.get(id, 0)) > 0:
		return "owned"
	if (Collection.record.get("met", {}) as Dictionary).has(str(id)):
		return "seen"
	# (0.55.3: every card shows its picture, in grey when it isn't yours. It was a "?" until you met it.)
	return "missing"


func _have(ids: Array) -> int:
	var n := 0
	for id in ids:
		if int(Collection.owned.get(int(id), 0)) > 0:
			n += 1
	return n


# ------------------------------------------------------------------ layout

func _build_ui() -> void:
	add_child(AcademyBackdrop.new(0.58, CardsGate.PICTURE, Color(1.0, 0.86, 0.5)))
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 52)
	m.add_theme_constant_override("margin_right", 52)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 22)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	m.add_child(root)
	# Header.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 22)
	root.add_child(head)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", -4)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tb)
	tb.add_child(UITheme.label(Loc.t("CARD ALBUM"), 54, Color.WHITE, UITheme.title_font()))
	tb.add_child(UITheme.label(Loc.t("Every card you can collect, set by set. Own more of a booster set to earn its rewards."), 19, UITheme.TEXT_DIM))
	var total := PanelContainer.new()
	total.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.08, 0.02, 0.9), 16, Color(UITheme.GOLD, 0.8)))
	total.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(total)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 12)
	total.add_child(th)
	var all_ids: Array = _sets[0]["ids"]
	var have := _have(all_ids)
	_total_label = UITheme.label("%d / %d" % [have, all_ids.size()], 32, UITheme.GOLD, UITheme.title_font())
	th.add_child(_total_label)
	_total_pct = UITheme.label(Loc.t("%d%% collected") % int(round(100.0 * have / maxf(1.0, all_ids.size()))), 19, Color(UITheme.GOLD, 0.8), UITheme.semi_font())
	_total_pct.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	th.add_child(_total_pct)
	var done := Button.new()
	done.text = "  Done  "
	done.add_theme_font_size_override("font_size", 24)
	done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	done.custom_minimum_size = Vector2(0, 58)
	done.focus_mode = Control.FOCUS_NONE
	done.pressed.connect(_close)
	head.add_child(done)
	# Body: sets | binder | the card.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_sets())
	body.add_child(_build_center())
	body.add_child(_build_detail())
	_hint = UITheme.label("", 17, UITheme.TEXT_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)
	_relabel_hint()
	if not Pad.changed.is_connected(_relabel_hint):
		Pad.changed.connect(_relabel_hint)


func _build_sets() -> Control:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(330, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var group := "-"
	for i in _sets.size():
		var s: Dictionary = _sets[i]
		if str(s["group"]) != group:
			group = str(s["group"])
			if group != "":
				var gl := UITheme.label(Loc.t(group), 15, UITheme.TEXT_DIM, UITheme.semi_font())
				gl.custom_minimum_size = Vector2(0, 30)
				gl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
				v.add_child(gl)
		var b := _SetButton.new()
		b.title = Loc.t(str(s["name"]))
		b.col = Color(s["color"])
		b.have = _have(s["ids"])
		b.total = (s["ids"] as Array).size()
		b.pressed.connect(_pick_set.bind(i, true))
		v.add_child(b)
		_set_buttons.append(b)
	return sc


func _build_center() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The set's name, how much of it you own, its rewards.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	v.add_child(top)
	_set_title = UITheme.label("", 34, Color.WHITE, UITheme.title_font())
	top.add_child(_set_title)
	_set_count = UITheme.label("", 22, UITheme.TEXT, UITheme.semi_font())
	_set_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_set_count)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_rewards = HBoxContainer.new()
	_rewards.add_theme_constant_override("separation", 8)
	_rewards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_rewards)
	_set_bar = _Bar.new()
	_set_bar.custom_minimum_size = Vector2(0, 8)
	v.add_child(_set_bar)
	# The binder.
	_binder = _Binder.new()
	_binder.custom_minimum_size = Vector2(1000, 650)
	_binder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.clip_safe(_binder)
	_binder.gui_input.connect(_binder_input)
	v.add_child(_binder)
	_spread_box = Control.new()
	_spread_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_binder.add_child(_spread_box)
	for i in SPREAD:
		var s := AlbumSlot.new()
		s.picked.connect(_on_slot_picked)
		_spread_box.add_child(s)
		_slots.append(s)
	_binder.resized.connect(_place_slots)
	# Pages, filter, search.
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	v.add_child(foot)
	var prev := RoundButton.new("back", Comic.BLUE, 48.0)
	prev.pressed.connect(_flip.bind(-1))
	foot.add_child(prev)
	_page_label = UITheme.label("", 20, UITheme.TEXT, UITheme.semi_font())
	_page_label.custom_minimum_size = Vector2(150, 0)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(_page_label)
	var nxt := _NextButton.new()
	nxt.pressed.connect(_flip.bind(1))
	foot.add_child(nxt)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp2)
	for f in [["all", "All"], ["owned", "Owned"], ["missing", "Missing"]]:
		var fb := Button.new()
		fb.text = "  %s  " % Loc.t(str(f[1]))
		fb.toggle_mode = true
		fb.focus_mode = Control.FOCUS_NONE
		fb.custom_minimum_size = Vector2(0, 46)
		fb.add_theme_font_size_override("font_size", 19)
		fb.pressed.connect(_set_filter.bind(str(f[0])))
		foot.add_child(fb)
		_filter_btns[str(f[0])] = fb
	_search_box = LineEdit.new()
	_search_box.placeholder_text = Loc.t("Search (English or Spanish name)")
	_search_box.custom_minimum_size = Vector2(380, 46)
	_search_box.add_theme_font_size_override("font_size", 18)
	_search_box.clear_button_enabled = true
	# (0.59.1) The search runs a moment after the last key, not on every key: typing fast
	# no longer queues one search of the whole album per letter.
	_search_wait = Timer.new()
	_search_wait.one_shot = true
	_search_wait.wait_time = 0.15
	_search_wait.timeout.connect(func():
		_search = CardSearch.fold(_search_box.text)
		_refilter(true))
	add_child(_search_wait)
	_search_box.text_changed.connect(func(_t): _search_wait.start())
	_search_box.text_submitted.connect(func(_t):
		_search_wait.stop()
		_search = CardSearch.fold(_search_box.text)
		_refilter(true)
		_search_box.release_focus())
	foot.add_child(_search_box)
	if OS.get_environment("ALBUM_SEARCH") != "" or OS.get_environment("ALBUM_TYPE") != "":
		# (dev: open with a search typed in)
		_search_box.set_deferred("text", OS.get_environment("ALBUM_SEARCH"))
		_search = CardSearch.fold(OS.get_environment("ALBUM_SEARCH"))
		_refilter.call_deferred(true)
		if OS.get_environment("ALBUM_TYPE") != "":
			# (dev: type a word one letter at a time, and time each search)
			var word := OS.get_environment("ALBUM_TYPE")
			get_tree().create_timer(2.0).timeout.connect(func():
				for k in range(1, word.length() + 1):
					var t0 := Time.get_ticks_usec()
					_search_box.text = word.substr(0, k)
					_search = CardSearch.fold(_search_box.text)
					_refilter(true)
					print("ALBUM TYPE '%s' %d ms, %d cards" % [word.substr(0, k), (Time.get_ticks_usec() - t0) / 1000, _list.size()])
					await get_tree().process_frame
					await get_tree().process_frame
				for k in range(word.length() - 1, -1, -1):
					var t1 := Time.get_ticks_usec()
					_search_box.text = word.substr(0, k)
					_search = CardSearch.fold(_search_box.text)
					_refilter(true)
					print("ALBUM BACK '%s' %d ms, %d cards" % [word.substr(0, k), (Time.get_ticks_usec() - t1) / 1000, _list.size()])
					await get_tree().process_frame)
		if OS.get_environment("ALBUM_WHERE") != "":
			get_tree().create_timer(1.5).timeout.connect(_open_where)
	return v


func _build_detail() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.052, 0.0824, 0.156, 0.92), 20, Color(UITheme.ACCENT, 0.25)))
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(pm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pm.add_child(v)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 360)
	v.add_child(holder)
	_d_face = TextureRect.new()
	_d_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_d_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_d_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_d_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_d_face)
	_d_unknown = _Mystery.new()
	_d_unknown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_d_unknown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_d_unknown)
	_d_name = UITheme.label("", 27, Color.WHITE, UITheme.title_font())
	_d_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_d_name)
	_d_type = UITheme.label("", 17, UITheme.ACCENT, UITheme.semi_font())
	_d_type.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_d_type)
	_d_stats = UITheme.label("", 19, UITheme.TEXT, UITheme.semi_font())
	v.add_child(_d_stats)
	var ts := ScrollContainer.new()
	ts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ts.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(ts)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 10)
	ts.add_child(tv)
	_d_text = UITheme.label("", 16, Color(0.86, 0.9, 1.0, 0.92))
	_d_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_text.custom_minimum_size = Vector2(320, 0)
	tv.add_child(_d_text)
	_d_owned = UITheme.label("", 17, UITheme.GOLD, UITheme.semi_font())
	_d_owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_d_owned)
	_d_from = UITheme.label("", 15, UITheme.TEXT_DIM)
	_d_from.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_d_from)
	_d_who = UITheme.label("", 15, UITheme.TEXT_DIM)
	_d_who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_d_who)
	# Where to find it: a short count, and a button that opens the full window with the packs,
	# decks and duelists world by world (it was a paragraph of text until 0.55.3).
	_where_sum = UITheme.label("", 15, UITheme.TEXT_DIM, UITheme.semi_font())
	_where_sum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_where_sum)
	_where_btn = Button.new()
	_where_btn.text = Loc.t("WHERE TO FIND IT")
	_where_btn.add_theme_font_size_override("font_size", 21)
	_where_btn.custom_minimum_size = Vector2(0, 52)
	_where_btn.focus_mode = Control.FOCUS_NONE
	_where_btn.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.ACCENT, 0.2), UITheme.ACCENT, 14))
	_where_btn.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.ACCENT, 0.38), Color.WHITE, 14))
	_where_btn.add_theme_stylebox_override("pressed", UITheme.button_box(Color(UITheme.ACCENT, 0.5), Color.WHITE, 14))
	_where_btn.pressed.connect(_open_where)
	v.add_child(_where_btn)
	return panel


func _open_where() -> void:
	if _d_card_id == 0 or _d_card_id in SPEED_IDS or find_children("*", "CardWhere", false, false).size() > 0:
		return
	Sfx.play("click")
	add_child(CardWhere.new(_d_card_id))


func _place_slots() -> void:
	var b: _Binder = _binder
	var page_w := (b.size.x - b.SPINE) / 2.0
	var slot := AlbumSlot.CARD + Vector2(14, 14)
	var gap := Vector2(10, 10)
	var grid := Vector2(slot.x * COLS + gap.x * (COLS - 1), slot.y * ROWS + gap.y * (ROWS - 1))
	var top := maxf(12.0, (b.size.y - grid.y) / 2.0)
	for i in SPREAD:
		var page := i / PER_PAGE
		var k := i % PER_PAGE
		var x0 := page * (page_w + b.SPINE) + (page_w - grid.x) / 2.0
		var s: AlbumSlot = _slots[i]
		s.position = Vector2(x0 + (k % COLS) * (slot.x + gap.x), top + (k / COLS) * (slot.y + gap.y))
		s.size = slot


# ------------------------------------------------------------------ behaviour

func _pick_set(i: int, sound := true) -> void:
	_set = clampi(i, 0, _sets.size() - 1)
	for k in _set_buttons.size():
		(_set_buttons[k] as _SetButton).active = k == _set
	var s: Dictionary = _sets[_set]
	_set_title.text = Loc.t(str(s["name"]))
	_set_title.add_theme_color_override("font_color", Color(s["color"]).lightened(0.25))
	(_binder as _Binder).tint = Color(s["color"])
	_binder.queue_redraw()
	_refresh_rewards()
	if sound:
		Sfx.play("click", -8.0)
	_refilter(false)


func _refresh_rewards() -> void:
	var s: Dictionary = _sets[_set]
	var ids: Array = s["ids"]
	var have := _have(ids)
	_set_count.text = Loc.t("%d of %d owned") % [have, ids.size()]
	(_set_bar as _Bar).value = float(have) / maxf(1.0, ids.size())
	(_set_bar as _Bar).col = Color(s["color"])
	_set_bar.queue_redraw()
	for c in _rewards.get_children():
		c.queue_free()
	var row := {}
	for r in Goals.album_rows():
		if str(r["key"]) == str(s["key"]):
			row = r
	if row.is_empty():
		return
	for k in Goals.ALBUM_STEPS.size():
		var st: Array = Goals.ALBUM_STEPS[k]
		var reached := int(row["step"]) > k
		var pill := PanelContainer.new()
		pill.add_theme_stylebox_override("panel", UITheme.button_box(Color(UITheme.GOLD, 0.2) if reached else Color(0.05, 0.08, 0.15, 0.85),
				Color(UITheme.GOLD, 0.9) if reached else Color(1, 1, 1, 0.14), 10))
		var at := int(ceil(float(st[0]) * ids.size()))
		var lab := UITheme.label(("✔ " if reached else "") + "%d%%  +%d" % [int(float(st[0]) * 100.0), int(st[1]), ], 16, UITheme.GOLD if reached else UITheme.TEXT_DIM, UITheme.semi_font())
		pill.tooltip_text = Loc.t("Own %d cards of this set: +%d Duel Points") % [at, int(st[1])]
		pill.add_child(lab)
		_rewards.add_child(pill)


func _set_filter(f: String) -> void:
	_filter = f
	Sfx.play("click", -10.0)
	_refilter(true)


func _refilter(keep_page: bool) -> void:
	for k in _filter_btns:
		(_filter_btns[k] as Button).set_pressed_no_signal(k == _filter)
	var ids: Array = _sets[_set]["ids"]
	_list.clear()
	var nums := {}
	for i in ids.size():
		var id := int(ids[i])
		nums[id] = i + 1
		var st := _state(id)
		if _filter == "owned" and st != "owned":
			continue
		if _filter == "missing" and st == "owned":
			continue
		if _search != "":
			# A name you type finds the card even if you have never met it (three letters or more),
			# so you can look up where to find it. Its picture stays hidden until you meet it.
			# (Its English or its Spanish name, whatever language the game is in.)
			if not CardSearch.matches(id, str(CardData.get_card(id).get("name", "")), _search):
				continue
		_list.append(id)
	_numbers = nums
	if not keep_page:
		_spread = 0
	_spread = clampi(_spread, 0, maxi(0, _spreads() - 1))
	# Start on the first card on these pages you know (an empty pocket shows nothing).
	_sel = 0
	for i in mini(SPREAD, _list.size() - _spread * SPREAD):
		if _state(int(_list[_spread * SPREAD + i])) != "unknown":
			_sel = i
			break
	_show_spread(0)


var _numbers := {}


func _spreads() -> int:
	return maxi(1, int(ceil(float(_list.size()) / SPREAD)))


func _show_spread(dir: int) -> void:
	var s: Dictionary = _sets[_set]
	var base := _spread * SPREAD
	for i in SPREAD:
		var slot: AlbumSlot = _slots[i]
		var li := base + i
		if li < _list.size():
			var id := int(_list[li])
			slot.setup(id, int(_numbers.get(id, li + 1)), _state(id), int(Collection.owned.get(id, 0)), Color(s["color"]), _new_ids.has(id))
		else:
			slot.setup(0, 0, "unknown", 0, Color(s["color"]))
	_page_label.text = Loc.t("Pages %d-%d of %d") % [_spread * 2 + 1, _spread * 2 + 2, _spreads() * 2]
	(_binder as _Binder).empty_text = "" if not _list.is_empty() else (Loc.t("No cards match.") if _search != "" or _filter != "all" else "")
	if _list.is_empty() and _search != "" and _set != 0:
		# (the search only looks in the set you are on: say if other sets have it)
		var elsewhere := 0
		for oid in _sets[0]["ids"]:
			if CardSearch.matches(int(oid), str(CardData.get_card(int(oid)).get("name", "")), _search):
				elsewhere += 1
		if elsewhere > 0:
			(_binder as _Binder).empty_text = Loc.t("None in this set. %d in All cards (the first set on the left).") % elsewhere
	_binder.queue_redraw()
	_sel = clampi(_sel, 0, maxi(0, mini(SPREAD, _list.size() - base) - 1))
	_select(_sel, false)
	if dir != 0:
		_spread_box.position.x = 70.0 * dir
		_spread_box.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(_spread_box, "position:x", 0.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_spread_box, "modulate:a", 1.0, 0.2)


func _flip(dir: int) -> void:
	var to := clampi(_spread + dir, 0, _spreads() - 1)
	if to == _spread:
		Sfx.play("blip", -14.0, 0.7)
		return
	_mark_shown()
	_spread = to
	Sfx.play("card", -5.0, randf_range(0.95, 1.1))
	_show_spread(dir)


func _on_slot_picked(slot: AlbumSlot) -> void:
	var i := _slots.find(slot)
	if i >= 0:
		Sfx.play("click", -10.0, 1.2)
		_select(i, true)


func _select(i: int, sound: bool) -> void:
	_sel = i
	for k in SPREAD:
		(_slots[k] as AlbumSlot).selected = k == i and (_slots[k] as AlbumSlot).id != 0
	var slot: AlbumSlot = _slots[i]
	_show_card(slot.id, slot.state, slot.number)
	if sound:
		pass


func _show_card(id: int, st: String, num: int) -> void:
	if id == _d_card_id and id != 0:
		return
	_d_card_id = id
	var s: Dictionary = _sets[_set]
	if id == 0:
		_d_face.texture = null
		_d_unknown.visible = false
		for l in [_d_name, _d_type, _d_stats, _d_text, _d_owned, _d_from, _d_who, _where_sum]:
			(l as Label).text = ""
		_where_btn.visible = false
		return
	var d := CardData.get_card(id)
	var who: Array = _played_by.get(id, [])
	var from: Array = _comes_from.get(id, [])
	# Where to find it (0.54.0): the packs and which world's shop sells them, the shop decks
	# that include it, the duelists who play it. Only for cards in the game's shops and worlds.
	var special := id in SPEED_IDS      # (0.82.2: Lumen's cards have a "Where to find it" like any other)
	if special:
		_d_from.text = (Loc.t("Comes from: %s") % ", ".join(from.map(func(n): return Loc.t(str(n))))) if not from.is_empty() else ""
	else:
		_d_from.text = ""
	_where_btn.visible = not special
	_where_sum.visible = not special
	_where_sum.text = CardFinder.summary(id) if not special else ""
	if _where_sum.text == "" and not special:
		_where_sum.text = Loc.t("Not sold in any shop: it comes from the story or from duels.")
	var names := ", ".join(who.slice(0, 4))
	if who.size() > 4:
		names += " " + Loc.t("and %d more") % (who.size() - 4)
	_d_who.text = (Loc.t("Played by: %s") % names) if not who.is_empty() else ""
	if st == "unknown":
		_d_face.texture = null
		_d_unknown.visible = true
		(_d_unknown as _Mystery).tint = Color(s["color"])
		(_d_unknown as _Mystery).number = num
		_d_unknown.queue_redraw()
		_d_name.text = _shown_name(id, d) if _search.length() >= 3 else Loc.t("Not found yet")
		_d_type.text = "#%03d  ·  %s" % [num, Loc.t(str(s["name"]))]
		_d_stats.text = ""
		_d_text.text = Loc.t("Open packs of its set, or meet it in a duel to see what it is.") if _d_from.text == "" else Loc.t("You haven't found it yet. Here is where to look:")
		_d_owned.text = ""
		return
	_d_unknown.visible = false
	_d_face.texture = Cards.get_face(id, true)
	if st == "owned":
		Foil.apply(_d_face, CardData.rarity(id), id)
		_d_face.modulate = Color.WHITE
	else:
		_d_face.material = AlbumSlot.gray_material()
		_d_face.modulate = Color.WHITE
	_d_face.pivot_offset = Vector2(170, 180)
	_d_face.scale = Vector2(0.94, 0.94)
	create_tween().tween_property(_d_face, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_d_name.text = _shown_name(id, d)
	var kind := str(d.get("kind", ""))
	var bits: Array = []
	if kind == "monster":
		if d.has("attribute"):
			bits.append(Loc.t(str(d["attribute"])))
		if d.has("race"):
			bits.append(Loc.t(str(d["race"])))
		var frame := str(d.get("frame", "normal"))
		bits.append(Loc.t(frame.capitalize()))
		var lv := int(d.get("level", 0))
		if lv > 0:
			bits.append((Loc.t("Rank %d") if frame == "xyz" else Loc.t("Level %d")) % lv)
		var atk = d.get("atk", null)
		var df = d.get("def", null)
		_d_stats.text = "ATK %s   DEF %s" % ["?" if atk == null or int(atk) < 0 else str(int(atk)), "?" if df == null or int(df) < 0 else str(int(df))]
	else:
		bits.append(Loc.t("Spell") if kind == "spell" else Loc.t("Trap"))
		if d.has("race") and str(d["race"]) != "Normal":
			bits.append(Loc.t(str(d["race"])))
		_d_stats.text = ""
	var rar := CardData.rarity(id)
	if rar > 0:
		bits.append(Loc.t(Foil.NAMES[rar]))
	_d_type.text = "  ·  ".join(bits)
	var txt := str(d.get("desc", d.get("text", "")))
	if txt == "":
		txt = str(CardData.EXT.get(id, {}).get("desc", ""))
	_d_text.text = CardText.shown(str(d.get("name", "")), txt)
	var n := int(Collection.owned.get(id, 0))
	if st == "owned":
		_d_owned.text = (Loc.t("You own %d copies") % n) if n != 1 else Loc.t("You own 1 copy")
		_d_owned.add_theme_color_override("font_color", UITheme.GOLD)
	else:
		_d_owned.text = Loc.t("Seen in a duel. Not in your collection yet.") if st == "seen" else Loc.t("You don't have it yet.")
		_d_owned.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))


func _move(dx: int, dy: int) -> void:
	# The spread is 6 pockets across (two pages of 3) and 3 down.
	var page := _sel / PER_PAGE
	var k := _sel % PER_PAGE
	var col := page * COLS + k % COLS
	var row := k / COLS
	col += dx
	row = clampi(row + dy, 0, ROWS - 1)
	if col < 0:
		if _spread > 0:
			_flip(-1)
			col = COLS * 2 - 1
		else:
			col = 0
	elif col > COLS * 2 - 1:
		if _spread < _spreads() - 1:
			_flip(1)
			col = 0
		else:
			col = COLS * 2 - 1
	var to := (col / COLS) * PER_PAGE + row * COLS + col % COLS
	var last := mini(SPREAD, _list.size() - _spread * SPREAD) - 1
	if to > last:
		to = last
	if to < 0:
		return
	if to != _sel:
		Sfx.play("blip", -18.0, 1.3)
	_select(to, false)


func _binder_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_flip(1)
			accept_event()
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_flip(-1)
			accept_event()


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if _search_box.has_focus():
		if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
			_search_box.release_focus()
			get_viewport().set_input_as_handled()
		return
	# (0.59.1) Letters and numbers always go to the search, even when the box isn't focused
	# (after clicking a card, or after Enter). They used to be shortcuts (A/D/W/S moved, Q/E
	# turned pages, F filtered, W opened "where to find it"), so a word typed after the box lost
	# focus jumped around the album, and Backspace closed it.
	if e is InputEventKey and e.pressed and not (e.ctrl_pressed or e.meta_pressed or e.alt_pressed):
		var ch := String.chr(e.unicode) if e.unicode >= 32 else ""
		if ch != "" or (e.keycode == KEY_BACKSPACE and _search_box.text != ""):
			_search_box.grab_focus()
			if ch != "":
				_search_box.insert_text_at_caret(ch)
			else:
				_search_box.text = _search_box.text.substr(0, _search_box.text.length() - 1)
				_search_box.caret_column = _search_box.text.length()
				_search_box.text_changed.emit(_search_box.text)
			get_viewport().set_input_as_handled()
			return
	var handled := true
	if e is InputEventKey and e.pressed and not e.echo or (e is InputEventKey and e.pressed and e.echo and e.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]):
		match e.keycode:
			KEY_LEFT:
				_move(-1, 0)
			KEY_RIGHT:
				_move(1, 0)
			KEY_UP:
				_move(0, -1)
			KEY_DOWN:
				_move(0, 1)
			KEY_PAGEUP:
				_flip(-1)
			KEY_PAGEDOWN:
				_flip(1)
			KEY_TAB:
				_pick_set((_set + (-1 if e.shift_pressed else 1) + _sets.size()) % _sets.size())
			KEY_ENTER, KEY_KP_ENTER:
				_open_where()
			KEY_ESCAPE:
				_close()
			_:
				handled = false
	elif e is InputEventJoypadButton and e.pressed:
		match Pad.b(e):
			JOY_BUTTON_DPAD_LEFT:
				_move(-1, 0)
			JOY_BUTTON_DPAD_RIGHT:
				_move(1, 0)
			JOY_BUTTON_DPAD_UP:
				_move(0, -1)
			JOY_BUTTON_DPAD_DOWN:
				_move(0, 1)
			JOY_BUTTON_LEFT_SHOULDER:
				_flip(-1)
			JOY_BUTTON_RIGHT_SHOULDER:
				_flip(1)
			JOY_BUTTON_Y:
				_pick_set((_set + 1) % _sets.size())
			JOY_BUTTON_X:
				_cycle_filter()
			JOY_BUTTON_A:
				_open_where()
			JOY_BUTTON_B:
				_close()
			_:
				handled = false
	elif e is InputEventJoypadMotion:
		handled = false
		if absf(e.axis_value) > 0.6 and e.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			var now := Time.get_ticks_msec()
			if now - _stick_at > 180:
				_stick_at = now
				if e.axis == JOY_AXIS_LEFT_X:
					_move(1 if e.axis_value > 0 else -1, 0)
				else:
					_move(0, 1 if e.axis_value > 0 else -1)
			handled = true
		elif absf(e.axis_value) > 0.6 and e.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
			var now2 := Time.get_ticks_msec()
			if now2 - _stick_at > 300:
				_stick_at = now2
				_pick_set((_set + (1 if e.axis == JOY_AXIS_TRIGGER_RIGHT else -1) + _sets.size()) % _sets.size())
			handled = true
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


var _stick_at := 0


func _cycle_filter() -> void:
	var order := ["all", "owned", "missing"]
	_set_filter(order[(order.find(_filter) + 1) % order.size()])


func _relabel_hint() -> void:
	if not is_instance_valid(_hint):
		return
	if Pad.connected:
		_hint.text = Loc.t("%s move     %s / %s turn the page     %s / %s change set     %s show: all, owned, missing     %s where to find it     %s close") % [
			Pad.g("D-pad ↑").replace(" ↑", ""), Pad.g("LB"), Pad.g("RB"), Pad.g("LT"), Pad.g("RT"), Pad.g("X"), Pad.g("A"), Pad.g("B")]
	else:
		_hint.text = Loc.t("Arrows  move     Page Up / Page Down or the mouse wheel  turn the page     Tab  next set     Type  search     Enter  where to find it     Esc  close")


func _process(_d: float) -> void:
	# Pictures load a few at a time, so turning a page never stalls.
	var budget := 3
	for s in _slots:
		if budget <= 0:
			break
		if (s as AlbumSlot).wants_face():
			(s as AlbumSlot).load_face()
			budget -= 1


func _mark_shown() -> void:
	# The NEW tags on the pages you looked at go away next time.
	var shown: Dictionary = Collection.record.get("album_seen", {})
	for s in _slots:
		if (s as AlbumSlot).id != 0 and (s as AlbumSlot).state == "owned":
			shown[str((s as AlbumSlot).id)] = true
	Collection.record["album_seen"] = shown


func _close() -> void:
	_mark_shown()
	# The first visit: everything you own counts as seen from now on.
	var shown: Dictionary = Collection.record.get("album_seen", {})
	if shown.size() < 2:
		for id in Collection.owned:
			if int(Collection.owned[id]) > 0:
				shown[str(id)] = true
		Collection.record["album_seen"] = shown
	Collection.save()
	Sfx.play("click", -6.0, 0.8)
	set_process_input(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func():
		closed.emit()
		queue_free())


# ------------------------------------------------------------------ small drawn parts

## A set in the list on the left: its color, name, how much you own.
class _SetButton extends Button:
	var title := ""
	var col := Color.WHITE
	var have := 0
	var total := 1
	var active := false:
		set(v):
			active = v
			queue_redraw()
	var _h := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(300, 62)
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _process(delta: float) -> void:
		var g := 1.0 if is_hovered() else 0.0
		if not is_equal_approx(_h, g):
			_h = move_toward(_h, g, delta * 9.0)
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col.darkened(0.78), 0.92) if active else Color(0.04, 0.065, 0.13, 0.7 + 0.2 * _h)
		sb.set_corner_radius_all(12)
		sb.border_color = Color(col, 0.9) if active else Color(1, 1, 1, 0.08 + 0.15 * _h)
		sb.set_border_width_all(2 if active else 1)
		draw_style_box(sb, r)
		draw_rect(Rect2(Vector2(0, 10), Vector2(5, size.y - 20)), col)
		var f := UITheme.title_font()
		# (A long name gets a smaller size rather than losing its end: "La Biblioteca de la Profecía".)
		var tsz := 21
		while tsz > 13 and f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, tsz).x > size.x - 92:
			tsz -= 1
		draw_string(f, Vector2(18, 28), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 92, tsz, Color.WHITE if active else Color(0.9, 0.93, 1.0, 0.92))
		var pct := float(have) / maxf(1.0, total)
		var t := "%d%%" % int(floor(pct * 100.0))
		var fs := UITheme.semi_font()
		var tw := fs.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		draw_string(fs, Vector2(size.x - 14 - tw, 28), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UITheme.GOLD if pct >= 1.0 else col.lightened(0.35))
		var bar := Rect2(Vector2(18, 42), Vector2(size.x - 36, 6))
		draw_rect(bar, Color(1, 1, 1, 0.08))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * pct, bar.size.y)), UITheme.GOLD if pct >= 1.0 else col)
		var c := "%d / %d" % [have, total]
		draw_string(fs, Vector2(size.x - 14 - fs.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, 58), c, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.45))


## A thin progress bar.
class _Bar extends Control:
	var value := 0.0
	var col := Color.WHITE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(1, 1, 1, 0.07))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.0, 1.0), size.y)), UITheme.GOLD if value >= 1.0 else col)


## The "next page" button: the back arrow, turned around.
class _NextButton extends RoundButton:
	func _init() -> void:
		super._init("next", Comic.BLUE, 48.0)


## The open binder: two leather pages, the rings in the middle, light on the edges.
class _Binder extends Control:
	const SPINE := 46.0
	var tint := Color("7fe8ff")
	var empty_text := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var page_w := (size.x - SPINE) / 2.0
		for p in 2:
			var r := Rect2(Vector2(p * (page_w + SPINE), 0), Vector2(page_w, size.y))
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.055, 0.075, 0.13, 0.97)
			sb.corner_radius_top_left = 16 if p == 0 else 4
			sb.corner_radius_bottom_left = 16 if p == 0 else 4
			sb.corner_radius_top_right = 4 if p == 0 else 16
			sb.corner_radius_bottom_right = 4 if p == 0 else 16
			sb.border_color = Color(tint, 0.35)
			sb.set_border_width_all(2)
			sb.shadow_color = Color(0, 0, 0, 0.45)
			sb.shadow_size = 14
			draw_style_box(sb, r)
			# Stitching just inside the edge.
			var inset := r.grow(-10)
			_dashes(inset.position, Vector2(inset.end.x, inset.position.y))
			_dashes(Vector2(inset.position.x, inset.end.y), inset.end)
			# A soft fall of light toward the spine.
			for k in 12:
				var a := 0.035 * pow(float(k + 1) / 12.0, 2.0) * 3.0
				var x := (r.end.x - 60.0 + k * 5.0) if p == 0 else (r.position.x + 55.0 - k * 5.0)
				draw_rect(Rect2(Vector2(x, 4), Vector2(5, size.y - 8)), Color(0, 0, 0, clampf(a, 0.0, 0.3)))
		# The spine and its rings.
		var spine := Rect2(Vector2(page_w, 6), Vector2(SPINE, size.y - 12))
		draw_rect(spine, Color(0.025, 0.035, 0.065))
		for k in 4:
			var y := size.y * (0.16 + 0.68 * k / 3.0)
			var c := Vector2(size.x / 2.0, y)
			# A binder ring seen from above: a metal bar across the spine, through a punched
			# hole in each page.
			var half := SPINE / 2.0 + 16.0
			for sx in [-1.0, 1.0]:
				draw_circle(c + Vector2(sx * (half - 2.0), 0), 9.0, Color(0.0, 0.0, 0.0, 0.55))
			draw_rect(Rect2(c + Vector2(-half, -1.0), Vector2(half * 2.0, 9.0)), Color(0, 0, 0, 0.35))   # its shadow
			var metal := Color(0.62, 0.67, 0.76)
			draw_rect(Rect2(c + Vector2(-half, -6.0), Vector2(half * 2.0, 12.0)), metal)
			draw_circle(c + Vector2(-half, 0), 6.0, metal)
			draw_circle(c + Vector2(half, 0), 6.0, metal)
			draw_rect(Rect2(c + Vector2(-half, -6.0), Vector2(half * 2.0, 4.0)), Color(0.88, 0.91, 0.97))
			draw_rect(Rect2(c + Vector2(-half, 3.0), Vector2(half * 2.0, 3.0)), Color(0.38, 0.42, 0.5))
			draw_line(c + Vector2(-half * 0.6, -4.5), c + Vector2(half * 0.2, -4.5), Color(1, 1, 1, 0.9), 1.5)
		if empty_text != "":
			var f := UITheme.semi_font()
			var w := f.get_string_size(empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			draw_string(f, Vector2(size.x / 4.0 - w / 2.0, size.y / 2.0), empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UITheme.TEXT_DIM)

	func _dashes(a: Vector2, b: Vector2) -> void:
		var n := int(a.distance_to(b) / 14.0)
		for i in n:
			var p := a.lerp(b, float(i) / n)
			draw_line(p, p + (b - a).normalized() * 7.0, Color(tint, 0.18), 1.5)


## The big view for a card you have not found: a card shape, its number, a question mark.
class _Mystery extends Control:
	var tint := Color.WHITE
	var number := 0

	func _draw() -> void:
		var h := size.y
		var w := h * 0.686
		var r := Rect2(Vector2((size.x - w) / 2.0, 0), Vector2(w, h))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(tint.darkened(0.85), 0.95)
		sb.set_corner_radius_all(14)
		sb.border_color = Color(tint, 0.45)
		sb.set_border_width_all(3)
		draw_style_box(sb, r)
		draw_rect(r.grow(-18), Color(tint, 0.08), false, 1.5)
		var f := UITheme.title_font()
		var q := "?"
		var qs := f.get_string_size(q, HORIZONTAL_ALIGNMENT_LEFT, -1, 150)
		draw_string(f, r.get_center() + Vector2(-qs.x / 2.0, 50), q, HORIZONTAL_ALIGNMENT_LEFT, -1, 150, Color(tint, 0.4))
		var t := "#%03d" % number
		var fs := UITheme.semi_font()
		var ts := fs.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		draw_string(fs, Vector2(r.get_center().x - ts.x / 2.0, r.end.y - 26), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.4))


## The card's name, and the Spanish one under it when that is the name the search found it by.
func _shown_name(id: int, d: Dictionary) -> String:
	var en := str(d.get("name", ""))
	var alt := CardSearch.other_name(id, en, _search)
	return en + ("\n(" + alt + ")" if alt != "" else "")
