class_name FxDemo
extends RefCounted
## Dev: plays one duel animation on a quiet table and saves frames of it, so its look can be
## checked without playing a duel to the right moment.
##   ... --duel --skip-opening --first=me --fxdemo=<name>[:frames[:seconds between]]
## Frames go to /tmp/fx_<name>_NN.png; the game quits after the last one.
## (Software rendering is slow, so the demo runs the clock slowly while it films.)


static func wanted() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fxdemo="):
			return a.substr(9)
	return ""


static func run(scene) -> void:
	var spec := wanted().split(":")
	var name := spec[0]
	var frames := int(spec[1]) if spec.size() > 1 else 8
	var gap := float(spec[2]) if spec.size() > 2 else 0.25
	var tree: SceneTree = scene.get_tree()
	await tree.create_timer(float(OS.get_environment("FX_WAIT")) if OS.has_environment("FX_WAIT") else 16.0).timeout
	var board = scene.board
	var st = scene.state
	Engine.time_scale = float(OS.get_environment("FX_SCALE")) if OS.has_environment("FX_SCALE") else 0.2
	_film(scene, name, frames, gap)
	await _play(scene, board, st, name)


static func _film(scene, name: String, frames: int, gap: float) -> void:
	var tree: SceneTree = scene.get_tree()
	if OS.has_environment("FX_SKIP"):
		# (start filming this many seconds into the animation)
		await tree.create_timer(float(OS.get_environment("FX_SKIP"))).timeout
	for i in frames:
		await tree.create_timer(gap).timeout
		await RenderingServer.frame_post_draw
		scene.get_viewport().get_texture().get_image().save_png("/tmp/fx_%s_%02d.png" % [name, i])
	print("FXDEMO done ", name)
	Engine.time_scale = 1.0
	tree.quit()


static func _mk(st, name: String, owner: int):
	var id := int(CardData.NAME_TO_ID.get(name.to_lower(), 0))
	var c = st._make(id, owner)
	c.face_up = true
	return c


