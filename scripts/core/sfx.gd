extends Node
## Procedural sound effects (no audio files needed yet). Sfx.play("click")

const RATE := 22050

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 42
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	for i in 2:
		var ap := AudioStreamPlayer.new()
		ap.bus = "SFX"
		ap.volume_db = -60.0
		add_child(ap)
		_amb.append(ap)
	_sounds["hover"] = _tone([1320.0], 0.04, 0.002, 0.25, 0.0, 0.0)
	_sounds["click"] = _tone([880.0, 1320.0], 0.09, 0.003, 0.35, 0.0, 0.05)
	_sounds["back"] = _tone([660.0, 440.0], 0.1, 0.003, 0.3, -0.4, 0.0)
	_sounds["draw"] = _noise(0.16, 0.25, 3000.0, 6000.0)
	_sounds["card"] = _noise(0.12, 0.3, 1500.0, 500.0)
	_sounds["summon"] = _tone([523.25, 659.25, 783.99, 1046.5], 0.7, 0.01, 0.35, 0.25, 0.06)
	_sounds["special"] = _mix(_tone([392.0, 523.25, 659.25, 987.77], 1.3, 0.02, 0.4, 0.4, 0.09), _noise(1.3, 0.25, 400.0, 5000.0))
	_sounds["attack"] = _noise(0.35, 0.6, 5000.0, 600.0)
	_sounds["impact"] = _mix(_tone([70.0, 55.0], 0.45, 0.002, 0.9, -0.6, 0.0), _noise(0.3, 0.5, 2500.0, 200.0))
	_sounds["destroy"] = _mix(_noise(0.6, 0.6, 6000.0, 300.0), _tone([220.0, 110.0], 0.5, 0.002, 0.3, -0.8, 0.0))
	_sounds["damage"] = _tone([440.0, 330.0], 0.5, 0.005, 0.4, -0.5, 0.0)
	_sounds["heal"] = _tone([659.25, 783.99, 1046.5], 0.5, 0.01, 0.3, 0.2, 0.08)
	_sounds["spell"] = _mix(_tone([987.77, 1318.5], 0.5, 0.01, 0.3, 0.1, 0.07), _noise(0.4, 0.15, 6000.0, 8000.0))
	_sounds["turn"] = _noise(0.45, 0.35, 800.0, 4000.0)
	_sounds["vs"] = _mix(_tone([110.0, 164.81, 220.0], 1.2, 0.005, 0.6, 0.0, 0.0), _noise(0.5, 0.5, 3000.0, 400.0))
	_sounds["firework"] = _mix(_tone([95.0, 60.0], 0.5, 0.002, 0.7, -0.5, 0.0), _noise(0.9, 0.3, 4500.0, 9000.0))
	_sounds["win"] = _tone([523.25, 659.25, 783.99, 1046.5, 1318.5], 1.4, 0.01, 0.35, 0.0, 0.12)
	_sounds["lose"] = _tone([392.0, 349.23, 293.66, 261.63], 1.4, 0.01, 0.35, 0.0, 0.18)
	if DisplayServer.get_name() != "headless":
		_thread = Thread.new()
		_thread.start(_build_more)


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		n.mouse_entered.connect(func():
			if not n.disabled:
				play("hover", -14.0))
		n.pressed.connect(func(): play("click", -8.0))


var _last := {}       # sound name -> msec it last played (the same sound twice in a blink is one sound)


func stream(name: String) -> AudioStream:
	return _sounds.get(name)


## Extra loudness for everything played while it is set (a duel turns it up, then back to 0).
var boost_db := 0.0


## Level trims from the sound audit (--sound-audit), in dB.
const TRIM := {"direct": -4.0, "destroy": -3.5, "attack": -3.5, "pack_rip": -3.0, "impact": -3.0, "vs": -1.5}


## Your own sounds: a file named like the sound (click.ogg, summon.wav, attack.mp3...) in a folder
## called "sounds" inside your card folder plays instead of the built-in one. Nothing is bundled.
var _own := {}


static func load_audio(path: String) -> AudioStream:
	var ext := path.get_extension().to_lower()
	if not FileAccess.file_exists(path):
		return null
	match ext:
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"wav":
			return AudioStreamWAV.load_from_file(path)
	return null


static func own_file(folder: String, name: String) -> AudioStream:
	var card_folder := str(Engine.get_main_loop().root.get_node("Settings").card_folder) if Engine.get_main_loop() and Engine.get_main_loop().root.has_node("Settings") else ""
	if card_folder == "":
		return bundled(folder, name)
	for ext in ["ogg", "wav", "mp3"]:
		var s := load_audio(card_folder.path_join(folder).path_join(name + "." + ext))
		if s != null:
			return s
	return bundled(folder, name)


