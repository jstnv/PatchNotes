## Shared Design/Alpha Pass allowance. Each phase owns its own counters.
extends RefCounted

const INITIAL := 2
const PRINTED_CORE_PER_PASS := 8

static func generated(printed_core: int) -> int:
	@warning_ignore("integer_division")
	return INITIAL + maxi(0, printed_core) / PRINTED_CORE_PER_PASS

static func remaining(printed_core: int, played_passes: int) -> int:
	return generated(printed_core) - played_passes

static func progress(printed_core: int) -> int:
	return posmod(printed_core, PRINTED_CORE_PER_PASS)

static func delta(cards: Array[CardData]) -> Dictionary:
	var printed := 0
	var passes := 0
	for card: CardData in cards:
		if card.card_type == &"pass":
			passes += 1
		elif card.card_type == &"feature":
			for entry in card.core_contributions(): printed += int(entry.value)
	return {"printed": printed, "passes": passes}
