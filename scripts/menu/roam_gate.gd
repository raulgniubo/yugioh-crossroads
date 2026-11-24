class_name RoamGate
extends Control
## The door to Free Roam, in the look of the Academy's and the main story's doors: the world you
## have picked fills the screen, its name and era down the left, and a card with what is going on
## there right now (the hour and the weather, today's duels, who is out and what they are doing,
## the favors people asked you for, the shops and street duelists). A big Go button, and down the
## right side every world as a tile with its own picture, locked ones saying how they open.
## Everything the old Free Roam panel did is here: the worlds, the night highway, the locks.

signal closed

const ORDER := ["domino", "academy", "satellite", "newdomino", "heartland", "highway"]
const HIGHWAY_PICTURE := "res://assets/ui/roam_title_highway.jpg"
const _RIDE := preload("res://scripts/turbo/turbo_ride.gd")   # (the night highway: its races and save)

var _back: AcademyBackdrop
var _left: VBoxContainer
var _tiles: VBoxContainer
var _pick := "domino"
var _last := ""                    # the world your game was in last
var _tile_of := {}                 # world -> its tile
var _go: Button
var _built := false


## The picture of a world: the ones the story's door uses, and the night highway's own.
static func picture_of(key: String) -> String:
	if key == "highway":
		return HIGHWAY_PICTURE if ResourceLoader.exists(HIGHWAY_PICTURE) else StoryGate.picture_of("newdomino")
	return StoryGate.picture_of(key)


static func world_row(key: String) -> Array:
	for w in RoamData.WORLDS:
		if str(w[0]) == key:
			return w
	return [key, "5D's  ·  Turbo Duels", "Ride your runner down the night highway and duel at full speed.", Color("ff8a3a")]


static func world_name(key: String) -> String:
	if key == "highway":
		return Loc.t("New Domino Highway")
	return Loc.t(str(RoamData.district(key).get("name", key)))


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	WorldClock.load_data()
	var pl := Saves.place()
	if str(pl.get("mode", "")) == "roam" and ORDER.has(str(pl.get("district", ""))):
		_last = str(pl["district"])
	# Open on the world you were in last, or the first one that is open.
	_pick = _last if _last != "" and Unlocks.world(_last) else "domino"
	_back = AcademyBackdrop.new(0.0, picture_of(_pick), Color(0.85, 0.92, 1.0))
	add_child(_back)
	var lm := MarginContainer.new()
	lm.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	lm.add_theme_constant_override("margin_left", 96)
	lm.add_theme_constant_override("margin_top", 56)
	lm.add_theme_constant_override("margin_bottom", 44)
	add_child(lm)
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 12)
	_left.custom_minimum_size = Vector2(820, 0)
	_left.alignment = BoxContainer.ALIGNMENT_CENTER
	lm.add_child(_left)
	# The worlds, down the right edge.
	var rm := MarginContainer.new()
	rm.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	rm.offset_left = -440
	rm.add_theme_constant_override("margin_right", 64)
	rm.add_theme_constant_override("margin_top", 56)
	rm.add_theme_constant_override("margin_bottom", 44)
	add_child(rm)
	var rv := VBoxContainer.new()
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 10)
	rm.add_child(rv)
	var head := UITheme.label(Loc.t("THE WORLDS"), 18, UITheme.GOLD, UITheme.semi_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(head)
	_tiles = VBoxContainer.new()
	_tiles.add_theme_constant_override("separation", 10)
	rv.add_child(_tiles)
	for key in ORDER:
		_tiles.add_child(_tile(key))
	_built = true
	_show(_pick, false)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


## A world as a small glass tile with its own picture on it.
func _tile(key: String) -> Button:
	var w := world_row(key)
	var col: Color = w[3]
	var open := Unlocks.world(key)
	var b := Button.new()
	b.custom_minimum_size = Vector2(376, 104)
	b.focus_mode = Control.FOCUS_ALL
	UITheme.clip_safe(b)
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.8), 16, Color(col, 0.35)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.06, 0.09, 0.18, 0.92), 16, col.lightened(0.2)))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.08, 0.12, 0.24, 0.95), 16, col.lightened(0.4)))
	var pic := TextureRect.new()
	var path := picture_of(key)
	pic.texture = UiPictures.thumb(path)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.position = Vector2(4, 4)
	pic.size = Vector2(150, 96)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.modulate = Color(1, 1, 1, 1.0 if open else 0.35)
	# (Rounded like the card around it: the square corners used to poke out of the curve.)
	b.add_child(UiPictures.rounded(pic, 12))
	var stripe := ColorRect.new()
	stripe.color = col if open else Color(col, 0.35)
	stripe.position = Vector2(154, 12)
	stripe.size = Vector2(4, 80)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(stripe)
	var v := VBoxContainer.new()
	v.position = Vector2(170, 10)
	v.size = Vector2(196, 86)
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var nm := UITheme.label(world_name(key).to_upper(), 21 if world_name(key).length() <= 18 else 18, Color(1, 1, 1, 1.0 if open else 0.5), UITheme.title_font())
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(196, 0)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var tag := str(w[1])
	if not open:
		tag = "🔒 " + Loc.t("LOCKED")
	elif key == _last:
		tag = "● " + Loc.t("You were here last")
	var era := UITheme.label(tag, 15, (col.lightened(0.35) if open else UITheme.GOLD), UITheme.semi_font())
	era.mouse_filter = Control.MOUSE_FILTER_IGNORE
	era.clip_text = true
	era.custom_minimum_size = Vector2(196, 0)
	v.add_child(era)
	b.focus_entered.connect(func(): _show(key))
	b.mouse_entered.connect(func(): b.grab_focus())
	b.pressed.connect(func():
		if _pick != key:
			_show(key)
		elif open:
			_enter(key))
	_tile_of[key] = b
	return b


