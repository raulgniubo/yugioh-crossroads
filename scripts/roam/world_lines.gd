class_name WorldLines
## Every line somebody can say out in a world, with the voice that says it: the walkers' barks and
## greetings, Lumen's remarks at your shoulder, what the people of a district and its rooms say when
## you talk to them, and the stars who spend their days there. Lines built on the spot (with % in
## them) are listed with the blank filled in every way it can be (who beat whom today, where and when
## to meet), so they have a file too; a line with a card's name in it is spoken with "that card".
## The voice tools make the files from this list, and the tests check that every one is there.

const ROAM := preload("res://scripts/roam/roam_scene.gd")
const WALKERS := ["kind_m", "kind_f", "cocky_m", "cocky_f", "cool_m", "cool_f", "wild_m"]


## [{"voice", "en", "from"}] for these districts (walkers and Lumen are in every one of them).
static func collect(districts: Array) -> Array:
	var out: Array = []
	var seen := {}
	for v in WALKERS:
		for l in RoamExtras.BARKS:
			_add(out, seen, v, l, "bark")
		var pers: String = str(v).get_slice("_", 0)
		for l in RoamExtras.GREET.get(pers, []):
			_add(out, seen, v, l, "greet")
		for topic in RoamExtras.GREET_WHEN:
			if (RoamExtras.GREET_WHEN[topic] as Dictionary).has(pers):
				_add(out, seen, v, RoamExtras.GREET_WHEN[topic][pers], "greet " + str(topic))
	for lv in Voices.LUMEN_VOICES:
		for k in Partner.HELLO:
			for l in Partner.HELLO[k]:
				_add(out, seen, lv, l, "lumen hello " + str(k))
		for pool in [Partner.IDLE, Partner.NIGHT, Partner.RAIN, Partner.WON, Partner.LOST, Partner.STRONG, Partner.EASY, Partner.BEATEN, Partner.SHINY, Partner.FEEL]:
			for l in pool:
				_add(out, seen, lv, l, "lumen")
	for dk in districts:
		var d: Dictionary = RoamData.district(str(dk))
		var people: Array = (d.get("npcs", []) as Array).duplicate()
		for rk in Interiors.rooms_in(str(dk)):
			people.append_array(Interiors.people(rk))
		for n in people:
			var nd: Dictionary = n
			var v := Voices.world_voice(str(nd.get("id", "")), str(nd.get("model", "")), str(nd.get("char", "")), str(nd.get("pers", "")))
			if v == "":
				continue
			for f in ["lines", "chats", "after", "barks"]:
				_walk(out, seen, v, nd.get(f), "%s %s" % [nd.get("id", "?"), f])
			if nd.has("duel"):
				_add(out, seen, v, "So? Are we dueling or what?", "ask")
				_add(out, seen, v, "Rematch? I won't go easy on you this time.", "ask again")
		for id in (StarLife.DAYS.get(str(dk), {}) as Dictionary):
			var sv := Voices.voice_for(str(id))
			_walk(out, seen, sv, StarLife.TALK.get(id), "star %s" % id)
			_walk(out, seen, sv, StarMeets.MORE.get(id), "star more %s" % id)
			_walk(out, seen, sv, StarLife.ASK.get(id), "star ask %s" % id)
			_blanks(out, seen, sv, str(dk), d, str(id))
		# The people a world adds on top of its list: the shop's own, the rivals and the ghost of
		# the Academy, and what anybody says about a favor they ask of you.
		var by_id := {}
		for n in people:
			by_id[str((n as Dictionary).get("id", ""))] = n
		var more: Array = (d.get("shop_npcs", []) as Array).duplicate()
		if str(dk) == "academy":
			more.append_array(WorldLife.RIVALS)
			more.append(WorldLife.GHOST)
		for n in more:
			var nd: Dictionary = n
			by_id[str(nd.get("id", ""))] = nd
			var v := Voices.world_voice(str(nd.get("id", "")), str(nd.get("model", "")), str(nd.get("char", "")), str(nd.get("pers", "")))
			for f in ["lines", "chats", "after", "barks"]:
				_walk(out, seen, v, nd.get(f), "%s %s" % [nd.get("id", "?"), f])
			if nd.has("duel"):
				_add(out, seen, v, "Rematch? I won't go easy on you this time.", "ask again")
		for e in WorldLife.ERRANDS.get(str(dk), []):
			var giver: Dictionary = by_id.get(str(e["giver"]), {})
			if giver.is_empty():
				continue
			var gv := Voices.world_voice(str(giver.get("id", "")), str(giver.get("model", "")), str(giver.get("char", "")), str(giver.get("pers", "")))
			for f in ["ask", "wait", "done"]:
				_walk(out, seen, gv, e.get(f), "favor %s %s" % [e["id"], f])
	# Anybody walking by will stop and talk (and duel): whoever they are, the lines are these.
	for v in WALKERS:
		for l in ROAM.WALK_LINES:
			_add(out, seen, v, l, "walker talk")
		_add(out, seen, v, "A duel? Right here? ...Sure, why not.", "walker talk")
		_add(out, seen, v, "Rematch? I won't go easy on you this time.", "walker ask again")
	return out


