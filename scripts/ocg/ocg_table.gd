class_name OcgTable
extends RefCounted
## The duel screen's side of a duel run by the rules engine. The engine decides what is
## legal; this puts each of its questions in front of the player with the menus the duel
## screen already has, lets the placeholder CPU answer for the other side, and keeps the
## table (cards on the board, your hand, the piles) matching the mirror state.

signal answered(bytes)

const ME := 0
const AI := 1

var s                      # the duel scene
var d := OcgDuel.new()
var cpu := OcgCpu.new()
var me_cpu := OcgCpu.new() # (autoplay: the CPU plays your side too)
var req = null             # the idle / battle question open for the player right now
var acts := {}             # card uid -> [[label, answer], ...] for that question
var pick := {}             # an on-board pick in progress: {"cands", "cancel", "sig"}; "many": taps toggle
var want := {}             # what you already said with a drag or a tap, before the engine asks:
                           # "zone": [location, sequence], "target": card uid, "direct": true, "attacker": card uid
var aim := {}              # an attack being aimed: {"inst", "answer", "direct", "from", "held", "moved"}
var press := {}            # a press on one of your monsters in Main Phase 1 that may turn into a dragged attack
var zone_pick: Array = []  # the zones lit up for you to choose from
var _hand := [5, 5]
var _menu: Array = []
var level := 2             # how the opponent thinks: 0 the plain policy, 1 Normal, 2 Hard, 3 Extreme
var _turn_think := 0       # ms it has thought this turn
var _turn_seen := -1
var _turn_asks := 0
const TURN_BUDGET := [0, 6000, 14000, 28000]     # after this much thinking in one turn it hurries
const NAMES := ["Basic", "Normal", "Hard", "Extreme"]
var _log := "--ocg-log" in OS.get_cmdline_user_args()
## Dev (with --human-test): picks on the table and zone choices are made too, at random, so
## the code that runs when you point at cards and zones is exercised without anybody there.
var _auto_board := "--human-board" in OS.get_cmdline_user_args()
var _auto_steps := 0

func _auto(what: Callable) -> void:
	if _auto_board and s._human_test:
		s.get_tree().create_timer(0.04).timeout.connect(what)


func _init(scene) -> void:
	s = scene
	cpu.blind = false


## Every duel is run by the rules engine. False only when its library did not load on this
## computer: then no duel can start (the game says so instead).
static func wanted(_cfg: Dictionary) -> bool:
	return OcgCore.ensure_loaded()


## How the opponent thinks in this duel: Free Duel says it itself, everywhere else Settings does.
static func level_for(cfg: Dictionary) -> int:
	var lv := clampi(int(cfg.get("cpu_level", Settings.cpu_level)), 1, 3)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ocg-level="):
			lv = clampi(int(a.trim_prefix("--ocg-level=")), 0, 3)
	return lv


## Build the mirror (the two sides, no cards drawn yet). The engine itself starts in begin().
## setup: cards already in place (see OcgDuel.prepare). rules: see OcgDuel.start.
var rules := {}
var puzzle := false        # one turn to win: when it passes, the duel is lost
var speed_acts: Array = [] # Speed World 2's effects you could pay for right now: [[label, answer], ...]
var _destiny_seen := 0
var _destiny_ask := [false, false]    # that player said yes to the Destiny Draw: the next pick is the card
var _destiny_draw := [false, false]   # ... and their next draw is that card (it lands quietly)

## Replays (see Replays): `rec` is this duel being written down, `replay` a written-down duel being
## played back. What is written is what happened, step by step (OcgDuel.tape), so playing it back
## needs no engine and does not depend on the version of the rules. The answers are kept too: they
## say when somebody took a Destiny Draw, and they give playback its pauses.
var rec := {}
var replay := {}
## (0.73.0) An online duel (NetDuel): the host's table runs the engine and waits for the other side's
## answers over the line; the guest's table has no engine and plays the host's steps (see guest_loop).
var net = null
var net_guest := false
var _wait_token := 0
var _wait_coach := false
var _replay_at := 0
var ev_hash := 0           # every event of the duel, folded into one number (a replay must end on the same one)
var replay_broken := ""    # why playback stopped early, when it did

func prepare(my_list: Array, opp_list: Array, my_extra: Array, opp_extra: Array, me_name: String, opp_name: String, first: int, hand: Array, setup := {}, rules_in := {}) -> void:
	var seed := randi() & 0x7fffffff
	if not replay.is_empty():
		var rs: Dictionary = replay["setup"]
		my_list = rs["decks"][0]
		opp_list = rs["decks"][1]
		my_extra = rs["extras"][0]
		opp_extra = rs["extras"][1]
		me_name = str(rs["names"][0])
		opp_name = str(rs["names"][1])
		first = int(rs["first"])
		hand = rs["hand"]
		setup = rs["lay"]
		rules_in = rs["rules"]
		seed = int(rs["seed"])
		puzzle = false
		d.playback = true
	elif not puzzle and not s._autoplay:
		d.tape = []
		rec = {"tape": d.tape, "setup": {"decks": [my_list.duplicate(), opp_list.duplicate()], "extras": [my_extra.duplicate(), opp_extra.duplicate()],
			"names": [me_name, opp_name], "first": first, "hand": hand.duplicate(), "lay": setup.duplicate(true), "rules": rules_in.duplicate(true), "seed": seed},
			"answers": [], "cards": d.book, "cfg": Replays.clean_cfg(Router.duel_config)}
		# (who is at the table, said outright: a duel started without naming them still shows their picture in the list)
		rec["cfg"]["opponent"] = str(s._opp_key)
		rec["cfg"]["player_char"] = str(s._me_key)
	_hand = hand
	rules = rules_in
	d.prepare(s.state, [my_list, opp_list], [my_extra, opp_extra], [me_name, opp_name], first, seed, setup)
	if net != null:
		net.swap = d.swap
		d.net_out = net.out_step
	s._turn_finished.connect(_on_abort)


## (0.73.0) The guest's table: its own deck, and for the host's side only how many cards there are.
func prepare_guest(my_list: Array, my_extra: Array, host_main: int, host_extra: int, me_name: String, opp_name: String, first: int) -> void:
	net_guest = true
	var opp_list: Array = []
	opp_list.resize(host_main)
	opp_list.fill(0)
	var opp_extra: Array = []
	opp_extra.resize(host_extra)
	opp_extra.fill(0)
	d.blind = true
	d.check = false
	d.playback = true
	d.prepare(s.state, [my_list, opp_list], [my_extra, opp_extra], [me_name, opp_name], first, -1, {})
	s._turn_finished.connect(_on_abort)


## The guest's first step: the opening hands.
func begin_guest() -> Array:
	while true:
		var e = await net.next_entry()
		if e == null:
			return []
		if (e as Dictionary).has("note"):
			continue
		return d.feed(e)
	return []


## Start the engine with the Life Points the scene settled on. Returns the opening events.
func begin() -> Array:
	var st: DuelState = s.state
	if not replay.is_empty():
		# (the Life Points the duel started with, whatever this game's settings say now)
		for q in 2:
			st.players[q].lp = int(replay["lp"][q])
			s.hud.set_lp(q, int(replay["lp"][q]), 0)
	elif not rec.is_empty():
		rec["lp"] = [int(st.players[ME].lp), int(st.players[AI].lp)]
	if not d.start([st.players[ME].lp, st.players[AI].lp], _hand, rules):
		st._set_winner(DuelState.DRAW, "The new engine could not start.")
		return []
	if not replay.is_empty():
		var tp: Array = replay.get("tape", [])
		return d.feed(tp[0]) if not tp.is_empty() else []
	return d.advance()


func _on_abort() -> void:
	answered.emit(null)


func active() -> bool:
	return req != null and not s.busy and not s._finished and not s.state.is_over() and pick.is_empty()


# ------------------------------------------------------------------ the loop

func loop() -> void:
	if net_guest:
		await _guest_loop()
		return
	var seen_retries := 0
	resync()
	while not d.over and not s._finished and not s.state.is_over():
		var m = d.request
		if m == null:
			break
		var p := int(m["p"])
		var bytes = null
		if int(m["t"]) in [10, 11] and not s.board._orbs.is_empty():
			s.board.clear_orbs()
		if int(m["t"]) in [10, 11] and not s._materials.is_empty():
			# A free moment in a turn: nothing is in the middle of being Summoned, so no card is
			# left hanging in the air as a "material" (they used to float there until the turn ended).
			s._materials.clear()
			resync()
		var refused: bool = d.retries > seen_retries
		seen_retries = d.retries
		if net != null and Net._log:
			print("NETDBG host asks p%d t%d (entries %d)" % [p, int(m["t"]), net.entries.size()])
		if not replay.is_empty():
			bytes = await _replay_answer(m)
			if bytes == null:
				break
		elif refused and not (net != null and p == AI):
			push_warning("OCG: answer refused for message %d" % int(m["t"]))
			if d.retries > 12:
				s.state._set_winner(DuelState.DRAW, "The duel could not go on.")
				break
			bytes = (cpu if p == AI else me_cpu).decide(d, true)
		elif p == ME and not s._autoplay:
			bytes = await _ask(m)
		elif p == AI and net != null:
			if d.retries > 12:
				s.state._set_winner(DuelState.DRAW, "The duel could not go on.")
				break
			bytes = await _net_answer(m)
		elif p == AI:
			bytes = await _cpu_answer(m)
		else:
			bytes = me_cpu.decide(d)
		if s._finished or s.state.is_over() or bytes == null:
			break
		if not rec.is_empty():
			(rec["answers"] as Array).append((bytes as PackedByteArray).hex_encode())
		var events: Array
		if replay.is_empty():
			d.answer(bytes)
			events = d.advance()
		else:
			events = d.feed(replay["tape"][_replay_at])      # (answer n is followed by step n + 1)
		for e in events:
			if str(e["type"]) in ["why", "status", "log"]:
				continue      # (what DuelWhy says is not the duel: replays recorded before it still match)
			ev_hash = hash([ev_hash, str(e["type"]), int(e.get("player", -1)), int(e["card"].id) if e.get("card") != null and "id" in e["card"] else 0, int(e.get("lp", 0))])
		if _live:
			# A pick made card by card stays up between its steps, and goes when it is over.
			var nx = d.request
			if nx == null or int(nx["p"]) != ME or int(nx["t"]) != 26 or not events.is_empty() or s._autoplay:
				_live_end()
		if _log:
			var kinds: Array = []
			for e in events:
				kinds.append(e["type"])
			print("OCG turn ", s.state.turn, " asked ", int(m["t"]), " p", p, " -> ", kinds, " errors ", d.errors.size())
		var passed := false
		for e in events:
			if e["type"] == "turn":
				passed = true
			elif e["type"] == "draw" and _destiny_draw[int(e.get("player", 0))]:
				# The show already took this card off the Deck: it just lands in the hand.
				_destiny_draw[int(e["player"])] = false
				s._destiny_card = e["card"]
		if puzzle and passed and not s.state.is_over():
			# The one turn is over and they are still standing.
			var cut: Array = []
			for e in events:
				if e["type"] == "turn":
					break
				cut.append(e)
			await s._play(cut)
			resync()
			s.state._set_winner(AI, "The turn ended and they are still standing.")
			break
		await s._play(events)
		if passed:
			s._materials.clear()   # (materials of a Summon that never came)
		resync()
	req = null
	if _log or not d.errors.is_empty():
		print("OCG END winner ", s.state.winner, " turn ", s.state.turn, " errors ", d.errors.slice(0, 8))
	if not s._autoplay or "--report" in OS.get_cmdline_user_args():
		var kind := "puzzle" if puzzle else ("turbo duel" if d.turbo else "duel")
		OcgReport.duel(kind + " (engine)", str(s.state.players[AI].name), level, int(s.state.winner), int(s.state.turn), str(s.state.win_reason), d.errors)
	d.close()


