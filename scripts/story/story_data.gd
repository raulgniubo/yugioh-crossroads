class_name StoryData
extends RefCounted
## Story chapters as data.
##
## Step kinds:
##   {"loc": "Place", "sub": "Era / time", "theme": field theme key}   location card
##   {"s": speaker key, "t": "text", "fx": "shake"|"flash"}             a line ("player" = you, "" = narration)
##   {"if": "flag", ...line}                                            line only if flag is set
##   {"choice": [["Option text", "flag"], ...]}                         sets one flag
##   {"duel": {"opponent", "deck", "lose_ok", "difficulty", "field"}}   story duel; sets "won" or "lost"
##   {"end": "Title", "unlock": "chapter id"}                           chapter complete
## {player} is replaced with your duelist name.

const CHAPTERS := [
	{"id": "prologue", "title": "Prologue", "name": "The Blank Deck", "era": "Crossroads"},
	{"id": "ch1", "title": "Chapter 1", "name": "Echoes of Battle City", "era": "Duel Monsters"},
	{"id": "ch2", "title": "Chapter 2", "name": "Slifer Red, Last of Its Kind", "era": "GX"},
]

const SCRIPTS := {
	"prologue": [
		{"loc": "Hometown Card Shop", "sub": "Friday night tournament", "theme": "crossroads"},
		{"s": "", "t": "The final round of the weekly tournament. Twelve duelists, a folding table, and one trophy shaped like a dragon that someone glued back together."},
		{"s": "", "t": "You lost. Badly."},
		{"s": "shopkeeper", "t": "Ha! Don't make that face, {player}. Everyone loses the final their first time."},
		{"s": "player", "t": "It wasn't my first time."},
		{"s": "shopkeeper", "t": "...Right. Well. Stick around after closing. I have something for you."},
		{"loc": "Card Shop, After Closing", "sub": "11:48 PM", "theme": "crossroads"},
		{"s": "shopkeeper", "t": "I've been keeping this deck for a long time. Waiting for the right person."},
		{"s": "player", "t": "These cards are... blank. Almost all of them."},
		{"s": "shopkeeper", "t": "They're not blank. They're waiting. A deck like this fills in when you make real bonds with other duelists."},
		{"choice": [["\"Is this a joke?\"", "doubt"], ["\"...I'll take care of it.\"", "trust"]]},
		{"if": "doubt", "s": "shopkeeper", "t": "Ha! Your face says that a lot. Hold it anyway."},
		{"if": "trust", "s": "shopkeeper", "t": "I know you will. That's why I picked you."},
		{"s": "", "t": "The deck is warm. Then it's hot. Then something crawls out of it.", "fx": "flash"},
		{"s": "lumen", "t": "AAAH! Light! Too much light! Where- who- WHAT year is it?!"},
		{"s": "player", "t": "A duel spirit...?"},
		{"s": "lumen", "t": "I'm Lumen! I think. Probably. My memory is... *bzzt* ...glitchy. Don't stare, it's rude!"},
		{"s": "", "t": "Outside, the street goes silent. A man stands frozen mid-step. A girl is shuffling the same three cards over and over, smiling at nothing.", "fx": "shake"},
		{"s": "lumen", "t": "Hollows. Someone's freezing people inside a single memory. This is bad. This is really, really bad!"},
		{"s": "kairo", "t": "So the last Echo Deck ended up with a nobody."},
		{"s": "player", "t": "Who are you?"},
		{"s": "kairo", "t": "Kairo. And that deck is wasted on you. Let me show you what an Echo Deck can really do."},
		{"duel": {"opponent": "kairo", "deck": "echo", "lose_ok": true, "difficulty": 1, "field": "crossroads"}},
		{"if": "won", "s": "kairo", "t": "...Tch. Beginner's luck. It won't happen twice."},
		{"if": "lost", "s": "kairo", "t": "Like I said. Wasted. Go home before you get hurt."},
		{"s": "", "t": "Kairo pulls a glowing shard out of the air. The tournament, the trophy, tonight's memory, all of it flows into his deck like smoke.", "fx": "flash"},
		{"s": "kairo", "t": "Stay out of the Curator's way. This is your only warning."},
		{"s": "lumen", "t": "He's taking echoes! If they're stolen, the past starts to crack. We have to fix it!"},
		{"s": "player", "t": "How?"},
		{"s": "lumen", "t": "We go back to where it started. Hold on tight, and please don't drop me!"},
		{"s": "", "t": "The air tears open like paper. Through it: a city of skyscrapers and a giant blimp with a K painted on its side.", "fx": "flash"},
		{"end": "Prologue complete", "unlock": "ch1"},
	],
	"ch1": [
		{"loc": "Domino City", "sub": "Battle City tournament, Day 1", "theme": "battlecity"},
		{"s": "lumen", "t": "Domino City! The Battle City tournament! This is where so many echoes started!"},
		{"s": "player", "t": "Everyone has a duel disk. Everyone."},
		{"s": "yugi", "t": "Hey, are you okay? You kind of fell out of the sky."},
		{"s": "player", "t": "...Yugi Muto?"},
		{"s": "yugi", "t": "Have we met? Sorry, I'm terrible with faces when I'm worried about a friend."},
		{"s": "yugi", "t": "Joey's been acting strange since this morning. He keeps dueling the same duel over and over, like he's stuck."},
		{"s": "lumen", "t": "(Psst! That's a Hollow! Your friend's been frozen in a memory!)"},
		{"choice": [["Tell Yugi about the Hollows", "honest"], ["Keep it quiet for now", "quiet"]]},
		{"if": "honest", "s": "yugi", "t": "Frozen in a memory... I've seen stranger things this week. I believe you."},
		{"if": "quiet", "s": "yugi", "t": "You know something, don't you? It's okay. Tell me when you're ready."},
		{"s": "kaiba", "t": "Yugi. Who is this? Another fan begging for an autograph?"},
		{"s": "yugi", "t": "Kaiba, this is {player}. They just got here."},
		{"s": "kaiba", "t": "No Locator Cards, a deck full of blank cards, and they 'just got here.' You're a fraud."},
		{"s": "player", "t": "Then duel me and find out."},
		{"s": "kaiba", "t": "Fine. I'll make it quick. Try not to embarrass yourself in front of my Blue-Eyes."},
		{"duel": {"opponent": "kaiba", "deck": "echo", "lose_ok": false, "difficulty": 1, "field": "kaibacorp"}},
		{"s": "kaiba", "t": "...Hmph. Not a complete fraud, then."},
		{"s": "yugi", "t": "That was amazing! Even Kaiba's impressed. He just won't say it."},
		{"s": "kaiba", "t": "I'm not impressed. I'm curious. There's a difference."},
		{"s": "lumen", "t": "Hey, look at the deck! One of the blank cards filled in!", "fx": "flash"},
		{"s": "", "t": "A new card shimmers into place: a bond, written in light."},
		{"loc": "Domino Back Alleys", "sub": "That evening", "theme": "battlecity"},
		{"s": "hunter", "t": "Well, well. Fresh rare cards walking around at night."},
		{"s": "lumen", "t": "That's one of Vellum's men! The Archivist's people!"},
		{"s": "hunter", "t": "Vellum sends his regards. And a little gift from another time..."},
		{"s": "", "t": "The Rare Hunter's deck pulses with a light that doesn't belong in this era.", "fx": "shake"},
		{"duel": {"opponent": "hunter", "deck": "echo", "lose_ok": false, "difficulty": 1, "field": "battlecity"}},
		{"s": "hunter", "t": "Impossible... a beginner beat the Synchro cards...!"},
		{"s": "player", "t": "Synchro? What's a Synchro?"},
		{"s": "lumen", "t": "Something that shouldn't exist here. Not for a long, long time. *bzzt* My head hurts..."},
		{"s": "yugi", "t": "{player}! It's Joey. He's at the pier, and he won't stop dueling. His eyes are... empty."},
		{"s": "lumen", "t": "The Curator's work. Joey's a Hollow, and he's getting worse."},
		{"s": "player", "t": "Then we're getting him back."},
		{"s": "yugi", "t": "Together. That's the only way I know how to do this."},
		{"end": "Chapter 1 complete", "unlock": "ch2"},
	],
}
