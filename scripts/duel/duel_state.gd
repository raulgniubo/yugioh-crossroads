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
	var mode := 0                 # which of a card's effects was chosen (Enemy Controller and friends)
	var normal_turn := -1         # the turn it was Normal Summoned (Photon Cerberus)
	var lv_set := 0               # a Level it was given by an effect (Gagaga Magician, Copy Plant, Infernity Avenger)
	var lv_turn := -1             # ...through this turn (-1: for as long as it stays on the field)
	var died_turn := -1           # the turn it was destroyed by battle (Captain Tenacious)
	var gy_turn := -9          # the turn it last went to the Graveyard
	var hit_def_turn := -1        # the turn it attacked a Defense Position monster (Twin-Sword Marauder)
	var tmp_atk := 0              # an ATK change that lasts through turn `tmp_until` (Bazoo the Soul-Eater)
	var tmp_until := -1
	var back_pos := ""            # in the Graveyard: Special Summon it at its owner's next Standby Phase (Revival Jam)
	var lv_aura := false          # its Level is set by its own continuous effect right now (Harpie Channeler)
	var leave_banish := false   # "banish it when it leaves the field" (Quillbolt Hedgehog)
	var shrunk := false         # Max Warrior: halved and Level 2 until its controller's next Standby Phase
	var wedge := false            # a Wedge Counter (Blackwing Armor Master)
	var flag_turn := -1           # "this card's effect was applied this turn" (Stardust Dragon)
	var once := false             # a once-while-in-the-Graveyard / once-per-Duel effect is spent
	var pos_lock_until := -1      # cannot change battle position through this turn (Goblin Attack Force)
	var no_tribute_turn := -1     # cannot be Tributed this turn (Mind Control)
	var def_mod := 0              # a lasting change to DEF (Blackwing - Gale)
	var cowboy_turn := -1         # Gagaga Cowboy used its Attack Position effect this turn
	var zero_perm := false        # its ATK is 0 for as long as it stays on the field (Starliege Paladynamo's target)
	var bonus_attacks := 0        # extra attacks this Battle Phase (Rose Tentacles), counted on bonus_attacks_turn
	var bonus_attacks_turn := -1
	var neg_perm := false         # its effects are negated for as long as it stays on the field (Junk Synchron's guest)
	var left_turn := -1           # a Spell/Trap: the turn it left the field (Axe of Despair goes back on the Deck)
	var tags := {}                # small notes that leave with the card: once-per-turn stamps, the materials it was made with

	func is_token() -> bool:
		return data.get("frame", "") == "token"

	func reset_mods() -> void:
		tags = {}
		lv_set = 0
		lv_turn = -1
		wedge = false
		def_mod = 0
		neg_perm = false
		zero_perm = false
		cowboy_turn = -1
		bonus_attacks = 0
		bonus_attacks_turn = -1
		atk_mod = 0
		atk_mod_t = 0
		atk_mod_turn = -1
		half_turn = -1
		zero_turn = -1
		attack_count = 0
		attack_count_turn = -1
		shrunk = false
		hit_def_turn = -1
		tmp_atk = 0
		tmp_until = -1
		lv_aura = false
		counter = 0

	func cname() -> String:
		if tags.has("as"):
			return str(tags["as"])   # "this card's name becomes that monster's original name" (Neo-Spacian Dark Panther)
		return str(data.get("name", ""))

	func is_trap() -> bool:
		return data.get("kind", "") == "trap"

	func is_spell() -> bool:
		return data.get("kind", "") == "spell"

	func is_monster() -> bool:
		return data.get("kind", "monster") == "monster"

	func atk() -> int:
		return maxi(0, int(data.get("atk", 0)))   # ("?" is stored as a negative number)

	func def() -> int:
		return maxi(0, int(data.get("def", 0)))

	func level() -> int:
		return lv_set if lv_set > 0 else int(data.get("level", 0))

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
	var no_effect_damage_turn := -1   # effect damage is 0 this turn (Cyber Kirin, Hallowed Life Barrier)
	var name_lock := {}               # card name -> turn: cards and effects with that name cannot be activated that turn (Sangan)
	var exiles: Array = []            # [{"card", "to", "left", "atk_pos"}]: banished until this player's 2nd Standby Phase (Destiny HERO - Doom Lord)
	var once_names := {}              # card name -> turn its once-per-turn effect was used
	var protect_turn := -1
	var swords_left := 0
	var field_spell: CardInst = null
	var no_attack_turn := -1
	var skip_draw := 0
	var attacks_this_turn := 0
	var attacks_turn := -1
	var spell_turn := -1          # last turn this player activated a Spell (Nitro Warrior)
	var speed := 0                # Speed Counters (Turbo Duels)
	var speed_turn := -1          # last turn this player used a Speed World 2 effect
	var no_summon_turn := -1      # Scapegoat: no Summons for the rest of this turn (Sets are fine)
	var extra_normals := 0        # extra Normal Summons / Sets left this turn (Double Summon)
	var no_damage_until := -1     # takes no damage of any kind through this turn (Synchro Barrier)
	var once_duel := {}           # card name -> true: its once-per-Duel effect is spent (Unknown Synchron)
	var summons_turn := -1        # the last turn this player Normal or Special Summoned a monster (Dark Magic Curtain)
	var only_attacker := -1       # uid of the one monster that may attack on `only_attacker_turn` (Feather Shot)
	var only_attacker_turn := -1

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
## Destiny Draw: once per duel, a duelist in trouble may choose the card of their next draw.
var destiny := false               # is it part of this duel at all
var destiny_who := [true, false]   # who may use it
var destiny_used := [false, false]
var destiny_next: Array = [null, null]   # the card each side has reached for (drawn in their next Draw Phase)
const DESTINY_LP := 2000
## Turbo Duel: Speed World 2 is in play. Both riders gain a Speed Counter each Standby Phase,
## lose them to big hits, need them to play Spells, and can spend them on its three effects.
var turbo := false
const SPEED_MAX := 12
const SPEED_HEAVY := ["Raigeki", "Dark Hole", "Monster Reborn", "Pot of Greed", "Heavy Storm", "Harpie's Feather Duster",
	"Change of Heart", "Graceful Charity", "Lightning Vortex", "Card Destruction"]
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
var gepd_hold: Array = []     # Galaxy-Eyes Photon Dragon: what it banished until the end of the Battle Phase
var defer_fx := false
var pending_fx: Array = []
## Whose card effect is resolving right now (-1: nobody's). "Destroyed by an opponent's card
## effect" is read from this.
var effect_by := -1
## The monster that declared the battle being worked out, and whether it attacked a monster.
var battle_attacker: CardInst = null
var battle_vs_monster := false
## The monster on the other side of the battle being worked out (Sonic Chick looks at its ATK).
var battle_foe: CardInst = null
## The player who takes no battle damage from the battle in progress (Defense Draw). -1: nobody.
var battle_shield := -1
## True while an attack is being worked out (the Damage Step).
var in_damage_step := false


## Pick n of cands. `auto` is what the rules would take on their own (AI, tests, a forced pick).
func choose(who: int, prompt: String, cands: Array, n := 1, auto: Array = [], optional := false, source: CardInst = null) -> Array:
	var uniq: Array = []
	for x in cands:
		if x != null and not uniq.has(x):
			uniq.append(x)
	if auto.is_empty() and not optional:
		auto = uniq.slice(0, n)
	# A human always makes the pick, even when there is only one card it could be.
	if not manual[who] or uniq.is_empty() or (uniq.size() < n and not optional):
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
		var text := str(c.data.get("desc", "")).to_lower()
		if not f["ctx"].get("_ign", false) and ("you can" in text or text.length() < 100 or " can " in str(EffectRunner.fx(c).get("note", "")).to_lower()):
			if choose_option(q, Loc.t("Activate the effect of %s?") % c.cname(), ["Activate", "Don't"], 0, c) == 1:
				continue
		chain.append({"player": q, "card": c, "kind": "fx", "spec": {"k": "fx"}, "target": null, "subject": null,
				"window": "open", "negated": false, "zone": -1, "actions": f["actions"], "ctx": f["ctx"]})
		events.append({"type": "effect", "player": q, "card": c, "text": Loc.t("%s: effect activated") % c.cname()})
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
	for ps0 in players:
		ps0.extra_normals = 0
	phase = Phase.DRAW
	var events := [{"type": "turn", "player": current, "turn": turn}, {"type": "phase", "phase": phase}]
	for q in 2:
		for m in players[q].monsters():
			if m.lv_set > 0 and m.lv_turn != -1 and m.lv_turn < turn:
				m.lv_set = 0   # a Level declared "until the end of this turn" is over
	events.append_array(_cleanup())
	if turn > 1:
		if players[current].skip_draw > 0:
			players[current].skip_draw -= 1
			events.append({"type": "effect", "player": current, "card": null, "text": "Draw Phase skipped"})
		else:
			var fated: CardInst = destiny_next[current]
			destiny_next[current] = null
			if fated != null and players[current].deck.has(fated):
				# Destiny Draw: the card they reached for is on top.
				players[current].deck.erase(fated)
				players[current].deck.append(fated)
				destiny_used[current] = true
				events.append({"type": "destiny", "player": current, "card": fated})
			var drew := _draw(current)
			events.append_array(drew)
			# Destiny HERO - Dasher, once while it is in the Graveyard: a monster you draw in your
			# Draw Phase can be shown and Special Summoned.
			if not is_over() and not drew.is_empty() and drew[0].get("type", "") == "draw":
				var got: CardInst = drew[0]["card"]
				var ps := players[current]
				for g in ps.gy:
					if got.is_monster() and not CardData.is_extra(got.id) and not g.once and CardEffects.of(g.cname()).get("gy_summon_drawn", false) and ps.free_zone() != -1 and ps.hand.has(got):
						if choose_option(current, Loc.t("%s: Special Summon %s, the monster you just drew?") % [g.cname(), got.cname()], ["Special Summon it", "Keep it in hand"], 0, g) == 0:
							g.once = true
							ps.hand.erase(got)
							events.append({"type": "effect", "player": current, "card": g, "text": Loc.t("%s calls out %s") % [g.cname(), got.cname()]})
							events.append_array(_special(current, got, "effect"))
						break
		if is_over():
			return events
	if step:
		return events
	events.append_array(begin_standby())
	if is_over():
		return events
	events.append_array(begin_main1())
	return events


## Destiny Draw is offered just before your turn begins: you are in trouble (2000 LP or less, or
## less than half of your opponent's), you have not used it this duel, and you will draw.
func can_destiny(p: int) -> bool:
	if not destiny or not destiny_who[p] or destiny_used[p] or is_over() or p != current or turn < 1:
		return false
	var ps := players[p]
	if ps.skip_draw > 0 or ps.deck.is_empty():
		return false
	return ps.lp <= DESTINY_LP or ps.lp * 2 < players[opponent(p)].lp


## Reach for that card: it is the one your Draw Phase draws.
func set_destiny(p: int, c: CardInst) -> bool:
	if not can_destiny(p) or c == null or not players[p].deck.has(c):
		return false
	destiny_next[p] = c
	return true


## The duel screen walks the turn phase by phase (begin_turn(true), begin_standby, begin_main1)
## so both players get their chance to act in each one.
func begin_standby() -> Array:
	phase = Phase.STANDBY
	var events := [{"type": "phase", "phase": phase}]
	if turbo and turn > 1:
		for q in [current, opponent(current)]:
			events.append_array(_speed(q, 1))
		# Slipstream: whoever is behind by 2000 or more tucks in and gains one extra.
		var gap: int = players[current].lp - players[opponent(current)].lp
		if absi(gap) >= 2000:
			var behind := current if gap < 0 else opponent(current)
			events.append_array(_speed(behind, 1))
			events.append({"type": "effect", "player": behind, "card": null, "text": Loc.t("Slipstream: +1 Speed Counter for the rider behind")})
	events.append_array(EffectRunner.standby(self, current))
	# Destiny HERO - Defender: in face-up Defense Position, the turn player draws 1 card.
	for m in players[opponent(current)].monsters():
		if not is_over() and m.face_up and not m.attack_pos and EffectRunner.fx(m).has("opp_standby_draw"):
			events.append({"type": "effect", "player": opponent(current), "card": m, "text": Loc.t("%s: the turn player draws 1 card") % m.cname()})
			events.append_array(_draw(current, int(EffectRunner.fx(m)["opp_standby_draw"])))
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
	var events := [{"type": "phase", "phase": phase}]
	# "At the start of your Battle Phase, for each Plant monster your opponent controls, this card
	# gains 1 additional attack during each Battle Phase this turn" (Rose Tentacles).
	for m in players[current].monsters():
		var per: String = str(EffectRunner.fx(m).get("extra_attack_per_opp_race", "")) if m.face_up and not m.negated else ""
		if per != "":
			var n := 0
			for o in players[opponent(current)].monsters():
				if o.face_up and str(o.data.get("race", "")) == per:
					n += 1
			m.bonus_attacks = n
			m.bonus_attacks_turn = turn
			if n > 0:
				events.append({"type": "effect", "player": current, "card": m, "text": Loc.t("%s can attack %d more times this turn") % [m.cname(), n]})
	return events


func enter_main2() -> Array:
	if phase != Phase.BATTLE:
		return []
	var events := _end_battle()
	phase = Phase.MAIN2
	events.push_front({"type": "phase", "phase": phase})
	return events


## The end of the Battle Phase: monsters that are banished after they attack (Big Jaws).
func _end_battle() -> Array:
	var events := []
	for m in players[current].monsters():
		if m.attacked_turn == turn and m.face_up and EffectRunner.fx(m).get("banish_after_attack", false):
			events.append({"type": "effect", "player": current, "card": m, "text": Loc.t("%s is banished at the end of the Battle Phase") % m.cname()})
			events.append_array(_banish(m))
		elif m.attacked_turn == turn and m.face_up and m.attack_pos and EffectRunner.fx(m).get("def_end_battle", false):
			# "If this card attacks, it is changed to Defense Position at the end of the Battle Phase."
			m.attack_pos = false
			events.append({"type": "position", "player": current, "card": m, "zone": players[current].field.find(m)})
			if EffectRunner.fx(m).get("pos_lock_next_turn", false):
				m.pos_lock_until = turn + 2   # ...and stays that way until the end of your next turn
	# Galaxy-Eyes Photon Dragon: the two monsters it took out of the battle come back.
	for hold in gepd_hold:
		for part in [["dragon", "dragon_side"], ["other", "other_side"]]:
			var c: CardInst = hold[part[0]]
			var side: int = hold[part[1]]
			if players[c.owner].banished.has(c) and players[side].free_zone() != -1:
				players[c.owner].banished.erase(c)
				events.append({"type": "unbanish", "player": side, "card": c, "to": "field"})
				events.append_array(_special(side, c, "effect", "atk" if hold[part[0] + "_atk"] else "def"))
				if part[0] == "dragon" and int(hold["mats"]) > 0:
					c.atk_mod += 500 * int(hold["mats"])
					events.append({"type": "effect", "player": side, "card": c, "text": Loc.t("%s gains %d ATK") % [c.cname(), 500 * int(hold["mats"])]})
	gepd_hold.clear()
	return events


func end_turn() -> Array:
	var events := begin_end()
	events.append_array(finish_turn())
	return events


