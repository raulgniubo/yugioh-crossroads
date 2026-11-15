class_name PerfReport
extends CanvasLayer
## The performance test. F4 anywhere (or the button in Settings) measures the screen you are
## on for about half a minute: first as it is, then with one thing switched off at a time, so
## the report says what each thing costs on this machine. Everything is put back afterwards.
## The report is a text file in the game's folder (Crossroads/reports).

static var running := false
static var last_path := ""

var _label: Label
var _undo: Array = []          # callables that put back what the running test changed


static func start(tree: SceneTree) -> void:
	if running or DisplayServer.get_name() == "headless":
		return
	running = true
	var p := PerfReport.new()
	p.layer = 127
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(p)


## Where reports go: beside the card folder (Documents/Crossroads/reports), or in the game's
## own folder ("Crossroads Data/reports").
static func folder() -> String:
	var base := Settings.card_folder
	if base.get_file() == "assets":
		base = base.get_base_dir()
	var dir := base.path_join("reports") if base != "" else ""
	if dir == "" or DirAccess.make_dir_recursive_absolute(dir) != OK:
		dir = OS.get_user_data_dir().path_join("reports")
		DirAccess.make_dir_recursive_absolute(dir)
	return dir


func _ready() -> void:
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.09, 0.9)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	sb.border_color = Color("ffb62e")
	sb.set_border_width_all(2)
	box.add_theme_stylebox_override("panel", sb)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.position.y = 90
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 26)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_label)
	add_child(box)
	_run()


func _say(step: int, total: int, what: String) -> void:
	_label.text = Loc.t("Performance test  %d / %d") % [step, total] + "\n" + what + "\n" + Loc.t("Do not touch anything for a moment.")


