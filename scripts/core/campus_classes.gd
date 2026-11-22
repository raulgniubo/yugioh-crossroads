class_name CampusClasses
## The Academy's classes (story mode). Monday to Thursday mornings in the Lecture Hall, one class a
## day. Nobody watches a lesson: each class is one short challenge that pays merits, and each time
## you go it is a different one. Going is never required.
## A class is a small story script (CampusData.SCRIPTS "class_<kind>"). This file says which class
## is on, which version of it you get this time, and what its duel looks like.

const KINDS := ["theory", "practice", "build", "history"]      # Monday, Tuesday, Wednesday, Thursday
const NAMES := {"theory": "Duel Theory", "practice": "Practice", "build": "Deck Building", "history": "History of Dueling"}
const TEACHERS := {"theory": "Doctor Crowler", "practice": "Professor Sato", "build": "Doctor Crowler", "history": "Headmaster Sheppard"}
const WHAT := {
	"theory": "One field, already set, and one turn to win it. Three stars at the first attempt.",
	"practice": "A duel with a condition. Win it the way the professor asks.",
	"build": "Sixty cards on the desk. Forty go into a deck, and you duel with it.",
	"history": "You play a famous old deck against another one.",
}
## The chapter that has to be behind you before the classrooms open.
const OPENS_AFTER := "ac_ch1"
## Merits for one, two and three stars.
const PAY := [0, 10, 20, 30]

## Duel Theory: the problems, in the order you meet them (Puzzles, marked "class").
const THEORY := ["class_1", "class_2", "class_3", "class_4", "class_5"]
## Practice: the conditions. "my_lp": where you start.
const PRACTICE := [
	{"id": "no_direct", "rule": "Practice. Win without a single direct attack.", "text": "Win without a direct attack"},
	{"id": "low", "rule": "Practice. You start at 1000 Life Points. Win anyway.", "text": "Win from 1000 Life Points", "my_lp": 1000},
	{"id": "three", "rule": "Practice. Put three monsters on your field in a single turn, and win.", "text": "Summon three monsters in one turn, and win"},
]
## History of Dueling: whose deck you are lent, and whose your partner gets.
const HISTORY := [
	{"mine": "yugi", "theirs": "kaiba", "rule": "History of Dueling. You are lent the magicians' deck. Your partner has the dragons."},
	{"mine": "joey", "theirs": "mai", "rule": "History of Dueling. You are lent the gambler's deck. Your partner has the harpies."},
	{"mine": "kaiba", "theirs": "yugi", "rule": "History of Dueling. You are lent the dragons. Your partner has the magicians."},
	{"mine": "mai", "theirs": "joey", "rule": "History of Dueling. You are lent the harpies. Your partner has the gambler's deck."},
]

## Deck Building: what the sixty cards on the desk are drawn from. Plain, readable cards.
const POOL_SMALL := ["Gemini Elf", "Vorse Raider", "Luster Dragon", "Archfiend Soldier", "Insect Knight", "Mad Dog of Darkness", "Gene-Warped Warwolf",
	"Battle Ox", "Celtic Guardian", "La Jinn the Mystical Genie of the Lamp", "Neo the Magic Swordsman", "Dark Blade", "Axe Raider", "Dunames Dark Witch",
	"Warrior Dai Grepher", "Giant Soldier of Stone", "Mystical Elf", "Big Shield Gardna", "Sangan", "Giant Rat", "Mystic Tomato", "Shining Angel",
	"Mother Grizzly", "Marauding Captain", "Command Knight", "Exiled Force", "D.D. Warrior Lady", "Breaker the Magical Warrior", "Kuriboh",
	"Man-Eater Bug", "Hane-Hane", "Magician of Faith", "Skilled Dark Magician", "Mechanicalchaser", "X-Head Cannon", "Opticlops", "Sky Scout",
	"Spear Dragon", "Goblin Attack Force", "Slate Warrior", "Kycoo the Ghost Destroyer", "Don Zaloog", "Zombyra the Dark", "Nimble Momonga", "Pyramid Turtle"]
