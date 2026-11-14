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
var fs_resolution := Vector2i.ZERO   # in fullscreen: the size the 3D picture is drawn at (ZERO: the screen's own)
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
## "Hold the frame rate": when the picture gets heavy the 3D view is drawn a little softer
## instead of slower, and sharpened again when there is room. `auto_k` is that factor.
var hold_fps := false
var auto_k := 1.0
## Frame rate: 0 = unlimited, -1 = match the screen (V-Sync), otherwise the cap.
var fps_cap := 0
const FPS_CAPS := [0, 30, 60, 120, 144, 240, -1]
## Graphics. Every effect has its own switch; a preset fills them all in, and changing any one
## of them by hand turns the preset into "Custom".
signal gfx_changed

const GFX_PRESET_NAMES := ["Low", "Medium", "High", "Ultra"]
const GFX_PRESETS := [
	{"res": 1, "aa": 0, "shadows": 1, "ao": false, "reflect": false, "glow": false, "fog": false, "gi": false, "detail": 0, "people": 0},
	{"res": 2, "aa": 1, "shadows": 2, "ao": false, "reflect": false, "glow": true, "fog": false, "gi": false, "detail": 1, "people": 1},
	{"res": 3, "aa": 2, "shadows": 2, "ao": true, "reflect": false, "glow": true, "fog": false, "gi": false, "detail": 2, "people": 1},
	{"res": 4, "aa": 3, "shadows": 3, "ao": true, "reflect": true, "glow": true, "fog": true, "gi": true, "detail": 3, "people": 2},
]
## How many lines the 3D picture is drawn at before it is fitted to the window. On a Retina
## or 4K screen "Native" is a huge number of pixels, and the biggest single cost there is.
const RES_NAMES := ["720p", "900p", "1080p", "1440p", "Native"]
const RES_LINES := [720, 900, 1080, 1440, 0]
const AA_NAMES := ["Off", "FXAA (fast)", "MSAA 2x", "MSAA 4x (sharpest)"]
const SHADOW_NAMES := ["Off", "Low", "Medium", "High"]
const DETAIL_NAMES := ["Off", "Some", "More", "Full"]
const PEOPLE_NAMES := ["Few", "Normal", "Busy"]
## -1 = Custom, otherwise an index into GFX_PRESETS.
var gfx_preset := 2
var gfx: Dictionary = GFX_PRESETS[2].duplicate()
## Older saves and the --gfx= switch: 0 = Performance, 1 = High, 2 = Ultra.
var graphics := 1:
	set(v):
		graphics = v
		set_gfx_preset([0, 2, 3][clampi(v, 0, 2)])


func set_gfx_preset(i: int) -> void:
	gfx_preset = clampi(i, 0, GFX_PRESETS.size() - 1)
	gfx = (GFX_PRESETS[gfx_preset] as Dictionary).duplicate()
	apply_graphics()


## Change one graphics value by hand. The preset becomes whichever one matches, or Custom.
func set_gfx(key: String, value) -> void:
	gfx[key] = value
	gfx_preset = -1
	for i in GFX_PRESETS.size():
		var same := true
		for k in GFX_PRESETS[i]:
			if typeof(gfx[k]) == TYPE_FLOAT:
				same = same and absf(float(gfx[k]) - float(GFX_PRESETS[i][k])) < 0.011
			else:
				same = same and gfx[k] == GFX_PRESETS[i][k]
		if same:
			gfx_preset = i
	apply_graphics()


func gfx_preset_name() -> String:
	return "Custom" if gfx_preset < 0 else GFX_PRESET_NAMES[gfx_preset]


## Anti-aliasing for the small 3D views (portraits, the creator's figure).
func small_view_msaa() -> int:
	var aa := int(gfx["aa"])
	return Viewport.MSAA_4X if aa >= 3 else (Viewport.MSAA_2X if aa >= 1 else Viewport.MSAA_DISABLED)


## The parts that apply to the whole window right away: sharpness, edges, shadow quality.
func apply_graphics() -> void:
	if not is_inside_tree():
		return
	var vp := get_tree().root
	var aa := int(gfx["aa"])
	_apply_scale()
	if not vp.size_changed.is_connected(_apply_scale):
		vp.size_changed.connect(_apply_scale)
	vp.msaa_3d = Viewport.MSAA_4X if aa == 3 else (Viewport.MSAA_2X if aa == 2 else Viewport.MSAA_DISABLED)
	var fplus := RenderingServer.get_current_rendering_method() != "gl_compatibility"
	if fplus:
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if aa == 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	var sh := int(gfx["shadows"])
	RenderingServer.directional_shadow_atlas_set_size([1024, 1024, 2048, 4096][sh], true)
	RenderingServer.directional_soft_shadow_filter_set_quality(
		[RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][sh])
	RenderingServer.positional_soft_shadow_filter_set_quality(
		[RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM][sh])
	vp.positional_shadow_atlas_size = [1024, 1024, 2048, 4096][sh]
	# How soon far-away models switch to their lighter versions (bigger = sooner = faster).
	# On Full nothing ever switches: every model is drawn with all it has.
	vp.mesh_lod_threshold = [4.0, 2.0, 1.0, 0.0][clampi(int(gfx.get("detail", 2)), 0, 3)]
	gfx_changed.emit()


