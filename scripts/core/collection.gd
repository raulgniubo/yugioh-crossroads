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
const PACKS := [
	{"key": "Duel Monsters", "name": "Legend of the King", "color": Color("8a4dff"), "blurb": "Cards from the Duel Monsters era."},
	{"key": "GX", "name": "Academy Heroes", "color": Color("ff3a4d"), "blurb": "Cards from the GX era."},
	{"key": "5D's", "name": "Signer's Road", "color": Color("2de2e6"), "blurb": "Cards from the 5D's era."},
	{"key": "ZEXAL", "name": "Overlay Network", "color": Color("ffd23a"), "blurb": "Cards from the ZEXAL era."},
]

var owned := {}          # card id -> copies
var main: Array = []     # card ids
var extra: Array = []
var dp := 300
var deck_name := "My Deck"
var side: Array = []     # Side Deck of the deck in use
var slots: Array = []    # saved recipes: {name, main, extra, side}
var slot := 0            # which recipe is loaded
var banlist := false     # play by the Forbidden/Limited list
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
	if owned.is_empty():
		_starter()
	_fill_slots()


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


## Duel Points for finishing a duel. Returns how many were earned.
func reward(won: bool, difficulty: int) -> int:
	var n := (120 + 60 * difficulty) if won else 40
	dp += n
	save()
	return n


## Every card that can come out of an era's pack: the cards its duelists play.
func pool(era: String) -> Array:
	if _pools.has(era):
		return _pools[era]
	var ids := {}
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
	if dp < PACK_PRICE or cards.is_empty():
		return []
	dp -= PACK_PRICE
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
