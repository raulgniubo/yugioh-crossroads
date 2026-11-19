class_name CardFx
extends RefCounted
## A look for what a card does (0.61.0). When a Spell, a Trap or a monster's effect is
## activated, the table shows what kind of thing it is: an emblem pops up over the card (a
## burst for "destroy", a card for "draw", a flame for "damage", chevrons up for "gains ATK"...)
## in that kind's colour, with a short flourish of the same kind under it. When the effect
## picks targets, a line of that kind runs from the card to each of them; damage and healing go
## to the duelist they land on.
## What kind an activation is comes from, in this order: the label its script gives that effect
## ("Destroy", "Special Summon"...), the card database's own tags for the card
## (data/card_cats.json), and last the card's text.
## Everything is drawn by shaders on simple pieces and frees itself. `board` is the DuelBoard.

## kind -> [emblem number, colour, second colour]
const KINDS := {
	"generic": [0, Color("ffd76a"), Color("ff9a3c")],
	"destroy": [1, Color("ff4a3a"), Color("ff9a5a")],
	"banish": [2, Color("b06bff"), Color("5a1ad0")],
	"bounce": [3, Color("9fd0ff"), Color("ffffff")],
	"draw": [4, Color("7fe8ff"), Color("ffffff")],
	"search": [5, Color("ffd76a"), Color("fff2c0")],
	"summon": [6, Color("ffb03a"), Color("ffe9a8")],
	"revive": [7, Color("ffe9a8"), Color("ffc23d")],
	"burn": [8, Color("ff7a1e"), Color("e0260a")],
	"heal": [9, Color("6dff9a"), Color("d8ffe0")],
	"boost": [10, Color("ffd23a"), Color("fff2a8")],
	"weaken": [11, Color("ff5a8a"), Color("8a2a5a")],
	"control": [12, Color("ff5ad8"), Color("a03cff")],
	"negate": [13, Color("9fe8ff"), Color("ff5a6a")],
	"position": [14, Color("5ad0c0"), Color("d0fff5")],
	"equip": [15, Color("7fb8ff"), Color("e0f0ff")],
	"discard": [16, Color("9a5cff"), Color("3a1a7a")],
	"mill": [17, Color("a8b8d8"), Color("5a6a8a")],
	"lock": [18, Color("e0b050"), Color("8a6a2a")],
	"protect": [19, Color("8fd0ff"), Color("ffffff")],
	"counter": [20, Color("b8ff5a"), Color("5ac03a")],
	"gamble": [21, Color("ffffff"), Color("ffd76a")],
	"peek": [22, Color("7fe8ff"), Color("3a8aff")],
	"level": [23, Color("ffe36a"), Color("ff9a3c")],
}

## What an effect's own label says it is (the first that matches).
const LABELS := [
	["negate", "negate"], ["destroy", "destroy"], ["banish", "banish"], ["remove from play", "banish"],
	["return to hand", "bounce"], ["return to the hand", "bounce"], ["return it to the hand", "bounce"], ["return to deck", "bounce"], ["shuffle", "bounce"],
	["draw", "draw"], ["search", "search"], ["add to hand", "search"], ["add card", "search"], ["to your hand", "search"],
	["from the gy", "revive"], ["from your gy", "revive"], ["from graveyard", "revive"], ["from the graveyard", "revive"],
	["special summon", "summon"], ["fusion summon", "summon"], ["ritual summon", "summon"], ["synchro summon", "summon"], ["xyz summon", "summon"], ["token", "summon"],
	["inflict", "burn"], ["damage", "burn"], ["gain lp", "heal"], ["recover", "heal"], ["gain life", "heal"],
	["lose atk", "weaken"], ["decrease", "weaken"], ["reduce", "weaken"], ["halve", "weaken"],
	["increase atk", "boost"], ["gain atk", "boost"], ["gain attack", "boost"], ["increase attack", "boost"], ["change atk", "boost"], ["atk", "boost"],
	["take control", "control"], ["control", "control"], ["position", "position"], ["face-down", "position"], ["equip", "equip"],
	["discard", "discard"], ["send to g", "mill"], ["excavate", "peek"], ["look", "peek"], ["reveal", "peek"],
	["counter", "counter"], ["coin", "gamble"], ["dice", "gamble"], ["die", "gamble"], ["level", "level"], ["rank", "level"],
]

