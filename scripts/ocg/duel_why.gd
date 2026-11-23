class_name DuelWhy
extends RefCounted
## Says why things happen in a duel, and why they don't. The rules engine applies every card
## right, but when an effect stops something (no damage, no attack) it simply sends nothing, and
## on screen that looks like the game forgot. This reads the same engine messages the table does
## and adds:
##   - "status" events: what is still in force for each player, from which card and until when
##     (One Day of Peace, Waboku, Threatening Roar, a face-up Gravity Bind...), shown by the Life Points;
##   - "why" events: the reason, the moment something expected does not happen ("No damage: One
##     Day of Peace", "Attack stopped: Swift Scarecrow", "Power Bond: no damage");
##   - "log" events: a line for the duel log for every point of damage and Life Points paid or
##     gained, with where it came from.
## It never changes the duel: it only reads.

const ME := 0

var turn := 0                 # the engine's turn count (1 = the first turn)
var turn_player := 0
var phase := 0
var names := ["", ""]         # the two duelists, for "until the end of Syrus's turn"

## Things in force from a card that resolved: {kind, players: [p...], id, name, until (turn), partial}
var lasting: Array = []
## The same for face-up cards on the field (worked out again whenever the field changes).
var standing: Array = []

var _links: Array = []        # the chain being built: [{id, con, name}]
var _solving := -1            # the link resolving now (index), or -1
var _link_hurt := false       # damage or Life Points happened while that link resolved
var _since_attack: Array = [] # cards that resolved since the last attack was declared: [{id, con, name}]
var _pending_battle := {}     # {victim, amount, attacker}
var _battle_src := ""         # the attacking monster's name while its battle runs
var _end_bills: Array = []    # "take damage in the End Phase" still to come: {p, turn, id, name}
var _hurt_this_end := [false, false]
var _shown: Array = [[], []]  # the status lists last sent (to send only changes)
var _field_dirty := true
var _told := {}               # reasons already shown on screen this turn
var _unpaid: Array = []      # Life Points paid as a cost, waiting for the card that asked for them


