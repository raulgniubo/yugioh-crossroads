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
var pick := {}             # an on-board pick in progress: {"cands", "answers", "cancel"}
var _hand := [5, 5]
var _menu: Array = []
var level := 2             # how the opponent thinks: 0 the plain policy, 1 Normal, 2 Hard, 3 Extreme
var _turn_think := 0       # ms it has thought this turn
var _turn_seen := -1
var _turn_asks := 0
const TURN_BUDGET := [0, 6000, 14000, 28000]     # after this much thinking in one turn it hurries
const NAMES := ["Basic", "Normal", "Hard", "Extreme"]
var _log := "--ocg-log" in OS.get_cmdline_user_args()


func _init(scene) -> void:
	s = scene


## Is this duel run by the rules engine? Every duel is, unless Settings asks for the classic
## rules (kept for one build as a way back) or the engine's library did not load.
static func wanted(cfg: Dictionary) -> bool:
	var args := OS.get_cmdline_user_args()
	if "--classic" in args or str(cfg.get("engine", "")) == "classic":
		return false
	if Settings.classic_engine and not "--ocg" in args and str(cfg.get("engine", "")) != "new":
		return false
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
var _destiny_ask := [false, false]    # that player said yes to the Destiny Draw: the next pick is the card
var _destiny_draw := [false, false]   # ... and their next draw is that card (it lands quietly)

func prepare(my_list: Array, opp_list: Array, my_extra: Array, opp_extra: Array, me_name: String, opp_name: String, first: int, hand: Array, setup := {}, rules_in := {}) -> void:
	_hand = hand
	rules = rules_in
	d.prepare(s.state, [my_list, opp_list], [my_extra, opp_extra], [me_name, opp_name], first, -1, setup)
	s._turn_finished.connect(_on_abort)


## Start the engine with the Life Points the scene settled on. Returns the opening events.
func begin() -> Array:
	var st: DuelState = s.state
	if not d.start([st.players[ME].lp, st.players[AI].lp], _hand, rules):
		st._set_winner(DuelState.DRAW, "The new engine could not start.")
		return []
	return d.advance()


func _on_abort() -> void:
	answered.emit(null)


func active() -> bool:
	return req != null and not s.busy and not s._finished and not s.state.is_over() and pick.is_empty()


# ------------------------------------------------------------------ the loop

func loop() -> void:
	var seen_retries := 0
	resync()
	while not d.over and not s._finished and not s.state.is_over():
		var m = d.request
		if m == null:
			break
		var p := int(m["p"])
		var bytes = null
		var refused: bool = d.retries > seen_retries
		seen_retries = d.retries
		if refused:
			push_warning("OCG: answer refused for message %d" % int(m["t"]))
			if d.retries > 12:
				s.state._set_winner(DuelState.DRAW, "The duel could not go on.")
				break
			bytes = (cpu if p == AI else me_cpu).decide(d, true)
		elif p == ME and not s._autoplay:
			bytes = await _ask(m)
		elif p == AI:
			bytes = await _cpu_answer(m)
		else:
			bytes = me_cpu.decide(d)
		if s._finished or s.state.is_over() or bytes == null:
			break
		d.answer(bytes)
		var events := d.advance()
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
	d.close()


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
	if level <= 0 or _turn_asks > 140:
		if command and not s._autoplay:
			await s._ai_wait(0.35)
		if reach:
			await _destiny_show(AI, 0)
		return cpu.decide(d, _turn_asks > 180)
	var cap := 0
	if _turn_think > int(TURN_BUDGET[level]):
		cap = 350
	var t0 := Time.get_ticks_msec()
	OcgCore.think_start(d.handle, level, cap, randi())
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
			if dv == 0:
				text = OcgCore.fill(OcgCore.sys(200), nm, Loc.t(d._zone_name(int(cd["loc"]))))
			elif (dv >> 20) == 0:
				text = OcgCore.fill(OcgCore.sys(dv), nm)
			else:
				text = nm + ": " + OcgCore.desc(dv) + "?"
			var src = d.card_at(int(cd["con"]), int(cd["loc"]), int(cd["seq"]), int(cd.get("pos", 0)))
			out = OcgDuel.i32(1 if await s.hud.ask_choice(text, [Loc.t("Yes"), Loc.t("No")], src) == 0 else 0)
		13:
			if _is_destiny_offer(m):
				var yes := true
				if not s._human_test:
					s._lumen("destiny")
					yes = await s.hud.ask_destiny()
				_destiny_ask[ME] = yes
				out = OcgDuel.i32(1 if yes else 0)
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
		143:
			var nums: Array = []
			for o in m["opts"]:
				nums.append(str(int(o)))
			out = OcgDuel.i32(await s.hud.ask_choice(_hint_text(ME, OcgCore.sys(565)), nums))
		_:
			# Zones, sort orders and the like: taken care of for you.
			out = me_cpu.decide(d)
	s._flow = was
	return out


