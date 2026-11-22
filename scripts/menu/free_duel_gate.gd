class_name FreeDuelGate
extends Control
## Free Duel (0.69.1), in the look of the Academy's and the main story's doors: the rival's world
## behind them (a picture taken in the game), the rival large on the right, their deck in its three
## versions as three cards to pick, your record and medals against them, and down the left every
## duelist by era. Everything the older setup screen did is one press away: "More options" opens
## it (who you play as, their deck as one of yours, Turbo, Best of 3, Destiny Draw, Life Points,
## who goes first, Gauntlet and Survival, the hand, the arena), with what you picked here.

signal start(config: Dictionary)
signal closed
signal knockout

const W := 1920.0
## Era names short enough for the tabs over the list (the full name is in the tooltip).
const ERA_SHORT := {"Duel Monsters": "DM"}
const H := 1080.0
const VERSIONS := ["starter", "standard", "full"]
## What the player sees for the three versions of a rival's deck (the keys stay starter / standard / full).
const VERSION_NAME := {"starter": "Basic", "standard": "Strong", "full": "Competitive"}
const VERSION_HOW := {
	"starter": "A simple version: fewer key cards, good to start.",
	"standard": "More of their key cards and combos.",
	"full": "Their full deck, at full power.",
}
## The world behind each era (5D's: the two from the Satellite stand over it).
const ERA_PICTURE := {
	"Duel Monsters": "res://assets/ui/story_title_domino.jpg",
	"GX": "res://assets/ui/academy_title.jpg",
	"5D's": "res://assets/ui/story_title_newdomino.jpg",
	"ZEXAL": "res://assets/ui/story_title_heartland.jpg",
}
const SATELLITE := ["crow", "kalin"]

var _me := "player"
var _opp := "kaiba"
var _version := "full"
var _my_deck := "echo"
var _field := "auto"
var _difficulty := 1
var _starting := false
var _t := 0.0

var _root: Control
var _back: AcademyBackdrop
var _rival_pic: TextureRect
var _rival_box: Control
var _rival_fade: TextureRect
var _list_box: VBoxContainer
var _list_scroll: ScrollContainer
var _rows := {}                     # key -> Button in the list
var _pending: Array = []            # [TextureRect, key]: list portraits still to load
var _info: VBoxContainer
var _cards_row: HBoxContainer
var _version_line: Label
var _deck_pick: OptionButton
var _deck_keys: Array = []
var _me_pick: OptionButton
var _me_keys: Array = []
var _diff_tabs: Array = []
var _reward: Label
var _go: Button
var _era_tabs := {}                 # era ("" = all) -> its tab Button
var _era_groups := {}               # era -> the VBox of its heading and rows in the list
## The era picked in the list's tabs, kept for the rest of the session ("" = every era).
static var era_pick := ""
var _version_cache := {}            # deck key -> [ace id, monsters, spells/traps, extra]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	var cfg: Dictionary = Router.duel_config
	_me = str(cfg.get("player_char", "player"))
	if _me != "player" and not (Characters.available(_me) and Unlocks.opponent(_me)):
		_me = "player"
	_opp = str(cfg.get("opponent", "kaiba"))
	if not _usable(_opp):
		_opp = ""
		for k in Characters.ORDER:
			if _usable(str(k)) and str(k) != _me:
				_opp = str(k)
				break
		if _opp == "":
			_opp = "joey"
	_version = _version_of(str(cfg.get("opponent_deck", "")))
	_difficulty = clampi(Settings.free_difficulty, 1, 3)
	_my_deck = str(cfg.get("player_deck", ""))
	_field = str(cfg.get("field", Settings.field_theme))
	if _field != "auto" and not FieldThemes.THEMES.has(_field):
		_field = "auto"
	_back = AcademyBackdrop.new(0.18, _picture_of(_opp), Color(0.85, 0.92, 1.0))
	add_child(_back)
	# The rival, large, standing on the right over their world.
	_rival_box = Control.new()
	_rival_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rival_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rival_box.clip_contents = true
	add_child(_rival_box)
	_rival_pic = TextureRect.new()
	_rival_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rival_pic.stretch_mode = TextureRect.STRETCH_SCALE
	_rival_pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_rival_pic.flip_h = true
	_rival_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rival_box.add_child(_rival_pic)
	# A dark foot under the rival, so the bottom of the picture melts into the screen.
	var fg := Gradient.new()
	fg.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	fg.colors = PackedColorArray([Color(0.02, 0.03, 0.09, 0.0), Color(0.02, 0.03, 0.09, 0.0), Color(0.02, 0.03, 0.09, 0.9)])
	var ft := GradientTexture2D.new()
	ft.gradient = fg
	ft.fill_from = Vector2(0, 0)
	ft.fill_to = Vector2(0, 1)
	ft.width = 4
	ft.height = 256
	_rival_fade = TextureRect.new()
	_rival_fade.texture = ft
	_rival_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rival_fade.stretch_mode = TextureRect.STRETCH_SCALE
	_rival_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rival_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rival_box.add_child(_rival_fade)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	resized.connect(_center)
	_center()
	_build_left()
	_build_info()
	_refresh_all()
	_scroll_to(_opp)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	_go.grab_focus.call_deferred()


func _center() -> void:
	if _root:
		_root.position = ((size - Vector2(W, H)) / 2.0).max(Vector2.ZERO)
	_place_rival()


