extends RunState
# Frozen pre-fix individual quote implementation, test oracle only.

func get_feature_research_quote(id: StringName,engine: StringName=&"") -> Dictionary:
	if not engine.is_empty():return super.get_feature_research_quote(id,engine)
	if FeatureStoreCatalog.graph(_feature_definitions, _feature_offers).has("error"): return {}
	var offer := get_feature_store_offer(id)
	var primitive := offer.is_empty()
	if primitive: offer = get_primitive_reserve_offer(id)
	if offer.is_empty(): return {}
	var base: int = offer.base_price_cents
	var entry: Dictionary = {}
	for candidate: Dictionary in _feature_research:
		if candidate.feature_id == id: entry = candidate
	var queued: bool = not entry.is_empty() and entry.payments.size() < entry.actions
	var actions: int = entry.get("actions",1)
	var done: int = entry.get("payments",[]).size()
	var discount: int = offer.get("discount_percent",0)
	var arithmetic := FeatureResearch.payment(base,actions,mini(done,actions-1),discount)
	if arithmetic.is_empty(): return {}
	var saving := resourceful_saving(arithmetic.due_cents) if done == actions-1 else 0
	var remaining := 0
	for index in range(done,actions): remaining += int(FeatureResearch.payment(base,actions,index,discount).due_cents)
	if done < actions: remaining -= resourceful_saving(int(FeatureResearch.payment(base,actions,actions-1,discount).due_cents))
	var paid := 0 if entry.is_empty() else int(arithmetic.down_cents)
	for installment: Dictionary in entry.get("payments",[]): paid += int(installment.paid_cents)
	var pending := get_feature_research_queue()
	var head: bool = queued and not pending.is_empty() and pending[0].feature_id == id
	var unlocked: bool = offer.get("unlocked",false)
	return {"feature_id":id,"entry_id":StringName("%s:research:%s" % [_bank_run_id,id]),
		"base_cents":base,"down_cents":arithmetic.down_cents,"due_cents":arithmetic.due_cents-saving,"saving_cents":saving,
		"nominal_cents":arithmetic.nominal_cents,"discount_percent":discount,"actions":actions,"completed":done,
		"paid_cents":paid,"remaining_actions":actions-done,"remaining_cents":remaining,"queued":queued,"head":head,"unlocked":unlocked,
		"can_admit":not needs_starter_selection() and not offer.owned and unlocked and not queued and _cash_initialized and _cash_cents>=arithmetic.down_cents and get_financial_block_reason().is_empty(),
		"can_research":head and can_complete_productive_cycle(-int(arithmetic.due_cents-saving)),
		"cycle":_completed_run_cycles,"cash_cents":_cash_cents,"revision":_studio_finance.get("actions",[]).size(),"queue_size":_feature_research.size(),"resourceful_window":_released_games.size()}



func get_primitive_reserve_offer(id: StringName) -> Dictionary:
	if not _first_studio_economy or not _feature_definitions.has(id) or _feature_offers.has(id):
		return {}
	var graph := FeatureStoreCatalog.graph(_feature_definitions, _feature_offers)
	if graph.has("error"): return {}
	var parents: Array = graph.parents[id]
	var missing: Array[StringName] = []
	var names: Array[String] = []
	for parent: StringName in parents:
		names.append(str(_feature_definitions[parent].name))
		if not owns_feature(parent): missing.append(parent)
	var entry: Dictionary = _feature_definitions[id]
	var scope := int(entry.scope)
	if scope < 1 or scope > 3:
		return {}
	var price := (scope + 1) * 15000
	var initial := needs_starter_selection()
	var base_price := price
	if initial: price -= resourceful_saving(price)
	return {"id": id, "name": entry.name, "phase": entry.phase, "scope": scope,
		"base_price_cents":base_price,"price_cents": price, "owned": owns_feature(id), "affordable": _cash_initialized and _cash_cents >= price,
		"parents": parents, "missing_parents": missing, "unlocked": missing.is_empty(),
		"prerequisite": "Own " + " AND ".join(names) if not names.is_empty() else "Primitive reserve",
		"grant_exception": owns_feature(id) and not missing.is_empty(),
		"initial": initial, "can_purchase": not owns_feature(id) and missing.is_empty() and _cash_initialized and _cash_cents >= price}



