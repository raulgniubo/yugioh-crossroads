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
const ATTACK_FIRST_TURN := 0x02      # (puzzles: the board is the middle of a duel)

## Cards that are rules, not cards of anybody's deck.
const SPEED_WORLD := 99100000        # each rider's road in a Turbo Duel (it sits in the Field Zone, unseen)
const DESTINY := 99199999            # (only a number its questions are filed under)

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


## The engine's own card table says what kind of card an id is (bits: 0x1 monster, 0x2 Spell,
## 0x4 Trap, 0x40 Fusion, 0x2000 Synchro, 0x800000 Xyz, 0x1000000 Pendulum, 0x4000000 Link).
## Read straight from the packed table, so it works whether or not the library loaded. 0: unknown.
const TYPE_PENDULUM := 0x1000000
const TYPE_LINK := 0x4000000
static var _types := {}

static func type_of(id: int) -> int:
	if _types.is_empty():
		var b := FileAccess.get_file_as_bytes("res://data/ocg/cards.bin")
		var at := 4
		var n := b.decode_u32(0) if b.size() >= 4 else 0
		for i in n:
			if at + 49 > b.size():
				break
			_types[b.decode_u32(at)] = b.decode_u32(at + 8)
			at += 48 + 1 + 2 * b.decode_u8(at + 48)
		_types[0] = 0
	return int(_types.get(id, 0))


static var _rows := {}

## What the engine's card table says about a card: [alias, type, attribute, race, [set codes]].
static func row_of(id: int) -> Array:
	if _rows.is_empty():
		var b := FileAccess.get_file_as_bytes("res://data/ocg/cards.bin")
		var at := 4
		var n := b.decode_u32(0) if b.size() >= 4 else 0
		for i in n:
			if at + 49 > b.size():
				break
			var cnt := b.decode_u8(at + 48)
			var sets: Array = []
			for k in cnt:
				sets.append(b.decode_u16(at + 49 + 2 * k))
			_rows[b.decode_u32(at)] = [b.decode_u32(at + 4), b.decode_u32(at + 8), b.decode_u32(at + 16), b.decode_s64(at + 20), sets]
			at += 49 + 2 * cnt
		_rows[0] = []
	return _rows.get(id, [])


## "Declare 1 card name": whether the engine will take this card for the question's own test
## (the list of numbers that comes with the question). The engine's rule, step for step.
static func announce_ok(opts: Array, id: int) -> bool:
	var row := row_of(id)
	if row.is_empty():
		return false
	var st: Array = []
	var alias := false
	var token := false
	for o in opts:
		var op := int(o)
		match op:
			0x4000000000000000, 0x4000000100000000, 0x4000000200000000, 0x4000000300000000, 0x4000000400000000, 0x4000000500000000, \
			0x4000000800000000, 0x4000000900000000, 0x4000001100000000, 0x4000001200000000, 0x4000001300000000:
				if st.size() >= 2:
					var r: int = st.pop_back()
					var l: int = st.pop_back()
					match op:
						0x4000000000000000: st.append(l + r)
						0x4000000100000000: st.append(l - r)
						0x4000000200000000: st.append(l * r)
						0x4000000300000000: st.append(l / r if r != 0 else 0)
						0x4000000400000000: st.append(1 if l != 0 and r != 0 else 0)
						0x4000000500000000: st.append(1 if l != 0 or r != 0 else 0)
						0x4000000800000000: st.append(l & r)
						0x4000000900000000: st.append(l | r)
						0x4000001100000000: st.append(l ^ r)
						0x4000001200000000: st.append(l << (r & 63))
						0x4000001300000000: st.append(l >> (r & 63))
			0x4000000600000000, 0x4000000700000000, 0x4000001000000000, 0x4000010000000000, 0x4000010100000000, 0x4000010200000000, \
			0x4000010300000000, 0x4000010400000000:
				if st.size() >= 1:
					var v: int = st.pop_back()
					match op:
						0x4000000600000000: st.append(-v)
						0x4000000700000000: st.append(1 if v == 0 else 0)
						0x4000001000000000: st.append(~v)
						0x4000010000000000: st.append(1 if id == (v & 0xffffffff) else 0)
						0x4000010100000000:
							var hit := 0
							for sc in row[4]:
								if (int(sc) & 0xfff) == (v & 0xfff) and (int(sc) & 0xf000 & v) == (v & 0xf000):
									hit = 1
							st.append(hit)
						0x4000010200000000: st.append(int(row[1]) & v)
						0x4000010300000000: st.append(int(row[3]) & v)
						0x4000010400000000: st.append(int(row[2]) & v)
			0x4000001400000000: alias = true
			0x4000001500000000: token = true
			0x4000010500000000: st.append(id)
			0x4000010700000000: st.append(int(row[1]))
			0x4000010800000000: st.append(int(row[3]))
			0x4000010900000000: st.append(int(row[2]))
			_: st.append(op)
	if st.size() != 1 or int(st[0]) == 0:
		return false
	return (alias or int(row[0]) == 0) and (token or (int(row[1]) & 0x4001) != 0x4001)


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
	99100000: ["4 Speed Counters: 800 damage for each Spell in your hand", "7 Speed Counters: draw 1 card", "10 Speed Counters: destroy 1 card on their field"],
	99199999: ["Destiny Draw: reach for the card you need?", "Destiny Draw: choose the card you draw"],
}
const QUICK_ORIGINALS := [99100004, 99100007, 99100012, 99100013, 99100017]


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
	b.put_u32(rows.size() + 1)
	# Speed World 2: a Field Spell nobody owns a copy of.
	b.put_u32(SPEED_WORLD)
	b.put_u32(0)
	b.put_u32(0x2 | 0x80000)
	b.put_u32(0)
	b.put_u32(0)
	b.put_u64(0)
	b.put_32(0)
	b.put_32(0)
	b.put_u32(0)
	b.put_u32(0)
	b.put_u32(0)
	b.put_u8(0)
	for id in rows:
		var d: Dictionary = CardData.get_card(id)
		var frame := str(d.get("frame", "normal"))
		var kind := str(d.get("kind", "monster"))
		var type := 0
		if kind == "spell":
			type = 0x2 | int({"Quick-Play": 0x10000, "Continuous": 0x20000, "Equip": 0x40000, "Field": 0x80000, "Ritual": 0x80}.get(str(d.get("race", "")), 0))
			if QUICK_ORIGINALS.has(id):
				type |= 0x10000
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


