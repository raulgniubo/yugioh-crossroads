class_name SummonShow
extends CanvasLayer
## The arrival of a big monster. Each signature card has its own colors and its own figure in
## the air (a magic circle, lightning, flames, a galaxy...) and every other strong monster gets
## one by attribute. The picture in the middle is the card's own art, from your card folder.
## It is drawn here with lines and light: no monster models.

## name -> [color A, color B, figure, line under the name, the name of its attack]
const SIGNATURE := {
	"Lumen, Echo Spirit": ["7fe8ff", "ffd76a", "cards", "Your partner", "Echo Flash"],
	"Lumen, Echo Chorus": ["ff8fd6", "6fd0ff", "circle", "Two voices, one song", "Chorus Wave"],
	"Lumen, Echo Comet": ["3fd8ff", "ffffff", "lightning", "Faster than the echo", "Comet Dive"],
	"Lumen, Echo Zenith": ["8a6bff", "ffd76a", "circle", "The sky, listening", "Zenith Orbit"],
	"Lumen, Echo Radiant": ["ffc23d", "fff6d6", "flames", "Every echo at once", "Radiant Answer"],
	"Lumen, Echo Aurora": ["4dffb0", "9a6bff", "aurora", "The first light after the longest night", "Aurora Veil"],
	"Lumen, Echo Nova": ["ffe9a8", "5a9eff", "nova", "Every road, one light", "Nova Crossing"],
	"Echo Sentinel": ["9fd8ff", "ffd766", "hex", "Nothing reaches her", "Echo Guard"],
	"Dark Magician": ["8a4dff", "ff7ad9", "circle", "The ultimate wizard", "Dark Magic Attack"],
	"Dark Magician Girl": ["ff7ad9", "7cc4ff", "circle", "Apprentice of the dark arts", "Dark Burning Attack"],
	"Blue-Eyes White Dragon": ["bfe6ff", "3a7bff", "lightning", "Engine of destruction", "White Lightning"],
	"Blue-Eyes Ultimate Dragon": ["ffffff", "3a7bff", "wings", "Three heads, one roar", "Neutron Blast"],
	"Red-Eyes Black Dragon": ["ff3a2a", "2a0a0a", "flames", "The dragon of potential", "Inferno Fire Blast"],
	"Red-Eyes Darkness Dragon": ["ff3a2a", "5a0a2a", "flames", "Darkness given wings", "Inferno Dark Fire"],
	"Summoned Skull": ["b06bff", "ffe36a", "lightning", "Lightning from the underworld", "Lightning Strike"],
	"Black Luster Soldier": ["ffd76a", "3a5fd9", "slash", "The chaos soldier", "Chaos Blade"],
	"Elemental HERO Neos": ["ffffff", "5affd0", "stars", "A hero from deep space", "Wrath of Neos"],
	"Elemental HERO Flame Wingman": ["5aff8a", "ff5a3c", "flames", "Hero of the skyfire", "Skydive Scorcher"],
	"Cyber Dragon": ["d8e6ff", "5a8aff", "gears", "The machine serpent", "Strident Blast"],
	"Cyber End Dragon": ["d8e6ff", "5a8aff", "gears", "Three engines, no brakes", "Super Strident Blaze"],
	"Armed Dragon LV7": ["ff8a3a", "5a2a0a", "flames", "It only gets bigger", "Dragon Talon Terror"],
	"Stardust Dragon": ["e8fbff", "5ad0ff", "stars", "The road of light", "Cosmic Flare"],
	"Junk Warrior": ["ff8a3a", "5a8aff", "gears", "Built from what was thrown away", "Scrap Fist"],
	"Red Dragon Archfiend": ["ff2a2a", "ffb03a", "wings", "The king's soul", "Scorching Crimson Flare"],
	"Black Rose Dragon": ["d9345a", "3a0a1a", "bloom", "A garden of thorns", "Black Rose Flare"],
	"Blackwing Armor Master": ["3a3a4a", "9a7aff", "feathers", "Black wings at full speed", "Black Hurricane"],
	"Number 39: Utopia": ["ffd76a", "ffffff", "slash", "The king of wishes", "Rising Sun Slash"],
	"Galaxy-Eyes Photon Dragon": ["7ab0ff", "b06bff", "galaxy", "A galaxy in its eyes", "Photon Stream of Destruction"],
	"Number 17: Leviathan Dragon": ["3a8aff", "0a2a5a", "waves", "From the deepest water", "Vice Stream"],
	# (0.83.0) More of the aces the duelists of the four eras are known for: their own colors, figure
	# and line, and the name of their attack where the show gives it one ("" where it does not).
	"Slifer the Sky Dragon": ["ff3a3a", "ffd76a", "storm", "The sky answers to it", "Thunder Force"],
	"Obelisk the Tormentor": ["3a6bff", "ffd76a", "runes", "The fist of a god", "Fist of Fate"],
	"The Winged Dragon of Ra": ["ffd23a", "ff7a2a", "flames", "The sun itself", "Blaze Cannon"],
	"Dark Paladin": ["6a4dff", "3ad0ff", "circle", "Sword and spell as one", ""],
	"Dark Magician of Chaos": ["8a4dff", "ff3a6a", "circle", "Magic from beyond the end", "Scepter Strike"],
	"Buster Blader": ["c9d4ff", "ffd76a", "slash", "The dragon slayer", ""],
	"Jinzo": ["5aff9a", "2a3a2a", "gears", "No trap survives it", "Cyber Energy Shock"],
	"Gaia the Dragon Champion": ["c9a0ff", "ff5a3c", "lightning", "Knight and dragon, one charge", ""],
	"Thousand-Eyes Restrict": ["b06bff", "ffd76a", "circle", "It sees everything you have", ""],
	"Harpie's Pet Dragon": ["ff5a8a", "ffb03a", "wings", "Loyal to its ladies", "Fearsome Fire Blast"],
	"Elemental HERO Shining Flare Wingman": ["ffffff", "5aff8a", "rays", "A hero wrapped in light", "Solar Flare"],
	"Rainbow Dragon": ["ffffff", "ff7ad9", "stars", "Seven gems, one dragon", "Rainbow Refraction"],
	"Yubel": ["9a4dff", "ff5a3c", "bloom", "What hurts her hurts you", ""],
	"Ancient Gear Golem": ["c9a76a", "5a8aff", "gears", "Older than any trap", "Mechanized Melee"],
	"Cyber Blader": ["7cc4ff", "ff7ad9", "stars", "Grace on a blade's edge", ""],
	"Destiny HERO - Plasma": ["d9345a", "3a0a1a", "feathers", "The last hero of destiny", "Bloody Fears"],
	"Ancient Fairy Dragon": ["7dffb0", "ffe9a8", "bloom", "Guardian of the spirit world", "Eternal Sunshine"],
	"Power Tool Dragon": ["ffd23a", "5a8aff", "gears", "Any tool for any job", "Crafty Break"],
	"Black-Winged Dragon": ["3a3a4a", "ff3a3a", "wings", "It carries the pain for you", "Noble Stream"],
	"Shooting Star Dragon": ["e8fbff", "ffd76a", "stars", "Faster than light itself", "Stardust Mirage"],
	"Red Nova Dragon": ["ff2a2a", "ffd23a", "flames", "A soul that burns twice", "Burning Soul"],
	"Life Stream Dragon": ["ffb03a", "5ad0ff", "rays", "Life, given back", "Life is Beauty Howl"],
	"Goyo Guardian": ["c9a76a", "ff5a3c", "hex", "You are under arrest", "Goyo Lariat"],
	"Number C39: Utopia Ray": ["ffd76a", "3a3aff", "photon", "Hope, past its limit", "Rising Sun Chaos Slash"],
	"Neo Galaxy-Eyes Photon Dragon": ["7ab0ff", "ff5a8a", "photon", "A galaxy that learned to hate", "Ultimate Photon Stream"],
	"Number 32: Shark Drake": ["3a8aff", "ff3a3a", "waves", "The sea remembers", "Depth Bite"],
	"Number 107: Galaxy-Eyes Tachyon Dragon": ["ffd23a", "8a4dff", "galaxy", "Time bends when it roars", "Tachyon Spiral of Destruction"],
	# (0.84.0) Two of the best known of each duelist: 87 more.
	"Quintet Magician": ["8a4dff", "ffd76a", "circle", "Five magicians, one spell", ""],
	"Master of Chaos": ["3a3aff", "ffd76a", "slash", "Where light and dark meet", ""],
	"Toon Black Luster Soldier": ["ffd76a", "ff5ad0", "stars", "Straight out of the cartoon", ""],
	"Blue-Eyes Toon Dragon": ["bfe6ff", "ff7ad9", "stars", "It laughs before it bites", ""],
	"Meteor Black Comet Dragon": ["ff3a2a", "ffb03a", "flames", "A comet with red eyes", ""],
	"Black Skull Dragon": ["ff3a2a", "b06bff", "wings", "Dragon and fiend, one skull", "Molten Fireball"],
	"Ultra Beetrooper Absolute Hercules": ["7dff6a", "c9a76a", "hex", "The swarm has a king", ""],
	"Metamorphosed Insect Queen": ["9aff5a", "ff5a8a", "hex", "Her brood eats first", ""],
	"Neo Blue-Eyes Ultimate Dragon": ["ffffff", "3a7bff", "wings", "Three heads, reborn", ""],
	"Blue-Eyes Tyrant Dragon": ["bfe6ff", "ff5a3c", "wings", "Nothing stops its fire", ""],
	"Ultimate Conductor Tyranno": ["ffe36a", "ff7a2a", "storm", "The king of the storm age", ""],
	"Super Conductor Tyranno": ["ffe36a", "5a8aff", "lightning", "Charged since the Jurassic", ""],
	"Harpie's Pet Phantasmal Dragon": ["ff5a8a", "9a7aff", "feathers", "It answers only to the Harpies", ""],
	"Dark Necrofear": ["b06bff", "3a0a4a", "runes", "Three fiends buried for her", ""],
	"Curse Necrofear": ["8a4dff", "ff3a6a", "runes", "Her curse comes back for you", ""],
	"Number 22: Zombiestein": ["7dff6a", "3a0a4a", "lightning", "Stitched together to hit hard", ""],
	"The Winged Dragon of Ra - Immortal Phoenix": ["ffd23a", "ff3a2a", "flames", "It will not stay dead", ""],
	"Lava Golem": ["ff5a1a", "5a1a0a", "flames", "A gift nobody wants", ""],
	"Egyptian God Slime": ["5ad0ff", "ffd23a", "waves", "A god's worth of slime", ""],
	"Mermail Abyssgaios": ["3a8aff", "ffd76a", "waves", "The deep has an emperor", ""],
	"The Legendary Fisherman III": ["5ad0ff", "ffffff", "waves", "The sea keeps its legends", ""],
	"Armed Dragon LV10": ["ff8a3a", "5a2a0a", "slash", "Every level sharper", ""],
	"Light and Darkness Dragon": ["ffffff", "3a3a4a", "wings", "Both sides of one dragon", ""],
	"Cyber Angel Vrash": ["ff7ad9", "ffe9a8", "rays", "The last dance of the angels", ""],
	"Cyber Angel Dakini": ["7cc4ff", "ff7ad9", "slash", "Four arms, four blades", ""],
	"Red-Eyes Dark Dragoon": ["8a4dff", "ff3a2a", "circle", "Magician and dragon as one", ""],
	"Red-Eyes Darkness Metal Dragon": ["ff3a2a", "6a6a7a", "wings", "Darkness in steel", ""],
	"Barbaroid, the Ultimate Battle Machine": ["ffb03a", "5a8aff", "gears", "Every Vehicroid at once", ""],
	"Super Vehicroid - Stealth Union": ["5a8aff", "c9d4ff", "gears", "Four machines, one stealth", ""],
	"Destiny End Dragoon": ["d9345a", "5a8aff", "wings", "Destiny ends here", ""],
	"Destiny HERO - Dystopia": ["b06bff", "d9345a", "slash", "A future with no way out", ""],
	"Elemental HERO The Shining": ["ffffff", "ffd76a", "rays", "The light of every hero", ""],
	"Elemental HERO Nova Master": ["ff5a3c", "ffb03a", "flames", "A hero born of fire", ""],
	"Elemental HERO Great Tornado": ["5aff8a", "d8ffe0", "storm", "A hero born of the storm", ""],
	"Cyber Twin Dragon": ["d8e6ff", "5a8aff", "gears", "Two heads, two strikes", ""],
	"Cyber Dragon Infinity": ["d8e6ff", "8a6bff", "photon", "It grows with everything it takes", ""],
	"Cyberdark End Dragon": ["6a6a7a", "b06bff", "gears", "The end of the dark style", ""],
	"Chaos Ancient Gear Giant": ["c9a76a", "b06bff", "gears", "The oldest machine, unchained", ""],
	"Ultimate Ancient Gear Golem": ["c9a76a", "ff5a3c", "gears", "It was built to end duels", ""],
	"Rainbow Overdragon": ["ffffff", "7dffb0", "stars", "Beyond the rainbow", ""],
	"Rainbow Dark Dragon": ["6a6a7a", "b06bff", "stars", "A rainbow with no light", ""],
	"Yubel - The Ultimate Nightmare": ["9a4dff", "ff3a2a", "bloom", "Her love, in its final form", ""],
	"Yubel - Terror Incarnate": ["9a4dff", "ff5a3c", "wings", "She has only begun", ""],
	"Ultimate Tyranno": ["c9a76a", "ff5a3c", "slash", "It attacks everything it sees", ""],
	"Shooting Quasar Dragon": ["ffffff", "ffd76a", "wings", "Five stars become one", "The Creation Burst"],
	"Cosmic Blazar Dragon": ["7ab0ff", "ffffff", "galaxy", "It vanishes, and so does your move", ""],
	"Stardust Warrior": ["e8fbff", "5ad0ff", "slash", "Stardust, with a fist", ""],
	"Red Supernova Dragon": ["ff2a2a", "ffd23a", "flames", "A star that dies shouting", ""],
	"Scarlight Red Dragon Archfiend": ["ff2a2a", "ffb03a", "wings", "The king, scarred and burning", ""],
	"Tyrant Red Dragon Archfiend": ["ff2a2a", "5a0a0a", "flames", "The king's rage, absolute", ""],
	"Black-Winged Assault Dragon": ["6a6a7a", "ff3a3a", "wings", "Black wings, sharper", ""],
	"Blackwing Full Armor Master": ["6a6a7a", "9a7aff", "feathers", "Nothing gets through the armor", ""],
	"Ruddy Rose Dragon": ["d9345a", "ff7a2a", "bloom", "A rose that burns the garden", ""],
	"Black Rose Moonlight Dragon": ["d9345a", "c9d4ff", "bloom", "Thorns under the moon", ""],
	"Tytannial, Princess of Camellias": ["ff5a8a", "7dffb0", "bloom", "The garden bows to her", ""],
	"Sun Dragon Inti": ["ffd23a", "ff5a3c", "rays", "The sun never forgives", ""],
	"Moon Dragon Quilla": ["c9d4ff", "5a5aff", "galaxy", "The moon takes half", ""],
	"Earthbound Immortal Ccarayhua": ["5aff8a", "3a0a4a", "runes", "A line drawn in the earth", ""],
	"Earthbound Immortal Wiraqocha Rasca": ["b06bff", "ffd23a", "runes", "The condor takes all but one", ""],
	"Number C104: Umbral Horror Masquerade": ["b06bff", "ff3a6a", "photon", "Behind the mask, nothing kind", ""],
	"Number 104: Masquerade": ["ffe9a8", "b06bff", "photon", "The show starts with your loss", ""],
	"Power Tool Braver Dragon": ["ffd23a", "ff5a3c", "gears", "Braver with every tool", ""],
	"Goyo Emperor": ["c9a76a", "ffd76a", "hex", "Everything you own is under arrest", ""],
	"Goyo King": ["c9a76a", "ff5a3c", "hex", "The law, crowned", ""],
	"Baronne de Fleur": ["7dffb0", "ffffff", "slash", "A blade among the flowers", ""],
	"Chevalier de Fleur": ["ffffff", "ff7ad9", "bloom", "The knight of the lily", ""],
	"Odin, Father of the Aesir": ["ffe9a8", "5a8aff", "runes", "The father of the gods", ""],
	"Thor, Lord of the Aesir": ["ffd23a", "5a8aff", "storm", "Thunder has a lord", ""],
	"Loki, Lord of the Aesir": ["b06bff", "5aff8a", "runes", "The trick is already played", ""],
	"Fenrir the Nordic Wolf": ["8a8aa0", "ff3a3a", "storm", "The wolf that ends the world", ""],
	"Jormungardr the Nordic Serpent": ["5aff8a", "3a0a4a", "waves", "It circles the whole world", ""],
	"Void Ogre Dragon": ["6a6a7a", "ff3a2a", "wings", "Empty hand, full fury", ""],
	"Hundred Eyes Dragon": ["b06bff", "ffd23a", "circle", "A hundred eyes, all on you", ""],
	"Infernity Doom Dragon": ["ff3a2a", "5a0a1a", "flames", "Doom from an empty hand", ""],
	"Number 99: Utopic Dragon": ["ffd76a", "ffffff", "photon", "Hope, with wings", ""],
	"Number 39: Utopia Beyond": ["ffd76a", "5ad0ff", "photon", "Past the far side of hope", ""],
	"Number S39: Utopia the Lightning": ["ffd76a", "5a8aff", "lightning", "Hope strikes like lightning", ""],
	"Number 62: Galaxy-Eyes Prime Photon Dragon": ["7ab0ff", "ffffff", "photon", "The first light of the galaxy", ""],
	"Galaxy-Eyes Cipher Dragon": ["5ad0ff", "b06bff", "photon", "It rewrites what is yours", ""],
	"Number 95: Galaxy-Eyes Dark Matter Dragon": ["6a6a7a", "b06bff", "galaxy", "The dark between the stars", ""],
	"Number C101: Silent Honor DARK": ["3a8aff", "6a6a7a", "waves", "Honor, drowned in chaos", ""],
	"Number 101: Silent Honor ARK": ["5ad0ff", "ffffff", "waves", "The ark takes what it wants", ""],
	"Bahamut Shark": ["3a8aff", "ffd76a", "waves", "The sea sends its king", ""],
	"Superdreadnought Rail Cannon Gustav Max": ["c9a76a", "ff5a3c", "gears", "One shot, two thousand", ""],
	"Machina Fortress": ["8a8aa0", "ffb03a", "gears", "It rebuilds itself", ""],
	"Splendid Venus": ["ffe9a8", "ffffff", "rays", "Only angels fight at full strength", ""],
	"Athena": ["ffffff", "ffd76a", "rays", "Every fairy answers her", ""],
}
const BY_ATTR := {"DARK": ["8a4dff", "2a0a4a", "circle"], "LIGHT": ["ffe9a8", "ffffff", "rays"], "FIRE": ["ff5a3c", "ffb03a", "flames"],
	"WATER": ["3a8aff", "9fe0ff", "waves"], "WIND": ["5aff8a", "d8ffe0", "streaks"], "EARTH": ["c9a76a", "5a3a1a", "hex"], "DIVINE": ["ffd76a", "ffffff", "rays"]}

