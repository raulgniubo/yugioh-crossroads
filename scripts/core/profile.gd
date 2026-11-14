extends Node
## The player's duelist profile. Saved to user://profile.cfg.

signal changed

const PATH := "user://profile.cfg"
const COLORS: Array[Color] = [
	Color("2de2e6"), Color("3a86ff"), Color("7b5cff"), Color("ff4d6d"), Color("ff9f1c"), Color("4fd18b"),
	Color("ff6ec7"), Color("ffd23a"), Color("b8f24a"), Color("59c8ff"), Color("d946ef"), Color("ff7a59"),
]
const COLOR_NAMES := ["Teal", "Blue", "Violet", "Crimson", "Orange", "Green", "Pink", "Gold", "Lime", "Sky", "Magenta", "Coral"]
const HEIGHTS := HeroLook.HEIGHTS
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
## Built-in hero look. The lists of what there is to pick from live in HeroLook.
var look_body := 0            # 0 body A, 1 body B
var look_hair := 0            # which hairstyle (HeroLook.HAIRS)
var look_outfit := 0          # which outfit (HeroLook.OUTFITS)
var look_height := 2          # HeroLook.HEIGHTS
var look_build := 1           # HeroLook.BUILDS: 0 Kid, 1 Teen, 2 Grown-up
var look_skin := 0            # the colors: 0 keeps what the model was painted with
var look_haircol := 0
var look_eyes := 0
var look_top := 0
var look_bottom := 0
var look_shoes := 0
var title := 0
var intro := 0
var win_line := 0
var wins := 0
var losses := 0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		_dev_look()
		return
	created = cfg.get_value("profile", "created", false)
	duelist_name = cfg.get_value("profile", "name", duelist_name)
	gender = cfg.get_value("profile", "gender", gender)
	color_index = cfg.get_value("profile", "color", color_index)
	emblem = cfg.get_value("profile", "emblem", emblem)
	tints = cfg.get_value("profile", "tints", tints)
	look_body = clampi(cfg.get_value("look", "body", 1 if gender == 1 else 0), 0, 1)
	look_hair = clampi(cfg.get_value("look", "hair", 0), 0, 3)
	look_outfit = clampi(cfg.get_value("look", "outfit", 0), 0, HeroLook.OUTFITS.size() - 1)
	if cfg.has_section_key("look", "height5"):
		look_height = clampi(cfg.get_value("look", "height5", 2), 0, HEIGHTS.size() - 1)
	else:
		# Saved before 0.29, when there were three heights.
		look_height = [1, 2, 3][clampi(cfg.get_value("look", "height", 1), 0, 2)]
	look_build = clampi(cfg.get_value("look", "build", 1), 0, HeroLook.BUILDS.size() - 1)
	look_skin = clampi(cfg.get_value("look", "skin", 0), 0, HeroLook.SKIN.size() - 1)
	look_haircol = clampi(cfg.get_value("look", "haircol", 0), 0, HeroLook.HAIR.size() - 1)
	look_eyes = clampi(cfg.get_value("look", "eyes", 0), 0, HeroLook.EYES.size() - 1)
	look_top = clampi(cfg.get_value("look", "top", 0), 0, HeroLook.CLOTH.size() - 1)
	look_bottom = clampi(cfg.get_value("look", "bottom", 0), 0, HeroLook.CLOTH.size() - 1)
	look_shoes = clampi(cfg.get_value("look", "shoes", 0), 0, HeroLook.CLOTH.size() - 1)
	title = clampi(cfg.get_value("profile", "title", 0), 0, TITLES.size() - 1)
	intro = clampi(cfg.get_value("profile", "intro", 0), 0, INTROS.size() - 1)
	win_line = clampi(cfg.get_value("profile", "win_line", 0), 0, WINS.size() - 1)
	wins = cfg.get_value("stats", "wins", 0)
	losses = cfg.get_value("stats", "losses", 0)
	_dev_look()


## Dev: --look=body,hair,outfit,build,height,skin,haircol,eyes,top,bottom,shoes,color sets the look for a screenshot.
func _dev_look() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--look="):
			var v := a.trim_prefix("--look=").split(",")
			var names := ["look_body", "look_hair", "look_outfit", "look_build", "look_height", "look_skin", "look_haircol", "look_eyes",
				"look_top", "look_bottom", "look_shoes", "color_index"]
			for i in mini(v.size(), names.size()):
				set(names[i], int(v[i]))
			gender = look_body


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
	cfg.set_value("look", "height5", look_height)
	cfg.set_value("look", "build", look_build)
	cfg.set_value("look", "skin", look_skin)
	cfg.set_value("look", "haircol", look_haircol)
	cfg.set_value("look", "eyes", look_eyes)
	cfg.set_value("look", "top", look_top)
	cfg.set_value("look", "bottom", look_bottom)
	cfg.set_value("look", "shoes", look_shoes)
	cfg.set_value("profile", "title", title)
	cfg.set_value("profile", "intro", intro)
	cfg.set_value("profile", "win_line", win_line)
	cfg.set_value("stats", "wins", wins)
	cfg.set_value("stats", "losses", losses)
	cfg.save(PATH)
	changed.emit()


## The bundled hero model that carries the chosen outfit (and, when it has it, the hairstyle).
func hero_key() -> String:
	return str(HeroLook.models(look_body, look_hair, look_outfit)["body"])


## Everything about the look that changes the model on screen, as one string.
func look_sig() -> String:
	return str([look_body, look_hair, look_outfit, look_height, look_build, look_skin, look_haircol, look_eyes,
			look_top, look_bottom, look_shoes, color_index])


func height() -> float:
	return float(HEIGHTS[clampi(look_height, 0, HEIGHTS.size() - 1)][1])


## Has this title been earned? "" always, "story:<chapter>" once that chapter is open or done,
## "title:<tournament>" once you hold it.
func title_open(i: int) -> bool:
	var need := str(TITLES[clampi(i, 0, TITLES.size() - 1)][1])
	if need == "" or Saves.admin:
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
