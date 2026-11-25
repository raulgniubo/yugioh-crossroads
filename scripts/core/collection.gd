extends Node
## Your cards: what you own, the deck you built, and Duel Points (DP) to spend on packs.
## Saved to user://collection.cfg.

signal changed

static var PATH := Saves.u("collection.cfg")
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
	{"key": "frontier", "tab": 0, "name": "New Frontier", "color": Color("4ad8c8"), "price": 200, "blurb": "Cards from after the four shows, picked for this world: hand traps, removal and Extra Deck monsters any deck can use, and seven newer families. Opens when you finish the story."},
	{"key": "legends", "tab": 0, "name": "Monster Legends", "color": Color("e8b04a"), "blurb": "Normal Monsters from every era: hundreds of them, from the classics to the rare big ones."},
	{"key": "echo", "tab": 0, "name": "Echo Pack", "color": Color("7fe8ff"), "price": 300, "size": 3, "blurb": "Cards of this game only: Lumen, her forms and the cards around her. Only the ones the story has already handed you, up to three of each."},
	{"key": "sylvan", "tab": 1, "name": "Sylvan Grove", "color": Color("5aa04a"), "family": true, "blurb": "The Sylvan plants of the high mountain: they dig through the top of the Deck, send Plants to the Graveyard and grow into the Sylvan High Protector and High Arbiter."},
	{"key": "heraldic", "tab": 1, "name": "Heraldic Beasts", "color": Color("8a5ac0"), "family": true, "blurb": "The Heraldic Beasts of the coats of arms, the Heraldry spells that copy and return them, and the Heraldry Numbers they build."},
	{"key": "artifact", "tab": 1, "name": "Artifact Armory", "color": Color("a0b0d0"), "family": true, "blurb": "The Artifacts, LIGHT weapons of the gods that sit face-down as Spells and come out the moment the other side destroys them."},
	{"key": "hieratic", "tab": 1, "name": "Hieratic Dynasty", "color": Color("e0c060"), "family": true, "blurb": "The Hieratic dragons of the sun: they Tribute each other from the hand and the field to call Dragon Normal Monsters, and the Sun Dragon Overlord rises over them all."},
	{"key": "hazy", "tab": 1, "name": "Hazy Flame and Fire Kings", "color": Color("ff6a2a"), "family": true, "blurb": "The Hazy Flame beasts that cannot be targeted and need FIRE Tributes, and the Fire King Avatars that burn themselves to rise again."},
	{"key": "inzektor", "tab": 1, "name": "Inzektor Hive", "color": Color("4a8a3a"), "family": true, "blurb": "The Inzektor, DARK insects that equip to each other and fire their effects when they let go, and the Exa Xyz that rule the hive."},
	{"key": "gears", "tab": 1, "name": "Gears and Rails", "color": Color("8a8aa0"), "family": true, "blurb": "The Geargia machines that gear up into Xyz, and the trains of the railway: Level 10 locomotives, their freight cars and the Superdreadnought Rail Cannons."},
	{"key": "noble_knight", "tab": 1, "name": "Knights of the Round Table", "color": Color("c0a050"), "family": true, "blurb": "The Noble Knights of Artorigus's round table, the Noble Arms they carry, Gwenhwyfar their queen, and the Ignoble Knights who turned against them."},
	{"key": "phantom_beast", "tab": 1, "name": "Mecha Phantom Beasts", "color": Color("5a8ab0"), "family": true, "blurb": "The Mecha Phantom Beasts, WIND machines that make Tokens to protect themselves and fight together in the air, with Dracossack at their head and the Phantom Beasts of old."},
	{"key": "evol", "tab": 1, "name": "Evolution of the Dinosaurs", "color": Color("d86a3a"), "family": true, "blurb": "The Evoltiles that flip and evolve into Evolsaurs, the Evolzar dragons they become, and the Evo- cards that drive the change."},
	{"key": "reptilianne", "tab": 1, "name": "Reptilianne Den", "color": Color("6aa04a"), "family": true, "blurb": "The Reptilianne, serpent-women who turn monsters to stone: they drop the other side's ATK to 0 and then feed on what is left."},
	{"key": "flamvell", "tab": 1, "name": "Flamvell Fire", "color": Color("ff7a3a"), "family": true, "blurb": "The Flamvell, FIRE dragons and fiends from a world of fire, and the Neo Flamvell who burn the other side's Graveyard to ash."},
	{"key": "ally_justice", "tab": 1, "name": "Allies of Justice", "color": Color("a0a0b0"), "family": true, "blurb": "The Ally of Justice machines built to hunt LIGHT monsters, from the little Cycle Reader up to Decisive Armor and the Field Marshal."},
	{"key": "laval", "tab": 1, "name": "Laval Eruption", "color": Color("e04a2a"), "family": true, "blurb": "The Laval of the volcano: FIRE monsters that grow stronger with every Laval in the Graveyard, and the Lavalval Synchros and Xyz they melt into."},
	{"key": "watt", "tab": 1, "name": "Wattage", "color": Color("f0d040"), "family": true, "blurb": "The Watt monsters, small LIGHT Thunder beasts that strike for their effects when they deal damage, and the Watt Synchros that charge through."},
	{"key": "gishki", "tab": 1, "name": "The Aquamirror", "color": Color("3a7ad8"), "family": true, "blurb": "The Gishki ritualists of the water and the Evigishki they summon through the Aquamirror, with the Aquamirror spells that find a ritual in the Deck."},
	{"key": "vylon", "tab": 1, "name": "Vylon Assembly", "color": Color("e0e8ff"), "family": true, "blurb": "The Vylon, LIGHT machine-angels that Synchro Summon and then equip themselves with the Vylon Equip Spells, and the Vylon Omega and Disigma at the top."},
	{"key": "swarm", "tab": 1, "name": "Swarm of the Lswarm", "color": Color("6a4a7a"), "family": true, "blurb": "The Steelswarm demons and the Evilswarm they became after the Infestation: Tributes for the old ones, Xyz Summons for the new, and the Infestation cards that spread through both."},
	{"key": "worm", "tab": 1, "name": "The Worm Invasion", "color": Color("8ab060"), "family": true, "blurb": "The Worms, LIGHT Reptiles from another planet: they flip face-down, swarm the field and turn every flip into a trick, until Worm Zero takes their place."},
	{"key": "frog", "tab": 1, "name": "Frogs and Penguins", "color": Color("4ab08a"), "family": true, "blurb": "The Frogs that swap, copy and sacrifice themselves for each other, the frog Xyz that rules the pond, and the Penguins that flip up to send your monsters home."},
	{"key": "barrier", "tab": 1, "name": "Wardens of the Barrier", "color": Color("e0d070"), "family": true, "blurb": "The six Barrier Statues that lock out every Attribute but their own, and the Counter Fairies who answer every Counter Trap with a reward."},
	{"key": "toy", "tab": 1, "name": "Toy Box Troubles", "color": Color("d87a3a"), "family": true, "blurb": "The chess Puppets from pawn to king, the Toy soldiers and magicians that hide in the Spell & Trap Zone until they spring out, and the puppeteers who pull every string."},
	{"key": "mask", "tab": 1, "name": "Masks and Curses", "color": Color("8a3a5a"), "family": true, "blurb": "The Masked Beast and the curse that summons it, the masks that weaken, bind and steal, and the old curses that age, freeze and punish whoever they fall on."},
	{"key": "goblin", "tab": 1, "name": "Goblin Gang", "color": Color("6a9a3a"), "family": true, "blurb": "The goblins of every squad and trade: the Attack Forces that hit hard and then need a nap, the thieves and salesmen, and the Ogre Grottos they live in."},
	{"key": "dd", "tab": 1, "name": "Different Dimension", "color": Color("5a6ad8"), "family": true, "blurb": "The D.D. monsters who banish whatever they touch and come back from the other side, the gates and jars that open the way, and the cards that call the banished home."},
	{"key": "dragon_ruler", "tab": 1, "name": "Dragon Rulers", "color": Color("d84a2a"), "family": true, "blurb": "The four Dragon Rulers of fire, water, wind and earth and their four little ones, the two that rule light and darkness, and the Rank 7 dragons that rule them all."},
	{"key": "ghostrick", "tab": 1, "name": "Ghostrick Night", "color": Color("8a5ad8"), "family": true, "blurb": "The Ghostrick spooks who hide face-down and flip up to play their tricks, the haunted mansion where nobody can attack a face-down monster, and the angel who wins once she collects ten materials."},
	{"key": "wind_up", "tab": 1, "name": "Wind-Up Toybox", "color": Color("e0c040"), "family": true, "blurb": "The Wind-Up toys, each with an effect it can use once while face-up, the Wind-Up Factory that keeps them coming, and the Zenmai Xyz Monsters that wind them up again."},
	{"key": "spellbook", "tab": 1, "name": "The Prophecy Library", "color": Color("4a5ad8"), "family": true, "blurb": "The Spellbook Spells and the Prophecy spellcasters who read them, the Spell Counter magicians of Endymion's citadel, and the Charmers who take control of monsters of their own Attribute."},
	{"key": "mermail", "tab": 1, "name": "Atlantis Rising", "color": Color("2a7ad8"), "family": true, "blurb": "The Mermails of the deep and the Atlantean sea serpents: WATER monsters that discard each other to come out, the Abyss- Spells and Traps, and the Poseidra dragons that rule the tide."},
	{"key": "gusto", "tab": 1, "name": "Winds of Gusto", "color": Color("5ac08a"), "family": true, "blurb": "The Gusto, the wind people and their beast companions who call each other from the Deck when they fall, and the Daigusto Synchro Monsters they ride into battle."},
	{"key": "fortune_lady", "tab": 1, "name": "Ladies of Fortune", "color": Color("c06ad8"), "family": true, "blurb": "The Fortune Ladies, spellcasters of time whose Level rises every Standby Phase and whose ATK grows with it, and Fortune Lady Every, the Synchro who stands over them all."},
	{"key": "fabled", "tab": 1, "name": "Realm of the Fabled", "color": Color("5a3a7a"), "family": true, "blurb": "The Fabled, fiends who do their best work from the discard pile: discard them and they come right back, and their Synchro lords punish your opponent for every card in hand."},
	{"key": "karakuri", "tab": 1, "name": "Karakuri Workshop", "color": Color("b07a3a"), "family": true, "blurb": "The Karakuri clockwork puppets that charge in, flip to defense when attacked, and trigger something every time their battle position changes, and the Karakuri Shoguns they tune into."},
	{"key": "synchron", "tab": 1, "name": "Junk, Wings and Resonance", "color": Color("e0a020"), "family": true, "blurb": "The rest of the Synchron and Junk monsters that build Synchro Summons out of scrap, the Blackwings and their Assault Blackwings, and the Resonators that tune for the Archfiends."},
	{"key": "meklord", "tab": 1, "name": "Machine Emperors and Earthbound Gods", "color": Color("8a8a9a"), "family": true, "blurb": "The Meklord Emperors that steal Synchro Monsters and wear them, their Armies and Astro dragons, and the Earthbound Immortals, the giant gods drawn on the earth that attack your Life Points directly."},
	{"key": "cyber", "tab": 1, "name": "Cyber Style", "color": Color("6ac0d8"), "family": true, "blurb": "The machines of the Cyber style: the rest of the Cyber Dragon line, the Cyberdark monsters that arm themselves from the Graveyard, Cyber Ogre and the old Cyber monsters, and the Roid vehicles."},
	{"key": "sacred_beast", "tab": 1, "name": "The Three Phantasms", "color": Color("8a1a2a"), "family": true, "blurb": "Uria, Hamon and Raviel, the three Sacred Beasts, with the martyrs and summoners that serve them, the fallen paradise they rise in, and Armityle, the phantasm they become together."},
	{"key": "hero", "tab": 1, "name": "Heroes and Villains", "color": Color("c03030"), "family": true, "blurb": "Every kind of HERO: the Evil HEROes who fuse with Dark Fusion, the Masked HEROes behind Mask Change, the Vision and Destiny HEROes, and the rest of the Elemental HEROes and their Neos fusions."},
	{"key": "union", "tab": 1, "name": "Union Hangar", "color": Color("3a8ad8"), "family": true, "blurb": "The Union monsters that equip to each other and split apart again: the A-B-C Dragon Buster pieces, the X-Y-Z cannons' new parts, Kiryu, the beasts of fire and ice, and the hangar that launches them."},
	{"key": "spirit", "tab": 1, "name": "Spirits of the Old Shrine", "color": Color("d84a6a"), "family": true, "blurb": "The Spirit monsters who strike and return to the hand at the end of the turn, the Shinobird ritual, and the six Elemental Lords who wake when five of their Attribute rest in the Graveyard."},
	{"key": "darklord", "tab": 1, "name": "Fall of the Darklords", "color": Color("6a2a8a"), "family": true, "blurb": "The fallen angels who lead the Darklords: Morningstar, Superbia and the rest, the Spells and Traps they cast twice from the grave, and the First Darklord they fuse into."},
	{"key": "jurrac", "tab": 1, "name": "Age of the Jurrac", "color": Color("e0602a"), "family": true, "blurb": "The fire dinosaurs of the Jurrac: raptors that call the next one from the Deck, giants that break the field in half, and the meteor that ends it all."},
	{"key": "legends_king", "tab": 1, "name": "Swords of Legend", "color": Color("c08a2e"), "family": true, "blurb": "The swordsman who slays dragons and the swords that serve him, the Legendary Knights who answer the Legend of Heart, Jinzo and the cyborgs that hunt Traps, and the Relinquished ritual."},
	{"key": "bujin", "tab": 1, "name": "Divine Warriors of the Sun", "color": Color("e0c070"), "family": true, "blurb": "The Bujin: Beast-Warrior gods and their Bujingi beast servants, who throw themselves from the hand to double an attack or stop one cold. The Bujintei Xyz lead them, one of each."},
	{"key": "nordic", "tab": 1, "name": "Twilight of the Gods", "color": Color("8ab4d8"), "family": true, "blurb": "The Nordics: Alfar, Beasts and Ascendants who Summon each other in pairs, the Relics they carry, and the three Aesir gods Odin, Thor and Loki who come back every time they fall."},
	{"key": "armed_dragon", "tab": 1, "name": "Climbing Levels", "color": Color("8a9aa8"), "family": true, "blurb": "The Armed Dragons and every LV monster: they start small, level up by sending themselves away, and come back stronger. Armed Dragon LV10, Horus LV8 and Silent Magician LV8 wait at the top."},
	{"key": "red_eyes", "tab": 1, "name": "Eyes of Red Potential", "color": Color("d83a3a"), "family": true, "blurb": "Red-Eyes Black Dragon and its whole brood: the chicks and black stones that hatch it, the metal, flare and darkness dragons it grows into, and Red-Eyes Fusion to tie it all together."},
	{"key": "blue_eyes", "tab": 1, "name": "Legend of the White Dragon", "color": Color("6ab4ff"), "family": true, "blurb": "Blue-Eyes White Dragon and every card that serves it: the maidens and sages with eyes of blue, the white stones, and the Ultimate, Twin Burst and Spirit dragons it becomes."},
	{"key": "dark_magician", "tab": 1, "name": "School of Dark Magic", "color": Color("7a4ad8"), "family": true, "blurb": "Dark Magician, Dark Magician Girl and everything built around them: the spells that only they can cast, the knights they fuse into, and the dragon Timaeus who rides with them."},
	{"key": "fire_fist", "tab": 1, "name": "Brotherhood of the Fire Fist", "color": Color("ff8a2a"), "family": true, "blurb": "The Fire Fist: FIRE Beast-Warriors who Set Fire Formation Spells and Traps straight from the Deck, then burn them for power. Tiger King, Cardinal and Kirin lead the brotherhood."},
	{"key": "tg", "tab": 1, "name": "Tech Genus", "color": Color("6ab0ff"), "family": true, "blurb": "The T.G. monsters: machines and beasts that fetch a new T.G. every time one is destroyed, and the T.G. Synchros, up to Halberd Cannon and Glaive Blaster, that stop Summons cold."},
	{"key": "naturia", "tab": 1, "name": "Voice of the Forest", "color": Color("6ac46a"), "family": true, "blurb": "The Naturia: small plants and bugs that punish every card your opponent plays, and the Synchro beasts Barkion, Landoise and Naturia Beast that negate Spells, Traps and effects outright."},
	{"key": "cloudian", "tab": 1, "name": "Fog, Fangs and Fossils", "color": Color("c8d8e8"), "family": true, "blurb": "The Cloudians, who spread fog counters and burst on contact; the Venom snakes and their swamp; and the Fossil fusions dug up from both Graveyards."},
	{"key": "kuriboh", "tab": 1, "name": "Kuriboh and Company", "color": Color("b07a4a"), "family": true, "blurb": "Kuriboh and its many cousins, the Magnet Warriors who snap together into the Magna Warriors, and the Harpie Ladies with their pet dragons."},
	{"key": "ninja", "tab": 1, "name": "Way of the Ninja", "color": Color("4a5a7a"), "family": true, "blurb": "The Ninjas and their Ninjitsu Arts: monsters that hide face-down, swap places and strike from the shadows, and the Dragon Ninjas that need a Ninja and an Art to act."},
	{"key": "ice_barrier", "tab": 1, "name": "Guardians of the Ice Barrier", "color": Color("8fd8ff"), "family": true, "blurb": "The Ice Barrier: WATER monsters who lock the field while another of them stands guard, and the Synchro dragons Brionac, Gungnir and Trishula they become."},
	{"key": "arcana_force", "tab": 1, "name": "Turn of the Arcana", "color": Color("f0e0a0"), "family": true, "blurb": "The Arcana Force: Fairies that toss a coin when they are Summoned. Heads, a blessing; tails, a curse. Light Barrier lets you skip the coin and pick."},
	{"key": "koaki_meiru", "tab": 1, "name": "Iron Core", "color": Color("c8742c"), "family": true, "blurb": "The Koa'ki Meiru: strong monsters that fall apart at the End Phase unless you feed them an Iron Core or show the right monster. In return they shut down LIGHT and DARK, Spells and Traps."},
	{"key": "exodia", "tab": 1, "name": "The Forbidden One", "color": Color("e0b040"), "family": true, "blurb": "Exodia's five pieces and every card that calls on them, plus the Batterymen and the Gadgets: small Thunder and Machine monsters that power each other up."},
	{"key": "battlin_boxer", "tab": 1, "name": "Ring of Champions", "color": Color("ff4a3d"), "family": true, "blurb": "The Battlin' Boxers: FIRE fighters who come in pairs, take the hits for each other, and overlay into the Numbers 79 and 105. Jolt Counter and Last Counter answer every punch."},
	{"key": "gimmick_puppet", "tab": 1, "name": "Mansion of the Dreadful Dolls", "color": Color("b05cff"), "family": true, "blurb": "The Gimmick Puppets: broken dolls that drop from the hand at Level 8, overlay into Numbers 15, 40 and 88, and rank up into the Chaos Numbers that can end a duel on their own."},
	{"key": "x_saber", "tab": 1, "name": "Sabers of the Sword Saints", "color": Color("c9b06a"), "family": true, "blurb": "The X-Sabers and XX-Sabers: EARTH swordsmen who call each other from the Deck and the Graveyard, and the Gottoms and Souza Synchros who lead them. Saber Slash cuts as many cards as they have blades."},
	{"key": "volcanic", "tab": 1, "name": "Volcano Island", "color": Color("ff6a2a"), "family": true, "blurb": "The Volcanics: Pyro monsters that burn, blow up and come back, and the Blaze Accelerator cannons that fire them. Volcanic Emperor and Volcanic Doomfire burn the whole field down."},
	{"key": "alien", "tab": 1, "name": "Invasion of the A-Counters", "color": Color("8be04f"), "family": true, "blurb": "The Aliens: they mark your monsters with A-Counters, weaken every monster that carries one, and then take them over. Brainwashing Beam, Mass Hypnosis and the \"A\" Cell spells do the marking."},
	{"key": "guardian", "tab": 1, "name": "Gate of the Guardians", "color": Color("7a9cff"), "family": true, "blurb": "Sanga, Kazejin and Suijin, the three who stand at the gate, and the Gate Guardians they become. With them, the weapon Guardians who can only take the field once their own weapon is on it."},
	{"key": "chronomaly", "tab": 1, "name": "Out-of-Place Artifacts", "color": Color("c9a24a"), "family": true, "blurb": "The Chronomaly: stone heads, crystal skulls and golden jets from places they should not be. They call each other out fast, change their own Levels, drop the other side's ATK to 0, and overlay into the Chronomaly Numbers."},
	{"key": "scrap", "tab": 1, "name": "Scrapyard", "color": Color("a08060"), "family": true, "blurb": "The Scraps: monsters built from junk that are meant to be destroyed. Break one with another Scrap's effect and it hands you a different one from the Graveyard, Scrap Factory replaces it from the Deck, and Scrap Dragon trades one of your cards for one of theirs every turn."},
	{"key": "morphtronic", "tab": 1, "name": "Morphtronic Workshop", "color": Color("f0c040"), "family": true, "blurb": "The Morphtronics: toys and gadgets that do one thing in Attack Position and another in Defense Position. Celfon rolls a die to call more of them, Radion and Boarden turn a field of small machines into direct attacks, and Power Tool Dragon fetches their equipment."},
	{"key": "vampire", "tab": 1, "name": "Vampire Kingdom", "color": Color("8a2040"), "family": true, "blurb": "The Vampires: Zombies that pay Life Points for what they want. They send cards from the other side's Deck to the Graveyard, take over monsters they destroy in battle, and Vampire Kingdom destroys a card every time the other Deck loses one."},
	{"key": "crystal_beast", "tab": 1, "name": "Rainbow Ruins", "color": Color("6fd6c8"), "family": true, "blurb": "The Crystal Beasts: seven gem animals that don't go to the Graveyard when they are destroyed. They wait in your Spell and Trap Zone as crystals, come back with Crystal Promise and Ruby Carbuncle, and with all seven out Rainbow Dragon arrives."},
	{"key": "amazoness", "tab": 1, "name": "Amazoness Village", "color": Color("c9773a"), "family": true, "blurb": "The Amazoness: a tribe of Warriors who punish every attack. Princess searches, Queen keeps them from dying in battle, Onslaught banishes what they fight, and the Pet Liger Fusions close the game. The Dark Scorpion gang rides along in this pack: five thieves who each steal something when they hit you directly."},
	{"key": "heroic", "tab": 1, "name": "Heroic Challengers", "color": Color("e0563c"), "family": true, "blurb": "The Heroic Challengers: Level 4 Warriors that call each other out and overlay into the Heroic Champions. Excalibur doubles to 4000 ATK, Rhongomyniad locks the whole field, and several of them get stronger when your Life Points drop to 500."},
	{"key": "dragunity", "tab": 1, "name": "Dragunity Legion", "color": Color("58b8d8"), "family": true, "blurb": "The Dragunity: winged riders who wear small Dragons as equipment. The Dragon jumps off the rider as a Tuner, and the pair become a Dragunity Knight on the spot. Dragon Ravine feeds the Graveyard they equip from."},
	{"key": "gladiator", "tab": 1, "name": "Gladiator's Assault", "color": Color("c8843c"), "family": true, "blurb": "The Gladiator Beasts: each one that fights goes back into the Deck at the end of the Battle Phase and tags in a different one, which uses its effect as it arrives. Two or three of them on the field shuffle together into Gyzarus or Heraklinos without Polymerization."},
	{"key": "toon", "tab": 1, "name": "Toon Kingdom", "color": Color("f2a03c"), "family": true, "blurb": "The Toons: cartoon copies of famous monsters that walk past the other side's monsters and attack directly while Toon World is open. Toon Kingdom keeps them from being destroyed, and Table of Contents finds whatever page you need."},
	{"key": "madolche", "tab": 1, "name": "Madolche Tea Party", "color": Color("f08ab0"), "family": true, "blurb": "The Madolche: a kingdom of sweets that never stays in the Graveyard. Destroyed Madolche shuffle back into the Deck, Ticket and Chateau turn that into new cards, and Queen Tiaramisu sends the other side's field back with them."},
	{"key": "genex", "tab": 1, "name": "Genex Works", "color": Color("4fb0a8"), "family": true, "blurb": "The Genex: machines built from every Attribute. Genex Controller tunes them into Synchros that change with the material you feed them, and the R-Genex line searches itself out of the Deck one card after another."},
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
	{"key": "spells", "tab": 3, "name": "Sorcerer's Library", "color": Color("3fe0c0"), "blurb": "Normal and Quick-Play Spells: removal, draw power, revival."},
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
## (0.80.0) The decks from the show cost less than the Competitive one: early show, later show
## (700 and 950 DP next to a 1200 DP duelist's deck; 500 and 700 next to a 900 DP theme deck).
const ANIME_SHARE := {"anime1": 0.58, "anime2": 0.79}


