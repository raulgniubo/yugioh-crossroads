class_name StoryGate
extends Control
## The door to the main story (0.69.0), in the same look as the Academy's: Domino City at night
## behind it, the story's title down the left, a card with where your game is (the chapter, the
## era, the place, how far along), Continue, and a row with Chapters / Load a save / New game /
## Back. Everything the old Story panel did is here: continue, any open chapter from its first
## scene, the bond scenes, the difficulty, load, and a new game.

signal closed

## One picture per world the story visits, all taken in the game itself at the same hour.
const WORLDS := ["domino", "academy", "newdomino", "satellite", "heartland", "museum"]
const PICTURE := "res://assets/ui/story_title_domino.jpg"


static func picture_of(district: String) -> String:
	var p := "res://assets/ui/story_title_%s.jpg" % district
	if district == "academy" and not ResourceLoader.exists(p):
		p = AcademyBackdrop.PICTURE          # the island at the same hour: the Academy door's own picture
	return p if ResourceLoader.exists(p) else PICTURE


## Every world's picture, for the crossfade (no game yet, and the Load screen).
static func all_pictures() -> Array:
	var out: Array = []
	for d in WORLDS:
		var p := picture_of(d)
		if ResourceLoader.exists(p) and not out.has(p):
			out.append(p)
	return out


## The world a chapter is in at a step: the last scene at or before it (its first scene for step 0).
static func district_of(chapter: String, step := 0) -> String:
	var steps: Array = StoryData.SCRIPTS.get(chapter, [])
	var d := ""
	for i in steps.size():
		var st: Dictionary = steps[i]
		if st.has("scene") and st["scene"] is Dictionary and (st["scene"] as Dictionary).has("district"):
			if d == "" or i <= step:
				d = str(st["scene"]["district"])
		if i > step and d != "":
			break
	return d if d != "" else "domino"


## The world's color, as on the travel screen.
static func world_color(district: String) -> Color:
	for w in RoamData.WORLDS:
		if str(w[0]) == district:
			return w[3]
	return Color("7fe8ff")


## The world a save is in: the district it was in, or the world of the chapter it stopped in.
static func world_of_save(sw: Dictionary) -> String:
	var mode := str(sw.get("mode", ""))
	if mode == "roam" and str(sw.get("district", "")) != "":
		return str(sw["district"])
	if mode == "story" and StoryData.SCRIPTS.has(str(sw.get("chapter", ""))):
		return district_of(str(sw["chapter"]))
	for c in StoryData.CHAPTERS:
		if str(c["title"]) == str(sw.get("where", "")):
			return district_of(str(c["id"]))
	return ""


## The world's name as the travel screen says it ("Domino City").
static func world_name(district: String) -> String:
	return Loc.t(str(RoamData.district(district).get("name", district)))

var _box: VBoxContainer          # a page in the middle of the screen (chapters, a question)
var _left: VBoxContainer         # the title page, down the left side over the picture
var _mid: CenterContainer
var _back: AcademyBackdrop
var _scroll: ScrollContainer


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_back = AcademyBackdrop.new(0.0, PICTURE, Color(0.72, 0.9, 1.0))
	_pick_picture()
	add_child(_back)
	var lm := MarginContainer.new()
	lm.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	lm.add_theme_constant_override("margin_left", 96)
	lm.add_theme_constant_override("margin_top", 64)
	lm.add_theme_constant_override("margin_bottom", 48)
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
	_box.add_theme_constant_override("separation", 14)
	_box.custom_minimum_size = Vector2(1100, 0)
	_scroll.add_child(_box)
	_home()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


## The picture behind the door: the world the game in this save is in, or, with no game yet, all
## of them in turn.
func _pick_picture() -> void:
	var pos := StoryProgress.position()
	var ch := str(pos.get("chapter", ""))
	if ch != "" and StoryData.SCRIPTS.has(ch):
		_back.show_picture(picture_of(district_of(ch, int(pos.get("step", 0)))))
	elif StoryProgress.unlocked().size() <= 1 and not StoryProgress.recalls("finished"):
		_back.cycle(all_pictures())
	else:
		_back.show_picture(picture_of(district_of(str(_current()[0]["id"]))))


func _process(_d: float) -> void:
	# The middle page never runs past the screen: it scrolls when it is taller than the view.
	var room := get_viewport_rect().size.y - 80.0
	var want := _box.get_combined_minimum_size().y
	_scroll.custom_minimum_size = Vector2(_box.custom_minimum_size.x, minf(want, room))


func _clear() -> void:
	for n in _box.get_children():
		n.queue_free()
	for n in _left.get_children():
		n.queue_free()


