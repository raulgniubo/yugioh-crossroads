class_name DuelAudio
## The sound of a duel: every event gets its sound, the crowd reacts to the big moments, and the
## music speeds up when someone is close to losing.

const SPECIAL := {"fusion": "fusion", "synchro": "synchro", "xyz": "xyz", "ritual": "ritual"}
static var tense := false
static var theme := "duel"      # what to go back to when nobody is in danger


static func reset() -> void:
	tense = false
	Sfx.ambience("crowd", -22.0)


static func on_event(ev: Dictionary, state: DuelState) -> void:
	match str(ev.get("type", "")):
		"turn":
			Sfx.play("gong", -6.0)
		"phase":
			Sfx.play("phase", -10.0, 0.8 + 0.08 * int(ev.get("phase", 0)))
		"set":
			Sfx.play("set", -2.0)
		"set_st":
			Sfx.play("set", -4.0, 1.25)
		"special":
			var m := str(ev.get("method", ""))
			Sfx.play(SPECIAL.get(m, "whoosh"), -2.0)
			if SPECIAL.has(m):
				Sfx.play("cheer", -14.0)
		"flip", "position":
			Sfx.play("flip", -4.0)
		"trap":
			Sfx.play("trap", -1.0)
		"chain":
			Sfx.play("chain", -2.0, 0.85 + 0.14 * int(ev.get("n", 1)))
		"st_settle":
			Sfx.play("equip", -4.0)
		"attack":
			Sfx.play("charge", -4.0)
		"battle":
			if ev.get("target") == null:
				Sfx.play("direct", -1.0)
		"attack_stopped":
			Sfx.play("negate", -4.0)
		"tribute", "material":
			Sfx.play("tribute", -5.0)
		"banish":
			Sfx.play("banish", -3.0)
		"bounce", "control", "gy_to_hand", "unbanish":
			Sfx.play("whoosh", -6.0)
		"search":
			Sfx.play("sparkle", -8.0)
		"discard", "mill":
			Sfx.play("card", -4.0, 0.8)
		"effect", "hand_effect":
			var text := str(ev.get("text", ""))
			if "negate" in text:
				Sfx.play("negate", -3.0)
			else:
				Sfx.play("effect", -6.0)
		"detach":
			Sfx.play("blip", -4.0, 0.7)
		"lp":
			var delta := int(ev.get("delta", 0))
			if delta < 0:
				Sfx.play("lp_drain", -5.0)
				if delta <= -2000:
					Sfx.play("gasp" if int(ev.get("player", 0)) == 0 else "cheer", -9.0)
			# The music turns urgent once either duelist is at 2000 or less.
			var low := false
			for ps in state.players:
				if ps.lp <= 2000:
					low = true
			if low != tense and not state.is_over():
				tense = low
				Music.play("duel_tense" if low else ("turbo" if state.turbo else theme))
		"win":
			pass