static func anime_price(version: String, full_price: int) -> int:
	return int(round(full_price * float(ANIME_SHARE.get(version, 1.0)) / 50.0)) * 50
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
	{"key": "deck_genex", "art": "machines", "cover": "Locomotion R-Genex", "color": Color("4fb0a8"), "era": "5D's", "blurb": "Undine fetches Genex Controller, Magma fetches Crusher, Crusher fetches Accelerator, and Accelerator puts every searched Genex straight onto the field. Then the Controller tunes them into Triarm, Hydro or Locomotion."},
	{"key": "deck_madolche", "art": "arcane", "cover": "Madolche Queen Tiaramisu", "color": Color("f08ab0"), "era": "ZEXAL", "blurb": "Magileine and Anjelly fetch the rest of the court, Hootcake calls one more from the Deck, and two Level 4 Madolche make Queen Tiaramisu, who shuffles two of your opponent's cards away. Keep your Graveyard empty and Puddingcess does the rest."},
	{"key": "deck_toon", "art": "arcane", "cover": "Toon Dark Magician", "color": Color("f2a03c"), "era": "Duel Monsters", "blurb": "Open Toon World or Toon Kingdom first. Then Toon Harpie Lady and Toon Cyber Dragon come down for free, Toon Dark Magician calls another Toon from the Deck, and all of them attack directly."},
	{"key": "deck_gladiator", "art": "warriors", "cover": "Gladiator Beast Gyzarus", "color": Color("c8843c"), "era": "GX", "blurb": "Attack with anything, then tag out: Laquari comes in at 2100, Bestiari destroys a Spell or Trap, Darius brings one back from the Graveyard. Bestiari plus any other Gladiator Beast becomes Gyzarus, who destroys two cards."},
	{"key": "deck_dragunity", "art": "dragons", "cover": "Dragunity Knight - Vajrayana", "color": Color("58b8d8"), "era": "5D's", "blurb": "Dragon Ravine sends Phalanx to the Graveyard. Dux equips it on arrival, Phalanx hops off as a Tuner, and the two make Vajrayana, who equips Phalanx again and doubles its own ATK."},
	{"key": "deck_heroic", "art": "warriors", "cover": "Heroic Champion - Excalibur", "color": Color("e0563c"), "era": "ZEXAL", "blurb": "Double Lance brings its twin, Thousand Blades calls another Heroic from the Deck, and any two Level 4 Warriors become Excalibur: detach both materials and it attacks at 4000."},
	{"key": "deck_amazoness", "art": "warriors", "cover": "Amazoness Queen", "color": Color("c9773a"), "era": "Duel Monsters", "blurb": "Princess fetches a Spell or Trap and calls another Amazoness when she attacks. With Queen on the field none of them die in battle, and Secret Arts fuses them into Empress or Pet Liger."},
	{"key": "deck_crystal_beast", "art": "arcane", "cover": "Rainbow Dragon", "color": Color("6fd6c8"), "era": "GX", "blurb": "Sapphire Pegasus and Crystal Bond fill your back row with crystals. Crystal Beacon and Crystal Promise turn them back into monsters, Rare Value draws from them, and seven different Crystal Beasts on your field or in your Graveyard call Rainbow Dragon."},
	{"key": "deck_vampire", "art": "shadow", "cover": "Vampire Lord", "color": Color("8a2040"), "era": "GX", "blurb": "Vampire Takeover opens the Kingdom straight from the Deck. Shadow Vampire and Duke bring more Vampires with them, Fraulein pays Life Points to win any battle, and what your Vampires destroy comes back on your side."},
	{"key": "deck_morphtronic", "art": "machines", "cover": "Power Tool Dragon", "color": Color("f0c040"), "era": "5D's", "blurb": "Celfon rolls a die and calls a Morphtronic from the top of your Deck. Radion gives them all 800 ATK, Boarden lets them attack directly, and a Tuner turns two of them into Power Tool Dragon."},
	{"key": "deck_scrap", "art": "machines", "cover": "Scrap Dragon", "color": Color("a08060"), "era": "5D's", "blurb": "Scrap Chimera brings a Tuner back from the Graveyard for Scrap Dragon. Scrap Dragon destroys one of your own Scraps and one of their cards, the Scrap you destroyed fetches another, and Scrap Factory calls a new one from the Deck."},
	{"key": "deck_chronomaly", "art": "arcane", "cover": "Number 33: Chronomaly Machu Mech", "color": Color("c9a24a"), "era": "ZEXAL", "blurb": "Nebra Disk searches, Crystal Bones and Moai arrive for free, and two Level 4 Chronomaly make Chateau Huyuk, who turns a monster's ATK to 0. Then Machu Mech burns for the difference."},
	{"key": "deck_guardian", "art": "arsenal", "cover": "Gate Guardian", "color": Color("7a9cff"), "era": "Duel Monsters", "blurb": "Thunder, wind and water hold the line until the three of them fuse into a Gate Guardian. Dark Element calls up the darkest one, and Guardian Eatos swings her sword between them."},
	{"key": "deck_alien", "art": "beyond", "cover": "Alien Overlord", "color": Color("8be04f"), "era": "GX", "blurb": "Every monster an Alien touches gets an A-Counter, and every A-Counter makes it weaker against them. Mark enough and Mass Hypnosis takes three of them home."},
	{"key": "deck_volcanic", "art": "wild", "cover": "Volcanic Emperor", "color": Color("ff6a2a"), "era": "GX", "blurb": "Load the Blaze Accelerator, fire small Volcanics at their monsters, and every one that hits the Graveyard burns. When three Pyros are gone, Volcanic Emperor rises."},
	{"key": "deck_x_saber", "art": "warriors", "cover": "XX-Saber Gottoms", "color": Color("c9b06a"), "era": "5D's", "blurb": "Boggart Knight and Pellina bring two swordsmen at once, Faultroll calls back the fallen, and the Synchro lords take over: Hyunlei clears the back row, Gottoms empties their hand."},
	{"key": "deck_gimmick_puppet", "art": "shadow", "cover": "Number 88: Gimmick Puppet of Leo", "color": Color("b05cff"), "era": "ZEXAL", "blurb": "Rouge Doll and Fiendish Knight drag two dolls out at a time, Little Soldiers turn them into Level 8s, and Giant Grinder starts cutting. If Leo gets three counters, the duel is over."},
	{"key": "deck_battlin_boxer", "art": "warriors", "cover": "Number 105: Battlin' Boxer Star Cestus", "color": Color("ff4a3d"), "era": "ZEXAL", "blurb": "Promoter and Uppercutter fill the ring, King Dempsey keeps the corner stocked, and Star Cestus turns their own attacks back on them. Then Comet Cestus throws the last punch."},
	{"key": "deck_exodia", "art": "beyond", "cover": "Exodia the Forbidden One", "color": Color("e0b040"), "era": "Duel Monsters", "blurb": "Stall, draw, and dig. Waboku and Swords buy the turns, Mystic Tomato and Break the Seal fetch the pieces, and when all five are in your hand the duel just ends."},
	{"key": "deck_koaki_meiru", "art": "arsenal", "cover": "Koa'ki Meiru Maximus", "color": Color("c8742c"), "era": "GX", "blurb": "Big bodies for cheap, as long as you keep the cores coming. Urnight and Boulder fill the field, the Rock guards negate whatever they throw, and Maximus breaks a card every turn."},
	{"key": "deck_arcana_force", "art": "arcane", "cover": "Arcana Force EX - The Light Ruler", "color": Color("f0e0a0"), "era": "GX", "blurb": "Every Summon is a coin toss until Light Barrier hits the field. After that you choose heads every time, and the three Rulers take over."},
	{"key": "deck_ice_barrier", "art": "tide", "cover": "Trishula, Dragon of the Ice Barrier", "color": Color("8fd8ff"), "era": "5D's", "blurb": "Two Ice Barrier monsters on the field and the locks start: no big attackers, no Spells, no changing positions. Then a Tuner joins in and Trishula takes a card from everywhere."},
	{"key": "deck_ninja", "art": "shadow", "cover": "Twilight Ninja Getsuga, the Shogun", "color": Color("4a5a7a"), "era": "ZEXAL", "blurb": "Hanzo finds the Arts, Yellow Ninja and Kagero bring friends face-down, and Dancing Leaves trades one ninja for another whenever you like. They never see what's under the cover."},
	{"key": "deck_kuriboh", "art": "arcane", "cover": "Kuribabylon", "color": Color("b07a4a"), "era": "Duel Monsters", "blurb": "A swarm of furballs that eat attacks for breakfast. Multiply them, call the five brothers out with Five Star Twilight, and when the field is full, Detonate takes their cards down with them."},
	{"key": "deck_cloudian", "art": "gale", "cover": "Cloudian - Eye of the Typhoon", "color": Color("c8d8e8"), "era": "GX", "blurb": "Smoke Ball and Sheep Cloud fill the field with fog, Turbulence and Cirrostratus spend it to blow cards away, and every Cloudian that bursts comes back with Raging Cloudian."},
	{"key": "deck_naturia", "art": "forest", "cover": "Naturia Beast", "color": Color("6ac46a"), "era": "5D's", "blurb": "Every time they act, the forest answers: Sunflower and Vein negate, Antjaw and Camellia grow new plants, and Naturia Beast and Barkion lock down Spells and Traps for good."},
	{"key": "deck_tg", "art": "machines", "cover": "T.G. Halberd Cannon", "color": Color("6ab0ff"), "era": "5D's", "blurb": "Lose a T.G. and you get another. Striker and Warwolf jump in for free, Cyber Magician turns your hand into Synchro material, and Hyper Librarian draws a card for every Synchro after."},
	{"key": "deck_fire_fist", "art": "wild", "cover": "Brotherhood of the Fire Fist - Tiger King", "color": Color("ff8a2a"), "era": "ZEXAL", "blurb": "Bear and Rooster set a Formation, send it away to break a card, and set the next one. Every Formation makes the brothers stronger, and two of them make a Tiger King."},
	{"key": "deck_dark_magician", "art": "spellbook", "cover": "Dark Magician", "color": Color("7a4ad8"), "era": "Duel Monsters", "blurb": "Rod and Robe bring the master out early, Magician Navigation drops two magicians at once, and Dark Magic Attack clears the board. Then teacher and student fuse into a Dragon Knight."},
	{"key": "deck_blue_eyes", "art": "dragons", "cover": "Blue-Eyes White Dragon", "color": Color("6ab4ff"), "era": "Duel Monsters", "blurb": "The sages and stones find the dragons, the maiden calls one out the moment she's targeted, and three white dragons on the field means only one thing: Ultimate."},
	{"key": "deck_red_eyes", "art": "dragons", "cover": "Red-Eyes Black Dragon", "color": Color("d83a3a"), "era": "Duel Monsters", "blurb": "Not the strongest dragon, but the one with the most potential. The chick and the black stone bring it out, Red-Eyes Fusion skips the wait, and every Red-Eyes that falls burns on the way down."},
	{"key": "deck_armed_dragon", "art": "dragons", "cover": "Armed Dragon LV10", "color": Color("8a9aa8"), "era": "GX", "blurb": "LV3 becomes LV5, LV5 becomes LV7, and Level Up! skips the waiting. By the time LV10 lands, a single discard wipes their whole board."},
	{"key": "deck_nordic", "art": "arcane", "cover": "Odin, Father of the Aesir", "color": Color("8ab4d8"), "era": "5D's", "blurb": "Dverg and Ljosalf bring a second Nordic every turn, the Beasts and Ascendants tune them up, and an Aesir hits the field. Destroy one and it comes back at the End Phase."},
	{"key": "deck_bujin", "art": "warriors", "cover": "Bujintei Susanowo", "color": Color("e0c070"), "era": "ZEXAL", "blurb": "Yamato searches every End Phase, Crane doubles its ATK from the hand, and Turtle and Hare make it untouchable. Two of them become Susanowo, who strikes every monster they have."},
	{"key": "deck_legends_king", "art": "warriors", "cover": "Buster Blader, the Destruction Swordmaster", "color": Color("c08a2e"), "era": "Duel Monsters", "blurb": "Buster Blader takes up the Destruction Swords, Jinzo keeps every Trap shut, and a dragon on the other side of the field only makes the swordsman stronger."},
	{"key": "deck_jurrac", "art": "wild", "cover": "Jurrac Titano", "color": Color("e0602a"), "era": "Duel Monsters", "blurb": "Every raptor that falls calls another from the Deck. Keep them coming until Titano shows up, then let the meteor burn the whole field down."},
	{"key": "deck_darklord", "art": "shadow", "cover": "Darklord Superbia", "color": Color("6a2a8a"), "era": "Duel Monsters", "blurb": "The Darklords pay Life Points to cast their Spells and Traps a second time from the Graveyard. Morningstar calls the host down, and three of them become the First Darklord."},
	{"key": "deck_spirit", "art": "forest", "cover": "Yata-Garasu", "color": Color("d84a6a"), "era": "Duel Monsters", "blurb": "Spirits hit hard and go home before your opponent can touch them. Aratama finds them, Nikitama doubles the summons, and the Shinobirds come down to finish the job."},
	{"key": "deck_union", "art": "machines", "cover": "B-Buster Drake", "color": Color("3a8ad8"), "era": "Duel Monsters", "blurb": "Every machine snaps onto another to shield it, then breaks off when it's needed. Get A, B and C on the field and they combine into the Dragon Buster."},
	{"key": "deck_hero", "art": "warriors", "cover": "Evil HERO Malicious Edge", "color": Color("c03030"), "era": "GX", "blurb": "Not every hero wears white. Dark Fusion turns the Elemental HEROes into fiends nobody can target, and Mask Change keeps a Masked HERO ready for every fight."},
	{"key": "deck_sacred_beast", "art": "shadow", "cover": "Hamon, Lord of Striking Thunder", "color": Color("8a1a2a"), "era": "GX", "blurb": "Three beasts sealed under the school. The martyrs and summoners open the doors one by one, and once all three stand on the field they can merge into Armityle."},
	{"key": "deck_cyber", "art": "machines", "cover": "Cyber Dragon", "color": Color("6ac0d8"), "era": "GX", "blurb": "Cyber Dragon drops in for free, Power Bond doubles whatever it fuses, and the Cyberdark dragons pull a monster out of the Graveyard to wear as armor."},
	{"key": "deck_meklord", "art": "machines", "cover": "Meklord Emperor Wisel", "color": Color("8a8a9a"), "era": "5D's", "blurb": "The Meklord Armies march in and fall on purpose, because every machine destroyed by an effect calls down an Emperor. And every Emperor wants your Synchro Monsters."},
	{"key": "deck_synchron", "art": "warriors", "cover": "Junk Synchron", "color": Color("e0a020"), "era": "5D's", "blurb": "Nothing in Satellite goes to waste. Junk Synchron pulls a buddy back from the Graveyard, and a pile of small monsters turns into Junk Warrior, then into something bigger."},
	{"key": "deck_karakuri", "art": "machines", "cover": "Karakuri Muso mdl 818 \"Haipa\"", "color": Color("b07a3a"), "era": "5D's", "blurb": "The puppets must attack, and they flip to defense the moment they're targeted. Every flip winds up another effect, and the Shoguns turn the turning into card advantage."},
	{"key": "deck_fabled", "art": "shadow", "cover": "Fabled Grimro", "color": Color("5a3a7a"), "era": "5D's", "blurb": "Throw your hand away. Cerburrel and Lurrie jump straight back out of the Graveyard, Grimro finds the next one, and the Fabled lords tune them into something your opponent can't answer."},
	{"key": "deck_fortune_lady", "art": "arcane", "cover": "Fortune Lady Earth", "color": Color("c06ad8"), "era": "5D's", "blurb": "Every turn the Ladies grow one Level older and stronger. Light calls the next Lady when it leaves, Fire burns a monster on arrival, and time is always on their side."},
	{"key": "deck_gusto", "art": "gale", "cover": "Windaar, Sage of Gusto", "color": Color("5ac08a"), "era": "5D's", "blurb": "When a Gusto falls, the wind carries another out of the Deck. Shuffle the fallen back in to keep it going, and ride the Daigusto beasts once the field fills up."},
	{"key": "deck_mermail", "art": "tide", "cover": "Mermail Abyssmegalo", "color": Color("2a7ad8"), "era": "ZEXAL", "blurb": "The Mermails throw other WATER monsters away to rise from the hand, and every Atlantean that sinks to the Graveyard strikes back on its way down."},
	{"key": "deck_spellbook", "art": "spellbook", "cover": "High Priestess of Prophecy", "color": Color("4a5ad8"), "era": "ZEXAL", "blurb": "The Prophecy spellcasters read one Spellbook after another. Every Spellbook in the Graveyard makes the next spell stronger, and the High Priestess turns pages into destruction."},
	{"key": "deck_wind_up", "art": "machines", "cover": "Wind-Up Magician", "color": Color("e0c040"), "era": "ZEXAL", "blurb": "Each toy does its trick once, then waits to be wound up again. Wind-Up Magician calls a friend every time a trick goes off, and the Zenmai reset the whole box."},
	{"key": "deck_ghostrick", "art": "shadow", "cover": "Ghostrick Jiangshi", "color": Color("8a5ad8"), "era": "ZEXAL", "blurb": "Boo. The spooks hide face-down where nothing can attack them, turn your monsters face-down too, and pop up one by one to play their tricks."},
	{"key": "deck_dragon_ruler", "art": "dragons", "cover": "Blaster, Dragon Ruler of Infernos", "color": Color("d84a2a"), "era": "ZEXAL", "blurb": "A little dragon throws itself away to call its ruler from the Deck. The rulers come back from the Graveyard by banishing their own kind, and two of them make a Rank 7."},
	{"key": "deck_dd", "art": "arcane", "cover": "D.D.M. - Different Dimension Master", "color": Color("5a6ad8"), "era": "Duel Monsters", "blurb": "Send monsters across to the other dimension, yours and theirs, then bring your own back stronger. D.D. Survivor and D.D.R. never stay gone for long."},
	{"key": "deck_goblin", "art": "wild", "cover": "Goblin Elite Attack Force", "color": Color("6a9a3a"), "era": "Duel Monsters", "blurb": "Big hits from small goblins. The Attack Forces swing for 2200 and then rest, so the rest of the gang keeps the field busy while they get up again."},
	{"key": "deck_mask", "art": "shadow", "cover": "The Masked Beast", "color": Color("8a3a5a"), "era": "Duel Monsters", "blurb": "Curses and masks wear the other side down while you ready the ritual. When the Masked Beast rises, Des Gardius waits behind it to take whatever is left."},
	{"key": "deck_toy", "art": "arcane", "cover": "Puppet King", "color": Color("d87a3a"), "era": "Duel Monsters", "blurb": "The Toys hide face-down as Spells and jump out when they're needed, the Toy Box sets them up, and the Puppet King comes back every time he falls."},
	{"key": "deck_barrier", "art": "arcane", "cover": "Splendid Venus", "color": Color("e0d070"), "era": "GX", "blurb": "A Barrier Statue shuts out a whole Attribute, and every Counter Trap you chain lets a Counter Fairy draw, destroy or come back. Say no to everything."},
	{"key": "deck_frog", "art": "tide", "cover": "The Great Emperor Penguin", "color": Color("4ab08a"), "era": "GX", "blurb": "Swap Frog and Ronintoadin keep the pond full, Dupe Frog takes the hits, and the Penguins flip up to bounce whatever comes too close."},
	{"key": "deck_rock", "art": "wild", "cover": "Gigantes", "color": Color("a08060"), "era": "Duel Monsters", "blurb": "Golems, sphinxes and stone giants that shrug off attacks and grind the other side down. Slow, heavy and very hard to move."},
	{"key": "deck_insect", "art": "forest", "cover": "Chainsaw Insect", "color": Color("7ab040"), "era": "GX", "blurb": "Mantises, beetles and swarms that come in numbers. Chainsaw Insect hits hard, the swarms clear the way, and the bugs keep coming."},
	{"key": "deck_zombie", "art": "shadow", "cover": "Lich Lord, King of the Underworld", "color": Color("5a7a5a"), "era": "GX", "blurb": "The dead don't stay down. Zombie World and Book of Life bring them back, Mezuki and the Pyramid Turtle dig them up, and the mummies just keep walking."},
	{"key": "deck_machina", "art": "machines", "cover": "Machina Force", "color": Color("8a9ab0"), "era": "Duel Monsters", "blurb": "The Machina soldiers and the Machine Kings, the old cannons and robots of the arcade. Line up three Machina and they build Machina Force."},
	{"key": "deck_worm", "art": "wild", "cover": "Worm King", "color": Color("8ab060"), "era": "5D's", "blurb": "Flip the Worms face-up one after another: each one sets up the next, and the King and Queen come down when the field is full of them."},
	{"key": "deck_swarm", "art": "shadow", "cover": "Evilswarm Ophion", "color": Color("6a4a7a"), "era": "5D's", "blurb": "Line up two Level 4 Evilswarm and overlay them. Ophion locks out big monsters, Bahamut steals the field, and the Infestation traps keep the swarm coming back."},
	{"key": "deck_vylon", "art": "machines", "cover": "Vylon Omega", "color": Color("e0e8ff"), "era": "5D's", "blurb": "Tune a Vylon, Synchro Summon, and every Vylon that leaves the field brings an Equip Spell with it. The more equips you stack, the stronger they get."},
	{"key": "deck_gishki", "art": "tide", "cover": "Evigishki Gustkraken", "color": Color("3a7ad8"), "era": "5D's", "blurb": "The Gishki find the ritual and the monster, the Aquamirror brings them across, and Gustkraken looks at the other side's hand before it sends it away."},
	{"key": "deck_watt", "art": "arcane", "cover": "Wattaildragon", "color": Color("f0d040"), "era": "5D's", "blurb": "Small Watt monsters that hit the other duelist directly and get a reward each time. Keep the current flowing and Wattchimera never stops."},
	{"key": "deck_laval", "art": "wild", "cover": "Laval Stennon", "color": Color("e04a2a"), "era": "5D's", "blurb": "Fill the Graveyard with Laval and the ones on the field burn hotter. The Volcano Handmaiden sends more down and the Synchros finish the job."},
	{"key": "deck_ally_justice", "art": "machines", "cover": "Ally of Justice Decisive Armor", "color": Color("a0a0b0"), "era": "5D's", "blurb": "Machines that punish LIGHT monsters: they destroy them in battle, take their attacks, and tune into Synchros that lock them out."},
	{"key": "deck_flamvell", "art": "wild", "cover": "Ancient Flamvell Deity", "color": Color("ff7a3a"), "era": "5D's", "blurb": "Small FIRE monsters that search each other out and tune into the Ancient Flamvell Deity, while the Neo Flamvell banish whatever the other side wanted back."},
	{"key": "deck_reptilianne", "art": "wild", "cover": "Reptilianne Vaskii", "color": Color("6aa04a"), "era": "5D's", "blurb": "Drop their monsters to 0 ATK and they're easy prey. Gorgon and Scylla bring the stone, Vaskii comes out when the field is full of statues."},
	{"key": "deck_evol", "art": "wild", "cover": "Evolzar Solda", "color": Color("d86a3a"), "era": "ZEXAL", "blurb": "Flip an Evoltile and it calls an Evolsaur from the Deck. Two of those make an Evolzar, and the Evolzar stop Summons and traps cold."},
	{"key": "deck_phantom_beast", "art": "machines", "cover": "Mecha Phantom Beast Dracossack", "color": Color("5a8ab0"), "era": "ZEXAL", "blurb": "Every Mecha Phantom Beast makes a Hamstrat Token or two. The Tokens keep them alive, raise their Levels and become Xyz material for Dracossack."},
	{"key": "deck_noble_knight", "art": "warriors", "cover": "Artorigus, King of the Noble Knights", "color": Color("c0a050"), "era": "ZEXAL", "blurb": "Each Noble Knight picks up a Noble Arms and passes it on. Two of them at Level 4 call the King to the table."},
	{"key": "deck_gears", "art": "machines", "cover": "Superdreadnought Rail Cannon Gustav Max", "color": Color("8a8aa0"), "era": "ZEXAL", "blurb": "The Geargia flip and search each other into a Rank 3, and when the big trains roll in, two Level 10s make a Rail Cannon."},
	{"key": "deck_inzektor", "art": "forest", "cover": "Inzektor Exa-Beetle", "color": Color("4a8a3a"), "era": "ZEXAL", "blurb": "Dragonfly and Centipede equip Hornet and Ladybug, then send them off to destroy a card. Every swap is another card gone from the other side."},
	{"key": "deck_hazy", "art": "wild", "cover": "Fire King High Avatar Garunix", "color": Color("ff6a2a"), "era": "ZEXAL", "blurb": "Level 6 Hazy Flames nobody can target, and Fire King Avatars that destroy a card of their own to come back from the flames."},
	{"key": "deck_hieratic", "art": "dragons", "cover": "Hieratic Sun Dragon Overlord of Heliopolis", "color": Color("e0c060"), "era": "ZEXAL", "blurb": "Tribute a Hieratic and it pulls a Dragon Normal Monster out of the Deck with its ATK and DEF at 0. Pile them up into Atum and Heliopolis."},
	{"key": "deck_artifact", "art": "arcane", "cover": "Artifact Moralltach", "color": Color("a0b0d0"), "era": "ZEXAL", "blurb": "Set the Artifacts in the Spell & Trap Zone and wait. When the other duelist destroys one on their turn, it jumps out and strikes back."},
	{"key": "deck_heraldic", "art": "arcane", "cover": "Number 69: Heraldry Crest", "color": Color("8a5ac0"), "era": "ZEXAL", "blurb": "Level 4 beasts that call each other and turn into Heraldry Numbers. Heraldry Crest takes the other side's effects for its own."},
	{"key": "deck_sylvan", "art": "forest", "cover": "Orea, the Sylvan High Arbiter", "color": Color("5aa04a"), "era": "ZEXAL", "blurb": "Excavate the top of the Deck: every Plant that gets sent to the Graveyard sets off a Sylvan's effect, and the big trees grow out of what's left."},
	{"key": "deck_branded", "worlds": ["heartland"], "stage": 6, "art": "dragons", "cover": "Fallen of Albaz", "color": Color("c86a3a"), "era": "", "blurb": "Fallen of Albaz fuses with whatever stands across from it. Branded Fusion pulls two cards straight from the Deck, and every Fusion that leaves the field brings the next Branded card with it."},
	{"key": "deck_drytron", "worlds": ["heartland"], "stage": 6, "art": "machines", "cover": "Drytron Meteonis Draconids", "color": Color("8ab4ff"), "era": "", "blurb": "The Drytron are Rituals with no Ritual Spell needed: they Tribute each other from the hand to come out, and Meteonis Drytron calls the Level 12 Draconids down on top of them."},
	{"key": "deck_dragonmaid", "worlds": ["heartland"], "stage": 6, "art": "dragons", "cover": "House Dragonmaid", "color": Color("7ad0c0"), "era": "", "blurb": "Maids by day, dragons when it matters. Each little Dragonmaid trades places with its big dragon form at the end of the Battle Phase, and House Dragonmaid keeps them coming."},
	{"key": "deck_swordsoul", "worlds": ["heartland"], "stage": 6, "art": "warriors", "cover": "Swordsoul Grandmaster - Chixiao", "color": Color("5ac0a0"), "era": "", "blurb": "Every Swordsoul makes a Wyrm Token tuner as it lands, so one card is already a Synchro Summon. Chixiao searches the next one and Chengying banishes whatever is in the way."},
	{"key": "deck_witchcrafter", "worlds": ["heartland"], "stage": 6, "art": "arcane", "cover": "Witchcrafter Madame Verre", "color": Color("c890e0"), "era": "", "blurb": "The Witchcrafters pay for their magic by discarding Spells, and every Witchcrafter Spell comes back from the Graveyard at the End Phase. Madame Verre wins the fights the others start."},
	{"key": "deck_true_draco", "worlds": ["heartland"], "stage": 6, "art": "dragons", "cover": "Master Peace, the True Dracoslayer", "color": Color("d0a040"), "era": "", "blurb": "Big Wyrms that Tribute Summon fast. The True Dracos get stronger the more Continuous Spells and Traps you Tribute for them, and the True Kings come out of the hand by destroying cards."},
	{"key": "deck_cipher", "worlds": ["heartland"], "stage": 6, "art": "machines", "cover": "Galaxy-Eyes Cipher Dragon", "color": Color("6a9aff"), "era": "", "blurb": "Two Level 4 Ciphers make Galaxy-Eyes Cipher Dragon, the same dragon Kite flies. It takes control of the other side's best monster, and the Cipher spells and traps rank it up."},
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
const SERIES := ["Duel Monsters", "GX", "5D's", "ZEXAL", "Vault", "legends", "frontier"]
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
	"chaos": {"era": "Duel Monsters", "deck": "deck_chaos", "cards": ["Black Luster Soldier", "Black Luster Soldier - Envoy of the Beginning", "Black Luster Soldier - Envoy of the Evening Twilight", "Black Luster Soldier - Legendary Swordsman", "Black Luster Soldier - Sacred Soldier", "Black Luster Soldier - Super Soldier", "Black Luster Ritual", "Super Soldier Ritual", "Super Soldier Rebirth", "Super Soldier Shield", "Super Soldier Soul", "Super Soldier Synthesis", "Beginning Knight", "Evening Twilight Knight", "Chaos Form", "Envoy of Chaos", "Gateway to Chaos", "Beginning of Heaven and Earth", "Chaos Sorcerer", "Dark Magician of Chaos", "Chaos Emperor Dragon - Envoy of the End", "Chaos Valkyria", "Chaos Hunter", "Chaos Betrayer", "Chaos Daedalus", "Chaos Dragon Levianeer", "Chaos End", "Chaos Greed", "Chaos Space", "Gaia The Fierce Knight", "Gaia the Dragon Champion", "Arisen Gaia the Fierce Knight", "Charging Gaia the Fierce Knight", "Lord Gaia the Fierce Knight", "Soldier Gaia the Fierce Knight", "Swift Gaia the Fierce Knight", "Gaia the Fierce Knight Origin", "Gaia the Magical Knight", "Gaia, the Mid-Knight Sun", "Gaia, the Polar Knight", "Sky Galloping Gaia the Dragon Champion", "Gaia the Magical Knight of Dragons", "Galloping Gaia", "Dragon Master Knight", "Dragon Master Magia", "Master of Chaos", "Magician of Black Chaos", "Magician of Black Chaos MAX", "Magician of Chaos", "Blue-Eyes Chaos Dragon", "Blue-Eyes Chaos MAX Dragon", "Five-Headed Dragon", "Curse of Dragon", "Spiral Spear Strike", "Spiral Discharge", "Illusion of Chaos", "Heart of Gaia", "Artillery Catapult Turtle", "Skilled Blue Magician", "Light and Darkness Ritual", "Black Luster Soldier - Soldier of Light and Darkness", "Magician of Dark Chaos - Black Chaos", "Black Chaos", "Chaos Magical Hats", "Skull Archfiend of Chaos", "Mind Shuffle", "Celtic Mystic", "Chaos Mystic Box", "Griffoh",
		"Chaos Angel", "Chaos Beast", "Chaos Core", "Chaos Grepher", "Chaos Mirage Dragon", "Chaos Nephthys", "Chaos Phantasm", "Chaos Ruler, the Chaotic Magical Dragon", "Chaos Summoning Beast", "Chaos Witch", "Core of Chaos", "Curse of Dragon, the Cursed Dragon", "Curse of Dragon, the Magical Knight Dragon", "Eternal Chaos", "Gaia Blaze, the Force of the Sun", "Gaia Prominence, the Fierce Force", "Gaiarmor Dragonshell", "Shell of Chaos", "Spiral Fusion", "Spiral Reborn", "Tachyon Spiral Galaxy", "Tachyon Spiral of Destruction", "The Chaos Creator"]},
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
		"Swift Samurai Storm!", "Swiftstrike Armor", "Shadow of the Six Samurai - Shien"]},
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
		"Number 102: Star Seraph Sentry", "Number C102: Archfiend Seraph",
		"Contract with the Void", "Fiendish Golem", "Infernity Conjurer", "Infernity Paranoia", "Infernity Patriarch", "Infernity Pawn", "Infernity Queen", "King Scarlet", "Red Cocoon", "Red Supremacy", "Red Zone", "This Creepy Little Punk", "Void Cauldron",
		"Crimson Blade Dragon", "The Crimson King", "Power Vice Dragon", "Red Nova Dragon - Burning Soul", "Champion's Pulse", "Crimson Call", "Fiend Piece Golem", "King's Resonance", "Soul Fist"]},
	"genex": {"era": "5D's", "deck": "deck_genex", "cards": [
		"Genex Power Planner", "Genex Recycled", "R-Genex Oracle", "Genex Ally Chemistrer", "Genex Ally Solid", "R-Genex Crusher", "R-Genex Overseer",
		"R-Genex Turing", "Genex Ally Birdman", "Genex Ally Changer", "Genex Ally Remote", "Genex Controller", "Genex Doctor", "Genex Gaia", "Genex Spare",
		"Genex Undine", "Genex Worker", "R-Genex Magma", "Genex Ally Bellflame", "Genex Ally Crusher", "Genex Ally Duradark", "Genex Ally Powercell",
		"Genex Ally Volcannon", "Genex Blastfan", "Genex Neutron", "Genex Searcher", "Genex Turbine", "R-Genex Accelerator", "R-Genex Turbo",
		"R-Genex Ultimum", "R-Genex Undine", "Genex Ally Reliever", "Genex Furnace", "Genex Army", "Genex Solar", "Arms of Genex Return Zero",
		"Genex Ally Axel", "Genex Ally Triarm", "Genex Ally Triforce", "Geo Genex", "Hydro Genex", "Locomotion R-Genex", "Thermal Genex",
		"Vindikite R-Genex", "Windmill Genex"]},
	"madolche": {"era": "ZEXAL", "deck": "deck_madolche", "cards": [
		"Madolche Baaple", "Madolche Chickolates", "Madolche Cruffssant", "Madolche Hootcake", "Madolche Mewfeuille", "Madolche Anjelly",
		"Madolche Butlerusk", "Madolche Chouxvalier", "Madolche Magileine", "Madolche Marmalmaide", "Madolche Messengelato", "Madolche Petingcessoeur",
		"Madolche Puddingcess", "Madolche Chateau", "Madolche Salon", "Madolche Ticket", "Madolche Dessert", "Madolche Lesson", "Madolche Nights",
		"Madolche Promenade", "Madolche Tea Break", "Madolche Waltz", "Madolchepalooza", "Madolche Puddingcess Chocolat-a-la-Mode",
		"Madolche Queen Tiarafraise", "Madolche Queen Tiaramisu", "Madolche Teacher Glassouffle"]},
	"toon": {"era": "Duel Monsters", "deck": "deck_toon", "cards": [
		"Blue-Eyes Toon Ultimate Dragon", "Comic Cat", "Dark-Eyes Illusionist Faceless Mage", "Funny Dark Rabbit", "Toon Alligator", "Toon Cannon Soldier",
		"Toon Gemini Elf", "Toon Goblin Attack Force", "Toon Harpie Lady", "Toon Masked Sorcerer", "Toon Mermaid", "Toon Cyber Dragon", "Evil Box",
		"Toon Dark Magician Girl", "Toon Summoned Skull", "Manga Ryu-Ran", "Red-Eyes Toon Dragon", "Toon Barrel Dragon", "Toon Buster Blader",
		"Toon Dark Magician", "Blue-Eyes Toon Dragon", "Toon Ancient Gear Golem", "Toon Black Luster Soldier", "Comic Hand", "Mimicat", "Shadow Toon",
		"Toon Bookmark", "Toon Kingdom", "Toon Page-Flip", "Toon Rollback", "Toon Table of Contents", "Toon World", "Toon World the Perfect World",
		"Mind Scan", "Toon Briefcase", "Toon Defense", "Toon Mask", "Toon Terror"]},
	"gladiator": {"era": "GX", "deck": "deck_gladiator", "cards": [
		"Gladiator Beast Andabata", "Gladiator Beast Claudius", "Gladiator Beast Domitianus", "Gladiator Beast Essedarii", "Gladiator Beast Gaiodiaz",
		"Gladiator Beast Gyzarus", "Gladiator Beast Heraklinos", "Gladiator Beast Nerokius", "Gladiator Beast Tamer Editor", "Test Ape",
		"Gladiator Beast Gistel", "Gladiator Beast Murmillo", "Gladiator Beast Retiari", "Gladiator Beast Sagittarii", "Gladiator Beast Samnite",
		"Gladiator Beast Torax", "Test Tiger", "Gladiator Beast Andal", "Gladiator Beast Attorix", "Gladiator Beast Bestiari", "Gladiator Beast Darius",
		"Gladiator Beast Dimacari", "Gladiator Beast Equeste", "Gladiator Beast Hoplomus", "Gladiator Beast Lanista", "Gladiator Beast Laquari",
		"Gladiator Beast Secutor", "Gladiator Beast Tygerius", "Test Bear", "Gladiator Beast Noxious", "Gladiator Beast Spartacus",
		"Gladiator Beast Alexander", "Gladiator Beast Octavius", "Gladiator Beast Vespasius", "Gladiator Beast Augustus",
		"Colosseum - Cage of the Gladiator Beasts", "Flavian - Colosseum of the Gladiator Beasts", "Gladiator Beast United",
		"Gladiator Beast's Battle Archfiend Shield", "Gladiator Beast's Battle Gladius", "Gladiator Beast's Battle Halberd",
		"Gladiator Beast's Battle Manica", "Gladiator Beast's Comeback", "Gladiator Beast's Respite", "Gladiator Proving Ground", "Gladiator Rejection",
		"Gladiator Taming", "Gladiator's Return", "Indomitable Gladiator Beast", "Defensive Tactics", "Disarm", "Double Tag Team",
		"Gladiator Beast Charge", "Gladiator Beast War Chariot", "Gladiator Lash", "Gladiator Naumachia", "Parry", "Trojan Gladiator Beast"]},
	"dragunity": {"era": "5D's", "deck": "deck_dragunity", "cards": [
		"Dragunity Brandistock", "Dragunity Corsesca", "Dragunity Tribus", "Dragunity Arma Gram", "Dragunity Aklys", "Dragunity Couse",
		"Dragunity Falchion", "Dragunity Javelin", "Dragunity Partisan", "Dragunity Phalanx", "Dragunity Remus", "Dragunity Darkspear",
		"Dragunity Guisarme", "Dragunity Legionnaire", "Dragunity Pilum", "Dragunity Dux", "Dragunity Legatus", "Dragunity Militum", "Dragunity Quirinus",
		"Dragunity Senatus", "Dragunity Angusticlavii", "Dragunity Primus Pilus", "Dragunity Arma Mystletainn", "Dragunity Arma Leyvaten",
		"Dragon Mastery", "Dragon Ravine", "Dragunity Divine Lance", "Dragunity Divine Wind", "Dragunity Draft", "Dragunity Glow", "Dragunity Whirlwind",
		"Dragunity Knight - Areadbhair", "Dragunity Knight - Areus", "Dragunity Knight - Ascalon", "Dragunity Knight - Barcha",
		"Dragunity Knight - Gae Bulg", "Dragunity Knight - Gae Dearg", "Dragunity Knight - Gormfaobhar", "Dragunity Knight - Luin",
		"Dragunity Knight - Trident", "Dragunity Knight - Vajrayana", "Dragunity Legion", "Dragunity Oubliette"]},
	"heroic": {"era": "ZEXAL", "deck": "deck_heroic", "cards": [
		"Heroic Challenger - Ambush Soldier", "Heroic Challenger - Clasp Sword", "Heroic Challenger - Knuckle Sword",
		"Heroic Challenger - Assault Halberd", "Heroic Challenger - Double Lance", "Heroic Challenger - Extra Sword", "Heroic Challenger - Morning Star",
		"Heroic Challenger - Night Watchman", "Heroic Challenger - Spartan", "Heroic Challenger - Swordshield", "Heroic Challenger - Thousand Blades",
		"Heroic Challenger - War Hammer", "Heroic Call", "Heroic Chance", "Heroic Envoy", "Heroic Advance", "Heroic Gift", "Heroic Retribution Sword",
		"Heroic Champion - Claivesolish", "Heroic Champion - Excalibur", "Heroic Champion - Gandiva", "Heroic Champion - Jarngreipr",
		"Heroic Champion - Kusanagi", "Heroic Champion - Magnum Excalibur", "Number 86: Heroic Champion - Rhongomyniad"]},
	"amazoness": {"era": "Duel Monsters", "deck": "deck_amazoness", "cards": [
		"Amazoness Augusta", "Amazoness Empress", "Amazoness Pet Liger", "Amazoness Pet Liger King", "Amazoness Baby Tiger", "Amazoness Scouts",
		"Amazoness Spiritualist", "Amazoness Blowpiper", "Amazoness Princess", "Amazoness Spy", "Dark Scorpion - Chick the Yellow",
		"Dark Scorpion - Cliff the Trap Remover", "Amazoness Archer", "Amazoness Chain Master", "Amazoness Fighter", "Amazoness Paladin", "Amazoness Sage",
		"Amazoness Swords Woman", "Amazoness Tiger", "Amazoness Trainee", "Dark Scorpion - Meanae the Thorn", "Dark Scorpion Burglars", "Don Zaloog",
		"Amazoness War Chief", "Dark Scorpion - Gorg the Strong", "Amazoness Queen", "Amazoness Call", "Amazoness Fighting Spirit", "Amazoness Heirloom",
		"Amazoness Secret Arts", "Amazoness Spellcaster", "Amazoness Village", "Mustering of the Dark Scorpions", "Amazoness Archers", "Amazoness Hall",
		"Amazoness Hot Spring", "Amazoness Onslaught", "Amazoness Shamanism", "Amazoness Willpower", "Dark Scorpion Combination", "Dramatic Rescue",
		"Queen's Pawn"]},
	"crystal_beast": {"era": "GX", "deck": "deck_crystal_beast", "cards": [
		"Rainbow Neos", "Rainbow Overdragon", "Ultimate Crystal Rainbow Dragon Overdrive", "Malefic Rainbow Dragon", "Rainbow Dark Dragon",
		"Rainbow Dragon", "Advanced Crystal Beast Amethyst Cat", "Advanced Crystal Beast Emerald Tortoise", "Advanced Crystal Beast Ruby Carbuncle",
		"Crystal Beast Amethyst Cat", "Crystal Beast Emerald Tortoise", "Crystal Beast Ruby Carbuncle", "Advanced Crystal Beast Amber Mammoth",
		"Advanced Crystal Beast Cobalt Eagle", "Advanced Crystal Beast Sapphire Pegasus", "Advanced Crystal Beast Topaz Tiger",
		"Crystal Beast Amber Mammoth", "Crystal Beast Cobalt Eagle", "Crystal Beast Sapphire Pegasus", "Crystal Beast Topaz Tiger",
		"Crystal Beast Rainbow Dragon", "Advanced Dark", "Ancient City - Rainbow Ruins", "Awakening of the Crystal Ultimates", "Crystal Abundance",
		"Crystal Aegis", "Crystal Beacon", "Crystal Blessing", "Crystal Bond", "Crystal Promise", "Crystal Release", "Crystal Tree", "Golden Rule",
		"Rainbow Bridge of the Heart", "Rainbow Refraction", "Rare Value", "Counter Gem", "Crystal Boon", "Crystal Brilliance", "Crystal Conclave",
		"Crystal Miracle", "Crystal Pair", "Crystal Raigeki", "Rainbow Bridge of Salvation", "Rainbow Gravity", "Rainbow Path", "Ultimate Crystal Magic"]},
	"vampire": {"era": "GX", "deck": "deck_vampire", "cards": [
		"Vampire Familiar", "Vampire Retainer", "Vampire Baby", "Vampire Ghost", "Vampire Hunter", "Vampire Lady", "Vampire Sorcerer", "Shadow Vampire",
		"Vampire Dragon", "Vampire Duke", "Vampire Fraulein", "Vampire Grimson", "Vampire Lord", "Vampire Grace", "Vampire Red Baron",
		"Vampire Scarlet Scourge", "Vampire's Curse", "Vampire Vamp", "Vampire Genesis", "Vampire Voivode", "Vampire Kingdom", "Vampire's Desire",
		"Vampire's Domain", "Vampire Awakening", "Vampire Domination", "Vampire Takeover", "Crimson Knight Vampire Bram", "Dhampir Vampire Sheridan",
		"The Zombie Vampire"]},
	"morphtronic": {"era": "5D's", "deck": "deck_morphtronic", "cards": [
		"Gadget Driver", "Morphtronic Celfon", "Morphtronic Lantron", "Morphtronic Magnen Bar", "Morphtronic Smartfon", "Morphtronic Telefon",
		"Morphtronic Vacuumen", "Gadget Arms", "Morphtronic Cameran", "Morphtronic Clocken", "Gadget Gamer", "Morphtronic Boarden", "Morphtronic Datatron",
		"Morphtronic Magnen", "Morphtronic Remoten", "Morphtronic Scopen", "Morphtronic Boomboxen", "Morphtronic Radion", "Morphtronic Slingen",
		"Morphtronic Staplen", "Morphtronic Videon", "Gadget Hauler", "Morphtronic Scannen", "Double Tool C&D", "Factory of 100 Machines", "Gadget Box",
		"Junk Box", "Morphtronic Accelerator", "Morphtronic Converter", "Morphtronic Cord", "Morphtronic Engine", "Morphtronic Map",
		"Morphtronic Repair Unit", "Morphtronic Rusty Engine", "Morphtronic Earfon", "Power Tool Dragon", "Morphtransition", "Morphtronic Bind",
		"Morphtronic Forcefield", "Morphtronic Impact Return", "Morphtronic Mix-up", "Morphtronic Monitron", "Morphtronics, Scramble!", "Power-Up Adapter",
		"Power Tool Braver Dragon"]},
	"scrap": {"era": "5D's", "deck": "deck_scrap", "cards": [
		"Scrap Mind Reader", "Scrap Searcher", "Scrap Synchron", "Scrap Worm", "Scrap Goblin", "Scrap Hunter", "Scrap Recycler", "Scrap Beast",
		"Scrap Chimera", "Scrap Kong", "Scrap Orthros", "Scrap Raptor", "Scrap Shark", "Scrap Golem", "Scrap Soldier", "Scrap Breaker", "Guts of Steel",
		"Scrap Factory", "Scrap Fist", "Scrap Lube", "Scrap Sheen", "Scrapstorm", "Scrapyard", "Atomic Scrap Dragon", "Scrap Archfiend", "Scrap Dragon",
		"Scrap Twin Dragon", "Scrap Warrior", "Scrap Crash", "Scrap Garage", "Scrap Rage"]},
	"chronomaly": {"era": "ZEXAL", "deck": "deck_chronomaly", "cards": [
		"Chronomaly Crystal Bones", "Chronomaly Crystal Skull", "Chronomaly Gordian Knot", "Chronomaly Mayan Machine", "Chronomaly Aztec Mask Golem",
		"Chronomaly Cabrera Trebuchet", "Chronomaly Colossal Head", "Chronomaly Golden Jet", "Chronomaly Magella Globe", "Chronomaly Mud Golem",
		"Chronomaly Nebra Disk", "Chronomaly Tuspa Rocket", "Chronomaly Acambaro Figures", "Chronomaly Moai", "Chronomaly Moai Carrier",
		"Chronomaly Tula Guardian", "Chronomaly Winged Sphinx", "Chronomaly Sol Monolith", "Chronomaly City Babylon", "Chronomaly Pyramid Eye Tablet",
		"Chronomaly Technology", "Chronomaly Temple - Trilithon", "Chronomaly Esperanza Glyph", "Stonehenge Methods", "Chronomaly Crystal Chrononaut",
		"Chronomaly Vimana", "Number 33: Chronomaly Machu Mech", "Number 36: Chronomaly Chateau Huyuk", "Number 6: Chronomaly Atlandis",
		"Number C6: Chronomaly Chaos Atlandis"]},
	"guardian": {"era": "Duel Monsters", "deck": "deck_guardian", "cards": [
		"Gate Guardian of Thunder and Wind", "Gate Guardian of Water and Thunder", "Gate Guardian of Wind and Water", "Gate Guardians Combined",
		"Gate Guardian", "Dark Guardian", "Guardian Elma", "Guardian Baou", "Guardian Ceal", "Guardian Kay'est", "Guardian Grarl", "Guardian Tryce",
		"Kazejin", "Labyrinth Heavy Tank", "Sanga of the Thunder", "Suijin", "Guardian Dreadscythe", "Guardian Eatos", "Butterfly Dagger - Elma",
		"Celestial Sword - Eatos", "Dark Element", "Double Attack! Wind and Thunder!!", "Gravity Axe - Grarl", "Labyrinth Wall Shadow",
		"Power of the Guardians", "Reaper Scythe - Dreadscythe", "Riryoku Guardian", "Rod of Silence - Kay'est", "Shooting Star Bow - Ceal",
		"Twin Swords of Flashing Light - Tryce", "Wicked-Breaking Flamberge - Baou", "Prey of the Jirai Gumo"]},
	"alien": {"era": "GX", "deck": "deck_alien", "cards": [
		"Alien Ammonite", "Alien Psychic", "Alien Grey", "Alien Infiltrator", "Alien Dog", "Alien Mars", "Alien Hunter", "Alien Hypno", "Alien Kid",
		"Alien Shocktrooper", "Alien Skull", "Alien Stealthbuster", "Alien Telepath", "Alien Warrior", "I.A.S. -Invasive Alien Species-",
		"Flying Saucer Muusik'i", "Alien Mother", "Alien Overlord", "Cosmic Horror Gangi'el", "\"A\" Cell Breeding Device", "\"A\" Cell Incubator",
		"\"A\" Cell Recombination Device", "\"A\" Cell Scatter Burst", "Code A Ancient Ruins", "Corruption Cell \"A\"", "Mysterious Triangle",
		"Otherworld - The \"A\" Zone", "Cosmic Fortress Gol'gar", "Alien Brain", "Brainwashing Beam", "Cell Explosion Virus", "Crop Circles",
		"Detonator Circle \"A\"", "Interdimensional Warp", "Mass Hypnosis", "Orbital Bombardment", "Planet Pollutant Virus"]},
	"volcanic": {"era": "GX", "deck": "deck_volcanic", "cards": [
		"Volcanic Rat", "Volcanic Rimfire", "Volcanic Shell", "Volcanic Scattershot", "Volcanic Blaster", "Volcanic Counter", "Volcanic Trooper",
		"Volcanic Rocket", "Volcanic Slicer", "Volcanic Hammerer", "Volcanic Queen", "Volcanic Doomfire", "Volcanic Emperor", "Blaze Accelerator",
		"Fire Ejection", "Tri-Blaze Accelerator", "Volcanic Blaze Accelerator", "Blaze Accelerator Reload", "Volcanic Emission", "Volcanic Eruption",
		"Volcanic Inferno", "Volcanic Recharge"]},
	"x_saber": {"era": "5D's", "deck": "deck_x_saber", "cards": [
		"X-Saber Axel", "X-Saber Palomuro", "XX-Saber Ragigura", "X-Saber Pashuul", "X-Saber Airbellum", "X-Saber Bruno", "XX-Saber Darksoul",
		"XX-Saber Emmersblade", "XX-Saber Fulhelmknight", "X-Saber Anu Piranha", "X-Saber Galahad", "X-Saber Pellina", "X-Saber Uruz",
		"XX-Saber Boggart Knight", "XX-Saber Garsem", "XX-Saber Gardestrike", "Commander Gottoms, Swordmaster", "XX-Saber Faultroll",
		"Gottoms' Second Call", "Saber Combination", "Saber Reflection", "Saber Slash", "Saber Vault", "Sword of Sparkles", "Commander Souza, Swordmaster",
		"X-Saber Gottoms", "X-Saber Souza", "X-Saber Urbellum", "X-Saber Wayne", "XX-Saber Gottoms", "XX-Saber Hyunlei", "At One With the Sword",
		"Gottoms' Emergency Call", "Saber Hole", "M-X-Saber Invoker"]},
	"gimmick_puppet": {"era": "ZEXAL", "deck": "deck_gimmick_puppet", "cards": [
		"Gimmick Puppet Gear Changer", "Gimmick Puppet Des Troy", "Gimmick Puppet Egg Head", "Gimmick Puppet Fiendish Knight",
		"Gimmick Puppet Humpty Dumpty", "Gimmick Puppet Little Soldiers", "Gimmick Puppet Scissor Arms", "Gimmick Puppet Terror Baby",
		"Gimmick Puppet Bisque Doll", "Gimmick Puppet Cattle Scream", "Gimmick Puppet Dreary Doll", "Gimmick Puppet Magnet Doll",
		"Gimmick Puppet Nightmare", "Gimmick Puppet Rouge Doll", "Gimmick Puppet Shadow Feeler", "Gimmick Puppet Twilight Joker", "Condolence Puppet",
		"Junk Puppet", "Mansion of the Dreadful Dolls", "Perform Puppet", "Puppet Ritual", "Puppet Parade", "Service Puppet Play",
		"CXyz Gimmick Puppet Fanatix Machinix", "Gimmick Puppet Fantasix Machinix", "Gimmick Puppet Gigantes Doll",
		"Number 15: Gimmick Puppet Giant Grinder", "Number 40: Gimmick Puppet of Strings", "Number 88: Gimmick Puppet of Leo",
		"Number C15: Gimmick Puppet Giant Hunter", "Number C40: Gimmick Puppet of Dark Strings", "Number C88: Gimmick Puppet Disaster Leo"]},
	"battlin_boxer": {"era": "ZEXAL", "deck": "deck_battlin_boxer", "cards": [
		"Battlin' Boxer Big Bandage", "Battlin' Boxer Counterpunch", "Battlin' Boxer Rabbit Puncher", "Battlin' Boxer Rib Gardna",
		"Battlin' Boxer Chief Second", "Battlin' Boxer Glassjaw", "Battlin' Boxer Headgeared", "Battlin' Boxer Promoter", "Battlin' Boxer Shadow",
		"Battlin' Boxer Sparrer", "Battlin' Boxer Switchitter", "Battlin' Boxer Uppercutter", "Battlin' Boxer Veil", "Battlin' Boxing Spirits",
		"Ring Announcer", "Battlin' Boxing Cross Counter", "Jolt Counter", "Last Counter", "Battlin' Boxer Cheat Commissioner",
		"Battlin' Boxer King Dempsey", "Battlin' Boxer Lead Yoke", "Number 105: Battlin' Boxer Star Cestus", "Number 79: Battlin' Boxer Nova Kaiser",
		"Number C105: Battlin' Boxer Comet Cestus", "Number C79: Battlin' Boxer General Kaiser"]},
	"exodia": {"era": "Duel Monsters", "deck": "deck_exodia", "cards": [
		"Shining Sarcophagus",
		"The Unstoppable Exodia Incarnate", "Batteryman D", "Batteryman Micro-Cell", "Left Arm of the Forbidden One", "Left Leg of the Forbidden One",
		"Right Arm of the Forbidden One", "Right Leg of the Forbidden One", "True Exodia", "Exodia, the Legendary Defender",
		"Exodius the Ultimate Forbidden Lord", "The Legendary Exodia Incarnate", "Batteryman C", "Batteryman AA", "Exodia the Forbidden One",
		"Batteryman 9-Volt", "Batteryman AAA", "Batteryman Solar", "Boot-Up Corporal - Command Dynamo", "Boot-Up Soldier - Dread Dynamo", "Cyberse Gadget",
		"Exodia Necross", "Gadget Trio", "Gold Gadget", "Green Gadget", "Red Gadget", "Silver Gadget", "Yellow Gadget", "Batteryman Charger",
		"Batteryman Fuel Cell", "Gadget Soldier", "Batteryman Industrial Strength", "Boot-Up Admiral - Destroyer Dynamo", "Battery Charger",
		"Boot-Up Order - Gear Charge", "Contract with Exodia", "Millennium Ankh", "Obliterate!!! Blaze", "Quick Charger", "Short Circuit",
		"Break the Seal", "Exxod Fires of Rage", "Obliterate!!!", "Portable Battery Pack", "Powerhold the Moving Battery", "Stronghold the Hidden Fortress"]},
	"koaki_meiru": {"era": "GX", "deck": "deck_koaki_meiru", "cards": [
		"Koa'ki Meiru Doom", "Koa'ki Meiru Hydro Barrier", "Koa'ki Meiru Speeder", "Koa'ki Meiru Beetle", "Koa'ki Meiru Bergzak", "Koa'ki Meiru Boulder",
		"Koa'ki Meiru Crusader", "Koa'ki Meiru Drago", "Koa'ki Meiru Gravirose", "Koa'ki Meiru Guardian", "Koa'ki Meiru Ice", "Koa'ki Meiru Overload",
		"Koa'ki Meiru Powerhand", "Koa'ki Meiru Prototype", "Koa'ki Meiru Sandman", "Koa'ki Meiru Sea Panther", "Koa'ki Meiru Supplier",
		"Koa'ki Meiru Tornado", "Koa'ki Meiru Urnight", "Koa'ki Meiru Wall", "Koa'ki Meiru War Arms", "Koa'ki Meiru Ghoulungulate",
		"Koa'ki Meiru Rooklord", "Koa'ki Meiru Maximus", "Koa'ki Meiru Valafar", "Core Blaster", "Core Compression", "Core Overclock",
		"Core Transport Unit", "Diamond Core of Koa'ki Meiru", "Iron Core Armor", "Iron Core Immediate Disposal", "Iron Core Specimen Lab",
		"Iron Core of Koa'ki Meiru", "Koa'ki Meiru Initialize!", "Koa'ki Ring", "Urgent Synthesis", "Automatic Laser", "Core Blast", "Core Reinforcement",
		"Iron Core Luster", "Koa'ki Meiru Shield", "Nega-Ton Corepanel", "Reckoned Power"]},
	"arcana_force": {"era": "GX", "deck": "deck_arcana_force", "cards": [
		"Arcana Force EX - The Chaos Ruler", "Arcana Force 0 - The Fool", "Arcana Force EX - The Dark Ruler", "Arcana Force EX - The Light Ruler",
		"Arcana Force I - The Magician", "Arcana Force III - The Empress", "Arcana Force IV - The Emperor", "Arcana Force V - The Hierophant",
		"Arcana Force VI - The Lovers", "Arcana Force VII - The Chariot", "Arcana Force XII - The Hangman", "Arcana Force XIV - Temperance",
		"Arcana Force XIX - The Sun", "Arcana Force XV - The Fiend", "Arcana Force XVIII - The Moon", "Arcana Force XXI - The World", "Arcana Reading",
		"Arcana Spread", "Light Barrier", "Light Force", "Arcana Call", "Reversal of Fate"]},
	"ice_barrier": {"era": "5D's", "deck": "deck_ice_barrier", "cards": [
		"Blizzed, Defender of the Ice Barrier", "Caravan of the Ice Barrier", "Hexa Spirit of the Ice Barrier", "Cryomancer of the Ice Barrier",
		"Dewdark of the Ice Barrier", "Mirror Mage of the Ice Barrier", "Prior of the Ice Barrier", "Secret Guards of the Ice Barrier",
		"Zuijin of the Ice Barrier", "Defender of the Ice Barrier", "Geomancer of the Ice Barrier", "Shock Troops of the Ice Barrier",
		"Warlock of the Ice Barrier", "Dance Princess of the Ice Barrier", "Judge of the Ice Barrier", "Numbing Grub in the Ice Barrier",
		"Pilgrim of the Ice Barrier", "Revealer of the Ice Barrier", "Sacred Spirit of the Ice Barrier", "Samurai of the Ice Barrier",
		"Speaker for the Ice Barriers", "Spellbreaker of the Ice Barrier", "Strategist of the Ice Barrier", "General Wayne of the Ice Barrier",
		"Royal Knight of the Ice Barrier", "Dai-sojo of the Ice Barrier", "General Raiho of the Ice Barrier", "Georgius, Swordman of the Ice Barrier",
		"General Gantala of the Ice Barrier", "Medium of the Ice Barrier", "General Grunard of the Ice Barrier", "Freezing Chains of the Ice Barrier",
		"Magic Triangle of the Ice Barrier", "Medallion of the Ice Barrier", "Mirror of the Ice Barrier", "Winds Over the Ice Barrier",
		"Brionac, Dragon of the Ice Barrier", "Dewloren, Tiger King of the Ice Barrier", "Ekhajar, Descendant Dragon of the Ice Barrier",
		"Gungnir, Dragon of the Ice Barrier", "Lancea, Ancestral Dragon of the Ice Mountain", "Trishula, Dragon of the Ice Barrier",
		"Trishula, Zero Dragon of the Ice Barrier", "Frozen Domain of the Ice Barrier", "Ice Barrier", "Terror of Trishula"]},
	"ninja": {"era": "ZEXAL", "deck": "deck_ninja", "cards": [
		"Meizen the Battle Ninja", "Yaguramaru the Armor Ninja", "Armed Ninja", "Crimson Ninja", "Tobari the Sky Ninja", "Green Ninja",
		"Mitsu the Insect Ninja", "Baku the Beast Ninja", "Bat, the Forest Ninja", "Karakuri Ninja mdl 339 \"Sazank\"", "Lady Ninja Yae", "Penguin Ninja",
		"Air Armor Ninja", "Aqua Armor Ninja", "Flame Armor Ninja", "Goe Goe the Gallant Ninja", "Kagero the Cannon Ninja",
		"Karakuri Ninja mdl 919 \"Kuick\"", "Masked Ninja Ebisu", "Ninja Grandmaster Hanzo", "Ninja Grandmaster Sasuke", "Strike Ninja",
		"Twilight Ninja Shingetsu", "Upstart Golden Ninja", "White Ninja", "Yellow Ninja", "Blue Dragon Ninja", "Earth Armor Ninja",
		"Karakuri Ninja mdl 7749 \"Nanashick\"", "Red Dragon Ninja", "Senior Silver Ninja", "Twilight Ninja Nichirin, the Chunin", "Black Dragon Ninja",
		"White Dragon Ninja", "Jioh the Gravity Ninja", "Twilight Ninja Getsuga, the Shogun", "Yellow Dragon Ninja", "Fuhma Shuriken",
		"Hidden Village of Ninjitsu Arts", "Ninjitsu Art Notebook", "Ninjitsu Art Notebook of Mystery", "Ninjitsu Art Tool - Iron Digger", "Tenchi Kaimei",
		"Superheavy Samurai Ninja Sarutobi", "Superheavy Samurai Stealth Ninja", "Armor Ninjitsu Art of Freezing", "Armor Ninjitsu Art of Rust Mist",
		"Ninjitsu Art of Dancing Leaves", "Ninjitsu Art of Decoy", "Ninjitsu Art of Duplication", "Ninjitsu Art of Mirage-Transformation",
		"Ninjitsu Art of Shadow Sealing", "Ninjitsu Art of Super-Transformation", "Ninjitsu Art of Transformation", "Blade Armor Ninja",
		"Number 12: Crimson Shadow Armor Ninja", "Number 2: Ninja Shadow Mosquito"]},
	"kuriboh": {"era": "Duel Monsters", "deck": "deck_kuriboh", "cards": [
		"Conduction Warrior Plasma Magnum", "Ankuriboh", "Astral Kuriboh", "Clear Kuriboh", "Darkuriboh", "Detonating Kuriboh", "Galactikuriboh",
		"Junkuriboh", "Kuribah", "Kuribee", "Kuribeh", "Kuriboh", "Kuribohrn", "Kuriboo", "Magikuriboh", "Multiplying Kuriboh!", "Performapal Kuribohble",
		"Rainbow Kuriboh", "Relinkuriboh", "Sphere Kuriboh", "Winged Kuriboh", "Winged Kuriboh LV10", "Winged Kuriboh Sabatiel LV10", "Harpie Girl",
		"Alpha The Electromagnet Warrior", "Beta The Electromagnet Warrior", "Gamma The Electromagnet Warrior", "Kuribandit", "Alpha The Magnet Warrior",
		"Beta The Magnet Warrior", "Birdface", "Delta The Magnet Warrior", "Epsilon The Magnet Warrior", "Gamma The Magnet Warrior", "Harpie Channeler",
		"Harpie Dancer", "Harpie Harpist", "Harpie Lady", "Harpie Oracle", "Harpie Perfumer", "Harpie Queen", "Harpie's Pet Baby Dragon",
		"Magnet Warrior Omega Plus", "Magnet Warrior Sigma Minus", "Magnet Warrior Sigma Plus", "Skilled Brown Magician", "Kuribabylon",
		"Harpie Lady Sisters", "Winged Kuriboh LV6", "Conduction Warrior Linear Magnum Plus Minus", "Harpie's Pet Dragon",
		"Harpie's Pet Dragon - Fearsome Fire Blast", "Berserkion the Electromagna Warrior", "Plasma Warrior Eitom", "Tellusion the Magna Warrior",
		"Valkyrion the Magna Warrior", "Winged Kuriboh LV9", "Alluring Mirror Split", "Cyber Shield", "Detonate", "Elegant Egotist", "Five Star Twilight",
		"Generation Next", "Harpie Lady Phoenix Formation", "Harpie's Feather Duster", "Harpie's Feather Rest", "Harpies' Hunting Ground", "Hysteric Sign",
		"Magnet Bonding", "Magnet Circle LV2", "Magnet Induction", "Magnet Reverse", "Magnetic Field", "Multiply", "The Flute of Summoning Kuriboh",
		"Cyber Slash Harpie Lady", "Harpie Lady Elegance", "Harpie's Feather Storm", "Hysteric Party", "Magnet Conversion", "Magnet Force",
		"Harpie's Pet Phantasmal Dragon"]},
	"cloudian": {"era": "GX", "deck": "deck_cloudian", "cards": [
		"Rise of the Snake Deity",
		"Fossil Dragon Skullgar", "Fossil Dragon Skullgios", "Fossil Machine Skull Buggy", "Fossil Machine Skull Convoy", "Fossil Machine Skull Wagon",
		"Fossil Warrior Skull Bone", "Fossil Warrior Skull King", "Fossil Warrior Skull Knight", "Cloudian - Ghost Fog", "Cloudian - Sheep Cloud",
		"Cloudian - Smoke Ball", "Vennominaga the Deity of Poisonous Snakes", "Cloudian - Poison Cloud", "Flint Cragger", "Venom Snake",
		"Cloudian - Acid Cloud", "Cloudian - Altus", "Cloudian - Cirrostratus", "Cloudian - Storm Dragon", "Cloudian - Turbulence", "Venom Cobra",
		"Venom Serpent", "Cloudian - Nimbusman", "Venom Boa", "Cloudian - Eye of the Typhoon", "Vennominon the King of Poisonous Snakes",
		"Cloudian Aerosol", "Cloudian Squall", "Diamond-Dust Cyclone", "Fog Control", "Fossil Fusion", "Lucky Cloud", "Summon Cloud", "Time Stream",
		"Venom Shot", "Venom Swamp", "Ambush Fangs", "Natural Disaster", "Raging Cloudian", "Rain Storm", "Snake Deity's Command", "Updraft", "Venom Burn"]},
	"naturia": {"era": "5D's", "deck": "deck_naturia", "cards": [
		"Naturia Exterio", "Naturia Gaiastrio", "Naturia Cherries", "Naturia Ladybug", "Naturia Mole Cricket", "Naturia Mosquito", "Naturia Vein",
		"Naturia Antjaw", "Naturia Beans", "Naturia Cosmobeet", "Naturia Eggplant", "Naturia Pineapple", "Naturia Sunflower", "Naturia Tulip",
		"Naturia Butterfly", "Naturia Fruitfly", "Naturia Marron", "Naturia Ragweed", "Naturia Rock", "Naturia Rosewhip", "Naturia Stinkbug",
		"Naturia Beetle", "Naturia Camellia", "Naturia Cliff", "Naturia Dragonfly", "Naturia Guardian", "Naturia Horneedle", "Naturia Mantis",
		"Naturia Pumpkin", "Naturia Spiderfang", "Naturia Strawberry", "Naturia White Oak", "Naturia Bamboo Shoot", "Naturia Hydrangea",
		"Naturia Stag Beetle", "Barkion's Bark", "Landoise's Luminous Moss", "Leodrake's Mane", "Naturia Blessing", "Naturia Forest", "Naturia Barkion",
		"Naturia Beast", "Naturia Landoise", "Naturia Leodrake", "Exterio's Fang", "Naturia Sacred Tree"]},
	"tg": {"era": "5D's", "deck": "deck_tg", "cards": [
		"T.G. Booster Raptor", "T.G. Cyber Magician", "T.G. Drill Fish", "T.G. Gear Zombie", "T.G. Rocket Salamander", "T.G. Tank Grub",
		"T.G. Halberd Cannon/Assault Mode", "T.G. Catapult Dragon", "T.G. Metal Skeleton", "T.G. Striker", "T.G. Jet Falcon", "T.G. Warwolf",
		"T.G. Rush Rhino", "T.G. Screw Serpent", "T.G. All Clear", "T.G. Limiter Removal", "TGX1-HL", "TGX300", "Shooting Star Dragon T.G. EX",
		"T.G. Blade Blaster", "T.G. Glaive Blaster", "T.G. Halberd Cannon", "T.G. Hyper Librarian", "T.G. Mighty Striker", "T.G. Over Dragonar",
		"T.G. Power Gladiator", "T.G. Recipro Dragonfly", "T.G. Star Guardian", "T.G. Wonder Magician", "Sonic Stun", "T.G. Close", "TG-SX1", "TG1-EM1",
		"TGX3-DX2"]},
	"fire_fist": {"era": "ZEXAL", "deck": "deck_fire_fist", "cards": [
		"Brotherhood of the Fire Fist - Swan", "Brotherhood of the Fire Fist - Hawk", "Brotherhood of the Fire Fist - Leopard",
		"Brotherhood of the Fire Fist - Ram", "Brotherhood of the Fire Fist - Raven", "Brotherhood of the Fire Fist - Rooster",
		"Brotherhood of the Fire Fist - Spirit", "Brotherhood of the Fire Fist - Wolf", "Brotherhood of the Fire Fist - Bear",
		"Brotherhood of the Fire Fist - Boar", "Brotherhood of the Fire Fist - Buffalo", "Brotherhood of the Fire Fist - Caribou",
		"Brotherhood of the Fire Fist - Dragon", "Brotherhood of the Fire Fist - Elephant", "Brotherhood of the Fire Fist - Gorilla",
		"Brotherhood of the Fire Fist - Rhino", "Brotherhood of the Fire Fist - Snake", "Brotherhood of the Fire Fist - Coyote",
		"Brotherhood of the Fire Fist - Panda", "Brotherhood of the Fire Fist - Swallow", "Brotherhood of the Fire Fist - Eland", "Fire Formation - Domei",
		"Fire Formation - Gyokkou", "Fire Formation - Ingen", "Fire Formation - Tenki", "Fire Formation - Tensu", "Fire Formation - Yoko",
		"Fire Fortress atop Liang Peak", "Brotherhood of the Fire Fist - Horse Prince", "Brotherhood of the Fire Fist - Kirin", "Fire Formation - Kaiyo",
		"Fire Formation - Tenken", "Fire Formation - Tensen", "Ultimate Fire Formation - Seito", "Ultimate Fire Formation - Sinto",
		"Brotherhood of the Fire Fist - Cardinal", "Brotherhood of the Fire Fist - Lion Emperor", "Brotherhood of the Fire Fist - Tiger King"]},
	"dark_magician": {"era": "Duel Monsters", "deck": "deck_dark_magician", "cards": [
		"Amulet Dragon", "Dark Cavalry", "Dark Flare Knight", "Dark Magician Girl the Dragon Knight", "Dark Magician of Destruction",
		"Dark Magician the Dragon Knight", "Dark Magician the Knight of Dragon Magic", "Dark Paladin", "Red-Eyes Dark Dragoon", "The Dark Magicians",
		"Timaeus the United Magical Dragon", "Magicians' Souls", "Magician's Robe", "Magician's Rod", "Chronicle Sorceress", "Skilled Dark Magician",
		"Apprentice Illusion Magician", "Dark Magician Girl", "Dark Magician Girl the Magician's Apprentice", "Palladium Oracle Mana",
		"Chronicle Magician", "Dark Eradicator Warlock", "Dark Magician", "Dark Magician Knight", "Dark Magician the Magician of Black Magic",
		"Dark Magician, the Pharaoh's Servant", "Magician of Dark Illusion", "Palladium Oracle Mahad", "Mirage Knight", "Timaeus the United Dragon",
		"Dark Sage", "Bond Between Teacher and Student", "Dark Burning Attack", "Dark Burning Magic", "Dark Magic Attack", "Dark Magic Curtain",
		"Dark Magic Expanded", "Dark Magic Inheritance", "Dark Magic Twin Burst", "Dark Magical Circle", "Dark Magical Curtain",
		"Dedication through Light and Darkness", "Illusion Magic", "Knight's Title", "Magic Formula", "Magician's Salvation", "Sage's Stone",
		"Secrets of Dark Magic", "Soul Servant", "Strength in Unity", "The Eye of Timaeus", "The Gaze of Timaeus", "Thousand Knives",
		"Dark Magic Mirror Force", "Dark Magic Talisman", "Destined Rivals", "Eternal Soul", "Magician Navigation", "Magicians' Combination",
		"Miracle Restoring",
		"Apple Magician Girl", "Berry Magician Girl", "Chaos Scepter Blast", "Chocolate Magician Girl", "Kiwi Magician Girl", "Lemon Magician Girl"]},
	"blue_eyes": {"era": "Duel Monsters", "deck": "deck_blue_eyes", "cards": [
		"Blue-Eyes Alternative Ultimate Dragon", "Blue-Eyes Twin Burst Dragon", "Blue-Eyes Tyrant Dragon", "Blue-Eyes Ultimate Dragon",
		"Neo Blue-Eyes Ultimate Dragon", "Kaibaman the Legend", "Maiden of White", "Maiden with Eyes of Blue", "Master with Eyes of Blue",
		"Priestess with Eyes of Blue", "Protector with Eyes of Blue", "Sage with Eyes of Blue", "The White Stone of Ancients", "The White Stone of Legend",
		"Blue-Eyes Shining Dragon", "Deep-Eyes White Dragon", "Deep-Eyes White Dragon, the Blue Abyss", "Kaibaman", "Dictator of D.",
		"Neo Kaiser Sea Horse", "Blue-Eyes Abyss Dragon", "Blue-Eyes Alternative White Dragon", "Blue-Eyes Jet Dragon", "Blue-Eyes Solid Dragon",
		"Blue-Eyes White Dragon", "Blue-Eyes White Dragon, the White Phantom Beast", "Dragon Spirit of White", "Heart of the Blue-Eyes",
		"Malefic Blue-Eyes White Dragon", "Paladin of White Dragon", "Beacon of White", "Bingo Machine, Go!!!", "Burst Stream of Destruction",
		"Majesty with Eyes of Blue", "Rage with Eyes of Blue", "Roar of the Blue-Eyed Dragons", "Ultimate Fusion", "Vision with Eyes of Blue",
		"White Dragon Ritual", "Wishes for Eyes of Blue", "Blue-Eyes Spirit Dragon", "Blue-Eyes Ultimate Spirit Dragon", "Majesty of the White Dragons",
		"The Ultimate Creature of Destruction", "True Light"]},
	"red_eyes": {"era": "Duel Monsters", "deck": "deck_red_eyes", "cards": [
		"The Claw of Hermos",
		"Meteor Black Comet Dragon", "Meteor Black Dragon", "Red-Eyes Black Dragon Sword", "Red-Eyes Slash Dragon", "Black Dragon's Chick",
		"Black Metal Dragon", "The Black Stone of Legend", "Red-Eyes Darkness Metal Dragon", "Red-Eyes Baby Dragon", "Gearfried the Red-Eyes Iron Knight",
		"Red-Eyes Retro Dragon", "Red-Eyes Wyvern", "Meteor Dragon Red-Eyes Impact", "Red-Eyes Black Meteor Dragon", "Malefic Red-Eyes Black Dragon",
		"Red-Eyes Alternative Black Dragon", "Red-Eyes Black Dragon", "Red-Eyes Black Flare Dragon", "Red-Eyes Metal Claws Dragon", "Red-Eyes Soul",
		"Red-Eyes Zombie Dragon", "Red-Eyes Black Fullmetal Dragon", "Red-Eyes Black Metal Dragon", "Red-Eyes Darkness Dragon", "Lord of the Red",
		"Paladin of Dark Dragon", "Cards of the Red Stone", "Dark Dragon Ritual", "Inferno Fire Blast", "Red-Eyes Fusion", "Red-Eyes Insight",
		"Red-Eyes Transmigration", "Red-Eyes Zombie Dragon Lord", "Red-Eyes Zombie Necro Dragon", "Red-Eyes Burn", "Red-Eyes Fang with Chain",
		"Red-Eyes Spirit", "Return of the Red-Eyes", "Red-Eyes Flare Metal Dragon"]},
	"armed_dragon": {"era": "GX", "deck": "deck_armed_dragon", "cards": [
		"White Veil",
		"Armed Dragon Catapult Cannon", "Armed Neos", "Dark Mimic LV1", "Ultimate Insect LV1", "Armed Dragon LV10", "Armed Dragon LV10 White",
		"Armed Dragon Thunder LV10", "Mystic Swordsman LV2", "Allure Queen LV3", "Armed Dragon LV3", "Armed Dragon Thunder LV3", "Dark Mimic LV3",
		"Drill Armed Dragon", "Knight Armed Dragon, the Armored Knight Dragon", "Silent Swordsman LV3", "Ultimate Insect LV3",
		"Armed Dragon, the Armored Dragon", "Dark Lucius LV4", "Hardened Armed Dragon", "Horus the Black Flame Dragon LV4", "Mystic Swordsman LV4",
		"Silent Magician LV4", "Silent Paladin", "Allure Queen LV5", "Armed Dragon LV5", "Armed Dragon Thunder LV5", "Fist Armed Dragon",
		"Silent Swordsman LV5", "Ultimate Insect LV5", "Dark Lucius LV6", "Horus the Black Flame Dragon LV6", "Mystic Swordsman LV6", "Allure Queen LV7",
		"Armed Dragon LV7", "Armed Dragon Thunder LV7", "Dark Armed Dragon", "Dark Armed Dragon Punisher", "Metaphys Armed Dragon", "Pile Armed Dragon",
		"Silent Swordsman LV7", "Ultimate Insect LV7", "Dark Lucius LV8", "Horus the Black Flame Dragon LV8", "Silent Magician LV8", "Armed Dragon Blitz",
		"Armed Dragon Flash", "Armed Dragon Lightning", "Feast of the Wild LV5", "Level Down!?", "Level Modulation", "Level Up!", "Ojamatch",
		"The Graveyard in the Fourth Dimension", "Armed Dragon Thunderbolt", "Ojama Pajama",
		"Ojama Duo", "Ojama Pink", "Ojamassimilation"]},
	"nordic": {"era": "5D's", "deck": "deck_nordic", "cards": [
		"Dverg of the Nordic Alfar", "Fenrir the Nordic Wolf", "Mara of the Nordic Alfar", "Mimir of the Nordic Ascendant",
		"Valkyrie of the Nordic Ascendant", "Nordic Beast Gullinbursti", "Tanngnjostr of the Nordic Beasts", "Tanngrisnir of the Nordic Beasts",
		"Alviss of the Nordic Alfar", "Garmr of the Nordic Beasts", "Guldfaxe of the Nordic Beasts", "Ljosalf of the Nordic Alfar", "Nordic Smith Ivaldi",
		"Tyr of the Nordic Champions", "Vanadis of the Nordic Ascendant", "Svartalf of the Nordic Alfar", "Jormungardr the Nordic Serpent",
		"Gotterdammerung", "March Towards Ragnarok", "Nordic Relic Draupnir", "Nordic Relic Hlidskjalf", "The Nordic Lights", "Loki, Lord of the Aesir",
		"Odin, Father of the Aesir", "Thor, Lord of the Aesir", "Divine Relic Mjollnir", "Gleipnir, the Fetters of Fenrir", "Nordic Relic Brisingamen",
		"Nordic Relic Gungnir", "Nordic Relic Laevateinn", "Nordic Relic Megingjord", "Nordic Relic Svalinn", "Odin's Eye", "Solemn Authority"]},
	"bujin": {"era": "ZEXAL", "deck": "deck_bujin", "cards": [
		"Bujin Arasuda", "Bujin Hirume", "Bujin Mahitotsu", "Bujin Mikazuchi", "Bujin Torifune", "Bujin Yamato", "Bujingi Boar", "Bujingi Centipede",
		"Bujingi Crane", "Bujingi Crow", "Bujingi Fox", "Bujingi Hare", "Bujingi Ibis", "Bujingi Ophidian", "Bujingi Pavo", "Bujingi Peacock",
		"Bujingi Quilin", "Bujingi Raven", "Bujingi Sinyou", "Bujingi Swallow", "Bujingi Turtle", "Bujingi Warg", "Bujingi Wolf",
		"Bujin Regalia - The Mirror", "Bujincandescence", "Bujincarnation", "Bujintervention", "Bujinunity", "Bujin Regalia - The Jewel",
		"Bujin Regalia - The Sword", "Bujincident", "Bujinfidel", "Bujinki Amaterasu", "Bujintei Kagutsuchi", "Bujintei Susanowo", "Bujintei Tsukuyomi"]},
	"legends_king": {"era": "Duel Monsters", "deck": "deck_legends_king", "cards": [
		"Wizard Buster Destruction Sword", "Buster Blader, the Destruction Swordmaster", "Samsara Lotus", "Jinzo - Returner", "The Fang of Critias",
		"Destruction Sword Flash", "Sword of Dark Rites", "Nightmare-Eyes Restrict", "Destruction Sword Memories", "Prologue of the Destruction Swordsman",
		"Jinzo - Lord", "Byroad Sacrifice", "Robot Buster Destruction Sword", "Jinzo the Machine Menace", "Destruction Swordsman Fusion",
		"Buster Whelp of the Destruction Swordsman", "Jinzo - Jector", "Relinquished Spider", "Samsara Kaiser", "Dragon Buster Destruction Sword",
		"Relinquished Fusion", "Karma of the Destruction Swordsman", "Legendary Knight Timaeus", "Legendary Knight Hermos", "Legendary Knight Critias",
		"Buster Blader, the Dragon Destroyer Swordsman", "Sacrifice Level-Up", "Jinzo - Layered", "Legend of Heart", "Buster Dragon", "Doom Virus Dragon", "Destruction Dragon", "Tyrant Burst Dragon", "Mirror Force Dragon", "Tyrant Wing"]},
	"jurrac": {"era": "Duel Monsters", "deck": "deck_jurrac", "cards": [
		"Jurrac Impact", "Jurrac Brachis", "Jurrac Guaiba", "Jurrac Herra", "Jurrac Meteor", "Jurrac Dino", "Jurrac Stego", "Jurrac Protops",
		"Jurrac Monoloph", "Jurrac Gallim", "Jurrac Spinos", "Jurrac Ptera", "Jurrac Stauriko", "Jurrac Astero", "Jurrac Velo", "Jurrac Tyrannus",
		"Jurrac Velphito", "Jurrac Iguanon", "Jurrac Giganoto", "Jurrac Aeolo", "Jurrac Titano", "Jurrac Volcano", "Jurrac Megalo"]},
	"darklord": {"era": "Duel Monsters", "deck": "deck_darklord", "cards": [
		"The First Darklord", "Darklord Eveningstar", "Darklord Djehuty", "Darklord Superbia", "Darklord Contact", "Darklord Nergal", "Darklord Nasten",
		"Darklord Morningstar", "Darklord Zerato", "Darklord Edeh Arae", "The Sanctified Darklord", "Darklord Rebellion", "Darklord Amdusc",
		"Darklord Ixchel", "Darklord Uprising", "Capricious Darklord", "Darklord Desire", "Darklord Marie", "Darklord Descent", "Darklord Nurse Reficule",
		"Indulged Darklord", "Darklord Gulgolet", "Darklord Asmodeus", "Banishment of the Darklords", "Darklord Enchantment", "Darklord Tezcatlipoca",
		"Darklord Ukoback", "Fallen Angel in Darkness", "Darklord Dance"]},
	"spirit": {"era": "Duel Monsters", "deck": "deck_spirit", "cards": [
		"Asura Priest", "Great Long Nose", "Yata-Garasu", "Ichiki Sayori-Hime", "Aratama", "Gishki Natalia", "Amaterasu", "Nikitama",
		"Shinobaroness Peacock", "Amano-Iwato", "Shinobaroness Shade Peacock", "Tsukuyomi", "Fushi No Tori", "Gundari", "Otohime", "Shinobird Crow",
		"Susa Soldier", "Maharaghi", "Rasetsu", "Izanami", "Kinka-byo", "Fenghuang", "Shinobaron Peacock", "Konohanasakuya", "Shinobaron Shade Peacock",
		"Shinobird Crane", "Sakitama", "Gishki Emilia", "Hino-Kagu-Tsuchi", "Yamata Dragon", "Inaba White Rabbit", "Tsumuha-Kutsunagi the Lord of Swords",
		"Yamato-no-Kami", "Dark Dust Spirit", "Hebo, Lord of the River", "Shinobird Pigeon", "Yaksha", "Phosphorage the Elemental Lord",
		"Moulinglacia the Elemental Lord", "Pyrorex the Elemental Lord", "Windrose the Elemental Lord", "Umbramirage the Elemental Lord",
		"Grandsoil the Elemental Lord", "Palace of the Elemental Lords", "Shinobird's Calling"]},
	"union": {"era": "Duel Monsters", "deck": "deck_union", "cards": [
		"C-Crush Wyvern", "Y-Yare Head", "Protective Soul Ailin", "Des Dendle", "Second Goblin", "Valkyrie Chariot", "A-Assault Core", "Oilman",
		"Z-Zillion Tank", "Fortune Chariot", "Pitch-Dark Dragon", "Zombie Tiger", "Trigon", "Doitsu", "Burning Beast", "Buster Blaster", "Koitsu",
		"Leng Ling", "B-Buster Drake", "Kiryu", "Freezing Beast", "Armor Breaker", "Union Pilot", "Union Driver", "Decayed Commander",
		"Indomitable Fighter Lei Lei", "Vampiric Orchis", "ABC-Dragon Buster", "A-to-Z-Dragon Buster Cannon", "Union Controller", "Union Rider",
		"Unauthorized Reactivation", "Formation Union", "Union Activation", "Union Scramble", "Frontline Base", "Union Attack", "Union Hangar"]},
	"hero": {"era": "GX", "deck": "deck_hero", "cards": [
		"Evil HERO Toxic Bubble", "Elemental HERO Marine Neos", "Elemental HERO Neo Bubbleman", "Elemental HERO Clay Guardian", "Elemental HERO Voltic",
		"Masked HERO Dusk Crow", "Masked HERO Vapor", "Favorite HERO Flame Wingman", "Evil HERO Wild Cyclone", "Evil HERO Adusted Gold",
		"Evil HERO Neos Lord", "Elemental HERO Chaos Neos", "Elemental HERO Thunder Giant - Voltic Thunder", "Evil HERO Lightning Golem",
		"Masked HERO Divine Wind", "Evil HERO Inferno Wing", "Contrast HERO Chaos", "Legacy of a HERO", "Destiny HERO - Dark Angel",
		"Evil HERO Dead-End Prison", "Miracle Ejector", "Evil HERO Vicious Claws", "Destiny HERO - Dread Servant", "Elemental HERO Grandmerge",
		"Elemental HERO Ocean", "Elemental HERO Nebula Neos", "Elemental HERO Ice Edge", "Elemental HERO Darkbright", "Evil HERO Sinister Necrom",
		"Evil HERO Infernal Sniper", "Evil HERO Infernal Prodigy", "Masked HERO Koga", "Elemental HERO Poison Rose", "Vision HERO Gravito",
		"Elemental HERO Shining Neos Wingman", "Masked HERO Goka", "Masked HERO Furnace", "Evil HERO Dark Gaia", "Evil HERO Malicious Edge",
		"Masked HERO Anki", "Evil HERO Inferno Wing - Backfire", "Elemental HERO Plasma Vice", "Vision HERO Minimum Ray", "Elemental HERO Knospe",
		"Masked HERO Dian", "Destiny HERO - Decider", "Masked HERO Fountain", "Destiny HERO - Dreamer", "Elemental HERO Inferno", "Elemental HERO Flash",
		"Elemental HERO Neos Alius", "Elemental HERO Neos Knight", "Elemental HERO Terra Firma", "Elemental HERO Woodsman", "HERO's Bond",
		"Evil HERO Infernal Rider", "Elemental HERO Captain Gold", "Vision HERO Witch Raider", "Vision HERO Poisoner", "Masked HERO Atomic",
		"Evil HERO Malicious Bane", "Evil HERO Darkest Knight", "Evil HERO Malicious Fiend", "Favorite HERO Shining Flare Wingman",
		"Elemental HERO Prisma", "Masked HERO Blast", "Elemental HERO Cosmo Neos", "Elemental HERO Neos Kluger", "Destiny HERO - Drilldark",
		"Elemental HERO Lady Heat", "Elemental HERO Core", "Evil HERO Infernal Gainer", "Vision HERO Multiply Guy", "Elemental HERO Heat", "Dark Fusion",
		"Metamorphosis", "Rose Bud",
		"Battle of Sleeping Spirits", "Break the Destiny", "Contact Gate", "Cross Keeper", "D - Force", "D Cubed", "Doctor D", "Double Hero Attack", "EN - Engage Neo Space", "EN Shuffle", "EN Wave", "Eternal Favorite", "Evil Mind", "Favorite Contact", "Favorite Hero", "Geistgrinder Golem", "Gruesome Grave Squirmer", "Instant Contact", "Magistery Alchemist", "Mask Charge", "Mature Chronicle", "NEXT", "Neo Space Connector", "Nightmare Pain", "Nightmare Throne", "Over Fusion", "Phantom of Yubel", "Protection of the Elements", "Samsara D Lotus", "Skydive Scorcher", "Spirit of Yubel", "Supreme King's Castle", "Yubel - The Loving Defender Forever"]},
	"sacred_beast": {"era": "GX", "deck": "deck_sacred_beast", "cards": [
		"Sacred Beasts Thunderclap", "The Chaotic Phantasmal Sacred Beasts", "Summoner of the Sacred Beasts",
		"Inferno of the Sacred Beasts - Uria, Lord of Searing Flames", "Raviel, Lord of Phantasms - Shimmering Scraper", "Illusion Gate",
		"Sacred Beasts Released", "Armityle the Chaos Phantasm", "Sacred Beasts Combined Assault",
		"Calamity of the Sacred Beasts - Hamon, Lord of Striking Thunder", "Phantasmal Summoning Beast", "Awakening of the Sacred Beasts",
		"Martyr of the Sacred Beasts", "Armityle the Chaos Phantasm - Phantom of Fury", "Fallen Paradise of the Sacred Beasts",
		"Raviel, Lord of Phantasms", "Abyss of the Sacred Beasts", "Phantasmal Martyrs", "Phantasm Emperor Trilojig",
		"Infinity of the Sacred Beasts - Raviel, Lord of Phantasms", "Uria, Lord of Searing Flames", "Hamon, Lord of Striking Thunder",
		"Dimension Fusion Destruction"]},
	"cyber": {"era": "GX", "deck": "deck_cyber", "cards": [
		"Cyberdark Invasion", "Malefic Cyber End Dragon", "Cyber Valley", "Cyberdark Chimera", "Cyber Network", "Cyberdarkness Dragon",
		"Cyber Jormungardr", "Cyber Pharos", "Cyber Ouroboros", "Cyber End Dragon the Decisive Strike Dragon", "Cyber Eternal", "Cyber Jar",
		"Cyber Ogre 2", "Cyberdark End Dragon", "Cyber Energy Shock", "Cyber Dinosaur", "Cyber Raider", "Cyber Tutubon", "Cyberdark Inferno",
		"Cyberdark Cannon", "Cyberdark Wurm", "Cyber Ogre", "Cyberdark Realm", "The Fiend Megacyber", "Revolution Cyber Dragon", "Armored Cybern",
		"Attachment Cybern", "Cyberdark Claw", "Cyber Shadow Gardna", "Cyber Esper", "Psychic Megacyber", "Stegocyber", "Dragonroid", "Shuttleroid",
		"Carrierroid", "Einroid", "Meteor Rush - Monochroid",
		"Cybernetic Revolution"]},
	"meklord": {"era": "5D's", "deck": "deck_meklord", "cards": [
		"Meklord Army of Granel", "Meklord Astro the Eradicator", "Meklord Army Deployer Obbligato", "Meklord Emperor Granel",
		"Meklord Astro Dragon Triskelion", "Earthbound Immortal Red Nova", "Earthbound Immortal Aslla piscu", "Boon of the Meklord Emperor",
		"Earthbound Immortal Uru", "Meklord Emperor Wisel - Synchro Absorption", "Meklord Emperor Skiel", "Earthbound Immortal Cusillu",
		"Meklord Astro Dragon Asterisk", "Meklord Assembly", "Meklord Army of Wisel", "Earthbound Immortal Wiraqocha Rasca",
		"Roar of the Earthbound Immortal", "The Resolute Meklord Army", "Meklord Astro Mekanikle", "Earthbound Immortal Revival", "Meklord Deflection",
		"Meklord Fortress", "Meklord Emperor Wisel", "Earthbound Immortal Chacu Challhua", "Ultimate Earthbound Immortal", "Meklord Army of Skiel",
		"Meklord Nucleus Infinity Core", "Meklord Factory", "Earthbound Immortal Ccarayhua",
		"Earthbound Fusion", "Earthbound Geoglyph", "Earthbound Greater Linewalker", "Earthbound Prison", "Earthbound Prisoner Ground Keeper", "Earthbound Prisoner Line Walker", "Earthbound Prisoner Stone Sweeper", "Earthbound Resonance", "Earthbound Servant Geo Grasha", "Earthbound Servant Geo Gremlin", "Earthbound Servant Geo Gremlina", "Earthbound Servant Geo Gryphon", "Earthbound Servant Geo Kraken", "Zoma the Earthbound Spirit"]},
	"synchron": {"era": "5D's", "deck": "deck_synchron", "cards": [
		"Starlight Junktion", "Junk Changer", "Blackwing - Hillen the Tengu-wind", "Junk Dragonlet", "Blackwing - Zonda the Dusk", "Resonator Command",
		"Blackwing - Gofu the Vague Shadow", "Starjunk Synchron", "Resonator Engine", "Junk Warrior Extreme", "Blackwing - Boreas the Sharp",
		"Blackwing - Gram the Shining Star", "Blackwing - Auster the South Wind", "Assault Blackwing - Sayo the Rain Hider",
		"Blackwing - Decay the Ill Wind", "Fleur Synchron", "Junk Warrior/Assault Mode", "Synchro Deflector", "Junk Anchor", "Changer Synchron",
		"Junk Signal", "Blackwing - Gladius the Midnight Sun", "Assault Blackwing - Kusanagi the Gathering Storm", "Junk Giant",
		"Blackwing - Hurricane the Tornado", "Accel Synchron", "Blackwing - Jin the Rain Shadow", "Junk Mail", "Mirror Resonator", "Junk Breaker",
		"Necro Synchron", "Blackwing - Kogarashi the Wanderer", "Junk Blader", "Bri Synchron", "Blackwing - Brisote the Tailwind",
		"Blackwing - Sharnga the Waning Moon", "Blackwing - Pinaki the Waxing Moon", "Junk Sleep", "Mono Synchron", "Satellite Synchron",
		"Blackwing - Damascus the Polar Night", "Junk Collector", "Wheel Synchron", "Double Resonator", "Junk Defender",
		"Assault Blackwing - Kunai the Drizzle", "Junk Meister", "Blackwing - Tornado the Reverse Wind", "Steam Synchron", "Darkness Resonator",
		"Junk Armor", "Necroid Synchro",
		"Arrive in Light", "Converging Wills Dragon", "Converging Wishes", "Cosmic Flare", "Final Cross", "Majestic Absorption", "Majestic Mirage", "On Your Mark, Get Set, DUEL!", "Rokket Synchron", "Rush Warrior", "Shooting Majestic Star Dragon", "Stardust Assault Warrior", "Stardust Chronicle Spark Dragon", "Stardust Flash", "Stardust Mirage", "Stardust Re-Spark", "Stardust Sifr Divine Dragon", "Stardust Wish", "Stardust Wurm", "Synchro Chase", "Synchro Dilemma"]},
	"karakuri": {"era": "5D's", "deck": "deck_karakuri", "cards": [
		"Karakuri Cash Shed", "Karakuri Cash Inn", "Karakuri Soldier mdl 236 \"Nisamu\"", "Karakuri Gama Oil", "Karakuri Gold Dust",
		"Karakuri Showdown Castle", "Karakuri Shogun mdl 00 \"Burei\"", "Karakuri Muso mdl 818 \"Haipa\"", "Karakuri Komachi mdl 224 \"Ninishi\"",
		"Karakuri Super Shogun mdl 00N \"Bureibu\"", "Karakuri Merchant mdl 177 \"Inashichi\"", "Karakuri Trick House",
		"Karakuri Bushi mdl 6318 \"Muzanichiha\"", "Karakuri Spider", "Karakuri Bonze mdl 9763 \"Kunamzan\"", "Karakuri Strategist mdl 248 \"Nishipachi\"",
		"Karakuri Steel Shogun mdl 00X \"Bureido\"", "Karakuri Watchdog mdl 313 \"Saizan\"", "Karakuri Gama mdl 4624 \"Shirokunishi\"", "Karakuri Klock",
		"Karakuri Cash Cache", "Runaway Karakuri", "Karakuri Anatomy", "Karakuri Barrel mdl 96 \"Shinkuro\""]},
	"fabled": {"era": "5D's", "deck": "deck_fabled", "cards": [
		"Fabled Miztoji", "Fabled Andwraith", "Fabled Ashenveil", "The Fabled Ganashia", "Fabled Krus", "Fabled Levilazebul", "Stairway to a Fabled Realm",
		"Fabled Grimro", "The Fabled Kokkator", "The Fabled Chawa", "Fabled Leviathan", "The Fabled Unicore", "Fabled Topi", "Fabled Raven",
		"Fabled Ragin", "Fabled Oltro", "Fabled Dianaira", "Fabled Valkyrus", "The Fabled Nozoochee", "Fabled Treason", "The Fabled Catsith",
		"Fabled Marcosia", "Fabled Realm's Revival", "Fabled Gallabas", "The Fabled Behilmoth", "Fabled Soulkius", "Fabled Urustos",
		"The Fabled Cerburrel", "The Fabled Abanc", "Fabled Dyf", "The Fabled Kudabbi", "The Fabled Peggulsus", "Fabled Gammajin", "The Fabled Rubyruda",
		"Fabled Kushano", "Fabled Lurrie"]},
	"fortune_lady": {"era": "5D's", "deck": "deck_fortune_lady", "cards": [
		"Fortune Lady Calling", "Fortune Lady Water", "Fortune Lady Light", "Fortune Lady Dark", "Fortune Lady Past", "Fortune Lady Every",
		"Fortune Lady Fire", "Fortune Lady Wind", "Fortune Lady Earth", "Fortune Lady Rewind",
		"Fortune Vision"]},
	"gusto": {"era": "5D's", "deck": "deck_gusto", "cards": [
		"Gusto Squirro", "Tailwind of Gusto", "Daigusto Phoenix", "Dust Storm of Gusto", "Musto, Oracle of Gusto", "Gusto Codor", "Daigusto Eguls",
		"Windaar, Sage of Gusto", "Gusto Thunbolt", "Daigusto Sphreez", "Daigusto Falcos", "Reeze, Whirlwind of Gusto", "Gusto Griffin", "Gusto Falco",
		"Winda, Priestess of Gusto", "Gusto Gulldo", "Pilica, Descendant of Gusto", "Kamui, Hope of Gusto", "Daigusto Laplampilica", "Blessings for Gusto",
		"Contact with Gusto", "Daigusto Gulldos", "Gusto Vedir", "Caam, Serenity of Gusto", "Gusto Egul", "Whirlwind of Gusto"]},
	"mermail": {"era": "ZEXAL", "deck": "deck_mermail", "cards": [
		"Mermail Abyssnose", "Atlantean Marksman", "Atlantean Attack Squad", "Abysstrite, the Atlantean Spirit", "Abyssrhine, the Atlantean Spirit",
		"Neptabyss, the Atlantean Prince", "Mermail Abyssmander", "Mermail Abyssmegalo", "Mermail Abyssturge", "Mermail Abyssteus", "Mermail Abysslinde",
		"Mermail Abyssocea", "Legendary Atlantean Tridon", "Atlantean Heavy Infantry", "Mermail Abyssleed", "Poseidra, the Atlantean Dragon",
		"Mermail Shadow Squad", "Mermail Abysspike", "Mermail Abysstrite", "Poseidra Abyss, the Atlantean Dragon Lord", "Mermail Abyssgunde",
		"Mermail Abyssnerei", "Call of the Atlanteans", "Mermail Abyssdine", "Atlantean Dragoons", "Mermail Abyssgaios", "Mermail Abyssbalaen",
		"Mermail Abysslung", "Mermail Abysshilde", "Poseidra, the Storming Atlantean", "Abyss-scale of the Kraken", "Abyss-scale of Cetus",
		"Abyss-scale of the Mizuchi", "Abyss-squall", "Abyss-sphere", "Abyss-steam", "Abyss-scorn", "Abyss-sting Triaina", "Abyss-strom"]},
	"spellbook": {"era": "ZEXAL", "deck": "deck_spellbook", "cards": [
		"Empress of Prophecy", "Defender, the Magical Knight", "Armor Exe", "Reaper of Prophecy", "Spellbook of the Grand Circle", "Strength of Prophecy",
		"Spellbook Magician of Prophecy", "Magical Contract Door", "Spellbook Library of the Heliosphere", "Supreme Arcanite Magician",
		"Type Zero Magic Crusher", "Hidden Spellbook", "Spellbook of Knowledge", "Spellbook of Power", "Time Wizard of Tomorrow", "Justice of Prophecy",
		"World of Prophecy", "Mega Ton Magical Cannon", "Magical Merchant", "The Grand Spellbook Tower", "Magical Scientist", "Amores of Prophecy",
		"Spellbook Library of the Crescent", "Endymion, the Master Magician", "Spellbook of Miracles", "Ebon Magician Curran", "Spellbook of Judgment",
		"Gilti-Gearfried the Magical Steel Knight", "Charioteer of Prophecy", "Giltia the D. Knight", "Spellbook of Life", "Emperor of Prophecy",
		"Stoic of Prophecy", "Prophecy Destroyer", "Spellbook Star Hall", "Spellbook of the Master", "Spellbook of Eternity", "Fool of Prophecy",
		"Wheel of Prophecy", "Magical Mid-Breaker Field", "Giltia the D. Knight - Soul Spear", "White Magician Pikeru", "High Priestess of Prophecy",
		"Temperance of Prophecy", "Spellbook of Wisdom", "Spellbook of Secrets", "Hermit of Prophecy", "Hierophant of Prophecy", "Spellbook Organization",
		"Spellbook of Fate", "Magical Citadel of Endymion", "Hiita the Fire Charmer", "Dharc the Dark Charmer", "Wynn the Wind Charmer", "Aussa the Earth Charmer", "Lyna the Light Charmer", "Eria the Water Charmer", "Familiar-Possessed - Hiita", "Familiar-Possessed - Dharc", "Familiar-Possessed - Wynn", "Familiar-Possessed - Aussa", "Familiar-Possessed - Lyna", "Familiar-Possessed - Eria", "Eria the Water Channeler", "Aussa the Earth Channeler", "Hiita the Fire Channeler", "Wynn the Wind Channeler", "Unpossessed", "Possessed Destiny", "Spiritual Art Familiars", "Charmers of the Grand Circle", "Possessed Destiny - Wynn", "Awakening of the Possessed", "Spirit Charmers", "Grand Spiritual Art - Ichirin"]},
	"wind_up": {"era": "ZEXAL", "deck": "deck_wind_up", "cards": [
		"Wind-Up Dog", "Wind-Up Soldier", "Wind-Up Hunter", "Wind-Up Shark", "Wind-Up Kitten", "Wind-Up Bat", "Wind-Up Rabbit", "Wind-Up Warrior",
		"Wind-Up Rat", "Wind-Up Snail", "Wind-Up Magician", "Wind-Up Zenmaister", "Legendary Wind-Up Key", "Wind-Up Arsenal Zenmaioh", "Wind-Up Knight",
		"Wind-Up Carrier Zenmaity", "Wind-Up Juggler", "Wind-Up Honeybee", "Wind-Up Factory"]},
	"ghostrick": {"era": "ZEXAL", "deck": "deck_ghostrick", "cards": [
		"Ghostrick Museum", "Ghostrick Stein", "Ghostrick Nekomusume", "Ghostrick or Treat", "Ghostrick Witch", "Ghostrick Parade", "Ghostrick Socuteboss",
		"Ghostrick Fairy", "Ghostrick-Go-Round", "Ghostrick Dullahan", "Ghostrick Doll", "Ghostrick Vanish", "Ghostrick Skeleton",
		"Ghostrick Angel of Mischief", "Ghostrick Yuki-onna", "Ghostrick Lantern", "Ghostrick Jackfrost", "Ghostrick Renovation", "Ghostrick Siren",
		"Ghostrick Shot", "Ghostrick Warwolf", "Ghostrick Break", "Ghostrick Jiangshi", "Ghostrick Specter", "Ghostrick Yeti", "Ghostrick Ghoul",
		"Ghostrick Night", "Ghostrick Scare", "Ghostrick Mummy", "Ghostrick Mary", "Ghostrick Mansion"]},
	"dragon_ruler": {"era": "ZEXAL", "deck": "deck_dragon_ruler", "cards": [
		"Chasma, Dragon Ruler of Auroras", "Tidal, Dragon Ruler of Waterfalls", "Stream, Dragon Ruler of Droplets",
		"Eclipse, Dragon Ruler of Catastrophes", "Burner, Dragon Ruler of Sparks", "Blaster, Dragon Ruler of Infernos",
		"Spectral, Dragon Ruler of Flickers", "Disaster, Dragon Ruler of All Apocalypses", "Lightning, Dragon Ruler of Drafts",
		"Redox, Dragon Ruler of Boulders", "Reactan, Dragon Ruler of Pebbles", "Nebulus, Dragon Ruler of Mishaps"]},
	"dd": {"era": "Duel Monsters", "deck": "deck_dd", "cards": [
		"D.D. Borderline", "D.D. Trap Hole", "D.D. Designator", "D.D. Crazy Beast", "D.D.M. - Different Dimension Master", "D.D. Dynamite",
		"D.D.R. - Different Dimension Reincarnation", "Different Dimension Gate", "D.D. Guide", "D.D. Survivor", "D.D. Scout Plane",
		"Dimension Distortion", "Dimension Explosion", "Dimension Jar", "Dimension Wall", "Dimensional Inversion", "Escape from the Dark Dimension",
		"D.D. Sprite", "D.D. Unicorn Knight", "D.D. Jet Iron", "D.D. Destroyer", "D.D. Esper Star Sparrow", "D.D. Telepon",
		"Sargasso the D.D. Battlefield", "D.D. Assailant", "D.D. Crow", "D.D. Trainer", "D.D. Warrior", "D.D. Warrior Lady", "Different Dimension Capsule",
		"Different Dimension Dragon", "Burial from a Different Dimension", "Return from the Different Dimension", "Dimension Fusion",
		"Dimensional Fissure", "Dimensional Alchemist", "Dimension Wanderer", "Invader from Another Dimension", "Macro Cosmos", "Banisher of the Light",
		"Dimensional Prison"]},
	"goblin": {"era": "Duel Monsters", "deck": "deck_goblin", "cards": [
		"Blindly Loyal Goblin", "Coach Goblin", "Goblin Black Ops", "Goblin Elite Attack Force", "Goblin Fan", "Goblin King",
		"Goblin Out of the Frying Pan", "Goblin Recon Squad", "Goblin Thief", "Goblin of Greed", "Good Goblin Housekeeping", "Hard-sellin' Goblin",
		"Minor Goblin Official", "Goblin Decoy Squad", "Goblin Pothole Squad", "Goblin Marauding Squad", "Peeking Goblin", "Goblin Circus",
		"Goblin Attack Force", "Goblin Calligrapher", "Goblin Zombie", "Goblin's Secret Remedy", "Goblindbergh", "Robbin' Goblin", "Second Goblin",
		"Upstart Goblin", "Crow Goblin", "Rock Ogre Grotto #1", "Rock Ogre Grotto #2", "Steel Ogre Grotto #1", "Steel Ogre Grotto #2", "Stone Ogre Grotto"]},
	"mask": {"era": "Duel Monsters", "deck": "deck_mask", "cards": [
		"The Mask of Remnants", "Mask of the Accursed", "The Masked Beast", "Mask of Weakness", "Mask of Dispel", "Curse of the Masked Beast",
		"Mask of Brutality", "Masked Beast Des Gardius", "Masked Sorcerer", "Tutan Mask", "Curse of Aging", "Curse of Anubis", "Curse of Darkness",
		"Curse of Fiend", "Curse of Royal", "Cursed Fig", "Masked Chameleon", "Mask of Restrict", "Mask of Darkness", "Masked Clown", "Masked Dragon",
		"Grand Tiki Elder", "Melchid the Four-Face Beast", "Masked Chopper"]},
	"toy": {"era": "Duel Monsters", "deck": "deck_toy", "cards": [
		"Puppet Pawn", "Puppet Rook", "Puppet Queen", "Puppet King", "Puppet Plant", "Puppet Master", "Mysterious Puppeteer",
		"The Puppet Magic of Dark Ruler", "Toy Box", "Toy Magician", "Toy Soldier", "Toy Knight", "Malice Doll of Demise", "Bait Doll",
		"Perditious Puppeteer", "Junk Puppet", "Puppet Ritual", "Condolence Puppet", "Puppet Parade"]},
	"barrier": {"era": "GX", "deck": "deck_barrier", "cards": [
		"Barrier Statue of the Inferno", "Barrier Statue of the Abyss", "Barrier Statue of the Stormwinds", "Barrier Statue of the Heavens",
		"Barrier Statue of the Drought", "Barrier Statue of the Torrent", "Harvest Angel of Wisdom", "Bountiful Artemis", "Voltanis the Adjudicator",
		"Layard the Liberator", "Meltiel, Sage of the Sky", "Synthetic Seraphim", "Mei-Kou, Master of Barriers", "Splendid Venus"]},
	"frog": {"era": "GX", "deck": "deck_frog", "cards": [
		"Poison Draw Frog", "D.3.S. Frog", "Unifrog", "Beelze Frog", "Des Frog", "Froggy Forcefield", "Penguin Torpedo", "Penguin Knight",
		"Nightmare Penguin", "Flip Flop Frog", "Dupe Frog", "Swap Frog", "Tradetoad", "Ronintoadin", "Puny Penguin", "Guard Penguin",
		"The Great Emperor Penguin", "T.A.D.P.O.L.E.", "Substitoad", "Submarine Frog", "Treeborn Frog", "Penguin Soldier", "Penguin Ninja",
		"Flying Penguin", "Bolt Penguin", "Slime Toad", "Toad Master", "Toadally Awesome", "Fishborg Blaster"]},
	"worm": {"era": "5D's", "deck": "deck_worm", "cards": [
		"Shield Worm", "Warm Worm", "Worm Bait", "Worm Call", "Worm Falco", "Worm Gulse", "Worm Hope", "Worm Illidan", "Worm Jetelikpse", "Worm King",
		"Worm Linx", "Worm Millidith", "Worm Noble", "Worm Opera", "Worm Prince", "Worm Queen", "Worm Rakuyeh", "Worm Solid", "Worm Tentacles",
		"Worm Ugly", "Worm Victory", "Worm Warlord", "Worm Xex", "Worm Yagan", "Worm Zero", "Dungeon Worm", "Needle Worm", "Scrap Worm", "Worm Drake"]},
	"swarm": {"era": "5D's", "deck": "deck_swarm", "cards": [
		"Evilswarm Azzathoth", "Evilswarm Bahamut", "Evilswarm Castor", "Evilswarm Coppelia", "Evilswarm Golem", "Evilswarm Hraesvelg",
		"Evilswarm Kerykeion", "Evilswarm Ketos", "Evilswarm Mandragora", "Evilswarm Nightmare", "Evilswarm O'lantern", "Evilswarm Obliviwisp",
		"Evilswarm Ophion", "Evilswarm Ouroboros", "Evilswarm Salamandra", "Evilswarm Thanatos", "Evilswarm Thunderbird", "Evilswarm Zahak",
		"First Step Towards Infestation", "Infestation Infection", "Infestation Pandemic", "Infestation Ripples", "Infestation Terminus",
		"Infestation Tool", "Infestation Wave", "Steelswarm Caller", "Steelswarm Caucastag", "Steelswarm Cell", "Steelswarm Gatekeeper",
		"Steelswarm Genome", "Steelswarm Girastag", "Steelswarm Hercules", "Steelswarm Longhorn", "Steelswarm Mantis", "Steelswarm Moth",
		"Steelswarm Scout", "Steelswarm Sentinel", "Steelswarm Sting", "Evilswarm Exciton Knight", "Evilswarm Heliotrope", "Steelswarm Roach"]},
	"vylon": {"era": "5D's", "deck": "deck_vylon", "cards": [
		"Vylon Alpha", "Vylon Charger", "Vylon Component", "Vylon Cube", "Vylon Delta", "Vylon Disigma", "Vylon Element", "Vylon Epsilon",
		"Vylon Filament", "Vylon Hept", "Vylon Material", "Vylon Matter", "Vylon Ohm", "Vylon Omega", "Vylon Pentachloro", "Vylon Polytope", "Vylon Prism",
		"Vylon Segment", "Vylon Sigma", "Vylon Soldier", "Vylon Sphere", "Vylon Stella", "Vylon Stigma", "Vylon Tesseract", "Vylon Tetra", "Vylon Vanguard"]},
	"gishki": {"era": "5D's", "deck": "deck_gishki", "cards": [
		"Aquamirror Cycle", "Aquamirror Illusion", "Aquamirror Meditation", "Contact with the Aquamirror", "Evigishki Gustkraken", "Evigishki Levianima",
		"Evigishki Merrowgeist", "Evigishki Mind Augus", "Evigishki Soul Ogre", "Evigishki Tetrogre", "Forbidden Arts of the Gishki", "Gishki Abyss",
		"Gishki Aquamirror", "Gishki Ariel", "Gishki Avance", "Gishki Beast", "Gishki Chain", "Gishki Diviner", "Gishki Marker", "Gishki Mollusk",
		"Gishki Noellia", "Gishki Photomirror", "Gishki Psychelone", "Gishki Reliever", "Gishki Shadow", "Gishki Vanity", "Gishki Vision",
		"Gishki Zielgigas", "Ritual Buster", "Spiritual Forest", "Gishki Emilia", "Gishki Natalia", "Ritual Weapon"]},
	"watt": {"era": "5D's", "deck": "deck_watt", "cards": [
		"Wattberyx", "Wattbetta", "Wattcannon", "Wattcastle", "Wattchimera", "Wattcine", "Wattcobra", "Wattcube", "Wattdragonfly", "Wattfox",
		"Wattgiraffe", "Watthopper", "Watthydra", "Wattjustment", "Wattkeeper", "Wattkey", "Wattkiwi", "Wattlemur", "Wattmole", "Wattpheasant",
		"Wattsquirrel", "Wattsychic Fighter", "Wattwoodpecker", "Wattaildragon", "Wattkid",
		"Wattkinetic Puppeteer", "Wattkingdom", "Wattkyuki", "Wattrain", "Wattsychic Fighting Porter", "Wattuna"]},
	"laval": {"era": "5D's", "deck": "deck_laval", "cards": [
		"Laval Blaster", "Laval Burner", "Laval Cannon", "Laval Coatl", "Laval Dual Slasher", "Laval Forest Sprite", "Laval Judgment Lord",
		"Laval Lakeside Lady", "Laval Lancelord", "Laval Magma Cannoneer", "Laval Miller", "Laval Phlogis", "Laval Stennon", "Laval Volcano Handmaiden",
		"Laval Warrior", "Laval the Greater", "Lavalval Dragon", "Lavalval Dragun", "Lavalval Ignis", "Lavalval Chain",
		"Laval Archer", "Lavalval Exlord", "Lavalval Salamander"]},
	"ally_justice": {"era": "5D's", "deck": "deck_ally_justice", "cards": [
		"Ally of Justice Core Destroyer", "Ally of Justice Cosmic Gateway", "Ally of Justice Cyclone Creator", "Ally of Justice Enemy Catcher",
		"Ally of Justice Field Marshal", "Ally of Justice Light Gazer", "Ally of Justice Nullfier", "Ally of Justice Omni-Weapon",
		"Ally of Justice Quarantine", "Ally of Justice Reverse Break", "Ally of Justice Searcher", "Ally of Justice Thousand Arms",
		"Ally of Justice Thunder Armor", "Ally of Justice Unknown Crusher", "Ally of Justice Unlimiter", "Ally of Justice Catastor",
		"Ally of Justice Clausolas", "Ally of Justice Cycle Reader", "Ally of Justice Decisive Armor", "Ally of Justice Garadholg"]},
	"flamvell": {"era": "5D's", "deck": "deck_flamvell", "cards": [
		"Ancient Flamvell Deity", "Flamvell Archer", "Flamvell Baby", "Flamvell Commando", "Flamvell Counter", "Flamvell Fiend", "Flamvell Firedog",
		"Flamvell Grunika", "Flamvell Poun", "Neo Flamvell Garuda", "Neo Flamvell Hedgehog", "Neo Flamvell Origin", "Neo Flamvell Sabre",
		"Neo Flamvell Shaman", "Flamvell Guard"]},
	"reptilianne": {"era": "5D's", "deck": "deck_reptilianne", "cards": [
		"Reptilianne Gardna", "Reptilianne Gorgon", "Reptilianne Hydra", "Reptilianne Medusa", "Reptilianne Naga", "Reptilianne Poison",
		"Reptilianne Rage", "Reptilianne Scylla", "Reptilianne Servant", "Reptilianne Spawn", "Reptilianne Vaskii", "Reptilianne Viper"]},
	"evol": {"era": "ZEXAL", "deck": "deck_evol", "cards": [
		"Evo-Branch", "Evo-Diversity", "Evo-Force", "Evo-Instant", "Evo-Karma", "Evo-Miracle", "Evo-Price", "Evo-Singularity", "Evolsaur Cerato",
		"Evolsaur Darwino", "Evolsaur Diplo", "Evolsaur Elias", "Evolsaur Pelta", "Evolsaur Terias", "Evolsaur Vulcano", "Evoltile Casinerio",
		"Evoltile Elginero", "Evoltile Gephyro", "Evoltile Lagosucho", "Evoltile Najasho", "Evoltile Odonto", "Evoltile Pleuro", "Evoltile Westlo",
		"Evolutionary Bridge", "Evolzar Solda", "Evolzar Dolkka", "Evolzar Laggia",
		"Beta Evolution Pill - Ultranscendance", "Cocoon of Ultra Evolution", "Evolsaur Lios", "Evoltile Megachirella", "Evoltile Pholis", "Evolution End Burst", "Evolzar Lars"]},
	"phantom_beast": {"era": "ZEXAL", "deck": "deck_phantom_beast", "cards": [
		"Horn of the Phantom Beast", "Mecha Phantom Beast Aerosguin", "Mecha Phantom Beast Blackfalcon", "Mecha Phantom Beast Blue Impala",
		"Mecha Phantom Beast Coltwing", "Mecha Phantom Beast Concoruda", "Mecha Phantom Beast Hamstrat", "Mecha Phantom Beast Harrliard",
		"Mecha Phantom Beast Kalgriffin", "Mecha Phantom Beast Megaraptor", "Mecha Phantom Beast O-Lion", "Mecha Phantom Beast Sabre Hawk",
		"Mecha Phantom Beast Stealthray", "Mecha Phantom Beast Tetherwolf", "Mecha Phantom Beast Turtletracer", "Mecha Phantom Beast Warbluran",
		"Chimera the Flying Mythical Beast", "Gazelle the King of Mythical Beasts", "Mecha Phantom Beast Dracossack", "Phantom Beast Wild-Horn",
		"Mecha Phantom Beast Jaculuslan", "Mecha Phantom Beast Raiten"]},
	"noble_knight": {"era": "ZEXAL", "deck": "deck_noble_knight", "cards": [
		"Artorigus, King of the Noble Knights", "Gwenhwyfar, Queen of Noble Arms", "Ignoble Knight of Black Laundsallyn",
		"Ignoble Knight of High Laundsallyn", "Noble Arms - Arfeudutyr", "Noble Arms - Caliburn", "Noble Arms - Excaliburn", "Noble Arms - Gallatin",
		"Noble Arms of Destiny", "Noble Knight Borz", "Noble Knight Brothers", "Noble Knight Drystan", "Noble Knight Eachtar", "Noble Knight Gawayn",
		"Noble Knight Gwalchavad", "Noble Knight Joan", "Noble Knight Medraut", "Noble Knight Peredur", "Noble Knights of the Round Table",
		"Sacred Noble Knight of King Artorigus", "Celestial Sword - Eatos", "Noble Knight Artorigus",
		"Camelot, Realm of Noble Knights and Noble Arms", "Celtic Guard of Noble Arms", "Glory of the Noble Knights", "Heritage of the Chalice", "Horse of the Floral Knights", "Last Chapter of the Noble Knights", "Merlin", "Morgan, the Enchantress of Avalon", "Noble Arms - Clarent", "Noble Arms Museum", "Noble Knight Bedwyr", "Noble Knight Iyvanne", "Noble Knight Pellinore", "Noble Knight's Shield-Bearer", "Noble Knight's Spearholder", "Sacred Noble Knight of King Custennin", "The Continuing Epic of Charles", "Until Noble Arms are Needed Once Again"]},
	"gears": {"era": "ZEXAL", "deck": "deck_gears", "cards": [
		"Construction Train Signal Red", "Express Train Trolley Olley", "Geargiaccelerator", "Geargiagear", "Geargiagear Gigant XG", "Geargiano",
		"Geargiano Mk-II", "Geargiano Mk-III", "Geargiarmor", "Geargiarsenal", "Geargiattacker", "Geargiauger", "Lionhearted Locomotive",
		"Night Express Knight", "Rocket Arrow Express", "Ruffian Railcar", "Snow Plow Hustle Rustle", "Special Schedule", "Train Connection",
		"Number 81: Superdreadnought Rail Cannon Super Dora", "Superdreadnought Rail Cannon Gustav Max",
		"Geargia Change", "Geargianchor"]},
	"inzektor": {"era": "ZEXAL", "deck": "deck_inzektor", "cards": [
		"Inzektor Ant", "Inzektor Axe - Zektahawk", "Inzektor Centipede", "Inzektor Crossbow - Zektarrow", "Inzektor Dragonfly", "Inzektor Earwig",
		"Inzektor Exa-Beetle", "Inzektor Exa-Stag", "Inzektor Firefly", "Inzektor Gauntlet", "Inzektor Giga-Cricket", "Inzektor Giga-Mantis",
		"Inzektor Giga-Weevil", "Inzektor Hopper", "Inzektor Hornet", "Inzektor Ladybug", "Inzektor Orb", "Inzektor Sword - Zektkaliber"]},
	"hazy": {"era": "ZEXAL", "deck": "deck_hazy", "cards": [
		"Circle of the Fire Kings", "Fire King Avatar Barong", "Fire King Avatar Garunix", "Fire King Avatar Kirin", "Fire King Avatar Yaksha",
		"Fire King High Avatar Garunix", "Hazy Flame Basiltrice", "Hazy Flame Cerbereus", "Hazy Flame Griffin", "Hazy Flame Hydra", "Hazy Flame Hyppogrif",
		"Hazy Flame Mantikor", "Hazy Flame Peryton", "Hazy Flame Sphynx", "Hazy Glory", "Hazy Pillar", "Onslaught of the Fire Kings",
		"Cursed Fire King Doom Burst", "Echelon of the Fire Kings", "Fire King Avatar Arvata", "Fire King Avatar Rangbali", "Fire King High Avatar Kirin", "Fire King Island", "Fire King Sanctuary", "Fire King Sky Burn", "Garunix Eternity, Hyang of the Fire Kings", "Legendary Fire King Ponix", "Sacred Fire King Garunix"]},
	"hieratic": {"era": "ZEXAL", "deck": "deck_hieratic", "cards": [
		"Hieratic Dragon King of Atum", "Hieratic Dragon of Asar", "Hieratic Dragon of Eset", "Hieratic Dragon of Gebeb", "Hieratic Dragon of Nebthet",
		"Hieratic Dragon of Nuit", "Hieratic Dragon of Su", "Hieratic Dragon of Sutekh", "Hieratic Dragon of Tefnuit", "Hieratic Seal From the Ashes",
		"Hieratic Seal of Banishment", "Hieratic Seal of Convocation", "Hieratic Seal of Reflection", "Hieratic Seal of Supremacy",
		"Hieratic Seal of the Dragon King", "Hieratic Seal of the Sun Dragon Overlord", "Hieratic Sun Dragon Overlord of Heliopolis",
		"Hieratic Seal of Creation", "Hieratic Sky Dragon Overlord of Heliopolis"]},
	"artifact": {"era": "ZEXAL", "deck": "deck_artifact", "cards": [
		"Artifact Achilleshield", "Artifact Aegis", "Artifact Beagalltach", "Artifact Caduceus", "Artifact Durendal", "Artifact Failnaught",
		"Artifact Ignition", "Artifact Labrys", "Artifact Moralltach", "Artifact Sanctum", "Artifact Scythe", "Artifacts Unleashed",
		"Artifact Chakram", "Artifact Lancea", "Artifact Mjollnir", "Artifact Vajra"]},
	"heraldic": {"era": "ZEXAL", "deck": "deck_heraldic", "cards": [
		"Advanced Heraldry Art", "Augmented Heraldry", "Heraldic Beast Aberconway", "Heraldic Beast Basilisk", "Heraldic Beast Berners Falcon",
		"Heraldic Beast Eale", "Heraldic Beast Leo", "Heraldic Beast Twin-Headed Eagle", "Heraldic Beast Unicorn", "Heraldry Change", "Heraldry Reborn",
		"Heraldry Record", "Number 8: Heraldic King Genom-Heritage", "Number 18: Heraldry Patriarch", "Number 69: Heraldry Crest",
		"Number C69: Heraldry Crest of Horror",
		"Charged-Up Heraldry"]},
	"sylvan": {"era": "ZEXAL", "deck": "deck_sylvan", "cards": [
		"Alsei, the Sylvan High Protector", "Mount Sylvania", "Orea, the Sylvan High Arbiter", "Sylvan Bladefender", "Sylvan Blessing", "Sylvan Charity",
		"Sylvan Cherubsprout", "Sylvan Flowerknight", "Sylvan Guardioak", "Sylvan Hermitree", "Sylvan Komushroomo", "Sylvan Lotuswain",
		"Sylvan Marshalleaf", "Sylvan Mikorange", "Sylvan Peaskeeper", "Sylvan Sagequoia", "Sylvan Snapdrassinagon", "Sylvan Waterslide",
		"Sylvan Princessprout",
		"Sylvan Princessprite"]},
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


