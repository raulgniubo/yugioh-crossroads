class_name Puzzles
## Duel puzzles: the field is already set, it is your turn, and you have this one turn to win.
## Each one is a real duel position played by the real rules. tools/puzzle_check.gd plays every
## puzzle through the rules engine to prove it can be won, and that just attacking is not enough.
##
## hand:   the cards you hold                mine:   your monsters, [name, "atk" | "def"]
## theirs: their monsters                    their_gy / my_gy: cards already in a Graveyard

const REWARD := 200
const LIST := [
	{"id": "gate", "title": "Open the Gate", "stars": 1, "opp_lp": 1500, "my_lp": 4000,
		"hint": "A wall is only a wall while it is in Defense Position.",
		"hand": ["Stop Defense", "Celtic Guardian"], "mine": [["Gemini Elf", "atk"]], "theirs": [["Giant Soldier of Stone", "def"]]},
	{"id": "crack", "title": "A Crack in the Ground", "stars": 1, "opp_lp": 2400, "my_lp": 4000,
		"hint": "You do not have to fight everything that stands in front of you.",
		"hand": ["Axe of Despair", "Fissure"], "mine": [["Battle Ox", "atk"]], "theirs": [["La Jinn the Mystical Genie of the Lamp", "atk"]]},
	{"id": "small", "title": "Cut Down to Size", "stars": 2, "opp_lp": 1300, "my_lp": 4000,
		"hint": "If you cannot get bigger than it, make it smaller. Then get bigger anyway.",
		"hand": ["Shrink", "Rush Recklessly"], "mine": [["Gemini Elf", "atk"]], "theirs": [["Summoned Skull", "atk"]]},
	{"id": "borrow", "title": "Borrowed Power", "stars": 2, "opp_lp": 4800, "my_lp": 4000,
		"hint": "The strongest monster on the field is not on your side. Yet.",
		"hand": ["Change of Heart", "Vorse Raider", "Hammer Shot"], "mine": [], "theirs": [["Blue-Eyes White Dragon", "atk"]]},
	{"id": "tribute", "title": "Worth the Price", "stars": 2, "opp_lp": 3000, "my_lp": 4000,
		"hint": "One of your monsters is worth more as a tribute than as an attacker.",
		"hand": ["Summoned Skull", "Axe of Despair", "Fissure"], "mine": [["Celtic Guardian", "atk"], ["Mystical Elf", "def"]],
		"theirs": [["Vorse Raider", "atk"], ["La Jinn the Mystical Genie of the Lamp", "atk"]]},
	{"id": "mage", "title": "Every Card Counts", "stars": 3, "opp_lp": 4000, "my_lp": 4000,
		"hint": "Mage Power counts every Spell and Trap you control. Even the ones you will never use.",
		"hand": ["Mage Power", "Mirror Force", "Negate Attack"], "mine": [["Dark Magician", "atk"]], "theirs": []},
	{"id": "mega", "title": "Back Against the Wall", "stars": 3, "opp_lp": 3000, "my_lp": 1000,
		"hint": "Megamorph doubles a monster while your Life Points are the lower ones. A wall that big still needs something to go through it.",
		"hand": ["Megamorph", "Fairy Meteor Crush"], "mine": [["Blue-Eyes White Dragon", "atk"]], "theirs": [["Millennium Shield", "def"]]},
	{"id": "reborn", "title": "Not Yours, Not Gone", "stars": 3, "opp_lp": 4000, "my_lp": 4000,
		"hint": "Monster Reborn does not care whose Graveyard it reaches into.",
		"hand": ["Monster Reborn", "Axe of Despair", "Fissure"], "mine": [], "theirs": [["Mystical Elf", "def"]],
		"their_gy": ["Blue-Eyes White Dragon"]},
	{"id": "storm", "title": "The Price of Lightning", "stars": 4, "opp_lp": 4600, "my_lp": 4000,
		"hint": "Lightning Vortex asks for a card from your hand. Which one will you miss least?",
		"hand": ["Lightning Vortex", "Celtic Guardian", "Axe of Despair"], "mine": [["Battle Ox", "atk"], ["La Jinn the Mystical Genie of the Lamp", "atk"]],
		"theirs": [["Vorse Raider", "atk"], ["Gemini Elf", "atk"], ["Luster Dragon", "atk"]]},
	# The written part of the promotion exam (Academy story, chapter 7). "exam": not on the puzzle board.
	# "real_only": tools/puzzle_check.gd cannot play it; tests/ocg_sim.tscn -- puzzles <id> 3 1 can.
	{"id": "exam_1", "title": "Exam: The Wall", "stars": 2, "exam": true, "opp_lp": 2500, "my_lp": 4000,
		"hint": "A monster in Defense Position is a target, not a wall.",
		"hand": ["Shield Crush", "Rush Recklessly"], "mine": [["Gemini Elf", "atk"]], "theirs": [["Big Shield Gardna", "def"]]},
	{"id": "exam_2", "real_only": true, "title": "Exam: Give and Take", "stars": 3, "exam": true, "opp_lp": 3500, "my_lp": 4000,
		"hint": "You can give before you take. Choose carefully what you give.",
		"hand": ["Creature Swap", "Axe of Despair"], "mine": [["Kuriboh", "atk"]], "theirs": [["Ancient Gear Golem", "atk"]]},
	{"id": "exam_3", "real_only": true, "title": "Exam: The Useful Tribute", "stars": 3, "exam": true, "opp_lp": 3600, "my_lp": 4000,
		"hint": "A monster you summon this turn can still be useful if it never attacks.",
		"hand": ["Enemy Controller", "Vorse Raider"], "mine": [["Gemini Elf", "atk"]],
		"theirs": [["Ancient Gear Golem", "atk"], ["Ancient Gear Soldier", "atk"]]},
]


