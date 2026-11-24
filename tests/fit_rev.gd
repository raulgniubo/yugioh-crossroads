extends Node
## The mark of how motions are fitted to a model (data/fit_rev.json).
##
## A motion fitted to a model (a borrowed walk, a wave, a stance) is kept on disk so it is worked out
## once. Until 0.72.4 everything kept was thrown away with each new version of the game, so the
## first visit to every place after every update worked it all out again. Now it is kept for as long
## as the way it is worked out stays the same, and this mark is what says so: a hash of the part of
## avatars.gd that does the fitting, of the motion files it fits from and of every bundled body.
##
## The unit tests fail when the mark in data/fit_rev.json is not the one of the code as it is.
## To set it:   godot --headless --path . res://tests/fit_rev.tscn -- --write

const FROM := "const DONOR :="
const TO := "func anim_player("
const FILES := ["res://assets/models/people/duelist_m2.glb", "res://assets/models/anim/gestures.glb"]
const CLIPS := "res://assets/models/anim/clips/"
const PEOPLE := "res://assets/models/people/"


static func current() -> String:
	var src := FileAccess.get_file_as_string("res://scripts/core/avatars.gd")
	var a := src.find(FROM)
	var b := src.find(TO)
	if a < 0 or b < a:
		return ""
	var parts: Array = [src.substr(a, b - a).md5_text()]
	var files: Array = FILES.duplicate()
	var d := DirAccess.open(CLIPS)
	if d != null:
		var names: Array = []
		for f in d.get_files():
			if f.ends_with(".res"):
				names.append(f)
		names.sort()
		for f in names:
			files.append(CLIPS + f)
	# Every bundled body too (and how it is imported): a fit is made for one skeleton and one shape.
	var pd := DirAccess.open(PEOPLE)
	if pd != null:
		var pn: Array = []
		for f in pd.get_files():
			if f.ends_with(".glb") or f.ends_with(".glb.import"):
				pn.append(f)
		pn.sort()
		for f in pn:
			if not files.has(PEOPLE + f):
				files.append(PEOPLE + f)
	for f in files:
		parts.append(f.get_file() + ":" + FileAccess.get_md5(f))
	return "|".join(parts).md5_text()


static func stored() -> String:
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/fit_rev.json"))
	return str((j as Dictionary).get("rev", "")) if j is Dictionary else ""


func _ready() -> void:
	var now := current()
	var was := stored()
	if "--write" in OS.get_cmdline_user_args():
		var w := FileAccess.open("res://data/fit_rev.json", FileAccess.WRITE)
		w.store_string(JSON.stringify({"rev": now}) + "\n")
		w.close()
		print("FIT REV written: %s (it was %s)" % [now, "the same" if now == was else "different"])
	else:
		print("FIT REV %s, stored %s: %s" % [now, stored(), "the same" if now == stored() else "DIFFERENT (run with -- --write)"])
	get_tree().quit()