## The card database's tags, most telling first: [bits, kind].
const BITS := [
	[0x30000, "negate"], [0x3, "destroy"], [0x40000000, "control"], [0x80, "banish"], [0x40000, "burn"], [0x80000, "heal"],
	[0x1D00000, "summon"], [0x100, "draw"], [0x200, "search"], [0x20, "search"], [0x8, "discard"], [0x4, "mill"], [0x40, "bounce"],
	[0x10, "mill"], [0x400, "boost"], [0x1000, "position"], [0x10000000, "counter"], [0x20000000, "gamble"], [0x800, "level"],
]

## The card's own words: the first of these its text gets to (after its cost, see _by_text).
const WORDS := [
	["negate the attack", "protect"], ["negate", "negate"], ["destroy", "destroy"], ["banish", "banish"], ["take control", "control"],
	["inflict", "burn"], ["fusion summon", "summon"], ["ritual summon", "summon"], ["special summon", "summon"], ["draw", "draw"],
	["from your deck to your hand", "search"], ["add 1", "search"], ["add it to your hand", "search"], ["return", "bounce"], ["shuffle", "bounce"], ["discard", "discard"],
	["cannot declare an attack", "lock"], ["cannot attack", "lock"], ["cannot be destroyed", "protect"], ["take no", "protect"], ["no battle damage", "protect"],
	["halve", "weaken"], ["loses", "weaken"], ["lose ", "weaken"], ["battle position", "position"], ["defense position", "position"], ["attack position", "position"],
	["look at", "peek"], ["excavate", "peek"], ["reveal", "peek"], ["roll a", "gamble"], ["toss a coin", "gamble"], ["counter", "counter"],
	["send", "mill"],
]

