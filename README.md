# Yu-Gi-Oh! Crossroads

A private fan project: a 3D Yu-Gi-Oh! story game with characters from Duel Monsters, GX, 5D's and ZEXAL.
Not affiliated with or endorsed by Konami. Not for distribution.

Built with **Godot 4.7** for macOS and Windows first, iOS and Android later.

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