func get_feature_store_offer(id: StringName) -> Dictionary:
	if not _feature_offers.has(id): return {}
	var graph := FeatureStoreCatalog.graph(_feature_definitions, _feature_offers)
	if graph.has("error"): return {}
	var entry: Dictionary = _feature_offers[id]
	var parents: Array = graph.parents[id]
	var parent: StringName = parents[0] if not parents.is_empty() else &""
	var missing: Array[StringName] = []
	var contributions: Array = []
	var names: Array[String] = []
	var credits := 0
	for required_parent: StringName in parents:
		var count := get_feature_familiarity(required_parent)
		var parent_name := str(_feature_definitions[required_parent].name)
		credits += count
		names.append(parent_name)
		if not owns_feature(required_parent): missing.append(required_parent)
		contributions.append({"id":required_parent,"name":parent_name,"owned":owns_feature(required_parent),"credits":count})
	var required := int(entry.get("gameplay_features_required", 0))
	var gameplay_owned := 0
	for owned_id: StringName in _owned_features:
		if _feature_definitions[owned_id].get("department", "") == "gameplay": gameplay_owned += 1
	var year_reached := get_current_year() >= int(entry.get("min_year",START_YEAR))
	var era_qualified: bool = not entry.has("era_year") or not get_store_era_status(int(entry.era_year)).receipt_id.is_empty()
	var unlocked: bool = missing.is_empty() and gameplay_owned >= required and year_reached and era_qualified
	var discount := mini(credits, 5) * 10
	var base_price := int(entry.base_price_cents)
	# Exact integer cents, without multiplying a potentially large base first.
	var price: int = (base_price / 100) * (100 - discount) + ((base_price % 100) * (100 - discount)) / 100
	var prerequisite := "New root"
	if not parents.is_empty(): prerequisite = "Own " + " AND ".join(names)
	elif required > 0: prerequisite = "Own %d distinct Gameplay Features (%d owned)" % [required, gameplay_owned]
	var offer := {"id":id,"name":entry.name,"parent":parent,"parents":parents.duplicate(),"missing_parents":missing,
		"parent_contributions":contributions,"parent_credits":credits,"prerequisite":prerequisite,
		"owned":owns_feature(id),"unlocked":unlocked,"base_price_cents":base_price,
		"discount_percent":discount,"price_cents":price,"affordable":_cash_initialized and _cash_cents >= price}
	if entry.has("min_year") or entry.has("era_year"):
		offer.merge({"min_year":int(entry.get("min_year",START_YEAR)),"era_year":int(entry.get("era_year",0)),"year_reached":year_reached,"era_qualified":era_qualified})
	return offer



