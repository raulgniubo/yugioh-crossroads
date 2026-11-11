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
	53129443: {"name": "Dark Hole", "frame": "spell", "effect": "darkhole", "text": "Destroy all monsters on the field."},
	5318639: {"name": "Mystical Space Typhoon", "frame": "spell", "effect": "mst", "text": "Destroy 1 Spell/Trap on the field."},
	72302403: {"name": "Swords of Revealing Light", "frame": "spell", "effect": "swords", "text": "Flip all monsters your opponent controls face-up. Your opponent's monsters cannot declare an attack for 3 of their turns."},
	# Traps
	44095762: {"name": "Mirror Force", "frame": "trap", "effect": "mirror_force", "text": "When an opponent's monster declares an attack: Destroy all your opponent's Attack Position monsters."},
	62279055: {"name": "Magic Cylinder", "frame": "trap", "effect": "magic_cylinder", "text": "When an opponent's monster declares an attack: Negate the attack, and inflict damage to your opponent equal to its ATK."},
	56120475: {"name": "Sakuretsu Armor", "frame": "trap", "effect": "sakuretsu", "text": "When an opponent's monster declares an attack: Destroy the attacking monster."},
	14315573: {"name": "Negate Attack", "frame": "trap", "effect": "negate_attack", "text": "When an opponent's monster declares an attack: Negate the attack."},
	98427577: {"name": "Scrap-Iron Scarecrow", "frame": "trap", "effect": "negate_attack", "text": "When an opponent's monster declares an attack: Negate the attack."},
	12607053: {"name": "Waboku", "frame": "trap", "effect": "waboku", "text": "You take no battle damage this turn, and your monsters can't be destroyed by battle this turn."},
	4206964: {"name": "Trap Hole", "frame": "trap", "effect": "trap_hole", "text": "When your opponent Normal or Flip Summons a monster with 1000 or more ATK: Destroy that monster."},
	29401950: {"name": "Bottomless Trap Hole", "frame": "trap", "effect": "bottomless", "text": "When your opponent Summons a monster with 1500 or more ATK: Destroy that monster, and banish it."},
	53582587: {"name": "Torrential Tribute", "frame": "trap", "effect": "torrential", "text": "When a monster is Summoned: Destroy all monsters on the field."},
	# Effect monsters with scripted effects
	40640057: {"name": "Kuriboh", "frame": "effect", "atk": 300, "def": 200, "level": 1, "attribute": "DARK", "race": "Fiend", "text": "During damage calculation, if your opponent attacks: Discard this card; you take no battle damage from that battle."},
	26202165: {"name": "Sangan", "frame": "effect", "atk": 1000, "def": 600, "level": 3, "attribute": "DARK", "race": "Fiend", "text": "If this card is sent from the field to the GY: Add 1 monster with 1500 or less ATK from your Deck to your hand."},
	83011277: {"name": "Mystic Tomato", "frame": "effect", "atk": 1400, "def": 1100, "level": 4, "attribute": "DARK", "race": "Plant", "text": "If this card is destroyed by battle: Special Summon 1 DARK monster with 1500 or less ATK from your Deck."},
	70095154: {"name": "Cyber Dragon", "frame": "effect", "atk": 2100, "def": 1600, "level": 5, "attribute": "LIGHT", "race": "Machine", "text": "If only your opponent controls a monster, you can Special Summon this card from your hand."},
	46130346: {"name": "Hinotama", "frame": "spell", "effect": "burn500", "text": "Inflict 500 damage to your opponent."},
}

## Spells the rules engine can play, by name (used for decks built from the card database).
const SPELL_EFFECTS := {
	"Pot of Greed": "draw2", "Dian Keto the Cure Master": "heal1000", "Fissure": "fissure",
	"Polymerization": "fusion", "Monster Reborn": "reborn", "Raigeki": "raigeki",
	"Dark Hole": "darkhole", "Hinotama": "burn500", "Mystical Space Typhoon": "mst",
	"Swords of Revealing Light": "swords", "Mirror Force": "mirror_force", "Magic Cylinder": "magic_cylinder",
	"Sakuretsu Armor": "sakuretsu", "Negate Attack": "negate_attack", "Scrap-Iron Scarecrow": "negate_attack",
	"Waboku": "waboku", "Galaxy Zero": "reborn", "Trap Hole": "trap_hole", "Bottomless Trap Hole": "bottomless", "Torrential Tribute": "torrential",
	"Soul Release": "soul_release", "Dark Core": "dark_core", "Burial from a Different Dimension": "burial_dd",
	"Dimensional Prison": "dim_prison", "D.D.R. - Different Dimension Reincarnation": "dd_return",
}

