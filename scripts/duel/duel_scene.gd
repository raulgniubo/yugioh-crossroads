extends Node
## Runs a duel: turn loop, player input, AI turns, and plays state events
## through the board (3D) and the HUD (2D).

const ME := 0
const AI := 1

var state := DuelState.new()
var ocg: OcgTable = null     # set when the new rules engine runs this duel (see OcgTable)
var board: DuelBoard
var hud: DuelHUD
var busy := false
var mode := ""  # "", "tribute", "attack"
var _shown = null                 # the monster whose arrival show just played
var _puzzle := {}                 # a duel puzzle: win this turn (see Puzzles)
var _pending_card = null
var _pending_set := false
var _tributes: Array = []
var _attacker = null
var _menu_card = null
var _turn_done := false
var _finished := false
var _surrendered := false
var _autoplay := "--autoplay" in OS.get_cmdline_user_args() or "--auto-story" in OS.get_cmdline_user_args()
var _shows := not _autoplay or "--shows" in OS.get_cmdline_user_args()   # (dev: the big summon shows in autoplay too)
var _opp_key := "kaiba"
var _me_key := "player"
var _pending_tributes := 0
var _said_low := false
var _won := false
var _ai_level := 1
var _start_lp: Array = [8000, 8000]
var _my_low := 99999          # the least Life Points you had in this duel (for the medals)
var _my_turns := 0            # turns of your own so far
var _theme := "duel"          # the music for this opponent
var _materials: Array = []
var _opened := false             # the opening already played on the field
## Dev: the AI plays your side too, but through the human path, with prompts answered at random.
var _human_test := "--human-test" in OS.get_cmdline_user_args()
var _asked := {}

signal _turn_finished