## (0.73.0) The guest's side of an online duel. There is no engine here: the host's steps come in
## and are played as they come (the same way a replay is), and when a question is yours it is asked
## here and the answer goes back. The host's questions only say that it is their turn to decide.
func _guest_loop() -> void:
	var seen_retries := 0
	resync()
	while not s._finished and not s.state.is_over():
		var m = d.request
		if Net._log:
			print("NETDBG guest req ", "none" if m == null else "p%d t%d" % [int(m["p"]), int(m["t"])], " played ", net._played, "/", net.inbox.size())
		if m != null and int(m["p"]) == ME and not d.over:
			if d.retries > seen_retries:
				seen_retries = d.retries
				if not s._autoplay:
					Router.toast(Loc.t("That can't be done right now. Choose again."))
			var bytes = me_cpu.decide(d) if s._autoplay else await _ask(m)
			if s._finished or s.state.is_over() or bytes == null:
				break
			net.send_answer(bytes)
		var token := randi()
		_wait_token = token
		if m == null or int(m["p"]) != ME:
			s.get_tree().create_timer(1.2).timeout.connect(func():
				if _wait_token == token and net.waiting_entries() == 0 and not s._finished:
					_wait_coach = true
					s.hud.set_coach(Loc.t("%s is thinking...") % str(s.state.players[AI].name)))
		var e = await net.next_entry()
		_wait_token = 0
		if _wait_coach:
			_wait_coach = false
			s.hud.set_coach("")
		if e == null:
			break
		if (e as Dictionary).has("note"):
			var nt: Dictionary = e["note"]
			if nt.has("destiny"):
				await _destiny_show(AI, 0)
			continue
		var events: Array = d.feed(e)
		if _live:
			var nx = d.request
			if nx == null or int(nx["p"]) != ME or int(nx["t"]) != 26 or not events.is_empty() or s._autoplay:
				_live_end()
		for ev in events:
			if ev["type"] == "turn":
				s._materials.clear()
			elif ev["type"] == "draw" and _destiny_draw[int(ev.get("player", 0))]:
				_destiny_draw[int(ev["player"])] = false
				s._destiny_card = ev["card"]
		await s._play(events)
		resync()
	req = null
	print("NET guest END winner ", s.state.winner, " turn ", s.state.turn)


## (0.73.0) The other side's answer, over the line. Their Destiny Draw is shown here face-down, the
## way the CPU's is.
func _net_answer(m: Dictionary):
	var token := randi()
	_wait_token = token
	s.get_tree().create_timer(1.2).timeout.connect(func():
		if _wait_token == token and net.want >= 0:
			_wait_coach = true
			s.hud.set_coach(Loc.t("%s is thinking...") % str(s.state.players[AI].name)))
	var bytes = await net.wait_answer()
	_wait_token = 0
	if _wait_coach:
		_wait_coach = false
		s.hud.set_coach("")
	if bytes == null:
		return null
	var p := AI
	var t := int(m["t"])
	if _is_destiny_offer(m):
		_destiny_ask[p] = (bytes as PackedByteArray).size() >= 4 and (bytes as PackedByteArray).decode_s32(0) == 1
	elif _destiny_ask[p] and t == 15:
		_destiny_ask[p] = false
		await _destiny_show(p, 0)
	return bytes


## The next answer of a duel being played back, with the moments a live duel gives it: a breath
## before each decision in the open, and the Destiny Draw show. null when the recording is over.
func _replay_answer(m: Dictionary):
	var answers: Array = replay["answers"]
	if _replay_at >= answers.size() or _replay_at + 1 >= (replay["tape"] as Array).size():
		return null
	var bytes: PackedByteArray = str(answers[_replay_at]).hex_decode()
	_replay_at += 1
	var p := int(m["p"])
	var t := int(m["t"])
	if _is_destiny_offer(m):
		_destiny_ask[p] = bytes.size() >= 4 and bytes.decode_s32(0) == 1
		if _destiny_ask[p] and p == ME and not s._autoplay:
			s._lumen("destiny")
	elif _destiny_ask[p] and t == 15:
		_destiny_ask[p] = false
		var code := 0
		var list: Array = m.get("cards", [])
		# (the pick is written as: kind, how many, then the index)
		if p == ME and bytes.size() >= 12:
			var idx := bytes.decode_s32(8)
			if idx >= 0 and idx < list.size():
				code = int(list[idx]["code"])
		await _destiny_show(p, code)
	elif t in [10, 11] and not s._autoplay:
		await s._ai_wait(0.45 if p == ME else 0.35)
	elif t == 16 and not s._autoplay and bytes.size() >= 4 and bytes.decode_s32(0) >= 0:
		await s._ai_wait(0.3)
	return bytes


## The opponent's answer. From Normal up it thinks in the engine (on its own thread, so the
## screen keeps moving): it tries its options on copies of the duel and takes the best.
func _cpu_answer(m: Dictionary) -> PackedByteArray:
	if s.state.turn != _turn_seen:
		_turn_seen = s.state.turn
		_turn_think = 0
		_turn_asks = 0
	_turn_asks += 1
	if _is_destiny_offer(m):
		_destiny_ask[AI] = true
		return OcgDuel.i32(1)
	var command: bool = int(m["t"]) in [10, 11]
	var reach: bool = _destiny_ask[AI] and int(m["t"]) == 15
	_destiny_ask[AI] = false
	if level <= 0 or _turn_asks > 260:
		# (a turn that will not end: the plainest answers close it)
		if command and not s._autoplay:
			await s._ai_wait(0.35)
		if reach:
			await _destiny_show(AI, 0)
		return cpu.decide(d, _turn_asks > 260)
	var cap := 0
	var lv_now := level
	if _turn_think > int(TURN_BUDGET[level]):
		cap = 350
	if _turn_asks > 140:
		# A very long turn: it still thinks (and keeps its common sense), only quicker. Before 0.76.0
		# it fell back to a placeholder that used every card it could, on anything.
		lv_now = 1
		cap = 200
	var t0 := Time.get_ticks_msec()
	OcgCore.think_start(d.handle, lv_now, cap, randi())
	var shown := false
	while true:
		await s.get_tree().process_frame
		var r := OcgCore.think_poll(d.handle)
		if not r.is_empty():
			_turn_think += int(r["ms"])
			if _log and int(r["cands"]) > 1:
				print("OCG think: ", int(r["cands"]), " answers, ", int(r["sims"]), " tries, ", int(r["ms"]), " ms")
			if shown:
				s.hud.set_coach("")
			var ans: PackedByteArray = r["answer"]
			if ans.is_empty():
				break
			# A command that came at once still gets a beat, so its plays do not blur together.
			if command and not s._autoplay and Time.get_ticks_msec() - t0 < 300:
				await s._ai_wait(0.3)
			if reach:
				await _destiny_show(AI, 0)
			return ans
		if not shown and Time.get_ticks_msec() - t0 > 900:
			shown = true
			s.hud.set_coach(Loc.t("%s is thinking...") % str(s.state.players[AI].name))
		if Time.get_ticks_msec() - t0 > 20000 or s._finished:
			break
	if shown:
		s.hud.set_coach("")
	if reach:
		await _destiny_show(AI, 0)
	return cpu.decide(d)


# ------------------------------------------------------------------ Destiny Draw

func _is_destiny_offer(m: Dictionary) -> bool:
	return int(m["t"]) == 13 and int(m["desc"]) == (OcgCore.DESTINY << 20)


## The moment itself: the duelist reaches for the card. (code 0: it stays face-down, their card.)
func _destiny_show(p: int, code: int) -> void:
	if net != null and not net_guest and p == ME:
		net.note({"destiny": 1})      # (the guest's screen shows it too, face-down)
	var st: DuelState = s.state
	st.destiny_used[p] = true
	_destiny_draw[p] = true
	print("DESTINY ", p, " ", OcgCore.card_name(code) if code > 0 else "?")
	s._update_counts()
	if s._autoplay or (s._human_test and not "--destiny-show" in OS.get_cmdline_user_args()):
		return
	s.hud.hide_actions()
	s.board.duelist_body(p, "draw")
	await s.DestinyShow.play(s.hud, {
		"side": p, "key": str(s.hud.portrait_keys[p]), "who": str(st.players[p].name),
		"color": UITheme.ACCENT if p == ME else Comic.RED,
		"back": Cards.duel_back(p), "face": Cards.get_face(code) if code > 0 else null, "name": OcgCore.card_name(code) if code > 0 else "",
		"spirit": LumenSpirit.portrait(s) if (p == ME and s._me_key == "player" and LumenBubble.with_you()) else null,
	})
	if p == AI:
		s.hud.feed(p, "★", Loc.t("Destiny Draw: chose the card they drew"))
		s._lumen("their_destiny")