## Monster effects the engine runs, by card name.
const MONSTER_EFFECTS := {
	"Kuriboh": "Discard during an opponent's attack: no battle damage.",
	"Winged Kuriboh": "Destroyed: no battle damage for the rest of the turn.",
	"Sangan": "Sent from field to GY: add a monster with 1500 or less ATK from Deck.",
	"Mystic Tomato": "Destroyed by battle: Special Summon a DARK monster (1500 or less ATK) from Deck.",
	"Cyber Dragon": "Special Summon from hand if only your opponent controls a monster.",
	"Junk Synchron": "Normal Summoned: Special Summon a Level 2 or lower monster from your GY.",
	"Goblindbergh": "Normal Summoned: Special Summon a Level 4 monster from your hand.",
	"Speed Warrior": "Doubles its ATK during the Battle Phase of the turn it was Normal Summoned.",
	"Max Warrior": "Gains 400 ATK when it attacks.",
	"Zubaba Knight": "Attacking a Defense Position monster: destroy it right away.",
	"Gogogo Golem": "Once per turn, in Defense Position it can't be destroyed by battle.",
	"Number 39: Utopia": "When a monster declares an attack: detach 1 material to negate it.",
	"Elemental HERO Wildheart": "Unaffected by Trap effects.",
}

## Filled from the downloaded card database (tools/fetch_cards.py), if present.
static var EXT := {}
static var NAME_TO_ID := {}

const DECKS := {
	# Story: the player's Echo Deck (early game) and Kairo's deck.
	"echo": {
		"name": "Echo",
		"cards": {91152256: 3, 48305365: 2, 69140098: 2, 14898066: 2, 41392891: 2, 32452818: 2, 15025844: 2,
			28279543: 2, 40640057: 2, 26202165: 1, 70781052: 1,
			55144522: 1, 66788016: 1, 72302403: 1, 62279055: 1, 12607053: 2, 4206964: 1, 84257639: 2},
	},
	"kairo": {
		"name": "Stolen Echo",
		"cards": {74677422: 2, 70781052: 2, 28279543: 2, 97590747: 3, 24611934: 3, 67724379: 2, 14898066: 3,
			41392891: 2, 70095154: 2, 83011277: 2,
			55144522: 1, 12580477: 1, 83764718: 1, 44095762: 1, 56120475: 2, 53582587: 1},
		"extra": {11901678: 1},
	},
	"yugi": {
		"name": "Dark Magician",
		"cards": {46986414: 2, 70781052: 2, 6368038: 2, 28279543: 2, 91152256: 2, 41392891: 1,
			15025844: 1, 13039848: 1, 32452818: 2, 69140098: 2, 40640057: 2, 26202165: 1,
			55144522: 1, 66788016: 1, 24094653: 2, 72302403: 1, 5318639: 1,
			44095762: 1, 62279055: 2, 12607053: 1},
		"extra": {66889139: 2},
	},
	"kaiba": {
		"name": "Blue-Eyes",
		"cards": {89631139: 3, 30113682: 2, 26378150: 2, 14898066: 3, 97590747: 2, 5053103: 2,
			67724379: 1, 24611934: 2, 70095154: 2, 83011277: 1,
			55144522: 1, 66788016: 1, 24094653: 2, 12580477: 1, 83764718: 1,
			4206964: 2, 14315573: 1, 53582587: 1},
		"extra": {23995346: 1},
	},
	"joey": {
		"name": "Red-Eyes",
		"cards": {74677422: 2, 70781052: 1, 48305365: 3, 14977074: 2, 18246479: 2, 34460851: 2,
			44287299: 3, 49791927: 1, 64428736: 2, 88819587: 2,
			24094653: 3, 55144522: 1, 84257639: 1, 83764718: 1,
			12607053: 2, 56120475: 1, 4206964: 1},
		"extra": {11901678: 1, 45231177: 2, 3366982: 1},
	},
	"jaden": {
		"name": "Elemental HERO",
		"cards": {21844576: 3, 58932615: 3, 84327329: 3, 20721928: 3, 86188410: 2, 79979666: 2,
			57116033: 2, 89943723: 2,
			24094653: 4, 55144522: 1, 83764718: 1,
			44095762: 1, 14315573: 2, 56120475: 1},
		"extra": {35809262: 2, 61204971: 2, 47737087: 1},
	},
	"yusei": {
		"name": "Synchron",
		"cards": {63977008: 3, 96182448: 3, 9365703: 3, 23571046: 3, 59546797: 3, 63142001: 3,
			91152256: 2, 32452818: 1,
			55144522: 1, 66788016: 1, 83764718: 1,
			98427577: 3, 56120475: 2, 5318639: 1},
		"extra": {60800381: 2, 44508094: 1, 51447164: 1},
	},
	"yuma": {
		"name": "Gagaga",
		"cards": {26082117: 3, 97617181: 3, 62476815: 3, 25259669: 3, 91152256: 2, 32452818: 2,
			5053103: 2, 44287299: 2, 90357090: 1,
			55144522: 1, 84257639: 1, 66788016: 1, 83764718: 1,
			14315573: 2, 12607053: 2, 4206964: 1},
		"extra": {84013237: 2, 12014404: 1},
	},
}