## The file this collection lives in. The Academy story keeps cards and decks of its own
## (campus_cards.cfg): Campus switches to it while you are on the island and back when you leave.
var path := PATH


## Put every list back to what a new duelist has (before another file is read).
func _blank() -> void:
	owned = {}
	main = []
	extra = []
	dp = 300
	deck_name = "My Deck"
	side = []
	slots = []
	dropped = []
	slot = 0
	banlist = false
	decks_owned = []
	active = "echo"
	starter_pick = ""
	_new_save = false
	record = {}
	last_reward = []
	last_prize = 0
	deck_news = false
	lumen_news = []


## Change which file the collection is: what is open now is saved first, then the other one is
## read as if the game had just started on it.
func switch_file(to: String) -> void:
	if to == path:
		return
	save()
	path = to
	_blank()
	_read()
	changed.emit()


func _ready() -> void:
	_read()


func _read() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
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
	elif path == PATH:
		_adopt_old_deck()
	_renumber()
	if owned.is_empty():
		_new_save = true
		if path == PATH:
			_starter()
	# Lumen, your partner: every duelist has her card, old saves included.
	if int(owned.get(CardData.LUMEN, 0)) < 1:
		owned[CardData.LUMEN] = 1
		if not main.has(CardData.LUMEN) and main.size() < 60:
			main.append(CardData.LUMEN)
		save.call_deferred()
	# (The Academy's own collection starts from nothing: Lumen's cards arrive with its story.)
	if path == PATH:
		lumen_gifts()
	_fill_slots()
	if path == PATH:
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
	if cfg.load(Saves.u("roam.cfg")) != OK:
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
	var an := DeckTiers.anime_owner(key)
	if not an.is_empty():
		return anime_price(an[1], deck_price(str(an[0])))
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
	# Buying a deck adds its cards to what you have (0.63.1): one Polymerization at home and one in the
	# deck is two. (Before, a card you already had was not added.) Three copies is the most a grant gives.
	for id in need:
		owned[id] = maxi(int(owned.get(id, 0)), mini(3, int(owned.get(id, 0)) + int(need[id])))
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
		# (A duelist who plays a theme deck leaves it in the shop as the theme deck it is.)
		if seen.has(dk) or not CardData.has_deck(dk) or not bool(d.get("pool", true)):
			continue
		seen[dk] = true
		out.append({"key": dk, "name": CardData.deck_name(dk), "owner": str(d.get("name", "")), "who": k, "color": d.get("color", Color.WHITE),
			"blurb": "", "art": "", "price": DECK_PRICE, "kind": "duelist", "era": str(d.get("era", ""))})
	for t in THEME_DECKS:
		if CardData.has_deck(str(t["key"])):
			out.append({"key": t["key"], "name": CardData.deck_name(str(t["key"])), "owner": "", "who": "", "color": t["color"],
				"blurb": t["blurb"], "art": t["art"], "price": THEME_PRICE, "kind": "theme", "era": str(t.get("era", "")), "stage": int(t.get("stage", 0))})
	return out


