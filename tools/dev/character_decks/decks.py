D = {}
def deck(key, who, era, idea, m, s, t, e, keep='', out=''):
    D[key] = dict(who=who, era=era, idea=idea, m=m, s=s, t=t, e=e, keep=keep, out=out)

# ---------------- Duel Monsters ----------------
deck('yugi', 'Yugi', 'Duel Monsters',
 "Pure Dark Magician. Magician's Rod and Magicians' Souls find Dark Magician every game, Dark Magical Circle banishes a card each time he arrives, and Eternal Soul keeps bringing him back.",
 "Dark Magician x3|Dark Magician Girl|Magician's Rod x3|Magicians' Souls x3|Apprentice Illusion Magician x2|Illusion of Chaos x2|Timaeus the United Dragon|Magikuriboh|Palladium Oracle Mahad",
 "Dark Magical Circle x3|Soul Servant x3|Magician's Salvation x2|Secrets of Dark Magic|The Eye of Timaeus|Bond Between Teacher and Student|Illusion Magic|Pot of Greed|Graceful Charity|Monster Reborn",
 "Eternal Soul x3|Magician Navigation x3|Mirror Force|Magic Cylinder",
 "Dark Magician the Dragon Knight|Amulet Dragon|Dark Magician Girl the Dragon Knight|The Dark Magicians x2|Dark Cavalry|Master of Chaos|Dark Paladin|Ebon Illusion Magician x2|Ebon High Magician|Magi Magi ☆ Magician Gal|Number 11: Big Eye|Mecha Phantom Beast Dracossack|Quintet Magician",
 keep="Dark Magician, Dark Magician Girl, Dark Paladin, Mirror Force, Magic Cylinder",
 out="Slifer, the three Knights, the Magnet Warriors, Buster Blader, Kuriboh, Skilled Dark Magician")

deck('kaiba', 'Kaiba', 'Duel Monsters',
 "Blue-Eyes with all of its modern support. Sage with Eyes of Blue and the White Stones put a 3000 ATK dragon on the field on turn one, and two Level 8 dragons make Rank 8 Xyz or Blue-Eyes Spirit Dragon.",
 "Blue-Eyes White Dragon x3|Blue-Eyes Alternative White Dragon x2|Blue-Eyes Jet Dragon|Blue-Eyes Abyss Dragon|Dragon Spirit of White|Sage with Eyes of Blue x3|Maiden of White x2|Neo Kaiser Sea Horse|Dictator of D. x2|The White Stone of Ancients x3|The White Stone of Legend",
 "Wishes for Eyes of Blue x3|Roar of the Blue-Eyed Dragons x2|The Melody of Awakening Dragon x2|Trade-In x2|Bingo Machine, Go!!! x2|Ultimate Fusion|Return of the Dragon Lords|Pot of Greed|Monster Reborn",
 "True Light|Majesty of the White Dragons x2|The Ultimate Creature of Destruction|Crush Card Virus",
 "Blue-Eyes Spirit Dragon x2|Blue-Eyes Ultimate Spirit Dragon x2|Azure-Eyes Silver Dragon|Blue-Eyes Twin Burst Dragon|Neo Blue-Eyes Ultimate Dragon|Blue-Eyes Tyrant Dragon|Blue-Eyes Ultimate Dragon|Indigo-Eyes Silver Dragon|Number 38: Hope Harbinger Dragon Titanic Galaxy|Thunder End Dragon|Hieratic Sun Dragon Overlord of Heliopolis|Number 97: Draglubion|Divine Dragon Knight Felgrand",
 keep="Blue-Eyes White Dragon x3, Blue-Eyes Ultimate Dragon, Crush Card Virus",
 out="Obelisk, Vorse Raider, Kaibaman, Lord of D., Vampire Lord, Chaos Emperor Dragon, Blue-Eyes Shining Dragon")

deck('joey', 'Joey', 'Duel Monsters',
 "Red-Eyes Fusion. Red-Eyes Fusion uses monsters straight from the Deck, so one card makes Red-Eyes Slash Dragon or Meteor Black Comet Dragon. The Black Stone of Legend and Red-Eyes Insight keep the dragons coming.",
 "Red-Eyes Black Dragon x3|Red-Eyes Black Flare Dragon x2|Meteor Dragon Red-Eyes Impact|Red-Eyes Baby Dragon x2|Red-Eyes Wyvern|The Black Stone of Legend x3|Red-Eyes Darkness Metal Dragon|Gearfried the Red-Eyes Iron Knight|Black Metal Dragon|Summoned Skull|Red-Eyes Black Fullmetal Dragon",
 "Red-Eyes Fusion x3|Red-Eyes Insight x3|Cards of the Red Stone x2|Dragon Shrine x2|Inferno Fire Blast|Foolish Burial|Scapegoat|Pot of Greed|Graceful Charity|Monster Reborn",
 "Red-Eyes Spirit x2|Return of the Red-Eyes x2|Red-Eyes Burn|Max Metalmorph x2",
 "Red-Eyes Slash Dragon x2|Meteor Black Comet Dragon x2|Archfiend Black Skull Dragon x2|Black Skull Dragon|Red-Eyes Flare Metal Dragon x2|Number 11: Big Eye|Mecha Phantom Beast Dracossack|Odd-Eyes Absolute Dragon|Number 42: Galaxy Tomahawk|Number 74: Master of Blades|Gaia Dragon, the Thunder Charger",
 keep="Red-Eyes Black Dragon x3, Black Skull Dragon, Summoned Skull, Scapegoat, the Metalmorph idea (now Max Metalmorph)",
 out="Time Wizard, Baby Dragon, the dice cards, Jinzo, Gilford, Goblin Attack Force, Panther Warrior")

