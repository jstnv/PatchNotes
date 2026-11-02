## Pure hand-level Gen II Pass marginal calculation. Remainders commit with the hand.
extends RefCounted
const ProductionHand:=preload("res://scripts/simulation/production_hand.gd")
const BalancedProduction:=preload("res://scripts/cards/balanced_production.gd")
const STATS: Dictionary={&"graphics":0,&"sound":1,&"technology":2,&"design":3}

static func pass_effect(cards: Array[CardData],base_scores: Dictionary,ordinary: Dictionary,engine_bonus: Dictionary,row: Dictionary,remainders: Dictionary) -> Dictionary:
	var updated:=remainders.duplicate(true)
	var additions: Dictionary=ordinary.score_additions.duplicate(true)
	if row.get("pass_effectiveness",{}).is_empty():return {"additions":additions,"remainders":updated}
	var without: Dictionary=base_scores.duplicate(true)
	for card: CardData in cards:
		if card.card_type!=&"pass":continue
		for entry: Dictionary in card.core_contributions():
			var category: Variant=STATS.get(entry.stat,-1)
			if category==-1:continue
			without[category]=int(without.get(category,0))-int(entry.value)
	var baseline: Dictionary=without
	if not ordinary.specialization_stat.is_empty():baseline=ProductionHand.specialize(without,engine_bonus)
	elif ordinary.balanced_production:baseline=BalancedProduction.redistribute(without)
	for branch: StringName in STATS:
		if not row.pass_effectiveness.has(branch):continue
		var category: int=STATS[branch]
		var marginal:=maxi(0,int(additions.get(category,0))-int(baseline.get(category,0)))
		var tenths:=int(updated.get(branch,0))+marginal
		additions[category]=int(additions.get(category,0))+tenths/10
		updated[branch]=tenths%10
	return {"additions":additions,"remainders":updated}
