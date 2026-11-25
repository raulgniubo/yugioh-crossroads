# New show duelists: plan

**0.80.0 (Nov 25): DONE for 15 of them** (mako, jesse, hassleberry, atticus, yubel, leo5ds, luna, trudge, sherry,
goodwin, halldor, dragan, broder, bronk, tori): decks, lines, voices, worlds, Academy, Free Duel, shops. They use stand-in
bodies until Raul's `characters/<key>.glb` files are in. Still open from this list: ishizu, keith, duke, rafael, quattro, mizar.

Raul makes the models. Files go in his `characters` folder, lowercase, no underscore in the key
(an underscore means an animation clip: `jesse_idle.glb`). Leo of 5D's is `leo5ds` (`leo` = Leo Brasa
of the Academy); Rex Goodwin is `goodwin` (`rex` = Rex Raptor).

| Era | Key | Name |
|---|---|---|
| DM | ishizu, mako, keith, duke, rafael | Ishizu Ishtar, Mako Tsunami, Bandit Keith, Duke Devlin, Rafael |
| GX | jesse, hassleberry, atticus, yubel | Jesse Anderson, Tyranno Hassleberry, Atticus Rhodes, Yubel |
| 5D's | luna, leo5ds, trudge, sherry, goodwin | Luna, Leo, Trudge, Sherry LeBlanc, Rex Goodwin |
| 5D's (Team Ragnarok, Raul's idea Nov 25) | halldor, dragan, broder | Halldor (Odin), Dragan (Thor), Broder (Loki): Nordic / Aesir decks |
| ZEXAL | quattro, mizar, tori, bronk | Quattro (IV), Mizar, Tori, Bronk |

First wave suggested: ishizu, jesse, luna, trudge, goodwin, quattro, mizar, bronk.

Per duelist, once the model is in:
1. Characters entry (name, short, era, color, title, personality, deck key, ace) + ORDER.
2. Decks: competitive deck + two anime decks (DeckTiers.ANIME), real cards of the show, playable.
3. Lines: intro, rematch, ace (Characters lines), Spanish in extras.tsv; voice = their personality voice
   (no new voice design unless Raul wants one for a big one). ~10-20 lines a language.
4. Unlock rule, Free Duel tile, worlds (roam), the online anime-only list picks them up by itself.
5. Optional: a Legendary Duel for them.