# The emblems: 24 small pictures drawn from distances, white on a dark disc with a coloured rim.
const EMBLEM := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;
uniform int kind = 0;
uniform vec3 color : source_color = vec3(1.0, 0.85, 0.4);
uniform vec3 color2 : source_color = vec3(1.0);
uniform float alpha = 1.0;
uniform float pop = 1.0;
varying vec2 uv;
void vertex() {
	uv = UV;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
float seg(vec2 p, vec2 a, vec2 b) { vec2 pa = p - a; vec2 ba = b - a; return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0)); }
float box(vec2 p, vec2 b) { vec2 d = abs(p) - b; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float tri(vec2 p, vec2 a, vec2 b, vec2 c) {
	vec2 e0 = b - a; vec2 e1 = c - b; vec2 e2 = a - c;
	vec2 v0 = p - a; vec2 v1 = p - b; vec2 v2 = p - c;
	vec2 q0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
	vec2 q1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
	vec2 q2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
	float s = sign(e0.x * e2.y - e0.y * e2.x);
	vec2 d = min(min(vec2(dot(q0, q0), s * (v0.x * e0.y - v0.y * e0.x)), vec2(dot(q1, q1), s * (v1.x * e1.y - v1.y * e1.x))), vec2(dot(q2, q2), s * (v2.x * e2.y - v2.y * e2.x)));
	return -sqrt(d.x) * sign(d.y);
}
// An arrow from a to b: shaft and head. Returns distance.
float arrow(vec2 p, vec2 a, vec2 b, float head) {
	vec2 d = normalize(b - a);
	vec2 n = vec2(-d.y, d.x);
	float s = seg(p, a, b - d * head * 0.8) - 0.045;
	float h = tri(p, b, b - d * head + n * head * 0.62, b - d * head - n * head * 0.62);
	return min(s, h);
}
float chevron(vec2 p, float y, float dir) {
	return min(seg(p, vec2(-0.3, y), vec2(0.0, y + 0.2 * dir)), seg(p, vec2(0.3, y), vec2(0.0, y + 0.2 * dir))) - 0.055;
}
float star(vec2 p, float r, float n, float inner) {
	float a = atan(p.x, p.y);
	float k = 6.2831853 / n;
	float f = abs(mod(a + k * 0.5, k) - k * 0.5) / (k * 0.5);
	return length(p) - mix(r, r * inner, f);
}
void fragment() {
	vec2 p = (uv - 0.5) * 2.0;
	p.y = -p.y;
	float r = length(p);
	float a = atan(p.y, p.x);
	float d = 1.0;        // distance to the picture (negative inside)
	if (kind == 0) { d = star(p, 0.6, 4.0, 0.3); }
	else if (kind == 1) { d = max(star(p, 0.62, 8.0, 0.55), -star(p, 0.3, 8.0, 0.5)); d = min(d, star(p, 0.14, 4.0, 0.4)); }
	else if (kind == 2) { float s = abs(fract(a / 6.2831853 + r * 1.7) - 0.5); d = max((s - 0.2) * 0.5, r - 0.62); }
	else if (kind == 3) {
		float arc = max(abs(length(p - vec2(0.05, 0.0)) - 0.34) - 0.05, -(p.x - 0.05));
		d = min(arc, seg(p, vec2(0.05, -0.34), vec2(-0.42, -0.34)) - 0.05);
		d = min(d, seg(p, vec2(0.05, 0.34), vec2(-0.2, 0.34)) - 0.05);
		d = min(d, tri(p, vec2(-0.58, 0.34), vec2(-0.2, 0.58), vec2(-0.2, 0.1)));
	}
	else if (kind == 4) { d = abs(box(p - vec2(-0.08, -0.05), vec2(0.27, 0.4)) - 0.04) - 0.04; d = min(d, min(box(p - vec2(0.38, 0.33), vec2(0.2, 0.05)), box(p - vec2(0.38, 0.33), vec2(0.05, 0.2)))); }
	else if (kind == 5) { d = abs(length(p - vec2(-0.1, 0.12)) - 0.3) - 0.055; d = min(d, seg(p, vec2(0.13, -0.11), vec2(0.46, -0.46)) - 0.075); }
	else if (kind == 6) { d = min(abs(r - 0.56) - 0.035, star(p, 0.42, 4.0, 0.28)); }
	else if (kind == 7) { d = arrow(p, vec2(0.0, -0.3), vec2(0.0, 0.58), 0.3); d = min(d, seg(p, vec2(-0.5, -0.42), vec2(-0.17, -0.42)) - 0.05); d = min(d, seg(p, vec2(0.17, -0.42), vec2(0.5, -0.42)) - 0.05); }
	else if (kind == 8) {
		float body = length(p - vec2(0.0, -0.18)) - 0.36;
		float tip = tri(p, vec2(-0.3, 0.0), vec2(0.3, 0.0), vec2(0.06, 0.62));
		float inner = min(length(p - vec2(0.0, -0.26)) - 0.17, tri(p, vec2(-0.14, -0.2), vec2(0.14, -0.2), vec2(-0.02, 0.14)));
		d = max(min(body, tip), -inner);
	}
	else if (kind == 9) { d = min(box(p, vec2(0.5, 0.17)), box(p, vec2(0.17, 0.5))) - 0.03; }
	else if (kind == 10) { d = min(min(chevron(p, -0.48, 1.0), chevron(p, -0.18, 1.0)), chevron(p, 0.12, 1.0)); }
	else if (kind == 11) { d = min(min(chevron(p, 0.48, -1.0), chevron(p, 0.18, -1.0)), chevron(p, -0.12, -1.0)); }
	else if (kind == 12) { d = min(arrow(p, vec2(-0.5, 0.22), vec2(0.52, 0.22), 0.26), arrow(p, vec2(0.5, -0.22), vec2(-0.52, -0.22), 0.26)); }
	else if (kind == 13) { d = min(abs(r - 0.5) - 0.06, max(seg(p, vec2(-0.36, 0.36), vec2(0.36, -0.36)) - 0.06, r - 0.5)); }
	else if (kind == 14) {
		float ring = abs(r - 0.44) - 0.05;
		ring = max(ring, -tri(p, vec2(0.0, 0.0), vec2(0.7, 0.1), vec2(0.45, 0.7)));
		d = min(ring, tri(p, vec2(0.44, 0.34), vec2(0.2, 0.08), vec2(0.66, 0.02)));
		d = min(d, box(p, vec2(0.11, 0.16)) - 0.02);
	}
	else if (kind == 15) {
		d = tri(p, vec2(-0.09, -0.12), vec2(0.09, -0.12), vec2(0.0, 0.64));
		d = min(d, box(p - vec2(0.0, -0.17), vec2(0.27, 0.05)));
		d = min(d, box(p - vec2(0.0, -0.38), vec2(0.045, 0.17)));
		d = min(d, length(p - vec2(0.0, -0.58)) - 0.08);
	}
	else if (kind == 16) { d = abs(box(p - vec2(0.0, 0.22), vec2(0.24, 0.33)) - 0.03) - 0.04; d = min(d, chevron(p, -0.34, -1.0)); }
	else if (kind == 17) {
		d = min(min(box(p - vec2(0.0, 0.42), vec2(0.4, 0.045)), box(p - vec2(0.0, 0.24), vec2(0.4, 0.045))), box(p - vec2(0.0, 0.06), vec2(0.4, 0.045)));
		d = min(d, arrow(p, vec2(0.0, -0.08), vec2(0.0, -0.6), 0.26));
	}
	else if (kind == 18) {
		d = box(p - vec2(0.0, -0.2), vec2(0.36, 0.28)) - 0.04;
		float sh = abs(length(p - vec2(0.0, 0.14)) - 0.26) - 0.055;
		d = min(d, max(sh, -(p.y - 0.1)));
		d = max(d, -(length(p - vec2(0.0, -0.16)) - 0.08));
	}
	else if (kind == 19) {
		float sh = min(box(p - vec2(0.0, 0.2), vec2(0.42, 0.34)), tri(p, vec2(-0.42, -0.1), vec2(0.42, -0.1), vec2(0.0, -0.62)));
		d = abs(sh) - 0.055;
		d = min(d, box(p - vec2(0.0, 0.02), vec2(0.04, 0.3)));
	}
	else if (kind == 20) { d = min(min(length(p - vec2(0.0, 0.3)) - 0.19, length(p - vec2(-0.29, -0.2)) - 0.19), length(p - vec2(0.29, -0.2)) - 0.19); }
	else if (kind == 21) {
		d = abs(box(p, vec2(0.38, 0.38)) - 0.08) - 0.045;
		d = min(d, length(p) - 0.085);
		d = min(d, min(length(abs(p) - vec2(0.24, 0.24)) - 0.085, 1.0));
	}
	else if (kind == 22) {
		float lens = max(length(p - vec2(0.0, -0.42)) - 0.72, length(p - vec2(0.0, 0.42)) - 0.72);
		d = min(abs(lens) - 0.045, length(p) - 0.15);
	}
	else { d = star(p, 0.62, 5.0, 0.42); }
	float pic = smoothstep(0.03, -0.01, d);
	float halo = exp(-max(d, 0.0) * 9.0) * 0.5;
	float disc = smoothstep(0.86, 0.82, r);
	float rim = smoothstep(0.045, 0.0, abs(r - 0.84)) + smoothstep(0.02, 0.0, abs(r - 0.74)) * 0.5;
	// (a ring of light that runs out from it as it pops)
	float wave = smoothstep(0.05, 0.0, abs(r - mix(0.2, 0.98, pop))) * (1.0 - pop);
	vec3 bg = mix(vec3(0.02, 0.035, 0.09), color * 0.34, 0.5 + 0.5 * (1.0 - r));
	vec3 c = mix(bg, color * 1.7, clamp(rim + halo * 0.9, 0.0, 1.0));
	c = mix(c, mix(vec3(1.0), color2, 0.25) * 1.9, pic);
	c += color * wave * 2.0;
	ALBEDO = c;
	ALPHA = clamp(disc * 0.9 + rim + wave, 0.0, 1.0) * alpha;
}
"""

static var _cats := {}
static var _loaded := false
static var _sh: Shader
static var _memo := {}


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open("res://data/card_cats.json", FileAccess.READ)
	if f:
		var got = JSON.parse_string(f.get_as_text())
		if got is Dictionary:
			_cats = got


static func _t(sec: float) -> float:
	return Settings.t(sec)


static func color(kind: String) -> Color:
	return (KINDS.get(kind, KINDS["generic"]) as Array)[1]


static func color2(kind: String) -> Color:
	return (KINDS.get(kind, KINDS["generic"]) as Array)[2]


## What kind of thing this activation is. `label` is the line the card's script gives the
## effect ("Destroy", "Special Summon from your hand"...), or "".
static func kind(inst, label := "") -> String:
	if inst == null:
		var only := _by_label(label)
		return only if only != "" else "generic"
	var text := str(inst.data.get("desc", inst.data.get("text", ""))).to_lower()
	var from_gy := (text.contains("from your gy") or text.contains("from your graveyard") or text.contains("in your gy") or text.contains("in your graveyard")
			or text.contains("either gy") or text.contains("either graveyard") or text.contains("from the gy") or text.contains("from the graveyard")) and not text.contains("from your hand")
	var by := _by_label(label)
	if by != "":
		return "revive" if by == "summon" and from_gy and not label.to_lower().contains("hand") and not label.to_lower().contains("deck") else by
	var key := "%d" % int(inst.id)
	if _memo.has(key):
		return _memo[key]
	_load()
	var bits := int(_cats.get(key, 0))
	var is_monster := str(inst.data.get("kind", "monster")) == "monster"
	var tagged := "generic"
	for b in BITS:
		if bits & int(b[0]) != 0:
			tagged = str(b[1])
			break
	var worded := _by_text(text)
	# A Spell or Trap is what its text does first; a monster's text opens with how it is
	# Summoned, so its tags are the better guide.
	var out := (worded if worded != "" else tagged) if not is_monster else (tagged if tagged != "generic" else (worded if worded != "" else "generic"))
	if tagged == "negate" and text.contains("negate"):
		out = "protect" if text.contains("negate the attack") else "negate"      # (a Counter Trap is a negation whatever it does next)
	if out == "summon" and from_gy:
		out = "revive"
	elif out == "boost" and not text.contains("gain") and (text.contains("loses") or text.contains("lose ") or text.contains("halve")):
		out = "weaken"
	elif out in ["generic", "mill"] and not is_monster and str(inst.data.get("st", "")).to_lower() == "equip":
		out = "equip"
	_memo[key] = out
	return out


## The first thing the text does, after its cost ("Discard 1 card; destroy..." is a "destroy").
static func _by_text(text: String) -> String:
	var t := text
	# (only a cost in the card's first sentence: "Discard 1 card; destroy all..." )
	var semi := t.find(";")
	var stop := t.find(". ")
	if semi >= 0 and semi < 240 and (stop < 0 or semi < stop):
		t = t.substr(semi + 1)
	var best := ""
	var at := 1 << 30
	for w in WORDS:
		var i := t.find(str(w[0]))
		if i >= 0 and i < at:
			at = i
			best = str(w[1])
	# "gain 1000 LP" heals, "gains 700 ATK" is a boost.
	var g := t.find("gain")
	if g >= 0 and g < at:
		var after := t.substr(g, 26)
		best = "heal" if (after.contains("lp") or after.contains("life")) else "boost"
	return best


static func _by_label(label: String) -> String:
	if label == "":
		return ""
	var l := label.to_lower()
	for pair in LABELS:
		if l.contains(str(pair[0])):
			return str(pair[1])
	return ""


static func _mat(k: String) -> ShaderMaterial:
	if _sh == null:
		_sh = Shader.new()
		_sh.code = EMBLEM
	var spec: Array = KINDS.get(k, KINDS["generic"])
	var m := ShaderMaterial.new()
	m.shader = _sh
	m.set_shader_parameter("kind", int(spec[0]))
	m.set_shader_parameter("color", spec[1])
	m.set_shader_parameter("color2", spec[2])
	m.set_shader_parameter("alpha", 0.0)
	m.set_shader_parameter("pop", 0.0)
	m.render_priority = 5
	return m


## The emblem of a kind, popping up at `at` (a point in the air), holding and drifting up as it fades.
static func emblem(board: Node3D, at: Vector3, k: String, size := 0.95, hold := 0.75) -> MeshInstance3D:
	var m := _mat(k)
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 4.0
	mi.position = at - Vector3(0, 0.25, 0)
	mi.scale = Vector3.ONE * size * 0.3
	board.add_child(mi)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(m, "shader_parameter/alpha", 1.0, _t(0.08))
	tw.tween_property(m, "shader_parameter/pop", 1.0, _t(0.4))
	tw.tween_property(mi, "scale", Vector3.ONE * size, _t(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "position", at, _t(0.2)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(_t(hold))
	tw.chain().tween_property(m, "shader_parameter/alpha", 0.0, _t(0.25))
	tw.parallel().tween_property(mi, "position:y", at.y + 0.3, _t(0.25))
	tw.chain().tween_callback(mi.queue_free)
	return mi


## An activation: the emblem over the card and the flourish of its kind under it.
## `spot` is the card's place on the table; `high` lifts the emblem (over a monster's hologram).
## `quiet`: the card has a signature look of its own (StrikeFx.card), so only the emblem shows.
static func play(board: Node3D, spot: Vector3, k: String, high := 1.25, quiet := false) -> void:
	if board.get("turbo") == true or Settings.anim_speed > 2.0:
		return
	emblem(board, Vector3(spot.x, high, spot.z), k)
	if quiet:
		return
	var f := Vector3(spot.x, 0.03, spot.z)
	var c := color(k)
	var c2 := color2(k)
	match k:
		"destroy":
			ElementFx.decal(board, f, 3, c, c2, 2.2, 1.0)
			DuelFx.rays(board, f, c, 1.6, 0.4, 18, true, 2.0)
			DuelFx.sparks(board, f + Vector3(0, 0.1, 0), c, 16, 3.5, 0.5, 0.6, -6.0, 0.05)
			Sfx.play("el_thunder", -12.0, 1.3)
		"banish":
			DuelFx.spiral(board, f + Vector3(0, 0.02, 0), c, c2, 0.95, 0.9, {"arms": 2, "twist": 6.0, "speed": 7.0, "hole": 0.18, "energy": 1.9})
			DuelFx.embers(board, f, c, 0.5, 14, 0.7, 1.6, 0.05)
			Sfx.play("banish", -12.0, 1.1)
		"bounce":
			ElementFx.twister(board, f, c, c2, 0.25, 0.55, 1.5, 0.6, 0.0, 1.4, 0.9)
			DuelFx.ring(board, f, c, 0.2, 1.1, 0.4, 0.04, 0.0, 1.7)
			Sfx.play("el_wind", -14.0, 1.6)
		"draw":
			DuelFx.glyph(board, f, c, 0.8, 0.8, {"rings": 1, "ticks": 0, "star": 0, "dash": 14, "turn": 2.4, "energy": 1.9})
			DuelFx.pillar(board, Vector3(f.x, 0, f.z), c, 0.22, 2.6, 0.6, 0.0, 1.3)
			DuelFx.embers(board, f, c2, 0.4, 12, 0.6, 2.4, 0.045)
			Sfx.play("sparkle", -10.0, 1.4)
		"search":
			DuelFx.glyph(board, f, c, 0.85, 0.85, {"rings": 1, "ticks": 24, "star": 0, "turn": -2.0, "energy": 1.9})
			DuelFx.rect(board, f, c2, 1.0, 1.6, 0.45, false, 1.8, 0.6)
			Sfx.play("sparkle", -10.0, 1.1)
		"summon":
			DuelFx.glyph(board, f, c, 0.95, 0.9, {"rings": 2, "ticks": 0, "star": 3, "turn": 2.6, "energy": 1.9})
			DuelFx.embers(board, f, c2, 0.6, 18, 0.7, 2.4, 0.05)
			Sfx.play("charge", -14.0, 1.5)
		"revive":
			DuelFx.pillar(board, Vector3(f.x, 0, f.z), c, 0.4, 4.5, 0.8, 0.0, 1.3)
			DuelFx.ring(board, f, c2, 1.2, 0.3, 0.45, 0.05, 0.0, 1.7)
			DuelFx.embers(board, f, c, 0.5, 20, 0.8, 2.8, 0.05)
			Sfx.play("el_light_up", -12.0, 0.9)
		"burn":
			for i in 3:
				var a := TAU * float(i) / 3.0 + 0.5
				ElementFx.puff(board, f + Vector3(cos(a) * 0.3, 0.42, sin(a) * 0.22), 1, c, c2, 0.85, 0.6, 0.2, i * 0.04)
			ElementFx.decal(board, f, 0, c, c2, 1.6, 1.1)
			Sfx.play("el_fire_up", -11.0, 1.2)
		"heal":
			for i in 3:
				DuelFx.ring(board, f, c.lerp(c2, i * 0.3), 1.2 - i * 0.1, 0.25, 0.5, 0.04, i * 0.1, 1.6)
			DuelFx.embers(board, f, c2, 0.55, 22, 0.8, 2.2, 0.05)
			Sfx.play("heal", -8.0, 1.1)
		"boost":
			DuelFx.rect(board, f, c, 1.0, 1.45, 0.5, false, 1.9, 0.7)
			DuelFx.embers(board, f, c2, 0.42, 22, 0.7, 2.8, 0.055)
			DuelFx.pillar(board, Vector3(f.x, 0, f.z), c, 0.3, 2.4, 0.55, 0.0, 1.1)
			Sfx.play("charge", -13.0, 1.5)
		"weaken":
			DuelFx.ring(board, f, c, 1.3, 0.25, 0.5, 0.05, 0.0, 1.7)
			DuelFx.sparks(board, f + Vector3(0, 1.0, 0), c, 16, 1.0, 0.0, 0.7, -5.0, 0.05)
			Sfx.play("fizz", -10.0, 0.8)
		"control":
			DuelFx.spiral(board, f + Vector3(0, 0.02, 0), c, c2, 0.9, 0.9, {"arms": 2, "twist": 3.0, "speed": -5.0, "energy": 1.8})
			DuelFx.ring(board, f, c, 0.2, 1.1, 0.45, 0.04, 0.0, 1.7)
			Sfx.play("special", -14.0, 1.3)
		"negate":
			DuelFx.glyph(board, f, c, 0.9, 0.85, {"rings": 2, "ticks": 16, "star": 4, "turn": -1.2, "energy": 2.0})
			DuelFx.rect(board, f, c2, 1.7, 1.0, 0.3, false, 2.0, 0.7)
			Sfx.play("counter", -10.0, 1.0)
		"position":
			DuelFx.glyph(board, f, c, 0.85, 0.8, {"rings": 1, "ticks": 0, "star": 0, "dash": 8, "turn": 5.0, "energy": 1.9})
			DuelFx.rect(board, f, c2, 1.0, 1.4, 0.45, true, 1.7, 0.5)
			Sfx.play("whoosh", -12.0, 1.3)
		"equip":
			DuelFx.rect(board, f, c, 1.0, 1.5, 0.45, false, 1.9, 0.7)
			DuelFx.ring(board, f, c2, 0.2, 1.0, 0.4, 0.04, 0.0, 1.7)
			Sfx.play("land", -12.0, 1.5)
		"discard":
			ElementFx.decal(board, f, 2, c, c2, 1.9, 0.9)
			DuelFx.embers(board, f, c, 0.45, 12, 0.7, 1.2, 0.045)
			Sfx.play("el_dark_up", -12.0, 1.3)
		"mill":
			DuelFx.ring(board, f, c, 1.1, 0.3, 0.45, 0.045, 0.0, 1.6)
			DuelFx.sparks(board, f + Vector3(0, 0.9, 0), c, 14, 0.9, 0.0, 0.7, -5.0, 0.05)
			Sfx.play("card", -8.0, 0.8)
		"lock":
			DuelFx.glyph(board, f, c, 0.9, 0.9, {"rings": 2, "ticks": 0, "star": 0, "dash": 10, "turn": 0.6, "energy": 1.9})
			DuelFx.rect(board, f, c2, 1.6, 1.0, 0.35, false, 1.9, 0.6)
			Sfx.play("chain", -8.0, 0.7)
		"protect":
			DuelFx.glyph(board, f, c, 1.0, 0.9, {"rings": 2, "ticks": 0, "star": 3, "turn": 0.8, "energy": 1.9})
			DuelFx.pillar(board, Vector3(f.x, 0, f.z), c, 0.75, 1.6, 0.7, 0.0, 1.0)
			Sfx.play("counter", -11.0, 1.3)
		"counter":
			for i in 3:
				DuelFx.ring(board, f, c, 0.15, 0.6 + i * 0.25, 0.4, 0.04, i * 0.08, 1.7)
			Sfx.play("blip", -6.0, 1.4)
		"gamble":
			DuelFx.rays(board, f, c, 1.4, 0.4, 12, true, 1.8)
			DuelFx.ring(board, f, c2, 0.2, 1.0, 0.4, 0.04, 0.0, 1.7)
			Sfx.play("coin", -8.0, 1.0)
		"peek":
			DuelFx.glow(board, f + Vector3(0, 0.3, 0), c, 1.2, 0.5, 0.8, 1.5)
			DuelFx.ring(board, f, c, 0.2, 1.0, 0.45, 0.035, 0.0, 1.6)
			Sfx.play("sparkle", -12.0, 1.6)
		"level":
			DuelFx.embers(board, f, c, 0.4, 16, 0.7, 2.6, 0.05)
			DuelFx.ring(board, f, c2, 0.2, 0.9, 0.4, 0.04, 0.0, 1.7)
			Sfx.play("sparkle", -11.0, 1.2)
		_:
			DuelFx.ring(board, f, c, 0.2, 1.0, 0.4, 0.04, 0.0, 1.7)
			DuelFx.embers(board, f, c2, 0.4, 10, 0.6, 2.0, 0.045)


## The effect picks a target: a line of its kind runs from the card to it, and it is marked.
static func aim(board: Node3D, from: Vector3, to: Vector3, k: String) -> void:
	if board.get("turbo") == true or Settings.anim_speed > 2.0 or from.distance_to(to) < 0.3:
		return
	var a := Vector3(from.x, 0.55, from.z)
	var b := Vector3(to.x, 0.45, to.z)
	var f := Vector3(to.x, 0.03, to.z)
	var c := color(k)
	var c2 := color2(k)
	match k:
		"destroy":
			ElementFx.ribbon(board, a, b, 6, c2, c, 0.75, 0.14, {"arc": 0.6, "hold": 0.1, "fade": 0.2, "energy": 1.6})
			DuelFx.rays(board, f, c, 1.3, 0.35, 14, true, 1.9)
		"banish", "discard":
			ElementFx.ribbon(board, a, b, 4, c, c2, 0.6, 0.18, {"arc": 0.5, "hold": 0.1, "fade": 0.25})
		"bounce", "position":
			ElementFx.ribbon(board, a, b, 2, c, c2, 0.7, 0.16, {"arc": 0.4, "hold": 0.08, "fade": 0.22})
		"burn":
			ElementFx.ribbon(board, a, b, 0, c, c2, 0.6, 0.16, {"arc": 0.5, "hold": 0.08, "fade": 0.25})
		"control":
			for i in 3:
				ElementFx.ribbon(board, a + Vector3(0, 0.4 + i * 0.25, 0), b + Vector3((i - 1) * 0.18, 0.1, 0), 3, c, c2, 0.16, 0.2, {"arc": 0.9 - i * 0.2, "hold": 0.35, "fade": 0.25, "energy": 1.6})
		"negate", "lock":
			ElementFx.ribbon(board, a, b, 3, c, c2, 0.4, 0.14, {"arc": 0.4, "hold": 0.1, "fade": 0.2, "energy": 1.6})
			DuelFx.rect(board, f, c, 1.7, 1.0, 0.3, false, 1.9, 0.6)
		_:
			ElementFx.ribbon(board, a, b, 3, c, c2, 0.34, 0.16, {"arc": 0.55, "hold": 0.1, "fade": 0.22, "energy": 1.5})
	# The mark on the target.
	DuelFx.ring(board, f, c, 1.2, 0.5, 0.3, 0.05, 0.1, 1.9)
	emblem(board, Vector3(to.x, 1.0, to.z), k, 0.55, 0.4)


## Damage from a card effect goes from the card to the duelist it lands on.
static func to_duelist(board: Node3D, from: Vector3, p: int, k: String) -> void:
	if board.get("turbo") == true or Settings.anim_speed > 2.0:
		return
	var z := 5.6 if p == 0 else -5.6
	var a := Vector3(from.x, 0.6, from.z)
	var b := Vector3(0.0, 1.1, z)
	var c := color(k)
	var c2 := color2(k)
	ElementFx.ribbon(board, a, b, 0, c, c2, 0.8, 0.2, {"arc": 1.0, "hold": 0.1, "fade": 0.28})
	ElementFx._later(board, 0.2, func():
		ElementFx.puff(board, b, 0, c, c2, 1.6, 0.6, 0.3, 0.0, 1.2)
		DuelFx.sparks(board, b, c, 18, 4.0, 0.5, 0.7, -6.0, 0.05)
		Sfx.play("el_fire_hit", -10.0, 1.3))


## Life Points gained: green light rises around that duelist.
static func bless(board: Node3D, p: int) -> void:
	if board.get("turbo") == true or Settings.anim_speed > 2.0:
		return
	var z := 6.0 if p == 0 else -6.0
	var f := Vector3(0.0, 0.03, z)
	var c := color("heal")
	for i in 3:
		DuelFx.ring(board, f, c.lerp(Color.WHITE, i * 0.25), 1.4 - i * 0.15, 0.3, 0.55, 0.045, i * 0.1, 1.6)
	DuelFx.pillar(board, Vector3(0, 0, z), c, 0.5, 3.2, 0.8, 0.0, 0.9)
	DuelFx.embers(board, f, color2("heal"), 0.6, 26, 0.9, 2.4, 0.05)


## Compile the emblem shader before the first card is played.
static func warm(board: Node3D) -> void:
	_load()
	var mi := emblem(board, Vector3(0, -40, 0), "generic", 0.01, 0.1)
	mi.visible = true
