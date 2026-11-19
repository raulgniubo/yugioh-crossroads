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
