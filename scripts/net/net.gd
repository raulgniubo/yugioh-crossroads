extends Node
## Online duels (0.73.0): Duel Groups, the people in them, challenges, and the duel's own line.
##
## A Duel Group is a private network (a Tailscale tailnet) that only holds copies of the game. One
## person makes it once with a free Tailscale account made for the game and a key; everyone else
## joins with an invite code that carries the key. Crossroads Link (tools/netlink, started by this
## script) joins the group without anything being installed; the game itself only ever talks to it
## on 127.0.0.1.
##
## Between two copies there is one connection (NetConn). Over it: who you are (your duelist's name,
## title and look), whether you are free, challenges, and a duel's events and answers (NetDuel).
##
## Tests on one computer: `--net-local=41301 --net-peers=41302` makes this copy listen on 41301 and
## find the other copy on 41302, with no Tailscale at all. NET_LAG / NET_JITTER / NET_DROP make the
## line bad on purpose (see NetConn).

signal changed                       # the people, the link or the groups changed: the Online screen redraws
signal challenged(ch: Dictionary)    # somebody challenges you
signal answered(ch: Dictionary)      # your challenge was answered (ok / no / gone)
signal session_message(msg: Dictionary)

static var DIR := Saves.u("online/")
const KEY_DAYS := 90                 # how long the keys the steps ask for last
const HOST_PREFIX := "xroads-"
const LINK_IDLE := 25

var groups: Array = []               # [{gid, name, color, owner, key, key_made, owner_name, joined}]
var current := ""                    # gid of the group in use ("" = none yet)
var install := ""                    # this installation, at random (part of its name in the group)
var me_id := ""                      # this copy's name in the group

var link_state := "off"              # off, starting, running, needs_key, error
var link_error := ""
var link_why := ""                   # "", offline, expired, bad_key
var link_pid := -1
var self_ip := ""
var self_addrs := 0                  # how many ways in this copy found (more: an easier connection to host from)
var tailnet := ""
var _ctl := 0
var _dial := 0
var _token := ""
var _http_busy := false
var _last_status := 0
var _status_every := 2.0
var _ping_at := {}                   # member id -> when it was last pinged

var server: TCPServer
var game_port := 0
var members := {}                    # id -> {id, ip, online, direct, ms, hello: {...}, status}
var conns := {}                      # member id -> NetConn
var _loose: Array = []               # connections that have not said who they are yet
var _dial_wait := {}                 # member id -> msec before dialing them again
var status := "idle"                 # what this copy tells the others: idle, duel, busy
var session = null                   # the NetDuel in progress
var challenge_out := {}              # the challenge you sent and are waiting on
var challenges_in := {}              # cid -> challenge waiting for your answer
var lobby_open := false              # the Online screen is up: people are pinged more often

# A test on one computer (no Tailscale).
var local := false
var _local_peers: Array = []         # ["127.0.0.1:41302", ...]

var auto := ""                       # dev: --net-auto=challenge | accept (two copies play each other by themselves)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(DIR)
	_load()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--net-local="):
			local = true
			game_port = int(a.substr(12))
		elif a.begins_with("--net-peers="):
			for p in a.substr(12).split(","):
				_local_peers.append(p if ":" in p else "127.0.0.1:" + p)
		elif a.begins_with("--net-auto="):
			auto = a.substr(11)
	if local:
		if groups.is_empty():
			# (a group for the test, never saved)
			groups = [{"gid": "local", "name": "Raul's Table", "color": 0, "owner": true, "key": "tskey-auth-kLOCAL0000CNTRL-test",
				"key_made": int(Time.get_unix_time_from_system()) - 86 * 86400 if "--net-key-old" in OS.get_cmdline_user_args() else int(Time.get_unix_time_from_system()),
				"owner_name": Profile.duelist_name, "joined": 0}]
			current = "local"
		me_id = "%slocal-%d" % [HOST_PREFIX, game_port]
		_listen(game_port)
		link_state = "running"
		print("NET local test: ", me_id, " peers ", _local_peers)
	elif not groups.is_empty() and not OS.has_feature("editor_hint"):
		# (online as soon as the menu is up, so the others see you and can challenge you)
		get_tree().create_timer(4.0).timeout.connect(func():
			if link_state == "off" and not groups.is_empty():
				link_start())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		link_stop()


# ------------------------------------------------------------------ groups

func _load() -> void:
	var v = JSON.parse_string(FileAccess.get_file_as_string(DIR + "groups.json")) if FileAccess.file_exists(DIR + "groups.json") else null
	if v is Dictionary:
		groups = (v as Dictionary).get("groups", [])
		current = str((v as Dictionary).get("current", ""))
		install = str((v as Dictionary).get("install", ""))
	if install == "":
		install = "%04x" % (randi() & 0xffff)
		_save()
	_make_id()


