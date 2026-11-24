class_name NetConn
extends RefCounted
## One connection to another copy of the game (0.73.0, online duels).
##
## Under it is a plain TCP connection on this computer: to Crossroads Link (the small program that
## carries it over the Duel Group's private network, see tools/netlink) or, in a test on one
## computer, straight to the other copy. Over it go messages: Dictionaries of numbers, strings and
## arrays (never objects), each one framed by its length, the larger ones compressed.
##
## A connection only carries messages. What a lost connection means (a duel waiting for someone to
## come back, the catch-up after) is up to whoever uses it: see NetDuel.

signal message(msg: Dictionary)
signal opened
signal closed(why: String)

enum { DIALING, HANDSHAKE, OPEN, CLOSED }

var tcp: StreamPeerTCP
var state := DIALING
var inbound := false
var peer := ""              # the other copy's id, once it said hello
var addr := ""              # where it is: a member's address in the group, or 127.0.0.1:port in a local test
var host_name := ""         # its name in the group (from Crossroads Link)
var hello := {}             # what it said about itself
var _first_line := ""       # through Crossroads Link: the line it sends before the messages start
var _want_line := false
var _dial_token := ""
var _buf := PackedByteArray()
var _out: Array = []        # [due msec, bytes] while a test makes the line slow
var _in: Array = []         # [due msec, Dictionary]
var _since := 0
var _last_in := 0
var _last_beat := 0
var sent := 0
var got := 0
var bytes_out := 0
var bytes_in := 0

const MAX_FRAME := 8 << 20
const BEAT_MS := 4000        # a message at least this often, so a dead line is noticed
const DEAD_MS := 15000       # nothing from them for this long: the line is gone

## Dev: a bad line for testing (NET_LAG=200 ms each way, NET_JITTER=80, NET_DROP=0.02: the chance that
## a message sent ends the connection, as a line that drops now and then would).
static var lag_ms := int(OS.get_environment("NET_LAG")) if OS.has_environment("NET_LAG") else 0
static var jitter_ms := int(OS.get_environment("NET_JITTER")) if OS.has_environment("NET_JITTER") else 0
static var drop_p := float(OS.get_environment("NET_DROP")) if OS.has_environment("NET_DROP") else 0.0


## A connection to make: `through_link` is the dial port of Crossroads Link and `token` its secret;
## without them `host`:`port` is dialed directly (a test with two copies on one computer).
static func dial(host: String, port: int, member_ip := "", token := "") -> NetConn:
	var c := NetConn.new()
	c.tcp = StreamPeerTCP.new()
	c.addr = member_ip if member_ip != "" else "%s:%d" % [host, port]
	c._dial_token = token
	c._want_line = token != ""
	c._since = Time.get_ticks_msec()
	if c.tcp.connect_to_host(host, port) != OK:
		c.state = CLOSED
	return c


## A connection that came in on the game's own port. Through Crossroads Link its first line says
## who it is from ("FROM <ip> <name>").
static func accepted(peer_tcp: StreamPeerTCP, via_link: bool) -> NetConn:
	var c := NetConn.new()
	c.tcp = peer_tcp
	c.inbound = true
	c._want_line = via_link
	c.state = HANDSHAKE if via_link else OPEN
	c._since = Time.get_ticks_msec()
	c._last_in = c._since
	return c


func is_open() -> bool:
	return state == OPEN


func send(msg: Dictionary) -> void:
	if state == CLOSED:
		return
	var body := var_to_bytes(msg)
	var flag := 0
	if body.size() > 600:
		var z := body.compress(FileAccess.COMPRESSION_DEFLATE)
		if z.size() < body.size():
			var raw := body.size()
			body = PackedByteArray()
			body.resize(4)
			body.encode_u32(0, raw)
			body.append_array(z)
			flag = 0x80000000
	var frame := PackedByteArray()
	frame.resize(4)
	frame.encode_u32(0, body.size() | flag)
	frame.append_array(body)
	sent += 1
	bytes_out += frame.size()
	_last_beat = Time.get_ticks_msec()
	if lag_ms > 0 or jitter_ms > 0:
		var due := Time.get_ticks_msec() + lag_ms + (randi() % (jitter_ms + 1) if jitter_ms > 0 else 0)
		# (in order: a later message never overtakes an earlier one, as on a real line)
		if not _out.is_empty():
			due = maxi(due, int(_out[-1][0]))
		_out.append([due, frame])
	elif state == OPEN:
		tcp.put_data(frame)
	else:
		_out.append([0, frame])
	if drop_p > 0.0 and state == OPEN and randf() < drop_p and str(msg.get("k", "")) not in ["hello", "beat"]:
		close("test drop")


