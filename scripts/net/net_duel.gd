class_name NetDuel
extends RefCounted
## One online duel (or a Match of 3) between two copies of the game (0.73.0).
##
## One engine, two screens. The HOST runs the duel engine exactly as against the CPU; the other side's
## answers come over the line instead of from the CPU. After every step the engine takes, the host
## sends that step to the GUEST: what happened (the engine's messages) and what is on the table
## (its picture of the cards), with everything the guest may not see taken out first (see _for_guest):
## the cards in the host's hand and Deck, its face-down cards, its own questions. The guest's game
## plays the steps through the same code a replay uses (OcgDuel.feed), so it shows the same duel with
## its own animations, and when a question is the guest's it asks it on the guest's screen and sends
## the answer back. The duel only lives in one place, so it cannot go out of step.
##
## Everything the host sends is kept and numbered. A line that drops is not the end: the guest's game
## calls again, says how much it has ("resume"), and catches up at speed.

signal entry_in                 # (guest) a step or a note came in
signal answer_in                # (host) the guest answered
signal deck_in                  # (host) the guest's deck came in
signal start_in                 # (guest) the host says how this duel starts
signal first_in                 # (host) the guest said whether they go first
signal ask_first_in             # (guest) the host asks you who starts
signal again_in                 # the other side wants another duel (or the next of the Match)
signal ended(why: String)       # the other side left, surrendered or the duel was called off
signal line_changed(up: bool)   # the line to the other side dropped / came back

var peer := ""
var sid := ""
var host := false
var challenger := false
var opts := {}
var deck := {}                  # your own deck: {main, extra, side, name}
var host_why := ""
var game := 1                   # which duel of the Match this is
var orig_deck := {}             # your deck as it was when the Match began
var wins := [0, 0]              # (in a Match) yours, theirs

# Host
var guest_deck := {}
var entries: Array = []         # everything sent to the guest this duel, in order
var want := -1                  # the entry whose question the guest is answering (-1: none open)
var _answers: Array = []        # [index, bytes]
var swap := false               # the host's engine: its player 0 is the host's player 1
# Guest
var start := {}
var inbox: Array = []           # entries that came in, not played yet
var have := 0                   # how many entries have come in
var _last_answer := []          # [index, bytes] until the next entry shows it was taken
var _played := 0
var first_pick := -1
# Both
var up := true                  # the line to them is open
var down_since := 0
var gone := ""                  # why the duel is over from their side ("" while it goes on)
var again_them := {}
var again_me := false
var record_done := false
var result_seen := false


func them() -> Dictionary:
	var c: NetConn = Net.conns.get(peer)
	return c.hello if c != null else {}


func their_name() -> String:
	return str(them().get("name", Characters.get_char("net:" + peer).get("name", "Duelist")))


func _send(msg: Dictionary) -> void:
	msg["sid"] = sid
	Net.send_to(peer, msg)


## Both sides go to the duel screen. The guest sends its deck to the host first.
func begin() -> void:
	entries.clear()
	inbox.clear()
	have = 0
	_played = 0
	want = -1
	_answers.clear()
	start = {}
	again_them = {}
	again_me = false
	record_done = false
	result_seen = false
	if orig_deck.is_empty() or game == 1:
		if orig_deck.is_empty():
			orig_deck = deck.duplicate(true)
		else:
			deck = orig_deck.duplicate(true)      # (a new Match: the Side Deck swaps of the last one are undone)
	if host:
		guest_deck = {}
	else:
		_send({"k": "deck", "deck": deck})
	# (0.79.0) Anime decks only: both play as the show's duelist they picked, not as their own.
	var anime := bool(opts.get("anime", false)) and str(opts.get("char", "")) != "" and str(opts.get("their_char", "")) != ""
	var cfg := {"net": true, "player_char": str(opts["char"]) if anime else "player", "opponent": str(opts["their_char"]) if anime else "net:" + peer,
		"player_deck": str(opts["deck"]), "anime": anime,
		"opponent_deck": "", "lp": int(opts.get("lp", 8000)), "match": str(opts.get("mode", "single")) == "match",
		"field": "auto", "destiny": bool(opts.get("destiny", Settings.destiny_draw))}
	if str(opts.get("mode", "")) == "match" and game == 1:
		Router.match_state = {"wins": [0, 0], "game": 1, "last_loser": -1, "net": true}
	Router.duel_config = cfg
	Router.go(Router.DUEL)


