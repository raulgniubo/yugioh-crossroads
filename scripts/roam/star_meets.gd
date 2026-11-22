class_name StarMeets
extends RefCounted
## What the main characters do with each other and with you, on top of their day (StarLife):
## the duels they have with one another, and what they say when they come looking for you,
## ask you to meet them somewhere, or tell you how their own duel went.

## How long a meeting holds its two duelists (walking there, the duel, a word after), in
## minutes of the world's clock.
const WINDOW := 150

## The duels of the day in each world: when, who (one pair per day, taking turns by the day),
## and the middle of the spot. They stand 3.3 m either side of it, facing each other along x.
const MEETS := {
	"domino": [
		{"at": 900, "pairs": [["yugi", "joey"], ["joey", "mai"]], "mid": Vector3(18.5, 0, 25.5), "fan_z": 2.4},
		{"at": 1140, "pairs": [["kaiba", "yugi"], ["kaiba", "joey"]], "mid": Vector3(18.5, 0, 25.5), "fan_z": 2.4},
	],
	"academy": [
		{"at": 660, "pairs": [["jaden", "chazz"], ["jaden", "alexis"]], "mid": Vector3(0.0, 0, -1.5), "fan_z": 2.7},
		{"at": 1080, "pairs": [["alexis", "chazz"], ["chazz", "jaden"]], "mid": Vector3(0.0, 0, -1.5), "fan_z": 2.7},
	],
	"satellite": [
		{"at": 840, "pairs": [["yusei", "crow"]], "mid": Vector3(0.0, 0, 0.0), "fan_z": 2.7},
	],
	"newdomino": [
		{"at": 900, "pairs": [["jack", "akiza"]], "mid": Vector3(20.0, 0, 24.0), "fan_z": 2.6},
	],
	"heartland": [
		{"at": 840, "pairs": [["yuma", "shark"], ["yuma", "kite"]], "mid": Vector3(0.0, 0, 0.0), "fan_z": 2.7},
		{"at": 1140, "pairs": [["kite", "shark"], ["shark", "yuma"]], "mid": Vector3(0.0, 0, 0.0), "fan_z": 2.7},
	],
}

