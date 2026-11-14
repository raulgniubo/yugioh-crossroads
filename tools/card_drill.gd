extends SceneTree
## Dev tool: the card drill. Every card in the game is put through the rules engine.
##
## Part 1, every card: a full duel is played with that card stacked into one deck. The duel
##   must run to its end with the card count intact.
## Part 2, every effect monster: the card is put through a set of standard situations (summoned,
##   flipped, attacking, attacked, destroyed, a turn passing, its ignition effect...) twice,
##   once as itself and once as a blank twin with the same numbers and no effect. If the two
##   never come out different, the effect never showed, and the card is flagged.
## Part 3, every Spell and Trap: activated (or Set and answered with) on a standard field. The
##   field must come out different than it went in.
##
## godot --headless -s tools/card_drill.gd -- [folder] [--only=Card Name]

const VANILLA := ["Celtic Guardian", "Mystical Elf", "Battle Ox", "Gemini Elf", "Giant Soldier of Stone", "Feral Imp", "Baby Dragon",
	"Silver Fang", "Mammoth Graveyard", "Dark Magician", "Blue-Eyes White Dragon", "Summoned Skull", "La Jinn the Mystical Genie of the Lamp",
	"Vorse Raider", "Luster Dragon", "Aqua Madoor", "Harpie Lady", "Mechanicalchaser", "Charcoal Inpachi", "Sonic Duck"]

var col: Node
var van: Array[int] = []
var only := ""
var flagged: Array = []


func _initialize() -> void:
	var folder := "/tmp/testassets2"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
		elif not a.begins_with("--"):
			folder = a
	CardData.load_external(folder)
	col = get_root().get_node("Collection")
	for n in VANILLA:
		var id := _id(n)
		if id != 0:
			van.append(id)
	var ids: Array = col.every_playable()
	ids.sort()
	# ---- Part 1
	var played := 0
	var bad_games := 0
	for id in ids:
		var d := CardData.get_card(id)
		if only != "" and str(d.get("name", "")) != only:
			continue
		print("DRILL1 ", d.get("name", ""))
		var why := _game(id)
		played += 1
		if why != "":
			bad_games += 1
			print("GAME PROBLEM|", d.get("name", ""), "|", why)
	print("PART 1: ", played, " cards each played a full duel; problems: ", bad_games)
	# ---- Part 2
	var mons := 0
	var shown := 0
	for id in ids:
		var d := CardData.get_card(id)
		var nm := str(d.get("name", ""))
		if str(d.get("kind", "monster")) != "monster" or (only != "" and nm != only):
			continue
		if not (CardEffects.has(nm) or CardData.MONSTER_EFFECTS.has(nm)):
			continue
		mons += 1
		print("DRILL2 ", nm)
		var where := _monster(id)
		if where == "":
			flagged.append(nm)
			print("NEVER SHOWED|", nm, "|", str(CardEffects.of(nm)).substr(0, 260))
		else:
			shown += 1
			if only != "":
				print("  showed in: ", where)
	print("PART 2: ", mons, " effect monsters; effect showed for ", shown, "; never showed: ", mons - shown)
	# ---- Part 3
	var sts := 0
	var worked := 0
	for id in ids:
		var d := CardData.get_card(id)
		var nm := str(d.get("name", ""))
		if str(d.get("kind", "monster")) == "monster" or (only != "" and nm != only):
			continue
		sts += 1
		print("DRILL3 ", nm)
		var res := _spell(id)
		if res.begins_with("ok"):
			worked += 1
			if only != "":
				print("  ", res)
		else:
			print("NO CHANGE|", nm, "|", res, "|", str(SpellRules.FX.get(nm, d.get("effect", ""))).substr(0, 200))
	print("PART 3: ", sts, " Spells and Traps; changed the field: ", worked, "; did not: ", sts - worked)
	quit()


func _id(name: String) -> int:
	return int(CardData.NAME_TO_ID.get(name.to_lower(), 0))


# ------------------------------------------------------------------ part 1

func _deck(with_id: int, copies: int) -> Array[int]:
	var out: Array[int] = []
	var d := CardData.get_card(with_id)
	if not (str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]):
		for i in copies:
			out.append(with_id)
	var k := 0
	while out.size() < 40:
		out.append(van[k % van.size()])
		k += 1
	return out


func _total(s: DuelState) -> int:
	var t := 0
	for ps in s.players:
		t += ps.deck.size() + ps.hand.size() + ps.gy.size() + ps.extra.size() + ps.banished.size()
		t += 1 if ps.field_spell != null else 0
		for st in ps.spells:
			t += 1 if st != null else 0
		for m in ps.monsters():
			t += (0 if m.is_token() else 1) + m.overlays.size()
	return t


func _game(id: int) -> String:
	var s := DuelState.new()
	var d := CardData.get_card(id)
	var extra: Array[int] = []
	if str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]:
		extra.append(id)
	var none: Array[int] = []
	s.setup(_deck(id, 3), _deck(0, 0), "A", "B", 0, id % 9973, extra, none)
	# One copy starts in the hand, so the card is seen in every drill.
	var ps := s.players[0]
	for c in ps.deck:
		if c.id == id:
			ps.deck.erase(c)
			ps.deck.append(ps.hand.pop_back())
			ps.hand.append(c)
			break
	if not extra.is_empty() or str(d.get("frame", "")) == "ritual":
		# Extra Deck and Ritual monsters start on the field: the drill is about what they do there.
		var m: DuelState.CardInst = ps.extra.pop_back() if not extra.is_empty() else null
		if m == null:
			for c in ps.hand:
				if c.id == id:
					m = c
					ps.hand.erase(c)
					break
		if m != null:
			ps.field[2] = m
			m.proper = true
	var start := _total(s)
	var guard := 0
	while not s.is_over() and guard < 60:
		guard += 1
		s.begin_turn()
		if s.is_over():
			break
		var p := s.current
		var steps := 0
		while steps < 20:
			steps += 1
			var act := DuelAI.next_main_action(s, p, 1)
			if act.is_empty() or DuelAI.apply(s, p, act).is_empty():
				break
			if not s.chain.is_empty():
				s.chain_resolve()
		if s.can_enter_battle():
			s.enter_battle()
			steps = 0
			while steps < 10 and not s.is_over():
				steps += 1
				var atk := DuelAI.next_attack(s, p, 1)
				if atk.is_empty() or s.declare_attack(p, atk["card"], atk["target"]).is_empty():
					break
				var dd := s.opponent(p)
				var r = DuelAI.choose_response(s, dd, "attack", s.responses(dd, "attack"), 1)
				if r != null:
					s.respond(dd, r)
				s.resolve_attack()
			s.enter_main2()
		if s.is_over():
			break
		s.end_turn()
		if _total(s) != start:
			return "card count changed from %d to %d on turn %d" % [start, _total(s), s.turn]
	return ""


