extends Node
## Your cards: what you own, the deck you built, and Duel Points (DP) to spend on packs.
## Saved to user://collection.cfg.

signal changed

const PATH := "user://collection.cfg"
const PACK_PRICE := 150
const PACK_SIZE := 5
const MAIN_MIN := 40
const MAIN_MAX := 60
const EXTRA_MAX := 15
const SIDE_MAX := 15
## The optional Forbidden/Limited list (a classic-era list). Only applies to decks you build,
## and only while the switch in the deck builder is on.
const FORBIDDEN := ["Pot of Greed", "Graceful Charity", "Raigeki", "Harpie's Feather Duster", "Change of Heart", "Snatch Steal",
	"Delinquent Duo", "The Forceful Sentry", "Confiscation", "Painful Choice", "Yata-Garasu", "Chaos Emperor Dragon - Envoy of the End"]
const LIMITED := ["Monster Reborn", "Dark Hole", "Heavy Storm", "Mirror Force", "Swords of Revealing Light", "Torrential Tribute",
	"Call of the Haunted", "Premature Burial", "Solemn Judgment", "Card Destruction", "Ring of Destruction", "Mystical Space Typhoon",
	"Black Luster Soldier - Envoy of the Beginning", "Sangan", "Exodia the Forbidden One", "Right Arm of the Forbidden One",
	"Left Arm of the Forbidden One", "Right Leg of the Forbidden One", "Left Leg of the Forbidden One", "Jinzo", "Injection Fairy Lily"]
const SEMI_LIMITED := ["Scapegoat", "Book of Moon", "Nobleman of Crossout", "Reinforcement of the Army", "Cyber Dragon", "Lightning Vortex"]
## Booster packs. "tab" is the shelf they stand on in the shop. The five series sets together hold
## every card in the game; the themed sets hold the same cards sorted by what they are, so you can
## chase the kind of card your deck needs.
const PACK_TABS := ["Series sets", "Card families", "Monster types", "Elements, Spells and Traps"]
const THEMED_PRICE := 200
const PACKS := [
	{"key": "Duel Monsters", "tab": 0, "name": "Legend of the King", "color": Color("8a4dff"), "blurb": "Cards from the Duel Monsters era."},
	{"key": "GX", "tab": 0, "name": "Academy Heroes", "color": Color("ff3a4d"), "blurb": "Cards from the GX era."},
	{"key": "5D's", "tab": 0, "name": "Signer's Road", "color": Color("2de2e6"), "blurb": "Cards from the 5D's era."},
	{"key": "ZEXAL", "tab": 0, "name": "Overlay Network", "color": Color("ffd23a"), "blurb": "Cards from the ZEXAL era."},
	{"key": "Vault", "tab": 0, "name": "Duelist's Vault", "color": Color("5affa0"), "blurb": "Classic Spells, Traps and monsters no story duelist plays."},
	{"key": "legends", "tab": 0, "name": "Monster Legends", "color": Color("e8b04a"), "blurb": "Normal Monsters from every era: hundreds of them, from the classics to the rare big ones."},
	{"key": "echo", "tab": 0, "name": "Echo Pack", "color": Color("7fe8ff"), "price": 300, "size": 3, "blurb": "Cards of this game only: Lumen, her forms and the cards around her. Only the ones the story has already handed you, up to three of each."},
	{"key": "archfiend", "tab": 1, "name": "Court of the Archfiends", "color": Color("b0303c"), "family": true, "blurb": "The Archfiends: the chess pieces of Pandemonium that cost Life Points every turn and roll a die against whatever targets them, Summoned Skull and everything that takes his name, and the Archfiend Synchros, Fusions and Rituals."},
	{"key": "dark_world", "tab": 1, "name": "Lords of Dark World", "color": Color("7a4bd0"), "family": true, "blurb": "Dark World: Fiends that want to be discarded. Throw one away and it draws, destroys or comes back to the field, and Grapha returns from the Graveyard again and again. With the discard cards built around them."},
	{"key": "constellar", "tab": 1, "name": "Starlight Knights", "color": Color("8fb4ff"), "family": true, "blurb": "Constellar and the tellarknights: LIGHT knights that call each other out of the hand, change their Levels, and stack into Xyz Monsters from Praesepe up to Ptolemy M7."},
	{"key": "six_samurai", "tab": 1, "name": "Way of the Six", "color": Color("d04a3c"), "family": true, "blurb": "The Six Samurai: warriors who cover for each other, Bushido Counters that pay for searches and draws, the Legendary and Secret Six, and Shi En, who shuts down a Spell or Trap every turn."},
	{"key": "monarchs", "tab": 1, "name": "Rule of the Monarchs", "color": Color("e0c070"), "family": true, "blurb": "Monarchs: Tribute Summon them and each one strikes as it lands. The Mega Monarchs rise from a Tribute Summoned monster, the Squires and Vassals feed the Tributes, and the Monarch Spells and Traps keep the field yours."},
	{"key": "chaos", "tab": 1, "name": "Envoys of Chaos", "color": Color("c8b0ff"), "family": true, "blurb": "Black Luster Soldier and Gaia the Fierce Knight: the Rituals that call the Soldier, the Gaia knights that ride beside him, the Light and Darkness Ritual, and the LIGHT and DARK monsters of Chaos."},
	{"key": "gem_knight", "tab": 1, "name": "Brilliant Gems", "color": Color("7ae0ff"), "family": true, "blurb": "Gem-Knights: Normal Monsters that fuse into shining knights, the Fusion Spells that pull materials from the Deck and Graveyard, and the Diamonds on top."},
	{"key": "lightsworn", "tab": 1, "name": "Light of Judgment", "color": Color("ffe7a0"), "family": true, "blurb": "Lightsworn: monsters that send their own Deck to the Graveyard and grow stronger for it, until Judgment Dragon clears the field."},
	{"key": "ancient_gear", "tab": 1, "name": "Clockwork Titans", "color": Color("b07a3c"), "family": true, "blurb": "Ancient Gear: Golems no Spell or Trap can answer, the fusions built from them, and the towns and castles that bring them out."},
	{"key": "gravekeeper", "tab": 1, "name": "Valley of the Kings", "color": Color("c8a050"), "family": true, "blurb": "The Gravekeeper's and Necrovalley: the tomb guardians, the valley that locks every Graveyard, and the cards around them."},
	{"key": "beyond", "tab": 0, "name": "Beyond the Limit", "color": Color("b06bff"), "blurb": "Fusion, Synchro, Xyz and Ritual monsters, and the Spells that call them."},
	{"key": "dragons", "tab": 2, "name": "Dragon's Roar", "color": Color("ff5a3c"), "blurb": "Dragons, Dinosaurs, Reptiles and Sea Serpents."},
	{"key": "warriors", "tab": 2, "name": "Blades of Valor", "color": Color("f0b040"), "blurb": "Warriors, from street fighters to legendary knights."},
	{"key": "arcane", "tab": 2, "name": "Arcane Circle", "color": Color("ffd97a"), "blurb": "Spellcasters, Fairies and Thunder."},
	{"key": "shadow", "tab": 2, "name": "Midnight Crypt", "color": Color("9a6bff"), "blurb": "Fiends and Zombies."},
	{"key": "machines", "tab": 2, "name": "Steel Factory", "color": Color("6fc3ff"), "blurb": "Machines of every size."},
	{"key": "wild", "tab": 2, "name": "Call of the Wild", "color": Color("ff9a3c"), "blurb": "Beasts and Beast-Warriors."},
	{"key": "tide", "tab": 3, "name": "Flame and Tide", "color": Color("4aa8ff"), "blurb": "Every WATER and FIRE monster."},
	{"key": "gale", "tab": 3, "name": "Sky Riders", "color": Color("7de0b0"), "blurb": "WIND monsters and Winged Beasts."},
	{"key": "forest", "tab": 3, "name": "Deep Woods", "color": Color("5fd070"), "blurb": "Insects, Plants, Rocks, Aqua, Fish and Pyro."},
	{"key": "spellbook", "tab": 3, "name": "Sorcerer's Library", "color": Color("3fe0c0"), "blurb": "Normal and Quick-Play Spells: removal, draw power, revival."},
	{"key": "arsenal", "tab": 3, "name": "Relic Arsenal", "color": Color("8fb8c8"), "blurb": "Equip, Field and Continuous Spells."},
	{"key": "traps", "tab": 3, "name": "Face-Down Secrets", "color": Color("ff5a8a"), "blurb": "Every Trap card in the game."},
]
## Which era each world's shops sell.
const WORLD_ERA := {"domino": "Duel Monsters", "academy": "GX", "satellite": "5D's", "newdomino": "5D's", "highway": "5D's", "heartland": "ZEXAL"}


## Is this theme deck on the shelf in that world's shop? ("worlds" in THEME_DECKS; a family's deck in its era's worlds.)
static func theme_sold_in(key: String, world: String) -> bool:
	for t in THEME_DECKS:
		if str(t["key"]) == key:
			if t.has("worlds"):
				return (t["worlds"] as Array).has(world)
			return str(t.get("era", "")) == "" or str(WORLD_ERA.get(world, "")) == str(t.get("era", ""))
	return true