func close(why := "closed") -> void:
	if state == CLOSED:
		return
	state = CLOSED
	if tcp != null:
		tcp.disconnect_from_host()
	closed.emit(why)


## Called every frame by Net: moves bytes in and out and hands over whole messages.
func poll() -> void:
	if state == CLOSED:
		return
	tcp.poll()
	var st := tcp.get_status()
	var now := Time.get_ticks_msec()
	if state == DIALING:
		if st == StreamPeerTCP.STATUS_CONNECTED:
			if _dial_token != "":
				tcp.put_data(("DIAL %s %s\n" % [_dial_token, addr]).to_utf8_buffer())
				state = HANDSHAKE
			else:
				_open()
		elif st == StreamPeerTCP.STATUS_ERROR or (st == StreamPeerTCP.STATUS_NONE and now - _since > 200) or now - _since > 12000:
			close("could not connect")
			return
		else:
			return
	if st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE:
		close("the line dropped")
		return
	var n := tcp.get_available_bytes()
	if n > 0:
		var r: Array = tcp.get_partial_data(n)
		if int(r[0]) == OK:
			_buf.append_array(r[1])
			bytes_in += (r[1] as PackedByteArray).size()
			_last_in = now
	if state == HANDSHAKE:
		var nl := _buf.find(10)
		if nl < 0:
			if now - _since > 25000:
				close("the other side did not answer")
			return
		var line := _buf.slice(0, nl).get_string_from_utf8().strip_edges()
		_buf = _buf.slice(nl + 1)
		_first_line = line
		if inbound:
			var f := line.split(" ")
			if f.size() >= 2 and f[0] == "FROM":
				addr = f[1]
				host_name = f[2] if f.size() >= 3 else ""
		elif not line.begins_with("OK"):
			close(line.trim_prefix("ERR ") if line.begins_with("ERR") else "could not connect")
			return
		_open()
	if state != OPEN:
		return
	# Whole frames out of what came in.
	while _buf.size() >= 4:
		var head := _buf.decode_u32(0)
		var size := head & 0x7fffffff
		if size > MAX_FRAME:
			close("a message that makes no sense")
			return
		if _buf.size() < 4 + size:
			break
		var body := _buf.slice(4, 4 + size)
		_buf = _buf.slice(4 + size)
		if head & 0x80000000:
			var raw := body.decode_u32(0)
			if raw > MAX_FRAME:
				close("a message that makes no sense")
				return
			body = body.slice(4).decompress(raw, FileAccess.COMPRESSION_DEFLATE)
		var v = bytes_to_var(body)      # (objects are never decoded: plain data only)
		if v is Dictionary:
			got += 1
			if lag_ms > 0 or jitter_ms > 0:
				var due := now + lag_ms + (randi() % (jitter_ms + 1) if jitter_ms > 0 else 0)
				if not _in.is_empty():
					due = maxi(due, int(_in[-1][0]))
				_in.append([due, v])
			elif str((v as Dictionary).get("k", "")) != "beat":
				message.emit(v)
		if state != OPEN:
			return
	while not _in.is_empty() and int(_in[0][0]) <= now:
		var d: Dictionary = _in.pop_front()[1]
		if str(d.get("k", "")) != "beat":
			message.emit(d)
		if state != OPEN:
			return
	while not _out.is_empty() and int(_out[0][0]) <= now:
		tcp.put_data(_out.pop_front()[1])
	if now - _last_beat > BEAT_MS:
		send({"k": "beat"})
	if now - _last_in > DEAD_MS:
		close("no word from the other side")


func _open() -> void:
	state = OPEN
	_last_in = Time.get_ticks_msec()
	_last_beat = 0
	# (what was sent while it was still connecting goes now)
	var held := _out.duplicate()
	if lag_ms <= 0 and jitter_ms <= 0:
		_out.clear()
		for f in held:
			tcp.put_data(f[1])
	opened.emit()
