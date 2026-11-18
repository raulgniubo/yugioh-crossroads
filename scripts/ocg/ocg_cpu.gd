class_name OcgCpu
extends RefCounted
## The placeholder opponent for the new engine: legal, basic moves and nothing clever.
## It summons its biggest monster, plays its cards, attacks what it can beat, and answers
## every question the engine asks. The real opponent replaces it in the next build.


var memo := {}       # per turn: what it already tried, so it never loops
var rng := RandomNumberGenerator.new()


func _turn_memo(d: OcgDuel) -> Dictionary:
	if int(memo.get("turn", -1)) != d.st.turn or int(memo.get("who", -1)) != d.st.current:
		memo = {"turn": d.st.turn, "who": d.st.current, "acts": 0, "done": {}, "skip": {}, "chains": {}, "target": null, "sets": 0}
	return memo


func _atk(d: OcgDuel, c) -> int:
	return d.st.atk_of(c, true) if c != null else 0


func _def(d: OcgDuel, c) -> int:
	return d.st.def_of(c) if c != null else 0


## The answer to the question the duel is waiting on. `safe`: the plainest legal answer
## (used after the engine refused one).
func decide(d: OcgDuel, safe := false) -> PackedByteArray:
	var m: Dictionary = d.request
	var mm := _turn_memo(d)
	match int(m["t"]):
		11: return _idle(d, m, mm, safe)
		10: return _battle(d, m, mm, safe)
		12, 13: return OcgDuel.i32(0 if safe else 1)
		14: return OcgDuel.i32(0)
		15: return _cards(d, m, mm, safe)
		16: return _chain(d, m, mm, safe)
		18, 24: return _place(d, m)
		19: return _position(d, m)
		20: return _tribute(d, m)
		21, 25:
			var b := PackedByteArray()
			b.append(255)
			return b
		22: return _counters(m)
		23: return _sum(m)
		26: return _unselect(m, mm, safe)
		132: return OcgDuel.i32(1 + rng.randi() % 3)
		140, 141: return _bits(m)
		142: return _announce(d, m, mm)
		143: return OcgDuel.i32(0)
	return OcgDuel.i32(0)


func _idle(d: OcgDuel, m: Dictionary, mm: Dictionary, safe: bool) -> PackedByteArray:
	if safe:
		return OcgDuel.i32(7 if int(m["to_ep"]) else 6)
	var acts := int(mm["acts"])
	mm["acts"] = acts + 1
	if acts < 25:
		var sp: Array = m["spsummon"]
		var sp_cards := d.cards_of(sp)
		var best := -1
		for i in sp.size():
			var key := "sp%d" % int(sp[i]["code"])
			if int((mm["done"] as Dictionary).get(key, 0)) >= 2:
				continue
			if best == -1 or _base_atk(sp_cards[i]) > _base_atk(sp_cards[best]):
				best = i
		if best != -1:
			var k := "sp%d" % int(sp[best]["code"])
			mm["done"][k] = int(mm["done"].get(k, 0)) + 1
			return OcgDuel.i32((best << 16) | 1)
		var ns: Array = m["summon"]
		var ns_cards := d.cards_of(ns)
		best = -1
		for i in ns.size():
			if best == -1 or _base_atk(ns_cards[i]) > _base_atk(ns_cards[best]):
				best = i
		if best != -1 and not mm["done"].has("ns"):
			mm["done"]["ns"] = 1
			var c = ns_cards[best]
			var ms: Array = m["mset"]
			# A weak monster with a better back goes face-down.
			if c != null and c.atk() < 1000 and c.def() > c.atk():
				for j in ms.size():
					if int(ms[j]["code"]) == int(ns[best]["code"]):
						return OcgDuel.i32((j << 16) | 3)
			return OcgDuel.i32((best << 16) | 0)
		var ch: Array = m["chains"]
		for i in ch.size():
			var key := "ac%d_%d" % [int(ch[i]["code"]), int(ch[i]["desc"])]
			if mm["done"].has(key):
				continue
			mm["done"][key] = 1
			return OcgDuel.i32((i << 16) | 5)
		var mset: Array = m["mset"]
		if ns.is_empty() and not mset.is_empty() and not mm["done"].has("ns"):
			mm["done"]["ns"] = 1
			return OcgDuel.i32((0 << 16) | 3)
		var ss: Array = m["sset"]
		if not ss.is_empty() and int(mm["sets"]) < 5:
			var ss_cards := d.cards_of(ss)
			for i in ss.size():
				var sc = ss_cards[i]
				var key := "ss%d" % (sc.uid if sc != null else i)
				if mm["done"].has(key):
					continue
				# Traps and Quick-Play Spells go face-down; other Spells stay in the hand for next turn.
				if sc != null and (sc.is_trap() or str(sc.data.get("race", "")) == "Quick-Play"):
					mm["done"][key] = 1
					mm["sets"] = int(mm["sets"]) + 1
					return OcgDuel.i32((i << 16) | 4)
	if int(m["to_bp"]) and not mm["done"].has("bp"):
		mm["done"]["bp"] = 1
		for c in d.st.players[int(m["p"])].monsters():
			if c.face_up and c.attack_pos:
				return OcgDuel.i32(6)
	return OcgDuel.i32(7 if int(m["to_ep"]) else 6)


