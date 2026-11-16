class_name SpellRules
## Spell and Trap Cards as data, plus the rules that run them.
##
## k:    normal | quick | cont | field | equip | ritual        (Spells)
##       trap | ctrap (Continuous Trap) | counter               (Traps)
## win:  response windows a Trap / Quick-Play fits: "attack", "summon", "free" (any time)
## neg:  what a Counter Trap negates: "spell", "trap", "summon"
## t:    what the player targets (see targets())      cost: discard | lp500.. | half_lp | tribute
## do:   actions run when the card resolves (see _run())
## Passive keys for cards that stay on the field are read by the hooks at the bottom.

const PERSIST := ["cont", "field", "equip", "ctrap"]
const ATTRS := ["DARK", "LIGHT", "EARTH", "WATER", "FIRE", "WIND", "DIVINE"]

const FX := {
	# ---------------------------------------------------------------- Speed Spells (Turbo Duels)
	# "speed" is how many Speed Counters you must have; a "speedN" cost spends N of them.
	"Speed Spell - Full Throttle": {"k": "normal", "speed": 0, "do": [["speed", 2]]},
	"Speed Spell - Tailwind": {"k": "normal", "speed": 2, "do": [["draw", 1]]},
	"Speed Spell - Pit Stop": {"k": "normal", "speed": 2, "do": [["heal", 1200]]},
	"Speed Spell - Slipstream Strike": {"k": "quick", "speed": 3, "t": "any_face", "do": [["atk", "target", 800, "eot"]]},
	"Speed Spell - Twin Turbo": {"k": "normal", "speed": 4, "do": [["draw", 2], ["discard", 1]]},
	"Speed Spell - Afterburner": {"k": "normal", "speed": 4, "do": [["damage", 800]]},
	"Speed Spell - Road Clear": {"k": "quick", "speed": 5, "t": "any_st", "do": [["destroy", "target"]]},
	"Speed Spell - Overtake": {"k": "normal", "speed": 6, "cost": "speed3", "do": [["destroy", "opp_best_def"]]},
	"Speed Spell - Redline": {"k": "normal", "speed": 8, "cost": "speed6", "do": [["damage", 2000]]},
	"Speed Spell - Shockwave": {"k": "normal", "speed": 7, "cost": "speed4", "do": [["destroy", "opp_st"]]},
	# ---------------------------------------------------------------- Lumen's cards (cards of this game)
	"Echo Resonance": {"k": "normal", "cond": "echo_ready", "do": [["echo_resonance"]]},
	"Echo Call": {"k": "normal", "do": [["search", {"has": "Lumen"}]]},
	"Echo Veil": {"k": "trap", "win": ["attack"], "do": [["negate_attack"], ["draw_if_own", "Lumen", 1]]},
	# ---------------------------------------------------------------- Normal Spells
	"Heavy Storm": {"k": "normal", "do": [["destroy", "all_st"]]},
	"Harpie's Feather Duster": {"k": "normal", "do": [["destroy", "opp_st"]]},
	"Giant Trunade": {"k": "normal", "do": [["bounce", "all_st"]]},
	"Change of Heart": {"k": "normal", "t": "opp_mon", "do": [["control", "target", "eot"]]},
	"Brain Control": {"k": "normal", "t": "opp_face", "cost": "lp800", "do": [["control", "target", "eot"]]},
	"Mind Control": {"k": "normal", "t": "opp_mon", "do": [["control", "target", "eot"], ["no_attack", "target"], ["no_tribute", "target"]]},
	"Graceful Charity": {"k": "normal", "do": [["draw", 3], ["discard", 2]]},
	"Card Destruction": {"k": "normal", "do": [["card_destruction"]]},
	"Upstart Goblin": {"k": "normal", "do": [["draw", 1], ["opp_heal", 1000]]},
	"Jar of Greed": {"k": "trap", "win": ["free"], "do": [["draw", 1]]},
	"Pot of Avarice": {"k": "normal", "do": [["avarice"]]},
	"Tribute to The Doomed": {"k": "normal", "t": "any_mon", "cost": "discard", "do": [["destroy", "target"]]},
	"Lightning Vortex": {"k": "normal", "cost": "discard", "do": [["destroy", "opp_face_mons"]]},
	"Smashing Ground": {"k": "normal", "do": [["destroy", "opp_best_def"]]},
	"Hammer Shot": {"k": "normal", "do": [["destroy", "best_atk_any"]]},
	"Nobleman of Crossout": {"k": "normal", "t": "any_fdown", "do": [["banish", "target"], ["purge_copies", "flip"]]},
	"Nobleman of Extermination": {"k": "normal", "t": "any_set_st", "do": [["banish", "target"], ["purge_copies", "trap"]]},
	"Remove Trap": {"k": "normal", "t": "any_face_trap", "do": [["destroy", "target"]]},
	"Stop Defense": {"k": "normal", "t": "opp_def", "do": [["to_atk", "target"]]},
	"Shield Crush": {"k": "normal", "t": "opp_def", "do": [["destroy", "target"]]},
	"Ookazi": {"k": "normal", "do": [["damage", 800]]},
	"Tremendous Fire": {"k": "normal", "do": [["damage", 1000], ["self_damage", 500]]},
	"Sparks": {"k": "normal", "do": [["damage", 200]]},
	"Final Flame": {"k": "normal", "do": [["damage", 600]]},
	"Meteor of Destruction": {"k": "normal", "cond": "opp_lp_over:3000", "do": [["damage", 1000]]},
	"Poison of the Old Man": {"k": "quick", "modes": [{"label": "Gain 1200 LP", "do": [["heal", 1200]]}, {"label": "Inflict 800 damage to your opponent", "do": [["damage", 800]]}]},
	"Goblin's Secret Remedy": {"k": "normal", "do": [["heal", 600]]},
	"Red Medicine": {"k": "normal", "do": [["heal", 500]]},
	"Blue Medicine": {"k": "normal", "do": [["heal", 400]]},
	"Soul of the Pure": {"k": "normal", "do": [["heal", 800]]},
	"Foolish Burial": {"k": "normal", "do": [["bury"]]},
	"Reinforcement of the Army": {"k": "normal", "do": [["search", {"race": "Warrior", "max_lv": 4}]]},
	"Sangan's Call": {"k": "normal", "do": [["search", {"max_atk": 1500}]]},
	"E - Emergency Call": {"k": "normal", "ai": "always", "do": [["search", {"has": "Elemental HERO"}]]},
	"The Warrior Returning Alive": {"k": "normal", "do": [["gy_to_hand", {"race": "Warrior"}, 1]]},
	"Monster Reincarnation": {"k": "normal", "cost": "discard", "do": [["gy_to_hand", {"monster": true}, 1]]},
	"Dark Factory of Mass Production": {"k": "normal", "do": [["gy_to_hand", {"frame": "normal"}, 2]]},
	"Share the Pain": {"k": "normal", "cost": "tribute", "do": [["opp_tribute"]]},
	"Soul Exchange": {"k": "normal", "t": "opp_mon", "do": [["tribute_fodder", "target"]]},
	"Premature Burial": {"k": "equip", "cost": "lp800", "do": [["revive", "own_gy", "atk", "link"]]},
	"Miracle Fusion": {"k": "normal", "do": [["miracle_fusion", {"has": "Elemental HERO"}]]},
	"Card of Sanctity": {"k": "normal", "do": [["sanctity"]]},
	"Dian Keto the Cure Master": {"k": "normal", "do": [["heal", 1000]]},
	"Nightmare's Steelcage": {"k": "normal", "do": [["no_attacks_both", 2]]},
	"Book of Taiyou": {"k": "normal", "t": "any_fdown", "do": [["flip_up", "target"]]},
	"Dark Core": {"k": "normal", "t": "any_face", "cost": "discard", "do": [["banish", "target"]]},
	# ---------------------------------------------------------------- Quick-Play Spells
	"Mystical Space Typhoon": {"k": "quick", "t": "any_st", "do": [["destroy", "target"]]},
	"Scapegoat": {"k": "quick", "do": [["tokens", 4, "Sheep Token", 73915052, 0, 0, 1, "EARTH", "Beast"]]},
	"Forbidden Chalice": {"k": "quick", "t": "any_face", "dmg": true, "do": [["atk", "target", 400, "eot"], ["negate_fx", "target"]]},
	"Rush Recklessly": {"k": "quick", "t": "any_face", "do": [["atk", "target", 700, "eot"]]},
	"Shrink": {"k": "quick", "t": "any_face", "do": [["halve", "target"]]},
	"Book of Moon": {"k": "quick", "t": "any_face", "do": [["flip_down", "target"]]},
	"Enemy Controller": {"k": "quick", "modes": [
		{"label": "Change the battle position of 1 of their face-up monsters", "t": "opp_face", "do": [["change_pos", "target"]]},
		{"label": "Tribute 1 monster: take control of 1 of their face-up monsters until the End Phase", "t": "opp_face", "cost": "tribute", "do": [["control", "target", "eot"]]}]},
	"Ego Boost": {"k": "quick", "win": ["attack"], "any_attack": true, "t": "any_face", "do": [["atk", "target", 1000, "eot"]]},
	"Forbidden Lance": {"k": "quick", "t": "any_face", "do": [["atk", "target", -800, "eot"]]},
	"Offerings to the Doomed": {"k": "quick", "t": "any_face", "do": [["destroy", "target"], ["skip_draw", 1]]},
	"The Reliable Guardian": {"k": "quick", "t": "any_face", "do": [["def", "target", 700]]},
	"De-Fusion": {"k": "quick", "t": "any_fusion", "do": [["defusion"]]},
	# ---------------------------------------------------------------- Continuous Spells
	"Toon World": {"k": "cont", "cost": "lp1000", "ai": "toon_world"},
	"Banner of Courage": {"k": "cont", "bp_boost": 200},
	"Burning Land": {"k": "cont", "do": [["destroy", "fields"]], "each_standby": [["self_damage", 500]]},
	"Messenger of Peace": {"k": "cont", "lock_atk_min": 1500, "upkeep": 100},
	"Level Limit - Area B": {"k": "cont", "force_def_lv_min": 4, "do": [["to_def", "lv4_all"]]},
	"The Dark Door": {"k": "cont", "one_attack": true},
	"Dimensional Fissure": {"k": "cont", "redirect": "mon"},
	"Wave-Motion Cannon": {"k": "cont", "counter_standby": true, "cannon": 1000},
	"Solidarity": {"k": "cont", "atk_all": [{"monster": true}, 800, "own_same_race_gy"]},
	# ---------------------------------------------------------------- Field Spells
	"Yami": {"k": "field", "boost": [[{"race": "Fiend"}, 200, 200], [{"race": "Spellcaster"}, 200, 200], [{"race": "Fairy"}, -200, -200]]},
	"Sogen": {"k": "field", "boost": [[{"race": "Warrior"}, 200, 200], [{"race": "Beast-Warrior"}, 200, 200]]},
	"Forest": {"k": "field", "boost": [[{"race": "Insect"}, 200, 200], [{"race": "Beast"}, 200, 200], [{"race": "Plant"}, 200, 200], [{"race": "Beast-Warrior"}, 200, 200]]},
	"Mountain": {"k": "field", "boost": [[{"race": "Dragon"}, 200, 200], [{"race": "Winged Beast"}, 200, 200], [{"race": "Thunder"}, 200, 200]]},
	"Wasteland": {"k": "field", "boost": [[{"race": "Dinosaur"}, 200, 200], [{"race": "Zombie"}, 200, 200], [{"race": "Rock"}, 200, 200]]},
	"Umi": {"k": "field", "boost": [[{"race": "Fish"}, 200, 200], [{"race": "Sea Serpent"}, 200, 200], [{"race": "Thunder"}, 200, 200], [{"race": "Aqua"}, 200, 200], [{"race": "Machine"}, -200, -200], [{"race": "Pyro"}, -200, -200]]},
	"A Legendary Ocean": {"k": "field", "boost": [[{"attr": "WATER"}, 200, 200]]},
	"Gaia Power": {"k": "field", "boost": [[{"attr": "EARTH"}, 500, -400]]},
	"Molten Destruction": {"k": "field", "boost": [[{"attr": "FIRE"}, 500, -400]]},
	"Luminous Spark": {"k": "field", "boost": [[{"attr": "LIGHT"}, 500, -400]]},
	"Mystic Plasma Zone": {"k": "field", "boost": [[{"attr": "DARK"}, 500, -400]]},
	"Rising Air Current": {"k": "field", "boost": [[{"attr": "WIND"}, 500, -400]]},
	"Umiiruka": {"k": "field", "boost": [[{"attr": "WATER"}, 500, -400]]},
	"Jurassic World": {"k": "field", "boost": [[{"race": "Dinosaur"}, 300, 300]]},
	"Harpies' Hunting Ground": {"k": "field", "boost": [[{"race": "Winged Beast"}, 200, 200]]},
	"Dragon's Mirror": {"k": "normal", "do": [["miracle_fusion", {"race": "Dragon"}]]},
	"Skyscraper": {"k": "field", "skyscraper": 1000},
	# ---------------------------------------------------------------- Jack's cards (v0.33.36)
	"Resonator Call": {"k": "normal", "ai": "always", "do": [["search", {"has": "Resonator", "monster": true}]]},
	"Scarlet Security": {"k": "normal", "ai": "always", "cond": "own_rda", "do": [["destroy", "opp_st"]]},
	# ---------------------------------------------------------------- Syrus's and Aster's cards (v0.33.35)
	"No Entry!!": {"k": "trap", "win": ["free", "attack"], "do": [["all_to_def"]]},
	"Supercharge": {"k": "trap", "win": ["attack"], "cond": "all_roids", "do": [["draw", 2]]},
	"Destiny Draw": {"k": "normal", "cost": "discard_f", "cost_f": {"has": "Destiny HERO"}, "do": [["draw", 2]]},
	"D - Spirit": {"k": "normal", "ai": "always", "cond": "no_dhero", "do": [["special_from_hand", {"has": "Destiny HERO", "max_lv": 4}]]},
	"Destiny Signal": {"k": "trap", "win": [], "battle_death": true, "do": [["special_hand_deck", {"has": "Destiny HERO", "max_lv": 4}]]},
	"Dark City": {"k": "field", "ai": "always", "dark_city": true},
	"Misfortune": {"k": "normal", "t": "opp_face", "do": [["misfortune"]]},
	# ---------------------------------------------------------------- Zane's cards (v0.33.35)
	"Limiter Removal": {"k": "quick", "ai": "wins", "cond": "own_machine", "do": [["limiter_removal"]]},
	"Photon Generator Unit": {"k": "normal", "ai": "always", "cond": "two_cyber_dragons", "do": [["cyber_unit", 2, "Cyber Laser Dragon", true]]},
	"Attack Reflector Unit": {"k": "trap", "win": ["free"], "cond": "one_cyber_dragon", "do": [["cyber_unit", 1, "Cyber Barrier Dragon", false]]},
	"Different Dimension Capsule": {"k": "cont", "ai": "always", "do": [["dd_capsule"]], "standby": [["dd_capsule_tick"]]},
	# ---------------------------------------------------------------- Chazz's cards (v0.33.35)
	"Level Up!": {"k": "normal", "ai": "always", "cond": "level_up", "do": [["level_up_spell"]]},
	"Ojama Delta Hurricane!!": {"k": "normal", "ai": "always", "cond": "ojama_three", "do": [["destroy_opp_all"]]},
	"Ojamagic": {"k": "normal", "ai": "always", "do": [], "sent_gy": [["ojamagic"]]},
	"Ojamuscle": {"k": "normal", "cond": "ojama_king", "do": [["ojamuscle"]]},
	# ---------------------------------------------------------------- Weevil's cards (v0.33.34)
	"Insect Barrier": {"k": "cont", "ai": "always", "opp_race_no_attack": "Insect"},
	"DNA Surgery": {"k": "ctrap", "win": ["free"], "ai": "always", "dna": true, "do": [["dna"]]},
	"Multiplication of Ants": {"k": "normal", "ai_if": "insect_queen", "cost": "tribute_f", "cost_f": {"race": "Insect"},
		"do": [["tokens", 2, "Army Ant Token", 22493812, 500, 1200, 4, "EARTH", "Insect", "free"]]},
	"Insect Armor with Laser Cannon": {"k": "equip", "must": {"race": "Insect"}, "atk": 700},
	"Eradicating Aerosol": {"k": "normal", "do": [["destroy_race", "Insect"]]},
	# ---------------------------------------------------------------- Pegasus's cards (v0.33.34)
	"Black Illusion Ritual": {"k": "ritual", "ai": "relinquished", "do": [["ritual"]]},
	"Toon Table of Contents": {"k": "normal", "ai": "always", "do": [["search", {"has": "Toon", "monster": false}]]},
	# ---------------------------------------------------------------- Marik's cards (v0.33.34)
	"Jam Defender": {"k": "ctrap", "win": ["attack"], "cond": "jam_defender", "do": [["jam_defender"]]},
	"Malevolent Catastrophe": {"k": "trap", "win": ["attack"], "do": [["destroy", "all_st"]]},
	"Vengeful Bog Spirit": {"k": "cont", "summon_sick_all": true},
	# ---------------------------------------------------------------- Bakura's cards (v0.33.34)
	"Destiny Board": {"k": "ctrap", "win": ["free"], "destiny_board": true, "ai": "always"},
	"Spirit Message \"I\"": {"k": "cont", "cond": "never"},
	"Spirit Message \"N\"": {"k": "cont", "cond": "never"},
	"Spirit Message \"A\"": {"k": "cont", "cond": "never"},
	"Spirit Message \"L\"": {"k": "cont", "cond": "never"},
	# ---------------------------------------------------------------- Vector's cards (v0.33.34)
	"Rank-Up-Magic Barian's Force": {"k": "normal", "ai": "always", "do": [["rank_up", 0, "Number C|CXyz", "same_race", "steal"]]},
	# ---------------------------------------------------------------- Shark's cards (v0.33.34)
	"Aqua Jet": {"k": "normal", "t": "own_face", "must": {"races": ["Fish", "Sea Serpent", "Aqua"]}, "do": [["atk", "target", 1000]]},
	"Surface": {"k": "normal", "do": [["revive", "own_gy", "def", "", {"races": ["Fish", "Sea Serpent", "Aqua"], "max_lv": 3}]]},
	# ---------------------------------------------------------------- Kite's cards (v0.33.34)
	"Photon Lead": {"k": "quick", "do": [["special_from_hand", {"attr": "LIGHT", "max_lv": 4}, "atk"]]},
	"Accellight": {"k": "normal", "cond": "accellight", "ai": "always", "do": [["special_deck_f", "Accellight", ["Photon", "Galaxy"], 0, 4, ""], ["no_normal"]]},
	"Galaxy Expedition": {"k": "normal", "cond": "galaxy_expedition", "ai": "always", "do": [["special_deck_f", "Galaxy Expedition", ["Photon", "Galaxy"], 5, 12, "def"]]},
	"Galaxy Storm": {"k": "normal", "t": "any_face", "must_xyz_empty": true, "do": [["destroy", "target"]]},
	# ---------------------------------------------------------------- Kalin's cards (v0.33.33)
	"Infernity Inferno": {"k": "trap", "win": ["free"], "do": [["infernity_inferno"]]},
	"Infernity Break": {"k": "trap", "win": ["free"], "cond": "hand_empty", "do": [["infernity_break"]]},
	"Infernity Barrier": {"k": "counter", "neg": ["spell", "trap", "fx"], "cond": "infernity_barrier"},
	"Infernity Force": {"k": "trap", "win": ["attack"], "cond": "infernity_targeted", "do": [["destroy", "attacker"], ["revive", "own_gy", "", "", {"has": "Infernity"}]]},
	"Void Trap Hole": {"k": "trap", "win": ["summon"], "subj_atk_min": 2000, "subj_special": true, "do": [["destroy", "summoned"]]},
	# ---------------------------------------------------------------- Akiza's cards (v0.33.33)
	"Seed of Deception": {"k": "normal", "do": [["special_from_hand", {"race": "Plant", "max_lv": 2}]]},
	"Thorn of Malice": {"k": "equip", "must_rose": true, "atk": 600, "pierce": true, "weaken_target": true, "spare_foe": true},
	"Wicked Rebirth": {"k": "ctrap", "win": ["free"], "cost": "lp800", "do": [["revive", "own_gy", "atk", "link", {"frame": "synchro"}, "negate"], ["linked_no_attack"]]},
	"Blossom Bombardment": {"k": "ctrap", "win": ["free"], "plant_burn": true},
	# ---------------------------------------------------------------- Crow's cards (v0.33.33)
	"Black Whirlwind": {"k": "cont", "whirlwind": true, "ai": "always"},
	"Blackwing - Backlash": {"k": "trap", "win": ["attack"], "cond": "backlash", "do": [["destroy", "opp_mons"]]},
	"Trap Stun": {"k": "trap", "win": ["free"], "do": [["trap_stun"]]},
	"Against the Wind": {"k": "normal", "do": [["against_wind"]]},
	"Blackback": {"k": "trap", "win": ["free"], "cond": "no_normal_yet", "do": [["revive", "own_gy", "", "", {"has": "Blackwing", "max_atk": 2000}], ["no_normal"]]},
	# ---------------------------------------------------------------- Jack's cards (v0.33.33)
	"Fiendish Chain": {"k": "ctrap", "win": ["free"], "t": "any_face", "must_effect": true, "equip": true, "no_attack": true, "negate_host": true},
	"Powerful Rebirth": {"k": "ctrap", "win": ["free"], "do": [["revive", "own_gy", "", "link", {"max_lv": 4}], ["linked_boost", 1, 100]]},
	"Half or Nothing": {"k": "trap", "win": ["free"], "cond": "opp_battle", "do": [["half_or_nothing"]]},
	# ---------------------------------------------------------------- Joey's cards (v0.33.33)
	"Graceful Dice": {"k": "quick", "dmg": true, "cond": "own_monster", "do": [["dice_all", "own", 1]]},
	"Skull Dice": {"k": "trap", "win": ["free"], "dmg": true, "do": [["dice_all", "opp", -1]]},
	"Shield & Sword": {"k": "normal", "do": [["shield_sword"]]},
	# ---------------------------------------------------------------- Kaiba's cards (v0.33.32)
	"The Flute of Summoning Dragon": {"k": "normal", "cond": "lord_of_d", "do": [["flute"]]},
	"Crush Card Virus": {"k": "trap", "win": ["free"], "cost": "tribute_f", "cost_f": {"attr": "DARK", "max_atk": 1000}, "do": [["crush_card"]]},
	"Cost Down": {"k": "normal", "cost": "discard", "do": [["cost_down"]]},
	"Burst Stream of Destruction": {"k": "normal", "cond": "own_bewd_fresh", "do": [["destroy", "opp_mons"], ["burst_lock"]]},
	"Interdimensional Matter Transporter": {"k": "trap", "win": ["free"], "t": "own_face", "do": [["exile_end", "target"]]},
	# ---------------------------------------------------------------- Yuma's cards (v0.33.32)
	"Gagagabolt": {"k": "normal", "cond": "own_gagaga", "t": "any_card", "do": [["destroy", "target"]]},
	"Onomatopaira": {"k": "normal", "cost": "discard", "do": [["onomatopaira"]]},
	"Gagagarevenge": {"k": "equip", "do": [["revive", "own_gy", "", "link", {"has": "Gagaga"}]], "xyz_mat_bonus": 300},
	"Xyz Energy": {"k": "normal", "cost": "detach_any", "t": "opp_face", "do": [["destroy", "target"]]},
	"Blustering Winds": {"k": "normal", "t": "own_face", "do": [["winds", "target"]]},
	"Rank-Up-Magic Limited Barian's Force": {"k": "normal", "ai": "always", "do": [["rank_up", 4, "Number C"]]},
	"Half Unbreak": {"k": "trap", "win": ["free"], "t": "any_mon", "do": [["half_unbreak", "target"]]},
	"Battle Break": {"k": "trap", "win": ["attack"], "do": [["battle_break"]]},
	"Bye Bye Damage": {"k": "trap", "win": ["free"], "only_win": "damage", "dmg": true, "cond": "being_attacked_monster", "do": [["bye_bye"]]},
	# ---------------------------------------------------------------- Jaden's cards (v0.33.32)
	"Neo Space": {"k": "field", "neo_space": true, "ai": "always"},
	"Instant Neo Space": {"k": "equip", "must_neos_fusion": true, "neos_keep": true, "host_gone": [["special_named_anywhere", "Elemental HERO Neos"]], "ai": "always"},
	"Fake Hero": {"k": "normal", "ai": "combo", "do": [["fake_hero"]]},
	"O - Oversoul": {"k": "normal", "ai_contact": true, "do": [["revive", "own_gy", "", "", {"has": "Elemental HERO", "frame": "normal"}]]},
	"Hero Signal": {"k": "trap", "win": [], "battle_death": true, "do": [["special_hand_deck", {"has": "Elemental HERO", "max_lv": 4}]]},
	"A Hero Emerges": {"k": "trap", "win": ["attack"], "cond": "own_hand", "do": [["hero_emerges"]]},
	"Hero Barrier": {"k": "trap", "win": ["attack"], "cond": "own_ehero", "do": [["negate_attack"]]},
	"R - Righteous Justice": {"k": "normal", "cond": "own_ehero", "do": [["righteous_justice"]]},
	"H - Heated Heart": {"k": "normal", "t": "own_face", "do": [["atk", "target", 500, "eot"], ["pierce_turn", "target"]]},
	"Edge Hammer": {"k": "trap", "win": ["free"], "cost": "tribute_f", "cost_f": {"name": "Elemental HERO Bladedge"}, "t": "opp_mon", "do": [["destroy_burn_atk", "target"]]},
	"Burst Return": {"k": "normal", "cond": "own_burstinatrix", "do": [["burst_return"]]},
	"Feather Shot": {"k": "normal", "t": "own_face", "must": {"name": "Elemental HERO Avian"}, "do": [["feather_shot", "target"]]},
	"Transcendent Wings": {"k": "quick", "do": [["transcendent_wings"]]},
	"Necrovalley": {"k": "field", "boost": [[{"has": "Gravekeeper"}, 500, 500]]},
	"Chorus of Sanctuary": {"k": "field", "def_pos_boost": 500},
	# ---------------------------------------------------------------- Equip Spells
	"Axe of Despair": {"k": "equip", "atk": 1000, "deck_top": "tribute"},
	"Malevolent Nuzzler": {"k": "equip", "atk": 700, "deck_top": "lp500"},
	"Horn of the Unicorn": {"k": "equip", "atk": 700, "def": 700, "deck_top": "field"},
	"Black Pendant": {"k": "equip", "atk": 500, "on_leave": [["damage", 500]]},
	"United We Stand": {"k": "equip", "atk_per": ["own_face_mons", 800], "def_per": ["own_face_mons", 800]},
	"Mage Power": {"k": "equip", "atk_per": ["own_st", 500], "def_per": ["own_st", 500]},
	"Megamorph": {"k": "equip", "megamorph": true},
	"Fairy Meteor Crush": {"k": "equip", "pierce": true},
	"Big Bang Shot": {"k": "equip", "atk": 400, "pierce": true, "banish_on_leave": true},
	"Lightning Blade": {"k": "equip", "must": {"race": "Warrior"}, "atk": 800, "all_boost": [[{"attr": "WATER"}, -500]]},
	"Sword of Deep-Seated": {"k": "equip", "atk": 500, "def": 500, "deck_top": "always"},
	"Legendary Sword": {"k": "equip", "must": {"race": "Warrior"}, "atk": 300, "def": 300},
	"Beast Fangs": {"k": "equip", "must": {"race": "Beast"}, "atk": 300, "def": 300},
	"Dark Energy": {"k": "equip", "must": {"race": "Fiend"}, "atk": 300, "def": 300},
	"Book of Secret Arts": {"k": "equip", "must": {"race": "Spellcaster"}, "atk": 300, "def": 300},
	"Dragon Treasure": {"k": "equip", "must": {"race": "Dragon"}, "atk": 300, "def": 300},
	"Silver Bow and Arrow": {"k": "equip", "must": {"race": "Fairy"}, "atk": 300, "def": 300},
	"Machine Conversion Factory": {"k": "equip", "must": {"race": "Machine"}, "atk": 300, "def": 300},
	"Vile Germs": {"k": "equip", "must": {"race": "Plant"}, "atk": 300, "def": 300},
	"Laser Cannon Armor": {"k": "equip", "must": {"race": "Insect"}, "atk": 300, "def": 300},
	"Violet Crystal": {"k": "equip", "must": {"race": "Zombie"}, "atk": 300, "def": 300},
	"Electro-Whip": {"k": "equip", "must": {"race": "Thunder"}, "atk": 300, "def": 300},
	"Mystical Moon": {"k": "equip", "must": {"race": "Beast-Warrior"}, "atk": 300, "def": 300},
	"Raise Body Heat": {"k": "equip", "must": {"race": "Dinosaur"}, "atk": 300, "def": 300},
	"Follow Wind": {"k": "equip", "must": {"race": "Winged Beast"}, "atk": 300, "def": 300},
	# ---- Mai, Rex, Alexis (v0.33.27)
	"Fusion Weapon": {"k": "equip", "must": {"frame": "fusion", "max_lv": 6}, "atk": 1500, "def": 1500},
	"Ritual Weapon": {"k": "equip", "must": {"frame": "ritual", "max_lv": 6}, "atk": 1500, "def": 1500},
	"Cyber Shield": {"k": "equip", "must": {"names": ["Harpie Lady", "Harpie Lady Sisters"], "zone": "field"}, "atk": 500},
	"Elegant Egotist": {"k": "normal", "cond": "harpie_lady_up", "do": [["egotist"]]},
	"Machine Angel Ritual": {"k": "ritual", "do": [["ritual"]]},
	"Fossil Excavation": {"k": "ctrap", "win": ["free"], "cost": "discard", "do": [["revive", "own_gy", "any", "link", {"race": "Dinosaur"}, "negate"]]},
	"Mirror Wall": {"k": "ctrap", "win": ["free"], "halve_attackers": true, "upkeep": 2000, "upkeep_ask": true, "do": [["mirror_wall"]]},
	# ---- Yusei (v0.33.28)
	"Tuning": {"k": "normal", "ai": "always", "do": [["search", {"has": "Synchron", "tuner": true}], ["mill_self", 1]]},
	"One for One": {"k": "normal", "ai": "combo", "cost": "discard_f", "cost_f": {}, "do": [["special_hand_deck", {"lv": 1}]]},
	"Double Summon": {"k": "normal", "ai": "second_summon", "do": [["extra_normal"]]},
	"Cards of Consonance": {"k": "normal", "ai": "always", "cost": "discard_f", "cost_f": {"race": "Dragon", "tuner": true, "max_atk": 1000}, "do": [["draw", 2]]},
	"Card Rotator": {"k": "normal", "cost": "discard", "do": [["change_pos", "opp_mons"]]},
	"Fighting Spirit": {"k": "equip", "atk_per": ["opp_mons", 300], "battle_sub": true},
	"Silver Wing": {"k": "equip", "must": {"frame": "synchro", "race": "Dragon", "min_lv": 8}, "battle_guard": 2, "fx_sub": true},
	"Graceful Revival": {"k": "ctrap", "win": ["free"], "do": [["revive", "own_gy", "atk", "link", {"max_lv": 2}]]},
	"Shooting Star": {"k": "trap", "win": ["free"], "cond": "stardust_up", "t": "any_card", "do": [["destroy", "target"]]},
	"Synchro Strike": {"k": "trap", "win": ["free"], "t": "any_face", "must": {"frame": "synchro"}, "must_proper": true, "dmg": true, "do": [["atk_per_mat", 500]]},
	"Skill Successor": {"k": "trap", "win": ["free"], "t": "own_face", "dmg": true, "do": [["atk", "target", 400, "eot"]]},
	"Descending Lost Star": {"k": "trap", "win": ["free"], "do": [["lost_star"]]},
	"Synchro Barrier": {"k": "trap", "win": ["free"], "cost": "tribute_f", "cost_f": {"frame": "synchro"}, "do": [["no_damage_until", 1]]},
	"Starlight Road": {"k": "trap", "win": ["chain"], "chain_if": "destroys_two_of_mine", "do": [["starlight"]]},
	"Defense Draw": {"k": "trap", "win": ["free"], "only_win": "damage", "dmg": true, "cond": "being_attacked", "do": [["battle_shield"], ["draw", 1]]},
	"Urgent Tuning": {"k": "trap", "win": ["free"], "cond": "battle_phase", "do": [["synchro_now"]]},
	"Give and Take": {"k": "trap", "win": ["free"], "do": [["give_and_take"]]},
	"Slip Summon": {"k": "trap", "win": ["summon"], "do": [["slip_summon"]]},
	"Limiter Overload": {"k": "trap", "win": [], "sent_gy": [["special_named_anywhere", "Speed Warrior"]]},
	# ---- Yugi (v0.33.32)
	"Black Luster Ritual": {"k": "ritual", "do": [["ritual"]]},
	"Black Magic Ritual": {"k": "ritual", "do": [["ritual"]]},
	"Dark Magic Attack": {"k": "normal", "cond": "own_dark_magician", "do": [["destroy", "opp_st"]]},
	"Thousand Knives": {"k": "normal", "cond": "own_dark_magician", "t": "opp_mon", "do": [["destroy", "target"]]},
	"Dark Magic Curtain": {"k": "normal", "cost": "half_lp", "cond": "no_summon_yet", "do": [["special_named", "Dark Magician", ["deck"]], ["no_more_summons"]]},
	"Sage's Stone": {"k": "normal", "cond": "own_dark_magician_girl", "do": [["special_named", "Dark Magician", ["hand", "deck"]]]},
	"Magic Formula": {"k": "equip", "must": {"names": ["Dark Magician", "Dark Magician Girl"]}, "atk": 700, "on_leave": [["heal", 1000]]},
	"Dedication through Light and Darkness": {"k": "quick", "cost": "tribute_f", "cost_f": {"name": "Dark Magician"}, "do": [["special_named", "Dark Magician of Chaos", ["hand", "deck", "gy"]]]},
	"Multiply": {"k": "quick", "cost": "tribute_f", "cost_f": {"name": "Kuriboh"}, "do": [["tokens", 5, "Kuriboh Token", 40703223, 300, 200, 1, "DARK", "Fiend", "free"]]},
	"Mystic Box": {"k": "normal", "t": "opp_mon", "cond": "own_monster", "do": [["destroy", "target"], ["give_pick"]]},
	"De-Spell": {"k": "normal", "t": "any_spell", "do": [["despell"]]},
	"Lightforce Sword": {"k": "trap", "win": ["free"], "cond": "opp_has_hand", "do": [["lightforce", 4]]},
	"Chain Destruction": {"k": "trap", "win": ["summon"], "subj_atk_max": 2000, "do": [["chain_destruction"]]},
	"Gold Sarcophagus": {"k": "normal", "do": [["gold_sarcophagus", 2]]},
	"Power of Kaishin": {"k": "equip", "must": {"race": "Aqua"}, "atk": 300, "def": 300},
	"Steel Shell": {"k": "equip", "must": {"attr": "WATER"}, "atk": 400, "def": -200},
	"Gust Fan": {"k": "equip", "must": {"attr": "WIND"}, "atk": 400, "def": -200},
	"Salamandra": {"k": "equip", "must": {"attr": "FIRE"}, "atk": 700},
	"Elf's Light": {"k": "equip", "must": {"attr": "LIGHT"}, "atk": 400, "def": -200},
	"Sword of Dark Destruction": {"k": "equip", "must": {"attr": "DARK"}, "atk": 400, "def": -200},
	"Snatch Steal": {"k": "equip", "t": "opp_face", "control": true, "standby": [["opp_heal", 1000]]},
	"Cyclon Laser": {"k": "equip", "must": {"name": "Gradius"}, "atk": 300, "pierce": true},
	"Spark Blaster": {"k": "equip", "atk": 300},
	"Assault Armor": {"k": "equip", "must": {"race": "Warrior"}, "atk": 300},
	"Junk Barrage": {"k": "equip", "burn_half_on_kill": true},
	"Mist Body": {"k": "equip", "no_battle_death": true},
	"Heart of Clear Water": {"k": "equip", "no_battle_death": true},
	"Ring of Magnetism": {"k": "equip", "atk": -500, "def": -500},
	# ---------------------------------------------------------------- Normal Traps
	"Ring of Destruction": {"k": "trap", "win": ["free"], "cond": "opp_turn", "t": "opp_face_atk_le_lp", "do": [["ring"]]},
	"Dust Tornado": {"k": "trap", "win": ["free"], "t": "opp_st", "do": [["destroy", "target"], ["may_set"]]},
	"Compulsory Evacuation Device": {"k": "trap", "win": ["free"], "t": "any_mon", "do": [["bounce", "target"]]},
	"Raigeki Break": {"k": "trap", "win": ["free"], "t": "any_card", "cost": "discard", "do": [["destroy", "target"]]},
	"Threatening Roar": {"k": "trap", "win": ["free"], "do": [["no_attacks"]]},
	"Draining Shield": {"k": "trap", "win": ["attack"], "do": [["negate_attack"], ["heal_attacker_atk"]]},
	"Just Desserts": {"k": "trap", "win": ["free"], "do": [["damage_per", "opp_mons", 500]]},
	"Ceasefire": {"k": "trap", "win": ["free"], "do": [["flip_up", "all_fdown"], ["damage_per", "all_effect_mons", 500]]},
	"Reckless Greed": {"k": "trap", "win": ["free"], "do": [["draw", 2], ["skip_draw", 2]]},
	"Widespread Ruin": {"k": "trap", "win": ["attack"], "do": [["destroy", "opp_best_atk_pos"]]},
	"Enchanted Javelin": {"k": "trap", "win": ["attack"], "do": [["heal_attacker_atk"]]},
	"Shadow Spell": {"k": "ctrap", "win": ["free"], "t": "opp_face", "equip": true, "atk": -700, "no_attack": true, "no_move": true},
	"Spellbinding Circle": {"k": "ctrap", "win": ["free"], "t": "opp_face", "equip": true, "no_attack": true, "no_move": true},
	"Nightmare Wheel": {"k": "ctrap", "win": ["free"], "t": "opp_face", "equip": true, "no_attack": true, "no_move": true, "standby": [["damage", 500]]},
	"Call of the Haunted": {"k": "ctrap", "win": ["free"], "do": [["revive", "own_gy", "atk", "link"]]},
	"Gravity Bind": {"k": "ctrap", "win": ["free"], "lock_lv_min": 4},
	"Royal Decree": {"k": "ctrap", "win": ["free"], "block": "trap"},
	"Imperial Order": {"k": "ctrap", "win": ["free"], "block": "spell", "upkeep": 700},
	"Macro Cosmos": {"k": "ctrap", "win": ["free"], "redirect": "all", "do": [["may_special_named", "Helios - The Primordial Sun"]]},
	"Windstorm of Etaqua": {"k": "trap", "win": ["free"], "do": [["change_pos", "opp_face_mons"]]},
	"Zero Gravity": {"k": "trap", "win": ["free"], "do": [["change_pos", "all_face_mons"]]},
	"Dimensional Prison": {"k": "trap", "win": ["attack"], "do": [["negate_attack"], ["banish", "attacker"]]},
	"Sakuretsu Armor": {"k": "trap", "win": ["attack"], "do": [["destroy", "attacker"]]},
	"Mirror Force": {"k": "trap", "win": ["attack"], "do": [["destroy", "opp_atk_mons"]]},
	"Magic Cylinder": {"k": "trap", "win": ["attack"], "do": [["negate_attack"], ["damage_attacker_atk"]]},
	"Negate Attack": {"k": "counter", "win": ["attack"], "neg": [], "do": [["end_battle"]]},
	"Waboku": {"k": "trap", "win": ["free"], "do": [["no_battle_damage"], ["protect"]]},
	"Hallowed Life Barrier": {"k": "trap", "win": ["free"], "cost": "discard", "do": [["no_damage_turn"], ["protect"]]},
	"Trap Hole": {"k": "trap", "win": ["summon"], "subj_atk_min": 1000, "normal_only": true, "do": [["destroy", "summoned"]]},
	"Bottomless Trap Hole": {"k": "trap", "win": ["summon"], "subj_atk_min": 1500, "do": [["destroy", "summoned"], ["banish", "summoned"]]},
	"Torrential Tribute": {"k": "trap", "win": ["summon"], "do": [["destroy", "all_mons"]]},
	"Adhesion Trap Hole": {"k": "trap", "win": ["summon"], "do": [["halve_perm", "summoned"]]},
	"Scrap-Iron Scarecrow": {"k": "trap", "win": ["attack"], "reset": true, "do": [["negate_attack"]]},
	# ---------------------------------------------------------------- Counter Traps
	"Solemn Judgment": {"k": "counter", "neg": ["spell", "trap", "summon"], "cost": "half_lp"},
	"Divine Wrath": {"k": "counter", "neg": ["fx"], "cost": "discard"},
	"Skill Drain": {"k": "ctrap", "win": ["free"], "cost": "lp1000", "drain": true},
	"Breakthrough Skill": {"k": "trap", "win": ["free"], "t": "opp_face", "do": [["negate_fx", "target"]]},
	"Magic Jammer": {"k": "counter", "neg": ["spell"], "cost": "discard"},
	"Seven Tools of the Bandit": {"k": "counter", "neg": ["trap"], "cost": "lp1000"},
	"Dark Bribe": {"k": "counter", "neg": ["spell", "trap"], "do": [["opp_draw", 1]]},
	"Horn of Heaven": {"k": "counter", "neg": ["summon"], "cost": "tribute"},
	"Spell Shield Type-8": {"k": "counter", "neg": ["spell"], "cost": "discard"},
	"Trap Jammer": {"k": "counter", "neg": ["trap"], "cond": "battle_phase"},
	"Cursed Seal of the Forbidden Spell": {"k": "counter", "neg": ["spell"], "cost": "discard"},
}

