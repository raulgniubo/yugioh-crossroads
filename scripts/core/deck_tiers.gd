class_name DeckTiers
## Deck strength (0.52.0). Every deck has three versions:
##   Full      the deck as written (4-5 star duelists, story bosses).
##   Standard  the same deck without the strongest generic staples, swapped one for one for plain
##             ones, and without generic Extra Deck power cards (3 star duelists, mid story).
##   Starter   a simple deck: the deck's own small monsters, one or two of its bigger ones, plain
##             Normal Monsters that fit it, one copy each of a few of its own Spells and Traps, and
##             basic cards to make forty (1-2 star duelists, early story).
## A version is asked for by key: "deck_dragunity@starter", "kaiba@standard". CardData builds the
## Full list first and passes it through here, so the versions follow the deck when it changes.
## Named characters always play their own deck as it is in Free Roam and Free Duel; Story picks a
## version per duel (StoryDirector) and the story difficulty moves it (Hard one step up, Extreme two).

const VERSIONS := ["starter", "standard", "full"]
## (0.77.0) The characters of the show also have their decks from the show: "anime1" from early on,
## "anime2" from later (Free Duel offers these and the full one instead of Basic and Strong).
const ANIME_VERSIONS := ["anime1", "anime2"]
const ANIME := {
	"akiza": ["anime_akiza_1", "anime_akiza_2"],
	"alexis": ["anime_alexis_1", "anime_alexis_2"],
	"aster": ["anime_aster_1", "anime_aster_2"],
	"bakura": ["anime_bakura_1", "anime_bakura_2"],
	"chazz": ["legend_chazz_y1", "anime_chazz_2"],
	"crow": ["anime_crow_1", "anime_crow_2"],
	"deck_ancient_gear": ["anime_crowler_1", "anime_crowler_2"],
	"deck_cyber": ["anime_sheppard_1", ""],
	"deck_water": ["anime_bastion_1", ""],
	"jack": ["legend_jack_s1", "anime_jack_2"],
	"jaden": ["legend_jaden_y1", "anime_jaden_2"],
	"joey": ["anime_joey_1", "anime_joey_2"],
	"kaiba": ["legend_kaiba_dk", "anime_kaiba_2"],
	"kalin": ["anime_kalin_1", "anime_kalin_2"],
	"kite": ["anime_kite_1", "anime_kite_2"],
	"mai": ["anime_mai_1", "anime_mai_2"],
	"marik": ["anime_marik_1", "anime_marik_2"],
	"pegasus": ["anime_pegasus_1", "anime_pegasus_2"],
	"rex": ["anime_rex_1", "anime_rex_2"],
	"shark": ["legend_shark_early", "anime_shark_2"],
	"syrus": ["anime_syrus_1", "anime_syrus_2"],
	"vector": ["anime_vector_1", ""],
	"weevil": ["anime_weevil_1", "anime_weevil_2"],
	"yugi": ["legend_yugi_dk", "anime_yugi_2"],
	"yuma": ["legend_yuma_early", "anime_yuma_2"],
	"yusei": ["legend_yusei_s1", "anime_yusei_2"],
	"zane": ["anime_zane_1", "anime_zane_2"],
}


## The strongest generic staples: a Standard deck plays without them.
const TOP := ["Solemn Judgment", "Solemn Warning", "Solemn Strike", "Mirror Force", "Dark Hole", "Raigeki", "Heavy Storm",
	"Torrential Tribute", "Dimensional Prison", "Bottomless Trap Hole", "Compulsory Evacuation Device", "Fiendish Chain",
	"Gold Sarcophagus", "Pot of Greed", "Graceful Charity", "Pot of Duality", "Maxx \"C\"", "Twin Twisters", "Cosmic Cyclone",
	"Phoenix Wing Wind Blast", "Book of Eclipse", "Black Horn of Heaven", "Royal Decree", "Crush Card Virus", "Skill Drain",
	"Soul Charge", "Swords of Concealing Light", "Card of Safe Return", "Debunk", "Trap Dustshoot", "Creature Swap",
	"D.D. Crow", "Necro Gardna", "Gorz the Emissary of Darkness", "Effect Veiler", "Change of Heart", "Harpie's Feather Duster",
	"Ring of Destruction", "Magic Jammer", "Seven Tools of the Bandit", "Imperial Order", "Premature Burial"]
