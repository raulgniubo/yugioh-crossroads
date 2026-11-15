class_name EffectRunner
## Runs the monster effects described in CardEffects against a DuelState.
## Everything returns duel events, like the rest of the rules engine.


static func fx(c) -> Dictionary:
	if c == null or c.negated:
		return {}   # negated (Skill Drain, Forbidden Chalice...): the monster has no effects right now
	return CardEffects.of(c.cname())


static func _ev(p: int, c, text: String) -> Dictionary:
	return {"type": "effect", "player": p, "card": c, "text": text}


# ------------------------------------------------------------------ passives

## ATK change from effects. vs = the other monster in battle (null for direct / not battling).
static func atk_bonus(s: DuelState, c, attacking: bool, vs, battling: bool) -> int:
	var f := fx(c)
	var b := union_boost(s, c)
	if c.atk_mod_turn == s.turn:
		b += c.atk_mod_t
	b += c.atk_mod
	if c.tmp_until >= s.turn:
		b += c.tmp_atk
	b += int(f.get("atk_per_counter", 0)) * c.counter
	if battling and attacking:
		if vs != null:
			b += int(f.get("atk_attack", 0))
			if not vs.attack_pos:
				b += int(f.get("atk_vs_def", 0))
		else:
			b += int(f.get("atk_direct", 0))
	if battling and attacking and f.get("nitro", false) and s.players[c.owner].spell_turn == s.turn and c.attack_count <= 1:
		b += 1000
	if battling and not attacking:
		b += int(f.get("atk_attacked", 0))
	# Speed Warrior: in the Battle Phase of the turn it was Normal Summoned, double its original ATK.
	if f.get("double_bp_normal_turn", false) and c.normal_turn == s.turn and s.phase == DuelState.Phase.BATTLE:
		b += c.atk()
	if f.has("atk_per"):
		var spec: String = f["atk_per"][0]
		b += _count(s, c.owner, spec) * int(f["atk_per"][1])
	if f.has("lose_if_alone"):
		var n := 0
		for m in s.players[c.owner].monsters():
			if m != c and m.cname() == c.cname():
				n += 1
		if n == 0:
			b -= int(f["lose_if_alone"])
	if f.get("blader", false) and s.players[s.opponent(c.owner)].monsters().size() == 2:
		b += c.atk()
	if f.get("half_if_special", false) and c.get_meta("special_from_hand", false):
		b -= c.atk() / 2
	# Auras from other monsters on the field
	for p in 2:
		for m in s.players[p].monsters():
			if not m.face_up or m == c:
				continue
			var mf := fx(m)
			if mf.has("aura") and str(c.data.get("attribute", "")) == mf["aura"][0]:
				b += int(mf["aura"][1])
			if mf.has("aura_own_race") and p == c.owner and str(c.data.get("race", "")) == mf["aura_own_race"][0]:
				b += int(mf["aura_own_race"][1])
	# Harpie Lady 1 also powers itself up (it's WIND)
	if f.has("aura") and str(c.data.get("attribute", "")) == f["aura"][0]:
		b += int(f["aura"][1])
	if c.zero_turn == s.turn:
		return -c.atk()
	if c.half_turn == s.turn:
		b -= (c.atk() + b) / 2
	return b


## DEF from a monster's own effect ("ATK/DEF become...", "gains ATK/DEF for each...").
static func def_bonus(s: DuelState, c) -> int:
	var f := fx(c)
	var u := union_boost(s, c)
	if f.has("def_per"):
		return u + _count(s, c.owner, str(f["def_per"][0])) * int(f["def_per"][1])
	return u


static func _count(s: DuelState, owner: int, spec: String) -> int:
	var parts := spec.split(":")
	var kind := parts[0]
	var val := parts[1] if parts.size() > 1 else ""
	var n := 0
	if kind == "own_banished":
		return s.players[owner].banished.size()
	if kind == "gy_named":
		# Copies of one card in both Graveyards (Dark Magician Girl counts Dark Magicians).
		for q in 2:
			for g in s.players[q].gy:
				if g.cname() in val.split("|"):
					n += 1
		return n
	if kind == "all_banished_monsters":
		for q in 2:
			for b in s.players[q].banished:
				if b.is_monster():
					n += 1
		return n
	var sides := [owner] if kind.begins_with("own") else [0, 1]
	for p in sides:
		for m in s.players[p].monsters():
			if not m.face_up:
				continue
			match kind:
				"own_race", "field_race_all":
					if str(m.data.get("race", "")) == val:
						n += 1
				"own_named", "field_named":
					if m.cname() == val or str(fx(m).get("name_as", "")) == val or str(fx(m).get("name_as_fg", "")) == val:
						n += 1
	return n


static func can_direct(s: DuelState, p: int, c) -> bool:
	var opp := s.players[s.opponent(p)]
	if opp.monsters().is_empty():
		return true
	var f := fx(c)
	if f.get("direct", false):
		return true
	# Toons. The small ones need your Toon World and no Toon across the table; the big ones
	# only need the other side to have no Toon.
	var toon := int(f.get("toon", 0))
	if toon == 1 and not c.negated:
		return s.toon_world(p) and not s.has_toon(s.opponent(p))
	if toon == 2 and not c.negated:
		return not s.has_toon(s.opponent(p))
	match str(f.get("direct_if", "")):
		"opp_all_def":
			# "If the only cards your opponent controls are Defense Position monsters"
			for m in opp.monsters():
				if m.attack_pos:
					return false
			return opp.set_cards().is_empty() and opp.field_spell == null and _st_count(opp) == 0
		"opp_only_ewf":
			for m in opp.monsters():
				if m.face_up and not str(m.data.get("attribute", "")) in ["EARTH", "WATER", "FIRE"]:
					return false
			return true
		"opp_all_1600":
			# "If the only cards your opponent controls are face-up monsters with 1600 or more ATK"
			for m in opp.monsters():
				if not m.face_up or s.atk_of(m, false) < 1600:
					return false
			return opp.field_spell == null and _st_count(opp) == 0
		"opp_all_stronger":
			for m in opp.monsters():
				if s.atk_of(m, false) <= s.atk_of(c, false):
					return false
			return true
	return false


static func _st_count(ps) -> int:
	var n := 0
	for st in ps.spells:
		if st != null:
			n += 1
	return n


static func max_attacks(c) -> int:
	var f := fx(c)
	if f.get("double_vs_def", false):
		# Twin-Sword Marauder: a second attack in a row only after it attacked a Defense Position monster.
		return 2 if c.hit_def_turn != -1 and c.hit_def_turn == c.attack_count_turn else 1
	if f.get("double_after_kill", false):
		# Black Luster Soldier - Envoy of the Beginning: one of its two effects each turn.
		return 2 if c.killed_turn != -1 and c.killed_turn == c.attack_count_turn and c.ignite_turn != c.killed_turn else 1
	return 2 if f.get("double_attack", false) else 1


static func piercing(s: DuelState, p: int, c) -> bool:
	if fx(c).get("piercing", false):
		return true
	if c.frame() == "ritual":
		# Cyber Angel Dakini: while it is face-up, every Ritual Monster you control pierces.
		for m in s.players[p].monsters():
			if m.face_up and not m.negated and fx(m).get("ritual_pierce", false):
				return true
	if s.players[p].hand.is_empty():
		for m in s.players[p].monsters():
			if m.face_up and fx(m).get("piercing_if", "") == "hand_empty":
				return true
	return false


## True if c cannot be destroyed by a card effect right now.
static func survives_effect(s: DuelState, c) -> bool:
	var f := fx(c)
	if f.get("hand_empty_guard", false) and c.face_up and s.players[c.owner].hand.is_empty():
		return true
	return false


## True if c shrugs off being destroyed by battle (and records the once-per-turn use).
static func survives_battle(s: DuelState, c) -> bool:
	var f := fx(c)
	if f.get("battle_immune", false):
		return true
	if f.get("hand_empty_guard", false) and s.players[c.owner].hand.is_empty():
		return true
	if f.get("blader", false) and s.players[s.opponent(c.owner)].monsters().size() == 1:
		return true
	if f.get("survive_once_def", false) and not c.attack_pos and c.survive_turn != s.turn:
		c.survive_turn = s.turn
		return true
	if f.get("survive_once", false) and c.survive_turn != s.turn:
		c.survive_turn = s.turn
		return true
	return false


static func no_damage_involving(c) -> bool:
	return c != null and fx(c).get("no_damage_involving", false)


static func no_tribute(s: DuelState, p: int, c) -> bool:
	var cond := str(fx(c).get("no_tribute_if", ""))
	return cond != "" and _cond(s, p, cond)


static func _cond(s: DuelState, p: int, cond: String) -> bool:
	var mine := s.players[p].monsters()
	var theirs := s.players[s.opponent(p)].monsters()
	if cond.begins_with("own_summoned_race:"):
		# One of your monsters of these Types was Summoned this turn (Shark Stickers).
		var races := cond.substr(18).split("|")
		for m in mine:
			if m.face_up and m.summoned_turn == s.turn and str(m.data.get("race", "")) in races:
				return true
		return false
	if cond.begins_with("own_has:"):
		for m in mine:
			if m.face_up and CardEffects.matches(m.data, {"has": cond.substr(8)}):
				return true
		return false
	match cond:
		"opp_only":
			return mine.is_empty() and not theirs.is_empty()
		"opp_two":
			return theirs.size() >= 2
		"own_none":
			return mine.is_empty()
		"always":
			return true
		"hand_empty":
			return s.players[p].hand.is_empty()
		"own_tuner":
			for m in mine:
				if m.face_up and m.is_tuner():
					return true
			return false
		"only_card_in_hand":
			return s.players[p].hand.size() == 1
		"gy_dark3":
			var n := 0
			for g in s.players[p].gy:
				if g.is_monster() and str(g.data.get("attribute", "")) == "DARK":
					n += 1
			return n == 3
	return false


