class_name Goals
extends RefCounted
## Reasons to keep playing: your Duelist Rank, and goals for today and for this week.
## Everything is kept in Collection.record, so it saves with your cards.
##   record["rp"]      rank points
##   record["daily"]   {"day", "n": {kind: count}, "paid": {id: true}}   (counted by Collection.daily_bump)
##   record["weekly"]  {"week", "n": {kind: count}, "paid": {id: true}, "beat": {key: true}}

## [name, points needed, color, Duel Points for reaching it]
const RANKS := [
	["Rookie", 0, Color("9fb3c8"), 0],
	["Bronze", 150, Color("d98a4a"), 300],
	["Silver", 400, Color("cfd6e2"), 500],
	["Gold", 800, Color("ffd166"), 800],
	["Platinum", 1400, Color("7fe3d6"), 1200],
	["Diamond", 2200, Color("8ab8ff"), 1600],
	["Legend", 3200, Color("d48bff"), 2200],
	["King of Games", 4500, Color("ff5a7a"), 3000],
]

## Duel goals join the old daily list (Collection.DAILY), so a day can ask for a Synchro too.
const DAILY_DUEL := [
	{"k": "extra", "goal": 1, "name": "Today: big summon", "text": "Summon a Fusion, Synchro, Xyz or Ritual monster in a duel.", "reward": 120},
	{"k": "trap", "goal": 2, "name": "Today: springing traps", "text": "Activate 2 Trap cards in duels.", "reward": 100},
	{"k": "tribute", "goal": 2, "name": "Today: heavy hitters", "text": "Summon 2 monsters of Level 5 or higher.", "reward": 100},
	{"k": "direct", "goal": 3, "name": "Today: straight through", "text": "Attack your opponent directly 3 times.", "reward": 90},
	{"k": "flawless", "goal": 1, "name": "Today: untouchable", "text": "Win a duel without taking any damage.", "reward": 200},
	{"k": "turbo_win", "goal": 1, "name": "Today: full throttle", "text": "Win a Riding Duel.", "reward": 160},
]

const WEEKLY := [
	{"k": "win", "goal": 12, "name": "This week: on a roll", "text": "Win 12 duels this week.", "reward": 1000},
	{"k": "beat", "goal": 5, "name": "This week: new rivals", "text": "Beat 5 different duelists this week.", "reward": 1000},
	{"k": "extra", "goal": 10, "name": "This week: Extra Deck", "text": "Summon 10 Fusion, Synchro, Xyz or Ritual monsters this week.", "reward": 900},
	{"k": "turbo_win", "goal": 3, "name": "This week: speed king", "text": "Win 3 Riding Duels this week.", "reward": 900},
	{"k": "pack", "goal": 6, "name": "This week: collector", "text": "Open 6 booster packs this week.", "reward": 700},
	{"k": "flawless", "goal": 3, "name": "This week: no scratches", "text": "Win 3 duels without taking damage this week.", "reward": 1200},
	{"k": "trap", "goal": 10, "name": "This week: trap master", "text": "Activate 10 Trap cards this week.", "reward": 700},
	{"k": "daily_done", "goal": 8, "name": "This week: every day counts", "text": "Finish 8 daily goals this week.", "reward": 1200},
]


# ------------------------------------------------------------------ rank

static func points() -> int:
	return int(Collection.record.get("rp", 0))


static func tier(rp := -1) -> int:
	if rp < 0:
		rp = points()
	var t := 0
	for i in RANKS.size():
		if rp >= int(RANKS[i][1]):
			t = i
	return t


static func rank_name(t := -1) -> String:
	return Loc.t(str(RANKS[tier() if t < 0 else t][0]))


static func rank_color(t := -1) -> Color:
	return RANKS[tier() if t < 0 else t][2]


## 0..1 of the way to the next rank (1 at the top).
static func progress() -> float:
	var t := tier()
	if t >= RANKS.size() - 1:
		return 1.0
	var a := int(RANKS[t][1])
	var b := int(RANKS[t + 1][1])
	return clampf(float(points() - a) / float(b - a), 0.0, 1.0)


