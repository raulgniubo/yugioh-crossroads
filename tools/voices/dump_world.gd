extends Node
## Every line somebody says out in a world, with the voice that says it, as JSON:
##   godot --headless --path . res://tools/voices/dump_world.tscn -- /tmp/world_lines.json [district,district]
## (A scene, not a -s script: the world's scripts need the game's autoloads.) The list itself is
## WorldLines.collect, which the tests use too. Default district: academy.
## Each entry: {"voice", "en", "from"}. tools/voices pairs it with its Spanish and makes the files.


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var path := str(args[0]) if args.size() > 0 else "/tmp/world_lines.json"
	var districts: Array = Array((str(args[1]) if args.size() > 1 else "academy").split(","))
	var out := WorldLines.collect(districts)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	var chars := 0
	for e in out:
		chars += str(e["en"]).length()
	print("WORLD LINES: ", out.size(), " files, ", chars, " characters of English -> ", path)
	get_tree().quit()