const LEGACY_WIN := {"mirror_force": "attack", "magic_cylinder": "attack", "sakuretsu": "attack", "negate_attack": "attack",
		"waboku": "attack", "dim_prison": "attack", "trap_hole": "summon", "bottomless": "summon", "torrential": "summon"}
static var _derived := {}


static var _moded := {}


static func spec(c) -> Dictionary:
	var name: String = c.cname()
	if FX.has(name):
		var base: Dictionary = FX[name]
		if base.has("modes"):
			# The chosen effect's keys laid over the card's own (the list stays, for the menu).
			var mi := clampi(int(c.mode), 0, (base["modes"] as Array).size() - 1)
			var key := "%s#%d" % [name, mi]
			if not _moded.has(key):
				var merged: Dictionary = base.duplicate()
				for k in base["modes"][mi]:
					merged[k] = base["modes"][mi][k]
				_moded[key] = merged
			return _moded[key]
		return base
	if _derived.has(name):
		return _derived[name]
	var d := _derive(c)
	_derived[name] = d
	return d


static func kind(c) -> String:
	return str(spec(c).get("k", ""))


## Cards without a hand-written entry: old effect tags, and Equip / Field / Ritual Spells whose text
## follows the usual pattern ("gains 500 ATK", "All Dragon monsters gain 200 ATK").
static func _derive(c) -> Dictionary:
	var tag: String = c.data.get("effect", "")
	if tag != "":
		if c.is_trap():
			return {"k": "trap", "legacy": tag, "win": [LEGACY_WIN.get(tag, "attack")]}
		return {"k": "normal", "legacy": tag}
	var st: String = str(c.data.get("st", "")).to_lower()
	var text: String = str(c.data.get("desc", c.data.get("text", "")))
	if st == "ritual":
		return {"k": "ritual", "do": [["ritual"]]}
	if st == "equip":
		var re := RegEx.new()
		re.compile("gains? (\\d+) ATK")
		var m := re.search(text)
		if m == null:
			return {}
		var out := {"k": "equip", "atk": int(m.get_string(1))}
		if text.contains("ATK and DEF") or text.contains("ATK/DEF"):
			out["def"] = out["atk"]
		var only := RegEx.new()
		only.compile("only to an? ([A-Za-z\\- ]+?)(?:-Type)? monster")
		var mm := only.search(text)
		if mm:
			var w := mm.get_string(1).strip_edges()
			out["must"] = {"attr": w} if ATTRS.has(w) else {"race": w}
		return out
	if st == "field":
		var re := RegEx.new()
		re.compile("All ([A-Za-z\\-, ]+?)(?:-Type)? monsters (?:on the field )?gain (\\d+) ATK( and DEF|/DEF)?")
		var boosts := []
		for m in re.search_all(text):
			for part in m.get_string(1).replace(" and ", ", ").split(", ", false):
				var w := part.strip_edges().trim_suffix("-Type")
				var n := int(m.get_string(2))
				boosts.append([{"attr": w} if ATTRS.has(w) else {"race": w}, n, n if m.get_string(3) != "" else 0])
		return {"k": "field", "boost": boosts} if not boosts.is_empty() else {}
	return {}


