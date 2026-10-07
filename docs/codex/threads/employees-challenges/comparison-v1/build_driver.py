"""Generate analysis-only driver from the pinned native banking route and curated control."""
from pathlib import Path
import sys

project = Path(sys.argv[1])
base = (project / 'analysis/b1_banking_route_v1.gd').read_text()
base = base.replace('max_games = 2', 'max_games = 3')
base = base.replace('action_limit = 60', 'action_limit = 100')
base = base.replace('for number in range(1, 3):', 'for number in range(1, 4):')
base = base.replace('if out.releases.size() == 2:', 'if out.releases.size() == 3:')
base = base.replace('"two releases and two legal earning follow-up actions"', '"three releases and two legal earning follow-up actions"')
base = base.replace('"requested two-release horizon"', '"requested three-release horizon"')
base = base.replace('number, out): break', 'number, out): break')
base = base.replace('"Rent Route Follow-up"', '"Employee Trial Follow-up"')
base = base.replace('"mixed", "design", 3, out)', '"mixed", "design", 4, out)')
base = base.replace('out["game2_available_cash"]', '_trial_shop(game, out)\n\t\t\t\tout["game2_available_cash"]')
base = base.replace('else 18))', 'else (22 if release_band == "stress" else 18)))')
base = base.replace('else [5, 6, 6]))', 'else ([7, 8, 6] if release_band == "stress" else [5, 6, 6])))')
base = base.replace('var out := await _finance_route()', 'mode = _arg("--reward=", "none")\n\tstaff = int(_arg("--staff=", "1"))\n\textra_rng.seed = declared_seed + 180000000\n\tvar out := await _finance_route()\n\tout["reward"] = mode\n\tout["staff"] = staff\n\tout["trial_events"] = trial_events')
base = base.replace('"/route_%s_%s_%s_%d.json" % [funding_mode, release_band, era_policy, declared_seed]', '"/route_%s_%s_%s_%d_%s_%d.json" % [funding_mode, release_band, era_policy, declared_seed, mode, staff]')
base = base.replace('"BANK B1 "', '"EMPLOYEE TRIAL "')
old_begin = 'project_number += 1'
base = base.replace(old_begin, old_begin + '\n\tuses_in_project = 0\n\ttriggered_project = false\n\tperk_used = false')
# Remove huge duplicate menu captures, retaining existing reconciliation checks.
base = base.replace('out["captures"] = final_captures', 'out["captures"] = []')
curated = (project / 'analysis/task18_curated_trial_v1.gd').read_text()
helpers = curated[curated.index('func _pool_value('):curated.index('func _develop_game(')]
helpers = helpers.replace('out.trial_events.append(', 'trial_events.append(')
helpers = helpers.replace('var eligible := trained and not perk_used and wants', 'var eligible := staff > 0 and trained and uses_in_project < staff and wants')
helpers = helpers.replace('if success and use: perk_used=true', 'if success and use:\n\t\tperk_used=true\n\t\tuses_in_project += 1')
helpers = helpers.replace('mode != "normal"', 'mode == "curated"')
prod = curated[curated.index('func _production_hand('):curated.index('func _choose_production(')]
prod = prod[:prod.index('\tif run.get_completed_run_cycles() == before_cycle + 1 and label == "design" and not trained:')]
prod = prod.replace('var base: Dictionary = phase.call', '''var matching := _printed_match(selected)
	var saved_priorities: Dictionary = phase.get_priority_distribution().duplicate()
	var desired := _priorities(project)
	var eligible := staff > 0 and trained and uses_in_project < staff and matching and desired != saved_priorities
	var used := false
	if mode in ["paid", "standalone", "bundle"] and eligible:
		var before_priority := _state_for(project, run)
		used = phase.commit_priority_distribution(desired) if mode == "paid" else _shadow_priority(phase, desired)
		trial_events.append({"kind":"priority", "mode":mode,"game":game_number,"matching":matching,"selected":_ids(selected),"old":saved_priorities,"new":desired,"before":before_priority,"after":_state_for(project,run),"success":used})
		if used and mode != "bundle": uses_in_project += 1
	entry["priority_opportunity"] = eligible
	entry["priority_use"] = used
	entry["priority_before"] = saved_priorities
	entry["priority_after"] = phase.get_priority_distribution()
	entry["matching"] = matching
	entry["trained_before"] = trained
	var base: Dictionary = phase.call''')
prod += '''	var committed := run.get_completed_run_cycles() == before_cycle + 1
	if used and mode == "bundle":
		if committed: uses_in_project += 1
		else: _shadow_priority(phase, saved_priorities)
	if committed and label == "design" and matching and not triggered_project and staff > 0:
		triggered_project = true
		trained = true
		trial_events.append({"kind":"training","game":game_number,"cycle":run.get_completed_run_cycles(),"staff":staff,"selected":_ids(selected)})
	entry["committed"] = committed
	entry["uses_in_project"] = uses_in_project
	_check_year(phase.get_parent().get_parent())
	return committed
'''
addon = '''
var mode := "none"
var staff := 1
var trained := false
var triggered_project := false
var perk_used := false
var uses_in_project := 0
var decision := 0
var extra_rng := RandomNumberGenerator.new()
var trial_events: Array = []

func _shadow_priority(phase: Control, distribution: Dictionary) -> bool:
	# Analysis-only counterfactual: public setter intentionally rejects active play.
	if not PriorityAllocation.is_valid_distribution(distribution): return false
	if not phase.get("_priority_allocation").set_distribution(distribution): return false
	phase.set("_priority_draft", phase.get_priority_distribution())
	phase.call("_sync_priority_controls")
	return true

func _printed_match(cards: Array[CardData]) -> bool:
	for p: CardData in cards:
		if p.card_type != &"pass": continue
		for f: CardData in cards:
			if f.card_type == &"feature" and p.primary_stat in [f.primary_stat, f.secondary_stat]: return true
	return false

func _release(project: ProjectState, run: RunState) -> Dictionary:
	var value := super._release(project,run)
	value["sales_record"] = run.get_released_game_sales(project.get_release_id())
	return value

func _trial_shop(game: Control, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var offers: Array[Dictionary] = []
	for item: Dictionary in FeatureStoreCatalog.entries():
		var offer := run.get_feature_store_offer(item.id)
		if offer.unlocked and not offer.owned and int(offer.price_cents) + 180000 <= run.get_cash_cents(): offers.append(offer)
	offers.sort_custom(func(a: Dictionary,b: Dictionary): return int(a.price_cents) < int(b.price_cents) if a.price_cents != b.price_cents else str(a.id) < str(b.id))
	var before := _state(game)
	var offer: Dictionary = offers[0] if not offers.is_empty() else {}
	var success := run.purchase_feature(offer.id) if not offer.is_empty() else false
	out.actions.append({"phase":"store","quote":offer,"success":success,"before":before,"after":_state(game)})
	out.purchases.append(out.actions[-1])
'''
driver = base + '\n' + addon + '\n' + helpers + '\n' + prod
(Path(__file__).parent / 'driver.gd').write_text(driver, newline='\n')
(project / 'analysis/employee_comparison_v1.gd').write_text(driver, newline='\n')
print('Created analysis driver:', len(driver), 'bytes')
