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
	# Gagaga Cowboy, Attack Position effect: attacking an opponent's monster it gains 1000 ATK and
	# that monster loses 500 ATK, during the Damage Step only.
	if battling and vs != null:
		if attacking and c.cowboy_turn == s.turn:
			b += 1000
		elif not attacking and vs.cowboy_turn == s.turn:
			b -= 500
	if battling and attacking:
		if vs != null:
			b += int(f.get("atk_attack", 0))
			if not vs.attack_pos:
				b += int(f.get("atk_vs_def", 0))
			if f.has("atk_attack_attr") and vs.face_up and str(vs.data.get("attribute", "")) == str(f["atk_attack_attr"][0]):
				b += int(f["atk_attack_attr"][1])   # Insect Soldiers of the Sky
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
	if int(c.tags.get("cka", -1)) == s.turn and s.phase == DuelState.Phase.BATTLE:
		b += c.def() - c.atk()   # Chaos King Archfiend switched it
	b -= int(f.get("lose_per_counter", 0)) * c.counter   # Black-Winged Dragon
	if battling and c.tags.has("prime_boost"):
		b += int(c.tags["prime_boost"])   # Number 62: Galaxy-Eyes Prime Photon Dragon
	if f.get("absorb_half", false) and s.absorbed_by(c) != null:
		b += s.absorbed_by(c).atk() / 2   # Destiny HERO - Plasma: "gains ATK equal to half the original ATK of the monster equipped to it"
	if f.get("dreadmaster", false):
		# Destiny HERO - Dreadmaster: "The ATK/DEF of this card are equal to the combined original ATK of all other "Destiny HERO" monsters you control."
		for m in s.players[c.owner].monsters():
			if m != c and m.face_up and m.cname().contains("Destiny HERO"):
				b += m.atk()
	if battling and attacking and f.get("stealth_union", false):
		b -= c.atk() / 2   # "If this card attacks, its original ATK is halved until the end of the Damage Step."
	if battling and attacking and vs == null and f.get("direct_half", false):
		b -= (c.atk() + b) / 2   # Cyberdark Edge: "If it does using this effect, its ATK is halved during damage calculation only."
	if f.get("absorb", false) and s.absorbed_by(c) != null:
		b += s.absorbed_by(c).atk()   # Relinquished: "This card's ATK/DEF become equal to that equipped monster's."
	if c.tags.has("cocoon_uid") and s.cocooned(c) != null:
		b += s.cocooned(c).atk() - c.atk()   # Cocoon of Evolution: its original ATK/DEF become the Cocoon's
	if battling and attacking and vs != null and vs.cname().contains("Blackwing"):
		# Blackwing - Gust the Backblast: a monster attacking one of your "Blackwing" monsters loses 300 ATK during the Damage Step only.
		for g in s.players[vs.owner].monsters():
			if g.face_up and not g.negated and fx(g).get("gust", false):
				b -= 300
	if f.has("atk_per") and str(f["atk_per"][0]).begins_with("own_attr_others:") and c.face_up and str(c.data.get("attribute", "")) == str(f["atk_per"][0]).split(":")[1]:
		b -= int(f["atk_per"][1])   # ("except this card")
	if f.has("atk_if_hand_le") and s.players[c.owner].hand.size() <= int(f["atk_if_hand_le"][0]):
		b += int(f["atk_if_hand_le"][1])   # Blade Knight
	if f.get("atk_lp_gap", false) and s.players[c.owner].lp < s.players[s.opponent(c.owner)].lp:
		# Air Neos: "While your Life Points are lower than your opponent's, this card gains ATK equal to the difference."
		b += s.players[s.opponent(c.owner)].lp - s.players[c.owner].lp
	if f.has("lose_if_alone"):
		var n := 0
		for m in s.players[c.owner].monsters():
			if m != c and m.cname() == c.cname():
				n += 1
		if n == 0:
			b -= int(f["lose_if_alone"])
	if f.get("blader", false) and s.players[s.opponent(c.owner)].monsters().size() == 2:
		b += c.atk()
	if f.get("element_saurus", false) and attr_on_field(s, "FIRE"):
		b += 500
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
	# Boost Warrior is one of the Warriors it powers up.
	if f.get("aura_self", false) and f.has("aura_own_race") and str(c.data.get("race", "")) == f["aura_own_race"][0]:
		b += int(f["aura_own_race"][1])
	# Armory Arm, riding as an Equip Card: ATK only.
	for u in s.unions_on(c):
		if not u.negated:
			b += int(fx(u).get("union", {}).get("boost_atk", 0))
	# Harpie Lady 1 also powers itself up (it's WIND)
	if f.has("aura") and str(c.data.get("attribute", "")) == f["aura"][0]:
		b += int(f["aura"][1])
	if c.zero_turn == s.turn or c.zero_perm:
		return -c.atk()
	if c.half_turn == s.turn:
		b -= (c.atk() + b) / 2
	return b


## DEF from a monster's own effect ("ATK/DEF become...", "gains ATK/DEF for each...").
static func def_bonus(s: DuelState, c) -> int:
	var f := fx(c)
	var u := union_boost(s, c)
	if int(c.tags.get("tmp_def_until", -1)) >= s.turn:
		u += int(c.tags.get("tmp_def", 0))   # Blustering Winds
	if f.get("absorb", false) and s.absorbed_by(c) != null:
		u += s.absorbed_by(c).def()
	if c.tags.has("cocoon_uid") and s.cocooned(c) != null:
		u += s.cocooned(c).def() - c.def()
	if fx(c).get("dreadmaster", false):
		for m in s.players[c.owner].monsters():
			if m != c and m.face_up and m.cname().contains("Destiny HERO"):
				u += m.atk()
	if int(c.tags.get("cka", -1)) == s.turn and s.phase == DuelState.Phase.BATTLE:
		u += c.atk() - c.def()   # Chaos King Archfiend switched it
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
	if kind == "own_hand":
		return s.players[owner].hand.size()   # Slifer the Sky Dragon
	if kind == "own_attr_others":
		# Jawsman: each other face-up WATER monster you control (the caller is not counted: it is passed by name in `val` after a comma).
		for m in s.players[owner].monsters():
			if m.face_up and str(m.data.get("attribute", "")) == val:
				n += 1
		return n
	if kind in ["all_st", "all_cards", "opp_st"]:
		# Flare Neos: every Spell/Trap on the field. Magma Neos: every card on the field. Flare Scarab: the opponent's Spells/Traps.
		for q in 2:
			if kind == "opp_st" and q == owner:
				continue
			n += s.players[q].set_cards().size() + (1 if s.players[q].field_spell != null else 0)
			if kind == "all_cards":
				n += s.players[q].monsters().size()
		return n
	if kind == "own_family":
		# Amazoness Paladin: each "Amazoness" monster you control.
		for m in s.players[owner].monsters():
			if m.face_up and m.cname().contains(val):
				n += 1
		return n
	if kind == "own_gy_race":
		for g in s.players[owner].gy:
			if g.is_monster() and str(g.data.get("race", "")) == val:
				n += 1
		return n
	if kind == "own_gy_monsters":
		for g in s.players[owner].gy:
			if g.is_monster():
				n += 1
		return n
	if kind == "own_gy_tuners":
		# Red Nova Dragon: each Tuner in your Graveyard.
		for g in s.players[owner].gy:
			if g.is_monster() and g.is_tuner():
				n += 1
		return n
	if kind == "own_gy_has":
		# Shining Flare Wingman: each "Elemental HERO" card in your Graveyard.
		for g in s.players[owner].gy:
			if str(g.data.get("name", "")).contains(val):
				n += 1
		return n
	if kind == "opp_attrs":
		# Electrum: each monster the opponent controls with one of its Attributes.
		for m in s.players[s.opponent(owner)].monsters():
			if m.face_up and str(m.data.get("attribute", "")) in val.split("|"):
				n += 1
		return n
	if kind == "opp_dragons" or kind == "all_dragons":
		# Buster Blader: Dragons the opponent controls or has in the Graveyard. Dark Paladin: every Dragon on the field and in the Graveyards.
		for q in 2:
			if kind == "opp_dragons" and q == owner:
				continue
			for m in s.players[q].monsters():
				if m.face_up and str(m.data.get("race", "")) == "Dragon":
					n += 1
			for g in s.players[q].gy:
				if g.is_monster() and str(g.data.get("race", "")) == "Dragon":
					n += 1
		return n
	if kind == "gy_race_all":
		# Monsters of one Type in both Graveyards (Colossal Fighter counts Warriors).
		for q in 2:
			for g in s.players[q].gy:
				if g.is_monster() and str(g.data.get("race", "")) == val:
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
	if f.get("direct", false) or int(c.tags.get("direct_turn", -1)) == s.turn:
		return true
	# Toons. The small ones need your Toon World and no Toon across the table; the big ones
	# only need the other side to have no Toon.
	var toon := int(f.get("toon", 0))
	if toon == 1 and not c.negated:
		return s.toon_world(p) and not s.has_toon(s.opponent(p))
	if toon == 2 and not c.negated:
		return not s.has_toon(s.opponent(p))
	match str(f.get("direct_if", "")):
		"hand_empty":
			return s.players[p].hand.is_empty()   # Infernity Archer
		"own_set":
			# Mariner: "While you have any Set card(s) in your Spell & Trap Zone".
			for st in s.players[p].spells:
				if st != null and not st.face_up:
					return true
			return false
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
	if f.get("attacks_per_mat", false):
		return maxi(1, int(c.tags.get("mat_n", 1)))   # Chimeratech Overdragon
	if f.get("attacks_per_non_tuner", false):
		# Shooting Quasar Dragon: up to the number of non-Tuners used for its Synchro Summon.
		return maxi(1, int(c.tags.get("non_tuners", 1)))
	if f.get("double_vs_def", false):
		# Twin-Sword Marauder: a second attack in a row only after it attacked a Defense Position monster.
		return 2 if c.hit_def_turn != -1 and c.hit_def_turn == c.attack_count_turn else 1
	if f.get("double_after_kill", false):
		# Black Luster Soldier - Envoy of the Beginning: one of its two effects each turn.
		return 2 if c.killed_turn != -1 and c.killed_turn == c.attack_count_turn and c.ignite_turn != c.killed_turn else 1
	return 2 if f.get("double_attack", false) else 1


static func piercing(s: DuelState, p: int, c) -> bool:
	if fx(c).get("piercing", false) or int(c.tags.get("pierce_turn", -1)) == s.turn:
		return true
	for dr in s.players[p].monsters():
		# Drill Synchron: your Warriors pierce.
		if dr.face_up and str(fx(dr).get("pierce_own_race", "")) != "" and str(fx(dr)["pierce_own_race"]) == str(c.data.get("race", "")):
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
	if f.get("survive_once_def_fx", false) and c.face_up and not c.attack_pos and c.survive_turn != s.turn:
		c.survive_turn = s.turn
		return true   # Clock Resonator: once per turn, in Defense Position, not by battle or by card effects
	if f.get("hand_empty_guard", false) and c.face_up and s.players[c.owner].hand.is_empty():
		return true
	return false


## True if c shrugs off being destroyed by battle (and records the once-per-turn use).
static func survives_battle(s: DuelState, c) -> bool:
	var f := fx(c)
	if c.tags.has("viser_t") and not c.negated:
		var vt = s.find_uid(int(c.tags["viser_t"]))
		if vt != null and s.players[s.opponent(c.owner)].field.has(vt):
			return true   # Viser Des: "This card cannot be destroyed by battle while the targeted monster is on the field."
	if f.get("battle_immune", false):
		return true
	if int(c.tags.get("unbreak_turn", -1)) == s.turn:
		return true   # Half Unbreak
	if s.current != c.owner and c.cname().contains("Blackwing"):
		# Silverwind the Ascendant: "During each of your opponent's turns, the first "Blackwing" monster you control that would be destroyed by battle, is not destroyed."
		for sw in s.players[c.owner].monsters():
			if sw.face_up and not sw.negated and fx(sw).get("silverwind", false) and int(sw.tags.get("sw_guard", -1)) != s.turn:
				sw.tags["sw_guard"] = s.turn
				return true
	if f.get("survive_vs_same_atk", false) and s.battle_foe != null and s.atk_of(s.battle_foe, false) == s.atk_of(c, false):
		return true   # Strong Wind Dragon
	if f.get("rocket", false) and s.current == c.owner and s.phase == DuelState.Phase.BATTLE:
		return true   # Rocket Warrior: "During your Battle Phase, this card cannot be destroyed by battle"
	if c.tags.has("guard_by"):
		# Elemental HERO Tempest: "while this card is face-up on the field, that monster cannot be destroyed by battle."
		var g = s.find_uid(int(c.tags["guard_by"]))
		if g != null and g.face_up and not g.negated and (s.players[0].field.has(g) or s.players[1].field.has(g)):
			return true
		c.tags.erase("guard_by")
	if f.has("survive_vs_atk_min") and s.battle_foe != null and s.atk_of(s.battle_foe, false) >= int(f["survive_vs_atk_min"]):
		return true   # Sonic Chick: not by battle with a monster that has 1900 or more ATK
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
	if cond == "lp_le_1000":
		return s.players[p].lp <= 1000   # Number C39: Utopia Ray
	if cond == "umbral_ghost":
		# "Special Summon this card and 1 Level 4 or lower Fiend-Type monster from your hand. You cannot Normal Summon/Set during the turn you activate this effect." Once per turn.
		var free_g := 0
		for z in s.players[p].field:
			if z == null:
				free_g += 1
		return free_g >= 2 and not s.normal_summoned and int(s.players[p].once_names.get("Umbral Horror Ghost", -1)) != s.turn \
				and s.players[p].hand.filter(func(h): return h.is_monster() and str(h.data.get("race", "")) == "Fiend" and h.level() <= 4 and not CardData.is_extra(h.id)).size() >= 2
	if cond == "own_water":
		return not s.players[p].monsters().filter(func(m): return m.face_up and str(m.data.get("attribute", "")) == "WATER").is_empty()
	if cond == "xyz_on_field":
		for q in 2:
			for m in s.players[q].monsters():
				if m.face_up and m.frame() == "xyz":
					return true
		return false
	if cond == "amaryllis_in_hand":
		return not s.players[p].hand.filter(func(h): return h.cname() == "Phoenixian Cluster Amaryllis").is_empty()
	if cond == "no_cards":
		# Gust the Backblast: "If you control no cards".
		return s.players[p].monsters().is_empty() and s.players[p].set_cards().is_empty() and s.players[p].field_spell == null
	if cond == "lp_over_1000":
		return s.players[p].lp > 1000   # Chaos Emperor Dragon: pay 1000 LP
	if cond == "metalmorph_red_eyes":
		# Red-Eyes Black Dragon equipped with Metalmorph, and Red-Eyes Black Metal Dragon in the Deck.
		if s.players[p].deck.filter(func(x): return x.cname() == "Red-Eyes Black Metal Dragon").is_empty():
			return false
		for st in s.players[p].spells:
			if st != null and st.face_up and st.cname() == "Metalmorph" and st.equipped_to != null and st.equipped_to.cname() == "Red-Eyes Black Dragon" and s.players[p].field.has(st.equipped_to):
				return true
		return false
	if cond == "lp_behind_2000":
		return s.players[s.opponent(p)].lp >= s.players[p].lp + 2000   # ZW - Eagle Claw
	if cond == "other_gagaga":
		return not s.players[p].monsters().filter(func(m): return m.face_up and m.cname().contains("Gagaga")).is_empty()
	if cond == "any_synchro":
		# Synkron Resonator: "If a Synchro Monster is on the field" (once per turn this way).
		return int(s.players[p].once_names.get("#synkron", -1)) != s.turn \
				and not (s.players[p].monsters() + s.players[s.opponent(p)].monsters()).filter(func(m): return m.face_up and m.frame() == "synchro").is_empty()
	if cond == "own_synchro8":
		# Creation Resonator: "If you control a Level 8 or higher Synchro Monster".
		return not s.players[p].monsters().filter(func(m): return m.face_up and m.frame() == "synchro" and m.level() >= 8).is_empty()
	if cond == "own_big_piece":
		return not s.players[p].monsters().filter(func(m): return m.face_up and m.cname() == "Big Piece Golem").is_empty()
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
	for k in ["special_tribute3", "special_cocoon", "lava_golem", "special_banish_race", "special_discard_race", "special_hand_if", "special_tribute2", "special_tribute_attr", "special_banish_ld", "eltanin", "special_toon", "special_discard_attr", "special_tribute_race", "special_discard_monster", "special_tribute_names", "special_tribute_f"]:
		if f.has(k):
			return true
	return false


## Special Summon from the hand by its own rule (Bora, Gale, Vice Dragon, Photon Thrasher...).
static func can_special_hand(s: DuelState, p: int, c) -> bool:
	var f := fx(c)
	if s.ss_locked(p) or s.big_locked(p, c):
		return false   # Gagaga Head / Crimson Blader
	if int(s.players[p].once_names.get("#no_hand_ss", -1)) == s.turn:
		return false   # Silent Angler: "you cannot Special Summon monsters from your hand for the rest of this turn"
	if f.get("one_only", false) and not s.players[p].monsters().filter(func(m): return m.face_up and m.cname() == c.cname()).is_empty():
		return false   # "You can only control 1" (Panther Shark)
	if f.has("special_tribute_names"):
		return not _named_set(s, p, c, f["special_tribute_names"]).is_empty()   # Valkyrion: Alpha, Beta and Gamma from the hand and/or field
	if f.has("special_tribute_f"):
		# Sorcerer of Dark Magic: Tribute 2 Level 6 or higher Spellcasters.
		return s.players[p].monsters().filter(func(m): return m.face_up and s.can_tribute_fx(m) and CardEffects.matches(m.data, f["special_tribute_f"][1])).size() >= int(f["special_tribute_f"][0])
	if f.has("special_cocoon"):
		return _cocoon_moth(s, p, int(f["special_cocoon"])) != null   # Larvae Moth, Great Moth, Perfectly Ultimate Great Moth
	if f.has("special_tribute3"):
		# Destiny HERO - Plasma (3 monsters), Destiny HERO - Dogma (3, at least 1 "Destiny HERO").
		var can3: Array = s.players[p].monsters().filter(func(m): return s.can_tribute_fx(m))
		return can3.size() >= 3 and (str(f["special_tribute3"]) == "" or not can3.filter(func(m): return m.face_up and m.cname().contains(str(f["special_tribute3"]))).is_empty())
	if s.players[p].free_zone() == -1 and int(f.get("special_toon", 0)) == 0 and not f.has("special_tribute_race"):
		return false
	if f.get("special_once_duel", false) and s.players[p].once_duel.has(c.cname()):
		return false   # "You can only Special Summon "Unknown Synchron" once per Duel this way."
	if f.has("special_tribute_race"):
		# Turret Warrior: by Tributing 1 Warrior monster.
		for m in s.players[p].monsters():
			if str(m.data.get("race", "")) == str(f["special_tribute_race"]) and s.can_tribute_fx(m):
				return true
		return false
	if f.get("special_discard_monster", false):
		# Quickdraw Synchron: by sending 1 monster from your hand to the Graveyard.
		for h in s.players[p].hand:
			if h != c and h.is_monster():
				return true
		return false
	if f.get("special_banish_ld", false):
		return _gy_attr(s, p, "LIGHT") != null and _gy_attr(s, p, "DARK") != null
	if f.get("lava_golem", false):
		# "Must first be Special Summoned (from your hand) to your opponent's field by Tributing 2 monsters they control. You cannot Normal Summon/Set the turn you Special Summon this card."
		return s.players[s.opponent(p)].monsters().filter(func(m): return s.can_tribute_fx(m)).size() >= 2 and not s.normal_summoned
	if f.has("special_banish_race"):
		# Dark Necrofear: banish 3 Fiend monsters from your Graveyard.
		return s.players[p].gy.filter(func(g): return g.is_monster() and str(g.data.get("race", "")) == str(f["special_banish_race"][0])).size() >= int(f["special_banish_race"][1])
	if f.get("eltanin", false):
		return not _light_machines(s, p).is_empty()
	if f.has("special_hand_if"):
		return _cond(s, p, str(f["special_hand_if"]))
	if f.has("special_discard_race"):
		# Malicevorous Fork: send 1 other monster of that Type from your hand to the Graveyard.
		return not s.players[p].hand.filter(func(h): return h != c and h.is_monster() and str(h.data.get("race", "")) == str(f["special_discard_race"])).is_empty()
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
	if f.get("lock_hand_ss", false):
		ps.once_names["#no_hand_ss"] = s.turn
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
			events.append_array(s._monster_left(m))
	c.set_meta("hand_fx_turn", s.turn)
	if str(f.get("special_hand_if", "")) == "any_synchro":
		ps.once_names["#synkron"] = s.turn
	if f.get("lava_golem", false):
		var opp_l := s.players[s.opponent(p)]
		var theirs_l: Array = opp_l.monsters().filter(func(m): return s.can_tribute_fx(m))
		theirs_l.sort_custom(func(x, y): return s.atk_of(x, false) > s.atk_of(y, false))
		for m in s.choose(p, Loc.t("%s: Tribute 2 of your opponent's monsters") % c.cname(), theirs_l, 2, theirs_l.slice(0, 2), false, c):
			opp_l.field[opp_l.field.find(m)] = null
			s._to_gy(s.players[m.owner if m.orig_owner == -1 else m.orig_owner], m)
			events.append({"type": "tribute", "player": s.opponent(p), "card": m})
			events.append_array(s._monster_left(m))
		ps.hand.erase(c)
		c.proper = true
		c.orig_owner = p
		c.owner = s.opponent(p)
		c.control_until = -1
		events.append(_ev(p, c, Loc.t("%s lands on the opponent's field") % c.cname()))
		events.append_array(s._special(s.opponent(p), c, "effect", "atk"))
		s.normal_summoned = true
		ps.extra_normals = 0
		return events
	if f.has("special_discard_race"):
		var pay_r: Array = ps.hand.filter(func(h): return h != c and h.is_monster() and str(h.data.get("race", "")) == str(f["special_discard_race"]))
		var least_r = pay_r[0]
		for h in pay_r:
			if s._card_value(h) < s._card_value(least_r):
				least_r = h
		least_r = s.pick1(p, Loc.t("%s: send 1 other %s monster from your hand to the Graveyard") % [c.cname(), str(f["special_discard_race"])], pay_r, least_r, c)
		ps.hand.erase(least_r)
		s._to_gy(ps, least_r)
		events.append({"type": "discard", "player": p, "card": least_r})
		events.append_array(trigger(s, least_r, "gy"))
		ps.hand.erase(c)
		events.append_array(s._special(p, c, "effect"))
		events.append_array(on_summon(s, p, c, "special"))
		return events
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
	if f.has("special_tribute3"):
		var pool3: Array = ps.monsters().filter(func(m): return s.can_tribute_fx(m))
		pool3.sort_custom(func(x, y): return s.atk_of(x, false) < s.atk_of(y, false))
		var fam3 := str(f["special_tribute3"])
		var auto3: Array = []
		if fam3 != "":
			var named3: Array = pool3.filter(func(m): return m.face_up and m.cname().contains(fam3))
			if named3.is_empty():
				return events
			auto3.append(named3[0])
		for m in pool3:
			if auto3.size() < 3 and not auto3.has(m):
				auto3.append(m)
		var picks3: Array = s.choose(p, Loc.t("%s: Tribute %d monster%s") % [c.cname(), 3, "s"], pool3, 3, auto3, false, c)
		if fam3 != "" and picks3.filter(func(m): return m.face_up and m.cname().contains(fam3)).is_empty():
			picks3 = auto3
		for m in picks3:
			ps.field[ps.field.find(m)] = null
			s._to_gy(ps, m)
			events.append({"type": "tribute", "player": p, "card": m})
			events.append_array(trigger(s, m, "tributed"))
			events.append_array(s._monster_left(m))
		ps.hand.erase(c)
		c.proper = true
		events.append_array(s._special(p, c, "effect"))
		if ps.field.has(c) and f.get("dogma", false):
			c.tags["dogma_due"] = true
		events.append_array(on_summon(s, p, c, "special"))
		return events
	if f.has("special_cocoon"):
		var moth = _cocoon_moth(s, p, int(f["special_cocoon"]))
		if moth == null:
			return events
		ps.field[ps.field.find(moth)] = null
		s._to_gy(ps, moth)
		events.append({"type": "tribute", "player": p, "card": moth})
		events.append_array(trigger(s, moth, "tributed"))
		events.append_array(s._monster_left(moth))
		ps.hand.erase(c)
		c.proper = true
		events.append_array(s._special(p, c, "effect"))
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
	if f.has("special_banish_race"):
		var pool_sb: Array = ps.gy.filter(func(g): return g.is_monster() and str(g.data.get("race", "")) == str(f["special_banish_race"][0]))
		pool_sb.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
		var n_sb := int(f["special_banish_race"][1])
		for g in s.choose(p, Loc.t("%s: banish %d monsters from your Graveyard") % [c.cname(), n_sb], pool_sb, n_sb, pool_sb.slice(0, n_sb), false, c):
			events.append_array(s._banish(g))
		c.proper = true
	var gain_atk := 0
	if f.has("special_tribute_names"):
		for m in _named_set(s, p, c, f["special_tribute_names"]):
			if ps.hand.has(m):
				ps.hand.erase(m)
			else:
				ps.field[ps.field.find(m)] = null
			s._to_gy(ps, m)
			events.append({"type": "tribute", "player": p, "card": m})
			events.append_array(s._monster_left(m))
	if f.has("special_tribute_f"):
		var pool_f: Array = ps.monsters().filter(func(m): return m.face_up and s.can_tribute_fx(m) and CardEffects.matches(m.data, f["special_tribute_f"][1]))
		pool_f.sort_custom(func(x, y): return s.atk_of(x, false) < s.atk_of(y, false))
		var n_f := int(f["special_tribute_f"][0])
		for m in s.choose(p, Loc.t("%s: Tribute %d monsters") % [c.cname(), n_f], pool_f, n_f, pool_f.slice(0, n_f), false, c):
			ps.field[ps.field.find(m)] = null
			s._to_gy(ps, m)
			events.append({"type": "tribute", "player": p, "card": m})
			events.append_array(EffectRunner.trigger(s, m, "tributed"))
			events.append_array(s._monster_left(m))
	if f.has("special_tribute_race"):
		var fodder: Array = ps.monsters().filter(func(m): return str(m.data.get("race", "")) == str(f["special_tribute_race"]) and s.can_tribute_fx(m))
		var weak = fodder[0]
		for m in fodder:
			if m.atk() > weak.atk():
				weak = m
		weak = s.pick1(p, Loc.t("%s: Tribute 1 %s monster") % [c.cname(), str(f["special_tribute_race"])], fodder, weak, c)
		gain_atk = weak.atk()
		ps.field[ps.field.find(weak)] = null
		s._to_gy(ps, weak)
		events.append({"type": "tribute", "player": p, "card": weak})
		events.append_array(EffectRunner.trigger(s, weak, "tributed"))
		events.append_array(s._monster_left(weak))
	if f.get("special_discard_monster", false):
		var mons_h: Array = ps.hand.filter(func(h): return h != c and h.is_monster())
		var low = mons_h[0]
		for h in mons_h:
			if s._card_value(h) < s._card_value(low):
				low = h
		low = s.pick1(p, Loc.t("%s: send 1 monster from your hand to the Graveyard") % c.cname(), mons_h, low, c)
		ps.hand.erase(low)
		s._to_gy(ps, low)
		events.append({"type": "discard", "player": p, "card": low})
	if f.get("special_once_duel", false):
		ps.once_duel[c.cname()] = true
	ps.hand.erase(c)
	if f.get("half_if_special", false):
		c.set_meta("special_from_hand", true)
	c.proper = true   # summoned by its own procedure: it may be brought back later
	events.append_array(s._special(p, c, "effect", str(f.get("special_hand_pos", ""))))
	if gain_atk > 0:
		# Turret Warrior: "...it gains ATK equal to the Tributed monster's original ATK."
		c.atk_mod += gain_atk
		events.append(_ev(p, c, Loc.t("%s gains %d ATK") % [c.cname(), gain_atk]))
	if int(f.get("special_hand_lv", 0)) > 0:
		c.lv_set = int(f["special_hand_lv"])   # Level Warrior: "...as a Level 4 monster"
		c.lv_turn = -1
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
	var fires: bool = (kind == "normal" and f.has("summon")) or (kind == "flip" and f.has("flip")) or (kind == "synchro" and f.has("synchro")) or (kind == "fusion" and f.has("fusion")) or (kind in ["special", "synchro", "fusion", "xyz"] and f.has("special_only")) or f.has("any_summon") or (kind == "xyz" and f.has("xyz"))
	if fires and _spent(s, p, c):
		return events
	if kind == "normal" and f.has("summon"):
		events.append_array(run_list(s, p, c, f["summon"], {}))
	if kind == "flip" and f.has("flip"):
		events.append_array(run_list(s, p, c, f["flip"], {}))
	if kind == "synchro" and f.has("synchro"):
		events.append_array(run_list(s, p, c, f["synchro"], {}))
	if kind == "fusion" and f.has("fusion"):
		events.append_array(run_list(s, p, c, f["fusion"], {}))
	if kind == "xyz" and f.has("xyz"):
		events.append_array(run_list(s, p, c, f["xyz"], {}))
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