func _own_sound(name: String) -> AudioStream:
	if not _own.has(name):
		_own[name] = own_file("sounds", name)
	return _own[name]


## (0.87.0) The sounds that come with the game: res://audio/<folder>/<name>.ogg (made with ElevenLabs,
## see tools/dev/sound/). A file of yours in the card folder still wins; with neither, the tone
## made by code plays as before, so a missing file never leaves a hole.
static func bundled(folder: String, name: String) -> AudioStream:
	var path := "res://audio/%s/%s.ogg" % [folder, name]
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


## Is there a real sound (yours or the game's) by this name?
func has_own(name: String) -> bool:
	return _own_sound(name) != null


## Plays `name` only if there is a real sound for it. Returns whether it did: the caller then
## skips the tones it would have used instead.
func play_own(name: String, volume_db := 0.0, pitch := 1.0) -> bool:
	if _own_sound(name) == null:
		return false
	play(name, volume_db, pitch)
	return true


## Plays `name` when there is a real sound for it, else `fallback` (a name the game always had).
func play_or(name: String, fallback: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not play_own(name, volume_db, pitch):
		play(fallback, volume_db, pitch)


## Milliseconds since any sound last started: a notice chimes only when nothing else just spoke.
var _last_any := -100000

func quiet_ms() -> int:
	return Time.get_ticks_msec() - _last_any


## Forget your own sounds (the card folder changed): they are looked for again.
func reload_own() -> void:
	_own.clear()
	_own_loops.clear()


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var mine := _own_sound(name)
	if not _sounds.has(name) and mine == null:
		return
	# The loudest hits were sitting 10 dB over everything else: bring them back into the mix.
	volume_db = minf(volume_db + boost_db + float(TRIM.get(name, 0.0)), 6.0)
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, -1000)) < 45:
		return
	_last[name] = now
	_last_any = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = mine if mine != null else _sounds[name]
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()


# ------------------------------------------------------------------ the bigger sound set

var _thread: Thread
var _amb: Array[AudioStreamPlayer] = []
var _amb_on := 0
var _amb_name := ""
var _amb_want := ""


