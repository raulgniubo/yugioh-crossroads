class_name Voices
## The spoken lines of a duel. Every opponent talks in the voice of their personality (kind, cocky,
## cool, wild, dark; the first three also have a woman's voice), Lumen has her own, and your duelist
## speaks at the big moments. The voices are original (designed for this game, one set per language)
## and the files are built in: res://voices/<lang>/<voice>/<key>.ogg, where <key> is the first 12 hex
## digits of the md5 of the line's English text ("call:<card id>" for a monster call-out).
## tools/voices/build_lines.py lists every line; a line with no file is simply not spoken.

const FEMALE := ["akiza", "alexis", "mai", "student_girl", "stylish_woman", "vesper"]
const HAS_F := ["kind", "cocky", "cool"]
## What your own duelist says out loud (the rest stays a bubble, so they do not talk all the time).
const PLAYER_KINDS := ["intro", "ace", "ace_lost", "chain", "negate", "negated", "fusion", "synchro", "xyz", "ritual", "trap", "big_hit", "comeback", "win", "lose",
	"turn", "draw", "first", "second", "summon", "set_mon", "set", "spell", "battle", "attack", "direct", "end", "hurt", "hurt_big", "react", "destroyed", "low"]
## A line that waits its turn when somebody is already talking (the others are dropped instead).
const MUST := ["intro", "ace", "ace_lost", "fusion", "synchro", "xyz", "ritual", "win", "lose", "comeback"]
## How each personality names its ace as it hits the field.
const CALLS := {"kind": "Come on out, %s!", "cocky": "Behold! %s!", "cool": "%s. Go.", "wild": "Here it comes! %s!", "dark": "Rise... %s."}
## The monsters your duelist names when they hit the field.
const PLAYER_CALLS := [89631139, 46986414, 74677422, 38033121, 10000020, 10000000, 10000010, 5405694, 23995346, 70781052,
	78193831, 98502113, 77585513, 89943723, 35809262, 70095154, 1546123, 79856792, 44508094, 70902743, 73580471, 60800381,
	24696097, 84013237, 93717133, 99267150, 82301904, 72989439]

## What a duelist who remembers the last duel opens with: [you beat them, they beat you].
const REMATCH := {
	"kind": ["You beat me last time. I've been practicing!", "Back for another? I'd love to!"],
	"cocky": ["You again. Last time was a fluke.", "Back for more? I'll make it quick again."],
	"cool": ["You won last time. Not today.", "Again? Same result."],
	"wild": ["YOU! I want my rematch! Right now!", "Ha! Came back for another beating?"],
	"dark": ["I remember you. I remember losing. Never again.", "You return... to lose once more."],
}
## Lumen's voices, in the order of the setting: warm (the usual one), bright, calm.
const LUMEN_VOICES := ["lumen_b", "lumen", "lumen_c"]
## Your duelist's voices, in the order of the setting (after "fits my look"): male A, male B, female A, female B.
const MY_VOICES := ["player_m", "player_m2", "player_f", "player_f2"]
## What Lumen says when the game opens (once per start): any time, after a win, after a loss, and when
## she has new cards for you.
const HELLO := {
	"any": ["You're back! I kept your deck warm.", "There you are! Shall we duel?", "Hi! I was just counting our cards. Again.", "Oh good, it's you. I was getting bored."],
	"won": ["Still smiling about that last win. Let's get another!", "The winner is back! Who's next?"],
	"lost": ["The last one got away from us. Today we get it back.", "New day, new duel. That loss doesn't count anymore. I checked."],
	"news": ["Psst. I have new cards for you!"],
}
## What both duelists shout as the duel starts.
const DUEL := "Duel!"

static var _speaker: Speaker = null
static var greeted := false      # Lumen has said hello since the game started
## Dev (--voicelog): every line somebody tries to say is printed with what became of it.
static var _log := "--voicelog" in OS.get_cmdline_user_args()


static func _sp() -> Speaker:
	if _speaker == null or not is_instance_valid(_speaker):
		_speaker = Speaker.new()
		_speaker.name = "Voices"
		# Deferred: the tree may be in the middle of building a scene. Until the speaker is in, the
		# lines that matter wait and the others are let go (see Speaker.busy).
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_speaker)
	return _speaker


## The speaker is made when the game starts, so it is there for the first line.
static func warm() -> void:
	_sp()


static func _pitch(who: String) -> float:
	# Each duelist sits a hair higher or lower than the others who share the voice.
	if who == "lumen" or who == "player":
		return 1.0
	return 1.0 + float((abs(hash(who)) % 9) - 4) * 0.008


static func key_of(text: String) -> String:
	return text.md5_text().substr(0, 12)