# ------------------------------------------------------------------ the standard field

func _put(s: DuelState, p: int, id: int, zone: int, atk_pos := true, up := true) -> DuelState.CardInst:
	var c := s._make(id, p)
	s.players[p].field[zone] = c
	c.attack_pos = atk_pos
	c.face_up = up
	c.summoned_turn = s.turn - 1
	return c


## A plain monster with the numbers (and Type) a situation needs.
func _dummy(s: DuelState, p: int, zone: int, atk: int, def: int, atk_pos := true, extra := {}) -> DuelState.CardInst:
	var c := _put(s, p, van[0], zone, atk_pos)
	c.data = c.data.duplicate()
	c.data["name"] = "Dummy"
	c.data["atk"] = atk
	c.data["def"] = def
	c.data.merge(extra, true)
	return c


var _found := {}

## A card in the game that fits a filter (not the card under test).
func _find(f: Dictionary, not_name := "") -> int:
	var key := str(f) + not_name
	if _found.has(key):
		return _found[key]
	var best := 0
	for id in col.every_playable():
		var d := CardData.get_card(id)
		if str(d.get("name", "")) != not_name and CardEffects.matches(d, f) and not (str(d.get("frame", "")) in ["fusion", "synchro", "xyz", "ritual"]):
			best = id
			if str(d.get("frame", "")) == "normal":
				break
	_found[key] = best
	return best


