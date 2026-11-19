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
				await board.anim_declare(ME, a, foe)
				await board.anim_battle(ME, a, foe)
				await board.anim_destroy(foe)
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
				{"type": "chain_solving", "n": 2}, {"type": "chain_negated", "n": 2}, {"type": "chain_solved", "n": 2},
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
