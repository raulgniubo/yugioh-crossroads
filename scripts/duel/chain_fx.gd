class_name ChainFx
extends Node3D
## A chain you can see (0.57.0). Every card that goes on the chain gets a numbered link over it,
## joined to the one before by a chain of light. When the chain resolves, the links go off one
## by one from the last to the first: the link swells, its chain breaks, and it is gone. A card
## whose effect is negated gets a red cross stamped on it.
## The first link only shows once a second card is chained to it, like at a real table.

const MINE := Color("5fc8ff")
const THEIRS := Color("ff6a7c")
const GOLD := Color("ffd23a")

var board: Node3D
var _links := {}      # n -> {"at": Vector3, "node": Node3D or null, "p": int, "card": inst}
var _ropes := {}      # n -> the chain from link n-1 to link n
var _top := 0


func _init(b: Node3D) -> void:
	board = b


## Card n goes on the chain, over the spot `at`.
func link(n: int, p: int, inst, at: Vector3) -> void:
	if n < 1:
		return
	# (Their back row sits under the caption at the top of the screen: its links hang a little
	# toward the middle of the table so they can be seen.)
	var over := at + Vector3(0, 0.62, 0.75 if at.z < -2.0 else 0.0)
	_links[n] = {"at": over, "node": null, "p": p, "card": inst}
	_top = maxi(_top, n)
	if n < 2:
		return
	# The second card makes it a chain: the first link appears with it.
	for k in range(1, n + 1):
		if _links.has(k) and _links[k]["node"] == null:
			_links[k]["node"] = _badge(k, int(_links[k]["p"]), _links[k]["at"], k == n)
	if _links.has(n - 1):
		var a: Vector3 = _links[n - 1]["at"]
		var b: Vector3 = _links[n]["at"]
		_ropes[n] = DuelFx.chain(self, a, b, GOLD, board.camera if "camera" in board else null, 0.28)
		Sfx.play("chain", -3.0, 0.9 + 0.08 * n)
		board.shake(0.12)


func _badge(n: int, p: int, at: Vector3, fresh: bool) -> Node3D:
	var col := MINE if p == 0 else THEIRS
	var root := Node3D.new()
	root.position = at
	add_child(root)
	var m := DuelFx._mat("glyph_badge", DuelFx.HEAD_TOP + DuelFx.BILLBOARD + DuelFx.GLYPH, {"color": col, "energy": 2.6, "alpha": 1.0, "radius": 0.8,
		"width": 0.07, "soft": 0.12, "rings": 0.0, "ticks": 0.0, "star": 0.0, "dash": 6.0, "spin": 0.0})
	m.render_priority = 2
	var ring := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.86, 0.86)
	ring.mesh = q
	ring.material_override = m
	ring.name = "Ring"
	root.add_child(ring)
	ring.create_tween().set_loops().tween_property(m, "shader_parameter/spin", DuelFx.TAU_F, 3.0).from(0.0)
	var disc := MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.7, 0.7)
	disc.mesh = q2
	disc.material_override = DuelFx._mat("badge_disc", "shader_type spatial;\nrender_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;\n" + DuelFx.BILLBOARD
		+ "uniform vec4 color : source_color = vec4(1.0);\nvoid fragment() { vec2 p = (UV - 0.5) * 2.0; float r = length(p); ALBEDO = color.rgb * 0.28; ALPHA = smoothstep(0.86, 0.78, r) * 0.86; }\n", {"color": col})
	disc.sorting_offset = -1.0
	root.add_child(disc)
	var num := Label3D.new()
	num.text = str(n)
	num.font = UITheme.title_font()
	num.font_size = 96
	num.pixel_size = 0.005
	num.outline_size = 18
	num.outline_modulate = Color(0.02, 0.03, 0.08)
	num.modulate = Color(1.0, 0.98, 0.9)
	num.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	num.no_depth_test = true
	num.render_priority = 3
	num.name = "Num"
	root.add_child(num)
	root.scale = Vector3.ONE * 0.2
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE * (1.25 if fresh else 1.0), Settings.t(0.16)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "scale", Vector3.ONE, Settings.t(0.12))
	DuelFx.glow(self, at, col, 1.3, 0.3, 0.6, 2.4, true)
	return root