func _ready() -> void:
	# Before every duel, the autosave: if anything goes wrong in it, you lose a minute at most.
	if not _autoplay:
		Saves.autosave(true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--caption="):
			# Dev: the activation line at the top, for a screenshot (by card id).
			var capid := int(a.get_slice("=", 1))
			get_tree().create_timer(5.0).timeout.connect(func():
				var fake := {"data": CardData.get_card(capid), "id": capid}
				var nm := str(fake["data"].get("name", ""))
				hud.action_caption("⚠  " + Loc.t("%s activates %s") % [str(Characters.get_char(_opp_key).get("name", "")), nm], CardText.gist(nm, str(fake["data"].get("desc", ""))), Color("ff4dd2"), false))
		if a.begins_with("--show=") or a.begins_with("--strike="):
			# Dev: hold a card's arrival or attack show on screen for a screenshot (by card id).
			var cid := int(a.get_slice("=", 1))
			var strike := a.begins_with("--strike=")
			get_tree().create_timer(4.0).timeout.connect(func():
				var cd: Dictionary = Cards.get_card(cid).duplicate()
				cd["id"] = cid
				SummonShow.dev_hold = 30.0
				if strike:
					SummonShow.strike(self, cd, true)
				else:
					SummonShow.play(self, cd, true))
	# Backs of the cards: your own sleeve, and the opponent's ace on theirs.
	var cfg0: Dictionary = Router.duel_config
	var me0 := str(cfg0.get("player_char", "player"))
	Cards.duel_backs = [Cards.player_back() if (me0 == "player" or Settings.sleeve != "default") else Cards.back_for_char(me0),
			Cards.back_for_char(str(cfg0.get("opponent", "kaiba")))]
	get_viewport().physics_object_picking = true
	Pad.walk_mode = false
	Pad.both_sticks = true
	Pad.hint("X  next phase     Y Y  end turn")
	Music.play("duel")
	DuelAudio.reset()
	# A duel is the loud part of the game: music and effects come up, the crowd is in the room.
	Sfx.boost_db = 4.0
	Music.set_boost(3.5)
	board = DuelBoard.new()
	board.theme = FieldThemes.resolve(str(cfg0.get("field", Settings.field_theme)), str(cfg0.get("opponent", "kaiba")))
	if cfg0.get("turbo", false):
		board.turbo = true
		board.theme = {"key": "highway", "name": "New Domino Highway", "base": Color("05070d"), "accent": Color("ff8a3a"), "accent2": Color("2de2e6"),
			"pattern": 1, "sky_top": Color("03040a"), "sky_horizon": Color("26163a"), "fog": Color("0c0a18")}
		Music.play("turbo")
		Sfx.ambience("engine", -21.0)
		Sfx.ambience_pitch(0.8)
	add_child(board)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = DuelHUD.new()
	hud.theme = UITheme.build()
	layer.add_child(hud)
	board.card_clicked.connect(_on_board_card_clicked)
	board.card_hovered.connect(_on_board_card_hovered)
	board.direct_clicked.connect(_on_direct_attack)
	board.ace_summoned.connect(func(inst):
		Sfx.play("gong", -9.0, 1.2)
		Sfx.play("rare", -8.0)
		if inst == _shown:
			return   # it already had its own arrival (SummonShow)
		hud.summon_cinematic(inst.cname(), int(inst.data.get("atk", 0)), int(inst.data.get("def", 0)),
			board._frame_color(inst), inst.owner == ME))
	hud.hand_card_pressed.connect(_on_hand_card_pressed)
	hud.hand_drag.connect(_on_hand_drag)
	hud.can_drag = func(inst): return _my_turn() and mode == "" and not _drop_plan(inst).is_empty()
	hud.drop_handler = _on_hand_drop
	board.deck_clicked.connect(_on_deck_clicked)
	board.pile_clicked.connect(func(p): hud.show_piles(p))
	hud.hand_card_hovered.connect(func(inst): hud.inspect(inst))
	hud.phase_button.connect(_on_phase_button)
	hud.action_chosen.connect(_on_action)
	hud.cancel_pressed.connect(_cancel_mode)
	hud.direct_attack_pressed.connect(_on_direct_attack)
	hud.pause_action.connect(_on_pause_action)
	hud.extra_pressed.connect(_on_extra_pressed)
	board.extra_clicked.connect(_on_extra_pressed)
	hud.speed_pressed.connect(_on_speed_pressed)
	hud.extra_chosen.connect(_on_extra_chosen)
	_start()


func _debug_cine() -> void:
	await get_tree().create_timer(4.0).timeout
	var inst = state._make(89631139, ME)
	if "--battle-demo" in OS.get_cmdline_user_args():
		# Two monsters on the field, ours attacks theirs and it shatters.
		var foe = state._make(89631139, AI)
		await board.anim_summon(ME, inst, 2, false)
		await board.anim_summon(AI, foe, 2, false)
		await board.anim_declare(ME, inst, foe)
		await board.anim_battle(ME, inst, foe)
		await board.anim_destroy(foe)
		if "--fx-demo" in OS.get_cmdline_user_args():
			# Every strike kind, then the signature card effects, one after another.
			for id in [6368038, 70781052, 46986414, 89631139, 13039848]:
				StrikeFx.play(board, state._make(id, ME), board.monster_zone_pos(ME, 2), board.monster_zone_pos(AI, 2))
				await get_tree().create_timer(1.0).timeout
			for nm in ["Raigeki", "Dark Hole", "Mirror Force", "Swords of Revealing Light", "Monster Reborn", "Magic Cylinder"]:
				StrikeFx.card(board, nm, ME)
				await get_tree().create_timer(1.3).timeout
		return
	board.hologram(inst, board.monster_zone_pos(ME, 2))


func _start() -> void:
	print("DUEL START vs ", Router.duel_config.get("opponent", "?"), " cfg keys ", Router.duel_config.keys())
	if "--cine" in OS.get_cmdline_user_args() or "--battle-demo" in OS.get_cmdline_user_args():
		_debug_cine()
	var cfg: Dictionary = Router.duel_config
	if OcgTable.wanted(cfg):
		state = OcgMirror.new()
		ocg = OcgTable.new(self)
		ocg.level = OcgTable.level_for(cfg)
		print("DUEL ENGINE new, opponent level ", ocg.level)
	_opp_key = cfg.get("opponent", "kaiba")
	Avatars.dress = {}
	if str(cfg.get("opponent_coat", "")) != "":
		Avatars.dress[_opp_key] = str(cfg["opponent_coat"])
	if str(cfg.get("player_coat", "")) != "":
		Avatars.dress[str(cfg.get("player_char", "player"))] = str(cfg["player_coat"])
	_ai_level = int(cfg.get("difficulty", 1))
	# Who you face decides how they play and what you hear.
	var mood := str(Characters.get_char(_opp_key).get("personality", ""))
	DuelAI.styles = ["", DuelAI.style_for(_opp_key)]
	var opp_ace := int(Characters.get_char(_opp_key).get("ace", 0))
	if opp_ace == 0:
		opp_ace = int(CardData.NAME_TO_ID.get(str(Characters.get_char(_opp_key).get("ace_name", "")).to_lower(), 0))
	DuelAI.aces = [0, opp_ace]
	if not cfg.get("turbo", false):
		_theme = {"cocky": "duel_rival", "cool": "duel_rival", "dark": "duel_dark", "wild": "duel_wild"}.get(mood, "duel")
		# A boss brings their own music.
		if cfg.has("music"):
			_theme = str(cfg["music"])
		Music.play(_theme)
		DuelAudio.theme = _theme
	var opp: Dictionary = Characters.get_char(_opp_key)
	var my_deck: String = cfg.get("player_deck", "yugi")
	var opp_deck: String = cfg.get("opponent_deck", opp.get("deck", "kaiba"))
	var opp_name: String = str(cfg.get("opponent_name", opp.get("name", "Rival")))
	_me_key = cfg.get("player_char", "player")
	var me_info := Portraits.info(_me_key)
	var me_name: String = me_info.get("name", Profile.duelist_name)
	hud.set_names(me_name, opp_name)
	hud.set_portraits(_me_key, _opp_key)
	var first := randi() % 2
	_puzzle = Puzzles.by_id(str(cfg.get("puzzle", "")))
	if not _puzzle.is_empty():
		cfg["first"] = ME
		opp_name = Loc.t("Puzzle")
		hud.set_names(me_name, opp_name)
	var ms: Dictionary = Router.match_state if cfg.get("match", false) else {}
	if not _autoplay and not ms.is_empty() and int(ms.get("last_loser", -1)) >= 0:
		# In a Match the loser of the last duel decides who starts.
		hud.banner(Loc.t("MATCH  ·  DUEL %d") % int(ms["game"]), UITheme.GOLD)
		if int(ms["last_loser"]) == ME:
			first = ME if await hud.ask_choice("You lost the last duel, so you choose", ["Go first", "Go second"]) == 0 else AI
		else:
			first = AI
	elif not _autoplay and not cfg.has("first"):
		# A coin toss or rock-paper-scissors, played out: the winner decides who starts.
		if _human_test or "--end-test" in OS.get_cmdline_user_args() or "--skip-opening" in OS.get_cmdline_user_args():
			first = int(cfg.get("first_turn", randi() % 2))
		else:
			# The opening plays on the field itself: a look at each duelist with their name
			# across the bottom, the two of them squared up, VS, and the game for the first turn
			# right there between them.
			board.add_duelists(_me_key, _opp_key)
			hud.set_chrome(false)
			var dz := DuelBoard.DUELIST_Z
			var opp_col := Color(opp.get("color", UITheme.DANGER))
			var me_col: Color = me_info.get("color", Profile.color())
			var opp_sub: String = Loc.t("%s Deck") % CardData.deck_name(opp_deck)
			if str(opp.get("title", "")) != "":
				opp_sub = "%s  ·  %s" % [Loc.t(str(opp["title"])), opp_sub]
			board.cam_cut(Vector3(2.4, 1.25, -dz + 4.8), Vector3(0.0, 1.5, -dz))
			board.cam_drift(Vector3(1.3, 1.5, -dz + 3.4), 2.6)
			await get_tree().create_timer(0.3).timeout
			hud.name_plate(1, opp_name, opp_sub, opp_col, 1.9, Loc.t(Characters.line(_opp_key, "intro")))
			board.duelist_gesture(1, "intro")
			await get_tree().create_timer(2.5).timeout
			board.cam_cut(Vector3(-2.4, 1.25, dz - 4.8), Vector3(0.0, 1.5, dz))
			board.cam_drift(Vector3(-1.3, 1.5, dz - 3.4), 2.2)
			hud.name_plate(0, me_name, Loc.t("%s Deck") % CardData.deck_name(my_deck), me_col, 1.5, Loc.t(Characters.line(_me_key, "intro")))
			board.duelist_gesture(0, "intro")
			await get_tree().create_timer(2.0).timeout
			# Over your shoulder, the whole field between you and them.
			board.cam_cut(Vector3(3.0, 2.5, dz + 3.9), Vector3(-2.4, 1.2, -dz))
			board.cam_drift(Vector3(2.6, 2.7, dz + 3.5), 8.0)
			await hud.vs_slam(me_col, opp_col)
			if cfg.has("first_turn"):
				# Already settled on the road (the ride into a Turbo Duel): no game for it.
				first = int(cfg["first_turn"])
				await get_tree().create_timer(0.5).timeout
			else:
				var og := OpeningGame.new()
				og.board = board
				og.me_key = _me_key
				og.opp_key = _opp_key
				og.me_name = me_name
				og.opp_name = str(opp.get("short", opp_name)) if str(opp.get("short", "")) != "" else opp_name
				og.me_color = me_info.get("color", Profile.color())
				og.opp_color = Color(opp.get("color", Color("ff5a6e")))
				hud.add_child(og)
				first = ME if await og.finished else AI
			_opened = true
			board.cam_release(1.1)
			hud.set_chrome(true)
	if _autoplay and cfg.has("first_turn"):
		first = int(cfg["first_turn"])
	if "--first=me" in OS.get_cmdline_user_args():
		first = ME
	state.defer_fx = true
	state.turbo = cfg.get("turbo", false)
	if state.turbo:
		hud.enable_turbo()
		hud.speed_need = func(inst): return state.speed_need(inst)
	state.manual = [not _autoplay, false]
	hud.auto_answer = _human_test
	# (A street duelist with "Yusei's deck" plays the plain version; only Yusei plays his own.)
	# (In Free Duel, a deck you hand the opponent yourself is the real one.)
	var opp_plain := SignatureDecks.borrowed(opp_deck, _opp_key) and not bool(cfg.get("opponent_deck_full", false))
	var opp_list := CardData.legend_deck(opp_deck, opp_plain) if _ai_level >= 2 else CardData.deck_list(opp_deck, opp_plain)
	var extra_hand := int(cfg.get("hand", 5)) - 5
	state.bonus_cards = [extra_hand, extra_hand + (1 if _ai_level >= 2 and ocg == null else 0)]   # (on the new engine the opponent's edge is how it thinks, not an extra card)
	# Destiny Draw: as the Free Duel screen says, else as Settings says. Never in a puzzle.
	# You always have it; of your opponents, the strong ones do: 4 and 5 stars, and story bosses.
	state.destiny = bool(cfg.get("destiny", Settings.destiny_draw)) and str(cfg.get("puzzle", "")) == ""
	state.destiny_who = [true, bool(cfg.get("destiny_opp", _ai_level >= 3 or (_ai_level >= 2 and bool(cfg.get("rare", false)))))]
	if "--destiny-all" in OS.get_cmdline_user_args():
		state.destiny_who = [true, true]   # dev: both sides may, whatever the difficulty
	board.state_ref = state
	var my_list: Array[int] = CardData.deck_list(my_deck)
	if state.turbo:
		# Every runner carries a kit of Speed Spells on top of the rider's own deck: the two
		# starters always, plus four more that change from duel to duel.
		for side_list in [my_list, opp_list]:
			var kit: Array = CardData.SPEED_SPELLS.slice(2)
			kit.shuffle()
			for id in [CardData.SPEED_SPELLS[0], CardData.SPEED_SPELLS[0], CardData.SPEED_SPELLS[1]] + kit.slice(0, 4):
				side_list.append(int(id))
	var events: Array
	if not _puzzle.is_empty() and ocg != null:
		# The position is handed to the engine as it stands: your hand, both fields, the Graveyards.
		first = ME
		var lay := {"hand": [Puzzles.hand_ids(_puzzle), []], "mons": [[], []], "gy": [[], []]}
		for side in 2:
			for pair in _puzzle.get("mine" if side == 0 else "theirs", []):
				(lay["mons"][side] as Array).append([Puzzles._id(str(pair[0])), str(pair[1])])
			for n in _puzzle.get("my_gy" if side == 0 else "their_gy", []):
				(lay["gy"][side] as Array).append(Puzzles._id(str(n)))
		ocg.puzzle = true
		ocg.prepare([], Puzzles.filler_ids(), [], [], me_name, opp_name, first, [0, 5], lay, {"flags": OcgCore.ATTACK_FIRST_TURN})
		events = []
		cfg["my_lp"] = int(_puzzle.get("my_lp", 4000))
		cfg["opp_lp"] = int(_puzzle.get("opp_lp", 4000))
	elif not _puzzle.is_empty():
		first = ME
		events = Puzzles.begin(state, _puzzle)
		state.players[ME].name = me_name
		state.players[AI].name = opp_name
		cfg["my_lp"] = int(_puzzle.get("my_lp", 4000))
		cfg["opp_lp"] = int(_puzzle.get("opp_lp", 4000))
	elif ocg != null:
		var speed0 := [0, 0]
		if state.turbo:
			var tune0 := int(Collection.record.get("runner_tune", 0))
			if cfg.has("speed_start"):
				speed0 = [int((cfg["speed_start"] as Array)[0]), int((cfg["speed_start"] as Array)[1])]
			elif tune0 > 0 and not _autoplay:
				speed0 = [tune0, 0]
		ocg.prepare(my_list, opp_list, CardData.extra_list(my_deck), CardData.extra_list(opp_deck, opp_plain), me_name, opp_name, first,
				[5 + int(state.bonus_cards[ME]), 5 + int(state.bonus_cards[AI])], {"turbo": state.turbo},
				{"speed": speed0, "destiny": [state.destiny and state.destiny_who[ME], state.destiny and state.destiny_who[AI]]})
		events = []
	else:
		events = state.setup(my_list, opp_list, me_name, opp_name, first, -1,
				CardData.extra_list(my_deck), CardData.extra_list(opp_deck, opp_plain))
	# Grand Prix: your lap decides how many Speed Counters each rider starts with.
	if state.turbo and cfg.has("speed_start") and ocg == null:
		for p in 2:
			state.players[p].speed = clampi(int((cfg["speed_start"] as Array)[p]), 0, DuelState.SPEED_MAX)
			hud.set_speed(p, state.players[p].speed, 0)
	# A runner tuned at the Satellite garage starts with Speed Counters already on the dial.
	var tune := int(Collection.record.get("runner_tune", 0))
	if state.turbo and tune > 0 and not cfg.has("speed_start") and not _autoplay and ocg == null:
		state.players[ME].speed = clampi(state.players[ME].speed + tune, 0, DuelState.SPEED_MAX)
		hud.set_speed(ME, state.players[ME].speed, 0)
	# House rules from Free Duel: starting Life Points (and what a Gauntlet carried over).
	_start_lp = [int(cfg.get("lp", DuelState.START_LP)), int(cfg.get("lp", DuelState.START_LP))]
	if cfg.has("my_lp"):
		_start_lp[ME] = int(cfg["my_lp"])
	if cfg.has("opp_lp"):
		_start_lp[AI] = int(cfg["opp_lp"])
	if "--destiny-low" in OS.get_cmdline_user_args():
		_start_lp[ME] = 1500   # dev: you start in trouble, so the Destiny Draw offer comes on your first draw
	# A burger set from Burger World: 500 extra Life Points, once.
	if Router.roam.get("fed", false) and not _autoplay:
		Router.roam["fed"] = false
		_start_lp[ME] += 500
		get_tree().create_timer(3.0).timeout.connect(func(): Router.toast(Loc.t("Well fed: +500 Life Points.")))
	for p in 2:
		if _start_lp[p] != DuelState.START_LP:
			state.players[p].lp = _start_lp[p]
			hud.set_lp(p, _start_lp[p], 0)
	for p in 2:
		board.set_deck_count(p, state.players[p].deck.size() + (0 if ocg != null else 5 + state.bonus_cards[p]))
	_update_counts()
	hud.set_phase_buttons("", false, false)
	hud.set_extra_button(state.players[ME].extra.size(), 0, false)
	board.set_extra_count(ME, state.players[ME].extra.size(), 0)
	board.set_extra_count(AI, state.players[AI].extra.size())
	if not _opened:
		board.add_duelists(_me_key, _opp_key)
	var fly := "--no-fly" not in OS.get_cmdline_user_args()
	_bring_spirit()
	if _opened:
		await get_tree().create_timer(0.7).timeout
	elif not _autoplay:
		if fly:
			board.intro_hold()
		hud.name_plate(1, opp_name, Loc.t("%s Deck") % CardData.deck_name(opp_deck), Color(opp.get("color", UITheme.DANGER)), 1.4)
		board.duelist_gesture(1, "intro")
		_talk(AI, "intro", 1.0, 0.0)
		if fly:
			await board.intro_duelists()
		# Boss rules are said out loud before the first draw.
		if cfg.has("rule"):
			hud.effect_text(Loc.t(str(cfg["rule"])))
			await hud.banner("SPECIAL RULE", UITheme.GOLD, true)
		get_tree().create_timer(2.5).timeout.connect(func(): _lumen("start"))
	else:
		if fly:
			board.intro_flyover(2.5)
		await get_tree().create_timer(0.5).timeout
		_talk(AI, "intro", 1.0, 0.0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--rider-shot="):
			var rs := int(a.substr(13))
			board.duelist_shot(rs, 0.1)
			for k in 12:
				if "--pose-lose" in OS.get_cmdline_user_args():
					(board._duelists[rs] as RoamFigure).play_once("lose")
				else:
					board.duelist_gesture(rs, "intro")
				await get_tree().create_timer(2.5).timeout
	await hud.banner("DUEL!", Comic.YELLOW)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cutin="):
			# Dev: hold a cut-in on screen for a screenshot. me | opp | big | hit
			var what := a.trim_prefix("--cutin=")
			get_tree().create_timer(5.0).timeout.connect(func():
				if what == "say":
					hud.say(0, "My turn. Draw!")
					hud.say(1, "You're wasting my time. Let's get this over with.")
				elif what == "hit":
					hud.impact(Vector3(0, 0.3, -1.5), Color("ff5a7a"), 1.0)
					hud._float_number(1, -2400)
				elif what == "opp":
					hud.cut_in(1, "BLUE-EYES WHITE DRAGON", "Attack!", Color("ff5a7a"), 30.0)
				elif what == "big":
					hud.cut_in(0, "DARK MAGICIAN", "ATK 2500   ·   DEF 2100", Color("a070ff"), 30.0, true)
				else:
					hud.cut_in(0, "TRAP CARD!", "Mirror Force", Color("ff4dd2"), 30.0))
	if "--ask-test" in OS.get_cmdline_user_args():
		await _play(events)
		var lab := {}
		for h in state.players[ME].hand:
			lab[h.uid] = "Your hand"
		if "--ask-gy" in OS.get_cmdline_user_args():
			# Dev: a full graveyard and a couple of banished cards, with the viewer open.
			var mine: DuelState.PlayerState = state.players[ME]
			for k in mini(7, mine.deck.size()):
				mine.gy.append(mine.deck.pop_back())
			for k in mini(2, mine.deck.size()):
				mine.banished.append(mine.deck.pop_back())
			_refresh()
			hud.show_piles(ME)
			return
		if "--ask-respond" in OS.get_cmdline_user_args():
			# Dev: the question you get when a Trap can answer an attack.
			hud.ask_why = Loc.t("Your opponent declared an attack. A Trap or Quick-Play Spell can answer it before it lands. Pick a card to use it, or let the attack go through.")
			await hud.ask_response("Your opponent attacks. Respond?", state.players[ME].hand.slice(0, 2))
			return
		if "--ask-mode" in OS.get_cmdline_user_args():
			# Dev: a card with two effects asks which one you want.
			await hud.ask_choice(Loc.t("%s: choose an effect") % "Enemy Controller", ["Change a monster's battle position", "Tribute 1 monster: take control of a monster until the End Phase"], state.players[ME].hand[0])
			return
		if "--ask-choice" in OS.get_cmdline_user_args():
			await hud.ask_choice(Loc.t("Special Summon %s in:") % state.players[ME].hand[0].cname(), ["Attack Position", "Defense Position"], state.players[ME].hand[0])
		else:
			await hud.ask_pick("Hand limit: discard 2 cards   (1 of 2)", state.players[ME].hand, "Select", "", [], lab)
		return
	if "--end-test" in OS.get_cmdline_user_args():
		state.winner = AI if "--lose" in OS.get_cmdline_user_args() else ME
		state.win_reason = "Test finish."
		if "--blow" in OS.get_cmdline_user_args() and board.track != null:
			# Dev: the slow motion last hit of a Turbo Duel, a few seconds in so a picture can catch it.
			await get_tree().create_timer(4.0).timeout
			board.track.finish(Color(1.0, 0.82, 0.3))
			board.turbo_blow(AI if state.winner == ME else ME)
		_finish()
		return
	if ocg != null:
		events = ocg.begin()
	await _play(events)
	if not _puzzle.is_empty() and ocg != null:
		_update_counts()
		hud.effect_text(Loc.t(str(_puzzle.get("hint", ""))))
		await hud.banner("WIN THIS TURN", UITheme.GOLD, true)
		_loop()
		return
	if not _puzzle.is_empty():
		# The position is laid out, then it is your move: this turn is the only one you get.
		Settings.pace = 0.45
		await _play(Puzzles.place(state, _puzzle))
		Settings.pace = 1.0
		_update_counts()
		hud.effect_text(Loc.t(str(_puzzle.get("hint", ""))))
		await hud.banner("WIN THIS TURN", UITheme.GOLD, true)
		_loop()
		return
	await hud.banner("You go first" if first == ME else Loc.t("%s goes first") % opp.get("short", opp_name), UITheme.TEXT)
	_loop()


func _speaker(p: int) -> String:
	return _me_key if p == ME else _opp_key


# ------------------------------------------------------------------ Destiny Draw

const DestinyShow := preload("res://scripts/duel/destiny_show.gd")
var _destiny_card = null          # the card the show has already drawn: its draw event is quiet


## Before a turn begins: a duelist in trouble may reach for the card they need (once per duel).
## You are asked; the computer decides for itself. Then the moment plays, and the Draw Phase
## that follows draws that card.
func _destiny_step() -> void:
	var p: int = state.current
	if "--destiny-dbg" in OS.get_cmdline_user_args():
		print("DDBG p ", p, " can ", state.can_destiny(p), " on ", state.destiny, " who ", state.destiny_who, " used ", state.destiny_used, " turn ", state.turn, " lp ", state.players[p].lp, " skip ", state.players[p].skip_draw, " fin ", _finished)
	if not state.can_destiny(p) or _finished:
		return
	var pick = null
	if p == ME and not _autoplay:
		if _human_test:
			pick = state.players[ME].deck[randi() % state.players[ME].deck.size()]
		else:
			_lumen("destiny")
			if not await hud.ask_destiny():
				return
			var seen := {}
			var opts: Array = []
			for c in state.players[ME].deck:
				if not seen.has(c.cname()):
					seen[c.cname()] = true
					opts.append(c)
			var rank := func(c) -> int: return 0 if c.is_monster() else (1 if c.is_spell() else 2)
			opts.sort_custom(func(a, b): return rank.call(a) < rank.call(b) if rank.call(a) != rank.call(b) else (a.atk() > b.atk() if a.is_monster() and a.atk() != b.atk() else a.cname() < b.cname()))
			pick = await hud.ask_pick(Loc.t("Destiny Draw: choose the card you draw"), opts, "Draw this card", "Not now")
			if pick == null:
				return
	else:
		pick = DuelAI.pick_destiny(state, p)
	if pick == null or not state.set_destiny(p, pick):
		return
	_destiny_card = pick
	print("DESTINY ", p, " ", pick.cname())
	if _autoplay or (_human_test and not "--destiny-show" in OS.get_cmdline_user_args()):
		return
	hud.hide_actions()
	var who_name: String = state.players[p].name
	board.duelist_body(p, "draw")
	await DestinyShow.play(hud, {
		"side": p, "key": str(hud.portrait_keys[p]), "who": who_name,
		"color": UITheme.ACCENT if p == ME else Comic.RED,
		"back": Cards.duel_back(p), "face": Cards.get_face(pick.id) if p == ME else null, "name": pick.cname() if p == ME else "",
		"spirit": LumenSpirit.portrait(self) if (p == ME and _me_key == "player" and LumenBubble.with_you()) else null,
	})
	if p == AI:
		_lumen("their_destiny")


## Dev: the Destiny Draw offer ("--demo-destiny=ask") or the moment itself, stopped at a stage
## ("deck", "lift", "title", "face"; "opp..." for the opponent's).
func _demo_destiny(stage: String) -> void:
	await get_tree().create_timer(1.0).timeout
	if stage == "ask":
		hud.ask_destiny()
		return
	var theirs := stage.begins_with("opp")
	var dc = state.players[AI if theirs else ME].deck[0]
	for c in state.players[ME].deck:
		if c.is_monster() and c.level() >= 7:
			dc = c
	var dp := AI if theirs else ME
	DestinyShow.play(hud, {"side": dp, "key": str(hud.portrait_keys[dp]), "who": state.players[dp].name, "color": UITheme.ACCENT if dp == ME else Comic.RED,
		"back": Cards.duel_back(dp), "face": null if theirs else Cards.get_face(dc.id), "name": dc.cname(),
		"spirit": null if theirs else LumenSpirit.portrait(self), "freeze": stage.trim_prefix("opp")})


func _loop() -> void:
	if "--count-meshes" in OS.get_cmdline_user_args():
		# Dev: what the duel scene is made of, by branch (each MeshInstance3D is at least one draw call).
		var tally := {}
		for mi in find_children("*", "GeometryInstance3D", true, false):
			if not (mi as GeometryInstance3D).is_visible_in_tree():
				continue
			var path := str(get_path_to(mi)).split("/")
			var key := "/".join(path.slice(0, mini(3, path.size() - 1)))
			tally[key] = int(tally.get(key, 0)) + 1
		var keys := tally.keys()
		keys.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
		var all_n := 0
		for k in keys:
			all_n += int(tally[k])
		print("MESHES TOTAL ", all_n, " in ", keys.size(), " branches")
		var kinds := {}
		var mats := {}
		for mi in find_children("*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).is_visible_in_tree() and (mi as MeshInstance3D).mesh != null and mi.get_parent().name == "Arena":
				var kc := (mi as MeshInstance3D).mesh.get_class() + ("+kids" if mi.get_child_count() > 0 else "")
				var mm: Material = (mi as MeshInstance3D).material_override if (mi as MeshInstance3D).material_override else (mi as MeshInstance3D).mesh.surface_get_material(0)
				kc += " " + (mm.get_class() if mm else "nomat") + (" glow" if mm is BaseMaterial3D and (mm as BaseMaterial3D).emission_enabled else "") + (" alpha" if mm is BaseMaterial3D and (mm as BaseMaterial3D).transparency != 0 else "")
				kinds[kc] = int(kinds.get(kc, 0)) + 1
				if mm:
					mats[mm.get_instance_id()] = true
		print("MESHES in Arena by kind ", kinds, " distinct materials ", mats.size())
		for k in keys.slice(0, 8):
			print("MESHES ", tally[k], "  ", k)
		get_tree().quit()
		return
	for da in OS.get_cmdline_user_args():
		if da.begins_with("--demo-destiny"):
			_demo_destiny(da.trim_prefix("--demo-destiny").trim_prefix("="))
			return
	if ocg != null:
		await ocg.loop()
		_finish()
		return
	while not state.is_over():
		# Draw Phase, Standby Phase, then Main Phase 1. Both players may act in each.
		await _destiny_step()
		await _act("begin_turn", [true])
		if state.is_over():
			break
		await _phase_window("Draw Phase")
		if not state.is_over():
			await _act("begin_standby", [])
			await _phase_window("Standby Phase")
		if state.is_over():
			break
		await _act("begin_main1", [])
		if state.current == AI or _autoplay or _human_test:
			await _ai_turn(state.current)
			Settings.pace = 1.0
		else:
			Settings.pace = 1.0
			_turn_done = false
			_refresh()
			if "--demo-actions" in OS.get_cmdline_user_args():
				_demo_actions()
			await _turn_finished
		if state.is_over():
			break
		_cancel_mode()
		if not _puzzle.is_empty():
			# The one turn is over and they are still standing.
			state._set_winner(AI, "The turn ended and they are still standing.")
			break
		await _act("begin_end", [])
		await _phase_window("End Phase")
		if state.is_over():
			break
		await _act("finish_turn", [])
	_finish()


## A chance for both players to act in a phase (the turn player first).
func _phase_window(phase_name: String) -> void:
	if state.is_over() or _finished:
		return
	await _window(state.current, "phase", null, Loc.t("%s. Activate a card?") % phase_name)


# ------------------------------------------------------------------ running the rules

## Run a rules action for real. Every choice it leaves to the human (a discard, a target, a
## material, a position) is found first by trying the action on a copy of the duel, asked,
## then replayed in the same order. Nothing is picked for you.
func _run(fn: Callable, args: Array = [], settle := true) -> Array:
	var answers: Array = []
	if not _autoplay:
		var guard := 0
		while guard < 30:
			guard += 1
			var sim := state.clone()
			sim.manual = state.manual.duplicate()
			sim.answers = answers.duplicate(true)
			fn.call(sim, _map(sim, args))
			if sim.need == null:
				break
			answers.append(await _ask(sim.need))
	state.answers = answers
	state.need = null
	var ev: Array = fn.call(state, args)
	state.answers = []
	await _play(ev)
	if settle:
		await _settle()
	return ev


func _act(method: String, args: Array = [], settle := true) -> Array:
	return await _run(func(st, a): return st.callv(method, a), args, settle)


## The same cards / chain links inside a copy of the duel.
func _map(st: DuelState, v):
	if st == state:
		return v
	if v is DuelState.CardInst:
		return st.find_uid(v.uid)
	if v is Array:
		var out: Array = []
		for x in v:
			out.append(_map(st, x))
		return out
	if v is Dictionary:
		var idx := state.chain.find(v)
		if idx != -1 and idx < st.chain.size():
			return st.chain[idx]
		var d := {}
		for k in v:
			d[k] = _map(st, v[k])
		return d
	return v


func _where(c) -> String:
	for q in 2:
		var ps: DuelState.PlayerState = state.players[q]
		var who := "Your" if q == ME else "Their"
		if ps.hand.has(c): return who + Loc.t(" hand")
		if ps.field.has(c) or ps.spells.has(c) or ps.field_spell == c: return who + Loc.t(" field")
		if ps.gy.has(c): return who + Loc.t(" Graveyard")
		if ps.deck.has(c): return who + " Deck"
		if ps.banished.has(c): return who + Loc.t(" banished")
		if ps.extra.has(c): return who + Loc.t(" Extra Deck")
	return ""


## Put one decision in front of the player. Returns card uids, or [index] for an option.
func _ask(need: Dictionary) -> Array:
	var was := _flow
	_flow = true
	if _human_test:
		var key := str(need["prompt"]).get_slice(":", 0).left(28)
		_asked[key] = int(_asked.get(key, 0)) + 1
	var src = state.find_uid(int(need.get("source", -1)))
	if need.has("options"):
		var idx: int = await hud.ask_choice(str(need["prompt"]), need["options"], src)
		_flow = was
		return [idx]
	var cands: Array = []
	for uid in need["cands"]:
		var x = state.find_uid(int(uid))
		if x != null:
			cands.append(x)
	var n: int = int(need["n"])
	var picked: Array = []
	while picked.size() < n and not cands.is_empty():
		var text := str(need["prompt"])
		if n > 1:
			text += Loc.t("   (%d of %d)") % [picked.size() + 1, n]
		var hidden: Array = []
		var labels := {}
		for x in cands:
			labels[x.uid] = _where(x)
			if x.owner != ME and not x.face_up and (state.players[AI].field.has(x) or state.players[AI].spells.has(x)):
				hidden.append(x)
			elif state.players[AI].hand.has(x):
				hidden.append(x)
		var got = await hud.ask_pick(text, cands, "Select", "Skip" if need.get("optional", false) else "", hidden, labels)
		if got == null:
			picked = []
			break
		picked.append(got.uid)
		cands.erase(got)
	_flow = was
	return picked


## Effects that triggered and are waiting go on a chain, and the chain plays out.
func _settle() -> void:
	if not state.pending_fx.is_empty() and not state.is_over() and not _finished:
		await _window(state.opponent(state.current), "chain", null, "")


func _finish() -> void:
	if _finished:
		return
	_finished = true
	# A duel takes an hour of the day (puzzles are off the clock).
	if _puzzle.is_empty():
		WorldClock.add_minutes(WorldClock.DUEL_COST)
		WorldClock.save_data()
	_cancel_mode()
	hud.set_phase_buttons("", false, false)
	hud.set_playable([])
	await get_tree().create_timer(0.6).timeout
	# A Turbo Duel's last hit plays out in slow motion first.
	while board.track != null and board.track.blow_busy:
		await get_tree().process_frame
	var won := state.winner == ME
	var tied := state.winner == DuelState.DRAW
	if "--auto-story" in OS.get_cmdline_user_args():
		get_tree().create_timer(2.0).timeout.connect(func():
			Router.story_result = "won" if state.winner == ME else "lost"
			Router.go(Router.duel_config.get("return_to", Router.STORY)))
	if _human_test:
		print("PROMPTS: ", _asked)
	print("DUEL OVER: winner %d (%s) LP %d vs %d turn %d" % [state.winner, state.win_reason, state.players[0].lp, state.players[1].lp, state.turn])
	Router.last_stats = {"won": won and not _surrendered, "lp": int(state.players[ME].lp), "turns": int(state.turn), "low": int(_my_low)}
	var earned := 0
	if not _puzzle.is_empty():
		# A puzzle is not a duel on your record: solving it pays once, and that is all.
		if won:
			earned = Puzzles.mark(str(_puzzle["id"]))
			Collection.last_reward = [["Puzzle solved", earned]] if earned > 0 else []
	elif not _autoplay:
		Profile.record_result(won)
		var my_lp: int = state.players[ME].lp
		var rinfo := {}
		if Router.duel_config.has("stake"):
			rinfo["stake"] = int(Router.duel_config["stake"])   # what they put on the line when they challenged you
		earned = Collection.reward(won and not _surrendered, _ai_level, rinfo.merged({"opponent": _opp_key, "lp": my_lp,
			"flawless": my_lp >= int(_start_lp[ME]), "turns": state.turn,
			"deck": str(Router.duel_config.get("opponent_deck", Characters.get_char(_opp_key).get("deck", ""))), "rare": bool(Router.duel_config.get("rare", false))}))
		if won:
			Router.duel_config.erase("stake")   # it changed hands: a rematch is not for the same card
		# Free Duel: the medals this win earned against them (each pays once).
		if won and not _surrendered and not Router.duel_config.has("return_to") and not Router.duel_config.get("story", false):
			earned += Collection.award_medals(_opp_key, {"low": _my_low, "my_turns": _my_turns, "my_start": int(_start_lp[ME]), "their_start": int(_start_lp[AI])})
		# The duel of the day pays the first time it is won that day.
		if won and not _surrendered and Router.duel_config.has("daily"):
			earned += Knockout.daily_win(str(Router.duel_config["daily"]))
		var g_lines := Goals.after_duel(won and not _surrendered and not tied, _ai_level, {"flawless": my_lp >= int(_start_lp[ME]),
				"turbo": board.track != null, "opponent": _opp_key, "draw": tied}, _tally)
		for line in g_lines:
			earned += int(line[1])
		Collection.last_reward.append_array(g_lines)
		var got := Collection.note_result(_opp_key, won and not _surrendered)
		if got != "":
			Router.toast(Loc.t("Third win over %s: their deck is now in My Decks.") % str(Characters.get_char(_opp_key).get("short", _opp_key)))
	Sfx.play("win" if won else "lose")
	Music.play("victory" if won else "defeat")
	if won and board.arena != null:
		# Yours: fireworks over the arena, confetti over the field, the house on its feet.
		board.arena.celebrate([Color(board.theme["accent"]), Color("ff5a7a"), Color("ffd84a"), Color(board.theme["accent2"]), Color("5affc0")])
	elif not won and not tied and board.arena != null:
		board.arena.hush()
	elif won and board.track != null:
		board.track.celebrate([Color(board.theme["accent"]), Color("ff5a7a"), Color("ffd84a"), Color(board.theme["accent2"]), Color("5affc0")])
	elif not won and not tied and board.track != null:
		board.track.hush()
	Sfx.play("cheer", -4.0 if won else -12.0)
	hud.say(AI, Characters.line(_opp_key, "lose" if won else "win"))
	# The winner gets the camera.
	var champ := ME if won else AI
	# The loser drops their head first, then the winner gets the camera and celebrates.
	if not tied and not board.track:
		var loser := AI if won else ME
		var lf = board._duelists.get(loser)
		if lf is RoamFigure:
			(lf as RoamFigure).play_once("lose")
		board.duelist_shot(loser, 0.5, false, 0.8)
		await get_tree().create_timer(1.3).timeout
	board.duelist_shot(champ, 0.9, not tied, 1.0)
	await get_tree().create_timer(1.5).timeout
	board.duelist_orbit(champ)
	var cfg: Dictionary = Router.duel_config
	var why: String = "You surrendered." if _surrendered else state.win_reason
	var match_info := {}
	if cfg.get("match", false) and not Router.match_state.is_empty() and not _autoplay:
		var ms: Dictionary = Router.match_state
		if not tied:
			ms["wins"][0 if won else 1] += 1
			ms["last_loser"] = AI if won else ME
		ms["game"] = int(ms["game"]) + 1
		var over: bool = ms["wins"][0] >= 2 or ms["wins"][1] >= 2
		match_info = {"wins": ms["wins"], "over": over, "won": ms["wins"][0] >= 2,
			"side": cfg.get("player_deck", "") == "custom" and not (Collection.side.is_empty() and Collection.main == ms["orig"]["main"])}
		if over:
			if ms["wins"][0] >= 2:
				Collection.dp += 200
				why += Loc.t("
Match won: +%d Duel Points") % 200
			_restore_match_deck()
	# Gauntlet: three duelists in a row on one pool of Life Points.
	var g: Dictionary = cfg.get("gauntlet", {})
	var g_next := false
	if not g.is_empty() and not _autoplay:
		var left: Array = g.get("left", [])
		if g.get("endless", false):
			# Survival: there is always someone next, until you lose.
			g_next = won
			var best := int(Collection.record.get("survival_best", 0))
			var streak := int(g.get("stage", 1)) - (0 if won else 1)
			if streak > best:
				Collection.record["survival_best"] = streak
				Collection.save()
			if won:
				Collection.dp += 60 * int(g.get("stage", 1))
				Collection.save()
			else:
				Router.toast(Loc.t("Survival over: %d wins in a row.  Best: %d") % [streak, maxi(best, streak)])
		elif won and not left.is_empty():
			g_next = true
		elif won:
			Collection.dp += 400
			Collection.save()
			Router.toast(Loc.t("Gauntlet cleared!  +400 Duel Points"))
	hud.gauntlet_next = g_next
	hud.gauntlet_label = "" if g.is_empty() else ((Loc.t("SURVIVAL  ·  duel %d") % int(g.get("stage", 1))) if g.get("endless", false) else (Loc.t("GAUNTLET  ·  duel %d of %d") % [int(g.get("stage", 1)), int(g.get("total", 3))]))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--result-action="):
			# Dev: press one of the result buttons by itself.
			var act := a.trim_prefix("--result-action=")
			get_tree().create_timer(1.0).timeout.connect(func():
				print("RESULT action ", act, " gauntlet_next=", hud.gauntlet_next, " vs=", Collection.versus(_opp_key), " decks=", Collection.decks_owned.size())
				_on_pause_action(act))
	hud.show_result(won, why, cfg.get("story", false), cfg.get("lose_ok", false), cfg.get("continue_label", "Continue Story"),
			{"turns": state.turn, "lp": [state.players[ME].lp, state.players[AI].lp], "names": [state.players[ME].name, state.players[AI].name],
			"reward": Collection.last_reward.duplicate() if earned > 0 else [], "earned": earned,
			"prize": Collection.last_prize if (earned > 0 and won) else 0,
			"free": not cfg.has("return_to") and not cfg.get("story", false), "draw": tied, "match": match_info,
			"task": cfg.get("task", false)})
	_won = won


# ------------------------------------------------------------------ events

func _play(events: Array) -> void:
	busy = true
	_refresh()
	for ev in events:
		await _play_event(ev)
		board.refresh_stats(state)
	busy = false
	_update_counts()
	_sync_field()
	_refresh()
	# A win can happen mid-turn (an attack or a burn spell). Release the turn wait.
	if state.is_over() and not _finished:
		_turn_finished.emit()


var _field_seq := {}       # Field Spell uid -> the order it came into force in
var _field_n := 0
var _field_uid := -1       # the one whose place the field is showing


## The field shows the place of the Field Spell in force: the one played last, if each duelist
## has one. When it leaves, the other one's place takes over, or the field is itself again.
func _sync_field() -> void:
	if board == null or board.turbo or state.players.size() < 2:
		return
	var best = null
	var best_seq := -1
	var owner := 0
	for p in 2:
		var f = state.players[p].field_spell
		if f == null or not f.face_up:
			continue
		if not _field_seq.has(f.uid):
			_field_n += 1
			_field_seq[f.uid] = _field_n
		if int(_field_seq[f.uid]) > best_seq:
			best_seq = int(_field_seq[f.uid])
			best = f
			owner = p
	var uid: int = best.uid if best != null else -1
	if uid == _field_uid:
		return
	_field_uid = uid
	if best == null:
		board.clear_field_look()
		hud.set_field_strip(null, [], Color.WHITE, "")
		board.refresh_stats(state)
		return
	var look := FieldLooks.look_for(best)
	var whose := Loc.t("yours") if owner == ME else state.players[owner].name
	board.set_field_look(look, board.field_pos(owner))
	hud.field_banner(best.cname(), whose, look["glow"])
	hud.set_field_strip(best, FieldLooks.says(best), look["glow"], whose)
	board.refresh_stats(state)


## A duelist says a line and acts it out at the table. `chance` keeps chatter from piling up.
var _last_talk := [-10.0, -10.0]


## Lumen, your partner, has an opinion about the duel. Each kind of remark once per duel.
const LUMEN_SAYS := {
	"start": ["I'm in your deck! Draw me, draw me!", "Okay. Deep breath. I believe in you. Also in me. Mostly you."],
	"me": ["That's me! Hi! One monster for your hand, coming right up!", "I'm on the field! Don't look at my ATK. Look at my heart."],
	"my_ace": ["Ooh, the big one! Get them!", "THERE it is! I love this part!"],
	"their_ace": ["That's their best monster. Don't panic. I'm panicking, but you shouldn't.", "Uh oh. Big. Very big. You have a plan, right?"],
	"ace_down": ["You took down their ace! Did you see their face?!", "Their best monster is GONE! Keep going!"],
	"ace_lost": ["Your ace... okay. Okay! We can still do this.", "It's fine! We have more cards! ...We have more cards, right?"],
	"my_low": ["Your Life Points are low. I'm not worried. *bzzt* I'm a little worried.", "Careful! One more hit like that and we're done!"],
	"their_low": ["They're almost out! One more push!", "They're on the ropes! Finish it!"],
	"hit": ["Ow! That one hurt just to watch.", "Okay, that was a lot of Life Points. We still have the rest!"],
	"direct": ["Right through! Nothing in the way!", "Direct hit! They felt that one!"],
	"trap": ["A Trap! I KNEW that card looked shifty.", "They were waiting for that. Sneaky."],
	"topdeck": ["No cards in hand... so the next one has to count. No pressure!", "Empty hand. This is where the good draws happen. Right? Right."],
	"comeback": ["You're back in it! I never doubted you. *bzzt* Much.", "From almost nothing to THIS? That's my duelist!"],
	"destiny": ["{player}. The Deck is listening. Ask it for the one card you need!", "This is it. One card can turn this around. Reach for it!"],
	"their_destiny": ["They can do that too?! Okay. Okay. Stay sharp.", "That was THEIR big draw. Whatever it is, we can take it."],
}
var _lumen_box: LumenBubble
var _lumen_said := {}
var _lumen_3d: LumenSpirit        # her, floating by your panel (only when you duel as your own duelist)
var _lumen_at := -100.0
var _me_was_low := false


## Your spirit comes to the duel with you: she floats by your panel and talks from there.
func _bring_spirit() -> void:
	if _autoplay or _me_key != "player" or not LumenBubble.with_you() or _lumen_3d != null:
		return
	var got: Array = LumenSpirit.floating(self)
	_lumen_3d = got[1]
	hud.show_spirit((got[0] as SubViewport).get_texture())


func _lumen(kind: String) -> void:
	if _autoplay or _lumen_said.has(kind) or not LumenBubble.with_you() or not LUMEN_SAYS.has(kind):
		return
	# The big moments always get a word; the small ones leave her some quiet in between.
	var now := Time.get_ticks_msec() / 1000.0
	var small: bool = kind in ["hit", "direct", "trap", "topdeck"]
	if small and now - _lumen_at < 14.0:
		return
	if _lumen_box == null:
		_lumen_box = LumenBubble.new(26.0, -380.0 if _lumen_3d != null else -330.0)
		add_child(_lumen_box)
	if _lumen_box.showing():
		return
	_lumen_said[kind] = true
	_lumen_at = now
	var lines: Array = LUMEN_SAYS[kind]
	_lumen_box.say(str(lines[randi() % lines.size()]))
	if _lumen_3d != null:
		_lumen_3d.speak(2.4)
		if kind in ["my_ace", "ace_down", "their_low", "destiny", "direct", "me", "comeback"]:
			_lumen_3d.hop()
		elif kind in ["their_ace", "my_low", "hit", "ace_lost", "their_destiny"]:
			_lumen_3d.glitch(0.3)
		hud.spirit_pop()


## "Kaiba activates Mirror Force" and what it does, at the top of the screen, while the card goes
## straight into its animation.
func _announce(p: int, card, trap: bool) -> void:
	var nm := str(card.data.get("name", ""))
	var txt := str(card.data.get("desc", card.data.get("text", "")))
	if txt == "":
		txt = str(CardData.EXT.get(int(card.id), {}).get("desc", ""))
	var who := Loc.t("You") if p == ME else str(state.players[AI].name)
	var title := (Loc.t("%s activate %s") if p == ME else Loc.t("%s activates %s")) % [who, nm]
	hud.action_caption(("✦  " if not trap else "⚠  ") + title, CardText.gist(nm, txt), Color("ff4dd2") if trap else Color("3fd9a8"), p == ME)


func _talk(p: int, kind: String, chance := 1.0, min_gap := 2.5) -> void:
	if _autoplay or randf() > chance:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_talk[p]) < min_gap:
		return
	var line := Characters.line(_speaker(p) if p == ME else _opp_key, kind)
	if line == "":
		return
	_last_talk[p] = now
	hud.say(p, line)
	board.duelist_gesture(p, kind)


func _play_event(ev: Dictionary) -> void:
	var p: int = ev.get("player", 0)
	# One line per step in the log (it is written out at once, see project.godot), so if the game
	# ever closes in a duel the log shows the last thing it was doing.
	if not _autoplay:
		var evc = ev.get("card")
		print("EV ", ev["type"], " p", p, " ", str(evc.cname()) if evc != null and evc.has_method("cname") else "")
		# Every card you see face-up in a duel goes in the Card Album as "seen".
		if evc != null and "face_up" in evc and evc.face_up and "id" in evc:
			Collection.meet(int(evc.id))
	DuelAudio.on_event(ev, state)
	_feed_event(ev, p)
	match ev["type"]:
		"turn":
			var mine := p == ME
			if mine:
				_my_turns += 1
			Sfx.play("turn")
			if mine and state.players[ME].hand.is_empty() and state.turn > 2:
				_lumen("topdeck")
			if randf() < 0.45:
				_talk(p, "turn", 1.0, 0.0)
			await hud.banner("YOUR TURN" if mine else Loc.t("%s'S TURN") % state.players[AI].name.to_upper(),
					Comic.SKY if mine else Color("ff7a8a"))
		"phase":
			var ph: int = ev["phase"]
			hud.set_phase(ph, state.current == ME, state.turn)
			board.set_battle_mode(ph == DuelState.Phase.BATTLE)
			var names := {DuelState.Phase.BATTLE: "BATTLE PHASE", DuelState.Phase.MAIN2: "MAIN PHASE 2", DuelState.Phase.END: "END PHASE"}
			if names.has(ph):
				var col: Color = UITheme.DANGER if ph == DuelState.Phase.BATTLE else (Comic.BLUE if state.current == ME else Comic.RED)
				await hud.phase_sweep(names[ph], col)
				if ph == DuelState.Phase.END and state.current == AI and randf() < 0.3:
					_talk(AI, "taunt")
		"draw":
			if _destiny_card != null and ev["card"] == _destiny_card:
				# The show already took this card off the Deck: it just lands in the hand.
				_destiny_card = null
				_update_counts()
				if p == ME:
					board.set_deck_count(p, int(ev["deck"]))
					hud.add_hand_card(ev["card"])
				else:
					board.deal_fast = true
					await board.anim_draw(p, ev["card"], ev["deck"])
				return
			_update_counts()
			Sfx.play("draw", -6.0)
			# The opening hands are dealt briskly; a draw during the duel takes its moment.
			board.deal_fast = state.turn <= 0
			if state.turn > 0:
				board.duelist_body(p, "draw")
			await board.anim_draw(p, ev["card"], ev["deck"])
			if p == ME:
				hud.add_hand_card(ev["card"])
		"summon", "set":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			Sfx.play("card")
			var is_ace: bool = ev["type"] == "summon" and (ev["card"].level() >= 7 or ev["card"].id == Characters.get_char(_opp_key).get("ace", 0))
			if ev["type"] == "summon":
				get_tree().create_timer(Settings.t(0.5)).timeout.connect(func(): Sfx.play("summon", -4.0))
			# A big monster arrives: its own show, in its own colors (see SummonShow).
			if ev["type"] == "summon" and _shows and Settings.big_shows and SummonShow.wants(ev["card"].data):
				var sd: Dictionary = (ev["card"].data as Dictionary).duplicate()
				sd["id"] = ev["card"].id
				_shown = ev["card"]
				SummonShow.play(self, sd, p == ME)
				await get_tree().create_timer(Settings.t(1.5)).timeout
			if is_ace:
				_talk(p, "ace", 1.0, 0.0)
				hud.react(p, "ace")
				_lumen("my_ace" if p == ME else "their_ace")
			elif p == ME and ev["type"] == "summon" and ev["card"].id == CardData.LUMEN:
				_lumen("me")
			if ev["type"] == "summon" and _pending_tributes > 0:
				hud.banner("TRIBUTE SUMMON", UITheme.GOLD, true)
			_pending_tributes = 0
			if ev["type"] == "summon":
				board.duelist_body(p, "summon", 1.4 if is_ace else 1.0)
			await board.anim_summon(p, ev["card"], ev["zone"], ev["type"] == "set")
			if p == ME and ev["type"] == "summon" and ev["card"].atk() >= 2000:
				_talk(AI, "react", 0.65)
			elif p == AI and ev["type"] == "summon" and ev["card"].atk() >= 2000:
				_talk(ME, "react", 0.4)
		"tribute":
			_pending_tributes += 1
			Sfx.play("spell", -4.0, 0.8)
			board.hide_stats_for(ev["card"])
			await board.anim_tribute(ev["card"])
		"flip", "reveal":
			await board.anim_flip(p, ev["card"], ev["zone"])
		"position":
			await board.anim_position(p, ev["card"], ev["zone"])
		"activate":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			elif ev["card"].is_trap():
				_lumen("trap")
			hud.inspect(ev["card"])
			Sfx.play("spell")
			_talk(p, "spell", 0.3)
			if SpellRules.kind(ev["card"]) in ["field", "equip", "cont", "ritual", "quick"]:
				var titles := {"field": "FIELD SPELL", "equip": "EQUIP SPELL", "cont": "CONTINUOUS SPELL", "ritual": "RITUAL SPELL", "quick": "QUICK-PLAY SPELL"}
				hud.effect_text("%s  ·  %s" % [titles[SpellRules.kind(ev["card"])], ev["card"].cname()], Color("7dffc8"))
			var sig_name := str(ev["card"].data.get("name", ""))
			if not _autoplay:
				_announce(p, ev["card"], false)
			if p == AI and not _autoplay and Settings.card_showcase:
				# Their Spell lands on the field, then it is held up to be read before it does anything.
				await board.anim_activate(p, ev["card"], int(ev.get("zone", 2)))
				await hud.showcase(ev["card"], Loc.t("SPELL CARD"), Color("3fd9a8"), state.players[AI].name)
				StrikeFx.card(board, sig_name, p)
				await get_tree().create_timer(Settings.t(0.3)).timeout
			else:
				get_tree().create_timer(Settings.t(0.45)).timeout.connect(func(): StrikeFx.card(board, sig_name, p))
				await board.anim_activate(p, ev["card"], int(ev.get("zone", 2)))
		"st_settle":
			await board.anim_settle(p, ev["card"], int(ev["zone"]))
		"st_reset":
			await board.anim_reset(p, ev["card"], int(ev["zone"]))
		"chain":
			Sfx.play("spell", -2.0, 1.25)
			hud.banner(Loc.t("CHAIN %d") % int(ev["n"]), Color("ffd23a"), true)
			await get_tree().create_timer(Settings.t(0.35)).timeout
		"control":
			Sfx.play("special", -3.0)
			board.hide_stats_for(ev["card"])
			hud.effect_text(Loc.t("%s changes sides!") % ev["card"].cname(), Color("ff8ad8"))
			await board.anim_control(p, ev["card"], int(ev["zone"]))
		"bounce":
			board.hide_stats_for(ev["card"])
			Sfx.play("card", -2.0)
			await board.anim_bounce(ev["card"])
			if not ev.get("extra", false):
				if p == ME:
					hud.add_hand_card(ev["card"])
				else:
					await board.anim_add_to_opp_hand(ev["card"])
		"gy_to_deck":
			board.remove_from_gy(ev["card"])
			board.set_deck_count(p, ev["deck"])
		"spell_done":
			await board.anim_spell_done(ev["card"])
		"attack":
			var atk_card = ev["card"]
			var direct: bool = ev["target"] == null
			if direct and p == ME:
				_lumen("direct")
			# Big swings get a cut-in instead of a bubble: the attacker's name, shouted.
			# A signature monster calls its attack by name, with its own picture across the screen.
			if _shows and Settings.big_shows and SummonShow.attack_name(atk_card.data) != "":
				var ad: Dictionary = (atk_card.data as Dictionary).duplicate()
				ad["id"] = atk_card.id
				SummonShow.strike(self, ad, p == ME)
				board.duelist_gesture(p, "attack")
				await get_tree().create_timer(Settings.t(0.75)).timeout
			elif not _autoplay and (direct or int(atk_card.atk()) >= 2400):
				hud.cut_in(p, str(atk_card.cname()).to_upper(), Loc.t("Direct attack!") if direct else Loc.t("Attack!"), Comic.BLUE if p == ME else Color("ff5a7a"), 0.45)
				board.duelist_gesture(p, "attack")
			elif randf() < 0.3:
				_talk(p, "attack")
			board.duelist_body(p, "attack", 1.3 if direct or int(atk_card.atk()) >= 2400 else 1.0)
			Sfx.play("attack")
			if board.track:
				board.track.surge(p)
				if hud.speed_fx:
					hud.speed_fx.kick(0.5)
			await board.anim_declare(p, ev["card"], ev["target"])
		"battle":
			get_tree().create_timer(Settings.t(0.12)).timeout.connect(func(): Sfx.play("impact"))
			var hit_at: Vector3 = board._attack_goal(p, ev["target"])
			var heavy: bool = ev["target"] == null or int(ev["card"].atk()) >= 2400
			get_tree().create_timer(Settings.t(0.46)).timeout.connect(func():
				hud.impact(hit_at + Vector3(0, 0.3, 0), Comic.SKY if p == ME else Color("ff5a7a"), 1.0 if heavy else 0.55))
			await board.anim_battle(p, ev["card"], ev["target"])
		"attack_stopped":
			await board.anim_attack_stopped(ev["card"])
		"set_st":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			_talk(p, "set", 0.25)
			Sfx.play("card")
			await board.anim_set_st(p, ev["card"], ev["zone"])
		"trap":
			Sfx.play("spell", 0.0, 0.8)
			hud.inspect(ev["card"])
			if not _autoplay:
				board.duelist_gesture(p, "trap")
			# The card turns face-up on the field first (and, with the setting on, is held up to be read).
			if not _autoplay:
				_announce(p, ev["card"], true)
			await board.anim_trap(p, ev["card"], ev["zone"])
			if not _autoplay and p == AI and Settings.card_showcase:
				await hud.showcase(ev["card"], Loc.t("TRAP CARD"), Color("ff4dd2"), state.players[AI].name)
			elif not _autoplay and Settings.card_showcase:
				hud.banner(str(ev["card"].data["name"]).to_upper(), Color("ff4dd2"), true)
				await get_tree().create_timer(Settings.t(0.45)).timeout
			StrikeFx.card(board, str(ev["card"].data.get("name", "")), p)
			await get_tree().create_timer(Settings.t(0.35)).timeout
		"st_done":
			await board.anim_spell_done(ev["card"])
		"destroy_st":
			Sfx.play("destroy", -4.0)
			await board.anim_destroy(ev["card"])
		"hand_effect":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			hud.effect_text(ev["text"])
			await board.anim_hand_effect(p, ev["card"])
		"speed":
			hud.set_speed(p, ev["speed"], ev["delta"])
			if board.track:
				board.track.target_speed = 22.0 + 3.2 * float(state.players[ME].speed + state.players[AI].speed) / 2.0
				Sfx.ambience_pitch(0.8 + 0.045 * float(state.players[ME].speed + state.players[AI].speed) / 2.0)
				if hud.speed_fx:
					hud.speed_fx.amount = 0.12 + 0.035 * float(state.players[ME].speed + state.players[AI].speed) / 2.0
					if ev["delta"] > 0:
						hud.speed_fx.kick(0.35)
			Sfx.play("charge" if ev["delta"] > 0 else "error", -9.0, 1.0 + 0.05 * float(ev["speed"]))
		"effect":
			var on_field: bool = ev["card"] != null and board.card_for(ev["card"]) != null and (state.players[0].field.has(ev["card"]) or state.players[1].field.has(ev["card"]))
			if on_field:
				board.effect_burst(ev["card"], UITheme.GOLD)
			elif ev["card"] != null:
				board.pulse(ev["card"], UITheme.GOLD)
			hud.effect_text(ev["text"])
			Sfx.play("effect", -3.0)
			Sfx.play("sparkle", -10.0, 1.2)
			await get_tree().create_timer(Settings.t(0.75 if on_field else 0.5)).timeout
		"search":
			if p == ME:
				hud.add_hand_card(ev["card"])
			else:
				await board.anim_add_to_opp_hand(ev["card"])
			board.set_deck_count(p, ev["deck"])
		"detach":
			board.set_overlays(ev["card"])
		"swords_end":
			hud.effect_text("Swords of Revealing Light fades")
		"destroy":
			var gone = ev["card"]
			var ace_id: int = int(Characters.get_char(_opp_key).get("ace", 0)) if p == AI else 0
			if gone != null and gone.is_monster() and gone.face_up and (gone.level() >= 7 or (ace_id != 0 and gone.id == ace_id)):
				# Their best monster just went down: that gets a real reaction.
				_talk(p, "ace_lost", 1.0, 0.0)
				hud.react(p, "hurt")
				_lumen("ace_down" if p == AI else "ace_lost")
			elif randf() < (0.5 if p == AI else 0.3):
				_talk(p, "destroyed")
			board.hide_stats_for(ev["card"])
			Sfx.play("destroy", -3.0)
			await board.anim_destroy(ev["card"], ev.get("overlays", []))
		"material":
			board.hide_stats_for(ev["card"])
			if ev["from"] == "hand" and p == ME:
				hud.remove_hand_card(ev["card"])
			_materials.append(ev["card"])
			Sfx.play("card", -4.0)
			await board.anim_material(p, ev["card"], ev["from"], board.monster_zone_pos(p, 2))
		"special":
			var method: String = ev["method"]
			if p == ME:
				hud.remove_hand_card(ev["card"])
			if method == "puzzle":
				Sfx.play("card", -6.0)
				await board.anim_special(p, ev["card"], ev["zone"], method, [])
				return
			var titles := {"fusion": "FUSION SUMMON", "synchro": "SYNCHRO SUMMON", "xyz": "XYZ SUMMON", "reborn": "REVIVED", "ritual": "RITUAL SUMMON"}
			Sfx.play("special")
			_talk(p, "ace", 1.0, 0.0)
			hud.react(p, "ace")
			hud.banner(titles.get(method, "SPECIAL SUMMON"), board.METHOD_COLORS.get(method, UITheme.ACCENT), true)
			if _shows and Settings.big_shows and SummonShow.wants(ev["card"].data):
				var sd2: Dictionary = (ev["card"].data as Dictionary).duplicate()
				sd2["id"] = ev["card"].id
				_shown = ev["card"]
				SummonShow.play(self, sd2, p == ME)
				await get_tree().create_timer(Settings.t(1.5)).timeout
			var mats := _materials.duplicate()
			_materials.clear()
			await board.anim_special(p, ev["card"], ev["zone"], method, mats)
		"discard":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			await board.anim_discard(p, ev["card"])
		"banish":
			board.hide_stats_for(ev["card"])
			if str(ev.get("from", "")) == "hand" and int(ev.get("side", p)) == ME:
				hud.remove_hand_card(ev["card"])
			Sfx.play("destroy", -6.0)
			hud.effect_text(Loc.t("%s is banished") % ev["card"].cname(), Color("c9a0ff"))
			await board.anim_banish(ev["card"], str(ev.get("from", "")), int(ev.get("side", p)))
		"unbanish":
			board.remove_from_banished(ev["card"])
			if ev.get("to", "gy") == "gy":
				board._add_to_gy(ev["card"])
			await get_tree().create_timer(Settings.t(0.2)).timeout
		"gy_to_hand":
			board.remove_from_gy(ev["card"])
			if p == ME:
				hud.add_hand_card(ev["card"])
			else:
				await board.anim_add_to_opp_hand(ev["card"])
		"mill":
			board._add_to_gy(ev["card"])
			board.set_deck_count(p, ev["deck"])
		"redraw":
			if p == ME:
				for e in hud._hand.duplicate():
					hud.remove_hand_card(e["inst"])
			board.set_deck_count(p, ev["deck"])
		"lp":
			hud.set_lp(p, ev["lp"], ev["delta"])
			if p == ME:
				_my_low = mini(_my_low, int(ev["lp"]))
			if ev["delta"] < 0 and int(ev["lp"]) <= 0 and not _autoplay:
				# The last hit of the duel: the winner gets the screen.
				hud.cut_in(1 - p, Loc.t("FINISHING BLOW!"), Characters.line(_speaker(ME) if p == AI else _opp_key, "win"), UITheme.GOLD, 0.8, true)
			if ev["delta"] < 0:
				# The house: a roar for a hit on the other side, a gasp (and red light) for one on yours.
				var hit_col := Color(1.0, 0.82, 0.3) if p == AI else Color(1.0, 0.3, 0.26)
				if int(ev["lp"]) <= 0 and board.arena != null:
					board.arena.finish(hit_col)
				elif int(ev["lp"]) <= 0 and board.track != null:
					board.track.finish(hit_col)
					if not _autoplay and not _finished:
						board.turbo_blow(p)
				else:
					board.house(clampf(float(-ev["delta"]) / 3000.0, 0.25, 0.9), hit_col, Vector3(0, 0, -3.0 if p == AI else 3.0), 0.6)
				board.duelist_body(p, "hurt", float(-ev["delta"]) / 1500.0)
				board.shake(0.5 if ev["delta"] > -2000 else 0.8)
				# You feel it in your hands when you take the hit, a little when you land one.
				if not _autoplay:
					if p == ME:
						Pad.rumble(0.4, 0.8 if ev["delta"] <= -2000 else 0.45, 0.35)
					else:
						Pad.rumble(0.25, 0.0, 0.15)
				if board.track:
					board.track.wobble(p, ev["delta"] <= -2000)
				# A heavy hit cuts to the one who took it for a moment.
				if ev["delta"] <= -2000 and int(ev["lp"]) > 0 and not _autoplay and not board.track:
					board.duelist_gesture(p, "hurt")
					board.duelist_shot(p, 0.35, false, 0.6)
					# ...and then to the people watching, on their feet, before the table again.
					get_tree().create_timer(Settings.t(1.1)).timeout.connect(func():
						if not board.crowd_shot(1.2):
							board.cam_release(0.5))
				Sfx.play("damage")
				hud.react(p, "hurt")
				if p == AI and ev["lp"] <= 2000 and not _said_low:
					_said_low = true
					_talk(AI, "low", 1.0, 0.0)
					_lumen("comeback" if _me_was_low else "their_low")
				if p == ME and int(ev["lp"]) <= 2000 and int(ev["lp"]) > 0:
					_me_was_low = true
					_lumen("my_low")
				elif p == ME and ev["delta"] <= -2000 and int(ev["lp"]) > 0:
					_lumen("hit")
				elif ev["delta"] <= -1000:
					_talk(p, "hurt")
					_talk(1 - p, "big_hit", 0.55)
			else:
				Sfx.play("heal")
			await get_tree().create_timer(Settings.t(0.45)).timeout
	_update_counts()


## One line in the play-by-play for what the other side does (and for what happens to you).
var _tally := {}


func _feed_event(ev: Dictionary, p: int) -> void:
	if _autoplay:
		return
	var c = ev.get("card")
	var cn := str(c.cname()) if c != null and c.has_method("cname") else ""
	var theirs := p == AI
	if p == ME and _puzzle.is_empty() and c != null and c.has_method("frame"):
		# What you did this duel, for your goals (Goals.after_duel).
		match str(ev["type"]):
			"special":
				if c.frame() in ["fusion", "synchro", "xyz", "ritual"]:
					_tally["extra"] = int(_tally.get("extra", 0)) + 1
				elif c.level() >= 5:
					_tally["tribute"] = int(_tally.get("tribute", 0)) + 1
			"summon":
				if c.level() >= 5:
					_tally["tribute"] = int(_tally.get("tribute", 0)) + 1
			"trap":
				_tally["trap"] = int(_tally.get("trap", 0)) + 1
			"attack":
				if ev.get("target") == null:
					_tally["direct"] = int(_tally.get("direct", 0)) + 1
	match str(ev["type"]):
		"destiny":
			if theirs:
				hud.feed(p, "★", Loc.t("Destiny Draw: chose the card they drew"))
		"summon":
			if theirs:
				hud.feed(p, "▲", Loc.t("Summoned %s  (%d ATK)") % [cn, int(c.atk())])
		"set":
			if theirs:
				hud.feed(p, "▣", Loc.t("Set a monster face-down"))
		"set_st":
			if theirs:
				hud.feed(p, "▣", Loc.t("Set a card face-down"))
		"activate":
			if theirs:
				hud.feed(p, "✦", Loc.t("Activated %s") % cn)
		"trap":
			if theirs:
				hud.feed(p, "!", Loc.t("Trap: %s") % cn)
		"special":
			if theirs:
				hud.feed(p, "★", Loc.t("Special Summoned %s") % cn)
		"flip":
			if theirs:
				hud.feed(p, "↻", Loc.t("Flipped %s face-up") % cn)
		"attack":
			if theirs:
				var tg = ev.get("target")
				if tg == null:
					hud.feed(p, "⚔", Loc.t("%s attacks you directly") % cn)
				else:
					hud.feed(p, "⚔", Loc.t("%s attacks %s") % [cn, str(tg.cname()) if tg.face_up else Loc.t("your face-down monster")])
		"destroy":
			if c != null and c.owner == ME and cn != "":
				hud.feed(AI, "✕", Loc.t("Your %s was destroyed") % cn)
		"effect":
			if theirs and cn != "":
				hud.feed(p, "✦", Loc.t("Effect: %s") % cn)


func _update_counts() -> void:
	board.sync_holos(state)
	for p in 2:
		var ps := state.players[p]
		hud.set_counts(p, ps.deck.size(), ps.hand.size(), ps.gy.size(), ps.banished.size())
		hud.piles[p] = [ps.gy, ps.banished]
		hud.set_destiny(p, 0 if not (state.destiny and state.destiny_who[p]) else (2 if state.destiny_used[p] else 1))
		board.set_gy_count(p, ps.gy.size())


# ------------------------------------------------------------------ player input

var _flow := false   # true while a chain / target prompt is running


func _my_turn() -> bool:
	if _flow:
		return false
	if ocg != null:
		return ocg.active() and not hud.overlay_visible()
	return state.current == ME and not busy and not state.is_over() and not hud.overlay_visible()


func _refresh() -> void:
	if ocg != null:
		ocg.refresh()
		return
	hud.set_speed_button(_my_turn() and (state.can_speed_world(ME, 4) or state.can_speed_world(ME, 7) or state.can_speed_world(ME, 10)))
	if not _my_turn():
		hud.set_phase_buttons("", false, false)
		hud.set_extra_button(state.players[ME].extra.size() if state.players.size() > 0 else 0, 0, false)
		if state.players.size() > 1:
			board.set_extra_count(ME, state.players[ME].extra.size(), 0)
			board.set_extra_count(AI, state.players[AI].extra.size())
		hud.set_playable([])
		hud.set_coach("")
		_clear_glows()
		return
	match state.phase:
		DuelState.Phase.MAIN1:
			hud.set_phase_buttons("Battle Phase", state.can_enter_battle(), true)
		DuelState.Phase.BATTLE:
			hud.set_phase_buttons("Main Phase 2", true, true)
		DuelState.Phase.MAIN2:
			hud.set_phase_buttons("", false, true)
		_:
			hud.set_phase_buttons("", false, false)
	var ready := 0
	for x in state.players[ME].extra:
		if state.can_extra_summon(ME, x):
			ready += 1
	hud.set_extra_button(state.players[ME].extra.size(), ready, true)
	board.set_extra_count(ME, state.players[ME].extra.size(), ready)
	board.set_extra_count(AI, state.players[AI].extra.size())
	var playable := []
	for c in state.players[ME].hand:
		if state.can_normal_summon(ME, c) or state.can_activate(ME, c) or state.can_special_from_hand(ME, c) or (c.is_trap() and state.can_set_st(ME, c)):
			playable.append(c)
	hud.set_playable(playable)
	hud.set_coach(_coach_line(ready) if mode == "" else "")
	_clear_glows()
	if mode == "":
		for st in state.players[ME].spells:
			var sc := board.card_for(st) if st != null else null
			if sc and not st.face_up:
				sc.set_glow(state.can_activate(ME, st), Color("ff4dd2"))
			elif sc and SpellRules.can_fire(state, ME, st):
				sc.set_glow(true, Color("ffd23a"))
		for m in state.players[ME].monsters():
			var c := board.card_for(m)
			if c and (state.can_attack(ME, m) or state.can_flip_summon(ME, m) or state.can_change_position(ME, m)):
				c.set_glow(true, Comic.SKY)


## A few words on what is open to you right now, so a glowing card is never a riddle.
func _coach_line(extra_ready: int) -> String:
	var me: DuelState.PlayerState = state.players[ME]
	var parts: Array = []
	if state.phase == DuelState.Phase.BATTLE:
		var n := 0
		for m in me.monsters():
			if state.can_attack(ME, m):
				n += 1
		if n > 0:
			parts.append(Loc.t("Tap a glowing monster to attack  (%d ready)") % n)
		else:
			parts.append(Loc.t("No attacks left: go to Main Phase 2 or end your turn"))
		return "   ·   ".join(parts)
	if state.phase != DuelState.Phase.MAIN1 and state.phase != DuelState.Phase.MAIN2:
		return ""
	var summon := false
	var special := false
	var spell := false
	var trap := false
	for c in me.hand:
		if state.can_normal_summon(ME, c):
			summon = true
		elif state.can_special_from_hand(ME, c):
			special = true
		if not c.is_monster() and state.can_activate(ME, c):
			spell = true
		if c.is_trap() and state.can_set_st(ME, c):
			trap = true
	if summon:
		parts.append(Loc.t("Summon or Set a monster"))
	if special:
		parts.append(Loc.t("Special Summon from your hand"))
	if extra_ready > 0:
		parts.append(Loc.t("Extra Deck summon ready"))
	if spell:
		parts.append(Loc.t("Play a Spell"))
	if trap and parts.size() < 3:
		parts.append(Loc.t("Set a Trap"))
	var set_ready := false
	for st in me.spells:
		if st != null and ((not st.face_up and state.can_activate(ME, st)) or (st.face_up and SpellRules.can_fire(state, ME, st))):
			set_ready = true
	if set_ready and parts.size() < 3:
		parts.append(Loc.t("Use a card on your field"))
	if state.phase == DuelState.Phase.MAIN1 and state.can_enter_battle():
		var can_hit := false
		for m in me.monsters():
			if m.face_up and m.attack_pos:
				can_hit = true
		if can_hit and parts.size() < 3:
			parts.append(Loc.t("Battle Phase to attack"))
	if parts.is_empty():
		return Loc.t("Nothing left to play: end your turn")
	return "   ·   ".join(parts.slice(0, 3))


func _clear_glows() -> void:
	board.clear_picks()
	for p in 2:
		for m in state.players[p].monsters():
			var c := board.card_for(m)
			if c:
				c.set_glow(false)


func _on_phase_button(action: String) -> void:
	if ocg != null:
		ocg.on_phase_button(action)
		return
	if not _my_turn():
		return
	_cancel_mode()
	if action == "battle":
		if state.phase == DuelState.Phase.MAIN1:
			await _act("enter_battle", [])
			await _window(AI, "battle_start", null, "")
		elif state.phase == DuelState.Phase.BATTLE:
			await _act("enter_main2", [])
			await _window(AI, "phase", null, "")
	elif action == "end":
		_turn_finished.emit()


## What dropping a hand card on your rows would do. A card only goes where its kind goes: a
## monster on the monster row (0), a Spell or Trap on the back row (1). The other row stays dark.
## plan[row] is one entry (the whole row does it) or two (left half, right half), each
## [action id, the word shown over it]: face-up on the left, Set on the right.
func _drop_plan(inst) -> Dictionary:
	if ocg != null:
		return ocg.drop_plan(inst)
	var plan := {}
	if inst.is_monster():
		var cells: Array = []
		if state.can_special_from_hand(ME, inst):
			cells.append(["special_hand", "SPECIAL SUMMON"])
		elif state.can_normal_summon(ME, inst):
			cells.append(["summon", "SUMMON"])
		if state.can_normal_summon(ME, inst):
			cells.append(["set", "SET"])
		if not cells.is_empty():
			plan[0] = cells
	elif inst.is_trap():
		if state.can_set_st(ME, inst):
			plan[1] = [["set_st", "SET"]]
	else:
		var cells2: Array = []
		if state.can_activate(ME, inst):
			cells2.append(["activate", "ACTIVATE"])
		if state.can_set_st(ME, inst):
			cells2.append(["set_st", "SET"])
		if not cells2.is_empty():
			plan[1] = cells2
	return plan


func _on_hand_drag(inst, on: bool) -> void:
	if not on:
		board.show_drop([], false)
		return
	var plan := _drop_plan(inst)
	_menu_card = null
	var rows: Array = [[], []]
	for r in plan:
		for cell in plan[r]:
			(rows[int(r)] as Array).append(Loc.t(str(cell[1])))
	board.show_drop(rows, true)


## A hand card let go over the table. True when it lands on a part of a row that takes it.
func _on_hand_drop(inst, at: Vector2) -> bool:
	if not _my_turn() or mode != "":
		return false
	var plan := _drop_plan(inst)
	var cell := board.drop_cell(at)
	var row := int(cell[0])
	if not plan.has(row):
		return false
	var cells: Array = plan[row]
	var pick: Array = cells[0] if cells.size() == 1 else cells[clampi(int(cell[1]), 0, cells.size() - 1)]
	_menu_card = inst
	Sfx.play("card", -4.0)
	_on_action.call_deferred(str(pick[0]))
	return true


## Your own deck: the things you would reach for it to do.
func _on_deck_clicked() -> void:
	if _finished or hud.overlay_visible():
		return
	if hud.actions_visible() and _menu_card == null and _deck_menu:
		hud.hide_actions()
		_deck_menu = false
		return
	_cancel_mode()
	_menu_card = null
	_deck_menu = true
	var deck_opts := [["piles", "Graveyards", true], ["pause", "Duel menu", true], ["surrender", "Surrender", true]]
	if (not ocg.pile_effects().is_empty()) if ocg != null else (_my_turn() and not state.gy_effects(ME).is_empty()):
		# A card in your Graveyard can use its effect from there (Destiny HERO - Malicious).
		deck_opts.push_front(["gyfx", "Effect from the Graveyard", true])
	hud.show_actions(board.camera.unproject_position(board.deck_pos(ME)) + Vector2(-420, -60), deck_opts)


var _deck_menu := false
var _closed_card = null          # the card whose menu this very tap just closed
var _closed_at := 0
var _drag_atk := {}              # a press on one of your monsters that may turn into a drag


func _input(event: InputEvent) -> void:
	if _drag_atk.is_empty():
		return
	if event is InputEventMouseMotion and not _drag_atk["on"]:
		if (event.position as Vector2).distance_to(_drag_atk["from"]) < 22.0 or not _my_turn():
			return
		_drag_atk["on"] = true
		var a = _drag_atk["inst"]
		hud.hide_actions()
		_menu_card = null
		if mode != "attack":
			# Dragging out of Main Phase 1 aims the same way; the Battle Phase starts on release.
			_clear_glows()
			var ac := board.card_for(a)
			if ac:
				ac.set_glow(true, UITheme.GOLD)
			for t in state.attack_targets_for(ME, a):
				var tc := board.card_for(t)
				if tc:
					tc.set_glow(true, UITheme.DANGER)
			board.start_aim(a)
			board.show_direct_target(state.can_direct_attack(ME) or state.can_direct_attack_with(ME, a))
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var d := _drag_atk
		_drag_atk = {}
		if not d["on"]:
			return
		var hit := board.enemy_card_at(event.position, state.attack_targets_for(ME, d["inst"]))
		var direct: bool = hit == null and board.side_at(event.position) == 1
		_drag_attack_go(d["inst"], hit.inst if hit else null, direct)


func _drag_attack_go(a, target, direct: bool) -> void:
	var aiming := mode == "attack"
	if target == null and not direct:
		# Let go over nothing: a tap-style attack keeps waiting for its target, a drag is dropped.
		if not aiming:
			_cancel_mode()
		return
	if not _my_turn():
		_cancel_mode()
		return
	_cancel_mode()
	if state.phase == DuelState.Phase.MAIN1:
		if not state.can_enter_battle():
			return
		await _act("enter_battle", [])
		await _window(AI, "battle_start", null, "")
	if not _my_turn() or not state.can_attack(ME, a):
		return
	if target != null and state.attack_targets_for(ME, a).has(target):
		await _do_attack(ME, a, target)
	elif target == null and (state.can_direct_attack(ME) or state.can_direct_attack_with(ME, a)):
		await _do_attack(ME, a, null)
	else:
		Sfx.play("error", -8.0)


func _on_hand_card_pressed(inst, at: Vector2) -> void:
	if ocg != null:
		ocg.on_hand_card_pressed(inst, at)
		return
	if not _my_turn() or mode != "":
		return
	if hud.actions_visible() and _menu_card == inst:
		# A second tap on the same card puts it back.
		hud.hide_actions()
		_menu_card = null
		return
	_deck_menu = false
	_menu_card = inst
	hud.inspect(inst)
	hud.focus_hand_card(inst)
	at = hud.hand_menu_anchor(inst)
	if inst.is_monster():
		var can := state.can_normal_summon(ME, inst)
		var need := state.tributes_needed(inst)
		var suffix := "" if need == 0 else Loc.t(" (%d tribute%s)") % [need, "" if need == 1 else "s"]
		var opts := [["summon", Loc.t("Summon") + suffix, can], ["set", "Set", can]]
		# Every monster with its own way out of the hand gets the button, not only Cyber Dragon.
		if inst.cname() == "Cyber Dragon" or EffectRunner.has_special_hand(inst) or state.can_special_from_hand(ME, inst):
			opts.push_front(["special_hand", "Special Summon", state.can_special_from_hand(ME, inst)])
		if EffectRunner.fx(inst).has("hand_ignite"):
			opts.append(["hand_fx", Loc.t("Effect: ") + Loc.t(str(EffectRunner.fx(inst)["hand_ignite"].get("label", "Discard it"))), state.can_hand_ignite(ME, inst)])
		hud.show_actions(at, opts, true)
	elif inst.is_trap():
		hud.show_actions(at, [["set_st", "Set", state.can_set_st(ME, inst)]], true)
	else:
		hud.show_actions(at, [["activate", "Activate", state.can_activate(ME, inst)], ["set_st", "Set", state.can_set_st(ME, inst)]], true)
	# Nothing to press: say why, so a greyed-out card is never a mystery.
	var why := state.why_not(ME, inst)
	if why != "":
		Router.toast(why, 2.6)


func _on_action(action: String) -> void:
	if action.begins_with("phase:"):
		hud.hide_actions()
		_on_phase_button(action.trim_prefix("phase:"))
		return
	if ocg != null and action == "gyfx":
		_deck_menu = false
		ocg.on_pile_effects()
		return
	if ocg != null and ocg.on_action(action):
		return
	if action in ["surrender", "piles", "pause", "gyfx"]:
		_deck_menu = false
		match action:
			"gyfx":
				var can_g: Array = state.gy_effects(ME)
				if can_g.is_empty() or not _my_turn():
					return
				var g_labels := []
				for g in can_g:
					g_labels.append("%s: %s" % [g.cname(), Loc.t(str(EffectRunner.fx(g)["gy_ignite"].get("label", "Activate")))])
				g_labels.append(Loc.t("Not now"))
				var gi: int = await hud.ask_choice(Loc.t("Use which effect from your Graveyard?"), g_labels)
				if gi >= 0 and gi < can_g.size() and _my_turn():
					await _act("gy_ignite", [ME, can_g[gi]], false)
					await _after_summon(ME)
			"surrender":
				var sure := await hud.ask_choice(Loc.t("Surrender this duel?"), [Loc.t("Keep dueling"), Loc.t("Surrender")])
				if sure == 1:
					_on_pause_action("surrender")
			"piles":
				hud.show_piles(ME)
			"pause":
				_on_pause_action("open")
		return
	var c = _menu_card
	_menu_card = null
	if c == null or not _my_turn() or ocg != null:
		return
	if action.begins_with("fuse:"):
		var uid := int(action.substr(5))
		for x in state.players[ME].extra:
			if x.uid == uid:
				await _activate_flow(ME, c, x)
				return
		return
	match action:
		"summon", "set":
			var need := state.tributes_needed(c)
			if need == 0:
				await _act("normal_summon", [ME, c, [], action == "set"], false)
				await _after_summon(ME)
			else:
				mode = "tribute"
				_pending_card = c
				_pending_set = action == "set"
				_tributes = []
				_refresh_tribute()
		"activate":
			if c.data.get("effect", "") == "fusion":
				var opts := state.fusion_targets(ME, c)
				if opts.size() > 1:
					_menu_card = c
					var list := []
					for o in opts:
						list.append([Loc.t("fuse:%d") % o["card"].uid, o["card"].data["name"], true])
					hud.show_actions(get_viewport().get_mouse_position(), list)
					return
			await _activate_flow(ME, c, null)
		"fire":
			await _run(func(st, a): return SpellRules.fire(st, ME, a[0]), [c])
		"attack":
			if state.phase == DuelState.Phase.MAIN1:
				await _act("enter_battle", [])
				await _window(AI, "battle_start", null, "")
			if state.can_attack(ME, c):
				_start_attack(c)
		"flip":
			await _act("flip_summon", [ME, c], false)
			await _after_summon(ME)
		"ignite":
			await _act("ignite", [ME, c], false)
			await _after_summon(ME)
		"set_st":
			await _act("set_st", [ME, c])
		"special_hand":
			await _act("special_from_hand", [ME, c], false)
			await _after_summon(ME)
		"hand_fx":
			await _act("hand_ignite", [ME, c], false)
		"position":
			await _act("change_position", [ME, c])


func _refresh_tribute() -> void:
	var need := state.tributes_needed(_pending_card)
	if need == 1:
		hud.show_prompt(Loc.t("Tap the monster you give up for %s") % _pending_card.cname())
	else:
		hud.show_prompt(Loc.t("Tap %d monsters to give up for %s   ·   %d of %d chosen") % [need, _pending_card.cname(), _tributes.size(), need])
	_clear_glows()
	for m in state.tributable(ME):
		var c := board.card_for(m)
		if c:
			c.set_glow(true, Color("5df07a") if _tributes.has(m) else UITheme.GOLD)
	# The cards themselves say what to do: an arrow over each one you can give up.
	board.show_picks(state.tributable(ME), _tributes, "TRIBUTE", "CHOSEN")


func _on_board_card_clicked(card: Card3D) -> void:
	if ocg != null:
		ocg.on_board_card_clicked(card)
		return
	var reopened: bool = (hud.actions_visible() and _menu_card != null and _menu_card == card.inst) or (_closed_card != null and _closed_card == card.inst and Time.get_ticks_msec() - _closed_at < 120)
	_closed_card = null
	hud.hide_actions()
	_deck_menu = false
	if not _my_turn() or reopened:
		# A second tap on the card whose menu is open just closes it.
		_menu_card = null
		return
	var inst = card.inst
	if inst == null:
		return
	var mine: bool = state.players[ME].field.has(inst)
	var theirs: bool = state.players[AI].field.has(inst)
	if mine and mode in ["", "attack"] and inst.face_up and (inst.attack_pos or EffectRunner.fx(inst).get("direct_from_def", false)) and (state.can_attack(ME, inst)
			or (state.phase == DuelState.Phase.MAIN1 and state.can_enter_battle() and inst.attacked_turn != state.turn)):
		_drag_atk = {"inst": inst, "from": get_viewport().get_mouse_position(), "on": false}
	if mode == "materials":
		if mine:
			_toggle_material(inst)
		return
	if mode == "" and state.players[ME].spells.has(inst):
		# Your own Spell & Trap cards: flip a Set one, or fire a charged one.
		var st_opts := []
		if not inst.face_up and state.can_activate(ME, inst):
			st_opts.append(["activate", "Activate", true])
		if state.can_ignite(ME, inst):
			# A Union monster riding as an Equip Card: take it off and Special Summon it.
			st_opts.append(["ignite", Loc.t("Effect: ") + str(EffectRunner.ignite_spec(inst).get("label", "Activate")), true])
		if SpellRules.can_fire(state, ME, inst):
			st_opts.append(["fire", Loc.t("Fire (%d damage)") % (inst.counter * int(SpellRules.spec(inst)["cannon"])), true])
		if not st_opts.is_empty():
			_menu_card = inst
			hud.show_actions(board.screen_pos(inst) + Vector2(60, 0), st_opts)
		return
	if mode == "tribute":
		if mine and state.tributable(ME).has(inst):
			if _tributes.has(inst):
				_tributes.erase(inst)
			else:
				_tributes.append(inst)
			if _tributes.size() == state.tributes_needed(_pending_card):
				var c = _pending_card
				var t := _tributes.duplicate()
				var s := _pending_set
				_cancel_mode()
				await _act("normal_summon", [ME, c, t, s], false)
				await _after_summon(ME)
			else:
				_refresh_tribute()
		return
	if mode == "attack":
		if theirs:
			var a = _attacker
			_cancel_mode()
			await _do_attack(ME, a, inst)
		elif mine and state.can_attack(ME, inst):
			_start_attack(inst)
		return
	if not mine:
		return
	if state.phase == DuelState.Phase.BATTLE and state.can_attack(ME, inst):
		_start_attack(inst)
		return
	var opts := []
	if state.phase == DuelState.Phase.MAIN1 and state.can_enter_battle() and inst.face_up and inst.attack_pos and inst.attacked_turn != state.turn:
		opts.append(["attack", "Attack", true])
	if state.can_ignite(ME, inst):
		opts.append(["ignite", Loc.t("Effect: ") + str(EffectRunner.ignite_spec(inst).get("label", "Activate")), true])
	if state.can_flip_summon(ME, inst):
		opts.append(["flip", "Flip Summon", true])
	if state.can_change_position(ME, inst):
		opts.append(["position", "To Defense" if inst.attack_pos else "To Attack", true])
	if opts.is_empty():
		return
	_menu_card = inst
	hud.show_actions(board.screen_pos(inst) + Vector2(60, 0), opts)


## Speed World 2: pick which of its three effects to pay for.
func _on_speed_pressed() -> void:
	if ocg != null:
		ocg.on_speed_pressed()
		return
	if not _my_turn():
		return
	_cancel_mode()
	var costs := []
	var labels := []
	var spells: int = state.players[ME].hand.filter(func(c): return not c.is_monster() and not c.is_trap()).size()
	for pair in [[4, Loc.t("4 counters: %d damage (800 for each Speed Spell in your hand)") % (800 * spells)],
			[7, Loc.t("7 counters: draw 1 card")], [10, Loc.t("10 counters: destroy 1 card on their field")]]:
		if state.can_speed_world(ME, pair[0]):
			costs.append(pair[0])
			labels.append(pair[1])
	if costs.is_empty():
		Router.toast("Not enough Speed Counters yet")
		return
	labels.append(Loc.t("Cancel"))
	var pick: int = await hud.ask_choice(Loc.t("Speed World 2   ·   you have %d Speed Counters") % state.players[ME].speed, labels)
	if pick < 0 or pick >= costs.size():
		return
	Sfx.play("gong", -6.0)
	await _act("speed_world", [ME, costs[pick]])
	_refresh()


func _on_extra_pressed() -> void:
	if ocg != null:
		ocg.on_extra_pressed()
		return
	if not _my_turn():
		return
	_cancel_mode()
	var opts := []
	var has_poly := false
	for h in state.players[ME].hand:
		if h.data.get("effect", "") == "fusion":
			has_poly = true
	for x in state.players[ME].extra:
		var status := ""
		var ok := false
		match x.frame():
			"fusion":
				if CardEffects.of(x.cname()).has("contact"):
					# Contact Fusion: no Polymerization, the materials go from your field.
					ok = state.can_extra_summon(ME, x)
					status = "Contact Fusion" if ok else "Needs its materials on your field"
				else:
					status = "Use Polymerization" if has_poly else "Needs Polymerization"
			"synchro":
				ok = state.can_extra_summon(ME, x)
				status = "Synchro Summon" if ok else Loc.t("Tuner + %d levels") % x.level()
			"xyz":
				ok = state.can_extra_summon(ME, x)
				status = "Xyz Summon" if ok else Loc.t("2 Level %d monsters") % x.level()
		opts.append([x, status, ok])
	hud.show_extra(opts)


var _extra_target = null
var _extra_sel: Array = []


## Pick materials yourself: tap monsters on your field, or press Auto.
func _on_extra_chosen(inst) -> void:
	if ocg != null:
		ocg.on_extra_chosen(inst)
		return
	if not _my_turn():
		return
	if CardEffects.of(inst.cname()).has("contact") or (state.extra_materials(ME, inst).is_empty() and state.xyz_base(ME, inst) != null):
		if state.can_extra_summon(ME, inst):
			_cancel_mode()
			await _act("extra_summon", [ME, inst, []], false)
			await _after_summon(ME)
		return
	var options := state.extra_materials(ME, inst)
	if options.is_empty():
		return
	mode = "materials"
	_extra_target = inst
	_extra_sel = []
	_refresh_materials()


func _material_candidates() -> Array:
	var out := []
	for opt in state.extra_materials(ME, _extra_target):
		for m in opt:
			if not out.has(m):
				out.append(m)
	return out


func _refresh_materials() -> void:
	var what := "Synchro" if _extra_target.frame() == "synchro" else "Xyz"
	var hint := Loc.t("a Tuner plus monsters adding up to Level %d") % _extra_target.level() if what == "Synchro" else Loc.t("2 Level %d monsters") % _extra_target.level()
	hud.show_prompt(Loc.t("%s Summon %s: pick %s") % [what, _extra_target.data["name"], hint], true, "Auto-pick")
	_clear_glows()
	for m in _material_candidates():
		var c := board.card_for(m)
		if c:
			c.set_glow(true, Color("5df07a") if _extra_sel.has(m) else UITheme.GOLD)
	board.show_picks(_material_candidates(), _extra_sel, "TAP", "CHOSEN")


func _toggle_material(inst) -> void:
	if not _material_candidates().has(inst):
		return
	if _extra_sel.has(inst):
		_extra_sel.erase(inst)
	else:
		_extra_sel.append(inst)
	Sfx.play("card", -6.0, 1.2)
	for opt in state.extra_materials(ME, _extra_target):
		if opt.size() == _extra_sel.size() and opt.all(func(m): return _extra_sel.has(m)):
			var target = _extra_target
			var mats := _extra_sel.duplicate()
			_cancel_mode()
			await _act("extra_summon", [ME, target, mats], false)
			await _after_summon(ME)
			return
	_refresh_materials()


## Declare, give the defender a chance to respond, then resolve.
func _do_attack(p: int, attacker, target) -> void:
	var ev: Array = await _act("declare_attack", [p, attacker, target], false)
	if ev.is_empty():
		return
	await _window(state.opponent(p), "attack", null, Loc.t("%s attacks! Respond?") % attacker.data["name"])
	# Replay: the defender's monsters changed, so the attacker chooses again.
	var replays := 0
	while state.replay_needed() and replays < 3:
		replays += 1
		var opts: Array = state.attack_targets_for(p, attacker)
		var pick = null
		var go := true
		if p == AI or _autoplay:
			var again := DuelAI.next_attack(state, p, _level_for(p))
			go = not again.is_empty() and again["card"] == attacker
			pick = again.get("target") if go else null
		else:
			var labels := []
			for m in opts:
				labels.append(Loc.t("Attack %s") % (m.cname() if m.face_up else "the face-down monster"))
			if state.can_direct_attack_with(p, attacker):
				labels.append("Attack directly")
			labels.append("Stop the attack")
			var idx: int = await hud.ask_choice(Loc.t("Replay! Their monsters changed. %s:") % attacker.cname(), labels, attacker)
			go = idx < labels.size() - 1
			pick = opts[idx] if idx < opts.size() else null
		if not go:
			await _act("cancel_attack", [])
			return
		await _act("replay_attack", [pick], false)
	# Damage Step: only ATK / DEF changers and Counter Traps.
	if not state.pending_attack.is_empty() and not state.pending_attack["negated"]:
		await _window(p, "damage", null, "Damage Step. Change ATK or DEF?")
	await _act("resolve_attack", [])


## After a summon, the other player may respond (Trap Hole, Solemn Judgment and friends).
func _after_summon(p: int) -> void:
	var subj = state.last_summoned
	if subj == null or state.is_over():
		await _settle()
		return
	state.last_summoned = null
	await _window(state.opponent(p), "summon", subj, Loc.t("%s was summoned. Respond?") % subj.data["name"])


## Activate a Spell/Trap with the full chain: target, the other player's response, then resolve.
func _activate_flow(who: int, c, target) -> void:
	var sp := SpellRules.spec(c)
	if target == null and who == ME and not _autoplay and not sp.has("legacy") and not sp.has("modes") and SpellRules._needs_target(sp):
		target = await _pick_target(who, c)
		if target == null:
			return
	_flow = true
	var ev: Array = await _act("chain_add", [who, c, target, "open", null], false)
	if ev.is_empty():
		_flow = false
		return
	await _window(state.opponent(who), "chain", null, "")
	_flow = false
	_refresh()
	await _after_summon(who)


func _pick_target(who: int, c):
	var cands := SpellRules.targets(state, who, c)
	if cands.is_empty():
		return null
	if who == AI or _autoplay:
		return SpellRules.auto_target(state, who, c)
	if _human_test:
		return cands[0]
	var hidden := []
	for x in cands:
		if x.owner != who and not x.face_up:
			hidden.append(x)
	_flow = true
	var pick = await hud.ask_pick(Loc.t("Choose a target for %s") % c.cname(), cands, "Select", "Cancel", hidden)
	_flow = false
	return pick


## A response window. Players take turns adding to the chain until both pass, then it resolves.
## window: "attack" | "summon" | "chain" | "battle_start". `first` gets the first chance.
func _window(first: int, window: String, subject, prompt: String) -> void:
	var who := first
	var passes := 0
	var was_flow := _flow
	_flow = true
	if not state.pending_fx.is_empty():
		await _act("fx_to_chain", [], false)
	while passes < 2 and not state.is_over() and not _finished:
		var win := window if state.chain.is_empty() else "chain"
		var subj = subject if state.chain.is_empty() else state.chain.back()
		var opts := state.responses(who, win, subj)
		if win == "chain" and window in ["attack", "summon"] and str(state.chain.back()["spec"].get("k", "")) != "counter":
			# Cards made for the original trigger still fit while the chain builds.
			for o in state.responses(who, window, subject):
				if not opts.has(o) and not o.is_monster() and SpellRules.kind(o) != "counter":
					opts.append(o)
		var choice = null
		if not opts.is_empty():
			if who == AI or _autoplay:
				choice = DuelAI.choose_response(state, who, win, opts, _level_for(who))
				if choice != null:
					await _ai_wait(0.3)
			elif window in ["phase", "battle_start"] and win == window and not hud.phase_prompts:
				choice = null
			elif not hud.phase_prompts and _nothing_to_answer(who, win, opts):
				choice = null
			else:
				var text := prompt
				var my_attack: bool = win == "attack" and not state.pending_attack.is_empty() and int(state.pending_attack["player"]) == who
				if win == "chain":
					text = Loc.t("Chain to %s%s?") % [state.chain.back()["card"].cname(), "'s effect" if state.chain.back()["kind"] == "fx" else ""]
				elif window == "battle_start":
					text = "The Battle Phase begins. Respond?"
				elif my_attack:
					text = Loc.t("%s attacks. Use a card?") % str(state.pending_attack["attacker"].cname())
					if not hud.phase_prompts:
						opts = opts.filter(_helps_my_attack)
				hud.ask_why = Loc.t("Your monster declared an attack. A card of yours can be used before it lands. Pick one, or let the attack go on.") if my_attack else Loc.t({
					"attack": "Your opponent declared an attack. A Trap or Quick-Play Spell can answer it before it lands. Pick a card to use it, or let the attack go through.",
					"summon": "A monster was just summoned. This is your chance to answer the summon with a Trap. Pick a card to use it, or let it stand.",
					"chain": "A card or effect was just activated. You can chain one of yours on top of it: the last card played resolves first.",
					"battle_start": "Cards that work at the start of the Battle Phase can be used now.",
					"phase": "You have a card that can be used in this phase. Use it now or keep it for later.",
				}.get(win, "You have a card that can respond right now. Use it or keep it."))
				choice = await hud.ask_response(text, opts)
		if choice != null:
			if choice.is_monster() or (choice.cname() == "Kuriboh" and state.players[who].hand.has(choice)) or state.players[who].gy.has(choice):
				await _act("respond", [who, choice, subject], false)
			else:
				var target = null
				var sp := SpellRules.spec(choice)
				if not sp.has("legacy") and not sp.has("modes") and SpellRules._needs_target(sp):
					target = await _pick_target(who, choice)
					_flow = true
					if target == null:
						passes += 1
						who = state.opponent(who)
						continue
				await _act("chain_add", [who, choice, target, win, subj], false)
			passes = 0
		else:
			passes += 1
		who = state.opponent(who)
	if not state.chain.is_empty():
		await _act("chain_resolve", [], false)
	_flow = was_flow
	# Effects that triggered while that chain resolved start a chain of their own.
	if not state.pending_fx.is_empty() and not state.is_over() and not _finished:
		await _window(state.opponent(state.current), "chain", null, "")


## With "Ask me at every chance" off: is this a stop with nothing in it to answer? Your own
## card going on the chain (there is nothing of theirs to answer), or your own attack when all
## you hold are cards for when you are the one being attacked.
func _nothing_to_answer(who: int, win: String, opts: Array) -> bool:
	if win == "chain" and not state.chain.is_empty() and int(state.chain.back()["player"]) == who:
		return true
	if win == "attack" and not state.pending_attack.is_empty() and int(state.pending_attack["player"]) == who:
		return opts.filter(_helps_my_attack).is_empty()
	return false


## A card worth being asked about while your own monster attacks: one that makes a monster
## stronger (Rush Recklessly), or a monster's own effect from the hand.
func _helps_my_attack(c) -> bool:
	if c.is_monster():
		return true
	var sp := SpellRules.spec(c)
	var lists: Array = [sp.get("do", [])]
	for m in sp.get("modes", []):
		lists.append((m as Dictionary).get("do", []))
	for acts in lists:
		for a in acts:
			if str(a[0]) in ["atk", "def"] and a.size() > 2 and int(a[2]) > 0:
				return true
	return false


func _start_attack(inst) -> void:
	mode = "attack"
	_attacker = inst
	_clear_glows()
	board.card_for(inst).set_glow(true, UITheme.GOLD)
	for t in state.attack_targets_for(ME, inst):
		var c := board.card_for(t)
		if c:
			c.set_glow(true, UITheme.DANGER)
	board.start_aim(inst)
	board.show_direct_target(state.can_direct_attack_with(ME, inst))
	if state.can_direct_attack(ME):
		hud.show_prompt("No monsters in the way. Click their side of the field to attack directly!", false)
	elif state.can_direct_attack_with(ME, inst):
		hud.show_prompt(Loc.t("Click a monster, or their side of the field: %s can attack directly!") % inst.data.get("name", ""), false)
	else:
		hud.show_prompt(Loc.t("Tap a monster to attack with %s") % inst.data.get("name", ""), false)


func _on_direct_attack() -> void:
	if ocg != null:
		return
	if mode == "materials" and _my_turn():
		var target = _extra_target
		_cancel_mode()
		await _act("extra_summon", [ME, target, []], false)
		await _after_summon(ME)
		return
	if mode != "attack" or not _my_turn():
		return
	var a = _attacker
	_cancel_mode()
	await _do_attack(ME, a, null)


func _cancel_mode() -> void:
	if ocg != null:
		ocg.cancel()
	board.stop_aim()
	board.show_direct_target(false)
	mode = ""
	_pending_card = null
	_attacker = null
	_tributes = []
	hud.hide_prompt()
	hud.hide_actions()
	_refresh()


func _on_board_card_hovered(card: Card3D, inside: bool) -> void:
	if (mode == "attack" or not _drag_atk.is_empty()) and card.inst != null and state.players[AI].field.has(card.inst):
		board.set_aim_target(card if inside else null)
	if not inside or card.inst == null:
		return
	var inst = card.inst
	# Anything of theirs that is face-down (monsters, Set Spells and Traps) or in their hand stays secret.
	var theirs: bool = state.players[AI].field.has(inst) or state.players[AI].spells.has(inst) or state.players[AI].field_spell == inst
	var hidden: bool = (theirs and not inst.face_up) or state.players[AI].hand.has(inst)
	hud.inspect(inst, hidden)


var _end_armed := 0.0
var _btn_watch := 0.0


## A safety net: when something finished while the screen was busy (an attack and its replies)
## and nothing redrew the phase buttons, End turn stayed grey until a right-click. If it is your
## turn, nothing is in progress and the buttons are off, they are put right.
func _process(delta: float) -> void:
	_btn_watch -= delta
	if _btn_watch > 0.0:
		return
	_btn_watch = 0.3
	if _my_turn() and mode == "" and not _finished and hud.end_button_off() \
			and state.phase in [DuelState.Phase.MAIN1, DuelState.Phase.BATTLE, DuelState.Phase.MAIN2]:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and _my_turn():
		if Pad.b(event) == JOY_BUTTON_X:
			_on_phase_button("battle")
			get_viewport().set_input_as_handled()
			return
		if Pad.b(event) == JOY_BUTTON_Y:
			# Twice, so a slip of the thumb does not end your turn.
			var now := Time.get_ticks_msec() / 1000.0
			if now - _end_armed < 1.4:
				_on_phase_button("end")
			else:
				_end_armed = now
				Router.toast(Loc.t("Press %s again to end your turn") % Pad.g("Y"))
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_pause"):
		if mode != "" or hud.actions_visible():
			_cancel_mode()
		elif not hud.overlay_visible() and not _finished:
			hud.show_pause()
		elif hud.overlay_visible() and not _finished:
			hud.hide_overlay()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if mode != "" or hud.actions_visible() or busy or not _my_turn() or hud.overlay_visible() or _finished:
			_cancel_mode()
			if hud.actions_visible():
				hud.hide_actions()
				_menu_card = null
		else:
			# Right-click on the table: the phase moves open right where the pointer is.
			var opts := []
			match state.phase:
				DuelState.Phase.MAIN1:
					opts.append(["phase:battle", Loc.t("Battle Phase"), state.can_enter_battle()])
				DuelState.Phase.BATTLE:
					opts.append(["phase:battle", Loc.t("Main Phase 2"), true])
			opts.append(["phase:end", Loc.t("End turn"), true])
			_menu_card = null
			hud.show_actions(event.position, opts)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and hud.actions_visible():
		# A tap anywhere else puts the card's menu away. Cards on the table still get the tap.
		_closed_card = _menu_card
		_closed_at = Time.get_ticks_msec()
		hud.hide_actions()
		_menu_card = null
		_deck_menu = false


func _on_pause_action(action: String) -> void:
	match action:
		"open":
			if not _finished and not hud.overlay_visible():
				_cancel_mode()
				hud.show_pause()
		"resume":
			hud.hide_overlay()
			_refresh()
		"settings":
			SettingsPanel.open(hud)
		"surrender":
			hud.hide_overlay()
			_surrendered = true
			state.winner = AI
			state.win_reason = "You surrendered."
			_turn_finished.emit()
			if state.current == AI or busy:
				_finish()
		"rematch":
			if Router.duel_config.has("gauntlet"):
				# Start the whole run again from the first duelist.
				var rg: Dictionary = Router.duel_config["gauntlet"]
				var order: Array = rg.get("all", []).duplicate()
				Router.duel_config["opponent"] = order.pop_front()
				Router.duel_config.erase("opponent_coat")
				rg["left"] = order
				rg["stage"] = 1
				Router.duel_config.erase("my_lp")
			if Router.duel_config.get("match", false):
				_restore_match_deck()
				Router.match_state = {"wins": [0, 0], "game": 1, "last_loser": -1,
					"orig": {"main": Collection.main.duplicate(), "side": Collection.side.duplicate()}}
			Router.go(Router.DUEL)
		"next_game":
			Router.go(Router.DUEL)
		"gauntlet_next":
			var gc: Dictionary = Router.duel_config
			var gg: Dictionary = gc["gauntlet"]
			var rest: Array = gg["left"]
			if rest.is_empty() and gg.get("endless", false):
				# Survival: draw the next opponent from everyone, and they get tougher as you go.
				for k in Characters.ORDER:
					if str(k) != str(gc.get("opponent", "")) and CardData.has_deck(str(Characters.DATA[k].get("deck", ""))):
						rest.append(str(k))
				rest.shuffle()
				gc["difficulty"] = clampi(1 + int(gg.get("stage", 1)) / 3, 1, 3)
			if rest.is_empty():
				return
			gc["opponent"] = rest.pop_front()
			gc.erase("opponent_deck")
			gc["my_lp"] = maxi(1000, state.players[ME].lp)
			gg["stage"] = int(gg.get("stage", 1)) + 1
			gc["field"] = "auto"
			Router.go(Router.DUEL)
		"side_deck":
			var sw := SideSwap.new()
			hud.add_child(sw)
			sw.done.connect(func(): Router.go(Router.DUEL))
		"select":
			_restore_match_deck()
			Router.menu_open = "select"
			Router.go(Router.MAIN_MENU)
		"story_continue":
			Router.story_result = "won" if _won else "lost"
			Router.go(Router.duel_config.get("return_to", Router.STORY))
		"menu":
			_restore_match_deck()
			Router.go(Router.MAIN_MENU)
		"decks":
			# Lost a duel the story needs: straight to your decks. The story waits at this duel.
			_restore_match_deck()
			Router.menu_open = "decks"
			Router.go(Router.MAIN_MENU)


## Side Deck swaps only last for the Match: put the deck back the way it was built.
func _restore_match_deck() -> void:
	var ms: Dictionary = Router.match_state
	if ms.has("orig"):
		Collection.main = (ms["orig"]["main"] as Array).duplicate()
		Collection.side = (ms["orig"]["side"] as Array).duplicate()
		Collection.save()
	Router.match_state = {}


# ------------------------------------------------------------------ AI

func _ai_turn(who: int) -> void:
	# The other side's turn runs a notch quicker: you are watching, not deciding.
	# The opponent's turn plays at the same speed as yours: you need to see what they do.
	Settings.pace = 1.0
	await _ai_wait(0.45)
	var steps := 0
	while steps < 20 and not state.is_over() and not _finished:
		steps += 1
		var act := DuelAI.next_main_action(state, who, _level_for(who))
		if act.is_empty():
			break
		if act["do"] == "activate":
			var n0 := state.players[who].hand.size() + state.players[who].set_cards().size()
			await _activate_flow(who, act["card"], act.get("choice"))
			if state.players[who].hand.size() + state.players[who].set_cards().size() == n0:
				break
			await _ai_wait(0.35)
			continue
		var ev: Array = await _run(func(st, a): return DuelAI.apply(st, who, a[0]), [act], false)
		if ev.is_empty():
			break
		if act["do"] in ["summon", "extra", "special_hand", "flip"]:
			await _after_summon(who)
		await _settle()
		await _ai_wait(0.35)
	if state.can_enter_battle() and not state.is_over() and not _finished:
		var any_attack := false
		for m in state.players[who].monsters():
			if m.face_up and m.attack_pos and state.attacks_left(m) > 0:
				any_attack = true
		if any_attack:
			await _act("enter_battle", [])
			await _window(state.opponent(who), "battle_start", null, "")
			await _ai_wait(0.3)
			steps = 0
			while steps < 10 and not state.is_over() and not _finished:
				steps += 1
				var atk := DuelAI.next_attack(state, who, _level_for(who))
				if atk.is_empty():
					break
				await _do_attack(who, atk["card"], atk["target"])
				await _ai_wait(0.3)
			if not state.is_over() and not _finished:
				await _act("enter_main2", [])
				await _window(state.opponent(who), "phase", null, "Main Phase 2 begins. Activate a card?")
				steps = 0
				while steps < 10 and not state.is_over() and not _finished:
					steps += 1
					var act2 := DuelAI.next_main_action(state, who, _level_for(who))
					if act2.is_empty():
						break
					if act2["do"] == "activate":
						var n1 := state.players[who].hand.size() + state.players[who].set_cards().size()
						await _activate_flow(who, act2["card"], act2.get("choice"))
						if state.players[who].hand.size() + state.players[who].set_cards().size() == n1:
							break
						await _ai_wait(0.3)
						continue
					var ev2: Array = await _run(func(st, a): return DuelAI.apply(st, who, a[0]), [act2], false)
					if ev2.is_empty():
						break
					if act2["do"] in ["summon", "extra", "special_hand", "flip"]:
						await _after_summon(who)
					await _settle()
					await _ai_wait(0.3)
	await _ai_wait(0.3)


func _level_for(who: int) -> int:
	return _ai_level if who == AI else 1


func _ai_wait(sec: float) -> void:
	await get_tree().create_timer(Settings.t(sec)).timeout


func _run_ai(act: Dictionary, who: int) -> Array:
	match act["do"]:
		"activate":
			return state.activate(who, act["card"], act.get("choice"))
		"extra":
			return state.extra_summon(who, act["card"])
		"summon":
			return state.normal_summon(who, act["card"], act["tributes"], false)
		"set":
			return state.normal_summon(who, act["card"], act["tributes"], true)
		"flip":
			return state.flip_summon(who, act["card"])
		"position":
			return state.change_position(who, act["card"])
		"ignite":
			return state.ignite(who, act["card"])
		"gy_ignite":
			return state.gy_ignite(who, act["card"])
		"hand_ignite":
			return state.hand_ignite(who, act["card"])
		"speed":
			return state.speed_world(who, int(act["cost"]))
	return []



func _demo_actions() -> void:
	await get_tree().create_timer(0.6).timeout
	if "--demo-say" in OS.get_cmdline_user_args():
		var t := Timer.new()
		t.wait_time = 2.4
		t.autostart = true
		add_child(t)
		var both := func():
			hud.say(0, "My turn. Draw!")
			hud.say(1, "You're wasting my time. Let's get this over with.")
		t.timeout.connect(both)
		both.call()
	if "--demo-big" in OS.get_cmdline_user_args():
		hud.cut_in(0, "DARK MAGICIAN", "ATK 2500   ·   DEF 2100", Color("a070ff"), 30.0, true)
		return
	if "--demo-opp" in OS.get_cmdline_user_args():
		hud.cut_in(1, "BLUE-EYES WHITE DRAGON", "Attack!", Comic.RED, 30.0)
		return
	if "--demo-deck" in OS.get_cmdline_user_args():
		_on_deck_clicked()
		return
	if "--demo-clicks" in OS.get_cmdline_user_args():
		# Click probe: what a press on a hand card costs, and how long the frames after it take.
		await get_tree().create_timer(2.0).timeout
		for i in 8:
			var hand: Array = state.players[ME].hand
			if hand.is_empty():
				break
			var hc = hand[i % hand.size()]
			hud.inspect(hc)
			await get_tree().process_frame
			var t0 := Time.get_ticks_usec()
			_on_hand_card_pressed(hc, Vector2.ZERO)
			var t1 := Time.get_ticks_usec()
			await get_tree().process_frame
			var t2 := Time.get_ticks_usec()
			await get_tree().process_frame
			var t3 := Time.get_ticks_usec()
			await get_tree().process_frame
			var t4 := Time.get_ticks_usec()
			print("CLICK %s handler %.2f ms, frames after: %.1f %.1f %.1f ms  (menu %s)" % [hc.cname(), (t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0, (t4 - t3) / 1000.0, str(hud.actions_visible())])
			await get_tree().create_timer(0.5).timeout
			hud.hide_actions()
			_menu_card = null
			await get_tree().create_timer(0.3).timeout
		return
	for da in OS.get_cmdline_user_args():
		if da.begins_with("--demo-field="):
			# Dev: two of your monsters and one of theirs on the table, then you play this Field
			# Spell by its real rules (--demo-field=Mountain). A second name after a comma is
			# played by you three seconds later, in its place; "-" after a comma takes yours away again.
			var names := da.trim_prefix("--demo-field=").split(",")
			var z := 1
			for pl in [ME, AI]:
				var side = state.players[pl]
				z = 1
				for c in side.deck.duplicate():
					if z > (2 if pl == ME else 1):
						break
					if c.is_monster() and c.level() <= 4:
						side.deck.erase(c)
						side.field[z] = c
						c.face_up = true
						c.attack_pos = true
						await board.anim_summon(pl, c, z, false)
						z += 1
			board.sync_holos(state)
			board.refresh_stats(state)
			var fid := int(CardData.NAME_TO_ID.get(names[0].to_lower(), 0))
			if fid == 0:
				print("DEMO FIELD: no card called ", names[0])
				return
			var fc := state._make(fid, ME)
			state.players[ME].hand.append(fc)
			hud.add_hand_card(fc)
			await get_tree().create_timer(0.6).timeout
			await _play(state.activate(ME, fc))
			if names.size() > 1:
				await get_tree().create_timer(3.0).timeout
				if names[1] == "-":
					await _play(state._destroy_st(fc))
				else:
					var fc2 := state._make(int(CardData.NAME_TO_ID.get(names[1].to_lower(), 0)), ME)
					state.players[ME].hand.append(fc2)
					hud.add_hand_card(fc2)
					await _play(state.activate(ME, fc2))
			return
		if da.begins_with("--demo-tribute"):
			# Dev: two monsters on your field and a big one in hand, stopped at "what do I give up".
			var me = state.players[ME]
			var z := 1
			var put := []
			for c in me.deck.duplicate():
				if z > 2:
					break
				if c.is_monster() and c.level() <= 4:
					me.deck.erase(c)
					me.field[z] = c
					c.face_up = true
					c.attack_pos = true
					put.append(c)
					await board.anim_summon(ME, c, z, false)
					z += 1
			board.sync_holos(state)
			var big = null
			for want in [2, 1]:
				for c in me.hand + me.deck:
					if big == null and c.is_monster() and state.tributes_needed(c) == want:
						big = c
			if big == null:
				return
			if not me.hand.has(big):
				me.deck.erase(big)
				me.hand.append(big)
			_refresh()
			await get_tree().create_timer(1.5).timeout
			mode = "tribute"
			_pending_card = big
			_pending_set = false
			_tributes = [put[0]] if da.ends_with("=1") and not put.is_empty() else []
			_refresh_tribute()
			return
	for da2 in OS.get_cmdline_user_args():
		# --demo-drop (a monster), --demo-drop=spell, --demo-drop=trap: light the rows as if that
		# kind of card from your hand were being dragged.
		if not da2.begins_with("--demo-drop"):
			continue
		var want := da2.get_slice("=", 1) if "=" in da2 else "monster"
		for c in state.players[ME].hand:
			var is_kind: bool = (want == "monster" and c.is_monster()) or (want == "trap" and c.is_trap()) or (want == "spell" and c.is_spell())
			if is_kind and not _drop_plan(c).is_empty():
				hud.inspect(c)
				_on_hand_drag(c, true)
				return
	for c in state.players[ME].hand:
		if c.is_monster():
			hud.inspect(c)
			_on_hand_card_pressed(c, Vector2.ZERO)
			return


func _exit_tree() -> void:
	Settings.pace = 1.0
	Sfx.boost_db = 0.0
	Music.set_boost(0.0)
	if Engine.time_scale < 1.0:
		Engine.time_scale = 1.0
	DuelAI.styles = ["", ""]
	DuelAI.aces = [0, 0]
	if board and board.turbo:
		Sfx.ambience_pitch(1.0)
		Sfx.ambience("")
