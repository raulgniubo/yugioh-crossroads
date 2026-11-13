class_name DuelAI
extends RefCounted
## Opponent brain with four levels.
##   0 Easy:   plays its best monster, attacks only when it clearly wins, makes mistakes.
##   1 Normal: sensible summons, spells and attacks.
##   2 Hard:   clears the strongest threats first with the smallest monster that wins,
##             plays around face-downs, saves removal for real threats, goes defensive
##             when behind, and sets up Synchro/Xyz/Fusion plays.
##   3 Expert: plans two plays ahead instead of one, tries every attack order on a copy of
##             the duel before committing, counts card advantage, and holds back when the
##             other side has face-downs waiting and nothing to gain by overextending.
## Each call returns the next action, or {} when done.
## Actions: {"do": "activate"|"summon"|"set"|"flip"|"position"|"attack"|"extra", ...}

const EASY := 0
const NORMAL := 1
const HARD := 2
const EXPERT := 3


## How each seat likes to play, set by the duel scene: "" (by the book), "aggro" (attacks into
## even trades and face-downs, summons in Attack), "wall" (sets when in doubt, attacks only
## when it clearly wins). The look-ahead levels decide on their own and ignore this.
static var styles: Array = ["", ""]


static func _style(p: int) -> String:
	return str(styles[p]) if p >= 0 and p < styles.size() else ""


static func next_main_action(s: DuelState, p: int, level := NORMAL) -> Dictionary:
	if s.turbo and level > EASY:
		var sw := _speed_world(s, p)
		if not sw.is_empty():
			return sw
	if level >= EXPERT:
		return _deep_main(s, p)
	if level >= HARD:
		return _lookahead_main(s, p)
	# Normal plays like the old Hard heuristics.
	if level == NORMAL:
		level = HARD
		return _heuristic_main(s, p, level)
	return _heuristic_main(s, p, level)


static func _heuristic_main(s: DuelState, p: int, level: int) -> Dictionary:
	var me := s.players[p]
	var opp := s.players[s.opponent(p)]
	var opp_best := _strongest_atk(opp)
	var my_best := _strongest_atk(me)
	if level == EASY and randf() < 0.12:
		return {}  # Easy sometimes just passes
	# 1. Spells
	var pool: Array = me.hand.duplicate()
	for st in me.spells:
		if st != null and not st.face_up:
			pool.append(st)
	var idle := -1e9
	for c in pool:
		if c.is_monster() or not s.can_activate(p, c):
			continue
		if not SpellRules.spec(c).has("legacy"):
			# Cards from the Spell/Trap table: play it if a quick look ahead says the board gets better.
			if idle < -1e8:
				idle = _score_after(s, p, {})
			if _score_after(s, p, {"do": "activate", "card": c}) > idle + 80.0:
				return {"do": "activate", "card": c}
			continue
		match c.data.get("effect", ""):
			"draw2", "swords":
				return {"do": "activate", "card": c}
			"mst":
				return {"do": "activate", "card": c}
			"heal1000":
				if me.lp <= (5000 if level == HARD else 6000):
					return {"do": "activate", "card": c}
			"fissure":
				var t := s._lowest_face_up(s.opponent(p))
				if level < HARD or t.atk() >= 1500 or t.atk() >= my_best:
					return {"do": "activate", "card": c}
			"raigeki":
				if level < HARD or opp.monsters().size() >= 2 or opp_best >= my_best:
					return {"do": "activate", "card": c}
			"reborn":
				var best := s._best_in_gy()
				if level < HARD or best.atk() >= 1800 or best.atk() > opp_best:
					return {"do": "activate", "card": c}
			"fusion":
				var opts := s.fusion_targets(p, c)
				var plan: Dictionary = opts[0]
				var lost := 0
				for m in plan["field"]:
					lost += m.atk()
				if plan["card"].atk() > lost or level == EASY:
					return {"do": "activate", "card": c, "choice": plan["card"]}
	# 2. Synchro / Xyz when it's an upgrade
	if level > EASY:
		var extra_sorted := me.extra.duplicate()
		extra_sorted.sort_custom(func(a, b): return a.atk() > b.atk())
		for x in extra_sorted:
			if not s.can_extra_summon(p, x):
				continue
			var mats: Array = s.extra_materials(p, x)[0]
			var mat_best := 0
			for m in mats:
				mat_best = maxi(mat_best, m.atk())
			if x.atk() > mat_best:
				return {"do": "extra", "card": x}
	# 3. Flip set monsters that can now do something
	for m in me.monsters():
		if s.can_flip_summon(p, m) and (m.atk() > opp_best or opp.monsters().is_empty()):
			return {"do": "flip", "card": m}
	# 4. Normal summon or set
	if not s.normal_summoned:
		var plan := _best_summon(s, p, opp_best, level)
		if not plan.is_empty():
			return plan
	# 4b. Special Summons from hand (Cyber Dragon, Bora, Gale...)
	for c in me.hand:
		if s.can_special_from_hand(p, c):
			return {"do": "special_hand", "card": c}
	# 4d. Monster effects on the field
	for m in me.monsters():
		if s.can_ignite(p, m):
			return {"do": "ignite", "card": m}
	# 4c. Set traps (and Mystical Space Typhoon / spells we're holding back)
	for c in me.hand:
		if c.is_trap() and s.can_set_st(p, c):
			return {"do": "set_st", "card": c}
	# 5. Position changes (before battle)
	if s.phase == DuelState.Phase.MAIN1 and level > EASY:
		for m in me.monsters():
			if not s.can_change_position(p, m):
				continue
			if not m.attack_pos and m.atk() > opp_best:
				return {"do": "position", "card": m}
			if m.attack_pos and m.atk() < opp_best and m.def() > m.atk():
				return {"do": "position", "card": m}
	return {}