## Built on a thread right after launch so the game opens at once. Until a sound is ready,
## play() for it is simply silent.
func _build_more() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var add := {}
	add["coin"] = _tone([1318.5, 1760.0, 2093.0], 0.35, 0.002, 0.3, 0.0, 0.05)
	add["step"] = _noise(0.07, 0.3, 900.0, 200.0)
	add["blip"] = _tone([520.0], 0.05, 0.002, 0.22, 0.1, 0.0)
	add["whoosh"] = _noise(0.4, 0.4, 400.0, 5000.0)
	# (0.60.0) What each Attribute's attack sounds like: gathering, crossing the field, landing.
	add["el_fire_up"] = _noise(0.5, 0.4, 300.0, 2600.0)
	add["el_fire"] = _mix(_noise(0.45, 0.5, 2400.0, 500.0), _tone([90.0, 70.0], 0.4, 0.01, 0.3, 0.3, 0.0))
	add["el_fire_hit"] = _mix(_mix(_tone([62.0, 44.0], 0.8, 0.003, 0.95, -0.5, 0.0), _noise(0.9, 0.6, 1800.0, 150.0)), _noise(0.35, 0.4, 5000.0, 900.0))
	add["el_water_up"] = _mix(_noise(0.5, 0.35, 900.0, 4200.0), _tone([520.0, 780.0], 0.3, 0.01, 0.12, 0.6, 0.08))
	add["el_water"] = _noise(0.5, 0.55, 3200.0, 900.0)
	add["el_water_hit"] = _mix(_mix(_noise(0.95, 0.65, 5200.0, 500.0), _tone([84.0, 60.0], 0.5, 0.003, 0.7, -0.5, 0.0)), _tone([900.0, 1300.0, 700.0], 0.35, 0.004, 0.1, 0.5, 0.07))
	add["el_wind"] = _mix(_noise(0.6, 0.45, 500.0, 6500.0), _tone([330.0], 0.55, 0.12, 0.1, 0.9, 0.0))
	add["el_wind_hit"] = _mix(_mix(_noise(0.9, 0.55, 7000.0, 700.0), _tone([260.0, 390.0], 0.8, 0.08, 0.14, 0.8, 0.1)), _tone([70.0], 0.3, 0.003, 0.5, -0.4, 0.0))
	add["el_earth_up"] = _mix(_tone([48.0, 38.0], 0.6, 0.02, 0.7, -0.2, 0.0), _noise(0.5, 0.35, 500.0, 120.0))
	add["el_earth"] = _mix(_tone([55.0, 41.0], 0.5, 0.004, 0.75, -0.3, 0.0), _noise(0.45, 0.5, 1400.0, 200.0))
	add["el_earth_hit"] = _mix(_mix(_tone([46.0, 34.0, 58.0], 1.0, 0.002, 1.0, -0.45, 0.04), _noise(0.7, 0.7, 2200.0, 120.0)), _noise(0.25, 0.5, 4200.0, 1500.0))
	add["el_light_up"] = _mix(_tone([1046.5, 1318.5, 1568.0], 0.6, 0.02, 0.2, 0.3, 0.07), _noise(0.5, 0.1, 7000.0, 9000.0))
	add["el_light"] = _mix(_tone([1760.0, 2093.0], 0.35, 0.003, 0.22, 0.6, 0.02), _noise(0.3, 0.2, 8000.0, 4000.0))
	add["el_light_hit"] = _mix(_mix(_tone([783.99, 1046.5, 1568.0, 2093.0], 1.1, 0.004, 0.3, 0.1, 0.03), _tone([98.0, 74.0], 0.5, 0.003, 0.6, -0.4, 0.0)), _noise(0.5, 0.25, 9000.0, 2500.0))
	add["el_dark_up"] = _mix(_tone([73.4, 77.8], 0.7, 0.05, 0.5, -0.25, 0.0), _noise(0.6, 0.2, 300.0, 900.0))
	add["el_dark"] = _mix(_tone([110.0, 116.5], 0.5, 0.02, 0.4, -0.5, 0.0), _noise(0.45, 0.35, 1600.0, 300.0))
	add["el_dark_hit"] = _mix(_mix(_tone([55.0, 58.3, 41.2], 1.1, 0.004, 0.9, -0.55, 0.05), _noise(0.8, 0.45, 1200.0, 100.0)), _tone([311.1, 220.0], 0.6, 0.01, 0.15, -0.6, 0.1))
	add["el_thunder"] = _mix(_noise(0.3, 0.6, 9000.0, 1200.0), _tone([120.0, 80.0], 0.35, 0.002, 0.5, -0.5, 0.0))
	add["el_thunder_hit"] = _mix(_mix(_tone([42.0, 33.0, 52.0], 1.4, 0.002, 1.0, -0.35, 0.06), _noise(1.2, 0.7, 6000.0, 90.0)), _noise(0.18, 0.7, 10000.0, 5000.0))
	add["set"] = _noise(0.18, 0.4, 700.0, 250.0)
	add["flip"] = _mix(_noise(0.2, 0.3, 2500.0, 900.0), _tone([740.0, 988.0], 0.25, 0.003, 0.22, 0.2, 0.05))
	add["trap"] = _mix(_tone([196.0, 233.08, 277.18], 0.7, 0.004, 0.5, -0.15, 0.03), _noise(0.3, 0.35, 3000.0, 400.0))
	add["chain"] = _tone([660.0, 990.0], 0.22, 0.002, 0.38, 0.3, 0.03)
	add["negate"] = _tone([140.0, 100.0], 0.45, 0.003, 0.55, -0.5, 0.0)
	add["counter"] = _tone([880.0, 660.0, 880.0, 660.0], 0.6, 0.002, 0.35, 0.0, 0.1)
	add["fusion"] = _mix(_noise(1.1, 0.35, 300.0, 6000.0), _tone([261.63, 329.63, 392.0, 523.25, 659.25], 1.3, 0.02, 0.4, 0.5, 0.12))
	add["synchro"] = _mix(_tone([523.25, 783.99, 1046.5, 1568.0], 1.2, 0.01, 0.35, 0.8, 0.1), _noise(0.9, 0.25, 6000.0, 1500.0))
	add["xyz"] = _mix(_tone([82.4, 110.0, 164.8], 1.3, 0.01, 0.6, -0.3, 0.05), _tone([1318.5, 1975.5, 2637.0], 1.1, 0.3, 0.22, 0.2, 0.15))
	add["ritual"] = _tone([220.0, 261.63, 329.63, 440.0, 523.25], 1.6, 0.25, 0.45, 0.0, 0.18)
	add["tribute"] = _mix(_noise(0.5, 0.35, 3000.0, 300.0), _tone([440.0, 220.0], 0.5, 0.005, 0.3, -0.5, 0.0))
	add["banish"] = _mix(_noise(0.6, 0.35, 300.0, 5000.0), _tone([880.0, 1760.0], 0.6, 0.2, 0.22, 0.6, 0.0))
	add["equip"] = _tone([1568.0, 2093.0], 0.25, 0.002, 0.3, 0.0, 0.04)
	add["effect"] = _tone([783.99, 1174.66], 0.35, 0.005, 0.28, 0.15, 0.06)
	add["phase"] = _tone([440.0, 587.33], 0.22, 0.004, 0.28, 0.0, 0.05)
	add["gong"] = _mix(_tone([98.0, 147.0, 196.5, 294.3], 1.8, 0.004, 0.55, -0.02, 0.0), _noise(0.25, 0.3, 4000.0, 500.0))
	add["charge"] = _mix(_noise(0.5, 0.35, 300.0, 4500.0), _tone([110.0, 220.0], 0.5, 0.05, 0.3, 1.0, 0.0))
	add["direct"] = _mix(_tone([60.0, 45.0], 0.7, 0.002, 1.0, -0.6, 0.0), _noise(0.5, 0.7, 7000.0, 200.0))
	add["lp_drain"] = _tone([1200.0, 1100.0, 1000.0, 900.0, 800.0, 700.0, 600.0, 500.0], 0.6, 0.001, 0.28, 0.0, 0.055)
	add["pack_rip"] = _noise(0.5, 0.55, 6000.0, 1200.0)
	add["sparkle"] = _tone([2093.0, 2637.0, 3136.0, 3951.0], 0.7, 0.005, 0.22, 0.0, 0.07)
	add["rare"] = _mix(_tone([523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0], 1.6, 0.01, 0.45, 0.0, 0.09), _tone([2093.0, 2637.0, 3136.0, 3951.0], 1.5, 0.3, 0.18, 0.0, 0.2))
	add["error"] = _tone([196.0, 155.56], 0.3, 0.003, 0.4, -0.2, 0.08)
	add["quest"] = _tone([659.25, 783.99, 987.77, 1318.5], 1.0, 0.01, 0.38, 0.0, 0.11)
	add["door"] = _mix(_noise(0.3, 0.45, 500.0, 150.0), _tone([120.0], 0.3, 0.005, 0.3, -0.3, 0.0))
	add["panel"] = _noise(0.22, 0.28, 1200.0, 4200.0)
	# The open world: footsteps for each kind of ground, jumps, animals, small machines.
	add["step_wood"] = _mix(_noise(0.06, 0.3, 500.0, 180.0), _tone([150.0], 0.07, 0.002, 0.22, -0.3, 0.0))
	add["step_grass"] = _noise(0.11, 0.2, 2600.0, 900.0)
	add["step_sand"] = _noise(0.14, 0.2, 1500.0, 400.0)
	add["step_hall"] = _mix(_noise(0.05, 0.3, 1800.0, 500.0), _tone([420.0], 0.09, 0.002, 0.12, -0.2, 0.0))
	add["jump"] = _noise(0.16, 0.22, 500.0, 2400.0)
	add["land"] = _mix(_noise(0.1, 0.35, 700.0, 150.0), _tone([90.0], 0.12, 0.002, 0.3, -0.4, 0.0))
	add["meow"] = _tone([620.0, 780.0], 0.42, 0.04, 0.3, -0.28, 0.06)
	add["purr"] = _tone([27.0, 54.0, 81.0], 1.1, 0.2, 0.5, 0.0, 0.0)
	add["can"] = _mix(_tone([180.0, 240.0], 0.25, 0.002, 0.5, -0.4, 0.12), _noise(0.3, 0.3, 900.0, 300.0))
	add["fizz"] = _noise(0.6, 0.2, 7000.0, 9000.0)
	add["flutter"] = _mix(_noise(0.5, 0.3, 1200.0, 3200.0), _noise(0.5, 0.25, 2400.0, 900.0))
	add["gull"] = _tone([1250.0, 1180.0, 1320.0], 0.7, 0.03, 0.2, -0.22, 0.2)
	add["chirp"] = _tone([3100.0, 3600.0, 3300.0, 3900.0], 0.42, 0.004, 0.14, 0.12, 0.09)
	add["chirp2"] = _tone([2500.0, 2900.0, 2500.0], 0.5, 0.004, 0.13, -0.1, 0.14)
	add["cricket"] = _tone([4300.0, 4300.0, 4300.0, 4300.0], 0.42, 0.002, 0.07, 0.0, 0.09)
	add["horn"] = _tone([392.0, 494.0], 0.5, 0.02, 0.16, 0.0, 0.0)
	add["hey"] = _tone([440.0, 554.0], 0.16, 0.01, 0.2, 0.25, 0.05)
	add["sit"] = _noise(0.2, 0.22, 400.0, 150.0)
	add["pickup"] = _tone([880.0, 1174.66, 1568.0], 0.4, 0.003, 0.3, 0.0, 0.06)
	add["bell"] = _tone([1046.5, 2093.0, 3140.0], 1.2, 0.002, 0.22, 0.0, 0.0)
	add["wave"] = _noise(2.4, 0.3, 300.0, 1400.0)
	add["cheer"] = _crowd(2.4, 0.55, true, r)
	add["gasp"] = _crowd(1.0, 0.4, false, r)
	call_deferred("_add_sounds", add)
	var loops := {}
	# A steady splash for fountains (played from where the fountain stands).
	var wn := int(3.0 * RATE)
	var wb := PackedFloat32Array()
	wb.resize(wn)
	var lp1 := 0.0
	var lp2 := 0.0
	for i in wn:
		var x := r.randf_range(-1.0, 1.0)
		lp1 += 0.5 * (x - lp1)
		lp2 += 0.06 * (x - lp2)
		var edge := minf(1.0, minf(i, wn - i) / 2000.0)
		wb[i] = (lp1 - lp2) * 0.35 * edge * (0.8 + 0.2 * sin(i * 0.0021))
	var water := _to_wav(wb)
	water.loop_mode = AudioStreamWAV.LOOP_FORWARD
	water.loop_end = wn
	call_deferred("_add_sounds", {"water": water})
	for kind in ["city", "sea", "wind", "hum", "crowd", "shop", "engine", "rain"]:
		loops["amb_" + kind] = _ambience(6.0, kind, r)
		call_deferred("_add_sounds", loops.duplicate())
		loops.clear()
	# Each world has its own air. These are longer, so the loop is harder to hear.
	for kind in ["satellite", "heartland", "newdomino", "museum", "night", "tunnel"]:
		loops["amb_" + kind] = _world_air(13.0, kind, r)
		call_deferred("_add_sounds", loops.duplicate())
		loops.clear()
	call_deferred("_audit")