func _strings(v, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Dictionary:
		for k in v:
			if k != "note" and k != "label":
				_strings(v[k], out)
	elif v is Array:
		for x in v:
			_strings(x, out)


## Turn 3, your Main Phase, plain decks and three plain monsters in each Graveyard.
func _arena() -> DuelState:
	var s := DuelState.new()
	s.manual = [false, false]
	var none: Array[int] = []
	s.setup(_deck(0, 0), _deck(0, 0), "A", "B", 0, 7, none, none)
	s.current = 0
	s.turn = 3
	s.phase = DuelState.Phase.MAIN1
	for p in 2:
		for n in ["Celtic Guardian", "Feral Imp", "Baby Dragon"]:
			s.players[p].gy.append(s._make(_id(n), p))
	return s


## Cards the effect looks for (by name, family, Type...) are put where it looks.
func _seed(s: DuelState, entry, self_name: String) -> void:
	var filters: Array = []
	_filters(entry, filters)
	for f in filters:
		var found := 0
		for id in col.every_playable():
			var d := CardData.get_card(id)
			if CardEffects.matches(d, f) and (str(d.get("name", "")) != self_name or f.has("name")):
				s.players[0].deck.insert(0, s._make(id, 0))
				s.players[0].deck.append(s._make(id, 0))
				s.players[0].gy.append(s._make(id, 0))
				s.players[0].hand.append(s._make(id, 0))
				found += 1
				if found >= 2:
					break
	# Any card the effect names outright (Armed Dragon LV5, Phoenixian Cluster Amaryllis...).
	var strs: Array = []
	_strings(entry, strs)
	for st in strs:
		for part in str(st).split(":"):
			var nid := _id(part)
			if nid != 0 and part != self_name and not CardData.is_extra(nid):
				s.players[0].deck.insert(0, s._make(nid, 0))
				s.players[0].hand.append(s._make(nid, 0))
				s.players[0].gy.append(s._make(nid, 0))
	# "gy_named:X" counters and the like.
	var text := str(entry)
	var re := RegEx.new()
	re.compile("(?:gy_named|named|own_has|field_named):([^\"\\]]+)")
	for m in re.search_all(text):
		var id := _id(m.get_string(1))
		if id != 0:
			s.players[0].gy.append(s._make(id, 0))
			s.players[1].gy.append(s._make(id, 1))


func _filters(v, out: Array) -> void:
	if v is Dictionary:
		var keys := ["name", "has", "race", "attr", "max_lv", "lv", "max_atk", "min_atk", "frame"]
		var is_filter := false
		for k in keys:
			if v.has(k):
				is_filter = true
		if is_filter:
			out.append(v)
		for k in v:
			_filters(v[k], out)
	elif v is Array:
		for x in v:
			_filters(x, out)


func _sig(s: DuelState, m = null, skip = null) -> String:
	var parts: Array = [s.winner]
	for p in 2:
		var ps := s.players[p]
		parts.append("%d/%d/%d/%d/%d/%d/%d" % [ps.lp, ps.hand.size() - (1 if ps.hand.has(skip) else 0), ps.deck.size(),
			ps.gy.size() - (1 if ps.gy.has(skip) else 0), ps.banished.size() - (1 if ps.banished.has(skip) else 0), ps.extra.size(), ps.skip_draw])
		for c in ps.field:
			if c == null:
				parts.append("-")
			else:
				parts.append("%s:%d:%d:%s%s:%d:%d:L%d" % ["M" if c == m else c.cname(), s.atk_of(c, false), s.def_of(c), "A" if c.attack_pos else "D", "u" if c.face_up else "d", c.overlays.size(), c.counter, c.level()])
		for c in ps.spells:
			parts.append("-" if c == null else "%s%s" % [c.cname(), "u" if c.face_up else "d"])
		parts.append("-" if ps.field_spell == null else ps.field_spell.cname())
	if m != null:
		parts.append("canatk%s" % s.can_attack(0, m) if s.current == 0 and s.phase == DuelState.Phase.BATTLE else "")
		for p in 2:
			var hn: Array = []
			for c in s.players[p].hand:
				hn.append("M" if c == m else c.cname())
			hn.sort()
			parts.append("+".join(PackedStringArray(hn)))
			var bn: Array = []
			for c in s.players[p].banished:
				bn.append("M" if c == m else c.cname())
			bn.sort()
			parts.append("+".join(PackedStringArray(bn)))
	return ",".join(PackedStringArray(parts.map(func(x): return str(x))))


# ------------------------------------------------------------------ part 2

## The card as itself (twin = false) or as a blank monster with the same numbers.
func _inst(s: DuelState, id: int, twin: bool) -> DuelState.CardInst:
	var c := s._make(id, 0)
	if twin:
		c.data = c.data.duplicate()
		c.data["name"] = "Blank Twin"
		c.data.erase("effect")
		c.data["frame"] = "normal" if not (str(c.data.get("frame", "")) in ["fusion", "synchro", "xyz", "ritual"]) else c.data["frame"]
	if str(c.data.get("frame", "")) == "xyz":
		c.overlays = [s._make(van[0], 0), s._make(van[1], 0)]
	return c


func _monster(id: int) -> String:
	var nm := str(CardData.get_card(id).get("name", ""))
	var entry = CardEffects.of(nm)
	var frame := str(CardData.get_card(id).get("frame", ""))
	var from_hand := not (frame in ["fusion", "synchro", "xyz", "ritual"])
	var names := ["summon", "set-flip", "attack weak", "attack wall", "attack direct", "blockers", "attacked", "attacked in defense",
		"attacked face-down", "destroyed", "turn passes", "ignition", "from hand", "in hand, attacked", "tributed", "on the field", "their turn passes",
		"discarded", "sent from Deck", "used as material", "banished"]
	names += ["Special Summoned", "Synchro Summoned", "attacks after a Spell", "a weak monster attacks it", "attacks a weak Plant", "in the Graveyard",
		"attacks a big wall", "attacks into a Trap", "summoned alone", "destroys a monster that has an effect", "another of yours falls in battle",
		"in hand while yours battles", "in the Graveyard when a Plant falls or arrives", "in the Graveyard when yours falls", "a turn after yours fell"]
	for pass_n in 2:
		empty_hand = pass_n == 1
		for k in names.size():
			if not from_hand and k in [0, 1, 12, 13, 17, 18, 29]:
				continue
			var a := _scene(id, k, false, entry, nm)
			var b := _scene(id, k, true, entry, nm)
			if a != b:
				return names[k] + (" (empty hand)" if empty_hand else "")
	return ""


var empty_hand := false

func _own_extras(s: DuelState, entry, nm: String) -> void:
	# What "if you control ..." conditions ask for: a family member, a Tuner, a WATER monster,
	# a LIGHT Machine, and two big monsters.
	var re := RegEx.new()
	re.compile("own_has:([^\"\\]]+)")
	var zone := 1
	for mm in re.search_all(str(entry)):
		var fid := _find({"has": mm.get_string(1)}, nm)
		if fid != 0 and zone < 4:
			_put(s, 0, fid, zone)
			zone += 1
	var re2 := RegEx.new()
	re2.compile("own_summoned_race:([^\"\\]]+)")
	for mm in re2.search_all(str(entry)):
		var fid4 := _find({"race": mm.get_string(1).split("|")[0]}, nm)
		if fid4 != 0 and zone < 4:
			var fresh := _put(s, 0, fid4, zone)
			fresh.summoned_turn = s.turn
			zone += 1
	var tuner := 0
	for id in col.every_playable():
		if CardData.get_card(id).get("tuner", false) and str(CardData.get_card(id).get("name", "")) != nm:
			tuner = id
			break
	if tuner != 0 and zone < 4:
		_put(s, 0, tuner, zone)
		zone += 1
	for f in [{"attr": "WATER"}, {"race": "Machine", "attr": "LIGHT"}]:
		var fid2 := _find(f, nm)
		if fid2 != 0 and zone < 4:
			_put(s, 0, fid2, zone)
			zone += 1
			s.players[0].gy.append(s._make(fid2, 0))


func _scene(id: int, k: int, twin: bool, entry, nm: String) -> String:
	var s := _arena()
	_seed(s, entry, nm)
	var me := s.players[0]
	var opp := s.players[1]
	var m := _inst(s, id, twin)
	var note := ""
	match k:
		0:  # Normal Summon from the hand
			me.hand.append(m)
			_put(s, 0, van[0], 3)
			_put(s, 0, van[1], 4)
			_put(s, 1, _id("Celtic Guardian"), 0)
			var fs := s._make(_id("Banner of Courage"), 1)
			opp.spells[1] = fs
			var ss := s._make(_id("Mirror Force"), 1)
			ss.face_up = false
			opp.spells[0] = ss
			var need := s.tributes_needed(m)
			var tr: Array = []
			for f in me.monsters():
				if tr.size() < need:
					tr.append(f)
			note = str(s.normal_summon(0, m, tr, false).size() > 0) + str(SpellRules.blocked(s, ss))
		1:  # Set, then Flip Summon on the next turn
			s.players[0].field[0] = m
			m.face_up = false
			m.attack_pos = false
			m.summoned_turn = 1
			_put(s, 1, _id("Celtic Guardian"), 0)
			_put(s, 0, van[0], 3)
			_put(s, 0, _id("Baby Dragon"), 4, false)
			var ss1 := s._make(_id("Mirror Force"), 1)
			ss1.face_up = false
			opp.spells[0] = ss1
			if s.can_flip_summon(0, m):
				s.flip_summon(0, m)
		2:  # attacks a weaker monster
			s.players[0].field[0] = m
			m.summoned_turn = 1
			_dummy(s, 1, 0, 0, 0)
			_put(s, 1, _id("Feral Imp"), 1)
			s.phase = DuelState.Phase.BATTLE
			if s.can_attack(0, m):
				s.attack(0, m, opp.field[0])
				note = "again%s" % s.can_attack(0, m)
		3:  # attacks a Defense Position monster
			s.players[0].field[0] = m
			m.summoned_turn = 1
			var wall := _put(s, 1, _id("Sonic Duck"), 0, false)
			s.phase = DuelState.Phase.BATTLE
			if s.atk_of(m, true) > s.def_of(wall):
				s.attack(0, m, wall)
				note = "again%s" % s.can_attack(0, m)
		4:  # attacks directly
			s.players[0].field[0] = m
			m.summoned_turn = 1
			s.phase = DuelState.Phase.BATTLE
			if s.can_attack(0, m):
				s.attack(0, m, null)
				note = "again%s" % s.can_attack(0, m)
		5:  # blockers in the way: can it go around them?
			s.players[0].field[0] = m
			m.summoned_turn = 1
			var outs: Array = []
			for layout in 4:
				var t := _arena()
				_seed(t, entry, nm)
				var tm := _inst(t, id, twin)
				t.players[0].field[0] = tm
				tm.summoned_turn = 1
				match layout:
					0:
						_put(t, 1, _id("Blue-Eyes White Dragon"), 0)
						_put(t, 1, _id("Mystical Elf"), 1, false)
					1:
						_put(t, 1, _id("Mystical Elf"), 0, false)
						_put(t, 1, _id("Giant Soldier of Stone"), 1, false)
					2:
						_put(t, 1, _id("Celtic Guardian"), 0)
						_put(t, 1, _id("Aqua Madoor"), 1)
					3:
						_put(t, 1, _id("Blue-Eyes White Dragon"), 0)
						_put(t, 1, _id("Dark Magician"), 1)
				if empty_hand:
					t.players[0].hand.clear()
				t.phase = DuelState.Phase.BATTLE
				var can := t.can_direct_attack_with(0, tm)
				if can:
					t.attack(0, tm, null)
				outs.append("%s%s" % [can, _sig(t, tm)])
			return "|".join(PackedStringArray(outs))
		6, 7, 8:  # a stronger monster attacks it
			s.players[0].field[0] = m
			m.summoned_turn = 1
			m.attack_pos = k == 6
			m.face_up = k != 8
			_put(s, 0, van[0], 3)
			var big := _put(s, 1, _id("Blue-Eyes White Dragon"), 0)
			var big2 := _put(s, 1, _id("Blue-Eyes White Dragon"), 1)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			if empty_hand:
				me.hand.clear()
			if s.attack_targets(1).has(m):
				s.declare_attack(1, big, m)
				var rr := s.responses(0, "attack", big)
				note = "offered%s" % rr.has(m)
				if rr.has(m):
					s.respond(0, m, big)
				s.resolve_attack()
				note += "there%s" % me.field.has(m)
				if me.field.has(m) and s.attack_targets(1).has(m):
					s.attack(1, big2, m)
		9:  # destroyed by a card effect
			s.players[0].field[0] = m
			_put(s, 1, _id("Celtic Guardian"), 0)
			s._destroy(m)
			s._cleanup()
		10:  # a whole turn of yours passes with it on the field
			s.players[0].field[0] = m
			_put(s, 1, _id("Celtic Guardian"), 0)
			_put(s, 0, van[0], 3)
			s.current = 0
			s.turn = 4
			s.begin_turn()
			if not s.is_over():
				s.end_turn()
		11:  # its ignition effect
			s.players[0].field[0] = m
			m.summoned_turn = 1
			_put(s, 1, _id("Celtic Guardian"), 0)
			_put(s, 1, _id("Mystical Elf"), 1, false)
			_put(s, 0, van[0], 3)
			_put(s, 0, van[1], 4)
			var set_card := s._make(_id("Mirror Force"), 1)
			set_card.face_up = false
			opp.spells[0] = set_card
			var fl2: Array = []
			_filters(entry, fl2)
			for f in fl2:
				var fid3 := _find(f, nm)
				if fid3 != 0:
					me.field[2] = null
					_put(s, 0, fid3, 2)
					break
			note = "can%s" % s.can_ignite(0, m)
			if s.can_ignite(0, m):
				s.ignite(0, m)
		12:  # Special Summon from the hand by its own rule
			me.hand.append(m)
			var out: Array = []
			for setup in 4:
				var t := _arena()
				_seed(t, entry, nm)
				var tm := _inst(t, id, twin)
				t.players[0].hand.append(tm)
				if setup != 1:
					_put(t, 1, _id("Celtic Guardian"), 0)
					_put(t, 1, _id("Battle Ox"), 1)
				if setup == 3:
					_put(t, 0, _id("Dark Magician"), 0)
					_put(t, 0, _id("Blue-Eyes White Dragon"), 1)
					_put(t, 0, _id("Summoned Skull"), 2)
				if setup == 2:
					_put(t, 0, _id("Blue-Eyes White Dragon"), 0)
					_own_extras(t, entry, nm)
				if empty_hand:
					t.players[0].hand = [tm]
				var ok := t.can_special_from_hand(0, tm)
				var need2 := t.tributes_needed(tm)
				if ok:
					t.special_from_hand(0, tm)
				out.append("%s%d%s" % [ok, need2, _sig(t, tm)])
			return "|".join(PackedStringArray(out))
		13:  # in the hand while they attack
			me.hand.append(m)
			_put(s, 0, van[0], 3)
			var atk := _put(s, 1, _id("Blue-Eyes White Dragon"), 0)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			s.declare_attack(1, atk, me.field[3])
			var r := s.responses(0, "attack")
			note = "offered%s" % r.has(m)
			if r.has(m):
				s.respond(0, m)
			s.resolve_attack()
		14:  # tributed for a bigger monster
			s.players[0].field[0] = m
			m.summoned_turn = 1
			var boss := s._make(_id("Summoned Skull"), 0)
			me.hand.append(boss)
			_put(s, 1, _id("Celtic Guardian"), 0)
			if s.tributable(0).has(m):
				s.normal_summon(0, boss, [m], false)
		15:  # just standing on the field next to other monsters
			s.players[0].field[0] = m
			_put(s, 0, _id("Harpie Lady"), 1)
			_put(s, 0, _id("Feral Imp"), 2)
			_put(s, 0, _id("Baby Dragon"), 3)
			_put(s, 1, _id("Aqua Madoor"), 0)
			_put(s, 1, _id("Mechanicalchaser"), 1)
			_put(s, 1, _id("Charcoal Inpachi"), 2, false)
			var sp := s._make(_id("Mirror Force"), 0)
			sp.face_up = false
			me.spells[0] = sp
			_put(s, 0, _id("Mechanicalchaser"), 4)
			note = "t%d s%d" % [s.tributes_needed(s._make(_id("Blue-Eyes White Dragon"), 0)), opp.field.count(null)]
			for x in ["Cyber Dragon", "Harpie Lady", "Elemental HERO Neos", "Dark Magician"]:
				note += str(CardEffects.matches(m.data, {"name": x}))
			note += str(SpellRules.blocked(s, sp))
			s._destroy(me.field[2])
			s._cleanup()
		16:  # their turn passes with it on the field
			s.players[0].field[0] = m
			m.attack_pos = false
			_put(s, 1, _id("Celtic Guardian"), 0)
			s.current = 1
			s.turn = 4
			s.begin_turn()
			if not s.is_over():
				s.end_turn()
		17:  # discarded from the hand
			me.hand.append(m)
			_put(s, 1, _id("Celtic Guardian"), 0)
			me.hand.erase(m)
			s._to_gy(me, m)
			if s.has_method("_on_discard"):
				s.call("_on_discard", m)
			s._cleanup()
		18:  # sent from the Deck to the Graveyard
			me.deck.append(m)
			me.deck.erase(m)
			s._to_gy(me, m)
			s._cleanup()
		19:  # Synchro / Xyz material, or a Tuner on the field
			s.players[0].field[0] = m
			m.summoned_turn = 1
			_put(s, 0, _id("Celtic Guardian"), 1)
			_put(s, 0, _id("Silver Fang"), 2)
			var fs2 := s._make(_id("Banner of Courage"), 1)
			opp.spells[1] = fs2
			var ss2 := s._make(_id("Mirror Force"), 1)
			ss2.face_up = false
			opp.spells[0] = ss2
			for x in ["Junk Warrior", "Stardust Dragon", "Number 39: Utopia", "Number 17: Leviathan Dragon", "Gaia Knight, the Force of Earth"]:
				if _id(x) != 0:
					me.extra.append(s._make(_id(x), 0))
			for x in me.extra.duplicate():
				if s.can_extra_summon(0, x):
					s.extra_summon(0, x)
					break
		20:  # banished
			s.players[0].field[0] = m
			s._banish(m)
			s._cleanup()
		21, 22:  # Special Summoned / Synchro Summoned
			_put(s, 0, _find({"max_lv": 2}, nm), 3)
			_put(s, 0, _id("Baby Dragon"), 4)
			_put(s, 1, _id("Celtic Guardian"), 0)
			var fs3 := s._make(_id("Banner of Courage"), 1)
			opp.spells[1] = fs3
			if empty_hand:
				me.hand.clear()
			s._special(0, m, "special", "atk")
			EffectRunner.on_summon(s, 0, m, "special" if k == 21 else "synchro")
			s._cleanup()
		23:  # attacks after you played a Spell this turn
			s.players[0].field[0] = m
			m.summoned_turn = 1
			_dummy(s, 1, 0, 0, 0)
			var heal := s._make(_id("Dian Keto the Cure Master"), 0)
			me.hand.append(heal)
			s.activate(0, heal)
			if not s.chain.is_empty():
				s.chain_resolve()
			s.enter_battle()
			if s.can_attack(0, m):
				s.attack(0, m, opp.field[0])
		24:  # a weaker monster attacks it
			s.players[0].field[0] = m
			m.summoned_turn = 1
			m.attack_pos = false
			var weak := _dummy(s, 1, 0, 100, 100)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			if s.attack_targets(1).has(m):
				s.attack(1, weak, m)
		25:  # attacks a weak Plant
			s.players[0].field[0] = m
			m.summoned_turn = 1
			_dummy(s, 1, 0, 0, 0, true, {"race": "Plant"})
			s.phase = DuelState.Phase.BATTLE
			if s.can_attack(0, m):
				s.attack(0, m, opp.field[0])
		26:  # in your Graveyard while your monster is attacked
			me.gy.append(m)
			var mine := _put(s, 0, _id("Celtic Guardian"), 0)
			var big3 := _put(s, 1, _id("Blue-Eyes White Dragon"), 0)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			s.declare_attack(1, big3, mine)
			for w in ["attack", "damage"]:
				var r2 := s.responses(0, w, big3)
				if r2.has(m):
					note += "offered"
					s.respond(0, m, big3)
			s.resolve_attack()
		27:  # attacks a wall too big for it
			s.players[0].field[0] = m
			m.summoned_turn = 1
			_dummy(s, 1, 0, 0, 5000, false)
			_dummy(s, 1, 1, 0, 5000, false)
			s.phase = DuelState.Phase.BATTLE
			if s.can_attack(0, m):
				s.attack(0, m, opp.field[0])
		28:  # attacks into Mirror Force
			s.players[0].field[0] = m
			m.summoned_turn = 1
			_dummy(s, 1, 0, 0, 0)
			var mf := s._make(_id("Mirror Force"), 1)
			mf.face_up = false
			mf.set_turn = 1
			opp.spells[0] = mf
			s.phase = DuelState.Phase.BATTLE
			if empty_hand:
				me.hand.clear()
			if s.can_attack(0, m):
				s.declare_attack(0, m, opp.field[0])
				if s.responses(1, "attack", m).has(mf):
					s.respond(1, mf, m)
				s.resolve_attack()
		29:  # Normal Summoned with nothing else in hand or on the field
			me.hand = [m]
			_put(s, 1, _id("Celtic Guardian"), 0)
			if s.tributes_needed(m) == 0:
				s.normal_summon(0, m, [], false)
		30:  # destroys a monster that has an effect of its own
			s.players[0].field[0] = m
			m.summoned_turn = 1
			var tom := _put(s, 1, _id("Mystic Tomato"), 0)
			s.phase = DuelState.Phase.BATTLE
			if s.can_attack(0, m) and s.atk_of(m, true) > 1400:
				s.attack(0, m, tom)
		31:  # another monster of yours is destroyed by battle
			s.players[0].field[0] = m
			var fam := 0
			for f in [{"has": "roid"}, {"has": "Destiny HERO"}, {"has": "Blackwing"}]:
				if fam == 0 and nm.contains(str(f["has"])):
					fam = _find(f, nm)
			var mate := _put(s, 0, fam if fam != 0 else _id("Celtic Guardian"), 1)
			var big4 := _put(s, 1, _id("Blue-Eyes White Dragon"), 0)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			s.attack(1, big4, mate)
		32:  # in your hand while your monster battles
			me.hand.append(m)
			var fam2 := 0
			for f in [{"has": "Blackwing"}, {"has": "Destiny HERO"}]:
				if fam2 == 0 and nm.contains(str(f["has"])):
					fam2 = _find(f, nm)
			var mate2 := _put(s, 0, fam2 if fam2 != 0 else _id("Celtic Guardian"), 1)
			var foe := _put(s, 1, _id("Battle Ox"), 0)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			s.declare_attack(1, foe, mate2)
			if s.responses(0, "damage", foe).has(m):
				note = "offered"
				s.respond(0, m, foe)
			s.resolve_attack()
		33:  # in the Graveyard: a big Plant of yours is destroyed, then a Plant Tuner is Normal Summoned
			me.gy.append(m)
			var plant5 := 0
			var plant_tuner := 0
			for id2 in col.every_playable():
				var d2 := CardData.get_card(id2)
				if str(d2.get("race", "")) == "Plant" and str(d2.get("name", "")) != nm and not CardData.is_extra(id2):
					if int(d2.get("level", 0)) >= 5 and plant5 == 0:
						plant5 = id2
					if d2.get("tuner", false) and plant_tuner == 0:
						plant_tuner = id2
			if plant5 != 0:
				var bigp := _put(s, 0, plant5, 1)
				s._destroy(bigp)
				s._cleanup()
			if plant_tuner != 0 and me.gy.has(m):
				var pt := s._make(plant_tuner, 0)
				me.hand.append(pt)
				s.normal_summon(0, pt, [], false)
		34:  # in the Graveyard, no cards in hand, and a monster of yours falls in battle
			me.gy.append(m)
			me.hand.clear()
			var mate3 := _put(s, 0, _id("Summoned Skull"), 1)
			var big5 := _put(s, 1, _id("Blue-Eyes White Dragon"), 0)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			s.attack(1, big5, mate3)
		35:  # on the field when a family member falls, then your next turn begins
			s.players[0].field[0] = m
			m.summoned_turn = 1
			m.attack_pos = false
			var fam3 := _find({"has": "Destiny HERO"}, nm) if nm.contains("Destiny HERO") else _id("Celtic Guardian")
			var mate4 := _put(s, 0, fam3, 1)
			var big6 := _put(s, 1, _id("Blue-Eyes White Dragon"), 0)
			s.current = 1
			s.turn = 4
			s.phase = DuelState.Phase.BATTLE
			s.attack(1, big6, mate4)
			s.end_turn()
			if not s.is_over():
				s.begin_turn()
	if s.phase == DuelState.Phase.BATTLE and s.current == 0 and not s.is_over() and k in [2, 3, 4, 23, 25, 27, 30]:
		s.enter_main2()   # the Battle Phase ends: effects that wait for that
	if empty_hand and k in [2, 3, 4, 9, 10, 11, 14, 15, 16]:
		# The same again with an empty hand, for the cards that only wake up then.
		return _scene_empty(id, k, twin, entry, nm)
	return note + "#" + _sig(s, m) + "#" + ("" if not m.face_up else str(s.atk_of(m, true)))


## A few situations replayed with no cards in hand (Infernity and friends).
func _scene_empty(id: int, k: int, twin: bool, entry, nm: String) -> String:
	var s := _arena()
	_seed(s, entry, nm)
	var me := s.players[0]
	var opp := s.players[1]
	var m := _inst(s, id, twin)
	me.hand.clear()
	me.field[0] = m
	m.summoned_turn = 1
	var note := ""
	match k:
		2, 3, 4:
			if k == 2:
				_dummy(s, 1, 0, 0, 0)
			elif k == 3:
				_dummy(s, 1, 0, 0, 0, false)
			_put(s, 0, _id("Celtic Guardian"), 1)
			s.phase = DuelState.Phase.BATTLE
			if s.can_attack(0, m):
				s.attack(0, m, opp.field[0])
			var other: DuelState.CardInst = me.field[1]
			if k == 3 and other != null and s.can_attack(0, other) and opp.field[0] != null:
				s.attack(0, other, opp.field[0])
		11:
			_put(s, 1, _id("Celtic Guardian"), 0)
			note = "can%s" % s.can_ignite(0, m)
			if s.can_ignite(0, m):
				s.ignite(0, m)
		_:
			_put(s, 1, _id("Blue-Eyes White Dragon"), 0)
			s.current = 1
			s.phase = DuelState.Phase.BATTLE
			s.attack(1, opp.field[0], m)
	return note + "#" + _sig(s, m) + "#" + ("" if not m.face_up else str(s.atk_of(m, true)))


# ------------------------------------------------------------------ part 3

func _field(s: DuelState) -> void:
	_put(s, 0, _id("Celtic Guardian"), 0)
	_put(s, 0, _id("Dark Magician"), 1)
	_put(s, 0, _id("Baby Dragon"), 2)
	_put(s, 1, _id("Battle Ox"), 0)
	_put(s, 1, _id("Mystical Elf"), 1, false)
	_put(s, 1, _id("Feral Imp"), 2, false, false)
	for p in 2:
		var sp := s._make(_id("Mirror Force"), p)
		sp.face_up = false
		sp.set_turn = 1
		s.players[p].spells[4] = sp
		s.players[p].lp = 6000


## Flags a card's rules may set that the field picture does not show.
func _flags(s: DuelState) -> String:
	var out := ""
	# Would a Trap or a Spell be locked out right now? (Royal Decree, Imperial Order)
	var probe_t := s._make(_id("Mirror Force"), 1)
	var probe_s := s._make(_id("Fissure"), 1)
	out += "blk%s%s;" % [SpellRules.blocked(s, probe_t), SpellRules.blocked(s, probe_s)]
	for prop in s.get_property_list():
		var n := str(prop["name"])
		if n in ["players", "chain", "pending_fx", "answers", "need", "_rng", "script", "manual", "redirected", "last_summoned", "pending_attack", "_uid", "bonus_cards"] or (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		out += "%s=%s;" % [n, str(s.get(n)).substr(0, 60)]
	for p in 2:
		for prop in s.players[p].get_property_list():
			var n := str(prop["name"])
			if n in ["hand", "deck", "gy", "banished", "extra", "field", "spells", "field_spell", "name", "script"] or (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
				continue
			out += "%d.%s=%s;" % [p, n, str(s.players[p].get(n)).substr(0, 60)]
		for c in s.players[p].monsters():
			out += "%d:%d:%d:%d:%d:%s;" % [c.atk_mod, c.atk_mod_t, c.half_turn, c.zero_turn, c.control_until, c.negated]
	return out


func _full(s: DuelState, skip = null) -> String:
	var hands := ""
	for p in 2:
		var names: Array = []
		for c in s.players[p].hand:
			if c != skip:
				names.append(c.cname())
		names.sort()
		hands += ",".join(PackedStringArray(names)) + "/"
		var g: Array = []
		for c in s.players[p].gy:
			if c != skip:
				g.append(c.cname())
		g.sort()
		hands += ",".join(PackedStringArray(g)) + "/"
	return _sig(s, null, skip) + "#" + hands + "#" + _flags(s)


func _spell(id: int) -> String:
	var d := CardData.get_card(id)
	var nm := str(d.get("name", ""))
	var entry = SpellRules.FX.get(nm, {})
	var is_trap := str(d.get("kind", "")) == "trap"
	# Several fields: some cards need a particular one (an empty field, a full Graveyard, low Life Points).
	for variant in 6:
		var s := _arena()
		_seed(s, entry, nm)
		if variant != 1:
			_field(s)
			# A monster of the kind the card asks for (Equip Spells for one Type, and so on).
			var fl: Array = []
			_filters(entry, fl)
			var z := 3
			for f in fl:
				var fid := _find(f, nm)
				if fid != 0 and z < 5:
					_put(s, 0, fid, z)
					z += 1
		if variant == 2:
			s.players[0].lp = 1000
		if variant == 3:
			s.players[1].lp = 1000
			for i in 4:
				s.players[1].hand.pop_back()
			# A face-up Trap, a Fusion Monster and a full Graveyard, for the cards that need them.
			for id2 in col.every_playable():
				var tc0 := s._make(id2, 1)
				if SpellRules.kind(tc0) == "ctrap" and not SpellRules.spec(tc0).has("block"):
					s.players[1].spells[1] = tc0
					break
			if _id("Blue-Eyes Ultimate Dragon") != 0:
				s.players[0].field[3] = s._make(_id("Blue-Eyes Ultimate Dragon"), 0)
			for x in ["Celtic Guardian", "Battle Ox", "Gemini Elf", "Silver Fang"]:
				s.players[0].gy.append(s._make(_id(x), 0))
		if variant == 4:
			# Fusion pieces in hand and Extra Deck for Polymerization and friends.
			for x in ["Elemental HERO Avian", "Elemental HERO Burstinatrix", "Dark Magician", "Buster Blader", "Blue-Eyes White Dragon", "Blue-Eyes White Dragon", "Blue-Eyes White Dragon", "Relinquished"]:
				if _id(x) != 0:
					s.players[0].hand.append(s._make(_id(x), 0))
			for x in ["Elemental HERO Flame Wingman", "Dark Paladin", "Blue-Eyes Ultimate Dragon", "Black Luster Soldier"]:
				if _id(x) != 0:
					s.players[0].extra.append(s._make(_id(x), 0))
			for x in ["Black Luster Soldier", "Relinquished"]:
				if _id(x) != 0:
					s.players[0].hand.append(s._make(_id(x), 0))
			for x in ["Elemental HERO Avian", "Elemental HERO Burstinatrix", "Blue-Eyes White Dragon", "Blue-Eyes White Dragon", "Blue-Eyes White Dragon"]:
				if _id(x) != 0:
					s.players[0].gy.append(s._make(_id(x), 0))
		if variant == 5:
			s.players[0].field = [null, null, null, null, null]
		var c := s._make(id, 0)
		var res := _spell_try(s, c, is_trap)
		if res != "":
			return "ok (%s, field %d)" % [res, variant]
	return "nothing happened on any of the six standard fields"


func _spell_try(s: DuelState, c: DuelState.CardInst, is_trap: bool) -> String:
	var me := s.players[0]
	var kind := SpellRules.kind(c)
	if not is_trap:
		# From the hand, in your Main Phase.
		var t := s.clone()
		var tc := t._make(c.id, 0)
		t.players[0].hand.append(tc)
		var before := _full(t, tc)
		if t.can_activate(0, tc):
			var choice = null
			if tc.data.get("effect", "") == "fusion":
				var opts := t.fusion_targets(0, tc)
				if not opts.is_empty():
					choice = opts[0]["card"]
			t.activate(0, tc, choice)
			if not t.chain.is_empty():
				t.chain_resolve()
			# A card that stays on the field has to show what it does there.
			if kind in ["cont", "field"]:
				t.current = 0
				t.begin_turn()
				if not t.is_over() and t.can_enter_battle():
					t.enter_battle()
			var after := _full(t, tc)
			var placed := "%s%s" % [tc.cname(), "u"]
			if after.replace(placed, "-") != before and after != before:
				return "activated"
		if not is_trap and kind != "quick":
			return ""
	# Set last turn, then used as an answer.
	for win: String in ["attack", "summon", "chain", "battle_start", "phase", "end", "standby", "direct", "chain_trap", "chain_fx", "my_direct"]:
		var out: Array = []
		for with_card: bool in [true, false]:
			var t := s.clone()
			var tc: DuelState.CardInst = null
			if with_card:
				tc = t._make(c.id, 0)
				tc.face_up = false
				tc.set_turn = 1
				t.players[0].spells[0] = tc
			var subject = null
			var offered := false
			match win:
				"attack", "direct":
					if win == "direct":
						t.players[0].field = [null, null, null, null, null]
					t.current = 1
					t.phase = DuelState.Phase.BATTLE
					var a: DuelState.CardInst = t.players[1].field[0]
					if a == null:
						a = _put(t, 1, _id("Battle Ox"), 0)
					var target = t.players[0].field[0] if win == "attack" else null
					t.declare_attack(1, a, target)
					subject = a
				"summon":
					t.current = 1
					t.phase = DuelState.Phase.MAIN1
					var nmon := t._make(_id("Vorse Raider"), 1)
					t.players[1].hand.append(nmon)
					t.normal_summon(1, nmon, [], false)
					subject = t.last_summoned
				"chain":
					t.current = 1
					t.phase = DuelState.Phase.MAIN1
					var osp := t._make(_id("Fissure"), 1)
					t.players[1].hand.append(osp)
					t.chain_add(1, osp, null, "open", null)
					subject = t.chain.back() if not t.chain.is_empty() else null
				"chain_trap":
					# You attack, they flip a Trap: a card that stops Traps answers that.
					t.current = 0
					t.phase = DuelState.Phase.BATTLE
					var mine: DuelState.CardInst = t.players[0].field[1]
					var their: DuelState.CardInst = t.players[1].spells[4]
					if mine != null and their != null:
						t.declare_attack(0, mine, t.players[1].field[0])
						t.chain_add(1, their, null, "attack", mine)
						subject = t.chain.back() if not t.chain.is_empty() else null
				"chain_fx":
					# They use a monster's effect: a card that stops effects answers that.
					t.current = 1
					t.phase = DuelState.Phase.MAIN1
					t.defer_fx = true
					var ef := _put(t, 1, _id("Exiled Force"), 3)
					if t.can_ignite(1, ef):
						t.ignite(1, ef)
						t.fx_to_chain()
					subject = t.chain.back() if not t.chain.is_empty() else null
				"my_direct":
					t.current = 0
					t.phase = DuelState.Phase.BATTLE
					t.players[1].field = [null, null, null, null, null]
					var mine2: DuelState.CardInst = t.players[0].field[1]
					if mine2 != null:
						t.declare_attack(0, mine2, null)
						subject = mine2
				"battle_start":
					t.current = 1
					t.phase = DuelState.Phase.BATTLE
				"phase":
					t.current = 0
					t.phase = DuelState.Phase.MAIN1
				"end":
					t.current = 1
					t.phase = DuelState.Phase.END
				"standby":
					t.current = 1
					t.phase = DuelState.Phase.STANDBY
			if with_card:
				var w: String = "attack" if win in ["direct", "my_direct"] else ("phase" if win in ["end", "standby"] else ("chain" if win.begins_with("chain") else win))
				var opts := t.responses(0, w, subject)
				offered = opts.has(tc)
				if offered:
					var target = null
					var sp := SpellRules.spec(tc)
					if not sp.has("legacy") and SpellRules._needs_target(sp):
						target = SpellRules.auto_target(t, 0, tc)
					var ev := t.chain_add(0, tc, target, w, subject)
					if ev.is_empty():
						t.respond(0, tc, subject)
			if not t.chain.is_empty():
				t.chain_resolve()
			if not t.pending_attack.is_empty():
				t.resolve_attack()
			if win in ["battle_start", "phase", "end", "standby", "summon", "chain"] and not t.is_over():
				# Let the turn run on, for cards that change what can happen next.
				if t.current == 1 and t.phase == DuelState.Phase.MAIN1 and t.can_enter_battle():
					t.enter_battle()
				if t.phase == DuelState.Phase.BATTLE:
					var a2: DuelState.CardInst = null
					for m in t.players[t.current].monsters():
						if t.can_attack(t.current, m):
							a2 = m
							break
					if a2 != null:
						var tg: Array = t.attack_targets(t.current)
						t.attack(t.current, a2, tg[0] if not tg.is_empty() else null)
			out.append(_full(t, tc).replace("%sd" % c.cname(), "-").replace("%su" % c.cname(), "-") + ("|offered" if offered else ""))
		if out[0].ends_with("|offered"):
			var with := str(out[0]).trim_suffix("|offered")
			# Compare without the trap's own place in the Graveyard.
			if _strip(with, c.cname()) != _strip(str(out[1]), c.cname()):
				return "answered in the %s window" % win
	return ""


func _strip(sig: String, name: String) -> String:
	return sig.replace(name + ",", "").replace("," + name, "").replace(name, "")