## Does this monster have its own way to be Special Summoned from the hand?
static func has_special_hand(c) -> bool:
	var f := fx(c)
	for k in ["special_hand_if", "special_tribute2", "special_tribute_attr", "special_banish_ld", "eltanin", "special_toon", "special_discard_attr"]:
		if f.has(k):
			return true
	return false


## Special Summon from the hand by its own rule (Bora, Gale, Vice Dragon, Photon Thrasher...).
static func can_special_hand(s: DuelState, p: int, c) -> bool:
	var f := fx(c)
	if s.players[p].free_zone() == -1 and int(f.get("special_toon", 0)) == 0:
		return false
	if f.get("special_banish_ld", false):
		return _gy_attr(s, p, "LIGHT") != null and _gy_attr(s, p, "DARK") != null
	if f.get("eltanin", false):
		return not _light_machines(s, p).is_empty()
	if f.has("special_hand_if"):
		return _cond(s, p, str(f["special_hand_if"]))
	if f.has("special_discard_attr"):
		# Galaxy Soldier: send 1 other monster of that Attribute from your hand to the Graveyard.
		for h in s.players[p].hand:
			if h != c and h.is_monster() and str(h.data.get("attribute", "")) == str(f["special_discard_attr"]):
				return true
		return false
	if f.has("special_toon"):
		# From the hand while you control Toon World, Tributing that many monsters first.
		return s.toon_world(p) and s.players[p].monsters().size() >= int(f["special_toon"])
	if f.has("special_tribute2"):
		var n := 0
		for m in s.players[p].monsters():
			if s.atk_of(m, false) >= int(f["special_tribute2"]):
				n += 1
		return n >= 2
	if f.has("special_tribute_attr"):
		for m in s.players[p].monsters():
			if str(m.data.get("attribute", "")) == f["special_tribute_attr"]:
				return true
	return false


## The weakest monster of an Attribute in a player's Graveyard (banish costs use the least useful one).
## With `c` (the card paying the cost) the player picks which one.
static func _gy_attr(s: DuelState, p: int, attr: String, c = null):
	var pick = null
	var all: Array = []
	for g in s.players[p].gy:
		if g.is_monster() and str(g.data.get("attribute", "")) == attr:
			all.append(g)
			if pick == null or g.atk() < pick.atk():
				pick = g
	if c != null and pick != null:
		return s.pick1(p, Loc.t("%s: banish 1 %s monster from your Graveyard") % [c.cname(), attr], all, pick, c)
	return pick


static func _light_machines(s: DuelState, p: int) -> Array:
	var out: Array = []
	for m in s.players[p].monsters() + s.players[p].gy:
		if m.is_monster() and (m.face_up or s.players[p].gy.has(m)) and str(m.data.get("attribute", "")) == "LIGHT" and str(m.data.get("race", "")) == "Machine":
			out.append(m)
	return out


static func special_hand(s: DuelState, p: int, c) -> Array:
	var f := fx(c)
	var ps := s.players[p]
	var events := []
	if f.get("eltanin", false):
		var fuel := _light_machines(s, p)
		for m in fuel:
			events.append_array(s._banish(m))
		ps.hand.erase(c)
		c.atk_mod = 500 * fuel.size() - c.atk()
		events.append_array(s._special(p, c, "effect"))
		events.append(_ev(p, c, Loc.t("%s: %d ATK. Every other face-up monster goes to the Graveyard!") % [c.cname(), 500 * fuel.size()]))
		for q in 2:
			for m in s.players[q].monsters():
				if m != c and m.face_up:
					var z := s.players[q].field.find(m)
					s.players[q].field[z] = null
					s._to_gy(s.players[q], m)
					events.append({"type": "destroy", "player": q, "card": m, "zone": z})
					events.append_array(s._monster_left(m))
		return events
	if f.has("special_tribute2") or f.has("special_tribute_attr"):
		var picks := []
		var need := 2 if f.has("special_tribute2") else 1
		var mons := ps.monsters()
		mons.sort_custom(func(a, b): return s.atk_of(a, false) < s.atk_of(b, false))
		var can: Array = []
		for m in mons:
			var ok: bool = (s.atk_of(m, false) >= int(f.get("special_tribute2", 0))) if f.has("special_tribute2") else str(m.data.get("attribute", "")) == f["special_tribute_attr"]
			if ok:
				can.append(m)
				if picks.size() < need:
					picks.append(m)
		picks = s.choose(p, Loc.t("%s: Tribute %d monster%s") % [c.cname(), need, "" if need == 1 else "s"], can, need, picks, false, c)
		for m in picks:
			ps.field[ps.field.find(m)] = null
			s._to_gy(ps, m)
			events.append({"type": "tribute", "player": p, "card": m})
			events.append_array(EffectRunner.trigger(s, m, "tributed"))
	if f.has("special_discard_attr"):
		var pay: Array = ps.hand.filter(func(h): return h != c and h.is_monster() and str(h.data.get("attribute", "")) == str(f["special_discard_attr"]))
		var least = pay[0]
		for h in pay:
			if s._card_value(h) < s._card_value(least):
				least = h
		least = s.pick1(p, Loc.t("%s: send 1 other %s monster from your hand to the Graveyard") % [c.cname(), str(f["special_discard_attr"])], pay, least, c)
		ps.hand.erase(least)
		s._to_gy(ps, least)
		events.append({"type": "discard", "player": p, "card": least})
		events.append_array(trigger(s, least, "gy"))
		ps.hand.erase(c)
		events.append_array(s._special(p, c, "effect", "def"))
		events.append_array(on_summon(s, p, c, "special"))
		return events
	if int(f.get("special_toon", 0)) > 0:
		var need_t := int(f["special_toon"])
		var all_t := ps.monsters()
		all_t.sort_custom(func(a, b): return s.atk_of(a, false) < s.atk_of(b, false))
		var picks_t: Array = all_t.slice(0, need_t)
		picks_t = s.choose(p, Loc.t("%s: Tribute %d monster%s") % [c.cname(), need_t, "" if need_t == 1 else "s"], all_t, need_t, picks_t, false, c)
		for m in picks_t:
			ps.field[ps.field.find(m)] = null
			s._to_gy(ps, m)
			events.append({"type": "tribute", "player": p, "card": m})
			events.append_array(EffectRunner.trigger(s, m, "tributed"))
			events.append_array(s._monster_left(m))
	if f.get("special_banish_ld", false):
		for attr in ["LIGHT", "DARK"]:
			events.append_array(s._banish(_gy_attr(s, p, attr, c)))
	ps.hand.erase(c)
	if f.get("half_if_special", false):
		c.set_meta("special_from_hand", true)
	c.proper = true   # summoned by its own procedure: it may be brought back later
	events.append_array(s._special(p, c, "effect"))
	events.append_array(on_summon(s, p, c, "special"))
	if f.has("hand_special"):
		# "If Summoned this way: ..." (Gilasaurus)
		events.append_array(run_list(s, p, c, f["hand_special"], {}))
	return events


# ------------------------------------------------------------------ triggers

## kind: "normal", "flip", "special", "synchro", "fusion", "xyz"
static func on_summon(s: DuelState, p: int, c, kind: String) -> Array:
	var f := fx(c)
	var events := []
	var fires: bool = (kind == "normal" and f.has("summon")) or (kind == "flip" and f.has("flip")) or (kind == "synchro" and f.has("synchro")) or (kind in ["special", "synchro", "fusion", "xyz"] and f.has("special_only")) or f.has("any_summon")
	if fires and _spent(s, p, c):
		return events
	if kind == "normal" and f.has("summon"):
		events.append_array(run_list(s, p, c, f["summon"], {}))
	if kind == "flip" and f.has("flip"):
		events.append_array(run_list(s, p, c, f["flip"], {}))
	if kind == "synchro" and f.has("synchro"):
		events.append_array(run_list(s, p, c, f["synchro"], {}))
	if kind in ["special", "synchro", "fusion", "xyz"] and f.has("special_only"):
		events.append_array(run_list(s, p, c, f["special_only"], {}))
	if f.has("any_summon"):
		events.append_array(run_list(s, p, c, f["any_summon"], {}))
	return events


## Is this card's effect shut off for its owner right now (a name lock, or its once-per-turn use is spent)?
static func _spent(s: DuelState, p: int, c) -> bool:
	var ps := s.players[p]
	if int(ps.name_lock.get(c.cname(), -1)) == s.turn:
		return true
	if fx(c).get("once_turn", false):
		if int(ps.once_names.get(c.cname(), -1)) == s.turn:
			return true
		ps.once_names[c.cname()] = s.turn
	return false


static func trigger(s: DuelState, c, key: String, ctx := {}) -> Array:
	var f := fx(c)
	if not f.has(key) or s.is_over() or _spent(s, c.owner, c):
		return []
	return run_list(s, c.owner, c, f[key], ctx)


static func standby(s: DuelState, p: int) -> Array:
	var events := []
	# "Special Summon it during your next Standby Phase" (Revival Jam).
	for g in s.players[p].gy.duplicate():
		if g.back_pos == "":
			continue
		var pos: String = g.back_pos if g.back_pos != "any" else ""
		g.back_pos = ""
		if s.players[p].free_zone() != -1 and s.can_revive(g):
			s.players[p].gy.erase(g)
			events.append(_ev(p, g, Loc.t("%s comes back from the Graveyard") % g.cname()))
			events.append_array(s._special(p, g, "reborn", pos))
			events.append_array(on_summon(s, p, g, "special"))
	# Destiny HERO - Doom Lord: the banished monster returns in your 2nd Standby Phase after.
	for ex in s.players[p].exiles.duplicate():
		ex["left"] = int(ex["left"]) - 1
		if int(ex["left"]) > 0:
			continue
		s.players[p].exiles.erase(ex)
		var back = ex["card"]
		var home: DuelState.PlayerState = s.players[int(ex["to"])]
		if home.banished.has(back) and home.free_zone() != -1:
			home.banished.erase(back)
			events.append(_ev(int(ex["to"]), back, Loc.t("%s returns to the field") % back.cname()))
			events.append_array(s._special(int(ex["to"]), back, "return", "atk" if ex["atk_pos"] else "def"))
	for m in s.players[p].monsters():
		if m.shrunk:
			# Max Warrior is itself again.
			m.shrunk = false
			m.lv_set = 0
			m.atk_mod += m.atk() / 2
			m.def_mod += m.def() / 2
			events.append(_ev(p, m, Loc.t("%s is back to full strength") % m.cname()))
		if m.face_up and fx(m).has("standby"):
			events.append_array(run_list(s, p, m, fx(m)["standby"], {}))
	return events


