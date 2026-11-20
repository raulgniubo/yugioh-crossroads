# Card plan part 2: where it stands and how a build is made

Branch `main` (ocgcore was merged in 0.50.0). Card plan part 2 is done: build 1 shipped as 0.46.0, builds 2 to 5 shipped together as **0.51.0**.

## Done
- Build 1 shipped as **0.46.0**: Amazoness + Dark Scorpion, Crystal Beast, Vampire, Morphtronic, Scrap, Chronomaly. 214 new cards, 2,704 total.

## Builds 2 to 5 (all shipped together in 0.51.0; kept for the record)
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

### After 0.50.0: 0.50.1 and 0.50.2 (same day), and the parked cleanup

Raul played 0.50.0 and sent fixes one after another; they shipped as 0.50.1 and 0.50.2 (see the README). main is at 0.50.2.

**The old-rules cleanup is PARKED on purpose. Raul said: do not continue it until he says so.** Its first step is on the branch `cleanup-old-rules` (pushed), cut from the 0.50.0 commit:
- `scripts/core/card_facts.gd` (class CardFacts) holds the few facts menus still read (Spell/Trap kind, Field Spell boosts, which of the game's own cards work, Speed Spell costs) and every outside caller of SpellRules / CardExact / CardEffects / DuelAI / EffectRunner uses it instead. Nothing is deleted yet.
- `tests/facts_gen.gd` made the tables and a baseline of every answer for all 14,339 known cards and every deck (`tools/dev/facts/base.json`); `tests/facts_check.gd` + `tools/dev/facts/cmp.sh` compare the new code against it ("FACTS SAME" when identical). It was identical.
- Left to do when he says go: rebase that branch on main (0.50.1 / 0.50.2 touched ocg_table.gd, duel_hud.gd, duel_scene.gd), cut `duel_state.gd` down to what the table reads (OcgMirror extends it; it has 500+ calls into the old files), delete effect_runner.gd, spell_rules.gd, duel_ai.gd, card_effects.gd, card_effects_auto.gd, card_exact.gd and the classic tests in tests/test_runner.gd, then: parse, cmp.sh, tools/cards.sh, the 1,260-duel sim, ht.sh duels.

Things learned on the way:
- The loading card (scripts/ui/load_card.gd) must `remove_child` its old labels before adding new ones with the same names.
- A forced chain question (message 16, forced = 1) can list mandatory steps together with optional Set cards. The table answers with the first entry that is mandatory-looking (mode != 0, or face-up on the field) and never shows a box for it.
- `Router.toast` holds messages while a place is loading.
- Software rendering here is about 4x slower than the clock: screenshot time limits must allow for it (tools/dev/shot.sh does).

## 0.51.0 shipped: card plan part 2, builds 2 to 5 in one build (done)
763 new cards, 3,869 total. 22 families (29 sub-families), each with pack, theme deck and duelist; see the README table.
- Build scripts: `tools/dev/families/b2.py` .. `b5.py` (specs + Spanish UI strings, run with `python3 bN.py [key]`), scans in `fam_specs.txt` + `extra/`, Spanish card text in `tools/dev/cardes/<key>.py` (+ `extra3.py`, `extra4.py` for the five helper cards).
- **Rotation mechanic** (`RoamData.district` / `deck_today`, `add_family.py` npc `rotate: true`): a world duel may carry `"decks"` (max 3) and `"intros"`; the deck of the day comes from the real date. Used by ac_beach, ac_ghost, night_heartland, hl_boy (3 decks), hl_jeweler, hl_girl.
- Cards that moved into families were taken out of `CardPool.ADDED` (`/tmp/dedup_added.py` logic: any ADDED name that is in a family). Cross-family duplicates kept in the first family (Chronicle Sorceress/Magician, Strength in Unity, Destined Rivals, Red-Eyes Dark Dragoon in Dark Magician; Winged Kuriboh LVs, Magnet Circle LV2, Multiplying Kuriboh!, Magikuriboh in Kuriboh). Cards already in older families were dropped from the new ones.
- Before shipping a family, list the cards its texts name that the game lacks (tokens aside) and add them: that is how The Claw of Hermos, Rise of the Snake Deity, Shining Sarcophagus, White Veil and Fairy Tale Prologue came in.
- `native/custom/c39163598.lua`: fixed copy of Planet Pollutant Virus (official script errors on a deleted effect). `native/custom/c43582229.lua`: Freezing Chains of the Ice Barrier (immunity condition recursed through set-code effects; seen in deck_ice_barrier vs deck_ninja, sim seed 4901). Files in native/custom override official scripts of the same name.
- Hand-made positions added for 12 cards. Counter Traps with a "reveal from hand" cost need a hand the AI cannot empty first (Snake Deity's Command uses two Venom Boa).
- No card plan is queued after this. Next is whatever Raul asks; the old-rules cleanup stays parked until he says go.

## Card plan part 3
Plan doc: https://claude.ai/artifact/1UfohMDpMZddGeut9ACkXb (project 03dcff0c-47fa-45ee-a7b2-821ed9925a02, node a1da7b6f-7154).
About 975 cards: 21 families (~650) and ~330 single cards, even across the eras, plus deck strength by stars
(Starter 1-2 stars / Standard 3 / Full 4-5; stars pick the deck, stars + Settings.cpu_level pick the play).
Lists: `tools/dev/plan3/plan.json` (families per era and singles per era, all checked missing from the game; Uria and Hamon
belong to the Sacred Beast family, not the singles). Build 1 = 0.52.0 (stars + singles), build 2 = 0.53.0 (families).
Raul's answers (Nov 18): keep the 21 families; stars 1-2 Starter, 3 Standard, 4-5 Full; characters always keep their own deck
(Free Roam, Free Duel); two builds. Mid-build he added: Story gets simpler character decks early, whole decks for the bosses,
and the story difficulty moves it. All of that is build 1. Build 2 is only the families (cards, packs, decks, duelists).

### Build 1 shipped as 0.52.0
- 334 singles in CardPool.ADDED (comment "0.52.0: card plan part 3"). 4,203 cards. Dropped: Raidraptor RUMs and Number 8
  (unplanned archetypes), NEX and the two Neo-Spacians not in the card folder, Uria/Hamon (Sacred Beast family, build 2).
- **Deck versions** (`scripts/core/deck_tiers.gd`): a key "deck_x@starter" / "@standard" asks CardData for that version; it is
  built at deal time from the Full list, so it follows the deck. Standard = no TOP staples (swapped for MID), 3rd copies of its own
  cards cut to 2 (plain Normals / MID fill), no GENERIC_EXTRA. Starter = own Level 4 or lower monsters (2 each, ~14), 1-2 bigger,
  plain Normals that share its Type/Attribute to 18, 6 own Spells/Traps (1 each), BASICS to 40, 3 weakest own extras.
  Prize cards still come from the whole deck (duel_scene passes the base key).
- Who gets which: `DeckTiers.for_duel(deck, who, stars)` in roam_scene, tournament, academy, turbo_ride. Unlocks.SERIES_STARS
  characters, DECKS keys and starter_* decks are always whole. NOTE: the engine's thinking is Settings.cpu_level everywhere; the
  per-duel "difficulty" only picks legend_deck and Destiny Draw, so the deck version is the main thing stars change.
- Story: every story duel has "deck_tier" in story_data; StoryDirector shifts it by Saves.story_difficulty() (Hard +1, Extreme +2).
  The hunter plays deck_shadow (was Yusei's deck).
- Full decks: `tools/dev/tiers/make_tiers.py --write` swapped up to 3 weak generics for era singles in 8 family decks
  (not Exodia or Kuriboh, stall decks).
- ocg_sim: `-L1 -B` makes both sides think in the engine (needed to see deck differences; the plain policy can't use staples).

### Build 2 shipped as 0.53.0
- 19 families (specs in `tools/dev/families/b6.py`, Spanish card text in `tools/dev/cardes/`): legends_king (pack renamed
  "Swords of Legend"), jurrac, darklord, spirit (+ Elemental Lords), union, hero, sacred_beast, cyber (+ Roids), meklord,
  synchron, karakuri, fabled, fortune_lady, gusto, mermail, wind_up, spellbook (+ Charmers), ghostrick, dragon_ruler.
  661 cards, 4,864 total. Dropped: Speedroids, Cyberse, Rokket Synchron, Cybersal Cyclone (unplanned shows); A Legendary Ocean
  (not in the card folder). The Shop Regular has "chats", not "lines", so add_family's rotate step fails on him: done by hand.
- **Volumes** (`Collection`: VOLUME_SIZE 150, volumes(), all_volumes(), shop_packs(), pack_title(), base_key()). The big
  SERIES sets are sold as "Duel Monsters#1".."#9" etc. pool("X#n") is the n-th slice of pool("X") sorted by
  `data/release_order.json` (card id -> Konami database number, made by `tools/dev/release/make_release_order.py` from
  yaml-yugi's aggregate cards.json on GitHub). PACKS still lists the whole sets: the album, album goals and pack covers keep
  using them. Unlocks.pack strips "#n". card_check checks the volumes cover each set exactly once.
- **Multi-open**: Collection.open_packs(key, n) (MULTI 5 -> 4.5x, 10 -> 8.5x the price), PackOpening.counter/last/skip_rest,
  `scripts/menu/pack_summary.gd` for the end screen. Dev: `--open=packmulti`, `packmulti10`, `packmulti10s` (skips to the end).
- Pack shop shelf is inside a ScrollContainer; album set names shrink to fit; Duel Dome solid (collide 0.92) with its sign on
  the rim's front; Kame Game back-left shelf removed for the vending machine.
- To see a prop that only lives on Raul's Mac in a test shot: copy its .glb from the staged uploads into
  `<test assets>/places/<name>.glb` (CityBuilder.own_place) and pass that folder as --assets. Don't commit it.

### Next: card plan parts 4 and 5 (doc aeb9ec09-f61b-428c-a4e7-235e63dc3e90, "Crossroads: card plan parts 4 and 5")
- Build 1 = 0.54.0: Duel Monsters and GX years (~1,390 cards, Konami id < 7734), mostly singles; 6 small group decks with packs
  (D.D., Goblins, Masks, Toys/Puppets, Barrier Statues/Counter Fairies, Frogs/Penguins) + 4 Type decks (Rock, Insect, Zombie,
  Machine); Chrysalis joins hero. Build 2 = 0.55.0: 5D's and ZEXAL years (~1,640), 19 families (table in the doc).
- Missing list: /tmp/missing.json (from yaml-yugi aggregate cards.json minus /tmp/ocg_ids.txt, no Link/Pendulum). Era by
  Konami id: GX starts 6310, 5D's 7734, ZEXAL 9575, Arc-V 11213.

### Build 1 of parts 4-5 shipped as 0.54.0
- Singles live in `data/singles.json` (CardPool.singles(), joined into era pools and added_names). 1,272 names, era by Konami id.
- Groups (`tools/dev/families/b7.py`, lists in `tools/dev/families/groups.py`): dd, goblin, mask, toy (DM), barrier, frog (GX).
- Type decks (`tools/dev/families/typedecks.py`): deck_rock, deck_machina (NOT deck_machine: that key is the old Gear Works
  deck), deck_insect, deck_zombie. add_family.py takes `"no_pack": true` for a theme deck with no family/pack.
- Spanish card text for new cards: official Spanish from yaml-yugi (`tools/dev/cardes/b54_official_es.json`), quoted names
  mapped back to English (es->en name map, then positional match with the English text's quotes). 8 hand-written.
- CardFinder (`scripts/core/card_finder.gd`): album card view lists packs (+ which world shops), theme decks (+ worlds),
  ordinary duelists (npcs + shop_npcs). Album search finds unknown cards from 3 letters (picture stays hidden).
  Dev: `ALBUM_SEARCH="name" ... --menu-open=album`.
- Engine fix (native/ocgcore/processor.cpp, processor_unit.h): ForcedBattle keeps the attacker/target it interrupted and
  restores them; BattleCommand steps 9-13 end the attack if core.attacker is null. Repro was Last Turn in a staged position
  (`SWEEP_ONLY=28566710 ... ocg_sweep.tscn -- 0 1 out added`). When rebuilding native, delete the non-l_*.o objects in every
  build/<target> dir first: build.sh skips objects that exist, and a changed header otherwise leaves stale objects.
- Sweep focus "singles" = data/singles.json only. SWEEP_TRACE=1 prints each staged card to stderr.
- deck_mask was retuned by hand after the sim (5 weak curses out, staple traps in); b7.py still has the first list.

### Build 2 of parts 4-5 shipped as 0.55.0
- 19 families via `tools/dev/families/b8.py` (5D's: worm swarm vylon gishki watt laval ally_justice flamvell reptilianne; ZEXAL:
  evol phantom_beast noble_knight gears inzektor sylvan hazy hieratic artifact heraldic). ZEXAL duelists are new Heartland
  Lounge regulars (MoreRooms.PEOPLE["hl_lounge"], 2 decks each); add_family.py accepts npc: None now.
- Singles for 5D's/ZEXAL years in data/singles.json. Spanish: tools/dev/cardes/b55_official_es.json.
- Bundles: Collection.BUNDLES (18), shop_packs() replaces every family pack with its bundle; family packs stay in PACKS for the
  album, goals and covers. unlock_key() (static) maps a volume to its set and a bundle to its first family. card_check prints
  every shop pack's size and fails a family that is in no bundle or two. A new family must be added to a bundle by hand.
- BIG_PACKS (Type/Element/Beyond/spells/traps) come in volumes of up to BIG_VOLUME (280).
- The tab-3 pack "spellbook" (Sorcerer's Library) is now "spells": its key had collided with the Spellbook family's.
- native/custom/c53334471.lua (Gozen Match): tp nil guard.
- Fixed in 0.55.1: the bridge's Duel never called OCG_DestroyDuel (only Sim did), so every played duel leaked its engine.
  Duel now frees it in its destructor (non-copyable), Sim relies on that, and OcgDuel.close() also runs on PREDELETE.
  Check: `godot --headless res://tests/leak_check.tscn -- 200` prints growth per duel (0 KB now, ~800 KB before).

### 0.55.2 and 0.55.3: finding cards
- 0.55.2: album search lists every matching card with its picture.
- 0.55.3: the album never shows "?" for a real card any more: AlbumSlot state is owned | seen | missing, and anything not owned
  is drawn with AlbumSlot.gray_material() plus a TE FALTA (Loc "MISSING") pill.
- CardWhere (scripts/menu/card_where.gd): the "Where to find it" window, from the album's side panel (W/Enter, pad A).
  Data from CardFinder.places(id) / summary(id); every pack or deck in it is clickable and opens CardListView. It shows
  information only, by Raul's rule: no button that takes you to a shop. If packs or decks move, CardFinder follows
  shop_packs(), THEME_DECKS, deck_catalog() and the roam/room people, so it updates by itself.
- CardListView (scripts/menu/card_list_view.gd): every card in a pack (Collection.pool) or deck (deck_list + extra_list),
  from the pack shop and deck shop (button, C key, pad X). Filters have/missing (F/Y) and rarity (R/X); faces load 10 a frame.
- Dev env: ALBUM_SEARCH, ALBUM_WHERE, WHERE_SCROLL, WHERE_LIST, PACK_CARDS=<shelf index>, DECK_CARDS=<index>,
  LIST_FILTER=all|have|missing|<rarity>, LIST_SEL=<index>.

### 0.56.0: card plan part 6 (doc 58a967cf-f14c-4403-9370-ec56132562b3, "Crossroads: card plan part 6")
- Raul chose a picked set from after ZEXAL instead of all ~4,500. Picks: `tools/dev/plan6/` (pick.py with RELAX=1,
  staples.txt, fam_extra.txt, drop.txt -> picked.json; apply.py --write places them; decks.py --write adds the 7 decks).
  Rule: no Link/Pendulum monsters and no text that needs them; "Fusion, Synchro, Xyz, or Link Monster" lists are fine.
- Four-show cards: into their FAMILIES list when the game has one (apply.py FAMKEY), else data/singles.json by era.
- "frontier" is a SERIES set (singles.json era "frontier"), PACKS tab 0, price 200, Heartland only, PACK_STAGE 6 (end of
  story; pack_why says so). pool() keeps frontier ids out of the themed packs; trader and claw skip it until it opens.
  THEME_DECKS entries can carry "stage": the deck shop shows them locked until Unlocks.stage() reaches it.
- data/cards_extra.json (tools/dev/make_cards_extra.py <game ids> <reference cards.json> <player's cards.json>): Raul's
  cards.json renames cards and has some only under reprint ids; CardData._load_extra adds/renames them and IMAGE_ALT points
  the picture at the reprint. Regenerate it after adding cards (game ids from tools/dev/dump_ids.tscn).
  Test card folder /tmp/testassets3 now uses Raul's cards.json (staged from his Mac); the old one is /tmp/cards_old_14321.json.
- Spanish: tools/dev/cardes/official_es.py (official text, quotes back to English) + b56_hand.py (11 written here).
- ocg_sweep focus "list:<json of names>".

### 0.57.0 and 0.58.0: duels feel alive (Raul asked for two builds back to back, overnight)
- Kit: `scripts/duel/duel_fx.gd` (DuelFx: ring, glyph, pillar, spiral, pit, glow, rect, rays, sparks, embers, orb, chain;
  all shader quads, additive, self-freeing, Settings.t speed; warm(board) pre-builds the shaders), `fx_orb.gd` (trail),
  `fx_orbit.gd` (Xyz Materials circling a card), `summon_fx.gd` (SummonFx.play per method, returns when the monster
  should appear), `chain_fx.gd` (ChainFx: link/solving/negated/solved/end), `screen_fx.gd` (flash, letterbox, speed lines,
  shatter: a canvas shader over the screen texture).
- Engine events added in ocg_duel.gd: "chain_link" (after the card's own activate/trap/effect event), "chain_solving",
  "chain_solved" (both only for chains of 2+), "chain_negated" (messages 75/76), "chain_end"; "special" carries "origin"
  (the engine location the card came from). The old "chain" banner event is gone.
- DuelBoard: anim_summon/slam(), anim_special(..., origin), set_overlays -> FxOrbit, chain_spot/chain_link, anim_finisher +
  signal finisher_hit. duel_scene._play marks the last "battle" before a lethal "lp" in the same batch as "finisher".
  hologram() emits ace_summoned 0.4 s after the art is up (the name band used to hide the arrival).
- A tweened shader parameter must be set when the material is made (a null start value makes tween_property return null).
- Looking at an animation without playing to it: `--fxdemo=<name>[:frames[:gap]]` (scripts/duel/fx_demo.gd; names: summon,
  set, oppsummon, synchro, xyz, fusion, ritual, battle, finish, chain, effects, kit). /tmp/fx.sh in the session made a
  contact sheet from the frames (1280x720 xvfb, FX_WAIT default 16 s so the deal is over, clock at 0.2x).
  A whole duel on screen with the test player: `--duel --skip-opening --human-test --speed=2 --deck=.. --oppdeck=..`.
- Two renders at once is the most this machine does in time.
- 0.58.0 (part 2):
  - `scripts/duel/clash_fx.gd` (ClashFx.play(host, a, b, a_mine, b_is_def, hit_in)): 2D, over the HUD. The loser's
    number is two copies of the Label under a shader that keeps one side of a jagged line (varying = VERTEX). The
    "battle" event now carries "atk", "t_atk", "t_def", "t_defending" straight from engine message 111 (aa/da/dd and
    the target's position bits), so the clash shows what the engine fought with. The clash starts 0.41 s before the hit
    (anim_battle: 0.26 wait + 0.15 dash); change both together.
  - DuelBoard: soul(from, to, color) is the light with a trail that carries a card between piles; _pile_arrives hides
    the card on the pile until the light lands; hand_pos(p); anim_travel(kind, p, inst) for search / gy_to_hand /
    gy_to_deck / mill; pile_flare, _deck_fan; anim_negated(inst) (seal at chain_spot); _stat_pop from refresh_stats
    (tracks _last_stats per uid); anim_destroy / anim_banish / anim_bounce / anim_discard / effect_burst redone on DuelFx.
  - MonsterHolo: CODE (the picture, + ace gleam), AURA (one shader for the back plane and the front plane: `front`,
    `depth`, `mode` 0-8 = how its Attribute or signature figure moves), POOL (floor light + the ace's circle).
    render_priority: back 0, picture 1, front 2 (stat labels are 2 with no depth test). height_for(data) sets the size.
    setup(..., ace): signature cards (SummonShow.SIGNATURE) are aces on their own; board.ace_ids adds the opponent's.
    Settings.gfx.detail 0 drops the front plane.
  - Camera: cam_punch(deg, roll) (field of view kick + roll, decays in _process), _battle_follow, the whip to the
    duelist on a direct attack (duelist_shot), the low swing in hologram() for big monsters (cam_shot then cam_drift).
  - set_overlays / sync_holos / holo_for read their dictionaries untyped: a freed node cannot go into a typed variable
    (that was 71 script errors in one duel after an Xyz card was redrawn; the lights never came back).
  - fxdemo names added: looks, holo, direct, oppbattle, ace. Env: FX_CASE=lose|tie|wall for "battle", FX_SKIP=<seconds>
    to start filming later. Deck names for --deck / --oppdeck carry the "deck_" prefix (deck_chaos).

### 0.59.0: the sea, and search in both languages
- 31 cards in CardPool.ADDED (marked "0.59.0: the sea"). A WATER check against yaml-yugi found only 3 cards up to
  ZEXAL's end missing (A Legendary Ocean, Lemuria, Neo-Spacian Marine Dolphin); the rest is the newer support for
  families already in the game (Umi, Kairyu-Shin, Fortress Whale, Legendary Fisherman, Deep Sea, Phantasm Spiral).
  Spanish text: tools/dev/cardes/official_es.py. Sweep of the 31: all played, 0 complaints.
- `scripts/core/card_search.gd` (CardSearch): fold(), score(id, english, folded query), matches(), es_name(),
  other_name(). Spanish names in data/card_names_es.json, made by tools/dev/cardes/names_es.py (needs
  /tmp/game_ids.txt from dump_ids and /tmp/dl_ygo/yy/cards.json); tools/cards.sh now runs it at the end.
  Used by the Card Album, the deck builder (_found: names, and card text in both languages via CardText.spanish)
  and the duel's "declare a card name" (ask_name). Dev: ASK_WORD="..." with --ask-test --ask-name-typed.
- A missing Spanish name (no official one yet, ~290 cards) just means that card is found by its English name only.
- 0.59.1: card_album._input sends any printable key (and Backspace) to the search box when it isn't focused; letter
  shortcuts are gone. Searches are debounced (0.15 s Timer) in the album and the deck builder. CardSearch also
  matches when every typed word is in the name. Dev: `--shots=<prefix>` (router) saves a screenshot every 0.5 s and
  logs slow frames; ALBUM_TYPE="word" times each search; for real keyboard input, run on a manual Xvfb display and
  drive it with xdotool (screen coords x1.2 = viewport coords at 1280x720).

### 0.63.0 IN PROGRESS: duelists come alive (plan doc a6c08700-2d6b-4c3e-a04f-8d0eb126e125, approved Nov 20)
Plan: https://claude.ai/artifact/MbHyzqSj3uSpMSELcQBKit . Two builds: 0.63.0 (motions + duel moments + more talking in
Spanish), 0.64.0 (all English voices). **Raul's rule: a build never waits on voices.** If a voice limit stops the
generation, ship with everything else and the missing voices come in their own build. He will not upgrade ElevenLabs
($100 plan not worth it): generate whenever the rolling daily limit has room. Spending limits he accepted: 300 Meshy
credits, 50,000 ElevenLabs credits. New Spanish text is neutral Latin American.
- **Part C (more talking): lines written and hooked, NOT generated yet.** `Characters.PLAYER_LINES` (every moment),
  `Characters.MORE_LINES` (per personality, joined to a duelist's own lines in `line()`, which also never repeats a
  line twice in a row), `LUMEN_SAYS` kinds first/second/long/thin_deck/win/close_win/flawless/lose. Attack calls by
  name: key `atk:<card id>` (`Voices.call_line(who, id, true)`), your duelist only. `duel_scene.gd`: `CALLS` table +
  `_call(p, kind)` (odds by `Settings.talk` 0/1/2 = Some/Normal/A lot, Settings > Audio "How much they talk"),
  `_last_words()` (winner, loser, Lumen in turn). `Voices.PLAYER_KINDS` covers every moment now.
  To do in C: generate (todo.json: 626 Spanish, 1,306 English = 680 old + 626 new; `batch.py` takes Spanish first),
  list and redo the old Spanish lines with Spain-only words ("Vale", "Menuda"), test with `--voicelog`.
- **Part A (motions): not started.** Today: `Avatars.gesture()` fits clips of `assets/models/anim/gestures.glb` to any
  skeleton (MADE_POSES are keyed in code); duels map moments to everyday clips (`DuelBoard.TALK_MOVES`) and
  `duelist_body()` tilts the WHOLE figure as one rigid piece for attack/hurt/summon/draw (that is the robotic look).
  Meshy: `meshy_animate` 3 credits per preset action (up to 10 per call, `post_process extract_armature` gives the
  skeleton without the mesh), `meshy_text_to_motion` 10 credits (prime). Useful preset ids seen: 377 battle pose,
  403 fist pump, 412/59 victory, 409 finger wag, 391 head hold, 404 crouch and step back, 31 catching breath,
  51 angry shout, 178/179/171 hit reactions, idles 0, 11, 12, 243-254, 599. Balance was 537 on Nov 20.
  **Meshy tasks made Nov 20 (66 credits so far):** test dummy text-to-3d `01a1f963-5122-73b8-9ef5-6047dd7083a7`
  (a plain robot dummy, not a character), its rig `01a1f963-f5a4-7491-a3c3-141005099d8d` (use this rig_task_id for
  every animate call), animation batch 1 `01a1f964-3fcf-73e0-abe8-b72b16a82018` (actions 377, 403, 409, 178, 179,
  171, 391, 31, 51, 315 in that order), text-to-motion "draw a card" `01a1f964-61ae-7002-9a53-551b8b06c9e1` applied
  as `01a1f965-bfbd-7770-a539-979ab69e3fd7`, text-to-motion "play a card and point" `01a1f964-66ec-753a-b3ae-70ab5b87dd77`
  applied as `01a1f965-c320-775a-9503-7725afd65ea8` (motion clips expire after 3 days). Next batch planned: 412, 59,
  404, 317, 318, 308, 311, 313, 306, 376, then idles 243-250. Merge tool: /home/claude/work/anim/merge.py (it merged
  lib_a.glb + lib_b.glb from his Mac's `Yu-Gi-Oh! Crossroads/meshy/anim/` into gestures.glb, mesh stripped).
  **Motion pipeline that works without Blender (custom motions):** `meshy_text_to_motion` (prime, 10 credits) ->
  `meshy_download_model(task_type "text-to-motion", save_to ".../Yu-Gi-Oh! Crossroads/meshy/anim/<name>.fbx")` saves the
  FBX on his Mac (SMPL-H skeleton: Pelvis, L_Hip, ...) -> `device_stage_files` -> copy into the scratch project
  `/tmp/fbxtest/in/` (project.godot + a copy of gestures.glb there), `godot --headless --path /tmp/fbxtest --import`,
  then `godot --headless --path /tmp/fbxtest -s tools/dev/motions/import_motions.gd -- <jobs.json> <repo>/assets/models/anim/clips`
  (jobs: src, name "g_<motion>", map "smplh" for these files or "same" for a Meshy rig file, optional from/to seconds).
  Clips land in `assets/models/anim/clips/g_<motion>.res`; `Avatars.gesture(model, "<motion>")` loads them by name.
  Made so far: `g_draw`, `g_play` (looked right on a test duelist: left forearm up, right hand to it; needs a closer
  look and trimming). Preview one motion slowed down: `--duel --skip-opening --first=me --rider-shot=0 --pose=<motion>
  --shots=<prefix>` (frames in /tmp/<prefix>_NNN.png).
  Text-to-motion batch 2 (Nov 20, 80 credits, total 146): set `01a1f973-6db3-71cc-80e5-2d2573bd24ac`, spell
  `01a1f973-729b-708d-ab1f-4dd0eb465886`, trap `01a1f973-7746-73c7-a879-2fbdb7d573fd`, point
  `01a1f973-7c0d-7709-8324-166e41297dff`, direct `01a1f973-80b8-7236-aeba-7f74bc316fab`, think
  `01a1f973-8550-7715-802e-4f4f3df6bb8b`, summon (arm up, then thrown forward) `01a1f973-8a86-714d-b10f-4ef55cefed74`,
  endturn `01a1f973-9005-7748-8ad3-3ac6bba225cd`. Saved on his Mac as `meshy/anim/motion_<name>.fbx`.
  **Preset animations are only download links** (assets.meshy.ai is blocked from his Mac's shell and from here).
  Asked Raul on Nov 20 whether Blender may download them like the audio; WAIT for his yes, do not use Blender for
  this before it. Until then only text-to-motion clips can come in.
- **Part B (duel moments): not started.** Turn beat, cards leave the duelist's hand, hits reach the body, camera cuts,
  thinking, the outro scene; settings "Camera cuts" and "Turn beat".

### 0.62.0: voices (Voices), face-off, narrated opening, hand reorder
- `scripts/core/voices.gd` (`Voices`): every spoken line is a file `res://voices/<lang>/<voice>/<key>.ogg`, key =
  first 12 hex of the md5 of the ENGLISH line (`"call:<card id>"` for monster call-outs). No file = no voice, the
  text bubble still shows. `voice_for(who)`: "narrator", "lumen" (Settings.voice_lumen: lumen_b warm, lumen bright,
  lumen_c calm, none), "player" (Settings.voice_me or the look: player_m, player_m2, player_f, player_f2), any other
  key by `Characters` personality + FEMALE (kind/cocky/cool/wild/dark _m/_f; wild and dark have no _f).
  `say(who, text, mine, must)`, `say_kind`, `call_line`, `rematch_line`, `hello_line`, `shout` (both voices, the only
  overlap), `length(who, text)` (seconds, 0 when nobody will say it: scenes use it to give a line room), `focus(on)`
  (music further down for the face-off), `hush`. Dev: `--voicelog` prints every line and what became of it.
- `Voices.Speaker` (a Node under root, made at start by `Voices.warm`): ONE voice at a time, 0.22 s of quiet after
  each line, a queue of 2 for `must` lines (valid 4 s), other lines are dropped while somebody talks. Ducks the
  Music bus (-5 dB, -11 dB under `focus`). Bus "Voice". Test: `godot --headless --path . res://tests/voice_overlap.tscn`
  must print `VOICE OVERLAP: PASS` (30 lines in 3 s never overlap; nothing gets on top of the shout).
- Hooks: `duel_scene.gd` (`_talk`, `_lumen`, the face-off with `_opp_intro()` and the "Duel!" shout before the
  DUEL banner, win/lose), `first_start.gd` (`_room()` times each line by its voice; narrator WORLD_SAY / TITLE_SAY /
  TITLE_SHORT), `main_menu.gd` `_lumen_hello()` (once per launch). `Profile.vs` / `last_vs()` / `last_won` remember
  the last result against each duelist for the rematch lines and the greeting.
- Settings: `voices_on`, `voice_volume`, `voice_opp`, `voice_lumen` (0 warm 1 bright 2 calm 3 none), `voice_me`
  (0 look, 1 male A, 2 male B, 3 female A, 4 female B, 5 none).
- The lines: `tools/voices/build_lines.py tools/voices/lines_src.json tools/voices/names_out.json` writes
  `lines.json` (1,792: 896 per language) and `todo.json` (what has no file, by `made.json`). New lines live in
  `new_lines.json` (with their Spanish). Voice ids of Raul's ElevenLabs account: `voices.json`.
- **State of the audio:** Spanish is complete (896 + 7 narrator lines in `voices/es`). English: 216 lines made and
  parked in `tools/voices/wip/en` (outside the build, `.gdignore`), 680 to go (`todo.json`), plus the 7 English
  narrator lines already cut (in `wip/en/narrator`). When English is done: move `wip/en` to `voices/en`, import,
  ship as 0.62.1. Do not ship English half-voiced.
- How the audio was made (ElevenLabs connector, model eleven_v4, about 1 credit per character): a flow with 20
  speech nodes, 20 lines per run, files collected and joined in the connector's sandbox with a 1 kHz beep between
  lines, the pack downloaded on Raul's Mac through Blender (he approved that use), split at the beeps, trimmed,
  levelled to -17 LUFS, saved as mono ogg. Things that bit: a DAILY generation cap (429
  daily_generation_limit_reached) separate from the monthly credits. It is a ROLLING 24 hours, not a reset at
  midnight UTC: after about 1,100 lines in one afternoon it closed, let 38 more through at 00:01 UTC and closed
  again. Plan a big batch for when the previous day's lines are a day old; the voice library is full at 30 of 30, so
  the narrator is NOT a saved voice: his 7 lines per language were cut from one voice-design take (seed 6262, the
  whole script as the sample text) at the pauses. To add narrator lines, a slot must be freed first or the same
  trick repeated (he will not sound exactly the same). Never transcribe a pack to check it (1,509 credits once).
  I cannot hear: voices were picked by description and measured pitch, lines were checked by length only.
- **Shipping got a size limit:** one file to the chat or to Raul's Mac can be at most 400 MiB. 0.62.0: the Windows
  zip fits with `zip -9` (396.7 MiB; /tmp/ship.sh now uses -9). The Mac zip (420 MiB) does not: `split -b 220m`,
  send the two parts with SendUserFile, commit them to `Old builds/`, join them there with `cat` in device_bash
  into `Crossroads-latest.zip`, check the md5, move the parts to `Old builds/_to_delete`, then `inst.sh`. With
  English voices (+27 MB) the Windows zip will need the same.
- Dev: `--open=settings --tab=3` opens Settings on Audio (for pictures). `--opening-auto` plays the first-turn
  game by itself, so the face-off and the shout can be watched in a test: `--duel --opening-auto --voicelog`.
- Hand reorder: `duel_hud.gd` `_hand_band` / `_hand_move` (a sideways drag inside the hand moves the card, up
  plays it). Dev check: `--handtest` with `--duel --first=me`. Exodia: the star pairs in `exodia_show.gd`.

### 0.61.0: effect looks (CardFx), special wins (WinShow), Field Spell floors
- `scripts/duel/card_fx.gd`: CardFx.kind(inst, label) picks one of 24 kinds (KINDS: emblem number, colour, second
  colour). Order: the effect's script label (LABELS); for a Spell/Trap the first thing its text does after a
  first-sentence cost, else the tags; for a monster the tags, then the text. Tags are `data/card_cats.json`
  (BabelCDB datas.category, built by tools/dev/make_card_cats.py from /tmp/game_ids.txt, which
  tools/dev/dump_ids.tscn writes). play(board, spot, k, high, quiet), aim(board, from, to, k),
  to_duelist(board, from, p, k), bless(board, p), emblem(), warm(board). The emblem is one shader with 24 SDF
  pictograms (blend_mix, no depth test, billboard).
- `scripts/ocg/ocg_duel.gd`: "activate" / "trap" / "effect" carry "label" (English script description), "effect" also
  "src"; engine message 83 becomes {"type": "targets", "cards": [...]}. Win kinds: 16 exodia, 21 destiny_board,
  17 countdown, 2 deckout, any other reason above 16 is "card:<id>".
- `scripts/duel/duel_scene.gd`: _card_look(p, card, label) plays StrikeFx.card then CardFx.play (quiet when the card
  has a signature look); "targets" calls CardFx.aim (up to 3); "lp" sends burn damage with to_duelist and any gain
  with bless; _fx_card / _fx_kind / _fx_p / _fx_at remember the effect that is resolving and are cleared on
  chain_end. _finish() plays ExodiaShow or WinShow.play(scene, board, hud, winner, kind).
- `scripts/duel/win_show.gd`: _destiny, _countdown, _deckout, _card. Same skip rule as ExodiaShow (_w()).
- Field floors (`field_themes.gd` GROUND_GLSL): the blocky floors came from value noise on a square grid plus a
  sine hash that loses precision on some GPUs. Now g_hash has no sine, g_noise is gradient noise and g_fbm rotates
  each octave. ground_lit(p, kind, t) adds relief from the slope of the luminance plus grain; the mat shader in
  duel_board uses it for both surfaces. Surface 3 (Mountain) repainted, surface 23 (brass and gears) is new
  (look "gears"). field_looks.gd: about 30 more names in BY_NAME, and BY_WORD reads the first Attribute or Type
  word of the text before falling back to "plasma".
- The air particles of a place (_field_air) need billboard_keep_scale = true: without it every particle that has
  not been emitted yet is drawn at the emitter, full size and black (default Color). The arena's particles already
  had it. Additive particles never showed it.
- Renderers: the Mac runs Forward+ (Vulkan). `--rendering-driver vulkan` reproduces it here on lavapipe (minutes per
  run); opengl3 is the fast one for everything else.
- Dev: `--fxdemo=emblems`, `cardfx` (FX_CARD), `win` (FX_KIND=destiny_board|countdown|deckout|card:<id>, FX_OPP=1),
  `fieldlooks` (FX_SCALE=1 FX_SKIP=2.2, 14 frames, gap 2.4), `fieldspell` (FX_CARD, FX_ZOOM=1);
  `--duel --end-test --win=<kind>`; `--menu-open=decks` opens My Decks.
- Not checked: a real GPU with real card art (the floor fix was checked on a software Vulkan renderer), sound mix,
  controller, Turbo Duels with the new looks, a real Destiny Board or Final Countdown win played to the end (the
  shows were triggered directly).

### 0.60.0: Attribute attacks (ElementFx) and the Exodia win (ExodiaShow)
- `scripts/duel/element_fx.gd`: gather(board, inst, at, tier) from anim_declare, travel(board, inst, from, to, tier, dur)
  with the dash in anim_battle, impact(board, inst, from, at, tier) on the hit. tier_of(inst): 0 under 1500 ATK, 1 from
  1500, 2 from 2400 or Level 7+. ranged(inst) = StrikeFx kind is beam or blast: those stop at 30% of the way and fire.
  Pieces: ribbon (one shader, modes 0 fire 1 water 2 wind 3 light 4 dark 5 earth crack 6 divine; world_vertex_coords,
  faces the camera or lies flat), puff (0 fireball 1 flame 2 mist 3 smoke 4 dark flame), decal (0 scorch 1 ripples
  2 shadow pool 3 cracks), twister, crown, wave, spike (rock or fang), lance, light. Fire, water and dark pieces use
  blend_mix (they keep their colour; additive washed out to white), the rest are additive. warm(board) at duel start.
  anim_battle timings by tier are BATTLE_WAIT / BATTLE_DASH; duel_scene asks board.battle_hit_time(inst) so the clash
  numbers and the speed lines land with the hit. _attr_hit is no longer called.
- `scripts/duel/exodia_show.gd`: ExodiaShow.play(scene, board, hud, winner), awaited in duel_scene._finish when
  state.win_kind == "exodia" (set by ocg_duel on victory reason 16, and by the old engine's own check). The figure
  always faces the loser and the camera sits at the loser's end; the opponent's hand cards and the HUD hand are hidden
  while it plays. Every wait goes through _w(), which returns true once any key or button was pressed.
- Dev: `--fxdemo=elem` (FX_CARD="name", FX_OPP=1, FX_DIRECT=1, FX_GATHER=1), `--fxdemo=exodia` (FX_OPP=1),
  `--duel --end-test --exodia [--lose]` for the show at the end of a real duel, FX_TAG to name the frames,
  `--parse-all` to list scripts that do not compile.
- This box's saved settings have anim_speed=2.0, so every demo here runs twice as fast as a default install:
  what takes 4.3 s in a demo takes about 8.5 s for a player on normal speed.
#### 0.63.0 notes of Nov 20, late morning (read after a context break)
- Part C Spanish: DONE. All 626 new Spanish lines are in `voices/es` (1,529 files), `made.json` has 1,752, Spanish
  to-do 0, overlap test PASS, a Spanish duel with `--voicelog` found every line. English: 1,266 left; the daily limit
  closed about 10:55 AM after 666 lines (see /home/claude/work/voices/PROCEDURE.md). Packs 88-89 (26 English lines)
  are still to be packed. ALWAYS read the clock with the time tool before telling Raul a time (I guessed 2 h off once).
- FOUND: with the table camera nobody sees the duelists' bodies. Their motions show only when the camera goes to
  them. So Part B's looks are what make Part A visible. Asked Raul (11:15 AM) whether he wants LIVE PORTRAITS (the two
  pictures by the Life Points become the 3D duelist from the chest up, all the time). NEW IDEA: wait for his yes.
- Part B written (compiles; turn beat, a Trap look and the ending seen in pictures, the rest not yet):
  `duel_scene.gd`: `_cut(p, moment, secs, big)` (awaited look at a duelist; gap 4 s Full / 8 s Fewer; `Settings.cam_cuts`
  0 Full 1 Fewer 2 Off), `_beat_secs(p)` + the beat in the "turn" event (`Settings.turn_beat` 0 Full 1 Brief 2 Off; 1.25 s
  on turns 1-3, 0.8 s after; banner moved to 27% of the height), `_act(p, moment)` (skips a motion a look has just
  played), opening hand = one pull of the arm (`_turn_seen`, `_dealt`), END/BATTLE calls use the event's player (state
  is a step ahead), battle damage flies on to the duelist (`_spill_at`, "lp" event) and `board.duelist_hit(p, big)`,
  `_outro(won, short)` (loser, winner + line, loser's answer, `board.outro_pullback`, Lumen; any key skips;
  `_outro_wait`, `_say_last`, `_lumen_last`). `duel_board.gd`: `duelist_shot(..., dist)` (dur 0 = a cut),
  `has_duelist`, `duelist_hit`, `outro_pullback`, `ACTS["ready"]`, no restart of a motion still playing (`_act_last`).
  Settings rows under Gameplay: "Camera cuts" (Full/Fewer/Off), "Turn beat" (Full/Brief/Off). Dev: `--pose-debug`
  prints ACT / CUT / OUTRO lines; `--duel --skip-opening --end-test [--lose]` goes straight to the ending.
- Meshy Nov 20 (second round, +80 = 226 of the 300 mark): preset batch 2 `01a1f9c2-6ca3-7262-82dd-1f3d10583d68`
  (412 victory, 59 victory cheer, 365 kneel on one knee and stand, 317 shrug, 318 scheming hand rub, 404 crouch and
  step back, 417 hop arms raised, 306 cheer one hand, 313 talk hands open, 376 punch pose); stances by personality
  (text-to-motion, 5 s): cocky `01a1f9c2-7115-77c7-8972-3a210d419b46`, wild `01a1f9c2-77ef-74dc-b344-1cd1ce9c9d3c`,
  dark `01a1f9c2-7e31-75eb-8625-f9b120622e24`, cool and kind: see the next lines.
  cool `01a1f9c2-8d77-70c3-a802-48b133a4cd52`, kind `01a1f9c2-9568-702a-b6ea-f63fabcea682`. Saved on his Mac as
  `meshy/anim/motion_st_<pers>.fbx` (cocky is `motion_st_cocky2.fbx`, same file twice) and `lib_d.glb` (preset batch 2).
- Converter (`tools/dev/motions/import_motions.gd`) new job keys: `"loop": secs` (the end eases back into the first
  frame, loop on), `"hips": true` (the hips travel too: a kneel, a hop, a stance with bent knees; for the SMPL-H files the
  hips' height is measured from the highest point of the whole clip). Job files: /tmp/fbxtools/jobs_st.json (stances),
  jobs_d.json + jobs_d2.json + jobs_d3.json (preset batch 2). New clips: g_st_cocky/wild/dark/cool/kind (stances, seen:
  good), g_win_a, g_win_b, g_kneel, g_kneel_down (first 1.1 s: ends kneeling), g_shrug, g_scheme, g_back_off, g_hop,
  g_cheer_one, g_talk_open, g_punch_pose (NOT all looked at yet).
- Personalities: `DuelBoard.style_of(key)` (named duelist: their personality; anybody else: one from their name; you:
  `Profile.style`, 0 = "Pick for me" = kind), `_style[p]`, `fig.stand_as("st_<style>")` (RoamFigure.stand_as waits
  for the model), `STYLE_WIN` / `STYLE_LOSE`, `duelist_win(p)` / `duelist_lose(p)` (used by the ending).
  Profile editor > You: "STYLE" (Pick for me, Friendly, Confident, Cool, Fired up, Dark).
- Card in the hand: `RoamFigure.hold_card(secs, delay)` (a card back on the RightHand bone; CARD_AT / CARD_TURN are
  guesses, NOT seen yet), `DuelBoard.CARD_IN_HAND` (which moments, when). Preview a whole moment: `--pose=act:draw`.
- Looking at the action: `DuelBoard.duelist_look(at, secs, only)` moves each duelist's `_focus` marker (their
  `watch`, `watch_far`); hooked in anim_summon, anim_special, anim_trap, anim_declare. NOT seen yet.
- Thinking: the opponent plays "think" as their Main Phase 1 opens.
- Spanish redo (Spain-only words): 11 Lumen lines reworded in extras.tsv and new_lines.json (Vale -> Bueno/Okey,
  Menuda -> Qué, a por -> por, lo han notado -> sí lo sintieron, hemos vuelto -> volvimos), 33 files to record again
  (they are in todo.json; copy them over the old files, do NOT use --update=none for these). Backup of the old text:
  /tmp/extras_before_latam.tsv.
- Signature moves (Nov 20, +140 Meshy credits = 366 used in all, 171 left): text-to-motion tasks, to be saved on his Mac as
  `meshy/anim/motion_<name>.fbx` and converted to `g_<name>`:
  face-off: fo_glove `01a1f9d0-037d-7676-94d1-8eb61b16f4dc`, fo_knuckles `01a1f9d0-09b9-70da-9ec4-0c9ede9284ce`,
  fo_chest `01a1f9d0-0ef8-77d0-8b59-12e0357ad3c8`, fo_bow `01a1f9d0-1488-71c8-9a40-f9f4ef36f727`,
  fo_hair `01a1f9d0-1a4a-7338-a81e-a65b98f970f2`, fo_salute `01a1f9d0-1ef0-70f1-ac5e-c738d08a22b6`,
  fo_beckon `01a1f9d0-240c-71b9-95d6-1bc7b839da46`, fo_open `01a1f9d0-2961-7148-bf84-e09bcbbe57c5`;
  ace: ace_sky `01a1f9d0-37e4-7480-8f41-5db2f09673db`, ace_both `01a1f9d0-3fb1-70aa-850e-b0d680d3361b`,
  ace_slam `01a1f9d0-4518-7758-83bf-99bc52b14bd9`, ace_sweep `01a1f9d0-4c4a-7285-a296-c90256193893`,
  ace_snap `01a1f9d0-5182-736d-989f-4a14fa35bc14`, ace_fist `01a1f9d0-5666-7457-b0d9-57dcf59cbc2f`.
  He has models for 25 characters (akiza alexis aster bakura chazz crow grandpa jack jaden joey kaiba kalin kite mai
  marik pegasus rex shark syrus vector weevil yugi yuma yusei zane). Plan: each gets their own pair (face-off pose,
  ace gesture) out of these 14 plus the library (challenge, battle_pose, punch_pose, hip, shout, scheme, summon_big).
  Original moves, not poses from the shows. TELL RAUL the Meshy total passed the 300 I first named (366).
- **LIVE PORTRAITS (Raul said yes, Nov 20 ~12:10):** `DuelBoard.live_portrait(p, px)` makes a SubViewport that shares
  the board's world, with a Camera3D that only sees render layer 10 (`PORTRAIT_LAYER`); the duelist figures are put on
  that layer too (`RoamFigure.show_on_layers`, `_apply_layers`, `ready_to_show`). The camera follows the Head bone
  softly (`_update_portrait`, framing in `PORTRAIT_FRAME`: [distance, lens, aim under the head, side] for you and for
  them) and has its own Environment (flat ambient light, so the face reads in any arena). `duel_scene._go_live()` (after
  both `add_duelists` calls) swaps each still for the live texture when the model is in: `hud.go_live(p, tex)` ->
  `DuelistPanel.go_live` (the TextureRect fills its clip strip; `live_size()` = strip x 2). `Settings.live_portraits`
  (Gameplay row "Live duelists in the corners"). Not in Turbo Duels, not for a figure with no model (the still stays).
  SEEN in a duel: stance, draw, Spell with the card in the hand, set, thinking, on both sides.
- Signature moves are in (`DuelBoard.SIGNATURE`, `STYLE_FACEOFF`, `STYLE_TAUNT`, moment "ace"); face-off and ace clips
  seen on the test body. fo_knuckles and ace_fist were too faint and are not used; back_off is not used (it walks off).
- Seen on screen so far: stances (5), win_a, kneel_down, shrug, scheme, hop, cheer_one, 8 face-off poses, 6 ace gestures,
  card in the hand (summon, Spell), turn beat, Trap look, the ending (winner, loser's answer; the pull back only a few
  frames of it), opening face-off with a signature pose. NOT seen: ace look, direct-attack look, hit sparks on the body,
  battle damage flying on, duelist_look head turns (too small to judge in pictures), Style choice in the profile editor,
  the new settings rows, tall/short/female bodies (the test models are stand-ins).

#### 0.63.0 notes of Nov 20, early afternoon (ship day)
- Raul: "I want it today. Like, as soon as you have it." Nothing is parked on a date; only what the voice limit blocks waits.
  He will keep sending requests; they go into the next build as they come.
- His report: a duelist named the wrong card (Zane, Kaiba's fusion). Cause: each character's "ace" line names their
  monster and played for ANY Level 7+ summon and for every Special Summon that was not Fusion/Synchro/Xyz/Ritual.
  Fix: `Characters.LINE_NEEDS` (34 lines -> the exact card name, a "Name*" family, "*text*", or "ace" = the speaker's
  own ace), `Characters.line(key, kind, card_id)` filters by it and falls back to the personality's lines;
  `duel_scene._talk/_call` take `about` (the card the line is about; attacks pass the attacker). Yugi's
  "Go, attack directly!" moved to kind "direct"; Jaden's fusion line moved to kind "fusion". A monster brought out
  by an effect is "ace" only when big (Level 7+, the speaker's ace, or one of PLAYER_CALLS), otherwise a "summon" call.
  Test: `godot --headless --path . res://tests/line_names.tscn` -> "LINE NAMES: PASS" (in /tmp/alltests.sh too).
  NOT changed: "ace_lost" lines still play for any Level 7+ destroyed (they say "my ace", no name).
- Live portraits: the portrait camera steps back when a hand is lifted or thrown out past the frame
  (`_pwide`, `PORTRAIT_WIDE_MAX` 1.5, in `_update_portrait`), seen in pictures. Talking: `hud.said` signal ->
  `board.duelist_mouth` -> `RoamFigure.mouth_for` (mouth shapes when the model has them, head nods always).
  The test stand-in models have 0 face parts, so the mouth itself was never seen moving.
- The turn's draw motion is guarded by turn number now (`_beat_drew`), not by the clock.
- Spanish redos done (33, batches 90-91), Spanish to-do 0, voices/es 1,529 files. English: batches 88-93 made
  (b89 and b93 partial), about 1,225 to go, parked in tools/voices/wip/en. Limit closed again about 12:50.
- Meshy 366 used / 171 left, told Raul (it passed the 300 named first). ElevenLabs about 63,900 of 131,000.
- **0.63.0 SHIPPED and installed on the Mac at about 1:10 PM Nov 20** (commit f1b614b; md5 of both zips checked on the
  Mac; `inst.sh 0.62.0` -> "mac identical", 0.63.0, "windows identical"). Only the exe changed on Windows.
  Tests at ship: failures 0, cards 8415 problems 0, positions 206 pass / 6 none, VOICE OVERLAP PASS, LINE NAMES PASS.
  A Zane duel on screen after the fix: 0 script errors, one draw motion per turn.
  Next: English voices (0.64.0) whenever the limit has room, plus whatever Raul asks for.