## Somebody you can face: they have a deck (the card database) and you have met them.
static func _usable(key: String) -> bool:
	return Characters.DATA.has(key) and Characters.available(key) and Unlocks.opponent(key)


static func _picture_of(key: String) -> String:
	if key in SATELLITE:
		return "res://assets/ui/story_title_satellite.jpg"
	var era := str(Characters.get_char(key).get("era", "Duel Monsters"))
	return str(ERA_PICTURE.get(era, ERA_PICTURE["Duel Monsters"]))


static func era_color(key: String) -> Color:
	return StoryEmblem.era_color(str(Characters.get_char(key).get("era", "")))


func _base_deck(key := "") -> String:
	return str(Characters.get_char(_opp if key == "" else key).get("deck", ""))


## "kaiba@starter" -> "starter"; their plain deck (or anything else) -> "full".
func _version_of(deck_key: String) -> String:
	if deck_key.begins_with("@") and deck_key.substr(1) in VERSIONS:
		return deck_key.substr(1)     # (the full setup screen's "their deck: Standard")
	if deck_key.contains("@"):
		var sp: Array = DeckTiers.split(deck_key)
		if str(sp[0]) == _base_deck() and str(sp[1]) in VERSIONS:
			return str(sp[1])
	return "full"


func _version_key(v: String, key := "") -> String:
	var base := _base_deck(key)
	return base if v == "full" else DeckTiers.with_version(base, v)


static func _stars(key: String) -> int:
	if Unlocks.SERIES_STARS.has(key):
		return int(Unlocks.SERIES_STARS[key])
	return clampi(int(Characters.get_char(key).get("stars", 3)), 1, 5)


# ------------------------------------------------------------------ the left: every duelist by era

func _build_left() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(56, 40)
	col.size = Vector2(430, 1000)
	col.add_theme_constant_override("separation", 10)
	_root.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	col.add_child(top)
	var back := _glass(Loc.t("◀  Back"), UITheme.ACCENT, _close)
	back.custom_minimum_size = Vector2(130, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.add_theme_font_size_override("font_size", 19)
	top.add_child(back)
	var over := UITheme.label(Loc.t("FREE DUEL"), 44, Color.WHITE, UITheme.title_font())
	over.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	over.add_theme_constant_override("shadow_offset_y", 3)
	top.add_child(over)
	var sub := UITheme.label(Loc.t("Pick a rival. Every duelist you have met is here."), 17, UITheme.TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(420, 0)
	col.add_child(sub)
	# Era tabs: All, then each era of the roster, in its color with its count.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	tabs.custom_minimum_size = Vector2(430, 0)
	col.add_child(tabs)
	var all_n := 0
	var era_n := {}
	for k in Characters.ORDER:
		var e := str(Characters.DATA[k].get("era", ""))
		era_n[e] = int(era_n.get(e, 0)) + 1
		all_n += 1
	tabs.add_child(_era_tab("", Loc.t("All"), all_n, UITheme.ACCENT))
	for era in Characters.ERAS:
		if int(era_n.get(era, 0)) > 0:
			tabs.add_child(_era_tab(str(era), str(era), int(era_n[era]), StoryEmblem.era_color(str(era))))
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.custom_minimum_size = Vector2(430, 660)
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_list_scroll)
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 6)
	_list_box.custom_minimum_size = Vector2(414, 0)
	_list_scroll.add_child(_list_box)
	for era in Characters.ERAS:
		var keys: Array = []
		for k in Characters.ORDER:
			if str(Characters.DATA[k].get("era", "")) == era:
				keys.append(str(k))
		if keys.is_empty():
			continue
		var ec := StoryEmblem.era_color(era)
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 6)
		_list_box.add_child(group)
		_era_groups[era] = group
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		group.add_child(head)
		var bar := ColorRect.new()
		bar.color = ec
		bar.custom_minimum_size = Vector2(5, 26)
		head.add_child(bar)
		var met := 0
		for k in keys:
			if _usable(k):
				met += 1
		head.add_child(UITheme.label(era.to_upper(), 21, ec.lightened(0.2), UITheme.title_font()))
		var cnt := UITheme.label("%d / %d" % [met, keys.size()], 16, UITheme.TEXT_DIM, UITheme.semi_font())
		cnt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(cnt)
		for k in keys:
			group.add_child(_list_row(k))
	_show_era(era_pick, false)
	# Today's set duel and the Knockout, under the list (as they sat beside the title before).
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 10)
	col.add_child(modes)
	var day := Knockout.daily()
	if not day.is_empty():
		var done := Knockout.daily_done()
		var opp := str(Characters.get_char(str(day["opponent"])).get("short", ""))
		var tw: Dictionary = day["twist"]
		var text := Loc.t(str(day["text"]))
		if text.contains("%s"):
			text = text % str(Characters.get_char(str(day["lender"])).get("short", ""))
		var b := _mode_card(UITheme.GOLD, Loc.t("DUEL OF THE DAY") + ("  ✓" if done else "  +%d" % Knockout.DAILY_REWARD),
				Loc.t("vs %s") % opp, Loc.t(str(tw["name"])))
		b.tooltip_text = "%s\n%s" % [text, (Loc.t("Already won today: you can play it again, it pays once a day.") if done
				else Loc.t("Win it for %d Duel Points. It pays once a day, and it changes at midnight.") % Knockout.DAILY_REWARD)]
		b.pressed.connect(func():
			if _starting:
				return
			_starting = true
			Router.match_state = {}
			Sfx.play("quest", -6.0)
			start.emit((Knockout.daily()["cfg"] as Dictionary).duplicate(true)))
		modes.add_child(b)
	var held: Dictionary = Collection.record.get("trophies", {})
	var cups := int(held.get("1", 0)) + int(held.get("2", 0)) + int(held.get("3", 0))
	var line := Loc.t("Open the bracket")
	if Knockout.running():
		line = Loc.t("%s next") % Loc.t(Knockout.round_name())
	var k := _mode_card(UITheme.ACCENT, Loc.t("KNOCKOUT") + "  ▶", line, (Loc.t("Cups: %d") % cups) if cups > 0 else Loc.t("8 duelists, 3 rounds"))
	k.tooltip_text = Loc.t("Another mode: eight duelists, three rounds. Lose once and you are out. Opens the bracket screen.")
	k.pressed.connect(func():
		if _starting:
			return
		Sfx.play("click")
		knockout.emit())
	modes.add_child(k)