# ------------------------------------------------------------------ what can be played

## True when this card is locked out by Royal Decree / Imperial Order.
static func blocked(s: DuelState, c) -> bool:
	if c.tags.get("neo_neg", false):
		return true   # Neo Galaxy-Eyes Photon Dragon negated it when it arrived
	# Photon Cerberus: no Trap Cards on the turn it was Normal Summoned, while it is face-up.
	if c.is_trap() and s.trap_stun_turn == s.turn and str(c.data.get("name", "")) != "Trap Stun":
		return true   # Trap Stun: "Negate all other Trap effects on the field this turn."
	if c.is_trap():
		for q in 2:
			for m in s.players[q].monsters():
				if m.face_up and m.normal_turn == s.turn and EffectRunner.fx(m).get("no_traps_normal_turn", false):
					return true
				if m.face_up and EffectRunner.fx(m).get("block_traps", false):
					return true   # Jinzo: "Trap Cards, and their effects on the field, cannot be activated. Negate all Trap effects on the field."
	if c.is_spell():
		# Silent Swordsman LV7: "Negate all Spell effects on the field."
		for q in 2:
			for m in s.players[q].monsters():
				if m.face_up and EffectRunner.fx(m).get("block_spells", false):
					return true
	for q in 2:
		for st in s.players[q].spells:
			if st == null or not st.face_up or st == c:
				continue
			var b: String = str(spec(st).get("block", ""))
			if (b == "trap" and c.is_trap()) or (b == "spell" and c.is_spell()):
				return true
	return false


## Would this chain link destroy a card on the field? (Stardust Dragon answers those.)
static func would_destroy(link: Dictionary) -> bool:
	if link.get("negated", false):
		return false
	var acts: Array = link.get("actions", []) if str(link.get("kind", "")) == "fx" else (link["spec"] as Dictionary).get("do", [])
	for a in acts:
		if str(a[0]) in ["destroy", "destroy_half_damage", "destroy_killer", "dice_destroy", "ring"]:
			return true
	var tag := str((link.get("spec", {}) as Dictionary).get("legacy", ""))
	return tag in ["raigeki", "darkhole", "fissure", "mst", "mirror_force", "sakuretsu", "trap_hole", "bottomless", "torrential"]


## How many cards that player `p` controls would this chain link destroy? (Starlight Road asks.)
static func destroy_count(s: DuelState, link: Dictionary, p: int) -> int:
	if link.get("negated", false):
		return 0
	var mine := s.players[p]
	var lp: int = link["player"]
	var mons: int = mine.monsters().size()
	var sts: int = mine.set_cards().size() + (1 if mine.field_spell != null else 0)
	var n := 0
	if str(link.get("kind", "")) == "fx":
		for a in link.get("actions", []):
			match str(a[0]):
				"black_rose":
					n = maxi(n, mons + sts)
				"destroy":
					var what := str(a[1]) if a.size() > 1 else ""
					if what == "all_field_other":
						n = maxi(n, mons + mine.set_cards().size())
					elif what.begins_with("all") and lp != p:
						n = maxi(n, mons)
		return n
	var sp: Dictionary = link.get("spec", {})
	match str(sp.get("legacy", "")):
		"raigeki":
			return mons if lp != p else 0
		"darkhole", "torrential":
			return mons
		"mirror_force":
			return mine.monsters().filter(func(m): return m.attack_pos).size() if lp != p else 0
	for a in sp.get("do", []):
		if str(a[0]) != "destroy" or a.size() < 2:
			continue
		var hit := 0
		for x in _sel(s, lp, link["card"], str(a[1]), {"target": link.get("target"), "subject": link.get("subject")}):
			if mine.field.has(x) or mine.spells.has(x) or mine.field_spell == x:
				hit += 1
		n = maxi(n, hit)
	return n


## Does this card fit the response window? window: attack | summon | chain | battle_start | open
static func fits(s: DuelState, p: int, c, window: String, subject) -> bool:
	var sp := spec(c)
	if sp.is_empty() or s.is_over():
		return false
	var k: String = sp["k"]
	var ps := s.players[p]
	if ps.hand.has(c):
		if k != "quick" or p != s.current or ps.spells.find(null) == -1:
			return false
	elif ps.spells.has(c) and not c.face_up:
		if (c.is_trap() or k == "quick") and c.set_turn >= s.turn:
			return false
		if not k in ["quick", "trap", "ctrap", "counter"]:
			return false
	else:
		return false
	if blocked(s, c):
		return false
	if sp.has("cond") and not cond_ok(s, p, str(sp["cond"])):
		return false
	# Spell Speed: only a Counter Trap can answer a Counter Trap.
	if window == "chain" and subject is Dictionary and str(subject.get("spec", {}).get("k", "")) == "counter" and k != "counter":
		return false
	if sp.has("only_win") and window != str(sp["only_win"]):
		return false   # a card for one moment only (Defense Draw: damage calculation)
	if sp.has("chain_if"):
		# Starlight Road: "When a card or effect is activated that would destroy 2 or more cards you control".
		if window != "chain" or not (subject is Dictionary) or destroy_count(s, subject, p) < 2:
			return false
	# Damage Step: only cards that change ATK / DEF (and Counter Traps) may be activated.
	if window == "damage":
		if sp.has("legacy") or (k != "counter" and not dmg_ok(sp)):
			return false
		window = "free"
	if sp.has("legacy"):
		return s._trap_fits(p, c, window, null if subject is Dictionary else subject)
	if k == "counter" and not sp.has("win"):
		var neg: Array = sp.get("neg", [])
		if window == "chain" and subject is Dictionary:
			return subject["player"] != p and neg.has(subject["kind"]) and _can_pay(s, p, c, sp)
		if window == "summon" and subject != null and not (subject is Dictionary):
			return neg.has("summon") and subject.owner != p and _can_pay(s, p, c, sp)
		return false
	var wins: Array = sp.get("win", ["free"] if k == "quick" else [])
	if not (wins.has("free") or wins.has(window)):
		return false
	if sp.get("any_attack", false):
		# Ego Boost: when any monster declares an attack.
		if s.pending_attack.is_empty() or window != "attack":
			return false
	elif wins.has("attack") and not wins.has("free"):
		if s.pending_attack.is_empty() or s.pending_attack["player"] == p or window != "attack":
			return false
	if wins.has("summon") and not wins.has("free"):
		if subject == null or subject is Dictionary or subject.owner == p or window != "summon":
			return false
		if sp.get("subj_special", false) and not subject.tags.get("ss", false):
			return false   # "When your opponent Special Summons a monster" (Void Trap Hole)
		if subject.atk() < int(sp.get("subj_atk_min", 0)) or subject.atk() > int(sp.get("subj_atk_max", 99999)):
			return false
	if sp.has("modes"):
		return not open_modes(s, p, c, window, subject).is_empty()
	return feasible(s, p, c, window, subject)


## Which of a multi-effect card's effects could be used right now (indices into "modes").
static func open_modes(s: DuelState, p: int, c, window: String, subject) -> Array:
	var out: Array = []
	var base: Dictionary = FX.get(c.cname(), {})
	var keep: int = c.mode
	for mi in (base.get("modes", []) as Array).size():
		c.mode = mi
		if feasible(s, p, c, window, subject):
			out.append(mi)
	c.mode = keep
	return out


## May this card be activated during the Damage Step? (ATK / DEF changers only.)
static func dmg_ok(sp: Dictionary) -> bool:
	if sp.has("dmg"):
		return bool(sp["dmg"])
	for a in sp.get("do", []):
		if str(a[0]) in ["atk", "def", "halve", "atk_all"]:
			return true
	return false


## Is a face-up Spell/Trap with this passive flag on the field (Skill Drain's "drain")?
static func field_flag(s: DuelState, flag: String) -> bool:
	for q in 2:
		for st in _up(s, q):
			if st.face_up and spec(st).get(flag, false) and not blocked(s, st):
				return true
	return false


## Would activating this card do anything right now?
## A card's own "only if / only during" condition.
static func cond_ok(s: DuelState, p: int, cond: String) -> bool:
	if cond.begins_with("opp_lp_over:"):
		return s.players[s.opponent(p)].lp > int(cond.substr(12))
	match cond:
		"echo_ready":
			# Echo Resonance: a Lumen, Echo Spirit to Tribute, and a Lumen, Echo Radiant to bring out.
			return echo_tribute(s, p) != null and echo_radiant(s, p) != null
		"battle_phase":
			return s.phase == DuelState.Phase.BATTLE
		"opp_turn":
			return s.current != p
		"own_dark_magician", "own_dark_magician_girl":
			var want_n := "Dark Magician" if cond == "own_dark_magician" else "Dark Magician Girl"
			for m in s.players[p].monsters():
				if m.face_up and CardEffects.matches(m.data, {"name": want_n, "zone": "field"}):
					return true
			return false
		"no_summon_yet":
			return s.players[p].summons_turn != s.turn and s.players[p].no_summon_turn != s.turn
		"own_monster":
			return not s.players[p].monsters().is_empty()
		"own_hand":
			return not s.players[p].hand.is_empty()
		"hand_empty":
			return s.players[p].hand.is_empty()
		"level_up":
			return not _lv_ready(s, p).is_empty()
		"own_rda":
			return not s.players[p].monsters().filter(func(m): return m.face_up and (m.cname() == "Red Dragon Archfiend" or str(CardEffects.of(m.cname()).get("name_as", "")) == "Red Dragon Archfiend")).is_empty() \
					and not (s.players[s.opponent(p)].set_cards().is_empty() and s.players[s.opponent(p)].field_spell == null)
		"all_roids":
			var mine_r: Array = s.players[p].monsters()
			return not mine_r.is_empty() and mine_r.filter(func(m): return not (m.face_up and str(m.data.get("race", "")) == "Machine" and m.cname().to_lower().contains("roid"))).is_empty() \
					and not s.pending_attack.is_empty() and s.pending_attack["player"] != p
		"no_dhero":
			return s.players[p].monsters().filter(func(m): return m.face_up and m.cname().contains("Destiny HERO")).is_empty() \
					and s.players[p].free_zone() != -1 and not EffectRunner._take(s.players[p].hand, {"has": "Destiny HERO", "max_lv": 4}, 1).is_empty()
		"own_machine":
			return not s.players[p].monsters().filter(func(m): return m.face_up and str(m.data.get("race", "")) == "Machine").is_empty()
		"two_cyber_dragons":
			return _cyber_dragons(s, p).size() >= 2 and not _unit_pool(s, p, "Cyber Laser Dragon", true).is_empty()
		"one_cyber_dragon":
			return _cyber_dragons(s, p).size() >= 1 and not _unit_pool(s, p, "Cyber Barrier Dragon", false).is_empty()
		"ojama_three":
			for nm in ["Ojama Green", "Ojama Yellow", "Ojama Black"]:
				if s.players[p].monsters().filter(func(m): return m.face_up and m.cname() == nm).is_empty():
					return false
			return true
		"ojama_king":
			return not (s.players[p].monsters() + s.players[s.opponent(p)].monsters()).filter(func(m): return m.face_up and m.cname() == "Ojama King").is_empty()
		"jam_defender":
			return not s.pending_attack.is_empty() and s.pending_attack["target"] != null and s.pending_attack["target"].cname() != "Revival Jam" \
					and not s.players[p].monsters().filter(func(m): return m.face_up and m.cname() == "Revival Jam").is_empty()
		"never":
			return false   # "This card can only be placed on the field by the effect of "Destiny Board"."
		"accellight":
			# "If you control no monsters... You cannot Normal Summon/Set during the turn you activate this card." Once per turn.
			return s.players[p].monsters().is_empty() and s.current == p and not s.normal_summoned and int(s.players[p].once_names.get("Accellight", -1)) != s.turn
		"galaxy_expedition":
			return int(s.players[p].once_names.get("Galaxy Expedition", -1)) != s.turn and not s.players[p].monsters().filter(func(m): return m.face_up and m.frame() != "xyz" and m.level() >= 5 and (m.cname().contains("Photon") or m.cname().contains("Galaxy"))).is_empty()
		"infernity_barrier":
			# "...while you control a face-up Attack Position "Infernity" monster and have no cards in your hand".
			return s.players[p].hand.is_empty() and not s.players[p].monsters().filter(func(m): return m.face_up and m.attack_pos and m.cname().contains("Infernity")).is_empty()
		"infernity_targeted":
			return s.players[p].hand.is_empty() and not s.pending_attack.is_empty() and s.pending_attack["target"] != null and s.pending_attack["target"].face_up and s.pending_attack["target"].cname().contains("Infernity")
		"backlash":
			# "...declares a direct attack while you have 5 or more "Blackwing" monsters in your Graveyard".
			return not s.pending_attack.is_empty() and s.pending_attack["target"] == null and s.players[p].gy.filter(func(g): return g.is_monster() and g.cname().contains("Blackwing")).size() >= 5
		"no_normal_yet":
			return s.current == p and not s.normal_summoned
		"opp_battle":
			return s.current != p and s.phase == DuelState.Phase.BATTLE and not s.in_damage_step
		"lord_of_d":
			for q in 2:
				for m in s.players[q].monsters():
					if m.face_up and m.cname() == "Lord of D.":
						return true
			return false
		"own_bewd_fresh":
			# "If you control "Blue-Eyes White Dragon"... [it] cannot attack the turn you activate this card."
			var any_b := false
			for m in s.players[p].monsters():
				if m.face_up and m.cname() == "Blue-Eyes White Dragon":
					any_b = true
					if m.attacked_turn == s.turn:
						return false
			return any_b
		"own_gagaga":
			for m in s.players[p].monsters():
				if m.face_up and m.cname().contains("Gagaga"):
					return true
			return false
		"being_attacked_monster":
			return s.current != p and not s.pending_attack.is_empty() and int(s.pending_attack["player"]) != p and s.pending_attack["target"] != null
		"own_ehero", "own_burstinatrix":
			for m in s.players[p].monsters():
				if m.face_up and str(m.data.get("name", "")).contains("Elemental HERO Burstinatrix" if cond == "own_burstinatrix" else "Elemental HERO"):
					return true
			return false
		"opp_has_hand":
			return not s.players[s.opponent(p)].hand.is_empty()
		"being_attacked":
			return s.current != p and not s.pending_attack.is_empty() and int(s.pending_attack["player"]) != p and not s.pending_attack.get("negated", false)
		"stardust_up":
			# Shooting Star: "If a "Stardust" monster is on the field" (either side).
			for q in 2:
				for m in s.players[q].monsters():
					if m.face_up and m.cname().contains("Stardust"):
						return true
			return false
		"harpie_lady_up":
			# Elegant Egotist: "If Harpie Lady is on the field" (either side; a card that counts as her does).
			for q in 2:
				for m in s.players[q].monsters():
					if m.face_up and CardEffects.matches(m.data, {"name": "Harpie Lady", "zone": "field"}):
						return true
			return false
	return true


## Elegant Egotist: every "Harpie Lady" and "Harpie Lady Sisters" in your hand and Deck.
static func _egotist_pool(s: DuelState, p: int) -> Array:
	var out: Array = []
	for src in [s.players[p].hand, s.players[p].deck]:
		for h in src:
			if h.is_monster() and h.cname() in ["Harpie Lady", "Harpie Lady Sisters"]:
				out.append(h)
	return out


## Echo Resonance: the "Lumen, Echo Spirit" you control that can be Tributed for it. She must not
## have been Summoned this turn, unless your Life Points are 2000 or less.
static func echo_tribute(s: DuelState, p: int):
	var ps := s.players[p]
	for m in ps.monsters():
		if m.face_up and m.cname() == "Lumen, Echo Spirit" and (m.summoned_turn != s.turn or ps.lp <= 2000) and m.no_tribute_turn != s.turn:
			return m
	return null


## ...and the "Lumen, Echo Radiant" it brings out: from the hand first, then the Deck.
static func echo_radiant(s: DuelState, p: int):
	var ps := s.players[p]
	for h in ps.hand:
		if h.cname() == "Lumen, Echo Radiant":
			return h
	for d in ps.deck:
		if d.cname() == "Lumen, Echo Radiant":
			return d
	return null