# ------------------------------------------------------------------ messages from the other side

func handle(from: String, msg: Dictionary) -> void:
	if from != peer or str(msg.get("sid", "")) != sid:
		return
	match str(msg.get("k", "")):
		"deck":
			if host:
				guest_deck = msg.get("deck", {})
				deck_in.emit()
		"start":
			if not host:
				start = msg
				start_in.emit()
		"step":
			if not host:
				var i := int(msg.get("i", -1))
				if i == have:
					inbox.append(msg.get("e", {}))
					have += 1
					_last_answer = []
					entry_in.emit()
				elif i > have:
					_send({"k": "resume", "have": have})      # (something went missing: from where it did)
		"ans":
			if host:
				_answers.append([int(msg.get("i", -1)), msg.get("b", PackedByteArray())])
				answer_in.emit()
		"resume":
			if host:
				_resend(int(msg.get("have", 0)))
		"ask_first":
			if not host:
				ask_first_in.emit()
		"first":
			if host:
				first_pick = 1 if bool(msg.get("me_first", false)) else 0
				first_in.emit()
		"react":
			var r := int(msg.get("r", 0))
			var scene = Router.get_tree().current_scene
			if scene != null and scene.has_method("net_reaction"):
				scene.net_reaction(r, false)
		"surrender":
			gone = "surrender"
			_wake()
			ended.emit("surrender")
		"leave":
			gone = "left"
			_wake()
			ended.emit("left")
		"nocontest":
			gone = "nocontest"
			_wake()
			ended.emit("nocontest")
		"end":
			# (the host says how it ended, when that is not in the engine's own messages: a surrender)
			start["end"] = msg
			ended.emit(str(msg.get("why", "")))
		"replay":
			if not host:
				_save_replay(msg)
		"again":
			again_them = msg
			if not host and msg.has("first"):
				first_pick = int(msg["first"])
			again_in.emit()
			_maybe_again()


## Whatever is waiting on the other side (an answer, a step, a deck) stops waiting: the duel is over.
func _wake() -> void:
	entry_in.emit()
	answer_in.emit()
	deck_in.emit()
	start_in.emit()
	first_in.emit()


func on_drop(id: String) -> void:
	if id != peer:
		return
	up = false
	down_since = Time.get_ticks_msec()
	line_changed.emit(false)


func on_reconnect(id: String) -> void:
	if id != peer:
		return
	up = true
	line_changed.emit(true)
	if not host:
		_send({"k": "resume", "have": have})
		if not _last_answer.is_empty():
			_send({"k": "ans", "i": int(_last_answer[0]), "b": _last_answer[1]})


# ------------------------------------------------------------------ host

## Every step the engine takes goes to the guest, with what they may not see taken out.
func out_step(msgs: Array, status: int, q: Array, cn: Array) -> void:
	var gm := _for_guest_msgs(msgs)
	Replays._turn_around(gm)      # (the guest is player 0 on its own screen)
	var e := {"m": gm, "s": status, "q": _for_guest_table(q), "c": cn.duplicate(true)}
	if _leak_on:
		_leak_check(e)
	_push(e)


# Dev (NET_LEAK=1 on the host): every step sent is searched for cards that only the host's deck has.
# One that turns up while it is nowhere face-up on the table it was sent with is printed as
# "NET LEAK?" for a look (a card shown by an effect and put back is the usual harmless one).
var _leak_on := OS.has_environment("NET_LEAK")
var _host_only := {}
var _shown := {}
var leaks := 0

