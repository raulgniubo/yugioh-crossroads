# Yu-Gi-Oh! Crossroads

A private fan project: a 3D Yu-Gi-Oh! story game with characters from Duel Monsters, GX, 5D's and ZEXAL.
Not affiliated with or endorsed by Konami. Not for distribution.

Built with **Godot 4.7** for macOS and Windows first, iOS and Android later.

## What is in 0.30

- **More hairstyles and outfits.** Four hairstyles per body now (new: Swept Back and Wild Mane, Twin Tails and Long Waves) and five outfits (new: the Satellite Jacket for a 5D's look on foot, and Heartland Casual for ZEXAL). Any hairstyle goes with any outfit: the head of one model rides on the body of another. All of them take every color in the creator.
- **The Curator, Vellum and Ren have their own models** instead of borrowed ones.
- **Cards rebuilt to their printed text**, each with its own test:
  - **Toons.** Toon World is in the game (pay 1000 LP). The big Toons (Mermaid, Summoned Skull, Dark Magician Girl) come from the hand only while you control it, Summoned Skull and Dark Magician Girl by Tributing a monster. Mermaid and Summoned Skull pay 500 LP to attack. The big ones attack directly unless the other side has a Toon, and then they must attack a Toon. The small ones (Gemini Elf, Masked Sorcerer, Goblin Attack Force, Cannon Soldier) attack directly only with your Toon World out and no Toon across the table. When Toon World is destroyed, they all go with it. Pegasus plays three copies.
  - **X, Y and Z.** Y-Dragon Head and Z-Metal Tank equip to their partners as Union monsters, give 400 and 600 ATK and DEF, are destroyed in place of the monster they ride on, and come back off as monsters. XYZ-Dragon Cannon is called from the Extra Deck by banishing all three, with no Polymerization, and its discard effect can hit any card and be used as often as you can pay.
  - **Destiny HERO - Malicious** is used from the Graveyard (your deck, then "Effect from the Graveyard"). **Disk Commander** draws 2 only when it comes back from the Graveyard, once per Duel, and not the turn it was sent there.
  - **Cyber Angels.** Benten searches a LIGHT Fairy when Tributed. Idaten fetches a Ritual Spell when Ritual Summoned and gives every Ritual Monster 1000 ATK and DEF when Tributed. Dakini makes the opponent give up a monster of their choice, gives your Ritual Monsters piercing, and brings a Ritual card back in your End Phase.
- **Fix:** enrolled at Duel Academy, your duelist keeps every color you picked; the dorm jacket is your top, repainted.

Still waiting: 54 effect monsters and 14 Spells and Traps are out of the game until they are rebuilt (the list is in CARD_REVIEW.md).

## What is in 0.29

A repair build first: several things looked wrong in 0.27 and 0.28, and they are fixed here.

- **Characters are whole again.** A speed trick from 0.26 swapped characters for lighter copies of themselves, and on a real machine those copies came out broken: missing heads at a few steps away, torn "lego" bodies up close. It is switched off. Every character is always drawn with its full model.
- **Looks first.** Ultra takes no shortcuts: nothing is hidden with distance, nothing switches to a lighter model, small things keep their shadows and round things stay round. High keeps things in view much further than before. Only Low and Medium trade looks for speed. "Hold 60 FPS" (which softened the picture in heavy scenes) is off by default and is switched off once on existing settings. It never limited the frame rate; that is the separate "Frame rate" setting.
- **Settings from inside a world.** Esc, then Settings. If you change how far things are drawn or how many people are about, the world is rebuilt right where you stand.
- **A much bigger character creator.** Four tabs: Body (type, Kid / Teen / Grown-up, five heights, ten skin tones, eye color), Hair (style and sixteen colors), Outfit (one per series, the three Duel Academy dorm colors in one press, and your own color for the top, the bottom and the shoes, plus your signature color), and You (name, title, lines, card sleeve). Colors repaint the figure on the spot and keep the folds and shading of the clothes.
- **Free Duel tiles** zoom in on the head and shoulders again, and portraits are drawn sharper on High and Ultra.
- **The menu lineup** fades from one duelist to the next instead of going dark in between.
- **Story panel:** difficulty, Save / Load and New Game sit in one row at the top, always in view.
- **Admin mode** turns into an off switch the moment you unlock it, and needs no PIN after the first time.
- **Story:** when somebody walks into a scene they start close, the last line leaves the screen and the camera turns to them. No more waiting on a frozen-looking screen.
- **Talking to a duelist:** Esc always walks away. The Duel / Not now answer waits half a second, so skipping lines cannot start a duel by accident, and "Not now" is the highlighted one.
- **Rock-paper-scissors:** the hands sit above the field, so the other duelist is not hidden behind them.

Not in this build yet: the rest of the card rebuild (69 monsters and 14 Spells and Traps are still waiting), the card shop makeover, more hairstyles and outfits, and the models for the Curator, Vellum and Ren.

## What is in 0.28

**Every card in the game now matches its printed text**
- New rule, enforced by the game itself: a card with an effect is only in the game once its rules have been checked against its printed text, sentence by sentence. The list is `scripts/core/card_exact.gd`, and `CARD_REVIEW.md` shows what is exact and what is waiting.
- A card that is waiting is not in packs, shops, prizes or the deck builder, and the ready-made decks use a stand-in for it until it is rebuilt. It comes back by itself.
- Rebuilt to their full text: Stardust Dragon, Red Dragon Archfiend, Black Rose Dragon, Blackwing Armor Master, Galaxy-Eyes Photon Dragon, Number 39: Utopia, Number 17: Leviathan Dragon, Dark Magician Girl, Destiny HERO - Dasher, Sangan, Magician of Faith, Goblin Attack Force, the D.D. Warriors, Twilight Rose Knight, the Sharks' Level effects, and about 40 more monsters and 27 Spells and Traps.
- Synchro and Xyz Monsters ask for the materials their first line names: Junk Warrior needs Junk Synchron, Armor Master needs a Blackwing Tuner, Black Ray Lancer needs WATER.
- Bugs found by reading the rules next to the text: Needle Worm sent 1 card instead of 5, Cyber Prima destroyed Set cards instead of face-up Spells, Elphin could only turn a monster to Defense, Sangan and Winged Kuriboh ran their effect twice.

**Rooms**
- The Yellow dorm's common room has the manor's panelling, hearth and chandelier; the Blue dorm's has the castle's columns, banners and gold.
- The Heartland Lounge is a neon night spot now, and the Scrap Trader is rust and tin with its own sign.

## What is in 0.27

**Your game in one folder, with real saves**
- The game now looks for a folder called `Crossroads Data` right beside it (cards, assets and saves all in one place). If it is not there, it uses the folder you pick in Settings, same as before.
- Three save slots plus an autosave, in the Story panel. A save holds the whole game: story, cards, Duel Points, decks, every world. Saving over a slot asks first.
- New Game, and Restart the whole game in Settings (asks twice). Save slots are kept.
- Story difficulty (Easy, Normal, Hard), changeable at any time.
- Admin mode in Settings, behind a PIN: everything open for testing, and your own game is put aside untouched until you turn it off.

**Cards: only cards that work**
- New test tool, the card drill (`tools/card_drill.gd`): every card in the game plays a full test duel, every effect monster is put through 36 situations next to a blank twin, and every Spell and Trap is played on a set of standard fields.
- The drill found 25 monsters that had a note instead of an effect. 15 now have their real effect. 10 are out of the game until they can be built properly.
- Special Summon from the hand now works for you with every monster that has that rule (it only showed for Cyber Dragon).
- Tokens are no longer cards you can pull or own. Burning Land can be played with no Field Spell out. Xyz monsters that ask for three materials need three.
- Packs, shops, prizes, the lost card and the scrap pile only hand out cards that are in the game. A card from an older build that had no working effect is swapped once for one that works.
- `CARD_REVIEW.md` lists the cards whose rules are probably simpler than their printed text.

**Progress that connects everything**
- Worlds open with the story. Each world's shops sell that world's era. Themed packs open with wins.
- Free Duel opponents open when you beat them. Duelists show 1 to 5 stars.
- First win over a duelist: their ace. Second win: another card from their deck. Third win: their deck.
- Opponents now play toward their ace.

**Duels**
- 22 signature monsters have their own arrival and their own named attack, built around the card's picture. Every other Level 7 or higher monster gets an arrival by Attribute.

**New things to do**
- Duel Puzzles in the Game Center: nine positions, win this turn. Each one is checked by a solver.
- Card Match, a second new cabinet.
- Three bond scenes (Joey, Jaden, Yusei) in the Story panel, opened by story progress and two wins.

## What is in 0.26

Speed, sound, and things to do indoors.

- **Lighter worlds.** Character models now get lighter versions for distance (worked out in the background when a model loads), small props are not drawn from far away, tiny things cast no shadow, lamps fade out with distance, and round shapes use only as many sides as they need (`scripts/roam/perf_pass.gd`, `Avatars.request_lods`). Measured on the test renderer: 20 to 65% fewer triangles per frame depending on the world.
- **Hold 60 FPS** (Settings, Display, on by default): when a scene gets heavy the 3D picture is drawn a little softer instead of slower, and sharpened again when there is room.
- **F3** shows where the time goes: FPS, CPU and GPU milliseconds, draw calls, triangles, the 3D resolution in use.
- **High** now uses two shadow splits instead of four (Ultra keeps four).
- **Sound.** Every world has its own background: Satellite wind and metal, Heartland crowd and monorail, New Domino's hum and the ring road, the museum's quiet, crickets at night in Domino, and a boomier engine inside the Turbo tunnels. The loudest hit sounds were clipping and sat about 10 dB over everything else: they are rounded off and trimmed (`--sound-audit` prints every level).
- **Things to do indoors.** Burger World sells a set meal (+500 Life Points in your next duel), the Game Center has a playable cabinet (Higher or Lower, with your own card pictures), the Yellow dorm has a study group quiz, the Blue dorm a trophy case, and two buildings that were only fronts now open: the Heartland Lounge and the Scrap Trader in Satellite (150 DP for a random card).
- **Runner tuning** at the Satellite garage: two levels, each starts you with one more Speed Counter in Turbo Duels.

## What is in 0.25

Story mode, start to finish.

- **A complete story.** Prologue, four chapters and a final chapter with an ending and credits. Chapter 4 (Heartland) and the finale (the Curator's museum, a new place built for the story) are new. The older chapters were reworked so the plot runs through all of them: who Lumen is, why Kairo works for the Curator, and what the Curator is building.
- **Cinematics.** Directed camera moves with captions for chapter openings, entrances, reveals and endings (`{"shot": {...}, "cap": "..."}` in `story_data.gd`).
- **Echoes.** Memory scenes: the picture turns to a tinted, framed panel and a short flashback plays inside the game world (`{"echo": "Title"}` ... `{"echo": false}`).
- **A camera that checks its own shots.** Every dialogue shot is picked from many candidate positions and scored: is the speaker in frame and above the dialogue box, is a wall, a prop or a bystander in front of them, is the lens inside something, do we see a face. `--story-audit` prints a line per shot for testing.
- **Clear goals.** Every goal has a one-line "how", Lumen flies ahead toward it, and she repeats the hint if you stand around.
- **Lumen, your partner.** She is a real spirit now (built in code, no model file): she floats beside you in every world, comments on what she sees, leads you to one lost card per world per day, answers when you press L (what to do next, today's challenges, small talk), reacts during duels, and has her own card in the Echo Deck that grows with every bond.
- **Choices that are remembered.** How you treat Kairo in chapter 2 decides whether you have to duel him in the finale.
- **Boss duels with special rules** (more Life Points for Vellum and the Curator, their own music).
- **Night duelists.** One rare, strong duelist per world who only shows up at night.
- **Card prizes.** The first win against any duelist gives you a card from their deck (their ace when they have one).
- Effect monsters in the ready-made decks: the audit tool (`tools/fx_audit.gd`) now reports no effect monster playing as plain ATK/DEF.

## What is in 0.24

- Buildings: the last pre-made apartment blocks, the cafe and the corner store in Domino are
  gone. In their place stand buildings made in the game's own kit (`scripts/roam/street_kit.gd`):
  flats with balconies and washing on the line, Burger World with a striped awning and tables
  outside, Domino Mart with its shelves showing through the glass. The kit also builds the
  patched-up parts store in Satellite and the glass lounge in Heartland and New Domino.
- Flicker: the pre-made models that are left (card shop, school, dome, clock tower, the main
  Academy) were being drawn from both sides, and where two thin faces lay on each other they
  fought over every pixel. They are drawn from the outside only now. The same goes for your
  own models in `<card folder>/places`.
- Dorms: three houses on one plan, each a step up. Red is the plank house. Yellow is a tiled
  manor with a front gable, dormers and flower boxes. Blue is a white castle: battlements,
  four round towers with pointed roofs, a keep with a round window. All three have stairs you
  can climb outside and bedrooms off the gallery; the Yellow rooms have a proper bed and an
  armchair, the Blue suites a four-poster, a fireplace and a chandelier.
- Your own main Academy building: put `academy_main.glb` in `<card folder>/places`. The island
  fits itself to it: the ground you walk on is read off the model, the way in is put where a
  walk up the middle meets the building, statues and people move out in front, and both maps
  show it at its real size. `dorm_red.glb`, `dorm_yellow.glb` and `dorm_blue.glb` work the
  same way.
- Satellite is a place now: cracked concrete and a patched road, heaps of scrap on mounds of
  earth, a runner garage you can walk into (a runner on the lift, a welder at work), homes
  made of shipping containers, power lines, a fire in a barrel, a painted wall, a fence of tin
  and wire, the unfinished highway hanging over the north edge, a crane and smokestacks.
- Heartland too: glass towers in pale colors, a monorail doing laps overhead, a big wheel
  turning beyond the roofs, balloons, floating screens, arches of light at the ways in,
  flower beds, strings of lamps, an ice cream cart, sweeper robots on their rounds.
- New Domino: team banners down the boulevard, painted crossings, screens on posts.
- Turbo: a new road (asphalt with worn lanes, joints, studs, wet reflections), a concrete
  barrier, a glass wall with the city going by behind it, proper lamp posts, a tiled tunnel
  with strip lights, fans and emergency doors, and a freight truck that looks like one. The
  road and walls now bend with the scenery on a curve, and the grain is fixed to the road so
  it no longer swims when the speed changes.
- Portraits: everyone is framed the same way, at the same scale, with room for any hair. No
  more hair cut off on the home screen or in the duel corner, and a small duelist looks small.
- Duels: pointing at a face-down card shows its owner's card back. An arm that carries a duel
  disk keeps the disk's own colors when the character wears a dorm jacket.
- People on benches sit up instead of slumping over their knees.
- Tournaments has a card per event: trophy, where it is, badges earned, prize.

## What is in 0.23

- Duel arenas are real places now. Sixteen of them, each with its own ground under the cards
  and its own scenery and crowd: a steel floor in the Kaiba Corp Dome, a varnished court ringed
  in dorm colors at Duel Academy, a wet rooftop over Battle City, a pier at sunset, a marble
  hall for the Blue Dorm, a lawn on the cliff by the Red Dorm, a closed highway overpass at
  night, a junkyard, Heartland's glowing tiles, and the six open-air fields. Every duelist has
  a home field (Jaden the Red Dorm cliff, Yusei the highway, Kaiba the dome). The Free Duel
  picker shows a picture of each one (made by `tools/arena_shots.tscn`).
- The Red Dorm on Academy Island is our own plank house: stairs outside that you can climb,
  a walkway along the upper floor, and four bedrooms you enter from it.
- Domino: buildings have real ledges, pilasters, balconies, awnings, air conditioners, pipes
  and fire escapes. A new Game Center replaces the old arcade model. Poster columns and a
  giant screen show real cards; shop fronts spill light onto the pavement at night.
- Academy: dorm banners on the lamp posts, bunting and pennants round the plaza, the crest in
  the paving, smoke off the volcano, and duels on the lawn you can stop and watch.
- Booster packs and deck boxes show a real card from inside them (the pack's strongest
  monster, the deck's ace) in place of the old made-up pictures.
- Home screen: the four duelists are one from each series, each slot swapping only inside its
  series. Tall hair and hats fit in the portraits.
- Settings are split into tabs (Display, Graphics, Audio, Gameplay, Card art). Card sleeves
  moved to "My duelist", opened from the profile bar, next to the character editor.
- Story scenes: two people talking are filmed together and the camera holds while they go
  back and forth. It cuts only when somebody new speaks or for a marked close-up.
- Fixed: getting stuck by the dorm stairs (their sides are closed in, the top no longer has
  a lip, and anyone boxed in on all sides is put back a few steps), seated people sinking
  into benches (the hall has real benches and everyone sits on the seat), patterns that
  shimmered at a distance (fine detail now fades out before it is smaller than a pixel),
  the milky haze on overcast days, the Back button over the Free Duel title.

## What is in 0.22

- The look, again: the comic style is gone. Menus and the duel screen are now dark glass over
  the real city, thin light edges, soft shadows, one amber accent, and a sharp narrow italic
  face (Barlow Condensed, SIL Open Font License, see `assets/fonts`). Same layout as 0.21.
- Home screen: a lineup of four duelists at a normal size that changes one face at a time,
  instead of one very large character.
- Free Duel: arenas are picked from pictures, and picking a duelist is instant.
- Duels: the opponent's Spells and Traps are held up with their name and text before they
  resolve, and the opponent plays at normal speed. Both Graveyards open with a click. Set cards
  of the opponent stay hidden when you point at them. Cards with more than one effect (Enemy
  Controller) ask which one, and effects that pick "the weakest" or "the strongest" ask you
  when there is a tie. Ego Boost can only be used when it should. More rules tests.
- Graphics settings: Low, Medium, High and Ultra presets, plus a switch for each effect (3D
  resolution, edge smoothing, shadows, soft corner shading, reflections, glow, haze, bounce
  light, ground detail, people in the world). Change one and the preset reads Custom.
- Worlds: a sky with clouds and stars, less haze, softer shadows, a grain on painted surfaces,
  real surface patterns (paving, planks, roof tiles, rock, sand, brick), grass tufts, flowers
  and pebbles on lawns, trees that sway, sea with waves and foam, boulder cliffs.
- Duel Academy: dorm front yards, and inside each dorm a staircase you can walk up to a
  gallery of bedrooms you can walk into. The grand staircase in the Blue Dorm can be climbed.
- Fixed: white patches and wrong colors on dorm jackets (the jacket is now painted from the
  rest pose, so it stays put when someone walks or sits), people sitting on thin air, two
  trees in one spot, ground slabs that flickered where they overlapped, the card shop beacon
  at the Academy pointing out to sea (it now leads to the right door), the place name
  overlapping the top buttons.
- Speed: menus open at once (buttons act on press, shorter fades), live portraits draw on
  every other frame, and the 3D picture is no longer drawn at full Retina / 4K size unless
  you pick Native.

## What is in 0.21

- A new look for the whole game: bright comic pages in place of the dark neon, deep navy cards
  on top of them, cream chips and dropdowns, orange for what is picked. Slanted slabs,
  ink outlines, halftone dots, a chunky title face (Lilita One) and a loud one for VS, banners
  and damage numbers (Bangers). Both fonts are under the SIL Open Font License, see
  `assets/fonts`.
- Duel screen: a big slanted panel per duelist in the corner (blue for you, red for them) with
  the live 3D character and the Life Points on a ribbon; comic speech boxes with a name tag; one
  pill for turn number and phase; round icon buttons (Graveyards, card log, duel menu); a card
  log of everything played; the card panel wears a header in the card's frame color.
- Big moments (ace summons, the finishing blow) cut to an eye close-up band with the field
  blurred behind it.
- The field: a steeper camera, zones painted on the ground as thin outlines with a small icon
  (no glowing plates), a Level or Rank star on every monster next to ATK / DEF, and six open-air
  fields (Meadow, Volcano, Frozen Summit, Ruins, Tide, Shadow Realm) you can pick in Free Duel.
  Out in the world the field follows where you are standing.
- Duel controls: drag a card from your hand onto the field, drag a monster onto a target to
  attack, tap anywhere to close a menu, tap your deck for Graveyards, the duel menu and
  Surrender. Every button answers on the press.
- Rules feel: nothing is chosen for you any more (targets, Xyz Materials, optional effects all
  ask), an effect shows on the field before its prompt, banners stay clear of the animation,
  Ego Boost only during an attack, Goblindbergh's effect no longer fires twice.
- The opening happens on the field: both duelists are introduced by the camera, VS lands over
  the live table and rock-paper-scissors is played right there. New challenge and defeat poses;
  the loser slumps and the winner celebrates.
- Card sleeves: a library in Settings, the opponent's ace on their sleeve, and `back.jpg` in
  your card folder becomes the default back.
- Home screen, Free Duel, Settings and the duelist creator are rebuilt. The creator has height,
  twelve colors, titles to unlock, an opening line, a victory line and a sleeve.
- More sound in duels (crowd, draws, summons, hits), louder music during a duel.
- Settings: frame rate. Unlimited by default, or 30 / 60 / 120 / 144 / 240, or match the screen.

## What is in 0.20

- Turbo: ten Speed Spell cards (Full Throttle, Tailwind, Pit Stop, Slipstream Strike, Twin Turbo,
  Afterburner, Road Clear, Overtake, Redline, Shockwave). Each needs a number of Speed Counters,
  the big ones spend them. Both riders get a set shuffled in for every Turbo Duel.
- Turbo: the road and barriers are drawn by shaders that stay sharp at speed (stretched lane
  dashes, expansion joints, cat's eyes, scrolling chevrons), a blur at the screen edges that
  grows with speed, holo gantry signs, boost chains and overtake bonuses on the ride.
- Tournaments: the Highway Grand Prix (press G at the start line; race a lap, then a Turbo
  Duel, three rounds; a better finish means more Speed Counters at the start) and the
  Crossroads Cup at the Domino harbor for anyone holding the three other titles, with a Turbo
  Duel in the semifinal.
- Story: Chapter 3, "The Last Lap". New Domino and Satellite, three duels (two of them Turbo
  Duels), one bond.
- New Domino City: people talking, walking their rounds and waiting at the stadium, two street
  duels to watch or join, Security drones, runners circling the ring road, benches to sit on,
  four favors, weather, and two places to walk into: the Stadium Concourse and the cafe.
- Satellite and Heartland: a first pass of the same (people, a street duel, weather).
- Kame Game: pendant lamps, a game in progress on both duel tables, a card of the day by the
  door. Academy main hall: dorm banners, chandeliers, a trophy case and the Dorm Cup board.
- Duels: duelists step into their attacks, stagger when they take damage and rise on a summon.

## What is in 0.19

- Tournaments: register at a tournament desk, earn Finals Badges by beating duelists around
  that world (each win also takes a card from their deck), then play an eight-duelist knockout
  on a bracket screen. Domino Street Championship (six badges, finals at the KaibaCorp plaza
  at night with a crowd) and the Academy Dorm Cup (four badges, your three rivals are in the
  draw). Champions get Duel Points, three rare cards and a trophy that appears in your room.
- Story: Chapter 2, "Slifer Red, Last of Its Kind". Free Joey at the pier, then follow the next
  crack to Duel Academy. Three duels, two bonds.
- Free Duel: Survival mode (opponents keep coming, Life Points carry over, best streak saved)
  and a starting hand of 4 to 7 cards.
- Duels: response prompts explain why the duel stopped and what your choice does; the loser
  drops their head before the winner celebrates.
- Turbo Duels: Slipstream. The rider 2000 or more Life Points behind gains an extra Speed
  Counter each Standby Phase.
- Worlds: the three Academy rivals have new things to say each time you beat them; the lost
  card favor in Domino and the deck box favor at the Academy are now three-part and two-part
  stories; rain is visible; the old dorm ghost looks like one.
- Fixes found by testing: speakers no longer stare at the floor in story close-ups; a hill no
  longer covers the Academy lookout.
- Dev: `--spot=`, `--result-action=`, `--tourney=`, `--parse-all`.

## What is in 0.18

- Academy uniforms: the white blocks on jackets are gone; trim is thin piping now.
- Duels: attacks land by monster type (blade slash, claws, jaws, beam, spell blast, crushing
  blow); well-known Spells and Traps have their own look on the field (lightning, a black hole,
  a barrier, falling swords, a revival pillar, cylinders, a storm); a heavy hit cuts to the
  duelist who took it; opponents play to their personality (reckless, careful or by the book)
  and each personality has its own duel theme; ace summons get a stinger.
- Free Duel: starting Life Points (4000 / 8000 / 16000), who goes first, the opponent's deck,
  your win-loss record against each duelist, their deck unlocked after three wins, and a
  Gauntlet of three duelists in a row on one pool of Life Points.
- Turbo Duels: a lower, wider camera that keeps the road and the far rider in view, engine sound
  that climbs with speed, and each rider's runner in their color.
- Domino City: a harbor market (rare singles, takoyaki, fortunes, duel puzzles) with lanterns
  at night; named shops with awnings on the plain buildings; rain on some visits; fewer people
  out at night and Burger World closes; you can challenge the winner of a street duel.
- Duel Academy: a lecture hall where you take today's class duel or exam in person; three named
  rivals, one per dorm; a ghost at the old dorm who only appears at night; hills, a lantern path
  to the old woods and a livelier beach with a drinks hut.

## What is in 0.17

- Duel feel: face-up monsters now stand over their cards as holograms for as long as they are
  on the field (they float, lean into attacks, flash when hit, dim in Defense and break into
  pixels when they leave). Hits freeze the table for a blink. Life Points count down as the
  damage number lands. The opening hands are dealt faster and summons are a touch quicker.
  The hand makes room for the card you point at, playable cards sit higher, and a click has a
  press-in. A small play-by-play next to the menu button lists what the opponent just did.
- Story: the prologue and chapter 1 were restaged line by line with gestures, reactions from
  the people listening, close-ups and low hero shots, silent beats, and a camera that slowly
  pushes in during every line.
- Worlds: Burger World, the Game Center, the KaibaCorp lobby and the dorms got windows with
  daylight, wall art, plants, lamps, rugs and their own touches (a jukebox, neon tubes, a prize
  wall, a holo globe). People with routines walk between stops in Domino and on the island.
- Turbo: speed lines at the edge of the screen in Turbo Duels and on the highway, lamp light
  sweeping over the duel field, slipstream boosts for tucking in behind a rider, near-miss
  bonuses for shaving past a hauler, and an exhaust flame while boosting.

## What is in 0.16

- Duels: anime cut-ins (a slanted band with the duelist's live portrait, speed lines and big
  words) for ace summons, heavy and direct attacks, Trap activations and the finishing blow;
  speed lines burst out where a hit lands; damage numbers pop in the middle and fly into the
  Life Point plate. The arena crowd is now real little people who bounce, raise their arms, wave
  glow sticks and pop camera flashes.
- Deck Builder: new three-column layout. Card detail on the left, your deck in the middle as
  actual cards (Main, Extra, Side) with a monsters / Spells / Traps bar, and your collection on
  the right. Cards pop when added and lift when you point at them. My Decks shows each deck's
  best monster. Both screens share a new animated backdrop.
- Domino City and Duel Academy: street duels you can watch (two duelists, holograms, Life
  Points, a cheering crowd) in the KaibaCorp plaza, at the harbor and on the practice fields;
  three new places to enter: your own room (rest to pass time, build decks at the desk, a
  trophy shelf), Domino Mart (a free lucky draw every day) and the Academy Library (a duel quiz
  that pays Duel Points, strategy books, a new building on the island). Shops and halls have
  more people in them. Building walls got real windows with frames, sills, blinds and doors,
  lawns got a proper grass look, and there are more people walking.
- Turbo Duels: runners surge forward when their monster attacks and shake and throw sparks
  when their rider takes damage.
- Story: characters are framed above the dialogue box, the box has the speaker's color, a name
  tab and a tall portrait that slides in, and chapter title cards are big and animated.
- Two more daily challenges (watch a street duel, answer a quiz).

## What is in 0.15

- Open world pass for Domino City and Duel Academy: street detail everywhere (bins, planters,
  hydrants, cones, signs, cafe tables, bunting, bikes, signposts), drifting clouds, lamp halos,
  birds that scatter, gulls, butterflies, cats you can pet, people chatting in pairs and sitting
  on benches. You can sit on free benches, buy a drink from vending machines, do small favors
  for people (two per world), and three daily challenges show up in Quests.
- Moving around: smooth start and stop, a lean into turns, a jump (Space, or A on a pad when
  nothing is nearby), footsteps that change with the ground, door sounds and a short step in when
  you enter a building, and a travel card (ferry or speed lines) between worlds.
- More sound: grass, sand, wood and hall footsteps, fountain water, birds, crickets at night,
  distant horns, cats, cans, pickups.
- Turbo Duels and the highway look much better: a real night sky with a moon, stars and lit
  cloud bands, a far wall of city, searchlights, light arches over the road, a wet road that
  smears the lamps, moving holo signs and mast lights on the towers, and long light trails.
- Duels: a coach line at the top says what you can do right now; the opponent's turn runs
  quicker; the opponent's Trap now flips up facing you; every monster shows its effect text;
  "Pause in every phase" has a small "?" that explains it; in a Turbo Duel the speech bubble no
  longer covers the speed gauges.
- Free Duel: smaller Back, a plain "My duelist / My opponent" switch, three difficulties (Easy,
  Normal, Hard; the old Easy is gone), clear TYPE (Standard / Turbo Duel) and LENGTH (1 duel /
  Best of 3) choices, and no second Back button.
- Home screen: the Duel Points box and the profile chip line up.
- Dev: `/tmp/rec.sh` style clip recording with `--write-movie`, plus `--tod=`, `--sit`, `--hop`.

## What is in 0.14

- Natural standing: every character gets a calm idle built from their own skeleton (arms by the
  sides, legs under the hips, breathing, weight shift). Everyday gestures move only the upper
  body, odd-looking ones were dropped, and hellos are a wave or a nod.
- Duels: the Extra Deck is a pile on the field (left of your Spell & Trap row, click it); a new
  VS card; both duelists talk more (traps, spells, big hits, reactions) and act it out at the
  table. "Pause in every phase" is explained on screen. The card panel is centered and only adds
  a note when the game plays a card differently.
- Free Duel: a Back button top left and a clear ME / OPPONENT switch over the roster.
- Main menu: the Duel Points purse no longer covers the profile chip.
- Duel Academy: a bigger island with a beach, the old woods and a ruined dorm, practice fields,
  stands around the duel field and a lookout. You can walk into the main hall (card shop, indoor
  arena, exam office) and all three dorms (`scripts/roam/academy_rooms.gd`).

## What is in 0.13

- Everybody is alive (`scripts/roam/roam_figure.gd`, `scripts/roam/head_look.gd`). A shared library
  of 16 everyday motions (`assets/models/anim/gestures.glb`) is fitted to every character, yours
  included: a natural standing idle, looking around, scratching, a phone call, talking with their
  hands. People turn their head to watch you, wave or nod when you walk up, sit at the duel table,
  and shop customers wander from shelf to shelf. The loser of a duel sulks while the winner cheers.
- Whoever is talking has their portrait in the dialogue box, in the street and in shops.
- My Decks (`scripts/menu/deck_menu.gd`): B in the city, the pause menu or the main menu. Five
  slots for decks you build plus your shelf of ready-made decks. Pick the one to duel with, edit,
  rename, empty, or copy a ready-made deck into a slot to make your own version.
- The shop sells ready-made decks (`scripts/menu/deck_shop.gd`): every duelist's deck and ten
  theme decks (water, fire, wind, dragon, warrior, spellcaster, fiend, machine, beast, insect).
  Buying one adds all its cards to your collection. The Echo Deck and whatever you were already
  dueling with stay free.
- 18 booster packs on three shelves: six series sets, six monster-type sets, and elements, Spells
  and Traps. Between them every card in the game can be pulled.
- Duel Points: wins pay bonuses (first win of the day, first win against a duelist, streaks, no
  damage, close call, quick win) with a breakdown on the result screen, and a purse is always on
  screen in the city and the main menu.
- Small things: a plate behind the location text, a named Star Chips counter that explains itself,
  real exit doors, speech-bubble markers, painted rock-paper-scissors hands.
- Yugi's grandpa runs Kame Game (slot `grandpa.glb`).

## Your own buildings and props

Put a GLB in `<card folder>/places/`, named after the thing it replaces: `card_shop.glb`,
`corp_tower.glb`, `duel_dome.glb`, `school.glb`, `clock_tower.glb`, `academy_main.glb`,
`dorm_red.glb`, `dorm_yellow.glb`, `dorm_blue.glb`, `lighthouse.glb`, `shop_counter.glb`,
`shop_shelf.glb`, `card_rack.glb`, `duel_table.glb`, `dragon_statue.glb`, `duel_stage.glb`,
`arcade_cabinet.glb`, `runner_a.glb`, `runner_b.glb`. The model is fitted to the same spot and
size as the game's own; its front should face +Z.

## What is in 0.12

- Who goes first is played, not announced (`scripts/duel/opening_game.gd`): call a coin toss and
  watch it flip, or throw rock-paper-scissors against the other duelist. The game remembers which
  one you like and you can switch on the spot.
- Booster packs have illustrated foil wrappers (`scripts/ui/pack_wrapper.gd`, art in
  `assets/ui/packs/`). The pack shop is a lit shelf with what is in each pack and what you own; the
  opening scene tears the seal off the real wrapper.
- Kame Game is a place to hang out: pack wall, a display case of the best cards, pennants, notice
  board, a cat. Eight people with rotating conversations and chatter of their own, a trader who
  sells one single a day, and a first pack on the house.
- Story: doors are shut during a scene and say so, the camera turns toward each new goal, and the
  goal is a gold diamond on the map.
- Dropped-in character models (see below) get the game's idle and victory, retargeted to fit.

## Your own character models

Put a rigged GLB (or VRM) in `<card folder>/characters/`, named after the character: `yugi.glb`,
`kaiba.glb`, `player.glb`... (the card folder is `Documents/Crossroads/assets` unless changed in
Settings). It replaces the stand-in on the next launch.

- Animations inside the file are used when their names contain `idle`, `walk`, `run` or `victory`.
- One file per motion works too: `yugi_walk.glb`, `yugi_run.glb`, `yugi_idle.glb`, `yugi_victory.glb`.
- Whatever is still missing is borrowed from the game's own clips when the skeleton has the same
  bone names (Meshy's auto-rig does). `godot --headless --path . -- --clips=yugi` prints what a
  character ends up with.

## What is in 0.11

- Story plays inside the walking world (`scripts/story/story_director.gd`, script in
  `scripts/story/story_data.gd`): title cards, actors who walk to their marks, over-the-shoulder
  dialogue cameras, emotes, choices, a NEXT GOAL panel with a beacon, a versus card before story
  duels, the bond card reveal, save and resume. The Prologue and Chapter 1 are rewritten for it.
- New Domino City (`scripts/roam/new_domino_builder.gd`): boulevard, stadium, Sector Security, the
  Tops and its garden, a Duel Runner showcase, cafe terrace, night market, holo billboards. Jack and
  Akiza live there now. It is the fifth world.
- The highway is a 2.6 km ring (`scripts/turbo/turbo_ride.gd`) through six zones with two exits
  (Satellite and New Domino), jump ramps and a one-lap race against the other riders.
- Bigger Domino City (`scripts/roam/domino_plus.gd`): KaibaCorp Plaza in front of the tower, the
  harbor and Domino Pier, the Duel Dome and Domino High forecourts. Three more buildings to enter
  (`scripts/roam/interiors.gd`): KaibaCorp Lobby with the Duel Simulator, Burger World, the Game
  Center with a prize claw. Kaiba, Pegasus, Marik, Weevil and Rex are out in the city.
- Expert AI: plays its whole turn out before choosing the first move, looks for Extra Deck lines,
  and leads attacks into face-downs with the monster it can best afford to lose.

## What is in 0.10

- Duel Academy mode (`scripts/core/academy.gd`, `scripts/menu/academy_hub.gd`): entrance exam, the three
  dorms (Slifer Red, Ra Yellow, Obelisk Blue), weeks of three class duels and a Friday exam, an
  8-duelist tournament bracket. Students wear dorm jackets (`Avatars.apply_uniform`), and so do you.
- Turbo Duels: Speed World 2 rules in `DuelState` (Speed Counters, Spells need speed, the 4 / 7 / 10
  effects), the highway board (`scripts/duel/turbo_track.gd`) and a ride mode, New Domino Highway
  (`scripts/turbo/turbo_ride.gd`).
- Expert AI (level 3 in `scripts/duel/duel_ai.gd`): two plays ahead, tries attack orders, plays the
  opponent's reply turn before it commits.
- Deck builder: five recipe slots, Side Deck, filters and sorting, optional Forbidden/Limited list.
  Free Duel can be a best-of-3 Match with side decking (`scripts/duel/side_swap.gd`).
- Presentation: card rarities with foil shaders (`scripts/ui/foil.gd`), a pack-opening scene
  (`scripts/menu/pack_opening.gd`), attack effects by Attribute, big Fusion / Synchro / Xyz / Ritual scenes.
- Cities: City Guide with search and directions, world travel, Satellite and Heartland, Star Chips,
  quests, street chatter. Sound and music everywhere. Controller support (`scripts/core/pad.gd`).
- English and Spanish (`scripts/core/loc.gd`, `scripts/core/es_strings.gd`). Card names and card text
  stay in English because the card database has no Spanish.
- A fifth pack, the Duelist's Vault: every scripted card the story duelists do not play.

## What is in 0.9

- Duel rules: chains (both players answer back and forth, last in resolves first), Continuous, Field,
  Equip, Quick-Play and Ritual Spells, Counter Traps, Continuous Traps, choosing your own targets,
  taking control, bouncing to hand, banishing, Exodia. About 170 Spell and Trap cards are data-driven
  in `scripts/duel/spell_rules.gd`.
- Deck builder and booster packs: win Duel Points, buy packs from four eras at the card shop, build a
  30 to 60 card deck (`scripts/core/collection.gd`, `scripts/menu/deck_builder.gd`, `pack_shop.gd`).
- Duel Academy island: a second free-roam district reached by ferry from Domino City.
- Free Duel: new setup screen (both duelists, deck preview, difficulty, arena), every duelist has a
  unique model, duelists stand in the arena with opening and victory shots, result screen with stats.
- 0.9.1 rules pass: you make every choice yourself (targets, discards, costs, Tributes, Fusion and
  Ritual materials, Deck searches, which monster to revive, Attack or Defense on a Special Summon,
  optional effects). Monster effects are chain links. Both players can act in the Draw, Standby and
  End Phases, at the start of the Battle Phase and of Main Phase 2. Damage Step limits, replays,
  Tokens, Skill Drain, effect negation, draws, coin toss, 40 to 60 card decks, revive limits for
  Ritual and Extra Deck monsters. The choice system is `DuelState.choose` + `DuelScene._run`.
- Out of scope: Pendulum and Link monsters (no cards from those eras are in the game).

## Playing a build

Builds come from GitHub Actions (Actions tab > latest **Build** run > Artifacts).

- **Mac:** builds automatically on every push to `main`. Download `Crossroads-macOS`, unzip, then run this once
  so macOS lets it open:
  ```
  xattr -cr "Yu-Gi-Oh! Crossroads.app"
  ```
- **Windows:** only built on request. Actions > Build > Run workflow > choose `windows` or `both`.

## Running from the editor

1. Install [Godot 4.7](https://godotengine.org/download) (standard version, not .NET).
2. Open Godot, click Import, pick this folder's `project.godot`.
3. Press F5.

## Real card images (optional)

The game runs with generated placeholder cards. To use real card images, run the downloader and point it at the
game's card folder (default `~/Documents/Crossroads/assets`, changeable in Settings):

```
python3 tools/fetch_cards.py --set "Legend of Blue Eyes White Dragon" --set "Metal Raiders" --out ~/Documents/Crossroads/assets
```

Character pictures (Yugi, Kaiba, Joey, Jaden, Yusei, Yuma) work the same way:

```
python3 tools/fetch_characters.py --out ~/Documents/Crossroads/assets
```

They land in `characters/<key>.png`. Drop your own `player.png` there to use your own picture.
Card and character images are never committed to this repo.

## Project layout

```
scenes/            main_menu.tscn, duel.tscn
scripts/core/      settings, card data, card textures, scene router
scripts/menu/      main menu and its 3D background
scripts/duel/      rules (duel_state), AI, 3D board, HUD, duel controller
scripts/ui/        theme, menu items, side panels, settings panel
tests/             headless rules tests (AI vs AI duels)
tools/             fetch_cards.py
```

## Dev commands

```
godot --headless --path . res://tests/test_runner.tscn        # rules tests
godot --path . -- --duel --autoplay --deck=yusei --opp=yuma    # watch AI vs AI
godot --headless --path . -- --story=ch1 --story-auto          # play a chapter by itself (duels skipped)
godot --headless --path . -- --roam --district=domino "--walk-to=@0,80;0,91" --walk-quit   # collision check
godot --path . -- --roam --district=newdomino "--tour=a:0,6,30,0,2,0;b:20,5,20,0,1,0"      # camera shots to /tmp
```
