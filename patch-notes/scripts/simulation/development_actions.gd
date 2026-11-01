## Synchronous development operations. View allocation/publication callbacks are
## trusted adapter plumbing; they must not resolve effects or consume RNG.
extends RefCounted

const Finalization := preload("res://scripts/simulation/development_finalization.gd")
const BETA_PLAYTEST_COST_CENTS := 50000
var hand: RefCounted
var phase: StringName
var catalog: RefCounted
var finalization_rng: RandomNumberGenerator

func boundary() -> RefCounted:
	var result:=Finalization.new()
	result._project_state=hand._project_state
	result.catalog=catalog
	if phase==&"design": result._exhausted_card_ids=hand._exhausted_card_ids
	if phase==&"alpha": result._exhausted_feature_ids=hand._exhausted_feature_ids
	return result

func initial_plan(rolls: Array[float] = [], definition_rolls: Array[float] = []) -> Dictionary:
	if not hand._candidate_cards.is_empty(): return {"valid":false}
	if phase==&"beta":
		if not hand._get_source_validation_error(hand._beta_definitions).is_empty(): return {"valid":false}
		return hand._build_candidate_definitions(hand._beta_definitions,hand.priorities,rolls,definition_rolls)
	if phase==&"alpha" and not hand._pending_playtest_categories.is_empty():
		return hand._build_corrective_candidate_definitions(hand.priorities,rolls)
	return hand._build_weighted_candidate_definitions(hand.priorities,rolls)

func publish_initial(plan: Dictionary) -> void:
	hand._candidate_cards.assign(plan.cards)
	hand.candidate_ids.clear()
	for card: CardData in plan.cards:
		hand.candidate_ids.append(hand.next_candidate_id)
		if phase==&"alpha" and hand.candidate_ids.size()<=int(plan.get("injected_count",0)):hand.injected_candidate_ids.append(hand.next_candidate_id)
		hand.next_candidate_id+=1
	if phase==&"design":
		for card: CardData in plan.selected_features: hand._available_features.erase(card)
		if plan.has("tutorial_stat"): hand._get_first_game_tutorial().record_deal(plan.tutorial_stat)
	elif phase==&"alpha": hand._pending_playtest_categories.clear()
	hand.revision+=1

func can_swap(slots: Array[int]) -> bool:
	if phase!=&"beta" or not hand.active or hand.launch_confirmation_pending or hand._run_state==null or not hand._run_state.can_mutate_checkpoint() or slots.size()!=1: return false
	var slot:=slots[0]
	if slot<0 or slot>=hand._candidate_cards.size() or hand.candidate_ids[slot] in hand.injected_candidate_ids: return false
	var old: CardData=hand._candidate_cards[slot]
	if old.id not in [&"search_for_bugs",&"debug"] or not EmployeeRoster.qa_swap_available(hand._run_state.get_employees(),hand._project_state.get_release_id()): return false
	var opposite: CardData=hand._definitions_by_id.get(&"debug" if old.id==&"search_for_bugs" else &"search_for_bugs")
	return opposite!=null and opposite.beta_value==old.beta_value

func valid_redraw(slots: Array[int], rolls: Array[float]) -> bool:
	if not hand.active or hand._run_state==null or not hand._run_state.can_consume_redraw(slots.size()): return false
	if not rolls.is_empty() and rolls.size()!=slots.size(): return false
	for roll in rolls:
		if not is_finite(roll) or roll<0.0 or roll>=1.0: return false
	var seen: Array[int] = []
	for slot in slots:
		if slot<0 or slot>=hand._candidate_cards.size() or slot in seen: return false
		seen.append(slot)
		if phase==&"beta":
			if hand.candidate_ids[slot] in hand.injected_candidate_ids: return false
		elif phase==&"alpha" and hand.candidate_ids[slot] in hand.injected_candidate_ids:return false
		elif hand._candidate_cards[slot].card_type not in [&"feature",&"pass"]: return false
	return true