## More of what they say, all of it ours. "bout_won" / "bout_lost": about their own duel today
## (%s is who it was against). "busy": you talk to them in the middle of it. "dare": they came
## to find you because you keep winning. "invite": come and meet me (%s place, %s hour).
## "met": you came. "missed": you did not. "bond2" / "bond4": the day they start calling you
## a friend (or a rival), and the day there is nobody they think more of.
const MORE := {
	"yugi": {"bout_won": "I got past %s today, but only just. One card either way.", "bout_lost": "%s beat me today. I misread one turn and that was all it took.",
		"busy": "Sorry, {player}, I am in the middle of a duel! Stay and watch?", "dare": "{player}! They say you cannot lose right now. Would you show me?",
		"invite": "Come find me at %s around %s. I want to show you a card I just found.", "met": "You came! Here, this is the card I told you about. I think it belongs with you.",
		"missed": "I waited for you the other day. It is all right. Next time.",
		"bond2": "You know, I think of you as a friend now. I hope that is all right.", "bond4": "Whatever happens out here, {player}, you have a friend in me. Always."},
	"joey": {"bout_won": "Didja see me take down %s? Tell me ya saw it!", "bout_lost": "%s got me today. I'm callin' it a warm-up.",
		"busy": "Not now, {player}! I'm in a duel here! Watch and learn!", "dare": "Yo, {player}! Word is ya can't lose. Let's fix that!",
		"invite": "Swing by %s around %s. I got somethin' for ya. Don't be late!", "met": "Ya made it! Here, pulled this one and thought of ya. Don't say I never gave ya nothin'.",
		"missed": "Hey, I waited for ya! ...It's fine. I ate your half too.",
		"bond2": "Ya know what? You're all right, {player}. We're pals now. No take-backs.", "bond4": "You and me, {player}? Best buds. Anybody messes with ya, they mess with me."},
	"mai": {"bout_won": "%s never stood a chance. I almost felt bad. Almost.", "bout_lost": "%s got lucky today. Do not bring it up again.",
		"busy": "Can you not see I am busy, hon? Watch. You might learn something.", "dare": "{player}. I hear nobody can beat you lately. I am not nobody.",
		"invite": "Be at %s around %s. I do not wait long, so be on time.", "met": "On time. I like that. Here, a spare. It does not match my deck anyway.",
		"missed": "You kept me waiting, and then you did not show. Bold. Do not do it twice.",
		"bond2": "Do not let it go to your head, but I have decided you are worth a real rivalry.", "bond4": "There are very few people I would call my equal. Congratulations, hon. You made the list."},
	"kaiba": {"bout_won": "%s lasted longer than I expected. It changed nothing.", "bout_lost": "%s won. Today. I have already found the flaw.",
		"busy": "I am dueling. Stand back and stay quiet.", "dare": "{player}. Your record says you are worth five minutes. Prove it.",
		"invite": "%s. %s. Be there. I have something to test and you will do.", "met": "You are punctual. Take this. I have no use for it, and I want to see what you do with it.",
		"missed": "You did not come. I do not make offers twice. ...Usually.",
		"bond2": "I have filed you under rivals. It is a short file. Do not waste the entry.", "bond4": "You are the opponent I measure myself against now. Do not ever tell anyone I said that."},
	"jaden": {"bout_won": "Did you see my duel with %s? That last turn was so sweet!", "bout_lost": "%s got me good today! I cannot wait to try again.",
		"busy": "Hang on, {player}, I am mid-duel! Watch this next draw!", "dare": "{player}! You are on a hot streak! I have GOT to duel you right now!",
		"invite": "Hey, meet me at %s around %s! I found something cool.", "met": "You made it! Check it out, I pulled this and it is not really my style. It is yours now!",
		"missed": "Aw, I waited for you! No big deal. I fell asleep anyway.",
		"bond2": "We have dueled enough that we are basically friends now, right? Sweet!", "bond4": "You are one of my best friends, {player}! Let us keep dueling forever, okay?"},
	"chazz": {"bout_won": "I crushed %s. As expected. You may applaud.", "bout_lost": "%s cheated. I do not know how yet. But I will.",
		"busy": "Quiet! The Chazz is dueling!", "dare": "You. Everyone keeps saying your name. Time they went back to saying mine.",
		"invite": "Come to %s around %s. Do not make me repeat myself.", "met": "Hmph. You showed up. Here. It was cluttering my collection. That is the only reason.",
		"missed": "You stood up the Chazz. Nobody stands up the Chazz.",
		"bond2": "Fine. You may call yourself my rival. A junior rival. On probation.", "bond4": "Listen. You are the only one who keeps up with the Chazz. That makes you my rival. THE rival."},
	"alexis": {"bout_won": "I beat %s today. It was closer than it looked from the side.", "bout_lost": "%s outplayed me today. I know exactly where, too.",
		"busy": "Give me a moment, {player}. I am in a duel.", "dare": "{player}. You are in form, and I want to test myself against it.",
		"invite": "Could you meet me at %s around %s? There is something I would like you to have.", "met": "Thank you for coming. This card never fit my deck, but it might fit yours.",
		"missed": "I waited a while the other day. I assume something came up.",
		"bond2": "I have come to count you as a friend, {player}. That does not happen quickly with me.", "bond4": "You are one of the people I trust most on this island. I wanted you to know that."},
	"yusei": {"bout_won": "%s pushed me hard today. That is the kind of duel that makes a deck better.", "bout_lost": "%s won today. Fair and clean. I will adjust.",
		"busy": "In a duel, {player}. Stay if you want.", "dare": "{player}. You have not lost in a while. I would like to see why.",
		"invite": "Come by %s around %s. I rebuilt something and I want your opinion.", "met": "Good, you are here. Take this. A good part should be used, not shelved.",
		"missed": "You did not make it the other day. No problem. Things come up.",
		"bond2": "I do not say this often. I consider you a friend.", "bond4": "A bond like this does not break, {player}. Whatever you need, I am there."},
	"crow": {"bout_won": "Ha! Did you see the look on %s? I still got it!", "bout_lost": "%s got me today. Do not tell the kids.",
		"busy": "Bit busy, {player}! Duel in progress! Cheer for me!", "dare": "{player}! I hear you are unbeatable lately. I love a rumor I can break!",
		"invite": "Meet me at %s around %s. Got a little something for you.", "met": "There you are! Here, found this on a delivery run. Finders keepers, and I am passing it on.",
		"missed": "Hey, I waited for you! The kids ate your share.",
		"bond2": "You are one of us now, {player}. The kids already voted.", "bond4": "Family is who shows up. You show up. That makes you family."},
	"jack": {"bout_won": "%s fell before the King. Was there ever any doubt?", "bout_lost": "%s won a duel. The King allowed it. For drama.",
		"busy": "Silence! A King's duel is not to be interrupted!", "dare": "You! They speak of your streak as if it rivals mine. Come. Be corrected.",
		"invite": "Attend me at %s around %s. The King has a gift, and it is rude to refuse.", "met": "You came. As you should. Take this. A King rewards loyalty.",
		"missed": "You kept a King waiting. I drank your coffee as well as my own.",
		"bond2": "The King acknowledges you as a rival. Few receive the honor. Fewer survive it.", "bond4": "Hear this once: you are the rival the King has been waiting for. Now forget I said it and duel me."},
	"akiza": {"bout_won": "I won against %s. I held back as much as I could.", "bout_lost": "%s beat me today. It was... nice, to lose and have nothing break.",
		"busy": "Please step back, {player}. I am dueling, and it is safer.", "dare": "{player}. You keep winning. I would like to know how that feels from the other side.",
		"invite": "Would you come to %s around %s? I have something for you. If you want it.", "met": "You came. I was not sure you would. This is for you. I grew tired of it sitting alone.",
		"missed": "I waited. It is all right. People usually do not come.",
		"bond2": "I think... we are friends. I would like that, if you would.", "bond4": "You stayed. Nobody stays. Thank you, {player}. I will not forget it."},
	"yuma": {"bout_won": "I beat %s! Did you see?! I was feeling the flow the whole time!", "bout_lost": "%s won today! But I almost had it! Next time for sure!",
		"busy": "{player}! I am dueling! Watch me, watch me!", "dare": "{player}! You keep winning and winning! Duel me! I am going to jet right past you!",
		"invite": "Hey! Come to %s around %s! I have a surprise!", "met": "You came! Ta-da! I had two of these, so one is yours!",
		"missed": "I waited for you forever! Well, ten minutes. It felt like forever!",
		"bond2": "We are friends now! Friends who duel are the best kind of friends!", "bond4": "You are my best friend, {player}! When we duel I feel like I can do anything!"},
	"shark": {"bout_won": "%s went under. That is all there is to say.", "bout_lost": "%s won. Do not make a thing of it.",
		"busy": "Busy. Watch or walk.", "dare": "You. Undefeated, they say. Let us see how you swim in deep water.",
		"invite": "%s. Around %s. Come or do not.", "met": "You showed. Here. I do not need it.",
		"missed": "You did not show. Whatever.",
		"bond2": "You are all right. That is as much as you are getting.", "bond4": "I do not have many people. You are one of them. Do not make it weird."},
	"kite": {"bout_won": "%s lost. The outcome was never in question.", "bout_lost": "%s won. I have logged every turn of it.",
		"busy": "I am engaged. Observe from a distance.", "dare": "{player}. Your results make you a target. Mine.",
		"invite": "Be at %s around %s. I have something that is of more use to you than to me.", "met": "You are on time. Take it. Do not thank me.",
		"missed": "You were absent. Noted.",
		"bond2": "I have reclassified you. From target to rival. Take it as intended.", "bond4": "There are two people whose strength I respect. You are the other one."},
}


