extends Control
## Dev tool: one menu on its own, saved as a picture.
## godot res://tools/ui_shot.tscn -- --what=packs|deckshop|decks --tab=1 --out=/tmp/x.png [--dp=5000] [--lang=es]
var n := 0
var out := "/tmp/ui_test.png"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var what := "packs"
	var tab := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--what="): what = a.trim_prefix("--what=")
		if a.begins_with("--tab="): tab = int(a.trim_prefix("--tab="))
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--dp="): Collection.dp = int(a.trim_prefix("--dp="))
		if a.begins_with("--lang="): Loc.setup(a.trim_prefix("--lang="))
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.25, 0.3)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var ps: Control
	match what:
		"packs": ps = PackShop.new()
		"deckshop": ps = DeckShop.new()
		"purse": ps = DpPurse.new()
		"rps":
			var og := OpeningGame.new()
			og.me_key = "player"
			og.opp_key = "kaiba"
			og.me_name = "Duelist"
			og.opp_name = "Kaiba"
			ps = og
		_: ps = DeckMenu.new()
	add_child(ps)
	if tab > 0 and ps.has_method("_show_tab"):
		ps.call_deferred("_show_tab", tab)
	if what == "rps":
		await get_tree().create_timer(0.4).timeout
		if tab == 1:
			ps._rps()
		elif tab == 2:
			ps._clear_buttons()
			ps._hands_show = true
			ps._hand = [0, 2]
			ps._hand_pop = [1.0, 1.0]

func _process(_d: float) -> void:
	n += 1
	if n == 70:
		get_viewport().get_texture().get_image().save_png(out)
		get_tree().quit()