func alignment_options(slots: Array[int]) -> Array:
	var result: Array=[]
	if slots.size()!=1 or phase not in [&"design",&"alpha"] or not hand.active or hand._run_state==null or not hand._run_state.can_consume_redraw(1) or not EmployeeRoster.Career.alignment_available(hand._run_state.get_employees()) or not valid_pool():return result
	var slot:=slots[0]
	if slot<0 or slot>=hand._candidate_cards.size() or hand.candidate_ids.size()!=hand._candidate_cards.size():return result
	if phase==&"alpha" and hand.candidate_ids[slot] in hand.injected_candidate_ids:return result
	var old: CardData=hand._candidate_cards[slot]
	if old.card_type!=&"pass" or not hand._pass_definitions.has(old):return result
	for target: CardData in hand._pass_definitions:
		if target.id==old.id or target.primary_value!=2 or not target.renewable:continue
		for index in hand._candidate_cards.size():
			var feature: CardData=hand._candidate_cards[index]
			if feature.card_type!=&"feature" or target.primary_stat not in [feature.primary_stat,feature.secondary_stat]:continue
			var quote:=alignment_quote(hand.candidate_ids[slot],target.id,hand.candidate_ids[index])
			if not quote.is_empty():result.append({"quote":quote,"target_id":target.id,"target_name":target.card_name,"feature_name":feature.card_name,"primary":target.primary_stat,"value":target.primary_value})
			break
	return result

func alignment_quote(source_token: int,target_id: StringName,feature_token: int) -> Dictionary:
	if phase not in [&"design",&"alpha"] or not hand.active or hand._run_state==null or not valid_pool() or not hand._run_state.can_consume_redraw(1) or not EmployeeRoster.Career.alignment_available(hand._run_state.get_employees()):return {}
	if source_token not in hand.candidate_ids or feature_token not in hand.candidate_ids or hand.revision>=ProjectState.MAX_SIGNED_INT or hand.next_candidate_id>=ProjectState.MAX_SIGNED_INT:return {}
	if phase==&"alpha" and source_token in hand.injected_candidate_ids:return {}
	if (phase==&"design" and (hand.finalization_requested or hand._project_state.has_design_bug_finalization())) or (phase==&"alpha" and hand._project_state.has_alpha_finalization()):return {}
	var old: CardData=hand._candidate_cards[hand.candidate_ids.find(source_token)]
	var feature: CardData=hand._candidate_cards[hand.candidate_ids.find(feature_token)]
	var target: CardData=catalog.get_card(target_id) if catalog!=null else null
	if old.card_type!=&"pass" or not hand._pass_definitions.has(old) or target==null or not hand._pass_definitions.has(target) or target.id==old.id or target.primary_value!=2 or not target.renewable or feature.card_type!=&"feature" or target.primary_stat not in [feature.primary_stat,feature.secondary_stat]:return {}
	return {"source_token":source_token,"target_id":target_id,"feature_token":feature_token,"revision":hand.revision,"project_id":hand._project_state.get_release_id(),"project_cycle":hand._project_state.get_current_cycle(),"run_cycle":hand._run_state.get_completed_run_cycles(),"redraws":hand._run_state.get_available_redraws()}

func replace_pass(quote: Dictionary,readiness: Callable=Callable(),publication: Callable=Callable()) -> Dictionary:
	var rejected:={"ok":false,"events":[],"plan":{"cards":[],"failed_features":[]}}
	if quote.size()!=8 or typeof(quote.get("source_token"))!=TYPE_INT or typeof(quote.get("feature_token"))!=TYPE_INT or (not quote.get("target_id") is StringName and not quote.get("target_id") is String):return rejected
	var current:=alignment_quote(quote.source_token,StringName(quote.target_id),quote.feature_token)
	if current.is_empty() or current!=quote or not hand._run_state.can_mutate_checkpoint():return rejected
	var cards: Array[CardData]=[catalog.get_card(quote.target_id)]
	if readiness.is_valid() and not readiness.call(cards):return rejected
	if alignment_quote(quote.source_token,StringName(quote.target_id),quote.feature_token)!=quote:return rejected
	var plan:={"valid":true,"cards":cards,"failed_features":[],"alignment":true}
	var publish:=func() -> void:
		var slot: int=hand.candidate_ids.find(quote.source_token)
		hand._candidate_cards[slot]=cards[0]
		hand.candidate_ids[slot]=hand.next_candidate_id;hand.next_candidate_id+=1;hand.revision+=1
		if publication.is_valid():publication.call(plan)
	if not hand._run_state.consume_redraw(1,publish):return rejected
	return {"ok":true,"events":[{"type":"pass_alignment","source_token":quote.source_token,"target_id":quote.target_id}],"plan":plan}