static var dev_hold := 0.0        # dev: keep it on screen (screenshots)
var _t := 0.0
var _dur := 1.9
var _a := Color.WHITE
var _b := Color.WHITE
var _figure := "circle"
var _pad: Control
var _art: TextureRect
var _rng := RandomNumberGenerator.new()
var _seeds: Array = []
var _strike := false
var _dir := 1.0
var _boss := false          # the long version: 4000 ATK or more, or one of BOSSES
var _art_mat: ShaderMaterial

## (0.84.0) The picture is alive while it is up: a band of light crosses it once, and it is white
## hot for the blink in which it lands.
const ART_GLSL := """
shader_type canvas_item;
uniform float sweep = -0.4;
uniform float flash = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = UV.x * 0.8 + UV.y * 0.6;
	float band = exp(-pow((d - sweep * 1.75) / 0.06, 2.0));
	c.rgb += band * 0.6 * c.a;
	c.rgb = mix(c.rgb, vec3(1.0), clamp(flash, 0.0, 1.0) * step(0.02, c.a));
	COLOR = c;
}
"""
static var _art_sh: Shader

## Aces that get the long entrance whatever their ATK (the last card of a duelist's story).
const BOSSES := ["Slifer the Sky Dragon", "Obelisk the Tormentor", "The Winged Dragon of Ra", "Blue-Eyes Ultimate Dragon", "Rainbow Dragon", "Yubel",
	"Shooting Star Dragon", "Red Nova Dragon", "Number C39: Utopia Ray", "Neo Galaxy-Eyes Photon Dragon", "Lumen, Echo Nova", "Lumen, Echo Aurora"]


