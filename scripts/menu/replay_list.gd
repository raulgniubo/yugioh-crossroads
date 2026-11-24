class_name ReplayList
extends Control
## The Replays screen (0.64.0). Every duel you play is kept here by itself (the last 30; a starred
## one stays until you unstar it). Each row is one duel: who, how it ended, how long, when. Watch it,
## make it a favorite, delete it. Each replay is one small file in the Replays folder: send it to a friend and
## it shows up in their list once they put it in theirs.

signal closed

var _list: VBoxContainer
var _count: Label
var _ask: Control


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(MenuBackdrop.new())
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 80)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 34)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	m.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	root.add_child(head)
	var back := Button.new()
	back.text = "◀  Back"
	back.add_theme_font_size_override("font_size", 18)
	back.custom_minimum_size = Vector2(104, 44)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	head.add_child(back)
	head.add_child(UITheme.label("REPLAYS", 44, Color.WHITE, UITheme.title_font()))
	_count = UITheme.label("", 17, UITheme.TEXT_DIM)
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_count)
	var folder := Button.new()
	folder.text = "Open the Replays folder"
	folder.custom_minimum_size = Vector2(0, 44)
	folder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	folder.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path(Replays.dir())))
	head.add_child(folder)
	var note := UITheme.label("Every duel is kept here by itself, the last 30. Mark one as a favorite (the star) to keep it for good. To share a duel, send its file from the Replays folder; a friend puts it in their own Replays folder and it appears in this list.", 15, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.86), 18, Color(UITheme.ACCENT, 0.2)))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 14)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(pad)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_list)
	_fill()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	back.grab_focus()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _ask != null and is_instance_valid(_ask):
			_ask.queue_free()
		else:
			_close()


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	closed.emit()
	queue_free()


var _dev_once := false

var _fill_gen := 0


func _fill() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var rows := Replays.list()
	var kept := 0
	for h in rows:
		if bool(h["keep"]):
			kept += 1
	_count.text = Loc.t("%d replays  ·  %d favorites") % [rows.size(), kept] if not rows.is_empty() else ""
	if rows.is_empty():
		var empty := UITheme.label("No replays yet. Play a duel and it will be here when you come back.", 20, UITheme.TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 220)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_list.add_child(empty)
		return
	# (0.72.3) The first rows now, the rest a frame at a time: a row with a face that is not in memory
	# yet reads a model, and thirty of those in one go was seconds of standing still.
	_fill_gen += 1
	var gen := _fill_gen
	var t0 := Time.get_ticks_msec()
	for k in rows.size():
		if k >= 6 and Time.get_ticks_msec() - t0 > 5:
			await get_tree().process_frame
			if not is_inside_tree() or gen != _fill_gen:
				return
			t0 = Time.get_ticks_msec()
		_list.add_child(_row(rows[k]))
	if "--replay-rename" in OS.get_cmdline_user_args() and not _dev_once:
		_dev_once = true      # dev: the naming box, for a picture
		_ask_name(str(rows[0]["path"]), "%s vs %s" % [str(rows[0]["names"][0]), str(rows[0]["names"][1])])


