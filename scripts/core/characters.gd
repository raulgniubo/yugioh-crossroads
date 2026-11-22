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
			"attack": ["Dark Magic Attack!"], "direct": ["Go, attack directly!"],
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
			"ace": ["Now we're talking!"], "fusion": ["Fusion time! Elemental HEROes, unite!"],
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
	"curator": {"name": "The Curator", "short": "Curator", "era": "Crossroads", "color": Color("f2e6c8"), "title": "Keeper of the Museum",
		"deck": "curator", "ace_name": "Blue-Eyes White Dragon", "personality": "cool",
		"lines": {"intro": ["Please don't touch the exhibits."], "ace": ["A masterpiece. I kept it perfect."], "taunt": ["Nothing in here ever gets worse."],
			"win": ["There. Now this moment is safe too."], "lose": ["...I had forgotten what losing felt like. It is not so bad."]}},
	"aurel": {"name": "Aurel Thane", "short": "Aurel", "era": "Crossroads", "color": Color("f2e6c8"), "title": "An old duelist"},
	"vellum": {"name": "Vellum", "short": "Vellum", "era": "Crossroads", "color": Color("8a6bd6"), "title": "Head Archivist",
		"deck": "vellum", "ace_name": "Dark Magician", "personality": "dark",
		"lines": {"intro": ["Everything gets filed. Even you."], "ace": ["Catalogue number one."], "taunt": ["Noted."],
			"win": ["Filed under: forgotten."], "lose": ["An error in the record... impossible."]}},
	"ren": {"name": "Ren Vance", "short": "Ren", "era": "Crossroads", "color": Color("ff9a5a"), "title": "Kairo's little brother"},
	"koji": {"name": "Koji", "short": "Koji", "era": "GX", "color": Color("e0564a"), "title": "Red dorm second-year"},
	"mechanic": {"name": "Runner Mechanic", "short": "Mechanic", "era": "5D's", "color": Color("f0a040"), "title": "Keeps the King's runner on the road"},
	"dai": {"name": "Dai", "short": "Dai", "era": "Crossroads", "color": Color("7cc4ff"), "title": "Friday night regular", "personality": "wild"},
	"boy_sol": {"name": "A boy with a deck box", "short": "Boy", "era": "Crossroads", "color": Color("c9a76a"), "title": "Long ago"},
	"boy_aurel": {"name": "A boy with a notebook", "short": "Boy", "era": "Crossroads", "color": Color("f2e6c8"), "title": "Long ago"},
	"lumen": {"name": "Lumen", "short": "Lumen", "era": "Crossroads", "color": Color("8ff0ff"), "title": "Your partner. A glitchy duel spirit"},
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
	# ---- the Academy story (0.65.0). Originals of this game, and four GX people who get their
	# own model when you drop one in characters/ (crowler, dorothy, sheppard, bastion).
	"nico": {"name": "Nico Paz", "short": "Nico", "era": "GX", "color": Color("ff7a45"), "title": "Red dorm, first year. The voice of every duel",
		"deck": "deck_warrior", "ace_name": "Gilford the Legend", "personality": "wild", "stars": 1,
		"lines": {"intro": ["And here we go! Nico Paz steps up to the field!"], "ace": ["The crowd goes wild! That is my ace!"], "taunt": ["Are you getting all this? I am."],
			"win": ["And that is the duel! What a finish!"], "lose": ["And the challenger wins it. I will still tell it well."]}},
	"mika": {"name": "Mika Arai", "short": "Mika", "era": "GX", "color": Color("b48cff"), "title": "Red dorm, first year. Top of every written test",
		"deck": "deck_arcane", "ace_name": "Dark Magician Girl", "personality": "cool", "stars": 2,
		"lines": {"intro": ["I ran the numbers on this duel. Let us see if they hold."], "ace": ["This is the card I planned for."], "taunt": ["That was the likely play."],
			"win": ["As calculated. Good duel."], "lose": ["I missed a line. I will find it tonight."]}},
	"bruno": {"name": "Bruno Salas", "short": "Bruno", "era": "GX", "color": Color("c9783a"), "title": "Red dorm, third year. They call him Tank",
		"deck": "deck_rock", "ace_name": "Guardian Sphinx", "personality": "kind", "stars": 3,
		"lines": {"intro": ["Nothing gets past me. Come and try."], "ace": ["Here is the wall. Take your time."], "taunt": ["You will need more than that."],
			"win": ["Good duel. Now come and eat."], "lose": ["You got past the Tank. That does not happen often."]}},
	"sato": {"name": "Professor Elena Sato", "short": "Sato", "era": "GX", "color": Color("e05a4a"), "title": "Head of the Red dorm. Coach of the Academy team",
		"deck": "deck_machine", "ace_name": "Machine King", "personality": "cool", "stars": 5,
		"lines": {"intro": ["Show me what you learned."], "ace": ["I captained with this card."], "taunt": ["Think one turn further."],
			"win": ["Again tomorrow. You are closer than you think."], "lose": ["Good. That is why I put your name on the list."]}},
	"crowler": {"name": "Doctor Crowler", "short": "Crowler", "era": "GX", "color": Color("5a6ad8"), "title": "Head of the Blue dorm. Chair of Dueling Theory",
		"deck": "deck_ancient_gear", "ace_name": "Ancient Gear Golem", "personality": "cocky", "stars": 4,
		"lines": {"intro": ["Class is in session. Do take notes."], "ace": ["Behold a proper education! Ancient Gear Golem!"], "taunt": ["A Red dorm play if I ever saw one."],
			"win": ["Failing grade. As expected."], "lose": ["Impossible. I shall be reviewing the tape."]}},
	"sheppard": {"name": "Chancellor Sheppard", "short": "Sheppard", "era": "GX", "color": Color("d8a23a"), "title": "Chancellor of Duel Academy",
		"deck": "deck_cyber", "ace_name": "Cyber Dragon", "personality": "kind", "stars": 5},
	"dorothy": {"name": "Dorothy", "short": "Dorothy", "era": "GX", "color": Color("ffd166"), "title": "The Academy card shop"},
	"bastion": {"name": "Bastion Misawa", "short": "Bastion", "era": "GX", "color": Color("f2c230"), "title": "Top of the Yellow dorm. The team's strategist",
		"deck": "deck_water", "personality": "cool", "stars": 3},
	"dante": {"name": "Dante Morel", "short": "Dante", "era": "GX", "color": Color("3a6ad8"), "title": "Blue dorm, first year. A champion's son",
		"deck": "deck_dragon", "ace_name": "Tyrant Dragon", "personality": "cocky", "stars": 4,
		"lines": {"intro": ["Try to make it worth my time."], "ace": ["This is what a real deck looks like."], "taunt": ["Is that all Red has?"],
			"win": ["As expected."], "lose": ["...Once. That happens once."]}},
	"octavia": {"name": "Octavia Lenz", "short": "Octavia", "era": "GX", "color": Color("6a7ae8"), "title": "Blue dorm prefect. President of the Student Council",
		"deck": "deck_barrier", "ace_name": "Voltanis the Adjudicator", "personality": "cool", "stars": 4,
		"lines": {"intro": ["The answer is no. Let us find out what the question was."], "ace": ["Voltanis. The verdict is in."], "taunt": ["That was denied. Try something else."],
			"win": ["Noted, and filed."], "lose": ["...Then I was wrong. I will write it down."]}},
	"crane": {"name": "Silas Crane", "short": "Crane", "era": "GX", "color": Color("c9a24a"), "title": "Owner of Apex Academy. Sponsor of the League"},
	# First-years of the Rookie Tournament (chapter 4). They wear bodies and voices the game already has.
	"gus": {"name": "Gus Moreno", "short": "Gus", "era": "GX", "color": Color("e0603a"), "title": "Red dorm, first year. Signed up by somebody else",
		"deck": "deck_goblin", "personality": "wild", "stars": 1},
	"felix": {"name": "Felix Arden", "short": "Felix", "era": "GX", "color": Color("3f7fe8"), "title": "Blue dorm, first year. Already picked your common room",
		"deck": "deck_archfiend", "personality": "cocky", "stars": 2},
	"ivo": {"name": "Ivo Brandt", "short": "Ivo", "era": "GX", "color": Color("e8c040"), "title": "Yellow dorm, first year. Never raises his voice",
		"deck": "deck_dark_world", "personality": "cool", "stars": 2},
	# The Midnight Circle: masks and nicknames. Nobody says who they are by day.
	"moth": {"name": "The Moth", "short": "Moth", "era": "GX", "color": Color("b0a070"), "title": "The Midnight Circle. Wins a lot, loses loudly",
		"deck": "deck_insect", "personality": "wild", "stars": 2},
	"ink": {"name": "Ink", "short": "Ink", "era": "GX", "color": Color("6a78c8"), "title": "The Midnight Circle. Writes down everything you play",
		"deck": "deck_spellbook", "personality": "cool", "stars": 2},
	# Act 2. Boreal Academy (the north): grey coats, walls, nobody smiles.
	"irina": {"name": "Irina Volkova", "short": "Irina", "era": "GX", "color": Color("9aa4b4"), "title": "Captain of Boreal Academy. They call her the Wall",
		"deck": "deck_ice_barrier", "ace_name": "Trishula, Dragon of the Ice Barrier", "personality": "cool", "stars": 5,
		"lines": {"intro": ["A wall is only a question asked slowly. Take your time answering."], "ace": ["Trishula. The answer is no."], "taunt": ["Boreal does not hurry."],
			"win": ["Boreal does not celebrate. We count. Then we go home."], "lose": ["...The wall had a door. I will find out who left it open."]}},
	"tova": {"name": "Tova Lindqvist", "short": "Tova", "era": "GX", "color": Color("8a8f98"), "title": "Boreal Academy. A notebook that is always open",
		"deck": "deck_cloudian", "personality": "cool", "stars": 3},
	"rurik": {"name": "Rurik", "short": "Rurik", "era": "GX", "color": Color("7c828c"), "title": "Boreal Academy. Says two words a match",
		"personality": "dark", "stars": 3},
	# The Midnight Circle, Lantern rank.
	"sparrow": {"name": "Sparrow", "short": "Sparrow", "era": "GX", "color": Color("78b8a0"), "title": "The Midnight Circle. The fastest hands of the Lantern rank",
		"deck": "deck_wind", "personality": "cocky", "stars": 3},
	"bell": {"name": "Third Bell", "short": "Third Bell", "era": "GX", "color": Color("8a7ab0"), "title": "The Midnight Circle. Has not been seen in third period for weeks",
		"deck": "deck_zombie", "personality": "dark", "stars": 3},
	"paper": {"name": "Paper", "short": "Paper", "era": "GX", "color": Color("e6e2d6"), "title": "The Midnight Circle. Watches more than he plays",
		"deck": "deck_monarchs", "personality": "cocky", "stars": 3},
	"harbor": {"name": "Harbor", "short": "Harbor", "era": "GX", "color": Color("4a88b8"), "title": "The Midnight Circle. Two years at the head of the Lantern rank",
		"deck": "deck_water", "personality": "cool", "stars": 4},
}

