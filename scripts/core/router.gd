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
var last_stats := {}      # the last duel, for whoever started it: {won, lp, turns, low, directs, summons}

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
	if _busy_since != 0:
		_busy_frames -= 1
		if _busy_frames <= 0:
			_busy_end()
	if _frame_log and loading and Time.get_ticks_msec() - _pulse_last > 80:
		print("DRAWGAP %d ms (frame)" % (Time.get_ticks_msec() - _pulse_last))
	_pulse_last = Time.get_ticks_msec()
	_pulse_seen = _pulse_last
	_stall_watch(delta)
	if _frame_log:
		# (by the clock, not by delta: the engine caps delta, so a 2 second frame read as 130 ms)
		var now_us := Time.get_ticks_usec()
		var real := (now_us - _frame_last) / 1000.0
		_frame_last = now_us
		_frame_n += 1
		if real > float(OS.get_environment("FRAME_LOG_MS") if OS.get_environment("FRAME_LOG_MS") != "" else "60"):
			print("SLOWFRAME %.0f ms  t=%.1f  n=%d busy=%s loading=%s  process %.1f ms physics %.1f ms  nodes %d  draws %d" % [real, Time.get_ticks_msec() / 1000.0, _frame_n, _busy, loading,
					Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
					int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	if _probe:
		_probe_t += delta
		if _probe_t > 3.0:
			_probe_t = 0.0
			print("PERF draws ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " tris ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
				" objects ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), " nodes ", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))


var opening_shown := false     # the menu has been up once since the game started
var _probe := false
var _frame_log := "--frame-log" in OS.get_cmdline_user_args()   # dev: say every slow frame
var _frame_last := 0
var _frame_n := 0

# How long the game takes to answer a click: from the press arriving to the end of the frame
# that draws the answer. Shown in the F3 readout. (What the screen adds after that is not ours.)
var _click_at := 0
var _click_ms := -1.0
var _click_wait := false


# A note next to the saves whenever the game runs like a slideshow (frames slower than a
# quarter second while nothing is loading): where, how long after the place opened, how bad.
# It is there so a stall on a machine nobody can look at can be read afterwards.
var _stall_n := 0
var _stall_worst := 0.0
var _stall_t := 0.0
var _scene_age := 0.0
var _scene_was := ""

func _stall_watch(delta: float) -> void:
	var here := str(get_tree().current_scene.scene_file_path) if get_tree().current_scene != null else ""
	if here != _scene_was:
		_scene_was = here
		_scene_age = 0.0
	_scene_age += delta
	if delta > 0.25 and not _busy and not loading:
		_stall_n += 1
		_stall_worst = maxf(_stall_worst, delta)
	_stall_t += delta
	if _stall_t < 5.0:
		return
	_stall_t = 0.0
	if _stall_n >= 2 and not "--no-report" in OS.get_cmdline_user_args():
		var path := Saves.saves_dir().path_join("stall_log.txt")
		var old_text := FileAccess.get_file_as_string(path)
		var lines := old_text.split("\n", false)
		var vp := get_viewport()
		lines.append("%s  v%s  %s  %s  %d frames slower than 0.25 s in 5 s, worst %.1f s, %.0f s after the place opened  CPU %.0f ms GPU %.0f ms  %s" % [
			Time.get_datetime_string_from_system(false, true), str(ProjectSettings.get_setting("application/config/version", "?")), here.get_file(),
			str(roam.get("district", "")), _stall_n, _stall_worst, _scene_age,
			RenderingServer.viewport_get_measured_render_time_cpu(vp.get_viewport_rid()), RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid()), Settings.gfx_preset_name()])
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lines.slice(maxi(0, lines.size() - 80))) + "\n")
			f.close()
	_stall_n = 0
	_stall_worst = 0.0


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
	apply_own_icon.call_deferred()
	# (a note next to the saves: did the rules engine load on this computer?)
	get_tree().create_timer(1.5).timeout.connect(func():
		if not "--no-report" in OS.get_cmdline_user_args():
			OcgReport.boot())
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
	_card = LoadCard.new()
	_card.visible = false
	_fade.add_child(_card)
	# Hover hints in the look of the game (they used to be the engine's plain grey box).
	var tips := Theme.new()
	var tip_box := StyleBoxFlat.new()
	tip_box.bg_color = Color(0.045, 0.085, 0.165, 0.97)
	tip_box.border_color = Color(0.17, 0.89, 0.9, 0.55)
	tip_box.set_border_width_all(1)
	tip_box.set_corner_radius_all(10)
	tip_box.content_margin_left = 16
	tip_box.content_margin_right = 16
	tip_box.content_margin_top = 9
	tip_box.content_margin_bottom = 9
	tip_box.shadow_color = Color(0, 0, 0, 0.45)
	tip_box.shadow_size = 8
	tips.set_stylebox("panel", "TooltipPanel", tip_box)
	tips.set_font("font", "TooltipLabel", load("res://assets/fonts/Rajdhani-SemiBold.ttf"))
	tips.set_font_size("font_size", "TooltipLabel", 20)
	tips.set_color("font_color", "TooltipLabel", Color(0.9, 0.95, 1.0))
	get_tree().root.theme = tips
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
	# A ring that turns while something is being got ready (see busy()). Drawn once here, shown by its
	# alpha: what is already drawn can be moved from inside long work, where nothing new can be drawn.
	_spin = LoadCard._Ring.new()
	_spin.size = Vector2(84, 84)
	_spin.pivot_offset = Vector2(42, 42)
	_spin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_spin.offset_left = -150
	_spin.offset_top = -150
	_spin.offset_right = -66
	_spin.offset_bottom = -66
	_spin.modulate.a = 0.0
	add_child(_spin)
	_boot_tw = create_tween()
	_boot_tw.tween_property(_fade, "color:a", 0.0, 0.8).set_delay(0.15)
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
		elif a.begins_with("--shots="):
			# Dev: a screenshot every half second to /tmp/<prefix>_NNN.png, plus a line in the log
			# for every frame that took over 100 ms (for watching the game while something else
			# types into it).
			var prefix := a.substr(8)
			var hb := func():
				var k := 0
				var last := Time.get_ticks_msec()
				var next_shot := last + 500
				while true:
					await get_tree().process_frame
					var now := Time.get_ticks_msec()
					if now - last > 100:
						print("SLOW FRAME %d ms" % (now - last))
					last = now
					if now >= next_shot:
						next_shot = now + 500
						print("FRAME ALIVE %d" % now)
						get_viewport().get_texture().get_image().save_png("/tmp/%s_%03d.png" % [prefix, k])
						k += 1
			hb.call()
		elif a.begins_with("--menu-open="):
			menu_open = a.substr(12)   # dev: open the main menu on one of its panels (select, decks...)
		elif a == "--duel":
			duel = true
		elif a.begins_with("--dump-deck-cards="):
			# Dev: every card any deck in the game plays, with its text (for translating).
			var seen := {}
			var out := FileAccess.open(a.trim_prefix("--dump-deck-cards="), FileAccess.WRITE)
			var keys: Array = CardData.DECKS.keys()
			for k in CardData.ADDONS.keys():
				if not keys.has(k):
					keys.append(k)
			for dk in keys:
				var lst := CardData.deck_list(str(dk))
				if lst.size() > 80:
					print("BIGDECK ", dk, " ", lst.size())
					continue
				for id in lst:
					if seen.has(id):
						continue
					seen[id] = true
					var d := CardData.get_card(id)
					var tx := str(d.get("desc", d.get("text", "")))
					if tx == "":
						tx = str(CardData.EXT.get(id, {}).get("desc", ""))
					out.store_line(JSON.stringify({"id": id, "name": d.get("name", ""), "desc": tx, "decks": 1}))
			for id in Collection.all_cards():
				if not seen.has(id):
					seen[id] = true
					var d2 := CardData.get_card(id)
					out.store_line(JSON.stringify({"id": id, "name": d2.get("name", ""), "desc": str(d2.get("desc", d2.get("text", ""))), "decks": 2}))
			for id in CardData.EXT.keys():
				if not seen.has(id):
					seen[id] = true
					out.store_line(JSON.stringify({"id": id, "name": CardData.EXT[id].get("name", ""), "desc": CardData.EXT[id].get("desc", ""), "decks": 0}))
			out.close()
			print("DUMPED ", seen.size())
			get_tree().quit()
		elif a == "--show-test":
			# Dev: every summon show and attack strike, one after another, then quit.
			await get_tree().create_timer(1.0).timeout
			var host := Node.new()
			get_tree().root.add_child(host)
			var only := OS.get_environment("SHOW_ONLY")
			for nm in SummonShow.SIGNATURE.keys():
				if only != "" and not str(nm).contains(only):
					continue
				print("SHOWGO ", nm, " ", Time.get_ticks_msec())
				var cd := {"name": nm, "id": 0, "atk": 2500, "level": 6, "attribute": "DARK"}
				SummonShow.play(host, cd, false)
				for i in 40:
					await get_tree().process_frame
					if i % 5 == 0:
						print("SHOWFRAME ", i, " ", Time.get_ticks_msec())
				SummonShow.strike(host, cd, true)
				for i in 70:
					await get_tree().process_frame
				print("SHOWOK ", nm)
			print("SHOW DONE")
			get_tree().quit()
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
		elif a == "--esc-test":
			_esc_test()      # dev: at the story's first goal, Esc, Resume, Esc, Main Menu, and say what happened
		elif a == "--class-desk":
			# Dev: the Deck Building class's desk by itself, half filled, for a picture.
			get_tree().create_timer(2.5).timeout.connect(func():
				var layer := CanvasLayer.new()
				layer.layer = 80
				add_child(layer)
				var desk := ClassBuild.new(CampusClasses.pool(6100))
				layer.add_child(desk)
				await get_tree().create_timer(0.5).timeout
				desk._fill()
				for id in desk.pool.slice(0, 4):
					desk._toggle(int(id))
				print("CLASS DESK ", desk.pool.size(), " cards, chosen ", desk._in.size()))
		elif a == "--toast-test":
			# Dev: a very long message, to see that it wraps inside the screen.
			get_tree().create_timer(1.5).timeout.connect(func(): toast("Lumen has new cards for you: Lumen, Echo Spirit, Lumen, Echo Radiant, Lumen, Echo Comet, Lumen, Echo Zenith, Echo Resonance, Echo Barrier, Echo Step, Echo Chorus and the rest of a very long list of names that used to run off both sides of the screen. They are in your collection.", 20.0))
		elif a == "--roam":
			await get_tree().process_frame
			go(ROAM)
		elif a.begins_with("--coat="):
			duel_config["opponent_coat"] = a.trim_prefix("--coat=")      # dev: the rival in a dorm jacket
		elif a.begins_with("--my-coat="):
			duel_config["player_coat"] = a.trim_prefix("--my-coat=")
		elif a.begins_with("--opp="):
			duel_config["opponent"] = a.substr(6)
		elif a.begins_with("--me="):
			duel_config["player_char"] = a.substr(5)      # dev: duel as one of the characters
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
		elif a.begins_with("--oppmodel="):
			# Dev: a duelist of the worlds, as a duel started there would name them (--opp=student_a --oppmodel=student_girl).
			duel_config["opponent_model"] = a.substr(11)
			duel_config["opponent_name"] = "First-Year Student"
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
		elif a.begins_with("--campus="):
			# Dev: the Academy story. --campus=new (a new game, "academia"), --campus=libre (a new game
			# with your own cards), --campus=go (carry on), --campus=ac_ch1 or ac_ch1:12 (that chapter / step),
			# --campus=island (a free day on the island).
			var cw := a.substr(9)
			await get_tree().create_timer(0.5).timeout
			if cw == "new" or cw == "libre":
				Campus.new_game("libre" if cw == "libre" else "academia")
				Campus.go()
			elif cw == "go":
				Campus.go()
			elif cw == "island":
				if not Campus.started():
					Campus.new_game("academia")
				Campus.put_many({"free_days": true, "jacket": true})
				for da in OS.get_cmdline_user_args():
					if da.begins_with("--dorm="):      # dev: a free day in another dorm's jacket
						Campus.put("dorm", clampi(int(da.substr(7)), 0, 2))
				Campus.island()
			else:
				if not Campus.started():
					Campus.new_game("academia")
				Campus.enter()
				for da in OS.get_cmdline_user_args():
					# dev: what the story remembers from earlier chapters (--recall=m_train_mika,dante_left)
					# and the dorm you are in by now (--dorm=2), so a late chapter can be walked on its own.
					if da.begins_with("--recall="):
						for rf in da.substr(9).split(",", false):
							CampusProgress.remember(rf)
					elif da.begins_with("--dorm="):
						Campus.put("dorm", clampi(int(da.substr(7)), 0, 2))
				var cparts := cw.split(":")
				if cparts[0] != "ac_prologue":
					Campus.put("jacket", true)
				if cparts.size() > 1:
					CampusProgress.save_position(cparts[0], int(cparts[1]), {})
					StoryDirector.begin(cparts[0], true)
				else:
					StoryDirector.begin(cparts[0])
		elif a.begins_with("--decks-report="):
			# (testing) every duelist in the roster with the deck they play, to a text file.
			var out := FileAccess.open(a.trim_prefix("--decks-report="), FileAccess.WRITE)
			for ck in Characters.ORDER:
				var info := Characters.get_char(str(ck))
				var dk2 := str(info.get("deck", ""))
				if dk2 == "" or not CardData.has_deck(dk2):
					out.store_line("## %s (%s): no deck '%s'" % [info.get("name", ck), info.get("era", "?"), dk2])
					continue
				var counts := {}
				var order: Array = []
				for id3 in CardData.deck_list(dk2):
					if not counts.has(id3):
						order.append(id3)
					counts[id3] = int(counts.get(id3, 0)) + 1
				var names: Array = []
				for id3 in order:
					var cd := CardData.get_card(int(id3))
					names.append("%s%s" % [cd.get("name", "?"), " x%d" % counts[id3] if counts[id3] > 1 else ""])
				var ex: Array = []
				for id4 in CardData.extra_list(dk2):
					ex.append(str(CardData.get_card(int(id4)).get("name", "?")))
				out.store_line("## %s (%s) deck=%s style=%s main=%d extra=%d" % [info.get("name", ck), info.get("era", "?"), dk2, info.get("style", "-"), CardData.deck_list(dk2).size(), ex.size()])
				out.store_line("MAIN: " + ", ".join(names))
				out.store_line("EXTRA: " + ", ".join(ex))
				var au := SignatureDecks.audit(str(ck))
				out.store_line("COUNTS: in=%d ready=%d need_effect=%d unknown=%d stand_ins=%d" % [(au["in"] as Array).size(), (au["ready"] as Array).size(),
					(au["need_effect"] as Array).size(), (au["unknown"] as Array).size(), (au["stand_ins"] as Array).size()])
				out.store_line("IN: " + ", ".join(au["in"]))
				out.store_line("READY: " + ", ".join(au["ready"]))
				out.store_line("NEED_EFFECT: " + ", ".join(au["need_effect"]))
				out.store_line("UNKNOWN: " + ", ".join(au["unknown"]))
				out.store_line("STAND_INS: " + ", ".join(au["stand_ins"]))
			out.close()
			print("decks report written")
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
			if what == "select" or what == "freeduel":
				menu._on_free_duel()
			elif what == "select-old":
				menu._on_free_duel_setup()
			elif what.begins_with("freeduel-"):
				# --open=freeduel-play[:me[:field[:their version]]]: press DUEL! (as "jaden" on "highway", say).
				# freeduel-tab2: the second era tab. freeduel-random: a random rival. freeduel-mine: choosing your side.
				menu._on_free_duel()
				await get_tree().create_timer(0.6).timeout
				for n in menu.find_children("*", "CharacterSelect", true, false):
					var parts := what.split(":")
					if parts[0] == "freeduel-play":
						if parts.size() > 1 and parts[1] != "":
							n._picking = "me"
							n._choose(parts[1])
						if parts.size() > 2 and parts[2] != "":
							n._field = parts[2]
							n._refresh_setup()
						if parts.size() > 3 and parts[3] != "":
							n._their_deck = "" if parts[3] == "full" else "@" + parts[3]
							n._refresh_pick()
						await get_tree().create_timer(1.0).timeout
						print("FREE DUEL: pressing DUEL! as ", n._me, " (", n._my_deck, ") vs ", n._opp, " (", n._deck_of("opp"), ") on ", n._field)
						n._start_duel()
					elif what.begins_with("freeduel-tab"):
						n._step_era(int(what.substr(12)))
					elif what == "freeduel-random":
						n._random_opponent()
					elif what == "freeduel-mine":
						n._picking = "me"
						n._choose("jaden")
						n._picking = "me"
						n._refresh_pick()
			elif what.begins_with("online"):
				# --open=online[:wizard:N | :renew | :help | :qr | :groups | :challenge | :card | :waiting]
				var parts := what.split(":")
				menu._on_online()
				await get_tree().create_timer(0.8).timeout
				var scr: Node = menu.find_children("*", "OnlineScreen", true, false)[0]
				var sub := parts[1] if parts.size() > 1 else ""
				if sub in ["challenge", "card", "waiting"]:
					for i in 40:
						if not Net.people().is_empty() and bool(Net.people()[0]["online"]):
							break
						await get_tree().create_timer(0.25).timeout
				var first: Dictionary = Net.people()[0] if not Net.people().is_empty() else {"id": "nobody"}
				match sub:
					"wizard", "renew":
						if sub == "renew" and Net.groups.is_empty():
							Net.make_group(Loc.t("%s's Table") % Profile.duelist_name, 0, "tskey-auth-kDEMO0000CNTRL-0000000000000000000000000000")
						scr._open_wizard("make" if sub == "wizard" else "renew")
						await get_tree().create_timer(0.4).timeout
						var w: Node = scr.find_children("*", "OnlineWizard", true, false)[0]
						for i in (int(parts[2]) - 1 if parts.size() > 2 else 0):
							if int(w._steps[w._at]) == 3:
								if Net.groups.is_empty() or w._made_gid == "":
									w._made_gid = str(Net.make_group(w._name, 0, "tskey-auth-kDEMO0000CNTRL-0000000000000000000000000000")["gid"])
								w._checked = true
							w._go(w._at + 1)
					"help":
						scr._help()
					"qr":
						scr._show_qr()
					"groups":
						scr._groups_menu()
					"challenge":
						scr._challenge_dialog(str(first["id"]))
					"waiting":
						scr._waiting(str(first["id"]))
					"card":
						ChallengeCard.show_for({"k": "challenge", "cid": "demo", "from": str(first["id"]), "mode": "match", "fl": false, "lp": 8000,
							"destiny": true, "deck_name": "Elemental Heroes"})
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
			elif what == "editor":
				menu._open_profile(false)      # dev: the editor as you open it later (Cancel, Save)
			elif what.begins_with("peek:"):
				# Dev: a duelist's deck laid out (the Free Duel "See their deck" view).
				var pk := what.trim_prefix("peek:")
				var dpk := DeckPeek.new(pk, str(Characters.get_char(pk).get("deck", "")))
				dpk.z_index = 200
				menu.add_child(dpk)
			elif what == "intro":
				menu._first_start()      # dev: the first-start opening, whoever you are
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
				menu._on_deck_list()
				await get_tree().create_timer(0.5).timeout
				for n in menu.find_children("*", "", true, false):
					if n is DeckMenu:
						n._edit(0)
						break
			elif what == "deck-list":
				menu._on_deck_list()
			elif what == "deck" or what.begins_with("cards"):
				# --open=cards (or deck): Decks & cards. cards-shops[:world]: its card shops page.
				# cards-decks / cards-album / cards-edit: press that button, as a player would.
				menu._on_deck()
				await get_tree().create_timer(0.4).timeout
				for n in menu.find_children("*", "CardsGate", true, false):
					if what.begins_with("cards-shops"):
						n._shops(what.get_slice(":", 1) if what.contains(":") else "")
					elif what == "cards-decks":
						n._open_decks()
					elif what == "cards-album":
						n._open_album()
					elif what == "cards-edit":
						n._edit_now()
					elif what.begins_with("cards-go:"):
						# Dev: the shops page's "Go to this shop" for a world.
						CardsGate.go_to_shop(what.get_slice(":", 1))
			elif what == "replays":
				menu._on_replays()
			elif what == "replay-last":
				# Dev: straight into the newest replay.
				for rh in Replays.list():
					if not bool(rh.get("newer", false)):
						duel_config = Replays.config_for(Replays.read(str(rh["path"])))
						menu_open = "replays"
						go(DUEL)
						break
			elif what == "welcome":
				# The "the game closed without warning" panel, as after a crash.
				Saves.crashed_last = true
				Saves.crash_report = "x"
				menu._welcome_back()
			elif what.begins_with("turbo"):
				# --open=turbo: the highway's door. turbo-races / turbo-riders / turbo-gp: on that page.
				# turbo-go=<what>: press into the ride as the screen would ("race:sprint", "rider:crow", "gp", "garage", "").
				menu._on_turbo()
				# (Wait for the screen itself: on a busy machine it takes more than a moment.)
				for _w in 30:
					await get_tree().create_timer(0.2).timeout
					if not menu.find_children("*", "TurboGate", true, false).is_empty():
						break
				for n in menu.find_children("*", "TurboGate", true, false):
					if what == "turbo-races":
						n._races()
					elif what == "turbo-riders":
						n._riders()
					elif what == "turbo-gp":
						n._grand_prix()
					elif what.begins_with("turbo-go="):
						print("TURBO GATE: going ", what.trim_prefix("turbo-go="))
						n._go(what.trim_prefix("turbo-go="))
			elif what == "campus":
				menu._on_academy()
			elif what == "campus-load":
				# The Academy's door with its Load screen open.
				menu._on_academy()
				await get_tree().create_timer(0.4).timeout
				for n in menu.find_children("*", "CampusGate", true, false):
					SaveMenu.open(n, false, true)
			elif what == "settings":
				for t in OS.get_cmdline_user_args():
					if t.begins_with("--tab="):      # dev: open on that tab (3 is Audio)
						SettingsPanel._tab_at["settings"] = int(t.substr(6))
				menu._on_settings()
			elif what.begins_with("story"):
				# --open=story: the story's door. story-load: with its Load screen open.
				# story-chapters: on its chapter page. story-new: the "new game?" question.
				# storypanel: the side panel from before 0.69.0.
				if what == "storypanel":
					menu._on_story_panel()
				else:
					menu._on_story()
					await get_tree().create_timer(0.4).timeout
					for n in menu.find_children("*", "StoryGate", true, false):
						if what == "story-load":
							SaveMenu.open(n, false, false, true)
						elif what == "story-chapters":
							n._chapters()
						elif what == "story-new":
							n._ask_new()
						elif what == "story-continue":
							# Dev: press the big button (Continue, or the chapter to play) as a player would.
							for bt in n._left.find_children("*", "Button", true, false):
								if (bt as Button).text.begins_with("▶"):
									print("STORY GATE: pressing ", (bt as Button).text)
									(bt as Button).pressed.emit()
									break
			elif what.begins_with("roam-pick"):
				# --open=roam-pick: the Free Roam door. roam-pick:<world>: on that world's page.
				# roam-pick-go:<world>: then press Go as a player would. roampanel: the side panel from before 0.69.1.
				menu._on_roam()
				await get_tree().create_timer(0.4).timeout
				for n in menu.find_children("*", "RoamGate", true, false):
					var wk := what.get_slice(":", 1)
					if wk != "" and n._tile_of.has(wk):
						(n._tile_of[wk] as Button).grab_focus()
						n._show(wk)
					if what.begins_with("roam-pick-go"):
						await get_tree().create_timer(0.6).timeout
						print("ROAM GATE: pressing ", n._go.text)
						n._go.pressed.emit()
			elif what == "roampanel":
				menu._on_roam_panel()
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
			elif what.begins_with("packs") or what == "packopen" or what.begins_with("packmulti"):
				var ps := PackShop.new()
				ps.z_index = 100
				menu.add_child(ps)
				if what.length() == 6:
					ps._show_tab.call_deferred(int(what.substr(5)))
				if what == "packopen":
					Collection.dp += 500
					await get_tree().create_timer(0.6).timeout
					ps._open(Collection.PACKS[0])
				if what.begins_with("packmulti"):
					# --open=packmulti / packmulti10: the first pack on the shelf, 5 (or 10) at once.
					Collection.dp += 5000
					await get_tree().create_timer(0.6).timeout
					ps._refresh()
					ps._open(ps._packs[0], 10 if what.contains("10") else 5)
					if what.ends_with("s"):
						# (…s: skip to the summary after the first pack starts.)
						await get_tree().create_timer(2.5).timeout
						for n in ps.find_children("*", "PackOpening", true, false):
							n.call("_skip_all")
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
						elif n is CanvasLayer:
							(n as CanvasLayer).visible = false
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
	Pad.hint("")                       # each screen sets its own controller hint, if it has one
	Settings.hold_gave_up = false      # a new place: "hold the frame rate" may try again there
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.09)
	await tw.finished
	get_tree().paused = false
	# (Said before the place is even built, so whatever starts in it can wait for it.)
	loading = path in [ROAM, RIDE] and (DisplayServer.get_name() != "headless" or _fake_load)
	get_viewport().disable_3d = false      # (a world that was left half-built must not leave this off)
	if loading:
		_show_card(path)
		# One frame so the card is on screen before the world starts building (that blocks).
		await get_tree().process_frame
		await get_tree().process_frame
	# The place you are leaving is taken down first, and it stays inside the tree until it is gone.
	# (The engine's own swap lifts the old scene out of the tree a frame before it deletes it. Anything
	# in it that was waiting frame by frame woke up once in between, with no tree to wait on: in a
	# shipped build that loop then never slept again. Leaving a story from the pause menu while a
	# "go there" goal was up left the screen black for good, with the music still playing.)
	var leaving := get_tree().current_scene
	if leaving != null:
		leaving.queue_free()
		await get_tree().process_frame
		if is_instance_valid(leaving):
			await get_tree().process_frame
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	if loading:
		await _settle()
	# The new screen takes clicks straight away; the fade-in is only for the eye.
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	# The loading card goes with the dark behind it, as one. (The dark used to clear first and
	# the card sat over the finished world for a moment, still, before it popped off.)
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(_fade, "color:a", 0.0, 0.45 if _card.visible else 0.22)
	if _card.visible:
		tw2.tween_property(_card, "modulate:a", 0.0, 0.3)
	tw2.chain().tween_callback(func():
		_card.visible = false
		_card.modulate.a = 1.0
		# A message that came while the place was loading (the weather, say) is shown now.
		if not _held_toast.is_empty():
			var h: Array = _held_toast
			_held_toast = []
			toast(str(h[0]), float(h[1])))


