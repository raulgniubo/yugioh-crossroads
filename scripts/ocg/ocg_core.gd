class_name OcgCore
extends RefCounted
## The door to the rules engine (ocgcore, the engine EDOPro runs on). The engine is a native
## library with one entry point; everything here turns that into plain calls. Nothing in the
## game names the native class directly, so if the library is missing the game still starts
## and the classic engine still works.

const LOC_DECK := 0x01
const LOC_HAND := 0x02
const LOC_MZONE := 0x04
const LOC_SZONE := 0x08
const LOC_GRAVE := 0x10
const LOC_REMOVED := 0x20
const LOC_EXTRA := 0x40
const LOC_OVERLAY := 0x80
const LOC_ONFIELD := 0x0c

const POS_FU_ATK := 0x1
const POS_FD_ATK := 0x2
const POS_FU_DEF := 0x4
const POS_FD_DEF := 0x8
const POS_FACEUP := 0x5
const POS_ATTACK := 0x3

## The field Crossroads plays on: Fusion, Synchro and Xyz, no Link zones, no Pendulum zones,
## no draw for whoever goes first.
const DUEL_FLAGS := 0x40000 | 0x10000 | 0x80000

static var _ready_state := 0     # 0 not tried, 1 loaded, -1 not there
static var _strings := {}
static var _why := ""


static func available() -> bool:
	return ClassDB.class_exists("OcgBridge")


static func why_not() -> String:
	return _why


static func op(code: int, data := PackedByteArray()) -> PackedByteArray:
	return ClassDB.class_call_static("OcgBridge", "op", code, data, data.size())


## Load the card table and the card scripts into the engine (once, about a tenth of a second).
static func ensure_loaded() -> bool:
	if _ready_state != 0:
		return _ready_state == 1
	_ready_state = -1
	if not available():
		_why = "The engine library did not load."
		return false
	var cards := FileAccess.get_file_as_bytes("res://data/ocg/cards.bin")
	var packed := FileAccess.get_file_as_bytes("res://data/ocg/scripts.bin")
	if cards.is_empty() or packed.is_empty():
		_why = "The engine's card data is missing."
		return false
	op(1, cards)
	var raw := packed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if raw.is_empty():
		_why = "The engine's card scripts could not be read."
		return false
	op(2, raw)
	var txt := FileAccess.get_file_as_string("res://data/ocg/strings.json")
	var parsed = JSON.parse_string(txt) if txt != "" else null
	_strings = parsed if parsed is Dictionary else {}
	_ready_state = 1
	register_originals()
	return true


const ATTRS := {"EARTH": 0x1, "WATER": 0x2, "FIRE": 0x4, "WIND": 0x8, "LIGHT": 0x10, "DARK": 0x20, "DIVINE": 0x40}
const RACES := ["Warrior", "Spellcaster", "Fairy", "Fiend", "Zombie", "Machine", "Aqua", "Pyro", "Rock", "Winged Beast", "Plant", "Insect",
	"Thunder", "Dragon", "Beast", "Beast-Warrior", "Dinosaur", "Fish", "Sea Serpent", "Reptile", "Psychic", "Divine-Beast", "Creator God", "Wyrm", "Cyberse"]
## The lines the engine shows for the effects of this game's own cards.
const ORIGINAL_LINES := {
	99200001: ["Add 1 monster with 1500 or less ATK from your Deck to your hand"],
	99200002: ["Draw 1 card", "Special Summon \"Lumen, Echo Spirit\" from your Graveyard"],
	99200003: ["Destroy 1 card your opponent controls"],
	99200004: ["Detach 1: Special Summon a \"Lumen\" monster from your Graveyard"],
	99200005: ["Destroy 1 card your opponent controls", "Gain 1000 Life Points"],
}


## The cards that exist only in this game (your partner and her cards) are in no card
## database: tell the engine about them from our own card data. Called again before a duel,
## because your partner's numbers grow with the story.
static func register_originals() -> void:
	if _ready_state != 1:
		return
	var b := StreamPeerBuffer.new()
	var rows: Array = []
	for id in CardData.ORIGINALS:
		rows.append(int(id))
	b.put_u32(rows.size())
	for id in rows:
		var d: Dictionary = CardData.get_card(id)
		var frame := str(d.get("frame", "normal"))
		var kind := str(d.get("kind", "monster"))
		var type := 0
		if kind == "spell":
			type = 0x2 | int({"Quick-Play": 0x10000, "Continuous": 0x20000, "Equip": 0x40000, "Field": 0x80000, "Ritual": 0x80}.get(str(d.get("race", "")), 0))
		elif kind == "trap":
			type = 0x4 | int({"Continuous": 0x20000, "Counter": 0x100000}.get(str(d.get("race", "")), 0))
		else:
			type = 0x1 | (0x10 if frame == "normal" else 0x20)
			type |= int({"fusion": 0x40, "ritual": 0x80, "synchro": 0x2000, "xyz": 0x800000}.get(frame, 0))
			if bool(d.get("tuner", false)):
				type |= 0x1000
		var race := 0
		var ri := RACES.find(str(d.get("race", "")))
		if kind == "monster" and ri != -1:
			race = 1 << ri
		b.put_u32(id)
		b.put_u32(0)
		b.put_u32(type)
		b.put_u32(int(d.get("level", 0)) if kind == "monster" else 0)
		b.put_u32(int(ATTRS.get(str(d.get("attribute", "")), 0)) if kind == "monster" else 0)
		b.put_u64(race)
		b.put_32(int(d.get("atk", 0)) if kind == "monster" else 0)
		b.put_32(int(d.get("def", 0)) if kind == "monster" else 0)
		b.put_u32(0)
		b.put_u32(0)
		b.put_u32(0)
		b.put_u8(0)
	op(1, b.data_array)
	if not _strings.has("card"):
		_strings["card"] = {}
	for id in ORIGINAL_LINES:
		var lines: Array = []
		for line in ORIGINAL_LINES[id]:
			lines.append(Loc.t(str(line)))
		_strings["card"][str(id)] = lines


