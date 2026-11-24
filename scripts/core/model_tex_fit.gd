extends GLTFDocumentExtension
## (0.72.4) Sizes the textures of a dropped-in model while its file is being read.
##
## A model made outside the game usually brings three 2048 x 2048 textures. They used to be read
## whole, sent to the graphics card whole, fetched back from it, made smaller and sent again, all
## on the main thread (Avatars._fit_textures). Here they are made smaller the moment they are
## decoded, which for a model read ahead of time (Avatars.warm) is on another thread, and the big
## version never reaches the graphics card at all.
##
## Only for a read that asks for it: the reader puts the size wanted for the color texture in the
## state ("yc_cap"); every other texture is held to 1024, the same rule as before. An image whose
## use cannot be told from the file is left alone (_fit_textures still looks at it afterwards).


func _import_preflight(state: GLTFState, _extensions: PackedStringArray) -> Error:
	var cap = state.get_additional_data(&"yc_cap")
	if cap == null or int(cap) <= 0:
		return ERR_SKIP
	var js: Dictionary = state.json
	var texs: Array = js.get("textures", []) if js.get("textures") is Array else []
	var imgs: Array = js.get("images", []) if js.get("images") is Array else []
	var views: Array = js.get("bufferViews", []) if js.get("bufferViews") is Array else []
	var kinds := {}      # image number -> "albedo" / "normal" / "other"
	var mark := func(ref, kind: String) -> void:
		if not (ref is Dictionary) or not (ref as Dictionary).has("index"):
			return
		var ti := int(ref["index"])
		if ti < 0 or ti >= texs.size() or not (texs[ti] is Dictionary):
			return
		var sources: Array = []
		if (texs[ti] as Dictionary).has("source"):
			sources.append(int(texs[ti]["source"]))
		var ex = (texs[ti] as Dictionary).get("extensions")
		if ex is Dictionary:
			for e in ex.values():
				if e is Dictionary and (e as Dictionary).has("source"):
					sources.append(int(e["source"]))
		for si in sources:
			if kind == "albedo" or not kinds.has(si) or (kind == "normal" and kinds[si] == "other"):
				if kinds.get(si, "") != "albedo":
					kinds[si] = kind
	var mats = js.get("materials")
	if mats is Array:
		for m in mats:
			if not (m is Dictionary):
				continue
			var pbr = m.get("pbrMetallicRoughness")
			if pbr is Dictionary:
				mark.call(pbr.get("baseColorTexture"), "albedo")
				mark.call(pbr.get("metallicRoughnessTexture"), "other")
			mark.call(m.get("normalTexture"), "normal")
			mark.call(m.get("occlusionTexture"), "other")
			mark.call(m.get("emissiveTexture"), "other")
			var mex = m.get("extensions")
			if mex is Dictionary and mex.get("KHR_materials_pbrSpecularGlossiness") is Dictionary:
				mark.call(mex["KHR_materials_pbrSpecularGlossiness"].get("diffuseTexture"), "albedo")
				mark.call(mex["KHR_materials_pbrSpecularGlossiness"].get("specularGlossinessTexture"), "other")
	# The reader hands over an image's bytes without saying which image it is: they are told
	# apart by their length. (Two of the same length with different uses: the color one's rule,
	# the gentler of the two.)
	var by_len := {}
	for i in imgs.size():
		if not kinds.has(i) or not (imgs[i] is Dictionary) or not (imgs[i] as Dictionary).has("bufferView"):
			continue
		var bv := int(imgs[i]["bufferView"])
		if bv < 0 or bv >= views.size() or not (views[bv] is Dictionary):
			continue
		var n := int(views[bv].get("byteLength", 0))
		if n > 0 and by_len.get(n, "") != "albedo":
			by_len[n] = kinds[i]
	state.set_additional_data(&"yc_kinds", by_len)
	return OK


func _parse_image_data(state: GLTFState, image_data: PackedByteArray, _mime_type: String, ret_image: Image) -> Error:
	var by_len = state.get_additional_data(&"yc_kinds")
	if not (by_len is Dictionary):
		return OK
	var kind := str((by_len as Dictionary).get(image_data.size(), ""))
	if kind == "" or image_data.size() < 16:
		return OK
	# Only the plain kinds, told by their first bytes; anything else is the engine's to read.
	var err := ERR_FILE_UNRECOGNIZED
	if image_data[0] == 0x89 and image_data[1] == 0x50 and image_data[2] == 0x4E and image_data[3] == 0x47:
		err = ret_image.load_png_from_buffer(image_data)
	elif image_data[0] == 0xFF and image_data[1] == 0xD8:
		err = ret_image.load_jpg_from_buffer(image_data)
	elif image_data[0] == 0x52 and image_data[1] == 0x49 and image_data[2] == 0x46 and image_data[3] == 0x46 and image_data[8] == 0x57 and image_data[9] == 0x45:
		err = ret_image.load_webp_from_buffer(image_data)
	if err != OK or ret_image.is_empty():
		return OK
	var cap := int(state.get_additional_data(&"yc_cap"))
	if kind != "albedo":
		cap = mini(cap, 1024)
	var big := maxi(ret_image.get_width(), ret_image.get_height())
	if big > cap:
		if ret_image.is_compressed():
			ret_image.decompress()
		var k := float(cap) / float(big)
		ret_image.resize(maxi(1, int(ret_image.get_width() * k)), maxi(1, int(ret_image.get_height() * k)), Image.INTERPOLATE_BILINEAR)
		ret_image.generate_mipmaps(kind == "normal")
	return OK
