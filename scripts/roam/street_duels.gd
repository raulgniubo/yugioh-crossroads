class_name StreetDuels
extends Node3D
## Duels happening around town that you can stop and watch: two duelists, a holographic field
## between them, monsters that get summoned and attack, Life Points over their heads and a few
## people cheering. Nothing here is a real rules duel; it is a little show that loops.

const SITES := {
	"domino": [
		{"at": Vector3(4.8, 0.2, -40.2), "yaw": 0.0, "a": "street_duelist", "b": "duelist_m5", "decks": ["joey", "rex"], "fans": 4},
		{"at": Vector3(-9.0, 0.2, 53.0), "yaw": 0.0, "a": "duelist_f1", "b": "student_boy", "decks": ["mai", "weevil"], "fans": 3},
	],
	"academy": [
		{"at": Vector3(18.0, 0.16, -22.0), "yaw": 0.0, "a": "student_boy", "b": "student_girl", "decks": ["jaden", "alexis"], "fans": 3, "dorms": ["red", "blue"]},
		{"at": Vector3(27.0, 0.16, -22.0), "yaw": 0.0, "a": "duelist_m9", "b": "student_boy", "decks": ["chazz", "syrus"], "fans": 2, "dorms": ["blue", "yellow"]},
	],
}
const FANS := ["student_girl", "student_boy", "office_worker", "stylish_woman", "duelist_f1", "duelist_m9"]
const SHOUTS := ["What a play!", "Did you see that?!", "Come on, attack!", "That monster is huge!", "Don't give up!", "One more turn!"]
const HALF := 3.3          # duelists stand this far from the middle

var life: Node               # the WorldLife that owns us
var scene: Node
var _duels: Array = []       # one Dictionary per running duel


func setup(world: Node, district: String) -> void:
	life = world
	scene = world.scene
	for s in SITES.get(district, []):
		_build(s)


func _monsters(deck: String) -> Array:
	var out: Array = []
	if CardData.has_deck(deck):
		for id in CardData.deck_list(deck):
			var d := CardData.get_card(int(id))
			if str(d.get("kind", "")) == "monster" and int(d.get("atk", 0)) > 0 and not out.has(int(id)):
				out.append(int(id))
	if out.is_empty():
		out = [0]
	return out


