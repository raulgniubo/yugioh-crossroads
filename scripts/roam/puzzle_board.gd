class_name PuzzleBoard
extends CanvasLayer
## The Duel Puzzle cabinet: pick a position and win it in one turn (see Puzzles).
## Free to play, and the first time you solve each one it pays Duel Points.

var scene


static func open(roam) -> void:
	var b := PuzzleBoard.new()
	b.scene = roam
	roam.add_child(b)


func _ready() -> void:
	layer = 6
	scene._overlay_open = true
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var v := VBoxContainer.new()
	v.theme = UITheme.build()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -620
	v.offset_right = 620
	v.offset_top = -470
	v.offset_bottom = 470
	v.add_theme_constant_override("separation", 10)
	shade.add_child(v)
	var title := UITheme.label(Loc.t("DUEL PUZZLES"), 54, Color("ffd166"), UITheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var done := 0
	for pz in Puzzles.LIST:
		if Puzzles.solved(str(pz["id"])):
			done += 1
	var sub := UITheme.label(Loc.t("The field is set and it is your turn. Win before the turn ends.   Solved: %d of %d") % [done, Puzzles.LIST.size()], 22, Color.WHITE, UITheme.semi_font())
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var first: Button = null
	for pz in Puzzles.LIST:
		var id := str(pz["id"])
		var b := Button.new()
		var ok := Puzzles.ready(pz)
		var mark := "✔  " if Puzzles.solved(id) else "      "
		b.text = "%s%s   %s" % [mark, "★".repeat(int(pz.get("stars", 1))), Loc.t(str(pz["title"]))]
		if not Puzzles.solved(id):
			b.text += "      +%d DP" % Puzzles.REWARD
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 62)
		b.add_theme_font_size_override("font_size", 26)
		b.disabled = not ok
		b.tooltip_text = Loc.t(str(pz.get("hint", ""))) if ok else Loc.t("Some of this puzzle's cards are not in your card folder.")
		b.pressed.connect(func(): _play(id))
		v.add_child(b)
		if first == null and ok:
			first = b
	var close := Button.new()
	close.text = Loc.t("Step away  (Esc)")
	close.custom_minimum_size = Vector2(0, 56)
	close.pressed.connect(_close)
	v.add_child(close)
	(first if first else close).grab_focus.call_deferred()


func _play(id: String) -> void:
	Router.roam["pos"] = scene._player.position
	Router.roam["yaw"] = scene._yaw
	Router.duel_config = {
		"opponent": "professor", "opponent_name": Loc.t("Puzzle"), "player_deck": Collection.active_deck(), "player_char": "player",
		"difficulty": 0, "puzzle": id, "story": true, "lose_ok": true, "return_to": Router.ROAM,
		"continue_label": Loc.t("Back to the Game Center"),
	}
	scene._overlay_open = false
	Router.go(Router.DUEL)


func _close() -> void:
	scene._overlay_open = false
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
		_close()
		get_viewport().set_input_as_handled()