static func next_attack(s: DuelState, p: int, level := NORMAL) -> Dictionary:
	var opp := s.players[s.opponent(p)]
	var attackers: Array = s.players[p].monsters().filter(func(m): return s.can_attack(p, m))
	if attackers.is_empty():
		return {}
	attackers.sort_custom(func(a, b): return s.atk_of(a, true) > s.atk_of(b, true))
	if s.can_direct_attack(p):
		return {"do": "attack", "card": attackers[0], "target": null}
	if level >= EXPERT:
		return _deep_attack(s, p, attackers)
	# Monsters that can go straight for the Life Points (Toons, Fane, Leghul...)
	for m in attackers:
		if s.can_direct_attack_with(p, m) and level > EASY:
			return {"do": "attack", "card": m, "target": null}
	var st := _style(p)
	if level == EASY:
		for m in attackers:
			for t in opp.monsters():
				if t.face_up and t.attack_pos and m.atk() > t.atk() + (300 if st != "aggro" else 0):
					return {"do": "attack", "card": m, "target": t}
				if st == "aggro" and not t.face_up and m.atk() >= 1500:
					return {"do": "attack", "card": m, "target": t}
		return {}
	var pick := _hard_attack(attackers, opp)
	if st == "aggro" and pick.is_empty():
		# Reckless: trade evenly, and swing at anything face-down.
		for m in attackers:
			for t in opp.monsters():
				if (t.face_up and t.attack_pos and m.atk() == t.atk() and m.atk() > 0) or (not t.face_up and m.atk() >= 1200):
					return {"do": "attack", "card": m, "target": t}
	elif st == "wall" and not pick.is_empty() and pick.get("target") != null:
		# Careful: leaves face-down monsters alone unless the attacker is big.
		var tg: DuelState.CardInst = pick["target"]
		if not tg.face_up and (pick["card"] as DuelState.CardInst).atk() < 1900:
			return {}
	return pick


static func _best_target(m: DuelState.CardInst, targets: Array, facedown_min: int) -> DuelState.CardInst:
	var best: DuelState.CardInst = null
	var best_score := -1
	for t in targets:
		var score := -1
		if t.face_up and t.attack_pos and m.atk() > t.atk():
			score = 1000 + t.atk()
		elif t.face_up and not t.attack_pos and m.atk() > t.def():
			score = 500 + t.def()
		elif not t.face_up and m.atk() >= facedown_min:
			score = 100
		if score > best_score:
			best_score = score
			best = t
	return best