func _build(s: Dictionary) -> void:
	var root := Node3D.new()
	root.position = s["at"]
	root.rotation.y = float(s["yaw"])
	add_child(root)
	var cols := [Color("2de2e6"), Color("ff5a7a")]
	var d := {"root": root, "figs": [], "lp": [4000, 4000], "lp_l": [], "mons": [[], []], "pool": [], "t": randf_range(1.0, 3.0),
		"turn": randi() % 2, "over": 0.0, "fans": [], "cols": cols, "near": false}
	# The field: a glowing outline, a center line and three card zones each.
	var edge := StandardMaterial3D.new()
	edge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	edge.albedo_color = Color(0.6, 0.9, 1.0, 0.55)
	for z: float in [-1.5, 1.5]:
		life._box(Vector3(4.6, 0.02, 0.05), Vector3(0, 0.03, z), edge, root)
	for x: float in [-2.3, 2.3]:
		life._box(Vector3(0.05, 0.02, 3.0), Vector3(x, 0.03, 0), edge, root)
	life._box(Vector3(0.03, 0.02, 3.0), Vector3(0, 0.03, 0), edge, root)
	var dorms: Array = s.get("dorms", ["", ""])
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var zone := StandardMaterial3D.new()
		zone.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		zone.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		zone.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		zone.albedo_color = Color(cols[i], 0.22)
		for k in 3:
			life._box(Vector3(0.62, 0.02, 0.86), Vector3(side * 1.25, 0.035, -1.0 + k * 1.0), zone, root)
		var f: RoamFigure = life._person(str(s["a"] if i == 0 else s["b"]), Vector3.ZERO, 0.0, "stand", str(dorms[i]))
		life.remove_child(f)
		root.add_child(f)
		f.position = Vector3(side * HALF, 0, 0)
		f.rotation.y = -side * PI / 2.0
		f.watch = null
		f.lively = false
		d["figs"].append(f)
		# A duel disk glow on the arm side and the Life Points overhead.
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.font = UITheme.title_font()
		l.font_size = 64
		l.pixel_size = 0.006
		l.outline_size = 14
		l.modulate = cols[i].lightened(0.3)
		l.outline_modulate = Color(0, 0, 0, 0.85)
		l.position = Vector3(side * HALF, 2.25, 0)
		l.text = "LP 4000"
		l.no_depth_test = false
		root.add_child(l)
		d["lp_l"].append(l)
		d["pool"].append(_monsters(str((s["decks"] as Array)[i])))
	# People watching from the long sides.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf((s["at"] as Vector3).x * 31.0 + (s["at"] as Vector3).z * 7.0))
	for k in int(s.get("fans", 3)):
		var zs := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(rng.randf_range(-2.4, 2.4), 0, zs * rng.randf_range(2.7, 3.5))
		var fan: RoamFigure = life._person(FANS[rng.randi() % FANS.size()], Vector3.ZERO, 0.0, "stand", str(dorms[k % 2]) if dorms[0] != "" else "")
		life.remove_child(fan)
		root.add_child(fan)
		fan.position = p
		fan.rotation.y = atan2(-p.x, -p.z)
		fan.watch = null
		d["fans"].append(fan)
	# Stop and watch.
	var wp: Vector3 = root.to_global(Vector3(0, 0, 4.2))
	scene._spots.append({"pos": Vector3(wp.x, 0, wp.z), "range": 2.0, "label": "Watch the duel", "action": func(): _watch(d)})
	_duels.append(d)


func _watch(d: Dictionary) -> void:
	var who := 0 if int(d["lp"][0]) >= int(d["lp"][1]) else 1
	if int(d["lp"][0]) == int(d["lp"][1]):
		Router.toast(Loc.t("Dead even at %d Life Points each.") % int(d["lp"][0]))
	else:
		Router.toast(Loc.t("The %s duelist leads, %d to %d.") % [Loc.t("blue") if who == 0 else Loc.t("red"), int(d["lp"][who]), int(d["lp"][1 - who])])
	Collection.daily_bump("watch")
	if scene._figure:
		scene._figure.gesture("cheer", 0.25)
		scene._figure._hold = 1.6


func _zone_pos(i: int, k: int) -> Vector3:
	return Vector3((-1.25 if i == 0 else 1.25), 0.05, -1.0 + k * 1.0)