## What takes their place (2 copies each at most).
const MID := ["Trap Hole", "Sakuretsu Armor", "Negate Attack", "Magic Cylinder", "Waboku", "Threatening Roar",
	"Enchanted Javelin", "Fissure", "Hammer Shot", "Dust Tornado", "Mirror Wall"]
## Cards any deck can play: never counted as a deck's own when a Starter is built.
const GENERIC := ["Mystical Space Typhoon", "Monster Reborn", "Call of the Haunted", "Book of Moon", "Terraforming",
	"Foolish Burial", "Reinforcement of the Army", "Upstart Goblin", "Swords of Revealing Light", "Scapegoat", "Pot of Avarice",
	"Salvage", "Limiter Removal", "Double Summon", "Card Destruction", "Enemy Controller", "Shrink", "Monster Reincarnation",
	"Giant Trunade", "Smashing Ground", "Lightning Vortex", "Card of Sanctity", "Rush Recklessly", "Dian Keto the Cure Master",
	"Stop Defense", "Remove Trap", "Hinotama", "Red Medicine", "Ookazi", "Trap Jammer", "Draining Shield", "Spellbinding Circle",
	"Sangan", "Kuriboh", "Morphing Jar", "Tour Guide From the Underworld", "Mage Power", "Megamorph", "Axe of Despair",
	"Malevolent Nuzzler", "Big Bang Shot", "Widespread Ruin", "Machine Duplication", "Dark Bribe", "Ceasefire", "Just Desserts"]
## Extra Deck monsters any deck can make: a Standard deck plays without them.
const GENERIC_EXTRA := ["Castel, the Skyblaster Musketeer", "Diamond Dire Wolf", "Abyss Dweller", "Stardust Dragon", "Scrap Dragon",
	"Black Rose Dragon", "Colossal Fighter", "Formula Synchron", "Starliege Paladynamo", "Daigusto Emeral", "Lavalval Chain",
	"Leviair the Sea Dragon", "Number 61: Volcasaurus", "Number 30: Acid Golem of Destruction", "Red Dragon Archfiend",
	"Road Warrior", "Power Tool Dragon", "Arcanite Magician", "Explosive Magician", "Shooting Star Dragon", "T.G. Hyper Librarian",
	"Gagaga Cowboy", "Evolzar Laggia", "Number 39: Utopia", "Number 17: Leviathan Dragon", "Thousand-Eyes Restrict",
	"Gaia Knight, the Force of Earth", "Ally of Justice Catastor", "Goyo Guardian", "Brionac, Dragon of the Ice Barrier",
	"Trishula, Dragon of the Ice Barrier", "Number 101: Silent Honor ARK", "Number 50: Blackship of Corn"]
## Plain Normal Monsters a Starter deck fills up with: the ones that share the deck's Type first,
## then its Attribute, then any.
const NORMALS := ["Dark Blade", "Neo the Magic Swordsman", "Dunames Dark Witch", "Axe Raider", "Battle Ox", "Warrior Dai Grepher",
	"Beta The Magnet Warrior", "Wolf Axwielder", "Crawling Dragon #2", "Beautiful Headhuntress", "Opticlops", "Ryu-Kishin Powered",
	"Mechanicalchaser", "La Jinn the Mystical Genie of the Lamp", "Hunter Dragon", "Maiden of the Moonlight", "Rogue Doll",
	"Queen's Knight", "Shining Abyss", "Guardian of the Throne Room", "7 Colored Fish", "Giant Red Seasnake", "Kabazauls",
	"Mad Lobster", "Great White", "Skull Mariner", "Gagagigo", "Sky Scout", "Sonic Duck", "Faith Bird", "Skull Red Bird",
	"Blue-Winged Crown", "Blazing Inpachi", "Great Angus", "Darkfire Soldier #1", "Fire Kraken", "Robotic Knight", "Fireyarou"]
## The basic cards a Starter deck makes forty with, in the order they go in.
const BASICS := ["Trap Hole", "Rush Recklessly", "Waboku", "Hammer Shot", "Negate Attack", "Dian Keto the Cure Master",
	"Sakuretsu Armor", "Fissure", "Enchanted Javelin", "Stop Defense", "Threatening Roar", "Hinotama", "Magic Cylinder",
	"Remove Trap", "Mirror Wall", "Red Medicine", "Dust Tornado", "Ookazi", "Trap Jammer"]


