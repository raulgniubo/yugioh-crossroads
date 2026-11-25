class_name CharacterSelect
extends Control
## Free Duel (what "Free Duel" opens). Two big duelist panels face each other across a VS; the
## roster sits underneath, by era; on the right, in glass cards: your deck, their deck (three
## versions: Basic / Strong / Competitive), the field, the difficulty and the rules. Tap a panel
## (YOU / OPPONENT) to say who you are choosing, then tap a duelist. Behind it all, still, the
## world of the rival's era (or of the field you picked), under a dark shade.
## Keys: Q / E (LB / RB) step the eras, Tab (Y) switches the side you choose, Start duels.

signal start(config: Dictionary)
signal closed
signal knockout          # the Knockout button: the menu swaps this screen for the bracket
signal online            # the Online button (0.73.0): the menu swaps this screen for the Online screen

const W := 1920.0
const H := 1080.0
const PANEL_SIZE := Vector2(506, 438)
const CELL := Vector2(102, 124)

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
var _fate_off_btn: CheckButton          # Destiny Draw switched off for this duel
var _engine_btn: CheckButton            # the new rules engine for this duel (a test switch while it is being built)
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
var _medal_line: Label
var _vs: Label
var _go: Button
var _starting := false
var _t := 0.0
var _pending: Array = []      # [TextureRect, key]: roster portraits still to load, a couple per frame
var _bg: AcademyBackdrop      # the still world picture behind everything
var _bg_path := ""
var _big_wait := {}           # side -> key: a big portrait waiting for its model (read on a worker thread)
var _my_cards: HBoxContainer      # the three versions of the deck of the duelist you play as
var _their_cards: HBoxContainer   # the three versions of the rival's deck
var _mine_box: VBoxContainer      # your own decks (when you play as yourself)
var _their_other: OptionButton    # or one of your decks for them
var _their_other_keys: Array = []
var _tab_counts := {}

const VERSIONS := ["starter", "standard", "full"]
## What the player sees for the three versions of a deck (the keys stay starter / standard / full).
const VERSION_NAME := {"starter": "Basic", "standard": "Strong", "full": "Competitive", "anime1": "Anime", "anime2": "Anime"}
const VERSION_HOW := {
	"starter": "A simple version: fewer key cards, good to start.",
	"standard": "More of their key cards and combos.",
	"full": "Their full deck, at full power.",
	"anime1": "The deck they played early in the show.",
	"anime2": "The deck they played later in the show.",
}
## The world behind each era (5D's: the two from the Satellite stand over it).
const ERA_PICTURE := {
	"Duel Monsters": "res://assets/ui/story_title_domino.jpg",
	"GX": "res://assets/ui/academy_title.jpg",
	"5D's": "res://assets/ui/story_title_newdomino.jpg",
	"ZEXAL": "res://assets/ui/story_title_heartland.jpg",
}
const SATELLITE := ["crow", "kalin"]
## A field picked by hand shows its own world, where there is a big picture of it.
const ARENA_PICTURE := {
	"battlecity": "res://assets/ui/story_title_domino.jpg", "kaibacorp": "res://assets/ui/story_title_domino.jpg",
	"pier": "res://assets/ui/story_title_domino.jpg", "academy": "res://assets/ui/academy_title.jpg",
	"reddorm": "res://assets/ui/academy_title.jpg", "bluehall": "res://assets/ui/academy_title.jpg",
	"satellite": "res://assets/ui/story_title_satellite.jpg", "highway": "res://assets/ui/roam_title_highway.jpg",
	"crossroads": "res://assets/ui/story_title_newdomino.jpg", "heartland": "res://assets/ui/story_title_heartland.jpg",
	"ruins": "res://assets/ui/story_title_museum.jpg", "shadow": "res://assets/ui/story_title_museum.jpg",
}
static var _version_cache := {}   # deck key -> [ace id, monsters, spells/traps, extra] (a version does not change during a run)
var _retouch := false


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cfg: Dictionary = Router.duel_config
	_me = cfg.get("player_char", "player")
	_opp = cfg.get("opponent", "kaiba")
	# Never start on someone you have not unlocked yet: the first one you have.
	if not Characters.available(_opp) or not Unlocks.opponent(_opp):
		for k in Characters.ORDER:
			if Characters.available(k) and Unlocks.opponent(k) and k != _me:
				_opp = k
				break
	_difficulty = Settings.free_difficulty   # Normal unless you picked another one here before
	_my_deck = cfg.get("player_deck", "yugi")
	# Their deck as one of its versions (Free Duel's front screen picks one: "kaiba@standard").
	# Back from a Free Duel: the version you had. Otherwise their last anime deck (see _default_their_deck).
	var od := str(cfg.get("opponent_deck", ""))
	_their_deck = "" if str(cfg.get("opponent_version", "")) == "full" else _default_their_deck(_opp)
	if od.contains("@"):
		var sp: Array = DeckTiers.split(od)
		if str(sp[0]) == str(Characters.get_char(_opp).get("deck", "")) and str(sp[1]) in ["starter", "standard", "anime1", "anime2"]:
			_their_deck = "@" + str(sp[1])
	if not CardData.has_deck(_my_deck):
		_my_deck = "echo" if CardData.has_deck("echo") else "yugi"
	_field = str(cfg.get("field", Settings.field_theme))
	if _field != "auto" and not FieldThemes.THEMES.has(_field):
		_field = "auto"
	# The world of the rival's era, still, under a dark shade so the panels read over it.
	_bg_path = _picture_for()
	_bg = AcademyBackdrop.new(0.5, _bg_path)
	add_child(_bg)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.032, 0.075, 0.3)
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
	header.position = Vector2(226, 22)
	_root.add_child(header)
	var bar := ColorRect.new()
	bar.color = UITheme.ACCENT
	bar.position = Vector2(228, 98)
	bar.size = Vector2(118, 4)
	_root.add_child(bar)
	_build_picker()
	_build_slots()
	_build_setup()
	_build_tabs()
	_build_extras.call_deferred()      # (today's duel works out who is in it: after the first frame)
	_grid = GridContainer.new()
	# Ten across, three rows: the roster owns the bottom left and never reaches the setup
	# column on the right.
	_grid.columns = 10      # (ten across since Crowler, Sheppard and Bastion joined: 29 tiles in three rows)
	_grid.position = Vector2(64, 632)
	_grid.add_theme_constant_override("h_separation", 7)
	_grid.add_theme_constant_override("v_separation", 7)
	_root.add_child(_grid)
	_refresh_all()
	_enter()
	_focus_opp.call_deferred()


## The tile of whoever is picked gets the keyboard / controller focus, so arrows start there.
func _focus_opp() -> void:
	var key := _opp if _picking == "opp" else _me
	for c in _grid.get_children():
		if str(c.get_meta("key", "")) == key:
			(c as Control).grab_focus()
			return
	if _grid.get_child_count() > 0:
		(_grid.get_child(0) as Control).grab_focus()


## The picture behind: the field you picked (when there is a big picture of it), else the rival's era.
func _picture_for() -> String:
	if _field != "auto" and ARENA_PICTURE.has(_field):
		return str(ARENA_PICTURE[_field])
	if _opp in SATELLITE:
		return "res://assets/ui/story_title_satellite.jpg"
	var era := str(Characters.get_char(_opp).get("era", "Duel Monsters"))
	return str(ERA_PICTURE.get(era, ERA_PICTURE["Duel Monsters"]))