func _plan_productive_cycle(direct_cash_delta_cents: int, campaign_release_id: StringName = &"", finance_kind: StringName = &"", source_id: StringName = &"") -> Dictionary:
	if _productive_cycle_in_progress or _feature_purchase_in_progress or _pending_contract_completion != null or _completed_run_cycles < 0 or _completed_run_cycles == MAX_SIGNED_INT or _available_redraws < 0 or _available_redraws > MAX_REDRAWS:
		return {}
	if not campaign_release_id.is_empty() and (direct_cash_delta_cents != -POST_LAUNCH_CAMPAIGN_COST_CENTS or not _released_games.has(campaign_release_id) or not ReleasedGameSales.can_campaign(_released_games[campaign_release_id]) or _commission_deals.has(campaign_release_id)):
		return {}
	if direct_cash_delta_cents != 0 and not _cash_initialized:
		return {}
	if direct_cash_delta_cents < -_cash_cents or direct_cash_delta_cents > MAX_SIGNED_INT - _cash_cents:
		return {}
	var cash_after_action := _cash_cents + direct_cash_delta_cents
	var market: Dictionary = preload("res://scripts/market/market_transaction_trial.gd").neutral()
	if _market_provider.is_valid():
		market = _market_provider.call(_bank_run_id,_completed_run_cycles+1)
		if not preload("res://scripts/market/market_transaction_trial.gd").valid(market): return {}
	var next_records: Dictionary = {}
	var payable := 0
	var earned := 0
	var support_rights := _support_rights.duplicate(true)
	var support_assessments := _support_assessments.duplicate(true)
	for id: StringName in _released_games:
		if not _cash_initialized or not _released_games[id] is Dictionary or _released_games[id].get("release_id") != id:
			return {}
		var factor: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").neutral_factor()
		if _market_provider.is_valid():
			if not _release_metadata.has(id): return {}
			var metadata: Dictionary=_release_metadata[id]
			factor=preload("res://scripts/market/market_transaction_trial.gd").sales_factor(market,str(_bank_run_id),str(id),str(metadata.genre),str(metadata.theme))
			if factor.is_empty(): return {}
		var next := ReleasedGameSales.next_cycle(_released_games[id], _completed_run_cycles + 1, will_next_cycle_cross_month_boundary(), id == campaign_release_id, int(factor.factor_bp), str(factor.snapshot_id),factor)
		if next.is_empty():
			return {}
		if _commission_deals.has(id):
			next_records[id] = next
			continue
		var release_payable: int = next.settled_cents - _released_games[id].settled_cents
		var release_earned: int = next.entitlement_cents - _released_games[id].entitlement_cents
		if _support_deals.has(id):
			if not support_rights.has(id): return {}
			var old: Dictionary = support_rights[id]
			var rights := Support.advance_rights(_support_deals[id].budget_cents,old,next.entitlement_cents,next.total_earned_cycles,will_next_cycle_cross_month_boundary())
			if rights.is_empty(): return {}
			release_payable = rights.studio_settled_cents-old.studio_settled_cents
			release_earned = rights.studio_earned_cents-old.studio_earned_cents
			support_rights[id] = rights
			if next.total_earned_cycles == 6:
				if support_assessments.has(id): return {}
				support_assessments[id] = Support.assessment(roundi(float(_release_metadata[id].review.final_review)*10.0),next.earned_units)
		if release_payable > MAX_SIGNED_INT - payable:
			return {}
		payable += release_payable
		if release_earned < 0 or release_earned > MAX_SIGNED_INT - earned: return {}
		earned += release_earned
		next_records[id] = next
	var fan_plan := StudioFanbase.plan(_fanbase, _released_games, next_records, _completed_run_cycles + 1)
	if fan_plan.is_empty(): return {}
	if payable > MAX_SIGNED_INT - cash_after_action:
		return {}
	var finance_plan: Dictionary = {}
	if _first_studio_economy:
		if finance_kind.is_empty():
			finance_kind = &"campaign" if not campaign_release_id.is_empty() else (&"other_expense" if direct_cash_delta_cents < 0 else (&"other_income" if direct_cash_delta_cents > 0 else &"calendar"))
		finance_plan = StudioFinanceLedger.plan(_studio_finance, _completed_run_cycles + 1, _cash_cents, direct_cash_delta_cents, finance_kind, earned, payable, true, source_id)
		if finance_plan.is_empty(): return {}
	var relationships := _publisher_relationships.duplicate(true)
	if support_assessments != _support_assessments:
		var prospective := RunState.new()
		preload("res://scripts/simulation/transaction_projection.gd").copy_fields(self,prospective)
		prospective._completed_run_cycles += 1
		prospective._released_games = next_records
		prospective._support_rights = support_rights
		prospective._support_assessments = support_assessments
		prospective._studio_finance = finance_plan.ledger
		for id: StringName in support_assessments:
			if _support_assessments.has(id): continue
			var request := Support.request_for(prospective,id)
			var resolver := func(source: Dictionary) -> Dictionary: return RelationshipRules.resolve(prospective,source)
			var award := RelationshipLedger.plan(relationships,_bank_run_id,request,prospective._completed_run_cycles,resolver)
			if award.is_empty(): return {}
			relationships = award.ledger
	return {"records":next_records,"payable":payable,"finance":finance_plan,"fans":fan_plan,"market":market,"support_rights":support_rights,"support_assessments":support_assessments,"relationships":relationships}



func research_feature(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint() or _feature_purchase_in_progress or _productive_cycle_in_progress or _publishing_cycle: return false
	if quote.is_empty() or typeof(quote.get("feature_id")) != TYPE_STRING_NAME: return false
	if quote != get_feature_research_quote(quote.get("feature_id",&"")) or not quote.can_research: return false
	var commit := func() -> bool:
		for entry: Dictionary in _feature_research:
			if entry.id != quote.entry_id: continue
			entry.payments.append({"cycle":_completed_run_cycles+1,"nominal_cents":quote.nominal_cents,"discount_percent":quote.discount_percent,"paid_cents":quote.due_cents,"saving_cents":quote.saving_cents,"window":quote.resourceful_window})
			if quote.saving_cents > 0: _resourceful_claims[_released_games.size()] = quote.entry_id
			if entry.payments.size() == entry.actions: _owned_features[entry.feature_id] = true
			return true
		return false
	return complete_productive_action(commit,-int(quote.due_cents),quote.cycle,&"",&"store",StringName("%s:%d" % [quote.entry_id,quote.completed]))