## Kill the biggest threat with the smallest monster that still wins, so the
## stronger monsters stay free for the next target or a direct hit.
static func _hard_attack(attackers: Array, opp: DuelState.PlayerState) -> Dictionary:
	var targets: Array = opp.monsters()
	if not opp.set_cards().is_empty() and attackers.size() > 1:
		# Possible traps: lead with the weakest attacker that still does something.
		var weakest: Array = attackers.duplicate()
		weakest.sort_custom(func(a, b): return a.atk() < b.atk())
		for m in weakest:
			if targets.is_empty():
				return {"do": "attack", "card": m, "target": null}
			for t in targets:
				if t.face_up and m.atk() > (t.atk() if t.attack_pos else t.def()):
					return {"do": "attack", "card": m, "target": t}
	targets.sort_custom(func(a, b): return _threat(a) > _threat(b))
	for t in targets:
		if not t.face_up:
			continue
		var need: int = t.atk() if t.attack_pos else t.def()
		var pick: DuelState.CardInst = null
		for m in attackers:
			if m.atk() > need and (pick == null or m.atk() < pick.atk()):
				pick = m
		if pick != null:
			return {"do": "attack", "card": pick, "target": t}
	# Probe a face-down with the weakest monster that can afford a bounce.
	for t in targets:
		if not t.face_up:
			var probe: DuelState.CardInst = null
			for m in attackers:
				if m.atk() >= 1500 and (probe == null or m.atk() < probe.atk()):
					probe = m
			if probe != null:
				return {"do": "attack", "card": probe, "target": t}
	return {}


static func _threat(t: DuelState.CardInst) -> int:
	return t.atk() if t.face_up else 1200


static func _strongest_atk(ps: DuelState.PlayerState) -> int:
	var best := 0
	for m in ps.monsters():
		if m.face_up and m.attack_pos:
			best = maxi(best, m.atk())
	return best


static func _best_summon(s: DuelState, p: int, opp_best: int, level: int) -> Dictionary:
	var me := s.players[p]
	var options := []
	for c in me.hand:
		if not s.can_normal_summon(p, c) or me.no_summon_turn == s.turn:
			continue
		var need := s.tributes_needed(c)
		var tributes := _weakest(me, need)
		var lost := 0
		for t in tributes:
			lost += t.atk()
		var margin := 600 if level < HARD else 300
		var worth := c.atk() >= lost + margin or (level == HARD and c.atk() > opp_best and lost < opp_best)
		if need > 0 and not worth:
			continue
		options.append({"card": c, "tributes": tributes})
	if options.is_empty():
		return {}
	if level == EASY:
		var pick: Dictionary = options[randi() % options.size()]
		return {"do": "summon", "card": pick["card"], "tributes": pick["tributes"]}
	# A monster that unlocks a Synchro or Xyz Summon right away beats raw ATK.
	for o in options:
		if o["tributes"].is_empty() and _enables_extra(s, p, o["card"]):
			return {"do": "summon", "card": o["card"], "tributes": []}
	options.sort_custom(func(a, b): return a["card"].atk() > b["card"].atk())
	var top: Dictionary = options[0]
	var card: DuelState.CardInst = top["card"]
	var st := _style(p)
	var edge := 0 if st == "" else (-500 if st == "aggro" else 300)
	if card.atk() >= opp_best + edge or s.players[s.opponent(p)].monsters().is_empty():
		return {"do": "summon", "card": card, "tributes": top["tributes"]}
	# Too weak to attack: set the best defender instead.
	options.sort_custom(func(a, b): return a["card"].def() > b["card"].def())
	return {"do": "set", "card": options[0]["card"], "tributes": options[0]["tributes"]}


static func _weakest(ps: DuelState.PlayerState, count: int) -> Array:
	# Only monsters that may be Tributed for a Tribute Summon (Sheep Tokens may not).
	var mons := ps.monsters().filter(func(m): return not m.data.get("no_tribute_summon", false))
	mons.sort_custom(func(a, b): return a.atk() < b.atk())
	return mons.slice(0, count)


static func _enables_extra(s: DuelState, p: int, c: DuelState.CardInst) -> bool:
	var ps := s.players[p]
	var zone := ps.free_zone()
	if zone == -1:
		return false
	ps.field[zone] = c
	var was_up := c.face_up
	c.face_up = true
	var ok := false
	for x in ps.extra:
		if x.frame() in ["synchro", "xyz"] and not s.extra_materials(p, x).is_empty():
			ok = true
			break
	ps.field[zone] = null
	c.face_up = was_up
	return ok


# ------------------------------------------------------------------ lookahead (Hard)

## Try every legal main-phase action on a copy of the duel, play out a greedy
## battle phase, score the result, and pick the best. Returns {} if doing
## nothing (or attacking right away) scores best.
static func _lookahead_main(s: DuelState, p: int) -> Dictionary:
	var candidates := _candidates(s, p)
	var best_score := _score_after(s, p, {})
	var best := {}
	for act in candidates:
		var sc := _score_after(s, p, act)
		if sc > best_score + 50.0:
			best_score = sc
			best = act
	return best


