class_name WorldClock
extends RefCounted
## One clock for every world. Time passes while you walk around (a full day in about 25
## minutes of play), every duel costs an hour, and you can sit down and wait. The look of the
## sky follows it smoothly: night, dawn, day, sunset, night. Weather follows it too: each world
## has its own habits, and a shower starts and ends by the clock instead of lasting a whole visit.
## The clock is part of the save (roam.cfg).

const PATH := "user://roam.cfg"
const DAY := 1440.0
const REAL_DAY := 25.0 * 60.0        # seconds of walking around for one full day
const DUEL_COST := 60.0              # game minutes a duel takes

## The sky's key frames through the day: [minute, look]. Between two different looks it blends.
const KEYS := [[0.0, "night"], [300.0, "night"], [390.0, "dawn"], [500.0, "day"], [1010.0, "day"], [1100.0, "sunset"], [1215.0, "night"], [1440.0, "night"]]
## Times you can wait for, by name.
const WAIT := {"morning": 450.0, "midday": 720.0, "evening": 1100.0, "night": 1290.0}
const WAIT_NAMES := {"morning": "Morning", "midday": "Midday", "evening": "Evening", "night": "Night"}
## Where a story scene that asks for a look puts the clock.
const LOOK_AT := {"dawn": 420.0, "day": 660.0, "sunset": 1100.0, "night": 1290.0}
## How often it rains, per world, out of 100 blocks of an hour and a half. Satellite gets dust.
const RAIN := {"domino": 22, "academy": 30, "newdomino": 18, "satellite": 14, "heartland": 9, "highway": 12, "museum": 0}
const BLOCK := 90.0

static var minutes := 9.0 * 60.0
static var day := 1
static var _loaded := false


static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		minutes = clampf(float(cfg.get_value("clock", "minutes", minutes)), 0.0, DAY - 0.01)
		day = maxi(1, int(cfg.get_value("clock", "day", day)))


static func save_data() -> void:
	load_data()
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("clock", "minutes", minutes)
	cfg.set_value("clock", "day", day)
	cfg.save(PATH)


## A save was swapped in or a new game began: read the clock again.
static func reload() -> void:
	_loaded = false
	minutes = 9.0 * 60.0
	day = 1
	load_data()


## Real seconds of walking around.
static func advance(real_seconds: float) -> void:
	add_minutes(real_seconds * DAY / REAL_DAY)


static func add_minutes(m: float) -> void:
	load_data()
	minutes += maxf(0.0, m)
	while minutes >= DAY:
		minutes -= DAY
		day += 1


## Jump forward to a time of day (never backward: an earlier time is tomorrow's).
static func go_to(minute: float) -> void:
	load_data()
	if minute <= minutes + 0.5:
		day += 1
	minutes = clampf(minute, 0.0, DAY - 0.01)


static func wait_until(name: String) -> void:
	go_to(float(WAIT.get(name, 720.0)))
	save_data()


## A story scene pins the look it was written for.
static func set_look(look: String) -> void:
	load_data()
	var m := float(LOOK_AT.get(look, 660.0))
	if absf(m - minutes) > 1.0:
		if m < minutes:
			day += 1
		minutes = m


static func hour() -> int:
	load_data()
	return int(minutes / 60.0)


static func text() -> String:
	load_data()
	return "%02d:%02d" % [int(minutes / 60.0), int(minutes) % 60]


## What part of the day it is, in words.
static func part() -> String:
	load_data()
	var h := minutes / 60.0
	if h < 5.0 or h >= 21.0:
		return "Night"
	if h < 8.5:
		return "Morning"
	if h < 12.0:
		return "Late morning"
	if h < 17.0:
		return "Afternoon"
	return "Evening"


## The two looks the sky is between, and how far along: [from, to, 0..1].
static func mix() -> Array:
	load_data()
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if minutes >= float(a[0]) and minutes < float(b[0]):
			if str(a[1]) == str(b[1]):
				return [a[1], b[1], 0.0]
			return [a[1], b[1], (minutes - float(a[0])) / (float(b[0]) - float(a[0]))]
	return ["night", "night", 0.0]


## The named look it is closest to right now: night | dawn | day | sunset.
static func look() -> String:
	var m := mix()
	return str(m[1]) if float(m[2]) >= 0.5 else str(m[0])


## Is it raining in this world right now? Weather comes in blocks of an hour and a half.
static func rains(district: String) -> bool:
	load_data()
	var chance := int(RAIN.get(district, 15))
	if chance <= 0:
		return false
	var block := int((float(day) * DAY + minutes) / BLOCK)
	return absi(hash("%s:%d" % [district, block])) % 100 < chance