func _leak_check(e: Dictionary) -> void:
	if _host_only.is_empty():
		var g := {}
		for k in ["main", "extra", "side"]:
			for id in guest_deck.get(k, []):
				g[int(id)] = true
		for k in ["main", "extra"]:
			for id in deck.get(k, []):
				if not g.has(int(id)):
					_host_only[int(id)] = true
	var on_table := {}
	_codes_in(e["q"], on_table)
	for m in e["m"]:
		# (cards an effect shows to the guest: a search that reveals, the top of a Deck)
		var t := int((m as Dictionary).get("t", -1))
		if t in [30, 42] or (t == 31 and int((m as Dictionary).get("p", 1)) == 0):
			_codes_in(m, _shown)
	on_table.merge(_shown)
	var sent := {}
	_codes_in(e["m"], sent)
	for c in sent:
		if _host_only.has(c) and not on_table.has(c):
			var types: Array = []
			for m in e["m"]:
				types.append(int((m as Dictionary).get("t", -1)))
			leaks += 1
			print("NET LEAK? card %d in step %d, messages %s" % [c, entries.size(), str(types)])


static func _codes_in(v, into: Dictionary) -> void:
	if v is Dictionary:
		for k in v:
			var x = v[k]
			if str(k) == "code" and (x is int or x is float) and int(x) != 0:
				into[int(x)] = true
			elif str(k) == "codes" and x is Array:
				for c in x:
					if int(c) != 0:
						into[int(c)] = true
			else:
				_codes_in(x, into)
	elif v is Array:
		for x in v:
			_codes_in(x, into)


func note(what: Dictionary) -> void:
	_push({"note": what})


func _push(e: Dictionary) -> void:
	entries.append(e)
	_send({"k": "step", "i": entries.size() - 1, "e": e})


func _resend(from: int) -> void:
	for i in range(maxi(0, from), entries.size()):
		_send({"k": "step", "i": i, "e": entries[i]})


## The guest's answer to the question in the last step sent. null when the duel is over first (they
## left, surrendered, or it was called off).
func wait_answer():
	want = entries.size() - 1
	while true:
		for a in _answers:
			if int(a[0]) == want:
				_answers.clear()
				var b = a[1]
				want = -1
				return b if b is PackedByteArray else PackedByteArray()
		_answers = _answers.filter(func(a): return int(a[0]) > want)
		if gone != "":
			want = -1
			return null
		await answer_in


func wait_deck() -> bool:
	while guest_deck.is_empty():
		if gone != "":
			return false
		await deck_in
	return true


## The host starts the duel: who goes first, the Life Points, the names, and how many cards the
## host's Deck and Extra Deck hold (only how many: never which).
func send_start(first: int, lp: Array, names: Array, counts: Array, destiny: Array) -> void:
	_send({"k": "start", "first": 1 - first, "lp": [lp[1], lp[0]], "names": [names[1], names[0]], "counts": counts,
		"destiny": [destiny[1], destiny[0]], "game": game, "wins": [wins[1], wins[0]]})


func ask_first() -> int:
	first_pick = -1
	_send({"k": "ask_first"})
	while first_pick < 0:
		if gone != "":
			return 0
		await first_in
	return first_pick


func answer_first(me_first: bool) -> void:
	_send({"k": "first", "me_first": me_first})


# ------------------------------------------------------------------ guest

func send_answer(bytes: PackedByteArray) -> void:
	_last_answer = [have - 1, bytes]
	_send({"k": "ans", "i": have - 1, "b": bytes})


## The next step or note from the host, in order. null when the duel is over from their side.
func next_entry():
	while _played >= inbox.size():
		if gone != "":
			return null
		await entry_in
	_played += 1
	return inbox[_played - 1]


func waiting_entries() -> int:
	return inbox.size() - _played


