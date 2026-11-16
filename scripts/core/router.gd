extends CanvasLayer
## Scene changes with a fade, toast messages, and data passed between scenes.

const MAIN_MENU := "res://scenes/main_menu.tscn"
const DUEL := "res://scenes/duel.tscn"
const STORY := "res://scenes/story.tscn"
const ROAM := "res://scenes/roam.tscn"
const RIDE := "res://scenes/turbo_ride.tscn"

## Free roam: where you are and what just happened there.
var roam := {"district": "domino", "pos": null, "last_duel": "", "result": ""}

## Story position handed between the story player and story duels.
var story := {}
var story_result := ""
var last_stats := {}      # the last duel, for whoever started it: {won, lp, turns, low}

## Set by the menu before starting a duel.
var duel_config := {"player_deck": "yugi", "opponent_deck": "kaiba"}
## Set before going to the main menu to land on a screen there ("select" = Free Duel setup).
var menu_open := ""
## A best-of-3 Match in progress: {"wins": [you, them], "game": n, "last_loser": 0/1, "orig": {main, side}}.
var match_state := {}

var _fade: ColorRect
var _toast: Label
var _busy := false
var _fps: Label


var _perf_t := 0.0
var _perf_full := false
var _probe_t := 0.0


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	Settings.hold_tick(delta, cam != null and not _busy)
	_fps.visible = Settings.show_fps
	_perf_t += delta
	if _fps.visible and _perf_t > 0.25:
		_perf_t = 0.0
		var line := Loc.t("%d FPS") % Engine.get_frames_per_second()
		if _perf_full:
			# The numbers that say where the time goes. F3 shows and hides them.
			var vp := get_viewport()
			var rid := vp.get_viewport_rid()
			var px := Vector2(vp.size) * vp.scaling_3d_scale
			line += "   CPU %.1f ms   GPU %.1f ms" % [RenderingServer.viewport_get_measured_render_time_cpu(rid), RenderingServer.viewport_get_measured_render_time_gpu(rid)]
			line += "\n%d draws   %dk triangles   %d objects" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)]
			line += "\n3D %dx%d (%d%%)   %s   %s" % [int(px.x), int(px.y), int(vp.scaling_3d_scale * 100.0), Settings.gfx_preset_name(), RenderingServer.get_current_rendering_method()]
			line += "\nslowest frame %.1f ms   physics %.1f ms   nodes %d" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))]
			if _click_ms >= 0.0:
				line += "\nlast click answered in %.0f ms" % _click_ms
		else:
			line += "   (F3)"
		_fps.text = line
	if _probe:
		_probe_t += delta
		if _probe_t > 3.0:
			_probe_t = 0.0
			print("PERF draws ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " tris ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
				" objects ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), " nodes ", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))


var _probe := false

# How long the game takes to answer a click: from the press arriving to the end of the frame
# that draws the answer. Shown in the F3 readout. (What the screen adds after that is not ours.)
var _click_at := 0
var _click_ms := -1.0
var _click_wait := false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _click_wait:
		_click_at = Time.get_ticks_usec()
		_click_wait = true
		RenderingServer.frame_post_draw.connect(_click_drawn, CONNECT_ONE_SHOT)


func _click_drawn() -> void:
	_click_ms = (Time.get_ticks_usec() - _click_at) / 1000.0
	_click_wait = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		if not Settings.show_fps:
			Settings.show_fps = true
			_perf_full = true
		elif not _perf_full:
			_perf_full = true
		else:
			_perf_full = false
			Settings.show_fps = false
		Settings.save_settings()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		PerfReport.start(get_tree())


func _ready() -> void:
	# One look everywhere: the game's theme becomes the default for every control, also the
	# ones on screens that never set a theme of their own.
	ThemeDB.get_default_theme().merge_with(UITheme.build())
	get_tree().node_added.connect(_on_node_added)
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.01, 0.02, 0.04, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_load_l = Label.new()
	_load_l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_load_l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_load_l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_load_l.offset_right = -56
	_load_l.offset_bottom = -44
	_load_l.add_theme_font_override("font", load("res://assets/fonts/Rajdhani-SemiBold.ttf"))
	_load_l.add_theme_font_size_override("font_size", 30)
	_load_l.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_load_l.visible = false
	_fade.add_child(_load_l)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position.y -= 140
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.add_theme_font_override("font", load("res://assets/fonts/Rajdhani-SemiBold.ttf"))
	_toast.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.052, 0.098, 0.185, 0.92)
	sb.border_color = Color(0.17, 0.89, 0.9, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_toast.add_theme_stylebox_override("normal", sb)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	_probe = "--perf-probe" in OS.get_cmdline_user_args()
	if "--unlock-audit" in OS.get_cmdline_user_args():
		# Dev: what a player at this point of the story can reach.
		var w := []
		for k in Unlocks.WORLD_STAGE:
			w.append("%s=%s" % [k, Unlocks.world(k)])
		var pk := []
		for k in ["Duel Monsters", "Vault", "GX", "5D's", "ZEXAL", "dragons"]:
			pk.append("%s=%s" % [k, Unlocks.pack(k)])
		var op := 0
		for k in Characters.ORDER:
			op += 1 if Unlocks.opponent(k) else 0
		print("UNLOCKS stage=", Unlocks.stage(), " wins=", Unlocks.wins(), " worlds ", w, " packs ", pk, " free duel opponents ", op, "/", Characters.ORDER.size(),
			" admin=", Saves.admin, " cards=", Collection.owned.size(), " playable=", Collection.every_playable().size(), " data=", Saves.data_dir())
	if "--save-test" in OS.get_cmdline_user_args():
		# Dev: write slot 1, say what is in it, and ask for it to be loaded on the next run.
		_save_test.call_deferred()
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_fps = Label.new()
	_fps.position = Vector2(12, 8)
	_fps.add_theme_font_size_override("font_size", 18)
	_fps.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_fps.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps.add_theme_constant_override("outline_size", 6)
	_fps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fps)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.8).set_delay(0.15)
	_debug_args()


