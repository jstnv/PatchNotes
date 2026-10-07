class_name FirstGameTutorial
extends RefCounted

## A bounded first-project lesson. Read/preview never consumes its guarantees.
## RunState retains this object; ongoing phase pools still belong to DesignPhase.
enum Stage { FIRST_HAND, REDRAW_HAND, REDRAW_READY, COMPLETE }
const STATS: Array[StringName] = [&"graphics", &"sound", &"technology", &"design"]
const CORE_BY_STAT := {&"graphics": ProjectState.CoreScore.GRAPHICS, &"sound": ProjectState.CoreScore.SOUND, &"technology": ProjectState.CoreScore.TECHNOLOGY, &"design": ProjectState.CoreScore.DESIGN}
var stage := Stage.FIRST_HAND
var first_stat: StringName
var second_stat: StringName
var first_pool_published := false
var second_pool_published := false


func needs_scripted_deal() -> bool:
	return (stage == Stage.FIRST_HAND and not first_pool_published) or (stage == Stage.REDRAW_HAND and not second_pool_published)


func plan_deal(features: Array[CardData], passes: Array[CardData], priorities: Dictionary, cash_cents: int, costs: Dictionary, rng: RandomNumberGenerator, retained: Array[CardData] = [], after_hand := false) -> Dictionary:
	if (after_hand and stage != Stage.FIRST_HAND) or (not after_hand and not needs_scripted_deal()): return {}
	var second := after_hand or stage == Stage.REDRAW_HAND
	var target := _dominant_stat(priorities, first_stat if second else &"", rng)
	var target_pass := _pass_for(passes, target)
	if target_pass == null: return {}
	var matching_count := 3 if second else 4
	var counts := {}
	for card: CardData in retained: counts[card.primary_stat] = int(counts.get(card.primary_stat, 0)) + 1
	var cards: Array[CardData] = []
	var selected_features: Array[CardData] = []
	var remaining: Array[CardData] = features.duplicate()
	var budget := cash_cents
	# Prefer actual affordable owned Features so the lesson can also build Scope.
	# Renewable Core Passes guarantee the pattern even for the smallest legal pool.
	for slot in range(matching_count - int(counts.get(target, 0))):
		var eligible: Array[CardData] = []
		for card: CardData in remaining:
			if card.primary_stat == target and costs.get(card.id, -1) >= 0 and costs[card.id] <= budget:
				eligible.append(card)
		eligible.sort_custom(func(a: CardData, b: CardData): return str(a.id) < str(b.id))
		if eligible.is_empty():
			cards.append(target_pass)
		else:
			var feature := eligible[rng.randi_range(0, eligible.size() - 1)]
			cards.append(feature)
			selected_features.append(feature)
			remaining.erase(feature)
			budget -= int(costs[feature.id])
	counts[target] = matching_count
	while cards.size() + retained.size() < 7:
		var entries: Array[Dictionary] = []
		for card: CardData in remaining + passes:
			if card.primary_stat == target or int(counts.get(card.primary_stat, 0)) >= 3: continue
			var weight := WeightedCandidateMath.calculate_printed_score_weight(card, priorities, CORE_BY_STAT)
			if weight > 0.0: entries.append({&"card": card, &"weight": weight})
		entries.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.card.id) < str(b.card.id))
		var next := WeightedCandidateMath.select_weighted_entry(entries, rng.randf())
		if next == null: return {}
		cards.append(next)
		counts[next.primary_stat] = int(counts.get(next.primary_stat, 0)) + 1
		if not next.renewable:
			selected_features.append(next)
			remaining.erase(next)
	# The player finds the common labels rather than always clicking slots 1–4.
	for index in range(cards.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var held := cards[index]
		cards[index] = cards[other]
		cards[other] = held
	return {&"valid": true, &"cards": cards, &"selected_features": selected_features, &"tutorial_stat": target}


func record_deal(target: StringName) -> void:
	if stage == Stage.FIRST_HAND and not first_pool_published:
		first_stat = target
		first_pool_published = true
	elif stage == Stage.REDRAW_HAND and not second_pool_published:
		second_stat = target
		second_pool_published = true


func record_successful_hand() -> void:
	if stage == Stage.FIRST_HAND:
		stage = Stage.REDRAW_HAND
	elif stage in [Stage.REDRAW_HAND, Stage.REDRAW_READY]:
		stage = Stage.COMPLETE


func guaranteed_redraw(current: Array[CardData], selected: Array[CardView], passes: Array[CardData]) -> CardData:
	if stage != Stage.REDRAW_HAND or not second_pool_published or selected.size() != 1: return null
	if selected[0].card_data.primary_stat == second_stat: return null
	var matching := 0
	for card: CardData in current:
		if card.primary_stat == second_stat: matching += 1
	return _pass_for(passes, second_stat) if matching == 3 else null


func record_successful_redraw() -> void:
	if stage == Stage.REDRAW_HAND: stage = Stage.REDRAW_READY


func _dominant_stat(priorities: Dictionary, exclude: StringName, rng: RandomNumberGenerator) -> StringName:
	var highest := -1
	var tied: Array[StringName] = []
	for index in range(STATS.size()):
		if STATS[index] == exclude: continue
		var value := int(priorities.get(index, 0))
		if value > highest:
			highest = value
			tied.clear()
		if value == highest: tied.append(STATS[index])
	return tied[rng.randi_range(0, tied.size() - 1)]


func _pass_for(passes: Array[CardData], stat: StringName) -> CardData:
	for card: CardData in passes:
		if card.primary_stat == stat: return card
	return null
