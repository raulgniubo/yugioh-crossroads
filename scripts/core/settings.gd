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
## Voices in duels (0.62.0): the master switch, how loud, and who talks.
var voices_on := true
var voice_volume := 0.9
var voice_opp := true
var voice_lumen := 0         # Lumen: 0 warm, 1 bright, 2 calm, 3 no voice
var talk := 1                # how much duelists talk: 0 the big moments only, 1 the calls of a turn too, 2 every action
var voice_me := 0            # your duelist: 0 the voice that fits their look, 1 male A, 2 male B, 3 female A, 4 female B, 5 no voice
var anim_speed := 1.0
var crowd_cam := true         # after a big hit the camera glances at the people watching
var ask_always := false       # duels: stop at every chance to use a card (off: only when there is something to answer)
var destiny_draw := true        # Destiny Draw is part of duels (once per duel, when you are in trouble)
var cpu_level := 2              # how opponents think in Story and in the worlds: 1 Normal, 2 Hard, 3 Extreme (Free Duel has its own buttons)
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
const FPS_CAPS := [0, 30, 60, 120, 144, 240]
## V-Sync is its own switch: it stops tearing by waiting for the screen, and it works together
## with any cap (60 FPS with V-Sync on is a steady, tear-free 60).
var vsync := false
## Controller (see Pad): button pictures, stick speeds, rumble, and which physical button does what.
var pad_layout := "auto"      # auto | xbox | ps | nintendo
var mouse_look := true        # open world: moving the mouse turns the camera (pointer hidden while walking)
var mouse_sens := 1.0
var mouse_invert := false
var big_shows := true
var opening := true             # play the short opening every time the game starts
var free_difficulty := 2       # Free Duel: 1 Easy, 2 Normal, 3 Hard (its own, not whatever the last duel was)
var card_showcase := false     # hold an activated Spell or Trap up in the middle to be read before it acts
var live_portraits := true     # the two duelists in the corners of a duel are the real 3D duelists, moving (off: still pictures)
var cam_cuts := 0               # looks at a duelist during a duel: 0 Full, 1 Fewer (ace, direct attack, the end), 2 Off
var roam_list_small := false    # Free Roam: the "On your list" box put away as one small line (Tab / R3)
var chain_pace := 0             # how fast a chain is shown, link by link: 0 Normal, 1 Slower, 2 Fast
var turn_beat := 0              # a moment on the duelist as each turn opens: 0 Full, 1 Short, 2 Off
var _lang_kept := ""            # the saved language while --lang= is trying another one          # the full-screen summon and attack scenes (SummonShow)
var pad_show := "auto"        # which buttons the game shows: auto | keys | pad
var pad_cam := 1.0            # camera turn speed with the right stick
var pad_pointer := 1.0        # pointer speed with the stick
var pad_invert := false       # push up to look down
var pad_rumble := true
var pad_map := {}             # physical button index -> the button it acts as (only changed ones)
## Graphics. Every effect has its own switch; a preset fills them all in, and changing any one
## of them by hand turns the preset into "Custom".
signal gfx_changed