## Dev helpers: `-- --shot=/tmp/a.png --after=3 [--duel]` saves a screenshot and quits.
func _debug_args() -> void:
	var shot := ""
	var after := 3.0
	var duel := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
		elif a.begins_with("--after="):
			after = float(a.substr(8))
		elif a == "--duel":
			duel = true
		elif a.begins_with("--assets="):
			Settings.card_folder = a.substr(9)
			Cards.clear_cache()
			Portraits.clear_cache()
		elif a.begins_with("--district="):
			roam["district"] = a.substr(11)
		elif a.begins_with("--tod="):
			roam["tod"] = a.substr(6)
		elif a.begins_with("--clips="):
			# Which animations does this character's model end up with? (checks dropped-in files)
			var ck := a.substr(8)
			var cm := Avatars.load_model(ck)
			var cap := Avatars.anim_player(cm) if cm else null
			print("CLIPS ", ck, " file=", Avatars.path_for(ck), " -> ", cap.get_animation_list() if cap else "no animation player",
					"  idle=", Avatars.clip(cap, "idle") if cap else "", " walk=", Avatars.clip(cap, "walk") if cap else "",
					" run=", Avatars.clip(cap, "run") if cap else "", " victory=", Avatars.clip(cap, "victory") if cap else "")
			if cm:
				cm.free()
		elif a.begins_with("--gfx="):
			Settings.graphics = int(a.substr(6))
		elif a.begins_with("--gfxset="):
			# Dev: single graphics values on top of the preset, e.g. --gfxset=gi:1,shadows:2
			for kv in a.substr(9).split(","):
				var k := kv.get_slice(":", 0)
				var v := kv.get_slice(":", 1)
				if Settings.gfx.has(k):
					Settings.set_gfx(k, (v == "1" or v == "true") if typeof(Settings.gfx[k]) == TYPE_BOOL else int(v))
		elif a == "--roam":
			await get_tree().process_frame
			go(ROAM)
		elif a.begins_with("--coat="):
			duel_config["opponent_coat"] = a.trim_prefix("--coat=")      # dev: the rival in a dorm jacket
		elif a.begins_with("--my-coat="):
			duel_config["player_coat"] = a.trim_prefix("--my-coat=")
		elif a.begins_with("--opp="):
			duel_config["opponent"] = a.substr(6)
		elif a == "--turbo":
			duel_config["turbo"] = true
		elif a.begins_with("--speed-start="):
			# Dev: Speed Counters each side starts a Turbo Duel with, e.g. --speed-start=3,1
			duel_config["speed_start"] = [int(a.trim_prefix("--speed-start=").get_slice(",", 0)), int(a.trim_prefix("--speed-start=").get_slice(",", 1))]
		elif a.begins_with("--first-turn="):
			duel_config["first_turn"] = int(a.trim_prefix("--first-turn="))
		elif a.begins_with("--puzzle="):
			duel_config["puzzle"] = a.substr(9)   # dev: start a duel puzzle
			duel_config["opponent"] = "professor"
		elif a == "--parse-all":
			# Dev: load every script so a parse error anywhere shows up, then quit.
			var todo: Array = ["res://scripts"]
			var count := 0
			while not todo.is_empty():
				var dir: String = todo.pop_back()
				for sub in DirAccess.get_directories_at(dir):
					todo.append(dir + "/" + sub)
				for f in DirAccess.get_files_at(dir):
					if f.ends_with(".gd"):
						count += 1
						if load(dir + "/" + f) == null:
							print("PARSE FAIL ", dir, "/", f)
			print("PARSE checked ", count, " scripts")
			get_tree().quit()
		elif a.begins_with("--lp="):
			duel_config["lp"] = int(a.substr(5))
		elif a.begins_with("--oppdeck="):
			duel_config["opponent_deck"] = a.substr(10)
		elif a == "--gauntlet":
			duel_config["gauntlet"] = {"all": ["kaiba", "joey", "mai"], "left": ["joey", "mai"], "stage": 1, "total": 3}
		elif a == "--ride":
			go(RIDE)
		elif a.begins_with("--story="):
			var parts := a.substr(8).split(":")
			await get_tree().create_timer(0.5).timeout
			if parts.size() > 1:
				StoryProgress.save_position(parts[0], int(parts[1]), {})
				StoryDirector.begin(parts[0], true)
			else:
				StoryDirector.begin(parts[0])
		elif a.begins_with("--deck-dump="):
			# (testing) what a named deck really comes out as: every card it lists, whether it
			# resolved, whether its rules are exact, and the final forty.
			var dk := a.substr(12)
			var want: Dictionary = CardData.NAMED_DECKS.get(dk, {}).get("cards", {})
			var got: Array[int] = CardData.deck_list(dk)
			var have := {}
			for id in got:
				have[id] = int(have.get(id, 0)) + 1
			var asked := 0
			for n in want:
				asked += int(want[n])
				var id: int = CardData.NAME_TO_ID.get(str(n).to_lower(), 0)
				var d := CardData.get_card(id) if id != 0 else {}
				var note := "OK" if id != 0 and int(have.get(id, 0)) == int(want[n]) and CardExact.ok(d) else "PROBLEM"
				print("DECK ", dk, " ", note, "  ", n, " x", want[n], "  id ", id, "  in deck ", have.get(id, 0), "  exact ", CardExact.ok(d) if id != 0 else false,
						"  ", d.get("kind", "?"), " L", d.get("level", "-"), " ", d.get("atk", "-"))
			print("DECK ", dk, " asked ", asked, " final ", got.size())
			for id2 in have:
				var d2 := CardData.get_card(int(id2))
				print("FINAL ", dk, "|", d2.get("name", "?"), "|", have[id2], "|", d2.get("kind", "?"), "|", int(d2.get("level", 0)), "|", int(d2.get("atk", 0)))
		elif a.begins_with("--card-sheet="):
			# (testing) card faces side by side, as the game draws them: --card-sheet=id,id,...
			await get_tree().create_timer(1.0).timeout
			var layer := CanvasLayer.new()
			layer.layer = 90
			add_child(layer)
			var bg := ColorRect.new()
			bg.color = Color(0.06, 0.08, 0.13)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			layer.add_child(bg)
			var ids := a.substr(13).split(",")
			var per_row := ids.size() if ids.size() <= 4 else (4 if ids.size() <= 8 else 6)
			var view: Vector2 = get_viewport().get_visible_rect().size
			var cw := minf((view.x - 20.0) / per_row - 10.0, ((view.y - 16.0) / ceilf(ids.size() / float(per_row)) - 8.0) * 420.0 / 612.0)
			for i in ids.size():
				var face := TextureRect.new()
				face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				face.texture = Cards.get_face(int(ids[i]))
				face.size = Vector2(cw, cw * 612.0 / 420.0)
				face.position = Vector2(12 + (i % per_row) * (cw + 10.0), 8 + (i / per_row) * (cw * 612.0 / 420.0 + 8.0))
				layer.add_child(face)
		elif a.begins_with("--field="):
			duel_config["field"] = a.substr(8)
		elif a.begins_with("--deck="):
			duel_config["player_deck"] = a.substr(7)
		elif a.begins_with("--open="):
			var what := a.substr(7)
			await get_tree().create_timer(1.2).timeout
			var menu := get_tree().current_scene
			if what == "select":
				menu._on_free_duel()
			elif what == "daily-play":
				# Straight into today's duel, the way the Free Duel card starts it.
				menu_open = "select"
				duel_config = (Knockout.daily()["cfg"] as Dictionary).duplicate(true)
				go(DUEL)
			elif what.begins_with("knockout-play"):
				# A fresh bracket and straight into its first duel (with --end-test --auto-story it
				# comes back to the bracket by itself).
				Knockout.start(int(what.get_slice(":", 1)) if ":" in what else 1)
				menu_open = "knockout"
				duel_config = Knockout.duel_config()
				go(DUEL)
			elif what.begins_with("knockout"):
				# --open=knockout            the setup, or the bracket on disk
				# --open=knockout:2:wwl      a fresh Normal bracket, two wins played, the last one shown coming in
				var kp := what.split(":")
				var last := ""
				if kp.size() >= 2:
					Knockout.start(int(kp[1]))
					var marks := kp[2] if kp.size() >= 3 else ""
					for i in marks.length():
						if i == marks.length() - 1:
							last = "won" if marks[i] == "w" else "lost"
						else:
							Knockout.report(marks[i] == "w")
				menu._on_knockout(last)
			elif what.begins_with("academy"):
				Academy.load_data()
				if what != "academy":
					Academy.d["enrolled"] = true
					Academy.d["dorm"] = 1 if "yellow" in what or "tourney" in what else (2 if "blue" in what else 0)
					Academy.d["day"] = 2
					Academy.d["wins"] = 1
					Academy.d["log"] = [true, false]
					Academy.d["merits"] = 7
					Academy.d["merit_prizes"] = 1
					Academy.d["dorm_pts"] = 5
					Academy.d["dorm_days"] = 4
					Academy.d["week_assign"] = 1
					if "tourney" in what:
						Academy.tourney_new()
				menu._on_academy()
			elif what == "me":
				menu._open_panel(SettingsPanel.open_profile(menu, func(): menu._open_profile(false)))
			elif what == "profile":
				menu._open_profile(true)
			elif what == "tournaments":
				menu._on_tournaments()
			elif what == "tournaments-demo":
				# Dev: one tournament at each step, for a picture (not saved).
				Tournament.load_data()
				Tournament.st("domino").merge({"stage": "qualify", "badges": 4}, true)
				Tournament.start_finals("academy")
				Tournament.st("turbo").merge({"stage": "won", "titles": 1}, true)
				Tournament._loaded = true
				menu._on_tournaments()
			elif what == "builder":
				menu._on_deck()
				await get_tree().create_timer(0.5).timeout
				for n in menu.find_children("*", "", true, false):
					if n is DeckMenu:
						n._edit(0)
						break
			elif what == "deck":
				menu._on_deck()
			elif what == "settings":
				menu._on_settings()
			elif what.begins_with("story"):
				menu._on_story()
				if what == "storysaves":
					# Dev: scroll the story panel down to the saves.
					await get_tree().create_timer(0.4).timeout
					for n in menu.find_children("*", "ScrollContainer", true, false):
						(n as ScrollContainer).scroll_vertical = 100000
			elif what == "settingsend":
				menu._on_settings()
				await get_tree().create_timer(0.4).timeout
				for n in menu.find_children("*", "ScrollContainer", true, false):
					(n as ScrollContainer).scroll_vertical = 100000
			elif what.begins_with("deckshop"):
				var ds := DeckShop.new()
				ds.z_index = 100
				menu.add_child(ds)
				if what.ends_with("2"):
					ds._show_tab.call_deferred(1)
			elif what.begins_with("packs") or what == "packopen":
				var ps := PackShop.new()
				ps.z_index = 100
				menu.add_child(ps)
				if what.length() == 6:
					ps._show_tab.call_deferred(int(what.substr(5)))
				if what == "packopen":
					Collection.dp += 500
					await get_tree().create_timer(0.6).timeout
					ps._open(Collection.PACKS[0])
		elif a.begins_with("--perf="):
			# Dev: run the performance test after this many seconds, then quit.
			await get_tree().create_timer(float(a.substr(7))).timeout
			PerfReport.start(get_tree())
			while PerfReport.running:
				await get_tree().create_timer(0.5).timeout
			get_tree().quit()
		elif a.begins_with("--speed="):
			Settings.anim_speed = float(a.substr(8))
	if duel:
		await get_tree().process_frame
		go(DUEL)
	if shot != "":
		await get_tree().create_timer(after).timeout
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--hide="):          # dev: hide every node of these classes before the shot
				var kinds := a.substr(7).split(",")
				for n in get_tree().root.find_children("*", "", true, false):
					if n.get_class() in kinds or (n.get_script() and str((n.get_script() as Script).get_global_name()) in kinds):
						if n is WorldEnvironment:
							(n as WorldEnvironment).environment = null
						elif n is Node3D:
							(n as Node3D).visible = false
				await get_tree().create_timer(1.5).timeout
		if "--unfight-scan" in OS.get_cmdline_user_args():     # dev: list surfaces lying on top of each other, change nothing
			print("UNFIGHT SCAN finds ", PerfPass.unfight(get_tree().root, true, true))
		if DisplayServer.get_name() != "headless":
			var img := get_viewport().get_texture().get_image()
			img.save_png(shot)
			print("SHOT draws ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " tris ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " objects ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
			print("screenshot saved: ", shot)
		else:
			print("headless run finished")
		get_tree().quit()


func go(path: String) -> void:
	if _busy:
		return
	_busy = true
	Settings.hold_gave_up = false      # a new place: "hold the frame rate" may try again there
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.09)
	await tw.finished
	get_tree().paused = false
	# (Said before the place is even built, so whatever starts in it can wait for it.)
	loading = path in [ROAM, RIDE] and DisplayServer.get_name() != "headless"
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	if loading:
		await _settle()
	# The new screen takes clicks straight away; the fade-in is only for the eye.
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.22)