## Is there a face-up monster of this Attribute anywhere on the field?
static func attr_on_field(s: DuelState, attr: String) -> bool:
	for q in 2:
		for m in s.players[q].monsters():
			if m.face_up and str(m.data.get("attribute", "")) == attr:
				return true
	return false


## Cyber Blader's third effect: player `p` controls exactly 3 monsters and the other side has a
## face-up Cyber Blader whose effects are not negated.
static func blader_negates(s: DuelState, p: int) -> bool:
	if s.players[p].monsters().size() != 3:
		return false
	for m in s.players[s.opponent(p)].monsters():
		if m.face_up and not m.negated and fx(m).get("blader", false):
			return true
	return false


static func trigger(s: DuelState, c, key: String, ctx := {}) -> Array:
	var f := fx(c)
	if not f.has(key) or s.is_over() or _spent(s, c.owner, c):
		return []
	if s.gy_fx_off == c.owner and s.players[c.owner].gy.has(c):
		return [_ev(c.owner, c, Loc.t("%s's effect in the Graveyard is negated") % c.cname())]   # Dododo Warrior is attacking
	if blader_negates(s, c.owner):
		return [_ev(c.owner, c, Loc.t("Cyber Blader negates %s") % c.cname())]
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
		if ex.get("end", false):
			continue   # back in an End Phase, not here
		ex["left"] = int(ex["left"]) - 1
		if int(ex["left"]) > 0:
			continue
		s.players[p].exiles.erase(ex)
		var back = ex["card"]
		var home: DuelState.PlayerState = s.players[int(ex["to"])]
		if ex.get("to_hand", false):
			# Lightforce Sword, Gold Sarcophagus: the card set aside goes to its owner's hand.
			if home.banished.has(back):
				home.banished.erase(back)
				home.hand.append(back)
				events.append(_ev(int(ex["to"]), back, Loc.t("The card that was set aside returns to the hand")))
				events.append({"type": "gy_to_hand", "player": int(ex["to"]), "card": back})
			continue
		if home.banished.has(back) and home.free_zone() != -1:
			home.banished.erase(back)
			events.append(_ev(int(ex["to"]), back, Loc.t("%s returns to the field") % back.cname()))
			events.append_array(s._special(int(ex["to"]), back, "return", "atk" if ex["atk_pos"] else "def"))
			if str(ex.get("then", "")) == "gy_monster_to_hand":
				# Drill Warrior: "...then add 1 monster from your Graveyard to your hand."
				var gm: Array = home.gy.filter(func(g): return g.is_monster() and not CardData.is_extra(g.id))
				if not gm.is_empty():
					gm.sort_custom(func(x, y): return x.atk() > y.atk())
					var take = s.pick1(int(ex["to"]), Loc.t("%s: add 1 monster from your Graveyard to your hand") % back.cname(), gm, gm[0], back)
					home.gy.erase(take)
					home.hand.append(take)
					events.append(_ev(int(ex["to"]), back, Loc.t("%s brings %s back to the hand") % [back.cname(), take.cname()]))
					events.append({"type": "gy_to_hand", "player": int(ex["to"]), "card": take})
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
	if g.get("not_sent_this_turn", false) and c.gy_turn == s.turn:
		return false
	if g.get("level_eater", false):
		return s.players[p].free_zone() != -1 and not _lv5_up(s, p).is_empty()
	if g.get("need_own_face", false) and s._strongest_face_up(p) == null:
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
	if g.has("equip_to"):
		return s.players[p].spells.find(null) != -1 and not _cocoon_hosts(s, p, str(g["equip_to"])).is_empty()
	if g.get("zw", false):
		return not _zw_hosts(s, p, c).is_empty()
	for a in g.get("do", []):
		if a[0] == "search" and _take(s.players[p].deck, a[1], 1).is_empty():
			return false
	return true


## May another card's effect Special Summon this monster from the hand or Deck? Not one that
## "Must (first) be Special Summoned" its own way (Perfectly Ultimate Great Moth out of Pinch Hopper).
static func _ss_ok(x) -> bool:
	if not x.is_monster():
		return true
	if CardEffects.of(x.cname()).get("no_special", false):
		return false
	var words := str(x.data.get("desc", "")).to_lower()
	return not (words.contains("must first be special summoned") or words.contains("must be special summoned") or words.contains("can only be special summoned"))


## The face-up monsters of that name a Cocoon of Evolution can go on (one Cocoon each).
static func _cocoon_hosts(s: DuelState, p: int, host_name: String) -> Array:
	return s.players[p].monsters().filter(func(m): return m.face_up and m.cname() == host_name and s.cocooned(m) == null)


## The Petit Moth that has been in its Cocoon for at least `turns` of its owner's turns, or null.
static func _cocoon_moth(s: DuelState, p: int, turns: int):
	for m in s.players[p].monsters():
		if m.face_up and m.cname() == "Petit Moth" and s.cocooned(m) != null and (s.turn - int(m.tags.get("cocoon_turn", s.turn))) / 2 >= turns:
			return m
	return null


static func hand_run(s: DuelState, p: int, c) -> Array:
	var g: Dictionary = fx(c)["hand_ignite"]
	var ps := s.players[p]
	if g.get("zw", false):
		return _zw_equip(s, p, c)
	if g.has("equip_to"):
		# Cocoon of Evolution: "target 1 "Petit Moth" you control; equip this card from your hand to that target."
		var hosts := _cocoon_hosts(s, p, str(g["equip_to"]))
		var zone_c: int = ps.spells.find(null)
		if hosts.is_empty() or zone_c == -1:
			return []
		var host = s.pick1(p, Loc.t("%s: equip it to which monster?") % c.cname(), hosts, hosts[0], c)
		ps.hand.erase(c)
		c.face_up = true
		ps.spells[zone_c] = c
		c.equipped_to = host
		host.tags["cocoon_uid"] = c.uid
		host.tags["cocoon_turn"] = s.turn
		return [{"type": "activate", "player": p, "card": c, "zone": zone_c},
				_ev(p, c, Loc.t("%s wraps %s: it is now %d / %d") % [c.cname(), host.cname(), c.atk(), c.def()])]
	var events := [_ev(p, c, Loc.t("%s is discarded for its effect") % c.cname())]
	ps.hand.erase(c)
	s._to_gy(ps, c)
	events.append({"type": "discard", "player": p, "card": c})
	events.append_array(run_list(s, p, c, g.get("do", []), {}))
	return events


## One card for each of these names from player p's hand and/or field, or [] when one is missing.
static func _named_set(s: DuelState, p: int, c, names: Array) -> Array:
	var out: Array = []
	for nm in names:
		var got = null
		for m in s.players[p].monsters() + s.players[p].hand:
			if m != c and m.cname() == str(nm) and not out.has(m) and (s.players[p].hand.has(m) or m.face_up):
				got = m
				break
		if got == null:
			return []
		out.append(got)
	return out


## A card was added from the Deck to the hand by a card effect (a search, or a draw a card gave you).
## Watapon: "You can Special Summon this card."
static func added_by_effect(s: DuelState, p: int, d) -> Array:
	var ps := s.players[p]
	if d == null or not ps.hand.has(d) or not d.is_monster() or not CardEffects.of(d.cname()).get("ss_when_added", false) or ps.free_zone() == -1 or ps.no_summon_turn == s.turn:
		return []
	if s.choose_option(p, Loc.t("%s: Special Summon it?") % d.cname(), ["Special Summon it", "Keep it in hand"], 0, d) != 0:
		return []
	ps.hand.erase(d)
	var ev := [_ev(p, d, Loc.t("%s hops onto the field") % d.cname())]
	ev.append_array(s._special(p, d, "effect"))
	return ev


## Face-up monsters of player p that are Level 5 or higher (Level Eater eats one of their Levels).
static func _lv5_up(s: DuelState, p: int) -> Array:
	return s.players[p].monsters().filter(func(m): return m.face_up and m.frame() != "xyz" and m.level() >= 5)


static func gy_run(s: DuelState, p: int, c) -> Array:
	var g: Dictionary = fx(c)["gy_ignite"]
	if g.get("level_eater", false):
		# "Target 1 Level 5 or higher monster you control; reduce its Level by 1, and if you do, Special Summon this card."
		var big: Array = _lv5_up(s, p)
		big.sort_custom(func(x, y): return x.level() > y.level())
		# (Left alone, the rules take a Level from anything but Stardust Dragon: it has to stay Level 8 for Shooting Star Dragon.)
		var spare: Array = big.filter(func(m): return m.cname() != "Stardust Dragon")
		var eat = s.pick1(p, Loc.t("%s: reduce the Level of 1 Level 5 or higher monster by 1") % c.cname(), big, spare[0] if not spare.is_empty() else big[0], c)
		eat.lv_set = eat.level() - 1
		eat.lv_turn = -1
		s.players[p].gy.erase(c)
		var up := [_ev(p, c, Loc.t("%s: %s is now Level %d") % [c.cname(), eat.cname(), eat.lv_set])]
		up.append_array(s._special(p, c, "reborn", "" if s.manual[p] else "def"))
		return up
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
	events.append({"type": "banish", "player": p, "card": c, "from": "gy"})
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
		ev.append_array(s._special(p, c, "effect", "atk" if fx(c).get("union", {}).get("atk_pos", false) else ""))
		return ev
	var hosts := s.union_hosts(p, c)
	var best = hosts[0]
	for h in hosts:
		if ps.field.has(h) == ps.field.has(best) and s.atk_of(h, false) > s.atk_of(best, false):
			best = h
	best = s.pick1(p, Loc.t("%s: equip it to which monster?") % c.cname(), hosts, best, c)
	ps.field[ps.field.find(c)] = null
	ps.spells[ps.spells.find(null)] = c
	c.equipped_to = best
	c.face_up = true
	c.attack_pos = true
	var gain := int(fx(c)["union"].get("boost", 0))
	if int(fx(c)["union"].get("boost_atk", 0)) > 0:
		return [_ev(p, c, Loc.t("%s is equipped to %s: +%d ATK") % [c.cname(), best.cname(), int(fx(c)["union"]["boost_atk"])])]
	return [_ev(p, c, Loc.t("%s is equipped to %s: +%d ATK and DEF") % [c.cname(), best.cname(), gain])]


## ATK and DEF a monster gets from the Union monsters equipped to it.
## Elemental HERO Wildedge always; Super Vehicroid - Stealth Union while it holds a monster.
static func attacks_all(s: DuelState, c) -> bool:
	if c == null:
		return false
	if fx(c).get("attack_all", false):
		return true
	return fx(c).get("stealth_union", false) and not c.negated and c.tags.has("su_eq") and s.find_uid(int(c.tags["su_eq"])) != null \
			and not s.unions_on(c).filter(func(u): return u.uid == int(c.tags["su_eq"])).is_empty()


static func union_boost(s: DuelState, c) -> int:
	var b := 0
	for u in s.unions_on(c):
		if not u.negated:
			b += int(fx(u).get("union", {}).get("boost", 0)) + int(fx(u).get("zw", {}).get("boost", 0))
	return b


## The monsters a "ZW -" card can be equipped to right now ("Utopia" monsters, or "Number C39: Utopia Ray" only).
static func _zw_hosts(s: DuelState, p: int, c) -> Array:
	var zw: Dictionary = fx(c).get("zw", {})
	if zw.is_empty() or s.players[p].spells.find(null) == -1:
		return []
	# "You can only control 1 (face-up) "ZW - ..."".
	for q in [p]:
		for st in s.players[q].spells:
			if st != null and st != c and st.face_up and st.cname() == c.cname():
				return []
	var want := str(zw.get("to", "Utopia"))
	return s.players[p].monsters().filter(func(m): return m != c and m.face_up and (m.cname().contains(want)))


## Equip a "ZW -" monster from the hand or the field to a "Utopia" monster.
static func _zw_equip(s: DuelState, p: int, c) -> Array:
	var ps := s.players[p]
	var hosts := _zw_hosts(s, p, c)
	if hosts.is_empty():
		return []
	var best = hosts[0]
	for m in hosts:
		if s.atk_of(m, false) > s.atk_of(best, false):
			best = m
	var host = s.pick1(p, Loc.t("%s: equip it to which monster?") % c.cname(), hosts, best, c)
	var events := []
	if ps.hand.has(c):
		ps.hand.erase(c)
	elif ps.field.has(c):
		for o in c.overlays:
			s._to_gy(s.players[o.owner], o)
		c.overlays.clear()
		ps.field[ps.field.find(c)] = null
		events.append_array(s._monster_left(c))
		c.reset_mods()
	var zone := ps.spells.find(null)
	c.face_up = true
	ps.spells[zone] = c
	c.equipped_to = host
	events.append({"type": "activate", "player": p, "card": c, "zone": zone})
	events.append(_ev(p, c, Loc.t("%s is equipped to %s: +%d ATK") % [c.cname(), host.cname(), int(fx(c)["zw"].get("boost", 0))]))
	return events


static func ignite_spec(c) -> Dictionary:
	if fx(c).has("union"):
		return {"label": "Equip to a partner / unequip"}
	return fx(c).get("ignite", {})


static func can_ignite(s: DuelState, p: int, c) -> bool:
	if int(s.players[p].once_names.get("#ced", -1)) == s.turn:
		return false   # Chaos Emperor Dragon: "You cannot activate other cards or effects during the turn you activate this card's effect."
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
	if ig.get("main1", false) and s.phase != DuelState.Phase.MAIN1:
		return false   # "during your Main Phase 1" (Glow Neos)
	if ig.has("need_overlay_has") and c.overlays.filter(func(o): return o.cname().contains(str(ig["need_overlay_has"]))).is_empty():
		return false   # "If this card has a "Utopia" monster as material" (Utopia Ray V)
	if ig.get("no_attack_yet", false) and ps.attacks_turn == s.turn and ps.attacks_this_turn > 0:
		return false   # "You cannot declare an attack the turn you activate this effect"
	if ig.get("not_after_double", false) and c.attack_count_turn == s.turn and c.attack_count >= 2:
		return false   # it already used its other effect this turn
	match str(ig.get("cost", "none")):
		"counter":
			if c.counter < 1:
				return false
		"tribute_self_counters":
			if c.counter < int(ig.get("counters", 3)):
				return false
		"half_lp":
			if ps.lp < 2:
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
			if ps.monsters().filter(func(m): return m != c and s.can_tribute_fx(m)).is_empty():
				return false
		"tribute_two":
			if ps.monsters().filter(func(m): return m != c and s.can_tribute_fx(m)).size() < 2:
				return false
		"send_other":
			# Tempest: "send 1 other card you control to the GY".
			if ps.monsters().size() + ps.set_cards().size() + (1 if ps.field_spell != null else 0) < 2:
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
	var ps := s.players[p]
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
			"exile_opp", "exile_opp_end", "opp_change_pos", "grand_neos":
				if opp.monsters().is_empty():
					return false
			"obelisk":
				if opp.monsters().is_empty():
					return false
			"time_wizard":
				if opp.monsters().is_empty() and s.players[p].monsters().size() < 2:
					return false
			"sirocco":
				if s.phase != DuelState.Phase.MAIN1:
					return false
			"randomizer":
				if s.players[p].deck.is_empty():
					return false
			"mill_opp_top":
				if opp.deck.is_empty():
					return false
			"majestic_red":
				if opp.monsters().filter(func(m): return m.face_up and can_target(c, m)).is_empty():
					return false
			"su_equip":
				if ps.spells.find(null) == -1 or c.tags.has("su_eq") and s.find_uid(int(c.tags["su_eq"])) != null and not s.unions_on(c).is_empty() \
						or (ps.monsters() + opp.monsters()).filter(func(m): return m != c and m.face_up and str(m.data.get("race", "")) != "Machine" and can_target(c, m)).is_empty():
					return false
			"dragoon":
				if opp.monsters().filter(func(m): return can_target(c, m)).is_empty():
					return false
			"splendid":
				if ps.gy.filter(func(g): return g.is_monster() and str(g.data.get("race", "")) == "Plant").is_empty() or opp.monsters().filter(func(m): return m.face_up and can_target(c, m)).is_empty():
					return false
			"master_key":
				if ps.monsters().filter(func(m): return m != c).is_empty() and ps.set_cards().is_empty():
					return false
			"soul_equip":
				if ps.spells.find(null) == -1 or ps.gy.filter(func(g): return g.cname().begins_with("Number")).is_empty():
					return false
			"overfiend":
				if opp.monsters().filter(func(m): return m.face_up and can_target(c, m)).is_empty():
					return false
			"ark_attach":
				if opp.monsters().filter(func(m): return m.face_up and m.attack_pos and m.tags.get("ss", false) and can_target(c, m) and not m.is_token()).is_empty():
					return false
			"dark_attach":
				if opp.monsters().filter(func(m): return m.face_up and m.tags.get("ss", false) and can_target(c, m) and not m.is_token()).is_empty():
					return false
			"rebarian":
				if ps.free_zone() == -1 or c.overlays.is_empty() or ps.gy.filter(func(g): return g.frame() == "xyz" and g.cname().begins_with("Number") and g.cname() != c.cname() and s.can_revive(g)).is_empty():
					return false
			"veiss":
				if ps.gy.filter(func(g): return g.is_monster()).is_empty() or (ps.monsters() + opp.monsters()).filter(func(m): return m.face_up and (s.atk_of(m, false) > 0)).is_empty():
					return false
			"zw_equip":
				if _zw_hosts(s, p, c).is_empty():
					return false
			"leo_arms":
				if _zw_hosts(s, p, c).is_empty() and (c.overlays.is_empty() or _take(ps.deck, {"has": "ZW -", "monster": true}, 1).is_empty()):
					return false
			"kurivolt":
				if ps.free_zone() == -1 or ps.deck.filter(func(x): return x.cname() == "Kurivolt").is_empty() \
						or (ps.monsters() + opp.monsters()).filter(func(m): return m.face_up and m.frame() == "xyz" and not m.overlays.is_empty()).is_empty():
					return false
			"terror_byte":
				if opp.monsters().filter(func(m): return m.face_up and m.attack_pos and m.level() <= 4 and m.frame() != "xyz" and can_target(c, m)).is_empty() or ps.free_zone() == -1:
					return false
			"beyond":
				if ps.free_zone() == -1 and ps.monsters().filter(func(m): return m != c and m.face_up and m.frame() == "xyz").is_empty():
					return false
				if ps.gy.filter(func(g): return g.cname().contains("Utopia") and s.can_revive(g)).is_empty() or ps.monsters().filter(func(m): return m.face_up and m.frame() == "xyz").is_empty():
					return false
			"gagaga_mancer":
				if ps.free_zone() == -1 or ps.gy.filter(func(g): return g.cname().contains("Gagaga") and g.cname() != "Gagaga Mancer" and s.can_revive(g)).is_empty():
					return false
			"scarlight":
				if opp.monsters().filter(func(m): return m.face_up and m.tags.get("ss", false) and m.frame() != "normal" and not m.is_token() and s.atk_of(m, false) <= s.atk_of(c, false)).is_empty():
					return false
			"neo_strip":
				var any_mat := false
				for m in opp.monsters():
					if not m.overlays.is_empty():
						any_mat = true
				if not any_mat:
					return false
			"laser":
				if opp.monsters().filter(func(m): return m.face_up and (s.atk_of(m, false) >= s.atk_of(c, false) or s.def_of(m) >= s.atk_of(c, false))).is_empty():
					return false
			"absorb":
				if opp.monsters().filter(func(m): return can_target(c, m) and not m.is_token()).is_empty() or s.absorbed_by(c) != null or s.players[p].spells.find(null) == -1:
					return false
			"ra_destroy":
				if s.players[p].lp <= 1000 or (opp.monsters().is_empty() and s.players[p].monsters().size() < 2):
					return false
			"aero_shark":
				if s.players[p].banished.filter(func(b): return b.is_monster()).is_empty():
					return false
			"nightmare_direct":
				if s.players[p].monsters().filter(func(m): return m.face_up and str(m.data.get("attribute", "")) == "WATER").is_empty():
					return false
			"bahamut":
				if s.players[p].free_zone() == -1 or s.players[p].extra.filter(func(x): return x.frame() == "xyz" and x.level() <= 3 and str(x.data.get("attribute", "")) == "WATER").is_empty():
					return false
			"photon_pirate":
				if s.players[p].gy.filter(func(g): return g.is_monster() and g.cname().contains("Photon")).is_empty() or (int(c.tags.get("pirate_turn", -1)) == s.turn and int(c.tags.get("pirate_n", 0)) >= 2):
					return false
			"galaxion":
				if s.players[p].free_zone() == -1 or ((s.players[p].hand.filter(func(h): return h.cname() == "Galaxy-Eyes Photon Dragon").is_empty() or c.overlays.size() < 1) \
						and (s.players[p].deck.filter(func(h): return h.cname() == "Galaxy-Eyes Photon Dragon").is_empty() or c.overlays.size() < 2)):
					return false
			"papillo":
				var any_def := false
				for q in 2:
					for m in s.players[q].monsters():
						if not m.attack_pos:
							any_def = true
				if not any_def:
					return false
			"illumiknight":
				if s.players[p].hand.is_empty() or s.players[p].deck.is_empty():
					return false
			"hundred_eyes":
				if s.players[p].gy.filter(func(g): return g.is_monster() and g.level() <= 6 and g.frame() != "xyz" and str(g.data.get("attribute", "")) == "DARK" and _is_effect_monster(g)).is_empty():
					return false
			"feather_release":
				if c.counter < 1 or opp.monsters().filter(func(m): return m.face_up).is_empty():
					return false
			"destroy_pick":
				if _pick_pool(s, p, str(a[1])).is_empty():
					return false
			"dark_panther", "volcasaurus":
				if opp.monsters().filter(func(m): return m.face_up).is_empty():
					return false
			"ray_v":
				if opp.monsters().is_empty():
					return false
			"second_attack":
				if s.players[p].monsters().filter(func(m): return m.face_up and CardEffects.matches(m.data, a[1])).is_empty():
					return false
			"aqua_dolphin", "aqua_neos", "heal_per_opp_hand":
				if opp.hand.is_empty():
					return false
			"dark_neos":
				# "If this card is not already targeting a monster with its effect".
				for q in 2:
					for m in s.players[q].monsters():
						if int(m.tags.get("neg_by", -1)) == c.uid:
							return false
				if _dark_neos_targets(s, c).is_empty():
					return false
			"glow_neos":
				if _face_up_cards(opp).is_empty():
					return false
			"storm_neos":
				if _all_st(s).is_empty():
					return false
			"card_trooper":
				if s.players[p].deck.is_empty():
					return false
			"tempest":
				if s.players[p].monsters().is_empty():
					return false
			"special_named_any":
				var any_n := false
				for src in [s.players[p].hand, s.players[p].deck, s.players[p].gy]:
					if not _take(src, {"name": str(a[1])}, 1).is_empty():
						any_n = true
				if not any_n:
					return false
			"magnet_split":
				for nm in a[1]:
					if s.players[p].gy.filter(func(g): return g.cname() == str(nm)).is_empty():
						return false
			"gandora":
				var others_n := 0
				for q in 2:
					others_n += s.players[q].monsters().size() + s.players[q].set_cards().size() + (1 if s.players[q].field_spell != null else 0)
				if others_n <= 1:
					return false
			"junk_berserker":
				if s.players[p].gy.filter(func(g): return g.is_monster() and CardEffects.matches(g.data, {"has": "Junk"})).is_empty() or s._strongest_face_up(s.opponent(p)) == null:
					return false
			"drill_warrior":
				if _drill_options(s, p, c).is_empty():
					return false
			"heal_level_other":
				if s.players[p].monsters().filter(func(m): return m != c and m.face_up and m.frame() != "xyz").is_empty():
					return false
			"ssd_excavate":
				if s.players[p].deck.is_empty() or s.phase != DuelState.Phase.MAIN1:
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
				ps = s.players[p]
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


