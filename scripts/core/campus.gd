class_name Campus
## The Academy story's state (0.65.0): which day it is, the part of the day, your dorm, your
## merits, what you chose, who you are close to, the mission board. It lives in campus.cfg,
## one more file of the normal save (Saves.FILES), next to the story's own place and memory
## (CampusProgress, same file, section "story"). The Academy's own cards and decks are a second
## Collection file, campus_cards.cfg (see Collection.switch_file).
##
## Two ways to play, picked when a game starts and changed from your room:
##   "academia"  you start from a novice deck and everything is earned on the island
##   "libre"     your own decks and your whole collection; rivals come one step stronger

const PATH := "user://campus.cfg"
const CARDS := "user://campus_cards.cfg"
const PARTS := ["Morning", "Afternoon", "Night"]
const PART_TOD := ["day", "sunset", "night"]
const WEEK := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const DORMS := ["red", "yellow", "blue"]
const DORM_NAMES := ["Red Dorm", "Yellow Dorm", "Blue Dorm"]
const DORM_COLORS := [Color("d9342b"), Color("f2c230"), Color("2f6fe0")]
## Merits it takes to be allowed up from each dorm (tuned by play).
const NEED := [300, 800, 1500]
## Your room, by dorm: the room key in AcademyRooms and where the bed is, from the room's centre.
const ROOM := ["red_room_2", "yel_room_2", "blue_room_1"]
const DEFAULTS := {"started": false, "mode": "academia", "day": 1, "part": 0, "dorm": 0, "merits": 0,
	"bonds": {}, "missions": {}, "trophies": [], "seen": [], "done": [], "wins": 0, "losses": 0, "slept": 0,
	"free_days": false, "jacket": false, "version": 1}

## An Academy session is running: the island belongs to the Academy story.
static var on := false
static var _c := {}
static var _have := false
## What was just earned, for the corner of the screen: [[amount, why], ...] (CampusLife takes them).
static var feed: Array = []


# ------------------------------------------------------------------ the file

## Read campus.cfg. If it is damaged (a power cut in the middle of a write), the copy kept from
## the save before it is used.
static func read() -> ConfigFile:
	var cfg := ConfigFile.new()
	if not FileAccess.file_exists(PATH):
		return cfg       # (no Academy game in this save: the copy beside it belongs to another one)
	if cfg.load(PATH) != OK and FileAccess.file_exists(PATH + ".bak"):
		cfg = ConfigFile.new()
		cfg.load(PATH + ".bak")
	return cfg


## Write campus.cfg: to a file beside it first, then swapped in whole, so a power cut in the
## middle of a save can never leave half a file. (Saves.guard_files keeps the copy from the last
## good start, as for every other save file.)
static func write(cfg: ConfigFile) -> void:
	if cfg.save(PATH + ".new") != OK or DirAccess.rename_absolute(PATH + ".new", PATH) != OK:
		cfg.save(PATH)
	Saves.push_file(PATH.get_file())


static func _state() -> Dictionary:
	if not _have:
		_have = true
		var cfg := read()
		_c = DEFAULTS.duplicate(true)
		if cfg.has_section("campus"):
			for k in cfg.get_section_keys("campus"):
				_c[k] = cfg.get_value("campus", k)
	return _c


## Forget what is in memory (another save was loaded, or the test changed the file).
static func reload() -> void:
	_have = false
	_c = {}


static func v(key: String, fallback = null):
	var s := _state()
	var got = s.get(key, DEFAULTS.get(key, fallback))
	return fallback if got == null else got


static func s_has(key: String) -> bool:
	return _state().has(key)


static func put(key: String, value) -> void:
	_state()[key] = value
	var cfg := read()
	cfg.set_value("campus", key, value)
	write(cfg)


static func put_many(pairs: Dictionary) -> void:
	var cfg := read()
	for k in pairs:
		_state()[k] = pairs[k]
		cfg.set_value("campus", str(k), pairs[k])
	write(cfg)