func _repaint_world() -> void:
	var want := _picture_for()
	if want != _bg_path and _bg != null:
		_bg_path = want
		_bg.fade_to(want, 0.5)


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
	# A tile zooms in on the face. How far depends on how wide that duelist's picture had to be
	# for the hair, which is only known a moment after the picture is first asked for.
	for z in _zoom_tiles:
		if is_instance_valid(z):
			_fit_tile(z as TextureRect, str((z as TextureRect).get_meta("key", "")))
	for side in _slots:
		_fit_slot(_slots[side]["portrait"], str(_slots[side]["key"]))
	if _zoom_t < 0.0:
		_zoom_tiles.clear()
	_zoom_t -= delta
	if _zoom_tiles.is_empty():
		_zoom_t = 1.5
	for ak in _arena_wait.keys():
		var at := arena_picture_later(str(_arena_wait[ak]))
		if at != null:
			(_arena_tiles[ak][1] as TextureRect).texture = at
			_arena_wait.erase(ak)
	# The two big portraits come in when their models are read (on a worker thread).
	for side in _big_wait.keys():
		var bk := str(_big_wait[side])
		if Avatars.ready_now(bk) or Portraits.holds(bk):
			_big_wait.erase(side)
			var bpt: TextureRect = _slots[side]["portrait"]
			bpt.texture = Portraits.get_portrait(bk, true)
			_fit_slot(bpt, bk)
			bpt.modulate.a = 0.0
			create_tween().tween_property(bpt, "modulate:a", 1.0, 0.25)
			break        # (one a frame: each is a small 3D picture to set up)
		else:
			Avatars.warm(bk)
	# Roster portraits: one a frame, and only once its model has been read, so the screen opens
	# at once and nothing stops to read a file. The ones still waiting go to the back of the line.
	for i in 2:
		if _pending.is_empty() or not _big_wait.is_empty():
			break
		var job: Array = _pending.pop_front()
		if is_instance_valid(job[0]) and not (Avatars.ready_now(str(job[1])) or Portraits.holds(str(job[1]))):
			Avatars.warm(str(job[1]))
			_pending.append(job)
			break
		if is_instance_valid(job[0]):
			(job[0] as TextureRect).texture = Portraits.get_portrait(job[1])
			(job[0] as TextureRect).set_meta("key", job[1])
			_zoom_tiles.append(job[0])
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
	# The ribbon on the side being chosen breathes, so the eye lands on it.
	for side in _slots:
		var rb2: Control = _slots[side].get("ribbon")
		if rb2 and rb2.visible:
			rb2.modulate = Color(1, 1, 1).lerp(Color(1.3, 1.3, 1.3), 0.5 + 0.5 * sin(_t * 4.0))


## Two tinted halves split by a slash, in each duelist's color.
func _draw_backdrop() -> void:
	var o := _root.position if _root else Vector2.ZERO
	var a: Color = Portraits.info(_me).get("color", UITheme.ACCENT)
	var b: Color = Portraits.info(_opp).get("color", UITheme.DANGER)
	var mid := o.x + 599.0
	var top := o.y + 104.0
	var bot := o.y + 566.0
	# Two halves washed in the duelists' colors, split by a slash of light.
	var left := PackedVector2Array([Vector2(0, top), Vector2(mid + 70, top), Vector2(mid - 70, bot), Vector2(0, bot)])
	var right := PackedVector2Array([Vector2(mid + 70, top), Vector2(o.x + 1146, top), Vector2(o.x + 1146, bot), Vector2(mid - 70, bot)])
	_backdrop.draw_polygon(left, PackedColorArray([Color(a.darkened(0.5), 0.5), Color(a.darkened(0.2), 0.55), Color(a.darkened(0.65), 0.6), Color(a.darkened(0.75), 0.55)]))
	_backdrop.draw_polygon(right, PackedColorArray([Color(b.darkened(0.2), 0.55), Color(b.darkened(0.5), 0.5), Color(b.darkened(0.75), 0.55), Color(b.darkened(0.65), 0.6)]))
	_backdrop.draw_line(Vector2(0, top), Vector2(o.x + 1146, top), Color(1, 1, 1, 0.14), 1.5)
	_backdrop.draw_line(Vector2(0, bot), Vector2(o.x + 1146, bot), Color(1, 1, 1, 0.14), 1.5)
	_backdrop.draw_line(Vector2(mid + 70, top), Vector2(mid - 70, bot), Color(1, 1, 1, 0.85), 3.0, true)


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
		UITheme.clip_safe(b)
		b.size = PANEL_SIZE
		b.position = Vector2(64 if side == "me" else 628, 116)
		b.pivot_offset = PANEL_SIZE / 2.0
		b.pressed.connect(func():
			_picking = side
			Sfx.play("card", -8.0)
			_refresh_pick())
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
		ace.position = Vector2(PANEL_SIZE.x - 128, PANEL_SIZE.y - 300)   # (above the name and the lines under it, never on them)
		ace.pivot_offset = ace.size / 2.0
		ace.rotation = deg_to_rad(6.0)
		ace.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ace)
		var name_l := Comic.label("", 46, Color.WHITE)
		name_l.position = Vector2(20, PANEL_SIZE.y - 132)
		name_l.size = Vector2(PANEL_SIZE.x - 44, 52)
		name_l.clip_text = true
		b.add_child(name_l)
		var title_l := UITheme.label("", 19, UITheme.GOLD, UITheme.semi_font())
		title_l.position = Vector2(22, PANEL_SIZE.y - 80)
		title_l.size = Vector2(PANEL_SIZE.x - 44, 26)
		title_l.clip_text = true
		title_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_child(title_l)
		var sub := UITheme.label("", 18, UITheme.TEXT_DIM)
		sub.position = Vector2(22, PANEL_SIZE.y - 52)
		sub.size = Vector2(PANEL_SIZE.x - 44, 24)
		sub.clip_text = true
		sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_child(sub)
		# (Their panel only) the medals you hold against them: ★ ☆ ☆ in the top right corner.
		var mbg := PanelContainer.new()
		var msb := UITheme.panel_box(Color(0.02, 0.03, 0.08, 0.72), 10, Color(UITheme.GOLD, 0.55))
		msb.content_margin_left = 10
		msb.content_margin_right = 10
		msb.content_margin_top = 2
		msb.content_margin_bottom = 2
		mbg.add_theme_stylebox_override("panel", msb)
		mbg.position = Vector2(PANEL_SIZE.x - 108, 16)
		mbg.mouse_filter = Control.MOUSE_FILTER_PASS
		mbg.visible = side == "opp"
		b.add_child(mbg)
		var medals := UITheme.label("", 20, UITheme.GOLD, UITheme.semi_font())
		medals.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mbg.add_child(medals)
		# The side the roster is choosing for says so, in a ribbon across the top of its panel.
		var ribbon := PanelContainer.new()
		ribbon.position = Vector2(0, 0)
		ribbon.size = Vector2(PANEL_SIZE.x, 40)
		ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ribbon.visible = false
		b.add_child(ribbon)
		var ribbon_l := UITheme.label("", 22, Color.WHITE, UITheme.title_font())
		ribbon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ribbon.add_child(ribbon_l)
		_slots[side] = {"button": b, "portrait": pt, "name": name_l, "title": title_l, "sub": sub, "tag": tag,
				"tag_bg": tag_bg, "ace": ace, "glow": glow, "key": "", "ribbon": ribbon, "ribbon_l": ribbon_l, "medals": medals, "medals_bg": mbg}
	_vs = UITheme.label("VS", 104, Color.WHITE, Comic.shout_font())
	_vs.position = Vector2(549, 286)
	_vs.z_index = 5           # over both duelists' panels, also the one that is lifted while you pick
	_vs.size = Vector2(100, 100)
	_vs.pivot_offset = Vector2(50, 50)
	_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs.add_theme_color_override("font_outline_color", Color(Comic.INK, 0.9))
	_vs.add_theme_constant_override("outline_size", 10)
	_vs.add_theme_color_override("font_shadow_color", Color(UITheme.ACCENT, 0.7))
	_vs.add_theme_constant_override("shadow_offset_x", 0)
	_vs.add_theme_constant_override("shadow_offset_y", 0)
	_vs.add_theme_constant_override("shadow_outline_size", 26)
	_vs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vs)


func _peek_deck() -> void:
	var deck := _deck_of("opp")
	if not CardData.has_deck(deck):
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
	# (One of your own decks carries your name, a duelist's deck theirs.)
	var mine: bool = _my_deck == "custom" or _my_deck.begins_with("slot:")
	var dp := DeckPeek.new("player" if mine else _me, _my_deck)
	dp.z_index = 200
	add_child(dp)


func _deck_of(side: String) -> String:
	if side == "opp" and _their_deck.begins_with("@"):
		return DeckTiers.with_version(str(Characters.get_char(_opp).get("deck", "")), _their_deck.substr(1))
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


## A long name ("Maximillion Pegasus") gets a smaller font instead of being cut off.
func _fit_font(l: Label, base: int) -> void:
	var f: Font = l.get_theme_font("font")
	var sz := base
	while sz > 24 and f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > l.size.x:
		sz -= 2
	l.add_theme_font_size_override("font_size", sz)


