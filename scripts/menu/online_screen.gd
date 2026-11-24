class_name OnlineScreen
extends Control
## The Online screen (0.73.0): your Duel Group and the people in it.
##
## The first time: two big cards, Join a group (paste an invite code) and Make a group (guided steps,
## see OnlineWizard). After that: the lobby, everyone in the group with their duelist, whether they
## are online, how good the line to them is, and your record against them; a Challenge button; your
## group's card with its invite code; the owner's tools; Help.

signal closed

const TEAL := Color("2de2e6")
const BACK_PICTURE := "res://assets/ui/story_title_heartland.jpg"

## The top corners of a card's picture, rounded like the card itself (the picture is drawn inside
## the border, so nothing pokes out at the corners).
const ROUND_TOP := """
shader_type canvas_item;
uniform vec2 box = vec2(100.0);
uniform float radius = 20.0;
varying vec2 local;
void vertex() { local = VERTEX; }
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 q = vec2(min(local.x, box.x - local.x), local.y);
	if (q.x < radius && q.y < radius) {
		float d = length(vec2(radius) - q);
		c.a *= 1.0 - smoothstep(radius - 1.0, radius + 0.5, d);
	}
	COLOR = c;
}
"""
static var _round_shader: Shader
const GROUP_COLORS := [Color("2de2e6"), Color("ffd766"), Color("ff4d6d"), Color("7b5cff"), Color("4fd18b"), Color("3a86ff"), Color("ff9f1c"), Color("ff6ec7")]

var _body: VBoxContainer
var _head_group: Label
var _head_dot: ColorRect
var _shape := ""
var _rows := {}               # member id -> {status: Label, bars: Control, button: Button}
var _modal: Control
var _wait_card: Control
var _wait_cid := ""
var _refresh_at := 0
var _groups_b: Button


func _ready() -> void:
	Router.busy()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	add_child(AcademyBackdrop.new(0.42, BACK_PICTURE, Color(0.75, 0.95, 1.0)))
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 80)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 34)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
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
	head.add_child(UITheme.label("ONLINE", 44, Color.WHITE, UITheme.title_font()))
	var gbox := HBoxContainer.new()
	gbox.add_theme_constant_override("separation", 8)
	gbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(gbox)
	_head_dot = ColorRect.new()
	_head_dot.custom_minimum_size = Vector2(12, 12)
	_head_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gbox.add_child(_head_dot)
	_head_group = UITheme.label("", 20, UITheme.TEXT_DIM, UITheme.semi_font())
	gbox.add_child(_head_group)
	var groups_b := Button.new()
	_groups_b = groups_b
	groups_b.text = "Groups"
	groups_b.custom_minimum_size = Vector2(0, 44)
	groups_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	groups_b.pressed.connect(_groups_menu)
	head.add_child(groups_b)
	var help := Button.new()
	help.text = "Help"
	help.custom_minimum_size = Vector2(0, 44)
	help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	help.pressed.connect(_help)
	head.add_child(help)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_body)
	Net.lobby_open = true
	Net.changed.connect(_on_changed)
	Net.answered.connect(_on_answered)
	if not Net.groups.is_empty() and Net.link_state == "off":
		Net.link_start()
	_refresh(true)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	back.grab_focus()


func _exit_tree() -> void:
	Net.lobby_open = false


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _modal != null and is_instance_valid(_modal):
			_close_modal()
		else:
			_close()


func _close() -> void:
	if not Net.challenge_out.is_empty() and not bool(Net.challenge_out.get("accepted", false)):
		Net.cancel_challenge()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	closed.emit()
	queue_free()


func _on_changed() -> void:
	# (the people and their lines change every few seconds: the screen is only rebuilt when what it
	# shows changed shape; the dots and the bars are updated in place)
	var now := Time.get_ticks_msec()
	if now - _refresh_at < 400:
		return
	_refresh_at = now
	_refresh(false)


# ------------------------------------------------------------------ what the screen shows

func _clear() -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_rows.clear()