## The background of a place, built from a few layers: a bed of filtered noise, slow swells,
## and small events scattered through the loop (a clank, a whoosh, a chime, a cricket).
func _world_air(dur: float, kind: String, r: RandomNumberGenerator) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var a := 0.0
	var b := 0.0
	var c := 0.0
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var x := r.randf_range(-1.0, 1.0)
		var v := 0.0
		match kind:
			"satellite":
				# Wind through scrap: a low moan that rises and falls, with grit on top.
				a += (0.012 + 0.02 * (0.5 + 0.5 * sin(TAU * t / dur * 2.0))) * (x - a)
				b += 0.003 * (x - b)
				c += 0.3 * (x - c)
				ph += TAU * (48.0 + 6.0 * sin(TAU * t / dur)) / RATE
				v = (a - b) * 2.6 + sin(ph) * 0.035 + (x - c) * 0.012 * (0.5 + 0.5 * sin(TAU * t / dur * 5.0))
			"heartland":
				# A happy crowd a block away, under a bright electric shimmer.
				a += 0.3 * (x - a)
				b += 0.04 * (x - b)
				ph += TAU * 392.0 / RATE
				v = (a - b) * 0.42 * (0.75 + 0.25 * sin(TAU * t / dur * 4.0)) + (sin(ph) + sin(ph * 1.5)) * 0.006 * (0.5 + 0.5 * sin(TAU * t / dur * 3.0))
			"newdomino":
				# A clean city: a soft power hum, and far overhead the ring road.
				a += 0.02 * (x - a)
				b += 0.002 * (x - b)
				ph += TAU * 96.0 / RATE
				v = sin(ph) * 0.03 + sin(ph * 2.0) * 0.012 + (a - b) * 1.2 * (0.5 + 0.5 * sin(TAU * t / dur * 2.0))
			"museum":
				# Almost nothing: air, and two glass tones that never quite agree.
				a += 0.004 * (x - a)
				ph += TAU * 220.0 / RATE
				v = a * 1.6 + sin(ph) * 0.012 * (0.5 + 0.5 * sin(TAU * t / dur)) + sin(ph * 1.498) * 0.01 * (0.5 + 0.5 * sin(TAU * t / dur * 2.0 + 1.0))
			"night":
				# A warm night: far traffic and crickets.
				a += 0.008 * (x - a)
				ph += TAU * 4300.0 / RATE
				var chirp := maxf(0.0, sin(TAU * t * 17.0)) * maxf(0.0, sin(TAU * t / dur * 13.0 * 0.5))
				v = a * 2.0 + sin(ph) * 0.02 * chirp * chirp + sin(ph * 1.07) * 0.012 * maxf(0.0, sin(TAU * t * 13.0 + 1.0)) * maxf(0.0, sin(TAU * t / dur * 7.0 + 2.0))
			"tunnel":
				# An engine inside concrete: the same growl, boomier, with the walls rushing past.
				a += 0.05 * (x - a)
				b += 0.4 * (x - b)
				ph += TAU * 74.0 / RATE
				var saw := fmod(ph / TAU, 1.0) * 2.0 - 1.0
				v = saw * 0.04 + sin(ph * 0.5) * 0.1 + sin(ph * 0.25) * 0.06 + a * 0.9 + (x - b) * 0.02 * (0.5 + 0.5 * sin(TAU * t * 5.5))
		buf[i] = v * 0.5
	# Things that happen now and then.
	var events := {"satellite": 5, "heartland": 3, "newdomino": 2, "museum": 2, "night": 0, "tunnel": 0}
	for e in int(events.get(kind, 0)):
		var at := int(r.randf_range(0.08, 0.86) * n)
		var len_e := int(RATE * (0.5 if kind == "satellite" else 1.6))
		var f0 := r.randf_range(180.0, 420.0)
		var lp := 0.0
		for i in mini(len_e, n - at - 1):
			var k := float(i) / len_e
			var s := 0.0
			match kind:
				"satellite":
					# Metal knocking on metal somewhere in the yard.
					s = (sin(TAU * f0 * i / RATE) + 0.6 * sin(TAU * f0 * 2.76 * i / RATE) + 0.4 * sin(TAU * f0 * 5.4 * i / RATE)) * exp(-k * 9.0) * 0.07
				"heartland":
					# The monorail going over: a rising, falling rush of air.
					lp += (0.03 + 0.2 * sin(k * PI)) * (r.randf_range(-1.0, 1.0) - lp)
					s = lp * sin(k * PI) * 0.22
				"newdomino":
					# A runner on the ring, far away.
					s = sin(TAU * (120.0 + 90.0 * sin(k * PI)) * i / RATE) * sin(k * PI) * 0.02
				"museum":
					# One soft bell, a long way down a hall.
					s = (sin(TAU * f0 * 2.0 * i / RATE) + 0.5 * sin(TAU * f0 * 4.02 * i / RATE)) * exp(-k * 4.0) * 0.02
			buf[at + i] += s
	var fade := int(0.8 * RATE)
	for i in fade:
		var kf := float(i) / fade
		buf[i] = buf[i] * kf + buf[n - fade + i] * (1.0 - kf)
	buf.resize(n - fade)
	var w := _to_wav(buf)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = buf.size()
	return w