## Show a world: its picture behind everything and its page on the left.
func _show(key: String, fade := true) -> void:
	var was := _pick
	_pick = key
	if fade and was != key:
		Sfx.play("card", -14.0)
		_back.fade_to(picture_of(key))
	elif not fade:
		_back.show_picture(picture_of(key))
	_page()


func _clear() -> void:
	for n in _left.get_children():
		n.queue_free()


func _page() -> void:
	_clear()
	var key := _pick
	var w := world_row(key)
	var col: Color = w[3]
	var open := Unlocks.world(key)
	_left.add_child(UITheme.label(Loc.t("FREE ROAM"), 19, UITheme.GOLD, UITheme.semi_font()))
	var t := UITheme.label(world_name(key).to_upper(), 92 if world_name(key).length() <= 16 else 74, Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 5)
	t.add_theme_constant_override("shadow_outline_size", 10)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(820, 0)
	_left.add_child(t)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	var seg := ColorRect.new()
	seg.color = col
	seg.custom_minimum_size = Vector2(120, 8)
	seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(seg)
	bar.add_child(UITheme.label(str(w[1]), 21, col.lightened(0.4), UITheme.semi_font()))
	_left.add_child(bar)
	var sub := UITheme.label(Loc.t(str(w[2])), 23, Color(0.9, 0.93, 1.0, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(800, 0)
	_left.add_child(sub)
	var gap0 := Control.new()
	gap0.custom_minimum_size = Vector2(0, 6)
	_left.add_child(gap0)
	_left.add_child(_now_card(key, col, open))
	_go = Button.new()
	if open:
		_go.text = "▶   " + (Loc.t("Ride out") if key == "highway" else Loc.t("Go to %s") % world_name(key))
		_go.pressed.connect(func(): _enter(key))
		UITheme.paint_button(_go, col.darkened(0.3))
	else:
		_go.text = "🔒   " + Loc.t("Locked")
		_go.disabled = true
		UITheme.paint_button(_go, Color(0.2, 0.22, 0.3))
	_go.custom_minimum_size = Vector2(820, 92)
	_go.add_theme_font_size_override("font_size", 36)
	_go.clip_text = true
	_left.add_child(_go)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(820, 0)
	_left.add_child(row)
	var back := Button.new()
	back.text = Loc.t("Back")
	back.custom_minimum_size = Vector2(220, 60)
	back.add_theme_font_size_override("font_size", 23)
	back.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		back.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 14, col.lightened(0.25)))
	back.pressed.connect(func():
		Sfx.play("click", -6.0)
		_close())
	row.add_child(back)
	var hint := UITheme.label(Loc.t("Inside, press G any time to jump to another world."), 19, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hint)
	# The focus stays where it was when you browse the tiles; the first time, on Go.
	if not _focus_in_tiles():
		(_go if open else (_tile_of[key] as Control)).grab_focus.call_deferred()
	var k := 0
	for n in _left.get_children():
		var c := n as Control
		c.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.035 * k)
		tw.tween_property(c, "modulate:a", 1.0, 0.2)
		k += 1