const POOL_BIG := ["Summoned Skull", "Jinzo", "Luster Dragon #2", "Millennium Shield", "Dark Magician Girl", "Vampire Lord", "Airknight Parshath",
	"Mobius the Frost Monarch", "Zaborg the Thunder Monarch", "Blue-Eyes White Dragon", "Dark Magician", "Red-Eyes Black Dragon", "Cyber Dragon",
	"Catapult Turtle", "Curse of Dragon", "Chaos Command Magician", "Dark Ruler Ha Des"]
const POOL_SPELLS := ["Rush Recklessly", "Axe of Despair", "Hammer Shot", "Fissure", "Smashing Ground", "Mystical Space Typhoon", "Monster Reborn",
	"Shrink", "Book of Moon", "Enemy Controller", "Stop Defense", "Malevolent Nuzzler", "Black Pendant", "Lightning Vortex", "Nobleman of Crossout",
	"Swords of Revealing Light", "Premature Burial", "Tribute to the Doomed", "Giant Trunade", "Heavy Storm", "Dian Keto the Cure Master", "Megamorph",
	"Mage Power", "United We Stand", "Soul Exchange", "Reinforcement of the Army", "Creature Swap", "Scapegoat", "Dark Hole"]
const POOL_TRAPS := ["Trap Hole", "Sakuretsu Armor", "Negate Attack", "Magic Cylinder", "Waboku", "Threatening Roar", "Mirror Force", "Bottomless Trap Hole",
	"Dust Tornado", "Call of the Haunted", "Draining Shield", "Widespread Ruin", "Magic Jammer", "Seven Tools of the Bandit", "Reckless Greed",
	"Torrential Tribute", "Raigeki Break", "Compulsory Evacuation Device"]
const POOL_SIZE := 60
const DECK_SIZE := 40


static func unlocked() -> bool:
	return Campus.chapter_done(OPENS_AFTER)


## The class of a weekday (0 Monday), "" from Friday on.
static func kind_on(weekday: int) -> String:
	return str(KINDS[weekday]) if weekday >= 0 and weekday < KINDS.size() else ""


## The class you can walk into right now: "" when there is none (it is not a morning from Monday to
## Thursday, the classrooms are not open yet, or you have already been today).
static func now() -> String:
	if not unlocked() or Campus.part() != 0:
		return ""
	if int(Campus.v("class_day", 0)) == Campus.day():
		return ""
	return kind_on(Campus.weekday())


## How many times you have been to a class, and your best stars in it.
static func record(kind: String) -> Dictionary:
	var all: Dictionary = Campus.v("classes", {})
	var r: Dictionary = all.get(kind, {})
	return {"n": int(r.get("n", 0)), "best": int(r.get("best", 0))}


static func versions(kind: String) -> int:
	match kind:
		"theory":
			return THEORY.size()
		"practice":
			return PRACTICE.size()
		"history":
			return HISTORY.size()
	return 4


## Which version of a class you get: the next one you have not had, round and round.
static func variant(kind: String) -> int:
	return int(record(kind)["n"]) % versions(kind)


## What the class's duel step becomes (laid over what the script says).
static func duel(kind: String) -> Dictionary:
	var v := variant(kind)
	match kind:
		"theory":
			return {"puzzle": str(THEORY[v])}
		"practice":
			var p: Dictionary = PRACTICE[v]
			var out := {"rule": str(p["rule"])}
			if p.has("my_lp"):
				out["my_lp"] = int(p["my_lp"])
			return out
		"history":
			var h: Dictionary = HISTORY[v]
			return {"my_deck": str(h["mine"]), "opp_deck": str(h["theirs"]), "deck_tier": "full", "rule": str(h["rule"])}
		"build":
			return {"opp_list": pick(pool(_seed() + 7919))}
	return {}


static func _seed() -> int:
	return 6100 + int(record("build")["n"]) * 131 + int(Campus.v("seed", 0))


static func _ids(names: Array) -> Array:
	var out: Array = []
	for n in names:
		var id := DeckTiers._id(str(n))
		if id != 0:
			out.append(id)
	return out


