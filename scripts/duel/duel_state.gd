class_name DuelState
extends RefCounted
## Pure duel rules, no visuals. Every action returns a list of events
## that the board plays back as animations.
##
## Prototype rules: Normal Monsters plus a few Normal Spells. Draw, Main 1,
## Battle, Main 2, End. One Normal Summon or Set per turn, tributes for
## Level 5+, flip summons, position changes, direct attacks and damage.

enum Phase { DRAW, MAIN1, BATTLE, MAIN2, END, STANDBY }

const START_LP := 8000
const HAND_LIMIT := 6
const ZONES := 5
const DRAW := 2    # winner value when nobody wins


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
	var set_turn := -1
	var used_turn := -1
	# Effect bookkeeping (see EffectRunner)
	var atk_mod := 0
	var atk_mod_t := 0
	var atk_mod_turn := -1
	var half_turn := -1
	var zero_turn := -1
	var survive_turn := -1
	var ignite_turn := -1
	var killed_turn := -1
	var attack_count := 0
	var attack_count_turn := -1
	var equipped_to = null        # an Equip card's monster
	var linked = null             # Call of the Haunted / Premature Burial: the monster it brought back
	var counter := 0
	var orig_owner := -1          # set while the opponent controls this monster
	var control_until := -1
	var def_mod_t := 0
	var def_mod_turn := -1
	var proper := false           # Extra Deck / Ritual monster that was summoned the proper way (may be revived)
	var negated := false          # effects negated right now (Skill Drain and friends); kept fresh by _cleanup
	var negated_turn := -1

	func is_token() -> bool:
		return data.get("frame", "") == "token"

	func reset_mods() -> void:
		atk_mod = 0
		atk_mod_t = 0
		atk_mod_turn = -1
		half_turn = -1
		zero_turn = -1
		attack_count = 0
		attack_count_turn = -1

	func cname() -> String:
		return str(data.get("name", ""))

	func is_trap() -> bool:
		return data.get("kind", "") == "trap"

	func is_spell() -> bool:
		return data.get("kind", "") == "spell"

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
	var banished: Array[CardInst] = []
	var extra: Array[CardInst] = []
	var spells: Array = [null, null, null, null, null]
	var no_damage_turn := -1
	var protect_turn := -1
	var swords_left := 0
	var field_spell: CardInst = null
	var no_attack_turn := -1
	var skip_draw := 0
	var attacks_this_turn := 0
	var attacks_turn := -1
	var no_summon_turn := -1      # Scapegoat: no Summons for the rest of this turn (Sets are fine)

	func set_cards() -> Array[CardInst]:
		var out: Array[CardInst] = []
		for c in spells:
			if c != null:
				out.append(c)
		return out
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

## --- Player decisions -------------------------------------------------------------------
## The rules never wait for input. A human's choices are found beforehand by trying the action
## on a clone (DuelScene._run), asked one by one, then replayed here in the same order.
var manual := [false, false]     # which players pick for themselves (the rest take `auto`)
var answers: Array = []          # queued answers: card uids, or [index] for an option
var need = null                  # the first decision a trial run could not answer

## --- Monster effects on the chain ---------------------------------------------------------
## With defer_fx on (the duel screen), a triggered or ignition effect is not run on the spot:
## it waits in pending_fx, fx_to_chain() makes it a chain link, and chain_resolve() runs it.
var defer_fx := false
var pending_fx: Array = []


## Pick n of cands. `auto` is what the rules would take on their own (AI, tests, a forced pick).
func choose(who: int, prompt: String, cands: Array, n := 1, auto: Array = [], optional := false, source: CardInst = null) -> Array:
	var uniq: Array = []
	for x in cands:
		if x != null and not uniq.has(x):
			uniq.append(x)
	if auto.is_empty() and not optional:
		auto = uniq.slice(0, n)
	if not manual[who] or uniq.is_empty() or (uniq.size() <= n and not optional):
		return auto
	if not answers.is_empty():
		var ans: Array = answers.pop_front()
		var out: Array = []
		for uid in ans:
			for x in uniq:
				if x.uid == int(uid) and not out.has(x):
					out.append(x)
		if out.size() == n or (optional and out.is_empty()):
			return out
		return auto
	if need == null:
		var ids: Array = []
		for x in uniq:
			ids.append(x.uid)
		need = {"who": who, "prompt": prompt, "cands": ids, "n": n, "optional": optional,
				"source": source.uid if source != null else -1}
	return auto


## Pick one of a few labelled options (a position, yes / no). Returns its index.
func choose_option(who: int, prompt: String, labels: Array, auto := 0, source: CardInst = null) -> int:
	if not manual[who]:
		return auto
	if not answers.is_empty():
		var ans: Array = answers.pop_front()
		if ans.size() == 1 and int(ans[0]) >= 0 and int(ans[0]) < labels.size():
			return int(ans[0])
		return auto
	if need == null:
		need = {"who": who, "prompt": prompt, "options": labels, "source": source.uid if source != null else -1}
	return auto


## Triggered effects waiting to activate go onto the chain, the turn player's first.
func fx_to_chain() -> Array:
	var events := []
	var ordered: Array = []
	for q in [current, opponent(current)]:
		for f in pending_fx:
			if f["player"] == q:
				ordered.append(f)
	pending_fx.clear()
	for f in ordered:
		var c: CardInst = f["card"]
		var q: int = f["player"]
		if is_over():
			break
		# "You can ..." effects are the owner's call.
		if not f["ctx"].get("_ign", false) and "you can" in str(c.data.get("desc", "")).to_lower():
			if choose_option(q, "Activate the effect of %s?" % c.cname(), ["Activate", "Don't"], 0, c) == 1:
				continue
		chain.append({"player": q, "card": c, "kind": "fx", "spec": {"k": "fx"}, "target": null, "subject": null,
				"window": "open", "negated": false, "zone": -1, "actions": f["actions"], "ctx": f["ctx"]})
		events.append({"type": "effect", "player": q, "card": c, "text": "%s: effect activated" % c.cname()})
		if chain.size() > 1:
			events.append({"type": "chain", "player": q, "card": c, "n": chain.size()})
	return events


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

func begin_turn(step := false) -> Array:
	redirected.clear()
	turn += 1
	normal_summoned = false
	phase = Phase.DRAW
	var events := [{"type": "turn", "player": current, "turn": turn}, {"type": "phase", "phase": phase}]
	events.append_array(_cleanup())
	if turn > 1:
		if players[current].skip_draw > 0:
			players[current].skip_draw -= 1
			events.append({"type": "effect", "player": current, "card": null, "text": "Draw Phase skipped"})
		else:
			events.append_array(_draw(current))
		if is_over():
			return events
	if step:
		return events
	events.append_array(begin_standby())
	if is_over():
		return events
	events.append_array(begin_main1())
	return events


## The duel screen walks the turn phase by phase (begin_turn(true), begin_standby, begin_main1)
## so both players get their chance to act in each one.
func begin_standby() -> Array:
	phase = Phase.STANDBY
	var events := [{"type": "phase", "phase": phase}]
	events.append_array(EffectRunner.standby(self, current))
	if not is_over():
		events.append_array(SpellRules.standby(self, current))
	return events


func begin_main1() -> Array:
	phase = Phase.MAIN1
	return [{"type": "phase", "phase": phase}]


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
	var events := begin_end()
	events.append_array(finish_turn())
	return events