func _focus_in_tiles() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and _tiles.is_ancestor_of(f)


## What is going on in a world right now.
func _now_card(key: String, col: Color, open: bool) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.84), 20, Color(col, 0.7)))
	card.custom_minimum_size = Vector2(820, 0)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 26)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 18)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	# The hour and the sky.
	var sky := Loc.t(WorldClock.part())
	if key != "highway" and WorldClock.rains(key):
		sky += "  ·  " + (Loc.t("Dust storm") if key == "satellite" else Loc.t("Raining"))
	var top := UITheme.label("%s   %s   ·   %s   ·   %s" % [_sky_icon(key), StarMeets.hour_text(WorldClock.minutes), sky, Loc.t("Day %d") % WorldClock.day], 25, Color.WHITE, UITheme.semi_font())
	v.add_child(top)
	if not open:
		var why := UITheme.label(Unlocks.world_why(key), 22, UITheme.GOLD)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(760, 0)
		v.add_child(why)
		return card
	if key == "highway":
		_highway_lines(v, col)
		return card
	# Today's duels.
	var duels := StarMeets.today(key, WorldClock.day)
	if not duels.is_empty():
		v.add_child(_head(Loc.t("Today's duels"), col))
		for d in duels:
			var at := int(d["at"])
			var when := ""
			if WorldClock.minutes < at:
				var left := at - int(WorldClock.minutes)
				when = Loc.t("in %d min") % left if left < 60 else Loc.t("in %d h") % int(round(left / 60.0))
			elif WorldClock.minutes < at + StarMeets.WINDOW:
				when = Loc.t("on right now")
			else:
				when = Loc.t("already played")
			v.add_child(_line("%s   %s  ·  %s" % [StarMeets.hour_text(at), Loc.t("%s vs %s") % [_short(str(d["a"])), _short(str(d["b"]))], when],
					UITheme.GOLD if when == Loc.t("on right now") else Color(1, 1, 1, 0.92)))
	# Who is out, and what they are doing.
	var who := _who_now(key)
	if not who.is_empty():
		v.add_child(_head(Loc.t("Out and about right now"), col))
		for i in mini(who.size(), 4):
			v.add_child(_line(str(who[i]), Color(1, 1, 1, 0.92)))
		if who.size() > 4:
			v.add_child(_line(Loc.t("...and %d more") % (who.size() - 4), UITheme.TEXT_DIM))
	# Favors.
	var fav := _favors(key)
	var facts: Array = []
	if fav[0] > 0:
		facts.append(Loc.t("%d favors under way") % fav[0])
	if fav[1] > 0:
		facts.append(Loc.t("%d people may need a hand") % fav[1])
	if fav[2] > 0 and fav[0] == 0 and fav[1] == 0:
		facts.append(Loc.t("Every favor done"))
	# Shops and the people who duel in the street.
	var d := RoamData.district(key)
	var shops := 0
	var duelists := 0
	for n in d.get("npcs", []):
		var nd := n as Dictionary
		if nd.get("shop", false):
			shops += 1
		elif nd.has("duel"):
			duelists += 1
	shops += (d.get("shop_npcs", []) as Array).size()
	if shops > 0:
		facts.append(Loc.t("%d shops") % shops)
	if duelists > 0:
		facts.append(Loc.t("%d street duelists") % duelists)
	if not facts.is_empty():
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 2)
		v.add_child(gap)
		var fl := UITheme.label("   ·   ".join(facts), 19, UITheme.TEXT_DIM)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl.custom_minimum_size = Vector2(760, 0)
		v.add_child(fl)
	return card


func _sky_icon(key: String) -> String:
	if key != "highway" and WorldClock.rains(key):
		return "☂" if key != "satellite" else "≋"
	var look := WorldClock.look()
	return {"night": "☾", "dawn": "◐", "sunset": "◑"}.get(look, "☀")


func _head(text: String, col: Color) -> Control:
	var l := UITheme.label(text.to_upper(), 16, col.lightened(0.35), UITheme.semi_font())
	var box := MarginContainer.new()
	box.add_theme_constant_override("margin_top", 6)
	box.add_child(l)
	return box