## The sixty cards on your desk: 26 small monsters, 8 big ones, 14 Spells, 12 Traps, one of each.
## The same every time for the same seed (so leaving and coming back does not reshuffle the desk).
static func pool(with_seed := -1) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed() if with_seed < 0 else with_seed
	var out: Array = []
	for part in [[POOL_SMALL, 26], [POOL_BIG, 8], [POOL_SPELLS, 14], [POOL_TRAPS, 12]]:
		var ids := _ids(part[0])
		# (a shuffle of our own: Array.shuffle uses the global generator)
		for i in range(ids.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = ids[i]
			ids[i] = ids[j]
			ids[j] = t
		out.append_array(ids.slice(0, int(part[1])))
	return out


## Forty of the sixty, chosen sensibly: the strongest small monsters, a few big ones, and the
## Spells and Traps. What your partner builds, and what "fill the rest for me" does.
static func pick(cards: Array, have: Array = []) -> Array:
	var chosen: Array = have.duplicate()
	var small: Array = []
	var big: Array = []
	var spells: Array = []
	var traps: Array = []
	for id in cards:
		if chosen.has(id):
			continue
		var c := CardData.get_card(int(id))
		match str(c.get("kind", "monster")):
			"spell":
				spells.append(id)
			"trap":
				traps.append(id)
			_:
				if int(c.get("level", 4)) >= 5:
					big.append(id)
				else:
					small.append(id)
	var by_atk := func(a, b): return int(CardData.get_card(int(a)).get("atk", 0)) > int(CardData.get_card(int(b)).get("atk", 0))
	small.sort_custom(by_atk)
	big.sort_custom(by_atk)
	# How many of each a forty-card deck wants, less what is already in it.
	var want := {"small": 18, "big": 4, "spell": 10, "trap": 8}
	for id in chosen:
		var c := CardData.get_card(int(id))
		var k := str(c.get("kind", "monster"))
		if k == "monster":
			k = "big" if int(c.get("level", 4)) >= 5 else "small"
		want[k] = int(want[k]) - 1
	for pair in [[small, "small"], [big, "big"], [spells, "spell"], [traps, "trap"]]:
		for id in (pair[0] as Array).slice(0, maxi(0, int(want[pair[1]]))):
			if chosen.size() < DECK_SIZE:
				chosen.append(id)
	# Still short (somebody chose a strange mix): anything left, monsters first.
	for id in small + big + spells + traps:
		if chosen.size() >= DECK_SIZE:
			break
		if not chosen.has(id):
			chosen.append(id)
	return chosen.slice(0, DECK_SIZE)


## Did the duel meet the Practice condition? `stats`: Router.last_stats.
static func condition_met(stats: Dictionary) -> bool:
	if not bool(stats.get("won", false)):
		return false
	match str(PRACTICE[variant("practice")]["id"]):
		"no_direct":
			return int(stats.get("directs", 0)) == 0
		"low":
			return true
		"three":
			return int(stats.get("summons", 0)) >= 3
	return false


## The stars a class ended with (1 to 3), from the story's flags.
static func stars(kind: String, flags: Dictionary) -> int:
	match kind:
		"theory":
			if flags.has("solved"):
				return 3
			return 2 if flags.has("second") and flags.has("won") else 1
		"practice":
			if flags.has("met"):
				return 3
			return 2 if flags.has("won") else 1
	return 3 if flags.has("won") else 1


## The class is over: merits, the record, the missions, and the morning is spent. Returns the merits.
static func finish(kind: String, n_stars: int) -> int:
	n_stars = clampi(n_stars, 1, 3)
	var all: Dictionary = (Campus.v("classes", {}) as Dictionary).duplicate(true)
	var r: Dictionary = all.get(kind, {})
	r["n"] = int(r.get("n", 0)) + 1
	r["best"] = maxi(int(r.get("best", 0)), n_stars)
	all[kind] = r
	Campus.put_many({"classes": all, "class_day": Campus.day()})
	var pay := int(PAY[n_stars])
	Campus.add_merits(pay, str(NAMES.get(kind, "Class")))
	Campus.mission_count("class")
	if n_stars >= 3:
		Campus.mission_count("class3")
	if Campus.part() == 0:
		Campus.pass_time()
	return pay