## Ready-made theme decks sold at the card shop (duelists' decks are sold there too).
const DECK_PRICE := 1200
const THEME_PRICE := 900
const THEME_DECKS := [
	{"key": "deck_water", "worlds": ["academy", "heartland"], "art": "deck_water", "color": Color("4aa8ff"), "blurb": "Sharks that call each other out of the hand, Salvage to get them back, and seven WATER Xyz Monsters led by Bahamut Shark."},
	{"key": "deck_fire", "worlds": ["domino", "newdomino"], "art": "deck_fire", "color": Color("ff6a3c"), "blurb": "Volcanic Slicer and Solar Flare Dragon burn every turn while Backfire punishes every removal. Resonators bring out Synchro finishers."},
	{"key": "deck_wind", "worlds": ["newdomino", "academy"], "art": "gale", "color": Color("7de0b0"), "blurb": "Mist Valley monsters bounce themselves and your opponent back to the hand, then Synchro into Mist Valley Thunder Lord."},
	{"key": "deck_dragon", "worlds": ["domino", "heartland"], "art": "dragons", "color": Color("ff5a3c"), "blurb": "Lord of D. and the Flute call the big Dragons, Thunder Dragon feeds Fusions, and Dragon's Mirror makes Five-Headed Dragon."},
	{"key": "deck_warrior", "worlds": ["domino", "satellite"], "art": "warriors", "color": Color("f0b040"), "blurb": "Marauding Captain and Command Knight hold the line, Torapart tunes into Warrior Synchros, and Gaia rides into Gaia the Dragon Champion."},
	{"key": "deck_arcane", "worlds": ["domino", "academy"], "art": "arcane", "color": Color("ffd97a"), "blurb": "Spell Counters: every Spell you play charges the Magical Library and the Skilled Magicians, then Arcanite Magician cashes them in."},
	{"key": "deck_shadow", "worlds": ["academy", "satellite"], "art": "shadow", "color": Color("9a6bff"), "blurb": "Fiends with heavy hits at Level 4, Dark Resonator to tune them into Chaos King Archfiend, and Number 66 for the rest."},
	{"key": "deck_machine", "worlds": ["newdomino", "satellite", "heartland"], "art": "machines", "color": Color("6fc3ff"), "blurb": "The V, W, X, Y and Z Unions: equip them to each other, then fuse up to VWXYZ-Dragon Catapult Cannon."},
	{"key": "deck_wild", "worlds": ["heartland", "domino"], "art": "wild", "color": Color("ff9a3c"), "blurb": "Big Beasts at Level 4 with Fusions on top: Chimera the Flying Mythical Beast and Rabid Horseman."},
	{"key": "deck_six_samurai", "art": "warriors", "cover": "Legendary Six Samurai - Shi En", "color": Color("d04a3c"), "era": "5D's", "blurb": "One Samurai on the field calls the next from your hand: Kageki, Kizan and the Grandmaster arrive for free, Six Samurai United draws, and a Tuner turns them into Shi En."},
	{"key": "deck_constellar", "art": "arcane", "cover": "Constellar Ptolemy M7", "color": Color("8fb4ff"), "era": "ZEXAL", "blurb": "Pollux and Algiedi put two Constellars on the field in one turn, Kaus moves their Levels, and the pair becomes Praesepe, Pleiades or Ptolemy M7. The tellarknights search each other on the way."},
	{"key": "deck_dark_world", "art": "shadow", "cover": "Grapha, Dragon Lord of Dark World", "color": Color("7a4bd0"), "era": "GX", "blurb": "Dark World Dealings and The Gates of Dark World discard your Fiends, and each discard pays you: Broww draws, Snoww searches, Sillva and Goldd arrive, and Grapha destroys a card."},
	{"key": "deck_archfiend", "art": "shadow", "cover": "Terrorking Archfiend", "color": Color("b0303c"), "era": "Duel Monsters", "blurb": "Pandemonium takes away the Life Point cost and replaces every Archfiend that falls. Terrorking and Infernalqueen hit hard for Level 4, the General fetches the field, and two Level 6 make Archfiend's Ascent."},
	{"key": "deck_monarchs", "art": "shadow", "cover": "Caius the Mega Monarch", "color": Color("e0c070"), "era": "GX", "blurb": "Squires and Vassals step out so a Monarch can be Tribute Summoned, then a Mega Monarch Tributes that one. Every landing clears something off their side."},
	{"key": "deck_chaos", "art": "warriors", "cover": "Black Luster Soldier - Super Soldier", "color": Color("c8b0ff"), "era": "Duel Monsters", "blurb": "Super Soldier Ritual turns two Level 4 Knights into Black Luster Soldier, and the Knights give him their powers. Gaia rides in when he falls, and Chaos Form brings back the old legends."},
	{"key": "deck_gem_knight", "art": "warriors", "cover": "Gem-Knight Master Diamond", "color": Color("7ae0ff"), "era": "ZEXAL", "blurb": "Gem-Knight Fusion turns two plain knights into a Fusion Monster, Brilliant Fusion fuses straight from the Deck, and Gem-Knight Fusion comes back from the Graveyard to do it again."},
	{"key": "deck_lightsworn", "art": "arcane", "cover": "Judgment Dragon", "color": Color("ffe7a0"), "era": "5D's", "blurb": "Lightsworn send cards from the top of the Deck every End Phase. Wulf jumps out, Garoth draws, and four names in the Graveyard bring Judgment Dragon."},
	{"key": "deck_ancient_gear", "art": "machines", "cover": "Ancient Gear Golem", "color": Color("b07a3c"), "era": "GX", "blurb": "Ancient Gear Golems hit hard, pierce, and nothing your opponent sets can stop the attack. Geartown and the Castle bring them out fast."},
	{"key": "deck_gravekeeper", "art": "arcane", "cover": "Gravekeeper's Chief", "color": Color("c8a050"), "era": "Duel Monsters", "blurb": "The Gravekeeper's guard Necrovalley: while it stands, nothing leaves either Graveyard. Flip Spies, call more guards, lock the other side down."},
	{"key": "deck_forest", "worlds": ["academy", "satellite"], "art": "forest", "color": Color("5fd070"), "blurb": "Lonefire Blossom and Dandylion fill the field with Plants, Gigaplant brings them back, and Splendid Rose closes it out."},
]
## The three decks a new duelist picks one of: the same strength, three ways to play, your
## partner in each. `show` are three cards that say what the deck is about.
const STARTERS := [
	{"key": "starter_warrior", "style": "WARRIORS", "color": Color("f0b040"), "show": ["Goblin Attack Force", "Exiled Force", "Airknight Parshath"],
		"blurb": "Attack. Strong Level 4 fighters that hit from the first turn, and Spells that make them hit harder.",
		"points": ["Easiest to pick up", "Wins by swinging first", "Reinforcement of the Army finds the fighter you need"]},
	{"key": "starter_arcane", "style": "SPELLCASTERS", "color": Color("b48cff"), "show": ["Dark Magician", "Dark Magician Girl", "Breaker the Magical Warrior"],
		"blurb": "Tricks. Flip monsters, Traps that stop an attack cold, and two famous magicians to finish with.",
		"points": ["Rewards patience", "Wins by turning their turn against them", "Magician of Faith gets a Spell back"]},
	{"key": "starter_dragon", "style": "DRAGONS", "color": Color("ff5a3c"), "show": ["Tri-Horned Dragon", "Luster Dragon #2", "Spear Dragon"],
		"blurb": "Big monsters. Solid small Dragons hold the field while you Tribute them for the heavy ones.",
		"points": ["Highest ATK of the three", "Wins by size", "Mountain makes every Dragon stronger"]},
]

