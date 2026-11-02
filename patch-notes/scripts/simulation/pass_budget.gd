## Shared Design/Alpha Pass allowance. Each phase owns its own counters.
extends RefCounted

const INITIAL := 10
const LEGACY_INITIAL := 2
const PRINTED_CORE_PER_PASS := 8

static func generated(printed_core: int, version: int = 2,bonus_centi: int = 0) -> int:
	@warning_ignore("integer_division")
	return (LEGACY_INITIAL if version == 1 else INITIAL) + (100*maxi(0, printed_core)+maxi(0,bonus_centi)) / (100*PRINTED_CORE_PER_PASS)

static func remaining(printed_core: int, played_passes: int, version: int = 2) -> int:
	return generated(printed_core, version) - played_passes

static func progress(printed_core: int) -> int:
	return posmod(printed_core, PRINTED_CORE_PER_PASS)

static func effective_progress(printed_core: int,bonus_centi: int=0) -> float:
	return float(posmod(100*printed_core+bonus_centi,100*PRINTED_CORE_PER_PASS))/100.0

static func delta(cards: Array[CardData]) -> Dictionary:
	var printed := 0
	var passes := 0
	for card: CardData in cards:
		if card.card_type == &"pass":
			passes += 1
		elif card.card_type == &"feature":
			for entry in card.core_contributions(): printed += int(entry.value)
	return {"printed": printed, "passes": passes}
