class_name QuizPanel
extends Control
## A one-question duel quiz: the question, three answers, then what was right and why.

signal closed
signal answered(correct: bool)

const QUESTIONS := [
	["How many cards does a Main Deck need at least?", ["40", "30", "50"], 0, "A Main Deck holds 40 to 60 cards."],
	["How many Life Points does each duelist start with?", ["8000", "4000", "10000"], 0, "Each duelist starts at 8000 Life Points."],
	["How many Tributes does a Level 5 or 6 monster need?", ["One", "Two", "None"], 0, "Level 5 and 6 need one Tribute. Level 7 and up need two."],
	["How many Tributes does a Level 7 monster need?", ["Two", "One", "Three"], 0, "Level 7 and higher need two Tributes."],
	["How many times can you Normal Summon or Set in one turn?", ["Once", "Twice", "As often as you like"], 0, "One Normal Summon or Set per turn. Special Summons do not count."],
	["When can you activate a Trap Card?", ["From the turn after you Set it", "The turn you Set it", "Only on your own turn"], 0, "A Trap must be Set first and can be used from the next turn on, including the opponent's turn."],
	["Your 1800 ATK monster attacks a 1500 ATK monster in Attack Position. What happens?", ["Theirs is destroyed and they lose 300", "Both are destroyed", "Nothing"], 0, "The weaker monster is destroyed and its owner takes the difference."],
	["Your 1600 ATK monster attacks a Defense Position monster with 2000 DEF. What happens?", ["You lose 400 and nothing is destroyed", "Your monster is destroyed", "Their monster is destroyed"], 0, "Attacking into higher DEF costs you the difference. Neither monster is destroyed."],
	["What do you need for a Synchro Summon?", ["A Tuner plus non-Tuner monsters whose Levels add up", "Two monsters of the same Level", "Polymerization"], 0, "One Tuner and one or more non-Tuners, with Levels that add up to the Synchro monster's Level."],
	["What do you need for an Xyz Summon?", ["Monsters of the same Level", "A Tuner", "A Ritual Spell"], 0, "Stack monsters of the same Level. They become Xyz Materials."],
	["Which phase comes right after the Draw Phase?", ["Standby Phase", "Main Phase 1", "Battle Phase"], 0, "Draw, Standby, Main 1, Battle, Main 2, End."],
	["Can the player who goes first attack on the very first turn?", ["No", "Yes", "Only directly"], 0, "There is no Battle Phase on the first turn of the duel."],
	["How many copies of the same card can a deck hold?", ["Three", "Two", "Four"], 0, "Up to three copies, fewer if the card is Limited."],
	["What happens when you must draw and your deck is empty?", ["You lose the duel", "You skip the draw", "You shuffle your Graveyard back"], 0, "No card to draw means you lose."],
	["A Quick-Play Spell is Set face-down. When can you activate it?", ["From the next turn on", "Right away", "Never"], 0, "Set Quick-Play Spells wait a turn, like Traps."],
	["What is the biggest Extra Deck allowed?", ["15 cards", "10 cards", "20 cards"], 0, "The Extra Deck holds up to 15 cards."],
	["In a Turbo Duel, what do both riders gain every Standby Phase?", ["A Speed Counter", "A card", "1000 Life Points"], 0, "Speed Counters build each Standby Phase and power Speed Spells."],
	["A monster in Defense Position is attacked and survives. Who takes damage if ATK was lower than DEF?", ["The attacker", "The defender", "Nobody"], 0, "The attacker takes the difference."],
]

var _buttons: Array = []
var _result: Label
var _why: Label
var _right := 0
var _done := false
var _reward := 0


func _init(reward := 0) -> void:
	_reward = reward


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.02, 0.05, 0.7)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var q: Array = QUESTIONS[randi() % QUESTIONS.size()]
	var pc := PanelContainer.new()
	var sb := UITheme.panel_box(Color(0.042, 0.0676, 0.145, 0.97), 22, Color(UITheme.GOLD, 0.6))
	sb.set_content_margin_all(34)
	pc.add_theme_stylebox_override("panel", sb)
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.custom_minimum_size = Vector2(900, 0)
	pc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pc.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	pc.add_child(v)
	v.add_child(UITheme.label("DUEL QUIZ", 22, UITheme.GOLD, UITheme.semi_font()))
	var ql := UITheme.label(str(q[0]), 34, Color.WHITE, UITheme.title_font())
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ql)
	# Shuffle the answers, remembering where the right one went.
	var order := [0, 1, 2]
	order.shuffle()
	for k in 3:
		var b := Button.new()
		b.text = Loc.t(str((q[1] as Array)[order[k]]))
		b.custom_minimum_size = Vector2(0, 60)
		b.add_theme_font_size_override("font_size", 24)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if order[k] == int(q[2]):
			_right = k
		b.pressed.connect(func(): _pick(k, str(q[3])))
		v.add_child(b)
		_buttons.append(b)
	_result = UITheme.label("", 28, Color.WHITE, UITheme.title_font())
	v.add_child(_result)
	_why = UITheme.label("", 20, UITheme.TEXT_DIM)
	_why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_why)
	(_buttons[0] as Button).grab_focus.call_deferred()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _pick(k: int, why: String) -> void:
	if _done:
		_close()
		return
	_done = true
	var ok := k == _right
	for i in _buttons.size():
		var b: Button = _buttons[i]
		var col := Color("2f9e63") if i == _right else (UITheme.DANGER.darkened(0.2) if i == k else Color(1, 1, 1, 0.04))
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, UITheme.button_box(col, col.lightened(0.2)))
	if ok:
		_result.text = Loc.t("Correct!") + ("   +%d Duel Points" % _reward if _reward > 0 else "")
		_result.add_theme_color_override("font_color", Color("6ff0a8"))
		Sfx.play("quest", -4.0)
	else:
		_result.text = Loc.t("Not quite.")
		_result.add_theme_color_override("font_color", UITheme.DANGER)
		Sfx.play("error", -6.0)
	_why.text = Loc.t(why) + "\n" + Loc.t("Press any answer or Esc to close.")
	answered.emit(ok)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