## Solid Normal Monsters that round out the Vault.
## The series sets: together they hold every card you can collect (the themed sets sort the same cards).
const SERIES := ["Duel Monsters", "GX", "5D's", "ZEXAL", "Vault", "legends"]
## Card families (the 1,000-card plan): each one has its own booster pack, a theme deck in the shop, and its
## cards also join its era's pack. One entry per family, in the order they were added.
const FAMILIES := {
	"gravekeeper": {"era": "Duel Monsters", "deck": "deck_gravekeeper", "cards": [
		"Gravekeeper's Spy", "Gravekeeper's Guard", "Gravekeeper's Spear Soldier", "Gravekeeper's Curse", "Gravekeeper's Assailant",
		"Gravekeeper's Commandant", "Gravekeeper's Recruiter", "Gravekeeper's Descendant", "Gravekeeper's Chief", "Gravekeeper's Cannonholder",
		"Gravekeeper's Priestess", "Gravekeeper's Visionary", "Gravekeeper's Headman", "Gravekeeper's Watcher", "Gravekeeper's Vassal",
		"Gravekeeper's Heretic", "Gravekeeper's Shaman", "Gravekeeper's Nobleman", "Gravekeeper's Ambusher", "Gravekeeper's Oracle",
		"Gravekeeper's Spiritualist", "Gravekeeper's Supernaturalist", "A Cat of Ill Omen", "An Owl of Luck", "Charm of Shabti",
		"Necrovalley", "Royal Tribute", "Rite of Spirit", "Gravekeeper's Stele", "Gravekeeper's Servant", "Hidden Temples of Necrovalley",
		"Imperial Tombs of Necrovalley", "Necrovalley Temple", "Necrovalley Throne", "Gravekeeper's Inscription", "Terraforming", "Royal Decree",
		"Gravekeeper's Trap", "Mudora the Sword Oracle", "Pharaoh's Treasure", "Exchange of the Spirit"]},
	"ancient_gear": {"era": "GX", "deck": "deck_ancient_gear", "cards": [
		"Ancient Gear", "Ancient Gear Beast", "Ancient Gear Box", "Ancient Gear Cannon", "Ancient Gear Commander", "Ancient Gear Dark Golem",
		"Ancient Gear Dragon", "Ancient Gear Engineer", "Ancient Gear Frame", "Ancient Gear Gadget", "Ancient Gear Gadjiltron Chimera",
		"Ancient Gear Gadjiltron Dragon", "Ancient Gear Golem", "Ancient Gear Golem - Ultimate Pound", "Ancient Gear Howitzer",
		"Ancient Gear Hunting Hound", "Ancient Gear Hydra", "Ancient Gear Knight", "Ancient Gear Megaton Golem", "Ancient Gear Reactor Dragon",
		"Ancient Gear Soldier", "Ancient Gear Statue", "Ancient Gear Tanker", "Ancient Gear Wyvern", "Chaos Ancient Gear Giant",
		"Ultimate Ancient Gear Golem", "Ancient Gear Advance", "Ancient Gear Castle", "Ancient Gear Catapult", "Ancient Gear Drill",
		"Ancient Gear Explosive", "Ancient Gear Factory", "Ancient Gear Fist", "Ancient Gear Fusion", "Ancient Gear Reborn", "Ancient Gear Tank",
		"Ancient Gear Workshop", "Cross-Dimensional Duel", "Geartown", "Spell Gear", "Toon Ancient Gear Golem", "Ancient Gear Duel", "Ancient Gear Fortress"]},
	"monarchs": {"era": "GX", "deck": "deck_monarchs", "cards": ["Mobius the Frost Monarch", "Strike of the Monarchs", "The First Monarch", "The Monarchs Revolt", "Caius the Shadow Monarch", "Granmarg the Mega Monarch", "Escalation of the Monarchs", "March of the Monarchs", "Pantheism of the Monarchs", "Erebus the Underworld Monarch", "Mobius the Mega Monarch", "Thestalos the Firestorm Monarch", "The Monarchs Awaken", "Eidos the Underworld Monarch", "Tenacity of the Monarchs", "The Monarchs Erupt", "Zaborg the Thunder Monarch", "The Prime Monarch", "Kuraz the Light Monarch", "Monarchic Perfection", "Granmarg the Rock Monarch", "Return of the Monarchs", "The Monarchs Masterplan", "Angmarl the Fiendish Monarch", "Tessera the Primal Squire", "Thestalos the Mega Monarch", "Raiza the Mega Monarch", "Raiza the Storm Monarch", "Thestalos the Shadowfire Monarch", "The Monarchs Stormforth", "Domain of the True Monarchs", "Delg the Dark Monarch", "Caius the Mega Monarch", "Zaborg the Mega Monarch", "Edea the Heavenly Squire", "Ehther the Heavenly Monarch", "Restoration of the Monarchs", "Frost Blast of the Monarchs", "Garum the Storm Vassal", "Mithra the Thunder Vassal", "Escher the Frost Vassal", "Lucius the Shadow Vassal", "Berlineth the Firestorm Vassal", "Landrobe the Rock Vassal", "Eidos the Underworld Squire"]},
	"chaos": {"era": "Duel Monsters", "deck": "deck_chaos", "cards": ["Black Luster Soldier", "Black Luster Soldier - Envoy of the Beginning", "Black Luster Soldier - Envoy of the Evening Twilight", "Black Luster Soldier - Legendary Swordsman", "Black Luster Soldier - Sacred Soldier", "Black Luster Soldier - Super Soldier", "Black Luster Ritual", "Super Soldier Ritual", "Super Soldier Rebirth", "Super Soldier Shield", "Super Soldier Soul", "Super Soldier Synthesis", "Beginning Knight", "Evening Twilight Knight", "Chaos Form", "Envoy of Chaos", "Gateway to Chaos", "Beginning of Heaven and Earth", "Chaos Sorcerer", "Dark Magician of Chaos", "Chaos Emperor Dragon - Envoy of the End", "Chaos Valkyria", "Chaos Hunter", "Chaos Betrayer", "Chaos Daedalus", "Chaos Dragon Levianeer", "Chaos End", "Chaos Greed", "Chaos Space", "Gaia The Fierce Knight", "Gaia the Dragon Champion", "Arisen Gaia the Fierce Knight", "Charging Gaia the Fierce Knight", "Lord Gaia the Fierce Knight", "Soldier Gaia the Fierce Knight", "Swift Gaia the Fierce Knight", "Gaia the Fierce Knight Origin", "Gaia the Magical Knight", "Gaia, the Mid-Knight Sun", "Gaia, the Polar Knight", "Sky Galloping Gaia the Dragon Champion", "Gaia the Magical Knight of Dragons", "Galloping Gaia", "Dragon Master Knight", "Dragon Master Magia", "Master of Chaos", "Magician of Black Chaos", "Magician of Black Chaos MAX", "Magician of Chaos", "Blue-Eyes Chaos Dragon", "Blue-Eyes Chaos MAX Dragon", "Five-Headed Dragon", "Curse of Dragon", "Spiral Spear Strike", "Spiral Discharge", "Illusion of Chaos", "Heart of Gaia", "Artillery Catapult Turtle", "Skilled Blue Magician", "Light and Darkness Ritual", "Black Luster Soldier - Soldier of Light and Darkness", "Magician of Dark Chaos - Black Chaos", "Black Chaos", "Chaos Magical Hats", "Skull Archfiend of Chaos", "Mind Shuffle", "Celtic Mystic", "Chaos Mystic Box", "Griffoh"]},
	"gem_knight": {"era": "ZEXAL", "deck": "deck_gem_knight", "cards": ["Gem-Enhancement", "Gem-Knight Fusion", "Brilliant Spark", "Gem-Knight Seraphinite", "Brilliant Fusion", "Gem-Knight Zirconia", "Gem-Knight Aquamarine", "Gem-Elephant", "Gem-Knight Obsidian", "Gem-Knight Lady Brilliant Diamond", "Gem-Knight Dispersion", "Gem-Knight Master Diamond Dispersion", "Gem-Armadillo", "Gem-Knight Sapphire", "Gem-Knight Quartz", "Particle Fusion", "Gem-Knight Master Diamond", "Scatter Fusion", "Gem-Knight Sardonyx", "Gem-Knight Iolite", "Gem-Knight Lady Lapis Lazuli", "Gem-Knight Topaz", "Gem-Knight Nepyrim", "Gem-Merchant", "Gem-Knight Tourmaline", "Gem-Knight Lady Rose Diamond", "Pyroxene Fusion", "Brilliant Rose", "Gem-Turtle", "Gem-Knight Citrine", "Gem-Knight Emerald", "Absorb Fusion", "Gem-Knight Pearl", "Gem-Knight Amethyst", "Fragment Fusion", "Gem-Knight Amber", "Gem-Knight Ruby", "Gem-Knight Crystal", "Crystal Rose", "Gem-Knight Lazuli", "Gem-Knight Hollowcore", "Gem-Knight Alexandrite", "Gem-Knight Garnet", "Gem-Knight Prismaura", "Gem-Knight Lapis"]},
	"lightsworn": {"era": "5D's", "deck": "deck_lightsworn", "cards": [
		"Judgment Dragon", "Celestia, Lightsworn Angel", "Wulf, Lightsworn Beast", "Felis, Lightsworn Archer", "Gragonith, Lightsworn Dragon",
		"Aurkus, Lightsworn Druid", "Ryko, Lightsworn Hunter", "Minerva, Lightsworn Maiden", "Jenis, Lightsworn Mender", "Ehren, Lightsworn Monk",
		"Jain, Lightsworn Paladin", "Rinyan, Lightsworn Rogue", "Lyla, Lightsworn Sorceress", "Shire, Lightsworn Spirit", "Lumina, Lightsworn Summoner",
		"Garoth, Lightsworn Warrior", "Raiden, Hand of the Lightsworn", "Lightsworn Dragonling", "Michael, the Arch-Lightsworn",
		"Minerva, the Exalted Lightsworn", "Charge of the Light Brigade", "Solar Recharge", "Lightsworn Sabre", "Light Spiral", "Realm of Light",
		"Glorious Illusion", "Vanquishing Light", "Twilight Cloth", "March of the Dark Brigade",
		"Weiss, Lightsworn Archfiend", "Punishment Dragon", "Enlightenment Dragon", "Lyla, Twilightsworn Enchantress", "Ryko, Twilightsworn Fighter",
		"Jain, Twilightsworn General", "Lumina, Twilightsworn Shaman", "Minerva, the Athenian Lightsworn", "Lightsworn Barrier", "Lightsworn Aegis",
		"Lightsworn Sanctuary", "Twilight Eraser", "Twilight Twin Dragons", "Lightsworn Judgment"]},
	"six_samurai": {"era": "5D's", "deck": "deck_six_samurai", "cards": [
		"Secret Six Samurai - Rihan", "Secret Six Samurai - Fuma", "Shien's Squire", "Kagemusha of the Blue Flame", "Kagemusha of the Six Samurai",
		"Secret Six Samurai - Genba", "Shien's Footsoldier", "Tactical Trainer of the Six Samurai", "Anarchist Monk of the Six Samurai",
		"Chamberlain of the Six Samurai", "Elder of the Six Samurai", "Hand of the Six Samurai", "Legendary Six Samurai - Kageki",
		"Legendary Six Samurai - Mizuho", "Legendary Six Samurai - Shinai", "Secret Six Samurai - Hatsume", "Spirit of the Six Samurai",
		"The Six Samurai - Kamon", "The Six Samurai - Yaichi", "The Six Samurai - Yariza", "Legendary Secret of the Six Samurai",
		"Legendary Six Samurai - Enishi", "Legendary Six Samurai - Kizan", "Secret Six Samurai - Doji", "Secret Six Samurai - Kizaru", "Shien's Advisor",
		"Shien's Daredevil", "Tenkabito Shien", "The Six Samurai - Irou", "The Six Samurai - Nisashi", "The Six Samurai - Zanji",
		"Grandmaster of the Six Samurai", "Enishi, Shien's Chancellor", "Great Shogun Shien", "Asceticism of the Six Samurai",
		"Cunning of the Six Samurai", "Gateway of the Six", "Legendary Ebon Steed", "Secret Skills of the Six Samurai", "Shien's Castle of Mist",
		"Shien's Dojo", "Shien's Smoke Signal", "Six Samurai United", "Six Scrolls of the Samurai", "Six Strike - Double Assault",
		"Six Strike - Triple Impact", "Temple of the Six", "Legendary Lord Six Samurai - Enishi", "Legendary Lord Six Samurai - Kizan",
		"Legendary Lord Six Samurai - Shi En", "Legendary Six Samurai - Shi En", "Backs to the Wall", "Breakthrough!", "Double-Edged Sword Technique",
		"Musakani Magatama", "Return of the Six Samurai", "Shien's Scheme", "Six Strike - Sextuple Barrage", "Six Style - Dual Wield",
		"Swift Samurai Storm!", "Swiftstrike Armor", "The Six Shinobi", "Shadow of the Six Samurai - Shien"]},
	"constellar": {"era": "ZEXAL", "deck": "deck_constellar", "cards": [
		"Constellar Siat", "Constellar Rasalhague", "Constellar Aldebaran", "Constellar Leonis", "Constellar Sheratan", "Constellar Acubens",
		"Constellar Algiedi", "Constellar Caduceus", "Constellar Castor", "Constellar Kaus", "Constellar Pollux", "Constellar Sombre",
		"Satellarknight Alsahm", "Satellarknight Altair", "Satellarknight Betelgeuse", "Satellarknight Capella", "Satellarknight Deneb",
		"Satellarknight Procyon", "Satellarknight Rigel", "Satellarknight Sirius", "Satellarknight Unukalhai", "Satellarknight Vega",
		"Tellarknight Altairan", "Tellarknight Cygnian", "Tellarknight Lyran", "Constellar Virgo", "Constellar Zubeneschamali", "Constellar Alrescha",
		"Constellar Antares", "Constellar Belt", "Constellar Star Chart", "Constellar Star Cradle", "Constellar Tellarknights", "Constellar Tempest",
		"Constellar Twinkle", "Hexatellarknight", "Satellarknight Skybridge", "Stellarknight Alpha", "Stellarnova Binding", "Tellarknight Genesis",
		"Constellar Meteor", "Stellarnova Alpha", "Stellarnova Wave", "Constellar Hyades", "Constellar Omega", "Constellar Pleiades",
		"Constellar Praesepe", "Constellar Ptolemy M7", "Darktellarknight Batlamyus", "Exstellarknight Constellar Ptolemy Ω7",
		"Stellarknight Constellar Diamond", "Stellarknight Delteros", "Stellarknight Triverr", "Tellarknight Constellar Caduceus",
		"Tellarknight Constellar Delteros", "Tellarknight Ptolemaeus"]},
	"dark_world": {"era": "GX", "deck": "deck_dark_world", "cards": [
		"Clorless, Chaos King of Dark World", "Grapha, Dragon Overlord of Dark World", "Ceruli, Guru of Dark World", "Parl, Hermit of Dark World",
		"Gren, Tactician of Dark World", "Kahkki, Guerilla of Dark World", "Scarr, Scout of Dark World", "Broww, Huntsman of Dark World",
		"Tour Guide From the Underworld", "Beiige, Vanguard of Dark World", "Brron, Mad King of Dark World", "Dark Grepher",
		"Genta, Gateman of Dark World", "Renge, Gatekeeper of Dark World", "Snoww, Unlight of Dark World", "Zure, Knight of Dark World",
		"Goldd, Wu-Lord of Dark World", "Sillva, Warlord of Dark World", "Latinum, Exarch of Dark World", "Lucent, Netherlord of Dark World",
		"Reign-Beaux, Overlord of Dark World", "Grapha, Dragon Lord of Dark World", "Reign-Beaux, Overking of Dark World", "Allure of Darkness",
		"Charge Into a Dark World", "Dark Corridor", "Dark Eruption", "Dark World Accession", "Dark World Archives", "Dark World Dealings",
		"Dark World Grimoire", "Dark World Lightning", "Dark World Puppetry", "Dragged Down into the Grave", "Gateway to Dark World", "Hand Destruction",
		"Into the Void", "Recurring Nightmare", "The Cheerful Coffin", "The Gates of Dark World", "Dark Deal", "Dark Smog", "Dark World Brainwashing",
		"Dark World Punishment", "Deck Devastation Virus", "Eradicator Epidemic Virus", "Mind Crush", "The Forces of Darkness",
		"Adreus, Keeper of Armageddon", "Hieratic Sun Dragon Overlord of Heliopolis", "Leviair the Sea Dragon", "Number 22: Zombiestein",
		"Number 80: Rhapsody in Berserk"]},
	"archfiend": {"era": "Duel Monsters", "deck": "deck_archfiend", "cards": [
		"Archfiend Black Skull Dragon", "Archfiend's Manifestation", "Black Skull Dragon", "Fiend Skull Dragon", "Mimighoul Archfiend",
		"Red Dragon Archfiend/Assault Mode", "Archfiend Marmot of Nefariousness", "Archfiend Mirror", "Plaguespreader Zombie", "Vilepawn Archfiend",
		"Archfiend Heiress", "Darkbishop Archfiend", "Desrook Archfiend", "Highness Archfiend", "Shadow Tamer", "Shipping Archfiend", "Archfiend Cavalry",
		"Archfiend General", "Archfiend Interceptor", "Archfiend Soldier", "Bone Archfiend", "Cave Dragon", "Cyber Archfiend", "Duke Archfiend",
		"Infernalqueen Archfiend", "Infernity Archfiend", "Lancer Archfiend", "Mad Archfiend", "Nefarious Archfiend Eater of Nefariousness",
		"Shadowknight Archfiend", "Skilled Red Magician", "Terrorking Archfiend", "Trance Archfiend", "Weiss, Lightsworn Archfiend",
		"Awakening of the Possessed - Nefariouser Archfiend", "Lesser Fiend", "Mist Archfiend", "Archfiend Commander", "Archfiend Giant",
		"Archfiend of Gilfer", "Archfiend's Advent", "Beast of Talwar", "Berserk Archfiend", "Red-Eyes Archfiend of Lightning", "Skull Archfiend of Chaos",
		"Skull Archfiend of Lightning", "Summoned Skull", "Toon Summoned Skull", "Archfiend's Origin", "Beast of Talwar - The Sword Summit",
		"Labrynth Archfiend", "Royal Archfiend", "Archfiend Emperor, the First Lord of Horror", "Archfiend Empress", "Berserk Dragon",
		"Imprisoned Queen Archfiend", "Regenesis Archfiend", "Annihilator Archfiend", "Archfiend's Awakening", "Matador Archfiend",
		"A Deal with Dark Ruler", "Archfiend Palabyrinth", "Archfiend Strategy", "Archfiend's Oath", "Archfiend's Staff of Despair",
		"Archfiend's Usurpation", "Axe of Despair", "Checkmate", "Contract with the Abyss", "Falling Down", "Gladiator Beast's Battle Archfiend Shield",
		"Makourai, the Lightning Strike", "Pandemonium", "Ritual of the Matador", "Throne of the Archfiends", "Archfiend Zombie-Skull", "Archfiend's Call",
		"Chaos Archfiend", "Chaos King Archfiend", "Crossmind Archfiend", "Hot Red Dragon Archfiend", "Hot Red Dragon Archfiend Abyss",
		"Hot Red Dragon Archfiend Bane", "Hot Red Dragon Archfiend King Calamity", "Infernity Doom Archfiend", "Overmind Archfiend",
		"Red Dragon Archfiend", "Scarlight Red Dragon Archfiend", "Scarred Dragon Archfiend", "Scrap Archfiend", "Thought Ruler Archfiend",
		"Tyrant Red Dragon Archfiend", "Archfiend Playtime", "Archfiend's Fervor", "Archfiend's Ghastly Glitch", "Archfiend's Roar", "Battle-Scarred",
		"Call of the Archfiend", "Nightmare Archfiends", "Red Dragon Archfiend's Chain", "Simul Archfiends", "Archfiend's Ascent",
		"Number 102: Star Seraph Sentry", "Number C102: Archfiend Seraph"]},
}