deck('mai', 'Mai', 'Duel Monsters',
 "Harpies that swarm and make Rank 4 Xyz. Every Harpie searches or summons another one, Hysteric Sign fetches three cards when it is sent to the Graveyard, and Harpie's Feather Storm shuts down the other side's monster effects for a turn.",
 "Harpie Channeler x3|Harpie Harpist x3|Harpie Perfumer x3|Harpie Dancer x3|Harpie Queen x3|Harpie Oracle x2|Harpie's Pet Dragon|Harpie's Pet Dragon - Fearsome Fire Blast|Harpie's Pet Baby Dragon",
 "Hysteric Sign x3|Elegant Egotist x2|Harpies' Hunting Ground x2|Harpie's Feather Duster|Harpie's Feather Rest|Harpie Lady Phoenix Formation|Swallow's Nest|Pot of Greed|Monster Reborn",
 "Harpie's Feather Storm x3|Hysteric Party x2|Icarus Attack x2",
 "Steelswarm Roach|Harpie's Pet Phantasmal Dragon x2|Lightning Chidori x2|Ice Beast Zerofyne|Castel, the Skyblaster Musketeer|Abyss Dweller|Daigusto Emeral|Diamond Dire Wolf|Tornado Dragon|Evilswarm Exciton Knight|Gagaga Cowboy|Number 50: Blackship of Corn|Dark Rebellion Xyz Dragon",
 keep="Harpie Channeler, Harpie Queen, Harpie's Pet Dragon, Elegant Egotist, Hunting Ground, Feather Duster, Hysteric Party",
 out="the Amazoness cards (they have their own deck now), Birdface, Cyber Shield, Gravity Bind, Mirror Wall")

deck('bakura', 'Bakura', 'Duel Monsters',
 "Fiends that fill the Graveyard for Dark Necrofear, with Destiny Board as a second way to win. Dark Spirit's Mastery searches either plan, and Tour Guide makes Rank 3 Xyz while it sets up.",
 "Dark Necrofear x3|Curse Necrofear|Dark Spirit of Malice|Dark Spirit of Banishment|Diabound Kernel x2|Tour Guide From the Underworld x2|Sangan|Fiendish Rhino Warrior x2|Absolute King Back Jack x2|Lilith, Lady of Lament x2|Morphing Jar",
 "Dark Spirit's Mastery x3|Dark Sanctuary|Spirit Message \"I\"|Spirit Message \"N\"|Spirit Message \"A\"|Spirit Message \"L\"|Allure of Darkness x2|Change of Heart|Pot of Greed|Monster Reborn",
 "Destiny Board x2|Sentence of Doom x2|Fiend Griefing x2|Torrential Tribute|Mirror Force|Call of the Haunted",
 "Dante, Traveler of the Burning Abyss|Leviair the Sea Dragon|Wind-Up Zenmaines|Ghostrick Alucard|Mechquipped Angineer|Number 30: Acid Golem of Destruction|Number 17: Leviathan Dragon|Number 23: Lancelot, Dark Knight of the Underworld|Number 22: Zombiestein|Number 68: Sanaphond the Sky Prison",
 keep="Dark Necrofear x3, Destiny Board and the Spirit Messages, Dark Sanctuary, Diabound Kernel, Change of Heart",
 out="Headless Knight, The Earl of Demise, The Portrait's Secret, Man-Eater Bug, Dark Ruler Ha Des, Earthbound Spirit")

deck('marik', 'Marik', 'Duel Monsters',
 "The Winged Dragon of Ra, built so Ra really comes out. The Slimes are the Tributes (Marik's Revival Jam idea, upgraded), Ancient Chant searches Ra and gives an extra Normal Summon, and Lava Golem and Sphere Mode eat the other side's monsters.",
 "The Winged Dragon of Ra x2|The Winged Dragon of Ra - Sphere Mode|The Winged Dragon of Ra - Immortal Phoenix|Guardian Slime x3|Reactor Slime x3|Revival Jam|Lava Golem x3|Ra's Disciple x2|Makyura the Destructor|Juragedo",
 "Ancient Chant x3|The True Sun God x2|Millennium Revelation|Blaze Cannon|Soul Crossing|Mystical Space Typhoon|Swords of Revealing Light|Dark Hole|Raigeki|Pot of Greed|Monster Reborn",
 "Metal Reflect Slime x3|Sun God Unification|Nightmare Wheel|Torrential Tribute|Mirror Force|Call of the Haunted",
 "Egyptian God Slime x3|Superdreadnought Rail Cannon Gustav Max|Number 35: Ravenous Tarantula|Skypalace Gangaridai",
 keep="The Winged Dragon of Ra, Lava Golem, Revival Jam, Metal Reflect Slime, Makyura, Nightmare Wheel",
 out="Helpoemer, Newdoria, Drillago, Viser Des, Gil Garth, Coffin Seller, Jam Defender and the other torture cards")

