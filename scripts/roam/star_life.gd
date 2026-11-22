class_name StarLife
extends Node
## The main characters live a day of their own in the open world. Each has places by the hour
## and walks between them; where they are, they do something (eat, practice their draw, take a
## call, nap on the lawn, look over their cards); and they know you: they call out when you
## come by, and what they say depends on how your last duel with them went, your winning
## streak, the card you lead with, the hour and the weather.
##
## Free Roam only. In Story, and while a chapter's list rides along, everybody stays where the
## story has them.

const SAVE := "user://stars.cfg"
const WALK := 1.35

## Where each one is through the day: [from this minute, where, facing, what they do there].
## The stop with the latest start that has passed is where they are (before the first one of
## the day they are still at the last one from the night before).
## Doing: cards | phone | eat | drink | practice | arms | sky | nap | tinker | disk | cheer | chat
const DAYS := {
	"domino": {
		"yugi": [[390, Vector3(-6.6, 0, -12.6), 0.0, "cards"], [690, Vector3(15.0, 0, 16.5), -2.3, "chat"], [960, Vector3(8.6, 0, 8.6), -2.4, "cheer"], [1200, Vector3(-7.4, 0, -9.6), 0.5, "sky"]],
		"joey": [[420, Vector3(12.0, 0, 6.0), -1.6, "practice"], [690, Vector3(21.5, 0, -6.6), 0.4, "eat"], [900, Vector3(11.0, 0, -9.2), 2.9, "cheer"], [1100, Vector3(6.0, 0, 55.0), 3.1, "sky"], [1330, Vector3(12.0, 0, 6.0), -1.6, "practice"]],
		"mai": [[450, Vector3(19.0, 0, -18.0), -2.4, "phone"], [750, Vector3(24.0, 0, -22.0), 2.6, "cards"], [1040, Vector3(12.0, 0, 46.0), 3.0, "sky"], [1270, Vector3(19.0, 0, -18.0), -2.4, "arms"]],
		"kaiba": [[400, Vector3(-4.4, 0, -48.4), 0.3, "phone"], [720, Vector3(6.0, 0, -44.0), -0.5, "disk"], [990, Vector3(0.0, 0, -40.5), 0.0, "arms"], [1290, Vector3(-4.4, 0, -48.4), 0.3, "arms"]],
	},
	"academy": {
		"jaden": [[360, Vector3(16.0, 0, 14.0), 0.6, "nap"], [570, Vector3(2.2, 0, -27.0), 0.0, "practice"], [780, Vector3(3.5, 0, 3.0), 2.4, "eat"], [960, Vector3(19.0, 0, 21.5), 0.0, "practice"], [1200, Vector3(-32.0, 0, 9.0), 1.57, "sky"]],
		"chazz": [[420, Vector3(-26.0, 0, -14.0), 0.6, "arms"], [720, Vector3(22.0, 0, -16.5), 3.14, "practice"], [1020, Vector3(-9.5, 0, -9.0), 0.8, "phone"], [1260, Vector3(-26.0, 0, -14.0), 0.6, "arms"]],
		"alexis": [[420, Vector3(6.0, 0, -22.0), 2.9, "cards"], [720, Vector3(40.0, 0, 28.5), 2.2, "sky"], [990, Vector3(11.5, 0, 27.0), 1.2, "cheer"], [1230, Vector3(-22.0, 0, -12.5), 0.3, "sky"]],
		# Crowler: the steps of the main building as classes start, the lecture hall door, the
		# practice fields to judge the Blues, tea on the plaza, the Blue dorm at night.
		"crowler": [[450, Vector3(-5.0, 0, -28.5), 0.0, "arms"], [600, Vector3(34.0, 0, -19.0), 1.57, "cards"], [870, Vector3(22.5, 0, -25.5), 3.14, "arms"],
			[1080, Vector3(-4.5, 0, -6.0), 2.4, "drink"], [1260, Vector3(-25.0, 0, -15.5), 0.9, "sky"]],
		# Sheppard: the first ferry at the dock, his office in the main building, the plaza to watch
		# the students duel, the dock again at sunset, the office late.
		"sheppard": [[420, Vector3(1.2, 0, 63.0), 3.14, "sky"], [570, Vector3(6.0, 0, -29.5), 3.14, "phone"], [810, Vector3(-6.5, 0, 4.0), 1.2, "cheer"],
			[1020, Vector3(-1.2, 0, 62.0), 3.14, "sky"], [1230, Vector3(6.0, 0, -29.5), 3.14, "phone"]],
		# Bastion: the Yellow dorm yard, the library door with his notes, the practice fields, home.
		"bastion": [[420, Vector3(29.0, 0, -1.0), -1.57, "cards"], [660, Vector3(-16.5, 0, 28.5), -1.57, "cards"], [900, Vector3(24.0, 0, -24.0), 0.0, "practice"],
			[1140, Vector3(29.0, 0, -6.5), -1.2, "sky"]],
	},
	"satellite": {
		"yusei": [[360, Vector3(-8.0, 0, 11.0), 0.4, "tinker"], [750, Vector3(15.0, 0, 11.5), 0.6, "eat"], [960, Vector3(-9.0, 0, -6.0), 1.0, "arms"], [1230, Vector3(-8.0, 0, 11.0), 0.4, "tinker"]],
		"crow": [[420, Vector3(17.0, 0, 11.5), -1.9, "eat"], [690, Vector3(-6.0, 0, 21.0), 0.0, "chat"], [960, Vector3(9.0, 0, 6.5), -2.2, "cheer"], [1260, Vector3(20.0, 0, -11.0), -0.6, "sky"]],
	},
	"newdomino": {
		"jack": [[420, Vector3(3.5, 0, -27.5), 0.3, "arms"], [750, Vector3(-24.0, 0, 24.5), 2.4, "drink"], [1020, Vector3(-2.0, 0, 13.0), 0.0, "arms"], [1260, Vector3(3.5, 0, -27.5), 0.3, "sky"]],
		"akiza": [[420, Vector3(33.5, 0, -2.0), -1.6, "cards"], [780, Vector3(30.0, 0, 21.0), 0.8, "cards"], [1020, Vector3(7.0, 0, 1.0), -1.0, "sky"], [1260, Vector3(33.5, 0, -2.0), -1.6, "sky"]],
	},
	"heartland": {
		"yuma": [[400, Vector3(-5.0, 0, 12.0), 0.3, "practice"], [720, Vector3(18.0, 0, 13.5), 0.6, "eat"], [990, Vector3(-20.0, 0, 16.5), -1.0, "cheer"], [1230, Vector3(4.5, 0, 22.5), 3.14, "sky"]],
		"shark": [[420, Vector3(19.0, 0, 4.0), -1.6, "arms"], [750, Vector3(-4.5, 0, 22.0), 3.14, "sky"], [1020, Vector3(20.0, 0, -11.0), 0.8, "arms"], [1290, Vector3(19.0, 0, 4.0), -1.6, "arms"]],
		"kite": [[420, Vector3(-3.0, 0, -24.0), 0.2, "arms"], [780, Vector3(-18.0, 0, -13.0), -1.0, "phone"], [1050, Vector3(-4.0, 0, -30.5), 0.0, "sky"], [1300, Vector3(-3.0, 0, -24.0), 0.2, "arms"]],
	},
}

## What they do with their hands and body while they are at a stop.
const ACTS := {
	"cards": ["read"], "phone": ["phone", "phone", "listen"], "eat": ["eat"],
	"drink": ["eat"], "practice": ["challenge", "challenge", "stomp", "cheer"], "arms": ["armsx", "armsx", "listen"],
	"sky": ["skygaze"], "tinker": ["tinker"], "disk": ["disk"], "cheer": ["cheer", "cheer2", "agree"], "chat": ["chat", "agree", "listen"],
	"nap": [], "duel": ["disk", "armsx", "disk"],
}
## The motions that are the business itself (they run on, with only a breath between).
const STEADY := ["read", "eat", "tinker", "disk", "armsx", "skygaze"]
## Who keeps to themselves: a nod where the others wave.
const ALOOF := ["kaiba", "mai", "chazz", "jack", "shark", "kite", "akiza", "crowler"]