func _save() -> void:
	var f := FileAccess.open(DIR + "groups.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"groups": groups, "current": current, "install": install}, "\t"))


func _make_id() -> void:
	if local:
		return
	var slug := ""
	for ch in Profile.duelist_name.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			slug += ch
		elif slug != "" and not slug.ends_with("-"):
			slug += "-"
	slug = slug.trim_suffix("-").left(14)
	if slug == "":
		slug = "duelist"
	me_id = "%s%s-%s" % [HOST_PREFIX, slug, install]


func group() -> Dictionary:
	for g in groups:
		if str(g["gid"]) == current:
			return g
	return {}


func is_owner() -> bool:
	return bool(group().get("owner", false))


## Days left on the group's key (it was made to last KEY_DAYS days when it was pasted).
func key_days_left(g := {}) -> int:
	if g.is_empty():
		g = group()
	if g.is_empty():
		return 0
	return int(ceil((float(g.get("key_made", 0)) + KEY_DAYS * 86400.0 - Time.get_unix_time_from_system()) / 86400.0))


## A new group, made by its owner (the last step of "Make a group").
func make_group(name: String, color: int, key: String) -> Dictionary:
	var g := {"gid": "%08x%04x" % [randi(), randi() & 0xffff], "name": name.strip_edges(), "color": color, "owner": true,
		"key": key.strip_edges(), "key_made": int(Time.get_unix_time_from_system()), "owner_name": Profile.duelist_name,
		"joined": int(Time.get_unix_time_from_system())}
	groups.append(g)
	current = str(g["gid"])
	_save()
	changed.emit()
	return g


## The text that lets somebody in: the group's name and color, its owner, and its key.
func invite_code(g := {}) -> String:
	if g.is_empty():
		g = group()
	var d := {"v": 1, "g": g["gid"], "n": g["name"], "c": int(g["color"]), "k": g["key"], "t": int(g["key_made"]), "o": str(g.get("owner_name", ""))}
	return "XR1-" + Marshalls.utf8_to_base64(JSON.stringify(d)).replace("+", "-").replace("/", "_").replace("=", "")


## What an invite code holds, or {} when it is not one.
static func read_invite(code: String) -> Dictionary:
	var s := code.strip_edges().replace(" ", "").replace("\n", "")
	var at := s.find("XR1-")
	if at < 0:
		return {}
	s = s.substr(at + 4).replace("-", "+").replace("_", "/")
	while s.length() % 4 != 0:
		s += "="
	var j = JSON.parse_string(Marshalls.base64_to_utf8(s))
	if not (j is Dictionary) or not (j as Dictionary).has("k") or not str(j["k"]).begins_with("tskey-"):
		return {}
	return j


## Join a group with an invite code. Returns "" or what is wrong with the code.
func join(code: String) -> String:
	var d := read_invite(code)
	if d.is_empty():
		return Loc.t("That is not an invite code. Ask for it again and paste all of it.")
	for g in groups:
		if str(g["gid"]) == str(d["g"]):
			g["key"] = str(d["k"])
			g["key_made"] = int(d.get("t", 0))
			current = str(g["gid"])
			_save()
			link_restart()
			return ""
	groups.append({"gid": str(d["g"]), "name": str(d.get("n", "Duel Group")), "color": int(d.get("c", 0)), "owner": false,
		"key": str(d["k"]), "key_made": int(d.get("t", 0)), "owner_name": str(d.get("o", "")), "joined": int(Time.get_unix_time_from_system())})
	current = str(d["g"])
	_save()
	link_restart()
	return ""


func use_group(gid: String) -> void:
	if gid == current:
		return
	current = gid
	_save()
	link_restart()


func leave_group(gid: String) -> void:
	for g in groups:
		if str(g["gid"]) == gid:
			groups.erase(g)
			break
	if current == gid:
		current = str(groups[0]["gid"]) if not groups.is_empty() else ""
		link_restart()
	_save()
	changed.emit()


func rename_group(name: String, color: int) -> void:
	var g := group()
	if g.is_empty():
		return
	g["name"] = name.strip_edges()
	g["color"] = color
	_save()
	_share_group()
	changed.emit()


## The owner pasted a new key (it was expiring, or the old invite code had to stop working).
func renew_key(key: String) -> void:
	var g := group()
	if g.is_empty():
		return
	g["key"] = key.strip_edges()
	g["key_made"] = int(Time.get_unix_time_from_system())
	_save()
	_share_group()
	changed.emit()


## The members who are online get the group as the owner has it now (a new name, a new key): their
## games keep working when the old key runs out, without a new invite code.
func _share_group() -> void:
	if not is_owner():
		return
	var g := group()
	for id in conns:
		(conns[id] as NetConn).send({"k": "group", "gid": g["gid"], "name": g["name"], "color": int(g["color"]), "key": g["key"], "t": int(g["key_made"])})


# ------------------------------------------------------------------ Crossroads Link

func _bin_name() -> String:
	match OS.get_name():
		"macOS":
			return "crossroads-link-darwin-%s.bin" % ("arm64" if Engine.get_architecture_name() in ["arm64", "arm64v8"] else "amd64")
		"Windows":
			return "crossroads-link-windows-amd64.bin"
		"Linux":
			return "crossroads-link-linux-amd64.bin"
	return ""


## Crossroads Link, out of the game's files into the saves folder, ready to run. "" when this
## computer has no copy of it.
func _link_path() -> String:
	var nm := _bin_name()
	if nm == "" or not FileAccess.file_exists("res://netbin/" + nm):
		return ""
	DirAccess.make_dir_recursive_absolute(DIR + "bin")
	var ver := str(ProjectSettings.get_setting("application/config/version", "0"))
	var out := DIR + "bin/crossroads-link-" + ver + (".exe" if OS.get_name() == "Windows" else "")
	var real := ProjectSettings.globalize_path(out)
	if not FileAccess.file_exists(out):
		var src := FileAccess.get_file_as_bytes("res://netbin/" + nm)
		if src.is_empty():
			return ""
		var f := FileAccess.open(out, FileAccess.WRITE)
		if f == null:
			return ""
		f.store_buffer(src)
		f.close()
		if OS.get_name() != "Windows":
			OS.execute("chmod", ["755", real])
		# (the older versions' copies go)
		for old in DirAccess.get_files_at(DIR + "bin"):
			if old.begins_with("crossroads-link-") and DIR + "bin/" + old != out:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR + "bin/" + old))
	return real


