class_name CardListView
extends Control
## "See the cards" (0.55.3): every card a pack can give you, or every card in a ready-made deck,
## laid out like a page of the album. Cards you own in full color with their foil, the ones you
## are missing in grey with a MISSING tag. On the left: the pack or deck itself, how many you
## have, and a count for each rarity (click one to see only those). On the right: the card you
## are on, big, with its text. It only shows: buying is still the shop's job.

signal closed

const HAVE_FILTERS := ["all", "have", "missing"]
const RAR_ORDER := [3, 2, 1, 0]

var _kind := "pack"            # pack | deck
var _info := {}
var _ids: Array = []           # every different card in it, in the order shown
var _in_deck := {}             # deck: id -> copies in it
var _slots: Array = []         # AlbumSlot per id, same order as _ids
var _shown: Array = []         # the slots the filters let through
var _sel := -1
var _have_f := 0
var _rar_f := -1               # -1: every rarity
var _closing := false
var _cols := 6
var _panel: PanelContainer
var _grid: GridContainer
var _scroll: ScrollContainer
var _have_btns: Array = []
var _rar_btns := {}
var _count: Label
var _empty: Label
# The card you are on.
var _d_face: TextureRect
var _d_name: Label
var _d_type: Label
var _d_stats: Label
var _d_text: RichTextLabel
var _d_owned: Label
var _d_id := 0
var _rar := {}                 # id -> rarity (worked out once)