## One era tab over the list: its name and how many duelists it has, in the era's color.
func _era_tab(era: String, text: String, n: int, ec: Color) -> Button:
	var b := Button.new()
	b.text = "%s %d" % [ERA_SHORT.get(text, text), n]
	b.toggle_mode = true
	b.button_pressed = era == era_pick
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, 38)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = {"": 1.4, "Duel Monsters": 0.85, "GX": 0.85, "5D's": 1.0, "ZEXAL": 1.2}.get(era, 1.0)
	b.clip_text = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", UITheme.title_font())
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", ec.lightened(0.25))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.7), 10, Color(ec, 0.35)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 10, ec.lightened(0.2)))
	var lit := UITheme.panel_box(Color(ec.darkened(0.45), 0.95), 10, ec.lightened(0.35))
	lit.set_border_width_all(2)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, lit)
	b.tooltip_text = Loc.t("Show every duelist") if era == "" else Loc.t("Show only %s") % era
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		_show_era(era))
	_era_tabs[era] = b
	return b


## Show one era in the list ("" = all). The rival stays picked if they are still in view;
## otherwise the first duelist you can face in that era is picked.
func _show_era(era: String, pick := true) -> void:
	era_pick = era
	for e in _era_tabs:
		(_era_tabs[e] as Button).set_pressed_no_signal(e == era)
	for e in _era_groups:
		(_era_groups[e] as Control).visible = era == "" or e == era
	if not pick:
		return
	if era != "" and str(Characters.get_char(_opp).get("era", "")) != era:
		for k in Characters.ORDER:
			if str(Characters.DATA[k].get("era", "")) == era and _usable(str(k)) and str(k) != _me:
				_pick(str(k))
				break
	_list_scroll.scroll_vertical = 0
	# (An era where nobody can be faced yet keeps the rival you had, and the list stays on that era.)
	if era == "" or str(Characters.get_char(_opp).get("era", "")) == era:
		_scroll_to(_opp)


## Q / E (or the shoulder buttons) step through the era tabs.
func _step_era(d: int) -> void:
	var order: Array = [""]
	for e in Characters.ERAS:
		if _era_groups.has(e):
			order.append(str(e))
	var i := order.find(era_pick)
	_show_era(str(order[posmod(i + d, order.size())]))
	if _era_tabs.has(era_pick):
		(_era_tabs[era_pick] as Button).grab_focus()


## A small card under the list: a heading, one big line, one small line.
func _mode_card(col: Color, head: String, mid: String, foot: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 92)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.82), 14, Color(col, 0.6)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(col.darkened(0.7), 0.95), 14, col))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(col.darkened(0.55), 0.98), 14, col.lightened(0.3)))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -10
	v.offset_top = 8
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	for r in [[head, 14, col, UITheme.semi_font()], [mid, 21, Color.WHITE, UITheme.title_font()], [foot, 14, UITheme.TEXT_DIM, null]]:
		var l := UITheme.label(str(r[0]), int(r[1]), r[2], r[3])
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	return b