static func feasible(s: DuelState, p: int, c, window: String, subject) -> bool:
	var sp := spec(c)
	if not _can_pay(s, p, c, sp):
		return false
	if sp.has("cond") and not cond_ok(s, p, str(sp["cond"])):
		return false
	if _needs_target(sp) and targets(s, p, c).is_empty():
		return false
	var ps := s.players[p]
	var opp := s.players[s.opponent(p)]
	for a in sp.get("do", []):
		match a[0]:
			"draw":
				if ps.deck.size() < int(a[1]):
					return false
			"destroy", "bounce", "banish", "flip_down", "change_pos", "control", "to_def":
				# (A card that stays on the field for what it does afterwards can be played with nothing to hit: Burning Land.)
				if a[1] != "target" and a[1] != "attacker" and a[1] != "summoned" and _sel(s, p, c, str(a[1]), {}).is_empty() and not (str(sp.get("k", "")) in ["cont", "ctrap"]):
					return false
			"revive":
				var from: Array = ps.gy if a[1] == "own_gy" else ps.gy + opp.gy
				if a.size() > 4:
					from = from.filter(func(x): return CardEffects.matches(x.data, a[4]))
				if ps.free_zone() == -1 or s._best_monsters(from.filter(func(x): return s.can_revive(x)), 1).is_empty():
					return false
			"egotist":
				if ps.free_zone() == -1 or _egotist_pool(s, p).is_empty():
					return false
			"special_hand_deck":
				var held: Array = ps.hand.filter(func(h): return h != c)
				if ps.free_zone() == -1 or ps.no_summon_turn == s.turn or (EffectRunner._take(held, a[1], 1).is_empty() and EffectRunner._take(ps.deck, a[1], 1).is_empty()):
					return false
			"extra_normal":
				if s.current != p or ps.extra_normals > 0:
					return false
			"special_named":
				var found_n := false
				for where in a[2]:
					var from_n: Array = ps.deck if where == "deck" else (ps.hand if where == "hand" else ps.gy.filter(func(x): return s.can_revive(x)))
					if not EffectRunner._take(from_n.filter(func(h): return h != c), {"name": str(a[1])}, 1).is_empty():
						found_n = true
				if not found_n or ps.free_zone() == -1 or ps.no_summon_turn == s.turn:
					return false
			"tokens":
				if ps.free_zone() == -1:
					return false
			"gold_sarcophagus":
				if ps.deck.is_empty():
					return false
			"lost_star":
				if ps.free_zone() == -1 or ps.gy.filter(func(x): return x.frame() == "synchro" and s.can_revive(x)).is_empty():
					return false
			"synchro_now":
				if _synchro_options(s, p).is_empty():
					return false
			"give_and_take":
				if s.players[s.opponent(p)].free_zone() == -1 or ps.gy.filter(func(x): return s.can_revive(x)).is_empty() \
						or ps.monsters().filter(func(m): return m.face_up and m.frame() != "xyz").is_empty():
					return false
			"slip_summon":
				if ps.free_zone() == -1 or ps.no_summon_turn == s.turn or EffectRunner._take(ps.hand, {"max_lv": 4}, 1).is_empty():
					return false
			"special_deck_f":
				if ps.free_zone() == -1 or ps.no_summon_turn == s.turn or _deck_family(s, p, a[2], int(a[3]), int(a[4])).is_empty():
					return false
			"infernity_inferno":
				if ps.hand.filter(func(h): return h != c).is_empty() or ps.deck.filter(func(x): return x.cname().contains("Infernity")).is_empty():
					return false
			"infernity_break":
				if ps.gy.filter(func(g): return g.cname().contains("Infernity")).is_empty() or (opp.monsters().is_empty() and opp.set_cards().is_empty() and opp.field_spell == null):
					return false
			"special_from_hand":
				if ps.free_zone() == -1 or ps.no_summon_turn == s.turn or EffectRunner._take(ps.hand.filter(func(h): return h != c and not CardEffects.of(h.cname()).get("no_special", false)), a[1], 1).is_empty():
					return false
			"against_wind":
				if ps.gy.filter(func(g): return g.is_monster() and g.cname().contains("Blackwing") and g.atk() < ps.lp).is_empty():
					return false
			"flute":
				if ps.free_zone() == -1 or ps.no_summon_turn == s.turn or ps.hand.filter(func(h): return h != c and h.is_monster() and str(h.data.get("race", "")) == "Dragon" and not CardEffects.of(h.cname()).get("no_special", false) and not CardData.is_extra(h.id)).is_empty():
					return false
			"cost_down":
				if ps.hand.filter(func(h): return h != c and h.is_monster()).size() < 2:
					return false
			"onomatopaira":
				if int(ps.once_names.get("Onomatopaira", -1)) == s.turn or _onoma_pool(s, p).is_empty():
					return false
			"rank_up":
				if _rank_up_options(s, p, int(a[1]), str(a[2]), a.size() > 3).is_empty():
					return false
			"fake_hero":
				if ps.free_zone() == -1 or ps.no_summon_turn == s.turn or EffectRunner._take(ps.hand.filter(func(h): return h != c and not CardEffects.of(h.cname()).get("no_special", false)), {"has": "Elemental HERO"}, 1).is_empty():
					return false
			"righteous_justice":
				if _justice_pool(s, c).size() < _ehero_count(s, p) or _ehero_count(s, p) == 0:
					return false
			"burst_return":
				var any_b := false
				for q in 2:
					for m in s.players[q].monsters():
						if m.face_up and str(m.data.get("name", "")).contains("Elemental HERO") and m.cname() != "Elemental HERO Burstinatrix":
							any_b = true
				if not any_b:
					return false
			"feather_shot":
				if s.current != p or s.phase == DuelState.Phase.MAIN2:
					return false
			"transcendent_wings":
				var kuri: Array = ps.monsters().filter(func(m): return str(m.data.get("name", "")) == "Winged Kuriboh")
				var lv10: Array = (ps.hand + ps.deck).filter(func(x): return x.cname() == "Winged Kuriboh LV10")
				var spare := ps.hand.filter(func(h): return h != c).size()
				# (A LV10 in the hand cannot also be one of the 2 cards sent, unless another copy waits in the Deck.)
				if ps.deck.filter(func(x): return x.cname() == "Winged Kuriboh LV10").is_empty():
					spare -= 1
				if kuri.is_empty() or lv10.is_empty() or spare < 2 or ps.no_summon_turn == s.turn:
					return false
			"gy_to_hand":
				if EffectRunner._take(ps.gy, a[1], 1).is_empty():
					return false
			"search":
				if EffectRunner._take(ps.deck, a[1], 1).is_empty():
					return false
			"bury":
				if s._best_monsters(ps.deck, 1).is_empty():
					return false
			"ritual":
				if ritual_plan(s, p, c).is_empty():
					return false
			"miracle_fusion":
				if _gy_fusions(s, p, a[1]).is_empty():
					return false
			"negate_attack", "damage_attacker_atk", "heal_attacker_atk", "end_battle":
				if s.pending_attack.is_empty() or s.pending_attack["player"] == p:
					return false
			"no_attacks":
				if s.current == p:
					return false
			"avarice":
				if s._best_monsters(ps.gy, 5).size() < 5:
					return false
			"sanctity":
				# "(min. 1 total)": there has to be at least one other card to banish.
				var others := ps.monsters().size() + ps.set_cards().size() + (ps.hand.size() - (1 if ps.hand.has(c) else 0))
				if others < 1:
					return false
			"damage_per":
				if _sel(s, p, c, str(a[1]), {}).is_empty():
					return false
	if sp.get("k", "") == "equip" and not sp.has("do") and targets(s, p, c).is_empty():
		return false
	return true


static func _needs_target(sp: Dictionary) -> bool:
	return sp.has("t") or (sp.get("k", "") == "equip" and not sp.has("do"))


static func _can_pay(s: DuelState, p: int, c, sp: Dictionary) -> bool:
	var ps := s.players[p]
	var cost: String = str(sp.get("cost", ""))
	if cost == "discard":
		return ps.hand.size() - (1 if ps.hand.has(c) else 0) >= 1
	if cost.begins_with("lp"):
		return ps.lp > int(cost.substr(2))
	if cost.begins_with("speed"):
		return ps.speed >= int(cost.substr(5))
	if cost == "tribute":
		return not ps.monsters().filter(func(m): return s.can_tribute_fx(m)).is_empty()
	if cost == "discard_f":
		return not ps.hand.filter(func(h): return h != c and CardEffects.matches(h.data, sp.get("cost_f", {}))).is_empty()
	if cost == "detach_any":
		return not ps.monsters().filter(func(m): return m.face_up and not m.overlays.is_empty()).is_empty()
	if cost == "tribute_f":
		return not ps.monsters().filter(func(m): return m.face_up and s.can_tribute_fx(m) and CardEffects.matches(m.data, sp.get("cost_f", {}))).is_empty()
	return true


static func pay_cost(s: DuelState, p: int, c, sp: Dictionary) -> Array:
	var ps := s.players[p]
	var events := []
	var cost: String = str(sp.get("cost", ""))
	if cost.begins_with("speed"):
		events.append_array(s._speed(p, -int(cost.substr(5))))
		return events
	if cost == "discard":
		var worst = null
		for h in ps.hand:
			if h != c and (worst == null or s._card_value(h) < s._card_value(worst)):
				worst = h
		worst = s.pick1(p, Loc.t("%s: discard 1 card as the cost") % c.cname(), ps.hand.filter(func(h): return h != c), worst, c)
		if worst != null:
			ps.hand.erase(worst)
			s._to_gy(ps, worst)
			events.append({"type": "discard", "player": p, "card": worst})
	elif cost.begins_with("lp"):
		var n := int(cost.substr(2))
		ps.lp -= n
		events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -n})
	elif cost == "half_lp":
		var n := ps.lp / 2
		ps.lp -= n
		events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": -n})
	elif cost == "discard_f":
		# "Send 1 monster from your hand to the GY" / "Discard 1 Dragon Tuner with 1000 or less ATK".
		var fit: Array = ps.hand.filter(func(h): return h != c and CardEffects.matches(h.data, sp.get("cost_f", {})))
		if not fit.is_empty():
			var least = fit[0]
			for h in fit:
				if s._card_value(h) < s._card_value(least):
					least = h
			least = s.pick1(p, Loc.t("%s: send 1 card from your hand to the Graveyard as the cost") % c.cname(), fit, least, c)
			ps.hand.erase(least)
			s._to_gy(ps, least)
			events.append({"type": "discard", "player": p, "card": least})
	elif cost == "detach_any":
		# "Detach 1 Xyz Material you control" (Xyz Energy).
		var holders: Array = ps.monsters().filter(func(m): return m.face_up and not m.overlays.is_empty())
		var most = holders[0]
		for m in holders:
			if m.overlays.size() > most.overlays.size():
				most = m
		most = s.pick1(p, Loc.t("%s: detach 1 material from which monster?") % c.cname(), holders, most, c)
		var mat = s.pick1(p, Loc.t("%s: detach which material?") % c.cname(), most.overlays, most.overlays.back(), c)
		most.overlays.erase(mat)
		s._to_gy(ps, mat)
		events.append({"type": "detach", "player": p, "card": most})
	elif cost == "tribute" or cost == "tribute_f":
		var weak = null
		var can_t: Array = ps.monsters().filter(func(m): return s.can_tribute_fx(m) and (cost == "tribute" or (m.face_up and CardEffects.matches(m.data, sp.get("cost_f", {})))))
		for m in can_t:
			if weak == null or s.atk_of(m, false) < s.atk_of(weak, false):
				weak = m
		weak = s.pick1(p, Loc.t("%s: Tribute 1 monster as the cost") % c.cname(), can_t, weak, c)
		if weak != null:
			ps.field[ps.field.find(weak)] = null
			s._to_gy(ps, weak)
			events.append({"type": "tribute", "player": p, "card": weak})
			events.append_array(EffectRunner.trigger(s, weak, "tributed"))
			events.append_array(s._monster_left(weak))
	return events


## Every legal target for this card (used for the player's choice and by the AI).
static func targets(s: DuelState, p: int, c) -> Array:
	var sp := spec(c)
	var t: String = str(sp.get("t", "any_face" if sp.get("k", "") == "equip" else ""))
	if sp.get("k", "") == "equip" and not sp.has("t"):
		t = "any_face"
	var out := []
	var opp_i := s.opponent(p)
	var must: Dictionary = sp.get("must", {})
	for q in 2:
		var mine := q == p
		for m in s.players[q].monsters():
			var ok := false
			match t:
				"opp_mon": ok = not mine
				"opp_face": ok = not mine and m.face_up
				"opp_def": ok = not mine and not m.attack_pos
				"opp_face_atk_le_lp": ok = not mine and m.face_up and s.atk_of(m, false) <= s.players[q].lp
				"own_mon": ok = mine
				"own_face": ok = mine and m.face_up
				"any_face": ok = m.face_up
				"any_mon", "any_card": ok = true
				"any_fdown": ok = not m.face_up
				"any_fusion": ok = m.face_up and m.frame() == "fusion"
			if ok and m.face_up and ((s.dragon_shield() and str(m.data.get("race", "")) == "Dragon") or (not m.negated and CardEffects.of(m.cname()).get("untargetable", false))):
				ok = false   # Lord of D. shields Dragons; Obelisk cannot be targeted
			if ok and m.face_up and str(m.data.get("race", "")) == "Machine" \
					and not s.players[m.owner].monsters().filter(func(x): return x.face_up and x.attack_pos and not x.negated and CardEffects.of(x.cname()).get("machine_guard", false)).is_empty():
				ok = false   # Cyber Phoenix: a Spell/Trap that targets 1 Machine its controller has does nothing
			if ok and sp.get("must_xyz_empty", false) and not (m.frame() == "xyz" and m.overlays.is_empty()):
				ok = false   # "1 face-up Xyz Monster on the field that has no Xyz Material" (Galaxy Storm)
			if ok and sp.get("must_rose", false) and not (m.cname() == "Black Rose Dragon" or str(m.data.get("race", "")) == "Plant"):
				ok = false   # "Equip only to "Black Rose Dragon" or a Plant-Type monster" (Thorn of Malice)
			if ok and sp.get("must_effect", false) and not EffectRunner._is_effect_monster(m):
				ok = false   # "targeting 1 Effect Monster" (Fiendish Chain)
			if ok and sp.get("must_neos_fusion", false) and not (m.frame() == "fusion" and neos_family(m)):
				ok = false   # "Equip only to a Fusion Monster that lists "Elemental HERO Neos" as material"
			if ok and (must.is_empty() or CardEffects.matches(m.data, must)) and (m.proper or not sp.get("must_proper", false)):
				out.append(m)
		var sts: Array = s.players[q].spells.duplicate()
		sts.append(s.players[q].field_spell)
		for st in sts:
			if st == null or st == c:
				continue
			var ok := false
			match t:
				"opp_st": ok = not mine
				"any_st", "any_card": ok = true
				"any_set_st": ok = not st.face_up
				"any_spell": ok = st.face_up and st.is_spell() or not st.face_up
				"any_face_trap": ok = st.face_up and st.is_trap()
			if ok:
				out.append(st)
	return out


## The target a sensible player would pick.
static func auto_target(s: DuelState, p: int, c) -> Variant:
	var list := targets(s, p, c)
	if list.is_empty():
		return null
	var sp := spec(c)
	var helpful: bool = sp.get("k", "") == "equip" and not sp.get("control", false) and int(sp.get("atk", 1)) >= 0 and not sp.get("no_attack", false)
	for a in sp.get("do", []):
		if a[0] in ["atk", "def"] and int(a[2]) > 0:
			helpful = true
	var best = null
	var best_v := -1e9
	for x in list:
		# Whose side of the table it is on (a monster taken with Change of Heart is yours for now).
		var mine: bool = s.players[p].field.has(x) or s.players[p].spells.has(x) or s.players[p].field_spell == x
		var v := 0.0
		if x.is_monster():
			v = float(s.atk_of(x, false)) if x.face_up else 1200.0
			if helpful:
				v = v + 5000.0 if mine else -1e8
			else:
				v = v + 5000.0 if not mine else -1e8
		else:
			v = (3000.0 if x.face_up else 2500.0) if not mine else -1e8
		if v > best_v:
			best_v = v
			best = x
	return best if best_v > -1e7 else null


# ------------------------------------------------------------------ resolving

static func _ev(p: int, c, text: String) -> Dictionary:
	return {"type": "effect", "player": p, "card": c, "text": text}


## Cards a selector names. ctx: {"target", "subject"}
## Monsters picked out by a selector, minus any that are unaffected by this kind of card.
static func _sel(s: DuelState, p: int, c, sel: String, ctx: Dictionary) -> Array:
	var out: Array = []
	for x in _sel_raw(s, p, c, sel, ctx):
		if c != null and c.is_trap() and x.is_monster() and (EffectRunner.fx(x).get("trap_immune", false) or x.cname() == "Elemental HERO Wildheart"):
			continue
		# Silent Swordsman LV5 and Silent Magician LV8: unaffected by the opponent's Spell effects.
		# Silent Swordsman LV3: the opponent's Spell effects that target it are negated.
		if c != null and c.is_spell() and x.is_monster() and x.face_up and x.owner != p and (s.players[0].field.has(x) or s.players[1].field.has(x)):
			var xf := EffectRunner.fx(x)
			if xf.get("spell_immune_opp", false) or (sel == "target" and xf.get("spell_immune_opp_target", false)):
				continue
		out.append(x)
	return out


static func _sel_raw(s: DuelState, p: int, c, sel: String, ctx: Dictionary) -> Array:
	var opp_i := s.opponent(p)
	var mine := s.players[p]
	var opp := s.players[opp_i]
	var out := []
	match sel:
		"target":
			if ctx.get("target") != null:
				out.append(ctx["target"])
		"attacker":
			if not s.pending_attack.is_empty():
				out.append(s.pending_attack["attacker"])
		"summoned":
			if ctx.get("subject") != null and not (ctx["subject"] is Dictionary):
				out.append(ctx["subject"])
		"opp_mons": out = opp.monsters()
		"own_mons": out = mine.monsters()
		"all_mons": out = mine.monsters() + opp.monsters()
		"opp_face_mons":
			for m in opp.monsters():
				if m.face_up:
					out.append(m)
		"all_face_mons":
			for m in mine.monsters() + opp.monsters():
				if m.face_up:
					out.append(m)
		"all_fdown":
			for m in mine.monsters() + opp.monsters():
				if not m.face_up:
					out.append(m)
		"all_effect_mons":
			for m in mine.monsters() + opp.monsters():
				if m.face_up and m.frame() != "normal":
					out.append(m)
		"opp_atk_mons":
			for m in opp.monsters():
				if m.attack_pos:
					out.append(m)
		"lv4_all":
			for m in mine.monsters() + opp.monsters():
				if m.face_up and m.level() >= 4 and m.attack_pos:
					out.append(m)
		"opp_best_atk_pos", "opp_best_def", "opp_weakest", "best_atk_any":
			var pool: Array = opp.monsters() if sel != "best_atk_any" else mine.monsters() + opp.monsters()
			var best = null
			for m in pool:
				if not m.face_up or (sel == "opp_best_atk_pos" and not m.attack_pos):
					continue
				var v: int = s.def_of(m) if sel == "opp_best_def" else s.atk_of(m, false)
				if sel == "opp_weakest":
					v = -v
				if best == null or v > (s.def_of(best) if sel == "opp_best_def" else (s.atk_of(best, false) * (-1 if sel == "opp_weakest" else 1))):
					best = m
			if best != null and ctx.has("link"):
				if sel == "opp_weakest":
					# Share the Pain: the other player decides which of their monsters goes.
					best = s.pick1(opp_i, Loc.t("%s: choose 1 of your monsters to give up") % c.cname(), opp.monsters(), best, c)
				else:
					# A tie is the player's call.
					var bv: int = s.def_of(best) if sel == "opp_best_def" else s.atk_of(best, false)
					var ties: Array = []
					for m in pool:
						if m.face_up and not (sel == "opp_best_atk_pos" and not m.attack_pos) and (s.def_of(m) if sel == "opp_best_def" else s.atk_of(m, false)) == bv:
							ties.append(m)
					if ties.size() > 1:
						best = s.pick1(p, Loc.t("%s: these are tied. Choose 1") % c.cname(), ties, best, c)
			if best != null:
				out.append(best)
		"opp_st", "own_st", "all_st", "fields":
			for q in 2:
				if (sel == "opp_st" and q == p) or (sel == "own_st" and q != p):
					continue
				if sel != "fields":
					for st in s.players[q].spells:
						if st != null and st != c:
							out.append(st)
				if s.players[q].field_spell != null and s.players[q].field_spell != c:
					out.append(s.players[q].field_spell)
	return out