## Your own picture as the game's icon while it runs (the Dock on a Mac, the taskbar on Windows):
## put icon.png (or .jpg) in your card folder, like back.jpg for the card backs. Nothing is bundled:
## without the file the build's own icon stays.
func apply_own_icon() -> void:
	if DisplayServer.get_name() == "headless" or Settings.card_folder == "":
		return
	for ext in ["png", "jpg", "jpeg", "webp"]:
		var path := Settings.card_folder.path_join("icon." + ext)
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null and not img.is_empty():
				if img.get_width() > 512:
					img.resize(512, 512 * img.get_height() / img.get_width(), Image.INTERPOLATE_LANCZOS)
				DisplayServer.set_icon(img)
			return


## True while a place is still getting ready behind the dark screen (see _settle).
var loading := false
var _load_l: Label
var _card: LoadCard


## The loading card for where you are going: the world's name, its area, its era.
func _show_card(path: String) -> void:
	var key := "ride" if path == RIDE else str(roam.get("district", "domino"))
	var title := Loc.t("The Highway") if path == RIDE else ""
	var sub := ""
	if path != RIDE:
		var d: Dictionary = RoamData.district(key)
		title = Loc.t(str(d.get("name", key)))
		sub = Loc.t(str(d.get("area", "")))
	_card.setup(key, title, sub)
	_card.modulate.a = 1.0
	_card.visible = true