## What they say. "hail": called out as you come by. Then what a talk opens with, the first that
## fits: "beat_me" (you won your last duel with them), "beat_you" (you lost it), "streak" (three
## wins in a row or more), "ace" (the card you lead with changed; %s is its name), "rain",
## "morning", "night", else "hello". "leave": said as they walk off. "do": a word about what they
## are doing. All of it ours, written to sound like them.
const TALK := {
	"yugi": {"hail": ["{player}! Over here!", "Hey, {player}! Got a minute?"], "hello": ["Good to see you, {player}. How is the deck coming along?", "I was just thinking about you. Funny how that works."],
		"morning": ["Morning, {player}! Grandpa already has the shutters up."], "night": ["Still out, {player}? The city is quieter at night. I like it."], "rain": ["Careful with your cards in this rain. Sleeves, {player}. Always sleeves."],
		"beat_me": ["That last duel... you saw a play I never did. I have been turning it over all day."], "beat_you": ["Do not let our last duel get to you. You were one draw away. I felt it."],
		"streak": ["People are talking about your winning streak. Do not let it rush you. Play each card like it is the first."], "ace": ["So you lead with %s now. It suits you. Trust it and it will answer."],
		"leave": ["I should get going. See you around, {player}!"],
		"do": {"cards": "I am trying one small change in my deck. One card. It is always one card.", "chat": "The park is where I think best. Decks make more sense under a tree.", "cheer": "I like to watch the street duels. You learn the most from other people's turns.", "sky": "Grandpa says the stars are just cards nobody has drawn yet."}},
	"joey": {"hail": ["Yo, {player}! Get over here!", "Hey hey, look who it is!"], "hello": ["{player}! Ya eat yet? Never duel hungry, that's rule one.", "There ya are. I was startin' to think ya were duckin' me."],
		"morning": ["Mornin'! I'm up early, can ya believe it? Me neither."], "night": ["Night's the best time on these streets. Nobody tells ya to go home."], "rain": ["Aw man, this rain. My hair takes an hour, ya know."],
		"beat_me": ["Okay, okay. Ya got me last time. Luck! Mostly luck. ...Some skill."], "beat_you": ["Heh. Still feelin' that last one? Don't sweat it. I lost a hundred before I won ten."],
		"streak": ["I hear you're on a roll! Don't go gettin' a big head, that's MY thing."], "ace": ["%s, huh? Not bad. Flashy. I like flashy."],
		"leave": ["Gotta run. Later, {player}!"],
		"do": {"practice": "I'm workin' on my draw. Ya gotta believe in it BEFORE ya look. That's the trick.", "eat": "Best burger in Domino, right here. Don't tell 'em I said so, they'll raise the price.", "cheer": "I got the high score on that machine once. For about a minute.", "sky": "I come out here when I gotta think. Don't laugh. I think sometimes."}},
	"mai": {"hail": ["Well, well. {player}.", "Over here, hon."], "hello": ["You again. I am starting to think you like losing to me.", "Make it quick, {player}. I have a schedule. Sort of."],
		"morning": ["Up this early? I am impressed. A little."], "night": ["The city looks better at night. So do I, frankly."], "rain": ["If this rain ruins my jacket, somebody is paying for it."],
		"beat_me": ["Do not look so pleased with yourself. One win does not make a pattern."], "beat_you": ["Still sore about last time? Good. Use it."],
		"streak": ["A winning streak. Cute. Streaks end, hon. Usually against me."], "ace": ["%s? Now that is a card with some style. Finally."],
		"leave": ["That is enough standing around. Ciao."],
		"do": {"phone": "Tournament organizers. They call, I let it ring. Then I call back when it suits me.", "cards": "A deck is like an outfit. If one piece is wrong, everybody notices.", "sky": "I like the harbor. Ships leave whenever they want. Smart.", "arms": "I am not waiting for anyone. I am deciding who is worth my time."}},
	"kaiba": {"hail": ["You. Do not waste my time.", "{player}. Hmph."], "hello": ["Speak. You have thirty seconds of my day.", "If this is not about a duel, it is not about anything."],
		"morning": ["I have been working since four. What is your excuse?"], "night": ["The tower lights stay on because I do. Remember that."], "rain": ["Rain does not stop my company. It will not stop a duel either."],
		"beat_me": ["One result. A data point. I have already corrected for it."], "beat_you": ["You lost because you hesitated. I do not hesitate."],
		"streak": ["A streak against amateurs proves nothing. Bring it to me."], "ace": ["%s. A reasonable choice. For someone at your level."],
		"leave": ["I have a company to run."],
		"do": {"phone": "Hold on. ...No. Rebuild it by Friday or find other work. ...Now. What do you want?", "disk": "The new Duel Disk is two grams too heavy. Two grams is unacceptable.", "arms": "I am looking at my city. Do not stand in the way of it."}},
	"jaden": {"hail": ["{player}! Hey! Over here!", "Yo, {player}! Perfect timing!"], "hello": ["{player}! Tell me you brought your deck. You always bring your deck, right?", "Man, what a great day for a duel. Every day is, really."],
		"morning": ["Morning! I may have missed first period. And second."], "night": ["I can never sleep after a good duel. So I duel some more."], "rain": ["Rain duels are the best. Everything feels bigger!"],
		"beat_me": ["That last duel was awesome! You got me fair and square. Again? Right now?"], "beat_you": ["Hey, you almost had me last time! That was a sweet game."],
		"streak": ["I heard you keep winning! That means the next one is going to be really fun."], "ace": ["Whoa, you are running %s now? I have to see that in a duel."],
		"leave": ["Oh man, I am late again! Catch you later!"], "woke": ["Huh? Wha... I was awake. Totally awake. Resting my eyes."],
		"do": {"nap": "Zzz... five more minutes, professor...", "practice": "I do not really practice. I just duel a lot. Same thing, more fun.", "eat": "Lunch is my second favorite class. Dueling is all the others.", "sky": "The Red dorm has the best view on the island. Do not tell the Blues."}},
	"chazz": {"hail": ["You there. Yes, you.", "{player}. Stop gawking."], "hello": ["You may speak to me. Briefly.", "Do you have any idea who you are talking to? Good. Then be quick."],
		"morning": ["I rise early. Greatness does not sleep in."], "night": ["I am not out here brooding. I am strategizing. In the dark. Alone."], "rain": ["This weather is beneath me."],
		"beat_me": ["That duel did not count. I was distracted. By how badly you were playing."], "beat_you": ["And that is why they say my name around here. Remember how it felt."],
		"streak": ["A winning streak? Everyone has one before they meet me."], "ace": ["%s? Hm. It will lose with dignity, at least."],
		"leave": ["I have better places to be. All of them."],
		"do": {"arms": "I am not waiting for anybody. People wait for me.", "practice": "I am perfecting something. You would not understand it.", "phone": "My family calls. I let them wait. It builds character. Theirs."}},
	"alexis": {"hail": ["{player}. Good, I wanted to see you.", "Hey, {player}."], "hello": ["You look like you have a duel on your mind. You usually do.", "Good timing. I needed a break from everyone asking me for advice."],
		"morning": ["Morning. The island is at its best before the boys wake up."], "night": ["I walk at night to clear my head. It works about half the time."], "rain": ["I do not mind the rain. It keeps the courtyard quiet."],
		"beat_me": ["You earned that last win. I have gone over it twice and I would still lose that turn."], "beat_you": ["Last time you went all in a turn too early. Patience wins more duels than power."],
		"streak": ["So the streak is real. Good. I like an opponent who is in form."], "ace": ["Leading with %s is a bold choice. Bold is fine if you can back it up."],
		"leave": ["I should go. Take care of yourself, {player}."],
		"do": {"cards": "I rebuild my deck every week. Not because it is wrong. Because I am not done.", "sky": "From here you can see the whole island. It makes the dorm rivalries look small.", "cheer": "I like watching the first-years. They make mistakes I had forgotten existed."}},
	"crowler": {"hail": ["You there! Yes, you.", "{player}! A word."], "hello": ["Make it brief. I have forty exam papers and one red pen.", "Ah. One of mine. Or one of Sato's. I can never tell until you duel."],
		"morning": ["Classes start at nine. Punctuality is the first card in any deck."], "night": ["Out after curfew? I did not see you. I am looking at the stars. Professionally."], "rain": ["Rain. My good boots. Of course."],
		"beat_me": ["About our last duel. I was testing a theory. The theory was wrong. You may go."], "beat_you": ["You lost our last duel by one turn of thinking. Study, and come back."],
		"streak": ["Everyone in the staff room is saying your name. I do not care for it. Prove them right, then."], "ace": ["%s? Hm. Not without merit. Not without flaws, either."],
		"leave": ["I have a lecture to deliver. Somebody has to educate this island."],
		"do": {"arms": "I am watching the students arrive. I can tell who did their reading by the way they walk.", "cards": "Exam papers. Half of them summoned in Attack Position into a set card. Half!", "drink": "Tea. A gentleman takes his tea before evening rounds. Do not tell the Red dorm.", "sky": "I am counting the lights in the Blue dorm. Lights out is at eleven. I am very patient."}},
	"sheppard": {"hail": ["{player}! Come here a moment.", "Ah, {player}. Good."], "hello": ["How is island life treating you? Eat properly. Sleep a little. Duel a lot.", "I like to know every student by name. You make it easy."],
		"morning": ["The first ferry. I meet it every morning. You never know who is on it."], "night": ["Still up? So am I. A headmaster's work is never quite done."], "rain": ["A little rain never closed this school. Mind the steps."],
		"beat_me": ["You beat me fair and square last time. I told the whole staff room. Twice."], "beat_you": ["About our last duel: you were closer than you think. I only had experience on my side."],
		"streak": ["Your winning streak is the talk of the staff room. Enjoy it. And keep your feet on the ground."], "ace": ["You lead with %s now? A fine card. Look after it and it will look after you."],
		"leave": ["Off I go. The paperwork will not sign itself, sadly."],
		"do": {"sky": "I watch the ferry come in. Every new face on this island started right here.", "phone": "...Yes, the budget. I know. ...We will manage. We always do. Ah, {player}! Sorry about that.", "cheer": "I come down to the plaza to watch the students duel. It is the best part of my day."}},
	"bastion": {"hail": ["{player}! Just the person.", "Ah, {player}. Have you got a moment?"], "hello": ["I have been revising my deck. Version forty-one. I think this is the one.", "Good timing. I needed a second opinion on a combination."],
		"morning": ["Up early. The chalkboard is cleaner in the morning."], "night": ["I think best at night. The numbers are quieter."], "rain": ["Rain improves my concentration by roughly twelve percent. I measured it."],
		"beat_me": ["Our last duel. I have run it through eleven times and you still win. Well done."], "beat_you": ["About last time: you were one card short of a different result. I checked."],
		"streak": ["Your winning streak is statistically remarkable. I would like to be the outlier that ends it."], "ace": ["%s, is it? I shall have to add a new term to my equations."],
		"leave": ["Excuse me. I have a formula half finished on the chalkboard."],
		"do": {"cards": "Notes. Every duel on this island, by dorm, by deck and by turn. It is a hobby.", "practice": "I am testing a new opening. Three draws, three outcomes, one answer.", "sky": "The Yellow dorm has the best sunset on the island. The Blues would disagree. They are wrong."}},
	"yusei": {"hail": ["{player}.", "Over here, {player}."], "hello": ["{player}. Everything running all right?", "Good to see you. I could use a second pair of eyes, actually."],
		"morning": ["Early start. The engine does not tune itself."], "night": ["The Satellite is quiet at night. You can hear every loose bolt."], "rain": ["Rain is hard on the electronics. Keep your Duel Disk dry."],
		"beat_me": ["That last duel. Clean. You left me no opening."], "beat_you": ["You had the pieces last time. The order was off. It will come."],
		"streak": ["A winning streak. Do not chase it. Just keep building."], "ace": ["%s. A solid core to build around."],
		"leave": ["I have to get back to it. See you."],
		"do": {"tinker": "The intake is running rich. Half a turn on this and it should settle.", "eat": "Crow says I forget to eat. He is right, so here I am.", "arms": "I come to the ring to watch how people ride out a bad hand. That tells you everything."}},
	"crow": {"hail": ["Hey, {player}! Over here!", "{player}! Just the duelist I wanted!"], "hello": ["{player}! What is the word on the street? Besides me.", "There you are! The kids keep asking when you are coming by."],
		"morning": ["Morning! Deliveries done, breakfast done, now the fun part."], "night": ["Night shift is the best shift. No traffic, no bosses."], "rain": ["A little rain never grounded a bird."],
		"beat_me": ["All right, you got me last time. I am telling the kids I let you win."], "beat_you": ["Do not hang your head over last time. You went down swinging."],
		"streak": ["Look at you, winning left and right! Save one of those for me."], "ace": ["%s, eh? Nice. Not as cool as a Blackwing, but nice."],
		"leave": ["Got to fly. Catch you later!"],
		"do": {"eat": "Two for me, six to go. The little ones eat more than my runner.", "chat": "I know every driver on this route. Half of them owe me a duel.", "cheer": "I love a good crowd. Makes a bad draw feel like part of the show.", "sky": "You can see the city lights from here. Used to make me mad. Now it is just a view."}},
	"jack": {"hail": ["You! Approach.", "{player}. The King will see you."], "hello": ["Speak, challenger. A King listens. Briefly.", "You stand before the best. Try to look worthy of it."],
		"morning": ["A King greets the sun as an equal."], "night": ["The city lights are a crown. Mine, naturally."], "rain": ["Even the sky weeps at my opponents' chances."],
		"beat_me": ["One fall does not unseat a King. It only makes the return grander."], "beat_you": ["You felt it last time. That is what the top looks like."],
		"streak": ["A streak? Good. A King wants challengers who arrive with momentum."], "ace": ["%s. Hm. It has presence. Not a King's presence, but presence."],
		"leave": ["My public awaits."],
		"do": {"arms": "I am not standing here. I am being seen. There is a difference.", "drink": "This cup costs more than your deck. It is worth every coin.", "sky": "I look at the stadium and it looks back. We understand each other."}},
	"akiza": {"hail": ["{player}.", "Oh. {player}. Hello."], "hello": ["I did not expect company. I do not mind it.", "{player}. You are one of the few people who does not flinch around me."],
		"morning": ["The garden is best in the morning, before anyone comes to stare."], "night": ["At night the roses close. I envy them a little."], "rain": ["The roses need this rain. So I will not complain about it."],
		"beat_me": ["You beat me last time and then you were kind about it. I am not used to either."], "beat_you": ["I am sorry about last time. I do not always know my own strength."],
		"streak": ["You keep winning. People will start to fear you. Do not let them."], "ace": ["%s. It is a strong card. Be gentle with what is strong."],
		"leave": ["I should go. Thank you for stopping."],
		"do": {"cards": "Each card is a seed. Most of a duel is deciding what to let grow.", "sky": "I come here to be nobody for a while."}},
	"yuma": {"hail": ["{player}! Heeey! Over here!", "Whoa, {player}! Wait up!"], "hello": ["{player}! Duel me! No wait, talk first, then duel me!", "I have been running around all day and I am still not tired!"],
		"morning": ["Morning! I already fell down the stairs once. Good sign!"], "night": ["I am supposed to be home. Do not tell my sister."], "rain": ["Rain cannot stop me! It can slow me down a little."],
		"beat_me": ["You beat me last time! That was so cool! Now I get to try again, which is even cooler!"], "beat_you": ["Do not be down about last time! You only really lose when you stop trying."],
		"streak": ["You keep winning?! Teach me! No, duel me! Both!"], "ace": ["%s?! That card looks awesome! Show me!"],
		"leave": ["Ah, I am late! Got to jet!"],
		"do": {"practice": "I am practicing my jump. And my draw. Mostly my jump.", "eat": "Duel fuel! You cannot go all out on an empty stomach.", "cheer": "Did you see that play?! I did not get it either, but wow!", "sky": "When I look up I feel like I could reach it. One jump at a time."}},
	"shark": {"hail": ["Hey. {player}.", "You. Got a second?"], "hello": ["What. ...Fine. Talk.", "You are either brave or you have nowhere else to be."],
		"morning": ["Too early. Keep it short."], "night": ["Night is fine. Fewer people."], "rain": ["Rain is just more water. I am fine with water."],
		"beat_me": ["Do not get used to it. Last time was last time."], "beat_you": ["You went under last time. Come back up or stay there. Your call."],
		"streak": ["A streak. Everything looks easy until something bites."], "ace": ["%s. Not bad. It has teeth."],
		"leave": ["I am out."],
		"do": {"arms": "I am not hanging around. I am keeping an eye on things.", "sky": "The fountain is the closest thing this place has to the sea. It will do."}},
	"kite": {"hail": ["{player}. A word.", "You. Hold still."], "hello": ["State your business. My time is counted.", "You again. You keep turning up where I am working."],
		"morning": ["I do not keep mornings. I keep hours."], "night": ["Night is when the work gets done."], "rain": ["Weather is irrelevant."],
		"beat_me": ["You won the last one. I have reviewed it. It will not happen the same way twice."], "beat_you": ["Last time you were outmatched. That is information, not an insult."],
		"streak": ["A streak makes you worth hunting. Noted."], "ace": ["%s. Efficient. I would have chosen the same."],
		"leave": ["I have somewhere to be."],
		"do": {"arms": "I am watching the tower. Someone has to.", "phone": "...Understood. Keep him comfortable. I will be back before dark. ...What is it, {player}?", "sky": "From the foot of the tower the sky is a narrow thing. I prefer it that way."}},
}

