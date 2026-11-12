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
var _pools := {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		owned = cfg.get_value("cards", "owned", {})
		main = cfg.get_value("deck", "main", [])
		extra = cfg.get_value("deck", "extra", [])
		deck_name = cfg.get_value("deck", "name", deck_name)
		dp = cfg.get_value("wallet", "dp", dp)
	if owned.is_empty():
		_starter()


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
	cfg.set_value("wallet", "dp", dp)
	cfg.save(PATH)
	changed.emit()


func count(id: int) -> int:
	return int(owned.get(id, 0))


func in_deck(id: int) -> int:
	return main.count(id) + extra.count(id)


func deck_ok() -> bool:
	return main.size() >= MAIN_MIN and main.size() <= MAIN_MAX and extra.size() <= EXTRA_MAX


func can_add(id: int) -> bool:
	var d := CardData.get_card(id)
	var is_extra: bool = str(d.get("frame", "")) in ["fusion", "synchro", "xyz"]
	if in_deck(id) >= mini(3, count(id)):
		return false
	return extra.size() < EXTRA_MAX if is_extra else main.size() < MAIN_MAX


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
				if int(a.get("atk", 0)) >= 2300 or str(a.get("frame", "")) in ["fusion", "synchro", "xyz", "ritual"]:
					id = alt
					break
		pulls.append(id)
		owned[id] = int(owned.get(id, 0)) + 1
	save()
	return pulls