## The face-up cards a player controls (monsters, Spells, Traps, the Field Spell).
static func _face_up_cards(ps) -> Array:
	var out: Array = ps.monsters().filter(func(m): return m.face_up)
	for st in ps.spells:
		if st != null and st.face_up:
			out.append(st)
	if ps.field_spell != null and ps.field_spell.face_up:
		out.append(ps.field_spell)
	return out


## XY-Dragon Cannon and its kind: what each may aim at on the opponent's side.
static func _pick_pool(s: DuelState, p: int, what: String) -> Array:
	var opp := s.players[s.opponent(p)]
	var out := []
	if what == "opp_fdown_mon":
		return opp.monsters().filter(func(m): return not m.face_up)
	for st in opp.spells:
		if st != null and st.face_up == (what == "opp_faceup_st"):
			out.append(st)
	if what == "opp_faceup_st" and opp.field_spell != null and opp.field_spell.face_up:
		out.append(opp.field_spell)
	return out


## Dark Neos: the face-up Effect Monsters it could aim at.
static func _dark_neos_targets(s: DuelState, c) -> Array:
	var out := []
	for q in 2:
		for m in s.players[q].monsters():
			if m != c and m.face_up and _is_effect_monster(m):
				out.append(m)
	return out


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
		"tribute_two":
			var fod: Array = ps.monsters().filter(func(m): return m != c and s.can_tribute_fx(m))
			fod.sort_custom(func(x, y): return s.atk_of(x, false) < s.atk_of(y, false))
			for m in s.choose(p, Loc.t("%s: Tribute 2 monsters") % c.cname(), fod, 2, fod.slice(0, 2), false, c):
				ps.field[ps.field.find(m)] = null
				s._to_gy(ps, m)
				events.append({"type": "tribute", "player": p, "card": m})
				events.append_array(EffectRunner.trigger(s, m, "tributed"))
				events.append_array(s._monster_left(m))
		"send_other":
			var mine_o: Array = ps.monsters().filter(func(m): return m != c)
			mine_o.append_array(ps.set_cards())
			if ps.field_spell != null:
				mine_o.append(ps.field_spell)
			var worst_o = mine_o[0]
			for x in mine_o:
				if s._card_value(x) < s._card_value(worst_o):
					worst_o = x
			worst_o = s.pick1(p, Loc.t("%s: send 1 other card you control to the Graveyard") % c.cname(), mine_o, worst_o, c)
			if ps.field.has(worst_o):
				ps.field[ps.field.find(worst_o)] = null
				s._to_gy(ps, worst_o)
				events.append({"type": "destroy", "player": p, "card": worst_o, "zone": -1, "overlays": []})
				events.append_array(s._monster_left(worst_o))
			else:
				events.append_array(s._destroy_st(worst_o))
		"half_lp":
			var half: int = ps.lp / 2
			ps.lp -= half
			events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -half})
		"tribute_self", "tribute_self_counters":
			ps.field[ps.field.find(c)] = null
			s._to_gy(ps, c)
			events.append({"type": "tribute", "player": p, "card": c})
			events.append_array(EffectRunner.trigger(s, c, "tributed"))
			events.append_array(s._monster_left(c))
		"tribute_other", "tribute_plant":
			var pick = null
			var can: Array = []
			for m in ps.monsters():
				if m == c or not s.can_tribute_fx(m):
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
			events.append_array(s._monster_left(pick))
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
	var ld = s._ladd_for(c)
	if ld != null:
		events.append_array(s._ladd_negate(ld, c))
		return events
	events.append_array(run_list(s, p, c, ig["do"], ctx))
	return events


# ------------------------------------------------------------------ Quick Effects (v0.33.28)

## Change a monster's battle position (a face-down one is turned face-up in Attack Position).
static func _flip_pos(s: DuelState, p: int, c, t) -> Array:
	var side := 0 if s.players[0].field.has(t) else 1
	if t.attack_pos:
		t.attack_pos = false
	else:
		t.attack_pos = true
		t.face_up = true
	var ev := [_ev(p, c, Loc.t("%s changes position") % t.cname()), {"type": "position", "player": side, "card": t, "zone": s.players[side].field.find(t)}]
	# An attacking monster turned to Defense Position stops attacking.
	if not s.pending_attack.is_empty() and s.pending_attack["attacker"] == t and not t.attack_pos:
		s.pending_attack["negated"] = true
	return ev


## Drill Warrior's two effects, each once per turn: which can be used right now.
static func _drill_options(s: DuelState, p: int, c) -> Array:
	var out: Array = []
	if int(c.tags.get("dw_direct", -1)) != s.turn and s.phase == DuelState.Phase.MAIN1 and s.turn > 1 and c.attack_pos:
		out.append("direct")
	if int(c.tags.get("dw_dig", -1)) != s.turn and not s.players[p].hand.is_empty():
		out.append("dig")
	return out


## The Synchro Monsters player p could make right now using `c` as one of the materials.
static func _synchro_with(s: DuelState, p: int, c) -> Array:
	var out: Array = []
	for x in s.players[p].extra:
		if x.frame() != "synchro" or s.players[p].no_summon_turn == s.turn:
			continue
		for mats in s.extra_materials(p, x):
			if mats.has(c):
				out.append({"card": x, "mats": mats})
				break
	return out


static func _is_effect_monster(m) -> bool:
	return m.is_monster() and not m.frame() in ["normal", "token"] and (m.frame() == "effect" or not CardEffects.of(m.cname()).is_empty())


## Can this card use its Quick Effect in this response window?
## Cards on the field, in the hand (Effect Veiler) and in the Graveyard (Skill Successor) are all asked.
static func quick_can(s: DuelState, p: int, c, window: String, _subject = null) -> bool:
	var kind := str(CardEffects.of(c.cname()).get("quick", ""))
	if kind == "" or s.is_over():
		return false
	var ps := s.players[p]
	var opp := s.players[s.opponent(p)]
	var on_field: bool = ps.field.has(c) and c.face_up and not c.negated
	var opp_turn: bool = s.current != p
	var hit: bool = not s.pending_attack.is_empty() and int(s.pending_attack["player"]) != p and not s.pending_attack.get("negated", false)
	if int(ps.name_lock.get(c.cname(), -1)) == s.turn:
		return false
	match kind:
		"majestic_star":
			# "when your opponent activates a card or effect: You can Tribute this card; negate the activation, and if you do, destroy all cards your opponent controls."
			return on_field and window == "chain" and not s.chain.is_empty() and int(s.chain.back()["player"]) != p and not s.chain.back().get("negated", false)
		"ssd":
			if not on_field:
				return false
			if window == "chain":
				return not s.chain.is_empty() and SpellRules.would_destroy(s.chain.back()) and int(c.tags.get("ssd_neg", -1)) != s.turn
			return window == "attack" and hit and int(c.tags.get("ssd_dodge", -1)) != s.turn
		"quasar":
			return on_field and window == "chain" and not s.chain.is_empty() and not s.chain.back().get("negated", false) and s.chain.back()["card"] != c and int(c.tags.get("q_neg", -1)) != s.turn
		"tytannial":
			# "When a card or effect is activated that targets a card(s) on the field: You can Tribute 1 face-up Plant monster; negate the activation, and if you do, destroy it."
			if not on_field or window != "chain" or s.chain.is_empty() or s.chain.back().get("negated", false) or s.chain.back()["card"] == c:
				return false
			var tl = s.chain.back().get("target")
			return tl != null and tl is DuelState.CardInst and s.on_field(tl) and not ps.monsters().filter(func(m): return m.face_up and str(m.data.get("race", "")) == "Plant" and s.can_tribute_fx(m)).is_empty()
		"junk_gardna":
			return on_field and opp_turn and c.ignite_turn != s.turn and window in ["attack", "battle_start", "phase", "summon"] and not opp.monsters().is_empty()
		"zero_gardna":
			return on_field and opp_turn and window in ["attack", "battle_start"] and ps.protect_turn != s.turn
		"ghost_gardna":
			if not on_field or window != "attack" or not hit:
				return false
			var t = s.pending_attack["target"]
			return t != null and t != c and t.face_up and ps.field.has(t) and not s.pending_attack["attacker"].tags.has("nitro_next") and not s.pending_attack.get("ghost", false)
		"effect_veiler":
			if not ps.hand.has(c) or not opp_turn or not s._in_main() or not window in ["summon", "chain", "phase"]:
				return false
			for m in opp.monsters():
				if m.face_up and not m.negated and _is_effect_monster(m):
					return true
			return false
		"formula":
			return on_field and opp_turn and s._in_main() and window in ["summon", "chain", "phase"] and not _synchro_with(s, p, c).is_empty()
		"void_ogre":
			# Void Ogre Dragon: "Once per turn, when your opponent activates a Spell/Trap Card while you have no cards in your hand".
			return on_field and window == "chain" and not s.chain.is_empty() and str(s.chain.back().get("kind", "")) in ["spell", "trap"] and int(s.chain.back()["player"]) != p \
					and not s.chain.back().get("negated", false) and ps.hand.is_empty() and int(c.tags.get("void_neg", -1)) != s.turn
		"masquerade", "c104", "djinn_buster":
			# They answer a monster effect the opponent activates (Masquerade: in a Battle Phase; C104: with Number 104 under it; Djinn Buster: for 2 materials).
			if not on_field or window != "chain" or s.chain.is_empty() or str(s.chain.back().get("kind", "")) != "fx" or int(s.chain.back()["player"]) == p or s.chain.back().get("negated", false):
				return false
			if kind == "masquerade":
				return s.phase == DuelState.Phase.BATTLE and c.overlays.size() >= 1
			if kind == "c104":
				return c.overlays.size() >= 1 and int(c.tags.get("c104_turn", -1)) != s.turn and not c.overlays.filter(func(o): return o.cname() == "Number 104: Masquerade").is_empty()
			return c.overlays.size() >= 2
		"dark_mist":
			# "Once per battle, when an attack is declared involving this card and an opponent's monster".
			if not on_field or window != "attack" or s.pending_attack.is_empty() or s.pending_attack.get("negated", false) or c.overlays.is_empty():
				return false
			var pa_a = s.pending_attack["attacker"]
			var pa_t = s.pending_attack["target"]
			if fx(c).get("storm_full", false) and c.overlays.filter(func(o): return o.cname() == "Number 96: Dark Mist").is_empty():
				return false   # (Dark Storm has this effect only with Dark Mist as material)
			return pa_t != null and (pa_a == c or pa_t == c) and int(c.tags.get("mist_n", -1)) != int(pa_a.attack_count) * 1000 + s.turn
		"paladin":
			# Dark Paladin: when a Spell Card is activated, discard 1 card: negate it and destroy it.
			return on_field and window == "chain" and not s.chain.is_empty() and str(s.chain.back().get("kind", "")) == "spell" and not s.chain.back().get("negated", false) and not ps.hand.is_empty()
		"sorcerer":
			# Sorcerer of Dark Magic: when a Trap Card is activated, negate it and destroy it.
			return on_field and window == "chain" and not s.chain.is_empty() and str(s.chain.back().get("kind", "")) == "trap" and not s.chain.back().get("negated", false)
		"joker":
			# Arcana Knight Joker: once per turn, when an effect that targets it is activated, discard the same kind of card.
			if not on_field or window != "chain" or s.chain.is_empty() or s.chain.back().get("negated", false) or s.chain.back().get("target") != c or int(c.tags.get("joker", -1)) == s.turn:
				return false
			return not _same_kind(ps.hand, s.chain.back()).is_empty()
		"big_shield":
			# Big Shield Gardna: a Spell that targets it (and nothing else) while it is face-down.
			return ps.field.has(c) and not c.face_up and window == "chain" and not s.chain.is_empty() and str(s.chain.back().get("kind", "")) == "spell" and s.chain.back().get("target") == c and not s.chain.back().get("negated", false)
		"skill_successor":
			return ps.gy.has(c) and s.current == p and c.gy_turn != s.turn and window in ["attack", "damage", "battle_start"] and s._strongest_face_up(p) != null
		"ghibli":
			return ps.hand.has(c) and window == "attack" and hit and s.pending_attack["target"] == null and ps.free_zone() != -1 and ps.no_summon_turn != s.turn
		"gagaga_gardna":
			if ps.hand.has(c):
				return window == "attack" and hit and s.pending_attack["target"] == null and ps.free_zone() != -1 and ps.no_summon_turn != s.turn
			return on_field and window == "attack" and hit and s.pending_attack["target"] == c and not ps.hand.is_empty() and s._shield != c
		"tasuke":
			return ps.gy.has(c) and window == "attack" and hit and ps.hand.is_empty() and ps.free_zone() != -1 and not ps.once_duel.has(c.cname())
		"samurai":
			return on_field and c.attack_pos and window == "attack" and hit and s.pending_attack["target"] != null and s.pending_attack["target"] != c
		"wk_lv10":
			# "During your opponent's Battle Phase (Quick Effect): You can Tribute this face-up card".
			return on_field and opp_turn and s.phase == DuelState.Phase.BATTLE and window in ["attack", "battle_start"] and s.can_tribute_fx(c)
	return false


## The cards in a hand of the same kind as the card behind a chain link (Monster, Spell or Trap).
static func _same_kind(hand: Array, link: Dictionary) -> Array:
	var k := str(link.get("kind", ""))
	return hand.filter(func(h): return (k == "fx" and h.is_monster()) or (k == "spell" and h.is_spell()) or (k == "trap" and h.is_trap()))


static func _negate_link(s: DuelState, p: int, c, link: Dictionary) -> Array:
	link["negated"] = true
	var bad = link["card"]
	var events := [_ev(p, c, Loc.t("%s negates %s and destroys it") % [c.cname(), bad.cname()])]
	var was_by := s.effect_by
	s.effect_by = p
	if bad.is_monster() and (s.players[0].field.has(bad) or s.players[1].field.has(bad)):
		events.append_array(s._destroy(bad))
	elif s.players[bad.owner].spells.has(bad) or s.players[bad.owner].field_spell == bad:
		events.append_array(s._destroy_st(bad))
	s.effect_by = was_by
	return events