## How each of them asks for a duel: the first time, and once you have beaten them.
const ASK := {
	"yugi": ["Want to duel? I would like to see how your deck has grown.", "One more? I learned something last time. Let me show you."],
	"joey": ["So whaddya say? You and me, right here, right now!", "Rematch! I been waitin' for this. No holdin' back!"],
	"mai": ["Care to duel? I could use the entertainment.", "A rematch? Fine. I do not lose to the same person twice."],
	"kaiba": ["Activate your Duel Disk. I will make this quick.", "Again. This time I show you the gap between us."],
	"jaden": ["So, want to throw down? Get your game on!", "Rematch! Come on, that last one was too much fun!"],
	"chazz": ["Duel me. Then you will know your place.", "Again. That last one was a fluke and we both know it."],
	"alexis": ["Shall we duel? I want to see what you have got.", "A rematch, then. I have had time to think about last time."],
	"crowler": ["A duel? Very well. This counts toward nothing, but I will grade it anyway.", "A rematch. Good. Let us correct the record."],
	"sheppard": ["Would you duel an old man? I promise not to go easy on you.", "Another? Splendid. I have been looking forward to it."],
	"bastion": ["Shall we duel? I have a hypothesis to test.", "A rematch? Excellent. I have revised the formula since."],
	"yusei": ["Want to duel? A deck only shows what it is under pressure.", "Again? Good. I made some adjustments."],
	"crow": ["How about a duel? Loser buys lunch!", "Rematch! The kids are still laughing at me. Help me fix that."],
	"jack": ["Duel me, challenger. Show the King what you have.", "Again! The King reclaims what is his!"],
	"akiza": ["Would you duel me? You are not afraid. I can tell.", "Once more? I will try to be gentle. I may not manage."],
	"yuma": ["Duel me! I am feeling the flow!", "Again, again! This time I am going to get you!"],
	"shark": ["You want a duel or not? Dive in.", "Round two. This time you sink."],
	"kite": ["Duel me. I will take what I need from it.", "Again. I have studied your deck since."],
}

## How well they know you, in points: a talk a day, duels with them, watching their duels,
## turning up when they ask. Each step up brings something (see _bond_check). The friendly ones
## call it friendship, the proud ones a rivalry: the same ladder under two names.
const BOND_STEPS := [0, 12, 35, 70, 110]
const BOND_NAMES := [["Stranger", "Stranger"], ["Acquaintance", "On their radar"], ["Friend", "Rival"], ["Good friend", "Fierce rival"], ["Best friend", "Sworn rival"]]

var scene: Node
var _stars: Array = []
var _cam: StoryCamera
var _mem := {}
var _tick := 0.0
## A map of where one can walk in this world, one cell a meter, worked out once after the world
## is built (a few hundred cells a frame, so nothing stutters). Routes between stops are found
## on it, so they walk round houses, fountains and the duel ring instead of through them.
var _grid: AStarGrid2D
var _grid_ready := false
var _district := "domino"
var _day := 0
## The duel two of them are having right now: {key, a, b, d (the show), duels (who runs it)}.
var _show := {}
var _told := {}                # duels already announced this visit
var _slow := 0.0               # the things that are looked at twice a second, not every frame
var _here_for := 0.0           # seconds since you arrived (nobody comes looking for you at the door)
var _dare: Dictionary = {}     # whoever is on the way to challenge you
const SEEK := 2.3


static func _load_mem() -> Dictionary:
	var cfg := ConfigFile.new()
	return cfg.get_value("m", "stars", {}) if cfg.load(SAVE) == OK else {}


