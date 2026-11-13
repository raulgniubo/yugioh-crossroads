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
	# ---------------------------------------------------------------- Normal Spells
	"Heavy Storm": {"k": "normal", "do": [["destroy", "all_st"]]},
	"Harpie's Feather Duster": {"k": "normal", "do": [["destroy", "opp_st"]]},
	"Giant Trunade": {"k": "normal", "do": [["bounce", "all_st"]]},
	"Change of Heart": {"k": "normal", "t": "opp_mon", "do": [["control", "target", "eot"]]},
	"Brain Control": {"k": "normal", "t": "opp_face", "cost": "lp800", "do": [["control", "target", "eot"]]},
	"Mind Control": {"k": "normal", "t": "opp_mon", "do": [["control", "target", "eot"], ["no_attack", "target"]]},
	"Graceful Charity": {"k": "normal", "do": [["draw", 3], ["discard", 2]]},
	"Card Destruction": {"k": "normal", "do": [["card_destruction"]]},
	"Upstart Goblin": {"k": "normal", "do": [["draw", 1], ["opp_heal", 1000]]},
	"Jar of Greed": {"k": "trap", "win": ["free"], "do": [["draw", 1]]},
	"Pot of Avarice": {"k": "normal", "do": [["avarice"]]},
	"Tribute to the Doomed": {"k": "normal", "t": "any_mon", "cost": "discard", "do": [["destroy", "target"]]},
	"Lightning Vortex": {"k": "normal", "cost": "discard", "do": [["destroy", "opp_face_mons"]]},
	"Smashing Ground": {"k": "normal", "do": [["destroy", "opp_best_def"]]},
	"Hammer Shot": {"k": "normal", "do": [["destroy", "best_atk_any"]]},
	"Nobleman of Crossout": {"k": "normal", "t": "any_fdown", "do": [["banish", "target"]]},
	"Nobleman of Extermination": {"k": "normal", "t": "any_set_st", "do": [["banish", "target"]]},
	"De-Spell": {"k": "normal", "t": "any_spell", "do": [["destroy", "target"]]},
	"Remove Trap": {"k": "normal", "t": "any_face_trap", "do": [["destroy", "target"]]},
	"Stop Defense": {"k": "normal", "t": "opp_def", "do": [["to_atk", "target"]]},
	"Shield Crush": {"k": "normal", "t": "opp_def", "do": [["destroy", "target"]]},
	"Ookazi": {"k": "normal", "do": [["damage", 800]]},
	"Tremendous Fire": {"k": "normal", "do": [["damage", 1000], ["self_damage", 500]]},
	"Sparks": {"k": "normal", "do": [["damage", 200]]},
	"Final Flame": {"k": "normal", "do": [["damage", 600]]},
	"Meteor of Destruction": {"k": "normal", "do": [["damage", 1000]]},
	"Poison of the Old Man": {"k": "quick", "do": [["heal", 1200]]},
	"Goblin's Secret Remedy": {"k": "normal", "do": [["heal", 600]]},
	"Red Medicine": {"k": "normal", "do": [["heal", 500]]},
	"Blue Medicine": {"k": "normal", "do": [["heal", 400]]},
	"Soul of the Pure": {"k": "normal", "do": [["heal", 800]]},
	"Foolish Burial": {"k": "normal", "do": [["bury"]]},
	"Reinforcement of the Army": {"k": "normal", "do": [["search", {"race": "Warrior", "max_lv": 4}]]},
	"Sangan's Call": {"k": "normal", "do": [["search", {"max_atk": 1500}]]},
	"E - Emergency Call": {"k": "normal", "do": [["search", {"has": "Elemental HERO"}]]},
	"The Warrior Returning Alive": {"k": "normal", "do": [["gy_to_hand", {"race": "Warrior"}, 1]]},
	"Monster Reincarnation": {"k": "normal", "cost": "discard", "do": [["gy_to_hand", {"monster": true}, 1]]},
	"Dark Factory of Mass Production": {"k": "normal", "do": [["gy_to_hand", {"frame": "normal"}, 2]]},
	"Share the Pain": {"k": "normal", "cost": "tribute", "do": [["destroy", "opp_weakest"]]},
	"Soul Exchange": {"k": "normal", "t": "opp_mon", "do": [["tribute_fodder", "target"]]},
	"Premature Burial": {"k": "equip", "cost": "lp800", "do": [["revive", "own_gy", "atk", "link"]]},
	"Miracle Fusion": {"k": "normal", "do": [["miracle_fusion", {"has": "Elemental HERO"}]]},
	"Card of Sanctity": {"k": "normal", "do": [["draw_to", 6]]},
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
	"Enemy Controller": {"k": "quick", "t": "opp_face", "do": [["change_pos", "target"]]},
	"Ego Boost": {"k": "quick", "t": "own_face", "do": [["atk", "target", 1000, "eot"]]},
	"Forbidden Lance": {"k": "quick", "t": "any_face", "do": [["atk", "target", -800, "eot"]]},
	"Offerings to the Doomed": {"k": "quick", "t": "any_face", "do": [["destroy", "target"], ["skip_draw", 1]]},
	"The Reliable Guardian": {"k": "quick", "t": "any_face", "do": [["def", "target", 700]]},
	"De-Fusion": {"k": "quick", "t": "any_fusion", "do": [["bounce", "target"]]},
	# ---------------------------------------------------------------- Continuous Spells
	"Banner of Courage": {"k": "cont", "bp_boost": 200},
	"Burning Land": {"k": "cont", "do": [["destroy", "fields"]], "each_standby": [["self_damage", 500]]},
	"Messenger of Peace": {"k": "cont", "lock_atk_min": 1500, "upkeep": 100},
	"Level Limit - Area B": {"k": "cont", "lock_lv_min": 4, "do": [["to_def", "lv4_all"]]},
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
	"Necrovalley": {"k": "field", "boost": [[{"has": "Gravekeeper"}, 500, 500]]},
	"Chorus of Sanctuary": {"k": "field", "def_pos_boost": 500},
	# ---------------------------------------------------------------- Equip Spells
	"Axe of Despair": {"k": "equip", "atk": 1000},
	"Malevolent Nuzzler": {"k": "equip", "atk": 700},
	"Horn of the Unicorn": {"k": "equip", "atk": 700, "def": 700},
	"Black Pendant": {"k": "equip", "atk": 500, "on_leave": [["damage", 500]]},
	"United We Stand": {"k": "equip", "atk_per": ["own_face_mons", 800], "def_per": ["own_face_mons", 800]},
	"Mage Power": {"k": "equip", "atk_per": ["own_st", 500], "def_per": ["own_st", 500]},
	"Megamorph": {"k": "equip", "megamorph": true},
	"Fairy Meteor Crush": {"k": "equip", "pierce": true},
	"Big Bang Shot": {"k": "equip", "atk": 400, "pierce": true},
	"Lightning Blade": {"k": "equip", "must": {"race": "Warrior"}, "atk": 800},
	"Sword of Deep-Seated": {"k": "equip", "atk": 500, "def": 500},
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
	"Power of Kaishin": {"k": "equip", "must": {"race": "Aqua"}, "atk": 300, "def": 300},
	"Steel Shell": {"k": "equip", "must": {"attr": "WATER"}, "atk": 400, "def": -200},
	"Gust Fan": {"k": "equip", "must": {"attr": "WIND"}, "atk": 400, "def": -200},
	"Salamandra": {"k": "equip", "must": {"attr": "FIRE"}, "atk": 700},
	"Elf's Light": {"k": "equip", "must": {"attr": "LIGHT"}, "atk": 400, "def": -200},
	"Sword of Dark Destruction": {"k": "equip", "must": {"attr": "DARK"}, "atk": 400, "def": -200},
	"Snatch Steal": {"k": "equip", "t": "opp_face", "control": true, "standby": [["opp_heal", 1000]]},
	"Cyclon Laser": {"k": "equip", "atk": 300, "pierce": true},
	"Spark Blaster": {"k": "equip", "atk": 300},
	"Assault Armor": {"k": "equip", "must": {"race": "Warrior"}, "atk": 300},
	"Junk Barrage": {"k": "equip", "atk": 300},
	"Mist Body": {"k": "equip", "no_battle_death": true},
	"Heart of Clear Water": {"k": "equip", "no_battle_death": true},
	"Ring of Magnetism": {"k": "equip", "atk": -500, "def": -500},
	# ---------------------------------------------------------------- Normal Traps
	"Ring of Destruction": {"k": "trap", "win": ["free"], "t": "any_face", "do": [["ring"]]},
	"Dust Tornado": {"k": "trap", "win": ["free"], "t": "opp_st", "do": [["destroy", "target"]]},
	"Compulsory Evacuation Device": {"k": "trap", "win": ["free"], "t": "any_mon", "do": [["bounce", "target"]]},
	"Raigeki Break": {"k": "trap", "win": ["free"], "t": "any_card", "cost": "discard", "do": [["destroy", "target"]]},
	"Threatening Roar": {"k": "trap", "win": ["free"], "do": [["no_attacks"]]},
	"Draining Shield": {"k": "trap", "win": ["attack"], "do": [["negate_attack"], ["heal_attacker_atk"]]},
	"Just Desserts": {"k": "trap", "win": ["free"], "do": [["damage_per", "opp_mons", 500]]},
	"Ceasefire": {"k": "trap", "win": ["free"], "do": [["flip_up", "all_fdown"], ["damage_per", "all_effect_mons", 500]]},
	"Reckless Greed": {"k": "trap", "win": ["free"], "do": [["draw", 2], ["skip_draw", 2]]},
	"Widespread Ruin": {"k": "trap", "win": ["attack"], "do": [["destroy", "opp_best_atk_pos"]]},
	"Enchanted Javelin": {"k": "trap", "win": ["attack"], "do": [["heal_attacker_atk"]]},
	"Shadow Spell": {"k": "ctrap", "win": ["free"], "t": "opp_face", "equip": true, "atk": -700, "no_attack": true},
	"Spellbinding Circle": {"k": "ctrap", "win": ["free"], "t": "opp_face", "equip": true, "no_attack": true},
	"Nightmare Wheel": {"k": "ctrap", "win": ["free"], "t": "opp_face", "equip": true, "no_attack": true, "standby": [["damage", 500]]},
	"Call of the Haunted": {"k": "ctrap", "win": ["free"], "do": [["revive", "own_gy", "atk", "link"]]},
	"Gravity Bind": {"k": "ctrap", "win": ["free"], "lock_lv_min": 4},
	"Royal Decree": {"k": "ctrap", "win": ["free"], "block": "trap"},
	"Imperial Order": {"k": "ctrap", "win": ["free"], "block": "spell", "upkeep": 700},
	"Macro Cosmos": {"k": "ctrap", "win": ["free"], "redirect": "all"},
	"Windstorm of Etaqua": {"k": "trap", "win": ["free"], "do": [["change_pos", "opp_face_mons"]]},
	"Zero Gravity": {"k": "trap", "win": ["free"], "do": [["change_pos", "all_face_mons"]]},
	"Dimensional Prison": {"k": "trap", "win": ["attack"], "do": [["negate_attack"], ["banish", "attacker"]]},
	"Sakuretsu Armor": {"k": "trap", "win": ["attack"], "do": [["destroy", "attacker"]]},
	"Mirror Force": {"k": "trap", "win": ["attack"], "do": [["destroy", "opp_atk_mons"]]},
	"Magic Cylinder": {"k": "trap", "win": ["attack"], "do": [["negate_attack"], ["damage_attacker_atk"]]},
	"Negate Attack": {"k": "counter", "win": ["attack"], "neg": [], "do": [["end_battle"]]},
	"Waboku": {"k": "trap", "win": ["free"], "do": [["no_battle_damage"], ["protect"]]},
	"Hallowed Life Barrier": {"k": "trap", "win": ["free"], "cost": "discard", "do": [["no_battle_damage"]]},
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
	"Trap Jammer": {"k": "counter", "neg": ["trap"]},
	"Cursed Seal of the Forbidden Spell": {"k": "counter", "neg": ["spell"], "cost": "discard"},
}

