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
	var b := 0
	if c.atk_mod_turn == s.turn:
		b += c.atk_mod_t
	b += c.atk_mod
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


static func _count(s: DuelState, owner: int, spec: String) -> int:
	var parts := spec.split(":")
	var kind := parts[0]
	var val := parts[1] if parts.size() > 1 else ""
	var n := 0
	if kind == "own_banished":
		return s.players[owner].banished.size()
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
					if m.cname() == val or str(fx(m).get("name_as", "")) == val:
						n += 1
	return n


static func can_direct(s: DuelState, p: int, c) -> bool:
	var opp := s.players[s.opponent(p)]
	if opp.monsters().is_empty():
		return true
	var f := fx(c)
	if f.get("direct", false):
		return true
	match str(f.get("direct_if", "")):
		"opp_all_def":
			for m in opp.monsters():
				if m.attack_pos:
					return false
			return true
		"opp_only_ewf":
			for m in opp.monsters():
				if m.face_up and not str(m.data.get("attribute", "")) in ["EARTH", "WATER", "FIRE"]:
					return false
			return true
		"opp_all_1600":
			for m in opp.monsters():
				if not m.face_up or s.atk_of(m, false) < 1600:
					return false
			return true
		"opp_all_stronger":
			for m in opp.monsters():
				if s.atk_of(m, false) <= s.atk_of(c, false):
					return false
			return true
	return false


static func max_attacks(c) -> int:
	var f := fx(c)
	return 2 if f.get("double_attack", false) or f.get("double_vs_def", false) else 1


static func piercing(s: DuelState, p: int, c) -> bool:
	if fx(c).get("piercing", false):
		return true
	if s.players[p].hand.is_empty():
		for m in s.players[p].monsters():
			if m.face_up and fx(m).get("piercing_if", "") == "hand_empty":
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


## Special Summon from the hand by its own rule (Bora, Gale, Vice Dragon, Photon Thrasher...).
static func can_special_hand(s: DuelState, p: int, c) -> bool:
	var f := fx(c)
	if s.players[p].free_zone() == -1:
		return false
	if f.get("special_banish_ld", false):
		return _gy_attr(s, p, "LIGHT") != null and _gy_attr(s, p, "DARK") != null
	if f.get("eltanin", false):
		return not _light_machines(s, p).is_empty()
	if f.has("special_hand_if"):
		return _cond(s, p, str(f["special_hand_if"]))
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
		return s.pick1(p, "%s: banish 1 %s monster from your Graveyard" % [c.cname(), attr], all, pick, c)
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
		events.append(_ev(p, c, "%s: %d ATK. Every other face-up monster goes to the Graveyard!" % [c.cname(), 500 * fuel.size()]))
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
		picks = s.choose(p, "%s: Tribute %d monster%s" % [c.cname(), need, "" if need == 1 else "s"], can, need, picks, false, c)
		for m in picks:
			ps.field[ps.field.find(m)] = null
			s._to_gy(ps, m)
			events.append({"type": "tribute", "player": p, "card": m})
	if f.get("special_banish_ld", false):
		for attr in ["LIGHT", "DARK"]:
			events.append_array(s._banish(_gy_attr(s, p, attr, c)))
	ps.hand.erase(c)
	if f.get("half_if_special", false):
		c.set_meta("special_from_hand", true)
	events.append_array(s._special(p, c, "effect"))
	events.append_array(on_summon(s, p, c, "special"))
	return events


# ------------------------------------------------------------------ triggers

## kind: "normal", "flip", "special", "synchro", "fusion", "xyz"
static func on_summon(s: DuelState, p: int, c, kind: String) -> Array:
	var f := fx(c)
	var events := []
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


static func trigger(s: DuelState, c, key: String, ctx := {}) -> Array:
	var f := fx(c)
	if not f.has(key) or s.is_over():
		return []
	return run_list(s, c.owner, c, f[key], ctx)


static func standby(s: DuelState, p: int) -> Array:
	var events := []
	for m in s.players[p].monsters():
		if m.face_up and fx(m).has("standby"):
			events.append_array(run_list(s, p, m, fx(m)["standby"], {}))
	return events


