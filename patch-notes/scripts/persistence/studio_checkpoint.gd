class_name StudioCheckpoint
extends RefCounted

const BUILD := "studio-checkpoint-runtime-v1"
const PREVIOUS_RULES := "finance5-bank1-employees1-traits5-sales1-contracts3-research1"
const RULES := PREVIOUS_RULES + "-review2"
const FIELDS := ["_resourceful_claims","_feature_research","_cash_cents","_cash_initialized","_completed_run_cycles","_available_redraws","_owned_features","_familiarity","_credited_projects","_released_games","_release_metadata","_ironclad_completion_committed","_sidestreet_results","_unlocked_publishers","_pending_publisher_notifications","_seen_tutorial_topics","_studio_name","_studio_specialty","_studio_traits","_lean_savings","_first_studio_economy","_starter_selection_confirmed","_first_tutorial_project_id","_studio_finance","_bank_run_id","_employees","_promotion_awards","_promotion_consumed"]
var error := ""
var _revision := ""
var _previous_revision := ""

func revision() -> String:
	if _revision.is_empty():
		_revision = _rules_revision(RULES)
	return _revision

func previous_revision() -> String:
	if _previous_revision.is_empty(): _previous_revision = _rules_revision(PREVIOUS_RULES)
	return _previous_revision

func _rules_revision(rules: String) -> String:
	var data := rules
	var paths: Array[String] = []
	_collect_data("res://data", paths)
	paths.sort()
	for path in paths: data += path + FileAccess.get_sha256(path)
	return data.sha256_text()

func _collect_data(directory: String, paths: Array[String]) -> void:
	for name in DirAccess.get_files_at(directory):
		if name.ends_with(".json"): paths.append(directory.path_join(name))
	for name in DirAccess.get_directories_at(directory): _collect_data(directory.path_join(name), paths)

func capture(run: RunState) -> Dictionary:
	error = ""
	if run == null or run._feature_purchase_in_progress or run._productive_cycle_in_progress or run._committing_cycle_cash or run._publishing_cycle or run._pending_contract_completion != null or run.get_active_contract() != null:
		error = "Checkpoint requires a quiescent Studio."
		return {}
	var state := {}
	for field: String in FIELDS:
		state[field.trim_prefix("_")] = run.get(field)
	state.next_project_serial = run.next_project_serial
	state.primitive_contract = _contract(run._primitive_contract)
	state.sidestreet_entitlements = {}
	for id: StringName in run._sidestreet_entitlements:
		var offer: Dictionary = run._sidestreet_entitlements[id]
		state.sidestreet_entitlements[id] = {"offer_id":offer.offer_id,"state":_contract(offer.state)}
	state.publisher_offers = {}
	for id: StringName in run._publisher_offers:
		var offer: Dictionary = run._publisher_offers[id]
		state.publisher_offers[id] = {"publisher_id":offer.publisher_id,"source_release_id":offer.source_release_id,"state":_contract(offer.state)}
	state.first_game_tutorial = null
	if run._first_game_tutorial != null:
		var tutorial := run._first_game_tutorial
		state.first_game_tutorial = {"stage":tutorial.stage,"first_stat":tutorial.first_stat,"second_stat":tutorial.second_stat,"first_pool_published":tutorial.first_pool_published,"second_pool_published":tutorial.second_pool_published}
	var native := {"checkpoint_kind":"studio","run_id":run._bank_run_id,"sequence":1,"source_build":BUILD,"content_revision":revision(),"rng_algorithm":RunRandom.ALGORITHM,"run":state,"rng":run.random_streams.snapshot()}
	var codec := CheckpointCodec.new()
	var encoded: Variant = codec.encode(native,CheckpointSchema.root())
	error = codec.error
	if not error.is_empty(): return {}
	error = validate(encoded)
	return encoded if error.is_empty() else {}