func _free_port() -> int:
	for i in 40:
		var p := 42000 + randi() % 20000
		var t := TCPServer.new()
		if t.listen(p, "127.0.0.1") == OK:
			t.stop()
			return p
	return 0


func _listen(port: int) -> bool:
	server = TCPServer.new()
	if server.listen(port, "127.0.0.1") != OK:
		server = null
		return false
	game_port = port
	return true


## Start the link for the group in use. Nothing happens without a group.
func link_start() -> void:
	if local or link_pid > 0:
		return
	var g := group()
	if g.is_empty():
		link_state = "off"
		changed.emit()
		return
	_make_id()
	var path := _link_path()
	if path == "":
		link_state = "error"
		link_error = Loc.t("Online duels are not part of this copy of the game.")
		changed.emit()
		return
	if server == null:
		var gp := _free_port()
		if gp == 0 or not _listen(gp):
			link_state = "error"
			link_error = Loc.t("The game could not open its own port on this computer.")
			changed.emit()
			return
	_ctl = _free_port()
	_dial = _free_port()
	_token = "%08x%08x%08x" % [randi(), randi(), randi()]
	var gdir := ProjectSettings.globalize_path(DIR + str(g["gid"]))
	DirAccess.make_dir_recursive_absolute(gdir)
	var keyfile := gdir.path_join("key.txt")
	var kf := FileAccess.open(keyfile, FileAccess.WRITE)
	if kf:
		kf.store_string(str(g["key"]))
		kf.close()
	link_pid = OS.create_process(path, ["-dir", gdir, "-ctl", str(_ctl), "-dial", str(_dial), "-game", str(game_port),
		"-hostname", me_id, "-token", _token, "-keyfile", keyfile, "-idle", str(LINK_IDLE)], false)
	if link_pid <= 0:
		link_pid = -1
		link_state = "error"
		link_error = Loc.t("Crossroads Link did not start on this computer.")
	else:
		link_state = "starting"
		link_error = ""
		print("NET link started, pid ", link_pid, " as ", me_id)
	_last_status = 0
	changed.emit()


func link_stop() -> void:
	if link_pid > 0:
		_http("/quit", func(_r): pass)
		OS.kill(link_pid)
		link_pid = -1
	for id in conns.keys():
		(conns[id] as NetConn).close("left the group")
	conns.clear()
	members.clear()
	if not local:
		link_state = "off"


func link_restart() -> void:
	link_stop()
	link_start()
	changed.emit()


func _http(path: String, done: Callable) -> void:
	var rq := HTTPRequest.new()
	rq.timeout = 8.0
	add_child(rq)
	rq.request_completed.connect(func(result: int, code: int, _h, body: PackedByteArray):
		rq.queue_free()
		var v = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
		done.call(v))
	if rq.request("http://127.0.0.1:%d%s" % [_ctl, path], ["X-Token: " + _token]) != OK:
		rq.queue_free()
		done.call(null)


func _poll_status() -> void:
	if _http_busy:
		return
	_http_busy = true
	_http("/status", func(v):
		_http_busy = false
		if v == null:
			if link_state == "starting" and Time.get_ticks_msec() - _last_status < 30000:
				return
			if link_pid > 0 and not OS.is_process_running(link_pid):
				link_pid = -1
				link_state = "error"
				link_error = Loc.t("Crossroads Link stopped.")
				changed.emit()
			return
		_read_status(v))