func begin_end() -> Array:
	var after_battle: Array = _end_battle() if phase == Phase.BATTLE else []
	phase = Phase.END
	var events := [{"type": "phase", "phase": phase}]
	events.append_array(after_battle)
	# Stardust Dragon: if it was Tributed for its effect this turn, it comes back from the Graveyard.
	for q in 2:
		for g in players[q].gy.duplicate():
			if g.flag_turn == turn and CardEffects.of(g.cname()).get("stardust", false) and players[q].free_zone() != -1:
				players[q].gy.erase(g)
				g.flag_turn = -1
				events.append({"type": "effect", "player": q, "card": g, "text": Loc.t("%s returns") % g.cname()})
				events.append_array(_special(q, g, "reborn"))
	# Banished "until the End Phase" (Junk Archer, Shooting Star Dragon): they come back now.
	for q in 2:
		for ex in players[q].exiles.duplicate():
			if not ex.get("end", false):
				continue
			players[q].exiles.erase(ex)
			var back: CardInst = ex["card"]
			if players[back.owner].banished.has(back):
				players[back.owner].banished.erase(back)
				events.append({"type": "effect", "player": int(ex["to"]), "card": back, "text": Loc.t("%s returns to the field") % back.cname()})
				events.append_array(_special(int(ex["to"]), back, "return", "atk" if ex["atk_pos"] else "def"))
	# Slifer the Sky Dragon, Special Summoned: to the Graveyard in the End Phase.
	for q in 2:
		for m in players[q].monsters():
			if m.face_up and m.tags.get("gy_end", false):
				events.append({"type": "effect", "player": q, "card": m, "text": Loc.t("%s was Special Summoned: it goes to the Graveyard") % m.cname()})
				players[q].field[players[q].field.find(m)] = null
				_to_gy(players[q], m)
				events.append({"type": "destroy", "player": q, "card": m, "zone": -1, "overlays": []})
				events.append_array(_monster_left(m))
	# Slip Summon: the monster it brought out goes back to the hand.
	for q in 2:
		for m in players[q].monsters():
			if m.tags.get("bounce_end", false):
				events.append({"type": "effect", "player": q, "card": m, "text": Loc.t("%s returns to the hand") % m.cname()})
				events.append_array(_bounce(m))
	# Hyper Synchron: the Dragon it powered up is banished in the End Phase.
	for q in 2:
		for m in players[q].monsters():
			if m.face_up and m.tags.get("banish_end", false):
				events.append({"type": "effect", "player": q, "card": m, "text": Loc.t("%s is banished in the End Phase") % m.cname()})
				events.append_array(_banish(m))
	# Fake Hero: the monster it brought out goes back to the hand (same as Slip Summon above).
	# Neos Contact Fusions: "During the End Phase: Shuffle this card into the Extra Deck."
	for q in 2:
		for m in players[q].monsters():
			if not players[q].field.has(m) or not m.face_up or m.negated:
				continue
			var nr := str(EffectRunner.fx(m).get("neos_return", ""))
			if nr == "":
				continue
			if neos_stays(m):
				# Neo Space / Instant Neo Space: it "does not have to" go back. Your call.
				var keep_auto := 0
				if choose_option(q, Loc.t("%s: shuffle it into the Extra Deck?") % m.cname(), ["Keep it on the field", "Shuffle it into the Extra Deck"], keep_auto, m) == 0:
					continue
			events.append({"type": "effect", "player": q, "card": m, "text": Loc.t("%s returns to the Extra Deck") % m.cname()})
			var who := m.cname()
			events.append_array(_bounce(m))
			if nr == "storm" or nr == "magma":
				# Storm Neos: "Shuffle all cards on the field into the Deck." Magma Neos: "Return all cards on the field to the hand."
				events.append({"type": "effect", "player": q, "card": m, "text": (Loc.t("%s: every card on the field is shuffled into the Deck") if nr == "storm" else Loc.t("%s: every card on the field returns to the hand")) % who})
				var was_by2 := effect_by
				effect_by = q
				for q2 in 2:
					var all: Array = players[q2].monsters()
					all.append_array(players[q2].set_cards())
					if players[q2].field_spell != null:
						all.append(players[q2].field_spell)
					for x in all:
						events.append_array(_to_deck(x) if nr == "storm" else _bounce(x))
				effect_by = was_by2
	events.append_array(EffectRunner.end_phase(self, current))
	events.append_array(EffectRunner.end_phase_any(self))
	# "...until the End Phase, this card's name becomes..." (Neo-Spacian Dark Panther).
	for q in 2:
		for m in players[q].monsters():
			m.tags.erase("as")
	return events


func finish_turn() -> Array:
	var events := []
	var ps := players[current]
	var over := ps.hand.size() - HAND_LIMIT
	if over > 0:
		# Hand limit: the turn player discards down to six, their pick.
		var by_value: Array = ps.hand.duplicate()
		by_value.sort_custom(func(a, b): return _card_value(a) < _card_value(b))
		for worst in choose(current, Loc.t("Hand limit: discard %d card%s") % [over, "" if over == 1 else "s"], ps.hand, over, by_value.slice(0, over)):
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
	var was_empty := turn > 0 and players[p].hand.is_empty()      # (the opening hand is dealt, not drawn)
	var drawn: Array = []
	for i in count:
		var ps := players[p]
		if ps.deck.is_empty():
			_set_winner(opponent(p), Loc.t("%s has no cards left to draw.") % ps.name)
			events.append({"type": "win", "player": winner, "reason": win_reason})
			return events
		var c: CardInst = ps.deck.pop_back()
		ps.hand.append(c)
		drawn.append(c)
		events.append({"type": "draw", "player": p, "card": c, "deck": ps.deck.size()})
	if not drawn.is_empty() and turn > 0:
		# Silent Magician LV4: "Each time your opponent draws a card(s), place 1 Spell Counter on this card (max. 5)."
		for sm in players[opponent(p)].monsters():
			var cap := int(EffectRunner.fx(sm).get("counter_on_opp_draw", 0)) if sm.face_up else 0
			if cap > 0 and sm.counter < cap:
				sm.counter += 1
				if sm.counter == cap:
					sm.tags["full_turn"] = turn
				events.append({"type": "effect", "player": opponent(p), "card": sm, "text": Loc.t("%s: Spell Counter %d") % [sm.cname(), sm.counter]})
	events.append_array(_check_exodia())
	if effect_by != -1 and not is_over():
		# A draw a card effect gave you counts as "added from your Deck to your hand by a card effect" (Watapon).
		for d in drawn:
			events.append_array(EffectRunner.added_by_effect(self, p, d))
	# "When you draw a card(s) while you have no cards in your hand, and you draw this card: You can
	# reveal this card; Special Summon it from your hand" (Infernity Archfiend).
	if was_empty and not is_over():
		for d in drawn:
			if players[p].hand.has(d) and d.is_monster() and EffectRunner.fx(d).get("draw_summon", false) and players[p].free_zone() != -1:
				if choose_option(p, Loc.t("%s: reveal it and Special Summon it?") % d.cname(), [Loc.t("Special Summon it"), Loc.t("Keep it in your hand")], 0, d) == 0:
					players[p].hand.erase(d)
					events.append({"type": "effect", "player": p, "card": d, "text": Loc.t("%s is revealed and Special Summoned") % d.cname()})
					events.append_array(_special(p, d, "effect"))
					events.append_array(EffectRunner.on_summon(self, p, d, "special"))
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
			_set_winner(q, Loc.t("%s assembled all five pieces of Exodia!") % players[q].name)
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
	if CardEffects.of(c.cname()).has("tributes"):
		return int(CardEffects.of(c.cname())["tributes"])   # "Requires 3 Tributes to Normal Summon" (Slifer the Sky Dragon)
	if c.level() >= 5 and EffectRunner.no_tribute(self, c.owner, c):
		return 0
	if c.level() >= 5 and necroshade_for(c) != null:
		return 0
	if CardEffects.of(c.cname()).has("free_summon_atk"):
		return 0   # "You can Normal Summon this card without Tributing, but its original ATK becomes 1800" (Dododo Warrior)
	if c.level() >= 7 and kaiser_for(c) != null:
		return 1   # Kaiser Sea Horse: "can be treated as 2 Tributes for the Tribute Summon of a LIGHT monster"
	if c.level() >= 7:
		return 2
	if c.level() >= 5:
		return 1
	return 0


## The monster this player controls that counts as 2 Tributes for `c` (Kaiser Sea Horse for a LIGHT monster), or null.
func kaiser_for(c: CardInst) -> CardInst:
	for m in tributable(c.owner):
		if m.face_up and not m.negated and str(EffectRunner.fx(m).get("double_tribute_attr", "-")) == str(c.data.get("attribute", "")):
			return m
	return null


## Lord of D.: "Neither player can target Dragon monsters on the field with card effects."
func dragon_shield() -> bool:
	for q in 2:
		for m in players[q].monsters():
			if m.face_up and not m.negated and EffectRunner.fx(m).get("dragon_shield", false):
				return true
	return false


## Elemental HERO Necroshade: "Once, while this card is in the GY, you can Normal Summon 1 Level 5
## or higher "Elemental HERO" monster without Tributing." The Necroshade that can still do it.
func necroshade_for(c: CardInst) -> CardInst:
	if c == null or c.level() < 5 or not str(c.data.get("name", "")).contains("Elemental HERO"):
		return null
	for g in players[c.owner].gy:
		if not g.once and CardEffects.of(g.cname()).get("necroshade", false):
			return g
	return null


func can_normal_summon(p: int, c: CardInst) -> bool:
	if CardEffects.of(c.cname()).get("one_only", false):
		for m in players[p].monsters():
			if m.face_up and m.cname() == c.cname():
				return false   # "You can only control 1"
	if p != current or not _in_main() or (normal_summoned and players[p].extra_normals <= 0) or is_over():
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
	return players[p].monsters().filter(func(m): return not m.data.get("no_tribute_summon", false) and m.no_tribute_turn != turn)


func normal_summon(p: int, c: CardInst, tributes: Array, set_card := false) -> Array:
	if not can_normal_summon(p, c) or tributes.size() != tributes_needed(c):
		return []
	tributes = tributes.duplicate()
	if tributes.size() == 1 and c.level() >= 7 and kaiser_for(c) != null and str(EffectRunner.fx(tributes[0]).get("double_tribute_attr", "-")) != str(c.data.get("attribute", "")):
		tributes = [kaiser_for(c)]   # (one Tribute is only enough when it is the Kaiser Sea Horse)
	if not set_card and players[p].no_summon_turn == turn:
		return []
	if set_card and CardEffects.of(c.cname()).get("no_set", false):
		return []   # "cannot be Normal Set"
	var free_atk := int(CardEffects.of(c.cname()).get("free_summon_atk", 0))
	if free_atk > 0 and set_card and tributes.is_empty():
		return []   # (only the Normal Summon is free; a Set still needs its Tribute)
	if free_atk > 0 and tributes.is_empty() and manual[p] and not tributable(p).is_empty():
		# Your call: Tribute 1 monster and keep its full ATK, or bring it out for free at the lower ATK.
		if choose_option(p, Loc.t("%s: Tribute 1 monster to keep its full ATK?") % c.cname(), [Loc.t("No Tribute: ATK %d") % free_atk, Loc.t("Tribute 1 monster: ATK %d") % c.atk()], 0, c) == 1:
			tributes = [pick1(p, Loc.t("%s: Tribute which monster?") % c.cname(), tributable(p), tributable(p)[0], c)]
			free_atk = 0
	# Elemental HERO Necroshade lets you Normal Summon without Tributing (a Set is not a Normal Summon).
	var necro: CardInst = null
	if tributes.is_empty() and c.level() >= 5 and not CardEffects.of(c.cname()).has("tributes") and not EffectRunner.no_tribute(self, c.owner, c):
		necro = necroshade_for(c)
		if necro != null and set_card:
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
		events.append_array(EffectRunner.trigger(self, t, "tributed"))
		# An Equip Card on a Tributed monster goes with it, right now (it used to sit there,
		# looking active, until the next sweep).
		events.append_array(_monster_left(t))
	var zone := ps.free_zone()
	ps.hand.erase(c)
	ps.field[zone] = c
	c.face_up = not set_card
	c.attack_pos = not set_card
	c.summoned_turn = turn
	c.pos_changed_turn = -1
	c.attacked_turn = -1
	c.reset_mods()
	if normal_summoned:
		ps.extra_normals -= 1   # Double Summon: this is the second one
	normal_summoned = true
	# Level Warrior: "If there are no monsters on the field, you can Normal Summon this card as a Level 2 monster."
	var as_lv := int(CardEffects.of(c.cname()).get("lv_normal_if_empty", 0))
	if as_lv > 0 and not set_card and ps.monsters().size() == 1 and players[opponent(p)].monsters().is_empty():
		if choose_option(p, Loc.t("%s: Normal Summon it as a Level %d monster?") % [c.cname(), as_lv], [Loc.t("Level %d") % as_lv, Loc.t("Level %d") % int(c.data.get("level", 0))], 0, c) == 0:
			c.lv_set = as_lv
			c.lv_turn = -1
	events.append({"type": "set" if set_card else "summon", "player": p, "card": c, "zone": zone})
	if free_atk > 0 and tributes.is_empty() and not set_card:
		c.atk_mod -= c.atk() - free_atk
		events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s is Normal Summoned without Tributing: its ATK is %d") % [c.cname(), free_atk]})
	# Kagetokage: "When you Normal Summon a Level 4 monster: You can Special Summon this card from your hand."
	if not set_card and c.level() == 4 and ps.no_summon_turn != turn:
		for h in ps.hand.duplicate():
			if ps.free_zone() != -1 and CardEffects.of(h.cname()).get("kagetokage", false):
				if choose_option(p, Loc.t("%s: Special Summon it from your hand?") % h.cname(), ["Special Summon it", "Keep it in hand"], 0, h) == 0:
					ps.hand.erase(h)
					h.proper = true
					events.append({"type": "effect", "player": p, "card": h, "text": Loc.t("%s follows %s onto the field") % [h.cname(), c.cname()]})
					events.append_array(_special(p, h, "effect"))
				break
	if necro != null:
		necro.once = true
		events.append({"type": "effect", "player": p, "card": necro, "text": Loc.t("%s in the Graveyard: %s is Normal Summoned without Tributing") % [necro.cname(), c.cname()]})
	if not set_card:
		c.normal_turn = turn
		last_summoned = c
		ps.summons_turn = turn
		if CardEffects.of(c.cname()).get("no_response_summon", false):
			last_summoned = null   # "When Normal Summoned, cards and effects cannot be activated."
		events.append_array(_summon_tax(p, c))
		if not ps.field.has(c):
			return events
		events.append_array(summon_triggers(p, c))
		if tributes.is_empty() and int(c.data.get("level", 0)) >= 5:
			# Normal Summoned without Tributing by its own rule (Galaxy Knight).
			events.append_array(EffectRunner.trigger(self, c, "free_summon"))
		events.append_array(EffectRunner.on_summon(self, p, c, "normal"))
		# Dark Verger: when a Plant Tuner is Normal Summoned to your side, it comes back from the Graveyard.
		if c.is_tuner() and str(c.data.get("race", "")) == "Plant":
			for g in ps.gy.duplicate():
				if ps.free_zone() != -1 and CardEffects.of(g.cname()).get("revive_on_plant_tuner", false):
					ps.gy.erase(g)
					events.append({"type": "effect", "player": p, "card": g, "text": Loc.t("%s returns from the Graveyard") % g.cname()})
					events.append_array(_special(p, g, "reborn", "atk"))
	return events


