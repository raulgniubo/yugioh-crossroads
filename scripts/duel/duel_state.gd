class_name DuelState
extends RefCounted
## Pure duel rules, no visuals. Every action returns a list of events
## that the board plays back as animations.
##
## Prototype rules: Normal Monsters plus a few Normal Spells. Draw, Main 1,
## Battle, Main 2, End. One Normal Summon or Set per turn, tributes for
## Level 5+, flip summons, position changes, direct attacks and damage.

enum Phase { DRAW, MAIN1, BATTLE, MAIN2, END }

const START_LP := 8000
const HAND_LIMIT := 6
const ZONES := 5


class CardInst:
	extends RefCounted
	var uid: int
	var id: int
	var data: Dictionary
	var owner: int
	var face_up := true
	var attack_pos := true
	var summoned_turn := -1
	var pos_changed_turn := -1
	var attacked_turn := -1
	var overlays: Array = []

	func is_monster() -> bool:
		return data.get("kind", "monster") == "monster"

	func atk() -> int:
		return int(data.get("atk", 0))

	func def() -> int:
		return int(data.get("def", 0))

	func level() -> int:
		return int(data.get("level", 0))

	func frame() -> String:
		return str(data.get("frame", "normal"))

	func is_tuner() -> bool:
		return bool(data.get("tuner", false))


class PlayerState:
	extends RefCounted
	var name := ""
	var lp := START_LP
	var deck: Array[CardInst] = []
	var hand: Array[CardInst] = []
	var gy: Array[CardInst] = []
	var extra: Array[CardInst] = []
	var field: Array = [null, null, null, null, null]

	func monsters() -> Array[CardInst]:
		var out: Array[CardInst] = []
		for c in field:
			if c != null:
				out.append(c)
		return out

	func free_zone() -> int:
		return field.find(null)


var players: Array[PlayerState] = []
var current := 0
var turn := 0
var phase := Phase.DRAW
var normal_summoned := false
var winner := -1
var win_reason := ""
var _uid := 0
## Extra cards in the opening hand (Hard mode gives the AI +1).
var bonus_cards := [0, 0]
var _rng := RandomNumberGenerator.new()


func setup(deck_a: Array[int], deck_b: Array[int], name_a: String, name_b: String, first := 0, seed := -1,
		extra_a: Array[int] = [], extra_b: Array[int] = []) -> Array:
	if seed >= 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	players = [PlayerState.new(), PlayerState.new()]
	players[0].name = name_a
	players[1].name = name_b
	for i in 2:
		var ids: Array[int] = deck_a if i == 0 else deck_b
		for id in ids:
			players[i].deck.append(_make(id, i))
		_shuffle(players[i].deck)
		for id in (extra_a if i == 0 else extra_b):
			players[i].extra.append(_make(id, i))
	current = first
	turn = 0
	var events := [{"type": "start"}]
	for i in 2:
		for n in 5 + bonus_cards[i]:
			events.append_array(_draw(i))
	return events


func _make(id: int, owner: int) -> CardInst:
	_uid += 1
	var c := CardInst.new()
	c.uid = _uid
	c.id = id
	c.data = CardData.get_card(id)
	c.owner = owner
	return c


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func opponent(p: int) -> int:
	return 1 - p


func is_over() -> bool:
	return winner != -1


# ------------------------------------------------------------------ turn flow

func begin_turn() -> Array:
	turn += 1
	normal_summoned = false
	phase = Phase.DRAW
	var events := [{"type": "turn", "player": current, "turn": turn}, {"type": "phase", "phase": phase}]
	if turn > 1:
		events.append_array(_draw(current))
		if is_over():
			return events
	phase = Phase.MAIN1
	events.append({"type": "phase", "phase": phase})
	return events


func can_enter_battle() -> bool:
	return phase == Phase.MAIN1 and turn > 1


func enter_battle() -> Array:
	if not can_enter_battle():
		return []
	phase = Phase.BATTLE
	return [{"type": "phase", "phase": phase}]