func begin_end() -> Array:
	phase = Phase.END
	var events := [{"type": "phase", "phase": phase}]
	events.append_array(EffectRunner.end_phase(self, current))
	return events


func finish_turn() -> Array:
	var events := []
	var ps := players[current]
	var over := ps.hand.size() - HAND_LIMIT
	if over > 0:
		# Hand limit: the turn player discards down to six, their pick.
		var by_value: Array = ps.hand.duplicate()
		by_value.sort_custom(func(a, b): return _card_value(a) < _card_value(b))
		for worst in choose(current, "Hand limit: discard %d card%s" % [over, "" if over == 1 else "s"], ps.hand, over, by_value.slice(0, over)):
			ps.hand.erase(worst)
			_to_gy(ps, worst)
			events.append({"type": "discard", "player": current, "card": worst})
	# Monsters borrowed until the End Phase go home.
	for m in ps.monsters():
		if m.control_until == turn:
			events.append_array(_return_control(m))
	events.append_array(_cleanup())
	# Swords of Revealing Light counts down at the end of the opponent's turns.
	var owner := opponent(current)
	if players[owner].swords_left > 0:
		players[owner].swords_left -= 1
		if players[owner].swords_left == 0:
			events.append({"type": "swords_end", "player": owner})
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
	events.append_array(_check_exodia())
	return events


const EXODIA := ["Exodia the Forbidden One", "Right Arm of the Forbidden One", "Left Arm of the Forbidden One",
		"Right Leg of the Forbidden One", "Left Leg of the Forbidden One"]


## All five pieces of Exodia in one hand wins the duel on the spot.
func _check_exodia() -> Array:
	if is_over():
		return []
	for q in 2:
		var have := {}
		for h in players[q].hand:
			if EXODIA.has(h.cname()):
				have[h.cname()] = true
		if have.size() == 5:
			_set_winner(q, "%s assembled all five pieces of Exodia!" % players[q].name)
			return [{"type": "effect", "player": q, "card": null, "text": "EXODIA! OBLITERATE!"},
					{"type": "win", "player": winner, "reason": win_reason}]
	return []


func _set_winner(p: int, reason: String) -> void:
	if winner == -1:
		winner = p
		win_reason = reason


func _in_main() -> bool:
	return phase == Phase.MAIN1 or phase == Phase.MAIN2


# ------------------------------------------------------------------ summoning

func tributes_needed(c: CardInst) -> int:
	if c.level() >= 5 and EffectRunner.no_tribute(self, c.owner, c):
		return 0
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
	# Ritual and Extra Deck monsters, and "Cannot be Normal Summoned/Set" monsters, need their own summon.
	if c.frame() in ["ritual", "fusion", "synchro", "xyz", "token"] or "cannot be normal summoned" in str(c.data.get("desc", "")).to_lower():
		return false
	var need := tributes_needed(c)
	var mons := players[p].monsters().size()
	if need == 0:
		return mons < ZONES
	return tributable(p).size() >= need


## Monsters this player may Tribute for a Tribute Summon (Sheep Tokens and the like may not be).
func tributable(p: int) -> Array:
	return players[p].monsters().filter(func(m): return not m.data.get("no_tribute_summon", false))


func normal_summon(p: int, c: CardInst, tributes: Array, set_card := false) -> Array:
	if not can_normal_summon(p, c) or tributes.size() != tributes_needed(c):
		return []
	if not set_card and players[p].no_summon_turn == turn:
		return []
	for t in tributes:
		if t.data.get("no_tribute_summon", false):
			return []
	var ps := players[p]
	var events := []
	for t in tributes:
		var idx := ps.field.find(t)
		if idx == -1:
			return []
	for t in tributes:
		ps.field[ps.field.find(t)] = null
		_to_gy(ps, t)
		events.append({"type": "tribute", "player": p, "card": t})
	var zone := ps.free_zone()
	ps.hand.erase(c)
	ps.field[zone] = c
	c.face_up = not set_card
	c.attack_pos = not set_card
	c.summoned_turn = turn
	c.pos_changed_turn = -1
	c.attacked_turn = -1
	c.reset_mods()
	normal_summoned = true
	events.append({"type": "set" if set_card else "summon", "player": p, "card": c, "zone": zone})
	if not set_card:
		last_summoned = c
		events.append_array(summon_triggers(p, c))
		events.append_array(EffectRunner.on_summon(self, p, c, "normal"))
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
	c.summoned_turn = turn
	last_summoned = c
	var events := [{"type": "flip", "player": p, "card": c, "zone": players[p].field.find(c)}]
	events.append_array(EffectRunner.on_summon(self, p, c, "flip"))
	return events


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

## Can player p activate this Spell/Trap right now as their own action (Main Phase)?
## From the hand (Spells), or a Set card (Spells, and Traps that can be used any time).
func can_activate(p: int, c: CardInst) -> bool:
	if p != current or not _in_main() or is_over() or c.is_monster():
		return false
	var sp := SpellRules.spec(c)
	if sp.is_empty():
		return false
	var ps := players[p]
	if ps.hand.has(c):
		if c.is_trap():
			return false
		if sp["k"] != "field" and ps.spells.find(null) == -1:
			return false
	elif ps.spells.has(c) and not c.face_up:
		if c.is_trap():
			if c.set_turn >= turn or not (sp.get("win", []) as Array).has("free"):
				return false
		elif sp["k"] == "quick" and c.set_turn >= turn:
			return false
	else:
		return false
	if SpellRules.blocked(self, c):
		return false
	if sp.has("legacy"):
		return _legacy_can(p, c)
	return SpellRules.feasible(self, p, c, "open", null)


## Activate and resolve at once (no responses). The duel screen uses chain_add / chain_resolve
## so both players get to respond; the AI's look-ahead and the tests use this shortcut.
func activate(p: int, c: CardInst, choice = null) -> Array:
	if not can_activate(p, c):
		return []
	var events := chain_add(p, c, choice, "open", null)
	if events.is_empty():
		return []
	events.append_array(chain_resolve())
	return events


## Put a card on the chain: pay its cost, turn it face-up, remember its target.
## `target` is the chosen target (or the Fusion Monster for Polymerization); null lets the game pick.
func chain_add(p: int, c: CardInst, target = null, window := "open", subject = null) -> Array:
	var sp := SpellRules.spec(c)
	var ps := players[p]
	if sp.is_empty():
		return []
	var events := []
	var zone := -1
	if sp.has("legacy") and str(sp["legacy"]) == "fusion":
		var ok := false
		for o in fusion_targets(p, c):
			if target == null or o["card"] == target:
				target = o["card"]
				ok = true
				break
		if not ok:
			return []
	if ps.hand.has(c):
		ps.hand.erase(c)
		if sp["k"] == "field":
			if ps.field_spell != null:
				events.append_array(_destroy_st(ps.field_spell))
			ps.field_spell = c
			zone = 5
		else:
			zone = ps.spells.find(null)
			if zone == -1:
				ps.hand.append(c)
				return []
			ps.spells[zone] = c
		c.face_up = true
		events.append({"type": "activate", "player": p, "card": c, "zone": zone})
	elif ps.spells.has(c):
		zone = ps.spells.find(c)
		c.face_up = true
		events.append({"type": "trap", "player": p, "card": c, "zone": zone})
	else:
		return []
	if target == null and not sp.has("legacy") and SpellRules._needs_target(sp):
		var auto_t = SpellRules.auto_target(self, p, c)
		var picked := choose(p, "Choose a target for %s" % c.cname(), SpellRules.targets(self, p, c), 1, [auto_t] if auto_t != null else [], false, c)
		target = picked[0] if not picked.is_empty() else auto_t
	var link := {"player": p, "card": c, "kind": "trap" if c.is_trap() else "spell", "spec": sp, "target": target,
			"subject": subject, "window": window, "negated": false, "zone": zone}
	events.append_array(SpellRules.pay_cost(self, p, c, sp))
	chain.append(link)
	if chain.size() > 1:
		events.append({"type": "chain", "player": p, "card": c, "n": chain.size()})
	return events


