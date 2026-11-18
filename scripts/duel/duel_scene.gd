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
	if not OcgTable.wanted(cfg):
		# The rules engine runs every duel. If its library did not load here, there is no duel.
		print("DUEL ENGINE not loaded: ", OcgCore.why_not())
		Router.toast(Loc.t("The rules engine did not load on this computer, so duels cannot start. Send the file engine_status.txt from the saves folder."), 9.0)
		Router.go(cfg.get("return_to", Router.MAIN_MENU))
		return
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
	var opp_ace := int(Characters.get_char(_opp_key).get("ace", 0))
	if opp_ace == 0:
		opp_ace = int(CardData.NAME_TO_ID.get(str(Characters.get_char(_opp_key).get("ace_name", "")).to_lower(), 0))
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
	# (A few duelists have a list the CPU can pilot: SignatureDecks.cpu picks it for the opponent only.)
	SignatureDecks.cpu = true
	var opp_list := CardData.legend_deck(opp_deck, opp_plain) if _ai_level >= 2 else CardData.deck_list(opp_deck, opp_plain)
	var opp_extra: Array[int] = CardData.extra_list(opp_deck, opp_plain)
	SignatureDecks.cpu = false
	var extra_hand := int(cfg.get("hand", 5)) - 5
	state.bonus_cards = [extra_hand, extra_hand]   # (the opponent's edge is how it thinks, not an extra card)
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
	if not _puzzle.is_empty():
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
	else:
		var speed0 := [0, 0]
		if state.turbo:
			var tune0 := int(Collection.record.get("runner_tune", 0))
			if cfg.has("speed_start"):
				speed0 = [int((cfg["speed_start"] as Array)[0]), int((cfg["speed_start"] as Array)[1])]
			elif tune0 > 0 and not _autoplay:
				speed0 = [tune0, 0]
		var lay := {"turbo": state.turbo}
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--lay="):
				# Dev: cards already in place, by name, from a JSON file:
				#   {"hand": [[..], [..]], "mons": [[[name, "atk"|"def"|"set"]], []], "st": [[name | [name, "up"]], []], "gy": [[..], [..]]}
				var lj = JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--lay=")))
				if lj is Dictionary:
					for k in lj:
						var sides: Array = []
						for side in lj[k]:
							var row: Array = []
							for x in side:
								row.append([Puzzles._id(str(x[0])), str(x[1])] if x is Array else Puzzles._id(str(x)))
							sides.append(row)
						lay[k] = sides
		ocg.prepare(my_list, opp_list, CardData.extra_list(my_deck), opp_extra, me_name, opp_name, first,
				[5 + int(state.bonus_cards[ME]), 5 + int(state.bonus_cards[AI])], lay,
				{"speed": speed0, "destiny": [state.destiny and state.destiny_who[ME], state.destiny and state.destiny_who[AI]]})
		events = []
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
		board.set_deck_count(p, state.players[p].deck.size())
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
		if "--ask-name" in OS.get_cmdline_user_args() or "--ask-name-typed" in OS.get_cmdline_user_args():
			# Dev: "declare 1 card name", first as it opens, then with a word typed in.
			var quick: Array = []
			for c in state.players[ME].hand:
				quick.append([c.id, c.cname()])
			var all: Array = []
			for id in Collection.all_cards():
				if OcgCore.announce_ok([0x7, 0x4000010200000000], int(id)):
					all.append([int(id), OcgCore.card_name(int(id))])
			all.sort_custom(func(x, y): return str(x[1]) < str(y[1]))
			if "--ask-name-typed" in OS.get_cmdline_user_args():
				get_tree().create_timer(1.5).timeout.connect(func():
					for n in hud.find_children("", "LineEdit", true, false):
						(n as LineEdit).text = "toon d"
						(n as LineEdit).text_changed.emit("toon d"))
			print("ASK NAME got ", await hud.ask_name(Loc.t("Declare 1 card name"), quick, all))
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
	events = ocg.begin()
	await _play(events)
	if not _puzzle.is_empty():
		# The position is laid out, then it is your move: this turn is the only one you get.
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
	await ocg.loop()
	_finish()


# ------------------------------------------------------------------ running the rules


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
				_leave_hand(ev["card"])
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
				_leave_hand(ev["card"])
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
				_leave_hand(ev["card"])
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
				_leave_hand(ev["card"])
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
				_leave_hand(ev["card"])
			_materials.append(ev["card"])
			Sfx.play("card", -4.0)
			await board.anim_material(p, ev["card"], ev["from"], board.monster_zone_pos(p, 2))
		"special":
			var method: String = ev["method"]
			if p == ME:
				_leave_hand(ev["card"])
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
				_leave_hand(ev["card"])
			await board.anim_discard(p, ev["card"])
		"banish":
			board.hide_stats_for(ev["card"])
			if str(ev.get("from", "")) == "hand" and int(ev.get("side", p)) == ME:
				_leave_hand(ev["card"])
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
		# (what a card effect makes them keep revealed: their hand, their Set cards)
		var shown: Array = []
		for c in ps.hand + ps.field + ps.spells:
			if c != null and c.tags.has("public") and (not c.face_up or ps.hand.has(c)):
				shown.append(c)
		if p == AI and not shown.is_empty() and (hud.revealed[p] as Array).is_empty():
			hud.feed(AI, "✦", Loc.t("Their cards are revealed. Click their Graveyard to look at them."))
		if "--ocg-log" in OS.get_cmdline_user_args() and shown.size() != (hud.revealed[p] as Array).size():
			print("REVEALED p", p, " ", shown.map(func(c): return c.cname()))
		hud.revealed[p] = shown
		hud.set_destiny(p, 0 if not (state.destiny and state.destiny_who[p]) else (2 if state.destiny_used[p] else 1))
		board.set_gy_count(p, ps.gy.size())


