extends CanvasLayer
## What the game shows in place of the menu when the base (base.pck: the voices and the 3D models,
## downloaded once) is not beside it, or is older than the one this version was made for.
## See scripts/core/packs.gd.


func _init() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var packs: Node = get_node("/root/Packs")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.build()
	add_child(root)
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(UITheme.PANEL_LIGHT, 22, UITheme.EDGE))
	panel.custom_minimum_size = Vector2(1100, 0)
	center.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 44)
	panel.add_child(pad)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	pad.add_child(col)

	var title := ""
	var text := ""
	var need := int(packs.base_needed)
	match str(packs.problem):
		"old":
			title = Loc.t("This version needs a newer base")
			text = Loc.t("This version was made for Base %d. The one in the folder is Base %d.") % [need, int(packs.base_found)]
			text += "\n\n" + Loc.t("Download Base %d, put its base.pck file in this folder in place of the old one, and open the game again:") % need
		"broken":
			title = Loc.t("The base file cannot be read")
			text = Loc.t("The base.pck file in the folder did not download whole, or is not the game's.")
			text += "\n\n" + Loc.t("Download Base %d again, put its base.pck file in this folder in place of the old one, and open the game again:") % need
		_:
			title = Loc.t("The game's base is missing")
			text = Loc.t("This is the small part of the game. The big part (the voices and the 3D models) comes one time only, in a file called base.pck.")
			text += "\n\n" + Loc.t("Download Base %d, put its base.pck file in this folder, and open the game again:") % need
	col.add_child(UITheme.label(title, 40, UITheme.ACCENT, UITheme.title_font()))
	var body := UITheme.label(text, 24, UITheme.TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(body)
	var where := UITheme.label(str(packs.home()), 22, UITheme.GOLD)
	where.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	col.add_child(where)
	var safe := UITheme.label(Loc.t("Your game, your cards and your decks are safe. Nothing of yours was touched."), 20, UITheme.TEXT_DIM)
	safe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(safe)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(row)
	var open := Button.new()
	open.text = Loc.t("Open the folder")
	open.custom_minimum_size = Vector2(280, 64)
	UITheme.paint_button(open, UITheme.ACCENT_2)
	open.pressed.connect(func(): OS.shell_open(str(packs.home())))
	row.add_child(open)
	var close := Button.new()
	close.text = Loc.t("Close the game")
	close.custom_minimum_size = Vector2(280, 64)
	UITheme.paint_button(close, UITheme.ACCENT, Color.BLACK)
	close.pressed.connect(func(): get_tree().quit())
	row.add_child(close)
	close.grab_focus.call_deferred()
	print("PACKS notice shown: ", packs.problem)
