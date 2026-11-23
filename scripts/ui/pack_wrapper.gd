class_name PackWrapper
extends Control
## A foil booster pack: the pack's illustration, crimped seals top and bottom, its name on a
## band, and a sheen of light that slides across. Used on the shop shelf and when a pack opens.

const ART := {"Duel Monsters": "dm", "GX": "gx", "5D's": "5ds", "ZEXAL": "zexal", "Vault": "vault"}

var pack := {}
var sheen := true           # the travelling highlight
var torn := false           # the top seal has been ripped off
var glow := 0.0             # 0..1 extra rim light (hover / selected)
var _art: Texture2D
var _t := randf() * 5.0
var _title_font: Font
var _semi: Font


## The cover is a real card from the pack: its strongest monster.
var _region := Rect2()


func setup(p: Dictionary, lazy := false) -> PackWrapper:
	pack = p
	if lazy:
		# (A shelf of them: the cover comes in when it is known and its picture is read, on another
		# thread; until then the wrapper shows its colors and name.)
		_wait_cover = true
		_take_cover()
		return self
	var cover := Collection.pack_cover(str(p.get("key", "")))
	if cover != 0:
		var got := Cards.cover_art(cover)
		_art = got[0]
		_region = got[1]
	return self


var _wait_cover := false


func _take_cover() -> void:
	if not Collection.covers_ready():
		return
	_wait_cover = false
	var cover := Collection.pack_cover(str(pack.get("key", "")))
	if cover == 0:
		return
	Cards.thumb_later(cover, func(t: Texture2D):
		if not is_instance_valid(self) or t == null:
			return
		var ts := t.get_size()
		_region = Rect2(Vector2.ZERO, ts)
		if ts.x / maxf(ts.y, 1.0) < 0.82:
			_region = Rect2(ts.x * 0.125, ts.y * 0.185, ts.x * 0.75, ts.x * 0.75)
		_art = t)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_font = UITheme.title_font()
	_semi = UITheme.semi_font()
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(250, 384)


func _process(delta: float) -> void:
	_t += delta
	if _wait_cover:
		_take_cover()
	queue_redraw()


