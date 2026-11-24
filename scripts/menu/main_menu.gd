extends Control
## Main menu: animated 3D backdrop, title, menu entries and side panels.

const MenuBackground := preload("res://scripts/menu/menu_city.gd")

var _hello_box: LumenBubble = null      # where Lumen says hello when the game opens
var _items: Array[Button] = []
var _menu_box: Control
var _title_box: Control
var _panel_open := false


static var _engine_told := false

func _exit_tree() -> void:
	Settings.scale_floor = 0.0


func _ready() -> void:
	# (0.72.3) The start of the game: a card with a turning ring is up while everything is got ready
	# (see Router.boot_begin). Only the first time the menu comes up, and never in a test without a screen.
	var boot := not Router.opening_shown and DisplayServer.get_name() != "headless" and not ("--no-boot-card" in OS.get_cmdline_user_args())
	if boot:
		process_mode = Node.PROCESS_MODE_DISABLED      # (nothing of the menu runs until it is whole)
		Router.boot_begin()
		await get_tree().process_frame
		await get_tree().process_frame
	# The city behind the menu is a backdrop: keep it sharp even when the 3D resolution is set low.
	Settings.scale_floor = 0.55
	# Back from the Academy story: your own collection and your own clothes again.
	if Campus.on:
		Campus.leave()
	theme = UITheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Music.play("menu")
	Sfx.ambience("")
	Pad.walk_mode = false
	Pad.both_sticks = false
	Pad.hint("")
	if Settings.first_run_pick:
		# The very first start: say what was chosen, and keep it.
		Settings.first_run_pick = false
		Settings.save_settings()
		Router.toast.call_deferred(Loc.t("Graphics set to %s for this machine. You can change it in Settings.") % Loc.t(Settings.gfx_preset_name()), 6.0)
	_build_background()
	_build_overlay()
	_build_title()
	if "--open=oldmenu" in OS.get_cmdline_user_args():
		_build_menu()          # dev: the home screen from before 0.69.1, to compare
	else:
		_build_home()
	_build_featured()
	_build_profile_chip()
	if _home_cont != null:
		# (Up from the Continue card is your duelist card; down from it, back to Continue.)
		_home_cont.focus_neighbor_top = _home_cont.get_path_to(_chip)
		_chip.focus_neighbor_bottom = _chip.get_path_to(_home_cont)
		_chip.focus_mode = Control.FOCUS_ALL
	_build_footer()
	if boot:
		Router.prepare()
		process_mode = Node.PROCESS_MODE_INHERIT
		await Router.boot_end()
		if not is_inside_tree():
			return
	# A new duelist: the opening is up before the menu is ever seen (it used to flash by first).
	var first_menu := not Router.opening_shown    # the first time the menu is up since the game started
	Router.opening_shown = true
	var replay := false
	if "--intro-short" in OS.get_cmdline_user_args():
		replay = true            # dev: the short opening, whoever you are
		_first_start(true)
	elif _language_due():
		_pick_language()
	elif _opening_due():
		_first_start()
	elif first_menu and _replay_due():
		# Every start after the first: the short opening (the worlds and the title), then the menu.
		replay = true
		_first_start(true)
	_intro()
	if not replay:
		if first_menu and Profile.created and Router.menu_open == "":
			get_tree().create_timer(0.9).timeout.connect(_lumen_hello)
		_lumen_news.call_deferred()
	Router.roam["story"] = ""
	if Router.menu_open == "":
		_welcome_back.call_deferred()
	if Router.menu_open == "select":
		Router.menu_open = ""
		Router.story_result = ""
		_on_free_duel.call_deferred()
	elif Router.menu_open == "replays":
		Router.menu_open = ""
		_on_replays.call_deferred()
	elif Router.menu_open == "knockout":
		Router.menu_open = ""
		var res := Router.story_result
		Router.story_result = ""
		_on_knockout.call_deferred(res)
	elif Router.menu_open == "academy":
		Router.menu_open = ""
		_on_academy_classic.call_deferred()
	elif Router.menu_open == "campus":
		Router.menu_open = ""
		_on_academy.call_deferred()
	elif Router.menu_open == "turbo":
		Router.menu_open = ""
		_on_turbo.call_deferred()
	elif Router.menu_open == "builder":
		Router.menu_open = ""
		(func():
			var b := DeckBuilder.new()
			b.z_index = 100
			add_child(b)).call_deferred()
	elif Router.menu_open == "pad":
		Router.menu_open = ""
		SettingsPanel._tab_at["settings"] = 99
		_on_settings.call_deferred()
	elif Router.menu_open == "album":
		Router.menu_open = ""
		_on_album.call_deferred()
	elif Router.menu_open == "online":
		Router.menu_open = ""
		_on_online.call_deferred()
	elif Router.menu_open == "saves":
		Router.menu_open = ""
		_on_saves.call_deferred()
	elif Router.menu_open == "goals":
		Router.menu_open = ""
		_on_goals.call_deferred()
	elif Router.menu_open == "decks":
		Router.menu_open = ""
		_on_deck_list.call_deferred()
		Router.toast.call_deferred(Loc.t("Pick or fix your deck, then press Story: it picks up at the duel you lost."))


var _bg_vp: SubViewport
var _bg_box: SubViewportContainer