deck('pegasus', 'Pegasus', 'Duel Monsters',
 "Toons that attack directly, with Toon Kingdom protecting them and Toon Bookmark and Table of Contents finding every piece. Instant Fusion makes Thousand-Eyes Restrict or Millennium-Eyes Restrict out of nothing to steal a monster.",
 "Red-Eyes Toon Dragon x3|Toon Harpie Lady x3|Toon Dark Magician x2|Toon Dark Magician Girl x2|Toon Cyber Dragon x2|Toon Black Luster Soldier|Toon Gemini Elf|Blue-Eyes Toon Dragon|Toon Summoned Skull",
 "Toon Table of Contents x3|Toon Bookmark x3|Toon Kingdom x3|Toon Page-Flip x2|Toon World|Instant Fusion x2|Terraforming|Pot of Greed|Monster Reborn",
 "Toon Terror x3|Fiendish Chain|Mirror Force|Torrential Tribute|Call of the Haunted",
 "Thousand-Eyes Restrict x2|Millennium-Eyes Restrict x2|Number 11: Big Eye|Mecha Phantom Beast Dracossack|Red-Eyes Flare Metal Dragon|Ebon Illusion Magician|Castel, the Skyblaster Musketeer|Abyss Dweller|Evilswarm Exciton Knight|Diamond Dire Wolf|Tornado Dragon|Gagaga Cowboy",
 keep="Toon World, Toon Kingdom, Blue-Eyes Toon Dragon, Toon Summoned Skull, Toon Dark Magician Girl, Thousand-Eyes Restrict",
 out="Relinquished and Black Illusion Ritual (Thousand-Eyes Restrict now comes from Instant Fusion), Toon Mermaid, Toon Goblin Attack Force")

deck('weevil', 'Weevil', 'Duel Monsters',
 "Insects that replace themselves. Resonance Insect and Gokipole search the big bugs, the Beetroopers swarm and fuse, and Insect Queen stays with her upgraded form, and four Insects fuse into a 4000 ATK Absolute Hercules that nothing can touch.",
 "Resonance Insect x3|Gokipole x3|Beetrooper Scout Buggy x3|Beetrooper Assault Roller x3|Beetrooper Sting Lancer x2|Beetrooper Scale Bomber x2|Beetrooper Light Flapper|Heavy Beetrooper Mighty Neptune|Insect Queen|Metamorphosed Insect Queen|Doom Dozer|Retaliating \"C\"",
 "Beetrooper Landing x2|Beetrooper Formation x2|Beetrooper Descent x2|Verdant Sanctuary x2|Insect Barrier|Pot of Greed|Monster Reborn|Dark Hole",
 "Beetrooper Fly & Sting x2|Beetrooper Squad|Mirror Force|Torrential Tribute|Call of the Haunted",
 "Ultra Beetrooper Absolute Hercules x2|Beetrooper Cruel Saturnas x2|Number 20: Giga-Brilliant|Number 3: Cicada King|Number 70: Malevolent Sin|Number 28: Titanic Moth|Number 11: Big Eye|Mecha Phantom Beast Dracossack|Leviair the Sea Dragon|Wind-Up Zenmaines|Mechquipped Angineer|Abyss Dweller|Castel, the Skyblaster Musketeer",
 keep="Insect Queen, Insect Barrier",
 out="Perfectly Ultimate Great Moth, Petit Moth and Cocoon of Evolution (too slow to ever come out), Man-Eater Bug, DNA Surgery, Parasite Paracide, Pinch Hopper")

deck('rex', 'Rex', 'Duel Monsters',
 "Modern Dinosaurs. The baby dinosaurs summon big ones from the Deck when they are destroyed, Souleating Oviraptor and Fossil Dig search anything, and Ultimate Conductor Tyranno flips the whole field face-down and attacks everything.",
 "Souleating Oviraptor x3|Miscellaneousaurus x3|Babycerasaurus x3|Petiteranodon x3|Giant Rex x3|Ultimate Conductor Tyranno x3|Megalosmasher X x2|Overtex Qoatlus|Animadorned Archosaur|Xeno Meteorus|Super Conductor Tyranno",
 "Fossil Dig x3|Lost World x3|Terraforming|Dark Hole|Pot of Greed|Monster Reborn",
 "Survival's End x3|Mirror Force|Torrential Tribute|Call of the Haunted",
 "Evolzar Laggia x2|Evolzar Dolkka x2|Tornado Dragon|Castel, the Skyblaster Musketeer|Abyss Dweller|Diamond Dire Wolf|Number 38: Hope Harbinger Dragon Titanic Galaxy|Number 97: Draglubion|Divine Dragon Knight Felgrand|Gachi Gachi Gantetsu|Sky Cavalry Centaurea|Herald of Pure Light|Number 107: Galaxy-Eyes Tachyon Dragon",
 keep="Super Conductor Tyranno, Babycerasaurus",
 out="Two-Headed King Rex, Black Tyranno, Tyrant Dragon, Serpent Night Dragon, Ultimate Tyranno, Sabersaurus, Jurassic World")