## The background for a world and an hour. Used wherever you walk.
func world_air(district: String, builder: String, theme: String, tod: String) -> void:
	var kind := "city"
	var vol := -16.0
	if builder == "academy":
		kind = "sea"
	elif builder == "museum":
		kind = "museum"
		vol = -13.0
	elif builder == "newdomino":
		kind = "newdomino"
	elif theme == "satellite":
		kind = "satellite"
		vol = -14.0
	elif theme == "heartland":
		kind = "heartland"
		vol = -15.0
	# After dark the two older towns go quiet: crickets instead of traffic.
	if tod == "night" and kind == "city":
		kind = "night"
		vol = -15.0
	ambience(kind, vol)


## --sound-audit: how loud is everything? Prints the level of every sound (dB, 0 is full
## scale) so nothing sits far above or below the rest.
func _audit() -> void:
	if not "--sound-audit" in OS.get_cmdline_user_args():
		return
	var names: Array = _sounds.keys()
	names.sort()
	for nm in names:
		var w = _sounds[nm]
		if not (w is AudioStreamWAV):
			continue
		var sm := _samples(w)
		if sm.is_empty():
			continue
		var sum := 0.0
		var peak := 0.0
		for v in sm:
			sum += v * v
			peak = maxf(peak, absf(v))
		print("SOUND %-22s rms %6.1f dB   peak %6.1f dB   %.2f s" % [nm, 20.0 * log(maxf(1e-6, sqrt(sum / sm.size()))) / log(10.0), 20.0 * log(maxf(1e-6, peak)) / log(10.0), float(sm.size()) / RATE])