## (0.80.0) Every version of a ready-made deck the shop sells, in the order shown: the two decks from
## the show (when the duelist has them) and the Competitive one. Each is a catalog entry of its own,
## with "version" ("anime1", "anime2", "full") and "base" (the catalog entry's key).
func deck_versions(e: Dictionary) -> Array:
	var out: Array = []
	var base := str(e["key"])
	if DeckTiers.ANIME.has(base):
		for i in 2:
			var ak := str(DeckTiers.ANIME[base][i])
			if ak == "" or not CardData.has_deck(ak):
				continue
			var v: String = DeckTiers.ANIME_VERSIONS[i]
			var a := e.duplicate()
			a["key"] = ak
			a["name"] = CardData.deck_name(ak)
			a["price"] = anime_price(v, int(e["price"]))
			a["version"] = v
			a["base"] = base
			if str(a.get("owner", "")) == "":
				# (A theme deck one of the cast plays, Crowler's Ancient Gears: their decks from the show are theirs.)
				for k in Characters.ORDER:
					if str(Characters.DATA[k].get("deck", "")) == base:
						a["owner"] = str(Characters.DATA[k].get("name", ""))
						a["who"] = k
						break
			out.append(a)
	var f := e.duplicate()
	f["version"] = "full"
	f["base"] = base
	out.append(f)
	return out