## Turbo Duels: when to cash Speed Counters in on Speed World 2.
static func _speed_world(s: DuelState, p: int) -> Dictionary:
	var me := s.players[p]
	var opp := s.players[s.opponent(p)]
	var spells: int = me.hand.filter(func(c): return not c.is_monster() and not c.is_trap()).size()
	# Burn for the win, or when the hand is full of Speed Spells and there is speed to spare.
	if s.can_speed_world(p, 4) and (800 * spells >= opp.lp or (spells >= 2 and me.speed >= 8)):
		return {"do": "speed", "cost": 4}
	# Remove a monster that nothing on this side can beat.
	if s.can_speed_world(p, 10) and _strongest_atk(opp) > maxi(_strongest_atk(me), 1900):
		return {"do": "speed", "cost": 10}
	if s.can_speed_world(p, 7) and me.hand.size() <= 2 and me.speed >= 9:
		return {"do": "speed", "cost": 7}
	return {}


# ------------------------------------------------------------------ Expert

## Two plays ahead: score every first play, then for the best few try every follow-up, and
## take the first step of the best line. Finds lines Hard misses (tribute then revive, clear
## the way with a Spell and then summon, set a Trap before swinging).
static func _deep_main(s: DuelState, p: int) -> Dictionary:
	var candidates := _candidates(s, p)
	var base := _score_after(s, p, {}, true)
	if candidates.is_empty():
		return {}
	var scored := []
	for act in candidates:
		var sc := _score_after(s, p, act, true)
		if sc > -1e8:
			scored.append([sc, act])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var best_score := base
	var best := {}
	for i in mini(4, scored.size()):
		var first: Dictionary = scored[i][1]
		var line: float = scored[i][0]
		# Where does this play lead?
		var sim := s.clone()
		var ev := apply(sim, p, _map_action(sim, first))
		if not ev.is_empty() and not sim.is_over():
			for second in _candidates(sim, p):
				var sc2 := _score_after(sim, p, second, true)
				if sc2 > line:
					line = sc2
				# Extra Deck turns take three plays (two materials, then the summon): look one
				# step further whenever the second play puts a material on the field.
				if second["do"] in ["summon", "special_hand", "activate"] and not sim.players[p].extra.is_empty():
					var sim2 := sim.clone()
					if apply(sim2, p, _map_action(sim2, second)).is_empty() or sim2.is_over():
						continue
					for x in sim2.players[p].extra:
						if sim2.can_extra_summon(p, x):
							var sc3 := _score_after(sim2, p, {"do": "extra", "card": x}, true)
							if sc3 > line:
								line = sc3
			# Then keep playing the best follow-up for as long as the position keeps improving:
			# this is what finds the four and five card turns.
			var roll := sim
			var depth := 0
			while depth < 3 and not roll.is_over():
				depth += 1
				var top := line
				var pick := {}
				for nxt in _candidates(roll, p):
					var scn := _score_after(roll, p, nxt, true)
					if scn > top + 1.0:
						top = scn
						pick = nxt
				if pick.is_empty():
					break
				var nxt_sim := roll.clone()
				if apply(nxt_sim, p, _map_action(nxt_sim, pick)).is_empty():
					break
				roll = nxt_sim
				line = top
		if line > best_score + 40.0:
			best_score = line
			best = first
	return best