func _line(text: String, color: Color) -> Label:
	var l := UITheme.label(text, 21, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(760, 0)
	return l


func _short(id: String) -> String:
	var c := Characters.get_char(id)
	return Loc.t(str(c.get("short", id.capitalize())))


## The main characters of a world where their day has them now, and anybody who only comes out at
## this hour (the dawn runners, the night collectors).
func _who_now(key: String) -> Array:
	var out: Array = []
	var d := RoamData.district(key)
	var days: Dictionary = StarLife.DAYS.get(key, {})
	for id in days:
		var stops := StarMeets.day_with(key, str(id), days[id], WorldClock.day)
		var st: Array = stops[StarLife._stop_now(stops)]
		var doing := Loc.t(str(StarLife.DOING_TEXT.get(str(st[3]), "Hanging out")))
		if str(st[3]) == "duel":
			for mt in StarMeets.today(key, WorldClock.day):
				if int(mt["at"]) == int(st[0]):
					doing = Loc.t("Dueling %s") % _short(str(mt["b"]) if str(mt["a"]) == str(id) else str(mt["a"]))
		var place := StarMeets.place_near(d, st[1])
		var txt := "%s  ·  %s" % [_short(str(id)), doing]
		if place != "":
			txt += "  ·  " + Loc.t(place)
		out.append(txt)
	var h := WorldClock.minutes / 60.0
	for n in d.get("npcs", []):
		var nd := n as Dictionary
		var here := false
		if nd.has("hours"):
			var hh: Array = nd["hours"]
			here = h >= float(hh[0]) and h < float(hh[1])
		elif nd.get("night", false):
			here = h >= 21.0 or h < 5.0
		if here:
			out.append("%s  ·  %s" % [Loc.t(str(nd.get("name", ""))), Loc.t("only at this hour")])
	return out


## [under way, not asked yet, done] for the favors of a world.
func _favors(key: String) -> Array:
	var cfg := ConfigFile.new()
	var st: Dictionary = {}
	if cfg.load(RoamExtras.SAVE) == OK:
		st = cfg.get_value("x", "errands", {})
	var out := [0, 0, 0]
	var seen_givers := {}
	for e in WorldLife.ERRANDS.get(key, []):
		var s := int(st.get(e["id"], 0))
		if s == 1 or s == 2:
			out[0] += 1
		elif s >= 3:
			out[2] += 1
		elif not seen_givers.has(str(e["giver"])):
			# (A chain of favors from one person counts once: they ask for the next when the last is done.)
			out[1] += 1
		seen_givers[str(e["giver"])] = true
	return out


func _highway_lines(v: VBoxContainer, col: Color) -> void:
	v.add_child(_head(Loc.t("Races at the start line"), col))
	var names: Array = []
	for id in _RIDE.EVENT_ORDER:
		names.append(Loc.t(str(_RIDE.EVENTS[id]["name"])))
	v.add_child(_line("  ·  ".join(names), Color(1, 1, 1, 0.92)))
	var cfg := ConfigFile.new()
	var facts: Array = []
	if cfg.load(_RIDE.SAVE) == OK:
		var best := float(cfg.get_value("turbo", "best", 0.0))
		if best > 0.0:
			facts.append(Loc.t("Your best lap: %.1f s") % best)
		var wins := 0
		var ev: Dictionary = cfg.get_value("turbo", "events_best", {})
		for k in ev:
			if int(ev[k]) == 1:
				wins += 1
		if wins > 0:
			facts.append(Loc.t("%d races won") % wins)
	if facts.is_empty():
		facts.append(Loc.t("No laps on the clock yet."))
	v.add_child(_line("   ·   ".join(facts), UITheme.TEXT_DIM))
	v.add_child(_line(Loc.t("Riders on the ring will duel you at full speed. Your garage is at the start line."), UITheme.TEXT_DIM))


## Into the world, exactly as the old Free Roam panel did it.
func _enter(key: String) -> void:
	if not Unlocks.world(key):
		return
	Sfx.play("gong", -8.0)
	if key == "highway":
		Router.go(Router.RIDE)
		return
	Router.roam["district"] = key
	Router.roam["free"] = true       # Free Roam is free: no chapter list, no story leads
	Router.roam["pos"] = null
	Router.roam.erase("yaw")
	Router.roam.erase("tod")
	Router.go(Router.ROAM)


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