static func end_phase(s: DuelState, p: int) -> Array:
	var events := []
	for m in s.players[p].monsters():
		if m.face_up and fx(m).has("end"):
			events.append_array(run_list(s, p, m, fx(m)["end"], {}))
	return events


# ------------------------------------------------------------------ ignition effects

static func ignite_spec(c) -> Dictionary:
	return fx(c).get("ignite", {})


static func can_ignite(s: DuelState, p: int, c) -> bool:
	var ig := ignite_spec(c)
	if ig.is_empty() or p != s.current or s.is_over() or not s._in_main():
		return false
	if not s.players[p].field.has(c) or not c.face_up or c.ignite_turn == s.turn:
		return false
	if ig.has("cond") and not _cond(s, p, str(ig["cond"])):
		return false
	var ps := s.players[p]
	match str(ig.get("cost", "none")):
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
				if str(a[1]).begins_with("best") or str(a[1]) in ["atk_below_self", "weakest"]:
					if opp.monsters().is_empty() and not (a[1] == "best_any" and not opp.set_cards().is_empty()):
						return false
			"opp_half", "opp_zero", "destroy_half_damage":
				if opp.monsters().is_empty():
					return false
			"banish":
				if s._strongest_face_up(s.opponent(p)) == null and not (a[1] == "best_any" and (not opp.monsters().is_empty() or not opp.set_cards().is_empty())):
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
	return true