## Wait `settle` seconds, then time every frame for `secs` seconds.
func _measure(settle: float, secs: float) -> Dictionary:
	var rid := get_tree().root.get_viewport_rid()
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < int(settle * 1e6):
		await get_tree().process_frame
	var frames: Array[float] = []
	var cpu := 0.0
	var gpu := 0.0
	var draws := 0
	var tris := 0
	var objs := 0
	var last := Time.get_ticks_usec()
	var start_t := last
	while last - start_t < int(secs * 1e6):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		draws = maxi(draws, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		tris = maxi(tris, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		objs = maxi(objs, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
	var n := maxi(frames.size(), 1)
	var sum := 0.0
	for f in frames:
		sum += f
	frames.sort()
	var worst_n := maxi(1, n / 20)
	var worst := 0.0
	for i in worst_n:
		worst += frames[frames.size() - 1 - i] if not frames.is_empty() else 0.0
	return {
		"ms": sum / n, "fps": 1000.0 * n / maxf(sum, 0.001), "worst": worst / worst_n,
		"max": frames[frames.size() - 1] if not frames.is_empty() else 0.0,
		"cpu": cpu / n, "gpu": gpu / n, "draws": draws, "tris": tris, "objs": objs, "frames": n,
		"process": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
	}


static func _fmt(m: Dictionary) -> String:
	return "%6.1f FPS  %5.2f ms  (worst 5%%: %5.1f ms, max %5.1f)  render cpu %5.2f  gpu %5.2f  draws %5d  tris %7d" % [
		m["fps"], m["ms"], m["worst"], m["max"], m["cpu"], m["gpu"], m["draws"], m["tris"]]


func _all_nodes() -> Array:
	var out: Array = []
	var todo: Array = [get_tree().root]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		if n == self:
			continue
		out.append(n)
		for c in n.get_children(true):
			todo.append(c)
	return out


func _put_back() -> void:
	for u in _undo:
		(u as Callable).call()
	_undo.clear()


func _swap(obj: Object, prop: String, value) -> void:
	var old = obj.get(prop)
	if old == value:
		return
	obj.set(prop, value)
	_undo.append(func():
		if is_instance_valid(obj):
			obj.set(prop, old))


func _environments() -> Array:
	var out: Array = []
	for n in _all_nodes():
		var e: Environment = null
		if n is WorldEnvironment:
			e = (n as WorldEnvironment).environment
		elif n is Camera3D:
			e = (n as Camera3D).environment
		if e and not out.has(e):
			out.append(e)
	return out


func _under_skeleton(n: Node) -> bool:
	var p := n.get_parent()
	for i in 4:
		if p == null:
			return false
		if p is Skeleton3D:
			return true
		p = p.get_parent()
	return false


## The switches. Each returns false when there was nothing to switch off.
func _tests() -> Array:
	var root := get_tree().root
	return [
		["3D picture at half size (says how much of the time is pixels)", func() -> bool:
			_swap(root, "scaling_3d_scale", root.scaling_3d_scale * 0.5)
			return true],
		["Edge smoothing off", func() -> bool:
			if root.msaa_3d == Viewport.MSAA_DISABLED and root.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED:
				return false
			_swap(root, "msaa_3d", Viewport.MSAA_DISABLED)
			_swap(root, "screen_space_aa", Viewport.SCREEN_SPACE_AA_DISABLED)
			return true],
		["All shadows off", func() -> bool:
			var any := false
			for n in _all_nodes():
				if n is Light3D and (n as Light3D).shadow_enabled and (n as Light3D).is_visible_in_tree():
					_swap(n, "shadow_enabled", false)
					any = true
			return any],
		["Street lamps and other small lights off", func() -> bool:
			var any := false
			for n in _all_nodes():
				if (n is OmniLight3D or n is SpotLight3D) and (n as Node3D).visible:
					_swap(n, "visible", false)
					any = true
			return any],
		["Soft corner shading off", func() -> bool: return _env_off(["ssao_enabled"])],
		["Glow off", func() -> bool: return _env_off(["glow_enabled"])],
		["Reflections off", func() -> bool: return _env_off(["ssr_enabled"])],
		["Light haze off", func() -> bool: return _env_off(["volumetric_fog_enabled"])],
		["Bounce light off", func() -> bool: return _env_off(["sdfgi_enabled", "ssil_enabled"])],
		["Characters hidden", func() -> bool:
			var any := false
			for n in _all_nodes():
				if n is MeshInstance3D and (n as Node3D).visible and _under_skeleton(n):
					_swap(n, "visible", false)
					any = true
			return any],
		["The place hidden (everything but the characters)", func() -> bool:
			var any := false
			for n in _all_nodes():
				if (n is MeshInstance3D or n is MultiMeshInstance3D) and (n as Node3D).visible and not _under_skeleton(n):
					_swap(n, "visible", false)
					any = true
			return any],
		["Particles and weather hidden", func() -> bool:
			var any := false
			for n in _all_nodes():
				if (n is GPUParticles3D or n is CPUParticles3D) and (n as Node3D).visible:
					_swap(n, "visible", false)
					any = true
			return any],
		["Small 3D views paused (portraits, spirits, screens)", func() -> bool:
			var any := false
			for n in _all_nodes():
				if n is SubViewport and (n as SubViewport).render_target_update_mode in [SubViewport.UPDATE_ALWAYS, SubViewport.UPDATE_WHEN_VISIBLE, SubViewport.UPDATE_WHEN_PARENT_VISIBLE]:
					_swap(n, "render_target_update_mode", SubViewport.UPDATE_DISABLED)
					any = true
			return any],
		["Menus and on-screen text hidden", func() -> bool:
			var any := false
			for n in _all_nodes():
				if n is CanvasLayer and (n as CanvasLayer).visible:
					_swap(n, "visible", false)
					any = true
			return any],
	]


func _env_off(props: Array) -> bool:
	var any := false
	for e in _environments():
		for p in props:
			if bool(e.get(p)):
				_swap(e, p, false)
				any = true
	return any


func _run() -> void:
	var root := get_tree().root
	var lines: PackedStringArray = []
	# The frame rate cap, V-Sync and the softening would hide the differences: off for the test.
	var was_hold := Settings.hold_fps
	Settings.hold_fps = false
	Settings.auto_k = 1.0
	Settings._apply_scale()
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var tests := _tests()
	var total := tests.size() + 2
	_say(1, total, Loc.t("As it is now"))
	lines.append_array(_header())
	lines.append_array(_census())
	var base: Dictionary = await _measure(0.8, 3.0)
	lines.append("")
	lines.append("== THE SCREEN AS IT IS ==")
	lines.append(_fmt(base))
	lines.append("script and game logic per frame: %.2f ms   physics: %.2f ms" % [base["process"], base["physics"]])
	lines.append("")
	lines.append("== ONE THING OFF AT A TIME ==")
	var gains: Array = []
	for i in tests.size():
		var name := str(tests[i][0])
		_say(i + 2, total, Loc.t(name))
		var did: bool = (tests[i][1] as Callable).call()
		if not did:
			lines.append("%-66s  (already off, or none here)" % name)
			continue
		var m: Dictionary = await _measure(0.6, 1.3)
		_put_back()
		Settings._apply_scale()
		lines.append("%-66s  %s" % [name, _fmt(m)])
		gains.append([float(base["ms"]) - float(m["ms"]), name, m])
	_say(total, total, Loc.t("As it is now, once more"))
	var again: Dictionary = await _measure(0.8, 1.5)
	lines.append("%-66s  %s" % ["As it is, measured again at the end", _fmt(again)])
	lines.append("")
	lines.append("== WHAT COSTS THE MOST HERE ==")
	gains.sort_custom(func(a, b): return a[0] > b[0])
	var drift := absf(float(again["ms"]) - float(base["ms"]))
	for g in gains:
		var m2: Dictionary = g[2]
		lines.append("%+6.2f ms saved  (%5.1f -> %5.1f FPS)   %s" % [g[0], base["fps"], m2["fps"], g[1]])
	lines.append("The two plain measurements differ by %.2f ms: savings smaller than that are noise." % drift)
	var hz := DisplayServer.screen_get_refresh_rate()
	if hz > 0.0 and absf(float(base["fps"]) - hz) < 1.5:
		lines.append("NOTE: the frame rate sat exactly on the screen's %d Hz, so the screen is still capping it. Read the cpu and gpu columns instead of FPS." % int(hz))
	# Everything back the way it was.
	_put_back()
	Settings.hold_fps = was_hold
	Settings.apply_fps()
	Settings._apply_scale()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := folder().path_join("perf_%s.txt" % stamp)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
		f.close()
		last_path = path
		Router.toast(Loc.t("Performance report saved in %s") % folder(), 5.0)
	else:
		Router.toast(Loc.t("Could not save the performance report."), 4.0)
	print("PERF REPORT ", path)
	running = false
	queue_free()


func _header() -> PackedStringArray:
	var root := get_tree().root
	var out: PackedStringArray = []
	var scr := DisplayServer.window_get_current_screen()
	var px := Vector2(root.size) * root.scaling_3d_scale
	out.append("YU-GI-OH! CROSSROADS PERFORMANCE REPORT")
	out.append("version %s   %s" % [str(ProjectSettings.get_setting("application/config/version", "?")), Time.get_datetime_string_from_system()])
	out.append("")
	out.append("== MACHINE ==")
	out.append("system: %s %s   model: %s" % [OS.get_name(), OS.get_version(), OS.get_model_name()])
	out.append("processor: %s (%d threads)" % [OS.get_processor_name(), OS.get_processor_count()])
	out.append("graphics: %s (%s)   api %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_api_version()])
	out.append("renderer: %s on %s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name()])
	out.append("screen: %dx%d  scale %.2f  %d Hz" % [DisplayServer.screen_get_size(scr).x, DisplayServer.screen_get_size(scr).y, DisplayServer.screen_get_scale(scr), int(DisplayServer.screen_get_refresh_rate(scr))])
	out.append("window: %dx%d  mode %d (0 window, 3 fullscreen)" % [root.size.x, root.size.y, DisplayServer.window_get_mode()])
	out.append("3D picture: %dx%d (%d%% of the window)   scaling mode %d   msaa %d   screen aa %d" % [int(px.x), int(px.y), int(root.scaling_3d_scale * 100.0), root.scaling_3d_mode, root.msaa_3d, root.screen_space_aa])
	out.append("")
	out.append("== SETTINGS ==")
	out.append("preset: %s   %s" % [Settings.gfx_preset_name(), str(Settings.gfx)])
	out.append("frame cap: %s   hold the frame rate: %s   fullscreen: %s   fullscreen 3D size: %s" % [Settings.fps_name(Settings.fps_cap), str(Settings.hold_fps), str(Settings.fullscreen), str(Settings.fs_resolution)])
	out.append("")
	out.append("== WHERE ==")
	var cs := get_tree().current_scene
	out.append("scene: %s   %s" % [cs.scene_file_path if cs else "none", str(Router.roam) if "roam" in Router else ""])
	out.append("memory: game %d MB   video %d MB   textures %d MB   buffers %d MB" % [
		int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0), int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0),
		int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0), int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0)])
	return out


static func _mesh_tris(mesh: Mesh, cache: Dictionary) -> int:
	if mesh == null:
		return 0
	var id := mesh.get_instance_id()
	if cache.has(id):
		return cache[id]
	var t := 0
	if mesh is ArrayMesh:
		var am := mesh as ArrayMesh
		for s in am.get_surface_count():
			var il := am.surface_get_array_index_len(s)
			t += (il if il > 0 else am.surface_get_array_len(s)) / 3
	else:
		t = mesh.get_faces().size() / 3
	cache[id] = t
	return t


## What is in the scene right now, counted.
func _census() -> PackedStringArray:
	var out: PackedStringArray = []
	var cache := {}
	var meshes := 0
	var skinned := 0
	var surfaces := 0
	var tris_static := 0
	var tris_skin := 0
	var casters := 0
	var by_mesh := {}          # mesh id -> [count, tris, name]
	var mats := {}
	var see_through := 0
	var mm := 0
	var mm_inst := 0
	var lights := {"sun": 0, "omni": 0, "spot": 0}
	var shadow_lights := 0
	var parts := 0
	var skels := 0
	var bones := 0
	var players := 0
	var label3d := 0
	var bodies := 0
	var shapes := 0
	var controls := 0
	var nodes := 0
	var views: PackedStringArray = []
	var cs := get_tree().current_scene
	var by_group := {}         # top child of the scene -> [meshes, tris]
	for n in _all_nodes():
		nodes += 1
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if not mi.is_visible_in_tree() or mi.mesh == null:
				continue
			meshes += 1
			var t := _mesh_tris(mi.mesh, cache)
			var sk := _under_skeleton(mi)
			if sk:
				skinned += 1
				tris_skin += t
			else:
				tris_static += t
			surfaces += mi.mesh.get_surface_count()
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				casters += 1
			var id := mi.mesh.get_instance_id()
			if not by_mesh.has(id):
				var nm := mi.mesh.resource_name
				by_mesh[id] = [0, t, (nm if nm != "" else mi.mesh.get_class()) + " / " + str(mi.name)]
			by_mesh[id][0] += 1
			for s in mi.mesh.get_surface_count():
				var mat: Material = mi.get_active_material(s)
				if mat:
					if not mats.has(mat.get_instance_id()):
						mats[mat.get_instance_id()] = true
						if mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
							see_through += 1
			if cs and cs.is_ancestor_of(mi):
				var top: Node = mi
				while top.get_parent() != cs:
					top = top.get_parent()
				var key := str(top.name)
				if not by_group.has(key):
					by_group[key] = [0, 0]
				by_group[key][0] += 1
				by_group[key][1] += t
		elif n is MultiMeshInstance3D:
			var mmi := n as MultiMeshInstance3D
			if mmi.is_visible_in_tree() and mmi.multimesh:
				mm += 1
				mm_inst += mmi.multimesh.instance_count
		elif n is Light3D:
			var l := n as Light3D
			if l.is_visible_in_tree():
				lights["sun" if l is DirectionalLight3D else ("omni" if l is OmniLight3D else "spot")] += 1
				if l.shadow_enabled:
					shadow_lights += 1
		elif n is GPUParticles3D or n is CPUParticles3D:
			if (n as Node3D).is_visible_in_tree():
				parts += 1
		elif n is Skeleton3D:
			if (n as Node3D).is_visible_in_tree():
				skels += 1
				bones += (n as Skeleton3D).get_bone_count()
		elif n is AnimationPlayer:
			if (n as AnimationPlayer).is_playing():
				players += 1
		elif n is Label3D:
			label3d += 1
		elif n is PhysicsBody3D:
			bodies += 1
		elif n is CollisionShape3D:
			shapes += 1
		elif n is SubViewport:
			var sv := n as SubViewport
			views.append("  %s  %dx%d  update %d  msaa %d  scale %.2f  own world %s" % [str(sv.get_path()).right(60), sv.size.x, sv.size.y, sv.render_target_update_mode, sv.msaa_3d, sv.scaling_3d_scale, str(sv.own_world_3d)])
		elif n is Control:
			if (n as Control).is_visible_in_tree():
				controls += 1
	out.append("")
	out.append("== WHAT IS ON SCREEN (counted in the scene, not only in view) ==")
	out.append("nodes %d   visible controls %d" % [nodes, controls])
	out.append("mesh pieces %d (%d on characters)   surfaces %d   different meshes %d   different materials %d (%d see-through)" % [meshes, skinned, surfaces, by_mesh.size(), mats.size(), see_through])
	out.append("triangles: place %d   characters %d   pieces that cast shadows %d" % [tris_static, tris_skin, casters])
	out.append("instanced groups %d with %d copies" % [mm, mm_inst])
	out.append("lights: sun %d  omni %d  spot %d   with shadows %d" % [lights["sun"], lights["omni"], lights["spot"], shadow_lights])
	out.append("skeletons %d (%d bones)   animations playing %d   particle systems %d   3D labels %d" % [skels, bones, players, parts, label3d])
	out.append("physics bodies %d   collision shapes %d" % [bodies, shapes])
	out.append("small 3D views: %d" % views.size())
	out.append_array(views)
	var top_m: Array = by_mesh.values()
	top_m.sort_custom(func(a, b): return a[0] > b[0])
	out.append("most repeated meshes (copies x triangles each):")
	for i in mini(14, top_m.size()):
		out.append("  %5d x %6d   %s" % [top_m[i][0], top_m[i][1], top_m[i][2]])
	var top_t: Array = by_mesh.values()
	top_t.sort_custom(func(a, b): return a[0] * a[1] > b[0] * b[1])
	out.append("heaviest meshes (copies x triangles each):")
	for i in mini(10, top_t.size()):
		out.append("  %5d x %6d   %s" % [top_t[i][0], top_t[i][1], top_t[i][2]])
	var groups: Array = []
	for k in by_group:
		groups.append([by_group[k][0], by_group[k][1], k])
	groups.sort_custom(func(a, b): return a[0] > b[0])
	out.append("parts of the scene by mesh pieces (pieces, triangles):")
	for i in mini(16, groups.size()):
		out.append("  %5d  %8d   %s" % [groups[i][0], groups[i][1], groups[i][2]])
	return out