static func resolve(s: DuelState, link: Dictionary) -> Array:
	var c = link["card"]
	var p: int = link["player"]
	var sp: Dictionary = link["spec"]
	var ctx := {"target": link.get("target"), "subject": link.get("subject"), "link": link}
	var events := []
	var k: String = sp["k"]
	# A target that left the field (or flipped away) before resolution: the card fizzles.
	if _needs_target(sp):
		var t = ctx["target"]
		if t == null or not targets(s, p, c).has(t):
			link["stays"] = false
			events.append(_ev(p, c, Loc.t("%s has no target") % c.cname()))
			return events
	if k == "counter" and not sp.get("neg", []).is_empty():
		events.append_array(_negate(s, p, c, link))
	for a in sp.get("do", []):
		events.append_array(_run(s, p, c, a, ctx))
		if s.is_over():
			return events
	if (k == "equip" or sp.get("equip", false)) and not sp.has("do"):
		var t = ctx["target"]
		c.equipped_to = t
		events.append(_ev(p, c, Loc.t("%s is equipped to %s") % [c.cname(), t.cname()]))
		if t.face_up and not t.negated and EffectRunner.fx(t).get("destroy_equips", false):
			# Gearfried the Iron Knight: "If either player equips an Equip Card(s) to this card: Destroy that Equip Card(s)."
			events.append(_ev(t.owner, t, Loc.t("%s destroys %s") % [t.cname(), c.cname()]))
			c.equipped_to = null
			link["stays"] = false
			return events
		if sp.get("control", false):
			events.append_array(s._take_control(t, p, -1))
			if not s.players[p].field.has(t):
				link["stays"] = false
	elif k == "equip" and c.linked == null:
		link["stays"] = false
	if k == "ctrap" and sp.has("do") and sp["do"][0][0] == "revive" and c.linked == null:
		link["stays"] = false
	if sp.get("reset", false):
		c.face_up = false
		c.set_turn = s.turn
		link["reset"] = true
	return events


static func _negate(s: DuelState, p: int, c, link: Dictionary) -> Array:
	var events := []
	var subj = link.get("subject")
	if subj is Dictionary:
		subj["negated"] = true
		events.append(_ev(p, c, Loc.t("%s negates %s") % [c.cname(), subj["card"].cname()]))
		var sc = subj["card"]
		if subj["kind"] == "fx" and s.players[sc.owner].field.has(sc):
			events.append_array(s._destroy(sc))
	elif subj != null:
		events.append(_ev(p, c, Loc.t("%s negates the summon of %s") % [c.cname(), subj.cname()]))
		if s.players[subj.owner].field.has(subj):
			events.append_array(s._destroy(subj))
	return events


