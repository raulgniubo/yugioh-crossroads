extends Node
## Dev: a replay must be the same duel. Plays duels with nobody at the table (your side answers at
## random, the opponent thinks the way it does in a real duel), then plays each one back from its
## file and checks that it ends on the same winner, turn and event count.
##   godot --headless --path . res://tests/replay_check.tscn -- --human-test --duels=3 [--speed=10] [--assets=<folder>] [--level=2]
## (Back up the profile first: a duel that is played gives its rewards.)
func _ready() -> void:
	var n := 3
	var speed := 10.0
	var level := 2
	var give_up := 5      # every fifth duel is surrendered a little way in
	var turbo := false    # Turbo Duels instead
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--duels="):
			n = int(a.substr(8))
		elif a.begins_with("--speed="):
			speed = float(a.substr(8))
		elif a.begins_with("--assets="):
			Settings.card_folder = a.substr(9)
		elif a.begins_with("--level="):
			level = int(a.substr(8))
		elif a.begins_with("--give-up="):
			give_up = int(a.substr(10))
		elif a == "--turbo":
			turbo = true
	await get_tree().process_frame
	Engine.time_scale = speed
	var decks := ["deck_dragon", "deck_warrior", "yugi", "kaiba", "joey", "jaden", "deck_hero", "deck_x_saber"]
	var foes := ["kaiba", "yugi", "joey", "jaden", "mai", "zane", "chazz", "weevil"]
	var same := 0
	var played := 0
	var t0 := Time.get_ticks_msec()
	for i in n:
		Router.duel_config = {"player_deck": decks[i % decks.size()], "opponent_deck": decks[(i + 3) % decks.size()], "opponent": foes[i % foes.size()],
			"difficulty": 1 + (i % 3), "cpu_level": level, "lp": 4000 if i % 2 == 0 else 8000}
		if turbo:
			Router.duel_config["turbo"] = true
		Replays.last_saved = ""
		var d: Node = (load("res://scenes/duel.tscn") as PackedScene).instantiate()
		add_child(d)
		var waited := 0.0
		var quit_at := 4.0 if (i % give_up == give_up - 1) else -1.0      # (some duels end in a surrender)
		while is_instance_valid(d) and Replays.last_saved == "" and waited < 900.0:
			await get_tree().create_timer(0.5, true, false, true).timeout
			waited += 0.5
			if quit_at > 0.0 and waited >= quit_at and d.state != null and int(d.state.winner) < 0 and int(d.state.turn) >= 2:
				quit_at = -1.0
				print("REPLAY CHECK duel %d: surrendering on turn %d" % [i + 1, int(d.state.turn)])
				d._on_pause_action("surrender")
		var path := Replays.last_saved
		var first_winner := int(d.state.winner) if is_instance_valid(d) and d.state != null else -9
		var first_turn := int(d.state.turn) if is_instance_valid(d) and d.state != null else -9
		await get_tree().create_timer(0.3, true, false, true).timeout
		d.queue_free()
		for k in 20:
			await get_tree().process_frame
		if path == "":
			print("REPLAY CHECK duel %d: no replay was written (%.0f s)" % [i + 1, waited])
			continue
		played += 1
		var data := Replays.read(path)
		Router.duel_config = Replays.config_for(data)
		var d2: Node = (load("res://scenes/duel.tscn") as PackedScene).instantiate()
		add_child(d2)
		var done := [false]
		d2.replay_over.connect(func(): done[0] = true)
		waited = 0.0
		while is_instance_valid(d2) and not done[0] and waited < 900.0:
			await get_tree().create_timer(0.5, true, false, true).timeout
			waited += 0.5
		var ok: bool = done[0] and bool(d2.replay_same)
		if ok:
			same += 1
		print("REPLAY CHECK duel %d (%s vs %s, %d steps): played winner %d turn %d | replay %s" % [i + 1, Router.duel_config.get("player_deck", "?"), Router.duel_config.get("opponent", "?"),
			(data["tape"] as Array).size(), first_winner, first_turn, "SAME" if ok else "DIFFERENT"])
		d2.queue_free()
		for k in 20:
			await get_tree().process_frame
		Router.duel_config = {}
		# (what is left once the duel and its replay are closed: numbers that keep climbing are a leak)
		print("REPLAY CHECK after duel %d: %.0f MB, %d objects, %d nodes" % [i + 1, OS.get_static_memory_usage() / 1048576.0,
			int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	Engine.time_scale = 1.0
	print("REPLAY CHECK: %d of %d replays matched their duel (%.0f s)  %s" % [same, played, (Time.get_ticks_msec() - t0) / 1000.0, "PASS" if same == played and played > 0 else "FAIL"])
	get_tree().quit(0 if same == played and played > 0 else 1)