func redraw_plan(slots: Array[int], rolls: Array[float]) -> Dictionary:
	if can_swap(slots):
		var old: CardData=hand._candidate_cards[slots[0]]
		return {"valid":true,"cards":[hand._definitions_by_id[&"debug" if old.id==&"search_for_bugs" else &"search_for_bugs"]] as Array[CardData],"failed_features":[],"swap":true}
	if not valid_redraw(slots,rolls): return {"valid":false,"cards":[],"failed_features":[]}
	if phase!=&"beta": return core_redraw_plan(slots,rolls)
	var replacements: Array[CardData] = []
	var reserved: Array[StringName] = hand._project_state.get_exhausted_beta_card_ids()
	for card: CardData in hand._candidate_cards:
		if not card.renewable and not reserved.has(card.id): reserved.append(card.id)
	for index in range(slots.size()):
		var excluded:=reserved.duplicate()
		excluded.append(hand._candidate_cards[slots[index]].id)
		var controlled: Array[float] = []
		if not rolls.is_empty(): controlled.append(rolls[index])
		var deal: Dictionary = hand._build_candidate_definitions(hand._beta_definitions,hand.priorities,controlled,controlled,excluded,1)
		if not deal.valid: return {"valid":false,"cards":[],"failed_features":[]}
		var card: CardData = deal.cards[0]
		replacements.append(card)
		if not card.renewable: reserved.append(card.id)
	return {"valid":true,"cards":replacements,"failed_features":[]}

func redraw(slots: Array[int], rolls: Array[float] = [], readiness: Callable = Callable(), publication: Callable = Callable()) -> Dictionary:
	var before: int = hand._deal_rng.state
	var revision: int=hand.revision
	var tokens: Array=hand.candidate_ids.duplicate()
	var plan:=redraw_plan(slots,rolls)
	if not plan.valid or (readiness.is_valid() and not readiness.call(plan.cards)) or hand.revision!=revision or hand.candidate_ids!=tokens:
		hand._deal_rng.state=before
		return {"ok":false,"events":[],"plan":plan}
	var run: RunState=hand._run_state
	var roster: Dictionary={}
	if plan.get("swap",false):
		roster=EmployeeRoster.qa_swap(run.get_employees(),hand._project_state.get_release_id(),hand._project_state.get_current_cycle(),run.get_completed_run_cycles())
		if roster.is_empty() or not run.can_mutate_checkpoint():
			hand._deal_rng.state=before
			return {"ok":false,"events":[],"plan":plan}
	var publish:=func() -> void:
		if plan.get("swap",false):run._employees=roster
		for index in range(slots.size()):
			var slot:=slots[index]
			var old: CardData = hand._candidate_cards[slot]
			var replacement: CardData = plan.cards[index]
			if phase==&"design":
				if replacement.card_type==&"feature": hand._available_features.erase(replacement)
				if old.card_type==&"feature" and not hand._exhausted_card_ids.has(old.id) and not hand._available_features.has(old): hand._available_features.append(old)
			hand._candidate_cards[slot]=replacement
			hand.candidate_ids[slot]=hand.next_candidate_id
			hand.next_candidate_id+=1
		if plan.get("guided_redraw",false): hand._get_first_game_tutorial().record_successful_redraw()
		hand.revision+=1
		if publication.is_valid(): publication.call(plan)
	if plan.get("swap",false):
		run._publishing_cycle=true;publish.call();run.employees_changed.emit();run._publishing_cycle=false
	elif not run.consume_redraw(slots.size(),publish):
		hand._deal_rng.state=before
		return {"ok":false,"events":[],"plan":plan}
	return {"ok":true,"events":[{"type":"qa_swap" if plan.get("swap",false) else "redraw","slots":slots.duplicate()}],"plan":plan}