# ---------------- GX ----------------
deck('jaden', 'Jaden', 'GX',
 "HERO Fusion at full speed. Stratos, Vyon and Faris set up the Graveyard, then Polymerization, Miracle Fusion, Super Polymerization and Mask Change turn any two HEROes into the right boss for the moment.",
 "Elemental HERO Stratos x3|Vision HERO Vyon x3|Vision HERO Faris x2|Vision HERO Increase|Elemental HERO Shadow Mist x2|Elemental HERO Liquid Soldier x2|Elemental HERO Solid Soldier|Elemental HERO Blazeman x2|Elemental HERO Neos|Elemental HERO Honest Neos|Elemental HERO Spirit of Neos|Destiny HERO - Malicious",
 "E - Emergency Call x3|A Hero Lives x2|Polymerization x3|Miracle Fusion x2|Super Polymerization x2|Mask Change x2|Neos Fusion x2|Reinforcement of the Army|Pot of Greed|Monster Reborn",
 "Hero Signal",
 "Elemental HERO Sunrise x2|Elemental HERO Absolute Zero|Elemental HERO Great Tornado|Elemental HERO The Shining|Elemental HERO Nova Master|Elemental HERO Gaia|Elemental HERO Escuridao|Elemental HERO Brave Neos|Elemental HERO Flame Wingman - Infernal Rage|Wake Up Your Elemental HERO|Masked HERO Dark Law|Masked HERO Acid|Vision HERO Adoration|Vision HERO Trinity",
 keep="Elemental HERO Neos, Polymerization, Miracle Fusion, E - Emergency Call, Flame Wingman (in its upgraded form)",
 out="Avian, Burstinatrix, Clayman, Sparkman, Bubbleman, the Neo-Spacians and their contact Fusions, Winged Kuriboh")

deck('chazz', 'Chazz', 'GX',
 "Armed Dragon Thunder. Each Armed Dragon Thunder calls the next Level from the Deck, so LV3 becomes LV10 in one or two turns, and LV10 destroys a card every turn. Ojama Trio stays as his trap.",
 "Armed Dragon Thunder LV10 x2|Armed Dragon Thunder LV7 x3|Armed Dragon Thunder LV5 x3|Armed Dragon Thunder LV3 x3|Armed Dragon LV10 White|Armed Dragon LV10|Armed Dragon LV7|Pile Armed Dragon x2|Tempest, Dragon Ruler of Storms x2|Light and Darkness Dragon",
 "Armed Dragon Flash x3|Armed Dragon Blitz x2|Armed Dragon Lightning x2|Level Up!|Dragon Shrine x2|Foolish Burial|Heavy Storm|Pot of Greed|Monster Reborn",
 "Armed Dragon Thunderbolt x2|Ojama Trio x2|Mirror Force|Torrential Tribute|Call of the Haunted",
 "Number 11: Big Eye|Mecha Phantom Beast Dracossack|Red-Eyes Flare Metal Dragon|Odd-Eyes Absolute Dragon|Number 61: Volcasaurus|Tiras, Keeper of Genesis|Adreus, Keeper of Armageddon|Leviair the Sea Dragon|Wind-Up Zenmaines|Superdreadnought Rail Cannon Gustav Max",
 keep="Armed Dragon LV7 and LV10, Level Up!, Light and Darkness Dragon, Ojama Trio",
 out="the Ojama brothers and their Fusions, X-Head Cannon, Y-Dragon Head, Z-Metal Tank and the VWXYZ pieces")

deck('zane', 'Zane', 'GX',
 "Cyber Dragon. Cyber Dragon Core searches the whole deck, Power Bond and Overload Fusion end games in one attack, and two Level 5 Machines make Cyber Dragon Infinity, which negates one card every turn.",
 "Cyber Dragon x3|Cyber Dragon Core x3|Cyber Dragon Herz x3|Cyber Dragon Nachster x2|Cyber Dragon Vier|Cyber Dragon Drei|Galaxy Soldier x2|Cyber Eltanin",
 "Cyber Emergency x3|Cyber Repair Plant x2|Cybernetic Horizon x2|Power Bond x2|Overload Fusion x2|Machine Duplication x2|Cyber Revsystem|Cyberload Fusion|Limiter Removal|De-Fusion|Heavy Storm|Pot of Greed|Monster Reborn",
 "Cybernetic Overflow x3|Call of the Haunted",
 "Cyber End Dragon x2|Cyber Twin Dragon x2|Chimeratech Rampage Dragon x2|Chimeratech Overdragon|Chimeratech Fortress Dragon|Constellar Pleiades|Cyber Eternity Dragon|Cyber Dragon Nova x2|Cyber Dragon Infinity x2|Number 61: Volcasaurus",
 keep="Cyber Dragon x3, Cyber End Dragon, Cyber Twin Dragon, Chimeratech Overdragon, Power Bond, Limiter Removal, De-Fusion",
 out="the Cyberdark monsters, Cyber Barrier Dragon, Cyber Laser Dragon, Cyber Phoenix, Proto-Cyber Dragon")

