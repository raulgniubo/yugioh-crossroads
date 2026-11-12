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
const SLOTS := 5
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
const PACK_TABS := ["Series sets", "Monster types", "Elements, Spells and Traps"]
const THEMED_PRICE := 200
const PACKS := [
	{"key": "Duel Monsters", "tab": 0, "name": "Legend of the King", "color": Color("8a4dff"), "blurb": "Cards from the Duel Monsters era."},
	{"key": "GX", "tab": 0, "name": "Academy Heroes", "color": Color("ff3a4d"), "blurb": "Cards from the GX era."},
	{"key": "5D's", "tab": 0, "name": "Signer's Road", "color": Color("2de2e6"), "blurb": "Cards from the 5D's era."},
	{"key": "ZEXAL", "tab": 0, "name": "Overlay Network", "color": Color("ffd23a"), "blurb": "Cards from the ZEXAL era."},
	{"key": "Vault", "tab": 0, "name": "Duelist's Vault", "color": Color("5affa0"), "blurb": "Classic Spells, Traps and monsters no story duelist plays."},
	{"key": "beyond", "tab": 0, "name": "Beyond the Limit", "color": Color("b06bff"), "blurb": "Fusion, Synchro, Xyz and Ritual monsters, and the Spells that call them."},
	{"key": "dragons", "tab": 1, "name": "Dragon's Roar", "color": Color("ff5a3c"), "blurb": "Dragons, Dinosaurs, Reptiles and Sea Serpents."},
	{"key": "warriors", "tab": 1, "name": "Blades of Valor", "color": Color("f0b040"), "blurb": "Warriors, from street fighters to legendary knights."},
	{"key": "arcane", "tab": 1, "name": "Arcane Circle", "color": Color("ffd97a"), "blurb": "Spellcasters, Fairies and Thunder."},
	{"key": "shadow", "tab": 1, "name": "Midnight Crypt", "color": Color("9a6bff"), "blurb": "Fiends and Zombies."},
	{"key": "machines", "tab": 1, "name": "Steel Factory", "color": Color("6fc3ff"), "blurb": "Machines of every size."},
	{"key": "wild", "tab": 1, "name": "Call of the Wild", "color": Color("ff9a3c"), "blurb": "Beasts and Beast-Warriors."},
	{"key": "tide", "tab": 2, "name": "Flame and Tide", "color": Color("4aa8ff"), "blurb": "Every WATER and FIRE monster."},
	{"key": "gale", "tab": 2, "name": "Sky Riders", "color": Color("7de0b0"), "blurb": "WIND monsters and Winged Beasts."},
	{"key": "forest", "tab": 2, "name": "Deep Woods", "color": Color("5fd070"), "blurb": "Insects, Plants, Rocks, Aqua, Fish and Pyro."},
	{"key": "spellbook", "tab": 2, "name": "Sorcerer's Library", "color": Color("3fe0c0"), "blurb": "Normal and Quick-Play Spells: removal, draw power, revival."},
	{"key": "arsenal", "tab": 2, "name": "Relic Arsenal", "color": Color("8fb8c8"), "blurb": "Equip, Field and Continuous Spells."},
	{"key": "traps", "tab": 2, "name": "Face-Down Secrets", "color": Color("ff5a8a"), "blurb": "Every Trap card in the game."},
]
## Ready-made theme decks sold at the card shop (duelists' decks are sold there too).
const DECK_PRICE := 1200
const THEME_PRICE := 900
const THEME_DECKS := [
	{"key": "deck_water", "art": "deck_water", "color": Color("4aa8ff"), "blurb": "WATER monsters at home in the open sea. Umi makes every one of them stronger."},
	{"key": "deck_fire", "art": "deck_fire", "color": Color("ff6a3c"), "blurb": "FIRE monsters and a hand full of burn Spells. Win without ever attacking."},
	{"key": "deck_wind", "art": "gale", "color": Color("7de0b0"), "blurb": "WIND monsters that hit fast, backed by Rising Air Current."},
	{"key": "deck_dragon", "art": "dragons", "color": Color("ff5a3c"), "blurb": "Big Dragons, and the smaller ones you Tribute to bring them out."},
	{"key": "deck_warrior", "art": "warriors", "color": Color("f0b040"), "blurb": "Warriors with swords for everyone. Reinforcement of the Army finds the one you need."},
	{"key": "deck_arcane", "art": "arcane", "color": Color("ffd97a"), "blurb": "Spellcasters and Fairies, with Spells that lock the other side down."},
	{"key": "deck_shadow", "art": "shadow", "color": Color("9a6bff"), "blurb": "Fiends that hit hard for their Level, and ways to bring them back."},
	{"key": "deck_machine", "art": "machines", "color": Color("6fc3ff"), "blurb": "Machines with heavy firepower and the tools to make them bigger."},
	{"key": "deck_wild", "art": "wild", "color": Color("ff9a3c"), "blurb": "Beasts with high ATK at Level 4. No tricks, just teeth."},
	{"key": "deck_forest", "art": "forest", "color": Color("5fd070"), "blurb": "Insects and Plants in their Forest, with Traps that slow everything down."},
]
## Solid Normal Monsters that round out the Vault.
const VAULT_EXTRAS := ["Gemini Elf", "Vorse Raider", "Luster Dragon", "Mad Dog of Darkness", "Insect Knight", "Gene-Warped Warwolf",
	"Archfiend Soldier", "Sabersaurus", "Alexandrite Dragon", "Summoned Skull", "Luster Dragon #2", "Mystical Elf", "Giant Soldier of Stone",
	"La Jinn the Mystical Genie of the Lamp", "Dark Blade", "Blazing Inpachi", "Neo the Magic Swordsman", "Sky Scout"]