## Slifer the Sky Dragon: "If a monster(s) is Normal or Special Summoned to your opponent's field in
## Attack Position: That monster(s) loses 2000 ATK, then if its ATK has been reduced to 0 as a
## result, destroy it."
func _summon_tax(p: int, c: CardInst) -> Array:
	var events := []
	if not c.face_up or not c.attack_pos or not players[p].field.has(c):
		return events
	for m in players[opponent(p)].monsters():
		var tax := int(EffectRunner.fx(m).get("summon_tax", 0)) if m.face_up else 0
		if tax <= 0 or not players[p].field.has(c):
			continue
		c.atk_mod -= tax
		events.append({"type": "effect", "player": opponent(p), "card": m, "text": Loc.t("%s: %s loses %d ATK") % [m.cname(), c.cname(), tax]})
		if atk_of(c, false) <= 0:
			var was_by := effect_by
			effect_by = opponent(p)
			events.append({"type": "effect", "player": opponent(p), "card": m, "text": Loc.t("%s is left with 0 ATK and is destroyed") % c.cname()})
			events.append_array(_destroy(c))
			effect_by = was_by
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
			and c.attacked_turn != turn and c.pos_lock_until < turn
			and not SpellRules.equip_flag(self, c, "no_move"))


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
	if turbo and not c.is_trap():
		# Speed World 2 holds the Field Zone, and Spells need speed.
		if sp["k"] == "field" or ps.speed < speed_need(c):
			return false
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
	# A card written for a moment (an attack, a summon) can only be used in that moment.
	var wins: Array = sp.get("win", [])
	if not wins.is_empty() and not wins.has("free"):
		return false
	if sp.has("modes"):
		return not SpellRules.open_modes(self, p, c, "open", null).is_empty()
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
	if sp.has("modes"):
		# A card with more than one effect: the player says which one, before anything else.
		var open: Array = SpellRules.open_modes(self, p, c, window, subject)
		if open.is_empty():
			return []
		var labels: Array = []
		for mi in open:
			labels.append(str(sp["modes"][mi]["label"]))
		c.mode = open[choose_option(p, Loc.t("%s: which effect?") % c.cname(), labels, 0, c)]
		sp = SpellRules.spec(c)
	if target == null and not sp.has("legacy") and SpellRules._needs_target(sp):
		var auto_t = SpellRules.auto_target(self, p, c)
		var picked := choose(p, Loc.t("Choose a target for %s") % c.cname(), SpellRules.targets(self, p, c), 1, [auto_t] if auto_t != null else [], false, c)
		target = picked[0] if not picked.is_empty() else auto_t
		if not manual[p] and auto_t != null:
			target = auto_t        # (the computer takes the target that is of use to it, never just the first on the list)
	var link := {"player": p, "card": c, "kind": "trap" if c.is_trap() else "spell", "spec": sp, "target": target,
			"subject": subject, "window": window, "negated": false, "zone": zone}
	events.append_array(SpellRules.pay_cost(self, p, c, sp))
	if c.is_spell():
		ps.spell_turn = turn
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
		# Cyber Blader, while its opponent controls exactly 3 monsters: "Your opponent's activated card
		# effects are negated."
		if not link["negated"] and EffectRunner.blader_negates(self, p):
			link["negated"] = true
			events.append({"type": "effect", "player": opponent(p), "card": null, "text": Loc.t("Cyber Blader negates %s") % c.cname()})
		if link["kind"] == "fx":
			# A monster effect. It still resolves if the monster has left the field.
			if link["negated"] or c.negated:
				events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s's effect is negated") % c.cname()})
			else:
				var ctx: Dictionary = link["ctx"].duplicate()
				ctx["_now"] = true
				events.append_array(EffectRunner.run_list(self, p, c, link["actions"], ctx))
			continue
		var here := ps.spells.has(c) or ps.field_spell == c
		var stays: bool = SpellRules.PERSIST.has(sp["k"])
		if link["negated"] or (not here and stays):
			events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s is negated") % c.cname()})
		elif sp.has("legacy"):
			var was_by := effect_by
			effect_by = p
			events.append_array(_legacy_trap(p, c, link["subject"]) if c.is_trap() else _legacy_spell(p, c, link["target"]))
			effect_by = was_by
			stays = false
		else:
			var was_by2 := effect_by
			effect_by = p
			events.append_array(SpellRules.resolve(self, link))
			effect_by = was_by2
			stays = stays and link.get("stays", true) and not link["negated"]
		if c.is_spell() and not link["negated"]:
			# Skilled Dark Magician: "Each time a Spell Card is activated, place 1 Spell Counter on this card when that Spell resolves (max. 3)."
			for q in 2:
				for sk in players[q].monsters():
					var cap2 := int(EffectRunner.fx(sk).get("counter_on_spell", 0)) if sk.face_up else 0
					if cap2 > 0 and sk.counter < cap2:
						sk.counter += 1
						events.append({"type": "effect", "player": q, "card": sk, "text": Loc.t("%s: Spell Counter %d") % [sk.cname(), sk.counter]})
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
				var tied: Array = players[opponent(p)].monsters().filter(func(m): return m.face_up and atk_of(m, false) == atk_of(target, false))
				if tied.size() > 1:
					target = pick1(p, Loc.t("%s: these are tied. Choose 1") % c.cname(), tied, target, c)
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
			picks = choose(p, Loc.t("Soul Release: banish %d from their Graveyard") % picks.size(), players[opponent(p)].gy, picks.size(), picks, false, c)
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
			for g in choose(p, Loc.t("Return %d banished monsters to the Graveyard") % b3.size(), _best_monsters(ps.banished, 99), b3.size(), b3, false, c):
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
			and c.face_up and (c.attack_pos or EffectRunner.fx(c).get("direct_from_def", false)) and attacks_left(c) > 0 and SpellRules.can_attack(self, p, c)
			and not (players[p].only_attacker_turn == turn and players[p].only_attacker != c.uid)
			and not (EffectRunner.fx(c).get("summon_sick", false) and c.summoned_turn == turn)
			and players[p].lp >= int(EffectRunner.fx(c).get("attack_cost", 0))
			and not (EffectRunner.fx(c).get("attack_tribute", false) and players[p].monsters().size() < 2)
			and not (EffectRunner.fx(c).get("no_attack_with_others", false) and players[p].monsters().size() > 1)
			and players[opponent(p)].swords_left == 0)


func attacks_left(c: CardInst) -> int:
	var used := c.attack_count if c.attack_count_turn == turn else 0
	if used > 0 and used < 99 and EffectRunner.fx(c).get("attack_all", false):
		# Elemental HERO Wildedge: "one attack on each monster per Battle Phase".
		if int(c.tags.get("went_direct", -1)) == turn:
			return 0
		return 1 if not _not_hit_yet(c).is_empty() else 0
	return EffectRunner.max_attacks(c) + (c.bonus_attacks if c.bonus_attacks_turn == turn else 0) - used


## Wildedge: the opponent's monsters it has not attacked yet this Battle Phase.
func _not_hit_yet(c: CardInst) -> Array:
	var hit: Array = c.tags.get("hit", []) if int(c.tags.get("hit_turn", -1)) == turn else []
	var out := []
	for m in attack_targets(c.owner):
		if not hit.has(m.uid):
			out.append(m)
	return out


## Can this monster attack the opponent directly right now?
func can_direct_attack_with(p: int, c: CardInst) -> bool:
	if int(c.tags.get("no_direct_turn", -1)) == turn:
		return false   # Feather Shot: "but cannot attack directly"
	if not c.attack_pos:
		return EffectRunner.fx(c).get("direct_from_def", false)   # Elemental HERO Rampart Blaster
	if EffectRunner.fx(c).get("attack_all", false) and c.attack_count_turn == turn and c.attack_count > 0:
		return false   # Wildedge already attacked a monster: only the other monsters are left
	if c.tags.has("nitro_next"):
		return false   # Nitro Warrior's second attack is on one monster only
	if EffectRunner.fx(c).get("direct_needs_material", false) and c.overlays.is_empty():
		return false   # Number 17: Leviathan Dragon cannot attack directly without material
	return EffectRunner.can_direct(self, p, c)


func can_direct_attack(p: int) -> bool:
	# (If every monster they have is one you are not allowed to attack, the way is clear.)
	return attack_targets(p).is_empty()


## Monster effects activated from the field (once per turn, Main Phase).
func can_ignite(p: int, c: CardInst) -> bool:
	return EffectRunner.can_ignite(self, p, c)


func ignite(p: int, c: CardInst) -> Array:
	return EffectRunner.ignite(self, p, c)


## Effects that are activated from the Graveyard (Destiny HERO - Malicious): the cards of
## `p` that could use theirs right now.
func gy_effects(p: int) -> Array:
	var out := []
	if p != current or not _in_main() or is_over():
		return out
	for g in players[p].gy:
		if EffectRunner.gy_can(self, p, g):
			out.append(g)
	return out


## "You can discard this card; ..." (Harpie Queen): an effect a monster uses from your hand
## in your Main Phase.
func can_hand_ignite(p: int, c: CardInst) -> bool:
	return p == current and _in_main() and not is_over() and players[p].hand.has(c) and EffectRunner.hand_can(self, p, c)


func hand_ignite(p: int, c: CardInst) -> Array:
	if not can_hand_ignite(p, c):
		return []
	return EffectRunner.hand_run(self, p, c)


func gy_ignite(p: int, c: CardInst) -> Array:
	if not gy_effects(p).has(c):
		return []
	return EffectRunner.gy_run(self, p, c)


## Union monsters riding on `m` as Equip Cards (Y-Dragon Head, Z-Metal Tank).
func unions_on(m: CardInst) -> Array:
	var out := []
	for q in 2:
		for st in players[q].spells:
			if st != null and st.face_up and st.is_monster() and st.equipped_to == m:
				out.append(st)
	return out


## The monsters a Union monster on the field could be equipped to right now.
func union_hosts(p: int, c: CardInst) -> Array:
	var out := []
	var names: Array = EffectRunner.fx(c).get("union", {}).get("to", [])
	if EffectRunner.fx(c).get("union", {}).get("any", false):
		# Armory Arm: "Target 1 monster on the field; equip this card to that target."
		for q in [p, opponent(p)]:
			for m in players[q].monsters():
				if m != c and m.face_up:
					out.append(m)
		return out
	for m in players[p].monsters():
		if m != c and m.face_up and names.has(m.cname()):
			out.append(m)
	return out


## Toon monsters: anything with "Toon" in its name, and Manga Ryu-Ran.
func is_toon(m: CardInst) -> bool:
	if m == null or not m.is_monster():
		return false
	var n := m.cname()
	return n.begins_with("Toon ") or n.contains(" Toon ") or n.ends_with(" Toon") or n == "Manga Ryu-Ran"


func has_toon(q: int) -> bool:
	for m in players[q].monsters():
		if m.face_up and is_toon(m):
			return true
	return false


## Does this player have a face-up "Toon World"?
func toon_world(q: int) -> bool:
	for st in players[q].spells:
		if st != null and st.face_up and st.cname() == "Toon World":
			return true
	return false


## What this one monster may attack. The big Toons (Toon Mermaid, Toon Summoned Skull, Toon Dark
## Magician Girl) must go for a Toon monster when the other side has one.
func attack_targets_for(p: int, attacker: CardInst) -> Array[CardInst]:
	var out := attack_targets(p)
	if attacker != null and not attacker.attack_pos:
		var none: Array[CardInst] = []
		return none   # (Rampart Blaster in Defense Position can only attack directly)
	if attacker != null and EffectRunner.fx(attacker).get("attack_all", false) and attacker.attack_count_turn == turn and attacker.attack_count > 0:
		var left: Array[CardInst] = []
		for m in _not_hit_yet(attacker):
			left.append(m)
		return left
	if attacker != null and attacker.tags.has("nitro_next"):
		# Nitro Warrior's second attack in a row: only on the monster it turned to Attack Position.
		var one: Array[CardInst] = []
		for m in out:
			if m.uid == int(attacker.tags["nitro_next"]):
				one.append(m)
		return one
	if attacker != null and int(EffectRunner.fx(attacker).get("toon", 0)) == 2 and has_toon(opponent(p)):
		var only: Array[CardInst] = []
		for m in out:
			if m.face_up and is_toon(m):
				only.append(m)
		return only
	return out


func attack_allowed(p: int, attacker: CardInst, target) -> bool:
	if target == null:
		return can_direct_attack_with(p, attacker)
	return attack_targets_for(p, attacker).has(target)


func attack_targets(p: int) -> Array[CardInst]:
	var out: Array[CardInst] = []
	var shield := protected_race(opponent(p))
	for m in players[opponent(p)].monsters():
		if shield != "" and m.face_up and str(m.data.get("race", "")) == shield:
			continue
		# Magician's Valkyria: the other face-up Spellcasters on her side cannot be attacked.
		var guarded := false
		for v in players[opponent(p)].monsters():
			if v != m and v.face_up and m.face_up and str(EffectRunner.fx(v).get("protect_race_others", "")) == str(m.data.get("race", "")):
				guarded = true
		if not guarded:
			out.append(m)
	return out


## Twilight Rose Knight: while it is face-up, the other side cannot attack this player's Plants.
func protected_race(q: int) -> String:
	for m in players[q].monsters():
		if m.face_up and EffectRunner.fx(m).has("protect_race"):
			return str(EffectRunner.fx(m)["protect_race"])
	return ""


## Attack in one go (AI simulation and tests). The duel screen uses
## declare_attack + response window + resolve_attack instead.
func attack(p: int, attacker: CardInst, target: CardInst) -> Array:
	var ev := declare_attack(p, attacker, target)
	if ev.is_empty():
		return []
	ev.append_array(resolve_attack())
	return ev


var pending_attack := {}
## Shield Warrior: the monster that cannot be destroyed by the battle in progress.
var _shield: CardInst = null
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
	if target != null and not attack_targets_for(p, attacker).has(target):
		return []
	# "You must pay 500 LP to declare an attack with this monster" (Toon Mermaid, Toon Summoned Skull).
	var toll := int(EffectRunner.fx(attacker).get("attack_cost", 0))
	var paid := []
	if toll > 0:
		players[p].lp -= toll
		paid.append({"type": "lp", "player": p, "lp": players[p].lp, "delta": -toll})
	if EffectRunner.fx(attacker).get("attack_tribute", false):
		# "Cannot declare an attack unless you Tribute 1 monster" (Insect Queen).
		var fodder: Array = players[p].monsters().filter(func(m): return m != attacker and can_tribute_fx(m))
		if fodder.is_empty():
			return []
		var least: CardInst = fodder[0]
		for m in fodder:
			if atk_of(m, false) < atk_of(least, false):
				least = m
		least = pick1(p, Loc.t("%s: Tribute 1 monster to attack") % attacker.cname(), fodder, least, attacker)
		players[p].field[players[p].field.find(least)] = null
		_to_gy(players[p], least)
		paid.append({"type": "tribute", "player": p, "card": least})
		paid.append_array(EffectRunner.trigger(self, least, "tributed"))
		paid.append_array(_monster_left(least))
	attacker.attacked_turn = turn
	_shield = null
	if EffectRunner.fx(attacker).get("attack_all", false):
		if int(attacker.tags.get("hit_turn", -1)) != turn:
			attacker.tags["hit_turn"] = turn
			attacker.tags["hit"] = []
		if target != null:
			attacker.tags["hit"].append(target.uid)
		else:
			attacker.tags["went_direct"] = turn
	if target != null and not target.attack_pos:
		attacker.hit_def_turn = turn
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
	var events := paid + [{"type": "attack", "player": p, "card": attacker, "target": target}]
	if target != null and target.face_up and target.attack_pos and not target.negated and EffectRunner.fx(target).get("def_when_targeted", false):
		if choose_option(target.owner, Loc.t("%s: change it to Defense Position?") % target.cname(), ["Change to Defense Position", "No"], 0, target) == 0:
			target.attack_pos = false
			events.append({"type": "effect", "player": target.owner, "card": target, "text": Loc.t("%s changes to Defense Position") % target.cname()})
			events.append({"type": "position", "player": target.owner, "card": target, "zone": players[target.owner].field.find(target)})
	# A Mirror Wall already standing on the other side halves whatever attacks into it.
	for st in players[opponent(p)].spells:
		if st != null and st.face_up and SpellRules.spec(st).get("halve_attackers", false) and not attacker.has_meta("mirror_wall"):
			attacker.set_meta("mirror_wall", st)
			events.append({"type": "effect", "player": opponent(p), "card": st, "text": Loc.t("%s: %s loses half its ATK") % [st.cname(), attacker.cname()]})
	if target != null and target.face_up:
		var tf := EffectRunner.fx(target)
		# Number 39: Utopia: targeted for an attack with no material left, it is destroyed.
		if (tf.get("destroy_if_attacked_no_material", false) or target.cname() == "Number 39: Utopia") and target.overlays.is_empty() and not target.negated:
			events.append({"type": "effect", "player": opponent(p), "card": target, "text": Loc.t("%s has no material left and is destroyed") % target.cname()})
			events.append_array(_destroy(target))
		# Cyber Larva: targeted for an attack, its controller takes no battle damage for the rest of the turn.
		if tf.get("no_damage_when_targeted", false):
			players[opponent(p)].no_damage_turn = turn
			events.append({"type": "effect", "player": opponent(p), "card": target, "text": Loc.t("%s: no battle damage for the rest of this turn") % target.cname()})
		# Mad Archfiend: targeted for an attack in Attack Position, it changes to Defense Position.
		if tf.get("def_when_targeted", false) and target.attack_pos and players[opponent(p)].field.has(target):
			target.attack_pos = false
			events.append({"type": "position", "player": opponent(p), "card": target, "zone": players[opponent(p)].field.find(target)})
	attacker.tags.erase("nitro_next")
	# Turbo Synchron: "When this card declares an attack: You can change the attack target to Defense Position."
	if target != null and target.face_up and target.attack_pos and players[opponent(p)].field.has(target) and EffectRunner.fx(attacker).get("turbo_synchron", false):
		if choose_option(p, Loc.t("%s: change %s to Defense Position?") % [attacker.cname(), target.cname()], ["Change it to Defense Position", "Leave it"], 0, attacker) == 0:
			target.attack_pos = false
			events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("%s turns %s to Defense Position") % [attacker.cname(), target.cname()]})
			events.append({"type": "position", "player": opponent(p), "card": target, "zone": players[opponent(p)].field.find(target)})
	return events


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


