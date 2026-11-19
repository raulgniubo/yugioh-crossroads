class_name Unlocks
extends RefCounted
## What is open, and why. One place for the rules that tie the modes together:
##   - every mode is there from the first minute;
##   - the story opens worlds, and each world's shop sells its own era;
##   - beating a duelist anywhere puts them in Free Duel;
##   - better packs open as the story moves and as you beat more people.
## Admin mode opens everything.

## How far the story has come: 0 new game, 1 prologue done, 2 chapter 1 done ... 6 finished.
static func stage() -> int:
	return 6 if Saves.admin else StoryProgress.stage()


static func _beaten() -> Dictionary:
	var col = Engine.get_main_loop().root.get_node_or_null("Collection")
	return col.record.get("beaten", {}) if col else {}


static func wins() -> int:
	return _beaten().size()


# ---- worlds
const WORLD_STAGE := {"domino": 0, "academy": 2, "satellite": 3, "newdomino": 3, "heartland": 4, "highway": 3}

static func world(key: String) -> bool:
	# The story can open a world early, when a chapter sends you there yourself.
	return Saves.admin or stage() >= int(WORLD_STAGE.get(key, 0)) or StoryProgress.recalls("open_" + key)


static func world_why(key: String) -> String:
	var need := int(WORLD_STAGE.get(key, 0))
	return Loc.t("Locked: the story takes you there in Chapter %d.") % maxi(1, need)


# ---- packs: each era's pack opens with the story; the special ones need wins.
const PACK_STAGE := {"frog": 2, "barrier": 2, "toy": 0, "mask": 0, "goblin": 0, "dd": 0, "dragon_ruler": 4, "ghostrick": 4, "wind_up": 4, "spellbook": 4, "mermail": 4, "gusto": 3, "fortune_lady": 3, "fabled": 3, "karakuri": 3, "synchron": 3, "meklord": 3, "cyber": 2, "sacred_beast": 2, "hero": 2, "union": 0, "spirit": 0, "darklord": 0, "jurrac": 0, "legends_king": 0, "bujin": 4, "nordic": 3, "armed_dragon": 2, "red_eyes": 0, "blue_eyes": 0, "dark_magician": 0, "fire_fist": 4, "tg": 3, "naturia": 3, "cloudian": 2, "kuriboh": 0, "ninja": 4, "ice_barrier": 3, "arcana_force": 2, "koaki_meiru": 2, "exodia": 0, "battlin_boxer": 4, "gimmick_puppet": 4, "x_saber": 3, "volcanic": 2, "alien": 2, "guardian": 0, "chronomaly": 4, "scrap": 3, "morphtronic": 3, "vampire": 2, "crystal_beast": 2, "amazoness": 0, "heroic": 4, "dragunity": 3, "gladiator": 2, "toon": 0, "madolche": 4, "genex": 3, "archfiend": 0, "dark_world": 2, "constellar": 4, "six_samurai": 3, "gravekeeper": 0, "ancient_gear": 2, "lightsworn": 3, "gem_knight": 4, "chaos": 0, "monarchs": 2, "Duel Monsters": 0, "Vault": 1, "legends": 0, "echo": 1, "GX": 2, "5D's": 3, "beyond": 3, "ZEXAL": 4}
const THEMED_WINS := 6

static func pack(key: String, tab := 0) -> bool:
	key = Collection.base_key(key)      # (a volume opens with its set)
	if Saves.admin:
		return true
	if PACK_STAGE.has(key):
		return stage() >= int(PACK_STAGE[key])
	return wins() >= THEMED_WINS


static func pack_why(key: String) -> String:
	key = Collection.base_key(key)
	if PACK_STAGE.has(key):
		return Loc.t("Locked: opens when you finish Chapter %d of the story.") % maxi(1, int(PACK_STAGE[key]) - 1) if int(PACK_STAGE[key]) > 1 else Loc.t("Locked: opens when you finish the Prologue.")
	return Loc.t("Locked: beat %d different duelists to open the themed packs (%d so far).") % [THEMED_WINS, wins()]


# ---- Free Duel: you can face the people you have beaten, plus a few who are always around.
const ALWAYS := ["joey", "weevil", "rex", "mai"]
## Duelists the story has you beat: finishing that chapter puts them on the list too.
const STORY_MET := {"kaiba": 2, "yugi": 2, "chazz": 3, "jaden": 3, "jack": 4, "yusei": 4, "crow": 4, "yuma": 5, "kite": 5, "shark": 5}

static func opponent(key: String) -> bool:
	if Saves.admin or key == "player" or key in ALWAYS:
		return true
	if _beaten().has(key):
		return true
	return STORY_MET.has(key) and stage() >= int(STORY_MET[key])


static func opponent_why(key: String) -> String:
	if STORY_MET.has(key):
		return Loc.t("Locked: beat this duelist in the story or in their world.")
	return Loc.t("Locked: find this duelist in the open world and beat them once.")


# ---- how hard somebody is, as stars (shown over duelists in the world)
static func stars(difficulty: int, rare := false) -> String:
	var n := clampi(difficulty + 1 + (1 if rare else 0), 1, 5)
	return "★".repeat(n) + "☆".repeat(5 - n)


## One ladder for everybody you can duel in the worlds. The duelists of the four series stand
## where their series puts them; ordinary people stand below the named rivals of their world;
## a dorm sets a student's range (Red 1 to 2, Yellow 2 to 3, Blue 3 to 4). Only the rare night
## duelists reach the top on their own.
const SERIES_STARS := {
	"yugi": 5, "kaiba": 5, "marik": 5, "pegasus": 5, "joey": 4, "mai": 4, "bakura": 4, "weevil": 3, "rex": 3,
	"jaden": 5, "zane": 5, "aster": 5, "chazz": 4, "alexis": 4, "syrus": 3,
	"yusei": 5, "jack": 5, "crow": 4, "akiza": 4, "kalin": 4,
	"kite": 5, "yuma": 4, "shark": 4, "vector": 4,
}
const DORM_STARS := {"red": [1, 2], "yellow": [2, 3], "blue": [3, 4]}

## Stars (1 to 5) of the person `d` (a world duelist's entry, with its "duel").
static func stars_of(d: Dictionary) -> int:
	var duel: Dictionary = d.get("duel", {})
	if duel.has("stars"):
		return clampi(int(duel["stars"]), 1, 5)
	var who := str(d.get("char", ""))
	if SERIES_STARS.has(who):
		return int(SERIES_STARS[who])
	var rare := bool(duel.get("rare", false))
	var n := clampi(int(duel.get("difficulty", 1)) + 1 + (1 if rare else 0), 1, 5)
	if rare:
		return n
	var dorm := str(d.get("dorm", ""))
	if dorm == "":
		for k in DORM_STARS:
			if who.begins_with(k):          # "blue_student", "red_student"...
				dorm = k
	if DORM_STARS.has(dorm):
		return clampi(n, int(DORM_STARS[dorm][0]), int(DORM_STARS[dorm][1]) - (1 if dorm == "blue" else 0))
	return mini(n, 3)


static func stars_text(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(5 - n)


## How well somebody with that many stars plays (the computer's level), 0 to 3.
static func level_for(stars_n: int) -> int:
	return [0, 0, 1, 2, 3, 3][clampi(stars_n, 1, 5)]
