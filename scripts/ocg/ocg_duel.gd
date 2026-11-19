class_name OcgDuel
extends RefCounted
## One duel run by the rules engine. It feeds the engine, keeps the mirror state (what the
## duel screen looks at) in step with it, turns what the engine reports into the same events
## the duel screen already animates, and holds the question the engine is waiting on.


const R_DESTROY := 0x1
const R_RELEASE := 0x2
const R_SUMMON := 0x10
const R_MATERIAL := 0x8
const R_BATTLE := 0x20
const R_EFFECT := 0x40
const R_COST := 0x80
const R_RULE := 0x400
const R_DISCARD := 0x4000

var st: DuelState
var handle := 0
var swap := false           # the engine's player 0 is our player 1 (they go first)
var request = null          # the question waiting for an answer (a message), or null
var over := false
var errors: Array = []
var hints := {}             # player -> the last "select..." line the engine gave
var check := true           # compare the mirror with the engine after every batch
var retries := 0
var steps := 0
var log_msgs := false
var chain_cards: Array = []  # what is on the chain right now, in order
var _chain_n := 0            # how long the chain being built or resolved is
var _pending = null         # a card that just reached the field, waiting for its Summon / Set / activation message
var _flip = null            # a Set Spell/Trap that just turned face-up, waiting for its activation message
var _last_request = null
var _attacker = null
var _dirty := false
var _limbo: Array = []
var _phase_raw := 0


## Build the two sides (the mirror's cards, nothing drawn yet). `first`: who goes first (0 or 1).
var _cards: Array = []
var _seed := 0

## setup (optional): cards already in place when the duel starts, each a list per player:
##   "hand": [[ids], [ids]]   "mons": [[[id, "atk" | "def" | "set"], ...], ...]   "st": [[id (Set) | [id, "up"], ...], ...]
##   "gy": [[ids], [ids]]     "turbo": true (each side's Speed World 2)
var turbo := false
var speed := [0, 0]