## Resolve the chain, last card first.
func chain_resolve() -> Array:
	var events := []
	while not chain.is_empty() and not is_over():
		var link: Dictionary = chain.pop_back()
		var c: CardInst = link["card"]
		var p: int = link["player"]
		var sp: Dictionary = link["spec"]
		var ps := players[p]
		if link["kind"] == "fx":
			# A monster effect. It still resolves if the monster has left the field.
			if link["negated"] or c.negated:
				events.append({"type": "effect", "player": p, "card": c, "text": "%s's effect is negated" % c.cname()})
			else:
				var ctx: Dictionary = link["ctx"].duplicate()
				ctx["_now"] = true
				events.append_array(EffectRunner.run_list(self, p, c, link["actions"], ctx))
			continue
		var here := ps.spells.has(c) or ps.field_spell == c
		var stays: bool = SpellRules.PERSIST.has(sp["k"])
		if link["negated"] or (not here and stays):
			events.append({"type": "effect", "player": p, "card": c, "text": "%s is negated" % c.cname()})
		elif sp.has("legacy"):
			events.append_array(_legacy_trap(p, c, link["subject"]) if c.is_trap() else _legacy_spell(p, c, link["target"]))
			stays = false
		else:
			events.append_array(SpellRules.resolve(self, link))
			stays = stays and link.get("stays", true) and not link["negated"]
		here = ps.spells.has(c) or ps.field_spell == c
		if here:
			if link.get("reset", false):
				events.append({"type": "st_reset", "player": p, "card": c, "zone": link["zone"]})
			elif stays and not link["negated"]:
				events.append({"type": "st_settle", "player": p, "card": c, "zone": link["zone"]})
			else:
				if ps.field_spell == c:
					ps.field_spell = null
				else:
					ps.spells[ps.spells.find(c)] = null
				events.append_array(SpellRules.left_field(self, c))
				_to_gy(ps, c)
				events.append({"type": "st_done" if c.is_trap() else "spell_done", "player": p, "card": c})
	chain.clear()
	events.append_array(_cleanup())
	events.append_array(_check_exodia())
	return events


func _legacy_can(p: int, c: CardInst) -> bool:
	match c.data.get("effect", ""):
		"soul_release":
			return not players[opponent(p)].gy.is_empty()
		"dark_core":
			return players[p].hand.size() >= 2 and _strongest_face_up(opponent(p)) != null
		"burial_dd":
			return not _best_monsters(players[p].banished, 3).is_empty()
		"dd_return":
			return players[p].free_zone() != -1 and not _best_monsters(players[p].banished, 1).is_empty()
		"mst":
			return not players[opponent(p)].set_cards().is_empty()
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


func _legacy_spell(p: int, c: CardInst, choice = null) -> Array:
	var ps := players[p]
	var fusion_plan := {}
	if c.data.get("effect", "") == "fusion":
		var options := fusion_targets(p, c, false, true, choice)
		for o in options:
			if choice == null or o["card"] == choice:
				fusion_plan = o
				break
		if fusion_plan.is_empty():
			return []
	var events := []
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
		"soul_release":
			# Banish up to 5 cards from the opponent's Graveyard (their best monsters first).
			var picks: Array = _best_monsters(players[opponent(p)].gy, 5)
			for g in players[opponent(p)].gy:
				if picks.size() < 5 and not picks.has(g):
					picks.append(g)
			picks = choose(p, "Soul Release: banish %d from their Graveyard" % picks.size(), players[opponent(p)].gy, picks.size(), picks, false, c)
			for g in picks:
				events.append_array(_banish(g))
		"dark_core":
			# Discard 1, then banish the opponent's strongest face-up monster.
			var worst: CardInst = null
			for h in ps.hand:
				if worst == null or _card_value(h) < _card_value(worst):
					worst = h
			worst = pick1(p, "Dark Core: discard 1 card", ps.hand, worst, c)
			if worst:
				ps.hand.erase(worst)
				_to_gy(ps, worst)
				events.append({"type": "discard", "player": p, "card": worst})
			var ups: Array = []
			for q in 2:
				for m in players[q].monsters():
					if m.face_up:
						ups.append(m)
			events.append_array(_banish(pick1(p, "Dark Core: banish 1 face-up monster", ups, _strongest_face_up(opponent(p)), c)))
		"burial_dd":
			# Return up to 3 of your banished monsters to the Graveyard.
			var b3: Array = _best_monsters(ps.banished, 3)
			for g in choose(p, "Return %d banished monsters to the Graveyard" % b3.size(), _best_monsters(ps.banished, 99), b3.size(), b3, false, c):
				ps.banished.erase(g)
				ps.gy.append(g)
				events.append({"type": "unbanish", "player": p, "card": g})
		"dd_return":
			# Special Summon your strongest banished monster.
			var back: Array = _best_monsters(ps.banished, 1)
			if not back.is_empty():
				back = [pick1(p, "Special Summon 1 of your banished monsters", _best_monsters(ps.banished, 99), back[0], c)]
				ps.banished.erase(back[0])
				events.append({"type": "unbanish", "player": p, "card": back[0], "to": "field"})
				events.append_array(_special(p, back[0], "reborn"))
				events.append_array(EffectRunner.on_summon(self, p, back[0], "special"))
		"mst":
			# Any Spell or Trap on the field, set or face-up, theirs or yours.
			var st: Array = []
			for q in [opponent(p), p]:
				for x in players[q].spells + [players[q].field_spell]:
					if x != null and x != c:
						st.append(x)
			var theirs: Array = players[opponent(p)].set_cards()
			if not st.is_empty():
				events.append_array(_destroy_st(pick1(p, "Destroy 1 Spell or Trap", st, theirs[0] if not theirs.is_empty() else st[0], c)))
		"swords":
			players[p].swords_left = 3
			for m in players[opponent(p)].monsters():
				if not m.face_up:
					m.face_up = true
					events.append({"type": "reveal", "player": opponent(p), "card": m, "zone": players[opponent(p)].field.find(m)})
		"fusion":
			events.append_array(_do_fusion(p, fusion_plan))
		"reborn":
			var revive := _best_in_gy()
			var dead: Array = []
			for q in [p, opponent(p)]:
				for g in players[q].gy:
					if can_revive(g):
						dead.append(g)
			revive = pick1(p, "Special Summon 1 monster from either Graveyard", dead, revive, c)
			if revive:
				players[revive.owner].gy.erase(revive)
				revive.owner = p
				events.append_array(_special(p, revive, "reborn"))
				events.append_array(EffectRunner.on_summon(self, p, revive, "special"))
	return events