## Try every attacker and target on a copy of the duel, let the rest of the battle and the
## opponent's answer play out, and keep the attack that leaves the best position. Holding
## back is an option too.
static func _deep_attack(s: DuelState, p: int, attackers: Array) -> Dictionary:
	var o := s.opponent(p)
	var best := {}
	var best_score := _after_battle(s.clone(), p, true)
	var traps: int = s.players[o].set_cards().filter(func(c): return not c.face_up).size()
	for m in attackers:
		var targets: Array = [null] if s.can_direct_attack_with(p, m) else []
		for t in s.players[o].monsters():
			targets.append(t)
		for t in targets:
			var sim := s.clone()
			var a = sim.find_uid(m.uid)
			var tt = sim.find_uid(t.uid) if t != null else null
			if a == null or (t != null and tt == null):
				continue
			# A face-down could be anything: assume a solid wall, not the best case.
			if tt != null and not tt.face_up and sim.atk_of(a, true) < 1900 and sim.players[p].lp <= 2500:
				continue
			var ev := sim.attack(p, a, tt)
			if ev.is_empty():
				continue
			var sc := _after_battle(sim, p, false)
			# Face-down Spells and Traps: the first attack of the turn is the one that walks into
			# them, so lead with the monster this side can best afford to lose. Once an attack
			# has gone through untouched, the rest are much safer.
			if traps > 0 and not sim.is_over():
				var risk := (1.0 - pow(0.62, float(traps))) * (1.0 if s.players[p].attacks_this_turn == 0 or s.players[p].attacks_turn != s.turn else 0.35)
				sc -= risk * (float(m.atk()) * 0.9 + 420.0) * 0.55
			if sc > best_score + 20.0:
				best_score = sc
				best = {"do": "attack", "card": m, "target": t}
	return best


## Finish the Battle Phase greedily (unless `stop`), let the other side swing back, and score.
static func _after_battle(sim: DuelState, p: int, stop: bool) -> float:
	var guard := 0
	while not stop and guard < 10 and not sim.is_over():
		guard += 1
		var attackers: Array = sim.players[p].monsters().filter(func(m): return sim.can_attack(p, m))
		if attackers.is_empty():
			break
		attackers.sort_custom(func(a, b): return sim.atk_of(a, true) > sim.atk_of(b, true))
		var a: Dictionary = {"do": "attack", "card": attackers[0], "target": null} if sim.can_direct_attack(p) else _hard_attack(attackers, sim.players[sim.opponent(p)])
		if a.is_empty():
			break
		if sim.attack(p, a["card"], a["target"]).is_empty():
			break
	return _reply_and_score(sim, p)


static func _candidates(s: DuelState, p: int) -> Array:
	var out := []
	var me := s.players[p]
	for c in me.hand:
		if not c.is_monster():
			if s.can_activate(p, c):
				if c.data.get("effect", "") == "fusion":
					for o in s.fusion_targets(p, c):
						out.append({"do": "activate", "card": c, "choice": o["card"]})
				else:
					out.append({"do": "activate", "card": c})
			continue
		if s.can_normal_summon(p, c):
			var need := s.tributes_needed(c)
			var tributes := _weakest(me, need)
			if me.no_summon_turn != s.turn:
				out.append({"do": "summon", "card": c, "tributes": tributes})
			out.append({"do": "set", "card": c, "tributes": tributes})
	for c in me.spells:
		if c != null and not c.face_up and s.can_activate(p, c):
			out.append({"do": "activate", "card": c})
	for x in me.extra:
		if s.can_extra_summon(p, x):
			out.append({"do": "extra", "card": x})
	for c in me.hand:
		if (c.is_trap() or SpellRules.kind(c) == "quick") and s.can_set_st(p, c):
			out.append({"do": "set_st", "card": c})
		if s.can_special_from_hand(p, c):
			out.append({"do": "special_hand", "card": c})
	for m in me.monsters():
		if s.can_ignite(p, m):
			out.append({"do": "ignite", "card": m})
		if s.can_flip_summon(p, m):
			out.append({"do": "flip", "card": m})
		if s.can_change_position(p, m):
			out.append({"do": "position", "card": m})
	return out


static func _score_after(s: DuelState, p: int, act: Dictionary, expert := false) -> float:
	var sim := s.clone()
	if not act.is_empty():
		var ev := apply(sim, p, _map_action(sim, act))
		if ev.is_empty():
			return -1e9
	# Play out a greedy battle if it's still Main Phase 1.
	if sim.can_enter_battle() and not sim.is_over():
		sim.enter_battle()
		var guard := 0
		while guard < 10 and not sim.is_over():
			guard += 1
			var a := next_attack(sim, p, HARD)
			if a.is_empty():
				break
			sim.attack(p, a["card"], a["target"])
	if expert:
		return _reply_and_score(sim, p)
	# Let the opponent swing back with what's already on their field.
	if not sim.is_over():
		var o := sim.opponent(p)
		sim.current = o
		sim.turn += 1
		sim.phase = DuelState.Phase.BATTLE
		var guard2 := 0
		while guard2 < 10 and not sim.is_over():
			guard2 += 1
			var b := next_attack(sim, o, HARD)
			if b.is_empty():
				break
			sim.attack(o, b["card"], b["target"])
	return _evaluate(sim, p, expert)


