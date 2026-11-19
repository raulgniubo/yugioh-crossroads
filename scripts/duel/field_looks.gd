class_name FieldLooks
extends RefCounted
## What a Field Spell does to the duel field. A Field Spell is a place: when one is played the
## ground of the field becomes that place (spreading out from the Field Zone), the light and
## the air change with it, things that belong there rise at the edges of the field, and it all
## goes back when the card leaves. Which place a card is, and what it does in plain words.

## surface: how the ground is painted (FieldThemes.GROUND_GLSL). glow: the color of its light,
## its wavefront and its marks. dark: the field's painted lines go dark on this ground (pale
## ground). air: what drifts over the field. props: what stands at its edges. shade: how much
## of a bright ground's light is kept, so the zones painted in white still read on it.
const LOOKS := {
	"grass": {"surface": 1, "glow": Color("9dff7a"), "fog": Color("cfe8c0"), "sky": [Color("2f7fd6"), Color("bfe3ff")], "air": "petals", "props": "grass", "day": true},
	"forest": {"surface": 17, "glow": Color("7dff9a"), "fog": Color("3d6a45"), "sky": [Color("0f2a1a"), Color("5a8a58")], "air": "leaves", "props": "trees"},
	"peak": {"surface": 3, "glow": Color("bfe8ff"), "fog": Color("dbeaff"), "sky": [Color("3a6fc4"), Color("dcefff")], "air": "snow", "props": "rocks", "dark": true, "day": true, "shade": 0.74},
	"waste": {"surface": 19, "glow": Color("ffc27a"), "fog": Color("c9a070"), "sky": [Color("7a5a3a"), Color("e0b880")], "air": "dust", "props": "dead", "day": true},
	"sea": {"surface": 5, "glow": Color("6ae8ff"), "fog": Color("9fe0f0"), "sky": [Color("1f7fd0"), Color("b8f0ff")], "air": "spray", "props": "coral", "dark": true, "day": true, "shade": 0.92},
	"lava": {"surface": 2, "glow": Color("ff8a3a"), "fog": Color("5a1a0a"), "sky": [Color("160505"), Color("8a240c")], "air": "embers", "props": "lava"},
	"dark": {"surface": 6, "glow": Color("c06bff"), "fog": Color("1e0a2c"), "sky": [Color("030108"), Color("2a0b3c")], "air": "motes_dark", "props": "spires"},
	"light": {"surface": 21, "glow": Color("ffe9a0"), "fog": Color("fff2cc"), "sky": [Color("ffd98a"), Color("fff8e0")], "air": "motes_light", "props": "pillars", "dark": true, "day": true, "shade": 0.7},
	"plasma": {"surface": 22, "glow": Color("a35cff"), "fog": Color("1a0a30"), "sky": [Color("05020c"), Color("3a1466")], "air": "sparks", "props": "spires"},
	"sky": {"surface": 20, "glow": Color("9fffd0"), "fog": Color("cfe9ff"), "sky": [Color("2a78d8"), Color("d6ecff")], "air": "wind", "props": "clouds", "dark": true, "day": true, "shade": 0.76},
	"city": {"surface": 9, "glow": Color("7cc4ff"), "fog": Color("1a1430"), "sky": [Color("06081a"), Color("3a2a6a")], "air": "none", "props": "towers"},
	"sand": {"surface": 4, "glow": Color("ffe0a0"), "fog": Color("e8c890"), "sky": [Color("3a5fae"), Color("ffcf8a")], "air": "dust", "props": "ruins", "dark": true, "day": true, "shade": 0.95},
	"gears": {"surface": 23, "glow": Color("ffc66a"), "fog": Color("3a2a1a"), "sky": [Color("120c08"), Color("6a4a2a")], "air": "embers", "props": "towers"},
	"marble": {"surface": 14, "glow": Color("ffe9a0"), "fog": Color("c8d8f0"), "sky": [Color("3a5a9a"), Color("e8f0ff")], "air": "motes_light", "props": "pillars", "dark": true, "day": true, "shade": 0.8},
}