func _read_status(v: Dictionary) -> void:
	var was := link_state
	var st := str(v.get("state", ""))
	# (the last thing Tailscale said went wrong, in its words: it tells a key it doesn't take from no internet)
	var last := ""
	for hl in v.get("health", []):
		var t := str(hl)
		var at := t.find("last login error was:")
		if at >= 0:
			last = t.substr(at + 21).strip_edges()
	if last == "" and str(v.get("error", "")) != "":
		last = str(v.get("error", ""))
	var low := last.to_lower()
	link_why = ""
	if st == "Running":
		link_state = "running"
		link_error = ""
	elif low != "" and ("expired" in low):
		link_state = "needs_key"
		link_why = "expired"
		link_error = Loc.t("The group's key has run out. The owner makes a new one (Owner tools > New invite code).")
	elif low != "" and ("invalid key" in low or "not valid" in low or "authkey" in low or "auth key" in low or "no key" in low or "not found" in low):
		link_state = "needs_key"
		link_why = "bad_key"
		link_error = Loc.t("Tailscale doesn't take the group's key. The owner can make a new one (Owner tools > New invite code).")
	elif low != "" and ("fetch control key" in low or "dial" in low or "forbidden" in low or "timeout" in low or "no such host" in low or "connection" in low):
		link_state = "error"
		link_why = "offline"
		link_error = Loc.t("The game can't reach Tailscale right now. Check the internet connection; it keeps trying by itself.")
	elif st == "Error":
		link_state = "error"
		link_error = last
	elif st in ["NeedsLogin", "NeedsMachineAuth"] and str(v.get("auth_url", "")) != "":
		link_state = "needs_key"
		link_why = "bad_key"
		link_error = Loc.t("Tailscale doesn't take the group's key. The owner can make a new one (Owner tools > New invite code).")
	else:
		link_state = "starting"
	if last != "" and _log:
		print("NET link says: ", last)
	var me: Dictionary = v.get("self", {}) if v.get("self") is Dictionary else {}
	self_ip = str(me.get("ip", ""))
	self_addrs = int(me.get("addrs", 0))
	tailnet = str(v.get("tailnet", ""))
	var seen := {}
	for p in v.get("peers", []):
		var host := str(p.get("host", ""))
		if not host.begins_with(HOST_PREFIX) or host == me_id:
			continue
		# (an older copy of the same member that has not been forgotten yet: the one that is online wins)
		if seen.has(host) and not bool(p.get("online", false)):
			continue
		seen[host] = true
		var m: Dictionary = members.get(host, {"id": host, "hello": {}, "ms": -1, "status": "idle"})
		m["ip"] = str(p.get("ip", ""))
		m["online"] = bool(p.get("online", false))
		m["direct"] = bool(p.get("direct", false))
		m["last_seen"] = int(p.get("last_seen", 0))
		members[host] = m
	for id in members.keys():
		if not seen.has(id):
			members.erase(id)
	if was != link_state:
		print("NET link ", link_state, " ", link_error)
	changed.emit()


func _ping(id: String) -> void:
	var m: Dictionary = members.get(id, {})
	if m.is_empty() or str(m.get("ip", "")) == "":
		return
	_ping_at[id] = Time.get_ticks_msec()
	_http("/ping?ip=" + str(m["ip"]), func(v):
		if v is Dictionary and members.has(id) and str(v.get("error", "")) == "":
			members[id]["ms"] = int(round(float(v.get("ms", -1))))
			members[id]["direct"] = bool(v.get("direct", false))
			changed.emit())


# ------------------------------------------------------------------ the people in the group

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _status_at > 1000:
		_status_at = now
		_auto_status()
	if not local and link_pid > 0:
		var every := 2000 if (lobby_open or session != null or link_state != "running") else 6000
		if now - _last_status > every:
			_last_status = now
			_poll_status()
	if server != null:
		while server.is_connection_available():
			var c := NetConn.accepted(server.take_connection(), not local)
			_adopt(c)
	for c in _loose.duplicate():
		(c as NetConn).poll()
	for id in conns.keys():
		var c: NetConn = conns.get(id)
		if c != null:
			c.poll()
	if link_state == "running":
		_reach_out(now)


var _status_at := 0

## What the others see: in a duel (or about to start one), free (at the menus), or away (playing
## something else: a story, Free Roam, the Academy). Challenges only reach people who are free.
func _auto_status() -> void:
	if session != null:
		return
	if bool(challenge_out.get("accepted", false)):
		set_status("busy")
		return
	var sc := get_tree().current_scene
	var at_menu := sc != null and sc.scene_file_path == Router.MAIN_MENU
	set_status("idle" if at_menu or local else "away")