## Expert only: play the other side's whole next turn (draw, plays, attacks) the way a strong
## opponent would, then score what is left. This is what lets Expert see a counterattack coming.
static func _reply_and_score(sim: DuelState, p: int) -> float:
	if sim.is_over():
		return _evaluate(sim, p, true)
	var o := sim.opponent(p)
	sim.manual = [false, false]
	sim.end_turn()
	if not sim.is_over():
		sim.current = o
		sim.begin_turn()
	if not sim.is_over():
		sim.phase = DuelState.Phase.MAIN1
		var guard := 0
		while guard < 6 and not sim.is_over():
			guard += 1
			var a := _heuristic_main(sim, o, HARD)
			if a.is_empty() or apply(sim, o, a).is_empty():
				break
	if not sim.is_over() and sim.can_enter_battle():
		sim.enter_battle()
		var guard2 := 0
		while guard2 < 10 and not sim.is_over():
			guard2 += 1
			var b := next_attack(sim, o, HARD)
			if b.is_empty() or sim.attack(o, b["card"], b["target"]).is_empty():
				break
	return _evaluate(sim, p, true)


static func _map_action(sim: DuelState, act: Dictionary) -> Dictionary:
	var m := act.duplicate()
	for k in ["card", "choice"]:
		if m.get(k) != null:
			m[k] = sim.find_uid(m[k].uid)
	if m.has("tributes"):
		var t := []
		for c in m["tributes"]:
			t.append(sim.find_uid(c.uid))
		m["tributes"] = t
	return m


static func apply(s: DuelState, p: int, act: Dictionary) -> Array:
	match act["do"]:
		"activate":
			return s.activate(p, act["card"], act.get("choice"))
		"extra":
			return s.extra_summon(p, act["card"])
		"summon":
			return s.normal_summon(p, act["card"], act["tributes"], false)
		"set":
			return s.normal_summon(p, act["card"], act["tributes"], true)
		"flip":
			return s.flip_summon(p, act["card"])
		"position":
			return s.change_position(p, act["card"])
		"set_st":
			return s.set_st(p, act["card"])
		"special_hand":
			return s.special_from_hand(p, act["card"])
		"ignite":
			return s.ignite(p, act["card"])
		"speed":
			return s.speed_world(p, int(act["cost"]))
	return []


## Data-driven Spell/Trap cards: try each on a copy of the duel and keep the one that helps most.
static func _sim_response(s: DuelState, p: int, window: String, options: Array) -> DuelState.CardInst:
	var base := _sim_score(s, p, window, null)
	var best: DuelState.CardInst = null
	var best_gain := 140.0
	for c in options:
		if c.is_monster() or SpellRules.spec(c).has("legacy") or SpellRules.spec(c).is_empty():
			continue
		var gain := _sim_score(s, p, window, c) - base
		if gain > best_gain:
			best_gain = gain
			best = c
	return best


static func _sim_score(s: DuelState, p: int, window: String, c) -> float:
	var sim := s.clone()
	if c != null:
		var subj = sim.chain.back() if not sim.chain.is_empty() else sim.last_summoned
		if sim.chain_add(p, sim.find_uid(c.uid), null, window, subj).is_empty():
			return -1e9
	sim.chain_resolve()
	if not sim.pending_attack.is_empty():
		sim.resolve_attack()
	return _evaluate(sim, p)


