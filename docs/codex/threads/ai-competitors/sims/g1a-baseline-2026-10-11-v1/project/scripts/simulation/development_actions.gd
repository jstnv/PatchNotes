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
		hand.next_candidate_id+=1
	if phase==&"design":
		for card: CardData in plan.selected_features: hand._available_features.erase(card)
		if plan.has("tutorial_stat"): hand._get_first_game_tutorial().record_deal(plan.tutorial_stat)
	elif phase==&"alpha": hand._pending_playtest_categories.clear()
	hand.revision+=1

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
		elif hand._candidate_cards[slot].card_type not in [&"feature",&"pass"]: return false
	return true

func redraw_plan(slots: Array[int], rolls: Array[float]) -> Dictionary:
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
	var plan:=redraw_plan(slots,rolls)
	if not plan.valid or (readiness.is_valid() and not readiness.call(plan.cards)):
		hand._deal_rng.state=before
		return {"ok":false,"events":[],"plan":plan}
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
	# The live adapter publishes the complete replacement pool before the one
	# budget notification, matching the existing observable transaction boundary.
	if publication.is_valid(): publication.call(plan)
	hand._run_state.consume_redraw(slots.size())
	hand.revision+=1
	return {"ok":true,"events":[{"type":"redraw","slots":slots.duplicate()}],"plan":plan}

static func commit_priorities(project: ProjectState, run: RunState, allocation: RefCounted, distribution: Dictionary, draft_publication: Callable = Callable()) -> bool:
	var old: Dictionary = allocation.get_distribution() if allocation is BetaPriorityAllocation else allocation.get_priority_distribution()
	var valid: bool = BetaPriorityAllocation.is_valid_distribution(distribution) if allocation is BetaPriorityAllocation else PriorityAllocation.is_valid_distribution(distribution)
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

func host_playtest() -> bool:
	if phase not in [&"alpha",&"beta"] or not hand.active or not valid_pool(): return false
	var project: ProjectState = hand._project_state
	var run: RunState = hand._run_state
	var pending: Array = hand._pending_playtest_categories if phase==&"alpha" else hand._pending_corrective_pass_ids
	var cost:=BETA_PLAYTEST_COST_CENTS if phase==&"beta" else 0
	if not pending.is_empty() or not project.can_advance_cycle(): return false
	if run!=null and not run.can_complete_productive_cycle(-cost): return false
	if phase==&"beta" and (run==null or not project.has_alpha_finalization() or not run.is_cash_initialized() or run.get_cash_cents()<cost): return false
	var selected: Array = corrective_categories() if phase==&"alpha" else corrective_pass_ids()
	if selected.size()!=2 or selected[0]==selected[1]: return false
	if phase==&"beta":
		for id: StringName in selected:
			if not hand._is_valid_corrective_pass(catalog.get_card(id)): return false
	var commit:=func() -> bool:
		if phase==&"alpha": pending.assign(selected)
		project.advance_cycle()
		if phase==&"beta": pending.assign(selected)
		return true
	return run.complete_productive_action(commit,-cost,-1,&"",&"playtest",project.get_release_id()) if run!=null else commit.call()

func valid_pool() -> bool:
	if hand._candidate_cards.size()!=7: return false
	if phase!=&"alpha": return true
	var seen: Array[StringName] = []
	for card: CardData in hand._candidate_cards:
		if card==null: return false
		if card.card_type==&"feature":
			if not hand._get_feature_validation_error(card).is_empty() or not hand._available_features.has(card) or hand._exhausted_feature_ids.has(card.id) or card.id in seen: return false
			seen.append(card.id)
		elif card.card_type==&"pass":
			if not hand._get_pass_validation_error(card).is_empty() or not hand._pass_definitions.has(card): return false
		else: return false
	return true

func can_finalize() -> bool:
	var project: ProjectState = hand._project_state
	var run: RunState = hand._run_state
	if project==null: return false
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
	if phase==&"design": hand.finalization_requested=true
	else: hand._pending_playtest_categories.clear()
	hand.active=false
	return {"ok":true,"events":[{"type":str(phase)+"_finalized"}],"finalization":result,"history":history}


func core_redraw_plan(slots: Array[int], controlled_rolls: Array[float]) -> Dictionary:
	if phase == &"design":
		var tutorial: FirstGameTutorial = hand._get_first_game_tutorial()
		if tutorial != null:
			var selected: Array[CardData] = []
			for slot in slots: selected.append(hand._candidate_cards[slot])
			var guided := tutorial.guaranteed_redraw_cards(hand._candidate_cards,selected,hand._pass_definitions)
			if guided != null: return {"valid":true,"cards":[guided] as Array[CardData],"failed_features":[],"guided_redraw":true}
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
			if not replacement.renewable: reserved.append(replacement.id)
	return {&"valid": valid, &"cards": cards, &"failed_features": failed_features}
