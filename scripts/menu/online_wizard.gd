class_name OnlineWizard
extends Control
## "Make a group" (0.73.0): five numbered steps with a picture of each page, a progress bar, and the
## game checking each step. mode "make": all five. mode "renew": the owner's new key (steps 2, 3,
## then the new invite code), for when the key is about to run out or the old code must stop working.

signal done

const TEAL := Color("2de2e6")
const KEYS_URL := "https://login.tailscale.com/admin/settings/keys"
const START_URL := "https://login.tailscale.com/start"

var mode := "make"
var _steps: Array = []        # step numbers shown (1..5)
var _at := 0                  # index into _steps
var _key := ""
var _name := ""
var _color := 0
var _checked := false
var _old_key := {}            # (renew) the group's key before, to go back to when the new one fails
var _made_gid := ""
var _check_token := 0

var _bar: HBoxContainer
var _page: HBoxContainer
var _next: Button
var _back: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_steps = [1, 2, 3, 4, 5] if mode == "make" else [2, 3, 5]
	_name = Loc.t("%s's Table") % Profile.duelist_name
	add_child(MenuBackdrop.new(1.0, TEAL))
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 90)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 34)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	m.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	root.add_child(head)
	var t := UITheme.label("MAKE A GROUP" if mode == "make" else "A NEW KEY FOR THE GROUP", 40, Color.WHITE, UITheme.title_font())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x := Button.new()
	x.text = "Close"
	x.custom_minimum_size = Vector2(110, 44)
	x.pressed.connect(_quit)
	head.add_child(x)
	_bar = HBoxContainer.new()
	_bar.add_theme_constant_override("separation", 0)
	root.add_child(_bar)
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.92), 22, Color(TEAL, 0.35)))
	pp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(pp)
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 30)
	pp.add_child(pm)
	_page = HBoxContainer.new()
	_page.add_theme_constant_override("separation", 34)
	pm.add_child(_page)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 14)
	root.add_child(nav)
	_back = Button.new()
	_back.text = "◀  Back"
	_back.custom_minimum_size = Vector2(150, 54)
	_back.pressed.connect(func(): _go(_at - 1))
	nav.add_child(_back)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(gap)
	_next = Button.new()
	_next.custom_minimum_size = Vector2(240, 54)
	_next.add_theme_font_size_override("font_size", 20)
	_next.add_theme_stylebox_override("normal", UITheme.button_box(Color(TEAL, 0.2), TEAL))
	_next.pressed.connect(func(): _go(_at + 1))
	nav.add_child(_next)
	if mode == "renew":
		var g := Net.group()
		_old_key = {"key": g.get("key", ""), "key_made": g.get("key_made", 0)}
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	_go(0)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_quit()


func _quit() -> void:
	_check_token += 1
	if mode == "renew" and not _checked and not _old_key.is_empty():
		# (a new key that was never checked does not replace the one that works)
		var g := Net.group()
		if str(g.get("key", "")) != str(_old_key["key"]):
			g["key"] = _old_key["key"]
			g["key_made"] = _old_key["key_made"]
			Net._save()
			Net.link_restart()
	if mode == "make" and _made_gid != "" and not _checked:
		# (a group whose key never worked is not kept)
		Net.leave_group(_made_gid)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	done.emit()
	queue_free()


func _go(i: int) -> void:
	if i < 0:
		return
	if i >= _steps.size():
		_quit()
		return
	# (step 3 can't be left forward before the key worked)
	if i > _at and _steps[_at] == 3 and not _checked:
		return
	if i > _at and _steps[_at] == 4:
		if _name.strip_edges() == "":
			return
		Net.rename_group(_name, _color)
	_at = i
	_draw_bar()
	for c in _page.get_children():
		_page.remove_child(c)
		c.queue_free()
	_back.visible = _at > 0 and _steps[_at] != 5
	_next.disabled = false
	match int(_steps[_at]):
		1: _step1()
		2: _step2()
		3: _step3()
		4: _step4()
		5: _step5()
	_next.text = Loc.t("Done") if _at == _steps.size() - 1 else Loc.t("Next  ▶")
	_page.modulate.a = 0.0
	create_tween().tween_property(_page, "modulate:a", 1.0, 0.16)