func wait_start() -> bool:
	while start.is_empty():
		if gone != "":
			return false
		await start_in
	return true


# ------------------------------------------------------------------ both

func react(r: int) -> void:
	_send({"k": "react", "r": r})


func surrender() -> void:
	_send({"k": "surrender"})


func leave() -> void:
	if gone == "":
		_send({"k": "leave"})
	gone = "me"
	Net.end_session()


func call_off() -> void:
	_send({"k": "nocontest"})
	gone = "nocontest"
	_wake()


## Another duel (or the next one of the Match). `side`: your deck after siding, if it changed.
func again(new_deck := {}) -> void:
	if not new_deck.is_empty():
		deck = new_deck
	again_me = true
	var m := {"k": "again"}
	if host and first_pick >= 0:
		m["first"] = first_pick
	_send(m)
	_maybe_again()


func _maybe_again() -> void:
	if again_me and not again_them.is_empty():
		if str(opts.get("mode", "")) == "match":
			var ms: Dictionary = Router.match_state
			if ms.is_empty() or int(ms["wins"][0]) >= 2 or int(ms["wins"][1]) >= 2:
				game = 1
			else:
				game = int(ms.get("game", game + 1))
		begin()


func host_end(why: String, winner_mine: int, reason: String) -> void:
	# winner_mine: 1 you (the host) won, -1 they did, 0 nobody
	_send({"k": "end", "why": why, "winner": -winner_mine, "reason": reason})


func send_replay(rec: Dictionary, result: Dictionary) -> void:
	_send({"k": "replay", "rec": rec, "result": result})


func _save_replay(msg: Dictionary) -> void:
	var rec: Dictionary = msg.get("rec", {})
	if rec.is_empty():
		return
	var flipped := Replays.flipped(rec)
	var res: Dictionary = (msg.get("result", {}) as Dictionary).duplicate()
	var w := int(res.get("winner", DuelState.DRAW))
	res["winner"] = (1 - w) if w < 2 else w
	if res.has("lp"):
		res["lp"] = [res["lp"][1], res["lp"][0]]
	var path := Replays.save(flipped, res)
	Replays.last_saved = path
	print("NET replay from the host saved: ", path.get_file())


# ------------------------------------------------------------------ what the guest may see

const LOC_DECK := 0x01
const LOC_HAND := 0x02
const LOC_MZONE := 0x04
const LOC_SZONE := 0x08
const LOC_GRAVE := 0x10
const LOC_REMOVED := 0x20
const LOC_EXTRA := 0x40
const LOC_OVERLAY := 0x80
const POS_FACEDOWN := 0xA
const QUESTIONS := [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 140, 141, 142, 143, 132]


## A card of the host's in a place the guest cannot look into.
static func _hidden_place(loc: int, pos: int) -> bool:
	if loc & (LOC_GRAVE | LOC_OVERLAY):
		return false
	if loc & (LOC_DECK | LOC_HAND):
		return true
	return (pos & POS_FACEDOWN) != 0