## The ids of a family's cards that work in the game.
static func family_ids(key: String) -> Array:
	var out: Array = []
	for n in FAMILIES.get(key, {}).get("cards", []):
		var id: int = CardData.NAME_TO_ID.get(str(n).to_lower(), 0)
		if id != 0 and not CardData.get_card(id).is_empty() and CardExact.ok(CardData.get_card(id)):
			out.append(id)
	return out
const VAULT_EXTRAS := ["Gemini Elf", "Vorse Raider", "Luster Dragon", "Mad Dog of Darkness", "Insect Knight", "Gene-Warped Warwolf",
	"Archfiend Soldier", "Sabersaurus", "Alexandrite Dragon", "Summoned Skull", "Luster Dragon #2", "Mystical Elf", "Giant Soldier of Stone",
	"La Jinn the Mystical Genie of the Lamp", "Dark Blade", "Blazing Inpachi", "Neo the Magic Swordsman", "Sky Scout"]

var owned := {}          # card id -> copies
var main: Array = []     # card ids
var extra: Array = []
var dp := 300
var deck_name := "My Deck"
var side: Array = []     # Side Deck of the deck in use
var slots: Array = []    # your decks: {name, main, extra, side, origin?}
var dropped: Array = []  # ready-made decks you own whose deck you threw away
var slot := 0            # which recipe is loaded
var banlist := false     # play by the Forbidden/Limited list
var decks_owned: Array = []   # ready-made decks you have (your starter, Lumen's deck once the story gives it, any you bought)
var active := "echo"     # the deck you duel with: "custom" (the one you built) or a ready-made deck
var starter_pick := ""   # which of the three starter decks you chose ("" not yet)
var _new_save := false   # nothing was saved before this start: a new duelist
var record := {}         # reward bookkeeping: {"day": "2026-11-12", "streak": 2, "beaten": {key: true}}
var last_reward: Array = []   # what the last duel paid, line by line: [[label, amount], ...]
var last_prize := 0           # the card the last duel's opponent handed over (0: none)
var _pools := {}


## Cards that carried a wrong number in older versions (CardData.RENUMBERED): what you own and
## every deck you built is moved to the right number, once, when the save is read.
func _renumber() -> void:
	var fix := func(list: Array) -> bool:
		var changed := false
		for i in list.size():
			if (typeof(list[i]) == TYPE_INT or typeof(list[i]) == TYPE_FLOAT) and CardData.RENUMBERED.has(int(list[i])):
				list[i] = int(CardData.RENUMBERED[int(list[i])])
				changed = true
		return changed
	var any := false
	for old_id in CardData.RENUMBERED:
		if owned.has(old_id):
			var to := int(CardData.RENUMBERED[old_id])
			owned[to] = mini(3, int(owned.get(to, 0)) + int(owned[old_id]))
			owned.erase(old_id)
			any = true
	for list in [main, extra, side]:
		if fix.call(list):
			any = true
	for sl in slots:
		if sl is Dictionary:
			for k in (sl as Dictionary).keys():
				if (sl as Dictionary)[k] is Array and fix.call((sl as Dictionary)[k]):
					any = true
	if any:
		save.call_deferred()


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		owned = cfg.get_value("cards", "owned", {})
		main = cfg.get_value("deck", "main", [])
		extra = cfg.get_value("deck", "extra", [])
		deck_name = cfg.get_value("deck", "name", deck_name)
		dp = cfg.get_value("wallet", "dp", dp)
		side = cfg.get_value("deck", "side", [])
		slots = cfg.get_value("deck", "slots", [])
		dropped = cfg.get_value("deck", "dropped", [])
		slot = int(cfg.get_value("deck", "slot", 0))
		banlist = bool(cfg.get_value("deck", "banlist", false))
		record = cfg.get_value("wallet", "record", {})
		starter_pick = str(cfg.get_value("deck", "starter", ""))
		if cfg.has_section_key("deck", "owned_decks"):
			decks_owned = cfg.get_value("deck", "owned_decks", ["echo"])
			active = str(cfg.get_value("deck", "active", "echo"))
		else:
			decks_owned = ["echo"]   # (a save from before decks had a shelf: it played Echo)
			_adopt_old_deck()
	else:
		_adopt_old_deck()
	_renumber()
	if owned.is_empty():
		_new_save = true
		_starter()
	# Lumen, your partner: every duelist has her card, old saves included.
	if int(owned.get(CardData.LUMEN, 0)) < 1:
		owned[CardData.LUMEN] = 1
		if not main.has(CardData.LUMEN) and main.size() < 60:
			main.append(CardData.LUMEN)
		save.call_deferred()
	lumen_gifts()
	_fill_slots()
	lumen_deck()
	_grant_decks()
	_adopt_decks()
	save.call_deferred()
	var forced := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--deck="):
			forced = true
	if not forced:
		_apply_active.call_deferred()
	_trade_in.call_deferred()


## Before there was a deck shelf, any duelist's deck could be picked for free. Whatever you were
## dueling with then stays yours.
func _adopt_old_deck() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://roam.cfg") != OK:
		return
	var old := str(cfg.get_value("roam", "deck", ""))
	if old == "custom":
		active = "custom"
	elif old != "" and CardData.has_deck(old):
		if not decks_owned.has(old):
			decks_owned.append(old)
		active = old


func _apply_active() -> void:
	var r := get_node_or_null("/root/Router")
	if r:
		r.duel_config["player_deck"] = active_deck()


## The deck to duel with right now. Falls back to your starter (or Lumen's deck) when the built
## deck is not legal, or the chosen ready-made deck is not on your shelf.
func active_deck() -> String:
	if active == "custom" and deck_ok():
		return "custom"
	if active != "custom" and decks_owned.has(active) and CardData.has_deck(active):
		return active
	return fallback_deck()


## A ready-made deck that is always there to duel with: the starter you picked, else Lumen's
## deck, else any deck on your shelf (and the Echo list itself before anything is picked).
func fallback_deck() -> String:
	for k in [starter_pick, "echo"] + decks_owned:
		if str(k) != "" and decks_owned.has(k) and CardData.has_deck(str(k)):
			return str(k)
	return "echo"


## Lumen's deck: hers to hand over once you have dueled Domino with her (story stage 2). Saves
## that had it from the start keep it. Returns true the moment it arrives.
func lumen_deck() -> bool:
	if decks_owned.has("echo") or Unlocks.stage() < 2 or not CardData.has_deck("echo"):
		return false
	decks_owned.append("echo")
	var need := {}
	for id in CardData.deck_list("echo") + CardData.extra_list("echo"):
		need[id] = int(need.get(id, 0)) + 1
	for id in need:
		owned[id] = maxi(int(owned.get(id, 0)), mini(3, int(need[id])))
	if origin_slot("echo") < 0 and not dropped.has("echo"):
		_store_slot()
		slots.append(_recipe_slot("echo"))
	deck_news = true
	save.call_deferred()
	return true


func use_deck(key: String) -> void:
	active = key
	save()
	_apply_active()


func owns_deck(key: String) -> bool:
	return decks_owned.has(key)


func deck_price(key: String) -> int:
	for t in THEME_DECKS:
		if t["key"] == key:
			return THEME_PRICE
	return DECK_PRICE


func starter_info(key: String) -> Dictionary:
	for st in STARTERS:
		if str(st["key"]) == key:
			return st
	return {}