static func _play(scene, board, st, name: String) -> void:
	var ME := 0
	var AI := 1
	match name:
		"summon":
			await board.anim_summon(ME, _mk(st, "Gagaga Magician", ME), 2, false)
		"set":
			var c = _mk(st, "Gagaga Magician", ME)
			c.face_up = false
			await board.anim_summon(ME, c, 1, true)
			var s = _mk(st, "Mirror Force", ME)
			s.face_up = false
			await board.anim_set_st(ME, s, 3)
		"oppsummon":
			var c2 = _mk(st, "Blue-Eyes White Dragon", AI)
			await board.anim_summon(AI, c2, 2, false)
		"synchro", "xyz", "fusion", "ritual":
			var mats := {"synchro": ["Junk Synchron", "Speed Warrior"], "xyz": ["Gagaga Magician", "Gogogo Golem"],
				"fusion": ["Elemental HERO Avian", "Elemental HERO Burstinatrix"], "ritual": ["Gagaga Magician", "Gogogo Golem"]}
			var big := {"synchro": "Junk Warrior", "xyz": "Number 39: Utopia", "fusion": "Elemental HERO Flame Wingman", "ritual": "Black Luster Soldier"}
			var ms: Array = []
			var z := 1
			for n in mats[name]:
				var m = _mk(st, n, ME)
				ms.append(m)
				var c3: Card3D = board._new_card(m)
				c3.transform = Transform3D(board.table_basis(ME, true, true), board.monster_zone_pos(ME, z) + Vector3(0, 0.02, 0))
				z += 2
			await scene.get_tree().create_timer(0.3).timeout
			for m in ms:
				await board.anim_material(ME, m, "field", board.monster_zone_pos(ME, 2))
			var b = _mk(st, big[name], ME)
			if name == "xyz":
				b.overlays = ms.duplicate()
			await board.anim_special(ME, b, 2, name, ms)
		"battle", "finish":
			var a = _mk(st, "Blue-Eyes White Dragon", ME)
			var foe = _mk(st, "Dark Magician", AI)
			var ca: Card3D = board._new_card(a)
			ca.transform = Transform3D(board.table_basis(ME, true, true), board.monster_zone_pos(ME, 2) + Vector3(0, 0.02, 0))
			if name == "battle":
				var cf: Card3D = board._new_card(foe)
				cf.transform = Transform3D(board.table_basis(AI, true, true), board.monster_zone_pos(AI, 2) + Vector3(0, 0.02, 0))
				await scene.get_tree().create_timer(0.2).timeout
				# FX_CASE: win (default), lose, tie, wall (a Defense Position monster that holds)
				var case := OS.get_environment("FX_CASE")
				var t_atk := {"": 2500, "lose": 3300, "tie": 3000, "wall": 2500}.get(case, 2500) as int
				var evs: Array = [{"type": "attack", "player": ME, "card": a, "target": foe},
					{"type": "battle", "player": ME, "card": a, "target": foe, "atk": 3000, "t_atk": t_atk, "t_def": 3400 if case == "wall" else 2100, "t_defending": case == "wall"}]
				if case == "" or case == "tie":
					evs.append({"type": "destroy", "player": AI, "card": foe})
				if case == "lose" or case == "tie":
					evs.append({"type": "destroy", "player": ME, "card": a})
				await scene._play(evs)
			else:
				await scene.get_tree().create_timer(0.2).timeout
				await scene._play([{"type": "attack", "player": ME, "card": a, "target": null},
					{"type": "battle", "player": ME, "card": a, "target": null},
					{"type": "lp", "player": AI, "lp": 0, "delta": -3000}])
		"chain":
			var s1 = _mk(st, "Mystical Space Typhoon", ME)
			var s2 = _mk(st, "Mirror Force", AI)
			var s3 = _mk(st, "Seven Tools of the Bandit", ME)
			for pair in [[s2, AI, 3], [s3, ME, 3]]:
				var cc: Card3D = board._new_card(pair[0])
				cc.transform = Transform3D(board.table_basis(pair[1], false, true), board.spell_zone_pos(pair[1], pair[2]) + Vector3(0, 0.02, 0))
			await scene._play([{"type": "activate", "player": ME, "card": s1, "zone": 1},
				{"type": "chain_link", "player": ME, "card": s1, "n": 1},
				{"type": "trap", "player": AI, "card": s2, "zone": 3},
				{"type": "chain_link", "player": AI, "card": s2, "n": 2},
				{"type": "trap", "player": ME, "card": s3, "zone": 3},
				{"type": "chain_link", "player": ME, "card": s3, "n": 3},
				{"type": "chain_solving", "n": 3}, {"type": "chain_solved", "n": 3},
				{"type": "chain_solving", "n": 2}, {"type": "chain_negated", "n": 2, "card": s2, "player": AI}, {"type": "chain_solved", "n": 2},
				{"type": "chain_solving", "n": 1}, {"type": "chain_solved", "n": 1},
				{"type": "chain_end"}])
		"effects":
			# One of each way a card leaves the field.
			var names := ["Gagaga Magician", "Gogogo Golem", "Speed Warrior", "Junk Synchron"]
			var cs: Array = []
			for i in 4:
				var m2 = _mk(st, names[i], AI if i < 2 else ME)
				cs.append(m2)
				var c4: Card3D = board._new_card(m2)
				c4.transform = Transform3D(board.table_basis(m2.owner, true, true), board.monster_zone_pos(m2.owner, 1 + (i % 2) * 2) + Vector3(0, 0.02, 0))
			await scene.get_tree().create_timer(0.2).timeout
			await board.anim_destroy(cs[0])
			await board.anim_banish(cs[1], "field", AI)
			await board.anim_bounce(cs[2])
			await board.anim_tribute(cs[3])
		"direct", "oppbattle", "ace":
			var d1 = _mk(st, "Blue-Eyes White Dragon", ME)
			var d2 = _mk(st, "Dark Magician", AI)
			if name == "ace":
				await board.anim_summon(ME, d1, 3, false)
				return
			for dm in [d1, d2]:
				if name == "direct" and dm == d2:
					continue
				var dc: Card3D = board._new_card(dm)
				dc.transform = Transform3D(board.table_basis(dm.owner, true, true), board.monster_zone_pos(dm.owner, 1 if dm == d1 else 3) + Vector3(0, 0.02, 0))
			await scene.get_tree().create_timer(0.2).timeout
			if name == "direct":
				await scene._play([{"type": "attack", "player": ME, "card": d1, "target": null},
					{"type": "battle", "player": ME, "card": d1, "target": null},
					{"type": "lp", "player": AI, "lp": 5000, "delta": -3000}])
			else:
				await scene._play([{"type": "attack", "player": AI, "card": d2, "target": d1},
					{"type": "battle", "player": AI, "card": d2, "target": d1, "atk": 2500, "t_atk": 3000, "t_def": 2500, "t_defending": false},
					{"type": "destroy", "player": AI, "card": d2}])
		"looks":
			# The trips between piles, a monster's effect, and ATK going up and down.
			var g1 = _mk(st, "Gagaga Magician", ME)
			var g2 = _mk(st, "Gogogo Golem", AI)
			for m3 in [g1, g2]:
				var c5: Card3D = board._new_card(m3)
				c5.transform = Transform3D(board.table_basis(m3.owner, true, true), board.monster_zone_pos(m3.owner, 2) + Vector3(0, 0.02, 0))
			var x1 = _mk(st, "Speed Warrior", ME)
			var x2 = _mk(st, "Junk Synchron", ME)
			var x3 = _mk(st, "Mirror Force", AI)
			await scene.get_tree().create_timer(0.2).timeout
			await board.anim_travel("search", ME, x1)
			await board.anim_travel("mill", ME, x2)
			await board.anim_travel("mill", AI, x3)
			board.remove_from_gy(x2)
			await board.anim_travel("gy_to_hand", ME, x2)
			board.remove_from_gy(x3)
			await board.anim_travel("gy_to_deck", AI, x3)
			await board.effect_burst(g1, Color("ffd23a"))
			await scene.get_tree().create_timer(0.5).timeout
			board._stat_pop(board.monster_zone_pos(ME, 2), 800, 0)
			board._stat_pop(board.monster_zone_pos(AI, 2), -500, -500)
			await scene.get_tree().create_timer(1.0).timeout
		"holo":
			# Holograms side by side: every Attribute, small and big, and three signature monsters.
			var mine := ["Kuriboh", "Dark Magician", "Blue-Eyes White Dragon", "Red-Eyes Black Dragon", "Gagaga Magician"]
			var theirs := ["Mother Grizzly", "Harpie Lady", "Obelisk the Tormentor", "Giant Soldier of Stone", "Flame Manipulator"]
			for i in 5:
				for pr in [[mine[i], ME], [theirs[i], AI]]:
					var hm = _mk(st, pr[0], pr[1])
					var hc: Card3D = board._new_card(hm)
					hc.transform = Transform3D(board.table_basis(pr[1], true, true), board.monster_zone_pos(pr[1], i) + Vector3(0, 0.02, 0))
					var hh := MonsterHolo.new()
					board.add_child(hh)
					hh.setup(hm, hc, board.ATTR_COLORS.get(str(hm.data.get("attribute", "")), UITheme.ACCENT), 0.1)
			await scene.get_tree().create_timer(1.1).timeout
			board.cam_shot(Vector3(0.6, 1.9, 6.4), Vector3(0, 0.9, 1.2), 0.3)
			await scene.get_tree().create_timer(1.0).timeout
			board.cam_shot(Vector3(-1.2, 2.4, 2.6), Vector3(0.2, 0.9, -1.6), 0.3)
			await scene.get_tree().create_timer(1.0).timeout
			board.cam_shot(Vector3(1.6, 1.3, 4.6), Vector3(0, 1.0, 1.4), 0.3)
			await scene.get_tree().create_timer(1.0).timeout
		"kit":
			var z0: Vector3 = board.monster_zone_pos(ME, 0)
			DuelFx.glyph(board, board.monster_zone_pos(ME, 0), Color("5aa8ff"), 1.1, 3.0)
			DuelFx.pillar(board, board.monster_zone_pos(ME, 1), Color("6dff9a"), 0.5, 6.0, 3.0)
			DuelFx.pit(board, board.monster_zone_pos(ME, 2), 1.0, 3.0)
			DuelFx.spiral(board, board.monster_zone_pos(ME, 2) + Vector3(0, 0.04, 0), Color("ffd23a"), Color("b15cff"), 1.4, 3.0, {"hole": 0.22})
			DuelFx.spiral(board, board.monster_zone_pos(ME, 3) + Vector3(0, 1.4, 0), Color("ff8a3a"), Color("3aa0ff"), 1.0, 3.0, {"flat": false, "arms": 2})
			DuelFx.glow(board, board.monster_zone_pos(ME, 4) + Vector3(0, 0.8, 0), Color("ffe9a8"), 1.6, 3.0, 1.0)
			DuelFx.rect(board, board.monster_zone_pos(AI, 0), Color("7fd8ff"), 1.0, 1.6, 3.0)
			DuelFx.rays(board, board.monster_zone_pos(AI, 1), Color("ffd23a"), 1.6, 3.0)
			DuelFx.ring(board, board.monster_zone_pos(AI, 2), Color("ff5a7a"), 0.3, 1.2, 3.0)
			DuelFx.embers(board, board.monster_zone_pos(AI, 3), Color("5aa8ff"), 0.4, 30, 3.0)
			DuelFx.chain(board, board.monster_zone_pos(AI, 4) + Vector3(0, 0.3, 0), board.monster_zone_pos(ME, 4) + Vector3(0, 0.3, 0), Color("ffd23a"), board.camera, 1.0)
			var o := DuelFx.orb(board, z0 + Vector3(0, 0.5, 1.5), Color("ffd23a"))
			var tw: Tween = board.create_tween()
			tw.tween_property(o, "position", board.monster_zone_pos(ME, 4) + Vector3(0, 1.5, 1.5), 2.0)
			await tw.finished
		_:
			print("FXDEMO unknown ", name)
