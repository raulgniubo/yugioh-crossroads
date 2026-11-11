class_name DuelAI
extends RefCounted
## Simple opponent. Each call returns the next action to take, or {} when done.
## Actions: {"do": "activate"|"summon"|"set"|"flip"|"position"|"attack", ...}


static func next_main_action(s: DuelState, p: int) -> Dictionary:
	var me := s.players[p]
	var opp := s.players[s.opponent(p)]
	# 1. Spells
	for c in me.hand:
		if c.is_monster() or not s.can_activate(p, c):
			continue
		match c.data.get("effect", ""):
			"draw2":
				return {"do": "activate", "card": c}
			"heal1000":
				if me.lp <= 6000:
					return {"do": "activate", "card": c}
			"fissure":
				return {"do": "activate", "card": c}
	var opp_best := _strongest_atk(opp)
	# 2. Flip set monsters that can now do something
	for m in me.monsters():
		if s.can_flip_summon(p, m) and (m.atk() > opp_best or opp.monsters().is_empty()):
			return {"do": "flip", "card": m}
	# 3. Normal summon or set
	if not s.normal_summoned:
		var plan := _best_summon(s, p, opp_best)
		if not plan.is_empty():
			return plan
	# 4. Position changes (main 1 only, before battle)
	if s.phase == DuelState.Phase.MAIN1:
		for m in me.monsters():
			if not s.can_change_position(p, m):
				continue
			if not m.attack_pos and m.atk() > opp_best:
				return {"do": "position", "card": m}
			if m.attack_pos and m.atk() < opp_best and m.def() > m.atk():
				return {"do": "position", "card": m}
	return {}


static func next_attack(s: DuelState, p: int) -> Dictionary:
	var opp := s.players[s.opponent(p)]
	for m in s.players[p].monsters():
		if not s.can_attack(p, m):
			continue
		if s.can_direct_attack(p):
			return {"do": "attack", "card": m, "target": null}
		var best: DuelState.CardInst = null
		var best_score := -1
		for t in opp.monsters():
			var score := -1
			if t.face_up and t.attack_pos and m.atk() > t.atk():
				score = 1000 + t.atk()
			elif t.face_up and not t.attack_pos and m.atk() > t.def():
				score = 500 + t.def()
			elif not t.face_up and m.atk() >= 1600:
				score = 100
			if score > best_score:
				best_score = score
				best = t
		if best != null:
			return {"do": "attack", "card": m, "target": best}
	return {}


static func _strongest_atk(ps: DuelState.PlayerState) -> int:
	var best := 0
	for m in ps.monsters():
		if m.face_up and m.attack_pos:
			best = maxi(best, m.atk())
	return best


static func _best_summon(s: DuelState, p: int, opp_best: int) -> Dictionary:
	var me := s.players[p]
	var options := []
	for c in me.hand:
		if not s.can_normal_summon(p, c):
			continue
		var need := s.tributes_needed(c)
		var tributes := _weakest(me, need)
		var lost := 0
		for t in tributes:
			lost += t.atk()
		# Only tribute when it's clearly worth it.
		if need > 0 and c.atk() < lost + 600:
			continue
		options.append({"card": c, "tributes": tributes})
	if options.is_empty():
		return {}
	options.sort_custom(func(a, b): return a["card"].atk() > b["card"].atk())
	var top: Dictionary = options[0]
	var card: DuelState.CardInst = top["card"]
	if card.atk() >= opp_best or s.players[s.opponent(p)].monsters().is_empty():
		return {"do": "summon", "card": card, "tributes": top["tributes"]}
	# Too weak to attack: set the best defender instead.
	options.sort_custom(func(a, b): return a["card"].def() > b["card"].def())
	return {"do": "set", "card": options[0]["card"], "tributes": options[0]["tributes"]}


static func _weakest(ps: DuelState.PlayerState, count: int) -> Array:
	var mons := ps.monsters()
	mons.sort_custom(func(a, b): return a.atk() < b.atk())
	return mons.slice(0, count)