func _refresh_slots() -> void:
	for side in _slots:
		var key: String = _me if side == "me" else _opp
		var sl: Dictionary = _slots[side]
		var info := Portraits.info(key)
		var col: Color = info.get("color", UITheme.ACCENT)
		var changed: bool = sl["key"] != key
		sl["key"] = key
		if Avatars.ready_now(key) or Portraits.holds(key):
			_big_wait.erase(side)
			sl["portrait"].texture = Portraits.get_portrait(key, true)
		elif changed or sl["portrait"].texture == null:
			sl["portrait"].texture = null       # (the panel's own color shows until the model is read)
			_big_wait[side] = key
			Avatars.warm(key)
		_fit_slot(sl["portrait"], key)
		sl["name"].text = str(info.get("name", "")).to_upper()
		_fit_font(sl["name"], 46)
		sl["title"].text = Loc.t(str(info.get("title", "")))
		if side == "opp":
			# How they play, so you know what you walk into.
			var how: String = {"aggro": "Plays aggressive", "wall": "Plays defensive", "trap": "Sets traps"}.get(DuelAI.style_for(key), "")
			if how != "":
				sl["title"].text = (sl["title"].text + "   ·   " if sl["title"].text != "" else "") + Loc.t(how)
		_shrink(sl["title"], 19, 14)
		var deck_key := _deck_of(side)
		sl["sub"].text = "%s  ·  %s" % [info.get("era", ""), _deck_words(deck_key)]
		if side == "opp":
			var rec := Collection.versus(key)
			# Your record against them, and how close you are to earning their deck.
			var bits: Array = [_deck_words(deck_key)]
			if rec[0] + rec[1] > 0:
				bits.append(Loc.t("%d W  %d L") % [rec[0], rec[1]])
			if rec[0] < 3 and not Collection.decks_owned.has(str(info.get("deck", ""))):
				bits.append(Loc.t("unlocks in %d wins") % (3 - rec[0]))
			sl["sub"].text = "  ·  ".join(bits)
			# The medals you hold against them, small in the corner of their panel.
			var held: Array = Collection.medals(key)
			var mtext := ""
			for i in 3:
				mtext += "★" if held[i] else "☆"
			(sl["medals"] as Label).text = mtext
			var tips: Array = [Loc.t("Medals against %s") % str(info.get("short", key))]
			for i in 3:
				tips.append("%s %s: %s  (+%d DP)" % ["★" if held[i] else "☆", Loc.t(str(Collection.MEDALS[i]["name"])), Loc.t(str(Collection.MEDALS[i]["how"])), int(Collection.MEDALS[i]["dp"])])
			(sl["medals_bg"] as Control).tooltip_text = "\n".join(tips)
		_shrink(sl["sub"], 18, 14)
		var ace := 0
		if side == "opp":
			ace = int(Characters.get_char(key).get("ace", 0))
		if ace == 0 or CardData.get_card(ace).is_empty():
			ace = _deck_ace(deck_key)
		_card_pic(sl["ace"], ace)
		var active: bool = side == _picking
		var sb := UITheme.button_box(Color(0.042, 0.0676, 0.136, 0.0), col if active else Color(1, 1, 1, 0.16), 20)
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
	_repaint_world()


## "Red-Eyes Deck" for a deck named "Red-Eyes"; a name that already says deck stays as it is.
func _deck_words(deck_key: String) -> String:
	var nm := Loc.t(CardData.deck_name(deck_key))
	if nm.to_lower().contains("deck") or nm.to_lower().contains("mazo"):
		return nm
	return Loc.t("%s Deck") % nm


## A line that would not fit gets a smaller font (down to `low`), then is cut.
func _shrink(l: Label, base: int, low: int) -> void:
	var f: Font = l.get_theme_font("font")
	var w := l.size.x if l.size.x > 10.0 else PANEL_SIZE.x - 44.0
	var sz := base
	while sz > low and f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w:
		sz -= 1
	l.add_theme_font_size_override("font_size", sz)


# ------------------------------------------------------------------ roster

var _pick_btns := {}
var _pick_title: Label


## Who the roster is choosing for, said loudly: two big switches over the roster.
func _build_picker() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(690, 580)
	# (Its right end lines up with the roster's, whatever the language makes it measure.)
	box.resized.connect(func(): box.position.x = 1146.0 - box.size.x)
	box.add_theme_constant_override("separation", 10)
	_root.add_child(box)
	_pick_title = UITheme.label("", 20, UITheme.TEXT_DIM, UITheme.semi_font())
	_pick_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(_pick_title)
	for side in ["me", "opp"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(140, 42)
		b.focus_mode = Control.FOCUS_NONE       # (Tab / Y switches it; arrows stay in the roster)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func():
			_picking = side
			Sfx.play("card", -8.0)
			_refresh_pick())
		box.add_child(b)
		_pick_btns[side] = b