## Does this one get the long entrance (letterbox, a second and third ring, the table shakes)?
static func is_boss(card: Dictionary) -> bool:
	return int(card.get("atk", 0)) >= 4000 or BOSSES.has(str(card.get("name", "")))


## How long the duel waits on the entrance before the monster comes down.
static func hold_for(card: Dictionary) -> float:
	return 2.15 if is_boss(card) else 1.5


## The two colors of its entrance (for the light that follows it down to the table).
static func colors_of(card: Dictionary) -> Array:
	var spec: Array = SIGNATURE.get(str(card.get("name", "")), BY_ATTR.get(str(card.get("attribute", "DARK")), BY_ATTR["DARK"]))
	return [Color(str(spec[0])), Color(str(spec[1]))]


## The name its attack is called by, or "" for a monster without one.
static func attack_name(card: Dictionary) -> String:
	var spec: Array = SIGNATURE.get(str(card.get("name", "")), [])
	return str(spec[4]) if spec.size() > 4 else ""


## A signature monster attacks: its picture cuts across the screen with the attack's name.
static func strike(host: Node, card: Dictionary, mine: bool) -> SummonShow:
	var nm := str(card.get("name", ""))
	var spec: Array = SIGNATURE.get(nm, [])
	if spec.size() < 5:
		return null
	var s := SummonShow.new()
	s._a = Color(str(spec[0]))
	s._b = Color(str(spec[1]))
	s._figure = str(spec[2])
	s._strike = true
	s._dur = 1.0
	s.layer = 4
	host.add_child(s)
	s._build_strike(card, str(spec[4]), mine)
	return s


