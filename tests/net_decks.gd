extends Node
## Prints the decks the Online screen offers with this profile, and why the open deck is not one of them.
## `-- --take-starter=starter_warrior` first gives the profile that starter (and saves it): a test profile with a deck.
func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--take-starter="):
			print("STARTER ", Collection.take_starter(a.substr(15)))
	print("DECKS ", Net.decks())
	print("OPEN main=%d extra=%d side=%d illegal=%s missing=%d has_custom=%s" % [Collection.main.size(), Collection.extra.size(), Collection.side.size(),
		str(Collection.illegal()), Collection.missing_cards().size(), str(CardData.has_deck("custom"))])
	print("SLOTS ", Collection.slots.size(), " owned ", Collection.decks_owned)
	get_tree().quit()