## Somebody in the group without a line to them: the copy with the smaller name calls (so the two
## never call each other at once); if it has not called after a while, the other one does.
func _reach_out(now: int) -> void:
	var want: Array = []
	if local:
		for p in _local_peers:
			want.append([HOST_PREFIX + "local-" + str(p).get_slice(":", 1), p])
	else:
		for id in members:
			if bool(members[id].get("online", false)):
				want.append([id, str(members[id]["ip"])])
	for w in want:
		var id: String = w[0]
		if conns.has(id) or now < int(_dial_wait.get(id, 0)):
			continue
		var waited := now - int(_dial_wait.get(id + "|first", now))
		if not _dial_wait.has(id + "|first"):
			_dial_wait[id + "|first"] = now
		if me_id < id or waited > 9000:
			_dial_wait[id] = now + 5000
			var c: NetConn
			if local:
				c = NetConn.dial("127.0.0.1", int(str(w[1]).get_slice(":", 1)))
			else:
				c = NetConn.dial("127.0.0.1", _dial, str(w[1]), _token)
			c.peer = id
			_adopt(c)
		if lobby_open and not local and now - int(_ping_at.get(id, 0)) > 10000:
			_ping(id)


func _adopt(c: NetConn) -> void:
	_loose.append(c)
	c.opened.connect(func(): c.send(_hello()))
	if c.is_open():
		c.send(_hello())
	c.message.connect(func(msg): _on_message(c, msg))
	c.closed.connect(func(why): _on_closed(c, why))


func _hello() -> Dictionary:
	var g := group()
	var look := {}
	for k in ["look_body", "look_hair", "look_outfit", "look_height", "look_build", "look_skin", "look_haircol", "look_eyes",
			"look_top", "look_bottom", "look_shoes", "color_index", "style", "gender", "emblem"]:
		look[k] = int(Profile.get(k))
	return {"k": "hello", "id": me_id, "name": Profile.duelist_name, "title": Profile.title_text(), "look": look,
		"voice": int(Settings.voice_me), "intro": int(Profile.intro), "win_line": int(Profile.win_line),
		"version": str(ProjectSettings.get_setting("application/config/version", "")), "gid": str(g.get("gid", "local")),
		"status": status, "score": self_addrs, "wins": int(Profile.wins), "losses": int(Profile.losses)}


var _log := OS.has_environment("NET_LOG")

func _on_message(c: NetConn, msg: Dictionary) -> void:
	var k := str(msg.get("k", ""))
	if _log:
		print("NET in ", k, " from ", c.peer, " ", str(msg).left(160) if k != "step" else "i=%d" % int(msg.get("i", -1)))
	if k == "hello":
		var id := str(msg.get("id", ""))
		if not id.begins_with(HOST_PREFIX) or id == me_id:
			c.close("not a copy of the game")
			return
		if not local and str(msg.get("gid", "")) != current:
			c.close("another group")
			return
		c.peer = id
		c.hello = msg
		_loose.erase(c)
		var old: NetConn = conns.get(id)
		if old != null and old != c:
			# (both called at once, or it came back: the newer line is the one)
			conns.erase(id)
			old.close("replaced")
		conns[id] = c
		var m: Dictionary = members.get(id, {"id": id, "ms": -1, "online": true, "ip": c.addr})
		m["hello"] = msg
		m["status"] = str(msg.get("status", "idle"))
		m["online"] = true
		members[id] = m
		_guest_look(id, msg)
		if is_owner():
			_share_group()
		if session != null:
			session.on_reconnect(id)
		changed.emit()
		if auto == "challenge" and challenge_out.is_empty() and session == null:
			get_tree().create_timer(1.0).timeout.connect(func(): _auto_challenge(id))
		return
	if c.peer == "" or not conns.has(c.peer):
		return      # (nothing is taken from a copy that has not said who it is)
	var from := c.peer
	match k:
		"status":
			if members.has(from):
				members[from]["status"] = str(msg.get("status", "idle"))
				changed.emit()
		"group":
			_take_group(msg)
		"challenge":
			msg["from"] = from
			if status != "idle" or session != null or not challenge_out.is_empty():
				c.send({"k": "decline", "cid": msg.get("cid", ""), "why": "away" if status == "away" else "busy"})
				return
			challenges_in[str(msg["cid"])] = msg
			challenged.emit(msg)
			if auto == "":
				ChallengeCard.show_for(msg)
			if auto == "accept":
				if bool(msg.get("anime", false)):
					var a: Array = anime_decks()[int(OS.get_environment("NET_ANIME_ME")) if OS.get_environment("NET_ANIME_ME") != "" else 0]
					get_tree().create_timer(0.5).timeout.connect(func(): accept(str(msg["cid"]), str(a[1]), str(a[0])))
				else:
					get_tree().create_timer(0.5).timeout.connect(func(): accept(str(msg["cid"]), _auto_deck()))
		"cancel":
			challenges_in.erase(str(msg.get("cid", "")))
			answered.emit({"cid": msg.get("cid", ""), "from": from, "cancelled": true})
		"accept", "decline":
			if str(challenge_out.get("cid", "")) != str(msg.get("cid", "")):
				return
			msg["from"] = from
			if k == "decline":
				challenge_out = {}
				answered.emit(msg)
				return
			_on_accepted(msg)
		"go":
			_on_go(from, msg)
		_:
			if msg.has("sid") and session != null:
				session.handle(from, msg)
			else:
				session_message.emit(msg)