func _refresh(force: bool) -> void:
	var g := Net.group()
	_head_dot.color = GROUP_COLORS[clampi(int(g.get("color", 0)), 0, GROUP_COLORS.size() - 1)] if not g.is_empty() else Color(1, 1, 1, 0.2)
	_head_group.text = str(g.get("name", "")) + ("   " + Loc.t("(you own it)") if bool(g.get("owner", false)) else "") if not g.is_empty() else Loc.t("No group yet")
	_groups_b.visible = not Net.groups.is_empty()
	var shape := "none"
	if not g.is_empty():
		shape = "%s|%s" % [Net.current, Net.link_state]
		if Net.link_state == "running":
			for p in Net.people():
				shape += "|%s:%s:%s:%s" % [p["id"], str(p["online"]), str(p["known"]), p["name"]]
	if shape == _shape and not force:
		_update_rows()
		return
	_shape = shape
	_clear()
	if g.is_empty():
		_first_time()
	elif Net.link_state == "running":
		_lobby()
	else:
		_connecting()


## No group yet: two big cards, nothing else to read.
func _first_time() -> void:
	var intro := UITheme.label("Play duels online with your friends, with your own duelist, cards and decks. A Duel Group is a private group just for Crossroads: one person creates it, and everyone else joins with an invite code.", 18, UITheme.TEXT_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(intro)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	_body.add_child(row)
	# Join
	var jv := _big_card(row, "JOIN A GROUP", "Someone sent you an invite code? Paste it here.", TEAL, "res://assets/ui/story_title_newdomino.jpg")
	var code := LineEdit.new()
	code.placeholder_text = Loc.t("Paste the invite code (XR1-...)")
	code.custom_minimum_size = Vector2(0, 52)
	code.add_theme_font_size_override("font_size", 18)
	jv.add_child(code)
	var msg := UITheme.label("", 16, UITheme.DANGER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var jb := Button.new()
	jb.text = "Join"
	jb.custom_minimum_size = Vector2(0, 56)
	jb.add_theme_font_size_override("font_size", 22)
	jb.add_theme_stylebox_override("normal", UITheme.button_box(Color(TEAL, 0.2), TEAL))
	jb.pressed.connect(func():
		var err := Net.join(code.text)
		msg.text = err
		if err == "":
			Sfx.play("summon", -8.0)
			_refresh(true))
	code.text_submitted.connect(func(_t): jb.pressed.emit())
	jv.add_child(jb)
	jv.add_child(msg)
	var perks := UITheme.label("•  You play as your own duelist, with your own cards and decks\n•  One duel or a Match of 3 with Side Deck\n•  Everyone keeps the replay and their record\n•  Nothing to install: the game does it all", 18, UITheme.TEXT_DIM)
	jv.add_child(perks)
	# Make
	var mv := _big_card(row, "MAKE A GROUP", "Be the owner. Takes about 5 minutes, only once.", UITheme.GOLD, "res://assets/ui/story_title_satellite.jpg")
	var steps := UITheme.label("1  A free Tailscale account just for the game\n2  A key for the game\n3  Paste the key: the game checks it\n4  Your group's name and color\n5  Invite people", 17, UITheme.TEXT)
	mv.add_child(steps)
	var mb := Button.new()
	mb.text = "Make a group"
	mb.custom_minimum_size = Vector2(0, 56)
	mb.add_theme_font_size_override("font_size", 22)
	mb.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.2), UITheme.GOLD))
	mb.pressed.connect(func(): _open_wizard("make"))
	mv.add_child(mb)
	var safe := UITheme.label("The group uses a free Tailscale account that you make just for the game. Only people with your invite code can join.", 14, UITheme.TEXT_DIM)
	safe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mv.add_child(safe)