static func _save_mem(m: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("m", "stars", m)
	cfg.save(SAVE)


## A street duel with one of them just ended: they will have something to say about it.
static func note_duel(who: String, won: bool) -> void:
	if not TALK.has(who):
		return
	var m := _load_mem()
	var e: Dictionary = m.get(who, {})
	e["fresh"] = "won" if won else "lost"
	e["bond"] = int(e.get("bond", 0)) + (5 if won else 3)       # a duel is a duel: they think more of you either way
	m[who] = e
	_save_mem(m)


static func rank_of(points: int) -> int:
	var r := 0
	for i in BOND_STEPS.size():
		if points >= int(BOND_STEPS[i]):
			r = i
	return r


static func rank_name(id: String, rank: int) -> String:
	return str(BOND_NAMES[clampi(rank, 0, BOND_NAMES.size() - 1)][1 if id in ALOOF else 0])


## Points with somebody go up (or down a little). Loud ones show a line on screen.
func _bond(id: String, n: int, loud := false) -> void:
	if not TALK.has(id) or n == 0:
		return
	var e: Dictionary = _mem.get(id, {})
	e["bond"] = maxi(0, int(e.get("bond", 0)) + n)
	_mem[id] = e
	_save_mem(_mem)
	if loud and n > 0:
		Router.toast(Loc.t("Bond with %s +%d") % [_short(id), n])
	_bond_check(id)


## A step up the ladder: say so and hand over what comes with it.
##   1: 100 Duel Points   2: a card from their deck   3: 300 Duel Points and a card
##   4: their own lead card and 500 Duel Points
func _bond_check(id: String) -> void:
	var e: Dictionary = _mem.get(id, {})
	var have := int(e.get("rank", 0))
	var now := rank_of(int(e.get("bond", 0)))
	if now <= have:
		return
	for r in range(have + 1, now + 1):
		Router.toast(Loc.t("%s now sees you as: %s") % [_short(id), Loc.t(rank_name(id, r))])
		var dp: int = [0, 100, 0, 300, 500][r]
		var card := 0
		if r == 2 or r == 3:
			card = _gift_from(id)
		elif r == 4:
			var key := str((_star(id).get("d", {}) as Dictionary).get("char", id))
			card = int(Characters.get_char(key).get("ace", 0))
			if card == 0:
				card = _gift_from(id)
		if dp > 0:
			Collection.dp += dp
			Router.toast(Loc.t("+%d Duel Points") % dp)
		if card != 0:
			Collection.add(card)
			Router.toast(Loc.t("%s gave you %s.") % [_short(id), Loc.t(str(CardData.get_card(card).get("name", "")))])
		if r == 2 or r == 4:
			e["rank_say"] = r
	e["rank"] = now
	_mem[id] = e
	_save_mem(_mem)
	Collection.save()
	Sfx.play("quest", -4.0)


func setup(roam: Node) -> void:
	scene = roam
	_mem = _load_mem()
	_district = str(Router.roam.get("district", "domino"))
	_day = WorldClock.day
	var here: Dictionary = DAYS.get(_district, {})
	if here.is_empty():
		return
	for a in OS.get_cmdline_user_args():
		# --stars-streak=N (testing): as if you had won N in a row, so somebody comes for you.
		# --stars-bond=id:points (testing): set how well somebody knows you.
		if a.begins_with("--stars-bond="):
			var bp := a.substr(13).split(":")
			if bp.size() == 2:
				var be: Dictionary = _mem.get(bp[0], {})
				be["bond"] = int(bp[1])
				_mem[bp[0]] = be
		if a.begins_with("--stars-streak="):
			Collection.record["streak"] = int(a.substr(15))
			_here_for = 20.0
			_mem.erase("_dare")
	_cam = StoryCamera.new(scene)
	for n in scene._npcs:
		var d: Dictionary = n[0]
		var id := str(d.get("id", ""))
		if not here.has(id):
			continue
		var fig: RoamFigure = n[1]
		var s := {"id": id, "fig": fig, "d": d, "stops": StarMeets.day_with(_district, id, here[id], _day), "base": here[id], "at": -1, "state": "there",
				"path": [], "doing": "", "act": 2.0, "hail": 0.0, "prop": null, "zzz": null, "stuck": 0.0, "body": null, "spots": {}}
		for c in fig.get_children():
			if c is PhysicsBody3D:
				s["body"] = c
		fig.greets = false
		_stars.append(s)
		# They start the visit where the hour has them, already at it.
		var i := _stop_now(s["stops"])
		s["at"] = i
		var spot := _spot(s, i)
		fig.position = spot
		fig.rotation.y = float(s["stops"][i][2])
		_start_doing(s, str(s["stops"][i][3]))
	_build_grid.call_deferred()
	# A duel just now may have taken you a step up with somebody: tell it once you are back.
	get_tree().create_timer(2.5).timeout.connect(func():
		for st in _stars:
			_bond_check(str(st["id"])))


func _build_grid() -> void:
	if _stars.is_empty():
		return
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for s in _stars:
		for st in s["stops"]:
			var p: Vector3 = st[1]
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	var x0 := int(floor(lo.x)) - 12
	var z0 := int(floor(lo.y)) - 12
	var w := int(ceil(hi.x)) + 12 - x0
	var h := int(ceil(hi.y)) + 12 - z0
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(x0, z0, w, h)
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	# People are not walls: nobody standing about counts as something in the way.
	var gcam := StoryCamera.new(scene)
	var rids: Array = [scene._player.get_rid()]
	for n in scene._npcs:
		for c in (n[1] as Node).get_children():
			if c is PhysicsBody3D:
				rids.append((c as PhysicsBody3D).get_rid())
	gcam.skip_rids = rids
	var domino := str(Router.roam.get("district", "domino")) == "domino"
	var done := 0
	for z in range(z0, z0 + h):
		for x in range(x0, x0 + w):
			if not is_inside_tree():
				return
			var id := Vector2i(x, z)
			if gcam.blocked_at(Vector3(x, 0, z)) != "":
				_grid.set_point_solid(id, true)
			elif domino and (absf(x) < 5.6 or absf(z) < 5.6) and absf(x) < 37.0 and absf(z) < 37.0:
				_grid.set_point_weight_scale(id, 5.0)      # the roads: cross them, do not stroll down them
			done += 1
			if done % 320 == 0:
				await get_tree().process_frame
	_grid_ready = true
	if "--stars-check" in OS.get_cmdline_user_args():
		_check()


func _free_cell(p: Vector3) -> Vector2i:
	var c := Vector2i(int(round(p.x)), int(round(p.z)))
	if _grid.is_in_boundsv(c) and not _grid.is_point_solid(c):
		return c
	for r in range(1, 5):
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c2 := c + Vector2i(dx, dz)
				if _grid.is_in_boundsv(c2) and not _grid.is_point_solid(c2):
					return c2
	return Vector2i(99999, 99999)


## Is the straight line from a to b walkable, without spending more of it on a road than
## `road_ok` cells? (A short cut must not turn a crossing into a stroll down the middle.)
func _cells_clear(a: Vector2, b: Vector2, road_ok := 0) -> bool:
	var n := int(ceil(a.distance_to(b) / 0.5))
	var on_road := {}
	for i in range(1, n):
		var p := a.lerp(b, i / float(n))
		var c := Vector2i(int(round(p.x)), int(round(p.y)))
		if not _grid.is_in_boundsv(c) or _grid.is_point_solid(c):
			return false
		if _grid.get_point_weight_scale(c) > 1.5:
			on_road[c] = true
	return on_road.size() <= road_ok


## The way from a to b as a few straight legs, or nothing if there is no way on foot.
func _route(a: Vector3, b: Vector3) -> Array:
	if not _grid_ready:
		return []
	var ca := _free_cell(a)
	var cb := _free_cell(b)
	if ca.x == 99999 or cb.x == 99999:
		return []
	var raw := _grid.get_point_path(ca, cb)
	if raw.is_empty():
		return []
	var out: Array = []
	var road: Array = []        # how many road cells the found way has up to each point
	var count := 0
	for pt in raw:
		if _grid.get_point_weight_scale(Vector2i(int(round(pt.x)), int(round(pt.y)))) > 1.5:
			count += 1
		road.append(count)
	var i := 0
	while i < raw.size() - 1:
		var j := raw.size() - 1
		while j > i + 1 and not _cells_clear(raw[i], raw[j], int(road[j]) - int(road[i]) + 1):
			j -= 1
		out.append(Vector3(raw[j].x, a.y, raw[j].y))
		i = j
	if out.is_empty() or (out[-1] as Vector3).distance_to(Vector3(b.x, a.y, b.z)) > 0.05:
		out.append(b)
	else:
		out[-1] = b
	return out


## Which stop of the day the hour falls in.
static func _stop_now(stops: Array) -> int:
	var now := WorldClock.minutes
	var best := stops.size() - 1
	for i in stops.size():
		if now >= float(stops[i][0]):
			best = i
	return best


## Where a stop really is: the place the day names, or the nearest free spot beside it if
## something stands there (a bench, a planter, another person).
func _spot(s: Dictionary, i: int) -> Vector3:
	var cache: Dictionary = s["spots"]
	if cache.has(i):
		return cache[i]
	var want: Vector3 = s["stops"][i][1]
	_skip_for(s)
	var out := want
	if _cam.blocked_at(want) != "":
		var found := false
		for ring in range(1, 7):
			for k in 8:
				var p := want + Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0)) * (ring * 0.7)
				if _cam.blocked_at(p) == "":
					out = p
					found = true
					break
			if found:
				break
	out.y = _floor_at(out)
	cache[i] = out
	return out


func _skip_for(s: Dictionary) -> void:
	var rids: Array = [scene._player.get_rid()]
	if s["body"] != null and is_instance_valid(s["body"]):
		rids.append((s["body"] as PhysicsBody3D).get_rid())
	_cam.skip_rids = rids


func _floor_at(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.2, 0), p + Vector3(0, -0.8, 0), 1)
	var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return p.y
	var y: float = (hit["position"] as Vector3).y
	return y if absf(y - p.y) < 0.7 else p.y


## Can they walk straight from a to b? Sampled every 0.8 m.
func _clear_until(a: Vector3, b: Vector3) -> float:
	var d := b - a
	d.y = 0.0
	var length := d.length()
	if length < 0.5:
		return length
	var dir := d / length
	var t := 0.8
	while t < length - 0.5:
		if _cam.blocked_at(a + dir * t) != "":
			return maxf(0.0, t - 0.9)
		t += 0.8
	return length


# ------------------------------------------------------------------ doing things