const GFX_PRESET_NAMES := ["Low", "Medium", "High", "Ultra", "Max"]
## Low runs on a modest laptop and still has glow and shadows. Ultra is everything on, drawn
## at a sensible size and brought up to the screen's. Max is Ultra at the screen's full size
## with nothing held back: for very strong machines, and for pictures.
const GFX_PRESETS := [
	{"res": 0, "aa": 1, "shadows": 1, "ao": false, "reflect": false, "glow": true, "fog": false, "gi": false, "detail": 0, "people": 0, "upscale": 1},
	{"res": 2, "aa": 1, "shadows": 2, "ao": true, "reflect": false, "glow": true, "fog": false, "gi": false, "detail": 1, "people": 1, "upscale": 1},
	{"res": 3, "aa": 2, "shadows": 2, "ao": true, "reflect": false, "glow": true, "fog": false, "gi": false, "detail": 2, "people": 1, "upscale": 2},
	{"res": 3, "aa": 2, "shadows": 3, "ao": true, "reflect": true, "glow": true, "fog": true, "gi": true, "detail": 3, "people": 2, "upscale": 2},
	{"res": 4, "aa": 3, "shadows": 3, "ao": true, "reflect": true, "glow": true, "fog": true, "gi": true, "detail": 3, "people": 2, "upscale": 2},
]
## How many lines the 3D picture is drawn at before it is fitted to the window. On a Retina
## or 4K screen "Native" is a huge number of pixels, and the biggest single cost there is.
const RES_NAMES := ["720p", "900p", "1080p", "1440p", "Native"]
const RES_LINES := [720, 900, 1080, 1440, 0]
const AA_NAMES := ["Off", "FXAA (fast)", "MSAA 2x", "MSAA 4x (sharpest)"]
const SHADOW_NAMES := ["Off", "Low", "Medium", "High"]
const DETAIL_NAMES := ["Off", "Some", "More", "Full"]
const PEOPLE_NAMES := ["Few", "Normal", "Busy"]
## How a 3D picture drawn below the window's size is blown back up to it. 0 = plain,
## 1 = sharpened (FSR 1; MetalFX on a Mac), 2 = rebuilt from several frames (FSR 2; MetalFX
## Temporal on a Mac). Only does something when "3D resolution" is below the window's own.
const UPSCALE_NAMES := ["Off", "FSR 1", "FSR 2"]
const UPSCALE_NAMES_MAC := ["Off", "MetalFX", "MetalFX Temporal"]


## True when this Mac draws with Metal, where Apple's own upscaler is the better one.
static func metalfx() -> bool:
	return OS.get_name() == "macOS" and RenderingServer.get_current_rendering_driver_name() == "metal"


static func upscale_names() -> Array:
	return UPSCALE_NAMES_MAC if metalfx() else UPSCALE_NAMES


## Upscaling needs the full renderer (Forward+). The light one only stretches the picture.
static func upscale_ok() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"
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
	# On Max nothing ever switches: every model is drawn with all it has.
	var maxed := gfx_preset == GFX_PRESETS.size() - 1
	vp.mesh_lod_threshold = 0.0 if maxed else [4.0, 2.0, 1.0, 1.0][clampi(int(gfx.get("detail", 2)), 0, 3)]
	if fplus:
		# Bounce light is worked out at half size and spread over a few frames, except on Max.
		# It is soft by nature, so the picture is the same and the cost is a fraction.
		RenderingServer.gi_set_use_half_resolution(not maxed)
		# 0.33.20: bounce light was still the second biggest cost on Ultra (9 ms of 30 on an M4
		# Max). It changes slowly by nature: it is spread over more frames (30 instead of 20),
		# the lamps feed it every 16th frame instead of every 8th, and the near kind (the one
		# worked out from the picture itself) uses fewer samples before it is blurred. Max keeps all.
		RenderingServer.environment_set_sdfgi_frames_to_converge(RenderingServer.ENV_SDFGI_CONVERGE_IN_10_FRAMES if maxed else RenderingServer.ENV_SDFGI_CONVERGE_IN_30_FRAMES)
		RenderingServer.environment_set_sdfgi_frames_to_update_light(RenderingServer.ENV_SDFGI_UPDATE_LIGHT_IN_2_FRAMES if maxed else RenderingServer.ENV_SDFGI_UPDATE_LIGHT_IN_16_FRAMES)
		RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_MEDIUM if maxed else RenderingServer.ENV_SSIL_QUALITY_LOW, true, 0.5, 4, 50.0, 300.0)
		# Soft corner shading: fewer samples on Medium (where it is new), the usual on High and up.
		RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_LOW if int(gfx.get("detail", 2)) <= 1 else RenderingServer.ENV_SSAO_QUALITY_MEDIUM, true, 0.5, 2, 50.0, 300.0)
		RenderingServer.environment_set_volumetric_fog_volume_size(96 if maxed else 64, 96 if maxed else 48)
		# (From a real report, an M4 Max on a 4480x2520 screen: haze and bounce light were each
		# the difference between 30 and a locked 60. Fewer rays per probe, a shallower haze grid.)
		RenderingServer.environment_set_sdfgi_ray_count(RenderingServer.ENV_SDFGI_RAY_COUNT_16 if maxed else RenderingServer.ENV_SDFGI_RAY_COUNT_8)
		RenderingServer.environment_set_volumetric_fog_filter_active(true)
	gfx_changed.emit()