static func _run(s: DuelState, p: int, c, a: Array, ctx: Dictionary) -> Array:
	var ps := s.players[p]
	var opp_i := s.opponent(p)
	var opp := s.players[opp_i]
	var name: String = c.cname()
	var events := []
	match a[0]:
		"draw":
			events.append_array(s._draw(p, int(a[1])))
		"opp_draw":
			events.append_array(s._draw(opp_i, int(a[1])))
		"draw_to":
			var need := int(a[1]) - ps.hand.size()
			if need > 0:
				events.append_array(s._draw(p, need))
		"sanctity":
			# Card of Sanctity: banish every other card you control and in your hand, then draw until you hold 2.
			for h in ps.hand.duplicate():
				if h != c:
					events.append_array(s._banish(h))
			for m in ps.monsters():
				events.append_array(s._banish(m))
			for st in ps.spells.duplicate():
				if st != null and st != c:
					events.append_array(s._banish(st))
			if ps.field_spell != null and ps.field_spell != c:
				events.append_array(s._banish(ps.field_spell))
			var need2 := 2 - ps.hand.size()
			if need2 > 0:
				events.append_array(s._draw(p, need2))
		"opp_tribute":
			# Share the Pain: the opponent Tributes 1 monster of their choice.
			var theirs: Array = opp.monsters()
			if not theirs.is_empty():
				var weak2 = theirs[0]
				for m in theirs:
					if s.atk_of(m, false) < s.atk_of(weak2, false):
						weak2 = m
				var gone2 = s.pick1(s.opponent(p), Loc.t("%s: Tribute 1 of your monsters") % c.cname(), theirs, weak2, c)
				opp.field[opp.field.find(gone2)] = null
				s._to_gy(opp, gone2)
				events.append({"type": "tribute", "player": s.opponent(p), "card": gone2})
				events.append_array(EffectRunner.trigger(s, gone2, "tributed"))
				events.append_array(s._monster_left(gone2))
		"no_tribute":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.no_tribute_turn = s.turn
		"no_damage_turn":
			# Hallowed Life Barrier: no damage of any kind from the opponent's cards this turn.
			ps.no_damage_turn = s.turn
			ps.no_effect_damage_turn = s.turn
		"may_set":
			# Dust Tornado: then you can Set 1 Spell/Trap from your hand.
			var cands: Array = ps.hand.filter(func(h): return not h.is_monster() and kind(h) != "field")
			if not cands.is_empty() and ps.spells.find(null) != -1:
				var pick: Array = s.choose(p, Loc.t("%s: Set 1 Spell or Trap from your hand?") % c.cname(), cands, 1, [], true, c)
				if not pick.is_empty():
					var st2 = pick[0]
					var z := ps.spells.find(null)
					ps.hand.erase(st2)
					ps.spells[z] = st2
					st2.face_up = false
					st2.set_turn = s.turn
					events.append({"type": "set_st", "player": p, "card": st2, "zone": z})
		"may_special_named":
			# Macro Cosmos: you can Special Summon the named monster from your hand or Deck.
			var found = null
			for src in [ps.hand, ps.deck]:
				for h in src:
					if found == null and h.cname() == str(a[1]):
						found = h
			if found != null and ps.free_zone() != -1 and s.choose_option(p, Loc.t("%s: Special Summon %s?") % [c.cname(), str(a[1])], ["Special Summon it", "No"], 0, c) == 0:
				ps.hand.erase(found)
				ps.deck.erase(found)
				events.append_array(s._special(p, found, "effect"))
		"purge_copies":
			# Nobleman of Crossout / Extermination: if what was banished was a Flip monster (or a Trap),
			# both players banish every copy of it from their Main Decks.
			var t0 = ctx.get("target")
			if t0 != null:
				var is_it: bool = t0.is_trap() if str(a[1]) == "trap" else (CardEffects.of(t0.cname()).has("flip") or str(t0.data.get("desc", t0.data.get("text", ""))).begins_with("FLIP"))
				if is_it:
					for q in 2:
						for d in s.players[q].deck.duplicate():
							if d.cname() == t0.cname():
								events.append_array(s._banish(d))
		"discard":
			var by_value: Array = ps.hand.duplicate()
			by_value.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
			var dn := mini(int(a[1]), by_value.size())
			for worst in s.choose(p, Loc.t("%s: discard %d card%s") % [c.cname(), dn, "" if dn == 1 else "s"], ps.hand, dn, by_value.slice(0, dn), false, c):
				ps.hand.erase(worst)
				s._to_gy(ps, worst)
				events.append({"type": "discard", "player": p, "card": worst})
		"card_destruction":
			for q in [p, opp_i]:
				var qs := s.players[q]
				var n := qs.hand.size()
				for h in qs.hand.duplicate():
					qs.hand.erase(h)
					s._to_gy(qs, h)
					events.append({"type": "discard", "player": q, "card": h})
				events.append_array(s._draw(q, n))
		"avarice":
			for g in s.choose(p, Loc.t("%s: shuffle 5 monsters from your Graveyard into the Deck") % c.cname(), s._best_monsters(ps.gy, 99), 5, s._best_monsters(ps.gy, 5), false, c):
				ps.gy.erase(g)
				ps.deck.append(g)
				events.append({"type": "gy_to_deck", "player": p, "card": g, "deck": ps.deck.size()})
			s._shuffle(ps.deck)
			events.append_array(s._draw(p, 2))
		"speed":
			events.append_array(s._speed(p, int(a[1])))
		"damage":
			events.append_array(s._damage(opp_i, int(a[1])))
		"self_damage":
			events.append_array(s._damage(p, int(a[1])))
		"heal", "opp_heal":
			var q := p if a[0] == "heal" else opp_i
			s.players[q].lp += int(a[1])
			events.append({"type": "lp", "player": q, "lp": s.players[q].lp, "delta": int(a[1])})
		"damage_per":
			var n := _sel(s, p, c, str(a[1]), ctx).size()
			if n > 0:
				events.append_array(s._damage(opp_i, n * int(a[2])))
		"destroy", "banish", "bounce":
			for t in _sel(s, p, c, str(a[1]), ctx):
				if a[0] == "banish":
					events.append_array(s._banish(t))
				elif a[0] == "bounce":
					events.append_array(s._bounce(t))
				elif t.is_monster():
					if s.players[t.owner].field.has(t):
						events.append_array(s._destroy(t))
				else:
					events.append_array(s._destroy_st(t))
		"negate_attack":
			if not s.pending_attack.is_empty():
				s.pending_attack["negated"] = true
		"draw_if_own":
			# "Then, if you control a "Lumen" monster, draw 1 card."
			for m in ps.monsters():
				if m.face_up and m.cname().contains(str(a[1])):
					events.append_array(s._draw(p, int(a[2])))
					break
		"echo_resonance":
			var lumen = echo_tribute(s, p)
			var big = echo_radiant(s, p)
			if lumen == null or big == null:
				return events
			var z := ps.field.find(lumen)
			ps.field[z] = null
			s._to_gy(ps, lumen)
			events.append({"type": "tribute", "player": p, "card": lumen, "zone": z})
			events.append_array(s._monster_left(lumen))
			var from_deck: bool = ps.deck.has(big)
			if from_deck:
				ps.deck.erase(big)
				s._shuffle(ps.deck)
			else:
				ps.hand.erase(big)
			events.append(_ev(p, c, Loc.t("%s answers the call") % big.cname()))
			big.proper = true
			events.append_array(s._special(p, big, "effect"))
			events.append_array(EffectRunner.on_summon(s, p, big, "special"))
		"end_battle":
			if not s.pending_attack.is_empty():
				s.pending_attack["negated"] = true
				s.players[s.pending_attack["player"]].no_attack_turn = s.turn
				events.append(_ev(p, c, "The Battle Phase ends"))
		"no_attacks":
			s.players[s.current].no_attack_turn = s.turn
			events.append(_ev(p, c, "No attacks this turn"))
		"no_attacks_both":
			for q in 2:
				s.players[q].no_attack_turn = s.turn + int(a[1])
		"no_battle_damage":
			ps.no_damage_turn = s.turn
			events.append(_ev(p, c, "No battle damage this turn"))
		"protect":
			ps.protect_turn = s.turn
		"damage_attacker_atk":
			if not s.pending_attack.is_empty():
				events.append_array(s._damage(opp_i, s.atk_of(s.pending_attack["attacker"], true)))
		"heal_attacker_atk":
			if not s.pending_attack.is_empty():
				var n: int = s.atk_of(s.pending_attack["attacker"], true)
				ps.lp += n
				events.append({"type": "lp", "player": p, "lp": ps.lp, "delta": n})
		"special_named":
			# 1 card with that name from the places listed (Dark Magic Curtain: the Deck; Sage's Stone: hand or Deck).
			for where in a[2]:
				var src_n: Array = ps.deck if where == "deck" else (ps.hand if where == "hand" else ps.gy)
				var got_c: Array = EffectRunner._take(src_n.filter(func(h): return h != c and (where != "gy" or s.can_revive(h))), {"name": str(a[1])}, 1)
				if not got_c.is_empty() and ps.free_zone() != -1:
					var named = got_c[0]
					src_n.erase(named)
					if where == "deck":
						s._shuffle(ps.deck)
					events.append(_ev(p, c, Loc.t("%s calls %s") % [name, named.cname()]))
					events.append_array(s._special(p, named, "reborn" if where == "gy" else "effect"))
					events.append_array(EffectRunner.on_summon(s, p, named, "special"))
					break
		"no_more_summons":
			ps.no_summon_turn = s.turn   # "You cannot Summon other monsters the turn you activate this card (but you can Normal Set)."
		"give_pick":
			# Mystic Box: after the first target is destroyed, 1 monster of yours goes to the opponent.
			var gifts_m: Array = ps.monsters()
			if not gifts_m.is_empty() and opp.free_zone() != -1:
				gifts_m.sort_custom(func(x, y): return s.atk_of(x, false) < s.atk_of(y, false))
				var given = s.pick1(p, Loc.t("%s: give control of 1 of your monsters to your opponent") % name, gifts_m, gifts_m[0], c)
				events.append_array(s._take_control(given, opp_i, -1))
		"despell":
			# "Destroy that target if it is a Spell. (If the target is Set, reveal it.)"
			for t in _sel(s, p, c, "target", ctx):
				if t.is_spell():
					events.append_array(s._destroy_st(t))
				else:
					events.append(_ev(p, c, Loc.t("%s is revealed: it is not a Spell") % t.cname()))
		"lightforce":
			# 1 random card from their hand is set aside until their 4th Standby Phase from now.
			if not opp.hand.is_empty():
				var taken = opp.hand[s._rng.randi() % opp.hand.size()]
				opp.hand.erase(taken)
				opp.banished.append(taken)
				opp.exiles.append({"card": taken, "to": opp_i, "left": int(a[1]), "atk_pos": true, "to_hand": true})
				events.append({"type": "discard", "player": opp_i, "card": taken})
				events.append(_ev(p, c, Loc.t("%s sets a card from the opponent's hand aside for %d of their turns") % [name, int(a[1])]))
		"chain_destruction":
			# Every card with that monster's name in its controller's hand and Deck is destroyed.
			var subj_c = ctx.get("subject")
			if subj_c != null and not (subj_c is Dictionary):
				var side_i: int = 0 if s.players[0].field.has(subj_c) else 1
				var side_ps: DuelState.PlayerState = s.players[side_i]
				var gone_n := 0
				for pile in [side_ps.hand, side_ps.deck]:
					for same in pile.filter(func(x): return x.cname() == subj_c.cname()):
						pile.erase(same)
						s._to_gy(side_ps, same)
						gone_n += 1
						events.append({"type": "mill", "player": side_i, "card": same, "deck": side_ps.deck.size()})
				events.append(_ev(p, c, Loc.t("%s: %d more \"%s\" destroyed in the hand and Deck") % [name, gone_n, subj_c.cname()]))
		"gold_sarcophagus":
			# 1 card from your Deck is banished face-up; it comes to your hand in your 2nd Standby Phase from now.
			if not ps.deck.is_empty():
				var by_worth: Array = ps.deck.duplicate()
				by_worth.sort_custom(func(x, y): return s._card_value(x) > s._card_value(y))
				var chosen = s.pick1(p, Loc.t("%s: banish 1 card from your Deck; it comes to your hand in 2 turns") % name, by_worth, by_worth[0], c)
				ps.deck.erase(chosen)
				s._shuffle(ps.deck)
				ps.banished.append(chosen)
				ps.exiles.append({"card": chosen, "to": p, "left": int(a[1]), "atk_pos": true, "to_hand": true})
				events.append({"type": "banish", "player": p, "card": chosen, "from": "deck"})
				events.append(_ev(p, c, Loc.t("%s seals %s away for %d turns") % [name, chosen.cname(), int(a[1])]))

		"mill_self":
			for i in int(a[1]):
				if not ps.deck.is_empty():
					var top = ps.deck.pop_back()
					s._to_gy(ps, top)
					events.append({"type": "mill", "player": p, "card": top, "deck": ps.deck.size()})
		"special_hand_deck":
			# One for One: 1 monster that fits, from your hand or Deck.
			var both: Array = ps.hand.filter(func(h): return h != c)
			both.append_array(ps.deck)
			both = both.filter(func(x): return not CardEffects.of(x.cname()).get("no_special", false))
			for d in EffectRunner._pick(s, p, c, Loc.t("Special Summon 1 monster from your hand or Deck"), both, a[1], 1):
				if ps.free_zone() == -1:
					break
				var from_deck: bool = ps.deck.has(d)
				ps.hand.erase(d)
				ps.deck.erase(d)
				if from_deck:
					s._shuffle(ps.deck)
				events.append(_ev(p, c, Loc.t("%s calls %s") % [name, d.cname()]))
				events.append_array(s._special(p, d, "effect"))
				events.append_array(EffectRunner.on_summon(s, p, d, "special"))
		"extra_normal":
			ps.extra_normals += 1
			events.append(_ev(p, c, Loc.t("%s: you can Normal Summon or Set one more time this turn") % name))
		"atk_per_mat":
			# Synchro Strike: 500 ATK for each Synchro Material used to Summon it, until the End Phase.
			for t in _sel(s, p, c, "target", ctx):
				var gain: int = int(a[1]) * int(t.tags.get("mats", 2))
				t.atk_mod_t = (t.atk_mod_t if t.atk_mod_turn == s.turn else 0) + gain
				t.atk_mod_turn = s.turn
				events.append(_ev(p, t, Loc.t("%s: %+d ATK") % [t.cname(), gain]))
		"lost_star":
			# Descending Lost Star: a Synchro Monster from your Graveyard, in Defense Position, effects
			# negated, Level 1 lower, DEF 0, and it cannot change its battle position.
			var syn: Array = ps.gy.filter(func(x): return x.frame() == "synchro" and s.can_revive(x))
			if not syn.is_empty() and ps.free_zone() != -1:
				syn.sort_custom(func(x, y): return x.level() > y.level())
				var star = s.pick1(p, Loc.t("%s: Special Summon 1 Synchro Monster from your Graveyard") % name, syn, syn[0], c)
				ps.gy.erase(star)
				events.append_array(s._special(p, star, "reborn", "def"))
				star.neg_perm = true
				star.negated = true
				star.lv_set = maxi(1, int(star.data.get("level", 1)) - 1)
				star.lv_turn = -1
				star.def_mod = -star.def()
				star.pos_lock_until = 99999
				events.append(_ev(p, c, Loc.t("%s returns at Level %d with 0 DEF and no effects") % [star.cname(), star.lv_set]))
		"no_damage_until":
			ps.no_damage_until = s.turn + int(a[1])
			events.append(_ev(p, c, Loc.t("%s: you take no damage until the End Phase of the next turn") % name))
		"battle_shield":
			if not s.pending_attack.is_empty():
				s.pending_attack["no_damage_to"] = p
				events.append(_ev(p, c, Loc.t("%s: no battle damage from this battle") % name))
		"starlight":
			# Negate that effect and destroy the card; then you can call Stardust Dragon from the Extra Deck.
			var bad_link = ctx.get("subject")
			if bad_link is Dictionary:
				events.append_array(EffectRunner._negate_link(s, p, c, bad_link))
				for x in ps.extra.duplicate():
					if x.cname() == "Stardust Dragon" and ps.free_zone() != -1 and ps.no_summon_turn != s.turn:
						if s.choose_option(p, Loc.t("%s: Special Summon Stardust Dragon from your Extra Deck?") % name, ["Special Summon it", "No"], 0, c) == 0:
							ps.extra.erase(x)
							events.append_array(s._special(p, x, "effect"))
						break
		"synchro_now":
			# Urgent Tuning: a Synchro Summon right now, with monsters you control.
			var ready: Array = _synchro_options(s, p)
			if not ready.is_empty():
				ready.sort_custom(func(x, y): return x.atk() > y.atk())
				var made = s.pick1(p, Loc.t("%s: Synchro Summon which monster?") % name, ready, ready[0], c)
				events.append_array(s.extra_summon(p, made, [], true))
		"give_and_take":
			var gifts: Array = ps.gy.filter(func(x): return s.can_revive(x))
			var takers: Array = ps.monsters().filter(func(m): return m.face_up and m.frame() != "xyz")
			if not gifts.is_empty() and not takers.is_empty() and opp.free_zone() != -1:
				gifts.sort_custom(func(x, y): return x.atk() < y.atk())
				var gift = s.pick1(p, Loc.t("%s: Special Summon 1 monster from your Graveyard to your opponent's field") % name, gifts, gifts[0], c)
				var taker = s.pick1(p, Loc.t("%s: which of your monsters gains its Level?") % name, takers, takers[0], c)
				ps.gy.erase(gift)
				gift.orig_owner = p
				gift.owner = opp_i
				events.append_array(s._special(opp_i, gift, "reborn", "def"))
				var lv_gain: int = int(gift.data.get("level", 0))
				taker.lv_set = taker.level() + lv_gain
				taker.lv_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s is Level %d until the End Phase") % [taker.cname(), taker.lv_set]))
		"infernity_inferno":
			# "Discard up to 2 cards, and send the same number of "Infernity" cards from your Deck to the Graveyard."
			var hand_i: Array = ps.hand.filter(func(h): return h != c)
			var in_deck: Array = ps.deck.filter(func(x): return x.cname().contains("Infernity"))
			var most_i: int = mini(2, mini(hand_i.size(), in_deck.size()))
			if most_i < 1:
				return events
			var by_i: Array = hand_i.duplicate()
			by_i.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
			var tossed: Array = s.choose(p, Loc.t("%s: discard up to 2 cards") % name, hand_i, most_i, by_i.slice(0, most_i), true, c)
			for h in tossed:
				ps.hand.erase(h)
				s._to_gy(ps, h)
				events.append({"type": "discard", "player": p, "card": h})
			in_deck.sort_custom(func(x, y): return (1 if x.is_monster() else 0) > (1 if y.is_monster() else 0))
			for x in s.choose(p, Loc.t("%s: send %d \"Infernity\" cards from your Deck to the Graveyard") % [name, tossed.size()], in_deck, tossed.size(), in_deck.slice(0, tossed.size()), false, c) if not tossed.is_empty() else []:
				ps.deck.erase(x)
				s._to_gy(ps, x)
				events.append({"type": "mill", "player": p, "card": x, "deck": ps.deck.size()})
			s._shuffle(ps.deck)
		"infernity_break":
			# "Target 1 "Infernity" card in your Graveyard and 1 card your opponent controls; banish the first target, and if you do, destroy the second target."
			var mine_b: Array = ps.gy.filter(func(g): return g.cname().contains("Infernity"))
			var theirs_b: Array = opp.monsters() + opp.set_cards()
			if opp.field_spell != null:
				theirs_b.append(opp.field_spell)
			if mine_b.is_empty() or theirs_b.is_empty() or not ps.hand.is_empty():
				return events
			var worst_b = mine_b[0]
			for g in mine_b:
				if s._card_value(g) < s._card_value(worst_b):
					worst_b = g
			var best_b = EffectRunner._best_opp(s, p)
			if best_b == null:
				best_b = theirs_b[0]
			events.append_array(s._banish(s.pick1(p, Loc.t("%s: banish which \"Infernity\" card from your Graveyard?") % name, mine_b, worst_b, c)))
			var hit_b = s.pick1(p, Loc.t("%s: destroy which card?") % name, theirs_b, best_b, c)
			events.append_array(s._destroy(hit_b) if hit_b.is_monster() and opp.field.has(hit_b) else s._destroy_st(hit_b))
		"special_deck_f":
			# 1 monster of these families and Levels from your Deck (Accellight, Galaxy Expedition). Once per turn by name.
			ps.once_names[str(a[1])] = s.turn
			var fam: Array = _deck_family(s, p, a[2], int(a[3]), int(a[4]))
			if fam.is_empty() or ps.free_zone() == -1:
				return events
			fam.sort_custom(func(x, y): return x.atk() > y.atk())
			var got_f = s.pick1(p, Loc.t("%s: Special Summon which monster from your Deck?") % name, fam, fam[0], c)
			ps.deck.erase(got_f)
			s._shuffle(ps.deck)
			events.append(_ev(p, c, Loc.t("%s calls %s") % [name, got_f.cname()]))
			events.append_array(s._special(p, got_f, "effect", str(a[5])))
			events.append_array(EffectRunner.on_summon(s, p, got_f, "special"))
		"special_from_hand":
			for d in EffectRunner._pick(s, p, c, Loc.t("Special Summon 1 monster from your hand"), ps.hand.filter(func(h): return h != c and not CardEffects.of(h.cname()).get("no_special", false)), a[1], 1):
				if ps.free_zone() == -1:
					break
				ps.hand.erase(d)
				events.append(_ev(p, c, Loc.t("%s calls %s") % [name, d.cname()]))
				events.append_array(s._special(p, d, "effect", str(a[2]) if a.size() > 2 else ""))
				events.append_array(EffectRunner.on_summon(s, p, d, "special"))
		"linked_no_attack":
			if c.linked != null:
				c.linked.attack_count_turn = s.turn
				c.linked.attack_count = 99
		"jam_defender":
			# "target 1 "Revival Jam" you control; switch the attack target to that target."
			var jams: Array = ps.monsters().filter(func(m): return m.face_up and m.cname() == "Revival Jam")
			if not jams.is_empty() and not s.pending_attack.is_empty():
				s.pending_attack["target"] = jams[0]
				events.append(_ev(p, c, Loc.t("%s: the attack is turned onto %s") % [name, jams[0].cname()]))
		"trap_stun":
			s.trap_stun_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s: every other Trap effect on the field is negated this turn") % name))
		"against_wind":
			# "Select 1 "Blackwing" monster in your Graveyard. Take damage equal to the ATK of the selected monster, and add it to your hand."
			var pool_a: Array = ps.gy.filter(func(g): return g.is_monster() and g.cname().contains("Blackwing"))
			var safe_a: Array = pool_a.filter(func(g): return g.atk() < ps.lp)
			if pool_a.is_empty():
				return events
			var best_a = (safe_a if not safe_a.is_empty() else pool_a)[0]
			for g in safe_a:
				if g.atk() < best_a.atk():
					best_a = g
			best_a = s.pick1(p, Loc.t("%s: add which \"Blackwing\" monster to your hand?") % name, pool_a, best_a, c)
			events.append_array(s._damage(p, best_a.atk()))
			if not s.is_over():
				ps.gy.erase(best_a)
				ps.hand.append(best_a)
				events.append({"type": "gy_to_hand", "player": p, "card": best_a})
		"no_normal":
			# Blackback: "You cannot Normal Summon/Set during the turn you activate this card."
			s.normal_summoned = true
			ps.extra_normals = 0
		"linked_boost":
			# Powerful Rebirth: "Increase its Level by 1 and ATK/DEF by 100."
			if c.linked != null:
				c.linked.lv_set = c.linked.level() + int(a[1])
				c.linked.lv_turn = -1
				c.linked.atk_mod += int(a[2])
				c.linked.def_mod += int(a[2])
		"half_or_nothing":
			# "Your opponent chooses: halve the ATK of all monsters they currently control until the end of the Battle Phase, or end the Battle Phase."
			var strong := 0
			for m in opp.monsters():
				if m.face_up and m.attack_pos and s.attacks_left(m) > 0:
					strong += s.atk_of(m, false) / 2
			if s.choose_option(opp_i, Loc.t("%s: choose one") % name, ["Halve the ATK of all your monsters this Battle Phase", "End the Battle Phase"], 0 if strong >= 1500 else 1, c) == 0:
				for m in opp.monsters():
					m.half_turn = s.turn
				events.append(_ev(opp_i, c, Loc.t("%s: the ATK of their monsters is halved for this Battle Phase") % name))
			else:
				if not s.pending_attack.is_empty():
					s.pending_attack["negated"] = true
				opp.no_attack_turn = s.turn
				events.append(_ev(opp_i, c, Loc.t("%s: the Battle Phase ends") % name))
		"dice_all":
			# "Roll a six-sided die. All monsters you currently control gain / your opponent currently controls lose ATK/DEF equal to the result x 100, until the end of this turn."
			var roll: int = randi() % 6 + 1
			var amt: int = roll * 100 * int(a[2])
			events.append(_ev(p, c, Loc.t("%s: the die shows %d") % [name, roll]))
			for m in (ps.monsters() if a[1] == "own" else opp.monsters()):
				if not m.face_up:
					continue
				if m.atk_mod_turn != s.turn:
					m.atk_mod_turn = s.turn
					m.atk_mod_t = 0
				m.atk_mod_t += amt
				m.tags["tmp_def"] = (int(m.tags.get("tmp_def", 0)) if int(m.tags.get("tmp_def_until", -1)) >= s.turn else 0) + amt
				m.tags["tmp_def_until"] = s.turn
		"shield_sword":
			# "Switch the original ATK and DEF of all face-up monsters currently on the field, until the end of this turn."
			for q in 2:
				for m in s.players[q].monsters():
					if not m.face_up:
						continue
					if m.atk_mod_turn != s.turn:
						m.atk_mod_turn = s.turn
						m.atk_mod_t = 0
					m.atk_mod_t += m.def() - m.atk()
					m.tags["tmp_def"] = (int(m.tags.get("tmp_def", 0)) if int(m.tags.get("tmp_def_until", -1)) >= s.turn else 0) + m.atk() - m.def()
					m.tags["tmp_def_until"] = s.turn
			events.append(_ev(p, c, Loc.t("%s: every face-up monster's ATK and DEF are switched until the end of this turn") % name))
		"flute":
			# "Special Summon up to 2 Dragon monsters from your hand."
			var drs: Array = ps.hand.filter(func(h): return h != c and h.is_monster() and str(h.data.get("race", "")) == "Dragon" and not CardEffects.of(h.cname()).get("no_special", false) and not CardData.is_extra(h.id))
			drs.sort_custom(func(x, y): return x.atk() > y.atk())
			if not cond_ok(s, p, "lord_of_d"):
				return events
			for d in s.choose(p, Loc.t("%s: Special Summon up to 2 Dragons from your hand") % name, drs, 2, drs.slice(0, 2), true, c):
				if ps.free_zone() == -1:
					break
				ps.hand.erase(d)
				events.append(_ev(p, c, Loc.t("%s calls %s") % [name, d.cname()]))
				events.append_array(s._special(p, d, "effect"))
				events.append_array(EffectRunner.on_summon(s, p, d, "special"))
		"crush_card":
			# The opponent takes no damage until the end of the next turn; their monsters with 1500 or more ATK, on the field and in the hand, are destroyed.
			opp.no_damage_until = s.turn + 1
			events.append(_ev(p, c, Loc.t("%s: the opponent takes no damage until the end of the next turn") % name))
			for m in opp.monsters():
				if s.atk_of(m, false) >= 1500 or (not m.face_up and m.atk() >= 1500):
					events.append_array(s._destroy(m))
			for h in opp.hand.duplicate():
				if h.is_monster() and h.atk() >= 1500:
					opp.hand.erase(h)
					s._to_gy(opp, h)
					events.append(_ev(p, c, Loc.t("%s is destroyed in the hand") % h.cname()))
					events.append({"type": "discard", "player": opp_i, "card": h})
			# "...then your opponent can destroy up to 3 monsters with 1500 or more ATK in their Deck."
			var deck_big: Array = opp.deck.filter(func(x): return x.is_monster() and x.atk() >= 1500)
			if not deck_big.is_empty():
				for x in s.choose(opp_i, Loc.t("%s: destroy up to 3 monsters with 1500 or more ATK in your Deck?") % name, deck_big, 3, [], true, c):
					opp.deck.erase(x)
					s._to_gy(opp, x)
					events.append({"type": "mill", "player": opp_i, "card": x, "deck": opp.deck.size()})
		"cost_down":
			for h in ps.hand:
				if h.is_monster() and h.level() > 0:
					h.lv_set = maxi(1, h.level() - 2)
					h.lv_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s: the monsters in your hand are 2 Levels lower this turn") % name))
		"burst_lock":
			for m in ps.monsters():
				if m.cname() == "Blue-Eyes White Dragon":
					m.attack_count_turn = s.turn
					m.attack_count = 99
		"exile_end":
			for t in _sel(s, p, c, str(a[1]), ctx):
				var pos_x: bool = t.attack_pos
				var side_x: int = 0 if s.players[0].field.has(t) else 1
				events.append(_ev(p, c, Loc.t("%s is banished until the End Phase") % t.cname()))
				events.append_array(s._banish(t))
				if s.players[t.owner].banished.has(t):
					s.players[side_x].exiles.append({"card": t, "to": side_x, "left": 0, "atk_pos": pos_x, "end": true})
		"onomatopaira":
			# "choose up to 2 of these categories. For each chosen category, add one monster in that category from your Deck to your hand."
			ps.once_names["Onomatopaira"] = s.turn
			var pool_o: Array = _onoma_pool(s, p)
			var auto_o: Array = []
			var used_o := {}
			for cat in ["Gagaga", "Gogogo", "Dododo", "Zubaba"]:
				for x in pool_o:
					if auto_o.size() < 2 and not used_o.has(cat) and x.cname().contains(cat):
						auto_o.append(x)
						used_o[cat] = true
			var seen_o := {}
			for x in s.choose(p, Loc.t("%s: add up to 2 monsters, each from a different group (Zubaba, Gagaga, Gogogo, Dododo)") % name, pool_o, 2, auto_o, true, c):
				var cat_x := ""
				for cat in ["Gagaga", "Gogogo", "Dododo", "Zubaba"]:
					if cat_x == "" and x.cname().contains(cat) and not seen_o.has(cat):
						cat_x = cat
				if cat_x == "":
					continue
				seen_o[cat_x] = true
				ps.deck.erase(x)
				ps.hand.append(x)
				events.append({"type": "search", "player": p, "card": x, "deck": ps.deck.size()})
				events.append_array(EffectRunner.added_by_effect(s, p, x))
			s._shuffle(ps.deck)
		"rank_up":
			# Rank-Up-Magic Limited Barian's Force: a "Number C" monster 1 Rank higher, using your Rank 4 Xyz Monster as the material.
			var opts_r: Array = _rank_up_options(s, p, int(a[1]), str(a[2]), a.size() > 3)
			if opts_r.is_empty():
				return events
			var tops: Array = []
			for o in opts_r:
				if not tops.has(o[1]):
					tops.append(o[1])
			var best_top = tops[0]
			for x in tops:
				if x.atk() > best_top.atk():
					best_top = x
			best_top = s.pick1(p, Loc.t("%s: Special Summon which monster?") % name, tops, best_top, c)
			var bases: Array = []
			for o in opts_r:
				if o[1] == best_top:
					bases.append(o[0])
			var base_r = s.pick1(p, Loc.t("%s: use which monster as the material?") % name, bases, bases[0], c)
			events.append(_ev(p, c, Loc.t("%s: %s ranks up into %s") % [name, base_r.cname(), best_top.cname()]))
			events.append_array(s.xyz_onto(p, best_top, base_r))
			if a.size() > 4 and ps.field.has(best_top):
				# Barian's Force: "Then, if possible, detach 1 Xyz Material from a monster your opponent controls and attach it to the Summoned monster."
				for m in opp.monsters():
					if not m.overlays.is_empty():
						var took = m.overlays.pop_back()
						best_top.overlays.append(took)
						events.append(_ev(p, c, Loc.t("%s takes 1 material from %s") % [best_top.cname(), m.cname()]))
						events.append({"type": "detach", "player": opp_i, "card": m})
						break
		"winds":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.tmp_atk = (t.tmp_atk if t.tmp_until >= s.turn else 0) + 1000
				t.tmp_until = s.turn + 1
				t.tags["tmp_def"] = 1000
				t.tags["tmp_def_until"] = s.turn + 1
				events.append(_ev(p, c, Loc.t("%s gains 1000 ATK and DEF until your next Standby Phase") % t.cname()))
		"half_unbreak":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.tags["unbreak_turn"] = s.turn
				t.tags["unbreak_for"] = p
				events.append(_ev(p, c, Loc.t("%s cannot be destroyed by battle this turn, and the battle damage you take from its battles is halved") % (t.cname() if t.face_up else Loc.t("The face-down monster"))))
		"battle_break":
			# "Your opponent can reveal 1 monster in their hand to negate this card's effect, otherwise destroy the attacking monster, then end the Battle Phase."
			if s.pending_attack.is_empty():
				return events
			var shown: Array = opp.hand.filter(func(h): return h.is_monster())
			if not shown.is_empty() and s.choose_option(opp_i, Loc.t("%s: reveal 1 monster in your hand to negate it?") % name, ["Reveal a monster", "No"], 0, c) == 0:
				events.append(_ev(opp_i, shown[0], Loc.t("%s is revealed: %s is negated") % [shown[0].cname(), name]))
				return events
			var att_b = s.pending_attack["attacker"]
			events.append_array(s._destroy(att_b))
			s.pending_attack["negated"] = true
			s.players[s.current].no_attack_turn = s.turn
			events.append(_ev(p, c, Loc.t("%s: the Battle Phase ends") % name))
		"bye_bye":
			if not s.pending_attack.is_empty() and s.pending_attack["target"] != null:
				s._shield = s.pending_attack["target"]
				s.bye_bye = p
				events.append(_ev(p, c, Loc.t("%s: your monster is not destroyed by this battle, and the battle damage you take is dealt to the opponent doubled") % name))
		"fake_hero":
			# "Special Summon 1 "Elemental HERO" monster from your hand, but it cannot attack, also return it to the hand during the End Phase."
			for d in EffectRunner._pick(s, p, c, Loc.t("Special Summon 1 \"Elemental HERO\" monster from your hand"), ps.hand.filter(func(h): return h != c and not CardEffects.of(h.cname()).get("no_special", false)), {"has": "Elemental HERO"}, 1):
				if ps.free_zone() == -1:
					break
				ps.hand.erase(d)
				events.append(_ev(p, c, Loc.t("%s calls %s") % [name, d.cname()]))
				events.append_array(s._special(p, d, "effect"))
				d.tags["bounce_end"] = true
				d.attack_count_turn = s.turn
				d.attack_count = 99
				events.append_array(EffectRunner.on_summon(s, p, d, "special"))
		"hero_emerges":
			# "Your opponent chooses 1 random card from your hand, then if it is a monster that can be Special
			# Summoned, Special Summon it. Otherwise, send it to the GY."
			if ps.hand.is_empty():
				return events
			var got_h = ps.hand[randi() % ps.hand.size()]
			ps.hand.erase(got_h)
			events.append(_ev(p, c, Loc.t("%s: the card picked is %s") % [name, got_h.cname()]))
			var can_h: bool = got_h.is_monster() and not CardData.is_extra(got_h.id) and got_h.frame() != "ritual" and ps.free_zone() != -1 and ps.no_summon_turn != s.turn \
					and not CardEffects.of(got_h.cname()).get("no_special", false) and not "must be special summoned" in str(got_h.data.get("desc", "")).to_lower() \
					and not "must first be special summoned" in str(got_h.data.get("desc", "")).to_lower()
			if can_h:
				events.append_array(s._special(p, got_h, "effect"))
				events.append_array(EffectRunner.on_summon(s, p, got_h, "special"))
			else:
				s._to_gy(ps, got_h)
				events.append({"type": "discard", "player": p, "card": got_h})
		"righteous_justice":
			# "Destroy Spells/Traps on the field equal to the number of "Elemental HERO" cards you control."
			var n_j := _ehero_count(s, p)
			var pool_j: Array = _justice_pool(s, c)
			if n_j == 0 or pool_j.size() < n_j:
				return events
			var auto_j: Array = pool_j.filter(func(x): return x.owner != p)
			for x in pool_j:
				if auto_j.size() < n_j and not auto_j.has(x):
					auto_j.append(x)
			for x in s.choose(p, Loc.t("%s: destroy %d Spells/Traps") % [name, n_j], pool_j, n_j, auto_j.slice(0, n_j), false, c):
				events.append_array(s._destroy_st(x))
		"pierce_turn":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.tags["pierce_turn"] = s.turn
				events.append(_ev(p, c, Loc.t("%s inflicts piercing battle damage this turn") % t.cname()))
		"destroy_burn_atk":
			for t in _sel(s, p, c, str(a[1]), ctx):
				var burn_e: int = t.atk()
				events.append_array(s._destroy(t))
				events.append(_ev(p, c, Loc.t("%s: %d damage") % [name, burn_e]))
				events.append_array(s._damage(opp_i, burn_e))
		"burst_return":
			for q in [p, opp_i]:
				for m in s.players[q].monsters():
					if m.face_up and str(m.data.get("name", "")).contains("Elemental HERO") and m.cname() != "Elemental HERO Burstinatrix":
						events.append_array(s._bounce(m))
		"feather_shot":
			# "...that target can attack a number of times equal to the number of monsters you control when this
			# card resolves, but cannot attack directly, and other monsters you control cannot attack this turn."
			for t in _sel(s, p, c, str(a[1]), ctx):
				var n_f: int = ps.monsters().size()
				t.bonus_attacks = maxi(0, n_f - EffectRunner.max_attacks(t))
				t.bonus_attacks_turn = s.turn
				t.tags["no_direct_turn"] = s.turn
				ps.only_attacker = t.uid
				ps.only_attacker_turn = s.turn
				events.append(_ev(p, c, Loc.t("%s can attack %d times this turn, but not directly. Your other monsters cannot attack") % [t.cname(), n_f]))
		"transcendent_wings":
			# Cost: 1 "Winged Kuriboh" you control (face-up or face-down) and 2 cards from your hand go to the Graveyard.
			var kuri_t: Array = ps.monsters().filter(func(m): return str(m.data.get("name", "")) == "Winged Kuriboh")
			if kuri_t.is_empty():
				return events
			var k0 = kuri_t[0]
			ps.field[ps.field.find(k0)] = null
			s._to_gy(ps, k0)
			events.append({"type": "tribute", "player": p, "card": k0})
			events.append_array(s._monster_left(k0))
			var keep_t = null
			if ps.deck.filter(func(x): return x.cname() == "Winged Kuriboh LV10").is_empty():
				for h in ps.hand:
					if h.cname() == "Winged Kuriboh LV10":
						keep_t = h
			var hand_t: Array = ps.hand.filter(func(h): return h != c and h != keep_t)
			var by_v: Array = hand_t.duplicate()
			by_v.sort_custom(func(x, y): return s._card_value(x) < s._card_value(y))
			for h in s.choose(p, Loc.t("%s: send 2 cards from your hand to the Graveyard") % name, hand_t, 2, by_v.slice(0, 2), false, c):
				ps.hand.erase(h)
				s._to_gy(ps, h)
				events.append({"type": "discard", "player": p, "card": h})
			for src in [ps.hand, ps.deck]:
				var got_t: Array = src.filter(func(x): return x.cname() == "Winged Kuriboh LV10")
				if not got_t.is_empty() and ps.free_zone() != -1:
					src.erase(got_t[0])
					if src == ps.deck:
						s._shuffle(ps.deck)
					got_t[0].proper = true
					events.append(_ev(p, c, Loc.t("%s calls %s") % [name, got_t[0].cname()]))
					events.append_array(s._special(p, got_t[0], "effect"))
					break
		"slip_summon":
			for d in EffectRunner._pick(s, p, c, Loc.t("Special Summon 1 Level 4 or lower monster from your hand"), ps.hand.filter(func(h): return not CardEffects.of(h.cname()).get("no_special", false)), {"max_lv": 4}, 1):
				if ps.free_zone() == -1:
					break
				ps.hand.erase(d)
				events.append_array(s._special(p, d, "effect", "def"))
				d.tags["bounce_end"] = true
				events.append_array(EffectRunner.on_summon(s, p, d, "special"))
		"special_named_anywhere":
			# Limiter Overload: 1 "Speed Warrior" from your hand, Deck, or Graveyard.
			for src in [ps.hand, ps.deck, ps.gy]:
				var got_n: Array = EffectRunner._take(src, {"name": str(a[1])}, 1)
				if not got_n.is_empty() and ps.free_zone() != -1 and ps.no_summon_turn != s.turn:
					var sw = got_n[0]
					var was_gy: bool = src == ps.gy
					src.erase(sw)
					if src == ps.deck:
						s._shuffle(ps.deck)
					events.append(_ev(p, c, Loc.t("%s calls %s") % [name, sw.cname()]))
					events.append_array(s._special(p, sw, "reborn" if was_gy else "effect"))
					events.append_array(EffectRunner.on_summon(s, p, sw, "special"))
					break
		"egotist":
			# Elegant Egotist: Special Summon 1 "Harpie Lady" or "Harpie Lady Sisters" from your hand or Deck.
			var ladies := _egotist_pool(s, p)
			if not ladies.is_empty() and ps.free_zone() != -1:
				var best = ladies[0]
				for l in ladies:
					if l.atk() > best.atk():
						best = l
				var lady = s.pick1(p, Loc.t("%s: Special Summon 1 Harpie Lady or Harpie Lady Sisters from your hand or Deck") % c.cname(), ladies, best, c)
				var from_deck: bool = ps.deck.has(lady)
				ps.hand.erase(lady)
				ps.deck.erase(lady)
				lady.proper = true        # (this is the summon Harpie Lady Sisters must have first)
				events.append_array(s._special(p, lady, "effect"))
				events.append_array(EffectRunner.on_summon(s, p, lady, "special"))
				if from_deck:
					s._shuffle(ps.deck)
		"mirror_wall":
			# Activated while an opponent's monster is attacking: that monster is halved too.
			if not s.pending_attack.is_empty() and s.pending_attack["player"] != p and not s.pending_attack.get("negated", false):
				var att = s.pending_attack["attacker"]
				if att != null and not att.has_meta("mirror_wall"):
					att.set_meta("mirror_wall", c)
					events.append(_ev(p, c, Loc.t("%s: %s loses half its ATK") % [c.cname(), att.cname()]))
		"revive":
			var pool: Array = (ps.gy if a[1] == "own_gy" else ps.gy + opp.gy).filter(func(x): return s.can_revive(x))
			if a.size() > 4:
				pool = pool.filter(func(x): return CardEffects.matches(x.data, a[4]))
			var pick: Array = s._best_monsters(pool, 1)
			if not pick.is_empty() and ps.free_zone() != -1:
				var m = s.pick1(p, Loc.t("%s: Special Summon 1 monster from the Graveyard") % c.cname(), pool, pick[0], c)
				s.players[m.owner].gy.erase(m)
				m.owner = p
				events.append_array(s._special(p, m, "reborn", "def" if str(a[2]) == "def" else ("atk" if str(a[2]) == "atk" else "")))
				if a.size() > 3 and a[3] == "link":
					c.linked = m
					c.equipped_to = m if spec(c)["k"] == "equip" else null
				if a.size() > 5 and a[5] == "negate":
					m.neg_perm = true         # "Negate the effects of that monster on the field."
					m.negated = true
				events.append_array(EffectRunner.on_summon(s, p, m, "special"))
		"control":
			for t in _sel(s, p, c, str(a[1]), ctx):
				events.append_array(s._take_control(t, p, s.turn if a[2] == "eot" else -1))
		"no_attack":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.attack_count_turn = s.turn
				t.attack_count = 99
		"tribute_fodder":
			for t in _sel(s, p, c, str(a[1]), ctx):
				events.append_array(s._take_control(t, p, s.turn))
				ps.no_attack_turn = s.turn
		"atk":
			for t in _sel(s, p, c, str(a[1]), ctx):
				if a.size() > 3 and a[3] == "eot":
					t.atk_mod_t = (t.atk_mod_t if t.atk_mod_turn == s.turn else 0) + int(a[2])
					t.atk_mod_turn = s.turn
				else:
					t.atk_mod += int(a[2])
				events.append(_ev(p, t, Loc.t("%s: %+d ATK") % [t.cname(), int(a[2])]))
		"def":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.def_mod_t = int(a[2])
				t.def_mod_turn = s.turn
				events.append(_ev(p, t, Loc.t("%s: %+d DEF") % [t.cname(), int(a[2])]))
		"halve":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.half_turn = s.turn
				events.append(_ev(p, t, Loc.t("%s's ATK is halved") % t.cname()))
		"halve_perm":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.atk_mod -= t.atk() / 2
				events.append(_ev(p, t, Loc.t("%s's ATK is halved") % t.cname()))
		"flip_down":
			for t in _sel(s, p, c, str(a[1]), ctx):
				if s.players[t.owner].field.has(t) and t.face_up:
					t.face_up = false
					t.attack_pos = false
					t.reset_mods()
					events.append({"type": "position", "player": t.owner, "card": t, "zone": s.players[t.owner].field.find(t)})
		"flip_up":
			for t in _sel(s, p, c, str(a[1]), ctx):
				if s.players[t.owner].field.has(t) and not t.face_up:
					t.face_up = true
					events.append({"type": "reveal", "player": t.owner, "card": t, "zone": s.players[t.owner].field.find(t)})
		"change_pos", "to_def", "to_atk":
			for t in _sel(s, p, c, str(a[1]), ctx):
				if not s.players[t.owner].field.has(t):
					continue
				var want: bool = (not t.attack_pos) if a[0] == "change_pos" else (a[0] == "to_atk")
				if t.attack_pos == want and t.face_up:
					continue
				t.attack_pos = want
				t.face_up = true
				events.append({"type": "position", "player": t.owner, "card": t, "zone": s.players[t.owner].field.find(t)})
		"search":
			# (Offered best first: a monster you can Summon right away, the strongest one, before one you cannot.)
			var by_use: Array = ps.deck.duplicate()
			var fake_in_hand: bool = not ps.hand.filter(func(h): return h.cname() == "Fake Hero").is_empty()
			var has_toon_world: bool = not (ps.hand + ps.spells).filter(func(h): return h != null and h.cname() == "Toon World").is_empty()
			var use_of := func(x) -> int:
				if x.cname() == "Toon World" and not has_toon_world:
					return 9000   # (the Toons need it first)
				if not x.is_monster():
					return 500
				if has_toon_world and CardEffects.of(x.cname()).has("special_toon") and ps.monsters().size() >= int(CardEffects.of(x.cname())["special_toon"]):
					return 1000 + x.atk()
				if x.level() <= 4 or s.tributes_needed(x) == 0 or (fake_in_hand and str(x.data.get("name", "")).contains("Elemental HERO")):
					return 1000 + x.atk()
				return x.atk() / 10
			var val_of := {}
			for x in by_use:
				val_of[x.uid] = use_of.call(x)
			by_use.sort_custom(func(x, y): return int(val_of[x.uid]) > int(val_of[y.uid]) or (int(val_of[x.uid]) == int(val_of[y.uid]) and x.uid < y.uid))
			var got: Array = EffectRunner._pick(s, p, c, "add 1 card from your Deck to your hand", by_use, a[1], 1)
			for g in got:
				ps.deck.erase(g)
				ps.hand.append(g)
				events.append({"type": "search", "player": p, "card": g, "deck": ps.deck.size()})
			s._shuffle(ps.deck)
			for g in got:
				events.append_array(EffectRunner.added_by_effect(s, p, g))
		"gy_to_hand":
			for g in EffectRunner._pick(s, p, c, "add from your Graveyard to your hand", ps.gy, a[1], int(a[2])):
				ps.gy.erase(g)
				ps.hand.append(g)
				events.append({"type": "gy_to_hand", "player": p, "card": g})
		"bury":
			var pick: Array = s._best_monsters(ps.deck, 1)
			if not pick.is_empty():
				pick = [s.pick1(p, Loc.t("%s: send 1 monster from your Deck to the Graveyard") % c.cname(), s._best_monsters(ps.deck, 99), pick[0], c)]
				s._shuffle(ps.deck)
				ps.deck.erase(pick[0])
				s._to_gy(ps, pick[0])
				events.append({"type": "mill", "player": p, "card": pick[0], "deck": ps.deck.size()})
		"skip_draw":
			ps.skip_draw += int(a[1])
		"ring":
			var t = ctx.get("target")
			if t != null and s.players[t.owner].field.has(t):
				# Destroy it, take damage equal to its original ATK, then deal the same to the opponent.
				var n: int = int(t.data.get("atk", 0))
				events.append_array(s._destroy(t))
				var before: int = ps.lp
				events.append_array(s._damage(p, n))
				if not s.is_over() and ps.lp < before:
					events.append_array(s._damage(s.opponent(p), before - ps.lp))
		"ritual":
			events.append_array(_do_ritual(s, p, c))
		"miracle_fusion":
			var opts := _gy_fusions(s, p, a[1])
			if not opts.is_empty():
				var fcards: Array = []
				for o in opts:
					fcards.append(o["card"])
				var want = s.pick1(p, Loc.t("%s: Fusion Summon which monster?") % c.cname(), fcards, fcards[0], c)
				for o in opts:
					if o["card"] == want:
						events.append_array(s._do_fusion(p, o, true))
						break
		"all_to_def":
			# No Entry!!: "Change all Attack Position monsters to Defense Position."
			for q in [p, s.opponent(p)]:
				for m in s.players[q].monsters():
					if m.face_up and m.attack_pos:
						m.attack_pos = false
						events.append({"type": "position", "player": q, "card": m, "zone": s.players[q].field.find(m)})
		"misfortune":
			# Misfortune: "Inflict damage to your opponent equal to half that monster's original ATK. Your monsters cannot attack this turn."
			for t in _sel(s, p, c, "target", ctx):
				events.append_array(s._damage(s.opponent(p), t.atk() / 2))
			ps.no_attack_turn = s.turn
		"limiter_removal":
			# Limiter Removal: "Double the ATK of all Machine monsters you currently control, until the end of
			# this turn. During the End Phase of this turn, destroy those monsters."
			for m in ps.monsters():
				if m.face_up and str(m.data.get("race", "")) == "Machine":
					var now_l: int = s.atk_of(m, false)
					if m.atk_mod_turn != s.turn:
						m.atk_mod_t = 0
					m.atk_mod_turn = s.turn
					m.atk_mod_t += now_l
					m.tags["limiter"] = s.turn
					events.append({"type": "effect", "player": p, "card": m, "text": Loc.t("%s: ATK %d") % [m.cname(), now_l * 2]})
		"cyber_unit":
			# Photon Generator Unit / Attack Reflector Unit: Tribute that many "Cyber Dragon", then Special
			# Summon the named monster from the hand or Deck (or Graveyard).
			var fuel: Array = _cyber_dragons(s, p)
			var from_u: Array = _unit_pool(s, p, str(a[2]), bool(a[3]))
			if fuel.size() < int(a[1]) or from_u.is_empty():
				return events
			fuel.sort_custom(func(x, y): return x.atk() < y.atk())
			var paid_u: Array = s.choose(p, Loc.t("%s: Tribute %d Cyber Dragon") % [c.cname(), int(a[1])], fuel, int(a[1]), fuel.slice(0, int(a[1])), false, c)
			for m in paid_u:
				ps.field[ps.field.find(m)] = null
				s._to_gy(ps, m)
				events.append({"type": "tribute", "player": p, "card": m})
				events.append_array(EffectRunner.trigger(s, m, "tributed"))
				events.append_array(s._monster_left(m))
			var got_u = from_u[0]
			for src in [ps.hand, ps.deck, ps.gy]:
				src.erase(got_u)
			got_u.proper = true
			events.append_array(s._special(p, got_u, "effect"))
			s._shuffle(ps.deck)
		"dd_capsule":
			# Different Dimension Capsule: "Banish 1 card from your Deck face-down. After this card's activation, it remains on the field."
			if ps.deck.is_empty():
				return events
			var by_val: Array = ps.deck.duplicate()
			by_val.sort_custom(func(x, y): return s._card_value(x) > s._card_value(y))
			var kept = s.pick1(p, Loc.t("%s: banish 1 card from your Deck face-down") % c.cname(), by_val, by_val[0], c)
			ps.deck.erase(kept)
			ps.banished.append(kept)
			c.tags["capsule"] = kept.uid
			c.tags["ticks"] = 0
			s._shuffle(ps.deck)
			events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s: 1 card is sealed away for 2 turns") % c.cname()})
		"dd_capsule_tick":
			# "Destroy this card during your 2nd Standby Phase after activating this card, and if you do, add the banished card to the hand."
			if not c.tags.has("capsule"):
				return events
			c.tags["ticks"] = int(c.tags.get("ticks", 0)) + 1
			if int(c.tags["ticks"]) >= 2:
				var uid_c := int(c.tags["capsule"])
				events.append_array(s._destroy_st(c))
				if not ps.spells.has(c):
					for b in ps.banished:
						if b.uid == uid_c:
							ps.banished.erase(b)
							ps.hand.append(b)
							events.append({"type": "gy_to_hand", "player": p, "card": b})
							break
		"defusion":
			# De-Fusion: "return that target to the Extra Deck, then, if all its listed materials that were used
			# for its Fusion Summon are in your GY, you can Special Summon all of them."
			for t in _sel(s, p, c, "target", ctx):
				var used: Array = t.tags.get("mats", []).duplicate()
				events.append_array(s._bounce(t))
				var back: Array = ps.gy.filter(func(g): return used.has(g.uid) and s.can_revive(g))
				var room := 0
				for i in ps.field.size():
					if ps.field[i] == null and not ps.blocked.has(i):
						room += 1
				if not used.is_empty() and back.size() == used.size() and room >= back.size() and ps.no_summon_turn != s.turn \
						and s.choose_option(p, Loc.t("%s: Special Summon its Fusion Materials?") % c.cname(), ["Special Summon them", "No"], 0, c) == 0:
					for g in back:
						ps.gy.erase(g)
						events.append_array(s._special(p, g, "reborn"))
		"level_up_spell":
			# Level Up!: "Send 1 face-up "LV" monster you control to the GY; Special Summon 1 "LV" monster that
			# is mentioned in the sent monster's text from your hand or Deck, ignoring its Summoning conditions."
			var ready: Array = _lv_ready(s, p)
			if ready.is_empty():
				return events
			var best_lv = ready[0]
			for m in ready:
				if m.level() > best_lv.level():
					best_lv = m
			var from_lv = s.pick1(p, Loc.t("%s: send which monster to the Graveyard?") % c.cname(), ready, best_lv, c)
			var next_nm := _lv_next(from_lv.cname())
			ps.field[ps.field.find(from_lv)] = null
			s._to_gy(ps, from_lv)
			events.append({"type": "tribute", "player": p, "card": from_lv})
			events.append_array(s._monster_left(from_lv))
			for src in [ps.hand, ps.deck]:
				var got_lv: Array = src.filter(func(x): return x.cname() == next_nm)
				if not got_lv.is_empty():
					src.erase(got_lv[0])
					got_lv[0].proper = true
					events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s levels up!") % from_lv.cname()})
					events.append_array(s._special(p, got_lv[0], "effect"))
					break
			s._shuffle(ps.deck)
		"destroy_opp_all":
			# Ojama Delta Hurricane!!: "Destroy all cards your opponent controls."
			var them := s.players[s.opponent(p)]
			for m in them.monsters():
				events.append_array(s._destroy(m))
			for st in them.spells.duplicate():
				if st != null:
					events.append_array(s._destroy_st(st))
			if them.field_spell != null:
				events.append_array(s._destroy_st(them.field_spell))
		"ojamagic":
			# Ojamagic: "Add 1 each of "Ojama Green", "Ojama Yellow", and "Ojama Black" from your Deck to your hand."
			for nm in ["Ojama Green", "Ojama Yellow", "Ojama Black"]:
				var got_o: Array = ps.deck.filter(func(x): return x.cname() == nm)
				if not got_o.is_empty():
					ps.deck.erase(got_o[0])
					ps.hand.append(got_o[0])
					events.append({"type": "search", "player": p, "card": got_o[0], "deck": ps.deck.size()})
			s._shuffle(ps.deck)
		"ojamuscle":
			# Ojamuscle: "Select 1 face-up "Ojama King". Destroy all "Ojama" monsters on the field, except the
			# selected "Ojama King". It gains 1000 ATK for each monster destroyed this way."
			var kings: Array = (ps.monsters() + s.players[s.opponent(p)].monsters()).filter(func(m): return m.face_up and m.cname() == "Ojama King")
			if kings.is_empty():
				return events
			var king = s.pick1(p, Loc.t("%s: which Ojama King?") % c.cname(), kings, kings[0], c)
			var gone_o := 0
			for q in [p, s.opponent(p)]:
				for m in s.players[q].monsters():
					if m != king and m.face_up and m.cname().contains("Ojama"):
						var before_o: bool = s.players[q].field.has(m)
						events.append_array(s._destroy(m))
						if before_o and not s.players[q].field.has(m):
							gone_o += 1
			king.atk_mod += 1000 * gone_o
			events.append({"type": "effect", "player": p, "card": king, "text": Loc.t("%s gains %d ATK") % [king.cname(), 1000 * gone_o]})
		"dna":
			# DNA Surgery: "Activate this card by declaring 1 Monster Type."
			var kinds: Array = TYPES.duplicate()
			var first_k := "Insect"
			var has_barrier: bool = not (ps.deck + ps.hand + ps.spells).filter(func(x): return x != null and x.cname() == "Insect Barrier").is_empty()
			if not has_barrier:
				var top_m = null
				for m in ps.monsters():
					if m.face_up and (top_m == null or m.atk() > top_m.atk()):
						top_m = m
				if top_m != null and kinds.has(str(top_m.data.get("race", ""))):
					first_k = str(top_m.data.get("race", ""))
			kinds.erase(first_k)
			kinds.push_front(first_k)
			var said := ""
			var from_k := 0
			while said == "":
				var page: Array = kinds.slice(from_k, from_k + 7)
				var labels_k: Array = page.map(func(x): return Loc.t(str(x)))
				if from_k + 7 < kinds.size():
					labels_k.append(Loc.t("More Types"))
				var got_k: int = s.choose_option(p, Loc.t("%s: declare 1 Monster Type") % c.cname(), labels_k, 0, c)
				if got_k < page.size():
					said = str(page[got_k])
				else:
					from_k += 7
			c.tags["declared"] = said
			events.append({"type": "effect", "player": p, "card": c, "text": Loc.t("%s: every face-up monster is now %s") % [c.cname(), Loc.t(said)]})
			s._apply_races()
		"destroy_race":
			# Eradicating Aerosol: "Destroy all Insect monsters on the field."
			for q in [p, s.opponent(p)]:
				for m in s.players[q].monsters():
					if m.face_up and str(m.data.get("race", "")) == str(a[1]):
						events.append_array(s._destroy(m))
		"tokens":
			# ["tokens", n, name, id, atk, def, level, attribute, race]: n Tokens in Defense Position.
			CardData.TOKENS[int(a[3])] = {"name": str(a[2]), "frame": "token", "atk": int(a[4]), "def": int(a[5]), "level": int(a[6]),
					"attribute": str(a[7]), "race": str(a[8]), "no_tribute_summon": true,
					"desc": Loc.t("This card can be used as a \"%s\". It cannot be Tributed for a Tribute Summon.") % str(a[2])}
			if not (a.size() > 9 and str(a[9]) == "free"):
				ps.no_summon_turn = s.turn   # (Scapegoat: no other Summons that turn. Multiply has no such rule.)
			for i in int(a[1]):
				if ps.free_zone() == -1:
					break
				events.append_array(s._special(p, s._make(int(a[3]), p), "effect", "def"))
			s.last_summoned = null
		"negate_fx":
			for t in _sel(s, p, c, str(a[1]), ctx):
				t.negated_turn = s.turn
				t.negated = true
				events.append(_ev(p, t, Loc.t("%s's effects are negated this turn") % t.cname()))
	return events


