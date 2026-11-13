class_name TourneyWorld
extends Node3D
## The tournament as you meet it in the world: the registration desk, the badge counter on
## screen, the crowd and lights that gather for the finals, and what happens when you come back
## from a duel.

var scene: Node
var life: Node
var district := ""
var _chip: PanelContainer
var _chip_l: Label
var _crowds := {}        # tournament id -> Node3D (shown during the finals)


func setup(roam: Node, world: Node) -> void:
	scene = roam
	life = world
	district = str(Router.roam.get("district", "domino"))
	if str(Router.roam.get("story", "")) != "":
		return
	Tournament.load_data()
	for id in Tournament.in_district(district):
		_build_desk(id)
	_build_chip()
	_refresh()
	# Back from a finals duel: settle the round and show the bracket.
	var back := str(Router.roam.get("tourney", ""))
	if back != "" and Router.story_result != "":
		var won := Router.story_result == "won"
		Router.story_result = ""
		Router.roam["tourney"] = ""
		var res := Tournament.resolve(back, won)
		print("TOURNEY back won=", won, " stage=", Tournament.st(back)["stage"], " round=", Tournament.st(back)["round"], " next=", Tournament.my_match(back).get("name", "-"))
		if "--tourney=play" in OS.get_cmdline_user_args():
			get_tree().quit()
			return
		_refresh()
		_show_bracket.call_deferred(back, res)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tourney="):
			# Dev: jump to a stage. qualify | finals | won | lose | bracket
			var what := a.trim_prefix("--tourney=")
			var tid: String = Tournament.in_district(district)[0]
			for a2 in OS.get_cmdline_user_args():
				if a2.begins_with("--tourney-id="):
					tid = a2.trim_prefix("--tourney-id=")
			if what == "play":
				Tournament.register(tid)
				Tournament.start_finals(tid)
				Router.roam["tourney"] = tid
				Router.roam["last_duel"] = ""
				Router.duel_config = Tournament.duel_config(tid)
				get_tree().create_timer(1.5).timeout.connect(func(): Router.go(Router.DUEL))
				return
			Tournament.register(tid)
			if what != "qualify":
				Tournament.start_finals(tid)
			var res2 := {}
			if what == "won":
				for k in 3:
					res2 = Tournament.resolve(tid, true)
			elif what == "lose":
				Tournament.resolve(tid, true)
				res2 = Tournament.resolve(tid, false)
			print("TOURNEY ", what, " stage=", Tournament.st(tid)["stage"], " rounds=", (Tournament.st(tid)["rounds"] as Array).size(), " next=", Tournament.my_match(tid).get("name", "-"), " res=", res2)
			_refresh()
			if what != "qualify":
				get_tree().create_timer(1.5).timeout.connect(func(): _show_bracket(tid, res2))