## Today's duels in a world: [{at, a, b, mid, fan_z}], the pair being the one whose turn it is.
static func today(district: String, day: int) -> Array:
	var out: Array = []
	for m in MEETS.get(district, []):
		var pairs: Array = m["pairs"]
		var pair: Array = pairs[posmod(day, pairs.size())]
		out.append({"at": int(m["at"]), "a": str(pair[0]), "b": str(pair[1]), "mid": m["mid"], "fan_z": float(m["fan_z"])})
	return out


## Somebody's day with today's duels worked in: at the hour of a duel they go to their side of
## the spot, and when the meeting is over they pick their day up where the clock has it.
static func day_with(district: String, id: String, stops: Array, day: int) -> Array:
	var out: Array = stops.duplicate()
	for m in today(district, day):
		if id != str(m["a"]) and id != str(m["b"]):
			continue
		var first := id == str(m["a"])
		var from := int(m["at"])
		var until := from + WINDOW
		var mid: Vector3 = m["mid"]
		var spot := mid + Vector3(-3.3 if first else 3.3, 0, 0)
		# What they would have been at when it ends.
		var back: Array = out[out.size() - 1]
		for st in out:
			if int(st[0]) <= until:
				back = st
		var next: Array = []
		for st in out:
			if int(st[0]) < from:
				next.append(st)
		next.append([from, spot, PI / 2.0 if first else -PI / 2.0, "duel"])
		next.append([until, back[1], back[2], back[3]])
		for st in out:
			if int(st[0]) > until:
				next.append(st)
		out = next
	return out


