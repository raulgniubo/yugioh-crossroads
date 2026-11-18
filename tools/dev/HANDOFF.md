# Card plan part 2: where it stands and how a build is made

Branch `ocgcore`. `main` stays at 0.40.0. Version 0.50.0 is reserved for removing classic rules and merging.

## Done
- Build 1 shipped as **0.46.0**: Amazoness + Dark Scorpion, Crystal Beast, Vampire, Morphtronic, Scrap, Chronomaly. 214 new cards, 2,704 total.

## Left (ship each build the same way, no questions in between)
- **Build 2 (0.47.0):** Guardian (the weapon Guardians and Gate Guardian only, about 35, sorted by hand because set code "Guardian" is a name grab bag), Alien, Volcanic, X-Saber, Gimmick Puppet, Battlin' Boxer.
  First add the mechanic: in Heartland and at the Academy **one ordinary duelist carries up to three family decks and plays a different one each day**. No new characters. Heartland has no free duelist left, so Gimmick Puppet and Battlin' Boxer need this.
- **Build 3 (0.48.0):** Exodia + Gadget + Batteryman, Koa'ki Meiru, Arcana Force, Ice Barrier, Ninja.
- **Build 4 (0.49.0):** Kuriboh + Magnet Warrior + Harpie, Cloudian + Fossil + Venom, Naturia, T.G., Fire Fist.
- **Build 5 (0.49.5 or similar, not 0.50.0):** Dark Magician, Blue-Eyes, Red-Eyes, Armed Dragon and the LV monsters, Nordic, Bujin.
- Famous-name families (Kuriboh, Magnet Warrior, Harpie, Dark Magician, Blue-Eyes, Red-Eyes, Armed Dragon/LV) go in as **packs and a shop deck only**. Duelists' own decks stay unchanged.

## Rules that always apply
- Never skip a card or change its effect because an engine piece is missing: build the piece. Only skip Links, Pendulums and cards from animes not planned. Full families.
- No new street duelists: an ordinary NPC of the family's era gets the deck. Theme decks open with their era. Every card must be obtainable.
- Reports: casual direct English, no em dashes, cards added and the new total, honest about what was not checked.
- No deleting on Raul's Mac. Replace the app in place, exe + dll into the Windows folder.

## One family, step by step
1. Scan: `tools/dev/scan.sh <key> <hex set codes> '<name regex>' [-t]` (set codes: probe/CardScripts/archetype_setcode_constants.lua). Extra adds/drops in `/tmp/fam_extra_<key>.json` as `{"add":[...],"drop":[...]}`.
2. Spanish card text: `tools/dev/cardes/<key>.py` with `ES = {...}`, then `python3 merge.py <key>.py`.
3. Family: `tools/dev/families/mk.py` `make(spec, strings)` (see chronomaly.json for a spec). Deck must be exactly 40.
4. `tools/cards.sh` (ids, engine data, script refs, card check, hand-made positions).
5. Sweep: `godot --headless res://tests/ocg_sweep.tscn -- 80 1 /tmp/sweep_<key>.txt <key>`. Every "NO POSITION YET" card gets an entry in `tests/card_positions.json`.

## One build
1. All families as above, then `godot --headless res://tests/ocg_sim.tscn -- all x 20 1` (about 6 minutes, run in the background), `tools/dev/parse.sh`, the classic test runner, and one on-screen duel per new deck with `tools/dev/scr.sh`.
2. Bump `project.godot` and `export_presets.cfg`, README section on top, commit, `tools/dev/ship.sh <version> ocgcore`.
3. Send both zips, copy them to `Old builds/Crossroads-latest*.zip` on the Mac, unzip. **Never copy over the app in place:** once macOS has run an app, overwriting its files makes it die at launch with "Code Signature Invalid" (this happened with 0.47.0). Instead `mv` the old app into `_to_delete/` under a new name, then `cp -Rp` the freshly unzipped app into the Mac folder, and `diff -rq` the two. Exe + dll to the Windows folder.
4. Mark the rows Shipped in the part 2 plan doc and add an entry to the migration plan doc.

The copies here were saved from /tmp and /home/claude/work so they survive a restart; the working copies still live there.

