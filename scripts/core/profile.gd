extends Node
## The player's duelist profile. Saved to user://profile.cfg.

signal changed

const PATH := "user://profile.cfg"
const COLORS: Array[Color] = [
	Color("2de2e6"), Color("3a86ff"), Color("7b5cff"), Color("ff4d6d"), Color("ff9f1c"), Color("4fd18b"),
	Color("ff6ec7"), Color("ffd23a"), Color("b8f24a"), Color("59c8ff"), Color("d946ef"), Color("ff7a59"),
]
const COLOR_NAMES := ["Teal", "Blue", "Violet", "Crimson", "Orange", "Green", "Pink", "Gold", "Lime", "Sky", "Magenta", "Coral"]
const HEIGHTS := [["Short", 0.94], ["Average", 1.0], ["Tall", 1.06]]
## Titles under your name. Each is [text, what unlocks it]; "" is open from the start.
const TITLES := [["", ""], ["Rookie Duelist", ""], ["Card Collector", ""], ["Street Duelist", ""], ["Echo Bearer", "story:ch1"],
	["Friend of Slifer Red", "story:ch2"], ["Highway Rider", "story:ch3"], ["Street Champion", "title:domino"],
	["Dorm Cup Winner", "title:academy"], ["Grand Prix Winner", "title:turbo"], ["Crossroads Champion", "title:cup"]]
## What you say when a duel starts and when you win it.
const INTROS := ["", "Let's do this.", "I won't hold back.", "It's time to duel!", "Show me what you've got.", "I've been waiting for this.",
	"Don't blink.", "My deck has no pathetic cards.", "Let's make this one to remember."]
const WINS := ["", "Yes! I won!", "That's how it's done!", "Good duel.", "Believe in your deck.", "Too easy.", "That was close. Again some time?",
	"And that's game.", "My cards came through."]
const EMBLEMS := ["Star", "Wing", "Blade", "Crown"]
const GENDERS := ["He", "She", "They"]

var created := false
var duelist_name := "Duelist"
var gender := 0
var color_index := 0
var emblem := 0
var tints := {"hair": Color.WHITE, "outfit": Color.WHITE, "eyes": Color.WHITE}
## Built-in hero look: body 0/1, hair 0/1, outfit 0..2 (see HERO_* below).
const HERO_BODIES := ["A", "B"]
const HERO_HAIR := [["Silver Spikes", "Navy Bangs"], ["Silver Ponytail", "Navy Bob"]]
const HERO_OUTFITS := ["Street Duelist", "Academy Blazer", "Turbo Rider"]
var look_body := 0
var look_hair := 0
var look_outfit := 0
var look_height := 1
var title := 0
var intro := 0
var win_line := 0
var wins := 0
var losses := 0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	created = cfg.get_value("profile", "created", false)
	duelist_name = cfg.get_value("profile", "name", duelist_name)
	gender = cfg.get_value("profile", "gender", gender)
	color_index = cfg.get_value("profile", "color", color_index)
	emblem = cfg.get_value("profile", "emblem", emblem)
	tints = cfg.get_value("profile", "tints", tints)
	look_body = clampi(cfg.get_value("look", "body", 1 if gender == 1 else 0), 0, 1)
	look_hair = clampi(cfg.get_value("look", "hair", 0), 0, 1)
	look_outfit = clampi(cfg.get_value("look", "outfit", 0), 0, 2)
	look_height = clampi(cfg.get_value("look", "height", 1), 0, HEIGHTS.size() - 1)
	title = clampi(cfg.get_value("profile", "title", 0), 0, TITLES.size() - 1)
	intro = clampi(cfg.get_value("profile", "intro", 0), 0, INTROS.size() - 1)
	win_line = clampi(cfg.get_value("profile", "win_line", 0), 0, WINS.size() - 1)
	wins = cfg.get_value("stats", "wins", 0)
	losses = cfg.get_value("stats", "losses", 0)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "created", created)
	cfg.set_value("profile", "name", duelist_name)
	cfg.set_value("profile", "gender", gender)
	cfg.set_value("profile", "color", color_index)
	cfg.set_value("profile", "emblem", emblem)
	cfg.set_value("profile", "tints", tints)
	cfg.set_value("look", "body", look_body)
	cfg.set_value("look", "hair", look_hair)
	cfg.set_value("look", "outfit", look_outfit)
	cfg.set_value("look", "height", look_height)
	cfg.set_value("profile", "title", title)
	cfg.set_value("profile", "intro", intro)
	cfg.set_value("profile", "win_line", win_line)
	cfg.set_value("stats", "wins", wins)
	cfg.set_value("stats", "losses", losses)
	cfg.save(PATH)
	changed.emit()


## The bundled hero model that matches the chosen look.
func hero_key() -> String:
	return "hero_%s%d_%s" % [["m", "f"][look_body], look_hair + 1, ["street", "academy", "rider"][look_outfit]]


func height() -> float:
	return float(HEIGHTS[clampi(look_height, 0, HEIGHTS.size() - 1)][1])


## Has this title been earned? "" always, "story:<chapter>" once that chapter is open or done,
## "title:<tournament>" once you hold it.
func title_open(i: int) -> bool:
	var need := str(TITLES[clampi(i, 0, TITLES.size() - 1)][1])
	if need == "":
		return true
	if need.begins_with("story:"):
		var order := ["prologue", "ch1", "ch2", "ch3", "ch4", "ch5"]
		var at := order.find(need.trim_prefix("story:"))
		for k in range(at + 1, order.size()):
			if StoryProgress.unlocked().has(order[k]):
				return true
		return false
	Tournament.load_data()
	return Tournament.DEFS.has(need.trim_prefix("title:")) and Tournament.titles(need.trim_prefix("title:")) > 0


## The line under your name: the title you picked, or your level.
func title_text() -> String:
	if title > 0 and title < TITLES.size() and title_open(title):
		return Loc.t(str(TITLES[title][0]))
	return Loc.t("Duelist Lv %d") % level()


func color() -> Color:
	return COLORS[clampi(color_index, 0, COLORS.size() - 1)]


func level() -> int:
	return 1 + wins / 3


func record_result(won: bool) -> void:
	if won:
		wins += 1
	else:
		losses += 1
	save()
