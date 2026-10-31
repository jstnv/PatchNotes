from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v8/project'
f=P/'scripts/market/rival_career_policy.gd';s=f.read_text(encoding='utf-8')
a=s.index('\t\tif int(plan.cost)>run.get_cash_cents()');b=s.index('\n\t\tvar themes:',a)
s=s[:a]+'''\t\tif not run.can_complete_productive_cycle():
			var bridge:=_loan(run)
			return bridge if not bridge.is_empty() else {"type":&"blocked","payload":{"reason":"Project start unavailable"}}'''+s[b:]
a=s.index('\tvar reserve:=run.get_cash_cents()');b=s.index('\n\tvar plans:',a)
s=s[:a]+'\tvar runway: Dictionary={}'+s[b:]
s=s.replace('var cycles:=ceili(float(cards.size())/4.0)+hands+4','var feature_hands:=ceili(float(cards.size())/4.0)\n\t\tvar cycles:=feature_hands+hands+5',1)
s=s.replace('''var cost: int=fee+_known_dues(run,cycles,planned_schedule)
		if cost<=reserve:plans.append({"genre":genre,"hands":hands,"cost":cost,"conditional_facility":conditional and cost>run.get_cash_cents()})''','''var cost: int=fee+_known_dues(run,cycles)
		if not runway.has(cycles):runway[cycles]=cost<=run.get_cash_cents() or _funded_runway(run,market,fee,feature_hands,cycles)
		if runway[cycles]:plans.append({"genre":genre,"hands":hands,"cost":cost})''',1)
s+='''
## Existing-title cash-flow scenario, not spendable forecast money. The shadow
## uses ordinary sales, dues and Bank qualification; no new-title proceeds or
## future draws/RNG are available. Prelude sales are exactly neutral. After1980
## only currently known Market facts are carried/aged: new rival releases are
## unknown, so actual commands must still recheck cash and recovery every tick.
func _funded_runway(run: RunState,market: Dictionary,fee: int,feature_hands: int,cycles: int) -> bool:
	if cycles<1 or cycles>64 or feature_hands<1:return false
	var shadow:=RunState.new()
	preload("res://scripts/simulation/transaction_projection.gd").copy_fields(run,shadow)
	shadow.random_streams=RunRandom.new();shadow.random_streams.restore(run.random_streams.snapshot())
	shadow.checkpoint_before_mutation=Callable();shadow.studio_departure_guard=Callable()
	shadow._market_provider=func(_owner: StringName,target: int)->Dictionary:
		var book:=preload("res://scripts/market/rival_standard_book.gd")
		var transaction:=preload("res://scripts/market/market_transaction_trial.gd")
		if market.get("version")==4:
			var world_cycle: int=target-int(market.epoch_offset)
			var month: int=world_cycle-world_cycle%2;var facts: Array=[]
			for fact: Dictionary in market.facts:
				if fact.release_cycle<month and month-fact.release_cycle<=12:facts.append(fact.duplicate(true))
			return book.snapshot(market.basis,world_cycle,market.epoch_offset,facts)
		return transaction.neutral()
	for step in range(cycles):
		# Begin costs no direct fee; reserve all finite Feature fees in the next
		# Feature hands. Exact dealing changes timing, never the authority checks.
		var cost: int=(fee/feature_hands+int(step<=fee%feature_hands)) if step>=1 and step<=feature_hands else 0
		var progressed:=false
		for attempt in range(3):
			if shadow.can_complete_productive_cycle(-cost):
				if not shadow.complete_productive_action(Callable(),-cost):return false
				progressed=true;break
			var borrowing:=_loan(shadow)
			if not borrowing.is_empty() and shadow.accept_bank_loan(borrowing.payload.quote):continue
			if not shadow.complete_productive_action():return false
		if not progressed:return false
	return true
'''
f.write_bytes(s.encode());print('Ordinary shadow cash flow replaces cash-up-front false deadlock; no forecast is spent.')