const PERSONALITY_LINES := {
	"kind": {"chain": ["I'll chain to that!", "Wait, I have a response!"], "negate": ["Sorry, that won't work!", "I had to stop that one."], "negated": ["Oh no, it was stopped!"], "fusion": ["Together now! Fusion Summon!"], "synchro": ["Everyone in tune! Synchro Summon!"], "xyz": ["Side by side! Xyz Summon!"], "ritual": ["The ritual is ready!"], "ace_lost": ["No...! I'm sorry, my friend.", "You fought well. Rest now."], "trap": ["Oh! I set a Trap. Sorry!", "Wait, I have a card for this!"], "spell": ["Let's try this!"], "set": ["I'll leave this face-down... just in case."], "big_hit": ["That one landed!"], "draw_pressure": ["Okay, think... think..."], "comeback": ["See? Never give up!"], "intro": ["Good luck! Let's have a great duel."], "turn": ["My turn! Here goes."],
		"ace": ["I believe in you!"], "attack": ["Go, attack!"], "hurt": ["That hurt... but I'm okay."],
		"react": ["Wow, that's a strong monster!"], "destroyed": ["Sorry, partner..."], "taunt": ["You're really good!"],
		"low": ["I can still turn this around!"], "win": ["That was fun! Thank you."], "lose": ["You're amazing. Well played."]},
	"cocky": {"chain": ["Not on my watch. Chain!", "You forgot about my cards."], "negate": ["Denied.", "Did you think I'd allow that?"], "negated": ["You stopped it? Tch."], "fusion": ["Two become one, and it's mine. Fusion Summon!"], "synchro": ["Watch the stars line up for me. Synchro Summon!"], "xyz": ["Two monsters, one Rank. Xyz Summon!"], "ritual": ["The ritual answers to me."], "ace_lost": ["You... you destroyed it?!", "That was my best card! You'll pay for that!"], "trap": ["Did you really think I'd leave myself open?", "Walked right into it."], "spell": ["Watch this."], "set": ["Go on. Attack. I dare you."], "big_hit": ["Feel that? That's the gap between us."], "draw_pressure": ["Hmph. This changes nothing."], "comeback": ["Back where I belong. On top."], "intro": ["This won't take long."], "turn": ["Watch and learn.", "My move."],
		"ace": ["Now witness true power!"], "attack": ["Crush them!"], "hurt": ["A lucky shot."],
		"react": ["Is that supposed to scare me?"], "destroyed": ["Hmph. A minor setback."], "taunt": ["Is that all you've got?", "Pathetic."],
		"low": ["Don't think you've won yet!"], "win": ["As expected."], "lose": ["Impossible...!"]},
	"cool": {"chain": ["Chain."], "negate": ["Negated."], "negated": ["...Stopped."], "fusion": ["Fusion Summon."], "synchro": ["Synchro Summon."], "xyz": ["Xyz Summon."], "ritual": ["Ritual Summon."], "ace_lost": ["...Impressive. That was my ace.", "So you can beat it. Noted."], "trap": ["Trap card.", "I saw that coming."], "spell": ["Spell."], "set": ["One face-down."], "big_hit": ["Clean hit."], "draw_pressure": ["Stay calm."], "comeback": ["Now it's even."], "intro": ["Let's go."], "turn": ["Draw."], "ace": ["Here it comes."], "attack": ["Go."],
		"hurt": ["Not bad."], "react": ["Interesting."], "destroyed": ["It did its job."], "taunt": ["Your move."],
		"low": ["It's not over."], "win": ["Good duel."], "lose": ["You earned it."]},
	"wild": {"chain": ["Hold it! I'm chaining!", "Oh no you don't!"], "negate": ["NOPE! Negated!", "Stopped it cold!"], "negated": ["Hey! That was a good one!"], "fusion": ["Smash 'em together! FUSION!"], "synchro": ["Rev it up! SYNCHRO!"], "xyz": ["Stack 'em up! XYZ!"], "ritual": ["Light the fires! RITUAL!"], "ace_lost": ["NO WAY! Not my ace!", "Aw, come ON! That was my favorite!"], "trap": ["Gotcha! Trap card!", "Surprise!"], "spell": ["Check THIS out!"], "set": ["Hehe... what's under there? Guess!"], "big_hit": ["BOOM! Right in the Life Points!"], "draw_pressure": ["Come on deck, don't fail me now!"], "comeback": ["Who's laughing now?!"], "intro": ["Let's GO!"], "turn": ["My turn! Come on, come on!"], "ace": ["Now we're talkin'!"],
		"attack": ["Charge!", "Take that!"], "hurt": ["Ow! Okay, okay!"], "react": ["Whoa! That thing's huge!"],
		"destroyed": ["Aw man, not my monster!"], "taunt": ["Bring it on!"], "low": ["I'm not done yet!"],
		"win": ["Woohoo! Did you see that?"], "lose": ["Rematch! Right now!"]},
	"dark": {"chain": ["The chain tightens.", "Your move wakes mine."], "negate": ["It dies unheard.", "Silence."], "negated": ["You cut the thread..."], "fusion": ["Two shadows, one shape. Fusion Summon."], "synchro": ["The stars align in the dark."], "xyz": ["From the void between the stars, rise."], "ritual": ["The offering is accepted."], "ace_lost": ["You dare...!", "It will rise again. They always do."], "trap": ["Caught in my web.", "Struggle all you like."], "spell": ["Let the ritual begin."], "set": ["Something waits in the dark..."], "big_hit": ["Scream for me."], "draw_pressure": ["Interesting... very interesting."], "comeback": ["The shadows always return."], "intro": ["Welcome to the shadows."], "turn": ["Now, the fun begins."], "ace": ["Despair!"],
		"attack": ["Devour them!"], "hurt": ["Hehehe... pain is delicious."], "react": ["Oh? How amusing."],
		"destroyed": ["It will return..."], "taunt": ["Can you feel the darkness closing in?"], "low": ["You think this is over?"],
		"win": ["Your soul is mine."], "lose": ["This isn't the end..."]},
}