## A big place does a lot in its first seconds: the graphics chip builds the shaders it has
## never used, the people's motions are fitted to their bodies. Shown as it happened, that was
## a slideshow (2 FPS for five seconds on a machine that then runs at 200). So the dark screen
## stays until the frames come evenly, with a word on it, and for 7 seconds at the most.
func _settle() -> void:
	if DisplayServer.get_name() == "headless" and not _fake_load:
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
		if el > 900 and _load_l != null and not _load_l.visible and not _card.visible:
			_load_l.text = Loc.t("Loading")
			_load_l.visible = true
		# (0.72.3) Never a half-built world: the place says when it is whole. And what it still has to
		# prepare (the people's motions, the walkways of the main characters) is done behind the
		# card too, where it can take 20 ms a frame without anyone feeling it.
		if building and el < 90000:
			continue
		var preparing: bool = not Avatars._warm_q.is_empty() or not get_tree().get_nodes_in_group("loading_job").is_empty()
		if el > (16000 if preparing else 9000):
			break
		if preparing:
			continue
		if el > 300 and recent.size() >= 12:
			var lo := 1e9
			var hi := 0.0
			for f in recent:
				lo = minf(lo, f)
				hi = maxf(hi, f)
			# Even, and quick: the slowest of the last twelve frames is not far off the fastest,
			# and none of them is slow in itself. (Frames that are all equally slow, while the
			# graphics are still being prepared in the first seconds, used to count as settled:
			# the Academy then showed at 2 or 3 frames a second for a few seconds.)
			if hi < maxf(34.0, lo * 2.2) and hi < 70.0:
				break
	if _load_l:
		_load_l.visible = false
	loading = false