## The frame rate the game tries to hold: the cap you picked, else 60.
func fps_target() -> float:
	if fps_cap > 0:
		return float(mini(fps_cap, 60)) if fps_cap < 60 else 60.0
	return 60.0


var _hold_t := 0.0
var _hold_frames := 0
var _hold_ceiling := 1.0      # raising past this dropped frames a moment ago
var _hold_cool := 0.0
var _hold_good := 0.0


## Called every frame by the Router. Watches the frame rate and trades sharpness for speed.
func hold_tick(delta: float, in_3d: bool) -> void:
	if not hold_fps or not in_3d or DisplayServer.get_name() == "headless":
		if auto_k != 1.0 and not hold_fps:
			auto_k = 1.0
			_apply_scale()
		return
	_hold_t += delta
	_hold_frames += 1
	_hold_cool = maxf(0.0, _hold_cool - delta)
	if _hold_t < 0.75:
		return
	var fps := float(_hold_frames) / _hold_t
	_hold_t = 0.0
	_hold_frames = 0
	var want := fps_target()
	var vp := get_tree().root.get_viewport_rid()
	var spent := RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var before := auto_k
	if fps < want * 0.92:
		# Too slow: soften. A big miss takes a bigger step.
		auto_k = maxf(0.5, auto_k * (0.86 if fps < want * 0.75 else 0.93))
		_hold_ceiling = before
		_hold_cool = 12.0
		_hold_good = 0.0
	elif auto_k < 1.0:
		_hold_good += 0.75
		var room := spent > 0.1 and spent < (1000.0 / want) * 0.62
		var may_try := _hold_good > (2.0 if room else 9.0)
		if may_try and (_hold_cool <= 0.0 or auto_k * 1.05 < _hold_ceiling):
			auto_k = minf(1.0, auto_k * 1.05)
			_hold_good = 0.0
	if not is_equal_approx(before, auto_k):
		_apply_scale()


func _apply_scale() -> void:
	var vp := get_tree().root
	var lines: int = RES_LINES[clampi(int(gfx["res"]), 0, RES_LINES.size() - 1)]
	var h := float(vp.size.y)
	var k := 1.0 if (lines == 0 or h <= float(lines)) else clampf(float(lines) / h, 0.35, 1.0)
	if fullscreen and fs_resolution.y > 0 and h > float(fs_resolution.y):
		# Fullscreen at a lower resolution: the 3D picture is drawn that small and scaled up.
		k = minf(k, clampf(float(fs_resolution.y) / h, 0.3, 1.0))
	k = clampf(k * (auto_k if hold_fps else 1.0), 0.3, 1.0)
	var fplus := RenderingServer.get_current_rendering_method() == "forward_plus"
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if (fplus and k < 0.99) else Viewport.SCALING_3D_MODE_BILINEAR
	vp.fsr_sharpness = 0.35
	if not is_equal_approx(vp.scaling_3d_scale, k):
		vp.scaling_3d_scale = k


## The size the 3D picture is drawn at right now, in pixels.
func render_size() -> Vector2i:
	if not is_inside_tree():
		return Vector2i.ZERO
	var vp := get_tree().root
	return Vector2i(Vector2(vp.size) * vp.scaling_3d_scale)


## The 3D scale the window is using right now (other 3D views match it).
func scale_3d() -> float:
	return get_tree().root.scaling_3d_scale if is_inside_tree() else 1.0


## Screen effects for a 3D scene, from the graphics settings.
func tune_environment(e: Environment) -> void:
	var fplus := RenderingServer.get_current_rendering_method() == "forward_plus"
	e.ssao_enabled = bool(gfx["ao"])
	e.ssao_radius = 1.2
	e.ssao_intensity = 1.6
	e.ssao_power = 1.4
	e.ssr_enabled = fplus and bool(gfx["reflect"])
	e.ssr_max_steps = 40
	e.ssr_fade_in = 0.25
	e.ssr_fade_out = 1.2
	e.ssr_depth_tolerance = 0.3
	e.ssil_enabled = fplus and bool(gfx["gi"])
	e.sdfgi_enabled = fplus and bool(gfx["gi"])
	e.volumetric_fog_enabled = fplus and bool(gfx["fog"])
	if not e.has_meta("glow_wanted"):
		e.set_meta("glow_wanted", e.glow_enabled)
	e.glow_enabled = bool(e.get_meta("glow_wanted")) and bool(gfx["glow"])