const PLAYER_LINES := {
	"chain": ["I chain this!", "Not so fast!"],
	"negate": ["Negated!", "That effect stops here."],
	"negated": ["They stopped it...!"],
	"fusion": ["Fusion Summon!"],
	"synchro": ["Synchro Summon!"],
	"xyz": ["Xyz Summon!"],
	"ritual": ["Ritual Summon!"],
	"ace_lost": ["My ace...! Not yet. I'm not done.", "They got my best monster. Think. Think!"],
	"intro": ["Let's do this.", "I won't hold back."],
	"turn": ["My turn!", "It's my turn!", "Here I go!"],
	"draw": ["Draw!", "I draw a card!", "My draw!", "Come on, deck!"],
	"first": ["I'll go first.", "First turn is mine!"],
	"second": ["Go ahead. You start.", "You go first. I'll be right here."],
	"summon": ["I summon this monster!", "Come out!", "Take the field!"],
	"set_mon": ["I set a monster.", "One monster, face-down."],
	"ace": ["This is my ace!", "Here's my best!"],
	"battle": ["Battle!", "Time to battle!", "Coming at you!"],
	"attack": ["Attack!", "Go!", "Attack now!", "Strike!"],
	"direct": ["Direct attack!", "Straight at your Life Points!", "Nothing in the way. Go!"],
	"end": ["I end my turn.", "Your move.", "That's it for now."],
	"hurt": ["I'm still standing.", "Not yet!", "Ugh!", "That stung."],
	"hurt_big": ["Agh! That was a big one...", "My Life Points...!", "I can take it. I have to."],
	"win": ["Yes! I won!", "That's how it's done!", "I did it!", "What a duel. Thank you!", "And that's the duel!"],
	"lose": ["Next time...", "Good duel. I'll be back.", "I lost... but I learned something.", "Good duel. The next one is mine.", "So close..."],
	"trap": ["Not so fast! Trap card!", "I was waiting for that!"],
	"spell": ["Let's see how you handle this.", "I activate a Spell Card!", "Spell Card, go!"],
	"set": ["I set a card face-down.", "One card face-down."],
	"big_hit": ["Direct hit!", "That's a big one!"],
	"react": ["That's a strong monster...", "Okay. I can handle that.", "So that's your ace..."],
	"destroyed": ["My monster...", "No!", "I'll get you back for that."],
	"low": ["I'm not done yet!"],
	"comeback": ["We're back in this!"],
}