func _build_background() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	svc.add_child(vp)
	var bg := Node3D.new()
	bg.set_script(MenuBackground)
	vp.add_child(bg)
	_bg_vp = vp
	_bg_box = svc
	# Like a photo focused on the duelists: the city behind them is a little soft, a little
	# darker and a little less colourful, so the people in front are what you look at.
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float radius = 1.6;
uniform float dim = 0.72;
uniform float sat = 0.8;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * radius;
	vec3 c = vec3(0.0);
	float w = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float k = exp(-float(x * x + y * y) / 4.0);
			c += texture(TEXTURE, UV + vec2(float(x), float(y)) * px).rgb * k;
			w += k;
		}
	}
	c /= w;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(g), c, sat) * dim, 1.0);
}
"""
	var soft := ShaderMaterial.new()
	soft.shader = sh
	svc.material = soft
	# The city is a picture, not a place you play in: it is drawn a few times at the full
	# sharpness of the screen and then held, so the home screen costs next to nothing and never
	# turns to blocks, whatever the 3D resolution is set to. It stays still (a slow drift looked wrong).
	_shoot_background()
	get_viewport().size_changed.connect(_shoot_background)
	Profile.changed.connect(_shoot_background)


var _bg_shots := 0


func _shoot_background() -> void:
	if _bg_vp == null or not is_inside_tree():
		return
	# The menu is laid out on a 1080-line canvas; the screen may have many more lines than that.
	var canvas_h := maxf(1.0, get_viewport_rect().size.y)
	var screen_h := float(DisplayServer.window_get_size().y)
	_bg_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_bg_vp.scaling_3d_scale = clampf(clampf(screen_h, 720.0, 1620.0) / canvas_h, 0.5, 2.0)
	_bg_shots += 1
	var mine := _bg_shots
	# Now, and twice more once everything in it has had time to load.
	for wait: float in [0.0, 0.35, 1.2]:
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout
		if not is_inside_tree() or mine != _bg_shots:
			return
		_bg_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _build_overlay() -> void:
	# The real city in its own colors. Dark on the left where the menu sits, clear on the
	# right where the duelists stand; a little shade top and bottom to frame it.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(0.015, 0.025, 0.06, 0.94), Color(0.015, 0.025, 0.06, 0.8), Color(0.015, 0.025, 0.06, 0.2), Color(0.015, 0.025, 0.06, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 4
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.anchor_bottom = 1.0
	tr.anchor_right = 0.8
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.18, 0.62, 1.0])
	vg.colors = PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0.01, 0.02, 0.05, 0.78)])
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill_from = Vector2(0, 0)
	vt.fill_to = Vector2(0, 1)
	vt.width = 4
	vt.height = 256
	var vr := TextureRect.new()
	vr.texture = vt
	vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vr.stretch_mode = TextureRect.STRETCH_SCALE
	vr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vr)


func _build_title() -> void:
	_title_box = Control.new()
	_title_box.position = Vector2(70, 158)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_box)
	var small := UITheme.label("Y U - G I - O H !", 22, UITheme.ACCENT, Comic.button_font())
	small.position = Vector2(4, 0)
	_title_box.add_child(small)
	var big := UITheme.label("CROSSROADS", 112, Color.WHITE, Comic.shout_font())
	big.position = Vector2(-2, 12)
	big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 6)
	big.add_theme_constant_override("shadow_outline_size", 14)
	_title_box.add_child(big)
	var rule := ColorRect.new()
	rule.color = UITheme.ACCENT
	rule.position = Vector2(4, 140)
	rule.size = Vector2(72, 4)
	_title_box.add_child(rule)
	var tag := UITheme.label("Four eras. One story.", 20, Color(0.82, 0.86, 0.95))
	tag.position = Vector2(90, 128)
	_title_box.add_child(tag)


## What the Story tile says: where you left off, or the newest chapter you can start.
func _story_line() -> Array:
	var pos := StoryProgress.position()
	var unlocked := StoryProgress.unlocked()
	var newest := {}
	var played := 0
	for c in StoryData.CHAPTERS:
		if unlocked.has(c["id"]) and StoryData.SCRIPTS.has(c["id"]):
			newest = c
			played += 1
		if str(pos["chapter"]) == str(c["id"]):
			return [Loc.t("Continue"), "%s: %s" % [Loc.t(str(c["title"])), Loc.t(str(c["name"]))], Loc.t("Pick up right where you stopped. %d of %d chapters open.") % [maxi(played, 1), StoryData.CHAPTERS.size()]]
	if newest.is_empty():
		newest = StoryData.CHAPTERS[0]
	return [Loc.t("Story"), "%s: %s" % [Loc.t(str(newest["title"])), Loc.t(str(newest["name"]))], Loc.t("%d of %d chapters open. Each one ends with a bond and a new card.") % [maxi(played, 1), StoryData.CHAPTERS.size()]]


func _build_menu() -> void:
	_menu_box = Control.new()
	_menu_box.position = Vector2(64, 336)
	add_child(_menu_box)
	Tournament.load_data()
	var won := 0
	for id in Tournament.DEFS:
		if Tournament.titles(str(id)) > 0:
			won += 1
	var st := _story_line()
	# The Story banner on top, then three rows of ribbons. Each row steps back along the slant.
	var story := MenuTile.new(str(st[0]), str(st[1]), str(st[2]), UITheme.ACCENT, "", Vector2(736, 150), "", true)
	story.position = Vector2(24, 0)
	story.pressed.connect(_on_story)
	story.pressed.connect(func(): Sfx.play("click", -6.0))
	_menu_box.add_child(story)
	_items.append(story)
	var rows := [
		[["Quick play", "FREE DUEL", "Any duelist, deck and field.", "⚔", _on_free_duel, ""],
			["Riding Duels", "TURBO DUEL", "Race the highway at speed.", "➤", _on_turbo, ""]],
		[["Open world", "FREE ROAM", "Five places to walk and duel.", "◎", _on_roam, ""],
			["Four titles", "TOURNAMENTS", "Badges, brackets, trophies.", "♛", _on_tournaments, "%d / %d" % [won, Tournament.DEFS.size()]]],
		[["A story of its own", "DUEL ACADEMY", "A school year on the island.", "✎", _on_academy, ""],
			["Your cards", "DECKS & CARDS", "Your decks, the album, the shops.", "❖", _on_deck, ""]],
	]
	var y := 160.0
	for ri in rows.size():
		var x := 16.0 - ri * 8.0
		for e in rows[ri]:
			var tile := MenuTile.new(str(e[0]), str(e[1]), str(e[2]), UITheme.ACCENT, "", Vector2(364, 112), str(e[5]), false)
			tile.position = Vector2(x, y)
			tile.pressed.connect(e[4])
			tile.pressed.connect(func(): Sfx.play("click", -6.0))
			_menu_box.add_child(tile)
			_items.append(tile)
			x += 364.0 + 2.0
		y += 112.0 + 6.0
	# Settings and Quit are round buttons in the corner.
	var rounds := HBoxContainer.new()
	rounds.add_theme_constant_override("separation", 14)
	rounds.anchor_top = 1.0
	rounds.anchor_bottom = 1.0
	rounds.offset_left = 64
	rounds.offset_top = -112
	rounds.offset_bottom = -48
	add_child(rounds)
	var gear := RoundButton.new("gear", Comic.BLUE, 64.0)
	gear.tooltip_text = "Settings"
	gear.focus_mode = Control.FOCUS_ALL
	gear.pressed.connect(_on_settings)
	rounds.add_child(gear)
	_items.append(gear)
	var goals := RoundButton.new("goals", Comic.BLUE, 64.0)
	goals.tooltip_text = Loc.t("Rank and goals")
	goals.focus_mode = Control.FOCUS_ALL
	var left := 0
	for r in Goals.daily_rows():
		if not r["done"]:
			left += 1
	goals.badge = left
	goals.pressed.connect(_on_goals)
	rounds.add_child(goals)
	_items.append(goals)
	var album := RoundButton.new("album", Comic.BLUE, 64.0)
	album.tooltip_text = Loc.t("Card Album")
	album.focus_mode = Control.FOCUS_ALL
	album.pressed.connect(_on_album)
	rounds.add_child(album)
	_items.append(album)
	var reps := RoundButton.new("replay", Comic.BLUE, 64.0)
	reps.tooltip_text = Loc.t("Replays")
	reps.focus_mode = Control.FOCUS_ALL
	reps.pressed.connect(_on_replays)
	rounds.add_child(reps)
	_items.append(reps)
	if OS.has_feature("pc"):
		var quit := RoundButton.new("power", Comic.RED, 64.0)
		quit.tooltip_text = "Quit"
		quit.focus_mode = Control.FOCUS_ALL
		quit.pressed.connect(_on_quit)
		rounds.add_child(quit)
		_items.append(quit)
	# (where the row ends: the line of small print beside it starts after that, however many buttons there are)
	_rounds_end = 64.0 + rounds.get_child_count() * 64.0 + maxi(rounds.get_child_count() - 1, 0) * 14.0


## The four tournaments at a glance, and a way to go straight to each one's desk.
func _on_tournaments() -> void:
	var p := SidePanel.new("Tournaments", 760)
	p.z_index = 100
	var hint := UITheme.label("Beat duelists out in the world to earn Finals Badges, then win the bracket. Three titles open the Crossroads Cup.", 18, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(hint)
	Tournament.load_data()
	# Where you stand over all four: a cup for each title, and what to do next.
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.12, 0.1, 0.04, 0.9), Color(UITheme.GOLD, 0.5), 14))
	var hm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		hm.add_theme_constant_override("margin_" + side, 16)
	head.add_child(hm)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	hm.add_child(hv)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 14)
	trow.add_child(UITheme.label(Loc.t("TITLES  %d / %d") % [Tournament.total_titles(), Tournament.ORDER.size()], 30, UITheme.GOLD, UITheme.title_font()))
	for tid in Tournament.ORDER:
		var won: bool = Tournament.titles(str(tid)) > 0
		var cup := UITheme.label("★" if won else "☆", 30, Color(Tournament.DEFS[tid]["color"]) if won else Color(1, 1, 1, 0.25))
		cup.tooltip_text = Loc.t(str(Tournament.DEFS[tid]["name"]))
		trow.add_child(cup)
	hv.add_child(trow)
	var nx := UITheme.label(Tournament.next_step(), 20, Color.WHITE, UITheme.semi_font())
	nx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(nx)
	hv.add_child(UITheme.label(Loc.t("Pick one to go there."), 15, UITheme.TEXT_DIM))
	p.body.add_child(head)
	for id in Tournament.DEFS:
		var d: Dictionary = Tournament.DEFS[id]
		var b := TourneyCard.new(str(id))
		b.disabled = not Tournament.missing(str(id)).is_empty()
		var district := str(d.get("district", "domino"))
		b.pressed.connect(func():
			if district == "ride":
				Router.go(Router.RIDE)
				return
			Router.roam["district"] = district
			Router.roam["free"] = true       # Free Roam is free: no chapter list, no story leads
			Router.roam["pos"] = null
			Router.roam.erase("yaw")
			Router.roam.erase("tod")
			Router.go(Router.ROAM))
		p.body.add_child(b)
	add_child(p)
	_open_panel(p)


## Your Duelist Rank, and what today and this week ask of you.
func _on_goals() -> void:
	Sfx.play("click", -6.0)
	# Anything finished since the last look pays now (a collection you built before goals existed too).
	var pays: Array = Goals.pay_due() + Goals.pay_album()
	var total := 0
	for line in pays:
		total += int(line[1])
	if total > 0:
		Router.toast(Loc.t("%d goals reached   +%d Duel Points") % [pays.size(), total], 3.0)
		Sfx.play("quest", -3.0)
	var p := SidePanel.new("Rank & Goals", 760)
	p.z_index = 100
	var head := PanelContainer.new()
	var rc := Goals.rank_color()
	head.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.06, 0.08, 0.16, 0.92), Color(rc, 0.6), 14))
	var hm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		hm.add_theme_constant_override("margin_" + side, 18)
	head.add_child(hm)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 8)
	hm.add_child(hv)
	hv.add_child(UITheme.label(Loc.t("DUELIST RANK"), 16, UITheme.TEXT_DIM, UITheme.semi_font()))
	hv.add_child(UITheme.label(Goals.rank_name().to_upper(), 40, rc, UITheme.title_font()))
	hv.add_child(_goal_bar(Goals.progress(), rc))
	var nxt := Goals.to_next()
	var t := Goals.tier()
	var under := Loc.t("%d rank points") % Goals.points()
	if nxt > 0:
		under += "   ·   " + Loc.t("%d more to %s (+%d Duel Points)") % [nxt, Goals.rank_name(t + 1), int(Goals.RANKS[t + 1][3])]
	else:
		under += "   ·   " + Loc.t("The top rank. Nobody stands above you.")
	hv.add_child(UITheme.label(under, 17, UITheme.TEXT))
	var how := UITheme.label(Loc.t("Every duel you win earns rank points: more against harder opponents, more for a win streak or a duel without damage. A loss costs a few, but you never drop out of a rank you reached."), 15, UITheme.TEXT_DIM)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(how)
	p.body.add_child(head)
	var sections := [[Loc.t("TODAY"), Goals.daily_rows(), Goals.day_left()], [Loc.t("THIS WEEK"), Goals.weekly_rows(), Goals.week_left()]]
	for sec in sections:
		var sh := HBoxContainer.new()
		var st := UITheme.label(str(sec[0]), 26, Color.WHITE, UITheme.title_font())
		st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sh.add_child(st)
		var secs := int(sec[2])
		var left_text := (Loc.t("New goals in %d h") % maxi(1, secs / 3600)) if secs < 86400 * 2 else (Loc.t("New goals in %d days") % (secs / 86400))
		sh.add_child(UITheme.label(left_text, 15, UITheme.TEXT_DIM))
		p.body.add_child(sh)
		for r in sec[1]:
			p.body.add_child(_goal_row(r))
	# Collection goals: every pack pays as you own a quarter, half, three quarters and all of it.
	p.body.add_child(UITheme.label(Loc.t("COLLECTION"), 26, Color.WHITE, UITheme.title_font()))
	var ch := UITheme.label(Loc.t("Own a quarter, half, three quarters and every card of a pack to earn its rewards."), 15, UITheme.TEXT_DIM)
	ch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(ch)
	for a in Goals.album_rows():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var nm := UITheme.label(Loc.t(str(a["name"])), 17, Color(a["color"]).lightened(0.3), UITheme.semi_font())
		nm.custom_minimum_size = Vector2(220, 0)
		nm.clip_text = true
		row.add_child(nm)
		var full: bool = int(a["step"]) >= Goals.ALBUM_STEPS.size()
		var bar := _goal_bar(float(a["have"]) / maxf(1.0, float(a["total"])), UITheme.ACCENT if full else Color(a["color"]))
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		var cnt := UITheme.label("%d / %d" % [int(a["have"]), int(a["total"])], 15, UITheme.TEXT_DIM)
		cnt.custom_minimum_size = Vector2(84, 0)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(cnt)
		var nx := UITheme.label(Loc.t("Complete") if full else (Loc.t("at %d: +%d") % [int(a["next_at"]), int(a["next_dp"])]), 15, UITheme.ACCENT if full else Comic.YELLOW)
		nx.custom_minimum_size = Vector2(120, 0)
		nx.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(nx)
		p.body.add_child(row)
	add_child(p)
	_open_panel(p)


func _goal_bar(f: float, col: Color) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.draw.connect(func():
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(1, 1, 1, 0.12))
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * clampf(f, 0.0, 1.0), bar.size.y)), col))
	return bar


func _goal_row(r: Dictionary) -> Control:
	var done: bool = r["done"]
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.05, 0.09, 0.08, 0.9) if done else Color(0.05, 0.075, 0.15, 0.9), Color(UITheme.ACCENT, 0.5) if done else Color(1, 1, 1, 0.12), 12))
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 14)
	box.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	var top := HBoxContainer.new()
	var name := UITheme.label(("✓  " if done else "") + Loc.t(str(r["name"])), 20, UITheme.ACCENT if done else Color.WHITE, UITheme.semi_font())
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	top.add_child(UITheme.label(Loc.t("Done") if done else ("+%d DP" % int(r["reward"])), 18, UITheme.ACCENT if done else Comic.YELLOW, UITheme.semi_font()))
	v.add_child(top)
	var txt := UITheme.label(Loc.t(str(r["text"])), 16, UITheme.TEXT_DIM)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	var low := HBoxContainer.new()
	low.add_theme_constant_override("separation", 12)
	var bar := _goal_bar(float(r["have"]) / maxf(1.0, float(r["goal"])), UITheme.ACCENT)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	low.add_child(bar)
	low.add_child(UITheme.label("%d / %d" % [int(r["have"]), int(r["goal"])], 15, UITheme.TEXT_DIM))
	v.add_child(low)
	return box


var _chip_avatar: TextureRect
var _chip_name: Label
var _chip_sub: Label


## A lineup of duelists on the right: four at a time, one from each series (Duel Monsters, GX,
## 5D's, ZEXAL), each with a name tag. Every few seconds one of them steps out for another
## duelist from the same series, so all four eras are always on screen.
const LINEUP := 4
const LINEUP_ERAS := ["Duel Monsters", "GX", "5D's", "ZEXAL"]
var _line: Array = []            # [{tex, tag, key, home, pool, at}]
var _feat_turn := 0


func _build_featured() -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	move_child(holder, 2)
	var pools: Array = [[], [], [], []]
	var spare: Array = []
	for key in Characters.ORDER:
		if not Avatars.has_avatar(str(key)):
			continue
		var era := LINEUP_ERAS.find(str(Characters.get_char(str(key)).get("era", "")))
		if era >= 0:
			(pools[era] as Array).append(str(key))
		else:
			spare.append(str(key))
	for pool in pools:
		(pool as Array).shuffle()
		if (pool as Array).is_empty():
			# Nobody from that series has a model yet: anyone will do.
			(pool as Array).append_array(spare if not spare.is_empty() else Characters.ORDER.slice(0, 1))
	var vs := get_viewport_rect().size
	# Back to front, so the two in the middle stand a step ahead of the outer two.
	var plan := [[0, 0.82, -30.0], [3, 0.82, -30.0], [1, 1.0, 0.0], [2, 1.0, 0.0]]
	_line.resize(LINEUP)
	for e in plan:
		var i: int = e[0]
		var sc: float = e[1]
		# The picture shows a wider piece of the world than the bust it used to (room for any
		# hair), so the slot is bigger and the slots overlap: what overlaps is empty air.
		var sz := Vector2(592, 740) * sc
		# (Clear of the mode tiles on the left, which end at x 900: the outer figures stand right of them.)
		var cx := vs.x - 815.0 + i * 228.0
		var home := Vector2(cx - sz.x / 2.0, vs.y - 62.0 - sz.y + float(e[2]))
		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.material = _fade_mat().duplicate()
		holder.add_child(tex)
		tex.size = sz
		tex.position = home
		var tex2: TextureRect = tex.duplicate()
		tex2.material = _fade_mat().duplicate()
		tex2.modulate.a = 0.0
		holder.add_child(tex2)
		var tag := Control.new()
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.position = Vector2(cx, home.y + sz.y - 114.0)
		tag.draw.connect(_draw_name_tag.bind(tag))
		holder.add_child(tag)
		_line[i] = {"tex": tex, "tex2": tex2, "tag": tag, "key": "", "home": home, "pool": pools[i], "at": 0, "dim": 0.82 if sc < 1.0 else 1.0}
	# (0.72.4) The four who stand there first: read side by side, not one after another.
	var first: Array = []
	for i in LINEUP:
		first.append(str((_line[i]["pool"] as Array)[0]))
	Avatars.read_ahead(first)
	for i in LINEUP:
		_set_lineup(i, str((_line[i]["pool"] as Array)[0]), true)
	for i in LINEUP:
		if (_line[i]["pool"] as Array).size() > 1:
			Avatars.warm(str((_line[i]["pool"] as Array)[1]))
	var t := Timer.new()
	t.wait_time = 3.4
	t.autostart = true
	t.timeout.connect(func():
		# Take turns; a series with only one duelist keeps the one it has.
		for tries in LINEUP:
			var slot: Dictionary = _line[[1, 3, 2, 0][_feat_turn % LINEUP]]
			_feat_turn += 1
			var pool: Array = slot["pool"]
			if pool.size() < 2:
				continue
			var coming := str(pool[(int(slot["at"]) + 1) % pool.size()])
			if not Avatars.ready_now(coming):
				# Their model is still being read in the background: somebody else takes this
				# turn, and nothing on screen waits for a file.
				Avatars.warm(coming)
				continue
			slot["at"] = (int(slot["at"]) + 1) % pool.size()
			_set_lineup(_line.find(slot), coming, false)
			break
		# Whoever is up next, in every slot, is read ahead of time.
		for sl in _line:
			var pl: Array = (sl as Dictionary)["pool"]
			if pl.size() > 1:
				Avatars.warm(str(pl[(int((sl as Dictionary)["at"]) + 1) % pl.size()])))
	add_child(t)


## The busts melt into the street at the waist instead of ending in a hard cut.
var _fade: ShaderMaterial


func _fade_mat() -> ShaderMaterial:
	if _fade == null:
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
uniform float shade = 0.0;          // 1 = a dark silhouette (while one duelist swaps for another)
uniform float dim = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb = mix(c.rgb * dim, vec3(0.035, 0.05, 0.11), shade);
	c.a *= 1.0 - smoothstep(0.74, 0.9, UV.y);
	// Nothing ends in a hard line at the edge of its picture.
	c.a *= smoothstep(0.0, 0.05, UV.x) * smoothstep(1.0, 0.95, UV.x) * smoothstep(0.0, 0.03, UV.y);
	COLOR = c;
}
"""
		_fade = ShaderMaterial.new()
		_fade.shader = sh
	return _fade


