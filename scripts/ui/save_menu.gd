class_name SaveMenu
extends Control
## Save and Load: the autosave and five save slots, each a card with where you were, how far the
## story is, your cards and Duel Points, and when it was saved. Save over a slot, load one (the
## game restarts on it and offers to take you back to where you were), or delete one. Opens from
## the main menu, the pause menu in the worlds and the Story panel.

signal closed

var _rows: VBoxContainer
var _confirm: Control
var _first: Control
var can_save := true     # false from the main menu: only loading makes sense there


var academy := false     # opened from the Academy's door: its picture behind, and each slot's dorm crest
var story := false       # opened from the main story's door: Domino at night behind, each slot's chapter mark


static func open(host: Node, saving := true, academy_look := false, story_look := false) -> SaveMenu:
	var m := SaveMenu.new()
	m.can_save = saving
	m.academy = academy_look
	m.story = story_look
	m.z_index = 120
	host.add_child(m)
	return m


func _ready() -> void:
	Router.busy()      # (a ring turns in the corner if this screen takes a moment to come up)
	z_index = maxi(z_index, 120)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	if academy:
		add_child(AcademyBackdrop.new(0.74))
	elif story:
		var bd := AcademyBackdrop.new(0.74, StoryGate.PICTURE, Color(0.72, 0.9, 1.0))
		add_child(bd)
		bd.cycle(StoryGate.all_pictures())
	else:
		add_child(MenuBackdrop.new())
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(1180, 0)
	c.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	v.add_child(head)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", -4)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tb)
	tb.add_child(UITheme.label(Loc.t("STORY SAVES") if can_save else Loc.t("LOAD A STORY SAVE"), 54, Color.WHITE, UITheme.title_font()))
	var sub := UITheme.label(Loc.t("Save the story right where you are, or go back to a moment you saved. The autosave is written before every duel and at every step: Continue always picks up from it.") if can_save
			else Loc.t("Go back to a moment you saved. To save, open the pause menu while you are in the story."), 19, UITheme.TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(900, 0)
	tb.add_child(sub)
	var done := Button.new()
	done.text = "  Done  "
	done.add_theme_font_size_override("font_size", 24)
	done.custom_minimum_size = Vector2(0, 58)
	done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(_close)
	head.add_child(done)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	v.add_child(_rows)
	if Saves.admin:
		var warn := UITheme.label(Loc.t("Admin mode is on: saving is switched off. Turn it off in Settings to get your own game back."), 20, UITheme.GOLD, UITheme.semi_font())
		v.add_child(warn)
	_build_rows()
	if _first:
		_first.grab_focus.call_deferred()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	Sfx.play("click", -6.0)


func _build_rows() -> void:
	for ch in _rows.get_children():
		ch.queue_free()
	_first = null
	for i in Saves.SLOTS + 1:
		var slot := "autosave" if i == 0 else "slot%d" % i
		_rows.add_child(_row(slot, i))


func _row(slot: String, i: int) -> Control:
	var meta := Saves.info(slot)
	var empty := meta.is_empty()
	var auto := i == 0
	var col: Color = Color("7fe8ff") if auto else [UITheme.ACCENT, Color("8a6bff"), Color("5aff8a"), Color("ff7ad9"), Color("ffd766")][(i - 1) % 5]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.045, 0.07, 0.14, 0.94) if not empty else Color(0.03, 0.045, 0.09, 0.7),
			Color(col, 0.55) if not empty else Color(1, 1, 1, 0.08), 16))
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 18)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	card.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	m.add_child(h)
	var bar := ColorRect.new()
	bar.color = col if not empty else Color(1, 1, 1, 0.15)
	bar.custom_minimum_size = Vector2(6, 0)
	h.add_child(bar)
	if academy:
		# The crest of the dorm that save is in (a grey one when it holds no Academy game).
		var camp: Dictionary = meta.get("campus", {})
		var crest := DormCrest.new(int(camp.get("dorm", -1)) if not camp.is_empty() else -1, 54.0)
		crest.lit = 1.0 if not camp.is_empty() else 0.35
		crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(crest)
		if not camp.is_empty():
			col = (Campus.DORM_COLORS[int(camp["dorm"])] as Color).lightened(0.2)
			bar.color = col
			card.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.045, 0.07, 0.14, 0.94), Color(col, 0.6), 16))
	if story:
		# The mark of the chapter that save has reached, in its era's color (grey when empty).
		var sw: Dictionary = meta.get("story", {})
		var idx := -1
		var where_t := str(sw.get("where", ""))
		if where_t == "" and str(meta.get("summary", "")) != "":
			where_t = str(meta["summary"]).split("  ·  ")[0]      # (a save from an older build keeps it only in its line)
		for k in StoryData.CHAPTERS.size():
			if str(StoryData.CHAPTERS[k]["title"]) == where_t:
				idx = k
		if where_t == "Story finished":
			idx = StoryData.CHAPTERS.size() - 1
		var ecol := StoryEmblem.era_color(str(StoryData.CHAPTERS[idx]["era"])) if idx >= 0 else Color(0.45, 0.48, 0.56)
		var em := StoryEmblem.new(ecol, StoryGate.mark_of(idx) if idx >= 0 else "", 58.0)
		em.lit = 1.0 if idx >= 0 else 0.35
		em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(em)
		if idx >= 0:
			col = ecol.lightened(0.1)
			bar.color = col
			card.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.045, 0.07, 0.14, 0.94), Color(col, 0.6), 16))
	var name_box := VBoxContainer.new()
	name_box.custom_minimum_size = Vector2(190, 0)
	name_box.add_theme_constant_override("separation", -2)
	h.add_child(name_box)
	name_box.add_child(UITheme.label(Loc.t("AUTOSAVE") if auto else Loc.t("SAVE %d") % i, 30, col.lightened(0.2) if not empty else UITheme.TEXT_DIM, UITheme.title_font()))
	name_box.add_child(UITheme.label(_when(str(meta.get("when", ""))) if not empty else Loc.t("Empty"), 16, UITheme.TEXT_DIM, UITheme.semi_font()))
	if story and not empty:
		# The world that save is in, in its color: a small tag under the date.
		var wd := StoryGate.world_of_save(meta.get("story", {}))
		if wd != "":
			name_box.add_child(UITheme.label("●  " + StoryGate.world_name(wd), 15, StoryGate.world_color(wd).lightened(0.15), UITheme.semi_font()))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	h.add_child(info)
	if not empty:
		var place := str(meta.get("place", ""))
		if place != "":
			info.add_child(UITheme.label(place, 23, Color.WHITE, UITheme.semi_font()))
		var sm := UITheme.label(Loc.t(str(meta["summary"])), 18 if place != "" else 23, UITheme.TEXT_DIM if place != "" else Color.WHITE, UITheme.semi_font() if place == "" else null)
		info.add_child(sm)
		info.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		info.add_child(UITheme.label(Loc.t("Nothing saved here yet."), 20, UITheme.TEXT_DIM))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btns)
	if not auto and can_save:
		var sv := _btn(Loc.t("Save here"), true)
		sv.disabled = Saves.admin
		sv.pressed.connect(func():
			if empty:
				_do_save(slot, i)
			else:
				_ask(Loc.t("Save over %s? The game that is in it now will be gone.") % (Loc.t("SAVE %d") % i).capitalize(), Loc.t("Save over it"), _do_save.bind(slot, i)))
		btns.add_child(sv)
		if _first == null:
			_first = sv
	var ld := _btn(Loc.t("Load"))
	ld.disabled = empty or Saves.admin
	ld.pressed.connect(func():
		_ask(Loc.t("Load this save? The game restarts on it. Anything you have done since then is only kept in the autosave."), Loc.t("Load"),
			func():
				Sfx.play("quest", -4.0)
				Saves.restart_with("load:" + slot)))
	btns.add_child(ld)
	if not auto:
		var del := _btn(Loc.t("Delete"))
		del.disabled = empty or Saves.admin
		del.pressed.connect(func():
			_ask(Loc.t("Delete this save? This cannot be undone."), Loc.t("Delete"), func():
				Saves.delete_slot(slot)
				Router.toast(Loc.t("Save deleted."))
				_build_rows()))
		btns.add_child(del)
	return card