var building := false      # a world is still being built (it says so itself): the loading card stays
var _pulse_last := 0      # when the last picture was finished
var _pulse_seen := 0      # when the last picture was begun (the ring turns by this)
var _pulse_gap := 24
var _fake_load := OS.get_environment("LOADING_HEADLESS") != ""      # dev: the loading card's timing with nothing drawn


## Called from inside long pieces of work (building a world, loading a model): while the loading card
## is up, and when the last frame is 24 ms old, the card's light is moved on and one frame is drawn
## right now. So the card keeps moving through work that cannot be cut into frames. Anywhere else it
## does nothing.
func pulse() -> void:
	if _busy_since != 0:
		_busy_pulse()
		return
	if not loading or _card == null or not _card.visible:
		return
	var now := Time.get_ticks_msec()
	if now - _pulse_last < _pulse_gap:
		return
	if _frame_log and now - _pulse_seen > maxi(80, _pulse_gap * 2):
		print("DRAWGAP %d ms (pulse)  %s" % [now - _pulse_seen, str(get_stack()[1]).substr(0, 110) if get_stack().size() > 1 else ""])
	_card.tick(minf((now - _pulse_seen) / 1000.0, 0.1))
	_pulse_draw(now)
	if OS.get_environment("PULSE_SHOT") != "" and pulses % 25 == 5:
		get_viewport().get_texture().get_image().save_png("%s_%03d.png" % [OS.get_environment("PULSE_SHOT"), pulses])