# ------------------------------------------------------------------ plain facts

static func started() -> bool:
	return bool(v("started"))


static func mode() -> String:
	return str(v("mode"))


static func own_cards() -> bool:
	return mode() == "academia"


static func day() -> int:
	return maxi(1, int(v("day")))


static func part() -> int:
	return clampi(int(v("part")), 0, 2)


static func weekday() -> int:
	return (day() - 1) % 7


static func dorm() -> int:
	return clampi(int(v("dorm")), 0, 2)


static func merits() -> int:
	return int(v("merits"))


static func tod() -> String:
	return PART_TOD[part()]


## "Monday · Morning · Day 3"
static func when_text() -> String:
	return "%s  ·  %s" % [Loc.t(WEEK[weekday()]), Loc.t(PARTS[part()])]


static func coat() -> String:
	return DORMS[dorm()]


# ------------------------------------------------------------------ starting, coming in, leaving

## A new Academy game: the campus file is wiped (the Academy's own cards too) and the prologue
## is the place to go.
static func new_game(how: String) -> void:
	var cfg := ConfigFile.new()
	for k in DEFAULTS:
		cfg.set_value("campus", k, DEFAULTS[k])
	cfg.set_value("campus", "started", true)
	cfg.set_value("campus", "mode", how if how in ["academia", "libre"] else "academia")
	write(cfg)
	if FileAccess.file_exists(PATH + ".bak"):
		DirAccess.remove_absolute(PATH + ".bak")
	reload()
	var col = _col()
	if col and str(col.path) == CARDS:
		col.switch_file(col.PATH)
	if FileAccess.file_exists(CARDS):
		DirAccess.remove_absolute(CARDS)


static func _col():
	var loop := Engine.get_main_loop()
	return (loop as SceneTree).root.get_node_or_null("Collection") if loop else null


static func _router():
	return (Engine.get_main_loop() as SceneTree).root.get_node("Router")


## Step onto the island: the director reads the Academy's chapters and the collection becomes
## the Academy's own (in "academia"). Safe to call twice.
static func enter() -> void:
	on = true
	StoryDirector.campus = true
	var col = _col()
	if col:
		col.switch_file(CARDS if own_cards() else col.PATH)


## Your dorm's jacket, as a color, or null before the entrance exam hands you one (RoamScene and
## the duel dress you from this while Campus.on).
static func jacket():
	return DORM_COLORS[dorm()] if bool(v("jacket", false)) else null


## Back to the rest of the game: your own collection again.
static func leave() -> void:
	on = false
	StoryDirector.campus = false
	var col = _col()
	if col:
		col.switch_file(col.PATH)


## Change between "academia" and "libre" (from your room).
static func set_mode(how: String) -> void:
	put("mode", how)
	if on:
		enter()


## Go to where the Academy game is: the chapter in progress, or the island on a free day.
static func go() -> void:
	enter()
	var pos: Dictionary = CampusProgress.position()
	var ch := str(pos.get("chapter", ""))
	if ch != "" and CampusData.SCRIPTS.has(ch):
		StoryDirector.begin(ch, true)
		return
	var next := next_chapter()
	if next != "" and not bool(v("free_days")):
		StoryDirector.begin(next)
		return
	island()


## The island on a free day: the open world, at the spot you were (or the door of your room).
static func island(at = null) -> void:
	enter()
	var r = _router()
	var spot = at
	if spot == null and s_has("x"):
		spot = Vector3(float(v("x")), 0, float(v("z")))
	if spot == null:
		spot = CampusData.YARDS[dorm()]      # nowhere remembered yet: the front yard of your dorm
	r.roam = {"district": "academy", "pos": spot, "tod": tod(), "free": true}
	if s_has("yaw") and at == null:
		r.roam["yaw"] = float(v("yaw"))
	r.story_result = ""
	r.go(r.ROAM)


