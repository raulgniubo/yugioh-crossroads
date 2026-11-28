class_name CardData
extends RefCounted
## Static card data and character decks. Used by the rules (no textures here).
##
## frame: normal | effect | fusion | synchro | xyz | spell
## Effect monsters are played as vanilla stats for now (effects come with the full rules engine).

const CARDS := {
	99100001: {"name": "Speed Spell - Full Throttle", "frame": "spell", "text": "Gain 2 Speed Counters.", "speed_spell": true},
	99100002: {"name": "Speed Spell - Tailwind", "frame": "spell", "text": "Needs 2 Speed Counters. Draw 1 card.", "speed_spell": true},
	99100003: {"name": "Speed Spell - Pit Stop", "frame": "spell", "text": "Needs 2 Speed Counters. Gain 1200 Life Points.", "speed_spell": true},
	99100004: {"name": "Speed Spell - Slipstream Strike", "frame": "spell", "text": "Needs 3 Speed Counters. Target 1 face-up monster: it gains 800 ATK until the end of this turn.", "speed_spell": true},
	99100005: {"name": "Speed Spell - Twin Turbo", "frame": "spell", "text": "Needs 4 Speed Counters. Draw 2 cards, then discard 1 card.", "speed_spell": true},
	99100006: {"name": "Speed Spell - Afterburner", "frame": "spell", "text": "Needs 4 Speed Counters. Inflict 800 damage to your opponent.", "speed_spell": true},
	99100007: {"name": "Speed Spell - Road Clear", "frame": "spell", "text": "Needs 5 Speed Counters. Destroy 1 Spell or Trap on the field.", "speed_spell": true},
	99100008: {"name": "Speed Spell - Overtake", "frame": "spell", "text": "Needs 6 Speed Counters. Spend 3 Speed Counters: destroy the monster your opponent controls with the highest DEF.", "speed_spell": true},
	99100009: {"name": "Speed Spell - Redline", "frame": "spell", "text": "Needs 8 Speed Counters. Spend 6 Speed Counters: inflict 2000 damage to your opponent.", "speed_spell": true},
	99100010: {"name": "Speed Spell - Shockwave", "frame": "spell", "text": "Needs 7 Speed Counters. Spend 4 Speed Counters: destroy every Spell and Trap your opponent controls.", "speed_spell": true},
	# (0.74.1) Twelve more, so every Turbo Duel draws a different hand of them.
	99100011: {"name": "Speed Spell - Green Light", "frame": "spell", "text": "Needs 1 Speed Counter. Draw 1 card, then gain 1 Speed Counter.", "speed_spell": true},
	99100012: {"name": "Speed Spell - Drift Guard", "frame": "spell", "text": "Needs 3 Speed Counters. Target 1 face-up monster you control: it cannot be destroyed by battle this turn.", "speed_spell": true},
	99100013: {"name": "Speed Spell - Pace Car", "frame": "spell", "text": "Needs 2 Speed Counters. Target 1 face-up monster your opponent controls: it loses 600 ATK until the end of this turn.", "speed_spell": true},
	99100014: {"name": "Speed Spell - Pit Crew", "frame": "spell", "text": "Needs 3 Speed Counters. Add 1 monster from your Graveyard to your hand.", "speed_spell": true},
	99100015: {"name": "Speed Spell - Fuel Line", "frame": "spell", "text": "Needs 5 Speed Counters. Gain 1000 Life Points, then draw 1 card.", "speed_spell": true},
	99100016: {"name": "Speed Spell - Jump Start", "frame": "spell", "text": "Needs 4 Speed Counters. Special Summon 1 Level 4 or lower monster from your Graveyard in Defense Position.", "speed_spell": true},
	99100017: {"name": "Speed Spell - Brake Check", "frame": "spell", "text": "Needs 4 Speed Counters. Target 1 face-up Attack Position monster your opponent controls: change it to Defense Position.", "speed_spell": true},
	99100018: {"name": "Speed Spell - Rev Limiter", "frame": "spell", "text": "Needs 6 Speed Counters. Spend 2 Speed Counters: your opponent loses 4 Speed Counters.", "speed_spell": true},
	99100019: {"name": "Speed Spell - Final Lap", "frame": "spell", "text": "Needs 9 Speed Counters. Spend 5 Speed Counters: every face-up monster you control gains 1000 ATK until the end of this turn.", "speed_spell": true},
	99100020: {"name": "Speed Spell - Double Lap", "frame": "spell", "text": "Needs 7 Speed Counters. Spend 3 Speed Counters: target 1 face-up monster you control; it can make a second attack during each Battle Phase this turn.", "speed_spell": true},
	99100021: {"name": "Speed Spell - Spin Out", "frame": "spell", "text": "Needs 5 Speed Counters. Spend 2 Speed Counters: target 1 monster your opponent controls; return it to the hand.", "speed_spell": true},
	99100022: {"name": "Speed Spell - Chequered Flag", "frame": "spell", "text": "Needs 10 Speed Counters. Spend 8 Speed Counters: draw 2 cards, then inflict 1000 damage to your opponent.", "speed_spell": true},
	# Your partner. She is in your deck from the first day (every starter has her) and grows with every bond.
	99200001: {"name": "Lumen, Echo Spirit", "frame": "effect", "atk": 500, "def": 500, "level": 2, "attribute": "LIGHT", "race": "Fairy", "partner": true,
		"text": "Normal Summoned: add 1 monster with 1500 or less ATK from your Deck to your hand. Destroyed by battle: you take no battle damage this turn. Gains 300 ATK and DEF for every bond you have made."},
	# Her forms, one from each world, and the cards around her. All of them are cards of this
	# game (see ORIGINALS): nothing here exists outside it, so their text is whatever we print.
	99200002: {"name": "Lumen, Echo Chorus", "frame": "fusion", "atk": 2300, "def": 2000, "level": 6, "attribute": "LIGHT", "race": "Fairy", "materials": [99200001, 0],
		"text": "\"Lumen, Echo Spirit\" + 1 monster\nFusion Summoned: draw 1 card. Once per turn, it is not destroyed by battle. Sent from the field to the Graveyard: Special Summon 1 \"Lumen, Echo Spirit\" from your Graveyard in Defense Position."},
	99200003: {"name": "Lumen, Echo Comet", "frame": "synchro", "atk": 2400, "def": 1800, "level": 6, "attribute": "LIGHT", "race": "Fairy",
		"text": "\"Lumen, Echo Spirit\" + 1 or more non-Tuner monsters\nSynchro Summoned: destroy 1 card your opponent controls. Piercing battle damage."},
	99200004: {"name": "Lumen, Echo Zenith", "frame": "xyz", "atk": 2500, "def": 2000, "level": 4, "attribute": "LIGHT", "race": "Fairy",
		"text": "2 Level 4 monsters\n1 \"Lumen, Echo Spirit\" you control can be used as a Level 4 material for this card. Once per turn: detach 1 material; Special Summon 1 \"Lumen\" monster from your Graveyard."},
	99200005: {"name": "Lumen, Echo Radiant", "frame": "effect", "atk": 3000, "def": 2500, "level": 8, "attribute": "LIGHT", "race": "Fairy",
		"text": "Cannot be Normal Summoned or Set. Must be Special Summoned by \"Echo Resonance\". When it is: destroy 1 card your opponent controls. Once per turn, it is not destroyed by battle. Destroys a monster by battle: gain 1000 Life Points."},
	99200011: {"name": "Echo Resonance", "frame": "spell",
		"text": "Tribute 1 \"Lumen, Echo Spirit\" you control that was not Summoned this turn (any, if your Life Points are 2000 or less): Special Summon 1 \"Lumen, Echo Radiant\" from your hand or Deck."},
	99200012: {"name": "Echo Call", "frame": "spell", "text": "Add 1 \"Echo\" monster from your Deck to your hand."},
	99200013: {"name": "Echo Veil", "frame": "trap", "text": "When an opponent's monster declares an attack: negate the attack. Then, if you control a \"Lumen\" monster, draw 1 card."},
	# (0.81.0) Two more forms of her, and the cards for a deck built around her. Every one of them is an
	# "Echo" card and her forms are "Lumen" monsters: the rules engine knows them by set code
	# (OcgCore.SET_LUMEN / SET_ECHO), so a card that says "Lumen" or "Echo" means these and no other.
	99200006: {"name": "Lumen, Echo Aurora", "frame": "ritual", "atk": 2800, "def": 2600, "level": 8, "attribute": "LIGHT", "race": "Fairy",
		"text": "You can Ritual Summon this card with \"Echo Dawn Rite\". Unaffected by your opponent's Spell effects. Once per turn, when your opponent activates a card or effect (Quick Effect): you can negate the activation."},
	99200007: {"name": "Lumen, Echo Nova", "frame": "fusion", "atk": 2800, "def": 2800, "level": 10, "attribute": "LIGHT", "race": "Fairy",
		"text": "1 \"Lumen\" monster + 1 Fusion, Synchro or Xyz Monster\nGains 400 ATK for each kind of monster in your Graveyard among Ritual, Fusion, Synchro and Xyz. Fusion Summoned: you can target up to that many cards your opponent controls; destroy them."},
	99200014: {"name": "Echo Dawn Rite", "frame": "spell", "race": "Ritual", "st": "ritual",
		"text": "This card is used to Ritual Summon \"Lumen, Echo Aurora\". You must also Tribute monsters from your hand or field whose total Levels equal 8 or more. \"Lumen, Echo Spirit\" can be the entire Tribute."},
	99200015: {"name": "Echo Bond", "frame": "spell", "race": "Continuous", "st": "continuous",
		"text": "\"Lumen\" monsters you control gain 300 ATK, and 100 more for every bond you have made. Once per turn, if a \"Lumen\" monster you control is destroyed: you can return it to your hand (or Extra Deck)."},
	99200016: {"name": "Hall of Echoes", "frame": "spell", "race": "Field", "st": "field",
		"text": "LIGHT Fairy monsters you control gain 300 ATK. During your Main Phase, you can Normal Summon 1 \"Lumen\" monster in addition to your Normal Summon/Set. During your End Phase, if you control a \"Lumen\" monster: gain 500 Life Points."},
	99200017: {"name": "Echo Merge", "frame": "spell",
		"text": "Fusion Summon 1 \"Lumen\" Fusion Monster from your Extra Deck, using monsters from your hand or field as material. If you use a \"Lumen, Echo Spirit\" you control as material, you can also use 1 monster from your Deck."},
	99200018: {"name": "Echo Memory", "frame": "spell", "race": "Quick-Play", "st": "quick-play",
		"text": "Target up to 3 \"Echo\" cards in your Graveyard: shuffle them into the Deck, then draw 1 card. You can only activate 1 \"Echo Memory\" per turn."},
	99200019: {"name": "Echo Return", "frame": "trap",
		"text": "When a \"Lumen\" monster you control is destroyed: Special Summon 1 \"Lumen\" monster with a different name from your Graveyard."},
	99200020: {"name": "Echo Silence", "frame": "trap", "race": "Counter", "st": "counter",
		"text": "If you control a \"Lumen\" monster, when your opponent activates a Spell/Trap Card: negate the activation, and if you do, destroy it."},
	99200021: {"name": "Echo Wisp", "frame": "effect", "atk": 300, "def": 300, "level": 1, "attribute": "LIGHT", "race": "Fairy",
		"text": "If you control a \"Lumen\" monster: you can Special Summon this card from your hand. If this card is used as material for the Summon of a \"Lumen\" monster: draw 1 card. You can only use each effect of \"Echo Wisp\" once per turn."},
	99200022: {"name": "Echo Lantern Keeper", "frame": "effect", "atk": 1600, "def": 1200, "level": 4, "attribute": "LIGHT", "race": "Fairy",
		"text": "Normal Summoned: add 1 \"Echo\" Spell or Trap from your Deck to your hand. You can only use this effect of \"Echo Lantern Keeper\" once per turn."},
	99200023: {"name": "Echo Twin", "frame": "effect", "atk": 1400, "def": 1800, "level": 4, "attribute": "LIGHT", "race": "Fairy",
		"text": "When \"Lumen, Echo Spirit\" is Normal or Special Summoned to your field: you can Special Summon this card from your hand or Graveyard (if from the Graveyard, banish it when it leaves the field). You can only use this effect of \"Echo Twin\" once per turn."},
	99200024: {"name": "Echo Messenger", "frame": "effect", "atk": 1200, "def": 1000, "level": 3, "attribute": "LIGHT", "race": "Fairy",
		"text": "If this card is sent to the Graveyard: you can add 1 \"Lumen, Echo Spirit\" from your Graveyard to your hand. You can only use this effect of \"Echo Messenger\" once per turn."},
	99200025: {"name": "Echo Sentinel", "frame": "effect", "atk": 2100, "def": 2400, "level": 6, "attribute": "LIGHT", "race": "Fairy",
		"text": "You can Special Summon this card (from your hand) by Tributing 1 \"Echo\" monster. Your opponent cannot target \"Lumen\" monsters you control with card effects."},
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
	95360850: {"name": "Shield Warrior", "frame": "effect", "atk": 800, "def": 1600, "level": 3, "attribute": "EARTH", "race": "Warrior"},
	94538053: {"name": "Max Warrior", "frame": "effect", "atk": 1800, "def": 800, "level": 4, "attribute": "EARTH", "race": "Warrior"},
	60800381: {"name": "Junk Warrior", "frame": "synchro", "atk": 2300, "def": 1300, "level": 5, "attribute": "DARK", "race": "Warrior"},
	44508094: {"name": "Stardust Dragon", "frame": "synchro", "atk": 2500, "def": 2000, "level": 8, "attribute": "WIND", "race": "Dragon"},
	18013090: {"name": "Nitro Warrior", "frame": "synchro", "atk": 2800, "def": 1800, "level": 7, "attribute": "FIRE", "race": "Warrior"},
	# ---------------------------------------------------------------- Yuma
	26082117: {"name": "Gagaga Magician", "frame": "effect", "atk": 1500, "def": 1000, "level": 4, "attribute": "DARK", "race": "Spellcaster"},
	97896503: {"name": "Zubaba Knight", "frame": "effect", "atk": 1600, "def": 900, "level": 3, "attribute": "EARTH", "race": "Warrior"},
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
	"Polymerization": "fusion", "Power Bond": "fusion", "Monster Reborn": "reborn", "Raigeki": "raigeki",
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
const MIN_DECK := 40
## The cards made for this game, with their place in the Crossroads set (CR-001 ...). They
## carry the Crossroads mark on their face and in every card list.
const ORIGINALS := [99200001, 99200002, 99200003, 99200004, 99200005, 99200011, 99200012, 99200013,
	99100001, 99100002, 99100003, 99100004, 99100005, 99100006, 99100007, 99100008, 99100009, 99100010,
	99100011, 99100012, 99100013, 99100014, 99100015, 99100016, 99100017, 99100018, 99100019, 99100020, 99100021, 99100022,
	99200006, 99200007, 99200014, 99200015, 99200016, 99200017, 99200018, 99200019, 99200020, 99200021, 99200022, 99200023, 99200024, 99200025]
## Every card of Lumen's, her forms first (the album, the deck editor and the card finder list these).
const LUMEN_CARDS := [99200001, 99200002, 99200003, 99200004, 99200005, 99200006, 99200007,
	99200011, 99200012, 99200013, 99200014, 99200015, 99200016, 99200017, 99200018, 99200019, 99200020,
	99200021, 99200022, 99200023, 99200024, 99200025]
## Her forms: "Lumen" monsters to the rules (the rest of LUMEN_CARDS are "Echo" cards only).
const LUMEN_FORMS := [99200001, 99200002, 99200003, 99200004, 99200005, 99200006, 99200007]
## The cards around her that the Echo Pack holds from the first day (0.81.0): nothing of the story
## is given away by them. Her forms and the cards that call them still come with the story.
const ECHO_SUPPORT := [99200021, 99200022, 99200023, 99200024, 99200025, 99200015, 99200016, 99200017, 99200018, 99200019, 99200020]
## Lumen's cards, and the story stage (see StoryProgress.stage) that hands each one over:
## [stage, id, copies]. Stage 1 is the prologue done, 2 Domino, 3 the Academy, 4 the 5D's
## worlds, 5 Heartland.
const LUMEN_GIFTS := [[1, 99200012, 2], [1, 99200013, 2], [2, 99200011, 2], [2, 99200005, 1], [3, 99200002, 1], [4, 99200003, 1], [5, 99200004, 1],
	[3, 99200006, 1], [3, 99200014, 2], [5, 99200007, 1]]
const LUMEN_TUNER_STAGE := 4


static func is_original(id: int) -> bool:
	return ORIGINALS.has(id)


## "CR-007": a card's number in the Crossroads set ("" for any other card).
static func set_code(id: int) -> String:
	var i := ORIGINALS.find(id)
	return "" if i == -1 else "CR-%03d" % (i + 1)


## Four cards carried the wrong number until 0.33.19, so the game showed another card's picture
## and text under their name (Max Warrior with Batteryman AA's face). Old number -> right one;
## saves are moved over when they are read.
const RENUMBERED := {59546797: 95360850, 63142001: 94538053, 51447164: 18013090, 97617181: 97896503}


## Lumen, your partner spirit, as a card.
const LUMEN := 99200001
## The Speed Spells every rider carries in a Turbo Duel.
const SPEED_SPELLS := [99100001, 99100002, 99100003, 99100004, 99100005, 99100006, 99100007, 99100008, 99100009, 99100010,
	99100011, 99100012, 99100013, 99100014, 99100015, 99100016, 99100017, 99100018, 99100019, 99100020, 99100021, 99100022]

static var EXT := {}
## Tokens made during a duel (Sheep Tokens...): id -> card data. Not real cards, never in a deck.
static var TOKENS := {}
static var NAME_TO_ID := {}

const DECKS := {
	# Story: the player's Echo Deck (early game) and Kairo's deck.
	"echo": {
		"name": "Lumen's Deck",
		# Lumen and the Echo cards she has by the time she hands it over (after Domino), around
		# the classics she grew up beside. Her later forms join through the story, not here.
		"cards": {99200001: 1, 99200012: 2, 99200013: 2, 99200011: 2, 99200005: 1,
			91152256: 2, 48305365: 2, 69140098: 2, 14898066: 2, 41392891: 2, 32452818: 2, 15025844: 2,
			28279543: 2, 40640057: 2, 70781052: 1,
			55144522: 1, 66788016: 1, 12607053: 1, 84257639: 1},
	},
	# (0.81.0) Two bigger decks of hers, sold beside the first one in the deck shops: the Echo
	# monsters and the cards around her, then every form she has.
	"echo_2": {
		"name": "Lumen's Echoes",
		"cards": {99200001: 3, 99200021: 3, 99200022: 3, 99200023: 3, 99200024: 2, 99200025: 2, 99200005: 1, 95956346: 2, 37742478: 1,
			99200012: 3, 99200011: 2, 99200015: 2, 99200016: 2, 99200018: 2, 55144522: 1,
			99200013: 3, 99200019: 2, 99200020: 2, 97077563: 1},
	},
	"echo_3": {
		"name": "Lumen's Dawn",
		"cards": {99200001: 3, 99200021: 3, 99200022: 3, 99200023: 3, 99200024: 2, 99200025: 2, 99200005: 1, 99200006: 2, 37742478: 1,
			99200012: 3, 99200011: 1, 99200014: 2, 99200017: 2, 99200015: 1, 99200016: 2, 99200018: 2,
			99200013: 2, 99200019: 2, 99200020: 2, 97077563: 1},
		"extra": {99200002: 2, 99200003: 2, 99200004: 2, 99200007: 1},
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
		"cards": {63977008: 3, 96182448: 3, 9365703: 3, 23571046: 3, 95360850: 3, 94538053: 3,
			91152256: 2, 32452818: 1,
			55144522: 1, 66788016: 1, 83764718: 1,
			98427577: 3, 56120475: 2, 5318639: 1},
		"extra": {60800381: 2, 44508094: 1, 18013090: 1},
	},
	"yuma": {
		"name": "Gagaga",
		"cards": {26082117: 3, 97896503: 3, 62476815: 3, 25259669: 3, 91152256: 2, 32452818: 2,
			5053103: 2, 44287299: 2, 90357090: 1,
			55144522: 1, 84257639: 1, 66788016: 1, 83764718: 1,
			14315573: 2, 12607053: 2, 4206964: 1},
		"extra": {84013237: 2, 12014404: 1},
	},
}


## Decks for the wider cast, by card name. They need the card database to resolve.
## Effect monsters play as their stats for now.
const NAMED_DECKS := {
	# The three decks a new duelist picks from (see Collection.STARTERS): the same strength, three
	# ways to play. Forty cards each, your partner Lumen in every one, nothing rare, no card
	# without its full printed effect.
	"starter_warrior": {"name": "First Blade", "ids": {99200001: 1}, "cards": {"Celtic Guardian": 2, "Axe Raider": 2, "Warrior Dai Grepher": 2, "Dark Blade": 2, "Gene-Warped Warwolf": 1,
		"Hayabusa Knight": 2, "Goblin Attack Force": 1, "Twin-Sword Marauder": 1, "Freed the Brave Wanderer": 1, "Exiled Force": 1, "D.D. Warrior Lady": 1,
		"Goblindbergh": 1, "Max Warrior": 1, "Shield Warrior": 1, "Airknight Parshath": 1,
		"Reinforcement of the Army": 1, "The Warrior Returning Alive": 1, "Lightning Blade": 1, "Axe of Despair": 1, "Legendary Sword": 1, "Rush Recklessly": 2, "Smashing Ground": 1, "Fissure": 1,
		"Swords of Revealing Light": 1, "Sogen": 1,
		"Sakuretsu Armor": 1, "Trap Hole": 2, "Waboku": 2, "Enchanted Javelin": 1, "Threatening Roar": 1, "Magic Cylinder": 1}},
	"starter_arcane": {"name": "First Spell", "ids": {99200001: 1}, "cards": {"Gemini Elf": 3, "Neo the Magic Swordsman": 2, "Mystical Elf": 2, "Gagaga Magician": 2,
		"Old Vindictive Magician": 2, "Magician of Faith": 2, "Breaker the Magical Warrior": 1, "Man-Eater Bug": 1, "Sangan": 1, "Kuriboh": 1,
		"La Jinn the Mystical Genie of the Lamp": 1, "Dark Magician Girl": 1, "Dark Magician": 1,
		"Book of Moon": 1, "Swords of Revealing Light": 1, "Remove Trap": 1, "Dian Keto the Cure Master": 1, "Mage Power": 1, "Book of Secret Arts": 2, "Yami": 1, "Fissure": 1,
		"Lightning Vortex": 1, "Hinotama": 1,
		"Spellbinding Circle": 2, "Magic Cylinder": 1, "Shadow Spell": 1, "Magic Jammer": 1, "Waboku": 2, "Trap Hole": 1}},
	"starter_dragon": {"name": "First Flame", "ids": {99200001: 1}, "cards": {"Luster Dragon": 2, "Alexandrite Dragon": 1, "Spear Dragon": 2, "Axe Dragonute": 1,
		"Koumori Dragon": 2, "Blackland Fire Dragon": 2, "Baby Dragon": 2, "Masked Dragon": 2, "Troop Dragon": 2, "Luster Dragon #2": 2, "Curse of Dragon": 1, "Tri-Horned Dragon": 1,
		"Mountain": 2, "Dragon Treasure": 1, "Rush Recklessly": 2, "Stop Defense": 1, "Dian Keto the Cure Master": 1, "Hammer Shot": 1, "Big Bang Shot": 1, "Swords of Revealing Light": 1, "Fissure": 1,
		"Sakuretsu Armor": 1, "Trap Hole": 2, "Waboku": 2, "Negate Attack": 1, "Enchanted Javelin": 1, "Threatening Roar": 1}},
	# Story bosses.
	"curator": {"name": "The Collection", "cards": {"Blue-Eyes White Dragon": 2, "Dark Magician": 2, "Red-Eyes Black Dragon": 1, "Summoned Skull": 2, "Elemental HERO Neos": 2, "Cyber Dragon": 2, "Zaborg the Thunder Monarch": 1, "Vorse Raider": 2, "Gemini Elf": 2, "La Jinn the Mystical Genie of the Lamp": 2, "Luster Dragon": 2, "Mystic Tomato": 1, "Sangan": 1, "Man-Eater Bug": 1, "Shining Angel": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Raigeki": 1, "Mystical Space Typhoon": 1, "Swords of Revealing Light": 1, "Fissure": 2, "Spellbinding Circle": 1, "Impenetrable Attack": 1, "Quaking Mirror Force": 1, "Divine Wrath": 1, "Chain Disappearance": 1, "Draining Shield": 1, "Scrap-Iron Scarecrow": 1}},
	"vellum": {"name": "The Catalogue", "cards": {"Dark Magician": 2, "Dark Magician Girl": 1, "Kycoo the Ghost Destroyer": 2, "Breaker the Magical Warrior": 1, "Magician of Faith": 2, "Old Vindictive Magician": 2, "Apprentice Magician": 2, "Man-Eater Bug": 2, "Gemini Elf": 3, "Summoned Skull": 2, "Sangan": 1, "Mystic Tomato": 2, "Exiled Force": 1, "Airknight Parshath": 1, "Fissure": 2, "Magic Cylinder": 1, "Sakuretsu Armor": 1, "Negate Attack": 1, "Bottomless Trap Hole": 1, "Waboku": 1, "Drowning Mirror Force": 1, "Ego Boost": 1, "Rising Energy": 1, "Forbidden Chalice": 1, "Seven Tools of the Bandit": 1, "Offerings to the Doomed": 1, "Spell Shield Type-8": 1, "Acid Trap Hole": 1, "Damage Diet": 1}},
	# Theme decks sold at the card shop.
	"deck_water": {"name": "Rising Tide", "cards": {"Hammer Shark": 3, "Saber Shark": 2, "Spear Shark": 2, "Double Fin Shark": 2, "Big Jaws": 2, "Shark Stickers": 2, "Silent Angler": 2, "Needle Sunfish": 1, "Mother Grizzly": 2, "Cyber Shark": 1, "Mermaid Shark": 2, "Umi": 2, "Big Wave Small Wave": 1, "Aqua Jet": 2, "Xyz Gift": 2, "Salvage": 2, "Pot of Greed": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1, "Torrential Tribute": 1, "Splash Capture": 1, "Poseidon Wave": 2, "Call of the Haunted": 1, "Draining Shield": 2},
		"extra": {"Bahamut Shark": 2, "Number 37: Hope Woven Dragon Spider Shark": 1, "Number 32: Shark Drake": 1, "Number 101: Silent Honor ARK": 1, "Number 17: Leviathan Dragon": 1, "Number 47: Nightmare Shark": 1}},
	"deck_fire": {"name": "Wildfire", "cards": {"Dian Keto the Cure Master": 1, "Fire Princess": 2, "UFO Turtle": 3, "Volcanic Slicer": 3, "Solar Flare Dragon": 3, "Flare Resonator": 2, "Flamvell Guard": 2, "Lava Golem": 1, "Hinotama": 2, "Ookazi": 2, "Tremendous Fire": 2, "Meteor of Destruction": 1, "Final Flame": 1, "Molten Destruction": 2, "Monster Reborn": 1, "Swords of Revealing Light": 1, "Salamandra": 1, "Just Desserts": 2, "Magic Cylinder": 1, "Ceasefire": 2, "Backfire": 2, "Sakuretsu Armor": 1, "Gravity Bind": 1, "Waboku": 1},
		"extra": {"Lightning Warrior": 2, "Crimson Blader": 1, "Colossal Fighter": 1}},
	"deck_wind": {"name": "Storm Wings", "cards": {"Mist Valley Apex Avian": 1, "Mist Valley Windmaster": 1, "Mist Valley Baby Roc": 2, "Mist Valley Soldier": 3, "Mist Valley Shaman": 2, "Mist Valley Falcon": 3, "Mist Valley Thunderbird": 3, "Mist Valley Watcher": 2, "Mist Valley Executor": 1, "Rising Air Current": 2, "Book of Moon": 1, "Heavy Storm": 1, "Rush Recklessly": 2, "Harpie's Feather Duster": 1, "Monster Reincarnation": 2, "Icarus Attack": 3, "Mirror Force": 1, "Dust Tornado": 2, "Torrential Tribute": 1, "Call of the Haunted": 1, "Shrink": 1, "Floodgate Trap Hole": 1, "Reckless Greed": 1, "Pot of Avarice": 1, "Defense Draw": 1},
		"extra": {"Mist Valley Thunder Lord": 2, "Lightning Warrior": 1, "Crimson Blader": 1, "Colossal Fighter": 1, "Gagaga Cowboy": 1}},
	"deck_dragon": {"name": "Dragon's Den", "cards": {"Lord of D.": 2, "Divine Dragon Ragnarok": 2, "Thunder Dragon": 3, "Luster Dragon #2": 1, "Tyrant Dragon": 1, "Alexandrite Dragon": 2, "Spear Dragon": 2, "Masked Dragon": 2, "Lancer Lindwurm": 1, "Strong Wind Dragon": 1, "Axe Dragonute": 1, "The Flute of Summoning Dragon": 2, "Polymerization": 2, "Dragon's Mirror": 2, "Mountain": 2, "Dark Hole": 1, "Stamping Destruction": 2, "Monster Reincarnation": 2, "Foolish Burial": 1, "Sakuretsu Armor": 1, "Trap Hole": 1, "Threatening Roar": 2, "Negate Attack": 1, "Bottomless Trap Hole": 1, "Raigeki Break": 1, "Windstorm of Etaqua": 1},
		"extra": {"Twin-Headed Thunder Dragon": 2, "King Dragun": 2, "Five-Headed Dragon": 1}},
	"deck_warrior": {"name": "Iron Vanguard", "cards": {"Marauding Captain": 3, "Command Knight": 2, "Goblin Attack Force": 2, "Dark Blade": 2, "Axe Raider": 1, "D.D. Warrior Lady": 1, "Exiled Force": 1, "Freed the Brave Wanderer": 1, "Twin-Sword Marauder": 1, "Gaia The Fierce Knight": 1, "Curse of Dragon": 1, "Torapart": 2, "Little-Winguard": 1, "Reinforcement of the Army": 2, "Fighting Spirit": 1, "The Warrior Returning Alive": 2, "Polymerization": 2, "Lightning Blade": 2, "Sogen": 2, "Mystical Space Typhoon": 1, "Smashing Ground": 1, "Double Summon": 1, "Mirror Force": 1, "Trap Hole": 1, "Call of the Haunted": 1, "Draining Shield": 2, "Storming Mirror Force": 1, "Fiendish Chain": 1},
		"extra": {"Gaia the Dragon Champion": 1, "Lightning Warrior": 1, "Colossal Fighter": 1, "Crimson Blader": 1, "Gagaga Cowboy": 1, "Number 10: Illumiknight": 1}},
	"deck_arcane": {"name": "Mystic Arts", "cards": {"Royal Magical Library": 2, "Skilled Dark Magician": 1, "Skilled White Magician": 2, "Breaker the Magical Warrior": 3, "Apprentice Magician": 2, "Old Vindictive Magician": 1, "Effect Veiler": 2, "Night's End Sorcerer": 2, "Buster Blader": 1, "Gemini Elf": 2, "Monster Reborn": 1, "Book of Moon": 1, "Mage Power": 2, "Lightning Vortex": 1, "Card of Sanctity": 1, "Upstart Goblin": 1, "Book of Secret Arts": 2, "Graceful Charity": 1, "Monster Reincarnation": 2, "Giant Trunade": 1, "Spellbinding Circle": 2, "Magic Jammer": 2, "Waboku": 1, "Fissure": 1, "Widespread Ruin": 1, "Dark Mirror Force": 1, "Lost Wind": 1},
		"extra": {"Arcanite Magician": 2, "Explosive Magician": 1, "Lightning Warrior": 1, "Number 104: Masquerade": 1}},
	"deck_shadow": {"name": "Midnight Court", "cards": {"Dark Resonator": 3, "Giant Orc": 2, "Archfiend Soldier": 2, "Mad Archfiend": 2, "Snipe Hunter": 2, "Stygian Street Patrol": 2, "Juragedo": 2, "Lancer Archfiend": 1, "Sangan": 1, "Newdoria": 1, "Summoned Skull": 1, "Dark Ruler Ha Des": 1, "Gil Garth": 1, "Kuriboh": 1, "Mystic Plasma Zone": 2, "Malevolent Nuzzler": 2, "Pot of Greed": 1, "Premature Burial": 1, "Foolish Burial": 1, "Tribute to The Doomed": 1, "Resonator Call": 2, "Double Summon": 1, "Fiendish Chain": 2, "Bottomless Trap Hole": 1, "Torrential Tribute": 1, "Dust Tornado": 1, "Threatening Roar": 1, "Starlight Road": 1},
		"extra": {"Chaos King Archfiend": 2, "Hundred Eyes Dragon": 1, "Lightning Warrior": 1, "Number 66: Master Key Beetle": 2, "Gagaga Cowboy": 1}},
	"deck_machine": {"name": "Gear Works", "cards": {"X-Head Cannon": 3, "Y-Dragon Head": 3, "Z-Metal Tank": 3, "V-Tiger Jet": 2, "W-Wing Catapult": 2, "Steamroid": 1, "Drillroid": 1, "Jetroid": 1, "Cyber Phoenix": 1, "Machine Conversion Factory": 1, "Megamorph": 2, "Limiter Removal": 1, "United We Stand": 2, "Heavy Storm": 1, "Enemy Controller": 2, "Shrink": 2, "Fissure": 1, "Premature Burial": 1, "Monster Reincarnation": 2, "Swords of Revealing Light": 1, "Ring of Destruction": 1, "Trap Jammer": 1, "Dimensional Prison": 1, "Compulsory Evacuation Device": 1, "Mirror Wall": 1, "Nightmare Wheel": 1, "Wall of Revealing Light": 1},
		"extra": {"XY-Dragon Cannon": 1, "XZ-Tank Cannon": 1, "YZ-Tank Dragon": 1, "XYZ-Dragon Cannon": 2, "VW-Tiger Catapult": 2, "VWXYZ-Dragon Catapult Cannon": 1}},
	"deck_wild": {"name": "Fang and Claw", "cards": {"Gene-Warped Warwolf": 3, "Vorse Raider": 2, "Mad Dog of Darkness": 2, "Battle Ox": 2, "Mystic Horseman": 2, "Gazelle the King of Mythical Beasts": 2, "Berfomet": 2, "Bazoo the Soul-Eater": 1, "Giant Rat": 2, "Desmanian Devil": 1, "Rude Kaiser": 1, "Polymerization": 3, "Beast Fangs": 2, "Forest": 2, "Rush Recklessly": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Smashing Ground": 1, "Big Bang Shot": 1, "Fissure": 1, "Monster Reincarnation": 1, "Threatening Roar": 1, "Trap Hole": 1, "Widespread Ruin": 1, "Draining Shield": 1, "Call of the Haunted": 1},
		"extra": {"Chimera the Flying Mythical Beast": 2, "Rabid Horseman": 2, "Gagaga Cowboy": 1}},
	# Doctor Crowler's exam deck: what every new student faces at the entrance exam. His own
	# Ancient Gears, the Golem included, but none of the fast pieces (no Geartown, no Fortress, no
	# Fusion) and only the plainest Spells and Traps. A novice deck can beat it. Not sold anywhere.
	"deck_exam_gear": {"name": "Exam Deck", "cards": {"Ancient Gear": 3, "Ancient Gear Soldier": 3, "Ancient Gear Statue": 2, "Ancient Gear Cannon": 1, "Ancient Gear Hunting Hound": 2,
		"Ancient Gear Box": 2, "Ancient Gear Tanker": 1, "Ancient Gear Knight": 1, "Ancient Gear Wyvern": 1, "Ancient Gear Engineer": 1, "Ancient Gear Golem": 2, "Mechanicalchaser": 1,
		"Ancient Gear Castle": 1, "Ancient Gear Tank": 1, "Ancient Gear Workshop": 1, "Dian Keto the Cure Master": 1, "Red Medicine": 1, "Hinotama": 1, "Stop Defense": 1,
		"Rush Recklessly": 1, "Hammer Shot": 1, "Remove Trap": 1, "Fissure": 1, "Trap Hole": 1, "Waboku": 1, "Negate Attack": 1, "Enchanted Javelin": 1,
		"Ookazi": 1, "Sparks": 1, "Goblin's Secret Remedy": 1, "Castle Walls": 1, "Reinforcements": 1}},
	"deck_ancient_gear": {"name": "Clockwork Titans", "cards": {"Ancient Gear Duel": 1, "Ancient Gear Fortress": 1, "Ancient Gear Golem": 3, "Ancient Gear": 3, "Ancient Gear Soldier": 2, "Ancient Gear Knight": 1,
		"Ancient Gear Wyvern": 2, "Ancient Gear Statue": 2, "Ancient Gear Box": 2, "Ancient Gear Tanker": 1, "Ancient Gear Commander": 1,
		"Ancient Gear Hunting Hound": 2, "Ancient Gear Cannon": 1, "Ancient Gear Engineer": 1,
		"Geartown": 2, "Ancient Gear Castle": 1, "Ancient Gear Fusion": 2, "Ancient Gear Workshop": 1, "Ancient Gear Tank": 1, "Ancient Gear Explosive": 1,
		"Spell Gear": 1, "Ancient Gear Catapult": 1, "Polymerization": 1, "Mystical Space Typhoon": 1, "Pot of Greed": 1, "Limiter Removal": 1,
		"Cross-Dimensional Duel": 2, "Ancient Gear Reborn": 1},
		"extra": {"Ultimate Ancient Gear Golem": 2, "Ancient Gear Howitzer": 2, "Ancient Gear Megaton Golem": 1, "Chaos Ancient Gear Giant": 1}},
	"deck_six_samurai": {"name": "Way of the Six", "cards": {"Legendary Six Samurai - Kizan": 3, "Legendary Six Samurai - Kageki": 3, "Kagemusha of the Six Samurai": 3, "Grandmaster of the Six Samurai": 2, "Legendary Six Samurai - Enishi": 1, "Legendary Six Samurai - Mizuho": 2, "Legendary Six Samurai - Shinai": 2, "The Six Samurai - Zanji": 1, "The Six Samurai - Irou": 1, "Hand of the Six Samurai": 1, "Great Shogun Shien": 1, "Secret Six Samurai - Fuma": 1, "Six Samurai United": 3, "Gateway of the Six": 2, "Shien's Smoke Signal": 3, "Asceticism of the Six Samurai": 2, "Shien's Dojo": 1, "Temple of the Six": 1, "Reinforcement of the Army": 1, "Double-Edged Sword Technique": 2, "Musakani Magatama": 2, "Return of the Six Samurai": 1, "Six Style - Dual Wield": 1},
		"extra": {"Legendary Six Samurai - Shi En": 2, "Legendary Lord Six Samurai - Shi En": 1, "Legendary Lord Six Samurai - Kizan": 1, "Legendary Lord Six Samurai - Enishi": 1, "Shadow of the Six Samurai - Shien": 2, "Secret Six Samurai - Rihan": 1}},
	"deck_constellar": {"name": "Starlight Knights", "cards": {"Constellar Pollux": 3, "Constellar Kaus": 3, "Constellar Algiedi": 3, "Constellar Sombre": 2, "Constellar Sheratan": 2, "Constellar Caduceus": 1, "Constellar Leonis": 1, "Constellar Siat": 1, "Constellar Aldebaran": 1, "Constellar Zubeneschamali": 1, "Constellar Virgo": 1, "Constellar Antares": 1, "Satellarknight Deneb": 2, "Satellarknight Altair": 1, "Satellarknight Vega": 1, "Satellarknight Unukalhai": 1, "Constellar Star Chart": 2, "Constellar Twinkle": 1, "Constellar Belt": 1, "Constellar Tempest": 1, "Constellar Star Cradle": 1, "Constellar Tellarknights": 1, "Satellarknight Skybridge": 1, "Stellarknight Alpha": 1, "Tellarknight Genesis": 1, "Hexatellarknight": 1, "Constellar Meteor": 1, "Stellarnova Alpha": 2, "Stellarnova Wave": 1},
		"extra": {"Constellar Praesepe": 2, "Constellar Omega": 2, "Constellar Hyades": 1, "Constellar Pleiades": 2, "Constellar Ptolemy M7": 2, "Stellarknight Delteros": 1, "Stellarknight Triverr": 1, "Stellarknight Constellar Diamond": 1, "Darktellarknight Batlamyus": 1, "Tellarknight Ptolemaeus": 1, "Tellarknight Constellar Caduceus": 1}},
	"deck_dark_world": {"name": "Lords of Dark World", "cards": {"Grapha, Dragon Lord of Dark World": 3, "Snoww, Unlight of Dark World": 3, "Broww, Huntsman of Dark World": 3, "Beiige, Vanguard of Dark World": 2, "Sillva, Warlord of Dark World": 2, "Goldd, Wu-Lord of Dark World": 2, "Ceruli, Guru of Dark World": 1, "Reign-Beaux, Overlord of Dark World": 1, "Tour Guide From the Underworld": 1, "Morphing Jar": 1, "Dark World Dealings": 3, "Dragged Down into the Grave": 2, "The Gates of Dark World": 3, "Gateway to Dark World": 1, "Card Destruction": 1, "Allure of Darkness": 2, "Dark World Lightning": 2, "Hand Destruction": 1, "The Forces of Darkness": 1, "Dark Deal": 1, "Mind Crush": 1, "Dark Smog": 1, "Deck Devastation Virus": 1, "Dark World Brainwashing": 1},
		"extra": {"Grapha, Dragon Overlord of Dark World": 1, "Clorless, Chaos King of Dark World": 1, "Number 22: Zombiestein": 1, "Hieratic Sun Dragon Overlord of Heliopolis": 1, "Adreus, Keeper of Armageddon": 1, "Leviair the Sea Dragon": 1, "Number 80: Rhapsody in Berserk": 1}},
	"deck_archfiend": {"name": "Court of the Archfiends", "cards": {"Terrorking Archfiend": 2, "Infernalqueen Archfiend": 2, "Shadowknight Archfiend": 2, "Darkbishop Archfiend": 1, "Desrook Archfiend": 2, "Vilepawn Archfiend": 1, "Skull Archfiend of Lightning": 2, "Archfiend Emperor, the First Lord of Horror": 1, "Archfiend Empress": 1, "Archfiend Commander": 2, "Archfiend Cavalry": 2, "Archfiend General": 2, "Archfiend Heiress": 2, "Archfiend Giant": 1, "Summoned Skull": 1, "Pandemonium": 3, "Archfiend Palabyrinth": 1, "Archfiend's Oath": 1, "Checkmate": 1, "Falling Down": 2, "Axe of Despair": 1, "Makourai, the Lightning Strike": 1, "Archfiend's Roar": 2, "Battle-Scarred": 1, "Call of the Archfiend": 1, "Archfiend's Ghastly Glitch": 1, "Nightmare Archfiends": 1},
		"extra": {"Archfiend's Ascent": 2, "Number 80: Rhapsody in Berserk": 1, "Number 66: Master Key Beetle": 1, "Leviair the Sea Dragon": 1}},
	"deck_genex": {"name": "Genex Works", "cards": {"Genex Controller": 3, "Genex Undine": 3, "Genex Ally Birdman": 2, "R-Genex Magma": 2, "R-Genex Crusher": 2, "R-Genex Turbo": 1, "R-Genex Oracle": 1, "R-Genex Accelerator": 2, "Genex Neutron": 2, "Genex Searcher": 2, "Genex Turbine": 1, "Genex Blastfan": 1, "Genex Ally Duradark": 1, "Genex Furnace": 1, "Genex Solar": 1, "R-Genex Undine": 1, "Limiter Removal": 1, "Machine Duplication": 2, "Dark Hole": 1, "Pot of Avarice": 2, "Double Summon": 1, "Salvage": 2, "Mirror Force": 1, "Dimensional Prison": 1, "Solemn Warning": 1, "Soul Exchange": 1, "Mind Control": 1},
		"extra": {"Genex Ally Triarm": 1, "Genex Ally Triforce": 1, "Genex Ally Axel": 1, "Hydro Genex": 1, "Thermal Genex": 1, "Windmill Genex": 1, "Geo Genex": 1, "Locomotion R-Genex": 1, "Vindikite R-Genex": 1, "Arms of Genex Return Zero": 1}},
	"deck_madolche": {"name": "Madolche Tea Party", "cards": {"Madolche Magileine": 3, "Madolche Anjelly": 3, "Madolche Hootcake": 3, "Madolche Messengelato": 2, "Madolche Mewfeuille": 2, "Madolche Puddingcess": 2, "Madolche Petingcessoeur": 2, "Madolche Butlerusk": 1, "Madolche Chouxvalier": 1, "Madolche Marmalmaide": 1, "Madolche Chateau": 2, "Madolche Ticket": 3, "Madolche Salon": 1, "Terraforming": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1, "Book of Moon": 1, "Madolche Lesson": 1, "Madolche Tea Break": 1, "Madolche Nights": 1, "Madolche Promenade": 1, "Madolchepalooza": 1, "Madolche Dessert": 1, "Madolche Waltz": 1, "Mirror Force": 1, "Fiendish Chain": 1, "Maxx \"C\"": 1},
		"extra": {"Madolche Queen Tiaramisu": 2, "Madolche Queen Tiarafraise": 1, "Madolche Teacher Glassouffle": 1, "Madolche Puddingcess Chocolat-a-la-Mode": 1, "Number 39: Utopia": 1, "Gagaga Cowboy": 1, "Leviair the Sea Dragon": 1, "Number 17: Leviathan Dragon": 1, "Photon Papilloperative": 1, "Gem-Knight Pearl": 1, "Number 101: Silent Honor ARK": 1}},
	"deck_toon": {"name": "Toon Kingdom", "cards": {"Toon Gemini Elf": 2, "Toon Masked Sorcerer": 1, "Toon Mermaid": 2, "Toon Harpie Lady": 2, "Toon Cyber Dragon": 2, "Toon Dark Magician Girl": 1, "Toon Summoned Skull": 1, "Toon Dark Magician": 2, "Red-Eyes Toon Dragon": 1, "Toon Barrel Dragon": 1, "Toon Black Luster Soldier": 1, "Blue-Eyes Toon Dragon": 1, "Funny Dark Rabbit": 1, "Comic Cat": 1, "Evil Box": 1, "Toon World": 1, "Toon Kingdom": 2, "Toon World the Perfect World": 1, "Toon Table of Contents": 3, "Toon Bookmark": 1, "Toon Page-Flip": 1, "Toon Rollback": 1, "Shadow Toon": 1, "Comic Hand": 1, "Mimicat": 1, "Toon Mask": 1, "Toon Terror": 1, "Toon Briefcase": 1, "Toon Defense": 1, "Mind Scan": 1, "Mirror Force": 1, "Mystical Space Typhoon": 1},
		"extra": {"Blue-Eyes Toon Ultimate Dragon": 1}},
	"deck_gladiator": {"name": "Gladiator's Assault", "cards": {"Gladiator Beast Laquari": 3, "Gladiator Beast Darius": 2, "Gladiator Beast Bestiari": 2, "Gladiator Beast Equeste": 2, "Gladiator Beast Murmillo": 1, "Gladiator Beast Retiari": 1, "Gladiator Beast Hoplomus": 1, "Gladiator Beast Secutor": 1, "Gladiator Beast Samnite": 1, "Gladiator Beast Dimacari": 1, "Gladiator Beast Andal": 1, "Test Tiger": 2, "Gladiator Beast Spartacus": 1, "Gladiator Beast Alexander": 1, "Gladiator Proving Ground": 3, "Gladiator Beast's Respite": 2, "Colosseum - Cage of the Gladiator Beasts": 1, "Gladiator Beast's Battle Manica": 1, "Gladiator Beast's Battle Gladius": 1, "Indomitable Gladiator Beast": 1, "Mystical Space Typhoon": 1, "Book of Moon": 1, "Gladiator Beast War Chariot": 3, "Defensive Tactics": 1, "Double Tag Team": 1, "Gladiator Lash": 1, "Parry": 1, "Disarm": 1, "Mirror Force": 1},
		"extra": {"Gladiator Beast Gyzarus": 2, "Gladiator Beast Heraklinos": 2, "Gladiator Beast Gaiodiaz": 1, "Gladiator Beast Essedarii": 2, "Gladiator Beast Nerokius": 1}},
	"deck_dragunity": {"name": "Dragunity Legion", "cards": {"Dragunity Dux": 3, "Dragunity Legionnaire": 2, "Dragunity Phalanx": 3, "Dragunity Aklys": 2, "Dragunity Senatus": 2, "Dragunity Remus": 2, "Dragunity Legatus": 2, "Dragunity Arma Mystletainn": 2, "Dragunity Arma Leyvaten": 1, "Dragunity Militum": 1, "Dragunity Couse": 1, "Dragunity Primus Pilus": 1, "Dragon Ravine": 3, "Dragunity Divine Wind": 1, "Dragunity Glow": 1, "Dragunity Divine Lance": 2, "Dragon Mastery": 2, "Terraforming": 1, "Monster Reborn": 1, "Dragunity Legion": 2, "Dragunity Oubliette": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Solemn Warning": 1},
		"extra": {"Dragunity Knight - Vajrayana": 2, "Dragunity Knight - Gae Dearg": 1, "Dragunity Knight - Gae Bulg": 1, "Dragunity Knight - Barcha": 1, "Dragunity Knight - Trident": 1, "Dragunity Knight - Ascalon": 1, "Dragunity Knight - Areadbhair": 1, "Dragunity Knight - Gormfaobhar": 1, "Dragunity Knight - Luin": 1, "Dragunity Knight - Areus": 1}},
	"deck_heroic": {"name": "Heroic Challengers", "cards": {"Heroic Challenger - Double Lance": 3, "Heroic Challenger - Thousand Blades": 3, "Heroic Challenger - Assault Halberd": 3, "Heroic Challenger - Morning Star": 2, "Heroic Challenger - Extra Sword": 2, "Heroic Challenger - Spartan": 2, "Heroic Challenger - Night Watchman": 1, "Heroic Challenger - Swordshield": 1, "Heroic Challenger - Knuckle Sword": 1, "Heroic Challenger - Clasp Sword": 1, "Heroic Challenger - Ambush Soldier": 1, "Heroic Challenger - War Hammer": 1, "Heroic Envoy": 3, "Heroic Call": 2, "Heroic Chance": 2, "Monster Reborn": 1, "Dark Hole": 1, "Book of Moon": 1, "Heroic Advance": 2, "Heroic Retribution Sword": 2, "Heroic Gift": 2, "Bottomless Trap Hole": 1, "Dimensional Prison": 1, "Maxx \"C\"": 1},
		"extra": {"Heroic Champion - Excalibur": 2, "Heroic Champion - Gandiva": 1, "Heroic Champion - Kusanagi": 1, "Heroic Champion - Claivesolish": 1, "Heroic Champion - Magnum Excalibur": 1, "Heroic Champion - Jarngreipr": 1, "Number 86: Heroic Champion - Rhongomyniad": 1, "Number 39: Utopia": 1, "Gagaga Cowboy": 1}},
	"deck_amazoness": {"name": "Amazoness Village", "cards": {"Amazoness Princess": 3, "Amazoness Queen": 2, "Amazoness Baby Tiger": 2, "Amazoness Tiger": 1, "Amazoness War Chief": 2, "Amazoness Swords Woman": 2, "Amazoness Paladin": 2, "Amazoness Sage": 1, "Amazoness Spy": 1, "Amazoness Spiritualist": 1, "Amazoness Fighter": 1, "Amazoness Chain Master": 1, "Amazoness Scouts": 1, "Amazoness Call": 2, "Amazoness Village": 2, "Amazoness Secret Arts": 1, "Polymerization": 2, "Amazoness Heirloom": 1, "Amazoness Spellcaster": 1, "Amazoness Fighting Spirit": 1, "Mystical Space Typhoon": 1, "Amazoness Onslaught": 2, "Amazoness Willpower": 1, "Amazoness Archers": 1, "Queen's Pawn": 1, "Dramatic Rescue": 1, "Amazoness Hall": 1, "Amazoness Hot Spring": 1, "Mirror Force": 1},
		"extra": {"Amazoness Empress": 2, "Amazoness Pet Liger": 2, "Amazoness Pet Liger King": 1, "Amazoness Augusta": 1}},
	"deck_crystal_beast": {"name": "Rainbow Ruins", "cards": {"Crystal Beast Sapphire Pegasus": 3, "Crystal Beast Ruby Carbuncle": 2, "Crystal Beast Topaz Tiger": 2, "Crystal Beast Amber Mammoth": 2, "Crystal Beast Cobalt Eagle": 2, "Crystal Beast Amethyst Cat": 2, "Crystal Beast Emerald Tortoise": 1, "Crystal Beast Rainbow Dragon": 1, "Rainbow Dragon": 2, "Crystal Bond": 3, "Crystal Beacon": 2, "Crystal Promise": 2, "Crystal Blessing": 2, "Rare Value": 2, "Crystal Abundance": 1, "Ancient City - Rainbow Ruins": 2, "Golden Rule": 1, "Crystal Release": 1, "Crystal Raigeki": 2, "Crystal Pair": 1, "Rainbow Path": 1, "Rainbow Gravity": 1, "Crystal Conclave": 1, "Crystal Miracle": 1},
		"extra": {"Rainbow Overdragon": 1, "Ultimate Crystal Rainbow Dragon Overdrive": 1}},
	"deck_vampire": {"name": "Vampire Kingdom", "cards": {"Vampire Familiar": 2, "Vampire Retainer": 2, "Vampire Ghost": 2, "Vampire Sorcerer": 3, "Vampire Lady": 2, "Shadow Vampire": 2, "Vampire Duke": 2, "Vampire Fraulein": 2, "Vampire Grace": 1, "Vampire Red Baron": 1, "Vampire Scarlet Scourge": 1, "Vampire Vamp": 1, "Vampire Lord": 1, "Vampire Kingdom": 2, "Vampire's Desire": 2, "Vampire's Domain": 2, "Terraforming": 1, "Mystical Space Typhoon": 1, "Monster Reborn": 1, "Book of Moon": 1, "Vampire Takeover": 2, "Vampire Domination": 2, "Vampire Awakening": 2, "Mirror Force": 1, "Call of the Haunted": 1},
		"extra": {"Crimson Knight Vampire Bram": 2, "Dhampir Vampire Sheridan": 2, "The Zombie Vampire": 1}},
	"deck_morphtronic": {"name": "Morphtronic Workshop", "cards": {"Morphtronic Celfon": 3, "Morphtronic Telefon": 2, "Morphtronic Smartfon": 1, "Morphtronic Radion": 2, "Morphtronic Boomboxen": 2, "Morphtronic Boarden": 2, "Morphtronic Remoten": 2, "Morphtronic Scopen": 2, "Morphtronic Datatron": 1, "Morphtronic Slingen": 1, "Morphtronic Magnen": 1, "Morphtronic Videon": 1, "Morphtronic Lantron": 1, "Gadget Gamer": 1, "Morphtronic Accelerator": 2, "Junk Box": 2, "Morphtronic Converter": 1, "Morphtronic Map": 1, "Gadget Box": 1, "Double Tool C&D": 1, "Morphtronic Repair Unit": 1, "Limiter Removal": 1, "Mystical Space Typhoon": 1, "Morphtronic Bind": 2, "Morphtransition": 1, "Morphtronics, Scramble!": 1, "Morphtronic Forcefield": 1, "Morphtronic Impact Return": 1, "Mirror Force": 1},
		"extra": {"Power Tool Dragon": 2, "Morphtronic Earfon": 1, "Armory Arm": 1}},
	"deck_scrap": {"name": "Scrapyard", "cards": {"Scrap Chimera": 3, "Scrap Beast": 3, "Scrap Goblin": 2, "Scrap Raptor": 2, "Scrap Orthros": 2, "Scrap Golem": 2, "Scrap Kong": 1, "Scrap Searcher": 2, "Scrap Recycler": 1, "Scrap Hunter": 1, "Scrap Breaker": 1, "Scrap Soldier": 1, "Scrap Worm": 1, "Scrapyard": 3, "Scrap Factory": 2, "Scrapstorm": 2, "Scrap Sheen": 1, "Guts of Steel": 1, "Terraforming": 1, "Mystical Space Typhoon": 1, "Monster Reborn": 1, "Scrap Crash": 1, "Scrap Rage": 1, "Scrap Garage": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1},
		"extra": {"Scrap Dragon": 2, "Scrap Twin Dragon": 1, "Atomic Scrap Dragon": 1, "Scrap Archfiend": 1}},
	"deck_chronomaly": {"name": "Out-of-Place Artifacts", "cards": {"Chronomaly Nebra Disk": 3, "Chronomaly Tuspa Rocket": 2, "Chronomaly Magella Globe": 2, "Chronomaly Crystal Skull": 2, "Chronomaly Crystal Bones": 2, "Chronomaly Golden Jet": 2, "Chronomaly Moai": 2, "Chronomaly Gordian Knot": 1, "Chronomaly Aztec Mask Golem": 1, "Chronomaly Colossal Head": 1, "Chronomaly Winged Sphinx": 1, "Chronomaly Tula Guardian": 1, "Chronomaly Mud Golem": 1, "Chronomaly Pyramid Eye Tablet": 2, "Chronomaly Technology": 2, "Chronomaly City Babylon": 2, "Chronomaly Temple - Trilithon": 2, "Dark Hole": 1, "Book of Moon": 1, "Stonehenge Methods": 2, "Chronomaly Esperanza Glyph": 2, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Dimensional Prison": 1, "Maxx \"C\"": 1, "Phoenix Wing Wind Blast": 1},
		"extra": {"Number 36: Chronomaly Chateau Huyuk": 2, "Number 33: Chronomaly Machu Mech": 1, "Chronomaly Vimana": 1, "Chronomaly Crystal Chrononaut": 1, "Number 6: Chronomaly Atlandis": 1, "Number C6: Chronomaly Chaos Atlandis": 1, "Number 39: Utopia": 1}},
	"deck_guardian": {"name": "Gate of the Guardians", "cards": {"Sanga of the Thunder": 3, "Kazejin": 3, "Suijin": 3, "Labyrinth Heavy Tank": 2, "Gate Guardian": 1, "Dark Guardian": 1, "Guardian Eatos": 2, "Guardian Dreadscythe": 1, "Guardian Grarl": 1, "Guardian Ceal": 1, "Labyrinth Wall Shadow": 2, "Dark Element": 2, "Double Attack! Wind and Thunder!!": 2, "Riryoku Guardian": 1, "Celestial Sword - Eatos": 1, "Reaper Scythe - Dreadscythe": 2, "Gravity Axe - Grarl": 1, "Shooting Star Bow - Ceal": 1, "Monster Reborn": 1, "Dark Hole": 1, "Prey of the Jirai Gumo": 2, "Call of the Haunted": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Phoenix Wing Wind Blast": 1, "Swords of Concealing Light": 1, "Creature Swap": 1},
		"extra": {"Gate Guardian of Thunder and Wind": 1, "Gate Guardian of Water and Thunder": 1, "Gate Guardian of Wind and Water": 1, "Gate Guardians Combined": 1}},
	"deck_alien": {"name": "Invasion of the A-Counters", "cards": {"Alien Shocktrooper": 2, "Alien Warrior": 2, "Alien Hunter": 2, "Alien Telepath": 1, "Alien Grey": 2, "Alien Dog": 2, "Alien Stealthbuster": 2, "I.A.S. -Invasive Alien Species-": 1, "Alien Overlord": 1, "Alien Mother": 1, "Alien Ammonite": 2, "Alien Kid": 1, "Cosmic Horror Gangi'el": 1, "\"A\" Cell Recombination Device": 2, "\"A\" Cell Breeding Device": 2, "Corruption Cell \"A\"": 2, "Mysterious Triangle": 1, "Code A Ancient Ruins": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Otherworld - The \"A\" Zone": 1, "Brainwashing Beam": 2, "Mass Hypnosis": 1, "Cell Explosion Virus": 1, "Interdimensional Warp": 1, "Detonator Circle \"A\"": 1, "Planet Pollutant Virus": 1, "Mirror Force": 1, "Crop Circles": 1},
		"extra": {"Cosmic Fortress Gol'gar": 2, "Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Starliege Paladynamo": 1}},
	"deck_volcanic": {"name": "Volcano Island", "cards": {"Volcanic Scattershot": 3, "Volcanic Shell": 2, "Volcanic Rimfire": 2, "Volcanic Trooper": 3, "Volcanic Rocket": 2, "Volcanic Slicer": 1, "Volcanic Blaster": 1, "Volcanic Counter": 1, "Volcanic Rat": 1, "Volcanic Hammerer": 1, "Volcanic Queen": 1, "Volcanic Emperor": 2, "Volcanic Doomfire": 1, "Blaze Accelerator": 2, "Tri-Blaze Accelerator": 1, "Volcanic Blaze Accelerator": 2, "Fire Ejection": 2, "Foolish Burial": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Volcanic Emission": 2, "Volcanic Inferno": 2, "Blaze Accelerator Reload": 2, "Volcanic Recharge": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1},
		"extra": {"Number 61: Volcasaurus": 1, "Number 30: Acid Golem of Destruction": 1, "Lavalval Chain": 1}},
	"deck_x_saber": {"name": "Sabers of the Sword Saints", "cards": {"XX-Saber Boggart Knight": 2, "X-Saber Pellina": 2, "X-Saber Bruno": 2, "XX-Saber Emmersblade": 2, "XX-Saber Darksoul": 1, "X-Saber Airbellum": 2, "X-Saber Galahad": 1, "XX-Saber Garsem": 1, "XX-Saber Fulhelmknight": 1, "XX-Saber Faultroll": 2, "XX-Saber Gardestrike": 1, "Commander Gottoms, Swordmaster": 1, "X-Saber Palomuro": 1, "XX-Saber Ragigura": 1, "X-Saber Uruz": 1, "X-Saber Anu Piranha": 1, "Saber Vault": 1, "Saber Slash": 1, "Saber Combination": 1, "Reinforcement of the Army": 2, "Gottoms' Second Call": 1, "Sword of Sparkles": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1, "Saber Reflection": 2, "Gottoms' Emergency Call": 2, "Saber Hole": 2, "At One With the Sword": 1, "Mirror Force": 1},
		"extra": {"X-Saber Gottoms": 1, "XX-Saber Gottoms": 1, "XX-Saber Hyunlei": 2, "X-Saber Souza": 1, "Commander Souza, Swordmaster": 1, "X-Saber Wayne": 1, "X-Saber Urbellum": 1, "M-X-Saber Invoker": 1, "Stardust Dragon": 1, "Scrap Dragon": 1, "Colossal Fighter": 1, "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1}},
	"deck_gimmick_puppet": {"name": "Mansion of the Dreadful Dolls", "cards": {"Gimmick Puppet Rouge Doll": 2, "Gimmick Puppet Fiendish Knight": 2, "Gimmick Puppet Little Soldiers": 2, "Gimmick Puppet Humpty Dumpty": 2, "Gimmick Puppet Scissor Arms": 2, "Gimmick Puppet Terror Baby": 2, "Gimmick Puppet Magnet Doll": 2, "Gimmick Puppet Bisque Doll": 1, "Gimmick Puppet Dreary Doll": 2, "Gimmick Puppet Nightmare": 2, "Gimmick Puppet Shadow Feeler": 1, "Gimmick Puppet Twilight Joker": 1, "Gimmick Puppet Cattle Scream": 1, "Gimmick Puppet Egg Head": 1, "Gimmick Puppet Des Troy": 1, "Junk Puppet": 2, "Mansion of the Dreadful Dolls": 2, "Perform Puppet": 1, "Condolence Puppet": 1, "Rank-Up-Magic Barian's Force": 1, "Monster Reborn": 1, "Puppet Ritual": 1, "Dark Hole": 1, "Mystical Space Typhoon": 1, "Puppet Parade": 2, "Service Puppet Play": 1, "Mirror Force": 1, "Call of the Haunted": 1},
		"extra": {"Number 15: Gimmick Puppet Giant Grinder": 1, "Number 40: Gimmick Puppet of Strings": 1, "Number 88: Gimmick Puppet of Leo": 1, "Gimmick Puppet Fantasix Machinix": 1, "Gimmick Puppet Gigantes Doll": 1, "Number C15: Gimmick Puppet Giant Hunter": 1, "Number C40: Gimmick Puppet of Dark Strings": 1, "Number C88: Gimmick Puppet Disaster Leo": 1, "CXyz Gimmick Puppet Fanatix Machinix": 1, "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1}},
	"deck_battlin_boxer": {"name": "Ring of Champions", "cards": {"Battlin' Boxer Promoter": 3, "Battlin' Boxer Uppercutter": 3, "Battlin' Boxer Switchitter": 2, "Battlin' Boxer Headgeared": 2, "Battlin' Boxer Glassjaw": 2, "Battlin' Boxer Sparrer": 2, "Battlin' Boxer Chief Second": 2, "Battlin' Boxer Shadow": 1, "Battlin' Boxer Veil": 1, "Battlin' Boxer Counterpunch": 1, "Battlin' Boxer Rib Gardna": 1, "Battlin' Boxer Rabbit Puncher": 1, "Battlin' Boxer Big Bandage": 1, "Battlin' Boxing Spirits": 2, "Ring Announcer": 2, "Reinforcement of the Army": 1, "Rank-Up-Magic Barian's Force": 2, "Monster Reborn": 1, "Double Summon": 1, "Dark Hole": 1, "Jolt Counter": 2, "Last Counter": 2, "Battlin' Boxing Cross Counter": 2, "Bottomless Trap Hole": 1, "Dimensional Prison": 1},
		"extra": {"Battlin' Boxer King Dempsey": 2, "Battlin' Boxer Lead Yoke": 1, "Number 79: Battlin' Boxer Nova Kaiser": 1, "Number C79: Battlin' Boxer General Kaiser": 1, "Number 105: Battlin' Boxer Star Cestus": 1, "Number C105: Battlin' Boxer Comet Cestus": 1, "Battlin' Boxer Cheat Commissioner": 1, "Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1}},
	"deck_exodia": {"name": "The Forbidden One", "cards": {"Exodia the Forbidden One": 1, "Right Arm of the Forbidden One": 1, "Left Arm of the Forbidden One": 1, "Right Leg of the Forbidden One": 1, "Left Leg of the Forbidden One": 1, "The Legendary Exodia Incarnate": 1, "Exodius the Ultimate Forbidden Lord": 1, "Exodia Necross": 1, "Mystic Tomato": 2, "Sangan": 1, "Battle Fader": 1, "Contract with Exodia": 2, "Millennium Ankh": 2, "Obliterate!!! Blaze": 2, "Upstart Goblin": 1, "Card Destruction": 1, "Swords of Revealing Light": 1, "Scapegoat": 2, "Gold Sarcophagus": 1, "Foolish Burial": 1, "Break the Seal": 3, "Obliterate!!!": 2, "Exxod Fires of Rage": 2, "Negate Attack": 1, "Magic Cylinder": 1, "Sakuretsu Armor": 1, "Fiendish Chain": 2, "Graceful Revival": 1, "Adhesion Trap Hole": 1, "Lightning Vortex": 1},
		"extra": {"The Unstoppable Exodia Incarnate": 1}},
	"deck_koaki_meiru": {"name": "Iron Core", "cards": {"Koa'ki Meiru Urnight": 2, "Koa'ki Meiru Boulder": 2, "Koa'ki Meiru Supplier": 1, "Koa'ki Meiru Guardian": 2, "Koa'ki Meiru Wall": 1, "Koa'ki Meiru Sandman": 1, "Koa'ki Meiru Drago": 1, "Koa'ki Meiru Beetle": 1, "Koa'ki Meiru Crusader": 1, "Koa'ki Meiru Ice": 1, "Koa'ki Meiru Prototype": 1, "Koa'ki Meiru Maximus": 2, "Koa'ki Meiru Valafar": 1, "Iron Core of Koa'ki Meiru": 3, "Core Transport Unit": 1, "Diamond Core of Koa'ki Meiru": 2, "Koa'ki Meiru Initialize!": 1, "Core Overclock": 2, "Iron Core Specimen Lab": 1, "Dark Hole": 1, "Iron Core Luster": 2, "Automatic Laser": 2, "Nega-Ton Corepanel": 2, "Core Reinforcement": 1, "Reckoned Power": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1, "Call of the Haunted": 1, "Compulsory Evacuation Device": 1},
		"extra": {"Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Starliege Paladynamo": 1, "Daigusto Emeral": 1}},
	"deck_arcana_force": {"name": "Turn of the Arcana", "cards": {"Arcana Force 0 - The Fool": 1, "Arcana Force I - The Magician": 2, "Arcana Force III - The Empress": 2, "Arcana Force IV - The Emperor": 2, "Arcana Force V - The Hierophant": 2, "Arcana Force VI - The Lovers": 2, "Arcana Force VII - The Chariot": 2, "Arcana Force XII - The Hangman": 1, "Arcana Force XIV - Temperance": 1, "Arcana Force XIX - The Sun": 1, "Arcana Force XV - The Fiend": 1, "Arcana Force XVIII - The Moon": 1, "Arcana Force XXI - The World": 1, "Arcana Force EX - The Light Ruler": 1, "Arcana Force EX - The Dark Ruler": 1, "Light Barrier": 3, "Light Force": 2, "Arcana Reading": 2, "Arcana Spread": 2, "Terraforming": 1, "Monster Reborn": 1, "Double Summon": 1, "Reversal of Fate": 2, "Arcana Call": 2, "Call of the Haunted": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1},
		"extra": {"Arcana Force EX - The Chaos Ruler": 1, "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1, "Diamond Dire Wolf": 1}},
	"deck_ice_barrier": {"name": "Guardians of the Ice Barrier", "cards": {"General Wayne of the Ice Barrier": 1, "Georgius, Swordman of the Ice Barrier": 2, "Speaker for the Ice Barriers": 2, "Revealer of the Ice Barrier": 1, "Hexa Spirit of the Ice Barrier": 1, "Mirror Mage of the Ice Barrier": 1, "Zuijin of the Ice Barrier": 1, "Prior of the Ice Barrier": 1, "Dewdark of the Ice Barrier": 1, "Cryomancer of the Ice Barrier": 1, "Defender of the Ice Barrier": 1, "Strategist of the Ice Barrier": 2, "Shock Troops of the Ice Barrier": 1, "Dance Princess of the Ice Barrier": 1, "Judge of the Ice Barrier": 1, "General Gantala of the Ice Barrier": 1, "General Grunard of the Ice Barrier": 1, "Medallion of the Ice Barrier": 3, "Winds Over the Ice Barrier": 2, "Freezing Chains of the Ice Barrier": 1, "Magic Triangle of the Ice Barrier": 2, "Dark Hole": 1, "Ice Barrier": 2, "Frozen Domain of the Ice Barrier": 2, "Terror of Trishula": 2, "Solemn Judgment": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Torrential Tribute": 1, "Blazing Mirror Force": 1},
		"extra": {"Brionac, Dragon of the Ice Barrier": 1, "Gungnir, Dragon of the Ice Barrier": 1, "Trishula, Dragon of the Ice Barrier": 1, "Trishula, Zero Dragon of the Ice Barrier": 1, "Dewloren, Tiger King of the Ice Barrier": 1, "Ekhajar, Descendant Dragon of the Ice Barrier": 1, "Lancea, Ancestral Dragon of the Ice Mountain": 1, "Stardust Dragon": 1, "Formula Synchron": 1, "Abyss Dweller": 1}},
	"deck_ninja": {"name": "Way of the Ninja", "cards": {"Ninja Grandmaster Hanzo": 2, "Yellow Ninja": 2, "Kagero the Cannon Ninja": 2, "Twilight Ninja Shingetsu": 1, "Upstart Golden Ninja": 1, "Green Ninja": 1, "Mitsu the Insect Ninja": 1, "Baku the Beast Ninja": 1, "Tobari the Sky Ninja": 1, "Senior Silver Ninja": 1, "Jioh the Gravity Ninja": 1, "Twilight Ninja Getsuga, the Shogun": 1, "Blue Dragon Ninja": 1, "Red Dragon Ninja": 1, "Twilight Ninja Nichirin, the Chunin": 1, "Black Dragon Ninja": 1, "White Ninja": 1, "Ninja Grandmaster Sasuke": 1, "Hidden Village of Ninjitsu Arts": 2, "Ninjitsu Art Notebook": 1, "Ninjitsu Art Notebook of Mystery": 1, "Ninjitsu Art Tool - Iron Digger": 1, "Monster Reborn": 1, "Book of Moon": 1, "Ninjitsu Art of Dancing Leaves": 2, "Ninjitsu Art of Duplication": 1, "Armor Ninjitsu Art of Freezing": 1, "Ninjitsu Art of Shadow Sealing": 1, "Ninjitsu Art of Decoy": 1, "Ninjitsu Art of Transformation": 2, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Solemn Judgment": 1, "Fiendish Chain": 1},
		"extra": {"Meizen the Battle Ninja": 1, "Yaguramaru the Armor Ninja": 1, "Blade Armor Ninja": 1, "Number 12: Crimson Shadow Armor Ninja": 1, "Number 2: Ninja Shadow Mosquito": 1, "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1, "Diamond Dire Wolf": 1}},
	"deck_kuriboh": {"name": "Kuriboh and Company", "cards": {"Kuriboh": 1, "Kuribah": 1, "Kuribee": 1, "Kuriboo": 1, "Kuribeh": 1, "Kuribabylon": 1, "Winged Kuriboh": 2, "Multiplying Kuriboh!": 1, "Clear Kuriboh": 1, "Ankuriboh": 1, "Junkuriboh": 1, "Kuribohrn": 1, "Rainbow Kuriboh": 1, "Sphere Kuriboh": 1, "Relinkuriboh": 1, "Kuribandit": 1, "Skilled Brown Magician": 1, "Winged Kuriboh LV10": 1, "Winged Kuriboh LV9": 1, "Magikuriboh": 1, "Five Star Twilight": 2, "The Flute of Summoning Kuriboh": 2, "Multiply": 2, "Detonate": 2, "Generation Next": 2, "Swords of Revealing Light": 1, "Scapegoat": 2, "Card Destruction": 1, "Magic Cylinder": 1, "Waboku": 1, "Negate Attack": 1, "Torrential Tribute": 1, "Safe Zone": 1}},
	"deck_cloudian": {"name": "Rolling Fog", "cards": {"Cloudian - Smoke Ball": 3, "Cloudian - Sheep Cloud": 2, "Cloudian - Poison Cloud": 2, "Cloudian - Ghost Fog": 1, "Cloudian - Acid Cloud": 2, "Cloudian - Altus": 2, "Cloudian - Cirrostratus": 2, "Cloudian - Turbulence": 2, "Cloudian - Storm Dragon": 2, "Cloudian - Nimbusman": 1, "Cloudian - Eye of the Typhoon": 1, "Summon Cloud": 2, "Cloudian Squall": 1, "Fog Control": 2, "Diamond-Dust Cyclone": 1, "Cloudian Aerosol": 2, "Lucky Cloud": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Raging Cloudian": 2, "Rain Storm": 1, "Natural Disaster": 1, "Updraft": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Bottomless Trap Hole": 1, "D.D. Crow": 1},
		"extra": {"Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Daigusto Emeral": 1}},
	"deck_naturia": {"name": "Voice of the Forest", "cards": {"Naturia Mole Cricket": 1, "Naturia Camellia": 2, "Naturia Marron": 1, "Naturia Cliff": 2, "Naturia Pumpkin": 2, "Naturia Rosewhip": 1, "Naturia Sunflower": 2, "Naturia Vein": 1, "Naturia Antjaw": 1, "Naturia Beans": 1, "Naturia Mantis": 1, "Naturia Horneedle": 1, "Naturia Ladybug": 1, "Naturia Strawberry": 1, "Naturia Hydrangea": 1, "Naturia Stag Beetle": 1, "Naturia Forest": 2, "Naturia Blessing": 1, "Barkion's Bark": 2, "Landoise's Luminous Moss": 2, "Leodrake's Mane": 1, "Dark Hole": 1, "Exterio's Fang": 2, "Naturia Sacred Tree": 2, "Solemn Judgment": 1, "Compulsory Evacuation Device": 1, "Torrential Tribute": 1, "Dimensional Prison": 1, "Fiendish Chain": 2, "Dark Bribe": 1},
		"extra": {"Naturia Barkion": 2, "Naturia Beast": 2, "Naturia Landoise": 1, "Naturia Leodrake": 1, "Naturia Exterio": 1, "Naturia Gaiastrio": 1, "Stardust Dragon": 1, "Formula Synchron": 1}},
	"deck_tg": {"name": "Tech Genus", "cards": {"T.G. Striker": 2, "T.G. Warwolf": 2, "T.G. Rush Rhino": 2, "T.G. Catapult Dragon": 1, "T.G. Cyber Magician": 2, "T.G. Booster Raptor": 2, "T.G. Jet Falcon": 1, "T.G. Screw Serpent": 1, "T.G. Rocket Salamander": 1, "T.G. Tank Grub": 1, "T.G. Metal Skeleton": 1, "T.G. Drill Fish": 1, "T.G. Gear Zombie": 1, "T.G. Limiter Removal": 2, "T.G. All Clear": 1, "TGX300": 1, "TGX1-HL": 2, "Dark Hole": 1, "Sonic Stun": 2, "T.G. Close": 2, "TG1-EM1": 1, "TGX3-DX2": 1, "TG-SX1": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Fiendish Chain": 2, "Chaos Trap Hole": 1},
		"extra": {"T.G. Hyper Librarian": 1, "T.G. Wonder Magician": 1, "T.G. Power Gladiator": 1, "T.G. Mighty Striker": 1, "T.G. Over Dragonar": 1, "T.G. Star Guardian": 1, "T.G. Recipro Dragonfly": 1, "T.G. Blade Blaster": 1, "T.G. Halberd Cannon": 1, "T.G. Glaive Blaster": 1, "Shooting Star Dragon T.G. EX": 1, "Stardust Dragon": 1}},
	"deck_fire_fist": {"name": "Brotherhood of the Fire Fist", "cards": {"Brotherhood of the Fire Fist - Bear": 2, "Brotherhood of the Fire Fist - Rooster": 2, "Brotherhood of the Fire Fist - Gorilla": 1, "Brotherhood of the Fire Fist - Raven": 1, "Brotherhood of the Fire Fist - Spirit": 1, "Brotherhood of the Fire Fist - Leopard": 1, "Brotherhood of the Fire Fist - Ram": 1, "Brotherhood of the Fire Fist - Wolf": 1, "Brotherhood of the Fire Fist - Coyote": 1, "Brotherhood of the Fire Fist - Panda": 1, "Brotherhood of the Fire Fist - Elephant": 1, "Brotherhood of the Fire Fist - Dragon": 1, "Brotherhood of the Fire Fist - Snake": 1, "Brotherhood of the Fire Fist - Buffalo": 1, "Brotherhood of the Fire Fist - Caribou": 1, "Brotherhood of the Fire Fist - Hawk": 1, "Brotherhood of the Fire Fist - Boar": 1, "Brotherhood of the Fire Fist - Swallow": 1, "Fire Formation - Tenki": 3, "Fire Formation - Gyokkou": 1, "Fire Formation - Tensu": 1, "Fire Formation - Yoko": 1, "Fire Formation - Ingen": 2, "Fire Fortress atop Liang Peak": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Fire Formation - Kaiyo": 1, "Fire Formation - Tenken": 1, "Fire Formation - Tensen": 2, "Ultimate Fire Formation - Sinto": 1, "Ultimate Fire Formation - Seito": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Solemn Judgment": 1},
		"extra": {"Brotherhood of the Fire Fist - Tiger King": 2, "Brotherhood of the Fire Fist - Cardinal": 1, "Brotherhood of the Fire Fist - Lion Emperor": 1, "Brotherhood of the Fire Fist - Swan": 1, "Brotherhood of the Fire Fist - Kirin": 1, "Brotherhood of the Fire Fist - Horse Prince": 1, "Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1}},
	"deck_dark_magician": {"name": "School of Dark Magic", "cards": {"Dark Magician": 3, "Dark Magician Girl": 1, "Magician's Rod": 2, "Magician's Robe": 2, "Apprentice Illusion Magician": 1, "Magician of Dark Illusion": 1, "Palladium Oracle Mahad": 1, "Palladium Oracle Mana": 1, "Skilled Dark Magician": 1, "Timaeus the United Dragon": 1, "Chronicle Sorceress": 1, "Magicians' Souls": 1, "Dark Magic Attack": 1, "Secrets of Dark Magic": 1, "Soul Servant": 1, "Dark Magical Circle": 1, "Illusion Magic": 1, "Dark Magic Inheritance": 1, "Thousand Knives": 1, "Dark Burning Attack": 1, "Magician's Salvation": 1, "The Eye of Timaeus": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Polymerization": 1, "Dark Magic Twin Burst": 1, "Bond Between Teacher and Student": 1, "Eternal Soul": 1, "Magician Navigation": 2, "Magicians' Combination": 1, "Destined Rivals": 1, "Dark Magic Talisman": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1},
		"extra": {"The Dark Magicians": 1, "Dark Magician the Dragon Knight": 1, "Dark Magician Girl the Dragon Knight": 1, "Dark Cavalry": 1, "Amulet Dragon": 1, "Timaeus the United Magical Dragon": 1, "Dark Magician of Destruction": 1, "Dark Paladin": 1}},
	"deck_blue_eyes": {"name": "Legend of the White Dragon", "cards": {"Blue-Eyes White Dragon": 3, "Blue-Eyes Alternative White Dragon": 2, "Sage with Eyes of Blue": 3, "The White Stone of Ancients": 1, "The White Stone of Legend": 2, "Maiden with Eyes of Blue": 1, "Kaibaman": 1, "Dragon Spirit of White": 1, "Blue-Eyes Abyss Dragon": 1, "Blue-Eyes Jet Dragon": 1, "Dictator of D.": 1, "Deep-Eyes White Dragon": 1, "Blue-Eyes Solid Dragon": 1, "Roar of the Blue-Eyed Dragons": 1, "Wishes for Eyes of Blue": 1, "Bingo Machine, Go!!!": 1, "Burst Stream of Destruction": 2, "Polymerization": 1, "Ultimate Fusion": 1, "Vision with Eyes of Blue": 1, "Majesty with Eyes of Blue": 2, "True Light": 2, "Majesty of the White Dragons": 2, "The Ultimate Creature of Destruction": 1, "Call of the Haunted": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Dimensional Prison": 1, "Zero Gravity": 1},
		"extra": {"Blue-Eyes Ultimate Dragon": 1, "Blue-Eyes Alternative Ultimate Dragon": 1, "Neo Blue-Eyes Ultimate Dragon": 1, "Blue-Eyes Twin Burst Dragon": 1, "Blue-Eyes Tyrant Dragon": 1, "Blue-Eyes Spirit Dragon": 1, "Blue-Eyes Ultimate Spirit Dragon": 1}},
	"deck_red_eyes": {"name": "Eyes of Red Potential", "cards": {"Red-Eyes Black Dragon": 3, "Red-Eyes Wyvern": 1, "Black Dragon's Chick": 2, "Red-Eyes Retro Dragon": 1, "Red-Eyes Black Meteor Dragon": 1, "Red-Eyes Alternative Black Dragon": 1, "Red-Eyes Soul": 1, "Red-Eyes Darkness Metal Dragon": 1, "Red-Eyes Black Flare Dragon": 1, "Gearfried the Red-Eyes Iron Knight": 1, "Meteor Dragon Red-Eyes Impact": 1, "Red-Eyes Darkness Dragon": 1, "The Black Stone of Legend": 2, "Red-Eyes Baby Dragon": 1, "Black Metal Dragon": 1, "Lord of the Red": 1, "Red-Eyes Fusion": 2, "Red-Eyes Insight": 2, "Cards of the Red Stone": 2, "Inferno Fire Blast": 1, "Dark Hole": 1, "Foolish Burial": 1, "Red-Eyes Transmigration": 2, "Return of the Red-Eyes": 1, "Red-Eyes Spirit": 1, "Red-Eyes Burn": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Red-Eyes Fang with Chain": 1, "Compulsory Evacuation Device": 1, "Xyz Reborn": 1},
		"extra": {"Red-Eyes Slash Dragon": 1, "Meteor Black Comet Dragon": 1, "Meteor Black Dragon": 1, "Red-Eyes Flare Metal Dragon": 1, "Red-Eyes Dark Dragoon": 1, "Black Skull Dragon": 1}},
	"deck_armed_dragon": {"name": "Armed Dragon Ascent", "cards": {"Armed Dragon LV3": 3, "Armed Dragon LV5": 2, "Armed Dragon LV7": 2, "Armed Dragon LV10": 1, "Armed Dragon Thunder LV3": 1, "Armed Dragon Thunder LV5": 1, "Armed Dragon Thunder LV7": 1, "Armed Dragon Thunder LV10": 1, "Fist Armed Dragon": 1, "Drill Armed Dragon": 1, "Armed Dragon, the Armored Dragon": 1, "Dark Armed Dragon": 1, "Knight Armed Dragon, the Armored Knight Dragon": 1, "Hardened Armed Dragon": 1, "Pile Armed Dragon": 1, "Metaphys Armed Dragon": 1, "Level Up!": 2, "Armed Dragon Blitz": 2, "Armed Dragon Flash": 1, "Armed Dragon Lightning": 2, "Level Modulation": 2, "Dark Hole": 1, "Foolish Burial": 1, "Armed Dragon Thunderbolt": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Fiendish Chain": 2, "D.D. Crow": 1, "Jar of Greed": 1},
		"extra": {"Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1}},
	"deck_nordic": {"name": "Twilight of the Gods", "cards": {"Dverg of the Nordic Alfar": 2, "Ljosalf of the Nordic Alfar": 1, "Svartalf of the Nordic Alfar": 2, "Mara of the Nordic Alfar": 1, "Mimir of the Nordic Ascendant": 1, "Vanadis of the Nordic Ascendant": 1, "Nordic Beast Gullinbursti": 1, "Tanngnjostr of the Nordic Beasts": 2, "Tanngrisnir of the Nordic Beasts": 1, "Guldfaxe of the Nordic Beasts": 1, "Garmr of the Nordic Beasts": 1, "Nordic Smith Ivaldi": 2, "Tyr of the Nordic Champions": 1, "Nordic Relic Hlidskjalf": 1, "Nordic Relic Draupnir": 2, "The Nordic Lights": 1, "March Towards Ragnarok": 1, "Dark Hole": 1, "Gleipnir, the Fetters of Fenrir": 2, "Nordic Relic Megingjord": 1, "Nordic Relic Gungnir": 2, "Nordic Relic Svalinn": 1, "Nordic Relic Laevateinn": 1, "Divine Relic Mjollnir": 2, "Solemn Authority": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Fiendish Chain": 2, "Smashing Ground": 1},
		"extra": {"Odin, Father of the Aesir": 1, "Thor, Lord of the Aesir": 1, "Loki, Lord of the Aesir": 1, "Stardust Dragon": 1, "Formula Synchron": 1}},
	"deck_bujin": {"name": "Divine Warriors of the Sun", "cards": {"Bujin Yamato": 2, "Bujin Mikazuchi": 2, "Bujin Arasuda": 1, "Bujin Hirume": 1, "Bujin Torifune": 1, "Bujin Mahitotsu": 1, "Bujingi Crane": 2, "Bujingi Turtle": 2, "Bujingi Quilin": 2, "Bujingi Hare": 2, "Bujingi Centipede": 1, "Bujingi Peacock": 1, "Bujingi Wolf": 1, "Bujingi Pavo": 1, "Bujincarnation": 2, "Bujincandescence": 1, "Bujinunity": 1, "Book of Moon": 1, "Bujin Regalia - The Sword": 2, "Bujin Regalia - The Jewel": 1, "Bujinfidel": 2, "Bujincident": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Fiendish Chain": 2, "Malevolent Catastrophe": 1, "Rush Recklessly": 1},
		"extra": {"Bujintei Susanowo": 2, "Bujintei Kagutsuchi": 1, "Bujintei Tsukuyomi": 1, "Bujinki Amaterasu": 1, "Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1}},
	"deck_legends_king": {"name": "Swords of Legend", "cards": {"Buster Blader": 3, "Buster Blader, the Destruction Swordmaster": 2, "Buster Whelp of the Destruction Swordsman": 3, "Wizard Buster Destruction Sword": 1, "Robot Buster Destruction Sword": 2, "Dragon Buster Destruction Sword": 2, "Jinzo": 2, "Jinzo - Jector": 2, "Jinzo - Returner": 1, "Jinzo the Machine Menace": 1, "Jinzo - Lord": 1, "Destruction Swordsman Fusion": 2, "Karma of the Destruction Swordsman": 2, "Polymerization": 2, "Reinforcement of the Army": 1, "Book of Moon": 1, "Destruction Sword Memories": 2, "Prologue of the Destruction Swordsman": 2, "Destruction Sword Flash": 2, "Compulsory Evacuation Device": 1, "Torrential Tribute": 1, "Dimensional Prison": 1, "Solemn Judgment": 1, "Hammer Shot": 1, "Enemy Controller": 1},
		"extra": {"Buster Blader, the Dragon Destroyer Swordsman": 2, "Buster Dragon": 1, "Jinzo - Layered": 1}},
	"deck_jurrac": {"name": "Age of the Jurrac", "cards": {"Jurrac Guaiba": 3, "Jurrac Velo": 3, "Jurrac Protops": 2, "Jurrac Stego": 1, "Jurrac Megalo": 2, "Jurrac Iguanon": 1, "Jurrac Monoloph": 1, "Jurrac Dino": 1, "Jurrac Brachis": 1, "Jurrac Herra": 1, "Jurrac Aeolo": 2, "Jurrac Titano": 1, "Jurrac Tyrannus": 1, "Jurrac Volcano": 2, "Big Evolution Pill": 2, "Jurassic World": 2, "Miracle Jurassic Egg": 1, "Swords of Revealing Light": 1, "Jurrac Impact": 2, "Sakuretsu Armor": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "Karma Cut": 1, "Forbidden Lance": 1, "Scapegoat": 1, "Battle Break": 1, "Time-Space Trap Hole": 1, "A Hero Emerges": 1},
		"extra": {"Jurrac Meteor": 1, "Jurrac Astero": 1, "Jurrac Velphito": 1, "Jurrac Giganoto": 1}},
	"deck_darklord": {"name": "Fall of the Darklords", "cards": {"Darklord Ukoback": 3, "Darklord Djehuty": 2, "Indulged Darklord": 1, "Darklord Nasten": 1, "Darklord Ixchel": 2, "Darklord Amdusc": 1, "Darklord Tezcatlipoca": 1, "Darklord Nergal": 1, "Darklord Superbia": 1, "Darklord Asmodeus": 1, "Darklord Desire": 1, "Darklord Zerato": 1, "Darklord Morningstar": 1, "Darklord Gulgolet": 1, "Capricious Darklord": 1, "Banishment of the Darklords": 2, "Darklord Contact": 1, "Darklord Dance": 2, "Foolish Burial": 1, "Dark Hole": 1, "Polymerization": 1, "Fallen Angel in Darkness": 2, "The Sanctified Darklord": 1, "Darklord Rebellion": 1, "Darklord Uprising": 2, "Darklord Enchantment": 2, "Darklord Descent": 1, "Call of the Haunted": 1, "Bottomless Trap Hole": 1, "Torrential Tribute": 1, "Dimensional Prison": 1},
		"extra": {"The First Darklord": 1, "Darklord Eveningstar": 2}},
	"deck_spirit": {"name": "Spirits of the Old Shrine", "cards": {"Aratama": 3, "Nikitama": 2, "Sakitama": 2, "Shinobird Crane": 1, "Shinobird Pigeon": 1, "Shinobird Crow": 1, "Izanami": 1, "Yata-Garasu": 1, "Rasetsu": 1, "Yaksha": 1, "Otohime": 1, "Susa Soldier": 1, "Fenghuang": 1, "Dark Dust Spirit": 1, "Konohanasakuya": 1, "Shinobaron Peacock": 1, "Shinobaroness Peacock": 1, "Asura Priest": 1, "Inaba White Rabbit": 1, "Hino-Kagu-Tsuchi": 1, "Shinobird's Calling": 2, "Swords of Revealing Light": 1, "Book of Moon": 1, "Sakuretsu Armor": 1, "Negate Attack": 1, "Magic Cylinder": 1, "Half Unbreak": 1, "Treacherous Trap Hole": 1, "Soul Taker": 1, "Miracle's Wake": 1, "Creature Swap": 1, "Staunch Defender": 1, "Giant Trap Hole": 1, "Deep Dark Trap Hole": 1, "Breakthrough Skill": 1}},
	"deck_union": {"name": "Union Hangar", "cards": {"A-Assault Core": 3, "B-Buster Drake": 3, "C-Crush Wyvern": 3, "Union Driver": 1, "Union Pilot": 1, "X-Head Cannon": 2, "Y-Dragon Head": 2, "Z-Metal Tank": 2, "Y-Yare Head": 1, "Z-Zillion Tank": 1, "Oilman": 1, "Union Hangar": 2, "Union Activation": 2, "Unauthorized Reactivation": 2, "Frontline Base": 2, "Union Scramble": 2, "Formation Union": 2, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1, "Solemn Judgment": 1, "Dimensional Prison": 1, "Void Trap Hole": 1, "Magic Jammer": 1, "Shadow Spell": 1},
		"extra": {"ABC-Dragon Buster": 2, "A-to-Z-Dragon Buster Cannon": 1, "XYZ-Dragon Cannon": 1, "XY-Dragon Cannon": 1, "XZ-Tank Cannon": 1, "YZ-Tank Dragon": 1, "Union Controller": 1}},
	"deck_hero": {"name": "Heroes and Villains", "cards": {"Evil HERO Infernal Prodigy": 1, "Evil HERO Adusted Gold": 2, "Evil HERO Sinister Necrom": 2, "Evil HERO Malicious Edge": 2, "Evil HERO Vicious Claws": 1, "Evil HERO Infernal Rider": 1, "Evil HERO Dead-End Prison": 1, "Evil HERO Toxic Bubble": 1, "Elemental HERO Avian": 1, "Elemental HERO Burstinatrix": 1, "Elemental HERO Clayman": 1, "Elemental HERO Sparkman": 1, "Elemental HERO Heat": 1, "Masked HERO Dusk Crow": 1, "Masked HERO Fountain": 1, "Elemental HERO Woodsman": 1, "Dark Fusion": 3, "Polymerization": 2, "Mask Change": 2, "E - Emergency Call": 2, "Reinforcement of the Army": 1, "HERO's Bond": 2, "Legacy of a HERO": 2, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Hero Blast": 1, "Dimensional Prison": 1, "Solemn Judgment": 1, "Sakuretsu Armor": 1, "Magic Drain": 1},
		"extra": {"Evil HERO Inferno Wing": 1, "Evil HERO Lightning Golem": 1, "Evil HERO Infernal Sniper": 1, "Evil HERO Malicious Fiend": 1, "Evil HERO Dark Gaia": 1, "Evil HERO Inferno Wing - Backfire": 1, "Evil HERO Darkest Knight": 1, "Evil HERO Malicious Bane": 1, "Masked HERO Vapor": 1, "Masked HERO Koga": 1, "Masked HERO Divine Wind": 1, "Masked HERO Anki": 1, "Masked HERO Dian": 1, "Elemental HERO Darkbright": 1, "Elemental HERO Thunder Giant - Voltic Thunder": 1}},
	"deck_sacred_beast": {"name": "The Three Phantasms", "cards": {"Uria, Lord of Searing Flames": 1, "Hamon, Lord of Striking Thunder": 1, "Raviel, Lord of Phantasms": 1, "Inferno of the Sacred Beasts - Uria, Lord of Searing Flames": 1, "Calamity of the Sacred Beasts - Hamon, Lord of Striking Thunder": 1, "Infinity of the Sacred Beasts - Raviel, Lord of Phantasms": 1, "Raviel, Lord of Phantasms - Shimmering Scraper": 1, "Summoner of the Sacred Beasts": 2, "Martyr of the Sacred Beasts": 3, "Phantasmal Summoning Beast": 2, "Sacred Beasts Released": 2, "Fallen Paradise of the Sacred Beasts": 2, "Sacred Beasts Thunderclap": 2, "Dimension Fusion Destruction": 1, "Polymerization": 1, "Foolish Burial": 1, "Illusion Gate": 2, "Phantasmal Martyrs": 2, "Book of Moon": 1, "Abyss of the Sacred Beasts": 3, "Sacred Beasts Combined Assault": 2, "Awakening of the Sacred Beasts": 2, "Call of the Haunted": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Dimensional Prison": 1, "Floodgate Trap Hole": 1},
		"extra": {"Armityle the Chaos Phantasm": 1, "Armityle the Chaos Phantasm - Phantom of Fury": 1, "Phantasm Emperor Trilojig": 1, "The Chaotic Phantasmal Sacred Beasts": 1}},
	"deck_cyber": {"name": "Cyber Style", "cards": {"Cyber Dragon": 3, "Cyber Dragon Core": 2, "Cyber Dragon Drei": 1, "Cyber Dragon Zwei": 1, "Cyber Jormungardr": 1, "Revolution Cyber Dragon": 1, "Cyber Pharos": 1, "Cyberdark Horn": 1, "Cyberdark Edge": 1, "Cyberdark Keel": 1, "Cyberdark Chimera": 1, "Cyberdark Cannon": 1, "Cyberdark Wurm": 1, "Armored Cybern": 1, "Attachment Cybern": 1, "Cyber Valley": 1, "Dragonroid": 1, "Power Bond": 2, "Polymerization": 2, "Overload Fusion": 2, "Cyberdark Realm": 2, "Cyber Eternal": 2, "Limiter Removal": 1, "Cyberdark Invasion": 2, "Cyber Network": 1, "Bottomless Trap Hole": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "Dimensional Prison": 1, "Book of Moon": 1, "Draining Shield": 1},
		"extra": {"Cyber End Dragon": 2, "Cyber Twin Dragon": 1, "Chimeratech Overdragon": 1, "Chimeratech Fortress Dragon": 1, "Cyberdark Dragon": 1, "Cyberdarkness Dragon": 1, "Cyberdark End Dragon": 1, "Cyber End Dragon the Decisive Strike Dragon": 1}},
	"deck_meklord": {"name": "Machine Emperors", "cards": {"Meklord Army of Wisel": 3, "Meklord Army of Skiel": 3, "Meklord Army of Granel": 3, "Meklord Army Deployer Obbligato": 2, "Meklord Nucleus Infinity Core": 2, "Meklord Emperor Wisel": 1, "Meklord Emperor Skiel": 1, "Meklord Emperor Granel": 1, "Meklord Emperor Wisel - Synchro Absorption": 1, "Meklord Astro Dragon Asterisk": 1, "Meklord Astro Dragon Triskelion": 1, "Meklord Astro Mekanikle": 1, "Meklord Assembly": 2, "Meklord Fortress": 1, "Boon of the Meklord Emperor": 2, "Meklord Deflection": 2, "The Resolute Meklord Army": 2, "Dark Hole": 1, "Limiter Removal": 1, "Meklord Factory": 2, "Meklord Astro the Eradicator": 2, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Sakuretsu Armor": 1, "Rising Energy": 1}},
	"deck_synchron": {"name": "Junk Squad", "cards": {"Junk Synchron": 3, "Quillbolt Hedgehog": 1, "Speed Warrior": 1, "Doppelwarrior": 1, "Junk Changer": 1, "Junk Meister": 1, "Junk Armor": 1, "Starjunk Synchron": 2, "Junk Anchor": 1, "Steam Synchron": 1, "Satellite Synchron": 1, "Junk Breaker": 1, "Junk Blader": 2, "Junk Giant": 1, "Junk Dragonlet": 1, "Fleur Synchron": 1, "Necro Synchron": 1, "Junk Signal": 2, "Starlight Junktion": 2, "Tuning": 2, "Monster Reborn": 1, "Book of Moon": 1, "Synchro Deflector": 2, "Junk Sleep": 2, "Mirror Force": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "Bri Synchron": 1, "Wheel Synchron": 1, "Storming Mirror Force": 1, "Malevolent Catastrophe": 1},
		"extra": {"Junk Warrior Extreme": 1, "Junk Warrior": 2, "Junk Destroyer": 1, "Junk Berserker": 1, "Junk Gardna": 1, "Nitro Warrior": 1, "Accel Synchron": 1, "Road Warrior": 1}},
	"deck_karakuri": {"name": "Karakuri Workshop", "cards": {"Karakuri Merchant mdl 177 \"Inashichi\"": 3, "Karakuri Strategist mdl 248 \"Nishipachi\"": 2, "Karakuri Komachi mdl 224 \"Ninishi\"": 3, "Karakuri Bonze mdl 9763 \"Kunamzan\"": 2, "Karakuri Gama mdl 4624 \"Shirokunishi\"": 2, "Karakuri Muso mdl 818 \"Haipa\"": 2, "Karakuri Bushi mdl 6318 \"Muzanichiha\"": 2, "Karakuri Soldier mdl 236 \"Nisamu\"": 2, "Karakuri Watchdog mdl 313 \"Saizan\"": 1, "Karakuri Barrel mdl 96 \"Shinkuro\"": 1, "Karakuri Spider": 1, "Karakuri Cash Cache": 2, "Karakuri Showdown Castle": 1, "Karakuri Gama Oil": 2, "Karakuri Anatomy": 2, "Mystical Space Typhoon": 1, "Karakuri Cash Inn": 2, "Karakuri Trick House": 2, "Karakuri Klock": 1, "Karakuri Cash Shed": 2, "Bottomless Trap Hole": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1},
		"extra": {"Karakuri Shogun mdl 00 \"Burei\"": 2, "Karakuri Steel Shogun mdl 00X \"Bureido\"": 1, "Karakuri Super Shogun mdl 00N \"Bureibu\"": 1}},
	"deck_fabled": {"name": "Realm of the Fabled", "cards": {"Fabled Grimro": 3, "The Fabled Cerburrel": 3, "Fabled Lurrie": 2, "The Fabled Ganashia": 2, "Fabled Krus": 2, "Fabled Marcosia": 2, "Fabled Raven": 1, "Fabled Miztoji": 1, "The Fabled Chawa": 1, "The Fabled Nozoochee": 1, "The Fabled Catsith": 1, "The Fabled Kokkator": 1, "Fabled Ashenveil": 1, "Fabled Soulkius": 1, "Stairway to a Fabled Realm": 2, "Fabled Realm's Revival": 2, "Card Destruction": 1, "Hand Destruction": 2, "Allure of Darkness": 1, "Upstart Goblin": 1, "Fabled Treason": 2, "Call of the Haunted": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "Dimensional Prison": 1, "Fabled Urustos": 1, "Time-Space Trap Hole": 1, "Dark Mirror Force": 1},
		"extra": {"Fabled Leviathan": 1, "Fabled Valkyrus": 1, "Fabled Ragin": 1, "Fabled Gammajin": 1, "The Fabled Unicore": 1, "The Fabled Kudabbi": 1, "Fabled Andwraith": 1, "Fabled Levilazebul": 1}},
	"deck_fortune_lady": {"name": "Ladies of Fortune", "cards": {"Fortune Lady Light": 3, "Fortune Lady Fire": 2, "Fortune Lady Wind": 3, "Fortune Lady Water": 3, "Fortune Lady Dark": 2, "Fortune Lady Earth": 2, "Fortune Lady Past": 2, "Fortune Fairy Hikari": 1, "Fortune Lady Calling": 3, "Magical Dimension": 2, "Dark Hole": 1, "Fortune Lady Rewind": 2, "Sakuretsu Armor": 1, "Compulsory Evacuation Device": 1, "Magic Cylinder": 1, "Swords of Revealing Light": 1, "Mirror Wall": 1, "Shadow Spell": 1, "Mind Control": 1, "Dust Tornado": 1, "Offerings to the Doomed": 1, "Spellbinding Circle": 1, "Enemy Controller": 1, "Forbidden Chalice": 1, "Magic Drain": 1, "Rush Recklessly": 1},
		"extra": {"Fortune Lady Every": 2, "Arcanite Magician": 1, "Explosive Magician": 1}},
	"deck_gusto": {"name": "Winds of Gusto", "cards": {"Winda, Priestess of Gusto": 2, "Kamui, Hope of Gusto": 1, "Gusto Gulldo": 2, "Gusto Egul": 2, "Gusto Falco": 2, "Gusto Codor": 2, "Gusto Griffin": 2, "Gusto Squirro": 2, "Gusto Vedir": 2, "Pilica, Descendant of Gusto": 1, "Musto, Oracle of Gusto": 1, "Caam, Serenity of Gusto": 1, "Windaar, Sage of Gusto": 1, "Reeze, Whirlwind of Gusto": 1, "Gusto Thunbolt": 1, "Tailwind of Gusto": 2, "Contact with Gusto": 2, "Mystical Space Typhoon": 1, "Monster Reborn": 1, "Rising Air Current": 1, "Blessings for Gusto": 2, "Whirlwind of Gusto": 2, "Dust Storm of Gusto": 2, "Call of the Haunted": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "Battle Break": 1},
		"extra": {"Daigusto Eguls": 1, "Daigusto Sphreez": 1, "Daigusto Falcos": 1, "Daigusto Gulldos": 1, "Daigusto Laplampilica": 1, "Daigusto Phoenix": 1, "Daigusto Emeral": 1}},
	"deck_mermail": {"name": "Atlantis Rising", "cards": {"Mermail Abyssteus": 2, "Mermail Abyssmegalo": 2, "Mermail Abyssleed": 1, "Mermail Abysspike": 3, "Mermail Abyssturge": 2, "Mermail Abysslinde": 2, "Mermail Abyssgunde": 2, "Mermail Abyssocea": 1, "Mermail Abysshilde": 1, "Neptabyss, the Atlantean Prince": 2, "Atlantean Marksman": 2, "Atlantean Heavy Infantry": 1, "Atlantean Dragoons": 1, "Poseidra, the Atlantean Dragon": 1, "Legendary Atlantean Tridon": 1, "Salvage": 2, "Abyss-sphere": 2, "Abyss-squall": 2, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Abyss-scorn": 1, "Abyss-steam": 1, "Mermail Abyssnose": 1, "Mermail Abyssdine": 1, "Quaking Mirror Force": 1},
		"extra": {"Mermail Abyssgaios": 1, "Mermail Abysstrite": 1, "Poseidra Abyss, the Atlantean Dragon Lord": 1, "Abysstrite, the Atlantean Spirit": 1}},
	"deck_spellbook": {"name": "The Prophecy Library", "cards": {"Spellbook Magician of Prophecy": 3, "Fool of Prophecy": 1, "Justice of Prophecy": 1, "Temperance of Prophecy": 1, "Amores of Prophecy": 1, "Charioteer of Prophecy": 1, "Reaper of Prophecy": 1, "High Priestess of Prophecy": 2, "Emperor of Prophecy": 1, "Prophecy Destroyer": 1, "World of Prophecy": 1, "Hermit of Prophecy": 1, "Spellbook of Secrets": 3, "Spellbook of Power": 2, "Spellbook of Life": 1, "Spellbook of Judgment": 1, "Spellbook of Knowledge": 2, "Spellbook of Fate": 1, "Spellbook of Eternity": 1, "Spellbook Library of the Heliosphere": 2, "Spellbook of the Master": 1, "The Grand Spellbook Tower": 1, "Spellbook Star Hall": 1, "Spellbook of Wisdom": 1, "Spellbook Organization": 2, "Mystical Space Typhoon": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1, "Magic Cylinder": 1, "Xyz Reborn": 1},
		"extra": {"Hierophant of Prophecy": 2, "Empress of Prophecy": 1}},
	"deck_wind_up": {"name": "Wind-Up Toybox", "cards": {"Wind-Up Magician": 3, "Wind-Up Rat": 3, "Wind-Up Shark": 3, "Wind-Up Hunter": 2, "Wind-Up Rabbit": 2, "Wind-Up Kitten": 1, "Wind-Up Soldier": 2, "Wind-Up Warrior": 1, "Wind-Up Knight": 1, "Wind-Up Juggler": 1, "Wind-Up Dog": 1, "Wind-Up Bat": 1, "Wind-Up Factory": 3, "Legendary Wind-Up Key": 2, "Monster Reborn": 1, "Book of Moon": 1, "Torrential Tribute": 1, "Dimensional Prison": 1, "Fiendish Chain": 2, "Sakuretsu Armor": 1, "Wind-Up Honeybee": 1, "Treacherous Trap Hole": 1, "Forbidden Lance": 1, "Dark Bribe": 1, "Zero Gravity": 1, "Safe Zone": 1, "Smashing Ground": 1},
		"extra": {"Wind-Up Zenmaister": 2, "Wind-Up Carrier Zenmaity": 2, "Wind-Up Arsenal Zenmaioh": 1}},
	"deck_ghostrick": {"name": "Ghostrick Night", "cards": {"Ghostrick Jiangshi": 2, "Ghostrick Siren": 2, "Ghostrick Lantern": 2, "Ghostrick Specter": 1, "Ghostrick Jackfrost": 1, "Ghostrick Mary": 1, "Ghostrick Witch": 2, "Ghostrick Yuki-onna": 1, "Ghostrick Stein": 1, "Ghostrick Skeleton": 1, "Ghostrick Mummy": 2, "Ghostrick Nekomusume": 1, "Ghostrick Warwolf": 1, "Ghostrick Doll": 1, "Ghostrick Fairy": 1, "Ghostrick Mansion": 2, "Ghostrick Museum": 2, "Ghostrick Parade": 2, "Ghostrick Shot": 1, "Book of Moon": 1, "Ghostrick Scare": 2, "Ghostrick Break": 1, "Ghostrick Vanish": 1, "Ghostrick-Go-Round": 1, "Ghostrick Night": 1, "Ghostrick Renovation": 2, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Dimensional Prison": 1},
		"extra": {"Ghostrick Angel of Mischief": 1, "Ghostrick Socuteboss": 1, "Ghostrick Dullahan": 2}},
	"deck_dragon_ruler": {"name": "Dragon Rulers", "cards": {"Tidal, Dragon Ruler of Waterfalls": 2, "Blaster, Dragon Ruler of Infernos": 2, "Redox, Dragon Ruler of Boulders": 2, "Tempest, Dragon Ruler of Storms": 2, "Stream, Dragon Ruler of Droplets": 1, "Burner, Dragon Ruler of Sparks": 1, "Reactan, Dragon Ruler of Pebbles": 1, "Lightning, Dragon Ruler of Drafts": 1, "Spectral, Dragon Ruler of Flickers": 1, "Nebulus, Dragon Ruler of Mishaps": 1, "Masked Dragon": 2, "Alexandrite Dragon": 1, "Spear Dragon": 2, "Luster Dragon": 2, "Axe Dragonute": 1, "Lord of D.": 1, "Monster Reborn": 1, "Foolish Burial": 1, "Card Destruction": 1, "Upstart Goblin": 1, "Dark Hole": 1, "Call of the Haunted": 1, "Sakuretsu Armor": 1, "Fiendish Chain": 2, "Trap Dustshoot": 2, "Karma Cut": 1, "Ego Boost": 1, "Giant Trap Hole": 1, "Lightning Vortex": 1, "Creature Swap": 1, "Defense Draw": 1},
		"extra": {"Chasma, Dragon Ruler of Auroras": 1, "Eclipse, Dragon Ruler of Catastrophes": 1, "Disaster, Dragon Ruler of All Apocalypses": 1, "Number 11: Big Eye": 1}},
	"deck_dd": {"name": "Different Dimension", "cards": {"D.D. Warrior Lady": 2, "D.D. Assailant": 2, "D.D. Survivor": 3, "D.D. Scout Plane": 2, "D.D. Guide": 1, "D.D. Crazy Beast": 2, "D.D. Unicorn Knight": 2, "D.D. Destroyer": 1, "D.D.M. - Different Dimension Master": 1, "Dimensional Alchemist": 2, "D.D. Crow": 1, "D.D.R. - Different Dimension Reincarnation": 2, "Dimension Fusion": 1, "Burial from a Different Dimension": 1, "Different Dimension Gate": 1, "D.D. Borderline": 1, "Dimensional Fissure": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Return from the Different Dimension": 1, "D.D. Dynamite": 2, "D.D. Trap Hole": 2, "Dimension Wall": 2, "Dimensional Prison": 1, "Macro Cosmos": 1, "Escape from the Dark Dimension": 1, "Mirror Force": 1, "Call of the Haunted": 1}},
	"deck_goblin": {"name": "Goblin Gang", "cards": {"Goblin Elite Attack Force": 2, "Goblin Attack Force": 2, "Goblin Marauding Squad": 2, "Goblin Recon Squad": 2, "Goblin Black Ops": 2, "Blindly Loyal Goblin": 2, "Coach Goblin": 1, "Goblin Pothole Squad": 1, "Goblin Decoy Squad": 1, "Goblindbergh": 2, "Goblin King": 1, "Crow Goblin": 1, "Goblin of Greed": 1, "Goblin Thief": 2, "Goblin's Secret Remedy": 1, "Upstart Goblin": 1, "Goblin Circus": 1, "Peeking Goblin": 2, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Robbin' Goblin": 1, "Goblin Fan": 1, "Goblin Out of the Frying Pan": 1, "Good Goblin Housekeeping": 1, "Hard-sellin' Goblin": 2, "Minor Goblin Official": 2, "Sakuretsu Armor": 1, "Bottomless Trap Hole": 1, "Drowning Mirror Force": 1}},
	"deck_mask": {"name": "Masks and Curses", "cards": {"The Masked Beast": 2, "Masked Beast Des Gardius": 1, "Masked Sorcerer": 2, "Masked Chameleon": 2, "Mask of Darkness": 2, "Masked Clown": 1, "Masked Dragon": 2, "Grand Tiki Elder": 2, "Melchid the Four-Face Beast": 2, "Curse of the Masked Beast": 2, "The Mask of Remnants": 1, "Mask of the Accursed": 2, "Mask of Dispel": 1, "Mask of Brutality": 2, "Curse of Fiend": 1, "Dark Hole": 1, "Mask of Restrict": 2, "Mask of Weakness": 2, "Tutan Mask": 2, "Curse of Anubis": 2, "Sakuretsu Armor": 1, "Torrential Tribute": 1, "Solemn Judgment": 1, "Compulsory Evacuation Device": 1, "Miracle's Wake": 1, "Lost Wind": 1}},
	"deck_toy": {"name": "Toy Box Troubles", "cards": {"Puppet Pawn": 2, "Puppet Rook": 2, "Puppet Queen": 2, "Puppet King": 2, "Puppet Plant": 1, "Puppet Master": 1, "Mysterious Puppeteer": 2, "Toy Magician": 2, "Toy Soldier": 2, "Toy Knight": 2, "Malice Doll of Demise": 2, "Perditious Puppeteer": 1, "Toy Box": 2, "The Puppet Magic of Dark Ruler": 2, "Bait Doll": 2, "Dark Hole": 1, "Sakuretsu Armor": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "A Hero Emerges": 1, "Starlight Road": 1, "Staunch Defender": 1, "Raigeki Break": 1, "Magic Jammer": 1, "Seven Tools of the Bandit": 1, "Windstorm of Etaqua": 1, "Graceful Revival": 1}},
	"deck_barrier": {"name": "Wardens of the Barrier", "cards": {"Barrier Statue of the Inferno": 1, "Barrier Statue of the Abyss": 1, "Barrier Statue of the Stormwinds": 1, "Barrier Statue of the Heavens": 1, "Barrier Statue of the Drought": 1, "Barrier Statue of the Torrent": 1, "Harvest Angel of Wisdom": 2, "Bountiful Artemis": 2, "Layard the Liberator": 2, "Meltiel, Sage of the Sky": 2, "Mei-Kou, Master of Barriers": 1, "Voltanis the Adjudicator": 1, "Splendid Venus": 1, "Mystical Space Typhoon": 1, "Pot of Duality": 1, "Pot of Greed": 1, "Solemn Warning": 1, "Magic Jammer": 2, "Seven Tools of the Bandit": 2, "Dark Bribe": 2, "Divine Wrath": 2, "Negate Attack": 1, "Synthetic Seraphim": 2, "Black Horn of Heaven": 2, "Horn of Heaven": 2, "Trap Jammer": 2, "Chaos Trap Hole": 1, "Scrap-Iron Scarecrow": 1}},
	"deck_frog": {"name": "Frogs and Penguins", "cards": {"Treeborn Frog": 1, "Submarine Frog": 1, "Dupe Frog": 2, "Swap Frog": 2, "Ronintoadin": 2, "Flip Flop Frog": 1, "Poison Draw Frog": 1, "Unifrog": 1, "Beelze Frog": 1, "Des Frog": 2, "Tradetoad": 1, "T.A.D.P.O.L.E.": 1, "Substitoad": 1, "Penguin Soldier": 2, "Penguin Knight": 1, "Nightmare Penguin": 1, "Penguin Ninja": 1, "Puny Penguin": 1, "The Great Emperor Penguin": 1, "Guard Penguin": 1, "Penguin Torpedo": 1, "Polymerization": 2, "Salvage": 2, "Pot of Duality": 1, "Froggy Forcefield": 2, "Call of the Haunted": 1, "Bottomless Trap Hole": 1, "Torrential Tribute": 1, "Solemn Judgment": 1, "Phoenix Wing Wind Blast": 1, "Fiendish Chain": 1, "Threatening Roar": 1},
		"extra": {"D.3.S. Frog": 1, "Toadally Awesome": 1}},
	"deck_rock": {"name": "Rock Solid", "cards": {"Gigantes": 2, "Grave Ohja": 2, "Golem Sentry": 2, "Goggle Golem": 2, "The Rock Spirit": 1, "Blockman": 2, "Moai Interceptor Cannons": 2, "Criosphinx": 1, "Hieracosphinx": 1, "Mystical Sand": 1, "Gonogo": 1, "Seismic Crasher": 1, "Legendary Jujitsu Master": 1, "Elephant Statue of Blessing": 1, "Elephant Statue of Disaster": 1, "Megarock Dragon": 1, "Castle Gate": 1, "Dark Hole": 1, "Pot of Duality": 1, "Dimensional Prison": 1, "Negate Attack": 1, "Sakuretsu Armor": 1, "Deep Dark Trap Hole": 1, "Pot of Avarice": 1, "Spell Shield Type-8": 1, "Jar of Greed": 1, "Blazing Mirror Force": 1, "Soul Exchange": 1, "Nightmare Wheel": 1, "Half Unbreak": 1, "Soul Taker": 1, "Hammer Shot": 1, "Shrink": 1, "Wall of Revealing Light": 1}},
	"deck_insect": {"name": "Insect Swarm", "cards": {"Chainsaw Insect": 2, "Jirai Gumo": 1, "Arsenal Bug": 1, "Guard Mantis": 2, "Praying Mantis": 2, "Blazewing Butterfly": 2, "Swarm of Scarabs": 1, "Swarm of Locusts": 1, "4-Starred Ladybug of Doom": 1, "Golden Ladybug": 1, "Insect Princess": 1, "Millennium Scorpion": 1, "Anteatereatingant": 1, "Bombardment Beetle": 1, "Silent Insect": 1, "Howling Insect": 2, "Gokipole": 1, "Drill Bug": 1, "Grasschopper": 1, "Insect Imitation": 2, "Mystical Space Typhoon": 1, "Dark Hole": 1, "Mirror Force": 1, "Sakuretsu Armor": 1, "Compulsory Evacuation Device": 1, "Impenetrable Attack": 1, "Breakthrough Skill": 1, "Void Trap Hole": 1, "Damage Diet": 1, "Chain Disappearance": 1, "Scapegoat": 1, "Adhesion Trap Hole": 1, "Fissure": 1, "Reckless Greed": 1}},
	"deck_zombie": {"name": "Zombie Night", "cards": {"Patrician of Darkness": 2, "Regenerating Mummy": 1, "Shutendoji": 1, "Lich Lord, King of the Underworld": 1, "Pumpking the King of Ghosts": 1, "Royal Keeper": 2, "Wandering Mummy": 1, "Necroface": 1, "Shadow Ghoul": 1, "Reborn Zombie": 1, "Double Coston": 1, "Fear from the Dark": 1, "Goka, the Pyre of Malice": 1, "Mezuki": 2, "Plaguespreader Zombie": 1, "Pyramid Turtle": 2, "Il Blud": 1, "Despair from the Dark": 1, "Goblin Zombie": 1, "Gernia": 1, "Zombie Master": 1, "Zombie World": 2, "Book of Life": 2, "Dark Hole": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1, "Divine Wrath": 1, "Acid Trap Hole": 1, "Widespread Ruin": 1, "Malevolent Catastrophe": 1, "Phoenix Wing Wind Blast": 1, "Threatening Roar": 1}},
	"deck_machina": {"name": "Machine Assembly", "cards": {"Machina Soldier": 2, "Machina Sniper": 2, "Machina Defender": 2, "Machina Force": 1, "Commander Covington": 1, "Cannon Soldier": 1, "Cannon Soldier MK-2": 1, "Machine King Prototype": 1, "Machine King": 1, "Perfect Machine King": 1, "Twin-Barrel Dragon": 1, "Blast Sphere": 1, "Reflect Bounder": 1, "Spell Canceller": 1, "Nanobreaker": 1, "Gear Golem the Moving Fortress": 1, "Mecha-Dog Marron": 1, "Emes the Infinity": 1, "B.E.S. Crystal Core": 1, "Patrol Robo": 1, "Monster Reborn": 1, "Pot of Duality": 1, "Dimensional Prison": 1, "Magic Jammer": 2, "Sakuretsu Armor": 1, "Solemn Judgment": 1, "Draining Shield": 1, "Damage Diet": 1, "Adhesion Trap Hole": 1, "Chaos Trap Hole": 1, "Rising Energy": 1, "Chain Disappearance": 1, "A Hero Emerges": 1, "Forbidden Lance": 1, "Wall of Revealing Light": 1, "Windstorm of Etaqua": 1}},
	"deck_worm": {"name": "The Worm Invasion", "cards": {"Worm Xex": 3, "Worm Yagan": 2, "Worm Opera": 2, "Worm Linx": 2, "Worm Ugly": 1, "Worm Gulse": 2, "Worm Rakuyeh": 2, "Worm Solid": 1, "Worm Tentacles": 1, "Worm Jetelikpse": 1, "Worm Falco": 1, "Worm Prince": 1, "Worm King": 1, "Worm Queen": 1, "Worm Warlord": 1, "Worm Noble": 1, "Worm Hope": 1, "Worm Bait": 2, "Worm Call": 2, "Pot of Duality": 1, "Sakuretsu Armor": 1, "Bottomless Trap Hole": 1, "Torrential Tribute": 1, "Call of the Haunted": 1, "Dark Mirror Force": 1, "Jar of Greed": 1, "Floodgate Trap Hole": 1, "Treacherous Trap Hole": 1, "Ego Boost": 1, "Magic Drain": 1, "Raigeki Break": 1},
		"extra": {"Worm Zero": 1}},
	"deck_swarm": {"name": "Swarm of the Lswarm", "cards": {"Steelswarm Caller": 2, "Steelswarm Scout": 1, "Steelswarm Sentinel": 2, "Steelswarm Genome": 1, "Steelswarm Sting": 2, "Steelswarm Gatekeeper": 1, "Steelswarm Mantis": 1, "Steelswarm Moth": 1, "Steelswarm Girastag": 1, "Steelswarm Caucastag": 1, "Evilswarm Castor": 3, "Evilswarm Mandragora": 2, "Evilswarm Salamandra": 2, "Evilswarm Kerykeion": 2, "Evilswarm Heliotrope": 1, "Infestation Pandemic": 2, "First Step Towards Infestation": 2, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Infestation Wave": 2, "Infestation Infection": 1, "Infestation Terminus": 2, "Infestation Ripples": 2, "Torrential Tribute": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Rush Recklessly": 1},
		"extra": {"Evilswarm Ophion": 1, "Evilswarm Bahamut": 1, "Evilswarm Ouroboros": 1, "Evilswarm Thanatos": 1, "Evilswarm Exciton Knight": 1, "Steelswarm Roach": 1, "Evilswarm Nightmare": 1}},
	"deck_vylon": {"name": "Vylon Assembly", "cards": {"Vylon Stigma": 2, "Vylon Prism": 2, "Vylon Ohm": 2, "Vylon Hept": 1, "Vylon Soldier": 1, "Vylon Charger": 2, "Vylon Vanguard": 2, "Vylon Cube": 2, "Vylon Tetra": 2, "Vylon Sphere": 2, "Vylon Stella": 2, "Vylon Tesseract": 1, "Vylon Pentachloro": 1, "Vylon Material": 1, "Vylon Element": 2, "Vylon Component": 1, "Vylon Polytope": 1, "Vylon Segment": 2, "Vylon Filament": 2, "Vylon Matter": 2, "Monster Reborn": 1, "Dimensional Prison": 1, "Compulsory Evacuation Device": 1, "Mirror Force": 1, "Solemn Judgment": 1, "Spell Shield Type-8": 1, "Forbidden Chalice": 1},
		"extra": {"Vylon Alpha": 1, "Vylon Delta": 1, "Vylon Epsilon": 1, "Vylon Omega": 1, "Vylon Sigma": 1, "Vylon Disigma": 1}},
	"deck_gishki": {"name": "The Aquamirror", "cards": {"Gishki Ariel": 2, "Gishki Avance": 1, "Gishki Beast": 1, "Gishki Chain": 2, "Gishki Diviner": 1, "Gishki Marker": 1, "Gishki Mollusk": 1, "Gishki Noellia": 2, "Gishki Shadow": 2, "Gishki Vision": 2, "Gishki Natalia": 1, "Gishki Emilia": 1, "Evigishki Gustkraken": 2, "Evigishki Levianima": 1, "Evigishki Soul Ogre": 1, "Evigishki Mind Augus": 1, "Gishki Psychelone": 1, "Evigishki Tetrogre": 1, "Gishki Aquamirror": 3, "Contact with the Aquamirror": 2, "Forbidden Arts of the Gishki": 2, "Mystical Space Typhoon": 1, "Salvage": 1, "Aquamirror Illusion": 2, "Aquamirror Cycle": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Evigishki Merrowgeist": 1}},
	"deck_watt": {"name": "Wattage", "cards": {"Wattcobra": 2, "Wattgiraffe": 2, "Wattpheasant": 2, "Wattkiwi": 2, "Wattsquirrel": 2, "Wattwoodpecker": 2, "Wattdragonfly": 2, "Wattfox": 2, "Wattlemur": 2, "Wattmole": 1, "Wattberyx": 1, "Wattsychic Fighter": 2, "Wattaildragon": 1, "Wattkid": 1, "Watthopper": 1, "Wattbetta": 1, "Wattcube": 1, "Wattjustment": 1, "Wattkey": 2, "Wattcastle": 2, "Mystical Space Typhoon": 1, "Wattcannon": 2, "Wattkeeper": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Wattchimera": 1, "Watthydra": 1}},
	"deck_laval": {"name": "Laval Eruption", "cards": {"Laval Volcano Handmaiden": 2, "Laval Lakeside Lady": 2, "Laval Forest Sprite": 2, "Laval Phlogis": 2, "Laval Magma Cannoneer": 2, "Laval Warrior": 2, "Laval Cannon": 2, "Laval Blaster": 2, "Laval Burner": 2, "Laval Coatl": 2, "Laval Miller": 2, "Laval Lancelord": 1, "Laval Judgment Lord": 1, "Pot of Duality": 1, "Dark Hole": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Sakuretsu Armor": 1, "Half Unbreak": 1, "Zero Gravity": 1, "Shrink": 1, "Hammer Shot": 1, "Lost Wind": 1, "Enemy Controller": 1, "Deep Dark Trap Hole": 1, "Soul Taker": 1, "Mind Control": 1, "Smashing Ground": 1, "Graceful Revival": 1},
		"extra": {"Laval Dual Slasher": 1, "Laval Stennon": 1, "Laval the Greater": 1, "Lavalval Dragon": 1, "Lavalval Dragun": 1, "Lavalval Ignis": 1, "Lavalval Chain": 1}},
	"deck_ally_justice": {"name": "Allies of Justice", "cards": {"Ally of Justice Garadholg": 2, "Ally of Justice Cycle Reader": 2, "Ally of Justice Clausolas": 1, "Ally of Justice Core Destroyer": 2, "Ally of Justice Cosmic Gateway": 1, "Ally of Justice Cyclone Creator": 2, "Ally of Justice Enemy Catcher": 1, "Ally of Justice Nullfier": 2, "Ally of Justice Omni-Weapon": 1, "Ally of Justice Quarantine": 2, "Ally of Justice Reverse Break": 2, "Ally of Justice Searcher": 2, "Ally of Justice Thousand Arms": 2, "Ally of Justice Thunder Armor": 1, "Ally of Justice Unknown Crusher": 2, "Ally of Justice Unlimiter": 1, "Pot of Duality": 1, "Dark Hole": 1, "Mirror Force": 1, "Dimensional Prison": 1, "Compulsory Evacuation Device": 1, "Widespread Ruin": 1, "Magic Jammer": 1, "Karma Cut": 1, "Miracle's Wake": 1, "Seven Tools of the Bandit": 1, "Battle Break": 1, "Mirror Wall": 1, "Pot of Avarice": 1, "Storming Mirror Force": 1},
		"extra": {"Ally of Justice Catastor": 1, "Ally of Justice Decisive Armor": 1, "Ally of Justice Field Marshal": 1, "Ally of Justice Light Gazer": 1}},
	"deck_flamvell": {"name": "Flamvell Fire", "cards": {"Flamvell Guard": 2, "Flamvell Poun": 2, "Flamvell Baby": 2, "Flamvell Archer": 2, "Flamvell Firedog": 2, "Flamvell Grunika": 2, "Flamvell Fiend": 1, "Flamvell Commando": 1, "Neo Flamvell Garuda": 2, "Neo Flamvell Hedgehog": 2, "Neo Flamvell Origin": 2, "Neo Flamvell Sabre": 2, "Neo Flamvell Shaman": 2, "Monster Reborn": 1, "Pot of Duality": 1, "Dark Hole": 1, "Flamvell Counter": 2, "Sakuretsu Armor": 1, "Dark Bribe": 1, "Defense Draw": 1, "Staunch Defender": 1, "Scrap-Iron Scarecrow": 1, "Xyz Reborn": 1, "Spellbinding Circle": 1, "Dust Tornado": 1, "Fissure": 1, "Acid Trap Hole": 1, "Scapegoat": 1},
		"extra": {"Ancient Flamvell Deity": 1}},
	"deck_reptilianne": {"name": "Reptilianne Den", "cards": {"Reptilianne Naga": 2, "Reptilianne Servant": 2, "Reptilianne Viper": 2, "Reptilianne Gardna": 2, "Reptilianne Gorgon": 3, "Reptilianne Scylla": 3, "Reptilianne Medusa": 1, "Reptilianne Vaskii": 1, "Sinister Serpent": 1, "Reptilianne Spawn": 2, "Reptilianne Rage": 2, "Reptilianne Poison": 2, "Pot of Duality": 1, "Sakuretsu Armor": 1, "Negate Attack": 1, "Magic Jammer": 2, "Shadow Spell": 1, "Breakthrough Skill": 1, "Impenetrable Attack": 1, "Safe Zone": 1, "Quaking Mirror Force": 1, "Void Trap Hole": 1, "Soul Exchange": 1, "Time-Space Trap Hole": 1, "Creature Swap": 1, "Drowning Mirror Force": 1, "Offerings to the Doomed": 1, "Giant Trap Hole": 1},
		"extra": {"Reptilianne Hydra": 1}},
	"deck_evol": {"name": "Evolution of the Dinosaurs", "cards": {"Evoltile Westlo": 2, "Evoltile Odonto": 2, "Evoltile Najasho": 1, "Evoltile Lagosucho": 2, "Evoltile Casinerio": 1, "Evoltile Elginero": 1, "Evoltile Pleuro": 1, "Evoltile Gephyro": 1, "Evolsaur Cerato": 2, "Evolsaur Diplo": 2, "Evolsaur Vulcano": 2, "Evolsaur Pelta": 1, "Evolsaur Darwino": 1, "Evolsaur Terias": 1, "Evolsaur Elias": 1, "Evo-Force": 2, "Evo-Karma": 1, "Evo-Miracle": 2, "Evo-Diversity": 1, "Evo-Price": 2, "Evo-Singularity": 2, "Evo-Branch": 2, "Evo-Instant": 2, "Evolutionary Bridge": 2, "Nightmare Wheel": 1, "Fiendish Chain": 1, "Starlight Road": 1},
		"extra": {"Evolzar Laggia": 1, "Evolzar Dolkka": 1, "Evolzar Solda": 1}},
	"deck_phantom_beast": {"name": "Mecha Phantom Beasts", "cards": {"Mecha Phantom Beast Blackfalcon": 2, "Mecha Phantom Beast Coltwing": 2, "Mecha Phantom Beast Harrliard": 2, "Mecha Phantom Beast Megaraptor": 2, "Mecha Phantom Beast Sabre Hawk": 1, "Mecha Phantom Beast Tetherwolf": 2, "Mecha Phantom Beast Aerosguin": 2, "Mecha Phantom Beast Blue Impala": 2, "Mecha Phantom Beast Hamstrat": 2, "Mecha Phantom Beast Stealthray": 1, "Mecha Phantom Beast Turtletracer": 1, "Mecha Phantom Beast O-Lion": 2, "Mecha Phantom Beast Warbluran": 1, "Mecha Phantom Beast Kalgriffin": 1, "Gazelle the King of Mythical Beasts": 1, "Phantom Beast Wild-Horn": 1, "Pot of Duality": 1, "Horn of the Phantom Beast": 2, "Blazing Mirror Force": 1, "Divine Wrath": 1, "Reckless Greed": 1, "Lightning Vortex": 1, "Karma Cut": 1, "Pot of Avarice": 1, "Shrink": 1, "Starlight Road": 1, "Xyz Reborn": 1, "Deep Dark Trap Hole": 1, "Fissure": 1, "Shadow Spell": 1},
		"extra": {"Mecha Phantom Beast Dracossack": 1, "Mecha Phantom Beast Concoruda": 1}},
	"deck_noble_knight": {"name": "Knights of the Round Table", "cards": {"Noble Knight Artorigus": 2, "Noble Knight Gawayn": 2, "Noble Knight Medraut": 2, "Noble Knight Drystan": 2, "Noble Knight Peredur": 1, "Noble Knight Borz": 2, "Noble Knight Joan": 2, "Noble Knight Gwalchavad": 2, "Noble Knight Eachtar": 1, "Noble Knight Brothers": 1, "Gwenhwyfar, Queen of Noble Arms": 1, "Ignoble Knight of Black Laundsallyn": 1, "Noble Arms - Caliburn": 2, "Noble Arms - Gallatin": 2, "Noble Arms - Arfeudutyr": 2, "Noble Arms - Excaliburn": 2, "Noble Arms of Destiny": 2, "Noble Knights of the Round Table": 2, "Celestial Sword - Eatos": 2, "Reinforcement of the Army": 1, "Scapegoat": 1, "Dark Bribe": 1, "Malevolent Catastrophe": 1, "Hammer Shot": 1, "Adhesion Trap Hole": 1, "Safe Zone": 1},
		"extra": {"Artorigus, King of the Noble Knights": 1, "Sacred Noble Knight of King Artorigus": 1, "Ignoble Knight of High Laundsallyn": 1}},
	"deck_gears": {"name": "Gears and Rails", "cards": {"Geargiano": 2, "Geargiano Mk-II": 2, "Geargiano Mk-III": 1, "Geargiarmor": 3, "Geargiattacker": 2, "Geargiarsenal": 2, "Geargiaccelerator": 2, "Geargiauger": 1, "Construction Train Signal Red": 1, "Express Train Trolley Olley": 1, "Ruffian Railcar": 1, "Lionhearted Locomotive": 1, "Night Express Knight": 1, "Rocket Arrow Express": 1, "Snow Plow Hustle Rustle": 1, "Train Connection": 2, "Special Schedule": 2, "Pot of Duality": 1, "Geargiagear": 2, "Sakuretsu Armor": 1, "Miracle's Wake": 1, "Mirror Wall": 1, "Rush Recklessly": 1, "Graceful Revival": 1, "Ego Boost": 1, "Dust Tornado": 1, "Soul Exchange": 1, "Phoenix Wing Wind Blast": 1, "Half Unbreak": 1, "Scrap-Iron Scarecrow": 1},
		"extra": {"Geargiagear Gigant XG": 1, "Superdreadnought Rail Cannon Gustav Max": 1, "Number 81: Superdreadnought Rail Cannon Super Dora": 1}},
	"deck_inzektor": {"name": "Inzektor Hive", "cards": {"Inzektor Dragonfly": 3, "Inzektor Hornet": 3, "Inzektor Centipede": 2, "Inzektor Ladybug": 2, "Inzektor Firefly": 1, "Inzektor Ant": 1, "Inzektor Earwig": 1, "Inzektor Hopper": 1, "Inzektor Giga-Mantis": 1, "Inzektor Giga-Weevil": 1, "Inzektor Giga-Cricket": 1, "Inzektor Sword - Zektkaliber": 2, "Inzektor Axe - Zektahawk": 2, "Inzektor Crossbow - Zektarrow": 2, "Pot of Duality": 1, "Inzektor Orb": 2, "Inzektor Gauntlet": 2, "Sakuretsu Armor": 1, "Magic Jammer": 2, "Drowning Mirror Force": 1, "Defense Draw": 1, "Breakthrough Skill": 1, "Divine Wrath": 1, "Jar of Greed": 1, "Zero Gravity": 1, "Dark Mirror Force": 1, "Floodgate Trap Hole": 1, "Windstorm of Etaqua": 1},
		"extra": {"Inzektor Exa-Beetle": 1, "Inzektor Exa-Stag": 1}},
	"deck_hazy": {"name": "Hazy Flame and Fire Kings", "cards": {"Hazy Flame Cerbereus": 2, "Hazy Flame Griffin": 2, "Hazy Flame Hydra": 1, "Hazy Flame Hyppogrif": 2, "Hazy Flame Mantikor": 2, "Hazy Flame Peryton": 2, "Hazy Flame Sphynx": 2, "Fire King Avatar Barong": 2, "Fire King Avatar Garunix": 2, "Fire King Avatar Kirin": 2, "Fire King Avatar Yaksha": 2, "Fire King High Avatar Garunix": 1, "Hazy Pillar": 2, "Circle of the Fire Kings": 2, "Onslaught of the Fire Kings": 2, "Hazy Glory": 2, "Sakuretsu Armor": 1, "Threatening Roar": 1, "Battle Break": 1, "Impenetrable Attack": 1, "Void Trap Hole": 1, "Magic Jammer": 1, "Raigeki Break": 1, "Time-Space Trap Hole": 1, "Offerings to the Doomed": 1, "Spellbinding Circle": 1},
		"extra": {"Hazy Flame Basiltrice": 1}},
	"deck_hieratic": {"name": "Hieratic Dynasty", "cards": {"Hieratic Dragon of Tefnuit": 2, "Hieratic Dragon of Su": 2, "Hieratic Dragon of Gebeb": 2, "Hieratic Dragon of Nuit": 2, "Hieratic Dragon of Eset": 2, "Hieratic Dragon of Nebthet": 2, "Hieratic Dragon of Asar": 1, "Hieratic Dragon of Sutekh": 1, "Hieratic Seal of the Dragon King": 1, "Hieratic Seal of the Sun Dragon Overlord": 1, "Alexandrite Dragon": 2, "Hieratic Seal of Convocation": 2, "Hieratic Seal of Supremacy": 2, "Pot of Duality": 1, "Hieratic Seal From the Ashes": 2, "Hieratic Seal of Banishment": 2, "Hieratic Seal of Reflection": 2, "Sakuretsu Armor": 1, "Fiendish Chain": 1, "Forbidden Chalice": 1, "Soul Taker": 1, "Giant Trap Hole": 1, "Blazing Mirror Force": 1, "Enemy Controller": 1, "Staunch Defender": 1, "Acid Trap Hole": 1, "Spell Shield Type-8": 1, "Treacherous Trap Hole": 1},
		"extra": {"Hieratic Dragon King of Atum": 1, "Hieratic Sun Dragon Overlord of Heliopolis": 1}},
	"deck_artifact": {"name": "Artifact Armory", "cards": {"Artifact Moralltach": 2, "Artifact Beagalltach": 2, "Artifact Caduceus": 2, "Artifact Failnaught": 2, "Artifact Labrys": 2, "Artifact Scythe": 1, "Artifact Achilleshield": 2, "Artifact Aegis": 1, "Artifact Ignition": 2, "Artifacts Unleashed": 2, "Pot of Duality": 1, "Artifact Sanctum": 2, "Sakuretsu Armor": 1, "Magic Jammer": 2, "Negate Attack": 1, "Mind Control": 1, "Chaos Trap Hole": 1, "A Hero Emerges": 1, "Draining Shield": 1, "Reckless Greed": 1, "Creature Swap": 1, "Widespread Ruin": 1, "Rising Energy": 1, "Magic Drain": 1, "Wall of Revealing Light": 1, "Seven Tools of the Bandit": 1, "Forbidden Lance": 1, "Storming Mirror Force": 1, "Lightning Vortex": 1, "Quaking Mirror Force": 1},
		"extra": {"Artifact Durendal": 1}},
	"deck_heraldic": {"name": "Heraldic Beasts", "cards": {"Heraldic Beast Leo": 2, "Heraldic Beast Aberconway": 2, "Heraldic Beast Basilisk": 2, "Heraldic Beast Berners Falcon": 2, "Heraldic Beast Eale": 2, "Heraldic Beast Twin-Headed Eagle": 2, "Heraldic Beast Unicorn": 2, "Gene-Warped Warwolf": 2, "Heraldry Reborn": 2, "Augmented Heraldry": 2, "Advanced Heraldry Art": 2, "Pot of Duality": 1, "Heraldry Change": 2, "Heraldry Record": 2, "Sakuretsu Armor": 1, "Magic Jammer": 2, "Negate Attack": 1, "Chain Disappearance": 1, "Lost Wind": 1, "Nightmare Wheel": 1, "Smashing Ground": 1, "Damage Diet": 1, "Storming Mirror Force": 1, "Fiendish Chain": 1, "Ego Boost": 1, "Dust Tornado": 1},
		"extra": {"Number 8: Heraldic King Genom-Heritage": 1, "Number 18: Heraldry Patriarch": 1, "Number 69: Heraldry Crest": 1, "Number C69: Heraldry Crest of Horror": 1}},
	"deck_sylvan": {"name": "Sylvan Grove", "cards": {"Sylvan Marshalleaf": 2, "Sylvan Komushroomo": 2, "Sylvan Peaskeeper": 2, "Sylvan Cherubsprout": 2, "Sylvan Mikorange": 2, "Sylvan Hermitree": 2, "Sylvan Snapdrassinagon": 2, "Sylvan Sagequoia": 1, "Sylvan Lotuswain": 1, "Sylvan Guardioak": 1, "Sylvan Bladefender": 1, "Sylvan Flowerknight": 1, "Sylvan Princessprout": 1, "Mount Sylvania": 2, "Sylvan Charity": 2, "Pot of Duality": 1, "Sylvan Waterslide": 2, "Sylvan Blessing": 2, "Forbidden Chalice": 1, "Jar of Greed": 1, "Adhesion Trap Hole": 1, "Defense Draw": 1, "Smashing Ground": 1, "Lost Wind": 1, "Pot of Avarice": 1, "Soul Exchange": 1, "Malevolent Catastrophe": 1, "Battle Break": 1, "Dark Mirror Force": 1},
		"extra": {"Alsei, the Sylvan High Protector": 1, "Orea, the Sylvan High Arbiter": 1}},
	"deck_branded": {"name": "Branded Despia", "cards": {"Fallen of Albaz": 3, "Aluber the Jester of Despia": 3, "Despian Tragedy": 1, "Despian Comedy": 1, "Guiding Quem, the Virtuous": 1, "Albion the Shrouded Dragon": 1, "The Bystial Aluber": 1, "Bystial Magnamhut": 1, "Bystial Saronir": 1, "Albaz the Ashen": 1, "Ash Blossom & Joyous Spring": 2, "Branded Fusion": 3, "Branded Opening": 2, "Branded in Red": 1, "Branded Lost": 1, "Branded in High Spirits": 1, "Branded Regained": 1, "Despia, Theater of the Branded": 1, "Called by the Grave": 1, "Branded Bond": 1, "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Branded Retribution": 2, "Branded Expulsion": 1, "Branded Banishment": 2, "Branded Beast": 1, "Infinite Impermanence": 2, "Branded Sword": 1, "Screams of the Branded": 1},
		"extra": {"Mirrorjade the Iceblade Dragon": 1, "Albion the Branded Dragon": 2, "Titaniklad the Ash Dragon": 1, "Lubellion the Searing Dragon": 1, "Granguignol the Dusk Dragon": 1, "Brigrand the Glory Dragon": 1, "Alba-Lenatus the Abyss Dragon": 1, "Sprind the Irondash Dragon": 1, "Despian Quaeritis": 1, "Rindbrumm the Striking Dragon": 1, "Masquerade the Blazing Dragon": 1, "Despian Luluwalilith": 1}},
	"deck_drytron": {"name": "Drytron Constellation", "cards": {"Drytron Alpha Thuban": 3, "Drytron Beta Rastaban": 2, "Drytron Gamma Eltanin": 2, "Drytron Zeta Aldhibah": 3, "Drytron Delta Altais": 1, "Drytron Meteonis Draconids": 2, "Drytron Meteonis Quadrantids": 1, "Ash Blossom & Joyous Spring": 3, "Ghost Ogre & Snow Rabbit": 1, "Meteonis Drytron": 3, "Drytron Nova": 2, "Drytron Fafnir": 1, "Drytron Asterism": 1, "Drytron Eclipse": 1, "Pot of Prosperity": 1, "Called by the Grave": 1, "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Drytron Meteor Shower": 2, "Dimensional Barrier": 1, "Solemn Judgment": 1, "Infinite Impermanence": 3, "Solemn Strike": 1, "Evenly Matched": 1, "Torrential Tribute": 1},
		"extra": {"Drytron Mu Beta Fafnir": 2, "Divine Arsenal AA-ZEUS - Sky Thunder": 1}},
	"deck_dragonmaid": {"name": "Dragonmaid Household", "cards": {"Kitchen Dragonmaid": 3, "Nurse Dragonmaid": 3, "Laundry Dragonmaid": 3, "Parlor Dragonmaid": 2, "Chamber Dragonmaid": 2, "Dragonmaid Lorpar": 1, "Dragonmaid Tinkhec": 1, "Dragonmaid Ernus": 1, "Dragonmaid Nudyarl": 1, "Ash Blossom & Joyous Spring": 2, "Dragonmaid Welcome": 1, "Dragonmaid Changeover": 3, "Dragonmaid Hospitality": 1, "Dragonmaid Send-Off": 1, "Called by the Grave": 1, "Pot of Prosperity": 1, "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Polymerization": 1, "Dragonmaid Tidying": 2, "Dragonmaid Downtime": 1, "Dimensional Barrier": 1, "Ice Dragon's Prison": 1, "Infinite Impermanence": 2, "Solemn Strike": 1, "Evenly Matched": 1, "Torrential Tribute": 1},
		"extra": {"House Dragonmaid": 2, "Dragonmaid Sheou": 2}},
	"deck_swordsoul": {"name": "Swordsoul Mountain", "cards": {"Swordsoul of Mo Ye": 3, "Swordsoul of Taia": 3, "Swordsoul Strategist Longyuan": 3, "Swordsoul Auspice Chunjun": 1, "The Iris Swordsoul": 1, "The Golden Swordsoul": 1, "Ash Blossom & Joyous Spring": 3, "Ghost Belle & Haunted Mansion": 1, "Droll & Lock Bird": 1, "Swordsoul Emergence": 3, "Swordsoul Sacred Summit": 2, "Called by the Grave": 1, "Pot of Prosperity": 2, "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Swordsoul Punishment": 1, "Swordsoul Strife": 2, "Swordsoul Blackout": 2, "Swordsoul Assessment": 1, "Dimensional Barrier": 1, "Infinite Impermanence": 3, "Solemn Strike": 1, "Evenly Matched": 1, "Torrential Tribute": 1},
		"extra": {"Swordsoul Grandmaster - Chixiao": 2, "Swordsoul Supreme Sovereign - Chengying": 2, "Swordsoul Sinister Sovereign - Qixing Longyuan": 1, "Baronne de Fleur": 1, "Crystal Wing Synchro Dragon": 1, "Stardust Dragon": 1, "Herald of the Arc Light": 1, "Tri-Edge Master": 1, "Coral Dragon": 1, "Ravenous Crocodragon Archethys": 1, "Groza, Tyrant of Thunder": 1}},
	"deck_witchcrafter": {"name": "Witchcrafter Atelier", "cards": {"Witchcrafter Genni": 3, "Witchcrafter Potterie": 2, "Witchcrafter Pittore": 3, "Witchcrafter Schmietta": 3, "Witchcrafter Edel": 1, "Witchcrafter Haine": 2, "Witchcrafter Madame Verre": 2, "Witchcrafter Golem Aruru": 1, "Ash Blossom & Joyous Spring": 2, "Witchcrafter Creation": 3, "Witchcrafter Holiday": 2, "Witchcrafter Confusion Confession": 1, "Witchcrafter Collaboration": 1, "Witchcrafter Draping": 1, "Witchcrafter Scroll": 1, "Witchcrafter Bystreet": 1, "Witchcrafter Unveiling": 1, "Called by the Grave": 1, "Dark Ruler No More": 1, "Witchcrafter Masterpiece": 1, "Witchcrafter Patronus": 1, "Dimensional Barrier": 1, "Infinite Impermanence": 2, "Solemn Strike": 1, "Evenly Matched": 1, "Torrential Tribute": 1},
		"extra": {"Witchcrafter Vice-Madame": 2, "Abyss Dweller": 1}},
	"deck_true_draco": {"name": "True Draco Throne", "cards": {"Master Peace, the True Dracoslayer": 2, "Master Peace, the True Dracoslaying King": 1, "Dinomight Knight, the True Dracofighter": 2, "Ignis Heat, the True Dracowarrior": 2, "Majesty Maiden, the True Dracocaster": 2, "Dreiath III, the True Dracocavalry General": 1, "Metaltron XII, the True Dracombatant": 1, "True King Agnimazud, the Vanisher": 2, "True King Bahrastos, the Fathomer": 1, "True King Lithosagym, the Disaster": 1, "Mariamne, the True Dracophoenix": 1, "Ash Blossom & Joyous Spring": 2, "True Draco Heritage": 1, "Disciples of the True Dracophoenix": 1, "Dragonic Diagram": 3, "Pot of Prosperity": 1, "Called by the Grave": 1, "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Foolish Burial Goods": 1, "Monster Reborn": 1, "True Draco Apocalypse": 2, "True King's Return": 2, "Solemn Judgment": 1, "Ice Dragon's Prison": 1, "Infinite Impermanence": 2, "Solemn Strike": 1, "Evenly Matched": 1, "Torrential Tribute": 1},
		"extra": {"True King of All Calamities": 1}},
	"deck_cipher": {"name": "Cipher Squadron", "cards": {"Cipher Wing": 3, "Cipher Twin Raptor": 3, "Cipher Mirror Knight": 2, "Cipher Biplane": 2, "Cipher Etranger": 2, "Photon Thrasher": 2, "Galaxy Soldier": 2, "Photon Vanisher": 1, "Cipher Soldier": 2, "Ash Blossom & Joyous Spring": 2, "Double Cipher": 2, "Cipher Interference": 1, "Double Exposure": 1, "Rank-Up-Magic Cipher Ascension": 1, "Galaxy Expedition": 1, "Called by the Grave": 1, "Pot of Prosperity": 1, "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Cipher Spectrum": 2, "Dimensional Barrier": 1, "Cipher Bit": 1, "Infinite Impermanence": 2, "Solemn Strike": 1, "Evenly Matched": 1, "Torrential Tribute": 1},
		"extra": {"Galaxy-Eyes Cipher Dragon": 2, "Neo Galaxy-Eyes Cipher Dragon": 1, "Number 62: Galaxy-Eyes Prime Photon Dragon": 1, "Abyss Dweller": 1, "Number 39: Utopia": 1}},
	"deck_monarchs": {"name": "Rule of the Monarchs", "cards": {"Caius the Shadow Monarch": 2, "Zaborg the Thunder Monarch": 2, "Mobius the Frost Monarch": 1, "Raiza the Storm Monarch": 1,
		"Thestalos the Firestorm Monarch": 1, "Granmarg the Rock Monarch": 1, "Kuraz the Light Monarch": 1, "Eidos the Underworld Monarch": 1, "Caius the Mega Monarch": 1,
		"Zaborg the Mega Monarch": 1, "Erebus the Underworld Monarch": 1, "Ehther the Heavenly Monarch": 1, "Edea the Heavenly Squire": 2, "Eidos the Underworld Squire": 2,
		"Tessera the Primal Squire": 1, "Mithra the Thunder Vassal": 1, "Garum the Storm Vassal": 1, "Berlineth the Firestorm Vassal": 1,
		"Pantheism of the Monarchs": 2, "Tenacity of the Monarchs": 2, "March of the Monarchs": 1, "Return of the Monarchs": 1, "The Monarchs Masterplan": 1,
		"The Monarchs Stormforth": 1, "Restoration of the Monarchs": 1, "Domain of the True Monarchs": 1, "Strike of the Monarchs": 1, "Frost Blast of the Monarchs": 1,
		"The Monarchs Revolt": 1, "Escalation of the Monarchs": 1, "The Prime Monarch": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1}},
	"deck_chaos": {"name": "Envoys of Chaos", "cards": {"Black Luster Soldier - Envoy of the Beginning": 1, "Chaos Sorcerer": 1, "Black Luster Soldier - Envoy of the Evening Twilight": 1,
		"Black Luster Soldier - Super Soldier": 2, "Black Luster Soldier - Legendary Swordsman": 1, "Black Luster Soldier": 1, "Black Luster Soldier - Sacred Soldier": 1,
		"Beginning Knight": 2, "Evening Twilight Knight": 2, "Super Soldier Soul": 1, "Envoy of Chaos": 1, "Charging Gaia the Fierce Knight": 2, "Arisen Gaia the Fierce Knight": 1,
		"Gaia the Fierce Knight Origin": 1, "Gaia, the Mid-Knight Sun": 1, "Gaia, the Polar Knight": 1, "Gaia The Fierce Knight": 1, "Chaos Valkyria": 1, "Curse of Dragon": 1,
		"Super Soldier Ritual": 3, "Chaos Form": 2, "Super Soldier Synthesis": 1, "Gateway to Chaos": 2, "Black Luster Ritual": 1, "Galloping Gaia": 1, "Chaos Space": 1,
		"Monster Reborn": 1, "Pot of Greed": 1, "Super Soldier Rebirth": 1, "Beginning of Heaven and Earth": 1, "Spiral Spear Strike": 1, "Super Soldier Shield": 1},
		"extra": {"Gaia the Dragon Champion": 1, "Sky Galloping Gaia the Dragon Champion": 2, "Gaia the Magical Knight of Dragons": 2}},
	"deck_gem_knight": {"name": "Brilliant Gems", "cards": {"Gem-Knight Garnet": 2, "Gem-Knight Sapphire": 2, "Gem-Knight Tourmaline": 2, "Gem-Knight Lapis": 1,
		"Gem-Knight Alexandrite": 2, "Gem-Knight Nepyrim": 2, "Gem-Knight Quartz": 1, "Gem-Knight Obsidian": 1, "Gem-Knight Lazuli": 1, "Gem-Knight Emerald": 1,
		"Gem-Armadillo": 2, "Brilliant Rose": 1, "Crystal Rose": 1, "Gem-Knight Sardonyx": 1, "Gem-Knight Amber": 1, "Gem-Knight Iolite": 1,
		"Gem-Knight Hollowcore": 1, "Gem-Turtle": 1, "Gem-Merchant": 1,
		"Gem-Knight Fusion": 3, "Brilliant Fusion": 1, "Particle Fusion": 1, "Absorb Fusion": 1, "Gem-Knight Dispersion": 1, "Scatter Fusion": 1,
		"Pot of Greed": 1, "Monster Reborn": 1, "Pyroxene Fusion": 1, "Fragment Fusion": 1, "Brilliant Spark": 1, "Gem-Enhancement": 1, "Mystical Space Typhoon": 1},
		"extra": {"Gem-Knight Ruby": 2, "Gem-Knight Topaz": 1, "Gem-Knight Aquamarine": 1, "Gem-Knight Lady Lapis Lazuli": 1, "Gem-Knight Zirconia": 1,
		"Gem-Knight Citrine": 1, "Gem-Knight Prismaura": 1, "Gem-Knight Amethyst": 1, "Gem-Knight Seraphinite": 1, "Gem-Knight Lady Brilliant Diamond": 1,
		"Gem-Knight Master Diamond": 1, "Gem-Knight Master Diamond Dispersion": 1, "Gem-Knight Lady Rose Diamond": 1, "Gem-Knight Pearl": 1}},
	"deck_lightsworn": {"name": "Light of Judgment", "cards": {"Lightsworn Judgment": 1, "Lightsworn Barrier": 1, "Judgment Dragon": 2, "Wulf, Lightsworn Beast": 3, "Ryko, Lightsworn Hunter": 2, "Lumina, Lightsworn Summoner": 2,
		"Lyla, Lightsworn Sorceress": 2, "Garoth, Lightsworn Warrior": 2, "Jain, Lightsworn Paladin": 1, "Ehren, Lightsworn Monk": 1, "Aurkus, Lightsworn Druid": 1,
		"Celestia, Lightsworn Angel": 1, "Raiden, Hand of the Lightsworn": 2, "Felis, Lightsworn Archer": 2, "Minerva, Lightsworn Maiden": 1, "Gragonith, Lightsworn Dragon": 1,
		"Lightsworn Dragonling": 1,
		"Charge of the Light Brigade": 3, "Solar Recharge": 2, "Realm of Light": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Lightsworn Sabre": 1,
		"March of the Dark Brigade": 1, "Mystical Space Typhoon": 1,
		"Glorious Illusion": 1, "Vanquishing Light": 1, "Torrential Tribute": 1},
		"extra": {"Minerva, the Athenian Lightsworn": 1, "Michael, the Arch-Lightsworn": 2, "Minerva, the Exalted Lightsworn": 2, "Lightning Warrior": 1, "Colossal Fighter": 1}},
	"deck_gravekeeper": {"name": "Valley of the Kings", "cards": {"Gravekeeper's Trap": 1, "Gravekeeper's Spy": 3, "Gravekeeper's Guard": 2, "Gravekeeper's Spear Soldier": 2,
		"Gravekeeper's Curse": 2, "Gravekeeper's Assailant": 2, "Gravekeeper's Commandant": 2, "Gravekeeper's Recruiter": 2, "Gravekeeper's Descendant": 1,
		"Gravekeeper's Chief": 2, "Gravekeeper's Cannonholder": 1, "Gravekeeper's Priestess": 1, "Gravekeeper's Visionary": 1, "Gravekeeper's Headman": 1,
		"Gravekeeper's Watcher": 1,
		"Necrovalley": 3, "Terraforming": 1, "Royal Tribute": 1, "Gravekeeper's Stele": 1, "Necrovalley Throne": 2, "Gravekeeper's Servant": 1,
		"Mystical Space Typhoon": 1, "Monster Reborn": 1,
		"Rite of Spirit": 2, "Imperial Tombs of Necrovalley": 1, "Hidden Temples of Necrovalley": 1, "Royal Decree": 1},
		"extra": {"Gravekeeper's Supernaturalist": 2}},
	"deck_forest": {"name": "Overgrowth", "cards": {"Lonefire Blossom": 3, "Dandylion": 2, "Copy Plant": 2, "Dark Verger": 1, "Glow-Up Bulb": 1, "Gigaplant": 1, "Botanical Lion": 2, "Lord Poison": 2, "Mystic Tomato": 2, "Revival Rose": 1, "Rose Fairy": 1, "Tytannial, Princess of Camellias": 1, "Kuwagata α": 1, "Hercules Beetle": 1, "Queen Angel of Roses": 1, "Forest": 2, "Polymerization": 1, "Pot of Greed": 1, "Foolish Burial": 1, "One for One": 1, "Swords of Revealing Light": 1, "Fissure": 2, "Waboku": 1, "Mark of the Rose": 2, "Adhesion Trap Hole": 2, "Gravity Bind": 2, "Treacherous Trap Hole": 1, "Rush Recklessly": 1},
		"extra": {"Splendid Rose": 2, "Queen of Thorns": 1, "Kwagar Hercules": 1, "Lightning Warrior": 1, "Colossal Fighter": 1}},
	"mai": {"name": "Harpie", "cards": {"Harpie Lady": 3, "Harpie Lady 1": 2, "Harpie Lady 2": 2, "Harpie Lady 3": 2, "Cyber Harpie Lady": 2,
		"Harpie's Pet Dragon": 2, "Harpie Girl": 2, "Harpie Queen": 2, "Birdface": 2, "Harpie Channeler": 2,
		"Pot of Greed": 1, "Dian Keto the Cure Master": 1, "Fissure": 2, "Monster Reborn": 1, "Hinotama": 2}},
	"bakura": {"name": "Dark Fiends", "cards": {"Newdoria": 1, "Dark Ruler Ha Des": 2, "Headless Knight": 3, "The Earl of Demise": 2, "Pumpking the King of Ghosts": 2,
		"Summoned Skull": 2, "Ryu-Kishin": 3, "Sangan": 2, "Gernia": 2, "Lord of the Lamp": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Fissure": 2}},
	"marik": {"name": "Rare Hunter", "cards": {"Gil Garth": 2, "Makyura the Destructor": 2, "Revival Jam": 2, "Drillago": 2, "Vampire Lord": 2,
		"Viser Des": 2, "Mystic Lamp": 2, "Stone Statue of the Aztecs": 2, "Bowganian": 2, "Granadora": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Raigeki": 1, "Hinotama": 2}},
	"pegasus": {"name": "Toon", "cards": {"Toon World": 3, "Toon Summoned Skull": 2, "Toon Dark Magician Girl": 2, "Toon Gemini Elf": 2, "Toon Mermaid": 2,
		"Toon Alligator": 3, "Toon Masked Sorcerer": 2, "Toon Goblin Attack Force": 2, "Bickuribox": 2, "Dragon Piper": 2, "Toon Cannon Soldier": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Raigeki": 1}},
	"weevil": {"name": "Insect", "cards": {"Insect Queen": 2, "Basic Insect": 3, "Hercules Beetle": 2, "Killer Needle": 3, "Petit Moth": 2,
		"Leghul": 2, "Pinch Hopper": 2, "Insect Knight": 3, "Neo Bug": 2, "Gokipon": 2,
		"Pot of Greed": 1, "Fissure": 2, "Monster Reborn": 1, "Dian Keto the Cure Master": 2}},
	# Legendary Duels (0.75.0): decks as the duelists had them at that time in the show.
	"legend_jaden_y1": {"name": "Jaden · First Year", "cards": {"Elemental HERO Avian": 3, "Elemental HERO Burstinatrix": 3, "Elemental HERO Clayman": 3,
		"Elemental HERO Sparkman": 3, "Elemental HERO Bubbleman": 2, "Elemental HERO Wildheart": 2, "Elemental HERO Bladedge": 1, "Winged Kuriboh": 2, "Hero Kid": 2,
		"Polymerization": 3, "Miracle Fusion": 1, "Fusion Recovery": 1, "Skyscraper": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Spark Blaster": 1, "Card of Sanctity": 1,
		"Hero Signal": 2, "Hero Barrier": 2, "Draining Shield": 1, "Negate Attack": 1, "A Hero Emerges": 1, "Trap Hole": 1},
		"extra": {"Elemental HERO Flame Wingman": 2, "Elemental HERO Thunder Giant": 2, "Elemental HERO Rampart Blaster": 1, "Elemental HERO Tempest": 1,
		"Elemental HERO Steam Healer": 1, "Elemental HERO Mudballman": 1}},
	"legend_chazz_y1": {"name": "Chazz · First Year", "cards": {"V-Tiger Jet": 3, "W-Wing Catapult": 3, "X-Head Cannon": 3, "Y-Dragon Head": 3, "Z-Metal Tank": 3, "Chthonian Soldier": 2, "Infernal Incinerator": 1, "Mechanicalchaser": 2, "Frontline Base": 2, "Cost Down": 2, "Pot of Greed": 1, "Heavy Storm": 1, "Fissure": 2, "Rush Recklessly": 1, "Union Attack": 2, "Dark Hole": 1, "Magical Mallet": 2, "Ring of Destruction": 1, "Chthonian Polymer": 2, "Dimension Wall": 1, "Sakuretsu Armor": 1, "Desert Sunlight": 1},
		"extra": {"XYZ-Dragon Cannon": 2, "VW-Tiger Catapult": 2, "VWXYZ-Dragon Catapult Cannon": 2, "XY-Dragon Cannon": 1, "XZ-Tank Cannon": 1, "YZ-Tank Dragon": 1}},
	# (0.77.0) Anime decks: the decks the characters played in the show, early and late (DeckTiers.ANIME).
	"anime_yugi_2": {"name": "Yugi · Battle City", "cards": {"Dark Magician": 2, "Dark Magician Girl": 1, "Slifer the Sky Dragon": 1, "Buster Blader": 1, "Black Luster Soldier": 1, "Gazelle the King of Mythical Beasts": 1, "Berfomet": 1, "Big Shield Gardna": 1, "Kuriboh": 2, "Breaker the Magical Warrior": 1, "Skilled Dark Magician": 1, "Watapon": 2, "Magician's Valkyria": 1, "Queen's Knight": 1, "King's Knight": 1, "Jack's Knight": 1, "Black Luster Ritual": 1, "Monster Reborn": 1, "Multiply": 2, "Thousand Knives": 1, "Dark Magic Attack": 1, "Polymerization": 2, "Swords of Revealing Light": 1, "Card of Sanctity": 1, "Brain Control": 1, "Book of Secret Arts": 2, "Mystical Elf": 1, "Celtic Guardian": 1, "Mirror Force": 1, "Magic Cylinder": 1, "Spellbinding Circle": 2, "Magical Hats": 1, "Dark Renewal": 1},
		"extra": {"Chimera the Flying Mythical Beast": 2, "Dark Paladin": 1}},
	"anime_kaiba_2": {"name": "Kaiba · Battle City", "cards": {"Blue-Eyes White Dragon": 3, "Obelisk the Tormentor": 1, "X-Head Cannon": 1, "Y-Dragon Head": 1, "Z-Metal Tank": 1, "Vorse Raider": 2, "Lord of D.": 1, "Kaiser Glider": 1, "Blade Knight": 1, "Battle Ox": 2, "Rude Kaiser": 1, "Swordstalker": 1, "La Jinn the Mystical Genie of the Lamp": 1, "The Flute of Summoning Dragon": 2, "Polymerization": 2, "Monster Reborn": 1, "Shrink": 1, "Enemy Controller": 1, "Interdimensional Matter Transporter": 1, "Silent Doom": 2, "Cost Down": 2, "Fiend's Sanctuary": 1, "Burst Stream of Destruction": 1, "Stop Defense": 1, "Double Summon": 1, "Pot of Greed": 1, "Ring of Destruction": 1, "Crush Card Virus": 1, "Virus Cannon": 2, "Negate Attack": 1, "Mesmeric Control": 1},
		"extra": {"Blue-Eyes Ultimate Dragon": 2, "XYZ-Dragon Cannon": 2}},
	"anime_joey_1": {"name": "Joey · Duelist Kingdom", "cards": {"Flame Manipulator": 1, "Sword Hunter": 1, "Red-Eyes Black Dragon": 1, "Time Wizard": 2, "Baby Dragon": 2, "Battle Warrior": 2, "Rock Ogre Grotto #1": 1, "Swamp Battleguard": 1, "Lava Battleguard": 1, "Garoozis": 1, "Panther Warrior": 2, "Axe Raider": 2, "Alligator's Sword": 2, "Kojikocy": 1, "Masaki the Legendary Swordsman": 1, "Polymerization": 2, "Salamandra": 1, "Shield & Sword": 2, "Graceful Dice": 1, "Skull Dice": 1, "Scapegoat": 2, "Giant Trunade": 1, "Monster Reborn": 1, "Legendary Sword": 1, "Fissure": 1, "Dian Keto the Cure Master": 1, "Graceful Charity": 1, "Kunai with Chain": 2, "Trap Hole": 1, "Waboku": 1},
		"extra": {"Flame Swordsman": 1, "Thousand Dragon": 2, "Alligator's Sword Dragon": 1, "Black Skull Dragon": 1}},
	"anime_joey_2": {"name": "Joey · Battle City", "cards": {"Red-Eyes Black Dragon": 2, "Jinzo": 1, "Gilford the Lightning": 1, "Gearfried the Iron Knight": 2, "Rocket Warrior": 1, "Panther Warrior": 2, "Swordsman of Landstar": 1, "Baby Dragon": 1, "Time Wizard": 1, "Alligator's Sword": 1, "Flame Manipulator": 1, "Masaki the Legendary Swordsman": 1, "Battle Warrior": 1, "Axe Raider": 2, "Red-Eyes Black Metal Dragon": 1, "Kojikocy": 1, "Polymerization": 2, "Graceful Dice": 2, "Skull Dice": 2, "Scapegoat": 1, "Shield & Sword": 1, "Giant Trunade": 1, "Monster Reborn": 1, "Salamandra": 2, "Legendary Sword": 1, "Fissure": 1, "Metalmorph": 1, "Kunai with Chain": 1, "Magic Cylinder": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Just Desserts": 1},
		"extra": {"Black Skull Dragon": 2, "Thousand Dragon": 1, "Alligator's Sword Dragon": 1, "Flame Swordsman": 1}},
	"anime_mai_1": {"name": "Mai · Duelist Kingdom", "cards": {"Harpie Lady": 3, "Harpie Lady Sisters": 2, "Harpie's Pet Dragon": 2, "Mystic Tomato": 2, "Kanan the Swordmistress": 1, "Amazoness Paladin": 1, "Amazoness Fighter": 2, "Amazoness Swords Woman": 2, "Dunames Dark Witch": 2, "Lady Assailant of Flames": 1, "Kuriboh": 1, "Elegant Egotist": 2, "Cyber Shield": 2, "Rising Air Current": 1, "Harpie's Feather Duster": 1, "Monster Reborn": 1, "Swords of Revealing Light": 1, "Rush Recklessly": 2, "Fissure": 2, "Dian Keto the Cure Master": 1, "Mystical Space Typhoon": 1, "Mirror Wall": 2, "Sakuretsu Armor": 1, "Spellbinding Circle": 2, "Stop Defense": 1, "Chain Destruction": 1},
		"extra": {}},
	"anime_mai_2": {"name": "Mai · Battle City", "cards": {"Harpie Lady 1": 1, "Harpie Lady 2": 1, "Harpie Lady 3": 1, "Harpie Lady": 2, "Harpie Lady Sisters": 2, "Cyber Harpie Lady": 2, "Harpie's Pet Dragon": 2, "Harpie's Pet Baby Dragon": 1, "Kanan the Swordmistress": 1, "Amazoness Paladin": 1, "Harpie Queen": 1, "Mystic Tomato": 2, "Amazoness Swords Woman": 1, "Kuriboh": 1, "Elegant Egotist": 2, "Harpies' Hunting Ground": 2, "Mystical Space Typhoon": 1, "Dian Keto the Cure Master": 1, "Triangle Ecstasy Spark": 2, "Harpie's Feather Duster": 1, "Cyber Shield": 2, "Rising Air Current": 2, "Monster Reborn": 1, "Hysteric Party": 2, "Mirror Wall": 1, "Trap Hole": 1, "Call of the Haunted": 1, "Robbin' Goblin": 1, "United We Stand": 1},
		"extra": {}},
	"anime_bakura_1": {"name": "Bakura · Duelist Kingdom", "cards": {"Headless Knight": 2, "The Earl of Demise": 2, "Morphing Jar": 1, "Man-Eater Bug": 2, "The Gross Ghost of Fled Dreams": 1, "Sangan": 1, "Dark Necrofear": 1, "Coffin Seller": 2, "Cyber Jar": 1, "Masked Sorcerer": 1, "Prisman": 1, "Mad Sword Beast": 1, "Dark Ruler Ha Des": 1, "Earthbound Spirit": 2, "Change of Heart": 1, "Dark Sanctuary": 1, "Dark Hole": 1, "Fissure": 2, "Ectoplasmer": 1, "Graverobber": 1, "Destiny Board": 1, "Spirit Message \"I\"": 1, "Spirit Message \"N\"": 2, "Spirit Message \"A\"": 2, "Spirit Message \"L\"": 1, "Dark Spirit of the Silent": 1, "Fiend's Hand Mirror": 1, "Call of the Haunted": 1, "Graceful Charity": 1, "Magic Cylinder": 1, "Shield & Sword": 1, "Rope of Life": 1},
		"extra": {}},
	"anime_bakura_2": {"name": "Bakura · Millennium World", "cards": {"Diabound Kernel": 2, "Dark Necrofear": 1, "Headless Knight": 2, "The Earl of Demise": 2, "Dark Ruler Ha Des": 1, "Tragoedia": 1, "Man-Eater Bug": 1, "Morphing Jar": 1, "Sangan": 1, "Gil Garth": 1, "Earthbound Spirit": 2, "Mad Sword Beast": 1, "Doom Dozer": 1, "Change of Heart": 1, "Dark Sanctuary": 1, "Dark Hole": 1, "Ectoplasmer": 2, "Double Summon": 1, "Destiny Board": 1, "Spirit Message \"I\"": 2, "Spirit Message \"N\"": 1, "Spirit Message \"A\"": 2, "Spirit Message \"L\"": 2, "Dark Spirit of the Silent": 2, "Sakuretsu Armor": 1, "Coffin Seller": 1, "Masked Sorcerer": 1, "Negate Attack": 1, "Ookazi": 1, "De-Spell": 1, "Fairy Box": 1},
		"extra": {}},
	"anime_marik_1": {"name": "Marik · Rare Hunters", "cards": {"Gil Garth": 2, "Viser Des": 1, "Dark Jeroid": 2, "Newdoria": 2, "Makyura the Destructor": 1, "Revival Jam": 2, "Lava Golem": 1, "Bowganian": 1, "Mad Sword Beast": 1, "Masked Sorcerer": 1, "Dark Ruler Ha Des": 1, "Sangan": 1, "Morphing Jar": 1, "Jam Breeding Machine": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Change of Heart": 1, "Fissure": 2, "Mystical Space Typhoon": 1, "Nightmare Wheel": 2, "Nightmare's Steelcage": 2, "Embodiment of Apophis": 2, "Waboku": 1, "Mystic Tomato": 1, "Ring of Destruction": 1, "Axe of Despair": 1, "Nutrient Z": 1, "Black Pendant": 1, "Malevolent Nuzzler": 1, "Block Attack": 1, "Reverse Trap": 1},
		"extra": {}},
	"anime_marik_2": {"name": "Marik · Battle City Finals", "cards": {"The Winged Dragon of Ra": 1, "Lava Golem": 1, "Revival Jam": 2, "Gil Garth": 2, "Viser Des": 1, "Dark Jeroid": 1, "Newdoria": 2, "Makyura the Destructor": 1, "Bowganian": 1, "Dark Ruler Ha Des": 1, "Mad Sword Beast": 1, "Masked Sorcerer": 1, "Sangan": 1, "Jam Breeding Machine": 2, "Double Summon": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Change of Heart": 1, "Brain Control": 1, "Nightmare Wheel": 2, "Embodiment of Apophis": 2, "Ring of Destruction": 1, "Mystic Tomato": 1, "Heavy Storm": 1, "Goblin's Secret Remedy": 1, "Horn of the Unicorn": 1, "Remove Trap": 1, "Skull Dice": 1, "Dark Energy": 1, "Gift of The Mystical Elf": 1, "Gravity Bind": 1, "Mage Power": 1, "Michizure": 1, "Hinotama": 1},
		"extra": {}},
	"anime_pegasus_1": {"name": "Pegasus · Toon World", "cards": {"Toon Mermaid": 2, "Manga Ryu-Ran": 1, "Toon Summoned Skull": 1, "Toon Alligator": 2, "Toon Gemini Elf": 1, "Toon Masked Sorcerer": 1, "Toon Cannon Soldier": 1, "Dragon Piper": 1, "Dark Rabbit": 1, "Parrot Dragon": 1, "Illusionist Faceless Mage": 1, "Crass Clown": 1, "Dream Clown": 1, "Morphing Jar": 1, "Hiro's Shadow Scout": 1, "Toon World": 2, "Toon Table of Contents": 2, "Polymerization": 2, "Change of Heart": 1, "Swords of Revealing Light": 1, "Shrink": 2, "Dragon Capture Jar": 2, "Mirror Force": 1, "Waboku": 1, "Spellbinding Circle": 2, "Toon Dark Magician Girl": 1, "Graceful Charity": 1, "Castle Walls": 1, "Graceful Dice": 1, "Enchanted Javelin": 1, "Reinforcements": 1, "Solemn Wishes": 1},
		"extra": {"Bickuribox": 1, "Rabid Horseman": 1}},
	"anime_pegasus_2": {"name": "Pegasus · Millennium Eye", "cards": {"Relinquished": 2, "Thousand-Eyes Idol": 2, "Toon Mermaid": 1, "Manga Ryu-Ran": 1, "Toon Summoned Skull": 1, "Toon Alligator": 1, "Illusionist Faceless Mage": 2, "Dragon Piper": 1, "Morphing Jar": 1, "Sangan": 1, "Doma The Angel of Silence": 1, "Hiro's Shadow Scout": 1, "Black Illusion Ritual": 2, "Toon World": 1, "Toon Table of Contents": 2, "Polymerization": 2, "Change of Heart": 1, "Dragon Capture Jar": 2, "Trap Hole": 1, "Spellbinding Circle": 2, "Toon Dark Magician Girl": 1, "Toon Gemini Elf": 1, "Mystical Space Typhoon": 1, "Sakuretsu Armor": 1, "Waboku": 1, "Dian Keto the Cure Master": 1, "Horn of the Unicorn": 1, "Mesmeric Control": 1, "Enchanted Javelin": 1, "Chain Destruction": 1, "United We Stand": 1, "Hinotama": 1},
		"extra": {"Thousand-Eyes Restrict": 2}},
	"anime_weevil_1": {"name": "Weevil · Duelist Kingdom", "cards": {"Basic Insect": 2, "Killer Needle": 2, "Hercules Beetle": 2, "Insect Queen": 1, "Larvae Moth": 1, "Petit Moth": 1, "Great Moth": 1, "Flying Kamakiri #1": 2, "Gokipon": 2, "Pinch Hopper": 1, "Man-Eater Bug": 1, "Cockroach Knight": 1, "Javelin Beetle": 1, "Cocoon of Evolution": 1, "Laser Cannon Armor": 2, "Insect Armor with Laser Cannon": 2, "Javelin Beetle Pact": 1, "Fissure": 1, "Shrink": 2, "Insect Barrier": 2, "Insect Imitation": 2, "Negate Attack": 1, "Call of the Haunted": 1, "DNA Surgery": 2, "Graceful Charity": 1, "Magic Cylinder": 1, "Reinforcements": 1, "Axe of Despair": 1, "Shield & Sword": 1},
		"extra": {}},
	"anime_weevil_2": {"name": "Weevil · Battle City", "cards": {"Insect Queen": 1, "Petit Moth": 2, "Larvae Moth": 1, "Great Moth": 1, "Perfectly Ultimate Great Moth": 1, "Parasite Paracide": 2, "Insect Princess": 1, "Javelin Beetle": 1, "Killer Needle": 2, "Pinch Hopper": 1, "Flying Kamakiri #1": 2, "Man-Eater Bug": 1, "Hercules Beetle": 1, "Gokipon": 2, "Cocoon of Evolution": 2, "Javelin Beetle Pact": 2, "Insect Armor with Laser Cannon": 2, "Laser Cannon Armor": 2, "Double Summon": 1, "Insect Barrier": 2, "Insect Imitation": 2, "DNA Surgery": 2, "Mirror Force": 1, "Sakuretsu Armor": 1, "Swords of Revealing Light": 1, "Solemn Wishes": 1, "Gift of The Mystical Elf": 1, "Michizure": 1},
		"extra": {}},
	"anime_rex_1": {"name": "Rex · Duelist Kingdom", "cards": {"Two-Headed King Rex": 2, "Sword Arm of Dragon": 2, "Uraby": 2, "Megazowler": 2, "Crawling Dragon": 2, "Serpent Night Dragon": 1, "Red-Eyes Black Dragon": 1, "Babycerasaurus": 1, "Kabazauls": 2, "Mad Sword Beast": 1, "Sabersaurus": 2, "Gilasaurus": 1, "Jurassic World": 2, "Fissure": 2, "Rush Recklessly": 2, "Stop Defense": 1, "Dragon Treasure": 2, "Big Evolution Pill": 2, "Trap Hole": 1, "Negate Attack": 1, "Call of the Haunted": 1, "Threatening Roar": 1, "Dust Tornado": 2, "Mystical Space Typhoon": 1, "Dark Energy": 1, "Just Desserts": 1, "Mage Power": 1},
		"extra": {}},
	"anime_rex_2": {"name": "Rex · Battle City", "cards": {"Black Tyranno": 1, "Gilasaurus": 2, "Megazowler": 2, "Sabersaurus": 2, "Ultimate Tyranno": 1, "Element Saurus": 1, "Babycerasaurus": 2, "Two-Headed King Rex": 1, "Uraby": 2, "Kabazauls": 1, "Mad Sword Beast": 2, "Tyranno Infinity": 1, "Jurassic World": 2, "Big Evolution Pill": 2, "Double Summon": 1, "Fissure": 2, "Rush Recklessly": 2, "Threatening Roar": 2, "Magic Cylinder": 1, "Dust Tornado": 2, "Graceful Charity": 1, "Swords of Revealing Light": 1, "Castle Walls": 1, "Block Attack": 1, "Reverse Trap": 1, "De-Spell": 1, "Rope of Life": 1, "Gravity Bind": 1},
		"extra": {}},
	"anime_jaden_2": {"name": "Jaden · Neos and the Neo-Spacians", "cards": {"Elemental HERO Neos": 3, "Neo-Spacian Grand Mole": 2, "Neo-Spacian Aqua Dolphin": 1, "Neo-Spacian Flare Scarab": 1, "Neo-Spacian Dark Panther": 1, "Neo-Spacian Air Hummingbird": 1, "Neo-Spacian Glow Moss": 1, "Neo Space Pathfinder": 1, "Elemental HERO Sparkman": 2, "Elemental HERO Avian": 1, "Elemental HERO Burstinatrix": 1, "Elemental HERO Clayman": 1, "Elemental HERO Bubbleman": 1, "Elemental HERO Neos Alius": 1, "Winged Kuriboh": 2, "Neo Space": 2, "Instant Neo Space": 1, "E - Emergency Call": 2, "Miracle Fusion": 2, "Polymerization": 2, "Hero Signal": 1, "Skyscraper": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Contact Out": 1, "NEX": 2, "Hero Barrier": 2, "Mirror Force": 1, "Negate Attack": 1},
		"extra": {"Elemental HERO Air Neos": 1, "Elemental HERO Flare Neos": 1, "Elemental HERO Aqua Neos": 1, "Elemental HERO Grand Neos": 1, "Elemental HERO Dark Neos": 1, "Elemental HERO Glow Neos": 1, "Elemental HERO Shining Flare Wingman": 1, "Elemental HERO Flame Wingman": 1, "Elemental HERO Thunder Giant": 1}},
	"anime_chazz_2": {"name": "Chazz · Ojamas and Armed Dragons", "cards": {"Armed Dragon LV3": 3, "Armed Dragon LV5": 3, "Armed Dragon LV7": 1, "Armed Dragon LV10": 1, "Ojama Yellow": 2, "Ojama Green": 1, "Ojama Black": 1, "Light and Darkness Dragon": 1, "V-Tiger Jet": 1, "W-Wing Catapult": 1, "X-Head Cannon": 1, "Y-Dragon Head": 1, "Z-Metal Tank": 1, "Chthonian Soldier": 1, "Level Up!": 2, "Ojamagic": 2, "Ojama Delta Hurricane!!": 2, "Ojama Country": 1, "Polymerization": 2, "Pot of Greed": 1, "Mirror Force": 1, "Sakuretsu Armor": 1, "Trap Hole": 1, "Ojamuscle": 2, "Wall of Disruption": 1, "Dimension Wall": 1, "Frontline Base": 2, "Level Limit - Area B": 1, "Covering Fire": 1},
		"extra": {"Ojama King": 2, "VW-Tiger Catapult": 1, "XYZ-Dragon Cannon": 1, "VWXYZ-Dragon Catapult Cannon": 1}},
	"anime_zane_1": {"name": "Zane · The Kaiser", "cards": {"Cyber Dragon": 3, "Proto-Cyber Dragon": 3, "Cyber Phoenix": 2, "Cyber Barrier Dragon": 1, "Cyber Laser Dragon": 1, "Cyber Valley": 1, "Cyber Kirin": 1, "Cyber Dinosaur": 1, "Cyber Jar": 1, "Cyber Larva": 1, "Drillroid": 1, "Mechanicalchaser": 2, "Power Bond": 2, "Polymerization": 2, "Different Dimension Capsule": 2, "Photon Generator Unit": 2, "Pot of Greed": 1, "Limiter Removal": 1, "Machine Duplication": 2, "Call of the Haunted": 1, "Dimension Wall": 2, "Waboku": 1, "Attack Reflector Unit": 2, "Heavy Storm": 1, "Emergency Provisions": 1, "Messenger of Peace": 1, "Ojama Trio": 1},
		"extra": {"Cyber Twin Dragon": 2, "Cyber End Dragon": 2}},
	"anime_zane_2": {"name": "Zane · Hell Kaiser", "cards": {"Cyberdark Horn": 3, "Cyberdark Edge": 3, "Cyberdark Keel": 3, "Cyber Dragon": 3, "Proto-Cyber Dragon": 1, "Cyber Laser Dragon": 1, "Cyber Barrier Dragon": 1, "Cyber Phoenix": 1, "Cyber Valley": 1, "Armed Dragon LV5": 1, "Masked Dragon": 1, "Power Bond": 2, "Cyberdark Impact!": 2, "Polymerization": 2, "Limiter Removal": 1, "Photon Generator Unit": 2, "Pot of Greed": 1, "Foolish Burial": 1, "Dimension Wall": 2, "Magic Cylinder": 1, "Attack Reflector Unit": 2, "Graceful Charity": 1, "Heavy Storm": 1, "Big Bang Shot": 1, "Good Goblin Housekeeping": 1, "The Warrior Returning Alive": 1},
		"extra": {"Cyberdark Dragon": 2, "Cyber End Dragon": 2, "Cyber Twin Dragon": 1}},
	"anime_alexis_1": {"name": "Alexis · Obelisk Blue", "cards": {"Etoile Cyber": 3, "Cyber Tutu": 2, "Blade Skater": 3, "Cyber Gymnast": 2, "Cyber Petit Angel": 3, "Cyber Prima": 1, "Cyber Angel Benten": 1, "Cyber Angel Dakini": 1, "Cyber Angel Idaten": 1, "Command Knight": 1, "Machine Angel Ritual": 2, "Polymerization": 2, "Fusion Gate": 2, "Mystical Space Typhoon": 1, "Swords of Revealing Light": 1, "Rush Recklessly": 2, "Double Summon": 1, "Doble Passe": 2, "Spellbinding Circle": 2, "Heavy Storm": 1, "Chain Burst": 1, "Fairy Meteor Crush": 1, "Legacy of Yata-Garasu": 1, "Wild Nature's Release": 1, "Nutrient Z": 1, "Good Goblin Housekeeping": 1},
		"extra": {"Cyber Blader": 2}},
	"anime_alexis_2": {"name": "Alexis · Cyber Angels", "cards": {"Cyber Angel Idaten": 2, "Cyber Angel Benten": 2, "Cyber Angel Dakini": 2, "Cyber Petit Angel": 3, "Cyber Prima": 2, "Etoile Cyber": 2, "Blade Skater": 2, "Cyber Tutu": 1, "Cyber Gymnast": 1, "Manju of the Ten Thousand Hands": 2, "Sonic Bird": 1, "Machine Angel Ritual": 3, "Polymerization": 2, "Fusion Gate": 2, "Pot of Avarice": 2, "Doble Passe": 2, "Sakuretsu Armor": 1, "Magic Cylinder": 1, "Waboku": 1, "Heavy Storm": 1, "Desert Sunlight": 1, "Wild Nature's Release": 1, "Messenger of Peace": 1, "Big Bang Shot": 1, "The Warrior Returning Alive": 1},
		"extra": {"Cyber Blader": 2}},
	"anime_syrus_1": {"name": "Syrus · Slifer Red", "cards": {"Gyroid": 2, "Steamroid": 2, "Patroid": 2, "Drillroid": 2, "Submarineroid": 2, "Cycroid": 2, "UFOroid": 2, "Expressroid": 2, "Truckroid": 1, "Jetroid": 1, "Rescueroid": 1, "Kuriboh": 1, "Polymerization": 3, "Vehicroid Connection Zone": 2, "Rush Recklessly": 2, "Swords of Revealing Light": 1, "Scapegoat": 2, "Shield & Sword": 2, "Call of the Haunted": 1, "Negate Attack": 1, "Mirror Wall": 2, "Graceful Charity": 1, "Fairy Meteor Crush": 1, "Chain Burst": 1, "Emergency Provisions": 1},
		"extra": {"Steam Gyroid": 2, "Super Vehicroid Jumbo Drill": 1, "Ambulance Rescueroid": 1, "Pair Cycroid": 1, "UFOroid Fighter": 1}},
	"anime_syrus_2": {"name": "Syrus · Stealth Union", "cards": {"Gyroid": 2, "Steamroid": 2, "Patroid": 2, "Drillroid": 2, "Submarineroid": 2, "Cycroid": 2, "Expressroid": 2, "Truckroid": 1, "Jetroid": 1, "Rescueroid": 1, "Cyber Dragon": 1, "UFOroid": 1, "Stealthroid": 1, "Carrierroid": 1, "Ambulanceroid": 1, "Power Bond": 2, "Polymerization": 2, "Vehicroid Connection Zone": 2, "Limiter Removal": 1, "Mystical Space Typhoon": 1, "Swords of Revealing Light": 1, "Trap Hole": 1, "Mirror Force": 1, "Supercharge": 2, "Ojama Trio": 1, "Legacy of Yata-Garasu": 1, "Covering Fire": 1, "Level Limit - Area B": 1, "Nutrient Z": 1},
		"extra": {"Super Vehicroid - Stealth Union": 2, "Super Vehicroid Jumbo Drill": 1, "Steam Gyroid": 1, "Cyber Twin Dragon": 1}},
	"anime_aster_1": {"name": "Aster · Destiny HEROes", "cards": {"Destiny HERO - Diamond Dude": 3, "Destiny HERO - Captain Tenacious": 1, "Destiny HERO - Doom Lord": 1, "Destiny HERO - Dreadmaster": 1, "Destiny HERO - Defender": 2, "Destiny HERO - Fear Monger": 1, "Destiny HERO - Dasher": 1, "Destiny HERO - Malicious": 3, "Destiny HERO - Disk Commander": 1, "Destiny HERO - Double Dude": 1, "Destiny HERO - Dark Angel": 1, "Elemental HERO Bladedge": 1, "Destiny Draw": 3, "Clock Tower Prison": 2, "D - Spirit": 2, "Polymerization": 2, "Over Destiny": 2, "D - Time": 2, "Destiny Signal": 2, "Eternal Dread": 1, "Destiny Mirage": 1, "Call of the Haunted": 1, "Mirror Force": 1, "Graceful Charity": 1, "Heavy Storm": 1, "Wild Nature's Release": 1, "Legacy of Yata-Garasu": 1},
		"extra": {}},
	"anime_aster_2": {"name": "Aster · Dogma and Plasma", "cards": {"Destiny HERO - Dogma": 1, "Destiny HERO - Plasma": 1, "Destiny HERO - Diamond Dude": 3, "Destiny HERO - Malicious": 3, "Destiny HERO - Dreadmaster": 1, "Destiny HERO - Doom Lord": 1, "Destiny HERO - Defender": 2, "Destiny HERO - Disk Commander": 1, "Destiny HERO - Double Dude": 1, "Destiny HERO - Dasher": 1, "Destiny HERO - Captain Tenacious": 1, "Destiny HERO - Fear Monger": 1, "Destiny Draw": 3, "Clock Tower Prison": 2, "D - Spirit": 2, "Over Destiny": 2, "Double Summon": 1, "D - Time": 2, "Destiny Signal": 2, "Eternal Dread": 1, "Destiny Mirage": 2, "Negate Attack": 1, "Ring of Destruction": 1, "Heavy Storm": 1, "Magic Cylinder": 1, "Messenger of Peace": 1, "Fairy Meteor Crush": 1},
		"extra": {}},
	"anime_crowler_1": {"name": "Crowler · Ancient Gears", "cards": {"Ancient Gear Golem": 3, "Ancient Gear Beast": 2, "Ancient Gear Soldier": 3, "Ancient Gear Cannon": 2, "Ancient Gear Engineer": 2, "Ancient Gear": 3, "Ancient Gear Knight": 2, "Ancient Gear Tank": 0, "Statue of the Wicked": 2, "Cyber Jar": 1, "Mechanicalchaser": 1, "Ancient Gear Castle": 2, "Ancient Gear Drill": 2, "Ancient Gear Explosive": 2, "Mystical Space Typhoon": 1, "Ultimate Offering": 2, "Ancient Gear Workshop": 2, "Damage Condenser": 1, "Trap Hole": 1, "Waboku": 1, "Heavy Storm": 1, "Desert Sunlight": 1, "Covering Fire": 1, "The Warrior Returning Alive": 1, "Chain Burst": 1},
		"extra": {}},
	"anime_crowler_2": {"name": "Crowler · Ultimate Ancient Gear", "cards": {"Ancient Gear Golem": 2, "Ancient Gear Gadjiltron Dragon": 1, "Ancient Gear Gadjiltron Chimera": 1, "Ancient Gear Beast": 2, "Ancient Gear Soldier": 2, "Ancient Gear Cannon": 2, "Ancient Gear Engineer": 2, "Ancient Gear": 3, "Ancient Gear Knight": 2, "Statue of the Wicked": 2, "Cyber Jar": 1, "Ancient Gear Fusion": 2, "Ancient Gear Castle": 1, "Ancient Gear Explosive": 2, "Polymerization": 2, "Double Summon": 1, "Ultimate Offering": 2, "Ancient Gear Workshop": 1, "Damage Condenser": 1, "Sakuretsu Armor": 1, "Negate Attack": 1, "Heavy Storm": 1, "Ancient Gear Drill": 2, "Mage Power": 1, "Rope of Life": 1, "Enchanted Javelin": 1},
		"extra": {"Ultimate Ancient Gear Golem": 2}},
	"anime_sheppard_1": {"name": "Sheppard · The Cyber Dojo", "cards": {"Cyber Dragon": 3, "Proto-Cyber Dragon": 3, "Cyber Barrier Dragon": 1, "Cyber Laser Dragon": 1, "Cyber Phoenix": 2, "Cyber Valley": 1, "Cyber Kirin": 1, "Cyber Jar": 1, "Cyber Larva": 1, "Cyber Dinosaur": 1, "Cyber Archfiend": 1, "Mechanicalchaser": 1, "Power Bond": 2, "Polymerization": 2, "Photon Generator Unit": 2, "Different Dimension Capsule": 2, "Limiter Removal": 1, "Swords of Revealing Light": 1, "Attack Reflector Unit": 2, "Call of the Haunted": 1, "Sakuretsu Armor": 1, "Dimension Wall": 2, "Waboku": 1, "Machine Duplication": 2, "Level Limit - Area B": 1, "United We Stand": 1, "Good Goblin Housekeeping": 1, "Michizure": 1},
		"extra": {"Cyber Twin Dragon": 2, "Cyber End Dragon": 2}},
	"anime_bastion_1": {"name": "Bastion · The Water Deck", "cards": {"Hydrogeddon": 3, "Oxygeddon": 3, "Carboneddon": 3, "Litmus Doom Swordsman": 1, "Mother Grizzly": 1, "Unshaven Angler": 1, "Sea Serpent Warrior of Darkness": 1, "Amphibious Bugroth MK-3": 1, "Spiritual Water Art - Aoi": 0, "Mermaid Knight": 2, "Fenrir": 1, "Star Boy": 2, "Bonding - H2O": 2, "Litmus Doom Ritual": 2, "A Legendary Ocean": 2, "Salvage": 2, "Double Summon": 1, "Card of Sanctity": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Waboku": 1, "Emergency Provisions": 1, "Ojama Trio": 1, "Big Bang Shot": 1, "Level Limit - Area B": 1, "Nutrient Z": 1, "Fairy Meteor Crush": 1, "Enchanted Javelin": 1, "Covering Fire": 1},
		"extra": {}},
	"anime_yusei_2": {"name": "Yusei · Shooting Star", "cards": {"Junk Synchron": 3, "Quickdraw Synchron": 3, "Level Eater": 1, "Debris Dragon": 2, "Turbo Synchron": 1, "Junk Converter": 1, "Doppelwarrior": 2, "Speed Warrior": 1, "Quillbolt Hedgehog": 1, "Zero Gardna": 1, "Shield Wing": 1, "Turbo Booster": 1, "Card Trooper": 1, "Sonic Chick": 1, "Max Warrior": 1, "Tuning": 1, "Junk Barrage": 2, "Mystical Space Typhoon": 1, "Graceful Charity": 1, "Swords of Revealing Light": 1, "Starlight Road": 2, "Stardust Flash": 2, "Scrap-Iron Scarecrow": 1, "Defense Draw": 2, "Graceful Revival": 2, "Fiendish Chain": 1, "Negate Attack": 1, "Card of Sacrifice": 1, "Tuner's Barrier": 1},
		"extra": {"Stardust Dragon": 2, "Shooting Star Dragon": 1, "Junk Destroyer": 1, "Junk Berserker": 1, "Junk Archer": 1, "Junk Warrior": 2, "Road Warrior": 1, "Turbo Warrior": 1, "Drill Warrior": 1, "Nitro Warrior": 1, "Formula Synchron": 1}},
	"anime_jack_2": {"name": "Jack · Assault Mode", "cards": {"Red Resonator": 2, "Dark Resonator": 2, "Big Piece Golem": 2, "Medium Piece Golem": 2, "Mad Archfiend": 1, "Vice Dragon": 2, "Red Dragon Archfiend/Assault Mode": 1, "Red Sprinter": 2, "Strong Wind Dragon": 1, "Exploder Dragon": 2, "Twin-Sword Marauder": 1, "Archfiend Soldier": 1, "Battle Fader": 1, "Assault Mode Activate": 2, "Scarlet Security": 2, "Mystical Space Typhoon": 1, "Battle Waltz": 2, "Graceful Charity": 1, "Crimson Fire": 2, "Red Screen": 2, "Burning Soul": 1, "Fiendish Chain": 1, "Call of the Haunted": 1, "Dimension Wall": 2, "Magic Cylinder": 1, "Battle Mania": 1, "Synchro Boost": 1},
		"extra": {"Red Dragon Archfiend": 2, "Red Wyvern": 1, "Exploder Dragonwing": 1, "Red Nova Dragon": 1}},
	"anime_crow_1": {"name": "Crow · Satellite Blackwings", "cards": {"Blackwing - Bora the Spear": 2, "Blackwing - Gale the Whirlwind": 3, "Blackwing - Sirocco the Dawn": 2, "Blackwing - Shura the Blue Flame": 2, "Blackwing - Kalut the Moon Shadow": 2, "Blackwing - Blizzard the Far North": 2, "Blackwing - Elphin the Raven": 2, "Blackwing - Fane the Steel Chain": 1, "Blackwing - Ghibli the Searing Wind": 2, "Blackwing - Gust the Backblast": 1, "Black Whirlwind": 2, "Double Summon": 1, "Icarus Attack": 2, "Delta Crow - Anti Reverse": 2, "Black Sonic": 2, "Sakuretsu Armor": 1, "Fiendish Chain": 2, "Trap Hole": 1, "Waboku": 1, "Synchro Strike": 1, "Lightwave Tuning": 1, "Urgent Tuning": 1, "Descending Lost Star": 1, "Remote Revenge": 1, "Fighting Spirit": 1, "Give and Take": 1},
		"extra": {"Blackwing Armor Master": 2, "Blackwing Armed Wing": 1}},
	"anime_crow_2": {"name": "Crow · Black-Winged Dragon", "cards": {"Blackwing - Bora the Spear": 2, "Blackwing - Gale the Whirlwind": 3, "Blackwing - Sirocco the Dawn": 2, "Blackwing - Shura the Blue Flame": 2, "Blackwing - Kalut the Moon Shadow": 2, "Blackwing - Blizzard the Far North": 2, "Blackwing - Vayu the Emblem of Honor": 2, "Blackwing - Elphin the Raven": 2, "Blackwing - Gust the Backblast": 1, "Blackwing - Ghibli the Searing Wind": 1, "Black Whirlwind": 2, "Pot of Greed": 1, "Icarus Attack": 2, "Delta Crow - Anti Reverse": 2, "Black Sonic": 2, "Fiendish Chain": 2, "Mirror Force": 1, "Trap Hole": 1, "Blackwing - Fane the Steel Chain": 1, "Magic Cylinder": 1, "Half or Nothing": 1, "Limit Reverse": 1, "Battle Mania": 1, "Urgent Tuning": 1, "Card of Sacrifice": 1, "Lightwave Tuning": 1},
		"extra": {"Black-Winged Dragon": 2, "Blackwing Armor Master": 2, "Blackwing Armed Wing": 1, "Blackwing - Silverwind the Ascendant": 1}},
	"anime_akiza_1": {"name": "Akiza · The Black Rose", "cards": {"Twilight Rose Knight": 3, "Evil Thorn": 3, "Copy Plant": 2, "Phoenixian Seed": 1, "Rose Witch": 1, "Lord Poison": 2, "Botanical Lion": 2, "Gigaplant": 2, "Dark Verger": 2, "Rose Tentacles": 1, "Revival Rose": 2, "Wall of Ivy": 1, "Mark of the Rose": 2, "Blossom Bombardment": 2, "Thorn of Malice": 2, "Fiendish Chain": 2, "Trap Hole": 1, "Magic Cylinder": 1, "Waboku": 1, "Heavy Storm": 1, "Limit Reverse": 1, "Tuner's Barrier": 1, "Half or Nothing": 1, "Fighting Spirit": 1, "Descending Lost Star": 1, "Give and Take": 1},
		"extra": {"Black Rose Dragon": 2}},
	"anime_akiza_2": {"name": "Akiza · Queen of Thorns", "cards": {"Twilight Rose Knight": 3, "Evil Thorn": 3, "Copy Plant": 2, "Phoenixian Seed": 1, "Rose Witch": 2, "Lord Poison": 2, "Botanical Lion": 2, "Dark Verger": 2, "Revival Rose": 2, "Gigaplant": 1, "Wall of Ivy": 1, "Rose Tentacles": 1, "Mark of the Rose": 2, "Blossom Bombardment": 2, "Thorn of Malice": 2, "Double Summon": 1, "Call of the Haunted": 1, "Fiendish Chain": 2, "Swords of Revealing Light": 1, "Negate Attack": 1, "Synchro Boost": 1, "Remote Revenge": 1, "Synchro Strike": 1, "Descending Lost Star": 1, "Give and Take": 1, "Half or Nothing": 1},
		"extra": {"Black Rose Dragon": 2, "Splendid Rose": 1, "Queen of Thorns": 1}},
	"anime_kalin_1": {"name": "Kalin · Dark Signer", "cards": {"Infernity Archfiend": 3, "Infernity Necromancer": 2, "Infernity Beast": 3, "Infernity Mirage": 2, "Infernity Avenger": 2, "Infernity Guardian": 1, "Infernity Knight": 1, "Infernity Destroyer": 1, "Infernity Dwarf": 1, "Stygian Street Patrol": 1, "Dark Resonator": 1, "Morphing Jar": 1, "Infernity Launcher": 2, "Graceful Charity": 1, "Card Destruction": 1, "Dark Hole": 1, "Infernity Barrier": 2, "Infernity Force": 2, "Infernity Inferno": 2, "Infernity Break": 2, "Sakuretsu Armor": 1, "Fiendish Chain": 2, "Pot of Greed": 1, "Synchro Strike": 1, "Limit Reverse": 1, "Urgent Tuning": 1, "Tuner's Barrier": 1},
		"extra": {"Hundred Eyes Dragon": 2, "Infernity Doom Dragon": 1}},
	"anime_kalin_2": {"name": "Kalin · Crash Town", "cards": {"Infernity Archfiend": 3, "Infernity Necromancer": 2, "Infernity Beast": 2, "Infernity Mirage": 2, "Infernity Avenger": 2, "Infernity Knight": 1, "Infernity Destroyer": 1, "Infernity Dwarf": 2, "Stygian Street Patrol": 1, "Dark Resonator": 1, "Morphing Jar": 1, "Infernity Launcher": 2, "Monster Reborn": 1, "Card Destruction": 1, "Mystical Space Typhoon": 1, "Infernity Barrier": 2, "Infernity Force": 2, "Infernity Inferno": 2, "Infernity Break": 2, "Fiendish Chain": 2, "Mirror Force": 1, "Infernity Guardian": 1, "Dark Hole": 1, "Lightwave Tuning": 1, "Card of Sacrifice": 1, "Synchro Boost": 1, "Battle Mania": 1},
		"extra": {"Infernity Doom Dragon": 2, "Hundred Eyes Dragon": 1, "Dark Strike Fighter": 1}},
	"anime_yuma_2": {"name": "Yuma · Utopia Ray", "cards": {"Gagaga Magician": 3, "Zubaba Knight": 3, "Gogogo Golem": 2, "Dodododo Warrior": 1, "Achacha Archer": 2, "Gagaga Girl": 1, "Gogogo Giant": 1, "Dododo Witch": 1, "Ganbara Knight": 1, "Kagetokage": 1, "ZW - Phoenix Bow": 1, "ZW - Lightning Blade": 1, "ZW - Tornado Bringer": 1, "ZW - Unicorn Spear": 1, "Rank-Up-Magic Barian's Force": 2, "Double or Nothing!": 2, "Gagagabolt": 2, "Gagagatag": 2, "Pot of Greed": 1, "Overlay Regen": 2, "Wonder Wand": 1, "Half Unbreak": 1, "Xyz Reborn": 1, "Fiendish Chain": 1, "Sakuretsu Armor": 1, "Mirror Force": 1, "Gagagaback": 1, "Dodododraw": 1, "Negate Attack": 1},
		"extra": {"Number 39: Utopia": 2, "Number C39: Utopia Ray": 1, "Number C39: Utopia Ray V": 1, "Number 34: Terror-Byte": 1, "Leviair the Sea Dragon": 1}},
	"anime_shark_2": {"name": "Shark · Barian Numbers", "cards": {"Big Jaws": 3, "Shark Stickers": 3, "Skull Kraken": 2, "Hammer Shark": 2, "Mermaid Shark": 2, "Spear Shark": 2, "Jawsman": 2, "Torpedo Fish": 2, "Deep Sea Diva": 2, "Aqua Spirit": 1, "Hammer Bounzer": 1, "Rank-Up-Magic Barian's Force": 2, "A Legendary Ocean": 2, "Overlay Regen": 2, "Mystical Space Typhoon": 1, "Xyz Reborn": 2, "Call of the Haunted": 1, "Fiendish Chain": 2, "Torrential Tribute": 1, "Magic Cylinder": 1, "Bye Bye Damage": 1, "Xyz Dimension Splash": 1, "Oh F!sh!": 1, "Blustering Winds": 1},
		"extra": {"Number 32: Shark Drake": 1, "Number C32: Shark Drake Veiss": 1, "Number 101: Silent Honor ARK": 1, "Number C101: Silent Honor DARK": 1, "Number 73: Abyss Splash": 1, "Number 17: Leviathan Dragon": 1, "Black Ray Lancer": 1, "Shark Fortress": 1, "Cat Shark": 1}},
	"anime_kite_1": {"name": "Kite · The Number Hunter", "cards": {"Galaxy-Eyes Photon Dragon": 3, "Photon Thrasher": 3, "Photon Crusher": 3, "Photon Sabre Tiger": 2, "Photon Cerberus": 2, "Galaxy Wizard": 1, "Photon Leo": 1, "Galaxy Knight": 1, "Galaxy Soldier": 2, "Photon Wyvern": 1, "Photon Vanisher": 1, "Photon Satellite": 1, "Galaxy Expedition": 2, "Photon Lead": 2, "Photon Sanctuary": 2, "Galaxy Queen's Light": 2, "Monster Reborn": 1, "Galaxy Cyclone": 2, "Double Summon": 1, "Fiendish Chain": 1, "Torrential Tribute": 1, "Xyz Reborn": 2, "Heavy Storm": 1, "Xyz Effect": 1, "Double or Nothing!": 1},
		"extra": {"Starliege Paladynamo": 1, "Number 62: Galaxy-Eyes Prime Photon Dragon": 1, "Photon Strike Bounzer": 1}},
	"anime_kite_2": {"name": "Kite · Neo Galaxy-Eyes", "cards": {"Galaxy-Eyes Photon Dragon": 3, "Photon Thrasher": 2, "Photon Crusher": 2, "Photon Sabre Tiger": 2, "Galaxy Wizard": 2, "Galaxy Knight": 2, "Galaxy Soldier": 2, "Photon Wyvern": 1, "Photon Vanisher": 1, "Photon Leo": 1, "Photon Cerberus": 1, "Galaxy Expedition": 2, "Photon Sanctuary": 2, "Rank-Up-Magic Barian's Force": 2, "Galaxy Queen's Light": 2, "Galaxy Cyclone": 1, "Fiendish Chain": 2, "Xyz Reborn": 2, "Torrential Tribute": 1, "Photon Satellite": 1, "Photon Lead": 1, "Heavy Storm": 1, "Negate Attack": 1, "Magic Cylinder": 1, "Xyz Revenge": 1, "Xyz Soul": 1},
		"extra": {"Neo Galaxy-Eyes Photon Dragon": 1, "Number 62: Galaxy-Eyes Prime Photon Dragon": 1, "Starliege Paladynamo": 1, "Photon Strike Bounzer": 1, "Photon Papilloperative": 1}},
	"anime_vector_1": {"name": "Vector · Umbral Horrors", "cards": {"Umbral Horror Ghoul": 3, "Umbral Horror Unform": 3, "Umbral Horror Will o' the Wisp": 2, "Umbral Horror Ghost": 3, "Doom Shaman": 2, "Gimmick Puppet Egg Head": 2, "Mad Sword Beast": 1, "Morphing Jar": 1, "Kagetokage": 1, "Archfiend Soldier": 2, "Rank-Up-Magic Barian's Force": 2, "Dark Hole": 1, "Graceful Charity": 1, "Overlay Regen": 2, "Xyz Reborn": 2, "Fiendish Chain": 2, "Torrential Tribute": 1, "Trap Hole": 1, "Heartfelt Appeal": 1, "Xyz Unit": 1, "Xyz Veil": 1, "Xyz Gift": 1, "Xyz Burst": 1, "Xyz Energy": 1, "Double or Nothing!": 1, "Xyz Dimension Splash": 1},
		"extra": {"Number 104: Masquerade": 1, "Number C104: Umbral Horror Masquerade": 1, "Number 65: Djinn Buster": 1, "Number 66: Master Key Beetle": 1, "Number 43: Manipulator of Souls": 1}},
	"legend_yugi_dk": {"name": "Yugi · Duelist Kingdom", "cards": {"Dark Magician": 1, "Summoned Skull": 1, "Gaia The Fierce Knight": 1, "Curse of Dragon": 1, "Celtic Guardian": 2, "Beaver Warrior": 2, "Feral Imp": 2, "Silver Fang": 2, "Mystical Elf": 2, "Giant Soldier of Stone": 2, "Big Shield Gardna": 1, "Kuriboh": 2, "Magician of Faith": 1, "Swords of Revealing Light": 1, "Monster Reborn": 1, "Polymerization": 2, "Book of Secret Arts": 2, "Card of Sanctity": 1, "Multiply": 2, "Fissure": 2, "Mirror Force": 1, "Spellbinding Circle": 2, "Magic Cylinder": 1, "Stop Defense": 1, "Dian Keto the Cure Master": 1, "Graceful Dice": 1, "Remove Trap": 1, "Robbin' Goblin": 1},
		"extra": {"Gaia the Dragon Champion": 2}},
	"legend_kaiba_dk": {"name": "Kaiba · Duelist Kingdom", "cards": {"Blue-Eyes White Dragon": 3, "Battle Ox": 2, "Hitotsu-Me Giant": 2, "Saggi the Dark Clown": 2, "La Jinn the Mystical Genie of the Lamp": 1, "Rude Kaiser": 2, "Judge Man": 1, "Ryu-Kishin Powered": 2, "Swordstalker": 1, "Vorse Raider": 2, "Lord of D.": 1, "Kaiser Glider": 1, "The Flute of Summoning Dragon": 2, "Polymerization": 2, "Monster Reborn": 1, "Shrink": 2, "Enemy Controller": 2, "Raigeki": 1, "Pot of Greed": 1, "Fissure": 2, "Ring of Destruction": 1, "Negate Attack": 1, "Crush Card Virus": 1, "Dust Tornado": 2, "Fairy Box": 1, "Skull Dice": 1},
		"extra": {"Blue-Eyes Ultimate Dragon": 2}},
	"legend_yusei_s1": {"name": "Yusei · Fortune Cup", "cards": {"Junk Synchron": 3, "Speed Warrior": 2, "Quillbolt Hedgehog": 2, "Nitro Synchron": 1, "Shield Warrior": 2, "Max Warrior": 2, "Sonic Chick": 2, "Fortress Warrior": 1, "Card Trooper": 2, "Swift Scarecrow": 1, "Second Booster": 1, "Tuning": 1, "Fissure": 2, "Swords of Revealing Light": 1, "Junk Barrage": 1, "Scrap-Iron Scarecrow": 2, "Defense Draw": 2, "Graceful Revival": 2, "Tuner's Barrier": 2, "Fiendish Chain": 2, "Call of the Haunted": 1, "Sakuretsu Armor": 1, "Dust Tornado": 2, "Negate Attack": 1, "Fighting Spirit": 1},
		"extra": {"Junk Warrior": 2, "Stardust Dragon": 2, "Nitro Warrior": 1, "Armory Arm": 1, "Junk Gardna": 1}},
	"legend_jack_s1": {"name": "Jack · Fortune Cup", "cards": {"Vice Dragon": 2, "Dark Resonator": 3, "Big Piece Golem": 2, "Medium Piece Golem": 1, "Mad Archfiend": 2, "Exploder Dragon": 1, "Twin-Sword Marauder": 2, "Sinister Sprocket": 1, "Red Sprinter": 2, "Archfiend Soldier": 2, "Trident Warrior": 1, "Battle Fader": 1, "Scarlet Security": 2, "Fissure": 2, "Mystical Space Typhoon": 1, "Shrink": 1, "Crimson Fire": 2, "Fiendish Chain": 2, "Call of the Haunted": 1, "Sakuretsu Armor": 1, "Trap Hole": 1, "Dust Tornado": 2, "Ring of Destruction": 1, "Dimension Wall": 2, "Remote Revenge": 1, "Urgent Tuning": 1},
		"extra": {"Red Dragon Archfiend": 2, "Exploder Dragonwing": 1}},
	"legend_yuma_early": {"name": "Yuma · First Numbers", "cards": {"Gagaga Magician": 3, "Zubaba Knight": 3, "Gogogo Golem": 3, "Ganbara Knight": 2, "Dodododo Warrior": 1, "Kurivolt": 1, "Achacha Archer": 2, "Gogogo Giant": 1, "Dododo Witch": 1, "Gagaga Girl": 1, "Kagetokage": 1, "Double or Nothing!": 2, "Gagagabolt": 2, "Gagagatag": 1, "Gagagaback": 1, "Dodododraw": 2, "Pot of Greed": 1, "Mystical Space Typhoon": 1, "Overlay Regen": 1, "Wonder Wand": 2, "Gagagawind": 1, "Half Unbreak": 2, "Xyz Reborn": 1, "Fiendish Chain": 1, "Mirror Force": 1, "Trap Hole": 1, "Xyz Effect": 1},
		"extra": {"Number 39: Utopia": 2, "Number 34: Terror-Byte": 1, "Leviair the Sea Dragon": 1}},
	"legend_shark_early": {"name": "Shark · First Numbers", "cards": {"Big Jaws": 3, "Shark Stickers": 3, "Skull Kraken": 2, "Hammer Shark": 2, "Mermaid Shark": 1, "Spear Shark": 2, "Jawsman": 1, "Torpedo Fish": 2, "Stinging Swordsman": 1, "Aqua Spirit": 1, "Hammer Bounzer": 1, "Deep Sea Diva": 2, "A Legendary Ocean": 2, "Overlay Regen": 2, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Fissure": 2, "Heavy Storm": 1, "Xyz Reborn": 2, "Call of the Haunted": 1, "Fiendish Chain": 2, "Dust Tornado": 2, "Xyz Energy": 1, "Heartfelt Appeal": 1, "Xyz Revenge": 1},
		"extra": {"Number 17: Leviathan Dragon": 2, "Cat Shark": 1, "Black Ray Lancer": 1, "Shark Fortress": 1, "Number 19: Freezadon": 1, "Shark Caesar": 1}},
	"rex": {"name": "Dinosaur", "cards": {"Black Tyranno": 2, "Two-Headed King Rex": 3, "Sword Arm of Dragon": 2, "Megazowler": 3, "Uraby": 3,
		"Crawling Dragon #2": 2, "Gilasaurus": 2, "Mad Sword Beast": 2, "Sabersaurus": 3,
		"Pot of Greed": 1, "Fissure": 2, "Monster Reborn": 1, "Hinotama": 2, "Dian Keto the Cure Master": 1}},
	"chazz": {"name": "Armed Dragon", "cards": {"Armed Dragon LV3": 3, "Armed Dragon LV5": 2, "Armed Dragon LV7": 2, "X-Head Cannon": 3, "Y-Dragon Head": 3,
		"Z-Metal Tank": 3, "Ojama Yellow": 2, "Ojama Green": 1, "Ojama Black": 1,
		"Mystical Space Typhoon": 2, "Heavy Storm": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2}, "extra": {"XYZ-Dragon Cannon": 2}},
	"zane": {"name": "Cyber Dragon", "cards": {"Cyber Dragon": 3, "Proto-Cyber Dragon": 3, "Cyber Dragon Zwei": 2, "Cyber Phoenix": 2, "Cyber Larva": 2,
		"Cyber Valley": 2, "Cyber Kirin": 2, "Cyber Eltanin": 1, "Cyber Barrier Dragon": 2,
		"Polymerization": 4, "Pot of Greed": 1, "Monster Reborn": 1, "Raigeki": 1, "Fissure": 2}, "extra": {"Cyber Twin Dragon": 2, "Cyber End Dragon": 1}},
	"alexis": {"name": "Cyber Girl", "cards": {"Cyber Tutu": 3, "Etoile Cyber": 3, "Blade Skater": 3, "Cyber Prima": 2, "Cyber Gymnast": 2,
		"Cyber Petit Angel": 2, "Cyber Angel Benten": 2, "Cyber Angel Idaten": 1, "Cyber Angel Dakini": 1,
		"Polymerization": 3, "Pot of Greed": 1, "Dian Keto the Cure Master": 2, "Fissure": 2, "Monster Reborn": 1}, "extra": {"Cyber Blader": 2}},
	"syrus": {"name": "Roid", "cards": {"Gyroid": 3, "Steamroid": 3, "Drillroid": 3, "Submarineroid": 3, "Truckroid": 3,
		"Expressroid": 3, "Cycroid": 2, "Rescueroid": 1,
		"Polymerization": 4, "Pot of Greed": 1, "Dian Keto the Cure Master": 2, "Fissure": 1, "Monster Reborn": 1}, "extra": {"Steam Gyroid": 2, "Super Vehicroid Jumbo Drill": 1}},
	"aster": {"name": "Destiny HERO", "cards": {"Destiny HERO - Diamond Dude": 3, "Destiny HERO - Doom Lord": 2, "Destiny HERO - Dasher": 2,
		"Destiny HERO - Defender": 2, "Destiny HERO - Captain Tenacious": 2, "Destiny HERO - Malicious": 3, "Destiny HERO - Doublecross": 2,
		"Destiny HERO - Dunker": 2, "Destiny HERO - Disk Commander": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Fissure": 2, "Raigeki": 1}},
	"jack": {"name": "Resonator", "cards": {"Stygian Street Patrol": 2, "Dark Resonator": 3, "Mad Archfiend": 3, "Twin-Sword Marauder": 3,
		"Big Piece Golem": 2, "Medium Piece Golem": 2, "Vice Dragon": 2, "Snipe Hunter": 2, "Battle Fader": 1, "Sinister Sprocket": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Raigeki": 1}, "extra": {"Red Dragon Archfiend": 2, "Exploder Dragonwing": 1}},
	"crow": {"name": "Blackwing", "cards": {"Blackwing - Bora the Spear": 3, "Blackwing - Gale the Whirlwind": 3, "Blackwing - Sirocco the Dawn": 2,
		"Blackwing - Blizzard the Far North": 3, "Blackwing - Kalut the Moon Shadow": 3, "Blackwing - Shura the Blue Flame": 3,
		"Blackwing - Elphin the Raven": 2, "Blackwing - Fane the Steel Chain": 2, 
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Dian Keto the Cure Master": 1}, "extra": {"Blackwing Armor Master": 2, "Blackwing Armed Wing": 1}},
	"akiza": {"name": "Rose", "cards": {"Rainbow Flower": 2, "Twilight Rose Knight": 3, "Lord Poison": 2, "Copy Plant": 2, "Revival Rose": 2, "Dark Verger": 3,
		"Botanical Lion": 2, "Evil Thorn": 2, "Rose Tentacles": 2, "Lonefire Blossom": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Dark Hole": 1}, "extra": {"Black Rose Dragon": 2, "Splendid Rose": 1}},
	"kalin": {"name": "Infernity", "cards": {"Infernity Necromancer": 3, "Infernity Archfiend": 3, "Infernity Beast": 3, "Infernity Avenger": 3,
		"Infernity Mirage": 2, "Infernity Dwarf": 2, "Infernity Guardian": 2, "Infernity Knight": 2, "Stygian Street Patrol": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Dark Hole": 1, "Fissure": 2, "Hinotama": 3}, "extra": {"Infernity Doom Dragon": 1}},
	"shark": {"name": "Shark", "cards": {"Big Jaws": 3, "Shark Stickers": 3, "Hammer Shark": 3, "Spear Shark": 2, "Double Shark": 3,
		"Eagle Shark": 2, "Cat Shark": 2, "Skull Kraken": 2, "Sharkraken": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Fissure": 2, "Dian Keto the Cure Master": 1}, "extra": {"Number 17: Leviathan Dragon": 2, "Black Ray Lancer": 1, "Number 32: Shark Drake": 1}},
	"kite": {"name": "Photon", "cards": {"Galaxy-Eyes Photon Dragon": 3, "Photon Thrasher": 3, "Photon Crusher": 3, "Photon Lizard": 2,
		"Photon Sabre Tiger": 3, "Galaxy Knight": 2, "Photon Cerberus": 2, "Galaxy Soldier": 2, "Photon Leo": 2,
		"Pot of Greed": 1, "Monster Reborn": 1, "Raigeki": 1, "Fissure": 2}, "extra": {"Number 62: Galaxy-Eyes Prime Photon Dragon": 1, "Starliege Paladynamo": 2}},
	"vector": {"name": "Umbral Horror", "cards": {"Umbral Horror Ghoul": 3, "Umbral Horror Unform": 3, "Umbral Horror Will o' the Wisp": 3,
		"Umbral Horror Ghost": 3, "Archfiend Soldier": 3, "Summoned Skull": 2, "Ryu-Kishin Powered": 3, "Vorse Raider": 2,
		"Pot of Greed": 1, "Dark Hole": 1, "Monster Reborn": 1, "Fissure": 2, "Hinotama": 3}, "extra": {"Gagaga Cowboy": 2}},
	# (0.80.0) The 15 new duelists: competitive deck (their key) and the two anime decks.
	"mako": {"name": "Kings of the Sea", "cards": {"The Legendary Fisherman III": 2, "The Legendary Fisherman": 2, "Mermail Abyssteus": 1, "Mermail Abysspike": 2, "Mermail Abyssmegalo": 2, "Atlantean Dragoons": 3, "Atlantean Marksman": 2, "Atlantean Heavy Infantry": 2, "Deep Sea Diva": 3, "Fortress Whale": 1, "Kairyu-Shin": 1, "Great White": 1, "A Legendary Ocean": 2, "Umi": 2, "Salvage": 2, "Fortress Whale's Oath": 2, "Abyss-sphere": 2, "Torrential Tribute": 1, "Tornado Wall": 2, "Big Wave Small Wave": 1, "Ocean Dragon Lord - Kairyu-Shin": 1, "Abyss-scale of the Mizuchi": 2, "Chaos Trap Hole": 1},
		"extra": {"Bahamut Shark": 1, "Mermail Abyssgaios": 1, "Gem-Knight Pearl": 1, "Number 101: Silent Honor ARK": 1}},
	"anime_mako_1": {"name": "Mako · Duelist Kingdom", "cards": {"The Legendary Fisherman": 3, "Great White": 2, "Jellyfish": 2, "Fiend Kraken": 2, "Kairyu-Shin": 2, "Star Boy": 2, "Fortress Whale": 2, "Electric Jellyfish": 1, "Cranium Fish": 2, "7 Colored Fish": 2, "Gyakutenno Megami": 1, "Armored Starfish": 2, "Crazy Fish": 2, "Umi": 3, "A Legendary Ocean": 1, "Pot of Greed": 1, "Fortress Whale's Oath": 2, "Salvage": 2, "Tornado Wall": 2, "Big Wave Small Wave": 1, "Trap Hole": 1, "Call of the Haunted": 1, "Torrential Tribute": 1},
		"extra": {}},
	"anime_mako_2": {"name": "Mako · Lord of the Ocean", "cards": {"The Legendary Fisherman": 2, "The Legendary Fisherman II": 2, "The Legendary Fisherman III": 1, "Fortress Whale": 2, "Kairyu-Shin": 3, "Great White": 2, "Fiend Kraken": 1, "Jellyfish": 2, "Star Boy": 2, "Electric Jellyfish": 1, "Deep Sea Diva": 2, "Armored Starfish": 1, "A Legendary Ocean": 2, "Umi": 1, "Fortress Whale's Oath": 2, "Salvage": 2, "Monster Reborn": 1, "Tornado Wall": 2, "Big Wave Small Wave": 2, "Torrential Tribute": 1, "Mirror Force": 1, "Negate Attack": 1, "Abyss-sphere": 2, "Ocean Dragon Lord - Kairyu-Shin": 1, "Gyakutenno Megami": 1},
		"extra": {}},
	"jesse": {"name": "Crystal Beasts", "cards": {"Crystal Beast Sapphire Pegasus": 3, "Crystal Beast Ruby Carbuncle": 2, "Crystal Beast Amethyst Cat": 3, "Crystal Beast Topaz Tiger": 3, "Crystal Beast Amber Mammoth": 1, "Crystal Beast Cobalt Eagle": 2, "Crystal Beast Emerald Tortoise": 2, "Rainbow Dragon": 1, "Crystal Beast Rainbow Dragon": 1, "Rainbow Dark Dragon": 1, "Crystal Beacon": 2, "Crystal Bond": 3, "Rainbow Bridge": 2, "Ancient City - Rainbow Ruins": 1, "Crystal Abundance": 2, "Rare Value": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Crystal Blessing": 1, "Rainbow Gravity": 1, "Crystal Promise": 1, "Ultimate Crystal Magic": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Solemn Judgment": 1, "Rainbow Refraction": 1},
		"extra": {"Rainbow Overdragon": 1}},
	"anime_jesse_1": {"name": "Jesse · The Crystal Beasts", "cards": {"Crystal Beast Sapphire Pegasus": 3, "Crystal Beast Ruby Carbuncle": 2, "Crystal Beast Amethyst Cat": 2, "Crystal Beast Topaz Tiger": 2, "Crystal Beast Amber Mammoth": 3, "Crystal Beast Cobalt Eagle": 3, "Crystal Beast Emerald Tortoise": 2, "Rainbow Dragon": 1, "Crystal Abundance": 1, "Crystal Promise": 2, "Rare Value": 3, "Crystal Beacon": 2, "Ancient City - Rainbow Ruins": 2, "Crystal Blessing": 1, "Pot of Greed": 1, "Crystal Release": 1, "Rainbow Gravity": 2, "Crystal Tree": 2, "Mirror Force": 1, "Sakuretsu Armor": 1, "Magic Cylinder": 1, "Draining Shield": 2},
		"extra": {}},
	"anime_jesse_2": {"name": "Jesse · Rainbow in the Dark", "cards": {"Crystal Beast Sapphire Pegasus": 3, "Crystal Beast Ruby Carbuncle": 2, "Crystal Beast Amethyst Cat": 3, "Crystal Beast Topaz Tiger": 3, "Crystal Beast Amber Mammoth": 1, "Crystal Beast Cobalt Eagle": 2, "Crystal Beast Emerald Tortoise": 2, "Rainbow Dragon": 1, "Rainbow Dark Dragon": 1, "Advanced Crystal Beast Sapphire Pegasus": 1, "Advanced Crystal Beast Ruby Carbuncle": 1, "Advanced Dark": 1, "Crystal Abundance": 1, "Crystal Promise": 2, "Rare Value": 2, "Crystal Beacon": 2, "Ancient City - Rainbow Ruins": 1, "Crystal Blessing": 2, "Crystal Bond": 2, "Rainbow Gravity": 2, "Crystal Tree": 2, "Rainbow Refraction": 1, "Magic Cylinder": 1, "The Warrior Returning Alive": 1},
		"extra": {}},
	"hassleberry": {"name": "Ultimate Tyranno", "cards": {"Babycerasaurus": 2, "Petiteranodon": 3, "Souleating Oviraptor": 3, "Miscellaneousaurus": 3, "Fossil Dyna Pachycephalo": 1, "Ultimate Tyranno": 2, "Super Conductor Tyranno": 1, "Sabersaurus": 1, "Gilasaurus": 2, "Black Tyranno": 1, "Dark Driceratops": 1, "Giant Rex": 1, "Element Saurus": 1, "Frostosaurus": 1, "Jurassic World": 2, "Lost World": 2, "Fossil Dig": 2, "Big Evolution Pill": 2, "Survival Instinct": 2, "Tail Swipe": 1, "Jurassic Impact": 1, "Evolution Burst": 2, "Ultimate Conductor Tyranno": 1, "Wall of Revealing Light": 1, "Lightning Vortex": 1},
		"extra": {}},
	"anime_hassleberry_1": {"name": "Hassleberry · Dino Platoon", "cards": {"Gilasaurus": 3, "Dark Driceratops": 2, "Black Tyranno": 2, "Sabersaurus": 3, "Hyper Hammerhead": 2, "Babycerasaurus": 2, "Two-Headed King Rex": 2, "Element Saurus": 2, "Frostosaurus": 1, "Sauropod Brachion": 2, "Giant Rex": 2, "Jurassic World": 3, "Big Evolution Pill": 2, "Fossil Dig": 2, "Rush Recklessly": 2, "Tail Swipe": 2, "Survival Instinct": 2, "Jurassic Impact": 2, "Sakuretsu Armor": 1, "Ojama Trio": 1},
		"extra": {}},
	"anime_hassleberry_2": {"name": "Hassleberry · Super Conductor", "cards": {"Gilasaurus": 3, "Dark Driceratops": 2, "Black Tyranno": 1, "Sabersaurus": 3, "Hyper Hammerhead": 2, "Babycerasaurus": 3, "Fossil Dyna Pachycephalo": 2, "Ultimate Tyranno": 1, "Super Conductor Tyranno": 2, "Element Saurus": 1, "Frostosaurus": 1, "Two-Headed King Rex": 1, "Giant Rex": 1, "Jurassic World": 2, "Big Evolution Pill": 2, "Fossil Dig": 3, "Evolution Burst": 2, "Tail Swipe": 2, "Survival Instinct": 2, "Jurassic Impact": 2, "Michizure": 1, "Messenger of Peace": 1},
		"extra": {}},
	"atticus": {"name": "Red-Eyes Legacy", "cards": {"Red-Eyes Black Dragon": 3, "Red-Eyes Darkness Metal Dragon": 1, "Red-Eyes Black Meteor Dragon": 1, "Red-Eyes Wyvern": 2, "Red-Eyes Retro Dragon": 2, "Red-Eyes Baby Dragon": 1, "Red-Eyes Darkness Dragon": 1, "Black Dragon's Chick": 2, "Gearfried the Red-Eyes Iron Knight": 1, "Red-Eyes Archfiend of Lightning": 1, "Red-Eyes Insight": 3, "Red-Eyes Fusion": 2, "Inferno Fire Blast": 2, "The Black Stone of Legend": 3, "Return of the Red-Eyes": 2, "Red-Eyes Spirit": 2, "Red-Eyes Burn": 1, "Dragon's Mirror": 2, "Silver's Cry": 3, "Cards of the Red Stone": 2, "Red-Eyes Black Flare Dragon": 1, "Magic Jammer": 1, "Acid Trap Hole": 1},
		"extra": {"Red-Eyes Dark Dragoon": 1, "Red-Eyes Slash Dragon": 1, "Red-Eyes Flare Metal Dragon": 1, "Meteor Black Comet Dragon": 1, "Black Skull Dragon": 1}},
	"anime_atticus_1": {"name": "Atticus · Nightshroud", "cards": {"Red-Eyes Black Dragon": 3, "Red-Eyes Darkness Dragon": 3, "Black Dragon's Chick": 3, "Red-Eyes Baby Dragon": 1, "Darkness Destroyer": 2, "Dark Blade": 2, "Kaiser Glider": 2, "Luster Dragon": 3, "Lord of D.": 2, "Masked Dragon": 3, "Inferno Fire Blast": 2, "Dragon's Mirror": 2, "Stamping Destruction": 2, "Dark Hole": 1, "The Flute of Summoning Dragon": 2, "Trap Hole": 1, "Dust Tornado": 2, "Mage Power": 1, "United We Stand": 1, "Chain Burst": 1, "Emergency Provisions": 1},
		"extra": {"Meteor Black Dragon": 1, "Black Skull Dragon": 1}},
	"anime_atticus_2": {"name": "Atticus · The Blue Idol", "cards": {"Red-Eyes Black Dragon": 3, "Red-Eyes Darkness Dragon": 2, "Red-Eyes Darkness Metal Dragon": 1, "Black Dragon's Chick": 2, "Red-Eyes Baby Dragon": 1, "Masked Dragon": 3, "Luster Dragon": 3, "Lord of D.": 1, "Kaiser Glider": 2, "Dragon Ice": 2, "Exploder Dragon": 2, "Darkness Destroyer": 1, "Inferno Fire Blast": 2, "Dragon's Mirror": 2, "The Flute of Summoning Dragon": 2, "Stamping Destruction": 2, "Polymerization": 2, "Dragon's Rebirth": 2, "Dust Tornado": 2, "Rope of Life": 1, "Desert Sunlight": 1, "Good Goblin Housekeeping": 1},
		"extra": {"Meteor Black Dragon": 1, "Black Skull Dragon": 1}},
	"yubel": {"name": "Nightmare of Love", "cards": {"Yubel": 3, "Spirit of Yubel": 3, "Yubel - Terror Incarnate": 1, "Yubel - The Ultimate Nightmare": 1, "Samsara D Lotus": 2, "Dark Grepher": 2, "Armageddon Knight": 2, "Archfiend Soldier": 2, "Summoned Skull": 2, "Sangan": 1, "Giant Orc": 1, "Opening of the Spirit Gates": 2, "Nightmare Throne": 2, "Unchained Soul of Sharvara": 1, "Fiend's Sanctuary": 2, "Dark Corridor": 2, "Mystic Plasma Zone": 2, "Nightmare Pain": 3, "Mirror Gate": 2, "Spirit Barrier": 2, "Floodgate Trap Hole": 1, "Dark Bribe": 1},
		"extra": {"Phantom of Yubel": 2, "Yubel - The Loving Defender Forever": 1}},
	"anime_yubel_1": {"name": "Yubel · The Other Dimension", "cards": {"Yubel": 3, "Yubel - Terror Incarnate": 1, "Yubel - The Ultimate Nightmare": 1, "Dark Grepher": 2, "Archfiend Soldier": 2, "Summoned Skull": 2, "Giant Orc": 2, "Sangan": 1, "Dark Blade": 1, "Opticlops": 2, "Vice Dragon": 2, "Infernalqueen Archfiend": 1, "Terrorking Archfiend": 1, "Fiend's Sanctuary": 2, "Altar for Tribute": 2, "Dark Corridor": 2, "Mystic Plasma Zone": 2, "Pandemonium": 2, "Nightmare Pain": 3, "Mirror Gate": 2, "Spirit Barrier": 2, "Big Bang Shot": 1, "Legacy of Yata-Garasu": 1},
		"extra": {}},
	"anime_yubel_2": {"name": "Yubel · The Last Nightmare", "cards": {"Yubel": 3, "Yubel - Terror Incarnate": 1, "Yubel - The Ultimate Nightmare": 1, "Dark Grepher": 2, "Archfiend Soldier": 2, "Summoned Skull": 2, "Giant Orc": 2, "Sangan": 1, "Opticlops": 2, "Infernalqueen Archfiend": 1, "Terrorking Archfiend": 1, "Skull Archfiend of Lightning": 1, "Armageddon Knight": 1, "Fiend's Sanctuary": 2, "Altar for Tribute": 2, "Dark Corridor": 2, "Mystic Plasma Zone": 1, "Pandemonium": 2, "Super Polymerization": 1, "Nightmare Pain": 3, "Mirror Gate": 2, "Spirit Barrier": 2, "Torrential Tribute": 1, "Wild Nature's Release": 1, "Divine Wrath": 1},
		"extra": {}},
	"leo5ds": {"name": "Power Tools", "cards": {"Morphtronic Celfon": 3, "Morphtronic Datatron": 3, "Morphtronic Boarden": 2, "Morphtronic Lantron": 2, "Morphtronic Scopen": 2, "Morphtronic Radion": 2, "Morphtronic Magnen": 2, "Morphtronic Remoten": 2, "Morphtronic Rusty Engine": 2, "Morphtronic Smartfon": 1, "Morphtronic Clocken": 1, "Morphtronic Slingen": 1, "Junk Synchron": 1, "Morphtronic Accelerator": 2, "Morphtronic Map": 2, "Morphtronic Repair Unit": 2, "Morphtransition": 2, "Wonder Wand": 2, "Morphtronic Bind": 2, "Morphtronic Forcefield": 1, "Morphtronic Monitron": 1, "Enemy Controller": 1, "Rising Energy": 1},
		"extra": {"Power Tool Dragon": 2, "Power Tool Braver Dragon": 1, "Power Tool Mecha Dragon": 1, "Life Stream Dragon": 1, "Junk Warrior": 1, "Stardust Dragon": 1, "Ancient Fairy Dragon": 1}},
	"anime_leo5ds_1": {"name": "Leo · Fortune Cup", "cards": {"Morphtronic Boomboxen": 3, "Morphtronic Magnen": 3, "Morphtronic Radion": 3, "Morphtronic Remoten": 2, "Morphtronic Celfon": 2, "Morphtronic Datatron": 2, "Morphtronic Cord": 2, "Morphtronic Scopen": 2, "Morphtronic Clocken": 2, "Morphtronic Slingen": 2, "Morphtronic Accelerator": 2, "Morphtronic Map": 2, "Morphtronic Repair Unit": 2, "Morphtransition": 2, "Morphtronic Bind": 2, "Morphtronic Forcefield": 2, "Morphtronic Monitron": 2, "Remote Revenge": 1, "Synchro Strike": 1, "Give and Take": 1},
		"extra": {"Morphtronic Earfon": 1}},
	"anime_leo5ds_2": {"name": "Leo · Power Tool Dragon", "cards": {"Morphtronic Boomboxen": 2, "Morphtronic Magnen": 2, "Morphtronic Radion": 2, "Morphtronic Remoten": 2, "Morphtronic Celfon": 2, "Morphtronic Datatron": 2, "Morphtronic Scopen": 2, "Morphtronic Lantron": 2, "Morphtronic Clocken": 2, "Morphtronic Boarden": 2, "Morphtronic Smartfon": 1, "Morphtronic Rusty Engine": 2, "Morphtronic Accelerator": 3, "Morphtronic Map": 2, "Morphtronic Repair Unit": 2, "Morphtransition": 2, "Wonder Wand": 1, "Morphtronic Bind": 2, "Morphtronic Forcefield": 2, "Morphtronic Monitron": 1, "Battle Mania": 1, "Card of Sacrifice": 1},
		"extra": {"Power Tool Dragon": 2, "Life Stream Dragon": 1}},
	"luna": {"name": "Ancient Fairy", "cards": {"Kuribon": 3, "Sunny Pixie": 3, "Fairy Archer": 3, "Regulus": 1, "Fairy King Truesdale": 1, "Sunlight Unicorn": 2, "Glow-Up Bulb": 1, "Spore": 1, "Mystical Fairy Elfuria": 1, "Fairy Tail - Snow": 1, "Tytannial, Princess of Camellias": 1, "Prickle Fairy": 1, "Marshmallon": 1, "Shining Angel": 2, "Honest": 2, "Watapon": 2, "Ancient Forest": 2, "Fairy Box": 2, "Synchro Change": 2, "Fairy Wind": 2, "Magic Cylinder": 1, "Negate Attack": 1, "Drowning Mirror Force": 1, "Starlight Road": 1, "Shadow Spell": 1, "Karma Cut": 1},
		"extra": {"Ancient Fairy Dragon": 2, "Ancient Fairy Life Dragon": 1, "Ancient Pixie Dragon": 1, "Stardust Dragon": 1, "Power Tool Dragon": 1, "Ancient Sacred Wyvern": 1}},
	"anime_luna_1": {"name": "Luna · Spirit World", "cards": {"Kuribon": 3, "Sunny Pixie": 2, "Fairy Archer": 2, "Regulus": 2, "Mystical Elf": 3, "Marshmallon": 1, "Spirit of the Breeze": 3, "Fairy of the Spring": 2, "Shining Angel": 2, "Watapon": 2, "Cure Mermaid": 2, "Dark Valkyria": 1, "Honest": 2, "Ancient Forest": 2, "Fairy Box": 2, "Fairy Wind": 2, "Draining Shield": 2, "Limit Reverse": 1, "Half or Nothing": 1, "Descending Lost Star": 1, "Tuner's Barrier": 1, "Fighting Spirit": 1},
		"extra": {"Ancient Fairy Dragon": 1}},
	"anime_luna_2": {"name": "Luna · Ancient Fairy Dragon", "cards": {"Kuribon": 3, "Sunny Pixie": 3, "Fairy Archer": 3, "Regulus": 1, "Fairy King Truesdale": 1, "Sunlight Unicorn": 2, "Mystical Elf": 2, "Marshmallon": 2, "Spirit of the Breeze": 2, "Shining Angel": 2, "Watapon": 2, "Honest": 2, "Prickle Fairy": 1, "Ancient Forest": 2, "Fairy Box": 2, "Fairy Wind": 2, "Synchro Change": 2, "Draining Shield": 2, "Lightwave Tuning": 1, "Synchro Boost": 1, "Zero Gravity": 1, "Battle Mania": 1},
		"extra": {"Ancient Fairy Dragon": 2, "Ancient Pixie Dragon": 1}},
	"trudge": {"name": "Sector Security", "cards": {"Jutte Fighter": 3, "Pursuit Chaser": 3, "Handcuffs Dragon": 3, "Gate Blocker": 2, "Ultimate Baseball Kid": 1, "Marauding Captain": 2, "Command Knight": 2, "Goblin Attack Force": 2, "Max Warrior": 2, "Shield Warrior": 1, "Card Trooper": 1, "Fortress Warrior": 1, "Junk Synchron": 1, "Changer Synchron": 1, "Reinforcement of the Army": 2, "Tuning": 2, "Polymerization": 2, "Security Block": 2, "Quaking Mirror Force": 1, "Draining Shield": 1, "Chain Disappearance": 1, "Breakthrough Skill": 1, "Half Unbreak": 1, "Fissure": 1, "Offerings to the Doomed": 1},
		"extra": {"Goyo Guardian": 2, "Goyo Chaser": 1, "Goyo King": 1, "Goyo Defender": 1, "Goyo Predator": 1, "Goyo Emperor": 1, "Junk Warrior": 1}},
	"anime_trudge_1": {"name": "Trudge · The Satellite Patrol", "cards": {"Jutte Fighter": 3, "Pursuit Chaser": 2, "Handcuffs Dragon": 2, "Gate Blocker": 2, "Ultimate Baseball Kid": 2, "Goblin Attack Force": 2, "Max Warrior": 3, "Shield Warrior": 2, "Marauding Captain": 2, "Command Knight": 2, "Card Trooper": 2, "Big Shield Gardna": 2, "Reinforcement of the Army": 1, "Tuning": 2, "Rush Recklessly": 2, "Security Block": 2, "Draining Shield": 2, "Descending Lost Star": 1, "Tuner's Barrier": 1, "Remote Revenge": 1, "Graceful Revival": 1, "Half or Nothing": 1},
		"extra": {"Goyo Guardian": 2}},
	"anime_trudge_2": {"name": "Trudge · Goyo Emperor", "cards": {"Jutte Fighter": 3, "Pursuit Chaser": 3, "Handcuffs Dragon": 3, "Gate Blocker": 2, "Ultimate Baseball Kid": 2, "Goblin Attack Force": 2, "Max Warrior": 3, "Shield Warrior": 1, "Marauding Captain": 2, "Command Knight": 2, "Card Trooper": 2, "Fortress Warrior": 1, "Reinforcement of the Army": 1, "Tuning": 2, "Polymerization": 2, "Security Block": 2, "Bottomless Trap Hole": 1, "Scapegoat": 1, "Spellbinding Circle": 1, "Nightmare Wheel": 1, "Mind Control": 1, "Urgent Tuning": 1, "Forbidden Lance": 1},
		"extra": {"Goyo Guardian": 2, "Goyo Chaser": 1, "Goyo King": 1, "Goyo Emperor": 1}},
	"sherry": {"name": "Fleur de Chevalier", "cards": {"Fleur Synchron": 3, "Lady of the Lake": 3, "Twilight Rose Knight": 1, "Necro Fleur": 2, "Sauge de Fleur": 1, "Sorciere de Fleur": 1, "Noble Knight Artorigus": 3, "Noble Knight Gawayn": 2, "Noble Knight Medraut": 2, "Marauding Captain": 2, "Command Knight": 1, "Ignoble Knight of Black Laundsallyn": 1, "Max Warrior": 2, "Reinforcement of the Army": 2, "Fleuret de Fleur": 2, "Tuning": 2, "Swords of Revealing Light": 1, "Magic Cylinder": 1, "Hammer Shot": 1, "Scrap-Iron Scarecrow": 1, "Impenetrable Attack": 1, "Spell Shield Type-8": 1, "Soul Taker": 1, "Widespread Ruin": 1, "Magic Drain": 1, "Miracle's Wake": 1},
		"extra": {"Chevalier de Fleur": 2, "Baronne de Fleur": 1, "Junk Warrior": 1, "Stardust Dragon": 1, "Goyo Guardian": 1}},
	"anime_sherry_1": {"name": "Sherry · The Grand Prix", "cards": {"Fleur Synchron": 3, "Twilight Rose Knight": 2, "Necro Fleur": 3, "Sauge de Fleur": 1, "Sorciere de Fleur": 1, "Lady of the Lake": 2, "Marauding Captain": 2, "Command Knight": 2, "Max Warrior": 2, "Shield Warrior": 2, "Noble Knight Artorigus": 2, "Noble Knight Gawayn": 2, "Big Shield Gardna": 1, "Fleuret de Fleur": 2, "Reinforcement of the Army": 2, "Tuning": 2, "Swords of Revealing Light": 1, "Draining Shield": 2, "Phoenix Wing Wind Blast": 1, "Give and Take": 1, "Card of Sacrifice": 1, "Reckless Greed": 1, "Raigeki Break": 1, "Synchro Boost": 1},
		"extra": {"Chevalier de Fleur": 2}},
	"anime_sherry_2": {"name": "Sherry · Knight of the Flower", "cards": {"Fleur Synchron": 3, "Twilight Rose Knight": 2, "Necro Fleur": 2, "Sauge de Fleur": 1, "Sorciere de Fleur": 1, "Lady of the Lake": 2, "Marauding Captain": 2, "Command Knight": 2, "Max Warrior": 2, "Noble Knight Artorigus": 2, "Noble Knight Gawayn": 3, "Noble Knight Medraut": 2, "Ignoble Knight of Black Laundsallyn": 1, "Fleuret de Fleur": 2, "Reinforcement of the Army": 2, "Tuning": 2, "Swords of Revealing Light": 1, "Mystical Space Typhoon": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1, "Seven Tools of the Bandit": 1, "Fighting Spirit": 1, "Limit Reverse": 1, "Shrink": 1, "Threatening Roar": 1},
		"extra": {"Chevalier de Fleur": 2, "Goyo Guardian": 1}},
	"goodwin": {"name": "Inti and Quilla", "cards": {"Supay": 3, "Ascator, Dawnwalker": 3, "Supay, Duskwalker": 2, "Earthbound Immortal Wiraqocha Rasca": 3, "Earthbound Immortal Ccarayhua": 2, "Earthbound Linewalker": 2, "Plaguespreader Zombie": 1, "Fire Ant Ascator": 2, "Sangan": 1, "Card Trooper": 2, "Mezuki": 2, "Glow-Up Bulb": 1, "Earthbound Geoglyph": 2, "Fires of Doomsday": 1, "Tuning": 2, "Earthbound Immortal Revival": 2, "Earthbound Wave": 2, "Roar of the Earthbound Immortal": 2, "Earthbound Release": 2, "Windstorm of Etaqua": 1, "Xyz Reborn": 1, "Staunch Defender": 1},
		"extra": {"Sun Dragon Inti": 2, "Moon Dragon Quilla": 2, "Crimson Dragon": 1}},
	"anime_goodwin_1": {"name": "Goodwin · The Director", "cards": {"Supay": 3, "Ascator, Dawnwalker": 3, "Earthbound Immortal Wiraqocha Rasca": 2, "Earthbound Linewalker": 2, "Sangan": 1, "Big Shield Gardna": 2, "Card Trooper": 2, "Mezuki": 2, "Plaguespreader Zombie": 2, "Fire Ant Ascator": 2, "Marshmallon": 2, "Spirit Reaper": 2, "Earthbound Geoglyph": 2, "Fires of Doomsday": 2, "Tuning": 2, "Swords of Revealing Light": 1, "Earthbound Wave": 2, "Roar of the Earthbound Immortal": 2, "Torrential Tribute": 1, "Giant Trap Hole": 1, "Creature Swap": 1, "Safe Zone": 1},
		"extra": {"Sun Dragon Inti": 1, "Moon Dragon Quilla": 1}},
	"anime_goodwin_2": {"name": "Goodwin · Earthbound God", "cards": {"Supay": 3, "Ascator, Dawnwalker": 3, "Earthbound Immortal Wiraqocha Rasca": 2, "Earthbound Linewalker": 2, "Sangan": 1, "Card Trooper": 2, "Mezuki": 2, "Plaguespreader Zombie": 2, "Fire Ant Ascator": 2, "Marshmallon": 2, "Spirit Reaper": 2, "Glow-Up Bulb": 2, "Earthbound Geoglyph": 2, "Fires of Doomsday": 2, "Tuning": 2, "Earthbound Immortal Revival": 2, "Earthbound Wave": 2, "Roar of the Earthbound Immortal": 1, "Torrential Tribute": 1, "Earthbound Release": 1, "Bottomless Trap Hole": 1, "Mirror Wall": 1},
		"extra": {"Sun Dragon Inti": 2, "Moon Dragon Quilla": 2}},
	"halldor": {"name": "Father of the Aesir", "cards": {"Nordic Relic Draupnir": 1, "Nordic Relic Gungnir": 2, "Gotterdammerung": 2, "The Nordic Lights": 2, "Gleipnir, the Fetters of Fenrir": 1, "Valkyrie of the Nordic Ascendant": 3, "Mimir of the Nordic Ascendant": 3, "Vanadis of the Nordic Ascendant": 3, "Mara of the Nordic Alfar": 2, "Ljosalf of the Nordic Alfar": 3, "Guldfaxe of the Nordic Beasts": 1, "Tanngrisnir of the Nordic Beasts": 2, "Shining Angel": 2, "Honest": 2, "Splendid Venus": 1, "Nordic Relic Hlidskjalf": 1, "Nordic Relic Svalinn": 2, "Odin's Eye": 1, "Valhalla, Hall of the Fallen": 1, "Divine Relic Mjollnir": 2, "Void Trap Hole": 1, "A Hero Emerges": 1, "Deep Dark Trap Hole": 1},
		"extra": {"Odin, Father of the Aesir": 2, "Thor, Lord of the Aesir": 1, "Loki, Lord of the Aesir": 1, "Ancient Fairy Dragon": 1, "Stardust Dragon": 1}},
	"dragan": {"name": "Lord of Thunder", "cards": {"Nordic Relic Draupnir": 2, "Nordic Relic Gungnir": 2, "Gotterdammerung": 2, "The Nordic Lights": 2, "Gleipnir, the Fetters of Fenrir": 2, "Tanngrisnir of the Nordic Beasts": 3, "Tanngnjostr of the Nordic Beasts": 3, "Guldfaxe of the Nordic Beasts": 3, "Nordic Beast Gullinbursti": 3, "Garmr of the Nordic Beasts": 3, "Valkyrie of the Nordic Ascendant": 1, "Mara of the Nordic Alfar": 2, "Fenrir the Nordic Wolf": 1, "Jormungardr the Nordic Serpent": 1, "Card Trooper": 2, "Nordic Relic Megingjord": 2, "Divine Relic Mjollnir": 1, "Nordic Relic Brisingamen": 2, "Blazing Mirror Force": 1, "Damage Diet": 1, "Time-Space Trap Hole": 1},
		"extra": {"Thor, Lord of the Aesir": 2, "Odin, Father of the Aesir": 1, "Loki, Lord of the Aesir": 1, "Junk Warrior": 1, "Stardust Dragon": 1}},
	"broder": {"name": "Lord of Tricks", "cards": {"Nordic Relic Draupnir": 2, "Nordic Relic Gungnir": 1, "Gotterdammerung": 2, "The Nordic Lights": 2, "Gleipnir, the Fetters of Fenrir": 2, "Dverg of the Nordic Alfar": 3, "Ljosalf of the Nordic Alfar": 3, "Svartalf of the Nordic Alfar": 3, "Mara of the Nordic Alfar": 3, "Alviss of the Nordic Alfar": 3, "Valkyrie of the Nordic Ascendant": 1, "Guldfaxe of the Nordic Beasts": 2, "Tanngrisnir of the Nordic Beasts": 1, "Mimir of the Nordic Ascendant": 1, "Breaker the Magical Warrior": 1, "Nordic Relic Laevateinn": 2, "Nordic Relic Brisingamen": 1, "Magic Cylinder": 1, "Dark Bribe": 1, "Trap Stun": 2, "Widespread Ruin": 1, "Quaking Mirror Force": 1, "Adhesion Trap Hole": 1},
		"extra": {"Loki, Lord of the Aesir": 2, "Odin, Father of the Aesir": 1, "Thor, Lord of the Aesir": 1, "Arcanite Magician": 1, "Stardust Dragon": 1}},
	"anime_halldor_1": {"name": "Halldor · The Polar Star", "cards": {"Nordic Relic Draupnir": 1, "Nordic Relic Gungnir": 2, "Gotterdammerung": 1, "Valkyrie of the Nordic Ascendant": 3, "Mimir of the Nordic Ascendant": 3, "Vanadis of the Nordic Ascendant": 2, "Shining Angel": 3, "Honest": 1, "Marshmallon": 3, "Mystical Elf": 2, "Hecatrice": 3, "Tethys, Goddess of Light": 1, "Zeradias, Herald of Heaven": 1, "Splendid Venus": 1, "Nordic Relic Hlidskjalf": 2, "Odin's Eye": 2, "Valhalla, Hall of the Fallen": 2, "The Sanctuary in the Sky": 2, "Nordic Relic Svalinn": 2, "Impenetrable Attack": 1, "Jar of Greed": 1, "Floodgate Trap Hole": 1},
		"extra": {"Odin, Father of the Aesir": 1}},
	"anime_halldor_2": {"name": "Halldor · Odin Descends", "cards": {"Nordic Relic Draupnir": 2, "Nordic Relic Gungnir": 1, "Gotterdammerung": 2, "Valkyrie of the Nordic Ascendant": 3, "Mimir of the Nordic Ascendant": 3, "Vanadis of the Nordic Ascendant": 2, "Mara of the Nordic Alfar": 3, "Shining Angel": 3, "Honest": 1, "Marshmallon": 2, "Hecatrice": 2, "Tethys, Goddess of Light": 1, "Splendid Venus": 1, "Guldfaxe of the Nordic Beasts": 2, "Nordic Relic Hlidskjalf": 2, "Odin's Eye": 2, "Valhalla, Hall of the Fallen": 2, "The Sanctuary in the Sky": 1, "Nordic Relic Svalinn": 2, "Blazing Mirror Force": 1, "Wall of Revealing Light": 1, "Chaos Trap Hole": 1},
		"extra": {"Odin, Father of the Aesir": 2, "Thor, Lord of the Aesir": 1}},
	"anime_dragan_1": {"name": "Dragan · The Polar Star", "cards": {"Nordic Relic Draupnir": 2, "Nordic Relic Gungnir": 1, "Gotterdammerung": 2, "Tanngrisnir of the Nordic Beasts": 3, "Tanngnjostr of the Nordic Beasts": 3, "Guldfaxe of the Nordic Beasts": 2, "Nordic Beast Gullinbursti": 2, "Garmr of the Nordic Beasts": 2, "Fenrir the Nordic Wolf": 1, "Big Shield Gardna": 2, "Battle Ox": 3, "Mad Sword Beast": 2, "Card Trooper": 2, "Gearfried the Iron Knight": 1, "Nordic Relic Megingjord": 2, "Divine Relic Mjollnir": 1, "Nordic Relic Brisingamen": 2, "Rush Recklessly": 2, "Fissure": 2, "Graceful Revival": 1, "Forbidden Lance": 1, "Zero Gravity": 1},
		"extra": {"Thor, Lord of the Aesir": 1}},
	"anime_dragan_2": {"name": "Dragan · Thor's Hammer", "cards": {"Nordic Relic Draupnir": 2, "Nordic Relic Gungnir": 1, "Gotterdammerung": 2, "Tanngrisnir of the Nordic Beasts": 3, "Tanngnjostr of the Nordic Beasts": 3, "Guldfaxe of the Nordic Beasts": 2, "Nordic Beast Gullinbursti": 2, "Garmr of the Nordic Beasts": 2, "Fenrir the Nordic Wolf": 1, "Jormungardr the Nordic Serpent": 2, "Mara of the Nordic Alfar": 2, "Valkyrie of the Nordic Ascendant": 2, "Card Trooper": 2, "Mad Sword Beast": 2, "Nordic Relic Megingjord": 2, "Divine Relic Mjollnir": 2, "Nordic Relic Brisingamen": 2, "Rush Recklessly": 1, "Fissure": 2, "A Hero Emerges": 1, "Soul Exchange": 1, "Shadow Spell": 1},
		"extra": {"Thor, Lord of the Aesir": 2, "Odin, Father of the Aesir": 1}},
	"anime_broder_1": {"name": "Broder · The Polar Star", "cards": {"Nordic Relic Draupnir": 2, "Nordic Relic Gungnir": 2, "Gotterdammerung": 1, "Dverg of the Nordic Alfar": 3, "Ljosalf of the Nordic Alfar": 3, "Svartalf of the Nordic Alfar": 2, "Mara of the Nordic Alfar": 2, "Alviss of the Nordic Alfar": 3, "Breaker the Magical Warrior": 2, "Skilled Dark Magician": 2, "Old Vindictive Magician": 2, "Magician of Faith": 2, "Apprentice Magician": 2, "Nordic Relic Laevateinn": 2, "Nordic Relic Brisingamen": 1, "Dark Bribe": 2, "Trap Stun": 2, "Dust Tornado": 2, "Nightmare Wheel": 1, "Scrap-Iron Scarecrow": 1, "Draining Shield": 1},
		"extra": {"Loki, Lord of the Aesir": 1}},
	"anime_broder_2": {"name": "Broder · Loki's Game", "cards": {"Nordic Relic Draupnir": 2, "Nordic Relic Gungnir": 2, "Gotterdammerung": 1, "Dverg of the Nordic Alfar": 3, "Ljosalf of the Nordic Alfar": 3, "Svartalf of the Nordic Alfar": 2, "Mara of the Nordic Alfar": 2, "Alviss of the Nordic Alfar": 2, "Breaker the Magical Warrior": 1, "Old Vindictive Magician": 2, "Magician of Faith": 2, "Apprentice Magician": 2, "Valkyrie of the Nordic Ascendant": 2, "Tanngrisnir of the Nordic Beasts": 1, "Mimir of the Nordic Ascendant": 1, "Nordic Relic Laevateinn": 2, "Nordic Relic Brisingamen": 1, "Dark Bribe": 2, "Trap Stun": 2, "Dust Tornado": 2, "Breakthrough Skill": 1, "Malevolent Catastrophe": 1, "Forbidden Chalice": 1},
		"extra": {"Loki, Lord of the Aesir": 2, "Odin, Father of the Aesir": 1}},
	"bronk": {"name": "Gear Gigant", "cards": {"Geargiano": 2, "Geargiano Mk-II": 2, "Geargiano Mk-III": 2, "Geargiarmor": 3, "Geargiarsenal": 2, "Geargiaccelerator": 2, "Geargiattacker": 2, "Geargianchor": 1, "Geargiauger": 1, "Card Trooper": 2, "Machina Gearframe": 2, "Machina Fortress": 2, "Cyber Dragon": 1, "Geargia Change": 2, "Limiter Removal": 1, "Machine Duplication": 2, "Machina Megaform": 1, "Geargiagear": 2, "Damage Condenser": 2, "Miracle's Wake": 1, "Seven Tools of the Bandit": 1, "Hammer Shot": 1, "Storming Mirror Force": 1, "Reckless Greed": 1, "Raigeki Break": 1},
		"extra": {"Gear Gigant X": 2, "Geargiagear Gigant XG": 2, "Number 39: Utopia": 1, "Superdreadnought Rail Cannon Gustav Max": 1, "Number 52: Diamond Crab King": 1, "Abyss Dweller": 1, "Number 34: Terror-Byte": 1}},
	"anime_bronk_1": {"name": "Bronk · Heartland Middle School", "cards": {"Geargiano": 2, "Geargiarmor": 3, "Geargiarsenal": 2, "Geargiaccelerator": 2, "Mechanicalchaser": 2, "Drillroid": 2, "Steamroid": 2, "Gyroid": 2, "Submarineroid": 2, "Card Trooper": 2, "Gogogo Golem": 2, "Big Shield Gardna": 2, "Cyber Dragon": 1, "Limiter Removal": 1, "Machine Duplication": 2, "Rush Recklessly": 2, "Geargia Change": 2, "Geargiagear": 2, "Xyz Soul": 1, "Xyz Burst": 1, "Oh F!sh!": 1, "Xyz Gift": 1, "Xyz Veil": 1},
		"extra": {"Gear Gigant X": 2, "Number 39: Utopia": 1}},
	"anime_bronk_2": {"name": "Bronk · Full Gear", "cards": {"Geargiano": 2, "Geargiano Mk-II": 2, "Geargiarmor": 3, "Geargiarsenal": 2, "Geargiaccelerator": 2, "Geargiattacker": 2, "Geargianchor": 1, "Mechanicalchaser": 2, "Steamroid": 2, "Gyroid": 2, "Card Trooper": 2, "Machina Gearframe": 2, "Big Shield Gardna": 1, "Limiter Removal": 1, "Machine Duplication": 2, "Geargia Change": 2, "Geargiagear": 2, "Torrential Tribute": 1, "Geargiano Mk-III": 1, "Blustering Winds": 1, "Xyz Unit": 1, "Bye Bye Damage": 1, "Oh F!sh!": 1, "Xyz Revenge": 1, "Xyz Veil": 1},
		"extra": {"Gear Gigant X": 2, "Geargiagear Gigant XG": 1, "Number 39: Utopia": 1}},
	"tori": {"name": "Cheer for Hope", "cards": {"Shining Angel": 3, "Hecatrice": 3, "Honest": 2, "Tethys, Goddess of Light": 2, "Zeradias, Herald of Heaven": 2, "Bountiful Artemis": 3, "Marshmallon": 2, "Mystical Elf": 2, "Splendid Venus": 1, "Athena": 1, "Freya, Spirit of Victory": 2, "Kuribon": 1, "Watapon": 1, "The Sanctuary in the Sky": 2, "Valhalla, Hall of the Fallen": 2, "Fairy's Hand Mirror": 2, "Magic Cylinder": 1, "Negate Attack": 1, "Dark Bribe": 1, "Smashing Ground": 1, "Rising Energy": 1, "Damage Diet": 1, "Mirror Wall": 1, "Windstorm of Etaqua": 1, "Chain Disappearance": 1},
		"extra": {"Fairy Cheer Girl": 3, "Number 39: Utopia": 1, "Tiras, Keeper of Genesis": 1, "Number 52: Diamond Crab King": 1, "Abyss Dweller": 1}},
	"anime_tori_1": {"name": "Tori · Cheering Section", "cards": {"Shining Angel": 3, "Hecatrice": 3, "Honest": 2, "Mystical Elf": 3, "Marshmallon": 2, "Freya, Spirit of Victory": 2, "Kuribon": 2, "Watapon": 2, "Mystical Shine Ball": 2, "Bountiful Artemis": 2, "Tethys, Goddess of Light": 2, "Fairy of the Spring": 2, "The Sanctuary in the Sky": 2, "Fairy's Hand Mirror": 2, "Rush Recklessly": 2, "Draining Shield": 2, "Bye Bye Damage": 1, "Xyz Unit": 1, "Xyz Dimension Splash": 1, "Xyz Burst": 1, "Xyz Soul": 1},
		"extra": {"Fairy Cheer Girl": 2}},
	"anime_tori_2": {"name": "Tori · Fairy Cheer Girl", "cards": {"Shining Angel": 3, "Hecatrice": 3, "Honest": 2, "Mystical Elf": 2, "Marshmallon": 2, "Freya, Spirit of Victory": 3, "Kuribon": 2, "Watapon": 2, "Bountiful Artemis": 3, "Tethys, Goddess of Light": 2, "Zeradias, Herald of Heaven": 2, "Athena": 1, "Splendid Venus": 1, "The Sanctuary in the Sky": 2, "Valhalla, Hall of the Fallen": 2, "Fairy's Hand Mirror": 2, "Draining Shield": 2, "Solemn Judgment": 1, "Xyz Effect": 1, "Double or Nothing!": 1, "Heartfelt Appeal": 1},
		"extra": {"Fairy Cheer Girl": 2, "Number 39: Utopia": 1}},
}


static var lumen_tuner_test := false      # tests: Lumen as a Tuner without a story save


## Cards a replay brought with it that this game does not have (a replay from a later version, or
## from someone with another set of cards): shown from what the replay says about them. Only for
## the time that replay is on the table.
static var GUEST := {}

static func knows(id: int) -> bool:
	return CARDS.has(id) or EXT.has(id) or TOKENS.has(id)


## ATK or DEF as printed: "?" for the cards whose stat is "?" (the database keeps it as -1: Slifer, Ra).
static func stat_text(v) -> String:
	return "?" if int(v) < 0 else str(int(v))


static func get_card(id: int) -> Dictionary:
	var d: Dictionary
	if TOKENS.has(id):
		d = TOKENS[id].duplicate()
	elif not CARDS.has(id) and EXT.has(id):
		d = EXT[id].duplicate()
	elif not CARDS.has(id) and GUEST.has(id):
		d = GUEST[id].duplicate()
	else:
		d = CARDS.get(id, {"name": "Unknown", "frame": "normal"}).duplicate()
	d["id"] = id
	if id == LUMEN:
		var grow := 300 * mini(5, StoryProgress.bonds())
		d["atk"] = 500 + grow
		d["def"] = 500 + grow
		# What she learned in the worlds of the riders: she is a Tuner from then on.
		if lumen_tuner_test or Unlocks.stage() >= LUMEN_TUNER_STAGE:
			d["tuner"] = true
			d["text"] = str(d["text"]) + " She is a Tuner."
	if ORIGINALS.has(id):
		d["original"] = true
		d["desc"] = str(d.get("text", ""))      # (the rules read a card's own text for how it is summoned)
	var frame: String = d.get("frame", "")
	d["kind"] = "trap" if frame == "trap" else ("spell" if frame == "spell" else "monster")
	return d


## How rare a card is: 0 Common, 1 Rare, 2 Super Rare, 3 Ultra Rare. Worked out from the card
## itself, so every copy of a card always has the same rarity.
static func rarity(id: int) -> int:
	var d := get_card(id)
	if d.is_empty():
		return 0
	var frame := str(d.get("frame", ""))
	var atk := int(d.get("atk", 0))
	var lv := int(d.get("level", 0))
	if d.get("kind", "") == "monster":
		if frame in ["fusion", "synchro", "xyz", "ritual"]:
			return 3 if atk >= 2800 else 2
		if atk >= 3000 or lv >= 8:
			return 3
		if atk >= 2400 or lv >= 7:
			return 2
		if lv >= 5 or (frame == "effect" and atk >= 1900):
			return 1
		return 1 if (id % 7 == 0) else 0
	# Spells and Traps: a steady share of them shine.
	var h := id % 20
	if h == 0:
		return 3
	if h <= 2:
		return 2
	if h <= 6:
		return 1
	return 0


static func is_extra(id: int) -> bool:
	return get_card(id).get("frame", "") in ["fusion", "synchro", "xyz"]


## "slot:N": one of the player's saved decks, by its place in their list (Free Duel).
static func _slot(deck_key: String) -> Dictionary:
	return Engine.get_main_loop().root.get_node("Collection").slot_cards(int(deck_key.substr(5)))


static func has_deck(deck_key: String) -> bool:
	if deck_key.contains("@"):
		return has_deck(str(DeckTiers.split(deck_key)[0]))
	if deck_key.begins_with("slot:"):
		return Engine.get_main_loop().root.get_node("Collection").slot_ready(int(deck_key.substr(5)))
	if deck_key == "custom":
		return Engine.get_main_loop().root.get_node("Collection").deck_ok()
	if DECKS.has(deck_key):
		return true
	return NAMED_DECKS.has(deck_key) and deck_list(deck_key).size() >= 20


static func deck_name(deck_key: String) -> String:
	if deck_key.contains("@"):
		var sp: Array = DeckTiers.split(deck_key)
		var ak := DeckTiers.anime_key(str(sp[0]), str(sp[1]))
		return deck_name(ak if ak != "" else str(sp[0]))
	if deck_key.begins_with("slot:"):
		return str(_slot(deck_key).get("name", "?"))
	if deck_key == "custom":
		return str(Engine.get_main_loop().root.get_node("Collection").deck_name)
	if DECKS.has(deck_key):
		return DECKS[deck_key]["name"]
	return NAMED_DECKS.get(deck_key, {}).get("name", "?")


## Extra Spells and Traps each deck gets when the full card database is installed
## (Field, Equip, Continuous, Quick-Play, Counter and Ritual cards).
const ADDONS := {
	"yugi": {"Magic Cylinder": 1, "Mystical Space Typhoon": 1, "Book of Secret Arts": 1, "Yami": 1, "Magic Jammer": 1, "Black Luster Ritual": 1, "Black Luster Soldier": 1},
	"kaiba": {"Shrink": 1, "Enemy Controller": 1, "Ring of Destruction": 1, "Mountain": 1, "Dragon Treasure": 1, "Negate Attack": 1},
	"joey": {"Graceful Charity": 1, "Sogen": 1, "Lightning Blade": 1, "Call of the Haunted": 1, "Rush Recklessly": 1, "Scapegoat": 1},
	"mai": {"Harpies' Hunting Ground": 2, "Harpie's Feather Duster": 1, "Gravity Bind": 1, "Follow Wind": 1},
	"bakura": {"Yami": 2, "Dark Energy": 1, "Call of the Haunted": 1, "Dark Core": 1},
	"marik": {"Nightmare Wheel": 2, "Mystic Plasma Zone": 1, "Malevolent Nuzzler": 1, "Magic Jammer": 1},
	"pegasus": {"Shadow Spell": 1, "Heavy Storm": 1, "Change of Heart": 1, "Mystical Space Typhoon": 1},
	"weevil": {"Forest": 2, "Laser Cannon Armor": 2, "Just Desserts": 1},
	"rex": {"Jurassic World": 2, "Raise Body Heat": 1, "Hammer Shot": 1, "Rush Recklessly": 1},
	"jaden": {"Skyscraper": 2, "Miracle Fusion": 1, "E - Emergency Call": 1, "Draining Shield": 1, "The Warrior Returning Alive": 1},
	"chazz": {"Rush Recklessly": 1, "Call of the Haunted": 1, "Ring of Destruction": 1, "Dragon Treasure": 1},
	"zane": {"Machine Conversion Factory": 1, "Heavy Storm": 1, "Mystical Space Typhoon": 1, "Trap Jammer": 1},
	"alexis": {"Machine Angel Ritual": 3, "Luminous Spark": 1, "Horn of the Unicorn": 1},
	"syrus": {"Machine Conversion Factory": 1, "Rush Recklessly": 1, "Negate Attack": 1, "Draining Shield": 1},
	"aster": {"Mystic Plasma Zone": 1, "Ring of Destruction": 1, "Book of Moon": 1, "Dark Bribe": 1},
	"yusei": {"Junk Barrage": 1, "Mystical Space Typhoon": 1, "Rush Recklessly": 1, "Draining Shield": 1, "Call of the Haunted": 1},
	"jack": {"Molten Destruction": 1, "Salamandra": 1, "Dark Bribe": 1, "Shrink": 1},
	"crow": {"Rising Air Current": 1, "Book of Moon": 1, "Mirror Force": 1, "Follow Wind": 1},
	"akiza": {"Vile Germs": 1, "Forest": 1, "Magic Cylinder": 1, "Mystical Space Typhoon": 1},
	"kalin": {"Mystic Plasma Zone": 1, "Card Destruction": 1, "Dark Energy": 1, "Dust Tornado": 1},
	"yuma": {"Ego Boost": 1, "Mystical Space Typhoon": 1, "Draining Shield": 1, "Lightning Blade": 1},
	"shark": {"A Legendary Ocean": 2, "Steel Shell": 1, "Dust Tornado": 1},
	"kite": {"Luminous Spark": 1, "Shrink": 1, "Solemn Judgment": 1, "Book of Moon": 1},
	"vector": {"Mystic Plasma Zone": 1, "Shadow Spell": 1, "Dark Bribe": 1, "Malevolent Nuzzler": 1},
	"echo": {"Mystical Space Typhoon": 1, "Axe of Despair": 1, "Call of the Haunted": 1, "Book of Moon": 1, "Solemn Judgment": 1},
	"kairo": {"Dragon Treasure": 1, "Mountain": 1, "Ring of Destruction": 1, "Solemn Judgment": 1, "Shrink": 1},
}


# ------------------------------------------------------------------ only exact cards
# A ready-made deck is written with the cards its duelist plays. A card whose rules do not
# match its printed text yet (see CardExact) is swapped for a stand-in here, and comes back
# by itself the day it is rebuilt.

const STAND_INS := ["Celtic Guardian", "Gemini Elf", "Vorse Raider", "Luster Dragon", "Mad Dog of Darkness", "Mechanicalchaser", "Archfiend Soldier",
	"Insect Knight", "Sabersaurus", "Harpie Lady", "Aqua Madoor", "7 Colored Fish", "Giant Soldier of Stone", "Mystical Elf", "Elemental HERO Sparkman",
	"Elemental HERO Avian", "Elemental HERO Burstinatrix", "Elemental HERO Clayman", "Charcoal Inpachi", "Blazing Inpachi", "Alexandrite Dragon",
	"Gene-Warped Warwolf", "X-Head Cannon", "Dark Blade", "Battle Ox", "La Jinn the Mystical Genie of the Lamp", "Neo Bug", "Baby Dragon", "Silver Fang", "Feral Imp",
	"Summoned Skull", "Curse of Dragon", "Luster Dragon #2", "Frostosaurus", "Millennium Shield",
	"Dark Magician", "Blue-Eyes White Dragon", "Red-Eyes Black Dragon", "Cosmo Queen", "Tri-Horned Dragon", "Elemental HERO Neos", "Rabidragon", "Gogiga Gagagigo"]
const STAND_SPELLS := ["Fissure", "Hinotama", "Dian Keto the Cure Master", "Smashing Ground"]
const STAND_TRAPS := ["Sakuretsu Armor", "Jar of Greed", "Waboku"]
static var _swap_cache := {}


## The card itself when its rules are exact, a stand-in when they are not (0: nothing takes its place).
static func swap(id: int) -> int:
	if _swap_cache.has(id):
		return _swap_cache[id]
	var d := get_card(id)
	var out := id
	if not d.is_empty() and str(d.get("name", "Unknown")) != "Unknown" and not CardExact.ok(d):
		out = _stand_in(id, d)
	_swap_cache[id] = out
	return out


static func _tier(level: int) -> int:
	return 0 if level <= 4 else (1 if level <= 6 else 2)


static func _stand_in(id: int, d: Dictionary) -> int:
	if str(d.get("kind", "monster")) != "monster":
		var names: Array = STAND_TRAPS if str(d.get("kind", "")) == "trap" else STAND_SPELLS
		return int(NAME_TO_ID.get(str(names[id % names.size()]).to_lower(), 0))
	if str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]:
		return 0   # an Extra Deck monster has no stand-in: the Extra Deck is just one card shorter
	var best := 0
	var best_score := 1 << 30
	for n in STAND_INS:
		var cid := int(NAME_TO_ID.get(str(n).to_lower(), 0))
		if cid == 0:
			continue
		var c := get_card(cid)
		var score := absi(_tier(int(c.get("level", 4))) - _tier(int(d.get("level", 4)))) * 100000
		score += 0 if str(c.get("race", "")) == str(d.get("race", "")) else 400
		score += 0 if str(c.get("attribute", "")) == str(d.get("attribute", "")) else 250
		score += absi(int(c.get("atk", 0)) - int(d.get("atk", 0))) + (id + cid) % 90
		if score < best_score:
			best_score = score
			best = cid
	return best


static func _swap_all(list: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for id in list:
		var s := swap(id)
		if s != 0:
			out.append(s)
	return out


## plain: the deck in somebody else's hands (see SignatureDecks.borrowed).
static func deck_list(deck_key: String, plain := false) -> Array[int]:
	if deck_key.contains("@"):
		var sp: Array = DeckTiers.split(deck_key)
		var ak := DeckTiers.anime_key(str(sp[0]), str(sp[1]))
		if ak != "":
			return deck_list(ak, plain)
		return DeckTiers.main(deck_list(str(sp[0]), plain), str(sp[1]))
	if deck_key.begins_with("slot:"):
		var saved: Array[int] = []
		for id in _slot(deck_key).get("main", []):
			saved.append(int(id))
		return saved
	if deck_key == "custom":
		var mine: Array[int] = []
		for id in Engine.get_main_loop().root.get_node("Collection").main:
			mine.append(int(id))
		return mine
	return SignatureDecks.tune(deck_key, _swap_all(_deck_list_raw(deck_key)), plain)


static func _deck_list_raw(deck_key: String) -> Array[int]:
	var extra_cards: Array[int] = _expand(_resolve(ADDONS.get(deck_key, {}), false))
	if DECKS.has(deck_key):
		return to_forty(_expand(DECKS[deck_key]["cards"]) + extra_cards)
	# A deck may also name cards by number (your partner, who is in no card database).
	var by_id: Array[int] = _expand(NAMED_DECKS.get(deck_key, {}).get("ids", {}))
	return to_forty(_fill_to_30(_resolve(NAMED_DECKS.get(deck_key, {}).get("cards", {}), false)) + by_id + extra_cards)


## A Main Deck is 40 to 60 cards. Smaller lists are topped up with further copies (3 at most)
## of what the deck already plays: low-Level monsters first, then its Spells and Traps.
static func to_forty(list: Array[int]) -> Array[int]:
	if list.size() >= MIN_DECK or list.is_empty():
		return list
	var counts := {}
	var order: Array = []
	for id in list:
		if not counts.has(id):
			order.append(id)
		counts[id] = int(counts.get(id, 0)) + 1
	var mons: Array = order.filter(func(id): return get_card(id)["kind"] == "monster" and int(get_card(id).get("level", 4)) <= 4)
	mons.sort_custom(func(a, b): return int(get_card(a).get("atk", 0)) > int(get_card(b).get("atk", 0)))
	var rest: Array = order.filter(func(id): return get_card(id)["kind"] != "monster")
	var out: Array[int] = list.duplicate()
	for pool in [mons, rest, order]:
		for id in pool:
			if out.size() >= MIN_DECK:
				return out
			if counts[id] < 3:
				counts[id] += 1
				out.append(id)
	# Still short: a second pass adds third copies.
	for id in mons + rest:
		if out.size() >= MIN_DECK:
			break
		if counts[id] < 3:
			counts[id] += 1
			out.append(id)
	return out


static func extra_list(deck_key: String, plain := false) -> Array[int]:
	if deck_key.contains("@"):
		var sp: Array = DeckTiers.split(deck_key)
		var ak := DeckTiers.anime_key(str(sp[0]), str(sp[1]))
		if ak != "":
			return extra_list(ak, plain)
		return DeckTiers.extra(extra_list(str(sp[0]), plain), str(sp[1]))
	if deck_key.begins_with("slot:"):
		var saved: Array[int] = []
		for id in _slot(deck_key).get("extra", []):
			saved.append(int(id))
		return saved
	if deck_key == "custom":
		var mine: Array[int] = []
		for id in Engine.get_main_loop().root.get_node("Collection").extra:
			mine.append(int(id))
		return mine
	if DECKS.has(deck_key):
		return SignatureDecks.tune_extra(deck_key, _swap_all(_expand(DECKS[deck_key].get("extra", {}))), plain)
	return SignatureDecks.tune_extra(deck_key, _swap_all(_expand(_resolve(NAMED_DECKS.get(deck_key, {}).get("extra", {}), true))), plain)


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
		if d["kind"] != "monster" and not CardPool.has(id) and not d.has("effect") and not SpellRules.FX.has(str(d.get("name", ""))) and not str(d.get("st", "")) in ["equip", "field", "ritual"]:
			continue      # (a Spell or Trap that is not in the game)
		if (d.get("frame", "") in ["fusion", "synchro", "xyz"]) != extra:
			continue
		if d.get("frame", "") == "link":
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
	_swap_cache.clear()
	EXT.clear()
	NAME_TO_ID.clear()
	var src := folder.path_join("cards.json")
	if not FileAccess.file_exists(src):
		return
	var cache := Saves.u("card_index.json")
	var stamp := str(FileAccess.get_modified_time(src)) + "-v11"
	if FileAccess.file_exists(cache):
		var c = JSON.parse_string(FileAccess.get_file_as_string(cache))
		if typeof(c) == TYPE_DICTIONARY and c.get("stamp", "") == stamp:
			for k in c["cards"]:
				var d: Dictionary = c["cards"][k]
				EXT[int(k)] = d
				NAME_TO_ID[str(d["name"]).to_lower()] = int(k)
			_load_extra()
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
	_load_extra()


## res://data/cards_extra.json (0.56.0): the cards the game names that a cards.json may know by
## another name (versions rename cards) or not have at all. A missing card is added; the game's
## name always finds its card. (tools/make_cards_extra.py)
## A card whose picture in the card folder is under another id (a reprint's), from cards_extra.json.
static var IMAGE_ALT := {}


static func _load_extra() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards_extra.json"))
	if typeof(parsed) != TYPE_ARRAY:
		return
	for raw in parsed:
		var id := int(raw.get("id", 0))
		if id == 0:
			continue
		if not EXT.has(id):
			var d := _from_db(raw)
			if d.is_empty():
				continue
			EXT[id] = d
		elif str(EXT[id].get("name", "")) != str(raw.get("name", "")):
			# (renamed in this cards.json: the game keeps the name its decks, packs and texts use)
			(EXT[id] as Dictionary)["name"] = str(raw.get("name", ""))
		NAME_TO_ID[str(raw.get("name", "")).to_lower()] = id
		if raw.has("image"):
			IMAGE_ALT[id] = int(raw["image"])


static func _num(v) -> int:
	return int(v) if v is int or v is float or (v is String and (v as String).is_valid_int()) else 0


static func _from_db(raw: Dictionary) -> Dictionary:
	var name := str(raw.get("name", ""))
	var frame := str(raw.get("frameType", "normal"))
	if frame.begins_with("effect"):
		frame = "effect"
	elif frame.begins_with("normal"):
		frame = "normal"
	var d := {"name": name, "frame": frame, "desc": str(raw.get("desc", ""))}
	if str(raw.get("frameType", "")).contains("pendulum") or str(raw.get("type", "")).contains("Pendulum") or str(d["desc"]).contains("[ Pendulum Effect ]"):
		d["pendulum"] = true      # (not a card of this game: see CardPool)
	if frame == "spell" or frame == "trap":
		d["st"] = str(raw.get("race", "")).to_lower()
		if SPELL_EFFECTS.has(name):
			d["effect"] = SPELL_EFFECTS[name]
			d["text"] = d["desc"]
		return d
	# (Some cards.json versions write null for "?" ATK/DEF: int(null) is an error.)
	d["atk"] = _num(raw.get("atk", 0))
	d["def"] = _num(raw.get("def", 0))
	d["level"] = _num(raw.get("level", raw.get("linkval", 0)))
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
static func legend_deck(deck_key: String, plain := false) -> Array[int]:
	if not DECKS.has(deck_key):
		return deck_list(deck_key, plain)
	var counts: Dictionary = DECKS[deck_key]["cards"].duplicate()
	var monsters := []
	for id in counts:
		if str(get_card(id).get("kind", "monster")) == "monster":
			monsters.append(id)
	# (get_card, not CARDS: Lumen's bigger decks have cards from the card database in them, 0.81.0)
	monsters.sort_custom(func(a, b): return int(get_card(a).get("atk", 0)) < int(get_card(b).get("atk", 0)))
	var removed := 0
	for id in monsters:
		while removed < 6 and counts[id] > 0 and int(get_card(id).get("level", 4)) <= 4:
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
	# (The duelist's own cards go in and the stand-ins come out here too: Hard and Expert play
	# this list, and it used to skip that step.)
	return SignatureDecks.tune(deck_key, _swap_all(to_forty(_expand(counts))), plain)
