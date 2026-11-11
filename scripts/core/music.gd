extends Node
## Generated background music (no audio files yet). Tracks are rendered once in a
## background thread, then loop. Music.play("menu") / Music.play("duel")

const RATE := 22050

const TRACKS := {
	"menu": {"bpm": 92.0, "bars": 8, "drums": false, "gain": 0.55,
		"chords": [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62],
			[57, 60, 64], [53, 57, 60], [50, 53, 57], [52, 56, 59]]},
	"duel": {"bpm": 128.0, "bars": 8, "drums": true, "gain": 0.5,
		"chords": [[50, 53, 57], [50, 53, 57], [46, 50, 53], [48, 52, 55],
			[50, 53, 57], [55, 58, 62], [46, 50, 53], [52, 55, 59]]},
}

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _wanted := ""
var _current := ""
var _thread: Thread


func _ready() -> void:
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	if DisplayServer.get_name() == "headless":
		return
	_thread = Thread.new()
	_thread.start(_render_all)


func play(track: String) -> void:
	_wanted = track
	if _streams.has(track):
		_switch(track)


func _render_all() -> void:
	for name in ["menu", "duel"]:
		var stream := _render(TRACKS[name])
		call_deferred("_on_rendered", name, stream)


func _on_rendered(name: String, stream: AudioStreamWAV) -> void:
	_streams[name] = stream
	if _wanted == name and _current != name:
		_switch(name)


func _switch(track: String) -> void:
	if _current == track:
		return
	_current = track
	var old := _players[_active]
	_active = 1 - _active
	var nxt := _players[_active]
	nxt.stream = _streams[track]
	nxt.volume_db = -40.0
	nxt.play()
	var tw := create_tween().set_parallel()
	tw.tween_property(nxt, "volume_db", -6.0, 1.5)
	tw.tween_property(old, "volume_db", -80.0, 1.2)
	tw.chain().tween_callback(old.stop)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


static func _hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


func _render(t: Dictionary) -> AudioStreamWAV:
	var bpm: float = t["bpm"]
	var beat := 60.0 / bpm
	var bars: int = t["bars"]
	var chords: Array = t["chords"]
	var n := int(bars * 4 * beat * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var bar_len := int(4 * beat * RATE)
	var sixteenth := int(beat * RATE / 4.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var lp := 0.0
	var phases := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var bass_phase := 0.0
	var arp_phase := 0.0
	for i in n:
		var bar := (i / bar_len) % bars
		var chord: Array = chords[bar]
		var in_bar := i % bar_len
		var bar_pos := float(in_bar) / bar_len
		# Pad: two detuned saws per chord note, gently filtered
		var pad := 0.0
		for k in 3:
			var f := _hz(chord[k])
			for d in 2:
				var idx := k * 2 + d
				phases[idx] = fmod(phases[idx] + f * (1.0 + (d * 2 - 1) * 0.004) / RATE, 1.0)
				pad += phases[idx] * 2.0 - 1.0
		pad /= 6.0
		lp += 0.06 * (pad - lp)
		var swell := 0.6 + 0.4 * sin(bar_pos * PI)
		var s := lp * 0.35 * swell
		# Bass: root on 8th notes
		var eighth := int(beat * RATE / 2.0)
		var in_eighth := float(i % eighth) / eighth
		var bf := _hz(chord[0] - 12)
		bass_phase = fmod(bass_phase + bf / RATE, 1.0)
		var bass_env := pow(1.0 - in_eighth, 1.5)
		s += (sin(bass_phase * TAU) + 0.3 * sign(sin(bass_phase * TAU))) * 0.22 * bass_env
		# Arp: chord notes up an octave, 16ths, plucky triangle
		var step := (in_bar / sixteenth) % 8
		var arp_note: int = chord[[0, 1, 2, 1, 0, 2, 1, 2][step]] + 12
		var in_step := float(in_bar % sixteenth) / sixteenth
		arp_phase = fmod(arp_phase + _hz(arp_note) / RATE, 1.0)
		var tri := 1.0 - 4.0 * absf(arp_phase - 0.5)
		s += tri * 0.12 * exp(-in_step * 4.0)
		if t["drums"]:
			var in_beat := float(i % int(beat * RATE)) / (beat * RATE)
			# Kick on every beat
			var kf := 50.0 + 120.0 * exp(-in_beat * 30.0)
			s += sin(TAU * kf * in_beat * beat) * exp(-in_beat * 9.0) * 0.45
			# Hats on the off-beat 8ths
			if in_eighth < 0.25 and (i / eighth) % 2 == 1:
				s += rng.randf_range(-1.0, 1.0) * 0.06 * (1.0 - in_eighth * 4.0)
			# Snare on 2 and 4
			var beat_idx := (in_bar / int(beat * RATE)) % 4
			if beat_idx == 1 or beat_idx == 3:
				s += rng.randf_range(-1.0, 1.0) * 0.16 * exp(-in_beat * 14.0)
		buf[i] = s * float(t["gain"])
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w