func _ask_cards(m: Dictionary, tribute := false):
	var list: Array = m["cards"]
	var cards := d.cards_of(list)
	for i in cards.size():
		if cards[i] == null:
			cards[i] = _temp(int(list[i]["code"]), int(list[i]["con"]) if int(list[i]["con"]) < 2 else ME)
	var lo := int(m["min"])
	var hi := int(m["max"])
	var can_cancel := int(m["cancel"]) != 0
	var text := _hint_text(ME, OcgCore.sys(500) if tribute else OcgCore.sys(560))
	# One card that is on the table: point at it there.
	if lo == 1 and hi == 1 and not tribute:
		var all_field := true
		for c in cards:
			if not _on_field(c):
				all_field = false
				break
		if all_field and not s._human_test:
			var got = await _pick_on_board(cards, text, can_cancel)
			if got == null:
				return OcgDuel.i32(-1) if can_cancel else OcgDuel.pick([0])
			return OcgDuel.pick([cards.find(got)])
	var picked: Array = []
	var left := cards.duplicate()
	var weight := 0
	while picked.size() < hi and not left.is_empty():
		var enough: bool = (weight >= lo) if tribute else (picked.size() >= lo)
		var line := text
		if hi > 1:
			line += "   (%d / %d)" % [picked.size() + 1, hi if lo == hi else lo]
		var stop := ""
		if enough:
			stop = Loc.t("Done")
		elif can_cancel and picked.is_empty():
			stop = Loc.t("Cancel")
		var got2 = await s.hud.ask_pick(line, left, Loc.t("Select"), stop, _hidden(left), _labels(left))
		if got2 == null:
			break
		var gi := cards.find(got2)
		picked.append(gi)
		weight += maxi(1, int(list[gi].get("param", 1))) if tribute else 1
		left.erase(got2)
		if tribute and weight >= lo and lo == hi:
			break
	var ok: bool = (weight >= lo) if tribute else (picked.size() >= lo)
	if not ok:
		if can_cancel:
			return OcgDuel.i32(-1)
		# Not enough chosen and it cannot be skipped: fill it up.
		for i in cards.size():
			if picked.size() >= lo:
				break
			if not picked.has(i):
				picked.append(i)
	return OcgDuel.pick(picked)


func _ask_unselect(m: Dictionary):
	var list: Array = m["cards"]
	var uns: Array = m["unsel"]
	var cards := d.cards_of(list)
	for i in cards.size():
		if cards[i] == null:
			cards[i] = _temp(int(list[i]["code"]), ME)
	var chosen := d.cards_of(uns)
	var text := _hint_text(ME, OcgCore.sys(560))
	var labels := _labels(cards)
	var options := cards.duplicate()
	for i in chosen.size():
		if chosen[i] != null and not options.has(chosen[i]):
			options.append(chosen[i])
			labels[chosen[i].uid] = Loc.t("Chosen (tap to take back)")
	var stop := ""
	if int(m["finish"]) != 0:
		stop = Loc.t("Done")
	elif int(m["cancel"]) != 0:
		stop = Loc.t("Cancel")
	if options.is_empty():
		return OcgDuel.i32(-1)
	var got = await s.hud.ask_pick(text, options, Loc.t("Select"), stop, _hidden(options), labels)
	if got == null:
		return OcgDuel.i32(-1) if stop != "" else OcgDuel.pick_one(0)
	var gi := cards.find(got)
	if gi == -1:
		gi = cards.size() + chosen.find(got)
	return OcgDuel.pick_one(gi)