func _big_card(row: HBoxContainer, title: String, sub: String, col: Color, pic := "") -> VBoxContainer:
	var p := PanelContainer.new()
	var box := UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.94), 22, Color(col, 0.6))
	box.set_content_margin_all(0)
	p.add_theme_stylebox_override("panel", box)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_FILL
	p.custom_minimum_size = Vector2(0, 600)
	row.add_child(p)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	p.add_child(stack)
	if pic != "" and ResourceLoader.exists(pic):
		# (inside the 2-pixel border, its top corners rounded to match: see ROUND_TOP)
		var bm := MarginContainer.new()
		for side in ["left", "right", "top"]:
			bm.add_theme_constant_override("margin_" + side, 2)
		stack.add_child(bm)
		var banner := Control.new()
		banner.custom_minimum_size = Vector2(0, 190)
		bm.add_child(banner)
		if _round_shader == null:
			_round_shader = Shader.new()
			_round_shader.code = ROUND_TOP
		var tr := TextureRect.new()
		tr.texture = load(pic)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.modulate = Color(0.8, 0.85, 0.95)
		var sm := ShaderMaterial.new()
		sm.shader = _round_shader
		sm.set_shader_parameter("radius", 20.0)
		tr.material = sm
		tr.resized.connect(func(): sm.set_shader_parameter("box", tr.size))
		banner.add_child(tr)
		var fade := TextureRect.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.03, 0.05, 0.11, 0.0))
		g.set_color(1, Color(0.03, 0.05, 0.11, 0.96))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0.25)
		gt.fill_to = Vector2(0, 1)
		fade.texture = gt
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner.add_child(fade)
	var mm := MarginContainer.new()
	for side in ["left", "right", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 34)
	mm.add_theme_constant_override("margin_top", 6)
	stack.add_child(mm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	mm.add_child(v)
	v.add_child(UITheme.label(title, 46, col, UITheme.title_font()))
	var s := UITheme.label(sub, 21, UITheme.TEXT)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	return v


## The link is starting, or something is wrong with it.
func _connecting() -> void:
	var g := Net.group()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.9), 22, Color(TEAL, 0.4)))
	_body.add_child(p)
	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 30)
	p.add_child(mm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	mm.add_child(v)
	match Net.link_state:
		"starting", "off":
			v.add_child(UITheme.label(Loc.t("Connecting to %s...") % str(g.get("name", "")), 30, TEAL, UITheme.title_font()))
			var s := UITheme.label("The first time on a new network this can take up to half a minute. If Windows asks whether Crossroads Link may use the network, say yes (Private networks is enough).", 17, UITheme.TEXT_DIM)
			s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(s)
			var spin := LoadCard._Ring.new()
			spin.custom_minimum_size = Vector2(84, 84)
			spin.size = Vector2(84, 84)
			spin.pivot_offset = Vector2(42, 42)
			var holder := CenterContainer.new()
			holder.add_child(spin)
			v.add_child(holder)
			var tw := spin.create_tween().set_loops()
			tw.tween_property(spin, "rotation", TAU, 1.1).from(0.0)
		"needs_key":
			v.add_child(UITheme.label("The group's key was not accepted", 30, UITheme.GOLD, UITheme.title_font()))
			var s2 := UITheme.label(Net.link_error if Net.link_error != "" else "It may have run out.", 17, UITheme.TEXT)
			s2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(s2)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			v.add_child(row)
			if Net.is_owner():
				_btn(row, "Make a new key", func(): _open_wizard("renew"), UITheme.GOLD)
			else:
				var s3 := UITheme.label(Loc.t("Ask %s (the owner) for a new invite code, then paste it under Groups.") % str(g.get("owner_name", "")), 17, UITheme.TEXT_DIM)
				s3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				v.add_child(s3)
				_btn(row, "Paste a new invite code", _join_dialog, TEAL)
			_btn(row, "Try again", func(): Net.link_restart(), Color.WHITE)
		_:
			v.add_child(UITheme.label("The group can't be reached right now", 30, UITheme.DANGER, UITheme.title_font()))
			var s4 := UITheme.label(Net.link_error, 17, UITheme.TEXT)
			s4.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(s4)
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 12)
			v.add_child(row2)
			_btn(row2, "Try again", func(): Net.link_restart(), TEAL)
			_btn(row2, "It doesn't connect", _help, Color.WHITE)


func _btn(parent: Control, text: String, cb: Callable, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 50)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_stylebox_override("normal", UITheme.button_box(Color(col, 0.16), Color(col, 0.8)))
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# ------------------------------------------------------------------ the lobby

