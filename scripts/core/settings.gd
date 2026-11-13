extends Node
## Player settings, saved to user://settings.cfg and applied on start.

signal changed

const PATH := "user://settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(3840, 2160),
]
const ANIM_SPEEDS := {"Normal": 1.0, "Fast": 1.6, "Very fast": 2.6}

var fullscreen := false
var resolution := Vector2i(1600, 900)
var master_volume := 0.8
var music_volume := 0.7
var sfx_volume := 0.8
var anim_speed := 1.0
var pace := 1.0          # extra speed on top, set by the duel (the opponent's turn runs quicker)
var card_folder := ""
var sleeve := "default"         # the back of your own cards in a duel (see Cards.sleeves)
var field_theme := "auto"
var language := "en"
var show_fps := false
## 0 = Performance, 1 = High, 2 = Ultra (global illumination).
var graphics := 1
const GRAPHICS := ["Performance", "High", "Ultra"]


## Applies screen effects that scale with the graphics setting to an Environment.
func tune_environment(e: Environment) -> void:
	var fplus := RenderingServer.get_current_rendering_method() == "forward_plus"
	e.ssao_enabled = graphics >= 1
	e.ssr_enabled = fplus and graphics >= 1
	e.ssr_max_steps = 48
	e.ssil_enabled = fplus and graphics >= 2
	e.sdfgi_enabled = fplus and graphics >= 2
	e.volumetric_fog_enabled = fplus and graphics >= 1


func _ready() -> void:
	card_folder = default_card_folder()
	_ensure_buses()
	load_settings()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			language = a.substr(7)
	apply()


func default_card_folder() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Crossroads/assets")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	resolution = cfg.get_value("display", "resolution", resolution)
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	anim_speed = cfg.get_value("game", "anim_speed", anim_speed)
	card_folder = cfg.get_value("game", "card_folder", card_folder)
	field_theme = cfg.get_value("game", "field_theme", field_theme)
	language = cfg.get_value("game", "language", language)
	sleeve = str(cfg.get_value("game", "sleeve", sleeve))
	show_fps = cfg.get_value("display", "show_fps", show_fps)
	graphics = cfg.get_value("display", "graphics", graphics)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "resolution", resolution)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("game", "anim_speed", anim_speed)
	cfg.set_value("game", "card_folder", card_folder)
	cfg.set_value("game", "field_theme", field_theme)
	cfg.set_value("game", "language", language)
	cfg.set_value("game", "sleeve", sleeve)
	cfg.set_value("display", "show_fps", show_fps)
	cfg.set_value("display", "graphics", graphics)
	cfg.save(PATH)


func apply() -> void:
	Loc.setup(language)
	_apply_audio()
	if not _is_desktop():
		changed.emit()
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var screen := DisplayServer.window_get_current_screen()
		var usable := DisplayServer.screen_get_usable_rect(screen)
		var size := resolution
		if usable.size.x > 0:
			size = Vector2i(mini(size.x, usable.size.x), mini(size.y, usable.size.y))
		DisplayServer.window_set_size(size)
		if usable.size.x > 0:
			DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)
	changed.emit()


## Seconds scaled by the animation speed setting.
func t(seconds: float) -> float:
	return seconds / maxf(anim_speed * pace, 0.1)


func _is_desktop() -> bool:
	return OS.has_feature("pc") and DisplayServer.get_name() != "headless"


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _apply_audio() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)


func _set_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
		AudioServer.set_bus_mute(idx, value <= 0.001)