## Which voice speaks for `who`: "lumen", "player" or a character's key. "" = nobody.
static func voice_for(who: String) -> String:
	if who == "narrator":
		return "narrator"
	if who == "lumen":
		return str(LUMEN_VOICES[int(Settings.voice_lumen)]) if int(Settings.voice_lumen) < LUMEN_VOICES.size() else ""
	if who == "player":
		var pick := int(Settings.voice_me)
		if pick >= 1 and pick <= MY_VOICES.size():
			return str(MY_VOICES[pick - 1])
		if pick > MY_VOICES.size():
			return ""
		return "player_f" if int(Profile.look_body) == 1 else "player_m"
	var pers := str(Characters.get_char(who).get("personality", ""))
	if pers == "":
		return ""
	return "%s_%s" % [pers, "f" if who in FEMALE and pers in HAS_F else "m"]


static func path_of(voice: String, key: String) -> String:
	return "res://voices/%s/%s/%s.ogg" % [Loc.lang(), voice, key]


## How long this line lasts out loud, in seconds. 0 when nobody will say it (voices off, or the
## line has no file in this language), so a scene can give a spoken line the room it needs.
static func length(who: String, text: String, mine := true) -> float:
	var voice := voice_for(who)
	var key := key_of(text)
	if text == "" or not _may(who, mine) or not has(voice, key):
		return 0.0
	var st := load(path_of(voice, key)) as AudioStream
	return st.get_length() / _pitch(who) if st != null else 0.0


static func has(voice: String, key: String) -> bool:
	return voice != "" and ResourceLoader.exists(path_of(voice, key))


static func _may(who: String, mine: bool) -> bool:
	if not Settings.voices_on or Settings.voice_volume <= 0.001:
		return false
	if who == "narrator":
		return true
	if who == "lumen":
		return int(Settings.voice_lumen) < LUMEN_VOICES.size()
	if mine:
		return int(Settings.voice_me) <= MY_VOICES.size()
	return Settings.voice_opp


## Speaks a line if there is a voice for it. `text` is the English line (or "call:<card id>").
## `mine`: your side of the table. `must`: wait for whoever is talking instead of staying quiet.
## True when the line will be heard.
static func say(who: String, text: String, mine := false, must := false) -> bool:
	var voice := voice_for(who)
	var key := key_of(text)
	if text == "" or not _may(who, mine) or not has(voice, key):
		if _log:
			print("VOICE %s [%s] \"%s\" -> %s" % [who, voice, text.left(48), "off" if not _may(who, mine) else ("NO FILE " + key)])
		return false
	var ok := _sp().take(path_of(voice, key), _pitch(who), must)
	if _log:
		print("VOICE %s [%s] \"%s\" -> %s" % [who, voice, text.left(48), ("said" if ok else "skipped (somebody is talking)") if not must else ("said or waiting" if ok else "skipped (two already waiting)")])
	return ok


## A line of a kind for a duelist: your own duelist only speaks the big ones.
static func say_kind(who: String, kind: String, text: String, mine := false) -> bool:
	if who == "player" and not (kind in PLAYER_KINDS or kind == "pick"):
		return false
	return say(who, text, mine, kind in MUST)


## The call-out for a monster hitting the field: [text for the bubble, text to speak], or [] when this
## duelist has none for that card.
static func call_line(who: String, card_id: int, attack := false) -> Array:
	var voice := voice_for(who)
	var spoken := ("atk:%d" if attack else "call:%d") % card_id
	if card_id <= 0 or not has(voice, key_of(spoken)):
		return []
	var nm := str(CardData.get_card(card_id).get("name", ""))
	if Loc.lang() == "es":
		var es := CardSearch.es_name(card_id)
		if es != "":
			nm = es
	if nm == "":
		return []
	if attack:
		# "Dark Magician, attack!" (your own duelist only, for the monsters in PLAYER_CALLS)
		return [("¡%s, ataca!" if Loc.lang() == "es" else "%s, attack!") % nm, spoken]
	if who == "player":
		return [("¡%s!" if Loc.lang() == "es" else "%s!") % nm, spoken]
	var pers := str(Characters.get_char(who).get("personality", ""))
	if not CALLS.has(pers):
		return []
	return [Loc.t(str(CALLS[pers])) % nm, spoken]


## The line a duelist opens with when they remember the last duel (English; "" when they have none).
## `last`: 1 = you beat them, -1 = they beat you, 0 = never met.
static func rematch_line(who: String, last: int) -> String:
	var pers := str(Characters.get_char(who).get("personality", ""))
	if last == 0 or not REMATCH.has(pers):
		return ""
	return str(REMATCH[pers][0 if last > 0 else 1])