var gy_fx_off := -1   # effects that activate in this player's Graveyard are negated until the end of the Damage Step (Dododo Warrior)
var bye_bye := -1     # Bye Bye Damage: battle damage this player takes in this battle comes back doubled at the other side


func resolve_attack() -> Array:
	if pending_attack.is_empty():
		return []
	in_damage_step = true
	battle_shield = int(pending_attack.get("no_damage_to", -1))
	var att0: CardInst = pending_attack["attacker"]
	if att0 != null and att0.face_up and not att0.negated and EffectRunner.fx(att0).get("negate_opp_gy_fx", false):
		gy_fx_off = opponent(int(pending_attack["player"]))   # Dododo Warrior
	var ev := _resolve_attack()
	in_damage_step = false
	battle_shield = -1
	gy_fx_off = -1
	bye_bye = -1
	return ev


func _resolve_attack() -> Array:
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
			return [{"type": "effect", "player": opp, "card": m, "text": Loc.t("%s negates the attack!") % m.cname()},
				{"type": "attack_stopped", "player": p, "card": attacker}]
	var events := [{"type": "battle", "player": p, "card": attacker, "target": target}]
	battle_attacker = attacker
	battle_vs_monster = target != null
	var a := atk_of(attacker, true, target, true)
	if target == null and EffectRunner.fx(attacker).get("direct_orig", false) and not players[opp].monsters().is_empty():
		# "...when it does so using this effect, the battle damage is the original ATK of this card."
		a = attacker.atk()
	# Neo-Spacian Glow Moss: "If this card attacks or is attacked: Your opponent draws 1 card and shows it".
	for pair1 in [[attacker, true], [target, false]]:
		if pair1[0] == null:
			continue
		var moss: CardInst = pair1[0]
		if moss.face_up and not moss.negated and EffectRunner.fx(moss).get("glow_moss", false) and not players[opponent(moss.owner)].deck.is_empty():
			var mo := moss.owner
			var drawn: CardInst = players[opponent(mo)].deck[0]
			events.append({"type": "effect", "player": mo, "card": moss, "text": Loc.t("%s: the opponent draws 1 card and shows it") % moss.cname()})
			events.append_array(_draw(opponent(mo), 1))
			events.append({"type": "effect", "player": opponent(mo), "card": drawn, "text": Loc.t("The card drawn is %s") % drawn.cname()})
			if drawn.is_monster():
				events.append({"type": "effect", "player": mo, "card": moss, "text": Loc.t("A monster: the Battle Phase ends")})
				players[current].no_attack_turn = turn
				events.append({"type": "attack_stopped", "player": p, "card": attacker})
				return events
			elif drawn.is_spell():
				if pair1[1] and target != null and choose_option(mo, Loc.t("%s: make it a direct attack?") % moss.cname(), ["Attack directly", "Keep the attack on the monster"], 0, moss) == 0:
					events.append({"type": "effect", "player": mo, "card": moss, "text": Loc.t("A Spell: %s attacks directly instead") % moss.cname()})
					var before_m := players[opp].lp
					events.append_array(_battle_damage(opp, a, attacker, null))
					if players[opp].lp < before_m:
						attacker.tags["hit_direct"] = turn
						events.append_array(EffectRunner.trigger(self, attacker, "damage"))
					events.append_array(_after_attack(attacker, null))
					return events
			elif moss.attack_pos:
				moss.attack_pos = false
				events.append({"type": "effect", "player": mo, "card": moss, "text": Loc.t("A Trap: %s changes to Defense Position") % moss.cname()})
				events.append({"type": "position", "player": mo, "card": moss, "zone": players[mo].field.find(moss)})
				if moss == attacker:
					events.append({"type": "attack_stopped", "player": p, "card": attacker})
					return events
	if target == null and not attacker.attack_pos:
		# Rampart Blaster: "apply its ATK for damage calculation, and its ATK is halved during damage calculation only."
		a = int(ceil(a / 2.0))
	if target == null:
		var before := players[opp].lp
		events.append_array(_battle_damage(opp, a, attacker, null))
		if players[opp].lp < before:
			attacker.tags["hit_direct"] = turn
			events.append_array(EffectRunner.trigger(self, attacker, "damage"))
		events.append_array(_after_attack(attacker, target))
		return events
	# Junk Berserker: "At the start of the Damage Step, if this card attacks a Defense Position
	# monster: Destroy that monster." (An effect, before the monster is even flipped.)
	if not target.attack_pos and EffectRunner.fx(attacker).get("kill_def_start", false):
		events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("%s destroys the Defense Position monster outright") % attacker.cname()})
		var was_by0 := effect_by
		effect_by = p
		events.append_array(_destroy(target))
		effect_by = was_by0
		if not players[opp].field.has(target):
			events.append_array(_after_attack(attacker, null))
			return events
	# Neo-Spacian Grand Mole: "At the start of the Damage Step, if this card battles an opponent's
	# monster: You can return both the opponent's monster and this card to the hand."
	for pair0 in [[attacker, target], [target, attacker]]:
		var mole: CardInst = pair0[0]
		var foe0: CardInst = pair0[1]
		if mole.face_up and not mole.negated and EffectRunner.fx(mole).get("grand_mole", false):
			var auto_m := 0 if (foe0.frame() in ["fusion", "synchro", "xyz"] or not foe0.face_up or atk_of(foe0, false) >= atk_of(mole, false) or foe0.level() >= 5) else 1
			if choose_option(mole.owner, Loc.t("%s: return it and %s to the hand?") % [mole.cname(), foe0.cname() if foe0.face_up else Loc.t("the face-down monster")], ["Return both to the hand", "No, battle"], auto_m, mole) == 0:
				events.append({"type": "effect", "player": mole.owner, "card": mole, "text": Loc.t("%s sends both monsters back to the hand") % mole.cname()})
				var was_by1 := effect_by
				effect_by = mole.owner
				events.append_array(_bounce(foe0))
				events.append_array(_bounce(mole))
				effect_by = was_by1
				events.append_array(_after_attack(attacker, null) if players[p].field.has(attacker) else [])
				return events
	var was_down: bool = not target.face_up
	if not target.face_up:
		target.face_up = true
		events.append({"type": "reveal", "player": opp, "card": target, "zone": players[opp].field.find(target)})
		events.append_array(EffectRunner.trigger(self, target, "flip"))
	target.tags["was_down"] = was_down
	var kill_def: bool = attacker.cname() == "Zubaba Knight" or EffectRunner.fx(attacker).get("kill_def", false)
	if kill_def and not target.attack_pos:
		events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("%s destroys it outright!") % attacker.cname()})
		events.append_array(_battle_kill(attacker, target))
		events.append_array(_after_attack(attacker, target))
		return events
	var target_was_def: bool = not target.attack_pos
	# "When this card inflicts battle damage to your opponent" counts every kind of battle,
	# not only direct attacks, and works for the monster that was attacked too.
	var lp_opp := players[opp].lp
	var lp_me := players[p].lp
	if target.attack_pos:
		var t := atk_of(target, false, attacker, true)
		# Turbo Warrior: attacking a Level 6 or higher Synchro Monster, that monster's ATK is halved
		# until the end of the Damage Step.
		if EffectRunner.fx(attacker).get("halve_synchro6", false) and target.frame() == "synchro" and target.level() >= 6:
			t = int(ceil(t / 2.0))
			events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("%s halves %s's ATK for this battle") % [attacker.cname(), target.cname()]})
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
				var lp_pierce := players[opp].lp
				events.append_array(_battle_damage(opp, a - d, attacker, target))
				# Drill Synchron: "Once per turn, when you inflict battle damage to your opponent with this effect: You can draw 1 card."
				if players[opp].lp < lp_pierce and not is_over():
					for dr in players[p].monsters():
						var race_p := str(EffectRunner.fx(dr).get("pierce_own_race", "")) if dr.face_up else ""
						if race_p != "" and race_p == str(attacker.data.get("race", "")) and int(dr.tags.get("drill_draw", -1)) != turn and not players[p].deck.is_empty():
							if choose_option(p, Loc.t("%s: draw 1 card?") % dr.cname(), ["Draw 1 card", "No"], 0, dr) == 0:
								dr.tags["drill_draw"] = turn
								events.append({"type": "effect", "player": p, "card": dr, "text": Loc.t("%s: draw 1 card") % dr.cname()})
								events.append_array(_draw(p, 1))
							break
		elif a < d:
			var dmg := d - a
			if EffectRunner.fx(target).get("double_damage_attacked", false):
				dmg *= 2
			events.append_array(_battle_damage(p, dmg, target, attacker))
	# Hyper Hammerhead: "At the end of the Damage Step, if an opponent's monster that battled this card
	# is not destroyed: return that opponent's monster to the hand."
	if not is_over() and target != null:
		for pair in [[attacker, target], [target, attacker]]:
			var mine: CardInst = pair[0]
			var theirs: CardInst = pair[1]
			var on_field: bool = players[0].field.has(theirs) or players[1].field.has(theirs)
			if mine.face_up and not mine.negated and EffectRunner.fx(mine).get("bounce_survivor", false) and on_field and (players[0].field.has(mine) or players[1].field.has(mine) or players[mine.owner].gy.has(mine)):
				events.append({"type": "effect", "player": mine.owner, "card": mine, "text": Loc.t("%s sends %s back to the hand") % [mine.cname(), theirs.cname()]})
				events.append_array(_bounce(theirs))
	if not is_over():
		if players[opp].lp < lp_opp and players[p].field.has(attacker):
			events.append_array(EffectRunner.trigger(self, attacker, "damage"))
		if players[p].lp < lp_me and players[opp].field.has(target):
			events.append_array(EffectRunner.trigger(self, target, "damage"))
	# Turbo Synchron: "When you take battle damage while this card is attacking: You can Special
	# Summon 1 monster from your hand with ATK less than or equal to the battle damage you took."
	if not is_over() and players[p].lp < lp_me and CardEffects.of(attacker.cname()).get("turbo_synchron", false) and not attacker.negated and players[p].free_zone() != -1 and players[p].no_summon_turn != turn:
		var took: int = lp_me - players[p].lp
		var fits_dmg: Array = players[p].hand.filter(func(h): return h.is_monster() and h.atk() <= took and not CardData.is_extra(h.id) and not CardEffects.of(h.cname()).get("no_special", false) and h.frame() != "ritual")
		if not fits_dmg.is_empty():
			fits_dmg.sort_custom(func(x, y): return x.atk() > y.atk())
			var called := choose(p, Loc.t("%s: Special Summon 1 monster with %d or less ATK from your hand") % [attacker.cname(), took], fits_dmg, 1, [fits_dmg[0]], true, attacker)
			if not called.is_empty():
				var hm: CardInst = called[0]
				players[p].hand.erase(hm)
				events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("%s calls %s") % [attacker.cname(), hm.cname()]})
				events.append_array(_special(p, hm, "effect"))
				events.append_array(EffectRunner.on_summon(self, p, hm, "special"))
	# Nitro Warrior: "If this attacking card destroys an opponent's monster by battle, after damage
	# calculation: You can target 1 face-up Defense Position monster your opponent controls; change
	# that target to Attack Position, then this card can make a second attack in a row, on that monster."
	if not is_over() and EffectRunner.fx(attacker).get("nitro_chain", false) and players[p].field.has(attacker) and attacker.attack_count == 1 \
			and target.died_turn == turn and not players[opp].field.has(target):
		var downs: Array = players[opp].monsters().filter(func(m): return m.face_up and not m.attack_pos)
		if not downs.is_empty():
			downs.sort_custom(func(x, y): return atk_of(x, false) < atk_of(y, false))
			var easy: Array = [downs[0]] if atk_of(downs[0], false) < atk_of(attacker, false) else []
			var next := choose(p, Loc.t("%s: turn 1 Defense Position monster to Attack Position and attack it?") % attacker.cname(), downs, 1, easy, true, attacker)
			if not next.is_empty():
				var nt: CardInst = next[0]
				nt.attack_pos = true
				events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("%s forces %s to Attack Position and can attack it") % [attacker.cname(), nt.cname()]})
				events.append({"type": "position", "player": opp, "card": nt, "zone": players[opp].field.find(nt)})
				attacker.bonus_attacks = (attacker.bonus_attacks if attacker.bonus_attacks_turn == turn else 0) + 1
				attacker.bonus_attacks_turn = turn
				attacker.tags["nitro_next"] = nt.uid
	# Red Dragon Archfiend: after attacking a Defense monster, burn all of them.
	if target_was_def and EffectRunner.fx(attacker).get("kill_def_all", false) and players[p].field.has(attacker):
		var defs := []
		for m in players[opp].monsters():
			if not m.attack_pos:
				defs.append(m)
		if not defs.is_empty():
			events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("%s scorches every Defense monster!") % attacker.cname()})
			for m in defs:
				events.append_array(_destroy(m))
	# D.D. Warrior (always) and D.D. Warrior Lady (if you want): after damage calculation, both monsters are banished.
	for pair in [[attacker, target, p], [target, attacker, opp]]:
		var dd: String = str(EffectRunner.fx(pair[0]).get("dd_after_battle", "")) if not pair[0].negated else ""
		if dd == "" or is_over():
			continue
		var both_here := true
		for x in pair.slice(0, 2):
			if not (players[0].field.has(x) or players[1].field.has(x) or players[x.owner].gy.has(x)):
				both_here = false
		if not both_here:
			continue
		var lost: bool = players[pair[0].owner].gy.has(pair[0])
		if dd == "may" and choose_option(pair[2], Loc.t("%s: banish it and %s?") % [pair[0].cname(), pair[1].cname()], ["Banish both", "No"], 0 if (lost or atk_of(pair[1], false) >= 1500) else 1, pair[0]) != 0:
			continue
		events.append({"type": "effect", "player": pair[2], "card": pair[0], "text": Loc.t("%s takes %s out of the duel with it") % [pair[0].cname(), pair[1].cname()]})
		events.append_array(_banish(pair[1]))
		events.append_array(_banish(pair[0]))
	# Blackwing Armor Master: a Wedge Counter on the monster it attacked.
	if EffectRunner.fx(attacker).get("wedge_on_attack", false) and players[p].field.has(attacker) and players[opp].field.has(target) and not target.wedge:
		target.wedge = true
		events.append({"type": "effect", "player": p, "card": attacker, "text": Loc.t("A Wedge Counter is placed on %s") % target.cname()})
	events.append_array(_after_attack(attacker, target))
	return events


