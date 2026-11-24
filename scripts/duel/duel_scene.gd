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
var _my_directs := 0          # direct attacks you made (a Practice class may ask for none)
var _my_summons_now := 0      # monsters you put on the field this turn, Normal and Special
var _my_summons_most := 0     # ... the most in any one of your turns
var _my_turns := 0            # turns of your own so far
var _theme := "duel"          # the music for this opponent
var _materials: Array = []
var _opened := false             # the opening already played on the field
var _vs_key := ""                # who this duelist is on your record (how the last duel with them went)
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
	if str(cfg0.get("opponent_model", "")) != "" and str(cfg0.get("opponent", "")) != "":
		Avatars.look_as[str(cfg0["opponent"])] = str(cfg0["opponent_model"])      # (a duelist of the worlds: see Avatars.look_as)
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
	board.finisher_hit.connect(func(at: Vector3, col: Color):
		var cam := get_viewport().get_camera_3d()
		var sp: Vector2 = hud.get_viewport_rect().size * 0.5
		if cam and not cam.is_position_behind(at):
			sp = cam.unproject_position(at)
		ScreenFx.flash(hud, Color.WHITE.lerp(col, 0.25), 0.4, 0.9)
		ScreenFx.shatter(hud, sp, 1.25)
		ScreenFx.speed_lines(hud, sp, Color(1, 1, 1, 0.8), 0.7))
	board.direct_clicked.connect(_on_direct_attack)
	board.ace_summoned.connect(func(inst):
		Sfx.play("gong", -9.0, 1.2)
		Sfx.play("rare", -8.0)
		if inst == _shown:
			return   # it already had its own arrival (SummonShow)
		hud.summon_cinematic(inst.cname(), int(inst.data.get("atk", 0)), int(inst.data.get("def", 0)),
			board._frame_color(inst), inst.owner == ME))
	hud.hand_card_pressed.connect(_on_hand_card_pressed)
	# A duelist's mouth moves for as long as their line takes to say (about 15 letters a second).
	hud.said.connect(func(sp: int, text: String): board.duelist_mouth(sp, clampf(text.length() * 0.065, 0.7, 4.0)))
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
	if FxDemo.wanted() != "":
		FxDemo.run(self)
	DuelFx.warm(board)
	ElementFx.warm(board)
	CardFx.warm(board)
	var opp_ace_id := int(Characters.get_char(_opp_key).get("ace", 0))
	if opp_ace_id != 0:
		board.ace_ids[opp_ace_id] = true
	var cfg: Dictionary = Router.duel_config
	if not OcgTable.wanted(cfg):
		# The rules engine runs every duel. If its library did not load here, there is no duel.
		print("DUEL ENGINE not loaded: ", OcgCore.why_not())
		Router.toast(Loc.t("The rules engine did not load on this computer, so duels cannot start. Send the file engine_status.txt from the saves folder."), 9.0)
		Router.go(cfg.get("return_to", Router.MAIN_MENU))
		return
	state = OcgMirror.new()
	ocg = OcgTable.new(self)
	# A recorded duel being played back (see Replays): the table takes everything from the recording.
	_replay = Router.duel_config.get("replay", {})
	ocg.replay = _replay
	if not _replay.is_empty():
		# (again here for "watch it again": the cards a replay brings with it are settled per table)
		Replays.settle(_replay, Router.duel_config)
		_replay_ui()
	else:
		Replays.last_saved = ""
		CardData.GUEST.clear()
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
	_vs_key = "%s|%s" % [_opp_key, opp_name]
	_me_key = cfg.get("player_char", "player")
	var me_info := Portraits.info(_me_key)
	var me_name: String = me_info.get("name", Profile.duelist_name)
	if not _replay.is_empty():
		# (the names the duel was played under, whoever is watching)
		me_name = str(_replay["setup"]["names"][0])
		opp_name = str(_replay["setup"]["names"][1])
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
			_go_live()
			hud.set_chrome(false)
			var dz := DuelBoard.DUELIST_Z
			var opp_col := Color(opp.get("color", UITheme.DANGER))
			var me_col: Color = me_info.get("color", Profile.color())
			var opp_sub: String = Loc.t("%s Deck") % CardData.deck_name(opp_deck)
			if str(opp.get("title", "")) != "":
				opp_sub = "%s  ·  %s" % [Loc.t(str(opp["title"])), opp_sub]
			board.cam_cut(Vector3(2.4, 1.25, -dz + 4.8), Vector3(0.0, 1.5, -dz))
			board.cam_drift(Vector3(1.3, 1.5, -dz + 3.4), 2.6)
			# The face-off: the music steps back while the two of them have their say.
			Voices.focus(true)
			await get_tree().create_timer(0.3).timeout
			# Each of them gets as long as their line takes out loud, so nobody talks over the other.
			var opp_line := _opp_intro()
			var opp_len := maxf(2.5, Voices.length(_opp_key, Characters.last_en, false) + 0.5)
			hud.name_plate(1, opp_name, opp_sub, opp_col, opp_len - 0.6, opp_line)
			Voices.say_kind(_opp_key, "intro", Characters.last_en, false)
			board.duelist_gesture(1, "intro")
			await get_tree().create_timer(opp_len).timeout
			board.cam_cut(Vector3(-2.4, 1.25, dz - 4.8), Vector3(0.0, 1.5, dz))
			board.cam_drift(Vector3(-1.3, 1.5, dz - 3.4), 2.2)
			var my_line := Loc.t(Characters.line(_me_key, "intro"))
			var my_len := maxf(2.0, Voices.length(_me_key, Characters.last_en, true) + 0.5)
			hud.name_plate(0, me_name, Loc.t("%s Deck") % CardData.deck_name(my_deck), me_col, my_len - 0.5, my_line)
			Voices.say_kind(_me_key, "intro", Characters.last_en, true)
			board.duelist_gesture(0, "intro")
			await get_tree().create_timer(my_len).timeout
			# Over your shoulder, the whole field between you and them.
			board.cam_cut(Vector3(3.0, 2.5, dz + 3.9), Vector3(-2.4, 1.2, -dz))
			board.cam_drift(Vector3(2.6, 2.7, dz + 3.5), 8.0)
			Voices.focus(false)
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
	var opp_plain := SignatureDecks.borrowed(str(DeckTiers.split(opp_deck)[0]), _opp_key) and not bool(cfg.get("opponent_deck_full", false))
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
	var my_extra: Array[int] = CardData.extra_list(my_deck)
	# Decks handed over as plain lists of cards (the Deck Building class): no Extra Deck.
	if cfg.has("player_list"):
		my_list.clear()
		my_extra.clear()
		for id in cfg["player_list"]:
			my_list.append(int(id))
	if cfg.has("opponent_list"):
		opp_list.clear()
		opp_extra.clear()
		for id in cfg["opponent_list"]:
			opp_list.append(int(id))
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
		ocg.prepare(my_list, opp_list, my_extra, opp_extra, me_name, opp_name, first,
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
	if Router.roam.get("fed", false) and not _autoplay and _replay.is_empty():
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
		_go_live()
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
		get_tree().create_timer(2.5).timeout.connect(func(): _lumen("start" if randf() < 0.6 else ("first" if state.current == ME else "second")))
	else:
		if fly:
			board.intro_flyover(2.5)
		await get_tree().create_timer(0.5).timeout
		_talk(AI, "intro", 1.0, 0.0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--rider-shot="):
			var rs := int(a.substr(13))
			board.duelist_shot(rs, 0.1)
			for k in 40:
				var pose := ""
				for pa in OS.get_cmdline_user_args():
					if pa.begins_with("--pose="):      # dev: look at one motion, slowed down (--rider-shot=0 --pose=draw --shots=x)
						pose = pa.substr(7)
				if pose != "":
					# (several motions, one after the other: --pose=draw,play,point)
					var list := pose.split(",")
					if k >= list.size():
						break
					var one := str(list[k])
					if one.begins_with("act:"):      # (a moment of the duel, with everything that goes with it: --pose=act:draw)
						print("POSE ", one, " ", board.duelist_act(rs, one.substr(4)))
					else:
						print("POSE ", one, " ", (board._duelists[rs] as RoamFigure).gesture(one, 0.25))
					await get_tree().create_timer(4.6).timeout
				elif "--pose-lose" in OS.get_cmdline_user_args():
					(board._duelists[rs] as RoamFigure).play_once("lose")
				else:
					board.duelist_gesture(rs, "intro")
				if pose == "":
					if k >= 12:
						break
					await get_tree().create_timer(2.5).timeout
	if not _autoplay and _puzzle.is_empty():
		# A held breath, then both of them shout it as the word lands and the music comes back up.
		Voices.focus(true)
		await get_tree().create_timer(0.35).timeout
		Voices.shout(_me_key, _opp_key, Voices.DUEL)
		Voices.focus(false)
	await hud.banner("DUEL!", Comic.YELLOW)
	if "--handtest" in OS.get_cmdline_user_args():
		# Dev: move the hand around with the mouse and print what happened (see DuelHud.dev_hand_test).
		get_tree().create_timer(9.0).timeout.connect(hud.dev_hand_test)
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
	if "--level-demo" in OS.get_cmdline_user_args():
		# Dev: two monsters of yours on the field, then the Level of one is lowered by an effect:
		# its star must say the new Level (0.72.5).
		await _play(events)
		var lv_a = state._make(89631139, ME)
		var lv_b = state._make(70781052, ME)
		state.players[ME].field[1] = lv_a
		state.players[ME].field[2] = lv_b
		lv_a.face_up = true
		lv_b.face_up = true
		await board.anim_summon(ME, lv_a, 1, false)
		await board.anim_summon(ME, lv_b, 2, false)
		board.refresh_stats(state)
		await get_tree().create_timer(1.0).timeout
		lv_a.lv_set = maxi(1, lv_a.level() - 1)
		lv_b.lv_set = lv_b.level() + 2
		board.refresh_stats(state)
		hud.inspect(lv_a)
		return
	if "--extra-demo" in OS.get_cmdline_user_args():
		# Dev: the Extra Deck list with a full Extra Deck (15), two of them ready.
		await _play(events)
		var demo: Array = []
		var n := 0
		for cid in Collection.all_cards():
			if CardData.is_extra(int(cid)) and n < 15:
				var inst := DuelState.CardInst.new()
				inst.id = int(cid)
				inst.uid = 9000 + n
				inst.data = CardData.get_card(int(cid))
				inst.owner = ME
				demo.append([inst, "Synchro Summon" if n in [6, 11] else "Needs its materials", n in [6, 11]])
				n += 1
		hud.show_extra(demo)
		return
	if "--why-demo" in OS.get_cmdline_user_args() or "--why-log" in OS.get_cmdline_user_args():
		# Dev: the reasons on screen (DuelWhy): a reason card, what is in force by each Life Points, the log.
		await _play(events)
		var w := DuelWhy.new()
		w.names = [state.players[ME].name, state.players[AI].name]
		var ev2: Array = []
		var peace := 33782437
		var roar := 36361633
		for m in [{"t": 40, "p": 0}, {"t": 70, "card": {"code": peace, "con": 0}, "n": 1}, {"t": 72, "n": 1}, {"t": 73, "n": 1}, {"t": 74},
				{"t": 70, "card": {"code": roar, "con": 0}, "n": 1}, {"t": 72, "n": 1}, {"t": 73, "n": 1}, {"t": 74},
				{"t": 40, "p": 1}, {"t": 110, "a": {"con": 1, "loc": 4, "seq": 0}, "b": {"con": 1, "loc": 0, "seq": 0}},
				{"t": 111, "a": {"con": 1, "loc": 4, "seq": 0}, "aa": 4400, "b": {"con": 1, "loc": 0, "seq": 0, "pos": 0}}, {"t": 10}]:
			w.read(m, ev2, ocg.d)
		for e in ev2:
			if e["type"] == "log":
				hud.log_line(int(e["player"]), str(e["icon"]), str(e["text"]))
		hud.why_ui.set_status(0, w.statuses(0))
		hud.why_ui.set_status(1, w.statuses(1))
		if "--why-demo" in OS.get_cmdline_user_args():
			await get_tree().create_timer(10.5).timeout
		hud.why_ui.show_why(0, Loc.t("NO DAMAGE"), Loc.t("You take no damage from this battle (%d): %s.") % [4400, "One Day of Peace"], peace)
		if "--why-log" in OS.get_cmdline_user_args():
			hud.log_line(1, "⚔", Loc.t("%s attacks you directly") % "Cyber Twin Dragon")
			hud.log_line(0, "−", Loc.t("Paid %d Life Points") % 1000 + " · Hope for Escape")
			hud.log_line(1, "+", Loc.t("Gained %d Life Points") % 3000 + " · Gift Card")
			hud.show_log()
		return
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
						var word := OS.get_environment("ASK_WORD") if OS.has_environment("ASK_WORD") else "toon d"
						(n as LineEdit).text = word
						(n as LineEdit).text_changed.emit(word))
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
		for wa in OS.get_cmdline_user_args():
			# Dev: --end-test --win=destiny_board | countdown | deckout | card:<id> [--lose]
			if wa.begins_with("--win="):
				state.win_kind = wa.substr(6)
		if "--exodia" in OS.get_cmdline_user_args():
			# Dev: the duel ends with the five pieces (--end-test --exodia [--lose]).
			state.win_kind = "exodia"
			state.win_reason = OcgCore.victory(16)
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
		if da == "--demo-chain":
			await _demo_chain()
			await get_tree().create_timer(600.0).timeout
			return
	await ocg.loop()
	if not _replay.is_empty() and not state.is_over() and not _finished:
		# The recording ends before the engine names a winner: a surrender, or the game was closed.
		# Or this version of the game could not follow it: then it still ends the way the duel ended.
		var res: Dictionary = _replay.get("result", {})
		var unread: bool = ocg._replay_at + 1 < (_replay.get("tape", []) as Array).size() and ocg._replay_at < (_replay.get("answers", []) as Array).size()
		if unread or ocg.replay_broken != "":
			_r_bailed = true
			if ocg.replay_broken == "":
				ocg.replay_broken = "stopped at step %d of %d" % [ocg._replay_at, (_replay.get("tape", []) as Array).size()]
			print("REPLAY BAIL: ", ocg.replay_broken)
		_surrendered = bool(res.get("surrendered", false))
		state._set_winner(int(res.get("winner", DuelState.DRAW)), str(res.get("reason", "")))
	_finish()


# ------------------------------------------------------------------ running the rules


func _where(c) -> String:
	# (whole phrases, so each one can be said properly in Spanish: it used to glue "Your" to a translated word)
	for q in 2:
		var ps: DuelState.PlayerState = state.players[q]
		var mine := q == ME
		if ps.hand.has(c): return Loc.t("Your hand") if mine else Loc.t("Their hand")
		if ps.field.has(c) or ps.spells.has(c) or ps.field_spell == c: return Loc.t("Your field") if mine else Loc.t("Their field")
		if ps.gy.has(c): return Loc.t("Your Graveyard") if mine else Loc.t("Their Graveyard")
		if ps.deck.has(c): return Loc.t("Your Deck") if mine else Loc.t("Their Deck")
		if ps.banished.has(c): return Loc.t("Your banished cards") if mine else Loc.t("Their banished cards")
		if ps.extra.has(c): return Loc.t("Your Extra Deck") if mine else Loc.t("Their Extra Deck")
	return ""


func _finish() -> void:
	if _finished:
		return
	_finished = true
	# The duel is written down the moment it is decided (0.64.0), so it is there even if the game is
	# closed during the ending. Watching a replay writes nothing and costs nothing.
	if _replay.is_empty() and not _autoplay and ocg != null and not ocg.rec.is_empty():
		var rp := Replays.save(ocg.rec, {"winner": int(state.winner), "reason": str(state.win_reason), "kind": str(state.win_kind),
			"turns": int(state.turn), "lp": [int(state.players[ME].lp), int(state.players[AI].lp)], "surrendered": _surrendered, "hash": int(ocg.ev_hash)})
		print("REPLAY saved ", rp.get_file(), " answers ", (ocg.rec["answers"] as Array).size(), " hash ", ocg.ev_hash)
	# A duel takes an hour of the day (puzzles are off the clock).
	if _puzzle.is_empty() and _replay.is_empty():
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
	# (0.60.0) The five pieces of Exodia: the win gets its show before anything else.
	# (0.61.0) So do the other special endings: Destiny Board, Final Countdown, an empty Deck,
	# any card that wins by its own effect.
	var wk := str(state.win_kind)
	if wk != "" and not tied and not board.turbo and not _surrendered:
		if wk == "exodia":
			await ExodiaShow.play(self, board, hud, int(state.winner))
		else:
			await WinShow.play(self, board, hud, int(state.winner), wk)
	if not _replay.is_empty():
		await _replay_end(won, tied, wk)
		return
	if "--auto-story" in OS.get_cmdline_user_args():
		get_tree().create_timer(2.0).timeout.connect(func():
			Router.story_result = "won" if state.winner == ME else "lost"
			Router.go(Router.duel_config.get("return_to", Router.STORY)))
	if _human_test:
		print("PROMPTS: ", _asked)
	print("DUEL OVER: winner %d (%s) LP %d vs %d turn %d" % [state.winner, state.win_reason, state.players[0].lp, state.players[1].lp, state.turn])
	Router.last_stats = {"won": won and not _surrendered, "lp": int(state.players[ME].lp), "turns": int(state.turn), "low": int(_my_low),
			"directs": _my_directs, "summons": _my_summons_most}
	var earned := 0
	if not _puzzle.is_empty():
		# A puzzle is not a duel on your record: solving it pays once, and that is all.
		if won:
			earned = Puzzles.mark(str(_puzzle["id"]))
			Collection.last_reward = [["Puzzle solved", earned]] if earned > 0 else []
	elif not _autoplay:
		Profile.record_result(won, _vs_key)
		var my_lp: int = state.players[ME].lp
		var rinfo := {}
		if Router.duel_config.has("stake"):
			rinfo["stake"] = int(Router.duel_config["stake"])   # what they put on the line when they challenged you
		earned = Collection.reward(won and not _surrendered, _ai_level, rinfo.merged({"opponent": _opp_key, "lp": my_lp,
			"flawless": my_lp >= int(_start_lp[ME]), "turns": state.turn,
			"deck": str(DeckTiers.split(str(Router.duel_config.get("opponent_deck", Characters.get_char(_opp_key).get("deck", ""))))[0]), "rare": bool(Router.duel_config.get("rare", false))}))
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
	# The winner gets the camera.
	var champ := ME if won else AI
	if not tied and board.track == null and not _autoplay and board.has_duelist(ME) and board.has_duelist(AI):
		await _outro(won, wk != "" and not _surrendered)
	else:
		_last_words(won, tied)
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
	if "--result-long" in OS.get_cmdline_user_args():
		# dev: the longest results there can be (a card handed over, every bonus), to see that it fits
		for extra in [["First win against this duelist", 100], ["First win of the day", 150], ["Medal: Victory", 60], ["Medal: Standing", 120], ["Medal: Swift", 120], ["Win streak x7", 70]]:
			Collection.last_reward.append(extra)
		Collection.last_prize = 99267150
		earned = maxi(earned, 1)
	if "--result-replay" in OS.get_cmdline_user_args() and Replays.last_saved == "" and not Replays.list().is_empty():
		Replays.last_saved = str(Replays.list()[0]["path"])      # dev: a results screen with a replay to its name, for a picture
	hud.show_result(won, why, cfg.get("story", false), cfg.get("lose_ok", false), cfg.get("continue_label", "Continue Story"),
			{"turns": state.turn, "lp": [state.players[ME].lp, state.players[AI].lp], "names": [state.players[ME].name, state.players[AI].name],
			"reward": Collection.last_reward.duplicate() if earned > 0 else [], "earned": earned,
			"prize": Collection.last_prize if (earned > 0 and won) else 0,
			"free": not cfg.has("return_to") and not cfg.get("story", false), "draw": tied, "match": match_info,
			"replay": Replays.last_saved != "", "replay_path": Replays.last_saved,
			"task": cfg.get("task", false)})
	_won = won


# ------------------------------------------------------------------ events

func _play(events: Array) -> void:
	busy = true
	_refresh()
	# (0.57.0) The attack that ends the duel is played as the finishing blow.
	for i in events.size():
		var fe: Dictionary = events[i]
		if str(fe["type"]) == "lp" and int(fe.get("delta", 0)) < 0 and int(fe.get("lp", 1)) <= 0:
			for k in range(i - 1, -1, -1):
				if str(events[k]["type"]) == "battle":
					events[k]["finisher"] = true
					fe["finished"] = true
					break
			break
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
	"start": ["I'm in your deck! Draw me, draw me!", "Okay. Deep breath. I believe in you. Also in me. Mostly you.", "New duel, new us! Well. Same us. But ready!", "I shuffled myself extra well this time. You're welcome."],
	"me": ["That's me! Hi! One monster for your hand, coming right up!", "I'm on the field! Don't look at my ATK. Look at my heart.", "Ta-da! It's me! Try to look impressed.", "Lumen, reporting for duty! Small but mighty!"],
	"my_ace": ["Ooh, the big one! Get them!", "THERE it is! I love this part!", "Yes! YES! That's the one I was hoping for!", "Your ace is here! Everybody look busy!"],
	"their_ace": ["That's their best monster. Don't panic. I'm panicking, but you shouldn't.", "Uh oh. Big. Very big. You have a plan, right?", "Okay, that one has a LOT of teeth. We've handled worse. Probably.", "Their ace. Great. Fine. We planned for this. Did we plan for this?"],
	"ace_down": ["You took down their ace! Did you see their face?!", "Their best monster is GONE! Keep going!", "Boom! Their ace is history!", "That was their best card! Not anymore!"],
	"ace_lost": ["Your ace... okay. Okay! We can still do this.", "It's fine! We have more cards! ...We have more cards, right?", "They got your ace... Shake it off! The duel isn't over.", "Ouch. Okay, new plan. I like new plans."],
	"my_low": ["Your Life Points are low. I'm not worried. *bzzt* I'm a little worried.", "Careful! One more hit like that and we're done!", "We're hanging by a thread. A very brave thread!", "Life Points are getting low. Time for something clever!"],
	"their_low": ["They're almost out! One more push!", "They're on the ropes! Finish it!", "They're wobbling! One good hit!", "Look at their Life Points! We're so close!"],
	"hit": ["Ow! That one hurt just to watch.", "Okay, that was a lot of Life Points. We still have the rest!", "Yikes! Okay, we felt that.", "That stung. We're still standing!"],
	"direct": ["Right through! Nothing in the way!", "Direct hit! They felt that one!", "Wide open! Go, go, go!", "Straight to their Life Points! Beautiful!"],
	"trap": ["A Trap! I KNEW that card looked shifty.", "They were waiting for that. Sneaky.", "A Trap! Of course there was a Trap.", "Sneaky! I should have seen that coming."],
	"topdeck": ["No cards in hand... so the next one has to count. No pressure!", "Empty hand. This is where the good draws happen. Right? Right.", "Nothing in hand. Everything rides on the next draw!", "One card at a time. That's all we need."],
	"comeback": ["You're back in it! I never doubted you. *bzzt* Much.", "From almost nothing to THIS? That's my duelist!", "And we're back! I knew it the whole time!", "What a turnaround! Do that again!"],
	"destiny": ["{player}. The Deck is listening. Ask it for the one card you need!", "This is it. One card can turn this around. Reach for it!", "I can feel it. The next card is the one. Draw!", "Deep breath... now reach for it!"],
	"their_destiny": ["They can do that too?! Okay. Okay. Stay sharp.", "That was THEIR big draw. Whatever it is, we can take it.", "Uh oh. Their deck answered them. Heads up!", "A big draw for them. Stay calm. Stay very calm."],
	"first": ["We go first! First is good. I like first.", "First turn! No pressure. Okay, a little pressure."],
	"second": ["They go first. Fine! We get to see their plan.", "Second is okay! Second gets to draw."],
	"long": ["This is a long one! I'm not tired. Are you tired?", "Still going! This is the good kind of long."],
	"thin_deck": ["Um. The Deck is getting thin. Just saying!", "Only a few cards left in there. Make them count!"],
	"win": ["We won! I knew it! I mostly knew it!", "Victory! High five! I don't have hands. Imagine it!"],
	"close_win": ["We won! By THIS much! I'm shaking!", "That was so close! Never do that to me again. Okay, do it again."],
	"flawless": ["Not a scratch on us! Did they even play?", "A perfect duel! Frame it!"],
	"lose": ["Hey. We lost. It happens to the best. That's us.", "It's okay. I saw three things we do better next time."],
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


# ---------------------------------------------------------------- watching a replay
const ReplayBar := preload("res://scripts/duel/replay_bar.gd")
var _rbar: Control
var _r_speed := 1.0
var _r_paused := false
var _r_hands := false
var _r_skip_from := -1       # the turn a "to the next turn" started on (-1: not skipping)

func _replay_ui() -> void:
	var res: Dictionary = _replay.get("result", {})
	var title := "%s  ·  %s" % [str(_replay.get("date", "")), Loc.t("%d turns") % int(res.get("turns", 0))]
	_rbar = ReplayBar.new(title)
	hud.replay_controls(_rbar)
	_rbar.pause_toggled.connect(func(on): _r_paused = on)
	_rbar.speed_picked.connect(func(x): _r_speed = x)
	_rbar.skip_turn.connect(func():
		if _r_skip_from < 0 and not _finished:
			_r_skip_from = int(state.turn)
			_rbar.skipping(true))
	_rbar.hands_toggled.connect(func(on):
		_r_hands = on
		if state != null and state.players.size() > 1:
			hud.set_opp_hand(state.players[AI].hand, on))
	_rbar.leave.connect(func(): _on_pause_action("replay_back"))
	# What this version of the game does not have (a replay from a later version, or from someone
	# with other cards): said once, and the replay plays anyway.
	var lost: Dictionary = Router.duel_config.get("replay_lost", {})
	var said: Array = []
	if int(lost.get("cards", 0)) > 0:
		said.append(Loc.t("This replay has %d cards that this version of the game does not have. They are shown by name.") % int(lost["cards"]))
	if bool(lost.get("duelist", false)):
		said.append(Loc.t("Its duelist is not in this version of the game, so someone else stands in."))
	if not said.is_empty():
		print("REPLAY missing here: ", lost)
		get_tree().create_timer(1.2).timeout.connect(func(): Router.toast(" ".join(said)))
	for a in OS.get_cmdline_user_args():
		if a == "--replay-hands":
			_rbar._eye_btn.pressed.emit()      # dev: start with both hands shown (for a picture)
		elif a.begins_with("--replay-speed="):
			_r_speed = float(a.substr(15))     # dev: a quick run to the end


## Every frame of a replay: its speed, its pause, the rush to the next turn, the rival's hand.
func _replay_tick() -> void:
	if _human_test:
		return      # (a test runs the clock itself)
	if _finished and _r_skip_from >= 0:
		_r_skip_from = -1
	if _r_skip_from >= 0 and int(state.turn) != _r_skip_from:
		_r_skip_from = -1
		if is_instance_valid(_rbar):
			_rbar.skipping(false)
	var want := _r_speed
	if _r_skip_from >= 0:
		want = 12.0
	if _r_paused:
		want = 0.0001      # (not zero: a few things divide by the time a frame took)
	Voices.muted = want > 1.01
	# (a slow-motion moment of the duel itself is left alone: it sets the clock below 1 and back to 1)
	if _r_paused or _finished:
		Engine.time_scale = want if not _finished else 1.0
	elif Engine.time_scale >= 0.99 or Engine.time_scale < 0.001:
		Engine.time_scale = want
	if _r_hands and not _finished and state != null and state.players.size() > 1:
		hud.set_opp_hand(state.players[AI].hand, true)
	# A replay never leaves you stuck: if nothing has moved for a long while (a recording this
	# version of the game cannot follow), it goes to its end and shows how the duel ended.
	var now := Time.get_ticks_msec()
	var dt := clampf((now - _r_last_ms) / 1000.0, 0.0, 0.25) if _r_last_ms > 0 else 0.0
	_r_last_ms = now
	if ocg != null and not _finished and not _r_paused:
		if ocg._replay_at != _r_seen:
			_r_seen = ocg._replay_at
			_r_stall = 0.0
		else:
			_r_stall += dt * maxf(1.0, Engine.time_scale)
			if _r_stall > REPLAY_STALL:
				_replay_bail("nothing moved after step %d" % ocg._replay_at)


const REPLAY_STALL := 100.0      # seconds of the duel's own time
var _r_seen := -1
var _r_stall := 0.0
var _r_last_ms := 0
var _r_bailed := false

func _replay_bail(why: String) -> void:
	if _finished:
		return
	print("REPLAY BAIL: ", why)
	ocg.replay_broken = why
	_r_bailed = true
	var res: Dictionary = _replay.get("result", {})
	state.winner = int(res.get("winner", DuelState.DRAW))
	state.win_reason = str(res.get("reason", ""))
	state.win_kind = ""
	_surrendered = bool(res.get("surrendered", false))
	Engine.time_scale = 1.0
	_finish()


## A replay is over: the ending plays like the duel's own, then the way out. Nothing is won, lost
## or written. (Also prints what a test compares with the original.)
var _replay := {}

func _replay_end(won: bool, tied: bool, wk: String) -> void:
	var res: Dictionary = _replay.get("result", {})
	var same: bool = ocg.replay_broken == "" and int(res.get("hash", 0)) == int(ocg.ev_hash) and int(res.get("winner", -9)) == int(state.winner) and int(res.get("turns", -9)) == int(state.turn)
	print("REPLAY END: winner %d turn %d LP %d vs %d hash %d | recorded winner %d turn %d hash %d | %s" % [state.winner, state.turn, state.players[ME].lp, state.players[AI].lp,
		ocg.ev_hash, int(res.get("winner", -9)), int(res.get("turns", -9)), int(res.get("hash", 0)), "MATCH" if same else ("BROKEN " + ocg.replay_broken)])
	replay_same = same
	if not _r_bailed and not tied and not _surrendered and not _autoplay and board.track == null and board.has_duelist(ME) and board.has_duelist(AI):
		await _outro(won, wk != "")
	replay_over.emit()
	if _autoplay or _human_test:
		return
	var who := str(state.players[int(state.winner)].name) if int(state.winner) in [0, 1] else ""
	var turns := int(res.get("turns", state.turn)) if _r_bailed else int(state.turn)
	var line := Loc.t("A draw.") if who == "" else (Loc.t("%s surrendered.") % str(state.players[ME].name) if _surrendered else Loc.t("%s won in %d turns.") % [who, turns])
	if _r_bailed:
		line = Loc.t("This version of the game could not show this replay to the end.") + "\n" + line
	hud.show_replay_over(Loc.t("REPLAY OVER"), line, UITheme.GOLD if int(state.winner) == ME else Color.WHITE, str(_replay.get("path", "")))

signal replay_over
var replay_same := false


## How fast a chain is shown (Settings > Gameplay > Chain pace): Normal, Slower, Fast.
func _chain_pace() -> float:
	if "--demo-slow" in OS.get_cmdline_user_args():
		return 5.0      # dev: long enough to photograph each moment under a slow renderer
	return float([1.0, 1.7, 0.5][clampi(int(Settings.chain_pace), 0, 2)])


## Dev: a chain of four with one negated, played through the real event code ("--demo-chain").
func _demo_chain() -> void:
	await get_tree().create_timer(2.5).timeout
	var ids := [[83968380, ME], [37576645, AI], [30461781, ME], [98444741, ME]]
	var cards: Array = []
	for pair in ids:
		cards.append(state._make(int(pair[0]), int(pair[1])))
	for i in cards.size():
		await _play_event({"type": "chain_link", "n": i + 1, "player": int(ids[i][1]), "card": cards[i]})
		await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(1.2).timeout
	for n in [4, 3, 2, 1]:
		await _play_event({"type": "chain_solving", "n": n, "player": int(ids[n - 1][1])})
		if n == 2:
			await _play_event({"type": "chain_negated", "n": n, "player": int(ids[n - 1][1]), "card": cards[n - 1]})
		await get_tree().create_timer(0.6).timeout
		await _play_event({"type": "chain_solved", "n": n, "player": int(ids[n - 1][1])})
	await _play_event({"type": "chain_end", "player": 0})


## The sound of taking a hit, from the one who took it. Small ones are not repeated back to back
## (a burn deck chipping away every second would be a lot of grunting).
var _ouch_at := [-99.0, -99.0]

func _ouch(p: int, kind: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if kind == "small" and now - float(_ouch_at[p]) < 4.0:
		return
	var secs := Voices.pain(_speaker(p) if p == ME else _opp_key, kind, p == ME)
	if secs > 0.0:
		_ouch_at[p] = now
		board.duelist_mouth(p, minf(secs, 1.2))


## Once the duel is decided (a hit took someone to 0, or it ended any other way) the only words
## left are the ending's: the winner's, the loser's and Lumen's last one.
var _decided := false
const LAST_WORDS := ["win", "lose", "flawless", "close_win"]

func _lumen(kind: String) -> void:
	if _autoplay or _lumen_said.has(kind) or not LumenBubble.with_you() or not LUMEN_SAYS.has(kind):
		return
	if (_decided or _finished) and not kind in LAST_WORDS:
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
	var said := str(lines[randi() % lines.size()])
	# Her bubble stays up for as long as she is talking (her voice may start a moment late, after a duelist's).
	_lumen_box.say(said, maxf(2.6 + said.length() * 0.055, Voices.length("lumen", said) + 1.2))
	Voices.say("lumen", said, true, true)
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


## What the opponent opens with: their own intro or, two times out of three when you have met
## before, a word about how the last duel went. Leaves the English in Characters.last_en.
func _opp_intro() -> String:
	var line := Characters.line(_opp_key, "intro")
	var rem := Voices.rematch_line(_opp_key, Profile.last_vs(_vs_key))
	if rem != "" and randf() < 0.67:
		Characters.last_en = rem
		return Loc.t(rem)
	return line


## A duelist says a line of a kind (a bubble, a gesture, and their voice when they have one).
## `card_id`: the monster that just hit the field; a duelist with a call-out for it names it instead.
## The last words of a duel: the winner first, then the loser, then Lumen. Each one waits for the
## one before, so nobody talks over anybody. (Runs beside the ending; it does not hold it up.)
func _last_words(won: bool, tied: bool) -> void:
	if tied:
		hud.say(AI, Characters.line(_opp_key, "win"))
		Voices.say_kind(_opp_key, "win", Characters.last_en, false)
		return
	for p in ([ME, AI] if won else [AI, ME]):
		var who := _speaker(p) if p == ME else _opp_key
		var kind := "win" if (p == ME) == won else "lose"
		var line := Characters.line(who, kind)
		if line == "":
			continue
		hud.say(p, line)
		var n := Voices.length(who, Characters.last_en, p == ME)
		Voices.say_kind(who, kind, Characters.last_en, p == ME)
		await get_tree().create_timer(maxf(1.5, n + 0.35)).timeout
		if not is_inside_tree():
			return
	_lumen_last(won)


## The ending scene (0.63.0): the loser takes it in, the winner has their moment and their line, the
## loser answers, and the camera pulls back over the arena before the results. About 7 seconds; any key
## or button skips it. short: after a special win's own show (Exodia, Destiny Board...) only the winner,
## the lines and the pull back.
var _outro_on := false
var _outro_skip := false

func _outro(won: bool, short: bool) -> void:
	var champ := ME if won else AI
	var loser := 1 - champ
	_outro_on = true
	_outro_skip = false
	if "--pose-debug" in OS.get_cmdline_user_args():
		print("OUTRO start short=", short, " t=", Time.get_ticks_msec())
	if not short:
		board.duelist_lose(loser)
		board.duelist_shot(loser, 0.5, false, 0.8)
		await _outro_wait(1.6)
	# The winner: their pose and their line.
	if not _outro_skip:
		board.duelist_shot(champ, 0.6 if short else 0.0, true, 1.0)
		var n := _say_last(champ, "win")
		await _outro_wait(maxf(1.8, n + 0.3))
	# The loser answers.
	if not short and not _outro_skip:
		board.duelist_shot(loser, 0.0, false, 0.8, 3.0)
		var n2 := _say_last(loser, "lose")
		await _outro_wait(maxf(1.5, n2 + 0.3))
	# Back over the arena, the house still on its feet; Lumen has the last word.
	board.outro_pullback(champ, 2.0 if not _outro_skip else 0.6)
	_lumen_last(won)
	await _outro_wait(1.8)
	_outro_on = false
	if "--pose-debug" in OS.get_cmdline_user_args():
		print("OUTRO end skip=", _outro_skip, " t=", Time.get_ticks_msec())


func _outro_wait(secs: float) -> void:
	var until := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < until and not _outro_skip and is_inside_tree():
		await get_tree().process_frame


## A duelist's last line of the duel (the bubble and the voice). Returns how long the voice takes.
func _say_last(p: int, kind: String) -> float:
	var who := _speaker(p) if p == ME else _opp_key
	var line := Characters.line(who, kind)
	if line == "":
		return 0.0
	hud.say(p, line)
	var n := Voices.length(who, Characters.last_en, p == ME)
	Voices.say_kind(who, kind, Characters.last_en, p == ME)
	return n


func _lumen_last(won: bool) -> void:
	var lp := int(state.players[ME].lp)
	if not won:
		_lumen("lose")
	elif lp >= int(_start_lp[ME]):
		_lumen("flawless")
	elif lp <= 1000:
		_lumen("close_win")
	else:
		_lumen("win")


## The calls of a turn (0.63.0). How often each one is said goes by Settings.talk:
## [big moments only, the normal amount, every action].
const CALLS := {"turn": [0.0, 1.0, 1.0], "first": [0.0, 1.0, 1.0], "battle": [0.0, 1.0, 1.0], "direct": [0.0, 1.0, 1.0],
	"hurt_big": [0.0, 1.0, 1.0], "end": [0.0, 0.5, 1.0], "summon": [0.0, 0.55, 1.0], "set_mon": [0.0, 0.3, 1.0],
	"attack": [0.3, 0.6, 1.0], "set": [0.25, 0.35, 1.0], "spell": [0.3, 0.55, 1.0], "hurt": [1.0, 0.7, 1.0]}


## Says a call of the turn, as often as the "How much they talk" setting asks for.
## The duelists in the corners go live (0.63.0): each still picture is swapped for the real duelist from
## the board as soon as their model is in. (Not in a Turbo Duel: there they are on their runners.)
func _go_live() -> void:
	if not Settings.live_portraits or board.track != null or _autoplay:
		return
	for p in 2:
		_live_when_ready(p)


func _live_when_ready(p: int) -> void:
	for i in 240:
		if not is_inside_tree():
			return
		if board.duelist_ready(p):
			break
		await get_tree().process_frame
	if not board.duelist_ready(p):
		return
	var tex := board.live_portrait(p, hud.live_size(p))
	await get_tree().process_frame
	await get_tree().process_frame
	if tex != null and is_inside_tree():
		hud.go_live(p, tex)


## The director (0.63.0): a short look at a duelist at a set moment, so what they do with their body
## is seen. The caller awaits it: the table waits for the look to end. Never more than one every few
## seconds, never in a Turbo Duel, never when the setting says no. big = the moments "Fewer" keeps.
var _last_cut := -99.0

func _cut(p: int, moment: String, secs: float, big := false) -> bool:
	if _autoplay or _finished or board.track != null or not board.has_duelist(p):
		return false
	if Settings.cam_cuts == 2 or (Settings.cam_cuts == 1 and not big):
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now < _last_cut + (4.0 if Settings.cam_cuts == 0 else 8.0):
		return false
	_last_cut = now + secs
	board.duelist_shot(p, 0.28, false, 0.0, 2.9)
	board.duelist_act(p, moment)
	_acted[p] = [moment, now + secs + 3.0]
	if _cut_log:
		print("CUT p%d %s %.2f t=%d" % [p, moment, secs, Time.get_ticks_msec()])
	await get_tree().create_timer(Settings.t(secs)).timeout
	board.cam_release(0.35)
	return true

var _cut_log := "--pose-debug" in OS.get_cmdline_user_args()
var _acted := {}        # player -> [moment, until]: the motion a look at the duelist has just played
var _beat_drew := -1    # the turn whose beat already played the draw motion (counted by turn, not by the clock: a slow computer must not see it twice)
var _turn_seen := false # the first turn has begun (before it, the opening hands are being dealt)
var _dealt := {}        # player -> true once their opening hand has had its one pull of the arm


## A duelist's motion for a moment of the duel, unless a look at them has just played that same one.
func _act(p: int, moment: String, strength := 1.0) -> void:
	var a: Array = _acted.get(p, ["", 0.0])
	if str(a[0]) == moment and Time.get_ticks_msec() / 1000.0 < float(a[1]):
		_acted.erase(p)
		return
	board.duelist_act(p, moment, strength)


## The turn beat: how long the camera stays on the duelist as their turn opens (0 = it does not go).
func _beat_secs(p: int) -> float:
	if _autoplay or _finished or board.track != null or not board.has_duelist(p) or Settings.turn_beat == 2:
		return 0.0
	if state.turn <= 1:
		return 0.0      # (the face-off has only just shown them both)
	return 1.25 if (Settings.turn_beat == 0 and state.turn <= 3) else 0.8


## `about`: the card the line is about (the one attacking), when it is not one to call by name.
func _call(p: int, kind: String, card_id := 0, about := 0) -> void:
	var odds: Array = CALLS.get(kind, [1.0, 1.0, 1.0])
	_talk(p, kind, float(odds[Settings.talk]), 2.5 if Settings.talk == 0 else (1.6 if Settings.talk == 1 else 0.9), card_id, about)


## `card_id`: a card to call out by name when this duelist has that call; `about`: the card the line
## is about either way. A line that names a card is only ever said about that card (Characters.LINE_NEEDS).
func _talk(p: int, kind: String, chance := 1.0, min_gap := 2.5, card_id := 0, about := 0) -> void:
	if _autoplay or randf() > chance:
		return
	if (_decided or _finished) and not kind in LAST_WORDS:
		return
	if about <= 0:
		about = card_id
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_talk[p]) < min_gap:
		return
	var who := _speaker(p) if p == ME else _opp_key
	if kind == "attack" and card_id > 0:
		# Your duelist sends a famous monster in by name.
		var cry: Array = Voices.call_line(who, card_id, true)
		if not cry.is_empty() and Voices.say(who, str(cry[1]), p == ME, false):
			_last_talk[p] = now
			hud.say(p, str(cry[0]))
			board.duelist_gesture(p, "attack")
			return
		card_id = 0
	if card_id > 0 and (kind == "ace" or randf() < 0.5):
		var call: Array = Voices.call_line(who, card_id)
		if not call.is_empty() and Voices.say(who, str(call[1]), p == ME, true):
			_last_talk[p] = now
			hud.say(p, str(call[0]))
			board.duelist_gesture(p, "ace")
			return
	var line := _opp_intro() if (p == AI and kind == "intro") else Characters.line(who, kind, about)
	if line == "":
		return
	_last_talk[p] = now
	hud.say(p, line)
	# (What they say about a hit comes after the sound they made taking it, not instead of it.)
	Voices.say_kind(who, kind, Characters.last_en, p == ME, kind in ["hurt", "hurt_big"] and now - float(_ouch_at[p]) < 1.5)
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
			_turn_seen = true
			_my_summons_now = 0
			if mine:
				_my_turns += 1
			Sfx.play("turn")
			if mine and state.players[ME].hand.is_empty() and state.turn > 2:
				_lumen("topdeck")
			if Settings.talk == 0:
				if randf() < 0.45:
					_talk(p, "turn", 1.0, 0.0)
			elif state.turn <= 1 or randf() < 0.35:
				_talk(p, "turn", 1.0, 0.0)      # (nobody draws on the very first turn)
			else:
				_talk(p, "draw", 1.0, 0.0)
			if mine and state.turn == 16:
				_lumen("long")
			# The turn beat: a moment on the duelist whose turn it is, calling it and drawing.
			var beat := _beat_secs(p)
			if beat > 0.0:
				_last_cut = Time.get_ticks_msec() / 1000.0 + beat
				board.duelist_shot(p, 0.3, false, 0.0, 2.9)
				board.duelist_act(p, "draw" if state.turn > 1 else "ready")
				if state.turn > 1:
					_beat_drew = state.turn      # (the turn's own draw is this same pull of the arm)
				if _cut_log:
					print("CUT p%d beat %.2f t=%d" % [p, beat, Time.get_ticks_msec()])
				get_tree().create_timer(Settings.t(beat)).timeout.connect(func(): board.cam_release(0.35))
			await hud.banner("YOUR TURN" if mine else Loc.t("%s'S TURN") % state.players[AI].name.to_upper(),
					Comic.SKY if mine else Color("ff7a8a"), beat > 0.0, 0.27 if beat > 0.0 else -1.0)
			if beat > 1.15:
				await get_tree().create_timer(Settings.t(beat - 1.15)).timeout
		"phase":
			var ph: int = ev["phase"]
			hud.set_phase(ph, state.current == ME, state.turn)
			board.set_battle_mode(ph == DuelState.Phase.BATTLE)
			if ph == DuelState.Phase.MAIN1 and p == AI and not _autoplay:
				board.duelist_act(AI, "think")      # (they look their hand over before the first move)
			var names := {DuelState.Phase.BATTLE: "BATTLE PHASE", DuelState.Phase.MAIN2: "MAIN PHASE 2", DuelState.Phase.END: "END PHASE"}
			if names.has(ph):
				var col: Color = UITheme.DANGER if ph == DuelState.Phase.BATTLE else (Comic.BLUE if state.current == ME else Comic.RED)
				await hud.phase_sweep(names[ph], col)
				if ph == DuelState.Phase.BATTLE:
					_call(p, "battle")
				elif ph == DuelState.Phase.END and p == AI and randf() < 0.3:
					_talk(AI, "taunt")
				elif ph == DuelState.Phase.END:
					# (p, not state.current: the rules are already a step ahead of what is on screen)
					_call(p, "end")
					_act(p, "end")
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
			if _turn_seen:
				if _beat_drew == state.turn:
					_beat_drew = -1
				else:
					_act(p, "draw")
			elif not _dealt.has(p):
				_dealt[p] = true      # (the opening hand: one pull of the arm for the five cards)
				board.duelist_act(p, "draw")
			await board.anim_draw(p, ev["card"], ev["deck"])
			if p == ME and state.turn > 4 and int(ev["deck"]) <= 3:
				_lumen("thin_deck")
			if p == ME:
				hud.add_hand_card(ev["card"])
		"summon", "set":
			if p == ME:
				_leave_hand(ev["card"])
				if ev["type"] == "summon":
					_my_summons_now += 1
					_my_summons_most = maxi(_my_summons_most, _my_summons_now)
			Sfx.play("card")
			var is_ace: bool = ev["type"] == "summon" and (ev["card"].level() >= 7 or ev["card"].id == Characters.get_char(_opp_key).get("ace", 0))
			if ev["type"] == "summon" and p == ME and int(ev["card"].id) in Voices.PLAYER_CALLS:
				is_ace = true
			if ev["type"] == "summon":
				get_tree().create_timer(Settings.t(0.5)).timeout.connect(func(): Sfx.play("summon", -4.0))
			# A big monster arrives: its own show, in its own colors (see SummonShow).
			if is_ace:
				await _cut(p, "ace", 1.1, true)      # (the duelist first, then the monster)
			if ev["type"] == "summon" and _shows and Settings.big_shows and SummonShow.wants(ev["card"].data):
				var sd: Dictionary = (ev["card"].data as Dictionary).duplicate()
				sd["id"] = ev["card"].id
				_shown = ev["card"]
				SummonShow.play(self, sd, p == ME)
				await get_tree().create_timer(Settings.t(1.5)).timeout
			if is_ace:
				_talk(p, "ace", 1.0, 0.0, int(ev["card"].id))
				hud.react(p, "ace")
				_lumen("my_ace" if p == ME else "their_ace")
			elif p == ME and ev["type"] == "summon" and ev["card"].id == CardData.LUMEN:
				_lumen("me")
			elif ev["type"] == "summon":
				_call(p, "summon")
			elif ev["type"] == "set":
				_call(p, "set_mon")
			if ev["type"] == "summon" and _pending_tributes > 0:
				hud.banner("TRIBUTE SUMMON", UITheme.GOLD, true)
			_pending_tributes = 0
			if ev["type"] == "summon":
				_act(p, "ace" if is_ace else "summon", 1.4 if is_ace else 1.0)
			else:
				_act(p, "set")
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
			_call(p, "spell")
			_act(p, "spell")
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
				_card_look(p, ev["card"], str(ev.get("label", "")))
				await get_tree().create_timer(Settings.t(0.3)).timeout
			else:
				var act_card = ev["card"]
				var act_label := str(ev.get("label", ""))
				get_tree().create_timer(Settings.t(0.45)).timeout.connect(func(): _card_look(p, act_card, act_label))
				await board.anim_activate(p, ev["card"], int(ev.get("zone", 2)))
		"st_settle":
			await board.anim_settle(p, ev["card"], int(ev["zone"]))
		"st_reset":
			await board.anim_reset(p, ev["card"], int(ev["zone"]))
		"chain_link":
			# (0.57.0) A numbered link over every card on the chain, joined by a chain of light.
			var cn := int(ev["n"])
			board.chain_link(cn, p, ev.get("card"))
			# (0.63.2) ...and the chain itself in a strip beside the card panel, where it can be read.
			var enter := 0.0
			if not _autoplay:
				enter = hud.chain_strip().link(cn, p, ev.get("card"), Settings.t(0.75) * _chain_pace())
			if cn >= 2:
				hud.effect_text(Loc.t("CHAIN %d") % cn, Color("ffd23a"))
				if cn == 2 or randf() < 0.5:
					_talk(p, "chain", 0.7)
				await get_tree().create_timer(maxf(enter, Settings.t(0.42))).timeout
		"chain_solving":
			if board.chain_fx != null:
				board.chain_fx.solving(int(ev["n"]))
			var strip_on: bool = not _autoplay and hud.chain_strip().showing()
			if strip_on:
				# One card at a time: it steps out, you read what it is, then its effect plays.
				var fwd: float = hud.chain_strip().solving(int(ev["n"]), Settings.t(0.8) * _chain_pace())
				await get_tree().create_timer(fwd).timeout
			elif board.chain_fx != null:
				await get_tree().create_timer(Settings.t(0.3)).timeout
		"chain_negated":
			if board.chain_fx == null:
				board.chain_link(0, p, null)
			board.chain_fx.negated(int(ev["n"]), ev.get("card"))
			if not _autoplay:
				hud.chain_strip().negated(int(ev["n"]))
			board.anim_negated(ev.get("card"))
			hud.effect_text(Loc.t("Negated!"), Color("ff5a6a"))
			var nc = ev.get("card")
			if nc != null:
				# (the one who stopped it has the word; sometimes the one who was stopped)
				if randf() < 0.7:
					_talk(1 - int(nc.owner), "negate", 1.0)
				else:
					_talk(int(nc.owner), "negated", 1.0)
			await get_tree().create_timer(Settings.t(0.5)).timeout
		"chain_solved":
			if board.chain_fx != null:
				board.chain_fx.solved(int(ev["n"]))
			if not _autoplay and hud.chain_strip().showing():
				# (a beat on what it did before the card steps back and the next one comes forward)
				await get_tree().create_timer(Settings.t(0.35) * _chain_pace()).timeout
				hud.chain_strip().solved(int(ev["n"]))
				await get_tree().create_timer(Settings.t(0.25) * _chain_pace()).timeout
			elif board.chain_fx != null:
				await get_tree().create_timer(Settings.t(0.12)).timeout
		"chain_end":
			if board.chain_fx != null:
				board.chain_fx.end()
			if not _autoplay:
				hud.chain_strip().clear()
			_fx_card = null
			_fx_kind = ""
		"targets":
			# The effect that was just activated picked these: a line of its kind runs to each.
			if _fx_kind != "" and not _autoplay:
				var aimed := 0
				for tcard in ev.get("cards", []):
					var t3 := board.card_for(tcard)
					if t3 != null and is_instance_valid(t3) and tcard != _fx_card and t3.position.y < 0.7 and aimed < 3:
						CardFx.aim(board, _fx_at, t3.position, _fx_kind)
						aimed += 1
				if aimed > 0:
					await get_tree().create_timer(Settings.t(0.3)).timeout
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
			await board.anim_travel("gy_to_deck", p, ev["card"])
			board.set_deck_count(p, ev["deck"])
		"spell_done":
			await board.anim_spell_done(ev["card"])
		"attack":
			var atk_card = ev["card"]
			var direct: bool = ev["target"] == null
			if direct and p == ME:
				_my_directs += 1
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
				if Settings.talk > 0:
					_call(p, "direct" if direct else "attack", 0 if direct or p != ME else int(atk_card.id), int(atk_card.id))
			elif direct:
				_call(p, "direct", 0, int(atk_card.id))
			else:
				_call(p, "attack", int(atk_card.id) if p == ME and int(atk_card.id) in Voices.PLAYER_CALLS else 0, int(atk_card.id))
			if direct:
				await _cut(p, "direct", 0.7, true)      # (the one who sends it in; the strike then goes into the other duelist)
			_act(p, "direct" if direct else "attack", 1.3 if direct or int(atk_card.atk()) >= 2400 else 1.0)
			Sfx.play("attack")
			if board.track:
				board.track.surge(p)
				if hud.speed_fx:
					hud.speed_fx.kick(0.5)
			await board.anim_declare(p, ev["card"], ev["target"])
		"battle":
			if ev.get("finisher", false) and not _autoplay and not board.turbo:
				ScreenFx.letterbox(hud, 2.6)
				board.duelist_gesture(p, "attack")
				await board.anim_finisher(p, ev["card"], ev["target"])
				return
			var hit_in: float = board.battle_hit_time(ev["card"])      # (a strong monster winds up longer)
			var hit_at: Vector3 = board._attack_goal(p, ev["target"])
			var heavy: bool = ev["target"] == null or int(ev["card"].atk()) >= 2400
			get_tree().create_timer(Settings.t(hit_in + 0.05)).timeout.connect(func():
				hud.impact(hit_at + Vector3(0, 0.3, 0), Comic.SKY if p == ME else Color("ff5a7a"), 1.0 if heavy else 0.55))
			if ev["target"] != null and ev.has("atk") and not _autoplay:
				var defending: bool = bool(ev.get("t_defending", false))
				ClashFx.play(hud, int(ev["atk"]), int(ev["t_def"] if defending else ev["t_atk"]), p == ME, defending, hit_in)
			if ev["target"] != null:
				_spill_at = hit_at      # (damage from this clash flies on from here: see "lp")
				_spill_until = Time.get_ticks_msec() + 4000
			else:
				_spill_at = Vector3.INF
			await board.anim_battle(p, ev["card"], ev["target"])
		"attack_stopped":
			await board.anim_attack_stopped(ev["card"])
		"set_st":
			if p == ME:
				_leave_hand(ev["card"])
			_call(p, "set")
			_act(p, "set")
			Sfx.play("card")
			await board.anim_set_st(p, ev["card"], ev["zone"])
		"trap":
			Sfx.play("spell", 0.0, 0.8)
			hud.inspect(ev["card"])
			if not _autoplay:
				await _cut(p, "trap", 0.75)      # (a quick look at the one who sprang it)
				_act(p, "trap")
			# The card turns face-up on the field first (and, with the setting on, is held up to be read).
			if not _autoplay:
				_announce(p, ev["card"], true)
			await board.anim_trap(p, ev["card"], ev["zone"])
			if not _autoplay and p == AI and Settings.card_showcase:
				await hud.showcase(ev["card"], Loc.t("TRAP CARD"), Color("ff4dd2"), state.players[AI].name)
			elif not _autoplay and Settings.card_showcase:
				hud.banner(str(ev["card"].data["name"]).to_upper(), Color("ff4dd2"), true)
				await get_tree().create_timer(Settings.t(0.45)).timeout
			_card_look(p, ev["card"], str(ev.get("label", "")))
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
		"why":
			if not _autoplay:
				if ev.get("quiet", false):
					hud.effect_text(str(ev["text"]), Color("5fd0ff"))
				else:
					hud.why_ui.show_why(p, str(ev["title"]), str(ev["text"]), int(ev.get("id", 0)))
					Sfx.play("error", -12.0, 1.4)
					await get_tree().create_timer(Settings.t(0.9)).timeout
		"status":
			if not _autoplay:
				hud.why_ui.set_status(p, ev["list"])
		"log":
			hud.log_line(p, str(ev["icon"]), str(ev["text"]))
		"effect":
			var on_field: bool = ev["card"] != null and board.card_for(ev["card"]) != null and (state.players[0].field.has(ev["card"]) or state.players[1].field.has(ev["card"]))
			# (0.61.0) What kind of effect it is shows in its colour and its emblem.
			var fx_src = ev["card"] if ev["card"] != null else ev.get("src")
			var fx_kind := CardFx.kind(fx_src, str(ev.get("label", "")))
			_fx_card = fx_src
			_fx_kind = fx_kind
			_fx_p = p
			if on_field:
				board.effect_burst(ev["card"], CardFx.color(fx_kind))
				_fx_at = board.card_for(ev["card"]).position
				CardFx.emblem(board, _fx_at + Vector3(0, 2.0, 0), fx_kind)
			elif fx_src != null and not _autoplay:
				if ev["card"] != null:
					board.pulse(ev["card"], CardFx.color(fx_kind))
				_fx_at = board.chain_spot(fx_src, p)
				CardFx.play(board, _fx_at, fx_kind, 1.25)
			hud.effect_text(ev["text"])
			Sfx.play("effect", -3.0)
			Sfx.play("sparkle", -10.0, 1.2)
			await get_tree().create_timer(Settings.t(0.75 if on_field else 0.5)).timeout
		"search":
			await board.anim_travel("search", p, ev["card"])
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
				_my_summons_now += 1
				_my_summons_most = maxi(_my_summons_most, _my_summons_now)
			if method == "puzzle":
				Sfx.play("card", -6.0)
				await board.anim_special(p, ev["card"], ev["zone"], method, [])
				return
			var titles := {"fusion": "FUSION SUMMON", "synchro": "SYNCHRO SUMMON", "xyz": "XYZ SUMMON", "reborn": "REVIVED", "ritual": "RITUAL SUMMON"}
			Sfx.play("special")
			# (a monster brought back or sent out by an effect is only "the ace" when it is a big one)
			var sp_big: bool = ev["card"].level() >= 7 or int(ev["card"].id) == int(Characters.get_char(_speaker(p)).get("ace", 0)) or (p == ME and int(ev["card"].id) in Voices.PLAYER_CALLS)
			if method in ["fusion", "synchro", "xyz", "ritual"] or sp_big:
				_talk(p, method if method in ["fusion", "synchro", "xyz", "ritual"] else "ace", 1.0, 0.0, int(ev["card"].id))
			else:
				_call(p, "summon", 0, int(ev["card"].id))
			if method in ["fusion", "synchro", "xyz", "ritual"]:
				await _cut(p, "summon_big", 0.9, true)
			_act(p, "summon_big", 1.5)
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
			await board.anim_special(p, ev["card"], ev["zone"], method, mats, int(ev.get("origin", 0)))
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
			await board.anim_travel("gy_to_hand", p, ev["card"])
			if p == ME:
				hud.add_hand_card(ev["card"])
			else:
				await board.anim_add_to_opp_hand(ev["card"])
		"mill":
			board.set_deck_count(p, ev["deck"])
			await board.anim_travel("mill", p, ev["card"])
		"redraw":
			if p == ME:
				for e in hud._hand.duplicate():
					hud.remove_hand_card(e["inst"])
			board.set_deck_count(p, ev["deck"])
		"lp":
			# (0.61.0) Damage and healing from a card effect go from the card to the duelist.
			if _fx_kind == "burn" and int(ev["delta"]) < 0 and not _autoplay:
				CardFx.to_duelist(board, _fx_at, p, "burn")
				await get_tree().create_timer(Settings.t(0.2)).timeout
			elif int(ev["delta"]) < 0 and not _autoplay and _spill_at != Vector3.INF and Time.get_ticks_msec() < _spill_until:
				# (0.63.0) Battle damage carries on past the monster that lost and reaches the duelist;
				# the Life Points drop when it lands.
				CardFx.to_duelist(board, _spill_at, p, "burn")
				_spill_at = Vector3.INF
				await get_tree().create_timer(Settings.t(0.2)).timeout
			elif int(ev["delta"]) > 0 and not _autoplay:
				CardFx.bless(board, p)
			hud.set_lp(p, ev["lp"], ev["delta"])
			if p == ME:
				_my_low = mini(_my_low, int(ev["lp"]))
			if ev["delta"] < 0 and int(ev["lp"]) <= 0 and not _autoplay and not ev.get("finished", false) and not board.turbo:
				# (a last hit that was not an attack: the picture breaks all the same)
				var lsp: Vector2 = hud.get_viewport_rect().size * Vector2(0.5, 0.32 if p == AI else 0.68)
				ScreenFx.flash(hud, Color.WHITE, 0.35, 0.8)
				ScreenFx.shatter(hud, lsp, 1.2)
			if int(ev["lp"]) <= 0:
				# The hit that ends the duel (0.63.1). From here nobody comments as if the duel went on
				# ("they are almost out!" after they were out), and a line that was waiting its turn is
				# dropped. The only words left are the ending's own.
				_decided = true
				Voices.hush()
			if ev["delta"] < 0 and int(ev["lp"]) <= 0 and not _autoplay:
				# The last hit of the duel: the one who took it cries out, then the winner gets the screen.
				_ouch(p, "last")
				hud.cut_in(1 - p, Loc.t("FINISHING BLOW!"), Characters.line(_speaker(ME) if p == AI else _opp_key, "win"), UITheme.GOLD, 0.8, true)
				Voices.say_kind(_speaker(ME) if p == AI else _opp_key, "win", Characters.last_en, p == AI)
			elif ev["delta"] < 0 and not _autoplay:
				# A hit that lands is heard (0.63.1): a grunt for a small one, a cry for a big one.
				if int(ev["delta"]) <= -2000:
					_ouch(p, "big")
				elif int(ev["delta"]) <= -300 and Settings.talk > 0:
					_ouch(p, "small")
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
				board.duelist_act(p, "hurt_big" if int(ev["delta"]) <= -2000 else "hurt", float(-ev["delta"]) / 1500.0)
				if not _autoplay:
					board.duelist_hit(p, int(ev["delta"]) <= -2000)
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
				if _decided:
					pass
				elif p == AI and ev["lp"] <= 2000 and not _said_low:
					_said_low = true
					_talk(AI, "low", 1.0, 0.0)
					_lumen("comeback" if _me_was_low else "their_low")
				if _decided:
					pass
				elif p == ME and int(ev["lp"]) <= 2000:
					_me_was_low = true
					_lumen("my_low")
				elif p == ME and ev["delta"] <= -2000:
					if Settings.talk > 0:
						_call(ME, "hurt_big")
					_lumen("hit")
				elif ev["delta"] <= -2000 and Settings.talk > 0:
					_call(p, "hurt_big")
					_talk(1 - p, "big_hit", 0.55)
				elif ev["delta"] <= -1000:
					_call(p, "hurt")
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
	# Every line goes in the card log; what the other side does also shows as a line on screen.
	var line: Array = []
	match str(ev["type"]):
		"destiny":
			line = ["★", Loc.t("Destiny Draw: chose the card they drew") if theirs else Loc.t("Destiny Draw: you chose your card")]
		"summon":
			line = ["▲", Loc.t("Summoned %s  (%d ATK)") % [cn, int(c.atk())]]
		"set":
			line = ["▣", Loc.t("Set a monster face-down")]
		"set_st":
			line = ["▣", Loc.t("Set a card face-down")]
		"activate":
			line = ["✦", Loc.t("Activated %s") % cn]
		"trap":
			line = ["!", Loc.t("Trap: %s") % cn]
		"special":
			line = ["★", Loc.t("Special Summoned %s") % cn]
		"flip":
			line = ["↻", Loc.t("Flipped %s face-up") % cn]
		"attack":
			var tg = ev.get("target")
			if tg == null:
				line = ["⚔", Loc.t("%s attacks you directly") % cn if theirs else Loc.t("%s attacks directly") % cn]
			elif theirs:
				line = ["⚔", Loc.t("%s attacks %s") % [cn, str(tg.cname()) if tg.face_up else Loc.t("your face-down monster")]]
			else:
				line = ["⚔", Loc.t("%s attacks %s") % [cn, str(tg.cname()) if tg.face_up else Loc.t("a face-down monster")]]
		"destroy":
			if c != null and cn != "":
				if c.owner == ME:
					hud.feed(AI, "✕", Loc.t("Your %s was destroyed") % cn)
				else:
					hud.log_line(ME, "✕", Loc.t("%s was destroyed") % cn)
		"effect":
			if cn != "":
				line = ["✦", Loc.t("Effect: %s") % cn]
	if not line.is_empty():
		if theirs:
			hud.feed(p, str(line[0]), str(line[1]))
		else:
			hud.log_line(p, str(line[0]), str(line[1]))


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
	if _outro_on and not _outro_skip and event.is_pressed() and not event.is_echo() \
			and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		_outro_skip = true      # (any key or button: straight to the results)
		get_viewport().set_input_as_handled()
		return
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
	if not _replay.is_empty():
		_replay_tick()
	_btn_watch -= delta
	if _btn_watch > 0.0:
		return
	_btn_watch = 0.3
	if _my_turn() and mode == "" and not _finished and hud.end_button_off() \
			and state.phase in [DuelState.Phase.MAIN1, DuelState.Phase.BATTLE, DuelState.Phase.MAIN2]:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_L and not _finished:
		hud.show_log()
		get_viewport().set_input_as_handled()
		return
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
		"admin_win", "admin_lose":
			hud.hide_overlay()
			state.winner = ME if action == "admin_win" else AI
			state.win_reason = "Ended from the admin menu."
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
			if not _replay.is_empty():
				Router.menu_open = "replays"
			Router.go(Router.MAIN_MENU)
		"watch_replay":
			# The duel that just ended, from its file.
			var wd := Replays.read(Replays.last_saved)
			if wd.is_empty():
				Router.toast(Loc.t("That replay could not be opened."))
			else:
				_restore_match_deck()
				Router.duel_config = Replays.config_for(wd)
				Router.go(Router.DUEL)
		"replay_again":
			Router.go(Router.DUEL)
		"replay_back":
			Router.menu_open = "replays"
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
	if not _replay.is_empty():
		Engine.time_scale = 1.0
		Voices.muted = false
	Voices.hush(true)
	Settings.pace = 1.0
	Sfx.boost_db = 0.0
	Music.set_boost(0.0)
	if Engine.time_scale < 1.0:
		Engine.time_scale = 1.0
	if board and board.turbo:
		Sfx.ambience_pitch(1.0)
		Sfx.ambience("")


var _fx_card = null        # the card whose effect was just activated (CardFx)
var _fx_kind := ""
var _spill_at := Vector3.INF      # where the last clash between two monsters landed
var _spill_until := 0
var _fx_p := 0
var _fx_at := Vector3.ZERO


## A Spell or Trap was just activated: its own signature look if it has one, and the emblem
## and flourish of what kind of card it is.
func _card_look(p: int, card, label: String) -> void:
	if card == null or board == null:
		return
	var sig := StrikeFx.card(board, str(card.data.get("name", "")), p)
	var k := CardFx.kind(card, label)
	_fx_card = card
	_fx_kind = k
	_fx_p = p
	_fx_at = board.chain_spot(card, p)
	if not _autoplay:
		CardFx.play(board, _fx_at, k, 1.25, sig)