static func end_phase(s: DuelState, p: int) -> Array:
	var events := []
	for m in s.players[p].monsters():
		if m.face_up and fx(m).has("end"):
			events.append_array(run_list(s, p, m, fx(m)["end"], {}))
	return events


## "During the End Phase" effects that do not care whose turn it is.
static func end_phase_any(s: DuelState) -> Array:
	var events := []
	for q in [s.current, s.opponent(s.current)]:
		for m in s.players[q].monsters():
			if m.face_up and fx(m).has("end_any"):
				events.append_array(run_list(s, q, m, fx(m)["end_any"], {}))
	return events


# ------------------------------------------------------------------ ignition effects

## "You can banish this card from your GY; ..." Can this card in the Graveyard do that now?
static func gy_can(s: DuelState, p: int, c) -> bool:
	var g: Dictionary = fx(c).get("gy_ignite", {})
	if g.is_empty() or not s.players[p].gy.has(c):
		return false
	if int(s.players[p].name_lock.get(c.cname(), -1)) == s.turn:
		return false
	if g.has("cond") and not _cond(s, p, str(g["cond"])):
		return false
	if g.get("revive_self", false):
		return s.players[p].free_zone() != -1
	for a in g.get("do", []):
		if a[0] == "special" and a[1] == "deck":
			if s.players[p].free_zone() == -1 or _take(s.players[p].deck, a[2], 1).is_empty():
				return false
		if a[0] == "special" and a[1] == "hand":
			if s.players[p].free_zone() == -1 or _take(s.players[p].hand, a[2], 1).is_empty():
				return false
	return true


## An effect used from the hand by discarding the card itself.
static func hand_can(s: DuelState, p: int, c) -> bool:
	var g: Dictionary = fx(c).get("hand_ignite", {})
	if g.is_empty() or int(s.players[p].name_lock.get(c.cname(), -1)) == s.turn:
		return false
	for a in g.get("do", []):
		if a[0] == "search" and _take(s.players[p].deck, a[1], 1).is_empty():
			return false
	return true


static func hand_run(s: DuelState, p: int, c) -> Array:
	var g: Dictionary = fx(c)["hand_ignite"]
	var ps := s.players[p]
	var events := [_ev(p, c, Loc.t("%s is discarded for its effect") % c.cname())]
	ps.hand.erase(c)
	s._to_gy(ps, c)
	events.append({"type": "discard", "player": p, "card": c})
	events.append_array(run_list(s, p, c, g.get("do", []), {}))
	return events


static func gy_run(s: DuelState, p: int, c) -> Array:
	var g: Dictionary = fx(c)["gy_ignite"]
	if g.get("revive_self", false):
		# "If this card is in your GY: You can Special Summon this card" (Quillbolt Hedgehog).
		s.players[p].gy.erase(c)
		var back := [_ev(p, c, Loc.t("%s comes back from the Graveyard") % c.cname())]
		back.append_array(s._special(p, c, "reborn"))
		c.leave_banish = bool(g.get("banish_on_leave", false))
		back.append_array(on_summon(s, p, c, "special"))
		return back
	var events := [_ev(p, c, Loc.t("%s is banished from the Graveyard for its effect") % c.cname())]
	s.players[p].gy.erase(c)
	s.players[p].banished.append(c)
	events.append({"type": "banish", "player": p, "card": c})
	events.append_array(run_list(s, p, c, g.get("do", []), {}))
	return events


## A Union monster's once-per-turn move: onto a partner as an Equip Card, or back off it as a monster.
static func _union(s: DuelState, p: int, c) -> Array:
	var ps := s.players[p]
	c.ignite_turn = s.turn
	if ps.spells.has(c):
		var was = c.equipped_to
		ps.spells[ps.spells.find(c)] = null
		c.equipped_to = null
		var ev := [_ev(p, c, Loc.t("%s comes off %s") % [c.cname(), was.cname() if was != null else "?"])]
		ev.append_array(s._special(p, c, "effect"))
		return ev
	var hosts := s.union_hosts(p, c)
	var best = hosts[0]
	for h in hosts:
		if s.atk_of(h, false) > s.atk_of(best, false):
			best = h
	best = s.pick1(p, Loc.t("%s: equip it to which monster?") % c.cname(), hosts, best, c)
	ps.field[ps.field.find(c)] = null
	ps.spells[ps.spells.find(null)] = c
	c.equipped_to = best
	c.face_up = true
	c.attack_pos = true
	var gain := int(fx(c)["union"].get("boost", 0))
	return [_ev(p, c, Loc.t("%s is equipped to %s: +%d ATK and DEF") % [c.cname(), best.cname(), gain])]


## ATK and DEF a monster gets from the Union monsters equipped to it.
static func union_boost(s: DuelState, c) -> int:
	var b := 0
	for u in s.unions_on(c):
		if not u.negated:
			b += int(fx(u).get("union", {}).get("boost", 0))
	return b


static func ignite_spec(c) -> Dictionary:
	if fx(c).has("union"):
		return {"label": "Equip to a partner / unequip"}
	return fx(c).get("ignite", {})


static func can_ignite(s: DuelState, p: int, c) -> bool:
	if fx(c).has("union"):
		# Once per turn, either: equip it to one of its partners, or take it off and Special Summon it.
		if p != s.current or s.is_over() or not s._in_main() or c.ignite_turn == s.turn or c.negated:
			return false
		if s.players[p].spells.has(c):
			return c.face_up and c.equipped_to != null and s.players[p].free_zone() != -1
		return s.players[p].field.has(c) and c.face_up and not s.union_hosts(p, c).is_empty() and s.players[p].spells.find(null) != -1
	var ig := ignite_spec(c)
	if ig.is_empty() or p != s.current or s.is_over() or not s._in_main():
		return false
	if int(s.players[p].name_lock.get(c.cname(), -1)) == s.turn:
		return false
	if not s.players[p].field.has(c) or not c.face_up or (c.ignite_turn == s.turn and not ig.get("repeat", false)):
		return false
	if ig.has("cond") and not _cond(s, p, str(ig["cond"])):
		return false
	var ps := s.players[p]
	if ig.get("name_once", false) and int(ps.once_names.get(c.cname(), -1)) == s.turn:
		return false   # "You can only use this effect of ... once per turn"
	if ig.get("need_atk_pos", false) and not c.attack_pos:
		return false
	if ig.get("no_attack_yet", false) and ps.attacks_turn == s.turn and ps.attacks_this_turn > 0:
		return false   # "You cannot declare an attack the turn you activate this effect"
	if ig.get("not_after_double", false) and c.attack_count_turn == s.turn and c.attack_count >= 2:
		return false   # it already used its other effect this turn
	match str(ig.get("cost", "none")):
		"counter":
			if c.counter < 1:
				return false
		"banish_gy_light2":
			if ps.gy.filter(func(g): return g.is_monster() and str(g.data.get("attribute", "")) == "LIGHT").size() < 2:
				return false
		"discard_family":
			var has_one := false
			for h in ps.hand:
				if h.cname().contains(str(ig.get("family", ""))):
					has_one = true
			if not has_one:
				return false
		"discard":
			if ps.hand.is_empty():
				return false
		"discard_monster":
			var any := false
			for h in ps.hand:
				if h.is_monster():
					any = true
			if not any:
				return false
		"tribute_other":
			if ps.monsters().size() < 2:
				return false
		"tribute_plant":
			var any := false
			for m in ps.monsters():
				if m.face_up and str(m.data.get("race", "")) == "Plant":
					any = true
			if not any:
				return false
		"detach":
			if c.overlays.size() < 1:
				return false
		"detach2":
			if c.overlays.size() < 2:
				return false
		"banish_gy_dark":
			if _gy_attr(s, p, "DARK") == null:
				return false
		"banish_gy_monster":
			if s._best_monsters(ps.gy, 1).is_empty():
				return false
	return _has_target(s, p, c, ig["do"])


