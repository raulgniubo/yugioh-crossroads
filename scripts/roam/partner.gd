class_name Partner
extends Node
## Lumen in the open world: she floats at your shoulder wherever you walk, looks at what
## interests her, says what she thinks, and tells you what to do next when you ask (L, or
## D-pad up). In a story chapter the director takes over her part; this is for everything else.

static var _greeted := {}        # worlds she has already said hello to (this session)
static var note := ""            # "won" / "lost": the duel you just came back from

var scene                        # RoamScene
var spirit: LumenSpirit
var away := false                # the Curator has her (between chapter 4 and the ending)
var _t := 0.0
var _quiet := 4.0                # seconds before she may speak again
var _still := 0.0                # how long you have stood still
var _visit = null                # something she has drifted over to look at (Vector3)
var _visit_t := 0.0
var _seen := {}                  # duelists she has already had an opinion about
var _asked := 0.0                # when you last asked her something
var _ask_n := 0
var _last_tod := ""
var _bubble: LumenBubble
var _last_pos := Vector3.ZERO

const HELLO := {
	"domino": ["Home! I like home. The card shop smells like new packs.", "Domino. Everything started on this street. *bzzt* I think."],
	"academy": ["An island school where the only subject is dueling. Why did nobody send ME here?", "I can hear the sea! And somebody losing a duel. Listen."],
	"newdomino": ["Everything is so clean here. I feel like I should wipe my feet. I don't have feet.", "Look up. That ring in the sky is a road. People DUEL on it."],
	"satellite": ["It's rusty and loud and I love it. Don't tell New Domino.", "Careful where you step. Half of this place is somebody's future Duel Runner."],
	"heartland": ["Balloons! Robots! A tower shaped like a heart! This city tries very hard and I respect it.", "Everybody here is so cheerful. It's a little suspicious. In a nice way."],
}
const IDLE := [
	"Are we waiting for something? I'm good at waiting. I waited in a deck box for fifty years.",
	"If you press L, I'll tell you what I'd do next. I always have an opinion.",
	"I counted the cards in your deck again. Still all there. Just checking.",
	"Do you ever forget a word and it goes *bzzt*? No? Just me?",
	"You know what would be nice right now? A duel. I'm just saying.",
	"When you summon me, I go and find one of your monsters for you. I'm basically a librarian. A cute one.",
	"I like it when you win. I also like it when you lose and then go again. That one might be my favorite.",
]
const NIGHT := ["It got dark. I glow, though. You're welcome.", "Night time. The strong ones come out at night. I read that somewhere. *bzzt* Or I made it up."]
const RAIN := ["Rain! I don't get wet. I just get staticky. *bzzt*", "It's raining. Stand under something. I'll hover dramatically."]
const WON := ["You WON! I helped. I was floating very supportively.", "That's how it's done! Did you see their face?", "One more for the Echo Deck. I'm so proud I could glitch."]
const LOST := ["Okay. So that happened. Again! Go again!", "They got lucky. Probably. Rematch?", "Losing is just winning that isn't finished yet. I should know."]
const STRONG := ["Careful. That one feels strong. I'm going to stand behind you.", "Um. That duelist has a scary deck. I can hear it from here."]
const EASY := ["That one looks beatable. Probably. I think.", "Ooh, a duelist! Go say hi with your deck."]
const BEATEN := ["You already beat that one. They still look a little mad about it.", "Old opponent. Wave! ...Or don't. They're glaring."]
const SHINY := ["Ooh. Something shiny over there.", "I see a Star Chip! Go go go!"]


func setup(roam) -> void:
	scene = roam
	away = not LumenBubble.with_you()
	_build_bubble()
	if away:
		return
	spirit = LumenSpirit.new()
	scene.add_child(spirit)
	spirit.watch = scene._player
	spirit.set_bonds(StoryProgress.bonds())
	spirit.global_position = _home()
	scene.partner = spirit
	_last_pos = scene._player.global_position
	_last_tod = str(scene.city.tod) if scene.city else ""
	var key := str(Router.roam.get("district", "domino"))
	_hide_lost_card()
	if note != "":
		_queue(WON if note == "won" else LOST, 1.6)
		spirit.mood = "happy" if note == "won" else "calm"
		note = ""
	elif not _greeted.has(key) and HELLO.has(key):
		_greeted[key] = true
		_queue(HELLO[key], 2.6)
	elif scene.weather and scene.weather.raining and randf() < 0.5:
		_queue(RAIN, 3.0)


# ------------------------------------------------------------------ the lost card of the day
# Once a day, in every world, a card is lying somewhere along the streets. Lumen can feel it
# when you get close and flies toward it. Walk into it and it is yours.

var _lost: Node3D
var _lost_called := false

const FEEL := ["I can feel a lost card somewhere close! This way, follow me!", "Something is calling from over there. A card! A lonely one!"]