## The frame rate the game tries to hold: the cap you picked, else 60.
func fps_target() -> float:
	if fps_cap > 0:
		return float(mini(fps_cap, 60)) if fps_cap < 60 else 60.0
	return 60.0


const HOLD_FLOOR := 0.75
var hold_gave_up := false     # shrinking the picture was not helping here (until the next place)
var _hold_was := 0.0          # the frame rate just before the last step down
var _hold_gain := 0           # steps down in a row that bought nothing
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
	# Did the last step down buy anything? Where the slow part is not the number of pixels (light
	# haze, bounce light, many people), a smaller picture is only a worse picture. Two steps
	# with nothing to show for them and the picture goes back to full, and stays there for
	# this place.
	if _hold_was > 0.0:
		_hold_gain = _hold_gain + 1 if fps < _hold_was * 1.04 else 0
		_hold_was = 0.0
		if _hold_gain >= 2:
			hold_gave_up = true
			auto_k = 1.0
			_hold_gain = 0
			_apply_scale()
			Router.toast.call_deferred(Loc.t("A smaller picture does not make this place faster, so it stays sharp. For more speed turn down Light haze or Bounce light."))
			return
	if hold_gave_up:
		return
	if fps < want * 0.92:
		# Too slow: soften. A big miss takes a bigger step. Never below three quarters: under
		# that the picture falls apart long before the frame rate is saved.
		auto_k = maxf(HOLD_FLOOR, auto_k * (0.9 if fps < want * 0.75 else 0.95))
		_hold_ceiling = before
		_hold_cool = 12.0
		_hold_good = 0.0
		if auto_k < before:
			_hold_was = fps
	elif auto_k < 1.0:
		_hold_good += 0.75
		var room := spent > 0.1 and spent < (1000.0 / want) * 0.62
		var may_try := _hold_good > (2.0 if room else 9.0)
		if may_try and (_hold_cool <= 0.0 or auto_k * 1.05 < _hold_ceiling):
			auto_k = minf(1.0, auto_k * 1.05)
			_hold_good = 0.0
	if not is_equal_approx(before, auto_k):
		_apply_scale()


## The least the 3D picture may be scaled down to on the screen that is showing (0: no floor).
var scale_floor := 0.0:
	set(v):
		scale_floor = v
		if is_inside_tree():
			_apply_scale()


func _apply_scale() -> void:
	var vp := get_tree().root
	var lines: int = RES_LINES[clampi(int(gfx["res"]), 0, RES_LINES.size() - 1)]
	var h := float(vp.size.y)
	var k := 1.0 if (lines == 0 or h <= float(lines)) else clampf(float(lines) / h, 0.35, 1.0)
	if fullscreen and fs_resolution.y > 0 and h > float(fs_resolution.y):
		# Fullscreen at a lower resolution: the 3D picture is drawn that small and scaled up.
		k = minf(k, clampf(float(fs_resolution.y) / h, 0.3, 1.0))
	var held := hold_fps and auto_k < 0.999
	if held:
		# Holding the frame rate may soften the picture, but never to less than 1080 lines (the
		# "720p" look on a big screen was this going down to 30%).
		k = maxf(k * auto_k, minf(k, 1080.0 / h))
	k = clampf(k, 0.3, 1.0)
	# A screen that is mostly a backdrop (the home screen's city) is never drawn so small that it
	# turns to blocks behind sharp menus, whatever the duel and world resolution is set to.
	k = clampf(maxf(k, scale_floor), 0.3, 1.0)
	var up := clampi(int(gfx.get("upscale", 1)), 0, 2) if upscale_ok() else 0
	if held and up == 1:
		up = 2          # a picture shrunk to hold the frame rate is rebuilt, not just stretched
	var mode := Viewport.SCALING_3D_MODE_BILINEAR
	if k < 0.99 and up == 1:
		mode = Viewport.SCALING_3D_MODE_METALFX_SPATIAL if metalfx() else Viewport.SCALING_3D_MODE_FSR
	elif k < 0.99 and up == 2:
		# The frame-to-frame upscalers cannot start from less than half the size.
		k = maxf(k, 0.5)
		mode = Viewport.SCALING_3D_MODE_METALFX_TEMPORAL if metalfx() else Viewport.SCALING_3D_MODE_FSR2
	if vp.scaling_3d_mode != mode:
		vp.scaling_3d_mode = mode
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