func _ask_position(m: Dictionary):
	var ok := int(m["positions"])
	var names := {1: "Attack Position", 2: "Face-down Attack Position", 4: "Defense Position", 8: "Face-down Defense Position"}
	var bits: Array = []
	var words: Array = []
	for b in [1, 4, 8, 2]:
		if ok & b:
			bits.append(b)
			words.append(Loc.t(names[b]))
	if bits.size() == 1:
		return OcgDuel.i32(bits[0])
	var c = _temp(int(m["code"]), ME)
	var i: int = await s.hud.ask_choice(Loc.t("%s: which position?") % c.cname(), words, c)
	return OcgDuel.i32(bits[clampi(i, 0, bits.size() - 1)])


func _ask_sum(m: Dictionary):
	# Levels that have to add up (a Ritual's Tributes, some Synchro picks). Pick until it fits.
	var list: Array = m["cards"]
	var cards := d.cards_of(list)
	for i in cards.size():
		if cards[i] == null:
			cards[i] = _temp(int(list[i]["code"]), ME)
	var text := _hint_text(ME, OcgCore.sys(560))
	var picked: Array = []
	var left := cards.duplicate()
	while not left.is_empty():
		if _sum_ok(m, picked):
			break
		var got = await s.hud.ask_pick(text + "   (%d)" % (picked.size() + 1), left, Loc.t("Select"), "", _hidden(left), _labels(left))
		if got == null:
			break
		picked.append(cards.find(got))
		left.erase(got)
	if not _sum_ok(m, picked):
		return me_cpu._sum(m)
	return OcgDuel.pick(picked)


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


## "Activate a card or effect?" Only asked when there is a reason to (the engine marks the
## moments your cards are meant for); otherwise it passes for you, as EDOPro does.
func _ask_chain(m: Dictionary):
	var ch: Array = m["chains"]
	if ch.is_empty():
		return OcgDuel.i32(-1)
	var forced := int(m["forced"]) != 0
	if forced and ch.size() == 1:
		return OcgDuel.i32(0)
	if not forced and int(m["spe"]) == 0 and not s.hud.phase_prompts:
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
	var got = await s.hud.ask_response(text, uniq, Loc.t("Activate"), "" if forced else Loc.t("Don't activate"), [], Color("ff4dd2"), _labels(uniq))
	s._flow = was
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
		_add_all(m["mset"], 3, "mset")
		_add_all(m["sset"], 4, "sset")
		_add_all(m["chains"], 5, "act")
	s._turn_done = false
	refresh()
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
	s.mode = ""
	s.hud.hide_actions()
	s.hud.hide_prompt()
	s.hud.hide_extra()
	s.board.clear_picks()
	refresh()
	return bytes


func _add_all(list: Array, kind: int, what: String) -> void:
	var cards := d.cards_of(list)
	for i in list.size():
		var c = cards[i]
		if c == null:
			continue
		var label := ""
		match what:
			"summon": label = Loc.t("Summon")
			"special": label = Loc.t("Special Summon")
			"mset", "sset": label = Loc.t("Set")
			"attack": label = Loc.t("Attack")
			"repos":
				label = Loc.t("Flip Summon") if not c.face_up else (Loc.t("To Defense") if c.attack_pos else Loc.t("To Attack"))
			"act":
				var line := OcgCore.desc(int(list[i]["desc"]))
				var plain: bool = not c.is_monster() and (s.state.players[ME].hand.has(c) or not c.face_up)
				label = Loc.t("Activate") if plain or line == "" else Loc.t("Effect: ") + line
		if not acts.has(c.uid):
			acts[c.uid] = []
		(acts[c.uid] as Array).append([label, OcgDuel.i32((i << 16) | kind), what])


func _has(c, what: String) -> bool:
	for a in acts.get(c.uid, []):
		if a[2] == what:
			return true
	return false


## What the table shows while it is your move: the phase buttons, which cards can do something.
func refresh() -> void:
	var hud = s.hud
	var board = s.board
	var st: DuelState = s.state
	if st.players.size() < 2:
		return
	hud.set_speed_button(active() and not speed_acts.is_empty())
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
		return Loc.t("Tap one of your glowing monsters to attack, or press Main Phase 2 / End Turn.")
	if ready > 0:
		return Loc.t("A monster in your Extra Deck is ready. Glowing cards can do something.")
	if acts.is_empty():
		return Loc.t("Nothing to play. Go to the Battle Phase or end your turn.")
	return Loc.t("Glowing cards can do something. Tap one.")


func _answer(bytes: PackedByteArray) -> void:
	if req == null:
		return
	answered.emit(bytes)


func _menu_for(c) -> Array:
	var opts: Array = []
	_menu = acts.get(c.uid, [])
	for i in _menu.size():
		opts.append(["ocg:%d" % i, _menu[i][0], true])
	return opts