func deck_info(key: String) -> Dictionary:
	if key == "echo":
		return {"key": "echo", "name": CardData.deck_name("echo"), "owner": "Lumen", "who": "player", "color": Color("2de2e6"),
			"blurb": "Lumen's own deck: hers, and the Echo cards she has given you.", "art": "", "price": 0, "kind": "gift", "era": ""}
	var st := starter_info(key)
	if not st.is_empty():
		return {"key": key, "name": CardData.deck_name(key), "owner": "", "who": "player", "color": st["color"],
			"blurb": st["blurb"], "art": "", "price": 0, "kind": "starter", "era": ""}
	var an := DeckTiers.anime_owner(key)
	for e in deck_catalog():
		if e["key"] == key:
			return e
		if not an.is_empty() and e["key"] == an[0]:
			for v in deck_versions(e):
				if v["key"] == key:
					return v
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


## The covers are worked out once (each pack's best card nobody else has on the front) and kept on
## disk for the same cards and the same game version: working them out reads every pack's pool,
## which took seconds the first time the shops page opened (0.69.2). `cover_step` does it a little at
## a time for a screen that wants to stay smooth meanwhile; `pack_cover` finishes it at once.
var _cover_q: Array = []        # packs still to give a cover (while it is done a little at a time)
var _cover_used := {}
static var COVERS_FILE := Saves.u("pack_covers.cfg")


