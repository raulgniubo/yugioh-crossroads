extends SceneTree
func _init():
	await process_frame
	await process_frame
	var cl = root.get_node("/root/Collection")
	for p in cl.shop_packs():
		var fam = cl.FAMILIES.get(str(p["key"]), {})
		print("PACK|%d|%s|%s|%d|%s" % [int(p.get("tab", 0)), str(p["key"]), str(p["name"]), cl.pool(str(p["key"])).size(), str(fam.get("era", ""))])
	quit()
