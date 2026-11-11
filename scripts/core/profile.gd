extends Node
## The player's duelist profile. Saved to user://profile.cfg.

signal changed

const PATH := "user://profile.cfg"
const COLORS: Array[Color] = [
	Color("2de2e6"), Color("3a86ff"), Color("7b5cff"), Color("ff4d6d"), Color("ff9f1c"), Color("4fd18b"),
]
const EMBLEMS := ["Star", "Wing", "Blade", "Crown"]
const GENDERS := ["He", "She", "They"]

var created := false
var duelist_name := "Duelist"
var gender := 0
var color_index := 0
var emblem := 0
var tints := {"hair": Color.WHITE, "outfit": Color.WHITE, "eyes": Color.WHITE}
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
	cfg.set_value("stats", "wins", wins)
	cfg.set_value("stats", "losses", losses)
	cfg.save(PATH)
	changed.emit()


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