func _start_doing(s: Dictionary, doing: String) -> void:
	var fig: RoamFigure = s["fig"]
	s["doing"] = doing
	s["act"] = randf_range(0.3, 1.2)
	fig.stance = "stand"
	fig.watch = scene._player
	fig.set_speed(0.0)
	_drop(s)
	match doing:
		"duel":
			# On their side of the field, waiting for the other one. If today's duel is already
			# played they just stand and talk it over.
			if _meet_played(s):
				s["doing"] = "chat"
			else:
				fig.watch = null
		"nap":
			# Flat on the grass, hands behind the head by the look of it, and not to be woken.
			fig.watch = null
			fig.lively = false
			if fig._model:
				fig._model.rotation.x = -PI * 0.5
				fig._model.position.y = 0.2
				fig._model.position.z = 0.85
			var z := Label3D.new()
			z.text = "Z z z"
			z.font = UITheme.title_font()
			z.font_size = 48
			z.pixel_size = 0.005
			z.outline_size = 10
			z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			z.modulate = Color(0.85, 0.92, 1.0, 0.9)
			z.position = Vector3(0, 1.0, -0.4)
			fig.add_child(z)
			var tw := z.create_tween().set_loops()
			tw.tween_property(z, "position:y", 1.5, 1.8).set_trans(Tween.TRANS_SINE)
			tw.parallel().tween_property(z, "modulate:a", 0.0, 1.8)
			tw.tween_callback(func():
				z.position.y = 1.0
				z.modulate.a = 0.9)
			s["zzz"] = z
		"cards":
			_give(s, "cards", "LeftHand")
		"phone":
			_give(s, "phone", "RightHand")
		"eat":
			_give(s, "burger", "RightHand")
		"drink":
			_give(s, "cup", "RightHand")
		"tinker":
			_give(s, "tool", "RightHand")


## Up from whatever they were doing, hands empty.
func _drop(s: Dictionary) -> void:
	var fig: RoamFigure = s["fig"]
	if s["prop"] != null and is_instance_valid(s["prop"]):
		(s["prop"] as Node).queue_free()
	s["prop"] = null
	if s["zzz"] != null and is_instance_valid(s["zzz"]):
		(s["zzz"] as Node).queue_free()
		s["zzz"] = null
		fig.lively = true
		if fig._model:
			fig._model.rotation.x = 0.0
			fig._model.position.y = 0.0
			fig._model.position.z = 0.0


## Something small in a hand: a fan of cards, a phone, a burger, a cup, a spanner.
func _give(s: Dictionary, what: String, hand: String) -> void:
	var fig: RoamFigure = s["fig"]
	if fig._model == null:
		return
	var sk: Skeleton3D = Avatars._skeleton(fig._model)
	var b := Avatars.bone(fig._model, hand)
	if "--stars-check" in OS.get_cmdline_user_args():
		print("STAR ", s["id"], " holds ", what, " skeleton ", sk != null, " bone ", b, " scale ", sk.global_transform.basis.get_scale() if sk else Vector3.ZERO)
	if sk == null or b == -1:
		return
	var at := BoneAttachment3D.new()
	at.bone_idx = b
	sk.add_child(at)
	var hold := Node3D.new()
	at.add_child(hold)
	_size_prop.call_deferred(at.get_instance_id(), hold.get_instance_id())
	var city: CityBuilder = scene.city
	match what:
		"cards":
			for k in 4:
				var c := city.box(Vector3(0.062, 0.09, 0.002), Vector3((k - 1.5) * 0.022, 0.04, k * 0.003), city.mat(Color(0.5, 0.3, 0.16), 0.5), false, hold)
				c.rotation.z = -(k - 1.5) * 0.2
				c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		"phone":
			city.round_box(Vector3(0.07, 0.14, 0.012), Vector3(0, 0.04, 0), city.mat(Color(0.1, 0.11, 0.14), 0.3, 0.4), 0.004, hold)
			city.box(Vector3(0.06, 0.12, 0.002), Vector3(0, 0.04, 0.008), city.glow_mat(Color(0.6, 0.85, 1.0), 0.8), false, hold)
		"burger":
			city.cyl(0.055, 0.06, 0.03, Vector3(0, 0.0, 0), city.mat(Color(0.82, 0.58, 0.28), 0.8), hold, 10)
			city.cyl(0.062, 0.062, 0.016, Vector3(0, 0.022, 0), city.mat(Color(0.3, 0.6, 0.22), 0.8), hold, 10)
			city.cyl(0.058, 0.058, 0.02, Vector3(0, 0.04, 0), city.mat(Color(0.36, 0.2, 0.12), 0.8), hold, 10)
			city.cyl(0.04, 0.06, 0.035, Vector3(0, 0.066, 0), city.mat(Color(0.86, 0.62, 0.3), 0.8), hold, 10)
		"cup":
			city.cyl(0.04, 0.032, 0.11, Vector3(0, 0.03, 0), city.mat(Color(0.95, 0.95, 0.93), 0.5), hold, 10)
			city.cyl(0.042, 0.042, 0.012, Vector3(0, 0.09, 0), city.mat(Color(0.2, 0.14, 0.1), 0.5), hold, 10)
			city.cyl(0.041, 0.041, 0.04, Vector3(0, 0.03, 0), city.mat(Color(0.5, 0.3, 0.2), 0.8), hold, 10)
		"tool":
			city.box(Vector3(0.022, 0.2, 0.008), Vector3(0, 0.06, 0), city.mat(Color(0.75, 0.77, 0.8), 0.3, 0.8), false, hold)
			city.box(Vector3(0.05, 0.04, 0.01), Vector3(0, 0.17, 0), city.mat(Color(0.75, 0.77, 0.8), 0.3, 0.8), false, hold)
	s["prop"] = at


