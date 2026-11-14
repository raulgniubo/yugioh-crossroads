class_name CardEffects
## Monster effects as data. The rules engine (EffectRunner) reads these.
##
## Passives:  piercing, direct, direct_if, battle_immune, survive_once, double_attack, double_vs_def,
##            atk_attack, atk_direct, atk_attacked, atk_vs_def, atk_per, aura, def_after_attack, kill_def,
##            no_damage_involving, double_damage_attacked, name_as, summon_sick, attacked_to_def,
##            lose_if_alone, hand_empty_guard, no_tribute_if, special_hand_if
## Triggers:  summon (Normal), any_summon (Normal/Flip/Special), synchro, flip, kill (this destroyed a monster
##            by battle; the victim is the context), death (this was destroyed by battle), gy (sent from the
##            field to the GY), damage (this dealt battle damage to the opponent), standby, end
## Ignition:  "ignite": {"cost": ..., "cond": ..., "do": [...], "label": "..."}  once per turn, Main Phase
## Actions:   ["draw", n] ["damage", n] ["heal", n] ["damage_victim_atk"] ["damage_victim_def"]
##            ["damage_victim_level", per] ["search", filter] ["special", from, filter, pos, count]
##            ["gy_to_hand", filter, count] ["destroy", what] ["self_atk", n] ["perm_atk", n]
##            ["opp_half"] ["opp_zero"] ["opp_flip"] ["no_damage"] ["revive_self", pos] ["self_damage", n]
## Filters:   {"name", "has", "race", "attr", "max_lv", "lv", "max_atk", "min_atk", "not", "monster"}