## winner destroys loser by battle (if it can be destroyed), with the triggers that come with it.
func _battle_kill(winner_c: CardInst, loser: CardInst) -> Array:
	if SpellRules.equip_flag(self, loser, "no_battle_death"):
		return []
	if _shield == loser:
		_shield = null
		return [{"type": "effect", "player": loser.owner, "card": loser, "text": Loc.t("%s is not destroyed") % loser.cname()}]
	# Dark Ruler Ha Des: monsters destroyed in battle by your Fiends have their effects negated.
	var wp := 0 if players[0].field.has(winner_c) else 1
	if str(winner_c.data.get("race", "")) == "Fiend":
		for h in players[wp].monsters():
			if h.face_up and EffectRunner.fx(h).get("fiend_negate", false):
				loser.negated = true
				loser.negated_turn = turn
	# Element Saurus, while an EARTH monster is on the field: "Negate the effects of Effect Monsters
	# destroyed by battle with this card."
	if winner_c.face_up and not winner_c.negated and EffectRunner.fx(winner_c).get("element_saurus", false) and EffectRunner.attr_on_field(self, "EARTH"):
		loser.negated = true
		loser.negated_turn = turn
	# Blade Knight: "If you control no other monsters, the effects of Flip monsters destroyed by battle with this card are negated."
	if winner_c.face_up and not winner_c.negated and EffectRunner.fx(winner_c).get("blade_knight", false) and players[wp].monsters().size() == 1 and CardEffects.of(loser.cname()).has("flip"):
		loser.negated = true
		loser.negated_turn = turn
	var loser_lv := loser.level()
	battle_foe = winner_c
	var events := _battle_destroy(loser)
	battle_foe = null
	var died := not players[loser.owner].field.has(loser) and players[loser.owner].gy.has(loser)
	if not died:
		return events
	loser.died_turn = turn
	var lp_side := players[loser.owner]
	# Rescueroid: a "roid" of yours destroyed by battle comes back to your hand.
	if loser.cname().contains("roid"):
		for r in lp_side.monsters():
			if r.face_up and r != loser and EffectRunner.fx(r).get("rescue_roid", false):
				lp_side.gy.erase(loser)
				lp_side.hand.append(loser)
				events.append({"type": "effect", "player": loser.owner, "card": r, "text": Loc.t("%s returns %s to the hand") % [r.cname(), loser.cname()]})
				events.append({"type": "gy_to_hand", "player": loser.owner, "card": loser})
				break
	# Infernity Avenger: with no cards in hand, it rises from the Graveyard at the destroyed monster's Level.
	if lp_side.hand.is_empty() and wp != loser.owner and loser.cname() != "Infernity Avenger":
		for g in lp_side.gy.duplicate():
			if g != loser and lp_side.free_zone() != -1 and CardEffects.of(g.cname()).get("avenger", false):
				lp_side.gy.erase(g)
				events.append({"type": "effect", "player": loser.owner, "card": g, "text": Loc.t("%s rises at Level %d") % [g.cname(), loser_lv]})
				events.append_array(_special(loser.owner, g, "reborn", "def"))
				g.lv_set = loser_lv
				g.lv_turn = -1
				break
	winner_c.killed_turn = turn
	events.append_array(SpellRules.after_battle_death(self, loser))
	# Junk Barrage: half the destroyed monster's ATK as damage.
	if SpellRules.equip_flag(self, winner_c, "burn_half_on_kill") and not is_over():
		events.append({"type": "effect", "player": wp, "card": winner_c, "text": Loc.t("Junk Barrage: %d damage") % (loser.atk() / 2)})
		events.append_array(_damage(opponent(wp), loser.atk() / 2))
	# Armory Arm, equipped: "If that target destroys a monster by battle and sends it to the GY:
	# Inflict damage to your opponent equal to the ATK of the destroyed monster in the GY."
	for arm in unions_on(winner_c):
		if not is_over() and not arm.negated and EffectRunner.fx(arm).get("union", {}).get("burn_on_kill", false):
			events.append({"type": "effect", "player": arm.owner, "card": arm, "text": Loc.t("%s: %d damage") % [arm.cname(), loser.atk()]})
			events.append_array(_damage(opponent(arm.owner), loser.atk()))
	if players[winner_c.owner].field.has(winner_c):
		events.append_array(EffectRunner.trigger(self, winner_c, "kill", {"victim": loser}))
	events.append_array(EffectRunner.trigger(self, loser, "death", {"killer": winner_c}))
	return events


func _after_attack(attacker: CardInst, target = null) -> Array:
	var events := []
	# Rocket Warrior: "If this card attacks a monster, after damage calculation: That attack target loses 500 ATK until the end of this turn."
	if target != null and target is CardInst and players[attacker.owner].field.has(attacker) and attacker.face_up and not attacker.negated and EffectRunner.fx(attacker).get("rocket", false):
		var rt: CardInst = target
		if players[0].field.has(rt) or players[1].field.has(rt):
			if rt.atk_mod_turn != turn:
				rt.atk_mod_turn = turn
				rt.atk_mod_t = 0
			rt.atk_mod_t -= 500
			events.append({"type": "effect", "player": attacker.owner, "card": attacker, "text": Loc.t("%s loses 500 ATK until the end of this turn") % rt.cname()})
	# Road Synchron: "If this card attacks, at the end of the Damage Step: Increase its Level by 1 until the end of this turn."
	if players[attacker.owner].field.has(attacker) and attacker.face_up and EffectRunner.fx(attacker).get("level_up_after_attack", false):
		attacker.lv_set = attacker.level() + 1
		attacker.lv_turn = turn
		events.append({"type": "effect", "player": attacker.owner, "card": attacker, "text": Loc.t("%s is Level %d until the end of this turn") % [attacker.cname(), attacker.lv_set]})
	if players[attacker.owner].field.has(attacker) and attacker.attack_pos and EffectRunner.fx(attacker).get("def_after_attack", false):
		attacker.attack_pos = false
		events.append({"type": "position", "player": attacker.owner, "card": attacker, "zone": players[attacker.owner].field.find(attacker)})
	# "At the end of the Damage Step, if this card battled: You can change this card to Defense
	# Position" (Submarineroid): whether it attacked or was attacked.
	if target != null and target is CardInst and not is_over():
		var tc: CardInst = target
		var tf := EffectRunner.fx(tc)
		# Marshmallon: "After damage calculation, if this card was attacked, and was face-down at the
		# start of the Damage Step: The attacking player takes 1000 damage."
		if int(tf.get("burn_attacker_if_flipped", 0)) > 0 and tc.tags.get("was_down", false):
			events.append({"type": "effect", "player": tc.owner, "card": tc, "text": Loc.t("%s: %d damage to the attacking player") % [tc.cname(), int(tf["burn_attacker_if_flipped"])]})
			events.append_array(_damage(attacker.owner, int(tf["burn_attacker_if_flipped"])))
		# Big Shield Gardna: "If this card is attacked, change it to Attack Position at the end of the Damage Step."
		if tf.get("atk_pos_after_attacked", false) and players[tc.owner].field.has(tc) and not tc.attack_pos:
			tc.attack_pos = true
			events.append({"type": "position", "player": tc.owner, "card": tc, "zone": players[tc.owner].field.find(tc)})
		tc.tags.erase("was_down")
	for m in [attacker, target]:
		if m == null or not (m is CardInst):
			continue
		var c: CardInst = m
		if players[c.owner].field.has(c) and c.face_up and c.attack_pos and EffectRunner.fx(c).get("may_def_after_battle", false):
			var auto := 0 if def_of(c) > atk_of(c, false) else 1
			if choose_option(c.owner, Loc.t("%s: change it to Defense Position?") % c.cname(), [Loc.t("Change to Defense Position"), Loc.t("Leave it in Attack Position")], auto, c) == 0:
				c.attack_pos = false
				events.append({"type": "position", "player": c.owner, "card": c, "zone": players[c.owner].field.find(c)})
	return events


## ATK including effects. `attacking` = it's the attacker in this battle; vs = the other monster.
func atk_of(c: CardInst, attacking: bool, vs: CardInst = null, battling := false) -> int:
	var v := c.atk()
	var total := maxi(0, v + EffectRunner.atk_bonus(self, c, attacking, vs, battling) + SpellRules.atk_bonus(self, c, attacking and battling, vs))
	# Mirror Wall: a monster that attacked into it stays at half its ATK for as long as the wall stands.
	if c.has_meta("mirror_wall"):
		var wall = c.get_meta("mirror_wall")
		if wall != null and wall.face_up and players[opponent(c.owner)].spells.has(wall) and (players[0].field.has(c) or players[1].field.has(c)):
			total = int(ceil(total / 2.0))
		else:
			c.remove_meta("mirror_wall")
	return total


func def_of(c: CardInst) -> int:
	return maxi(0, c.def() + c.def_mod + (c.def_mod_t if c.def_mod_turn == turn else 0) + SpellRules.def_bonus(self, c) + EffectRunner.def_bonus(self, c))


func _battle_destroy(c: CardInst) -> Array:
	var ps := players[c.owner]
	if ps.protect_turn == turn:
		return []
	if EffectRunner.survives_battle(self, c):
		return [{"type": "effect", "player": c.owner, "card": c, "text": Loc.t("%s isn't destroyed!") % c.cname()}]
	for eq in SpellRules.equips_on(self, c):
		var esp := SpellRules.spec(eq)
		# Silver Wing: "Twice per turn, it cannot be destroyed by battle."
		if esp.has("battle_guard"):
			var used_g := int(eq.tags.get("guard_n", 0)) if int(eq.tags.get("guard_turn", -1)) == turn else 0
			if used_g < int(esp["battle_guard"]):
				eq.tags["guard_turn"] = turn
				eq.tags["guard_n"] = used_g + 1
				return [{"type": "effect", "player": eq.owner, "card": eq, "text": Loc.t("%s: %s isn't destroyed!") % [eq.cname(), c.cname()]}]
		# Fighting Spirit: "If it would be destroyed by battle, you can destroy this card instead."
		if esp.get("battle_sub", false) and choose_option(eq.owner, Loc.t("%s would be destroyed by battle. Destroy %s instead?") % [c.cname(), eq.cname()], ["Destroy the Equip Card instead", "No"], 0, eq) == 0:
			var kept := [{"type": "effect", "player": eq.owner, "card": eq, "text": Loc.t("%s is destroyed in place of %s") % [eq.cname(), c.cname()]}]
			kept.append_array(_destroy_st(eq))
			return kept
	if c.cname() == "Gogogo Golem" and not c.attack_pos and c.used_turn != turn:
		c.used_turn = turn
		return [{"type": "effect", "player": c.owner, "card": c, "text": "Gogogo Golem holds on!"}]
	return _destroy(c, true)


func _battle_damage(p: int, amount: int, dealer: CardInst = null, taker: CardInst = null) -> Array:
	var ps := players[p]
	if battle_shield == p:
		return [{"type": "effect", "player": p, "card": null, "text": "No battle damage!"}]
	# Rocket Warrior: "During your Battle Phase... you take no damage from battles involving this card."
	for rm0 in [dealer, taker]:
		if rm0 != null and rm0.owner == p and current == p and rm0.face_up and not rm0.negated and EffectRunner.fx(rm0).get("rocket", false):
			return [{"type": "effect", "player": p, "card": rm0, "text": "No battle damage!"}]
	# Half Unbreak: "any battle damage you take from attacks involving that monster is halved."
	for hm in [dealer, taker]:
		if hm != null and int(hm.tags.get("unbreak_turn", -1)) == turn and int(hm.tags.get("unbreak_for", -1)) == p:
			amount = int(ceil(amount / 2.0))
			break
	if bye_bye == p and amount > 0 and ps.no_damage_turn != turn and ps.protect_turn != turn:
		# Bye Bye Damage: "if you take battle damage from that battle, your opponent takes effect damage equal to double that amount."
		var out_b := _damage(p, amount, true)
		out_b.append({"type": "effect", "player": p, "card": null, "text": Loc.t("Bye Bye Damage: %d damage to the opponent") % (amount * 2)})
		out_b.append_array(_damage(opponent(p), amount * 2))
		return out_b
	if EffectRunner.no_damage_involving(taker) and taker.owner == p:
		return [{"type": "effect", "player": p, "card": taker, "text": "No battle damage!"}]
	# Amazoness Swords Woman: "Your opponent takes any battle damage you would have taken from
	# battles involving this card instead."
	if taker != null and taker.owner == p and taker.face_up and not taker.negated and EffectRunner.fx(taker).get("reflect_damage", false):
		var back := [{"type": "effect", "player": p, "card": taker, "text": Loc.t("%s turns the battle damage on the opponent") % taker.cname()}]
		var other := opponent(p)
		if players[other].no_damage_turn == turn or players[other].protect_turn == turn:
			back.append({"type": "effect", "player": other, "card": null, "text": "No battle damage!"})
			return back
		back.append_array(_damage(other, amount, true))
		return back
	if ps.no_damage_turn == turn or ps.protect_turn == turn:
		return [{"type": "effect", "player": p, "card": null, "text": "No battle damage!"}]
	return _damage(p, amount, true)


func _destroy(c: CardInst, by_battle := false) -> Array:
	var ps := players[c.owner]
	var zone := ps.field.find(c)
	if zone == -1:
		return []
	# "Cannot be destroyed by card effects" (Infernity Guardian with an empty hand).
	if not by_battle and EffectRunner.survives_effect(self, c):
		return [{"type": "effect", "player": c.owner, "card": c, "text": Loc.t("%s is not destroyed") % c.cname()}]
	# Machine Angel Ritual in your Graveyard: "If a LIGHT monster(s) you control would be destroyed by
	# battle or card effect, you can banish this card instead."
	if str(c.data.get("attribute", "")) == "LIGHT":
		for g in ps.gy.duplicate():
			if g.cname() == "Machine Angel Ritual" and choose_option(c.owner, Loc.t("%s would be destroyed. Banish Machine Angel Ritual from your Graveyard instead?") % c.cname(), ["Banish it", "No"], 0, g) == 0:
				ps.gy.erase(g)
				ps.banished.append(g)
				return [{"type": "effect", "player": c.owner, "card": g, "text": Loc.t("Machine Angel Ritual is banished: %s is not destroyed") % c.cname()}]
	var by_opp_any := not by_battle and effect_by != -1 and effect_by != c.owner
	var by_opp_fx := by_opp_any and c.face_up
	# "If the equipped monster would be destroyed by battle or card effect, destroy this card instead."
	var riders := unions_on(c).filter(func(u): return not EffectRunner.fx(u).get("union", {}).get("no_shield", false))
	if not by_battle:
		# Silver Wing: "If it would be destroyed by a card effect, you can destroy this card instead."
		for eq in SpellRules.equips_on(self, c):
			if SpellRules.spec(eq).get("fx_sub", false) and choose_option(eq.owner, Loc.t("%s would be destroyed. Destroy %s instead?") % [c.cname(), eq.cname()], ["Destroy the Equip Card instead", "No"], 0, eq) == 0:
				var kept := [{"type": "effect", "player": eq.owner, "card": eq, "text": Loc.t("%s is destroyed in place of %s") % [eq.cname(), c.cname()]}]
				kept.append_array(_destroy_st(eq))
				return kept
	if not riders.is_empty():
		var u: CardInst = riders[0]
		var saved := [{"type": "effect", "player": u.owner, "card": u, "text": Loc.t("%s is destroyed in place of %s") % [u.cname(), c.cname()]}]
		saved.append_array(_destroy_st(u))
		return saved
	ps.field[zone] = null
	var mats: Array = c.overlays.duplicate()
	_to_gy(ps, c)   # its Xyz Materials go with it
	var events := [{"type": "destroy", "player": c.owner, "card": c, "zone": zone, "overlays": mats}]
	events.append_array(_on_leave_field(c, by_battle))
	events.append_array(_monster_left(c))
	# "When this card on the field is destroyed and sent to the Graveyard" (by battle or by an effect).
	if players[c.owner].gy.has(c):
		events.append_array(EffectRunner.trigger(self, c, "destroyed"))
		# "Destroyed by a card effect and sent to the Graveyard" (Babycerasaurus).
		if not by_battle:
			events.append_array(EffectRunner.trigger(self, c, "fx_destroyed"))
		# "...was destroyed by an opponent's card effect and sent to your GY" (Gernia).
		if by_opp_fx:
			events.append_array(EffectRunner.trigger(self, c, "opp_fx_destroyed"))
		# The same, face-up or not (Vampire Lord).
		if by_opp_any:
			events.append_array(EffectRunner.trigger(self, c, "opp_fx_destroyed_any"))
		# "Destroyed by an opponent's card (by battle or card effect) and sent to your Graveyard"
		# (Starliege Paladynamo). In a battle the other monster is always the opponent's.
		if by_battle or by_opp_any:
			events.append_array(EffectRunner.trigger(self, c, "opp_destroyed"))
	# Revival Rose: when a Level 5 or higher Plant of yours is destroyed, it comes back from the Graveyard.
	if str(c.data.get("race", "")) == "Plant" and int(c.data.get("level", 0)) >= 5:
		for g in ps.gy.duplicate():
			if g != c and ps.free_zone() != -1 and CardEffects.of(g.cname()).get("revive_on_plant5", false):
				ps.gy.erase(g)
				events.append({"type": "effect", "player": c.owner, "card": g, "text": Loc.t("%s blooms again") % g.cname()})
				events.append_array(_special(c.owner, g, "reborn"))
				break
	return events


