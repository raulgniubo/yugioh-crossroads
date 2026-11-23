class_name DeckBox
extends Control
## A ready-made deck in its box: the art, the deck's name on a band, who plays it, and a
## ribbon when it is already yours.

var info := {}
var owned := false
var glow := 0.0
var _art: Texture2D
var _face: Texture2D          # a duelist's deck: their portrait, in a medallion on the art
var _card_art := false       # the art is a card face: show its picture window, not the frame
var _title_font: Font
var _semi: Font


## The cover is the deck's own ace monster.
var _region := Rect2()


func setup(entry: Dictionary, lazy := false) -> DeckBox:
	info = entry
	var ace := Collection.deck_ace(str(entry.get("key", "")))
	if ace != 0:
		_card_art = true
		if lazy:
			# (A row of them: the picture is read on another thread and comes in when it is ready.)
			Cards.thumb_later(ace, func(t: Texture2D):
				if not is_instance_valid(self) or t == null:
					return
				var ts := t.get_size()
				_region = Rect2(Vector2.ZERO, ts)
				if ts.x / maxf(ts.y, 1.0) < 0.82:
					_region = Rect2(ts.x * 0.125, ts.y * 0.185, ts.x * 0.75, ts.x * 0.75)
				_art = t)
		else:
			var got := Cards.cover_art(ace)
			_art = got[0]
			_region = got[1]
	var who := str(entry.get("who", ""))
	if str(entry.get("kind", "")) == "duelist" and who != "" and Avatars.has_avatar(who):
		if not lazy or Avatars.ready_now(who) or Portraits.holds(who):
			_face = Portraits.get_portrait(who)
		else:
			_face_wait = who          # (their model is read on a worker thread first)
			Avatars.warm(who)
	return self


var _face_wait := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_font = UITheme.title_font()
	_semi = UITheme.semi_font()


func _process(_delta: float) -> void:
	if _face_wait != "" and is_visible_in_tree():
		if Avatars.ready_now(_face_wait) or Portraits.holds(_face_wait):
			_face = Portraits.get_portrait(_face_wait)
			_face_wait = ""
		else:
			Avatars.warm(_face_wait)
	queue_redraw()


## A texture drawn inside a circle (as a fan of triangles with UVs).
func _draw_round(tex: Texture2D, cen: Vector2, rad: float, src: Rect2) -> void:
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var ts := tex.get_size()
	for i in 40:
		var a := TAU * i / 40.0
		var d := Vector2(cos(a), sin(a))
		pts.append(cen + d * rad)
		uvs.append((src.position + src.size * (Vector2(0.5, 0.5) + d * 0.5)) / ts)
	draw_colored_polygon(pts, Color.WHITE, uvs, tex)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var col: Color = info.get("color", UITheme.ACCENT)
	draw_rect(Rect2(5, 8, w, h), Color(0, 0, 0, 0.4))
	if glow > 0.01:
		for i in 4:
			draw_rect(Rect2(-3 - i * 3, -3 - i * 3, w + 6 + i * 6, h + 6 + i * 6), Color(col.r, col.g, col.b, 0.12 * glow), false, 4.0)
	draw_rect(Rect2(0, 0, w, h), col.darkened(0.78))
	var band := h * 0.24
	var art_r := Rect2(6, 6, w - 12, h - band - 8)
	if _art:
		draw_texture_rect_region(_art, art_r, Cards.cover_fit(_region, art_r.size))
		draw_rect(art_r, Color(col, 0.08))
		draw_rect(art_r, Color(col.lightened(0.4), 0.4), false, 1.5)
	else:
		draw_rect(art_r, col.darkened(0.5))
	if _face:
		# The duelist whose deck this is, in a round frame at the bottom right of the art.
		var rad := minf(w, h) * 0.2
		var cen := Vector2(art_r.end.x - rad - 8, art_r.end.y - rad - 10)
		draw_circle(cen + Vector2(2, 4), rad + 4, Color(0, 0, 0, 0.45))
		draw_circle(cen, rad + 4, col.lightened(0.35))
		draw_circle(cen, rad, col.darkened(0.55))
		var fs_sz := _face.get_size()
		var side := minf(fs_sz.x, fs_sz.y)
		var src := Rect2((fs_sz.x - side) / 2.0, 0, side, side)
		_draw_round(_face, cen, rad - 2, src)
	# Shade into the band.
	for i in 8:
		draw_rect(Rect2(6, art_r.end.y - 48 + i * 6, w - 12, 6), Color(0, 0, 0, 0.08 * i))
	draw_rect(Rect2(0, h - band, w, band), col.darkened(0.62))
	draw_rect(Rect2(0, h - band, w, 4), col.lightened(0.25))
	var name := Loc.t(str(info.get("name", ""))).to_upper()
	var fs := 26
	while fs > 11 and _title_font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 20:
		fs -= 1
	draw_string(_title_font, Vector2(10, h - band + 34), name, HORIZONTAL_ALIGNMENT_CENTER, w - 20, fs, Color.WHITE)
	var sub := Loc.t("%s's deck") % Loc.t(str(info["owner"])) if str(info.get("owner", "")) != "" else Loc.t("Theme deck")
	if str(info.get("kind", "")) == "starter":
		sub = Loc.t("Starter deck")
	elif str(info.get("kind", "")) == "gift":
		sub = Loc.t("A gift from Lumen")
	# (Small boxes, like the shelves of the Decks hub: the line gets smaller rather than cut off.)
	var sfs := 16
	while sfs > 10 and _semi.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x > w - 12:
		sfs -= 1
	draw_string(_semi, Vector2(6, h - band + 58), sub, HORIZONTAL_ALIGNMENT_CENTER, w - 12, sfs, col.lightened(0.55))
	draw_rect(Rect2(0, 0, w, h), col.lightened(0.1 + 0.4 * glow), false, 3.0)
	# Tag, top left.
	draw_rect(Rect2(0, 12, minf(112.0, w), 24), Color(0, 0, 0, 0.72))
	draw_string(_semi, Vector2(8, 30), Loc.t("40 CARDS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.9))
	if owned:
		draw_rect(Rect2(w - 96, 12, 96, 26), Color("2bb673"))
		draw_string(_semi, Vector2(w - 90, 31), Loc.t("OWNED"), HORIZONTAL_ALIGNMENT_CENTER, 84, 16, Color.WHITE)