func _set_lineup(i: int, key: String, instant: bool) -> void:
	var slot: Dictionary = _line[i]
	var tex: TextureRect = slot["tex"]
	var tag: Control = slot["tag"]
	var mat: ShaderMaterial = tex.material
	mat.set_shader_parameter("dim", slot["dim"])
	var d := Characters.get_char(key)
	var swap := func():
		slot["key"] = key
		tex.texture = Portraits.get_portrait(key, true)
		tag.set_meta("name", str(d.get("short", key)).to_upper())
		tag.set_meta("color", Color(d.get("color", Comic.BLUE)))
		tag.queue_redraw()
	var home: Vector2 = slot["home"]
	if instant:
		swap.call()
		tex.modulate.a = 0.0
		tag.modulate.a = 0.0
		tex.position = home + Vector2(40, 0)
		var tw0 := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw0.tween_property(tex, "position", home, 0.4).set_delay(0.1 + i * 0.05)
		tw0.tween_property(tex, "modulate:a", 1.0, 0.3).set_delay(0.1 + i * 0.05)
		tw0.tween_property(tag, "modulate:a", 1.0, 0.25).set_delay(0.25 + i * 0.05)
		return
	# The next duelist fades in over the one who is leaving, with a small step in from the side.
	# The picture is asked for a moment early, so it is fully drawn before anyone sees it.
	var nxt: TextureRect = slot["tex2"]
	nxt.texture = Portraits.get_portrait(key, true)
	nxt.material.set_shader_parameter("dim", slot["dim"])
	nxt.modulate.a = 0.0
	nxt.position = home + Vector2(26, 0)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(tag, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func():
		slot["key"] = key
		tag.set_meta("name", str(d.get("short", key)).to_upper())
		tag.set_meta("color", Color(d.get("color", Comic.BLUE)))
		tag.queue_redraw())
	tw.set_parallel()
	tw.tween_property(nxt, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(nxt, "position", home, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(tex, "modulate:a", 0.0, 0.45).set_delay(0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(tex, "position", home + Vector2(-20, 0), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(tag, "modulate:a", 1.0, 0.3).set_delay(0.2)
	tw.set_parallel(false)
	tw.tween_callback(func():
		slot["tex"] = nxt
		slot["tex2"] = tex
		tex.texture = null)


func _draw_name_tag(c: Control) -> void:
	if not c.has_meta("name"):
		return
	var nm := str(c.get_meta("name"))
	var col: Color = c.get_meta("color")
	var f := Comic.chunky_font()
	var size := 30
	var w := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 44.0
	var r := Rect2(-w / 2.0, 0, w, 38)
	var pts := Comic.slab(c, r, 10.0, Color(0.05, 0.075, 0.16, 0.94), Color(0.03, 0.045, 0.1, 0.96), 1.0, Vector2(0, 3))
	c.draw_polyline(PackedVector2Array([pts[0], pts[3]]), col.lightened(0.2), 4.0, true)
	c.draw_string(f, Vector2(r.position.x + 24, 28), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)


## The profile bar in the top left: your face, name and title, your Duel Points and how far
## along the current level you are. Press it to open the duelist creator.
var _chip: Button
var _chip_dp: Label


func _build_profile_chip() -> void:
	var chip := Button.new()
	_chip = chip
	chip.position = Vector2(40, 22)
	chip.size = Vector2(700, 112)
	chip.flat = true
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.tooltip_text = "Change your duelist"
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		chip.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	chip.draw.connect(_draw_chip)
	chip.mouse_entered.connect(chip.queue_redraw)
	chip.mouse_exited.connect(chip.queue_redraw)
	add_child(chip)
	var frame := Panel.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.0211, 0.026, 0.0897)
	fsb.set_corner_radius_all(46)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.position = Vector2(10, 10)
	frame.size = Vector2(92, 92)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(frame)
	_chip_avatar = TextureRect.new()
	_chip_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chip_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# The portrait is a whole bust with room around it: zoomed in so the face fills the circle.
	_chip_avatar.position = Vector2(-60, -70)
	_chip_avatar.size = Vector2(213, 266)
	frame.add_child(_chip_avatar)
	_chip_name = Comic.label("", 34, Color.WHITE)
	_chip_name.position = Vector2(126, 14)
	_chip_name.size = Vector2(290, 40)
	_chip_name.clip_text = true
	_chip_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_name)
	_chip_sub = UITheme.label("", 18, UITheme.TEXT_DIM, UITheme.semi_font())
	_chip_sub.position = Vector2(128, 58)
	_chip_sub.size = Vector2(290, 26)
	_chip_sub.clip_text = true
	_chip_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_sub)
	_chip_dp = Comic.label("", 32, Comic.YELLOW)
	_chip_dp.position = Vector2(476, 14)
	_chip_dp.size = Vector2(190, 40)
	_chip_dp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_chip_dp)
	chip.pressed.connect(func(): _open_panel(SettingsPanel.open_profile(self, func(): _open_profile(false))))
	Profile.changed.connect(_refresh_chip)
	Collection.changed.connect(_refresh_chip)
	Portraits.flushed.connect(_on_flushed)
	_refresh_chip()