func _on_closed(c: NetConn, why: String) -> void:
	_loose.erase(c)
	if c.peer != "" and conns.get(c.peer) == c:
		conns.erase(c.peer)
		print("NET line to ", c.peer, " closed: ", why)
		if session != null:
			session.on_drop(c.peer)
		if str(challenge_out.get("to", "")) == c.peer and session == null:
			challenge_out = {}
			answered.emit({"cid": "", "from": c.peer, "gone": true})
		changed.emit()


func _take_group(msg: Dictionary) -> void:
	for g in groups:
		if str(g["gid"]) == str(msg.get("gid", "")) and not bool(g.get("owner", false)):
			g["name"] = str(msg.get("name", g["name"]))
			g["color"] = int(msg.get("color", g["color"]))
			if int(msg.get("t", 0)) > int(g.get("key_made", 0)):
				g["key"] = str(msg.get("key", g["key"]))
				g["key_made"] = int(msg.get("t", 0))
			_save()
			changed.emit()


func send_to(id: String, msg: Dictionary) -> bool:
	var c: NetConn = conns.get(id)
	if c == null or not c.is_open():
		return false
	c.send(msg)
	return true


func set_status(s: String) -> void:
	if s == status:
		return
	status = s
	for id in conns:
		(conns[id] as NetConn).send({"k": "status", "status": s})


## The people in the group, for the lobby: online first, then by name.
func people() -> Array:
	var out: Array = []
	for id in members:
		var m: Dictionary = members[id]
		var h: Dictionary = m.get("hello", {})
		out.append({"id": id, "name": str(h.get("name", str(id).trim_prefix(HOST_PREFIX).rsplit("-", true, 1)[0])),
			"title": str(h.get("title", "")), "online": bool(m.get("online", false)) and conns.has(id),
			"reachable": bool(m.get("online", false)), "status": str(m.get("status", "idle")), "ms": int(m.get("ms", -1)),
			"direct": bool(m.get("direct", false)), "version": str(h.get("version", "")), "color": int((h.get("look", {}) as Dictionary).get("color_index", 0)),
			"key": "net:" + id, "known": not h.is_empty(), "last_seen": int(m.get("last_seen", 0))})
	if local:
		for id in conns:
			if not members.has(id):
				var h2: Dictionary = (conns[id] as NetConn).hello
				out.append({"id": id, "name": str(h2.get("name", id)), "title": str(h2.get("title", "")), "online": true, "reachable": true,
					"status": "idle", "ms": 1, "direct": true, "version": str(h2.get("version", "")), "color": 0, "key": "net:" + id, "known": true})
	out.sort_custom(func(a, b): return [not a["online"], str(a["name"]).to_lower()] < [not b["online"], str(b["name"]).to_lower()])
	return out


func person(id: String) -> Dictionary:
	for p in people():
		if p["id"] == id:
			return p
	return {}


## Connection bars for a member: 0 (none) to 4.
static func bars(ms: int, direct: bool) -> int:
	if ms < 0:
		return 0
	var b := 4 if ms < 60 else (3 if ms < 120 else (2 if ms < 250 else 1))
	if not direct:
		b = mini(b, 3)
	return b


# ------------------------------------------------------------------ what the others look like

## A member's duelist is shown with their own look: portraits, the figure across the table and the
## lines they say are made from what they sent (see Avatars.guests and Characters.GUESTS).
func _guest_look(id: String, h: Dictionary) -> void:
	var key := "net:" + id
	var look: Dictionary = (h.get("look", {}) as Dictionary).duplicate()
	look["duelist_name"] = str(h.get("name", "Duelist"))
	Avatars.guests[key] = look
	var styles: Array = Profile.STYLES
	var st := int(look.get("style", 0))
	var col: Color = Profile.COLORS[clampi(int(look.get("color_index", 0)), 0, Profile.COLORS.size() - 1)]
	Characters.GUESTS[key] = {"name": str(h.get("name", "Duelist")), "short": str(h.get("name", "Duelist")), "title": str(h.get("title", "")),
		"color": col, "personality": str(styles[st]) if st > 0 and st < styles.size() else "kind", "era": "Crossroads",
		"deck": "", "voice_pick": int(h.get("voice", 0)), "body": int(look.get("look_body", 0)),
		"intro_line": int(h.get("intro", 0)), "win_line": int(h.get("win_line", 0)), "online": true}
	Portraits.forget_key(key)


# ------------------------------------------------------------------ challenges

## The decks you can take online: complete ones only (every card owned, a legal size), the same
## rule as everywhere else. [[deck key, name], ...]
static func decks() -> Array:
	var out: Array = []
	if CardData.has_deck("custom") and Collection.deck_ok():
		out.append(["custom", CardData.deck_name("custom")])
	for md in Collection.my_decks():
		if not md["open"]:
			out.append([str(md["key"]), str(md["name"])])
	for k in Collection.decks_owned:
		if CardData.has_deck(str(k)) and not str(k) in ["custom"]:
			out.append([str(k), CardData.deck_name(str(k))])
	# (the same deck twice, a starter that is also the open deck as it came: once)
	var seen := {}
	var kept: Array = []
	for d in out:
		var sig := "%s|%s" % [str(d[1]), str(CardData.deck_list(str(d[0])).size())]
		if seen.has(sig):
			continue
		seen[sig] = true
		kept.append(d)
	return kept