## Has the choice of a first deck still to be made?
## Lumen's cards come with the story: the cards around her after the prologue, her big form
## and the spell that calls it after Domino, then one Extra Deck form from each world (see
## CardData.LUMEN_GIFTS). Hands over whatever the story has reached and has not been given yet,
## and returns those card ids. An Extra Deck form also goes into the Extra Deck of the deck you
## built, if there is room, and the Fusion form comes with a Polymerization if you have none.
var deck_news := false        # Lumen's deck just arrived (the main menu says it)
var lumen_news: Array = []      # ids handed over and not yet announced (the main menu says it)

func lumen_gifts() -> Array:
	var stage := Unlocks.stage()
	var had: Array = record.get("lumen_gifts", [])
	var got: Array = []
	for g in CardData.LUMEN_GIFTS:
		var id := int(g[1])
		if stage < int(g[0]) or had.has(id):
			continue
		owned[id] = maxi(int(owned.get(id, 0)), int(g[2]))
		had.append(id)
		got.append(id)
		if CardData.is_extra(id) and not extra.has(id) and extra.size() < EXTRA_MAX:
			extra.append(id)
		if id == 99200002 and int(owned.get(24094653, 0)) < 1:
			owned[24094653] = 1
	if not got.is_empty():
		record["lumen_gifts"] = had
		lumen_news.append_array(got)
		save.call_deferred()
	return got


func needs_starter() -> bool:
	return starter_pick == "" and CardData.has_deck("starter_warrior")


## Somebody who has never dueled yet (the deck they pick becomes the deck they play).
func is_new() -> bool:
	if _new_save:
		return true
	var played := 0
	var vs: Dictionary = record.get("vs", {})
	for k in vs:
		played += int((vs[k] as Array)[0]) + int((vs[k] as Array)[1])
	return played == 0 and decks_owned.size() <= 1 and active == "echo" and starter_pick == ""


## The first deck: free, on your shelf, its cards in your collection. For a new duelist it is
## also the deck in their hands; anybody who already plays keeps the deck they have.
func take_starter(key: String) -> bool:
	if starter_info(key).is_empty() or not CardData.has_deck(key):
		return false
	var fresh := is_new()
	starter_pick = key
	if not decks_owned.has(key):
		decks_owned.append(key)
	var need := {}
	for id in CardData.deck_list(key) + CardData.extra_list(key):
		need[id] = int(need.get(id, 0)) + 1
	for id in need:
		owned[id] = maxi(int(owned.get(id, 0)), mini(3, int(need[id])))
	_store_slot()
	if fresh:
		# A new duelist: the deck in your hands IS the starter (no leftover deck next to it).
		var at := origin_slot(key)
		if at < 0:
			at = clampi(slot, 0, maxi(0, slots.size() - 1))
			if slots.is_empty():
				slots.append({})
			slots[at] = _recipe_slot(key)
		slot = at
		_take_slot()
		active = "custom"
		_apply_active()
	elif origin_slot(key) < 0:
		slots.append(_recipe_slot(key))
	_new_save = false
	save()
	return fresh


## Buy a ready-made deck: it goes on your shelf, and every card in it joins your collection
## (so you can copy it into a slot and rebuild it your way).
func buy_deck(key: String) -> bool:
	var price := deck_price(key)
	if decks_owned.has(key) or dp < price or not CardData.has_deck(key):
		return false
	dp -= price
	decks_owned.append(key)
	var need := {}
	for id in CardData.deck_list(key) + CardData.extra_list(key):
		need[id] = int(need.get(id, 0)) + 1
	for id in need:
		owned[id] = maxi(int(owned.get(id, 0)), mini(3, int(need[id])))
	_store_slot()
	if origin_slot(key) < 0:
		slots.append(_recipe_slot(key))
	save()
	return true


## A ready-made deck you own is cards you own: every one of them is in your collection, so the
## deck builder can use them (decks handed to you by the story or an old save included).
func _grant_decks() -> void:
	for key in decks_owned:
		if not CardData.has_deck(str(key)):
			continue
		var need := {}
		for id in CardData.deck_list(str(key)) + CardData.extra_list(str(key)):
			need[id] = int(need.get(id, 0)) + 1
		for id in need:
			if playable(int(id)):
				owned[id] = maxi(int(owned.get(id, 0)), mini(3, int(need[id])))


## Copy a ready-made deck you own into a recipe slot and load it, ready to edit.
func copy_ready_to_slot(key: String, i: int) -> void:
	load_slot(i)
	var need := {}
	for id in CardData.deck_list(key) + CardData.extra_list(key):
		need[id] = int(need.get(id, 0)) + 1
	for id in need:
		owned[id] = maxi(int(owned.get(id, 0)), mini(3, int(need[id])))
	main = Array(CardData.deck_list(key))
	extra = Array(CardData.extra_list(key))
	side = []
	deck_name = CardData.deck_name(key) + " +"
	save()


## Every ready-made deck the shop can sell: duelists' decks first, then the theme decks.
## [{key, name, owner, color, blurb, art, price, kind}]
func deck_catalog() -> Array:
	var out: Array = []
	var seen := {"echo": true}
	for k in Characters.ORDER:
		var d: Dictionary = Characters.DATA[k]
		var dk := str(d.get("deck", ""))
		if seen.has(dk) or not CardData.has_deck(dk):
			continue
		seen[dk] = true
		out.append({"key": dk, "name": CardData.deck_name(dk), "owner": str(d.get("name", "")), "who": k, "color": d.get("color", Color.WHITE),
			"blurb": "", "art": "", "price": DECK_PRICE, "kind": "duelist", "era": str(d.get("era", ""))})
	for t in THEME_DECKS:
		if CardData.has_deck(str(t["key"])):
			out.append({"key": t["key"], "name": CardData.deck_name(str(t["key"])), "owner": "", "who": "", "color": t["color"],
				"blurb": t["blurb"], "art": t["art"], "price": THEME_PRICE, "kind": "theme", "era": str(t.get("era", ""))})
	return out


func deck_info(key: String) -> Dictionary:
	if key == "echo":
		return {"key": "echo", "name": CardData.deck_name("echo"), "owner": "Lumen", "who": "player", "color": Color("2de2e6"),
			"blurb": "Lumen's own deck: hers, and the Echo cards she has given you.", "art": "", "price": 0, "kind": "gift", "era": ""}
	var st := starter_info(key)
	if not st.is_empty():
		return {"key": key, "name": CardData.deck_name(key), "owner": "", "who": "player", "color": st["color"],
			"blurb": st["blurb"], "art": "", "price": 0, "kind": "starter", "era": ""}
	for e in deck_catalog():
		if e["key"] == key:
			return e
	return {"key": key, "name": CardData.deck_name(key), "owner": "", "who": "", "color": Color.WHITE, "blurb": "", "art": "", "price": 0, "kind": "", "era": ""}


## The card that goes on a deck's box: its rarest, strongest monster.
## Wins and losses against one duelist: [wins, losses].
func versus(key: String) -> Array:
	var vs: Dictionary = record.get("vs", {})
	var r: Array = vs.get(key, [0, 0])
	return [int(r[0]), int(r[1])]


## Count a finished duel against `key`. The third win over a duelist unlocks their deck as a
## ready-made deck; returns that deck's key when it happens, "" otherwise.
func note_result(key: String, won: bool) -> String:
	var vs: Dictionary = record.get("vs", {})
	var r := versus(key)
	r[0 if won else 1] += 1
	vs[key] = r
	record["vs"] = vs
	var unlocked := ""
	if won and r[0] == 3:
		var deck := str(Characters.get_char(key).get("deck", ""))
		if deck != "" and CardData.has_deck(deck) and not decks_owned.has(deck):
			decks_owned.append(deck)
			unlocked = deck
	save()
	return unlocked


## Medals against each duelist in Free Duel: three to earn from every one of them.
##   0 Victory       beat them
##   1 Standing tall beat them without ever dropping under 4000 Life Points (a duel at 8000)
##   2 Swift         beat them within 8 turns of your own (they started at 8000 or more)
const MEDALS := [
	{"name": "Victory", "how": "Beat them.", "dp": 60, "color": Color("d98a4a")},
	{"name": "Standing tall", "how": "Beat them without ever dropping under 4000 Life Points.", "dp": 120, "color": Color("cfd6e2")},
	{"name": "Swift", "how": "Beat them within 8 turns of your own.", "dp": 120, "color": Color("ffd166")},
]


## Which medals you hold against somebody: [bool, bool, bool].
func medals(key: String) -> Array:
	var have: Dictionary = record.get("medals", {})
	var bits := int(have.get(key, 0))
	return [bits & 1 != 0, bits & 2 != 0, bits & 4 != 0]


func medal_count() -> int:
	var n := 0
	for k in (record.get("medals", {}) as Dictionary):
		for on in medals(str(k)):
			if on:
				n += 1
	return n


## A Free Duel was won: hand out the medals it earned that you did not have yet. Each pays
## once and goes on the result screen. Returns the Duel Points paid.
##   info: low (the least Life Points you had), my_turns, my_start, their_start
func award_medals(key: String, info: Dictionary) -> int:
	var earned := [true,
		int(info.get("my_start", 8000)) >= 8000 and int(info.get("low", 0)) >= 4000,
		int(info.get("their_start", 8000)) >= 8000 and int(info.get("my_turns", 99)) <= 8]
	var have := medals(key)
	var bits := 0
	var paid := 0
	for i in 3:
		if have[i] or earned[i]:
			bits |= 1 << i
		if earned[i] and not have[i]:
			var m: Dictionary = MEDALS[i]
			last_reward.append([Loc.t("Medal: %s") % Loc.t(str(m["name"])), int(m["dp"])])
			paid += int(m["dp"])
	if paid > 0:
		var all: Dictionary = record.get("medals", {})
		all[key] = bits
		record["medals"] = all
		dp += paid
		save()
	return paid


## Each deck's cover card, never the same one on two decks. {deck key: card id}
var _deck_covers := {}


func deck_ace(key: String) -> int:
	if _deck_covers.is_empty():
		var used := {}
		for e in deck_catalog():
			var k := str(e["key"])
			var id := _deck_ace(k, used)
			_deck_covers[k] = id
			used[id] = true
	if _deck_covers.has(key):
		return int(_deck_covers[key])
	return _deck_ace(key, {})


func _deck_ace(key: String, used: Dictionary) -> int:
	for t in THEME_DECKS:
		if str(t["key"]) == key and t.has("cover"):
			var cid: int = CardData.NAME_TO_ID.get(str(t["cover"]).to_lower(), 0)
			if cid != 0 and not used.has(cid):
				return cid
	var ids: Array = CardData.extra_list(key) + CardData.deck_list(key)
	# A duelist's deck shows that duelist's own card (Yugi's shows Dark Magician, not whatever
	# in it happens to hit hardest), and a deck named after a card shows that card.
	for who in Characters.DATA:
		var c: Dictionary = Characters.DATA[who]
		if str(c.get("deck", "")) == key and int(c.get("ace", 0)) != 0 and ids.has(int(c["ace"])):
			return int(c["ace"])
	var title := CardData.deck_name(key).to_lower()
	if title != "":
		var named := 0
		var named_atk := -1
		for id in ids:
			var nd := CardData.get_card(id)
			var nm := str(nd.get("name", "")).to_lower()
			if nd.get("kind", "") != "monster":
				continue
			if nm == title and not used.has(id):
				return id
			if nm.contains(title) and not used.has(id) and not CardData.extra_list(key).has(id) and int(nd.get("atk", 0)) > named_atk:
				named_atk = int(nd.get("atk", 0))
				named = id
		if named != 0:
			return named
	var best := 0
	var score := -1
	for id in ids:
		var d := CardData.get_card(id)
		if d.get("kind", "") != "monster":
			continue
		var sc := CardData.rarity(id) * 10000 + int(d.get("atk", 0))
		if used.has(id):
			sc -= 1000000   # (another deck already shows it)
		if sc > score:
			score = sc
			best = id
	return best