func _add_sounds(more: Dictionary) -> void:
	for k in more:
		_sounds[k] = more[k]
	if _wx_want != "" and _sounds.has("amb_" + _wx_want) and (_wx == null or not _wx.playing):
		weather(_wx_want, _wx_db)
	if _amb_want != "" and _sounds.has("amb_" + _amb_want) and _amb_name != _amb_want:
		ambience(_amb_want)


## A crowd: band-limited noise that swells (a cheer) or jumps and falls (a gasp).
func _crowd(dur: float, gain: float, cheer: bool, r: RandomNumberGenerator) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lo := 0.0
	var hi := 0.0
	var wob := 0.0
	for i in n:
		var t := float(i) / n
		var x := r.randf_range(-1.0, 1.0)
		hi += 0.45 * (x - hi)
		lo += 0.07 * (x - lo)
		wob += 0.002 * (r.randf_range(-1.0, 1.0) - wob)
		var env := (minf(1.0, t * 5.0) * pow(1.0 - t, 1.2)) if cheer else (minf(1.0, t * 25.0) * pow(1.0 - t, 2.5))
		buf[i] = (hi - lo) * env * gain * 2.6 * (1.0 + wob * 30.0) * (0.75 + 0.25 * sin(t * dur * TAU * 6.0))
	return _to_wav(buf)


