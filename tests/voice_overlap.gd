extends Node
## Voices never talk over each other: 30 lines are thrown at the speaker in 3 seconds and every frame is
## checked for more than one voice playing. Then the shout (two voices on purpose) with lines thrown at it.
##   godot --headless --path . res://tests/voice_overlap.tscn

func _ready() -> void:
	var files: Array = []
	for d in ["res://voices/es/lumen", "res://voices/es/cocky_m", "res://voices/es/wild_m"]:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".ogg.import") or f.ends_with(".ogg"):
				var p: String = str(d) + "/" + str(f).trim_suffix(".import")
				if not files.has(p):
					files.append(p)
	if files.size() < 6:
		print("VOICE OVERLAP: no voice files to test with")
		get_tree().quit(1)
		return
	# Short lines first, so the ones that wait their turn get it before they are too late to matter.
	files.sort_custom(func(x, y): return (load(x) as AudioStream).get_length() < (load(y) as AudioStream).get_length())
	files = files.slice(0, 12)
	var sp: Voices.Speaker = Voices._sp()
	await get_tree().process_frame
	await get_tree().process_frame
	var most := 0
	var heard := 0
	var starts := 0
	var last_stream = null
	var gap_ok := true
	var last_end := -1.0
	var was := false
	var t := 0.0
	var sent := 0
	var frames := 0
	# 30 lines in 3 seconds, every third one a line that waits its turn.
	while t < 16.0:
		var dt := get_process_delta_time()
		t += dt
		frames += 1
		while sent < 30 and t >= sent * 0.1:
			# (every sixth: a pain sound, which only waits a moment for its turn)
			if sp.take(str(files[sent % files.size()]), 1.0, sent % 3 == 0, 0.6 if sent % 6 == 0 else 4.0):
				heard += 1
			sent += 1
		var n := int(sp._player.playing) + int(sp._second.playing)
		most = maxi(most, n)
		if sp._player.playing and sp._player.stream != last_stream:
			last_stream = sp._player.stream
			starts += 1
			if last_end >= 0.0 and t - last_end < 0.15:
				gap_ok = false
		if was and not sp._player.playing:
			last_end = t
		was = sp._player.playing
		if sent >= 30 and not sp.busy() and sp._queue.is_empty() and t > 4.0:
			break
		await get_tree().process_frame
	print("VOICE OVERLAP rapid: sent %d, taken %d, started %d, most voices at once %d, breath between lines %s, %.1f s, %d frames" % [sent, heard, starts, most, "yes" if gap_ok else "NO", t, frames])
	var ok := most <= 1 and starts >= 2 and gap_ok
	# The shout: two voices on purpose; lines thrown at it must not make a third or cut it.
	sp.both(str(files[0]), 1.0, str(files[1]), 1.0)
	var most2 := 0
	var extra := 0
	var s_a = sp._player.stream
	var cut := false
	t = 0.0
	sent = 0
	while t < 8.0:
		t += get_process_delta_time()
		if sent < 10 and t >= 0.02 + sent * 0.05:
			if sp.take(str(files[2 + sent % 3]), 1.0, false):
				extra += 1
			sent += 1
		most2 = maxi(most2, int(sp._player.playing) + int(sp._second.playing))
		if sp._second.playing and sp._player.playing and sp._player.stream != s_a:
			cut = true
		if sent >= 10 and not sp.busy():
			break
		await get_tree().process_frame
	print("VOICE OVERLAP shout: most voices at once %d (2 is the shout itself), lines let in on top %d, shout cut %s" % [most2, extra, "YES" if cut else "no"])
	ok = ok and most2 <= 2 and extra == 0 and not cut
	print("VOICE OVERLAP: ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