## The outline of the top seal alone (for the strip that tears away).
static func seal_rect(sz: Vector2) -> Rect2:
	return Rect2(0, 0, sz.x, sz.y * 0.075)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var col: Color = pack.get("color", UITheme.ACCENT)
	var seal := h * 0.075
	var band := h * 0.2
	# Drop shadow.
	draw_rect(Rect2(6, 10, w, h), Color(0, 0, 0, 0.35))
	# Rim light when picked.
	if glow > 0.01:
		for i in 4:
			draw_rect(Rect2(-4 - i * 3, -4 - i * 3, w + 8 + i * 6, h + 8 + i * 6), Color(col.r, col.g, col.b, 0.11 * glow), false, 4.0)
	# Body.
	draw_rect(Rect2(0, seal if torn else 0.0, w, h - (seal if torn else 0.0)), col.darkened(0.7))
	var art_r := Rect2(0, seal, w, h - seal * 2.0)
	if _art:
		# The monster fills the wrapper, lit in the pack's color: a glow behind the name band
		# and a shade at the top so the seal and the tag read.
		draw_texture_rect_region(_art, art_r, Cards.cover_fit(_region, art_r.size))
		for i in 10:
			draw_rect(Rect2(0, art_r.position.y + art_r.size.y * (0.45 + 0.055 * i), w, art_r.size.y * 0.055 + 1), Color(col.darkened(0.55), 0.075 * i))
		for i in 6:
			draw_rect(Rect2(0, art_r.position.y + art_r.size.y * 0.03 * i, w, art_r.size.y * 0.03 + 1), Color(0, 0, 0, 0.3 - 0.05 * i))
		draw_rect(art_r, Color(col, 0.1))
		draw_rect(art_r.grow(-5), Color(col.lightened(0.5), 0.35), false, 1.5)
	else:
		for i in 12:
			draw_rect(Rect2(0, art_r.position.y + art_r.size.y * i / 12.0, w, art_r.size.y / 12.0 + 1), col.darkened(0.2 + i * 0.05))
	# Name band.
	var by := h - seal - band
	for i in 10:
		draw_rect(Rect2(0, by + band * i / 10.0, w, band / 10.0 + 1), Color(0.02, 0.03, 0.06, 0.55 + 0.4 * i / 9.0))
	draw_rect(Rect2(0, by, w, 3), col)
	var name_s := Collection.pack_title(pack).to_upper()
	var fs := int(h * 0.062)
	while fs > 7 and _title_font.get_string_size(name_s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 20.0:
		fs -= 1
	var ns := _title_font.get_string_size(name_s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	# (The outline follows the type size: a fixed 6 px swamped the name on small wrappers.)
	draw_string_outline(_title_font, Vector2((w - ns.x) / 2.0, by + band * 0.5), name_s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(fs * 0.3)), Color(0, 0, 0, 0.9))
	draw_string(_title_font, Vector2((w - ns.x) / 2.0, by + band * 0.5), name_s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	var sub := Loc.t("%d CARDS  ·  BOOSTER PACK") % Collection.PACK_SIZE
	var ss := int(h * 0.034)
	var sw := _semi.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
	draw_string(_semi, Vector2((w - sw) / 2.0, by + band * 0.83), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, col.lightened(0.55))
	# Era tag, top left of the art.
	var era := Collection.base_key(str(pack.get("key", "")))
	if pack.has("era"):
		era = str(pack["era"])
	elif Collection.FAMILIES.has(era):
		era = str(Collection.FAMILIES[era].get("era", ""))      # (the family's era, not its key)
	era = era.to_upper()
	if int(pack.get("vol", 0)) > 0:
		era += "  ·  VOL. %d/%d" % [int(pack["vol"]), int(pack["vols"])]
	var es := int(h * 0.036)
	var ew := _semi.get_string_size(era, HORIZONTAL_ALIGNMENT_LEFT, -1, es).x
	draw_rect(Rect2(0, seal + 10, ew + 22, es + 12), Color(0.02, 0.03, 0.06, 0.8))
	draw_rect(Rect2(0, seal + 10, 4, es + 12), col)
	draw_string(_semi, Vector2(12, seal + 10 + es + 2), era, HORIZONTAL_ALIGNMENT_LEFT, -1, es, col.lightened(0.5))
	# Crimped seals: ridged foil with a saw-tooth edge.
	for top in ([false] if torn else [true, false]):
		var y0 := 0.0 if top else h - seal
		draw_rect(Rect2(0, y0, w, seal), col.darkened(0.35))
		var ridges := int(w / 7.0)
		for i in ridges:
			var x := w * float(i) / ridges
			draw_rect(Rect2(x, y0, w / ridges * 0.5, seal), Color(1, 1, 1, 0.13))
		draw_rect(Rect2(0, y0 + (seal - 2.0 if top else 0.0), w, 2), Color(0, 0, 0, 0.35))
		var teeth := int(w / 9.0)
		for i in teeth:
			var x0 := w * float(i) / teeth
			var x1 := w * float(i + 1) / teeth
			var ye := y0 if top else y0 + seal
			var tip := ye + (5.0 if top else -5.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x0, ye), Vector2(x1, ye), Vector2((x0 + x1) / 2.0, tip)]), Color(0.01, 0.015, 0.04))
	if torn:
		# A ragged edge where the seal used to be.
		var teeth2 := int(w / 14.0)
		for i in teeth2:
			var xa := w * float(i) / teeth2
			var xb := w * float(i + 1) / teeth2
			draw_colored_polygon(PackedVector2Array([Vector2(xa, seal), Vector2(xb, seal), Vector2((xa + xb) / 2.0, seal - 7.0 - 5.0 * sin(i * 2.1))]), col.darkened(0.55))
	# Foil sheen: a slanted bar of light that crosses every few seconds.
	if sheen:
		var u := fmod(_t, 3.4) / 1.1
		if u < 1.0:
			var cx := lerpf(-w * 0.6, w * 1.6, u)
			var pts := PackedVector2Array([Vector2(cx - 34, h), Vector2(cx + 34, h), Vector2(cx + 34 + h * 0.35, 0), Vector2(cx - 34 + h * 0.35, 0)])
			var clip := Geometry2D.intersect_polygons(pts, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]))
			for poly in clip:
				draw_colored_polygon(poly, Color(1, 1, 1, 0.17))
	# A steady soft gloss down the left side and the outline.
	for i in 6:
		draw_rect(Rect2(w * 0.04 + i * 2.0, seal, 2.0, h - seal * 2.0), Color(1, 1, 1, 0.05 - i * 0.007))
	draw_rect(Rect2(0, seal if torn else 0.0, w, h - (seal if torn else 0.0)), Color(col.lightened(0.3), 0.9), false, 2.0)
