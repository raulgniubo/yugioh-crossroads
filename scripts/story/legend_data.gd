class_name LegendData
extends RefCounted
## Legendary Duels (0.75.0): famous matchups from the shows, played with the decks the duelists had
## at that time, with a short scene before and after written for this game (never the show's own
## scenes or lines). Three matchups per era (0.79.0; one per era in 0.75.1).
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
		"id": "dm_yugi_pegasus_dk",
		"era": "dm",
		"title": "Yugi vs Pegasus",
		"when": "The final duel on the island",
		"field": "shadow",
		"picture": "res://assets/ui/story_title_domino.jpg",
		"sides": [
			{"key": "yugi", "deck": "legend_yugi_dk", "stars": [["win"], ["ace", "Gaia the Dragon Champion"], ["turns", 9]]},
			{"key": "pegasus", "deck": "anime_pegasus_2", "stars": [["win"], ["ace", "Thousand-Eyes Restrict"], ["turns", 9]]},
		],
		"before": [
			["", "The top of the castle, the night of the final. The host of the tournament waits behind a smile."],
			["pegasus", "Welcome, Yugi-boy. You climbed all the way up here just to lose in my house."],
			["yugi", "I came for the people you took. Not for your prize."],
			["pegasus", "Such a serious face! My cartoons will cheer you up. They always know what you are going to do."],
			["yugi", "Then they know this too: I will not stop until I win."],
			["pegasus", "Marvelous. Let the show begin!"],
		],
		"after": [
			[
				["pegasus", "Impossible... I saw every card you were going to play."],
				["yugi", "You saw my cards. You never saw how we trust each other."],
				["pegasus", "Trust. What a strange little thing to lose to."],
			],
			[
				["pegasus", "Oh, don't look so sad. Everybody loses to me in the end."],
				["yugi", "This is not the end. I will come back for them."],
				["pegasus", "I'll leave the light on for you, Yugi-boy."],
			],
		],
	},
	{
		"id": "dm_yugi_marik_bc",
		"era": "dm",
		"title": "Yugi vs Marik",
		"when": "The Battle City finals",
		"field": "kaibacorp",
		"picture": "res://assets/ui/story_title_museum.jpg",
		"sides": [
			{"key": "yugi", "deck": "anime_yugi_2", "stars": [["win"], ["ace", "Dark Magician Girl"], ["turns", 9]]},
			{"key": "marik", "deck": "anime_marik_2", "stars": [["win"], ["ace", "The Winged Dragon of Ra"], ["turns", 9]]},
		],
		"before": [
			["", "A tower above the city, the last round of the finals. Two of the Egyptian gods are about to meet."],
			["marik", "So the pharaoh's little vessel made it to the end. How fitting. I wanted an audience."],
			["yugi", "This ends today, Marik. You have hurt enough people."],
			["marik", "Hurt? I am only getting started. My god does not know mercy."],
			["yugi", "My friends are with me in every card. That is something your god cannot burn."],
			["marik", "Then let us see what is left of them when the sun rises."],
		],
		"after": [
			[
				["marik", "No... the sun was mine. It was supposed to be mine."],
				["yugi", "It was never about owning it. Let go, Marik."],
				["marik", "Maybe... maybe it is time I did."],
			],
			[
				["marik", "Do you feel it? That is the heat of a real god."],
				["yugi", "I am still standing. And my friends are still here."],
				["marik", "Enjoy them while you can, little pharaoh."],
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
		"id": "gx_jaden_zane_grad",
		"era": "gx",
		"title": "Jaden vs Zane",
		"when": "Graduation day",
		"field": "academy",
		"picture": "res://assets/ui/academy_title.jpg",
		"sides": [
			{"key": "jaden", "deck": "legend_jaden_y1", "stars": [["win"], ["ace", "Elemental HERO Thunder Giant"], ["turns", 9]]},
			{"key": "zane", "deck": "anime_zane_1", "stars": [["win"], ["ace", "Cyber End Dragon"], ["turns", 9]]},
		],
		"before": [
			["", "The last day of the school year. The arena is full, and the best student of the Academy is leaving."],
			["zane", "Of everyone here, I picked you for my last duel at this school. Do not make me regret it."],
			["jaden", "Regret it? This is gonna be the best duel of the year!"],
			["zane", "Respect your opponent. That means everything you have, from the first card."],
			["jaden", "Everything I have. Got it! My heroes are fired up."],
			["zane", "Good. Then show me."],
		],
		"after": [
			[
				["zane", "You gave it everything. That is all I wanted to see."],
				["jaden", "That was amazing! Thanks for picking me, Zane."],
				["zane", "Keep dueling like that. The school is yours now."],
			],
			[
				["zane", "You held nothing back. Neither did I."],
				["jaden", "Man, those dragons... I gotta get stronger."],
				["zane", "You will. I will be watching."],
			],
		],
	},
	{
		"id": "gx_jaden_aster_y2",
		"era": "gx",
		"title": "Jaden vs Aster",
		"when": "The pro who came to school",
		"field": "bluehall",
		"picture": "res://assets/ui/academy_title.jpg",
		"sides": [
			{"key": "jaden", "deck": "anime_jaden_2", "stars": [["win"], ["ace", "Elemental HERO Neos"], ["turns", 9]]},
			{"key": "aster", "deck": "anime_aster_1", "stars": [["win"], ["ace", "Destiny HERO - Dreadmaster"], ["turns", 9]]},
		],
		"before": [
			["", "Second year. A professional duelist walks into the Academy, and everybody wants to see him play."],
			["aster", "So you are the famous Jaden. I expected someone taller."],
			["jaden", "And you're the pro! Cool. Wanna duel?"],
			["aster", "My heroes do not play. They follow a destiny, and it already says how this ends."],
			["jaden", "Nobody wrote my next draw yet. That's the fun part!"],
			["aster", "Fun. Let us see how long it lasts."],
		],
		"after": [
			[
				["aster", "That was not the ending I was told."],
				["jaden", "Told by who? You make your own ending, man."],
				["aster", "Perhaps. Next time I will write it myself."],
			],
			[
				["aster", "Destiny does not lose. Remember that."],
				["jaden", "Okay, that one stung. But I'm not done!"],
				["aster", "No. Nobody ever is, the first time."],
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
		"id": "5ds_yusei_kalin_ds",
		"era": "5ds",
		"title": "Yusei vs Kalin",
		"when": "The Dark Signers",
		"field": "satellite",
		"picture": "res://assets/ui/story_title_satellite.jpg",
		"sides": [
			{"key": "yusei", "deck": "anime_yusei_2", "stars": [["win"], ["ace", "Stardust Dragon"], ["turns", 9]]},
			{"key": "kalin", "deck": "anime_kalin_1", "stars": [["win"], ["ace", "Infernity Doom Dragon"], ["turns", 9]]},
		],
		"before": [
			["", "The Satellite, under a purple sky. An old friend from the gang days, back from somewhere dark."],
			["kalin", "Yusei. You look surprised. Did you think I would stay gone?"],
			["yusei", "Kalin. This is not you. Whatever brought you back, you can still walk away."],
			["kalin", "Walk away? I came back for one thing. You."],
			["yusei", "Then duel me. And when it is over, come home."],
			["kalin", "Home burned down a long time ago. Let us finish this."],
		],
		"after": [
			[
				["kalin", "So that is it... you were always the one who held us together."],
				["yusei", "We held each other. That never changed."],
				["kalin", "Maybe I can remember that now."],
			],
			[
				["kalin", "Do you see it now? This is what you left behind."],
				["yusei", "I never left you. I am still here, Kalin."],
				["kalin", "Then come and get me back. If you can."],
			],
		],
	},
	{
		"id": "5ds_yusei_akiza_fc",
		"era": "5ds",
		"title": "Yusei vs Akiza",
		"when": "The Fortune Cup semifinal",
		"field": "kaibacorp",
		"picture": "res://assets/ui/story_title_newdomino.jpg",
		"sides": [
			{"key": "yusei", "deck": "legend_yusei_s1", "stars": [["win"], ["ace", "Junk Warrior"], ["turns", 8]]},
			{"key": "akiza", "deck": "anime_akiza_1", "stars": [["win"], ["ace", "Black Rose Dragon"], ["turns", 8]]},
		],
		"before": [
			["", "The Fortune Cup, a stadium that is afraid of her. Everyone in the stands has heard the stories."],
			["akiza", "You heard them too. The witch. Everybody keeps their distance."],
			["yusei", "I am not here for stories. I am here to duel you."],
			["akiza", "Then you will get hurt, like all of them."],
			["yusei", "Maybe. But you do not have to duel alone."],
			["akiza", "Stop talking. Let my roses answer you."],
		],
		"after": [
			[
				["akiza", "You did not run. Not even once."],
				["yusei", "Your cards are not a curse. They are just strong. Like you."],
				["akiza", "Nobody has said that to me before."],
			],
			[
				["akiza", "I told you. People get hurt around me."],
				["yusei", "I am fine. And I would duel you again."],
				["akiza", "Why? ... You are a strange one, Yusei."],
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
	{
		"id": "zexal_yuma_kite_hunt",
		"era": "zexal",
		"title": "Yuma vs Kite",
		"when": "The Number Hunter",
		"field": "heartland",
		"picture": "res://assets/ui/story_title_heartland.jpg",
		"sides": [
			{"key": "yuma", "deck": "anime_yuma_2", "stars": [["win"], ["ace", "Number 39: Utopia"], ["turns", 9]]},
			{"key": "kite", "deck": "anime_kite_1", "stars": [["win"], ["ace", "Galaxy-Eyes Photon Dragon"], ["turns", 9]]},
		],
		"before": [
			["", "Heartland City at night. Someone is hunting Numbers, and Yuma has one."],
			["kite", "You have a Number. Hand it over, or I take it."],
			["yuma", "No way! You don't get to just take people's cards!"],
			["kite", "I do not have time for this. My dragon will end it quickly."],
			["yuma", "Then I'll just have to keep going until your dragon gets tired!"],
			["kite", "It does not get tired. Let's go."],
		],
		"after": [
			[
				["kite", "Hm. You are more stubborn than you look."],
				["yuma", "Told you! I never give up!"],
				["kite", "This is not over. I will be back for that Number."],
			],
			[
				["kite", "That is the difference between a hunter and a kid."],
				["yuma", "I'm not done yet! I'll be stronger next time!"],
				["kite", "Then be ready. I will not go easy."],
			],
		],
	},
	{
		"id": "zexal_yuma_vector_barian",
		"era": "zexal",
		"title": "Yuma vs Vector",
		"when": "The Barian war",
		"field": "shadow",
		"picture": "res://assets/ui/story_title_heartland.jpg",
		"sides": [
			{"key": "yuma", "deck": "anime_yuma_2", "stars": [["win"], ["ace", "Number C39: Utopia Ray"], ["turns", 9]]},
			{"key": "vector", "deck": "anime_vector_1", "stars": [["win"], ["ace", "Number C104: Umbral Horror Masquerade"], ["turns", 9]]},
		],
		"before": [
			["", "The war with the Barian World. A friend from school was never a friend at all."],
			["vector", "Surprise, Yuma! Did you miss me? Your old pal from class?"],
			["yuma", "You lied to everybody. To me, too."],
			["vector", "Lying is the fun part! And now I get to see your face when you lose."],
			["yuma", "Not today. I believe in my friends, and they believe in me."],
			["vector", "Ooh, so sweet. Let's see it break."],
		],
		"after": [
			[
				["vector", "No, no, no! That was not how this was supposed to go!"],
				["yuma", "You can still change, Vector. It is never too late."],
				["vector", "Ha... Don't be stupid. Just... don't."],
			],
			[
				["vector", "Ahahaha! Look at you! Was it worth trusting me?"],
				["yuma", "I'm not sorry I trusted you. I'm getting back up."],
				["vector", "Of course you are. That's what makes it so fun."],
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