## Before build 2: competitive character decks (waiting for Raul's go)
Plan doc "Crossroads: competitive character decks" (https://claude.ai/artifact/U6hs873oskdBTZRj1x1Wxy). All 24 character decks rebuilt, 403 new cards (2,704 to 3,107), one build, 0.47.0, before build 2 of the card plan.
The lists are in `tools/dev/character_decks/decks.py` (checked by `check.py` there against the card database: names, no Links or Pendulums, 40 cards, at most 3 copies). They go into `SignatureDecks.TUNE` "main" and "extra". Borrowed (plain) versions stay as they are.
Not built yet. Do not start until Raul says go. His answers to the three questions at the bottom of the doc decide: gods out or one copy, Vector with Numeron or not, one build or two.

## 0.47.0 shipped: competitive character decks (done)
402 new cards, 3,106 total. Lists in `tools/dev/character_decks/decks.py` and `SignatureDecks.TUNE`.
- Six decks have a second list the CPU plays (`cpu_main`/`cpu_extra` or `cpu_swap` in TUNE; `SignatureDecks.cpu` is set while the opponent's deck is dealt). The player always gets the real list.
- When a family from the card plan is added later and some of its cards are already in `CardPool.ADDED` (Harpie, Dark Magician, Blue-Eyes, Red-Eyes, Armed Dragon, Blackwing and others), take them out of ADDED so they are not listed twice.
- Benchmark tools used: `DUEL_LOG=1` on ocg_sim, `-- deck all`, and 20 duels against deck_monarchs and deck_amazoness per character.
- Next: build 2 of the card plan (see above). Version numbers move up by one: build 2 is 0.48.0.

## Batch after 0.47.0 (Raul, Nov 18): engine-only, duel interactions, intro. Ships as 0.50.0, merged into main.
Raul's words: old engine out, merge ocgcore into main as the default; fresh look at the duel INTERACTIONS (not the look: duelist panels, names, LP stay); intro hitch. New card families wait until this is done. One batch, report at the end.

Done so far:
- Intro: bands + duelist portraits prepared in the dark (`_prepare_bands`), worlds freed one at a time (`_take_down`) in scripts/menu/first_start.gd.
- Classic rules can no longer run: Settings switch, Free Duel fallback and `--classic` are gone; without the engine a duel refuses to start. The classic rules CODE (effect_runner, spell_rules, duel_ai, card_effects, card_exact, most of duel_state, tests) is still in the repo as dead code; many menus still call SpellRules/CardExact for "does this card work". Deleting it is a separate careful job.

Duel interaction plan (engine path lives in scripts/ocg/ocg_table.gd; HUD in scripts/duel/duel_hud.gd; board in duel_board.gd):
1. Action menu on a tapped card: animated pop-in, icons, hover (hud.show_actions).
2. One panel to pick several cards (Tributes, Synchro/Xyz materials, sums): toggle cards, counter, Confirm. On the field when every candidate is on the field.
3. Choose the zone: drop a dragged card on the zone you want; from the menu, free zones glow and you click one (engine message 18).
4. Attack by dragging from your monster to the target with an arrow; drop on the opponent for a direct attack. Click flow stays.
5. Animations for summon, set, special summon, attack, direct attack.
6. Remove the stale note "Not in this game yet: this card plays with its ATK and DEF only." (duel_hud.gd ~1066, 1102).
Dev tools: `/tmp/shot.sh <name> <seconds> args` takes a screenshot of a duel (xvfb + opengl3); `--ux=menu|pick|choice` opens one interaction (OcgTable._ux_demo).

### Where that batch ended (0.50.0)

Shipped as 0.50.0 and merged into `main` (the default branch from now on; `ocgcore` is the same commit).

How the duel is played now (all in scripts/ocg/ocg_table.gd unless said otherwise):
- `acts[uid]` entries are `[word, answer, kind, second line, can attack directly]`. Kinds: summon, tribute, special, mset, sset, act, repos, flipsummon, attack. `_menu_for(card, only)` builds the menu; hud.show_actions takes `[id, word, enabled, kind, second line]`.
- `want` = what the player already said before the engine asks: `zone` (a hand card dropped on a zone), `target` / `direct` (an aimed attack), `attacker` (an attack dragged out of Main Phase 1). `_ask_place`, `_ask_cards` and message 13 (desc 31, "attack directly?") read it.
- `aim` = an attack being aimed (`_aim_start`, `_aim_go`, `on_input` for the drag). Nothing is sent to the engine until the target is chosen.
- Picks: `hud.ask_cards()` (scripts/duel/card_picker.gd, class CardPicker) for anything not on the table; `_pick_on_board`, `_pick_many_on_board`, `_pick_live_on_board` when every candidate is on the field. Message 26 (materials one at a time) is "live": the box or the markers stay up between the engine's steps (`_live`, `_live_end`).
- Zones: `board.show_zone_picks(zones, word)`, `board.zone_at(screen, zones)`; zone = [player, location, sequence].
- Engine events: a Tribute for a Normal Summon carries RELEASE + SUMMON + MATERIAL. ocg_duel.gd sends it as "tribute" (not "material"), and the loop clears `s._materials` at every free moment (messages 10 / 11). Before, such cards floated over the table for the whole turn.

Dev tools:
- `tools/dev/shot.sh <name> <game seconds> args` : a screenshot of a duel (software rendering is about 4x slower than the clock; never run two at once, and take a snapshot of the scripts first if you keep editing).
- `--ux=menu|menu2|pick|pick1|choice|pos|drag|zone|aim|many|tsummon|tsummon2` opens one interaction (OcgTable._ux_demo). Puzzles are the quick way to a board with monsters: `--puzzle=tribute --ux=aim`, `--puzzle=mage --ux=aim` (direct attack), `--puzzle=tribute --ux=tsummon2` (a whole Tribute Summon).
- `tools/dev/ht.sh <name> <deck> <opp deck>` : a headless duel where the boxes, the picks on the table and the zones are answered at random (`--human-test --human-board`). It finds script errors in the interaction code.
- `--lay=<json file>` puts cards in place at the start of a normal duel (see duel_scene.gd `_start`).

Still open:
- The classic rules files are dead weight but not deleted: duel_state.gd is the base of the table's view model (OcgMirror) and has 500+ calls into effect_runner / spell_rules; collection.gd, card_data.gd, signature_decks.gd and deck_builder.gd read CardExact / SpellRules.FX / CardEffects for card facts. Plan for a later cleanup: move the few facts the menus need (spell kind, "is this card in the game") to CardPool / card data, cut DuelState down to the fields and helpers the table reads, then delete effect_runner.gd, spell_rules.gd, duel_ai.gd, card_effects.gd, card_exact.gd and the classic tests in tests/test_runner.gd.
- Controller support for aiming an attack and for choosing a zone.
- Intro fix and every animation: not seen on a real GPU yet.
- Card plan part 2, builds 2 to 5 (Raul will switch to Opus 5.5 medium for those). Next card build is 0.51.0.
