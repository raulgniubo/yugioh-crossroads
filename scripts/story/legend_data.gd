class_name LegendData
extends RefCounted
## Legendary Duels (0.75.0): famous matchups from the shows, played with the decks the duelists had
## at that time, with a short scene before and after written for this game (never the show's own
## scenes or lines). One matchup per era for now (0.75.1).
##
## A matchup: id, era, the two duelists (keys of Characters), their decks of the time
## (CardData.NAMED_DECKS keys), the place behind the scenes, and for each side the three stars:
## ["win"], ["ace", card name] (it is on your field when you win), ["turns", n] (win by turn n).
## Lines are [speaker key or "" for the narrator, text in English]; Spanish comes through Loc.

const ERAS := [["dm", "Duel Monsters"], ["gx", "GX"], ["5ds", "5D's"], ["zexal", "ZEXAL"]]

const LEGENDS := [
	{
		"id": "dm_yugi_kaiba_dk",
		"era": "dm",
		"title": "Yugi vs Kaiba",
		"when": "The island tournament",
		"field": "battlecity",
		"picture": "res://assets/ui/story_title_domino.jpg",
		"sides": [
			{"key": "yugi", "deck": "legend_yugi_dk", "stars": [["win"], ["ace", "Dark Magician"], ["turns", 8]]},
			{"key": "kaiba", "deck": "legend_kaiba_dk", "stars": [["win"], ["ace", "Blue-Eyes Ultimate Dragon"], ["turns", 8]]},
		],
		"before": [
			["", "A tournament on an island, a castle on the cliffs. Two duelists who have met before."],
			["kaiba", "Last time was an accident. Today the score gets fixed."],
			["yugi", "It was never about the score, Kaiba. It is about trusting your cards."],
			["kaiba", "Trust? My dragons do not need trust. They need something to crush."],
			["yugi", "Then let's see whose deck answers when it counts."],
			["kaiba", "Draw. And try to make this interesting."],
		],
		"after": [
			[
				["kaiba", "Again. How does that deck keep doing that?"],
				["yugi", "You treat it like a machine. It is a team."],
				["kaiba", "Spare me. I will be back, and I will be ready for your team."],
			],
			[
				["kaiba", "Now it is settled. Power beats sentiment, every time."],
				["yugi", "You played well. But this is not over, Kaiba."],
				["kaiba", "For you it is. Go home and rebuild that deck."],
			],
		],
	},
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
	{
		"id": "5ds_yusei_jack_s1",
		"era": "5ds",
		"title": "Yusei vs Jack",
		"when": "The Fortune Cup",
		"field": "highway",
		"picture": "res://assets/ui/story_title_newdomino.jpg",
		"sides": [
			{"key": "yusei", "deck": "legend_yusei_s1", "stars": [["win"], ["ace", "Stardust Dragon"], ["turns", 8]]},
			{"key": "jack", "deck": "legend_jack_s1", "stars": [["win"], ["ace", "Red Dragon Archfiend"], ["turns", 8]]},
		],
		"before": [
			["", "New Domino City. A stadium full of lights, and an old friendship gone cold."],
			["jack", "So you finally climbed up here. The view is better from the top, isn't it?"],
			["yusei", "I did not come for the view, Jack. I came for answers."],
			["jack", "The only answer you will get is the one my dragon gives."],
			["yusei", "My deck is made of cards nobody wanted. Together they still get back up."],
			["jack", "Then let's count how many times. Show me, Yusei!"],
		],
		"after": [
			[
				["jack", "The cards nobody wanted... and they beat me."],
				["yusei", "They never fight alone. You did not either, once."],
				["jack", "Do not get sentimental. Next time I take it all back."],
			],
			[
				["jack", "The crown stays where it is. Remember the view from down there."],
				["yusei", "I will. And I will be back up here."],
				["jack", "I am counting on it."],
			],
		],
	},
	{
		"id": "zexal_yuma_shark_early",
		"era": "zexal",
		"title": "Yuma vs Shark",
		"when": "The first Numbers",
		"field": "heartland",
		"picture": "res://assets/ui/story_title_heartland.jpg",
		"sides": [
			{"key": "yuma", "deck": "legend_yuma_early", "stars": [["win"], ["ace", "Number 39: Utopia"], ["turns", 8]]},
			{"key": "shark", "deck": "legend_shark_early", "stars": [["win"], ["ace", "Number 17: Leviathan Dragon"], ["turns", 8]]},
		],
		"before": [
			["", "Heartland City, a schoolyard after class. A deck, a dare, and somebody who will not back down."],
			["shark", "You are the kid who keeps saying he will be champion? Cute."],
			["yuma", "Not cute. True! And I am not backing down from you."],
			["shark", "Bold. My sharks can smell fear from a mile away."],
			["yuma", "Then they will smell nothing. Let's go!"],
			["shark", "Fine. Do not cry when this is over."],
		],
		"after": [
			[
				["shark", "Huh. You got lucky, kid."],
				["yuma", "Lucky? I kept going! That is how you win!"],
				["shark", "Keep going, then. I will be waiting."],
			],
			[
				["shark", "Told you. The deep is no place for beginners."],
				["yuma", "I am not done! Next time I swim with you."],
				["shark", "Ha. Learn to float first."],
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
