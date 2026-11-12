class_name DeckBox
extends Control
## A ready-made deck in its box: the art, the deck's name on a band, who plays it, and a
## ribbon when it is already yours.

var info := {}
var owned := false
var glow := 0.0
var _art: Texture2D
var _card_art := false       # the art is a card face: show its picture window, not the frame
var _title_font: Font
var _semi: Font


func setup(entry: Dictionary) -> DeckBox:
	info = entry
	var art := str(entry.get("art", ""))
	var path := "res://assets/ui/packs/%s.jpg" % art
	if art != "" and ResourceLoader.exists(path):
		_art = load(path)
	else:
		var ace := Collection.deck_ace(str(entry.get("key", "")))
		if ace != 0:
			_art = Cards.get_face(ace)
			_card_art = true
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_font = UITheme.title_font()
	_semi = UITheme.semi_font()


func _process(_delta: float) -> void:
	queue_redraw()


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
		var ts := _art.get_size()
		var src := Rect2(Vector2.ZERO, ts)
		if _card_art:
			src = Rect2(ts.x * 0.12, ts.y * 0.18, ts.x * 0.76, ts.y * 0.45)
		var want := art_r.size.x / art_r.size.y
		if src.size.x / src.size.y > want:
			var nw := src.size.y * want
			src = Rect2(src.position.x + (src.size.x - nw) / 2.0, src.position.y, nw, src.size.y)
		else:
			var nh := src.size.x / want
			src = Rect2(src.position.x, src.position.y + (src.size.y - nh) * 0.3, src.size.x, nh)
		draw_texture_rect_region(_art, art_r, src)
	else:
		draw_rect(art_r, col.darkened(0.5))
	# Shade into the band.
	for i in 8:
		draw_rect(Rect2(6, art_r.end.y - 48 + i * 6, w - 12, 6), Color(0, 0, 0, 0.08 * i))
	draw_rect(Rect2(0, h - band, w, band), col.darkened(0.62))
	draw_rect(Rect2(0, h - band, w, 4), col.lightened(0.25))
	var name := Loc.t(str(info.get("name", ""))).to_upper()
	var fs := 26
	while fs > 14 and _title_font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 20:
		fs -= 1
	draw_string(_title_font, Vector2(10, h - band + 34), name, HORIZONTAL_ALIGNMENT_CENTER, w - 20, fs, Color.WHITE)
	var sub := Loc.t("%s's deck") % Loc.t(str(info["owner"])) if str(info.get("owner", "")) != "" else Loc.t("Theme deck")
	if str(info.get("kind", "")) == "starter":
		sub = Loc.t("Starter deck")
	draw_string(_semi, Vector2(10, h - band + 58), sub, HORIZONTAL_ALIGNMENT_CENTER, w - 20, 16, col.lightened(0.55))
	draw_rect(Rect2(0, 0, w, h), col.lightened(0.1 + 0.4 * glow), false, 3.0)
	# Tag, top left.
	draw_rect(Rect2(0, 12, 112, 24), Color(0, 0, 0, 0.72))
	draw_string(_semi, Vector2(8, 30), Loc.t("40 CARDS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.9))
	if owned:
		draw_rect(Rect2(w - 96, 12, 96, 26), Color("2bb673"))
		draw_string(_semi, Vector2(w - 90, 31), Loc.t("OWNED"), HORIZONTAL_ALIGNMENT_CENTER, 84, 16, Color.WHITE)