## "deck_x@starter" -> ["deck_x", "starter"]; a plain key -> [key, "full"].
static func split(key: String) -> Array:
	var at := key.find("@")
	if at < 0:
		return [key, "full"]
	var v := key.substr(at + 1)
	return [key.substr(0, at), v if (v in VERSIONS or v in ANIME_VERSIONS) else "full"]


## The deck behind an anime version ("" when this deck has none).
static func anime_key(base: String, version: String) -> String:
	if not ANIME.has(base) or not version in ANIME_VERSIONS:
		return ""
	return str(ANIME[base][ANIME_VERSIONS.find(version)])


## The versions a deck is offered in: the show's decks and the full one when it has them, else the three.
static func versions_of(base: String) -> Array:
	if not ANIME.has(base):
		return VERSIONS
	var out: Array = []
	for i in 2:
		if str(ANIME[base][i]) != "":
			out.append(ANIME_VERSIONS[i])
	out.append("full")
	return out


static func with_version(key: String, version: String) -> String:
	var base: String = split(key)[0]
	return base if version == "full" or version == "" else base + "@" + version


## The version of a deck that fits a duelist with this many stars: 1-2 Starter, 3 Standard,
## 4-5 Full. The decks of named characters, and the decks you start with, are always played whole.
static func for_stars(key: String, stars: int, who := "") -> String:
	if key.begins_with("slot:") or key == "custom" or key.begins_with("starter_") or CardData.DECKS.has(key):
		return key
	if who != "" and SignatureDecks.owner(key) == who:
		return key
	return with_version(key, "starter" if stars <= 2 else ("standard" if stars == 3 else "full"))


## for_stars for a duel against `who`: the show's characters always play their own deck whole.
static func for_duel(key: String, who: String, stars: int) -> String:
	if Unlocks.SERIES_STARS.has(who):
		return key
	return for_stars(key, stars, who)


## One step up or down the ladder (story difficulty).
static func shift(version: String, steps: int) -> String:
	var i: int = VERSIONS.find(version)
	if i < 0:
		i = 2
	return VERSIONS[clampi(i + steps, 0, 2)]


static func _id(n: String) -> int:
	var id: int = int(CardData.NAME_TO_ID.get(n.to_lower(), 0))
	if id == 0 or not CardPool.has(id):
		return 0
	return id


static func _ids(names: Array) -> Dictionary:
	var out := {}
	for n in names:
		var id := _id(str(n))
		if id != 0:
			out[id] = true
	return out


static func _is_normal(c: Dictionary) -> bool:
	return str(c.get("frame", "")) == "normal"


## The Main Deck of a version, from the Full list.
static func main(full: Array[int], version: String) -> Array[int]:
	if version == "standard":
		return _standard(full)
	if version == "starter":
		return _starter(full)
	return full


static func extra(full: Array[int], version: String) -> Array[int]:
	if version == "full" or full.is_empty():
		return full
	var gen := _ids(GENERIC_EXTRA)
	var out: Array[int] = []
	var order: Array[int] = full.duplicate()
	if version == "starter":
		# A Starter brings its weaker Extra Deck monsters, not its best.
		order.sort_custom(func(a, b): return int(CardData.get_card(a).get("atk", 0)) < int(CardData.get_card(b).get("atk", 0)))
	for id in order:
		if gen.has(id):
			continue
		if version == "starter":
			if out.has(id) or out.size() >= 3:
				continue
		out.append(id)
	return out


static func _standard(full: Array[int]) -> Array[int]:
	var top := _ids(TOP)
	var generic := _ids(GENERIC + TOP + MID + BASICS)
	var out: Array[int] = []
	var gone_st := 0
	var gone_mon := 0
	var seen := {}
	for id in full:
		if top.has(id):
			gone_st += 1
			continue
		# Its own cards it plays three of, it plays two of: a mid deck draws them less often.
		seen[id] = int(seen.get(id, 0)) + 1
		if int(seen[id]) == 3 and not generic.has(id):
			if CardData.get_card(id)["kind"] == "monster":
				gone_mon += 1
			else:
				gone_st += 1
			continue
		out.append(id)
	var lean := _lean(out, generic)
	for nid in _normals(out, str(lean[0]), str(lean[1])):
		if gone_mon <= 0:
			break
		for k in 2:
			if gone_mon > 0:
				out.append(nid)
				gone_mon -= 1
	gone_st += gone_mon
	var k2 := 0
	var guard := 0
	while gone_st > 0 and guard < 200:
		guard += 1
		var id2 := _id(str(MID[k2 % MID.size()]))
		k2 += 1
		if id2 != 0 and out.count(id2) < 2:
			out.append(id2)
			gone_st -= 1
	return out