## Every card headed for the Graveyard goes through here, so "banish instead" effects work.
func _to_gy(ps: PlayerState, c: CardInst) -> void:
	if c.is_token():
		return   # Tokens are not cards: they simply stop existing.
	c.gy_turn = turn
	if not c.overlays.is_empty():
		# An Xyz Monster's materials go to the Graveyard when it leaves the field.
		var mats: Array = c.overlays.duplicate()
		c.overlays.clear()
		for o in mats:
			players[o.owner].gy.append(o)
			_sent_to_gy(o)
	if c.orig_owner != -1:
		# A borrowed monster goes to its real owner's Graveyard.
		c.owner = c.orig_owner
		c.orig_owner = -1
		c.control_until = -1
		ps = players[c.owner]
	if c.leave_banish:
		# Brought back on the condition that it is banished when it leaves the field.
		c.leave_banish = false
		ps.banished.append(c)
		redirected.append(c)
	elif _gy_redirect(c):
		ps.banished.append(c)
		redirected.append(c)
	else:
		ps.gy.append(c)
		_sent_to_gy(c)
		# Axe of Despair and friends: sent from the field to the Graveyard, they go back on top of the Deck.
		var back := str(SpellRules.FX.get(c.cname(), {}).get("deck_top", "")) if not c.is_monster() else ""
		if back != "" and (c.left_turn == turn or back == "always"):
			var who := c.owner
			var okay := true
			if back == "tribute":
				okay = not tributable(who).is_empty() and choose_option(who, Loc.t("%s: Tribute 1 monster to put it on top of your Deck?") % c.cname(), ["Tribute a monster", "Leave it in the Graveyard"], 1, c) == 0
				if okay:
					var weak: CardInst = null
					for m in tributable(who):
						if weak == null or atk_of(m, false) < atk_of(weak, false):
							weak = m
					weak = pick1(who, Loc.t("%s: Tribute 1 monster") % c.cname(), tributable(who), weak, c)
					players[who].field[players[who].field.find(weak)] = null
					_to_gy(players[who], weak)
					pending_events.append({"type": "tribute", "player": who, "card": weak})
					pending_events.append_array(EffectRunner.trigger(self, weak, "tributed"))
					pending_events.append_array(_monster_left(weak))
			elif back == "lp500":
				okay = players[who].lp > 500 and choose_option(who, Loc.t("%s: pay 500 LP to put it on top of your Deck?") % c.cname(), ["Pay 500 LP", "Leave it in the Graveyard"], 0, c) == 0
				if okay:
					players[who].lp -= 500
					pending_events.append({"type": "lp", "player": who, "lp": players[who].lp, "delta": -500})
			if okay and ps.gy.has(c):
				ps.gy.erase(c)
				ps.deck.append(c)
				pending_events.append({"type": "effect", "player": who, "card": c, "text": Loc.t("%s returns to the top of the Deck") % c.cname()})
				pending_events.append({"type": "gy_to_deck", "player": who, "card": c, "deck": ps.deck.size()})


## "When this card is sent to the Graveyard" from anywhere: the field, the hand, the Deck, as
## an Xyz Material (Skull-Mark Ladybug). What it does is picked up by _cleanup.
func _sent_to_gy(c: CardInst) -> void:
	if not c.is_monster():
		# "If this card is sent to the Graveyard" on a Spell or Trap (Limiter Overload).
		var st_sent: Array = SpellRules.FX.get(c.cname(), {}).get("sent_gy", [])
		if not st_sent.is_empty() and not is_over():
			var was_by := effect_by
			effect_by = c.owner
			for a in st_sent:
				pending_events.append_array(SpellRules._run(self, c.owner, c, a, {}))
			effect_by = was_by
		return
	var sent: Array = CardEffects.of(c.cname()).get("sent_gy", [])
	if not sent.is_empty() and not is_over():
		pending_events.append_array(EffectRunner.run_list(self, c.owner, c, sent, {}))


## Cards banished instead of going to the GY since the last time the scene looked (for the board).
var redirected: Array = []
## Things that happened inside _to_gy (it returns nothing): picked up by _cleanup.
var pending_events: Array = []


func _gy_redirect(c: CardInst = null) -> bool:
	if SpellRules.redirect(self, c):
		return true
	if c != null and c.is_monster() and EffectRunner.fx(c).get("banish_when_leaves", false) and c.summoned_turn != -1:
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
	var was_up_mon := false
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
			was_up_mon = c.face_up
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
				if was_up_mon:
					# "When this face-up card leaves the field" (Shooting Quasar Dragon).
					bev.append_array(EffectRunner.trigger(self, c, "leave"))
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
	var was_up := c.face_up
	_to_gy(ps, c)
	var events := [{"type": "destroy_st", "player": c.owner, "card": c, "zone": zone}]
	events.append_array(SpellRules.left_field(self, c))
	if was_up and c.cname() == "Toon World":
		# "If "Toon World" on the field is destroyed, destroy this card": every Toon that says so.
		for q in 2:
			for m in players[q].monsters():
				if m.face_up and EffectRunner.fx(m).has("toon") and not m.negated:
					events.append({"type": "effect", "player": q, "card": m, "text": Loc.t("Toon World is gone: %s is destroyed") % m.cname()})
					events.append_array(_destroy(m))
	return events


## Equip cards (and Call of the Haunted) go when their monster goes.
func _monster_left(m: CardInst) -> Array:
	var events := []
	for q in 2:
		for st in players[q].spells.duplicate():
			if st == null or not st.face_up:
				continue
			if st.equipped_to == m or st.linked == m:
				var gone_fx: Array = SpellRules.host_gone(self, st) if st.equipped_to == m else []
				st.linked = null
				st.equipped_to = null
				events.append_array(_destroy_st(st))
				events.append_array(gone_fx)
	return events


## Sweep up Equip cards whose monster is gone (tributed, used as material...).
func _cleanup() -> Array:
	var events := []
	if not pending_events.is_empty():
		events.append_array(pending_events)
		pending_events = []
	# Level Limit - Area B: face-up monsters of that Level or higher are held in Defense Position.
	for q0 in 2:
		for st0 in players[q0].spells:
			if st0 != null and st0.face_up and SpellRules.spec(st0).has("force_def_lv_min"):
				for q1 in 2:
					for m0 in players[q1].monsters():
						if m0.face_up and m0.attack_pos and m0.frame() != "xyz" and m0.level() >= int(SpellRules.spec(st0)["force_def_lv_min"]):
							m0.attack_pos = false
							events.append({"type": "position", "player": q1, "card": m0, "zone": players[q1].field.find(m0)})
	# "While you control a Dragon monster, this card's Level becomes 7" (Harpie Channeler).
	for qa in 2:
		for ma in players[qa].monsters():
			var la: Array = EffectRunner.fx(ma).get("lv_with_race", [])
			if la.is_empty():
				continue
			var on := false
			if ma.face_up and not ma.negated:
				for other in players[qa].monsters():
					if other.face_up and str(other.data.get("race", "")) == str(la[0]):
						on = true
			if on and (ma.lv_set == 0 or ma.lv_aura):
				ma.lv_set = int(la[1])
				ma.lv_turn = -1
				ma.lv_aura = true
			elif not on and ma.lv_aura:
				ma.lv_set = 0
				ma.lv_aura = false
	# Effect negation (Skill Drain and one-turn negations) is re-derived from what is on the field.
	var drain := SpellRules.field_flag(self, "drain")
	for q in 2:
		for m in players[q].monsters():
			m.negated = m.face_up and (drain or m.negated_turn == turn or m.neg_perm)
	# Lord of D.: Dragons cannot be targeted while he is face-up (EffectRunner.can_target reads the mark).
	var lord_up := dragon_shield()
	for q in 2:
		for m in players[q].monsters():
			if lord_up and m.face_up and str(m.data.get("race", "")) == "Dragon":
				m.tags["no_target"] = true
			else:
				m.tags.erase("no_target")
	# Elemental HERO Dark Neos: "while you control this face-up card, that target's effect on the field is negated."
	for q in 2:
		for m in players[q].monsters():
			if not m.tags.has("neg_by"):
				continue
			var src := find_uid(int(m.tags["neg_by"]))
			if src != null and src.face_up and not src.negated and (players[0].field.has(src) or players[1].field.has(src)) and m.face_up:
				m.negated = true
			else:
				m.tags.erase("neg_by")
	for q in 2:
		for st in players[q].spells.duplicate():
			if st == null or not st.face_up:
				continue
			var m = st.equipped_to if st.equipped_to != null else st.linked
			if m == null:
				continue
			if not (players[0].field.has(m) or players[1].field.has(m)) or not m.face_up:
				var gone_fx2: Array = SpellRules.host_gone(self, st) if st.equipped_to == m and not (players[0].field.has(m) or players[1].field.has(m)) else []
				st.linked = null
				st.equipped_to = null
				events.append_array(_destroy_st(st))
				events.append_array(gone_fx2)
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
	if c != null and c.leave_banish and (players[0].field.has(c) or players[1].field.has(c)):
		return _banish(c)
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
		if from == "field" and c.is_monster():
			events.append_array(EffectRunner.trigger(self, c, "leave"))
		return events
	return []


## Shuffle a card on the field into its owner's Deck (Extra Deck monsters go back to the Extra Deck).
func _to_deck(c: CardInst) -> Array:
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
			home.deck.append(c)
			_shuffle(home.deck)
		var events := [{"type": "bounce", "player": c.owner, "card": c, "from": from, "zone": zone, "side": q, "extra": true, "deck": not to_extra}]
		if from == "field" or c.is_monster():
			events.append_array(_monster_left(c))
		else:
			events.append_array(SpellRules.left_field(self, c))
		if from == "field" and c.is_monster():
			events.append_array(EffectRunner.trigger(self, c, "leave"))
		return events
	return []


## A Neos Contact Fusion stays on the field through the End Phase while Neo Space is face-up
## or Instant Neo Space is equipped to it.
func neos_stays(m: CardInst) -> bool:
	for q in 2:
		var f := players[q].field_spell
		if f != null and f.face_up and SpellRules.spec(f).get("neo_space", false) and not SpellRules.blocked(self, f):
			return true
	return SpellRules.equip_flag(self, m, "neos_keep")


## Move a monster to player p's side. `until`: the turn it goes back at the End Phase, or -1 to keep it.
func _take_control(c: CardInst, p: int, until: int) -> Array:
	var from_p := c.owner
	if from_p == p or not players[from_p].field.has(c):
		return []
	if c.face_up and EffectRunner.fx(c).get("no_control", false):
		return [{"type": "effect", "player": from_p, "card": c, "text": Loc.t("Control of %s cannot switch") % c.cname()}]
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
	# (Sangan, Winged Kuriboh and Mystic Tomato run from their entries in CardEffects like every other card.)
	events.append_array(EffectRunner.trigger(self, c, "gy"))
	events.append_array(EffectRunner.trigger(self, c, "leave"))
	return events


# ------------------------------------------------------------------ Turbo Duels

func _speed(p: int, delta: int) -> Array:
	var ps := players[p]
	var to := clampi(ps.speed + delta, 0, SPEED_MAX)
	if to == ps.speed:
		return []
	var d := to - ps.speed
	ps.speed = to
	return [{"type": "speed", "player": p, "speed": to, "delta": d}]


## Speed Counters a Spell needs before it can be played in a Turbo Duel (0 outside one).
func speed_need(c: CardInst) -> int:
	if not turbo or c.is_monster() or c.is_trap():
		return 0
	var sp0 := SpellRules.spec(c)
	if sp0.has("speed"):
		return int(sp0["speed"])
	var k := SpellRules.kind(c)
	var n := 2 if k in ["quick", "equip"] else 3
	if c.cname() in SPEED_HEAVY:
		n += 2
	return n


## The three effects of Speed World 2: spend 4, 7 or 10 Speed Counters, once per turn.
func can_speed_world(p: int, cost: int) -> bool:
	if not turbo or p != current or not _in_main() or is_over():
		return false
	var ps := players[p]
	if ps.speed < cost or ps.speed_turn == turn:
		return false
	match cost:
		4:
			return ps.hand.any(func(c): return not c.is_monster() and not c.is_trap())
		7:
			return not ps.deck.is_empty()
		10:
			return not _field_cards(opponent(p)).is_empty()
	return false


func _field_cards(q: int) -> Array:
	var out: Array = players[q].monsters()
	for c in players[q].spells:
		if c != null:
			out.append(c)
	return out


func speed_world(p: int, cost: int) -> Array:
	if not can_speed_world(p, cost):
		return []
	var ps := players[p]
	ps.speed_turn = turn
	var events := _speed(p, -cost)
	match cost:
		4:
			var n: int = ps.hand.filter(func(c): return not c.is_monster() and not c.is_trap()).size()
			events.append({"type": "effect", "player": p, "card": null, "text": Loc.t("Speed World 2: %d damage for the Speed Spells in hand!") % (800 * n)})
			events.append_array(_damage(opponent(p), 800 * n))
		7:
			events.append({"type": "effect", "player": p, "card": null, "text": "Speed World 2: draw 1 card"})
			events.append_array(_draw(p))
		10:
			var cands := _field_cards(opponent(p))
			var best = cands[0]
			for c in cands:
				if c.is_monster() and (not best.is_monster() or c.atk() > best.atk()):
					best = c
			var t = pick1(p, "Speed World 2: destroy 1 card", cands, best, null)
			events.append({"type": "effect", "player": p, "card": null, "text": "Speed World 2: destroy 1 card"})
			if t.is_monster():
				events.append_array(_destroy(t))
			else:
				events.append_array(_destroy_st(t))
	return events


