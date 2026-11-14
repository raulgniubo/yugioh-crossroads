class_name FieldThemes
extends RefCounted
## Duel field looks. "auto" picks the opponent's home field.

const ORDER := ["crossroads", "kaibacorp", "battlecity", "pier", "academy", "reddorm", "bluehall", "satellite", "highway", "heartland",
	"meadow", "volcano", "peak", "ruins", "tide", "shadow"]

## Every field is a place. "surface" picks how its ground is painted (see GROUND_GLSL; the mat
## and the land around it share it), "day" lights it like the open air.
const THEMES := {
	"crossroads": {"name": "Crossroads", "base": Color("050a14"), "accent": Color("2de2e6"), "accent2": Color("7b5cff"),
		"pattern": 0, "sky_top": Color("02050c"), "sky_horizon": Color("0f2b44"), "fog": Color("0a1a2c"), "surface": 7,
		"blurb": "A stone plaza adrift between the four eras."},
	"kaibacorp": {"name": "Kaiba Corp Dome", "base": Color("06101f"), "accent": Color("7cc4ff"), "accent2": Color("e6f4ff"),
		"pattern": 1, "sky_top": Color("030a1c"), "sky_horizon": Color("1b4d96"), "fog": Color("0c2244"), "surface": 8,
		"blurb": "A steel arena floor under stadium lights and a full house."},
	"battlecity": {"name": "Battle City Rooftop", "base": Color("0f0a18"), "accent": Color("c08cff"), "accent2": Color("ffcf5a"),
		"pattern": 3, "sky_top": Color("0a0618"), "sky_horizon": Color("5a2a6a"), "fog": Color("24123a"), "surface": 9,
		"blurb": "Wet concrete high over the city at night."},
	"pier": {"name": "Domino Pier", "base": Color("2a1c10"), "accent": Color("ffd9a0"), "accent2": Color("ffffff"),
		"pattern": 0, "sky_top": Color("3a4a8c"), "sky_horizon": Color("ffab6a"), "fog": Color("f0b488"), "surface": 16, "day": true,
		"blurb": "Old planks over the harbor at sunset."},
	"academy": {"name": "Duel Academy Arena", "base": Color("170809"), "accent": Color("ff4d5e"), "accent2": Color("ffd166"),
		"pattern": 4, "sky_top": Color("120406"), "sky_horizon": Color("6a1f22"), "fog": Color("2c0c0e"), "surface": 10,
		"blurb": "The school's duel hall: a varnished court ringed in dorm colors."},
	"reddorm": {"name": "Red Dorm Cliff", "base": Color("1c2410"), "accent": Color("ffe9c2"), "accent2": Color("ffffff"),
		"pattern": 0, "sky_top": Color("36458c"), "sky_horizon": Color("ff9d5c"), "fog": Color("f2b890"), "surface": 13, "day": true,
		"blurb": "A worn lawn on the cliff by the red dorm, the sea below."},
	"bluehall": {"dark_paint": true, "name": "Blue Dorm Hall", "base": Color("0c1424"), "accent": Color("9cc8ff"), "accent2": Color("ffd98a"),
		"pattern": 1, "sky_top": Color("060b18"), "sky_horizon": Color("24406e"), "fog": Color("16264a"), "surface": 14,
		"blurb": "Marble, gold and blue banners under a chandelier."},
	"satellite": {"name": "Satellite Junkyard", "base": Color("0d0b09"), "accent": Color("ff8a3a"), "accent2": Color("2de2e6"),
		"pattern": 2, "sky_top": Color("0a0705"), "sky_horizon": Color("5c3418"), "fog": Color("26170c"), "surface": 11,
		"blurb": "Cracked asphalt, rust and scrap heaps."},
	"highway": {"name": "Night Highway", "base": Color("08090c"), "accent": Color("ffd23a"), "accent2": Color("7cc4ff"),
		"pattern": 2, "sky_top": Color("04060e"), "sky_horizon": Color("1c3a6a"), "fog": Color("0e1a30"), "surface": 15,
		"blurb": "A closed stretch of overpass with the city glowing below."},
	"heartland": {"dark_paint": true, "name": "Heartland Tower", "base": Color("120d04"), "accent": Color("ffd23a"), "accent2": Color("ff5ab4"),
		"pattern": 1, "sky_top": Color("0e0614"), "sky_horizon": Color("7a3a5c"), "fog": Color("2a1420"), "surface": 12,
		"blurb": "A bright plaza of glowing tiles in the city of the future."},
	# Fields out in the world: the ground itself is the playmat. "surface" picks how it is
	# painted (see GROUND_GLSL), "day" lights the place like the open air.
	"meadow": {"name": "Windmill Meadow", "base": Color("13240f"), "accent": Color("fff4c2"), "accent2": Color("ffffff"),
		"pattern": 0, "sky_top": Color("2f7fd6"), "sky_horizon": Color("bfe3ff"), "fog": Color("cfe8ff"), "surface": 1, "day": true, "blurb": "Grass, a dirt path and a windmill on the hill."},
	"volcano": {"name": "Molten Caldera", "base": Color("120806"), "accent": Color("ff7a2a"), "accent2": Color("ffd23a"),
		"pattern": 0, "sky_top": Color("120404"), "sky_horizon": Color("7a1c0a"), "fog": Color("3a0f06"), "surface": 2, "blurb": "Black rock split by glowing lava."},
	"peak": {"dark_paint": true, "name": "Frozen Summit", "base": Color("1b2230"), "accent": Color("9fe8ff"), "accent2": Color("ffffff"),
		"pattern": 0, "sky_top": Color("3a6fc4"), "sky_horizon": Color("dcefff"), "fog": Color("e6f2ff"), "surface": 3, "day": true, "blurb": "Snow and bare rock above the clouds."},
	"ruins": {"name": "Sunken Ruins", "base": Color("2a2012"), "accent": Color("ffe9a8"), "accent2": Color("7cf0e0"),
		"pattern": 0, "sky_top": Color("3a5fae"), "sky_horizon": Color("ffcf8a"), "fog": Color("f2c890"), "surface": 4, "day": true, "blurb": "Sand drifting over ancient paving."},
	"tide": {"name": "Coral Shallows", "base": Color("0a2a30"), "accent": Color("ffffff"), "accent2": Color("ffe48a"),
		"pattern": 0, "sky_top": Color("1f7fd0"), "sky_horizon": Color("b8f0ff"), "fog": Color("c8f4ff"), "surface": 5, "day": true, "blurb": "Ankle-deep water over white sand."},
	"shadow": {"name": "Shadow Realm", "base": Color("08030f"), "accent": Color("c06bff"), "accent2": Color("ff4d8a"),
		"pattern": 0, "sky_top": Color("030108"), "sky_horizon": Color("2a0b3c"), "fog": Color("1a0626"), "surface": 6, "blurb": "Purple mist where the ground should be."},
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
	if (kind == 7) {
		// Crossroads: big stone slabs, a few seams lit from below.
		vec2 q = p * 0.5;
		vec2 f = abs(fract(q) - 0.5);
		float seam = smoothstep(0.465, 0.5, max(f.x, f.y));
		vec3 st = mix(vec3(0.15, 0.17, 0.22), vec3(0.24, 0.26, 0.32), g_hash(floor(q))) * (0.82 + 0.34 * g_fbm(p * 3.0));
		st *= 1.0 - 0.55 * seam;
		float lit = seam * step(0.6, g_hash(floor(q * 0.5) + 5.0)) * (0.6 + 0.4 * sin(t * 0.8 + q.x + q.y));
		return st + vec3(0.1, 0.75, 0.8) * lit * 0.55;
	} else if (kind == 8) {
		// Dome: brushed steel panels with glowing seams and hazard stripes at the ends.
		vec2 q = p * 0.8;
		vec2 f = abs(fract(q) - 0.5);
		float seam = smoothstep(0.47, 0.5, max(f.x, f.y));
		vec3 metal = vec3(0.075, 0.105, 0.165) * (0.8 + 0.5 * g_noise(vec2(p.x * 30.0, p.y * 2.0))) + vec3(0.02, 0.035, 0.07) * g_hash(floor(q));
		metal += vec3(0.05, 0.08, 0.12) * g_fbm(p * 0.3 + 2.0);
		metal = mix(metal, vec3(0.25, 0.62, 1.0), seam * 0.6);
		float haz = step(0.5, fract((p.x + p.y) * 0.7)) * step(6.75, abs(p.x)) * step(abs(p.x), 7.35) * step(abs(p.y), 4.6);
		return mix(metal, vec3(0.95, 0.76, 0.1), haz * 0.7);
	} else if (kind == 9) {
		// Rooftop: poured concrete, joints, damp stains, puddles holding the night sky.
		float n = g_fbm(p * 0.7);
		vec3 c = mix(vec3(0.2, 0.2, 0.235), vec3(0.33, 0.32, 0.36), n) * (0.86 + 0.24 * g_noise(p * 18.0));
		vec2 f = abs(fract(p / 3.0) - 0.5);
		c *= 1.0 - 0.45 * smoothstep(0.485, 0.5, max(f.x, f.y));
		c *= 1.0 - 0.3 * smoothstep(0.55, 0.8, g_fbm(p * 0.35 + 4.0));
		float pud = smoothstep(0.6, 0.68, g_fbm(p * 0.5 + 11.0));
		c = mix(c, vec3(0.3, 0.16, 0.42) * (0.8 + 0.5 * g_noise(p * 2.0 + t * 0.15)), pud * 0.65);
		float ring = 1.0 - smoothstep(0.07, 0.12, abs(length(p) - 9.2));
		return mix(c, vec3(0.92, 0.74, 0.16), ring * 0.75 * (0.6 + 0.4 * g_noise(p * 6.0)));
	} else if (kind == 10) {
		// Duel hall: a varnished plank court, the three dorm colors painted round its edge.
		vec2 q = vec2(p.x * 0.9, p.y * 3.2);
		float row = floor(q.y);
		q.x += g_hash(vec2(row, 1.0)) * 5.0;
		vec2 f = fract(q);
		vec3 w = mix(vec3(0.6, 0.4, 0.2), vec3(0.8, 0.58, 0.31), g_hash(vec2(floor(q.x), row)));
		w *= 0.9 + 0.16 * g_noise(vec2(q.x * 5.0, q.y * 40.0));
		w *= 1.0 - 0.3 * (1.0 - smoothstep(0.0, 0.05, f.y));
		w *= 1.0 - 0.25 * (1.0 - smoothstep(0.0, 0.012, f.x));
		float band = step(4.25, abs(p.y)) * step(abs(p.y), 4.6) * step(abs(p.x), 7.4);
		w = mix(w, p.y > 0.0 ? vec3(0.82, 0.15, 0.14) : vec3(0.16, 0.36, 0.86), band * 0.88);
		float band2 = step(7.05, abs(p.x)) * step(abs(p.x), 7.4) * step(abs(p.y), 4.6);
		w = mix(w, vec3(0.95, 0.76, 0.18), band2 * 0.88);
		return w + vec3(0.09, 0.08, 0.06) * g_fbm(p * 0.3 + t * 0.02);
	} else if (kind == 11) {
		// Junkyard: cracked asphalt, rust bleeding across it, weeds in the cracks, an oil slick.
		vec2 v = g_voro(p * 0.5 + g_fbm(p * 0.6));
		float crack = 1.0 - smoothstep(0.0, 0.035, v.x);
		vec3 a = vec3(0.105, 0.1, 0.095) * (0.75 + 0.6 * g_fbm(p * 6.0));
		a = mix(a, vec3(0.36, 0.17, 0.07) * (0.8 + 0.4 * g_noise(p * 9.0)), smoothstep(0.5, 0.8, g_fbm(p * 0.45 + 2.0)) * 0.6);
		a = mix(a, vec3(0.02), crack * 0.8);
		a = mix(a, vec3(0.14, 0.24, 0.08), crack * smoothstep(0.45, 0.7, v.y) * 0.7);
		float oil = smoothstep(0.7, 0.76, g_fbm(p * 0.8 + 20.0));
		vec3 sheen = 0.5 + 0.5 * vec3(sin(p.x * 9.0 + t * 0.2), sin(p.y * 7.0 + 2.0), sin(p.x * 5.0 + p.y * 4.0 + 4.0));
		return mix(a, vec3(0.03, 0.03, 0.05) + sheen * 0.09, oil * 0.7);
	} else if (kind == 12) {
		// Heartland: pale tiles of every shape with light running in the gaps.
		vec2 v = g_voro(p * 0.9);
		vec3 tile = mix(vec3(0.86, 0.83, 0.76), vec3(0.98, 0.95, 0.88), v.y) * (0.92 + 0.1 * g_noise(p * 20.0));
		float edge = 1.0 - smoothstep(0.0, 0.05, v.x);
		float pulse = 0.5 + 0.5 * sin(t * 1.5 + v.y * 30.0);
		vec3 glow = mix(vec3(1.0, 0.8, 0.2), vec3(1.0, 0.35, 0.7), step(0.5, v.y));
		tile = mix(tile, glow, edge * (0.55 + 0.4 * pulse));
		return mix(tile, glow, step(0.9, v.y) * 0.3 * pulse);
	} else if (kind == 13) {
		// Red dorm lawn at sunset: warm grass, a patch worn bare by a hundred duels, red flowers.
		float n = g_fbm(p * 1.3);
		vec3 g = mix(vec3(0.15, 0.29, 0.07), vec3(0.4, 0.54, 0.14), n);
		g *= 0.84 + 0.32 * g_noise(p * vec2(38.0, 9.0));
		float worn = smoothstep(0.38, 0.66, g_fbm(p * 0.6 + 3.0)) * (1.0 - smoothstep(4.0, 8.5, length(p * vec2(0.62, 1.0))));
		g = mix(g, vec3(0.52, 0.37, 0.2) * (0.8 + 0.4 * g_noise(p * 12.0)), worn * 0.75);
		vec2 fc = floor(p * 6.0);
		float fl = step(0.985, g_hash(fc)) * (1.0 - smoothstep(0.12, 0.3, length(fract(p * 6.0) - 0.5))) * (1.0 - worn);
		g = mix(g, mix(vec3(0.95, 0.2, 0.16), vec3(1.0, 0.95, 0.85), step(0.6, g_hash(fc + 3.0))), fl);
		return g * vec3(1.14, 0.98, 0.8);
	} else if (kind == 14) {
		// Blue dorm hall: white and blue marble squares, veined, set in thin gold.
		vec2 q = p * 0.55;
		vec2 c = floor(q);
		float chk = mod(c.x + c.y, 2.0);
		vec2 f = abs(fract(q) - 0.5);
		float vein = smoothstep(0.0, 0.1, abs(g_fbm(p * 1.6 + g_fbm(p * 0.8) * 2.0) - 0.5));
		vec3 m = mix(vec3(0.85, 0.87, 0.93), vec3(0.52, 0.64, 0.88), chk * 0.85);
		m *= 0.9 + 0.14 * g_fbm(p * 4.0);
		m = mix(m * (chk > 0.5 ? 1.22 : 0.78), m, vein);
		m = mix(m, vec3(0.88, 0.72, 0.32), smoothstep(0.465, 0.5, max(f.x, f.y)) * 0.85);
		return m + vec3(0.07, 0.09, 0.13) * g_fbm(p * 0.25 + t * 0.03);
	} else if (kind == 15) {
		// Highway at night: dark asphalt, lane dashes, yellow edge lines, reflector studs.
		vec3 a = vec3(0.075, 0.08, 0.09) * (0.8 + 0.5 * g_fbm(p * 7.0));
		a *= 1.0 - 0.22 * smoothstep(0.55, 0.8, g_noise(vec2(p.x * 0.3, p.y * 5.0)));
		float dash = step(abs(abs(p.y) - 4.9), 0.07) * step(0.45, fract(p.x * 0.2));
		a = mix(a, vec3(0.9, 0.9, 0.85), dash * 0.8);
		float edge = step(abs(abs(p.y) - 9.0), 0.09);
		a = mix(a, vec3(0.95, 0.75, 0.15), edge * 0.85);
		float stud = step(0.93, fract(p.x * 0.2)) * step(abs(abs(p.y) - 4.9), 0.1);
		return a + vec3(1.0, 0.5, 0.1) * stud * 0.9;
	} else if (kind == 16) {
		// Pier: long weathered planks, dark gaps, damp green patches, the odd nail head.
		vec2 q = vec2(p.x * 2.6, p.y * 0.35);
		float row = floor(q.x);
		q.y += g_hash(vec2(row, 2.0)) * 3.0;
		vec2 f = fract(q);
		vec3 w = mix(vec3(0.38, 0.27, 0.17), vec3(0.56, 0.43, 0.29), g_hash(vec2(row, floor(q.y))));
		w *= 0.85 + 0.25 * g_noise(vec2(q.x * 30.0, q.y * 4.0));
		w *= 1.0 - 0.6 * (1.0 - smoothstep(0.0, 0.06, f.x));
		w *= 1.0 - 0.4 * (1.0 - smoothstep(0.0, 0.015, f.y));
		w = mix(w, vec3(0.2, 0.32, 0.24), smoothstep(0.6, 0.85, g_fbm(p * 0.5 + 7.0)) * 0.3);
		float nail = 1.0 - smoothstep(0.03, 0.05, length(vec2((f.x - 0.5) * 0.38, f.y - 0.06)));
		return mix(w, vec3(0.12, 0.11, 0.1), nail * 0.8) * vec3(1.1, 0.97, 0.85);
	}
	float n = g_fbm(p * 0.9 + vec2(t * 0.05, -t * 0.03));
	float n2 = g_fbm(p * 2.2 - vec2(t * 0.04));
	vec3 c = mix(vec3(0.03, 0.01, 0.06), vec3(0.22, 0.05, 0.32), smoothstep(0.35, 0.75, n));
	return c + vec3(0.5, 0.15, 0.7) * pow(smoothstep(0.55, 0.8, n2), 2.0) * 0.35;
}
"""

## Where each duelist feels at home. Anyone not listed gets their series' field.
const HOME := {
	"yugi": "battlecity", "kaiba": "kaibacorp", "joey": "pier", "mai": "pier", "bakura": "shadow", "marik": "shadow",
	"pegasus": "ruins", "weevil": "meadow", "rex": "volcano",
	"jaden": "reddorm", "syrus": "reddorm", "chazz": "academy", "aster": "academy", "zane": "bluehall", "alexis": "bluehall",
	"yusei": "highway", "jack": "highway", "crow": "satellite", "kalin": "satellite", "akiza": "highway",
	"yuma": "heartland", "shark": "tide", "kite": "heartland", "vector": "shadow",
}


static func resolve(choice: String, opponent: String) -> Dictionary:
	var key := choice
	if key == "auto" or not THEMES.has(key):
		key = HOME.get(opponent, "")
		if key == "":
			var era: String = Characters.DATA.get(opponent, {}).get("era", "")
			key = {"Duel Monsters": "battlecity", "GX": "academy", "5D's": "highway", "ZEXAL": "heartland"}.get(era, "crossroads")
	var t: Dictionary = THEMES[key].duplicate()
	t["key"] = key
	return t