## Where you stand (written as you walk, so "continue" puts you back there).
static func note(pos: Vector3, yaw: float) -> void:
	put_many({"x": pos.x, "z": pos.z, "yaw": yaw})


## The first chapter that is open and not finished yet ("" when the story has nothing new).
static func next_chapter() -> String:
	var u: Array = CampusProgress.unlocked()
	var done: Array = v("done", [])
	for ch in CampusData.CHAPTERS:
		var id := str(ch["id"])
		if u.has(id) and not done.has(id) and CampusData.SCRIPTS.has(id):
			return id
	return ""


static func finish_chapter(id: String) -> void:
	var done: Array = (v("done", []) as Array).duplicate()
	if not done.has(id):
		done.append(id)
	put("done", done)


static func chapter_done(id: String) -> bool:
	return (v("done", []) as Array).has(id)


# ------------------------------------------------------------------ merits

static func add_merits(n: int, why := "") -> void:
	if n == 0:
		return
	put("merits", maxi(0, merits() + n))
	feed.append([n, why])
	if feed.size() > 6:
		feed.pop_front()


## How many are still missing to be allowed to sit the promotion exam (0: enough).
static func merits_to_go() -> int:
	return maxi(0, int(NEED[dorm()]) - merits())


# ------------------------------------------------------------------ time

## The day moves on a part: morning -> afternoon -> night. Night stays night until you sleep.
static func pass_time() -> bool:
	if part() >= 2:
		return false
	put("part", part() + 1)
	return true


## Sleep in your room: the next morning.
static func sleep() -> void:
	put_many({"day": day() + 1, "part": 0, "slept": int(v("slept")) + 1})
	_cup_day()


static func set_time(d: int, p: int) -> void:
	var later := maxi(1, d) > day()
	put_many({"day": maxi(1, d), "part": clampi(p, 0, 2)})
	if later:
		_cup_day()


# ------------------------------------------------------------------ the Dorm Cup

## The Dorm Cup (open from chapter 2): the three dorms' points this term, [red, yellow, blue].
## A win against a student of another dorm scores for yours, by how strong they are. Every new
## day the three dorms also score a little on their own: Blue the most, Red the least.
const CUP_START := [2, 5, 9]
const CUP_DAILY := [[1, 2], [3, 4], [5, 6, 5]]

static func cup_on() -> bool:
	return bool((v("cup", {}) as Dictionary).get("open", false))


static func cup_points() -> Array:
	return ((v("cup", {}) as Dictionary).get("pts", [0, 0, 0]) as Array).duplicate()


static func cup_open() -> void:
	if cup_on():
		return
	put("cup", {"open": true, "pts": CUP_START.duplicate(), "since": day()})
	feed.append([0, "The Dorm Cup is open", "note"])


## 1, 2 or 3: where this dorm stands in the Cup (ties go to the higher dorm, as on the board).
static func cup_place(d: int) -> int:
	var pts := cup_points()
	var place := 1
	for i in 3:
		if i != d and (int(pts[i]) > int(pts[d]) or (int(pts[i]) == int(pts[d]) and i > d)):
			place += 1
	return place


## You beat a student of `their` dorm ("red", "yellow", "blue") worth `stars`. The points scored.
static func cup_score(their: String, stars: int) -> int:
	if not cup_on() or not DORMS.has(their) or their == DORMS[dorm()]:
		return 0
	var c: Dictionary = (v("cup", {}) as Dictionary).duplicate(true)
	var n := clampi(stars, 1, 5)
	c["pts"][dorm()] = int(c["pts"][dorm()]) + n
	put("cup", c)
	feed.append([n, DORM_NAMES[dorm()], "cup"])
	mission_count("cup", n)
	return n


## Points for a dorm from the story (a Cup duel on the duel field): "red", "yellow" or "blue".
static func cup_add(which: String, n: int) -> void:
	var i := DORMS.find(which)
	if not cup_on() or i < 0 or n == 0:
		return
	var c: Dictionary = (v("cup", {}) as Dictionary).duplicate(true)
	c["pts"][i] = int(c["pts"][i]) + n
	put("cup", c)
	feed.append([n, DORM_NAMES[i], "cup"])