func _damage(p: int, amount: int, battle := false) -> Array:
	if amount <= 0:
		return []
	var ps := players[p]
	if ps.no_damage_until >= turn:
		return [{"type": "effect", "player": p, "card": null, "text": "No damage!"}]
	if not battle and ps.no_effect_damage_turn == turn:
		return [{"type": "effect", "player": p, "card": null, "text": "No effect damage this turn!"}]
	ps.lp = maxi(0, ps.lp - amount)
	var events := [{"type": "lp", "player": p, "lp": ps.lp, "delta": -amount}]
	if turbo and amount >= 1000:
		events.append_array(_speed(p, -(amount / 1000)))
	if ps.lp == 0:
		if winner == p and players[opponent(p)].lp == 0:
			# Both duelists reached zero in the same resolution: nobody wins.
			winner = DRAW
			win_reason = "Both duelists' Life Points hit zero. The duel is a draw."
		else:
			_set_winner(opponent(p), Loc.t("%s's Life Points hit zero.") % ps.name)
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
		c.attack_pos = choose_option(p, Loc.t("Special Summon %s in:") % c.cname(), ["Attack Position", "Defense Position"], 0, c) == 0
	c.summoned_turn = turn
	c.pos_changed_turn = -1
	c.attacked_turn = -1
	c.reset_mods()
	c.tags["ss"] = true   # "a Special Summoned monster" (Gagaga Girl)
	last_summoned = c
	var events := [{"type": "special", "player": p, "card": c, "zone": zone, "method": method}]
	if not c.attack_pos:
		events.append({"type": "position", "player": p, "card": c, "zone": zone})
	ps.summons_turn = turn
	if CardEffects.of(c.cname()).get("gy_end_if_special", false):
		c.tags["gy_end"] = true   # Slifer: "Once per turn, during the End Phase, if this card was Special Summoned: Send it to the GY."
	if method != "return":
		events.append_array(_summon_tax(p, c))
		if not ps.field.has(c):
			return events
	if method == "reborn":
		# "If this card is Special Summoned from the GY" (Destiny HERO - Disk Commander).
		events.append_array(EffectRunner.trigger(self, c, "revived"))
		# Doppelwarrior: "When a monster(s) is Special Summoned from your GY (except during the Damage
		# Step): You can Special Summon this card from your hand."
		if not in_damage_step and ps.no_summon_turn != turn:
			for h in ps.hand.duplicate():
				if ps.free_zone() != -1 and CardEffects.of(h.cname()).get("hand_on_gy_special", false):
					if choose_option(p, Loc.t("%s: Special Summon it from your hand?") % h.cname(), ["Special Summon it", "Keep it in hand"], 0, h) == 0:
						ps.hand.erase(h)
						events.append({"type": "effect", "player": p, "card": h, "text": Loc.t("%s follows %s onto the field") % [h.cname(), c.cname()]})
						events.append_array(_special(p, h, "effect"))
						last_summoned = c
					break
	return events


## Ritual and Extra Deck monsters can only come back if they were first summoned the proper way.
func can_revive(c: CardInst) -> bool:
	if CardEffects.of(c.cname()).get("no_revive", false) or CardEffects.of(c.cname()).get("no_special", false):
		return false   # "Cannot be Special Summoned (from the GY)": Dark Ruler Ha Des, Blackwing - Blizzard
	if CardEffects.of(c.cname()).get("no_revive_same_turn", false) and c.gy_turn == turn:
		return false   # Destiny HERO - Disk Commander: not the turn it was sent to the Graveyard
	if not c.proper:
		# "Must first be Special Summoned (from your hand) by ...": no coming back before that.
		var words := str(c.data.get("desc", "")).to_lower()
		if words.contains("must first be special summoned"):
			return false
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
		if CardEffects.of(f.cname()).has("contact"):
			continue   # "(You do not use "Polymerization".)"
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
			if int(mid) == 0:
				continue      # "+ 1 monster": taken last, from whatever is left (below)
			for h in pool_hand:
				if h.id == mid:
					found = h
					break
			if ask and found:
				var on_field: Array = pool_field.filter(func(m): return m.id == mid)
				if not on_field.is_empty():
					var got := pick1(p, Loc.t("Fusion material: use which %s?") % found.cname(), [found, on_field[0]], found, f)
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
		# "+ 1 monster": any monster left in the hand or on the field (not a token). The game
		# takes the weakest; when it is your call you say which.
		for mid in mats:
			if int(mid) != 0 or not ok:
				continue
			var any: Array = pool_hand.filter(func(h): return h.is_monster()) + pool_field.filter(func(m): return not m.is_token())
			if any.is_empty():
				ok = false
				break
			var pick = any[0]
			for x in any:
				if x.atk() < pick.atk():
					pick = x
			if ask:
				pick = pick1(p, Loc.t("%s: which monster is the other material?") % f.cname(), any, pick, f)
			if pool_hand.has(pick):
				pool_hand.erase(pick)
				used_hand.append(pick)
			else:
				pool_field.erase(pick)
				used_field.append(pick)
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
			events.append_array(_monster_left(m))
	var f: CardInst = plan["card"]
	ps.extra.erase(f)
	f.proper = true
	events.append_array(_special(p, f, "fusion"))
	events.append_array(EffectRunner.on_summon(self, p, f, "fusion"))
	return events


## Material sets for a Synchro or Xyz monster, best (cheapest) first.
static var _mat_rules := {}

## What a Synchro or Xyz Monster's first line of text asks of its materials:
## {"tuner": filter, "others": filter, "one_other": bool} or {"count": n, "filter": filter}.
static func material_rule(c: CardInst) -> Dictionary:
	var key := c.cname()
	if _mat_rules.has(key):
		return _mat_rules[key]
	# The card file's own text (the built-in short texts leave the material line out).
	var raw := str((CardData.EXT.get(c.id, {}) as Dictionary).get("desc", c.data.get("desc", c.data.get("text", ""))))
	var line := raw.split("\n")[0].strip_edges()
	var rule := {}
	var re := RegEx.new()
	if c.frame() == "synchro" and line.contains(" + "):
		var parts := line.split(" + ")
		var tun := parts[0].strip_edges()
		var rest := parts[1].strip_edges()
		var tf := {}
		re.compile("^\"([^\"]+)\"$")
		var m := re.search(tun)
		if m:
			tf = {"name": m.get_string(1)}
		else:
			re.compile("^1 \"([^\"]+)\" Tuner")
			m = re.search(tun)
			if m:
				tf = {"has": m.get_string(1)}
			else:
				re.compile("^1 (DARK|LIGHT|EARTH|WATER|FIRE|WIND) Tuner")
				m = re.search(tun)
				if m:
					tf = {"attr": m.get_string(1)}
		var of := {}
		re.compile("non-Tuner ([A-Z][A-Za-z\\- ]+?)(?:-Type)? monsters?")
		m = re.search(rest)
		if m:
			var w := m.get_string(1).strip_edges()
			of = {"attr": w} if w in ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND"] else {"race": w}
		if tun.to_lower().contains("tuner synchro monster"):
			tf = {"frame": "synchro"}   # "1 Tuner Synchro Monster + ..." (Shooting Star Dragon, Shooting Quasar Dragon)
		var one := rest.begins_with("1 non-Tuner")
		re.compile("^\"([^\"]+)\"$")
		m = re.search(rest)
		if m:
			of = {"name": m.get_string(1)}   # '... + "Stardust Dragon"'
			one = true
		elif rest.to_lower().contains("non-tuner synchro monster"):
			of = {"frame": "synchro"}
		rule = {"tuner": tf, "others": of, "one_other": one, "min_others": 2 if (rest.begins_with("2+") or rest.begins_with("2 or more")) else 1}
	elif c.frame() == "xyz":
		re.compile("^(\\d) Level \\d+ ?([A-Za-z\\- ]*?)(?:-Type)? monsters")
		var m2 := re.search(line)
		if m2:
			var w2 := m2.get_string(2).strip_edges()
			var f := {}
			if w2 != "":
				f = {"attr": w2} if w2 in ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND"] else {"race": w2}
			rule = {"count": int(m2.get_string(1)), "filter": f}
	_mat_rules[key] = rule
	return rule


static func _fits(m: CardInst, f: Dictionary) -> bool:
	if f.has("name") and m.cname() != f["name"] and str(CardEffects.of(m.cname()).get("name_as", "")) != f["name"] and str(CardEffects.of(m.cname()).get("name_as_fg", "")) != f["name"]:
		# Quickdraw Synchron: "For a Synchro Summon, you can substitute this card for any 1 "Synchron" Tuner."
		if not (str(f["name"]).contains("Synchron") and m.is_tuner() and EffectRunner.fx(m).get("sub_synchron", false)):
			return false
	if f.has("frame") and m.frame() != f["frame"]:
		return false
	if f.has("has") and not m.cname().contains(str(f["has"])):
		return false
	if f.has("attr") and str(m.data.get("attribute", "")) != f["attr"]:
		return false
	if f.has("race") and str(m.data.get("race", "")) != f["race"]:
		return false
	return true


func extra_materials(p: int, c: CardInst) -> Array:
	var mons: Array = []
	for m in players[p].monsters():
		if m.face_up:
			mons.append(m)
	var out := []
	var rule := material_rule(c)
	if c.frame() == "xyz":
		var xf: Dictionary = rule.get("filter", {})
		# (Lumen, Echo Zenith: "1 Lumen, Echo Spirit you control can be used as a Level 4 material".)
		var also := str(EffectRunner.fx(c).get("xyz_also", ""))
		var same := mons.filter(func(m): return m.frame() not in ["xyz", "token"] and ((m.level() == c.level() and _fits(m, xf)) or (also != "" and m.cname() == also)))
		if also != "":
			# Only one of them may stand in.
			var first_also = null
			for m in same.duplicate():
				if m.cname() == also and m.level() != c.level():
					if first_also == null:
						first_also = m
					else:
						same.erase(m)
		same.sort_custom(func(a, b): return a.atk() < b.atk())
		# "3 Level 4 monsters" asks for three; most ask for two. "2 Level 3 WATER monsters" asks for WATER.
		var want := clampi(int(rule.get("count", 2)), 2, 5)
		if want == 2:
			for i in same.size():
				for j in range(i + 1, same.size()):
					out.append([same[i], same[j]])
		else:
			for mask in range(1, 1 << same.size()):
				var pick := []
				for i in same.size():
					if mask & (1 << i):
						pick.append(same[i])
				if pick.size() == want:
					out.append(pick)
	elif c.frame() == "synchro":
		mons = mons.filter(func(m): return m.frame() != "xyz" and not EffectRunner.fx(m).get("no_synchro", false))   # Xyz Monsters have a Rank, not a Level
		var n := mons.size()
		for mask in range(1, 1 << n):
			var sel := []
			for i in n:
				if mask & (1 << i):
					sel.append(mons[i])
			var tuners := sel.filter(func(m): return m.is_tuner())
			if tuners.size() != 1 or sel.size() < 2:
				continue
			# The Tuner it names ("Junk Synchron", a "Blackwing" Tuner, a DARK Tuner) and what the rest must be.
			if not _fits(tuners[0], rule.get("tuner", {})):
				continue
			var others_ok := true
			for m in sel:
				if not m.is_tuner() and not _fits(m, rule.get("others", {})):
					others_ok = false
				if not _may_be_material(m, c, sel, rule):
					others_ok = false
			if not others_ok or (rule.get("one_other", false) and sel.size() != 2) or sel.size() - 1 < int(rule.get("min_others", 1)):
				continue
			if _levels_reach(sel, c):
				out.append(sel)
		out.sort_custom(func(a, b): return _sum_atk(a) < _sum_atk(b))
	return out


## A material's own limits: what it may be used for, and who it may be used with.
func _may_be_material(m: CardInst, c: CardInst, sel: Array, rule: Dictionary) -> bool:
	var mf := EffectRunner.fx(m)
	# Debris Dragon: only for a Dragon Synchro Monster, and the other materials cannot be Level 4.
	var only: Dictionary = mf.get("synchro_for", {})
	if not only.is_empty() and not CardEffects.matches(c.data, only):
		return false
	if mf.has("others_not_lv"):
		for o in sel:
			if o != m and o.level() == int(mf["others_not_lv"]):
				return false
	# Quickdraw Synchron: only for a monster that names a "Synchron" Tuner as its material.
	if mf.has("synchro_for_tuner_has"):
		var tf: Dictionary = rule.get("tuner", {})
		if not (str(tf.get("name", "")).contains(str(mf["synchro_for_tuner_has"])) or str(tf.get("has", "")).contains(str(mf["synchro_for_tuner_has"]))):
			return false
	return true


## The Levels a monster can count as when it is a Synchro Material for `c`.
func _synchro_levels(m: CardInst, c: CardInst) -> Array:
	var mf := EffectRunner.fx(m)
	var lv := m.level()
	# Road Synchron: its Level is 2 lower for anything but "Road Warrior".
	var delta: Array = mf.get("synchro_lv_delta", [])
	if not delta.is_empty() and c.cname() != str(delta[1]):
		lv = maxi(1, lv + int(delta[0]))
	var out := [lv]
	# Tuningware: on the field it can be treated as a Level 2 monster.
	if mf.has("synchro_lv_alt") and not out.has(int(mf["synchro_lv_alt"])):
		out.append(int(mf["synchro_lv_alt"]))
	return out


func _levels_reach(sel: Array, c: CardInst) -> bool:
	var sums := [0]
	for m in sel:
		var next := []
		for base in sums:
			for lv in _synchro_levels(m, c):
				if not next.has(base + lv):
					next.append(base + lv)
		sums = next
	return sums.has(c.level())


## May this monster be Tributed for a card effect or a cost? (Level Eater: only for a Tribute Summon.)
func can_tribute_fx(m: CardInst) -> bool:
	return m.no_tribute_turn != turn and not (m.face_up and EffectRunner.fx(m).get("no_effect_tribute", false))


func _sum_atk(arr: Array) -> int:
	var t := 0
	for m in arr:
		t += m.atk()
	return t


func can_extra_summon(p: int, c: CardInst, any_time := false) -> bool:
	if (not any_time and (p != current or not _in_main())) or is_over() or not players[p].extra.has(c) or players[p].no_summon_turn == turn:
		return false
	if EffectRunner.fx(c).has("contact"):
		return not contact_materials(p, c).is_empty() and (players[p].free_zone() != -1 or _contact_frees_zone(p, c))
	if c.frame() != "synchro" and c.frame() != "xyz":
		return false
	return not extra_materials(p, c).is_empty() or xyz_base(p, c) != null


## "You can also Xyz Summon this card by using a "Number 39: Utopia" you control as material."
## The monster it would go on top of, or null.
func xyz_base(p: int, c: CardInst) -> CardInst:
	var want := str(CardEffects.of(c.cname()).get("xyz_onto", ""))
	if want == "" or c.frame() != "xyz":
		return null
	for m in players[p].monsters():
		if m.face_up and m.cname() == want:
			return m
	return null


## Xyz Summon `x` using `base` as the material: its own materials move across with it.
func xyz_onto(p: int, x: CardInst, base: CardInst) -> Array:
	var ps := players[p]
	if not ps.extra.has(x) or not ps.field.has(base):
		return []
	var z := ps.field.find(base)
	ps.field[z] = null
	x.overlays.append(base)
	for o in base.overlays:
		x.overlays.append(o)
	base.overlays.clear()
	var events := [{"type": "material", "player": p, "card": base, "from": "field", "zone": z, "overlay": true}]
	events.append_array(_monster_left(base))
	ps.extra.erase(x)
	x.proper = true
	events.append_array(_special(p, x, "xyz"))
	events.append_array(EffectRunner.on_summon(self, p, x, "xyz"))
	return events


## XYZ-Dragon Cannon and its kind: "Special Summoned (from your Extra Deck) by banishing the above
## cards you control". The named cards count wherever you control them face-up: as monsters, or
## as Union monsters riding as Equip Cards. Returns one card per name, or [] when one is missing.
func contact_materials(p: int, c: CardInst) -> Array:
	var out := []
	# (The Neos Contact Fusions take "the above cards you control", face-down ones too.)
	var any_face: bool = str(CardEffects.of(c.cname()).get("contact_to", "")) == "deck"
	for nm in CardEffects.of(c.cname()).get("contact", []):
		var got: CardInst = null
		for m in players[p].monsters():
			if (m.face_up or any_face) and m.cname() == str(nm) and not out.has(m):
				got = m
				break
		if got == null:
			for st in players[p].spells:
				if st != null and st.face_up and st.is_monster() and st.cname() == str(nm) and not out.has(st):
					got = st
					break
		if got == null:
			return []
		out.append(got)
	return out


func _contact_frees_zone(p: int, c: CardInst) -> bool:
	for m in contact_materials(p, c):
		if players[p].field.has(m):
			return true
	return false


