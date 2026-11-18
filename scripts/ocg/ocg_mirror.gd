class_name OcgMirror
extends DuelState
## What the duel screen looks at when the rules run in the engine: the same shape as the
## classic duel state (players, zones, cards), kept in step with the engine by OcgDuel.
## It holds no rules of its own. The numbers on the cards are the engine's.


func atk_of(c: CardInst, _attacking: bool, _vs: CardInst = null, _battling := false) -> int:
	return int(c.tags.get("ocg_atk", c.atk()))


func def_of(c: CardInst) -> int:
	return int(c.tags.get("ocg_def", c.def()))