const LEGACY_WIN := {"mirror_force": "attack", "magic_cylinder": "attack", "sakuretsu": "attack", "negate_attack": "attack",
		"waboku": "attack", "dim_prison": "attack", "trap_hole": "summon", "bottomless": "summon", "torrential": "summon"}
static var _derived := {}


static func spec(c) -> Dictionary:
	var name: String = c.cname()
	if FX.has(name):
		return FX[name]
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
	for q in 2:
		for st in s.players[q].spells:
			if st == null or not st.face_up or st == c:
				continue
			var b: String = str(spec(st).get("block", ""))
			if (b == "trap" and c.is_trap()) or (b == "spell" and c.is_spell()):
				return true
	return false


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
	# Spell Speed: only a Counter Trap can answer a Counter Trap.
	if window == "chain" and subject is Dictionary and str(subject.get("spec", {}).get("k", "")) == "counter" and k != "counter":
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
	if wins.has("attack") and not wins.has("free"):
		if s.pending_attack.is_empty() or s.pending_attack["player"] == p or window != "attack":
			return false
	if wins.has("summon") and not wins.has("free"):
		if subject == null or subject is Dictionary or subject.owner == p or window != "summon":
			return false
		if subject.atk() < int(sp.get("subj_atk_min", 0)) or subject.atk() > int(sp.get("subj_atk_max", 99999)):
			return false
	return feasible(s, p, c, window, subject)


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
static func feasible(s: DuelState, p: int, c, window: String, subject) -> bool:
	var sp := spec(c)
	if not _can_pay(s, p, c, sp):
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
				if a[1] != "target" and a[1] != "attacker" and a[1] != "summoned" and _sel(s, p, c, str(a[1]), {}).is_empty():
					return false
			"revive":
				if ps.free_zone() == -1 or s._best_monsters(ps.gy if a[1] == "own_gy" else ps.gy + opp.gy, 1).is_empty():
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
		return not ps.monsters().is_empty()
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
	elif cost == "tribute":
		var weak = null
		for m in ps.monsters():
			if weak == null or s.atk_of(m, false) < s.atk_of(weak, false):
				weak = m
		weak = s.pick1(p, Loc.t("%s: Tribute 1 monster as the cost") % c.cname(), ps.monsters(), weak, c)
		if weak != null:
			ps.field[ps.field.find(weak)] = null
			s._to_gy(ps, weak)
			events.append({"type": "tribute", "player": p, "card": weak})
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
				"own_mon": ok = mine
				"own_face": ok = mine and m.face_up
				"any_face": ok = m.face_up
				"any_mon", "any_card": ok = true
				"any_fdown": ok = not m.face_up
				"any_fusion": ok = m.face_up and m.frame() == "fusion"
			if ok and (must.is_empty() or CardEffects.matches(m.data, must)):
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
		var mine: bool = x.owner == p
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
		"revive":
			var pool: Array = (ps.gy if a[1] == "own_gy" else ps.gy + opp.gy).filter(func(x): return s.can_revive(x))
			var pick: Array = s._best_monsters(pool, 1)
			if not pick.is_empty() and ps.free_zone() != -1:
				var m = s.pick1(p, Loc.t("%s: Special Summon 1 monster from the Graveyard") % c.cname(), pool, pick[0], c)
				s.players[m.owner].gy.erase(m)
				m.owner = p
				events.append_array(s._special(p, m, "reborn"))
				if a.size() > 3 and a[3] == "link":
					c.linked = m
					c.equipped_to = m if spec(c)["k"] == "equip" else null
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
			var got: Array = EffectRunner._pick(s, p, c, "add 1 card from your Deck to your hand", ps.deck, a[1], 1)
			for g in got:
				ps.deck.erase(g)
				ps.hand.append(g)
				events.append({"type": "search", "player": p, "card": g, "deck": ps.deck.size()})
			s._shuffle(ps.deck)
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
				var n: int = s.atk_of(t, false)
				events.append_array(s._destroy(t))
				events.append_array(s._damage(0, n))
				if not s.is_over():
					events.append_array(s._damage(1, n))
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
		"tokens":
			# ["tokens", n, name, id, atk, def, level, attribute, race]: n Tokens in Defense Position.
			CardData.TOKENS[int(a[3])] = {"name": str(a[2]), "frame": "token", "atk": int(a[4]), "def": int(a[5]), "level": int(a[6]),
					"attribute": str(a[7]), "race": str(a[8]), "no_tribute_summon": true,
					"desc": Loc.t("This card can be used as a \"%s\". It cannot be Tributed for a Tribute Summon.") % str(a[2])}
			ps.no_summon_turn = s.turn
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
		else:
			ps.field[ps.field.find(t)] = null
			s._to_gy(ps, t)
			events.append({"type": "tribute", "player": p, "card": t})
	ps.hand.erase(m)
	m.proper = true
	events.append_array(s._special(p, m, "ritual"))
	events.append_array(EffectRunner.on_summon(s, p, m, "special"))
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
	return n


static func _one_race_gy(s: DuelState, q: int, race: String) -> bool:
	var any := false
	for g in s.players[q].gy:
		if g.is_monster():
			if str(g.data.get("race", "")) != race:
				return false
			any = true
	return any


## Equip-style flags on a monster ("pierce", "no_attack", "no_battle_death").
static func equip_flag(s: DuelState, c, flag: String) -> bool:
	for q in 2:
		for st in s.players[q].spells:
			if st != null and st.face_up and st.equipped_to == c and spec(st).get(flag, false):
				return true
	return false


## Can this monster declare an attack, as far as Spell/Trap cards are concerned?
static func can_attack(s: DuelState, p: int, c) -> bool:
	if s.players[p].no_attack_turn >= s.turn:
		return false
	if equip_flag(s, c, "no_attack"):
		return false
	for q in 2:
		for st in _up(s, q):
			var sp := spec(st)
			if sp.has("lock_atk_min") and s.atk_of(c, false) >= int(sp["lock_atk_min"]):
				return false
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
	c.equipped_to = null
	c.linked = null
	c.counter = 0
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