func _lobby() -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(cols)
	# The people
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.8), 20, Color(TEAL, 0.3)))
	lp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.size_flags_stretch_ratio = 1.9
	cols.add_child(lp)
	var lm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		lm.add_theme_constant_override("margin_" + side, 18)
	lp.add_child(lm)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 10)
	lm.add_child(lv)
	lv.add_child(UITheme.label("IN THE GROUP", 26, TEAL, UITheme.title_font()))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lv.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	# (as tall as the people in it, up to most of the screen; past that it scrolls)
	list.minimum_size_changed.connect(func():
		if is_instance_valid(sc):
			sc.custom_minimum_size.y = minf(list.get_combined_minimum_size().y, 700.0))
	var people := Net.people()
	if people.is_empty():
		var e := UITheme.label("Nobody else is in the group yet. Send your invite code (on the right) to the people you want to duel: the moment they join, they show up here.", 19, UITheme.TEXT_DIM)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.custom_minimum_size = Vector2(0, 160)
		list.add_child(e)
	var keys: Array = []
	for p in people:
		if bool(p["known"]):
			keys.append(str(p["key"]))
	Avatars.read_ahead(keys, 2500)
	for p in people:
		list.add_child(_person_row(p))
	var inv := Button.new()
	inv.text = Loc.t("+   Invite someone (copies the invite code)")
	inv.custom_minimum_size = Vector2(0, 64)
	inv.add_theme_font_size_override("font_size", 18)
	var ib := UITheme.button_box(Color(1, 1, 1, 0.02), Color(TEAL, 0.35), 16)
	inv.add_theme_stylebox_override("normal", ib)
	inv.add_theme_color_override("font_color", Color(TEAL, 0.85))
	inv.pressed.connect(func():
		DisplayServer.clipboard_set(Net.invite_code())
		inv.text = Loc.t("Copied! Send it to them (WhatsApp, a text...)")
		Sfx.play("click", -6.0))
	list.add_child(inv)
	# Your group
	var rp := PanelContainer.new()
	rp.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.8), 20, Color(UITheme.GOLD, 0.3)))
	rp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(rp)
	var rm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		rm.add_theme_constant_override("margin_" + side, 18)
	rp.add_child(rm)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 12)
	rm.add_child(rv)
	var you := HBoxContainer.new()
	you.add_theme_constant_override("separation", 14)
	rv.add_child(you)
	var yf := TextureRect.new()
	yf.custom_minimum_size = Vector2(78, 88)
	yf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	yf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	yf.texture = Portraits.get_portrait("player")
	you.add_child(yf)
	var yv := VBoxContainer.new()
	yv.alignment = BoxContainer.ALIGNMENT_CENTER
	you.add_child(yv)
	yv.add_child(UITheme.label(Profile.duelist_name, 24, Color.WHITE, UITheme.title_font()))
	yv.add_child(UITheme.label(Profile.title_text(), 15, UITheme.GOLD))
	var ydot := UITheme.label(Loc.t("● You are online: the group sees you"), 14, Color("4fd18b"))
	yv.add_child(ydot)
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.08)
	sep.custom_minimum_size = Vector2(0, 2)
	rv.add_child(sep)
	var g := Net.group()
	rv.add_child(UITheme.label(str(g.get("name", "")).to_upper(), 30, GROUP_COLORS[clampi(int(g.get("color", 0)), 0, GROUP_COLORS.size() - 1)], UITheme.title_font()))
	var who := Loc.t("You own this group.") if Net.is_owner() else Loc.t("Owner: %s") % str(g.get("owner_name", ""))
	rv.add_child(UITheme.label(who, 16, UITheme.TEXT_DIM))
	var days := Net.key_days_left()
	if Net.is_owner() and days <= 7:
		var warn := PanelContainer.new()
		warn.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.25, 0.16, 0.02, 0.9), UITheme.GOLD))
		var wv := VBoxContainer.new()
		warn.add_child(wv)
		var wl := UITheme.label(Loc.t("The group's key runs out in %d days.") % maxi(0, days) if days > 0 else Loc.t("The group's key has run out."), 17, UITheme.GOLD, UITheme.semi_font())
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wv.add_child(wl)
		var wb := Button.new()
		wb.text = "Renew it now (2 minutes)"
		wb.pressed.connect(func(): _open_wizard("renew"))
		wv.add_child(wb)
		rv.add_child(warn)
	rv.add_child(UITheme.label("INVITE CODE", 18, UITheme.GOLD, UITheme.semi_font()))
	var hint := UITheme.label("Anyone who pastes it under Online > Join a group is in. Send it however you like (WhatsApp, a text).", 15, UITheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(hint)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 8)
	rv.add_child(crow)
	var copy := Button.new()
	copy.text = "Copy the invite code"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.custom_minimum_size = Vector2(0, 48)
	copy.add_theme_stylebox_override("normal", UITheme.button_box(Color(UITheme.GOLD, 0.18), UITheme.GOLD))
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(Net.invite_code())
		copy.text = Loc.t("Copied!")
		Sfx.play("click", -6.0)
		get_tree().create_timer(1.6).timeout.connect(func():
			if is_instance_valid(copy):
				copy.text = Loc.t("Copy the invite code")))
	crow.add_child(copy)
	var qrb := Button.new()
	qrb.text = "QR"
	qrb.custom_minimum_size = Vector2(70, 48)
	qrb.pressed.connect(_show_qr)
	crow.add_child(qrb)
	if Net.is_owner():
		rv.add_child(UITheme.label("OWNER TOOLS", 18, UITheme.GOLD, UITheme.semi_font()))
		var ot := VBoxContainer.new()
		ot.add_theme_constant_override("separation", 8)
		rv.add_child(ot)
		_btn(ot, "New invite code (the old one stops working)", func(): _open_wizard("renew"), Color.WHITE)
		_btn(ot, "Remove someone", _remove_someone, Color.WHITE)
		_btn(ot, "Name and color", _rename, Color.WHITE)


