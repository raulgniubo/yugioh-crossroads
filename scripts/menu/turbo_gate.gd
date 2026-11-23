class_name TurboGate
extends Control
## The door to the highway (0.69.1), in the look of the Academy's and the main story's: the ring at
## dusk behind it, the road's name down the left, your Duel Runner turning on its stand with what
## the garage did to it, how far you have come on this road, and a big "Ride the highway". Under it:
## the race events, the five riders who duel at speed, the Highway Grand Prix and the garage. Every
## one of them opens the ride where that thing happens (the start line, beside a rider, the garage),
## so nothing that the ring offers is lost: it is all still out on the road as well.

signal closed

const PICTURE := "res://assets/ui/turbo_title.jpg"
const RIDE_SCRIPT := "res://scripts/turbo/turbo_ride.gd"
const ORANGE := Color("ff8a3a")
const TEAL := Color("2de2e6")
## The ring as a strip, stretch by stretch: [from, to, color]. (TurboRide.ZONES, colored.)
const ZONE_COLORS := {"satellite": Color("c98b4a"), "tunnel": Color("6a7a96"), "bridge": Color("2de2e6"), "tops": Color("b07cff")}

var _box: VBoxContainer          # a page in the middle of the screen (races, riders, Grand Prix)
var _left: VBoxContainer         # the title page, down the left side over the picture
var _mid: CenterContainer
var _back: AcademyBackdrop
var _scroll: ScrollContainer
var _stand: Node3D               # your runner on its turntable
var _ride: GDScript
var _faces_wait: Array = []      # [TextureRect, key]: rider portraits waiting for their model
var _save := {}                  # what the highway kept: beaten, chips, best, wins, medals...


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_ride = load(RIDE_SCRIPT)
	_read_save()
	_back = AcademyBackdrop.new(0.0, PICTURE if ResourceLoader.exists(PICTURE) else AcademyBackdrop.PICTURE, Color(0.6, 0.95, 1.0))
	add_child(_back)
	var lm := MarginContainer.new()
	lm.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	lm.add_theme_constant_override("margin_left", 96)
	lm.add_theme_constant_override("margin_top", 56)
	lm.add_theme_constant_override("margin_bottom", 40)
	add_child(lm)
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 12)
	_left.custom_minimum_size = Vector2(820, 0)
	_left.alignment = BoxContainer.ALIGNMENT_CENTER
	lm.add_child(_left)
	_mid = CenterContainer.new()
	_mid.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mid)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mid.add_child(_scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	_box.custom_minimum_size = Vector2(1180, 0)
	_scroll.add_child(_box)
	_home()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


## What the highway has kept in its own save file (the ride writes it; this screen only reads).
func _read_save() -> void:
	var cfg := ConfigFile.new()
	_save = {}
	if cfg.load("user://turbo.cfg") == OK:
		for k in ["beaten", "medals", "events_best"]:
			_save[k] = cfg.get_value("turbo", k, {})
		for k in ["chips", "wins"]:
			_save[k] = int(cfg.get_value("turbo", k, 0))
		for k in ["best", "trial_best"]:
			_save[k] = float(cfg.get_value("turbo", k, 0.0))
	for k in ["beaten", "medals", "events_best"]:
		if not _save.has(k):
			_save[k] = {}
	TurboGarage.load_data()


func _beaten() -> Dictionary:
	return _save.get("beaten", {})


static func clock(t: float) -> String:
	if t <= 0.0:
		return "--"
	return "%d:%05.2f" % [int(t) / 60, fmod(t, 60.0)]


func _process(_delta: float) -> void:
	# One rider's portrait a frame, once its model has been read.
	for i in _faces_wait.size():
		var fw: Array = _faces_wait[i]
		if not is_instance_valid(fw[0]):
			_faces_wait.remove_at(i)
			break
		if Avatars.ready_now(str(fw[1])) or Portraits.holds(str(fw[1])):
			var ft = Portraits.get_portrait(str(fw[1]))
			if ft is Texture2D:
				(fw[0] as TextureRect).texture = ft
			_faces_wait.remove_at(i)
			break
		Avatars.warm(str(fw[1]))
	# The middle page never runs past the screen: it scrolls when it is taller than the view.
	var room := get_viewport_rect().size.y - 80.0
	var want := _box.get_combined_minimum_size().y
	_scroll.custom_minimum_size = Vector2(_box.custom_minimum_size.x, minf(want, room))
	# (The runner stands still at a three-quarter view; drag it with the mouse to turn it.)


func _clear() -> void:
	for n in _box.get_children():
		n.queue_free()
	for n in _left.get_children():
		n.queue_free()
	_stand = null


## The ring as one bar: each stretch in its color and as long as it is on the road.
func _ring_bar() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var zones: Array = _ride.ZONES
	var lap: float = _ride.LAP
	for z in zones:
		var seg := ColorRect.new()
		var col: Color = ZONE_COLORS.get(str(z[2]), TEAL)
		seg.color = col
		seg.custom_minimum_size = Vector2(maxf(18.0, 640.0 * (float(z[1]) - float(z[0])) / lap), 6)
		seg.tooltip_text = Loc.t(str(z[3]))
		seg.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(seg)
	return h


## A glass button for the row under the big one (as on the Academy's and the story's doors).
func _glass(text: String, col: Color, act: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 22)
	b.clip_text = true
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.72), 14, Color(1, 1, 1, 0.22)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.9), 14, col.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.1, 0.14, 0.26, 0.95), 14, col.lightened(0.4)))
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		act.call())
	return b