## Lumen's hello when the game opens (English). `last`: 1 = you won your last duel, -1 = you lost it.
static func hello_line(last: int, news: bool) -> String:
	var pool: Array = HELLO["any"]
	if news:
		pool = HELLO["news"]
	elif last != 0 and randf() < 0.6:
		pool = HELLO["won"] if last > 0 else HELLO["lost"]
	return str(pool[randi() % pool.size()])


## The face-off before a duel: the music steps well back so the two voices own the moment.
static func focus(on: bool) -> void:
	if on and not Settings.voices_on:
		return
	if on or (_speaker != null and is_instance_valid(_speaker)):
		_sp().deep = on


## Both duelists shout the same line at once (the start of the duel). True when anybody is heard.
static func shout(me: String, opp: String, text: String) -> bool:
	var key := key_of(text)
	var mine := voice_for(me)
	var theirs := voice_for(opp)
	var a := path_of(mine, key) if _may(me, true) and has(mine, key) else ""
	var b := path_of(theirs, key) if _may(opp, false) and has(theirs, key) else ""
	if _log:
		print("VOICE shout \"%s\" me [%s] %s, them [%s] %s" % [text, mine, "yes" if a != "" else "no", theirs, "yes" if b != "" else "no"])
	if a == "" and b == "":
		return false
	_sp().both(a, _pitch(me), b, _pitch(opp))
	return true


## Nobody says anything more (the duel is over, or the scene is leaving).
static func hush(cut := false) -> void:
	if _speaker != null and is_instance_valid(_speaker):
		_speaker.hush(cut)


## The one who actually talks: one line at a time, the next ones wait a moment, and the music
## steps back a little while somebody is speaking.
class Speaker extends Node:
	const DUCK_DB := -5.0
	const DEEP_DB := -11.0
	var deep := false             # the face-off: the music stays low between the lines too
	var _player: AudioStreamPlayer
	var _second: AudioStreamPlayer      # the other voice of a shout
	var _queue: Array = []        # [path, pitch, good until (seconds)]
	var _duck := 0.0
	var _t := 0.0
	var _quiet_until := 0.0       # the breath after a line: nobody starts before it is over
	var _was_busy := false
	var _second_due := false      # the other voice of a shout is about to come in

	## Somebody is talking (or just stopped, or is about to): nothing else may start now.
	func busy() -> bool:
		return not is_inside_tree() or _player.playing or _second.playing or _second_due or _t < _quiet_until

	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_player = AudioStreamPlayer.new()
		add_child(_player)
		_second = AudioStreamPlayer.new()
		add_child(_second)

	func _enter_tree() -> void:
		_player.bus = "Voice" if AudioServer.get_bus_index("Voice") >= 0 else "SFX"
		_second.bus = _player.bus

	## Two voices at once, the second a breath behind the first so they do not sound like one.
	func both(a: String, pa: float, b: String, pb: float) -> void:
		if not is_inside_tree():
			return
		_queue.clear()
		_player.stop()
		_second.stop()
		if a != "":
			_start(a, pa)
		if b != "":
			var s = load(b)
			if s is AudioStream:
				_second.stream = s
				_second.pitch_scale = pb
				if a == "":
					_second.play()
				else:
					_second_due = true
					get_tree().create_timer(0.06).timeout.connect(func():
						_second_due = false
						_second.play())

	func take(path: String, pitch: float, must: bool) -> bool:
		if busy():
			if not must or _queue.size() >= 2:
				return false
			_queue.append([path, pitch, _t + 4.0])
			return true
		return _start(path, pitch)

	func _start(path: String, pitch: float) -> bool:
		var s = load(path)
		if not (s is AudioStream):
			return false
		_player.stream = s
		_player.pitch_scale = pitch
		_player.play()
		return true

	func hush(cut: bool) -> void:
		_queue.clear()
		deep = false
		if cut:
			_player.stop()
			_second.stop()

	func _process(delta: float) -> void:
		_t += delta
		# One voice at a time, with a breath between two lines.
		var talking := _player.playing or _second.playing or _second_due
		if _was_busy and not talking:
			_quiet_until = _t + 0.22
		_was_busy = talking
		while not busy() and not _queue.is_empty():
			var q: Array = _queue.pop_front()
			if _t <= float(q[2]):
				_start(str(q[0]), float(q[1]))
		# The music gives the voice room, and comes back when it is done.
		var want := DEEP_DB if deep else (DUCK_DB if _player.playing or _second.playing else 0.0)
		if not is_equal_approx(_duck, want):
			_duck = move_toward(_duck, want, delta * (30.0 if want < _duck else 9.0))
			var idx := AudioServer.get_bus_index("Music")
			if idx >= 0 and Settings.music_volume > 0.001:
				AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(Settings.music_volume, 0.0001)) + _duck)
