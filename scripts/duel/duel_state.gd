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

	func is_monster() -> bool:
		return data.get("kind", "monster") == "monster"

	func atk() -> int:
		return int(data.get("atk", 0))

	func def() -> int:
		return int(data.get("def", 0))

	func level() -> int:
		return int(data.get("level", 0))


class PlayerState:
	extends RefCounted
	var name := ""
	var lp := START_LP
	var deck: Array[CardInst] = []
	var hand: Array[CardInst] = []
	var gy: Array[CardInst] = []
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
var _rng := RandomNumberGenerator.new()


func setup(deck_a: Array[int], deck_b: Array[int], name_a: String, name_b: String, first := 0, seed := -1) -> Array:
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
			_uid += 1
			var c := CardInst.new()
			c.uid = _uid
			c.id = id
			c.data = CardData.get_card(id)
			c.owner = i
			players[i].deck.append(c)
		_shuffle(players[i].deck)
	current = first
	turn = 0
	var events := [{"type": "start"}]
	for i in 2:
		for n in 5:
			events.append_array(_draw(i))
	return events


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
	return true


func activate(p: int, c: CardInst) -> Array:
	if not can_activate(p, c):
		return []
	var ps := players[p]
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
	return [{"type": "destroy", "player": c.owner, "card": c, "zone": zone}]


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