## The card on the front of each booster pack: a real card that is in it. The strongest, rarest
## monster in the pack (a Spell or Trap for the packs that have no monsters), and never the same
## card on two packs. {pack key: card id}
var _covers := {}


func pack_cover(key: String) -> int:
	if _covers.is_empty():
		var used := {}
		for p in PACKS:
			var ids: Array = pool(str(p["key"])).duplicate()
			var monsters: Array = ids.filter(func(id): return CardData.get_card(id).get("kind", "") == "monster")
			if not monsters.is_empty():
				ids = monsters
			ids.sort_custom(func(a, b):
				var ra := CardData.rarity(a)
				var rb := CardData.rarity(b)
				if ra != rb:
					return ra > rb
				var aa := int(CardData.get_card(a).get("atk", 0))
				var ab := int(CardData.get_card(b).get("atk", 0))
				return aa > ab if aa != ab else a < b)
			var pick := 0
			for id in ids:
				if not used.has(id):
					pick = id
					break
			if pick == 0 and not ids.is_empty():
				pick = ids[0]
			used[pick] = true
			_covers[str(p["key"])] = pick
		_covers["echo"] = CardData.LUMEN       # (her own pack has her on it, whatever it holds by now)
	return int(_covers.get(key, 0))


func slot_empty(i: int) -> bool:
	if i == slot:
		return main.is_empty() and extra.is_empty()
	var s: Dictionary = slots[i]
	return (s.get("main", []) as Array).is_empty() and (s.get("extra", []) as Array).is_empty()


func slot_ok(i: int) -> bool:
	if i == slot:
		return deck_ok()
	var n: int = (slots[i].get("main", []) as Array).size()
	return n >= MAIN_MIN and n <= MAIN_MAX


## Your own decks: as many as you like, in the order you keep them. There are no empty
## slots: older saves had five fixed ones, and any empty deck you are not standing on is dropped.
func _fill_slots() -> void:
	if slots.is_empty():
		slots.append({"name": deck_name, "main": main.duplicate(), "extra": extra.duplicate(), "side": side.duplicate()})
		slot = 0
	slot = clampi(slot, 0, slots.size() - 1)
	var keep: Array = []
	var now := 0
	for i in slots.size():
		if i == slot:
			now = keep.size()
			keep.append(slots[i])
		elif not slot_empty(i):
			keep.append(slots[i])
	slots = keep
	slot = now


func _store_slot() -> void:
	if slot < slots.size():
		var s: Dictionary = slots[slot]
		s["name"] = deck_name
		s["main"] = main.duplicate()
		s["extra"] = extra.duplicate()
		s["side"] = side.duplicate()
		slots[slot] = s


func _take_slot() -> void:
	var s: Dictionary = slots[slot]
	deck_name = str(s.get("name", "Deck %d" % (slot + 1)))
	main = (s.get("main", []) as Array).duplicate()
	extra = (s.get("extra", []) as Array).duplicate()
	side = (s.get("side", []) as Array).duplicate()


## Switch to another saved recipe.
func load_slot(i: int) -> void:
	_store_slot()
	slot = clampi(i, 0, slots.size() - 1)
	_take_slot()
	save()


## A new, empty deck at the end of the list. Returns where it is.
func new_slot(title := "") -> int:
	_store_slot()
	var used := {}
	for s in slots:
		used[str((s as Dictionary).get("name", ""))] = true
	var n := slots.size() + 1
	while title == "" and used.has("Deck %d" % n):
		n += 1
	slots.append({"name": title if title != "" else "Deck %d" % n, "main": [], "extra": [], "side": []})
	save()
	return slots.size() - 1


## A copy of deck `i` at the end of the list. Returns where it is.
func duplicate_slot(i: int) -> int:
	_store_slot()
	var s: Dictionary = (slots[clampi(i, 0, slots.size() - 1)] as Dictionary).duplicate(true)
	s["name"] = (str(s.get("name", "")) + " copy").left(24)
	s.erase("origin")
	slots.append(s)
	save()
	return slots.size() - 1


## Throw deck `i` away. The last deck left is emptied instead: there is always one.
func delete_slot(i: int) -> void:
	_store_slot()
	i = clampi(i, 0, slots.size() - 1)
	var from := str((slots[i] as Dictionary).get("origin", ""))
	if from != "" and not dropped.has(from):
		dropped.append(from)
	if slots.size() <= 1:
		slots[0] = {"name": "My Deck", "main": [], "extra": [], "side": []}
		slot = 0
		_take_slot()
	else:
		slots.remove_at(i)
		if i < slot:
			slot -= 1
		elif i == slot:
			slot = clampi(slot, 0, slots.size() - 1)
			_take_slot()
	save()


# ------------------------------------------------------------------ decks you were given or bought

## A deck you buy (or start with) is simply one of your decks: change it as you like. Its
## original list is kept ("origin" names it), so it can always be put back.

## Where the deck that came from ready-made deck `key` sits in your list, or -1.
func origin_slot(key: String) -> int:
	for i in slots.size():
		if str((slots[i] as Dictionary).get("origin", "")) == key:
			return i
	return -1


func _recipe_slot(key: String) -> Dictionary:
	return {"name": CardData.deck_name(key), "main": Array(CardData.deck_list(key)), "extra": Array(CardData.extra_list(key)), "side": [], "origin": key}


## Every ready-made deck you own gets its place among your decks (once; one you threw away
## stays away until you ask for it again at the shop).
func _adopt_decks() -> void:
	_store_slot()
	for key in decks_owned:
		var k := str(key)
		if not CardData.has_deck(k) or k == "custom" or origin_slot(k) >= 0 or dropped.has(k):
			continue
		# A deck of yours that is still exactly that list is that deck (a new save starts so).
		var want: Array = Array(CardData.deck_list(k))
		want.sort()
		var found := false
		for sl in slots:
			var d: Dictionary = sl
			if d.has("origin"):
				continue
			var have: Array = (d.get("main", []) as Array).duplicate()
			have.sort()
			if have == want:
				d["origin"] = k
				if str(d.get("name", "")) in ["My Deck", ""]:
					d["name"] = CardData.deck_name(k)
				found = true
				break
		if not found:
			slots.append(_recipe_slot(k))
	_take_slot()
	# Older saves could be dueling with a ready-made deck directly: now that is its own deck.
	if active != "custom":
		var at := origin_slot(active)
		if at >= 0:
			slot = at
			_take_slot()
			active = "custom"


## Duel with the deck that came from ready-made deck `key` (it comes back if you threw it away).
func use_owned(key: String) -> void:
	_store_slot()
	dropped.erase(key)
	var at := origin_slot(key)
	if at < 0:
		slots.append(_recipe_slot(key))
		at = slots.size() - 1
	slot = at
	_take_slot()
	use_deck("custom")


func using_origin(key: String) -> bool:
	return active == "custom" and slot < slots.size() and str((slots[slot] as Dictionary).get("origin", "")) == key


## Has deck `i` been changed from the list it came with?
func slot_changed(i: int) -> bool:
	var s: Dictionary = slots[i]
	var key := str(s.get("origin", ""))
	if key == "" or not CardData.has_deck(key):
		return false
	var m: Array = (main if i == slot else (s.get("main", []) as Array)).duplicate()
	var e: Array = (extra if i == slot else (s.get("extra", []) as Array)).duplicate()
	var sd: Array = side if i == slot else (s.get("side", []) as Array)
	var m0: Array = Array(CardData.deck_list(key))
	var e0: Array = Array(CardData.extra_list(key))
	m.sort()
	e.sort()
	m0.sort()
	e0.sort()
	return m != m0 or e != e0 or not sd.is_empty()


## Put deck `i` back to the list it came with.
func restore_slot(i: int) -> void:
	_store_slot()
	var s: Dictionary = slots[i]
	var key := str(s.get("origin", ""))
	if key == "" or not CardData.has_deck(key):
		return
	s["main"] = Array(CardData.deck_list(key))
	s["extra"] = Array(CardData.extra_list(key))
	s["side"] = []
	if i == slot:
		_take_slot()
	save()


## The deck in use is gone or no longer legal: the first of your decks that is ready takes over
## (the starter first). Returns its name, or "" when none is ready.
func fall_back() -> String:
	_store_slot()
	var pick := -1
	var echo := origin_slot("echo")
	if echo >= 0 and slot_ok(echo):
		pick = echo
	for i in slots.size():
		if pick < 0 and slot_ok(i):
			pick = i
	if pick < 0:
		return ""
	slot = pick
	_take_slot()
	use_deck("custom")
	return deck_name


## Move deck `i` one place up (-1) or down (+1) the list. Returns where it ended up.
func move_slot(i: int, dir: int) -> int:
	_store_slot()
	var j := i + dir
	if i < 0 or i >= slots.size() or j < 0 or j >= slots.size():
		return i
	var t = slots[i]
	slots[i] = slots[j]
	slots[j] = t
	if slot == i:
		slot = j
	elif slot == j:
		slot = i
	save()
	return j


## Fill the deck in use from a ready-made recipe, using only cards you own.
func load_recipe(key: String) -> int:
	main.clear()
	extra.clear()
	side.clear()
	var missing := 0
	for pair in [[CardData.deck_list(key), main], [CardData.extra_list(key), extra]]:
		for id in pair[0]:
			if can_add(id):
				(pair[1] as Array).append(id)
			else:
				missing += 1
	save()
	return missing


## How many copies the Forbidden/Limited list allows (3 when the list is off).
func limit(id: int) -> int:
	if not banlist:
		return 3
	var n := str(CardData.get_card(id).get("name", ""))
	if n in FORBIDDEN:
		return 0
	if n in LIMITED:
		return 1
	if n in SEMI_LIMITED:
		return 2
	return 3


## Cards in the deck that break the list: [[name, copies, allowed]].
func illegal() -> Array:
	var out := []
	if not banlist:
		return out
	var seen := {}
	for id in main + extra + side:
		if seen.has(id):
			continue
		seen[id] = true
		if in_deck(id) > limit(id):
			out.append([str(CardData.get_card(id).get("name", "")), in_deck(id), limit(id)])
	return out