## Decks for the wider cast, by card name. They need the card database to resolve.
## Effect monsters play as their stats for now.
const NAMED_DECKS := {
	"mai": {"name": "Harpie", "cards": {"Harpie Lady": 3, "Harpie Lady 1": 2, "Harpie Lady 2": 2, "Harpie Lady 3": 2, "Cyber Harpie Lady": 2,
		"Harpie's Pet Dragon": 2, "Harpie Girl": 2, "Harpie Queen": 2, "Birdface": 2, "Harpie Channeler": 2,
		"Pot of Greed": 1, "Dian Keto the Cure Master": 1, "Fissure": 2, "Monster Reborn": 1, "Hinotama": 2}},
	"bakura": {"name": "Dark Fiends", "cards": {"Dark Ruler Ha Des": 2, "Headless Knight": 3, "The Earl of Demise": 2, "Pumpking the King of Ghosts": 2,
		"Summoned Skull": 2, "Ryu-Kishin": 3, "Sangan": 2, "Dark Necrofear": 1, "Gernia": 2, "Lord of the Lamp": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Fissure": 2}},
	"marik": {"name": "Rare Hunter", "cards": {"Gil Garth": 2, "Makyura the Destructor": 2, "Revival Jam": 2, "Drillago": 2, "Vampire Lord": 2,
		"Viser Des": 2, "Mystic Lamp": 2, "Stone Statue of the Aztecs": 2, "Bowganian": 2, "Granadora": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Raigeki": 1, "Hinotama": 2}},
	"pegasus": {"name": "Toon", "cards": {"Toon Summoned Skull": 2, "Toon Dark Magician Girl": 2, "Toon Gemini Elf": 2, "Toon Mermaid": 2,
		"Toon Alligator": 3, "Toon Masked Sorcerer": 2, "Toon Goblin Attack Force": 2, "Bickuribox": 2, "Dragon Piper": 2, "Toon Cannon Soldier": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Raigeki": 1}},
	"weevil": {"name": "Insect", "cards": {"Insect Queen": 2, "Basic Insect": 3, "Hercules Beetle": 2, "Killer Needle": 3, "Petit Moth": 2,
		"Leghul": 2, "Pinch Hopper": 2, "Insect Knight": 3, "Neo Bug": 2, "Gokipon": 2,
		"Pot of Greed": 1, "Fissure": 2, "Monster Reborn": 1, "Dian Keto the Cure Master": 2}},
	"rex": {"name": "Dinosaur", "cards": {"Black Tyranno": 2, "Two-Headed King Rex": 3, "Sword Arm of Dragon": 2, "Megazowler": 3, "Uraby": 3,
		"Crawling Dragon #2": 2, "Gilasaurus": 2, "Mad Sword Beast": 2, "Sabersaurus": 3,
		"Pot of Greed": 1, "Fissure": 2, "Monster Reborn": 1, "Hinotama": 2, "Dian Keto the Cure Master": 1}},
	"chazz": {"name": "Armed Dragon", "cards": {"Armed Dragon LV3": 3, "Armed Dragon LV5": 2, "Armed Dragon LV7": 2, "X-Head Cannon": 3, "Y-Dragon Head": 3,
		"Z-Metal Tank": 3, "Ojama Yellow": 2, "Ojama Green": 1, "Ojama Black": 1,
		"Polymerization": 3, "Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2}, "extra": {"XYZ-Dragon Cannon": 2}},
	"zane": {"name": "Cyber Dragon", "cards": {"Cyber Dragon": 3, "Proto-Cyber Dragon": 3, "Cyber Dragon Zwei": 2, "Cyber Phoenix": 2, "Cyber Larva": 2,
		"Cyber Valley": 2, "Cyber Kirin": 2, "Cyber Eltanin": 1, "Cyber Barrier Dragon": 2,
		"Polymerization": 4, "Pot of Greed": 1, "Monster Reborn": 1, "Raigeki": 1, "Fissure": 2}, "extra": {"Cyber Twin Dragon": 2, "Cyber End Dragon": 1}},
	"alexis": {"name": "Cyber Girl", "cards": {"Cyber Tutu": 3, "Etoile Cyber": 3, "Blade Skater": 3, "Cyber Prima": 2, "Cyber Gymnast": 2,
		"Cyber Petit Angel": 2, "Cyber Angel Benten": 2, "Cyber Angel Idaten": 1, "Cyber Angel Dakini": 1,
		"Polymerization": 3, "Pot of Greed": 1, "Dian Keto the Cure Master": 2, "Fissure": 2, "Monster Reborn": 1}, "extra": {"Cyber Blader": 2}},
	"syrus": {"name": "Roid", "cards": {"Gyroid": 3, "Steamroid": 3, "Drillroid": 2, "Submarineroid": 2, "Truckroid": 2,
		"Expressroid": 2, "Patroid": 2, "Cycroid": 2, "Jetroid": 2, "Rescueroid": 1,
		"Polymerization": 4, "Pot of Greed": 1, "Dian Keto the Cure Master": 2, "Fissure": 1, "Monster Reborn": 1}, "extra": {"Steam Gyroid": 2, "Super Vehicroid Jumbo Drill": 1}},
	"aster": {"name": "Destiny HERO", "cards": {"Destiny HERO - Diamond Dude": 3, "Destiny HERO - Doom Lord": 2, "Destiny HERO - Dasher": 2,
		"Destiny HERO - Defender": 2, "Destiny HERO - Captain Tenacious": 2, "Destiny HERO - Malicious": 3, "Destiny HERO - Doublecross": 2,
		"Destiny HERO - Dunker": 2, "Destiny HERO - Disk Commander": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Fissure": 2, "Raigeki": 1}},
	"jack": {"name": "Resonator", "cards": {"Dark Resonator": 3, "Barrier Resonator": 2, "Mad Archfiend": 3, "Twin-Sword Marauder": 3,
		"Big Piece Golem": 2, "Medium Piece Golem": 2, "Vice Dragon": 2, "Snipe Hunter": 2, "Battle Fader": 1, "Sinister Sprocket": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Raigeki": 1}, "extra": {"Red Dragon Archfiend": 2, "Exploder Dragonwing": 1}},
	"crow": {"name": "Blackwing", "cards": {"Blackwing - Bora the Spear": 3, "Blackwing - Gale the Whirlwind": 3, "Blackwing - Sirocco the Dawn": 2,
		"Blackwing - Blizzard the Far North": 3, "Blackwing - Kalut the Moon Shadow": 2, "Blackwing - Shura the Blue Flame": 2,
		"Blackwing - Elphin the Raven": 2, "Blackwing - Fane the Steel Chain": 2, "Blackwing - Vayu the Emblem of Honor": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Dian Keto the Cure Master": 1}, "extra": {"Blackwing Armor Master": 2, "Blackwing Armed Wing": 1}},
	"akiza": {"name": "Rose", "cards": {"Twilight Rose Knight": 3, "Lord Poison": 2, "Copy Plant": 2, "Revival Rose": 2, "Dark Verger": 3,
		"Botanical Lion": 2, "Evil Thorn": 2, "Phoenixian Seed": 2, "Rose Tentacles": 2, "Lonefire Blossom": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Dark Hole": 1}, "extra": {"Black Rose Dragon": 2, "Splendid Rose": 1}},
	"kalin": {"name": "Infernity", "cards": {"Infernity Necromancer": 3, "Infernity Archfiend": 3, "Infernity Beast": 3, "Infernity Avenger": 3,
		"Infernity Mirage": 2, "Infernity Dwarf": 2, "Infernity Guardian": 2, "Infernity Knight": 2, "Stygian Street Patrol": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Dark Hole": 1, "Fissure": 2, "Hinotama": 3}, "extra": {"Infernity Doom Dragon": 1}},
	"shark": {"name": "Shark", "cards": {"Big Jaws": 3, "Shark Stickers": 3, "Hammer Shark": 2, "Spear Shark": 2, "Double Shark": 2,
		"Eagle Shark": 2, "Cat Shark": 2, "Skull Kraken": 2, "Saber Shark": 2, "Sharkraken": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Dian Keto the Cure Master": 1}, "extra": {"Number 17: Leviathan Dragon": 2, "Black Ray Lancer": 1, "Number 32: Shark Drake": 1}},
	"kite": {"name": "Photon", "cards": {"Galaxy-Eyes Photon Dragon": 3, "Photon Thrasher": 3, "Photon Crusher": 3, "Photon Lizard": 2,
		"Photon Sabre Tiger": 3, "Galaxy Knight": 2, "Photon Cerberus": 2, "Galaxy Soldier": 2, "Photon Leo": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Raigeki": 1, "Fissure": 2}, "extra": {"Number 62: Galaxy-Eyes Prime Photon Dragon": 1, "Starliege Paladynamo": 2}},
	"vector": {"name": "Umbral Horror", "cards": {"Umbral Horror Ghoul": 3, "Umbral Horror Unform": 3, "Umbral Horror Will o' the Wisp": 3,
		"Umbral Horror Ghost": 3, "Archfiend Soldier": 3, "Summoned Skull": 2, "Ryu-Kishin Powered": 3, "Vorse Raider": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Fissure": 2, "Hinotama": 3}, "extra": {"Number 43: Manipulator of Souls": 1, "Number 65: Djinn Buster": 2}},
}


static func get_card(id: int) -> Dictionary:
	var d: Dictionary
	if not CARDS.has(id) and EXT.has(id):
		d = EXT[id].duplicate()
	else:
		d = CARDS.get(id, {"name": "Unknown", "frame": "normal"}).duplicate()
	d["id"] = id
	var frame: String = d.get("frame", "")
	d["kind"] = "trap" if frame == "trap" else ("spell" if frame == "spell" else "monster")
	return d


static func is_extra(id: int) -> bool:
	return get_card(id).get("frame", "") in ["fusion", "synchro", "xyz"]


static func has_deck(deck_key: String) -> bool:
	if DECKS.has(deck_key):
		return true
	return NAMED_DECKS.has(deck_key) and deck_list(deck_key).size() >= 20


static func deck_name(deck_key: String) -> String:
	if DECKS.has(deck_key):
		return DECKS[deck_key]["name"]
	return NAMED_DECKS.get(deck_key, {}).get("name", "?")


static func deck_list(deck_key: String) -> Array[int]:
	if DECKS.has(deck_key):
		return _expand(DECKS[deck_key]["cards"])
	return _fill_to_30(_resolve(NAMED_DECKS.get(deck_key, {}).get("cards", {}), false))


static func extra_list(deck_key: String) -> Array[int]:
	if DECKS.has(deck_key):
		return _expand(DECKS[deck_key].get("extra", {}))
	return _expand(_resolve(NAMED_DECKS.get(deck_key, {}).get("extra", {}), true))


## Card names -> ids via the database. Unknown or unsupported cards are dropped.
static func _resolve(names: Dictionary, extra: bool) -> Dictionary:
	var out := {}
	for n in names:
		if names[n] <= 0:
			continue
		var id: int = NAME_TO_ID.get(str(n).to_lower(), 0)
		if id == 0:
			continue
		var d := get_card(id)
		if d["kind"] != "monster" and not d.has("effect"):
			continue
		if (d.get("frame", "") in ["fusion", "synchro", "xyz"]) != extra:
			continue
		if d.get("frame", "") in ["ritual", "link"]:
			continue
		out[id] = names[n]
	return out


## Keep the deck at 30 by adding copies of its best monsters (max 3 each).
static func _fill_to_30(counts: Dictionary) -> Array[int]:
	var ids := counts.keys()
	ids.sort_custom(func(a, b): return get_card(a).get("atk", 0) > get_card(b).get("atk", 0))
	var total := 0
	for id in counts:
		total += counts[id]
	for id in ids:
		while total < 30 and counts[id] < 3 and get_card(id)["kind"] == "monster" and get_card(id).get("level", 4) <= 4:
			counts[id] += 1
			total += 1
	return _expand(counts)


## Load the downloaded card database. A compact index is cached in user:// so
## later launches don't parse the full file again.
static func load_external(folder: String) -> void:
	EXT.clear()
	NAME_TO_ID.clear()
	var src := folder.path_join("cards.json")
	if not FileAccess.file_exists(src):
		return
	var cache := "user://card_index.json"
	var stamp := str(FileAccess.get_modified_time(src))
	if FileAccess.file_exists(cache):
		var c = JSON.parse_string(FileAccess.get_file_as_string(cache))
		if typeof(c) == TYPE_DICTIONARY and c.get("stamp", "") == stamp:
			for k in c["cards"]:
				var d: Dictionary = c["cards"][k]
				EXT[int(k)] = d
				NAME_TO_ID[str(d["name"]).to_lower()] = int(k)
			return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(src))
	if typeof(parsed) != TYPE_ARRAY:
		return
	var compact := {}
	for raw in parsed:
		if typeof(raw) != TYPE_DICTIONARY or not raw.has("id"):
			continue
		var d := _from_db(raw)
		if d.is_empty():
			continue
		var id := int(raw["id"])
		EXT[id] = d
		compact[str(id)] = d
		NAME_TO_ID[str(d["name"]).to_lower()] = id
	var f := FileAccess.open(cache, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"stamp": stamp, "cards": compact}))


static func _from_db(raw: Dictionary) -> Dictionary:
	var name := str(raw.get("name", ""))
	var frame := str(raw.get("frameType", "normal"))
	if frame.begins_with("effect"):
		frame = "effect"
	elif frame.begins_with("normal"):
		frame = "normal"
	var d := {"name": name, "frame": frame, "desc": str(raw.get("desc", ""))}
	if frame == "spell" or frame == "trap":
		if SPELL_EFFECTS.has(name):
			d["effect"] = SPELL_EFFECTS[name]
			d["text"] = d["desc"]
		return d
	d["atk"] = int(raw.get("atk", 0))
	d["def"] = int(raw.get("def", 0))
	d["level"] = int(raw.get("level", raw.get("linkval", 0)))
	d["attribute"] = str(raw.get("attribute", ""))
	d["race"] = str(raw.get("race", ""))
	if "Tuner" in str(raw.get("type", "")):
		d["tuner"] = true
	if frame == "fusion":
		var first: String = str(d["desc"]).split("\n")[0]
		var mats := []
		var parts: PackedStringArray = first.split("\"")
		for i in range(1, parts.size(), 2):
			mats.append(parts[i])
		if "+" in first and mats.size() >= 2:
			d["material_names"] = mats
	return d


static func fusion_materials(card: Dictionary) -> Array:
	if card.has("materials"):
		return card["materials"]
	var out := []
	for n in card.get("material_names", []):
		var id: int = NAME_TO_ID.get(str(n).to_lower(), 0)
		if id == 0:
			return []
		out.append(id)
	return out


static func _expand(cards: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for id in cards:
		for i in cards[id]:
			out.append(int(id))
	return out



## Hard mode: the opponent brings a tuned "Legend" version of their deck.
## The 6 weakest monsters are swapped for extra copies of their best ones
## (max 3 per card), plus Pot of Greed and Monster Reborn if missing.
static func legend_deck(deck_key: String) -> Array[int]:
	if not DECKS.has(deck_key):
		return deck_list(deck_key)
	var counts: Dictionary = DECKS[deck_key]["cards"].duplicate()
	var monsters := []
	for id in counts:
		if not (CARDS.get(id, {}).get("frame", "") in ["spell", "trap"]):
			monsters.append(id)
	monsters.sort_custom(func(a, b): return CARDS[a].get("atk", 0) < CARDS[b].get("atk", 0))
	var removed := 0
	for id in monsters:
		while removed < 6 and counts[id] > 0 and CARDS[id].get("level", 4) <= 4:
			counts[id] -= 1
			removed += 1
	var strong := monsters.duplicate()
	strong.reverse()
	var added := 0
	for want in [55144522, 83764718]:
		if counts.get(want, 0) == 0 and added < removed:
			counts[want] = 1
			added += 1
	for id in strong:
		while added < removed and counts[id] < 3:
			counts[id] += 1
			added += 1
	return _expand(counts)