deck('alexis', 'Alexis', 'GX',
 "Cyber Angel Rituals. Every Cyber Angel does something when it is Tributed, so each Ritual Summon also searches the next one, and Machine Angel Absolute Ritual recycles them from the Graveyard. Cyber Blader stays as a small package.",
 "Cyber Angel Benten x3|Cyber Angel Idaten x2|Cyber Angel Dakini x2|Cyber Angel Natasha|Cyber Angel Vrash|Cyber Angel Izana|Cyber Petit Angel x3|Cyber Egg Angel x2|Manju of the Ten Thousand Hands x3|Etoile Cyber|Blade Skater|Honest",
 "Machine Angel Ritual x3|Machine Angel Absolute Ritual x2|Pre-Preparation of Rites x3|Preparation of Rites|Ritual Sanctuary|Merciful Machine Angel|Magnificent Machine Angel|Incarnated Machine Angel|Polymerization|Pot of Greed|Monster Reborn",
 "Mirror Force|Torrential Tribute|Call of the Haunted",
 "Cyber Blader x2|Constellar Ptolemy M7|Photon Strike Bounzer|Number 38: Hope Harbinger Dragon Titanic Galaxy|Divine Dragon Knight Felgrand|Herald of Pure Light|Castel, the Skyblaster Musketeer",
 keep="Cyber Angel Benten, Idaten and Dakini, Machine Angel Ritual, Cyber Blader with Etoile Cyber and Blade Skater",
 out="Cyber Tutu, Cyber Gymnast, Cyber Prima, Doble Passe, Fusion Weapon, Ritual Weapon")

deck('syrus', 'Syrus', 'GX',
 "Vehicroids with their own search cards. Megaroid City finds any roid, Emergeroid Call negates a card while a roid Fusion is out, Vehicroid Connection Zone makes a Fusion that cannot be negated or destroyed, and Power Bond doubles it.",
 "Expressroid x3|Mixeroid x3|Submarineroid x2|Drillroid x2|Steamroid|Stealthroid|Truckroid|Armoroid|UFOroid|Ambulanceroid|Rescueroid|Cyber Dragon",
 "Megaroid City x3|Vehicroid Connection Zone x3|Power Bond x2|Polymerization x2|Terraforming|Limiter Removal|Pot of Greed|Monster Reborn",
 "Emergeroid Call x3|Supercharge x2|Mirror Force|Call of the Haunted|Torrential Tribute",
 "Super Vehicroid - Mobile Base x2|Barbaroid, the Ultimate Battle Machine|Super Vehicroid Jumbo Drill|Super Vehicroid - Stealth Union|Ambulance Rescueroid|Steam Gyroid|Pair Cycroid|UFOroid Fighter|Gear Gigant X x2|Castel, the Skyblaster Musketeer|Abyss Dweller|Tornado Dragon|Evilswarm Exciton Knight",
 keep="every roid he is known for, Power Bond, Super Vehicroid Jumbo Drill, Stealth Union, Steam Gyroid",
 out="Gyroid, Cycroid, Decoyroid, Shield Crush, Draining Shield, Negate Attack")

deck('aster', 'Aster', 'GX',
 "Destiny HERO around Fusion Destiny. One Spell sends two Destiny HEROes from the Deck and makes Destroyer Phoenix Enforcer, which destroys a card every turn and comes back when it dies. Vision HEROes (his manga deck) are the engine.",
 "Vision HERO Vyon x3|Vision HERO Faris x2|Vision HERO Increase|Destiny HERO - Malicious x2|Destiny HERO - Celestial x2|Destiny HERO - Denier x2|Destiny HERO - Dasher|Destiny HERO - Drawhand|Destiny HERO - Disk Commander|Destiny HERO - Dynatag|Destiny HERO - Diamond Dude|Destiny HERO - Plasma|Elemental HERO Stratos x2",
 "Fusion Destiny x3|Destiny Draw x2|E - Emergency Call x2|A Hero Lives x2|Allure of Darkness x2|Polymerization|Foolish Burial|Reinforcement of the Army|Pot of Greed|Monster Reborn",
 "D-Fusion x2|D - Tactics|Mirror Force",
 "Destiny HERO - Destroyer Phoenix Enforcer x3|Destiny HERO - Dangerous x2|Destiny HERO - Dystopia|Destiny HERO - Dusktopia|Destiny HERO - Dominance|Destiny End Dragoon|Vision HERO Adoration x2|Vision HERO Trinity|Elemental HERO Escuridao|Abyss Dweller|Castel, the Skyblaster Musketeer",
 keep="Destiny HERO - Plasma, Malicious, Diamond Dude, Dasher, Disk Commander, Destiny Draw, Destiny End Dragoon",
 out="Dogma, Dreadmaster, Doom Lord, Captain Tenacious, Double Dude, Clock Tower Prison and its traps")