## You said yes: every different card in your Deck, best first. Returns the engine's answer.
func _ask_destiny_card(m: Dictionary):
	var list: Array = m["cards"]
	var seen := {}
	var opts: Array = []
	var index := {}
	for i in list.size():
		var code := int(list[i]["code"])
		if seen.has(code):
			continue
		seen[code] = true
		var c = _temp(code, ME)
		opts.append(c)
		index[c.uid] = i
	var rank := func(c) -> int: return 0 if c.is_monster() else (1 if c.is_spell() else 2)
	opts.sort_custom(func(a, b): return rank.call(a) < rank.call(b) if rank.call(a) != rank.call(b) else (a.atk() > b.atk() if a.is_monster() and a.atk() != b.atk() else a.cname() < b.cname()))
	var got = await s.hud.ask_pick(Loc.t("Destiny Draw: choose the card you draw"), opts, "Draw this card", "")
	if got == null:
		got = opts[0]
	await _destiny_show(ME, got.id)
	return OcgDuel.pick([int(index[got.uid])])


# ------------------------------------------------------------------ questions for the player

func _name(code: int) -> String:
	return str(CardData.get_card(code).get("name", "?"))


func _hint_text(p: int, fallback: String) -> String:
	var t := OcgCore.desc(int(d.hints.get(p, 0)))
	d.hints.erase(p)
	return t if t != "" else fallback


func _temp(code: int, owner: int):
	return d._new_card(code, owner)


func _hidden(cards: Array) -> Array:
	var out: Array = []
	var foe: DuelState.PlayerState = s.state.players[AI]
	for c in cards:
		if c == null:
			continue
		if foe.hand.has(c) or ((foe.field.has(c) or foe.spells.has(c) or foe.field_spell == c) and not c.face_up):
			out.append(c)
	return out


func _labels(cards: Array) -> Dictionary:
	var out := {}
	for c in cards:
		if c != null:
			out[c.uid] = s._where(c)
	return out


func _on_field(c) -> bool:
	for q in 2:
		var ps: DuelState.PlayerState = s.state.players[q]
		if ps.field.has(c) or ps.spells.has(c) or ps.field_spell == c:
			return true
	return false


func _ask(m: Dictionary):
	var t := int(m["t"])
	var was: bool = s._flow
	match t:
		10, 11:
			return await _ask_command(m)
		16:
			return await _ask_chain(m)
	s._flow = true
	var out = null
	match t:
		12:
			var cd: Dictionary = m["card"]
			var dv := int(m["desc"])
			var text := ""
			var nm := _name(int(cd["code"]))
			if dv == 0 or dv == 200 or dv == 221:
				# (the engine's own line for this has two blanks, card and place, in an order that
				# changes with the language: it came out as "the effect of []")
				text = Loc.t("Activate the effect of %s?") % nm
			elif (dv >> 20) == 0:
				text = OcgCore.fill(OcgCore.sys(dv), nm)
				if text.contains("[]") or text.contains("%ls") or text.strip_edges() == "":
					text = Loc.t("Activate the effect of %s?") % nm
			else:
				text = nm + ": " + OcgCore.desc(dv) + "?"
			var src = d.card_at(int(cd["con"]), int(cd["loc"]), int(cd["seq"]), int(cd.get("pos", 0)))
			out = OcgDuel.i32(1 if await s.hud.ask_choice(text, [Loc.t("Yes"), Loc.t("No")], src) == 0 else 0)
		13:
			if _is_destiny_offer(m):
				var yes := true
				if "--destiny-debug" in OS.get_cmdline_user_args():
					# dev: say no to the first three offers, to see that it keeps being offered
					_destiny_seen += 1
					yes = _destiny_seen > 3
					print("DESTINY OFFER %d on turn %d, LP %d vs %d, answered %s" % [_destiny_seen, int(s.state.turn), int(s.state.players[ME].lp), int(s.state.players[AI].lp), "yes" if yes else "no"])
				elif not s._human_test:
					s._lumen("destiny")
					yes = await s.hud.ask_destiny()
				_destiny_ask[ME] = yes
				out = OcgDuel.i32(1 if yes else 0)
			elif int(m["desc"]) == 31 and (want.has("target") or want.has("direct")):
				# "Attack directly?" You already said which, when you aimed the attack.
				out = OcgDuel.i32(1 if want.has("direct") else 0)
				want.erase("direct")
			else:
				var text2 := OcgCore.desc(int(m["desc"]))
				out = OcgDuel.i32(1 if await s.hud.ask_choice(text2 if text2 != "" else Loc.t("Do it?"), [Loc.t("Yes"), Loc.t("No")]) == 0 else 0)
		14:
			var opts: Array = []
			for o in m["opts"]:
				var line := OcgCore.desc(int(o))
				opts.append(line if line != "" else Loc.t("Option %d") % (opts.size() + 1))
			out = OcgDuel.i32(await s.hud.ask_choice(_hint_text(ME, OcgCore.sys(555)), opts))
		15:
			if _destiny_ask[ME]:
				_destiny_ask[ME] = false
				d.hints.erase(ME)
				out = await _ask_destiny_card(m)
			else:
				out = await _ask_cards(m)
		20:
			out = await _ask_cards(m, true)
		26:
			out = await _ask_unselect(m)
		19:
			out = await _ask_position(m)
		23:
			out = await _ask_sum(m)
		140, 141:
			out = await _ask_bits(m)
		142:
			out = await _ask_announce(m)
		143:
			var nums: Array = []
			for o in m["opts"]:
				nums.append(str(int(o)))
			out = OcgDuel.i32(await s.hud.ask_choice(_hint_text(ME, OcgCore.sys(565)), nums))
		18:
			out = await _ask_place(m)
		_:
			# Sort orders and the like: taken care of for you.
			out = me_cpu.decide(d)
	s._flow = was
	return out


## "Declare 1 card name." When the card allows only a few names, those; otherwise every different
## card your opponent has shown this duel, then your own (a card nobody has seen cannot be told
## apart by looking at the table anyway).
func _ask_announce(m: Dictionary):
	# "Declare 1 card name". Any card the question allows can be named, so the dialog searches
	# every card in the game; the ones seen in this duel are offered first.
	var opts: Array = m["opts"]
	var seen: Array = []
	var st: DuelState = s.state
	var theirs: DuelState.PlayerState = st.players[AI]
	var mine: DuelState.PlayerState = st.players[ME]
	var known: Array = theirs.gy + theirs.banished + theirs.monsters() + theirs.set_cards() + ([theirs.field_spell] if theirs.field_spell != null else [])
	for c in known:
		if c != null and c.face_up and c.id > 0 and not seen.has(c.id):
			seen.append(c.id)
	var own: Array = []
	for c in mine.hand + mine.deck + mine.gy + mine.banished + mine.monsters() + mine.set_cards():
		if c != null and c.id > 0 and not seen.has(c.id) and not own.has(c.id):
			own.append(c.id)
	own.sort_custom(func(a, b): return OcgCore.card_name(a) < OcgCore.card_name(b))
	var quick: Array = []
	for id in seen + own:
		if OcgCore.announce_ok(opts, int(id)):
			quick.append([int(id), OcgCore.card_name(int(id))])
	if _name_list.is_empty():
		for id in Collection.all_cards():
			_name_list.append([int(id), OcgCore.card_name(int(id))])
		_name_list.sort_custom(func(a, b): return str(a[1]) < str(b[1]))
	var all: Array = _name_list.filter(func(r): return OcgCore.announce_ok(opts, int(r[0])))
	if quick.is_empty() and all.is_empty():
		return me_cpu.decide(d)
	var text := _hint_text(ME, OcgCore.sys(564))
	var got: int = await s.hud.ask_name(text if text != "" else Loc.t("Declare 1 card name"), quick, all)
	if got <= 0:
		got = int((quick if not quick.is_empty() else all)[0][0])
	return OcgDuel.i32(got)

var _name_list: Array = []