var owned := {}          # card id -> copies
var main: Array = []     # card ids
var extra: Array = []
var dp := 300
var deck_name := "My Deck"
var side: Array = []     # Side Deck of the deck in use
var slots: Array = []    # saved recipes: {name, main, extra, side}
var slot := 0            # which recipe is loaded
var banlist := false     # play by the Forbidden/Limited list
var decks_owned: Array = ["echo"]   # ready-made decks you have (the Echo starter, and any you bought)
var active := "echo"     # the deck you duel with: "custom" (the one you built) or a ready-made deck
var record := {}         # reward bookkeeping: {"day": "2026-11-12", "streak": 2, "beaten": {key: true}}
var last_reward: Array = []   # what the last duel paid, line by line: [[label, amount], ...]
var _pools := {}


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
		slot = int(cfg.get_value("deck", "slot", 0))
		banlist = bool(cfg.get_value("deck", "banlist", false))
		record = cfg.get_value("wallet", "record", {})
		if cfg.has_section_key("deck", "owned_decks"):
			decks_owned = cfg.get_value("deck", "owned_decks", ["echo"])
			active = str(cfg.get_value("deck", "active", "echo"))
		else:
			_adopt_old_deck()
	else:
		_adopt_old_deck()
	if owned.is_empty():
		_starter()
	_fill_slots()
	if not decks_owned.has("echo"):
		decks_owned.append("echo")
	var forced := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--deck="):
			forced = true
	if not forced:
		_apply_active.call_deferred()


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


## The deck to duel with right now. Falls back to the Echo Deck when the built deck is not
## legal, or the chosen ready-made deck is not on your shelf.
func active_deck() -> String:
	if active == "custom":
		return "custom" if deck_ok() else "echo"
	if decks_owned.has(active) and CardData.has_deck(active):
		return active
	return "echo"


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
	save()
	return true


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
				"blurb": t["blurb"], "art": t["art"], "price": THEME_PRICE, "kind": "theme", "era": ""})
	return out


func deck_info(key: String) -> Dictionary:
	if key == "echo":
		return {"key": "echo", "name": CardData.deck_name("echo"), "owner": "", "who": "player", "color": Color("2de2e6"),
			"blurb": "Your starter deck.", "art": "", "price": 0, "kind": "starter", "era": ""}
	for e in deck_catalog():
		if e["key"] == key:
			return e
	return {"key": key, "name": CardData.deck_name(key), "owner": "", "who": "", "color": Color.WHITE, "blurb": "", "art": "", "price": 0, "kind": "", "era": ""}


## The card that goes on a deck's box: its rarest, strongest monster.
func deck_ace(key: String) -> int:
	var best := 0
	var score := -1
	for id in CardData.extra_list(key) + CardData.deck_list(key):
		var d := CardData.get_card(id)
		if d.get("kind", "") != "monster":
			continue
		var sc := CardData.rarity(id) * 10000 + int(d.get("atk", 0))
		if sc > score:
			score = sc
			best = id
	return best


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


## Five recipe slots. Slot 0 starts as whatever deck you already had.
func _fill_slots() -> void:
	while slots.size() < SLOTS:
		var i := slots.size()
		slots.append({"name": deck_name if i == 0 else "Deck %d" % (i + 1), "main": main.duplicate() if i == 0 else [],
			"extra": extra.duplicate() if i == 0 else [], "side": side.duplicate() if i == 0 else []})
	slot = clampi(slot, 0, SLOTS - 1)