## The oldest rule of the Cup: a dorm that wins the final round cannot finish last, whatever the
## table says. If `which` is last, it is lifted to one point above the dorm in front of it.
static func cup_not_last(which: String) -> void:
	var i := DORMS.find(which)
	if not cup_on() or i < 0 or cup_place(i) < 3:
		return
	var c: Dictionary = (v("cup", {}) as Dictionary).duplicate(true)
	var low := 1 << 30
	for k in 3:
		if k != i:
			low = mini(low, int(c["pts"][k]))
	var n := low + 1 - int(c["pts"][i])
	c["pts"][i] = low + 1
	put("cup", c)
	feed.append([n, DORM_NAMES[i], "cup"])


## Your classmates get better as the year goes on: one more star (a stronger version of their deck,
## a sharper duelist) for each of their chapters you have finished. See CampusData.GROWTH.
static func growth(who: String) -> int:
	var n := 0
	for ch in CampusData.GROWTH.get(who, []):
		if chapter_done(str(ch)):
			n += 1
	return n


## How strong somebody on the island is right now: what they are worth by themselves, plus a star
## for every chapter that made them grow, plus (your own year only) one for every dorm you have
## climbed, because they have been climbing too. Never more than five.
static func stars_now(who: String, base: int) -> int:
	var n := base + growth(who)
	if who in CampusData.CLASSMATES:
		n += dorm()
	return clampi(n, 1, 5)


## The deck somebody on the island brings, moved by how you play: your difficulty setting (Hard a
## step up the ladder Starter, Standard, Full; Extreme two) and one more step when you brought your
## own collection instead of building one here. A whole deck stays whole.
static func deck_now(key: String) -> String:
	var harder := Saves.story_difficulty() + (0 if own_cards() else 1)
	if harder <= 0 or not key.contains("@"):
		return key
	var sp: Array = DeckTiers.split(key)
	return DeckTiers.with_version(str(sp[0]), DeckTiers.shift(str(sp[1]), harder))


## The island's best (they play their whole deck and think at Extreme from the first day): beating
## one of them while you still wear red is a trophy, and they remember it. True the first time.
const ELITE := ["zane", "jaden", "aster", "sato"]

static func beat_elite(who: String) -> bool:
	if not (who in ELITE) or dorm() != 0:
		return false
	CampusProgress.remember("beat_" + who)
	if (v("trophies", []) as Array).has("beat_elite"):
		return false
	trophy("beat_elite")
	return true


static func _cup_day() -> void:
	if not cup_on():
		return
	var c: Dictionary = (v("cup", {}) as Dictionary).duplicate(true)
	for i in 3:
		var steps: Array = CUP_DAILY[i]
		c["pts"][i] = int(c["pts"][i]) + int(steps[day() % steps.size()])
	put("cup", c)


## One line about the Cup for the corner of the screen ("" while it is not open).
static func cup_line() -> String:
	if not cup_on():
		return ""
	var pts := cup_points()
	var me := dorm()
	var place := cup_place(me)
	if place == 1:
		return Loc.t("Dorm Cup: %s is first") % Loc.t(DORM_NAMES[me])
	# The dorm right above yours, and how far it is.
	var above := -1
	for i in 3:
		if i != me and cup_place(i) == place - 1:
			above = i
	var gap := int(pts[above]) - int(pts[me])
	return Loc.t("Dorm Cup: %s is %s, %d behind %s") % [Loc.t(DORM_NAMES[me]), Loc.t("second" if place == 2 else "last"), gap, Loc.t(DORM_NAMES[above])]


# ------------------------------------------------------------------ people

static func bond(who: String) -> int:
	return int((v("bonds", {}) as Dictionary).get(who, 0))