func _hide_lost_card() -> void:
	var routes: Array = scene.district.get("routes", [])
	var key := "lost_card_" + str(Router.roam.get("district", "domino"))
	if routes.is_empty() or str(Collection.record.get(key, "")) == Time.get_date_string_from_system():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Time.get_date_string_from_system() + key)
	var seg: Array = routes[rng.randi() % routes.size()]
	var at: Vector3 = (seg[0] as Vector3).lerp(seg[1], rng.randf_range(0.15, 0.85))
	_lost = Node3D.new()
	_lost.position = Vector3(at.x, 1.05, at.z)
	scene.add_child(_lost)
	var card := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.61, 0.012)
	card.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c9f3ff")
	m.emission_enabled = true
	m.emission = Color("7fe8ff")
	m.emission_energy_multiplier = 1.8
	card.material_override = m
	_lost.add_child(card)
	var l := OmniLight3D.new()
	l.light_color = Color("7fe8ff")
	l.light_energy = 1.4
	l.omni_range = 5.0
	_lost.add_child(l)


func _lost_card_tick(delta: float, pp: Vector3) -> void:
	if _lost == null or not is_instance_valid(_lost):
		return
	_lost.rotation.y += delta * 1.8
	_lost.position.y = 1.05 + sin(_t * 2.0) * 0.1
	var d := Vector2(_lost.position.x - pp.x, _lost.position.z - pp.z).length()
	if d < 1.3 and scene._inside == "":
		var prize := _rare_pick()
		Collection.record["lost_card_" + str(Router.roam.get("district", "domino"))] = Time.get_date_string_from_system()
		if prize != 0:
			Collection.owned[prize] = mini(3, int(Collection.owned.get(prize, 0)) + 1)
			Router.toast(Loc.t("Lumen found a lost card: %s!") % Loc.t(str(CardData.get_card(prize).get("name", ""))))
		Collection.dp += 100
		Collection.save()
		Sfx.play("rare")
		_lost.queue_free()
		_lost = null
		_visit = null
		spirit.look_at_point = null
		spirit.mood = "happy"
		spirit.spin()
		say("We found it! It's yours now. Check your collection!")
		return
	if d < 26.0 and scene._inside == "" and not _busy():
		if not _lost_called and _quiet <= 0.0:
			_lost_called = true
			say(FEEL[randi() % FEEL.size()], 5.0)
			spirit.mood = "curious"
		if _lost_called:
			# She leads: a few steps ahead of you, toward it.
			_visit = Vector3(_lost.position.x, 1.2, _lost.position.z)
			_visit_t = 1.0
			spirit.look_at_point = _lost.position


## A rare card you do not have three of yet.
func _rare_pick() -> int:
	var ids: Array = CardData.EXT.keys()
	if ids.is_empty():
		return 0
	for i in 300:
		var id := int(ids[randi() % ids.size()])
		if CardData.rarity(id) >= 2 and int(Collection.owned.get(id, 0)) < 3 and not CardData.is_extra(id):
			return id
	return 0


func _home() -> Vector3:
	var p: Vector3 = scene._player.global_position
	return p + Basis(Vector3.UP, scene._yaw) * Vector3(0.78, 0, 0.55) + Vector3(0, 1.25, 0)


func _queue(lines: Array, delay: float) -> void:
	var line := str(lines[randi() % lines.size()])
	get_tree().create_timer(delay).timeout.connect(func(): say(line))


## She says something: a small box at the bottom left with her face on it.
func say(line: String, hold := 0.0) -> void:
	if not is_instance_valid(_bubble):
		return
	_bubble.say(line, hold)
	_quiet = 14.0
	if spirit and is_instance_valid(spirit):
		spirit.speak(1.8)
		if "*bzzt*" in line:
			spirit.glitch(0.3)


func _build_bubble() -> void:
	_bubble = LumenBubble.new()
	add_child(_bubble)


func _busy() -> bool:
	return scene._overlay_open or scene._talking or (scene.story != null)


func _unhandled_input(event: InputEvent) -> void:
	if _busy():
		return
	var asked: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L
	asked = asked or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_UP)
	if asked:
		get_viewport().set_input_as_handled()
		ask()


## You ask her. The first time she says what to do next; ask again and she just talks.
func ask() -> void:
	if away:
		say("(Lumen is not here. The Curator has her. Story: the final chapter is waiting in the main menu.)", 5.0)
		return
	var again := _t - _asked < 9.0
	_asked = _t
	_ask_n = _ask_n + 1 if again else 0
	if _ask_n % 3 == 1:
		# What is on for today.
		var parts: Array = []
		for row in Collection.daily_rows():
			parts.append("%s (%d/%d)" % [Loc.t(str(row["name"])).trim_prefix(Loc.t("Today: ")), int(row["have"]), int(row["goal"])])
		say(Loc.t("Today's challenges: %s. They are in your quest list, press J.") % ", ".join(PackedStringArray(parts)), 7.0)
		return
	if _ask_n % 3 == 2:
		say(IDLE[randi() % IDLE.size()])
		spirit.hop()
		return
	say(_what_next(), 6.0)
	spirit.spin()