func _refresh_picker() -> void:
	if _pick_title == null:
		return
	_pick_title.text = Loc.t("You are picking:")
	for side in _pick_btns:
		var b: Button = _pick_btns[side]
		var on: bool = side == _picking
		var col: Color = Portraits.info(_me if side == "me" else _opp).get("color", UITheme.ACCENT)
		b.text = ("●  " if on else "") + (Loc.t("My duelist") if side == "me" else Loc.t("My opponent"))
		var sb := UITheme._chip_box(col if on else Color(0.09, 0.13, 0.25, 0.94))
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(fc, (Comic.INK if col.get_luminance() > 0.45 else Color.WHITE) if on else UITheme.TEXT)
		b.tooltip_text = "Choose who you play as" if side == "me" else "Choose who you duel against"
	for side in _slots:
		var pb: Control = _slots[side]["button"]
		var on2: bool = side == _picking
		# The side being chosen stands forward at full color under a ribbon that says so; the
		# other one steps back, smaller and dark.
		var want_mod := Color.WHITE if on2 else Color(0.36, 0.38, 0.46)
		var want_scale := Vector2.ONE if on2 else Vector2(0.93, 0.93)
		var tw := pb.create_tween().set_parallel(true)
		tw.tween_property(pb, "modulate", want_mod, 0.18)
		tw.tween_property(pb, "scale", want_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pb.z_index = 1 if on2 else 0
		var col2: Color = Portraits.info(_me if side == "me" else _opp).get("color", UITheme.ACCENT)
		var rb: PanelContainer = _slots[side]["ribbon"]
		rb.visible = on2
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = col2
		rsb.corner_radius_top_left = 16
		rsb.corner_radius_top_right = 16
		rsb.content_margin_top = 6
		rsb.content_margin_bottom = 6
		rb.add_theme_stylebox_override("panel", rsb)
		var rl: Label = _slots[side]["ribbon_l"]
		rl.text = "▼   " + (Loc.t("PICKING YOUR DUELIST") if side == "me" else Loc.t("PICKING YOUR OPPONENT")) + "   ▼"
		rl.add_theme_color_override("font_color", Comic.INK if col2.get_luminance() > 0.45 else Color.WHITE)
		(_slots[side]["tag_bg"] as Control).position.y = 52.0 if on2 else 16.0
		(_slots[side]["medals_bg"] as Control).position.y = 52.0 if on2 else 16.0


## Next to the title: today's set duel, and the way into the Knockout.
static var _daily := {}


func _build_extras() -> void:
	if not is_inside_tree():
		return
	if str(_daily.get("day", "")) != Time.get_date_string_from_system():
		_daily = Knockout.daily()
	var day := _daily
	if not day.is_empty():
		var done := Knockout.daily_done()
		var opp := str(Characters.get_char(str(day["opponent"])).get("short", ""))
		var tw: Dictionary = day["twist"]
		var text := Loc.t(str(day["text"]))
		if text.contains("%s"):
			text = text % str(Characters.get_char(str(day["lender"])).get("short", ""))
		var b := _extra_button(Vector2(590, 22), Vector2(372, 80), UITheme.GOLD,
				Loc.t("DUEL OF THE DAY") + ("   ✓" if done else "   +%d" % Knockout.DAILY_REWARD) + "      " + Loc.t("PLAY") + " ▶",
				"%s  ·  %s" % [Loc.t("vs %s") % opp, Loc.t(str(tw["name"]))],
				Loc.t("Won today. A new one tomorrow.") if done else text)
		b.tooltip_text = "%s\n%s" % [text, (Loc.t("Already won today: you can play it again, it pays once a day.") if done
				else Loc.t("Win it for %d Duel Points. It pays once a day, and it changes at midnight.") % Knockout.DAILY_REWARD)]
		b.pressed.connect(func():
			if _starting:
				return
			_starting = true
			Router.match_state = {}
			Sfx.play("quest", -6.0)
			start.emit((Knockout.daily()["cfg"] as Dictionary).duplicate(true)))
	# The Knockout is another screen, so its button looks like a way in: filled, with an arrow.
	var held: Dictionary = Collection.record.get("trophies", {})
	var cups := int(held.get("1", 0)) + int(held.get("2", 0)) + int(held.get("3", 0))
	var line := Loc.t("Open the bracket")
	if Knockout.running():
		line = Loc.t("%s next") % Loc.t(Knockout.round_name())
	var k := _extra_button(Vector2(970, 22), Vector2(190, 80), UITheme.ACCENT, Loc.t("KNOCKOUT") + "   ▶", line, (Loc.t("Cups: %d") % cups) if cups > 0 else Loc.t("8 duelists, 3 rounds"), true)
	k.tooltip_text = Loc.t("Another mode: eight duelists, three rounds. Lose once and you are out. Opens the bracket screen.")
	k.pressed.connect(func():
		if _starting:
			return
		Sfx.play("click")
		knockout.emit())
	# Online: duel the people in your Duel Group.
	var on_n := 0
	for p in Net.people():
		if bool(p["online"]):
			on_n += 1
	var o := _extra_button(Vector2(1176, 22), Vector2(190, 80), Color("2de2e6"), Loc.t("ONLINE") + "   ▶",
			Loc.t("Play online"), (Loc.t("%d online") % on_n) if on_n > 0 else Loc.t("With your group"), true)
	o.tooltip_text = Loc.t("Duel the people in your Duel Group, each from your own computer. Opens the Online screen.")
	o.pressed.connect(func():
		if _starting:
			return
		Sfx.play("click")
		online.emit())


func _extra_button(at: Vector2, sz: Vector2, col: Color, head: String, mid: String, foot: String, filled := false) -> Button:
	var b := Button.new()
	b.position = at
	b.size = sz
	UITheme.clip_safe(b)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus"]:
		var bg := Color(0.05, 0.08, 0.15, 0.96) if st != "hover" else Color(col.darkened(0.7), 0.98)
		if filled:
			bg = Color(col.darkened(0.5), 0.98) if st != "hover" else Color(col.darkened(0.3), 1.0)
		var sb := UITheme.button_box(bg, col if (filled or st in ["hover", "focus"]) else Color(col, 0.5), 14)
		sb.set_border_width_all(2)
		b.add_theme_stylebox_override(st, sb)
	var rows := [[head, 15, Color.WHITE if filled else col, UITheme.semi_font(), 7.0], [mid, 21, Color.WHITE, UITheme.title_font(), 25.0], [foot, 14, Color(1, 1, 1, 0.8) if filled else UITheme.TEXT_DIM, null, 54.0]]
	for r in rows:
		var l := UITheme.label(str(r[0]), int(r[1]), r[2], r[3])
		l.position = Vector2(14, float(r[4]))
		l.size = Vector2(sz.x - 24.0, 24)
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(l)
	_root.add_child(b)
	return b


func _build_tabs() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(64, 580)
	row.add_theme_constant_override("separation", 6)
	_root.add_child(row)
	var tabs := [["", "ALL"]]
	for e in Characters.ERAS:
		tabs.append([e, e.to_upper()])
	for t in tabs:
		var era: String = t[0]
		var n := 0
		for k in Characters.ORDER:
			if era == "" or str(Characters.DATA[k]["era"]) == era:
				n += 1
		if era == "":
			n += 1        # (you, the first tile)
		_tab_counts[era] = n
		# The era's name, and how many duelists it has beside it, smaller and dimmer: "GX (9)".
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = Loc.t("%d duelists") % n
		var ec: Color = UITheme.ACCENT if era == "" else StoryEmblem.era_color(era)
		b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.78), 10, Color(ec, 0.4)))
		b.add_theme_stylebox_override("hover", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.92), 10, ec.lightened(0.2)))
		var lit := UITheme.panel_box(Color(ec.darkened(0.35), 0.96), 10, ec.lightened(0.35))
		lit.set_border_width_all(2)
		for st in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, lit)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 5)
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(hb)
		var nl := UITheme.label(Loc.t(str(t[1])), 16, Color.WHITE, UITheme.title_font())
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(nl)
		var cl := UITheme.label("(%d)" % n, 13, Color(1, 1, 1, 0.55), UITheme.semi_font())
		cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(cl)
		var f1: Font = nl.get_theme_font("font")
		var f2: Font = cl.get_theme_font("font")
		b.custom_minimum_size = Vector2(f1.get_string_size(nl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
				+ f2.get_string_size(cl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 30.0, 42)
		b.pressed.connect(func():
			Sfx.play("click", -6.0)
			_era = era
			_refresh_all())
		row.add_child(b)
		_tabs.append(b)


## Q / E (LB / RB): the era before or after.
func _step_era(d: int) -> void:
	var all: Array = [""] + Characters.ERAS
	_era = str(all[posmod(all.find(_era) + d, all.size())])
	Sfx.play("click", -6.0)
	_refresh_all()
	_focus_opp.call_deferred()


var _grid_keys: Array = []


func _cell_sig(key: String) -> String:
	return "%s|%s|%s|%s" % [key == _me, key == _opp, _picking, Collection.medals(key)]


func _refresh_grid() -> void:
	# Your own duelist is always the first tile, whoever you are choosing for.
	var keys: Array = ["player"]
	for k in Characters.ORDER:
		if _era == "" or Characters.DATA[k]["era"] == _era:
			keys.append(k)
	if keys == _grid_keys and _grid.get_child_count() == keys.size():
		# Same roster: only the tiles whose badge or frame changed are swapped. A pick is instant.
		for i in keys.size():
			var cell := _grid.get_child(i)
			var sig := _cell_sig(str(keys[i]))
			if str(cell.get_meta("sig", "")) != sig:
				var fresh := _roster_card(str(keys[i]))
				fresh.set_meta("sig", sig)
				_grid.remove_child(cell)
				cell.queue_free()
				_grid.add_child(fresh)
				_grid.move_child(fresh, i)
		return
	_grid_keys = keys
	_pending.clear()
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	for key in keys:
		var card := _roster_card(key)
		card.set_meta("sig", _cell_sig(str(key)))
		_grid.add_child(card)


var _zoom_tiles: Array = []
var _zoom_t := 1.5


## Fill a roster tile with the duelist's head and shoulders. The portrait itself is framed wide
## enough for the tallest hair, which left most faces small in a tile this size; here the
## picture is scaled up so about 0.92 m shows top to bottom, with the head just above the middle.
func _fit_tile(pt: TextureRect, key: String) -> void:
	if not Avatars.has_avatar(key):
		pt.size = Vector2(CELL.x, CELL.x * 640.0 / 512.0)
		pt.position = Vector2(0, 2)
		return
	# Every duelist at the same scale (190 px to the metre) with the head at the same height,
	# so the grid reads as a line-up: faces big, level with each other, whatever the hair.
	var h := Avatars.portrait_view(key) * 190.0
	var w := h * 512.0 / 640.0
	pt.size = Vector2(w, h)
	pt.position = Vector2((CELL.x - w) / 2.0, 64.0 - h * 0.5)


## The two big pictures: head and shoulders, the same size and the same place for everybody.
func _fit_slot(pt: TextureRect, key: String) -> void:
	if not Avatars.has_avatar(key):
		pt.size = Vector2(PANEL_SIZE.x, PANEL_SIZE.x * 640.0 / 512.0)
		pt.position = Vector2(0, 6)
		return
	var h := Avatars.portrait_view(key) * PANEL_SIZE.y / 1.0
	var w := h * 512.0 / 640.0
	pt.size = Vector2(w, h)
	pt.position = Vector2((PANEL_SIZE.x - w) / 2.0, PANEL_SIZE.y * 0.47 - h * 0.5)


func _roster_card(key: String) -> Control:
	var info := Portraits.info(key)
	var has_deck := key == "player" or Characters.available(key)
	var met := Unlocks.opponent(key)
	var ok := has_deck and met
	var b := Button.new()
	b.custom_minimum_size = CELL
	UITheme.clip_safe(b)
	b.flat = true
	b.set_meta("key", key)
	b.tooltip_text = "%s\n%s" % [info.get("name", ""), Loc.t(str(info.get("title", "")))] if met else Unlocks.opponent_why(key)
	if met and key != "player":
		var held: Array = Collection.medals(key)
		for i in 3:
			b.tooltip_text += "\n%s  %s: %s" % ["★" if held[i] else "☆", Loc.t(str(Collection.MEDALS[i]["name"])), Loc.t(str(Collection.MEDALS[i]["how"]))]
	var is_me := key == _me
	var is_opp := key == _opp
	var chosen := (is_me and _picking == "me") or (is_opp and _picking == "opp")
	var col: Color = info.get("color", UITheme.ACCENT)
	for st in ["normal", "hover", "pressed", "focus"]:
		var lit: bool = chosen or st == "hover" or st == "focus"
		var sb := UITheme.button_box(Color(0.062, 0.098, 0.174, 1), col if lit else Color(1, 1, 1, 0.08), 12)
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
	pt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pt.set_meta("key", key)
	_fit_tile(pt, key)
	_zoom_tiles.append(pt)
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
	# The medals you hold against them: three pips over the name band.
	if key != "player" and met:
		var got: Array = Collection.medals(key)
		for i in 3:
			var pip := Panel.new()
			var on: bool = got[i]
			var mc: Color = Collection.MEDALS[i]["color"]
			var ps := StyleBoxFlat.new()
			ps.bg_color = mc if on else Color(0, 0, 0, 0.55)
			ps.border_color = Color(0, 0, 0, 0.85) if on else Color(1, 1, 1, 0.28)
			ps.set_border_width_all(1)
			ps.set_corner_radius_all(6)
			pip.add_theme_stylebox_override("panel", ps)
			pip.size = Vector2(11, 11)
			pip.position = Vector2(CELL.x - 16 - (2 - i) * 14, CELL.y - 28 - 15)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(pip)
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
		# Two different reasons, said as what they are. (Everybody you had not beaten yet used
		# to say "Needs the card database", with the database sitting right there.)
		var why := "Needs the\ncard database"
		if has_deck:
			why = "LOCKED\nBeat them in\nthe story" if Unlocks.STORY_MET.has(key) else "LOCKED\nBeat them in\ntheir world"
		var lock := UITheme.label(why, 13, Color(0.92, 0.94, 1.0, 0.92), UITheme.semi_font())
		lock.position = Vector2(8, 30 if not badges.is_empty() else 8)     # (under a YOU / CPU badge)
		lock.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		lock.add_theme_constant_override("outline_size", 4)
		lock.add_theme_constant_override("line_spacing", -3)
		b.add_child(lock)
	b.pressed.connect(func():
		if not ok:
			if has_deck:
				Router.toast("%s  ·  %s" % [str(info.get("short", "")), Unlocks.opponent_why(key)], 3.2)
			else:
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
		# Tapping your own duelist always puts you back in the YOU seat, with your own deck.
		_me = "player"
		_my_deck = Collection.active_deck()
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
		if _their_deck == "" or _their_deck.begins_with("@"):
			_their_deck = _default_their_deck(_opp)
	Sfx.play("card", -6.0)
	_refresh_pick()


## After a pick: just the two big slots, the tiles that changed, and what depends on who is
## dueling. Nothing is rebuilt, so the tap answers at once.
func _refresh_pick() -> void:
	_refresh_slots()
	_refresh_picker()
	_refresh_grid()
	_fill_my_decks()
	_refresh_deck_row()
	_refresh_setup()
	_refresh_versions()


## YOUR DECK: the deck of the duelist you play as (when that is not you), and your own saved
## decks. Nothing else: no list of every deck in the game.
func _fill_my_decks() -> void:
	if _deck_pick == null:
		return
	if _me != "player":
		# Playing as a duelist: one of the three versions of their own deck (the cards above).
		if _version_in(_me, _my_deck) == "":
			_my_deck = _base_of(_me)
		return
	_deck_pick.clear()
	_deck_keys.clear()
	if _me != "player":
		var own := str(Characters.get_char(_me).get("deck", ""))
		if CardData.has_deck(own):
			_deck_keys.append(own)
			_deck_pick.add_item(Loc.t("%s's own deck") % str(Characters.get_char(_me).get("short", _me)))
	# The deck you have open first (side-decking in a Match works with that one), then the others.
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
		_my_deck = _deck_keys[0]
	_deck_pick.select(maxi(0, _deck_keys.find(_my_deck)))


func _random_opponent() -> void:
	var pool := []
	for k in Characters.ORDER:
		if Characters.available(k) and Unlocks.opponent(k) and k != _opp:
			pool.append(k)
	if pool.is_empty():
		return
	_picking = "opp"
	_opp = pool[randi() % pool.size()]
	if _their_deck == "" or _their_deck.begins_with("@"):
		_their_deck = _default_their_deck(_opp)
	Sfx.play("card", -6.0)
	_refresh_pick()


# ------------------------------------------------------------------ match setup

func _section(v: VBoxContainer, text: String) -> Label:
	var l := UITheme.label(Loc.t(text), 15, UITheme.ACCENT, UITheme.semi_font())
	v.add_child(l)
	return l


## A glass card on the right: a clean section with its heading.
func _glass_card(parent: Control, head: String) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.74), 16, Color(1, 1, 1, 0.14))
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sb)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	pc.add_child(v)
	if head != "":
		var hrow := HBoxContainer.new()
		hrow.name = "Head"
		hrow.add_theme_constant_override("separation", 10)
		v.add_child(hrow)
		var hl := UITheme.label(Loc.t(head), 15, UITheme.ACCENT, UITheme.semi_font())
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hrow.add_child(hl)
	return v