## Use a Quick Effect (DuelState.respond sends every card with one here).
static func quick_run(s: DuelState, p: int, c) -> Array:
	var kind := str(CardEffects.of(c.cname()).get("quick", ""))
	var ps := s.players[p]
	var opp_i := s.opponent(p)
	var opp := s.players[opp_i]
	var events := []
	var hit: bool = not s.pending_attack.is_empty() and int(s.pending_attack["player"]) != p and not s.pending_attack.get("negated", false)
	match kind:
		"ghibli":
			ps.hand.erase(c)
			events.append(_ev(p, c, Loc.t("%s jumps in front of the direct attack") % c.cname()))
			events.append_array(s._special(p, c, "effect", "def"))
		"gagaga_gardna":
			if ps.hand.has(c):
				ps.hand.erase(c)
				events.append(_ev(p, c, Loc.t("%s jumps in front of the direct attack") % c.cname()))
				events.append_array(s._special(p, c, "effect"))
			elif not ps.hand.is_empty():
				var low = ps.hand[0]
				for h in ps.hand:
					if s._card_value(h) < s._card_value(low):
						low = h
				low = s.pick1(p, Loc.t("%s: discard 1 card") % c.cname(), ps.hand, low, c)
				ps.hand.erase(low)
				s._to_gy(ps, low)
				events.append({"type": "discard", "player": p, "card": low})
				s._shield = c
				events.append(_ev(p, c, Loc.t("%s cannot be destroyed by this battle") % c.cname()))
		"tasuke":
			ps.once_duel[c.cname()] = true
			ps.gy.erase(c)
			events.append(_ev(p, c, Loc.t("%s rises from the Graveyard and the Battle Phase ends") % c.cname()))
			events.append_array(s._special(p, c, "reborn"))
			s.pending_attack["negated"] = true
			s.players[s.current].no_attack_turn = s.turn
		"samurai":
			c.attack_pos = false
			events.append(_ev(p, c, Loc.t("%s takes the attack") % c.cname()))
			events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
			s.pending_attack["target"] = c
		"wk_lv10":
			ps.field[ps.field.find(c)] = null
			s._to_gy(ps, c)
			events.append({"type": "tribute", "player": p, "card": c})
			events.append_array(s._monster_left(c))
			var sum_w := 0
			var was_by_w := s.effect_by
			s.effect_by = p
			for m in opp.monsters():
				if m.attack_pos:
					events.append_array(s._destroy(m))
					if not opp.field.has(m):
						sum_w += m.atk()
			s.effect_by = was_by_w
			events.append(_ev(p, c, Loc.t("%s destroys every Attack Position monster: %d damage") % [c.cname(), sum_w]))
			if sum_w > 0:
				events.append_array(s._damage(opp_i, sum_w))
		"majestic_star":
			if not s.chain.is_empty() and ps.field.has(c):
				ps.field[ps.field.find(c)] = null
				s._to_gy(ps, c)
				events.append({"type": "tribute", "player": p, "card": c})
				events.append_array(s._monster_left(c))
				var link_ms: Dictionary = s.chain.back()
				link_ms["negated"] = true
				events.append(_ev(p, c, Loc.t("%s negates %s and destroys everything your opponent controls") % [c.cname(), link_ms["card"].cname()]))
				for m in opp.monsters():
					events.append_array(s._destroy(m))
				for st in opp.spells.duplicate():
					if st != null:
						events.append_array(s._destroy_st(st))
				if opp.field_spell != null:
					events.append_array(s._destroy_st(opp.field_spell))
		"ssd":
			if not s.chain.is_empty() and SpellRules.would_destroy(s.chain.back()) and int(c.tags.get("ssd_neg", -1)) != s.turn:
				c.tags["ssd_neg"] = s.turn
				events.append_array(_negate_link(s, p, c, s.chain.back()))
			elif hit and ps.field.has(c):
				var pos: bool = c.attack_pos
				events.append(_ev(p, c, Loc.t("%s vanishes and the attack is negated. It returns in the End Phase") % c.cname()))
				events.append_array(s._banish(c))
				s.pending_attack["negated"] = true
				if s.players[c.owner].banished.has(c):
					ps.exiles.append({"card": c, "to": p, "left": 0, "atk_pos": pos, "end": true})
		"quasar":
			if not s.chain.is_empty():
				c.tags["q_neg"] = s.turn
				events.append_array(_negate_link(s, p, c, s.chain.back()))
		"tytannial":
			var plants: Array = ps.monsters().filter(func(m): return m.face_up and str(m.data.get("race", "")) == "Plant" and s.can_tribute_fx(m))
			if s.chain.is_empty() or plants.is_empty():
				return events
			plants.sort_custom(func(x, y): return s.atk_of(x, false) < s.atk_of(y, false))
			var feed_t = s.pick1(p, Loc.t("%s: Tribute which Plant monster?") % c.cname(), plants, plants[0], c)
			ps.field[ps.field.find(feed_t)] = null
			s._to_gy(ps, feed_t)
			events.append({"type": "tribute", "player": p, "card": feed_t})
			events.append_array(s._monster_left(feed_t))
			events.append_array(_negate_link(s, p, c, s.chain.back()))
		"junk_gardna":
			var all_m: Array = opp.monsters()
			if not all_m.is_empty():
				c.ignite_turn = s.turn
				var auto = all_m[0]
				for m in all_m:
					if m.attack_pos and (not auto.attack_pos or s.atk_of(m, false) > s.atk_of(auto, false)):
						auto = m
				if hit and s.pending_attack["attacker"].attack_pos:
					auto = s.pending_attack["attacker"]
				var t = s.pick1(p, Loc.t("%s: change the battle position of 1 monster") % c.cname(), all_m, auto, c)
				events.append_array(_flip_pos(s, p, c, t))
		"zero_gardna":
			ps.field[ps.field.find(c)] = null
			s._to_gy(ps, c)
			events.append({"type": "tribute", "player": p, "card": c})
			events.append_array(trigger(s, c, "tributed"))
			events.append_array(s._monster_left(c))
			ps.protect_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s: no battle destruction and no battle damage for you this turn") % c.cname()))
		"ghost_gardna":
			if hit and s.pending_attack["target"] != null:
				s.pending_attack["target"] = c
				s.pending_attack["ghost"] = true
				events.append(_ev(p, c, Loc.t("%s takes the attack instead") % c.cname()))
				events.append({"type": "attack", "player": opp_i, "card": s.pending_attack["attacker"], "target": c})
		"effect_veiler":
			var cands: Array = opp.monsters().filter(func(m): return m.face_up and not m.negated and _is_effect_monster(m))
			if not cands.is_empty() and ps.hand.has(c):
				var best = cands[0]
				for m in cands:
					if s.atk_of(m, false) > s.atk_of(best, false):
						best = m
				if s.last_summoned != null and cands.has(s.last_summoned):
					best = s.last_summoned
				var t2 = s.pick1(p, Loc.t("%s: negate the effects of 1 Effect Monster until the end of this turn") % c.cname(), cands, best, c)
				ps.hand.erase(c)
				s._to_gy(ps, c)
				events.append({"type": "hand_effect", "player": p, "card": c, "text": Loc.t("%s: %s's effects are negated until the end of this turn") % [c.cname(), t2.cname()]})
				t2.negated_turn = s.turn
				t2.negated = true
		"formula":
			var opts: Array = _synchro_with(s, p, c)
			if not opts.is_empty():
				opts.sort_custom(func(x, y): return x["card"].atk() > y["card"].atk())
				var cards: Array = []
				for o in opts:
					cards.append(o["card"])
				var want = s.pick1(p, Loc.t("%s: Synchro Summon which monster?") % c.cname(), cards, cards[0], c)
				for o in opts:
					if o["card"] == want:
						events.append(_ev(p, c, Loc.t("%s: a Synchro Summon in the opponent's turn!") % c.cname()))
						events.append_array(s.extra_summon(p, want, o["mats"], true))
						break
		"masquerade", "c104", "djinn_buster":
			if s.chain.is_empty():
				return events
			for i in (2 if kind == "djinn_buster" else 1):
				s._to_gy(ps, c.overlays.pop_back())
			events.append({"type": "detach", "player": p, "card": c})
			events.append_array(_negate_link(s, p, c, s.chain.back()))
			if kind == "masquerade":
				events.append_array(s._damage(opp_i, 800))
			elif kind == "djinn_buster":
				events.append_array(s._damage(opp_i, 500))
			else:
				c.tags["c104_turn"] = s.turn
				if not opp.hand.is_empty() and s.choose_option(p, Loc.t("%s: send 1 random card from their hand to the Graveyard and halve their LP?") % c.cname(), ["Yes", "No"], 0, c) == 0:
					var rnd_c = opp.hand[randi() % opp.hand.size()]
					opp.hand.erase(rnd_c)
					s._to_gy(opp, rnd_c)
					events.append({"type": "discard", "player": opp_i, "card": rnd_c})
					var half_c: int = opp.lp / 2
					opp.lp -= half_c
					events.append({"type": "lp", "player": opp_i, "lp": opp.lp, "delta": -half_c})
		"dark_mist":
			var foe_m = s.pending_attack["target"] if s.pending_attack["attacker"] == c else s.pending_attack["attacker"]
			c.tags["mist_n"] = int(s.pending_attack["attacker"].attack_count) * 1000 + s.turn
			s._to_gy(ps, c.overlays.pop_back())
			events.append({"type": "detach", "player": p, "card": c})
			var half_m: int = s.atk_of(foe_m, false) / 2
			if fx(c).get("storm_full", false):
				# Number C96: Dark Storm: "the ATK of the opponent's monster becomes 0, and if it does, this card gains ATK equal to the original ATK of the opponent's monster."
				foe_m.atk_mod -= s.atk_of(foe_m, false)
				c.atk_mod += foe_m.atk()
				half_m = foe_m.atk()
			else:
				foe_m.atk_mod -= half_m
				c.atk_mod += half_m
			events.append(_ev(p, c, Loc.t("%s halves %s's ATK and gains %d") % [c.cname(), foe_m.cname(), half_m]))
		"void_ogre":
			if not s.chain.is_empty():
				c.tags["void_neg"] = s.turn
				events.append_array(_negate_link(s, p, c, s.chain.back()))
		"paladin":
			if not s.chain.is_empty() and not ps.hand.is_empty():
				var toss_c: Array = ps.hand.duplicate()
				toss_c.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
				var toss = s.pick1(p, Loc.t("%s: discard 1 card") % c.cname(), toss_c, toss_c[0], c)
				ps.hand.erase(toss)
				s._to_gy(ps, toss)
				events.append({"type": "discard", "player": p, "card": toss})
				events.append_array(_negate_link(s, p, c, s.chain.back()))
		"sorcerer":
			if not s.chain.is_empty():
				events.append_array(_negate_link(s, p, c, s.chain.back()))
		"joker":
			if not s.chain.is_empty():
				var same: Array = _same_kind(ps.hand, s.chain.back())
				if not same.is_empty():
					same.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
					var pay = s.pick1(p, Loc.t("%s: discard 1 card of the same kind") % c.cname(), same, same[0], c)
					ps.hand.erase(pay)
					s._to_gy(ps, pay)
					events.append({"type": "discard", "player": p, "card": pay})
					c.tags["joker"] = s.turn
					s.chain.back()["negated"] = true
					events.append(_ev(p, c, Loc.t("%s negates %s") % [c.cname(), s.chain.back()["card"].cname()]))
		"big_shield":
			if not s.chain.is_empty():
				c.face_up = true
				c.attack_pos = false
				events.append({"type": "reveal", "player": p, "card": c, "zone": ps.field.find(c)})
				s.chain.back()["negated"] = true
				events.append(_ev(p, c, Loc.t("%s negates %s") % [c.cname(), s.chain.back()["card"].cname()]))
		"skill_successor":
			if ps.gy.has(c):
				ps.gy.erase(c)
				ps.banished.append(c)
				events.append({"type": "banish", "player": p, "card": c, "from": "gy"})
				events.append_array(run(s, p, c, ["boost_own_pick", 800], {}))
	return events


## Would the computer use this Quick Effect now?
static func quick_ai(s: DuelState, p: int, c, window: String) -> bool:
	var kind := str(CardEffects.of(c.cname()).get("quick", ""))
	var ps := s.players[p]
	var hit: bool = not s.pending_attack.is_empty() and int(s.pending_attack["player"]) != p and not s.pending_attack.get("negated", false)
	var att = s.pending_attack.get("attacker") if hit else null
	var tgt = s.pending_attack.get("target") if hit else null
	# How bad is the attack in progress for player p?
	var dmg := 0
	var lose := false
	if hit:
		var a: int = s.atk_of(att, true, tgt, true)
		if tgt == null:
			dmg = a
		elif tgt.attack_pos and tgt.face_up:
			var t: int = s.atk_of(tgt, false, att, true)
			dmg = maxi(0, a - t)
			lose = a >= t
		else:
			lose = a > s.def_of(tgt)
	match kind:
		"majestic_star":
			# Worth the Tribute when their side has 3 or more cards, or this would be lost anyway.
			var theirs_ms: int = s.players[s.opponent(p)].monsters().size() + s.players[s.opponent(p)].set_cards().size()
			return theirs_ms >= 3 or SpellRules.would_destroy(s.chain.back())
		"ssd":
			if window == "chain":
				return not s.chain.is_empty() and int(s.chain.back()["player"]) != p
			return hit and (lose or dmg >= 1000 or dmg >= ps.lp)
		"quasar":
			return not s.chain.is_empty() and int(s.chain.back()["player"]) != p
		"tytannial":
			return not s.chain.is_empty() and int(s.chain.back()["player"]) != p
		"junk_gardna":
			return window == "attack" and hit and att.attack_pos and (lose or dmg >= 1000 or dmg >= ps.lp) and s.def_of(att) < 2500
		"zero_gardna":
			return window == "attack" and hit and (dmg >= 1500 or dmg >= ps.lp or (lose and tgt != c and s.atk_of(tgt, false) >= 1500) or tgt == c)
		"ghost_gardna":
			if not hit or tgt == null or not lose:
				return false
			return (not c.attack_pos and s.def_of(c) >= s.atk_of(att, true, c, true)) or s.atk_of(tgt, false) >= 1800
		"effect_veiler":
			var sub = s.last_summoned
			if window == "summon" and sub != null and sub.owner != p and _is_effect_monster(sub) and not sub.negated:
				return sub.frame() in ["synchro", "xyz", "fusion", "ritual"] or sub.atk() >= 2300
			return false
		"formula":
			for o in _synchro_with(s, p, c):
				if o["card"].atk() >= 2500:
					return true
			return false
		"paladin":
			return not s.chain.is_empty() and int(s.chain.back()["player"]) != p and ps.hand.size() >= 1
		"dark_mist":
			return true
		"sorcerer", "joker", "big_shield", "void_ogre", "masquerade", "c104", "djinn_buster":
			return not s.chain.is_empty() and int(s.chain.back()["player"]) != p
		"ghibli":
			return dmg >= 1000 or dmg >= ps.lp
		"gagaga_gardna":
			if ps.hand.has(c):
				return dmg >= 1000 or dmg >= ps.lp
			return lose and ps.hand.size() >= 2
		"tasuke":
			return dmg >= 1000 or dmg >= ps.lp or lose
		"samurai":
			return lose and tgt != null and s.def_of(c) > s.atk_of(att, true, c, true)
		"wk_lv10":
			var sum_k := 0
			var n_k := 0
			for m in s.players[s.opponent(p)].monsters():
				if m.attack_pos:
					sum_k += m.atk()
					n_k += 1
			return n_k >= 1 and (sum_k >= s.players[s.opponent(p)].lp or n_k >= 2 or sum_k >= 2000)
		"skill_successor":
			if s.pending_attack.is_empty() or window == "battle_start":
				return false
			var mine = null
			var foe = null
			for pair in [[s.pending_attack["attacker"], s.pending_attack["target"]], [s.pending_attack["target"], s.pending_attack["attacker"]]]:
				if pair[0] != null and ps.field.has(pair[0]):
					mine = pair[0]
					foe = pair[1]
			if mine == null or foe == null or not mine.face_up:
				return false
			var a0: int = s.atk_of(mine, true, foe, true)
			var b0: int = s.atk_of(foe, false, mine, true) if foe.attack_pos else s.def_of(foe)
			return a0 <= b0 and a0 + 800 > b0
	return false


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
		if str(a[0]) == "need_was_atk":
			# "When this Attack Position card is destroyed..." (Umbral Horror Will o' the Wisp).
			if not c.attack_pos:
				break
			continue
		if str(a[0]) == "need_attacking":
			# "...while attacking a monster" (Umbral Horror Unform).
			if s.battle_attacker != c or not s.battle_vs_monster:
				break
			continue
		if str(a[0]) == "need_hit_direct":
			# "...inflicts Battle Damage to your opponent by a direct attack" (Drill Barnacle).
			if int(c.tags.get("hit_direct", -1)) != s.turn or s.battle_vs_monster:
				break
			continue
		if str(a[0]) == "need_older":
			# "You cannot activate this effect the turn this card is Summoned or flipped face-up."
			if c.summoned_turn == s.turn:
				break
			continue
		if str(a[0]) == "need_tag_before":
			# Something that happened in an earlier turn (Silent Swordsman LV5 dealt direct damage, Silent Magician LV4 got its 5th counter).
			if not c.tags.has(str(a[1])) or int(c.tags[str(a[1])]) >= s.turn:
				break
			continue
		if str(a[0]) == "need_summoned_now":
			if c.summoned_turn != s.turn:
				break
			continue
		if str(a[0]) == "ask":
			# "You can": the player says yes or no (the computer says yes).
			if s.choose_option(p, "%s: %s" % [c.cname(), Loc.t(str(a[1]))], ["Yes", "No"], 0, c) != 0:
				break
			continue
		if str(a[0]) == "need_deck":
			# ["need_deck", filter, n]: exactly n of them must be there to come out, with room for all.
			var free_n := 0
			for z in s.players[p].field:
				if z == null:
					free_n += 1
			if _take(s.players[p].deck, a[1], int(a[2])).size() < int(a[2]) or free_n < int(a[2]):
				break
			continue
		events.append_array(run(s, p, c, a, ctx))
	s.effect_by = was_by
	return events


## Turbo Warrior: "This card cannot be targeted by the effects of Level 6 or lower monsters."
static func can_target(src, m) -> bool:
	if src != null and m != null and m.has_meta("zw_untarget_owner") and src.owner != m.owner:
		return false
	if m != null and m.face_up and (m.tags.get("no_target", false) or (not m.negated and CardEffects.of(m.cname()).get("untargetable", false))):
		return false   # Lord of D. is up and this is a Dragon / "Neither player can target this card with card effects" (Obelisk)
	if src == null or m == null or not src.is_monster() or src.frame() == "xyz" or not m.face_up or m.negated:
		return true
	var cap := int(CardEffects.of(m.cname()).get("untargetable_lv_max", 0))
	return cap == 0 or src.level() > cap


## Would the computer want to use this monster's ignition effect right now? The rules allow it;
## this is only judgement (never spend Zero Gardna in your own turn, and so on).
static func ai_ignite_ok(s: DuelState, p: int, c) -> bool:
	var f := fx(c)
	var ps := s.players[p]
	var opp := s.players[s.opponent(p)]
	if f.has("union") and f["union"].get("any", false):
		return not ps.spells.has(c) and not ps.monsters().filter(func(m): return m != c and m.face_up).is_empty()
	match str(ignite_spec(c).get("ai", "")):
		"never":
			return false
		"spare_card":
			# An effect that costs a discard (Aqua Dolphin, Aqua Neos): only with a card to spare.
			return ps.hand.size() >= 2 and not opp.hand.is_empty()
		"opp_st":
			# Wild Wingman: when the opponent has a Spell or Trap to hit.
			return ps.hand.size() >= 2 and (not opp.set_cards().is_empty() or opp.field_spell != null)
		"ced":
			# Chaos Emperor Dragon: when they have more on the table and in hand than you do, and it does not cost the duel.
			var mine_c: int = ps.hand.size() + ps.monsters().size() + ps.set_cards().size()
			var theirs_c: int = opp.hand.size() + opp.monsters().size() + opp.set_cards().size()
			return ps.lp > 2000 and theirs_c >= mine_c + 2
		"time_wizard":
			# Worth the coin when there is more to win than to lose.
			var mine_tw := 0
			for m in ps.monsters():
				if m.face_up:
					mine_tw += s.atk_of(m, false)
			var theirs_tw := 0
			for m in opp.monsters():
				theirs_tw += maxi(1200, s.atk_of(m, false))
			return not opp.monsters().is_empty() and theirs_tw >= mine_tw + 1000 and ps.lp > mine_tw / 2 + 1000
		"obelisk":
			var gain_o := 0
			for m in opp.monsters():
				gain_o += maxi(1000, s.atk_of(m, false))
			return opp.monsters().size() >= 2 and gain_o >= 3500
		"storm":
			var theirs_st: int = opp.set_cards().size() + (1 if opp.field_spell != null else 0)
			var mine_st: int = ps.set_cards().size() + (1 if ps.field_spell != null else 0)
			return theirs_st > mine_st
		"dark_neos":
			for m in opp.monsters():
				if m.face_up and _is_effect_monster(m) and not m.negated:
					return true
			return false
		"glow_neos":
			# Take a monster only when it is the one in the way; a face-up Spell or Trap is always worth it.
			for x in _face_up_cards(opp):
				if not x.is_monster():
					return true
			var top := 0
			for m in opp.monsters():
				if m.face_up:
					top = maxi(top, s.atk_of(m, false) if m.attack_pos else s.def_of(m))
			return top >= s.atk_of(c, false)
		"trooper":
			return ps.deck.size() >= 12
		"before_battle":
			return s.phase == DuelState.Phase.MAIN1 and s.turn > 1 and not opp.monsters().is_empty()
		"papillo":
			return not opp.monsters().filter(func(m): return not m.attack_pos).is_empty()
		"ra":
			var top_ra = s._strongest_face_up(s.opponent(p))
			return ps.lp > 3000 and top_ra != null and s.atk_of(top_ra, false) >= 2000
		"nightmare":
			# Worth it when the way is blocked and the direct hit is big.
			var top_w := 0
			for m in ps.monsters():
				if m.face_up and str(m.data.get("attribute", "")) == "WATER":
					top_w = maxi(top_w, s.atk_of(m, false))
			return s.phase == DuelState.Phase.MAIN1 and s.turn > 1 and not opp.monsters().is_empty() and (top_w >= opp.lp or (top_w >= 2000 and s._strongest_face_up(s.opponent(p)) != null and s.atk_of(s._strongest_face_up(s.opponent(p)), false) >= top_w))
		"spare_hand":
			return ps.hand.size() >= 2
		"catapult":
			# Only for the win: the biggest monster's half ATK finishes the duel.
			var top_atk := 0
			for m in ps.monsters():
				top_atk = maxi(top_atk, s.atk_of(m, false))
			return top_atk / 2 >= opp.lp
		"gandora":
			# When the other side has clearly more on the field, and the Life Points can take it.
			var theirs_n: int = opp.monsters().size() + opp.set_cards().size()
			var mine_n: int = ps.monsters().size() - 1 + ps.set_cards().size()
			return ps.lp >= 3000 and theirs_n >= mine_n + 2
		"ssd":
			# Worth it when the Deck is thick with Tuners: no Tuner among the five means no attack.
			var tuners := ps.deck.filter(func(d): return d.is_monster() and d.is_tuner()).size()
			return ps.deck.size() >= 5 and tuners * 4 >= ps.deck.size()
		"drill":
			if not _drill_options(s, p, c).has("direct") or opp.monsters().is_empty():
				return false
			var mine: int = s.atk_of(c, false)
			var wall := 0
			for m in opp.monsters():
				wall = maxi(wall, s.atk_of(m, false) if m.attack_pos and m.face_up else s.def_of(m))
			return mine / 2 >= opp.lp or wall >= mine
	return true


static func ai_gy_ok(s: DuelState, p: int, c) -> bool:
	var g: Dictionary = fx(c).get("gy_ignite", {})
	if str(g.get("ai", "")) == "never":
		return false
	if g.get("level_eater", false):
		# Only as Synchro fodder: with a Tuner of yours on the field and room to spare.
		var free := 0
		for z in s.players[p].field:
			if z == null:
				free += 1
		return free >= 2 and not s.players[p].monsters().filter(func(m): return m.face_up and m.is_tuner()).is_empty() \
				and not _lv5_up(s, p).filter(func(m): return m.cname() != "Stardust Dragon").is_empty()
	return true


## One of the opponent's monsters: the effect's controller picks, the rules default to the strongest.
static func _best_opp(s: DuelState, p: int, filter := "", c = null, prompt := "Choose 1 of your opponent's monsters") -> Variant:
	var best = null
	var cands: Array = []
	for m in s.players[s.opponent(p)].monsters():
		if filter == "atk_pos" and not (m.face_up and m.attack_pos):
			continue
		if not can_target(c, m):
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
		if CardEffects.matches(x.data, f) and (not CardData.is_extra(x.id) or f.get("extra_ok", false)):
			all.append(x)
	return s.choose(p, "%s: %s" % [c.cname(), prompt], all, auto.size(), auto, false, c)