func _ask_cards(m: Dictionary, tribute := false):
	var list: Array = m["cards"]
	var cards := d.cards_of(list)
	if "--pick-debug" in OS.get_cmdline_user_args():
		var codes: Array = []
		var uids: Array = []
		for i in list.size():
			codes.append("%d@%d/%d" % [int(list[i]["code"]), int(list[i]["loc"]), int(list[i]["seq"])])
			uids.append(cards[i].uid if cards[i] != null else -1)
		print("PICK ", codes, " -> ", uids)
	for i in cards.size():
		if cards[i] == null:
			cards[i] = _temp(int(list[i]["code"]), int(list[i]["con"]) if int(list[i]["con"]) < 2 else ME)
	var lo := int(m["min"])
	var hi := mini(int(m["max"]), cards.size())
	var can_cancel := int(m["cancel"]) != 0
	var text := _hint_text(ME, OcgCore.sys(500) if tribute else OcgCore.sys(560))
	if tribute:
		# (said plainly, with the number when there is one)
		text = Loc.t("Choose the monster to Tribute") if hi <= 1 else (Loc.t("Choose %d monsters to Tribute") % lo if lo == hi else Loc.t("Choose the monsters to Tribute"))
	if want.has("target") or want.has("direct"):
		# The target of an attack you aimed: it is already chosen.
		var uid := int(want.get("target", -1))
		want.erase("target")
		want.erase("direct")
		for i in cards.size():
			if cards[i].uid == uid:
				return OcgDuel.pick([i])
		Router.toast(Loc.t("That one cannot be attacked. Choose another target."), 2.4)
	var all_field: bool = not s._human_test or _auto_board
	for c in cards:
		if not _on_field(c):
			all_field = false
			break
	# One card: point at it on the table, or tap it in the box.
	if hi <= 1 and lo <= 1:
		var got = null
		if all_field:
			got = await _pick_on_board(cards, text, can_cancel or lo == 0, "TRIBUTE" if tribute else "SELECT")
		else:
			var res = await s.hud.ask_cards(text, cards, {"min": 1, "max": 1, "cancel": Loc.t("Cancel") if can_cancel else (Loc.t("None") if lo == 0 else ""), "hidden": _hidden(cards), "labels": _labels(cards)})
			if res is Array and not (res as Array).is_empty():
				got = res[0]
		if got == null:
			if can_cancel:
				return OcgDuel.i32(-1)
			return OcgDuel.pick([] if lo == 0 else [0])
		return OcgDuel.pick([cards.find(got)])
	# Several: tap them all, then Confirm.
	var weigh := func(chosen: Array) -> int:
		var w := 0
		for c in chosen:
			w += maxi(1, int(list[cards.find(c)].get("param", 1))) if tribute else 1
		return w
	var valid := func(chosen: Array) -> bool:
		return chosen.size() <= hi and int(weigh.call(chosen)) >= lo and (not tribute or chosen.size() >= 1 or lo == 0)
	var info := func(chosen: Array) -> String:
		if tribute and int(weigh.call(chosen)) != chosen.size():
			return Loc.t("Counts as %d Tributes") % int(weigh.call(chosen))
		return ""
	var count := [lo, hi]
	var picked = null
	if all_field:
		picked = await _pick_many_on_board(cards, text, count, valid, can_cancel, "TRIBUTE" if tribute else "SELECT")
	else:
		picked = await s.hud.ask_cards(text, cards, {"min": lo, "max": hi, "valid": valid, "info": info, "cancel": Loc.t("Cancel") if can_cancel else "", "hidden": _hidden(cards), "labels": _labels(cards)})
	if picked == null:
		if can_cancel:
			return OcgDuel.i32(-1)
		# It cannot be skipped: the first ones that fit are taken.
		picked = []
		for c in cards:
			if int(weigh.call(picked)) >= lo:
				break
			(picked as Array).append(c)
	var idx: Array = []
	for c in picked:
		idx.append(cards.find(c))
	return OcgDuel.pick(idx)


var _live := false

func _live_end() -> void:
	_live = false
	if pick.is_empty():
		s.board.clear_picks()
		s.hud.hide_prompt()
	s.hud.close_cards()


## Materials the rules check one card at a time (Synchro, Xyz, Fusion): every tap goes to the
## engine, which answers with what may still be added. On your side it is one pick: the cards
## stay lit (or the box stays open) until you confirm.
func _ask_unselect(m: Dictionary):
	var list: Array = m["cards"]
	var uns: Array = m["unsel"]
	var cards := d.cards_of(list)
	for i in cards.size():
		if cards[i] == null:
			cards[i] = _temp(int(list[i]["code"]), ME)
	var chosen := d.cards_of(uns)
	for i in chosen.size():
		if chosen[i] == null:
			chosen[i] = _temp(int(uns[i]["code"]), ME)
	var text := _hint_text(ME, OcgCore.sys(560))
	var finish := int(m["finish"]) != 0
	var can_cancel := int(m["cancel"]) != 0
	if cards.is_empty() and chosen.is_empty():
		return OcgDuel.i32(-1)
	var all_field: bool = not s._human_test or _auto_board
	for c in cards + chosen:
		if not _on_field(c):
			all_field = false
			break
	var got = null
	if int(m["max"]) <= 1 and chosen.is_empty():
		# One card (a search, a single material): the same as any pick of one. Tap it and Confirm,
		# or point at it on the table. It is not sent on the first tap, so a slip can be taken back.
		_live_end()
		var skip: bool = can_cancel or finish
		if all_field:
			got = await _pick_on_board(cards, text, skip, "SELECT")
		else:
			var res = await s.hud.ask_cards(text, cards, {"min": 1, "max": 1, "cancel": Loc.t("Cancel") if skip else "", "hidden": _hidden(cards), "labels": _labels(cards)})
			if res is Array and not (res as Array).is_empty():
				got = res[0]
		if got == null:
			return OcgDuel.i32(-1) if skip else OcgDuel.pick_one(0)
		return OcgDuel.pick_one(cards.find(got))
	_live = true
	if all_field:
		s.hud.close_cards()
		got = await _pick_live_on_board(cards, chosen, text, finish, can_cancel)
	else:
		var labels := _labels(cards + chosen)
		got = await s.hud.ask_cards(text, cards, {"live": true, "chosen": chosen, "finish": finish,
				"cancel": Loc.t("Cancel") if (can_cancel and not finish) else "", "hidden": _hidden(cards), "labels": labels})
	if got == null or (got is String):
		return OcgDuel.i32(-1) if (finish or can_cancel) else OcgDuel.pick_one(0)
	var gi := cards.find(got)
	if gi == -1:
		gi = cards.size() + chosen.find(got)
	return OcgDuel.pick_one(gi)


func _ask_position(m: Dictionary):
	var ok := int(m["positions"])
	var bits: Array = []
	for b in [1, 4, 8, 2]:
		if ok & b:
			bits.append(b)
	if bits.size() == 1:
		return OcgDuel.i32(bits[0])
	var c = _temp(int(m["code"]), ME)
	var i: int = await s.hud.ask_position(c, bits)
	return OcgDuel.i32(bits[clampi(i, 0, bits.size() - 1)])


## Zone of your choice. A card you dragged goes where you dropped it. A monster played from its
## menu: the free zones light up and you tap one (Esc or "Place it for me": the middle first).
## Spell and Trap Cards played from the menu are placed for you.
func _ask_place(m: Dictionary):
	var said = want.get("zone")
	want.erase("zone")
	if int(m["count"]) > 1 or (s._human_test and not _auto_board):
		return me_cpu.decide(d)
	var can: Array = []
	var monster := false
	for o in d.place_options(m):
		if int(o[2]) < 5:
			can.append(o)
			if int(o[1]) == OcgCore.LOC_MZONE:
				monster = true
	if can.size() <= 1:
		return me_cpu.decide(d)
	if said != null:
		for o in can:
			if int(o[0]) == ME and int(o[1]) == int(said[0]) and int(o[2]) == int(said[1]):
				return d.place([o])
	if not monster:
		return me_cpu.decide(d)
	var code := int(d.hints.get(ME, 0))
	d.hints.erase(ME)
	var nm := str(CardData.get_card(code).get("name", "")) if code > 10000 else ""
	var theirs := int(can[0][0]) != ME
	var text := Loc.t("Choose one of their zones") if theirs else Loc.t("Choose a zone")
	if nm != "":
		text = (Loc.t("Choose one of their zones for %s") if theirs else Loc.t("Choose a zone for %s")) % nm
	zone_pick = can
	s.board.show_zone_picks(can, "HERE")
	s.hud.show_prompt(text, false, "", "Place it for me")
	_auto(func(): _zone_picked.emit(can.pick_random() if randf() < 0.85 else null))
	var got = await _zone_picked
	zone_pick = []
	s.board.show_zone_picks([])
	s.hud.hide_prompt()
	if got == null:
		return me_cpu.decide(d)
	return d.place([got])

signal _zone_picked(zone)


func _ask_sum(m: Dictionary):
	# Values that have to add up (a Ritual's Tributes, some Synchro picks): one pick, with the
	# total so far in view. Confirm lights up when it fits.
	var list: Array = m["cards"]
	var cards := d.cards_of(list)
	if "--pick-debug" in OS.get_cmdline_user_args():
		var codes: Array = []
		var uids: Array = []
		for i in list.size():
			codes.append("%d@%d/%d" % [int(list[i]["code"]), int(list[i]["loc"]), int(list[i]["seq"])])
			uids.append(cards[i].uid if cards[i] != null else -1)
		print("PICK ", codes, " -> ", uids)
	for i in cards.size():
		if cards[i] == null:
			cards[i] = _temp(int(list[i]["code"]), ME)
	var text := _hint_text(ME, OcgCore.sys(560))
	var acc := int(m["acc"])
	var base := 0
	for c in m["must"]:
		base += int(c["param"]) & 0xffff
	var idx_of := func(chosen: Array) -> Array:
		var out: Array = []
		for c in chosen:
			out.append(cards.find(c))
		return out
	var valid := func(chosen: Array) -> bool:
		return _sum_ok(m, idx_of.call(chosen))
	var info := func(chosen: Array) -> String:
		var total := base
		for c in chosen:
			total += int(list[cards.find(c)]["param"]) & 0xffff
		return Loc.t("Total so far: %d   ·   needed: %d") % [total, acc] if int(m["mode"]) == 0 else Loc.t("Total so far: %d   ·   needed: at least %d") % [total, acc]
	var all_field: bool = not s._human_test or _auto_board
	for c in cards:
		if not _on_field(c):
			all_field = false
			break
	var hi := cards.size() if int(m["mode"]) != 0 else mini(maxi(1, int(m["max"])), cards.size())
	var picked = null
	if all_field:
		picked = await _pick_many_on_board(cards, text, [1, hi], valid, false, "SELECT", info)
	else:
		picked = await s.hud.ask_cards(text, cards, {"min": 1, "max": hi, "valid": valid, "info": info, "hidden": _hidden(cards), "labels": _labels(cards)})
	if picked == null or not _sum_ok(m, idx_of.call(picked)):
		return me_cpu._sum(m)
	return OcgDuel.pick(idx_of.call(picked))


func _sum_ok(m: Dictionary, picked: Array) -> bool:
	if picked.is_empty():
		return false
	var params: Array = []
	for c in m["must"]:
		params.append(int(c["param"]))
	for i in picked:
		params.append(int(m["cards"][i]["param"]))
	var acc := int(m["acc"])
	if int(m["mode"]) == 0:
		return picked.size() >= int(m["min"]) and picked.size() <= int(m["max"]) and me_cpu._sum_exact(params, 0, acc)
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
	return most >= acc and total - least < acc


