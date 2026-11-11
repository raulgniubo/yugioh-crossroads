class_name RoamData
## Free-roam districts: who stands where, what they say, and who wants to duel.

const DISTRICTS := {
	"domino": {
		"name": "Domino City",
		"area": "Downtown",
		"theme": "battlecity",
		"npcs": [
			{"id": "yugi", "char": "yugi", "pos": Vector3(-9, 0, -14), "face": 0.0,
				"lines": ["Hey, {player}! Grandpa says the shop is getting a new shipment today.", "Whenever you want a real test, I'll be here."],
				"duel": {"deck": "yugi", "difficulty": 2, "intro": "Let's see how much you've grown!"}},
			{"id": "joey", "char": "joey", "pos": Vector3(12, 0, 6), "face": -1.6,
				"lines": ["Yo! Ya look like someone who needs a warm-up duel.", "I ain't losin' twice in one day, ya hear?"],
				"duel": {"deck": "joey", "difficulty": 1, "intro": "Time ta roll the dice!"}},
			{"id": "mai", "char": "mai", "pos": Vector3(15, 0, -18), "face": -2.4,
				"lines": ["You're blocking my view of the skyline, rookie.", "...Fine. One duel. Don't waste my time."],
				"duel": {"deck": "mai", "difficulty": 2, "intro": "Harpies, show them some manners."}},
			{"id": "bakura", "char": "bakura", "pos": Vector3(-17, 0, 9), "face": 1.2,
				"lines": ["Oh! Sorry, I was miles away.", "Do you ever feel like the city is... watching you?"],
				"duel": {"deck": "bakura", "difficulty": 2, "intro": "Let's play a little game, shall we?"}},
			{"id": "kid", "char": "", "model": "street_duelist", "name": "Rookie Duelist", "color": Color("f0a040"), "pos": Vector3(3, 0, 14), "face": 3.0,
				"lines": ["I just built my first deck! Wanna duel? Please?"],
				"duel": {"deck": "joey", "difficulty": 0, "intro": "Here goes nothing!"}},
			{"id": "vendor", "char": "", "model": "shopkeeper", "name": "Card Vendor", "color": Color("40c0a0"), "pos": Vector3(-4, 0, -12), "face": 0.4,
				"lines": ["Kame Game's been here longer than KaibaCorp tower, you know.", "Win some duels around town and the shop might have something special for you."]},
			{"id": "guard", "char": "", "model": "office_worker", "name": "KaibaCorp Guard", "color": Color("4070e0"), "pos": Vector3(0, 0, -30), "face": 0.0,
				"lines": ["KaibaCorp Tower. No entry without an appointment.", "Mr. Kaiba doesn't take walk-ins. ...Especially not you."]},
			{"id": "hunter", "char": "hunter", "pos": Vector3(-20, 0, -24), "face": 0.8,
				"lines": ["...", "The Hollows remember your face, duelist."],
				"duel": {"deck": "yusei", "difficulty": 1, "intro": "Your soul will make a fine card."}},
		],
		# Inside Kame Game (positions are relative to the shop room).
		"shop_npcs": [
			{"id": "owner", "char": "", "model": "shopkeeper", "name": "Shop Owner", "color": Color("c9a76a"), "pos": Vector3(0, 0, -4.1), "face": 0.0, "shop": true,
				"lines": ["Welcome to Kame Game, {player}! Take your time and look around.", "Want to switch the deck you duel with? I keep them all behind the counter."]},
			{"id": "regular", "char": "", "model": "student_girl", "name": "Shop Regular", "color": Color("ff8ac0"), "pos": Vector3(4.0, 0, 1.6), "face": 2.6,
				"lines": ["The tables are free play. Winner stays on!"],
				"duel": {"deck": "alexis", "difficulty": 1, "intro": "Table two is mine!"}},
			{"id": "browser", "char": "", "model": "student_boy", "name": "Card Collector", "color": Color("7cc4ff"), "pos": Vector3(-5.2, 0, -3.2), "face": 2.2,
				"lines": ["I've opened forty packs and still no ultra rare...", "The mirror over there lets you change your outfit, by the way."]},
		],
	},
}


static func district(key: String) -> Dictionary:
	return DISTRICTS.get(key, DISTRICTS["domino"])