func enter_main2() -> Array:
	if phase != Phase.BATTLE:
		return []
	phase = Phase.MAIN2
	return [{"type": "phase", "phase": phase}]


func end_turn() -> Array:
	phase = Phase.END
	var events := [{"type": "phase", "phase": phase}]
	var ps := players[current]
	while ps.hand.size() > HAND_LIMIT:
		# Prototype: discard the weakest card automatically.
		var worst := ps.hand[0]
		for c in ps.hand:
			if _card_value(c) < _card_value(worst):
				worst = c
		ps.hand.erase(worst)
		ps.gy.append(worst)
		events.append({"type": "discard", "player": current, "card": worst})
	current = opponent(current)
	return events


func _card_value(c: CardInst) -> int:
	return c.atk() + c.def() / 2 if c.is_monster() else 1500


func _draw(p: int, count := 1) -> Array:
	var events := []
	for i in count:
		var ps := players[p]
		if ps.deck.is_empty():
			_set_winner(opponent(p), "%s has no cards left to draw." % ps.name)
			events.append({"type": "win", "player": winner, "reason": win_reason})
			return events
		var c: CardInst = ps.deck.pop_back()
		ps.hand.append(c)
		events.append({"type": "draw", "player": p, "card": c, "deck": ps.deck.size()})
	return events


func _set_winner(p: int, reason: String) -> void:
	if winner == -1:
		winner = p
		win_reason = reason


func _in_main() -> bool:
	return phase == Phase.MAIN1 or phase == Phase.MAIN2


# ------------------------------------------------------------------ summoning

func tributes_needed(c: CardInst) -> int:
	if c.level() >= 7:
		return 2
	if c.level() >= 5:
		return 1
	return 0


func can_normal_summon(p: int, c: CardInst) -> bool:
	if p != current or not _in_main() or normal_summoned or is_over():
		return false
	if not c.is_monster() or not players[p].hand.has(c):
		return false
	var need := tributes_needed(c)
	var mons := players[p].monsters().size()
	if need == 0:
		return mons < ZONES
	return mons >= need


func normal_summon(p: int, c: CardInst, tributes: Array, set_card := false) -> Array:
	if not can_normal_summon(p, c) or tributes.size() != tributes_needed(c):
		return []
	var ps := players[p]
	var events := []
	for t in tributes:
		var idx := ps.field.find(t)
		if idx == -1:
			return []
	for t in tributes:
		ps.field[ps.field.find(t)] = null
		ps.gy.append(t)
		events.append({"type": "tribute", "player": p, "card": t})
	var zone := ps.free_zone()
	ps.hand.erase(c)
	ps.field[zone] = c
	c.face_up = not set_card
	c.attack_pos = not set_card
	c.summoned_turn = turn
	c.pos_changed_turn = -1
	c.attacked_turn = -1
	normal_summoned = true
	events.append({"type": "set" if set_card else "summon", "player": p, "card": c, "zone": zone})
	return events


func can_flip_summon(p: int, c: CardInst) -> bool:
	return (p == current and _in_main() and not is_over() and players[p].field.has(c)
			and not c.face_up and c.summoned_turn != turn and c.pos_changed_turn != turn)


func flip_summon(p: int, c: CardInst) -> Array:
	if not can_flip_summon(p, c):
		return []
	c.face_up = true
	c.attack_pos = true
	c.pos_changed_turn = turn
	return [{"type": "flip", "player": p, "card": c, "zone": players[p].field.find(c)}]


func can_change_position(p: int, c: CardInst) -> bool:
	return (p == current and _in_main() and not is_over() and players[p].field.has(c)
			and c.face_up and c.summoned_turn != turn and c.pos_changed_turn != turn
			and c.attacked_turn != turn)


func change_position(p: int, c: CardInst) -> Array:
	if not can_change_position(p, c):
		return []
	c.attack_pos = not c.attack_pos
	c.pos_changed_turn = turn
	return [{"type": "position", "player": p, "card": c, "zone": players[p].field.find(c)}]