func _contract(state: ContractState) -> Variant:
	if state == null: return null
	if not state.is_completed(): return null
	var result := state.get_result()
	return {"publisher_connections":state._publisher_connections,"contract_id":state._contract_id,"offer_id":state._offer_id,"source_release_id":state._source_release_id,"eligible":state._eligible_feature_ids,"scope":state._scope,"cores":state._core_half_units,"hands":state._successful_hands,"exhausted":state._exhausted_feature_ids,"priorities":state._priorities,"upfront":state._upfront_committed,"paid":state._payout_committed,"trial_terms":state._trial_terms,"neon_focus":state._neon_focus,"result":{"scope":result._scope,"cores":result._core_half_units,"numerator":result._completion_numerator,"payout":result._payout_cents,"remainder":result._remainder_cents,"upfront":result._upfront_cents,"denominator":result._denominator,"promotion":result._promotion}}

func validate(payload: Dictionary) -> String:
	var codec := CheckpointCodec.new()
	var value: Variant = codec.decode(payload,CheckpointSchema.root())
	if not codec.error.is_empty(): return codec.error
	# The immediately preceding format has identical fields and data. Frozen
	# releases stay authoritative; no active project is saved. Reading is passive,
	# and the next normal Studio checkpoint records the current revision.
	if value.content_revision not in [revision(), previous_revision()] or value.rng_algorithm != RunRandom.ALGORITHM: return "INCOMPATIBLE_CONTENT_OR_RNG"
	if value.checkpoint_kind != "studio" or value.sequence < 1: return "Invalid checkpoint boundary"
	var r: Dictionary = value.run
	if value.run_id.is_empty() or value.run_id != r.bank_run_id: return "Invalid run identity"
	if r.studio_name.is_empty() or r.studio_name != r.studio_name.strip_edges() or r.studio_name.length()>80 or StudioSpecialties.preview(r.studio_specialty).is_empty(): return "Invalid Studio identity"
	if not r.cash_initialized or not r.first_studio_economy or r.available_redraws>4 or r.next_project_serial<1: return "Invalid run counters"
	if r.studio_finance.cash_cents != r.cash_cents or r.studio_finance.last_cycle != r.completed_run_cycles or not StudioFinanceLedger._is_valid(r.studio_finance): return "Invalid finance provenance"
	if not FeatureResearch.validate(r.feature_research,r.owned_features,r.studio_finance,r.completed_run_cycles,r.bank_run_id): return "Invalid research provenance"
	for research: Dictionary in r.feature_research:
		var definition := RunState.new()
		if not definition._feature_definitions.has(research.feature_id): return "Unknown research Feature"
		var catalog_base: int = definition._feature_offers[research.feature_id].base_price_cents if definition._feature_offers.has(research.feature_id) else (int(definition._feature_definitions[research.feature_id].scope)+1)*15000
		if research.base_cents != catalog_base or r.starter_selection_confirmed == false: return "Invalid research terms"
	if r.employees.owner != value.run_id or not EmployeeRoster.valid(r.employees): return "Invalid employee provenance"
	if r.employees.employees.size() != r.studio_finance.employees.size(): return "Payroll roster mismatch"
	for employee: Dictionary in r.studio_finance.employees:
		if not r.employees.employees.has(employee.employee_id) or r.employees.employees[employee.employee_id].hire_cycle != employee.hire_cycle: return "Payroll identity mismatch"
	for loan: Dictionary in r.studio_finance.bank_loans:
		if loan.run_id != value.run_id: return "Loan owner mismatch"
	if not r.studio_traits.is_empty() and StudioTraits.evaluate_traits(r.studio_traits.trait_ids,r.studio_traits.version) != r.studio_traits: return "Invalid traits"
	if not r.resourceful_claims.is_empty() and not StudioTraits.is_active(r.studio_traits,&"resourceful"): return "Inactive Resourceful claim"
	var claim_sources := {}
	var catalog_for_claims := RunState.new()
	for window: int in r.resourceful_claims:
		var source: StringName = r.resourceful_claims[window]
		if window > r.released_games.size() or claim_sources.has(source): return "Invalid Resourceful window"
		claim_sources[source] = true
		var matched := false
		for entry: Dictionary in r.feature_research:
			for paid: Dictionary in entry.payments:
				if entry.id == source and paid.saving_cents > 0 and paid.window == window: matched = true
		if catalog_for_claims._feature_definitions.has(source) and not catalog_for_claims._feature_offers.has(source) and r.owned_features.has(source) and window == 0:
			var base: int = (int(catalog_for_claims._feature_definitions[source].scope)+1)*15000
			for action: Dictionary in r.studio_finance.actions:
				if action.source_id==source and action.kind==&"store" and not action.productive and action.direct_delta==-(base-mini(10000,base)): matched = true
		if not matched: return "Unproven Resourceful claim"
	for entry: Dictionary in r.feature_research:
		for paid: Dictionary in entry.payments:
			if paid.window > r.released_games.size(): return "Future Resourceful window"
			if paid.saving_cents > 0 and r.resourceful_claims.get(paid.window,&"") != entry.id: return "Missing Resourceful consumption"
	if r.studio_finance.monthly_rent_cents != (51500 if StudioTraits.is_active(r.studio_traits,&"expensive_lease") else 50000): return "Trait rent mismatch"
	var catalog := RunState.new()
	for id: StringName in r.owned_features:
		if not catalog._feature_definitions.has(id) or not r.owned_features[id]: return "Unknown owned Feature"
	var counts := {}
	for id: StringName in r.credited_projects:
		if not r.released_games.has(id): return "Unreleased familiarity project"
		for feature: StringName in r.credited_projects[id]:
			if not r.owned_features.has(feature) or not r.credited_projects[id][feature]: return "Invalid familiarity Feature"
			counts[feature] = int(counts.get(feature,0))+1
	if counts != r.familiarity: return "Familiarity count mismatch"
	if r.released_games.keys() != r.release_metadata.keys(): return "Release order/identity mismatch"
	for id: StringName in r.released_games:
		var sales: Dictionary = r.released_games[id]
		var meta: Dictionary = r.release_metadata[id]
		if id.is_empty() or sales.release_id != id or not ReleasedGameSales.is_valid(sales): return "Invalid release sales"
		if meta.release_cycle>r.completed_run_cycles or sales.last_processed_run_cycle>r.completed_run_cycles or sales.last_settlement_run_cycle>r.completed_run_cycles: return "Future release accounting"
		if sales.later_enabled and sales.total_earned_cycles != r.completed_run_cycles-meta.release_cycle: return "Release age mismatch"
		if sales.last_settlement_run_cycle>=0 and sales.last_settlement_run_cycle%2!=0: return "Invalid settlement boundary"
		if sales.release_title!=meta.release_title or sales.release_year!=meta.release_year or sales.base_name!=meta.base_name: return "Release metadata mismatch"
		if meta.release_year != RunState.START_YEAR+meta.release_cycle/24 or PrimitivePredevelopment.find_entry("genres",meta.genre).is_empty() or PrimitivePredevelopment.find_entry("themes",meta.theme).is_empty(): return "Invalid release catalog/year"
		if meta.review.cores.size()!=4 or meta.review.standards.size()!=4 or meta.review.final_review<0 or meta.review.final_review>10 or meta.review.scope_completion<0: return "Invalid frozen Review"
		if roundi(meta.review.final_review*10)!=sales.review_tenths or meta.review.awareness!=sales.launch_awareness or meta.review.projected_units!=sales.total_units: return "Frozen launch mismatch"
	for id: StringName in r.lean_savings:
		if not r.released_games.has(id) or r.lean_savings[id]>10000: return "Invalid Lean cap"
	if not _valid_contract(r.primitive_contract,r,ContractState.CONTRACT_ID,ContractState.CONTRACT_ID,&""): return "Invalid Ironclad checkpoint"
	if r.ironclad_completion_committed != (r.primitive_contract!=null): return "Ironclad completion mismatch"
	var results := {}
	for id: StringName in r.sidestreet_entitlements:
		var offer: Dictionary = r.sidestreet_entitlements[id]
		var expected := StringName("%s:%s" % [ContractState.SIDESTREET_CONTRACT_ID,id])
		if not r.released_games.has(id) or offer.offer_id!=expected or not _valid_contract(offer.state,r,ContractState.SIDESTREET_CONTRACT_ID,expected,id): return "Invalid SideStreet checkpoint"
		if offer.state!=null:
			var c: Dictionary = offer.state
			results[expected] = {"offer_id":expected,"release_id":id,"scope":c.scope,"core_half_units":c.cores,"completion_numerator":c.result.numerator,"payout_cents":c.result.payout}
	if results!=r.sidestreet_results: return "Contract history mismatch"
	var expected_awards := {}
	for publisher: StringName in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT]:
		var offer_id := StringName("%s:%s:first" % [r.bank_run_id,publisher])
		var source: StringName
		for release_id: StringName in r.release_metadata:
			var frozen: Dictionary = r.release_metadata[release_id].review
			if (publisher==PublisherCatalog.CROWN_QUILL and frozen.final_review>=7.0) or (publisher==PublisherCatalog.NEON_CIRCUIT and frozen.awareness>=125):
				source = release_id
				break
		if source.is_empty():
			if r.publisher_offers.has(offer_id) or r.unlocked_publishers.has(publisher): return "Unqualified trial offer"
			continue
		if not r.publisher_offers.has(offer_id) or not r.unlocked_publishers.has(publisher): return "Missing trial offer"
		var offer: Dictionary = r.publisher_offers[offer_id]
		if offer.publisher_id!=publisher or offer.source_release_id!=source or not _valid_contract(offer.state,r,PublisherTrialTerms.contract_id(publisher),offer_id,source): return "Invalid trial offer"
		if offer.state!=null: expected_awards[offer_id] = offer.state.result.promotion
	for id: StringName in r.publisher_offers:
		var publisher: StringName = r.publisher_offers[id].publisher_id
		if publisher not in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT] or id!=StringName("%s:%s:first" % [r.bank_run_id,publisher]): return "Unknown trial offer"
	if expected_awards!=r.promotion_awards: return "Promotion award mismatch"
	for id: StringName in r.promotion_consumed:
		if not r.promotion_awards.has(id) or not r.released_games.has(r.promotion_consumed[id]): return "Invalid Promotion consumption"
	for id: StringName in r.promotion_awards:
		var completed_cycle := -1
		for action: Dictionary in r.studio_finance.actions:
			if action.source_id==id and action.productive: completed_cycle = action.cycle
		var next_release: StringName
		for release_id: StringName in r.release_metadata:
			if r.release_metadata[release_id].release_cycle>=completed_cycle:
				next_release = release_id
				break
		if next_release.is_empty():
			if r.promotion_consumed.has(id): return "Premature Promotion consumption"
		elif r.promotion_consumed.get(id,&"")!=next_release: return "Promotion next-release mismatch"
	for id: StringName in r.unlocked_publishers:
		if not r.unlocked_publishers[id] or not id in [&"ironclad",&"sidestreet",&"crown_quill",&"neon_circuit",&"starwave"]: return "Invalid publisher"
	var seen := {}
	for id: StringName in r.pending_publisher_notifications:
		if seen.has(id) or not r.unlocked_publishers.has(id): return "Invalid publisher notice"
		seen[id] = true
	if r.first_game_tutorial!=null:
		var tutorial: Dictionary = r.first_game_tutorial
		if not r.released_games.has(r.first_tutorial_project_id) or tutorial.stage>FirstGameTutorial.Stage.COMPLETE: return "Invalid tutorial"
		for stat in [tutorial.first_stat,tutorial.second_stat]:
			if stat!=&"" and stat not in FirstGameTutorial.STATS: return "Invalid tutorial stat"
	if not RunRandom.new().restore(value.rng): return "Invalid RNG streams"
	return ""