func _draw_chip() -> void:
	var c := _chip
	var hot := c.is_hovered()
	var pts := Comic.slab(c, Rect2(50, 10, 640, 88), 18.0, Color(0.07, 0.1, 0.2, 0.92) if hot else Color(0.05, 0.075, 0.16, 0.9), Color(0.03, 0.045, 0.1, 0.94), 1.0, Vector2(0, 4))
	if hot:
		Comic.outline(c, pts, UITheme.ACCENT, 2.0)
	# The coin.
	var cc := Vector2(456, 39)
	c.draw_circle(cc, 12.0, Color("c98a00"))
	c.draw_circle(cc, 9.5, Comic.YELLOW)
	c.draw_colored_polygon(PackedVector2Array([cc + Vector2(0, -6), cc + Vector2(4.5, 0), cc + Vector2(0, 6), cc + Vector2(-4.5, 0)]), Color("a86a00"))
	c.draw_line(Vector2(428, 22), Vector2(412, 88), Color(1, 1, 1, 0.12), 1.5, true)
	# The level and how far along it is (three wins a level).
	var f := Comic.button_font()
	c.draw_string(f, Vector2(440, 82), Loc.t("Lv %d") % Profile.level(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	var bar := Rect2(500, 70, 156, 8)
	c.draw_rect(bar, Color(1, 1, 1, 0.14))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(Profile.wins % 3) / 3.0, bar.size.y)), UITheme.ACCENT)
	# The ring around the face.
	c.draw_arc(Vector2(56, 56), 48.0, 0.0, TAU, 48, UITheme.ACCENT if hot else Color(1, 1, 1, 0.85), 3.0, true)