## A place to nudge one scene's light on the full renderer only (and to try values from the
## command line). With ShaderFix in place the defaults change nothing.
static func fplus_env(e: Environment, amb := 1.0, fog := 1.0, exposure := 1.0) -> void:
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		return
	var tm := -1
	var refl := true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fpenv="):          # dev: --fpenv=amb:0.5,fog:0.3,exp:1.0,tm:3,refl:1
			for kv in a.substr(8).split(","):
				var v := float(kv.get_slice(":", 1))
				match kv.get_slice(":", 0):
					"amb": amb = v
					"fog": fog = v
					"exp": exposure = v
					"tm": tm = int(v)
					"refl": refl = v > 0.5
					"bloom": e.glow_bloom *= v
					"glow": e.glow_intensity *= v
					"ssao": e.ssao_intensity *= v
					"gmode": e.glow_blend_mode = int(v) as Environment.GlowBlendMode
	e.ambient_light_energy *= amb
	e.fog_density *= fog
	e.volumetric_fog_density *= fog
	e.tonemap_exposure *= exposure
	if not refl:
		e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	if tm >= 0:
		e.tonemap_mode = [Environment.TONE_MAPPER_AGX, Environment.TONE_MAPPER_FILMIC, Environment.TONE_MAPPER_ACES, Environment.TONE_MAPPER_LINEAR][clampi(tm, 0, 3)]


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
	Voices.warm.call_deferred()
	# Before anything reads a save: a load, a new game or leaving admin mode asked for last run.
	Saves.session_start()
	Saves.apply_pending()
	Saves.pull_shared()
	Saves.read_admin()
	Saves.pull_live()
	Saves.guard_files()
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
			_lang_kept = language       # (dev: for this run only, the saved choice stays)
			language = a.substr(7)
	apply()
	apply_graphics()
	# With the game folder beside the game, the game you are playing is copied into it as you
	# go (and once more on the way out), so that folder is all another computer needs.
	if Saves.portable():
		var keep := Timer.new()
		keep.wait_time = 15.0
		keep.autostart = true
		keep.timeout.connect(Saves.push_live)
		add_child(keep)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		Saves.push_live()
		Saves.session_end()


## Where the game's own folder is looked for first: "Crossroads Data" beside the game. It
## holds the cards, your own models and the saves. Without it, Documents/Crossroads/assets.
func default_card_folder() -> String:
	var beside := Saves.game_dir().path_join(Saves.DATA_NAME)
	if DirAccess.dir_exists_absolute(beside):
		return beside
	return old_default_folder()


func old_default_folder() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Crossroads/assets")


## True on the very first start: the graphics were picked for this machine, not by you yet.
var first_run_pick := false
var first_language := false    # the very first start: ask which language before anything else