var pulses := 0      # (dev: how many frames pulse() drew)


# ---- (0.72.3) a ring in the corner while a screen is being got ready
var _spin: Control
var _busy_since := 0
var _boot_tw: Tween


## Say this right before work that may take a moment (opening a big screen). If it does take long,
## a ring turns in the corner until it is done, instead of the picture standing still. It ends by
## itself when the frame does.
func busy() -> void:
	if DisplayServer.get_name() == "headless" or _busy_since != 0 or loading:
		return
	_busy_since = Time.get_ticks_msec()
	_busy_frames = 2      # (this frame and the next: a screen's first drawing often asks for the faces it shows)


var _busy_frames := 0


func _busy_end() -> void:
	_busy_since = 0
	if _spin != null and _spin.modulate.a > 0.0:
		create_tween().tween_property(_spin, "modulate:a", 0.0, 0.15)


func _busy_pulse() -> void:
	var now := Time.get_ticks_msec()
	if now - _busy_since < 140 or now - _pulse_last < _pulse_gap:
		return      # (quick things never show it)
	_spin.modulate.a = 1.0
	_spin.rotation += minf((now - _pulse_seen) / 1000.0, 0.1) * 3.4
	_pulse_draw(now)


## One picture drawn from inside the work. Drawing has a price of its own (waiting for the screen's
## next refresh, a slow card): the work between two pictures is at least three times as long as the
## last picture took, so showing that the game is alive never makes the wait much longer.
func _pulse_draw(now: int) -> void:
	RenderingServer.force_draw(true, minf((now - _pulse_seen) / 1000.0, 0.1))
	_pulse_seen = now
	_pulse_last = Time.get_ticks_msec()
	_pulse_gap = clampi((_pulse_last - now) * 3, 24, 120)
	pulses += 1


