class_name FieldThemes
extends RefCounted
## Duel field looks. "auto" picks the opponent's home field.

const ORDER := ["crossroads", "kaibacorp", "battlecity", "academy", "satellite", "heartland"]

const THEMES := {
	"crossroads": {"name": "Crossroads", "base": Color("050a14"), "accent": Color("2de2e6"), "accent2": Color("7b5cff"),
		"pattern": 0, "sky_top": Color("02050c"), "sky_horizon": Color("0f2b44"), "fog": Color("0a1a2c")},
	"kaibacorp": {"name": "Kaiba Corp Dome", "base": Color("06101f"), "accent": Color("7cc4ff"), "accent2": Color("e6f4ff"),
		"pattern": 1, "sky_top": Color("030a1c"), "sky_horizon": Color("1b4d96"), "fog": Color("0c2244")},
	"battlecity": {"name": "Battle City Rooftop", "base": Color("0f0a18"), "accent": Color("c08cff"), "accent2": Color("ffcf5a"),
		"pattern": 3, "sky_top": Color("0a0618"), "sky_horizon": Color("5a2a6a"), "fog": Color("24123a")},
	"academy": {"name": "Duel Academy Arena", "base": Color("170809"), "accent": Color("ff4d5e"), "accent2": Color("ffd166"),
		"pattern": 4, "sky_top": Color("120406"), "sky_horizon": Color("6a1f22"), "fog": Color("2c0c0e")},
	"satellite": {"name": "Satellite Junkyard", "base": Color("0d0b09"), "accent": Color("ff8a3a"), "accent2": Color("2de2e6"),
		"pattern": 2, "sky_top": Color("0a0705"), "sky_horizon": Color("5c3418"), "fog": Color("26170c")},
	"heartland": {"name": "Heartland Tower", "base": Color("120d04"), "accent": Color("ffd23a"), "accent2": Color("ff5ab4"),
		"pattern": 1, "sky_top": Color("0e0614"), "sky_horizon": Color("7a3a5c"), "fog": Color("2a1420")},
}

const HOME := {
	"yugi": "battlecity", "kaiba": "kaibacorp", "joey": "battlecity",
	"jaden": "academy", "yusei": "satellite", "yuma": "heartland",
}


static func resolve(choice: String, opponent: String) -> Dictionary:
	var key := choice
	if key == "auto" or not THEMES.has(key):
		key = HOME.get(opponent, "crossroads")
	var t: Dictionary = THEMES[key].duplicate()
	t["key"] = key
	return t