static func to_next() -> int:
	var t := tier()
	if t >= RANKS.size() - 1:
		return 0
	return int(RANKS[t + 1][1]) - points()


## Points for one duel. A win pays more against a harder opponent; a loss costs a little, but
## you never drop out of a rank you reached.
static func duel_points(won: bool, difficulty: int, flawless: bool, streak: int) -> int:
	if won:
		return 20 + 10 * clampi(difficulty, 0, 3) + (10 if flawless else 0) + 5 * clampi(streak - 1, 0, 4)
	return -(4 + 4 * clampi(difficulty, 0, 3))


## Moves the points and returns reward lines [[text, dp]] (the rank-up pays).
static func apply_points(delta: int) -> Array:
	var before := points()
	var t0 := tier(before)
	var after := maxi(int(RANKS[t0][1]), before + delta)
	Collection.record["rp"] = after
	var out := []
	if delta > 0:
		out.append([Loc.t("Rank points +%d  (%s)") % [delta, rank_name(tier(after))], 0])
	var t1 := tier(after)
	for t in range(t0 + 1, t1 + 1):
		out.append([Loc.t("Rank up: %s!") % rank_name(t), int(RANKS[t][3])])
	return out


# ------------------------------------------------------------------ days and weeks

static func week_key() -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var now := int(Time.get_unix_time_from_system()) + bias
	# 1 Jan 1970 was a Thursday: shift so weeks start on Monday.
	return "w%d" % int((now + 3 * 86400) / 604800)


## Seconds until the next week starts (local time).
static func week_left() -> int:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var now := int(Time.get_unix_time_from_system()) + bias
	return 604800 - ((now + 3 * 86400) % 604800)


static func day_left() -> int:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var now := int(Time.get_unix_time_from_system()) + bias
	return 86400 - (now % 86400)


static func _weekly() -> Dictionary:
	var key := week_key()
	var w: Dictionary = Collection.record.get("weekly", {})
	if str(w.get("week", "")) != key:
		w = {"week": key, "n": {}, "paid": {}, "beat": {}}
		Collection.record["weekly"] = w
	return w


## Counts toward this week's goals. Collection.daily_bump calls this, so every daily count
## also counts for the week.
static func week_bump(kind: String, n := 1) -> void:
	var w := _weekly()
	var c: Dictionary = w.get("n", {})
	c[kind] = int(c.get(kind, 0)) + n
	w["n"] = c


## A win over someone: new rivals this week are counted once each.
static func beat(key: String) -> void:
	if key == "":
		return
	var w := _weekly()
	var b: Dictionary = w.get("beat", {})
	if not b.has(key):
		b[key] = true
		w["beat"] = b
		week_bump("beat")


static func weekly_rows() -> Array:
	var w := _weekly()
	var n: Dictionary = w.get("n", {})
	var paid: Dictionary = w.get("paid", {})
	var out := []
	var start := absi(hash(str(w["week"]))) % WEEKLY.size()
	for i in 3:
		var t: Dictionary = WEEKLY[(start + i * 3) % WEEKLY.size()]
		var id := "weekly_%s_%s" % [w["week"], t["k"]]
		out.append({"id": id, "name": t["name"], "text": t["text"], "have": mini(int(t["goal"]), int(n.get(t["k"], 0))),
			"goal": t["goal"], "reward": t["reward"], "done": paid.has(id)})
	return out


static func daily_rows() -> Array:
	var rows: Array = Collection.daily_rows()
	var d: Dictionary = Collection.record.get("daily", {})
	var paid: Dictionary = d.get("paid", {})
	for r in rows:
		r["done"] = paid.has(r["id"])
	return rows


