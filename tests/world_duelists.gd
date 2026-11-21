extends Node
## Dev: everybody you can duel in every world, and what the duel knows about them. A duelist the
## duel does not know by their key gets the name "Rival" and a drawn stand-in face: none may be left.
##   godot --headless --path . res://tests/world_duelists.tscn
func _ready() -> void:
	var bad := 0
	var all := 0
	for wk in RoamData.DISTRICTS:
		var d: Dictionary = RoamData.district(str(wk))
		for n in d.get("npcs", []):
			var npc: Dictionary = n
			if not npc.has("duel"):
				continue
			all += 1
			var key := str(npc.get("char", ""))
			if key == "":
				key = str(npc.get("id", ""))
			# (what roam_scene._start_duel does: a character sheet, or their own name and a model to look like)
			var known := not Characters.get_char(key).is_empty() or (str(npc.get("name", "")) != "" and str(npc.get("model", "")) != "" and Avatars.has_avatar(str(npc["model"])))
			if not known:
				bad += 1
				print("  %-12s %-18s name '%s' model '%s' pos %s : the duel does not know this key" % [wk, key, str(npc.get("name", "")), str(npc.get("model", "")), str(npc.get("pos", ""))])
	print("WORLD DUELISTS: %d duelists in %d worlds, %d the duel does not know  %s" % [all, RoamData.DISTRICTS.size(), bad, "PASS" if bad == 0 else "FAIL"])
	get_tree().quit(0 if bad == 0 else 1)
