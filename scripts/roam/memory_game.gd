class_name MemoryGame
extends CanvasLayer
## A cabinet: Card Match. Sixteen cards face down, eight pairs. Turn two over: a pair stays,
## anything else flips back. The fewer misses, the bigger the prize.

const FEE := 10
const BASE := 140         # prize for a clean board
const PER_MISS := 10
const FLOOR := 20

var scene
var _ids: Array = []
var _cards: Array = []     # TextureButton per slot
var _open: Array = []      # slots turned over this try
var _found := {}
var _misses := 0
var _busy := false
var _info: Label


static func open(roam) -> void:
	if Collection.dp < FEE:
		Router.toast(Loc.t("Not enough Duel Points to play. The cabinet takes %d.") % FEE)
		return
	var g := MemoryGame.new()
	g.scene = roam
	roam.add_child(g)


func _ready() -> void:
	layer = 6
	scene._overlay_open = true
	Collection.dp -= FEE
	Collection.save()
	var pool: Array = []
	for id in Collection.every_playable():
		if CardData.get_card(id).get("kind", "") == "monster":
			pool.append(id)
	pool.shuffle()
	for id in pool.slice(0, 8):
		_ids.append(id)
		_ids.append(id)
	_ids.shuffle()
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var v := VBoxContainer.new()
	v.theme = UITheme.build()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -560
	v.offset_right = 560
	v.offset_top = -500
	v.offset_bottom = 500
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	shade.add_child(v)
	var title := UITheme.label(Loc.t("CARD MATCH"), 50, Color("ff8ad8"), UITheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_info = UITheme.label("", 22, Color.WHITE, UITheme.semi_font())
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	for i in 16:
		var b := TextureButton.new()
		b.custom_minimum_size = Vector2(126, 184)
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.texture_normal = Cards.get_back()
		b.focus_mode = Control.FOCUS_ALL
		b.pivot_offset = Vector2(63, 92)
		var slot := i
		b.pressed.connect(func(): _turn(slot))
		b.focus_entered.connect(func(): b.modulate = Color(1.25, 1.25, 1.0))
		b.focus_exited.connect(func(): b.modulate = Color.WHITE)
		grid.add_child(b)
		_cards.append(b)
	var close := Button.new()
	close.text = Loc.t("Step away  (Esc)")
	close.custom_minimum_size = Vector2(300, 52)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): _finish(false))
	v.add_child(close)
	_say()
	(_cards[0] as Control).grab_focus.call_deferred()


func _say() -> void:
	_info.text = Loc.t("Find the eight pairs.   Misses: %d   Prize now: %d DP   Best: %s") % [_misses, _prize(),
		str(Collection.record.get("match_best", "-"))]


func _prize() -> int:
	return maxi(FLOOR, BASE - PER_MISS * _misses)


func _turn(slot: int) -> void:
	if _busy or _found.has(slot) or _open.has(slot):
		return
	_busy = true
	Sfx.play("card", -4.0)
	await _flip(slot, Cards.get_face(int(_ids[slot])))
	_open.append(slot)
	if _open.size() < 2:
		_busy = false
		return
	var a: int = _open[0]
	var b: int = _open[1]
	_open.clear()
	if int(_ids[a]) == int(_ids[b]):
		_found[a] = true
		_found[b] = true
		Sfx.play("coin", -4.0, 1.0 + 0.05 * _found.size())
		_say()
		if _found.size() == 16:
			await get_tree().create_timer(0.8).timeout
			_finish(true)
			return
	else:
		_misses += 1
		_say()
		await get_tree().create_timer(0.85).timeout
		await _flip(a, Cards.get_back())
		await _flip(b, Cards.get_back())
	_busy = false


func _flip(slot: int, tex: Texture2D) -> void:
	var c: TextureButton = _cards[slot]
	var t1 := create_tween()
	t1.tween_property(c, "scale:x", 0.0, 0.1)
	await t1.finished
	c.texture_normal = tex
	var t2 := create_tween()
	t2.tween_property(c, "scale:x", 1.0, 0.1)
	await t2.finished


func _finish(cleared: bool) -> void:
	if cleared:
		var won := _prize()
		Collection.dp += won
		var best = Collection.record.get("match_best", null)
		if best == null or _misses < int(best):
			Collection.record["match_best"] = _misses
		Sfx.play("rare", -4.0)
		Router.toast(Loc.t("Board cleared with %d misses. The cabinet pays out %d Duel Points.") % [_misses, won])
	Collection.save()
	scene._overlay_open = false
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
		_finish(false)
		get_viewport().set_input_as_handled()
