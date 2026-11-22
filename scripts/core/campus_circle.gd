class_name CampusCircle
## The Midnight Circle (Academy story, optional): a secret league the students run at night at the
## Old Dorm. No jackets: masks and nicknames, so a Red and a Blue play as equals. One duel a night,
## each under the house rule chalked on the door. Twelve duels in three ranks (Candle, Lantern,
## Midnight), one rank per act. This build has two ranks: the Candle (nights 1 to 4) and, once
## chapter 8 is done, the Lantern (nights 5 to 8).
## Each night is a small story script (CampusData.SCRIPTS "circle_<n>"); this file keeps count.

const OPENS_AFTER := "ac_ch2"
const RANKS := ["Candle", "Lantern", "Midnight"]
## Duels in a rank.
const PER_RANK := 4
## The chapter that opens each rank (a rank with no chapter here is not built yet).
const RANK_AFTER := ["ac_ch2", "ac_ch8"]
const RANK_TROPHY := ["circle_candle", "circle_lantern", "circle_midnight"]
## The card for finishing the Candle rank.
const CANDLE_PRIZE := "Mask of Darkness"
## Night three: the decks in the box (played at their standard version).
const BOX := ["deck_warrior", "deck_dragon", "deck_machine", "deck_water", "deck_fire", "deck_wind", "deck_zombie", "deck_rock"]
const NICKS := {"nick_echo": "Echo", "nick_static": "Static", "nick_ash": "Ash"}


static func unlocked() -> bool:
	return Campus.chapter_done(OPENS_AFTER)


static func state() -> Dictionary:
	var c: Dictionary = Campus.v("circle", {})
	return {"met": bool(c.get("met", false)), "wins": int(c.get("wins", 0)), "night": int(c.get("night", 0))}


## Duels won so far (0 to open_duels()).
static func wins() -> int:
	return int(state()["wins"])


## How many duels are open right now: four for every rank whose chapter is behind you.
static func open_duels() -> int:
	var n := 0
	for i in RANK_AFTER.size():
		if not Campus.chapter_done(str(RANK_AFTER[i])) or not CampusData.SCRIPTS.has("circle_%d" % ((i + 1) * PER_RANK)):
			break
		n = (i + 1) * PER_RANK
	return n


## Is rank `r` (0 Candle, 1 Lantern, 2 Midnight) finished?
static func rank_done(r := 0) -> bool:
	return wins() >= (r + 1) * PER_RANK


## What the door says when every duel that is open has been won.
static func waiting() -> String:
	var r := mini(wins() / PER_RANK, RANKS.size() - 1)
	if r <= 1:
		return "The Candle rank is yours. The Lantern rank opens next term."
	return "The Lantern rank is yours. The Midnight rank opens next term."


## Has tonight's duel been played already?
static func played_tonight() -> bool:
	return int(state()["night"]) == Campus.day()


## What knocking on the door does right now: the script to play ("" when the door stays shut) and,
## when it stays shut, why.
static func knock() -> Dictionary:
	if not unlocked():
		return {"script": "", "why": "The door is shut. They say it only opens at night."}
	if Campus.part() != 2:
		return {"script": "", "why": "The door is shut. They say it only opens at night."}
	var st := state()
	if not bool(st["met"]):
		return {"script": "circle_0", "why": ""}
	if wins() >= open_duels():
		return {"script": "", "why": waiting()}
	if played_tonight():
		return {"script": "", "why": "One duel a night. The door opens again tomorrow night."}
	return {"script": "circle_%d" % (wins() + 1), "why": ""}


## What a Circle duel becomes (laid over what the script says). Night three: both decks come out
## of the box. Night four: you swap, they play your deck and you play theirs. From night five on
## the script says everything itself.
static func duel(n: int, their_deck: String) -> Dictionary:
	match n:
		1:
			return {"my_lp": 4000, "opp_lp": 4000}
		3:
			var rng := RandomNumberGenerator.new()
			rng.seed = 3300 + Campus.day() * 17
			var a := rng.randi_range(0, BOX.size() - 1)
			var b := (a + 1 + rng.randi_range(0, BOX.size() - 2)) % BOX.size()
			return {"my_deck": str(BOX[a]) + "@standard", "opp_deck": str(BOX[b]), "deck_tier": "standard"}
		4:
			return {"my_deck": their_deck, "opp_deck_exact": _my_deck()}
	return {}


static func _my_deck() -> String:
	var col = Engine.get_main_loop().root.get_node_or_null("Collection")
	return str(col.active_deck()) if col != null else ""


## The night is over. `n`: which duel (0: the first visit, nothing played). Returns what to show:
## {"wins", "rank": true when this win finished a rank, "prize": card id or 0}. (The Candle rank
## hands its card over here; from the Lantern rank on the night's own script does.)
static func finish(n: int, won: bool) -> Dictionary:
	var c: Dictionary = (Campus.v("circle", {}) as Dictionary).duplicate(true)
	c["met"] = true
	var out := {"wins": int(c.get("wins", 0)), "rank": false, "prize": 0}
	if n > 0:
		c["night"] = Campus.day()
		if won and int(c.get("wins", 0)) < n:
			c["wins"] = n
			out["wins"] = n
			if n % PER_RANK == 0:
				out["rank"] = true
	Campus.put("circle", c)
	if n == 0:
		Campus.mission_count("circle")
	if bool(out["rank"]):
		Campus.trophy(str(RANK_TROPHY[clampi(n / PER_RANK - 1, 0, RANK_TROPHY.size() - 1)]))
		var id := DeckTiers._id(CANDLE_PRIZE) if n == PER_RANK else 0
		if id != 0:
			var col = Engine.get_main_loop().root.get_node_or_null("Collection")
			if col != null:
				col.owned[id] = mini(3, int(col.owned.get(id, 0)) + 1)
				col.save()
				out["prize"] = id
	return out
