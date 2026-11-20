extends Node
## Dev: card name -> id for the names in a JSON list (argument 1) to a JSON file (argument 2), plus
## the names of a few ids. `godot --headless res://tools/voices/dump_names.tscn -- names.json out.json`
func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var names: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var out := {}
	for n in names:
		if n is String:
			out[n] = int(CardData.NAME_TO_ID.get(str(n).to_lower(), 0))
		else:
			out[str(int(n))] = str(CardData.get_card(int(n)).get("name", ""))
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("NAMES DUMPED ", out.size())
	get_tree().quit()