const BY_NAME := {
	"Yami": "dark", "Sogen": "grass", "Forest": "forest", "Mountain": "peak", "Wasteland": "waste",
	"Umi": "sea", "A Legendary Ocean": "sea", "Umiiruka": "sea",
	"Gaia Power": "forest", "Molten Destruction": "lava", "Luminous Spark": "light", "Mystic Plasma Zone": "plasma",
	"Rising Air Current": "sky", "Jurassic World": "forest", "Harpies' Hunting Ground": "waste",
	"Skyscraper": "city", "Necrovalley": "sand", "Chorus of Sanctuary": "marble",
	# (0.61.0)
	"Geartown": "gears", "Skyscraper 2 - Hero City": "city", "Dark City": "city", "Clock Tower Prison": "city", "Kyoutou Waterfront": "city", "Union Hangar": "city",
	"Dragon Ravine": "peak", "Canyon": "waste", "Zombie World": "dark", "Dark Zone": "dark", "Pandemonium": "dark", "Chaos Zone": "dark", "Gateway to Chaos": "dark",
	"Black Garden": "forest", "Venom Swamp": "forest", "Secret Village of the Spellcasters": "forest", "Ojama Country": "grass",
	"Ancient City - Rainbow Ruins": "marble", "The Sanctuary in the Sky": "marble", "Magical Citadel of Endymion": "marble", "Realm of Light": "light",
	"Mausoleum of the Emperor": "sand", "Savage Colosseum": "sand", "Temple of the Kings": "sand",
	"Lemuria, the Forgotten City": "sea", "Pacifis, the Phantasm City": "sea", "Magellanica, the Deep Sea City": "sea",
	"Neo Space": "sky", "Divine Wind of Mist Valley": "sky", "Fusion Gate": "plasma", "Xyz Territory": "plasma",
}
## Words in a Field Spell's text that say what place it is, when nothing else does.
const BY_WORD := [
	["ancient gear", "gears"], ["machine", "city"], ["cyber", "city"], ["water", "sea"], ["fish", "sea"], ["sea serpent", "sea"], ["aqua", "sea"],
	["fire", "lava"], ["pyro", "lava"], ["wind", "sky"], ["winged beast", "sky"], ["dragon", "peak"], ["thunder", "peak"],
	["zombie", "dark"], ["fiend", "dark"], ["dark", "dark"], ["fairy", "light"], ["light", "light"], ["spellcaster", "marble"],
	["plant", "forest"], ["insect", "forest"], ["beast", "forest"], ["dinosaur", "waste"], ["rock", "waste"], ["earth", "waste"], ["warrior", "grass"],
]
const BY_ATTR := {"FIRE": "lava", "WATER": "sea", "WIND": "sky", "EARTH": "forest", "LIGHT": "light", "DARK": "dark"}
const BY_RACE := {
	"Dragon": "peak", "Winged Beast": "peak", "Thunder": "peak", "Warrior": "grass", "Beast-Warrior": "grass",
	"Insect": "forest", "Beast": "forest", "Plant": "forest", "Dinosaur": "waste", "Zombie": "waste", "Rock": "waste",
	"Fish": "sea", "Sea Serpent": "sea", "Aqua": "sea", "Fiend": "dark", "Spellcaster": "dark", "Fairy": "light",
	"Machine": "city", "Pyro": "lava", "Psychic": "plasma", "Reptile": "forest", "Cyberse": "city", "Wyrm": "peak",
}


## The place a Field Spell is. Named cards first, then by what it makes stronger.
static func look_for(card) -> Dictionary:
	var name := str(card.data.get("name", ""))
	var key := str(BY_NAME.get(name, ""))
	var sp: Dictionary = SpellRules.spec(card)
	if key == "":
		for b in sp.get("boost", []):
			var who: Dictionary = b[0]
			if who.has("attr") and BY_ATTR.has(str(who["attr"])):
				key = BY_ATTR[str(who["attr"])]
			elif who.has("race") and BY_RACE.has(str(who["race"])):
				key = BY_RACE[str(who["race"])]
			if key != "":
				break
	if key == "":
		# (0.61.0) A newer Field Spell: the first Attribute or Type its text names.
		var text := (name + ". " + str(card.data.get("desc", card.data.get("text", "")))).to_lower()
		var at := 1 << 30
		for w in BY_WORD:
			var i := text.find(str(w[0]))
			if i >= 0 and i < at:
				at = i
				key = str(w[1])
	if key == "":
		key = "plasma"
	var out: Dictionary = (LOOKS[key] as Dictionary).duplicate()
	out["key"] = key
	out["name"] = name
	return out


## What the card does, as short lines for the strip under the card panel:
## ["Dragon, Winged Beast, Thunder", "+200 ATK  +200 DEF"] pairs.
static func says(card) -> Array:
	var sp: Dictionary = SpellRules.spec(card)
	var groups := {}        # "+200 ATK  +200 DEF" -> [who, who]
	var order: Array = []
	for b in sp.get("boost", []):
		var who: Dictionary = b[0]
		var label := ""
		if who.has("race"):
			label = Loc.t(str(who["race"]))
		elif who.has("attr"):
			label = str(who["attr"])
		elif who.has("has"):
			label = "\"%s\"" % str(who["has"])
		elif who.has("name"):
			label = str(who["name"])
		var parts: Array = []
		if int(b[1]) != 0:
			parts.append("%+d ATK" % int(b[1]))
		if b.size() > 2 and int(b[2]) != 0:
			parts.append("%+d DEF" % int(b[2]))
		var what := "  ".join(parts)
		if label == "" or what == "":
			continue
		if not groups.has(what):
			groups[what] = []
			order.append(what)
		(groups[what] as Array).append(label)
	var out: Array = []
	for what in order:
		out.append([", ".join(groups[what]), what])
	if sp.has("skyscraper"):
		out.append(["Elemental HERO", Loc.t("+%d ATK when it attacks a stronger monster") % int(sp["skyscraper"])])
	if sp.has("def_pos_boost"):
		out.append([Loc.t("Defense Position monsters"), "%+d DEF" % int(sp["def_pos_boost"])])
	return out


## What the Field Spells on the table add to this monster right now: [ATK, DEF].
static func delta(s: DuelState, m) -> Array:
	var a := 0
	var d := 0
	for q in 2:
		var f = s.players[q].field_spell
		if f == null or not f.face_up:
			continue
		var sp: Dictionary = SpellRules.spec(f)
		for b in sp.get("boost", []):
			if CardEffects.matches(m.data, b[0]):
				a += int(b[1])
				if b.size() > 2:
					d += int(b[2])
		if sp.has("def_pos_boost") and not m.attack_pos:
			d += int(sp["def_pos_boost"])
	return [a, d]