## A seamless background loop for a kind of place.
func _ambience(dur: float, kind: String, r: RandomNumberGenerator) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var a := 0.0
	var b := 0.0
	var c := 0.0
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var x := r.randf_range(-1.0, 1.0)
		var v := 0.0
		match kind:
			"rain":
				# (0.74.1) Rain on a road at speed: a bright hiss, a low wash, and drops ticking.
				a += 0.55 * (x - a)
				b += 0.03 * (x - b)
				if r.randf() < 0.0012:
					c = r.randf_range(0.4, 1.0)
				c *= 0.993
				v = (x - a) * 0.22 + (a - b) * 0.5 + b * 0.9 + c * x * 0.35
			"sea":
				a += 0.05 * (x - a)
				v = a * (0.35 + 0.65 * pow(0.5 + 0.5 * sin(TAU * t / 6.0 * 2.0 - 1.2), 2.0)) * 1.6
			"wind":
				a += (0.02 + 0.03 * (0.5 + 0.5 * sin(TAU * t / 6.0))) * (x - a)
				b += 0.004 * (x - b)
				v = (a - b) * 2.2
			"city":
				a += 0.012 * (x - a)
				b += 0.25 * (x - b)
				ph += TAU * 55.0 / RATE
				v = a * 3.0 + (b - a) * 0.05 + sin(ph) * 0.03 * (0.6 + 0.4 * sin(TAU * t / 3.0))
			"hum":
				a += 0.3 * (x - a)
				ph += TAU * 82.0 / RATE
				v = sin(ph) * 0.07 + sin(ph * 1.5) * 0.04 + a * 0.02 + sin(ph * 12.0) * 0.012 * (0.5 + 0.5 * sin(TAU * t / 2.0))
			"engine":
				# A runner at speed: a growling saw with wind over it.
				a += 0.12 * (x - a)
				ph += TAU * 74.0 / RATE
				var saw := fmod(ph / TAU, 1.0) * 2.0 - 1.0
				v = saw * 0.05 + sin(ph * 0.5) * 0.06 + sin(ph * 2.0) * 0.025 * (0.6 + 0.4 * sin(TAU * t * 2.0)) + a * 0.5
			"crowd":
				a += 0.35 * (x - a)
				b += 0.05 * (x - b)
				v = (a - b) * 0.55 * (0.7 + 0.3 * sin(TAU * t / 6.0 * 3.0))
			"shop":
				a += 0.008 * (x - a)
				ph += TAU * 110.0 / RATE
				v = a * 1.6 + sin(ph) * 0.012
		buf[i] = v * 0.5
	# Blend the tail into the head so the loop point cannot be heard.
	var fade := int(0.6 * RATE)
	for i in fade:
		var k := float(i) / fade
		buf[i] = buf[i] * k + buf[n - fade + i] * (1.0 - k)
	buf.resize(n - fade)
	var w := _to_wav(buf)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = buf.size()
	return w


## Background sound for where you are: "city", "sea", "wind", "hum", "crowd", "shop" or "" for none.
## Bend the pitch of whatever ambience is playing (an engine that follows the throttle).
## (0.74.1) A second background loop that plays over the ambience: the weather ("rain", or "").
var _wx: AudioStreamPlayer
var _wx_want := ""
var _wx_db := -18.0


## (0.87.0) A real loop for this kind of air: res://audio/ambience/<kind>.ogg, or yours in
## <card folder>/ambience. Null when there is none: the loop made by code plays as before.
var _own_loops := {}
const REAL_LOOP_DB := 5.0      # recorded air is levelled like the built loops, then lifted: under the music it was lost (measured in a recording of the game)

