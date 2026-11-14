class_name ArcadeGame
extends CanvasLayer
## A cabinet you can actually play: Higher or Lower. One card is face up. Is the next
## monster's ATK higher or lower? Every right call grows the prize; one wrong call loses it.
## Walk away with the prize whenever you like. Eight in a row is the jackpot.

const FEE := 10
const STEP := 18          # prize per right call
const JACKPOT := 250

var scene
var _pool: Array = []
var _cur := 0
var _next := 0
var _streak := 0
var _busy := false
var _left: TextureRect
var _right: TextureRect
var _left_l: Label
var _right_l: Label
var _info: Label
var _prize: Label
var _btns: Array = []


static func open(roam) -> void:
	if Collection.dp < FEE:
		Router.toast(Loc.t("Not enough Duel Points to play. The cabinet takes %d.") % FEE)
		return
	var g := ArcadeGame.new()
	g.scene = roam
	roam.add_child(g)


func _ready() -> void:
	layer = 6
	scene._overlay_open = true
	Collection.dp -= FEE
	Collection.save()
	for id in CardData.EXT.keys():
		var d: Dictionary = CardData.EXT[id]
		if str(d.get("frame", "")) in ["normal", "effect"] and int(d.get("atk", 0)) > 0 and int(d.get("level", 0)) > 0:
			_pool.append(int(id))
	if _pool.size() < 20:
		for id in CardData.deck_list("echo") + CardData.deck_list("kairo"):
			if CardData.get_card(id).get("kind", "") == "monster":
				_pool.append(id)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var v := VBoxContainer.new()
	v.theme = UITheme.build()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.offset_left = -560
	v.offset_right = 560
	v.offset_top = -430
	v.offset_bottom = 430
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	shade.add_child(v)
	var title := UITheme.label(Loc.t("HIGHER OR LOWER"), 54, Color("5affc0"), UITheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_info = UITheme.label(Loc.t("Is the next monster's ATK higher or lower?"), 24, Color.WHITE, UITheme.semi_font())
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 70)
	v.add_child(row)
	for side in 2:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		row.add_child(col)
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(300, 437)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.pivot_offset = Vector2(150, 218)
		col.add_child(tr)
		var l := UITheme.label("", 30, UITheme.GOLD, UITheme.title_font())
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		if side == 0:
			_left = tr
			_left_l = l
		else:
			_right = tr
			_right_l = l
	_prize = UITheme.label("", 28, UITheme.GOLD, UITheme.semi_font())
	_prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_prize)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 18)
	v.add_child(bar)
	for spec in [["Higher  (W / Up)", 1], ["Lower  (S / Down)", -1], ["Take the prize  (Esc)", 0]]:
		var b := Button.new()
		b.text = Loc.t(str(spec[0]))
		b.custom_minimum_size = Vector2(300, 64)
		b.add_theme_font_size_override("font_size", 24)
		var way: int = spec[1]
		b.pressed.connect(func(): _call(way))
		bar.add_child(b)
		_btns.append(b)
	_cur = _pick(0)
	_deal()
	(_btns[0] as Button).grab_focus.call_deferred()


func _pick(not_this: int) -> int:
	for i in 40:
		var id: int = _pool[randi() % _pool.size()]
		if id != not_this and int(CardData.get_card(id).get("atk", 0)) != int(CardData.get_card(not_this).get("atk", -1)):
			return id
	return _pool[randi() % _pool.size()]


func _atk(id: int) -> int:
	return int(CardData.get_card(id).get("atk", 0))


func _deal() -> void:
	_next = _pick(_cur)
	_left.texture = Cards.get_face(_cur)
	_left_l.text = "ATK %d" % _atk(_cur)
	_right.texture = Cards.get_back()
	_right_l.text = "ATK ?"
	_prize.text = Loc.t("Prize so far: %d DP     Streak: %d     Best: %d") % [_streak * STEP, _streak, int(Collection.record.get("hilo_best", 0))]
	_busy = false


func _call(way: int) -> void:
	if _busy:
		return
	if way == 0:
		_finish(true)
		return
	_busy = true
	Sfx.play("card")
	var t1 := create_tween()
	t1.tween_property(_right, "scale:x", 0.0, 0.13)
	await t1.finished
	_right.texture = Cards.get_face(_next)
	_right_l.text = "ATK %d" % _atk(_next)
	var t2 := create_tween()
	t2.tween_property(_right, "scale:x", 1.0, 0.15)
	await t2.finished
	var right := (_atk(_next) > _atk(_cur)) == (way > 0)
	if not right:
		Sfx.play("lose", -6.0)
		_info.text = Loc.t("Wrong! The prize is gone.")
		_streak = 0
		await get_tree().create_timer(1.6).timeout
		_finish(false)
		return
	_streak += 1
	Sfx.play("coin", -3.0, 1.0 + _streak * 0.06)
	_info.text = Loc.t("Right! Keep going, or take the prize?")
	if _streak > int(Collection.record.get("hilo_best", 0)):
		Collection.record["hilo_best"] = _streak
	if _streak >= 8:
		_info.text = Loc.t("EIGHT IN A ROW! JACKPOT!")
		Sfx.play("rare")
		await get_tree().create_timer(1.6).timeout
		_finish(true)
		return
	await get_tree().create_timer(0.9).timeout
	_cur = _next
	_deal()


func _finish(paid: bool) -> void:
	var won := _streak * STEP + (JACKPOT if _streak >= 8 else 0)
	if paid and won > 0:
		Collection.dp += won
		Router.toast(Loc.t("The cabinet pays out %d Duel Points.") % won)
	Collection.save()
	scene._overlay_open = false
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_W, KEY_UP]:
			_call(1)
		elif event.keycode in [KEY_S, KEY_DOWN]:
			_call(-1)
		elif event.keycode == KEY_ESCAPE:
			_call(0)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		_call(0)
		get_viewport().set_input_as_handled()
