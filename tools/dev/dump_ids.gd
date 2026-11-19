extends Node
## Dev: every card id in the game to /tmp/game_ids.txt (godot --headless res://tools/dev/dump_ids.tscn).
func _ready() -> void:
	await get_tree().process_frame
	var f := FileAccess.open("/tmp/game_ids.txt", FileAccess.WRITE)
	for id in Collection.all_cards():
		f.store_line(str(id))
	f.close()
	print("dumped ", Collection.all_cards().size(), " folder ", Settings.card_folder, " ext ", CardData.EXT.size())
	get_tree().quit()