# ---------------- 5D's ----------------
deck('yusei', 'Yusei', "5D's",
 "Synchron combo. Junk Synchron, Junk Converter and Doppelwarrior turn one Normal Summon into Junk Speeder, who summons a Tuner of every Level from the Deck. From there it climbs to Stardust Dragon, Shooting Star Dragon and Cosmic Blazar Dragon in one turn.",
 "Junk Synchron x3|Junk Converter x3|Doppelwarrior x3|Jet Synchron x2|Stardust Synchron x2|Assault Synchron x2|Revolution Synchron|Quickdraw Synchron|Synchron Carrier|Synchron Explorer|Stardust Trail|Level Eater x2|Tuningware x2|Quillbolt Hedgehog|Effect Veiler x2",
 "Tuning x3|Reinforcement of the Army x2|Stardust Illumination|One for One|Foolish Burial|Pot of Greed|Monster Reborn",
 "Scrap-Iron Scarecrow|Starlight Road|Graceful Revival",
 "Junk Speeder x2|Junk Warrior|Formula Synchron|T.G. Hyper Librarian|Stardust Charge Warrior|Accel Synchro Stardust Dragon|Stardust Dragon|Shooting Riser Dragon|Satellite Warrior|Shooting Star Dragon|Stardust Warrior|Cosmic Blazar Dragon|Shooting Quasar Dragon|Crimson Dragon",
 keep="Junk Synchron, Junk Warrior, Stardust Dragon, Shooting Star Dragon, Shooting Quasar Dragon, Formula Synchron, Quillbolt Hedgehog, Effect Veiler, Scrap-Iron Scarecrow, Starlight Road",
 out="Speed Warrior, Max Warrior, Shield Warrior, Debris Dragon, Majestic Dragon and Majestic Star Dragon, Junk Archer, Nitro Warrior, Turbo Warrior")

deck('jack', 'Jack', "5D's",
 "Resonators into Red Dragon Archfiend. Soul Resonator and Crimson Resonator turn one card into Red Rising Dragon, then into Hot Red Dragon Archfiend Abyss (negates an effect every turn) or Scarlight (wipes the field). Crimson Gaia searches whatever is missing.",
 "Soul Resonator x3|Crimson Resonator x3|Vision Resonator x3|Red Resonator x2|Synkron Resonator x2|Dark Resonator|Bone Archfiend x2|Wandering King Wildwind x2|Red Nova|Red Gardna",
 "Resonator Call x3|Crimson Gaia x3|Absolute Powerforce|Scarlet Security|One for One|Foolish Burial|Allure of Darkness|Pot of Greed|Monster Reborn",
 "Red Reign x2|Fiendish Chain x2|King's Synchro|Red Carpet|Call of the Haunted",
 "Red Rising Dragon x3|Red Dragon Archfiend|Scarlight Red Dragon Archfiend x2|Hot Red Dragon Archfiend Abyss x2|Hot Red Dragon Archfiend Bane|Hot Red Dragon Archfiend King Calamity|Red Nova Dragon|Tyrant Red Dragon Archfiend|Red Supernova Dragon|Scarred Dragon Archfiend|Crimson Dragon",
 keep="Red Dragon Archfiend, Scarlight, Red Nova Dragon, Dark Resonator, Synkron Resonator, Resonator Call, Scarlet Security, Fiendish Chain",
 out="Vice Dragon, Mad Archfiend, Twin-Sword Marauder, Big Piece Golem, Strong Wind Dragon, the Assault Mode cards, Majestic Red Dragon")

deck('crow', 'Crow', "5D's",
 "Blackwings that swarm from the hand. Simoon puts Black Whirlwind on the field for free, every summon searches another Blackwing, and the turn ends on Full Armor Master or Raikiri with Blackbird Close ready to negate from the hand.",
 "Blackwing - Simoon the Poison Wind x3|Blackwing - Gale the Whirlwind x3|Blackwing - Kris the Crack of Dawn x2|Blackwing - Oroshi the Squall x2|Blackwing - Vata the Emblem of Wandering x2|Blackwing - Shamal the Sandstorm x2|Blackwing - Kalut the Moon Shadow x2|Blackwing - Zephyros the Elite|Blackwing - Sudri the Phantom Glimmer|Blackwing - Harmattan the Dust|Blackwing - Steam the Cloak|Blackwing - Bora the Spear|Blackwing - Shura the Blue Flame|Blackwing - Chinook the Snow Blast",
 "Black Whirlwind x3|Allure of Darkness x2|Black Feather Whirlwind|Foolish Burial|Pot of Greed|Monster Reborn",
 "Blackbird Close x3|Delta Crow - Anti Reverse x2|Black Shadow Squall|Blackwing - Twin Shadow|Blackwing - Boobytrap",
 "Black-Winged Dragon|Black-Winged Assault Dragon|Blackwing Full Armor Master x2|Blackwing Armor Master|Assault Blackwing - Raikiri the Rain Shower x2|Assault Blackwing - Chidori the Rain Sprinkling|Assault Blackwing - Onimaru the Divine Thunder|Assault Blackwing - Sohaya the Rain Storm|Blackwing - Nothung the Starlight|Blackwing Tamer - Obsidian Hawk Joe|Blackwing - Boreastorm the Wicked Wind|Blackwing - Silverwind the Ascendant|Crimson Dragon",
 keep="Gale, Bora, Shura, Kalut, Black Whirlwind, Delta Crow - Anti Reverse, Black-Winged Dragon, Armor Master, Silverwind",
 out="Blizzard, Sirocco, Mistral, Fane, Ghibli, Elphin, Gust, Black Sonic, Blackback, Against the Wind")