func _do_save(slot: String, i: int) -> void:
	if Saves.save_to(slot):
		Sfx.play("quest", -4.0)
		Router.toast(Loc.t("Game saved to %s.") % (Loc.t("SAVE %d") % i).capitalize())
	_build_rows()
	if _first:
		_first.grab_focus.call_deferred()


## "Today, 8:12" / "Yesterday, 21:40" / "Nov 3, 18:05" from a saved date and time.
static func _when(stamp: String) -> String:
	if stamp == "":
		return ""
	var d := Time.get_datetime_dict_from_datetime_string(stamp, false)
	var now := Time.get_datetime_dict_from_system()
	var hm := "%02d:%02d" % [int(d.get("hour", 0)), int(d.get("minute", 0))]
	var day := Time.get_unix_time_from_datetime_dict({"year": d["year"], "month": d["month"], "day": d["day"]})
	var today := Time.get_unix_time_from_datetime_dict({"year": now["year"], "month": now["month"], "day": now["day"]})
	var diff := int((today - day) / 86400)
	if diff == 0:
		return Loc.t("Today, %s") % hm
	if diff == 1:
		return Loc.t("Yesterday, %s") % hm
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %d, %s" % [Loc.t(str(months[clampi(int(d["month"]) - 1, 0, 11)])), int(d["day"]), hm]


func _btn(text: String, primary := false) -> Button:
	var b := Button.new()
	b.text = "  %s  " % text
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_font_size_override("font_size", 21)
	if primary:
		b.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.22), UITheme.GOLD, 14))
		b.add_theme_stylebox_override("hover", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 14))
		b.add_theme_stylebox_override("focus", UITheme.button_box(Color(UITheme.GOLD, 0.4), Color.WHITE, 14))
	return b


## A small question in the middle of the screen, with the safe answer focused.
func _ask(text: String, yes: String, then: Callable) -> void:
	if _confirm:
		_confirm.queue_free()
	_confirm = Control.new()
	_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.05, 0.08, 0.16, 0.98), 20, Color(UITheme.ACCENT, 0.6)))
	cc.add_child(p)
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 28)
	p.add_child(pm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	pm.add_child(v)
	var l := UITheme.label(text, 23, Color.WHITE, UITheme.semi_font())
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(620, 0)
	v.add_child(l)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var no := _btn(Loc.t("Cancel"))
	var c2 := _confirm
	no.pressed.connect(func():
		c2.queue_free()
		_confirm = null)
	h.add_child(no)
	var ok := _btn(yes, true)
	ok.pressed.connect(func():
		c2.queue_free()
		_confirm = null
		then.call())
	h.add_child(ok)
	no.grab_focus.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		if _confirm:
			_confirm.queue_free()
			_confirm = null
		else:
			_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	set_process_unhandled_input(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		closed.emit()
		queue_free())


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and _first:
		_first.grab_focus.call_deferred()