## Fusions that can be made by banishing materials from the field and Graveyard.
static func _gy_fusions(s: DuelState, p: int, filter: Dictionary) -> Array:
	var out := []
	for o in s.fusion_targets(p, null, true):
		if CardEffects.matches(o["card"].data, filter):
			out.append(o)
	out.sort_custom(func(a, b): return a["card"].atk() > b["card"].atk())
	return out


# ------------------------------------------------------------------ Ritual Summons

## {"monster", "tributes"} for the best Ritual Monster this spell can bring out, or {}.
static func ritual_plan(s: DuelState, p: int, c) -> Dictionary:
	var ps := s.players[p]
	if ps.free_zone() == -1 and ps.monsters().is_empty():
		return {}
	var best := {}
	for h in ps.hand:
		if not h.is_monster() or h.frame() != "ritual":
			continue
		var text: String = str(h.data.get("desc", h.data.get("text", "")))
		if not text.contains(c.cname()) and not str(c.data.get("desc", c.data.get("text", ""))).contains(h.cname()):
			continue
		var pool: Array = []
		for x in ps.hand:
			if x != h and x.is_monster() and x.frame() != "ritual":
				pool.append(x)
		pool.append_array(ps.monsters())
		pool.sort_custom(func(a, b): return s._card_value(a) < s._card_value(b))
		var picks := []
		var total := 0
		for x in pool:
			if total >= h.level():
				break
			picks.append(x)
			total += maxi(1, x.level())
		if total >= h.level() and (best.is_empty() or h.atk() > best["monster"].atk()):
			best = {"monster": h, "tributes": picks}
	return best


