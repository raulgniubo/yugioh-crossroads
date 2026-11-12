# Yu-Gi-Oh! Crossroads

A private fan project: a 3D Yu-Gi-Oh! story game with characters from Duel Monsters, GX, 5D's and ZEXAL.
Not affiliated with or endorsed by Konami. Not for distribution.

Built with **Godot 4.7** for macOS and Windows first, iOS and Android later.

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