## True while a place is still getting ready behind the dark screen (see _settle).
var loading := false
var _load_l: Label


## A big place does a lot in its first seconds: the graphics chip builds the shaders it has
## never used, the people's motions are fitted to their bodies. Shown as it happened, that was
## a slideshow (2 FPS for five seconds on a machine that then runs at 200). So the dark screen
## stays until the frames come evenly, with a word on it, and for 7 seconds at the most.
func _settle() -> void:
	if DisplayServer.get_name() == "headless":
		return
	loading = true
	var t0 := Time.get_ticks_msec()
	var last := t0
	var recent: Array[float] = []
	while true:
		await get_tree().process_frame
		var now := Time.get_ticks_msec()
		recent.append(float(now - last))
		last = now
		if recent.size() > 12:
			recent.pop_front()
		var el := now - t0
		if el > 900 and _load_l != null and not _load_l.visible:
			_load_l.text = Loc.t("Loading")
			_load_l.visible = true
		if el > 7000:
			break
		if el > 300 and recent.size() >= 12:
			var lo := 1e9
			var hi := 0.0
			for f in recent:
				lo = minf(lo, f)
				hi = maxf(hi, f)
			# Even: the slowest of the last twelve frames is not far off the fastest.
			if hi < maxf(34.0, lo * 2.2):
				break
	if _load_l:
		_load_l.visible = false
	loading = false