## kind "pack": info is the shop's pack. kind "deck": info is the deck catalog entry.
func _init(kind: String, info: Dictionary) -> void:
	_kind = kind
	_info = info


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 150
	theme = UITheme.build()
	_gather()
	var col := _color()
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.03, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_close())
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 60
	_panel.offset_right = -60
	_panel.offset_top = 40
	_panel.offset_bottom = -40
	var box := UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.98), 22, Color(col, 0.6))
	box.border_width_top = 3
	box.content_margin_left = 26
	box.content_margin_right = 26
	box.content_margin_top = 22
	box.content_margin_bottom = 18
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	_panel.add_child(outer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(row)
	var _lc := _left_column(col)
	row.add_child(_lc)
	row.add_child(_grid_column(col))
	row.add_child(_detail_column(col))
	var hints := UITheme.label(Loc.t("Arrows  move     F / Y  have or missing     R / X  rarity     LB / RB  page     Esc / B  close"), 16, UITheme.TEXT_DIM)
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(hints)
	_apply_filters()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	_panel.pivot_offset = get_viewport_rect().size / 2.0 - Vector2(60, 40)
	_panel.scale = Vector2(0.97, 0.97)
	create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("whoosh", -12.0, 1.3)
	if OS.has_environment("LIST_FILTER"):	# dev: look at a filter
		var f := OS.get_environment("LIST_FILTER")
		if f.is_valid_int():
			_set_rar(int(f))
		else:
			_set_have(HAVE_FILTERS.find(f))
	if OS.has_environment("LIST_SEL"):
		_select(int(OS.get_environment("LIST_SEL")))


## Every different card in it, best first.
func _gather() -> void:
	var seen := {}
	if _kind == "deck":
		var key := str(_info["key"])
		for id in CardData.deck_list(key) + CardData.extra_list(key):
			_in_deck[int(id)] = int(_in_deck.get(int(id), 0)) + 1
			seen[int(id)] = true
	else:
		for id in Collection.pool(str(_info["key"])):
			seen[int(id)] = true
	_ids = seen.keys()
	# (Each card's sort key worked out once: sorting 270 cards looked each one up again and again.)
	var kind_rank := {"monster": 0, "spell": 1, "trap": 2}
	var keys := {}
	for id in _ids:
		var d := CardData.get_card(id)
		var r := CardData.rarity(id)
		_rar[id] = r
		var k := int(kind_rank.get(str(d.get("kind", "")), 3))
		keys[id] = [-r if _kind == "pack" else 0, k, -int(d.get("level", 0)) if (_kind == "deck" and k == 0) else 0, str(d.get("name", ""))]
	_ids.sort_custom(func(a, b):
		var ka: Array = keys[a]
		var kb: Array = keys[b]
		for i in 3:
			if ka[i] != kb[i]:
				return ka[i] < kb[i]
		return ka[3] < kb[3])


func _color() -> Color:
	var c = _info.get("color", UITheme.ACCENT)
	return c if c is Color else Color(str(c))


func _title() -> String:
	return Collection.pack_title(_info) if _kind == "pack" else Loc.t(str(_info.get("name", "")))


# ---------------------------------------------------------------- left: the pack or deck

func _left_column(col: Color) -> Control:
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size = Vector2(290, 0)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(290, 300)
	left.add_child(holder)
	if _kind == "pack":
		var w := PackWrapper.new().setup(_info, true)
		w.custom_minimum_size = Vector2(230, 353)
		w.size = Vector2(230, 353)
		w.scale = Vector2(0.81, 0.81)
		w.position = Vector2(52, 6)
		holder.add_child(w)
	else:
		var b := DeckBox.new().setup(_info)
		b.size = Vector2(206, 290)
		b.position = Vector2(42, 6)
		b.owned = Collection.owns_deck(str(_info["key"]))
		holder.add_child(b)
	var t := UITheme.label(_title(), 30, col.lightened(0.45), UITheme.title_font())
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(t)
	var sub := ""
	if _kind == "pack":
		sub = Loc.t("Pack  ·  %d possible cards") % _ids.size()
	else:
		var owner := str(_info.get("owner", ""))
		sub = (Loc.t("%s's deck") % Loc.t(owner) if owner != "" else Loc.t("Theme deck")) \
				+ "  ·  " + Loc.t("%d different cards") % _ids.size()
	left.add_child(UITheme.label(sub, 16, UITheme.TEXT_DIM, UITheme.semi_font()))
	var have := 0
	for id in _ids:
		if Collection.count(id) > 0:
			have += 1
	var hv := HBoxContainer.new()
	hv.add_theme_constant_override("separation", 8)
	left.add_child(hv)
	hv.add_child(UITheme.label(Loc.t("You have"), 18, UITheme.TEXT, UITheme.semi_font()))
	var big := UITheme.label("%d / %d" % [have, _ids.size()], 30, UITheme.GOLD, UITheme.title_font())
	hv.add_child(big)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(290, 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	bg.set_corner_radius_all(6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = UITheme.GOLD
	fg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	bar.max_value = maxi(1, _ids.size())
	bar.value = 0
	left.add_child(bar)
	bar.create_tween().tween_property(bar, "value", float(have), 0.6).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if have == _ids.size() and have > 0:
		left.add_child(UITheme.label(Loc.t("★ Complete!"), 20, UITheme.GOLD, UITheme.title_font()))
	# Have / missing.
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	left.add_child(sp)
	left.add_child(UITheme.label(Loc.t("SHOW"), 14, col.lightened(0.5), UITheme.semi_font()))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	left.add_child(hb)
	for i in HAVE_FILTERS.size():
		var b := _chip(Loc.t(["All", "Have", "Missing"][i]), col)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _set_have(i))
		hb.add_child(b)
		_have_btns.append(b)
	# One line per rarity: how many you have of how many.
	left.add_child(UITheme.label(Loc.t("BY RARITY"), 14, col.lightened(0.5), UITheme.semi_font()))
	for r in RAR_ORDER:
		var n := 0
		var h := 0
		for id in _ids:
			if int(_rar.get(id, 0)) == r:
				n += 1
				if Collection.count(id) > 0:
					h += 1
		if n == 0:
			continue
		var b := _chip("", Foil.COLORS[r])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "  ●  %s" % Loc.t(Foil.NAMES[r])
		b.add_theme_color_override("font_color", Foil.COLORS[r])
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		var cnt := UITheme.label("%d / %d" % [h, n], 17, UITheme.GOLD if h == n else UITheme.TEXT, UITheme.semi_font())
		cnt.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		cnt.offset_left = -90
		cnt.offset_right = -12
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cnt)
		b.pressed.connect(func(): _set_rar(r))
		left.add_child(b)
		_rar_btns[r] = b
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(fill)
	var note := UITheme.label(Loc.t("Cards you don't have yet are shown in grey."), 15, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(290, 0)
	left.add_child(note)
	var close := Button.new()
	close.text = Loc.t("Close")
	close.custom_minimum_size = Vector2(0, 52)
	close.add_theme_font_size_override("font_size", 22)
	close.pressed.connect(_close)
	left.add_child(close)
	return left


func _chip(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_stylebox_override("normal", UITheme.button_box(Color(0.06, 0.09, 0.17, 0.9), Color(col, 0.25), 12))
	b.add_theme_stylebox_override("hover", UITheme.button_box(Color(col.darkened(0.55), 0.6), Color(col, 0.7), 12))
	b.add_theme_stylebox_override("pressed", UITheme.button_box(Color(col.darkened(0.35), 0.75), col.lightened(0.3), 12))
	b.add_theme_stylebox_override("hover_pressed", UITheme.button_box(Color(col.darkened(0.3), 0.8), Color.WHITE, 12))
	for k in ["font_pressed_color", "font_hover_pressed_color", "font_hover_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	return b


# ---------------------------------------------------------------- middle: the cards

func _grid_column(col: Color) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UITheme.label(Loc.t("EVERY CARD IN THIS PACK") if _kind == "pack" else Loc.t("EVERY CARD IN THIS DECK"), 26, Color.WHITE, UITheme.title_font())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_count = UITheme.label("", 17, UITheme.TEXT_DIM, UITheme.semi_font())
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_count)
	var line := ColorRect.new()
	line.color = Color(col, 0.45)
	line.custom_minimum_size = Vector2(0, 2)
	v.add_child(line)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["top", "bottom", "left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 8)
	_scroll.add_child(pad)
	# As many columns as fit between the two side columns.
	var avail := get_viewport_rect().size.x - 120 - 52 - 290 - 400 - 52 - 16 - 24
	_cols = clampi(int(avail / (AlbumSlot.CARD.x + 14 + 8)), 3, 10)
	var cen := CenterContainer.new()
	cen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(cen)
	_grid = GridContainer.new()
	_grid.columns = _cols
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	cen.add_child(_grid)
	# (The first screenfuls now, the rest a few rows a frame: a pack of 270 cards used to build
	# every slot in one frame.)
	_slot_col = col
	_add_slots(_cols * 6)
	_empty = UITheme.label(Loc.t("Nothing here with these filters."), 22, UITheme.TEXT_DIM)
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.visible = false
	v.add_child(_empty)
	return v


# ---------------------------------------------------------------- right: the card you are on

func _detail_column(col: Color) -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(400, 0)
	var sb := UITheme.panel_box(Color(0.05, 0.08, 0.16, 0.85), 18, Color(col, 0.3))
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	_d_face = TextureRect.new()
	_d_face.custom_minimum_size = Vector2(250, 364)
	_d_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_d_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_d_face.pivot_offset = Vector2(180, 182)
	v.add_child(_d_face)
	_d_name = UITheme.label("", 26, Color.WHITE, UITheme.title_font())
	_d_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_d_name)
	_d_type = UITheme.label("", 15, UITheme.GOLD, UITheme.semi_font())
	_d_type.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_d_type)
	_d_stats = UITheme.label("", 17, UITheme.TEXT, UITheme.semi_font())
	v.add_child(_d_stats)
	_d_text = RichTextLabel.new()
	_d_text.fit_content = false
	_d_text.scroll_active = true
	_d_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_d_text.add_theme_font_size_override("normal_font_size", 16)
	_d_text.add_theme_color_override("default_color", UITheme.TEXT)
	v.add_child(_d_text)
	_d_owned = UITheme.label("", 17, UITheme.GOLD, UITheme.semi_font())
	_d_owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_d_owned)
	return pc


static func _when_big(me: WeakRef, want: int) -> Callable:
	return func(t: Texture2D):
		var v = me.get_ref()
		if v != null and v._d_id == want and t != null:
			v._d_face.texture = t


func _show_card(id: int) -> void:
	var d := CardData.get_card(id)
	var n := Collection.count(id)
	# (The sharp picture is read on another thread; the small one, if it is already in memory,
	# stands in for the few frames that takes.)
	var small = Cards._kept(Cards._thumb_cache, id)
	_d_face.texture = small
	_d_id = id
	Cards.face_later(id, _when_big(weakref(self), id))
	if n > 0:
		Foil.apply(_d_face, CardData.rarity(id))
	else:
		_d_face.material = AlbumSlot.gray_material()
	_d_face.scale = Vector2(0.95, 0.95)
	_d_face.create_tween().tween_property(_d_face, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_d_name.text = str(d.get("name", ""))
	var bits: Array = []
	var kind := str(d.get("kind", ""))
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
	_d_stats.visible = _d_stats.text != ""
	var rar := CardData.rarity(id)
	_d_type.text = "  ·  ".join(bits)
	_d_type.add_theme_color_override("font_color", Foil.COLORS[rar] if rar > 0 else UITheme.GOLD)
	if rar > 0:
		_d_type.text += "  ·  " + Loc.t(Foil.NAMES[rar])
	var txt := str(d.get("desc", d.get("text", "")))
	if txt == "":
		txt = str(CardData.EXT.get(id, {}).get("desc", ""))
	_d_text.text = CardText.shown(str(d.get("name", "")), txt)
	_d_text.scroll_to_line(0)
	var line := ""
	if n > 0:
		line = (Loc.t("You own %d copies") % n) if n != 1 else Loc.t("You own 1 copy")
		_d_owned.add_theme_color_override("font_color", UITheme.GOLD)
	else:
		line = Loc.t("You don't have it yet.")
		_d_owned.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))
	if _kind == "deck":
		line += "   ·   " + Loc.t("In this deck: x%d") % int(_in_deck.get(id, 1))
	_d_owned.text = line