func _cover_sig() -> String:
	var cj := Settings.card_folder.path_join("cards.json")
	return "%s|%d|%d|%d" % [ProjectSettings.get_setting("application/config/version", ""), CardData.EXT.size(), CardData.NAME_TO_ID.size(),
			FileAccess.get_modified_time(cj) if FileAccess.file_exists(cj) else 0]


func covers_ready() -> bool:
	if _covers.is_empty() and _cover_q.is_empty():
		_covers_from_disk()
	return not _covers.is_empty() and _cover_q.is_empty()


func _covers_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(COVERS_FILE) != OK or str(cfg.get_value("covers", "sig", "")) != _cover_sig():
		return
	var got = cfg.get_value("covers", "all", {})
	if got is Dictionary and not (got as Dictionary).is_empty():
		_covers = got


## Work on the covers for about `budget_ms`; true once they are all known.
func cover_step(budget_ms := 6.0) -> bool:
	if covers_ready():
		return true
	if _cover_q.is_empty():
		_cover_q = PACKS + all_volumes() + BUNDLES.map(func(b): return bundle_pack(b))
		_cover_used = {}
		_covers_partial = {}
	var t0 := Time.get_ticks_usec()
	while not _cover_q.is_empty() and Time.get_ticks_usec() - t0 < budget_ms * 1000.0:
		var p: Dictionary = _cover_q.pop_front()
		_covers_partial[str(p["key"])] = _cover_for(p)
	if _cover_q.is_empty():
		_covers_partial["echo"] = CardData.LUMEN       # (her own pack has her on it, whatever it holds by now)
		_covers = _covers_partial
		_covers_partial = {}
		var cfg := ConfigFile.new()
		cfg.load(COVERS_FILE)
		cfg.set_value("covers", "sig", _cover_sig())
		cfg.set_value("covers", "all", _covers)
		cfg.save(COVERS_FILE)
		return true
	return false


