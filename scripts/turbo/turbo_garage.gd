class_name TurboGarage
extends RefCounted
## What you have done to your Duel Runner: which frame it is built on, its paint, the colour of
## the light it trails, what is painted on its side, and the parts bolted in. Kept in the
## highway's own save file, and worn in every Turbo Duel as well as on the ride.

static var SAVE := Saves.u("turbo.cfg")
const FRAMES := ["Street frame", "Long frame"]
## [name, colour]. An empty colour means "the colour of your duelist".
const PAINTS := [["Your colour", ""], ["Signal red", "e23a3a"], ["Sunset orange", "ff8a3a"], ["Solar yellow", "ffd23a"],
	["Circuit green", "3ad66e"], ["Tide teal", "2de2e6"], ["Deep blue", "3a6cff"], ["Violet", "9a5cff"],
	["Pearl white", "f2f2f2"], ["Night black", "23252e"]]
const TRAILS := [["Match the paint", ""], ["Red", "ff4040"], ["Orange", "ff8a3a"], ["Gold", "ffd23a"], ["Green", "5aff90"],
	["Teal", "5affd0"], ["Blue", "5a9cff"], ["Violet", "b07cff"], ["White", "ffffff"], ["Pink", "ff6ad8"]]
## [name, what is painted]. "#" stands for your racing number.
const MARKS := [["None", ""], ["Number", "#"], ["Star", "★"], ["Bolt", "⚡"], ["Crown", "♛"], ["Spade", "♠"], ["Wing", "➶"]]
## Parts come in three levels. `step` is what each level adds.
const PARTS := {
	"engine": {"name": "Engine", "what": "Top speed", "unit": "+%d km/h", "step": 7.0},
	"tyres": {"name": "Tyres", "what": "Grip: quicker steering, less pushed wide in bends", "unit": "+%d%% grip", "step": 12.0},
	"booster": {"name": "Booster", "what": "Every boost burns longer", "unit": "+%.1f s", "step": 0.4},
	"brace": {"name": "Frame brace", "what": "A crash costs less time and less Momentum", "unit": "-%d%% crash", "step": 20.0},
}
const PART_ORDER := ["engine", "tyres", "booster", "brace"]
const COST := [300, 700, 1500]

static var data := {}
static var _loaded := false


static func load_data() -> void:
	_loaded = true
	data = {}
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		data = cfg.get_value("garage", "data", {})


static func save() -> void:
	# The highway keeps its own things in the same file: read it first so nothing is lost.
	var cfg := ConfigFile.new()
	cfg.load(SAVE)
	cfg.set_value("garage", "data", data)
	cfg.save(SAVE)


static func val(key: String, fallback = 0):
	if not _loaded:
		load_data()
	return data.get(key, fallback)


static func put(key: String, value) -> void:
	if not _loaded:
		load_data()
	data[key] = value
	save()


static func level(part: String) -> int:
	return clampi(int(val("part_" + part, 0)), 0, COST.size())


## Buy the next level of a part. Returns "" when bought, or why not.
static func buy(part: String) -> String:
	var lvl := level(part)
	if lvl >= COST.size():
		return "That part is as good as it gets."
	var cost: int = COST[lvl]
	if Collection.dp < cost:
		return "Not enough Duel Points."
	Collection.dp -= cost
	Collection.save()
	put("part_" + part, lvl + 1)
	return ""


## What a part gives at its level, as words for the garage.
static func gives(part: String, lvl: int) -> String:
	var p: Dictionary = PARTS[part]
	if lvl <= 0:
		return "Standard"
	var amount: float = float(p["step"]) * lvl
	return str(p["unit"]) % amount


static func frame() -> int:
	return clampi(int(val("frame", 0)), 0, FRAMES.size() - 1)


## The paint, or `fallback` (your duelist's colour) when none was picked.
static func paint(fallback: Color) -> Color:
	var hex := str(PAINTS[clampi(int(val("paint", 0)), 0, PAINTS.size() - 1)][1])
	return Color(hex) if hex != "" else fallback


static func has_paint() -> bool:
	return int(val("paint", 0)) > 0


static func trail(fallback: Color) -> Color:
	var hex := str(TRAILS[clampi(int(val("trail", 0)), 0, TRAILS.size() - 1)][1])
	return Color(hex) if hex != "" else fallback


## What is painted on the side: "", a sign, or your number.
static func mark() -> String:
	var m := str(MARKS[clampi(int(val("mark", 0)), 0, MARKS.size() - 1)][1])
	return str(clampi(int(val("number", 7)), 0, 99)) if m == "#" else m


# What the parts do on the road.
static func top_bonus() -> float:
	return level("engine") * 2.0          # m/s: about 7 km/h a level


static func grip() -> float:
	return 1.0 + level("tyres") * 0.12


static func boost_bonus() -> float:
	return level("booster") * 0.4


static func crash() -> float:
	return 1.0 - level("brace") * 0.2