# ---------------------------------------------------------------- filters and moving

func _set_have(i: int) -> void:
	_have_f = clampi(i, 0, HAVE_FILTERS.size() - 1)
	Sfx.play("click", -8.0)
	_apply_filters()


func _set_rar(r: int) -> void:
	_rar_f = -1 if _rar_f == r or not _rar_btns.has(r) else r
	Sfx.play("click", -8.0)
	_apply_filters()


var _slot_col := Color.WHITE


## Make the next `n` slots (in order) and put them in the grid.
func _add_slots(n: int) -> int:
	var made := 0
	while made < n and _slots.size() < _ids.size():
		var i := _slots.size()
		var id: int = _ids[i]
		var s := AlbumSlot.new()
		var c := Collection.count(id)
		s.setup(id, i + 1, "owned" if c > 0 else "missing", c, _slot_col)
		s.picked.connect(func(sl): _select(_shown.find(sl)))
		_grid.add_child(s)
		_slots.append(s)
		made += 1
	return made


func _passes(sl: AlbumSlot) -> bool:
	var ok := true
	match HAVE_FILTERS[_have_f]:
		"have": ok = sl.state == "owned"
		"missing": ok = sl.state != "owned"
	if ok and _rar_f >= 0:
		ok = int(_rar.get(sl.id, 0)) == _rar_f
	return ok