func _build_strike(card: Dictionary, attack: String, mine: bool) -> void:
	_rng.seed = hash(attack)
	for i in 40:
		_seeds.append([_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf()])
	_dir = 1.0 if mine else -1.0
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_paint)
	add_child(_pad)
	var vp := get_viewport().get_visible_rect().size
	_art = TextureRect.new()
	_art.texture = Cards.get_figure(int(card.get("id", 0)))
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.size = Vector2(300, 430)
	_art.pivot_offset = _art.size / 2.0
	_art.rotation = -0.1 * _dir
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var y := vp.y * 0.5 - 250.0
	var from_x := -340.0 if mine else vp.x + 40.0
	var hold_x := vp.x * (0.22 if mine else 0.78) - 150.0
	var out_x := vp.x + 80.0 if mine else -380.0
	_art.position = Vector2(from_x, y)
	var echoes: Array = []
	if CardData.LUMEN_CARDS.has(int(card.get("id", 0))):
		# One of Lumen's: two echoes of it come across behind it, each a step later.
		for k in 2:
			var e := _art.duplicate() as TextureRect
			e.modulate = Color(0.5, 0.92, 1.0, 0.5 - 0.2 * k)
			add_child(e)
			echoes.append(e)
	add_child(_art)
	var name_l := UITheme.label(Loc.t(attack).to_upper() + "!", 66, Color.WHITE, UITheme.title_font())
	name_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	name_l.offset_left = -900
	name_l.offset_right = 900
	name_l.offset_top = 40
	name_l.offset_bottom = 130
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_color_override("font_outline_color", _b.darkened(0.6))
	name_l.add_theme_constant_override("outline_size", 16)
	name_l.modulate.a = 0.0
	add_child(name_l)
	Sfx.play("charge", -6.0, 1.3)
	var tw := create_tween()
	tw.tween_property(_art, "position:x", hold_x, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(name_l, "modulate:a", 1.0, 0.12).set_delay(0.1)
	tw.tween_property(_art, "position:x", hold_x + 40.0 * _dir, 0.45 + dev_hold)
	tw.tween_property(_art, "position:x", out_x, 0.16).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "_fade", 0.0, 0.2)
	tw.tween_callback(queue_free)
	for k in echoes.size():
		var e2: TextureRect = echoes[k]
		var lag := 0.07 * (k + 1)
		var back := 70.0 * (k + 1) * _dir
		var et := create_tween()
		et.tween_interval(lag)
		et.tween_property(e2, "position:x", hold_x - back, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		et.tween_property(e2, "position:x", hold_x - back * 0.3 + 40.0 * _dir, 0.4 + dev_hold)
		et.tween_property(e2, "position:x", out_x, 0.16).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)


## Does this monster get an arrival? (Signature cards always; others from Level 7 up.)
static func wants(card: Dictionary) -> bool:
	return SIGNATURE.has(str(card.get("name", ""))) or int(card.get("level", 0)) >= 7


static func play(host: Node, card: Dictionary, mine: bool) -> SummonShow:
	var s := SummonShow.new()
	var nm := str(card.get("name", ""))
	var spec: Array = SIGNATURE.get(nm, [])
	var line := ""
	if spec.is_empty():
		var by: Array = BY_ATTR.get(str(card.get("attribute", "DARK")), BY_ATTR["DARK"])
		spec = [by[0], by[1], by[2], ""]
	else:
		line = str(spec[3])
	s._a = Color(str(spec[0]))
	s._b = Color(str(spec[1]))
	s._figure = str(spec[2])
	s._boss = is_boss(card)
	if s._boss:
		s._dur = 2.55
	s.layer = 4
	host.add_child(s)
	s._build(card, nm, line, mine)
	return s