# ------------------------------------------------------------------ spells

func can_activate(p: int, c: CardInst) -> bool:
	if p != current or not _in_main() or is_over() or c.is_monster() or not players[p].hand.has(c):
		return false
	match c.data.get("effect", ""):
		"draw2":
			return players[p].deck.size() >= 2
		"fissure":
			return _lowest_face_up(opponent(p)) != null
		"raigeki":
			return not players[opponent(p)].monsters().is_empty()
		"darkhole":
			return not players[0].monsters().is_empty() or not players[1].monsters().is_empty()
		"fusion":
			return not fusion_targets(p, c).is_empty()
		"reborn":
			return _best_in_gy() != null and players[p].free_zone() != -1
	return true


func activate(p: int, c: CardInst, choice: CardInst = null) -> Array:
	if not can_activate(p, c):
		return []
	var ps := players[p]
	var fusion_plan := {}
	if c.data.get("effect", "") == "fusion":
		var options := fusion_targets(p, c)
		for o in options:
			if choice == null or o["card"] == choice:
				fusion_plan = o
				break
		if fusion_plan.is_empty():
			return []
	ps.hand.erase(c)
	var events := [{"type": "activate", "player": p, "card": c}]
	match c.data.get("effect", ""):
		"draw2":
			events.append_array(_draw(p, 2))
		"heal1000":
			ps.lp += 1000
			events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": 1000})
		"fissure":
			var target := _lowest_face_up(opponent(p))
			if target:
				events.append_array(_destroy(target))
		"raigeki":
			for m in players[opponent(p)].monsters():
				events.append_array(_destroy(m))
		"darkhole":
			for q in 2:
				for m in players[q].monsters():
					events.append_array(_destroy(m))
		"burn500":
			events.append_array(_damage(opponent(p), 500))
		"fusion":
			events.append_array(_do_fusion(p, fusion_plan))
		"reborn":
			var revive := _best_in_gy()
			if revive:
				players[revive.owner].gy.erase(revive)
				revive.owner = p
				events.append_array(_special(p, revive, "reborn"))
	ps.gy.append(c)
	events.append({"type": "spell_done", "player": p, "card": c})
	return events


func _lowest_face_up(p: int) -> CardInst:
	var best: CardInst = null
	for m in players[p].monsters():
		if m.face_up and (best == null or m.atk() < best.atk()):
			best = m
	return best


# ------------------------------------------------------------------ battle

func can_attack(p: int, c: CardInst) -> bool:
	return (p == current and phase == Phase.BATTLE and not is_over() and players[p].field.has(c)
			and c.face_up and c.attack_pos and c.attacked_turn != turn)


func can_direct_attack(p: int) -> bool:
	return players[opponent(p)].monsters().is_empty()


func attack_targets(p: int) -> Array[CardInst]:
	return players[opponent(p)].monsters()


func attack(p: int, attacker: CardInst, target: CardInst) -> Array:
	if not can_attack(p, attacker):
		return []
	var opp := opponent(p)
	if target == null and not can_direct_attack(p):
		return []
	if target != null and not players[opp].field.has(target):
		return []
	attacker.attacked_turn = turn
	var events := [{"type": "attack", "player": p, "card": attacker, "target": target}]
	if target == null:
		events.append_array(_damage(opp, attacker.atk()))
		return events
	if not target.face_up:
		target.face_up = true
		events.append({"type": "reveal", "player": opp, "card": target, "zone": players[opp].field.find(target)})
	var a := attacker.atk()
	if target.attack_pos:
		var t := target.atk()
		if a > t:
			events.append_array(_destroy(target))
			events.append_array(_damage(opp, a - t))
		elif a < t:
			events.append_array(_destroy(attacker))
			events.append_array(_damage(p, t - a))
		elif a > 0:
			events.append_array(_destroy(attacker))
			events.append_array(_destroy(target))
	else:
		var d := target.def()
		if a > d:
			events.append_array(_destroy(target))
		elif a < d:
			events.append_array(_damage(p, d - a))
	return events