func _summon(d: Dictionary, i: int) -> void:
	var mons: Array = d["mons"][i]
	if mons.size() >= 3:
		return
	var used := {}
	for m in mons:
		used[int(m["zone"])] = true
	var zone := 0
	for k in [1, 0, 2]:
		if not used.has(k):
			zone = k
			break
	var pool: Array = d["pool"][i]
	var id: int = pool[randi() % pool.size()]
	var data := CardData.get_card(id)
	var root: Node3D = d["root"]
	var holder := Node3D.new()
	holder.position = _zone_pos(i, zone)
	root.add_child(holder)
	# The card on the ground and its monster standing over it as a hologram.
	var card := Sprite3D.new()
	card.texture = Cards.get_face(id)
	card.pixel_size = 0.82 / maxf(1.0, card.texture.get_height())
	card.rotation = Vector3(-PI / 2.0, (PI / 2.0 if i == 0 else -PI / 2.0), 0)
	card.shaded = false
	holder.add_child(card)
	var art := Cards.get_art(id)
	var spr := Sprite3D.new()
	spr.texture = art
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.shaded = false
	var h := 1.25 + clampf(float(data.get("level", 4)) - 4.0, 0.0, 4.0) * 0.14
	spr.pixel_size = h / maxf(1.0, art.get_height())
	spr.position = Vector3(0, h * 0.5 + 0.35, 0)
	spr.modulate = Color(1.1, 1.15, 1.25, 0.0)
	spr.scale = Vector3(0.2, 0.05, 0.2)
	holder.add_child(spr)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.48
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.albedo_color = Color(d["cols"][i], 0.9)
	ring.material_override = rm
	ring.position.y = 0.04
	holder.add_child(ring)
	var tag := Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font = UITheme.semi_font()
	tag.font_size = 40
	tag.pixel_size = 0.005
	tag.outline_size = 10
	tag.text = str(int(data.get("atk", 0)))
	tag.modulate = Color(1.0, 0.9, 0.5)
	tag.position = Vector3(0, 0.24, 0)
	holder.add_child(tag)
	var tw := holder.create_tween().set_parallel()
	tw.tween_property(spr, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "modulate:a", 0.92, 0.3)
	tw.tween_property(ring, "scale", Vector3(1.9, 1.0, 1.9), 0.5)
	tw.tween_property(rm, "albedo_color:a", 0.25, 0.5)
	mons.append({"node": holder, "spr": spr, "atk": int(data.get("atk", 0)), "zone": zone, "name": str(data.get("name", ""))})
	(d["figs"][i] as RoamFigure).gesture("checkout", 0.2)
	(d["figs"][i] as RoamFigure)._hold = 1.2
	if d["near"]:
		Sfx.play("flip", -14.0)


func _remove(d: Dictionary, i: int, m: Dictionary) -> void:
	(d["mons"][i] as Array).erase(m)
	var node: Node3D = m["node"]
	var tw := node.create_tween().set_parallel()
	tw.tween_property(m["spr"], "modulate", Color(3.0, 3.0, 3.0, 0.0), 0.3)
	tw.tween_property(m["spr"], "scale", Vector3(1.5, 0.02, 1.5), 0.3)
	tw.chain().tween_callback(node.queue_free)