func _on_flushed() -> void:
	_refresh_chip()
	for i in _line.size():
		if _line[i] != null and str(_line[i]["key"]) != "":
			(_line[i]["tex"] as TextureRect).texture = Portraits.get_portrait(str(_line[i]["key"]), true)


func _refresh_chip() -> void:
	_chip_avatar.texture = Portraits.get_portrait("player")
	_chip_name.text = Profile.duelist_name
	_chip_sub.text = "%s   ·   %s" % [Profile.title_text(), Loc.t("%s rank") % Goals.rank_name()]
	_chip_sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_chip_dp.text = DpPurse._fmt(Collection.dp)
	_chip.queue_redraw()


var _first: FirstStart


## The very first start: the opening plays over the menu, and the character creator opens on
## its stage when it asks who you are.
func _language_due() -> bool:
	return (Settings.first_language and not "--shot" in str(OS.get_cmdline_user_args())) or "--lang-pick" in OS.get_cmdline_user_args()


func _opening_due() -> bool:
	var args := str(OS.get_cmdline_user_args())
	if _language_due():
		return false     # the language comes first; the menu is loaded again after it
	return not Profile.created and not "--shot" in args and not "--story" in args


## The short opening plays when the game starts for somebody who already has a duelist. Not
## after a load or a crash (the welcome-back panel is up then), and never on a dev run.
func _replay_due() -> bool:
	if not Settings.opening or not Profile.created or DisplayServer.get_name() == "headless":
		return false
	if Router.menu_open != "" or Saves.crashed_last or Saves.just_loaded != "":
		return false
	for a in OS.get_cmdline_user_args():
		if not (a.begins_with("--assets=") or a.begins_with("--lang=") or a.begins_with("--intro")):
			return false
	return true


func _opening_done() -> void:
	_first = null
	_panel_open = false
	_lumen_hello()
	_lumen_news()
	if _starter_due():
		_open_starter()
	elif _items.size() > 0:
		_items[0].grab_focus()


func _first_start(short := false) -> void:
	if _first != null and is_instance_valid(_first):
		return
	_first = FirstStart.new()
	_first.short = short
	if short:
		_first.done.connect(_opening_done)
	_first.z_index = 90
	add_child(_first)
	_panel_open = true
	_first.ask.connect(func(): _open_profile(true))


func _open_profile(first: bool) -> void:
	var ed := ProfileEditor.new(first)
	ed.z_index = 100
	add_child(ed)
	_panel_open = true
	ed.closed.connect(func():
		_panel_open = false
		_refresh_chip()
		if _first != null and is_instance_valid(_first):
			_first.leave()
			_first = null
		# A new duelist has a name and a look: now a deck.
		if first and _starter_due():
			_open_starter()
			return
		if _items.size() > 1:
			_items[0].grab_focus())


var _rounds_end := 386.0

func _build_footer() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1")
	var credit: String = Loc.t("Fan project  ·  v%s  ·  by %s") % [version, "Atlas Peak Games"]
	var left := UITheme.label(credit, 16, Color(1, 1, 1, 0.35))
	if not OcgCore.ensure_loaded() and not _engine_told:
		_engine_told = true
		get_tree().create_timer(2.0).timeout.connect(func(): Router.toast(Loc.t("The rules engine did not load on this computer, so duels cannot start. Send the file engine_status.txt from the saves folder."), 9.0))
	_anchor_bottom(left, _rounds_end + 24.0, _rounds_end + 24.0 + 650.0)
	# On the same line as the three round buttons beside it (they span 112 to 48 from the bottom).
	left.offset_top = -112
	left.offset_bottom = -48
	left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(left)


func _anchor_bottom(c: Control, left: float, right: float) -> void:
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_top = -64
	c.offset_bottom = -34
	c.offset_left = left
	c.offset_right = right


func _intro() -> void:
	_title_box.modulate.a = 0.0
	_title_box.position.x -= 40
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_title_box, "modulate:a", 1.0, 0.35)
	tw.tween_property(_title_box, "position:x", _title_box.position.x + 40, 0.45)
	for i in _items.size():
		var item := _items[i]
		item.modulate.a = 0.0
		tw.tween_property(item, "modulate:a", 1.0, 0.18).set_delay(0.04 + i * 0.022)
		if item.get_parent() is Container:
			continue
		var home := item.position
		item.position = home + Vector2(-18, 8)
		tw.tween_property(item, "position", home, 0.24).set_delay(0.04 + i * 0.022)
	await get_tree().create_timer(0.22).timeout
	if not is_inside_tree() or Router._busy:
		return
	if _language_due():
		pass     # (already up, see _ready)
	elif _opening_due() and _first == null:
		_first_start()
	elif _starter_due():
		_open_starter()
	elif _items.size() > 0 and not _panel_open:
		_items[0].grab_focus()
	if "--focus-walk" in OS.get_cmdline_user_args():
		_focus_walk()


## Dev: walk the home screen with the arrow keys and print where focus goes, then quit.
func _focus_walk() -> void:
	var seen := {}
	print("FOCUS start ", get_viewport().gui_get_focus_owner(), " panel_open ", _panel_open)
	if get_viewport().gui_get_focus_owner() == null and _items.size() > 0:
		_items[0].grab_focus()
		await get_tree().process_frame
		print("FOCUS grabbed ", get_viewport().gui_get_focus_owner())
	for act in ["ui_down", "ui_down", "ui_right", "ui_right", "ui_down", "ui_right", "ui_down", "ui_right", "ui_right", "ui_right", "ui_right", "ui_up", "ui_up", "ui_up", "ui_left"]:
		await get_tree().create_timer(0.15).timeout
		var ev := InputEventAction.new()
		ev.action = act
		ev.pressed = true
		get_viewport().push_input(ev)
		await get_tree().process_frame
		var f := get_viewport().gui_get_focus_owner()
		var nm := "null"
		if f != null:
			nm = str(f.tooltip_text) if str(f.tooltip_text) != "" else f.get_class()
			if f is HomeTile:
				nm = "tile " + str((f as HomeTile).find_children("*", "Label", true, false)[1].text) if (f as HomeTile).find_children("*", "Label", true, false).size() > 1 else "tile"
			seen[f] = true
		print("FOCUS %s -> %s" % [act, nm])
	print("FOCUS distinct %d of %d items" % [seen.size(), _items.size()])
	get_tree().quit()


## The very first start, before anything else: which language. The menu is built again in it.
func _pick_language() -> void:
	_panel_open = true
	var lp := LanguagePick.new()
	lp.z_index = 200
	add_child(lp)


## Lumen says hello, once each time the game is started: a line in her box, and out loud in the voice
## you picked for her. She knows how your last duel went and whether she has new cards for you.
func _lumen_hello() -> void:
	if Voices.greeted or not Profile.created or not is_inside_tree():
		return
	Voices.greeted = true
	var line := Voices.hello_line(Profile.last_won, not Collection.lumen_news.is_empty())
	if _hello_box == null or not is_instance_valid(_hello_box):
		_hello_box = LumenBubble.new(26.0, -150.0)
		add_child(_hello_box)
	_hello_box.say(line, maxf(4.2, Voices.length("lumen", line) + 0.6))    # the bubble stays while she talks
	Voices.say("lumen", line, true, true)