func _row(h: Dictionary) -> Control:
	var res: Dictionary = h["result"]
	var winner := int(res.get("winner", 2))
	var won := winner == 0
	var draw := winner > 1
	var col: Color = UITheme.TEXT_DIM if draw else (Color("5fe39a") if won else Color("ff6a7c"))
	var box := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.055, 0.085, 0.17, 0.95), 14, Color(col, 0.45))
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.border_width_left = 6
	box.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	# Who it was against.
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(78, 92)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if str(h["opponent"]) != "":
		# (a duelist this version of the game does not have: the stand-in's picture, the replay's name)
		var who_key := str(h["opponent"])
		if str(h.get("looks", "")) != "" and Avatars.has_avatar(str(h["looks"])):
			who_key = str(h["looks"])
		elif Characters.get_char(who_key).is_empty() and not Avatars.has_avatar(who_key):
			who_key = Replays.STAND_IN
		face.texture = Portraits.get_portrait(who_key)
	var clip := PanelContainer.new()
	UITheme.clip_safe(clip)
	clip.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.02, 0.03, 0.07), 10, Color(1, 1, 1, 0.12)))
	clip.add_child(face)
	row.add_child(clip)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 3)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(mid)
	var names: Array = h["names"]
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 10)
	mid.add_child(title)
	if bool(h["keep"]):
		title.add_child(_chip(Loc.t("Favorite"), UITheme.GOLD))
	var given := str(h.get("title", ""))
	var big := UITheme.label(given if given != "" else "%s  vs  %s" % [str(names[0]), str(names[1])], 25, Color.WHITE, UITheme.title_font())
	big.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	big.clip_text = true
	big.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	big.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(big)
	if bool(h["turbo"]):
		title.add_child(_chip(Loc.t("Turbo Duel"), Color("ffb347")))
	var how := Loc.t("Tied duel") if draw else (Loc.t("Victory") if won else Loc.t("Defeat"))
	if bool(res.get("surrendered", false)):
		how = Loc.t("Surrendered")
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	mid.add_child(line)
	line.add_child(_chip(how, col))
	var lp: Array = res.get("lp", [0, 0])
	# (a replay with a name of its own still says who played)
	var who := ("%s vs %s   ·   " % [str(names[0]), str(names[1])]) if given != "" else ""
	line.add_child(UITheme.label(who + Loc.t("%d turns") % int(res.get("turns", 0)) + "   ·   " + Loc.t("LP %d - %d") % [int(lp[0]), int(lp[1])], 16, UITheme.TEXT))
	var when := UITheme.label(str(h["date"]), 15, UITheme.TEXT_DIM)
	mid.add_child(when)
	# What you can do with it.
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 12)
	acts.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(acts)
	var path := str(h["path"])
	var names_label := "%s vs %s, %s" % [str(names[0]), str(names[1]), str(h["date"])]
	if bool(h.get("newer", false)):
		# Written by a later version in a way this one cannot play: it stays in the list, and says so.
		box.modulate = Color(1, 1, 1, 0.62)
		var why := UITheme.label(Loc.t("Made with a newer version of the game (%s). Update the game to watch it.") % str(h.get("game", "?")), 15, UITheme.TEXT_DIM)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(300, 0)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		why.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		acts.add_child(why)
		var del2 := RoundButton.new("trash", Comic.RED, 54.0)
		del2.tooltip_text = Loc.t("Delete this replay")
		del2.focus_mode = Control.FOCUS_ALL
		del2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		del2.pressed.connect(func(): _confirm_delete(path, names_label))
		acts.add_child(del2)
		return box
	var watch := Button.new()
	watch.text = "Watch"
	watch.custom_minimum_size = Vector2(150, 54)
	UITheme.paint_button(watch, UITheme.ACCENT)
	watch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	watch.pressed.connect(func(): _watch(path))
	acts.add_child(watch)
	# Its name: the pencil. The name is the file's name in the Replays folder.
	var pen := RoundButton.new("pencil", Comic.BLUE, 54.0)
	pen.tooltip_text = Loc.t("Name this replay")
	pen.focus_mode = Control.FOCUS_ALL
	pen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pen.pressed.connect(func(): _ask_name(path, given if given != "" else "%s vs %s" % [str(names[0]), str(names[1])]))
	acts.add_child(pen)
	# Favorite: a star, hollow or gold. A favorite is never cleared out by newer duels.
	var keep_now := bool(h["keep"])
	var star := RoundButton.new("star_on" if keep_now else "star", Comic.BLUE, 54.0)
	star.tooltip_text = Loc.t("Remove from favorites") if keep_now else Loc.t("Favorite: keep this replay for good")
	star.focus_mode = Control.FOCUS_ALL
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	star.pressed.connect(func():
		Replays.set_keep(path, not keep_now)
		_fill())
	acts.add_child(star)
	# Delete: a bin, the same size as the star and right beside it. It asks before it does anything.
	var del := RoundButton.new("trash", Comic.RED, 54.0)
	del.tooltip_text = Loc.t("Delete this replay")
	del.focus_mode = Control.FOCUS_ALL
	del.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	del.pressed.connect(func(): _confirm_delete(path, names_label))
	acts.add_child(del)
	return box


