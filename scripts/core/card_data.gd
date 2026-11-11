class_name CardData
extends RefCounted
## Static card data and starter decks. Used by the rules (no textures here).

## kind: "monster" or "spell". effect is used by spells.
const CARDS := {
	# Yugi-style
	46986414: {"name": "Dark Magician", "kind": "monster", "atk": 2500, "def": 2100, "level": 7, "attribute": "DARK", "race": "Spellcaster"},
	70781052: {"name": "Summoned Skull", "kind": "monster", "atk": 2500, "def": 1200, "level": 6, "attribute": "DARK", "race": "Fiend"},
	6368038: {"name": "Gaia The Fierce Knight", "kind": "monster", "atk": 2300, "def": 2100, "level": 7, "attribute": "EARTH", "race": "Warrior"},
	28279543: {"name": "Curse of Dragon", "kind": "monster", "atk": 2000, "def": 1500, "level": 5, "attribute": "DARK", "race": "Dragon"},
	91152256: {"name": "Celtic Guardian", "kind": "monster", "atk": 1400, "def": 1200, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	41392891: {"name": "Feral Imp", "kind": "monster", "atk": 1300, "def": 1400, "level": 4, "attribute": "DARK", "race": "Fiend"},
	15025844: {"name": "Mystical Elf", "kind": "monster", "atk": 800, "def": 2000, "level": 4, "attribute": "LIGHT", "race": "Spellcaster"},
	13039848: {"name": "Giant Soldier of Stone", "kind": "monster", "atk": 1300, "def": 2000, "level": 3, "attribute": "EARTH", "race": "Rock"},
	32452818: {"name": "Beaver Warrior", "kind": "monster", "atk": 1200, "def": 1500, "level": 4, "attribute": "EARTH", "race": "Beast-Warrior"},
	69140098: {"name": "Gemini Elf", "kind": "monster", "atk": 1900, "def": 900, "level": 4, "attribute": "EARTH", "race": "Spellcaster"},
	66602787: {"name": "Saggi the Dark Clown", "kind": "monster", "atk": 600, "def": 1500, "level": 3, "attribute": "DARK", "race": "Spellcaster"},
	90357090: {"name": "Silver Fang", "kind": "monster", "atk": 1200, "def": 800, "level": 3, "attribute": "EARTH", "race": "Beast"},
	# Kaiba-style
	89631139: {"name": "Blue-Eyes White Dragon", "kind": "monster", "atk": 3000, "def": 2500, "level": 8, "attribute": "LIGHT", "race": "Dragon"},
	30113682: {"name": "Judge Man", "kind": "monster", "atk": 2200, "def": 1500, "level": 6, "attribute": "EARTH", "race": "Warrior"},
	26378150: {"name": "Rude Kaiser", "kind": "monster", "atk": 1800, "def": 1600, "level": 5, "attribute": "EARTH", "race": "Beast-Warrior"},
	14898066: {"name": "Vorse Raider", "kind": "monster", "atk": 1900, "def": 1200, "level": 4, "attribute": "DARK", "race": "Beast-Warrior"},
	97590747: {"name": "La Jinn the Mystical Genie of the Lamp", "kind": "monster", "atk": 1800, "def": 1000, "level": 4, "attribute": "DARK", "race": "Fiend"},
	5053103: {"name": "Battle Ox", "kind": "monster", "atk": 1700, "def": 1000, "level": 4, "attribute": "EARTH", "race": "Beast-Warrior"},
	67724379: {"name": "Koumori Dragon", "kind": "monster", "atk": 1500, "def": 1200, "level": 4, "attribute": "DARK", "race": "Dragon"},
	24611934: {"name": "Ryu-Kishin Powered", "kind": "monster", "atk": 1600, "def": 1200, "level": 4, "attribute": "DARK", "race": "Fiend"},
	76184692: {"name": "Hitotsu-Me Giant", "kind": "monster", "atk": 1200, "def": 1000, "level": 4, "attribute": "EARTH", "race": "Beast-Warrior"},
	88819587: {"name": "Baby Dragon", "kind": "monster", "atk": 1200, "def": 700, "level": 3, "attribute": "WIND", "race": "Dragon"},
	64428736: {"name": "Alligator's Sword", "kind": "monster", "atk": 1500, "def": 1200, "level": 4, "attribute": "EARTH", "race": "Beast"},
	# Spells
	55144522: {"name": "Pot of Greed", "kind": "spell", "effect": "draw2", "text": "Draw 2 cards."},
	84257639: {"name": "Dian Keto the Cure Master", "kind": "spell", "effect": "heal1000", "text": "Increase your Life Points by 1000."},
	66788016: {"name": "Fissure", "kind": "spell", "effect": "fissure", "text": "Destroy the 1 face-up monster your opponent controls that has the lowest ATK."},
}

const DECKS := {
	"yugi": {
		"name": "Dark Magician",
		"duelist": "Yugi Muto",
		"cards": {46986414: 2, 70781052: 2, 6368038: 1, 28279543: 2, 91152256: 3, 41392891: 3,
			15025844: 2, 13039848: 3, 32452818: 3, 69140098: 2, 66602787: 1, 90357090: 1,
			55144522: 1, 84257639: 2, 66788016: 2},
	},
	"kaiba": {
		"name": "Blue-Eyes",
		"duelist": "Seto Kaiba",
		"cards": {89631139: 3, 30113682: 2, 26378150: 2, 14898066: 3, 97590747: 3, 5053103: 3,
			67724379: 2, 24611934: 2, 76184692: 2, 88819587: 2, 64428736: 2,
			55144522: 1, 66788016: 2, 84257639: 1},
	},
}


static func get_card(id: int) -> Dictionary:
	var d: Dictionary = CARDS.get(id, {"name": "Unknown", "kind": "monster"}).duplicate()
	d["id"] = id
	return d


static func deck_list(deck_key: String) -> Array[int]:
	var out: Array[int] = []
	var cards: Dictionary = DECKS[deck_key]["cards"]
	for id in cards:
		for i in cards[id]:
			out.append(int(id))
	return out