func _count_text() -> void:
	# (Counted over every card, built or not yet.)
	var n := 0
	for id in _ids:
		var ok := true
		var own := Collection.count(id) > 0
		match HAVE_FILTERS[_have_f]:
			"have": ok = own
			"missing": ok = not own
		if ok and _rar_f >= 0:
			ok = int(_rar.get(id, 0)) == _rar_f
		if ok:
			n += 1
	_count.text = Loc.t("%d cards") % n if n != 1 else Loc.t("1 card")


func _apply_filters() -> void:
	var keep_id: int = (_shown[_sel] as AlbumSlot).id if _sel >= 0 and _sel < _shown.size() else 0
	_shown.clear()
	for s in _slots:
		var sl := s as AlbumSlot
		var ok := _passes(sl)
		sl.visible = ok
		sl.selected = false
		if ok:
			_shown.append(sl)
	for i in _have_btns.size():
		(_have_btns[i] as Button).button_pressed = i == _have_f
	for r in _rar_btns:
		(_rar_btns[r] as Button).button_pressed = r == _rar_f
	_count_text()
	_empty.visible = _shown.is_empty() and _slots.size() >= _ids.size()
	_scroll.visible = not _shown.is_empty()
	_sel = -1
	var to := 0
	for i in _shown.size():
		if (_shown[i] as AlbumSlot).id == keep_id:
			to = i
	_scroll.scroll_vertical = 0
	if not _shown.is_empty():
		_select(to, true)


