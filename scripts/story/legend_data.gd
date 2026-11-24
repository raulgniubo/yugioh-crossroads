class_name LegendData
extends RefCounted
## Legendary Duels (0.75.0): famous matchups from the shows, played with the decks the duelists had
## at that time, with a short scene before and after written for this game (never the show's own
## scenes or lines). One matchup for now, from GX; more come once this one is right.
##
## A matchup: id, era, the two duelists (keys of Characters), their decks of the time
## (CardData.NAMED_DECKS keys), the place behind the scenes, and for each side the three stars:
## ["win"], ["ace", card name] (it is on your field when you win), ["turns", n] (win by turn n).
## Lines are [speaker key or "" for the narrator, text in English]; Spanish comes through Loc.

const ERAS := [["dm", "Duel Monsters"], ["gx", "GX"], ["5ds", "5D's"], ["zexal", "ZEXAL"]]

const LEGENDS := [
	{
		"id": "gx_jaden_chazz_y1",
		"era": "gx",
		"title": "Jaden vs Chazz",
		"when": "First year at Duel Academy",
		"field": "academy",
		"picture": "res://assets/ui/academy_title.jpg",
		"sides": [
			{"key": "jaden", "deck": "legend_jaden_y1", "stars": [["win"], ["ace", "Elemental HERO Flame Wingman"], ["turns", 8]]},
			{"key": "chazz", "deck": "legend_chazz_y1", "stars": [["win"], ["ace", "VWXYZ-Dragon Catapult Cannon"], ["turns", 8]]},
		],
		"before": [
			["", "Duel Academy, the first weeks of the year. The arena is empty after classes... almost."],
			["chazz", "A Slifer Red in the Obelisk arena. Somebody should check the schedule."],
			["jaden", "There was a free field and a guy with a deck. Sounded like an invitation to me!"],
			["chazz", "Every card in this deck was picked to fit the next one. Machines, built to win."],
			["jaden", "Mine are built to have fun. My heroes always find a way."],
			["chazz", "Fun. That is what people say right before they lose."],
			["jaden", "Then let's find out. Duel!"],
		],
		"after": [
			# by who won: 0 the first side, 1 the second
			[
				["chazz", "That was luck. Nothing else."],
				["jaden", "Maybe! It was still a great duel. Your machines had me worried there."],
				["chazz", "Next time I will not leave you a single card to stand on."],
				["jaden", "Can't wait. Rematch whenever you want!"],
			],
			[
				["chazz", "That is the difference between Blue and Red. Remember it."],
				["jaden", "Those machines hit hard... Okay, my heroes learned something today."],
				["chazz", "Learn faster. I am not waiting for you."],
				["jaden", "Ha! Next time you will have to."],
			],
		],
	},
]


static func by_id(id: String) -> Dictionary:
	for l in LEGENDS:
		if str(l["id"]) == id:
			return l
	return {}


static func in_era(era: String) -> Array:
	return LEGENDS.filter(func(l): return str(l["era"]) == era)


## What a star asks for, in words.
static func star_text(s: Array) -> String:
	match str(s[0]):
		"win":
			return Loc.t("Win the duel")
		"ace":
			return Loc.t("Win with %s on your field") % str(s[1])
		"turns":
			return Loc.t("Win by turn %d") % int(s[1])
	return ""


# ------------------------------------------------------------------ what you have done (legends.cfg)

static var PATH := Saves.u("legends.cfg")


static func _cfg() -> ConfigFile:
	var c := ConfigFile.new()
	c.load(PATH)
	return c


## Stars won on one side: an Array of three bools.
static func stars(id: String, side: int) -> Array:
	var bits := int(_cfg().get_value(id, "stars%d" % side, 0))
	return [bits & 1 != 0, bits & 2 != 0, bits & 4 != 0]


static func star_count(id: String) -> int:
	var n := 0
	for side in 2:
		for s in stars(id, side):
			n += 1 if s else 0
	return n


static func seen(id: String) -> bool:
	return bool(_cfg().get_value(id, "seen", false))


static func mark_seen(id: String) -> void:
	var c := _cfg()
	c.set_value(id, "seen", true)
	c.save(PATH)


## A duel is over: which stars it earned (new ones are returned as their indexes).
static func award(id: String, side: int, stats: Dictionary) -> Array:
	var l := by_id(id)
	if l.is_empty() or not bool(stats.get("won", false)):
		return []
	var c := _cfg()
	var bits := int(c.get_value(id, "stars%d" % side, 0))
	var got: Array = []
	var st: Array = l["sides"][side]["stars"]
	for i in st.size():
		var s: Array = st[i]
		var ok := false
		match str(s[0]):
			"win":
				ok = true
			"ace":
				ok = (stats.get("field", []) as Array).has(str(s[1]))
			"turns":
				ok = int(stats.get("turns", 99)) <= int(s[1])
		if ok and bits & (1 << i) == 0:
			bits |= 1 << i
			got.append(i)
	c.set_value(id, "stars%d" % side, bits)
	c.save(PATH)
	return got
