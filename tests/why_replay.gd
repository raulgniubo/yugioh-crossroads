extends Node
## Dev: plays a saved replay (.cxr) through the duel mirror and prints what DuelWhy says: the reasons,
## what is in force, and the log lines.
##   godot --headless --path . res://tests/why_replay.tscn -- <file.cxr>
func _ready():
	await get_tree().process_frame
	var f := FileAccess.open_compressed(OS.get_cmdline_user_args()[0], FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	var head = f.get_var()
	var body = f.get_var()
	var rs: Dictionary = body["setup"]
	for k in body["cards"]:
		CardData.GUEST[int(k)] = body["cards"][k]
	var st := DuelState.new()
	var d := OcgDuel.new()
	d.prepare(st, rs["decks"], rs["extras"], rs["names"], int(rs["first"]), int(rs["seed"]), rs["lay"])
	d.playback = true
	d.check = false
	var tape: Array = body["tape"]
	var turn := 0
	for i in tape.size():
		var evs: Array = d.feed(tape[i])
		for e in evs:
			var t := str(e["type"])
			if t == "turn":
				turn += 1
				print("---- turn ", turn, " p", e["player"])
			elif t in ["why", "status", "log"]:
				if t == "status":
					var l := []
					for s in e["list"]:
						l.append("%s [%s · %s]" % [s["short"], s["when"], s["name"]])
					print("  STATUS p", e["player"], " ", l)
				elif t == "why":
					print("  WHY p", e["player"], " ", e["title"], " | ", e["text"])
				else:
					print("  LOG p", e["player"], " ", e["icon"], " ", e["text"])
	get_tree().quit()