## One card of the player's choosing (auto when the rules or the AI decide).
func pick1(who: int, prompt: String, cands: Array, auto: CardInst = null, source: CardInst = null) -> CardInst:
	var got := choose(who, prompt, cands, 1, [auto] if auto != null else [], false, source)
	return got[0] if not got.is_empty() else auto


func _strongest_face_up(p: int) -> CardInst:
	var best: CardInst = null
	for m in players[p].monsters():
		if m.face_up and (best == null or atk_of(m, false) > atk_of(best, false)):
			best = m
	return best


func _lowest_face_up(p: int) -> CardInst:
	var best: CardInst = null
	for m in players[p].monsters():
		if m.face_up and (best == null or m.atk() < best.atk()):
			best = m
	return best


# ------------------------------------------------------------------ battle

func can_attack(p: int, c: CardInst) -> bool:
	return (p == current and phase == Phase.BATTLE and not is_over() and players[p].field.has(c)
			and c.face_up and c.attack_pos and attacks_left(c) > 0 and SpellRules.can_attack(self, p, c)
			and not (EffectRunner.fx(c).get("summon_sick", false) and c.summoned_turn == turn)
			and players[opponent(p)].swords_left == 0)


func attacks_left(c: CardInst) -> int:
	var used := c.attack_count if c.attack_count_turn == turn else 0
	return EffectRunner.max_attacks(c) - used


## Can this monster attack the opponent directly right now?
func can_direct_attack_with(p: int, c: CardInst) -> bool:
	return EffectRunner.can_direct(self, p, c)


func can_direct_attack(p: int) -> bool:
	return players[opponent(p)].monsters().is_empty()


## Monster effects activated from the field (once per turn, Main Phase).
func can_ignite(p: int, c: CardInst) -> bool:
	return EffectRunner.can_ignite(self, p, c)


func ignite(p: int, c: CardInst) -> Array:
	return EffectRunner.ignite(self, p, c)


func attack_targets(p: int) -> Array[CardInst]:
	return players[opponent(p)].monsters()


## Attack in one go (AI simulation and tests). The duel screen uses
## declare_attack + response window + resolve_attack instead.
func attack(p: int, attacker: CardInst, target: CardInst) -> Array:
	var ev := declare_attack(p, attacker, target)
	if ev.is_empty():
		return []
	ev.append_array(resolve_attack())
	return ev


var pending_attack := {}
## The chain: links are {"player", "card", "kind", "spec", "target", "subject", "negated"}, last in resolves first.
var chain: Array = []
## Last monster Normal Summoned, for the "summon" response window.
var last_summoned: CardInst = null


func declare_attack(p: int, attacker: CardInst, target: CardInst) -> Array:
	if not can_attack(p, attacker):
		return []
	if target == null and not can_direct_attack_with(p, attacker):
		return []
	if target != null and not players[opponent(p)].field.has(target):
		return []
	attacker.attacked_turn = turn
	if attacker.attack_count_turn != turn:
		attacker.attack_count_turn = turn
		attacker.attack_count = 0
	attacker.attack_count += 1
	if players[p].attacks_turn != turn:
		players[p].attacks_turn = turn
		players[p].attacks_this_turn = 0
	players[p].attacks_this_turn += 1
	pending_attack = {"player": p, "attacker": attacker, "target": target, "negated": false,
			"opp_count": players[opponent(p)].monsters().size()}
	return [{"type": "attack", "player": p, "card": attacker, "target": target}]


## Replay: the number of monsters on the defender's side changed after the attack was declared,
## so the attacker picks again (a new target, a direct attack if the way is clear, or no attack).
func replay_needed() -> bool:
	if pending_attack.is_empty() or pending_attack["negated"] or is_over():
		return false
	var p: int = pending_attack["player"]
	var a: CardInst = pending_attack["attacker"]
	if not players[p].field.has(a) or not a.face_up or not a.attack_pos:
		return false
	return players[opponent(p)].monsters().size() != int(pending_attack.get("opp_count", -1))


func replay_attack(target: CardInst) -> Array:
	if pending_attack.is_empty():
		return []
	var p: int = pending_attack["player"]
	var a: CardInst = pending_attack["attacker"]
	if target == null and not can_direct_attack_with(p, a):
		return cancel_attack()
	if target != null and not players[opponent(p)].field.has(target):
		return cancel_attack()
	pending_attack["target"] = target
	pending_attack["opp_count"] = players[opponent(p)].monsters().size()
	return [{"type": "effect", "player": p, "card": a, "text": "Replay!"}, {"type": "attack", "player": p, "card": a, "target": target}]


func cancel_attack() -> Array:
	if pending_attack.is_empty():
		return []
	var p: int = pending_attack["player"]
	var a: CardInst = pending_attack["attacker"]
	pending_attack = {}
	return [{"type": "attack_stopped", "player": p, "card": a}]


func resolve_attack() -> Array:
	if pending_attack.is_empty():
		return []
	var pa := pending_attack
	pending_attack = {}
	var p: int = pa["player"]
	var attacker: CardInst = pa["attacker"]
	var target = pa["target"]
	var opp := opponent(p)
	if pa["negated"] or not players[p].field.has(attacker) or is_over():
		return [{"type": "attack_stopped", "player": p, "card": attacker}]
	if target != null and not players[opp].field.has(target):
		return [{"type": "attack_stopped", "player": p, "card": attacker}]
	# Cyber Barrier Dragon: once per turn, its owner's side shrugs off an attack.
	for m in players[opp].monsters():
		if m.face_up and m.attack_pos and EffectRunner.fx(m).get("negate_attack_once", false) and m.ignite_turn != turn:
			m.ignite_turn = turn
			return [{"type": "effect", "player": opp, "card": m, "text": "%s negates the attack!" % m.cname()},
				{"type": "attack_stopped", "player": p, "card": attacker}]
	var events := [{"type": "battle", "player": p, "card": attacker, "target": target}]
	var a := atk_of(attacker, true, target, true)
	if target == null:
		var before := players[opp].lp
		events.append_array(_battle_damage(opp, a, attacker, null))
		if players[opp].lp < before:
			events.append_array(EffectRunner.trigger(self, attacker, "damage"))
		events.append_array(_after_attack(attacker))
		return events
	if not target.face_up:
		target.face_up = true
		events.append({"type": "reveal", "player": opp, "card": target, "zone": players[opp].field.find(target)})
		events.append_array(EffectRunner.trigger(self, target, "flip"))
	var kill_def: bool = attacker.cname() == "Zubaba Knight" or EffectRunner.fx(attacker).get("kill_def", false)
	if kill_def and not target.attack_pos:
		events.append({"type": "effect", "player": p, "card": attacker, "text": "%s destroys it outright!" % attacker.cname()})
		events.append_array(_battle_kill(attacker, target))
		events.append_array(_after_attack(attacker))
		return events
	var target_was_def: bool = not target.attack_pos
	if target.attack_pos:
		var t := atk_of(target, false, attacker, true)
		if a > t:
			events.append_array(_battle_kill(attacker, target))
			events.append_array(_battle_damage(opp, a - t, attacker, target))
		elif a < t:
			events.append_array(_battle_kill(target, attacker))
			events.append_array(_battle_damage(p, t - a, target, attacker))
		elif a > 0:
			events.append_array(_battle_kill(target, attacker))
			events.append_array(_battle_kill(attacker, target))
	else:
		var d: int = def_of(target)
		if a > d:
			events.append_array(_battle_kill(attacker, target))
			if EffectRunner.piercing(self, p, attacker) or SpellRules.equip_flag(self, attacker, "pierce"):
				events.append({"type": "effect", "player": p, "card": attacker, "text": "Piercing damage!"})
				events.append_array(_battle_damage(opp, a - d, attacker, target))
		elif a < d:
			var dmg := d - a
			if EffectRunner.fx(target).get("double_damage_attacked", false):
				dmg *= 2
			events.append_array(_battle_damage(p, dmg, target, attacker))
	# Red Dragon Archfiend: after attacking a Defense monster, burn all of them.
	if target_was_def and EffectRunner.fx(attacker).get("kill_def_all", false) and players[p].field.has(attacker):
		var defs := []
		for m in players[opp].monsters():
			if not m.attack_pos:
				defs.append(m)
		if not defs.is_empty():
			events.append({"type": "effect", "player": p, "card": attacker, "text": "%s scorches every Defense monster!" % attacker.cname()})
			for m in defs:
				events.append_array(_destroy(m))
	events.append_array(_after_attack(attacker))
	return events