var _covers_partial := {}


func _cover_for(p: Dictionary) -> int:
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
		if not _cover_used.has(id):
			pick = id
			break
	if pick == 0 and not ids.is_empty():
		pick = ids[0]
	_cover_used[pick] = true
	return pick


func pack_cover(key: String) -> int:
	while not cover_step(1000000.0):
		pass
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
	return n >= MAIN_MIN and n <= MAIN_MAX and _missing_in((slots[i].get("main", []) as Array) + (slots[i].get("extra", []) as Array) + (slots[i].get("side", []) as Array)).is_empty()


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
	cfg.save(path)
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
	if not _missing_in(m + e + (s.get("side", []) as Array)).is_empty():
		return false      # (cards you don't have yet)
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
	return main.size() >= MAIN_MIN and main.size() <= MAIN_MAX and extra.size() <= EXTRA_MAX and side.size() <= SIDE_MAX and illegal().is_empty() and missing_cards().is_empty()


## The cards in the open deck you don't have enough copies of yet (a deck can be planned with
## cards you are still looking for; it can't be dueled with until you have them all):
## [[id, copies in the deck, copies you own]].
func missing_cards() -> Array:
	return _missing_in(main + extra + side)


func _missing_in(ids: Array) -> Array:
	var n := {}
	for id in ids:
		n[int(id)] = int(n.get(int(id), 0)) + 1
	var out: Array = []
	for id in n:
		if int(n[id]) > count(int(id)) and int(id) != CardData.LUMEN:
			out.append([int(id), int(n[id]), count(int(id))])
	return out


