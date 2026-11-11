class_name CardData
extends RefCounted
## Static card data and character decks. Used by the rules (no textures here).
##
## frame: normal | effect | fusion | synchro | xyz | spell
## Effect monsters are played as vanilla stats for now (effects come with the full rules engine).

const CARDS := {
	# ---------------------------------------------------------------- Yugi
	46986414: {"name": "Dark Magician", "frame": "normal", "atk": 2500, "def": 2100, "level": 7, "attribute": "DARK", "race": "Spellcaster"},
	70781052: {"name": "Summoned Skull", "frame": "normal", "atk": 2500, "def": 1200, "level": 6, "attribute": "DARK", "race": "Fiend"},
	6368038: {"name": "Gaia The Fierce Knight", "frame": "normal", "atk": 2300, "def": 2100, "level": 7, "attribute": "EARTH", "race": "Warrior"},
	28279543: {"name": "Curse of Dragon", "frame": "normal", "atk": 2000, "def": 1500, "level": 5, "attribute": "DARK", "race": "Dragon"},
	91152256: {"name": "Celtic Guardian", "frame": "normal", "atk": 1400, "def": 1200, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	41392891: {"name": "Feral Imp", "frame": "normal", "atk": 1300, "def": 1400, "level": 4, "attribute": "DARK", "race": "Fiend"},
	15025844: {"name": "Mystical Elf", "frame": "normal", "atk": 800, "def": 2000, "level": 4, "attribute": "LIGHT", "race": "Spellcaster"},
	13039848: {"name": "Giant Soldier of Stone", "frame": "normal", "atk": 1300, "def": 2000, "level": 3, "attribute": "EARTH", "race": "Rock"},
	32452818: {"name": "Beaver Warrior", "frame": "normal", "atk": 1200, "def": 1500, "level": 4, "attribute": "EARTH", "race": "Beast-Warrior"},
	69140098: {"name": "Gemini Elf", "frame": "normal", "atk": 1900, "def": 900, "level": 4, "attribute": "EARTH", "race": "Spellcaster"},
	66602787: {"name": "Saggi the Dark Clown", "frame": "normal", "atk": 600, "def": 1500, "level": 3, "attribute": "DARK", "race": "Spellcaster"},
	90357090: {"name": "Silver Fang", "frame": "normal", "atk": 1200, "def": 800, "level": 3, "attribute": "EARTH", "race": "Beast"},
	66889139: {"name": "Gaia the Dragon Champion", "frame": "fusion", "atk": 2600, "def": 2100, "level": 7, "attribute": "WIND", "race": "Dragon", "materials": [6368038, 28279543]},
	# ---------------------------------------------------------------- Kaiba
	89631139: {"name": "Blue-Eyes White Dragon", "frame": "normal", "atk": 3000, "def": 2500, "level": 8, "attribute": "LIGHT", "race": "Dragon"},
	30113682: {"name": "Judge Man", "frame": "normal", "atk": 2200, "def": 1500, "level": 6, "attribute": "EARTH", "race": "Warrior"},
	26378150: {"name": "Rude Kaiser", "frame": "normal", "atk": 1800, "def": 1600, "level": 5, "attribute": "EARTH", "race": "Beast-Warrior"},
	14898066: {"name": "Vorse Raider", "frame": "normal", "atk": 1900, "def": 1200, "level": 4, "attribute": "DARK", "race": "Beast-Warrior"},
	97590747: {"name": "La Jinn the Mystical Genie of the Lamp", "frame": "normal", "atk": 1800, "def": 1000, "level": 4, "attribute": "DARK", "race": "Fiend"},
	5053103: {"name": "Battle Ox", "frame": "normal", "atk": 1700, "def": 1000, "level": 4, "attribute": "EARTH", "race": "Beast-Warrior"},
	67724379: {"name": "Koumori Dragon", "frame": "normal", "atk": 1500, "def": 1200, "level": 4, "attribute": "DARK", "race": "Dragon"},
	24611934: {"name": "Ryu-Kishin Powered", "frame": "normal", "atk": 1600, "def": 1200, "level": 4, "attribute": "DARK", "race": "Fiend"},
	76184692: {"name": "Hitotsu-Me Giant", "frame": "normal", "atk": 1200, "def": 1000, "level": 4, "attribute": "EARTH", "race": "Beast-Warrior"},
	88819587: {"name": "Baby Dragon", "frame": "normal", "atk": 1200, "def": 700, "level": 3, "attribute": "WIND", "race": "Dragon"},
	64428736: {"name": "Alligator's Sword", "frame": "normal", "atk": 1500, "def": 1200, "level": 4, "attribute": "EARTH", "race": "Beast"},
	23995346: {"name": "Blue-Eyes Ultimate Dragon", "frame": "fusion", "atk": 4500, "def": 3800, "level": 12, "attribute": "LIGHT", "race": "Dragon", "materials": [89631139, 89631139, 89631139]},
	# ---------------------------------------------------------------- Joey
	74677422: {"name": "Red-Eyes Black Dragon", "frame": "normal", "atk": 2400, "def": 2000, "level": 7, "attribute": "DARK", "race": "Dragon"},
	48305365: {"name": "Axe Raider", "frame": "normal", "atk": 1700, "def": 1150, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	14977074: {"name": "Garoozis", "frame": "normal", "atk": 1800, "def": 1500, "level": 5, "attribute": "FIRE", "race": "Beast-Warrior"},
	18246479: {"name": "Battle Steer", "frame": "normal", "atk": 1800, "def": 1300, "level": 5, "attribute": "EARTH", "race": "Beast-Warrior"},
	34460851: {"name": "Flame Manipulator", "frame": "normal", "atk": 900, "def": 1000, "level": 3, "attribute": "FIRE", "race": "Spellcaster"},
	44287299: {"name": "Masaki the Legendary Swordsman", "frame": "normal", "atk": 1100, "def": 1100, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	49791927: {"name": "Tiger Axe", "frame": "normal", "atk": 1300, "def": 1100, "level": 4, "attribute": "EARTH", "race": "Beast-Warrior"},
	11901678: {"name": "Black Skull Dragon", "frame": "fusion", "atk": 3200, "def": 2500, "level": 9, "attribute": "DARK", "race": "Dragon", "materials": [70781052, 74677422]},
	45231177: {"name": "Flame Swordsman", "frame": "fusion", "atk": 1800, "def": 1600, "level": 5, "attribute": "FIRE", "race": "Warrior", "materials": [34460851, 44287299]},
	3366982: {"name": "Alligator's Sword Dragon", "frame": "fusion", "atk": 1700, "def": 1500, "level": 5, "attribute": "WIND", "race": "Dragon", "materials": [88819587, 64428736]},
	# ---------------------------------------------------------------- Jaden
	21844576: {"name": "Elemental HERO Avian", "frame": "normal", "atk": 1000, "def": 1000, "level": 3, "attribute": "WIND", "race": "Warrior"},
	58932615: {"name": "Elemental HERO Burstinatrix", "frame": "normal", "atk": 1200, "def": 800, "level": 3, "attribute": "FIRE", "race": "Warrior"},
	84327329: {"name": "Elemental HERO Clayman", "frame": "normal", "atk": 800, "def": 2000, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	20721928: {"name": "Elemental HERO Sparkman", "frame": "normal", "atk": 1600, "def": 1400, "level": 4, "attribute": "LIGHT", "race": "Warrior"},
	86188410: {"name": "Elemental HERO Wildheart", "frame": "effect", "atk": 1500, "def": 1600, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	79979666: {"name": "Elemental HERO Bubbleman", "frame": "effect", "atk": 800, "def": 1200, "level": 4, "attribute": "WATER", "race": "Warrior"},
	57116033: {"name": "Winged Kuriboh", "frame": "effect", "atk": 300, "def": 200, "level": 1, "attribute": "LIGHT", "race": "Fairy"},
	89943723: {"name": "Elemental HERO Neos", "frame": "normal", "atk": 2500, "def": 2000, "level": 7, "attribute": "LIGHT", "race": "Warrior"},
	35809262: {"name": "Elemental HERO Flame Wingman", "frame": "fusion", "atk": 2100, "def": 1200, "level": 6, "attribute": "WIND", "race": "Warrior", "materials": [21844576, 58932615]},
	61204971: {"name": "Elemental HERO Thunder Giant", "frame": "fusion", "atk": 2400, "def": 1500, "level": 6, "attribute": "LIGHT", "race": "Warrior", "materials": [20721928, 84327329]},
	47737087: {"name": "Elemental HERO Rampart Blaster", "frame": "fusion", "atk": 2000, "def": 2500, "level": 6, "attribute": "EARTH", "race": "Warrior", "materials": [58932615, 84327329]},
	# ---------------------------------------------------------------- Yusei
	63977008: {"name": "Junk Synchron", "frame": "effect", "tuner": true, "atk": 1300, "def": 500, "level": 3, "attribute": "DARK", "race": "Warrior"},
	96182448: {"name": "Nitro Synchron", "frame": "effect", "tuner": true, "atk": 300, "def": 100, "level": 2, "attribute": "FIRE", "race": "Machine"},
	9365703: {"name": "Speed Warrior", "frame": "effect", "atk": 900, "def": 400, "level": 2, "attribute": "WIND", "race": "Warrior"},
	23571046: {"name": "Quillbolt Hedgehog", "frame": "effect", "atk": 800, "def": 800, "level": 2, "attribute": "EARTH", "race": "Machine"},
	59546797: {"name": "Shield Warrior", "frame": "effect", "atk": 800, "def": 1600, "level": 3, "attribute": "EARTH", "race": "Warrior"},
	63142001: {"name": "Max Warrior", "frame": "effect", "atk": 1800, "def": 800, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	60800381: {"name": "Junk Warrior", "frame": "synchro", "atk": 2300, "def": 1300, "level": 5, "attribute": "DARK", "race": "Warrior"},
	44508094: {"name": "Stardust Dragon", "frame": "synchro", "atk": 2500, "def": 2000, "level": 8, "attribute": "WIND", "race": "Dragon"},
	51447164: {"name": "Nitro Warrior", "frame": "synchro", "atk": 2800, "def": 1800, "level": 7, "attribute": "FIRE", "race": "Warrior"},
	# ---------------------------------------------------------------- Yuma
	26082117: {"name": "Gagaga Magician", "frame": "effect", "atk": 1500, "def": 1000, "level": 4, "attribute": "DARK", "race": "Spellcaster"},
	97617181: {"name": "Zubaba Knight", "frame": "effect", "atk": 1600, "def": 900, "level": 3, "attribute": "EARTH", "race": "Warrior"},
	62476815: {"name": "Gogogo Golem", "frame": "effect", "atk": 1800, "def": 1500, "level": 4, "attribute": "EARTH", "race": "Rock"},
	25259669: {"name": "Goblindbergh", "frame": "effect", "atk": 1400, "def": 0, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	84013237: {"name": "Number 39: Utopia", "frame": "xyz", "atk": 2500, "def": 2000, "level": 4, "attribute": "LIGHT", "race": "Warrior"},
	12014404: {"name": "Gagaga Cowboy", "frame": "xyz", "atk": 1500, "def": 2400, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	# ---------------------------------------------------------------- Spells
	55144522: {"name": "Pot of Greed", "frame": "spell", "effect": "draw2", "text": "Draw 2 cards."},
	84257639: {"name": "Dian Keto the Cure Master", "frame": "spell", "effect": "heal1000", "text": "Increase your Life Points by 1000."},
	66788016: {"name": "Fissure", "frame": "spell", "effect": "fissure", "text": "Destroy the 1 face-up monster your opponent controls that has the lowest ATK."},
	24094653: {"name": "Polymerization", "frame": "spell", "effect": "fusion", "text": "Fusion Summon 1 Fusion Monster from your Extra Deck, using monsters from your hand or field as Fusion Material."},
	83764718: {"name": "Monster Reborn", "frame": "spell", "effect": "reborn", "text": "Target 1 monster in either GY; Special Summon it."},
	12580477: {"name": "Raigeki", "frame": "spell", "effect": "raigeki", "text": "Destroy all monsters your opponent controls."},
}

const DECKS := {
	"yugi": {
		"name": "Dark Magician",
		"cards": {46986414: 2, 70781052: 2, 6368038: 2, 28279543: 2, 91152256: 3, 41392891: 2,
			15025844: 2, 13039848: 2, 32452818: 3, 69140098: 2, 66602787: 1, 90357090: 1,
			55144522: 1, 84257639: 1, 66788016: 2, 24094653: 2},
		"extra": {66889139: 2},
	},
	"kaiba": {
		"name": "Blue-Eyes",
		"cards": {89631139: 3, 30113682: 2, 26378150: 2, 14898066: 3, 97590747: 3, 5053103: 3,
			67724379: 2, 24611934: 2, 76184692: 2, 88819587: 1,
			55144522: 1, 66788016: 1, 24094653: 2, 12580477: 1, 83764718: 1, 84257639: 1},
		"extra": {23995346: 1},
	},
	"joey": {
		"name": "Red-Eyes",
		"cards": {74677422: 2, 70781052: 1, 48305365: 3, 14977074: 2, 18246479: 2, 34460851: 2,
			44287299: 3, 49791927: 2, 64428736: 2, 88819587: 2, 76184692: 1,
			24094653: 3, 55144522: 1, 84257639: 2, 66788016: 1, 83764718: 1},
		"extra": {11901678: 1, 45231177: 2, 3366982: 1},
	},
	"jaden": {
		"name": "Elemental HERO",
		"cards": {21844576: 3, 58932615: 3, 84327329: 3, 20721928: 3, 86188410: 3, 79979666: 3,
			57116033: 2, 89943723: 2,
			24094653: 4, 55144522: 1, 84257639: 1, 66788016: 1, 83764718: 1},
		"extra": {35809262: 2, 61204971: 2, 47737087: 1},
	},
	"yusei": {
		"name": "Synchron",
		"cards": {63977008: 3, 96182448: 3, 9365703: 3, 23571046: 3, 59546797: 3, 63142001: 3,
			91152256: 2, 32452818: 2, 76184692: 2,
			55144522: 1, 84257639: 2, 66788016: 2, 83764718: 1},
		"extra": {60800381: 2, 44508094: 1, 51447164: 1},
	},
	"yuma": {
		"name": "Gagaga",
		"cards": {26082117: 3, 97617181: 2, 62476815: 3, 25259669: 3, 91152256: 2, 32452818: 2,
			5053103: 2, 44287299: 2, 76184692: 3, 90357090: 2,
			55144522: 1, 84257639: 2, 66788016: 2, 83764718: 1},
		"extra": {84013237: 2, 12014404: 1},
	},
}


static func get_card(id: int) -> Dictionary:
	var d: Dictionary = CARDS.get(id, {"name": "Unknown", "frame": "normal"}).duplicate()
	d["id"] = id
	d["kind"] = "spell" if d.get("frame", "") == "spell" else "monster"
	return d


static func is_extra(id: int) -> bool:
	return CARDS.get(id, {}).get("frame", "") in ["fusion", "synchro", "xyz"]


static func deck_list(deck_key: String) -> Array[int]:
	return _expand(DECKS[deck_key]["cards"])


static func extra_list(deck_key: String) -> Array[int]:
	return _expand(DECKS[deck_key].get("extra", {}))


static func _expand(cards: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for id in cards:
		for i in cards[id]:
			out.append(int(id))
	return out