func _chip(text: String, col: Color) -> Control:
	var l := UITheme.label(text, 15, col, UITheme.semi_font())
	var sb := UITheme.panel_box(Color(col, 0.14), 9, Color(col, 0.6))
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	l.add_theme_stylebox_override("normal", sb)
	return l


func _watch(path: String) -> void:
	var data := Replays.read(path)
	if data.is_empty():
		Router.toast(Loc.t("That replay could not be opened."))
		return
	Router.duel_config = Replays.config_for(data)
	Router.menu_open = "replays"
	Router.go(Router.DUEL)


## Deleting is for good, so it asks first.
func _confirm_delete(path: String, label: String) -> void:
	if _ask != null and is_instance_valid(_ask):
		_ask.queue_free()
	_ask = Control.new()
	_ask.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_ask)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask.add_child(shade)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.05, 0.08, 0.16, 0.98), 18, Color(1, 1, 1, 0.2)))
	cc.add_child(p)
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 26)
	p.add_child(pm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	pm.add_child(v)
	v.add_child(UITheme.label("Delete this replay?", 28, Color.WHITE, UITheme.title_font()))
	v.add_child(UITheme.label(label, 17, UITheme.TEXT_DIM))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(bar)
	var no := Button.new()
	no.text = "Keep it"
	no.custom_minimum_size = Vector2(170, 52)
	no.pressed.connect(func(): _ask.queue_free())
	bar.add_child(no)
	var yes := Button.new()
	yes.text = "Delete"
	yes.custom_minimum_size = Vector2(170, 52)
	yes.add_theme_color_override("font_color", Color("ff8a98"))
	yes.pressed.connect(func():
		Replays.remove(path)
		_ask.queue_free()
		_fill())
	bar.add_child(yes)
	no.grab_focus()


## A name for a replay: typed here, and it becomes the name of the file itself.
func _ask_name(path: String, now: String) -> void:
	if _ask != null and is_instance_valid(_ask):
		_ask.queue_free()
	_ask = Control.new()
	_ask.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_ask)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask.add_child(shade)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.05, 0.08, 0.16, 0.98), 18, Color(1, 1, 1, 0.2)))
	cc.add_child(p)
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 26)
	p.add_child(pm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pm.add_child(v)
	v.add_child(UITheme.label("Name this replay", 28, Color.WHITE, UITheme.title_font()))
	var edit := LineEdit.new()
	edit.text = now
	edit.max_length = 70
	edit.custom_minimum_size = Vector2(560, 52)
	edit.add_theme_font_size_override("font_size", 22)
	v.add_child(edit)
	var note := UITheme.label("This is also the name of its file in the Replays folder, so it is easy to find and to share. A replay with a name is never cleared out by newer duels.", 15, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(560, 0)
	v.add_child(note)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(bar)
	var no := Button.new()
	no.text = "Cancel"
	no.custom_minimum_size = Vector2(170, 52)
	no.pressed.connect(func(): _ask.queue_free())
	bar.add_child(no)
	var yes := Button.new()
	yes.text = "Save name"
	yes.custom_minimum_size = Vector2(200, 52)
	UITheme.paint_button(yes, UITheme.ACCENT)
	bar.add_child(yes)
	var done := func():
		if edit.text.strip_edges() == "":
			return
		if Replays.rename(path, edit.text) == "":
			Router.toast(Loc.t("That name could not be used."))
			return
		_ask.queue_free()
		_fill()
	yes.pressed.connect(done)
	edit.text_submitted.connect(func(_t): done.call())
	edit.grab_focus()
	edit.select_all()