## More to say (0.63.0): the calls of a turn (draw, who starts, summon, battle, end) and more versions of
## the lines that come up most, per personality. A duelist's own lines for a moment come first; these join them.
const MORE_LINES := {
	"kind": {
		"turn": ["It's my turn!"],
		"draw": ["Okay, here I go. Draw!", "I draw. Please be a good one!", "Draw!"],
		"first": ["I'll go first, if that's okay.", "I'll start us off!"],
		"second": ["You can go first. Good luck!", "After you!"],
		"summon": ["I summon this monster!", "Come on out, friend!", "This one's up next!"],
		"set_mon": ["I'll set a monster."],
		"set": ["I'll leave this face-down."],
		"spell": ["I activate a Spell Card!", "This should help!"],
		"trap": ["Sorry! That was a Trap."],
		"battle": ["Let's battle!", "Here we go, everyone!", "Battle!"],
		"direct": ["Direct attack! Sorry!", "The way is open. Go!", "Straight to the Life Points!"],
		"end": ["I end my turn.", "That's all for me. Your turn!", "Go ahead, it's your turn."],
		"hurt_big": ["Ugh... that was a strong one.", "I felt that... but I'm still here."],
		"win": ["We did it! Great duel!", "Thank you for dueling me."],
		"lose": ["I lost... I'll train harder.", "That was a great duel. Really."]},
	"cocky": {
		"turn": ["My turn. Finally."],
		"draw": ["My turn. Draw.", "Draw. Exactly what I needed.", "Watch and learn. Draw!"],
		"first": ["I go first. Obviously.", "First turn is mine. Try to keep up."],
		"second": ["Go first. You'll need the head start.", "Take the first turn. It won't matter."],
		"summon": ["I summon this. Tremble.", "Come forth!", "Another one you can't beat."],
		"set_mon": ["A monster, face-down. Guess."],
		"set": ["Face-down. Go ahead, walk into it."],
		"spell": ["A Spell Card. Pay attention.", "This is how the game is really played."],
		"trap": ["You walked right into it."],
		"battle": ["Battle. This won't take long.", "Time to finish this.", "Battle!"],
		"direct": ["Direct attack. Feel that?", "Nothing to hide behind.", "Straight to your Life Points."],
		"end": ["I end my turn. Do your worst.", "Your turn. Don't waste it.", "Go. Entertain me."],
		"hurt_big": ["Tch... you'll pay for that.", "Enjoy it. It's the last one you get."],
		"win": ["Was there ever any doubt?", "Come back when you're ready."],
		"lose": ["This... isn't over.", "You got lucky. Remember that."]},
	"cool": {
		"turn": ["My turn."],
		"draw": ["Draw.", "I draw.", "Draw. Good."],
		"first": ["I'll go first.", "First turn. Mine."],
		"second": ["You first.", "Go ahead."],
		"summon": ["Summon.", "I summon this.", "Take the field."],
		"set_mon": ["Monster. Face-down."],
		"set": ["One card face-down."],
		"spell": ["Spell Card.", "Activate."],
		"trap": ["Trap."],
		"battle": ["Battle.", "Battle Phase.", "Let's settle this."],
		"direct": ["Direct attack.", "Open field. Go.", "Straight through."],
		"end": ["Turn end.", "I end my turn.", "Your turn."],
		"hurt_big": ["...That one counted.", "I'm still here."],
		"win": ["It's over.", "You fought well."],
		"lose": ["I lost. Fair.", "Next time."]},
	"wild": {
		"turn": ["My turn, my turn!"],
		"draw": ["Draw! Come on, come on!", "My turn! DRAW!", "Draw! Ha! Look at this!"],
		"first": ["Me first! Me first!", "I'm starting! Try and stop me!"],
		"second": ["You first! Show me what you've got!", "Go on, go on! I can't wait!"],
		"summon": ["Get out here!", "Summon! Yeah!", "Here comes trouble!"],
		"set_mon": ["Hehe. Face-down monster!"],
		"set": ["Face-down! Don't peek!"],
		"spell": ["Spell Card! Boom!", "Oh, you're gonna love this one!"],
		"trap": ["Ha! Fell for it!"],
		"battle": ["BATTLE!", "Let's fight!", "Finally! Battle time!"],
		"direct": ["Direct attack! WHAM!", "Nobody home! Go, go, go!", "Right at ya!"],
		"end": ["Okay, okay, I'm done!", "Turn over! Your go!", "That's my turn! Beat that!"],
		"hurt_big": ["YOWCH! That one hurt!", "Whoa... okay, that was a LOT."],
		"win": ["YES! That was awesome!", "Again! Let's go again!"],
		"lose": ["Aw, no way! So close!", "Okay, you got me. That was fun!"]},
	"dark": {
		"turn": ["My turn... at last."],
		"draw": ["I draw... from the dark.", "Draw. Your end comes closer.", "My turn. Draw..."],
		"first": ["I begin. You only wait.", "The first turn is mine."],
		"second": ["Go first. It changes nothing.", "Begin. I am patient."],
		"summon": ["Rise.", "I summon this from the shadows.", "Come. Serve me."],
		"set_mon": ["Something waits, face-down."],
		"set": ["A card in the dark. Step closer."],
		"spell": ["A Spell Card. Despair.", "Let the dark do its work."],
		"trap": ["The trap closes."],
		"battle": ["Battle. Scream if you like.", "Now, the battle.", "Let it begin."],
		"direct": ["Direct attack. Nothing protects you.", "Feel it yourself.", "Straight into you."],
		"end": ["I end my turn. Struggle.", "Your turn. Use it well.", "Go on. Amuse me."],
		"hurt_big": ["Pain... how nostalgic.", "You will regret that."],
		"win": ["It ends as it had to.", "The dark takes you."],
		"lose": ["The dark... fades...", "This is not the end."]},
}