## (0.79.0) The "Anime decks only" rule: the show's duelists with the decks they had in the anime,
## nothing else (no own duelist, no own decks, no Competitive). [[character key, deck key, name], ...]
static func anime_decks() -> Array:
	var out: Array = []
	for k in Characters.ORDER:
		var base := str(Characters.get_char(str(k)).get("deck", ""))
		for v in DeckTiers.versions_of(base):
			if not v in DeckTiers.ANIME_VERSIONS:
				continue
			var dk := DeckTiers.anime_key(base, str(v))
			if dk != "" and CardData.has_deck(dk):
				out.append([str(k), dk, Loc.t(CardData.deck_name(dk))])
	return out


## Is this one of the anime-only rule's picks (a show duelist with one of their own anime decks)?
static func anime_pick_ok(char_key: String, deck_key: String) -> bool:
	for a in anime_decks():
		if str(a[0]) == char_key and str(a[1]) == deck_key:
			return true
	return false


static func deck_lists(key: String) -> Dictionary:
	var main: Array = []
	var extra: Array = []
	var side: Array = []
	for id in CardData.deck_list(key):
		main.append(int(id))
	for id in CardData.extra_list(key):
		extra.append(int(id))
	if key == "custom":
		for id in Collection.side:
			side.append(int(id))
	elif key.begins_with("slot:"):
		var i := int(key.substr(5))
		if i >= 0 and i < Collection.slots.size():
			for id in (Collection.slots[i] as Dictionary).get("side", []):
				side.append(int(id))
	return {"main": main, "extra": extra, "side": side, "name": CardData.deck_name(key)}


## What is wrong with a deck for an online duel ("" = nothing). `fl`: the Forbidden/Limited list is on.
static func deck_problem(d: Dictionary, fl: bool) -> String:
	var main: Array = d.get("main", [])
	var extra: Array = d.get("extra", [])
	var side: Array = d.get("side", [])
	if main.size() < Collection.MAIN_MIN or main.size() > Collection.MAIN_MAX:
		return Loc.t("The Main Deck must have 40 to 60 cards.")
	if extra.size() > Collection.EXTRA_MAX or side.size() > Collection.SIDE_MAX:
		return Loc.t("The Extra Deck and the Side Deck hold 15 cards at most.")
	var n := {}
	for id in main + extra + side:
		if CardData.get_card(int(id)).is_empty() and OcgCore.card_name(int(id)) == "":
			return Loc.t("The deck has a card this version of the game does not know.")
		n[int(id)] = int(n.get(int(id), 0)) + 1
	for id in n:
		var nm := str(CardData.get_card(int(id)).get("name", ""))
		var most := 3
		if fl:
			most = 0 if nm in Collection.FORBIDDEN else (1 if nm in Collection.LIMITED else (2 if nm in Collection.SEMI_LIMITED else 3))
		if int(n[id]) > most:
			return Loc.t("%s: %d copies, the list allows %d.") % [nm, int(n[id]), most]
	return ""


## Challenge a member. opts: {deck, mode ("single" / "match"), fl (Forbidden/Limited list), lp}
func challenge(id: String, opts: Dictionary) -> bool:
	if session != null or not challenge_out.is_empty():
		return false
	var cid := "%08x" % randi()
	challenge_out = {"cid": cid, "to": id, "opts": opts, "at": Time.get_ticks_msec()}
	var ok := send_to(id, {"k": "challenge", "cid": cid, "mode": str(opts.get("mode", "single")), "fl": bool(opts.get("fl", true)),
		"lp": int(opts.get("lp", 8000)), "destiny": bool(opts.get("destiny", Settings.destiny_draw)),
		"anime": bool(opts.get("anime", false)), "char": str(opts.get("char", "")),
		"deck_name": str(deck_lists(str(opts["deck"]))["name"]), "score": self_addrs})
	if not ok:
		challenge_out = {}
	return ok


func cancel_challenge() -> void:
	if challenge_out.is_empty():
		return
	send_to(str(challenge_out["to"]), {"k": "cancel", "cid": challenge_out["cid"]})
	challenge_out = {}


func decline(cid: String, why := "no") -> void:
	var ch: Dictionary = challenges_in.get(cid, {})
	challenges_in.erase(cid)
	if not ch.is_empty():
		send_to(str(ch["from"]), {"k": "decline", "cid": cid, "why": why})