func _what_next() -> String:
	# The story first, if a chapter is waiting.
	var unlocked: Array = StoryProgress.unlocked()
	var next := ""
	for ch in StoryData.CHAPTERS:
		if unlocked.has(ch["id"]):
			next = Loc.t(str(ch["title"])) + ": " + Loc.t(str(ch["name"]))
	if not StoryProgress.recalls("finished") and next != "" and randf() < 0.5:
		return Loc.t("The story is waiting: %s. Open Story from the main menu when you're ready.") % next
	# Otherwise: the nearest duelist here you have not beaten yet. She points the way.
	var best := 1e9
	var who: Array = []
	var left := 0
	for n in scene._npcs:
		var d: Dictionary = n[0]
		if not d.has("duel") or scene._beaten.has(d["id"]):
			continue
		left += 1
		var dist: float = (n[1] as Node3D).global_position.distance_to(scene._player.global_position)
		if dist < best:
			best = dist
			who = n
	if not who.is_empty():
		var nm: String = scene._npc_name(who[0])
		if scene.extras and scene._inside == "":
			scene.extras.set_waypoint((who[1] as Node3D).global_position, nm)
		return Loc.t("There are %d duelists here you haven't beaten. The nearest is %s. I put a beacon on them. Follow me!") % [left, nm]
	if next != "" and not StoryProgress.recalls("finished"):
		return Loc.t("The story is waiting: %s. Open Story from the main menu when you're ready.") % next
	return Loc.t("You've beaten everyone here! Press G and pick another world. Or open a few packs. I like watching you open packs.")


func _process(delta: float) -> void:
	_t += delta
	if away or spirit == null or not is_instance_valid(spirit):
		return
	# A story chapter has its own Lumen.
	spirit.visible = scene.story == null
	if scene.story != null:
		return
	var pp: Vector3 = scene._player.global_position
	var moved := pp.distance_to(_last_pos)
	_last_pos = pp
	_still = _still + delta if moved < 0.01 else 0.0
	_quiet -= delta
	_lost_card_tick(delta, pp)
	# Where she wants to be.
	var want := _home()
	if _visit != null:
		_visit_t -= delta
		var v: Vector3 = _visit
		var from_you := Vector3(v.x - pp.x, 0, v.z - pp.z)
		if _visit_t < 0.0 or from_you.length() > 9.0:
			_visit = null
			spirit.look_at_point = null
			spirit.mood = "calm"
		else:
			want = pp + from_you.normalized() * minf(from_you.length() - 1.0, 2.6) + Vector3(0, 1.3, 0)
			if spirit.mood == "scared":
				# Behind you, peeking out.
				want = pp - from_you.normalized() * 0.7 + Vector3(0, 1.1, 0)
	var sp := spirit.global_position
	if sp.distance_to(want) > 12.0:
		spirit.global_position = want
	else:
		spirit.global_position = sp.lerp(want, clampf(delta * (3.2 if _visit == null else 2.0), 0.0, 1.0))
	if _busy() or _quiet > 0.0:
		return
	# Things worth a word.
	var tod := str(scene.city.tod) if scene.city else ""
	if tod != _last_tod:
		_last_tod = tod
		if tod == "night":
			say(NIGHT[randi() % NIGHT.size()])
			return
	for n in scene._npcs:
		var d: Dictionary = n[0]
		if not d.has("duel") or _seen.has(d["id"]):
			continue
		var np: Vector3 = (n[1] as Node3D).global_position
		if np.distance_to(pp) < 6.0:
			_seen[d["id"]] = true
			_visit = np + Vector3(0, 1.4, 0)
			_visit_t = 5.0
			spirit.look_at_point = np + Vector3(0, 1.4, 0)
			var hard := int((d["duel"] as Dictionary).get("difficulty", 1)) >= 3
			if scene._beaten.has(d["id"]):
				say(BEATEN[randi() % BEATEN.size()])
			elif hard:
				spirit.mood = "scared"
				say(STRONG[randi() % STRONG.size()])
			else:
				spirit.mood = "curious"
				say(EASY[randi() % EASY.size()])
			return
	if scene.extras and scene._inside == "":
		for c in scene.extras._chips:
			var cp: Vector3 = c["pos"]
			if not _seen.has("chip%d" % int(c["idx"])) and cp.distance_to(pp) < 9.0 and is_instance_valid(c["node"]) and (c["node"] as Node3D).visible:
				_seen["chip%d" % int(c["idx"])] = true
				_visit = cp + Vector3(0, 1.0, 0)
				_visit_t = 4.0
				spirit.look_at_point = cp + Vector3(0, 1.0, 0)
				spirit.mood = "happy"
				say(SHINY[randi() % SHINY.size()])
				return
	if _still > 24.0:
		_still = 0.0
		say(IDLE[randi() % IDLE.size()])
		spirit.hop()