## Avoid offering effects that would do nothing.
static func _has_target(s: DuelState, p: int, c, actions: Array) -> bool:
	var opp := s.players[s.opponent(p)]
	for a in actions:
		match a[0]:
			"destroy":
				if str(a[1]) == "any_pick":
					var n_cards: int = opp.monsters().size() + (1 if opp.field_spell != null else 0)
					for st in opp.spells:
						if st != null:
							n_cards += 1
					if n_cards == 0:
						return false
				elif str(a[1]) == "st_pick":
					if _all_st(s).is_empty():
						return false
				elif str(a[1]) == "opp_faceup_spell":
					var any_up := opp.field_spell != null and opp.field_spell.face_up
					for st3 in opp.spells:
						if st3 != null and st3.face_up and st3.is_spell():
							any_up = true
					if not any_up:
						return false
				elif str(a[1]) == "atk_above_self":
					if _stronger_than(s, c).is_empty():
						return false
				elif str(a[1]).begins_with("best") or str(a[1]) in ["atk_below_self", "weakest"]:
					if opp.monsters().is_empty() and not (a[1] == "best_any" and not opp.set_cards().is_empty()):
						return false
			"opp_half", "opp_zero", "destroy_half_damage":
				if opp.monsters().is_empty():
					return false
			"exile_opp":
				if opp.monsters().is_empty():
					return false
			"banish":
				if str(a[1]) == "field_mon":
					if opp.monsters().is_empty() and s.players[p].monsters().size() < 2:
						return false
				elif s._strongest_face_up(s.opponent(p)) == null and not (a[1] == "best_any" and (not opp.monsters().is_empty() or not opp.set_cards().is_empty())):
					return false
			"banish_own_gy_boost":
				if s._best_monsters(s.players[p].gy, 1).is_empty():
					return false
			"special":
				var ps := s.players[p]
				if ps.free_zone() == -1:
					return false
				var src: Array = ps.deck if a[1] == "deck" else (ps.hand if a[1] == "hand" else ps.gy)
				if _take(src, a[2], 1).is_empty():
					return false
			"search":
				if _take(s.players[p].deck, a[1], 1).is_empty():
					return false
			"copy_level":
				if _level_sources(s, c, a[1]).is_empty():
					return false
			"rose_bind":
				var has_plant := false
				for g in s.players[p].gy:
					if g.is_monster() and str(g.data.get("race", "")) == "Plant":
						has_plant = true
				var has_def := false
				for m in opp.monsters():
					if not m.attack_pos:
						has_def = true
				if not has_plant or not has_def:
					return false
			"wedge_release":
				var any_wedge := false
				for m in opp.monsters():
					if m.wedge:
						any_wedge = true
				if not any_wedge:
					return false
	return true


## Every Spell and Trap on the field, either side, Set ones included.
static func _all_st(s: DuelState) -> Array:
	var out := []
	for q in 2:
		for st in s.players[q].spells:
			if st != null and not st.is_monster():
				out.append(st)
		if s.players[q].field_spell != null:
			out.append(s.players[q].field_spell)
	return out


## Face-up monsters on the field with more ATK than this one (Freed the Brave Wanderer).
static func _stronger_than(s: DuelState, c) -> Array:
	var out := []
	for q in 2:
		for m in s.players[q].monsters():
			if m != c and m.face_up and s.atk_of(m, false) > s.atk_of(c, false):
				out.append(m)
	return out


## Other face-up monsters on the field that fit a filter and have a Level (Copy Plant).
static func _level_sources(s: DuelState, c, f: Dictionary) -> Array:
	var out := []
	for q in 2:
		for m in s.players[q].monsters():
			if m != c and m.face_up and m.frame() != "xyz" and m.level() > 0 and CardEffects.matches(m.data, f):
				out.append(m)
	return out


static func ignite(s: DuelState, p: int, c) -> Array:
	if not can_ignite(s, p, c):
		return []
	if fx(c).has("union"):
		return _union(s, p, c)
	var ig := ignite_spec(c)
	var ps := s.players[p]
	var events := [_ev(p, c, Loc.t("%s activates its effect") % c.cname())]
	c.ignite_turn = s.turn
	if ig.get("name_once", false):
		ps.once_names[c.cname()] = s.turn
	var ctx := {"_ign": true}
	match str(ig.get("cost", "none")):
		"counter":
			c.counter -= 1
			events.append(_ev(p, c, Loc.t("%s removes its Spell Counter") % c.cname()))
		"banish_gy_light2":
			var lights: Array = ps.gy.filter(func(g): return g.is_monster() and str(g.data.get("attribute", "")) == "LIGHT")
			lights.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
			for g in s.choose(p, Loc.t("%s: banish 2 LIGHT monsters from your Graveyard") % c.cname(), lights, 2, lights.slice(0, 2), false, c):
				events.append_array(s._banish(g))
		"discard", "discard_monster", "discard_family":
			var pick = null
			var can: Array = []
			for h in ps.hand:
				if ig["cost"] == "discard_monster" and not h.is_monster():
					continue
				if ig["cost"] == "discard_family" and not h.cname().contains(str(ig.get("family", ""))):
					continue
				can.append(h)
				if pick == null or s._card_value(h) < s._card_value(pick) or (ig["cost"] == "discard_monster" and h.atk() > pick.atk()):
					pick = h
			pick = s.pick1(p, Loc.t("%s: discard 1 card as the cost") % c.cname(), can, pick, c)
			ps.hand.erase(pick)
			s._to_gy(ps, pick)
			ctx["discarded"] = pick
			events.append({"type": "discard", "player": p, "card": pick})
		"tribute_any":
			# "Tribute 1 monster": any of yours, this one included. The weakest other one by default.
			var anyp = null
			var anyc: Array = ps.monsters()
			for m in anyc:
				if m != c and (anyp == null or s.atk_of(m, false) < s.atk_of(anyp, false)):
					anyp = m
			if anyp == null:
				anyp = c
			anyp = s.pick1(p, Loc.t("%s: Tribute 1 monster") % c.cname(), anyc, anyp, c)
			ps.field[ps.field.find(anyp)] = null
			s._to_gy(ps, anyp)
			events.append({"type": "tribute", "player": p, "card": anyp})
			events.append_array(EffectRunner.trigger(s, anyp, "tributed"))
			events.append_array(s._monster_left(anyp))
		"tribute_self":
			ps.field[ps.field.find(c)] = null
			s._to_gy(ps, c)
			events.append({"type": "tribute", "player": p, "card": c})
			events.append_array(EffectRunner.trigger(s, c, "tributed"))
		"tribute_other", "tribute_plant":
			var pick = null
			var can: Array = []
			for m in ps.monsters():
				if m == c:
					continue
				if ig["cost"] == "tribute_plant" and str(m.data.get("race", "")) != "Plant":
					continue
				can.append(m)
				if pick == null or s.atk_of(m, false) < s.atk_of(pick, false):
					pick = m
			if pick == null and ig["cost"] == "tribute_plant":
				pick = c
			elif pick != null:
				if ig["cost"] == "tribute_plant" and str(c.data.get("race", "")) == "Plant":
					can.append(c)
				pick = s.pick1(p, Loc.t("%s: Tribute 1 monster as the cost") % c.cname(), can, pick, c)
			ps.field[ps.field.find(pick)] = null
			s._to_gy(ps, pick)
			events.append({"type": "tribute", "player": p, "card": pick})
			events.append_array(EffectRunner.trigger(s, pick, "tributed"))
		"banish_gy_dark":
			events.append_array(s._banish(_gy_attr(s, p, "DARK", c)))
		"banish_gy_monster":
			var gm: Array = s._best_monsters(ps.gy, 99)
			events.append_array(s._banish(s.pick1(p, Loc.t("%s: banish 1 monster from your Graveyard") % c.cname(), gm, gm[gm.size() - 1], c)))
		"detach", "detach2":
			var n := 2 if ig["cost"] == "detach2" else 1
			for i in n:
				var o = s.pick1(p, Loc.t("%s: detach 1 material") % c.cname(), c.overlays, c.overlays.back(), c)
				c.overlays.erase(o)
				s._to_gy(ps, o)
			events.append({"type": "detach", "player": p, "card": c})
	events.append_array(run_list(s, p, c, ig["do"], ctx))
	return events


# ------------------------------------------------------------------ actions

static func run_list(s: DuelState, p: int, c, actions: Array, ctx: Dictionary) -> Array:
	if s.defer_fx and not ctx.get("_now", false):
		# On the duel screen the effect activates now and resolves on the chain (see fx_to_chain).
		s.pending_fx.append({"player": p, "card": c, "actions": actions, "ctx": ctx})
		return []
	var events := []
	var was_by := s.effect_by
	s.effect_by = p
	for a in actions:
		if s.is_over():
			break
		if str(a[0]) == "need":
			# ["need", cond]: the rest only happens while this holds ("if you control a ...").
			if not _cond(s, p, str(a[1])):
				break
			continue
		events.append_array(run(s, p, c, a, ctx))
	s.effect_by = was_by
	return events


## One of the opponent's monsters: the effect's controller picks, the rules default to the strongest.
static func _best_opp(s: DuelState, p: int, filter := "", c = null, prompt := "Choose 1 of your opponent's monsters") -> Variant:
	var best = null
	var cands: Array = []
	for m in s.players[s.opponent(p)].monsters():
		if filter == "atk_pos" and not (m.face_up and m.attack_pos):
			continue
		cands.append(m)
		if best == null or s.atk_of(m, false) > s.atk_of(best, false):
			best = m
	if c != null and best != null:
		return s.pick1(p, "%s: %s" % [c.cname(), prompt], cands, best, c)
	return best


## Like _take, but the player picks among everything that matches.
static func _pick(s: DuelState, p: int, c, prompt: String, arr: Array, f: Dictionary, n: int) -> Array:
	var auto := _take(arr, f, n)
	if auto.is_empty():
		return auto
	var all: Array = []
	for x in arr:
		if CardEffects.matches(x.data, f) and not CardData.is_extra(x.id):
			all.append(x)
	return s.choose(p, "%s: %s" % [c.cname(), prompt], all, auto.size(), auto, false, c)


static func _take(arr: Array, f: Dictionary, n: int) -> Array:
	var out := []
	for x in arr:
		if out.size() >= n:
			break
		if CardEffects.matches(x.data, f) and not CardData.is_extra(x.id):
			out.append(x)
	return out


## Debug/test stats: how often each card's effect ran.
static var fired := {}