## winner destroys loser by battle (if it can be destroyed), with the triggers that come with it.
func _battle_kill(winner_c: CardInst, loser: CardInst) -> Array:
	if SpellRules.equip_flag(self, loser, "no_battle_death"):
		return []
	var events := _battle_destroy(loser)
	var died := not players[loser.owner].field.has(loser) and players[loser.owner].gy.has(loser)
	if not died:
		return events
	winner_c.killed_turn = turn
	if players[winner_c.owner].field.has(winner_c):
		events.append_array(EffectRunner.trigger(self, winner_c, "kill", {"victim": loser}))
	events.append_array(EffectRunner.trigger(self, loser, "death", {"killer": winner_c}))
	return events


func _after_attack(attacker: CardInst) -> Array:
	if players[attacker.owner].field.has(attacker) and attacker.attack_pos and EffectRunner.fx(attacker).get("def_after_attack", false):
		attacker.attack_pos = false
		return [{"type": "position", "player": attacker.owner, "card": attacker, "zone": players[attacker.owner].field.find(attacker)}]
	return []


## ATK including effects. `attacking` = it's the attacker in this battle; vs = the other monster.
func atk_of(c: CardInst, attacking: bool, vs: CardInst = null, battling := false) -> int:
	var v := c.atk()
	match c.cname():
		"Speed Warrior":
			if phase == Phase.BATTLE and c.summoned_turn == turn:
				v *= 2
		"Max Warrior":
			if attacking:
				v += 400
	return maxi(0, v + EffectRunner.atk_bonus(self, c, attacking, vs, battling) + SpellRules.atk_bonus(self, c, attacking and battling, vs))


func def_of(c: CardInst) -> int:
	return maxi(0, c.def() + (c.def_mod_t if c.def_mod_turn == turn else 0) + SpellRules.def_bonus(self, c))


func _battle_destroy(c: CardInst) -> Array:
	var ps := players[c.owner]
	if ps.protect_turn == turn:
		return []
	if EffectRunner.survives_battle(self, c):
		return [{"type": "effect", "player": c.owner, "card": c, "text": "%s isn't destroyed!" % c.cname()}]
	if c.cname() == "Gogogo Golem" and not c.attack_pos and c.used_turn != turn:
		c.used_turn = turn
		return [{"type": "effect", "player": c.owner, "card": c, "text": "Gogogo Golem holds on!"}]
	return _destroy(c, true)


func _battle_damage(p: int, amount: int, dealer: CardInst = null, taker: CardInst = null) -> Array:
	var ps := players[p]
	if EffectRunner.no_damage_involving(taker) and taker.owner == p:
		return [{"type": "effect", "player": p, "card": taker, "text": "No battle damage!"}]
	if ps.no_damage_turn == turn or ps.protect_turn == turn:
		return [{"type": "effect", "player": p, "card": null, "text": "No battle damage!"}]
	return _damage(p, amount)


func _destroy(c: CardInst, by_battle := false) -> Array:
	var ps := players[c.owner]
	var zone := ps.field.find(c)
	if zone == -1:
		return []
	ps.field[zone] = null
	_to_gy(ps, c)
	var events := [{"type": "destroy", "player": c.owner, "card": c, "zone": zone, "overlays": c.overlays.duplicate()}]
	for o in c.overlays:
		_to_gy(ps, o)
	c.overlays.clear()
	events.append_array(_on_leave_field(c, by_battle))
	events.append_array(_monster_left(c))
	return events


## Every card headed for the Graveyard goes through here, so "banish instead" effects work.
func _to_gy(ps: PlayerState, c: CardInst) -> void:
	if c.is_token():
		return   # Tokens are not cards: they simply stop existing.
	if not c.overlays.is_empty():
		# An Xyz Monster's materials go to the Graveyard when it leaves the field.
		var mats: Array = c.overlays.duplicate()
		c.overlays.clear()
		for o in mats:
			players[o.owner].gy.append(o)
	if c.orig_owner != -1:
		# A borrowed monster goes to its real owner's Graveyard.
		c.owner = c.orig_owner
		c.orig_owner = -1
		c.control_until = -1
		ps = players[c.owner]
	if _gy_redirect(c):
		ps.banished.append(c)
		redirected.append(c)
	else:
		ps.gy.append(c)


## Cards banished instead of going to the GY since the last time the scene looked (for the board).
var redirected: Array = []


func _gy_redirect(c: CardInst = null) -> bool:
	if SpellRules.redirect(self, c):
		return true
	for q in 2:
		for m in players[q].monsters():
			if m.face_up and EffectRunner.fx(m).get("banish_redirect", false):
				return true
	return false


## Banish (remove from play) a card from wherever it is: field, Spell & Trap zone, GY or hand.
## Banished cards are out of the duel: no Graveyard triggers, no Monster Reborn.
func _banish(c: CardInst) -> Array:
	if c == null:
		return []
	if c.is_token():
		return _vanish(c)
	for q in 2:
		var ps := players[q]
		var from := ""
		var zone := -1
		if ps.field.has(c):
			from = "field"
			zone = ps.field.find(c)
			ps.field[zone] = null
			for o in c.overlays:
				_to_gy(ps, o)
			c.overlays.clear()
			c.reset_mods()
		elif ps.spells.has(c):
			from = "spells"
			zone = ps.spells.find(c)
			ps.spells[zone] = null
		elif ps.gy.has(c):
			from = "gy"
			ps.gy.erase(c)
		elif ps.hand.has(c):
			from = "hand"
			ps.hand.erase(c)
		elif ps.deck.has(c):
			from = "deck"
			ps.deck.erase(c)
		elif ps.field_spell == c:
			from = "spells"
			zone = 5
			ps.field_spell = null
		if from != "":
			if c.orig_owner != -1:
				c.owner = c.orig_owner
				c.orig_owner = -1
				c.control_until = -1
			c.face_up = true
			players[c.owner].banished.append(c)
			var bev := [{"type": "banish", "player": c.owner, "card": c, "from": from, "zone": zone, "side": q}]
			if from == "field":
				bev.append_array(_monster_left(c))
			elif from == "spells":
				bev.append_array(SpellRules.left_field(self, c))
			return bev
	return []