## Your Duel Runner on a turntable, wearing what the garage gave it, with you on it.
func _runner_view(parent: Control, w: int, h: int) -> Control:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(w, h)
	svc.mouse_filter = Control.MOUSE_FILTER_STOP
	svc.mouse_default_cursor_shape = Control.CURSOR_DRAG
	svc.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseMotion and ((ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and _stand and is_instance_valid(_stand):
			_stand.rotation.y += (ev as InputEventMouseMotion).relative.x * 0.01
			svc.accept_event())
	parent.add_child(svc)            # (in the tree first: the camera and the rider need it)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.size = Vector2i(w, h)
	svc.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.62, 0.8)
	e.ambient_light_energy = 0.8
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 35, 0)
	key.light_energy = 1.3
	vp.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2.2, 1.6, -2.4)
	rim.light_color = TEAL
	rim.light_energy = 2.2
	rim.omni_range = 6.0
	vp.add_child(rim)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.15, 3.3)
	cam.fov = 36.0
	vp.add_child(cam)
	cam.look_at(Vector3(0, 0.62, 0), Vector3.UP)
	_stand = Node3D.new()
	vp.add_child(_stand)
	_stand.rotation.y = -0.6
	var paint := TurboGarage.paint(Profile.color())
	var frame := TurboGarage.frame()
	var runners: Array = TurboTrack.RUNNERS
	var own := CityBuilder.own_instance(["runner_a", "runner_b"][frame % 2])
	var ps = load(runners[frame % runners.size()])
	var holder := Node3D.new()
	_stand.add_child(holder)
	if own != null or ps is PackedScene:
		var bike: Node3D = own if own != null else ps.instantiate()
		holder.add_child(bike)
		var box := _aabb(bike, Transform3D())
		var s := 2.55 / maxf(0.01, maxf(box.size.x, box.size.z))
		bike.scale = Vector3.ONE * s
		bike.rotation.y = PI if box.size.x >= box.size.z else PI / 2.0
		bike.position = Vector3(box.get_center().x * s, -box.position.y * s, box.get_center().z * s)
		var coat := StandardMaterial3D.new()
		coat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		coat.albedo_color = Color(paint, 0.34)
		coat.metallic = 0.6
		coat.roughness = 0.35
		for mi in bike.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = coat
		var mark := TurboGarage.mark()
		if mark != "":
			for sz: float in [-1.0, 1.0]:
				var ml := Label3D.new()
				ml.text = mark
				ml.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf") if mark.is_valid_int() else null
				ml.font_size = 96
				ml.pixel_size = 0.0042
				ml.outline_size = 14
				ml.outline_modulate = Color(0.04, 0.05, 0.08)
				ml.shaded = false
				var half: float = box.size.z * s * 0.5 + 0.02 if box.size.x >= box.size.z else box.size.x * s * 0.5 + 0.02
				ml.position = Vector3(0.62 if frame == 0 else 0.22, 0.72 if frame == 0 else 0.8, sz * half)
				ml.rotation.y = 0.0 if sz > 0.0 else PI
				holder.add_child(ml)
	var fig := RoamFigure.new()
	fig.rotation.y = PI / 2.0
	fig.position = Vector3(-0.2, 0.0, 0.0)
	fig.scale = Vector3.ONE * 1.08
	holder.add_child(fig)
	fig.setup("player", paint, "", false)
	fig.ride_pose.call_deferred()
	# A ring of light on the floor under the stand, in the color of its trail.
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.65
	cm.bottom_radius = 1.65
	cm.height = 0.02
	disc.mesh = cm
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(TurboGarage.trail(paint), 0.22)
	disc.material_override = dm
	_stand.add_child(disc)
	return svc