## Where the story is: [chapter dictionary, index] of the chapter you are in, or the newest open one.
func _current() -> Array:
	var pos := StoryProgress.position()
	var open := StoryProgress.unlocked()
	var newest := 0
	for i in StoryData.CHAPTERS.size():
		var c: Dictionary = StoryData.CHAPTERS[i]
		if str(c["id"]) == str(pos.get("chapter", "")):
			return [c, i]
		if open.has(c["id"]) and StoryData.SCRIPTS.has(c["id"]):
			newest = i
	return [StoryData.CHAPTERS[newest], newest]


func _played() -> int:
	var open := StoryProgress.unlocked()
	var n := 0
	for c in StoryData.CHAPTERS:
		if open.has(c["id"]) and StoryData.SCRIPTS.has(c["id"]):
			n += 1
	return maxi(n, 1)


## A short word for a chapter's mark: "P" for the prologue, "F" for the final chapter, else its number.
static func mark_of(i: int) -> String:
	if i <= 0:
		return "P"
	if i >= StoryData.CHAPTERS.size() - 1:
		return "F"
	return str(i)


## The six chapters as one bar, each in its era's color: the one you are on lit and taller.
func _era_bar(at: int) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var open := StoryProgress.unlocked()
	for i in StoryData.CHAPTERS.size():
		var c: Dictionary = StoryData.CHAPTERS[i]
		var col := StoryEmblem.era_color(str(c["era"]))
		var seg := ColorRect.new()
		var on := i == at
		seg.color = col if on else Color(col, 0.55 if open.has(c["id"]) else 0.2)
		seg.custom_minimum_size = Vector2(120 if on else 78, 8 if on else 5)
		seg.size_flags_vertical = Control.SIZE_SHRINK_END
		h.add_child(seg)
	return h


## A glass button for the row under Continue (as on the Academy's door).
func _glass(text: String, col: Color, act: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 23)
	b.clip_text = true
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 14, col.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.1, 0.14, 0.26, 0.95), 14, col.lightened(0.4)))
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		act.call())
	return b


## Normal / Hard / Extreme as three small glass tabs; the one in use is lit.
func _difficulty_row(col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := UITheme.label(Loc.t("Difficulty"), 19, UITheme.TEXT_DIM, UITheme.semi_font())
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.tooltip_text = Loc.t("You can change this any time. It changes how well opponents play, not what happens. The same setting is in Settings.")
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(6, 0)
	h.add_child(gap)
	var tabs: Array = []
	for i in 3:
		var b := Button.new()
		b.text = Loc.t(["Normal", "Hard", "Extreme"][i])
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(132, 44)
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.6), 12, Color(1, 1, 1, 0.16)))
		b.add_theme_stylebox_override("hover", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.85), 12, col.lightened(0.2)))
		b.add_theme_stylebox_override("focus", UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.85), 12, col.lightened(0.2)))
		b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(col.darkened(0.55), 0.92), 12, col.lightened(0.3)))
		b.add_theme_stylebox_override("hover_pressed", UITheme.panel_box(Color(col.darkened(0.5), 0.95), 12, col.lightened(0.4)))
		for fc in ["font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_hover_color"]:
			b.add_theme_color_override(fc, Color.WHITE)
		b.button_pressed = Saves.story_difficulty() == i
		tabs.append(b)
		h.add_child(b)
	for i in 3:
		var me: Button = tabs[i]
		me.pressed.connect(func():
			Sfx.play("click", -8.0)
			Saves.set_story_difficulty(i)
			for j in 3:
				(tabs[j] as Button).set_pressed_no_signal(j == i))
	return h