## Called for every engine message, before the table handles it. `duel` is the OcgDuel (for the
## cards on the field). Appends its own events to `ev`.
func read(m: Dictionary, ev: Array, duel) -> void:
	var t := int(m.get("t", -1))
	match t:
		40:
			_settle_battle(ev, duel)
			_settle_end_bills(ev)
			turn += 1
			turn_player = int(m.get("p", 0))
			phase = 0
			_hurt_this_end = [false, false]
			_since_attack.clear()
			var before := lasting.size()
			lasting = lasting.filter(func(l): return int(l["until"]) >= turn)
			if lasting.size() != before:
				_send_status(ev)
		41:
			_settle_battle(ev, duel)
			_battle_src = ""
			for u in _unpaid:
				ev.append(_log(int(u[0]), "−", Loc.t("Paid %d Life Points") % int(u[1])))
			_unpaid.clear()
			phase = int(m.get("phase", 0))
		10, 11:
			_settle_battle(ev, duel)
			_battle_src = ""
			if _field_dirty:
				_field_dirty = false
				_scan_field(duel)
				_send_status(ev)
		50:
			_field_dirty = true
			# A monster whose own effect spares its player battle damage once it is destroyed by battle
			# (Lumen): that is in force for the rest of the turn.
			var fr: Dictionary = m.get("from", {})
			if (int(m.get("reason", 0)) & 0x20) != 0 and int(fr.get("loc", 0)) == 4:
				var mid := int(m.get("code", 0)) & 0x7fffffff
				var md := card_text(mid)
				if md.contains("destroyed by battle") and md.contains("no battle damage this turn"):
					var e := {"kind": "no_bdmg", "players": [int(fr.get("con", 0))], "id": mid, "name": _name(mid), "until": turn}
					lasting.append(e)
					ev.append(_log(int(fr.get("con", 0)), "⏳", _sentence(e)))
					_send_status(ev)
		53, 54, 55, 56, 60, 62, 64:
			_field_dirty = true
		70:
			var cl: Dictionary = m.get("card", {})
			var id := int(cl.get("code", 0)) & 0x7fffffff
			_links.append({"id": id, "con": int(cl.get("con", 0)), "name": _name(id)})
			for u in _unpaid:
				ev.append(_log(int(u[0]), "−", (Loc.t("Paid %d Life Points") % int(u[1])) + " · " + _name(id)))
			_unpaid.clear()
		72:
			_solving = int(m.get("n", 0)) - 1
			_link_hurt = false
		73:
			if _solving >= 0 and _solving < _links.size():
				_resolved(_links[_solving], ev, duel)
			_solving = -1
		74:
			_links.clear()
			_solving = -1
			_field_dirty = true
		75, 76:
			# (negated: the link does nothing, so it starts nothing)
			var n := int(m.get("n", 0)) - 1
			if n >= 0 and n < _links.size():
				_links[n]["negated"] = true
		91, 100:
			var p := int(m.get("p", 0))
			var v := int(m.get("v", 0))
			if not _pending_battle.is_empty() and int(_pending_battle["victim"]) == p and t == 91:
				_pending_battle = {}
			if phase == 0x200:
				_hurt_this_end[p] = true
			_link_hurt = true
			var src := _source()
			if t == 91:
				ev.append(_log(p, "−", (Loc.t("%d damage") % v) + ((" · " + src) if src != "" else "")))
			elif src != "" or not _links.is_empty():
				# (a cost is paid as its card goes on the chain: the newest link asked for it)
				ev.append(_log(p, "−", (Loc.t("Paid %d Life Points") % v) + " · " + (src if src != "" else str(_links.back()["name"]))))
			else:
				_unpaid.append([p, v])
		92:
			var p := int(m.get("p", 0))
			_link_hurt = true
			var src := _source()
			ev.append(_log(p, "+", (Loc.t("Gained %d Life Points") % int(m.get("v", 0))) + ((" · " + src) if src != "" else "")))
		110:
			_settle_battle(ev, duel)
			_since_attack.clear()
			var a = duel._loc_card(m["a"]) if m.has("a") else null
			_battle_src = str(a.cname()) if a != null else ""
		111:
			_expect_battle(m, duel)
		112:
			# The attack stopped. Say by what.
			_pending_battle = {}
			var by := ""
			for s in _since_attack:
				by = str(s["name"])
			if by != "":
				ev.append(_why(-1, Loc.t("ATTACK STOPPED"), Loc.t("Stopped by %s.") % by, _id_of(by)))
			ev.append(_log(-1, "✋", Loc.t("Attack stopped") + ((" · " + by) if by != "" else "")))


## A link resolved (and was not negated): what it leaves in force, and damage it could not do.
func _resolved(link: Dictionary, ev: Array, duel) -> void:
	if link.get("negated", false):
		return
	_since_attack.append(link)
	var id := int(link["id"])
	var p := int(link["con"])
	var d := CardData.get_card(id)
	var desc := card_text(id)
	var frame := str(d.get("frame", ""))
	var race := spell_kind(id)
	# A card that bills its own player in the End Phase (Power Bond): remember it.
	if desc.contains("end phase") and (desc.contains("you take damage") or desc.contains("take damage equal")):
		_end_bills.append({"p": p, "turn": turn, "id": id, "name": str(link["name"])})
	# An effect that should have hurt someone, stopped by something still in force.
	if not _link_hurt and desc.contains("inflict") and desc.contains("damage") and not desc.contains("battle damage"):
		var stop := _blocker(1 - p, false)
		if not stop.is_empty():
			ev.append(_why(1 - p, Loc.t("NO DAMAGE"), Loc.t("%s did no damage: %s is in force.") % [str(link["name"]), str(stop["name"])], int(stop["id"])))
	# Spells and Traps that leave something in force for a while.
	if (frame == "spell" or frame == "trap") and race != "continuous" and race != "field" and race != "equip":
		for e in _lasting_from(desc, p, id, str(link["name"])):
			lasting.append(e)
			ev.append(_why(e["players"][0] if (e["players"] as Array).size() == 1 else -1, _title(e), _sentence(e), id))
			ev.append(_log(p, "⏳", _sentence(e)))
		_send_status(ev)