static func create(seed: int, lp: Array, hand: Array, flags := DUEL_FLAGS) -> int:
	var b := StreamPeerBuffer.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 4:
		b.put_u64(rng.randi() | (rng.randi() << 32))
	b.put_u64(flags)
	for p in 2:
		b.put_u32(int(lp[p]))
		b.put_u32(int(hand[p]))
		b.put_u32(1)
	var r := op(10, b.data_array)
	return r.decode_u32(0) if r.size() >= 4 else 0


## cards: [[team, code, location, position], ...] in the order they go in.
static func add_cards(handle: int, cards: Array) -> void:
	var b := StreamPeerBuffer.new()
	b.put_u32(handle)
	b.put_u32(cards.size())
	for c in cards:
		b.put_u8(int(c[0]))
		b.put_u8(0)
		b.put_u32(int(c[1]))
		b.put_u8(int(c[0]))
		b.put_u32(int(c[2]))
		b.put_u32(0)
		b.put_u32(int(c[3]))
	op(11, b.data_array)


static func _h(handle: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(4)
	b.encode_u32(0, handle)
	return b


static func start(handle: int) -> void:
	op(12, _h(handle))


## Run the duel until it waits for an answer or ends. {"status": 0 end / 1 waiting, "msgs": [...]}
static func process(handle: int) -> Dictionary:
	var v = bytes_to_var(op(13, _h(handle)))
	return v if v is Dictionary else {"status": 0, "msgs": []}


static func respond(handle: int, answer: PackedByteArray) -> void:
	var b := _h(handle)
	b.append_array(answer)
	op(14, b)


## Every card in the places named by `mask`: [player] -> {"<location>": [card or null, ...]}
static func query(handle: int, mask: int) -> Array:
	var b := _h(handle)
	b.resize(8)
	b.encode_u32(4, mask)
	var v = bytes_to_var(op(15, b))
	return v if v is Array else []


static func counts(handle: int) -> Array:
	var v = bytes_to_var(op(18, _h(handle)))
	return v if v is Array else []


static func logs(handle: int) -> Dictionary:
	var v = bytes_to_var(op(17, _h(handle)))
	return v if v is Dictionary else {"logs": [], "missing": []}


static func destroy(handle: int) -> void:
	op(16, _h(handle))


# ------------------------------------------------------------------ the engine's words

static func _lang() -> String:
	return "es" if str(Settings.language) == "es" and _strings.has("es") else "en"


static func sys(id: int) -> String:
	var t: Dictionary = (_strings.get(_lang(), {}) as Dictionary).get("system", {})
	if t.has(str(id)):
		return str(t[str(id)])
	return str(((_strings.get("en", {}) as Dictionary).get("system", {}) as Dictionary).get(str(id), ""))


static func victory(id: int) -> String:
	var t: Dictionary = (_strings.get(_lang(), {}) as Dictionary).get("victory", {})
	return str(t.get(str(id), ((_strings.get("en", {}) as Dictionary).get("victory", {}) as Dictionary).get(str(id), "")))


## A description number from the engine as words: a system line, or one of a card's own lines.
static func desc(v: int) -> String:
	if v <= 0:
		return ""
	var code := v >> 20
	var idx := v & 0xfffff
	if code == 0:
		return sys(idx)
	var lines: Array = (_strings.get("card", {}) as Dictionary).get(str(code), [])
	if idx < lines.size() and str(lines[idx]) != "":
		return str(lines[idx])
	return ""


## "%ls" in a system line is a card name.
static func fill(text: String, card_name: String, place := "") -> String:
	var out := text
	var i := out.find("%ls")
	if i != -1:
		out = out.substr(0, i) + card_name + out.substr(i + 3)
	i = out.find("%ls")
	if i != -1:
		out = out.substr(0, i) + place + out.substr(i + 3)
	return out