static func run(s: DuelState, p: int, c, a: Array, ctx: Dictionary) -> Array:
	fired[c.cname()] = int(fired.get(c.cname(), 0)) + 1
	var ps := s.players[p]
	var opp_i := s.opponent(p)
	var opp := s.players[opp_i]
	var name: String = c.cname()
	var events := []
	match a[0]:
		"rda_end":
			# Red Dragon Archfiend, your End Phase: your other monsters that did not attack are destroyed.
			var idle := []
			for m in ps.monsters():
				if m != c and m.attacked_turn != s.turn:
					idle.append(m)
			if not idle.is_empty():
				events.append(_ev(p, c, Loc.t("%s destroys your monsters that did not attack") % name))
				for m in idle:
					events.append_array(s._destroy(m))
		"black_rose":
			# Black Rose Dragon, Synchro Summoned: you can destroy all cards on the field.
			var mine_n := ps.monsters().size() + ps.set_cards().size()
			var their_n := opp.monsters().size() + opp.set_cards().size()
			var yes := s.choose_option(p, Loc.t("%s: destroy all cards on the field?") % name, ["Destroy everything", "Leave the field as it is"], 0 if their_n > mine_n else 1, c) == 0
			if yes:
				events.append(_ev(p, c, Loc.t("%s destroys every card on the field") % name))
				for q in 2:
					for m in s.players[q].monsters():
						events.append_array(s._destroy(m))
					for st in s.players[q].spells.duplicate():
						if st != null:
							events.append_array(s._destroy_st(st))
					if s.players[q].field_spell != null:
						events.append_array(s._destroy_st(s.players[q].field_spell))
		"rose_bind":
			# Black Rose Dragon: banish a Plant from your Graveyard; one of their Defense Position
			# monsters is turned to face-up Attack Position with 0 ATK until the end of the turn.
			var plants := []
			for g in ps.gy:
				if g.is_monster() and str(g.data.get("race", "")) == "Plant":
					plants.append(g)
			var defs := []
			for m in opp.monsters():
				if not m.attack_pos:
					defs.append(m)
			if not plants.is_empty() and not defs.is_empty():
				plants.sort_custom(func(x, y): return x.atk() < y.atk())
				var cost: Array = s.choose(p, Loc.t("%s: banish 1 Plant from your Graveyard") % name, plants, 1, [plants[0]], false, c)
				events.append_array(s._banish(cost[0] if not cost.is_empty() else plants[0]))
				defs.sort_custom(func(x, y): return x.def() > y.def())
				var tg: Array = s.choose(p, Loc.t("%s: choose 1 Defense Position monster") % name, defs, 1, [defs[0]], false, c)
				var t = tg[0] if not tg.is_empty() else defs[0]
				t.face_up = true
				t.attack_pos = true
				t.zero_turn = s.turn
				events.append({"type": "position", "player": opp_i, "card": t, "zone": opp.field.find(t)})
				events.append(_ev(p, c, Loc.t("%s is forced into Attack Position with 0 ATK") % t.cname()))
		"wedge_release":
			# Blackwing Armor Master: remove the Wedge Counters; those monsters drop to 0 ATK and DEF this turn.
			for m in opp.monsters():
				if m.wedge:
					m.wedge = false
					m.zero_turn = s.turn
					m.def_mod_turn = s.turn
					m.def_mod_t = -m.def()
					events.append(_ev(p, c, Loc.t("%s drops to 0 ATK and DEF") % m.cname()))
		"declare_level":
			# Gagaga Magician: declare a Level from 1 to 8, until the end of this turn.
			var want := 4
			for m in ps.monsters():
				if m != c and m.face_up and m.frame() != "xyz" and m.level() >= 1 and m.level() <= 8:
					want = m.level()
			var labels := []
			for lv in range(1, 9):
				labels.append(Loc.t("Level %d") % lv)
			var got := s.choose_option(p, Loc.t("%s: declare a Level") % name, labels, want - 1, c)
			c.lv_set = clampi(got + 1, 1, 8)
			c.lv_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s becomes Level %d") % [name, c.lv_set]))
		"copy_level":
			# Copy Plant: its Level becomes another monster's, until the end of this turn.
			var srcs := _level_sources(s, c, a[1])
			if not srcs.is_empty():
				var pick: Array = _pick(s, p, c, Loc.t("%s: copy whose Level?") % name, srcs, {"monster": true}, 1)
				var from = pick[0] if not pick.is_empty() else srcs[0]
				c.lv_set = from.level()
				c.lv_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s becomes Level %d") % [name, c.lv_set]))
		"tenacious":
			# Captain Tenacious: bring back a Destiny HERO destroyed by battle since your last Standby Phase,
			# if this card was already face-up when it fell.
			var best = null
			for g in ps.gy:
				if g.cname().contains("Destiny HERO") and g.died_turn >= s.turn - 2 and g.died_turn >= 0 and c.summoned_turn <= g.died_turn and s.can_revive(g):
					if best == null or g.atk() > best.atk():
						best = g
			if best != null and ps.free_zone() != -1:
				ps.gy.erase(best)
				events.append(_ev(p, c, Loc.t("%s brings back %s") % [name, best.cname()]))
				events.append_array(s._special(p, best, "reborn"))
		"shark_drake":
			# Number 32: Shark Drake. The monster it just destroyed returns to their side with 1000 less ATK,
			# and Shark Drake attacks once more.
			var victim = ctx.get("victim")
			var attacking: bool = s.current == p and c.attacked_turn == s.turn   # it won a battle on its own turn: it was the attacker
			if victim != null and attacking and c.used_turn != s.turn and not c.overlays.is_empty() and opp.gy.has(victim) and opp.free_zone() != -1:
				c.used_turn = s.turn
				var mat = c.overlays.pop_back()
				s._to_gy(s.players[mat.owner], mat)
				events.append({"type": "detach", "player": p, "card": c, "material": mat})
				opp.gy.erase(victim)
				events.append(_ev(p, c, Loc.t("%s drags %s back for another round") % [name, victim.cname()]))
				events.append_array(s._special(opp_i, victim, "reborn", "atk"))
				victim.atk_mod -= 1000
				c.attack_count = maxi(0, c.attack_count - 1)
		"draw":
			events.append(_ev(p, c, Loc.t("%s: draw %d") % [name, a[1]]))
			events.append_array(s._draw(p, int(a[1])))
		"draw_if_alone":
			if ps.hand.is_empty() and ps.monsters().size() == 1 and ps.set_cards().is_empty():
				events.append(_ev(p, c, Loc.t("%s: draw %d") % [name, a[1]]))
				events.append_array(s._draw(p, int(a[1])))
		"draw_once":
			var once_key := "once_" + name.validate_node_name().replace(" ", "_").replace("-", "_").replace("'", "")
			if not ps.has_meta(once_key):
				ps.set_meta(once_key, true)
				events.append(_ev(p, c, Loc.t("%s: draw %d") % [name, a[1]]))
				events.append_array(s._draw(p, int(a[1])))
		"damage":
			events.append(_ev(p, c, Loc.t("%s deals %d damage") % [name, a[1]]))
			events.append_array(s._damage(opp_i, int(a[1])))
		"self_damage":
			events.append(_ev(p, c, Loc.t("%s: you take %d damage") % [name, a[1]]))
			events.append_array(s._damage(p, int(a[1])))
		"heal":
			ps.lp += int(a[1])
			events.append(_ev(p, c, Loc.t("%s: gain %d LP") % [name, a[1]]))
			events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": int(a[1])})
		"damage_victim_atk", "damage_victim_def", "damage_victim_level", "damage_if_victim_race":
			var v = ctx.get("victim")
			if v != null:
				var amt := 0
				match a[0]:
					"damage_victim_atk":
						amt = v.atk()
					"damage_victim_def":
						amt = v.def()
					"damage_victim_level":
						# "...and sends it to the GY: damage equal to its original Level x 100".
						if s.players[0].gy.has(v) or s.players[1].gy.has(v):
							amt = int(v.data.get("level", 0)) * int(a[1])
					"damage_if_victim_race":
						amt = int(a[2]) if str(v.data.get("race", "")) == a[1] else 0
				if amt > 0:
					events.append(_ev(p, c, Loc.t("%s burns %d!") % [name, amt]))
					events.append_array(s._damage(opp_i, amt))
		"gain_victim_atk":
			var v = ctx.get("victim")
			if v != null and v.atk() > 0:
				c.atk_mod += v.atk()
				events.append(_ev(p, c, Loc.t("%s gains %d ATK") % [name, v.atk()]))
		"search":
			var got := _pick(s, p, c, "add 1 card from your Deck to your hand", ps.deck, a[1], 1)
			if got.is_empty():
				return events
			var d = got[0]
			ps.deck.erase(d)
			ps.hand.append(d)
			ctx["searched"] = d
			s._shuffle(ps.deck)
			events.append(_ev(p, c, Loc.t("%s adds %s to the hand") % [name, d.cname()]))
			events.append({"type": "search", "player": p, "card": d, "deck": ps.deck.size()})
		"gy_to_hand":
			for d in _pick(s, p, c, "add from your Graveyard to your hand", ps.gy, a[1], int(a[2])):
				ps.gy.erase(d)
				ps.hand.append(d)
				events.append(_ev(p, c, Loc.t("%s returns %s to the hand") % [name, d.cname()]))
				events.append({"type": "gy_to_hand", "player": p, "card": d, "deck": ps.deck.size()})
		"special":
			var src: Array = ps.deck if a[1] == "deck" else (ps.hand if a[1] == "hand" else ps.gy)
			var n: int = int(a[4]) if a.size() > 4 else 1
			var pool: Array = src.filter(func(x): return s.can_revive(x)) if a[1] == "gy" else src.filter(func(x): return not CardEffects.of(x.cname()).get("no_special", false))
			var flt: Dictionary = a[2]
			if a[1] == "gy":
				flt = flt.duplicate()
				flt["zone"] = "gy"
			for d in _pick(s, p, c, Loc.t("Special Summon from your %s") % ("Deck" if a[1] == "deck" else ("hand" if a[1] == "hand" else "Graveyard")), pool, flt, n):
				if ps.free_zone() == -1:
					break
				src.erase(d)
				if a[1] == "deck":
					s._shuffle(ps.deck)
				events.append(_ev(p, c, Loc.t("%s calls %s") % [name, d.cname()]))
				var ev := s._special(p, d, "reborn" if a[1] == "gy" else "effect", "def" if a.size() > 3 and a[3] == "def" else ("atk" if a.size() > 3 and a[3] == "atk" else ""))
				events.append_array(ev)
				if a.size() > 5 and str(a[5]) == "negated":
					d.neg_perm = true   # "...but its effects are negated"
					d.negated = true
				else:
					events.append_array(on_summon(s, p, d, "special"))
		"revive_self", "revive_self_discard2", "pay_revive":
			if not ps.gy.has(c) or ps.free_zone() == -1:
				return events
			if c.get_meta("revived", false):
				return events
			if a[0] == "revive_self_discard2":
				if ps.hand.size() < 2:
					return events
				for h in s.choose(p, Loc.t("%s: discard 2 cards") % name, ps.hand, 2, ps.hand.slice(0, 2), false, c):
					ps.hand.erase(h)
					s._to_gy(ps, h)
					events.append({"type": "discard", "player": p, "card": h})
			if a[0] == "pay_revive":
				if ps.lp <= int(a[1]):
					return events
				ps.lp -= int(a[1])
				events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -int(a[1])})
			c.set_meta("revived", true)
			ps.gy.erase(c)
			events.append(_ev(p, c, Loc.t("%s comes back!") % name))
			events.append_array(s._special(p, c, "reborn", "def" if (a.size() < 2 or a[0] != "revive_self" or a[1] == "def") else ""))
		"destroy":
			events.append_array(_destroy_action(s, p, c, str(a[1]), ctx))
		"banish":
			# ["banish", "best"]: the opponent's strongest face-up monster. "best_any": or a set card.
			var t = s._strongest_face_up(opp_i)
			var bcan: Array = opp.monsters().filter(func(m): return m.face_up)
			if str(a[1]) == "field_mon":
				# "Target 1 monster on the field": either side, face-down ones too.
				bcan = opp.monsters() + ps.monsters().filter(func(m): return m != c)
				if t == null:
					t = _best_opp(s, p)
				if t == null and not s.manual[p]:
					return events          # the AI does not banish its own monster
				if t == null and not bcan.is_empty():
					t = bcan[0]
			if str(a[1]) == "best_any":
				bcan = opp.monsters() + opp.set_cards()
				if t == null:
					t = _best_opp(s, p)
				if t == null and not opp.set_cards().is_empty():
					t = opp.set_cards()[0]
			if t != null:
				t = s.pick1(p, Loc.t("%s: banish 1 card") % name, bcan, t, c)
			if t != null:
				events.append(_ev(p, c, Loc.t("%s banishes %s") % [name, t.cname() if t.face_up else "a set card"]))
				ctx["banished"] = t
				events.append_array(s._banish(t))
		"banish_opp_gy":
			var picks: Array = s._best_monsters(opp.gy, int(a[1]))
			if not picks.is_empty():
				picks = s.choose(p, Loc.t("%s: banish from their Graveyard") % name, s._best_monsters(opp.gy, 99), picks.size(), picks, false, c)
				events.append(_ev(p, c, Loc.t("%s banishes from the Graveyard") % name))
			for g in picks:
				events.append_array(s._banish(g))
		"banish_own_gy_boost":
			# Bazoo: banish up to n monsters from your GY, gain ATK for each until the end of the turn.
			var picks: Array = s._best_monsters(ps.gy, 99)
			picks.reverse()
			var own_all: Array = picks.duplicate()
			picks = picks.slice(0, int(a[1]))
			if picks.size() > 1 and s.manual[p]:
				# "up to 3": how many is the player's call.
				var labels := []
				for i in picks.size():
					labels.append(str(i + 1))
				picks = picks.slice(0, s.choose_option(p, Loc.t("%s: banish how many monsters?") % name, labels, picks.size() - 1, c) + 1)
			if not picks.is_empty():
				picks = s.choose(p, Loc.t("%s: banish %d from your Graveyard") % [name, picks.size()], own_all, picks.size(), picks, false, c)
			for g in picks:
				events.append_array(s._banish(g))
			if not picks.is_empty():
				# "...until the end of your opponent's turn".
				c.tmp_atk = (c.tmp_atk if c.tmp_until >= s.turn else 0) + int(a[2]) * picks.size()
				c.tmp_until = s.turn + 1
				events.append(_ev(p, c, Loc.t("%s gains %d ATK until the end of your opponent's turn") % [name, int(a[2]) * picks.size()]))
		"banish_killer_and_self":
			var k = ctx.get("killer")
			events.append(_ev(p, c, Loc.t("%s drags its attacker out of the duel") % name))
			if k != null and s.players[k.owner].field.has(k):
				events.append_array(s._banish(k))
			events.append_array(s._banish(c))
		"banish_victim":
			var v = ctx.get("victim")
			if v != null and s.players[v.owner].gy.has(v):
				events.append(_ev(p, c, Loc.t("%s banishes %s") % [name, v.cname()]))
				events.append_array(s._banish(v))
		"damage_if_banished_dark":
			var b = ctx.get("banished")
			if b != null and b.is_monster() and str(b.data.get("attribute", "")) == "DARK":
				events.append_array(s._damage(opp_i, int(a[1])))
		"destroy_half_damage":
			var t = _best_opp(s, p, "", c, "destroy 1 monster")
			if t != null:
				var dmg: int = s.atk_of(t, false) / 2
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, t.cname()]))
				events.append_array(s._destroy(t))
				events.append_array(s._damage(opp_i, dmg))
		"destroy_killer":
			var k = ctx.get("killer")
			if k != null and s.players[k.owner].field.has(k):
				events.append(_ev(p, c, Loc.t("%s takes %s down with it") % [name, k.cname()]))
				events.append_array(s._destroy(k))
		"dice_destroy":
			var roll := s._rng.randi_range(1, 6)
			if roll == 1 or roll == 6:
				events.append(_ev(p, c, Loc.t("%s rolled a %d... miss!") % [name, roll]))
			else:
				events.append(_ev(p, c, Loc.t("%s rolled a %d!") % [name, roll]))
				events.append_array(_destroy_action(s, p, c, "best_any", ctx))
		"self_atk":
			c.atk_mod_turn = s.turn
			c.atk_mod_t = int(a[1])
			events.append(_ev(p, c, Loc.t("%s gains %d ATK this turn") % [name, a[1]]))
		"no_battle_damage":
			ps.no_damage_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s: no battle damage this turn") % name))
		"self_atk_zero":
			c.atk_mod = -c.atk()   # "make this card's ATK 0": it stays 0
		"perm_atk":
			c.atk_mod += int(a[1])
			events.append(_ev(p, c, Loc.t("%s gains %d ATK") % [name, a[1]]))
		"counter_self":
			# "Place 1 Spell Counter on it (max. 1)".
			if c.counter < int(a[1]):
				c.counter += 1
				events.append(_ev(p, c, Loc.t("%s gets a Spell Counter") % name))
		"exile_opp":
			# Destiny HERO - Doom Lord: banish 1 of their monsters until your 2nd Standby Phase after this.
			var gone = _best_opp(s, p, "", c, Loc.t("banish 1 monster until your 2nd Standby Phase from now"))
			if gone != null and c.attack_pos and ps.field.has(c):
				var was_atk: bool = gone.attack_pos or not gone.face_up
				var is_tok: bool = gone.is_token()
				events.append(_ev(p, c, Loc.t("%s sends %s away") % [name, gone.cname() if gone.face_up else Loc.t("a Set monster")]))
				events.append_array(s._banish(gone))
				if not is_tok and opp.banished.has(gone):
					ps.exiles.append({"card": gone, "to": opp_i, "left": 2, "atk_pos": was_atk})
			ps.no_attack_turn = s.turn
		"opp_may_revive":
			# Gilasaurus: your opponent can Special Summon 1 monster from their Graveyard.
			var theirs: Array = opp.gy.filter(func(g): return g.is_monster() and s.can_revive(g))
			if not theirs.is_empty() and opp.free_zone() != -1:
				var top = theirs[0]
				for g in theirs:
					if g.atk() > top.atk():
						top = g
				var got: Array = s.choose(opp_i, Loc.t("%s: you may Special Summon 1 monster from your Graveyard") % name, theirs, 1, [top], true, c)
				if not got.is_empty():
					opp.gy.erase(got[0])
					events.append(_ev(opp_i, c, Loc.t("%s lets %s come back") % [name, got[0].cname()]))
					events.append_array(s._special(opp_i, got[0], "reborn"))
					events.append_array(on_summon(s, opp_i, got[0], "special"))
		"pay_revive_standby":
			# Revival Jam: pay LP now, it returns in Defense at your next Standby Phase.
			if ps.gy.has(c) and ps.lp > int(a[1]):
				var yes := ps.lp > int(a[1]) + 2000
				if s.manual[p]:
					yes = s.choose_option(p, Loc.t("%s: pay %d LP to bring it back at your next Standby Phase?") % [name, int(a[1])], [Loc.t("Yes"), Loc.t("No")], 0, c) == 0
				if yes:
					ps.lp -= int(a[1])
					events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -int(a[1])})
					c.back_pos = "def"
					events.append(_ev(p, c, Loc.t("%s will be back at your next Standby Phase") % name))
		"token_if_killed":
			# Insect Queen, End Phase: it destroyed a monster by battle this turn.
			if c.killed_turn == s.turn and c.flag_turn != s.turn and ps.free_zone() != -1:
				c.flag_turn = s.turn
				CardData.TOKENS[int(a[2])] = {"name": str(a[1]), "frame": "token", "atk": int(a[3]), "def": int(a[4]), "level": int(a[5]),
						"attribute": str(a[6]), "race": str(a[7]), "desc": Loc.t("This card can be used as a \"%s\".") % str(a[1])}
				events.append(_ev(p, c, Loc.t("%s lays an egg: %s") % [name, str(a[1])]))
				events.append_array(s._special(p, s._make(int(a[2]), p), "effect", "atk"))
		"max_shrink":
			# Max Warrior destroyed a monster by battle: Level 2, original ATK and DEF halved,
			# until your next Standby Phase.
			if not c.shrunk and s.players[p].field.has(c):
				c.shrunk = true
				c.lv_set = 2
				c.lv_turn = -1
				c.atk_mod -= c.atk() / 2
				c.def_mod -= c.def() / 2
				events.append(_ev(p, c, Loc.t("%s is spent: Level 2 with half its ATK and DEF until your next Standby Phase") % name))
		"self_atk_turn":
			if c.atk_mod_turn != s.turn:
				c.atk_mod_turn = s.turn
				c.atk_mod_t = 0
			c.atk_mod_t += int(a[1])
			events.append(_ev(p, c, Loc.t("%s: %d ATK until the end of this turn") % [name, int(a[1])]))
		"ritual_boost":
			# Cyber Angel Idaten, Tributed: every Ritual Monster you control gains ATK and DEF.
			var any_r := false
			for m in ps.monsters():
				if m.face_up and m.frame() == "ritual":
					m.atk_mod += int(a[1])
					m.def_mod += int(a[1])
					any_r = true
			if any_r:
				events.append(_ev(p, c, Loc.t("%s: your Ritual Monsters gain %d ATK and DEF") % [name, a[1]]))
		"add_ritual_spell":
			# Cyber Angel Idaten, Ritual Summoned: 1 Ritual Spell from your Deck or Graveyard to your hand.
			var rs: Array = []
			for x in ps.deck + ps.gy:
				if not x.is_monster() and str(SpellRules.spec(x).get("k", "")) == "ritual":
					rs.append(x)
			if not rs.is_empty():
				var gotr = s.pick1(p, Loc.t("%s: add 1 Ritual Spell to your hand") % name, rs, rs[0], c)
				ps.deck.erase(gotr)
				ps.gy.erase(gotr)
				ps.hand.append(gotr)
				events.append(_ev(p, c, Loc.t("%s adds %s to the hand") % [name, gotr.cname()]))
				events.append({"type": "to_hand", "player": p, "card": gotr})
		"recover_ritual":
			# Cyber Angel Dakini, your End Phase: 1 Ritual Monster or 1 "Machine Angel Ritual" from your Graveyard.
			var back_r: Array = []
			for x in ps.gy:
				if (x.is_monster() and x.frame() == "ritual") or x.cname() == "Machine Angel Ritual":
					back_r.append(x)
			if not back_r.is_empty():
				var best_r = back_r[0]
				for x in back_r:
					if x.is_monster() and (not best_r.is_monster() or x.atk() > best_r.atk()):
						best_r = x
				var gotb = s.pick1(p, Loc.t("%s: add 1 Ritual Monster or Machine Angel Ritual from your Graveyard to your hand") % name, back_r, best_r, c)
				ps.gy.erase(gotb)
				ps.hand.append(gotb)
				events.append(_ev(p, c, Loc.t("%s returns %s to the hand") % [name, gotb.cname()]))
				events.append({"type": "to_hand", "player": p, "card": gotb})
		"opp_sends":
			# Cyber Angel Dakini, Ritual Summoned: the opponent sends 1 monster they control to the
			# Graveyard, and they choose which. (Sent, not destroyed.)
			var theirs: Array = opp.monsters()
			if not theirs.is_empty():
				var weak = theirs[0]
				for x in theirs:
					if s.atk_of(x, false) < s.atk_of(weak, false):
						weak = x
				var gone = s.pick1(opp_i, Loc.t("%s: send 1 of your monsters to the Graveyard") % name, theirs, weak, c)
				var zg := opp.field.find(gone)
				opp.field[zg] = null
				s._to_gy(opp, gone)
				events.append(_ev(p, c, Loc.t("%s: %s is sent to the Graveyard") % [name, gone.cname()]))
				events.append({"type": "destroy", "player": opp_i, "card": gone, "zone": zg})
				events.append_array(s._monster_left(gone))
				events.append_array(trigger(s, gone, "gy"))
		"best_own_atk":
			var best = null
			for m in ps.monsters():
				if best == null or s.atk_of(m, false) > s.atk_of(best, false):
					best = m
			if best != null:
				best.atk_mod_turn = s.turn
				best.atk_mod_t = int(a[1])
				events.append(_ev(p, best, Loc.t("%s gains %d ATK") % [best.cname(), a[1]]))
		"opp_half", "opp_zero":
			var t = _best_opp(s, p, "", c, "choose the monster to weaken")
			if t != null:
				if a[0] == "opp_half":
					t.half_turn = s.turn
				else:
					t.zero_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s's ATK is %s this turn") % [t.cname(), "halved" if a[0] == "opp_half" else "0"]))
		"opp_change_pos":
			# "Target 1 monster your opponent controls; change that target's battle position."
			var all_m: Array = opp.monsters()
			if not all_m.is_empty():
				var strongest = all_m[0]
				for m in all_m:
					if m.attack_pos and (not strongest.attack_pos or s.atk_of(m, false) > s.atk_of(strongest, false)):
						strongest = m
				var t2 = s.pick1(p, Loc.t("%s: change the battle position of 1 monster") % name, all_m, strongest, c)
				if t2.attack_pos:
					t2.attack_pos = false
				else:
					t2.attack_pos = true
					t2.face_up = true
				events.append(_ev(p, c, Loc.t("%s changes position") % t2.cname()))
				events.append({"type": "position", "player": opp_i, "card": t2, "zone": opp.field.find(t2)})
		"opp_half_perm":
			# Blackwing - Gale: a face-up monster's ATK and DEF become half of what they are now.
			var t3 = _best_opp(s, p, "", c, "halve 1 monster's ATK and DEF")
			if t3 != null and t3.face_up:
				t3.atk_mod -= s.atk_of(t3, false) / 2
				t3.def_mod -= s.def_of(t3) / 2
				events.append(_ev(p, c, Loc.t("%s's ATK and DEF are halved") % t3.cname()))
		"negate_target":
			# Black Ray Lancer: a face-up monster's effects are negated until the End Phase.
			var ups: Array = []
			for q in 2:
				for m in s.players[q].monsters():
					if m.face_up and m != c:
						ups.append(m)
			if not ups.is_empty():
				var auto = s._strongest_face_up(opp_i)
				var t4 = s.pick1(p, Loc.t("%s: negate 1 monster's effects") % name, ups, auto if auto != null else ups[0], c)
				t4.negated_turn = s.turn
				t4.negated = true
				events.append(_ev(p, c, Loc.t("%s's effects are negated until the End Phase") % t4.cname()))
		"self_level":
			# Hammer Shark: this card's Level goes down by 1.
			c.lv_set = maxi(1, c.level() + int(a[1]))
			c.lv_turn = -1
			events.append(_ev(p, c, Loc.t("%s becomes Level %d") % [name, c.lv_set]))
		"level_all":
			# Double Shark / Spear Shark: every monster you control that fits, at that Level, moves 1 Level.
			for m in ps.monsters():
				if m.face_up and m.frame() != "xyz" and str(m.data.get("race", "")) == str(a[1]) and m.level() == int(a[2]):
					m.lv_set = m.level() + int(a[3])
					m.lv_turn = -1
					events.append(_ev(p, c, Loc.t("%s becomes Level %d") % [m.cname(), m.lv_set]))
		"no_effect_damage":
			ps.no_effect_damage_turn = s.turn
			events.append(_ev(p, c, "No effect damage this turn"))
		"lock_name":
			# "...but you cannot activate cards, or the effects of cards, with that name for the rest of this turn."
			var last = ctx.get("searched")
			if last != null:
				ps.name_lock[last.cname()] = s.turn
		"opp_flip", "opp_to_def":
			var t = _best_opp(s, p, "atk_pos", c, "switch 1 monster to Defense")
			if t != null:
				t.attack_pos = false
				events.append(_ev(p, c, Loc.t("%s switches to Defense") % t.cname()))
				events.append({"type": "position", "player": opp_i, "card": t, "zone": opp.field.find(t)})
		"to_def":
			c.attack_pos = false
			events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
		"self_switch":
			# "Once per turn: You can change the battle position of this card" (Skull Kraken).
			if ps.field.has(c) and c.face_up:
				c.attack_pos = not c.attack_pos
				events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
		"back_next_standby":
			# "During your next Standby Phase ...: Special Summon it from your GY" (Gernia).
			if ps.gy.has(c):
				c.back_pos = str(a[1]) if a.size() > 1 else "any"
				events.append(_ev(p, c, Loc.t("%s will be back at your next Standby Phase") % name))
		"no_damage":
			ps.no_damage_turn = s.turn
			events.append(_ev(p, c, "No damage this turn"))
		"no_attack_turn":
			c.attack_count_turn = s.turn
			c.attack_count = 99
		"opp_discard":
			if not opp.hand.is_empty():
				var h = opp.hand[s._rng.randi() % opp.hand.size()]
				opp.hand.erase(h)
				s._to_gy(opp, h)
				events.append(_ev(p, c, Loc.t("%s makes the opponent discard") % name))
				events.append({"type": "discard", "player": opp_i, "card": h})
		"opp_mill":
			for i in int(a[1]) if a.size() > 1 else 1:
				if not opp.deck.is_empty():
					var d = opp.deck.pop_back()
					s._to_gy(opp, d)
					events.append(_ev(p, c, Loc.t("%s sends %s to the GY") % [name, d.cname()]))
					events.append({"type": "mill", "player": opp_i, "card": d, "deck": opp.deck.size()})
		"opp_redraw":
			var n := opp.hand.size()
			for h in opp.hand:
				opp.deck.append(h)
			opp.hand.clear()
			s._shuffle(opp.deck)
			events.append(_ev(p, c, Loc.t("%s: the opponent redraws their hand") % name))
			events.append({"type": "redraw", "player": opp_i, "deck": opp.deck.size()})
			events.append_array(s._draw(opp_i, n))
		"top_spell_draw":
			if not ps.deck.is_empty() and ps.deck.back().is_spell():
				events.append(_ev(p, c, Loc.t("%s finds a Spell!") % name))
				events.append_array(s._draw(p, 1))
			else:
				events.append(_ev(p, c, Loc.t("%s: no Spell on top") % name))
		"junk_warrior":
			var sum := 0
			for m in ps.monsters():
				if m != c and m.level() <= 2:
					sum += s.atk_of(m, false)
			for m in ctx.get("materials", []):
				if m.level() <= 2:
					sum += m.atk()
			if sum > 0:
				c.atk_mod += sum
				events.append(_ev(p, c, Loc.t("Junk Warrior gains %d ATK") % sum))
		"all_dragons_attack":
			# Dragon Piper: destroy every face-up "Dragon Capture Jar"; only if one was destroyed do
			# the Dragons turn to Attack Position.
			var jars := 0
			for q0 in 2:
				for st in s.players[q0].spells.duplicate():
					if st != null and st.face_up and st.cname() == "Dragon Capture Jar":
						events.append_array(s._destroy_st(st))
						jars += 1
			if jars == 0:
				return events
			for q in 2:
				for m in s.players[q].monsters():
					if m.face_up and not m.attack_pos and str(m.data.get("race", "")) == "Dragon":
						m.attack_pos = true
						events.append({"type": "position", "player": q, "card": m, "zone": s.players[q].field.find(m)})
		"level_up", "level_up_if_killed":
			if a[0] == "level_up_if_killed" and c.killed_turn != s.turn:
				return events
			var target := str(a[1])
			for src in [ps.hand, ps.deck]:
				for d in src:
					if d.cname() == target:
						var zone := ps.field.find(c)
						if zone == -1:
							return events
						ps.field[zone] = null
						s._to_gy(ps, c)
						events.append({"type": "tribute", "player": p, "card": c})
						events.append_array(EffectRunner.trigger(s, c, "tributed"))
						src.erase(d)
						events.append(_ev(p, c, Loc.t("%s levels up!") % name))
						events.append_array(s._special(p, d, "effect"))
						return events
	return events


