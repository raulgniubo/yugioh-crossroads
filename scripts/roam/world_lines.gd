class_name WorldLines
## Every line somebody can say out in a world, with the voice that says it: the walkers' barks and
## greetings, Lumen's remarks at your shoulder, what the people of a district and its rooms say when
## you talk to them, and the stars who spend their days there. Lines built on the spot (with % in
## them) are left out: they have no file. The voice tools make the files from this list, and the
## tests check that every one of them is there.

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
	return out


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