## The model may be built at any scale, bones included: once the hand knows where it is, the
## thing in it is sized in the world's meters.
func _size_prop(at_id: int, hold_id: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var at := instance_from_id(at_id) as Node3D
	var hold := instance_from_id(hold_id) as Node3D
	if at == null or hold == null or not is_instance_valid(at) or not is_instance_valid(hold):
		return
	var sc := maxf(at.global_transform.basis.get_scale().x, 0.0001)
	hold.scale = Vector3.ONE / sc
	hold.position = Vector3(0, 0.08, 0.035) / sc
	if "--stars-check" in OS.get_cmdline_user_args():
		print("STAR prop sized: hand scale ", sc, " prop world scale ", hold.global_transform.basis.get_scale())
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(hold):
			for c in hold.get_children():
				if c is MeshInstance3D:
					print("   piece at ", (c as MeshInstance3D).global_position.snapped(Vector3.ONE * 0.01), " world size ", ((c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()).size.snapped(Vector3.ONE * 0.001), " visible ", (c as MeshInstance3D).is_visible_in_tree(), " range ", (c as MeshInstance3D).visibility_range_end)


# ------------------------------------------------------------------ every frame

func _process(delta: float) -> void:
	if scene == null or scene.story != null or scene.quest != null:
		return
	var player: Node3D = scene._player
	var cam := get_viewport().get_camera_3d()
	if WorldClock.day != _day:
		_new_day()
	_here_for += delta
	for s in _stars:
		var fig: RoamFigure = s["fig"]
		if not is_instance_valid(fig):
			continue
		s["hail"] = float(s["hail"]) - delta
		var talking: bool = scene._talking and str(scene._dlg_npc.get("id", "")) == str(s["id"])
		if talking:
			fig.set_speed(0.0)
			continue
		var dist := fig.global_position.distance_to(player.global_position)
		match str(s["state"]):
			"seek":
				_seek(s, delta, dist)
			"there":
				if _in_show(s):
					continue            # the duel has them (StreetDuels moves them) until it is decided
				var i := _stop_now(s["stops"])
				if i != int(s["at"]) and not scene._overlay_open and _grid_ready:
					_leave(s, i, dist)
					continue
				_act(s, delta)
				_hail(s, dist)
			"walk":
				_walk(s, delta, dist, cam)
	_slow -= delta
	if _slow <= 0.0:
		_slow = 0.5
		_meets_step()
		_dare_step()
		_invite_step()


## Midnight: tomorrow's duels are other pairs, so everybody's day is put together again.
func _new_day() -> void:
	_day = WorldClock.day
	var here: Dictionary = DAYS.get(_district, {})
	for s in _stars:
		var keep: Vector3 = s["stops"][clampi(int(s["at"]), 0, (s["stops"] as Array).size() - 1)][1]
		s["stops"] = StarMeets.day_with(_district, str(s["id"]), here.get(s["id"], s["base"]), _day)
		s["spots"] = {}
		# The same place under its number in the new day, so nobody sets off for where they are.
		var stops: Array = s["stops"]
		for i in stops.size():
			if (stops[i][1] as Vector3).distance_to(keep) < 0.1:
				s["at"] = i
		var now := _stop_now(stops)
		if (stops[now][1] as Vector3).distance_to(keep) < 0.1:
			s["at"] = now


## Time to go: say so if you are near enough to hear, get up, and set off.
func _leave(s: Dictionary, i: int, dist: float) -> void:
	var fig: RoamFigure = s["fig"]
	_drop(s)
	s["doing"] = ""
	fig.stance = "stand"
	fig._cur_clip = ""
	if dist < 9.0 and scene.extras:
		scene.extras._say_over(fig, _line(str(s["id"]), "leave"), 2.6, last_src, Voices.voice_for(str(s["id"])))
	s["at"] = i
	_set_off(s, _spot(s, i))
	if "--stars-check" in OS.get_cmdline_user_args():
		print("STAR ", s["id"], " leaves at ", int(WorldClock.minutes), " for stop ", i, " legs ", (s["path"] as Array).size())


## Off they go to a spot: round the houses if there is a way on foot, else out of sight and in
## again at the far end.
func _set_off(s: Dictionary, to: Vector3) -> void:
	var fig: RoamFigure = s["fig"]
	_skip_for(s)
	var from := fig.position
	var way := _route(from, to)
	var reach := _clear_until(from, to)
	var whole := Vector3(to.x - from.x, 0, to.z - from.z).length()
	if not way.is_empty():
		s["path"] = way
	elif reach >= whole - 0.01:
		s["path"] = [to]
	else:
		# Something is in the way of a straight walk (a block of houses, the harbor wall): they
		# walk off as far as the way is clear, and come walking in at the other end.
		var dir := Vector3(to.x - from.x, 0, to.z - from.z).normalized()
		var out_len := minf(reach, 16.0)
		var back := _clear_until(to, from)
		var in_len := minf(back, 10.0)
		s["path"] = [from + dir * out_len, "jump", to - dir * in_len, to]
	s["state"] = "walk"
	s["stuck"] = 0.0


func _walk(s: Dictionary, delta: float, dist: float, cam: Camera3D) -> void:
	var fig: RoamFigure = s["fig"]
	var path: Array = s["path"]
	if path.is_empty():
		_arrive(s)
		return
	if path[0] is String:
		# Out of sight (or after a few seconds, if you insist on watching), they are at the far end.
		s["stuck"] = float(s["stuck"]) + delta
		fig.set_speed(0.0)
		var seen := dist < 46.0 and cam != null and cam.is_position_in_frustum(fig.global_position + Vector3(0, 1.0, 0))
		if not seen or float(s["stuck"]) > 5.0:
			path.pop_front()
			var next: Vector3 = path[0]
			path.pop_front()
			if seen:
				fig.scale = Vector3.ONE * 0.01
				create_tween().tween_property(fig, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			fig.position = Vector3(next.x, _floor_at(next), next.z)
			s["stuck"] = 0.0
		return
	var to: Vector3 = path[0]
	var d := Vector3(to.x - fig.position.x, 0, to.z - fig.position.z)
	if d.length() < 0.12:
		path.pop_front()
		if path.is_empty():
			_arrive(s)
		return
	if dist < 1.2:
		fig.set_speed(0.0)          # you are standing in their way: they wait for you to move
		return
	var step := minf(d.length(), WALK * delta)
	fig.position += d.normalized() * step
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		fig.position.y = lerpf(fig.position.y, _floor_at(fig.position), 0.6)
	fig.rotation.y = lerp_angle(fig.rotation.y, atan2(d.x, d.z), clampf(delta * 7.0, 0.0, 1.0))
	fig.set_speed(WALK)
	_hail(s, dist)


func _arrive(s: Dictionary) -> void:
	var fig: RoamFigure = s["fig"]
	var stop: Array = s["stops"][int(s["at"])]
	s["state"] = "there"
	fig.set_speed(0.0)
	if "--stars-check" in OS.get_cmdline_user_args():
		print("STAR ", s["id"], " arrived at ", int(WorldClock.minutes), " ", fig.position.snapped(Vector3.ONE * 0.1), " doing ", stop[3])
	create_tween().tween_property(fig, "rotation:y", fig.rotation.y + wrapf(float(stop[2]) - fig.rotation.y, -PI, PI), 0.4)
	_start_doing(s, str(stop[3]))


## The small motions of whatever they are doing, every few seconds.
func _act(s: Dictionary, delta: float) -> void:
	s["act"] = float(s["act"]) - delta
	if float(s["act"]) > 0.0:
		return
	s["act"] = randf_range(5.0, 10.0)
	var pool: Array = ACTS.get(str(s["doing"]), [])
	if pool.is_empty():
		return
	var fig: RoamFigure = s["fig"]
	var motion := str(pool[randi() % pool.size()])
	if fig.gesture(motion, 0.5):
		if motion in STEADY:
			s["act"] = fig._hold + randf_range(0.4, 1.6)
		elif fig._hold > 6.0:
			fig._hold = 6.0


## You come by: they call out (or, the ones who keep to themselves, give you a nod).
func _hail(s: Dictionary, dist: float) -> void:
	var id := str(s["id"])
	# Somebody who counts you a friend (or a rival) spots you from further off.
	var reach := 12.0 if rank_of(int((_mem.get(id, {}) as Dictionary).get("bond", 0))) >= 2 else 8.0
	if dist > reach or float(s["hail"]) > 0.0 or scene._talking or scene.extras == null:
		return
	var fig: RoamFigure = s["fig"]
	s["hail"] = randf_range(100.0, 150.0)
	if str(s["doing"]) == "nap":
		if dist < 4.5:
			scene.extras._say_over(fig, _line(id, "do", "nap"), 3.0, last_src, Voices.voice_for(id))
		else:
			s["hail"] = 0.0
		return
	scene.extras._say_over(fig, _line(id, "hail"), 2.8, last_src, Voices.voice_for(id))
	if str(s["state"]) == "there":
		if id in ALOOF:
			fig.do_nod()
		elif fig.gesture("wave", 0.3):
			fig._hold = minf(fig._hold, 3.2)
		s["act"] = 6.0


# ------------------------------------------------------------------ what they say

func _line(id: String, kind: String, sub := "") -> String:
	var t: Dictionary = TALK.get(id, {})
	var got = t.get(kind)
	if got == null:
		got = (StarMeets.MORE.get(id, {}) as Dictionary).get(kind)
	if sub != "" and got is Dictionary:
		got = (got as Dictionary).get(sub, "")
	var text := ""
	if got is Array and not (got as Array).is_empty():
		text = str((got as Array)[randi() % (got as Array).size()])
	elif got is String:
		text = str(got)
	last_src = text
	var shown := Loc.t(text).replace("{player}", Profile.duelist_name) if text != "" else ""
	if text != "":
		Voices.note_src(shown, text)
	return shown


## The English line the last _line() gave (its voice file is named after it).
var last_src := ""


## The card the player leads with: the strongest monster in the deck they have built.
static func my_ace() -> int:
	var best := 0
	var best_atk := -1
	for id in Collection.main:
		var d := CardData.get_card(int(id))
		if d.get("kind", "") == "monster" and int(d.get("atk", 0)) > best_atk:
			best_atk = int(d.get("atk", 0))
			best = int(id)
	return best


## Is this one of them, living their day here right now?
## What the map's "who is where" list says for each thing they do.
const DOING_TEXT := {
	"cards": "Going through a deck", "phone": "On the phone", "eat": "Having a bite", "drink": "Having a drink",
	"practice": "Practicing moves", "arms": "Watching the crowd", "sky": "Looking at the sky", "tinker": "Fixing something",
	"disk": "Tuning a Duel Disk", "cheer": "Watching the duels", "chat": "Hanging out", "nap": "Taking a nap",
}


## For the map: every main character out here, where they are right now, what they are at,
## and where the day takes them next.
func where() -> Array:
	var out: Array = []
	for s in _stars:
		var fig: RoamFigure = s["fig"]
		if not is_instance_valid(fig):
			continue
		var stops: Array = s["stops"]
		var i := clampi(int(s["at"]), 0, stops.size() - 1)
		var nxt: Array = stops[(i + 1) % stops.size()]
		var walking := str(s["state"]) == "walk"
		var doing := Loc.t(str(DOING_TEXT.get(str(stops[i][3]), "Hanging out")))
		if str(stops[i][3]) == "duel":
			# Who it is against: the other name in today's duel at this hour.
			var other := ""
			for m in StarMeets.today(_district, _day):
				if int(m["at"]) == int(stops[i][0]):
					other = str(m["b"]) if str(m["a"]) == str(s["id"]) else str(m["a"])
			if _in_show(s):
				doing = Loc.t("Dueling %s") % _short(other)
			elif _meet_played(s):
				doing = Loc.t("Talking over the duel with %s") % _short(other)
			else:
				doing = Loc.t("About to duel %s") % _short(other)
		if str(s["state"]) == "seek":
			doing = Loc.t("Looking for you")
		var pts := int((_mem.get(str(s["id"]), {}) as Dictionary).get("bond", 0))
		var rank := rank_of(pts)
		var frac := 1.0
		if rank + 1 < BOND_STEPS.size():
			frac = float(pts - int(BOND_STEPS[rank])) / float(int(BOND_STEPS[rank + 1]) - int(BOND_STEPS[rank]))
		out.append({"id": str(s["id"]), "fig": fig, "d": s["d"], "walking": walking,
				"bond": pts, "rank": rank, "rank_name": Loc.t(rank_name(str(s["id"]), rank)), "frac": frac, "ranks": BOND_STEPS.size() - 1,
				"doing": doing, "stop": stops[i][1],
				"next_min": int(nxt[0]), "next": nxt[1], "one_stop": stops.size() < 2})
	return out


## Their own way of asking for a duel ("" if they are not one of ours).
func ask(id: String, again: bool) -> String:
	if not has(id) or not ASK.has(id):
		return ""
	return str(ASK[id][1 if again else 0])


func has(id: String) -> bool:
	for s in _stars:
		if str(s["id"]) == id and is_instance_valid(s["fig"]):
			return true
	return false


## You walked up and talked to one of them. What they open with, and a word about what they are
## doing; `usual` is what they said before they had a life (kept as the fallback).
func lines(id: String, usual: Array) -> Array:
	var s := {}
	for e in _stars:
		if str(e["id"]) == id:
			s = e
	if s.is_empty():
		return usual
	if _in_show(s):
		return [_line(id, "busy")]
	if str(s["state"]) == "seek":
		# They came for a duel: that is all they have to say.
		s["talked"] = true
		return [_line(id, "dare")]
	var m: Dictionary = _mem.get(id, {})
	var out: Array = []
	var was_nap := str(s["doing"]) == "nap"
	if was_nap:
		# Talking to someone asleep wakes them.
		_drop(s)
		s["doing"] = "sky"
		out.append(_line(id, "woke"))
	var open := ""
	var today := WorldClock.day
	var streak := int(Collection.record.get("streak", 0))
	var ace := my_ace()
	if str(m.get("fresh", "")) != "":
		open = _line(id, "beat_me" if str(m["fresh"]) == "won" else "beat_you")
		m["fresh"] = ""
	elif int((m.get("bout", {}) as Dictionary).get("day", -1)) == today and not bool((m["bout"] as Dictionary).get("told", false)):
		# Their own duel today: they tell you how it went.
		var bt: Dictionary = m["bout"]
		open = _line(id, "bout_won" if bool(bt.get("won", false)) else "bout_lost")
		if open.contains("%s"):
			open = open % _short(str(bt.get("vs", "")))
			Voices.note_src(open, last_src % _short(str(bt.get("vs", ""))))
		bt["told"] = true
	elif streak >= 3 and int(m.get("streak_day", -1)) != today:
		open = _line(id, "streak")
		m["streak_day"] = today
	elif ace != 0 and int(m.get("ace", 0)) != ace and m.has("ace"):
		open = _line(id, "ace")
		if open.contains("%s"):
			# (Out loud the card is "that card": one file for the line, whatever you lead with.)
			open = open % Loc.t(str(CardData.get_card(ace).get("name", "")))
			Voices.note_src(open, last_src)
	elif scene.weather != null and scene.weather.raining and int(m.get("rain_day", -1)) != today:
		open = _line(id, "rain")
		m["rain_day"] = today
	elif int(m.get("day", -1)) != today and WorldClock.minutes >= 300.0 and WorldClock.minutes < 660.0:
		open = _line(id, "morning")
	elif int(m.get("night_day", -1)) != today and (WorldClock.minutes >= 1215.0 or WorldClock.minutes < 300.0):
		open = _line(id, "night")
		m["night_day"] = today
	if open == "":
		open = _line(id, "hello")
	if ace != 0:
		m["ace"] = ace
	var first_today := int(m.get("day", -1)) != today
	m["day"] = today
	m["talks"] = int(m.get("talks", 0)) + 1
	# The day they start calling you a friend or a rival, they say so before anything else.
	var said := int(m.get("rank_say", 0))
	if said != 0:
		m.erase("rank_say")
		var word := _line(id, "bond%d" % said)
		if word != "":
			out.append(word)
			open = ""
	_mem[id] = m
	_save_mem(_mem)
	if first_today:
		_bond(id, 2)
	if open != "":
		out.append(open)
	var doing := _line(id, "do", "sky" if was_nap else str(s["doing"]))
	if doing != "" and not was_nap:
		out.append(doing)
	var more := _invite_talk(s, int(m.get("talks", 0)), was_nap)
	if more.size() == 2 and bool(more[0]):
		return [more[1]]                 # you came to meet them: that is the whole talk
	if more.size() == 2:
		out.append(more[1])
	return out if not out.is_empty() else usual


# ------------------------------------------------------------------ their own duels

func _star(id: String) -> Dictionary:
	for s in _stars:
		if str(s["id"]) == id and is_instance_valid(s["fig"]):
			return s
	return {}


## The name people call them by.
func _short(id: String) -> String:
	return id.capitalize()


func _meet_key(at: int) -> String:
	return "%s:%d:%d" % [_district, _day, at]


## Has the duel this star is standing at already been played today?
func _meet_played(s: Dictionary) -> bool:
	var at := int(s["stops"][int(s["at"])][0])
	return (_mem.get("_bouts", {}) as Dictionary).has(_meet_key(at))


func _in_show(s: Dictionary) -> bool:
	if _show.is_empty():
		return false
	if not is_instance_valid(_show["duels"]) or not (_show["duels"] as StreetDuels).bout_on(_show["d"]):
		return false
	return is_same(_show["a"], s) or is_same(_show["b"], s)


## Are they in the middle of a duel of their own? (No challenging them now.)
func busy(id: String) -> bool:
	var s := _star(id)
	return not s.is_empty() and _in_show(s)


func _duels_node() -> StreetDuels:
	var life = scene.get("life")
	if life == null or not is_instance_valid(life):
		return null
	var dn = life.get("duels")
	return dn if dn != null and is_instance_valid(dn) else null


func _free_spot(p: Vector3) -> bool:
	_cam.skip_rids = [scene._player.get_rid()]
	return _cam.blocked_at(p) == ""


## Today's duels: say so when one is coming up, and start it once both stand on their side.
func _meets_step() -> void:
	if not _show.is_empty() and not _in_show(_show["a"]):
		_show = {}
	if not _show.is_empty():
		return
	var duels := _duels_node()
	if duels == null:
		return
	var now := WorldClock.minutes
	for m in StarMeets.today(_district, _day):
		var at := int(m["at"])
		var key := _meet_key(at)
		if (_mem.get("_bouts", {}) as Dictionary).has(key) or now < float(at) or now > float(at + StarMeets.WINDOW + 90):
			continue
		var a := _star(str(m["a"]))
		var b := _star(str(m["b"]))
		if a.is_empty() or b.is_empty():
			continue
		if not _told.has(key):
			_told[key] = true
			if now < float(at + 40):
				Router.toast(Loc.t("%s and %s are about to duel near %s.") % [_short(str(a["id"])), _short(str(b["id"])), Loc.t(StarMeets.place_near(scene.district, m["mid"]))])
		var ready := true
		for s in [a, b]:
			if str(s["state"]) != "there" or str(s["doing"]) != "duel" or int(s["stops"][int(s["at"])][0]) != at:
				ready = false
		if not ready:
			continue
		var fans := 4 if Settings.gfx_preset >= 2 else 2
		var d: Dictionary = duels.open_bout(a["fig"], b["fig"], [_short(str(a["id"])), _short(str(b["id"]))], [str(a["id"]), str(b["id"])], fans, float(m["fan_z"]),
				_free_spot, func(w: int, watched: bool): _bout_done(key, w, watched))
		_show = {"key": key, "a": a, "b": b, "d": d, "duels": duels, "mid": m["mid"]}
		if "--stars-check" in OS.get_cmdline_user_args():
			print("STAR bout opens ", key, " ", a["id"], " vs ", b["id"])
		return


func _bout_done(key: String, w: int, watched: bool) -> void:
	if _show.is_empty():
		return
	var a: Dictionary = _show["a"]
	var b: Dictionary = _show["b"]
	_show = {}
	var win: Dictionary = a if w == 0 else b
	var lose: Dictionary = b if w == 0 else a
	var bouts: Dictionary = _mem.get("_bouts", {})
	for k in bouts.keys():
		# Only today is kept.
		var parts := str(k).split(":")
		if parts.size() < 3 or int(parts[1]) != _day:
			bouts.erase(k)
	bouts[key] = {"w": str(win["id"]), "l": str(lose["id"])}
	_mem["_bouts"] = bouts
	for pair in [[win, lose, true], [lose, win, false]]:
		var e: Dictionary = _mem.get(str(pair[0]["id"]), {})
		e["bout"] = {"vs": str(pair[1]["id"]), "won": bool(pair[2]), "day": _day}
		_mem[str(pair[0]["id"])] = e
		pair[0]["doing"] = "chat"
		pair[0]["act"] = 4.0
		if is_instance_valid(pair[0]["fig"]):
			(pair[0]["fig"] as RoamFigure).watch = scene._player
	_save_mem(_mem)
	Router.toast(Loc.t("%s wins the duel against %s!") % [_short(str(win["id"])), _short(str(lose["id"]))])
	if watched:
		# You stood there for it: both of them noticed.
		_bond(str(win["id"]), 3, true)
		_bond(str(lose["id"]), 3, true)
		Collection.dp += 30
		Collection.daily_bump("watch")
		Collection.save()
		Router.toast(Loc.t("You watched the whole thing: +%d Duel Points") % 30)
		Sfx.play("coin", -5.0)
	if "--stars-check" in OS.get_cmdline_user_args():
		print("STAR bout over ", key, " winner ", win["id"], " watched ", watched)


## For the map: today's duels here. [{at, a, b, mid, state: "later" | "now" | "over", winner}]
func meets_today() -> Array:
	var out: Array = []
	var bouts: Dictionary = _mem.get("_bouts", {})
	for m in StarMeets.today(_district, _day):
		if _star(str(m["a"])).is_empty() or _star(str(m["b"])).is_empty():
			continue
		var key := _meet_key(int(m["at"]))
		var state := "later"
		var winner := ""
		if bouts.has(key):
			state = "over"
			winner = _short(str((bouts[key] as Dictionary).get("w", "")))
		elif not _show.is_empty() and str(_show["key"]) == key:
			state = "now"
		elif WorldClock.minutes > float(int(m["at"]) + StarMeets.WINDOW + 90):
			continue
		elif WorldClock.minutes >= float(m["at"]):
			state = "soon"
		out.append({"at": int(m["at"]), "a": _short(str(m["a"])), "b": _short(str(m["b"])), "mid": m["mid"], "state": state, "winner": winner})
	return out


# ------------------------------------------------------------------ they come to you

## You keep winning: once a day somebody nearby comes over to put a stop to it.
func _dare_step() -> void:
	if not _dare.is_empty() or not _grid_ready or _here_for < 25.0 or scene.extras == null:
		return
	if int(Collection.record.get("streak", 0)) < 3:
		return
	var days: Dictionary = _mem.get("_dare", {})
	if int(days.get(_district, -1)) == _day:
		return
	if str(scene._inside) != "" or scene._talking or scene._overlay_open or not _show.is_empty():
		return
	var pp: Vector3 = scene._player.global_position
	var best := {}
	var best_d := 60.0
	for s in _stars:
		if str(s["state"]) != "there" or str(s["doing"]) in ["duel", "nap", ""] or not (s["d"] as Dictionary).has("duel"):
			continue
		var dd := (s["fig"] as RoamFigure).global_position.distance_to(pp)
		if dd > 9.0 and dd < best_d:
			best_d = dd
			best = s
	if best.is_empty():
		return
	days[_district] = _day
	_mem["_dare"] = days
	_save_mem(_mem)
	_drop(best)
	best["doing"] = ""
	(best["fig"] as RoamFigure).stance = "stand"
	(best["fig"] as RoamFigure)._cur_clip = ""
	best["state"] = "seek"
	best["path"] = []
	best["repath"] = 0.0
	best["seek_t"] = 0.0
	best["dared"] = false
	best["talked"] = false
	best["wait_t"] = 0.0
	_dare = best
	if "--stars-check" in OS.get_cmdline_user_args():
		print("STAR ", best["id"], " comes to challenge you from ", int(best_d), " m")


func _seek(s: Dictionary, delta: float, dist: float) -> void:
	var fig: RoamFigure = s["fig"]
	var id := str(s["id"])
	var player: Node3D = scene._player
	s["seek_t"] = float(s["seek_t"]) + delta
	if bool(s["talked"]) and not scene._talking:
		_seek_over(s, false)               # you heard them out (a yes would have started the duel)
		return
	if str(scene._inside) != "" or float(s["seek_t"]) > 55.0:
		_seek_over(s, false)
		return
	if dist < 2.6:
		fig.set_speed(0.0)
		var to := player.global_position - fig.global_position
		fig.rotation.y = lerp_angle(fig.rotation.y, atan2(to.x, to.z), clampf(delta * 8.0, 0.0, 1.0))
		if not bool(s["dared"]):
			s["dared"] = true
			scene.extras._say_over(fig, _line(id, "dare"), 4.0, last_src, Voices.voice_for(id))
			fig.gesture("challenge", 0.25)
			if "--stars-check" in OS.get_cmdline_user_args():
				print("STAR ", id, " reached you after ", snappedf(float(s["seek_t"]), 0.1), " s: ", _line(id, "dare"))
			Sfx.play("quest", -10.0)
		s["wait_t"] = float(s["wait_t"]) + delta
		if float(s["wait_t"]) > 16.0:
			_seek_over(s, true)
		return
	if bool(s["dared"]):
		# They said their piece. Walk off and so do they.
		s["wait_t"] = float(s["wait_t"]) + delta
		if dist > 8.0 or float(s["wait_t"]) > 16.0:
			_seek_over(s, true)
			return
	s["repath"] = float(s["repath"]) - delta
	var path: Array = s["path"]
	if float(s["repath"]) <= 0.0 or path.is_empty():
		s["repath"] = 1.6
		_skip_for(s)
		path = _route(fig.position, player.global_position)
		if path.is_empty():
			if _clear_until(fig.position, player.global_position) >= dist - 1.0:
				path = [player.global_position]
			else:
				_seek_over(s, false)
				return
		s["path"] = path
	var next: Vector3 = path[0]
	var d := Vector3(next.x - fig.position.x, 0, next.z - fig.position.z)
	if d.length() < 0.25:
		path.pop_front()
		return
	fig.position += d.normalized() * minf(d.length(), SEEK * delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		fig.position.y = lerpf(fig.position.y, _floor_at(fig.position), 0.6)
	fig.rotation.y = lerp_angle(fig.rotation.y, atan2(d.x, d.z), clampf(delta * 8.0, 0.0, 1.0))
	fig.set_speed(SEEK)


## Back to their day.
func _seek_over(s: Dictionary, say: bool) -> void:
	var fig: RoamFigure = s["fig"]
	if say and scene.extras and fig.global_position.distance_to(scene._player.global_position) < 10.0:
		scene.extras._say_over(fig, _line(str(s["id"]), "leave"), 2.6, last_src, Voices.voice_for(str(s["id"])))
	_dare = {}
	if "--stars-check" in OS.get_cmdline_user_args():
		print("STAR ", s["id"], " gives up the challenge and goes back (said goodbye: ", say, ")")
	s["talked"] = false
	s["dared"] = false
	s["at"] = _stop_now(s["stops"])
	_set_off(s, _spot(s, int(s["at"])))


# ------------------------------------------------------------------ come and meet me

## Somebody who knows you a little asks you to come by later; if you do, they have something
## for you. One invitation at a time, at most one a day.
## Returns [] for nothing, or [was this the meeting itself, the line].
func _invite_talk(s: Dictionary, talks: int, was_nap: bool) -> Array:
	var id := str(s["id"])
	var now := WorldClock.minutes
	var inv: Dictionary = _mem.get("_invite", {})
	if not inv.is_empty() and str(inv.get("who", "")) == id and str(inv.get("district", "")) == _district:
		var from := float(inv.get("from", 0))
		var until := float(inv.get("until", 0))
		if int(inv.get("day", -1)) == _day and now >= from - 25.0 and now <= until:
			# You came.
			_mem.erase("_invite")
			var e: Dictionary = _mem.get(id, {})
			e["met"] = int(e.get("met", 0)) + 1
			_mem[id] = e
			_save_mem(_mem)
			var gift := _gift_from(id)
			Collection.dp += 120
			if gift != 0:
				Collection.add(gift)
				Router.toast(Loc.t("%s gave you %s.") % [_short(id), Loc.t(str(CardData.get_card(gift).get("name", "")))])
			Router.toast(Loc.t("+%d Duel Points") % 120)
			Collection.save()
			Sfx.play("quest", -4.0)
			_bond(id, 10, true)
			return [true, _line(id, "met")]
		if int(inv.get("day", -1)) < _day or now > until:
			_mem.erase("_invite")
			_save_mem(_mem)
			_bond(id, -3)
			return [false, _line(id, "missed")]
		return []
	if not inv.is_empty() and int(inv.get("day", -1)) >= _day:
		return []                    # somebody else is expecting you today
	# --stars-invite (testing): ask right away.
	var force := "--stars-invite" in OS.get_cmdline_user_args()
	var close := rank_of(int((_mem.get(id, {}) as Dictionary).get("bond", 0))) >= 2
	if not force and (talks < 2 or was_nap or int(_mem.get("_invite_day", -1)) == _day or randf() > (0.9 if close else 0.6)):
		return []
	# A later stop of theirs today, far enough off to be worth a wait.
	var stops: Array = s["stops"]
	for i in stops.size():
		var st: Array = stops[i]
		if float(st[0]) < now + 45.0 or float(st[0]) > 1320.0 or str(st[3]) in ["duel", "nap"]:
			continue
		var until2 := float(stops[i + 1][0]) if i + 1 < stops.size() else 1439.0
		var place := StarMeets.place_near(scene.district, st[1])
		if place == "":
			continue
		var hour := StarMeets.hour_text(float(st[0]))
		_mem["_invite"] = {"who": id, "district": _district, "day": _day, "from": float(st[0]), "until": until2, "place": place, "hour": hour, "pinged": false}
		_mem["_invite_day"] = _day
		_save_mem(_mem)
		Router.toast(Loc.t("New: meet %s at %s around %s") % [_short(id), Loc.t(place), hour])
		Sfx.play("quest", -6.0)
		var line := _line(id, "invite")
		if line.count("%s") == 2:
			line = StarMeets.invite_text(line, place, hour, true)
			Voices.note_src(line, StarMeets.invite_text(last_src, place, hour))
		return [false, line]
	return []


## A card out of their own deck, not the one they lead with.
func _gift_from(id: String) -> int:
	var key := str((_star(id).get("d", {}) as Dictionary).get("char", id))
	if not CardData.has_deck(key):
		key = id
	if not CardData.has_deck(key):
		return 0
	var ace := int(Characters.get_char(key).get("ace", 0))
	var pool: Array = []
	for c in CardData.deck_list(key):
		if int(c) != ace and not pool.has(int(c)):
			pool.append(int(c))
	return int(pool[randi() % pool.size()]) if not pool.is_empty() else 0


## The hour has come and you are in the right world: a nudge, and the way there.
func _invite_step() -> void:
	var inv: Dictionary = _mem.get("_invite", {})
	if inv.is_empty() or bool(inv.get("pinged", false)) or str(inv.get("district", "")) != _district or int(inv.get("day", -1)) != _day:
		return
	if WorldClock.minutes < float(inv.get("from", 0)) or WorldClock.minutes > float(inv.get("until", 0)):
		return
	var s := _star(str(inv.get("who", "")))
	if s.is_empty() or str(s["state"]) != "there":
		return
	inv["pinged"] = true
	_mem["_invite"] = inv
	_save_mem(_mem)
	Router.toast(Loc.t("%s is waiting for you at %s.") % [_short(str(s["id"])), Loc.t(str(inv.get("place", "")))])
	if scene.extras and not scene.extras.has_waypoint():
		scene.extras.set_waypoint((s["fig"] as RoamFigure).position, scene._npc_name(s["d"]))


## The line for the "On your list" box: who expects you, where and when ("" if nobody does).
func invite_row() -> String:
	var inv: Dictionary = _mem.get("_invite", {})
	if inv.is_empty() or int(inv.get("day", -1)) != WorldClock.day or WorldClock.minutes > float(inv.get("until", 0)):
		return ""
	var away := "" if str(inv.get("district", "")) == _district else "   (" + Loc.t(str(RoamData.district(str(inv.get("district", ""))).get("name", ""))) + ")"
	return Loc.t("Meet %s: %s, around %s") % [_short(str(inv.get("who", ""))), Loc.t(str(inv.get("place", ""))), str(inv.get("hour", ""))] + away


# ------------------------------------------------------------------ dev

## --stars-check: is every stop of everyone here a place to stand, and can they walk between them?
func _check() -> void:
	for s in _stars:
		_skip_for(s)
		var stops: Array = s["stops"]
		for i in stops.size():
			var want: Vector3 = stops[i][1]
			var got := _spot(s, i)
			var nxt := _spot(s, (i + 1) % stops.size())
			var way := _route(got, nxt)
			var length := 0.0
			var prev := got
			for wp in way:
				length += Vector3((wp as Vector3).x - prev.x, 0, (wp as Vector3).z - prev.z).length()
				prev = wp
			var whole := Vector3(nxt.x - got.x, 0, nxt.z - got.z).length()
			print("STAR ", s["id"], " stop ", i, " ", stops[i][3], " at ", got.snapped(Vector3.ONE * 0.1), "" if got.distance_to(want) < 0.8 else "  MOVED from %s" % str(want),
					"  to next: ", ("walks %.0f m in %d legs (straight %.0f)" % [length, way.size(), whole]) if not way.is_empty() else "NO WAY ON FOOT (%.0f m): appears" % whole)