func _destroy(c: CardInst) -> Array:
	var ps := players[c.owner]
	var zone := ps.field.find(c)
	if zone == -1:
		return []
	ps.field[zone] = null
	ps.gy.append(c)
	var events := [{"type": "destroy", "player": c.owner, "card": c, "zone": zone, "overlays": c.overlays.duplicate()}]
	for o in c.overlays:
		ps.gy.append(o)
	c.overlays.clear()
	return events


func _damage(p: int, amount: int) -> Array:
	if amount <= 0:
		return []
	var ps := players[p]
	ps.lp = maxi(0, ps.lp - amount)
	var events := [{"type": "lp", "player": p, "lp": ps.lp, "delta": -amount}]
	if ps.lp == 0:
		_set_winner(opponent(p), "%s's Life Points hit zero." % ps.name)
		events.append({"type": "win", "player": winner, "reason": win_reason})
	return events


# ------------------------------------------------------------------ special summons

func _best_in_gy() -> CardInst:
	var best: CardInst = null
	for ps in players:
		for c in ps.gy:
			if c.is_monster() and (best == null or c.atk() > best.atk()):
				best = c
	return best


func _special(p: int, c: CardInst, method: String) -> Array:
	var ps := players[p]
	var zone := ps.free_zone()
	if zone == -1:
		ps.gy.append(c)
		return []
	ps.field[zone] = c
	c.face_up = true
	c.attack_pos = true
	c.summoned_turn = turn
	c.pos_changed_turn = -1
	c.attacked_turn = -1
	return [{"type": "special", "player": p, "card": c, "zone": zone, "method": method}]


## Every Fusion Monster that can be made right now with Polymerization `poly`.
## Each option: {"card", "hand": [materials], "field": [materials]}
func fusion_targets(p: int, poly: CardInst = null) -> Array:
	var ps := players[p]
	var out := []
	for f in ps.extra:
		if f.frame() != "fusion":
			continue
		var pool_hand: Array = ps.hand.duplicate()
		if poly:
			pool_hand.erase(poly)
		var pool_field: Array = ps.monsters()
		var used_hand := []
		var used_field := []
		var ok := true
		var mats := CardData.fusion_materials(f.data)
		if mats.is_empty():
			continue
		for mid in mats:
			var found = null
			for h in pool_hand:
				if h.id == mid:
					found = h
					break
			if found:
				pool_hand.erase(found)
				used_hand.append(found)
				continue
			for m in pool_field:
				if m.id == mid:
					found = m
					break
			if found:
				pool_field.erase(found)
				used_field.append(found)
				continue
			ok = false
			break
		if not ok:
			continue
		if used_field.is_empty() and ps.free_zone() == -1:
			continue
		out.append({"card": f, "hand": used_hand, "field": used_field})
	out.sort_custom(func(a, b): return a["card"].atk() > b["card"].atk())
	return out


func _do_fusion(p: int, plan: Dictionary) -> Array:
	var ps := players[p]
	var events := []
	for m in plan["hand"]:
		ps.hand.erase(m)
		ps.gy.append(m)
		events.append({"type": "material", "player": p, "card": m, "from": "hand"})
	for m in plan["field"]:
		var z := ps.field.find(m)
		ps.field[z] = null
		ps.gy.append(m)
		events.append({"type": "material", "player": p, "card": m, "from": "field", "zone": z})
	var f: CardInst = plan["card"]
	ps.extra.erase(f)
	events.append_array(_special(p, f, "fusion"))
	return events


