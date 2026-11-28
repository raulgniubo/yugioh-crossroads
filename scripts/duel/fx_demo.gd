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
		scene.get_viewport().get_texture().get_image().save_png("/tmp/fx_%s_%02d.png" % [OS.get_environment("FX_TAG") if OS.has_environment("FX_TAG") else name, i])
	print("FXDEMO done ", name)
	Engine.time_scale = 1.0
	tree.quit()


static func _mk(st, name: String, owner: int):
	var id := int(CardData.NAME_TO_ID.get(name.to_lower(), 0))
	var c = st._make(id, owner)
	c.face_up = true
	return c


static func _mk_id(st, id: int, owner: int):
	var c = st._make(id, owner)
	c.face_up = true
	return c


static func _play(scene, board, st, name: String) -> void:
	var ME := 0
	var AI := 1
	match name:
		# (0.81.0) Lumen's cards: lumen_summon, lumen_battle, lumen_finish, lumen_field,
		# lumen_aurora (Ritual), lumen_nova / lumen_chorus (Fusion), lumen_comet (Synchro), lumen_zenith (Xyz)
		# (0.83.0) How a card goes, by what destroyed it: gone_fire / water / wind / earth / light / dark
		# (an effect of a monster of that Attribute), gone_battle (FIRE, in a fight), gone_spell, gone_trap.
		"gone_fire", "gone_water", "gone_wind", "gone_earth", "gone_light", "gone_dark", "gone_battle", "gone_spell", "gone_trap":
			var gk := name.trim_prefix("gone_")
			var gm = _mk(st, "Dark Magician", AI)
			var gc: Card3D = board._new_card(gm)
			gc.transform = Transform3D(board.table_basis(AI, true, true), board.monster_zone_pos(AI, 2) + Vector3(0, 0.02, 0))
			await scene.get_tree().create_timer(0.4).timeout
			var gfrom: Vector3 = board.monster_zone_pos(ME, 1)
			var ghow := {"kind": "effect", "from": gfrom, "attr": gk.to_upper(), "st": ""}
			if gk == "battle":
				ghow = {"kind": "battle", "from": gfrom, "attr": "EARTH"}
			elif gk in ["spell", "trap"]:
				ghow = {"kind": "effect", "from": gfrom, "attr": "", "st": gk}
			await board.anim_destroy(gm, [], ghow)
			await scene.get_tree().create_timer(1.0).timeout
		# The draw everything rides on (fate_draw: yours, fate_draw_opp: theirs), and a hit on the Life
		# Points bar (lp_hit), and the entrance of one of the newer aces (ace_new, FX_ACE=<card name>).
		"fate_draw", "fate_draw_opp":
			var fp := ME if name == "fate_draw" else AI
			ScreenFx.letterbox(scene.hud, 1.9)
			if fp == ME:
				scene.hud.effect_text(Loc.t("Everything rides on this draw"), Color("ffd76a"))
			await board.anim_draw_fate(fp, _mk(st, "Dark Magician", fp), 20)
			await scene.get_tree().create_timer(0.6).timeout
		"fate_scene":
			# The same through the duel screen: you are at 1500 with one card and nothing on the field.
			st.players[ME].lp = 1500
			while st.players[ME].hand.size() > 1:
				st.players[ME].hand.pop_back()
			st.turn = 5
			await scene._play([{"type": "turn", "player": ME},
				{"type": "draw", "player": ME, "card": st.players[ME].deck[0], "deck": st.players[ME].deck.size() - 1}])
			print("FATE scene: fated=", scene._fated)
			await scene.get_tree().create_timer(0.6).timeout
		"lp_hit":
			scene.hud.set_lp(ME, 5200, -2800)
			await scene.get_tree().create_timer(3.0).timeout
		"ace_new":
			var an := OS.get_environment("FX_ACE") if OS.has_environment("FX_ACE") else "Shooting Star Dragon"
			var ac = _mk(st, an, ME)
			var ad: Dictionary = (ac.data as Dictionary).duplicate()
			ad["id"] = ac.id
			SummonShow.play(scene, ad, true)
			await scene.get_tree().create_timer(2.4).timeout
		"lumen_summon":
			await board.anim_summon(ME, _mk_id(st, 99200001, ME), 2, false)
			await board.hologram(_mk_id(st, 99200001, ME), board.monster_zone_pos(ME, 2))
		"lumen_battle", "lumen_finish":
			var la = _mk_id(st, 99200006 if name == "lumen_battle" else 99200007, ME)
			var lfoe = _mk(st, "Dark Magician", AI)
			var lca: Card3D = board._new_card(la)
			lca.transform = Transform3D(board.table_basis(ME, true, true), board.monster_zone_pos(ME, 2) + Vector3(0, 0.02, 0))
			if name == "lumen_battle":
				var lcf: Card3D = board._new_card(lfoe)
				lcf.transform = Transform3D(board.table_basis(AI, true, true), board.monster_zone_pos(AI, 2) + Vector3(0, 0.02, 0))
				await scene.get_tree().create_timer(0.2).timeout
				await scene._play([{"type": "attack", "player": ME, "card": la, "target": lfoe},
					{"type": "battle", "player": ME, "card": la, "target": lfoe, "atk": 2800, "t_atk": 2500, "t_def": 2100, "t_defending": false},
					{"type": "destroy", "player": AI, "card": lfoe}])
			else:
				await scene.get_tree().create_timer(0.2).timeout
				await scene._play([{"type": "attack", "player": ME, "card": la, "target": null},
					{"type": "battle", "player": ME, "card": la, "target": null},
					{"type": "lp", "player": AI, "lp": 0, "delta": -3000}])
		"lumen_bonds":
			var lb0 = _mk_id(st, 99200001, ME)
			var lbc: Card3D = board._new_card(lb0)
			lbc.transform = Transform3D(board.table_basis(ME, true, true), board.monster_zone_pos(ME, 2) + Vector3(0, 0.02, 0))
			await scene.get_tree().create_timer(0.2).timeout
			board.EchoFx.bonds(board, lbc.position, 5)
			await scene.get_tree().create_timer(1.6).timeout
		"lumen_field":
			var hall = _mk_id(st, 99200016, ME)
			board.set_field_look(FieldLooks.look_for(hall), board.field_pos(ME))
			scene.hud.field_banner(hall.cname(), "yours", Color("7fe8ff"))
			scene.hud.set_field_strip(hall, FieldLooks.says(hall), Color("7fe8ff"), "yours")
			await scene.get_tree().create_timer(6.0).timeout
		"lumen_aurora", "lumen_nova", "lumen_chorus", "lumen_comet", "lumen_zenith":
			var how: String = {"lumen_aurora": "ritual", "lumen_nova": "fusion", "lumen_chorus": "fusion", "lumen_comet": "synchro", "lumen_zenith": "xyz"}[name]
			var lbig: int = {"lumen_aurora": 99200006, "lumen_nova": 99200007, "lumen_chorus": 99200002, "lumen_comet": 99200003, "lumen_zenith": 99200004}[name]
			var lmats: Array = {"lumen_aurora": [99200001], "lumen_nova": [99200001, 99200003], "lumen_chorus": [99200001, 99200021],
				"lumen_comet": [99200001, 99200024, 99200021], "lumen_zenith": [99200001, 99200022]}[name]
			var lms: Array = []
			var lz := 1
			for mid in lmats:
				var lm = _mk_id(st, int(mid), ME)
				lms.append(lm)
				var lc3: Card3D = board._new_card(lm)
				lc3.transform = Transform3D(board.table_basis(ME, true, true), board.monster_zone_pos(ME, lz) + Vector3(0, 0.02, 0))
				lz += 2 if lmats.size() <= 2 else 1
			await scene.get_tree().create_timer(0.3).timeout
			for lm2 in lms:
				await board.anim_material(ME, lm2, "field", board.monster_zone_pos(ME, 2))
			var lb = _mk_id(st, lbig, ME)
			if how == "xyz":
				lb.overlays = lms.duplicate()
			await board.anim_special(ME, lb, 2, how, lms)
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
		"elem":
			# One attack, start to end. FX_CARD = the attacker (default Tyrant Dragon), FX_OPP=1 the
			# opponent attacks, FX_DIRECT=1 a direct attack, FX_GATHER=1 stop after the declaration.
			var who := OS.get_environment("FX_CARD") if OS.has_environment("FX_CARD") else "Tyrant Dragon"
			var side := AI if OS.get_environment("FX_OPP") == "1" else ME
			var e1 = _mk(st, who, side)
			var e2 = _mk(st, "Gogogo Golem", 1 - side)
			var ec: Card3D = board._new_card(e1)
			ec.transform = Transform3D(board.table_basis(side, true, true), board.monster_zone_pos(side, 1) + Vector3(0, 0.02, 0))
			var tgt = null
			if OS.get_environment("FX_DIRECT") != "1":
				tgt = e2
				var ec2: Card3D = board._new_card(e2)
				ec2.transform = Transform3D(board.table_basis(1 - side, true, true), board.monster_zone_pos(1 - side, 3) + Vector3(0, 0.02, 0))
			print("ELEM ", who, " attr ", ElementFx.attr_of(e1), " tier ", ElementFx.tier_of(e1), " ranged ", ElementFx.ranged(e1), " kind ", StrikeFx.kind_of(e1))
			await scene.get_tree().create_timer(0.2).timeout
			await board.anim_declare(side, e1, tgt)
			if OS.get_environment("FX_GATHER") == "1":
				await scene.get_tree().create_timer(1.0).timeout
				return
			await board.anim_battle(side, e1, tgt)
			if tgt != null:
				await board.anim_destroy(tgt)
		"exodia":
			# FX_OPP=1: the opponent is the one who assembles it.
			var t0 := Time.get_ticks_msec()
			await ExodiaShow.play(scene, board, scene.hud, AI if OS.get_environment("FX_OPP") == "1" else ME)
			print("EXODIA took ", (Time.get_ticks_msec() - t0) * Engine.time_scale / 1000.0, " s of game time")
		"emblems":
			# Every emblem, in rows over the table, with the flourish of each kind under it.
			var ks: Array = CardFx.KINDS.keys()
			board.cam_shot(Vector3(0, 9.5, 5.2), Vector3(0, 0.6, -0.3), 0.2)
			await scene.get_tree().create_timer(0.4).timeout
			for i in ks.size():
				var col := i % 6
				var row := i / 6
				var at := Vector3(-4.0 + col * 1.6, 0.03, -2.6 + row * 1.5)
				CardFx.play(board, at, str(ks[i]), 1.0)
			await scene.get_tree().create_timer(1.2).timeout
		"cardfx":
			# FX_CARD = a Spell or Trap (default Change of Heart), played by you on their monster.
			var nm := OS.get_environment("FX_CARD") if OS.has_environment("FX_CARD") else "Change of Heart"
			var cs1 = _mk(st, nm, ME)
			var foe2 = _mk(st, "Gogogo Golem", AI)
			var fc: Card3D = board._new_card(foe2)
			fc.transform = Transform3D(board.table_basis(AI, true, true), board.monster_zone_pos(AI, 3) + Vector3(0, 0.02, 0))
			print("CARDFX ", nm, " -> ", CardFx.kind(cs1, ""))
			await scene._play([{"type": "activate", "player": ME, "card": cs1, "zone": 1, "label": ""},
				{"type": "targets", "player": ME, "cards": [foe2]},
				{"type": "lp", "player": AI, "lp": 7000, "delta": -1000},
				{"type": "lp", "player": ME, "lp": 9000, "delta": 1000},
				{"type": "chain_end"}])
		"win":
			# FX_KIND = destiny_board | countdown | deckout | card:<id>; FX_OPP=1: the opponent wins.
			await WinShow.play(scene, board, scene.hud, AI if OS.get_environment("FX_OPP") == "1" else ME, OS.get_environment("FX_KIND"))
		"fieldlooks":
			# Every Field Spell place, one after the other (film with a gap of 2.4 and FX_SKIP=2.2).
			board.cam_shot(Vector3(0.4, 3.6, 4.4), Vector3(0.2, 0, 0.4), 0.2)
			await scene.get_tree().create_timer(0.3).timeout
			for fk in FieldLooks.LOOKS.keys():
				var lk: Dictionary = (FieldLooks.LOOKS[fk] as Dictionary).duplicate()
				lk["key"] = fk
				lk["name"] = fk
				board.set_field_look(lk, board.field_pos(ME))
				await scene.get_tree().create_timer(2.4).timeout
		"fieldspell":
			# FX_CARD = a Field Spell (default Mountain): its place takes the field over. FX_ZOOM=1 looks closer.
			var fn := OS.get_environment("FX_CARD") if OS.has_environment("FX_CARD") else "Mountain"
			var fcard = _mk(st, fn, ME)
			board.set_field_look(FieldLooks.look_for(fcard), board.field_pos(ME))
			if OS.get_environment("FX_ZOOM") == "1":
				board.cam_shot(Vector3(0.5, 3.2, 3.6), Vector3(0.3, 0, 0.6), 0.3)
			await scene.get_tree().create_timer(6.0).timeout
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