func _small_button(text: String, act: Callable) -> Button:
	var b := Button.new()
	b.text = Loc.t(text)
	b.add_theme_font_size_override("font_size", 14)
	b.custom_minimum_size = Vector2(0, 30)
	for st in ["normal", "hover", "focus", "pressed"]:
		var sb := UITheme.panel_box(Color(0.06, 0.09, 0.18, 0.9) if st == "normal" else Color(0.09, 0.13, 0.25, 0.95), 10,
				Color(1, 1, 1, 0.2) if st == "normal" else UITheme.ACCENT)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(act)
	return b


func _build_setup() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(1166, 104)
	col.size = Vector2(690, 936)
	col.add_theme_constant_override("separation", 10)
	_root.add_child(col)
	_quote = UITheme.label("", 17, UITheme.TEXT)
	# The line sits to the right of the Knockout and Online buttons and wraps, so a long one never runs under them.
	_quote.position = Vector2(1384, 22)
	_quote.size = Vector2(472, 80)
	_quote.clip_text = true
	_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote.max_lines_visible = 3
	_quote.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quote.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_root.add_child(_quote)
	# Everything but the DUEL! row scrolls, should a language or a small window make it taller.
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)

	# ---- YOUR DECK: your own decks (as yourself), or the three versions of theirs (as a duelist).
	var mine := _glass_card(v, "YOUR DECK")
	(mine.get_node("Head") as HBoxContainer).add_child(_small_button("See deck", _peek_mine))
	_mine_box = VBoxContainer.new()
	_mine_box.add_theme_constant_override("separation", 6)
	mine.add_child(_mine_box)
	_deck_pick = OptionButton.new()
	_deck_pick.fit_to_longest_item = false
	_deck_pick.add_theme_font_size_override("font_size", 17)
	_deck_pick.item_selected.connect(func(i):
		if str(_deck_keys[i]) == "":
			return   # (a heading in the list)
		_my_deck = _deck_keys[i]
		_refresh_slots()
		_refresh_deck_row())
	_mine_box.add_child(_deck_pick)
	_deck_row = HBoxContainer.new()
	_deck_row.add_theme_constant_override("separation", 8)
	_deck_row.custom_minimum_size = Vector2(0, 62)
	_mine_box.add_child(_deck_row)
	_deck_note = UITheme.label("", 14, UITheme.TEXT_DIM)
	_mine_box.add_child(_deck_note)
	_my_cards = HBoxContainer.new()
	_my_cards.add_theme_constant_override("separation", 10)
	mine.add_child(_my_cards)

	# ---- THEIR DECK: three versions of it as cards, or one of your own decks.
	var theirs := _glass_card(v, "THEIR DECK")
	var th_head := theirs.get_node("Head") as HBoxContainer
	_their_other = OptionButton.new()
	_their_other.add_theme_font_size_override("font_size", 14)
	_their_other.custom_minimum_size = Vector2(190, 30)
	_their_other.fit_to_longest_item = false
	_their_other.tooltip_text = Loc.t("Or give them one of your own decks (to see how it plays from the other side).")
	_their_other_keys = [""]
	_their_other.add_item(Loc.t("Their own deck"))
	for md in Collection.my_decks():
		_their_other_keys.append(str(md["key"]))
		_their_other.add_item(Loc.t("My deck: %s") % str(md["name"]))
	_their_other.item_selected.connect(func(i):
		if i == 0:
			if not _their_deck.begins_with("@"):
				_their_deck = ""
		else:
			_their_deck = str(_their_other_keys[i])
		Sfx.play("card", -8.0)
		_refresh_slots()
		_refresh_versions())
	th_head.add_child(_their_other)
	th_head.add_child(_small_button("See deck", _peek_deck))
	_their_cards = HBoxContainer.new()
	_their_cards.add_theme_constant_override("separation", 10)
	theirs.add_child(_their_cards)

	# ---- THE FIELD: every arena as a small picture, in a row you scroll sideways.
	var fld := _glass_card(v, "FIELD")
	_field_name = UITheme.label("", 15, UITheme.TEXT, UITheme.semi_font())
	_field_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_field_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(fld.get_node("Head") as HBoxContainer).add_child(_field_name)
	_field_swatch = ColorRect.new()
	var asc := ScrollContainer.new()
	asc.custom_minimum_size = Vector2(0, 108)
	asc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fld.add_child(asc)
	var agrid := HBoxContainer.new()
	agrid.add_theme_constant_override("separation", 8)
	asc.add_child(agrid)
	for key in ["auto"] + FieldThemes.ORDER:
		agrid.add_child(_arena_tile(str(key)))

	# ---- DIFFICULTY and what a win pays.
	var dif := _glass_card(v, "DIFFICULTY")
	_reward = UITheme.label("", 15, UITheme.GOLD, UITheme.semi_font())
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	(dif.get_node("Head") as HBoxContainer).add_child(_reward)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	dif.add_child(drow)
	for i in 3:
		var db := Button.new()
		db.text = ["Easy", "Normal", "Hard"][i]
		db.toggle_mode = true
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		db.custom_minimum_size = Vector2(0, 36)
		db.add_theme_font_size_override("font_size", 18)
		_pick_style(db)
		db.pressed.connect(func():
			_difficulty = i + 1
			Settings.free_difficulty = _difficulty
			Settings.save_settings()
			_refresh_setup())
		drow.add_child(db)
		_diff_btns.append(db)
	_diff_note = UITheme.label("", 14, UITheme.TEXT_DIM)
	# Two lines are kept free so nothing jumps when the note changes.
	_diff_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_diff_note.custom_minimum_size = Vector2(0, 36)
	dif.add_child(_diff_note)

	# ---- RULES: how the duel is played, then the house rules (each button steps through its choices).
	var rul := _glass_card(v, "RULES")
	_match_btn = CheckButton.new()
	_turbo_btn = CheckButton.new()
	_fate_off_btn = CheckButton.new()
	_fate_off_btn.button_pressed = not Settings.destiny_draw
	_engine_btn = CheckButton.new()
	# (The rules engine runs every duel now; Settings has the switch back to the classic rules.)
	_engine_btn.button_pressed = true
	var groups: Array = [[_turbo_btn, "TYPE", ["Standard", "Turbo Duel"], ["A normal duel at the table.", "Both duelists ride runners. Spells need Speed Counters."]],
			[_match_btn, "LENGTH", ["1 duel", "Best of 3"], ["One duel decides it.", "First to win two duels. You can swap Side Deck cards between duels."]],
			[_fate_off_btn, "DESTINY DRAW", ["On", "Off"], ["Once per duel, at 2000 Life Points or less (or under half of your opponent's), you choose the card you draw. Hard opponents can do it too.", "Every draw is the top card, as usual."]]]
	var rules := HBoxContainer.new()
	rules.add_theme_constant_override("separation", 10)
	rul.add_child(rules)
	for grp in groups:
		var cb: CheckButton = grp[0]
		var gv := VBoxContainer.new()
		gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gv.add_theme_constant_override("separation", 2)
		rules.add_child(gv)
		gv.add_child(UITheme.label(Loc.t(str(grp[1])), 13, UITheme.TEXT_DIM, UITheme.semi_font()))
		var gh := HBoxContainer.new()
		gh.add_theme_constant_override("separation", 4)
		gv.add_child(gh)
		var pair: Array = []
		for k in 2:
			var ob := Button.new()
			ob.text = str(grp[2][k])
			ob.tooltip_text = str(grp[3][k])
			ob.toggle_mode = true
			ob.clip_text = true
			ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ob.add_theme_font_size_override("font_size", 14)
			_pick_style(ob)
			ob.button_pressed = (k == 1) == cb.button_pressed
			gh.add_child(ob)
			pair.append(ob)
		for k in 2:
			(pair[k] as Button).pressed.connect(func():
				cb.button_pressed = k == 1
				(pair[0] as Button).set_pressed_no_signal(k == 0)
				(pair[1] as Button).set_pressed_no_signal(k == 1))
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 6)
	rul.add_child(rrow)
	var lp_b := Button.new()
	var first_b := Button.new()
	var g_b := Button.new()
	var hand_b := Button.new()
	var paint := func():
		lp_b.text = Loc.t("%d Life Points") % _lp
		first_b.text = Loc.t(["Rock-paper-scissors", "I go first", "They go first"][_first + 1])
		g_b.text = Loc.t(["Single opponent", "Gauntlet: 3 in a row", "Survival: endless"][_run])
		g_b.add_theme_color_override("font_color", UITheme.GOLD if _run > 0 else UITheme.TEXT)
		hand_b.text = Loc.t("Hand of %d") % _hand_n
	for rb in [lp_b, hand_b, first_b, g_b]:
		UITheme.chip(rb)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.add_theme_font_size_override("font_size", 14)
		rb.clip_text = true
		rrow.add_child(rb)
	lp_b.tooltip_text = "Starting Life Points for both duelists."
	first_b.tooltip_text = "Who takes the first turn."
	g_b.tooltip_text = "Single opponent, a Gauntlet of three in a row, or Survival: opponents keep coming until you lose. Your Life Points carry over."
	hand_b.tooltip_text = "How many cards each duelist starts with."
	lp_b.pressed.connect(func():
		_lp = {4000: 8000, 8000: 16000, 16000: 4000}[_lp]
		paint.call())
	first_b.pressed.connect(func():
		_first = (_first + 2) % 3 - 1
		paint.call())
	hand_b.pressed.connect(func():
		_hand_n = {5: 6, 6: 7, 7: 4, 4: 5}[_hand_n]
		paint.call())
	g_b.pressed.connect(func():
		_run = (_run + 1) % 3
		_gauntlet = _run > 0
		paint.call())
	paint.call()

	# ---- the big DUEL! (and a random rival beside it), always on the floor of the column.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var rnd := Button.new()
	rnd.text = "Random rival"
	rnd.custom_minimum_size = Vector2(170, 86)
	rnd.add_theme_font_size_override("font_size", 18)
	rnd.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.04, 0.06, 0.14, 0.86), 16, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		rnd.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.08, 0.11, 0.22, 0.95), 16, UITheme.ACCENT))
	rnd.pressed.connect(_random_opponent)
	row.add_child(rnd)
	_go = Button.new()
	_go.text = "DUEL!"
	_go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_go.custom_minimum_size = Vector2(0, 86)
	_go.add_theme_font_size_override("font_size", 60)
	_go.add_theme_font_override("font", Comic.shout_font())
	_go.tooltip_text = Loc.t("Start the duel (Start on a controller)")
	UITheme.paint_button(_go, UITheme.ACCENT)
	_go.pressed.connect(_start_duel)
	row.add_child(_go)