const FX := {
	# ---- The Head Archivist's shelf
	"Apprentice Magician": {"note": "Destroyed by battle: Special Summon a Level 2 or lower Spellcaster from your Deck in Defense Position.", "death": [["special", "deck", {"race": "Spellcaster", "max_lv": 2}, "def", 1]]},
	"Breaker the Magical Warrior": {"note": "Normal Summoned: gains 300 ATK.", "summon": [["perm_atk", 300]]},
	"Dark Magician Girl": {"note": "Gains 300 ATK for every Dark Magician in the Graveyards.", "atk_per": ["gy_named:Dark Magician", 300]},
	"Magician of Faith": {"note": "Flip: draw 1 card.", "flip": [["draw", 1]]},
	# ---- Your partner
	"Lumen, Echo Spirit": {"note": "Normal Summoned: add 1 monster with 1500 or less ATK from your Deck to your hand. Destroyed by battle: you take no battle damage this turn.",
		"summon": [["search", {"max_atk": 1500}]], "death": [["no_battle_damage"]]},
	# ---- The Duelist's Vault: classic monsters from outside the story decks
	"Giant Rat": {"note": "Destroyed by battle and sent to the Graveyard: Special Summon a EARTH monster with 1500 or less ATK from your Deck in Attack Position.", "death": [["special", "deck", {"attr": "EARTH", "max_atk": 1500}, "atk", 1]]},
	"Shining Angel": {"note": "Destroyed by battle and sent to the Graveyard: Special Summon a LIGHT monster with 1500 or less ATK from your Deck in Attack Position.", "death": [["special", "deck", {"attr": "LIGHT", "max_atk": 1500}, "atk", 1]]},
	"Mother Grizzly": {"note": "Destroyed by battle and sent to the Graveyard: Special Summon a WATER monster with 1500 or less ATK from your Deck in Attack Position.", "death": [["special", "deck", {"attr": "WATER", "max_atk": 1500}, "atk", 1]]},
	"UFO Turtle": {"note": "Destroyed by battle and sent to the Graveyard: Special Summon a FIRE monster with 1500 or less ATK from your Deck in Attack Position.", "death": [["special", "deck", {"attr": "FIRE", "max_atk": 1500}, "atk", 1]]},
	"Flying Kamakiri #1": {"note": "Destroyed by battle and sent to the Graveyard: Special Summon a WIND monster with 1500 or less ATK from your Deck in Attack Position.", "death": [["special", "deck", {"attr": "WIND", "max_atk": 1500}, "atk", 1]]},
	"Masked Dragon": {"note": "Destroyed by battle and sent to the Graveyard: Special Summon a Dragon with 1500 or less ATK from your Deck.", "death": [["special", "deck", {"race": "Dragon", "max_atk": 1500}, "any", 1]]},
	"Troop Dragon": {"note": "Destroyed by battle and sent to the Graveyard: Special Summon another Troop Dragon from your Deck.", "death": [["special", "deck", {"name": "Troop Dragon"}, "any", 1]]},
	"Giant Germ": {"note": "Destroyed by battle and sent to the Graveyard: 500 damage to the opponent, then Special Summon up to 2 Giant Germs from your Deck in Attack Position.", "death": [["damage", 500], ["special", "deck", {"name": "Giant Germ"}, "atk", 2]]},
	"Man-Eater Bug": {"note": "Flip: destroy 1 monster on the field.", "flip": [["destroy", "best"]]},
	"Old Vindictive Magician": {"note": "Flip: destroy 1 monster your opponent controls.", "flip": [["destroy", "best"]]},
	"Poison Mummy": {"note": "Flip: 500 damage to the opponent.", "flip": [["damage", 500]]},
	"Needle Worm": {"note": "Flip: the opponent sends the top 5 cards of their Deck to the Graveyard.", "flip": [["opp_mill", 5]]},
	"Skull-Mark Ladybug": {"note": "Sent to the Graveyard: gain 1000 Life Points.", "gy": [["heal", 1000]]},
	"Cure Mermaid": {"note": "Your Standby Phase: gain 800 Life Points.", "standby": [["heal", 800]]},
	"Exiled Force": {"note": "Tribute this card: destroy 1 monster on the field.",
		"ignite": {"cost": "tribute_self", "do": [["destroy", "best"]], "label": "Tribute itself: destroy a monster"}},
	"Zaborg the Thunder Monarch": {"note": "Tribute Summoned: destroy 1 monster on the field.", "summon": [["destroy", "best"]]},
	"Airknight Parshath": {"note": "Piercing damage. Deals battle damage to the opponent: draw 1 card.", "piercing": true, "damage": [["draw", 1]]},
	"Spear Dragon": {"note": "Piercing damage. Changes to Defense Position after it attacks.", "piercing": true, "def_after_attack": true},
	"Dark Driceratops": {"note": "Piercing damage.", "piercing": true},
	"Goblin Attack Force": {"note": "Changes to Defense Position after it attacks.", "def_after_attack": true},
	"Giant Orc": {"note": "Changes to Defense Position after it attacks.", "def_after_attack": true},
	"Axe Dragonute": {"note": "Changes to Defense Position after it attacks.", "def_after_attack": true},
	"Hayabusa Knight": {"note": "Can attack twice each Battle Phase.", "double_attack": true},
	"Jinzo #7": {"note": "Can attack directly.", "direct": true},
	"Ooguchi": {"note": "Can attack directly.", "direct": true},
	"Rainbow Flower": {"note": "Can attack directly.", "direct": true},
	"Servant of Catabolism": {"note": "Can attack directly.", "direct": true},
	# ---- The last deck monsters that used to play without their effects
	"Sangan": {"note": "Sent from the field to the Graveyard: add a monster with 1500 or less ATK from your Deck to your hand.", "gy": [["search", {"max_atk": 1500}]]},
	"Mystic Tomato": {"note": "Destroyed by battle: Special Summon a DARK monster with 1500 or less ATK from your Deck.", "death": [["special", "deck", {"attr": "DARK", "max_atk": 1500}, "atk", 1]]},
	"Junk Synchron": {"note": "Normal Summoned: Special Summon a Level 2 or lower monster from your Graveyard in Defense Position.", "summon": [["special", "gy", {"max_lv": 2}, "def", 1]]},
	"Goblindbergh": {"note": "Normal Summoned: Special Summon a Level 4 or lower monster from your hand, then this card changes to Defense Position.", "summon": [["special", "hand", {"max_lv": 4}, "any", 1], ["to_def"]]},
	"Max Warrior": {"note": "Gains 400 ATK while it attacks a monster.", "atk_attack": 400},
	"Gogogo Golem": {"note": "Once per turn, in Defense Position, it is not destroyed by battle.", "survive_once_def": true},
	"Drillago": {"note": "Can attack directly if every monster your opponent controls is face-up with 1600 or more ATK.", "direct_if": "opp_all_1600"},
	"Winged Kuriboh": {"note": "Destroyed and sent to the Graveyard: you take no battle damage for the rest of the turn.", "death": [["no_battle_damage"]], "gy": [["no_battle_damage"]]},
	"Speed Warrior": {"note": "Normal Summoned: its ATK is doubled this turn.", "summon": [["self_atk", 900]]},
	"Nitro Warrior": {"note": "If you activated a Spell this turn, its first attack gains 1000 ATK.", "nitro": true},
	"Battle Fader": {"note": "From your hand, when the opponent attacks you directly: Special Summon it and end the Battle Phase. Banished when it leaves the field.", "banish_when_leaves": true},
	"Shield Warrior": {"note": "From your Graveyard, when your monster is attacked: banish this card and that monster is not destroyed by this battle."},
	"Cyber Eltanin": {"note": "Special Summon from your hand by banishing every LIGHT Machine from your field and Graveyard: 500 ATK for each, and every other face-up monster goes to the Graveyard.", "eltanin": true},
	# ---- Banishing (removed from play)
	"D.D. Warrior Lady": {"note": "Destroyed by battle: banishes itself and the monster that destroyed it.", "death": [["banish_killer_and_self"]]},
	"D.D. Assailant": {"note": "Destroyed by battle: banishes itself and the monster that destroyed it.", "death": [["banish_killer_and_self"]]},
	"D.D. Warrior": {"note": "Destroyed by battle: banishes itself and the monster that destroyed it.", "death": [["banish_killer_and_self"]]},
	"Kycoo the Ghost Destroyer": {"note": "Deals battle damage: banish up to 2 monsters from the opponent's Graveyard.", "damage": [["banish_opp_gy", 2]]},
	"Bazoo the Soul-Eater": {"note": "Once per turn: banish up to 3 monsters from your Graveyard, gain 300 ATK for each this turn.",
		"ignite": {"cost": "none", "do": [["banish_own_gy_boost", 3, 300]], "label": "Banish up to 3 from your GY: +300 ATK each"}},
	"Chaos Sorcerer": {"note": "Special Summon by banishing 1 LIGHT and 1 DARK monster from your Graveyard. Once per turn: banish a face-up monster (it can't attack this turn).",
		"special_banish_ld": true,
		"ignite": {"cost": "none", "do": [["banish", "best"], ["no_attack_turn"]], "label": "Banish a monster (no attack this turn)"}},
	"Black Luster Soldier - Envoy of the Beginning": {"note": "Special Summon by banishing 1 LIGHT and 1 DARK monster from your Graveyard. Once per turn: banish a monster (it can't attack this turn).",
		"special_banish_ld": true,
		"ignite": {"cost": "none", "do": [["banish", "best"], ["no_attack_turn"]], "label": "Banish a monster (no attack this turn)"}},
	"Dark Armed Dragon": {"note": "Special Summon while you have exactly 3 DARK monsters in your Graveyard. Once per turn, banish a DARK monster from your Graveyard: destroy a card.",
		"special_hand_if": "gy_dark3",
		"ignite": {"cost": "banish_gy_dark", "do": [["destroy", "best_any"]], "label": "Banish a DARK from your GY: destroy a card"}},
	"Caius the Shadow Monarch": {"note": "Tribute Summoned: banish a card. If it was a DARK monster, 1000 damage.",
		"summon": [["banish", "best_any"], ["damage_if_banished_dark", 1000]]},
	"Gren Maju Da Eiza": {"note": "Gains 400 ATK for each of your banished cards.", "atk_per": ["own_banished", 400]},
	"Helios - The Primordial Sun": {"note": "Gains 100 ATK for each banished monster.", "atk_per": ["all_banished_monsters", 100]},
	"Banisher of the Light": {"note": "While face-up, cards sent to the Graveyard are banished instead.", "banish_redirect": true},
	"Banisher of the Radiance": {"note": "While face-up, cards sent to the Graveyard are banished instead.", "banish_redirect": true},
	"Dimensional Alchemist": {"note": "Destroys a monster by battle: that monster is banished.", "kill": [["banish_victim"]]},
	"Freed the Brave Wanderer": {"note": "Once per turn, banish a monster from your Graveyard: destroy a weaker monster.",
		"ignite": {"cost": "banish_gy_monster", "do": [["destroy", "atk_below_self"]], "label": "Banish from your GY: destroy a weaker monster"}},
	# ---- Duel Monsters
	"Elemental HERO Flame Wingman": {"note": "Destroys a monster by battle: damage equal to its ATK.", "kill": [["damage_victim_atk"]]},
	"Elemental HERO Thunder Giant": {"note": "Once per turn, discard 1: destroy a monster with less original ATK.",
		"ignite": {"cost": "discard", "do": [["destroy", "atk_below_self"]], "label": "Discard 1: destroy a weaker monster"}},
	"Elemental HERO Rampart Blaster": {"note": "Can attack directly.", "direct": true},
	"Elemental HERO Bubbleman": {"note": "Summoned with no other cards in hand or on field: draw 2.",
		"any_summon": [["draw_if_alone", 2]], "special_hand_if": "only_card_in_hand"},
	"Alligator's Sword Dragon": {"note": "Can attack directly if the opponent only has EARTH, WATER or FIRE monsters.", "direct_if": "opp_only_ewf"},
	"Black Tyranno": {"note": "Can attack directly if the opponent only has Defense Position monsters.", "direct_if": "opp_all_def"},
	"Leghul": {"note": "Can attack directly.", "direct": true},
	"Mystic Lamp": {"note": "Can attack directly.", "direct": true},
	"Big Jaws": {"note": "Strong for its level."},
	"Big Piece Golem": {"note": "No tribute needed if you have no monsters and the opponent does.", "no_tribute_if": "opp_only"},
	"Medium Piece Golem": {"note": "Summoned: Special Summon a Level 3 or lower EARTH monster from the Deck.",
		"any_summon": [["special", "deck", {"attr": "EARTH", "max_lv": 3}, "atk", 1]]},
	"Harpie Lady 1": {"note": "All WIND monsters gain 300 ATK. Counts as Harpie Lady.", "aura": ["WIND", 300], "name_as": "Harpie Lady"},
	"Harpie Lady 2": {"note": "Counts as Harpie Lady.", "name_as": "Harpie Lady"},
	"Harpie Lady 3": {"note": "Counts as Harpie Lady.", "name_as": "Harpie Lady"},
	"Cyber Harpie Lady": {"note": "Counts as Harpie Lady.", "name_as": "Harpie Lady"},
	"Harpie Queen": {"note": "Counts as Harpie Lady.", "name_as": "Harpie Lady"},
	"Harpie Channeler": {"note": "Once per turn, discard 1: Special Summon a Harpie from the Deck in Defense.", "name_as": "Harpie Lady",
		"ignite": {"cost": "discard", "do": [["special", "deck", {"has": "Harpie", "not": "Harpie Channeler"}, "def", 1]], "label": "Discard 1: call a Harpie from the Deck"}},
	"Harpie's Pet Dragon": {"note": "Gains 300 ATK for each Harpie Lady on the field.", "atk_per": ["field_named:Harpie Lady", 300]},
	"Birdface": {"note": "Destroyed by battle: add a Harpie Lady from the Deck.", "death": [["search", {"has": "Harpie Lady"}]]},
	"Dark Ruler Ha Des": {"note": "Strong Fiend boss."},
	"Dark Necrofear": {"note": "A Fiend boss with high DEF."},
	"Pumpking the King of Ghosts": {"note": "Gains 100 ATK during each of your Standby Phases.", "standby": [["perm_atk", 100]]},
	"Gernia": {"note": "Destroyed: comes back at your next Standby (simplified: revives in Defense right away once).", "gy": [["revive_self", "def"]]},
	"Makyura the Destructor": {"note": "Sent to the GY: draw 1.", "gy": [["draw", 1]]},
	"Granadora": {"note": "Summoned: gain 1000 LP. Destroyed: you take 2000 damage.", "any_summon": [["heal", 1000]], "gy": [["self_damage", 2000]]},
	"Gokipon": {"note": "Destroyed by battle: add an Insect with 1500 or less ATK from the Deck.", "death": [["search", {"race": "Insect", "max_atk": 1500}]]},
	"Insect Queen": {"note": "Gains 200 ATK for each Insect on the field.", "atk_per": ["field_race_all:Insect", 200]},
	"Pinch Hopper": {"note": "Sent to the GY: Special Summon an Insect from your hand.", "gy": [["special", "hand", {"race": "Insect"}, "atk", 1]]},
	"Cyber Kirin": {"note": "Tribute it: no damage this turn.", "ignite": {"cost": "tribute_self", "do": [["no_damage"]], "label": "Tribute: take no damage this turn"}},
	"Toon Cannon Soldier": {"note": "Tribute another monster: 500 damage. Can attack directly, not the turn it's summoned.", "direct": true, "summon_sick": true,
		"ignite": {"cost": "tribute_other", "do": [["damage", 500]], "label": "Tribute a monster: 500 damage"}},
	"Toon Dark Magician Girl": {"note": "Attacks directly unless the opponent has a Toon.", "direct": true, "summon_sick": true},
	"Toon Gemini Elf": {"note": "Attacks directly. Deals damage: the opponent discards a random card.", "direct": true, "summon_sick": true, "damage": [["opp_discard", 1]]},
	"Toon Goblin Attack Force": {"note": "Attacks directly; switches to Defense after attacking.", "direct": true, "summon_sick": true, "def_after_attack": true},
	"Toon Masked Sorcerer": {"note": "Attacks directly. Deals damage: draw 1.", "direct": true, "summon_sick": true, "damage": [["draw", 1]]},
	"Toon Mermaid": {"note": "Attacks directly.", "direct": true, "summon_sick": true},
	"Toon Summoned Skull": {"note": "Attacks directly.", "direct": true, "summon_sick": true},
	"Stone Statue of the Aztecs": {"note": "Battle damage the attacker takes from attacking it is doubled.", "double_damage_attacked": true},
	"Revival Jam": {"note": "Destroyed by battle: pay 1000 LP to bring it back in Defense.", "death": [["pay_revive", 1000]]},
	"Viser Des": {"note": "Can't be destroyed by battle.", "battle_immune": true},
	"Vampire Lord": {"note": "Deals battle damage: the opponent sends the top card of their Deck to the GY.", "damage": [["opp_mill", 1]]},
	"Y-Dragon Head": {"note": "Gives 400 ATK to another Machine you control (simplified union).", "aura_own_race": ["Machine", 400]},
	"Z-Metal Tank": {"note": "Gives 600 ATK to another Machine you control (simplified union).", "aura_own_race": ["Machine", 600]},
	"XYZ-Dragon Cannon": {"note": "Once per turn, discard 1: destroy one of the opponent's cards.",
		"ignite": {"cost": "discard", "do": [["destroy", "best_any"]], "label": "Discard 1: destroy an opponent's card"}},
	"Armed Dragon LV3": {"note": "Standby: level up into Armed Dragon LV5 from hand or Deck.", "standby": [["level_up", "Armed Dragon LV5"]]},
	"Armed Dragon LV5": {"note": "Discard a monster: destroy a monster with ATK up to the discarded one's.",
		"ignite": {"cost": "discard_monster", "do": [["destroy", "atk_below_discard"]], "label": "Discard a monster: destroy a weaker one"},
		"end": [["level_up_if_killed", "Armed Dragon LV7"]]},
	"Armed Dragon LV7": {"note": "Discard a monster: destroy all opponent's monsters with ATK up to it.",
		"ignite": {"cost": "discard_monster", "do": [["destroy", "all_atk_below_discard"]], "label": "Discard a monster: wipe weaker monsters"}},
	"Dragon Piper": {"note": "Flip: all Dragons switch to Attack Position.", "flip": [["all_dragons_attack"]]},
	"Gilasaurus": {"note": "Can be Special Summoned from your hand.", "special_hand_if": "always"},
	"Vice Dragon": {"note": "Special Summon from hand if only the opponent has monsters (half stats).", "special_hand_if": "opp_only", "half_if_special": true},
	"Snipe Hunter": {"note": "Once per turn, discard 1: roll a die; on 2-5 destroy an opponent's card.",
		"ignite": {"cost": "discard", "do": [["dice_destroy"]], "label": "Discard 1: roll to destroy a card"}},
	"Lord Poison": {"note": "Destroyed by battle: revive a Plant from your GY.", "death": [["special", "gy", {"race": "Plant", "not": "Lord Poison"}, "atk", 1]]},
	"Mad Sword Beast": {"note": "Piercing damage.", "piercing": true},
	"Bowganian": {"note": "Your Standby Phase: 600 damage to the opponent.", "standby": [["damage", 600]]},
	"Stygian Street Patrol": {"note": "Destroys a monster by battle: damage = its Level x 100.", "kill": [["damage_victim_level", 100]]},

	# ---- GX
	"Cyber Twin Dragon": {"note": "Can attack twice each Battle Phase.", "double_attack": true},
	"Cyber End Dragon": {"note": "Piercing damage.", "piercing": true},
	"Proto-Cyber Dragon": {"note": "Counts as Cyber Dragon on the field.", "name_as": "Cyber Dragon"},
	"Cyber Dragon Zwei": {"note": "Gains 300 ATK when it attacks a monster. Counts as Cyber Dragon in the GY.", "atk_attack": 300, "name_as": "Cyber Dragon"},
	"Cyber Barrier Dragon": {"note": "Once per turn in Attack Position, negates the opponent's attack.", "negate_attack_once": true},
	"Cyber Phoenix": {"note": "Destroyed by battle: draw 1.", "death": [["draw", 1]]},
	"Cyber Larva": {"note": "Destroyed by battle: Special Summon another Cyber Larva from the Deck.", "death": [["special", "deck", {"name": "Cyber Larva"}, "def", 1]],
		"no_damage_involving": true},
	"Cyber Valley": {"note": "Tribute it: draw 1.", "ignite": {"cost": "tribute_self", "do": [["draw", 1]], "label": "Tribute: draw 1"}},
	"Cyber Blader": {"note": "Can't be destroyed by battle while the opponent has 1 monster; ATK doubles with 2.", "blader": true},
	"Cyber Gymnast": {"note": "Once per turn, discard 1: destroy an Attack Position monster.",
		"ignite": {"cost": "discard", "do": [["destroy", "best_atk_pos"]], "label": "Discard 1: destroy an Attack Position monster"}},
	"Cyber Prima": {"note": "Tribute Summoned: destroy all face-up Spells.", "summon": [["destroy", "all_faceup_spells"]]},
	"Cyber Tutu": {"note": "Can attack directly if all the opponent's monsters are stronger.", "direct_if": "opp_all_stronger"},
	"Etoile Cyber": {"note": "Gains 500 ATK when attacking directly.", "atk_direct": 500},
	"Cyber Petit Angel": {"note": "Summoned: add a Cyber Angel from the Deck.", "any_summon": [["search", {"has": "Cyber Angel"}]]},
	"Cyber Angel Benten": {"note": "Destroys a monster by battle: damage equal to its DEF.", "kill": [["damage_victim_def"]]},
	"Cyber Angel Dakini": {"note": "Summoned: the opponent sends a monster to the GY. Piercing.", "any_summon": [["destroy", "weakest"]], "piercing": true},
	"Cyber Angel Idaten": {"note": "Summoned: gains 1000 ATK.", "any_summon": [["perm_atk", 1000]]},
	"Destiny HERO - Captain Tenacious": {"note": "A small D-HERO."},
	"Destiny HERO - Dasher": {"note": "Tribute another monster: +1000 ATK this turn. Goes to Defense after attacking.", "def_after_attack": true,
		"ignite": {"cost": "tribute_other", "do": [["self_atk", 1000]], "label": "Tribute a monster: +1000 ATK"}},
	"Destiny HERO - Defender": {"note": "A tough wall."},
	"Destiny HERO - Diamond Dude": {"note": "Once per turn: if the top card is a Spell, draw it.",
		"ignite": {"cost": "none", "do": [["top_spell_draw"]], "label": "Check the top card"}},
	"Destiny HERO - Disk Commander": {"note": "Special Summoned: draw 2 (once per duel).", "special_only": [["draw_once", 2]]},
	"Destiny HERO - Doom Lord": {"note": "Once per turn: remove an opponent's monster (it's destroyed here). Can't attack that turn.",
		"ignite": {"cost": "none", "do": [["destroy", "best"], ["no_attack_turn"]], "label": "Remove a monster"}},
	"Destiny HERO - Dunker": {"note": "Discard 1: 500 damage.", "ignite": {"cost": "discard", "do": [["damage", 500]], "label": "Discard 1: 500 damage"}},
	"Destiny HERO - Malicious": {"note": "Sent to the GY: Special Summon another Malicious from the Deck.", "gy": [["special", "deck", {"name": "Destiny HERO - Malicious"}, "def", 1]]},
	"Granmarg the Rock Monarch": {"note": "Tribute Summoned: destroy a set card.", "summon": [["destroy", "set_st"]]},

	# ---- 5D's
	"Stardust Dragon": {"note": "Once per turn, survives destruction by battle.", "survive_once": true},
	"Red Dragon Archfiend": {"note": "Attacks a Defense monster: destroy all the opponent's Defense monsters.", "kill_def_all": true},
	"Black Rose Dragon": {"note": "Synchro Summoned: destroy every other card on the field.", "synchro": [["destroy", "all_field_other"]]},
	"Junk Warrior": {"note": "Synchro Summoned: gains the ATK of your Level 2 or lower monsters.", "synchro": [["junk_warrior"]]},
	"Exploder Dragonwing": {"note": "Battles a weaker monster: destroy it and deal damage equal to its ATK.", "kill": [["damage_victim_atk"]]},
	"Blackwing Armor Master": {"note": "Can't be destroyed by battle; you take no damage from its battles.", "battle_immune": true, "no_damage_involving": true},
	"Blackwing Armed Wing": {"note": "Gains 500 ATK attacking a Defense monster; piercing.", "atk_vs_def": 500, "piercing": true},
	"Blackwing - Bora the Spear": {"note": "Piercing. Special Summon from hand if you control a Blackwing.", "piercing": true, "special_hand_if": "own_has:Blackwing"},
	"Blackwing - Gale the Whirlwind": {"note": "Special Summon from hand if you control a Blackwing. Once per turn: halve a monster's ATK.",
		"special_hand_if": "own_has:Blackwing", "ignite": {"cost": "none", "do": [["opp_half"]], "label": "Halve a monster's ATK"}},
	"Blackwing - Shura the Blue Flame": {"note": "Destroys a monster by battle: Special Summon a Blackwing (1500 ATK or less) from the Deck.",
		"kill": [["special", "deck", {"has": "Blackwing", "max_atk": 1500}, "atk", 1]]},
	"Blackwing - Sirocco the Dawn": {"note": "No tribute if you have no monsters and the opponent does.", "no_tribute_if": "opp_only"},
	"Blackwing - Elphin the Raven": {"note": "No tribute if you control a Blackwing. Summoned: switch an opponent's monster's position.",
		"no_tribute_if": "own_has:Blackwing", "summon": [["opp_flip"]]},
	"Blackwing - Fane the Steel Chain": {"note": "Can attack directly. Deals damage: an opponent's monster goes to Defense.", "direct": true, "damage": [["opp_to_def"]]},
	"Blackwing - Blizzard the Far North": {"note": "Normal Summoned: revive a Level 4 or lower Blackwing in Defense.",
		"summon": [["special", "gy", {"has": "Blackwing", "max_lv": 4}, "def", 1]]},
	"Blackwing - Kalut the Moon Shadow": {"note": "A Blackwing tuner."},
	"Blackwing - Vayu the Emblem of Honor": {"note": "A Blackwing tuner."},
	"Twilight Rose Knight": {"note": "Normal Summoned: Special Summon a Level 4 or lower Plant from your hand.",
		"summon": [["special", "hand", {"race": "Plant", "max_lv": 4}, "atk", 1]]},
	"Botanical Lion": {"note": "Gains 300 ATK for each Plant you control.", "atk_per": ["own_race:Plant", 300]},
	"Lonefire Blossom": {"note": "Tribute a Plant you control: Special Summon a Plant from the Deck.",
		"ignite": {"cost": "tribute_plant", "do": [["special", "deck", {"race": "Plant"}, "atk", 1]], "label": "Tribute a Plant: call one from the Deck"}},
	"Evil Thorn": {"note": "Tribute it: 300 damage, then Special Summon up to 2 Evil Thorn from the Deck.",
		"ignite": {"cost": "tribute_self", "do": [["damage", 300], ["special", "deck", {"name": "Evil Thorn"}, "atk", 2]], "label": "Tribute: 300 damage + more Thorns"}},
	"Revival Rose": {"note": "A Plant tuner support."},
	"Rose Tentacles": {"note": "Destroys a Plant by battle: 300 damage.", "kill": [["damage_if_victim_race", "Plant", 300]]},
	"Splendid Rose": {"note": "Once per turn: halve an opponent's monster's ATK.", "ignite": {"cost": "none", "do": [["opp_half"]], "label": "Halve a monster's ATK"}},
	"Copy Plant": {"note": "A Plant tuner."},
	"Dark Verger": {"note": "A Plant tuner."},
	"Phoenixian Seed": {"note": "A Plant support."},
	"Barrier Resonator": {"note": "A tuner."},
	"Dark Resonator": {"note": "Once per turn, survives destruction by battle.", "survive_once": true},
	"Nitro Synchron": {"note": "Used for a Synchro: draw 1.", "material": [["draw", 1]]},
	"Sinister Sprocket": {"note": "Used for a Synchro: destroy a face-up Spell/Trap.", "material": [["destroy", "set_st"]]},
	"Quillbolt Hedgehog": {"note": "Special Summon from your hand while you control a tuner.", "special_hand_if": "own_tuner"},
	"Batteryman AA": {"note": "Gains 1000 ATK for each Batteryman AA you control.", "atk_per": ["own_named:Batteryman AA", 1000]},
	"T.G. Blade Blaster": {"note": "A huge Synchro."},
	"Infernity Archfiend": {"note": "Special Summoned: add an Infernity card from the Deck.", "special_only": [["search", {"has": "Infernity"}]]},
	"Infernity Beast": {"note": "A hand-empty attacker."},
	"Infernity Guardian": {"note": "With an empty hand it can't be destroyed by battle.", "hand_empty_guard": true},
	"Infernity Dwarf": {"note": "With an empty hand, your monsters deal piercing damage.", "piercing_if": "hand_empty"},
	"Infernity Necromancer": {"note": "Summoned in Defense. With an empty hand: once per turn revive an Infernity.",
		"summon": [["to_def"]], "ignite": {"cost": "none", "cond": "hand_empty", "do": [["special", "gy", {"has": "Infernity", "not": "Infernity Necromancer"}, "atk", 1]], "label": "Revive an Infernity"}},
	"Infernity Mirage": {"note": "With an empty hand, tribute it: revive 2 Infernity monsters.",
		"ignite": {"cost": "tribute_self", "cond": "hand_empty", "do": [["special", "gy", {"has": "Infernity"}, "atk", 2]], "label": "Tribute: revive 2 Infernity"}},
	"Infernity Knight": {"note": "Destroyed: comes back in Defense if your hand has 2+ cards (discarding 2).", "gy": [["revive_self_discard2"]]},
	"Infernity Avenger": {"note": "A tuner for empty-hand decks."},
	"Infernity Doom Dragon": {"note": "With an empty hand, once per turn: destroy a monster and deal half its ATK.",
		"ignite": {"cost": "none", "cond": "hand_empty", "do": [["destroy_half_damage"], ["no_attack_turn"]], "label": "Destroy a monster, burn half its ATK"}},
	"Gyroid": {"note": "Once per turn, survives destruction by battle.", "survive_once": true},
	"Steamroid": {"note": "+500 ATK when it attacks, -500 when attacked.", "atk_attack": 500, "atk_attacked": -500},
	"Drillroid": {"note": "Attacks a Defense monster: destroy it right away.", "kill_def": true},
	"Submarineroid": {"note": "Can attack directly.", "direct": true},
	"Super Vehicroid Jumbo Drill": {"note": "Piercing damage.", "piercing": true},
	"Truckroid": {"note": "Destroys a monster by battle: gains its ATK.", "kill": [["gain_victim_atk"]]},
	"Expressroid": {"note": "Summoned: add 2 roid monsters from the GY to the hand.", "any_summon": [["gy_to_hand", {"has": "roid", "not": "Expressroid"}, 2]]},
	"Rescueroid": {"note": "A roid helper."},
	"Jetroid": {"note": "A roid wall."},
	"Patroid": {"note": "A roid scout."},
	"Mad Archfiend": {"note": "Piercing damage.", "piercing": true},
	"Juragedo": {"note": "Tribute it: one of your monsters gains 1000 ATK this turn.",
		"ignite": {"cost": "tribute_self", "do": [["best_own_atk", 1000]], "label": "Tribute: +1000 ATK to a monster"}},
	"Gagaga Magician": {"note": "A Level-changing Spellcaster."},
	"Gagaga Cowboy": {"note": "Detach 1: gains 1000 ATK this turn.", "ignite": {"cost": "detach", "do": [["self_atk", 1000]], "label": "Detach: +1000 ATK"}},

	# ---- ZEXAL
	"Number 17: Leviathan Dragon": {"note": "Detach 1: gains 500 ATK.", "ignite": {"cost": "detach", "do": [["perm_atk", 500]], "label": "Detach: +500 ATK"}},
	"Number 32: Shark Drake": {"note": "A Rank 4 shark boss."},
	"Number 43: Manipulator of Souls": {"note": "A Rank 2 Number."},
	"Number 62: Galaxy-Eyes Prime Photon Dragon": {"note": "Detach 1 in battle: gains 200 ATK per Rank of Xyz monsters on the field.", "atk_attack": 1600},
	"Number 65: Djinn Buster": {"note": "A Rank 2 Number."},
	"Black Ray Lancer": {"note": "Detach 1: negate a monster (its ATK becomes 0 here).", "ignite": {"cost": "detach", "do": [["opp_zero"]], "label": "Detach: zero a monster's ATK"}},
	"Starliege Paladynamo": {"note": "Detach 2: an opponent's monster's ATK becomes 0.", "ignite": {"cost": "detach2", "do": [["opp_zero"]], "label": "Detach 2: zero a monster's ATK"}},
	"Cat Shark": {"note": "Can't be destroyed by battle.", "battle_immune": true},
	"Galaxy-Eyes Photon Dragon": {"note": "Special Summon from hand by tributing 2 monsters with 2000+ ATK.", "special_tribute2": 2000},
	"Galaxy Knight": {"note": "No tribute if you control a Photon or Galaxy monster.", "no_tribute_if": "own_has:Photon|Galaxy"},
	"Galaxy Soldier": {"note": "Special Summoned: add a Galaxy monster from the Deck.", "special_only": [["search", {"has": "Galaxy"}]]},
	"Photon Crusher": {"note": "Switches to Defense after it attacks.", "def_after_attack": true},
	"Photon Thrasher": {"note": "Special Summon from hand while you control no monsters.", "special_hand_if": "own_none"},
	"Photon Sabre Tiger": {"note": "Summoned: add another Photon Sabre Tiger. Loses 800 ATK without a partner.",
		"any_summon": [["search", {"name": "Photon Sabre Tiger"}]], "lose_if_alone": 800},
	"Photon Lizard": {"note": "Tribute it: add a Level 4 or lower Photon from the Deck.",
		"ignite": {"cost": "tribute_self", "do": [["search", {"has": "Photon", "max_lv": 4}]], "label": "Tribute: search a Photon"}},
	"Photon Leo": {"note": "Normal Summoned: the opponent shuffles their hand away and redraws.", "summon": [["opp_redraw"]]},
	"Photon Cerberus": {"note": "A Photon monster."},
	"Double Shark": {"note": "Can attack twice each Battle Phase.", "double_attack": true},
	"Spear Shark": {"note": "Piercing damage.", "piercing": true},
	"Hammer Shark": {"note": "Once per turn: Special Summon a Level 3 or lower WATER monster from your hand.",
		"ignite": {"cost": "none", "do": [["special", "hand", {"attr": "WATER", "max_lv": 3}, "atk", 1]], "label": "Call a WATER monster"}},
	"Eagle Shark": {"note": "No tribute if the opponent has 2+ monsters.", "no_tribute_if": "opp_two"},
	"Sharkraken": {"note": "Special Summon from hand by tributing a WATER monster.", "special_tribute_attr": "WATER"},
	"Shark Stickers": {"note": "A Fish helper."},
	"Saber Shark": {"note": "A Level-changing shark."},
	"Skull Kraken": {"note": "Normal Summoned: destroy a set Spell/Trap.", "summon": [["destroy", "set_st"]]},
	"Twin-Sword Marauder": {"note": "Piercing; attacks twice against Defense monsters.", "piercing": true, "double_vs_def": true},
	"Umbral Horror Ghost": {"note": "Special Summon from your hand; then call a Level 4 or lower Fiend from your hand too.",
		"special_hand_if": "always", "special_only": [["special", "hand", {"race": "Fiend", "max_lv": 4}, "atk", 1]]},
	"Umbral Horror Ghoul": {"note": "Once per turn: its ATK becomes 0 to Special Summon an Umbral Horror (0 ATK) from hand.",
		"ignite": {"cost": "none", "do": [["self_atk_zero"], ["special", "hand", {"has": "Umbral Horror", "max_atk": 0}, "atk", 1]], "label": "Call an Umbral Horror"}},
	"Umbral Horror Unform": {"note": "Destroyed by battle: Special Summon 2 Umbral Horror from the Deck.", "death": [["special", "deck", {"has": "Umbral Horror"}, "atk", 2]]},
	"Umbral Horror Will o' the Wisp": {"note": "Destroyed by battle in Attack Position: destroy the monster that destroyed it.", "death": [["destroy_killer"]]},
}