func prepare(state: DuelState, decks: Array, extras: Array, names: Array, first: int, seed := -1, setup := {}) -> void:
	st = state
	swap = first == 1
	EffectRunner.current_state = st
	st.players = [DuelState.PlayerState.new(), DuelState.PlayerState.new()]
	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	_cards = []
	turbo = bool(setup.get("turbo", false))
	for t in 2:
		var p := t ^ int(swap)
		var ps: DuelState.PlayerState = st.players[p]
		ps.name = str(names[p])
		if turbo:
			_cards.append([t, OcgCore.SPEED_WORLD, OcgCore.LOC_SZONE, OcgCore.POS_FU_ATK, 5])
		var order := [2, 1, 3, 0, 4]       # (laid out from the middle, as a person would)
		var zi := 0
		for pair in (setup.get("mons", [[], []]) as Array)[p]:
			var zone: int = order[mini(zi, 4)]
			zi += 1
			var mc := _new_card(int(pair[0]), p)
			var how := str(pair[1])
			mc.face_up = how != "set"
			mc.attack_pos = how == "atk"
			mc.summoned_turn = 0
			ps.field[zone] = mc
			_cards.append([t, mc.id, OcgCore.LOC_MZONE, OcgCore.POS_FU_ATK if how == "atk" else (OcgCore.POS_FU_DEF if how == "def" else OcgCore.POS_FD_DEF), zone])
		zi = 0
		for id in (setup.get("st", [[], []]) as Array)[p]:
			var szone: int = order[mini(zi, 4)]
			zi += 1
			# (a bare id is Set; [id, "up"] is already face-up, for a Continuous card in play)
			var up: bool = id is Array and str(id[1]) == "up"
			var sc := _new_card(int(id[0]) if id is Array else int(id), p)
			sc.face_up = up
			ps.spells[szone] = sc
			_cards.append([t, sc.id, OcgCore.LOC_SZONE, OcgCore.POS_FU_ATK if up else 0xa, szone])
		for id in (setup.get("hand", [[], []]) as Array)[p]:
			ps.hand.append(_new_card(int(id), p))
			_cards.append([t, int(id), OcgCore.LOC_HAND, 0xa])
		for id in (setup.get("gy", [[], []]) as Array)[p]:
			ps.gy.append(_new_card(int(id), p))
			_cards.append([t, int(id), OcgCore.LOC_GRAVE, OcgCore.POS_FU_ATK])
		var main: Array = (decks[p] as Array).duplicate()
		for i in range(main.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = main[i]
			main[i] = main[j]
			main[j] = tmp
		for id in main:
			ps.deck.append(_new_card(int(id), p))
			_cards.append([t, int(id), OcgCore.LOC_DECK, OcgCore.POS_FD_DEF])
		for id in extras[p]:
			ps.extra.append(_new_card(int(id), p))
			_cards.append([t, int(id), OcgCore.LOC_EXTRA, OcgCore.POS_FD_DEF])
	st.current = first
	st.turn = 0
	_seed = rng.randi()


## Start the engine: Life Points and opening hands per player. False when the engine is not there.
## rules: {"flags": extra duel flags, "destiny": [may player 0, may player 1], "speed": [counters to start with]}
func start(lp: Array, hand: Array, rules := {}) -> bool:
	if not OcgCore.ensure_loaded():
		return false
	OcgCore.register_originals()
	for p in 2:
		st.players[p].lp = int(lp[p])
	handle = OcgCore.create(_seed, [lp[int(swap)], lp[1 - int(swap)]], [hand[int(swap)], hand[1 - int(swap)]], OcgCore.DUEL_FLAGS | int(rules.get("flags", 0)))
	if handle == 0:
		return false
	# This game's own rules go in before the cards do (the cards' scripts read what is set here).
	var sp: Array = rules.get("speed", [0, 0])
	if turbo and (int(sp[0]) > 0 or int(sp[1]) > 0):
		OcgCore.load_script(handle, "crossroads_speed.lua", "CROSSROADS_SPEED_START={[0]=%d,[1]=%d}" % [int(sp[int(swap)]), int(sp[1 - int(swap)])])
	var dz: Array = rules.get("destiny", [false, false])
	if bool(dz[0]) or bool(dz[1]):
		var text := FileAccess.get_file_as_string("res://data/ocg/destiny.lua")
		if text != "":
			OcgCore.load_script(handle, "crossroads_destiny.lua", "CROSSROADS_DESTINY={[0]=%s,[1]=%s}\n%s" % [str(bool(dz[int(swap)])).to_lower(), str(bool(dz[1 - int(swap)])).to_lower(), text])
	OcgCore.add_cards(handle, _cards)
	OcgCore.start(handle)
	return true


func setup(state: DuelState, decks: Array, extras: Array, names: Array, first: int, lp: Array, hand: Array, seed := -1) -> bool:
	if not OcgCore.ensure_loaded():
		return false
	prepare(state, decks, extras, names, first, seed)
	return start(lp, hand)


func close() -> void:
	if handle != 0:
		OcgCore.destroy(handle)
		handle = 0


## A duel that ends early (you leave the table, the scene closes) still frees its engine.
func _notification(what: int) -> void:
	# (Inline, not close(): while it is being freed, calling its own methods fails.)
	if what == NOTIFICATION_PREDELETE and handle != 0:
		OcgCore.destroy(handle)
		handle = 0


func _new_card(id: int, owner: int) -> DuelState.CardInst:
	var c: DuelState.CardInst = st._make(id, owner)
	if c.data.is_empty() or str(c.data.get("name", "")) in ["", "Unknown"]:
		var td := OcgCore.token_data(id)
		c.data = td if not td.is_empty() else {"id": id, "name": "Token", "frame": "token", "kind": "monster", "atk": 0, "def": 0, "level": 1}
	return c


func _err(text: String) -> void:
	if errors.size() < 60:
		errors.append(text)


# ------------------------------------------------------------------ running

## Run the engine until it asks something or the duel ends. Returns the events to play.
func advance() -> Array:
	var events: Array = []
	if over or handle == 0:
		return events
	request = null
	var res := OcgCore.process(handle)
	steps += 1
	var msgs: Array = res.get("msgs", [])
	if swap:
		_norm(msgs)
	for m in msgs:
		_one(m, events)
	_flush(events)
	if int(res.get("status", 0)) == 0 and not st.is_over():
		st._set_winner(DuelState.DRAW, "The duel ended.")
	if st.is_over():
		over = true
		request = null
	var lg := OcgCore.logs(handle)
	for s in lg.get("logs", []):
		if not str(s).begins_with("9:"):     # (9: the thinking opponent's own notes, not an error)
			_err("script: " + str(s))
	for s in lg.get("missing", []):
		_err("missing script: " + str(s))
	_sync()
	if turbo:
		for p in 2:
			var ps: DuelState.PlayerState = st.players[p]
			if ps.speed != int(speed[p]):
				events.append({"type": "speed", "player": p, "speed": int(speed[p]), "delta": int(speed[p]) - ps.speed})
				ps.speed = int(speed[p])
	if request == null and not over:
		_err("the engine stopped without a question")
		over = true
		st._set_winner(DuelState.DRAW, "The duel stopped.")
	return events


func answer(bytes: PackedByteArray) -> void:
	if handle == 0 or request == null:
		return
	_last_request = request
	request = null
	OcgCore.respond(handle, bytes)


func _norm(v) -> void:
	if v is Dictionary:
		for k in v:
			var x = v[k]
			if x is Dictionary or x is Array:
				_norm(x)
			elif (k == "p" or k == "con" or k == "tc") and int(x) < 2:
				v[k] = 1 - int(x)
	elif v is Array:
		for x in v:
			_norm(x)


# ------------------------------------------------------------------ where cards are

func card_at(con: int, loc: int, seq: int, pos := 0):
	if con < 0 or con > 1:
		return null
	var ps: DuelState.PlayerState = st.players[con]
	if loc & OcgCore.LOC_OVERLAY:
		var h = card_at(con, loc & 0x7f, seq)
		return h.overlays[pos] if h != null and pos < h.overlays.size() else null
	match loc:
		OcgCore.LOC_MZONE:
			return ps.field[seq] if seq < 5 else null
		OcgCore.LOC_SZONE:
			return ps.field_spell if seq == 5 else (ps.spells[seq] if seq < 5 else null)
		OcgCore.LOC_HAND:
			return ps.hand[seq] if seq < ps.hand.size() else null
		OcgCore.LOC_GRAVE:
			return ps.gy[seq] if seq < ps.gy.size() else null
		OcgCore.LOC_REMOVED:
			return ps.banished[seq] if seq < ps.banished.size() else null
		OcgCore.LOC_EXTRA:
			return ps.extra[seq] if seq < ps.extra.size() else null
	return null


func _by_id(list: Array, code: int, prefer := -1):
	if prefer >= 0 and prefer < list.size() and list[prefer] != null and list[prefer].id == code:
		return list[prefer]
	for c in list:
		if c != null and c.id == code:
			return c
	return null


## Take a card out of where the engine says it was.
func _take(code: int, f: Dictionary):
	var con := int(f["con"])
	var loc := int(f["loc"])
	var seq := int(f["seq"])
	if loc == 0 or con > 1:
		return null
	var ps: DuelState.PlayerState = st.players[con]
	if loc & OcgCore.LOC_OVERLAY:
		var h = card_at(con, loc & 0x7f, seq)
		if h == null:
			return null
		var oc = _by_id(h.overlays, code, int(f["pos"]))
		if oc != null:
			h.overlays.erase(oc)
		return oc
	var c = null
	match loc:
		OcgCore.LOC_MZONE:
			if seq < 5:
				c = ps.field[seq]
				ps.field[seq] = null
		OcgCore.LOC_SZONE:
			if seq == 5:
				c = ps.field_spell
				ps.field_spell = null
			elif seq < 5:
				c = ps.spells[seq]
				ps.spells[seq] = null
		OcgCore.LOC_HAND:
			c = _by_id(ps.hand, code, seq)
			ps.hand.erase(c)
		OcgCore.LOC_GRAVE:
			c = _by_id(ps.gy, code, seq)
			ps.gy.erase(c)
		OcgCore.LOC_REMOVED:
			c = _by_id(ps.banished, code, seq)
			ps.banished.erase(c)
		OcgCore.LOC_EXTRA:
			c = _by_id(ps.extra, code, seq)
			ps.extra.erase(c)
		OcgCore.LOC_DECK:
			c = _by_id(ps.deck, code)
			ps.deck.erase(c)
	if c != null and c.id != code and code != 0:
		_dirty = true
	return c


func _put(c, t: Dictionary) -> void:
	var con := int(t["con"])
	var loc := int(t["loc"])
	var seq := int(t["seq"])
	var pos := int(t["pos"])
	var ps: DuelState.PlayerState = st.players[con]
	if loc & OcgCore.LOC_OVERLAY:
		var h = card_at(con, loc & 0x7f, seq)
		if h != null:
			h.overlays.append(c)
		else:
			_limbo.append(c)
		c.face_up = true
		return
	if c.owner != con:
		if loc & OcgCore.LOC_ONFIELD:
			if c.orig_owner == -1:
				c.orig_owner = c.owner
		c.owner = con
	if not (loc & OcgCore.LOC_ONFIELD):
		c.orig_owner = -1
		c.equipped_to = null
		c.counter = 0
		c.tags.erase("ocg_atk")
		c.tags.erase("ocg_def")
		c.lv_set = 0
		c.face_up = true
		c.attack_pos = true
	else:
		c.face_up = (pos & OcgCore.POS_FACEUP) != 0
		c.attack_pos = (pos & OcgCore.POS_ATTACK) != 0
	match loc:
		OcgCore.LOC_MZONE:
			if seq < 5:
				if ps.field[seq] != null:
					_limbo.append(ps.field[seq])
					_dirty = true
				ps.field[seq] = c
				c.summoned_turn = st.turn
		OcgCore.LOC_SZONE:
			if seq == 5:
				ps.field_spell = c
			elif seq < 5:
				if ps.spells[seq] != null:
					_limbo.append(ps.spells[seq])
					_dirty = true
				ps.spells[seq] = c
			c.set_turn = st.turn
		OcgCore.LOC_HAND:
			ps.hand.insert(mini(seq, ps.hand.size()), c)
		OcgCore.LOC_GRAVE:
			ps.gy.insert(mini(seq, ps.gy.size()), c)
			c.gy_turn = st.turn
		OcgCore.LOC_REMOVED:
			ps.banished.insert(mini(seq, ps.banished.size()), c)
			c.face_up = (pos & OcgCore.POS_FACEUP) != 0 or pos == 0
		OcgCore.LOC_EXTRA:
			ps.extra.append(c)
		OcgCore.LOC_DECK:
			ps.deck.append(c)


func _zone_name(loc: int) -> String:
	match loc & 0x7f:
		OcgCore.LOC_MZONE, OcgCore.LOC_SZONE: return "field"
		OcgCore.LOC_HAND: return "hand"
		OcgCore.LOC_GRAVE: return "gy"
		OcgCore.LOC_DECK: return "deck"
		OcgCore.LOC_EXTRA: return "extra"
		OcgCore.LOC_REMOVED: return "banished"
	return ""


# ------------------------------------------------------------------ one message

const QUIET := [2, 160, 165, 53, 54, 60, 62, 64, 70]

func _flush(events: Array) -> void:
	if _pending != null:
		var a: Dictionary = _pending
		_pending = null
		var c = a["card"]
		if a["kind"] == "m":
			if c.face_up:
				events.append({"type": "special", "player": a["p"], "card": c, "zone": a["zone"], "method": _method(c, int(a["from"])), "origin": int(a["from"])})
			else:
				events.append({"type": "set", "player": a["p"], "card": c, "zone": a["zone"]})
		elif c.face_up:
			events.append({"type": "activate", "player": a["p"], "card": c, "zone": a["zone"]})
		else:
			events.append({"type": "set_st", "player": a["p"], "card": c, "zone": a["zone"]})
	if _flip != null:
		var b: Dictionary = _flip
		_flip = null
		events.append({"type": "trap", "player": b["p"], "card": b["card"], "zone": b["zone"]})


func _method(c, from: int) -> String:
	var fr: String = c.frame()
	if from == OcgCore.LOC_EXTRA and fr in ["fusion", "synchro", "xyz"]:
		return fr
	if fr == "ritual" and from == OcgCore.LOC_HAND:
		return "ritual"
	if from == OcgCore.LOC_GRAVE:
		return "reborn"
	return ""


func _one(m: Dictionary, ev: Array) -> void:
	var t := int(m["t"])
	if log_msgs:
		print("MSG ", m)
	if m.has("bad"):
		_err("short message %d" % t)
	if (_pending != null or _flip != null) and not QUIET.has(t):
		_flush(ev)
	if (t >= 10 and t <= 26) or (t >= 140 and t <= 143) or t == 132:
		request = m
		return
	match t:
		1:
			retries += 1
			_err("the engine refused an answer to message %d" % (int(_last_request["t"]) if _last_request != null else -1))
			request = _last_request
		2:
			_hint(m, ev)
		5:
			var wp := int(m["p"])
			var why := OcgCore.victory(int(m["reason"]))
			st._set_winner(wp if wp < 2 else DuelState.DRAW, why if why != "" else "The duel is over.")
		31:
			_confirm(m, ev)
		33:
			_reorder(st.players[int(m["p"])].hand, m["codes"])
		36, 35, 39:
			_dirty = true
		40:
			st.turn += 1
			st.current = int(m["p"])
			st.normal_summoned = false
			ev.append({"type": "turn", "player": st.current})
		41:
			_phase(int(m["phase"]), ev)
		50:
			_move(m, ev)
		53:
			_pos_change(m, ev)
		54:
			_arrived(m["card"], "set", ev)
		55:
			_swap(m)
		60:
			_arrived(m["card"], "summon", ev)
		62:
			_arrived(m["card"], "special", ev)
		64:
			var fc = card_at(int(m["card"]["con"]), int(m["card"]["loc"]), int(m["card"]["seq"]))
			if fc != null:
				fc.face_up = true
				fc.attack_pos = true
				ev.append({"type": "flip", "player": int(m["card"]["con"]), "card": fc, "zone": int(m["card"]["seq"])})
		70:
			_chaining(m, ev)
		72:
			if _chain_n >= 2:
				ev.append({"type": "chain_solving", "n": int(m["n"])})
		73:
			if _chain_n >= 2:
				ev.append({"type": "chain_solved", "n": int(m["n"])})
		75, 76:
			# (negated: the activation itself; disabled: its effect. Either way it does nothing.)
			ev.append({"type": "chain_negated", "n": int(m["n"]), "card": chain_cards[int(m["n"]) - 1] if int(m["n"]) >= 1 and int(m["n"]) <= chain_cards.size() else null})
		74:
			if _chain_n >= 1:
				ev.append({"type": "chain_end"})
			_chain_n = 0
			chain_cards.clear()
		90:
			var dp := int(m["p"])
			for dc in m["cards"]:
				var code := int(dc["code"]) & 0x7fffffff
				var c = _by_id(st.players[dp].deck, code)
				if c == null:
					c = _new_card(code, dp)
					_dirty = true
				else:
					st.players[dp].deck.erase(c)
				c.face_up = true
				st.players[dp].hand.append(c)
				ev.append({"type": "draw", "player": dp, "card": c, "deck": st.players[dp].deck.size()})
		91, 100:
			_lp(int(m["p"]), -int(m["v"]), ev)
		92:
			_lp(int(m["p"]), int(m["v"]), ev)
		94:
			var lpp := int(m["p"])
			_lp(lpp, int(m["v"]) - st.players[lpp].lp, ev)
		93:
			var ea = _loc_card(m["a"])
			if ea != null:
				ea.equipped_to = _loc_card(m["b"])
		95:
			var ua = _loc_card(m["a"])
			if ua != null:
				ua.equipped_to = null
		101, 102:
			var cc = card_at(int(m["con"]), int(m["loc"]), int(m["seq"]))
			if cc != null:
				cc.counter = maxi(0, cc.counter + (int(m["n"]) if t == 101 else -int(m["n"])))
		110:
			_attacker = _loc_card(m["a"])
			if _attacker != null:
				_attacker.attacked_turn = st.turn
				ev.append({"type": "attack", "player": int(m["a"]["con"]), "card": _attacker, "target": _loc_card(m["b"]) if int(m["b"]["loc"]) != 0 else null})
		111:
			var ba = _loc_card(m["a"])
			if ba != null:
				ev.append({"type": "battle", "player": int(m["a"]["con"]), "card": ba, "target": _loc_card(m["b"]) if int(m["b"]["loc"]) != 0 else null})
		112:
			if _attacker != null:
				ev.append({"type": "attack_stopped", "player": _attacker.owner, "card": _attacker})
		130:
			var faces: Array = []
			for r in m["res"]:
				faces.append(Loc.t("Heads") if int(r) == 1 else Loc.t("Tails"))
			ev.append({"type": "effect", "player": int(m["p"]), "card": null, "text": Loc.t("Coin toss: ") + ", ".join(faces)})
		131:
			var rolls: Array = []
			for r in m["res"]:
				rolls.append(str(int(r)))
			ev.append({"type": "effect", "player": int(m["p"]), "card": null, "text": Loc.t("Dice roll: ") + ", ".join(rolls)})
		_:
			pass


func _loc_card(l: Dictionary):
	if int(l["loc"]) == 0:
		return null
	return card_at(int(l["con"]), int(l["loc"]), int(l["seq"]), int(l.get("pos", 0)))


func _hint(m: Dictionary, ev: Array) -> void:
	var ht := int(m["ht"])
	var p := int(m["p"])
	var v := int(m["v"])
	match ht:
		3:
			hints[p] = v
		4:
			var words := OcgCore.desc(v)
			if words != "":
				ev.append({"type": "effect", "player": p, "card": null, "text": words})
		6, 7, 8, 9:
			pass


func _confirm(m: Dictionary, ev: Array) -> void:
	# Cards shown to player p. Worth a line when they are cards p could not see before.
	var p := int(m["p"])
	var names: Array = []
	for cd in m["cards"]:
		if int(cd["con"]) != p or int(cd["loc"]) == OcgCore.LOC_DECK:
			var d: Dictionary = CardData.get_card(int(cd["code"]))
			if str(d.get("name", "")) != "":
				names.append(str(d["name"]))
	if p == 0 and not names.is_empty():
		ev.append({"type": "effect", "player": 1, "card": null, "text": Loc.t("Revealed: ") + ", ".join(names.slice(0, 4))})


func _reorder(list: Array, codes: Array) -> void:
	var pool := list.duplicate()
	var out: Array = []
	for code in codes:
		var c = _by_id(pool, int(code))
		if c != null:
			pool.erase(c)
			out.append(c)
	out.append_array(pool)
	for i in list.size():
		list[i] = out[i]


func _phase(raw: int, ev: Array) -> void:
	_phase_raw = raw
	var ph := st.phase
	match raw:
		0x01: ph = DuelState.Phase.DRAW
		0x02: ph = DuelState.Phase.STANDBY
		0x04: ph = DuelState.Phase.MAIN1
		0x08, 0x10, 0x20, 0x40, 0x80: ph = DuelState.Phase.BATTLE
		0x100: ph = DuelState.Phase.MAIN2
		0x200: ph = DuelState.Phase.END
	if ph != st.phase or raw == 0x01:
		st.phase = ph
		ev.append({"type": "phase", "phase": ph, "player": st.current})


func _lp(p: int, delta: int, ev: Array) -> void:
	var ps: DuelState.PlayerState = st.players[p]
	ps.lp = maxi(0, ps.lp + delta)
	if delta != 0:
		ev.append({"type": "lp", "player": p, "lp": ps.lp, "delta": delta})


func _swap(m: Dictionary) -> void:
	var a: Dictionary = m["a"]
	var b: Dictionary = m["b"]
	var ca = _take(int(a["code"]), a)
	var cb = _take(int(b["code"]), b)
	if ca != null:
		_put(ca, b)
	if cb != null:
		_put(cb, a)
	_dirty = true


func _pos_change(m: Dictionary, ev: Array) -> void:
	var con := int(m["con"])
	var loc := int(m["loc"])
	var seq := int(m["seq"])
	var c = card_at(con, loc, seq)
	if c == null:
		_dirty = true
		return
	var pp := int(m["pp"])
	var cp := int(m["cp"])
	c.face_up = (cp & OcgCore.POS_FACEUP) != 0
	c.attack_pos = (cp & OcgCore.POS_ATTACK) != 0
	c.pos_changed_turn = st.turn
	if loc == OcgCore.LOC_MZONE:
		if not (pp & OcgCore.POS_FACEUP) and c.face_up:
			ev.append({"type": "flip", "player": con, "card": c, "zone": seq})
		else:
			ev.append({"type": "position", "player": con, "card": c, "zone": seq})
	elif loc == OcgCore.LOC_SZONE:
		if not (pp & OcgCore.POS_FACEUP) and c.face_up:
			_flip = {"card": c, "p": con, "zone": seq}
		elif not c.face_up:
			ev.append({"type": "st_reset", "player": con, "card": c, "zone": seq})


## A Summon / Set message for the card that just reached the field.
func _arrived(cl: Dictionary, kind: String, ev: Array) -> void:
	var con := int(cl["con"])
	var loc := int(cl["loc"])
	var seq := int(cl["seq"])
	var c = card_at(con, loc, seq)
	var a = _pending
	if a != null and a["card"] != c:
		_flush(ev)
		a = null
	_pending = null
	if c == null:
		return
	var from := int(a["from"]) if a != null else OcgCore.LOC_HAND
	if loc == OcgCore.LOC_SZONE:
		if kind == "set":
			if a == null:
				ev.append({"type": "st_reset", "player": con, "card": c, "zone": seq})
			else:
				ev.append({"type": "set_st", "player": con, "card": c, "zone": seq})
		return
	match kind:
		"set":
			if a == null:
				ev.append({"type": "position", "player": con, "card": c, "zone": seq})
			else:
				ev.append({"type": "set", "player": con, "card": c, "zone": seq})
		"summon":
			st.normal_summoned = true
			c.normal_turn = st.turn
			ev.append({"type": "summon", "player": con, "card": c, "zone": seq})
		"special":
			if a == null:
				return   # (already there: a Summon that was being negotiated)
			if c.face_up:
				ev.append({"type": "special", "player": con, "card": c, "zone": seq, "method": _method(c, from), "origin": from})
			else:
				ev.append({"type": "set", "player": con, "card": c, "zone": seq})


func _chaining(m: Dictionary, ev: Array) -> void:
	var cl: Dictionary = m["card"]
	var con := int(cl["con"])
	var loc := int(cl["loc"])
	var c = card_at(con, loc, int(cl["seq"]), int(cl.get("pos", 0)))
	var who := int(m["tc"])
	var n := int(m["n"])
	chain_cards.append(c)
	_chain_n = n
	# (0.57.0) Every link is told to the table after its card has been shown: the table hangs a
	# numbered link on it once the chain is two long.
	var link := {"type": "chain_link", "n": n, "player": who, "card": c}
	if _pending != null and _pending["card"] == c and _pending["kind"] == "s":
		var a: Dictionary = _pending
		_pending = null
		ev.append({"type": "activate", "player": who, "card": c, "zone": a["zone"]})
		ev.append(link)
		return
	if _flip != null and _flip["card"] == c:
		var b: Dictionary = _flip
		_flip = null
		ev.append({"type": "trap", "player": who, "card": c, "zone": b["zone"]})
		ev.append(link)
		return
	_flush(ev)
	var text := ""
	if c != null:
		text = c.cname()
	else:
		text = OcgCore.card_name(int(cl["code"]))
	var line := OcgCore.desc(int(m["desc"]))
	if line != "" and line.length() < 70:
		text += ": " + line
	ev.append({"type": "effect", "player": who, "card": c if c != null and (loc & OcgCore.LOC_ONFIELD) != 0 else null, "text": text})
	ev.append(link)


func _move(m: Dictionary, ev: Array) -> void:
	var f: Dictionary = m["from"]
	var t: Dictionary = m["to"]
	var code := int(m["code"])
	var reason := int(m["reason"])
	var fl := int(f["loc"])
	var tl := int(t["loc"])
	var F := fl & 0x7f
	var T := tl & 0x7f
	var pf := int(f["con"])
	var pt := int(t["con"])
	var holder = card_at(pf, F, int(f["seq"])) if (fl & OcgCore.LOC_OVERLAY) else null
	var c = _take(code, f)
	if c == null:
		c = _new_card(code, pt if tl != 0 else pf)
		if fl != 0:
			_dirty = true
	if tl == 0:
		# A Token leaving the field is gone.
		ev.append({"type": "destroy", "player": pf, "card": c, "overlays": []})
		_limbo.append(c)
		return
	var ctrl: int = c.owner
	_put(c, t)
	if tl & OcgCore.LOC_OVERLAY:
		if F == OcgCore.LOC_MZONE or F == OcgCore.LOC_HAND:
			ev.append({"type": "material", "player": pf, "card": c, "from": "field" if F == OcgCore.LOC_MZONE else "hand"})
		return
	if fl & OcgCore.LOC_OVERLAY:
		if holder != null:
			ev.append({"type": "detach", "player": pf, "card": holder})
		if T == OcgCore.LOC_GRAVE:
			ev.append({"type": "mill", "player": pt, "card": c, "deck": st.players[pt].deck.size()})
		return
	match T:
		OcgCore.LOC_MZONE:
			if F == OcgCore.LOC_MZONE:
				ev.append({"type": "control", "player": pt, "card": c, "zone": int(t["seq"])})
			else:
				_pending = {"card": c, "p": pt, "zone": int(t["seq"]), "from": F, "kind": "m"}
		OcgCore.LOC_SZONE:
			if F != OcgCore.LOC_SZONE and F != OcgCore.LOC_MZONE:
				_pending = {"card": c, "p": pt, "zone": int(t["seq"]), "from": F, "kind": "s"}
		OcgCore.LOC_GRAVE:
			match F:
				OcgCore.LOC_MZONE:
					if (reason & R_RELEASE) and (reason & R_SUMMON):
						# Tributed for a Normal Summon or Set (the engine also calls these "material"):
						# they go the way Tributes go, and the monster that follows is a plain Summon.
						ev.append({"type": "tribute", "player": pf, "card": c})
					elif reason & R_MATERIAL:
						ev.append({"type": "material", "player": pf, "card": c, "from": "field"})
					elif reason & R_RELEASE:
						ev.append({"type": "tribute", "player": pf, "card": c})
					else:
						ev.append({"type": "destroy", "player": pf, "card": c, "overlays": []})
				OcgCore.LOC_SZONE:
					if (reason & R_RULE) and not (reason & R_DESTROY):
						ev.append({"type": "spell_done", "player": pf, "card": c})
					else:
						ev.append({"type": "destroy_st", "player": pf, "card": c})
				OcgCore.LOC_HAND:
					if reason & R_MATERIAL:
						ev.append({"type": "material", "player": pf, "card": c, "from": "hand"})
					else:
						ev.append({"type": "discard", "player": pf, "card": c})
				OcgCore.LOC_DECK, OcgCore.LOC_EXTRA:
					ev.append({"type": "mill", "player": pf, "card": c, "deck": st.players[pf].deck.size()})
				OcgCore.LOC_REMOVED:
					ev.append({"type": "unbanish", "player": pt, "card": c, "to": "gy"})
		OcgCore.LOC_REMOVED:
			ev.append({"type": "banish", "player": pf, "card": c, "from": _zone_name(F), "side": ctrl if F == OcgCore.LOC_HAND else pf})
		OcgCore.LOC_HAND:
			match F:
				OcgCore.LOC_DECK, OcgCore.LOC_EXTRA:
					ev.append({"type": "search", "player": pt, "card": c, "deck": st.players[pt].deck.size()})
				OcgCore.LOC_MZONE, OcgCore.LOC_SZONE:
					ev.append({"type": "bounce", "player": pt, "card": c})
				OcgCore.LOC_GRAVE:
					ev.append({"type": "gy_to_hand", "player": pt, "card": c})
				OcgCore.LOC_REMOVED:
					ev.append({"type": "unbanish", "player": pt, "card": c, "to": "hand"})
					ev.append({"type": "search", "player": pt, "card": c, "deck": st.players[pt].deck.size()})
		OcgCore.LOC_DECK, OcgCore.LOC_EXTRA:
			match F:
				OcgCore.LOC_MZONE, OcgCore.LOC_SZONE:
					ev.append({"type": "bounce", "player": pt, "card": c, "extra": true})
				OcgCore.LOC_GRAVE:
					ev.append({"type": "gy_to_deck", "player": pt, "card": c, "deck": st.players[pt].deck.size()})
				OcgCore.LOC_REMOVED:
					ev.append({"type": "unbanish", "player": pt, "card": c, "to": "deck"})


# ------------------------------------------------------------------ keeping the mirror honest

## Compare the mirror with the engine, repair it if it drifted, and copy the engine's numbers
## (ATK, DEF, Level, counters, positions) onto the cards.
func _sync() -> void:
	if handle == 0:
		return
	var q := OcgCore.query(handle, OcgCore.LOC_HAND | OcgCore.LOC_MZONE | OcgCore.LOC_SZONE | OcgCore.LOC_GRAVE | OcgCore.LOC_REMOVED | OcgCore.LOC_EXTRA)
	if q.size() < 2:
		return
	var cn := OcgCore.counts(handle)
	for t in 2:
		var p := t ^ int(swap)
		var ps: DuelState.PlayerState = st.players[p]
		var d: Dictionary = q[t]
		_sync_list(ps.hand, d.get(str(OcgCore.LOC_HAND), []), p, "hand")
		# (a hand a card effect keeps revealed: the engine says so card by card)
		var eh: Array = d.get(str(OcgCore.LOC_HAND), [])
		for i in mini(ps.hand.size(), eh.size()):
			if eh[i] != null and int(eh[i].get("pub", 0)) != 0:
				ps.hand[i].tags["public"] = true
			else:
				ps.hand[i].tags.erase("public")
		_sync_list(ps.gy, d.get(str(OcgCore.LOC_GRAVE), []), p, "gy")
		_sync_list(ps.banished, d.get(str(OcgCore.LOC_REMOVED), []), p, "banished")
		# (banished face-down: its owner may look, the other side may not)
		var eb: Array = d.get(str(OcgCore.LOC_REMOVED), [])
		for i in mini(ps.banished.size(), eb.size()):
			if eb[i] != null and (int(eb[i].get("pos", 1)) & OcgCore.POS_FACEUP) == 0:
				ps.banished[i].tags["facedown"] = true
			else:
				ps.banished[i].tags.erase("facedown")
		_sync_list(ps.extra, d.get(str(OcgCore.LOC_EXTRA), []), p, "extra")
		var mz: Array = d.get(str(OcgCore.LOC_MZONE), [])
		for i in 5:
			ps.field[i] = _sync_slot(ps.field[i], mz[i] if i < mz.size() else null, p, "monster zone")
		var sz: Array = d.get(str(OcgCore.LOC_SZONE), [])
		for i in 5:
			ps.spells[i] = _sync_slot(ps.spells[i], sz[i] if i < sz.size() else null, p, "spell zone")
		var fz = sz[5] if sz.size() > 5 else null
		if fz != null and int(fz.get("code", 0)) == OcgCore.SPEED_WORLD:
			# Speed World 2 is the road, not a card on the table: only its counters are read.
			var n := 0
			for ct in fz.get("ctr", []):
				n += int(ct) >> 16
			speed[p] = n
		else:
			ps.field_spell = _sync_slot(ps.field_spell, fz, p, "field zone")
		if cn.size() == 2:
			var want := int(cn[t]["deck"])
			if ps.deck.size() != want:
				if not _dirty:
					_err("deck count p%d: %d, the engine has %d" % [p, ps.deck.size(), want])
				while ps.deck.size() > want:
					_limbo.append(ps.deck.pop_back())
				while ps.deck.size() < want:
					ps.deck.append(_new_card(0, p))
			var elp := int(cn[t]["lp"])
			if elp > 0x7fffffff:
				elp -= 0x100000000     # (the engine lets Life Points go below zero)
			ps.lp = maxi(0, elp)
	# Equip links, now that every card is in place.
	for t in 2:
		var p := t ^ int(swap)
		var sz: Array = (q[t] as Dictionary).get(str(OcgCore.LOC_SZONE), [])
		for i in mini(5, sz.size()):
			var c = st.players[p].spells[i]
			var e = sz[i]
			if c == null or e == null:
				continue
			var eq = e.get("eq")
			if eq is Dictionary and int(eq["loc"]) != 0:
				var econ := int(eq["con"]) ^ int(swap)
				c.equipped_to = card_at(econ, int(eq["loc"]), int(eq["seq"]))
			else:
				c.equipped_to = null
	_dirty = false


func _grab(code: int, p: int):
	for c in _limbo:
		if c.id == code:
			_limbo.erase(c)
			c.owner = p
			return c
	return _new_card(code, p)


func _sync_list(list: Array, eng: Array, p: int, what: String) -> void:
	var same := list.size() == eng.size()
	if same:
		for i in list.size():
			if eng[i] == null or list[i].id != int(eng[i].get("code", 0)):
				same = false
				break
	if same:
		return
	if check and not _dirty:
		var a: Array = []
		for c in list:
			a.append(c.id)
		var b: Array = []
		for e in eng:
			b.append(int(e.get("code", 0)) if e != null else 0)
		_err("%s p%d drifted: %s, the engine has %s" % [what, p, str(a), str(b)])
	var pool := list.duplicate()
	list.clear()
	for e in eng:
		if e == null:
			continue
		var code := int(e.get("code", 0))
		var c = _by_id(pool, code)
		if c != null:
			pool.erase(c)
		else:
			c = _grab(code, p)
		list.append(c)
	_limbo.append_array(pool)


func _sync_slot(c, e, p: int, what: String):
	if e == null:
		if c != null:
			if check and not _dirty:
				_err("%s p%d: %s is not there in the engine" % [what, p, c.cname()])
			_limbo.append(c)
		return null
	var code := int(e.get("code", 0))
	if c == null or c.id != code:
		if check and not _dirty:
			_err("%s p%d: has %s, the engine has %d" % [what, p, c.cname() if c != null else "nothing", code])
		if c != null:
			_limbo.append(c)
		c = _grab(code, p)
	var pos := int(e.get("pos", 1))
	c.face_up = (pos & OcgCore.POS_FACEUP) != 0
	c.attack_pos = (pos & OcgCore.POS_ATTACK) != 0
	c.owner = p
	if not c.face_up and int(e.get("pub", 0)) != 0:
		c.tags["public"] = true     # (a Set card a card effect lets the other side look at)
	else:
		c.tags.erase("public")
	var own := int(e.get("owner", 0)) ^ int(swap)
	c.orig_owner = own if own != p else -1
	if int(e.get("type", 0)) & 0x1:
		c.tags["ocg_atk"] = maxi(0, int(e.get("atk", 0)))
		c.tags["ocg_def"] = maxi(0, int(e.get("def", 0)))
		var lv := int(e.get("lvl", 0))
		if lv == 0:
			lv = int(e.get("rank", 0))
		c.lv_set = lv if lv > 0 and lv != int(c.data.get("level", 0)) else 0
	var n := 0
	for ct in e.get("ctr", []):
		n += int(ct) >> 16
	c.counter = n
	c.negated = (int(e.get("status", 0)) & 0x1) != 0
	var ov: Array = e.get("ov", [])
	if ov.size() != c.overlays.size():
		var pool: Array = c.overlays.duplicate()
		c.overlays.clear()
		for oc in ov:
			var x = _by_id(pool, int(oc))
			if x != null:
				pool.erase(x)
			else:
				x = _grab(int(oc), p)
			c.overlays.append(x)
		_limbo.append_array(pool)
	return c


# ------------------------------------------------------------------ answers

static func i32(v: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(4)
	b.encode_s32(0, v)
	return b


## Pick cards by their place in the question's list.
static func pick(indexes: Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(8 + 4 * indexes.size())
	b.encode_s32(0, 0)
	b.encode_u32(4, indexes.size())
	for i in indexes.size():
		b.encode_u32(8 + 4 * i, int(indexes[i]))
	return b


static func pick_one(index: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_s32(0, 1)
	b.encode_s32(4, index)
	return b


## zones: [[player, location, sequence], ...] with our player numbers.
func place(zones: Array) -> PackedByteArray:
	var b := PackedByteArray()
	for z in zones:
		b.append(int(z[0]) ^ int(swap))
		b.append(int(z[1]))
		b.append(int(z[2]))
	return b


## The free zones a place question allows, as [[player, location, sequence], ...].
func place_options(m: Dictionary) -> Array:
	var p := int(m["p"])
	var flag := int(m["flag"])
	var out: Array = []
	for side in 2:
		for loc_i in 2:
			for s in (7 if loc_i == 0 else 8):
				var bit := s + (0 if loc_i == 0 else 8) + (0 if side == 0 else 16)
				if not (flag >> bit) & 1:
					out.append([p if side == 0 else 1 - p, OcgCore.LOC_MZONE if loc_i == 0 else OcgCore.LOC_SZONE, s])
	return out


## The cards a question lists, as cards of the mirror (same order; null where one cannot be found).
func cards_of(list: Array) -> Array:
	var out: Array = []
	var used := {}
	for e in list:
		var con := int(e["con"])
		var loc := int(e["loc"])
		var c = null
		if con > 1:
			out.append(null)
			continue
		if loc == OcgCore.LOC_DECK or loc == 0:
			for x in st.players[con].deck:
				if x.id == int(e["code"]) and not used.has(x.uid):
					c = x
					break
		else:
			c = card_at(con, loc, int(e["seq"]), int(e.get("pos", 0)))
		if c != null:
			used[c.uid] = true
		out.append(c)
	return out