# ------------------------------------------------------------------ deck versions

func _base_of(key: String) -> String:
	return str(Characters.get_char(key).get("deck", ""))


func _version_key_of(key: String, v: String) -> String:
	var base := _base_of(key)
	return base if v == "full" else DeckTiers.with_version(base, v)


## Which version of `key`'s own deck `deck_key` is ("" when it is not one of theirs).
func _version_in(key: String, deck_key: String) -> String:
	var base := _base_of(key)
	if base == "":
		return ""
	if deck_key == base:
		return "full"
	if deck_key.contains("@"):
		var sp: Array = DeckTiers.split(deck_key)
		if str(sp[0]) == base and str(sp[1]) in DeckTiers.versions_of(base):
			return str(sp[1])
	return ""


## The version a rival starts on: their last anime deck (the middle step), else their full deck.
## The Competitive one is a pick, not the default (Raul, 0.78.2).
func _default_their_deck(key: String) -> String:
	var vs: Array = DeckTiers.versions_of(_base_of(key))
	for v in ["anime2", "anime1"]:
		if v in vs:
			return "@" + v
	return ""


func _their_version() -> String:
	if _their_deck == "":
		return "full"
	if _their_deck.begins_with("@"):
		return _their_deck.substr(1)
	return ""


## What is in one version of a deck: its ace (or strongest monster), monsters, Spells and Traps, Extra.
func _version_facts(key: String, deck_key: String) -> Array:
	if _version_cache.has(deck_key):
		return _version_cache[deck_key]
	var main: Array = CardData.deck_list(deck_key)
	var extra: Array = CardData.extra_list(deck_key)
	var best := 0
	var best_atk := -1
	var mons := 0
	for id in main:
		if not (CardData.get_card(id).get("kind", "") in ["spell", "trap"]):
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
	var ace := int(Characters.get_char(key).get("ace", 0)) if Characters.get_char(key).get("ace", 0) is int else 0
	if ace != 0 and seen.has(ace):
		best = ace
	var out := [best, mons, main.size() - mons, extra.size()]
	_version_cache[deck_key] = out
	return out


