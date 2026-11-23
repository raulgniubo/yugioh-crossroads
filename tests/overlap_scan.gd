extends SceneTree
## Dev: people standing inside each other. For every world and every half hour of the day: the
## fixed people (each world's NPCs and shop people), where the stars are (StarLife's day plans)
## and every stop of the walkers' loops (WorldLife routines: any of them can be there at any time).
## Prints each pair closer than 1.2 m.   godot --headless --path . -s tests/overlap_scan.gd

const NEAR := 1.2


func _init() -> void:
	var found := 0
	for d in ["academy", "domino", "satellite", "newdomino", "heartland", "museum"]:
		var fixed: Array = []      # [name, pos]
		var dd: Dictionary = RoamData.DISTRICTS.get(d, {})
		for list_key in ["npcs", "shop_npcs"]:
			for n in dd.get(list_key, []):
				# (A star's own entry is where their day plan puts them, counted below.)
				if n is Dictionary and (n as Dictionary).has("pos") and n["pos"] is Vector3 and not StarLife.DAYS.get(d, {}).has(str(n.get("id", ""))):
					fixed.append([str(n.get("id", n.get("name", "?"))), n["pos"]])
		for r in WorldLife.ROUTINES.get(d, []):
			var k := 0
			for st in r[2]:
				fixed.append(["walker %s stop %d" % [str(r[0]), k], st[0]])
				k += 1
		var pairs := {}
		for minute in range(0, 1440, 30):
			var here: Array = fixed.duplicate()
			var plans: Dictionary = StarLife.DAYS.get(d, {})
			for who in plans:
				var stops: Array = plans[who]
				var now: Array = stops[stops.size() - 1]
				for s in stops:
					if int(s[0]) <= minute:
						now = s
				here.append([str(who), now[1]])
			for i in here.size():
				for j in range(i + 1, here.size()):
					var a: Vector3 = here[i][1]
					var b: Vector3 = here[j][1]
					var dist := Vector2(a.x - b.x, a.z - b.z).length()
					if dist < NEAR:
						var key := "%s | %s | %s" % [d, here[i][0], here[j][0]]
						if not pairs.has(key):
							pairs[key] = [dist, minute]
		for key in pairs:
			found += 1
			print("OVERLAP %s  %.2f m  (first at %02d:%02d)" % [key, pairs[key][0], int(pairs[key][1]) / 60, int(pairs[key][1]) % 60])
	print("OVERLAPS FOUND: ", found)
	quit()