## Everything that could be Tributed for this Ritual Monster, cheapest first.
static func _ritual_pool(s: DuelState, p: int, h) -> Array:
	var ps := s.players[p]
	var pool: Array = []
	for x in ps.hand:
		if x != h and x.is_monster() and x.frame() != "ritual":
			pool.append(x)
	pool.append_array(ps.monsters())
	pool.sort_custom(func(a, b): return s._card_value(a) < s._card_value(b))
	return pool


static func _do_ritual(s: DuelState, p: int, c) -> Array:
	var plan := ritual_plan(s, p, c)
	var events := []
	if plan.is_empty():
		return events
	var ps := s.players[p]
	# Which Ritual Monster, then which Tributes (their Levels must reach its Level): the player's call.
	var able: Array = []
	for h in ps.hand:
		if h.is_monster() and h.frame() == "ritual":
			var text: String = str(h.data.get("desc", h.data.get("text", "")))
			if not text.contains(c.cname()) and not str(c.data.get("desc", c.data.get("text", ""))).contains(h.cname()):
				continue
			var sum := 0
			for x in _ritual_pool(s, p, h):
				sum += maxi(1, x.level())
			if sum >= h.level():
				able.append(h)
	var m = s.pick1(p, Loc.t("%s: Ritual Summon which monster?") % c.cname(), able, plan["monster"], c)
	var pool := _ritual_pool(s, p, m)
	var tributes: Array = []
	var total := 0
	while total < m.level() and not pool.is_empty():
		var t = s.pick1(p, Loc.t("%s: Tribute (Levels %d of %d)") % [m.cname(), total, m.level()], pool, pool[0], c)
		pool.erase(t)
		tributes.append(t)
		total += maxi(1, t.level())
	for t in tributes:
		if ps.hand.has(t):
			ps.hand.erase(t)
			s._to_gy(ps, t)
			events.append({"type": "discard", "player": p, "card": t})
			# A Ritual Tribute from the hand is a Tribute too ("If this card is Tributed").
			events.append_array(EffectRunner.trigger(s, t, "tributed"))
		else:
			ps.field[ps.field.find(t)] = null
			s._to_gy(ps, t)
			events.append({"type": "tribute", "player": p, "card": t})
			events.append_array(EffectRunner.trigger(s, t, "tributed"))
	ps.hand.erase(m)
	m.proper = true
	events.append_array(s._special(p, m, "ritual"))
	events.append_array(EffectRunner.on_summon(s, p, m, "special"))
	events.append_array(EffectRunner.trigger(s, m, "ritual_summoned"))
	return events


# ------------------------------------------------------------------ cards that stay on the field

## Face-up Spell/Trap cards on a side (including the Field Spell).
static func _up(s: DuelState, q: int) -> Array:
	var out := []
	for st in s.players[q].spells:
		if st != null and st.face_up:
			out.append(st)
	var f = s.players[q].field_spell
	if f != null:
		out.append(f)
	return out


static func atk_bonus(s: DuelState, c, attacking: bool, vs) -> int:
	var b := 0
	for q in 2:
		for st in _up(s, q):
			var sp := spec(st)
			if sp.is_empty():
				continue
			for boost in sp.get("boost", []):
				if CardEffects.matches(c.data, boost[0]):
					b += int(boost[1])
			for boost in sp.get("all_boost", []):
				if c.face_up and CardEffects.matches(c.data, boost[0]):
					b += int(boost[1])
			if sp.get("neo_space", false) and c.face_up and neos_family(c):
				b += 500   # Neo Space: "Elemental HERO Neos" and every Fusion Monster that lists it gain 500 ATK
			if st.equipped_to == c:
				b += int(sp.get("atk", 0))
				if sp.has("atk_per"):
					b += _per(s, q, str(sp["atk_per"][0])) * int(sp["atk_per"][1])
				if sp.get("megamorph", false):
					var mine := s.players[q].lp
					var theirs := s.players[s.opponent(q)].lp
					if mine < theirs:
						b += c.atk()
					elif mine > theirs:
						b -= c.atk() / 2
			if q == c.owner:
				if sp.has("bp_boost") and s.current == q and s.phase == DuelState.Phase.BATTLE:
					b += int(sp["bp_boost"])
				if sp.has("atk_all") and CardEffects.matches(c.data, sp["atk_all"][0]):
					if sp["atk_all"][2] != "own_same_race_gy" or _one_race_gy(s, q, str(c.data.get("race", ""))):
						b += int(sp["atk_all"][1])
				if attacking and vs != null and sp.has("skyscraper") and str(c.data.get("name", "")).contains("Elemental HERO") and s.atk_of(c, false) < vs.atk():
					b += int(sp["skyscraper"])
	return b


static func def_bonus(s: DuelState, c) -> int:
	var b := 0
	for q in 2:
		for st in _up(s, q):
			var sp := spec(st)
			for boost in sp.get("boost", []):
				if CardEffects.matches(c.data, boost[0]):
					b += int(boost[2])
			if st.equipped_to == c:
				b += int(sp.get("def", 0))
				if sp.has("def_per"):
					b += _per(s, q, str(sp["def_per"][0])) * int(sp["def_per"][1])
			if sp.has("def_pos_boost") and not c.attack_pos:
				b += int(sp["def_pos_boost"])
	return b


static func _per(s: DuelState, q: int, what: String) -> int:
	var n := 0
	if what == "own_face_mons":
		for m in s.players[q].monsters():
			if m.face_up:
				n += 1
	elif what == "own_st":
		for st in s.players[q].spells:
			if st != null:
				n += 1
	elif what == "opp_mons":
		n = s.players[s.opponent(q)].monsters().size()
	return n


static func _one_race_gy(s: DuelState, q: int, race: String) -> bool:
	var any := false
	for g in s.players[q].gy:
		if g.is_monster():
			if str(g.data.get("race", "")) != race:
				return false
			any = true
	return any


## The face-up Equip Spells on a monster (not Union monsters: DuelState.unions_on has those).
static func equips_on(s: DuelState, m) -> Array:
	var out := []
	for q in 2:
		for st in s.players[q].spells:
			if st != null and st.face_up and st.equipped_to == m and not st.is_monster():
				out.append(st)
	return out


## The Synchro Monsters in player p's Extra Deck that could be Synchro Summoned right now.
static func _synchro_options(s: DuelState, p: int) -> Array:
	var out := []
	if s.players[p].no_summon_turn == s.turn:
		return out
	for x in s.players[p].extra:
		if x.frame() == "synchro" and not s.extra_materials(p, x).is_empty():
			out.append(x)
	return out


## Equip-style flags on a monster ("pierce", "no_attack", "no_battle_death").
static func equip_flag(s: DuelState, c, flag: String) -> bool:
	for q in 2:
		for st in s.players[q].spells:
			if st != null and st.face_up and st.equipped_to == c and spec(st).get(flag, false):
				return true
	return false


## Can this monster declare an attack, as far as Spell/Trap cards are concerned?
## Player p's face-up monsters that are "Cyber Dragon" (Proto-Cyber Dragon counts on the field).
static func _cyber_dragons(s: DuelState, p: int) -> Array:
	return s.players[p].monsters().filter(func(m): return m.face_up and s.can_tribute_fx(m) and (m.cname() == "Cyber Dragon" or str(CardEffects.of(m.cname()).get("name_as", "")) == "Cyber Dragon"))


## Where Photon Generator Unit / Attack Reflector Unit can take their monster from.
static func _unit_pool(s: DuelState, p: int, card_name: String, with_gy: bool) -> Array:
	var ps := s.players[p]
	var out: Array = (ps.hand + ps.deck).filter(func(x): return x.cname() == card_name)
	if with_gy:
		out.append_array(ps.gy.filter(func(x): return x.cname() == card_name))
	return out


## The "LV" monster named in this one's own text as its next step (Armed Dragon LV3 -> LV5), or "".
static func _lv_next(card_name: String) -> String:
	var f: Dictionary = CardEffects.of(card_name)
	for k in f:
		if f[k] is Array:
			for a in f[k]:
				if a is Array and not a.is_empty() and str(a[0]).begins_with("level_up") and a.size() > 1:
					return str(a[1])
	return ""


## Player p's face-up "LV" monsters whose next step is waiting in the hand or Deck.
static func _lv_ready(s: DuelState, p: int) -> Array:
	var ps := s.players[p]
	return ps.monsters().filter(func(m): return m.face_up and m.cname().contains(" LV") and _lv_next(m.cname()) != "" \
			and not (ps.hand + ps.deck).filter(func(x): return x.cname() == _lv_next(m.cname())).is_empty())


const TYPES := ["Aqua", "Beast", "Beast-Warrior", "Cyberse", "Dinosaur", "Divine-Beast", "Dragon", "Fairy", "Fiend", "Fish", "Illusion", "Insect", "Machine",
		"Plant", "Psychic", "Pyro", "Reptile", "Rock", "Sea Serpent", "Spellcaster", "Thunder", "Warrior", "Winged Beast", "Wyrm", "Zombie"]


static func can_attack(s: DuelState, p: int, c) -> bool:
	if c.summoned_turn == s.turn and field_flag(s, "summon_sick_all"):
		return false   # Vengeful Bog Spirit: "Monsters cannot attack the turn they are Summoned."
	if s.players[p].no_attack_turn >= s.turn:
		return false
	if equip_flag(s, c, "no_attack"):
		return false
	for q in 2:
		for st in _up(s, q):
			var sp := spec(st)
			if sp.has("lock_atk_min") and s.atk_of(c, false) >= int(sp["lock_atk_min"]):
				return false
			if sp.has("opp_race_no_attack") and q != p and c.face_up and str(c.data.get("race", "")) == str(sp["opp_race_no_attack"]):
				return false   # Insect Barrier: "Insect-Type monsters your opponent controls cannot declare an attack."
			if sp.has("lock_lv_min") and c.frame() != "xyz" and c.level() >= int(sp["lock_lv_min"]):
				return false
			if sp.get("one_attack", false) and s.players[p].attacks_this_turn >= 1 and s.players[p].attacks_turn == s.turn:
				return false
			if sp.has("attack_toll") and s.players[p].lp <= int(sp["attack_toll"]):
				return false
	return true


## Should a card headed for the Graveyard be banished instead?
static func redirect(s: DuelState, c) -> bool:
	for q in 2:
		for st in _up(s, q):
			var r: String = str(spec(st).get("redirect", ""))
			if r == "all" or (r == "mon" and c != null and c.is_monster()):
				return true
	return false


## Standby Phase upkeep and effects of the turn player's (and sometimes both players') cards.
static func standby(s: DuelState, p: int) -> Array:
	var events := []
	for q in 2:
		for st in _up(s, q):
			var sp := spec(st)
			if sp.is_empty() or s.is_over():
				continue
			if q == p:
				if sp.has("upkeep"):
					var n := int(sp["upkeep"])
					# "Pay 2000 LP or destroy this card": yours to decide (Mirror Wall).
					if sp.get("upkeep_ask", false) and s.players[p].lp > n and s.choose_option(p, Loc.t("%s: pay %d Life Points to keep it?") % [st.cname(), n], ["Pay", "Destroy it"], 0 if s.players[p].lp > n + 3000 else 1, st) == 1:
						events.append_array(s._destroy_st(st))
						continue
					if s.players[p].lp > n:
						s.players[p].lp -= n
						events.append({"type": "lp", "player": p, "lp": s.players[p].lp, "delta": -n})
					else:
						events.append_array(s._destroy_st(st))
						continue
				if sp.get("counter_standby", false):
					st.counter += 1
					events.append(_ev(p, st, Loc.t("%s charges (%d)") % [st.cname(), st.counter]))
				for a in sp.get("standby", []):
					events.append_array(_run(s, p, st, a, {}))
			else:
				for a in sp.get("standby_opp", []):
					events.append_array(_run(s, p, st, a, {}))
			for a in sp.get("each_standby", []):
				events.append_array(_run(s, p, st, a, {}))
	return events


## A Spell/Trap card left the field: run "on_leave", free what it was holding.
static func left_field(s: DuelState, c) -> Array:
	var events := []
	var sp := spec(c)
	var p: int = c.owner
	if c.linked != null and s.players[c.linked.owner].field.has(c.linked):
		var m = c.linked
		c.linked = null
		events.append_array(s._destroy(m))
	if sp.get("control", false) and c.equipped_to != null:
		events.append_array(s._return_control(c.equipped_to))
	for a in sp.get("on_leave", []):
		events.append_array(_run(s, p, c, a, {}))
	# Big Bang Shot: when it leaves the field, the equipped monster is banished.
	if sp.get("banish_on_leave", false) and c.equipped_to != null and (s.players[0].field.has(c.equipped_to) or s.players[1].field.has(c.equipped_to)):
		var gone = c.equipped_to
		c.equipped_to = null
		events.append_array(s._banish(gone))
	c.left_turn = s.turn
	c.equipped_to = null
	c.linked = null
	c.counter = 0
	return events


## The monsters in a Deck whose name has one of these words, within a Level range, that can be Special Summoned.
static func _deck_family(s: DuelState, p: int, words: Array, lo: int, hi: int) -> Array:
	return s.players[p].deck.filter(func(x):
		if not x.is_monster() or CardData.is_extra(x.id) or x.level() < lo or x.level() > hi or CardEffects.of(x.cname()).get("no_special", false):
			return false
		if "cannot be normal summoned" in str(x.data.get("desc", "")).to_lower() and "must" in str(x.data.get("desc", "")).to_lower():
			return false
		for w in words:
			if x.cname().contains(str(w)):
				return true
		return false)


## Onomatopaira: the Zubaba, Gagaga, Gogogo and Dododo monsters in your Deck.
static func _onoma_pool(s: DuelState, p: int) -> Array:
	return s.players[p].deck.filter(func(x): return x.is_monster() and not CardData.is_extra(x.id) and (x.cname().contains("Gagaga") or x.cname().contains("Gogogo") or x.cname().contains("Dododo") or x.cname().contains("Zubaba")))


## Rank-Up: [base on your field, monster in your Extra Deck] pairs, one Rank apart.
static func _rank_up_options(s: DuelState, p: int, rank: int, family: String, same_race := false) -> Array:
	var out := []
	for m in s.players[p].monsters():
		if not m.face_up or m.frame() != "xyz" or (rank > 0 and m.level() != rank):
			continue
		for x in s.players[p].extra:
			var fam_ok := false
			for w in family.split("|"):
				if x.cname().contains(w):
					fam_ok = true
			if x.frame() == "xyz" and x.level() == m.level() + 1 and fam_ok and (not same_race or str(x.data.get("race", "")) == str(m.data.get("race", ""))):
				out.append([m, x])
	return out


## "Elemental HERO Neos" itself, or a Fusion Monster that lists it as a material.
static func neos_family(m) -> bool:
	var n := str(m.data.get("name", ""))
	if n == "Elemental HERO Neos":
		return true
	return m.frame() == "fusion" and str(m.data.get("desc", "")).contains("\"Elemental HERO Neos\"")


static func _ehero_count(s: DuelState, p: int) -> int:
	var n := 0
	for m in s.players[p].monsters():
		if m.face_up and str(m.data.get("name", "")).contains("Elemental HERO"):
			n += 1
	return n


## R - Righteous Justice: every Spell/Trap on the field but itself.
static func _justice_pool(s: DuelState, c) -> Array:
	var out := []
	for q in 2:
		for st in s.players[q].spells:
			if st != null and st != c:
				out.append(st)
		if s.players[q].field_spell != null and s.players[q].field_spell != c:
			out.append(s.players[q].field_spell)
	return out


## Hero Signal: a Set Trap that answers "a monster you control is destroyed by battle and sent to the GY".
static func after_battle_death(s: DuelState, loser) -> Array:
	var p: int = loser.owner
	var events := []
	if s.is_over() or not s.chain.is_empty():
		return events
	for st in s.players[p].spells.duplicate():
		if st == null or st.face_up or st.set_turn >= s.turn or not spec(st).get("battle_death", false) or blocked(s, st):
			continue
		if not feasible(s, p, st, "free", null):
			continue
		if s.choose_option(p, Loc.t("%s was destroyed by battle. Activate %s?") % [loser.cname(), st.cname()], ["Activate it", "No"], 0, st) != 0:
			continue
		events.append_array(s.chain_add(p, st, null, "free"))
		events.append_array(s.chain_resolve())
		break
	return events


## Instant Neo Space: "If the equipped monster leaves the field: You can Special Summon 1 "Elemental HERO Neos"".
static func host_gone(s: DuelState, st) -> Array:
	var events := []
	var sp := spec(st)
	if st == null or not st.face_up or not sp.has("host_gone") or blocked(s, st):
		return events
	if s.choose_option(st.owner, Loc.t("%s: use its effect?") % st.cname(), ["Yes", "No"], 0, st) != 0:
		return events
	for a in sp["host_gone"]:
		events.append_array(_run(s, st.owner, st, a, {}))
	return events


## Wave-Motion Cannon and friends: a face-up card you can fire from the field.
static func can_fire(s: DuelState, p: int, c) -> bool:
	var sp := spec(c)
	return (sp.has("cannon") and p == s.current and s._in_main() and s.players[p].spells.has(c)
			and c.face_up and c.counter > 0)


static func fire(s: DuelState, p: int, c) -> Array:
	if not can_fire(s, p, c):
		return []
	var n: int = c.counter * int(spec(c)["cannon"])
	var events := [_ev(p, c, Loc.t("%s fires for %d!") % [c.cname(), n])]
	events.append_array(s._destroy_st(c))
	events.append_array(s._damage(s.opponent(p), n))
	return events


## One-line "in this game" note for the card inspector.
static func note(c) -> String:
	var sp := spec(c)
	if sp.is_empty():
		return "This card's effect isn't in the game yet. You can still Set it as a bluff."
	var names := {"quick": "Quick-Play Spell: can be chained on your turn, or Set and used on either turn",
			"cont": "Continuous Spell: stays on the field", "field": "Field Spell: stays in the Field Zone",
			"equip": "Equip Spell: attaches to a monster", "ritual": "Ritual Spell: tribute monsters whose Levels add up",
			"ctrap": "Continuous Trap: stays on the field",
			"counter": "Counter Trap: negates a card in a chain"}
	return str(names.get(sp.get("k", ""), ""))