## cards: [[team, code, location, position, sequence (optional)], ...] in the order they go in.
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
		b.put_u32(int(c[4]) if c.size() > 4 else 0)
		b.put_u32(int(c[3]))
	op(11, b.data_array)


## Run one more script in a duel before it starts (a rule of this game: Destiny Draw, a starting speed).
static func load_script(handle: int, name: String, text: String) -> void:
	var b := _h(handle)
	var nb := name.to_utf8_buffer()
	b.resize(6)
	b.encode_u16(4, nb.size())
	b.append_array(nb)
	b.append_array(text.to_utf8_buffer())
	op(19, b)


## A card's name: the game's own, else the engine's Token or rule names.
static func card_name(code: int) -> String:
	if code == SPEED_WORLD:
		return "Speed World 2"
	var n := str(CardData.get_card(code).get("name", ""))
	if n != "" and n != "Unknown":
		return n
	var t := token_data(code)
	return str(t.get("name", "?"))


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


# ------------------------------------------------------------------ the opponent's brain

## Ask the engine-side opponent for its answer to the open question. level: 1 Normal, 2 Hard,
## 3 Extreme (0: the plain policy). Blocks until it has it; use think_start / think_poll in a duel.
static func think(handle: int, level: int, ms := 0, seed := 1) -> Dictionary:
	var b := _h(handle)
	b.resize(20)
	b.encode_u32(4, level)
	b.encode_u32(8, ms)
	b.encode_u64(12, seed)
	var r := op(30, b)
	if r.size() < 12:
		return {"answer": PackedByteArray(), "sims": 0, "cands": 0, "ms": 0}
	return {"sims": r.decode_u32(0), "cands": r.decode_u32(4), "ms": r.decode_u32(8), "answer": r.slice(12)}


static func think_start(handle: int, level: int, ms := 0, seed := 1) -> void:
	var b := _h(handle)
	b.resize(20)
	b.encode_u32(4, level)
	b.encode_u32(8, ms)
	b.encode_u64(12, seed)
	op(31, b)


## {} while it is still thinking, else {"answer", "sims", "cands", "ms"}.
static func think_poll(handle: int) -> Dictionary:
	var r := op(32, _h(handle))
	if r.size() < 13 or r[0] != 2:
		return {}
	return {"sims": r.decode_u32(1), "cands": r.decode_u32(5), "ms": r.decode_u32(9), "answer": r.slice(13)}


## A whole duel between two levels with no screen (for measuring). decks/extras: [side 0, side 1].
static func match_duel(decks: Array, extras: Array, levels: Array, seed: int, ms := 0, lp := 8000, max_turns := 60) -> Dictionary:
	var b := StreamPeerBuffer.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 4:
		b.put_u64(rng.randi() | (rng.randi() << 32))
	b.put_u64(DUEL_FLAGS)
	for p in 2:
		b.put_u32(lp)
		b.put_u32(5)
	b.put_u32(int(levels[0]))
	b.put_u32(int(levels[1]))
	b.put_u32(ms)
	b.put_u32(max_turns)
	b.put_u64(seed)
	for p in 2:
		for part in [decks[p], extras[p]]:
			b.put_u32((part as Array).size())
			for id in part:
				b.put_u32(int(id))
	var r := op(33, b.data_array)
	if r.size() < 28:
		return {"winner": 2}
	var out := {"winner": r.decode_u32(0), "turns": r.decode_u32(4), "decisions": r.decode_u32(8), "sims": r.decode_u32(12),
		"think_ms": r.decode_u32(16), "max_ms": r.decode_u32(20), "refused": r.decode_u32(24), "played": [], "logs": []}
	if r.size() >= 32:
		var n := r.decode_u32(28)
		for i in n:
			(out["played"] as Array).append(r.decode_u32(32 + 4 * i))
		var lg = bytes_to_var(r.slice(32 + 4 * n))
		if lg is Array:
			out["logs"] = lg
		elif lg is Dictionary:
			out["logs"] = lg.get("logs", [])
			out["acted"] = lg.get("acted", [])
			out["cs"] = lg.get("cs", {})          # (0.76.0) common-sense mistakes per level: "L2:help_foe" -> n
			out["cs_ex"] = lg.get("cs_ex", [])
	return out


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


## A Token the game's own card data does not know, as card data (or {} if the engine does not know it either).
static func token_data(code: int) -> Dictionary:
	var t: Dictionary = (_strings.get("tokens", {}) as Dictionary).get(str(code), {})
	if t.is_empty():
		return {}
	return {"id": code, "name": str(t["name"]), "frame": "token", "kind": "monster", "atk": int(t["atk"]), "def": int(t["def"]),
		"level": int(t["level"]), "attribute": str(t["attribute"]), "race": str(t["race"]), "text": ""}


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