func _person_row(p: Dictionary) -> Control:
	var id := str(p["id"])
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.button_box(Color(0.05, 0.08, 0.16, 0.92), Color(1, 1, 1, 0.08), 16))
	box.custom_minimum_size = Vector2(0, 124)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	box.add_child(h)
	var band := ColorRect.new()
	band.color = Profile.COLORS[clampi(int(p.get("color", 0)), 0, Profile.COLORS.size() - 1)]
	band.custom_minimum_size = Vector2(6, 0)
	h.add_child(band)
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(104, 116)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if bool(p["known"]):
		face.texture = Portraits.get_portrait(str(p["key"]))
	h.add_child(face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var nm := HBoxContainer.new()
	nm.add_theme_constant_override("separation", 10)
	v.add_child(nm)
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nm.add_child(dot)
	nm.add_child(UITheme.label(str(p["name"]), 28, Color.WHITE, UITheme.title_font()))
	if str(p["title"]) != "":
		nm.add_child(UITheme.label(str(p["title"]), 15, UITheme.GOLD))
	var st := UITheme.label("", 15, UITheme.TEXT_DIM)
	v.add_child(st)
	var rec := Net.record_of(id)
	if int(rec.get("w", 0)) + int(rec.get("l", 0)) + int(rec.get("d", 0)) > 0:
		v.add_child(UITheme.label(Loc.t("Your record: %d won, %d lost") % [int(rec["w"]), int(rec["l"])], 15, TEAL))
	var bars := _Bars.new()
	bars.custom_minimum_size = Vector2(54, 40)
	bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bars)
	var ms := UITheme.label("", 14, UITheme.TEXT_DIM)
	ms.custom_minimum_size = Vector2(70, 0)
	ms.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ms)
	var b := Button.new()
	b.text = "Challenge"
	b.custom_minimum_size = Vector2(150, 54)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_stylebox_override("normal", UITheme.button_box(Color(TEAL, 0.18), TEAL))
	b.pressed.connect(func(): _challenge_dialog(id))
	h.add_child(b)
	_rows[id] = {"dot": dot, "status": st, "bars": bars, "ms": ms, "button": b}
	_update_row(id, p)
	return box


func _update_rows() -> void:
	for p in Net.people():
		if _rows.has(str(p["id"])):
			_update_row(str(p["id"]), p)


func _update_row(id: String, p: Dictionary) -> void:
	var r: Dictionary = _rows[id]
	var online: bool = p["online"]
	var st := str(p["status"])
	var dot_col := Color(0.4, 0.45, 0.55)
	var text := Loc.t("Offline")
	if online:
		match st:
			"duel":
				dot_col = UITheme.GOLD
				text = Loc.t("In a duel")
			"busy":
				dot_col = UITheme.GOLD
				text = Loc.t("Busy now")
			"away":
				dot_col = Color("ff9f1c")
				text = Loc.t("Away")
			_:
				dot_col = Color("4fd18b")
				text = Loc.t("Online")
	elif bool(p.get("reachable", false)):
		text = Loc.t("Connecting...")
	elif int(p.get("last_seen", 0)) > 0:
		text = Loc.t("Offline  ·  last seen %s") % _ago(int(p["last_seen"]))
	if online and str(p["version"]) != "" and str(p["version"]) != str(ProjectSettings.get_setting("application/config/version", "")):
		text = Loc.t("Has version %s (you have %s): both need the same version") % [str(p["version"]), str(ProjectSettings.get_setting("application/config/version", ""))]
		dot_col = UITheme.DANGER
	(r["dot"] as ColorRect).color = dot_col
	(r["status"] as Label).text = text
	var bars := Net.bars(int(p["ms"]), bool(p["direct"])) if online else 0
	if online and int(p["ms"]) < 0 and Net.local:
		bars = 4
	(r["bars"] as _Bars).n = bars
	(r["bars"] as _Bars).queue_redraw()
	(r["ms"] as Label).text = ("%d ms" % int(p["ms"])) if online and int(p["ms"]) >= 0 else ""
	var can: bool = online and st == "idle" and Net.session == null and Net.challenge_out.is_empty() \
			and str(p["version"]) == str(ProjectSettings.get_setting("application/config/version", ""))
	(r["button"] as Button).disabled = not can