## A starting preset that fits the graphics chip. A guess from its name, on the careful side:
## a smooth first minute matters more than the last bit of shine, and Settings is one click away.
func suggest_preset() -> int:
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		return 0
	var n := RenderingServer.get_video_adapter_name().to_lower()
	var kind := RenderingServer.get_video_adapter_type()
	if n.contains("apple"):
		if n.contains("max") or n.contains("ultra"):
			return 3
		if n.contains("pro"):
			return 2
		return 2 if (n.contains("m3") or n.contains("m4") or n.contains("m5")) else 1
	var num := 0
	var rx := RegEx.new()
	rx.compile("(\\d{3,4})")
	var hit := rx.search(n)
	if hit:
		num = int(hit.get_string(1))
	if n.contains("rtx"):
		var tier := num % 100
		return 3 if (tier >= 70 or (num >= 3000 and tier >= 80)) and num >= 3000 else 2
	if n.contains("gtx"):
		return 2 if num >= 1070 and num < 1600 else 1
	if n.contains("radeon") and n.contains("rx") and num > 0:
		var t := num % 1000
		if num >= 6000:
			return 3 if t >= 800 or (num >= 9000 and t >= 70) else 2
		return 1
	if n.contains("arc"):
		return 2 if num >= 700 or n.contains("b5") else 1
	if kind == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU or n.contains("intel") or n.contains("uhd") or n.contains("iris"):
		return 0
	if kind == RenderingDevice.DEVICE_TYPE_CPU or n.contains("llvmpipe") or n.contains("swiftshader"):
		return 0
	return 2 if kind == RenderingDevice.DEVICE_TYPE_DISCRETE_GPU else 1


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		if DisplayServer.get_name() != "headless":
			first_run_pick = true
			first_language = true
			fullscreen = true          # a game starts on the whole screen the first time, not in a small window
			set_gfx_preset(suggest_preset())
		return
	var fresh := [fullscreen, resolution, fs_resolution]
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	resolution = cfg.get_value("display", "resolution", resolution)
	fs_resolution = cfg.get_value("display", "fs_resolution", fs_resolution)
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	voices_on = bool(cfg.get_value("audio", "voices", voices_on))
	voice_volume = cfg.get_value("audio", "voice", voice_volume)
	voice_opp = bool(cfg.get_value("audio", "voice_opp", voice_opp))
	voice_lumen = clampi(int(cfg.get_value("audio", "lumen_voice", voice_lumen)), 0, 3)
	voice_me = clampi(int(cfg.get_value("audio", "my_voice", voice_me)), 0, 5)
	talk = clampi(int(cfg.get_value("audio", "talk", talk)), 0, 2)
	anim_speed = cfg.get_value("game", "anim_speed", anim_speed)
	crowd_cam = bool(cfg.get_value("game", "crowd_cam", crowd_cam))
	ask_always = bool(cfg.get_value("game", "ask_always", ask_always))
	destiny_draw = bool(cfg.get_value("game", "destiny_draw", destiny_draw))
	cpu_level = clampi(int(cfg.get_value("game", "cpu_level", cpu_level)), 1, 3)
	card_folder = cfg.get_value("game", "card_folder", card_folder)
	field_theme = cfg.get_value("game", "field_theme", field_theme)
	language = cfg.get_value("game", "language", language)
	sleeve = str(cfg.get_value("game", "sleeve", sleeve))
	pad_layout = str(cfg.get_value("pad", "layout", pad_layout))
	pad_show = str(cfg.get_value("pad", "show", pad_show))
	mouse_look = bool(cfg.get_value("game", "mouse_look", mouse_look))
	mouse_sens = float(cfg.get_value("game", "mouse_sens", mouse_sens))
	mouse_invert = bool(cfg.get_value("game", "mouse_invert", mouse_invert))
	big_shows = bool(cfg.get_value("game", "big_shows", big_shows))
	card_showcase = bool(cfg.get_value("game", "card_showcase", card_showcase))
	cam_cuts = clampi(int(cfg.get_value("game", "cam_cuts", cam_cuts)), 0, 2)
	live_portraits = bool(cfg.get_value("game", "live_portraits", live_portraits))
	turn_beat = clampi(int(cfg.get_value("game", "turn_beat", turn_beat)), 0, 2)
	chain_pace = clampi(int(cfg.get_value("game", "chain_pace", chain_pace)), 0, 2)
	roam_list_small = bool(cfg.get_value("game", "roam_list_small", roam_list_small))
	opening = bool(cfg.get_value("game", "opening", opening))
	free_difficulty = clampi(int(cfg.get_value("game", "free_difficulty", free_difficulty)), 1, 3)
	pad_cam = float(cfg.get_value("pad", "cam", pad_cam))
	pad_pointer = float(cfg.get_value("pad", "pointer", pad_pointer))
	pad_invert = bool(cfg.get_value("pad", "invert", pad_invert))
	pad_rumble = bool(cfg.get_value("pad", "rumble", pad_rumble))
	pad_map = cfg.get_value("pad", "map", pad_map)
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
	vsync = bool(cfg.get_value("display", "vsync", fps_cap < 0))
	if fps_cap < 0:
		fps_cap = 0          # (older saves: "Match screen" was one of the caps)
	if not _looks_first:
		# Once, for settings saved before 0.29: the softening goes off. It is off unless you ask.
		_looks_first = true
		hold_fps = false
	if not bool(cfg.get_value("display", "hold_reset_0338", false)):
		# Once more with 0.33.8: until then it could shrink the picture to 30% (a 720p look on a
		# big screen). It goes off; whoever wants it turns it on knowing what it does.
		hold_fps = false
	# The settings travel inside the game folder. On a different computer everything about you
	# stays (sound, language, speed, sleeve...), but the picture is picked again for the machine
	# in front of it: Ultra from a fast Mac is the wrong start on a small laptop.
	var was := str(cfg.get_value("display", "machine", ""))
	if was != "" and was != machine() and DisplayServer.get_name() != "headless":
		first_run_pick = true
		set_gfx_preset(suggest_preset())
		fullscreen = fresh[0]
		resolution = fresh[1]
		fs_resolution = fresh[2]
		hold_fps = false
		save_settings.call_deferred()
		print("SETTINGS came from another computer (", was, "): graphics picked again for ", machine())