## A place the way you say it in a sentence: "the Main Hall", but "Burger World". (English; the
## table of the language turns "the Main Hall" into its own words, article and all.)
const BARE := ["Burger World", "Kame Game", "Cafe La Geen", "Central Park", "Central Plaza", "Heartland Tower", "KaibaCorp Plaza", "KaibaCorp Tower", "New Domino Stadium", "Domino Mart", "Kaiba Dome"]

static func place_say(place: String) -> String:
	return place if place in BARE or place.begins_with("The ") else "the " + place


## An invitation with its place and hour in (the same words the voice file is named after).
## `shown`: in the language on screen. A line that opens with the place gets its capital letter.
static func invite_text(tpl: String, place: String, hour: String, shown := false) -> String:
	var where := place_say(place)
	if shown and Loc.lang() != "en":
		# ("@Main Hall" is the place with its article: "el Salón Principal".)
		var said := Loc.t("@" + place)
		where = said if said != "@" + place else Loc.t(place)
	if tpl.begins_with("%s") and where != "":
		where = where[0].to_upper() + where.substr(1)
	return tpl % [where, hour]


## The hour as people say it: "9:30", not "09:30".
static func hour_text(minutes: float) -> String:
	return "%d:%02d" % [int(minutes) / 60, int(minutes) % 60]


## One landmark name for a spot: the place it is at or nearest to.
static func place_near(district: Dictionary, p: Vector3) -> String:
	var best := ""
	var best_d := 1e9
	var m: Dictionary = district.get("map", {})
	for lm in m.get("landmarks", RoamMap.LANDMARKS):
		var c: Vector2 = lm["pos"]
		var hs: Vector2 = (lm["size"] as Vector2) / 2.0
		var q := Vector2(absf(p.x - c.x) - hs.x, absf(p.z - c.y) - hs.y)
		var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length()
		if lm.get("park", false):
			d += 3.0
		if d < best_d:
			best_d = d
			best = str(lm["name"])
	return best