func _best_monsters(list: Array, n: int) -> Array:
	var mons: Array = []
	for g in list:
		if g.is_monster():
			mons.append(g)
	mons.sort_custom(func(a, b): return a.atk() > b.atk())
	return mons.slice(0, n)


func _destroy_st(c: CardInst) -> Array:
	var ps := players[c.owner]
	var zone := ps.spells.find(c)
	if ps.field_spell == c:
		ps.field_spell = null
		zone = 5
	elif zone == -1:
		return []
	else:
		ps.spells[zone] = null
	_to_gy(ps, c)
	var events := [{"type": "destroy_st", "player": c.owner, "card": c, "zone": zone}]
	events.append_array(SpellRules.left_field(self, c))
	return events


## Equip cards (and Call of the Haunted) go when their monster goes.
func _monster_left(m: CardInst) -> Array:
	var events := []
	for q in 2:
		for st in players[q].spells.duplicate():
			if st == null or not st.face_up:
				continue
			if st.equipped_to == m or st.linked == m:
				st.linked = null
				st.equipped_to = null
				events.append_array(_destroy_st(st))
	return events


## Sweep up Equip cards whose monster is gone (tributed, used as material...).
func _cleanup() -> Array:
	var events := []
	# Effect negation (Skill Drain and one-turn negations) is re-derived from what is on the field.
	var drain := SpellRules.field_flag(self, "drain")
	for q in 2:
		for m in players[q].monsters():
			m.negated = m.face_up and (drain or m.negated_turn == turn)
	for q in 2:
		for st in players[q].spells.duplicate():
			if st == null or not st.face_up:
				continue
			var m = st.equipped_to if st.equipped_to != null else st.linked
			if m == null:
				continue
			if not (players[0].field.has(m) or players[1].field.has(m)) or not m.face_up:
				st.linked = null
				st.equipped_to = null
				events.append_array(_destroy_st(st))
	return events


## A Token leaving the field any way at all just disappears.
func _vanish(c: CardInst) -> Array:
	for q in 2:
		var z := players[q].field.find(c)
		if z != -1:
			players[q].field[z] = null
			return [{"type": "destroy", "player": q, "card": c, "zone": z}]
	return []


## Return a card on the field to its owner's hand (Extra Deck monsters go back to the Extra Deck).
func _bounce(c: CardInst) -> Array:
	if c != null and c.is_token():
		return _vanish(c)
	for q in 2:
		var ps := players[q]
		var from := ""
		var zone := -1
		if ps.field.has(c):
			from = "field"
			zone = ps.field.find(c)
			ps.field[zone] = null
			for o in c.overlays:
				_to_gy(ps, o)
			c.overlays.clear()
			c.reset_mods()
		elif ps.spells.has(c):
			from = "spells"
			zone = ps.spells.find(c)
			ps.spells[zone] = null
		elif ps.field_spell == c:
			from = "spells"
			zone = 5
			ps.field_spell = null
		if from == "":
			continue
		if c.orig_owner != -1:
			c.owner = c.orig_owner
			c.orig_owner = -1
			c.control_until = -1
		c.face_up = true
		var home := players[c.owner]
		var to_extra: bool = c.is_monster() and c.frame() in ["fusion", "synchro", "xyz"]
		if to_extra:
			home.extra.append(c)
		else:
			home.hand.append(c)
		var events := [{"type": "bounce", "player": c.owner, "card": c, "from": from, "zone": zone, "side": q, "extra": to_extra}]
		events.append_array(_monster_left(c) if from == "field" else SpellRules.left_field(self, c))
		return events
	return []


## Move a monster to player p's side. `until`: the turn it goes back at the End Phase, or -1 to keep it.
func _take_control(c: CardInst, p: int, until: int) -> Array:
	var from_p := c.owner
	if from_p == p or not players[from_p].field.has(c):
		return []
	var zone := players[p].free_zone()
	if zone == -1:
		return _destroy(c)
	var from_zone := players[from_p].field.find(c)
	players[from_p].field[from_zone] = null
	players[p].field[zone] = c
	if c.orig_owner == -1:
		c.orig_owner = from_p
	c.owner = p
	c.control_until = until
	return [{"type": "control", "player": p, "card": c, "zone": zone, "from_player": from_p, "from_zone": from_zone}]


func _return_control(c: CardInst) -> Array:
	if c.orig_owner == -1 or c.orig_owner == c.owner or not players[c.owner].field.has(c):
		return []
	var home := c.orig_owner
	c.orig_owner = -1
	var ev := _take_control(c, home, -1)
	c.orig_owner = -1
	c.control_until = -1
	return ev


## Triggers when a monster leaves the field for the GY.
func _on_leave_field(c: CardInst, by_battle: bool) -> Array:
	var p := c.owner
	var ps := players[p]
	var events := []
	match c.cname():
		"Sangan":
			for d in ps.deck:
				if d.is_monster() and d.atk() <= 1500:
					ps.deck.erase(d)
					ps.hand.append(d)
					events.append({"type": "effect", "player": p, "card": c, "text": "Sangan adds %s to the hand" % d.cname()})
					events.append({"type": "search", "player": p, "card": d, "deck": ps.deck.size()})
					break
		"Winged Kuriboh":
			ps.no_damage_turn = turn
			events.append({"type": "effect", "player": p, "card": c, "text": "No battle damage this turn"})
		"Mystic Tomato":
			if by_battle and ps.free_zone() != -1:
				for d in ps.deck:
					if d.is_monster() and d.atk() <= 1500 and d.data.get("attribute", "") == "DARK" and not CardData.is_extra(d.id):
						ps.deck.erase(d)
						events.append({"type": "effect", "player": p, "card": c, "text": "Mystic Tomato calls %s" % d.cname()})
						events.append_array(_special(p, d, "effect"))
						break
	events.append_array(EffectRunner.trigger(self, c, "gy"))
	return events


func _damage(p: int, amount: int) -> Array:
	if amount <= 0:
		return []
	var ps := players[p]
	ps.lp = maxi(0, ps.lp - amount)
	var events := [{"type": "lp", "player": p, "lp": ps.lp, "delta": -amount}]
	if ps.lp == 0:
		if winner == p and players[opponent(p)].lp == 0:
			# Both duelists reached zero in the same resolution: nobody wins.
			winner = DRAW
			win_reason = "Both duelists' Life Points hit zero. The duel is a draw."
		else:
			_set_winner(opponent(p), "%s's Life Points hit zero." % ps.name)
		events.append({"type": "win", "player": winner, "reason": win_reason})
	return events


# ------------------------------------------------------------------ special summons

func _best_in_gy() -> CardInst:
	var best: CardInst = null
	for ps in players:
		for c in ps.gy:
			if can_revive(c) and (best == null or c.atk() > best.atk()):
				best = c
	return best


## pos: "" = the summoner chooses Attack or face-up Defense, "atk" / "def" = the effect says which.
func _special(p: int, c: CardInst, method: String, pos := "") -> Array:
	var ps := players[p]
	var zone := ps.free_zone()
	if zone == -1:
		_to_gy(ps, c)
		return []
	ps.field[zone] = c
	c.face_up = true
	c.attack_pos = pos != "def"
	if pos == "" and manual[p]:
		c.attack_pos = choose_option(p, "Special Summon %s in:" % c.cname(), ["Attack Position", "Defense Position"], 0, c) == 0
	c.summoned_turn = turn
	c.pos_changed_turn = -1
	c.attacked_turn = -1
	c.reset_mods()
	last_summoned = c
	var events := [{"type": "special", "player": p, "card": c, "zone": zone, "method": method}]
	if not c.attack_pos:
		events.append({"type": "position", "player": p, "card": c, "zone": zone})
	return events