func _build_desk(id: String) -> void:
	var d: Dictionary = Tournament.DEFS[id]
	var at: Vector3 = d["desk"]
	var col: Color = d["color"]
	var root := Node3D.new()
	root.position = at
	root.rotation.y = float(d["desk_yaw"])
	add_child(root)
	var cloth: StandardMaterial3D = life._m(col.darkened(0.35), 0.8)
	var white: StandardMaterial3D = life._m(Color(0.95, 0.95, 0.96), 0.6)
	var dark: StandardMaterial3D = life._m(Color(0.1, 0.11, 0.15), 0.6, 0.3)
	# A draped table, a bracket board behind it and two banners.
	life._box(Vector3(2.6, 0.9, 0.9), Vector3(0, 0.45, 0), cloth, root)
	life._box(Vector3(2.7, 0.05, 1.0), Vector3(0, 0.92, 0), white, root)
	life._box(Vector3(2.8, 1.7, 0.08), Vector3(0, 2.0, -0.9), dark, root)
	var line: StandardMaterial3D = scene.city.glow_mat(col, 1.4)
	for r in 3:
		var n := 4 >> r
		for i in n:
			var y := 1.4 + (i + 0.5) * (1.2 / n)
			life._box(Vector3(0.5, 0.05, 0.02), Vector3(-0.95 + r * 0.7, y, -0.85), line, root)
	life._box(Vector3(0.36, 0.3, 0.02), Vector3(1.05, 2.0, -0.85), scene.city.glow_mat(UITheme.GOLD, 2.0), root)
	for sx: float in [-1.0, 1.0]:
		life._cyl(0.04, 0.04, 3.4, Vector3(sx * 1.9, 1.7, -0.6), dark, root, 6)
		life._box(Vector3(0.7, 2.2, 0.03), Vector3(sx * 1.9, 2.2, -0.52), scene.city.glow_mat(col.darkened(0.2), 0.7), root)
	# A trophy on the table.
	var gold: StandardMaterial3D = life._m(Color(0.95, 0.78, 0.3), 0.25, 0.9)
	life._cyl(0.16, 0.07, 0.3, Vector3(0.8, 1.22, 0), gold, root, 12)
	life._cyl(0.03, 0.03, 0.14, Vector3(0.8, 1.02, 0), gold, root, 8)
	life._box(Vector3(0.22, 0.05, 0.22), Vector3(0.8, 0.96, 0), dark, root)
	var sign := Label3D.new()
	sign.text = Loc.t(str(d["name"])).to_upper() if d.has("requires") else Loc.t("TOURNAMENT DESK")
	sign.font = UITheme.title_font()
	sign.font_size = 60
	sign.pixel_size = 0.006
	sign.outline_size = 12
	sign.modulate = col.lightened(0.4)
	sign.position = Vector3(0, 3.25, -0.8)
	root.add_child(sign)
	life._solid(1.5, 1.0, at + Vector3(0, 0.5, 0))
	var front: Vector3 = at + Basis(Vector3.UP, float(d["desk_yaw"])) * Vector3(0, 0, 1.7)
	scene._spots.append({"pos": Vector3(front.x, 0, front.z), "range": 2.0, "label": "Crossroads Cup desk" if d.has("requires") else "Tournament desk", "action": func(): _desk(id)})
	# The finals crowd: people in a half ring, spotlights and a banner. Hidden until the finals.
	var crowd := Node3D.new()
	add_child(crowd)
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	var models := ["student_boy", "student_girl", "office_worker", "stylish_woman", "street_duelist", "duelist_f1", "duelist_m5", "duelist_m9"]
	for k in 12:
		var ang := float(d["desk_yaw"]) + PI * (0.2 + 0.6 * float(k) / 11.0) - PI / 2.0
		var rad := 4.6 + (k % 3) * 1.1
		var p := Vector3(front.x + sin(ang) * rad, at.y, front.z + cos(ang) * rad)
		var f: RoamFigure = life._person(models[rng.randi() % models.size()], p, atan2(front.x - p.x, front.z - p.z), "stand",
			["red", "yellow", "blue"][k % 3] if district == "academy" else "")
		f.watch = scene._player
		life._day_people.erase(f)
		life.remove_child(f)
		crowd.add_child(f)
		f.position = p
	for sx: float in [-1.0, 1.0]:
		var spot := SpotLight3D.new()
		spot.light_color = col.lightened(0.5)
		spot.light_energy = 14.0
		spot.spot_range = 16.0
		spot.spot_angle = 32.0
		spot.position = at + Vector3(sx * 5.0, 7.0, 2.0)
		crowd.add_child(spot)
		spot.look_at(front + Vector3(0, 0.5, 0), Vector3.UP)
	var ban := Label3D.new()
	ban.text = Loc.t("FINALS TONIGHT")
	ban.font = UITheme.title_font()
	ban.font_size = 120
	ban.pixel_size = 0.008
	ban.outline_size = 16
	ban.modulate = UITheme.GOLD
	ban.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	ban.position = at + Vector3(0, 5.2, 0)
	crowd.add_child(ban)
	crowd.visible = false
	_crowds[id] = crowd