func _ask_bits(m: Dictionary):
	var avail := int(m["avail"])
	var race := int(m["t"]) == 140
	var names: Array = []
	var bits: Array = []
	var words: Array = OcgCore.RACES if race else ["EARTH", "WATER", "FIRE", "WIND", "LIGHT", "DARK", "DIVINE"]
	for i in words.size():
		if avail & (1 << i):
			bits.append(1 << i)
			names.append(Loc.t(str(words[i])))
	var out := 0
	for n in maxi(1, int(m["count"])):
		if names.is_empty():
			break
		var i: int = await s.hud.ask_choice(OcgCore.sys(563 if race else 562), names)
		i = clampi(i, 0, names.size() - 1)
		out |= int(bits[i])
		bits.remove_at(i)
		names.remove_at(i)
	var b := PackedByteArray()
	if race:
		b.resize(8)
		b.encode_u64(0, out)
	else:
		b.resize(4)
		b.encode_u32(0, out)
	return b


## Cards that only work as a link of a chain you build yourself ("Activate only as Chain Link 4 or
## higher"). With "Ask me at every chance" off, the table passes for you whenever nothing calls for
## an answer, the way EDOPro does: after your own Jar of Greed nobody asked "anything on top of it?",
## so Chain Link 4 could never be reached and Accumulated Fortune looked like it could not be
## activated. While you have one of these Set (or in your hand, for a Quick-Play Spell), you are
## asked at every link of a chain, whatever the switch says. (0.63.1)
const CHAIN_CARDS := ["Accumulated Fortune", "Chain Strike"]

func _holds_chain_card() -> bool:
	var ps: DuelState.PlayerState = s.state.players[ME]
	for c in ps.spells:
		if c != null and not c.face_up and c.cname() in CHAIN_CARDS:
			return true
	for c in ps.hand:
		if c != null and c.cname() in CHAIN_CARDS:
			return true
	return false


## "Activate a card or effect?" Only asked when there is a reason to (the engine marks the
## moments your cards are meant for); otherwise it passes for you, as EDOPro does.
func _ask_chain(m: Dictionary):
	var ch: Array = m["chains"]
	if not d.chain_cards.is_empty() and not s._autoplay:
		# A line in the game's log for every link of a chain: what is in it and what you could add.
		# (So a report like "it would not let me activate X" can be checked against what happened.)
		var inside: Array = []
		for cc in d.chain_cards:
			inside.append(cc.cname() if cc != null else "?")
		var can: Array = []
		for e in ch:
			can.append(_name(int(e["code"])))
		print("CHAIN %d links %s | you may add %s" % [inside.size(), str(inside), str(can)])
	if ch.is_empty():
		return OcgDuel.i32(-1)
	var forced := int(m["forced"]) != 0
	if forced:
		# Something must happen now (in the End Phase: Swords of Revealing Light counts its turn).
		# The engine lists it together with the cards you could also activate (your Set Waboku),
		# and the box looked like an offer to activate all of them, every End Phase. What must
		# happen is done for you, in the order given, as EDOPro does by default; your Set cards
		# are then offered the usual way, when there is a reason to.
		if ch.size() == 1:
			return OcgDuel.i32(0)
		var listed := d.cards_of(ch)
		for i in ch.size():
			var lc = listed[i]
			if int(ch[i].get("mode", 0)) != 0 or (lc != null and lc.face_up and _on_field(lc)):
				return OcgDuel.i32(i)
	if not forced and int(m["spe"]) == 0 and not s.hud.phase_prompts:
		# (Unless you are building a chain for a card that needs one: see ChainAsk.)
		if d.chain_cards.is_empty() or not _holds_chain_card():
			return OcgDuel.i32(-1)
	var was: bool = s._flow
	s._flow = true
	var cards := d.cards_of(ch)
	var uniq: Array = []
	for i in cards.size():
		if cards[i] == null:
			cards[i] = _temp(int(ch[i]["code"]), ME)
		if not uniq.has(cards[i]):
			uniq.append(cards[i])
	var text := OcgCore.sys(203)
	var last = d.chain_cards.back() if not d.chain_cards.is_empty() else null
	if last != null and last.owner == AI:
		text = Loc.t("%s was activated. Respond?") % last.cname()
	if forced:
		text = OcgCore.sys(206) if OcgCore.sys(206) != "" else text
	var res = await s.hud.ask_cards(text, uniq, {"min": 1, "max": 1, "confirm": Loc.t("Activate"), "cancel": "" if forced else Loc.t("Don't activate"),
			"tint": Color("ff4dd2"), "labels": _labels(uniq)})
	s._flow = was
	var got = res[0] if (res is Array and not (res as Array).is_empty()) else null
	if got == null:
		return OcgDuel.i32(0 if forced else -1)
	var idxs: Array = []
	for i in cards.size():
		if cards[i] == got:
			idxs.append(i)
	if idxs.size() == 1:
		return OcgDuel.i32(idxs[0])
	var words: Array = []
	for i in idxs:
		var line := OcgCore.desc(int(ch[i]["desc"]))
		words.append(line if line != "" else Loc.t("Effect %d") % (words.size() + 1))
	s._flow = true
	var wi: int = await s.hud.ask_choice(Loc.t("%s: which effect?") % got.cname(), words, got)
	s._flow = was
	return OcgDuel.i32(idxs[clampi(wi, 0, idxs.size() - 1)])


# ------------------------------------------------------------------ your Main Phase and Battle Phase

func _ask_command(m: Dictionary):
	req = m
	acts = {}
	speed_acts = []
	var battle := int(m["t"]) == 10
	if d.turbo:
		var ch: Array = m["chains"]
		for i in ch.size():
			if int(ch[i]["code"]) == OcgCore.SPEED_WORLD:
				speed_acts.append([OcgCore.desc(int(ch[i]["desc"])), OcgDuel.i32((i << 16) | (0 if battle else 5))])
	if battle:
		_add_all(m["chains"], 0, "act")
		_add_all(m["attacks"], 1, "attack")
	else:
		_add_all(m["summon"], 0, "summon")
		_add_all(m["spsummon"], 1, "special")
		_add_all(m["repos"], 2, "repos")
		# (Activate comes before Set: a Spell in your hand is usually there to be played.)
		_add_all(m["chains"], 5, "act")
		_add_all(m["mset"], 3, "mset")
		_add_all(m["sset"], 4, "sset")
	s._turn_done = false
	# An attack dragged out of Main Phase 1: the Battle Phase has started, now it is declared.
	var said := want
	want = {}
	if battle and said.has("attacker"):
		for a in acts.get(int(said["attacker"]), []):
			if str(a[2]) == "attack":
				for k in ["target", "direct"]:
					if said.has(k):
						want[k] = said[k]
				req = null
				acts = {}
				return a[1]
		Router.toast(Loc.t("That monster cannot attack right now."), 2.2)
	refresh()
	_ux_demo()
	if s._human_test:
		# Dev: nobody at the table. The commands are picked for you; the questions go through the real menus.
		await s._ai_wait(0.15)
		req = null
		acts = {}
		return me_cpu.decide(d)
	var bytes = await answered
	req = null
	acts = {}
	speed_acts = []
	pick = {}
	press = {}
	if not aim.is_empty():
		_aim_stop()
	s.mode = ""
	s.hud.hide_actions()
	s.hud.hide_prompt()
	s.hud.hide_extra()
	s.board.clear_picks()
	refresh()
	return bytes


## One entry per thing a card can do right now: [the word, the answer, what kind of move, a
## second line for the menu ("" = the usual one for that kind), can it attack directly].
func _add_all(list: Array, kind: int, what: String) -> void:
	var cards := d.cards_of(list)
	for i in list.size():
		var c = cards[i]
		if c == null:
			continue
		var label := ""
		var hint := ""
		var k := what
		match what:
			"summon":
				label = Loc.t("Summon")
				if c.level() >= 5:
					label = Loc.t("Tribute Summon")
					k = "tribute"
			"special": label = Loc.t("Special Summon")
			"mset":
				label = Loc.t("Set")
				if c.level() >= 5:
					hint = "Face-down. It needs Tributes too"
			"sset": label = Loc.t("Set")
			"attack": label = Loc.t("Attack")
			"repos":
				label = Loc.t("Flip Summon") if not c.face_up else (Loc.t("To Defense Position") if c.attack_pos else Loc.t("To Attack Position"))
				if not c.face_up:
					k = "flipsummon"
			"act":
				var line := OcgCore.desc(int(list[i]["desc"]))
				var plain: bool = not c.is_monster() and (s.state.players[ME].hand.has(c) or not c.face_up)
				label = Loc.t("Activate") if not c.is_monster() else Loc.t("Use its effect")
				if not plain and line != "":
					hint = line
		if not acts.has(c.uid):
			acts[c.uid] = []
		(acts[c.uid] as Array).append([label, OcgDuel.i32((i << 16) | kind), k, hint, int(list[i].get("direct", 0)) != 0])


func _is(a: Array, what: String) -> bool:
	return str(a[2]) == what or (what == "summon" and str(a[2]) == "tribute") or (what == "repos" and str(a[2]) == "flipsummon")


func _has(c, what: String) -> bool:
	for a in acts.get(c.uid, []):
		if _is(a, what):
			return true
	return false


## What the table shows while it is your move: the phase buttons, which cards can do something.
func refresh() -> void:
	var hud = s.hud
	var board = s.board
	var st: DuelState = s.state
	if st.players.size() < 2:
		return
	var costs: Array = []
	if active():
		for a in speed_acts:
			var lead := str(a[0]).get_slice(" ", 0)
			if lead.is_valid_int():
				costs.append(int(lead))
	hud.set_speed_button(active() and not speed_acts.is_empty(), costs)
	board.set_extra_count(AI, st.players[AI].extra.size())
	if not active():
		hud.set_phase_buttons("", false, false)
		hud.set_extra_button(st.players[ME].extra.size(), 0, false)
		board.set_extra_count(ME, st.players[ME].extra.size(), 0)
		hud.set_playable([])
		hud.set_coach("")
		s._clear_glows()
		return
	var battle := int(req["t"]) == 10
	if battle:
		hud.set_phase_buttons("Main Phase 2", int(req["to_m2"]) != 0, int(req["to_ep"]) != 0)
	elif st.phase == DuelState.Phase.MAIN1:
		hud.set_phase_buttons("Battle Phase", int(req["to_bp"]) != 0, int(req["to_ep"]) != 0)
	else:
		hud.set_phase_buttons("", false, int(req["to_ep"]) != 0)
	var ready := 0
	for x in st.players[ME].extra:
		if acts.has(x.uid):
			ready += 1
	hud.set_extra_button(st.players[ME].extra.size(), ready, true)
	board.set_extra_count(ME, st.players[ME].extra.size(), ready)
	var playable: Array = []
	for c in st.players[ME].hand:
		if acts.has(c.uid):
			playable.append(c)
	hud.set_playable(playable)
	hud.set_coach(_coach(battle, ready))
	s._clear_glows()
	for p in 2:
		for c in st.players[p].monsters() + st.players[p].set_cards() + ([st.players[p].field_spell] if st.players[p].field_spell != null else []):
			var node = board.card_for(c)
			if node == null:
				continue
			if acts.has(c.uid):
				var col: Color = Comic.SKY
				if _has(c, "act") and not c.is_monster():
					col = Color("ff4dd2") if not c.face_up else Color("ffd23a")
				node.set_glow(true, col)
			else:
				node.set_glow(false)