func _home() -> void:
	_clear()
	_back.shade_to(0.0)
	var cur := _current()
	var ch: Dictionary = cur[0]
	var at: int = cur[1]
	var col := StoryEmblem.era_color(str(ch["era"]))
	var pos := StoryProgress.position()
	var mid: bool = str(pos.get("chapter", "")) != ""
	var fresh: bool = not mid and StoryProgress.unlocked().size() <= 1 and not StoryProgress.recalls("finished")
	var over := UITheme.label(Loc.t("THE MAIN STORY"), 19, UITheme.GOLD, UITheme.semi_font())
	_left.add_child(over)
	var t := UITheme.label("CROSSROADS", 104, Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 5)
	t.add_theme_constant_override("shadow_outline_size", 10)
	_left.add_child(t)
	_left.add_child(_era_bar(at))
	var sub := UITheme.label(Loc.t("Four eras. One story.") + "  " + Loc.t("A blank deck, a card shop on a Friday night, and every era of dueling at once."), 23, Color(0.9, 0.93, 1.0, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(780, 0)
	_left.add_child(sub)
	var gap0 := Control.new()
	gap0.custom_minimum_size = Vector2(0, 12)
	_left.add_child(gap0)
	# Where the game in this save is: the chapter's mark, its era, the place and how far along.
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.82), 20, Color(col, 0.75)))
	card.custom_minimum_size = Vector2(800, 0)
	_left.add_child(card)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 18)
	card.add_child(m)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	m.add_child(row)
	var em := StoryEmblem.new(col, mark_of(at), 104.0)
	em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(em)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UITheme.label(Loc.t(str(ch["title"])).to_upper(), 38, col.lightened(0.45), UITheme.title_font()))
	var name := UITheme.label(Loc.t(str(ch["name"])), 25, UITheme.GOLD, UITheme.semi_font())
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size = Vector2(580, 0)
	v.add_child(name)
	var era_word := Loc.t("The world between the eras") if str(ch["era"]) == "Crossroads" else str(ch["era"])
	# The world the chapter is in right now (the same one as the picture behind).
	var world := world_name(district_of(str(ch["id"]), int(pos.get("step", 0)) if mid else 0))
	var line2 := "%s   ·   %s" % [era_word, world]
	if StoryProgress.recalls("finished") and not mid:
		line2 = "%s   ·   %s" % [era_word, Loc.t("Story finished")]
	var l2 := UITheme.label(line2, 21, Color.WHITE, UITheme.semi_font())
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l2.custom_minimum_size = Vector2(580, 0)
	v.add_child(l2)
	var col_node = get_tree().root.get_node_or_null("Collection") if is_inside_tree() else null
	var facts := Loc.t("%d of %d chapters open") % [_played(), StoryData.CHAPTERS.size()]
	facts += "   ·   " + Loc.t("%d bonds") % StoryProgress.bonds()
	if col_node:
		facts += "   ·   %d DP" % int(col_node.dp)
	v.add_child(UITheme.label(facts, 17, UITheme.TEXT_DIM))
	var first := Button.new()
	if mid:
		first.text = "▶   " + Loc.t("Continue")
		first.pressed.connect(func():
			Sfx.play("click", -6.0)
			StoryDirector.begin(str(pos["chapter"]), true))
	else:
		first.text = "▶   " + (Loc.t("Begin the story") if fresh else "%s: %s" % [Loc.t("Play"), Loc.t(str(ch["title"]))])
		var cid := str(ch["id"])
		first.pressed.connect(func():
			Sfx.play("gong", -8.0)
			StoryDirector.begin(cid))
	first.custom_minimum_size = Vector2(800, 92)
	first.add_theme_font_size_override("font_size", 38)
	first.clip_text = true
	UITheme.paint_button(first, col.darkened(0.25))
	_left.add_child(first)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	row2.custom_minimum_size = Vector2(800, 0)
	_left.add_child(row2)
	row2.add_child(_glass(Loc.t("Chapters"), col, _chapters))
	if not Saves.admin:
		row2.add_child(_glass(Loc.t("Load a save"), col, func():
			_back.shade_to(0.0)
			var sm := SaveMenu.open(self, false, false, true)
			sm.closed.connect(_home)))
		row2.add_child(_glass(Loc.t("New game"), col, _ask_new))
	row2.add_child(_glass(Loc.t("Back"), col, _close))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	_left.add_child(gap)
	_left.add_child(_difficulty_row(col))
	if Saves.admin:
		var warn := UITheme.label(Loc.t("ADMIN MODE IS ON: every chapter is open. Saving is switched off. Turn it off in Settings to get your own game back."), 18, UITheme.GOLD)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.custom_minimum_size = Vector2(780, 0)
		_left.add_child(warn)
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


func _page_title(text: String, sub: String) -> void:
	var t := UITheme.label(Loc.t(text).to_upper(), 72, Color.WHITE, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	if sub != "":
		var s := UITheme.label(Loc.t(sub), 22, UITheme.TEXT_DIM)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(s)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	_box.add_child(gap)


## A chapter as a wide glass tile: its mark, title and name, the era; and whether it is where you are.
func _chapter_tile(i: int, parent: Container) -> Button:
	var c: Dictionary = StoryData.CHAPTERS[i]
	var pos := StoryProgress.position()
	var open: bool = StoryProgress.unlocked().has(c["id"]) and StoryData.SCRIPTS.has(c["id"])
	var col := StoryEmblem.era_color(str(c["era"]))
	var here: bool = open and str(pos.get("chapter", "")) == str(c["id"]) and int(pos.get("step", 0)) > 0
	var b := Button.new()
	b.custom_minimum_size = Vector2(540, 128)
	b.disabled = not open
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.04, 0.06, 0.13, 0.9), 18, Color(col, 0.55 if open else 0.15)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.96), 18, col))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.09, 0.13, 0.25, 0.96), 18, col.lightened(0.3)))
	b.add_theme_stylebox_override("disabled", UITheme.panel_box(Color(0.03, 0.04, 0.08, 0.75), 18, Color(1, 1, 1, 0.06)))
	parent.add_child(b)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12)
	b.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	var em := StoryEmblem.new(col, mark_of(i), 92.0)
	em.lit = 1.0 if open else 0.3
	em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(em)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var era_word := Loc.t("The world between the eras") if str(c["era"]) == "Crossroads" else str(c["era"])
	v.add_child(UITheme.label("%s   ·   %s" % [Loc.t(str(c["title"])).to_upper(), era_word], 16, Color(col.lightened(0.35), 1.0 if open else 0.45), UITheme.semi_font()))
	var nm := UITheme.label(Loc.t(str(c["name"])) if open else Loc.t("Locked" if StoryData.SCRIPTS.has(c["id"]) else "Coming soon"), 25, Color(1, 1, 1, 1.0 if open else 0.4), UITheme.title_font())
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(380, 0)
	v.add_child(nm)
	if open:
		var how := UITheme.label(Loc.t("You are here. This starts it over; Continue picks up where you were.") if here else Loc.t("Starts from the beginning"), 15,
				UITheme.GOLD if here else UITheme.TEXT_DIM, UITheme.semi_font())
		how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		how.custom_minimum_size = Vector2(380, 0)
		v.add_child(how)
	for n in v.get_children():
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var id := str(c["id"])
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		if here:
			_ask("Start this chapter over?", "Start this chapter over from its first scene? To pick up where you were, go back and use Continue.", "Start over", func(): StoryDirector.begin(id), _chapters)
		else:
			StoryDirector.begin(id))
	return b