## The Type and Attribute most of a deck's own monsters share.
static func _lean(list: Array[int], generic: Dictionary) -> Array:
	var races := {}
	var attrs := {}
	for id in list:
		if generic.has(id):
			continue
		var c := CardData.get_card(id)
		if c["kind"] == "monster":
			races[str(c.get("race", ""))] = int(races.get(str(c.get("race", "")), 0)) + 1
			attrs[str(c.get("attribute", ""))] = int(attrs.get(str(c.get("attribute", "")), 0)) + 1
	return [_top(races), _top(attrs)]


## Plain Normal Monsters not in `have`: the deck's Type first, then its Attribute, then any.
static func _normals(have: Array[int], race: String, attr: String) -> Array[int]:
	var pool: Array[int] = []
	for pass_i in 3:
		for n in NORMALS:
			var nid := _id(str(n))
			if nid == 0 or pool.has(nid) or have.has(nid):
				continue
			var c2 := CardData.get_card(nid)
			if pass_i == 0 and str(c2.get("race", "")) != race:
				continue
			if pass_i == 1 and str(c2.get("attribute", "")) != attr:
				continue
			pool.append(nid)
	return pool


static func _starter(full: Array[int]) -> Array[int]:
	var generic := _ids(GENERIC + TOP + MID + BASICS)
	var counts := {}
	var order: Array[int] = []
	for id in full:
		if not counts.has(id):
			order.append(id)
		counts[id] = int(counts.get(id, 0)) + 1
	var small: Array[int] = []
	var mid_lv: Array[int] = []
	var big: Array[int] = []
	var own_st: Array[int] = []
	for id in order:
		if generic.has(id):
			continue
		var c := CardData.get_card(id)
		if c["kind"] == "monster":
			var lv := int(c.get("level", 4))
			if lv <= 4:
				small.append(id)
			elif lv <= 6:
				mid_lv.append(id)
			else:
				big.append(id)
		else:
			own_st.append(id)
	# Most-played first, then the strongest.
	small.sort_custom(func(a, b): return counts[a] > counts[b] if counts[a] != counts[b] else int(CardData.get_card(a).get("atk", 0)) > int(CardData.get_card(b).get("atk", 0)))
	big.sort_custom(func(a, b): return counts[a] > counts[b])
	var out: Array[int] = []
	for id in small:
		if out.size() >= 14:
			break
		for k in mini(2, int(counts[id])):
			out.append(id)
	# A deck of nothing but big monsters (Gate Guardian) keeps a few more of them.
	var n_mid := 2 if small.size() >= 5 else 4
	for id in mid_lv.slice(0, n_mid):
		out.append(id)
	for id in big.slice(0, 1 if small.size() >= 5 else 2):
		out.append(id)
	# Plain monsters that fit the deck, to about 18 monsters.
	var lean := _lean(full, generic)
	var pool := _normals(out, str(lean[0]), str(lean[1]))
	for nid in pool:
		if out.size() >= 18:
			break
		out.append(nid)
		if out.size() < 18:
			out.append(nid)
	for id in own_st.slice(0, 6):
		out.append(id)
	var k := 0
	var guard := 0
	while out.size() < CardData.MIN_DECK and guard < 400:
		guard += 1
		var bid := _id(str(BASICS[k % BASICS.size()]))
		k += 1
		if bid != 0 and out.count(bid) < 2:
			out.append(bid)
	while out.size() > CardData.MIN_DECK:
		out.pop_back()
	return out


static func _top(tally: Dictionary) -> String:
	var best := ""
	var n := -1
	for k in tally:
		if int(tally[k]) > n:
			n = int(tally[k])
			best = str(k)
	return best