## One duelist in the list: their face, name, stars and the medals you hold against them.
func _list_row(key: String) -> Button:
	var info := Portraits.info(key)
	var ok := _usable(key)
	var has_deck := Characters.available(key)
	var ec := era_color(key)
	var col: Color = info.get("color", ec)
	var b := Button.new()
	b.custom_minimum_size = Vector2(414, 68)
	b.clip_contents = true
	b.toggle_mode = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.62), 12, Color(1, 1, 1, 0.08)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.88), 12, Color(col, 0.9)))
	var on := UITheme.panel_box(Color(col.darkened(0.6), 0.92), 12, col.lightened(0.2))
	on.set_border_width_all(2)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, on)
	var face_box := Control.new()
	face_box.position = Vector2(6, 5)
	face_box.size = Vector2(58, 58)
	face_box.clip_contents = true
	face_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(face_box)
	var tint := ColorRect.new()
	tint.color = Color(col.darkened(0.55), 0.85)
	tint.size = face_box.size
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_box.add_child(tint)
	var pt := TextureRect.new()
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_face(pt, key, face_box.size)
	if Portraits._cache.has(key):
		pt.texture = Portraits.get_portrait(key)
	else:
		_pending.append([pt, key])
	if not ok:
		pt.modulate = Color(0.32, 0.32, 0.38)
	face_box.add_child(pt)
	var name := UITheme.label(Loc.t(str(info.get("name", key))), 21, Color.WHITE if ok else Color(1, 1, 1, 0.45), UITheme.title_font())
	name.position = Vector2(76, 6)
	name.size = Vector2(250, 30)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(name)
	var st_text := "★".repeat(_stars(key)) + "☆".repeat(5 - _stars(key))
	var under := st_text
	if not ok:
		under = Loc.t("Locked") if has_deck else Loc.t("Needs the card database")
	var sl := UITheme.label(under, 16, UITheme.GOLD if ok else UITheme.TEXT_DIM, UITheme.semi_font())
	sl.position = Vector2(76, 36)
	sl.size = Vector2(250, 24)
	sl.clip_text = true
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sl)
	if ok:
		var got: Array = Collection.medals(key)
		for i in 3:
			var pip := Panel.new()
			var mc: Color = Collection.MEDALS[i]["color"]
			var ps := StyleBoxFlat.new()
			ps.bg_color = mc if got[i] else Color(0, 0, 0, 0.5)
			ps.border_color = Color(0, 0, 0, 0.8) if got[i] else Color(1, 1, 1, 0.3)
			ps.set_border_width_all(1)
			ps.set_corner_radius_all(7)
			pip.add_theme_stylebox_override("panel", ps)
			pip.size = Vector2(13, 13)
			pip.position = Vector2(340 + i * 18, 28)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(pip)
	else:
		var lock := UITheme.label("🔒", 20, Color(1, 1, 1, 0.5))
		lock.position = Vector2(372, 18)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lock)
	var tip := "%s\n%s" % [Loc.t(str(info.get("name", ""))), Loc.t(str(info.get("title", "")))]
	if not ok:
		tip = Unlocks.opponent_why(key) if has_deck else Loc.t("Download the full card database to unlock %s") % str(info.get("short", key))
	b.tooltip_text = tip
	b.pressed.connect(func():
		if not ok:
			b.set_pressed_no_signal(false)
			if has_deck:
				Router.toast("%s  ·  %s" % [str(info.get("short", "")), Unlocks.opponent_why(key)], 3.2)
			else:
				Router.toast(Loc.t("Download the full card database to unlock %s") % str(info.get("short", key)))
			return
		_pick(key))
	_rows[key] = b
	return b


## A face in a small square: head and shoulders, as the roster tiles frame them.
func _fit_face(pt: TextureRect, key: String, box: Vector2) -> void:
	if not Avatars.has_avatar(key):
		pt.size = Vector2(box.x, box.x * 640.0 / 512.0)
		pt.position = Vector2(0, 0)
		return
	var h := Avatars.portrait_view(key) * box.y * 1.5
	var w := h * 512.0 / 640.0
	pt.size = Vector2(w, h)
	pt.position = Vector2((box.x - w) / 2.0, box.y * 0.5 - h * 0.46)


