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
	return Saves.admin or stage() >= int(WORLD_STAGE.get(key, 0))


static func world_why(key: String) -> String:
	var need := int(WORLD_STAGE.get(key, 0))
	return Loc.t("Locked: the story takes you there in Chapter %d.") % maxi(1, need)


# ---- packs: each era's pack opens with the story; the special ones need wins.
const PACK_STAGE := {"Duel Monsters": 0, "Vault": 1, "GX": 2, "5D's": 3, "beyond": 3, "ZEXAL": 4}
const THEMED_WINS := 6

static func pack(key: String, tab := 0) -> bool:
	if Saves.admin:
		return true
	if PACK_STAGE.has(key):
		return stage() >= int(PACK_STAGE[key])
	return wins() >= THEMED_WINS


static func pack_why(key: String) -> String:
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