func toast(message: String, hold := 1.8) -> void:
	_toast.text = message
	_toast.reset_size()
	_toast.position.x = (_toast.get_viewport_rect().size.x - _toast.size.x) / 2.0
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(hold)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


## Plain toggle buttons (a word, nothing inside, no look of their own) become choice chips.
func _on_node_added(n: Node) -> void:
	if (n is GeometryInstance3D or n is WorldEnvironment) and ShaderFix.active():
		# The game's own shaders are made to match on both renderers (see ShaderFix). Now for
		# what is already on the node, and once more a frame later for what is put on it next.
		ShaderFix.node(n)
		ShaderFix.node_later.call_deferred(n.get_instance_id())
	if n is BaseButton and not (n is OptionButton):
		# Every button answers on the press, not on the release: taps feel instant.
		(n as BaseButton).action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	if n.get_class() == "Button":
		_chip_later.call_deferred(n)


func _chip_later(n: Node) -> void:
	if not is_instance_valid(n):
		return
	var b := n as Button
	if b.toggle_mode and b.text != "" and b.get_child_count() == 0 and not b.has_theme_stylebox_override("normal"):
		UITheme.chip(b)


func _save_test() -> void:
	print("SAVETEST dir=", Saves.saves_dir(), " game_dir=", Saves.game_dir(), " saved=", Saves.save_to("slot1"), " info=", Saves.info("slot1"), " admin=", Saves.admin, " diff=", Saves.story_difficulty())
	var f := FileAccess.open(Saves.PENDING, FileAccess.WRITE)
	f.store_string("load:slot1")
	f.close()
	get_tree().quit()