func _build(card: Dictionary, nm: String, line: String, mine: bool) -> void:
	_rng.seed = hash(nm)
	for i in 40:
		_seeds.append([_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf()])
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_paint)
	add_child(_pad)
	_art = TextureRect.new()
	_art.texture = Cards.get_figure(int(card.get("id", 0)))
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_art.offset_left = -190
	_art.offset_right = 190
	_art.offset_top = -300
	_art.offset_bottom = 250
	_art.pivot_offset = Vector2(190, 275)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.modulate.a = 0.0
	if _art_sh == null:
		_art_sh = Shader.new()
		_art_sh.code = ART_GLSL
	_art_mat = ShaderMaterial.new()
	_art_mat.shader = _art_sh
	_art.material = _art_mat
	if CardData.LUMEN_CARDS.has(int(card.get("id", 0))):
		# One of Lumen's: four echoes of it stand round where it will be and close into it as it lands.
		for k in 4:
			var e := _art.duplicate() as TextureRect
			var off := Vector2([-330.0, 330.0, -190.0, 190.0][k], [-20.0, -20.0, 30.0, 30.0][k])
			e.offset_left += off.x
			e.offset_right += off.x
			e.offset_top += off.y
			e.offset_bottom += off.y
			e.modulate = Color(0.5, 0.92, 1.0, 0.0)
			add_child(e)
			var et := create_tween()
			et.tween_interval(0.12 + 0.05 * k)
			et.tween_property(e, "modulate:a", 0.5 if k < 2 else 0.34, 0.16)
			et.tween_interval(0.12)
			et.tween_property(e, "offset_left", -190.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			et.parallel().tween_property(e, "offset_right", 190.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			et.parallel().tween_property(e, "offset_top", -300.0, 0.22)
			et.parallel().tween_property(e, "offset_bottom", 250.0, 0.22)
			et.tween_property(e, "modulate:a", 0.0, 0.1)
			et.tween_callback(e.queue_free)
	# Two after-images run in ahead of it, in its color, and are gone as it arrives.
	for g in 2:
		var ghost := _art.duplicate() as TextureRect
		ghost.material = null
		ghost.modulate = Color(_a.lightened(0.3), 0.0)
		ghost.scale = Vector2(0.45, 0.45)
		ghost.rotation = -0.1
		add_child(ghost)
		var gt := create_tween()
		gt.tween_interval(0.2 + 0.06 * g)
		gt.tween_property(ghost, "modulate:a", 0.32 - 0.1 * g, 0.08)
		gt.parallel().tween_property(ghost, "scale", Vector2.ONE * (1.14 + 0.1 * g), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		gt.parallel().tween_property(ghost, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		gt.tween_property(ghost, "modulate:a", 0.0, 0.18)
		gt.tween_callback(ghost.queue_free)
	add_child(_art)
	var name_l := UITheme.label(Loc.t(nm).to_upper(), 58, Color.WHITE, UITheme.title_font())
	name_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	name_l.offset_left = -800
	name_l.offset_right = 800
	name_l.offset_top = -250
	name_l.offset_bottom = -180
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_color_override("font_outline_color", _b.darkened(0.6))
	name_l.add_theme_constant_override("outline_size", 14)
	name_l.modulate.a = 0.0
	add_child(name_l)
	var sub := UITheme.label(Loc.t(line) if line != "" else ("ATK %s" % CardData.stat_text(card.get("atk", 0))), 30, _a.lightened(0.72), UITheme.semi_font())
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	sub.add_theme_constant_override("outline_size", 7)
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	sub.offset_left = -800
	sub.offset_right = 800
	sub.offset_top = -180
	sub.offset_bottom = -140
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate.a = 0.0
	add_child(sub)
	Sfx.play("special", -3.0, 0.8 if mine else 0.65)
	Sfx.play("charge", -8.0)
	# It comes up out of the depth of the screen, turning straight as it does, lands white hot, and
	# then keeps drifting a hair closer for as long as it is up (it never just sits there).
	var tw := create_tween().set_parallel()
	_art.scale = Vector2(0.42, 0.42)
	_art.rotation = -0.1
	tw.tween_property(_art, "modulate:a", 1.0, 0.14).set_delay(0.28)
	tw.tween_property(_art, "scale", Vector2.ONE, 0.44).set_delay(0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_art, "rotation", 0.0, 0.44).set_delay(0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): _art_mat.set_shader_parameter("flash", v), 0.95, 0.0, 0.4).set_delay(0.3)
	tw.tween_method(func(v: float): _art_mat.set_shader_parameter("sweep", v), -0.3, 1.2, 0.5).set_delay(0.86)
	tw.tween_property(_art, "scale", Vector2.ONE * 1.045, maxf(0.3, _dur - 1.05 + dev_hold)).set_delay(0.75)
	name_l.pivot_offset = Vector2(800, 35)
	name_l.scale = Vector2(1.28, 1.28)
	tw.tween_property(name_l, "modulate:a", 1.0, 0.14).set_delay(0.6)
	tw.tween_property(name_l, "scale", Vector2.ONE, 0.22).set_delay(0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sub, "modulate:a", 1.0, 0.2).set_delay(0.78)
	if _boss:
		var hit2 := create_tween()
		hit2.tween_interval(0.86)
		hit2.tween_callback(Sfx.play.bind("impact", -7.0, 0.7))
	var hit := create_tween()
	hit.tween_interval(0.62)
	hit.tween_callback(Sfx.play.bind("impact", -5.0))       # (goes with this node, no loose timer)
	print("SHOW ", nm)
	var out := create_tween()
	out.tween_interval(_dur - 0.3 + dev_hold)
	out.tween_property(self, "_fade", 0.0, 0.3)
	out.tween_callback(queue_free)


var _fade := 1.0:
	set(v):
		_fade = v
		for c in get_children():
			if c is CanvasItem and c != _pad:
				(c as CanvasItem).modulate.a = minf((c as CanvasItem).modulate.a, v)


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_pad):
		_pad.queue_redraw()


func _paint() -> void:
	var sz := _pad.size
	if sz.x < 8.0 or sz.y < 8.0:
		return      # (not laid out yet)
	var c := sz / 2.0 + Vector2(0, -25)
	var k := clampf(_t / 0.5, 0.0, 1.0)
	var f := _fade
	if _strike:
		# A slanted band in the card's colors, with speed lines running the way it attacks.
		var kb := clampf(_t / 0.15, 0.0, 1.0)
		var half := 205.0 * kb
		if half < 2.0:
			return      # (a band with no height yet is not a shape that can be drawn)
		var band := PackedVector2Array([Vector2(0, c.y - half + 60.0), Vector2(sz.x, c.y - half - 60.0), Vector2(sz.x, c.y + half - 60.0), Vector2(0, c.y + half + 60.0)])
		_pad.draw_colored_polygon(band, Color(_b.darkened(0.7), 0.88 * f))
		_pad.draw_line(band[0], band[1], Color(_a, f), 5.0)
		_pad.draw_line(band[3], band[2], Color(_a, f), 5.0)
		for i in 26:
			var sd0: Array = _seeds[i]
			var ly := c.y + (float(sd0[0]) - 0.5) * 2.0 * (half - 30.0)
			var lx := fmod(float(sd0[1]) * sz.x + _t * (2600.0 + 1800.0 * float(sd0[2])) * _dir, sz.x + 500.0)
			if lx < 0.0:
				lx += sz.x + 500.0
			lx -= 250.0
			var slope := -120.0 / sz.x
			_pad.draw_line(Vector2(lx, ly + (lx - sz.x * 0.5) * slope), Vector2(lx + (160.0 + 300.0 * float(sd0[3])) * _dir, ly + (lx + 300.0 * _dir - sz.x * 0.5) * slope), Color(_a if i % 3 else _b.lightened(0.5), 0.55 * f), 3.0 + 3.0 * float(sd0[2]))
		return
	# The world goes dark, in the card's own color.
	_pad.draw_rect(Rect2(Vector2.ZERO, sz), Color(_a.lerp(_b, 0.3).darkened(0.88), 0.86 * k * f))
	var R := minf(sz.x, sz.y) * 0.36
	# (0.84.0) Light behind it once it has landed: a soft glow in its two colors, and wide shafts
	# turning slowly round it. It is what makes the figure sit IN something and not on black.
	var lit := clampf((_t - 0.5) / 0.35, 0.0, 1.0)
	if lit > 0.0:
		for i in 9:
			var gr := R * (1.75 - float(i) * 0.17)
			_pad.draw_circle(c, gr, Color(_b.lerp(_a, float(i) / 8.0), 0.04 * lit * f))
		for i in 12:
			var wa := float(i) * TAU / 12.0 + _t * 0.16
			var ww := 0.07 + 0.05 * float(_seeds[i][0])
			var far := maxf(sz.x, sz.y)
			_pad.draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(wa - ww), sin(wa - ww)) * far, c + Vector2(cos(wa + ww), sin(wa + ww)) * far]),
					Color(_a if i % 2 == 0 else _b.lightened(0.25), 0.055 * lit * f))
	# A burst behind the card at the moment it lands (a boss: three, one after the other).
	for b in (3 if _boss else 1):
		var hit := clampf((_t - 0.55 - 0.2 * float(b)) / 0.5, 0.0, 1.0)
		if hit > 0.0 and hit < 1.0:
			_pad.draw_arc(c, 120.0 + hit * (900.0 + 240.0 * float(b)), 0, TAU, 96, Color(_a if b != 1 else _b.lightened(0.3), (1.0 - hit) * 0.9 * f), 14.0 * (1.0 - hit) + 2.0)
	# Lines flying out from behind it as it lands.
	var fly := clampf((_t - 0.52) / 0.42, 0.0, 1.0)
	if fly > 0.0 and fly < 1.0:
		for i in (44 if _boss else 26):
			var la := float(_seeds[i % 40][0]) * TAU + float(i) * 0.37
			var l0 := R * (0.7 + 2.6 * fly) * (0.7 + 0.5 * float(_seeds[i % 40][1]))
			var l1 := l0 + R * (0.25 + 0.5 * float(_seeds[i % 40][2])) * (1.0 - fly * 0.4)
			_pad.draw_line(c + Vector2(cos(la), sin(la)) * l0, c + Vector2(cos(la), sin(la)) * l1, Color(Color.WHITE.lerp(_a, 0.4), (1.0 - fly) * 0.8 * f), 2.0 + 3.0 * float(_seeds[i % 40][3]))
	# Motes drifting up for as long as it is on screen.
	for i in 22:
		var ms: Array = _seeds[(i * 7 + 3) % 40]
		var ml := fmod(_t * (0.16 + 0.22 * float(ms[2])) + float(ms[0]), 1.0)
		var mp := Vector2(sz.x * float(ms[1]) + sin(_t * 1.3 + float(i)) * 18.0, sz.y * (1.02 - ml * 1.04))
		_pad.draw_circle(mp, 1.5 + 2.5 * float(ms[3]), Color((_a if i % 2 == 0 else _b).lightened(0.45), sin(ml * PI) * 0.75 * lit * f))
	# The band its name stands on: it opens from the middle as the name arrives.
	var nb := clampf((_t - 0.56) / 0.22, 0.0, 1.0)
	if nb > 0.0:
		var ny := sz.y - 215.0
		var half_w := 560.0 * (1.0 - pow(1.0 - nb, 3.0))
		_pad.draw_colored_polygon(PackedVector2Array([Vector2(c.x - half_w - 40.0, ny - 40.0), Vector2(c.x + half_w, ny - 40.0), Vector2(c.x + half_w + 40.0, ny + 44.0), Vector2(c.x - half_w, ny + 44.0)]),
				Color(_b.darkened(0.72), 0.78 * f))
		_pad.draw_line(Vector2(c.x - half_w - 40.0, ny - 40.0), Vector2(c.x + half_w, ny - 40.0), Color(_a, 0.95 * f), 3.0)
		_pad.draw_line(Vector2(c.x - half_w, ny + 44.0), Vector2(c.x + half_w + 40.0, ny + 44.0), Color(_a, 0.95 * f), 3.0)
	if _boss:
		# The edges of the screen burn in its color.
		for e in 5:
			var ew := 26.0 * float(5 - e)
			var ea := 0.05 * lit * f
			_pad.draw_rect(Rect2(0, 0, sz.x, ew), Color(_a, ea))
			_pad.draw_rect(Rect2(0, sz.y - ew, sz.x, ew), Color(_a, ea))
			_pad.draw_rect(Rect2(0, 0, ew, sz.y), Color(_a, ea))
			_pad.draw_rect(Rect2(sz.x - ew, 0, ew, sz.y), Color(_a, ea))
	match _figure:
		"wings":
			# Two wings open from behind it, feather by feather, and beat once, slowly.
			var open := clampf((_t - 0.35) / 0.55, 0.0, 1.0)
			open = 1.0 - pow(1.0 - open, 3.0)
			var beat := sin(_t * 2.2) * 0.07
			for side in [-1.0, 1.0]:
				if open < 0.03:
					break
				var root := c + Vector2(side * 120.0, -40.0)
				for i in 9:
					var u := float(i) / 8.0
					var ang := (-1.25 + u * 1.75 + beat) * open
					var ln := R * (2.1 - 0.9 * absf(u - 0.35)) * open
					var dirv := Vector2(side * cos(ang), sin(ang) - 0.25)
					var tip := root + dirv.normalized() * ln
					var nrm := Vector2(-dirv.y, dirv.x).normalized() * (20.0 + 16.0 * (1.0 - u))
					var colw := (_a if i % 2 == 0 else _b.lightened(0.3))
					_pad.draw_polygon(PackedVector2Array([root + nrm * 0.4, tip, root - nrm]), PackedColorArray([Color(colw, 0.75 * f), Color(colw.lightened(0.4), 0.15 * f), Color(colw, 0.75 * f)]))
					_pad.draw_line(root, tip, Color(colw.lightened(0.5), 0.8 * f), 2.0)
		"slash":
			# Three cuts across the screen, one after the other, each left hanging in the air.
			for i in 3:
				var st := clampf((_t - 0.18 - 0.14 * float(i)) / 0.12, 0.0, 1.0)
				if st <= 0.0:
					continue
				var tilt: float = [-0.42, 0.5, -0.12][i]
				var mid := c + Vector2([-60.0, 80.0, 0.0][i], [-90.0, 20.0, 150.0][i])
				var along := Vector2(cos(tilt), sin(tilt))
				var len_s := sz.x * 0.62 * st
				var hold_a := (1.0 - clampf((_t - 0.5 - 0.14 * float(i)) / 1.6, 0.0, 0.75))
				var wdt := 26.0 * hold_a + 3.0
				var perp := Vector2(-along.y, along.x) * wdt
				var p0 := mid - along * sz.x * 0.31
				var p1 := p0 + along * len_s
				_pad.draw_polygon(PackedVector2Array([p0, (p0 + p1) / 2.0 + perp, p1, (p0 + p1) / 2.0 - perp]),
						PackedColorArray([Color(_a, 0.0), Color(Color.WHITE, 0.9 * hold_a * f), Color(_a, 0.0), Color(_b.lightened(0.3), 0.7 * hold_a * f)]))
				_pad.draw_line(p0, p1, Color(Color.WHITE, 0.9 * hold_a * f), 3.0)
			for i in 26:
				var ss: Array = _seeds[i]
				var sl := fmod(_t * (0.8 + float(ss[2])) + float(ss[0]), 1.0)
				var sp := Vector2(sz.x * float(ss[1]), sz.y * (0.2 + 0.6 * float(ss[3]))) + Vector2(260.0, -110.0) * sl
				_pad.draw_line(sp, sp + Vector2(34.0, -14.0), Color(_a.lightened(0.5), (1.0 - sl) * 0.7 * k * f), 2.0)
		"runes":
			# A ring of old signs turning round it, a second one the other way, and light standing in two columns.
			for col_i in 2:
				var cx := c.x + (-1.0 if col_i == 0 else 1.0) * R * 1.75
				_pad.draw_polygon(PackedVector2Array([Vector2(cx - 46.0, 0), Vector2(cx + 46.0, 0), Vector2(cx + 30.0, sz.y), Vector2(cx - 30.0, sz.y)]),
						PackedColorArray([Color(_a, 0.0), Color(_a, 0.0), Color(_a, 0.34 * k * f), Color(_a, 0.34 * k * f)]))
			for ring in 2:
				var rr2 := R * (1.08 if ring == 0 else 0.8) * k
				_pad.draw_arc(c, rr2 + 34.0, 0, TAU, 96, Color(_a, 0.7 * f), 2.0)
				_pad.draw_arc(c, rr2 - 34.0, 0, TAU, 96, Color(_a, 0.7 * f), 2.0)
				var count := 14 if ring == 0 else 10
				for i in count:
					var ra := float(i) * TAU / float(count) + _t * (0.5 if ring == 0 else -0.7)
					var rp := c + Vector2(cos(ra), sin(ra)) * rr2
					var rx := Vector2(cos(ra + PI / 2.0), sin(ra + PI / 2.0)) * 11.0
					var ry := Vector2(cos(ra), sin(ra)) * 20.0
					var rc := Color((_b if ring == 0 else _a).lightened(0.45), 0.95 * f)
					# (five signs, each a few strokes: an upright with a different arm on each)
					_pad.draw_line(rp - ry, rp + ry, rc, 3.0)
					match (i + ring * 2) % 5:
						0:
							_pad.draw_line(rp - ry, rp + rx, rc, 3.0)
							_pad.draw_line(rp + rx, rp, rc, 3.0)
						1:
							_pad.draw_line(rp - ry * 0.4 - rx, rp + ry * 0.4 + rx, rc, 3.0)
						2:
							_pad.draw_line(rp - ry, rp - ry * 0.3 + rx, rc, 3.0)
							_pad.draw_line(rp, rp + ry * 0.7 + rx, rc, 3.0)
						3:
							_pad.draw_line(rp - rx, rp - ry * 0.6, rc, 3.0)
							_pad.draw_line(rp + rx, rp - ry * 0.6, rc, 3.0)
						_:
							_pad.draw_line(rp + ry * 0.5 - rx, rp + ry * 0.5 + rx, rc, 3.0)
		"storm":
			# Cloud across the top, rain driven on a slant, and now and then the sky opens.
			_pad.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, sz.y * 0.34), Vector2(0, sz.y * 0.28)]),
					PackedColorArray([Color(_b.darkened(0.5), 0.75 * k * f), Color(_b.darkened(0.5), 0.75 * k * f), Color(_b, 0.0), Color(_b, 0.0)]))
			for i in 40:
				var rs: Array = _seeds[i]
				for rep in 2:
					var rl := fmod(_t * (1.5 + 1.2 * float(rs[2])) + float(rs[0]) + 0.5 * float(rep), 1.0)
					var rp0 := Vector2(sz.x * (float(rs[1]) * 1.3 - 0.1) - rl * 260.0, sz.y * rl * 1.1 - 40.0)
					_pad.draw_line(rp0, rp0 + Vector2(-34.0, 110.0) * (0.6 + float(rs[3])), Color(_a.lightened(0.5), 0.4 * k * f), 2.0)
			for i in 3:
				var onb := fmod(_t * 2.6 + float(_seeds[i][1]) * 3.0, 1.0) < 0.22
				if not onb:
					continue
				var bx := sz.x * (0.15 + 0.7 * float(_seeds[(i + int(_t * 2.6)) % 40][0]))
				var bpts := PackedVector2Array([Vector2(bx, 0)])
				var by := 0.0
				var bj := 0
				while by < sz.y * 0.8 and bj < 20:
					by += 50.0 + 90.0 * float(_seeds[(i * 7 + bj) % 40][2])
					bx += (float(_seeds[(i * 11 + bj) % 40][3]) - 0.5) * 200.0
					bpts.append(Vector2(bx, by))
					bj += 1
				_pad.draw_polyline(bpts, Color(_b.lightened(0.6), 0.5 * f), 14.0)
				_pad.draw_polyline(bpts, Color(Color.WHITE, 0.95 * f), 4.0)
		"bloom":
			# A flower opens behind it, petal over petal, and loose petals come down across the screen.
			var op := clampf((_t - 0.3) / 0.7, 0.0, 1.0)
			op = 1.0 - pow(1.0 - op, 3.0)
			for layer in 2:
				var pc := 8 if layer == 0 else 6
				var pr := R * (1.5 if layer == 0 else 1.0) * op
				for i in pc:
					var pa := float(i) * TAU / float(pc) + (0.2 if layer == 1 else 0.0) + _t * (0.12 if layer == 0 else -0.16)
					var axis := Vector2(cos(pa), sin(pa))
					var side2 := Vector2(-axis.y, axis.x)
					var pcol := (_b if layer == 0 else _a)
					var pts3 := PackedVector2Array()
					var cols3 := PackedColorArray()
					for j in 9:
						var v := float(j) / 8.0
						var wv := sin(v * PI) * pr * 0.26
						pts3.append(c + axis * (60.0 + pr * v) + side2 * wv)
						cols3.append(Color(pcol.lightened(0.35 * v), (0.72 - 0.3 * v) * f))
					for j in 9:
						var v2 := 1.0 - float(j) / 8.0
						var wv2 := sin(v2 * PI) * pr * 0.26
						pts3.append(c + axis * (60.0 + pr * v2) - side2 * wv2)
						cols3.append(Color(pcol.darkened(0.15), (0.72 - 0.3 * v2) * f))
					_pad.draw_polygon(pts3, cols3)
					_pad.draw_line(c + axis * 60.0, c + axis * (60.0 + pr), Color(pcol.lightened(0.6), 0.6 * f), 2.0)
			for i in 24:
				var fs: Array = _seeds[i]
				var fl := fmod(_t * (0.3 + 0.3 * float(fs[2])) + float(fs[0]), 1.0)
				var fp := Vector2(sz.x * float(fs[1]) + sin(_t * 2.0 + float(i)) * 40.0, sz.y * (-0.05 + fl * 1.1))
				var fw := 12.0 + 14.0 * float(fs[3])
				var fa := _t * 2.0 + float(i)
				var fx := Vector2(cos(fa), sin(fa)) * fw
				var fy := Vector2(-sin(fa), cos(fa)) * fw * 0.45
				_pad.draw_colored_polygon(PackedVector2Array([fp - fx, fp + fy, fp + fx, fp - fy]), Color((_a if i % 2 == 0 else _b).lightened(0.3), 0.75 * k * f))
		"photon":
			# Three orbits round it with a light running on each, and streaks falling in to the middle.
			for i in 3:
				var tiltp := float(i) * PI / 3.0 + _t * 0.25
				var pts4 := PackedVector2Array()
				for j in 65:
					var pa2 := float(j) * TAU / 64.0
					var e2 := Vector2(cos(pa2) * R * 1.55 * k, sin(pa2) * R * 0.5 * k)
					pts4.append(c + e2.rotated(tiltp))
				_pad.draw_polyline(pts4, Color((_a if i != 1 else _b).lightened(0.2), 0.8 * f), 3.0)
				var da := _t * (2.6 + 0.5 * float(i)) + float(i) * 2.0
				var dp := c + Vector2(cos(da) * R * 1.55 * k, sin(da) * R * 0.5 * k).rotated(tiltp)
				for gl in 5:
					_pad.draw_circle(dp, 22.0 - 4.0 * float(gl), Color(Color.WHITE.lerp(_a, 0.3), 0.14 * f))
				_pad.draw_circle(dp, 6.0, Color(1, 1, 1, f))
			for i in 34:
				var hs: Array = _seeds[i]
				var hl := fmod(_t * (0.7 + 0.8 * float(hs[2])) + float(hs[0]), 1.0)
				var ha := float(hs[1]) * TAU
				var hr0 := R * 3.0 * (1.0 - hl)
				var hd := Vector2(cos(ha), sin(ha))
				_pad.draw_line(c + hd * hr0, c + hd * (hr0 + 30.0 + 70.0 * float(hs[3])), Color((_b if i % 3 == 0 else _a).lightened(0.4), hl * 0.7 * k * f), 2.0)
		"circle", "cards":
			for ring in 2:
				var rr := R * (1.0 if ring == 0 else 0.78)
				_pad.draw_arc(c, rr * k, 0, TAU, 96, Color(_a if ring == 0 else _b.lightened(0.3), 0.9 * f), 4.0)
			# A six-pointed star (two triangles) for magic, a five-pointed one for Lumen.
			var step := TAU / 3.0 if _figure == "circle" else TAU * 2.0 / 5.0
			var corners := 3 if _figure == "circle" else 5
			for tri in (2 if _figure == "circle" else 1):
				var pts := PackedVector2Array()
				for i in corners + 1:
					var ang := _t * 0.9 + float(i) * step + float(tri) * PI / 3.0
					pts.append(c + Vector2(cos(ang), sin(ang)) * R * 0.78 * k)
				_pad.draw_polyline(pts, Color(_a.lightened(0.3), 0.8 * f), 3.0)
			for i in 24:
				var a2 := -_t * 0.6 + float(i) * TAU / 24.0
				var p := c + Vector2(cos(a2), sin(a2)) * R * 0.89 * k
				if _figure == "cards" and i % 4 == 0:
					_pad.draw_rect(Rect2(p - Vector2(13, 19), Vector2(26, 38)), Color(_b if i % 8 == 0 else _a, 0.9 * f))
				else:
					_pad.draw_circle(p, 4.0, Color(_b.lightened(0.4), 0.9 * f))
		"aurora":
			# Curtains of light hanging from the top of the screen, swaying, and a few stars.
			for i in 16:
				var ax := sz.x * (float(i) + 0.5) / 16.0 + sin(_t * 0.9 + float(i) * 1.3) * 26.0
				var aw := sz.x / 16.0 * (0.7 + 0.5 * float(_seeds[i][0]))
				var ay := sz.y * (0.42 + 0.2 * sin(float(i) * 1.7 + _t * 0.7)) * k
				var ac := (_a if i % 2 == 0 else _b)
				_pad.draw_polygon(PackedVector2Array([Vector2(ax - aw, 0), Vector2(ax + aw, 0), Vector2(ax + aw * 0.7, ay), Vector2(ax - aw * 0.7, ay)]),
						PackedColorArray([Color(ac, 0.0), Color(ac, 0.0), Color(ac, 0.62 * f), Color(ac, 0.62 * f)]))
			for i in 30:
				var sp0: Array = _seeds[i]
				var tw0 := 0.5 + 0.5 * sin(_t * 6.0 + float(i))
				_pad.draw_circle(Vector2(sz.x * float(sp0[1]), sz.y * 0.95 * float(sp0[2])), 1.5 + 2.5 * float(sp0[3]) * tw0, Color(1, 1, 1, 0.8 * f * k))
			_pad.draw_arc(c, R * 0.95 * k, 0, TAU, 96, Color(1.0, 0.97, 0.8, 0.8 * f), 3.0)
		"nova":
			# A burst in the four colors of the worlds, and rings going out from it.
			var four := [Color("5a9eff"), Color("ffd24d"), Color("b86bff"), Color("eef8ff")]
			for i in 40:
				var na := float(i) * TAU / 40.0 + _t * 0.3
				var nc: Color = four[int(floor(fposmod(na - _t * 0.3 + 0.4, TAU) / (TAU / 4.0))) % 4]
				var nl := R * (0.6 + 2.2 * k) * (0.55 + 0.45 * float(_seeds[i][0]))
				_pad.draw_line(c + Vector2(cos(na), sin(na)) * 140.0, c + Vector2(cos(na), sin(na)) * (140.0 + nl), Color(nc, 0.6 * f), 5.0 + 9.0 * float(_seeds[i][1]))
			for i in 4:
				var nph := fmod(_t * 0.6 + float(i) / 4.0, 1.0)
				_pad.draw_arc(c, R * 2.2 * nph, 0, TAU, 96, Color(four[i] as Color, (1.0 - nph) * 0.9 * f), 6.0 * (1.0 - nph) + 1.0)
		"rays":
			for i in 28:
				var a3 := float(i) * TAU / 28.0 + _t * 0.25
				var len0 := R * (0.5 + 1.6 * k) * (0.6 + 0.4 * float(_seeds[i][0]))
				_pad.draw_line(c + Vector2(cos(a3), sin(a3)) * 150.0, c + Vector2(cos(a3), sin(a3)) * (150.0 + len0), Color(_a if i % 2 == 0 else _b, 0.55 * f), 6.0 + 10.0 * float(_seeds[i][1]))
		"lightning":
			for i in 7:
				var x := sz.x * (0.12 + 0.76 * float(_seeds[i][0]))
				var on := fmod(_t * 6.0 + float(_seeds[i][1]) * 5.0, 1.0) < 0.55
				if not on:
					continue
				var pts2 := PackedVector2Array([Vector2(x, 0)])
				var y := 0.0
				var j := 0
				while y < sz.y * 0.85 and j < 24:
					y += 60.0 + 80.0 * float(_seeds[(i * 5 + j) % 40][2])
					x += (float(_seeds[(i * 3 + j) % 40][3]) - 0.5) * 190.0
					pts2.append(Vector2(x, y))
					j += 1
				_pad.draw_polyline(pts2, Color(_a, 0.95 * f), 5.0)
				_pad.draw_polyline(pts2, Color(_b, 0.5 * f), 12.0)
		"flames", "petals", "feathers":
			for i in 40:
				var sd: Array = _seeds[i]
				var life := fmod(_t * (0.5 + float(sd[2])) + float(sd[0]), 1.0)
				var px := sz.x * float(sd[1])
				var py := sz.y * (1.05 - life * 1.1) if _figure == "flames" else sz.y * (-0.05 + life * 1.1)
				var w := 26.0 + 40.0 * float(sd[3])
				px += sin(_t * 3.0 + float(i)) * 30.0
				var col := (_a if i % 2 == 0 else _b.lightened(0.2))
				var tri := PackedVector2Array([Vector2(px, py - w * 1.6), Vector2(px - w * 0.5, py), Vector2(px + w * 0.5, py)]) if _figure == "flames" else PackedVector2Array([Vector2(px, py - w * 0.7), Vector2(px - w * 0.3, py), Vector2(px, py + w * 0.7), Vector2(px + w * 0.3, py)])
				_pad.draw_colored_polygon(tri, Color(col, (1.0 - life) * 0.8 * k * f))
		"stars":
			for i in 40:
				var sd2: Array = _seeds[i]
				var a4 := float(sd2[0]) * TAU
				var dist := (0.15 + float(sd2[1])) * R * 2.2 * (0.3 + 0.7 * clampf(_t / 1.2, 0.0, 1.0))
				var p2 := c + Vector2(cos(a4), sin(a4)) * dist
				var tw2 := 0.5 + 0.5 * sin(_t * 9.0 + float(i))
				var s2 := (5.0 + 16.0 * float(sd2[2])) * tw2
				_pad.draw_line(p2 - Vector2(s2, 0), p2 + Vector2(s2, 0), Color(_a, f), 2.0)
				_pad.draw_line(p2 - Vector2(0, s2), p2 + Vector2(0, s2), Color(_b.lightened(0.5), f), 2.0)
		"galaxy":
			for i in 160:
				var u := float(i) / 160.0
				var a5 := u * TAU * 3.0 + _t * 1.2 + (PI if i % 2 == 0 else 0.0)
				var p3 := c + Vector2(cos(a5), sin(a5) * 0.55) * R * 2.5 * u * k
				_pad.draw_circle(p3, 3.0 + 8.0 * (1.0 - u), Color(_a.lerp(_b, u).lightened(0.25), 0.95 * f))
			for ring in 3:
				_pad.draw_circle(c, R * (0.75 - 0.2 * float(ring)) * k, Color(_a.lerp(_b, 0.5), 0.10 * f))
		"waves":
			for i in 6:
				var ph := fmod(_t * 0.7 + float(i) / 6.0, 1.0)
				_pad.draw_arc(c, R * 2.0 * ph, 0, TAU, 96, Color(_a.lerp(_b, ph), (1.0 - ph) * 0.9 * f), 8.0 * (1.0 - ph) + 1.0)
		"gears":
			for g in 3:
				var gc: Vector2 = c + Vector2(float([-R * 1.25, R * 1.25, 0.0][g]), float([R * 0.2, -R * 0.3, R * 0.05][g]))
				var gr: float = R * float([0.55, 0.45, 0.95][g]) * k
				var teeth: int = int([10, 8, 16][g])
				var spin := _t * (1.2 if g != 1 else -1.5) * (1.0 if g < 2 else 0.5)
				_pad.draw_arc(gc, gr, 0, TAU, 64, Color(_a if g % 2 == 0 else _b, 0.85 * f), 5.0)
				for tI in teeth:
					var a6 := spin + float(tI) * TAU / float(teeth)
					_pad.draw_line(gc + Vector2(cos(a6), sin(a6)) * gr, gc + Vector2(cos(a6), sin(a6)) * (gr + 20.0), Color(_a, 0.85 * f), 9.0)
		"streaks":
			for i in 30:
				var sd3: Array = _seeds[i]
				var y2 := sz.y * float(sd3[0])
				var x2 := fmod(float(sd3[1]) * sz.x + _t * (1400.0 + 900.0 * float(sd3[2])), sz.x + 600.0) - 300.0
				_pad.draw_line(Vector2(x2, y2), Vector2(x2 + 220.0 + 260.0 * float(sd3[3]), y2), Color(_a if i % 2 == 0 else _b, 0.6 * f), 4.0)
		"hex":
			for i in 40:
				var sd4: Array = _seeds[i]
				var hc := Vector2(sz.x * float(sd4[0]), sz.y * float(sd4[1]))
				var hr := 30.0 + 50.0 * float(sd4[2])
				var hp := PackedVector2Array()
				for j2 in 7:
					hp.append(hc + Vector2(cos(float(j2) * TAU / 6.0), sin(float(j2) * TAU / 6.0)) * hr * k)
				_pad.draw_polyline(hp, Color(_a if i % 2 == 0 else _b.lightened(0.3), (0.3 + 0.5 * absf(sin(_t * 2.0 + float(i)))) * f), 3.0)