static func commit_priorities(project: ProjectState, run: RunState, allocation: RefCounted, distribution: Dictionary, draft_publication: Callable = Callable()) -> bool:
	var old: Dictionary = allocation.get_distribution() if allocation is BetaPriorityAllocation else allocation.get_priority_distribution()
	var valid: bool = BetaPriorityAllocation.is_valid_new_distribution(distribution, run) if allocation is BetaPriorityAllocation else PriorityAllocation.is_valid_new_distribution(distribution, run)
	if project==null or run==null or not valid or distribution==old or not project.can_advance_cycle() or not run.can_advance_calendar_cycle(): return false
	var commit:=func() -> bool:
		if not allocation.set_distribution(distribution): return false
		if draft_publication.is_valid(): draft_publication.call()
		project.advance_cycle()
		return true
	return run.complete_productive_action(commit,0,-1,&"",&"priority_change",project.get_release_id())

func corrective_categories() -> Array[ProjectState.CoreScore]:
	var project: ProjectState = hand._project_state
	if project==null: return [] as Array[ProjectState.CoreScore]
	var profile:=PrimitiveReviewCalculator.get_project_profile(project)
	if profile==null: return [] as Array[ProjectState.CoreScore]
	var categories: Array[ProjectState.CoreScore] = []
	categories.assign(ProjectState.CoreScore.values())
	categories.sort_custom(func(a: ProjectState.CoreScore,b: ProjectState.CoreScore) -> bool:
		var a_score:=float(project.get_core_score(a))/profile.get_standard(a)
		var b_score:=float(project.get_core_score(b))/profile.get_standard(b)
		if a_score!=b_score: return a_score<b_score
		if phase==&"alpha" and hand.priorities[a]!=hand.priorities[b]: return hand.priorities[a]>hand.priorities[b]
		return a<b)
	return categories.slice(0,2)

func corrective_pass_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for category in corrective_categories(): ids.append(hand.PASS_ID_BY_CORE_SCORE[category])
	return ids

func _playtest_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for category in corrective_categories():
		var card: CardData = hand._get_pass_for_category(category) if phase == &"alpha" else catalog.get_card(hand.PASS_ID_BY_CORE_SCORE[category])
		if card == null or (phase == &"beta" and not hand._is_valid_corrective_pass(card)): return []
		cards.append(card)
	return cards

func can_host_playtest() -> bool:
	if phase not in [&"alpha", &"beta"] or not hand.active or not valid_pool(): return false
	var project: ProjectState = hand._project_state
	var run: RunState = hand._run_state
	var pending: Array = hand._pending_playtest_categories if phase == &"alpha" else hand._pending_corrective_pass_ids
	var cost := BETA_PLAYTEST_COST_CENTS if phase == &"beta" else 0
	if not pending.is_empty() or not project.can_advance_cycle(): return false
	if run != null and not run.can_complete_productive_cycle(-cost): return false
	if phase == &"beta" and (run == null or not project.has_alpha_finalization() or not run.is_cash_initialized() or run.get_cash_cents() < cost): return false
	if phase == &"alpha" and hand.pass_budget_active():
		var held: int = hand._candidate_cards.filter(func(card: CardData): return card.card_type == &"pass").size()
		if hand.pass_budget_available() - held < 2: return false
	return _playtest_cards().size() == 2

## Prepare any live views before the productive transaction. No random deal.
func host_playtest(readiness: Callable = Callable()) -> bool:
	if not can_host_playtest(): return false
	var cards := _playtest_cards()
	if readiness.is_valid() and not readiness.call(cards): return false
	var project: ProjectState = hand._project_state
	var run: RunState = hand._run_state
	var cost := BETA_PLAYTEST_COST_CENTS if phase == &"beta" else 0
	var commit := func() -> bool:
		for card: CardData in cards:
			hand._candidate_cards.append(card)
			hand.candidate_ids.append(hand.next_candidate_id)
			hand.injected_candidate_ids.append(hand.next_candidate_id)
			hand.next_candidate_id += 1
		hand.revision += 1
		project.advance_cycle()
		return true
	return run.complete_productive_action(commit, -cost, -1, &"", &"playtest", project.get_release_id()) if run != null else commit.call()

