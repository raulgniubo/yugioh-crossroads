class_name FieldThemes
extends RefCounted
## Duel field looks. "auto" picks the opponent's home field.

const ORDER := ["crossroads", "kaibacorp", "battlecity", "academy", "satellite", "heartland",
	"meadow", "volcano", "peak", "ruins", "tide", "shadow"]

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
	# Fields out in the world: the ground itself is the playmat. "surface" picks how it is
	# painted (see GROUND_GLSL), "day" lights the place like the open air.
	"meadow": {"name": "Windmill Meadow", "base": Color("13240f"), "accent": Color("fff4c2"), "accent2": Color("ffffff"),
		"pattern": 0, "sky_top": Color("2f7fd6"), "sky_horizon": Color("bfe3ff"), "fog": Color("cfe8ff"), "surface": 1, "day": true},
	"volcano": {"name": "Molten Caldera", "base": Color("120806"), "accent": Color("ff7a2a"), "accent2": Color("ffd23a"),
		"pattern": 0, "sky_top": Color("120404"), "sky_horizon": Color("7a1c0a"), "fog": Color("3a0f06"), "surface": 2},
	"peak": {"name": "Frozen Summit", "base": Color("1b2230"), "accent": Color("9fe8ff"), "accent2": Color("ffffff"),
		"pattern": 0, "sky_top": Color("3a6fc4"), "sky_horizon": Color("dcefff"), "fog": Color("e6f2ff"), "surface": 3, "day": true},
	"ruins": {"name": "Sunken Ruins", "base": Color("2a2012"), "accent": Color("ffe9a8"), "accent2": Color("7cf0e0"),
		"pattern": 0, "sky_top": Color("3a5fae"), "sky_horizon": Color("ffcf8a"), "fog": Color("f2c890"), "surface": 4, "day": true},
	"tide": {"name": "Coral Shallows", "base": Color("0a2a30"), "accent": Color("ffffff"), "accent2": Color("ffe48a"),
		"pattern": 0, "sky_top": Color("1f7fd0"), "sky_horizon": Color("b8f0ff"), "fog": Color("c8f4ff"), "surface": 5, "day": true},
	"shadow": {"name": "Shadow Realm", "base": Color("08030f"), "accent": Color("c06bff"), "accent2": Color("ff4d8a"),
		"pattern": 0, "sky_top": Color("030108"), "sky_horizon": Color("2a0b3c"), "fog": Color("1a0626"), "surface": 6},
}

