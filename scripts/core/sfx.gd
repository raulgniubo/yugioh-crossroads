extends Node
## Procedural sound effects (no audio files needed yet). Sfx.play("click")

const RATE := 22050

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 42
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
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
	_sounds["win"] = _tone([523.25, 659.25, 783.99, 1046.5, 1318.5], 1.4, 0.01, 0.35, 0.0, 0.12)
	_sounds["lose"] = _tone([392.0, 349.23, 293.66, 261.63], 1.4, 0.01, 0.35, 0.0, 0.18)


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		n.mouse_entered.connect(func():
			if not n.disabled:
				play("hover", -14.0))
		n.pressed.connect(func(): play("click", -8.0))


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not _sounds.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[name]
	p.volume_db = volume_db
	p.pitch_scale = pitch * _rng.randf_range(0.97, 1.03)
	p.play()


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
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