## One version of a deck as a small card: its ace, 1-2-3 bars, the name, one plain line.
func _version_card(key: String, v: String, on: bool, col: Color, pick: Callable) -> Button:
	var dk := _version_key_of(key, v)
	var ok := CardData.has_deck(_base_of(key))
	var facts: Array = _version_facts(key, dk) if ok else [0, 0, 0, 0]
	var b := Button.new()
	b.custom_minimum_size = Vector2(206, 102)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.toggle_mode = true
	b.button_pressed = on
	UITheme.clip_safe(b)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.14)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.92), 14, col.lightened(0.15)))
	var lit := UITheme.panel_box(Color(col.darkened(0.6), 0.95), 14, col.lightened(0.3))
	lit.set_border_width_all(3)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, lit)
	var art := TextureRect.new()
	_card_pic(art, int(facts[0]))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(8, 9)
	art.size = Vector2(58, 84)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not on:
		art.modulate = Color(0.72, 0.72, 0.78)
	b.add_child(art)
	var steps := {"starter": 1, "standard": 2, "full": 3, "anime1": 1, "anime2": 2}
	var pips := HBoxContainer.new()
	pips.position = Vector2(78, 12)
	pips.add_theme_constant_override("separation", 4)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pips)
	for i in 3:
		var p := ColorRect.new()
		p.color = col.lightened(0.25) if i < int(steps[v]) else Color(1, 1, 1, 0.18)
		p.custom_minimum_size = Vector2(22, 6)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(p)
	var vn := UITheme.label(Loc.t(str(VERSION_NAME[v])).to_upper(), 17, Color.WHITE if on else Color(1, 1, 1, 0.85), UITheme.title_font())
	vn.position = Vector2(78, 22)
	vn.size = Vector2(120, 24)
	vn.clip_text = true
	vn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vn)
	# (an anime version says which part of the show: "Battle City", "Neos and the Neo-Spacians")
	var how := Loc.t(str(VERSION_HOW[v]))
	if v in DeckTiers.ANIME_VERSIONS:
		var dn := Loc.t(CardData.deck_name(DeckTiers.anime_key(_base_of(key), v)))
		how = dn.get_slice(" · ", 1) if dn.contains(" · ") else dn
	var st2 := UITheme.label(how, 13, Color(1, 1, 1, 0.92) if on else UITheme.TEXT_DIM, UITheme.semi_font())
	st2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st2.position = Vector2(78, 48)
	st2.size = Vector2(122, 60)
	st2.add_theme_constant_override("line_spacing", -3)
	st2.max_lines_visible = 3
	st2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(st2)
	var lines: Array = [Loc.t("%d monsters") % int(facts[1])]
	if int(facts[3]) > 0:
		lines.append(Loc.t("%d Extra") % int(facts[3]))
	lines.append(Loc.t("%d Spells and Traps") % int(facts[2]))
	b.tooltip_text = "%s: %s\n%s" % [Loc.t(str(VERSION_NAME[v])), Loc.t(str(VERSION_HOW[v])), "  ·  ".join(lines)]
	b.pressed.connect(func():
		Sfx.play("card", -8.0)
		pick.call(v))
	return b


## The two rows of version cards, drawn again for whoever is picked.
func _refresh_versions() -> void:
	if _their_cards == null:
		return
	var focus_owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var refocus := ""
	if focus_owner != null and (_their_cards.is_ancestor_of(focus_owner) or _my_cards.is_ancestor_of(focus_owner)):
		refocus = "their" if _their_cards.is_ancestor_of(focus_owner) else "mine"
	for row in [_their_cards, _my_cards]:
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()
	var ocol: Color = Portraits.info(_opp).get("color", UITheme.DANGER)
	var tv := _their_version()
	if not tv in DeckTiers.versions_of(_base_of(_opp)) and _their_deck.begins_with("@"):
		_their_deck = ""
		tv = "full"
	for v in DeckTiers.versions_of(_base_of(_opp)):
		_their_cards.add_child(_version_card(_opp, str(v), str(v) == tv, ocol, func(pv: String):
			_their_deck = "" if pv == "full" else "@" + pv
			_their_other.select(0)
			_refresh_slots()
			_refresh_versions()))
	_their_other.select(maxi(0, _their_other_keys.find(_their_deck)) if not _their_deck.begins_with("@") else 0)
	# As yourself: your own decks. As a duelist: the three versions of their deck.
	var as_char := _me != "player"
	_mine_box.visible = not as_char
	_my_cards.visible = as_char
	if as_char:
		var mcol: Color = Portraits.info(_me).get("color", UITheme.ACCENT)
		var mv := _version_in(_me, _my_deck)
		for v in DeckTiers.versions_of(_base_of(_me)):
			_my_cards.add_child(_version_card(_me, str(v), str(v) == mv, mcol, func(pv: String):
				_my_deck = _version_key_of(_me, pv)
				_refresh_slots()
				_refresh_versions()))
	if refocus != "":
		var row2: HBoxContainer = _their_cards if refocus == "their" else _my_cards
		for c in row2.get_children():
			if (c as Button).button_pressed:
				(c as Button).grab_focus.call_deferred()


## A choice button: the picked one is filled bright so it is obvious which is on.
func _pick_style(b: Button) -> void:
	var on := UITheme.button_box(UITheme.ACCENT, UITheme.ACCENT, 8)
	on.content_margin_left = 8
	on.content_margin_right = 8
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, on)
	for c in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Color(0.02, 0.05, 0.08))


## The arena picker: a real picture of each place (made by tools/arena_shots), its name under
## it. "Auto" shows whichever place the opponent calls home.
var _arena_tiles := {}           # key -> [Button, TextureRect]
static var _arena_pics := {}


static func arena_picture(key: String) -> Texture2D:
	if not _arena_pics.has(key):
		var path := "res://assets/arenas/%s.jpg" % key
		_arena_pics[key] = load(path) if ResourceLoader.exists(path) else null
	return _arena_pics[key]


## The same, read on another thread: null until it is in (the tile asks again each frame).
static func arena_picture_later(key: String) -> Texture2D:
	if _arena_pics.has(key):
		return _arena_pics[key]
	var path := "res://assets/arenas/%s.jpg" % key
	if not ResourceLoader.exists(path):
		_arena_pics[key] = null
		return null
	var tex := UiPictures.full(path)
	if tex != null:
		_arena_pics[key] = tex
	return tex


## A card's picture on a TextureRect, read on another thread (a small copy: these are all small).
func _card_pic(tr: TextureRect, id: int) -> void:
	tr.set_meta("card", id)
	if id == 0:
		tr.texture = null
		return
	Cards.thumb_later(id, func(t: Texture2D):
		if is_instance_valid(tr) and int(tr.get_meta("card", 0)) == id:
			tr.texture = t)


var _arena_wait := {}      # arena tile key -> the picture it waits for