## Ritual and Extra Deck monsters can only come back if they were first summoned the proper way.
func can_revive(c: CardInst) -> bool:
	return c.is_monster() and not c.is_token() and (c.proper or not c.frame() in ["ritual", "fusion", "synchro", "xyz"])


## Every Fusion Monster that can be made right now with Polymerization `poly`.
## Each option: {"card", "hand": [materials], "field": [materials]}
## `ask` (only while resolving, for the one Fusion Monster in `only`): when a material could come
## from the hand or from the field, the player says which.
func fusion_targets(p: int, poly: CardInst = null, from_gy := false, ask := false, only: CardInst = null) -> Array:
	var ps := players[p]
	var out := []
	for f in ps.extra:
		if f.frame() != "fusion" or (only != null and f != only):
			continue
		var pool_hand: Array = ps.hand.duplicate() if not from_gy else ps.gy.duplicate()
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
			if ask and found:
				var on_field: Array = pool_field.filter(func(m): return m.id == mid)
				if not on_field.is_empty():
					var got := pick1(p, "Fusion material: use which %s?" % found.cname(), [found, on_field[0]], found, f)
					if got != found:
						found = null
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


func _do_fusion(p: int, plan: Dictionary, banish := false) -> Array:
	var ps := players[p]
	var events := []
	if banish:
		for m in plan["hand"] + plan["field"]:
			events.append_array(_banish(m))
	else:
		for m in plan["hand"]:
			ps.hand.erase(m)
			_to_gy(ps, m)
			events.append({"type": "material", "player": p, "card": m, "from": "hand"})
		for m in plan["field"]:
			var z := ps.field.find(m)
			ps.field[z] = null
			_to_gy(ps, m)
			events.append({"type": "material", "player": p, "card": m, "from": "field", "zone": z})
	var f: CardInst = plan["card"]
	ps.extra.erase(f)
	f.proper = true
	events.append_array(_special(p, f, "fusion"))
	events.append_array(EffectRunner.on_summon(self, p, f, "fusion"))
	return events


## Material sets for a Synchro or Xyz monster, best (cheapest) first.
func extra_materials(p: int, c: CardInst) -> Array:
	var mons: Array = []
	for m in players[p].monsters():
		if m.face_up:
			mons.append(m)
	var out := []
	if c.frame() == "xyz":
		var same := mons.filter(func(m): return m.level() == c.level() and m.frame() not in ["xyz", "token"])
		same.sort_custom(func(a, b): return a.atk() < b.atk())
		for i in same.size():
			for j in range(i + 1, same.size()):
				out.append([same[i], same[j]])
	elif c.frame() == "synchro":
		mons = mons.filter(func(m): return m.frame() != "xyz")   # Xyz Monsters have a Rank, not a Level
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
	if p != current or not _in_main() or is_over() or not players[p].extra.has(c) or players[p].no_summon_turn == turn:
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
			_to_gy(ps, m)
		events.append({"type": "material", "player": p, "card": m, "from": "field", "zone": z, "overlay": xyz})
	ps.extra.erase(c)
	c.proper = true
	events.append_array(_special(p, c, c.frame()))
	if not xyz:
		for m in materials:
			events.append_array(EffectRunner.trigger(self, m, "material"))
	var ctx_kind := c.frame()
	events.append_array(EffectRunner.on_summon(self, p, c, ctx_kind))
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
		for c in ps.banished:
			np.banished.append(_clone_card(c, map))
		for c in ps.extra:
			np.extra.append(_clone_card(c, map))
		np.field = []
		for c in ps.field:
			np.field.append(_clone_card(c, map) if c != null else null)
		np.spells = []
		for c in ps.spells:
			np.spells.append(_clone_card(c, map) if c != null else null)
		np.no_damage_turn = ps.no_damage_turn
		np.protect_turn = ps.protect_turn
		np.swords_left = ps.swords_left
		np.field_spell = _clone_card(ps.field_spell, map) if ps.field_spell != null else null
		np.no_attack_turn = ps.no_attack_turn
		np.skip_draw = ps.skip_draw
		np.no_summon_turn = ps.no_summon_turn
		np.attacks_this_turn = ps.attacks_this_turn
		np.attacks_turn = ps.attacks_turn
		s.players.append(np)
	# Links between cards (equips, borrowed monsters, the chain, the attack in progress).
	for ps in players:
		for c in ps.spells:
			if c != null:
				var n: CardInst = map[c.uid]
				n.equipped_to = map.get(c.equipped_to.uid) if c.equipped_to != null else null
				n.linked = map.get(c.linked.uid) if c.linked != null else null
	for f in pending_fx:
		var nf: Dictionary = f.duplicate()
		nf["card"] = map.get(f["card"].uid, f["card"])
		nf["ctx"] = _clone_ctx(f["ctx"], map)
		s.pending_fx.append(nf)
	s.defer_fx = defer_fx
	for l in chain:
		var nl: Dictionary = l.duplicate()
		if nl.has("ctx"):
			nl["ctx"] = _clone_ctx(l["ctx"], map)
		nl["card"] = map.get(l["card"].uid, l["card"])
		if l["target"] != null:
			nl["target"] = map.get(l["target"].uid, l["target"])
		if l["subject"] != null and not (l["subject"] is Dictionary):
			nl["subject"] = map.get(l["subject"].uid, l["subject"])
		elif l["subject"] is Dictionary:
			nl["subject"] = null
		s.chain.append(nl)
	for i in s.chain.size():
		if chain[i]["subject"] is Dictionary:
			var idx := chain.find(chain[i]["subject"])
			if idx != -1:
				s.chain[i]["subject"] = s.chain[idx]
	if last_summoned != null:
		s.last_summoned = map.get(last_summoned.uid)
	if not pending_attack.is_empty():
		s.pending_attack = pending_attack.duplicate()
		s.pending_attack["attacker"] = map.get(pending_attack["attacker"].uid, pending_attack["attacker"])
		if pending_attack["target"] != null:
			s.pending_attack["target"] = map.get(pending_attack["target"].uid, pending_attack["target"])
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


func _clone_ctx(ctx: Dictionary, map: Dictionary) -> Dictionary:
	var out := {}
	for k in ctx:
		var v = ctx[k]
		out[k] = map.get(v.uid, v) if v is CardInst else v
	return out


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
	n.set_turn = c.set_turn
	n.used_turn = c.used_turn
	n.atk_mod = c.atk_mod
	n.atk_mod_t = c.atk_mod_t
	n.atk_mod_turn = c.atk_mod_turn
	n.half_turn = c.half_turn
	n.zero_turn = c.zero_turn
	n.survive_turn = c.survive_turn
	n.ignite_turn = c.ignite_turn
	n.killed_turn = c.killed_turn
	n.attack_count = c.attack_count
	n.attack_count_turn = c.attack_count_turn
	n.counter = c.counter
	n.orig_owner = c.orig_owner
	n.control_until = c.control_until
	n.def_mod_t = c.def_mod_t
	n.def_mod_turn = c.def_mod_turn
	n.proper = c.proper
	n.negated = c.negated
	n.negated_turn = c.negated_turn
	map[c.uid] = n
	for o in c.overlays:
		n.overlays.append(_clone_card(o, map))
	return n