func _coach(battle: bool, ready: int) -> String:
	if battle:
		return Loc.t("Tap a glowing monster and then its target, or drag it there.")
	if ready > 0:
		return Loc.t("A monster in your Extra Deck is ready. Glowing cards can do something.")
	if acts.is_empty():
		return Loc.t("Nothing to play. Go to the Battle Phase or end your turn.")
	return Loc.t("Glowing cards can do something: tap one, or drag it onto the table.")


func _answer(bytes: PackedByteArray) -> void:
	if req == null:
		return
	answered.emit(bytes)


## The menu of a card: every entry carries its kind (for the icon and the color) and, when it
## has one, its own second line. `only`: just these kinds (a card dropped on a zone).
func _menu_for(c, only: Array = []) -> Array:
	var opts: Array = []
	_menu = acts.get(c.uid, [])
	for i in _menu.size():
		var e: Array = _menu[i]
		if not only.is_empty() and not only.has(str(e[2])):
			continue
		var o: Array = ["ocg:%d" % i, e[0], true, str(e[2])]
		if str(e[3]) != "":
			o.append(str(e[3]))
		opts.append(o)
	return opts


func on_hand_card_pressed(inst, _at: Vector2) -> void:
	var hud = s.hud
	if hud.actions_visible() and s._menu_card == inst:
		hud.hide_actions()
		s._menu_card = null
		return
	if not aim.is_empty():
		s._cancel_mode()
	want = {}
	s._deck_menu = false
	s._menu_card = inst
	hud.inspect(inst)
	if not active():
		return
	var opts := _menu_for(inst)
	if opts.is_empty():
		# Nothing it can do right now: the tap just shows the card (no message over your hand).
		return
	hud.focus_hand_card(inst)
	hud.show_actions(hud.hand_menu_anchor(inst), opts, true)


func _mine(inst) -> bool:
	return s.state.players[ME].field.has(inst)


func on_board_card_clicked(card) -> void:
	var hud = s.hud
	var inst = card.inst
	if inst == null:
		return
	if not pick.is_empty():
		if (pick["cands"] as Array).has(inst):
			(pick["sig"] as Callable).call(inst)
		return
	if not zone_pick.is_empty():
		return
	if not aim.is_empty():
		# An attack is being aimed: one of theirs is the target; the attacker again calls it off.
		if s.state.players[AI].field.has(inst):
			_aim_go(inst, false)
		elif _mine(inst) and inst != aim["inst"] and _has(inst, "attack"):
			_aim_from(inst)
		else:
			s._cancel_mode()
		return
	# (a second tap on the card whose menu is open closes it; the tap itself may already have put the menu away)
	var reopened: bool = (hud.actions_visible() and s._menu_card != null and s._menu_card == inst) or (s._closed_card != null and s._closed_card == inst and Time.get_ticks_msec() - int(s._closed_at) < 150)
	s._closed_card = null
	hud.hide_actions()
	s._deck_menu = false
	if not active() or reopened:
		s._menu_card = null
		press = {}
		return
	want = {}
	var battle := int(req["t"]) == 10
	if not battle and int(req["to_bp"]) != 0 and _mine(inst) and inst.face_up and inst.attack_pos:
		# In Main Phase 1 a press that turns into a drag is an attack: the Battle Phase starts by itself.
		press = {"inst": inst, "from": s.get_viewport().get_mouse_position()}
	var opts := _menu_for(inst)
	if opts.is_empty():
		return
	s._menu_card = inst
	if opts.size() == 1 and _is(_menu[0], "attack"):
		s._menu_card = null
		_aim_from(inst)
		return
	hud.show_actions(s.board.screen_pos(inst) + Vector2(60, 0), opts)


func on_action(action: String) -> bool:
	if not action.begins_with("ocg:"):
		return false
	var card = s._menu_card
	s._menu_card = null
	var parts := action.split(":")
	var list: Array = _menu
	var i := int(parts[1])
	if parts.size() >= 3:
		# (a card dropped on the table: "ocg:<card uid>:<which of its actions>")
		list = acts.get(int(parts[1]), [])
		i = int(parts[2])
	if active() and i >= 0 and i < list.size():
		if _is(list[i], "attack") and card != null and _mine(card):
			# Attack: now say at what. Nothing is declared until you do.
			_aim_start(card, list[i][1], bool(list[i][4]), false)
			return true
		_answer(list[i][1])
	return true


# ------------------------------------------------------------------ attacking

func _foes() -> Array:
	return s.state.players[AI].monsters()


func _aim_from(inst) -> void:
	for a in acts.get(inst.uid, []):
		if _is(a, "attack"):
			_aim_start(inst, a[1], bool(a[4]), true)
			return


## Aim an attack: an arrow runs from the attacker to the pointer, their monsters light up, and
## their side of the field becomes a target when the attack can go direct. Tap a target, or
## hold the press and let go over it. `answer` is null for an attack dragged out of Main Phase 1.
func _aim_start(inst, answer, direct: bool, held: bool) -> void:
	var foes := _foes()
	if answer == null:
		direct = foes.is_empty()
	elif foes.is_empty():
		direct = true
	aim = {"inst": inst, "answer": answer, "direct": direct, "from": s.get_viewport().get_mouse_position(),
			"held": held and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "moved": false}
	press = {}
	s.mode = "attack"
	s.hud.hide_actions()
	s._menu_card = null
	s._clear_glows()
	var node = s.board.card_for(inst)
	if node:
		node.set_glow(true, UITheme.GOLD)
	for t in foes:
		var tc = s.board.card_for(t)
		if tc:
			tc.set_glow(true, UITheme.DANGER)
	s.board.start_aim(inst)
	s.board.show_direct_target(direct)
	Sfx.play("hover", -8.0, 0.9)
	var nm := str(inst.cname())
	if foes.is_empty():
		s.hud.show_prompt(Loc.t("%s: tap their side of the field to attack directly") % nm, false)
	elif direct:
		s.hud.show_prompt(Loc.t("%s: tap a monster to attack it, or their side of the field to attack directly") % nm, false)
	else:
		s.hud.show_prompt(Loc.t("%s: tap the monster it attacks") % nm, false)


func _aim_stop() -> void:
	aim = {}
	s.board.stop_aim()
	s.board.show_direct_target(false)
	s.mode = ""
	s.hud.hide_prompt()


## The attack is on: at `target`, or directly.
func _aim_go(target, direct: bool) -> void:
	var a := aim
	if a.is_empty():
		return
	if direct and not bool(a["direct"]):
		Sfx.play("error", -8.0)
		return
	_aim_stop()
	if not active():
		refresh()
		return
	want = {"direct": true} if direct else {"target": target.uid}
	Sfx.play("card", -4.0, 0.8)
	if a["answer"] != null:
		_answer(a["answer"])
	else:
		want["attacker"] = a["inst"].uid
		_answer(OcgDuel.i32(6))


## Their side of the field was tapped while aiming.
func on_direct() -> void:
	if not aim.is_empty():
		_aim_go(null, true)


## The second button of the line at the top (Confirm).
func on_prompt_button() -> void:
	if not pick.is_empty() and pick.has("sig"):
		(pick["sig"] as Callable).call("ok")


## The pointer, before anything else sees it: a tap on a lit zone, and presses that turn into drags.
func on_input(event: InputEvent) -> bool:
	if not zone_pick.is_empty():
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var z = s.board.zone_at(event.position, zone_pick)
			if z != null:
				Sfx.play("card", -6.0)
				_zone_picked.emit(z)
				return true
		return false
	if event is InputEventMouseMotion:
		if not press.is_empty() and aim.is_empty() and active():
			if (event.position as Vector2).distance_to(press["from"]) > 22.0:
				var inst = press["inst"]
				press = {}
				_aim_start(inst, null, false, true)
				if not aim.is_empty():
					aim["moved"] = true
		elif not aim.is_empty() and aim["held"] and not aim["moved"]:
			if (event.position as Vector2).distance_to(aim["from"]) > 22.0:
				aim["moved"] = true
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		press = {}
		if not aim.is_empty() and aim["held"]:
			aim["held"] = false
			if aim["moved"]:
				# Let go: over one of their monsters, over their side of the field, or nowhere.
				var hit = s.board.enemy_card_at(event.position, _foes())
				if hit != null:
					_aim_go(hit.inst, false)
				elif bool(aim["direct"]) and s.board.side_at(event.position) == 1:
					_aim_go(null, true)
				else:
					s._cancel_mode()
	return false


# ------------------------------------------------------------------ dragging a card out of the hand

## The zones a hand card can be dropped on: free Monster Zones for a monster you can Summon or
## Set, free Spell & Trap Zones for a Spell or Trap (the Field Zone for a Field Spell).
func _drop_zones(inst) -> Array:
	var out: Array = []
	if not active() or not acts.has(inst.uid):
		return out
	var ps: DuelState.PlayerState = s.state.players[ME]
	if inst.is_monster():
		if not (_has(inst, "summon") or _has(inst, "mset") or _has(inst, "special")):
			return out
		for z in 5:
			if ps.field[z] == null:
				out.append([ME, OcgCore.LOC_MZONE, z])
		if out.is_empty():
			# A full row: it takes the place of a monster you Tribute.
			for z in 5:
				out.append([ME, OcgCore.LOC_MZONE, z])
	elif _has(inst, "act") or _has(inst, "sset"):
		if SpellRules.kind(inst) == "field":
			out.append([ME, OcgCore.LOC_SZONE, 5])
		else:
			for z in 5:
				if ps.spells[z] == null:
					out.append([ME, OcgCore.LOC_SZONE, z])
	return out