deck('akiza', 'Akiza', "5D's",
 "Rose Dragons and Plants. Red Rose Dragon and Lonefire Blossom summon the rest from the Deck, Roxrose Dragon searches the Rose Spells, and every line ends on Black Rose Dragon or Ruddy Rose Dragon clearing the field.",
 "Red Rose Dragon x3|Roxrose Dragon x3|White Rose Dragon x2|Blue Rose Dragon|Lonefire Blossom x3|Twilight Rose Knight x2|Rose Fairy|Witch of the Black Rose|Rose Princess|Spore|Dandylion|Glow-Up Bulb|Copy Plant|Tytannial, Princess of Camellias",
 "Frozen Rose x3|Rose Bell of Revelation x2|Basal Rose Shoot|White Rose Cloister|One for One|Foolish Burial|Pot of Greed|Monster Reborn",
 "Blooming of the Darkest Rose x2|Wicked Rebirth|Urgent Tuning|Mirror Force|Torrential Tribute|Call of the Haunted",
 "Black Rose Dragon x2|Ruddy Rose Dragon x2|Black Rose Moonlight Dragon|Garden Rose Maiden x2|Garden Rose Flora x2|Queen of Thorns|Splendid Rose|Crimson Dragon|Meliae of the Trees",
 keep="Black Rose Dragon, Twilight Rose Knight, Lonefire Blossom, Rose Fairy, Witch of the Black Rose, Blue Rose Dragon, Tytannial, Queen of Thorns, Splendid Rose",
 out="Dark Verger, Evil Thorn, Lord Poison, Rose Tentacles, Phoenixian Seed and Cluster Amaryllis, Mark of the Rose, Thorn of Malice")

deck('kalin', 'Kalin', "5D's",
 "Infernity, played the way it is meant to be: empty the hand, then Infernity Archfiend, Necromancer and Launcher bring out the whole Graveyard. It ends on Void Ogre Dragon with Infernity Barrier and Suppression set to negate.",
 "Infernity Archfiend x3|Infernity Necromancer x3|Infernity Mirage x2|Infernity Beetle x2|Infernity Sage x2|Infernity Wildcat x2|Infernity Avenger|Infernity Destroyer|Infernity General|Stygian Street Patrol x2|Dark Grepher x2|Armageddon Knight",
 "Infernity Launcher x3|Allure of Darkness x2|Foolish Burial|Reinforcement of the Army|Pot of Greed|Monster Reborn",
 "Infernity Barrier x3|Infernity Break x2|Infernity Suppression x2|Infernity Inferno|Void Trap Hole",
 "Void Ogre Dragon x2|Hundred Eyes Dragon x2|Infernity Doom Dragon|Infernity Doom Archfiend|Beelze of the Diabolic Dragons|Lavalval Chain x2|Leviair the Sea Dragon|Abyss Dweller|Number 66: Master Key Beetle|Crimson Dragon",
 keep="Infernity Archfiend, Necromancer, Mirage, Beetle, Launcher, Barrier, Break, Infernity Doom Dragon, Void Ogre Dragon, Hundred Eyes Dragon",
 out="Infernity Guardian, Knight, Beast, Randomizer, Reflector, Force, ZERO-MAX, Full Salvo, Card Destruction")

# ---------------- ZEXAL ----------------
deck('yuma', 'Yuma', 'ZEXAL',
 "Utopia with the Gagaga, Gogogo, Dododo and Zubaba cards merged into two monsters that search and summon each other. It makes Utopia on turn one, then Utopia Double fetches Double or Nothing! and attacks twice with doubled ATK, which usually ends the duel.",
 "Zubababancho Gagagacoat x3|Dodododwarf Gogogoglove x3|Gagaga Magician x2|Gagaga Sister x2|Gagaga Girl x2|Utopic Onomatopoeia|ZS - Ascended Sage x2|ZS - Armed Sage|ZW - Pegasus Twin Saber|ZW - Sylphid Wing|ZW - Eagle Claw|Goblindbergh",
 "Onomatopaira x3|Onomatopickup x2|Zexal Construction x2|Zexal Entrust x2|Double or Nothing! x2|Rank-Up-Magic Zexal Force|Xyz Change Tactics|Reinforcement of the Army|Pot of Greed|Monster Reborn",
 "Xyz Reborn|Mirror Force|Torrential Tribute|Call of the Haunted",
 "Number 39: Utopia|Number 39: Utopia Double x2|Number S39: Utopia the Lightning|Number S39: Utopia Prime|Number 39: Utopia Rising|Number C39: Utopia Ray|Number 39: Utopia Beyond|Number 99: Utopic Dragon|Number 93: Utopia Kaiser|Number F0: Utopic Future|Number F0: Utopic Draco Future|ZW - Dragonic Halberd|Gagagaga Magician|Gagagaga Girl",
 keep="Number 39: Utopia and its upgrades, Gagaga Magician, Gagaga Girl, Goblindbergh, Onomatopaira, the ZW weapons (newer ones)",
 out="Gogogo Golem, Dododo Warrior, Zubaba Knight, Kagetokage, Gagaga Clerk, the old ZW weapons, Gagagabolt, Half Unbreak")