func _base_atk(c) -> int:
	return c.atk() if c != null else 0


func _battle(d: OcgDuel, m: Dictionary, mm: Dictionary, safe: bool) -> PackedByteArray:
	var leave := OcgDuel.i32(2 if int(m["to_m2"]) else 3)
	var at: Array = m["attacks"]
	if int(m["to_m2"]) == 0 and int(m["to_ep"]) == 0:
		# It may not leave the Battle Phase yet (a monster that must attack): do what is open.
		if not at.is_empty():
			return OcgDuel.i32(1)
		if not (m["chains"] as Array).is_empty():
			return OcgDuel.i32(0)
	if safe:
		return leave
	var p := int(m["p"])
	var foes: Array = d.st.players[1 - p].monsters()
	for i in at.size():
		var a = d.card_at(int(at[i]["con"]), int(at[i]["loc"]), int(at[i]["seq"]))
		if a == null or mm["skip"].has(a.uid):
			continue
		var power := _atk(d, a)
		if foes.is_empty() or int(at[i]["direct"]) != 0:
			mm["target"] = null
			mm["skip"][a.uid] = int(mm["skip"].get(a.uid, 0)) + 1
			return OcgDuel.i32((i << 16) | 1)
		var pick = null
		for f in foes:
			var beat := false
			if not f.face_up:
				beat = power >= 1500
			elif f.attack_pos:
				beat = power > _atk(d, f)
			else:
				beat = power > _def(d, f)
			if beat and (pick == null or _atk(d, f) > _atk(d, pick)):
				pick = f
		mm["skip"][a.uid] = 1
		if pick != null:
			mm["target"] = pick
			return OcgDuel.i32((i << 16) | 1)
	return leave


func _score(d: OcgDuel, c) -> int:
	if c == null:
		return 0
	if c.is_monster():
		return maxi(c.atk(), int(c.tags.get("ocg_atk", 0))) + 1
	return 800


func _cards(d: OcgDuel, m: Dictionary, mm: Dictionary, safe: bool) -> PackedByteArray:
	var p := int(m["p"])
	var list: Array = m["cards"]
	var lo := int(m["min"])
	var hi := int(m["max"])
	var n := maxi(lo, 1) if hi >= 1 else 0
	if safe:
		var first: Array = []
		for i in mini(maxi(lo, 1), list.size()):
			first.append(i)
		return OcgDuel.pick(first)
	var cards := d.cards_of(list)
	var target = mm.get("target")
	if target != null:
		mm["target"] = null
		var ti := cards.find(target)
		if ti != -1:
			return OcgDuel.pick([ti])
	var hint := int(d.hints.get(p, 0))
	# Mine and paid as a cost: the weakest. Theirs, or something I get: the strongest.
	var give := hint in [500, 501, 502, 503, 504, 505, 507, 511, 512, 513]
	var order: Array = []
	for i in list.size():
		order.append(i)
	order.sort_custom(func(a, b):
		var ca = cards[a]
		var cb = cards[b]
		var mine_a: bool = int(list[a]["con"]) == p
		var mine_b: bool = int(list[b]["con"]) == p
		if mine_a != mine_b:
			return mine_b if not give else mine_b   # theirs first, either way
		var sa := _score(d, ca)
		var sb := _score(d, cb)
		if mine_a and give:
			return sa < sb
		return sa > sb)
	return OcgDuel.pick(order.slice(0, mini(n, order.size())))


func _chain(d: OcgDuel, m: Dictionary, mm: Dictionary, safe: bool) -> PackedByteArray:
	var ch: Array = m["chains"]
	if ch.is_empty():
		return OcgDuel.i32(-1)
	if int(m["forced"]):
		return OcgDuel.i32(0)
	if safe:
		return OcgDuel.i32(-1)
	for i in ch.size():
		var key := "%d_%d" % [int(ch[i]["code"]), int(ch[i]["desc"])]
		var used := int(mm["chains"].get(key, 0))
		if used >= 2:
			continue
		mm["chains"][key] = used + 1
		return OcgDuel.i32(i)
	return OcgDuel.i32(-1)


func _place(d: OcgDuel, m: Dictionary) -> PackedByteArray:
	var opts := d.place_options(m)
	var p := int(m["p"])
	var want := maxi(1, int(m["count"]))
	var pref := [2, 1, 3, 0, 4, 5, 6, 7]
	opts.sort_custom(func(a, b):
		if (int(a[0]) == p) != (int(b[0]) == p):
			return int(a[0]) == p
		if int(a[1]) != int(b[1]):
			return int(a[1]) < int(b[1])
		return pref.find(int(a[2])) < pref.find(int(b[2])))
	return d.place(opts.slice(0, want))