## The start of the game: a card with the turning ring is up while the menu, the card lists and the
## first people are got ready, and it goes when the frames come evenly. (The menu used to appear and
## then stutter through all of that, and the first visit to the album or a shop froze for seconds.)
func boot_begin() -> void:
	if _boot_tw != null and _boot_tw.is_valid():
		_boot_tw.kill()
	_fade.color.a = 1.0
	loading = true
	_card.setup("boot", Loc.t("Crossroads"), Loc.t("Getting everything ready"))
	_card.modulate.a = 1.0
	_card.visible = true


## What every later screen leans on, worked out once behind the card: what each pack holds and where
## every card can be found. (The first visit to the album, a shop or "Where to find it" used to stop
## for seconds to work these out.)
func prepare() -> void:
	var t0 := Time.get_ticks_msec()
	for p in Collection.PACKS:
		if str(p["key"]) != "echo":
			Collection.pool(str(p["key"]))
		pulse()
	for p in Collection.shop_packs():
		if str(p["key"]) != "echo":
			Collection.pool(str(p["key"]))
		pulse()
	CardFinder.summary(CardData.LUMEN)
	pulse()
	Avatars.prime()
	if _frame_log:
		print("PREPARE %d ms" % (Time.get_ticks_msec() - t0))


func boot_end() -> void:
	await _settle()
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(_fade, "color:a", 0.0, 0.45)
	tw2.tween_property(_card, "modulate:a", 0.0, 0.3)
	tw2.chain().tween_callback(func():
		_card.visible = false
		_card.modulate.a = 1.0)