## The sun's shadows: how far they reach and how soft they are.
func tune_sun(l: DirectionalLight3D) -> void:
	var sh := int(gfx["shadows"])
	l.shadow_enabled = sh > 0
	l.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if sh >= 3 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	l.directional_shadow_max_distance = [40.0, 45.0, 70.0, 110.0][sh]
	l.directional_shadow_blend_splits = sh >= 2
	l.shadow_blur = [1.0, 1.0, 1.6, 2.0][sh]
	l.shadow_bias = 0.06
	l.shadow_normal_bias = 1.6
	l.light_angular_distance = 0.0 if sh < 2 else 1.2


func _ready() -> void:
	# Before anything reads a save: a load, a new game or leaving admin mode asked for last run.
	Saves.apply_pending()
	Saves.read_admin()
	card_folder = default_card_folder()
	_ensure_buses()
	load_settings()
	# A game folder beside the game wins over the old default place (a folder you picked
	# yourself in Settings is left alone).
	var beside := Saves.game_dir().path_join(Saves.DATA_NAME)
	if DirAccess.dir_exists_absolute(beside) and (card_folder == "" or card_folder == old_default_folder() or not DirAccess.dir_exists_absolute(card_folder)):
		card_folder = beside
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			language = a.substr(7)
	apply()
	apply_graphics()


## Where the game's own folder is looked for first: "Crossroads Data" beside the game. It
## holds the cards, your own models and the saves. Without it, Documents/Crossroads/assets.
func default_card_folder() -> String:
	var beside := Saves.game_dir().path_join(Saves.DATA_NAME)
	if DirAccess.dir_exists_absolute(beside):
		return beside
	return old_default_folder()


func old_default_folder() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Crossroads/assets")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	resolution = cfg.get_value("display", "resolution", resolution)
	fs_resolution = cfg.get_value("display", "fs_resolution", fs_resolution)
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	anim_speed = cfg.get_value("game", "anim_speed", anim_speed)
	card_folder = cfg.get_value("game", "card_folder", card_folder)
	field_theme = cfg.get_value("game", "field_theme", field_theme)
	language = cfg.get_value("game", "language", language)
	sleeve = str(cfg.get_value("game", "sleeve", sleeve))
	show_fps = cfg.get_value("display", "show_fps", show_fps)
	hold_fps = bool(cfg.get_value("display", "hold_fps", hold_fps))
	_looks_first = bool(cfg.get_value("display", "looks_first", false))
	if cfg.has_section_key("graphics", "preset"):
		gfx_preset = int(cfg.get_value("graphics", "preset", gfx_preset))
		gfx = (GFX_PRESETS[clampi(gfx_preset, 0, GFX_PRESETS.size() - 1)] as Dictionary).duplicate()
		if gfx_preset < 0:
			gfx = (GFX_PRESETS[2] as Dictionary).duplicate()
			for k in gfx.keys():
				var v = cfg.get_value("graphics", k, gfx[k])
				if typeof(v) == typeof(gfx[k]) or (typeof(v) in [TYPE_INT, TYPE_FLOAT] and typeof(gfx[k]) in [TYPE_INT, TYPE_FLOAT]):
					gfx[k] = v
	elif cfg.has_section_key("display", "graphics"):
		graphics = int(cfg.get_value("display", "graphics", 1))
	fps_cap = int(cfg.get_value("display", "fps_cap", fps_cap))
	if not _looks_first:
		# Once, for settings saved before 0.29: the softening goes off. It is off unless you ask.
		_looks_first = true
		hold_fps = false


var _looks_first := false


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "resolution", resolution)
	cfg.set_value("display", "fs_resolution", fs_resolution)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("game", "anim_speed", anim_speed)
	cfg.set_value("game", "card_folder", card_folder)
	cfg.set_value("game", "field_theme", field_theme)
	cfg.set_value("game", "language", language)
	cfg.set_value("game", "sleeve", sleeve)
	cfg.set_value("display", "show_fps", show_fps)
	cfg.set_value("display", "hold_fps", hold_fps)
	cfg.set_value("display", "looks_first", true)
	cfg.set_value("graphics", "preset", gfx_preset)
	for k in gfx:
		cfg.set_value("graphics", k, gfx[k])
	cfg.set_value("display", "fps_cap", fps_cap)
	cfg.save(PATH)


## The frame rate cap. V-Sync is what held the game at the screen's 60, so every choice but
## "Match screen" turns it off.
func apply_fps() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if fps_cap < 0 else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = maxi(fps_cap, 0)


static func fps_name(cap: int) -> String:
	return "Unlimited" if cap == 0 else ("Match screen (V-Sync)" if cap < 0 else "%d FPS" % cap)


func apply() -> void:
	Loc.setup(language)
	_apply_audio()
	if not _is_desktop():
		changed.emit()
		return
	apply_fps()
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
	# Resizing the window can rebuild the screen buffers with V-Sync back on: set it once more.
	apply_fps.call_deferred()
	_apply_scale.call_deferred()
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