static func _destroy_action(s: DuelState, p: int, c, what: String, ctx: Dictionary) -> Array:
	var opp_i := s.opponent(p)
	var opp := s.players[opp_i]
	var events := []
	var targets := []
	match what:
		"best":
			var t = _best_opp(s, p, "", c, "destroy 1 monster")
			if t != null:
				targets.append(t)
		"best_atk_pos":
			var t = _best_opp(s, p, "atk_pos", c, "destroy 1 Attack Position monster")
			if t != null:
				targets.append(t)
		"weakest":
			var w = null
			for m in opp.monsters():
				if w == null or s.atk_of(m, false) < s.atk_of(w, false):
					w = m
			if w != null:
				targets.append(w)
		"atk_below_self", "atk_below_discard", "all_atk_below_discard":
			var limit: int = s.atk_of(c, false) if what == "atk_below_self" else (ctx["discarded"].atk() if ctx.has("discarded") else 0)
			var best = null
			var low: Array = []
			for m in opp.monsters():
				var v: int = m.atk() if what == "atk_below_self" else s.atk_of(m, false)
				var ok := v < limit if what == "atk_below_self" else v <= limit
				if ok:
					if what == "all_atk_below_discard":
						targets.append(m)
					else:
						low.append(m)
						if best == null or s.atk_of(m, false) > s.atk_of(best, false):
							best = m
			if best != null:
				targets.append(s.pick1(p, Loc.t("%s: destroy 1 monster") % c.cname(), low, best, c))
		"best_any":
			var t = _best_opp(s, p)
			var any: Array = opp.monsters() + opp.set_cards()
			if not any.is_empty():
				var got = s.pick1(p, Loc.t("%s: destroy 1 card") % c.cname(), any, t if t != null else opp.set_cards()[0], c)
				if opp.field.has(got):
					targets.append(got)
				else:
					events.append(_ev(p, c, Loc.t("%s destroys a set card") % c.cname()))
					events.append_array(s._destroy_st(got))
					return events
		"opp_faceup_spell":
			# "You can target 1 face-up Spell your opponent controls; destroy that target" (Skull Kraken).
			var ups: Array = []
			for st2 in opp.spells:
				if st2 != null and st2.face_up and st2.is_spell():
					ups.append(st2)
			if opp.field_spell != null and opp.field_spell.face_up:
				ups.append(opp.field_spell)
			if ups.is_empty():
				return events
			var got6: Array = s.choose(p, Loc.t("%s: destroy 1 face-up Spell?") % c.cname(), ups, 1, [ups[0]], true, c)
			if got6.is_empty():
				return events
			events.append(_ev(p, c, Loc.t("%s destroys %s") % [c.cname(), got6[0].cname()]))
			events.append_array(s._destroy_st(got6[0]))
			return events
		"st_pick":
			# "Target 1 Spell/Trap on the field; destroy that target" (Breaker the Magical Warrior).
			var every: Array = _all_st(s)
			var theirs4: Array = every.filter(func(x): return x.owner == opp_i)
			if not every.is_empty():
				var got4 = s.pick1(p, Loc.t("%s: destroy 1 Spell or Trap") % c.cname(), every, theirs4[0] if not theirs4.is_empty() else every[0], c)
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [c.cname(), got4.cname() if got4.face_up else Loc.t("a Set card")]))
				events.append_array(s._destroy_st(got4))
			return events
		"atk_above_self":
			# Freed the Brave Wanderer: 1 face-up monster on the field with more ATK than this card.
			var big: Array = _stronger_than(s, c)
			var theirs5: Array = big.filter(func(x): return opp.field.has(x))
			if not big.is_empty() and s.players[p].field.has(c) and c.face_up:
				var top5 = theirs5[0] if not theirs5.is_empty() else big[0]
				for m in theirs5:
					if s.atk_of(m, false) > s.atk_of(top5, false):
						top5 = m
				targets.append(s.pick1(p, Loc.t("%s: destroy 1 monster with more ATK") % c.cname(), big, top5, c))
		"faceup_st_pick":
			# Sinister Sprocket: 1 face-up Spell or Trap Card, on either side.
			var ups3: Array = []
			for q in [opp_i, p]:
				for st in s.players[q].spells:
					if st != null and st.face_up:
						ups3.append(st)
				if s.players[q].field_spell != null:
					ups3.append(s.players[q].field_spell)
			var theirs3: Array = ups3.filter(func(x): return x.owner == opp_i)
			if theirs3.is_empty() and not s.manual[p]:
				return events          # the AI does not blow up its own cards
			if not ups3.is_empty() and s.manual[p] and s.choose_option(p, Loc.t("%s: destroy 1 face-up Spell or Trap?") % c.cname(), [Loc.t("Yes"), Loc.t("No")], 0, c) == 1:
				return events
			if not ups3.is_empty():
				var got3 = s.pick1(p, Loc.t("%s: destroy 1 face-up Spell or Trap") % c.cname(), ups3, theirs3[0] if not theirs3.is_empty() else ups3[0], c)
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [c.cname(), got3.cname()]))
				events.append_array(s._destroy_st(got3))
			return events
		"any_pick":
			# "Target 1 card your opponent controls; destroy that target": a monster, a Spell or Trap
			# (face-up or Set), or their Field Spell.
			var every: Array = opp.monsters()
			for st in opp.spells:
				if st != null:
					every.append(st)
			if opp.field_spell != null:
				every.append(opp.field_spell)
			if every.is_empty():
				return events
			var want = _best_opp(s, p)
			var gotx = s.pick1(p, Loc.t("%s: destroy 1 card") % c.cname(), every, want if want != null else every[0], c)
			if opp.field.has(gotx):
				targets.append(gotx)
			else:
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [c.cname(), gotx.cname() if gotx.face_up else Loc.t("a set card")]))
				events.append_array(s._destroy_st(gotx))
				return events
		"all_faceup_spells":
			# Cyber Prima: every face-up Spell on the field, both sides.
			var ups2: Array = []
			for q in 2:
				for st in s.players[q].spells:
					if st != null and st.face_up and st.is_spell():
						ups2.append(st)
				if s.players[q].field_spell != null:
					ups2.append(s.players[q].field_spell)
			if not ups2.is_empty():
				events.append(_ev(p, c, Loc.t("%s destroys every face-up Spell") % c.cname()))
			for st in ups2:
				events.append_array(s._destroy_st(st))
			return events
		"set_any":
			# Granmarg: 1 Set card on the field, a face-down monster or a Set Spell/Trap.
			var downs: Array = []
			for q in [opp_i, p]:
				for m in s.players[q].monsters():
					if not m.face_up:
						downs.append(m)
				for st in s.players[q].spells:
					if st != null and not st.face_up:
						downs.append(st)
			if not downs.is_empty():
				var got2 = s.pick1(p, Loc.t("%s: destroy 1 Set card") % c.cname(), downs, downs[0], c)
				events.append(_ev(p, c, Loc.t("%s destroys a Set card") % c.cname()))
				events.append_array(s._destroy(got2) if got2.is_monster() and (s.players[0].field.has(got2) or s.players[1].field.has(got2)) else s._destroy_st(got2))
			return events
		"set_st":
			var sts := opp.set_cards()
			if not sts.is_empty():
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [c.cname(), "a set card" if what == "set_st" else "Spells"]))
				for st in [s.pick1(p, Loc.t("%s: destroy 1 Spell or Trap") % c.cname(), sts, sts[0], c)]:
					events.append_array(s._destroy_st(st))
			return events
		"all_field_other":
			for q in 2:
				for m in s.players[q].monsters():
					if m != c:
						targets.append(m)
				for st in s.players[q].set_cards():
					events.append_array(s._destroy_st(st))
	if targets.is_empty():
		return events
	events.append(_ev(p, c, Loc.t("%s destroys %s") % [c.cname(), targets[0].cname() if targets.size() == 1 else Loc.t("%d monsters") % targets.size()]))
	for t in targets:
		events.append_array(s._destroy(t))
	return events
