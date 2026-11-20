extends Node
## Dev check: every card a spoken line names (Characters.LINE_NEEDS) is a card of this game, and each
## duelist's own lines pass or fail for the right cards. Run:
##   godot --headless --path . res://tests/line_names.tscn
func _ready() -> void:
	var bad := 0
	var names := {}
	CardData.get_card(46986414)      # (makes sure the name table is filled)
	for lower in CardData.NAME_TO_ID:
		var cid := int(CardData.NAME_TO_ID[lower])
		names[str(CardData.get_card(cid).get("name", ""))] = cid
	for text in Characters.LINE_NEEDS:
		for need in Characters.LINE_NEEDS[text]:
			var n := str(need)
			if n == "ace":
				continue
			var hits := 0
			for nm in names:
				if (n.begins_with("*") and n.ends_with("*") and str(nm).contains(n.substr(1, n.length() - 2))) \
						or (not n.begins_with("*") and n.ends_with("*") and str(nm).begins_with(n.substr(0, n.length() - 1))) or str(nm) == n:
					hits += 1
			if hits == 0:
				bad += 1
				print("NO CARD for '%s' (line: %s)" % [n, text])
			else:
				print("ok %4d card(s)  %-34s  %s" % [hits, n, text])
	# every line in the table belongs to somebody
	var all := {}
	for src in [Characters.DATA, Characters.STORY_CAST]:
		for key in src:
			var lines: Dictionary = src[key].get("lines", {})
			for kind in lines:
				for t in lines[kind]:
					all[str(t)] = key
					if str(t) in Characters.LINE_NEEDS and "ace" in Characters.LINE_NEEDS[str(t)] and int(Characters.get_char(key).get("ace", 0)) == 0:
						bad += 1
						print("NO ACE for %s (line: %s)" % [key, t])
	for text in Characters.LINE_NEEDS:
		if not all.has(text):
			bad += 1
			print("NOBODY SAYS: ", text)
	# spot checks
	var bew: int = names.get("Blue-Eyes White Dragon", 0)
	var beud: int = names.get("Blue-Eyes Ultimate Dragon", 0)
	var checks := [["kaiba", "Behold, the Blue-Eyes White Dragon!", bew, true], ["kaiba", "Behold, the Blue-Eyes White Dragon!", beud, false],
		["kaiba", "Behold, the Blue-Eyes White Dragon!", 0, false], ["kaiba", "Witness true power!", beud, true],
		["zane", "Cyber End Dragon. Evolution complete.", names.get("Cyber Dragon", 0), false], ["zane", "Cyber End Dragon. Evolution complete.", names.get("Cyber End Dragon", 0), true],
		["yugi", "My most trusted monster!", names.get("Dark Magician", 0), true], ["yugi", "My most trusted monster!", names.get("Dark Magician Girl", 0), false],
		["mai", "My Harpies always come in style!", names.get("Harpie Lady Sisters", 0), true], ["mai", "My Harpies always come in style!", names.get("Harpie's Pet Dragon", 0), false]]
	for c in checks:
		if Characters.line_fits(str(c[0]), str(c[1]), int(c[2])) != bool(c[3]) or (int(c[2]) == 0 and c != checks[2]):
			bad += 1
			print("WRONG: ", c)
	# a line picked 300 times for the wrong card never names a card
	for i in 300:
		var l := Characters.line("kaiba", "ace", beud)
		if Characters.last_en == "Behold, the Blue-Eyes White Dragon!":
			bad += 1
			print("WRONG PICK")
			break
	print("LINE NAMES: %s (%d lines tied to a card, %d problems)" % ["PASS" if bad == 0 else "FAIL", Characters.LINE_NEEDS.size(), bad])
	get_tree().quit(0 if bad == 0 else 1)