func on_hand_card_pressed(inst, _at: Vector2) -> void:
	var hud = s.hud
	if hud.actions_visible() and s._menu_card == inst:
		hud.hide_actions()
		s._menu_card = null
		return
	s._deck_menu = false
	s._menu_card = inst
	hud.inspect(inst)
	if not active():
		return
	hud.focus_hand_card(inst)
	var opts := _menu_for(inst)
	if opts.is_empty():
		Router.toast(Loc.t("That card cannot be played right now."), 2.0)
		return
	hud.show_actions(hud.hand_menu_anchor(inst), opts, true)


func on_board_card_clicked(card) -> void:
	var hud = s.hud
	var inst = card.inst
	if inst == null:
		return
	if not pick.is_empty():
		if (pick["cands"] as Array).has(inst):
			var done = pick
			pick = {}
			done["result"] = inst
			(done["sig"] as Callable).call(inst)
		return
	var reopened: bool = hud.actions_visible() and s._menu_card != null and s._menu_card == inst
	hud.hide_actions()
	s._deck_menu = false
	if not active() or reopened:
		s._menu_card = null
		return
	var opts := _menu_for(inst)
	if opts.is_empty():
		return
	s._menu_card = inst
	if opts.size() == 1 and _menu[0][2] == "attack":
		s._menu_card = null
		_answer(_menu[0][1])
		return
	hud.show_actions(s.board.screen_pos(inst) + Vector2(60, 0), opts)


func on_action(action: String) -> bool:
	if not action.begins_with("ocg:"):
		return false
	s._menu_card = null
	var parts := action.split(":")
	var list: Array = _menu
	var i := int(parts[1])
	if parts.size() >= 3:
		# (a card dropped on the table: "ocg:<card uid>:<which of its actions>")
		list = acts.get(int(parts[1]), [])
		i = int(parts[2])
	if active() and i >= 0 and i < list.size():
		_answer(list[i][1])
	return true


## What dropping a hand card on your rows would do (see the duel scene's _drop_plan): a monster
## on the monster row, a Spell or Trap on the back row; face-up on the left, Set on the right.
func drop_plan(inst) -> Dictionary:
	if not active() or not acts.has(inst.uid):
		return {}
	var list: Array = acts[inst.uid]
	var up := -1
	var down := -1
	var word := ""
	for i in list.size():
		match str(list[i][2]):
			"special":
				up = i
				word = "SPECIAL SUMMON"
			"summon":
				if up == -1:
					up = i
					word = "SUMMON"
			"act":
				if not inst.is_monster() and up == -1:
					up = i
					word = "ACTIVATE"
			"mset", "sset":
				if down == -1:
					down = i
	var cells: Array = []
	if up >= 0:
		cells.append(["ocg:%d:%d" % [inst.uid, up], word])
	if down >= 0:
		cells.append(["ocg:%d:%d" % [inst.uid, down], "SET"])
	if cells.is_empty():
		return {}
	return {(0 if inst.is_monster() else 1): cells}


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
	var cards := pile_effects()
	if cards.is_empty():
		return
	var got = await s.hud.ask_pick(Loc.t("Use which card's effect?"), cards, Loc.t("Activate"), Loc.t("Not now"), [], _labels(cards))
	if got == null or not active() or not acts.has(got.uid):
		return
	var list: Array = acts[got.uid]
	if list.size() == 1:
		_answer(list[0][1])
		return
	var words: Array = []
	for a in list:
		words.append(a[0])
	var i: int = await s.hud.ask_choice(Loc.t("%s: which effect?") % got.cname(), words, got)
	if active():
		_answer(list[clampi(i, 0, list.size() - 1)][1])


func cancel() -> void:
	if not pick.is_empty() and bool(pick.get("cancel", false)):
		var done = pick
		pick = {}
		(done["sig"] as Callable).call(null)


## Point at one card on the table. Returns the card, or null if it was cancelled.
signal _picked(card)

func _pick_on_board(cards: Array, text: String, can_cancel: bool):
	pick = {"cands": cards, "cancel": can_cancel, "sig": func(c): _picked.emit(c)}
	s.board.show_picks(cards, [])
	s.hud.show_prompt(text + ("" if not can_cancel else "   " + Loc.t("(Esc: cancel)")), false)
	var got = await _picked
	pick = {}
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