## Every line a personality can say: its own table and MORE_LINES together.
static func personality_lines(pers: String) -> Dictionary:
	var out := {}
	for src in [PERSONALITY_LINES.get(pers, {}), MORE_LINES.get(pers, {})]:
		for k in src:
			out[k] = (out.get(k, []) as Array) + (src[k] as Array)
	return out


static func get_char(key: String) -> Dictionary:
	var d: Dictionary = DATA.get(key, STORY_CAST.get(key, {})).duplicate()
	if d.is_empty():
		return d
	if not d.has("ace") and d.has("ace_name"):
		d["ace"] = CardData.NAME_TO_ID.get(str(d["ace_name"]).to_lower(), 0)
	return d


static func available(key: String) -> bool:
	return DATA.has(key) and CardData.has_deck(DATA[key]["deck"])


## The English of the line `line()` picked last (the voices are looked up by it, see Voices).
static var last_en := ""
static var _last_said := {}       # "<who>|<moment>" -> the line said last time


## A line that names a card, a family of cards or a monster's own attack is only said about that
## card (0.63.0): Kaiba does not announce "the Blue-Eyes White Dragon" for the three-headed fusion,
## and nobody shouts a monster's attack name while another monster attacks.
## line -> what the card must be (any one of): a card's exact name; "Name*" = its name begins so;
## "*text*" = its name has that in it; "ace" = the speaker's own ace card.
const LINE_NEEDS := {
	"Dark Magician, I summon you!": ["Dark Magician"], "My most trusted monster!": ["ace"], "Dark Magic Attack!": ["Dark Magician"],
	"Behold, the Blue-Eyes White Dragon!": ["Blue-Eyes White Dragon"], "Burst Stream of Destruction!": ["Blue-Eyes White Dragon"],
	"Red-Eyes, show 'em what you got!": ["Red-Eyes Black Dragon"], "Inferno Fire Blast!": ["Red-Eyes Black Dragon"],
	"Fusion time! Elemental HEROes, unite!": ["Elemental HERO*"], "Go, HERO, take 'em down!": ["*HERO*"], "Skyscraper Shoot!": ["ace"],
	"Clustering wishes become a new shining star!": ["Stardust Dragon"], "Take flight, Stardust Dragon!": ["Stardust Dragon"], "Shooting Sonic!": ["Stardust Dragon"],
	"I build the Overlay Network! Come on out, Utopia!": ["Number 39: Utopia"], "Utopia, here we go!": ["Number 39: Utopia"], "Rising Sun Slash!": ["Number 39: Utopia"],
	"My Harpies always come in style!": ["Harpie *", "Cyber Harpie Lady"], "Cyclone Attack!": ["Harpie *", "Cyber Harpie Lady"],
	"Isn't my Toon simply marvelous?": ["Toon *"],
	"Bow to the Insect Queen!": ["Insect Queen"], "ROAR! Black Tyranno!": ["Black Tyranno"],
	"Cyber End Dragon. Evolution complete.": ["Cyber End Dragon"], "Take the stage, Cyber Blader!": ["Cyber Blader"],
	"Destiny HEROes, show them their fate.": ["Destiny HERO*"],
	"The King's soul burns hot! Red Dragon Archfiend!": ["Red Dragon Archfiend"], "Absolute Powerforce!": ["Red Dragon Archfiend"],
	"Blackwings, take to the sky!": ["Blackwing*"], "Bloom, Black Rose Dragon!": ["Black Rose Dragon"],
	"Rise from the depths, Leviathan Dragon!": ["Number 17: Leviathan Dragon"],
	"Galaxy-Eyes Photon Dragon! Descend!": ["Galaxy-Eyes Photon Dragon"], "Photon Stream of Destruction!": ["Galaxy-Eyes Photon Dragon"],
	"This echo is mine now.": ["ace"], "A masterpiece. I kept it perfect.": ["ace"], "Catalogue number one.": ["ace"],
}