func _pick(key: String) -> void:
	if key == _opp:
		return
	_opp = key
	_version = "full"
	Sfx.play("card", -6.0)
	_back.fade_to(_picture_of(key))
	_refresh_all()
	# The new rival comes in from the right.
	_rival_pic.modulate = Color(1, 1, 1, 0)
	var home := _rival_pic.position
	_rival_pic.position.x += 90.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_rival_pic, "modulate:a", 1.0, 0.3)
	tw.tween_property(_rival_pic, "position", home, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ the middle: the rival and the setup

func _build_info() -> void:
	_info = VBoxContainer.new()
	_info.position = Vector2(540, 46)
	_info.size = Vector2(700, 1000)
	_info.add_theme_constant_override("separation", 10)
	_root.add_child(_info)


func _clear_info() -> void:
	for n in _info.get_children():
		_info.remove_child(n)
		n.queue_free()


func _refresh_all() -> void:
	for k in _rows:
		(_rows[k] as Button).set_pressed_no_signal(k == _opp)
	_place_rival()
	_rival_pic.texture = Portraits.get_portrait(_opp, true)
	_fill_info()


## Where the big picture of the rival goes: right of the middle column, feet past the bottom edge.
func _place_rival() -> void:
	if _rival_pic == null or _root == null:
		return
	var o := _root.position
	var box_h := H * 1.02
	var h := box_h
	if Avatars.has_avatar(_opp):
		h = Avatars.portrait_view(_opp) * box_h * 0.95
	var w := h * 512.0 / 640.0
	_rival_pic.size = Vector2(w, h)
	_rival_pic.position = Vector2(o.x + 1590.0 - w * 0.5, o.y + H * 0.5 - h * 0.42)


func _fill_info() -> void:
	_clear_info()
	var key := _opp
	var info := Portraits.info(key)
	var c := Characters.get_char(key)
	var ec := era_color(key)
	var col: Color = info.get("color", ec)
	var era := str(c.get("era", ""))
	var over := UITheme.label(("%s   ·   %s" % [era, Loc.t("RIVAL")]).to_upper(), 19, ec.lightened(0.25), UITheme.semi_font())
	_info.add_child(over)
	var nm := UITheme.label(Loc.t(str(info.get("name", key))).to_upper(), 78, Color.WHITE, UITheme.title_font())
	nm.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	nm.add_theme_constant_override("shadow_offset_y", 5)
	nm.custom_minimum_size = Vector2(700, 0)
	nm.clip_text = true
	_fit_font(nm, 78, 700.0)
	_info.add_child(nm)
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(150, 6)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_info.add_child(bar)
	var title := Loc.t(str(info.get("title", "")))
	var how: String = {"aggro": "Plays aggressive", "wall": "Plays defensive", "trap": "Sets traps"}.get(DuelAI.style_for(key), "")
	if how != "":
		title = (title + "   ·   " if title != "" else "") + Loc.t(how)
	var tl := UITheme.label(title, 22, Color(0.9, 0.93, 1.0, 0.92), UITheme.semi_font())
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(700, 0)
	_info.add_child(tl)
	var said := Characters.line(key, "intro")
	if said != "":
		var q := UITheme.label("“%s”" % said, 21, Color(1, 1, 1, 0.78))
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.custom_minimum_size = Vector2(700, 0)
		_info.add_child(q)
	# Their stars, your record against them and the three medals there are to win.
	var rec_card := PanelContainer.new()
	rec_card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.8), 18, Color(col, 0.6)))
	rec_card.custom_minimum_size = Vector2(700, 0)
	_info.add_child(rec_card)
	var rm := MarginContainer.new()
	for s in ["left", "right"]:
		rm.add_theme_constant_override("margin_" + s, 22)
	for s in ["top", "bottom"]:
		rm.add_theme_constant_override("margin_" + s, 12)
	rec_card.add_child(rm)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	rm.add_child(rv)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 18)
	rv.add_child(r1)
	var stars := _stars(key)
	r1.add_child(UITheme.label("★".repeat(stars) + "☆".repeat(5 - stars), 28, UITheme.GOLD, UITheme.title_font()))
	var rec := Collection.versus(key)
	var rec_text := Loc.t("No duels yet") if rec[0] + rec[1] == 0 else (Loc.t("%d W  %d L") % [rec[0], rec[1]])
	var rl := UITheme.label(rec_text, 26, Color.WHITE, UITheme.title_font())
	rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r1.add_child(rl)
	var last := Profile.last_vs(key)
	if last != 0:
		var ll := UITheme.label(Loc.t("Last time: you won") if last > 0 else Loc.t("Last time: they won"), 18, Color("7ee08a") if last > 0 else Color("ff8a7a"), UITheme.semi_font())
		ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r1.add_child(ll)
	var held: Array = Collection.medals(key)
	var parts: Array = []
	for i in 3:
		parts.append(("★ " if held[i] else "☆ ") + Loc.t(str(Collection.MEDALS[i]["name"])))
	var ml := UITheme.label(Loc.t("Medals") + ":   " + "     ".join(parts), 17, UITheme.GOLD, UITheme.semi_font())
	ml.mouse_filter = Control.MOUSE_FILTER_STOP
	ml.tooltip_text = "\n".join(Collection.MEDALS.map(func(m): return "%s: %s  (+%d)" % [Loc.t(str(m["name"])), Loc.t(str(m["how"])), int(m["dp"])]))
	rv.add_child(ml)
	var base := _base_deck()
	if rec[0] < 3 and not Collection.decks_owned.has(base):
		rv.add_child(UITheme.label(Loc.t("Win %d more to get their deck as a ready-made deck") % (3 - rec[0]), 16, UITheme.TEXT_DIM))
	# Their deck in three versions: three cards side by side, the one you will face lit.
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 12)
	_info.add_child(dh)
	var dt := UITheme.label(Loc.t("THEIR DECK") + "   ·   " + CardData.deck_name(base), 19, ec.lightened(0.25), UITheme.semi_font())
	dt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dt.clip_text = true
	dt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dh.add_child(dt)
	var peek := _glass(Loc.t("See deck"), col, _peek_deck)
	peek.custom_minimum_size = Vector2(150, 40)
	peek.size_flags_horizontal = Control.SIZE_SHRINK_END
	peek.add_theme_font_size_override("font_size", 17)
	dh.add_child(peek)
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 14)
	_info.add_child(_cards_row)
	for v in VERSIONS:
		_cards_row.add_child(_version_card(str(v), col))
	_version_line = UITheme.label("", 17, Color(1, 1, 1, 0.85))
	_version_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_version_line.custom_minimum_size = Vector2(700, 0)
	_info.add_child(_version_line)
	_paint_version_line()
	# You: who you play as and with which deck.
	var you := HBoxContainer.new()
	you.add_theme_constant_override("separation", 10)
	_info.add_child(you)
	var yl := UITheme.label(Loc.t("YOU"), 19, UITheme.ACCENT, UITheme.semi_font())
	yl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	you.add_child(yl)
	_me_pick = OptionButton.new()
	_me_pick.custom_minimum_size = Vector2(200, 44)
	_me_pick.add_theme_font_size_override("font_size", 17)
	_me_pick.fit_to_longest_item = false
	_me_pick.tooltip_text = Loc.t("Who you play as")
	_fill_me()
	_me_pick.item_selected.connect(func(i):
		_me = str(_me_keys[i])
		_my_deck = ""
		_fill_my_decks()
		Sfx.play("card", -10.0))
	you.add_child(_me_pick)
	_deck_pick = OptionButton.new()
	_deck_pick.custom_minimum_size = Vector2(0, 44)
	_deck_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_pick.add_theme_font_size_override("font_size", 17)
	_deck_pick.fit_to_longest_item = false
	_deck_pick.clip_text = true
	_deck_pick.item_selected.connect(func(i):
		_my_deck = str(_deck_keys[i]))
	you.add_child(_deck_pick)
	var mine := _glass(Loc.t("See deck"), UITheme.ACCENT, _peek_mine)
	mine.custom_minimum_size = Vector2(130, 44)
	mine.size_flags_horizontal = Control.SIZE_SHRINK_END
	mine.add_theme_font_size_override("font_size", 17)
	you.add_child(mine)
	_fill_my_decks()
	_info.add_child(_difficulty_row(col))
	# The duel, then the row of everything else.
	_go = Button.new()
	_go.text = Loc.t("DUEL!")
	_go.custom_minimum_size = Vector2(700, 86)
	_go.add_theme_font_size_override("font_size", 48)
	_go.add_theme_font_override("font", Comic.shout_font())
	UITheme.paint_button(_go, col.darkened(0.2))
	_go.pressed.connect(_start_duel)
	_info.add_child(_go)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(700, 0)
	_info.add_child(row)
	row.add_child(_glass(Loc.t("Random rival"), col, _random_opponent))
	var more := _glass(Loc.t("More options"), col, _more_options)
	more.tooltip_text = Loc.t("Turbo Duel, Best of 3, Destiny Draw, Life Points, who goes first, Gauntlet and Survival, the hand, the arena, and their deck as one of yours.")
	row.add_child(more)
	row.add_child(_glass(Loc.t("Back"), col, _close))
	if is_instance_valid(_go) and is_inside_tree():
		_go.grab_focus.call_deferred()


