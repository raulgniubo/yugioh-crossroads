# Yu-Gi-Oh! Crossroads

A private fan project: a 3D Yu-Gi-Oh! story game with characters from Duel Monsters, GX, 5D's and ZEXAL.
Not affiliated with or endorsed by Konami. Not for distribution.

Built with **Godot 4.7** for macOS and Windows first, iOS and Android later.

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
- Out of scope: Pendulum and Link monsters (no cards from those eras are in the game), Match play
  with a Side Deck, the Forbidden/Limited list.

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
```