## Should player p use a response card? Returns the card or null.
static func choose_response(s: DuelState, p: int, window: String, options: Array, level := NORMAL) -> DuelState.CardInst:
	if options.is_empty() or (level == EASY and randf() < 0.4):
		return null
	var sim_pick := _sim_response(s, p, window, options)
	if sim_pick != null:
		return sim_pick
	if window != "attack" and window != "summon":
		return null
	var me := s.players[p]
	if window == "attack":
		var att: DuelState.CardInst = s.pending_attack["attacker"]
		var target = s.pending_attack["target"]
		var opp := s.players[s.opponent(p)]
		var attackers_up := 0
		for m in opp.monsters():
			if m.attack_pos:
				attackers_up += 1
		# How bad is this attack if we let it through?
		var dmg := 0
		var lose_monster := false
		if target == null:
			dmg = att.atk()
		elif target.face_up and target.attack_pos:
			dmg = maxi(0, att.atk() - target.atk())
			lose_monster = att.atk() > target.atk()
		else:
			lose_monster = att.atk() > target.def()
		var bad := dmg >= 1000 or lose_monster or dmg >= me.lp
		for c in options:
			match c.data.get("effect", c.cname()):
				"mirror_force":
					if attackers_up >= 2 or (bad and att.atk() >= 1800):
						return c
				"magic_cylinder":
					if att.atk() >= 1500:
						return c
				"sakuretsu":
					if att.atk() >= 1600 or bad:
						return c
		for c in options:
			var e: String = c.data.get("effect", "")
			if c.cname() == "Number 39: Utopia" and bad:
				return c
			if c.cname() == "Kuriboh" and dmg >= 1500:
				return c
			if e in ["negate_attack", "waboku"] and (dmg >= 1500 or lose_monster or dmg >= me.lp):
				return c
		return null
	if window == "summon":
		var subj: DuelState.CardInst = s.last_summoned
		for c in options:
			match c.data.get("effect", ""):
				"trap_hole", "bottomless":
					if subj and subj.atk() >= 1700:
						return c
				"torrential":
					if s.players[s.opponent(p)].monsters().size() > me.monsters().size():
						return c
	return null


## Board + life point evaluation from player p's point of view.
static func _evaluate(s: DuelState, p: int, expert := false) -> float:
	if s.is_over():
		return 1e8 if s.winner == p else -1e8
	var o := s.opponent(p)
	if expert:
		return _evaluate_expert(s, p, o)
	var score := float(s.players[p].lp) * 0.8 - float(s.players[o].lp) * 1.3
	score += _board(s.players[p]) - _board(s.players[o])
	score += 150.0 * (s.players[p].hand.size() - s.players[o].hand.size())
	score += 400.0 * (s.players[p].set_cards().size() - s.players[o].set_cards().size())
	return score


## Expert's view of a position: cards matter more than Life Points until Life Points get
## low, a monster is worth what it can beat, and cards in hand are worth keeping.
static func _evaluate_expert(s: DuelState, p: int, o: int) -> float:
	var me := s.players[p]
	var opp := s.players[o]
	var score := 0.0
	# Life Points: every point counts double once you are in range of one big hit.
	score += _lp_value(me.lp) - _lp_value(opp.lp) * 1.15
	var my_best := 0
	var opp_best := 0
	for m in me.monsters():
		my_best = maxi(my_best, m.atk() if m.attack_pos else 0)
	for m in opp.monsters():
		opp_best = maxi(opp_best, m.atk() if (m.face_up and m.attack_pos) else 0)
	for m in me.monsters():
		var v := float(maxi(m.atk(), m.def())) * 0.9 + 420.0 + 220.0 * m.overlays.size()
		# A monster that would just be run over next turn is worth less.
		if m.attack_pos and m.atk() < opp_best:
			v *= 0.55
		score += v
	for m in opp.monsters():
		var v2 := float(maxi(m.atk(), m.def())) * 0.9 + 420.0 + 220.0 * m.overlays.size()
		if m.face_up and m.attack_pos and m.atk() < my_best:
			v2 *= 0.55
		score -= v2 * 1.05
	score += 330.0 * (me.hand.size() - opp.hand.size())
	score += 450.0 * me.set_cards().size() - 520.0 * opp.set_cards().size()
	# Their face-downs could be a Mirror Force or a Torrential Tribute: a third and fourth
	# attacker on the field is mostly something to lose.
	var hidden: int = opp.set_cards().filter(func(c): return not c.face_up).size()
	if hidden > 0:
		var out := 0
		for m in me.monsters():
			if m.attack_pos:
				out += 1
				if out > 2:
					score -= (float(m.atk()) * 0.9 + 420.0) * 0.22 * minf(2.0, float(hidden))
	# An empty field against attackers is an emergency.
	if me.monsters().is_empty() and not opp.monsters().is_empty():
		score -= 900.0
	if opp.monsters().is_empty() and not me.monsters().is_empty():
		score += 500.0
	return score


static func _lp_value(lp: int) -> float:
	var v := float(lp) * 0.7
	if lp <= 3000:
		v -= float(3000 - lp) * 0.9
	return v


static func _board(ps: DuelState.PlayerState) -> float:
	var v := 0.0
	for m in ps.monsters():
		v += float(maxi(m.atk(), m.def())) * 0.9 + 300.0
		v += 200.0 * m.overlays.size()
	return v