## The lines of a star that have a blank in them, once for every way the blank is filled.
## "bout_won" / "bout_lost": who they dueled today. "invite": the place and the hour of a later
## stop of theirs. "ace": the card you lead with, which can be any card: one file, the line itself
## (the tools say it with "that card" where the name goes).
static func _blanks(out: Array, seen: Dictionary, voice: String, dk: String, d: Dictionary, id: String) -> void:
	var more: Dictionary = StarMeets.MORE.get(id, {})
	var talk: Dictionary = StarLife.TALK.get(id, {})
	for m in StarMeets.MEETS.get(dk, []):
		for pair in m["pairs"]:
			if not id in pair:
				continue
			var other := str(pair[1] if str(pair[0]) == id else pair[0]).capitalize()
			for kind in ["bout_won", "bout_lost"]:
				for t in _each(more.get(kind, talk.get(kind))):
					if "%s" in t:
						_add_filled(out, seen, voice, t, [other], "star %s %s" % [id, kind])
	for t in _each(more.get("invite", talk.get("invite"))):
		if t.count("%s") != 2:
			continue
		for day in 4:
			var stops: Array = StarMeets.day_with(dk, id, StarLife.DAYS[dk][id], day)
			for st in stops:
				if float(st[0]) > 1320.0 or str(st[3]) in ["duel", "nap"]:
					continue
				var place := StarMeets.place_near(d, st[1])
				if place == "":
					continue
				var hour := StarMeets.hour_text(float(st[0]))
				var line := StarMeets.invite_text(t, place, hour)
				if not seen.has(voice + "|" + line):
					seen[voice + "|" + line] = true
					out.append({"voice": voice, "en": line, "from": "star %s invite" % id, "tpl": t, "place": place, "hour": hour})
	for t in _each(talk.get("ace", more.get("ace"))):
		if "%s" in t and not seen.has(voice + "|" + t):
			seen[voice + "|" + t] = true
			out.append({"voice": voice, "en": t, "from": "star %s ace" % id, "tpl": t, "say": ["that card"]})


static func _each(what) -> Array:
	if what is String:
		return [what]
	return what if what is Array else []


static func _add_filled(out: Array, seen: Dictionary, voice: String, tpl: String, args: Array, from: String) -> void:
	var line := tpl % args
	if voice == "" or seen.has(voice + "|" + line):
		return
	seen[voice + "|" + line] = true
	out.append({"voice": voice, "en": line, "from": from, "tpl": tpl, "args": args})


static func _walk(out: Array, seen: Dictionary, voice: String, what, from: String) -> void:
	if what is String:
		_add(out, seen, voice, what, from)
	elif what is Array:
		for x in what:
			_walk(out, seen, voice, x, from)
	elif what is Dictionary:
		for k in what:
			_walk(out, seen, voice, what[k], from)


static func _add(out: Array, seen: Dictionary, voice: String, line: String, from: String) -> void:
	if voice == "" or line == "" or "%" in line or seen.has(voice + "|" + line):
		return
	seen[voice + "|" + line] = true
	out.append({"voice": voice, "en": line, "from": from})
