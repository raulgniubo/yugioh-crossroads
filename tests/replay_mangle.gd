extends Node
## Dev: makes "a replay from another version" out of a real one, to prove such a replay still plays:
## a duelist, a field and a song this game does not have, six cards it does not have, and things in
## the recording it cannot read. Also writes a file in a later format and a file of rubbish.
##   godot --headless --path . res://tests/replay_mangle.tscn -- <a replay.cxr> <folder to write into>
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var data := Replays.read(args[0])
	var out_dir := str(args[1])
	if data.is_empty():
		print("MANGLE: could not read ", args[0])
		get_tree().quit(1)
		return
	data.erase("path")
	data["game"] = "0.80.0"
	data["names"] = [data["names"][0], "Zara Novak"]
	data["setup"]["names"] = [data["setup"]["names"][0], "Zara Novak"]
	var cfg: Dictionary = data["cfg"]
	cfg["opponent"] = "zara_future"
	cfg["opponent_coat"] = "not a colour"
	cfg["field"] = "moonbase"
	cfg["music"] = "duel_future"
	cfg["opponent_deck"] = "deck_future"
	cfg["something_new"] = {"a": 1}
	# Six of the rival's cards become cards this game has never heard of.
	var swap := {}
	var seen := {}
	for id in data["setup"]["decks"][1]:
		if not seen.has(int(id)) and swap.size() < 6 and data["cards"].has(int(id)):
			swap[int(id)] = 990000001 + swap.size()
		seen[int(id)] = true
	var book: Dictionary = data["cards"]
	var n := 0
	for old in swap:
		var c: Dictionary = book[old]
		book.erase(old)
		n += 1
		c["name"] = "Nebula Card %d" % n
		c.erase("es")
		book[swap[old]] = c
	data["setup"] = _re(data["setup"], swap)
	data["tape"] = _re(data["tape"], swap)
	# Things in the recording this game cannot read.
	var tape: Array = data["tape"]
	(tape[3]["m"] as Array).append({"t": 999, "p": 0, "what": "a message from the future"})
	(tape[4]["m"] as Array).append("not a message at all")
	(tape[5]["m"] as Array).append({"no_t": true})
	tape[6]["extra"] = [1, 2, 3]
	Replays._write(out_dir.path_join("2026-11-20 20-00-00 vs Zara Novak (other version).cxr"), data)
	# A later format: only its first lines can be read here.
	var f := FileAccess.open_compressed(out_dir.path_join("2026-11-20 21-00-00 vs Someone (later format).cxr"), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	f.store_var({"format": Replays.FORMAT + 1, "game": "0.90.0", "when": int(data["when"]) + 5000, "date": "2027-03-01 10:00", "keep": false,
		"names": ["Someone", "Someone Else"], "result": {"winner": 0, "turns": 9, "lp": [3000, 0]}, "cfg": {"opponent": "nobody_yet"}, "steps": 300})
	f.store_var({"a_new_way_to_write_it": true})
	f.close()
	# Rubbish with the right ending.
	var g := FileAccess.open(out_dir.path_join("rubbish.cxr"), FileAccess.WRITE)
	g.store_string("this is not a replay")
	g.close()
	print("MANGLE: wrote 3 files, swapped ", swap)
	get_tree().quit(0)


func _re(v, swap: Dictionary):
	if v is int:
		return swap.get(v, v)
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(_re(x, swap))
		return a
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _re(v[k], swap)
		return d
	return v