func _draw_bar() -> void:
	for c in _bar.get_children():
		c.queue_free()
	var names := {1: "Account", 2: "Key", 3: "Check", 4: "Name", 5: "Invite"}
	for k in _steps.size():
		var n: int = _steps[k]
		var done_k := k < _at
		var here := k == _at
		var col := TEAL if (done_k or here) else Color(1, 1, 1, 0.25)
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(44, 44)
		dot.add_theme_stylebox_override("panel", UITheme.button_box(Color(col, 0.9 if done_k else (0.25 if here else 0.05)), col, 22))
		var num := UITheme.label("✓" if done_k else str(k + 1), 20, Color(0.02, 0.05, 0.1) if done_k else Color.WHITE, UITheme.semi_font())
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.add_child(num)
		box.add_child(dot)
		box.add_child(UITheme.label(str(names[n]), 18, Color.WHITE if here else UITheme.TEXT_DIM, UITheme.semi_font()))
		if k < _steps.size() - 1:
			var line := ColorRect.new()
			line.color = Color(TEAL, 0.8) if done_k else Color(1, 1, 1, 0.12)
			line.custom_minimum_size = Vector2(0, 4)
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			box.add_child(line)
		_bar.add_child(box)


func _text_col(title: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_child(v)
	v.add_child(UITheme.label(title, 32, TEAL, UITheme.title_font()))
	return v


func _para(v: Control, text: String, size := 19, col := UITheme.TEXT) -> Label:
	var l := UITheme.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	return l


func _picture(kind: String) -> void:
	var p := _Pic.new()
	p.kind = kind
	p.custom_minimum_size = Vector2(640, 420)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_page.add_child(p)


func _big_btn(v: Control, text: String, cb: Callable, col := UITheme.GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_stylebox_override("normal", UITheme.button_box(Color(col, 0.2), col))
	b.pressed.connect(cb)
	v.add_child(b)
	return b


# ------------------------------------------------------------------ the steps

func _step1() -> void:
	var v := _text_col("1  A FREE ACCOUNT, JUST FOR THE GAME")
	_para(v, "Your group lives on a free Tailscale account. Make one only for Crossroads: then nothing else of yours is ever in the group, and you can hand it to someone else one day.")
	_para(v, "The easiest way: sign up with a new Google or GitHub account, or with an email you don't use for anything else.", 18, UITheme.TEXT_DIM)
	_para(v, "If Tailscale asks you to download it or to add your first device, skip that. The game is the only thing that joins.", 18, UITheme.TEXT_DIM)
	_big_btn(v, "Open tailscale.com", func(): OS.shell_open(START_URL))
	_para(v, "Signed in? Press Next.", 17, TEAL)
	_picture("signup")


func _step2() -> void:
	var v := _text_col("2  A KEY FOR THE GAME" if mode == "make" else "1  A NEW KEY")
	_para(v, "Signed in to the group's Tailscale account, open the keys page (Settings > Keys) and press Generate auth key.")
	_para(v, "In the window that opens:\n•  Reusable: ON (everyone in the group uses the same key)\n•  Expiration: 90 days\n•  Leave the rest as it is, and press Generate key.", 19)
	_para(v, "Copy the key it shows (it starts with tskey-auth-). Tailscale shows it only once.", 18, UITheme.GOLD)
	_big_btn(v, "Open the keys page", func(): OS.shell_open(KEYS_URL))
	_picture("keys")


func _step3() -> void:
	var v := _text_col("3  PASTE THE KEY" if mode == "make" else "2  PASTE THE NEW KEY")
	_para(v, "Paste it here. The game tries it right away.")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var le := LineEdit.new()
	le.placeholder_text = "tskey-auth-..."
	le.text = _key
	le.secret = false
	le.custom_minimum_size = Vector2(0, 54)
	le.add_theme_font_size_override("font_size", 18)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(le)
	var paste := Button.new()
	paste.text = "Paste"
	paste.custom_minimum_size = Vector2(110, 54)
	paste.pressed.connect(func(): le.text = DisplayServer.clipboard_get().strip_edges())
	row.add_child(paste)
	var state := HBoxContainer.new()
	state.add_theme_constant_override("separation", 12)
	v.add_child(state)
	var mark := UITheme.label("", 40, TEAL)
	state.add_child(mark)
	var msg := UITheme.label("", 20, UITheme.TEXT)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state.add_child(msg)
	var tryb := _big_btn(v, "Try the key", func(): pass, TEAL)
	tryb.pressed.connect(func(): _try(le.text, mark, msg, tryb))
	le.text_submitted.connect(func(_t): _try(le.text, mark, msg, tryb))
	if _checked:
		mark.text = "✓"
		msg.text = Loc.t("Your group is ready.")
	_next.disabled = not _checked
	_picture("paste")
	le.grab_focus()


## The key, tried for real: Crossroads Link starts with it and the game waits until it is in (or says why not).
func _try(text: String, mark: Label, msg: Label, b: Button) -> void:
	var key := text.strip_edges().replace(" ", "")
	mark.add_theme_color_override("font_color", UITheme.DANGER)
	if key.begins_with("tskey-api-"):
		mark.text = "✕"
		msg.text = Loc.t("That is an API access token. In step 2, press Generate auth key (not an access token).")
		return
	if not key.begins_with("tskey-auth-") or key.length() < 30:
		mark.text = "✕"
		msg.text = Loc.t("That is not a key. It starts with tskey-auth-: copy it again from step 2.")
		return
	_key = key
	_checked = false
	_next.disabled = true
	b.disabled = true
	mark.add_theme_color_override("font_color", TEAL)
	mark.text = "…"
	msg.text = Loc.t("Trying the key...")
	if mode == "make":
		if _made_gid == "":
			_made_gid = str(Net.make_group(_name, _color, key)["gid"])
		else:
			Net.use_group(_made_gid)
			Net.renew_key(key)
	else:
		Net.renew_key(key)
	Net.link_restart()
	_check_token += 1
	var tok := _check_token
	var t0 := Time.get_ticks_msec()
	while tok == _check_token and is_inside_tree():
		await get_tree().create_timer(0.5).timeout
		if tok != _check_token or not is_inside_tree():
			return
		if Net.link_state == "running":
			_checked = true
			mark.text = "✓"
			msg.text = Loc.t("Your group is ready.")
			_next.disabled = false
			b.disabled = false
			Sfx.play("summon", -8.0)
			return
		var step := 2 if mode == "make" else 1
		if Net.link_why in ["expired", "bad_key"] or (Net.link_state == "error" and Net.link_why == "" and Time.get_ticks_msec() - t0 > 2500):
			mark.add_theme_color_override("font_color", UITheme.DANGER)
			mark.text = "✕"
			match Net.link_why:
				"expired":
					msg.text = Loc.t("That key has expired. Make a new one in step %d.") % step
				"bad_key":
					msg.text = Loc.t("Tailscale did not take that key. Copy it again from step %d (all of it), or make a new one.") % step
				_:
					msg.text = Loc.t("It didn't work: %s") % Net.link_error
			b.disabled = false
			return
		if Net.link_why == "offline" and Time.get_ticks_msec() - t0 > 12000:
			mark.add_theme_color_override("font_color", UITheme.DANGER)
			mark.text = "✕"
			msg.text = Loc.t("The game couldn't reach Tailscale. Check the internet connection and try again.")
			b.disabled = false
			return
		if Time.get_ticks_msec() - t0 > 45000:
			mark.add_theme_color_override("font_color", UITheme.DANGER)
			mark.text = "✕"
			msg.text = Loc.t("The game couldn't reach Tailscale. Check the internet connection and try again.")
			b.disabled = false
			return


func _step4() -> void:
	var v := _text_col("4  NAME AND COLOR")
	_para(v, "This is what everyone in the group sees.")
	var le := LineEdit.new()
	le.text = _name
	le.max_length = 28
	le.custom_minimum_size = Vector2(0, 54)
	le.add_theme_font_size_override("font_size", 22)
	v.add_child(le)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 10)
	v.add_child(crow)
	var preview := PanelContainer.new()
	var plabel := UITheme.label(_name.to_upper(), 34, OnlineScreen.GROUP_COLORS[_color], UITheme.title_font())
	var paint := func():
		preview.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.95), 18, OnlineScreen.GROUP_COLORS[_color]))
		plabel.text = _name.to_upper()
		plabel.add_theme_color_override("font_color", OnlineScreen.GROUP_COLORS[_color])
		for k in crow.get_child_count():
			(crow.get_child(k) as Button).add_theme_stylebox_override("normal", UITheme.button_box(OnlineScreen.GROUP_COLORS[k], Color.WHITE if k == _color else Color(0, 0, 0, 0), 26))
	for i in OnlineScreen.GROUP_COLORS.size():
		var cb := Button.new()
		cb.custom_minimum_size = Vector2(52, 52)
		cb.pressed.connect(func():
			_color = i
			paint.call())
		crow.add_child(cb)
	le.text_changed.connect(func(t):
		_name = t
		paint.call()
		_next.disabled = t.strip_edges() == "")
	var pm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + side, 22)
	pm.add_child(plabel)
	preview.add_child(pm)
	v.add_child(preview)
	paint.call()
	_picture("name")
	le.grab_focus()