## Material sets for a Synchro or Xyz monster, best (cheapest) first.
func extra_materials(p: int, c: CardInst) -> Array:
	var mons: Array = []
	for m in players[p].monsters():
		if m.face_up:
			mons.append(m)
	var out := []
	if c.frame() == "xyz":
		var same := mons.filter(func(m): return m.level() == c.level() and m.frame() not in ["xyz"])
		if same.size() >= 2:
			same.sort_custom(func(a, b): return a.atk() < b.atk())
			out.append(same.slice(0, 2))
	elif c.frame() == "synchro":
		var n := mons.size()
		for mask in range(1, 1 << n):
			var sel := []
			for i in n:
				if mask & (1 << i):
					sel.append(mons[i])
			var tuners := sel.filter(func(m): return m.is_tuner())
			if tuners.size() != 1 or sel.size() < 2:
				continue
			var total := 0
			for m in sel:
				total += m.level()
			if total == c.level():
				out.append(sel)
		out.sort_custom(func(a, b): return _sum_atk(a) < _sum_atk(b))
	return out


func _sum_atk(arr: Array) -> int:
	var t := 0
	for m in arr:
		t += m.atk()
	return t


func can_extra_summon(p: int, c: CardInst) -> bool:
	if p != current or not _in_main() or is_over() or not players[p].extra.has(c):
		return false
	if c.frame() != "synchro" and c.frame() != "xyz":
		return false
	return not extra_materials(p, c).is_empty()


func extra_summon(p: int, c: CardInst, materials: Array = []) -> Array:
	if not can_extra_summon(p, c):
		return []
	if materials.is_empty():
		materials = extra_materials(p, c)[0]
	var ps := players[p]
	var events := []
	var xyz := c.frame() == "xyz"
	for m in materials:
		var z := ps.field.find(m)
		if z == -1:
			return []
	for m in materials:
		var z := ps.field.find(m)
		ps.field[z] = null
		if xyz:
			c.overlays.append(m)
		else:
			ps.gy.append(m)
		events.append({"type": "material", "player": p, "card": m, "from": "field", "zone": z, "overlay": xyz})
	ps.extra.erase(c)
	events.append_array(_special(p, c, c.frame()))
	return events


# ------------------------------------------------------------------ simulation helpers (AI)

## Deep copy for lookahead. Cards keep their uid so actions can be mapped across.
func clone() -> DuelState:
	var s := DuelState.new()
	var map := {}
	s.players = []
	for ps in players:
		var np := PlayerState.new()
		np.name = ps.name
		np.lp = ps.lp
		for c in ps.deck:
			np.deck.append(_clone_card(c, map))
		for c in ps.hand:
			np.hand.append(_clone_card(c, map))
		for c in ps.gy:
			np.gy.append(_clone_card(c, map))
		for c in ps.extra:
			np.extra.append(_clone_card(c, map))
		np.field = []
		for c in ps.field:
			np.field.append(_clone_card(c, map) if c != null else null)
		s.players.append(np)
	s.current = current
	s.turn = turn
	s.phase = phase
	s.normal_summoned = normal_summoned
	s.winner = winner
	s.win_reason = win_reason
	s._uid = _uid
	s._rng.seed = _rng.seed
	s._rng.state = _rng.state
	return s


func _clone_card(c: CardInst, map: Dictionary) -> CardInst:
	if map.has(c.uid):
		return map[c.uid]
	var n := CardInst.new()
	n.uid = c.uid
	n.id = c.id
	n.data = c.data
	n.owner = c.owner
	n.face_up = c.face_up
	n.attack_pos = c.attack_pos
	n.summoned_turn = c.summoned_turn
	n.pos_changed_turn = c.pos_changed_turn
	n.attacked_turn = c.attacked_turn
	map[c.uid] = n
	for o in c.overlays:
		n.overlays.append(_clone_card(o, map))
	return n


func find_uid(uid: int) -> CardInst:
	for ps in players:
		for list in [ps.hand, ps.deck, ps.gy, ps.extra]:
			for c in list:
				if c.uid == uid:
					return c
		for c in ps.field:
			if c != null and c.uid == uid:
				return c
	return null