static func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t: Transform3D = xf * (n as Node3D).transform if n is Node3D else xf
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var b: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		out = b
		first = false
	for c in n.get_children():
		var cb := _aabb(c, t)
		if cb.size != Vector3.ZERO:
			out = cb if first else out.merge(cb)
			first = false
	return out


func _home() -> void:
	_clear()
	_back.shade_to(0.0)
	var beaten := _beaten()
	var rivals: Array = _ride.RIVALS
	_left.add_child(UITheme.label(Loc.t("TURBO DUELS") + "   ·   " + Loc.t("NEW DOMINO"), 19, UITheme.GOLD, UITheme.semi_font()))
	var t := UITheme.label(Loc.t("THE HIGHWAY").to_upper(), 104, Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 5)
	t.add_theme_constant_override("shadow_outline_size", 10)
	_left.add_child(t)
	_left.add_child(_ring_bar())
	var sub := UITheme.label(Loc.t("One loop from Satellite to the Tops. Race the riders, take them on in a Turbo Duel, and ride well before you ask: how you ride up to them is how the duel opens."), 22, Color(0.9, 0.95, 1.0, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(800, 0)
	_left.add_child(sub)
	var gap0 := Control.new()
	gap0.custom_minimum_size = Vector2(0, 8)
	_left.add_child(gap0)
	# Your runner, and how far you have come on this road.
	var paint := TurboGarage.paint(Profile.color())
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.12, 0.84), 20, Color(TEAL, 0.7)))
	card.custom_minimum_size = Vector2(820, 0)
	_left.add_child(card)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12)
	card.add_child(m)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	m.add_child(row)
	_runner_view(row, 300, 190)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(v)
	v.add_child(UITheme.label(Loc.t("YOUR DUEL RUNNER"), 34, TEAL.lightened(0.35), UITheme.title_font()))
	var frame_name := Loc.t(str(TurboGarage.FRAMES[TurboGarage.frame()]))
	var paint_name := Loc.t(str(TurboGarage.PAINTS[clampi(int(TurboGarage.val("paint", 0)), 0, TurboGarage.PAINTS.size() - 1)][0]))
	var look := UITheme.label("%s   ·   %s" % [frame_name, paint_name], 21, Color.WHITE, UITheme.semi_font())
	look.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(look)
	# The four parts as small level pips.
	var parts := HBoxContainer.new()
	parts.add_theme_constant_override("separation", 14)
	for pk in TurboGarage.PART_ORDER:
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", 2)
		pv.tooltip_text = "%s: %s" % [Loc.t(str(TurboGarage.PARTS[pk]["what"])), TurboGarage.gives(pk, TurboGarage.level(pk))]
		pv.mouse_filter = Control.MOUSE_FILTER_PASS
		pv.add_child(UITheme.label(Loc.t(str(TurboGarage.PARTS[pk]["name"])), 15, UITheme.TEXT_DIM, UITheme.semi_font()))
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 3)
		for k in TurboGarage.COST.size():
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(22, 6)
			pip.color = paint if k < TurboGarage.level(pk) else Color(1, 1, 1, 0.16)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
		pv.add_child(pips)
		parts.add_child(pv)
	v.add_child(parts)
	var facts := Loc.t("Riders beaten %d / %d") % [beaten.size(), rivals.size()]
	facts += "   ·   " + Loc.t("Races won %d") % int(_save.get("wins", 0))
	facts += "   ·   " + Loc.t("Best lap %s") % clock(float(_save.get("best", 0.0)))
	var fl := UITheme.label(facts, 17, UITheme.TEXT_DIM)
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(fl)
	var first := Button.new()
	first.text = "▶   " + Loc.t("Ride the highway")
	first.custom_minimum_size = Vector2(820, 92)
	first.add_theme_font_size_override("font_size", 38)
	first.clip_text = true
	UITheme.paint_button(first, ORANGE.darkened(0.2))
	first.pressed.connect(func():
		Sfx.play("gong", -6.0)
		_go(""))
	_left.add_child(first)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	row2.custom_minimum_size = Vector2(820, 0)
	_left.add_child(row2)
	row2.add_child(_glass(Loc.t("Races"), TEAL, _races))
	row2.add_child(_glass(Loc.t("Rivals"), TEAL, _riders))
	row2.add_child(_glass(Loc.t("Grand Prix"), ORANGE, _grand_prix))
	row2.add_child(_glass(Loc.t("Garage"), TEAL, func(): _go("garage")))
	row2.add_child(_glass(Loc.t("Back"), TEAL, _close))
	# The one thing to do next, in a line.
	var hint := UITheme.label(_next_hint(), 18, UITheme.GOLD)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(800, 0)
	_left.add_child(hint)
	first.grab_focus.call_deferred()
	var k := 0
	for n in _left.get_children():
		var c := n as Control
		c.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.05 * k)
		tw.tween_property(c, "modulate:a", 1.0, 0.25)
		k += 1