## Link n is about to resolve: it swells and lights up.
func solving(n: int) -> void:
	if not _links.has(n) or _links[n]["node"] == null:
		return
	var root: Node3D = _links[n]["node"]
	var at: Vector3 = _links[n]["at"]
	var col := MINE if int(_links[n]["p"]) == 0 else THEIRS
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE * 1.55, Settings.t(0.14)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	DuelFx.glow(self, at, col, 2.0, 0.4, 1.0, 2.8, true)
	DuelFx.ring(board, Vector3(at.x, 0.03, at.z), col, 0.3, 1.2, 0.45, 0.05)
	Sfx.play("chain", -5.0, 1.5)


## Link n was negated: a red cross over it.
func negated(n: int, inst) -> void:
	var at: Vector3
	if _links.has(n):
		at = _links[n]["at"]
	elif inst != null and board.has_method("chain_spot"):
		at = board.chain_spot(inst, int(inst.owner))
		at += Vector3(0, 0.62, 0.75 if at.z < -2.0 else 0.0)
	else:
		return
	var x := Label3D.new()
	x.text = "✕"
	x.font = UITheme.title_font()
	x.font_size = 170
	x.pixel_size = 0.0042
	x.outline_size = 22
	x.outline_modulate = Color(0.2, 0.0, 0.02)
	x.modulate = Color(1.0, 0.22, 0.25)
	x.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	x.no_depth_test = true
	x.render_priority = 4
	x.position = at
	x.scale = Vector3.ONE * 2.4
	add_child(x)
	var tw := x.create_tween()
	tw.tween_property(x, "scale", Vector3.ONE, Settings.t(0.12)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(Settings.t(0.55))
	tw.tween_property(x, "modulate:a", 0.0, Settings.t(0.25))
	tw.tween_callback(x.queue_free)
	DuelFx.glow(self, at, Color(1.0, 0.2, 0.2), 2.2, 0.4, 0.0, 2.6, true)
	DuelFx.rays(self, at, Color(1.0, 0.3, 0.3), 1.4, 0.35, 18, false)
	Sfx.play("negate", -2.0)
	board.shake(0.35)
	if _links.has(n) and _links[n]["node"] != null:
		var num := (_links[n]["node"] as Node3D).get_node_or_null("Num") as Label3D
		if num:
			num.modulate = Color(0.55, 0.55, 0.6)


## Link n is done: it bursts, and the chain that held it to the one before breaks.
func solved(n: int) -> void:
	if _ropes.has(n):
		DuelFx.snap_chain(_ropes[n], 0.2)
		_ropes.erase(n)
	if not _links.has(n):
		return
	var root = _links[n]["node"]
	var at: Vector3 = _links[n]["at"]
	_links.erase(n)
	if root == null or not is_instance_valid(root):
		return
	DuelFx.sparks(self, at, GOLD, 14, 2.6, 0.5, 0.5, -4.0, 0.04)
	var tw := (root as Node3D).create_tween()
	tw.tween_property(root, "scale", Vector3.ONE * 0.05, Settings.t(0.14)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(root.queue_free)


## The chain is over: whatever is left goes.
func end() -> void:
	for n in _ropes.keys():
		DuelFx.fade(_ropes[n], 0.15)
	_ropes.clear()
	for n in _links.keys():
		var root = _links[n]["node"]
		if root != null and is_instance_valid(root):
			var tw := (root as Node3D).create_tween()
			tw.tween_property(root, "scale", Vector3.ONE * 0.05, Settings.t(0.12))
			tw.tween_callback(root.queue_free)
	_links.clear()
	_top = 0


func size() -> int:
	return _top
