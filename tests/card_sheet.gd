extends Control
## Dev: card faces side by side, as the game draws them, saved as a picture.
##   xvfb-run godot --rendering-driver opengl3 res://tests/card_sheet.tscn -- --ids=1,2,3 --out=/tmp/x.png [--cols=5] [--wait=4] [--scale=1.0]
func _ready() -> void:
	var ids: Array = []
	var out := "/tmp/card_sheet.png"
	var cols := 5
	var wait := 4.0
	var sc := 1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="):
			for x in a.trim_prefix("--ids=").split(","):
				ids.append(int(x))
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--cols="): cols = int(a.trim_prefix("--cols="))
		if a.begins_with("--wait="): wait = float(a.trim_prefix("--wait="))
		if a.begins_with("--scale="): sc = float(a.trim_prefix("--scale="))
	var w := 420.0 * sc
	var h := 612.0 * sc
	var rows := int(ceil(ids.size() / float(cols)))
	get_window().size = Vector2i(1920, 1080)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.13, 0.16)
	bg.size = Vector2(1920, 1080)
	add_child(bg)
	for i in ids.size():
		var tr := TextureRect.new()
		tr.texture = Cards.get_face(int(ids[i]))
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.position = Vector2(8 + (i % cols) * (w + 8), 8 + (i / cols) * (h + 8))
		tr.size = Vector2(w, h)
		add_child(tr)
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