## Pays every daily and weekly goal that is finished and not paid yet. Returns [[text, dp]];
## the Duel Points are already added.
static func pay_due() -> Array:
	var out := []
	var rows := daily_rows()
	var d: Dictionary = Collection.record.get("daily", {})
	var dpaid: Dictionary = d.get("paid", {})
	for r in rows:
		if not r["done"] and int(r["have"]) >= int(r["goal"]):
			dpaid[r["id"]] = true
			out.append([Loc.t("Goal: %s") % Loc.t(str(r["name"])), int(r["reward"])])
			week_bump("daily_done")
	d["paid"] = dpaid
	Collection.record["daily"] = d
	var w := _weekly()
	var wpaid: Dictionary = w.get("paid", {})
	for r in weekly_rows():
		if not r["done"] and int(r["have"]) >= int(r["goal"]):
			wpaid[r["id"]] = true
			out.append([Loc.t("Goal: %s") % Loc.t(str(r["name"])), int(r["reward"])])
	w["paid"] = wpaid
	for line in out:
		Collection.dp += int(line[1])
	if not out.is_empty():
		Collection.save()
	return out


## How many goals are finished and waiting (the main menu shows a dot).
static func open_count() -> int:
	var n := 0
	for r in daily_rows() + weekly_rows():
		if not r["done"]:
			n += 1
	return n


## After a duel: the counts it made, the rank points, and any goals it finished.
## tally: {"extra": n, "trap": n, "tribute": n, "direct": n}. Returns [[text, dp]], already paid.
static func after_duel(won: bool, difficulty: int, info: Dictionary, tally: Dictionary) -> Array:
	for k in tally:
		if int(tally[k]) > 0:
			for i in int(tally[k]):
				Collection.daily_bump(str(k))
	if won:
		if info.get("flawless", false):
			Collection.daily_bump("flawless")
		if info.get("turbo", false):
			Collection.daily_bump("turbo_win")
		beat(str(info.get("opponent", "")))
	var pts := 0 if info.get("draw", false) else duel_points(won, difficulty, bool(info.get("flawless", false)), int(Collection.record.get("streak", 0)))
	var out := apply_points(pts)
	var got := 0
	for line in out:
		got += int(line[1])
	Collection.dp += got
	out.append_array(pay_due())
	out.append_array(pay_album())
	Collection.save()
	return out


# ------------------------------------------------------------------ collection goals

## Owning a share of a pack's cards pays once at each step.
const ALBUM_STEPS := [[0.25, 200], [0.5, 400], [0.75, 700], [1.0, 1500]]


## One row per pack: {key, name, color, have, total, step (0..4 steps paid), next_at, next_dp}
static func album_rows() -> Array:
	var out := []
	var paid: Dictionary = Collection.record.get("album", {})
	for p in Collection.PACKS:
		var key := str(p["key"])
		if key == "echo":
			continue
		var pool: Array = Collection.pool(key)
		if pool.is_empty():
			continue
		var have := 0
		for id in pool:
			if int(Collection.owned.get(int(id), 0)) > 0:
				have += 1
		var step := int(paid.get(key, 0))
		var row := {"key": key, "name": str(p["name"]), "color": p["color"], "have": have, "total": pool.size(), "step": step,
			"next_at": 0, "next_dp": 0}
		if step < ALBUM_STEPS.size():
			row["next_at"] = int(ceil(float(ALBUM_STEPS[step][0]) * pool.size()))
			row["next_dp"] = int(ALBUM_STEPS[step][1])
		out.append(row)
	return out


## Pays every collection step reached and not paid yet. Returns [[text, dp]], already paid.
static func pay_album() -> Array:
	var out := []
	var paid: Dictionary = Collection.record.get("album", {})
	for r in album_rows():
		var step := int(r["step"])
		while step < ALBUM_STEPS.size() and int(r["have"]) >= int(ceil(float(ALBUM_STEPS[step][0]) * int(r["total"]))):
			out.append([Loc.t("%s: %d%% collected") % [Loc.t(str(r["name"])), int(float(ALBUM_STEPS[step][0]) * 100.0)], int(ALBUM_STEPS[step][1])])
			step += 1
		paid[r["key"]] = step
	Collection.record["album"] = paid
	for line in out:
		Collection.dp += int(line[1])
	if not out.is_empty():
		Collection.save()
	return out