## New cards of Lumen's came with the story since the last time the menu was up: say so.
func _lumen_news() -> void:
	Collection.lumen_gifts()
	if Collection.lumen_deck() or Collection.deck_news:
		Collection.deck_news = false
		Sfx.play("quest", -6.0)
		Router.toast(Loc.t("Lumen gave you her own deck: %s. It is in Decks, ready to play or change.") % Loc.t(CardData.deck_name("echo")), 7.0)
		Collection.lumen_news.clear()
		return
	if Collection.lumen_news.is_empty():
		return
	var names: Array = []
	for id in Collection.lumen_news:
		names.append(str(CardData.get_card(int(id)).get("name", "")))
	Collection.lumen_news.clear()
	Sfx.play("quest", -6.0)
	# (A long list is cut short: three names and how many more.)
	var shown := ", ".join(names.slice(0, 3)) + ((" " + Loc.t("and %d more") % (names.size() - 3)) if names.size() > 3 else "")
	Router.toast(Loc.t("Lumen has new cards for you: %s. They are in your collection.") % shown, 6.0)


## Your first deck is still to be chosen (and nothing else is open).
func _starter_due() -> bool:
	var args := str(OS.get_cmdline_user_args())
	if "--starter-pick" in args:
		return true
	return Collection.needs_starter() and not _panel_open and not "--shot" in args and not "--story" in args


func _open_starter() -> void:
	var sp := StarterPick.new()
	sp.z_index = 100
	add_child(sp)
	_panel_open = true
	sp.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


func _open_panel(p: SidePanel) -> void:
	_panel_open = true
	p.z_index = 100
	p.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## Free Roam starts with a choice of world: full screen, in the Academy door's look (0.69.1).
func _on_roam() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var gate := RoamGate.new()
	gate.z_index = 100
	add_child(gate)
	_panel_open = true
	gate.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## The side panel the Free Roam tile opened before 0.69.1 (kept for the tools that still call it).