func valid_pool() -> bool:
	if hand.candidate_ids.size() != hand._candidate_cards.size(): return false
	var seen_tokens := {}
	for token: int in hand.candidate_ids:
		if token < 0 or seen_tokens.has(token): return false
		seen_tokens[token] = true
	var protected: Array[int] = []
	if phase in [&"alpha", &"beta"]:
		for token: int in hand.injected_candidate_ids:
			if token not in hand.candidate_ids or token in protected: return false
			var card: CardData = hand._candidate_cards[hand.candidate_ids.find(token)]
			if card == null or card.card_type != &"pass": return false
			if phase == &"beta" and not hand._is_valid_corrective_pass(card): return false
			protected.append(token)
	if hand._candidate_cards.size() - protected.size() > 7: return false
	var held_passes := 0
	for card: CardData in hand._candidate_cards:
		if card == null: return false
		if card.card_type == &"pass": held_passes += 1
	if phase in [&"design", &"alpha"] and hand.pass_budget_active() and held_passes > hand.pass_budget_available(): return false
	if phase == &"beta":
		for index in hand._candidate_cards.size():
			var card: CardData = hand._candidate_cards[index]
			if hand._definitions_by_id.get(card.id) != card: return false
			if hand.candidate_ids[index] not in protected and (card.phase != CardData.PHASE_BETA or card.card_type != &"beta"): return false
		return true
	if phase != &"alpha": return true
	var seen: Array[StringName] = []
	for card: CardData in hand._candidate_cards:
		if card.card_type == &"feature":
			if not hand._get_feature_validation_error(card).is_empty() or not hand._available_features.has(card) or hand._exhausted_feature_ids.has(card.id) or card.id in seen: return false
			seen.append(card.id)
		elif card.card_type == &"pass":
			if not hand._get_pass_validation_error(card).is_empty() or not hand._pass_definitions.has(card): return false
		else: return false
	return true

func can_finalize() -> bool:
	var project: ProjectState = hand._project_state
	var run: RunState = hand._run_state
	if project==null: return false
	if run!=null and not run._rival_founder_profile.is_empty():
		if phase in [&"alpha",&"beta"] and project.get_current_scope()<project.get_required_scope():return false
		if phase in [&"design",&"alpha"]:
			var remaining: Array[CardData]=[]
			remaining.assign(hand._available_features)
			for card: CardData in hand._candidate_cards:
				if card.card_type==&"feature" and not remaining.has(card):remaining.append(card)
			# A single affordable remaining Feature is now a legal hand.
			for card: CardData in remaining:
				var fee: int = run.primitive_feature_hand_cost_cents([card] as Array[CardData], project.get_release_id())
				if fee >= 0 and run.can_complete_productive_cycle(-fee): return false
	if phase==&"design": return not project.has_design_bug_finalization()
	if not hand.active or not valid_pool(): return false
	if phase==&"alpha":
		var history: Dictionary = boundary()._build_alpha_feature_history(false)
		return project.can_advance_cycle() and (run==null or run.can_transition_without_productive_cycle()) and not project.has_alpha_finalization() and history.valid and project.has_launch_feature_work(history.implemented_ids)
	return project.has_launch_feature_work() and project.has_alpha_finalization() and not project.has_beta_finalization() and run!=null and run.is_cash_initialized() and hand._snapshot_database!=null and hand._snapshot_database.has_competitor(project.get_assigned_competitor_snapshot_id_for_authority()) and hand._snapshot_database.has_forecast(project.get_assigned_market_forecast_snapshot_id_for_authority())