## A long name gets a smaller font instead of running past the column.
func _fit_font(l: Label, base: int, width: float) -> void:
	var f: Font = l.get_theme_font("font")
	var sz := base
	while sz > 40 and f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width:
		sz -= 4
	l.add_theme_font_size_override("font_size", sz)


## What a deck version holds: [its ace, monsters, Spells and Traps, Extra Deck] (worked out once).
func _version_facts(deck_key: String) -> Array:
	if _version_cache.has(deck_key):
		return _version_cache[deck_key]
	var main: Array = CardData.deck_list(deck_key)
	var extra: Array = CardData.extra_list(deck_key)
	var best := 0
	var best_atk := -1
	var mons := 0
	for id in main:
		var d := CardData.get_card(id)
		if d.get("kind", "") in ["spell", "trap"]:
			continue
		mons += 1
	var seen := {}
	for id in extra + main:
		if seen.has(id):
			continue
		seen[id] = true
		var d := CardData.get_card(id)
		if d.get("kind", "") in ["spell", "trap"]:
			continue
		if int(d.get("atk", 0)) > best_atk:
			best_atk = int(d.get("atk", 0))
			best = int(id)
	# The picture is their ace when this version has it (Crowler's Golem, Joey's Red-Eyes),
	# otherwise the strongest monster in it.
	var ace := _ace_id()
	if ace != 0 and seen.has(ace):
		best = ace
	var out := [best, mons, main.size() - mons, extra.size()]
	_version_cache[deck_key] = out
	return out


## The rival's ace card: its number in Characters ("ace"), or found by its name ("ace_name").
func _ace_id() -> int:
	var c: Dictionary = Characters.get_char(_opp)
	if c.get("ace", 0) is int and int(c.get("ace", 0)) != 0:
		return int(c["ace"])
	var nm := str(c.get("ace_name", "")).to_lower()
	if nm != "" and CardData.NAME_TO_ID.has(nm):
		return int(CardData.NAME_TO_ID[nm])
	return 0


## One version of their deck as a card: its strongest monster, the version's name, what is in it.
func _version_card(v: String, col: Color) -> Button:
	var dk := _version_key(v)
	var ok := CardData.has_deck(_base_deck())
	var facts: Array = _version_facts(dk) if ok else [0, 0, 0, 0]
	var on := v == _version
	var b := Button.new()
	b.custom_minimum_size = Vector2(224, 184)
	b.toggle_mode = true
	b.button_pressed = on
	b.clip_contents = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.78), 16, Color(1, 1, 1, 0.14)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.92), 16, col.lightened(0.15)))
	var lit := UITheme.panel_box(Color(col.darkened(0.6), 0.95), 16, col.lightened(0.3))
	lit.set_border_width_all(3)
	lit.shadow_color = Color(col, 0.45)
	lit.shadow_size = 16
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, lit)
	var art := TextureRect.new()
	art.texture = Cards.get_face(int(facts[0])) if int(facts[0]) != 0 else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(12, 12)
	art.size = Vector2(70, 102)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not on:
		art.modulate = Color(0.75, 0.75, 0.8)
	b.add_child(art)
	var steps := {"starter": 1, "standard": 2, "full": 3}
	var pips := HBoxContainer.new()
	pips.position = Vector2(92, 16)
	pips.add_theme_constant_override("separation", 4)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pips)
	for i in 3:
		var p := ColorRect.new()
		p.color = col.lightened(0.2) if i < int(steps[v]) else Color(1, 1, 1, 0.18)
		p.custom_minimum_size = Vector2(24, 7)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(p)
	var vn := UITheme.label(Loc.t(str(VERSION_NAME[v])).to_upper(), 20, Color.WHITE if on else Color(1, 1, 1, 0.85), UITheme.title_font())
	vn.position = Vector2(92, 30)
	vn.size = Vector2(124, 28)
	vn.clip_text = true
	vn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vn)
	# What is in it, under the picture: monsters and the Extra Deck, then Spells and Traps.
	var facts_box := VBoxContainer.new()
	facts_box.position = Vector2(92, 60)
	facts_box.size = Vector2(124, 56)
	facts_box.add_theme_constant_override("separation", 0)
	facts_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(facts_box)
	var lines: Array = [Loc.t("%d monsters") % int(facts[1])]
	if int(facts[3]) > 0:
		lines.append("+ " + Loc.t("%d Extra") % int(facts[3]))
	lines.append(Loc.t("%d Spells and Traps") % int(facts[2]))
	for t in lines:
		var l := UITheme.label(t, 13, UITheme.TEXT_DIM, UITheme.semi_font())
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		facts_box.add_child(l)
	# What the version means, in one plain line under the picture (two at most).
	var st := UITheme.label(Loc.t(str(VERSION_HOW[v])), 13, Color(1, 1, 1, 0.92) if on else UITheme.TEXT_DIM, UITheme.semi_font())
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.position = Vector2(12, 120)
	st.size = Vector2(202, 50)
	st.add_theme_constant_override("line_spacing", -3)
	st.max_lines_visible = 2
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(st)
	var bar := ColorRect.new()
	bar.color = col.lightened(0.2) if on else Color(1, 1, 1, 0.08)
	bar.position = Vector2(12, 174)
	bar.size = Vector2(200, 3)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bar)
	b.tooltip_text = "%s: %s" % [Loc.t(str(VERSION_NAME[v])), Loc.t(str(VERSION_HOW[v]))]
	b.pressed.connect(func():
		_version = v
		Sfx.play("card", -8.0)
		for n in _cards_row.get_children():
			n.queue_free()
		for v2 in VERSIONS:
			_cards_row.add_child(_version_card(str(v2), col))
		_paint_version_line()
		for n in _cards_row.get_children():
			if (n as Button).button_pressed:
				(n as Button).grab_focus.call_deferred())
	return b