func _build_chip() -> void:
	_chip = PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.054, 0.0996, 0.285, 0.86), 14, Color(UITheme.GOLD, 0.6))
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_chip.add_theme_stylebox_override("panel", sb)
	_chip.position = Vector2(44, 176)
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.visible = false
	scene._ui.add_child(_chip)
	_chip_l = UITheme.label("", 20, UITheme.GOLD, UITheme.semi_font())
	_chip.add_child(_chip_l)


func _refresh() -> void:
	var text := ""
	for id in Tournament.in_district(district):
		var s := Tournament.st(id)
		var d: Dictionary = Tournament.DEFS[id]
		var finals := str(s["stage"]) == "finals"
		if _crowds.has(id):
			(_crowds[id] as Node3D).visible = finals
		if str(s["stage"]) == "qualify":
			var have := int(s["badges"])
			text = Loc.t("Finals Badges  %d / %d") % [have, int(d["need"])] + ("   ·   " + Loc.t("go to the desk") if have >= int(d["need"]) else "")
		elif finals:
			text = Loc.t("%s  ·  your match is waiting at the desk") % Loc.t(Tournament.ROUNDS[clampi(int(s["round"]), 0, 2)]).capitalize()
			# Finals are held under the lights.
			if scene.city.tod != "night":
				scene.city.apply_tod("night")
				scene._update_fill()
	if _chip:
		_chip.visible = text != ""
		_chip_l.text = text


func _desk(id: String) -> void:
	var s := Tournament.st(id)
	var d: Dictionary = Tournament.DEFS[id]
	match str(s["stage"]):
		"qualify":
			if int(s["badges"]) >= int(d["need"]):
				Tournament.start_finals(id)
				Sfx.play("quest", -3.0)
				_refresh()
				_show_bracket(id, {})
			else:
				Router.toast(Loc.t("%d of %d Finals Badges. Beat more duelists, then come back.") % [int(s["badges"]), int(d["need"])])
		"finals":
			_show_bracket(id, {})
		_:
			var lack := Tournament.missing(id)
			if not lack.is_empty():
				Router.toast(Loc.t("Champions only. You still need: %s") % ", ".join(lack))
				Sfx.play("error", -8.0)
				return
			Tournament.register(id)
			if int(d["need"]) <= 0:
				# No qualifying round: straight to the draw.
				Tournament.start_finals(id)
				Sfx.play("quest", -3.0)
				_refresh()
				_show_bracket(id, {})
				return
			Sfx.play("quest", -3.0)
			Router.toast(Loc.t("You are entered in the %s!") % Loc.t(str(d["name"])))
			get_tree().create_timer(2.6).timeout.connect(func(): Router.toast(Loc.t(str(d["blurb"]))))
			_refresh()


func _show_bracket(id: String, result: Dictionary) -> void:
	if scene._overlay_open:
		return
	var p := BracketPanel.new(id, result)
	p.play.connect(func():
		Router.roam["pos"] = scene._player.position
		Router.roam["yaw"] = scene._yaw
		Router.roam["tourney"] = id
		Router.roam["last_duel"] = ""
		Router.duel_config = Tournament.duel_config(id)
		Router.go(Router.DUEL))
	scene._open_overlay(p)


## Called by the world when you win a duel against someone out here.
func street_win(npc_id: String, deck: String) -> void:
	var got := Tournament.street_win(district, npc_id, deck)
	if got.is_empty():
		return
	_refresh()
	Sfx.play("quest", -4.0)
	var line := Loc.t("Finals Badge earned!  %d / %d") % [int(got["badges"]), int(got["need"])]
	if int(got["card"]) != 0:
		line += "   ·   " + Loc.t("You take %s from their deck.") % str(CardData.get_card(int(got["card"])).get("name", "?"))
	get_tree().create_timer(2.4).timeout.connect(func(): Router.toast(line))
	if got["ready"]:
		get_tree().create_timer(5.4).timeout.connect(func(): Router.toast(Loc.t("That is enough badges. The finals are waiting at the tournament desk.")))
