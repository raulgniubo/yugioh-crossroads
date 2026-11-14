# Card review

The rule: a card with an effect is in the game only when its rules match its printed text, sentence by sentence.
The list of cards that passed is `scripts/core/card_exact.gd`. Normal monsters are always in.

## Where it stands

- Effect monsters checked and exact: **214**
- Effect monsters waiting to be rebuilt: **46**
- Spells and Traps exact: **162**
- Spells and Traps waiting to be rebuilt: **14**

A card that is waiting is not in packs, shops, prizes or the deck builder, and the ready-made decks use a stand-in for it. It comes back by itself the day it is added to the exact list.

## Effect monsters waiting to be rebuilt

- Apprentice Magician
- Blackwing - Sirocco the Dawn
- Cat Shark
- Cyber Barrier Dragon
- Cyber Blader
- Cyber Dragon Zwei
- Cyber Phoenix
- Cyber Valley
- Destiny HERO - Diamond Dude
- Dimensional Alchemist
- Dragon Piper
- Elemental HERO Rampart Blaster
- Elemental HERO Wildheart
- Exploder Dragonwing
- Gagaga Cowboy
- Gernia
- Infernity Archfiend
- Infernity Guardian
- Kycoo the Ghost Destroyer
- Makyura the Destructor
- Medium Piece Golem
- Nitro Warrior
- Number 62: Galaxy-Eyes Prime Photon Dragon
- Pumpking the King of Ghosts
- Rose Tentacles
- Skull Kraken
- Skull-Mark Ladybug
- Splendid Rose
- Starliege Paladynamo
- Submarineroid
- Truckroid
- Umbral Horror Ghost
- Umbral Horror Unform
- Umbral Horror Will o' the Wisp
- Vampire Lord
- Viser Des
- Barrier Resonator
- Blackwing - Vayu the Emblem of Honor
- Dark Necrofear
- Jetroid
- Number 43: Manipulator of Souls
- Number 65: Djinn Buster
- Patroid
- Phoenixian Seed
- Saber Shark
- T.G. Blade Blaster

## Spells and Traps waiting to be rebuilt

- Assault Armor
- Breakthrough Skill
- Cursed Seal of the Forbidden Spell
- De-Fusion
- De-Spell
- Forbidden Lance
- Harpies' Hunting Ground
- Heart of Clear Water
- Necrovalley
- Nightmare's Steelcage
- Ring of Magnetism
- Soul Exchange
- Spark Blaster
- Spell Shield Type-8

## How a card gets on the exact list

1. Its printed text is read next to its rules (`work/cmp.py NAME`).
2. Every sentence gets the same trigger, cost and result in the rules.
3. It gets a test in `tests/test_runner.gd` when it has a new mechanic, and it must show in the card drill (`tools/card_drill.gd`).