func _own_loop(kind: String) -> AudioStream:
	if kind == "":
		return null
	if not _own_loops.has(kind):
		var s := own_file("ambience", kind)
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		elif s is AudioStreamMP3:
			(s as AudioStreamMP3).loop = true
		elif s is AudioStreamWAV:
			(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			(s as AudioStreamWAV).loop_end = int((s as AudioStreamWAV).get_length() * (s as AudioStreamWAV).mix_rate)
		_own_loops[kind] = s
	return _own_loops[kind]


func _air_bus() -> String:
	return "Ambience" if AudioServer.get_bus_index("Ambience") >= 0 else "SFX"


func weather(kind: String, volume_db := -18.0) -> void:
	_wx_want = kind
	_wx_db = volume_db
	if _wx == null:
		_wx = AudioStreamPlayer.new()
		_wx.bus = _air_bus()
		add_child(_wx)
	var real := _own_loop(kind)
	if kind == "" or (real == null and not _sounds.has("amb_" + kind)):
		if _wx.playing:
			var tw := create_tween()
			tw.tween_property(_wx, "volume_db", -60.0, 0.8)
			tw.tween_callback(_wx.stop)
		return
	_wx.stream = real if real != null else _sounds["amb_" + kind]
	if real != null:
		volume_db += REAL_LOOP_DB
	_wx.volume_db = -50.0
	_wx.play()
	create_tween().tween_property(_wx, "volume_db", volume_db, 1.2)


## A built loop by name ("engine", "rain"...), or null while it is still being made.
func loop(kind: String) -> AudioStream:
	return _sounds.get("amb_" + kind, null)


func ambience_pitch(pitch: float) -> void:
	if not _amb.is_empty():
		(_amb[_amb_on] as AudioStreamPlayer).pitch_scale = clampf(pitch, 0.4, 2.5)


func ambience(kind: String, volume_db := -16.0) -> void:
	_amb_want = kind
	if _amb.is_empty():
		return
	var real := _own_loop(kind)
	if kind != "" and real == null and not _sounds.has("amb_" + kind):
		return   # still being built: _add_sounds starts it
	if kind == _amb_name:
		return
	_amb_name = kind
	var old := _amb[_amb_on]
	_amb_on = 1 - _amb_on
	var nxt := _amb[_amb_on]
	var tw := create_tween().set_parallel()
	tw.tween_property(old, "volume_db", -60.0, 1.0)
	tw.chain().tween_callback(old.stop)
	if kind != "":
		nxt.stream = real if real != null else _sounds["amb_" + kind]
		# The air of a place follows the Ambience slider; an engine or the rushing wind is an effect.
		nxt.bus = "SFX" if kind in ["engine", "tunnel", "wind"] else _air_bus()
		nxt.pitch_scale = 1.0
		nxt.volume_db = -50.0
		nxt.play()
		create_tween().tween_property(nxt, "volume_db", volume_db + (REAL_LOOP_DB if real != null else 0.0), 1.4)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## Notes played as an arpeggio (spread seconds apart), with a pitch bend.
func _tone(freqs: Array, dur: float, attack: float, gain: float, bend: float, spread: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for fi in freqs.size():
		var start := int(fi * spread * RATE)
		var phase := 0.0
		for i in range(start, n):
			var t := float(i - start) / RATE
			var local := float(i - start) / float(n - start)
			var env := minf(1.0, t / maxf(attack, 0.0001)) * pow(1.0 - local, 2.0)
			var f: float = freqs[fi] * (1.0 + bend * local)
			phase += TAU * f / RATE
			buf[i] += (sin(phase) + 0.25 * sin(phase * 2.0)) * env * gain / sqrt(freqs.size())
	return _to_wav(buf)


func _noise(dur: float, gain: float, f_from: float, f_to: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in n:
		var local := float(i) / n
		var cutoff := lerpf(f_from, f_to, local)
		var a := clampf(TAU * cutoff / RATE, 0.0, 1.0)
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		var env := minf(1.0, local * 40.0) * pow(1.0 - local, 1.5)
		buf[i] = lp * env * gain * 2.0
	return _to_wav(buf)


func _mix(a: AudioStreamWAV, b: AudioStreamWAV) -> AudioStreamWAV:
	var da := _samples(a)
	var db := _samples(b)
	var n := maxi(da.size(), db.size())
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		buf[i] = (da[i] if i < da.size() else 0.0) + (db[i] if i < db.size() else 0.0)
	return _to_wav(buf)


func _samples(w: AudioStreamWAV) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var bytes := w.data
	out.resize(bytes.size() / 2)
	for i in out.size():
		out[i] = bytes.decode_s16(i * 2) / 32767.0
	return out


func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		# Peaks are rounded off instead of chopped flat: no crackle on the big hits.
		var v := buf[i]
		var mag := absf(v)
		if mag > 0.8:
			v = signf(v) * (0.8 + 0.2 * tanh((mag - 0.8) / 0.2))
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