## Older versions could hand out a card the game has no rules for (the lost card of the day,
## the scrap pile). Any such card you hold is swapped, once, for one that works, of the same
## kind and about the same strength, in your collection and in every deck that used it.
func _trade_in() -> void:
	if CardData.EXT.is_empty():
		return   # no card folder yet: nothing can be judged
	var swap := {}
	for id in owned.keys():
		if playable(int(id)) or CardData.get_card(int(id)).is_empty():
			continue
		var d := CardData.get_card(int(id))
		var kind := str(d.get("kind", "monster"))
		var best := 0
		var best_gap := 1 << 30
		var rng := RandomNumberGenerator.new()
		rng.seed = int(id)
		var pool_ids: Array = all_cards()
		for i in 60:
			var cand: int = pool_ids[rng.randi() % pool_ids.size()]
			var cd := CardData.get_card(cand)
			if str(cd.get("kind", "monster")) != kind or str(cd.get("frame", "")) in ["fusion", "synchro", "xyz"]:
				continue
			var gap := absi(int(cd.get("atk", 0)) - int(d.get("atk", 0))) + absi(int(cd.get("level", 0)) - int(d.get("level", 0))) * 300
			if gap < best_gap:
				best_gap = gap
				best = cand
		if best != 0:
			swap[int(id)] = best
	if swap.is_empty():
		return
	for id in swap:
		var n := int(owned.get(id, 0))
		owned.erase(id)
		owned[swap[id]] = mini(3, int(owned.get(swap[id], 0)) + n)
	for list in [main, extra, side]:
		for i in (list as Array).size():
			if swap.has(int(list[i])):
				list[i] = swap[int(list[i])]
	for sl in slots:
		for part in ["main", "extra", "side"]:
			var arr: Array = (sl as Dictionary).get(part, [])
			for i in arr.size():
				if swap.has(int(arr[i])):
					arr[i] = swap[int(arr[i])]
	save()
	var count := swap.size()
	get_tree().create_timer(3.0).timeout.connect(func():
		Router.toast(Loc.t("%d cards that had no working effect were swapped for cards that do") % count))


## A new duelist starts with a few classic cards; the deck itself is the starter they pick
## (Lumen is in every one). Lumen's own deck comes later, from the story.
func _starter() -> void:
	for id in CardData.deck_list("yugi") + CardData.extra_list("yugi"):
		owned[id] = mini(3, int(owned.get(id, 0)) + 1)
	if not CardData.has_deck("starter_warrior"):
		# (No starters in this build: the old way, the Echo list in your hands.)
		decks_owned.append("echo")
		main = Array(CardData.deck_list("echo"))
		extra = Array(CardData.extra_list("echo"))
	else:
		main = []
		extra = []
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("cards", "owned", owned)
	cfg.set_value("deck", "main", main)
	cfg.set_value("deck", "extra", extra)
	cfg.set_value("deck", "name", deck_name)
	_store_slot()
	cfg.set_value("deck", "side", side)
	cfg.set_value("deck", "slots", slots)
	cfg.set_value("deck", "dropped", dropped)
	cfg.set_value("deck", "slot", slot)
	cfg.set_value("deck", "banlist", banlist)
	cfg.set_value("wallet", "dp", dp)
	cfg.set_value("wallet", "record", record)
	cfg.set_value("deck", "owned_decks", decks_owned)
	cfg.set_value("deck", "starter", starter_pick)
	cfg.set_value("deck", "active", active)
	cfg.save(PATH)
	changed.emit()


func count(id: int) -> int:
	return int(owned.get(id, 0))


func in_deck(id: int) -> int:
	return main.count(id) + extra.count(id) + side.count(id)


## One of your saved decks, by its place in the list (the one that is open reads the live lists).
func slot_cards(i: int) -> Dictionary:
	if i < 0 or i >= slots.size():
		return {}
	if i == slot:
		return {"name": deck_name, "main": main.duplicate(), "extra": extra.duplicate()}
	var s: Dictionary = slots[i]
	return {"name": str(s.get("name", "Deck %d" % (i + 1))), "main": (s.get("main", []) as Array).duplicate(), "extra": (s.get("extra", []) as Array).duplicate()}


## Can that saved deck be dueled with as it stands? (Free Duel lets either side play any of them.)
func slot_ready(i: int) -> bool:
	if i == slot and i < slots.size():
		return deck_ok()
	var s := slot_cards(i)
	if s.is_empty():
		return false
	var m: Array = s["main"]
	var e: Array = s["extra"]
	if m.size() < MAIN_MIN or m.size() > MAIN_MAX or e.size() > EXTRA_MAX:
		return false
	var count := {}
	for id in m + e:
		if CardData.get_card(int(id)).is_empty():
			return false
		count[id] = int(count.get(id, 0)) + 1
	if banlist:
		for id in count:
			if int(count[id]) > limit(int(id)):
				return false
	return true


## Your saved decks that are ready to duel: [{"key": "slot:2", "name": "...", "open": bool}].
func my_decks() -> Array:
	var out := []
	for i in slots.size():
		if slot_ready(i):
			out.append({"key": "slot:%d" % i, "name": str(slot_cards(i)["name"]), "open": i == slot})
	return out


func deck_ok() -> bool:
	return main.size() >= MAIN_MIN and main.size() <= MAIN_MAX and extra.size() <= EXTRA_MAX and side.size() <= SIDE_MAX and illegal().is_empty()


func can_add(id: int, to_side := false) -> bool:
	var d := CardData.get_card(id)
	var is_extra: bool = str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]
	if in_deck(id) >= mini(mini(3, limit(id)), count(id)):
		return false
	if to_side:
		return side.size() < SIDE_MAX
	return extra.size() < EXTRA_MAX if is_extra else main.size() < MAIN_MAX


func add_side(id: int) -> void:
	if can_add(id, true):
		side.append(id)
		save()


func remove_side(id: int) -> void:
	if side.has(id):
		side.erase(id)
		save()


func add(id: int) -> void:
	if not can_add(id):
		return
	if str(CardData.get_card(id).get("frame", "")) in ["fusion", "synchro", "xyz"]:
		extra.append(id)
	else:
		main.append(id)
	save()


func remove(id: int) -> void:
	if main.has(id):
		main.erase(id)
	elif extra.has(id):
		extra.erase(id)
	save()


## Duel Points for finishing a duel. Returns how many were earned; `last_reward` holds the
## breakdown. `info` can carry {"opponent": key, "flawless": bool, "turns": int, "lp": int}.
func reward(won: bool, difficulty: int, info := {}) -> int:
	last_reward = []
	last_prize = 0
	if not won:
		record["streak"] = 0
		last_reward.append(["Duel finished", 40])
		dp += 40
		save()
		return 40
	last_reward.append([["Win (Beginner)", "Win (Easy)", "Win (Normal)", "Win (Hard)"][clampi(difficulty, 0, 3)], 120 + 60 * difficulty])
	daily_bump("win")
	var today := Time.get_date_string_from_system()
	if str(record.get("day", "")) != today:
		record["day"] = today
		last_reward.append(["First win of the day", 150])
	var opp := str(info.get("opponent", ""))
	if opp != "":
		var beaten: Dictionary = record.get("beaten", {})
		# The card they put on the line before the duel (see stake_for), when they did.
		var staked := int(info.get("stake", 0))
		var prize := staked
		if not beaten.has(opp):
			beaten[opp] = true
			record["beaten"] = beaten
			last_reward.append(["First win against this duelist", 100])
			# And a card out of their deck: their ace if they have one, else their best.
			if prize == 0 and not info.has("stake"):
				prize = _prize_card(opp, str(info.get("deck", "")))
		elif prize == 0 and not info.has("stake") and versus(opp)[0] == 1 and str(info.get("deck", "")) != "":
			# The second win: one more card from their deck. (The third gives you the deck.)
			prize = _prize_card("", str(info.get("deck", "")))
		if prize != 0:
			owned[prize] = mini(3, int(owned.get(prize, 0)) + 1)
			last_prize = prize
			last_reward.append(["New card: " + str(CardData.get_card(prize).get("name", "")), 0])
		if info.get("rare", false):
			last_reward.append(["Beat a night duelist", 300])
	var streak := int(record.get("streak", 0)) + 1
	record["streak"] = streak
	if streak >= 2:
		last_reward.append(["Win streak x%d" % streak, mini(150, 30 * (streak - 1))])
	if info.get("flawless", false):
		last_reward.append(["No damage taken", 100])
	elif int(info.get("lp", 9999)) <= 1000:
		last_reward.append(["Close call", 50])
	if int(info.get("turns", 99)) <= 6:
		last_reward.append(["Quick win", 50])
	var n := 0
	for line in last_reward:
		n += int(line[1])
	dp += n
	save()
	return n


## The card you win the first time you beat someone: their ace, or the rarest card in their
## deck that you do not already have three of.
## The card a duelist in the worlds puts on the line when they challenge you: "beat me and it
## is yours". Always the first two times you could win it from them; after that, on some days.
## A stronger duelist stakes a better card. 0: nothing on the line this time.
func stake_for(opp: String, deck: String, stars: int) -> int:
	var wins := int(versus(opp)[0])
	var beaten: Dictionary = record.get("beaten", {})
	if not beaten.has(opp):
		return _prize_card(opp if stars >= 4 else "", deck, stars)
	if wins <= 1:
		return _prize_card("", deck, stars)
	# Later: about one day in three, and the same answer all day.
	if absi(hash(opp + Time.get_date_string_from_system())) % 100 >= 35:
		return 0
	return _prize_card("", deck, stars)


func _prize_card(opp: String, deck: String, stars := 5) -> int:
	var ace := int(Characters.get_char(opp).get("ace", 0))
	if ace == 0:
		var ace_name := str(Characters.get_char(opp).get("ace_name", ""))
		ace = int(CardData.NAME_TO_ID.get(ace_name.to_lower(), 0))
	if ace != 0 and int(owned.get(ace, 0)) < 3 and str(CardData.get_card(ace).get("name", "Unknown")) != "Unknown" and playable(ace):
		return ace
	if deck == "" or not CardData.has_deck(deck):
		return 0
	# Their cards you do not have three of yet, best first. The top duelists give up their best;
	# the rest reach lower down the list, so a first-year never hands over a rare.
	var seen := {}
	var list: Array = []
	for id in CardData.deck_list(deck):
		if seen.has(id) or int(owned.get(id, 0)) >= 3 or CardData.get_card(id).get("speed_spell", false) or not playable(id):
			continue
		seen[id] = true
		list.append(id)
	if list.is_empty():
		return 0
	var rank := func(id: int) -> int: return CardData.rarity(id) * 10 + (1 if CardData.get_card(id).get("kind", "") == "monster" else 0)
	list.sort_custom(func(a, b): return rank.call(a) > rank.call(b))
	var at: float = [0.75, 0.75, 0.6, 0.35, 0.0, 0.0][clampi(stars, 0, 5)]
	return list[mini(list.size() - 1, int(list.size() * at))]