func _step5() -> void:
	var v := _text_col("5  INVITE PEOPLE" if mode == "make" else "3  THE NEW INVITE CODE")
	if mode == "renew":
		_para(v, "Done: the group runs on the new key. The old invite code no longer lets anyone in once the old key is gone (delete it on the keys page if you want it gone now).")
		_para(v, "Everyone already in the group gets the new key by itself the next time they are online with you. Someone who was away for a long time can paste this code.", 18, UITheme.TEXT_DIM)
	else:
		_para(v, "Your group is ready. Send this code to the people you want to duel (WhatsApp, a text, anything). They paste it under Online > Join a group.")
		_para(v, "The code is the way in: send it only to people you want in the group. You can make a new one any time (Owner tools), and the old one stops working.", 18, UITheme.TEXT_DIM)
	var code := Net.invite_code()
	var copy := _big_btn(v, "Copy the invite code", func(): pass)
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(code)
		copy.text = Loc.t("Copied!")
		Sfx.play("click", -6.0))
	var cl := UITheme.label(code, 12, UITheme.TEXT_DIM)
	cl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	v.add_child(cl)
	var img := QrCode.image(code, 6)
	if img != null:
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(400, 400)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_page.add_child(tr)


## A drawing of the page a step is about (not a screenshot: the shapes, the words to look for, and
## the one thing to press, circled).
class _Pic:
	extends Control
	var kind := ""

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.93, 0.95, 0.98), true)
		draw_rect(Rect2(0, 0, w, 40), Color(0.82, 0.86, 0.92), true)
		for i in 3:
			draw_circle(Vector2(20 + i * 18, 20), 6, [Color("ff5f57"), Color("febc2e"), Color("28c840")][i])
		draw_rect(Rect2(80, 9, w - 100, 22), Color.WHITE, true)
		var url: String = {"signup": "login.tailscale.com/start", "keys": "login.tailscale.com/admin/settings/keys",
			"paste": "Crossroads  ·  Online", "name": "Crossroads  ·  Online"}.get(kind, "")
		draw_string(f, Vector2(90, 26), url, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.33, 0.4))
		var ink := Color(0.12, 0.14, 0.2)
		var dim := Color(0.45, 0.48, 0.56)
		var ring := Color("e63946")
		match kind:
			"signup":
				draw_string(f, Vector2(w / 2 - 150, 100), "Sign up for Tailscale", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, ink)
				var labels := ["Sign up with Google", "Sign up with Microsoft", "Sign up with GitHub", "Sign up with Apple"]
				for i in labels.size():
					var r := Rect2(w / 2 - 170, 130 + i * 58, 340, 44)
					draw_rect(r, Color.WHITE, true)
					draw_rect(r, Color(0.75, 0.78, 0.84), false, 2.0)
					draw_string(f, r.position + Vector2(70, 29), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ink)
				draw_rect(Rect2(w / 2 - 180, 122, 360, 60), ring, false, 4.0)
				draw_string(f, Vector2(w / 2 - 170, h - 30), Loc.t("A new account, only for the game"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ring)
			"keys":
				draw_rect(Rect2(0, 40, 150, h - 40), Color(0.88, 0.9, 0.94), true)
				for i in 5:
					draw_string(f, Vector2(18, 80 + i * 30), ["General", "Users", "Keys", "OAuth clients", "Billing"][i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink if i == 2 else dim)
				draw_rect(Rect2(8, 120, 134, 28), ring, false, 3.0)
				draw_string(f, Vector2(170, 85), "Keys", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
				var dlg := Rect2(190, 105, w - 220, h - 125)
				draw_rect(dlg, Color.WHITE, true)
				draw_rect(dlg, Color(0.7, 0.73, 0.8), false, 2.0)
				draw_string(f, dlg.position + Vector2(20, 34), "Generate auth key", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, ink)
				var rows := [["Reusable", true], ["Expiration      90 days", false], ["Ephemeral", false], ["Tags", false]]
				for i in rows.size():
					var y: float = dlg.position.y + 74 + i * 44
					draw_string(f, Vector2(dlg.position.x + 20, y), str(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
					if i != 1:
						var on: bool = rows[i][1]
						var sw := Rect2(dlg.end.x - 70, y - 17, 44, 22)
						draw_rect(sw, Color("2b6cb0") if on else Color(0.8, 0.82, 0.86), true)
						draw_circle(Vector2(sw.end.x - 11 if on else sw.position.x + 11, sw.position.y + 11), 9, Color.WHITE)
				draw_rect(Rect2(dlg.position.x + 8, dlg.position.y + 50, dlg.size.x - 16, 36), ring, false, 3.0)
				draw_rect(Rect2(dlg.position.x + 8, dlg.position.y + 94, dlg.size.x - 16, 36), ring, false, 3.0)
				var gb := Rect2(dlg.end.x - 150, dlg.end.y - 52, 130, 36)
				draw_rect(gb, Color("2b6cb0"), true)
				draw_string(f, gb.position + Vector2(16, 24), "Generate key", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
				draw_rect(gb.grow(5), ring, false, 3.0)
			"paste":
				draw_rect(Rect2(0, 40, w, h - 40), Color("0b1226"), true)
				draw_string(f, Vector2(40, 100), Loc.t("3  PASTE THE KEY"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("2de2e6"))
				draw_rect(Rect2(40, 130, w - 80, 46), Color(1, 1, 1, 0.08), true)
				draw_string(f, Vector2(54, 160), "tskey-auth-k1a2B3c4CNTRL-...", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.8))
				draw_string(f, Vector2(40, 240), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("2de2e6"))
				draw_string(f, Vector2(90, 232), Loc.t("Your group is ready."), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
			"name":
				draw_rect(Rect2(0, 40, w, h - 40), Color("0b1226"), true)
				var cols: Array = OnlineScreen.GROUP_COLORS
				for i in 4:
					var r := Rect2(50, 80 + i * 78, w - 100, 62)
					draw_rect(r, Color(1, 1, 1, 0.05), true)
					draw_rect(Rect2(r.position, Vector2(8, r.size.y)), cols[i], true)
					draw_string(f, r.position + Vector2(26, 40), [Loc.t("You"), "Alex", "Sam", "Jordan"][i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
					draw_string(f, r.position + Vector2(r.size.x - 120, 40), ["", Loc.t("Online"), Loc.t("In a duel"), Loc.t("Online")][i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.6))