func _contact_summon(p: int, c: CardInst) -> Array:
	var ps := players[p]
	var events := []
	var to_deck := str(CardEffects.of(c.cname()).get("contact_to", "")) == "deck"
	for m in contact_materials(p, c):
		if to_deck:
			# "...by shuffling the above cards you control into the Deck" (the Neos Contact Fusions).
			events.append_array(_to_deck(m))
		elif ps.spells.has(m):
			ps.spells[ps.spells.find(m)] = null
			m.equipped_to = null
			ps.banished.append(m)
			events.append({"type": "banish", "player": p, "card": m})
		else:
			events.append_array(_banish(m))
	ps.extra.erase(c)
	c.proper = true
	events.append_array(_special(p, c, "fusion"))
	events.append_array(EffectRunner.on_summon(self, p, c, "fusion"))
	return events


## any_time: a Synchro Summon made by an effect outside your own Main Phase (Formula Synchron, Urgent Tuning).
func extra_summon(p: int, c: CardInst, materials: Array = [], any_time := false) -> Array:
	if not can_extra_summon(p, c, any_time):
		return []
	if EffectRunner.fx(c).has("contact"):
		return _contact_summon(p, c)
	if materials.is_empty() and extra_materials(p, c).is_empty() and xyz_base(p, c) != null:
		return xyz_onto(p, c, xyz_base(p, c))
	if materials.is_empty():
		materials = extra_materials(p, c)[0]
	var ps := players[p]
	var events := []
	var xyz := c.frame() == "xyz"
	for m in materials:
		var z := ps.field.find(m)
		if z == -1:
			return []
	var revenge_bonus := 0
	var girl_gift: bool = xyz and not materials.is_empty()
	for m in materials:
		if not m.cname().contains("Gagaga"):
			girl_gift = false
		for st in ps.spells:
			if xyz and st != null and st.face_up and (st.linked == m or st.equipped_to == m):
				revenge_bonus += int(SpellRules.spec(st).get("xyz_mat_bonus", 0))
	if girl_gift and materials.filter(func(m): return m.face_up and not m.negated and CardEffects.of(m.cname()).get("gagaga_girl", false)).is_empty():
		girl_gift = false
	for m in materials:
		var z := ps.field.find(m)
		ps.field[z] = null
		if xyz:
			c.overlays.append(m)
		else:
			_to_gy(ps, m)
		events.append({"type": "material", "player": p, "card": m, "from": "field", "zone": z, "overlay": xyz})
		events.append_array(_monster_left(m))
	ps.extra.erase(c)
	c.proper = true
	events.append_array(_special(p, c, c.frame()))
	if not xyz:
		# What it was made with (Junk Destroyer, Shooting Quasar Dragon, Synchro Strike).
		c.tags["mats"] = materials.size()
		c.tags["non_tuners"] = materials.filter(func(m): return not m.is_tuner()).size()
		for m in materials:
			# "...for the Synchro Summon of a "Nitro" Synchro Monster" / "of a DARK Synchro Monster".
			var mf := EffectRunner.fx(m)
			if mf.has("material_for") and not c.cname().contains(str(mf["material_for"])):
				continue
			if mf.has("material_attr") and str(c.data.get("attribute", "")) != str(mf["material_attr"]):
				continue
			if mf.has("material_race") and str(c.data.get("race", "")) != str(mf["material_race"]):
				continue
			events.append_array(EffectRunner.trigger(self, m, "material", {"into": c}))
	var ctx_kind := c.frame()
	events.append_array(EffectRunner.on_summon(self, p, c, ctx_kind))
	if revenge_bonus > 0:
		# Gagagarevenge: "...because the equipped monster was used as an Xyz Material: All Xyz Monsters you currently control gain 300 ATK."
		for xm in ps.monsters():
			if xm.face_up and xm.frame() == "xyz":
				xm.atk_mod += revenge_bonus
		events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("Gagagarevenge: your Xyz Monsters gain %d ATK") % revenge_bonus})
	if girl_gift and ps.field.has(c):
		# Gagaga Girl: "When it is Xyz Summoned: You can target 1 Special Summoned monster your opponent controls; its ATK becomes 0."
		var ss_m: Array = players[opponent(p)].monsters().filter(func(m): return m.face_up and m.tags.get("ss", false) and not m.zero_perm)
		if not ss_m.is_empty():
			var top_g: CardInst = ss_m[0]
			for m in ss_m:
				if atk_of(m, false) > atk_of(top_g, false):
					top_g = m
			var got_g := choose(p, Loc.t("Gagaga Girl: make the ATK of 1 Special Summoned monster 0?"), ss_m, 1, [top_g], true, c)
			if not got_g.is_empty():
				got_g[0].zero_perm = true
				events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("Gagaga Girl's gift: the ATK of %s becomes 0") % got_g[0].cname()})
	if not xyz and not is_over():
		# Stardust Xiaolong: "When you Synchro Summon "Stardust Dragon": You can Special Summon this card from your GY in Attack Position."
		for g in ps.gy.duplicate():
			if ps.free_zone() != -1 and str(CardEffects.of(g.cname()).get("revive_on_synchro", "")) == c.cname() and can_revive(g):
				if choose_option(p, Loc.t("%s: Special Summon it from your Graveyard?") % g.cname(), ["Special Summon it", "No"], 0, g) == 0:
					ps.gy.erase(g)
					events.append({"type": "effect", "player": p, "card": g, "text": Loc.t("%s rises with %s") % [g.cname(), c.cname()]})
					events.append_array(_special(p, g, "reborn", "atk"))
					last_summoned = c
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
		np.no_effect_damage_turn = ps.no_effect_damage_turn
		np.name_lock = ps.name_lock.duplicate()
		np.once_names = ps.once_names.duplicate()
		np.exiles = ps.exiles.duplicate(true)   # their cards are mapped below, once every card has its copy
		np.protect_turn = ps.protect_turn
		np.swords_left = ps.swords_left
		np.field_spell = _clone_card(ps.field_spell, map) if ps.field_spell != null else null
		np.no_attack_turn = ps.no_attack_turn
		np.skip_draw = ps.skip_draw
		np.no_summon_turn = ps.no_summon_turn
		np.spell_turn = ps.spell_turn
		np.speed = ps.speed
		np.speed_turn = ps.speed_turn
		np.attacks_this_turn = ps.attacks_this_turn
		np.attacks_turn = ps.attacks_turn
		np.extra_normals = ps.extra_normals
		np.no_damage_until = ps.no_damage_until
		np.once_duel = ps.once_duel.duplicate()
		np.summons_turn = ps.summons_turn
		np.only_attacker = ps.only_attacker
		np.only_attacker_turn = ps.only_attacker_turn
		s.players.append(np)
	for np2 in s.players:
		for ex in np2.exiles:
			ex["card"] = map.get(ex["card"].uid, ex["card"])
	s.destiny = destiny
	s.destiny_who = destiny_who.duplicate()
	s.destiny_used = destiny_used.duplicate()
	for q in 2:
		s.destiny_next[q] = map.get(destiny_next[q].uid) if destiny_next[q] != null else null
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
	if _shield != null:
		s._shield = map.get(_shield.uid)
	if not pending_attack.is_empty():
		s.pending_attack = pending_attack.duplicate()
		s.pending_attack["attacker"] = map.get(pending_attack["attacker"].uid, pending_attack["attacker"])
		if pending_attack["target"] != null:
			s.pending_attack["target"] = map.get(pending_attack["target"].uid, pending_attack["target"])
	s.current = current
	s.turn = turn
	s.turbo = turbo
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
	n.mode = c.mode
	n.normal_turn = c.normal_turn
	n.lv_set = c.lv_set
	n.lv_turn = c.lv_turn
	n.died_turn = c.died_turn
	n.gy_turn = c.gy_turn
	n.leave_banish = c.leave_banish
	n.tmp_atk = c.tmp_atk
	n.tmp_until = c.tmp_until
	n.back_pos = c.back_pos
	n.lv_aura = c.lv_aura
	n.hit_def_turn = c.hit_def_turn
	n.shrunk = c.shrunk
	n.wedge = c.wedge
	n.flag_turn = c.flag_turn
	n.once = c.once
	n.pos_lock_until = c.pos_lock_until
	n.no_tribute_turn = c.no_tribute_turn
	n.def_mod = c.def_mod
	n.neg_perm = c.neg_perm
	n.zero_perm = c.zero_perm
	n.cowboy_turn = c.cowboy_turn
	n.bonus_attacks = c.bonus_attacks
	n.tags = c.tags.duplicate()
	n.bonus_attacks_turn = c.bonus_attacks_turn
	n.left_turn = c.left_turn
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
	# Infernity Beast: while it attacks with its owner's hand empty, the other side cannot use Spells or Traps.
	var st_locked := false
	if not pending_attack.is_empty() and pending_attack["player"] != p and not pending_attack.get("negated", false):
		var atk_c: CardInst = pending_attack["attacker"]
		if EffectRunner.fx(atk_c).get("lock_st_if_hand_empty", false) and players[pending_attack["player"]].hand.is_empty():
			st_locked = true
	for c in ps.spells:
		if not st_locked and c != null and not c.face_up and SpellRules.fits(self, p, c, window, subject) and ps.speed >= speed_need(c):
			out.append(c)
	for c in ps.hand:
		if not st_locked and not c.is_monster() and SpellRules.fits(self, p, c, window, subject) and ps.speed >= speed_need(c):
			out.append(c)
	# Stardust Dragon: when a card or effect that would destroy a card on the field is activated.
	if not chain.is_empty() and window == "chain" and SpellRules.would_destroy(chain.back()):
		for m in ps.monsters():
			if m.face_up and EffectRunner.fx(m).get("stardust", false):
				out.append(m)
				break
	# Quick Effects of monsters on the field, in the hand, and of cards in the Graveyard
	# (EffectRunner.quick_can says when each one fits).
	var quicks: Array = []
	quicks.append_array(ps.monsters())
	quicks.append_array(ps.hand)
	quicks.append_array(ps.gy)
	for qc in quicks:
		if not out.has(qc) and EffectRunner.quick_can(self, p, qc, window, subject):
			out.append(qc)
	# Galaxy-Eyes Photon Dragon: in the Battle Step, while it battles an opponent's monster.
	if window == "attack" and not pending_attack.is_empty() and not pending_attack.get("negated", false) and pending_attack["target"] != null:
		for m in [pending_attack["attacker"], pending_attack["target"]]:
			if ps.field.has(m) and m.face_up and EffectRunner.fx(m).get("gepd", false):
				out.append(m)
	# Blackwing - Kalut the Moon Shadow: from the hand in the Damage Step, when your Blackwing battles.
	if window == "damage" and not pending_attack.is_empty() and not pending_attack.get("negated", false):
		var mine := _kalut_target(p)
		if mine != null:
			for c in ps.hand:
				if CardEffects.of(c.cname()).has("hand_boost_family"):
					out.append(c)
					break
	if window == "attack":
		if not pending_attack.is_empty() and pending_attack["player"] != p:
			for c in ps.hand:
				if c.cname() == "Kuriboh":
					out.append(c)
					break
			# Battle Fader: from the hand, against a direct attack.
			if pending_attack["target"] == null and ps.free_zone() != -1 and ps.no_summon_turn != turn:
				for c in ps.hand:
					if c.cname() == "Battle Fader":
						out.append(c)
						break
			# Shield Warrior: from the Graveyard, when one of your monsters is attacked.
			if pending_attack["target"] != null and _shield == null:
				for c in ps.gy:
					if c.cname() == "Shield Warrior":
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
## The monster of player `p` that is battling right now, if it belongs to the family Kalut helps.
func _kalut_target(p: int) -> CardInst:
	if pending_attack.is_empty():
		return null
	for m in [pending_attack["attacker"], pending_attack["target"]]:
		if m != null and players[p].field.has(m) and m.face_up and m.cname().contains("Blackwing"):
			return m
	return null


func respond(p: int, c: CardInst, subject = null) -> Array:
	var ps := players[p]
	var events := []
	if CardEffects.of(c.cname()).has("quick") and (c.is_monster() or ps.gy.has(c)):
		return EffectRunner.quick_run(self, p, c)
	if ps.field.has(c) and EffectRunner.fx(c).get("stardust", false) and not chain.is_empty():
		# Tribute Stardust Dragon: negate that activation and destroy the card.
		var link: Dictionary = chain.back()
		var zone := ps.field.find(c)
		ps.field[zone] = null
		_to_gy(ps, c)
		c.flag_turn = turn
		events.append({"type": "tribute", "player": p, "card": c})
		events.append_array(EffectRunner.trigger(self, c, "tributed"))
		events.append_array(_monster_left(c))
		link["negated"] = true
		var bad: CardInst = link["card"]
		events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s negates %s and destroys it") % [c.cname(), bad.cname()]})
		if bad.is_monster():
			events.append_array(_destroy(bad))
		else:
			events.append_array(_destroy_st(bad))
		return events
	if ps.field.has(c) and EffectRunner.fx(c).get("gepd", false) and not pending_attack.is_empty():
		# Banish Galaxy-Eyes and the monster it battles until the end of the Battle Phase.
		var other: CardInst = pending_attack["target"] if pending_attack["attacker"] == c else pending_attack["attacker"]
		if other == null:
			return events
		var o := opponent(p)
		var hold := {"dragon": c, "dragon_side": p, "dragon_atk": c.attack_pos, "other": other, "other_side": o, "other_atk": other.attack_pos,
			"mats": other.overlays.size() if other.frame() == "xyz" else 0}
		events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s takes %s out of the battle") % [c.cname(), other.cname()]})
		events.append_array(_banish(c))
		events.append_array(_banish(other))
		gepd_hold.append(hold)
		pending_attack["negated"] = true
		return events
	var boost: Array = CardEffects.of(c.cname()).get("hand_boost_family", [])
	if not boost.is_empty() and ps.hand.has(c):
		var who := _kalut_target(p)
		if who == null:
			return events
		ps.hand.erase(c)
		_to_gy(ps, c)
		if who.atk_mod_turn != turn:
			who.atk_mod_turn = turn
			who.atk_mod_t = 0
		who.atk_mod_t += int(boost[1])
		events.append({"type": "hand_effect", "player": p, "card": c, "text": Loc.t("%s: %s gains %d ATK") % [c.cname(), who.cname(), int(boost[1])]})
		return events
	if c.cname() == "Kuriboh" and ps.hand.has(c):
		ps.hand.erase(c)
		_to_gy(ps, c)
		ps.no_damage_turn = turn
		events.append({"type": "hand_effect", "player": p, "card": c, "text": "Kuriboh! No battle damage."})
		return events
	if c.cname() == "Battle Fader" and ps.hand.has(c) and not pending_attack.is_empty():
		ps.hand.erase(c)
		events.append({"type": "hand_effect", "player": p, "card": c, "text": "Battle Fader! The Battle Phase ends."})
		events.append_array(_special(p, c, "effect"))
		pending_attack["negated"] = true
		players[pending_attack["player"]].no_attack_turn = turn
		last_summoned = null
		return events
	if c.cname() == "Shield Warrior" and ps.gy.has(c) and not pending_attack.is_empty() and pending_attack["target"] != null:
		events.append_array(_banish(c))
		_shield = pending_attack["target"]
		events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("Shield Warrior protects %s") % _shield.cname()})
		return events
	if c.cname() == "Number 39: Utopia":
		c.used_turn = turn
		var o: CardInst = pick1(p, Loc.t("%s: detach 1 material") % c.cname(), c.overlays, c.overlays.back(), c)
		c.overlays.erase(o)
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
	# Cards with a written effect list run through EffectRunner (once, on the chain, with the
	# player choosing). The fixed versions below are only for cards that have none.
	if EffectRunner.fx(c).has("summon"):
		return events
	match c.cname():
		"Junk Synchron":
			if ps.free_zone() == -1:
				return events
			for g in ps.gy:
				if g.is_monster() and g.level() <= 2 and not CardData.is_extra(g.id):
					ps.gy.erase(g)
					events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("Junk Synchron revives %s") % g.cname()})
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
					events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("Goblindbergh brings out %s") % h.cname()})
					events.append_array(_special(p, h, "effect"))
					c.attack_pos = false
					events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
					break
	return events