func _select(i: int, quiet := false) -> void:
	if _shown.is_empty():
		return
	i = clampi(i, 0, _shown.size() - 1)
	if i == _sel:
		return
	if _sel >= 0 and _sel < _shown.size():
		(_shown[_sel] as AlbumSlot).selected = false
	_sel = i
	var s: AlbumSlot = _shown[i]
	s.selected = true
	if not quiet:
		Sfx.play("blip", -16.0, 1.4)
	_show_card(s.id)
	_scroll.ensure_control_visible.call_deferred(s)


func _process(_delta: float) -> void:
	# The rest of the slots, a few rows a frame.
	if _slots.size() < _ids.size():
		var from := _slots.size()
		_add_slots(_cols * 3)
		var any := false
		for k in range(from, _slots.size()):
			var sl: AlbumSlot = _slots[k]
			sl.visible = _passes(sl)
			if sl.visible:
				_shown.append(sl)
				any = true
		if any:
			_scroll.visible = true
			_empty.visible = false
			if _sel < 0:
				_select(0, true)
		if _slots.size() >= _ids.size():
			_empty.visible = _shown.is_empty()
			_scroll.visible = not _shown.is_empty()
	# Pictures load a few a frame, starting from what is on screen.
	if _shown.is_empty():
		return
	var row_h := AlbumSlot.CARD.y + 14 + 8
	var first := clampi(int(_scroll.scroll_vertical / row_h) * _cols, 0, _shown.size() - 1)
	var done := 0
	for k in _shown.size():
		var s: AlbumSlot = _shown[(first + k) % _shown.size()]
		if s.wants_face():
			s.load_face_later()
			done += 1
			if done >= 8:
				break


func _close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	# (It sits above a shop that reads keys and pads in _input too: the window takes them first.)
	if _closing:
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		_close()
	elif event.is_action_pressed("ui_left"):
		_select(_sel - 1)
	elif event.is_action_pressed("ui_right"):
		_select(_sel + 1)
	elif event.is_action_pressed("ui_up"):
		if _sel - _cols >= 0:
			_select(_sel - _cols)
	elif event.is_action_pressed("ui_down"):
		if _sel + _cols < _shown.size():
			_select(_sel + _cols)
		elif _sel / _cols < (_shown.size() - 1) / _cols:
			_select(_shown.size() - 1)
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_Y):
		_set_have((_have_f + 1) % HAVE_FILTERS.size())
	elif (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_X):
		# Every rarity, then each one there is, from the rarest down.
		var have: Array = RAR_ORDER.filter(func(r): return _rar_btns.has(r))
		var at := have.find(_rar_f)
		_rar_f = -1
		_set_rar(have[at + 1] if at + 1 < have.size() else -1)
	elif (event is InputEventKey and event.pressed and event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN, KEY_Q, KEY_E]) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		var back: bool = (event is InputEventKey and event.keycode in [KEY_PAGEUP, KEY_Q]) or (event is InputEventJoypadButton and Pad.b(event) == JOY_BUTTON_LEFT_SHOULDER)
		var page := _cols * maxi(1, int(_scroll.size.y / (AlbumSlot.CARD.y + 22)))
		_select(_sel + (-page if back else page))