func finalize(controlled_rolls: Array[float] = []) -> Dictionary:
	if not can_finalize(): return {"ok":false,"events":[]}
	var rules:=boundary()
	var project: ProjectState = hand._project_state
	if phase==&"beta":
		if not rules._validate_exhausted_beta_ids(catalog) or not rules._validate_feature_histories(catalog) or not project.finalize_beta(): return {"ok":false,"events":[]}
		hand._pending_corrective_pass_ids.clear()
		hand._candidate_cards.clear()
		hand.candidate_ids.clear()
		hand.injected_candidate_ids.clear()
		hand.active=false
		return {"ok":true,"events":[{"type":"beta_finalized"}]}
	if not controlled_rolls.is_empty() and controlled_rolls.size()!=2: return {"ok":false,"events":[]}
	var before:=finalization_rng.state
	var first:=finalization_rng.randf() if controlled_rolls.is_empty() else controlled_rolls[0]
	var second:=finalization_rng.randf() if controlled_rolls.is_empty() else controlled_rolls[1]
	var history: Dictionary = rules._build_design_feature_history() if phase==&"design" else rules._build_alpha_feature_history()
	var result: Dictionary = rules._calculate_design_finalization(first,second) if phase==&"design" else rules._calculate_alpha_finalization(first,second)
	var ok:=false
	if history.valid and result.valid:
		ok=project.finalize_design_bugs(result.perfect_production,result.hidden_bugs,history.implemented_ids,history.unimplemented_ids) if phase==&"design" else project.finalize_alpha(result.generated,history.implemented_ids,history.unimplemented_ids)
	if not ok:
		finalization_rng.state=before
		return {"ok":false,"events":[]}
	if phase==&"design":
		hand.finalization_requested=true
		if hand._run_state!=null: hand._run_state.resolve_qa_design_leads(project)
	else: hand._pending_playtest_categories.clear()
	hand.active=false
	return {"ok":true,"events":[{"type":str(phase)+"_finalized"}],"finalization":result,"history":history}


func core_redraw_plan(slots: Array[int], controlled_rolls: Array[float]) -> Dictionary:
	var remaining_pass_room: int = hand.pass_budget_available()
	for index in hand._candidate_cards.size():
		if index not in slots and hand._candidate_cards[index].card_type==&"pass":remaining_pass_room-=1
	if phase == &"design":
		var tutorial: FirstGameTutorial = hand._get_first_game_tutorial()
		if tutorial != null:
			var selected: Array[CardData] = []
			for slot in slots: selected.append(hand._candidate_cards[slot])
			var guided := tutorial.guaranteed_redraw_cards(hand._candidate_cards,selected,hand._pass_definitions)
			if guided != null and (guided.card_type!=&"pass" or remaining_pass_room>0): return {"valid":true,"cards":[guided] as Array[CardData],"failed_features":[],"guided_redraw":true}
	var cards: Array[CardData] = []
	var reserved: Array[StringName] = []
	var failed_features: Array[int] = []
	var valid := true
	for index in range(slots.size()):
		var slot := slots[index]
		var old_card: CardData = hand._candidate_cards[slot]
		var feature_entries: Array[Dictionary] = []
		var pass_entries: Array[Dictionary] = []
		for card: CardData in hand._available_features:
			if card.id == old_card.id or reserved.has(card.id): continue
			var already_visible := false
			for current: CardData in hand._candidate_cards:
				if current.id == card.id: already_visible = true
			if already_visible: continue
			var weight: float = hand._calculate_candidate_weight(card, hand.get_priority_distribution())
			if weight > 0.0: feature_entries.append({&"card": card, &"weight": weight})
		for card: CardData in hand._pass_definitions:
			if remaining_pass_room<=0:break
			if card.id == old_card.id: continue
			var weight: float = hand._calculate_candidate_weight(card, hand.get_priority_distribution())
			if weight > 0.0: pass_entries.append({&"card": card, &"weight": weight})
		feature_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.card.id) < str(b.card.id))
		pass_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.card.id) < str(b.card.id))
		var roll: float = controlled_rolls[index] if not controlled_rolls.is_empty() else hand._deal_rng.randf()
		var entries: Array[Dictionary] = []
		var weighted_roll := roll
		if not feature_entries.is_empty() and not pass_entries.is_empty():
			# Split one uniform roll by class, then use its remaining range for
			# priority-weighted selection within that class.
			entries = feature_entries if roll < 0.5 else pass_entries
			weighted_roll = roll * 2.0 if roll < 0.5 else (roll - 0.5) * 2.0
		elif not feature_entries.is_empty():
			entries = feature_entries
		else:
			entries = pass_entries
		var replacement: CardData = hand._select_weighted_entry(entries, weighted_roll)
		if replacement == null:
			valid = false
			if old_card.card_type == &"feature": failed_features.append(slot)
		else:
			cards.append(replacement)
			if replacement.card_type==&"pass":remaining_pass_room-=1
			if not replacement.renewable: reserved.append(replacement.id)
	return {&"valid": valid, &"cards": cards, &"failed_features": failed_features}