## The engine's messages of this step, as the guest may see them. The host is player 0 here.
static func _for_guest_msgs(msgs: Array) -> Array:
	var out: Array = []
	var shown := {}          # (con, loc, seq) of host cards revealed to the guest in this step
	for m0 in msgs:
		if not (m0 is Dictionary):
			continue
		var t := int(m0.get("t", -1))
		if t == 31 and int(m0.get("p", 0)) == 1:
			for cd in m0.get("cards", []):
				shown["%d|%d|%d" % [int(cd.get("con", 0)), int(cd.get("loc", 0)), int(cd.get("seq", 0))]] = true
	for m0 in msgs:
		if not (m0 is Dictionary):
			continue
		var m: Dictionary = (m0 as Dictionary).duplicate(true)
		var t := int(m.get("t", -1))
		if t in QUESTIONS:
			if int(m.get("p", 0)) == 0:
				out.append({"t": t, "p": 0})      # (the host's own question: only that it is theirs)
			else:
				_blank_host_cards(m, shown)
				out.append(m)
			continue
		match t:
			2:
				# The host's own "select a card" hints are theirs alone.
				if int(m.get("p", 0)) == 0 and int(m.get("ht", 0)) in [1, 2, 3, 5]:
					continue
			90:
				if int(m.get("p", 0)) == 0:
					for cd in m.get("cards", []):
						if (int(cd.get("pos", 0)) & 0x5) == 0:      # (a card drawn face-up is public)
							cd["code"] = 0
			50:
				var to: Dictionary = m.get("to", {})
				if int(to.get("con", 1)) == 0 and _hidden_place(int(to.get("loc", 0)), int(to.get("pos", 0))):
					m["code"] = 0
			54:
				var sc: Dictionary = m.get("card", {})
				if int(sc.get("con", 1)) == 0:
					sc["code"] = 0
			62:
				var pc: Dictionary = m.get("card", {})
				if int(pc.get("con", 1)) == 0 and (int(pc.get("pos", 0)) & POS_FACEDOWN) != 0:
					pc["code"] = 0
			33, 39:
				if int(m.get("p", 0)) == 0:
					var z: Array = []
					for _c in m.get("codes", []):
						z.append(0)
					m["codes"] = z
			30, 31, 42:
				# Cards confirmed to the host (a look at their own Deck) stay theirs.
				if int(m.get("p", 0)) == 0:
					for cd in m.get("cards", []):
						if int(cd.get("con", 0)) == 0:
							cd["code"] = 0
			38:
				if int(m.get("p", 0)) == 0 and (int(m.get("pos", 0)) & 0x5) == 0:
					m["code"] = 0
			55:
				for key in ["a", "b"]:
					var sw: Dictionary = m.get(key, {})
					if int(sw.get("con", 1)) == 0 and _hidden_place(int(sw.get("loc", 0)), int(sw.get("pos", 0))):
						sw["code"] = 0
		out.append(m)
	return out


## In a question for the guest, the host's cards it may not see show up blank (a face-down card it
## can target is still a face-down card).
static func _blank_host_cards(v, shown: Dictionary) -> void:
	if v is Dictionary:
		var d: Dictionary = v
		if d.has("code") and d.has("con") and d.has("loc") and int(d["con"]) == 0:
			var key := "%d|%d|%d" % [int(d["con"]), int(d["loc"]), int(d.get("seq", 0))]
			if not shown.has(key) and _hidden_place(int(d["loc"]), int(d.get("pos", POS_FACEDOWN if (int(d["loc"]) & (LOC_MZONE | LOC_SZONE)) == 0 else 0))):
				d["code"] = 0
		for k in d:
			if d[k] is Dictionary or d[k] is Array:
				_blank_host_cards(d[k], shown)
	elif v is Array:
		for x in v:
			_blank_host_cards(x, shown)


## The engine's picture of the table, as the guest may see it. q is in the engine's own order;
## the host's side is q[t] with t = 0 ^ swap.
func _for_guest_table(q: Array) -> Array:
	var out: Array = q.duplicate(true)
	if out.size() < 2:
		return out
	var t := int(swap)
	var side: Dictionary = out[t]
	for lk in side.keys():
		var loc := int(lk)
		var list: Array = side[lk]
		for i in list.size():
			var e = list[i]
			if not (e is Dictionary):
				continue
			var pos := int(e.get("pos", 0))
			var pub := int(e.get("pub", 0)) != 0
			var hide := false
			if loc == LOC_HAND:
				hide = not pub
			elif loc == LOC_EXTRA or loc == LOC_REMOVED or loc == LOC_MZONE or loc == LOC_SZONE:
				hide = (pos & POS_FACEDOWN) != 0 and not pub
			if hide:
				list[i] = {"code": 0, "pos": pos, "owner": int(e.get("owner", t)), "pub": 0}
	return out