## May `key` say this line about that card (0 = no card in particular)?
static func line_fits(key: String, text: String, card_id: int) -> bool:
	if not LINE_NEEDS.has(text):
		return true
	if card_id <= 0:
		return false
	var nm := str(CardData.get_card(card_id).get("name", ""))
	for need in LINE_NEEDS[text]:
		var n := str(need)
		if n == "ace":
			if int(get_char(key).get("ace", 0)) == card_id:
				return true
		elif n.begins_with("*") and n.ends_with("*"):
			if nm.contains(n.substr(1, n.length() - 2)):
				return true
		elif n.ends_with("*"):
			if nm.begins_with(n.substr(0, n.length() - 1)):
				return true
		elif nm == n:
			return true
	return false


static func _fitting(key: String, arr: Array, card_id: int) -> Array:
	return arr.filter(func(t): return line_fits(key, str(t), card_id))


## `card_id`: the card the line would be about (the monster arriving, the one attacking), 0 = none.
static func line(key: String, kind: String, card_id := 0) -> String:
	last_en = ""
	# Your own duelist says the lines you picked for them.
	if key == "player" and kind == "intro" and Profile.intro > 0:
		last_en = str(Profile.INTROS[Profile.intro])
		return Loc.t(last_en)
	if key == "player" and kind == "win" and Profile.win_line > 0:
		last_en = str(Profile.WINS[Profile.win_line])
		return Loc.t(last_en)
	var who: Dictionary = DATA.get(key, STORY_CAST.get(key, {}))
	var arr: Array = _fitting(key, (PLAYER_LINES if key == "player" else who.get("lines", {})).get(kind, []), card_id)
	if key != "player":
		var pers: String = who.get("personality", "cool")
		if arr.is_empty():
			arr = PERSONALITY_LINES.get(pers, {}).get(kind, [])
		arr = arr + (MORE_LINES.get(pers, {}).get(kind, []) as Array)
	elif arr.is_empty():
		arr = PERSONALITY_LINES["wild"].get(kind, [])
	if arr.is_empty():
		return ""
	# Never the same line twice in a row for the same moment.
	var slot := key + "|" + kind
	var pick := str(arr[randi() % arr.size()])
	if arr.size() > 1 and pick == str(_last_said.get(slot, "")):
		pick = str(arr[(arr.find(pick) + 1 + randi() % (arr.size() - 1)) % arr.size()])
	_last_said[slot] = pick
	last_en = pick
	return Loc.t(last_en)