func _valid_contract(c: Variant, r: Dictionary, kind: StringName, offer: StringName, release: StringName) -> bool:
	if c==null: return true
	if c.contract_id!=kind or c.offer_id!=offer or c.source_release_id!=release or c.hands!=2 or not c.upfront or not c.paid or not PriorityAllocation.is_valid_distribution(c.priorities): return false
	for id: StringName in c.eligible:
		if not c.eligible[id] or not r.owned_features.has(id): return false
		var primitive := false
		for entry: Dictionary in FeatureStoreCatalog.starting_features():
			if StringName(entry.id)==id: primitive = true; break
		if not primitive: return false
	for id: StringName in c.exhausted:
		if not c.exhausted[id] or not c.eligible.has(id): return false
	var terms := PublisherTrialTerms.terms(kind)
	var connected := kind==ContractState.CONTRACT_ID and StudioTraits.is_active(r.studio_traits,&"publisher_connections")
	if c.publisher_connections != connected: return false
	var advance := (55000 if connected else 40000) if kind==ContractState.CONTRACT_ID else 0
	var expected: Dictionary
	if terms.is_empty():
		if not c.trial_terms.is_empty() or c.neon_focus!=-1: return false
		expected = ContractState._calculate_completion_for_budget(c.scope,c.cores,240000-advance,advance) if kind==ContractState.CONTRACT_ID else ContractState.calculate_sidestreet_completion(c.scope,c.cores)
	else:
		var eligible: Array[StringName] = []
		eligible.assign(c.eligible.keys())
		var focus := PublisherTrialTerms.focus(eligible) if kind==PublisherTrialTerms.NEON else -1
		if c.trial_terms!=terms or c.neon_focus!=focus: return false
		advance = terms.advance_cents
		expected = PublisherTrialTerms.completion(kind,c.scope,c.cores,focus)
	if expected.is_empty(): return false
	var paid := 0
	var hands := 0
	for action: Dictionary in r.studio_finance.actions:
		if action.source_id!=offer: continue
		if action.kind==&"publisher_receipt": paid += int(action.direct_delta)
		if action.productive: hands += 1
	if paid!=int(expected.payout_cents) or hands!=2: return false
	return c.result == {"scope":c.scope,"cores":c.cores,"numerator":expected.numerator,"payout":expected.payout_cents,"remainder":expected.remainder_cents,"upfront":advance,"denominator":expected.get("denominator",96),"promotion":expected.get("promotion",0)}

