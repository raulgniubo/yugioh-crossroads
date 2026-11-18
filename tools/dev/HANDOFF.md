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
3. Send both zips, copy them to `Old builds/Crossroads-latest*.zip` on the Mac, unzip, check the file list matches, `cp -R` over the app in place, exe + dll to the Windows folder.
4. Mark the rows Shipped in the part 2 plan doc and add an entry to the migration plan doc.

The copies here were saved from /tmp and /home/claude/work so they survive a restart; the working copies still live there.
