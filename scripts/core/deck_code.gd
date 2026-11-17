class_name DeckCode
extends RefCounted
## A deck as one short line of text, to send to a friend: "CR1-" and the cards, packed.
## Each card is 5 bytes: its id (4) and one byte for where it goes (Main/Extra/Side) and how many.

const HEAD := "CR1-"


static func encode(main: Array, extra: Array, side: Array) -> String:
	var bytes := PackedByteArray()
	var zones := [main, extra, side]
	for z in zones.size():
		var counts := {}
		var order := []
		for id in zones[z]:
			if not counts.has(int(id)):
				order.append(int(id))
			counts[int(id)] = int(counts.get(int(id), 0)) + 1
		for id in order:
			var b := PackedByteArray()
			b.resize(5)
			b.encode_u32(0, id)
			b[4] = (z << 4) | clampi(int(counts[id]), 1, 15)
			bytes.append_array(b)
	var s := Marshalls.raw_to_base64(bytes)
	return HEAD + s.replace("+", "-").replace("/", "_").replace("=", "")


## {"main": [...], "extra": [...], "side": [...]} or {} when the text is not a deck code.
static func decode(text: String) -> Dictionary:
	var t := text.strip_edges()
	if not t.begins_with(HEAD):
		return {}
	var s := t.substr(HEAD.length()).replace("-", "+").replace("_", "/")
	var ok := RegEx.create_from_string("^[A-Za-z0-9+/]+$")
	if ok.search(s) == null:
		return {}
	while s.length() % 4 != 0:
		s += "="
	var bytes := Marshalls.base64_to_raw(s)
	if bytes.size() == 0 or bytes.size() % 5 != 0:
		return {}
	var out := {"main": [], "extra": [], "side": []}
	var names := ["main", "extra", "side"]
	for i in range(0, bytes.size(), 5):
		var id := bytes.decode_u32(i)
		var z := bytes[i + 4] >> 4
		var n := bytes[i + 4] & 15
		if z > 2 or CardData.get_card(id).get("name", "Unknown") == "Unknown":
			continue
		for k in n:
			(out[names[z]] as Array).append(id)
	return out
