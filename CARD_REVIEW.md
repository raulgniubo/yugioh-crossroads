# Card review

The rule: a card with an effect is in the game only when its rules match its printed text, sentence by sentence.
The list of cards that passed is `scripts/core/card_exact.gd`. Normal monsters are always in.

## Where it stands

- Effect monsters checked and exact: **181**
- Effect monsters waiting to be rebuilt: **79**
- Spells and Traps exact: **161**
- Spells and Traps waiting to be rebuilt: **14**

A card that is waiting is not in packs, shops, prizes or the deck builder, and the ready-made decks use a stand-in for it. It comes back by itself the day it is added to the exact list.

## Effect monsters waiting to be rebuilt

- Apprentice Magician
- Bazoo the Soul-Eater
- Black Luster Soldier - Envoy of the Beginning
- Blackwing - Sirocco the Dawn
- Breaker the Magical Warrior
- Cat Shark
- Cyber Angel Benten
- Cyber Angel Dakini
- Cyber Angel Idaten
- Cyber Barrier Dragon
- Cyber Blader
- Cyber Dragon Zwei
- Cyber Phoenix
- Cyber Valley
- Destiny HERO - Diamond Dude
- Destiny HERO - Disk Commander
- Destiny HERO - Doom Lord
- Destiny HERO - Malicious
- Dimensional Alchemist
- Dragon Piper
- Elemental HERO Rampart Blaster
- Elemental HERO Wildheart
- Exploder Dragonwing
- Freed the Brave Wanderer
- Gagaga Cowboy
- Galaxy Knight
- Galaxy Soldier
- Gernia
- Gilasaurus
- Harpie Channeler
- Harpie Queen
- Infernity Archfiend
- Infernity Guardian
- Insect Queen
- Kycoo the Ghost Destroyer
- Makyura the Destructor
- Max Warrior
- Medium Piece Golem
- Nitro Synchron
- Nitro Warrior
- Number 62: Galaxy-Eyes Prime Photon Dragon
- Pumpking the King of Ghosts
- Quillbolt Hedgehog
- Revival Jam
- Rose Tentacles
- Sinister Sprocket
- Skull Kraken
- Skull-Mark Ladybug
- Splendid Rose
- Starliege Paladynamo
- Stygian Street Patrol
- Submarineroid
- Toon Cannon Soldier
- Toon Dark Magician Girl
- Toon Gemini Elf
- Toon Goblin Attack Force
- Toon Masked Sorcerer
- Toon Mermaid
- Toon Summoned Skull
- Truckroid
- Twin-Sword Marauder
- Umbral Horror Ghost
- Umbral Horror Unform
- Umbral Horror Will o' the Wisp
- Vampire Lord
- Viser Des
- XYZ-Dragon Cannon
- Y-Dragon Head
- Z-Metal Tank
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