## Painted ground for the open-air fields, shared by the playmat and the land around it.
## p is in meters on the table plane.
const GROUND_GLSL := """
float g_hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float g_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(g_hash(i), g_hash(i + vec2(1.0, 0.0)), f.x), mix(g_hash(i + vec2(0.0, 1.0)), g_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float g_fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) { s += a * g_noise(p); p *= 2.03; a *= 0.5; }
	return s;
}
vec2 g_voro(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float md = 8.0;
	float md2 = 8.0;
	float id = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = vec2(g_hash(n + g), g_hash(n + g + 31.7));
			float d = length(g + o - f);
			if (d < md) { md2 = md; md = d; id = g_hash(n + g + 7.3); } else if (d < md2) { md2 = d; }
		}
	}
	return vec2(md2 - md, id);
}
vec3 ground_color(vec2 p, int kind, float t) {
	if (kind == 1) {
		float n = g_fbm(p * 1.3);
		vec3 g = mix(vec3(0.09, 0.27, 0.07), vec3(0.25, 0.52, 0.13), n);
		g *= 0.84 + 0.32 * g_noise(p * vec2(38.0, 9.0));
		g *= 0.95 + 0.05 * step(0.5, fract(p.x * 0.42));
		vec2 fc = floor(p * 7.0);
		float fl = step(0.985, g_hash(fc)) * (1.0 - smoothstep(0.12, 0.3, length(fract(p * 7.0) - 0.5)));
		g = mix(g, mix(vec3(1.0, 0.95, 0.55), vec3(1.0, 0.62, 0.82), g_hash(fc + 3.0)), fl);
		float path = 1.0 - smoothstep(0.1, 0.34, abs(p.y) + (g_fbm(p * 2.0) - 0.5) * 0.3);
		return mix(g, vec3(0.44, 0.34, 0.2) * (0.8 + 0.4 * g_noise(p * 14.0)), path * 0.85);
	} else if (kind == 2) {
		vec2 v = g_voro(p * 0.85 + vec2(g_fbm(p * 0.7)) * 0.7);
		float crack = 1.0 - smoothstep(0.0, 0.085, v.x);
		vec3 rock = vec3(0.075, 0.058, 0.052) * (0.7 + 0.9 * g_fbm(p * 5.0)) + vec3(0.05, 0.02, 0.01) * v.y;
		float pulse = 0.62 + 0.38 * sin(t * 1.3 + v.y * 20.0 + p.x * 0.6);
		vec3 lava = mix(vec3(1.0, 0.24, 0.02), vec3(1.0, 0.78, 0.22), crack * crack) * pulse;
		return mix(rock, lava * 1.7, crack);
	} else if (kind == 3) {
		float n = g_fbm(p * 1.1 + 3.0);
		vec2 v = g_voro(p * 0.7);
		vec3 rock = mix(vec3(0.26, 0.28, 0.33), vec3(0.43, 0.45, 0.5), g_fbm(p * 4.0));
		rock *= 0.78 + 0.22 * smoothstep(0.0, 0.07, v.x);
		float snow = smoothstep(0.46, 0.6, n + 0.1 * g_noise(p * 9.0));
		return mix(rock, vec3(0.8, 0.87, 0.97) * (0.9 + 0.1 * g_noise(p * 20.0)), snow);
	} else if (kind == 4) {
		float ripple = 0.5 + 0.5 * sin(p.y * 9.0 + g_fbm(p * 1.2) * 7.0);
		vec3 sand = mix(vec3(0.7, 0.56, 0.34), vec3(0.87, 0.75, 0.5), ripple * 0.55 + 0.45 * g_fbm(p * 3.0));
		vec2 gq = abs(fract(p * 0.55) - 0.5);
		float seam = smoothstep(0.46, 0.5, max(gq.x, gq.y));
		float worn = smoothstep(0.35, 0.62, g_fbm(p * 0.9 + 9.0));
		vec3 stone = vec3(0.6, 0.53, 0.42) * (0.84 + 0.3 * g_noise(p * 12.0)) * (1.0 - 0.45 * seam);
		return mix(sand, stone, worn * 0.85);
	} else if (kind == 5) {
		vec3 sand = vec3(0.78, 0.7, 0.5) * (0.85 + 0.3 * g_fbm(p * 3.0));
		vec2 w = p * 1.4 + vec2(t * 0.12, t * 0.07);
		float c1 = g_voro(w + g_fbm(w) * 0.5).x;
		float c2 = g_voro(w * 1.7 - vec2(t * 0.1)).x;
		float caust = pow(1.0 - smoothstep(0.0, 0.22, c1), 2.0) + 0.6 * pow(1.0 - smoothstep(0.0, 0.2, c2), 2.0);
		vec3 water = mix(vec3(0.04, 0.4, 0.5), vec3(0.2, 0.72, 0.74), g_fbm(p * 0.8 + t * 0.05));
		return mix(sand, water, 0.7) + vec3(0.7, 0.95, 1.0) * caust * 0.3;
	}
	float n = g_fbm(p * 0.9 + vec2(t * 0.05, -t * 0.03));
	float n2 = g_fbm(p * 2.2 - vec2(t * 0.04));
	vec3 c = mix(vec3(0.03, 0.01, 0.06), vec3(0.22, 0.05, 0.32), smoothstep(0.35, 0.75, n));
	return c + vec3(0.5, 0.15, 0.7) * pow(smoothstep(0.55, 0.8, n2), 2.0) * 0.35;
}
"""

const HOME := {
	"yugi": "battlecity", "kaiba": "kaibacorp", "joey": "battlecity",
	"jaden": "academy", "yusei": "satellite", "yuma": "heartland",
}


static func resolve(choice: String, opponent: String) -> Dictionary:
	var key := choice
	if key == "auto" or not THEMES.has(key):
		key = HOME.get(opponent, "")
		if key == "":
			var era: String = Characters.DATA.get(opponent, {}).get("era", "")
			key = {"Duel Monsters": "battlecity", "GX": "academy", "5D's": "satellite", "ZEXAL": "heartland"}.get(era, "crossroads")
	var t: Dictionary = THEMES[key].duplicate()
	t["key"] = key
	return t