## (the duel scene asks this to know whether a hand card can be dragged at all)
func drop_plan(inst) -> Dictionary:
	return {} if _drop_zones(inst).is_empty() else {0: []}


func on_hand_drag(inst, on: bool) -> void:
	if not on:
		s.board.show_zone_picks([])
		return
	s._menu_card = null
	var word := "PLAY"
	if inst.is_monster():
		word = "SUMMON" if (_has(inst, "summon") or _has(inst, "special")) else "SET"
	elif not _has(inst, "act"):
		word = "SET"
	s.board.show_zone_picks(_drop_zones(inst), word)


## A hand card let go over the table. On a lit zone it is played there: at once when there is
## one way to play it, and with its choices (Summon or Set) opening over that zone otherwise.
func on_hand_drop(inst, at: Vector2) -> bool:
	var z = s.board.zone_at(at, _drop_zones(inst))
	if z == null or not active():
		return false
	var kinds: Array = ["summon", "tribute", "special", "mset"] if inst.is_monster() else ["act", "sset"]
	var opts := _menu_for(inst, kinds)
	if opts.is_empty():
		return false
	want = {"zone": [int(z[1]), int(z[2])]}
	Sfx.play("card", -4.0)
	if opts.size() == 1:
		s._menu_card = inst
		on_action.call_deferred(str(opts[0][0]))
		return true
	s._menu_card = inst
	s.hud.focus_hand_card(inst)
	s.hud.show_actions(s.board.camera.unproject_position(s.board.zone_pos(z)) + Vector2(0, -40), opts, true)
	return false


## Speed World 2: which of its effects to pay for.
func on_speed_pressed() -> void:
	if not active() or speed_acts.is_empty():
		Router.toast("Not enough Speed Counters yet")
		return
	var labels: Array = []
	for a in speed_acts:
		labels.append(a[0])
	labels.append(Loc.t("Cancel"))
	var list := speed_acts.duplicate()
	var i: int = await s.hud.ask_choice(Loc.t("Speed World 2   ·   you have %d Speed Counters") % s.state.players[ME].speed, labels)
	if i < 0 or i >= list.size() or not active():
		return
	Sfx.play("gong", -6.0)
	_answer(list[i][1])


func on_phase_button(action: String) -> void:
	if not active():
		return
	var battle := int(req["t"]) == 10
	if action == "battle":
		if battle and int(req["to_m2"]) != 0:
			_answer(OcgDuel.i32(2))
		elif not battle and int(req["to_bp"]) != 0:
			_answer(OcgDuel.i32(6))
	elif action == "end":
		if battle:
			_answer(OcgDuel.i32(3 if int(req["to_ep"]) != 0 else 2))
		elif int(req["to_ep"]) != 0:
			_answer(OcgDuel.i32(7))


func on_extra_pressed() -> void:
	if not active():
		return
	want = {}
	var opts: Array = []
	for x in s.state.players[ME].extra:
		var ok: bool = acts.has(x.uid)
		var status := ""
		if ok:
			status = {"fusion": "Fusion Summon", "synchro": "Synchro Summon", "xyz": "Xyz Summon"}.get(x.frame(), "Special Summon")
			if _has(x, "act") and not _has(x, "special"):
				status = "Use its effect"
		else:
			status = {"fusion": "Needs a Fusion card", "synchro": "Needs its materials", "xyz": "Needs its materials"}.get(x.frame(), "")
		opts.append([x, status, ok])
	s.hud.show_extra(opts)


func on_extra_chosen(inst) -> void:
	if not active() or not acts.has(inst.uid):
		return
	var list: Array = acts[inst.uid]
	s.hud.hide_extra()
	_answer(list[0][1])


## Effects of cards in your Graveyard or among your banished cards.
func pile_effects() -> Array:
	var out: Array = []
	if not active():
		return out
	var ps: DuelState.PlayerState = s.state.players[ME]
	for c in ps.gy + ps.banished:
		if acts.has(c.uid):
			out.append(c)
	return out


func on_pile_effects() -> void:
	want = {}
	var cards := pile_effects()
	if cards.is_empty():
		return
	var res = await s.hud.ask_cards(Loc.t("Use which card's effect?"), cards, {"min": 1, "max": 1, "confirm": Loc.t("Activate"), "cancel": Loc.t("Not now"), "labels": _labels(cards)})
	var got = res[0] if (res is Array and not (res as Array).is_empty()) else null
	use_pile_card(got)


## Use the effect of this card in your Graveyard or banished pile (from the piles window, 0.73.2).
func use_pile_card(got) -> void:
	if got == null or not active() or not acts.has(got.uid):
		return
	var list: Array = acts[got.uid]
	if list.size() == 1:
		_answer(list[0][1])
		return
	var words: Array = []
	for a in list:
		words.append(a[3] if str(a[3]) != "" else a[0])
	var i: int = await s.hud.ask_choice(Loc.t("%s: which effect?") % got.cname(), words, got)
	if active():
		_answer(list[clampi(i, 0, list.size() - 1)][1])


## Esc, a right-click or the Cancel button. True when something of the table's own was open
## (a pick, a zone choice): the scene then leaves the rest alone.
func cancel() -> bool:
	press = {}
	if not zone_pick.is_empty():
		_zone_picked.emit(null)
		return true
	if not pick.is_empty():
		if bool(pick.get("cancel", false)):
			(pick["sig"] as Callable).call(null)
		else:
			Sfx.play("error", -10.0)
		return true
	aim = {}
	return false


## Point at one card on the table. Returns the card, or null if it was cancelled.
signal _picked(card)

func _pick_on_board(cards: Array, text: String, can_cancel: bool, word := "SELECT"):
	pick = {"cands": cards, "cancel": can_cancel, "sig": func(c): _picked.emit(c)}
	s.board.show_picks(cards, [], word)
	s.hud.show_prompt(text, false, "", "Cancel" if can_cancel else "")
	_auto(func(): _picked.emit(null if (can_cancel and randf() < 0.15) else cards.pick_random()))
	var got = await _picked
	while got is String:      # (a stray Confirm: there is nothing to confirm here)
		got = await _picked
	pick = {}
	s.board.clear_picks()
	s.hud.hide_prompt()
	return got


## Point at several cards on the table: a tap chooses one, a second tap takes it back, the
## counter at the top keeps score and Confirm sends them. count = [fewest, most]; `valid` says
## whether the cards chosen so far may be confirmed. Returns the cards, or null if cancelled.
func _pick_many_on_board(cards: Array, text: String, count: Array, valid: Callable, can_cancel: bool, word := "SELECT", info := Callable()):
	var chosen: Array = []
	pick = {"cands": cards, "cancel": can_cancel, "many": true, "sig": func(c): _picked.emit(c)}
	var hi := int(count[1])
	var out = null
	while true:
		s.board.show_picks(cards, chosen, word, "CHOSEN")
		var ok: bool = valid.call(chosen)
		var line := "%s   ·   %d / %d" % [text, chosen.size(), hi if int(count[0]) == hi else maxi(int(count[0]), chosen.size())]
		if info.is_valid() and str(info.call(chosen)) != "":
			line += "   ·   " + str(info.call(chosen))
		s.hud.show_prompt(line, true, "Confirm", "Cancel" if can_cancel else "", ok)
		_auto_steps += 1
		var step := _auto_steps
		_auto(func():
			if step != _auto_steps or pick.is_empty():
				return
			if ok and (randf() < 0.6 or chosen.size() >= hi):
				_picked.emit("ok")
			elif step % 40 == 39:
				_picked.emit(null if can_cancel else "stop")
			else:
				_picked.emit(cards.pick_random()))
		var got = await _picked
		if got is String and str(got) == "stop":
			break
		if got == null:
			break
		if got is String:
			if ok:
				out = chosen
				break
			Sfx.play("error", -10.0)
			continue
		if chosen.has(got):
			chosen.erase(got)
			Sfx.play("card", -10.0, 0.9)
		elif chosen.size() >= hi:
			Sfx.play("error", -10.0)
		else:
			chosen.append(got)
			Sfx.play("card", -8.0, 1.15 + 0.06 * chosen.size())
	pick = {}
	s.board.clear_picks()
	s.hud.hide_prompt()
	return out


## One step of a pick the engine checks card by card, on the table: the cards that may be added
## and the ones already in (tap one of those to take it back). Returns the card tapped,
## "ok" for Confirm, or null for a cancel.
func _pick_live_on_board(cards: Array, chosen: Array, text: String, finish: bool, can_cancel: bool):
	var all: Array = cards + chosen
	pick = {"cands": all, "cancel": can_cancel or finish, "sig": func(c): _picked.emit(c)}
	s.board.show_picks(all, chosen, "SELECT", "CHOSEN")
	s.hud.show_prompt("%s   ·   %s" % [text, Loc.t("%d chosen") % chosen.size()], true, "Confirm", "Cancel" if (can_cancel and not finish) else "", finish)
	_auto(func(): _picked.emit("ok" if (finish and (randf() < 0.5 or cards.is_empty())) else (all.pick_random() if not cards.is_empty() or finish else null)))
	var got = await _picked
	while got is String and not finish:
		Sfx.play("error", -10.0)
		got = await _picked
	pick = {}
	if got == null or got is String:
		s.board.clear_picks()
		s.hud.hide_prompt()
	return got


# ------------------------------------------------------------------ the table matches the mirror