func _on_roam_panel() -> void:
	var p := SidePanel.new("Free Roam", 640)
	p.z_index = 100
	var hint := UITheme.label("Pick a world. Inside, press G any time to jump to another one.", 18, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(hint)
	p.body.add_child(CityGuide.world_cards(func(key):
		if key == "highway":
			Router.go(Router.RIDE)
			return
		Router.roam["district"] = key
		Router.roam["free"] = true       # Free Roam is free: no chapter list, no story leads
		Router.roam["pos"] = null
		Router.roam.erase("yaw")
		Router.roam.erase("tod")
		Router.go(Router.ROAM)))
	add_child(p)
	_open_panel(p)


## The main story's door (0.69.0): full screen, in the Academy door's look.
func _on_story() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var gate := StoryGate.new()
	gate.z_index = 100
	add_child(gate)
	_panel_open = true
	gate.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## The side panel the Story tile opened before 0.69.0 (kept for the tools that still call it).
func _on_story_panel() -> void:
	var p := SidePanel.new("Story", 760)
	p.z_index = 100
	var pos := StoryProgress.position()
	if pos["chapter"] != "":
		var cont := Button.new()
		cont.text = "▶  Continue where you left off"
		cont.custom_minimum_size = Vector2(0, 72)
		cont.add_theme_font_size_override("font_size", 28)
		cont.pressed.connect(func(): StoryDirector.begin(str(pos["chapter"]), true))
		p.body.add_child(cont)
	SavesUI.story_block(p.body, self)
	p.add_section("Chapters")
	var unlocked := StoryProgress.unlocked()
	for c in StoryData.CHAPTERS:
		var ok: bool = unlocked.has(c["id"]) and StoryData.SCRIPTS.has(c["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 96)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s   ·   %s\n%s" % [Loc.t(c["title"]).to_upper(), c["era"], Loc.t(c["name"]) if ok else Loc.t("Locked" if StoryData.SCRIPTS.has(c["id"]) else "Coming soon")]
		b.add_theme_font_size_override("font_size", 24)
		b.disabled = not ok
		var id: String = c["id"]
		# A chapter in this list always starts from its first scene. Say so, and ask before
		# throwing away the place you are at in it (Continue is the way back to that).
		var mid: bool = ok and str(pos["chapter"]) == id and int(pos.get("step", 0)) > 0
		if ok:
			# On the right of the tile, where there is room for it at a readable size.
			var how := UITheme.label(Loc.t("You are here. Tapping starts it over.\nContinue picks up where you were.") if mid else Loc.t("Starts from the beginning"),
					18, UITheme.GOLD if mid else UITheme.TEXT_DIM, UITheme.semi_font())
			how.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
			how.offset_left = -340.0 if mid else -250.0
			how.offset_right = -22.0
			how.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			how.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			how.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(how)
			b.clip_text = true
		b.pressed.connect(func():
			if mid:
				SavesUI._ask(self, "Start this chapter over from its first scene? To pick up where you were, close this and use Continue.", "Start over", func(): StoryDirector.begin(id))
			else:
				StoryDirector.begin(id))
		p.body.add_child(b)
	p.add_section("Bond scenes")
	for bd in StoryData.BONDS:
		var who := str(Characters.get_char(str(bd["who"])).get("short", bd["who"]))
		var wins: int = Collection.versus(str(bd["who"]))[0]
		var open: bool = Saves.admin or (unlocked.has(bd["after"]) and wins >= int(bd["wins"]))
		var seen := StoryProgress.recalls("side_" + str(bd["id"]).substr(5))
		var bb := Button.new()
		bb.custom_minimum_size = Vector2(0, 64)
		bb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bb.add_theme_font_size_override("font_size", 22)
		if open:
			bb.text = "%s%s   ·   %s" % ["✔  " if seen else "", who, Loc.t(str(bd["name"]))]
		elif not unlocked.has(bd["after"]):
			bb.text = Loc.t("%s   ·   opens later in the story") % who
		else:
			bb.text = Loc.t("%s   ·   beat them %d times to open (%d so far)") % [who, int(bd["wins"]), wins]
		bb.disabled = not open
		var bid := str(bd["id"])
		bb.pressed.connect(func(): StoryDirector.begin(bid))
		p.body.add_child(bb)
	add_child(p)
	_open_panel(p)


func _on_saves() -> void:
	var m := SaveMenu.open(self)
	_panel_open = true
	m.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## After a load, or after the game closed without warning: say so, and offer to take you back
## to where you were (the story scene, or the spot in the world).
func _welcome_back() -> void:
	var crashed := Saves.crashed_last
	var loaded := Saves.just_loaded
	Saves.crashed_last = false
	Saves.just_loaded = ""
	if not crashed and loaded == "":
		return
	if _first != null and is_instance_valid(_first):
		return     # the opening is playing: nothing goes on top of it
	var where := Saves.place()
	var text := ""
	if crashed:
		text = Loc.t("The game closed without warning last time. Your progress is safe: it was saved as you played.")
		if Saves.crash_report != "":
			text += "\n\n" + Loc.t("A report of what happened was kept in Crossroads Data, in the Crash reports folder. Send it over and we can fix it.")
	else:
		text = Loc.t("%s is loaded.") % (Loc.t("AUTOSAVE") if loaded == "autosave" else (Loc.t("SAVE %d") % int(loaded.trim_prefix("slot"))).capitalize())
	var p := SidePanel.new("Welcome back" if crashed else "Save loaded", 700)
	p.z_index = 100
	var l := UITheme.label(text, 22, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.body.add_child(l)
	var pt := Saves.place_text()
	if not where.is_empty() and pt != "":
		var go := Button.new()
		# Two lines, and the place wraps: one long line here once pushed the whole panel off
		# the edge of the screen.
		go.text = "▶  " + Loc.t("Go back to where you were") + "\n" + pt
		go.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		go.custom_minimum_size = Vector2(0, 96)
		go.add_theme_font_size_override("font_size", 23)
		go.pressed.connect(func():
			Sfx.play("click", -6.0)
			if str(where.get("mode", "")) == "campus":
				Campus.go()
			elif str(where.get("mode", "")) == "story":
				StoryDirector.begin(str(where.get("chapter", "")), true)
			else:
				Router.roam = {"district": str(where.get("district", "domino")), "pos": Vector3(float(where.get("x", 0.0)), 0, float(where.get("z", 8.0))), "yaw": float(where.get("yaw", PI))}
				Router.go(Router.ROAM))
		p.body.add_child(go)
		go.grab_focus.call_deferred()
	var stay := Button.new()
	stay.text = Loc.t("Stay on the main menu")
	stay.custom_minimum_size = Vector2(0, 60)
	stay.pressed.connect(p.close)
	p.body.add_child(stay)
	add_child(p)


func _on_album() -> void:
	Sfx.play("click", -6.0)
	var a := CardAlbum.open(self)
	_panel_open = true
	a.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## Decks and cards (0.69.1): the full-screen door to your decks, the album and the card shops.
func _on_deck() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var gate := CardsGate.new()
	gate.z_index = 100
	add_child(gate)
	_panel_open = true
	gate.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## My decks straight away (after a lost story duel: fix the deck, then carry on).
func _on_deck_list() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var db := DeckMenu.new()
	db.z_index = 100
	add_child(db)
	_panel_open = true
	db.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## Every duel you played, to watch again (see Replays).
## Online (0.73.0): your Duel Group, the people in it, challenges.
func _on_online() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var os := OnlineScreen.new()
	os.z_index = 100
	add_child(os)
	_panel_open = true
	os.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


func _online_line() -> String:
	if Net.groups.is_empty():
		return Loc.t("Play online with friends.")
	return Loc.t("Group: %s") % str(Net.group().get("name", ""))      # (0.74.2: short, it has one line)


func _online_badge() -> String:
	if Net.is_owner() and Net.key_days_left() <= 7:
		return Loc.t("Key: %d days") % maxi(0, Net.key_days_left())
	var n := 0
	for p in Net.people():
		if bool(p["online"]):
			n += 1
	return (Loc.t("%d online") % n) if n > 0 else ""


func _on_replays() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var rl := ReplayList.new()
	rl.z_index = 100
	add_child(rl)
	_panel_open = true
	rl.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


func _on_settings() -> void:
	_open_panel(SettingsPanel.open(self))


func _on_quit() -> void:
	get_tree().quit()


## The highway's door (0.69.1): races, riders, the Grand Prix and the garage, then the ride.
func _on_turbo() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	Sfx.play("gong", -6.0)
	var gate := TurboGate.new()
	gate.z_index = 100
	add_child(gate)
	_panel_open = true
	gate.closed.connect(func():
		_panel_open = false
		if is_instance_valid(gate) and _items.size() > 1:
			_items[0].grab_focus())


## The Academy story's door (0.65.0). The mode from before opens from the bottom of it.
func _on_academy() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var gate := CampusGate.new()
	gate.z_index = 100
	add_child(gate)
	_panel_open = true
	gate.classic.connect(_on_academy_classic)
	gate.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


func _on_academy_classic() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var hub := AcademyHub.new()
	hub.z_index = 100
	add_child(hub)
	_panel_open = true
	hub.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


## The Free Duel Knockout: the bracket. `result` is "won" / "lost" when you are back from one of
## its duels, so the round can be settled on screen.
func _on_knockout(result: String) -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	var ks := KnockoutScreen.new()
	ks.result = result
	ks.z_index = 100
	add_child(ks)
	_panel_open = true
	ks.start.connect(func(cfg):
		Router.menu_open = "knockout"
		Router.match_state = {}
		Router.duel_config = cfg
		Router.go(Router.DUEL))
	ks.closed.connect(_on_free_duel)


func _on_free_duel() -> void:
	Router.busy()      # (a ring turns in the corner if this takes a moment)
	# The full Free Duel screen, straight away (the two duelists face to face, the roster, the setup).
	var cs := CharacterSelect.new()
	cs.z_index = 100
	add_child(cs)
	_panel_open = true
	cs.start.connect(func(cfg):
		if cfg.has("daily"):
			Router.menu_open = "select"      # the duel of the day comes back here
		Router.duel_config = cfg
		Router.go(Router.DUEL))
	cs.knockout.connect(func():
		cs.queue_free()
		_on_knockout(""))
	cs.online.connect(func():
		cs.queue_free()
		_on_online())
	cs.closed.connect(func():
		_panel_open = false
		if _items.size() > 1:
			_items[0].grab_focus())


# ------------------------------------------------------------------ the home screen (0.69.1)

var _home_cont: HomeTile = null
const HOME_X := 64.0
const HOME_W := 836.0


## The home screen: the title, a big Continue card that knows what you were doing last, and the
## modes as tiles with the game's own pictures (the same ones their own screens open on).
func _build_home() -> void:
	_title_box.scale = Vector2(0.8, 0.8)
	_title_box.position = Vector2(70, 146)
	_menu_box = Control.new()
	_menu_box.position = Vector2.ZERO
	_menu_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_box)
	Tournament.load_data()
	var won := 0
	for id in Tournament.DEFS:
		if Tournament.titles(str(id)) > 0:
			won += 1
	var cont := _continue_card()
	_home_cont = cont
	cont.position = Vector2(HOME_X, 290)
	_menu_box.add_child(cont)
	_items.append(cont)
	var story_pic := StoryGate.picture_of(StoryGate.district_of(_story_chapter()))
	var half := (HOME_W - 14.0) / 2.0
	var third := (HOME_W - 28.0) / 3.0
	var rows := [
		[476.0, 150.0, [
			["The main story", "STORY", _chapter_label(_story_chapter()), Color("ffb62e"), [story_pic], _on_story, ""],
			["A story of its own", "DUEL ACADEMY", Campus.summary() if Campus.started() else Loc.t("A school year on the island."), Color("e0533f"), [AcademyBackdrop.PICTURE], _on_academy, ""]]],
		[640.0, 124.0, [
			["Quick play", "FREE DUEL", "Any duelist, deck and field.", Color("8a6dff"), ["res://assets/ui/story_title_heartland.jpg"], _on_free_duel, ""],
			["Riding Duels", "TURBO DUEL", "Race the highway at speed.", Color("3fc6ff"), ["res://assets/ui/roam_title_highway.jpg"], _on_turbo, ""],
			["Open world", "FREE ROAM", "Five places to walk and duel.", Color("3fbf8a"), [_roam_picture()], _on_roam, ""]]],
		[778.0, 104.0, [
			["Four titles", "TOURNAMENTS", "Badges, brackets, trophies.", Color("ffd766"), ["res://assets/ui/story_title_newdomino.jpg"], _on_tournaments, "%d / %d" % [won, Tournament.DEFS.size()]],
			["With friends", "ONLINE", _online_line(), Color("2de2e6"), ["res://assets/ui/story_title_satellite.jpg"], _on_online, _online_badge()],
			["Your cards", "MY DECKS", "Build, rename, pick a deck.", Color("ff7ab8"), ["res://assets/ui/story_title_museum.jpg"], _on_deck, ""]]],
	]
	var grid: Array = [[cont]]
	for row in rows:
		var y: float = row[0]
		var h: float = row[1]
		var entries: Array = row[2]
		var w: float = half if entries.size() == 2 else third
		var x := HOME_X
		grid.append([])
		for e in entries:
			var tile := HomeTile.new(Loc.t(str(e[0])), Loc.t(str(e[1])), Loc.t(str(e[2])), e[3], e[4], Vector2(w, h), str(e[6]))
			tile.position = Vector2(x, y)
			tile.pressed.connect(e[5])
			tile.pressed.connect(func(): Sfx.play("click", -6.0))
			_menu_box.add_child(tile)
			_items.append(tile)
			(grid[grid.size() - 1] as Array).append(tile)
			x += w + 14.0
	var first_round := _items.size()
	_build_rounds()
	grid.append(_items.slice(first_round))
	_link_grid(grid)
	_link_grid_later(grid)


## Once the round buttons have been laid out, link them again by where they really are.
func _link_grid_later(grid: Array) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		_link_grid(grid)
		if _home_cont != null and _chip != null:
			_home_cont.focus_neighbor_top = _home_cont.get_path_to(_chip)


## Arrow keys and the stick move through the home screen as a grid: left and right stay in the row,
## up and down go to the tile above or below that is closest in line.
func _link_grid(grid: Array) -> void:
	for r in grid.size():
		var row: Array = grid[r]
		for i in row.size():
			var b: Control = row[i]
			b.focus_neighbor_left = b.get_path_to(row[i - 1] if i > 0 else b)
			b.focus_neighbor_right = b.get_path_to(row[i + 1] if i < row.size() - 1 else b)
			b.focus_neighbor_top = b.get_path_to(_closest(b, grid[r - 1]) if r > 0 else b)
			b.focus_neighbor_bottom = b.get_path_to(_closest(b, grid[r + 1]) if r < grid.size() - 1 else b)


func _closest(b: Control, row: Array) -> Control:
	var mid := b.global_position.x + b.size.x / 2.0
	var best: Control = row[0]
	var bd := INF
	for o in row:
		var c := o as Control
		var d := absf(c.global_position.x + c.size.x / 2.0 - mid)
		if d < bd:
			bd = d
			best = c
	return best


## The Free Roam tile's picture: the world you walked in last (Domino before you have been anywhere).
func _roam_picture() -> String:
	var where := Saves.place()
	var dk := str(where.get("district", "")) if str(where.get("mode", "")) == "roam" else ""
	if dk == "" or dk == "highway":
		dk = "domino"
	return StoryGate.picture_of(dk)


## The chapter the Story tile shows: where you are, or the newest you can start.
func _story_chapter() -> String:
	var where := Saves.place()
	if str(where.get("mode", "")) == "story" and StoryData.SCRIPTS.has(str(where.get("chapter", ""))):
		return str(where["chapter"])
	var pos := StoryProgress.position()
	if str(pos.get("chapter", "")) != "" and StoryData.SCRIPTS.has(str(pos["chapter"])):
		return str(pos["chapter"])
	var newest := str(StoryData.CHAPTERS[0]["id"])
	for c in StoryData.CHAPTERS:
		if StoryProgress.unlocked().has(c["id"]) and StoryData.SCRIPTS.has(c["id"]):
			newest = str(c["id"])
	return newest


## "Chapter 3: The Last Lap" for a chapter id.
func _chapter_label(id: String) -> String:
	for c in StoryData.CHAPTERS:
		if str(c["id"]) == id:
			return "%s: %s" % [Loc.t(str(c["title"])), Loc.t(str(c["name"]))]
	return ""


## How long ago, in words ("5 minutes ago", "yesterday").
func _ago(when: String) -> String:
	if when == "":
		return ""
	var then := Time.get_unix_time_from_datetime_string(when)
	var now := Time.get_unix_time_from_datetime_string(Time.get_datetime_string_from_system(false, true))
	var mins := int((now - then) / 60)
	if mins < 2:
		return Loc.t("Just now")
	if mins < 60:
		return Loc.t("%d minutes ago") % mins
	if mins < 120:
		return Loc.t("An hour ago")
	if mins < 60 * 24:
		return Loc.t("%d hours ago") % (mins / 60)
	if mins < 60 * 48:
		return Loc.t("Yesterday")
	return Loc.t("%d days ago") % (mins / (60 * 24))


## The big card on top: what you were doing last (a chapter of the story, a day at the Academy, a
## walk in one of the worlds), with that place's picture, and one press takes you back there.
## With nothing played yet it is the way in: the story's first chapter.
func _continue_card() -> HomeTile:
	var where := Saves.place()
	var mode := str(where.get("mode", ""))
	var over := ""
	var title := ""
	var sub := ""
	var pic := StoryGate.PICTURE
	var color := Color("ffb62e")
	var act := Callable()
	var ago := _ago(str(where.get("when", "")))
	if mode == "story" and StoryData.SCRIPTS.has(str(where.get("chapter", ""))):
		var ch := str(where["chapter"])
		var pos := StoryProgress.position()
		var step := int(pos.get("step", 0)) if str(pos.get("chapter", "")) == ch else 0
		var d := StoryGate.district_of(ch, step)
		pic = StoryGate.picture_of(d)
		over = Loc.t("Continue") + "  ·  " + Loc.t("Story")
		title = Saves.place_text()
		sub = StoryGate.world_name(d) + ("  ·  " + ago if ago != "" else "")
		act = func(): StoryDirector.begin(ch, true)
	elif mode == "campus" and Campus.started():
		pic = AcademyBackdrop.PICTURE
		color = Color("e0533f")
		over = Loc.t("Continue") + "  ·  " + Loc.t("Duel Academy")
		title = Loc.t("Day %d on the island") % Campus.day()
		sub = Campus.summary() + ("  ·  " + ago if ago != "" else "")
		act = func(): Campus.go()
	elif mode == "roam" and str(where.get("district", "")) != "":
		var dk := str(where["district"])
		pic = StoryGate.picture_of(dk)
		color = StoryGate.world_color(dk)
		over = Loc.t("Continue") + "  ·  " + Loc.t("Free Roam")
		title = StoryGate.world_name(dk)
		sub = Loc.t("Right where you left off") + ("  ·  " + ago if ago != "" else "")
		act = func():
			Router.roam = {"district": dk, "pos": Vector3(float(where.get("x", 0.0)), 0, float(where.get("z", 8.0))), "yaw": float(where.get("yaw", PI))}
			Router.go(Router.ROAM)
	else:
		var st := _story_line()
		pic = StoryGate.picture_of(StoryGate.district_of(_story_chapter()))
		over = Loc.t("Start here") + "  ·  " + Loc.t("Story")
		title = str(st[1])
		sub = Loc.t("A blank deck and every era of dueling.")
		act = _on_story
	var hint := "▶  " + (Loc.t("Begin") if over.begins_with(Loc.t("Start here")) else Loc.t("Continue"))
	var card := HomeTile.new(over, title, sub, color, [pic], Vector2(HOME_W, 172), "", true, hint)
	card.pressed.connect(func():
		Sfx.play("click", -6.0)
		act.call())
	return card


## Settings, rank and goals, the album, replays and Quit: round buttons in the corner.
func _build_rounds() -> void:
	var rounds := HBoxContainer.new()
	rounds.add_theme_constant_override("separation", 14)
	rounds.anchor_top = 1.0
	rounds.anchor_bottom = 1.0
	rounds.offset_left = 64
	rounds.offset_top = -112
	rounds.offset_bottom = -48
	add_child(rounds)
	var gear := RoundButton.new("gear", Comic.BLUE, 64.0)
	gear.tooltip_text = Loc.t("Settings")
	gear.focus_mode = Control.FOCUS_ALL
	gear.pressed.connect(_on_settings)
	rounds.add_child(gear)
	_items.append(gear)
	var goals := RoundButton.new("goals", Comic.BLUE, 64.0)
	goals.tooltip_text = Loc.t("Rank and goals")
	goals.focus_mode = Control.FOCUS_ALL
	var left := 0
	for r in Goals.daily_rows():
		if not r["done"]:
			left += 1
	goals.badge = left
	goals.pressed.connect(_on_goals)
	rounds.add_child(goals)
	_items.append(goals)
	var album := RoundButton.new("album", Comic.BLUE, 64.0)
	album.tooltip_text = Loc.t("Card Album")
	album.focus_mode = Control.FOCUS_ALL
	album.pressed.connect(_on_album)
	rounds.add_child(album)
	_items.append(album)
	var reps := RoundButton.new("replay", Comic.BLUE, 64.0)
	reps.tooltip_text = Loc.t("Replays")
	reps.focus_mode = Control.FOCUS_ALL
	reps.pressed.connect(_on_replays)
	rounds.add_child(reps)
	_items.append(reps)
	if OS.has_feature("pc"):
		var quit := RoundButton.new("power", Comic.RED, 64.0)
		quit.tooltip_text = Loc.t("Quit")
		quit.focus_mode = Control.FOCUS_ALL
		quit.pressed.connect(_on_quit)
		rounds.add_child(quit)
		_items.append(quit)
	_rounds_end = 64.0 + rounds.get_child_count() * 64.0 + maxi(rounds.get_child_count() - 1, 0) * 14.0


## (dev: --open=select-old, the same screen.)
func _on_free_duel_setup() -> void:
	_on_free_duel()


## While the menu sits there, the card shops' pack covers are worked out a few milliseconds a frame
## (once a game version and card set: then they are read from disk), so the shops page never waits.
var _idle_t := 0.0
func _process(delta: float) -> void:
	_idle_t += delta
	if _idle_t > 3.0 and not Collection.covers_ready():
		Collection.cover_step(3.0)