## What a Spell or Trap leaves in force, from its text.
func _lasting_from(desc: String, p: int, id: int, nm: String) -> Array:
	var out: Array = []
	var until := turn
	if desc.contains("until the end of the opponent's next turn") or desc.contains("until the end of your opponent's next turn"):
		until = turn + (1 if turn_player == p else 2)
	elif desc.contains("until the end of your next turn"):
		until = turn + (2 if turn_player == p else 1)
	if desc.contains("neither player takes any damage") or desc.contains("neither player takes damage") or desc.contains("neither player takes any battle damage"):
		out.append({"kind": "no_bdmg" if desc.contains("battle damage") else "no_dmg", "players": [0, 1], "id": id, "name": nm, "until": until})
	elif desc.contains("you take no damage") or desc.contains("you do not take any damage") or desc.contains("you take no effect damage") or (desc.contains("damage you take") and desc.contains("becomes 0") and not desc.contains("from this battle")):
		out.append({"kind": "no_dmg", "players": [p], "id": id, "name": nm, "until": until})
	elif desc.contains("you take no battle damage") or desc.contains("you do not take any battle damage"):
		out.append({"kind": "no_bdmg", "players": [p], "id": id, "name": nm, "until": until})
	if desc.contains("your opponent cannot declare an attack") or desc.contains("your opponent cannot attack") or desc.contains("your opponent cannot conduct their battle phase"):
		out.append({"kind": "no_attack", "players": [1 - p], "id": id, "name": nm, "until": until})
	if desc.contains("your monsters cannot be destroyed by battle") or desc.contains("monsters you control cannot be destroyed by battle"):
		out.append({"kind": "no_kill", "players": [p], "id": id, "name": nm, "until": until})
	return out


## What face-up Continuous and Field cards keep in force while they stay.
func _scan_field(duel) -> void:
	standing.clear()
	var st = duel.st
	if st == null:
		return
	for p in 2:
		var cards: Array = []
		for c in st.players[p].spells:
			if c != null:
				cards.append(c)
		if st.players[p].field_spell != null:
			cards.append(st.players[p].field_spell)
		for c in cards:
			if not c.face_up or not (spell_kind(int(c.id)) in ["continuous", "field"]):
				continue
			var desc := card_text(int(c.id))
			var nm := str(c.cname())
			var id := int(c.id)
			var partial := desc.contains("level") or desc.contains("or more atk") or desc.contains("or higher")
			if desc.contains("cannot declare an attack") or desc.contains("cannot attack"):
				var who: Array = [1 - p] if desc.contains("your opponent") or desc.contains("opponent's monsters") else [0, 1]
				standing.append({"kind": "no_attack", "players": who, "id": id, "name": nm, "until": -1, "partial": partial})
			if desc.contains("you take no battle damage") or desc.contains("battle damage to you becomes 0") or desc.contains("you do not take any battle damage"):
				standing.append({"kind": "no_bdmg", "players": [p], "id": id, "name": nm, "until": -1, "partial": desc.contains("if ") or desc.contains("when ") or desc.contains("while ")})
			if desc.contains("neither player can special summon") or desc.contains("cannot special summon"):
				var who2: Array = [1 - p] if desc.contains("your opponent cannot special summon") else [0, 1]
				standing.append({"kind": "no_special", "players": who2, "id": id, "name": nm, "until": -1, "partial": partial})


## A battle is about to deal damage: remember who should take how much.
func _expect_battle(m: Dictionary, duel) -> void:
	_pending_battle = {}
	if not m.has("a"):
		return
	var ac := int(m["a"].get("con", 0))
	var aa := int(m.get("aa", 0))
	var direct := int(m["b"].get("loc", 0)) == 0 if m.has("b") else true
	var victim := -1
	var amount := 0
	if direct:
		victim = 1 - ac
		amount = aa
	else:
		var defending := (int(m["b"].get("pos", 0)) & 0xC) != 0
		if defending:
			var dd := int(m.get("dd", 0))
			if dd > aa:
				victim = ac
				amount = dd - aa
		else:
			var da := int(m.get("da", 0))
			if aa > da:
				victim = 1 - ac
				amount = aa - da
			elif da > aa:
				victim = ac
				amount = da - aa
	if victim >= 0 and amount > 0:
		_pending_battle = {"victim": victim, "amount": amount, "attacker": _battle_src}