var _toast_tw: Tween


## A line at the bottom of the screen. A long one wraps inside the screen (it used to run off
## both sides) and stays up long enough to be read.
var _held_toast: Array = []

func toast(message: String, hold := 1.8) -> void:
	if loading or (_card != null and _card.visible):
		_held_toast = [message, hold]      # (not over the loading card: it waits for the place to show)
		return
	var view: Vector2 = _toast.get_viewport_rect().size
	var max_w: float = maxf(600.0, view.x * 0.78)
	_toast.autowrap_mode = TextServer.AUTOWRAP_OFF
	_toast.custom_minimum_size = Vector2.ZERO
	_toast.text = message
	_toast.reset_size()
	if _toast.size.x > max_w:
		_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_toast.custom_minimum_size = Vector2(max_w, 0)
		_toast.size = Vector2(max_w, 0)
		_toast.reset_size()
	_toast.position = Vector2((view.x - _toast.size.x) / 2.0, view.y - 90.0 - _toast.size.y)
	hold = maxf(hold, 1.4 + float(message.length()) / 22.0)
	if _toast_tw != null and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tw.tween_interval(hold)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


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
	if n is Control:
		_tip_later.call_deferred(n)


## A long hover hint is broken into lines (the engine would draw it as one line across the screen).
func _tip_later(n) -> void:
	if not is_instance_valid(n):
		return
	var c := n as Control
	if c.tooltip_text.length() <= 58 or c.tooltip_text.contains("\n"):
		return
	var out := ""
	var line := ""
	for word in c.tooltip_text.split(" "):
		if line.length() + word.length() + 1 > 54 and line != "":
			out += line + "\n"
			line = word
		else:
			line = word if line == "" else line + " " + word
	c.tooltip_text = out + line