static func ignite(s: DuelState, p: int, c) -> Array:
	if not can_ignite(s, p, c):
		return []
	var ig := ignite_spec(c)
	var ps := s.players[p]
	var events := [_ev(p, c, "%s activates its effect" % c.cname())]
	c.ignite_turn = s.turn
	var ctx := {"_ign": true}
	match str(ig.get("cost", "none")):
		"discard", "discard_monster":
			var pick = null
			var can: Array = []
			for h in ps.hand:
				if ig["cost"] == "discard_monster" and not h.is_monster():
					continue
				can.append(h)
				if pick == null or s._card_value(h) < s._card_value(pick) or (ig["cost"] == "discard_monster" and h.atk() > pick.atk()):
					pick = h
			pick = s.pick1(p, "%s: discard 1 card as the cost" % c.cname(), can, pick, c)
			ps.hand.erase(pick)
			s._to_gy(ps, pick)
			ctx["discarded"] = pick
			events.append({"type": "discard", "player": p, "card": pick})
		"tribute_self":
			ps.field[ps.field.find(c)] = null
			s._to_gy(ps, c)
			events.append({"type": "tribute", "player": p, "card": c})
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
				pick = s.pick1(p, "%s: Tribute 1 monster as the cost" % c.cname(), can, pick, c)
			ps.field[ps.field.find(pick)] = null
			s._to_gy(ps, pick)
			events.append({"type": "tribute", "player": p, "card": pick})
		"banish_gy_dark":
			events.append_array(s._banish(_gy_attr(s, p, "DARK", c)))
		"banish_gy_monster":
			var gm: Array = s._best_monsters(ps.gy, 99)
			events.append_array(s._banish(s.pick1(p, "%s: banish 1 monster from your Graveyard" % c.cname(), gm, gm[gm.size() - 1], c)))
		"detach", "detach2":
			var n := 2 if ig["cost"] == "detach2" else 1
			for i in n:
				var o = c.overlays.pop_back()
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
	for a in actions:
		if s.is_over():
			break
		events.append_array(run(s, p, c, a, ctx))
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
		"draw":
			events.append(_ev(p, c, "%s: draw %d" % [name, a[1]]))
			events.append_array(s._draw(p, int(a[1])))
		"draw_if_alone":
			if ps.hand.is_empty() and ps.monsters().size() == 1 and ps.set_cards().is_empty():
				events.append(_ev(p, c, "%s: draw %d" % [name, a[1]]))
				events.append_array(s._draw(p, int(a[1])))
		"draw_once":
			var once_key := "once_" + name.validate_node_name().replace(" ", "_").replace("-", "_").replace("'", "")
			if not ps.has_meta(once_key):
				ps.set_meta(once_key, true)
				events.append(_ev(p, c, "%s: draw %d" % [name, a[1]]))
				events.append_array(s._draw(p, int(a[1])))
		"damage":
			events.append(_ev(p, c, "%s deals %d damage" % [name, a[1]]))
			events.append_array(s._damage(opp_i, int(a[1])))
		"self_damage":
			events.append(_ev(p, c, "%s: you take %d damage" % [name, a[1]]))
			events.append_array(s._damage(p, int(a[1])))
		"heal":
			ps.lp += int(a[1])
			events.append(_ev(p, c, "%s: gain %d LP" % [name, a[1]]))
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
						amt = v.level() * int(a[1])
					"damage_if_victim_race":
						amt = int(a[2]) if str(v.data.get("race", "")) == a[1] else 0
				if amt > 0:
					events.append(_ev(p, c, "%s burns %d!" % [name, amt]))
					events.append_array(s._damage(opp_i, amt))
		"gain_victim_atk":
			var v = ctx.get("victim")
			if v != null and v.atk() > 0:
				c.atk_mod += v.atk()
				events.append(_ev(p, c, "%s gains %d ATK" % [name, v.atk()]))
		"search":
			var got := _pick(s, p, c, "add 1 card from your Deck to your hand", ps.deck, a[1], 1)
			if got.is_empty():
				return events
			var d = got[0]
			ps.deck.erase(d)
			ps.hand.append(d)
			s._shuffle(ps.deck)
			events.append(_ev(p, c, "%s adds %s to the hand" % [name, d.cname()]))
			events.append({"type": "search", "player": p, "card": d, "deck": ps.deck.size()})
		"gy_to_hand":
			for d in _pick(s, p, c, "add from your Graveyard to your hand", ps.gy, a[1], int(a[2])):
				ps.gy.erase(d)
				ps.hand.append(d)
				events.append(_ev(p, c, "%s returns %s to the hand" % [name, d.cname()]))
				events.append({"type": "gy_to_hand", "player": p, "card": d, "deck": ps.deck.size()})
		"special":
			var src: Array = ps.deck if a[1] == "deck" else (ps.hand if a[1] == "hand" else ps.gy)
			var n: int = int(a[4]) if a.size() > 4 else 1
			var pool: Array = src.filter(func(x): return s.can_revive(x)) if a[1] == "gy" else src
			for d in _pick(s, p, c, "Special Summon from your %s" % ("Deck" if a[1] == "deck" else ("hand" if a[1] == "hand" else "Graveyard")), pool, a[2], n):
				if ps.free_zone() == -1:
					break
				src.erase(d)
				if a[1] == "deck":
					s._shuffle(ps.deck)
				events.append(_ev(p, c, "%s calls %s" % [name, d.cname()]))
				var ev := s._special(p, d, "reborn" if a[1] == "gy" else "effect", "def" if a.size() > 3 and a[3] == "def" else ("atk" if a.size() > 3 and a[3] == "atk" else ""))
				events.append_array(ev)
				events.append_array(on_summon(s, p, d, "special"))
		"revive_self", "revive_self_discard2", "pay_revive":
			if not ps.gy.has(c) or ps.free_zone() == -1:
				return events
			if c.get_meta("revived", false):
				return events
			if a[0] == "revive_self_discard2":
				if ps.hand.size() < 2:
					return events
				for h in s.choose(p, "%s: discard 2 cards" % name, ps.hand, 2, ps.hand.slice(0, 2), false, c):
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
			events.append(_ev(p, c, "%s comes back!" % name))
			events.append_array(s._special(p, c, "reborn", "def" if (a.size() < 2 or a[0] != "revive_self" or a[1] == "def") else ""))
		"destroy":
			events.append_array(_destroy_action(s, p, c, str(a[1]), ctx))
		"banish":
			# ["banish", "best"]: the opponent's strongest face-up monster. "best_any": or a set card.
			var t = s._strongest_face_up(opp_i)
			var bcan: Array = opp.monsters().filter(func(m): return m.face_up)
			if str(a[1]) == "best_any":
				bcan = opp.monsters() + opp.set_cards()
				if t == null:
					t = _best_opp(s, p)
				if t == null and not opp.set_cards().is_empty():
					t = opp.set_cards()[0]
			if t != null:
				t = s.pick1(p, "%s: banish 1 card" % name, bcan, t, c)
			if t != null:
				events.append(_ev(p, c, "%s banishes %s" % [name, t.cname() if t.face_up else "a set card"]))
				ctx["banished"] = t
				events.append_array(s._banish(t))
		"banish_opp_gy":
			var picks: Array = s._best_monsters(opp.gy, int(a[1]))
			if not picks.is_empty():
				picks = s.choose(p, "%s: banish from their Graveyard" % name, s._best_monsters(opp.gy, 99), picks.size(), picks, false, c)
				events.append(_ev(p, c, "%s banishes from the Graveyard" % name))
			for g in picks:
				events.append_array(s._banish(g))
		"banish_own_gy_boost":
			# Bazoo: banish up to n monsters from your GY, gain ATK for each until the end of the turn.
			var picks: Array = s._best_monsters(ps.gy, 99)
			picks.reverse()
			var own_all: Array = picks.duplicate()
			picks = picks.slice(0, int(a[1]))
			if not picks.is_empty():
				picks = s.choose(p, "%s: banish %d from your Graveyard" % [name, picks.size()], own_all, picks.size(), picks, false, c)
			for g in picks:
				events.append_array(s._banish(g))
			if not picks.is_empty():
				c.atk_mod_t = (c.atk_mod_t if c.atk_mod_turn == s.turn else 0) + int(a[2]) * picks.size()
				c.atk_mod_turn = s.turn
				events.append(_ev(p, c, "%s gains %d ATK" % [name, int(a[2]) * picks.size()]))
		"banish_killer_and_self":
			var k = ctx.get("killer")
			events.append(_ev(p, c, "%s drags its attacker out of the duel" % name))
			if k != null and s.players[k.owner].field.has(k):
				events.append_array(s._banish(k))
			events.append_array(s._banish(c))
		"banish_victim":
			var v = ctx.get("victim")
			if v != null and s.players[v.owner].gy.has(v):
				events.append(_ev(p, c, "%s banishes %s" % [name, v.cname()]))
				events.append_array(s._banish(v))
		"damage_if_banished_dark":
			var b = ctx.get("banished")
			if b != null and b.is_monster() and str(b.data.get("attribute", "")) == "DARK":
				events.append_array(s._damage(opp_i, int(a[1])))
		"destroy_half_damage":
			var t = _best_opp(s, p, "", c, "destroy 1 monster")
			if t != null:
				var dmg: int = s.atk_of(t, false) / 2
				events.append(_ev(p, c, "%s destroys %s" % [name, t.cname()]))
				events.append_array(s._destroy(t))
				events.append_array(s._damage(opp_i, dmg))
		"destroy_killer":
			var k = ctx.get("killer")
			if k != null and s.players[k.owner].field.has(k):
				events.append(_ev(p, c, "%s takes %s down with it" % [name, k.cname()]))
				events.append_array(s._destroy(k))
		"dice_destroy":
			var roll := s._rng.randi_range(1, 6)
			if roll == 1 or roll == 6:
				events.append(_ev(p, c, "%s rolled a %d... miss!" % [name, roll]))
			else:
				events.append(_ev(p, c, "%s rolled a %d!" % [name, roll]))
				events.append_array(_destroy_action(s, p, c, "best_any", ctx))
		"self_atk":
			c.atk_mod_turn = s.turn
			c.atk_mod_t = int(a[1])
			events.append(_ev(p, c, "%s gains %d ATK this turn" % [name, a[1]]))
		"no_battle_damage":
			ps.no_damage_turn = s.turn
			events.append(_ev(p, c, "%s: no battle damage this turn" % name))
		"self_atk_zero":
			c.zero_turn = s.turn
		"perm_atk":
			c.atk_mod += int(a[1])
			events.append(_ev(p, c, "%s gains %d ATK" % [name, a[1]]))
		"best_own_atk":
			var best = null
			for m in ps.monsters():
				if best == null or s.atk_of(m, false) > s.atk_of(best, false):
					best = m
			if best != null:
				best.atk_mod_turn = s.turn
				best.atk_mod_t = int(a[1])
				events.append(_ev(p, best, "%s gains %d ATK" % [best.cname(), a[1]]))
		"opp_half", "opp_zero":
			var t = _best_opp(s, p, "", c, "choose the monster to weaken")
			if t != null:
				if a[0] == "opp_half":
					t.half_turn = s.turn
				else:
					t.zero_turn = s.turn
				events.append(_ev(p, c, "%s's ATK is %s this turn" % [t.cname(), "halved" if a[0] == "opp_half" else "0"]))
		"opp_flip", "opp_to_def":
			var t = _best_opp(s, p, "atk_pos", c, "switch 1 monster to Defense")
			if t != null:
				t.attack_pos = false
				events.append(_ev(p, c, "%s switches to Defense" % t.cname()))
				events.append({"type": "position", "player": opp_i, "card": t, "zone": opp.field.find(t)})
		"to_def":
			c.attack_pos = false
			events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
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
				events.append(_ev(p, c, "%s makes the opponent discard" % name))
				events.append({"type": "discard", "player": opp_i, "card": h})
		"opp_mill":
			if not opp.deck.is_empty():
				var d = opp.deck.pop_back()
				s._to_gy(opp, d)
				events.append(_ev(p, c, "%s sends %s to the GY" % [name, d.cname()]))
				events.append({"type": "mill", "player": opp_i, "card": d, "deck": opp.deck.size()})
		"opp_redraw":
			var n := opp.hand.size()
			for h in opp.hand:
				opp.deck.append(h)
			opp.hand.clear()
			s._shuffle(opp.deck)
			events.append(_ev(p, c, "%s: the opponent redraws their hand" % name))
			events.append({"type": "redraw", "player": opp_i, "deck": opp.deck.size()})
			events.append_array(s._draw(opp_i, n))
		"top_spell_draw":
			if not ps.deck.is_empty() and ps.deck.back().is_spell():
				events.append(_ev(p, c, "%s finds a Spell!" % name))
				events.append_array(s._draw(p, 1))
			else:
				events.append(_ev(p, c, "%s: no Spell on top" % name))
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
				events.append(_ev(p, c, "Junk Warrior gains %d ATK" % sum))
		"all_dragons_attack":
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
						src.erase(d)
						events.append(_ev(p, c, "%s levels up!" % name))
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
				targets.append(s.pick1(p, "%s: destroy 1 monster" % c.cname(), low, best, c))
		"best_any":
			var t = _best_opp(s, p)
			var any: Array = opp.monsters() + opp.set_cards()
			if not any.is_empty():
				var got = s.pick1(p, "%s: destroy 1 card" % c.cname(), any, t if t != null else opp.set_cards()[0], c)
				if opp.field.has(got):
					targets.append(got)
				else:
					events.append(_ev(p, c, "%s destroys a set card" % c.cname()))
					events.append_array(s._destroy_st(got))
					return events
		"set_st", "all_faceup_spells":
			var sts := opp.set_cards()
			if not sts.is_empty():
				events.append(_ev(p, c, "%s destroys %s" % [c.cname(), "a set card" if what == "set_st" else "Spells"]))
				for st in (sts if what == "all_faceup_spells" else [s.pick1(p, "%s: destroy 1 Spell or Trap" % c.cname(), sts, sts[0], c)]):
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
	events.append(_ev(p, c, "%s destroys %s" % [c.cname(), targets[0].cname() if targets.size() == 1 else "%d monsters" % targets.size()]))
	for t in targets:
		events.append_array(s._destroy(t))
	return events