## Today's challenges: three small things to do, new every day.
const DAILY := [
	{"k": "win", "goal": 1, "name": "Today: win a duel", "text": "Win any duel today.", "reward": 120},
	{"k": "win", "goal": 3, "name": "Today: win 3 duels", "text": "Win three duels today.", "reward": 300},
	{"k": "pack", "goal": 1, "name": "Today: open a pack", "text": "Open a booster pack today.", "reward": 80},
	{"k": "talk", "goal": 5, "name": "Today: catch up", "text": "Talk to people 5 times today.", "reward": 80},
	{"k": "chip", "goal": 2, "name": "Today: star search", "text": "Find 2 Star Chips today.", "reward": 100},
	{"k": "sit", "goal": 1, "name": "Today: take a break", "text": "Sit down on a bench for a moment.", "reward": 40},
	{"k": "cat", "goal": 1, "name": "Today: make a friend", "text": "Pet a cat.", "reward": 40},
	{"k": "errand", "goal": 1, "name": "Today: lend a hand", "text": "Finish a favor for someone in town.", "reward": 150},
	{"k": "watch", "goal": 1, "name": "Today: front row", "text": "Stop and watch a street duel.", "reward": 50},
	{"k": "quiz", "goal": 1, "name": "Today: know your rules", "text": "Answer a duel quiz correctly.", "reward": 80},
]


func _daily() -> Dictionary:
	var today := Time.get_date_string_from_system()
	var d: Dictionary = record.get("daily", {})
	if str(d.get("day", "")) != today:
		d = {"day": today, "n": {}}
		record["daily"] = d
	return d


## Count something toward today's challenges ("win", "pack", "talk", "chip", "sit", "cat", "errand").
func daily_bump(kind: String) -> void:
	var d := _daily()
	var n: Dictionary = d.get("n", {})
	n[kind] = int(n.get(kind, 0)) + 1
	d["n"] = n
	record["daily"] = d
	Goals.week_bump(kind)


## The three challenges picked for today, with progress: [{id, name, text, have, goal, reward}]
func daily_rows() -> Array:
	var d := _daily()
	var day := str(d["day"])
	var n: Dictionary = d.get("n", {})
	var out: Array = []
	var pool: Array = DAILY + Goals.DAILY_DUEL
	var start := absi(hash(day)) % pool.size()
	var used := {}
	var i := 0
	while out.size() < 3 and i < pool.size():
		var t: Dictionary = pool[(start + i * 3) % pool.size()]
		i += 1
		if used.has(t["k"]):
			continue
		used[t["k"]] = true
		out.append({"id": "daily_%s_%s%d" % [day, t["k"], t["goal"]], "name": t["name"], "text": t["text"],
			"have": mini(int(t["goal"]), int(n.get(t["k"], 0))), "goal": t["goal"], "reward": t["reward"]})
	return out


func pack_price(pack: Dictionary) -> int:
	return int(pack.get("price", PACK_PRICE if int(pack.get("tab", 0)) == 0 and str(pack.get("key", "")) != "beyond" else THEMED_PRICE))


func _spell_kind(id: int) -> String:
	var d := CardData.get_card(id)
	var k := str(SpellRules.FX.get(str(d.get("name", "")), {}).get("k", ""))
	if k == "":
		k = str(d.get("st", "")).to_lower()
	return {"quick-play": "quick", "continuous": "cont"}.get(k, k)


## Does this card belong in a themed pack?
func _in_theme(theme: String, id: int) -> bool:
	var d := CardData.get_card(id)
	var kind := str(d.get("kind", ""))
	var race := str(d.get("race", ""))
	var attr := str(d.get("attribute", ""))
	var name := str(d.get("name", ""))
	match theme:
		"beyond":
			if kind == "monster":
				return str(d.get("frame", "")) in ["fusion", "synchro", "xyz", "ritual"]
			return kind == "spell" and (name.contains("Fusion") or name.contains("Polymerization") or name.contains("Ritual") or name == "Dragon's Mirror")
		"traps":
			return kind == "trap"
		"spellbook":
			return kind == "spell" and not (_spell_kind(id) in ["equip", "field", "cont"])
		"arsenal":
			return kind == "spell" and _spell_kind(id) in ["equip", "field", "cont"]
	if kind != "monster":
		return false
	match theme:
		"tide":
			return attr in ["WATER", "FIRE"]
		"gale":
			return attr == "WIND" or race == "Winged Beast"
		"dragons":
			return race in ["Dragon", "Dinosaur", "Reptile", "Sea Serpent"]
		"warriors":
			return race == "Warrior"
		"arcane":
			return race in ["Spellcaster", "Fairy", "Thunder"]
		"shadow":
			return race in ["Fiend", "Zombie"]
		"machines":
			return race == "Machine"
		"wild":
			return race in ["Beast", "Beast-Warrior"]
		"forest":
			return race in ["Insect", "Plant", "Rock", "Aqua", "Fish", "Pyro"]
	return false


## Every card that can be pulled from any pack.
## Every card that is in the game at all: the cards with working rules, plus every Normal
## monster in the database (those need no rules). Nothing outside this list can be found,
## bought or won, so every card you hold does what it says.
## The card lists are worked out once and kept, and thrown away when the card folder changes
## (a new folder picked in Settings, or the data arriving after the first look).
func _fresh() -> void:
	if int(_pools.get("_n", -1)) != CardData.EXT.size():
		_pools = {"_n": CardData.EXT.size()}
		_covers = {}


func every_playable() -> Array:
	_fresh()
	if _pools.has("**"):
		return _pools["**"]
	var ids := {}
	for id in all_cards():
		ids[id] = true
	for id in CardData.EXT:
		var d: Dictionary = CardData.EXT[id]
		# (Tokens are listed as Normal monsters in the card file: they are not cards you can own.)
		if str(d.get("frame", "")) == "normal" and int(d.get("level", 0)) > 0 and not str(d.get("name", "")).contains("Token"):
			ids[int(id)] = true
	# Only cards whose rules match their printed text (see CardExact).
	for id in ids.keys():
		if not CardExact.ok(CardData.get_card(int(id))):
			ids.erase(id)
	_pools["**"] = ids.keys()
	return _pools["**"]


## Is this card in the game?
func playable(id: int) -> bool:
	_fresh()
	if not _pools.has("set"):
		var st := {}
		for i in every_playable():
			st[i] = true
		# The game's own cards (the ones ready-made decks are written with, Fissure and the
		# like) are in the game even when no booster pack carries them.
		for i in CardData.CARDS:
			if CardExact.ok(CardData.get_card(int(i))):
				st[int(i)] = true
		_pools["set"] = st
	return (_pools["set"] as Dictionary).has(id) or id == CardData.LUMEN


func all_cards() -> Array:
	_fresh()
	if _pools.has("*"):
		return _pools["*"]
	var ids := {}
	for era in SERIES:
		for id in pool(era):
			ids[id] = true
	for id in ids.keys():
		if not CardExact.ok(CardData.get_card(int(id))):
			ids.erase(id)
	_pools["*"] = ids.keys()
	return _pools["*"]


## Lumen's cards the story has handed over so far (her own card always). With `open_only`,
## only those you hold fewer than three of.
## A card you met face-up in a duel (the Card Album shows it as seen). Saved with the rest.
func meet(id: int) -> void:
	if id == 0:
		return
	var met: Dictionary = record.get("met", {})
	if not met.has(str(id)):
		met[str(id)] = true
		record["met"] = met


func lumen_pool(open_only := false) -> Array:
	var had: Array = record.get("lumen_gifts", [])
	var out: Array = []
	for id in [CardData.LUMEN] + had:
		if not out.has(int(id)) and (not open_only or int(owned.get(int(id), 0)) < 3):
			out.append(int(id))
	return out


## One more copy of a card of Lumen's that you hold fewer than three of (her Extra Deck forms
## first, if asked). Returns the card id, or 0 when you already have three of everything.
func lumen_copy(forms_first := false) -> int:
	var open := lumen_pool(true)
	if open.is_empty():
		return 0
	var forms: Array = open.filter(func(id): return CardData.is_extra(int(id)) or int(id) == 99200005)
	var from: Array = forms if forms_first and not forms.is_empty() else open
	var id: int = int(from[randi() % from.size()])
	owned[id] = int(owned.get(id, 0)) + 1
	save()
	return id


## Every card that can come out of an era's pack: the cards its duelists play.
func pool(era: String) -> Array:
	_fresh()
	if era == "echo":
		return lumen_pool()           # (grows with the story: never kept from one look to the next)
	if _pools.has(era):
		return _pools[era]
	var ids := {}
	if FAMILIES.has(era):
		_pools[era] = family_ids(era)
		return _pools[era]
	if not (era in SERIES):
		var themed: Array = []
		for id in all_cards():
			if _in_theme(era, id):
				themed.append(id)
		_pools[era] = themed
		return themed
	# A series set: what was written down for it (CardPool), and for the four eras also every
	# family of that era and everything its duelists' decks play.
	for id in CardPool.era(era):
		ids[int(id)] = true
	if era in ["Vault", "legends"]:
		# (These two hold what the era packs do not hand out.)
		for other in (["Duel Monsters", "GX", "5D's", "ZEXAL"] if era == "Vault" else ["Duel Monsters", "GX", "5D's", "ZEXAL", "Vault"]):
			for id in pool(other):
				ids.erase(id)
	else:
		for fk in FAMILIES:
			if str(FAMILIES[fk]["era"]) == era:
				for id in family_ids(fk):
					ids[id] = true
		for k in Characters.ORDER:
			var d: Dictionary = Characters.DATA[k]
			if str(d.get("era", "")) != era or not CardData.has_deck(str(d["deck"])):
				continue
			for id in CardData.deck_list(str(d["deck"])) + CardData.extra_list(str(d["deck"])):
				ids[id] = true
	for id in ids.keys():
		var cd := CardData.get_card(int(id))
		if cd.is_empty() or str(cd.get("name", "Unknown")) == "Unknown":
			ids.erase(id)      # (the card folder does not know it)
	_pools[era] = ids.keys()
	return _pools[era]


## Buy and open a pack. Returns the card ids pulled (empty if you can't afford it).
func open_pack(era: String) -> Array:
	if not Unlocks.pack(era):
		Router.toast(Unlocks.pack_why(era))
		return []
	var cards := pool(era)
	var price := PACK_PRICE
	var count := PACK_SIZE
	for p in PACKS:
		if p["key"] == era:
			price = pack_price(p)
			count = int(p.get("size", PACK_SIZE))
	if era == "echo":
		# Never more than three of a card of Lumen's: a pack only holds the ones you still lack.
		if dp < price:
			return []
		if lumen_pool(true).is_empty():
			Router.toast(Loc.t("You hold three of every card of Lumen's that the story has given you so far."))
			return []
		dp -= price
		var got: Array = []
		for i in count:
			var id2 := lumen_copy()
			if id2 == 0:
				break
			got.append(id2)
		daily_bump("pack")
		save()
		return got
	if dp < price or cards.is_empty():
		return []
	dp -= price
	var pulls := []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in PACK_SIZE:
		var id: int = cards[rng.randi() % cards.size()]
		# The last slot leans toward stronger cards.
		if i == PACK_SIZE - 1:
			for tries in 6:
				var alt: int = cards[rng.randi() % cards.size()]
				var a := CardData.get_card(alt)
				if CardData.rarity(alt) >= 2:
					id = alt
					break
		pulls.append(id)
		owned[id] = int(owned.get(id, 0)) + 1
	daily_bump("pack")
	save()
	return pulls
