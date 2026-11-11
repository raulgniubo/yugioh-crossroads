class_name Characters
extends RefCounted
## Duelists: who they are, their deck, their ace and what they say.

const ORDER := ["yugi", "kaiba", "joey", "jaden", "yusei", "yuma"]

const DATA := {
	"yugi": {
		"name": "Yugi Muto", "short": "Yugi", "era": "Duel Monsters", "color": Color("8a4dff"),
		"title": "King of Games", "deck": "yugi", "ace": 46986414, "wiki": "Yugi Muto",
		"lines": {
			"intro": ["Let's see what kind of duelist you are.", "I'm ready. Let's duel!"],
			"turn": ["My turn. I draw!", "The cards won't let me down."],
			"ace": ["Dark Magician, I summon you!", "My most trusted monster!"],
			"attack": ["Dark Magic Attack!", "Go, attack directly!"],
			"hurt": ["That was a good move...", "I'm not done yet!"],
			"win": ["That was a great duel. Let's do it again sometime."],
			"lose": ["You won fair and square. Well played!"],
		},
	},
	"kaiba": {
		"name": "Seto Kaiba", "short": "Kaiba", "era": "Duel Monsters", "color": Color("3a86ff"),
		"title": "CEO of Kaiba Corp", "deck": "kaiba", "ace": 89631139, "wiki": "Seto Kaiba",
		"lines": {
			"intro": ["You're wasting my time. Let's get this over with.", "Prepare to lose to a real duelist."],
			"turn": ["My turn. Watch closely.", "Draw!"],
			"ace": ["Behold, the Blue-Eyes White Dragon!", "Witness true power!"],
			"attack": ["Burst Stream of Destruction!", "Crush them!"],
			"hurt": ["A lucky hit. Nothing more.", "Don't get cocky."],
			"win": ["As expected. Come back when you're worth my time."],
			"lose": ["Hmph. This isn't over."],
		},
	},
	"joey": {
		"name": "Joey Wheeler", "short": "Joey", "era": "Duel Monsters", "color": Color("ff8a3a"),
		"title": "The Underdog", "deck": "joey", "ace": 74677422, "wiki": "Joey Wheeler",
		"lines": {
			"intro": ["Alright, let's throw down!", "Ya ready? 'Cause I'm fired up!"],
			"turn": ["My draw! Come on, come on...", "Here goes nothin'!"],
			"ace": ["Red-Eyes, show 'em what you got!", "Now that's what I'm talkin' about!"],
			"attack": ["Inferno Fire Blast!", "Take that!"],
			"hurt": ["Ow! Hey, that one stung!", "No way I'm goin' down like this!"],
			"win": ["Yeah! Who's the man? Joey's the man!"],
			"lose": ["Aw man... rematch, right now!"],
		},
	},
	"jaden": {
		"name": "Jaden Yuki", "short": "Jaden", "era": "GX", "color": Color("ff3a4d"),
		"title": "Slifer Red Ace", "deck": "jaden", "ace": 35809262, "wiki": "Jaden Yuki",
		"lines": {
			"intro": ["Get your game on!", "This is gonna be fun!"],
			"turn": ["My turn! Let's see what I've got.", "Draw! Oh, sweet!"],
			"ace": ["Fusion time! Elemental HEROes, unite!", "Now we're talking!"],
			"attack": ["Go, HERO, take 'em down!", "Skyscraper Shoot!"],
			"hurt": ["Whoa, nice one!", "Okay, now I'm really having fun."],
			"win": ["Gotcha! That's game!"],
			"lose": ["Ha, you got me! Great duel."],
		},
	},
	"yusei": {
		"name": "Yusei Fudo", "short": "Yusei", "era": "5D's", "color": Color("2de2e6"),
		"title": "The Satellite's Hope", "deck": "yusei", "ace": 44508094, "wiki": "Yusei Fudo",
		"lines": {
			"intro": ["Let's ride.", "Show me your bonds."],
			"turn": ["My turn. Draw.", "I won't give up."],
			"ace": ["Clustering wishes become a new shining star!", "Take flight, Stardust Dragon!"],
			"attack": ["Shooting Sonic!", "Go!"],
			"hurt": ["Not bad.", "I can still turn this around."],
			"win": ["Good duel. You've got heart."],
			"lose": ["You earned that. I'll be stronger next time."],
		},
	},
	"yuma": {
		"name": "Yuma Tsukumo", "short": "Yuma", "era": "ZEXAL", "color": Color("ffd23a"),
		"title": "Kattobingu!", "deck": "yuma", "ace": 84013237, "wiki": "Yuma Tsukumo",
		"lines": {
			"intro": ["Kattobingu! Let's go!", "Feel the flow, let's duel!"],
			"turn": ["My turn! Kattobingu!", "I draw!"],
			"ace": ["I build the Overlay Network! Come on out, Utopia!", "Utopia, here we go!"],
			"attack": ["Rising Sun Slash!", "Charge!"],
			"hurt": ["Ouch! Okay, okay, I got this!", "I'm not giving up!"],
			"win": ["Yes! Did you see that? Kattobingu!"],
			"lose": ["Aww... that was awesome though!"],
		},
	},
}

const PLAYER_LINES := {
	"intro": ["Let's do this.", "I won't hold back."],
	"turn": ["My turn!", "Draw!"],
	"ace": ["This is my ace!", "Here's my best!"],
	"attack": ["Attack!", "Go!"],
	"hurt": ["I'm still standing.", "Not yet!"],
	"win": ["Yes! I won!"],
	"lose": ["Next time..."],
}


static func get_char(key: String) -> Dictionary:
	return DATA.get(key, {})


static func line(key: String, kind: String) -> String:
	var lines: Dictionary = PLAYER_LINES if key == "player" else DATA.get(key, {}).get("lines", {})
	var arr: Array = lines.get(kind, [])
	if arr.is_empty():
		return ""
	return arr[randi() % arr.size()]