## The version you will face, in words, under the three cards.
func _paint_version_line() -> void:
	if _version_line:
		_version_line.text = "%s:  %s" % [Loc.t(str(VERSION_NAME[_version])), Loc.t(str(VERSION_HOW[_version]))]


## Who you play as: yourself, or any duelist you have met.
func _fill_me() -> void:
	_me_pick.clear()
	_me_keys = ["player"]
	_me_pick.add_item(Loc.t("Play as: you"))
	for k in Characters.ORDER:
		if _usable(str(k)):
			_me_keys.append(str(k))
			_me_pick.add_item(Loc.t("Play as: %s") % str(Characters.get_char(str(k)).get("short", k)))
	if not _me_keys.has(_me):
		_me = "player"
	_me_pick.select(_me_keys.find(_me))


## YOUR DECK: the deck of the duelist you play as (when that is not you), and your own decks.
func _fill_my_decks() -> void:
	_deck_pick.clear()
	_deck_keys.clear()
	if _me != "player":
		var own := str(Characters.get_char(_me).get("deck", ""))
		if CardData.has_deck(own):
			_deck_keys.append(own)
			_deck_pick.add_item(Loc.t("%s's own deck") % str(Characters.get_char(_me).get("short", _me)))
	if CardData.has_deck("custom"):
		_deck_keys.append("custom")
		_deck_pick.add_item(Loc.t("My deck: %s") % CardData.deck_name("custom"))
	for md in Collection.my_decks():
		if not md["open"]:
			_deck_keys.append(str(md["key"]))
			_deck_pick.add_item(Loc.t("My deck: %s") % str(md["name"]))
	if _deck_keys.is_empty() and CardData.has_deck("echo"):
		_deck_keys.append("echo")
		_deck_pick.add_item(CardData.deck_name("echo"))
	if not _deck_keys.has(_my_deck) and not _deck_keys.is_empty():
		_my_deck = str(_deck_keys[0])
	_deck_pick.select(maxi(0, _deck_keys.find(_my_deck)))


## Normal / Hard / Extreme as three glass tabs, and what a win pays.
func _difficulty_row(col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := UITheme.label(Loc.t("Difficulty"), 19, UITheme.TEXT_DIM, UITheme.semi_font())
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	_diff_tabs = []
	var notes := ["", "Looks a little ahead and sometimes slips, like a person.",
			"Plans its turn by trying its plays on copies of the duel and checks what you could answer. Tuned deck.",
			"Tries more plays, against more of what you might be holding, for longer. Tuned deck. It never looks at your hand or face-down cards."]
	for i in 3:
		var b := Button.new()
		b.text = Loc.t(["Normal", "Hard", "Extreme"][i])
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(124, 44)
		b.add_theme_font_size_override("font_size", 19)
		b.tooltip_text = Loc.t(str(notes[i + 1]))
		b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.6), 12, Color(1, 1, 1, 0.16)))
		b.add_theme_stylebox_override("hover", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.85), 12, col.lightened(0.2)))
		b.add_theme_stylebox_override("focus", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.85), 12, col.lightened(0.2)))
		b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(col.darkened(0.55), 0.92), 12, col.lightened(0.3)))
		b.add_theme_stylebox_override("hover_pressed", UITheme.panel_box(Color(col.darkened(0.5), 0.95), 12, col.lightened(0.4)))
		for fc in ["font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_hover_color"]:
			b.add_theme_color_override(fc, Color.WHITE)
		b.button_pressed = _difficulty == i + 1
		_diff_tabs.append(b)
		h.add_child(b)
	_reward = UITheme.label("", 17, UITheme.GOLD, UITheme.semi_font())
	_reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_reward)
	for i in 3:
		var me: Button = _diff_tabs[i]
		me.pressed.connect(func():
			Sfx.play("click", -8.0)
			_difficulty = i + 1
			Settings.free_difficulty = _difficulty
			Settings.save_settings()
			for j in 3:
				(_diff_tabs[j] as Button).set_pressed_no_signal(j == i)
			_paint_reward())
	_paint_reward()
	return h