## The battle is over: if its damage never came, say why.
func _settle_battle(ev: Array, duel) -> void:
	if _pending_battle.is_empty():
		return
	var v := int(_pending_battle["victim"])
	var amount := int(_pending_battle["amount"])
	_pending_battle = {}
	var stop := _blocker(v, true)
	var text := ""
	var src_id := 0
	if not stop.is_empty():
		text = _no_battle_damage(v, str(stop["name"]), amount)
		src_id = int(stop["id"])
	else:
		for s in _since_attack:
			if int(s["con"]) == v:
				text = _no_battle_damage(v, str(s["name"]), amount)
				src_id = int(s["id"])
		if text == "":
			text = _no_battle_damage(v, "", amount)
	# (the first time in a turn as a card on screen; the same reason again as a short line)
	var key := "%d/%d/%d" % [turn, v, src_id]
	var w := _why(v, Loc.t("NO DAMAGE"), text, src_id)
	if _told.has(key):
		w["quiet"] = true
	_told[key] = true
	ev.append(w)
	ev.append(_log(v, "🛡", text))


## Cards that bill their player in the End Phase and could not.
func _settle_end_bills(ev: Array) -> void:
	var keep: Array = []
	for b in _end_bills:
		if int(b["turn"]) != turn:
			continue
		var p := int(b["p"])
		if not _hurt_this_end[p]:
			var stop := _blocker(p, false)
			if not stop.is_empty():
				var text := Loc.t("%s: no damage in the End Phase, %s is in force.") % [str(b["name"]), str(stop["name"])]
				var w := _why(p, Loc.t("NO DAMAGE"), text, int(stop["id"]))
				if _told.has(text):
					w["quiet"] = true
				_told[text] = true
				ev.append(w)
				ev.append(_log(p, "🛡", text))
	_end_bills = keep


## What keeps player `p` from taking damage now (battle damage when `battle`), or {}.
func _blocker(p: int, battle: bool) -> Dictionary:
	for l in lasting + standing:
		if not (l["players"] as Array).has(p):
			continue
		if l.get("partial", false):
			continue
		if str(l["kind"]) == "no_dmg" or (battle and str(l["kind"]) == "no_bdmg"):
			return l
	return {}


## The lists shown by each player's Life Points: {text, short, id, name, kind, partial}.
func statuses(p: int) -> Array:
	var out: Array = []
	for l in lasting + standing:
		if (l["players"] as Array).has(p):
			out.append({"kind": l["kind"], "id": l["id"], "name": l["name"], "text": _sentence(l, p), "short": _short(l), "when": _until(l), "partial": l.get("partial", false)})
	return out


func _send_status(ev: Array) -> void:
	for p in 2:
		var now := statuses(p)
		var key: Array = []
		for s in now:
			key.append([s["kind"], s["id"], s["when"]])
		if key != _shown[p]:
			_shown[p] = key
			ev.append({"type": "status", "player": p, "list": now})


## (wording)
func _short(l: Dictionary) -> String:
	var partial: bool = l.get("partial", false)
	match str(l["kind"]):
		"no_dmg": return Loc.t("No damage")
		"no_bdmg": return Loc.t("No battle damage")
		"no_attack": return Loc.t("Some monsters can't attack") if partial else Loc.t("Can't attack")
		"no_kill": return Loc.t("Not destroyed by battle")
		"no_special": return Loc.t("Some Special Summons blocked") if partial else Loc.t("Can't Special Summon")
	return str(l["name"])


func _title(l: Dictionary) -> String:
	match str(l["kind"]):
		"no_dmg", "no_bdmg": return Loc.t("NO DAMAGE")
		"no_attack": return Loc.t("NO ATTACKS")
		"no_kill": return Loc.t("SAFE IN BATTLE")
	return Loc.t("IN FORCE")


func _until(l: Dictionary) -> String:
	var u := int(l["until"])
	if u < 0:
		return Loc.t("while %s is face-up") % str(l["name"])
	if u == turn:
		return Loc.t("this turn")
	var who := turn_player if (u - turn) % 2 == 0 else 1 - turn_player
	if who == ME:
		return Loc.t("until the end of your next turn") if u > turn else Loc.t("until the end of your turn")
	return Loc.t("until the end of %s's turn") % _who(who)