## This computer, as far as the picture is concerned.
func machine() -> String:
	return "%s | %s" % [OS.get_name(), RenderingServer.get_video_adapter_name()]


var _looks_first := false


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "resolution", resolution)
	cfg.set_value("display", "fs_resolution", fs_resolution)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "voices", voices_on)
	cfg.set_value("audio", "voice", voice_volume)
	cfg.set_value("audio", "voice_opp", voice_opp)
	cfg.set_value("audio", "lumen_voice", voice_lumen)
	cfg.set_value("audio", "my_voice", voice_me)
	cfg.set_value("audio", "talk", talk)
	cfg.set_value("game", "anim_speed", anim_speed)
	cfg.set_value("game", "crowd_cam", crowd_cam)
	cfg.set_value("game", "ask_always", ask_always)
	cfg.set_value("game", "destiny_draw", destiny_draw)
	cfg.set_value("game", "cpu_level", cpu_level)
	cfg.set_value("game", "card_folder", card_folder)
	cfg.set_value("game", "field_theme", field_theme)
	cfg.set_value("game", "language", _lang_kept if _lang_kept != "" else language)
	cfg.set_value("game", "sleeve", sleeve)
	cfg.set_value("pad", "layout", pad_layout)
	cfg.set_value("pad", "show", pad_show)
	cfg.set_value("game", "mouse_look", mouse_look)
	cfg.set_value("game", "mouse_sens", mouse_sens)
	cfg.set_value("game", "mouse_invert", mouse_invert)
	cfg.set_value("game", "big_shows", big_shows)
	cfg.set_value("game", "card_showcase", card_showcase)
	cfg.set_value("game", "cam_cuts", cam_cuts)
	cfg.set_value("game", "live_portraits", live_portraits)
	cfg.set_value("game", "turn_beat", turn_beat)
	cfg.set_value("game", "chain_pace", chain_pace)
	cfg.set_value("game", "roam_list_small", roam_list_small)
	cfg.set_value("game", "free_difficulty", free_difficulty)
	cfg.set_value("game", "opening", opening)
	cfg.set_value("pad", "cam", pad_cam)
	cfg.set_value("pad", "pointer", pad_pointer)
	cfg.set_value("pad", "invert", pad_invert)
	cfg.set_value("pad", "rumble", pad_rumble)
	cfg.set_value("pad", "map", pad_map)
	cfg.set_value("display", "show_fps", show_fps)
	cfg.set_value("display", "hold_fps", hold_fps)
	cfg.set_value("display", "looks_first", true)
	cfg.set_value("display", "hold_reset_0338", true)
	cfg.set_value("graphics", "preset", gfx_preset)
	for k in gfx:
		cfg.set_value("graphics", k, gfx[k])
	cfg.set_value("display", "fps_cap", fps_cap)
	cfg.set_value("display", "vsync", vsync)
	if DisplayServer.get_name() != "headless":
		cfg.set_value("display", "machine", machine())
	cfg.save(PATH)


## The frame rate cap and V-Sync, each on its own.
func apply_fps() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = maxi(fps_cap, 0)


static func fps_name(cap: int) -> String:
	return "Unlimited" if cap <= 0 else "%d FPS" % cap


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
	for bus_name in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _apply_audio() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	_set_bus("Voice", voice_volume)


func _set_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
		AudioServer.set_bus_mute(idx, value <= 0.001)