func _chapters() -> void:
	_clear()
	_back.shade_to(0.74)
	_page_title("Chapters", "Any open chapter, from its first scene. The bond scenes open as you get to know people.")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(grid)
	var first: Button = null
	for i in StoryData.CHAPTERS.size():
		var b := _chapter_tile(i, grid)
		if first == null and not b.disabled:
			first = b
	var bl := UITheme.label(Loc.t("Bond scenes").to_upper(), 20, UITheme.GOLD, UITheme.semi_font())
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(bl)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 12)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(brow)
	var unlocked := StoryProgress.unlocked()
	for bd in StoryData.BONDS:
		var who := str(Characters.get_char(str(bd["who"])).get("short", bd["who"]))
		var wins: int = Collection.versus(str(bd["who"]))[0]
		var open: bool = Saves.admin or (unlocked.has(bd["after"]) and wins >= int(bd["wins"]))
		var seen := StoryProgress.recalls("side_" + str(bd["id"]).substr(5))
		var txt := ""
		if open:
			txt = "%s%s\n%s" % ["✔  " if seen else "", who, Loc.t(str(bd["name"]))]
		elif not unlocked.has(bd["after"]):
			txt = "%s\n%s" % [who, Loc.t("Opens later in the story")]
		else:
			txt = "%s\n%s" % [who, Loc.t("Beat them %d times (%d so far)") % [int(bd["wins"]), wins]]
		var bb := _glass(txt, UITheme.GOLD, func(): StoryDirector.begin(str(bd["id"])))
		bb.custom_minimum_size = Vector2(352, 78)
		bb.add_theme_font_size_override("font_size", 19)
		bb.clip_text = false
		bb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bb.disabled = not open
		bb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		brow.add_child(bb)
	var back := _glass(Loc.t("Back"), UITheme.GOLD, _home)
	back.custom_minimum_size = Vector2(360, 60)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(back)
	if first:
		first.grab_focus.call_deferred()
	else:
		back.grab_focus.call_deferred()


## A question in the middle of the screen, the picture darkened behind it; the safe answer focused.
func _ask(title: String, text: String, yes: String, then: Callable, back: Callable = Callable()) -> void:
	_clear()
	_back.shade_to(0.74)
	_page_title(title, text)
	var b1 := Button.new()
	b1.text = Loc.t(yes)
	b1.custom_minimum_size = Vector2(620, 84)
	b1.add_theme_font_size_override("font_size", 32)
	b1.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.paint_button(b1, Color("c8322a"))
	b1.pressed.connect(func():
		Sfx.play("click", -6.0)
		then.call())
	_box.add_child(b1)
	var b2 := Button.new()
	b2.text = Loc.t("Keep my game") if yes == "Start a new game" else Loc.t("Cancel")
	b2.custom_minimum_size = Vector2(620, 62)
	b2.add_theme_font_size_override("font_size", 25)
	b2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var go_back: Callable = back if back.is_valid() else _home
	b2.pressed.connect(func():
		Sfx.play("click", -6.0)
		go_back.call())
	_box.add_child(b2)
	b2.grab_focus.call_deferred()


func _ask_new() -> void:
	_ask("New game?", "Start a new game from the very beginning: story, cards, Duel Points, everything? Save your current game to a slot first if you want to keep it. The game restarts.",
		"Start a new game", func(): Saves.restart_with("new"))


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _left.get_child_count() == 0:
			_home()
		else:
			_close()