deck('shark', 'Shark', 'ZEXAL',
 "WATER Xyz that never stops summoning. Buzzsaw Shark, Lantern Shark and Abyss Shark each count as two materials or bring a friend, Bahamut Shark makes Toadally Awesome (negates and steals), and Number 101 takes a monster as material.",
 "Buzzsaw Shark x3|Lantern Shark x3|Abyss Shark x3|Crystal Shark x2|Silent Angler x2|Surfacing Big Jaws x2|Saber Shark|Double Fin Shark|Hammer Shark|Xyz Remora|Cyber Shark|Beautunaful Princess|Shark Stickers",
 "Surface x2|Torpedo Takedown x2|Salvage|Water Hazard|Moray of Greed|Rank-Up-Magic - The Seventh One|Rank-Up-Magic Barian's Force|Foolish Burial|Mystical Space Typhoon|Pot of Greed|Monster Reborn",
 "Torrential Tribute|Poseidon Wave|Xyz Reborn|Mirror Force|Call of the Haunted",
 "Bahamut Shark x2|Toadally Awesome|Number 101: Silent Honor ARK|Number C101: Silent Honor DARK|N.As.H. Knight|CXyz N.As.Ch. Knight|Number 4: Stealth Kragen|Number 71: Rebarian Shark|Number 37: Hope Woven Dragon Spider Shark|Valiant Shark Lancer|Number 32: Shark Drake|Number 73: Abyss Splash|Black Ray Lancer|Number 47: Nightmare Shark",
 keep="Number 101 and C101, Bahamut Shark, Shark Drake, Black Ray Lancer, Abyss Splash, Silent Angler, Hammer Shark, Double Fin Shark, Shark Stickers",
 out="Big Jaws, Skull Kraken, Jawsman, Needle Sunfish, Spear Shark, Depth Shark, Mermaid Shark, Eagle Shark, Panther Shark, Aqua Jet")

deck('kite', 'Kite', 'ZEXAL',
 "Galaxy-Eyes Photon Dragon every turn. Photon Orbital and Galaxy Wizard search it, Photon Sanctuary and Photon Vanisher pay for it, and two Level 8s make Number 62 or Photon Lord, then Full Armor Photon Dragon on top.",
 "Galaxy-Eyes Photon Dragon x3|Galaxy-Eyes Afterglow Dragon x2|Photon Orbital x3|Photon Vanisher x3|Galaxy Soldier x3|Galaxy Wizard x2|Photon Thrasher x2|Photon Advancer x2|Galaxy Knight|Galaxy Summoner|Photon Emperor|Galaxy Brave",
 "Photon Sanctuary x3|Galaxy Expedition x2|Trade-In x2|Galaxy Trance|Photon Hand|Accellight|Photon Stream of Destruction|Pot of Greed|Monster Reborn",
 "Eternal Galaxy|Photon Change|Mirror Force",
 "Number 62: Galaxy-Eyes Prime Photon Dragon x2|Neo Galaxy-Eyes Photon Dragon|Galaxy-Eyes Full Armor Photon Dragon x2|Number 90: Galaxy-Eyes Photon Lord x2|Galaxy-Eyes Cipher Dragon|Galaxy-Eyes Cipher Blade Dragon|Galaxy-Eyes Cipher X Dragon|Number 95: Galaxy-Eyes Dark Matter Dragon|Galaxy Photon Dragon|Starliege Photon Blast Dragon|Starliege Lord Galaxion|Number 38: Hope Harbinger Dragon Titanic Galaxy",
 keep="Galaxy-Eyes Photon Dragon x3, Neo Galaxy-Eyes, Number 62, Photon Thrasher, Galaxy Wizard, Galaxy Knight, Galaxy Soldier, Galaxy Expedition, Accellight",
 out="Daybreaker, Photon Crusher, Photon Caesar, Photon Lizard, Photon Leo, Photon Cerberus, Photon Pirate, Photon Sabre Tiger, Photon Slasher")

deck('vector', 'Vector', 'ZEXAL',
 "Two plans. Umbral Horrors still make Number 104 and rank it up, and Don Thousand's Numeron cards (he is inside Vector for the last arc) give a real finisher: Numeron Calling puts four Numbers on the field from the Extra Deck in one card.",
 "Umbral Horror Ghoul x3|Umbral Horror Unform x3|Umbral Horror Will o' the Wisp x3|Umbral Horror Ghost x2|Malicevorous Fork x2|Malicevorous Knife x2|Malicevorous Spoon|Numeron Wall",
 "Numeron Network x3|Numeron Calling x3|Terraforming|Allure of Darkness x2|Rank-Up-Magic Barian's Force|Rank-Up-Magic - The Seventh One|Mystical Space Typhoon|Dark Hole|Raigeki|Pot of Greed|Monster Reborn",
 "Fiendish Chain x2|Vain Betrayer|Dark Bribe|Mirror Force|Torrential Tribute|Call of the Haunted",
 "Number 104: Masquerade x2|Number C104: Umbral Horror Masquerade|Number 1: Numeron Gate Ekam|Number 2: Numeron Gate Dve|Number 3: Numeron Gate Trini|Number 4: Numeron Gate Catvari|Number C1: Numeron Chaos Gate Sunya|Number C1000: Numerounius|Number iC1000: Numerounius Numerounia|Number 66: Master Key Beetle|Number 96: Dark Mist|Number C96: Dark Storm|Number 65: Djinn Buster|Number C65: King Overfiend",
 keep="every Umbral Horror and Malicevorous, Number 104 and C104, Number 96 and C96, Number 65 and C65, Number 66, Barian's Force",
 out="Shadow Spell, Swords of Revealing Light, Book of Moon, Sakuretsu Armor, Number 43")