func _arena_tile(key: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 98)
	b.toggle_mode = true
	UITheme.clip_safe(b)
	b.add_theme_stylebox_override("normal", UITheme.button_box(Color(0.05, 0.075, 0.16, 0.9), Color(1, 1, 1, 0.14), 8))
	b.add_theme_stylebox_override("hover", UITheme.button_box(Color(0.09, 0.13, 0.25, 0.95), Color(UITheme.ACCENT, 0.9), 8))
	var on := UITheme.button_box(Color(0.09, 0.13, 0.25, 0.95), UITheme.ACCENT, 8)
	on.set_border_width_all(3)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	UITheme.clip_safe(pic)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	pic.position = Vector2(4, 4)
	pic.size = Vector2(142, 70)
	if key == "auto":
		var tag := UITheme.label("AUTO", 13, Color(0.06, 0.07, 0.12), UITheme.semi_font())
		var tb := StyleBoxFlat.new()
		tb.bg_color = UITheme.ACCENT
		tb.set_corner_radius_all(4)
		tb.content_margin_left = 7
		tb.content_margin_right = 7
		tb.content_margin_top = 1
		tb.content_margin_bottom = 1
		tag.add_theme_stylebox_override("normal", tb)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tag)
		tag.position = Vector2(8, 8)
	var l := UITheme.label("", 13, UITheme.TEXT, UITheme.semi_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	l.position = Vector2(4, 76)
	l.size = Vector2(142, 20)
	l.name = "Name"
	b.pressed.connect(func():
		_field = key
		Sfx.play("card", -10.0)
		_refresh_setup())
	_arena_tiles[key] = [b, pic]
	return b


func _paint_arena(key: String) -> void:
	var th := FieldThemes.resolve(key, _opp)
	var apic := arena_picture_later(str(th["key"]))
	(_arena_tiles[key][1] as TextureRect).texture = apic
	if apic == null and ResourceLoader.exists("res://assets/arenas/%s.jpg" % str(th["key"])):
		_arena_wait[key] = str(th["key"])
	else:
		_arena_wait.erase(key)
	var b: Button = _arena_tiles[key][0]
	(b.get_node("Name") as Label).text = Loc.t(str(th["name"]))
	b.tooltip_text = (Loc.t("The opponent's home field") + ":  " if key == "auto" else "") + Loc.t(str(th["name"])) + "\n" + Loc.t(str(th.get("blurb", "")))
	b.set_pressed_no_signal(key == _field)


func _step_field(dir: int) -> void:
	var opts: Array = ["auto"] + FieldThemes.ORDER
	_field = opts[posmod(opts.find(_field) + dir, opts.size())]
	Sfx.play("card", -10.0)
	_refresh_setup()


## The five cards that best show what a deck is about: its biggest monsters.
var _row_for := ""   # the deck the row of thumbnails was last drawn for


func _refresh_deck_row() -> void:
	# Picking an opponent redraws the screen: your deck's row only moves when your deck changed.
	var row_key := str(_my_deck) + "|" + str(str(CardData.deck_list(_my_deck)).hash()) + "|" + str(str(CardData.extra_list(_my_deck)).hash())
	if row_key == _row_for and _deck_row.get_child_count() > 0:
		return
	_row_for = row_key
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
		_card_pic(tr, id)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(42, 62)
		tr.tooltip_text = Loc.t("%s\nATK %d") % [CardData.get_card(id).get("name", ""), mons[i][0]]
		tr.modulate.a = 0.0
		_deck_row.add_child(tr)
		create_tween().tween_property(tr, "modulate:a", 1.0, 0.2).set_delay(i * 0.04)
	_deck_note.text = Loc.t("%d cards  ·  %d monsters  ·  %d Spells and Traps  ·  %d in the Extra Deck") % [
			all.size(), all.size() - others, others, CardData.extra_list(_my_deck).size()]


func _refresh_setup() -> void:
	for i in _diff_btns.size():
		_diff_btns[i].set_pressed_no_signal(i + 1 == maxi(1, _difficulty))
	var new_engine: bool = _engine_btn != null and _engine_btn.button_pressed
	for i in _diff_btns.size():
		_diff_btns[i].text = Loc.t(Settings.LEVEL_NAMES[i])
	if new_engine:
		_diff_note.text = Loc.t(["", "Plays well but simply: no long combos, and it does not play around your face-down cards.",
				"Looks further ahead, keeps its Traps for the right moment and plays around yours. Tuned deck.",
				"The strongest: it tries the most plays, looks the furthest and always hunts for the win. Tuned deck. It never looks at your hand or face-down cards."][_difficulty])
	else:
		_diff_note.text = ["Plays sensibly and attacks when it can.", "Plays sensibly and attacks when it can.",
				"Thinks ahead, brings a tuned deck and starts with one extra card.",
				"Plans two plays ahead and sees your counterattack coming. Tuned deck, one extra card."][_difficulty]
	var th := FieldThemes.resolve(_field, _opp)
	_field_name.text = (Loc.t("Auto  ·  %s") % Loc.t(str(th["name"]))) if _field == "auto" else Loc.t(str(th["name"]))
	_repaint_world()
	for ak in _arena_tiles:
		_paint_arena(str(ak))
	var o := Characters.get_char(_opp)
	var said := Characters.line(_opp, "intro")
	_quote.text = "%s:  \"%s\"" % [str(o.get("short", "")).to_upper(), said] if said != "" else ""
	_reward.text = Loc.t("Win +%d Duel Points  ·  Lose +40") % (120 + 60 * _difficulty)
	if _medal_line:
		var held: Array = Collection.medals(_opp)
		var parts: Array = []
		for i in 3:
			parts.append(("★ " if held[i] else "☆ ") + Loc.t(str(Collection.MEDALS[i]["name"])))
		_medal_line.text = Loc.t("Medals against %s:   %s") % [str(o.get("short", _opp)), "     ".join(parts)]
		_medal_line.tooltip_text = "\n".join(Collection.MEDALS.map(func(m): return "%s: %s  (+%d)" % [Loc.t(str(m["name"])), Loc.t(str(m["how"])), int(m["dp"])]))


func _refresh_all() -> void:
	_refresh_slots()
	_refresh_picker()
	_refresh_grid()
	for i in _tabs.size():
		var era: String = "" if i == 0 else Characters.ERAS[i - 1]
		_tabs[i].set_pressed_no_signal(era == _era)
	_fill_my_decks()
	_refresh_deck_row()
	_refresh_setup()
	_refresh_versions()


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
		"turbo": _turbo_btn != null and _turbo_btn.button_pressed, "lp": _lp, "hand": _hand_n,
		"destiny": not (_fate_off_btn != null and _fate_off_btn.button_pressed),
		"cpu_level": _difficulty}
	if _their_deck == "":
		cfg["opponent_version"] = "full"          # (so coming back keeps Competitive picked)
	if _their_deck.begins_with("@"):
		cfg["opponent_deck"] = _deck_of("opp")    # one of the smaller versions of their own deck
	elif _their_deck != "":
		cfg["opponent_deck"] = _their_deck
		cfg["opponent_deck_full"] = true   # a deck you picked for them is the real one, aces included
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
	for n in get_children():
		if n is DeckPeek:
			return        # (the deck on show takes the keys until it closes)
	if _starting:
		return
	var key: InputEventKey = event as InputEventKey
	var pad: InputEventJoypadButton = event as InputEventJoypadButton
	if (key and key.pressed and not key.echo and key.keycode in [KEY_Q, KEY_E]) \
			or (pad and pad.pressed and Pad.b(pad) in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		get_viewport().set_input_as_handled()
		_step_era(-1 if (key and key.keycode == KEY_Q) or (pad and Pad.b(pad) == JOY_BUTTON_LEFT_SHOULDER) else 1)
		return
	# Tab / Y: choose for the other side.
	if (key and key.pressed and not key.echo and key.keycode == KEY_TAB and not key.shift_pressed) \
			or (pad and pad.pressed and Pad.b(pad) == JOY_BUTTON_Y):
		get_viewport().set_input_as_handled()
		_picking = "me" if _picking == "opp" else "opp"
		Sfx.play("card", -8.0)
		_refresh_pick()
		_focus_opp.call_deferred()
		return
	# Start (or F on the keyboard): the duel.
	if (pad and pad.pressed and Pad.b(pad) == JOY_BUTTON_START) or (key and key.pressed and not key.echo and key.keycode == KEY_F):
		get_viewport().set_input_as_handled()
		_start_duel()
		return
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