static func _ago(unix: int) -> String:
	var d := int(Time.get_unix_time_from_system()) - unix
	if d < 3600:
		return Loc.t("%d min ago") % maxi(1, d / 60)
	if d < 86400:
		return Loc.t("%d h ago") % (d / 3600)
	return Loc.t("%d days ago") % (d / 86400)


## Connection bars: four, filled by how quick the line is.
class _Bars:
	extends Control
	var n := 0

	func _draw() -> void:
		for i in 4:
			var h := 8.0 + i * 8.0
			var r := Rect2(i * 13.0, size.y - h, 9.0, h)
			draw_rect(r, Color("2de2e6") if i < n else Color(1, 1, 1, 0.14))


# ------------------------------------------------------------------ challenges

func _modal_box(title: String, col: Color, width := 640.0) -> VBoxContainer:
	_close_modal()
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.06, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_modal = dim
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.11, 0.98), 22, Color(col, 0.7)))
	p.custom_minimum_size = Vector2(width, 0)
	c.add_child(p)
	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 28)
	p.add_child(mm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	mm.add_child(v)
	v.add_child(UITheme.label(title, 34, col, UITheme.title_font()))
	p.scale = Vector2(0.94, 0.94)
	p.pivot_offset = Vector2(width / 2.0, 160)
	dim.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(dim, "modulate:a", 1.0, 0.15)
	tw.tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return v


func _close_modal() -> void:
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null


func _challenge_dialog(id: String) -> void:
	var p := Net.person(id)
	var decks := Net.decks()
	var v := _modal_box(Loc.t("CHALLENGE %s") % str(p.get("name", "")).to_upper(), TEAL)
	if decks.is_empty():
		var l := UITheme.label("You have no complete deck yet. A deck can be taken online when it has 40 to 60 cards and you own every card in it.", 18, UITheme.TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		_btn(v, "OK", _close_modal, Color.WHITE)
		return
	v.add_child(UITheme.label("Your deck", 16, UITheme.TEXT_DIM))
	var dp := OptionButton.new()
	dp.custom_minimum_size = Vector2(0, 46)
	for d in decks:
		dp.add_item(str(d[1]))
	v.add_child(dp)
	v.add_child(UITheme.label("How many duels", 16, UITheme.TEXT_DIM))
	var mode := OptionButton.new()
	mode.custom_minimum_size = Vector2(0, 46)
	mode.add_item(Loc.t("One duel"))
	mode.add_item(Loc.t("Match of 3 (Side Deck between duels)"))
	v.add_child(mode)
	var fl := CheckButton.new()
	fl.text = "Forbidden/Limited list"
	fl.button_pressed = true
	v.add_child(fl)
	var de := CheckButton.new()
	de.text = "Destiny Draw"
	de.button_pressed = Settings.destiny_draw
	v.add_child(de)
	var lpb := OptionButton.new()
	for x in [8000, 4000, 16000]:
		lpb.add_item(Loc.t("%d Life Points") % x)
	v.add_child(lpb)
	var note := UITheme.label("No prizes online: each duel goes on your record against them.", 14, UITheme.TEXT_DIM)
	v.add_child(note)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var go := _btn(row, "Send challenge", func():
		var opts := {"deck": str(decks[dp.selected][0]), "mode": "match" if mode.selected == 1 else "single", "fl": fl.button_pressed,
			"lp": [8000, 4000, 16000][lpb.selected], "destiny": de.button_pressed}
		var bad := Net.deck_problem(Net.deck_lists(opts["deck"]), opts["fl"])
		if bad != "":
			note.text = bad
			note.add_theme_color_override("font_color", UITheme.DANGER)
			return
		if Net.challenge(id, opts):
			_waiting(id)
		else:
			note.text = Loc.t("%s can't be reached right now.") % str(p.get("name", ""))
			note.add_theme_color_override("font_color", UITheme.DANGER), TEAL)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(row, "Cancel", _close_modal, Color.WHITE)
	go.grab_focus()


func _waiting(id: String) -> void:
	var p := Net.person(id)
	var v := _modal_box(Loc.t("WAITING FOR %s") % str(p.get("name", "")).to_upper(), TEAL, 560)
	var l := UITheme.label("Your challenge is on their screen. They accept or decline.", 18, UITheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	_wait_card = v
	_wait_cid = str(Net.challenge_out.get("cid", ""))
	_btn(v, "Cancel the challenge", func():
		Net.cancel_challenge()
		_close_modal(), Color.WHITE)


func _on_answered(a: Dictionary) -> void:
	if _wait_card == null or not is_instance_valid(_wait_card) or a.get("cancelled", false):
		return
	if str(a.get("cid", "")) != "" and str(a.get("cid", "")) != _wait_cid:
		return
	var name := str(Net.person(str(a.get("from", ""))).get("name", ""))
	var v := _modal_box(Loc.t("NOT THIS TIME"), UITheme.GOLD, 560)
	var why := Loc.t("%s declined.") % name
	if str(a.get("why", "")) == "busy":
		why = Loc.t("%s is busy right now.") % name
	elif str(a.get("why", "")) == "away":
		why = Loc.t("%s is playing something else right now.") % name
	elif str(a.get("why", "")) == "time":
		why = Loc.t("%s didn't answer in time.") % name
	elif a.get("gone", false):
		why = Loc.t("The line to %s dropped.") % name
	v.add_child(UITheme.label(why, 19, UITheme.TEXT))
	_btn(v, "OK", _close_modal, Color.WHITE)


# ------------------------------------------------------------------ groups, help, owner tools

func _groups_menu() -> void:
	var v := _modal_box("DUEL GROUPS", TEAL, 620)
	for g in Net.groups:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		v.add_child(row)
		var dot := ColorRect.new()
		dot.color = GROUP_COLORS[clampi(int(g.get("color", 0)), 0, GROUP_COLORS.size() - 1)]
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var nl := UITheme.label(str(g["name"]) + ("  (" + Loc.t("owner") + ")" if bool(g.get("owner", false)) else ""), 20, Color.WHITE if str(g["gid"]) == Net.current else UITheme.TEXT_DIM)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		var gid := str(g["gid"])
		if gid != Net.current:
			var use := Button.new()
			use.text = "Use"
			use.pressed.connect(func():
				Net.use_group(gid)
				_close_modal()
				_refresh(true))
			row.add_child(use)
		var lv := Button.new()
		lv.text = "Leave"
		lv.pressed.connect(func(): _confirm_leave(gid, str(g["name"])))
		row.add_child(lv)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	v.add_child(row2)
	_btn(row2, "Join another group", _join_dialog, TEAL)
	_btn(row2, "Make a group", func(): _open_wizard("make"), UITheme.GOLD)
	_btn(v, "Close", _close_modal, Color.WHITE)


func _confirm_leave(gid: String, name: String) -> void:
	var v := _modal_box(Loc.t("LEAVE %s?") % name.to_upper(), UITheme.DANGER, 560)
	var l := UITheme.label("You can come back any time with an invite code. Your record against its members stays.", 17, UITheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_btn(row, "Leave the group", func():
		Net.leave_group(gid)
		_close_modal()
		_refresh(true), UITheme.DANGER)
	_btn(row, "Stay", _close_modal, Color.WHITE)


func _join_dialog() -> void:
	var v := _modal_box("JOIN A GROUP", TEAL, 620)
	var code := LineEdit.new()
	code.placeholder_text = Loc.t("Paste the invite code (XR1-...)")
	code.custom_minimum_size = Vector2(0, 50)
	v.add_child(code)
	var msg := UITheme.label("", 16, UITheme.DANGER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_btn(row, "Join", func():
		var err := Net.join(code.text)
		msg.text = err
		if err == "":
			_close_modal()
			_refresh(true), TEAL)
	_btn(row, "Cancel", _close_modal, Color.WHITE)
	code.grab_focus()


func _rename() -> void:
	var g := Net.group()
	var v := _modal_box("NAME AND COLOR", UITheme.GOLD, 620)
	var nm := LineEdit.new()
	nm.text = str(g.get("name", ""))
	nm.max_length = 28
	nm.custom_minimum_size = Vector2(0, 50)
	v.add_child(nm)
	var pick := [int(g.get("color", 0))]
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 8)
	v.add_child(crow)
	for i in GROUP_COLORS.size():
		var cb := Button.new()
		cb.custom_minimum_size = Vector2(46, 46)
		cb.add_theme_stylebox_override("normal", UITheme.button_box(GROUP_COLORS[i], Color.WHITE if i == pick[0] else Color(0, 0, 0, 0)))
		cb.pressed.connect(func():
			pick[0] = i
			for k in crow.get_child_count():
				(crow.get_child(k) as Button).add_theme_stylebox_override("normal", UITheme.button_box(GROUP_COLORS[k], Color.WHITE if k == i else Color(0, 0, 0, 0))))
		crow.add_child(cb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_btn(row, "Save", func():
		if nm.text.strip_edges() != "":
			Net.rename_group(nm.text, pick[0])
		_close_modal()
		_refresh(true), UITheme.GOLD)
	_btn(row, "Cancel", _close_modal, Color.WHITE)


func _remove_someone() -> void:
	var v := _modal_box("REMOVE SOMEONE", UITheme.GOLD, 680)
	var l := UITheme.label("Two steps on Tailscale's site, signed in with the group's account:\n\n1  Make a new invite code here first (Owner tools), so the old code stops working.\n2  On the Machines page, find their copy (its name starts with xroads- and their duelist's name), press ⋯ and Remove.\n\nEveryone else's game takes the new key by itself the next time they are online with you.", 17, UITheme.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_btn(row, "Open the Machines page", func(): OS.shell_open("https://login.tailscale.com/admin/machines"), UITheme.GOLD)
	_btn(row, "Close", _close_modal, Color.WHITE)


func _show_qr() -> void:
	var v := _modal_box("INVITE CODE", UITheme.GOLD, 620)
	var l := UITheme.label("Scan it with a phone to send the code on from there.", 16, UITheme.TEXT_DIM)
	v.add_child(l)
	var img := QrCode.image(Net.invite_code(), 8)
	if img != null:
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(420, 420)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(tr)
	var code := UITheme.label(Net.invite_code(), 12, UITheme.TEXT_DIM)
	code.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	v.add_child(code)
	_btn(v, "Close", _close_modal, Color.WHITE)


func _open_wizard(mode: String) -> void:
	_close_modal()
	var w := OnlineWizard.new()
	w.mode = mode
	w.z_index = 5
	add_child(w)
	w.done.connect(func():
		_refresh(true))


func _help() -> void:
	var v := _modal_box("HELP", TEAL, 900)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 560)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 10)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(tv)
	for part in [
		["JOINING", "Someone in a group sends you its invite code. Under Online, paste it in Join a group. That's all: the group and its people show up a few seconds later."],
		["MAKING A GROUP", "1  Make a free Tailscale account just for the game (use a new Google or GitHub account, or an email you don't use for anything else).\n2  On its keys page (Settings > Keys > Generate auth key): Reusable on, Expiration 90 days, then Generate. Copy the key (it starts with tskey-auth-).\n3  Paste it in the game. The game checks it and says when your group is ready.\n4  Name your group and pick its color.\n5  Copy the invite code and send it to the people you want to duel."],
		["DUELING", "In the lobby, press Challenge next to someone who is online. Pick your deck, one duel or a Match of 3. They get a card on their screen with Accept or Decline. The game picks who hosts the duel (the easier connection) and says so. Each of you keeps your own replay and your record against the other. There are no prizes online."],
		["IT DOESN'T CONNECT", "•  Windows asks whether Crossroads Link may use the network: say Allow (Private networks is enough). If you said no, Windows Security > Firewall > Allow an app, and tick Crossroads Link.\n•  Both of you need the same version of the game. The lobby says when one of you has another.\n•  \"The group's key was not accepted\": the owner's key ran out. The owner makes a new one (Owner tools > New invite code); everyone else's game takes it the next time they are online with the owner, or pastes the new invite code.\n•  A slow line is fine: a duel sends very little. When the line drops, the duel waits and goes on where it was when it comes back.\n•  Still nothing? Close the game on both computers and open it again."],
		["SAFE FOR THE OWNER", "The group uses a Tailscale account made only for the game, separate from your other accounts. Only people with the invite code can join, and the game only uses it for duels. Crossroads Link closes when the game does."]]:
		tv.add_child(UITheme.label(str(part[0]), 20, UITheme.GOLD, UITheme.semi_font()))
		var t := UITheme.label(str(part[1]), 17, UITheme.TEXT)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(t)
	_btn(v, "Close", _close_modal, Color.WHITE)