func hydrate(payload: Dictionary) -> RunState:
	error = validate(payload)
	if not error.is_empty(): return null
	var value: Dictionary = CheckpointCodec.new().decode(payload,CheckpointSchema.root())
	var run := RunState.new()
	var r: Dictionary = value.run
	for field: String in FIELDS:
		if field=="_pending_publisher_notifications": run._pending_publisher_notifications.assign(r.pending_publisher_notifications)
		else: run.set(field,r[field.trim_prefix("_")])
	run.next_project_serial = r.next_project_serial
	run.random_streams.restore(value.rng)
	run._primitive_contract = _hydrate_contract(r.primitive_contract)
	for id: StringName in r.sidestreet_entitlements:
		var offer: Dictionary = r.sidestreet_entitlements[id]
		run._sidestreet_entitlements[id] = {"offer_id":offer.offer_id,"state":_hydrate_contract(offer.state)}
	for id: StringName in r.publisher_offers:
		var offer: Dictionary = r.publisher_offers[id]
		run._publisher_offers[id] = {"publisher_id":offer.publisher_id,"source_release_id":offer.source_release_id,"state":_hydrate_contract(offer.state)}
	if r.first_game_tutorial!=null:
		run._first_game_tutorial = FirstGameTutorial.new()
		for key: String in r.first_game_tutorial: run._first_game_tutorial.set(key,r.first_game_tutorial[key])
	return run