static func of(name: String) -> Dictionary:
	return FX.get(name, {})


static func has(name: String) -> bool:
	return FX.has(name) and not FX[name].is_empty()


## Does a card match a filter dictionary?
static func matches(d: Dictionary, f: Dictionary) -> bool:
	if f.get("monster", true) and (d.get("kind", "monster") != "monster" or str(d.get("frame", "")) in ["spell", "trap"]):
		return false
	if f.has("frame") and str(d.get("frame", "")) != f["frame"]:
		return false
	var n := str(d.get("name", ""))
	var alias := str(of(n).get("name_as", ""))
	if f.has("name") and n != f["name"] and alias != f["name"]:
		return false
	if f.has("not") and n == f["not"]:
		return false
	if f.has("has"):
		var ok := false
		for part in str(f["has"]).split("|"):
			if n.contains(part) or alias.contains(part):
				ok = true
		if not ok:
			return false
	if f.has("race") and str(d.get("race", "")) != f["race"]:
		return false
	if f.has("attr") and str(d.get("attribute", "")) != f["attr"]:
		return false
	if f.has("max_lv") and int(d.get("level", 0)) > int(f["max_lv"]):
		return false
	if f.has("lv") and int(d.get("level", 0)) != int(f["lv"]):
		return false
	if f.has("max_atk") and int(d.get("atk", 0)) > int(f["max_atk"]):
		return false
	if f.has("min_atk") and int(d.get("atk", 0)) < int(f["min_atk"]):
		return false
	return true