## After every batch of events: whatever the animations left out, the table is put right.
## Cards on the field stand where the engine has them, the hands and the piles match.
func resync() -> void:
	var st: DuelState = s.state
	var board = s.board
	var hud = s.hud
	if st.players.size() < 2:
		return
	var on_table := {}
	for p in 2:
		var ps: DuelState.PlayerState = st.players[p]
		for i in 5:
			var mc = ps.field[i]
			if mc != null:
				on_table[mc.uid] = true
				_seat(mc, Transform3D(board.table_basis(p, mc.face_up, mc.attack_pos), board.monster_zone_pos(p, i) + Vector3(0, 0.02, 0)))
			var sc = ps.spells[i]
			if sc != null:
				on_table[sc.uid] = true
				_seat(sc, Transform3D(board.table_basis(p, sc.face_up, true), board.st_pos(p, i) + Vector3(0, 0.02, 0)))
		if ps.field_spell != null:
			on_table[ps.field_spell.uid] = true
			_seat(ps.field_spell, Transform3D(board.table_basis(p, ps.field_spell.face_up, true), board.st_pos(p, 5) + Vector3(0, 0.02, 0)))
	for mc in s._materials:
		on_table[mc.uid] = true     # (materials on their way into a Summon stay in the air until it lands)
	# Their hand, as backs across the table.
	var theirs: Array = st.players[AI].hand
	var keep: Array = []
	for c in theirs:
		on_table[c.uid] = true
		var node = board.card_for(c)
		if node == null:
			node = board._new_card(c)
			node.set_pickable(false)
		keep.append(node)
	var changed: bool = keep.size() != board._opp_hand.size()
	if not changed:
		for i in keep.size():
			if board._opp_hand[i] != keep[i]:
				changed = true
				break
	if changed:
		board._opp_hand.clear()
		for node in keep:
			board._opp_hand.append(node)
		board._layout_opp_hand()
	# (online, the cards of theirs that were blank and are now known, a set card flipped face-up,
	# show their face from here on)
	if net_guest:
		for uid in board._cards.keys():
			var nd = board._cards[uid]
			if is_instance_valid(nd) and nd.inst != null and nd.card_id != int(nd.inst.id):
				nd.setup(int(nd.inst.id), int(nd.inst.owner))
	# Anything else still standing on the table has left it.
	for uid in board._cards.keys():
		if not on_table.has(uid):
			var node = board._cards[uid]
			board._cards.erase(uid)
			if is_instance_valid(node):
				node.queue_free()
	# Your hand.
	var mine: Array = st.players[ME].hand
	for e in hud._hand.duplicate():
		if not mine.has(e["inst"]):
			hud.remove_hand_card(e["inst"])
	for c in mine:
		var found := false
		for e in hud._hand:
			if e["inst"] == c:
				found = true
				break
		if not found:
			hud.add_hand_card(c)
	# The piles show their top cards.
	for p in 2:
		_pile(board._gy_cards[p], st.players[p].gy, func(c): board._add_to_gy(c))
		_pile(board._ban_cards[p], st.players[p].banished, func(c): board._add_to_banished(c))
		board.set_deck_count(p, st.players[p].deck.size())
	for p in 2:
		for mc in st.players[p].monsters():
			board.set_overlays(mc)
	board.refresh_stats(st)
	s._update_counts()
	s._sync_field()


func _seat(c, to: Transform3D) -> void:
	var board = s.board
	var node = board.card_for(c)
	if node == null:
		node = board._new_card(c)
		node.transform = to
		node.set_pickable(true)
		return
	board._opp_hand.erase(node)
	if node.position.distance_to(to.origin) > 0.05 or not node.transform.basis.is_equal_approx(to.basis):
		node.transform = to
	node.set_pickable(true)


func _pile(nodes: Array, cards: Array, add: Callable) -> void:
	var top: Array = cards.slice(maxi(0, cards.size() - 3))
	var same := nodes.size() == top.size()
	if same:
		for i in top.size():
			if nodes[i].inst != top[i]:
				same = false
				break
	if same:
		return
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	nodes.clear()
	for c in top:
		add.call(c)


## Dev: `--ux=menu|pick|choice|attack` opens one interaction at the first chance, for a screenshot.
var _ux_done := false
var _ux_busy := false

func _ux_summon() -> bool:
	for c in s.state.players[ME].hand:
		for a in acts.get(c.uid, []):
			if str(a[2]) == "summon":
				_answer(a[1])
				return true
	return false


func _ux_demo() -> void:
	if _ux_done or _ux_busy:
		return
	var what := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ux="):
			what = a.trim_prefix("--ux=")
	if what == "":
		return
	_ux_busy = true
	await s.get_tree().create_timer(1.2).timeout
	_ux_busy = false
	if not active():
		return
	var hand: Array = s.state.players[ME].hand
	var mons: Array = s.state.players[ME].monsters()
	var battle := int(req["t"]) == 10
	match what:
		"piles", "piles-use":
			# (0.73.2) The piles window with a card whose effect works from the Graveyard; "-use" also
			# uses it, the way a click on ACTIVATE does.
			_ux_done = true
			print("UX pile effects: ", pile_effects().map(func(c): return c.cname()))
			s.hud.show_piles(ME)
			if what == "piles-use":
				await s.get_tree().create_timer(1.0).timeout
				var pe := pile_effects()
				if not pe.is_empty():
					print("UX using ", pe[0].cname())
					s.hud.pile_chosen.emit(pe[0])
		"useall":
			# (dev, 0.74.1) Play every Speed Spell in hand that can be played, one after another
			# (prompts answered on their own), then end the turn. For checking new cards.
			s.hud.auto_answer = true
			print("UX useall hand: ", hand.map(func(c): return "%s%s" % [c.cname(), "*" if acts.has(c.uid) else ""]))
			for c in hand:
				if c.cname().begins_with("Speed Spell") and acts.has(c.uid):
					for a in acts[c.uid]:
						if str(a[2]) == "act":
							print("UX useall ", c.cname())
							_answer(a[1])
							return
			_ux_done = true
			print("UX useall done")
			_answer(OcgDuel.i32(7))
		"fakehit":
			# (dev, 0.74.0) Your first monster on the field throws a direct attack again and again
			# (the picture only: nothing in the duel changes), for screenshots of a blow landing.
			_ux_done = true
			while is_instance_valid(s) and not mons.is_empty():
				print("UX fakehit at ", Time.get_ticks_msec())
				await s.board.anim_battle(ME, mons[0], null)
				await s.get_tree().create_timer(1.5).timeout
		"menu":
			_ux_done = true
			for c in hand:
				if acts.has(c.uid) and c.is_monster():
					on_hand_card_pressed(c, Vector2.ZERO)
					break
		"menu2":
			_ux_done = true
			for c in hand:
				if acts.has(c.uid) and not c.is_monster():
					on_hand_card_pressed(c, Vector2.ZERO)
					break
		"pick":
			_ux_done = true
			s.hud.ask_cards("Select the cards to discard", hand, {"min": 2, "max": 2, "cancel": Loc.t("Cancel"), "labels": _labels(hand)})
			await s.get_tree().create_timer(0.6).timeout
			s.hud._picker._tap(hand[1])
			s.hud._picker._tap(hand[3])
		"pick1":
			_ux_done = true
			s.hud.ask_cards("Add 1 card to your hand", s.state.players[ME].deck.slice(0, 14), {"min": 1, "max": 1})
			await s.get_tree().create_timer(0.6).timeout
			s.hud._picker._tap(s.state.players[ME].deck[2])
		"destiny":
			_ux_done = true
			s.hud.ask_pick(Loc.t("Destiny Draw: choose the card you draw"), s.state.players[ME].deck.duplicate(), "Draw this card", "")
			await s.get_tree().create_timer(0.8).timeout
			s.hud._picker._tap(s.state.players[ME].deck[4])
		"choice":
			_ux_done = true
			s.hud.ask_choice("Activate \"Dark Magical Circle\"?", [Loc.t("Yes"), Loc.t("No")], hand[0])
		"pos":
			_ux_done = true
			s.hud.ask_position(hand[0], [1, 4, 8])
		"drag":
			_ux_done = true
			for c in hand:
				if acts.has(c.uid) and c.is_monster():
					on_hand_drag(c, true)
					break
		"zone":
			_ux_done = true
			_ux_summon()
		"tsummon", "tsummon2":
			_ux_done = true
			for c in hand:
				for a in acts.get(c.uid, []):
					if str(a[2]) == "tribute":
						_answer(a[1])
						if what == "tsummon2":
							# (the whole way: the Tribute is tapped, then a zone)
							await s.get_tree().create_timer(1.5).timeout
							if not pick.is_empty():
								(pick["sig"] as Callable).call((pick["cands"] as Array)[0])
							await s.get_tree().create_timer(1.5).timeout
							if not zone_pick.is_empty():
								_zone_picked.emit(zone_pick[0])
						return
		"aim", "direct", "hit":
			s.hud.auto_answer = true
			if battle:
				var who = null
				for mm in mons:
					if _has(mm, "attack"):
						who = mm
						break
				if who != null and what == "hit":
					# (dev, 0.74.0) The attack goes through, for pictures of a blow landing.
					_ux_done = true
					for a in acts.get(who.uid, []):
						if str(a[2]) == "attack":
							_answer(a[1])
							break
				elif who != null:
					_ux_done = true
					s.hud.auto_answer = false
					_aim_from(who)
				else:
					_answer(OcgDuel.i32(3))
			elif mons.is_empty():
				want = {"zone": [OcgCore.LOC_MZONE, 1]}
				if not _ux_summon():
					_answer(OcgDuel.i32(7))
			elif int(req["to_bp"]) != 0:
				_answer(OcgDuel.i32(6))
			else:
				_answer(OcgDuel.i32(7))
		"many":
			s.hud.auto_answer = true
			if mons.size() >= 2:
				_ux_done = true
				s.hud.auto_answer = false
				_pick_many_on_board(mons, "Select the monsters to Tribute", [2, 2], func(ch: Array): return ch.size() == 2, true, "TRIBUTE")
				await s.get_tree().create_timer(0.5).timeout
				(pick["sig"] as Callable).call(mons[0])
			elif battle:
				_answer(OcgDuel.i32(3))
			else:
				want = {"zone": [OcgCore.LOC_MZONE, mons.size() * 3]}
				if not _ux_summon():
					_answer(OcgDuel.i32(7))