## Accept a challenge with one of your decks. The challenger then says who hosts the duel (see _on_accepted).
func accept(cid: String, deck_key: String, my_char := "") -> void:
	var ch: Dictionary = challenges_in.get(cid, {})
	if ch.is_empty():
		return
	challenges_in.erase(cid)
	for other in challenges_in.keys():
		decline(str(other), "busy")
	ch["deck"] = deck_key
	var anime := bool(ch.get("anime", false))
	challenge_out = {"cid": cid, "to": str(ch["from"]), "opts": {"deck": deck_key, "mode": ch["mode"], "fl": ch["fl"], "lp": ch["lp"],
		"destiny": bool(ch.get("destiny", false)), "anime": anime, "char": my_char if anime else "",
		"their_char": str(ch.get("char", "")) if anime else ""}, "accepted": true}
	set_status("busy")
	send_to(str(ch["from"]), {"k": "accept", "cid": cid, "score": self_addrs, "deck_name": str(deck_lists(deck_key)["name"]),
		"char": my_char if anime else "", "deck_key": deck_key if anime else ""})


## They said yes. The host is the one with the easier connection (more ways in); the challenger
## when it is even. The guest sends its deck to the host; the host never sends its own.
func _on_accepted(msg: Dictionary) -> void:
	var them := str(msg["from"])
	var o: Dictionary = challenge_out["opts"]
	if bool(o.get("anime", false)):
		# (anime decks only: their pick has to be a show duelist with one of their anime decks)
		if not anime_pick_ok(str(msg.get("char", "")), str(msg.get("deck_key", ""))):
			send_to(them, {"k": "cancel", "cid": msg["cid"]})
			challenge_out = {}
			answered.emit({"cid": msg["cid"], "from": them, "why": "rule"})
			return
		o["their_char"] = str(msg.get("char", ""))
	var mine := self_addrs
	var theirs := int(msg.get("score", 0))
	var host := me_id if mine >= theirs else them
	var sid := "%08x%08x" % [randi(), randi()]
	var why := "even" if mine == theirs else "connection"
	set_status("busy")
	send_to(them, {"k": "go", "cid": msg["cid"], "sid": sid, "host": host, "why": why})
	_begin(them, sid, host == me_id, challenge_out["opts"], why, true)


func _on_go(from: String, msg: Dictionary) -> void:
	if str(challenge_out.get("cid", "")) != str(msg.get("cid", "")) or not bool(challenge_out.get("accepted", false)):
		return
	_begin(from, str(msg["sid"]), str(msg["host"]) == me_id, challenge_out["opts"], str(msg.get("why", "")), false)


## Both know who hosts: the duel screen opens on both sides (see NetDuel).
func _begin(peer: String, sid: String, hosting: bool, opts: Dictionary, why: String, challenger: bool) -> void:
	challenge_out = {}
	var nd := NetDuel.new()
	nd.peer = peer
	nd.sid = sid
	nd.host = hosting
	nd.challenger = challenger
	nd.opts = opts.duplicate()
	nd.deck = deck_lists(str(opts["deck"]))
	nd.host_why = why
	session = nd
	set_status("duel")
	print("NET duel ", sid, " with ", peer, " hosting: ", hosting)
	nd.begin()


func end_session() -> void:
	session = null
	set_status("idle")


# ------------------------------------------------------------------ your record against each member

static var RECORD := DIR + "record.json"

func record_all() -> Dictionary:
	var v = JSON.parse_string(FileAccess.get_file_as_string(RECORD)) if FileAccess.file_exists(RECORD) else null
	return v if v is Dictionary else {}


func record_of(id: String) -> Dictionary:
	return record_all().get(id, {"w": 0, "l": 0, "d": 0})


func record_result(id: String, name: String, result: int) -> void:
	var all := record_all()
	var r: Dictionary = all.get(id, {"w": 0, "l": 0, "d": 0})
	r["name"] = name
	match result:
		1: r["w"] = int(r["w"]) + 1
		-1: r["l"] = int(r["l"]) + 1
		_: r["d"] = int(r["d"]) + 1
	r["last"] = int(Time.get_unix_time_from_system())
	all[id] = r
	var f := FileAccess.open(RECORD, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(all, "\t"))


# ------------------------------------------------------------------ dev: two copies that play by themselves

func _auto_deck() -> String:
	if OS.get_environment("NET_DECK") != "":
		return OS.get_environment("NET_DECK")
	var ds := decks()
	if ds.is_empty():
		return "yugi"
	return str(ds[0][0])


func _auto_challenge(id: String) -> void:
	if session != null or not challenge_out.is_empty():
		return
	var mode := "match" if "--net-match" in OS.get_cmdline_user_args() else "single"
	if OS.get_environment("NET_ANIME") != "":
		# (dev: the "Anime decks only" rule, with the pick at that index of anime_decks())
		var a: Array = anime_decks()[int(OS.get_environment("NET_ANIME"))]
		challenge(id, {"deck": str(a[1]), "mode": mode, "fl": false, "lp": 8000, "anime": true, "char": str(a[0])})
		return
	challenge(id, {"deck": _auto_deck(), "mode": mode, "fl": false, "lp": 8000})
