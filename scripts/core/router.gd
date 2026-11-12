extends CanvasLayer
## Scene changes with a fade, toast messages, and data passed between scenes.

const MAIN_MENU := "res://scenes/main_menu.tscn"
const DUEL := "res://scenes/duel.tscn"
const STORY := "res://scenes/story.tscn"
const ROAM := "res://scenes/roam.tscn"

## Free roam: where you are and what just happened there.
var roam := {"district": "domino", "pos": null, "last_duel": "", "result": ""}

## Story position handed between the story player and story duels.
var story := {}
var story_result := ""

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


func _process(_delta: float) -> void:
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = Loc.t("%d FPS") % Engine.get_frames_per_second()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.01, 0.02, 0.04, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position.y -= 140
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.add_theme_font_override("font", load("res://assets/fonts/Rajdhani-SemiBold.ttf"))
	_toast.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.14, 0.92)
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
		elif a.begins_with("--story="):
			story = {"chapter": a.substr(8), "step": 0, "flags": {}}
			await get_tree().process_frame
			go(STORY)
		elif a.begins_with("--district="):
			roam["district"] = a.substr(11)
		elif a.begins_with("--tod="):
			roam["tod"] = a.substr(6)
		elif a.begins_with("--gfx="):
			Settings.graphics = int(a.substr(6))
		elif a == "--roam":
			await get_tree().process_frame
			go(ROAM)
		elif a.begins_with("--opp="):
			duel_config["opponent"] = a.substr(6)
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
			elif what.begins_with("academy"):
				Academy.load_data()
				if what != "academy":
					Academy.d["enrolled"] = true
					Academy.d["dorm"] = 1 if "yellow" in what or "tourney" in what else (2 if "blue" in what else 0)
					Academy.d["day"] = 2
					Academy.d["wins"] = 1
					Academy.d["log"] = [true, false]
					if "tourney" in what:
						Academy.tourney_new()
				menu._on_academy()
			elif what == "profile":
				menu._open_profile(true)
			elif what == "deck":
				menu._on_deck()
			elif what == "settings":
				menu._on_settings()
			elif what == "packs":
				var ps := PackShop.new()
				ps.z_index = 100
				menu.add_child(ps)
				await get_tree().create_timer(0.6).timeout
				ps._open(Collection.PACKS[1])
		elif a.begins_with("--speed="):
			Settings.anim_speed = float(a.substr(8))
	if duel:
		await get_tree().process_frame
		go(DUEL)
	if shot != "":
		await get_tree().create_timer(after).timeout
		if DisplayServer.get_name() != "headless":
			var img := get_viewport().get_texture().get_image()
			img.save_png(shot)
			print("screenshot saved: ", shot)
		else:
			print("headless run finished")
		get_tree().quit()


func go(path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	await tw.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.5)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func toast(message: String) -> void:
	_toast.text = message
	_toast.reset_size()
	_toast.position.x = (_toast.get_viewport_rect().size.x - _toast.size.x) / 2.0
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.8)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