static func by_id(id: String) -> Dictionary:
	for p in LIST:
		if p["id"] == id:
			return p
	return {}


static func _id(name: String) -> int:
	return int(CardData.NAME_TO_ID.get(name.to_lower(), 0))


## Is every card of this puzzle in the card folder?
static func ready(pz: Dictionary) -> bool:
	for n in names(pz):
		if _id(n) == 0:
			return false
	return true


static func names(pz: Dictionary) -> Array:
	var out: Array = (pz.get("hand", []) as Array).duplicate()
	for pair in (pz.get("mine", []) as Array) + (pz.get("theirs", []) as Array):
		out.append(pair[0])
	return out + (pz.get("their_gy", []) as Array) + (pz.get("my_gy", []) as Array)


## Your deck in a puzzle is exactly your hand: every card of it is drawn before you move.
static func hand_ids(pz: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for n in pz.get("hand", []):
		out.append(_id(str(n)))
	return out


## The other side holds nothing that can answer you: plain monsters only.
static func filler_ids() -> Array[int]:
	var out: Array[int] = []
	var id := _id("Mystical Elf")
	for i in 12:
		out.append(id)
	return out


## Start a state for this puzzle: your hand drawn, turn 1 already behind you.
static func begin(s: DuelState, pz: Dictionary) -> Array:
	var hand := hand_ids(pz)
	s.bonus_cards = [hand.size() - 6, 0]
	var ev := s.setup(hand, filler_ids(), "You", "Puzzle", 0)
	s.players[0].lp = int(pz.get("my_lp", 4000))
	s.players[1].lp = int(pz.get("opp_lp", 4000))
	return ev


## Put the monsters and Graveyards in place. Call after setup, before the first turn.
static func place(s: DuelState, pz: Dictionary) -> Array:
	var ev: Array = []
	for side in 2:
		for pair in pz.get("mine" if side == 0 else "theirs", []):
			var c := s._make(_id(str(pair[0])), side)
			ev.append_array(s._special(side, c, "puzzle", str(pair[1])))
			c.summoned_turn = 0
		for n in pz.get("my_gy" if side == 0 else "their_gy", []):
			s.players[side].gy.append(s._make(_id(str(n)), side))
	s.turn = 1   # so this is not the first turn of the duel: you draw, and you may attack
	return ev


## The Collection autoload, looked up by path so dev tools run with -s can load this file too.
static func _col() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Collection")


static func solved(id: String) -> bool:
	return bool((_col().record.get("puzzles", {}) as Dictionary).get(id, false))


## Mark a puzzle solved; returns the Duel Points it paid (only the first time).
static func mark(id: String) -> int:
	var col := _col()
	var done: Dictionary = col.record.get("puzzles", {})
	if done.get(id, false):
		return 0
	done[id] = true
	col.record["puzzles"] = done
	col.dp += REWARD
	col.save()
	return REWARD
