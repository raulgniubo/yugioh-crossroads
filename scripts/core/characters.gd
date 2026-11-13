class_name Characters
extends RefCounted
## Duelists: who they are, their deck, their ace and what they say.

const ORDER := [
	"yugi", "kaiba", "joey", "mai", "bakura", "marik", "pegasus", "weevil", "rex",
	"jaden", "chazz", "zane", "alexis", "syrus", "aster",
	"yusei", "jack", "crow", "akiza", "kalin",
	"yuma", "shark", "kite", "vector",
]
const ERAS := ["Duel Monsters", "GX", "5D's", "ZEXAL"]

const DATA := {
	"yugi": {
		"name": "Yugi Muto", "short": "Yugi", "era": "Duel Monsters", "color": Color("8a4dff"),
		"title": "King of Games", "deck": "yugi", "ace": 46986414, "wiki": "Yugi Muto", "personality": "kind",
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
		"title": "CEO of Kaiba Corp", "deck": "kaiba", "ace": 89631139, "wiki": "Seto Kaiba", "personality": "cocky",
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
		"title": "The Underdog", "deck": "joey", "ace": 74677422, "wiki": "Joey Wheeler", "personality": "wild",
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
		"title": "Slifer Red Ace", "deck": "jaden", "ace": 35809262, "wiki": "Jaden Yuki", "personality": "wild",
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
		"title": "The Satellite's Hope", "deck": "yusei", "ace": 44508094, "wiki": "Yusei Fudo", "personality": "cool",
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
		"title": "Kattobingu!", "deck": "yuma", "ace": 84013237, "wiki": "Yuma Tsukumo", "personality": "wild",
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
	"mai": {"name": "Mai Valentine", "short": "Mai", "era": "Duel Monsters", "color": Color("c86bff"), "title": "Queen of Harpies",
		"deck": "mai", "ace_name": "Harpie's Pet Dragon", "wiki": "Mai Valentine", "personality": "cocky",
		"lines": {"intro": ["Try to keep up, hon."], "ace": ["My Harpies always come in style!"], "attack": ["Cyclone Attack!"]}},
	"bakura": {"name": "Bakura", "short": "Bakura", "era": "Duel Monsters", "color": Color("7a6a9e"), "title": "The Thief King's Shadow",
		"deck": "bakura", "ace_name": "Dark Ruler Ha Des", "wiki": "Bakura Ryou", "personality": "dark",
		"lines": {"intro": ["Let's play a little game, shall we?"], "ace": ["Rise from the shadows!"]}},
	"marik": {"name": "Marik Ishtar", "short": "Marik", "era": "Duel Monsters", "color": Color("d9a640"), "title": "Leader of the Rare Hunters",
		"deck": "marik", "ace_name": "Gil Garth", "wiki": "Marik Ishtar", "personality": "dark",
		"lines": {"intro": ["Your soul will be mine."], "ace": ["Feel the power of the shadows!"]}},
	"pegasus": {"name": "Maximillion Pegasus", "short": "Pegasus", "era": "Duel Monsters", "color": Color("e04d6b"), "title": "Creator of Duel Monsters",
		"deck": "pegasus", "ace_name": "Toon Summoned Skull", "wiki": "Maximillion J. Pegasus", "personality": "cocky",
		"lines": {"intro": ["Oh, how delightful! A new playmate!"], "ace": ["Isn't my Toon simply marvelous?"], "taunt": ["I can read you like a comic book!"]}},
	"weevil": {"name": "Weevil Underwood", "short": "Weevil", "era": "Duel Monsters", "color": Color("6bbf4a"), "title": "Regional Champion",
		"deck": "weevil", "ace_name": "Insect Queen", "wiki": "Weevil Underwood", "personality": "cocky",
		"lines": {"intro": ["Heh heh heh... you're already trapped in my web."], "ace": ["Bow to the Insect Queen!"]}},
	"rex": {"name": "Rex Raptor", "short": "Rex", "era": "Duel Monsters", "color": Color("c9783a"), "title": "Dinosaur Duelist",
		"deck": "rex", "ace_name": "Black Tyranno", "wiki": "Rex Raptor", "personality": "cocky",
		"lines": {"intro": ["My dinos are gonna stomp you flat!"], "ace": ["ROAR! Black Tyranno!"]}},
	"chazz": {"name": "Chazz Princeton", "short": "Chazz", "era": "GX", "color": Color("4a4f66"), "title": "The Chazz",
		"deck": "chazz", "ace_name": "Armed Dragon LV7", "wiki": "Chazz Princeton", "personality": "cocky",
		"lines": {"intro": ["Chazz it up!", "You're about to get Chazzed."], "ace": ["Behold the power of the Chazz!"]}},
	"zane": {"name": "Zane Truesdale", "short": "Zane", "era": "GX", "color": Color("3a8fd9"), "title": "Kaiser",
		"deck": "zane", "ace_name": "Cyber End Dragon", "wiki": "Zane Truesdale", "personality": "cool",
		"lines": {"intro": ["Show me respect by giving everything you've got."], "ace": ["Cyber End Dragon. Evolution complete."]}},
	"alexis": {"name": "Alexis Rhodes", "short": "Alexis", "era": "GX", "color": Color("4fb8e0"), "title": "Queen of Obelisk Blue",
		"deck": "alexis", "ace_name": "Cyber Blader", "wiki": "Alexis Rhodes", "personality": "kind",
		"lines": {"intro": ["Let's see if you can keep up with my dance."], "ace": ["Take the stage, Cyber Blader!"]}},
	"syrus": {"name": "Syrus Truesdale", "short": "Syrus", "era": "GX", "color": Color("6fa8ff"), "title": "Roid Mechanic",
		"deck": "syrus", "ace_name": "Steam Gyroid", "wiki": "Syrus Truesdale", "personality": "kind",
		"lines": {"intro": ["I-I can do this! Let's duel!"], "ace": ["Full speed ahead!"]}},
	"aster": {"name": "Aster Phoenix", "short": "Aster", "era": "GX", "color": Color("9aa3b5"), "title": "Pro League Champion",
		"deck": "aster", "ace_name": "Destiny HERO - Dasher", "wiki": "Aster Phoenix", "personality": "cocky",
		"lines": {"intro": ["Your destiny was decided before we started."], "ace": ["Destiny HEROes, show them their fate."]}},
	"jack": {"name": "Jack Atlas", "short": "Jack", "era": "5D's", "color": Color("e0343c"), "title": "The King",
		"deck": "jack", "ace_name": "Red Dragon Archfiend", "wiki": "Jack Atlas", "personality": "cocky",
		"lines": {"intro": ["There is only one King, and it's me!"], "ace": ["The King's soul burns hot! Red Dragon Archfiend!"],
			"attack": ["Absolute Powerforce!"]}},
	"crow": {"name": "Crow Hogan", "short": "Crow", "era": "5D's", "color": Color("ff9a3a"), "title": "Blackwing Courier",
		"deck": "crow", "ace_name": "Blackwing Armor Master", "wiki": "Crow Hogan", "personality": "wild",
		"lines": {"intro": ["Delivery's here! Let's make this quick."], "ace": ["Blackwings, take to the sky!"]}},
	"akiza": {"name": "Akiza Izinski", "short": "Akiza", "era": "5D's", "color": Color("d6386b"), "title": "Black Rose Witch",
		"deck": "akiza", "ace_name": "Black Rose Dragon", "wiki": "Akiza Izinski", "personality": "cool",
		"lines": {"intro": ["Be careful. My roses have thorns."], "ace": ["Bloom, Black Rose Dragon!"]}},
	"kalin": {"name": "Kalin Kessler", "short": "Kalin", "era": "5D's", "color": Color("8a5cff"), "title": "Former Enforcer",
		"deck": "kalin", "ace_name": "Infernity Doom Dragon", "wiki": "Kalin Kessler", "personality": "dark",
		"lines": {"intro": ["Let's have some fun... like old times."], "ace": ["Satisfaction guaranteed!"]}},
	"shark": {"name": "Shark", "short": "Shark", "era": "ZEXAL", "color": Color("3a5fd9"), "title": "Reginald Kastle",
		"deck": "shark", "ace_name": "Number 17: Leviathan Dragon", "wiki": "Reginald Kastle", "personality": "cool",
		"lines": {"intro": ["Don't waste my time."], "ace": ["Rise from the depths, Leviathan Dragon!"]}},
	"kite": {"name": "Kite Tenjo", "short": "Kite", "era": "ZEXAL", "color": Color("6ad7ff"), "title": "Numbers Hunter",
		"deck": "kite", "ace_name": "Galaxy-Eyes Photon Dragon", "wiki": "Kite Tenjo", "personality": "cool",
		"lines": {"intro": ["I'll take your soul, Number holder."], "ace": ["Galaxy-Eyes Photon Dragon! Descend!"], "attack": ["Photon Stream of Destruction!"]}},
	"vector": {"name": "Vector", "short": "Vector", "era": "ZEXAL", "color": Color("b03aff"), "title": "Barian Emperor",
		"deck": "vector", "ace_name": "Umbral Horror Ghoul", "wiki": "Vector", "personality": "dark",
		"lines": {"intro": ["Aww, you actually think you can win? Cute!"], "taunt": ["Hahaha! Did that hurt?"]}},
}

## Fallback lines by personality, used when a character has nothing specific to say.
## Story-only cast (not in the Free Duel roster).
const STORY_CAST := {
	"student_boy": {"name": "Student Duelist", "short": "Student", "era": "Crossroads", "color": Color("7cc4ff"), "title": "Duels between classes", "personality": "wild"},
	"student_girl": {"name": "Schoolgirl Duelist", "short": "Student", "era": "Crossroads", "color": Color("ff8ac0"), "title": "Top of her class", "personality": "kind"},
	"office_worker": {"name": "Office Duelist", "short": "Salaryman", "era": "Crossroads", "color": Color("9fb4c8"), "title": "Lunch break champion", "personality": "cool"},
	"stylish_woman": {"name": "Stylish Duelist", "short": "Stylish Duelist", "era": "Crossroads", "color": Color("c94f8a"), "title": "Duels in heels", "personality": "cocky"},
	"street_duelist": {"name": "Street Duelist", "short": "Street Duelist", "era": "Crossroads", "color": Color("f0a040"), "title": "Any corner, any time", "personality": "wild"},
	"kairo": {"name": "Kairo Vance", "short": "Kairo", "era": "Crossroads", "color": Color("e04848"), "title": "The Rival",
		"deck": "kairo", "ace_name": "Red-Eyes Black Dragon", "personality": "cool",
		"lines": {"intro": ["Stay out of my way."], "ace": ["This echo is mine now."], "taunt": ["You're slow."],
			"win": ["Told you. Go home."], "lose": ["...Lucky."]}},
	"lumen": {"name": "Lumen", "short": "Lumen", "era": "Crossroads", "color": Color("8ff0ff"), "title": "A glitchy duel spirit"},
	"vesper": {"name": "Vesper Quill", "short": "Vesper", "era": "Crossroads", "color": Color("e8ecff"), "title": "The Archivist",
		"deck": "kalin", "personality": "cocky",
		"lines": {"intro": ["Hold still. This will make a lovely exhibit."], "ace": ["A perfect lap. Admire it."], "taunt": ["You're behind."],
			"win": ["Catalogued."], "lose": ["...It's loud again."]}},
	"shopkeeper": {"name": "Old Shopkeeper", "short": "Shopkeeper", "era": "Crossroads", "color": Color("c9a76a"), "title": "Card shop owner"},
	"grandpa": {"name": "Solomon Muto", "short": "Grandpa", "era": "Duel Monsters", "color": Color("c9a76a"), "title": "Owner of Kame Game"},
	"hunter": {"name": "Rare Hunter", "short": "Rare Hunter", "era": "Duel Monsters", "color": Color("6b4a9e"), "title": "One of Vellum's men",
		"deck": "yusei", "personality": "dark",
		"lines": {"intro": ["Your rare cards belong to Vellum now."], "ace": ["Behold... a power from another time!"]}},
	"kid": {"name": "Rookie Duelist", "short": "Rookie", "era": "Duel Monsters", "color": Color("f0a040"), "title": "Street duelist",
		"deck": "joey", "personality": "kind"},
	"vendor": {"name": "Card Vendor", "short": "Vendor", "era": "Duel Monsters", "color": Color("40c0a0"), "title": "Kame Game regular"},
	"professor": {"name": "Exam Proctor", "short": "Proctor", "era": "GX", "color": Color("c9a76a"), "title": "Academy faculty", "personality": "cocky"},
	"red_student": {"name": "Red Dorm Student", "short": "Student", "era": "GX", "color": Color("d9342b"), "title": "Slifer Red", "personality": "wild"},
	"yellow_student": {"name": "Yellow Dorm Student", "short": "Student", "era": "GX", "color": Color("f2c230"), "title": "Ra Yellow", "personality": "cool"},
	"blue_student": {"name": "Blue Dorm Student", "short": "Student", "era": "GX", "color": Color("2f6fe0"), "title": "Obelisk Blue", "personality": "cocky"},
	"guard": {"name": "KaibaCorp Guard", "short": "Guard", "era": "Duel Monsters", "color": Color("4070e0"), "title": "Security"},
}

const PERSONALITY_LINES := {
	"kind": {"trap": ["Oh! I set a Trap. Sorry!", "Wait, I have a card for this!"], "spell": ["Let's try this!"], "set": ["I'll leave this face-down... just in case."], "big_hit": ["That one landed!"], "draw_pressure": ["Okay, think... think..."], "comeback": ["See? Never give up!"], "intro": ["Good luck! Let's have a great duel."], "turn": ["My turn! Here goes."],
		"ace": ["I believe in you!"], "attack": ["Go, attack!"], "hurt": ["That hurt... but I'm okay."],
		"react": ["Wow, that's a strong monster!"], "destroyed": ["Sorry, partner..."], "taunt": ["You're really good!"],
		"low": ["I can still turn this around!"], "win": ["That was fun! Thank you."], "lose": ["You're amazing. Well played."]},
	"cocky": {"trap": ["Did you really think I'd leave myself open?", "Walked right into it."], "spell": ["Watch this."], "set": ["Go on. Attack. I dare you."], "big_hit": ["Feel that? That's the gap between us."], "draw_pressure": ["Hmph. This changes nothing."], "comeback": ["Back where I belong. On top."], "intro": ["This won't take long."], "turn": ["Watch and learn.", "My move."],
		"ace": ["Now witness true power!"], "attack": ["Crush them!"], "hurt": ["A lucky shot."],
		"react": ["Is that supposed to scare me?"], "destroyed": ["Hmph. A minor setback."], "taunt": ["Is that all you've got?", "Pathetic."],
		"low": ["Don't think you've won yet!"], "win": ["As expected."], "lose": ["Impossible...!"]},
	"cool": {"trap": ["Trap card.", "I saw that coming."], "spell": ["Spell."], "set": ["One face-down."], "big_hit": ["Clean hit."], "draw_pressure": ["Stay calm."], "comeback": ["Now it's even."], "intro": ["Let's go."], "turn": ["Draw."], "ace": ["Here it comes."], "attack": ["Go."],
		"hurt": ["Not bad."], "react": ["Interesting."], "destroyed": ["It did its job."], "taunt": ["Your move."],
		"low": ["It's not over."], "win": ["Good duel."], "lose": ["You earned it."]},
	"wild": {"trap": ["Gotcha! Trap card!", "Surprise!"], "spell": ["Check THIS out!"], "set": ["Hehe... what's under there? Guess!"], "big_hit": ["BOOM! Right in the Life Points!"], "draw_pressure": ["Come on deck, don't fail me now!"], "comeback": ["Who's laughing now?!"], "intro": ["Let's GO!"], "turn": ["My turn! Come on, come on!"], "ace": ["Now we're talkin'!"],
		"attack": ["Charge!", "Take that!"], "hurt": ["Ow! Okay, okay!"], "react": ["Whoa! That thing's huge!"],
		"destroyed": ["Aw man, not my monster!"], "taunt": ["Bring it on!"], "low": ["I'm not done yet!"],
		"win": ["Woohoo! Did you see that?"], "lose": ["Rematch! Right now!"]},
	"dark": {"trap": ["Caught in my web.", "Struggle all you like."], "spell": ["Let the ritual begin."], "set": ["Something waits in the dark..."], "big_hit": ["Scream for me."], "draw_pressure": ["Interesting... very interesting."], "comeback": ["The shadows always return."], "intro": ["Welcome to the shadows."], "turn": ["Now, the fun begins."], "ace": ["Despair!"],
		"attack": ["Devour them!"], "hurt": ["Hehehe... pain is delicious."], "react": ["Oh? How amusing."],
		"destroyed": ["It will return..."], "taunt": ["Can you feel the darkness closing in?"], "low": ["You think this is over?"],
		"win": ["Your soul is mine."], "lose": ["This isn't the end..."]},
}

const PLAYER_LINES := {
	"intro": ["Let's do this.", "I won't hold back."],
	"turn": ["My turn!", "Draw!"],
	"ace": ["This is my ace!", "Here's my best!"],
	"attack": ["Attack!", "Go!"],
	"hurt": ["I'm still standing.", "Not yet!"],
	"win": ["Yes! I won!", "That's how it's done!"],
	"lose": ["Next time...", "Good duel. I'll be back."],
	"trap": ["Not so fast! Trap card!", "I was waiting for that!"],
	"spell": ["Let's see how you handle this."],
	"set": ["I'll set this and end my turn."],
	"big_hit": ["Direct hit!", "That's a big one!"],
	"react": ["That's a strong monster...", "Okay. I can handle that."],
	"destroyed": ["My monster..."],
	"low": ["I'm not done yet!"],
	"comeback": ["We're back in this!"],
}


static func get_char(key: String) -> Dictionary:
	var d: Dictionary = DATA.get(key, STORY_CAST.get(key, {})).duplicate()
	if d.is_empty():
		return d
	if not d.has("ace") and d.has("ace_name"):
		d["ace"] = CardData.NAME_TO_ID.get(str(d["ace_name"]).to_lower(), 0)
	return d


static func available(key: String) -> bool:
	return DATA.has(key) and CardData.has_deck(DATA[key]["deck"])


static func line(key: String, kind: String) -> String:
	var own: Dictionary = PLAYER_LINES if key == "player" else DATA.get(key, STORY_CAST.get(key, {})).get("lines", {})
	var arr: Array = own.get(kind, [])
	if arr.is_empty() and key != "player":
		var pers: String = DATA.get(key, STORY_CAST.get(key, {})).get("personality", "cool")
		arr = PERSONALITY_LINES.get(pers, {}).get(kind, [])
	if arr.is_empty() and key == "player":
		arr = PERSONALITY_LINES["wild"].get(kind, [])
	if arr.is_empty():
		return ""
	return Loc.t(str(arr[randi() % arr.size()]))