func _paint_reward() -> void:
	if _reward:
		_reward.text = Loc.t("Win +%d Duel Points  ·  Lose +40") % (120 + 60 * _difficulty)


## A glass button (as on the Academy's door).
func _glass(text: String, col: Color, act: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 60)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 21)
	b.clip_text = true
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 14, col.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.1, 0.14, 0.26, 0.95), 14, col.lightened(0.4)))
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		act.call())
	return b


func _process(delta: float) -> void:
	_t += delta
	# List faces load a couple per frame, so the screen opens at once and fills in.
	for i in 2:
		if _pending.is_empty():
			break
		var job: Array = _pending.pop_front()
		if is_instance_valid(job[0]):
			(job[0] as TextureRect).texture = Portraits.get_portrait(str(job[1]))
			(job[0] as TextureRect).modulate.a = 0.0
			create_tween().tween_property(job[0], "modulate:a", 1.0, 0.2)


# ------------------------------------------------------------------ actions

func _peek_deck() -> void:
	var deck := _version_key(_version)
	if not CardData.has_deck(_base_deck()):
		Router.toast(Loc.t("Their deck needs the card database."))
		return
	Sfx.play("select", -4.0)
	var dp := DeckPeek.new(_opp, deck)
	dp.z_index = 200
	add_child(dp)


func _peek_mine() -> void:
	if not CardData.has_deck(_my_deck):
		return
	Sfx.play("select", -4.0)
	var mine: bool = _my_deck == "custom" or _my_deck.begins_with("slot:")
	var dp := DeckPeek.new("player" if mine else _me, _my_deck)
	dp.z_index = 200
	add_child(dp)


func _random_opponent() -> void:
	var pool := []
	for k in Characters.ORDER:
		if _usable(str(k)) and str(k) != _opp:
			pool.append(str(k))
	if pool.is_empty():
		return
	var k: String = pool[randi() % pool.size()]
	_pick(k)
	_scroll_to(k)


func _scroll_to(key: String) -> void:
	if not _rows.has(key):
		return
	# (A rival outside the era tab in use brings their own era into view.)
	var e := str(Characters.get_char(key).get("era", ""))
	if era_pick != "" and e != era_pick and _era_groups.has(e):
		_show_era(e, false)
	# (After the list has its layout: two frames.)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_list_scroll) and _rows.has(key):
		var b: Button = _rows[key]
		_list_scroll.scroll_vertical = int(maxf(0.0, b.position.y - 140.0))


## The full setup screen (from before 0.69.1), opened with what you picked here.
func _more_options() -> void:
	if _starting:
		return
	Router.duel_config = _config()
	var cs := CharacterSelect.new()
	cs.z_index = 10
	add_child(cs)
	cs.start.connect(func(cfg):
		_starting = true
		start.emit(cfg))
	cs.knockout.connect(func():
		cs.queue_free()
		knockout.emit())
	cs.closed.connect(func():
		# Whatever was picked there comes back here.
		if is_instance_valid(cs):
			if cs._opp != _opp and _usable(cs._opp):
				_opp = cs._opp
				_back.fade_to(_picture_of(_opp))
			_me = cs._me if (cs._me == "player" or _usable(cs._me)) else "player"
			_my_deck = cs._my_deck
			_field = cs._field
			_version = _version_of(cs._their_deck)
			_difficulty = clampi(cs._difficulty, 1, 3)
		_refresh_all()
		_scroll_to(_opp))


func _config() -> Dictionary:
	var cfg := {"player_char": _me, "opponent": _opp, "player_deck": _my_deck, "difficulty": _difficulty, "field": _field, "match": false,
		"turbo": false, "lp": 8000, "hand": 5, "destiny": Settings.destiny_draw, "cpu_level": _difficulty}
	if _version != "full":
		cfg["opponent_deck"] = _version_key(_version)
	return cfg


func _start_duel() -> void:
	if _starting:
		return
	if not CardData.has_deck(_my_deck):
		Router.toast(Loc.t("Pick a deck first."))
		return
	_starting = true
	Sfx.play("summon", -4.0)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw2 := create_tween()
	tw2.tween_interval(0.12)
	tw2.tween_property(flash, "color:a", 1.0, 0.14)
	tw2.tween_property(flash, "color", Color(0, 0, 0, 1), 0.2)
	await tw2.finished
	Router.match_state = {}
	start.emit(_config())


func _close() -> void:
	if _starting:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Q, KEY_E]) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		for n in get_children():
			if n is CharacterSelect or n is DeckPeek:
				return
		var back: bool = (event is InputEventKey and event.keycode == KEY_Q) or (event is InputEventJoypadButton and Pad.b(event) == JOY_BUTTON_LEFT_SHOULDER)
		get_viewport().set_input_as_handled()
		_step_era(-1 if back else 1)
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		# (The full setup screen, when it is open over this one, closes itself first.)
		for n in get_children():
			if n is CharacterSelect or n is DeckPeek:
				return
		get_viewport().set_input_as_handled()
		_close()