## Admin mode only (0.72.1): hands over every copy the open deck is missing. Returns how many.
func admin_fill_missing() -> int:
	if not Saves.admin:
		return 0
	var n := 0
	for m in missing_cards():
		var short := int(m[1]) - int(m[2])
		owned[int(m[0])] = int(m[1])
		n += short
		meet(int(m[0]))
	if n > 0:
		save()
	return n


## How many copies the open deck still needs.
func missing_count() -> int:
	var t := 0
	for m in missing_cards():
		t += int(m[1]) - int(m[2])
	return t


## `plan`: the deck editor, where a card you don't own (yet) can go in a deck all the same.
func can_add(id: int, to_side := false, plan := false) -> bool:
	var d := CardData.get_card(id)
	var is_extra: bool = str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]
	if in_deck(id) >= (mini(3, limit(id)) if plan else mini(mini(3, limit(id)), count(id))):
		return false
	if to_side:
		return side.size() < SIDE_MAX
	return extra.size() < EXTRA_MAX if is_extra else main.size() < MAIN_MAX


func add_side(id: int, plan := false) -> void:
	if can_add(id, true, plan):
		side.append(id)
		save()


func remove_side(id: int) -> void:
	if side.has(id):
		side.erase(id)
		save()


func add(id: int, plan := false) -> void:
	if not can_add(id, false, plan):
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
	return int(pack.get("price", PACK_PRICE if int(pack.get("tab", 0)) == 0 and base_key(str(pack.get("key", ""))) != "beyond" else THEMED_PRICE))


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
		"spells":      # (was "spellbook" until 0.55.0: that is the Spellbook family's key since 0.53.0)
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
	Router.pulse()      # (keeps a loading card or the busy ring moving while lists are worked out)
	_fresh()
	if era == "echo":
		return lumen_pool()           # (grows with the story: never kept from one look to the next)
	if _pools.has(era):
		return _pools[era]
	if era.contains("#"):
		_pools[era] = _volume_ids(era)
		return _pools[era]
	if is_bundle(era):
		var seen := {}
		for b in BUNDLES:
			if str(b["key"]) == era:
				for fk in b["families"]:
					for id in family_ids(str(fk)):
						seen[int(id)] = true
		_pools[era] = seen.keys()
		return _pools[era]
	var ids := {}
	if FAMILIES.has(era):
		_pools[era] = family_ids(era)
		return _pools[era]
	if not (era in SERIES):
		var themed: Array = []
		# (New Frontier's cards stay in New Frontier: it opens after the story, so they are not
		# sold early in the Type and Element packs.)
		var later := {}
		for id in pool("frontier"):
			later[id] = true
		for id in all_cards():
			if _in_theme(era, id) and not later.has(id):
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
			if str(d.get("era", "")) != era or not CardData.has_deck(str(d["deck"])) or not bool(d.get("pool", true)):
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
	var got := open_packs(era, 1)
	return [] if got.is_empty() else got[0]


## Several of the same pack at once, for less: 5 cost the price of 4.5, 10 the price of 8.5.
const MULTI := {1: 1.0, 5: 4.5, 10: 8.5}


func multi_price(pack: Dictionary, n: int) -> int:
	return int(round(pack_price(pack) * float(MULTI.get(n, n))))


## Buy and open n of a pack in one go. Returns one array of card ids per pack (empty if you
## can't afford them all).
func open_packs(era: String, n: int) -> Array:
	if not Unlocks.pack(era):
		Router.toast(Unlocks.pack_why(era))
		return []
	var cards := pool(era)
	var pk := pack_of(era)
	var price := multi_price(pk, n)
	var count := int(pk.get("size", PACK_SIZE))
	if era == "echo":
		# Never more than three of a card of Lumen's: a pack only holds the ones you still lack.
		if n != 1 or dp < price:
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
		return [got]
	if dp < price or cards.is_empty():
		return []
	dp -= price
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for k in n:
		var pulls := []
		for i in PACK_SIZE:
			var id: int = cards[rng.randi() % cards.size()]
			# The last slot leans toward stronger cards.
			if i == PACK_SIZE - 1:
				for tries in 6:
					var alt: int = cards[rng.randi() % cards.size()]
					if CardData.rarity(alt) >= 2:
						id = alt
						break
			pulls.append(id)
			owned[id] = int(owned.get(id, 0)) + 1
		out.append(pulls)
		daily_bump("pack")
	save()
	return out


## The shop entry for a pack key (a volume's own entry for "Duel Monsters#2").
func pack_of(key: String) -> Dictionary:
	for p in PACKS:
		if str(p["key"]) == key:
			return p
	for p in all_volumes():
		if str(p["key"]) == key:
			return p
	for b in BUNDLES:
		if str(b["key"]) == key:
			return bundle_pack(b)
	return {"key": key, "tab": 0}


# ---- Volumes (0.53.0). The era sets got too big to collect from one pack (Legend of the King
# held over a thousand cards), so the shop sells each one in volumes of about VOLUME_SIZE cards,
# in the order the cards first came out (data/release_order.json: Konami's database number for
# each card). The whole set stays one page in the album; "Duel Monsters#2" is its second volume.
const VOLUME_SIZE := 150
var _release := {}


static func base_key(key: String) -> String:
	return key.get_slice("#", 0)


static func volume_of(key: String) -> int:
	return int(key.get_slice("#", 1)) if key.contains("#") else 0


func volume_count(era: String) -> int:
	if not (era in SERIES or era in BIG_PACKS):
		return 1
	# (Kept on disk with the pack covers, for the same cards and game version: counting means
	# working out the whole pool of a big set, and the shops page asks for every one of them.)
	if _vols_disk.is_empty():
		var cfg := ConfigFile.new()
		_vols_disk = {"_": true}
		if cfg.load(COVERS_FILE) == OK and str(cfg.get_value("vols", "sig", "")) == _cover_sig():
			var got = cfg.get_value("vols", "all", {})
			if got is Dictionary:
				_vols_disk.merge(got)
	if _vols_disk.has(era):
		return int(_vols_disk[era])
	var n := 1
	if era in SERIES:
		n = maxi(1, int(ceil(float(pool(era).size()) / VOLUME_SIZE)))
	else:
		# (the Type, Element and Beyond packs: volumes of up to BIG_VOLUME cards, 0.55.0)
		n = maxi(1, int(ceil(float(pool(era).size()) / BIG_VOLUME)))
	_vols_disk[era] = n
	var save := ConfigFile.new()
	save.load(COVERS_FILE)
	var keep := _vols_disk.duplicate()
	keep.erase("_")
	save.set_value("vols", "sig", _cover_sig())
	save.set_value("vols", "all", keep)
	save.save(COVERS_FILE)
	return n


var _vols_disk := {}


## The volumes of one set as shop entries (just the set itself when it is small enough).
func volumes(era: String) -> Array:
	var base := {}
	for p in PACKS:
		if str(p["key"]) == era:
			base = p
	var n := volume_count(era)
	if n <= 1 or base.is_empty():
		return [] if base.is_empty() else [base]
	var out := []
	for v in n:
		var e: Dictionary = base.duplicate()
		e["key"] = "%s#%d" % [era, v + 1]
		e["vol"] = v + 1
		e["vols"] = n
		e["color"] = (base["color"] as Color).lerp(Color.WHITE if v % 2 == 0 else Color.BLACK, 0.06 * (v % 3))
		out.append(e)
	return out


## Every volume of every split set.
func all_volumes() -> Array:
	var out := []
	for era in SERIES + BIG_PACKS:
		if volume_count(era) > 1:
			out += volumes(era)
	return out


## What the shop puts on its shelves: the split sets as their volumes.
func shop_packs() -> Array:
	var out := []
	var bundled := false
	for p in PACKS:
		var k := str(p["key"])
		if FAMILIES.has(k) and bundle_of(k) != "":
			# (a family's cards are sold in its bundle: one bigger pack for several related families)
			if not bundled:
				bundled = true
				for b in BUNDLES:
					out.append(bundle_pack(b))
			continue
		if (k in SERIES or k in BIG_PACKS) and volume_count(k) > 1:
			out += volumes(k)
		else:
			out.append(p)
	return out


# ---- Bundles (0.55.0). A family pack held 10 to 100 cards, too few to be worth a shelf of its
# own, so related families of one era are sold together in a pack of about 120 to 250 cards.
# Each family keeps its theme deck and its album page; "b_dm_dragons" is a bundle's key.
const BUNDLES := [
	{"key": "b_dm_dragons", "era": "Duel Monsters", "name": "Legends of Dragons and Magic", "color": Color("6a7ad8"),
		"blurb": "Blue-Eyes and Red-Eyes with all their support, Dark Magician and his school of magic, and the dragon-slaying swordsman with Jinzo and the Legendary Knights.",
		"families": ["blue_eyes", "red_eyes", "dark_magician", "legends_king"]},
	{"key": "b_dm_kingdom", "era": "Duel Monsters", "name": "Kingdom of Wonders", "color": Color("e0a050"),
		"blurb": "Kuriboh and its cousins, the Magnet Warriors and the Harpies, the Toons of Toon World, and Exodia with Batteryman and the Gadgets.",
		"families": ["kuriboh", "toon", "exodia"]},
	{"key": "b_dm_fiends", "era": "Duel Monsters", "name": "Fiends and Curses", "color": Color("8a2a5a"),
		"blurb": "The Archfiends and their court, the fallen Darklords, and the masks and old curses that wear a duelist down.",
		"families": ["archfiend", "darklord", "mask"]},
	{"key": "b_dm_guardians", "era": "Duel Monsters", "name": "Guardians and Warriors", "color": Color("c08a3a"),
		"blurb": "The Amazons, the Gravekeepers of the Valley of the Kings, the Gate Guardians and their weapons, the Union machines and the Jurrac dinosaurs.",
		"families": ["amazoness", "gravekeeper", "guardian", "union", "jurrac"]},
	{"key": "b_dm_dimensions", "era": "Duel Monsters", "name": "Chaos and Other Dimensions", "color": Color("7a5ad8"),
		"blurb": "The Envoys of Chaos, the D.D. monsters of the other dimension, the Spirits of the old shrine, the goblin gang and the toys that come alive.",
		"families": ["chaos", "dd", "spirit", "goblin", "toy"]},
	{"key": "b_gx_heroes", "era": "GX", "name": "Heroes, Gems and Machines", "color": Color("d84a4a"),
		"blurb": "Every kind of HERO and their fusions, the seven Crystal Beasts and their rainbow, and the Cyber Dragons and Cyberdarks.",
		"families": ["hero", "crystal_beast", "cyber"]},
	{"key": "b_gx_dark", "era": "GX", "name": "Dark Powers", "color": Color("6a3a9a"),
		"blurb": "The Fiends of Dark World, the Vampire Kingdom, the three Sacred Beasts, the Arcana Force tarot and the Monarchs.",
		"families": ["dark_world", "vampire", "sacred_beast", "arcana_force", "monarchs"]},
	{"key": "b_gx_iron", "era": "GX", "name": "Iron and Fire", "color": Color("b07a4a"),
		"blurb": "The Ancient Gear machines, the Koa'ki Meiru with their iron cores, the Alien invaders, the Barrier Statues and Counter Fairies, and the Volcanics.",
		"families": ["ancient_gear", "koaki_meiru", "alien", "barrier", "volcanic"]},
	{"key": "b_gx_arena", "era": "GX", "name": "Arena of Beasts", "color": Color("5a9a5a"),
		"blurb": "The Gladiator Beasts, the Armed Dragons and every LV monster, the Cloudians, Venoms and Fossils, and the Frogs and Penguins.",
		"families": ["gladiator", "armed_dragon", "cloudian", "frog"]},
	{"key": "b_5d_junk", "era": "5D's", "name": "Junk and Gears", "color": Color("e0a020"),
		"blurb": "The Synchrons, Junk and Blackwings, the T.G. machines, the Morphtronics, the Scraps and the Meklord Emperors with the Earthbound Immortals.",
		"families": ["synchron", "tg", "morphtronic", "scrap", "meklord"]},
	{"key": "b_5d_blade", "era": "5D's", "name": "Way of the Blade", "color": Color("c04a3a"),
		"blurb": "The Six Samurai and their Shien, the X-Sabers, the Karakuri puppets and the Genex machines.",
		"families": ["six_samurai", "x_saber", "karakuri", "genex"]},
	{"key": "b_5d_skies", "era": "5D's", "name": "Light and Wind", "color": Color("8ab4d8"),
		"blurb": "The Lightsworn, the Dragunity, the Fabled, the Fortune Ladies, the Gusto, the Vylon angels and the Nordic gods.",
		"families": ["lightsworn", "dragunity", "fabled", "fortune_lady", "gusto", "vylon", "nordic"]},
	{"key": "b_5d_elements", "era": "5D's", "name": "Ice, Forest and Flame", "color": Color("4ab0a0"),
		"blurb": "The Ice Barrier, the Naturia of the forest, the Laval and Flamvell of the fire, and the Gishki rituals of the water.",
		"families": ["ice_barrier", "naturia", "laval", "flamvell", "gishki"]},
	{"key": "b_5d_invaders", "era": "5D's", "name": "Invaders from Beyond", "color": Color("6a8a4a"),
		"blurb": "The Worm aliens, the Steelswarm and the Infestation, the Reptilianne, the Watt monsters and the Ally of Justice machines.",
		"families": ["worm", "swarm", "reptilianne", "watt", "ally_justice"]},
	{"key": "b_zx_knights", "era": "ZEXAL", "name": "Knights and Stars", "color": Color("e0c050"),
		"blurb": "The Heroic Challengers, the Noble Knights of the round table, the Constellar stars, the Battlin' Boxers and the Gem-Knights.",
		"families": ["heroic", "noble_knight", "constellar", "battlin_boxer", "gem_knight"]},
	{"key": "b_zx_gods", "era": "ZEXAL", "name": "Gods and Dragons", "color": Color("d86a2a"),
		"blurb": "The Bujin, the Hieratic dragons of the sun, the Dragon Rulers, the Evoltile and Evolsaur, the Fire Fist, the Hazy Flame and Fire Kings, and the Artifacts.",
		"families": ["bujin", "hieratic", "dragon_ruler", "evol", "fire_fist", "hazy", "artifact"]},
	{"key": "b_zx_tricks", "era": "ZEXAL", "name": "Toys, Tricks and Spellbooks", "color": Color("b05ad8"),
		"blurb": "The Madolche sweets, the Wind-Up toys, the Ghostrick spooks, the Gimmick Puppets and the Spellbooks of Prophecy.",
		"families": ["madolche", "wind_up", "ghostrick", "gimmick_puppet", "spellbook"]},
	{"key": "b_zx_hidden", "era": "ZEXAL", "name": "Hidden Worlds", "color": Color("3a8a8a"),
		"blurb": "The Chronomaly relics, the Ninjas, the Mermails, the Inzektor and the Sylvan, the Phantom Beasts, the Geargia and Trains, and the Heraldic Beasts.",
		"families": ["chronomaly", "ninja", "mermail", "inzektor", "sylvan", "phantom_beast", "gears", "heraldic"]},
]
## Packs big enough to come in volumes of BIG_VOLUME cards (the Type, Element and Beyond packs).
const BIG_PACKS := ["beyond", "dragons", "warriors", "arcane", "shadow", "machines", "wild", "tide", "gale", "forest", "spells", "traps"]
const BIG_VOLUME := 280


## The bundle a family is sold in ("" if none).
func bundle_of(family: String) -> String:
	for b in BUNDLES:
		if (b["families"] as Array).has(family):
			return str(b["key"])
	return ""


static func is_bundle(key: String) -> bool:
	return key.begins_with("b_")


## A bundle as a shop entry (tab 1, priced like the family packs).
func bundle_pack(b: Dictionary) -> Dictionary:
	return {"key": b["key"], "tab": 1, "name": b["name"], "color": b["color"], "blurb": b["blurb"], "era": b["era"], "bundle": true, "families": b["families"]}


## The key unlocks and shelves are decided by: a volume's set, a bundle's first family.
static func unlock_key(key: String) -> String:
	key = base_key(key)
	if is_bundle(key):
		for b in BUNDLES:
			if str(b["key"]) == key:
				return str(b["families"][0])
	return key


## A pack's name as the shop shows it ("Legend of the King Vol. 2").
static func pack_title(pack: Dictionary) -> String:
	var t := Loc.t(str(pack.get("name", "")))
	if int(pack.get("vol", 0)) > 0:
		t += " Vol. %d" % int(pack["vol"])
	return t


func release_rank(id: int) -> int:
	if _release.is_empty():
		var f := FileAccess.open("res://data/release_order.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				for k in d:
					_release[int(k)] = int(d[k])
		if _release.is_empty():
			_release[0] = 0
	# (Cards with no number go last, by their own number.)
	return int(_release.get(id, 100000000 + (id % 100000000)))


func _volume_ids(key: String) -> Array:
	var era := base_key(key)
	var v := volume_of(key)
	# (0.72.3) The era in the order it came out is worked out once, not once per volume, and sorted
	# as plain numbers (release rank, then id): 25 volumes of New Frontier took a second together.
	var sk := "~order:" + era
	if not _pools.has(sk):
		var keys := PackedInt64Array()
		for id in pool(era):
			keys.append(release_rank(int(id)) * 268435456 + int(id))
		keys.sort()
		var ordered: Array = []
		for k in keys:
			ordered.append(int(k & 268435455))
		_pools[sk] = ordered
	var ids: Array = _pools[sk]
	var n := volume_count(era)
	var per := int(ceil(float(ids.size()) / n))
	return ids.slice((v - 1) * per, mini(ids.size(), v * per))