## What to go for next on this road, in one line.
func _next_hint() -> String:
	var beaten := _beaten()
	var gp := Tournament.st("turbo")
	if str(gp.get("stage", "")) == "finals":
		return Loc.t("You are in the Highway Grand Prix: your next round is waiting at the start line.")
	if beaten.size() < 2:
		return Loc.t("Win 2 Turbo Duels on this road to enter the Highway Grand Prix (%d of 2).") % beaten.size()
	for r in _ride.RIVALS:
		if not beaten.has(str(r["key"])):
			return Loc.t("Next rider to beat: %s.") % str(Characters.get_char(str(r["key"])).get("name", r["key"]))
	return Loc.t("Every rider on the ring has lost to you. The Grand Prix and the clock are still out there.")


## Into the ride: `what` is "" (just ride), "race:<event>", "gp", "garage" or "rider:<key>".
func _go(what: String) -> void:
	Router.roam["ride_go"] = what
	Router.roam.erase("ride_s")
	Router.roam["ride_from"] = ""
	Router.roam["ride_gate"] = true
	closed.emit()
	Router.go(Router.RIDE)


func _page_title(text: String, sub: String) -> void:
	var t := UITheme.label(Loc.t(text).to_upper(), 72, Color.WHITE, UITheme.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	if sub != "":
		var s := UITheme.label(Loc.t(sub), 22, UITheme.TEXT_DIM)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(s)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	_box.add_child(gap)


## A wide glass tile with a colored edge: a mark on the left, words in the middle, an action on the right.
func _tile(col: Color, mark: Control, title: String, lines: Array, act_text: String, act: Callable, locked := false, act_below := false) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(580, 150)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = locked
	b.add_theme_stylebox_override("normal", UITheme.panel_box(Color(0.04, 0.06, 0.13, 0.9), 18, Color(col, 0.6)))
	for st in ["hover", "focus"]:
		b.add_theme_stylebox_override(st, UITheme.panel_box(Color(0.07, 0.1, 0.2, 0.96), 18, col))
	b.add_theme_stylebox_override("pressed", UITheme.panel_box(Color(0.09, 0.13, 0.25, 0.96), 18, col.lightened(0.3)))
	b.add_theme_stylebox_override("disabled", UITheme.panel_box(Color(0.03, 0.04, 0.08, 0.8), 18, Color(1, 1, 1, 0.08)))
	b.pressed.connect(func():
		Sfx.play("gong", -8.0)
		act.call())
	var mm := MarginContainer.new()
	mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		mm.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 12)
	b.add_child(mm)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm.add_child(h)
	if mark:
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(mark)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var tl := UITheme.label(title, 28, Color(1, 1, 1, 0.45) if locked else Color.WHITE, UITheme.title_font())
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tl)
	var last: Label = null
	for ln in lines:
		var l := UITheme.label(str(ln[0]), int(ln[1]), ln[2] if not locked else Color(ln[2], 0.5))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(320, 0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		last = l
	if act_text != "":
		var a := UITheme.label(act_text, 19, col.lightened(0.3) if not locked else Color(1, 1, 1, 0.35), UITheme.semi_font())
		a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if act_below and last != null:
			# The last line (beaten or not) and the action share one row along the bottom.
			var bot := HBoxContainer.new()
			bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.remove_child(last)
			last.autowrap_mode = TextServer.AUTOWRAP_OFF
			last.custom_minimum_size = Vector2.ZERO
			last.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bot.add_child(last)
			bot.add_child(a)
			v.add_child(bot)
		else:
			h.add_child(a)
	# The tile is as tall as what is in it (a button does not grow with its children by itself).
	mm.minimum_size_changed.connect(func(): b.custom_minimum_size.y = maxf(150.0, mm.get_combined_minimum_size().y))
	return b


## A big round-cornered mark with a word or sign in it (the event's or the medal's).
func _sign(text: String, col: Color, size := 86.0) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(size, size)
	p.add_theme_stylebox_override("panel", UITheme.panel_box(Color(col.darkened(0.6), 0.9), int(size / 4.0), col))
	var l := UITheme.label(text, int(size * 0.42), col.lightened(0.4), UITheme.title_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _two_columns() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 16)
	_box.add_child(g)
	return g


func _back_row() -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	_box.add_child(gap)
	var c := CenterContainer.new()
	_box.add_child(c)
	var b := _glass(Loc.t("Back"), TEAL, _home)
	b.custom_minimum_size = Vector2(360, 64)
	c.add_child(b)


func _page() -> void:
	_clear()
	_back.shade_to(0.72)


## The four events at the start line: what each is, what first place pays, your best.
func _races() -> void:
	_page()
	_page_title("Race events", "They start at the line on the ring. First place pays Duel Points; the time trial pays a medal once each.")
	var events: Dictionary = _ride.EVENTS
	var order: Array = _ride.EVENT_ORDER
	var marks := {"circuit": "◎", "sprint": "»", "elim": "✕", "trial": "◷"}
	var cols := {"circuit": TEAL, "sprint": ORANGE, "elim": Color("ff5a6a"), "trial": Color("ffd23a")}
	var best: Dictionary = _save.get("events_best", {})
	var medals: Dictionary = _save.get("medals", {})
	var g := _two_columns()
	var first: Button = null
	for id in order:
		var ev: Dictionary = events[id]
		var col: Color = cols.get(id, TEAL)
		var lines: Array = [[Loc.t(str(ev["what"])), 18, UITheme.TEXT_DIM]]
		if id == "trial":
			var have: Array = []
			for md in _ride.MEDALS:
				have.append("%s %s%s" % [Loc.t(str(md[0]).capitalize()), clock(float(md[1])), " ✓" if medals.has(md[0]) else ""])
			lines.append(["   ·   ".join(have), 16, UITheme.GOLD])
			if float(_save.get("trial_best", 0.0)) > 0.0:
				lines.append([Loc.t("Your best: %s") % clock(float(_save["trial_best"])), 16, Color.WHITE])
		else:
			var prize: Array = ev["prize"]
			lines.append([Loc.t("First place pays %d Duel Points.") % int(prize[0]), 16, UITheme.GOLD])
			if best.has(id):
				lines.append([Loc.t("Your best finish: place %d.") % int(best[id]), 16, Color.WHITE])
		var b := _tile(col, _sign(str(marks.get(id, "•")), col), Loc.t(str(ev["name"])), lines, Loc.t("Race it") + "  ▶", func(): _go("race:" + str(id)))
		g.add_child(b)
		if first == null:
			first = b
	_back_row()
	if first:
		first.grab_focus.call_deferred()


## The five riders who duel at speed: who they are, how hard, beaten or not, and a way to them.
func _riders() -> void:
	_page()
	_page_title("Rivals of the ring", "Ride up beside one and press E for a Turbo Duel. Ride well first: your Momentum becomes your Speed Counters.")
	var beaten := _beaten()
	var g := _two_columns()
	var first: Button = null
	for r in _ride.RIVALS:
		var key := str(r["key"])
		var ch: Dictionary = Characters.get_char(key)
		var col: Color = ch.get("color", TEAL)
		var face := TextureRect.new()
		face.custom_minimum_size = Vector2(96, 96)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if Avatars.ready_now(key) or Portraits.holds(key):
			var tex = Portraits.get_portrait(key)
			if tex is Texture2D:
				face.texture = tex
		else:
			_faces_wait.append([face, key])      # (filled in once the model is read on a worker thread)
			Avatars.warm(key)
		var stars := "★".repeat(int(r["difficulty"])) + "☆".repeat(maxi(0, 3 - int(r["difficulty"])))
		var lines: Array = [["%s   ·   %s" % [Loc.t(str(ch.get("title", ""))), stars], 17, col.lightened(0.35)],
			["“%s”" % Loc.t(str(r["line"])), 17, UITheme.TEXT_DIM]]
		lines.append([Loc.t("You beat them") + "  ✓" if beaten.has(key) else Loc.t("Not beaten yet"), 16, Color("5affa0") if beaten.has(key) else UITheme.GOLD])
		# (The square portrait inside the rounded card gets rounded corners of its own.)
		var b := _tile(col, UiPictures.rounded(face, 14), str(ch.get("name", key)), lines, Loc.t("Ride to them") + "  ▶", func(): _go("rider:" + key), false, true)
		g.add_child(b)
		if first == null:
			first = b
	_back_row()
	if first:
		first.grab_focus.call_deferred()


## The Highway Grand Prix: what it is, whether you may enter, and where you stand in it.
func _grand_prix() -> void:
	_page()
	var defs: Dictionary = Tournament.DEFS["turbo"]
	_page_title(str(defs["name"]), str(defs["blurb"]))
	var beaten := _beaten()
	var s := Tournament.st("turbo")
	var inside := str(s.get("stage", "")) == "finals"
	var open := inside or beaten.size() >= 2
	var lines: Array = []
	if inside:
		var nxt: Dictionary = Tournament.my_match("turbo")
		lines.append([Loc.t("You are in it. Next: %s.") % str(nxt.get("name", "?")), 20, Color.WHITE])
	elif open:
		lines.append([Loc.t("You may enter: you have won %d Turbo Duels on this road.") % beaten.size(), 20, Color.WHITE])
	else:
		lines.append([Loc.t("The Grand Prix is for riders who have won 2 Turbo Duels on this road. You have %d.") % beaten.size(), 20, UITheme.GOLD])
	lines.append([Loc.t("The winner takes %d Duel Points.") % int(defs.get("prize_dp", 0)), 18, UITheme.GOLD])
	var c := CenterContainer.new()
	_box.add_child(c)
	var b := _tile(ORANGE, _sign("GP", ORANGE, 104.0), Loc.t("Highway Grand Prix"), lines,
		(Loc.t("Your next round") if inside else Loc.t("Enter")) + "  ▶" if open else Loc.t("Locked"), func(): _go("gp"), not open)
	b.custom_minimum_size = Vector2(900, 190)
	c.add_child(b)
	_back_row()
	if open:
		b.grab_focus.call_deferred()
	else:
		for n in _box.find_children("*", "Button", true, false):
			if not (n as Button).disabled:
				(n as Button).grab_focus.call_deferred()
				break


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _left.get_child_count() == 0:
			_home()
		else:
			_close()