func _hydrate_contract(c: Variant) -> ContractState:
	if c==null: return null
	var state := ContractState.new()
	for key in {"_publisher_connections":"publisher_connections","_contract_id":"contract_id","_offer_id":"offer_id","_source_release_id":"source_release_id","_eligible_feature_ids":"eligible","_scope":"scope","_core_half_units":"cores","_successful_hands":"hands","_exhausted_feature_ids":"exhausted","_priorities":"priorities","_upfront_committed":"upfront","_payout_committed":"paid","_trial_terms":"trial_terms","_neon_focus":"neon_focus"}:
		var mapping := {"_publisher_connections":"publisher_connections","_contract_id":"contract_id","_offer_id":"offer_id","_source_release_id":"source_release_id","_eligible_feature_ids":"eligible","_scope":"scope","_core_half_units":"cores","_successful_hands":"hands","_exhausted_feature_ids":"exhausted","_priorities":"priorities","_upfront_committed":"upfront","_payout_committed":"paid","_trial_terms":"trial_terms","_neon_focus":"neon_focus"}
		state.set(key,c[mapping[key]])
	state._result = ContractResult.new(c.result.scope,c.result.cores,c.result.numerator,c.result.payout,c.result.remainder,c.result.upfront,c.result.denominator,c.result.promotion)
	return state