func _sentence(l: Dictionary, p := -1) -> String:
	var who: String
	var pl: Array = l["players"]
	if pl.size() == 2:
		who = Loc.t("Neither player")
	else:
		who = _who(int(pl[0]))
	var what := ""
	match str(l["kind"]):
		"no_dmg":
			if pl.size() == 2:
				what = Loc.t("Neither player takes damage")
			else:
				what = Loc.t("You take no damage") if int(pl[0]) == ME else Loc.t("%s takes no damage") % who
		"no_bdmg":
			if pl.size() == 2:
				what = Loc.t("Neither player takes battle damage")
			else:
				what = Loc.t("You take no battle damage") if int(pl[0]) == ME else Loc.t("%s takes no battle damage") % who
		"no_attack":
			if pl.size() == 2:
				what = Loc.t("Some monsters can't attack") if l.get("partial", false) else Loc.t("No monster can declare an attack")
			elif l.get("partial", false):
				what = Loc.t("Some of your monsters can't attack") if int(pl[0]) == ME else Loc.t("Some of %s's monsters can't attack") % who
			else:
				what = Loc.t("You can't declare attacks") if int(pl[0]) == ME else Loc.t("%s can't declare attacks") % who
		"no_kill":
			what = Loc.t("Your monsters can't be destroyed by battle") if int(pl[0]) == ME else Loc.t("%s's monsters can't be destroyed by battle") % who
		"no_special":
			if pl.size() == 2:
				what = Loc.t("Special Summons are limited")
			else:
				what = Loc.t("You can't Special Summon") if int(pl[0]) == ME else Loc.t("%s can't Special Summon") % who
	return "%s %s (%s)." % [what, _until(l), str(l["name"])]


func _no_battle_damage(v: int, by: String, amount: int) -> String:
	if v == ME:
		return Loc.t("You take no damage from this battle (%d): %s.") % [amount, by] if by != "" else Loc.t("You take no damage from this battle (%d): an effect stopped it.") % amount
	return Loc.t("%s takes no damage from this battle (%d): %s.") % [_who(v), amount, by] if by != "" else Loc.t("%s takes no damage from this battle (%d): an effect stopped it.") % [_who(v), amount]


func _who(p: int) -> String:
	if p == ME:
		return Loc.t("You")
	return str(names[p]) if str(names[p]) != "" else Loc.t("Your opponent")


func _source() -> String:
	if _solving >= 0 and _solving < _links.size():
		return str(_links[_solving]["name"])
	if not _pending_battle.is_empty() or _battle_src != "":
		return Loc.t("battle with %s") % _battle_src if _battle_src != "" else Loc.t("battle")
	return ""


## A card's English rules text, lower case, with "can't" written out (the texts differ in that).
static func card_text(id: int) -> String:
	var t := ""
	if CardData.EXT.has(id):
		t = str(CardData.EXT[id].get("desc", ""))
	if t == "":
		var d := CardData.get_card(id)
		t = str(d.get("desc", ""))
		if t == "" or t == "<null>":
			t = str(d.get("text", ""))
	return t.to_lower().replace("can't", "cannot").replace("don't", "do not").replace("’", "'")


## "continuous", "field", "equip", "quick-play", "normal", "counter" for a Spell or Trap ("" if not known).
static func spell_kind(id: int) -> String:
	if CardData.EXT.has(id):
		return str(CardData.EXT[id].get("st", "")).to_lower()
	return str(CardData.get_card(id).get("st", "")).to_lower()


func _name(id: int) -> String:
	var n := str(CardData.get_card(id).get("name", ""))
	return n if n != "" else OcgCore.card_name(id)


func _id_of(nm: String) -> int:
	for s in _since_attack:
		if str(s["name"]) == nm:
			return int(s["id"])
	return 0


func _why(p: int, title: String, text: String, id: int) -> Dictionary:
	return {"type": "why", "player": p, "title": title, "text": text, "id": id}


func _log(p: int, icon: String, text: String) -> Dictionary:
	return {"type": "log", "player": p, "icon": icon, "text": text}