func _position(d: OcgDuel, m: Dictionary) -> PackedByteArray:
	var ok := int(m["positions"])
	var data: Dictionary = CardData.get_card(int(m["code"]))
	var atk := int(data.get("atk", 0))
	var def := int(data.get("def", 0))
	if (ok & 1) and (atk >= def or atk >= 1500 or not (ok & 4)):
		return OcgDuel.i32(1)
	for bit in [4, 8, 1, 2]:
		if ok & bit:
			return OcgDuel.i32(bit)
	return OcgDuel.i32(1)


func _tribute(d: OcgDuel, m: Dictionary) -> PackedByteArray:
	var list: Array = m["cards"]
	var cards := d.cards_of(list)
	var order: Array = []
	for i in list.size():
		order.append(i)
	order.sort_custom(func(a, b): return _score(d, cards[a]) < _score(d, cards[b]))
	var need := int(m["min"])
	var got := 0
	var picks: Array = []
	for i in order:
		if got >= need or picks.size() >= int(m["max"]):
			break
		picks.append(i)
		got += maxi(1, int(list[i].get("param", 1)))
	return OcgDuel.pick(picks)


func _counters(m: Dictionary) -> PackedByteArray:
	var left := int(m["count"])
	var b := PackedByteArray()
	for c in m["cards"]:
		var take := mini(left, int(c["n"]))
		left -= take
		b.append(take & 0xff)
		b.append((take >> 8) & 0xff)
	return b


## A set of cards whose Levels (or other numbers) add up the way the question wants.
func _sum(m: Dictionary) -> PackedByteArray:
	var acc := int(m["acc"])
	var must: Array = m["must"]
	var list: Array = m["cards"]
	var exact := int(m["mode"]) == 0
	var lo := int(m["min"])
	var hi := int(m["max"])
	var n := mini(list.size(), 14)
	for mask in range(1, 1 << n):
		var picks: Array = []
		var params: Array = []
		for c in must:
			params.append(int(c["param"]))
		for i in n:
			if mask & (1 << i):
				picks.append(i)
				params.append(int(list[i]["param"]))
		if exact:
			if picks.size() < lo or picks.size() > hi:
				continue
			if _sum_exact(params, 0, acc):
				return OcgDuel.pick(picks)
		else:
			var total := 0
			var most := 0
			var least := 0x7fffffff
			for pv in params:
				var o1: int = pv & 0xffff
				var o2: int = pv >> 16
				var small: int = o2 if (o2 > 0 and o2 < o1) else o1
				total += small
				most += maxi(o1, o2)
				least = mini(least, small)
			if most >= acc and total - least < acc:
				return OcgDuel.pick(picks)
	var all: Array = []
	for i in mini(maxi(lo, 1), list.size()):
		all.append(i)
	return OcgDuel.pick(all)


func _sum_exact(params: Array, i: int, acc: int) -> bool:
	if i == params.size():
		return acc == 0
	if acc <= 0:
		return false
	var o1: int = int(params[i]) & 0xffff
	var o2: int = int(params[i]) >> 16
	if _sum_exact(params, i + 1, acc - o1):
		return true
	return o2 > 0 and _sum_exact(params, i + 1, acc - o2)


func _unselect(m: Dictionary, mm: Dictionary, safe: bool) -> PackedByteArray:
	var list: Array = m["cards"]
	if int(m["finish"]) != 0:
		return OcgDuel.i32(-1)
	if list.is_empty() or safe:
		if int(m["cancel"]) != 0:
			return OcgDuel.i32(-1)
		return OcgDuel.pick_one(0)
	return OcgDuel.pick_one(0)


func _bits(m: Dictionary) -> PackedByteArray:
	var avail := int(m["avail"])
	var want := int(m["count"])
	var out := 0
	var bit := 1
	while want > 0 and bit != 0 and bit <= avail:
		if avail & bit:
			out |= bit
			want -= 1
		bit <<= 1
	var b := PackedByteArray()
	if int(m["t"]) == 140:
		b.resize(8)
		b.encode_u64(0, out)
	else:
		b.resize(4)
		b.encode_u32(0, out)
	return b


func _announce(d: OcgDuel, m: Dictionary, mm: Dictionary) -> PackedByteArray:
	# Name a card: one of theirs it has seen, else one of its own.
	var p := int(m["p"])
	var pool: Array = []
	for c in d.st.players[1 - p].gy + d.st.players[1 - p].monsters() + d.st.players[p].deck + d.st.players[p].hand:
		if c != null and c.id > 0 and not pool.has(c.id):
			pool.append(c.id)
	# (only names the engine will take: the question carries its own test)
	pool = pool.filter(func(id): return OcgCore.announce_ok(m.get("opts", []), int(id)))
	for staple in [55144522, 83764718, 44095762, 5318639]:
		if pool.size() < 2 and OcgCore.announce_ok(m.get("opts", []), staple):
			pool.append(staple)
	var k := int(mm.get("announce", 0))
	mm["announce"] = k + 1
	return OcgDuel.i32(int(pool[k % pool.size()]) if not pool.is_empty() else 55144522)