func _store_slot() -> void:
	if slot < slots.size():
		slots[slot] = {"name": deck_name, "main": main.duplicate(), "extra": extra.duplicate(), "side": side.duplicate()}


## Switch to another saved recipe.
func load_slot(i: int) -> void:
	_store_slot()
	slot = clampi(i, 0, SLOTS - 1)
	var s: Dictionary = slots[slot]
	deck_name = str(s.get("name", "Deck %d" % (slot + 1)))
	main = (s.get("main", []) as Array).duplicate()
	extra = (s.get("extra", []) as Array).duplicate()
	side = (s.get("side", []) as Array).duplicate()
	save()


## Copy the deck in use into another slot (overwrites it).
func copy_to_slot(i: int) -> void:
	_store_slot()
	var s: Dictionary = (slots[slot] as Dictionary).duplicate(true)
	s["name"] = deck_name + " copy"
	slots[clampi(i, 0, SLOTS - 1)] = s
	save()


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


## A new duelist starts with the Echo starter deck (and a little more).
func _starter() -> void:
	for key in ["echo", "yugi"]:
		for id in CardData.deck_list(key):
			owned[id] = mini(3, int(owned.get(id, 0)) + 1)
		for id in CardData.extra_list(key):
			owned[id] = mini(3, int(owned.get(id, 0)) + 1)
	main = Array(CardData.deck_list("echo"))
	extra = Array(CardData.extra_list("echo"))
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
	cfg.set_value("deck", "slot", slot)
	cfg.set_value("deck", "banlist", banlist)
	cfg.set_value("wallet", "dp", dp)
	cfg.set_value("wallet", "record", record)
	cfg.set_value("deck", "owned_decks", decks_owned)
	cfg.set_value("deck", "active", active)
	cfg.save(PATH)
	changed.emit()


func count(id: int) -> int:
	return int(owned.get(id, 0))


func in_deck(id: int) -> int:
	return main.count(id) + extra.count(id) + side.count(id)


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
	if not won:
		record["streak"] = 0
		last_reward.append(["Duel finished", 40])
		dp += 40
		save()
		return 40
	last_reward.append([["Win (Easy)", "Win (Normal)", "Win (Hard)", "Win (Expert)"][clampi(difficulty, 0, 3)], 120 + 60 * difficulty])
	var today := Time.get_date_string_from_system()
	if str(record.get("day", "")) != today:
		record["day"] = today
		last_reward.append(["First win of the day", 150])
	var opp := str(info.get("opponent", ""))
	if opp != "":
		var beaten: Dictionary = record.get("beaten", {})
		if not beaten.has(opp):
			beaten[opp] = true
			record["beaten"] = beaten
			last_reward.append(["First win against this duelist", 100])
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
func all_cards() -> Array:
	if _pools.has("*"):
		return _pools["*"]
	var ids := {}
	for era in ["Duel Monsters", "GX", "5D's", "ZEXAL", "Vault"]:
		for id in pool(era):
			ids[id] = true
	_pools["*"] = ids.keys()
	return _pools["*"]


## Every card that can come out of an era's pack: the cards its duelists play.
func pool(era: String) -> Array:
	if _pools.has(era):
		return _pools[era]
	var ids := {}
	if not (era in ["Duel Monsters", "GX", "5D's", "ZEXAL", "Vault"]):
		var themed: Array = []
		for id in all_cards():
			if _in_theme(era, id):
				themed.append(id)
		_pools[era] = themed
		return themed
	if era == "Vault":
		# Every card the game has rules for that the four era packs do not hand out.
		var taken := {}
		for other in ["Duel Monsters", "GX", "5D's", "ZEXAL"]:
			for id in pool(other):
				taken[id] = true
		for name in SpellRules.FX.keys() + CardEffects.FX.keys() + VAULT_EXTRAS:
			var id: int = CardData.NAME_TO_ID.get(str(name).to_lower(), 0)
			if id != 0 and not taken.has(id) and not CardData.get_card(id).is_empty():
				ids[id] = true
		_pools[era] = ids.keys()
		return _pools[era]
	for k in Characters.ORDER:
		var d: Dictionary = Characters.DATA[k]
		if str(d.get("era", "")) != era or not CardData.has_deck(str(d["deck"])):
			continue
		for id in CardData.deck_list(str(d["deck"])) + CardData.extra_list(str(d["deck"])):
			ids[id] = true
	_pools[era] = ids.keys()
	return _pools[era]


## Buy and open a pack. Returns the card ids pulled (empty if you can't afford it).
func open_pack(era: String) -> Array:
	var cards := pool(era)
	var price := PACK_PRICE
	for p in PACKS:
		if p["key"] == era:
			price = pack_price(p)
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
	save()
	return pulls