func find_uid(uid: int) -> CardInst:
	for ps in players:
		for list in [ps.hand, ps.deck, ps.gy, ps.extra, ps.banished]:
			for c in list:
				if c.uid == uid:
					return c
		for c in ps.field + ps.spells + [ps.field_spell]:
			if c != null and c.uid == uid:
				return c
			if c != null:
				for o in c.overlays:
					if o.uid == uid:
						return o
	return null


# ------------------------------------------------------------------ spells & traps on the field

func can_set_st(p: int, c: CardInst) -> bool:
	return (p == current and _in_main() and not is_over() and not c.is_monster()
			and players[p].hand.has(c) and players[p].spells.find(null) != -1 and SpellRules.kind(c) != "field")


func set_st(p: int, c: CardInst) -> Array:
	if not can_set_st(p, c):
		return []
	var ps := players[p]
	var zone := ps.spells.find(null)
	ps.hand.erase(c)
	ps.spells[zone] = c
	c.face_up = false
	c.set_turn = turn
	return [{"type": "set_st", "player": p, "card": c, "zone": zone}]


## Cards player `p` could activate right now in a response window.
## window: "attack" (an opponent's monster declared an attack) or "summon".
func responses(p: int, window: String, subject = null) -> Array:
	var out := []
	var ps := players[p]
	if is_over():
		return out
	for c in ps.spells:
		if c != null and not c.face_up and SpellRules.fits(self, p, c, window, subject):
			out.append(c)
	for c in ps.hand:
		if not c.is_monster() and SpellRules.fits(self, p, c, window, subject):
			out.append(c)
	if window == "attack":
		if not pending_attack.is_empty() and pending_attack["player"] != p:
			for c in ps.hand:
				if c.cname() == "Kuriboh":
					out.append(c)
					break
		for m in ps.monsters():
			if m.cname() == "Number 39: Utopia" and m.face_up and m.overlays.size() > 0 and m.used_turn != turn:
				out.append(m)
	return out


func _trap_fits(p: int, c: CardInst, window: String, subject: CardInst) -> bool:
	var e: String = c.data.get("effect", "")
	if window == "attack":
		if pending_attack.is_empty() or pending_attack["player"] == p:
			return false
		var att: CardInst = pending_attack["attacker"]
		var immune := att.cname() == "Elemental HERO Wildheart"
		match e:
			"mirror_force", "sakuretsu":
				return not immune
			"magic_cylinder", "negate_attack", "waboku", "dim_prison":
				return true
		return false
	if window == "summon" and subject != null and subject.owner != p:
		if subject.cname() == "Elemental HERO Wildheart":
			return false
		match e:
			"trap_hole":
				return subject.atk() >= 1000 and subject.summoned_turn == turn
			"bottomless":
				return subject.atk() >= 1500
			"torrential":
				return true
	return false


## Activate a response card (trap, Kuriboh from hand, Utopia's effect).
func respond(p: int, c: CardInst, subject = null) -> Array:
	var ps := players[p]
	var events := []
	if c.cname() == "Kuriboh" and ps.hand.has(c):
		ps.hand.erase(c)
		_to_gy(ps, c)
		ps.no_damage_turn = turn
		events.append({"type": "hand_effect", "player": p, "card": c, "text": "Kuriboh! No battle damage."})
		return events
	if c.cname() == "Number 39: Utopia":
		c.used_turn = turn
		var o: CardInst = c.overlays.pop_back()
		_to_gy(ps, o)
		events.append({"type": "detach", "player": p, "card": c, "material": o})
		if not pending_attack.is_empty():
			pending_attack["negated"] = true
		events.append({"type": "effect", "player": p, "card": c, "text": "Utopia negates the attack!"})
		return events
	if not ps.spells.has(c) and not ps.hand.has(c):
		return events
	events.append_array(chain_add(p, c, null, "attack" if not pending_attack.is_empty() else "summon", subject))
	events.append_array(chain_resolve())
	return events

func _legacy_trap(p: int, c: CardInst, subject = null) -> Array:
	var ps := players[p]
	var events := []
	var opp := opponent(p)
	if subject is Dictionary:
		subject = null
	match c.data.get("effect", ""):
		"mirror_force":
			# Does not negate the attack: an attacker that survives (unaffected by Traps) keeps attacking.
			for m in players[opp].monsters():
				if m.attack_pos and not EffectRunner.fx(m).get("trap_immune", false) and m.cname() != "Elemental HERO Wildheart":
					events.append_array(_destroy(m))
		"sakuretsu":
			events.append_array(_destroy(pending_attack["attacker"]))
		"magic_cylinder":
			pending_attack["negated"] = true
			events.append_array(_damage(opp, pending_attack["attacker"].atk()))
		"negate_attack":
			pending_attack["negated"] = true
		"waboku":
			ps.protect_turn = turn
		"dim_prison":
			pending_attack["negated"] = true
			events.append_array(_banish(pending_attack["attacker"]))
		"trap_hole":
			if subject != null:
				events.append_array(_destroy(subject))
		"bottomless":
			# Destroy it, and banish it instead of sending it to the Graveyard.
			if subject != null:
				events.append_array(_destroy(subject))
				events.append_array(_banish(subject))
		"torrential":
			for q in 2:
				for m in players[q].monsters():
					events.append_array(_destroy(m))
	return events


# ------------------------------------------------------------------ monster effects from hand / on summon

func can_special_from_hand(p: int, c: CardInst) -> bool:
	if p != current or not _in_main() or is_over() or not players[p].hand.has(c) or players[p].no_summon_turn == turn:
		return false
	if c.cname() == "Cyber Dragon":
		return players[p].monsters().is_empty() and not players[opponent(p)].monsters().is_empty() and players[p].free_zone() != -1
	return EffectRunner.can_special_hand(self, p, c)


func special_from_hand(p: int, c: CardInst) -> Array:
	if not can_special_from_hand(p, c):
		return []
	if c.cname() != "Cyber Dragon":
		return EffectRunner.special_hand(self, p, c)
	players[p].hand.erase(c)
	return _special(p, c, "effect")


## Triggers after a Normal Summon resolves.
func summon_triggers(p: int, c: CardInst) -> Array:
	var ps := players[p]
	var events := []
	match c.cname():
		"Junk Synchron":
			if ps.free_zone() == -1:
				return events
			for g in ps.gy:
				if g.is_monster() and g.level() <= 2 and not CardData.is_extra(g.id):
					ps.gy.erase(g)
					events.append({"type": "effect", "player": p, "card": c, "text": "Junk Synchron revives %s" % g.cname()})
					var ev := _special(p, g, "reborn")
					if not ev.is_empty():
						g.attack_pos = false
					events.append_array(ev)
					break
		"Goblindbergh":
			if ps.free_zone() == -1:
				return events
			for h in ps.hand:
				if h.is_monster() and h.level() == 4:
					ps.hand.erase(h)
					events.append({"type": "effect", "player": p, "card": c, "text": "Goblindbergh brings out %s" % h.cname()})
					events.append_array(_special(p, h, "effect"))
					c.attack_pos = false
					events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
					break
	return events