static func _take(arr: Array, f: Dictionary, n: int) -> Array:
	var out := []
	for x in arr:
		if out.size() >= n:
			break
		if CardEffects.matches(x.data, f) and (not CardData.is_extra(x.id) or f.get("extra_ok", false)):
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
		"ced":
			# Chaos Emperor Dragon - Envoy of the End: "pay 1000 LP; send as many cards in both players' hands and on the field as possible
			# to the GY, then inflict 300 damage to your opponent for each card sent to the opponent's GY by this effect."
			if ps.lp <= 1000:
				return events
			ps.lp -= 1000
			events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -1000})
			ps.once_names["#ced"] = s.turn
			var to_opp := 0
			for q in 2:
				var pq := s.players[q]
				for h in pq.hand.duplicate():
					pq.hand.erase(h)
					s._to_gy(pq, h)
					events.append({"type": "discard", "player": q, "card": h})
					if q == opp_i:
						to_opp += 1
				for z in 5:
					var fm = pq.field[z]
					if fm == null:
						continue
					var home_c: int = fm.orig_owner if fm.orig_owner != -1 else fm.owner
					if home_c == opp_i and not fm.is_token():
						to_opp += 1
					pq.field[z] = null
					s._to_gy(pq, fm)
					events.append({"type": "destroy", "player": q, "card": fm, "zone": z})
					events.append_array(s._monster_left(fm))
				for st in pq.spells.duplicate():
					if st != null:
						if st.owner == opp_i:
							to_opp += 1
						events.append_array(s._destroy_st(st))
				if pq.field_spell != null:
					if pq.field_spell.owner == opp_i:
						to_opp += 1
					events.append_array(s._destroy_st(pq.field_spell))
			events.append(_ev(p, c, Loc.t("%s: %d cards to the opponent's Graveyard") % [name, to_opp]))
			if to_opp > 0:
				events.append_array(s._damage(opp_i, 300 * to_opp))
		"metal_up":
			# Red-Eyes Black Metal Dragon: "Special Summoned (from your Deck) by Tributing "Red-Eyes Black Dragon" equipped with "Metalmorph"."
			var metal: Array = ps.deck.filter(func(x): return x.cname() == "Red-Eyes Black Metal Dragon")
			if metal.is_empty() or not ps.field.has(c):
				return events
			var z_m := ps.field.find(c)
			ps.field[z_m] = null
			s._to_gy(ps, c)
			events.append({"type": "tribute", "player": p, "card": c})
			events.append_array(s._monster_left(c))
			var rb = metal[0]
			ps.deck.erase(rb)
			s._shuffle(ps.deck)
			rb.proper = true
			events.append(_ev(p, c, Loc.t("%s calls %s") % [name, rb.cname()]))
			events.append_array(s._special(p, rb, "effect", "atk"))
			events.append_array(on_summon(s, p, rb, "special"))
		"yubel_next":
			# Yubel: "When this card is destroyed, except by its own effect: Its owner can Special Summon 1 "Yubel - Terror Incarnate" from
			# their hand, Deck, or GY." / Terror Incarnate: "When this face-up card leaves the field: You can Special Summon 1 "Yubel - The Ultimate Nightmare"".
			if c.cname() == "Yubel" and int(c.get_meta("yubel_self", -1)) == s.turn:
				return events
			var want_y := str(a[1])
			var pool_y: Array = (ps.hand + ps.deck + ps.gy).filter(func(x): return x.cname() == want_y)
			if pool_y.is_empty() or ps.free_zone() == -1 or s.is_over():
				return events
			if s.choose_option(p, Loc.t("%s: Special Summon %s?") % [name, want_y], ["Special Summon it", "No"], 0, c) != 0:
				return events
			var ny = pool_y[0]
			if ps.deck.has(ny):
				ps.deck.erase(ny)
				s._shuffle(ps.deck)
			ps.hand.erase(ny)
			ps.gy.erase(ny)
			ny.proper = true
			events.append(_ev(p, c, Loc.t("%s calls %s") % [name, ny.cname()]))
			events.append_array(s._special(p, ny, "effect", "atk"))
			events.append_array(on_summon(s, p, ny, "special"))
		"ladd_burst":
			# Light and Darkness Dragon: "Target 1 monster in your GY (if possible); destroy all cards you control, also, after that, Special Summon that monster (if any)."
			var back_l: Array = ps.gy.filter(func(g): return g != c and g.is_monster() and s.can_revive(g))
			var pick_l = null
			if not back_l.is_empty():
				back_l.sort_custom(func(x, y): return x.atk() > y.atk())
				pick_l = s.pick1(p, Loc.t("%s: which monster comes back?") % name, back_l, back_l[0], c)
			for m in ps.monsters():
				events.append_array(s._destroy(m))
			for st in ps.spells.duplicate():
				if st != null:
					events.append_array(s._destroy_st(st))
			if ps.field_spell != null:
				events.append_array(s._destroy_st(ps.field_spell))
			if pick_l != null and ps.gy.has(pick_l) and ps.free_zone() != -1 and not s.is_over():
				ps.gy.erase(pick_l)
				events.append(_ev(p, c, Loc.t("%s calls %s") % [name, pick_l.cname()]))
				events.append_array(s._special(p, pick_l, "reborn"))
				events.append_array(on_summon(s, p, pick_l, "special"))
		"big_lock":
			# Crimson Blader: "Your opponent cannot Normal or Special Summon Level 5 or higher monsters during their next turn."
			opp.once_names["#no_big"] = s.turn + 1
			events.append(_ev(p, c, Loc.t("%s: no Level 5 or higher Summons in the opponent's next turn") % name))
		"majestic_red":
			# Majestic Red Dragon: "target 1 face-up monster your opponent controls; negate its effects, and if you do, this card gains ATK equal to that monster's ATK."
			var tg_m: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if tg_m.is_empty():
				return events
			var best_m = tg_m[0]
			for m in tg_m:
				if s.atk_of(m, false) > s.atk_of(best_m, false):
					best_m = m
			best_m = s.pick1(p, Loc.t("%s: negate which monster?") % name, tg_m, best_m, c)
			best_m.negated_turn = s.turn
			best_m.negated = true
			var gain_m: int = s.atk_of(best_m, false)
			if c.atk_mod_turn != s.turn:
				c.atk_mod_t = 0
			c.atk_mod_turn = s.turn
			c.atk_mod_t += gain_m
			events.append(_ev(p, c, Loc.t("%s gains %d ATK") % [name, gain_m]))
		"gilford":
			# Gilford the Lightning: Tribute Summoned with 3 Tributes: "Destroy all monsters your opponent controls."
			if int(c.tags.get("tributes_n", 0)) >= 3:
				for m in opp.monsters():
					events.append_array(s._destroy(m))
		"dmk":
			# Dark Magician Knight: "When this card is Special Summoned: Target 1 card on the field; destroy that target."
			events.append_array(run_list(s, p, c, [["destroy", "any_pick"]], ctx))
		"viser_mark":
			# Viser Des: "Target 1 monster your opponent controls" (destroyed in your 3rd Standby Phase after this).
			var vs_t: Array = opp.monsters().filter(func(m): return can_target(c, m))
			if not vs_t.is_empty():
				var best_v = vs_t[0]
				for m in vs_t:
					if (s.atk_of(m, false) if m.face_up else 1500) > (s.atk_of(best_v, false) if best_v.face_up else 1500):
						best_v = m
				best_v = s.pick1(p, Loc.t("%s: mark which monster?") % name, vs_t, best_v, c)
				c.tags["viser_t"] = best_v.uid
				c.tags["viser_n"] = 0
				events.append(_ev(p, c, Loc.t("%s marks %s: it is destroyed in your 3rd Standby Phase") % [name, best_v.cname() if best_v.face_up else Loc.t("a face-down monster")]))
		"gagaga_lock":
			# Gagaga Head: "also you cannot Special Summon monsters for the rest of this turn, except by an Xyz Summon that uses only "Gagaga" monsters as materials."
			ps.once_names["#gagaga_lock"] = s.turn
		"no_attack_self":
			c.tags["sct_turn"] = s.turn   # Super Conductor Tyranno: "This card cannot declare an attack the turn this effect is activated."
		"su_equip":
			# Super Vehicroid - Stealth Union: "target 1 face-up non-Machine monster on the field; equip that target to this card."
			var nm: Array = (opp.monsters() + ps.monsters()).filter(func(m): return m != c and m.face_up and str(m.data.get("race", "")) != "Machine" and can_target(c, m))
			var zone_u: int = ps.spells.find(null)
			if nm.is_empty() or zone_u == -1:
				return events
			var best_u = nm[0]
			for m in nm:
				if (m.owner != p and best_u.owner == p) or (m.owner == best_u.owner and s.atk_of(m, false) > s.atk_of(best_u, false)):
					best_u = m
			best_u = s.pick1(p, Loc.t("%s: equip which monster?") % name, nm, best_u, c)
			var from_q := s.players[best_u.owner]
			from_q.field[from_q.field.find(best_u)] = null
			events.append_array(s._monster_left(best_u))
			best_u.reset_mods()
			if best_u.orig_owner == -1 and best_u.owner != p:
				best_u.orig_owner = best_u.owner
			best_u.owner = p
			best_u.face_up = true
			ps.spells[zone_u] = best_u
			best_u.equipped_to = c
			c.tags["su_eq"] = best_u.uid
			events.append({"type": "activate", "player": p, "card": best_u, "zone": zone_u})
			events.append(_ev(p, c, Loc.t("%s takes %s: it can attack every monster") % [name, best_u.cname()]))
		"dragoon":
			# Destiny End Dragoon: "target 1 monster your opponent controls; destroy that target, and if it was face-up, inflict damage
			# to your opponent equal to the ATK it had on the field. You cannot conduct your Battle Phase the turn you activate this effect."
			var tg_d: Array = opp.monsters().filter(func(m): return can_target(c, m))
			if tg_d.is_empty():
				return events
			var best_g = tg_d[0]
			for m in tg_d:
				if (s.atk_of(m, false) if m.face_up else 0) > (s.atk_of(best_g, false) if best_g.face_up else 0):
					best_g = m
			best_g = s.pick1(p, Loc.t("%s: destroy which monster?") % name, tg_d, best_g, c)
			var dmg_g: int = s.atk_of(best_g, false) if best_g.face_up else 0
			events.append_array(s._destroy(best_g))
			if dmg_g > 0 and not opp.field.has(best_g):
				events.append_array(s._damage(s.opponent(p), dmg_g))
			ps.no_attack_turn = s.turn
		"cyberdark":
			# Cyberdark Horn / Edge / Keel (Level 3 or lower) and Cyberdark Dragon (any): equip a Dragon from your GY; gain its original ATK.
			var zone_cd: int = ps.spells.find(null)
			var drs: Array = ps.gy.filter(func(g): return g.is_monster() and str(g.data.get("race", "")) == "Dragon" and g.level() <= int(a[1]))
			if drs.is_empty() or zone_cd == -1 or s.absorbed_by(c) != null:
				return events
			var best_d = drs[0]
			for g in drs:
				if g.atk() > best_d.atk():
					best_d = g
			best_d = s.pick1(p, Loc.t("%s: equip which Dragon from your Graveyard?") % name, drs, best_d, c)
			ps.gy.erase(best_d)
			best_d.face_up = true
			ps.spells[zone_cd] = best_d
			best_d.equipped_to = c
			c.tags["absorbed"] = best_d.uid
			events.append({"type": "activate", "player": p, "card": best_d, "zone": zone_cd})
			events.append(_ev(p, c, Loc.t("%s takes %s: +%d ATK") % [name, best_d.cname(), best_d.atk()]))
		"splendid":
			# Splendid Rose: "banish 1 Plant-Type monster from your Graveyard, then target 1 face-up monster your opponent controls; halve that target's ATK, until the end of this turn."
			var pl: Array = ps.gy.filter(func(g): return g.is_monster() and str(g.data.get("race", "")) == "Plant")
			var tg_s: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if pl.is_empty() or tg_s.is_empty():
				return events
			events.append_array(s._banish(pl[0]))
			var best_s = tg_s[0]
			for m in tg_s:
				if s.atk_of(m, false) > s.atk_of(best_s, false):
					best_s = m
			best_s = s.pick1(p, Loc.t("%s: halve whose ATK?") % name, tg_s, best_s, c)
			var half_s: int = s.atk_of(best_s, false) / 2
			if best_s.atk_mod_turn != s.turn:
				best_s.atk_mod_t = 0
			best_s.atk_mod_turn = s.turn
			best_s.atk_mod_t -= half_s
			events.append(_ev(p, c, Loc.t("%s halves %s's ATK") % [name, best_s.cname()]))
		"master_key":
			# Number 66: "target 1 other card you control" (it cannot be destroyed by card effects; it can go to the Graveyard in this card's place).
			var keys: Array = ps.monsters().filter(func(m): return m != c)
			keys.append_array(ps.set_cards())
			if keys.is_empty():
				return events
			var best_k = keys[0]
			for k in keys:
				if k.is_monster() and (not best_k.is_monster() or k.atk() > best_k.atk()):
					best_k = k
			best_k = s.pick1(p, Loc.t("%s: which card holds the key?") % name, keys, best_k, c)
			c.tags["key_to"] = best_k.uid
			best_k.tags["key_by"] = c.uid
			events.append(_ev(p, c, Loc.t("%s guards %s") % [name, best_k.cname()]))
		"soul_equip":
			# Number 43: "target 1 "Number" monster in your Graveyard; equip that target to this card."
			var nn: Array = ps.gy.filter(func(g): return g.cname().begins_with("Number"))
			var zone_n: int = ps.spells.find(null)
			if nn.is_empty() or zone_n == -1:
				return events
			var eq_n = s.pick1(p, Loc.t("%s: equip which Number?") % name, nn, nn[0], c)
			ps.gy.erase(eq_n)
			eq_n.face_up = true
			ps.spells[zone_n] = eq_n
			eq_n.equipped_to = c
			events.append({"type": "activate", "player": p, "card": eq_n, "zone": zone_n})
		"overfiend":
			# Number C65: "target 1 face-up monster your opponent controls; it loses 1000 ATK and DEF."
			var of: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if not of.is_empty():
				var t_o = of[0]
				for m in of:
					if s.atk_of(m, false) > s.atk_of(t_o, false):
						t_o = m
				t_o = s.pick1(p, Loc.t("%s: which monster loses 1000 ATK and DEF?") % name, of, t_o, c)
				t_o.atk_mod -= 1000
				t_o.def_mod -= 1000
				events.append(_ev(p, c, Loc.t("%s loses 1000 ATK and DEF") % t_o.cname()))
		"ark_attach", "dark_attach":
			# Number 101 / C101: "target 1 Special Summoned monster your opponent controls (in face-up Attack Position); attach it to this card as material."
			var prey: Array = opp.monsters().filter(func(m): return m.face_up and (m.attack_pos or a[0] == "dark_attach") and m.tags.get("ss", false) and can_target(c, m) and not m.is_token())
			if prey.is_empty():
				return events
			var best_p = prey[0]
			for m in prey:
				if s.atk_of(m, false) > s.atk_of(best_p, false):
					best_p = m
			best_p = s.pick1(p, Loc.t("%s: attach which monster?") % name, prey, best_p, c)
			opp.field[opp.field.find(best_p)] = null
			for o in best_p.overlays:
				s._to_gy(s.players[o.owner], o)
			best_p.overlays.clear()
			events.append_array(s._monster_left(best_p))
			best_p.reset_mods()
			c.overlays.append(best_p)
			events.append(_ev(p, c, Loc.t("%s takes %s as material") % [name, best_p.cname()]))
		"rebarian":
			# Number 71: "target 1 "Number" Xyz Monster in your GY, except this; Special Summon it, and if you do, attach 1 material from this card to it."
			var nums: Array = ps.gy.filter(func(g): return g.frame() == "xyz" and g.cname().begins_with("Number") and g.cname() != c.cname() and s.can_revive(g))
			if nums.is_empty():
				return events
			var best_n = nums[0]
			for g in nums:
				if g.atk() > best_n.atk():
					best_n = g
			best_n = s.pick1(p, Loc.t("%s: Special Summon which Number?") % name, nums, best_n, c)
			ps.gy.erase(best_n)
			events.append_array(s._special(p, best_n, "reborn"))
			if ps.field.has(best_n) and not c.overlays.is_empty():
				best_n.overlays.append(c.overlays.pop_back())
		"splash":
			# Number 73: "double this card's ATK until the end of your opponent's turn, also, any battle damage it inflicts to your opponent this turn is halved."
			c.tmp_atk = s.atk_of(c, false)
			c.tmp_until = s.turn + 1
			c.tags["splash_turn"] = s.turn
			events.append(_ev(p, c, Loc.t("%s doubles its ATK") % name))
		"veiss":
			# Number C32: "If your LP are 1000 or less: banish 1 monster from your GY and detach 1 material, then target 1 face-up monster on the field; its ATK/DEF become 0 until the end of your turn."
			var fuel_v: Array = ps.gy.filter(func(g): return g.is_monster())
			var tg_v: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if fuel_v.is_empty() or tg_v.is_empty():
				return events
			events.append_array(s._banish(fuel_v[0]))
			var best_v = tg_v[0]
			for m in tg_v:
				if s.atk_of(m, false) > s.atk_of(best_v, false):
					best_v = m
			best_v = s.pick1(p, Loc.t("%s: which monster goes to 0?") % name, tg_v, best_v, c)
			if best_v.atk_mod_turn != s.turn:
				best_v.atk_mod_t = 0
			best_v.atk_mod_turn = s.turn
			best_v.atk_mod_t -= s.atk_of(best_v, false)
			events.append(_ev(p, c, Loc.t("%s: %s has 0 ATK this turn") % [name, best_v.cname()]))
		"zw_equip":
			events.append_array(_zw_equip(s, p, c))
		"leo_arms":
			# ZW - Leo Arms: equip itself to a "Utopia" monster (+3000), or detach 1 to add a "ZW -" monster from the Deck.
			if not _zw_hosts(s, p, c).is_empty():
				events.append_array(_zw_equip(s, p, c))
			elif not c.overlays.is_empty():
				var o_l = c.overlays[0]
				c.overlays.erase(o_l)
				s.players[o_l.owner].gy.append(o_l)
				events.append_array(run_list(s, p, c, [["search", {"has": "ZW -", "monster": true}]], ctx))
		"kurivolt":
			# Kurivolt: "target 1 Xyz Monster that has material; detach 1 material from it, and if you do, Special Summon 1 "Kurivolt" from your Deck."
			var xs: Array = (opp.monsters() + ps.monsters()).filter(func(m): return m.face_up and m.frame() == "xyz" and not m.overlays.is_empty())
			if xs.is_empty():
				return events
			var x_k = s.pick1(p, Loc.t("%s: detach 1 material from which Xyz Monster?") % name, xs, xs[0], c)
			var o_k = x_k.overlays[0]
			x_k.overlays.erase(o_k)
			s.players[o_k.owner].gy.append(o_k)
			var kv: Array = ps.deck.filter(func(x): return x.cname() == "Kurivolt")
			if not kv.is_empty() and ps.free_zone() != -1:
				ps.deck.erase(kv[0])
				events.append_array(s._special(p, kv[0], "effect"))
		"terror_byte":
			# Number 34: "target 1 Level 4 or lower Attack Position monster your opponent controls; gain control of it until the End Phase."
			var tb: Array = opp.monsters().filter(func(m): return m.face_up and m.attack_pos and m.level() <= 4 and m.frame() != "xyz" and can_target(c, m))
			if not tb.is_empty():
				var best_t = tb[0]
				for m in tb:
					if s.atk_of(m, false) > s.atk_of(best_t, false):
						best_t = m
				events.append_array(s._take_control(s.pick1(p, Loc.t("%s: take which monster?") % name, tb, best_t, c), p, s.turn))
		"zero_opp":
			# Number 39: Utopia Beyond: "If this card is Xyz Summoned: The ATK of all monsters your opponent currently controls become 0."
			for m in opp.monsters():
				if m.face_up:
					m.zero_perm = true
			events.append(_ev(p, c, Loc.t("%s: the opponent's monsters have 0 ATK") % name))
		"beyond":
			# "banish a face-up Xyz Monster you control, and if you do, Special Summon a "Utopia" monster from your GY, then gain 1250 LP."
			var xb: Array = ps.monsters().filter(func(m): return m.face_up and m.frame() == "xyz" and m != c)
			if xb.is_empty():
				xb = [c]
			var gone_b = s.pick1(p, Loc.t("%s: banish which Xyz Monster?") % name, xb, xb[0], c)
			events.append_array(s._banish(gone_b))
			var back_b: Array = ps.gy.filter(func(g): return g.cname().contains("Utopia") and s.can_revive(g))
			if not back_b.is_empty() and ps.free_zone() != -1:
				var best_b = back_b[0]
				for g in back_b:
					if g.atk() > best_b.atk():
						best_b = g
				ps.gy.erase(best_b)
				events.append_array(s._special(p, best_b, "reborn"))
				events.append_array(run_list(s, p, c, [["heal", 1250]], ctx))
		"gagaga_mancer":
			var gm: Array = ps.gy.filter(func(g): return g.cname().contains("Gagaga") and g.cname() != "Gagaga Mancer" and s.can_revive(g))
			if not gm.is_empty() and ps.free_zone() != -1:
				var pick_g = gm[0]
				for g in gm:
					if g.atk() > pick_g.atk():
						pick_g = g
				pick_g = s.pick1(p, Loc.t("%s: Special Summon which Gagaga monster?") % name, gm, pick_g, c)
				ps.gy.erase(pick_g)
				events.append_array(s._special(p, pick_g, "reborn"))
		"zubaba_buster":
			# Zubaba Buster: "Destroy the 1 face-up monster on the field that has the lowest ATK, and if you do, this card loses 800 ATK."
			var low_z = null
			for q in [opp, ps]:
				for m in q.monsters():
					if m.face_up and (low_z == null or s.atk_of(m, false) < s.atk_of(low_z, false)):
						low_z = m
			if low_z != null:
				events.append_array(s._destroy(low_z))
				if ps.field.has(c):
					c.atk_mod -= 800
		"chain_resonator":
			# Chain Resonator: "When this card is Normal Summoned while a Synchro Monster is on the field: You can Special
			# Summon 1 "Resonator" monster from your Deck, except "Chain Resonator"."
			if (ps.monsters() + opp.monsters()).filter(func(m): return m.face_up and m.frame() == "synchro").is_empty() or ps.free_zone() == -1:
				return events
			var res_pool: Array = ps.deck.filter(func(x): return x.is_monster() and x.cname().contains("Resonator") and x.cname() != "Chain Resonator" and _ss_ok(x))
			if res_pool.is_empty():
				return events
			# (The one that makes Red Nova Dragon's Level right, when Red Dragon Archfiend is out: a Level 3.)
			var want_r = res_pool[0]
			for x in res_pool:
				if x.level() == 3:
					want_r = x
					break
			var got_r = s.pick1(p, Loc.t("%s: Special Summon 1 Resonator from your Deck") % name, res_pool, want_r, c)
			ps.deck.erase(got_r)
			s._shuffle(ps.deck)
			events.append_array(s._special(p, got_r, "effect"))
		"synkron_back":
			# Synkron Resonator: "If this card is sent from the field to the GY: You can target 1 "Resonator" monster in
			# your GY, except "Synkron Resonator"; add it to your hand."
			if not (c.tags.get("ss", false) or c.tags.get("ns", false)):
				return events   # (discarded or sent from the Deck: it was never on the field)
			var back_r: Array = s.players[c.owner].gy.filter(func(x): return x.is_monster() and x.cname().contains("Resonator") and x.cname() != "Synkron Resonator")
			if not back_r.is_empty():
				var take_r = s.pick1(c.owner, Loc.t("%s: add 1 Resonator from your Graveyard to your hand") % name, back_r, back_r[0], c)
				s.players[c.owner].gy.erase(take_r)
				s.players[c.owner].hand.append(take_r)
				events.append({"type": "gy_to_hand", "player": c.owner, "card": take_r})
		"scarlight":
			# Scarlight Red Dragon Archfiend: "destroy as many other Special Summoned Effect Monsters on the field as
			# possible with ATK less than or equal to this card's, then inflict 500 damage to your opponent for each."
			var cap_s: int = s.atk_of(c, false)
			var burnt := 0
			for q in [s.opponent(p), p]:
				for m in s.players[q].monsters():
					if m != c and m.face_up and m.tags.get("ss", false) and m.frame() != "normal" and not m.is_token() and s.atk_of(m, false) <= cap_s:
						events.append_array(s._destroy(m))
						if not s.players[q].field.has(m):
							burnt += 1
			if burnt > 0:
				events.append(_ev(p, c, Loc.t("%s: %d damage") % [name, 500 * burnt]))
				events.append_array(s._damage(s.opponent(p), 500 * burnt))
		"neo_negate":
			# Neo Galaxy-Eyes Photon Dragon: "If this card is Xyz Summoned using "Galaxy-Eyes Photon Dragon" as any of its
			# materials: All other face-up cards currently on the field have their effects negated."
			if c.overlays.filter(func(o): return o.cname() == "Galaxy-Eyes Photon Dragon").is_empty():
				return events
			for q in 2:
				for m in s.players[q].monsters():
					if m != c and m.face_up:
						m.neg_perm = true
						m.negated = true
				for st in s.players[q].spells:
					if st != null and st.face_up:
						st.tags["neo_neg"] = true
				if s.players[q].field_spell != null and s.players[q].field_spell.face_up:
					s.players[q].field_spell.tags["neo_neg"] = true
			events.append(_ev(p, c, Loc.t("%s negates every other face-up card on the field") % name))
		"neo_strip":
			# "detach all materials from monsters your opponent controls, then, for the rest of this turn, this card gains
			# 500 ATK for each, also it can attack up to that many times during each Battle Phase."
			var took := 0
			for m in opp.monsters():
				for o in m.overlays.duplicate():
					m.overlays.erase(o)
					s.players[o.owner].gy.append(o)
					took += 1
			if took > 0:
				if c.atk_mod_turn != s.turn:
					c.atk_mod_t = 0
				c.atk_mod_turn = s.turn
				c.atk_mod_t += 500 * took
				c.bonus_attacks = maxi(0, took - 1)
				c.bonus_attacks_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s takes %d materials: +%d ATK and %d attacks this turn") % [name, took, 500 * took, took]))
		"laser":
			# Cyber Laser Dragon: "you can destroy 1 monster with ATK or DEF equal to or higher than the ATK of this card."
			var mine_l: int = s.atk_of(c, false)
			var big_l: Array = opp.monsters().filter(func(m): return m.face_up and (s.atk_of(m, false) >= mine_l or s.def_of(m) >= mine_l))
			if big_l.is_empty():
				return events
			var top_l = big_l[0]
			for m in big_l:
				if s.atk_of(m, false) > s.atk_of(top_l, false):
					top_l = m
			top_l = s.pick1(p, Loc.t("%s: destroy which monster?") % name, big_l, top_l, c)
			events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, top_l.cname()]))
			events.append_array(s._destroy(top_l))
		"destroy_opp_faceup":
			# Armed Dragon LV10: "destroy all face-up monsters your opponent controls."
			for m in opp.monsters():
				if m.face_up:
					events.append_array(s._destroy(m))
		"banish_opp_card":
			# VWXYZ-Dragon Catapult Cannon: "target 1 card your opponent controls; banish that target."
			var every_b: Array = opp.monsters().filter(func(m): return can_target(c, m))
			for st in opp.spells:
				if st != null:
					every_b.append(st)
			if opp.field_spell != null:
				every_b.append(opp.field_spell)
			if every_b.is_empty():
				return events
			var want_b = _best_opp(s, p, "", c)
			var got_b = s.pick1(p, Loc.t("%s: banish 1 card") % name, every_b, want_b if want_b != null and every_b.has(want_b) else every_b[0], c)
			events.append(_ev(p, c, Loc.t("%s banishes %s") % [name, got_b.cname() if got_b.face_up else Loc.t("a set card")]))
			events.append_array(s._banish(got_b))
		"zone_lock":
			# Ojama King: "Choose up to 3 of your opponent's unused Monster Zones. Those zones cannot be used."
			var shut_z: Array = []
			for i in range(opp.field.size() - 1, -1, -1):
				if opp.field[i] == null and shut_z.size() < int(a[1]):
					shut_z.append(i)
			c.tags["zones"] = shut_z
			s._apply_zone_locks()
			if not shut_z.is_empty():
				events.append(_ev(p, c, Loc.t("%s shuts %d of %s's Monster Zones") % [name, shut_z.size(), opp.name]))
		"parasite":
			# Parasite Paracide: "FLIP: Shuffle this card face-up into your opponent's Deck."
			if ps.field.has(c):
				ps.field[ps.field.find(c)] = null
				events.append_array(s._monster_left(c))
				c.reset_mods()
				c.face_up = true
				c.orig_owner = c.owner if c.orig_owner == -1 else c.orig_owner
				c.owner = s.opponent(p)
				c.tags["parasite"] = true
				opp.deck.append(c)
				s._shuffle(opp.deck)
				events.append({"type": "bounce", "player": p, "card": c, "extra": true})
				events.append(_ev(p, c, Loc.t("%s burrows into %s's Deck") % [name, opp.name]))
		"self_deck_top":
			# Cockroach Knight: "When this card has been sent to the Graveyard, it is returned to the top of the Deck."
			var own_k := s.players[c.owner]
			if own_k.gy.has(c):
				own_k.gy.erase(c)
				own_k.deck.append(c)
				events.append(_ev(c.owner, c, Loc.t("%s returns to the top of the Deck") % name))
		"absorb":
			# Relinquished: "target 1 monster your opponent controls; equip that target to this card (max. 1)."
			var prey_a: Array = opp.monsters().filter(func(m): return can_target(c, m) and not m.is_token())
			var zone_a: int = ps.spells.find(null)
			if prey_a.is_empty() or zone_a == -1 or s.absorbed_by(c) != null:
				return events
			var best_a = prey_a[0]
			for m in prey_a:
				if (s.atk_of(m, false) if m.face_up else 1500) > (s.atk_of(best_a, false) if best_a.face_up else 1500):
					best_a = m
			best_a = s.pick1(p, Loc.t("%s: take which monster?") % name, prey_a, best_a, c)
			opp.field[opp.field.find(best_a)] = null
			for o in best_a.overlays:
				s._to_gy(s.players[o.owner], o)
			best_a.overlays.clear()
			events.append_array(s._monster_left(best_a))
			best_a.reset_mods()
			best_a.face_up = true
			if best_a.orig_owner == -1:
				best_a.orig_owner = best_a.owner
			best_a.owner = p
			ps.spells[zone_a] = best_a
			best_a.equipped_to = c
			c.tags["absorbed"] = best_a.uid
			events.append(_ev(p, c, Loc.t("%s takes %s: its ATK and DEF are now %d / %d") % [name, best_a.cname(), best_a.atk(), best_a.def()]))
			events.append({"type": "activate", "player": p, "card": best_a, "zone": zone_a})
		"illusionist":
			# Dark-Eyes Illusionist: "Target 1 monster on the field; it cannot attack while this card is face-up on the field."
			var t_i = _best_opp(s, p, "", c, "which monster cannot attack?")
			if t_i != null:
				t_i.tags["no_atk_by"] = c.uid
				events.append(_ev(p, c, Loc.t("%s cannot attack while %s is face-up") % [t_i.cname() if t_i.face_up else Loc.t("The face-down monster"), name]))
		"set_to_hand":
			# Byser Shock: "Return all Set cards on the field to the hand."
			for q in [opp_i, p]:
				for m in s.players[q].monsters():
					if not m.face_up:
						events.append_array(s._bounce(m))
				for st in s.players[q].spells.duplicate():
					if st != null and not st.face_up:
						events.append_array(s._bounce(st))
		"ra_pay":
			# The Winged Dragon of Ra: "You can pay LP so that you only have 100 left; this card gains ATK/DEF equal to the amount of LP paid."
			var paid_r: int = ps.lp - 100
			if paid_r <= 0:
				return events
			var sure: bool = opp.monsters().is_empty() and paid_r >= opp.lp
			if s.choose_option(p, Loc.t("%s: pay %d LP (down to 100) to give it that much ATK and DEF?") % [name, paid_r], ["Pay", "No"], 0 if sure else 1, c) != 0:
				return events
			ps.lp = 100
			events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -paid_r})
			c.atk_mod += paid_r
			c.def_mod += paid_r
			events.append(_ev(p, c, Loc.t("%s: its ATK and DEF become %d / %d") % [name, paid_r, paid_r]))
		"ra_destroy":
			# "You can pay 1000 LP, then target 1 monster on the field; destroy that target."
			if ps.lp <= 1000:
				return events
			var every_r: Array = opp.monsters() + ps.monsters().filter(func(m): return m != c)
			var theirs_r: Array = every_r.filter(func(m): return opp.field.has(m) and can_target(c, m))
			if theirs_r.is_empty() and not s.manual[p]:
				return events
			if every_r.is_empty():
				return events
			var best_rd = theirs_r[0] if not theirs_r.is_empty() else every_r[0]
			for m in theirs_r:
				if s.atk_of(m, false) > s.atk_of(best_rd, false):
					best_rd = m
			best_rd = s.pick1(p, Loc.t("%s: destroy which monster?") % name, every_r, best_rd, c)
			ps.lp -= 1000
			events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -1000})
			events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, best_rd.cname() if best_rd.face_up else Loc.t("the face-down monster")]))
			events.append_array(s._destroy(best_rd))
		"necro_mark":
			# Dark Necrofear was destroyed in the Monster Zone by the opponent's card: it acts in this turn's End Phase.
			if s.effect_by != p or ctx.has("killer"):
				c.set_meta("necro_turn", s.turn)
		"morphing_jar":
			# "Both players discard as many cards as possible from their hands, also, after that, each player draws 5 cards."
			for q in [p, opp_i]:
				for h in s.players[q].hand.duplicate():
					s.players[q].hand.erase(h)
					s._to_gy(s.players[q], h)
					events.append({"type": "discard", "player": q, "card": h})
			for q in [p, opp_i]:
				events.append_array(s._draw(q, 5))
		"opp_discard_random":
			if not opp.hand.is_empty():
				var rnd_h = opp.hand[randi() % opp.hand.size()]
				opp.hand.erase(rnd_h)
				s._to_gy(opp, rnd_h)
				events.append(_ev(p, c, Loc.t("%s: the opponent discards %s") % [name, rnd_h.cname()]))
				events.append({"type": "discard", "player": opp_i, "card": rnd_h})
		"umbral_ghost":
			# (Only when it came out by its own effect, not when something else Special Summoned it.)
			if int(c.get_meta("hand_fx_turn", -1)) != s.turn or int(ps.once_names.get("Umbral Horror Ghost", -1)) == s.turn:
				return events
			ps.once_names["Umbral Horror Ghost"] = s.turn
			s.normal_summoned = true
			ps.extra_normals = 0
			var fiends: Array = ps.hand.filter(func(h): return h.is_monster() and str(h.data.get("race", "")) == "Fiend" and h.level() <= 4 and not CardData.is_extra(h.id) and not CardEffects.of(h.cname()).get("no_special", false))
			if fiends.is_empty() or ps.free_zone() == -1:
				return events
			fiends.sort_custom(func(x, y): return x.atk() > y.atk())
			var got_u = s.pick1(p, Loc.t("%s: Special Summon which Fiend from your hand?") % name, fiends, fiends[0], c)
			ps.hand.erase(got_u)
			events.append(_ev(p, c, Loc.t("%s calls %s") % [name, got_u.cname()]))
			events.append_array(s._special(p, got_u, "effect"))
			events.append_array(on_summon(s, p, got_u, "special"))
		"mill_opp_top":
			# Number 104: Masquerade: "send the top card of your opponent's Deck to the Graveyard."
			if not opp.deck.is_empty():
				var top_m = opp.deck.pop_back()
				s._to_gy(opp, top_m)
				events.append({"type": "mill", "player": opp_i, "card": top_m, "deck": opp.deck.size()})
				events.append_array(trigger(s, top_m, "sent_gy"))
		"destroy_st_may":
			# C104: "When this card is Special Summoned: You can target 1 Spell/Trap on the field; destroy that target."
			var every_s: Array = _all_st(s)
			var theirs_s: Array = every_s.filter(func(x): return x.owner == opp_i)
			if every_s.is_empty():
				return events
			var got_s := s.choose(p, Loc.t("%s: destroy 1 Spell or Trap?") % name, every_s, 1, [theirs_s[0]] if not theirs_s.is_empty() else [], true, c)
			if not got_s.is_empty():
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, got_s[0].cname() if got_s[0].face_up else Loc.t("a Set card")]))
				events.append_array(s._destroy_st(got_s[0]))
		"opp_lose_atk":
			# Needle Sunfish: "Target 1 face-up monster your opponent controls; that target loses 500 ATK."
			var t_n = s._strongest_face_up(opp_i)
			var ups_n: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if t_n != null and not ups_n.is_empty():
				if not ups_n.has(t_n):
					t_n = ups_n[0]
				t_n = s.pick1(p, Loc.t("%s: which monster loses %d ATK?") % [name, int(a[1])], ups_n, t_n, c)
				t_n.atk_mod -= int(a[1])
				events.append(_ev(p, c, Loc.t("%s loses %d ATK") % [t_n.cname(), int(a[1])]))
		"aero_shark":
			var n_a: int = ps.banished.filter(func(b): return b.is_monster()).size()
			events.append(_ev(p, c, Loc.t("%s: %d damage") % [name, n_a * 100]))
			events.append_array(s._damage(opp_i, n_a * 100))
		"nightmare_attach":
			# Number 47: "When this card is Special Summoned: You can attach 1 Level 3 WATER monster from your hand or your side of the field to this card as an Xyz Material."
			var pool_na: Array = ps.hand.filter(func(h): return h.is_monster() and h.level() == 3 and str(h.data.get("attribute", "")) == "WATER")
			pool_na.append_array(ps.monsters().filter(func(m): return m != c and m.face_up and m.frame() != "xyz" and m.level() == 3 and str(m.data.get("attribute", "")) == "WATER"))
			if pool_na.is_empty():
				return events
			var in_hand_na: Array = pool_na.filter(func(x): return ps.hand.has(x))
			var got_na := s.choose(p, Loc.t("%s: attach 1 Level 3 WATER monster as material?") % name, pool_na, 1, [in_hand_na[0]] if not in_hand_na.is_empty() else [], true, c)
			if got_na.is_empty():
				return events
			var mat_na = got_na[0]
			if ps.hand.has(mat_na):
				ps.hand.erase(mat_na)
			else:
				ps.field[ps.field.find(mat_na)] = null
				events.append_array(s._monster_left(mat_na))
			c.overlays.append(mat_na)
			events.append(_ev(p, c, Loc.t("%s is attached to %s as material") % [mat_na.cname(), name]))
			events.append({"type": "detach", "player": p, "card": c})
		"nightmare_direct":
			# "target 1 WATER monster you control; this turn, that monster can attack your opponent directly, also other monsters cannot attack."
			var waters: Array = ps.monsters().filter(func(m): return m.face_up and str(m.data.get("attribute", "")) == "WATER")
			if waters.is_empty():
				return events
			var best_nd = waters[0]
			for m in waters:
				if s.atk_of(m, false) > s.atk_of(best_nd, false):
					best_nd = m
			best_nd = s.pick1(p, Loc.t("%s: which WATER monster attacks directly this turn?") % name, waters, best_nd, c)
			best_nd.tags["direct_turn"] = s.turn
			ps.only_attacker = best_nd.uid
			ps.only_attacker_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s can attack directly this turn. Your other monsters cannot attack") % best_nd.cname()))
		"bahamut":
			# "Special Summon 1 Rank 3 or lower WATER Xyz Monster from your Extra Deck. This card cannot attack for the rest of this turn."
			var xs_b: Array = ps.extra.filter(func(x): return x.frame() == "xyz" and x.level() <= 3 and str(x.data.get("attribute", "")) == "WATER")
			if xs_b.is_empty() or ps.free_zone() == -1:
				return events
			var best_bh = xs_b[0]
			for x in xs_b:
				if x.atk() > best_bh.atk():
					best_bh = x
			best_bh = s.pick1(p, Loc.t("%s: Special Summon which Xyz Monster?") % name, xs_b, best_bh, c)
			ps.extra.erase(best_bh)
			best_bh.proper = true
			events.append(_ev(p, c, Loc.t("%s calls %s") % [name, best_bh.cname()]))
			events.append_array(s._special(p, best_bh, "effect"))
			events.append_array(on_summon(s, p, best_bh, "special"))
			c.attack_count_turn = s.turn
			c.attack_count = 99
		"destroy_opp_set":
			# Photon Wyvern: "Destroy all Set cards your opponent controls."
			for m in opp.monsters():
				if not m.face_up:
					events.append_array(s._destroy(m))
			for st in opp.spells.duplicate():
				if st != null and not st.face_up:
					events.append_array(s._destroy_st(st))
		"chargeman":
			# "make this card's ATK become double its original ATK, until your next Standby Phase. This card cannot attack the turn you activate this effect."
			c.tmp_atk = c.atk()
			c.tmp_until = s.turn + 1
			c.attack_count_turn = s.turn
			c.attack_count = 99
			events.append(_ev(p, c, Loc.t("%s: its ATK is %d until your next Standby Phase") % [name, c.atk() * 2]))
		"photon_pirate":
			# "banish 1 "Photon" monster from your Graveyard; this card gains 1000 ATK until the End Phase" (up to twice per turn).
			var pool_pp: Array = ps.gy.filter(func(g): return g.is_monster() and g.cname().contains("Photon"))
			if pool_pp.is_empty():
				return events
			pool_pp.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
			events.append_array(s._banish(s.pick1(p, Loc.t("%s: banish which \"Photon\" monster from your Graveyard?") % name, pool_pp, pool_pp[0], c)))
			c.tags["pirate_n"] = (int(c.tags.get("pirate_n", 0)) if int(c.tags.get("pirate_turn", -1)) == s.turn else 0) + 1
			c.tags["pirate_turn"] = s.turn
			if c.atk_mod_turn != s.turn:
				c.atk_mod_turn = s.turn
				c.atk_mod_t = 0
			c.atk_mod_t += 1000
			events.append(_ev(p, c, Loc.t("%s: %d ATK until the end of this turn") % [name, 1000]))
		"caesar":
			# "You can Special Summon 1 "Photon Caesar" from your hand or Deck."
			for src in [ps.hand, ps.deck]:
				var got_c: Array = src.filter(func(x): return x != c and x.cname() == "Photon Caesar")
				if not got_c.is_empty() and ps.free_zone() != -1:
					if s.choose_option(p, Loc.t("%s: Special Summon another Photon Caesar?") % name, ["Yes", "No"], 0, c) != 0:
						return events
					src.erase(got_c[0])
					if src == ps.deck:
						s._shuffle(ps.deck)
					events.append(_ev(p, c, Loc.t("%s calls %s") % [name, got_c[0].cname()]))
					events.append_array(s._special(p, got_c[0], "effect"))
					break
		"galaxy_wizard":
			# Two effects: its Level +4 until the end of this turn, or Tribute it to add 1 "Galaxy" card from the Deck (not Galaxy Wizard).
			var can_search: bool = not ps.deck.filter(func(x): return x.cname().contains("Galaxy") and x.cname() != "Galaxy Wizard" and not CardData.is_extra(x.id)).is_empty()
			var want_lv := 0
			for m in ps.monsters():
				if m != c and m.face_up and m.level() == c.level() + 4 and m.frame() != "xyz":
					want_lv = 1
			var pick_w: int = 0
			if can_search:
				pick_w = s.choose_option(p, Loc.t("%s: which effect?") % name, ["Level +4 until the end of this turn", "Tribute it: add 1 \"Galaxy\" card from your Deck"], 0 if want_lv == 1 else 1, c)
			if pick_w == 0:
				c.lv_set = c.level() + 4
				c.lv_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s is Level %d until the end of this turn") % [name, c.lv_set]))
			else:
				ps.field[ps.field.find(c)] = null
				s._to_gy(ps, c)
				events.append({"type": "tribute", "player": p, "card": c})
				events.append_array(s._monster_left(c))
				var gal: Array = ps.deck.filter(func(x): return x.cname().contains("Galaxy") and x.cname() != "Galaxy Wizard" and not CardData.is_extra(x.id))
				gal.sort_custom(func(x, y): return s._card_value(x) > s._card_value(y))
				var got_w = s.pick1(p, Loc.t("%s: add which \"Galaxy\" card to your hand?") % name, gal, gal[0], c)
				ps.deck.erase(got_w)
				ps.hand.append(got_w)
				s._shuffle(ps.deck)
				events.append({"type": "search", "player": p, "card": got_w, "deck": ps.deck.size()})
		"galaxion":
			# Detach 1: Special Summon Galaxy-Eyes Photon Dragon from your hand. Detach 2: from your Deck.
			var in_hand: Array = ps.hand.filter(func(h): return h.cname() == "Galaxy-Eyes Photon Dragon")
			var in_deck_g: Array = ps.deck.filter(func(h): return h.cname() == "Galaxy-Eyes Photon Dragon")
			var use_deck: bool = in_hand.is_empty() or c.overlays.size() < 1
			if not in_hand.is_empty() and not in_deck_g.is_empty() and c.overlays.size() >= 2:
				use_deck = s.choose_option(p, Loc.t("%s: detach how many?") % name, ["1: from your hand", "2: from your Deck"], 0, c) == 1
			if use_deck and (in_deck_g.is_empty() or c.overlays.size() < 2):
				return events
			for i in (2 if use_deck else 1):
				var o = c.overlays.pop_back()
				s._to_gy(ps, o)
			events.append({"type": "detach", "player": p, "card": c})
			var ge = in_deck_g[0] if use_deck else in_hand[0]
			if use_deck:
				ps.deck.erase(ge)
				s._shuffle(ps.deck)
			else:
				ps.hand.erase(ge)
			ge.proper = true
			events.append(_ev(p, c, Loc.t("%s calls %s") % [name, ge.cname()]))
			events.append_array(s._special(p, ge, "effect"))
		"papillo":
			# "target 1 Defense Position monster on the field; change it to face-up Attack Position, and if you do, it loses 600 ATK."
			var defs: Array = []
			for q in [opp_i, p]:
				for m in s.players[q].monsters():
					if not m.attack_pos and can_target(c, m):
						defs.append(m)
			var theirs_p: Array = defs.filter(func(m): return opp.field.has(m))
			if defs.is_empty() or (theirs_p.is_empty() and not s.manual[p]):
				return events
			var t_p = s.pick1(p, Loc.t("%s: change which monster to Attack Position?") % name, defs, theirs_p[0] if not theirs_p.is_empty() else defs[0], c)
			t_p.face_up = true
			t_p.attack_pos = true
			t_p.atk_mod -= 600
			events.append(_ev(p, c, Loc.t("%s is turned to Attack Position and loses 600 ATK") % t_p.cname()))
			events.append({"type": "position", "player": 0 if s.players[0].field.has(t_p) else 1, "card": t_p, "zone": s.players[0 if s.players[0].field.has(t_p) else 1].field.find(t_p)})
		"illumiknight":
			# "send 1 card from your hand to the Graveyard, and if you do, draw 1 card."
			if ps.hand.is_empty():
				return events
			var low_i = ps.hand[0]
			for h in ps.hand:
				if s._card_value(h) < s._card_value(low_i):
					low_i = h
			low_i = s.pick1(p, Loc.t("%s: send 1 card from your hand to the Graveyard") % name, ps.hand, low_i, c)
			ps.hand.erase(low_i)
			s._to_gy(ps, low_i)
			events.append({"type": "discard", "player": p, "card": low_i})
			events.append_array(s._draw(p, 1))
		"randomizer":
			# "draw 1 card and reveal it. For a Monster Card, inflict damage equal to its Level x 200. For a Spell or Trap Card, you take 500 damage."
			if not ps.hand.is_empty() or ps.deck.is_empty():
				return events
			var top_r = ps.deck.back()
			events.append_array(s._draw(p, 1))
			events.append(_ev(p, c, Loc.t("%s: the card drawn is %s") % [name, top_r.cname()]))
			if top_r.is_monster():
				events.append_array(s._damage(opp_i, top_r.level() * 200))
			else:
				events.append_array(s._damage(p, 500))
		"hundred_eyes":
			# "banish 1 Level 6 or lower DARK Effect Monster from your GY; until the End Phase, this card's name becomes that monster's original name, and replace this effect with that monster's original effects."
			var pool_h: Array = ps.gy.filter(func(g): return g.is_monster() and g.level() <= 6 and g.frame() != "xyz" and str(g.data.get("attribute", "")) == "DARK" and _is_effect_monster(g))
			if pool_h.is_empty():
				return events
			var best_h = pool_h[0]
			for g in pool_h:
				if CardEffects.of(g.cname()).has("ignite") and not CardEffects.of(best_h.cname()).has("ignite"):
					best_h = g
			best_h = s.pick1(p, Loc.t("%s: banish which monster to take its name and effects?") % name, pool_h, best_h, c)
			events.append_array(s._banish(best_h))
			c.tags["as"] = str(best_h.data.get("name", ""))
			c.ignite_turn = -1
			events.append(_ev(p, c, Loc.t("%s becomes %s until the End Phase") % [name, str(c.tags["as"])]))
		"amaryllis_hand":
			for h in ps.hand.duplicate():
				if h.cname() == "Phoenixian Cluster Amaryllis" and ps.free_zone() != -1:
					ps.hand.erase(h)
					h.proper = true
					events.append(_ev(p, c, Loc.t("%s calls %s") % [name, h.cname()]))
					events.append_array(s._special(p, h, "effect"))
					break
		"witch_rose":
			# "...and you control no other cards: Draw 1 card and show it, then, if it is not a monster, send it to the GY, also destroy this card."
			if ps.monsters().size() != 1 or not ps.set_cards().is_empty() or ps.field_spell != null or ps.deck.is_empty():
				return events
			var top_w = ps.deck.back()
			events.append_array(s._draw(p, 1))
			events.append(_ev(p, c, Loc.t("%s: the card drawn is %s") % [name, top_w.cname()]))
			if not top_w.is_monster() and ps.hand.has(top_w):
				ps.hand.erase(top_w)
				s._to_gy(ps, top_w)
				events.append({"type": "discard", "player": p, "card": top_w})
				events.append_array(s._destroy(c))
		"blue_rose":
			var pool_r: Array = ps.gy.filter(func(g): return g != c and g.is_monster() and s.can_revive(g) and (g.cname() == "Black Rose Dragon" or str(g.data.get("race", "")) == "Plant"))
			if pool_r.is_empty() or ps.free_zone() == -1:
				return events
			var best_r = pool_r[0]
			for g in pool_r:
				if g.atk() > best_r.atk():
					best_r = g
			var got_r := s.choose(p, Loc.t("%s: Special Summon Black Rose Dragon or a Plant monster from your Graveyard?") % name, pool_r, 1, [best_r], true, c)
			if not got_r.is_empty():
				ps.gy.erase(got_r[0])
				events.append_array(s._special(p, got_r[0], "reborn"))
		"destroy_lowest_atk":
			# Queen Angel of Roses: "Destroy the 1 face-up monster on the field that has the lowest ATK (your choice, if tied)."
			var ups_q: Array = []
			for q in 2:
				for m in s.players[q].monsters():
					if m.face_up:
						ups_q.append(m)
			if ups_q.is_empty():
				return events
			var low_q: int = s.atk_of(ups_q[0], false)
			for m in ups_q:
				low_q = mini(low_q, s.atk_of(m, false))
			var ties_q: Array = ups_q.filter(func(m): return s.atk_of(m, false) == low_q)
			var pick_q = ties_q[0]
			for m in ties_q:
				if opp.field.has(m):
					pick_q = m
			pick_q = s.pick1(p, Loc.t("%s: destroy which monster? (tied for the lowest ATK)") % name, ties_q, pick_q, c) if ties_q.size() > 1 else pick_q
			events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, pick_q.cname()]))
			events.append_array(s._destroy(pick_q))
		"sirocco":
			# "target 1 "Blackwing" monster you control; until the end of this turn, it gains ATK equal to the total ATK of all "Blackwing"
			# monsters currently on the field, except itself. Monsters other than the targeted monster cannot attack during the turn you activate this effect."
			var bws: Array = ps.monsters().filter(func(m): return m.face_up and m.cname().contains("Blackwing"))
			if bws.is_empty():
				return events
			var best_b = bws[0]
			for m in bws:
				if s.atk_of(m, false) > s.atk_of(best_b, false):
					best_b = m
			best_b = s.pick1(p, Loc.t("%s: which \"Blackwing\" monster takes the others' ATK?") % name, bws, best_b, c)
			var sum_b := 0
			for q in 2:
				for m in s.players[q].monsters():
					if m != best_b and m.face_up and m.cname().contains("Blackwing"):
						sum_b += s.atk_of(m, false)
			if best_b.atk_mod_turn != s.turn:
				best_b.atk_mod_turn = s.turn
				best_b.atk_mod_t = 0
			best_b.atk_mod_t += sum_b
			ps.only_attacker = best_b.uid
			ps.only_attacker_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s gains %d ATK this turn. Your other monsters cannot attack") % [best_b.cname(), sum_b]))
		"next_bd_zero":
			s.next_bd_zero[p] = s.turn
			events.append(_ev(p, c, Loc.t("%s: the next battle damage you take this turn is 0") % name))
		"self_swap":
			# Ghibli: "switch the original ATK and DEF of this card, until the end of this turn."
			if c.atk_mod_turn != s.turn:
				c.atk_mod_turn = s.turn
				c.atk_mod_t = 0
			c.atk_mod_t += c.def() - c.atk()
			c.tags["tmp_def"] = (int(c.tags.get("tmp_def", 0)) if int(c.tags.get("tmp_def_until", -1)) >= s.turn else 0) + c.atk() - c.def()
			c.tags["tmp_def_until"] = s.turn
			events.append(_ev(p, c, Loc.t("%s switches its ATK and DEF until the end of this turn") % name))
		"silverwind":
			# "target up to 2 face-up monsters on the field with DEF lower than this card's ATK; destroy those targets. You cannot conduct your Battle Phase the turn you activate this effect."
			var my_atk: int = s.atk_of(c, false)
			var low_d: Array = []
			for q in [opp_i, p]:
				for m in s.players[q].monsters():
					if m != c and m.face_up and s.def_of(m) < my_atk and can_target(c, m):
						low_d.append(m)
			var theirs_d: Array = low_d.filter(func(m): return opp.field.has(m))
			theirs_d.sort_custom(func(x, y): return s.atk_of(x, false) > s.atk_of(y, false))
			# The computer uses it when it removes more than this card's own attack would.
			var auto_d: Array = theirs_d.slice(0, 2) if (theirs_d.size() >= 2 or s.phase == DuelState.Phase.MAIN2) else []
			var got_d := s.choose(p, Loc.t("%s: destroy up to 2 monsters with DEF lower than its ATK? (no Battle Phase this turn)") % name, low_d, 2, auto_d, true, c)
			if got_d.is_empty():
				return events
			for m in got_d:
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, m.cname()]))
				events.append_array(s._destroy(m))
			ps.no_attack_turn = s.turn
		"feather_release":
			# Black-Winged Dragon: remove all its counters; 1 face-up monster of theirs loses 700 ATK for each, and they take that much damage.
			var n_f: int = c.counter
			var t_f = _best_opp(s, p, "", c, "which monster loses the ATK?")
			if n_f < 1 or t_f == null or not t_f.face_up:
				return events
			c.counter = 0
			var lost_f: int = mini(700 * n_f, s.atk_of(t_f, false))
			t_f.atk_mod -= lost_f
			events.append(_ev(p, c, Loc.t("%s: %s loses %d ATK and the opponent takes that much damage") % [name, t_f.cname(), lost_f]))
			events.append_array(s._damage(opp_i, lost_f))
		"into_atk":
			# Flare Resonator: "A Synchro Monster that used this card as a Synchro Material gains 300 ATK."
			var into_m = ctx.get("into")
			if into_m != null:
				into_m.atk_mod += int(a[1])
				events.append(_ev(p, c, Loc.t("%s: %s gains %d ATK") % [name, into_m.cname(), int(a[1])]))
		"time_wizard":
			# "toss a coin and call it. If you call it right, destroy all monsters your opponent controls. If you call it wrong, destroy as
			# many monsters you control as possible, and if you do, take damage equal to half the total ATK those destroyed monsters had."
			var call_it: int = s.choose_option(p, Loc.t("%s: call the coin") % name, ["Heads", "Tails"], 0, c)
			var coin: int = randi() % 2
			events.append(_ev(p, c, Loc.t("%s: the coin shows %s") % [name, Loc.t("Heads") if coin == 0 else Loc.t("Tails")]))
			if coin == call_it:
				events.append(_ev(p, c, Loc.t("Called it right: every monster the opponent controls is destroyed")))
				for m in opp.monsters():
					events.append_array(s._destroy(m))
			else:
				events.append(_ev(p, c, Loc.t("Called it wrong: your monsters are destroyed")))
				var lost_tw := 0
				for m in ps.monsters():
					var had_tw: int = s.atk_of(m, false) if m.face_up else 0
					events.append_array(s._destroy(m))
					if not ps.field.has(m):
						lost_tw += had_tw
				if lost_tw > 0:
					events.append_array(s._damage(p, lost_tw / 2))
		"copycat":
			# "Target 1 face-up monster your opponent controls; this card's ATK/DEF become equal to that monster's original ATK/DEF."
			var ups_c: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if not ups_c.is_empty():
				var best_c = ups_c[0]
				for m in ups_c:
					if m.atk() > best_c.atk():
						best_c = m
				best_c = s.pick1(p, Loc.t("%s: copy which monster's ATK and DEF?") % name, ups_c, best_c, c)
				c.atk_mod = best_c.atk() - c.atk()
				c.def_mod = best_c.def() - c.def()
				events.append(_ev(p, c, Loc.t("%s: its ATK and DEF become %d / %d") % [name, best_c.atk(), best_c.def()]))
		"obelisk":
			# "destroy all monsters your opponent controls. This card cannot declare an attack the turn this effect is activated."
			events.append(_ev(p, c, Loc.t("%s destroys every monster the opponent controls") % name))
			for m in opp.monsters():
				events.append_array(s._destroy(m))
			c.attack_count_turn = s.turn
			c.attack_count = 99
		"destroy_pick":
			var pool_p: Array = _pick_pool(s, p, str(a[1]))
			if not pool_p.is_empty():
				var got_p = s.pick1(p, Loc.t("%s: destroy 1 card") % name, pool_p, pool_p[0], c)
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, got_p.cname() if got_p.face_up else Loc.t("a Set card")]))
				events.append_array(s._destroy(got_p) if got_p.is_monster() and opp.field.has(got_p) else s._destroy_st(got_p))
		"utopia_ray":
			# "it gains 500 ATK until the end of this turn, and if it does, 1 monster your opponent controls loses 1000 ATK until the end of this turn."
			if ps.lp > 1000:
				return events
			if c.atk_mod_turn != s.turn:
				c.atk_mod_turn = s.turn
				c.atk_mod_t = 0
			c.atk_mod_t += 500
			events.append(_ev(p, c, Loc.t("%s: 500 ATK until the end of this turn") % name))
			var t_r = _best_opp(s, p, "", null, "")
			var ups_r: Array = opp.monsters().filter(func(m): return m.face_up)
			if not ups_r.is_empty():
				if t_r == null or not t_r.face_up:
					t_r = ups_r[0]
				t_r = s.pick1(p, Loc.t("%s: which monster loses 1000 ATK?") % name, ups_r, t_r, c)
				if t_r.atk_mod_turn != s.turn:
					t_r.atk_mod_turn = s.turn
					t_r.atk_mod_t = 0
				t_r.atk_mod_t -= 1000
				events.append(_ev(p, c, Loc.t("%s loses 1000 ATK until the end of this turn") % t_r.cname()))
		"ray_v":
			# "destroy that monster, and if it was face-up, inflict damage to your opponent equal to the ATK the destroyed monster had on the field."
			var t_v = _best_opp(s, p, "", c, "destroy 1 monster")
			if t_v != null:
				var was_up: bool = t_v.face_up
				var had: int = s.atk_of(t_v, false)
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, t_v.cname() if was_up else Loc.t("the face-down monster")]))
				events.append_array(s._destroy(t_v))
				if not opp.field.has(t_v) and was_up and had > 0:
					events.append_array(s._damage(opp_i, had))
		"xyz_gy_to_extra":
			var xs: Array = ps.gy.filter(func(g): return g.is_monster() and g.frame() == "xyz")
			if not xs.is_empty():
				var best_x = xs[0]
				for g in xs:
					if g.atk() > best_x.atk():
						best_x = g
				var got_x := s.choose(p, Loc.t("%s: return 1 Xyz Monster from your Graveyard to the Extra Deck?") % name, xs, 1, [best_x], true, c)
				if not got_x.is_empty():
					ps.gy.erase(got_x[0])
					ps.extra.append(got_x[0])
					events.append(_ev(p, c, Loc.t("%s returns to the Extra Deck") % got_x[0].cname()))
		"second_attack":
			# Gagaga Samurai: 1 "Gagaga" monster you control can make a second attack during each Battle Phase this turn.
			var mine_s: Array = ps.monsters().filter(func(m): return m.face_up and CardEffects.matches(m.data, a[1]))
			if not mine_s.is_empty():
				var best_s = mine_s[0]
				for m in mine_s:
					if s.atk_of(m, false) > s.atk_of(best_s, false):
						best_s = m
				best_s = s.pick1(p, Loc.t("%s: which monster can attack twice this turn?") % name, mine_s, best_s, c)
				best_s.bonus_attacks = (best_s.bonus_attacks if best_s.bonus_attacks_turn == s.turn else 0) + 1
				best_s.bonus_attacks_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s can make a second attack this turn") % best_s.cname()))
		"volcasaurus":
			var ups_v: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if not ups_v.is_empty():
				var best_v = ups_v[0]
				for m in ups_v:
					if m.atk() > best_v.atk():
						best_v = m
				best_v = s.pick1(p, Loc.t("%s: destroy 1 face-up monster") % name, ups_v, best_v, c)
				events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, best_v.cname()]))
				events.append_array(s._destroy(best_v))
				if not opp.field.has(best_v):
					events.append_array(s._damage(opp_i, best_v.atk()))
			c.tags["no_direct_turn"] = s.turn
		"gogogo_giant":
			# "target 1 "Gogogo" monster in your GY; Special Summon that target in Defense Position, then change this card to Defense Position."
			var pool_g: Array = ps.gy.filter(func(g): return g.is_monster() and g.cname().contains("Gogogo") and s.can_revive(g))
			if pool_g.is_empty() or ps.free_zone() == -1:
				return events
			var best_gg = pool_g[0]
			for g in pool_g:
				if g.def() > best_gg.def():
					best_gg = g
			var got_gg := s.choose(p, Loc.t("%s: Special Summon 1 \"Gogogo\" monster from your Graveyard?") % name, pool_g, 1, [best_gg], true, c)
			if got_gg.is_empty():
				return events
			ps.gy.erase(got_gg[0])
			events.append_array(s._special(p, got_gg[0], "reborn", "def"))
			events.append_array(on_summon(s, p, got_gg[0], "special"))
			if ps.field.has(c) and c.attack_pos:
				c.attack_pos = false
				events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
		"aqua_dolphin":
			# Look at the opponent's hand and choose 1 monster. Control a monster with at least its ATK: it is
			# destroyed and they take 500. Otherwise you take 500.
			var seen: Array = opp.hand.filter(func(h): return h.is_monster())
			events.append(_ev(p, c, Loc.t("%s looks at the opponent's hand") % name))
			if seen.is_empty():
				events.append(_ev(p, c, Loc.t("There is no monster in the opponent's hand")))
				return events
			var my_top := -1
			for m in ps.monsters():
				my_top = maxi(my_top, s.atk_of(m, false))
			var pick_d = null
			for h in seen:
				if h.atk() <= my_top and (pick_d == null or h.atk() > pick_d.atk()):
					pick_d = h
			if pick_d == null:
				pick_d = seen[0]
			pick_d = s.pick1(p, Loc.t("%s: choose 1 monster in the opponent's hand") % name, seen, pick_d, c)
			if pick_d.atk() <= my_top:
				opp.hand.erase(pick_d)
				s._to_gy(opp, pick_d)
				events.append(_ev(p, c, Loc.t("%s is destroyed in the hand") % pick_d.cname()))
				events.append({"type": "discard", "player": opp_i, "card": pick_d})
				events.append_array(s._damage(opp_i, 500))
			else:
				events.append(_ev(p, c, Loc.t("%s is too strong: you take 500 damage") % pick_d.cname()))
				events.append_array(s._damage(p, 500))
		"heal_per_opp_hand":
			var gain_h: int = int(a[1]) * opp.hand.size()
			ps.lp += gain_h
			events.append(_ev(p, c, Loc.t("%s: gain %d LP") % [name, gain_h]))
			events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": gain_h})
		"dark_panther":
			# "...until the End Phase, this card's name becomes that monster's original name, also replace this
			# effect with that monster's original effects (if any)."
			var ups_p: Array = opp.monsters().filter(func(m): return m.face_up and can_target(c, m))
			if ups_p.is_empty():
				return events
			var best_p = ups_p[0]
			for m in ups_p:
				if not CardEffects.of(str(m.data.get("name", ""))).is_empty() and CardEffects.of(str(best_p.data.get("name", ""))).is_empty():
					best_p = m
			best_p = s.pick1(p, Loc.t("%s: copy which monster's name and effects?") % name, ups_p, best_p, c)
			c.tags["as"] = str(best_p.data.get("name", ""))
			c.ignite_turn = -1
			events.append(_ev(p, c, Loc.t("%s becomes %s until the End Phase") % [name, str(c.tags["as"])]))
		"aqua_neos":
			if not opp.hand.is_empty():
				var rnd = opp.hand[randi() % opp.hand.size()]
				opp.hand.erase(rnd)
				s._to_gy(opp, rnd)
				events.append(_ev(p, c, Loc.t("%s destroys %s in the opponent's hand") % [name, rnd.cname()]))
				events.append({"type": "discard", "player": opp_i, "card": rnd})
		"dark_neos":
			var cand_n: Array = _dark_neos_targets(s, c).filter(func(m): return can_target(c, m))
			if cand_n.is_empty():
				return events
			var best_n = null
			for m in cand_n:
				if opp.field.has(m) and not m.negated and (best_n == null or s.atk_of(m, false) > s.atk_of(best_n, false)):
					best_n = m
			if best_n == null:
				if not s.manual[p]:
					return events      # the computer does not shut off its own monsters
				best_n = cand_n[0]
			best_n = s.pick1(p, Loc.t("%s: negate which monster's effects?") % name, cand_n, best_n, c)
			best_n.tags["neg_by"] = c.uid
			best_n.negated = true
			events.append(_ev(p, c, Loc.t("%s negates the effects of %s while it is on the field") % [name, best_n.cname()]))
		"grand_neos":
			var t_g = _best_opp(s, p, "", c, "return 1 monster to the hand")
			if t_g != null:
				events.append(_ev(p, c, Loc.t("%s returns %s to the hand") % [name, t_g.cname() if t_g.face_up else Loc.t("the face-down monster")]))
				events.append_array(s._bounce(t_g))
		"glow_neos":
			# Destroy 1 face-up card the opponent controls, then by its type: Monster, this card cannot attack
			# this turn. Spell, it can attack directly this turn. Trap, it changes to Defense Position.
			var ups_g: Array = _face_up_cards(opp).filter(func(x): return not x.is_monster() or can_target(c, x))
			if ups_g.is_empty():
				return events
			var best_g = null
			for x in ups_g:
				if not x.is_monster() and (best_g == null or x.is_spell()):
					best_g = x
			if best_g == null:
				for x in ups_g:
					if best_g == null or s.atk_of(x, false) > s.atk_of(best_g, false):
						best_g = x
			best_g = s.pick1(p, Loc.t("%s: destroy 1 face-up card") % name, ups_g, best_g, c)
			var kind_g := "monster" if best_g.is_monster() else ("spell" if best_g.is_spell() else "trap")
			events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, best_g.cname()]))
			events.append_array(s._destroy(best_g) if best_g.is_monster() else s._destroy_st(best_g))
			if not ps.field.has(c):
				return events
			match kind_g:
				"monster":
					c.attack_count_turn = s.turn
					c.attack_count = 99
					events.append(_ev(p, c, Loc.t("A monster: %s cannot attack this turn") % name))
				"spell":
					c.tags["direct_turn"] = s.turn
					events.append(_ev(p, c, Loc.t("A Spell: %s can attack directly this turn") % name))
				"trap":
					if c.attack_pos:
						c.attack_pos = false
						events.append(_ev(p, c, Loc.t("A Trap: %s changes to Defense Position") % name))
						events.append({"type": "position", "player": p, "card": c, "zone": ps.field.find(c)})
		"storm_neos":
			events.append(_ev(p, c, Loc.t("%s destroys every Spell and Trap on the field") % name))
			for st in _all_st(s):
				events.append_array(s._destroy_st(st))
		"tempest":
			var mine_t: Array = ps.monsters()
			if mine_t.is_empty():
				return events
			var best_t = mine_t[0]
			for m in mine_t:
				if s.atk_of(m, false) > s.atk_of(best_t, false):
					best_t = m
			best_t = s.pick1(p, Loc.t("%s: which monster cannot be destroyed by battle?") % name, mine_t, best_t, c)
			for m in ps.monsters():
				if int(m.tags.get("guard_by", -1)) == c.uid:
					m.tags.erase("guard_by")
			best_t.tags["guard_by"] = c.uid
			events.append(_ev(p, c, Loc.t("%s cannot be destroyed by battle while %s is face-up") % [best_t.cname(), name]))
		"card_trooper":
			var most: int = mini(3, ps.deck.size())
			var labels_t: Array = []
			for i in most:
				labels_t.append(Loc.t("Send %d") % (i + 1))
			var n_t: int = s.choose_option(p, Loc.t("%s: send how many cards from the top of your Deck to the Graveyard?") % name, labels_t, most - 1, c) + 1
			for i in n_t:
				var top_t = ps.deck.pop_back()
				s._to_gy(ps, top_t)
				events.append({"type": "mill", "player": p, "card": top_t, "deck": ps.deck.size()})
				events.append_array(trigger(s, top_t, "sent_gy"))
			if c.atk_mod_turn != s.turn:
				c.atk_mod_turn = s.turn
				c.atk_mod_t = 0
			c.atk_mod_t += 500 * n_t
			events.append(_ev(p, c, Loc.t("%s: %d ATK until the end of this turn") % [name, 500 * n_t]))
		"necroid":
			# "Target 1 monster your opponent controls; destroy that target, then Special Summon 1 monster from
			# your opponent's GY to their field."
			var t_s = _best_opp(s, p, "", c, "destroy 1 monster")
			if t_s == null:
				return events
			events.append(_ev(p, c, Loc.t("%s destroys %s") % [name, t_s.cname() if t_s.face_up else Loc.t("the face-down monster")]))
			events.append_array(s._destroy(t_s))
			if opp.field.has(t_s):
				return events
			var back_s: Array = opp.gy.filter(func(g): return g.is_monster() and s.can_revive(g))
			if back_s.is_empty() or opp.free_zone() == -1:
				return events
			var weak_s = back_s[0]
			for g in back_s:
				if g.atk() < weak_s.atk():
					weak_s = g
			weak_s = s.pick1(p, Loc.t("%s: Special Summon which monster to the opponent's field?") % name, back_s, weak_s, c)
			opp.gy.erase(weak_s)
			events.append(_ev(p, c, Loc.t("%s comes back to the opponent's field") % weak_s.cname()))
			events.append_array(s._special(opp_i, weak_s, "reborn", "atk"))
		"electrum":
			# "When this card is Fusion Summoned: Shuffle all banished cards into the Deck(s)."
			var n_e := 0
			for q in 2:
				for b in s.players[q].banished.duplicate():
					var hold := false
					for q3 in 2:
						for ex in s.players[q3].exiles:
							if ex["card"] == b:
								hold = true      # only away for a while (Shooting Star Dragon): it is on its way back
					if hold:
						continue
					s.players[q].banished.erase(b)
					if b.is_monster() and b.frame() in ["fusion", "synchro", "xyz"]:
						s.players[q].extra.append(b)
					else:
						s.players[q].deck.append(b)
					n_e += 1
				s._shuffle(s.players[q].deck)
			events.append(_ev(p, c, Loc.t("%s: %d banished cards are shuffled into the Decks") % [name, n_e]))
		"heal_victim_atk":
			var v_h = ctx.get("victim")
			if v_h != null and (s.players[0].gy.has(v_h) or s.players[1].gy.has(v_h)) and v_h.atk() > 0:
				ps.lp += v_h.atk()
				events.append(_ev(p, c, Loc.t("%s: gain %d LP") % [name, v_h.atk()]))
				events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": v_h.atk()})
		"wroughtweiler":
			# "Target 1 "Elemental HERO" card and 1 "Polymerization" in your GY; add them to your hand."
			var heroes_w: Array = ps.gy.filter(func(g): return g != c and str(g.data.get("name", "")).contains("Elemental HERO"))
			var polys_w: Array = ps.gy.filter(func(g): return g.cname() == "Polymerization")
			if heroes_w.is_empty() or polys_w.is_empty():
				return events
			var best_w = heroes_w[0]
			for g in heroes_w:
				if s._card_value(g) > s._card_value(best_w):
					best_w = g
			best_w = s.pick1(p, Loc.t("%s: add which \"Elemental HERO\" card to your hand?") % name, heroes_w, best_w, c)
			for g in [best_w, polys_w[0]]:
				ps.gy.erase(g)
				ps.hand.append(g)
				events.append(_ev(p, c, Loc.t("%s returns %s to the hand") % [name, g.cname()]))
				events.append({"type": "gy_to_hand", "player": p, "card": g})
				events.append_array(added_by_effect(s, p, g))
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
		# ---- v0.33.30: Yugi's cards
		"catapult":
			# Catapult Turtle: Tribute 1 monster; damage equal to half its ATK on the field.
			var ammo: Array = ps.monsters().filter(func(m): return s.can_tribute_fx(m))
			if not ammo.is_empty():
				var shot = ammo[0]
				for m in ammo:
					if m != c and (shot == c or s.atk_of(m, false) > s.atk_of(shot, false)):
						shot = m
				shot = s.pick1(p, Loc.t("%s: Tribute 1 monster") % name, ammo, shot, c)
				var half_atk: int = s.atk_of(shot, false) / 2 if shot.face_up else shot.atk() / 2
				ps.field[ps.field.find(shot)] = null
				s._to_gy(ps, shot)
				events.append({"type": "tribute", "player": p, "card": shot})
				events.append_array(trigger(s, shot, "tributed"))
				events.append_array(s._monster_left(shot))
				events.append(_ev(p, c, Loc.t("%s launches %s: %d damage") % [name, shot.cname(), half_atk]))
				events.append_array(s._damage(opp_i, half_atk))
		"special_named_any":
			# 1 card with that name from your hand, Deck, or Graveyard (Skilled Dark Magician, Dedication).
			for src in [ps.hand, ps.deck, ps.gy]:
				var got_n: Array = _take(src, {"name": str(a[1])}, 1)
				if not got_n.is_empty() and ps.free_zone() != -1:
					var dm = got_n[0]
					var was_gy: bool = src == ps.gy
					src.erase(dm)
					if src == ps.deck:
						s._shuffle(ps.deck)
					events.append(_ev(p, c, Loc.t("%s calls %s") % [name, dm.cname()]))
					events.append_array(s._special(p, dm, "reborn" if was_gy else "effect"))
					events.append_array(on_summon(s, p, dm, "special"))
					break
		"magnet_split":
			# Valkyrion: Alpha, Beta and Gamma return from your Graveyard.
			for nm in a[1]:
				var parts: Array = ps.gy.filter(func(g): return g.cname() == str(nm))
				if not parts.is_empty() and ps.free_zone() != -1:
					ps.gy.erase(parts[0])
					events.append_array(s._special(p, parts[0], "reborn"))
		"gandora":
			# Destroy as many cards on the field as possible (other than this card) and banish them; +300 ATK each.
			var wiped := 0
			for q in [opp_i, p]:
				for m in s.players[q].monsters():
					if m != c:
						var ev_m := s._destroy(m)
						events.append_array(ev_m)
						if not (s.players[0].field.has(m) or s.players[1].field.has(m)):
							wiped += 1
							events.append_array(s._banish(m))
				var sts: Array = s.players[q].set_cards()
				if s.players[q].field_spell != null:
					sts.append(s.players[q].field_spell)
				for st in sts:
					events.append_array(s._destroy_st(st))
					wiped += 1
					events.append_array(s._banish(st))
			c.atk_mod += 300 * wiped
			events.append(_ev(p, c, Loc.t("%s destroys and banishes %d cards: +%d ATK") % [name, wiped, 300 * wiped]))
		"gy_self":
			# "...Send it to the Graveyard" (Gandora in the End Phase of the turn it was Summoned).
			if ps.field.has(c):
				ps.field[ps.field.find(c)] = null
				s._to_gy(ps, c)
				events.append(_ev(p, c, Loc.t("%s goes to the Graveyard") % name))
				events.append({"type": "destroy", "player": p, "card": c, "zone": -1, "overlays": []})
				events.append_array(s._monster_left(c))
		"gy_spell_to_hand":
			# Dark Magician of Chaos: 1 Spell from your Graveyard to your hand (once per turn, by name).
			var spells_gy: Array = ps.gy.filter(func(g): return g.is_spell())
			if not spells_gy.is_empty() and int(ps.once_names.get(name, -1)) != s.turn:
				spells_gy.sort_custom(func(x, y): return s._card_value(x) > s._card_value(y))
				var take_sp := s.choose(p, Loc.t("%s: add 1 Spell from your Graveyard to your hand") % name, spells_gy, 1, [spells_gy[0]], true, c)
				if not take_sp.is_empty():
					ps.once_names[name] = s.turn
					ps.gy.erase(take_sp[0])
					ps.hand.append(take_sp[0])
					events.append(_ev(p, c, Loc.t("%s brings %s back to the hand") % [name, take_sp[0].cname()]))
					events.append({"type": "gy_to_hand", "player": p, "card": take_sp[0]})
		"level_up_any":
			# Send this card to the Graveyard; Special Summon its next form from your hand or Deck.
			for src in [ps.hand, ps.deck]:
				var next_f: Array = src.filter(func(d): return d.cname() == str(a[1]))
				if not next_f.is_empty() and ps.field.has(c):
					if a.size() > 2 and str(a[2]) == "ask" and s.choose_option(p, Loc.t("%s: send it to the Graveyard and Special Summon %s?") % [name, str(a[1])], ["Yes", "No"], 0, c) != 0:
						break
					ps.field[ps.field.find(c)] = null
					s._to_gy(ps, c)
					events.append({"type": "tribute", "player": p, "card": c})
					events.append_array(s._monster_left(c))
					src.erase(next_f[0])
					if src == ps.deck:
						s._shuffle(ps.deck)
					next_f[0].proper = true
					events.append(_ev(p, c, Loc.t("%s levels up!") % name))
					events.append_array(s._special(p, next_f[0], "effect"))
					break
		# ---- v0.33.28: Yusei's cards
		"tokens":
			# ["tokens", n, name, id, atk, def, level, attribute, race, pos, no tribute summon]
			CardData.TOKENS[int(a[3])] = {"name": str(a[2]), "frame": "token", "atk": int(a[4]), "def": int(a[5]), "level": int(a[6]),
					"attribute": str(a[7]), "race": str(a[8]), "no_tribute_summon": a.size() > 10 and bool(a[10]),
					"desc": Loc.t("This card can be used as a \"%s\".") % str(a[2])}
			var made := 0
			for i in int(a[1]):
				if ps.free_zone() == -1:
					break
				events.append_array(s._special(p, s._make(int(a[3]), p), "effect", str(a[9]) if a.size() > 9 else ""))
				made += 1
			if made > 0:
				events.push_front(_ev(p, c, Loc.t("%s: %d %s") % [name, made, str(a[2])]))
			s.last_summoned = null
		"may_draw":
			if not ps.deck.is_empty() and s.choose_option(p, Loc.t("%s: draw %d card?") % [name, int(a[1])], ["Draw", "No"], 0, c) == 0:
				events.append(_ev(p, c, Loc.t("%s: draw %d") % [name, a[1]]))
				events.append_array(s._draw(p, int(a[1])))
		"heal_level_other":
			# Healing Wave Generator: another face-up monster you control, its Level x 100.
			var friends: Array = ps.monsters().filter(func(m): return m != c and m.face_up and m.frame() != "xyz")
			if not friends.is_empty():
				friends.sort_custom(func(x, y): return x.level() > y.level())
				var hw = s.pick1(p, Loc.t("%s: gain LP equal to 1 other monster's Level x 100") % name, friends, friends[0], c)
				var gain_lp: int = hw.level() * 100
				ps.lp += gain_lp
				events.append(_ev(p, c, Loc.t("%s: gain %d LP") % [name, gain_lp]))
				events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": gain_lp})
		"damage_per_opp_hand":
			var burn: int = opp.hand.size() * int(a[1])
			if burn > 0:
				events.append(_ev(p, c, Loc.t("%s: %d damage") % [name, burn]))
				events.append_array(s._damage(opp_i, burn))
		"revive_race_any_gy":
			# Colossal Fighter: 1 monster of that Type in either Graveyard (itself counts).
			var dead: Array = []
			for q in 2:
				for g in s.players[q].gy:
					if g.is_monster() and str(g.data.get("race", "")) == str(a[1]) and s.can_revive(g):
						dead.append(g)
			if not dead.is_empty() and ps.free_zone() != -1:
				dead.sort_custom(func(x, y): return x.atk() > y.atk())
				var rise := s.choose(p, Loc.t("%s: Special Summon 1 %s monster from either Graveyard") % [name, str(a[1])], dead, 1, [dead[0]], true, c)
				if not rise.is_empty():
					var up = rise[0]
					s.players[up.owner].gy.erase(up)
					events.append(_ev(p, c, Loc.t("%s brings back %s") % [name, up.cname()]))
					if up.owner != p:
						up.orig_owner = up.owner
						up.owner = p
					events.append_array(s._special(p, up, "reborn"))
					events.append_array(on_summon(s, p, up, "special"))
		"exile_opp_end":
			# Junk Archer: banish 1 of their monsters; it returns to their field in this turn's End Phase.
			var away = _best_opp(s, p, "", c, Loc.t("banish 1 monster until the End Phase"))
			if away != null:
				var away_atk: bool = away.attack_pos or not away.face_up
				var away_tok: bool = away.is_token()
				events.append(_ev(p, c, Loc.t("%s sends %s away until the End Phase") % [name, away.cname() if away.face_up else Loc.t("a Set monster")]))
				events.append_array(s._banish(away))
				if not away_tok and s.players[away.owner].banished.has(away):
					ps.exiles.append({"card": away, "to": opp_i, "left": 0, "atk_pos": away_atk, "end": true})
		"destroy_up_to_non_tuners":
			# Junk Destroyer: cards on the field, up to the number of non-Tuners used for its Synchro Summon.
			var cap := int(c.tags.get("non_tuners", 1))
			var all_cards: Array = []
			var theirs: Array = []
			for q in [opp_i, p]:
				for m in s.players[q].monsters():
					if m != c:
						all_cards.append(m)
						if q == opp_i:
							theirs.append(m)
				for st in s.players[q].spells:
					if st != null:
						all_cards.append(st)
						if q == opp_i:
							theirs.append(st)
				if s.players[q].field_spell != null:
					all_cards.append(s.players[q].field_spell)
					if q == opp_i:
						theirs.append(s.players[q].field_spell)
			theirs.sort_custom(func(x, y): return (s.atk_of(x, false) if x.is_monster() and s.players[opp_i].field.has(x) else 1500) > (s.atk_of(y, false) if y.is_monster() and s.players[opp_i].field.has(y) else 1500))
			var hits: Array = []
			var left_n := cap
			var auto_n := mini(cap, theirs.size())
			if s.manual[p]:
				# The player picks one card at a time and may stop early.
				while left_n > 0 and not all_cards.is_empty():
					var one := s.choose(p, Loc.t("%s: destroy a card (%d left). Skip to stop.") % [name, left_n], all_cards, 1, [theirs[hits.size()]] if hits.size() < auto_n else [], true, c)
					if one.is_empty():
						break
					hits.append(one[0])
					all_cards.erase(one[0])
					left_n -= 1
			else:
				hits = theirs.slice(0, auto_n)
			if not hits.is_empty():
				events.append(_ev(p, c, Loc.t("%s destroys %d card%s") % [name, hits.size(), "" if hits.size() == 1 else "s"]))
			for h in hits:
				if h.is_monster() and (s.players[0].field.has(h) or s.players[1].field.has(h)):
					events.append_array(s._destroy(h))
				else:
					events.append_array(s._destroy_st(h))
		"junk_berserker":
			# Banish 1 "Junk" monster from your Graveyard; 1 face-up monster they control loses that much ATK.
			var junk: Array = ps.gy.filter(func(g): return g.is_monster() and CardEffects.matches(g.data, {"has": "Junk"}))
			var foes: Array = opp.monsters().filter(func(m): return m.face_up)
			if not junk.is_empty() and not foes.is_empty():
				junk.sort_custom(func(x, y): return x.atk() > y.atk())
				var fuel = s.pick1(p, Loc.t("%s: banish 1 \"Junk\" monster from your Graveyard") % name, junk, junk[0], c)
				var foe = s.pick1(p, Loc.t("%s: which monster loses %d ATK?") % [name, fuel.atk()], foes, s._strongest_face_up(opp_i), c)
				events.append_array(s._banish(fuel))
				foe.atk_mod -= fuel.atk()
				events.append(_ev(p, c, Loc.t("%s loses %d ATK") % [foe.cname(), fuel.atk()]))
		"any_change_pos":
			# Junk Gardna, sent from the field to the Graveyard: 1 monster on the field changes position.
			var every_m: Array = opp.monsters() + ps.monsters()
			if not every_m.is_empty():
				var auto_m = null
				for m in opp.monsters():
					if m.attack_pos and (auto_m == null or s.atk_of(m, false) > s.atk_of(auto_m, false)):
						auto_m = m
				var turned := s.choose(p, Loc.t("%s: change the battle position of 1 monster") % name, every_m, 1, [auto_m] if auto_m != null else [], true, c)
				if not turned.is_empty():
					events.append_array(_flip_pos(s, p, c, turned[0]))
		"drill_warrior":
			var open: Array = _drill_options(s, p, c)
			if open.is_empty():
				return events
			var labels: Array = []
			for o in open:
				labels.append(Loc.t("Halve its ATK: it can attack directly this turn") if o == "direct" else Loc.t("Discard 1 card: banish it until your next Standby Phase"))
			# (The computer goes for the direct attack when that is worth more than a normal attack.)
			var auto_o := 0
			var which: String = open[s.choose_option(p, Loc.t("%s: which effect?") % name, labels, auto_o, c)]
			if which == "direct":
				c.tags["dw_direct"] = s.turn
				c.atk_mod -= s.atk_of(c, false) / 2
				c.tags["direct_turn"] = s.turn
				events.append(_ev(p, c, Loc.t("%s halves its ATK and can attack directly this turn") % name))
			else:
				var hand_c: Array = ps.hand.duplicate()
				hand_c.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
				var toss = s.pick1(p, Loc.t("%s: discard 1 card") % name, hand_c, hand_c[0], c)
				ps.hand.erase(toss)
				s._to_gy(ps, toss)
				events.append({"type": "discard", "player": p, "card": toss})
				if ps.field.has(c):
					var dw_pos: bool = c.attack_pos
					events.append(_ev(p, c, Loc.t("%s drills out of sight until your next Standby Phase") % name))
					events.append_array(s._banish(c))
					if s.players[c.owner].banished.has(c):
						ps.exiles.append({"card": c, "to": p, "left": 1, "atk_pos": dw_pos, "then": "gy_monster_to_hand"})
		"ssd_excavate":
			# Shooting Star Dragon: the top 5 cards; one attack this Battle Phase for each Tuner among them.
			var top: Array = []
			for i in mini(5, ps.deck.size()):
				top.append(ps.deck[ps.deck.size() - 1 - i])
			var tuners_n := 0
			var seen: Array = []
			for t in top:
				seen.append(t.cname())
				if t.is_monster() and t.is_tuner():
					tuners_n += 1
			s._shuffle(ps.deck)
			c.bonus_attacks = tuners_n - 1
			c.bonus_attacks_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s reveals %s: %d Tuner%s, so it can attack %d time%s this turn") % [name, ", ".join(seen), tuners_n, "" if tuners_n == 1 else "s", tuners_n, "" if tuners_n == 1 else "s"]))
		"special_extra_named":
			# Shooting Quasar Dragon leaves the field: "Shooting Star Dragon" comes out of the Extra Deck.
			for x in ps.extra.duplicate():
				if x.cname() == str(a[1]) and ps.free_zone() != -1 and ps.no_summon_turn != s.turn:
					if s.choose_option(p, Loc.t("%s: Special Summon %s from your Extra Deck?") % [name, x.cname()], ["Special Summon it", "No"], 0, c) == 0:
						ps.extra.erase(x)
						events.append(_ev(p, c, Loc.t("%s calls %s") % [name, x.cname()]))
						events.append_array(s._special(p, x, "effect"))
						events.append_array(on_summon(s, p, x, "special"))
					break
		"hyper_synchron":
			var into = ctx.get("into")
			if into != null and s.players[p].field.has(into):
				into.atk_mod += 800
				into.tags["banish_end"] = true
				events.append(_ev(p, c, Loc.t("%s: %s gains 800 ATK and is banished in the End Phase") % [name, into.cname()]))
		"opp_lose_atk_turn":
			# Ghost Gardna: 1 face-up monster they control loses that much ATK until the End Phase.
			var lose = s._strongest_face_up(opp_i)
			if lose != null:
				lose = s.pick1(p, Loc.t("%s: which monster loses %d ATK?") % [name, int(a[1])], opp.monsters().filter(func(m): return m.face_up), lose, c)
				if lose.atk_mod_turn != s.turn:
					lose.atk_mod_turn = s.turn
					lose.atk_mod_t = 0
				lose.atk_mod_t -= int(a[1])
				events.append(_ev(p, c, Loc.t("%s loses %d ATK until the End Phase") % [lose.cname(), int(a[1])]))
		"protect_turn":
			# Zero Gardna: your monsters cannot be destroyed by battle and you take no battle damage this turn.
			ps.protect_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s: no battle destruction and no battle damage for you this turn") % name))
		"boost_own_pick":
			var mine_up: Array = ps.monsters().filter(func(m): return m.face_up)
			if not mine_up.is_empty():
				var strong = s._strongest_face_up(p)
				if not s.pending_attack.is_empty():
					for bm in [s.pending_attack["attacker"], s.pending_attack["target"]]:
						if bm != null and ps.field.has(bm) and bm.face_up:
							strong = bm
				var lift = s.pick1(p, Loc.t("%s: which monster gains %d ATK?") % [name, int(a[1])], mine_up, strong, c)
				if lift.atk_mod_turn != s.turn:
					lift.atk_mod_turn = s.turn
					lift.atk_mod_t = 0
				lift.atk_mod_t += int(a[1])
				events.append(_ev(p, c, Loc.t("%s gains %d ATK until the end of this turn") % [lift.cname(), int(a[1])]))
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
			events.append_array(added_by_effect(s, p, d))
		"gy_to_hand":
			for d in _pick(s, p, c, "add from your Graveyard to your hand", ps.gy, a[1], int(a[2])):
				ps.gy.erase(d)
				ps.hand.append(d)
				events.append(_ev(p, c, Loc.t("%s returns %s to the hand") % [name, d.cname()]))
				events.append({"type": "gy_to_hand", "player": p, "card": d, "deck": ps.deck.size()})
		"special":
			var src: Array = ps.deck if a[1] == "deck" else (ps.hand if a[1] == "hand" else ps.gy)
			var n: int = int(a[4]) if a.size() > 4 else 1
			var pool: Array = src.filter(func(x): return s.can_revive(x)) if a[1] == "gy" else src.filter(func(x): return _ss_ok(x))
			var flt: Dictionary = a[2]
			if a[1] == "gy":
				flt = flt.duplicate()
				flt["zone"] = "gy"
			if a[1] == "hand_gy":
				# "...from your hand or Graveyard" (Salvage Warrior).
				pool = ps.hand.filter(func(x): return _ss_ok(x))
				pool.append_array(ps.gy.filter(func(x): return s.can_revive(x)))
			if s.ss_locked(p):
				pool = []   # Gagaga Head's lock
			pool = pool.filter(func(x): return not s.big_locked(p, x))   # Crimson Blader
			for d in _pick(s, p, c, Loc.t("Special Summon from your %s") % ("Deck" if a[1] == "deck" else ("hand" if a[1] == "hand" else ("hand or Graveyard" if a[1] == "hand_gy" else "Graveyard"))), pool, flt, n):
				if ps.free_zone() == -1:
					break
				if a[1] != "hand_gy" and not src.has(d):
					continue   # it already came out (Hero Kid: the first one out called the next)
				var from_gy: bool = a[1] == "gy" or (a[1] == "hand_gy" and ps.gy.has(d))
				if a[1] == "hand_gy":
					ps.hand.erase(d)
					ps.gy.erase(d)
				src.erase(d)
				if a[1] == "deck":
					s._shuffle(ps.deck)
				events.append(_ev(p, c, Loc.t("%s calls %s") % [name, d.cname()]))
				var ev := s._special(p, d, "reborn" if from_gy else "effect", "def" if a.size() > 3 and a[3] == "def" else ("atk" if a.size() > 3 and a[3] == "atk" else ""))
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
			var all_m: Array = opp.monsters().filter(func(m): return can_target(c, m))
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
					if m.face_up and m != c and can_target(c, m):
						ups.append(m)
			if not ups.is_empty():
				var auto = s._strongest_face_up(opp_i)
				if auto != null and not ups.has(auto):
					auto = null
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
		"opp_mill_type":
			# Vampire Lord: declare Monster, Spell or Trap; the opponent sends 1 card of that type
			# from their Deck to the Graveyard (their pick).
			var type_i: int = s.choose_option(p, Loc.t("%s: declare a card type") % name, [Loc.t("Monster"), Loc.t("Spell"), Loc.t("Trap")], 0, c)
			var of_type: Array = opp.deck.filter(func(x): return x.is_monster() if type_i == 0 else (x.is_spell() if type_i == 1 else x.is_trap()))
			events.append(_ev(p, c, Loc.t("%s declares: %s") % [name, [Loc.t("Monster"), Loc.t("Spell"), Loc.t("Trap")][type_i]]))
			if of_type.is_empty():
				return events
			var sent_pick: Array = s.choose(opp_i, Loc.t("%s: send 1 card of that type from your Deck to the Graveyard") % name, of_type, 1, [of_type[0]], false, c)
			var sent_c = sent_pick[0] if not sent_pick.is_empty() else of_type[0]
			opp.deck.erase(sent_c)
			s._to_gy(opp, sent_c)
			s._shuffle(opp.deck)
			events.append({"type": "mill", "player": opp_i, "card": sent_c, "deck": opp.deck.size()})
		"wisp_level":
			# Umbral Horror Will o' the Wisp: you can target 1 other "Umbral Horror" monster you
			# control or in your GY; this card's Level becomes that monster's current Level.
			var uh: Array = []
			for m2 in ps.monsters():
				if m2 != c and m2.face_up and m2.frame() != "xyz" and m2.cname().contains("Umbral Horror"):
					uh.append(m2)
			for g2 in ps.gy:
				if g2 != c and g2.is_monster() and g2.frame() != "xyz" and g2.cname().contains("Umbral Horror"):
					uh.append(g2)
			if uh.is_empty() or not ps.field.has(c):
				return events
			var best_lv = uh[0]
			for u in uh:
				if u.level() > best_lv.level():
					best_lv = u
			var lv_pick: Array = s.choose(p, Loc.t("%s: take the Level of which Umbral Horror monster?") % name, uh, 1, [best_lv], true, c)
			if lv_pick.is_empty():
				return events
			c.lv_set = lv_pick[0].level()
			c.lv_turn = -1
			events.append(_ev(p, c, Loc.t("%s is now Level %d") % [name, c.lv_set]))
		"cowboy":
			# Gagaga Cowboy: what the effect does depends on its battle position right now.
			if c.attack_pos:
				c.cowboy_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s: +1000 ATK when it attacks a monster this turn, and that monster loses 500") % name))
			else:
				events.append_array(run(s, p, c, ["damage", 800], ctx))
		"zero_negate_opp":
			# Starliege Paladynamo: 1 face-up monster the opponent controls; its ATK becomes 0 and its
			# effects are negated, for as long as it stays on the field.
			var ups2: Array = opp.monsters().filter(func(m): return m.face_up)
			if ups2.is_empty():
				return events
			var zt = s.pick1(p, Loc.t("%s: choose the monster whose ATK becomes 0") % name, ups2, s._strongest_face_up(opp_i), c)
			zt.zero_perm = true
			zt.neg_perm = true
			zt.negated = true
			events.append(_ev(p, c, Loc.t("%s: ATK 0, effects negated") % zt.cname()))
		"alch_boost":
			# Dimensional Alchemist: banish the top card of your Deck, and if you do, +500 ATK this turn.
			if ps.deck.is_empty():
				return events
			var top_c = ps.deck[ps.deck.size() - 1]
			events.append_array(s._banish(top_c))
			if ps.banished.has(top_c):
				c.atk_mod_turn = s.turn
				c.atk_mod_t = 500
				events.append(_ev(p, c, Loc.t("%s gains %d ATK this turn") % [name, 500]))
		"banished_to_hand":
			# "You can target 1 of your banished monsters; add it to your hand."
			var out_m: Array = ps.banished.filter(func(x): return x.is_monster() and not x.is_token())
			if out_m.is_empty():
				return events
			var back_pick: Array = s.choose(p, Loc.t("%s: add 1 of your banished monsters to your hand?") % name, out_m, 1, s._best_monsters(out_m, 1), true, c)
			if back_pick.is_empty():
				return events
			ps.banished.erase(back_pick[0])
			ps.hand.append(back_pick[0])
			events.append({"type": "unbanish", "player": p, "card": back_pick[0], "to": "hand"})
			events.append({"type": "gy_to_hand", "player": p, "card": back_pick[0]})
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
						events.append_array(s._monster_left(c))
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
