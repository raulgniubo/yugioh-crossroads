class_name SavesUI
extends RefCounted
## The controls for saves, story difficulty, starting over and admin mode. They are added to
## the Story panel and to Settings.

static func _ask(host: Node, text: String, yes: String, then: Callable) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = Loc.t("Are you sure?")
	dlg.dialog_text = Loc.t(text)
	dlg.ok_button_text = Loc.t(yes)
	dlg.cancel_button_text = Loc.t("Cancel")
	dlg.dialog_autowrap = true
	dlg.min_size = Vector2i(620, 220)
	host.add_child(dlg)
	dlg.confirmed.connect(then)
	dlg.close_requested.connect(dlg.queue_free)
	dlg.popup_centered()


static func _line(text: String, size := 20, col := Color.WHITE) -> Label:
	var l := UITheme.label(Loc.t(text), size, col, UITheme.semi_font())
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Story panel: difficulty, Save / Load and New Game in one row at the top, always in view.
## The save slots open right under the row when you press Save / Load.
static func story_block(body: VBoxContainer, host: Node) -> void:
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 10)
	body.add_child(diff_row)
	var dl := _line("Difficulty", 20)
	# A wrapping label with no width of its own folds to one letter a line and drags the row tall.
	dl.autowrap_mode = TextServer.AUTOWRAP_OFF
	dl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	diff_row.add_child(dl)
	var opt := OptionButton.new()
	for nm in ["Easy", "Normal", "Hard"]:
		opt.add_item(Loc.t(nm))
	opt.select(Saves.story_difficulty())
	opt.custom_minimum_size = Vector2(150, 52)
	opt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	opt.tooltip_text = Loc.t("You can change this any time. It changes how well story opponents play, not what happens.")
	opt.item_selected.connect(func(i): Saves.set_story_difficulty(i))
	diff_row.add_child(opt)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_row.add_child(gap)
	if Saves.admin:
		body.add_child(_line("ADMIN MODE IS ON: every chapter is open. Saving is switched off. Turn it off in Settings to get your own game back.", 18, UITheme.GOLD))
		return
	var slots := VBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	slots.visible = false
	var sl := Button.new()
	sl.text = Loc.t("Save / Load")
	sl.custom_minimum_size = Vector2(170, 52)
	sl.toggle_mode = true
	sl.toggled.connect(func(on): slots.visible = on)
	diff_row.add_child(sl)
	var ng0 := Button.new()
	ng0.text = Loc.t("New Game")
	ng0.custom_minimum_size = Vector2(150, 52)
	diff_row.add_child(ng0)
	body.add_child(slots)
	body = slots
	for i in Saves.SLOTS + 1:
		var slot := "autosave" if i == 0 else "slot%d" % i
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		body.add_child(row)
		var meta := Saves.info(slot)
		var name := Loc.t("Autosave") if i == 0 else Loc.t("Save %d") % i
		var text := name + "   " + (Loc.t("empty") if meta.is_empty() else "%s   (%s)" % [Loc.t(str(meta["summary"])), str(meta["when"])])
		var l := _line(text, 19, Color.WHITE if not meta.is_empty() else UITheme.TEXT_DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if i > 0:
			var sv := Button.new()
			sv.text = Loc.t("Save here")
			sv.custom_minimum_size = Vector2(150, 46)
			sv.pressed.connect(func():
				var go := func():
					Saves.save_to(slot)
					Router.toast(Loc.t("Game saved to %s.") % name)
					l.text = name + "   " + Loc.t(Saves.summary()) + "   (" + Loc.t("just now") + ")"
				if Saves.exists(slot):
					_ask(host, "Overwrite this save? The game that is in it now will be gone.", "Overwrite", go)
				else:
					go.call())
			row.add_child(sv)
		var ld := Button.new()
		ld.text = Loc.t("Load")
		ld.custom_minimum_size = Vector2(110, 46)
		ld.disabled = meta.is_empty()
		ld.pressed.connect(func():
			_ask(host, "Load this save? The game restarts on it. Anything you have not saved to a slot stays only in the autosave.", "Load",
				func(): Saves.restart_with("load:" + slot)))
		row.add_child(ld)
	ng0.pressed.connect(func():
		_ask(host, "Start a new game from the very beginning: story, cards, Duel Points, everything? Save your current game to a slot first if you want to keep it. The game restarts.", "Start over",
			func(): Saves.restart_with("new")))


## Settings: wipe everything, and the admin switch.
static func settings_block(add_row: Callable, host: Node) -> void:
	var wipe := Button.new()
	wipe.text = Loc.t("Restart the whole game")
	wipe.custom_minimum_size = Vector2(300, 46)
	wipe.disabled = Saves.admin
	wipe.pressed.connect(func():
		_ask(host, "Restart the whole game? Your story, your cards, your Duel Points, your decks and your progress in every world go back to day one. Your save slots are kept.", "Yes, restart",
			func(): _ask(host, "Last check. This cannot be undone, except by loading a save slot. Restart everything now?", "Restart everything",
				func(): Saves.restart_with("new"))))
	add_row.call("Restart the game", "Back to a brand new game. Asks twice. Save slots are kept.", wipe)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_admin_controls(box, host)
	add_row.call("Admin mode", "For testing: every world, chapter, duelist and pack is open, with plenty of Duel Points. Your real game is not touched. Switch it on and off here as often as you like.", box)


## The admin switch. Off: a PIN box the first time, then just a button (the game remembers you
## know the PIN). On: a button that turns it off again and brings your own game back.
static func _admin_controls(box: HBoxContainer, host: Node) -> void:
	for c in box.get_children():
		c.queue_free()
	if Saves.admin:
		var badge := _line("ON", 20, UITheme.GOLD)
		box.add_child(badge)
		var off := Button.new()
		off.text = Loc.t("Turn admin mode off")
		off.custom_minimum_size = Vector2(280, 46)
		off.pressed.connect(func(): _ask(host, "Leave admin mode? The game restarts on your own save, exactly as you left it.", "Leave admin mode", func(): Saves.admin_off()))
		box.add_child(off)
		return
	var turn_on := func(pin_text: String) -> bool:
		if not Saves.admin_on(pin_text):
			return false
		Router.toast(Loc.t("Admin mode on: everything is open. Your own game is put aside until you turn it off."))
		var col = host.get_tree().root.get_node_or_null("Collection")
		if col:
			col.dp += 500000
		_admin_controls(box, host)
		return true
	if Saves.pin_known():
		var again := Button.new()
		again.text = Loc.t("Turn admin mode on")
		again.custom_minimum_size = Vector2(280, 46)
		again.pressed.connect(func(): turn_on.call(Saves.PIN))
		box.add_child(again)
		return
	var pin := LineEdit.new()
	pin.secret = true
	pin.placeholder_text = Loc.t("PIN")
	pin.max_length = 8
	pin.custom_minimum_size = Vector2(140, 46)
	box.add_child(pin)
	var on := Button.new()
	on.text = Loc.t("Unlock")
	on.custom_minimum_size = Vector2(150, 46)
	var try_pin := func():
		if not turn_on.call(pin.text):
			Router.toast(Loc.t("Wrong PIN."))
			pin.text = ""
	on.pressed.connect(try_pin)
	pin.text_submitted.connect(func(_t): try_pin.call())
	box.add_child(on)