func _chip_later(n) -> void:
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


## Dev (--esc-test): plays a story up to its first goal by pressing "accept", then works the pause
## menu with real key and mouse events and prints what it finds.
func _esc_test() -> void:
	var sc: Node = null
	for i in 900:
		await get_tree().create_timer(0.35).timeout
		sc = get_tree().current_scene
		if sc != null and "story" in sc and sc.story != null and not sc.story._goal.is_empty():
			break
		var acc := InputEventAction.new()
		acc.action = "ui_accept"
		acc.pressed = true
		Input.parse_input_event(acc)
	await get_tree().create_timer(2.0).timeout
	print("ESC TEST: at the goal, step ", sc.story.step)
	for round in 2:
		var esc := InputEventKey.new()
		esc.keycode = KEY_ESCAPE
		esc.physical_keycode = KEY_ESCAPE
		esc.pressed = true
		Input.parse_input_event(esc)
		await get_tree().create_timer(0.1).timeout
		esc = esc.duplicate()
		esc.pressed = false
		Input.parse_input_event(esc)
		await get_tree().create_timer(0.8).timeout
		print("ESC TEST: pause open=", sc._pause != null, "  mouse mode=", Input.mouse_mode, "  tree paused=", get_tree().paused)
		if sc._pause == null:
			return
		await _dev_shot("/tmp/esc_%d.png" % round)
		var want := "Resume" if round == 0 else "Main Menu"
		var hit: Button = null
		for b in sc._pause.find_children("*", "Button", true, false):
			if (b as Button).text in [want, Loc.t(want)]:
				hit = b
		print("ESC TEST: button ", want, " found=", hit != null)
		var at: Vector2 = get_tree().root.get_final_transform() * hit.get_global_rect().get_center()
		for down in [true, false]:
			var mb := InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			mb.pressed = down
			mb.position = at
			mb.global_position = at
			Input.parse_input_event(mb)
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(1.0).timeout
		if round == 0:
			print("ESC TEST: after Resume, pause open=", sc._pause != null, "  hovered=", get_viewport().gui_get_hovered_control())
			if sc._pause != null:
				sc._close_pause()
	for i in 8:
		await get_tree().create_timer(1.0).timeout
		var cur := get_tree().current_scene
		print("ESC TEST: +", i + 1, "s scene=", cur.scene_file_path if cur else "none", "  busy=", _busy, "  fade=", _fade.color.a)
	await _dev_shot("/tmp/esc_after.png")
	get_tree().quit()


func _dev_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