static func add_bond(who: String, by := 1) -> void:
	var b: Dictionary = (v("bonds", {}) as Dictionary).duplicate()
	b[who] = clampi(int(b.get(who, 0)) + by, 0, 10)
	put("bonds", b)


## Who you are closest to (among your classmates), or "".
static func closest() -> String:
	var best := ""
	var top := 0
	var b: Dictionary = v("bonds", {})
	for who in b:
		if int(b[who]) > top and str(who) in CampusData.CLASSMATES:
			top = int(b[who])
			best = str(who)
	return best


# ------------------------------------------------------------------ the mission board

## What the golden (story) mission says right now: {"text", "sub"}.
static func golden() -> Dictionary:
	var next := next_chapter()
	if next == "":
		return {"text": "The next chapter is on its way", "sub": "Until then the island is yours: duel, train, and fill your collection."}
	for ch in CampusData.CHAPTERS:
		if str(ch["id"]) == next:
			return {"text": "%s: %s" % [Loc.t(str(ch["title"])), Loc.t(str(ch["name"]))], "sub": str(ch.get("lead", "")), "chapter": next}
	return {}


## Silver missions: {id: {"n": progress, "done": bool, "paid": bool}}. See CampusData.MISSIONS.
static func mission(id: String) -> Dictionary:
	return (v("missions", {}) as Dictionary).get(id, {"n": 0, "done": false, "paid": false})


static func mission_count(kind: String, by := 1) -> void:
	var all: Dictionary = (v("missions", {}) as Dictionary).duplicate(true)
	var changed := false
	for m in CampusData.MISSIONS:
		if str(m["kind"]) != kind or not mission_open(m):
			continue
		var id := str(m["id"])
		var st: Dictionary = all.get(id, {"n": 0, "done": false, "paid": false})
		if bool(st["done"]):
			continue
		st["n"] = int(st["n"]) + by
		if int(st["n"]) >= int(m["need"]):
			st["done"] = true
		all[id] = st
		changed = true
	if changed:
		put("missions", all)


static func mission_open(m: Dictionary) -> bool:
	return str(m.get("after", "")) == "" or chapter_done(str(m["after"]))


## Hand in a finished mission at the board: pays its merits once.
static func mission_claim(id: String) -> int:
	var all: Dictionary = (v("missions", {}) as Dictionary).duplicate(true)
	var st: Dictionary = all.get(id, {})
	if st.is_empty() or not bool(st.get("done", false)) or bool(st.get("paid", false)):
		return 0
	st["paid"] = true
	all[id] = st
	put("missions", all)
	for m in CampusData.MISSIONS:
		if str(m["id"]) == id:
			add_merits(int(m["merits"]), str(m["name"]))
			return int(m["merits"])
	return 0


# ------------------------------------------------------------------ duels on the island

## A duel against somebody on the island ended (not a story duel).
static func duel_result(won: bool, stars: int, their := "") -> void:
	put("wins" if won else "losses", int(v("wins" if won else "losses")) + 1)
	if won:
		add_merits(6 + 4 * clampi(stars, 1, 5), "Duel won")
		mission_count("win")
		cup_score(their, stars)
	else:
		add_merits(2, "Duel played")
	mission_count("duel")


# ------------------------------------------------------------------ trophies and scenes seen

static func trophy(id: String) -> void:
	var t: Array = (v("trophies", []) as Array).duplicate()
	if not t.has(id):
		t.append(id)
		put("trophies", t)


static func saw(id: String) -> void:
	var s: Array = (v("seen", []) as Array).duplicate()
	if not s.has(id):
		s.append(id)
		put("seen", s)


## One line for a save slot or the menu: "Red Dorm  ·  Day 3  ·  120 merits".
static func summary() -> String:
	if not started():
		return ""
	return "%s  ·  %s %d  ·  %d %s" % [Loc.t(DORM_NAMES[dorm()]), Loc.t("Day"), day(), merits(), Loc.t("merits")]