func _attack(d: Dictionary, i: int) -> void:
	var mine: Array = d["mons"][i]
	var theirs: Array = d["mons"][1 - i]
	if mine.is_empty():
		return
	var a: Dictionary = mine[0]
	for m in mine:
		if int(m["atk"]) > int(a["atk"]):
			a = m
	var spr: Sprite3D = a["spr"]
	var home := spr.position
	var target := Vector3.ZERO
	var dmg := 0
	var victim := {}
	var lose_own := false
	if theirs.is_empty():
		target = Vector3((HALF - 0.6) * (1.0 if i == 0 else -1.0) - (a["node"] as Node3D).position.x, 1.0, -(a["node"] as Node3D).position.z)
		dmg = int(a["atk"])
	else:
		victim = theirs[0]
		for m in theirs:
			if int(m["atk"]) < int(victim["atk"]):
				victim = m
		target = (victim["node"] as Node3D).position - (a["node"] as Node3D).position + Vector3(0, 0.9, 0)
		if int(a["atk"]) > int(victim["atk"]):
			dmg = int(a["atk"]) - int(victim["atk"])
		elif int(a["atk"]) < int(victim["atk"]):
			lose_own = true
			dmg = -(int(victim["atk"]) - int(a["atk"]))
	var fig: RoamFigure = d["figs"][i]
	fig.gesture("cheer", 0.15)
	fig._hold = 1.0
	if d["near"]:
		Sfx.play("attack", -15.0)
	var tw := spr.create_tween()
	tw.tween_property(spr, "position", home + Vector3(0, 0.25, 0), 0.18)
	tw.tween_property(spr, "position", home + target * 0.82, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_flash(d, (a["node"] as Node3D).position + home + target * 0.9, d["cols"][i])
		if d["near"]:
			Sfx.play("impact", -15.0)
		if lose_own:
			_hurt(d, i, -dmg)
		else:
			if not victim.is_empty() and int(a["atk"]) >= int(victim["atk"]):
				_remove(d, 1 - i, victim)
			if dmg > 0:
				_hurt(d, 1 - i, dmg))
	tw.tween_property(spr, "position", home, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if lose_own:
		tw.tween_callback(func(): _remove(d, i, a))


func _flash(d: Dictionary, at: Vector3, col: Color) -> void:
	var root: Node3D = d["root"]
	var s := Sprite3D.new()
	if true:
		var g := GradientTexture2D.new()
		var gr := Gradient.new()
		gr.set_color(0, Color(1, 1, 1, 1))
		gr.set_color(1, Color(1, 1, 1, 0))
		g.gradient = gr
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		g.width = 64
		g.height = 64
		s.texture = g
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.modulate = Color(col.lightened(0.5), 0.95)
	s.pixel_size = 0.012
	s.position = at
	root.add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale", Vector3.ONE * 3.2, 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(s.queue_free)


func _hurt(d: Dictionary, i: int, amount: int) -> void:
	d["lp"][i] = maxi(0, int(d["lp"][i]) - amount)
	var l: Label3D = d["lp_l"][i]
	l.text = "LP %d" % int(d["lp"][i])
	var base: Color = (d["cols"][i] as Color).lightened(0.3)
	l.modulate = Color(1.0, 0.25, 0.25)
	l.create_tween().tween_property(l, "modulate", base, 0.6)
	var fig: RoamFigure = d["figs"][i]
	if amount >= 1500:
		fig.gesture("stomp", 0.15)
		fig._hold = 1.2
	# The crowd reacts to a big hit.
	if amount >= 1200:
		for f in d["fans"]:
			if randf() < 0.6:
				(f as RoamFigure).gesture("cheer" if randf() < 0.7 else "cheer2", 0.25)
				(f as RoamFigure)._hold = 1.6
		if d["near"] and randf() < 0.5:
			Router.toast("\"" + Loc.t(SHOUTS[randi() % SHOUTS.size()]) + "\"")
	if int(d["lp"][i]) <= 0:
		d["over"] = 5.0
		(d["figs"][1 - i] as RoamFigure).play_once("victory", 2)
		fig.play_once("lose", 1)
		if d["near"]:
			Sfx.play("cheer", -12.0)


func _reset(d: Dictionary) -> void:
	for i in 2:
		for m in (d["mons"][i] as Array).duplicate():
			_remove(d, i, m)
		d["lp"][i] = 4000
		(d["lp_l"][i] as Label3D).text = "LP 4000"
	d["turn"] = randi() % 2


func _process(delta: float) -> void:
	if scene == null or scene._player == null:
		return
	var pp: Vector3 = scene._player.global_position
	for d in _duels:
		var root: Node3D = d["root"]
		var dist := root.global_position.distance_to(pp)
		d["near"] = dist < 16.0
		# Far away nobody is watching: let it rest.
		if dist > 70.0:
			continue
		if float(d["over"]) > 0.0:
			d["over"] = float(d["over"]) - delta
			if float(d["over"]) <= 0.0:
				_reset(d)
			continue
		d["t"] = float(d["t"]) - delta
		if float(d["t"]) > 0.0:
			continue
		var i: int = d["turn"]
		var mine: Array = d["mons"][i]
		# A turn is: summon if there is room, then attack with the strongest.
		if int(d.get("step", 0)) == 0:
			if mine.size() < 3 and (mine.is_empty() or randf() < 0.75):
				_summon(d, i)
			d["step"] = 1
			d["t"] = randf_range(1.3, 2.0)
		else:
			if not mine.is_empty() and randf() < 0.9:
				_attack(d, i)
			d["step"] = 0
			d["turn"] = 1 - i
			d["t"] = randf_range(2.0, 3.2)