# ------------------------------------------------------------------ player input

var _flow := false   # true while a chain / target prompt is running


func _my_turn() -> bool:
	if _flow:
		return false
	return ocg.active() and not hud.overlay_visible()


func _refresh() -> void:
	ocg.refresh()


func _clear_glows() -> void:
	board.clear_picks()
	for p in 2:
		for m in state.players[p].monsters():
			var c := board.card_for(m)
			if c:
				c.set_glow(false)


func _on_phase_button(action: String) -> void:
	ocg.on_phase_button(action)


## Whether a hand card can be dragged onto the table right now (see OcgTable.drop_plan).
func _drop_plan(inst) -> Dictionary:
	return ocg.drop_plan(inst)


## A card leaves your hand to be played: the table is told where it was on the screen, so its
## flight starts from there.
func _leave_hand(inst) -> void:
	var at: Vector2 = hud.hand_card_center(inst)
	if at.x >= 0.0:
		board.fly_from = at
		board.fly_at = Time.get_ticks_msec()
	hud.remove_hand_card(inst)


func _on_hand_drag(inst, on: bool) -> void:
	ocg.on_hand_drag(inst, on)


## A hand card let go over the table. True when it lands on a zone that takes it.
func _on_hand_drop(inst, at: Vector2) -> bool:
	if not _my_turn() or mode != "":
		return false
	return ocg.on_hand_drop(inst, at)


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
	if not ocg.pile_effects().is_empty():
		# A card in your Graveyard can use its effect from there (Destiny HERO - Malicious).
		deck_opts.push_front(["gyfx", "Effect from the Graveyard", true])
	hud.show_actions(board.camera.unproject_position(board.deck_pos(ME)) + Vector2(-420, -60), deck_opts)


var _deck_menu := false
var _closed_card = null          # the card whose menu this very tap just closed
var _closed_at := 0


func _input(event: InputEvent) -> void:
	if ocg != null and not _finished and not hud.overlay_visible() and ocg.on_input(event):
		get_viewport().set_input_as_handled()


func _on_hand_card_pressed(inst, at: Vector2) -> void:
	ocg.on_hand_card_pressed(inst, at)


func _on_action(action: String) -> void:
	if action.begins_with("phase:"):
		hud.hide_actions()
		_on_phase_button(action.trim_prefix("phase:"))
		return
	if action == "gyfx":
		_deck_menu = false
		ocg.on_pile_effects()
		return
	if ocg.on_action(action):
		return
	_deck_menu = false
	match action:
		"surrender":
			var sure := await hud.ask_choice(Loc.t("Surrender this duel?"), [Loc.t("Keep dueling"), Loc.t("Surrender")])
			if sure == 1:
				_on_pause_action("surrender")
		"piles":
			hud.show_piles(ME)
		"pause":
			_on_pause_action("open")


func _on_board_card_clicked(card: Card3D) -> void:
	ocg.on_board_card_clicked(card)


## Speed World 2: pick which of its effects to pay for.
func _on_speed_pressed() -> void:
	ocg.on_speed_pressed()


func _on_extra_pressed() -> void:
	ocg.on_extra_pressed()




func _on_extra_chosen(inst) -> void:
	ocg.on_extra_chosen(inst)


## Their side of the field tapped while an attack is aimed, or the Confirm button of a pick on the table.
func _on_direct_attack() -> void:
	if mode == "attack":
		ocg.on_direct()
	else:
		ocg.on_prompt_button()


func _cancel_mode() -> void:
	if ocg != null and ocg.cancel():
		return
	board.stop_aim()
	board.show_direct_target(false)
	mode = ""
	hud.hide_prompt()
	hud.hide_actions()
	_refresh()


func _on_board_card_hovered(card: Card3D, inside: bool) -> void:
	if mode == "attack" and card.inst != null and state.players[AI].field.has(card.inst):
		board.set_aim_target(card if inside else null)
	if not inside or card.inst == null:
		return
	var inst = card.inst
	# Anything of theirs that is face-down (monsters, Set Spells and Traps) or in their hand stays secret.
	var theirs: bool = state.players[AI].field.has(inst) or state.players[AI].spells.has(inst) or state.players[AI].field_spell == inst
	var hidden: bool = ((theirs and not inst.face_up) or state.players[AI].hand.has(inst)) and not inst.tags.has("public")
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
			var rq: Dictionary = ocg.req
			if int(rq["t"]) == 10:
				opts.append(["phase:battle", Loc.t("Main Phase 2"), int(rq["to_m2"]) != 0, "repos", Loc.t("Back to playing cards")])
			elif state.phase == DuelState.Phase.MAIN1:
				opts.append(["phase:battle", Loc.t("Battle Phase"), int(rq["to_bp"]) != 0, "attack", Loc.t("Attack with your monsters")])
			opts.append(["phase:end", Loc.t("End turn"), int(rq["to_ep"]) != 0, "view", Loc.t("Your opponent plays next")])
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


func _ai_wait(sec: float) -> void:
	await get_tree().create_timer(Settings.t(sec)).timeout


func _exit_tree() -> void:
	Settings.pace = 1.0
	Sfx.boost_db = 0.0
	Music.set_boost(0.0)
	if Engine.time_scale < 1.0:
		Engine.time_scale = 1.0
	if board and board.turbo:
		Sfx.ambience_pitch(1.0)
		Sfx.ambience("")
